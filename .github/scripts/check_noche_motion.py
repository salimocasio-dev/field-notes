#!/usr/bin/env python3
"""CI guardrail enforcing Noche motion rules from docs/proyecto/24-noche-motion.md.

Checks added lines only in PR diffs (against the base ref):
  1. Fails if a PR adds `Curves.`, `Cubic(`, or `Duration(` to any Dart file
     under `coqui/packages/features/*/lib/` or `coqui/app/lib/`, other than
     that package's `lib/src/motion.dart` — unless a `Duration(` has an
     explicit `// non-motion` (or `/* non-motion */`) marker comment on the
     same line.
  2. Fails if a PR adds `NocheMotion.ms(` to any Dart file under `coqui/`
     outside `coqui/packages/core/coqui_ui/` and any package's
     `lib/src/motion.dart`.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import os
from pathlib import Path
import re
import subprocess
import sys

COQUI_UI_PREFIX = "coqui/packages/core/coqui_ui/"

# Rule 1 scope: feature lib/ and app lib/
FEATURE_OR_APP_LIB_RE = re.compile(
    r"^coqui/(?:packages/features/[^/]+|app)/lib/.+\.dart$"
)

# Exact `<pkg>/lib/src/motion.dart` for any workspace package under coqui/
PACKAGE_MOTION_FILE_RE = re.compile(
    r"^coqui/(?:app|packages/(?:(?:core|features)/)?[^/]+)/lib/src/motion\.dart$"
)

# Forbidden tokens (word-bounded so identifiers like `myDuration(` or
# `AppCurves.` do not falsely match).
RAW_CURVES_RE = re.compile(r"\bCurves\.")
RAW_CUBIC_RE = re.compile(r"\bCubic\s*\(")
RAW_DURATION_RE = re.compile(r"\bDuration\s*\(")
NOCHE_MOTION_MS_RE = re.compile(r"\bNocheMotion\.ms\s*\(")

# Non-motion marker comment body (after stripping `//` or `/* ... */` and whitespace).
# Matches e.g. `// non-motion`, `// non-motion: clip timeout`, `/* non-motion */`.
NON_MOTION_MARKER_RE = re.compile(
    r"^non-motion(?:$|\s|[:\-–—(])", re.IGNORECASE
)

HUNK_HEADER_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


@dataclass(frozen=True)
class Violation:
    path: str
    line: int
    rule: str
    token: str
    message: str
    source_line: str


@dataclass
class DiffEntry:
    old_path: str | None
    new_path: str
    added_lines: set[int]


def is_coqui_ui_path(rel_path: str) -> bool:
    return rel_path.startswith(COQUI_UI_PREFIX)


def is_package_motion_file(rel_path: str) -> bool:
    return bool(PACKAGE_MOTION_FILE_RE.match(rel_path))


def is_raw_motion_checked_path(rel_path: str) -> bool:
    """True if Rule 1 (no raw Curves./Cubic(/Duration() applies to rel_path."""
    if not FEATURE_OR_APP_LIB_RE.match(rel_path):
        return False
    return not is_package_motion_file(rel_path)


def is_ms_checked_path(rel_path: str) -> bool:
    """True if Rule 2 (no NocheMotion.ms() applies to rel_path."""
    if not (rel_path.startswith("coqui/") and rel_path.endswith(".dart")):
        return False
    if is_coqui_ui_path(rel_path):
        return False
    return not is_package_motion_file(rel_path)


def _is_ident_char(ch: str) -> bool:
    return ch.isalnum() or ch in ("_", "$")


def mask_dart_source(source: str) -> tuple[list[str], dict[int, list[str]]]:
    """Return (code_lines, comments_by_line) for a Dart source file.

    String literal text (outside `${...}` interpolations) and comments are
    replaced with spaces while preserving line breaks, so 1-based line numbers
    match the original file. Every `//` and `/* ... */` comment's body is also
    recorded per 1-based line number in `comments_by_line`.
    """
    text = source.replace("\r\n", "\n").replace("\r", "\n")
    n = len(text)
    out: list[str] = []
    comments_by_line: dict[int, list[str]] = {}

    # Stack entries:
    #   ("str", quote_str)         -> inside a non-raw string literal
    #   ("interp", brace_depth)    -> inside `${...}` interpolation of a string
    stack: list[tuple[str, object]] = []
    line = 1
    i = 0

    def add_comment(line_no: int, body: str) -> None:
        stripped = body.strip()
        if stripped:
            comments_by_line.setdefault(line_no, []).append(stripped)

    while i < n:
        ch = text[i]

        # Inside a non-raw string literal
        if stack and stack[-1][0] == "str":
            quote = str(stack[-1][1])
            qlen = len(quote)
            if ch == "\\" and i + 1 < n:
                nxt = text[i + 1]
                out.append(" ")
                if nxt == "\n":
                    out.append("\n")
                    line += 1
                else:
                    out.append(" ")
                i += 2
                continue
            if ch == "$" and i + 1 < n and text[i + 1] == "{":
                out.append(" ")
                out.append(" ")
                stack.append(("interp", 0))
                i += 2
                continue
            if text.startswith(quote, i):
                out.extend(" " * qlen)
                stack.pop()
                i += qlen
                continue
            if ch == "\n":
                out.append("\n")
                line += 1
            else:
                out.append(" ")
            i += 1
            continue

        # Code state (top-level or inside `${...}` interpolation)
        if ch == "/" and i + 1 < n and text[i + 1] == "/":
            start_line = line
            j = i + 2
            while j < n and text[j] != "\n":
                j += 1
            add_comment(start_line, text[i + 2 : j])
            out.extend(" " * (j - i))
            i = j
            continue

        if ch == "/" and i + 1 < n and text[i + 1] == "*":
            depth = 1
            out.append(" ")
            out.append(" ")
            i += 2
            seg_start = i
            seg_line = line
            while i < n and depth > 0:
                if text[i] == "/" and i + 1 < n and text[i + 1] == "*":
                    depth += 1
                    out.append(" ")
                    out.append(" ")
                    i += 2
                elif text[i] == "*" and i + 1 < n and text[i + 1] == "/":
                    if depth == 1:
                        add_comment(seg_line, text[seg_start:i])
                    depth -= 1
                    out.append(" ")
                    out.append(" ")
                    i += 2
                elif text[i] == "\n":
                    add_comment(seg_line, text[seg_start:i])
                    out.append("\n")
                    line += 1
                    i += 1
                    seg_start = i
                    seg_line = line
                else:
                    out.append(" ")
                    i += 1
            continue

        # Raw strings: r'...', r"...", r'''...''', r"""..."""
        if (
            ch == "r"
            and i + 1 < n
            and text[i + 1] in ("'", '"')
            and (i == 0 or not _is_ident_char(text[i - 1]))
        ):
            qchar = text[i + 1]
            if text.startswith(qchar * 3, i + 1):
                quote = qchar * 3
            else:
                quote = qchar
            qlen = len(quote)
            out.extend(" " * (1 + qlen))
            i += 1 + qlen
            while i < n:
                if text.startswith(quote, i):
                    out.extend(" " * qlen)
                    i += qlen
                    break
                if text[i] == "\n":
                    out.append("\n")
                    line += 1
                else:
                    out.append(" ")
                i += 1
            continue

        # Regular strings: '...', "...", '''...''', """..."""
        if ch in ("'", '"'):
            if text.startswith(ch * 3, i):
                quote = ch * 3
            else:
                quote = ch
            qlen = len(quote)
            out.extend(" " * qlen)
            stack.append(("str", quote))
            i += qlen
            continue

        # Track braces inside `${...}` interpolation
        if stack and stack[-1][0] == "interp":
            depth = int(stack[-1][1])
            if ch == "{":
                stack[-1] = ("interp", depth + 1)
                out.append(ch)
                i += 1
                continue
            if ch == "}":
                if depth == 0:
                    stack.pop()
                    out.append(" ")
                else:
                    stack[-1] = ("interp", depth - 1)
                    out.append(ch)
                i += 1
                continue

        if ch == "\n":
            out.append("\n")
            line += 1
        else:
            out.append(ch)
        i += 1

    return "".join(out).split("\n"), comments_by_line


def has_non_motion_marker(comments: list[str]) -> bool:
    return any(NON_MOTION_MARKER_RE.match(c) for c in comments)


def scan_dart_source(
    rel_path: str,
    source: str,
    added_lines: set[int],
    *,
    raw_lines_override: set[int] | None = None,
    ms_lines_override: set[int] | None = None,
) -> list[Violation]:
    """Scan added lines of a single Dart file for Noche motion violations."""
    check_raw = is_raw_motion_checked_path(rel_path)
    check_ms = is_ms_checked_path(rel_path)
    raw_target = raw_lines_override if raw_lines_override is not None else added_lines
    ms_target = ms_lines_override if ms_lines_override is not None else added_lines

    target_lines: set[int] = set()
    if check_raw:
        target_lines |= raw_target
    if check_ms:
        target_lines |= ms_target
    if not target_lines:
        return []

    raw_lines = source.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    code_lines, comments_by_line = mask_dart_source(source)
    violations: list[Violation] = []

    for line_no in sorted(target_lines):
        if line_no < 1 or line_no > len(code_lines):
            continue
        code = code_lines[line_no - 1]
        raw = raw_lines[line_no - 1]
        line_comments = comments_by_line.get(line_no, [])

        if check_raw and line_no in raw_target:
            if RAW_CURVES_RE.search(code):
                violations.append(
                    Violation(
                        path=rel_path,
                        line=line_no,
                        rule="raw-curve",
                        token="Curves.",
                        message=(
                            f"Noche motion guard: forbidden raw `Curves.` in "
                            f"{rel_path}:{line_no}. Use NocheMotion curve tokens "
                            f"from coqui_ui (page 24, Part 1.2)."
                        ),
                        source_line=raw,
                    )
                )
            if RAW_CUBIC_RE.search(code):
                violations.append(
                    Violation(
                        path=rel_path,
                        line=line_no,
                        rule="raw-cubic",
                        token="Cubic(",
                        message=(
                            f"Noche motion guard: forbidden raw `Cubic(` in "
                            f"{rel_path}:{line_no}. Use NocheMotion curve tokens "
                            f"from coqui_ui (page 24, Part 1.2)."
                        ),
                        source_line=raw,
                    )
                )
            if RAW_DURATION_RE.search(code) and not has_non_motion_marker(
                line_comments
            ):
                violations.append(
                    Violation(
                        path=rel_path,
                        line=line_no,
                        rule="raw-duration",
                        token="Duration(",
                        message=(
                            f"Noche motion guard: forbidden raw `Duration(` in "
                            f"{rel_path}:{line_no}. Use NocheMotion tokens from "
                            f"coqui_ui or a named wait in this package's "
                            f"lib/src/motion.dart. For non-motion durations "
                            f"(timeouts, clip lengths), add `// non-motion` on "
                            f"the same line."
                        ),
                        source_line=raw,
                    )
                )

        if check_ms and line_no in ms_target and NOCHE_MOTION_MS_RE.search(code):
            violations.append(
                Violation(
                    path=rel_path,
                    line=line_no,
                    rule="noche-motion-ms",
                    token="NocheMotion.ms(",
                    message=(
                        f"Noche motion guard: `NocheMotion.ms(` is only allowed "
                        f"in a package's lib/src/motion.dart (or coqui_ui), "
                        f"found in {rel_path}:{line_no} (page 24, Part 1.2 & 1.6)."
                    ),
                    source_line=raw,
                )
            )

    return violations


def parse_diff_entries(unified_diff: str) -> list[DiffEntry]:
    """Parse `git diff -U0` output into per-file DiffEntry objects."""
    entries: list[DiffEntry] = []
    cur_old: str | None = None
    cur_new: str | None = None
    cur_added: set[int] = set()
    in_file = False
    in_hunk = False

    def flush() -> None:
        nonlocal cur_old, cur_new, cur_added, in_file, in_hunk
        if in_file and cur_new is not None:
            entries.append(
                DiffEntry(
                    old_path=cur_old,
                    new_path=cur_new,
                    added_lines=set(cur_added),
                )
            )
        cur_old = None
        cur_new = None
        cur_added = set()
        in_file = False
        in_hunk = False

    for raw_line in unified_diff.splitlines():
        if raw_line.startswith("diff --git "):
            flush()
            in_file = True
            continue
        if not in_file:
            continue
        m = HUNK_HEADER_RE.match(raw_line)
        if m:
            in_hunk = True
            start = int(m.group(1))
            count = 1 if m.group(2) is None else int(m.group(2))
            if count > 0:
                cur_added.update(range(start, start + count))
            continue
        if in_hunk:
            continue
        if raw_line.startswith("rename from "):
            cur_old = raw_line[len("rename from ") :]
            continue
        if raw_line.startswith("rename to "):
            cur_new = raw_line[len("rename to ") :]
            continue
        if raw_line.startswith("copy from "):
            cur_old = raw_line[len("copy from ") :]
            continue
        if raw_line.startswith("copy to "):
            cur_new = raw_line[len("copy to ") :]
            continue
        if raw_line.startswith("--- "):
            src = raw_line[4:]
            if src == "/dev/null":
                cur_old = None
            elif src.startswith("a/"):
                cur_old = src[2:]
            continue
        if raw_line.startswith("+++ "):
            dst = raw_line[4:]
            if dst == "/dev/null":
                cur_new = None
            elif dst.startswith("b/"):
                cur_new = dst[2:]
            continue

    flush()
    return entries


def _git(repo: Path, args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )


def _git_ref_exists(repo: Path, ref: str) -> bool:
    res = _git(repo, ["rev-parse", "--verify", "--quiet", f"{ref}^{{commit}}"])
    return res.returncode == 0


def resolve_diff_base(repo: Path, base_arg: str | None) -> str:
    """Resolve the git diff base ref, matching pr_guardrails.sh semantics."""
    if base_arg:
        if _git_ref_exists(repo, base_arg):
            return base_arg
        raise RuntimeError(
            f"--base ref '{base_arg}' does not resolve to a commit."
        )

    env_base = os.environ.get("BASE_REF", "").strip()
    if env_base:
        if _git_ref_exists(repo, f"origin/{env_base}"):
            return f"origin/{env_base}"
        if _git_ref_exists(repo, env_base):
            return env_base
        raise RuntimeError(
            f"BASE_REF '{env_base}' does not resolve to origin/{env_base} or {env_base}."
        )

    if _git_ref_exists(repo, "origin/main"):
        return "origin/main"
    if _git_ref_exists(repo, "main"):
        return "main"
    raise RuntimeError("neither origin/main nor main resolves to a commit.")


def check_repo(
    repo: Path, base_arg: str | None = None
) -> tuple[list[Violation], int, int]:
    """Run the Noche motion guard against `<base>...HEAD` in `repo`.

    Returns `(violations, checked_files, checked_added_lines)`.
    """
    top = _git(repo, ["rev-parse", "--show-toplevel"])
    if top.returncode != 0:
        raise RuntimeError(
            f"not a git repository ({repo}): {top.stderr.strip()}"
        )
    repo_root = Path(top.stdout.strip())
    diff_base = resolve_diff_base(repo_root, base_arg)

    diff = _git(
        repo_root,
        [
            "-c",
            "core.quotepath=false",
            "diff",
            "--no-ext-diff",
            "-M",
            "-U0",
            "--diff-filter=AMCR",
            f"{diff_base}...HEAD",
            "--",
            "*.dart",
        ],
    )
    if diff.returncode != 0:
        raise RuntimeError(
            f"git diff {diff_base}...HEAD failed: {diff.stderr.strip()}"
        )

    entries = parse_diff_entries(diff.stdout)
    violations: list[Violation] = []
    checked_files = 0
    checked_lines = 0

    for entry in sorted(entries, key=lambda e: e.new_path):
        rel_path = entry.new_path
        check_raw = is_raw_motion_checked_path(rel_path)
        check_ms = is_ms_checked_path(rel_path)
        if not (check_raw or check_ms):
            continue

        # If a file was renamed/copied from an exempt path into a checked path,
        # all of its lines are newly entering the checked scope.
        moved_into_raw = (
            check_raw
            and entry.old_path is not None
            and entry.old_path != rel_path
            and not is_raw_motion_checked_path(entry.old_path)
        )
        moved_into_ms = (
            check_ms
            and entry.old_path is not None
            and entry.old_path != rel_path
            and not is_ms_checked_path(entry.old_path)
        )

        if not entry.added_lines and not moved_into_raw and not moved_into_ms:
            continue

        show = _git(repo_root, ["show", f"HEAD:{rel_path}"])
        if show.returncode != 0:
            raise RuntimeError(
                f"git show HEAD:{rel_path} failed: {show.stderr.strip()}"
            )

        line_count = len(
            show.stdout.replace("\r\n", "\n").replace("\r", "\n").split("\n")
        )
        all_lines = set(range(1, line_count + 1))
        raw_target = all_lines if moved_into_raw else entry.added_lines
        ms_target = all_lines if moved_into_ms else entry.added_lines

        effective_lines: set[int] = set()
        if check_raw:
            effective_lines |= raw_target
        if check_ms:
            effective_lines |= ms_target

        checked_files += 1
        checked_lines += len(effective_lines)
        violations.extend(
            scan_dart_source(
                rel_path,
                show.stdout,
                entry.added_lines,
                raw_lines_override=raw_target,
                ms_lines_override=ms_target,
            )
        )

    return violations, checked_files, checked_lines


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check PR added lines for Noche motion rule violations."
    )
    parser.add_argument(
        "--base",
        default=None,
        help="Git base ref to diff against (default: BASE_REF, origin/main, or main).",
    )
    parser.add_argument(
        "--repo",
        default=".",
        help="Path inside the git repository to check (default: current directory).",
    )
    args = parser.parse_args(argv)

    try:
        violations, checked_files, checked_lines = check_repo(
            Path(args.repo), base_arg=args.base
        )
    except RuntimeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2

    if violations:
        for v in violations:
            print(f"::error file={v.path},line={v.line}::{v.message}")
            print(f"  {v.path}:{v.line}: {v.source_line.strip()}")
        print(
            f"Noche motion guard failed: {len(violations)} violation(s) "
            f"across {checked_files} checked Dart file(s).",
            file=sys.stderr,
        )
        return 1

    print(
        f"Noche motion guard passed ({checked_lines} added line(s) checked "
        f"across {checked_files} Dart file(s))."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
