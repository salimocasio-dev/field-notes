#!/usr/bin/env python3
"""Antigravity PreToolUse safety hook for Coqui.
Blocks accidental writes to historia/cuentos/ (paid Azure audio trigger)
and direct pushes to main. Fail-open on unknown stdin formats.
"""
import json
import os
import re
import shlex
import subprocess
import sys


def _current_branch(cwd: str | None = None) -> str | None:
    for git_args in (
        ["git", "symbolic-ref", "--short", "HEAD"],
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
    ):
        try:
            res = subprocess.run(
                git_args,
                cwd=cwd or None,
                capture_output=True,
                text=True,
                timeout=2,
            )
            if res.returncode == 0:
                return res.stdout.strip()
        except Exception:
            pass
    return None


def _split_shell_segments(cmd: str) -> list[str]:
    return [s.strip() for s in re.split(r"(?:&&|\|\||[;\n|])", cmd) if s.strip()]


def _tokenize(segment: str) -> list[str]:
    try:
        return shlex.split(segment)
    except ValueError:
        return segment.split()


def _refspec_targets_main(refspec: str, current_branch: str | None) -> bool:
    ref = refspec.lstrip("+")
    if ":" in ref:
        _, dst = ref.split(":", 1)
    else:
        dst = ref
    if dst in ("main", "refs/heads/main"):
        return True
    if dst == "HEAD" and current_branch == "main":
        return True
    return False


def _is_push_to_main(cmd: str, default_cwd: str | None = None) -> bool:
    current_cwd = default_cwd
    for seg in _split_shell_segments(cmd):
        tokens = _tokenize(seg)
        if not tokens:
            continue

        if tokens[0] == "cd" and len(tokens) >= 2 and not tokens[1].startswith("-"):
            target = tokens[1]
            current_cwd = os.path.join(current_cwd, target) if (current_cwd and not os.path.isabs(target)) else target
            continue

        i = 0
        while i < len(tokens) and (
            re.match(r"^[A-Za-z_][A-Za-z0-9_]*=.*", tokens[i])
            or tokens[i] in ("env", "sudo", "command")
        ):
            i += 1
        if i >= len(tokens):
            continue

        if os.path.basename(tokens[i]) != "git":
            continue
        i += 1

        git_cwd = current_cwd
        subcmd = None
        while i < len(tokens):
            tok = tokens[i]
            if tok in ("-C", "-c", "--git-dir", "--work-tree", "--namespace"):
                if tok == "-C" and i + 1 < len(tokens):
                    target = tokens[i + 1]
                    git_cwd = os.path.join(git_cwd, target) if (git_cwd and not os.path.isabs(target)) else target
                i += 2
                continue
            if tok.startswith("-"):
                if tok.startswith("-C") and len(tok) > 2:
                    target = tok[2:]
                    git_cwd = os.path.join(git_cwd, target) if (git_cwd and not os.path.isabs(target)) else target
                i += 1
                continue
            subcmd = tok
            i += 1
            break

        if subcmd != "push":
            continue

        push_tokens = tokens[i:]
        positional: list[str] = []
        has_tags_only = False
        skip_next = False
        value_flags = {"-o", "--push-option", "--repo", "--receive-pack", "--exec", "--recurse-submodules"}
        for tok in push_tokens:
            if skip_next:
                skip_next = False
                continue
            if tok == "--":
                continue
            if tok in value_flags:
                skip_next = True
                continue
            if tok == "--tags":
                has_tags_only = True
                continue
            if tok.startswith("-"):
                continue
            positional.append(tok)

        for pos in positional:
            if _refspec_targets_main(pos, None):
                return True

        needs_branch_check = (
            (len(positional) == 0 and not has_tags_only)
            or (len(positional) == 1 and ":" not in positional[0] and not has_tags_only)
            or any(_refspec_targets_main(p, "main") for p in positional)
        )
        if needs_branch_check and _current_branch(git_cwd) == "main":
            return True

    return False


def main() -> int:
    raw = sys.stdin.read().strip()
    if not raw:
        return 0
    try:
        payload = json.loads(raw)
    except Exception:
        return 0

    args = payload.get("arguments") or payload.get("tool_input") or payload
    target_fields = []
    cmd = ""
    default_cwd = None
    if isinstance(args, dict):
        cmd = str(args.get("CommandLine") or args.get("command") or "")
        cwd_val = args.get("Cwd") or args.get("cwd")
        if isinstance(cwd_val, str) and cwd_val:
            default_cwd = cwd_val
        for k in ("TargetFile", "target_file", "path", "file_path", "CommandLine", "command"):
            v = args.get(k)
            if isinstance(v, str):
                target_fields.append(v)

    joined = "\n".join(target_fields) if target_fields else json.dumps(payload)

    if cmd:
        if _is_push_to_main(cmd, default_cwd=default_cwd):
            sys.stderr.write("BLOCKED by Coqui hook: Never push directly to main. Use a branch and PR.\n")
            return 2
        if re.search(r"historia[/\\]cuentos", cmd) and (
            re.search(r"(?:>>?)\s*\S*historia[/\\]cuentos", cmd)
            or re.search(
                r"\b(rm|mv|cp|tee|sed\s+-i|python3?|git\s+add|git\s+commit|git\s+push)\b",
                cmd,
            )
        ):
            sys.stderr.write("BLOCKED by Coqui hook: historia/cuentos/ triggers paid Azure audio jobs.\n")
            return 2
    else:
        if re.search(r"historia[/\\]cuentos(?:[/\\]|$)", joined):
            sys.stderr.write("BLOCKED by Coqui hook: Editing historia/cuentos/ is blocked (paid Azure audio).\n")
            return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
