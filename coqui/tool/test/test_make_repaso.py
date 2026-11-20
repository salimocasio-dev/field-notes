"""Tests for coqui/tool/make_repaso.py: a made-up story and book in a temp folder.

    python3 coqui/tool/test/test_make_repaso.py

Checks rules 2a (accents kept; a word inside a longer tracked phrase), 2b (a word only in the speaker tag), 2c (a question line),
2d (a line heard only after a wrong touch), 2e (a correction), 2f (three words after the tag), rule 3 (fair wrong pictures:
distance, plural, farthest first) and that two runs give the same bytes. `dart test tool/test` does not see this file (it looks
for *_test.dart).
"""
import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import make_repaso as mr  # noqa: E402

TRACKED = ["él", "el", "tú", "tu", "está", "esta", "bebé", "bebe", "no hay", "no", "hay", "de nada", "nada", "abuela", "mira", "hola",
           "flor", "casa", "pan", "perro", "gato"]

# clip id -> text of the first story ("uno"). Every one is played by the beats below unless a comment says otherwise.
UNO = {
    "a_el": "Él come pan en casa.",                     # él, not el (2a: accents)
    "b_el": "El perro come pan aquí.",                  # el (and perro, pan), not él
    "c_tu": "Tú tienes tu pan aquí.",                   # tú and tu
    "d_esta": "Esta casa está aquí ahora.",             # esta and está
    "e_bebe": "El bebé bebe agua ahora.",               # bebé, bebe, el
    "f_nohay": "No hay pan aquí ahora.",                # "no hay" only: not no, not hay (2a: phrase inside phrase)
    "g_nada": "No quiero nada aquí.",                   # no and nada
    "h_denada": "De nada, abuela amiga.",               # "de nada" only, not nada
    "i_tag": "Abuela dice: Come pan ahora.",            # abuela only in the tag: no candidate for abuela (2b)
    "j_body": "Luis dice: Abuela come pan ya.",         # abuela in the body: a candidate
    "k_corr": "No, Coquí. Mira el pan aquí.",           # a correction (2e): no candidate for mira
    "l_mira": "Mira el pan aquí.",                      # mira: a candidate
    "m_short": "Abuela dice: Hola pan.",                # two words after the tag (2f): none
    "n_three": "Abuela dice: Hola pan ahora.",          # three words: hola is a candidate
    "o_name": "Mira a Luis con el pan.",               # a name in it; starts with mira (atada al dibujo)
    "q_question": "¿Dónde está el gato aquí?",          # the question line of the decide (2c)
    "r_right": "El gato está aquí ahora.",              # right branch: reached
    "w_wrong": "Luis dice: El perro no está aquí.",     # wrong branch only (2d)
    "z_unused": "El perro corre aquí ahora.",           # named by no step: not placed, not a candidate
}
UNO_BEATS = ["a_el", "b_el", "c_tu", "d_esta", "e_bebe", "f_nohay", "g_nada", "h_denada", "i_tag", "j_body", "k_corr", "l_mira", "o_name", "m_short", "n_three",
             {"decide": "do", "options": ["si", "no"], "pick": "si", "line": "q_question", "right": ["r_right"], "wrong": ["w_wrong"]}]

# the second story and its book: pictures and texts for rule 3. Pages 1 to 5.
DOS = {"p1": "Mira la flor roja.", "p2": "El perro come pan.", "p3": "Las flores son rojas.", "p4": "El gato duerme aquí.", "p5": "La casa es grande."}


def make_repo(root):
    root = Path(root)
    (root / "historia" / "datos").mkdir(parents=True)
    (root / "historia" / "audio").mkdir()
    (root / "historia" / "cuentos").mkdir()
    (root / "historia" / "libros" / "img").mkdir(parents=True)
    (root / "docs" / "hablar").mkdir(parents=True)

    def dump(p, o):
        with open(root / p, "w", encoding="utf-8") as f:
            json.dump(o, f, ensure_ascii=False)

    dump("historia/datos/curso.json", {"lugares": [{"id": "casa", "n": 1, "cuentos": ["uno", "dos"], "dibujos": []}], "cuentos": {}, "cual": []})
    dump("historia/datos/fijos.json", {"clips": {"story_your_turn": "ahora_tu", "story_praise": "muy_bien", "story_routine_no_prefix": "hz_no_"}, "lineas": {}})
    clips = {k: {"who": "narr", "text": t} for k, t in UNO.items()}
    clips["muy_bien"] = {"who": "narr", "text": "¡Muy bien!"}
    dump("historia/cuentos/uno.json", {"id": "uno", "focus_words": TRACKED[:12], "back_again": [], "also_heard": ["come"], "clips": clips, "beats": UNO_BEATS})
    dump("historia/cuentos/dos.json", {"id": "dos", "focus_words": TRACKED[12:], "back_again": [],
                                       "clips": {k: {"who": "narr", "text": t} for k, t in DOS.items()}, "beats": list(DOS)})
    dump("historia/audio/ready.json", {"voces": {}, "clips": sorted(set(clips) | set(DOS))})
    dump("historia/libros/uno.json", {"id": "uno", "pages": [{"img": "img/uno-1.png", "clips": ["a_el"]}]})
    dump("historia/libros/dos.json", {"id": "dos", "pages": [{"img": "img/dos-%d.png" % n, "clips": [k]} for n, k in enumerate(DOS, 1)]})
    from PIL import Image
    for n in range(1, 6):
        Image.new("RGB", (8, 8), (n * 40, 0, 0)).save(root / "historia" / "libros" / "img" / ("dos-%d.png" % n))
    Image.new("RGB", (8, 8), (255, 255, 255)).save(root / "historia" / "libros" / "img" / "uno-1.png")
    dump("docs/hablar/02-marcas.json", {})


class MakeRepaso(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        make_repo(cls.tmp.name)
        cls.R = mr.build(cls.tmp.name)
        cls.C = cls.R["cands"]

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def words_of(self, clip, story=None):
        return sorted(c["word"] for c in self.C if c["clip"] == clip and (story is None or c["story"] == story))

    def assertWords(self, clip, has=(), hasnt=()):
        got = self.words_of(clip)
        for w in has:
            self.assertIn(w, got, "%s should be a candidate for %r, got %r" % (clip, w, got))
        for w in hasnt:
            self.assertNotIn(w, got, "%s should not be a candidate for %r, got %r" % (clip, w, got))

    # rule 2a
    def test_accents_kept(self):
        self.assertWords("a_el", has=["él"], hasnt=["el"])
        self.assertWords("b_el", has=["el"], hasnt=["él"])
        self.assertWords("c_tu", has=["tú", "tu"])
        self.assertWords("d_esta", has=["esta", "está"])
        self.assertWords("e_bebe", has=["bebé", "bebe", "el"])

    def test_phrase_inside_phrase(self):
        self.assertWords("f_nohay", has=["no hay"], hasnt=["no", "hay"])
        self.assertWords("g_nada", has=["no", "nada"])                          # alone, both count
        self.assertWords("h_denada", has=["de nada"], hasnt=["nada"])

    # rule 2b
    def test_word_only_in_tag(self):
        self.assertWords("i_tag", has=["pan"], hasnt=["abuela"])                # abuela is only in the tag
        self.assertWords("j_body", has=["abuela", "pan"])
        c = next(c for c in self.C if c["clip"] == "i_tag")
        self.assertTrue(c["tag"])
        self.assertEqual(c["text_sin_tag"], "Come pan ahora.")
        self.assertEqual(c["tokens"], ["come", "pan", "ahora"])
        self.assertEqual(c["n_tokens"], 3)

    # rule 2e
    def test_correction(self):
        self.assertEqual(self.words_of("k_corr"), [])                           # no candidate at all
        self.assertWords("l_mira", has=["mira", "pan"])

    # rule 2f
    def test_more_than_two_words_after_the_tag(self):
        self.assertEqual(self.words_of("m_short"), [])
        self.assertWords("n_three", has=["hola", "pan"])

    # rule 2c and 2d
    def test_question_and_wrong_branch(self):
        self.assertEqual(self.words_of("q_question"), [])                      # the question line of the decide
        self.assertEqual(self.words_of("w_wrong"), [])                         # heard only after a wrong touch
        self.assertEqual(self.words_of("z_unused"), [])                        # named by no step
        self.assertWords("r_right", has=["gato"])                              # right branch: reached
        self.assertEqual(self.R["classes"]["uno"]["which"]["w_wrong"], "solo_error")
        self.assertEqual(self.R["classes"]["uno"]["which"]["z_unused"], "sin_lugar")
        self.assertEqual(self.R["classes"]["uno"]["which"]["q_question"], "pregunta")

    # flags
    def test_flags(self):
        c = next(c for c in self.C if c["clip"] == "j_body" and c["word"] == "abuela")
        self.assertFalse(c["tiene_nombre"])                                    # the name is in the tag, which is taken off
        self.assertEqual(c["token_no_enseñado"], ["ya"])                       # come is also_heard; ya is not taught
        c = next(c for c in self.C if c["clip"] == "o_name" and c["word"] == "pan")
        self.assertTrue(c["tiene_nombre"])
        self.assertTrue(c["atada_al_dibujo"])
        c = next(c for c in self.C if c["clip"] == "l_mira" and c["word"] == "mira")
        self.assertTrue(c["atada_al_dibujo"])
        c = next(c for c in self.C if c["clip"] == "g_nada" and c["word"] == "nada")
        self.assertFalse(c["atada_al_dibujo"])
        c = next(c for c in self.C if c["clip"] == "b_el" and c["word"] == "el")
        self.assertEqual(c["cluster"], next(x for x in self.C if x["clip"] == "b_el" and x["word"] == "perro")["cluster"])

    # rule 3
    def test_fair_wrong_pictures(self):
        c = next(c for c in self.C if c["story"] == "dos" and c["clip"] == "p1" and c["word"] == "flor")
        self.assertEqual(c["pagina"]["page"], 1)
        # page 2 is one page away; page 3 holds "flores" (a plural of the tracked flor); 4 and 5 are fair; farthest first
        self.assertEqual([w["page"] for w in c["wrong_pictures"]], [5, 4])
        self.assertEqual([w["distance"] for w in c["wrong_pictures"]], [4, 3])
        self.assertTrue(all(w["img"].startswith("historia/libros/img/dos-") for w in c["wrong_pictures"]))

    def test_wrong_pictures_leave_out_a_page_with_a_word_of_the_sentence(self):
        # p2 "El perro come pan." holds el, perro and pan: page 4 "El gato duerme aquí." holds el, so only page 5 is fair
        # (page 1 and 3 are 1 away)
        c = next(c for c in self.C if c["story"] == "dos" and c["clip"] == "p2" and c["word"] == "pan")
        self.assertEqual([w["page"] for w in c["wrong_pictures"]], [5])
        c = next(c for c in self.C if c["story"] == "dos" and c["clip"] == "p5" and c["word"] == "casa")
        self.assertEqual([w["page"] for w in c["wrong_pictures"]], [1, 2, 3])   # page 4 is one away; the rest are fair; farthest first

    # determinism
    def test_same_bytes_twice(self):
        outs = []
        for i in range(2):
            d = Path(self.tmp.name) / ("out%d" % i)
            mr.main(["--out", str(d), "--repo", self.tmp.name])
            outs.append(d)
        for name in ("candidatos.json", "resumen.md"):
            h = [hashlib.sha256((d / name).read_bytes()).hexdigest() for d in outs]
            self.assertEqual(h[0], h[1], name)
        files = sorted(p.relative_to(outs[0] / "hojas") for p in (outs[0] / "hojas").rglob("*") if p.is_file())
        self.assertTrue(any(str(f).endswith(".png") for f in files))
        for f in files:
            self.assertEqual((outs[0] / "hojas" / f).read_bytes(), (outs[1] / "hojas" / f).read_bytes(), str(f))

    def test_sheet_key_matches_sheets(self):
        d = Path(self.tmp.name) / "outk"
        mr.main(["--out", str(d), "--repo", self.tmp.name])
        claves = json.loads((d / "hojas" / "claves.json").read_text(encoding="utf-8"))
        n_with_page = sum(1 for c in self.C if c["pagina"])
        self.assertEqual(len(claves), n_with_page)
        for num, k in claves.items():
            self.assertTrue((d / "hojas" / k["book"] / (num + ".png")).exists())
            self.assertIn(k["right"], k["letters"])
        # the sheets' list says nothing about which letter is right
        for line in (d / "hojas" / "dos" / "hojas.jsonl").read_text(encoding="utf-8").splitlines():
            self.assertEqual(sorted(json.loads(line)), ["n", "text", "word"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
