"""Tests for coqui/tool/split_stories.py.

    python3 coqui/tool/test/test_split_stories.py -v

Covers:
1. Exact round-trip of all 70 real stories in historia/cuentos/*.json (in-memory and committed content/).
2. Freshness check of committed content/ via check_directory and CLI `check`.
3. ID-to-word table (`content/lines/es/words.json`) completeness, sorting, homonym/suppression
   equivalence (bebe/bebé, tu/tú, nino/niño/-, nina/niña/-), and coverage of all trazas decision words.
4. Synthetic multi-language (French `fr`) pairing with real `content/games/la-lluvia.json`.
5. Safety guards (refuses historia/cuentos, historia/, and src_dir) and strict schema validation.

`dart test tool/test` ignores this file (it looks for *_test.dart).
"""
from __future__ import annotations

import contextlib
import copy
import io
import json
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path

sys.dont_write_bytecode = True
TOOL_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = TOOL_DIR.parents[1]
sys.path.insert(0, str(TOOL_DIR))

import split_stories as ss  # noqa: E402

SRC_DIR = REPO_ROOT / "historia" / "cuentos"
CONTENT_DIR = REPO_ROOT / "content"
TRAZAS_DIR = REPO_ROOT / "coqui" / "ref" / "trazas"


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _tree_bytes(root: Path) -> dict[str, bytes]:
    return {
        str(p.relative_to(root)): p.read_bytes()
        for p in sorted(root.rglob("*"))
        if p.is_file()
    }


def _run_cli(*args: str) -> tuple[int, str, str]:
    out, err = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        code = ss.main(list(args))
    return code, out.getvalue(), err.getvalue()


class RealStoriesRoundTripTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source_paths = sorted(SRC_DIR.glob("*.json"))
        cls.stories = {p.stem: _load_json(p) for p in cls.source_paths}

    def test_all_70_real_stories_breakdown_and_round_trip(self) -> None:
        self.assertEqual(len(self.stories), 70)

        kinds = Counter(s.get("tipo", "story") for s in self.stories.values())
        self.assertEqual(
            dict(kinds),
            {"story": 35, "escucha": 11, "haz": 11, "cual": 12, "palabras": 1},
        )

        for sid, original in self.stories.items():
            # 1. In-memory split -> join exact equality
            game, lines = ss.split_story(original, lang="es")
            self.assertEqual(game["format"], ss.GAME_FORMAT, sid)
            self.assertEqual(lines["format"], ss.LINES_FORMAT, sid)
            self.assertEqual(lines["lang"], "es", sid)
            self.assertEqual(ss.join_story(game, lines), original, f"in-memory round-trip failed: {sid}")

            # 2. Committed content/ files join -> exact equality with original
            disk_game = _load_json(CONTENT_DIR / "games" / f"{sid}.json")
            disk_lines = _load_json(CONTENT_DIR / "lines" / "es" / f"{sid}.json")
            self.assertEqual(
                ss.join_story(disk_game, disk_lines),
                original,
                f"committed content round-trip failed: {sid}",
            )

    def test_split_and_join_do_not_alias_caller_objects(self) -> None:
        original = copy.deepcopy(self.stories["la-lluvia"])
        snapshot = copy.deepcopy(original)
        game, lines = ss.split_story(original, lang="es")
        game["beats"].append({"wait": 999})
        lines["clips"]["esta_casa"]["text"] = "MUTATED"
        self.assertEqual(original, snapshot)

        game2, lines2 = ss.split_story(original, lang="es")
        g_snap = copy.deepcopy(game2)
        l_snap = copy.deepcopy(lines2)
        joined = ss.join_story(game2, lines2)
        joined["beats"].append({"wait": 123})
        joined["clips"]["esta_casa"]["text"] = "CHANGED"
        self.assertEqual(game2, g_snap)
        self.assertEqual(lines2, l_snap)

    def test_committed_content_freshness_check(self) -> None:
        problems = ss.check_directory(SRC_DIR, CONTENT_DIR, lang="es")
        self.assertEqual(problems, [])

        code, out, err = _run_cli("check")
        self.assertEqual(code, 0, err)
        self.assertEqual(err, "")
        self.assertIn("70 stories", out)


class WordTableAndResolutionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.stories = {p.stem: _load_json(p) for p in sorted(SRC_DIR.glob("*.json"))}
        cls.words_doc = _load_json(CONTENT_DIR / "lines" / "es" / "words.json")

    def test_words_json_shape_sorting_and_no_placeholders(self) -> None:
        self.assertEqual(self.words_doc["format"], ss.WORDS_FORMAT)
        self.assertEqual(self.words_doc["lang"], "es")
        words = self.words_doc["words"]
        self.assertIsInstance(words, dict)
        self.assertGreater(len(words), 0)
        keys = list(words.keys())
        self.assertEqual(keys, sorted(keys))
        for k, v in words.items():
            self.assertNotIn("$", k, f"placeholder key leaked: {k}")
            self.assertNotEqual(k, "-", "dash key must not appear")
            self.assertIsInstance(v, str)
            self.assertTrue(len(v) > 0, f"empty word for {k}")
        # Regression: $m must not corrupt $mal in "$mal_$m" (quien-eres-tu)
        self.assertNotIn("mamaal_mama", words)
        self.assertNotIn("papaal_papa", words)
        self.assertEqual(
            ss._expand_expr("$mal_$m", {"m": {"mama", "papa"}, "mal": {"el", "ella"}}),
            ["el_mama", "el_papa", "ella_mama", "ella_papa"],
        )

    def test_every_story_tested_id_matches_legacy_resolution(self) -> None:
        total_checked = 0
        for sid, original in self.stories.items():
            lines = _load_json(CONTENT_DIR / "lines" / "es" / f"{sid}.json")
            story_pal = original.get("palabras", {})
            for tid in sorted(ss.extract_story_tested_ids(original)):
                legacy = story_pal.get(tid) or tid
                resolved = ss.resolve_tested_word(tid, lines, self.words_doc)
                self.assertEqual(
                    resolved,
                    legacy,
                    f"Mismatch in {sid} for tested_id={tid!r}: got {resolved!r}, want {legacy!r}",
                )
                total_checked += 1
        self.assertGreater(total_checked, 100)

    def test_four_context_dependent_spanish_ids(self) -> None:
        def resolve_in(story_id: str, tid: str) -> str:
            lines = _load_json(CONTENT_DIR / "lines" / "es" / f"{story_id}.json")
            return ss.resolve_tested_word(tid, lines, self.words_doc)

        # bebe: verb "bebe" in la-piragua vs noun "bebé" in la-familia
        self.assertEqual(resolve_in("la-piragua", "bebe"), "bebe")
        self.assertEqual(resolve_in("la-familia", "bebe"), "bebé")

        # tu: possessive "tu" in otra-vez vs pronoun "tú" in quien-eres-tu
        self.assertEqual(resolve_in("otra-vez", "tu"), "tu")
        self.assertEqual(resolve_in("quien-eres-tu", "tu"), "tú")

        # nino: "niño" in las-flores vs suppressed "-" in la-piragua
        self.assertEqual(resolve_in("las-flores", "nino"), "niño")
        self.assertEqual(resolve_in("la-piragua", "nino"), "-")

        # nina: "niña" in las-flores vs suppressed "-" in la-piragua
        self.assertEqual(resolve_in("las-flores", "nina"), "niña")
        self.assertEqual(resolve_in("la-piragua", "nina"), "-")

        # nomas: dash-only in otra-vez -> "-"
        self.assertEqual(resolve_in("otra-vez", "nomas"), "-")

    def test_every_traza_decision_word_is_covered(self) -> None:
        traza_paths = sorted(TRAZAS_DIR.rglob("*.json"))
        self.assertGreater(len(traza_paths), 0, "expected reference traces under coqui/ref/trazas/")

        known_words = set(self.words_doc["words"].values())
        for sid in self.stories:
            lines = _load_json(CONTENT_DIR / "lines" / "es" / f"{sid}.json")
            known_words.update(lines.get("palabras", {}).values())

        seen = 0
        for path in traza_paths:
            traza = _load_json(path)
            decisions = traza.get("decisions")
            if not isinstance(decisions, list):
                continue
            for dec in decisions:
                if not isinstance(dec, dict):
                    continue
                word = dec.get("word")
                if not word:
                    continue
                seen += 1
                self.assertIn(
                    word,
                    known_words,
                    f"Traza decision word {word!r} (story={traza.get('story')}, file={path.name}) "
                    "not present in words.json or story lines.palabras",
                )
        self.assertGreater(seen, 0)


class MultiLanguageFrenchTests(unittest.TestCase):
    def test_real_la_lluvia_game_pairs_with_synthetic_french_lines(self) -> None:
        game = _load_json(CONTENT_DIR / "games" / "la-lluvia.json")
        es_lines = _load_json(CONTENT_DIR / "lines" / "es" / "la-lluvia.json")

        fr_lines = {
            "format": ss.LINES_FORMAT,
            "id": "la-lluvia",
            "lang": "fr",
            "title": "La pluie",
            "place": "La maison",
            "focus_words": ["maison", "porte", "fenêtre", "mamie", "bonjour", "touche", "ouvre"],
            "names": copy.deepcopy(es_lines["names"]),
            "clips": {
                cid: {"who": clip["who"], "text": f"[fr] {clip['text']}"}
                for cid, clip in es_lines["clips"].items()
            },
        }
        fr_words = {
            "format": ss.WORDS_FORMAT,
            "lang": "fr",
            "words": {
                "ventana": "fenêtre",
                "puerta": "porte",
                "casa": "maison",
            },
        }

        self.assertEqual(ss.resolve_tested_word("ventana", fr_lines, fr_words), "fenêtre")
        self.assertEqual(ss.resolve_tested_word("puerta", fr_lines, fr_words), "porte")
        self.assertEqual(ss.resolve_tested_word("casa", fr_lines, fr_words), "maison")

        game_before = copy.deepcopy(game)
        joined_fr = ss.join_story(game, fr_lines)
        self.assertEqual(game, game_before)  # game file untouched
        self.assertEqual(joined_fr["id"], "la-lluvia")
        self.assertEqual(joined_fr["title"], "La pluie")
        self.assertEqual(joined_fr["place"], "La maison")
        self.assertEqual(joined_fr["scene"], "frente")
        self.assertEqual(joined_fr["beats"], game["beats"])
        self.assertEqual(joined_fr["clips"], fr_lines["clips"])
        self.assertNotIn("format", joined_fr)
        self.assertNotIn("lang", joined_fr)


class SafetyAndValidationTests(unittest.TestCase):
    def _minimal_story(self, sid: str = "demo") -> dict:
        return {
            "id": sid,
            "title": "Demo",
            "scene": "frente",
            "clips": {"c1": {"who": "narr", "text": "Hola."}},
            "beats": ["c1"],
        }

    def test_refuses_writing_to_historia_cuentos_and_subdirs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            src = tmp_path / "src"
            src.mkdir()
            (src / "demo.json").write_bytes(ss.render_json(self._minimal_story()))

            ss.split_directory(src, tmp_path / "safe_out")

            forbidden_targets = [
                REPO_ROOT / "historia" / "cuentos",
                REPO_ROOT / "historia" / "cuentos" / "nested",
                REPO_ROOT / "historia",
                REPO_ROOT / "historia" / "datos",
                tmp_path / "historia" / "cuentos",
                tmp_path / "historia" / "cuentos" / "sub",
            ]
            for target in forbidden_targets:
                with self.assertRaises(ValueError, msg=f"split_directory allowed {target}"):
                    ss.split_directory(src, target)
                with self.assertRaises(ValueError, msg=f"join_directory allowed {target}"):
                    ss.join_directory(
                        tmp_path / "safe_out" / "games",
                        tmp_path / "safe_out" / "lines" / "es",
                        target,
                    )

            # Also refuses writing output inside src_dir itself
            with self.assertRaises(ValueError):
                ss.split_directory(src, src)
            with self.assertRaises(ValueError):
                ss.split_directory(src, src / "nested")

    def test_unknown_top_level_keys_raise(self) -> None:
        bad_story = self._minimal_story()
        bad_story["unexpected_key"] = 42
        with self.assertRaises(ValueError):
            ss.split_story(bad_story)

        game, lines = ss.split_story(self._minimal_story())
        bad_game = copy.deepcopy(game)
        bad_game["mystery"] = True
        with self.assertRaises(ValueError):
            ss.join_story(bad_game, lines)

        bad_lines = copy.deepcopy(lines)
        bad_lines["extra"] = "nope"
        with self.assertRaises(ValueError):
            ss.join_story(game, bad_lines)

    def test_mismatched_id_invalid_format_and_cual_items_validation(self) -> None:
        game, lines = ss.split_story(self._minimal_story("one"))

        # Mismatched id
        other_lines = copy.deepcopy(lines)
        other_lines["id"] = "two"
        with self.assertRaises(ValueError):
            ss.join_story(game, other_lines)

        # Invalid format
        bad_game_fmt = copy.deepcopy(game)
        bad_game_fmt["format"] = "coqui.game.v99"
        with self.assertRaises(ValueError):
            ss.join_story(bad_game_fmt, lines)

        bad_lines_fmt = copy.deepcopy(lines)
        bad_lines_fmt["format"] = "coqui.lines.v99"
        with self.assertRaises(ValueError):
            ss.join_story(game, bad_lines_fmt)

        # cual item missing "w" on split
        bad_cual = {
            "id": "cual-bad",
            "title": "¿Cuál?",
            "tipo": "cual",
            "clips": {},
            "items": [{"say": "c1", "si": {}, "no": {}}],
        }
        with self.assertRaises(ValueError):
            ss.split_story(bad_cual)

        # cual mismatched item_words length on join
        good_cual = {
            "id": "cual-ok",
            "title": "¿Cuál?",
            "tipo": "cual",
            "clips": {},
            "items": [
                {"w": "casa", "say": "c1", "si": {}, "no": {}},
                {"w": "puerta", "say": "c2", "si": {}, "no": {}},
            ],
        }
        c_game, c_lines = ss.split_story(good_cual)
        self.assertEqual(c_lines["item_words"], ["casa", "puerta"])
        self.assertNotIn("w", c_game["items"][0])

        short_lines = copy.deepcopy(c_lines)
        short_lines["item_words"] = ["casa"]
        with self.assertRaises(ValueError):
            ss.join_story(c_game, short_lines)

        # item_words without items
        stray_lines = copy.deepcopy(lines)
        stray_lines["item_words"] = ["casa"]
        with self.assertRaises(ValueError):
            ss.join_story(game, stray_lines)

    def test_conflicting_palabras_in_word_table_raises(self) -> None:
        s1 = self._minimal_story("s1")
        s1["palabras"] = {"gato": "gato"}
        s2 = self._minimal_story("s2")
        s2["palabras"] = {"gato": "gata"}
        with self.assertRaises(ValueError):
            ss.build_word_table([s1, s2], lang="es")

    def test_split_directory_does_not_touch_src_dir_and_check_detects_drift(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            src = root / "src"
            out = root / "out"
            joined_out = root / "joined"
            src.mkdir()

            s1 = self._minimal_story("uno")
            s2 = {
                "id": "cual-uno",
                "title": "¿Cuál?",
                "tipo": "cual",
                "clips": {"c1": {"who": "narr", "text": "Casa."}},
                "items": [{"w": "casa", "say": "c1", "si": {}, "no": {}}],
            }
            (src / "uno.json").write_bytes(ss.render_json(s1))
            (src / "cual-uno.json").write_bytes(ss.render_json(s2))

            before_src = _tree_bytes(src)
            info = ss.split_directory(src, out, lang="es")
            self.assertEqual(info["stories"], 2)
            self.assertEqual(_tree_bytes(src), before_src)
            self.assertEqual(ss.check_directory(src, out, lang="es"), [])

            # join_directory round-trips cleanly
            count = ss.join_directory(out / "games", out / "lines" / "es", joined_out)
            self.assertEqual(count, 2)
            self.assertEqual(_load_json(joined_out / "uno.json"), s1)
            self.assertEqual(_load_json(joined_out / "cual-uno.json"), s2)

            # 1. Modified generated file detected by check_directory
            gpath = out / "games" / "uno.json"
            good_bytes = gpath.read_bytes()
            gpath.write_bytes(good_bytes.replace(b'"frente"', b'"patio"'))
            self.assertNotEqual(ss.check_directory(src, out, lang="es"), [])
            gpath.write_bytes(good_bytes)
            self.assertEqual(ss.check_directory(src, out, lang="es"), [])

            # 2. Missing generated file detected by check_directory
            lpath = out / "lines" / "es" / "uno.json"
            l_bytes = lpath.read_bytes()
            lpath.unlink()
            self.assertNotEqual(ss.check_directory(src, out, lang="es"), [])
            lpath.write_bytes(l_bytes)
            self.assertEqual(ss.check_directory(src, out, lang="es"), [])

            # 3. Extra stale file detected by check_directory and cleaned on next split
            extra = out / "games" / "stale.json"
            extra.write_text("{}", encoding="utf-8")
            self.assertNotEqual(ss.check_directory(src, out, lang="es"), [])
            ss.split_directory(src, out, lang="es")
            self.assertFalse(extra.exists())
            self.assertEqual(ss.check_directory(src, out, lang="es"), [])


if __name__ == "__main__":
    unittest.main()
