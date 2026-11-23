#!/usr/bin/env python3
"""The Coqui board, for any AI. Talks to GitHub issues through `gh api` (REST only).

  python3 tools/board.py status                 the whole board, by status
  python3 tools/board.py ready <agent>          stories you may take now (your label or agent:any, lane free)
  python3 tools/board.py claim <n> <agent>      take story n (fails if its lane is taken)
  python3 tools/board.py review <n> <agent> <pr-number>   your PR is open: story n goes to in-review
  python3 tools/board.py release <n> <agent> "<why>"     give story n back (blocked, or you stop)
  python3 tools/board.py block <n> <agent> "<question>"  story n needs Salim: one question

<agent> is claude, codex or gemini. Set COQUI_REPO to use another repo.
"""
import json
import subprocess
import sys

REPO = __import__("os").environ.get("COQUI_REPO", "salimocasio-dev/field-notes")
AGENTS = ("claude", "codex", "gemini")
STATUSES = ("status:ready", "status:claimed", "status:in-review", "status:blocked", "status:needs-salim")


def gh(method, path, fields=None):
    cmd = ["gh", "api", "-X", method, f"repos/{REPO}/{path}"]
    data = None
    if fields is not None:
        cmd += ["--input", "-"]
        data = json.dumps(fields)
    out = subprocess.run(cmd, input=data, capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"gh api {method} {path} failed: {out.stderr.strip() or out.stdout.strip()}")
    return json.loads(out.stdout) if out.stdout.strip() else None


def open_issues(label):
    items, page = [], 1
    while True:
        batch = gh("GET", f"issues?state=open&labels={label}&per_page=100&page={page}")
        items += [i for i in batch if "pull_request" not in i]
        if len(batch) < 100:
            return items
        page += 1


def labels_of(issue):
    return [l["name"] for l in issue["labels"]]


def pick(issue, prefix):
    return next((l for l in labels_of(issue) if l.startswith(prefix)), None)


def lanes_of(issue):
    """A story's lanes. Most have one; a scene port holds two (coqui_scenes and feature_story)."""
    return [l for l in labels_of(issue) if l.startswith("lane:")]


def lane_owner(lane, skip=None):
    """The claimed or in-review story holding this lane, if any."""
    for status in ("status:claimed", "status:in-review"):
        for i in open_issues(f"{lane},{status}"):
            if i["number"] != skip:
                return i
    return None


def branch_for(n, lanes):
    return f"lane/{lanes[0][5:]}/{n}" if len(lanes) == 1 else f"story/{n}"


def set_status(n, new):
    issue = gh("GET", f"issues/{n}")
    keep = [l for l in labels_of(issue) if l not in STATUSES]
    gh("PUT", f"issues/{n}/labels", {"labels": keep + [new]})


def say(n, text):
    gh("POST", f"issues/{n}/comments", {"body": text})


def need_agent(a):
    if a not in AGENTS:
        sys.exit(f"agent must be one of {', '.join(AGENTS)}")


def cmd_status():
    for status in STATUSES:
        items = open_issues(f"type:story,{status}")
        print(f"\n{status[7:].upper()} ({len(items)})")
        for i in sorted(items, key=lambda x: x["number"]):
            print(f"  #{i['number']:<4} {'+'.join(lanes_of(i)) or '-':<24} {pick(i, 'agent:') or '-':<13} {i['title']}")


def cmd_ready(agent):
    need_agent(agent)
    busy = {l for s in ("status:claimed", "status:in-review") for i in open_issues(s) for l in lanes_of(i)}
    found = 0
    for i in sorted(open_issues("type:story,status:ready"), key=lambda x: x["number"]):
        who = pick(i, "agent:")
        lanes = lanes_of(i)
        if who not in (f"agent:{agent}", "agent:any"):
            continue
        if busy.intersection(lanes):
            continue
        found += 1
        print(f"#{i['number']:<4} {'+'.join(lanes):<24} {who:<13} {i['title']}")
    if not found:
        print("Nothing for you right now. Check `status`, or review an open PR from another agent.")


def cmd_claim(n, agent):
    need_agent(agent)
    issue = gh("GET", f"issues/{n}")
    labels = labels_of(issue)
    if "status:ready" not in labels:
        sys.exit(f"#{n} is not ready ({[l for l in labels if l.startswith('status:')]}).")
    who = pick(issue, "agent:")
    if who not in (f"agent:{agent}", "agent:any"):
        sys.exit(f"#{n} is for {who}, not agent:{agent}.")
    lanes = lanes_of(issue)
    if not lanes:
        sys.exit(f"#{n} has no lane label. Ask the scrum master (Claude) to add one.")
    for lane in lanes:
        holder = lane_owner(lane)
        if holder:
            sys.exit(f"{lane} is taken by #{holder['number']} ({pick(holder, 'agent:')}). Pick another story.")
    branch = branch_for(n, lanes)
    set_status(n, "status:claimed")
    say(n, f"CLAIM {agent}\nBranch: `{branch}`")
    # Two agents can claim the same lane in the same second. The earlier claim comment wins.
    # Each issue counts by its newest claim, so an old, released claim gives no head start.
    rivals, seen = [], set()
    for i in [i for lane in lanes for i in open_issues(f"{lane},status:claimed")]:
        if i["number"] in seen:
            continue
        seen.add(i["number"])
        claims = [(c["created_at"], c["id"], i["number"])
                  for c in gh("GET", f"issues/{i['number']}/comments?per_page=100")
                  if c["body"].startswith("CLAIM ")]
        if claims:
            rivals.append(max(claims))
    rivals.sort()
    if rivals and rivals[0][2] != n:
        set_status(n, "status:ready")
        say(n, f"RELEASE {agent}\nIts lane was claimed first by #{rivals[0][2]}.")
        sys.exit(f"Lost the race to #{rivals[0][2]}. #{n} is ready again. Pick another story.")
    print(f"#{n} is yours. Work on branch {branch}, in your own clone or worktree.")


def cmd_review(n, agent, pr):
    need_agent(agent)
    set_status(n, "status:in-review")
    say(n, f"IN REVIEW {agent}\nPR #{pr}. Reviewer: an agent from a different company than {agent}.")
    print(f"#{n} is in review (PR #{pr}). The lane stays yours until the PR is merged or closed.")


def cmd_release(n, agent, why):
    need_agent(agent)
    set_status(n, "status:ready")
    say(n, f"RELEASE {agent}\n{why}")
    print(f"#{n} is ready again.")


def cmd_block(n, agent, question):
    need_agent(agent)
    set_status(n, "status:needs-salim")
    say(n, f"NEEDS SALIM ({agent})\n{question}")
    print(f"#{n} waits on Salim. Its lane is free again.")


def main(argv):
    if not argv or argv[0] in ("-h", "--help", "help"):
        print(__doc__)
        return
    c, rest = argv[0], argv[1:]
    try:
        if c == "status":
            cmd_status()
        elif c == "ready":
            cmd_ready(rest[0])
        elif c == "claim":
            cmd_claim(int(rest[0]), rest[1])
        elif c == "review":
            cmd_review(int(rest[0]), rest[1], int(rest[2]))
        elif c == "release":
            cmd_release(int(rest[0]), rest[1], rest[2])
        elif c == "block":
            cmd_block(int(rest[0]), rest[1], rest[2])
        else:
            sys.exit(f"unknown command {c}\n{__doc__}")
    except (IndexError, ValueError):
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
