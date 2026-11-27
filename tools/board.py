#!/usr/bin/env python3
"""The Coqui board, for any AI. Talks to GitHub issues through `gh api` (REST only).

  python3 tools/board.py status                 the whole board, by status
  python3 tools/board.py ready <agent>          stories you may take now (your label or agent:any, lane free)
  python3 tools/board.py claim <n> <agent>      take story n (fails if its lane conflicts with a held story)
  python3 tools/board.py review <n> <agent> <pr-number>   your PR is open: story n goes to in-review
  python3 tools/board.py release <n> <agent> "<why>"     give story n back (blocked, or you stop)
  python3 tools/board.py block <n> <agent> "<question>"  story n needs Salim: one question
  python3 tools/board.py dry-run [--lane-map PATH]       in-memory concurrency/conflict proof (no GitHub calls)

<agent> is claude, codex or gemini. Set COQUI_REPO to use another repo.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

_TOOLS_DIR = str(Path(__file__).resolve().parent)
if _TOOLS_DIR not in sys.path:
    sys.path.insert(0, _TOOLS_DIR)

import lanes as lane_lib  # noqa: E402

REPO = os.environ.get("COQUI_REPO", "salimocasio-dev/field-notes")
AGENTS = ("claude", "codex", "gemini")
STATUSES = ("status:ready", "status:claimed", "status:in-review", "status:blocked", "status:needs-salim")


def load_lanes(lane_map_path=None):
    try:
        return lane_lib.load_lane_map(lane_map_path, validate=True)
    except lane_lib.LaneMapError as exc:
        sys.exit(str(exc))


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
    """A story's lane labels (e.g. ['lane:feature_words'])."""
    return [l for l in labels_of(issue) if l.startswith("lane:")]


def lane_ids_of(issue):
    """A story's lane IDs stripped of the 'lane:' prefix."""
    return [l[5:] for l in lanes_of(issue)]


def find_conflicting_holder(lane_map, candidate_lane_ids, held_issues, skip=None):
    """Return (holder_issue, candidate_lane, held_lane) for the first conflict, or None."""
    for holder in sorted(held_issues, key=lambda x: x["number"]):
        if skip is not None and holder["number"] == skip:
            continue
        conflict = lane_lib.any_lanes_conflict(lane_map, candidate_lane_ids, lane_ids_of(holder))
        if conflict is not None:
            return holder, conflict[0], conflict[1]
    return None


def held_issues_from_github():
    seen = {}
    for status in ("status:claimed", "status:in-review"):
        for issue in open_issues(status):
            seen[issue["number"]] = issue
    return list(seen.values())


def branch_for(n, lane_labels, lane_map=None):
    lm = lane_map or load_lanes()
    ids = [l[5:] if l.startswith("lane:") else l for l in lane_labels]
    return lane_lib.branch_for_lanes(lm, n, ids)


def evaluate_claim(lane_map, issue, agent, held_issues):
    """Pure claim check shared by `cmd_claim` and `cmd_dry_run`.

    Returns `(branch, None)` on success or `(None, error_message)` on rejection.
    """
    n = issue["number"]
    labels = labels_of(issue)
    if "status:ready" not in labels:
        return None, f"#{n} is not ready ({[l for l in labels if l.startswith('status:')]})."
    who = pick(issue, "agent:")
    if who not in (f"agent:{agent}", "agent:any"):
        return None, f"#{n} is for {who}, not agent:{agent}."
    lane_ids = lane_ids_of(issue)
    if not lane_ids:
        return None, f"#{n} has no lane label. Ask the scrum master (Claude) to add one."
    err = lane_lib.validate_issue_lanes(lane_map, lane_ids, labels)
    if err is not None:
        return None, f"#{n}: {err}."
    conflict = find_conflicting_holder(lane_map, lane_ids, held_issues, skip=n)
    if conflict is not None:
        holder, cand_lane, held_lane = conflict
        return None, (
            f"lane:{cand_lane} conflicts with lane:{held_lane} taken by "
            f"#{holder['number']} ({pick(holder, 'agent:')}). Pick another story."
        )
    return lane_lib.branch_for_lanes(lane_map, n, lane_ids), None


def filter_ready_stories(lane_map, agent, ready_issues, held_issues):
    """Return ready issues available to `agent` whose lanes do not conflict with `held_issues`."""
    available = []
    for issue in sorted(ready_issues, key=lambda x: x["number"]):
        who = pick(issue, "agent:")
        if who not in (f"agent:{agent}", "agent:any"):
            continue
        lane_ids = lane_ids_of(issue)
        if lane_ids and find_conflicting_holder(lane_map, lane_ids, held_issues, skip=issue["number"]) is not None:
            continue
        available.append(issue)
    return available


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
    lane_map = load_lanes()
    held = held_issues_from_github()
    ready = open_issues("type:story,status:ready")
    available = filter_ready_stories(lane_map, agent, ready, held)
    for i in available:
        who = pick(i, "agent:")
        print(f"#{i['number']:<4} {'+'.join(lanes_of(i)):<24} {who:<13} {i['title']}")
    if not available:
        print("Nothing for you right now. Check `status`, or review an open PR from another agent.")


def cmd_claim(n, agent):
    need_agent(agent)
    lane_map = load_lanes()
    issue = gh("GET", f"issues/{n}")
    held = held_issues_from_github()
    branch, err = evaluate_claim(lane_map, issue, agent, held)
    if err is not None:
        sys.exit(err)
    lane_ids = lane_ids_of(issue)
    set_status(n, "status:claimed")
    say(n, f"CLAIM {agent}\nBranch: `{branch}`")
    # Two agents can claim conflicting lanes in the same second. The earlier claim comment wins.
    # Each issue counts by its newest claim, so an old, released claim gives no head start.
    rivals, seen = [], set()
    for i in open_issues("status:claimed"):
        if i["number"] in seen:
            continue
        other_lanes = lane_ids_of(i)
        if lane_lib.any_lanes_conflict(lane_map, lane_ids, other_lanes) is None:
            continue
        seen.add(i["number"])
        claims = [
            (c["created_at"], c["id"], i["number"])
            for c in gh("GET", f"issues/{i['number']}/comments?per_page=100")
            if c["body"].startswith("CLAIM ")
        ]
        if claims:
            rivals.append(max(claims))
    rivals.sort()
    if rivals and rivals[0][2] != n:
        set_status(n, "status:ready")
        say(n, f"RELEASE {agent}\nA conflicting lane was claimed first by #{rivals[0][2]}.")
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


def _mock_issue(number, title, lane_ids, agent="any", extra_labels=()):
    labels = [
        {"name": "type:story"},
        {"name": "status:ready"},
        {"name": f"agent:{agent}"},
        *({"name": f"lane:{lid}"} for lid in lane_ids),
        *({"name": lbl} for lbl in extra_labels),
    ]
    return {"number": number, "title": title, "labels": labels}


def _claim_in_memory(lane_map, issue, agent, held):
    branch, err = evaluate_claim(lane_map, issue, agent, held)
    if err is None:
        claimed = dict(issue)
        claimed["labels"] = [
            {"name": "status:claimed" if l["name"] == "status:ready" else l["name"]}
            for l in issue["labels"]
        ]
        held.append(claimed)
    return branch, err


def cmd_dry_run(lane_map_path=None):
    lane_map = load_lanes(lane_map_path)
    failures = []

    def expect_ok(held, issue, agent):
        branch, err = _claim_in_memory(lane_map, issue, agent, held)
        if err is not None:
            failures.append(f"EXPECTED OK for #{issue['number']} ({lanes_of(issue)}): got {err}")
            print(f"  [FAIL] #{issue['number']} {'+'.join(lanes_of(issue))} ({agent}) -> {err}")
        else:
            print(f"  [OK]   #{issue['number']} {'+'.join(lanes_of(issue))} ({agent}) -> {branch}")

    def expect_blocked(held, issue, agent):
        branch, err = _claim_in_memory(lane_map, issue, agent, held)
        if err is None:
            failures.append(f"EXPECTED BLOCKED for #{issue['number']} ({lanes_of(issue)}): got {branch}")
            print(f"  [FAIL] #{issue['number']} {'+'.join(lanes_of(issue))} ({agent}) unexpectedly allowed -> {branch}")
        else:
            print(f"  [BLOCKED] #{issue['number']} {'+'.join(lanes_of(issue))} ({agent}) -> {err}")

    print(f"Lane map: {lane_map.source_path} ({len(lane_map.lanes)} lanes validated, 0 overlaps)")

    print("\n1. La fonda: 4 scenes concurrently + whole-package / duplicate mutual exclusion")
    held_fonda = []
    expect_ok(held_fonda, _mock_issue(301, "La fonda: entrada", ["scene.entrada"]), "gemini")
    expect_ok(held_fonda, _mock_issue(302, "La fonda: pedido", ["scene.pedido"]), "codex")
    expect_ok(held_fonda, _mock_issue(303, "La fonda: comida", ["scene.comida"]), "claude")
    expect_ok(held_fonda, _mock_issue(304, "La fonda: cuenta", ["scene.cuenta"]), "gemini")
    expect_blocked(held_fonda, _mock_issue(305, "Whole coqui_scenes", ["coqui_scenes"]), "claude")
    expect_blocked(held_fonda, _mock_issue(306, "Whole coqui_story_checks", ["coqui_story_checks"]), "codex")
    expect_blocked(held_fonda, _mock_issue(307, "Whole scene_port", ["scene_port"]), "gemini")
    expect_blocked(held_fonda, _mock_issue(308, "Duplicate entrada", ["scene.entrada"]), "codex")

    print("\n2a. feature_library: concurrent reader + shelf screens block whole package")
    held_lib = []
    expect_ok(held_lib, _mock_issue(401, "Library reader polish", ["feature_library.reader"]), "gemini")
    expect_ok(held_lib, _mock_issue(402, "Library shelf layout", ["feature_library.shelf"]), "codex")
    expect_blocked(held_lib, _mock_issue(403, "Whole feature_library refactor", ["feature_library"]), "claude")

    print("\n2b. feature_library: whole package blocks both screen sub-lanes")
    held_lib_whole = []
    expect_ok(held_lib_whole, _mock_issue(410, "Whole feature_library refactor", ["feature_library"]), "claude")
    expect_blocked(held_lib_whole, _mock_issue(411, "Library reader polish", ["feature_library.reader"]), "gemini")
    expect_blocked(held_lib_whole, _mock_issue(412, "Library shelf layout", ["feature_library.shelf"]), "codex")

    print("\n3. Concurrent language lanes + content parent, and design vs coqui_ui/docs")
    held_content = []
    expect_ok(held_content, _mock_issue(501, "Spanish lines", ["content.lines.es"]), "gemini")
    expect_ok(held_content, _mock_issue(502, "French lines", ["content.lines.fr"]), "codex")
    expect_ok(held_content, _mock_issue(503, "Arabic lines", ["content.lines.ar"]), "claude")
    expect_blocked(held_content, _mock_issue(504, "Whole content", ["content"]), "gemini")

    held_design = []
    expect_ok(held_design, _mock_issue(601, "Noche visual polish", ["design"]), "claude")
    expect_blocked(held_design, _mock_issue(602, "coqui_ui token edit", ["coqui_ui"]), "gemini")
    expect_blocked(held_design, _mock_issue(603, "Docs update", ["docs"]), "codex")

    if failures:
        sys.exit("dry-run failed:\n" + "\n".join(failures))
    print("\ndry-run: ok (all scenarios passed)")


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
        elif c == "dry-run":
            lane_map_path = None
            idx = 0
            while idx < len(rest):
                if rest[idx] == "--lane-map" and idx + 1 < len(rest):
                    lane_map_path = rest[idx + 1]
                    idx += 2
                else:
                    sys.exit(f"unknown argument to dry-run: {rest[idx]}\n{__doc__}")
            cmd_dry_run(lane_map_path=lane_map_path)
        else:
            sys.exit(f"unknown command {c}\n{__doc__}")
    except (IndexError, ValueError):
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
