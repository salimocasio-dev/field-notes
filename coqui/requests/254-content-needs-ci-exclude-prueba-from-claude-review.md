# 254: `content` needs CI to exclude `prueba/` from Claude PR review diff cap

## What I need
Update `.github/scripts/claude_pr_review.py`'s `DIFF_EXCLUDES` to exclude generated Flutter web build artifacts under `prueba/*` (e.g., `:(exclude)prueba/*`, or generated `main.dart.js` / `NOTICES` files) so deleting the remaining 23 static build files in `prueba/` does not overflow the 330,000-character (6-chunk) review cap.

## Why
Issue #254 (`First-version pages: keep, move or remove`) retires the public `prueba/` phone-test Flutter web build. Deleting `prueba/main.dart.js` (~1.83M chars) and `prueba/assets/NOTICES` (~1.44M chars) produced a 3,644,120-char diff that exceeded `.github/scripts/claude_pr_review.py`'s 330,000-char limit and prevented Claude API from reviewing PR #277.

## What I am using meanwhile
Replaced `prueba/index.html` with a minimal unconditional redirect to `../app/` so public access to `prueba/` is blocked immediately while keeping the remaining 23 static build files in `prueba/` untouched on disk until `DIFF_EXCLUDES` allows deleting them in a clean follow-up PR.

## Order and branch
Issue `#254`, branch `content/254` (`lane:content`).
