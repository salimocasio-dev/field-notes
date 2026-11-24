#!/usr/bin/env python3
"""Antigravity PreToolUse safety hook for Coqui.
Blocks accidental writes to historia/cuentos/ (paid Azure audio trigger)
and direct pushes to main. Fail-open on unknown stdin formats.
"""
import json
import re
import sys


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
    if isinstance(args, dict):
        cmd = str(args.get("CommandLine") or args.get("command") or "")
        for k in ("TargetFile", "target_file", "path", "file_path", "CommandLine", "command"):
            v = args.get(k)
            if isinstance(v, str):
                target_fields.append(v)

    joined = "\n".join(target_fields) if target_fields else json.dumps(payload)

    if cmd:
        if re.search(r"\bgit\s+push\b.*\b(origin\s+)?main\b", cmd):
            sys.stderr.write("BLOCKED by Coqui hook: Never push directly to main. Use a branch and PR.\n")
            return 2
        if "historia/cuentos" in cmd and re.search(
            r"\b(rm|mv|cp|tee|sed\s+-i|python|git\s+add|git\s+commit|git\s+push|>)\b", cmd
        ):
            sys.stderr.write("BLOCKED by Coqui hook: historia/cuentos/ triggers paid Azure audio jobs.\n")
            return 2
    else:
        if "historia/cuentos/" in joined or "historia\\cuentos\\" in joined:
            sys.stderr.write("BLOCKED by Coqui hook: Editing historia/cuentos/ is blocked (paid Azure audio).\n")
            return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
