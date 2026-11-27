#!/usr/bin/env python3
"""Decide whether Coquí sitio should build and deploy to GitHub Pages.

Stdlib-only Python 3.12 gate script invoked by `.github/workflows/coqui-sitio.yml`.
Validates `coqui/.flutter-version` and `coqui/BUILD`, evaluates git diff / Pages
deployment state to skip no-op rebuilds, and provides the `#262` green-`main`
CI check extension point (`check_main_ci_green`).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
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


def check_main_ci_green(
    repository: str,
    sha: str,
    token: str,
    *,
    require_green_main: bool = False,
    api_get: ApiGetFn = github_api_get_json,
) -> tuple[bool, str]:
    """Extension point for #262 (E6): require green `coqui` check-run on `main`."""
    if not require_green_main:
        return True, "green-main gate not yet enabled (#262)"

    if not repository or not sha or not token:
        return (
            False,
            "cannot verify green main CI: repository, sha, and GITHUB_TOKEN are required",
        )

    url = (
        f"{API_BASE}/repos/{repository}/commits/{sha}/check-runs"
        "?check_name=coqui&per_page=20"
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
        return False, f"failed to query 'coqui' check-runs for {sha[:12]}: {exc}"

    runs = payload.get("check_runs") if isinstance(payload, dict) else None
    if not isinstance(runs, list):
        return False, f"unexpected check-runs payload for {sha[:12]}"

    for run in runs:
        if (
            isinstance(run, dict)
            and run.get("status") == "completed"
            and run.get("conclusion") == "success"
        ):
            return True, f"check 'coqui' succeeded on {sha[:12]}"

    states = [
        f"{r.get('status')}/{r.get('conclusion')}"
        for r in runs
        if isinstance(r, dict)
    ]
    summary = ", ".join(states) if states else "no check-runs found"
    return (
        False,
        f"refusing to publish {sha[:12]}: required check 'coqui' is not green ({summary})",
    )


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
    require_green_main: bool = False,
    api_get: ApiGetFn = github_api_get_json,
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

    green, green_msg = check_main_ci_green(
        repository,
        resolved_sha,
        token,
        require_green_main=require_green_main,
        api_get=api_get,
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
        action="store_true",
        default=_env_truthy(os.environ.get("REQUIRE_GREEN_MAIN")),
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
