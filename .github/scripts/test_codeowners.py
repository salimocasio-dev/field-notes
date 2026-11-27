#!/usr/bin/env python3
"""Validate .github/CODEOWNERS syntax, root-anchoring, and path matching."""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

EXPECTED_OWNER = "@salimocasio-dev"

MUST_NOT_MATCH = (
    "coqui/packages/core/coqui_scenes/AGENTS.md",
    "coqui/app/lib/main.dart",
    "coqui/packages/core/coqui_contracts/lib/coqui_contracts.dart",
)

MUST_MATCH = (
    "AGENTS.md",
    "app/index.html",
    ".github/workflows/coqui-guardrails.yml",
    ".github/scripts/pr_guardrails.sh",
    ".agents/hooks.json",
    "CLAUDE.md",
    "GEMINI.md",
    "tool/antigravity_guard_hook.py",
    "tools/board.py",
    "tools/lanes.json",
    "tools/lanes.py",
    "coqui/BUILD",
    "coqui/tool/build_sitio.sh",
    "index.html",
    "historia/cuentos/foo.json",
    "historia/tools/gen.py",
    "historia/llamada.js",
    "historia/datos/llamadas.json",
    "historia/datos/curso.json",
    "historia/notas/danny-prompt-v3.md",
    "coqui/packages/core/coqui_platform/lib/src/call/conv.dart",
    "coqui/packages/core/coqui_platform/lib/src/web/el_conv.dart",
    "coqui/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js",
    "coqui/app/android/app/build.gradle.kts",
    "coqui/tool/check_boundaries.dart",
)

KEY_SUMMARY_PATHS = (
    ("coqui/packages/core/coqui_scenes/AGENTS.md", False),
    ("coqui/app/lib/main.dart", False),
    ("AGENTS.md", True),
    ("app/index.html", True),
)


def parse_codeowners(path: Path) -> list[tuple[int, str, list[str]]]:
    rules: list[tuple[int, str, list[str]]] = []
    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        parts = stripped.split()
        if len(parts) < 2:
            raise AssertionError(
                f"{path}:{line_no}: expected '<pattern> <owner>...', got {raw!r}"
            )
        pattern, owners = parts[0], parts[1:]
        if not pattern.startswith("/"):
            raise AssertionError(
                f"{path}:{line_no}: pattern {pattern!r} must start with '/' (repo-root anchored)"
            )
        for owner in owners:
            if not owner.startswith("@"):
                raise AssertionError(
                    f"{path}:{line_no}: owner {owner!r} must start with '@'"
                )
        rules.append((line_no, pattern, owners))
    if not rules:
        raise AssertionError(f"{path}: no CODEOWNERS rules found")
    return rules


def check_path(tmp_repo: Path, test_path: str) -> tuple[bool, str | None, int | None]:
    res = subprocess.run(
        [
            "git",
            "-C",
            str(tmp_repo),
            "-c",
            "core.excludesFile=/dev/null",
            "check-ignore",
            "-v",
            "--no-index",
            test_path,
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if res.returncode == 0:
        line = res.stdout.strip().splitlines()[0]
        # Format: .gitignore:<line>:<pattern>\t<path>
        meta, _ = line.split("\t", 1)
        _, line_str, pattern = meta.split(":", 2)
        return True, pattern, int(line_str)
    if res.returncode == 1:
        return False, None, None
    raise RuntimeError(
        f"git check-ignore failed for {test_path!r} (exit {res.returncode}): {res.stderr.strip()}"
    )


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    codeowners_path = repo_root / ".github" / "CODEOWNERS"
    if not codeowners_path.is_file():
        print(f"ERROR: missing {codeowners_path}", file=sys.stderr)
        return 1

    rules = parse_codeowners(codeowners_path)

    results: dict[str, tuple[bool, str | None, list[str]]] = {}
    errors: list[str] = []

    with tempfile.TemporaryDirectory() as tmp:
        tmp_repo = Path(tmp)
        init = subprocess.run(
            ["git", "init", "-q", str(tmp_repo)],
            capture_output=True,
            text=True,
            check=False,
        )
        if init.returncode != 0:
            raise RuntimeError(f"git init failed: {init.stderr.strip()}")

        gitignore = tmp_repo / ".gitignore"
        gitignore.write_text(
            "\n".join(pattern for _, pattern, _ in rules) + "\n",
            encoding="utf-8",
        )

        for path in MUST_NOT_MATCH:
            matched, pattern, gitignore_line = check_path(tmp_repo, path)
            owners = rules[gitignore_line - 1][2] if gitignore_line else []
            results[path] = (matched, pattern, owners)
            if matched:
                errors.append(
                    f"UNEXPECTED MATCH: {path} matched {pattern!r} ({', '.join(owners)})"
                )

        for path in MUST_MATCH:
            matched, pattern, gitignore_line = check_path(tmp_repo, path)
            owners = rules[gitignore_line - 1][2] if gitignore_line else []
            results[path] = (matched, pattern, owners)
            if not matched:
                errors.append(f"MISSING MATCH: {path} did not match any CODEOWNERS rule")
            elif EXPECTED_OWNER not in owners:
                errors.append(
                    f"WRONG OWNER: {path} matched {pattern!r} with owners {owners}, expected {EXPECTED_OWNER}"
                )

    if errors:
        for err in errors:
            print(f"ERROR: {err}", file=sys.stderr)
        return 1

    print(
        f"CODEOWNERS check passed: {len(rules)} root-anchored rules, "
        f"{len(MUST_NOT_MATCH)} non-matches, {len(MUST_MATCH)} matches ({EXPECTED_OWNER})."
    )
    for path, should_match in KEY_SUMMARY_PATHS:
        matched, pattern, owners = results[path]
        if should_match:
            print(f"  MATCH     /{path} -> {pattern} {' '.join(owners)}")
        else:
            print(f"  NO MATCH  {path} (unmatched={not matched})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
