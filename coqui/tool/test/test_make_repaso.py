"""Tests for coqui/tool/make_repaso.py: a made-up story and book in a temp folder.

    python3 coqui/tool/test/test_make_repaso.py

Checks rules 2a (accents kept; a word inside a longer tracked phrase), 2b (a word only in the speaker tag), 2c (a question line),
2d (a line heard only after a wrong touch), 2e (a correction), 2f (three words after the tag), rule 3 (fair wrong pictures:
distance, plural, farthest first) and that two runs give the same bytes. The readers' step (--hojas-libro, --valida-veredictos,
--veredictos --final) is tested with made-up verdicts: the validator (each kind of fault), `cual` (parecidas, own page not in si,
farthest first, at most 3), `puntua`, `falsas`, Parejas (a set of 4, the fallback to 3, words that differ), the fixed shuffle, and
that two runs give the same bytes. `dart test tool/test` does not see this file (it looks for *_test.dart).
"""
import contextlib
import hashlib
import io
import itertools
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
    "y_long": "Abuela come pan aquí con mamá y papá en casa ahora.",   # 11 words, on page 1 of the book of uno: no page-free use
}
UNO_BEATS = ["a_el", "b_el", "c_tu", "d_esta", "e_bebe", "f_nohay", "g_nada", "h_denada", "i_tag", "j_body", "k_corr", "l_mira", "o_name", "m_short", "n_three", "y_long",
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

    dump("historia/datos/curso.json", {"lugares": [{"id": "casa", "n": 1, "cuentos": ["uno", "dos"], "dibujos": []}], "cuentos": {}, "cual": ["cual-x"]})
    dump("historia/cuentos/cual-x.json", {"id": "cual-x", "scene": "frente", "clips": {"esta_casa": {"who": "narr", "text": "Esta es la casa."}},
                                          "items": [{"w": "casa", "say": "esta_casa", "si": {"cam": [1, 2, 3, 4]}, "no": {"cam": [5, 6, 7, 8]}}]})
    dump("historia/datos/fijos.json", {"clips": {"story_your_turn": "ahora_tu", "story_praise": "muy_bien", "story_routine_no_prefix": "hz_no_"}, "lineas": {}})
    clips = {k: {"who": "narr", "text": t} for k, t in UNO.items()}
    clips["muy_bien"] = {"who": "narr", "text": "¡Muy bien!"}
    dump("historia/cuentos/uno.json", {"id": "uno", "focus_words": TRACKED[:12], "back_again": [], "also_heard": ["come"], "clips": clips, "beats": UNO_BEATS})
    dump("historia/cuentos/dos.json", {"id": "dos", "focus_words": TRACKED[12:], "back_again": [],
                                       "clips": {k: {"who": "narr", "text": t} for k, t in DOS.items()}, "beats": list(DOS)})
    dump("historia/audio/ready.json", {"voces": {}, "clips": sorted(set(clips) | set(DOS))})
    dump("historia/libros/uno.json", {"id": "uno", "pages": [{"img": "img/uno-1.png", "clips": ["a_el", "y_long"]}]})
    dump("historia/libros/dos.json", {"id": "dos", "pages": [{"img": "img/dos-%d.png" % n, "clips": [k]} for n, k in enumerate(DOS, 1)]})
    from PIL import Image
    for n in range(1, 6):
        Image.new("RGB", (8, 8), (n * 40, 0, 0)).save(root / "historia" / "libros" / "img" / ("dos-%d.png" % n))
    Image.new("RGB", (8, 8), (255, 255, 255)).save(root / "historia" / "libros" / "img" / "uno-1.png")
    dump("docs/hablar/02-marcas.json", {"uno": {"l_mira": [{"palabra": "mira", "formas": ["mira", "mirá"]}]}})


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


# ---------------------------------------------------------------------------------------------------------------- the readers' step

def sent(i, own, words=("w",), pages=None, book="b"):
    """A made-up sentence row, as sentences_by_book makes them."""
    return {"id": "%s:%d" % (book, i), "k": i, "clip": "c%d" % i, "text": "t%d" % i, "own": own, "pages": pages or [own], "words": list(words)}


def quiet(argv):
    """mr.main with its one line of output kept out of the test run; -> its exit code."""
    with contextlib.redirect_stdout(io.StringIO()):
        return mr.main(argv)


def verd(si=(), no=(), duda=()):
    return {"si": set(si), "no": set(no), "duda": set(duda)}


def pairs(*ps):
    return {frozenset(p) for p in ps}


class Rules(unittest.TestCase):
    """The rules of the final data on plain values."""

    # cual
    def test_cual_farthest_first_at_most_three(self):
        v = verd(si=[5], no=[1, 2, 3, 4, 6, 7])
        # distances from 5: 1 -> 4, 2 -> 3, 3 -> 2, 7 -> 2, 4 -> 1, 6 -> 1; farthest first, the lower page first on a tie; three at most
        self.assertEqual(mr.cual_pages(5, [], v, set()), [1, 2, 3])
        self.assertEqual(mr.cual_pages(5, [], verd(si=[5], no=[4, 6, 7, 3]), set()), [3, 7, 4])
        self.assertEqual(mr.cual_pages(5, [], verd(si=[5], no=[6]), set()), [6])          # fewer than three is fine
        self.assertEqual(mr.cual_pages(5, [], verd(si=[5], no=[]), set()), [])

    def test_cual_leaves_out_pages_parecidas_with_the_own_page(self):
        v = verd(si=[5], no=[1, 2, 3, 4, 6, 7])
        self.assertEqual(mr.cual_pages(5, [], v, pairs((5, 1))), [2, 3, 7])               # page 1 looks like the own page: out
        self.assertEqual(mr.cual_pages(5, [], v, pairs((1, 5), (2, 5), (3, 5))), [7, 4, 6])
        self.assertEqual(mr.cual_pages(5, [], v, pairs((1, 2), (3, 4))), [1, 2, 3])       # two other pages that look alike: no matter

    def test_cual_empty_when_the_own_page_is_not_si(self):
        self.assertEqual(mr.cual_pages(5, [], verd(duda=[5], no=[1, 2]), set()), [])
        self.assertEqual(mr.cual_pages(5, [], verd(no=[5, 1, 2]), set()), [])
        self.assertEqual(mr.cual_pages(5, [], verd(si=[1], no=[2, 3]), set()), [])         # si, but for another page

    def test_cual_leaves_out_the_other_pages_of_the_same_sentence(self):
        v = verd(si=[3], no=[1, 7, 8])                                                      # the sentence also stands on page 7
        self.assertEqual(mr.cual_pages(3, [7], v, set()), [8, 1])
        self.assertEqual(mr.cual_pages(3, [7], v, pairs((8, 7))), [1])

    # puntua
    def test_puntua(self):
        it = lambda cual, oyes: {"cual": cual, "que_oyes": oyes}
        self.assertEqual(mr.puntua([it([2], True)], None), "cual")
        self.assertEqual(mr.puntua([it([], True), it([4, 5], False)], None), "cual")
        self.assertEqual(mr.puntua([it([], True)], {"clip": "x"}), "cual")                 # a picture pair is enough
        self.assertEqual(mr.puntua([], {"clip": "x"}), "cual")
        self.assertEqual(mr.puntua([it([], True), it([], False)], None), "que_oyes")
        self.assertEqual(mr.puntua([it([], False)], None), "nada")
        self.assertEqual(mr.puntua([], None), "nada")

    # falsas
    def test_falsas(self):
        S = [sent(1, 1), sent(2, 2), sent(3, 5), sent(4, 6), sent(5, 7), sent(6, 3), sent(7, 4)]
        V = {s["id"]: verd(si=[s["own"]], no=[3]) for s in S}
        V["b:6"] = verd(si=[3], no=[])                              # stands on page 3: not false for it
        V["b:7"] = verd(si=[4], duda=[3])                           # the reader was unsure: not false
        # page 3: s5 (own 7, 4 away), s4 (6, 3), s3 (5, 2) but parecidas with 3 -> out, s1 (1, 2), s2 (2, 1)
        got = mr.falsas_for_page(S, V, pairs((5, 3)), 3)
        self.assertEqual([g["clip"] for g in got], ["c5", "c4", "c1", "c2"])
        self.assertEqual(got[0], {"clip": "c5", "text": "t5"})
        self.assertEqual([g["clip"] for g in mr.falsas_for_page(S, V, set(), 3)], ["c5", "c4", "c1", "c3", "c2"])

    def test_falsas_at_most_six_farthest_first(self):
        S = [sent(i, i) for i in range(1, 12)]
        V = {s["id"]: verd(si=[s["own"]], no=[6]) for s in S}
        got = mr.falsas_for_page(S, V, set(), 6)
        self.assertEqual([g["clip"] for g in got], ["c1", "c11", "c2", "c10", "c3", "c9"])  # 5 and 5 away, then 4 and 4, then 3 and 3
        V["b:6"] = verd(si=[6])
        self.assertEqual(len(mr.falsas_for_page(S, V, set(), 6)), 6)

    # Parejas
    def all_no(self, S):
        return {s["id"]: verd(si=s["pages"], no=[p for t in S for p in t["pages"] if p not in s["pages"]]) for s in S}

    def test_parejas_a_set_of_four(self):
        S = [sent(i, i, words=["w%d" % i]) for i in range(1, 6)]
        sets = mr.parejas_for_book(S, self.all_no(S), set(), {"w%d" % i: i for i in range(1, 6)})
        self.assertEqual([[s["clip"] for s in st] for st in sets], [["c1", "c2", "c3", "c4"]])   # the fifth is left; no second set of 3

    def test_parejas_up_to_three_sets_on_fresh_pages(self):
        S = [sent(i, i, words=["w%d" % i]) for i in range(1, 14)]
        sets = mr.parejas_for_book(S, self.all_no(S), set(), {"w%d" % i: i for i in range(1, 14)})
        self.assertEqual([[s["own"] for s in st] for st in sets], [[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12]])

    def test_parejas_falls_back_to_three(self):
        S = [sent(i, i, words=["w%d" % i]) for i in range(1, 5)]
        wi = {"w%d" % i: i for i in range(1, 5)}
        # pages 1 and 2 look alike: no set of 4; the first set of 3 in the order of the pages
        sets = mr.parejas_for_book(S, self.all_no(S), pairs((1, 2)), wi)
        self.assertEqual([[s["own"] for s in st] for st in sets], [[1, 3, 4]])
        # pages 2 and 4 are `duda` for the sentence of page 1 (not `no`): it can stand with page 3 only, so a set of 3 is made without it
        V = self.all_no(S)
        V["b:1"] = verd(si=[1], no=[3], duda=[2, 4])
        sets = mr.parejas_for_book(S, V, set(), wi)
        self.assertEqual([[s["own"] for s in st] for st in sets], [[2, 3, 4]])
        # a sentence whose own page is not si is not used at all
        V = self.all_no(S)
        V["b:2"] = verd(duda=[2], no=[1, 3, 4])
        sets = mr.parejas_for_book(S, V, set(), wi)
        self.assertEqual([[s["own"] for s in st] for st in sets], [[1, 3, 4]])
        # nothing when fewer than three can stand together
        self.assertEqual(mr.parejas_for_book(S, self.all_no(S), pairs((1, 2), (3, 4)), wi), [])

    def test_parejas_prefers_sentences_of_different_words(self):
        S = [sent(1, 1, ["a"]), sent(2, 2, ["a"]), sent(3, 3, ["b"]), sent(4, 4, ["c"]), sent(5, 5, ["d"])]
        wi = {"a": 1, "b": 2, "c": 3, "d": 4}
        sets = mr.parejas_for_book(S, self.all_no(S), set(), wi)
        self.assertEqual([[s["own"] for s in st] for st in sets], [[1, 3, 4, 5]])           # not the first four by page: 1 and 2 share `a`
        S = [sent(1, 1, ["a"]), sent(2, 2, ["a"]), sent(3, 3, ["b"]), sent(4, 4, ["c"])]
        sets = mr.parejas_for_book(S, self.all_no(S), set(), wi)
        self.assertEqual([[s["own"] for s in st] for st in sets], [[1, 2, 3, 4]])           # no set of 4 without a shared word: a set of 4 still

    def test_parejas_a_sentence_on_two_pages(self):
        S = [sent(1, 3, pages=[3, 7]), sent(2, 5), sent(3, 6), sent(4, 8)]
        V = {"b:1": verd(si=[3, 7], no=[5, 6, 8]), "b:2": verd(si=[5], no=[3, 6, 7, 8]), "b:3": verd(si=[6], no=[3, 5, 7, 8]), "b:4": verd(si=[8], no=[3, 5, 6, 7])}
        self.assertEqual([len(st) for st in mr.parejas_for_book(S, V, set(), {"w": 1})], [4])
        self.assertEqual(mr.parejas_for_book(S, V, pairs((7, 8)), {"w": 1})[0][0]["own"], 3)     # page 7 looks like 8: 1 and 4 cannot stand together
        self.assertEqual([[s["own"] for s in st] for st in mr.parejas_for_book(S, V, pairs((7, 8)), {"w": 1})], [[3, 5, 6]])

    # the shuffle
    def test_mix_is_fixed(self):
        # pinned: the same on every machine and every Python (SHA-256 only)
        self.assertEqual(mr.mix(list(range(10)), "casa"), [6, 4, 8, 0, 5, 9, 2, 1, 7, 3])
        self.assertEqual(mr.mix(list(range(10)), "¿cómo estás?"), [1, 3, 6, 0, 8, 7, 4, 2, 5, 9])
        self.assertEqual(mr.mix([1], "x"), [1])
        self.assertEqual(mr.mix([], "x"), [])
        seq = list(range(7))
        mr.mix(seq, "casa")
        self.assertEqual(seq, list(range(7)))                                                 # the input is not changed
        import unicodedata
        self.assertEqual(mr.mix(list(range(6)), unicodedata.normalize("NFD", "niño")), mr.mix(list(range(6)), "niño"))   # NFC first


class Verdicts(unittest.TestCase):
    """The sheets for the readers, the verdict check and the final data, on the made-up repo and made-up verdicts."""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        make_repo(cls.tmp.name)
        cls.root = Path(cls.tmp.name)
        cls.out = cls.root / "out"
        quiet(["--out", str(cls.out), "--repo", cls.tmp.name, "--hojas-libro"])
        cls.R = mr.build(cls.tmp.name)
        cls.S = mr.sentences_by_book(cls.R)
        cls.n = 0

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def run_cli(self, *args):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = mr.main(["--out", str(self.out), "--repo", self.tmp.name] + list(args))
        return code, buf.getvalue()

    def verdicts(self, parecidas=None, duda=()):
        """A made-up verdict of every book: each sentence fits its own page only (`si`), every other page is `no`; the ids in `duda` have
        their own page in `duda`. parecidas: {book: [[p, q], ..]}."""
        out = {}
        for b, rows in self.S.items():
            n = len(self.R["D"].book[b]["pages"])
            fr = {}
            for s in rows:
                own = s["own"]
                fr[s["id"]] = {"si": [] if s["id"] in duda else [own], "no": [p for p in range(1, n + 1) if p != own],
                               "duda": [own] if s["id"] in duda else []}
            out[b] = {"libro": b, "frases": fr, "parecidas": (parecidas or {}).get(b, [])}
        return out

    def write(self, verdicts, name):
        d = self.root / name
        d.mkdir(exist_ok=True)
        for old in d.glob("*.json"):
            old.unlink()
        for b, v in verdicts.items():
            (d / (b + ".json")).write_text(json.dumps(v, ensure_ascii=False), encoding="utf-8")
        return d

    def final(self, name, **kw):
        d = self.write(self.verdicts(**kw), name)
        f = self.root / (name + "-final") / "repaso-final.json"
        code, text = self.run_cli("--veredictos", str(d), "--final", str(f))
        self.assertEqual(code, 0, text)
        return json.loads(f.read_text(encoding="utf-8")), f

    def word(self, final, w):
        return next(x for x in final["palabras"] if x["word"] == w)

    def item(self, final, w, clip):
        return next(i for i in self.word(final, w)["frases"] if i["clip"] == clip)

    # the sheets
    def test_hojas_libro(self):
        idx = json.loads((self.out / "libro" / "indice.json").read_text(encoding="utf-8"))
        self.assertEqual([b["libro"] for b in idx["libros"]], ["uno", "dos"])                 # course order
        self.assertEqual([(b["paginas"], b["frases"]) for b in idx["libros"]], [(1, 2), (5, 4)])
        self.assertEqual(idx["totales"], {"libros": 2, "paginas": 6, "frases": 6})
        fr = json.loads((self.out / "libro" / "dos" / "frases.json").read_text(encoding="utf-8"))
        self.assertEqual(fr["libro"], "dos")
        self.assertEqual(fr["paginas"], [1, 2, 3, 4, 5])
        self.assertEqual(fr["frases"], [{"id": "dos:1", "text": "Mira la flor roja."}, {"id": "dos:2", "text": "El perro come pan."},
                                        {"id": "dos:3", "text": "El gato duerme aquí."}, {"id": "dos:4", "text": "La casa es grande."}])
        for f in fr["frases"]:
            self.assertEqual(sorted(f), ["id", "text"])                                       # nothing about a page
        self.assertEqual(sorted(fr), ["frases", "libro", "paginas"])
        # a sentence that is a candidate for several words is one; the same sentence is not listed twice
        self.assertEqual(len({f["text"] for f in fr["frases"]}), len(fr["frases"]))
        from PIL import Image
        # 5 pictures of 8x8 at 2x: 3 columns, 2 rows; 12 margin, 16 gap, 44 for the number
        with Image.open(self.out / "libro" / "dos" / "paginas.png") as im:
            self.assertEqual(im.size, (12 * 2 + 3 * 16 + 2 * 16, 12 * 2 + 2 * (44 + 16) + 16))
        with Image.open(self.out / "libro" / "uno" / "paginas.png") as im:
            self.assertEqual(im.size, (12 * 2 + 16, 12 * 2 + 44 + 16))
        # the long uno sentence is on the page of the book of uno: both are there, in story order
        self.assertEqual([f["text"] for f in json.loads((self.out / "libro" / "uno" / "frases.json").read_text(encoding="utf-8"))["frases"]],
                         ["Él come pan en casa.", "Abuela come pan aquí con mamá y papá en casa ahora."])

    def test_sheets_split_after_nine_pages(self):
        chunks = mr.sheet_chunks(11)
        self.assertEqual(chunks, [("paginas-1.png", list(range(1, 10))), ("paginas-2.png", [10, 11])])
        self.assertEqual(mr.sheet_chunks(9), [("paginas.png", list(range(1, 10)))])
        self.assertEqual(mr.sheet_chunks(3), [("paginas.png", [1, 2, 3])])
        self.assertEqual(mr.sheet_chunks(18), [("paginas-1.png", list(range(1, 10))), ("paginas-2.png", list(range(10, 19)))])

    def test_sheets_show_the_pictures_and_digits_only(self):
        from PIL import Image
        with Image.open(self.out / "libro" / "dos" / "paginas.png") as im:
            sheet = im.convert("RGB")
        # page 2 is the second picture of the first row: x = 12 + 16 + 16, y = 12 + 44; its pixel is (80, 0, 0) at 2x
        self.assertEqual(sheet.getpixel((12 + 16 + 16 + 3, 12 + 44 + 3)), (80, 0, 0))
        self.assertEqual(sheet.getpixel((12 + 3, 12 + 44 + 3)), (40, 0, 0))                    # page 1
        self.assertEqual(sheet.getpixel((12 + 3, 12 + 44 + 16 + 16 + 44 + 3)), (160, 0, 0))     # page 4, first of row 2

    # the validator: each kind of fault
    def faults(self, mutate, name="vf"):
        v = self.verdicts()
        mutate(v)
        d = self.write(v, name)
        return mr.valida_veredictos(d, self.out)[0]

    def test_validator_accepts_a_good_set(self):
        d = self.write(self.verdicts(), "vok")
        faults, notes = mr.valida_veredictos(d, self.out)
        self.assertEqual((faults, notes), ([], []))
        code, text = self.run_cli("--valida-veredictos", str(d))
        self.assertEqual(code, 0)
        self.assertIn("ok: 2 files", text)

    def test_validator_missing_sentence(self):
        def m(v):
            del v["dos"]["frases"]["dos:3"]
        f = self.faults(m)
        self.assertEqual(f, ["dos.json: missing sentence dos:3"])

    def test_validator_unknown_id(self):
        def m(v):
            v["dos"]["frases"]["dos:9"] = dict(v["dos"]["frases"]["dos:1"])
        self.assertEqual(self.faults(m), ["dos.json: unknown sentence id dos:9"])

    def test_validator_missing_page(self):
        def m(v):
            v["dos"]["frases"]["dos:2"]["no"].remove(4)
        self.assertEqual(self.faults(m), ["dos.json: dos:2: missing page 4 (in none of si, no, duda)"])

    def test_validator_unknown_page(self):
        def m(v):
            v["dos"]["frases"]["dos:2"]["no"].append(6)
            v["uno"]["frases"]["uno:1"]["duda"].append(0)
        self.assertEqual(self.faults(m), ["dos.json: dos:2: unknown page 6 in `no`", "uno.json: uno:1: unknown page 0 in `duda`"])

    def test_validator_page_in_two_lists(self):
        def m(v):
            v["dos"]["frases"]["dos:1"]["no"].append(1)                       # 1 is si and no
            v["dos"]["frases"]["dos:4"]["duda"].append(2)                     # 2 is no and duda
            v["dos"]["frases"]["dos:4"]["no"].append(2)                       # and 2 is twice in no
        f = self.faults(m)
        self.assertIn("dos.json: dos:1: page 1 is in two lists (si, no)", f)
        self.assertIn("dos.json: dos:4: page 2 is in two lists (no, duda)", f)
        self.assertIn("dos.json: dos:4: page 2 is written twice in `no`", f)
        self.assertEqual(len(f), 3)

    def test_validator_other_faults(self):
        def m(v):
            v["dos"]["libro"] = "tres"
            v["dos"]["frases"]["dos:1"]["si"] = "1"
            v["dos"]["frases"]["dos:2"]["no"].append("x")
            del v["uno"]["frases"]["uno:1"]["duda"]
            v["uno"]["parecidas"] = [[1, 1], [1], [1, 9]]
        f = self.faults(m)
        self.assertIn("dos.json: `libro` is \"tres\", not \"dos\"", f)
        self.assertIn("dos.json: dos:1: list `si` is missing or is not a list", f)
        self.assertIn("dos.json: dos:2: `no` holds \"x\", which is not a page number", f)
        self.assertIn("uno.json: uno:1: list `duda` is missing or is not a list", f)
        self.assertIn("uno.json: parecidas[0] is [1, 1], not two different page numbers", f)
        self.assertIn("uno.json: parecidas[1] is [1], not two different page numbers", f)
        self.assertIn("uno.json: parecidas[2]: unknown page 9", f)

    def test_validator_files(self):
        v = self.verdicts()
        d = self.write(v, "vfiles")
        (d / "tres.json").write_text("{}", encoding="utf-8")
        (d / "uno.json").write_text("{ not json", encoding="utf-8")
        f = mr.valida_veredictos(d, self.out)[0]
        self.assertTrue(any(x.startswith("tres.json: not the file of a book") for x in f), f)
        self.assertTrue(any(x.startswith("uno.json: cannot be read as JSON") for x in f), f)
        # a book with no file is only a note, until the merge asks for every book
        (d / "tres.json").unlink()
        (d / "uno.json").unlink()
        faults, notes = mr.valida_veredictos(d, self.out)
        self.assertEqual(faults, [])
        self.assertEqual(len(notes), 1)
        self.assertIn("uno", notes[0])
        self.assertEqual(mr.valida_veredictos(d, self.out, require_all=True)[0], ["uno.json: no verdict file for this book"])
        code, text = self.run_cli("--valida-veredictos", str(self.write({"dos": v["dos"]}, "vone")))
        self.assertEqual(code, 0)

    def test_validator_exit_code_is_one_with_a_fault(self):
        v = self.verdicts()
        del v["dos"]["frases"]["dos:3"]
        d = self.write(v, "vbad")
        code, text = self.run_cli("--valida-veredictos", str(d))
        self.assertEqual(code, 1)
        self.assertIn("dos.json: missing sentence dos:3", text)

    def test_the_merge_refuses_a_bad_set(self):
        v = self.verdicts()
        del v["dos"]["frases"]["dos:3"]
        d = self.write(v, "vmerge")
        f = self.root / "refused" / "final.json"
        code, text = self.run_cli("--veredictos", str(d), "--final", str(f))
        self.assertEqual(code, 1)
        self.assertFalse(f.exists())
        self.write({"uno": self.verdicts()["uno"]}, "vmerge")                      # a book with no file
        code, text = self.run_cli("--veredictos", str(self.root / "vmerge"), "--final", str(f))
        self.assertEqual(code, 1)
        self.assertIn("dos.json: no verdict file for this book", text)
        self.assertFalse(f.exists())

    # the final data
    def test_final_cual_and_puntua(self):
        fin, _ = self.final("a")
        flor = self.item(fin, "flor", "p1")
        self.assertEqual(flor["pagina"], {"book": "dos", "page": 1, "img": "img/dos-1.png"})
        self.assertEqual(flor["cuento"], "dos")
        self.assertEqual(flor["tokens"], ["mira", "la", "flor", "roja"])
        self.assertEqual(flor["cual"], [5, 4, 3])                                  # farthest first
        self.assertFalse(flor["propia_dudosa"])
        self.assertEqual(self.item(fin, "perro", "p2")["cual"], [5, 4, 1])
        self.assertEqual(self.item(fin, "gato", "p4")["cual"], [1, 2, 3])
        self.assertEqual(self.word(fin, "flor")["puntua"], "cual")
        self.assertEqual(self.word(fin, "casa")["puntua"], "cual")
        # a word whose pictured sentence is in a book of one page: nothing is wrong there; heard-and-chosen only
        self.assertEqual(self.item(fin, "él", "a_el")["cual"], [])
        self.assertEqual(self.word(fin, "él")["puntua"], "que_oyes")
        self.assertEqual(self.word(fin, "nada")["puntua"], "que_oyes")             # a sentence with no page, 4 words
        # arma and que_oyes are the flags of stage 1
        self.assertEqual((self.item(fin, "perro", "p2")["arma"], self.item(fin, "perro", "p2")["que_oyes"]), (True, True))
        self.assertEqual((self.item(fin, "flor", "p1")["arma"], self.item(fin, "flor", "p1")["que_oyes"]), (False, True))   # "mira" ... 4 tokens, but "roja" is not taught
        for w in fin["palabras"]:
            self.assertEqual(list(w), ["word", "puntua", "par", "dilo", "frases"])
            for i in w["frases"]:
                self.assertEqual(list(i), ["clip", "cuento", "text", "tokens", "pagina", "cual", "propia_dudosa", "arma", "que_oyes"])
                self.assertLessEqual(len(i["cual"]), 3)

    def test_final_parecidas_and_own_page_not_si(self):
        fin, _ = self.final("b", parecidas={"dos": [[1, 2]]}, duda=["dos:3"])
        self.assertEqual(self.item(fin, "perro", "p2")["cual"], [5, 4, 3])        # page 1 looks like page 2: out
        self.assertEqual(self.item(fin, "flor", "p1")["cual"], [5, 4, 3])         # page 2: out
        gato = self.item(fin, "gato", "p4")                                       # its own page is `duda`: no wrong picture, and it says so
        self.assertEqual(gato["cual"], [])
        self.assertTrue(gato["propia_dudosa"])
        self.assertEqual(self.word(fin, "gato")["puntua"], "que_oyes")            # the other gato sentence has no page; 5 words
        # its own page is not si, but "El gato duerme aquí." has 4 words: still an item (que_oyes)
        self.assertTrue(gato["que_oyes"])

    def test_final_leaves_out_a_sentence_with_no_use(self):
        fin, _ = self.final("c")
        for w in ("abuela", "pan", "casa"):
            self.assertIn("y_long", [i["clip"] for i in self.word(fin, w)["frases"]], w)    # own page is si: kept (11 words, no flag)
        y = self.item(fin, "abuela", "y_long")
        self.assertEqual((y["arma"], y["que_oyes"], y["cual"]), (False, False, []))
        out = fin["meta"]["frases_fuera"]
        fin2, _ = self.final("c2", duda=["uno:2"])                                # its own page is not si, and it has no page-free use
        for w in ("abuela", "pan", "casa"):
            self.assertNotIn("y_long", [i["clip"] for i in self.word(fin2, w)["frases"]], w)
        self.assertEqual(fin2["meta"]["frases_fuera"], out + 3)
        # a sentence that is not usable on a page but is page-free (que_oyes) stays
        fin3, _ = self.final("c3", duda=["dos:1", "dos:2", "dos:3", "dos:4"])
        self.assertIn("p1", [i["clip"] for i in self.word(fin3, "flor")["frases"]])
        self.assertTrue(self.item(fin3, "flor", "p1")["propia_dudosa"])

    def test_final_the_order_of_a_words_sentences(self):
        fin, _ = self.final("d")
        w = self.word(fin, "pan")
        clips = [i["clip"] for i in w["frases"]]
        self.assertEqual(clips, [c["clip"] for c in mr.mix([c for c in self.R["cands"] if c["word"] == "pan"], "pan") if c["clip"] in clips])
        self.assertGreater(len(clips), 3)

    def test_final_dilo_and_par(self):
        fin, _ = self.final("e")
        mira = self.word(fin, "mira")
        self.assertEqual(len(mira["dilo"]), 1)
        d = mira["dilo"][0]
        self.assertEqual((d["clip"], d["cuento"], d["formas"], d["pagina"]), ("l_mira", "uno", ["mira", "mirá"], None))
        self.assertEqual(d["antes"], {"clip": "k_corr", "text": "No, Coquí. Mira el pan aquí."})         # the clip just before it in its story
        self.assertEqual(self.word(fin, "pan")["dilo"], [])                                                # the mark targets "mira", not "pan"
        casa = self.word(fin, "casa")
        self.assertEqual(casa["par"], {"clip": "esta_casa", "text": "Esta es la casa.", "si": {"cam": [1, 2, 3, 4]}, "no": {"cam": [5, 6, 7, 8]},
                                       "scene": "frente", "file": "cual-x"})
        self.assertIsNone(self.word(fin, "flor")["par"])

    def test_final_falsas_and_ciertas(self):
        fin, _ = self.final("f")
        self.assertEqual([x["clip"] for x in fin["paginas"]["dos/3"]["falsas"]], ["p1", "p5", "p2", "p4"])   # farthest own page first, then story order
        self.assertEqual(fin["paginas"]["dos/3"]["ciertas"], [])
        self.assertEqual(fin["paginas"]["dos/1"]["ciertas"], [{"clip": "p1", "text": "Mira la flor roja."}])
        self.assertEqual(fin["paginas"]["dos/1"]["img"], "img/dos-1.png")
        self.assertEqual(sorted(k for k in fin["paginas"] if k.startswith("dos/")), ["dos/%d" % n for n in range(1, 6)])
        fin, _ = self.final("g", parecidas={"dos": [[1, 2]]})
        self.assertEqual([x["clip"] for x in fin["paginas"]["dos/2"]["falsas"]], ["p5", "p4"])            # the sentence of page 1 looks like page 2: out

    def test_final_parejas(self):
        fin, _ = self.final("h")
        sets = fin["parejas"]["dos"]
        self.assertEqual(len(sets), 1)
        self.assertEqual((sets[0]["size"], sets[0]["words_differ"]), (4, False))                          # "el" is a word of two of them
        self.assertEqual([(i["clip"], i["pagina"]["page"]) for i in sets[0]["items"]], [("p1", 1), ("p2", 2), ("p4", 4), ("p5", 5)])
        self.assertEqual(sorted(sets[0]["items"][0]), ["clip", "pagina", "text"])
        self.assertEqual(fin["parejas"]["uno"], [])                                                       # two sentences on one page of one picture
        fin, _ = self.final("i", parecidas={"dos": [[1, 2]]})
        sets = fin["parejas"]["dos"]
        self.assertEqual([(s["size"], s["words_differ"], [i["clip"] for i in s["items"]]) for s in sets], [(3, True, ["p1", "p4", "p5"])])

    # determinism
    def test_same_bytes_twice(self):
        for i in range(2):
            d = self.root / ("det%d" % i)
            quiet(["--out", str(d), "--repo", self.tmp.name, "--hojas-libro"])
        files = sorted(p.relative_to(self.root / "det0") for p in (self.root / "det0").rglob("*") if p.is_file())
        self.assertTrue(any(str(f).endswith(".png") for f in files))
        for f in files:
            self.assertEqual((self.root / "det0" / f).read_bytes(), (self.root / "det1" / f).read_bytes(), str(f))
        # the sheets of a book are the sheets the run above wrote
        self.assertEqual((self.root / "det0" / "libro" / "dos" / "frases.json").read_bytes(), (self.out / "libro" / "dos" / "frases.json").read_bytes())
        sums = []
        for i in range(2):
            d = self.write(self.verdicts(parecidas={"dos": [[1, 2]]}, duda=["dos:3"]), "vdet%d" % i)
            f = self.root / ("fdet%d" % i) / "final.json"
            code, text = self.run_cli("--veredictos", str(d), "--final", str(f))
            self.assertEqual(code, 0, text)
            sums.append([hashlib.sha256(p.read_bytes()).hexdigest() for p in (f, f.with_name("resumen-final.md"))])
        self.assertEqual(sums[0], sums[1])

    def test_the_merge_notices_stale_sheets(self):
        d = self.write(self.verdicts(), "vstale")
        # the repo changed after the sheets were made: a sentence of the book of dos is not the same
        out2 = self.root / "out-stale"
        quiet(["--out", str(out2), "--repo", self.tmp.name, "--hojas-libro"])
        p = out2 / "libro" / "dos" / "frases.json"
        j = json.loads(p.read_text(encoding="utf-8"))
        j["frases"][0]["text"] = "Otra frase."
        p.write_text(json.dumps(j, ensure_ascii=False), encoding="utf-8")
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = mr.main(["--out", str(out2), "--repo", self.tmp.name, "--veredictos", str(d), "--final", str(self.root / "stale" / "f.json")])
        self.assertEqual(code, 1)
        self.assertIn("frases.json is not what the tool makes", buf.getvalue())

    def test_resumen_final(self):
        fin, f = self.final("r", parecidas={"dos": [[1, 2]]}, duda=["dos:3"])
        text = f.with_name("resumen-final.md").read_text(encoding="utf-8")
        for needle in ("## Per word", "## Distribution of words by number of items with a non-empty `cual`", "finished stories 1..3", "finished stories 1..32",
                       "## Words that are not scored by `cual`", "`puntua` = `que_oyes`", "`puntua` = `nada`", "Pages with at least 2 `falsas`",
                       "Books with at least one set", "`propia_dudosa`", "SHA-256"):
            self.assertIn(needle, text)
        # "El gato duerme aquí." is a candidate for el and for gato: two items, one sentence
        self.assertIn("| items with `propia_dudosa` (a picture of its own that the verdict does not put in si) | 2 |", text)
        self.assertIn("|   distinct sentences (book, text) with `propia_dudosa` | 1 |", text)


class RealData(unittest.TestCase):
    """The tool on this repo's real stories with made-up verdicts (nothing about the real pictures is judged): sizes and invariants."""

    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[3]
        if not (cls.root / "historia" / "datos" / "curso.json").exists():
            raise unittest.SkipTest("no historia/ in this checkout")
        cls.R = mr.build(cls.root)
        cls.S = mr.sentences_by_book(cls.R)

    def test_every_candidate_that_has_a_page_is_judged_in_its_book(self):
        D = self.R["D"]
        by = {b: {s["text"]: s for s in rows} for b, rows in self.S.items()}
        self.assertEqual(list(self.S), D.eligible)
        n = 0
        for c in self.R["cands"]:
            if c["pagina"]:
                n += 1
                self.assertEqual(by[c["pagina"]["book"]][c["text"]]["own"], c["pagina"]["page"])
        self.assertGreater(n, 1000)
        for b, rows in self.S.items():
            self.assertEqual([r["k"] for r in rows], list(range(1, len(rows) + 1)))
            self.assertEqual(len({r["text"] for r in rows}), len(rows))
            for r in rows:
                self.assertTrue(all(1 <= p <= len(D.book[b]["pages"]) for p in r["pages"]))

    def test_made_up_verdicts(self):
        D, S = self.R["D"], self.S
        V = {}
        for b, rows in S.items():
            n = len(D.book[b]["pages"])
            fr = {}
            for s in rows:
                own = s["own"]
                if s["k"] % 7 == 0:
                    v = verd(duda=[own], no=[p for p in range(1, n + 1) if p != own])
                else:
                    near = [p for p in (own - 1, own + 1) if 1 <= p <= n and s["k"] % 3 == 0]
                    v = verd(si=[own], duda=near, no=[p for p in range(1, n + 1) if p != own and p not in near])
                fr[s["id"]] = v
            par = {frozenset((1, 2))} if n >= 2 else set()
            V[b] = {"frases": fr, "parecidas": par}
        fin = mr.build_final(self.R, V)
        self.assertEqual(len(fin["palabras"]), len(self.R["words"]))
        self.assertEqual(list(fin["paginas"]), ["%s/%d" % (b, n) for b in D.eligible for n in range(1, len(D.book[b]["pages"]) + 1)])
        self.assertEqual(list(fin["parejas"]), D.eligible)
        for w in fin["palabras"]:
            self.assertEqual(w["puntua"], mr.puntua(w["frases"], w["par"]))
            for i in w["frases"]:
                self.assertLessEqual(len(i["cual"]), 3)
                if i["pagina"]:
                    s = next(x for x in S[i["pagina"]["book"]] if x["text"] == i["text"])
                    v = V[i["pagina"]["book"]]["frases"][s["id"]]
                    self.assertEqual(i["propia_dudosa"], s["own"] not in v["si"])
                    self.assertTrue(set(i["cual"]) <= v["no"])
                    self.assertTrue(all(abs(a - s["own"]) >= abs(b - s["own"]) for a, b in zip(i["cual"], i["cual"][1:])))
                    self.assertFalse(any(frozenset((p, s["own"])) in V[i["pagina"]["book"]]["parecidas"] for p in i["cual"]))
                else:
                    self.assertEqual((i["cual"], i["propia_dudosa"]), ([], False))
                if i["propia_dudosa"] or not i["pagina"]:
                    self.assertTrue(i["arma"] or i["que_oyes"])
        for key, pg in fin["paginas"].items():
            self.assertLessEqual(len(pg["falsas"]), 6)
        for b, sets in fin["parejas"].items():
            self.assertLessEqual(len(sets), 3)
            for st in sets:
                pages = [i["pagina"]["page"] for i in st["items"]]
                self.assertEqual(len(set(pages)), len(pages))
                self.assertIn(len(pages), (3, 4))
                self.assertFalse(any(frozenset(pq) in V[b]["parecidas"] for pq in itertools.combinations(pages, 2)))
                by_clip = {s["clip"]: s for s in S[b]}
                for i in st["items"]:
                    s = by_clip[i["clip"]]
                    self.assertIn(s["own"], V[b]["frases"][s["id"]]["si"])
                    self.assertTrue(all(p in V[b]["frases"][s["id"]]["no"] for p in pages if p != s["own"]))
        # some of everything, with these verdicts
        self.assertTrue(any(v["falsas"] for v in fin["paginas"].values()))
        self.assertTrue(any(fin["parejas"].values()))
        self.assertTrue(any(i["cual"] for w in fin["palabras"] for i in w["frases"]))


if __name__ == "__main__":
    unittest.main(verbosity=2)
