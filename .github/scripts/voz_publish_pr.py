#!/usr/bin/env python3
"""Commit recorded Azure Speech audio to a dedicated PR branch (never `main`).

Stdlib-only Python 3.12 script invoked by `.github/workflows/voz.yml`.
Stages only `historia/audio/` and `historia/muestras/`, validates staged paths,
pushes to a dedicated `audio/voz-*` branch, and opens a PR (or emits a 1-click
compare URL notice + job summary if GitHub Actions is not permitted to create PRs).
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ALLOWED_STAGE_DIRS = ("historia/audio", "historia/muestras")
ALLOWED_PREFIXES = ("historia/audio/", "historia/muestras/")
ACTIONS_PR_FORBIDDEN_MSG = (
    "GitHub Actions is not permitted to create or approve pull requests"
)


def _run(
    cmd: list[str],
    *,
    cwd: Path,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=str(cwd),
        capture_output=True,
        text=True,
        check=False,
    )


def _run_git(repo_root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return _run(["git", "-C", str(repo_root), *args], cwd=repo_root)


def default_branch_name(
    run_id: str | None = None,
    run_attempt: str | None = None,
) -> str:
    rid = (run_id if run_id is not None else os.environ.get("GITHUB_RUN_ID", "")).strip()
    att = (
        run_attempt
        if run_attempt is not None
        else os.environ.get("GITHUB_RUN_ATTEMPT", "")
    ).strip()
    if rid:
        return f"audio/voz-{rid}-a{att}" if att else f"audio/voz-{rid}"
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return f"audio/voz-{stamp}"


def validate_branch_name(branch: str, base_branch: str) -> None:
    cleaned = branch.strip()
    if not cleaned:
        raise ValueError("branch name must not be empty")
    if cleaned in {"main", "master", base_branch.strip()}:
        raise ValueError(
            f"refusing to push to protected/base branch {cleaned!r}; use a PR branch"
        )
    if cleaned.startswith("refs/"):
        raise ValueError(f"branch name must be short ref name, not {cleaned!r}")


def is_allowed_audio_path(path: str) -> bool:
    norm = path.strip().replace("\\", "/").lstrip("/")
    return any(norm.startswith(prefix) for prefix in ALLOWED_PREFIXES)


def _append_step_summary(step_summary: str, markdown: str) -> None:
    if not step_summary:
        return
    with open(step_summary, "a", encoding="utf-8") as fh:
        fh.write(markdown)
        if not markdown.endswith("\n"):
            fh.write("\n")


def _compare_url(repository: str, base_branch: str, branch: str) -> str:
    repo = repository.strip().strip("/")
    if not repo:
        return ""
    return f"https://github.com/{repo}/compare/{base_branch}...{branch}?expand=1"


def publish_audio_pr(
    *,
    repo_root: Path,
    modo: str,
    base_branch: str,
    branch: str,
    repository: str,
    step_summary: str,
    dry_run: bool = False,
) -> int:
    repo_root = repo_root.resolve()
    modo_clean = (modo or "cuento").strip() or "cuento"
    base_clean = (base_branch or "main").strip() or "main"
    branch_clean = branch.strip()

    try:
        validate_branch_name(branch_clean, base_clean)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    # Stage ONLY existing paths among historia/audio and historia/muestras.
    existing_dirs = [d for d in ALLOWED_STAGE_DIRS if (repo_root / d).exists()]
    if existing_dirs:
        add_res = _run_git(repo_root, "add", "-A", "--", *existing_dirs)
        if add_res.returncode != 0:
            print(
                f"ERROR: git add failed: {add_res.stderr.strip()}",
                file=sys.stderr,
            )
            return 1

    # Check whether anything is staged.
    quiet_res = _run_git(repo_root, "diff", "--cached", "--quiet")
    if quiet_res.returncode == 0:
        print("nothing new")
        return 0
    if quiet_res.returncode != 1:
        print(
            f"ERROR: git diff --cached --quiet failed: {quiet_res.stderr.strip()}",
            file=sys.stderr,
        )
        return 1

    # Verify EVERY staged path is strictly inside historia/audio/ or historia/muestras/.
    names_res = _run_git(repo_root, "diff", "--cached", "--name-only", "-z")
    if names_res.returncode != 0:
        print(
            f"ERROR: git diff --cached --name-only failed: {names_res.stderr.strip()}",
            file=sys.stderr,
        )
        return 1

    staged_paths = [p for p in names_res.stdout.split("\0") if p]
    disallowed = [p for p in staged_paths if not is_allowed_audio_path(p)]
    if disallowed:
        print(
            "ERROR: refusing to commit disallowed staged paths "
            f"(only {', '.join(ALLOWED_PREFIXES)} allowed): {', '.join(disallowed)}",
            file=sys.stderr,
        )
        return 1

    file_count = len(staged_paths)
    title = f"Audio: {modo_clean}"

    if dry_run:
        print(
            f"dry-run: would commit {file_count} staged file(s) as {title!r} "
            f"on branch {branch_clean!r} targeting {base_clean!r}"
        )
        return 0

    for key, val in (
        ("user.name", "coqui-voz"),
        ("user.email", "coqui-voz@users.noreply.github.com"),
    ):
        cfg = _run_git(repo_root, "config", key, val)
        if cfg.returncode != 0:
            print(f"ERROR: git config {key} failed: {cfg.stderr.strip()}", file=sys.stderr)
            return 1

    co = _run_git(repo_root, "checkout", "-b", branch_clean)
    if co.returncode != 0:
        print(
            f"ERROR: git checkout -b {branch_clean} failed: {co.stderr.strip()}",
            file=sys.stderr,
        )
        return 1

    commit = _run_git(repo_root, "commit", "-m", title)
    if commit.returncode != 0:
        print(f"ERROR: git commit failed: {commit.stderr.strip()}", file=sys.stderr)
        return 1

    push = _run_git(repo_root, "push", "origin", f"HEAD:refs/heads/{branch_clean}")
    if push.returncode != 0:
        print(
            f"ERROR: git push origin HEAD:refs/heads/{branch_clean} failed: {push.stderr.strip()}",
            file=sys.stderr,
        )
        return 1

    body = (
        f"Automated Azure Speech audio update (`modo: {modo_clean}`).\n\n"
        f"- **Branch:** `{branch_clean}`\n"
        f"- **Changed files:** {file_count} (under `historia/audio/` and/or `historia/muestras/`)\n"
    )

    pr_res = _run(
        [
            "gh",
            "pr",
            "create",
            "--base",
            base_clean,
            "--head",
            branch_clean,
            "--title",
            title,
            "--body",
            body,
        ],
        cwd=repo_root,
    )

    if pr_res.returncode == 0:
        pr_url = pr_res.stdout.strip().splitlines()[-1].strip() if pr_res.stdout.strip() else ""
        print(pr_url or f"PR created for branch {branch_clean}")
        summary_lines = [
            "### Voz audio PR created",
            "",
            f"- **PR:** {pr_url or '(created)'}",
            f"- **Branch:** `{branch_clean}`",
            f"- **Changed files:** {file_count}",
            "",
        ]
        _append_step_summary(step_summary, "\n".join(summary_lines))
        return 0

    combined_output = "\n".join(
        part for part in (pr_res.stderr.strip(), pr_res.stdout.strip()) if part
    )
    if ACTIONS_PR_FORBIDDEN_MSG in combined_output:
        url = _compare_url(repository, base_clean, branch_clean)
        if url:
            print(
                f"::notice::Audio safely pushed to branch '{branch_clean}' ({file_count} file(s)), "
                f"but GitHub Actions is not permitted to create pull requests. Open PR here: {url}"
            )
            summary_lines = [
                "### Voz audio pushed to branch (manual PR step)",
                "",
                f"Recorded audio ({file_count} file(s)) was safely committed and pushed to **`{branch_clean}`**.",
                "GitHub Actions is not permitted to create pull requests in this repository, so open the PR in one click:",
                "",
                f"- **Open PR:** {url}",
                f"- **Branch:** `{branch_clean}` -> `{base_clean}`",
                "",
            ]
        else:
            print(
                f"::notice::Audio safely pushed to branch '{branch_clean}' ({file_count} file(s)), "
                "but GitHub Actions is not permitted to create pull requests. "
                f"Please open a PR from '{branch_clean}' into '{base_clean}'."
            )
            summary_lines = [
                "### Voz audio pushed to branch (manual PR step)",
                "",
                f"Recorded audio ({file_count} file(s)) was safely committed and pushed to **`{branch_clean}`**.",
                f"Open a pull request from `{branch_clean}` into `{base_clean}`.",
                "",
            ]
        _append_step_summary(step_summary, "\n".join(summary_lines))
        return 0

    print(
        f"ERROR: gh pr create failed (exit {pr_res.returncode}): {combined_output}",
        file=sys.stderr,
    )
    return pr_res.returncode or 1


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    default_root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(
        description="Commit and push recorded Voz audio to a PR branch."
    )
    parser.add_argument("--repo-root", type=Path, default=default_root)
    parser.add_argument("--modo", default=os.environ.get("MODO") or "cuento")
    parser.add_argument("--base-branch", default="main")
    parser.add_argument("--branch", default=default_branch_name())
    parser.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY", ""))
    parser.add_argument(
        "--step-summary", default=os.environ.get("GITHUB_STEP_SUMMARY", "")
    )
    parser.add_argument("--dry-run", action="store_true", default=False)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    return publish_audio_pr(
        repo_root=args.repo_root,
        modo=args.modo,
        base_branch=args.base_branch,
        branch=args.branch,
        repository=args.repository,
        step_summary=args.step_summary,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    sys.exit(main())
