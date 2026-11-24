# Coqui Parallel Package Workflow (Template)

Run in Antigravity when 2+ independent Flutter packages are ready in the same wave:

/run-workflow For each listed GitHub issue [<ISSUE_1>, <ISSUE_2>], start one subagent in an isolated Git branch worktree (workspace="branch") using model flash/hydrogen at high thinking. Each subagent must:
1. Read root AGENTS.md, coqui/AGENTS.md, its package AGENTS.md, and the GitHub issue body.
2. Edit files ONLY inside its single assigned package (or coqui/requests/ for contract requests). Never touch historia/cuentos/.
3. Run dart run tool/check_boundaries.dart, dart format, flutter analyze, and its package tests.
4. Commit to its branch, open a Draft PR referencing the issue, and return a one-line status with test results and PR URL.
Do not merge any PR; leave merging for independent review (Claude API + Codex).
