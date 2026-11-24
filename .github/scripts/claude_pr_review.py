#!/usr/bin/env python3
"""Read-only PR reviewer calling the Anthropic Messages API using Python stdlib only."""
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

MARKER = "<!-- coqui-claude-review -->"
MAX_DIFF_CHARS = 55000

SYSTEM_PROMPT = """You are an independent, read-only code and spec reviewer for Coqui (a Flutter language-learning app).
Review ONLY the provided PR metadata and diff against these non-negotiable rules:
1. Package boundaries: one branch changes one package under coqui/; feature branches must not edit coqui_contracts (must use coqui/requests/).
2. Paid-audio lock: never change historia/cuentos/ unless explicitly authorized.
3. Danny security lock: never relax ElevenLabs allowlist/origin/rate-limit or add pet names (mi amor, nene).
4. Product rules: no honor-system / "I said it" buttons, no translation pop-ups, no machine-translated lesson screens, no story screenshots reused as UI/book pictures.
5. Noche UI rules (for Flutter UI diffs): no Color(0x...) or fontFamily outside coqui_ui; use directional layout (start/end, EdgeInsetsDirectional) not left/right; no red anywhere; one orange primary action per screen; no hardcoded Spanish strings in Dart code; no sample data baked in.
6. Rename/private readiness: do not introduce new hardcoded public repo/Pages URLs without a build-time override.
7. Bugs & regressions: flag logic bugs, broken edge cases, missing tests, or security issues.

Output format (concise, phone-friendly, one point per line):
- **Verdict:** APPROVE | CHANGES REQUESTED | COMMENT
- **Blockers:** bullet list (or "None")
- **Warnings / Notes:** bullet list (max 5, only real issues — do not invent nitpicks)
"""


def get_diff(base_ref: str) -> str:
    cmd = [
        "git",
        "diff",
        "--no-color",
        f"origin/{base_ref}...HEAD",
        "--",
        ".",
        ":(exclude)*.lock",
        ":(exclude)*.png",
        ":(exclude)*.jpg",
        ":(exclude)*.mp3",
        ":(exclude)*.ttf",
        ":(exclude)coqui/ref/*",
        ":(exclude)historia/audio/*",
        ":(exclude)historia/libros/*",
    ]
    diff = subprocess.check_output(cmd, text=True, errors="replace")
    if len(diff) > MAX_DIFF_CHARS:
        diff = diff[:MAX_DIFF_CHARS] + "\n\n... [DIFF TRUNCATED AT 55,000 CHARS] ..."
    return diff


def call_claude(api_key: str, model: str, user_prompt: str) -> str:
    payload = {
        "model": model,
        "max_tokens": 1800,
        "temperature": 0,
        "system": SYSTEM_PROMPT,
        "messages": [{"role": "user", "content": user_prompt}],
    }
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    parts = [b["text"] for b in data.get("content", []) if b.get("type") == "text"]
    return "\n".join(parts).strip()


def gh_request(url: str, token: str, method: str = "GET", body: dict | None = None):
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
        },
        method=method,
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def upsert_comment(repo: str, pr_number: str, token: str, body: str) -> None:
    comments_url = f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments?per_page=100"
    comments = gh_request(comments_url, token)
    existing_id = None
    for c in comments:
        if MARKER in (c.get("body") or ""):
            existing_id = c["id"]
            break
    model_name = os.environ.get("CLAUDE_MODEL", "claude-opus-5-5")
    full_body = f"{MARKER}\n### Claude API Independent Review (`{model_name}`)\n\n{body}"
    if existing_id:
        patch_url = f"https://api.github.com/repos/{repo}/issues/comments/{existing_id}"
        gh_request(patch_url, token, method="PATCH", body={"body": full_body})
    else:
        post_url = f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments"
        gh_request(post_url, token, method="POST", body={"body": full_body})


def main() -> int:
    api_key = os.environ.get("ANTHROPIC_API_KEY", "").strip()
    if not api_key:
        print("ANTHROPIC_API_KEY secret is not configured yet; skipping Claude API review.")
        return 0

    gh_token = os.environ["GITHUB_TOKEN"]
    repo = os.environ["GITHUB_REPOSITORY"]
    pr_number = os.environ["PR_NUMBER"]
    base_ref = os.environ["BASE_REF"]
    pr_title = os.environ.get("PR_TITLE", "")
    pr_body = os.environ.get("PR_BODY", "")[:4000]
    model = os.environ.get("CLAUDE_MODEL", "claude-opus-5-5")

    changed_files = subprocess.check_output(
        ["git", "diff", "--name-only", f"origin/{base_ref}...HEAD"], text=True
    ).strip()
    if not changed_files:
        print("No changed files to review.")
        return 0

    diff = get_diff(base_ref)
    prompt = (
        f"PR #{pr_number}: {pr_title}\n\n"
        f"Description:\n{pr_body}\n\n"
        f"Changed files:\n{changed_files}\n\n"
        f"Diff:\n--- BEGIN DIFF ---\n{diff}\n--- END DIFF ---"
    )

    try:
        review = call_claude(api_key, model, prompt)
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="replace")
        print(f"Claude API HTTP {e.code}: {err}", file=sys.stderr)
        return 1

    upsert_comment(repo, pr_number, gh_token, review)
    print("Posted/updated Claude API PR review comment.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
