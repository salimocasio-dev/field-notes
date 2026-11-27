#!/usr/bin/env python3
"""Validate tools/lanes.json and enforce branch-to-lane path boundaries for PR guardrails.

Usage:
  python3 .github/scripts/check_lanes.py [--base <ref>] [--head-ref <branch>] [--lane-map <path>]
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

_SCRIPT_REPO_ROOT = Path(__file__).resolve().parents[2]
_TOOLS_DIR = str(_SCRIPT_REPO_ROOT / "tools")
if _TOOLS_DIR not in sys.path:
    sys.path.insert(0, _TOOLS_DIR)

import lanes as lane_lib  # noqa: E402


def _git(args: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=str(cwd) if cwd is not None else None,
        capture_output=True,
        text=True,
        check=False,
    )


def _resolve_repo_root() -> Path:
    res = _git(["rev-parse", "--show-toplevel"])
    if res.returncode == 0 and res.stdout.strip():
        return Path(res.stdout.strip())
    return Path.cwd()


def _resolve_base(base_arg: str | None, repo_root: Path) -> str:
    if base_arg:
        if _git(["rev-parse", "--verify", "--quiet", f"{base_arg}^{{commit}}"], cwd=repo_root).returncode == 0:
            return base_arg
        raise RuntimeError(f"--base ref '{base_arg}' does not resolve to a commit.")

    env_base = os.environ.get("BASE_REF", "").strip()
    if env_base:
        for candidate in (f"origin/{env_base}", env_base):
            if _git(["rev-parse", "--verify", "--quiet", f"{candidate}^{{commit}}"], cwd=repo_root).returncode == 0:
                return candidate
        raise RuntimeError(f"BASE_REF '{env_base}' does not resolve to origin/{env_base} or {env_base}.")

    for candidate in ("origin/main", "main"):
        if _git(["rev-parse", "--verify", "--quiet", f"{candidate}^{{commit}}"], cwd=repo_root).returncode == 0:
            return candidate
    raise RuntimeError("neither origin/main nor main resolves to a commit.")


def _resolve_head_ref(head_ref_arg: str | None, repo_root: Path) -> str:
    if head_ref_arg:
        return head_ref_arg
    env_head = os.environ.get("HEAD_REF", "").strip()
    if env_head:
        return env_head
    res = _git(["rev-parse", "--abbrev-ref", "HEAD"], cwd=repo_root)
    if res.returncode != 0:
        raise RuntimeError(f"git rev-parse --abbrev-ref HEAD failed: {res.stderr.strip()}")
    return res.stdout.strip()


def _changed_files(base_ref: str, repo_root: Path) -> list[str]:
    mb = _git(["merge-base", "HEAD", base_ref], cwd=repo_root)
    if mb.returncode != 0 or not mb.stdout.strip():
        raise RuntimeError(f"git merge-base HEAD {base_ref} failed: {mb.stderr.strip()}")
    merge_base = mb.stdout.strip()
    diff = _git(
        [
            "-c",
            "core.quotepath=false",
            "diff",
            "--name-only",
            "--no-renames",
            "-z",
            f"{merge_base}..HEAD",
        ],
        cwd=repo_root,
    )
    if diff.returncode != 0:
        raise RuntimeError(f"git diff failed: {diff.stderr.strip()}")
    return [f for f in diff.stdout.split("\x00") if f]


def _emit_error(file_path: str | None, message: str) -> None:
    single_line = " | ".join(line.strip() for line in message.splitlines() if line.strip())
    if file_path:
        print(f"::error file={file_path}::{single_line}")
    else:
        print(f"::error::{single_line}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate tools/lanes.json and check branch lane boundaries.")
    parser.add_argument("--base", default=None, help="Git base ref (default: BASE_REF, origin/main, or main)")
    parser.add_argument("--head-ref", default=None, help="Head branch name (default: HEAD_REF or current branch)")
    parser.add_argument("--lane-map", default=None, help="Path to lanes.json (default: <repo>/tools/lanes.json)")
    args = parser.parse_args(argv)

    repo_root = _resolve_repo_root()
    lane_map_path = Path(args.lane_map) if args.lane_map else repo_root / "tools" / "lanes.json"

    try:
        lane_map = lane_lib.load_lane_map(lane_map_path, validate=True)
    except lane_lib.LaneMapError as exc:
        _emit_error("tools/lanes.json", str(exc))
        return 1

    try:
        base_ref = _resolve_base(args.base, repo_root)
        head_ref = _resolve_head_ref(args.head_ref, repo_root)
        changed = _changed_files(base_ref, repo_root)
    except RuntimeError as exc:
        _emit_error(None, str(exc))
        return 1

    resolution = lane_lib.resolve_branch(lane_map, head_ref)
    violations = lane_lib.check_changed_files(
        lane_map,
        resolution,
        changed,
        block_packages_on_unrestricted=True,
    )

    if violations:
        for file_path, message in violations:
            _emit_error(file_path, message)
        return 1

    print(
        f"Lane check passed: {head_ref} "
        f"({len(lane_map.lanes)} lanes validated, {len(changed)} changed files)."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
