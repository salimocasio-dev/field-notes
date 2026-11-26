#!/usr/bin/env python3
"""Antigravity PreToolUse safety hook for Coqui.
Blocks accidental writes/staging of historia/cuentos/ (paid Azure audio trigger),
manual dispatches of voz.yml, and direct pushes to main.
Fail-open on unknown stdin formats.
"""
from __future__ import annotations

import fnmatch
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


def _repo_toplevel(cwd: str | None = None) -> str | None:
    try:
        res = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=cwd or None,
            capture_output=True,
            text=True,
            timeout=2,
        )
        if res.returncode == 0:
            return res.stdout.strip() or None
    except Exception:
        pass
    return None


def _changed_cuentos_paths(
    cwd: str | None = None,
    include_ignored: bool = False,
) -> list[str]:
    """Return repo-relative paths with uncommitted (and optionally ignored) changes under historia/cuentos/."""
    try:
        cmd = ["git", "status", "--porcelain", "-z", "-uall"]
        if include_ignored:
            cmd.append("--ignored=matching")
        cmd += ["--", ":(top)historia/cuentos"]
        res = subprocess.run(
            cmd,
            cwd=cwd or None,
            capture_output=True,
            text=True,
            timeout=2,
        )
        if res.returncode != 0 or not res.stdout:
            return []
        entries = res.stdout.split("\0")
        paths: list[str] = []
        i = 0
        while i < len(entries):
            entry = entries[i]
            if len(entry) >= 4:
                status = entry[:2]
                path = entry[3:]
                if path:
                    paths.append(path)
                # Porcelain -z emits an extra NUL-terminated source path for renames/copies.
                if "R" in status or "C" in status:
                    i += 1
            i += 1
        return paths
    except Exception:
        return []


def _historia_cuentos_has_changes(cwd: str | None = None) -> bool:
    return bool(_changed_cuentos_paths(cwd))


def _read_pathspec_file(
    pathspec_file: str,
    git_cwd: str | None,
    nul_delimited: bool = False,
) -> list[str] | None:
    """Read pathspecs from a file, returning None if stdin (`-`) or unreadable (caller fails closed)."""
    if pathspec_file == "-":
        return None
    effective_cwd = git_cwd or os.getcwd()
    full_path = (
        pathspec_file
        if os.path.isabs(pathspec_file)
        else os.path.join(effective_cwd, pathspec_file)
    )
    try:
        with open(full_path, "r", encoding="utf-8", errors="replace") as f:
            raw = f.read()
    except Exception:
        return None
    if nul_delimited:
        return [p for p in raw.split("\0") if p]
    return [line for line in raw.splitlines() if line]


def _git_add_dry_run_touches_cuentos(
    paths: list[str],
    git_cwd: str | None,
    has_all_flag: bool = False,
    has_force_flag: bool = False,
    pathspec_file: str | None = None,
    pathspec_file_nul: bool = False,
) -> bool:
    """Use Git's own pathspec engine (`git add --dry-run`) to detect cuentos matches."""
    if not paths and not pathspec_file:
        return False
    if pathspec_file == "-":
        return True
    cmd = ["git", "add", "--dry-run"]
    if has_all_flag:
        cmd.append("-A")
    if has_force_flag:
        cmd.append("-f")
    if pathspec_file:
        cmd.append(f"--pathspec-from-file={pathspec_file}")
        if pathspec_file_nul:
            cmd.append("--pathspec-file-nul")
    if paths:
        cmd += ["--"] + paths
    try:
        res = subprocess.run(
            cmd,
            cwd=git_cwd or None,
            capture_output=True,
            text=True,
            timeout=2,
        )
        combined = (res.stdout or "") + "\n" + (res.stderr or "")
        for line in combined.splitlines():
            if re.search(r"(?:^|['\"/\s])historia[/\\]cuentos(?:[/\\]|['\"\s]|$)", line):
                return True
    except Exception:
        if pathspec_file:
            return True
    return False


def _split_shell_segments(cmd: str) -> list[str]:
    return [s.strip() for s in re.split(r"(?:&&|\|\||[;\n|])", cmd) if s.strip()]


def _tokenize(segment: str) -> list[str]:
    try:
        return shlex.split(segment)
    except ValueError:
        return segment.split()


def _skip_wrappers(tokens: list[str]) -> int:
    i = 0
    while i < len(tokens) and (
        re.match(r"^[A-Za-z_][A-Za-z0-9_]*=.*", tokens[i])
        or tokens[i] in ("env", "sudo", "command")
    ):
        i += 1
    return i


def _parse_git_segment(
    tokens: list[str], current_cwd: str | None
) -> tuple[str | None, list[str], str | None]:
    """If tokens invoke git, return (subcmd, rest_tokens, git_cwd); else (None, [], current_cwd)."""
    i = _skip_wrappers(tokens)
    if i >= len(tokens) or os.path.basename(tokens[i]) != "git":
        return None, [], current_cwd
    i += 1

    git_cwd = current_cwd
    while i < len(tokens):
        tok = tokens[i]
        if tok in ("-C", "-c", "--git-dir", "--work-tree", "--namespace"):
            if tok == "-C" and i + 1 < len(tokens):
                target = tokens[i + 1]
                git_cwd = (
                    os.path.join(git_cwd, target)
                    if (git_cwd and not os.path.isabs(target))
                    else target
                )
            i += 2
            continue
        if tok.startswith("-"):
            if tok.startswith("-C") and len(tok) > 2:
                target = tok[2:]
                git_cwd = (
                    os.path.join(git_cwd, target)
                    if (git_cwd and not os.path.isabs(target))
                    else target
                )
            i += 1
            continue
        return tok, tokens[i + 1 :], git_cwd
    return None, [], git_cwd


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
            current_cwd = (
                os.path.join(current_cwd, target)
                if (current_cwd and not os.path.isabs(target))
                else target
            )
            continue

        subcmd, push_tokens, git_cwd = _parse_git_segment(tokens, current_cwd)
        if subcmd != "push":
            continue

        positional: list[str] = []
        has_tags_only = False
        skip_next = False
        value_flags = {
            "-o",
            "--push-option",
            "--repo",
            "--receive-pack",
            "--exec",
            "--recurse-submodules",
        }
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


def _is_paid_workflow_dispatch(cmd: str) -> bool:
    """Detect `gh workflow run voz.yml` (and ID/name/API dispatch equivalents)."""
    voz_targets = {"voz.yml", "voz.yaml", "voz", "417069462"}
    for seg in _split_shell_segments(cmd):
        tokens = _tokenize(seg)
        if not tokens:
            continue
        i = _skip_wrappers(tokens)
        if i >= len(tokens) or os.path.basename(tokens[i]) != "gh":
            continue
        i += 1

        # Parse gh global flags before subcommand.
        gh_args: list[str] = []
        skip_next = False
        for tok in tokens[i:]:
            if skip_next:
                skip_next = False
                continue
            if not gh_args and tok in ("-R", "--repo", "--hostname"):
                skip_next = True
                continue
            if not gh_args and tok.startswith("-"):
                continue
            gh_args.append(tok)

        if len(gh_args) >= 2 and gh_args[0] == "workflow" and gh_args[1] == "run":
            value_flags = {"-r", "--ref", "-f", "--raw-field", "-F", "--field", "-R", "--repo"}
            skip = False
            for tok in gh_args[2:]:
                if skip:
                    skip = False
                    continue
                if tok == "--":
                    continue
                if tok in value_flags:
                    skip = True
                    continue
                if tok.startswith("-"):
                    continue
                if os.path.basename(tok.strip()).lower() in voz_targets:
                    return True
        elif gh_args and gh_args[0] == "api":
            for tok in gh_args[1:]:
                if re.search(
                    r"/actions/workflows/(?:voz\.ya?ml|417069462)/dispatches",
                    tok,
                    re.IGNORECASE,
                ):
                    return True
    return False


def _is_glob_pathspec(pathspec: str) -> bool:
    return any(ch in pathspec for ch in ("*", "?", "["))


def _glob_covers_cuentos(
    pathspec: str,
    effective_cwd: str,
    cuentos_abs: str,
    repo_root: str,
    changed_paths: list[str] | None = None,
) -> bool:
    norm = pathspec.replace("\\", "/")
    is_abs = norm.startswith("/")
    parts = [p for p in norm.split("/") if p not in ("", ".")]
    static_parts: list[str] = []
    glob_parts: list[str] = []
    for idx, part in enumerate(parts):
        if _is_glob_pathspec(part):
            glob_parts = parts[idx:]
            break
        static_parts.append(part)

    if is_abs:
        prefix_raw = "/" + "/".join(static_parts)
    else:
        prefix_raw = os.path.join(effective_cwd, *static_parts) if static_parts else effective_cwd
    prefix_abs = os.path.realpath(prefix_raw)

    if prefix_abs == cuentos_abs or prefix_abs.startswith(cuentos_abs + os.sep):
        return True
    if not cuentos_abs.startswith(prefix_abs + os.sep):
        return False

    rel_cuentos = os.path.relpath(cuentos_abs, prefix_abs).replace("\\", "/")
    rel_parts = rel_cuentos.split("/")
    glob_pat = "/".join(glob_parts)
    candidates = ["/".join(rel_parts[:i]) for i in range(1, len(rel_parts) + 1)]
    if changed_paths:
        for rel_from_root in changed_paths:
            abs_p = os.path.realpath(os.path.join(repo_root, rel_from_root))
            if abs_p.startswith(prefix_abs + os.sep):
                candidates.append(os.path.relpath(abs_p, prefix_abs).replace("\\", "/"))
    else:
        candidates.append(rel_cuentos + "/story.json")
    patterns = [glob_pat]
    if glob_pat.startswith("**/"):
        patterns.append(glob_pat[3:])
    return any(
        fnmatch.fnmatchcase(cand, pat)
        for cand in candidates
        for pat in patterns
    )


def _path_covers_cuentos(
    pathspec: str,
    git_cwd: str | None,
    repo_root: str | None,
    changed_paths: list[str] | None = None,
) -> bool:
    if pathspec in ("*", ".", "./", "..", "../", "historia", "historia/", ":/", ":(top)"):
        if repo_root is None:
            return True
    if pathspec.startswith(":"):
        # Pathspec magic such as `:/` or `:(top)` unless explicitly scoped away from historia/cuentos.
        if re.search(r"exclude|!", pathspec) and re.search(r"historia[/\\]cuentos", pathspec):
            return False
        return True
    if re.search(r"(^|[/\\])historia[/\\]cuentos([/\\]|$)", pathspec):
        return True
    if _is_glob_pathspec(pathspec):
        if repo_root is None:
            return True
        effective_cwd = os.path.realpath(git_cwd or os.getcwd())
        cuentos_abs = os.path.realpath(os.path.join(repo_root, "historia", "cuentos"))
        return _glob_covers_cuentos(
            pathspec, effective_cwd, cuentos_abs, repo_root, changed_paths=changed_paths
        )
    if repo_root:
        effective_cwd = os.path.realpath(git_cwd or os.getcwd())
        target_abs = os.path.realpath(os.path.join(effective_cwd, pathspec))
        cuentos_abs = os.path.realpath(os.path.join(repo_root, "historia", "cuentos"))
        if (
            target_abs == cuentos_abs
            or cuentos_abs.startswith(target_abs + os.sep)
            or target_abs.startswith(cuentos_abs + os.sep)
        ):
            return True
    return False


def _is_broad_stage_with_cuentos_changes(cmd: str, default_cwd: str | None = None) -> bool:
    """Block `git add .` / `git add -A` (and similar broad staging) when historia/cuentos/ has changes."""
    current_cwd = default_cwd
    for seg in _split_shell_segments(cmd):
        tokens = _tokenize(seg)
        if not tokens:
            continue

        if tokens[0] == "cd" and len(tokens) >= 2 and not tokens[1].startswith("-"):
            target = tokens[1]
            current_cwd = (
                os.path.join(current_cwd, target)
                if (current_cwd and not os.path.isabs(target))
                else target
            )
            continue

        subcmd, rest, git_cwd = _parse_git_segment(tokens, current_cwd)
        if subcmd == "add":
            has_all_flag = False
            has_force_flag = False
            paths: list[str] = []
            pathspec_file: str | None = None
            pathspec_file_nul = False
            expect_pathspec_file = False
            after_double_dash = False
            skip_next = False
            value_flags = {"--chmod"}
            for tok in rest:
                if expect_pathspec_file:
                    pathspec_file = tok
                    expect_pathspec_file = False
                    continue
                if skip_next:
                    skip_next = False
                    continue
                if after_double_dash:
                    paths.append(tok)
                    continue
                if tok == "--":
                    after_double_dash = True
                    continue
                if tok == "--pathspec-from-file":
                    expect_pathspec_file = True
                    continue
                if tok.startswith("--pathspec-from-file="):
                    pathspec_file = tok.split("=", 1)[1]
                    continue
                if tok == "--pathspec-file-nul":
                    pathspec_file_nul = True
                    continue
                if tok in value_flags:
                    skip_next = True
                    continue
                if tok in ("-f", "--force"):
                    has_force_flag = True
                    continue
                if tok in ("-A", "--all", "-u", "--update", "-p", "--patch", "-i", "--interactive"):
                    has_all_flag = True
                    continue
                if tok.startswith("-") and not tok.startswith("--"):
                    flags = tok[1:]
                    if "f" in flags:
                        has_force_flag = True
                    if any(ch in flags for ch in ("A", "u", "p", "i")):
                        has_all_flag = True
                    continue
                if tok.startswith("--"):
                    continue
                paths.append(tok)

            changed_cuentos = _changed_cuentos_paths(git_cwd, include_ignored=has_force_flag)
            if not changed_cuentos:
                continue
            if expect_pathspec_file:
                return True
            effective_paths = list(paths)
            if pathspec_file is not None:
                file_paths = _read_pathspec_file(
                    pathspec_file, git_cwd, nul_delimited=pathspec_file_nul
                )
                if file_paths is None:
                    # Stdin (`-`) or unreadable pathspec file: fail closed while cuentos has changes.
                    return True
                effective_paths.extend(file_paths)
            repo_root = _repo_toplevel(git_cwd)
            covers_cuentos = (
                (has_all_flag and not effective_paths and pathspec_file is None)
                or any(
                    _path_covers_cuentos(p, git_cwd, repo_root, changed_paths=changed_cuentos)
                    for p in effective_paths
                )
                or _git_add_dry_run_touches_cuentos(
                    paths,
                    git_cwd,
                    has_all_flag=has_all_flag,
                    has_force_flag=has_force_flag,
                    pathspec_file=pathspec_file,
                    pathspec_file_nul=pathspec_file_nul,
                )
            )
            if covers_cuentos:
                return True

        elif subcmd == "commit":
            stages_all = False
            for tok in rest:
                if tok == "--":
                    break
                if tok in ("-a", "--all"):
                    stages_all = True
                    break
                if tok.startswith("-") and not tok.startswith("--") and "a" in tok[1:]:
                    stages_all = True
                    break
            if stages_all and _historia_cuentos_has_changes(git_cwd):
                return True

    return False


def _emit_allow(antigravity_protocol: bool) -> int:
    if antigravity_protocol:
        sys.stdout.write(json.dumps({"decision": "allow"}) + "\n")
    return 0


def _emit_block(reason: str, antigravity_protocol: bool) -> int:
    if antigravity_protocol:
        sys.stdout.write(json.dumps({"decision": "deny", "reason": reason}) + "\n")
        return 0
    sys.stderr.write(reason + "\n")
    return 2


def main() -> int:
    raw = sys.stdin.read().strip()
    if not raw:
        return 0
    try:
        payload = json.loads(raw)
    except Exception:
        return 0

    if not isinstance(payload, dict):
        return 0

    antigravity_protocol = (
        isinstance(payload.get("toolCall"), dict)
        or payload.get("hookEventName") == "PreToolUse"
    )
    if isinstance(payload.get("toolCall"), dict):
        args = payload["toolCall"].get("args") or {}
    else:
        args = payload.get("arguments") or payload.get("tool_input") or payload

    target_fields = []
    cmd = ""
    default_cwd = payload.get("cwd") if isinstance(payload.get("cwd"), str) else None
    if isinstance(args, dict):
        cmd = str(args.get("CommandLine") or args.get("command") or "")
        cwd_val = args.get("Cwd") or args.get("cwd")
        if isinstance(cwd_val, str) and cwd_val:
            default_cwd = cwd_val
        for k in ("Path", "TargetFile", "target_file", "path", "file_path", "CommandLine", "command"):
            v = args.get(k)
            if isinstance(v, str):
                target_fields.append(v)

    joined = "\n".join(target_fields) if target_fields else json.dumps(payload)

    if cmd:
        if _is_push_to_main(cmd, default_cwd=default_cwd):
            return _emit_block(
                "BLOCKED by Coqui hook: Never push directly to main. Use a branch and PR.",
                antigravity_protocol,
            )
        if _is_paid_workflow_dispatch(cmd):
            return _emit_block(
                "BLOCKED by Coqui hook: Running voz.yml triggers paid Azure audio jobs.",
                antigravity_protocol,
            )
        if _is_broad_stage_with_cuentos_changes(cmd, default_cwd=default_cwd):
            return _emit_block(
                "BLOCKED by Coqui hook: Broad git staging blocked while historia/cuentos/ has uncommitted changes (paid Azure audio).",
                antigravity_protocol,
            )
        if re.search(r"historia[/\\]cuentos", cmd) and (
            re.search(r"(?:>>?)\s*\S*historia[/\\]cuentos", cmd)
            or re.search(
                r"\b(rm|mv|cp|tee|sed\s+-i|python3?|git\s+add|git\s+commit|git\s+push)\b",
                cmd,
            )
        ):
            return _emit_block(
                "BLOCKED by Coqui hook: historia/cuentos/ triggers paid Azure audio jobs.",
                antigravity_protocol,
            )
    else:
        if re.search(r"historia[/\\]cuentos(?:[/\\]|$)", joined):
            return _emit_block(
                "BLOCKED by Coqui hook: Editing historia/cuentos/ is blocked (paid Azure audio).",
                antigravity_protocol,
            )

    return _emit_allow(antigravity_protocol)


if __name__ == "__main__":
    raise SystemExit(main())
