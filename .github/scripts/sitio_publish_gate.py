#!/usr/bin/env python3
"""Decide whether Coquí sitio should build and deploy to GitHub Pages.

Stdlib-only Python 3.12 gate script invoked by `.github/workflows/coqui-sitio.yml`.
Validates `coqui/.flutter-version` and `coqui/BUILD`, evaluates git diff / Pages
deployment state to skip no-op rebuilds, and enforces the `#262` green-`main`
CI check (`check_main_ci_green`) by default.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

API_BASE = "https://api.github.com"
BUILD_RE = re.compile(r"^[0-9]+$")
HEX40_RE = re.compile(r"^[0-9a-fA-F]{40}$")
ZERO_SHA = "0" * 40
TRUTHY = {"1", "true", "yes", "on"}
FALSY = {"0", "false", "no", "off"}
DEFAULT_PUSH_WAIT_TIMEOUT_SECONDS = 1500.0
DEFAULT_WAIT_POLL_SECONDS = 30.0
REGISTRATION_GRACE_SECONDS = 120.0

ApiGetFn = Callable[[str, str], Any]


@dataclass(frozen=True)
class GateDecision:
    flutter: str
    build: str
    should_build: bool
    should_deploy: bool
    reason: str


def _env_truthy(value: str | None) -> bool:
    return (value or "").strip().lower() in TRUTHY


def _env_bool_default_true(value: str | None) -> bool:
    if value is None or not value.strip():
        return True
    return value.strip().lower() not in FALSY


def _normalize_repo_path(path: str) -> str:
    norm = path.strip().replace("\\", "/")
    while norm.startswith("./"):
        norm = norm[2:]
    return norm.lstrip("/")


def is_publish_trigger_path(path: str) -> bool:
    """Return True if a repo-relative path should trigger a live Pages publish."""
    norm = _normalize_repo_path(path)
    if norm in {"coqui/BUILD", "index.html", "prueba/index.html"}:
        return True
    if norm.startswith("historia/"):
        if (
            norm == "historia/tools"
            or norm.startswith("historia/tools/")
            or norm == "historia/notas"
            or norm.startswith("historia/notas/")
        ):
            return False
        return True
    return False


def is_site_content_path(path: str) -> bool:
    """Return True if a repo-relative path affects the published Pages site."""
    norm = _normalize_repo_path(path)
    if is_publish_trigger_path(norm):
        return True
    if norm.startswith("coqui/"):
        if (
            norm == "coqui/ref"
            or norm.startswith("coqui/ref/")
            or norm == "coqui/requests"
            or norm.startswith("coqui/requests/")
        ):
            return False
        return True
    return False


def is_coqui_main_ci_path(path: str) -> bool:
    """Return True if a repo-relative path triggers the push-to-main `coqui.yml` workflow."""
    norm = _normalize_repo_path(path).rstrip("/")
    return (
        norm == "coqui"
        or norm.startswith("coqui/")
        or norm in {".github/workflows/coqui.yml", ".github/scripts/coqui_ci_gate.sh"}
    )


def read_flutter_and_build(repo_root: Path) -> tuple[str, str]:
    """Read and validate `coqui/.flutter-version` and `coqui/BUILD`."""
    flutter_path = repo_root / "coqui" / ".flutter-version"
    build_path = repo_root / "coqui" / "BUILD"

    if not flutter_path.is_file():
        raise ValueError(f"missing Flutter version file: {flutter_path}")
    flutter = flutter_path.read_text(encoding="utf-8").strip()
    if not flutter:
        raise ValueError(f"{flutter_path} must not be empty")

    if not build_path.is_file():
        raise ValueError(f"missing build number file: {build_path}")
    build = build_path.read_text(encoding="utf-8").strip()
    if not BUILD_RE.match(build):
        raise ValueError(f"coqui/BUILD must hold one non-negative integer, not {build!r}")

    return flutter, build


def _run_git(repo_root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo_root), *args],
        capture_output=True,
        text=True,
        check=False,
    )


def _commit_exists(repo_root: Path, sha: str) -> bool:
    if not sha or not HEX40_RE.match(sha) or sha == ZERO_SHA:
        return False
    res = _run_git(repo_root, "cat-file", "-e", f"{sha}^{{commit}}")
    return res.returncode == 0


def _is_ancestor(repo_root: Path, ancestor: str, descendant: str) -> bool:
    res = _run_git(repo_root, "merge-base", "--is-ancestor", ancestor, descendant)
    return res.returncode == 0


def _git_diff_names(repo_root: Path, base_sha: str, head_sha: str) -> list[str] | None:
    res = _run_git(
        repo_root,
        "diff",
        "--name-only",
        "--no-renames",
        f"{base_sha}..{head_sha}",
    )
    if res.returncode != 0:
        return None
    return [line.strip() for line in res.stdout.splitlines() if line.strip()]


def _git_show_file(repo_root: Path, rev: str, rel_path: str) -> str | None:
    res = _run_git(repo_root, "show", f"{rev}:{rel_path}")
    if res.returncode != 0:
        return None
    return res.stdout


def github_api_get_json(url: str, token: str, *, timeout: int = 15) -> Any:
    """Perform a GET request against the GitHub REST API and decode JSON."""
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "coqui-sitio-publish-gate",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers, method="GET")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read().decode("utf-8")
    return json.loads(raw)


def _append_query_param(url: str, key: str, value: str) -> str:
    parsed = urllib.parse.urlsplit(url)
    params = urllib.parse.parse_qsl(parsed.query, keep_blank_values=True)
    params = [(k, v) for k, v in params if k != key]
    params.append((key, value))
    return urllib.parse.urlunsplit(
        (
            parsed.scheme,
            parsed.netloc,
            parsed.path,
            urllib.parse.urlencode(params),
            parsed.fragment,
        )
    )


def find_latest_actions_pages_deployment_sha(
    repository: str,
    token: str,
    *,
    api_get: ApiGetFn = github_api_get_json,
) -> str | None:
    """Return the commit SHA of the newest successful github-actions Pages deploy.

    Strictly filters to deployments performed by `github-actions` so legacy
    `github-pages` branch deployments do not suppress the first Actions deploy.
    """
    deployments_url = (
        f"{API_BASE}/repos/{repository}/deployments"
        "?environment=github-pages&per_page=10"
    )
    deployments = api_get(deployments_url, token)
    if not isinstance(deployments, list):
        return None

    actions_deployments = [
        d
        for d in deployments
        if isinstance(d, dict)
        and ((d.get("performed_via_github_app") or {}).get("slug") == "github-actions")
    ]
    if not actions_deployments:
        return None

    newest = actions_deployments[0]
    statuses_url = newest.get("statuses_url")
    deployed_sha = (newest.get("sha") or "").strip()
    if not statuses_url or not deployed_sha:
        return None

    statuses = api_get(_append_query_param(str(statuses_url), "per_page", "1"), token)
    if not isinstance(statuses, list) or not statuses:
        return None
    latest_status = statuses[0]
    if isinstance(latest_status, dict) and latest_status.get("state") == "success":
        return deployed_sha
    return None


def _evaluate_main_ci_once(
    repository: str,
    sha: str,
    token: str,
    *,
    repo_root: Path | None = None,
    api_get: ApiGetFn = github_api_get_json,
) -> tuple[str, str]:
    """Single poll of the latest full `coqui.yml` workflow run on `main`.

    Returns `(outcome, message)` where `outcome` is one of:
      - `"pass"`: latest full `coqui.yml` run on `main` succeeded and covers `sha`
      - `"pending"`: latest full `coqui.yml` run on `main` is still running/queued
      - `"awaiting_registration"`: latest green run is an ancestor and Coquí CI
        paths changed since, so GitHub may not have listed the new run yet
      - `"fail"`: terminal refusal (failed/cancelled run, API error, missing
        credentials, empty runs, non-ancestor, or git diff error)

    Checking `full_runs[0]` strictly blocks publishing an earlier SHA while a
    newer commit's run on `main` is pending or red (intentional fail-closed
    safety). `coqui-sitio.yml` checks out with `fetch-depth: 0`, so ancestor
    commits exist locally for `_is_ancestor` / `_git_diff_names`.
    """
    if not repository or not sha or not token:
        return (
            "fail",
            "cannot verify green main CI: repository, sha, and GITHUB_TOKEN are required",
        )

    url = (
        f"{API_BASE}/repos/{repository}/actions/workflows/coqui.yml/runs"
        "?branch=main&per_page=20"
    )
    try:
        payload = api_get(url, token)
    except (
        urllib.error.URLError,
        urllib.error.HTTPError,
        TimeoutError,
        json.JSONDecodeError,
        OSError,
    ) as exc:
        return (
            "fail",
            f"failed to query 'coqui' workflow runs on main for {sha[:12]}: {exc}",
        )

    runs = payload.get("workflow_runs") if isinstance(payload, dict) else None
    if not isinstance(runs, list):
        return "fail", f"unexpected workflow runs payload for {sha[:12]}"

    full_runs = [
        r
        for r in runs
        if isinstance(r, dict)
        and r.get("head_branch") == "main"
        and r.get("event") in {"push", "workflow_dispatch"}
    ]
    if not full_runs:
        return (
            "fail",
            f"refusing to publish {sha[:12]}: no full 'coqui' workflow runs found on main",
        )

    latest = full_runs[0]
    status = latest.get("status")
    conclusion = latest.get("conclusion")
    latest_sha = (latest.get("head_sha") or "").strip()

    if status != "completed":
        return (
            "pending",
            f"refusing to publish {sha[:12]}: latest full 'coqui' run on main is pending "
            f"(status={status}, run_sha={latest_sha[:12]})",
        )

    if conclusion != "success":
        return (
            "fail",
            f"refusing to publish {sha[:12]}: latest full 'coqui' run on main is not green "
            f"(conclusion={conclusion}, run_sha={latest_sha[:12]})",
        )

    if not latest_sha:
        return (
            "fail",
            f"refusing to publish {sha[:12]}: latest full 'coqui' run on main has missing head_sha",
        )

    if latest_sha == sha:
        return "pass", f"latest full 'coqui' run on main succeeded on {sha[:12]}"

    if repo_root is None:
        return (
            "fail",
            f"refusing to publish {sha[:12]}: latest green full 'coqui' run on main is on "
            f"{latest_sha[:12]}, not {sha[:12]}",
        )

    if (
        not _commit_exists(repo_root, latest_sha)
        or not _commit_exists(repo_root, sha)
        or not _is_ancestor(repo_root, latest_sha, sha)
    ):
        return (
            "fail",
            f"refusing to publish {sha[:12]}: latest green full 'coqui' run "
            f"({latest_sha[:12]}) does not cover {sha[:12]}",
        )

    changed = _git_diff_names(repo_root, latest_sha, sha)
    if changed is None:
        return (
            "fail",
            f"refusing to publish {sha[:12]}: failed to diff {latest_sha[:12]}..{sha[:12]}",
        )

    ci_changed = [p for p in changed if is_coqui_main_ci_path(p)]
    if ci_changed:
        return (
            "awaiting_registration",
            f"refusing to publish {sha[:12]}: Coquí CI paths changed since last green full "
            f"'coqui' run ({latest_sha[:12]}): {', '.join(ci_changed[:5])}",
        )

    return (
        "pass",
        f"latest full 'coqui' run on main succeeded on {latest_sha[:12]} and no Coquí CI paths changed since",
    )


def check_main_ci_green(
    repository: str,
    sha: str,
    token: str,
    *,
    require_green_main: bool = True,
    repo_root: Path | None = None,
    wait_timeout_seconds: float = 0.0,
    poll_interval_seconds: float = DEFAULT_WAIT_POLL_SECONDS,
    registration_grace_seconds: float = REGISTRATION_GRACE_SECONDS,
    api_get: ApiGetFn = github_api_get_json,
    sleep_fn: Callable[[float], None] = time.sleep,
    monotonic_fn: Callable[[], float] = time.monotonic,
    stderr: Any = None,
) -> tuple[bool, str]:
    """Verify the latest full `coqui.yml` workflow run on `main` succeeded (#262).

    When `wait_timeout_seconds > 0` (the default on `push` to `main`, where
    `coqui.yml` and `coqui-sitio.yml` start in parallel), polls while the latest
    full `coqui.yml` run is pending or awaiting API registration. Terminal
    failures (`failure`, `cancelled`, API errors, etc.) always refuse
    immediately without sleeping.

    Note: inspecting `full_runs[0]` strictly blocks publishing an earlier SHA
    while a newer commit's run on `main` is pending (intentional fail-closed
    safety), and `coqui-sitio.yml` uses `fetch-depth: 0` so ancestor commits
    exist locally.
    """
    if not require_green_main:
        return True, "green-main gate explicitly disabled"

    err = stderr if stderr is not None else sys.stderr
    start = monotonic_fn()

    while True:
        outcome, msg = _evaluate_main_ci_once(
            repository,
            sha,
            token,
            repo_root=repo_root,
            api_get=api_get,
        )
        if outcome == "pass":
            return True, msg
        if outcome == "fail":
            return False, msg

        elapsed = monotonic_fn() - start
        if outcome == "pending":
            limit = wait_timeout_seconds
        else:  # "awaiting_registration"
            limit = min(wait_timeout_seconds, registration_grace_seconds)

        if limit <= 0 or elapsed >= limit:
            if wait_timeout_seconds > 0:
                return False, f"timed out after {int(elapsed)}s waiting for main CI: {msg}"
            return False, msg

        sleep_for = min(max(poll_interval_seconds, 0.0), max(limit - elapsed, 0.0))
        if sleep_for <= 0:
            if wait_timeout_seconds > 0:
                return False, f"timed out after {int(elapsed)}s waiting for main CI: {msg}"
            return False, msg

        print(
            f"sitio_publish_gate: waiting for full 'coqui' CI on main "
            f"({outcome}, elapsed={int(elapsed)}s/{int(limit)}s); retrying in {int(sleep_for)}s",
            file=err,
        )
        sleep_fn(sleep_for)


def evaluate_gate(
    *,
    repo_root: Path,
    event: str,
    ref: str,
    sha: str,
    before_sha: str,
    repository: str,
    token: str,
    force: bool = False,
    skip_api: bool = False,
    require_green_main: bool = True,
    wait_timeout_seconds: float | None = None,
    poll_interval_seconds: float = DEFAULT_WAIT_POLL_SECONDS,
    registration_grace_seconds: float = REGISTRATION_GRACE_SECONDS,
    api_get: ApiGetFn = github_api_get_json,
    sleep_fn: Callable[[float], None] = time.sleep,
    monotonic_fn: Callable[[], float] = time.monotonic,
    stderr: Any = None,
) -> tuple[GateDecision, int]:
    """Evaluate build/deploy decision and return `(decision, exit_code)`."""
    err = stderr if stderr is not None else sys.stderr
    flutter, build = read_flutter_and_build(repo_root)

    resolved_sha = sha.strip()
    if not resolved_sha:
        head = _run_git(repo_root, "rev-parse", "HEAD")
        if head.returncode == 0:
            resolved_sha = head.stdout.strip()

    if ref != "refs/heads/main" or event == "pull_request":
        return (
            GateDecision(
                flutter=flutter,
                build=build,
                should_build=True,
                should_deploy=False,
                reason=f"non-main ref or pull_request (event={event or 'unknown'}, ref={ref or 'unknown'}): build artifact only",
            ),
            0,
        )

    # On refs/heads/main (push or workflow_dispatch)
    reason = "force publish requested" if force else f"publish triggered ({event or 'main'})"

    if event == "push" and not force:
        before = before_sha.strip()
        if _commit_exists(repo_root, before) and _commit_exists(repo_root, resolved_sha):
            changed = _git_diff_names(repo_root, before, resolved_sha)
            if changed is not None:
                matched = [p for p in changed if is_publish_trigger_path(p)]
                if not matched:
                    return (
                        GateDecision(
                            flutter=flutter,
                            build=build,
                            should_build=False,
                            should_deploy=False,
                            reason="push changed no publish-trigger paths",
                        ),
                        0,
                    )
                if matched == ["coqui/BUILD"]:
                    before_raw = _git_show_file(repo_root, before, "coqui/BUILD")
                    after_raw = _git_show_file(repo_root, resolved_sha, "coqui/BUILD")
                    if before_raw is not None and after_raw is not None:
                        if before_raw.strip() == after_raw.strip():
                            return (
                                GateDecision(
                                    flutter=flutter,
                                    build=build,
                                    should_build=False,
                                    should_deploy=False,
                                    reason=f"coqui/BUILD value unchanged ({build})",
                                ),
                                0,
                            )

    if not force and not skip_api and token and repository:
        try:
            deployed_sha = find_latest_actions_pages_deployment_sha(
                repository, token, api_get=api_get
            )
        except (
            urllib.error.URLError,
            urllib.error.HTTPError,
            TimeoutError,
            json.JSONDecodeError,
            OSError,
        ) as exc:
            print(
                f"sitio_publish_gate: warning: GitHub deployments API check failed ({exc}); continuing",
                file=err,
            )
            deployed_sha = None

        if deployed_sha:
            if resolved_sha and deployed_sha == resolved_sha:
                return (
                    GateDecision(
                        flutter=flutter,
                        build=build,
                        should_build=False,
                        should_deploy=False,
                        reason=f"commit {resolved_sha[:12]} already deployed to github-pages",
                    ),
                    0,
                )
            if (
                event == "workflow_dispatch"
                and _commit_exists(repo_root, deployed_sha)
                and _commit_exists(repo_root, resolved_sha)
            ):
                changed_since_deploy = _git_diff_names(
                    repo_root, deployed_sha, resolved_sha
                )
                if changed_since_deploy is not None and not any(
                    is_site_content_path(p) for p in changed_since_deploy
                ):
                    return (
                        GateDecision(
                            flutter=flutter,
                            build=build,
                            should_build=False,
                            should_deploy=False,
                            reason=f"no site content changed since deployed commit {deployed_sha[:12]}",
                        ),
                        0,
                    )

    if wait_timeout_seconds is None:
        resolved_wait_timeout = (
            DEFAULT_PUSH_WAIT_TIMEOUT_SECONDS if event == "push" else 0.0
        )
    else:
        resolved_wait_timeout = wait_timeout_seconds

    green, green_msg = check_main_ci_green(
        repository,
        resolved_sha,
        token,
        require_green_main=require_green_main,
        repo_root=repo_root,
        wait_timeout_seconds=resolved_wait_timeout,
        poll_interval_seconds=poll_interval_seconds,
        registration_grace_seconds=registration_grace_seconds,
        api_get=api_get,
        sleep_fn=sleep_fn,
        monotonic_fn=monotonic_fn,
        stderr=err,
    )
    if not green:
        print(f"ERROR: {green_msg}", file=err)
        return (
            GateDecision(
                flutter=flutter,
                build=build,
                should_build=False,
                should_deploy=False,
                reason=green_msg,
            ),
            1,
        )

    return (
        GateDecision(
            flutter=flutter,
            build=build,
            should_build=True,
            should_deploy=True,
            reason=reason,
        ),
        0,
    )


def sanitize_output_value(value: str) -> str:
    """Remove CR/LF so single-line `$GITHUB_OUTPUT` writes are always safe."""
    return " ".join(value.replace("\r", " ").replace("\n", " ").split())


def write_github_output(output_path: str, decision: GateDecision) -> None:
    if not output_path:
        return
    lines = [
        f"flutter={sanitize_output_value(decision.flutter)}",
        f"build={sanitize_output_value(decision.build)}",
        f"should_build={'true' if decision.should_build else 'false'}",
        f"should_deploy={'true' if decision.should_deploy else 'false'}",
        f"reason={sanitize_output_value(decision.reason)}",
    ]
    with open(output_path, "a", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")


def _env_float(name: str, default: float | None) -> float | None:
    raw = (os.environ.get(name) or "").strip()
    if not raw:
        return default
    return float(raw)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    default_root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(
        description="Gate Coquí sitio build and GitHub Pages deployment."
    )
    parser.add_argument("--repo-root", type=Path, default=default_root)
    parser.add_argument(
        "--event",
        default=os.environ.get("EVENT_NAME") or os.environ.get("GITHUB_EVENT_NAME") or "",
    )
    parser.add_argument("--ref", default=os.environ.get("GITHUB_REF", ""))
    parser.add_argument("--sha", default=os.environ.get("GITHUB_SHA", ""))
    parser.add_argument("--before-sha", default=os.environ.get("BEFORE_SHA", ""))
    parser.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY", ""))
    parser.add_argument(
        "--force",
        action="store_true",
        default=_env_truthy(os.environ.get("FORCE_PUBLISH")),
    )
    parser.add_argument(
        "--github-output", default=os.environ.get("GITHUB_OUTPUT", "")
    )
    parser.add_argument(
        "--require-green-main",
        action=argparse.BooleanOptionalAction,
        default=_env_bool_default_true(os.environ.get("REQUIRE_GREEN_MAIN")),
        help=(
            "Require the latest full 'coqui' CI workflow run on main to be green before "
            "publishing (default: true; pass --no-require-green-main for local dry runs "
            "without a GITHUB_TOKEN)."
        ),
    )
    parser.add_argument(
        "--wait-ci-timeout",
        type=float,
        default=_env_float("WAIT_MAIN_CI_TIMEOUT_SECONDS", None),
        help=(
            "Max seconds to wait for an in-progress full 'coqui' CI run on main "
            f"(default: {int(DEFAULT_PUSH_WAIT_TIMEOUT_SECONDS)}s on push, 0s otherwise)."
        ),
    )
    parser.add_argument(
        "--wait-ci-interval",
        type=float,
        default=_env_float("WAIT_MAIN_CI_POLL_SECONDS", DEFAULT_WAIT_POLL_SECONDS),
        help=f"Seconds between CI status polls while waiting (default: {int(DEFAULT_WAIT_POLL_SECONDS)}s).",
    )
    parser.add_argument("--skip-api", action="store_true", default=False)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    token = os.environ.get("GITHUB_TOKEN", "")
    try:
        decision, rc = evaluate_gate(
            repo_root=args.repo_root.resolve(),
            event=args.event,
            ref=args.ref,
            sha=args.sha,
            before_sha=args.before_sha,
            repository=args.repository,
            token=token,
            force=args.force,
            skip_api=args.skip_api,
            require_green_main=args.require_green_main,
            wait_timeout_seconds=args.wait_ci_timeout,
            poll_interval_seconds=args.wait_ci_interval,
        )
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    write_github_output(args.github_output, decision)
    print(
        "sitio_publish_gate: "
        f"flutter={decision.flutter} "
        f"build={decision.build} "
        f"should_build={'true' if decision.should_build else 'false'} "
        f"should_deploy={'true' if decision.should_deploy else 'false'} "
        f"reason={sanitize_output_value(decision.reason)}"
    )
    return rc


if __name__ == "__main__":
    sys.exit(main())
