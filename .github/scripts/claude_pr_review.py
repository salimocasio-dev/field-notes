#!/usr/bin/env python3
"""Read-only PR reviewer calling the Anthropic Messages API using Python stdlib only."""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

MARKER = "<!-- coqui-claude-review -->"
BOT_LOGIN = "github-actions[bot]"
MAX_DIFF_CHARS = 55000
MAX_CHUNKS = 6

DIFF_EXCLUDES = [
    ":(exclude)*.lock",
    ":(exclude)*.png",
    ":(exclude)*.jpg",
    ":(exclude)*.mp3",
    ":(exclude)*.ttf",
    ":(exclude)coqui/ref/*",
    ":(exclude)historia/audio/*",
    ":(exclude)historia/libros/*",
]

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


def _git_commit_exists(ref: str) -> bool:
    if not ref:
        return False
    res = subprocess.run(
        ["git", "cat-file", "-e", f"{ref}^{{commit}}"],
        capture_output=True,
        text=True,
    )
    return res.returncode == 0


def _split_oversized_text(path: str, text: str, max_chars: int) -> list[str]:
    if len(text) <= max_chars:
        return [text]
    # Reserve space for the part header so every emitted piece stays <= max_chars.
    header_reserve = len(f"# File {path} (part 999/999)\n")
    body_limit = max(1, max_chars - header_reserve)
    pieces: list[str] = []
    buf: list[str] = []
    buf_len = 0
    for line in text.splitlines(keepends=True):
        if len(line) > body_limit:
            if buf:
                pieces.append("".join(buf))
                buf = []
                buf_len = 0
            for start in range(0, len(line), body_limit):
                pieces.append(line[start : start + body_limit])
            continue
        if buf_len + len(line) > body_limit and buf:
            pieces.append("".join(buf))
            buf = []
            buf_len = 0
        buf.append(line)
        buf_len += len(line)
    if buf:
        pieces.append("".join(buf))
    total = len(pieces)
    return [f"# File {path} (part {idx}/{total})\n{part}" for idx, part in enumerate(pieces, 1)]


def chunk_file_diffs(
    file_diffs: list[tuple[str, str]], max_chars: int = MAX_DIFF_CHARS
) -> list[tuple[list[str], str]]:
    """Pack per-file diffs into chunks <= max_chars without dropping any file."""
    chunks: list[tuple[list[str], str]] = []
    cur_files: list[str] = []
    cur_parts: list[str] = []
    cur_len = 0

    for path, diff_text in file_diffs:
        if not diff_text:
            continue
        segments = _split_oversized_text(path, diff_text, max_chars)
        for seg in segments:
            sep_len = 1 if cur_parts else 0
            if cur_parts and cur_len + sep_len + len(seg) > max_chars:
                chunks.append((cur_files, "\n".join(cur_parts)))
                cur_files = []
                cur_parts = []
                cur_len = 0
                sep_len = 0
            if path not in cur_files:
                cur_files.append(path)
            cur_parts.append(seg)
            cur_len += sep_len + len(seg)

    if cur_parts:
        chunks.append((cur_files, "\n".join(cur_parts)))
    return chunks


def get_diff_chunks(
    base_target: str, head_ref: str = "pr_head", max_chars: int = MAX_DIFF_CHARS
) -> tuple[list[tuple[list[str], str]], int]:
    """Return (chunks, total_chars) covering every non-excluded changed file."""
    rev_files_raw = subprocess.check_output(
        [
            "git",
            "diff",
            "--name-only",
            "-z",
            f"{base_target}...{head_ref}",
            "--",
            ".",
            *DIFF_EXCLUDES,
        ],
        text=True,
        errors="replace",
    )
    reviewable_files = [f for f in rev_files_raw.split("\0") if f]
    if not reviewable_files:
        return [], 0

    full_diff = subprocess.check_output(
        [
            "git",
            "diff",
            "--no-color",
            f"{base_target}...{head_ref}",
            "--",
            ".",
            *DIFF_EXCLUDES,
        ],
        text=True,
        errors="replace",
    )
    total_chars = len(full_diff)
    if total_chars <= max_chars:
        return [(reviewable_files, full_diff)], total_chars

    file_diffs: list[tuple[str, str]] = []
    for path in reviewable_files:
        file_diff = subprocess.check_output(
            [
                "git",
                "diff",
                "--no-color",
                f"{base_target}...{head_ref}",
                "--",
                path,
            ],
            text=True,
            errors="replace",
        )
        file_diffs.append((path, file_diff))
    return chunk_file_diffs(file_diffs, max_chars=max_chars), total_chars


def _is_none_item(text: str) -> bool:
    cleaned = re.sub(r"^[-*•\s]+", "", text).strip()
    cleaned = cleaned.strip("`*_()[]").rstrip(".").strip().lower()
    return cleaned in ("", "none", "n/a", "no blockers", "no warnings", "no notes")


def parse_review(review_text: str) -> tuple[str, list[str], list[str]]:
    """Parse (verdict, blockers, warnings) from Claude's formatted review."""
    verdict = "UNKNOWN"
    blockers: list[str] = []
    warnings: list[str] = []
    section: str | None = None

    verdict_re = re.compile(
        r"^\s*(?:[-*•]\s*)?(?:\*\*)?Verdict(?:\*\*)?\s*:\s*(?:\*\*)?(.*)$",
        re.IGNORECASE,
    )
    blockers_re = re.compile(
        r"^\s*(?:[-*•]\s*)?(?:\*\*)?Blockers(?:\*\*)?\s*:\s*(?:\*\*)?(.*)$",
        re.IGNORECASE,
    )
    warnings_re = re.compile(
        r"^\s*(?:[-*•]\s*)?(?:\*\*)?Warnings(?:\s*/\s*Notes)?(?:\*\*)?\s*:\s*(?:\*\*)?(.*)$",
        re.IGNORECASE,
    )
    heading_re = re.compile(r"^\s*#{1,6}\s+")

    for raw_line in review_text.splitlines():
        line = raw_line.strip()
        if not line:
            continue

        m = verdict_re.match(line)
        if m:
            section = None
            val = re.sub(r"[*_`]", "", m.group(1)).strip().upper()
            if val.startswith("CHANGES REQUESTED"):
                verdict = "CHANGES REQUESTED"
            elif val.startswith("APPROVE"):
                verdict = "APPROVE"
            elif val.startswith("COMMENT"):
                verdict = "COMMENT"
            continue

        m = blockers_re.match(line)
        if m:
            section = "blockers"
            inline = m.group(1).strip().strip("*").strip()
            if inline and not _is_none_item(inline):
                blockers.append(re.sub(r"^[-*•]\s*", "", inline))
            continue

        m = warnings_re.match(line)
        if m:
            section = "warnings"
            inline = m.group(1).strip().strip("*").strip()
            if inline and not _is_none_item(inline):
                warnings.append(re.sub(r"^[-*•]\s*", "", inline))
            continue

        if heading_re.match(line):
            section = None
            continue

        if section == "blockers":
            if not _is_none_item(line):
                blockers.append(re.sub(r"^[-*•]\s*", "", line))
        elif section == "warnings":
            if not _is_none_item(line):
                warnings.append(re.sub(r"^[-*•]\s*", "", line))

    return verdict, blockers, warnings


def review_has_blockers(review_text: str) -> bool:
    verdict, blockers, _ = parse_review(review_text)
    if verdict in ("CHANGES REQUESTED", "UNKNOWN"):
        return True
    return len(blockers) > 0


def merge_chunk_reviews(reviews: list[str]) -> str:
    """Combine multiple chunk reviews into one deterministic summary."""
    if len(reviews) == 1:
        return reviews[0]

    severity = {"APPROVE": 0, "COMMENT": 1, "UNKNOWN": 2, "CHANGES REQUESTED": 3}
    worst = "APPROVE"
    all_blockers: list[str] = []
    all_warnings: list[str] = []

    for r in reviews:
        v, b, w = parse_review(r)
        if severity.get(v, 2) > severity.get(worst, 0):
            worst = v
        for item in b:
            if item not in all_blockers:
                all_blockers.append(item)
        for item in w:
            if item not in all_warnings:
                all_warnings.append(item)

    if all_blockers:
        worst = "CHANGES REQUESTED"
    elif worst == "UNKNOWN":
        worst = "CHANGES REQUESTED"
        all_blockers.append("One or more review chunks returned an unparseable verdict.")

    lines = [f"- **Verdict:** {worst}"]
    if all_blockers:
        lines.append("- **Blockers:**")
        lines.extend(f"  - {item}" for item in all_blockers)
    else:
        lines.append("- **Blockers:** None")

    if all_warnings:
        lines.append("- **Warnings / Notes:**")
        lines.extend(f"  - {item}" for item in all_warnings[:5])
    else:
        lines.append("- **Warnings / Notes:** None")

    return "\n".join(lines)


def call_claude(api_key: str, model: str, user_prompt: str) -> str:
    payload = {
        "model": model,
        "max_tokens": 4096,
        "output_config": {"effort": "medium"},
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
    with urllib.request.urlopen(req, timeout=120) as resp:
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


def upsert_comment(
    repo: str, pr_number: str, token: str, body: str, head_sha: str = ""
) -> None:
    existing_id = None
    page = 1
    while True:
        comments_url = (
            f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments"
            f"?per_page=100&page={page}"
        )
        comments = gh_request(comments_url, token)
        if not comments:
            break
        for c in comments:
            author = (c.get("user") or {}).get("login")
            if author == BOT_LOGIN and MARKER in (c.get("body") or ""):
                existing_id = c["id"]
                break
        if existing_id or len(comments) < 100:
            break
        page += 1

    model_name = os.environ.get("CLAUDE_MODEL") or "claude-opus-5-5"
    commit_line = f"**Reviewed commit:** `{head_sha}`\n\n" if head_sha else "\n"
    full_body = f"{MARKER}\n### Claude API Independent Review (`{model_name}`)\n{commit_line}{body}"
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
    pr_number = os.environ["PR_NUMBER"].strip()
    if not pr_number.isdigit():
        print(f"Invalid PR_NUMBER: {pr_number!r}", file=sys.stderr)
        return 1

    base_ref = (os.environ.get("PR_BASE_REF") or os.environ.get("BASE_REF") or "").strip()
    base_sha = (os.environ.get("PR_BASE_SHA") or os.environ.get("BASE_SHA") or "").strip()
    expected_head_sha = (os.environ.get("PR_HEAD_SHA") or os.environ.get("HEAD_SHA") or "").strip()
    pr_title = os.environ.get("PR_TITLE", "")
    pr_body = os.environ.get("PR_BODY", "")[:4000]
    model = os.environ.get("CLAUDE_MODEL") or "claude-opus-5-5"

    if not base_ref and not base_sha:
        pr_url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}"
        pr_data = gh_request(pr_url, gh_token)
        head_repo = ((pr_data.get("head") or {}).get("repo") or {}).get("full_name")
        if head_repo != repo:
            print(
                f"Skipping fork PR #{pr_number} (head.repo.full_name={head_repo!r} != {repo!r}).",
                file=sys.stderr,
            )
            return 1
        base_ref = (pr_data.get("base") or {}).get("ref", "")
        base_sha = (pr_data.get("base") or {}).get("sha", "")
        if not expected_head_sha:
            expected_head_sha = (pr_data.get("head") or {}).get("sha", "")
        if not base_ref and not base_sha:
            print(f"Missing base ref for PR #{pr_number}.", file=sys.stderr)
            return 1
        if not pr_title:
            pr_title = pr_data.get("title") or ""
        if not pr_body:
            pr_body = (pr_data.get("body") or "")[:4000]

    # Never rely on checked-out HEAD for PR code; always diff against fetched pull/<n>/head.
    if not _git_commit_exists("pr_head") or (
        expected_head_sha and not _git_commit_exists(expected_head_sha)
    ):
        subprocess.run(
            ["git", "fetch", "--no-tags", "--force", "origin", f"pull/{pr_number}/head:pr_head"],
            check=True,
        )

    head_ref = expected_head_sha if _git_commit_exists(expected_head_sha) else "pr_head"
    head_sha = subprocess.check_output(["git", "rev-parse", head_ref], text=True).strip()

    if base_sha and _git_commit_exists(base_sha):
        base_target = base_sha
    else:
        if not base_ref:
            print(f"Missing base ref for PR #{pr_number}.", file=sys.stderr)
            return 1
        subprocess.run(
            [
                "git",
                "fetch",
                "--no-tags",
                "origin",
                f"+refs/heads/{base_ref}:refs/remotes/origin/{base_ref}",
            ],
            check=True,
        )
        base_target = (
            base_sha if (base_sha and _git_commit_exists(base_sha)) else f"origin/{base_ref}"
        )

    changed_files_raw = subprocess.check_output(
        ["git", "diff", "--name-only", "-z", f"{base_target}...{head_ref}"],
        text=True,
        errors="replace",
    )
    changed_files_list = [f for f in changed_files_raw.split("\0") if f]
    if not changed_files_list:
        print("No changed files to review.")
        return 0
    changed_files = "\n".join(changed_files_list)

    chunks, total_chars = get_diff_chunks(base_target, head_ref=head_ref)
    if len(chunks) > MAX_CHUNKS:
        review = (
            "- **Verdict:** CHANGES REQUESTED\n"
            "- **Blockers:**\n"
            f"  - Diff size ({total_chars:,} chars across {len(chunks)} chunks) exceeds the "
            f"{MAX_CHUNKS}-chunk review limit ({MAX_CHUNKS * MAX_DIFF_CHARS:,} chars). "
            "Split this PR into smaller changes so every file can be reviewed.\n"
            "- **Warnings / Notes:** None"
        )
        upsert_comment(repo, pr_number, gh_token, review, head_sha=head_sha)
        print("Diff exceeded reviewable chunk limit; posted blocking comment.", file=sys.stderr)
        return 1

    chunk_reviews: list[str] = []
    if not chunks:
        # Only excluded binary/ref assets changed; still review changed file list against rules.
        prompt = (
            f"PR #{pr_number}: {pr_title}\n\n"
            f"Description:\n{pr_body}\n\n"
            f"Changed files:\n{changed_files}\n\n"
            "Diff:\n--- BEGIN DIFF ---\n"
            "(All changed files matched binary/reference exclusions; review file paths and PR metadata.)\n"
            "--- END DIFF ---"
        )
        try:
            chunk_reviews.append(call_claude(api_key, model, prompt))
        except urllib.error.HTTPError as e:
            err = e.read().decode("utf-8", errors="replace")
            print(f"Claude API HTTP {e.code}: {err}", file=sys.stderr)
            return 1
    else:
        total_chunks = len(chunks)
        for idx, (chunk_files, diff_text) in enumerate(chunks, 1):
            chunk_header = (
                f"Chunk {idx} of {total_chunks} (files in this chunk: {', '.join(chunk_files)})\n\n"
                if total_chunks > 1
                else ""
            )
            prompt = (
                f"PR #{pr_number}: {pr_title}\n\n"
                f"Description:\n{pr_body}\n\n"
                f"Changed files:\n{changed_files}\n\n"
                f"{chunk_header}"
                f"Diff:\n--- BEGIN DIFF ---\n{diff_text}\n--- END DIFF ---"
            )
            try:
                chunk_reviews.append(call_claude(api_key, model, prompt))
            except urllib.error.HTTPError as e:
                err = e.read().decode("utf-8", errors="replace")
                print(f"Claude API HTTP {e.code}: {err}", file=sys.stderr)
                return 1

    review = merge_chunk_reviews(chunk_reviews)
    upsert_comment(repo, pr_number, gh_token, review, head_sha=head_sha)
    print(f"Posted/updated Claude API PR review comment for commit {head_sha}.")

    if review_has_blockers(review):
        print("Claude API review requested changes or reported blockers; failing check.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
