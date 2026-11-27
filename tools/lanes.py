#!/usr/bin/env python3
"""Single-source-of-truth lane map loader, validator, and matcher for Coqui.

Reads `tools/lanes.json` and is shared by `tools/board.py` and
`.github/scripts/check_lanes.py` (invoked by `.github/scripts/pr_guardrails.sh`).
Pure Python 3 standard library only.
"""

from __future__ import annotations

import json
import re
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

_PLACEHOLDER_RE = re.compile(r"\{([A-Za-z0-9_]+)\}")
_LANE_ID_RE = re.compile(r"^[A-Za-z0-9._-]+$")
_DIGITS_RE = re.compile(r"^[0-9]+$")


class LaneMapError(ValueError):
    """Raised when tools/lanes.json fails to load or validate."""


@dataclass(frozen=True)
class Lane:
    id: str
    kind: str
    paths: tuple[str, ...]
    generated_paths: tuple[str, ...] = ()
    parents: tuple[str, ...] = ()
    spans: tuple[str, ...] = ()
    conflicts_with: tuple[str, ...] = ()
    multi_package_ok: bool = False


@dataclass(frozen=True)
class SanctionedMultiPackage:
    name: str
    combinations: tuple[tuple[str, ...], ...]
    extra_paths: tuple[str, ...] = ()
    branch_style: str = "lane"
    requires_label: str | None = None


@dataclass(frozen=True)
class BranchRules:
    lane_prefix: str
    story_prefix: str
    story_default_lane: str


@dataclass(frozen=True)
class LaneMap:
    version: int
    shared_paths: tuple[str, ...]
    package_root_prefix: str
    multi_package_label: str
    branch_rules: BranchRules
    generated_path_groups: dict[str, tuple[str, ...]]
    sanctioned_multi_package: dict[str, SanctionedMultiPackage]
    lanes: dict[str, Lane]
    source_path: Path | None = None


@dataclass(frozen=True)
class BranchResolution:
    branch: str
    restricted: bool
    lane_ids: tuple[str, ...] = ()
    allowed_paths: tuple[str, ...] = ()
    generated_paths: tuple[str, ...] = ()
    shared_paths: tuple[str, ...] = ()
    error: str | None = None

    @property
    def all_allowed_patterns(self) -> tuple[str, ...]:
        return _dedupe((*self.allowed_paths, *self.generated_paths, *self.shared_paths))


def default_lane_map_path() -> Path:
    return Path(__file__).resolve().with_name("lanes.json")


def _dedupe(items: Iterable[str]) -> tuple[str, ...]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            out.append(item)
    return tuple(out)


# ---------------------------------------------------------------------------
# Pattern validation, matching, and exact regular-language overlap detection
# ---------------------------------------------------------------------------


def validate_pattern(pattern: str) -> str | None:
    """Validate a repo-relative glob pattern. Returns an error string or None."""
    if not isinstance(pattern, str) or not pattern:
        return "pattern must be a non-empty string"
    if "\\" in pattern:
        return f"pattern {pattern!r} must use POSIX '/' separators, not '\\'"
    if pattern.startswith("/"):
        return f"pattern {pattern!r} must not start with '/'"
    if pattern.endswith("/"):
        return f"pattern {pattern!r} must not end with '/' (use '/**' for directories)"
    segments = pattern.split("/")
    for idx, seg in enumerate(segments):
        if not seg:
            return f"pattern {pattern!r} contains an empty path segment"
        if seg in (".", ".."):
            return f"pattern {pattern!r} contains disallowed segment {seg!r}"
        if "**" in seg:
            if seg != "**":
                return f"pattern {pattern!r} uses '**' inside segment {seg!r}; only trailing '/**' is allowed"
            if idx != len(segments) - 1 or len(segments) < 2:
                return f"pattern {pattern!r} may only use '**' as a trailing '/**'"
    return None


def _match_segment(pat_seg: str, val_seg: str) -> bool:
    if "*" not in pat_seg:
        return pat_seg == val_seg
    parts = [re.escape(part) for part in pat_seg.split("*")]
    regex = "^" + "[^/]*".join(parts) + "$"
    return re.match(regex, val_seg) is not None


def match_pattern(pattern: str, path: str) -> bool:
    """Return True if repo-relative file path matches pattern."""
    if not path or path.startswith("/") or path.endswith("/") or "\\" in path:
        return False
    p_segs = pattern.split("/")
    f_segs = path.split("/")
    if any(not s or s in (".", "..") for s in f_segs):
        return False
    if p_segs[-1] == "**":
        prefix = p_segs[:-1]
        if len(f_segs) <= len(prefix):
            return False
        return all(_match_segment(p, f) for p, f in zip(prefix, f_segs))
    if len(f_segs) != len(p_segs):
        return False
    return all(_match_segment(p, f) for p, f in zip(p_segs, f_segs))


def _next_seg_kind(kind: int, ch: str) -> int:
    # 0 = "", 1 = ".", 2 = "..", 3 = valid non-dot-dot non-empty segment
    if kind == 0:
        return 1 if ch == "." else 3
    if kind == 1:
        return 2 if ch == "." else 3
    return 3


def segment_overlap(pat1: str, pat2: str) -> str | None:
    """Return a concrete valid segment matching both single-segment patterns, or None."""
    if "*" not in pat1 and "*" not in pat2:
        return pat1 if pat1 == pat2 and pat1 not in ("", ".", "..") else None
    if pat1 and pat2:
        if pat1[0] != "*" and pat2[0] != "*" and pat1[0] != pat2[0]:
            return None
        if pat1[-1] != "*" and pat2[-1] != "*" and pat1[-1] != pat2[-1]:
            return None
    n1, n2 = len(pat1), len(pat2)
    start = (0, 0, 0)
    queue: deque[tuple[tuple[int, int, int], str]] = deque([(start, "")])
    visited: set[tuple[int, int, int]] = {start}

    def enqueue(state: tuple[int, int, int], witness: str) -> None:
        if state not in visited:
            visited.add(state)
            queue.append((state, witness))

    while queue:
        (i, j, kind), witness = queue.popleft()
        if i == n1 and j == n2 and kind == 3:
            return witness

        # Epsilon transitions for '*' matching zero characters.
        if i < n1 and pat1[i] == "*":
            enqueue((i + 1, j, kind), witness)
        if j < n2 and pat2[j] == "*":
            enqueue((i, j + 1, kind), witness)

        # Single-character transitions.
        if i < n1 and j < n2:
            c1, c2 = pat1[i], pat2[j]
            if c1 != "*" and c2 != "*":
                if c1 == c2:
                    enqueue((i + 1, j + 1, _next_seg_kind(kind, c1)), witness + c1)
            elif c1 == "*" and c2 != "*":
                enqueue((i, j + 1, _next_seg_kind(kind, c2)), witness + c2)
            elif c1 != "*" and c2 == "*":
                enqueue((i + 1, j, _next_seg_kind(kind, c1)), witness + c1)
            else:
                # Both are '*': emit a concrete non-dot char 'x'.
                enqueue((i, j, _next_seg_kind(kind, "x")), witness + "x")

    return None


def _concrete_segment(pat_seg: str) -> str:
    stripped = pat_seg.replace("*", "")
    if stripped not in ("", ".", ".."):
        return stripped
    # Replace the first '*' with 'x' and drop remaining '*'.
    return pat_seg.replace("*", "x", 1).replace("*", "")


@dataclass(frozen=True)
class _ParsedPattern:
    raw: str
    segs: tuple[str, ...]
    rec: bool
    has_star: tuple[bool, ...]


def _parse_pattern(pattern: str) -> _ParsedPattern:
    parts = pattern.split("/")
    rec = parts[-1] == "**"
    segs = tuple(parts[:-1] if rec else parts)
    return _ParsedPattern(
        raw=pattern,
        segs=segs,
        rec=rec,
        has_star=tuple("*" in s for s in segs),
    )


def _parsed_patterns_overlap(p1: _ParsedPattern, p2: _ParsedPattern) -> str | None:
    a, b = p1.segs, p2.segs
    na, nb = len(a), len(b)
    if not p1.rec and not p2.rec:
        if na != nb:
            return None
        k = na
    elif p1.rec and not p2.rec:
        if nb <= na:
            return None
        k = na
    elif not p1.rec and p2.rec:
        if na <= nb:
            return None
        k = nb
    else:
        k = na if na < nb else nb

    # Fast rejection from the deepest shared segment backwards (filenames differ most often).
    ha, hb = p1.has_star, p2.has_star
    for i in range(k - 1, -1, -1):
        if not ha[i] and not hb[i] and a[i] != b[i]:
            return None

    witness: list[str] = []
    for i in range(k):
        if not ha[i] and not hb[i]:
            witness.append(a[i])
        else:
            w = segment_overlap(a[i], b[i])
            if w is None:
                return None
            witness.append(w)

    if not p1.rec and not p2.rec:
        return "/".join(witness)
    if p1.rec and not p2.rec:
        for seg2 in b[na:]:
            witness.append(_concrete_segment(seg2))
        return "/".join(witness)
    if not p1.rec and p2.rec:
        for seg1 in a[nb:]:
            witness.append(_concrete_segment(seg1))
        return "/".join(witness)

    longer = a if na >= nb else b
    for seg in longer[k:]:
        witness.append(_concrete_segment(seg))
    witness.append("file")
    return "/".join(witness)


def patterns_overlap(p1: str, p2: str) -> str | None:
    """Exact regular-language overlap check.

    Returns a concrete witness file path matching both `p1` and `p2`, or None
    if the two patterns are provably disjoint.
    """
    return _parsed_patterns_overlap(_parse_pattern(p1), _parse_pattern(p2))


# ---------------------------------------------------------------------------
# Loading and validation
# ---------------------------------------------------------------------------


def _expand_template_path(template_path: str, params: dict[str, str], lane_id: str, errors: list[str]) -> str:
    def repl(match: re.Match[str]) -> str:
        key = match.group(1)
        if key not in params:
            errors.append(f"lane {lane_id!r}: template path {template_path!r} references missing param {key!r}")
            return match.group(0)
        return params[key]

    return _PLACEHOLDER_RE.sub(repl, template_path)


def _as_str_list(obj: object, field: str, errors: list[str], *, allow_empty: bool = True) -> list[str]:
    if not isinstance(obj, list) or not all(isinstance(x, str) for x in obj):
        errors.append(f"{field} must be a list of strings")
        return []
    if not allow_empty and not obj:
        errors.append(f"{field} must be a non-empty list of strings")
    return list(obj)


def parse_lane_map(data: object, *, source_path: Path | None = None) -> tuple[LaneMap | None, list[str]]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return None, ["lane map root must be a JSON object"]

    version = data.get("version")
    if version != 1 or isinstance(version, bool):
        errors.append(f"unsupported lane map version {version!r}; expected 1")

    shared_paths = tuple(_as_str_list(data.get("shared_paths", []), "shared_paths", errors))
    package_root_prefix = data.get("package_root_prefix")
    if not isinstance(package_root_prefix, str) or not package_root_prefix.endswith("/") or package_root_prefix.startswith("/"):
        errors.append("package_root_prefix must be a non-empty relative path ending with '/'")
        package_root_prefix = "coqui/packages/"

    multi_package_label = data.get("multi_package_label")
    if not isinstance(multi_package_label, str) or not multi_package_label:
        errors.append("multi_package_label must be a non-empty string")
        multi_package_label = "multi-package-ok"

    raw_branch_rules = data.get("branch_rules")
    if not isinstance(raw_branch_rules, dict):
        errors.append("branch_rules must be an object")
        branch_rules = BranchRules("lane/", "story/", "scene_port")
    else:
        lane_prefix = raw_branch_rules.get("lane_prefix")
        story_prefix = raw_branch_rules.get("story_prefix")
        story_default_lane = raw_branch_rules.get("story_default_lane")
        if not isinstance(lane_prefix, str) or not lane_prefix.endswith("/"):
            errors.append("branch_rules.lane_prefix must be a string ending with '/'")
            lane_prefix = "lane/"
        if not isinstance(story_prefix, str) or not story_prefix.endswith("/"):
            errors.append("branch_rules.story_prefix must be a string ending with '/'")
            story_prefix = "story/"
        if not isinstance(story_default_lane, str) or not story_default_lane:
            errors.append("branch_rules.story_default_lane must be a non-empty string")
            story_default_lane = ""
        branch_rules = BranchRules(lane_prefix, story_prefix, story_default_lane)

    raw_gen_groups = data.get("generated_path_groups", {})
    generated_path_groups: dict[str, tuple[str, ...]] = {}
    if not isinstance(raw_gen_groups, dict):
        errors.append("generated_path_groups must be an object")
    else:
        for group_name, group_paths in raw_gen_groups.items():
            if not isinstance(group_name, str) or not group_name:
                errors.append("generated_path_groups keys must be non-empty strings")
                continue
            generated_path_groups[group_name] = tuple(
                _as_str_list(group_paths, f"generated_path_groups.{group_name}", errors, allow_empty=False)
            )

    raw_templates = data.get("templates", {})
    if not isinstance(raw_templates, dict):
        errors.append("templates must be an object")
        raw_templates = {}

    raw_lanes = data.get("lanes")
    lanes: dict[str, Lane] = {}
    if not isinstance(raw_lanes, dict) or not raw_lanes:
        errors.append("lanes must be a non-empty object")
    else:
        for lane_id, raw_lane in raw_lanes.items():
            if not isinstance(lane_id, str) or not _LANE_ID_RE.match(lane_id):
                errors.append(f"invalid lane id {lane_id!r} (allowed: letters, digits, '.', '_', '-')")
                continue
            if not isinstance(raw_lane, dict):
                errors.append(f"lane {lane_id!r} must be an object")
                continue

            tmpl_name = raw_lane.get("template")
            tmpl: dict[str, object] = {}
            params: dict[str, str] = {}
            if tmpl_name is not None:
                if not isinstance(tmpl_name, str) or tmpl_name not in raw_templates:
                    errors.append(f"lane {lane_id!r}: unknown template {tmpl_name!r}")
                elif not isinstance(raw_templates[tmpl_name], dict):
                    errors.append(f"template {tmpl_name!r} must be an object")
                else:
                    tmpl = raw_templates[tmpl_name]
                raw_params = raw_lane.get("params", {})
                if not isinstance(raw_params, dict):
                    errors.append(f"lane {lane_id!r}.params must be an object")
                else:
                    for pk, pv in raw_params.items():
                        if not isinstance(pk, str) or not isinstance(pv, str) or not pv or "/" in pv or "\\" in pv:
                            errors.append(f"lane {lane_id!r}.params[{pk!r}] must be a non-empty single-segment string")
                        else:
                            params[pk] = pv

            kind = raw_lane.get("kind", tmpl.get("kind"))
            if not isinstance(kind, str) or not kind:
                errors.append(f"lane {lane_id!r}.kind must be a non-empty string")
                kind = ""

            raw_parents = raw_lane.get("parents", tmpl.get("parents", []))
            parents = tuple(_as_str_list(raw_parents, f"lanes.{lane_id}.parents", errors))

            raw_spans = raw_lane.get("spans", tmpl.get("spans", []))
            spans = tuple(_as_str_list(raw_spans, f"lanes.{lane_id}.spans", errors))

            raw_conflicts = raw_lane.get("conflicts_with", tmpl.get("conflicts_with", []))
            conflicts_with = tuple(_as_str_list(raw_conflicts, f"lanes.{lane_id}.conflicts_with", errors))

            multi_ok = raw_lane.get("multi_package_ok", tmpl.get("multi_package_ok", False))
            if not isinstance(multi_ok, bool):
                errors.append(f"lanes.{lane_id}.multi_package_ok must be a boolean")
                multi_ok = False

            gen_group = raw_lane.get("generated_group", tmpl.get("generated_group"))
            generated_paths: tuple[str, ...] = ()
            if gen_group is not None:
                if not isinstance(gen_group, str) or gen_group not in generated_path_groups:
                    errors.append(f"lanes.{lane_id}.generated_group references unknown group {gen_group!r}")
                else:
                    generated_paths = generated_path_groups[gen_group]

            raw_paths = raw_lane.get("paths")
            if raw_paths is None:
                tmpl_paths = _as_str_list(tmpl.get("paths", []), f"templates.{tmpl_name}.paths", errors, allow_empty=False)
                expanded_paths = [_expand_template_path(p, params, lane_id, errors) for p in tmpl_paths]
            else:
                expanded_paths = _as_str_list(raw_paths, f"lanes.{lane_id}.paths", errors, allow_empty=False)

            lanes[lane_id] = Lane(
                id=lane_id,
                kind=kind,
                paths=tuple(expanded_paths),
                generated_paths=generated_paths,
                parents=parents,
                spans=spans,
                conflicts_with=conflicts_with,
                multi_package_ok=multi_ok,
            )

    raw_sanctioned = data.get("sanctioned_multi_package", {})
    sanctioned_multi_package: dict[str, SanctionedMultiPackage] = {}
    if not isinstance(raw_sanctioned, dict):
        errors.append("sanctioned_multi_package must be an object")
    else:
        for rule_name, raw_rule in raw_sanctioned.items():
            if not isinstance(rule_name, str) or not rule_name:
                errors.append("sanctioned_multi_package keys must be non-empty strings")
                continue
            if not isinstance(raw_rule, dict):
                errors.append(f"sanctioned_multi_package.{rule_name} must be an object")
                continue
            raw_combos = raw_rule.get("combinations")
            combos: list[tuple[str, ...]] = []
            if not isinstance(raw_combos, list) or not raw_combos:
                errors.append(f"sanctioned_multi_package.{rule_name}.combinations must be a non-empty list")
            else:
                for idx, combo in enumerate(raw_combos):
                    combo_list = _as_str_list(
                        combo,
                        f"sanctioned_multi_package.{rule_name}.combinations[{idx}]",
                        errors,
                        allow_empty=False,
                    )
                    if combo_list:
                        combos.append(tuple(sorted(combo_list)))
            extra_paths = tuple(_as_str_list(raw_rule.get("extra_paths", []), f"sanctioned_multi_package.{rule_name}.extra_paths", errors))
            branch_style = raw_rule.get("branch_style", "lane")
            if branch_style not in ("lane", "story"):
                errors.append(f"sanctioned_multi_package.{rule_name}.branch_style must be 'lane' or 'story', got {branch_style!r}")
                branch_style = "lane"
            req_label = raw_rule.get("requires_label")
            if req_label is not None and (not isinstance(req_label, str) or not req_label):
                errors.append(f"sanctioned_multi_package.{rule_name}.requires_label must be null or a non-empty string")
                req_label = None
            sanctioned_multi_package[rule_name] = SanctionedMultiPackage(
                name=rule_name,
                combinations=tuple(combos),
                extra_paths=extra_paths,
                branch_style=branch_style,
                requires_label=req_label,
            )

    lane_map = LaneMap(
        version=version if isinstance(version, int) else 0,
        shared_paths=shared_paths,
        package_root_prefix=package_root_prefix,
        multi_package_label=multi_package_label,
        branch_rules=branch_rules,
        generated_path_groups=generated_path_groups,
        sanctioned_multi_package=sanctioned_multi_package,
        lanes=lanes,
        source_path=source_path,
    )
    return lane_map, errors


def ancestors_of(lane_map: LaneMap, lane_id: str) -> set[str]:
    """Return transitive parents of `lane_id` (excluding `lane_id` itself)."""
    result: set[str] = set()
    stack = list(lane_map.lanes[lane_id].parents) if lane_id in lane_map.lanes else []
    while stack:
        cur = stack.pop()
        if cur == lane_id or cur in result:
            continue
        result.add(cur)
        if cur in lane_map.lanes:
            stack.extend(lane_map.lanes[cur].parents)
    return result


def are_declared_exclusive(lane_map: LaneMap, lane_a: str, lane_b: str) -> bool:
    """True if lane_a and lane_b are declared mutually exclusive in the lane graph."""
    if lane_a == lane_b:
        return True
    a = lane_map.lanes[lane_a]
    b = lane_map.lanes[lane_b]
    anc_a = ancestors_of(lane_map, lane_a)
    anc_b = ancestors_of(lane_map, lane_b)
    if lane_a in anc_b or lane_b in anc_a:
        return True
    spans_a = set(a.spans)
    spans_b = set(b.spans)
    if lane_b in spans_a or bool(spans_a & anc_b):
        return True
    if lane_a in spans_b or bool(spans_b & anc_a):
        return True
    if lane_b in a.conflicts_with or lane_a in b.conflicts_with:
        return True
    return False


def validate_lane_map(lane_map: LaneMap) -> list[str]:
    """Validate references, pattern syntax, parent acyclicity, and concurrent-lane non-overlap."""
    errors: list[str] = []
    invalid_patterns: set[str] = set()

    def check_pat(pat: str, where: str) -> None:
        err = validate_pattern(pat)
        if err is not None:
            errors.append(f"{where}: {err}")
            invalid_patterns.add(pat)

    for p in lane_map.shared_paths:
        check_pat(p, "shared_paths")

    for gname, gpaths in lane_map.generated_path_groups.items():
        for p in gpaths:
            check_pat(p, f"generated_path_groups.{gname}")

    if lane_map.branch_rules.story_default_lane not in lane_map.lanes:
        errors.append(
            f"branch_rules.story_default_lane references unknown lane {lane_map.branch_rules.story_default_lane!r}"
        )

    for rule_name, rule in lane_map.sanctioned_multi_package.items():
        for combo in rule.combinations:
            for lid in combo:
                if lid not in lane_map.lanes:
                    errors.append(f"sanctioned_multi_package.{rule_name} references unknown lane {lid!r}")
        for p in rule.extra_paths:
            check_pat(p, f"sanctioned_multi_package.{rule_name}.extra_paths")

    for lane_id, lane in lane_map.lanes.items():
        if not lane.paths:
            errors.append(f"lanes.{lane_id}.paths must be non-empty")
        for p in lane.paths:
            check_pat(p, f"lanes.{lane_id}.paths")
        for parent in lane.parents:
            if parent == lane_id:
                errors.append(f"lanes.{lane_id}.parents cannot reference itself")
            elif parent not in lane_map.lanes:
                errors.append(f"lanes.{lane_id}.parents references unknown lane {parent!r}")
        for span in lane.spans:
            if span == lane_id:
                errors.append(f"lanes.{lane_id}.spans cannot reference itself")
            elif span not in lane_map.lanes:
                errors.append(f"lanes.{lane_id}.spans references unknown lane {span!r}")
        for other in lane.conflicts_with:
            if other == lane_id:
                errors.append(f"lanes.{lane_id}.conflicts_with cannot reference itself")
            elif other not in lane_map.lanes:
                errors.append(f"lanes.{lane_id}.conflicts_with references unknown lane {other!r}")

    # Detect parent cycles via 3-color DFS.
    color: dict[str, int] = {}  # 0=unvisited, 1=visiting, 2=done

    def dfs_cycle(lid: str, trail: list[str]) -> None:
        color[lid] = 1
        for parent in lane_map.lanes[lid].parents:
            if parent not in lane_map.lanes:
                continue
            state = color.get(parent, 0)
            if state == 1:
                cycle = " -> ".join(trail[trail.index(parent) :] + [parent])
                errors.append(f"parent cycle detected: {cycle}")
            elif state == 0:
                dfs_cycle(parent, trail + [parent])
        color[lid] = 2

    for lane_id in lane_map.lanes:
        if color.get(lane_id, 0) == 0:
            dfs_cycle(lane_id, [lane_id])

    # Pairwise overlap check across all distinct lanes not declared mutually exclusive.
    lane_ids = list(lane_map.lanes.keys())
    ancestors_cache = {lid: ancestors_of(lane_map, lid) for lid in lane_ids}

    def declared_excl(lid_a: str, lid_b: str) -> bool:
        a = lane_map.lanes[lid_a]
        b = lane_map.lanes[lid_b]
        anc_a = ancestors_cache[lid_a]
        anc_b = ancestors_cache[lid_b]
        if lid_a in anc_b or lid_b in anc_a:
            return True
        if lid_b in a.spans or any(s in anc_b for s in a.spans):
            return True
        if lid_a in b.spans or any(s in anc_a for s in b.spans):
            return True
        if lid_b in a.conflicts_with or lid_a in b.conflicts_with:
            return True
        return False

    parsed_by_lane = {
        lid: [_parse_pattern(p) for p in lane_map.lanes[lid].paths if p not in invalid_patterns]
        for lid in lane_ids
    }

    for i in range(len(lane_ids)):
        lid_a = lane_ids[i]
        valid_a = parsed_by_lane[lid_a]
        for j in range(i + 1, len(lane_ids)):
            lid_b = lane_ids[j]
            if declared_excl(lid_a, lid_b):
                continue
            valid_b = parsed_by_lane[lid_b]
            found_overlap = False
            for pa in valid_a:
                for pb in valid_b:
                    witness = _parsed_patterns_overlap(pa, pb)
                    if witness is not None:
                        errors.append(
                            f"overlapping concurrent lanes {lid_a!r} and {lid_b!r}: "
                            f"patterns {pa.raw!r} and {pb.raw!r} both match {witness!r}"
                        )
                        found_overlap = True
                        break
                if found_overlap:
                    break

    return errors


def load_lane_map(path: str | Path | None = None, *, validate: bool = True) -> LaneMap:
    """Load `tools/lanes.json` (or custom path), optionally validating schema & overlaps."""
    file_path = Path(path) if path is not None else default_lane_map_path()
    if not file_path.is_file():
        raise LaneMapError(f"missing lane map file: {file_path}")
    try:
        raw = json.loads(file_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise LaneMapError(f"invalid JSON in {file_path}: {exc}") from exc

    lane_map, parse_errors = parse_lane_map(raw, source_path=file_path)
    all_errors = list(parse_errors)
    if lane_map is not None and validate:
        all_errors.extend(validate_lane_map(lane_map))
    if all_errors:
        joined = "\n  - ".join(all_errors)
        raise LaneMapError(f"invalid lane map {file_path}:\n  - {joined}")
    assert lane_map is not None
    return lane_map


# ---------------------------------------------------------------------------
# Conflict detection, multi-package sanctioning, and branch resolution
# ---------------------------------------------------------------------------


def lanes_conflict(lane_map: LaneMap, lane_a: str, lane_b: str) -> bool:
    """True if lane_a and lane_b cannot be held concurrently."""
    if lane_a == lane_b:
        return True
    if lane_a not in lane_map.lanes or lane_b not in lane_map.lanes:
        return False
    if are_declared_exclusive(lane_map, lane_a, lane_b):
        return True
    for pa in lane_map.lanes[lane_a].paths:
        for pb in lane_map.lanes[lane_b].paths:
            if patterns_overlap(pa, pb) is not None:
                return True
    return False


def any_lanes_conflict(
    lane_map: LaneMap, lanes_a: Iterable[str], lanes_b: Iterable[str]
) -> tuple[str, str] | None:
    """Return the first conflicting (lane_a, lane_b) pair, or None if concurrent."""
    list_b = list(lanes_b)
    for la in lanes_a:
        for lb in list_b:
            if lanes_conflict(lane_map, la, lb):
                return (la, lb)
    return None


def touched_packages(lane_map: LaneMap, lane_id: str) -> set[str]:
    """Return all `kind == 'package'` lane IDs whose paths overlap `lane_id.paths`."""
    if lane_id not in lane_map.lanes:
        return set()
    lane = lane_map.lanes[lane_id]
    pkgs: set[str] = set()
    for pkg_id, pkg_lane in lane_map.lanes.items():
        if pkg_lane.kind != "package":
            continue
        if any(patterns_overlap(p1, p2) is not None for p1 in lane.paths for p2 in pkg_lane.paths):
            pkgs.add(pkg_id)
    return pkgs


def find_sanctioned_multi_package(
    lane_map: LaneMap, lane_ids: Iterable[str]
) -> SanctionedMultiPackage | None:
    target = tuple(sorted(lane_ids))
    for rule in lane_map.sanctioned_multi_package.values():
        if target in rule.combinations:
            return rule
    return None


def validate_issue_lanes(
    lane_map: LaneMap,
    lane_ids: Sequence[str],
    issue_labels: Iterable[str],
) -> str | None:
    """Validate an issue's lane IDs and required multi-package labels. Returns error or None."""
    if not lane_ids:
        return "story has no lane label"
    if len(set(lane_ids)) != len(lane_ids):
        return f"story has duplicate lane labels: {list(lane_ids)}"
    unknown = [lid for lid in lane_ids if lid not in lane_map.lanes]
    if unknown:
        return f"unknown lane(s) {', '.join(repr(u) for u in unknown)} (not in tools/lanes.json)"

    all_pkgs: set[str] = set()
    for lid in lane_ids:
        all_pkgs.update(touched_packages(lane_map, lid))

    if len(lane_ids) == 1:
        lane = lane_map.lanes[lane_ids[0]]
        if len(all_pkgs) > 1 and not lane.multi_package_ok:
            return (
                f"lane {lane.id!r} touches multiple packages ({', '.join(sorted(all_pkgs))}) "
                "and is not marked multi_package_ok"
            )
        return None

    if len(all_pkgs) <= 1:
        return None

    sanctioned = find_sanctioned_multi_package(lane_map, lane_ids)
    if sanctioned is None:
        return (
            f"lanes {'+'.join(sorted(lane_ids))} touch multiple packages "
            f"({', '.join(sorted(all_pkgs))}) and are not a sanctioned multi-package combination"
        )
    label_set = set(issue_labels)
    if sanctioned.requires_label and sanctioned.requires_label not in label_set:
        return (
            f"multi-package combination {'+'.join(sorted(lane_ids))} "
            f"({sanctioned.name}) requires label {sanctioned.requires_label!r}"
        )
    return None


def branch_for_lanes(lane_map: LaneMap, issue_number: int, lane_ids: Sequence[str]) -> str:
    """Compute the canonical git branch name for an issue's lane IDs."""
    if not lane_ids:
        raise ValueError("lane_ids must be non-empty")
    if len(lane_ids) == 1:
        return f"{lane_map.branch_rules.lane_prefix}{lane_ids[0]}/{issue_number}"
    sanctioned = find_sanctioned_multi_package(lane_map, lane_ids)
    if sanctioned is not None and sanctioned.branch_style == "story":
        return f"{lane_map.branch_rules.story_prefix}{issue_number}"
    joined = "+".join(sorted(lane_ids))
    return f"{lane_map.branch_rules.lane_prefix}{joined}/{issue_number}"


def resolve_branch(lane_map: LaneMap, branch: str) -> BranchResolution:
    """Resolve a git branch name against the lane map."""
    lane_prefix = lane_map.branch_rules.lane_prefix
    story_prefix = lane_map.branch_rules.story_prefix

    if branch.startswith(lane_prefix):
        after = branch[len(lane_prefix) :]
        if "/" not in after:
            return BranchResolution(
                branch=branch,
                restricted=True,
                error=f"branch '{branch}' must match '{lane_prefix}<lane>/<id>'",
            )
        spec, rest = after.split("/", 1)
        if not spec or not rest:
            return BranchResolution(
                branch=branch,
                restricted=True,
                error=f"branch '{branch}' must match '{lane_prefix}<lane>/<id>'",
            )
        parts = spec.split("+")
        if any(not p for p in parts):
            return BranchResolution(
                branch=branch,
                restricted=True,
                error=f"branch '{branch}' contains an empty lane name in '{spec}'",
            )
        if len(set(parts)) != len(parts):
            return BranchResolution(
                branch=branch,
                restricted=True,
                error=f"branch '{branch}' lists duplicate lane in '{spec}'",
            )
        unknown = [p for p in parts if p not in lane_map.lanes]
        if unknown:
            return BranchResolution(
                branch=branch,
                restricted=True,
                error=f"branch '{branch}' names unknown lane '{unknown[0]}' (not in tools/lanes.json)",
            )

        all_pkgs: set[str] = set()
        for lid in parts:
            all_pkgs.update(touched_packages(lane_map, lid))

        extra_paths: list[str] = []
        if len(parts) == 1:
            lane = lane_map.lanes[parts[0]]
            if len(all_pkgs) > 1 and not lane.multi_package_ok:
                return BranchResolution(
                    branch=branch,
                    restricted=True,
                    error=(
                        f"branch '{branch}' lane '{lane.id}' touches multiple packages "
                        f"({', '.join(sorted(all_pkgs))}) without multi_package_ok"
                    ),
                )
        elif len(all_pkgs) > 1:
            sanctioned = find_sanctioned_multi_package(lane_map, parts)
            if sanctioned is None:
                return BranchResolution(
                    branch=branch,
                    restricted=True,
                    error=(
                        f"branch '{branch}' touches multiple packages "
                        f"({', '.join(sorted(all_pkgs))}) with unsanctioned lane combination '{spec}'"
                    ),
                )
            extra_paths.extend(sanctioned.extra_paths)

        allowed = _dedupe(p for lid in parts for p in lane_map.lanes[lid].paths)
        allowed = _dedupe((*allowed, *extra_paths))
        generated = _dedupe(p for lid in parts for p in lane_map.lanes[lid].generated_paths)
        return BranchResolution(
            branch=branch,
            restricted=True,
            lane_ids=tuple(parts),
            allowed_paths=allowed,
            generated_paths=generated,
            shared_paths=lane_map.shared_paths,
        )

    if branch.startswith(story_prefix):
        rest = branch[len(story_prefix) :]
        if not _DIGITS_RE.match(rest):
            return BranchResolution(
                branch=branch,
                restricted=True,
                error=f"branch '{branch}' must match '{story_prefix}<number>'",
            )
        default_id = lane_map.branch_rules.story_default_lane
        lane = lane_map.lanes[default_id]
        return BranchResolution(
            branch=branch,
            restricted=True,
            lane_ids=(default_id,),
            allowed_paths=lane.paths,
            generated_paths=lane.generated_paths,
            shared_paths=lane_map.shared_paths,
        )

    return BranchResolution(
        branch=branch,
        restricted=False,
        shared_paths=lane_map.shared_paths,
    )


def format_allowed_summary(patterns: Sequence[str]) -> str:
    if not patterns:
        return "(no paths)"
    if len(patterns) == 1:
        return patterns[0]
    if len(patterns) == 2:
        return f"{patterns[0]} and {patterns[1]}"
    if len(patterns) <= 6:
        return f"{', '.join(patterns[:-1])}, and {patterns[-1]}"
    head = ", ".join(patterns[:4])
    return f"{head}, ... ({len(patterns)} patterns total)"


def check_changed_files(
    lane_map: LaneMap,
    resolution: BranchResolution,
    changed_files: Iterable[str],
    *,
    block_packages_on_unrestricted: bool = False,
) -> list[tuple[str | None, str]]:
    """Check changed file paths against a BranchResolution.

    Returns a list of `(file_path_or_none, message)` violations.
    """
    if resolution.error is not None:
        return [(None, resolution.error)]

    files = [f for f in changed_files if f]
    if not files:
        return []

    violations: list[tuple[str | None, str]] = []
    if resolution.restricted:
        patterns = resolution.all_allowed_patterns
        summary = format_allowed_summary(patterns)
        for path in files:
            if any(match_pattern(pat, path) for pat in patterns):
                continue
            violations.append(
                (
                    path,
                    f"branch '{resolution.branch}' (lane {'+'.join(resolution.lane_ids)}) "
                    f"may not modify '{path}' (allowed: {summary})",
                )
            )
        return violations

    if block_packages_on_unrestricted:
        prefix = lane_map.package_root_prefix
        for path in files:
            if path.startswith(prefix):
                violations.append(
                    (
                        path,
                        f"branch '{resolution.branch}' modifies '{prefix}' with an unauthorized prefix. "
                        f"Use {lane_map.branch_rules.lane_prefix}<lane>/<n> or "
                        f"{lane_map.branch_rules.story_prefix}<n>.",
                    )
                )
    return violations
