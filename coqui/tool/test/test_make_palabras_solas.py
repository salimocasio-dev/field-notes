"""Tests for coqui/tool/make_palabras_solas.py: pure rules on plain data, then the whole tool on a made-up course in a temp folder.

    python3 coqui/tool/test/test_make_palabras_solas.py

Checks the slug (case, accents, runs of other characters, trimmed), the collisions (tu/tú, esta/está, bebe/bebé: the accented word gets
_a, whatever the order and whether or not the other word gets a clip; the cases the rule cannot name are a Fault), the text of each kind
of word (plain, with an accent, a phrase, a question, an exclamation, a word that begins with a sign), that a word with a clip of its
own already gets none (case, signs and a whole text only; an accent counts), that an id of another file is a Fault, the order, the
shape of the file and its bytes, and, on a made-up tree, that the tool never reads its own file (two runs give the same bytes),
that --check says 0 for the file it made and 1 for a missing or a changed one, and that nothing but the one file is written.
`dart test tool/test` does not see this file (it looks for *_test.dart).
"""
import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import make_palabras_solas as ps  # noqa: E402


def ids_of(words):
    return ps.clip_ids(words)


class Slug(unittest.TestCase):
    def test_lower_case_and_accents_folded(self):
        self.assertEqual(ps.slug_of("puerta"), "puerta")
        self.assertEqual(ps.slug_of("Puerta"), "puerta")
        self.assertEqual(ps.slug_of("adiós"), "adios")
        self.assertEqual(ps.slug_of("pequeña"), "pequena")      # ñ too
        self.assertEqual(ps.slug_of("mamá"), "mama")
        self.assertEqual(ps.slug_of("pingüino"), "pinguino")    # ü too

    def test_a_run_of_other_characters_is_one_underscore(self):
        self.assertEqual(ps.slug_of("se sienta"), "se_sienta")
        self.assertEqual(ps.slug_of("hasta   mañana"), "hasta_manana")
        self.assertEqual(ps.slug_of("a - b"), "a_b")
        self.assertEqual(ps.slug_of("a, b!?"), "a_b")

    def test_the_signs_at_the_ends_are_trimmed(self):
        self.assertEqual(ps.slug_of("¿cómo estás?"), "como_estas")
        self.assertEqual(ps.slug_of("¿qué es esto?"), "que_es_esto")
        self.assertEqual(ps.slug_of("¡hola!"), "hola")
        self.assertEqual(ps.slug_of("¿y tú?"), "y_tu")

    def test_digits_stay(self):
        self.assertEqual(ps.slug_of("dos 2"), "dos_2")

    def test_nothing_to_name_it_by_is_a_fault(self):
        with self.assertRaises(ps.Fault):
            ps.slug_of("¿?")

    def test_a_decomposed_spelling_gives_the_same_slug(self):
        self.assertEqual(ps.slug_of("mamá"), "mama")


class Collisions(unittest.TestCase):
    def test_no_collision_no_suffix(self):
        self.assertEqual(ids_of(["casa", "puerta", "tú"]), {"casa": "w_casa", "puerta": "w_puerta", "tú": "w_tu"})

    def test_the_accented_word_gets_a(self):
        for words in (["tu", "tú"], ["tú", "tu"]):
            self.assertEqual(ids_of(words), {"tu": "w_tu", "tú": "w_tu_a"}, words)
        self.assertEqual(ids_of(["esta", "está"]), {"esta": "w_esta", "está": "w_esta_a"})
        self.assertEqual(ids_of(["está", "esta"]), {"esta": "w_esta", "está": "w_esta_a"})
        self.assertEqual(ids_of(["bebe", "bebé"]), {"bebe": "w_bebe", "bebé": "w_bebe_a"})
        self.assertEqual(ids_of(["bebé", "bebe"]), {"bebe": "w_bebe", "bebé": "w_bebe_a"})

    def test_all_three_pairs_among_the_others(self):
        ids = ids_of(["casa", "bebé", "tú", "está", "tu", "esta", "bebe", "este"])
        self.assertEqual(ids["bebé"], "w_bebe_a")
        self.assertEqual(ids["tú"], "w_tu_a")
        self.assertEqual(ids["está"], "w_esta_a")
        self.assertEqual({ids["bebe"], ids["tu"], ids["esta"], ids["este"], ids["casa"]}, {"w_bebe", "w_tu", "w_esta", "w_este", "w_casa"})
        self.assertEqual(len(set(ids.values())), len(ids))

    def test_the_ids_do_not_depend_on_which_words_get_a_clip(self):
        # tú keeps _a even when tu is not among the words that get a clip: the ids are decided over every tracked word.
        words = ["tu", "tú"]
        doc = ps.make_doc(words, [("cq_tu", "¡Tu!")])
        self.assertEqual(list(doc["clips"]), ["w_tu_a"])

    def test_a_group_the_rule_cannot_name_is_a_fault(self):
        with self.assertRaises(ps.Fault):
            ps.clip_ids(["tu", "Tu"])          # two without an accent
        with self.assertRaises(ps.Fault):
            ps.clip_ids(["tú", "tù"])          # two with an accent, none without
        with self.assertRaises(ps.Fault):
            ps.clip_ids(["tú", "tù", "tu"])    # more than one with an accent

    def test_a_suffixed_id_that_is_taken_is_a_fault(self):
        with self.assertRaises(ps.Fault):
            ps.clip_ids(["tu", "tú", "tu a"])  # "tu a" is w_tu_a

    def test_an_id_of_another_file_is_a_fault_naming_it(self):
        with self.assertRaises(ps.Fault) as cm:
            ps.make_doc(["casa", "puerta"], [("w_casa", "Otra cosa.")])
        self.assertIn("w_casa", str(cm.exception))
        self.assertNotIn("w_puerta", str(cm.exception))

    def test_an_id_of_another_file_is_no_fault_for_a_word_that_gets_no_clip(self):
        doc = ps.make_doc(["hola", "casa"], [("w_hola", "Algo."), ("cq_hola", "¡Hola!")])
        self.assertEqual(list(doc["clips"]), ["w_casa"])


class Text(unittest.TestCase):
    def test_a_plain_word(self):
        self.assertEqual(ps.text_of("puerta"), "Puerta.")
        self.assertEqual(ps.text_of("casa"), "Casa.")

    def test_an_accent_is_kept_and_a_first_letter_with_one_is_made_upper_case(self):
        self.assertEqual(ps.text_of("tú"), "Tú.")
        self.assertEqual(ps.text_of("él"), "Él.")
        self.assertEqual(ps.text_of("árbol"), "Árbol.")
        self.assertEqual(ps.text_of("pequeña"), "Pequeña.")
        self.assertEqual(ps.text_of("ñandú"), "Ñandú.")

    def test_only_the_first_letter_changes(self):
        self.assertEqual(ps.text_of("se sienta"), "Se sienta.")
        self.assertEqual(ps.text_of("hasta mañana"), "Hasta mañana.")
        self.assertEqual(ps.text_of("no hay"), "No hay.")
        self.assertEqual(ps.text_of("Casa"), "Casa.")

    def test_a_question_ends_as_it_is_and_the_letter_after_the_sign_is_the_one(self):
        self.assertEqual(ps.text_of("¿de qué color?"), "¿De qué color?")
        self.assertEqual(ps.text_of("¿dónde está?"), "¿Dónde está?")
        self.assertEqual(ps.text_of("¿quién?"), "¿Quién?")
        self.assertEqual(ps.text_of("¿y tú?"), "¿Y tú?")

    def test_an_exclamation_gets_no_full_stop(self):
        self.assertEqual(ps.text_of("¡hola!"), "¡Hola!")
        self.assertEqual(ps.text_of("hola!"), "Hola!")

    def test_a_word_that_ends_in_a_full_stop_gets_no_second(self):
        self.assertEqual(ps.text_of("etc."), "Etc.")

    def test_a_word_with_no_letter_is_a_fault(self):
        with self.assertRaises(ps.Fault):
            ps.text_of("¿?")


class Existing(unittest.TestCase):
    WORDS = ["hola", "tú", "tu", "¿cómo estás?", "no más", "jugo", "abuela", "casa"]

    def doc(self, existing):
        return ps.make_doc(self.WORDS, existing)

    def texts(self, existing):
        return [c["text"] for c in self.doc(existing)["clips"].values()]

    def test_no_existing_clip_every_word_gets_one_in_the_order_of_the_words(self):
        self.assertEqual(self.texts([]), ["Hola.", "Tú.", "Tu.", "¿Cómo estás?", "No más.", "Jugo.", "Abuela.", "Casa."])

    def test_a_clip_whose_whole_text_is_the_word_gives_it_none_case_and_signs_ignored(self):
        got = self.texts([("a", "¡Hola!"), ("b", "Jugo?"), ("c", "NO MÁS."), ("d", "¿Cómo estás?")])
        self.assertEqual(got, ["Tú.", "Tu.", "Abuela.", "Casa."])

    def test_a_word_inside_a_longer_text_still_gets_a_clip(self):
        got = self.texts([("a", "Abuela dice: ¡Hola!"), ("b", "Hola, abuela."), ("c", "Hola hola."), ("d", "Mira la casa.")])
        self.assertEqual(len(got), 8)

    def test_an_accent_counts(self):
        got = self.texts([("a", "¡Tú!")])
        self.assertEqual(got, ["Hola.", "Tu.", "¿Cómo estás?", "No más.", "Jugo.", "Abuela.", "Casa."])
        got = self.texts([("a", "Tu.")])
        self.assertEqual(got, ["Hola.", "Tú.", "¿Cómo estás?", "No más.", "Jugo.", "Abuela.", "Casa."])

    def test_the_same_clip_in_two_files_is_one_clip(self):
        got = self.texts([("a", "¡Hola!"), ("a", "¡Hola!")])
        self.assertNotIn("Hola.", got)

    def test_the_words_that_have_one_are_a_count_of_the_words_not_the_clips(self):
        self.assertEqual(len(self.doc([("a", "Hola."), ("b", "Hola."), ("c", "¡Hola!")])["clips"]), len(self.WORDS) - 1)


class Shape(unittest.TestCase):
    def test_the_file(self):
        doc = ps.make_doc(["casa", "¿cómo estás?"], [])
        self.assertEqual(list(doc), ["id", "title", "tipo", "note", "clips"])
        self.assertEqual(doc["id"], "palabras-solas")
        self.assertEqual(doc["title"], "Palabras")
        self.assertEqual(doc["tipo"], "palabras")
        self.assertEqual(doc["note"], "Each tracked word alone, for the word tiles of Repaso (docs/proyecto/15-repaso-juegos.md). "
                                       "Made by coqui/tool/make_palabras_solas.py; not a story.")
        self.assertEqual(doc["clips"], {"w_casa": {"who": "narr", "text": "Casa."}, "w_como_estas": {"who": "narr", "text": "¿Cómo estás?"}})
        self.assertEqual(list(doc["clips"]["w_casa"]), ["who", "text"])

    def test_the_bytes(self):
        b = ps.render(ps.make_doc(["casa", "tú", "tu"], []))
        s = b.decode("utf-8")
        self.assertIn("Tú.", s)                    # not ú: the accents are written as they are
        self.assertNotIn("\\u", s)
        self.assertFalse(s.endswith("\n"))         # as the files the gen_*.py tools write
        self.assertTrue(s.startswith('{\n "id": "palabras-solas",\n'))
        self.assertEqual(json.loads(s)["clips"]["w_tu_a"]["text"], "Tú.")
        self.assertNotIn(b"\xef\xbb\xbf", b)       # no byte order mark

    def test_the_same_input_gives_the_same_bytes(self):
        words = ["casa", "tú", "tu", "¿de qué color?", "no más", "bebé", "bebe"]
        ex = [("x", "¡No más!"), ("y", "Hola.")]
        self.assertEqual(ps.render(ps.make_doc(words, ex)), ps.render(ps.make_doc(list(words), list(ex))))

    def test_the_order_of_the_clips_is_the_order_of_the_words(self):
        words = ["zorro", "abeja", "mono", "casa"]
        self.assertEqual(list(ps.make_doc(words, [])["clips"]), ["w_zorro", "w_abeja", "w_mono", "w_casa"])


def write(p, obj):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(obj, ensure_ascii=False, indent=1), encoding="utf-8")


def made_up_tree(root):
    """A course of two stories, a review set and a book-less folder: the words are tú, tu, está, esta, casa, hola, ¿cómo estás?, no más."""
    H = Path(root) / "historia"
    write(H / "datos" / "curso.json", {
        "lugares": [{"id": "uno", "n": 1, "nombre": "Uno", "en": "One", "cuentos": ["s1", "s2"], "dibujos": [], "haz": [], "escenas": []}],
        "cuentos": {"s1": {"t": "S1", "min": 2}, "s2": {"t": "S2", "min": 2}},
        "cual": ["cual-uno"]})
    write(H / "audio" / "ready.json", {"clips": ["a_hola"], "hechos": {"a_hola": "x"}, "v": 1})
    write(H / "cuentos" / "s1.json", {"id": "s1", "title": "S1", "focus_words": ["casa", "hola", "tú"], "back_again": [],
                                      "clips": {"a_hola": {"who": "narr", "text": "¡Hola!"}, "b_casa": {"who": "narr", "text": "Es la casa."}}})
    write(H / "cuentos" / "s2.json", {"id": "s2", "title": "S2", "focus_words": ["tu", "está", "esta"], "back_again": ["¿cómo estás?", "no más", "casa"],
                                      "clips": {"c_nomas": {"who": "narr", "text": "No más."}, "d_tu": {"who": "narr", "text": "Tu casa."}}})
    write(H / "cuentos" / "cual-uno.json", {"id": "cual-uno", "tipo": "cual", "clips": {"e_x": {"who": "narr", "text": "Esta es la casa."}}, "items": []})
    (H / "libros").mkdir(parents=True, exist_ok=True)


def run(*args):
    out, err = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        code = ps.main(list(args))
    return code, out.getvalue(), err.getvalue()


def tree_bytes(root):
    return {str(p.relative_to(root)): p.read_bytes() for p in sorted(Path(root).rglob("*")) if p.is_file()}


class WholeTool(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        made_up_tree(self.root)
        self.file = self.root / "historia" / "cuentos" / "palabras-solas.json"

    def tearDown(self):
        self.tmp.cleanup()

    def test_it_writes_the_one_file_and_nothing_else(self):
        before = tree_bytes(self.root)
        code, out, _ = run("--repo", str(self.root))
        self.assertEqual(code, 0, out)
        after = tree_bytes(self.root)
        self.assertEqual(set(after) - set(before), {"historia/cuentos/palabras-solas.json"})
        for k, v in before.items():
            self.assertEqual(after[k], v, k)
        doc = json.loads(self.file.read_text(encoding="utf-8"))
        self.assertEqual(len(doc["clips"]), 6)     # 8 words; hola (¡Hola!) and no más (No más.) have a clip already

    def test_which_words_get_a_clip_and_which_ids(self):
        run("--repo", str(self.root))
        doc = json.loads(self.file.read_text(encoding="utf-8"))
        got = {k: v["text"] for k, v in doc["clips"].items()}
        # course order: casa, hola, tú, tu, está, esta, ¿cómo estás?, no más. hola and no más have a clip already.
        self.assertEqual(list(got.items()), [("w_casa", "Casa."), ("w_tu_a", "Tú."), ("w_tu", "Tu."), ("w_esta_a", "Está."),
                                              ("w_esta", "Esta."), ("w_como_estas", "¿Cómo estás?")])

    def test_two_runs_give_the_same_bytes_the_tool_never_reads_its_own_file(self):
        run("--repo", str(self.root))
        first = self.file.read_bytes()
        code, _, _ = run("--repo", str(self.root))
        self.assertEqual(code, 0)
        self.assertEqual(self.file.read_bytes(), first)
        self.assertIn(b"Casa.", first)     # its own clips did not make "casa" a word that is already said
        run("--repo", str(self.root))
        self.assertEqual(self.file.read_bytes(), first)

    def test_check(self):
        code, _, err = run("--repo", str(self.root), "--check")
        self.assertEqual(code, 1)
        self.assertIn("not there", err)
        self.assertFalse(self.file.exists())               # --check writes nothing
        run("--repo", str(self.root))
        code, out, _ = run("--repo", str(self.root), "--check")
        self.assertEqual(code, 0)
        self.assertIn("6 clips", out)
        good = self.file.read_bytes()
        self.file.write_bytes(good.replace(b"Casa.", b"Casa"))
        code, _, err = run("--repo", str(self.root), "--check")
        self.assertEqual(code, 1)
        self.assertIn("not what the tool makes", err)
        self.assertEqual(self.file.read_bytes(), good.replace(b"Casa.", b"Casa"))   # still not written
        self.file.write_bytes(good + b"\n")                 # a newline at the end is a difference too
        self.assertEqual(run("--repo", str(self.root), "--check")[0], 1)
        self.file.write_bytes(good)
        self.assertEqual(run("--repo", str(self.root), "--check")[0], 0)

    def test_a_story_that_changes_changes_the_file(self):
        run("--repo", str(self.root))
        write(self.root / "historia" / "cuentos" / "s2.json", {
            "id": "s2", "title": "S2", "focus_words": ["tu", "está", "esta"], "back_again": ["¿cómo estás?", "no más", "casa"],
            "clips": {"c_nomas": {"who": "narr", "text": "No más."}, "d_casa": {"who": "narr", "text": "¡Casa!"}}})
        self.assertEqual(run("--repo", str(self.root), "--check")[0], 1)
        run("--repo", str(self.root))
        self.assertNotIn("w_casa", json.loads(self.file.read_text(encoding="utf-8"))["clips"])

    def test_an_id_clash_stops_and_writes_nothing(self):
        write(self.root / "historia" / "cuentos" / "s3.json", {"id": "s3", "clips": {"w_casa": {"who": "narr", "text": "Algo."}}})
        code, out, err = run("--repo", str(self.root))
        self.assertEqual(code, 1)
        self.assertIn("STOP", err)
        self.assertIn("w_casa", err)
        self.assertFalse(self.file.exists())
        self.assertEqual(run("--repo", str(self.root), "--check")[0], 1)


if __name__ == "__main__":
    unittest.main()
