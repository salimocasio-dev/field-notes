#!/usr/bin/env python3
"""Split single-file Coquí stories into shared game files, per-language lines files,
and a per-language ID-to-word table (see docs/proyecto/23-split-story-format.md).

    python3 coqui/tool/split_stories.py split [--src historia/cuentos] [--out content] [--lang es]
    python3 coqui/tool/split_stories.py join  --games DIR --lines DIR --out DIR
    python3 coqui/tool/split_stories.py check [--src historia/cuentos] [--out content] [--lang es]

SAFETY: This tool NEVER writes under `historia/cuentos/` (pushing there starts a paid
Azure audio recording job) or anywhere under `historia/` or the source directory.
"""
from __future__ import annotations

import argparse
import copy
import json
import re
import sys
from itertools import product
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True

REPO_ROOT = Path(__file__).resolve().parents[2]

GAME_FORMAT = "coqui.game.v1"
LINES_FORMAT = "coqui.lines.v1"
WORDS_FORMAT = "coqui.words.v1"

# Exact 24-key partition of historia/cuentos/*.json.
CANONICAL_STORY_KEYS: tuple[str, ...] = (
    "id",
    "title",
    "place",
    "scene",
    "tipo",
    "next",
    "nota",
    "goal",
    "stake",
    "note",
    "dots",
    "bien",
    "callado",
    "cam",
    "focus_words",
    "back_again",
    "also_heard",
    "names",
    "palabras",
    "clips",
    "beats",
    "final",
    "leer",
    "items",
)
ALL_SOURCE_KEYS: frozenset[str] = frozenset(CANONICAL_STORY_KEYS)

GAME_OPTIONAL_KEYS: tuple[str, ...] = (
    "tipo",
    "scene",
    "next",
    "goal",
    "note",
    "stake",
    "dots",
    "bien",
    "callado",
    "cam",
    "beats",
    "final",
    "leer",
    "items",
)
GAME_ALLOWED_KEYS: frozenset[str] = frozenset(("format", "id") + GAME_OPTIONAL_KEYS)

LINES_OPTIONAL_SOURCE_KEYS: tuple[str, ...] = (
    "place",
    "nota",
    "focus_words",
    "back_again",
    "also_heard",
    "names",
    "palabras",
)
LINES_ALLOWED_KEYS: frozenset[str] = frozenset(
    ("format", "id", "lang", "title", "clips", "item_words") + LINES_OPTIONAL_SOURCE_KEYS
)

# Matches coqui/packages/features/feature_story/lib/src/runner/steps.dart:35
VAR_RE = re.compile(r"\$([a-z]+)")
SAFE_SEGMENT_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
RESERVED_STORY_IDS: frozenset[str] = frozenset({"words"})


def _assert_safe_segment(value: Any, label: str) -> str:
    """Validate that an id or lang code is a single safe path segment (no traversal)."""
    if (
        not isinstance(value, str)
        or not value
        or value in (".", "..")
        or "/" in value
        or "\\" in value
        or not SAFE_SEGMENT_RE.match(value)
    ):
        raise ValueError(f"Unsafe {label}: {value!r}")
    return value


def _assert_safe_story_id(value: Any, label: str = "story id") -> str:
    """Validate a story id is a safe path segment and not reserved (e.g. 'words')."""
    sid = _assert_safe_segment(value, label)
    if sid in RESERVED_STORY_IDS:
        raise ValueError(f"Reserved {label} {sid!r}: collides with {sid}.json word table")
    return sid


def _assert_safe_output_dir(
    out_dir: Path,
    repo_root: Path = REPO_ROOT,
    *,
    src_dir: Path | None = None,
) -> None:
    """Refuse writing inside historia/cuentos, repo_root/historia, or src_dir (following symlinks)."""
    out_path = Path(out_dir)
    out_resolved = out_path.resolve()
    root_resolved = Path(repo_root).resolve()
    historia_resolved = (root_resolved / "historia").resolve()
    cuentos_resolved = (root_resolved / "historia" / "cuentos").resolve()

    if out_resolved == cuentos_resolved or cuentos_resolved in out_resolved.parents:
        raise ValueError(
            f"Refusing to write inside historia/cuentos (paid audio guard): {out_dir}"
        )

    if out_resolved == historia_resolved or historia_resolved in out_resolved.parents:
        raise ValueError(
            f"Refusing to write inside frozen historia/ directory: {out_dir}"
        )

    for parts in (out_path.parts, out_resolved.parts):
        for i in range(len(parts) - 1):
            if parts[i] == "historia" and parts[i + 1] == "cuentos":
                raise ValueError(
                    f"Refusing to write to a path containing historia/cuentos: {out_dir}"
                )

    if src_dir is not None:
        src_resolved = Path(src_dir).resolve()
        if out_resolved == src_resolved or src_resolved in out_resolved.parents:
            raise ValueError(
                f"Refusing to write output inside source directory {src_dir}: {out_dir}"
            )


def _assert_safe_target_file(
    target_file: Path,
    expected_dir: Path,
    repo_root: Path = REPO_ROOT,
    *,
    src_dir: Path | None = None,
) -> None:
    """Validate that a target file (following symlinks) stays inside expected_dir and safe bounds."""
    if target_file.is_symlink():
        raise ValueError(f"Refusing to write or delete through symlink: {target_file}")
    _assert_safe_output_dir(target_file.parent, repo_root, src_dir=src_dir)
    _assert_safe_output_dir(target_file, repo_root, src_dir=src_dir)
    expected_resolved = expected_dir.resolve()
    target_resolved = target_file.resolve()
    if target_resolved.parent != expected_resolved:
        raise ValueError(
            f"Target file {target_file} resolves outside {expected_dir}: {target_resolved}"
        )


def render_json(obj: Any) -> bytes:
    """Deterministic UTF-8 JSON bytes with indent=2, ensure_ascii=False, trailing newline."""
    return (json.dumps(obj, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def _read_json(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"Expected JSON object in {path}, got {type(data).__name__}")
    return data


def _load_stories_dir(src_dir: Path) -> list[dict[str, Any]]:
    src_path = Path(src_dir)
    if not src_path.is_dir():
        raise ValueError(f"Source directory does not exist: {src_dir}")
    paths = sorted(src_path.glob("*.json"))
    if not paths:
        raise ValueError(f"No story JSON files found in: {src_dir}")
    stories: list[dict[str, Any]] = []
    for path in paths:
        story = _read_json(path)
        sid = story.get("id")
        if not isinstance(sid, str) or sid != path.stem:
            raise ValueError(
                f"Story id {sid!r} does not match filename stem {path.stem!r} ({path})"
            )
        _assert_safe_story_id(sid, "story id")
        stories.append(story)
    return stories


def split_story(story: dict[str, Any], *, lang: str = "es") -> tuple[dict[str, Any], dict[str, Any]]:
    """Split a single-file story dict into (game_dict, lines_dict)."""
    if not isinstance(story, dict):
        raise ValueError(f"Story must be a dict, got {type(story).__name__}")
    _assert_safe_segment(lang, "lang")

    unknown = sorted(set(story.keys()) - ALL_SOURCE_KEYS)
    if unknown:
        raise ValueError(f"Unknown top-level key(s) in story {story.get('id')!r}: {unknown}")

    sid = _assert_safe_story_id(story.get("id"), "story id")
    if "title" not in story:
        raise ValueError(f"Story {sid!r} is missing required key 'title'")
    if "clips" not in story:
        raise ValueError(f"Story {sid!r} is missing required key 'clips'")

    game: dict[str, Any] = {
        "format": GAME_FORMAT,
        "id": sid,
    }
    item_words: list[str] | None = None

    for key in GAME_OPTIONAL_KEYS:
        if key not in story:
            continue
        if key == "items":
            raw_items = story["items"]
            if not isinstance(raw_items, list):
                raise ValueError(f"Story {sid!r}: 'items' must be a list")
            game_items: list[dict[str, Any]] = []
            words_list: list[str] = []
            for idx, item in enumerate(raw_items):
                if not isinstance(item, dict) or "w" not in item:
                    raise ValueError(
                        f"Story {sid!r}: items[{idx}] must be a dict containing 'w'"
                    )
                word = item["w"]
                if not isinstance(word, str):
                    raise ValueError(
                        f"Story {sid!r}: items[{idx}]['w'] must be a string, got {type(word).__name__}"
                    )
                words_list.append(word)
                stripped = {k: copy.deepcopy(v) for k, v in item.items() if k != "w"}
                game_items.append(stripped)
            game["items"] = game_items
            item_words = words_list
        else:
            game[key] = copy.deepcopy(story[key])

    lines: dict[str, Any] = {
        "format": LINES_FORMAT,
        "id": sid,
        "lang": lang,
        "title": copy.deepcopy(story["title"]),
    }
    for key in LINES_OPTIONAL_SOURCE_KEYS:
        if key in story:
            lines[key] = copy.deepcopy(story[key])
    lines["clips"] = copy.deepcopy(story["clips"])
    if item_words is not None:
        lines["item_words"] = item_words

    return game, lines


def join_story(game: dict[str, Any], lines: dict[str, Any]) -> dict[str, Any]:
    """Reconstruct a single-file story dict from (game_dict, lines_dict)."""
    if not isinstance(game, dict):
        raise ValueError(f"game must be a dict, got {type(game).__name__}")
    if not isinstance(lines, dict):
        raise ValueError(f"lines must be a dict, got {type(lines).__name__}")

    if game.get("format") != GAME_FORMAT:
        raise ValueError(f"Invalid game format: {game.get('format')!r} (expected {GAME_FORMAT!r})")
    if lines.get("format") != LINES_FORMAT:
        raise ValueError(f"Invalid lines format: {lines.get('format')!r} (expected {LINES_FORMAT!r})")

    gid = _assert_safe_story_id(game.get("id"), "game id")
    lid = lines.get("id")
    if gid != lid:
        raise ValueError(f"Mismatched story id: game={gid!r} vs lines={lid!r}")

    _assert_safe_segment(lines.get("lang"), "lang")
    if "title" not in lines:
        raise ValueError(f"lines for {gid!r} is missing required key 'title'")
    if "clips" not in lines:
        raise ValueError(f"lines for {gid!r} is missing required key 'clips'")

    unknown_game = sorted(set(game.keys()) - GAME_ALLOWED_KEYS)
    if unknown_game:
        raise ValueError(f"Unknown key(s) in game {gid!r}: {unknown_game}")
    unknown_lines = sorted(set(lines.keys()) - LINES_ALLOWED_KEYS)
    if unknown_lines:
        raise ValueError(f"Unknown key(s) in lines {gid!r}: {unknown_lines}")

    has_items = "items" in game
    has_item_words = "item_words" in lines
    if has_items != has_item_words:
        raise ValueError(
            f"Story {gid!r}: 'items' in game ({has_items}) must match 'item_words' in lines ({has_item_words})"
        )

    joined_items: list[dict[str, Any]] | None = None
    if has_items:
        raw_items = game["items"]
        raw_words = lines["item_words"]
        if not isinstance(raw_items, list) or not isinstance(raw_words, list):
            raise ValueError(f"Story {gid!r}: 'items' and 'item_words' must both be lists")
        if len(raw_items) != len(raw_words):
            raise ValueError(
                f"Story {gid!r}: len(item_words)={len(raw_words)} != len(items)={len(raw_items)}"
            )
        joined_items = []
        for idx, (word, item) in enumerate(zip(raw_words, raw_items)):
            if not isinstance(word, str):
                raise ValueError(f"Story {gid!r}: item_words[{idx}] must be a string")
            if not isinstance(item, dict):
                raise ValueError(f"Story {gid!r}: items[{idx}] must be a dict")
            if "w" in item:
                raise ValueError(f"Story {gid!r}: game items[{idx}] must not contain 'w'")
            rebuilt = {"w": word}
            for k, v in item.items():
                rebuilt[k] = copy.deepcopy(v)
            joined_items.append(rebuilt)

    out: dict[str, Any] = {}
    for key in CANONICAL_STORY_KEYS:
        if key == "id":
            out["id"] = gid
        elif key == "items":
            if joined_items is not None:
                out["items"] = joined_items
        elif key in game:
            out[key] = copy.deepcopy(game[key])
        elif key in lines:
            out[key] = copy.deepcopy(lines[key])

    return out


def _iter_steps(node: Any):
    """Yield every step dict nested anywhere inside beats/final."""
    if isinstance(node, list):
        for item in node:
            yield from _iter_steps(item)
    elif isinstance(node, dict):
        yield node
        for value in node.values():
            if isinstance(value, list):
                yield from _iter_steps(value)
            elif isinstance(value, dict):
                for sub in value.values():
                    if isinstance(sub, list):
                        yield from _iter_steps(sub)


def _expand_expr(expr: Any, domains: dict[str, set[str]]) -> list[str]:
    """Expand `$var` placeholders using known per-story variable domains."""
    if not isinstance(expr, str):
        return []
    vars_found = sorted(set(VAR_RE.findall(expr)))
    if not vars_found:
        return [expr]
    choices: list[tuple[str, list[str]]] = []
    for var in vars_found:
        vals = sorted(domains.get(var, set()))
        if not vals:
            return [expr]
        choices.append((var, vals))
    expanded: set[str] = set()
    for combo in product(*(vals for _, vals in choices)):
        mapping = {var: val for (var, _), val in zip(choices, combo)}
        expanded.add(VAR_RE.sub(lambda m: mapping[m.group(1)], expr))
    return sorted(expanded)


def _collect_story_domains_and_steps(story: dict[str, Any]) -> tuple[dict[str, set[str]], list[dict[str, Any]]]:
    """Collect variable domains (up to 4 expansion passes) and all step dicts for a story."""
    steps = list(_iter_steps([story.get("beats", []), story.get("final", [])]))
    domains: dict[str, set[str]] = {}

    def _add(var: Any, val: str) -> bool:
        if not isinstance(var, str) or not var or "$" in val:
            return False
        bucket = domains.setdefault(var, set())
        if val not in bucket:
            bucket.add(val)
            return True
        return False

    for _ in range(4):
        changed = False
        for st in steps:
            if st.get("draw"):
                var = st["draw"]
                other = st.get("other")
                for opt in st.get("options") or []:
                    for val in _expand_expr(opt, domains):
                        changed |= _add(var, val)
                        if other:
                            changed |= _add(other, val)
            if st.get("reparte"):
                raw_vars = st["reparte"]
                var_list = raw_vars if isinstance(raw_vars, list) else [raw_vars]
                for opt in st.get("options") or []:
                    for val in _expand_expr(opt, domains):
                        for var in var_list:
                            changed |= _add(var, val)
            if st.get("calc"):
                var = st["calc"]
                for branch in ("then", "else"):
                    raw = st.get(branch)
                    if isinstance(raw, str):
                        for val in _expand_expr(raw, domains):
                            changed |= _add(var, val)
            if st.get("decide"):
                as_var = st.get("as")
                other = st.get("other")
                if as_var or other:
                    for opt in st.get("options") or []:
                        for val in _expand_expr(opt, domains):
                            if as_var:
                                changed |= _add(as_var, val)
                            if other:
                                changed |= _add(other, val)
        if not changed:
            break

    return domains, steps


def extract_story_tested_ids(story: dict[str, Any]) -> set[str]:
    """Return all concrete (non-$var, non-'-') tested IDs for a story."""
    domains, steps = _collect_story_domains_and_steps(story)
    tested: set[str] = set()
    for st in steps:
        if st.get("decide") and not st.get("libre"):
            if st.get("tests"):
                exprs = [st["tests"]]
            elif st.get("pick"):
                exprs = [st["pick"]]
            else:
                exprs = list(st.get("options") or [])
            for expr in exprs:
                for val in _expand_expr(expr, domains):
                    if "$" not in val and val != "-":
                        tested.add(val)
    return tested


def build_word_table(stories: list[dict[str, Any]], *, lang: str = "es") -> dict[str, Any]:
    """Build the language-wide ID-to-word table (`coqui.words.v1`) across all stories."""
    _assert_safe_segment(lang, "lang")

    names_keys: set[str] = set()
    touched_ids: set[str] = set()
    tested_ids: set[str] = set()
    palabras_keys: set[str] = set()
    unmapped_tested: set[str] = set()
    non_dash_palabras: dict[str, str] = {}
    dash_palabras: set[str] = set()

    for story in stories:
        domains, steps = _collect_story_domains_and_steps(story)
        story_pal = story.get("palabras")
        if not isinstance(story_pal, dict):
            story_pal = {}

        raw_names = story.get("names")
        if isinstance(raw_names, dict):
            for k in raw_names:
                if isinstance(k, str) and "$" not in k and k != "-":
                    names_keys.add(k)

        for k, v in story_pal.items():
            if not isinstance(k, str) or "$" in k or k == "-":
                continue
            palabras_keys.add(k)
            if v == "-":
                dash_palabras.add(k)
            elif isinstance(v, str) and v:
                prev = non_dash_palabras.get(k)
                if prev is not None and prev != v:
                    raise ValueError(
                        f"Conflicting palabras mapping for {k!r}: {prev!r} vs {v!r} (in {story.get('id')!r})"
                    )
                non_dash_palabras[k] = v

        for st in steps:
            if st.get("ask"):
                for val in _expand_expr(st["ask"], domains):
                    if "$" not in val and val != "-":
                        touched_ids.add(val)
            if st.get("elige"):
                for opt in st.get("options") or []:
                    for val in _expand_expr(opt, domains):
                        if "$" not in val and val != "-":
                            touched_ids.add(val)
            if st.get("decide"):
                for field in ("options", "vale"):
                    for opt in st.get(field) or []:
                        for val in _expand_expr(opt, domains):
                            if "$" not in val and val != "-":
                                touched_ids.add(val)
                if not st.get("libre"):
                    if st.get("tests"):
                        exprs = [st["tests"]]
                    elif st.get("pick"):
                        exprs = [st["pick"]]
                    else:
                        exprs = list(st.get("options") or [])
                    for expr in exprs:
                        for val in _expand_expr(expr, domains):
                            if "$" not in val and val != "-":
                                tested_ids.add(val)
                                if val not in story_pal:
                                    unmapped_tested.add(val)

    all_ids = sorted(names_keys | touched_ids | tested_ids | palabras_keys)
    words: dict[str, str] = {}
    for k in all_ids:
        if k in unmapped_tested:
            words[k] = k
        elif k in non_dash_palabras:
            words[k] = non_dash_palabras[k]
        elif k in dash_palabras:
            words[k] = "-"
        else:
            words[k] = k

    return {
        "format": WORDS_FORMAT,
        "lang": lang,
        "words": words,
    }


def resolve_tested_word(
    tested_id: str,
    lines: dict[str, Any],
    word_table: dict[str, Any],
) -> str:
    """Resolve a concrete tested ID to its target-language word.

    Precedence:
      1. lines["palabras"][tested_id] (when non-empty string)
      2. word_table["words"][tested_id] (when non-empty string)
      3. tested_id itself
    If the resolved string is "-", progress does not log the decision.
    """
    if isinstance(lines, dict):
        story_pal = lines.get("palabras")
        if isinstance(story_pal, dict):
            val = story_pal.get(tested_id)
            if isinstance(val, str) and val:
                return val
    if isinstance(word_table, dict):
        table_words = word_table.get("words")
        if isinstance(table_words, dict):
            val = table_words.get(tested_id)
            if isinstance(val, str) and val:
                return val
    return tested_id


def _assert_safe_dir_tree(
    directory: Path,
    base_dir: Path,
    repo_root: Path = REPO_ROOT,
    *,
    src_dir: Path | None = None,
) -> None:
    """Ensure directory and all intermediate components from base_dir are non-symlink and safe."""
    _assert_safe_output_dir(base_dir, repo_root, src_dir=src_dir)
    if base_dir.is_symlink():
        raise ValueError(f"Refusing to write through symlinked output directory: {base_dir}")
    rel = directory.relative_to(base_dir)
    cur = base_dir
    for part in rel.parts:
        cur = cur / part
        if cur.is_symlink():
            raise ValueError(f"Refusing to write through symlinked subdirectory: {cur}")
        _assert_safe_output_dir(cur, repo_root, src_dir=src_dir)
    base_resolved = base_dir.resolve()
    dir_resolved = directory.resolve()
    if dir_resolved != base_resolved and base_resolved not in dir_resolved.parents:
        raise ValueError(f"Destination {directory} resolves outside {base_dir}: {dir_resolved}")


def _remove_stale_json(
    directory: Path,
    expected_names: set[str],
    repo_root: Path = REPO_ROOT,
    *,
    src_dir: Path | None = None,
) -> list[str]:
    removed: list[str] = []
    if not directory.is_dir():
        return removed
    _assert_safe_output_dir(directory, repo_root, src_dir=src_dir)
    if directory.is_symlink():
        raise ValueError(f"Refusing to clean stale files in symlinked directory: {directory}")
    for path in sorted(directory.glob("*.json")):
        if path.name not in expected_names:
            _assert_safe_target_file(path, directory, repo_root, src_dir=src_dir)
            path.unlink()
            removed.append(path.name)
    return removed


def split_directory(
    src_dir: Path,
    out_dir: Path,
    *,
    lang: str = "es",
    repo_root: Path = REPO_ROOT,
) -> dict[str, Any]:
    """Split every story JSON in src_dir into out_dir/games and out_dir/lines/<lang>."""
    _assert_safe_segment(lang, "lang")
    src_path = Path(src_dir)
    out_path = Path(out_dir)
    games_dir = out_path / "games"
    lines_dir = out_path / "lines" / lang

    _assert_safe_dir_tree(games_dir, out_path, repo_root, src_dir=src_path)
    _assert_safe_dir_tree(lines_dir, out_path, repo_root, src_dir=src_path)

    stories = _load_stories_dir(src_path)
    word_table = build_word_table(stories, lang=lang)

    # Prepare payloads and pre-validate EVERY destination file before writing or deleting anything.
    pending_writes: list[tuple[Path, Path, bytes]] = []
    expected_game_names: set[str] = set()
    expected_line_names: set[str] = {"words.json"}

    for story in stories:
        game, lines = split_story(story, lang=lang)
        fname = f"{story['id']}.json"
        expected_game_names.add(fname)
        expected_line_names.add(fname)
        gtarget = games_dir / fname
        ltarget = lines_dir / fname
        _assert_safe_target_file(gtarget, games_dir, repo_root, src_dir=src_path)
        _assert_safe_target_file(ltarget, lines_dir, repo_root, src_dir=src_path)
        pending_writes.append((gtarget, games_dir, render_json(game)))
        pending_writes.append((ltarget, lines_dir, render_json(lines)))

    words_target = lines_dir / "words.json"
    _assert_safe_target_file(words_target, lines_dir, repo_root, src_dir=src_path)
    pending_writes.append((words_target, lines_dir, render_json(word_table)))

    games_dir.mkdir(parents=True, exist_ok=True)
    lines_dir.mkdir(parents=True, exist_ok=True)

    for target, expected_parent, payload in pending_writes:
        _assert_safe_target_file(target, expected_parent, repo_root, src_dir=src_path)
        target.write_bytes(payload)

    removed_games = _remove_stale_json(
        games_dir, expected_game_names, repo_root, src_dir=src_path
    )
    removed_lines = _remove_stale_json(
        lines_dir, expected_line_names, repo_root, src_dir=src_path
    )

    return {
        "stories": len(stories),
        "words": len(word_table["words"]),
        "lang": lang,
        "games_dir": str(games_dir),
        "lines_dir": str(lines_dir),
        "removed_games": removed_games,
        "removed_lines": removed_lines,
    }


def join_directory(
    games_dir: Path,
    lines_dir: Path,
    out_dir: Path,
    *,
    repo_root: Path = REPO_ROOT,
) -> int:
    """Join games_dir/*.json and lines_dir/*.json (ignoring words.json) into out_dir."""
    games_path = Path(games_dir)
    lines_path = Path(lines_dir)
    out_path = Path(out_dir)
    _assert_safe_dir_tree(out_path, out_path, repo_root, src_dir=games_path)
    _assert_safe_output_dir(out_path, repo_root, src_dir=lines_path)

    if not games_path.is_dir():
        raise ValueError(f"Games directory does not exist: {games_dir}")
    if not lines_path.is_dir():
        raise ValueError(f"Lines directory does not exist: {lines_dir}")

    game_files = {p.stem: p for p in sorted(games_path.glob("*.json"))}
    line_files = {
        p.stem: p for p in sorted(lines_path.glob("*.json")) if p.name != "words.json"
    }

    if not game_files:
        raise ValueError(f"No game JSON files found in: {games_dir}")

    missing_lines = sorted(set(game_files) - set(line_files))
    extra_lines = sorted(set(line_files) - set(game_files))
    if missing_lines or extra_lines:
        raise ValueError(
            f"Game/lines file mismatch: missing_lines={missing_lines}, extra_lines={extra_lines}"
        )

    pending: list[tuple[Path, bytes]] = []
    for sid in sorted(game_files):
        _assert_safe_story_id(sid, "story id")
        game = _read_json(game_files[sid])
        lines = _read_json(line_files[sid])
        joined = join_story(game, lines)
        target = out_path / f"{sid}.json"
        _assert_safe_target_file(target, out_path, repo_root, src_dir=games_path)
        _assert_safe_target_file(target, out_path, repo_root, src_dir=lines_path)
        pending.append((target, render_json(joined)))

    out_path.mkdir(parents=True, exist_ok=True)
    for target, payload in pending:
        _assert_safe_target_file(target, out_path, repo_root, src_dir=games_path)
        _assert_safe_target_file(target, out_path, repo_root, src_dir=lines_path)
        target.write_bytes(payload)
    return len(pending)


def check_directory(
    src_dir: Path,
    out_dir: Path,
    *,
    lang: str = "es",
) -> list[str]:
    """Verify out_dir matches a fresh split of src_dir, round-trips exactly, and resolves words."""
    problems: list[str] = []
    try:
        _assert_safe_segment(lang, "lang")
    except ValueError as exc:
        return [str(exc)]
    src_path = Path(src_dir)
    out_path = Path(out_dir)
    games_dir = out_path / "games"
    lines_dir = out_path / "lines" / lang

    try:
        stories = _load_stories_dir(src_path)
    except ValueError as exc:
        return [str(exc)]

    if not games_dir.is_dir():
        problems.append(f"Missing games directory: {games_dir}")
    if not lines_dir.is_dir():
        problems.append(f"Missing lines directory: {lines_dir}")
    if problems:
        return problems

    expected_story_files = {f"{s['id']}.json" for s in stories}
    expected_line_files = expected_story_files | {"words.json"}

    actual_game_files = {p.name for p in games_dir.glob("*.json")}
    actual_line_files = {p.name for p in lines_dir.glob("*.json")}

    for name in sorted(expected_story_files - actual_game_files):
        problems.append(f"Missing game file: {games_dir / name}")
    for name in sorted(actual_game_files - expected_story_files):
        problems.append(f"Unexpected extra game file: {games_dir / name}")
    for name in sorted(expected_line_files - actual_line_files):
        problems.append(f"Missing lines file: {lines_dir / name}")
    for name in sorted(actual_line_files - expected_line_files):
        problems.append(f"Unexpected extra lines file: {lines_dir / name}")

    expected_words = build_word_table(stories, lang=lang)
    expected_words_bytes = render_json(expected_words)
    words_path = lines_dir / "words.json"
    disk_words: dict[str, Any] | None = None
    if words_path.is_file():
        actual_words_bytes = words_path.read_bytes()
        if actual_words_bytes != expected_words_bytes:
            problems.append(f"Byte mismatch in {words_path} (run split_stories.py split)")
        try:
            disk_words = json.loads(actual_words_bytes.decode("utf-8"))
        except Exception as exc:  # noqa: BLE001
            problems.append(f"Invalid JSON in {words_path}: {exc}")

    for story in stories:
        sid = story["id"]
        fname = f"{sid}.json"
        expected_game, expected_lines = split_story(story, lang=lang)
        expected_game_bytes = render_json(expected_game)
        expected_lines_bytes = render_json(expected_lines)

        gpath = games_dir / fname
        lpath = lines_dir / fname
        disk_game: dict[str, Any] | None = None
        disk_lines: dict[str, Any] | None = None

        if gpath.is_file():
            gbytes = gpath.read_bytes()
            if gbytes != expected_game_bytes:
                problems.append(f"Byte mismatch in {gpath}")
            try:
                disk_game = json.loads(gbytes.decode("utf-8"))
            except Exception as exc:  # noqa: BLE001
                problems.append(f"Invalid JSON in {gpath}: {exc}")

        if lpath.is_file():
            lbytes = lpath.read_bytes()
            if lbytes != expected_lines_bytes:
                problems.append(f"Byte mismatch in {lpath}")
            try:
                disk_lines = json.loads(lbytes.decode("utf-8"))
            except Exception as exc:  # noqa: BLE001
                problems.append(f"Invalid JSON in {lpath}: {exc}")

        if disk_game is not None and disk_lines is not None:
            try:
                rejoined = join_story(disk_game, disk_lines)
            except Exception as exc:  # noqa: BLE001
                problems.append(f"join_story failed for {sid}: {exc}")
            else:
                if rejoined != story:
                    problems.append(f"Round-trip mismatch for {sid}: join_story != original")

        if disk_lines is not None and disk_words is not None:
            story_pal = story.get("palabras") if isinstance(story.get("palabras"), dict) else {}
            for tid in sorted(extract_story_tested_ids(story)):
                legacy = story_pal.get(tid) or tid
                resolved = resolve_tested_word(tid, disk_lines, disk_words)
                if resolved != legacy:
                    problems.append(
                        f"Word resolution mismatch in {sid} for {tid!r}: legacy={legacy!r} vs resolved={resolved!r}"
                    )

    return problems


def _resolve_default_path(raw: str | None, default_rel: str) -> Path:
    if raw is None:
        return REPO_ROOT / default_rel
    return Path(raw)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Split, join, or check Coquí story files."
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_split = sub.add_parser("split", help="Split single-file stories into game + lines + words.json")
    p_split.add_argument("--src", default=None, help="Source stories dir (default: <repo>/historia/cuentos)")
    p_split.add_argument("--out", default=None, help="Output content dir (default: <repo>/content)")
    p_split.add_argument("--lang", default="es", help="BCP-47 language code (default: es)")

    p_join = sub.add_parser("join", help="Join game + lines directories into single-file stories")
    p_join.add_argument("--games", required=True, help="Input games directory")
    p_join.add_argument("--lines", required=True, help="Input language lines directory")
    p_join.add_argument("--out", required=True, help="Output directory (never historia/cuentos)")

    p_check = sub.add_parser("check", help="Verify split files match source, round-trip, and resolve words")
    p_check.add_argument("--src", default=None, help="Source stories dir (default: <repo>/historia/cuentos)")
    p_check.add_argument("--out", default=None, help="Output content dir (default: <repo>/content)")
    p_check.add_argument("--lang", default="es", help="BCP-47 language code (default: es)")

    args = parser.parse_args(argv)

    try:
        if args.cmd == "split":
            src = _resolve_default_path(args.src, "historia/cuentos")
            out = _resolve_default_path(args.out, "content")
            info = split_directory(src, out, lang=args.lang)
            print(
                f"split_stories: wrote {info['stories']} games, {info['stories']} {info['lang']} lines, "
                f"and words.json ({info['words']} entries)"
            )
            return 0

        if args.cmd == "join":
            count = join_directory(Path(args.games), Path(args.lines), Path(args.out))
            print(f"split_stories: joined {count} stories into {args.out}")
            return 0

        if args.cmd == "check":
            src = _resolve_default_path(args.src, "historia/cuentos")
            out = _resolve_default_path(args.out, "content")
            problems = check_directory(src, out, lang=args.lang)
            if problems:
                for p in problems:
                    print(f"ERROR: {p}", file=sys.stderr)
                return 1
            stories = _load_stories_dir(src)
            words = _read_json(out / "lines" / args.lang / "words.json")
            print(
                f"split_stories check: ok ({len(stories)} stories, {len(words['words'])} {args.lang} words)"
            )
            return 0
    except ValueError as exc:
        print(f"STOP: {exc}", file=sys.stderr)
        return 1

    return 1


if __name__ == "__main__":
    sys.exit(main())
