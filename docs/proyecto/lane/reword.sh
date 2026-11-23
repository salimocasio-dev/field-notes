#!/bin/bash
# reword.sh WORKTREE RANGE...   : sets the two closing lines on every commit of the range
cd "$1" || exit 1; shift
[ -z "$(git status --porcelain)" ] || { echo "tree not clean"; git status --short | head; exit 1; }
git filter-branch -f --commit-filter 'git commit-tree -S "$@"' --msg-filter 'python3 -c "
import sys
t=sys.stdin.read().rstrip().split(chr(10))
t=[l for l in t if not l.startswith(\"Co-Authored-By:\") and not l.startswith(\"Claude-Session:\")]
while t and not t[-1].strip(): t.pop()
print(chr(10).join(t)+chr(10)+chr(10)+\"Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>\"+chr(10)+\"Claude-Session: https://claude.ai/code/session_01XaggvvU5SXHEvuKSPNh3qh\")
"' "$@" 2>&1 | tail -2
echo "names of models in messages: $(git log --format=%B "$@" | grep -ciE 'opus|sonnet|haiku')"
echo "unsigned commits: $(for c in $(git rev-list "$@"); do git cat-file -p $c | grep -c "^gpgsig" ; done | grep -c "^0$")"
echo "old check (ignore): $(for c in $(git rev-list "$@"); do git log -1 --format=%B $c | tail -2 | grep -c 'Fable 5.2\|Claude-Session' | grep -vc '^2$'; done | grep -c 1)"
git log --oneline "$@" | cut -c1-100
