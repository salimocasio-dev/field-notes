"""Tests for coqui/tool/make_repaso.py: a made-up story and book in a temp folder.

    python3 coqui/tool/test/test_make_repaso.py

Checks rules 2a (accents kept; a word inside a longer tracked phrase), 2b (a word only in the speaker tag), 2c (a question line),
2d (a line heard only after a wrong touch), 2e (a correction), 2f (three words after the tag), rule 3 (fair wrong pictures:
distance, plural, farthest first) and that two runs give the same bytes. The readers' step (--hojas-libro, --valida-veredictos,
--veredictos --final) is tested with made-up verdicts: the validator (each kind of fault), `cual` (parecidas, own page not in si,
farthest first, at most 3), `puntua`, `falsas`, the fixed shuffle, and that two runs give the same bytes. The pair step (--hojas-par,
--valida-veredictos-par, --veredictos-par) is tested with made-up pair verdicts: the slugs, the sheet and its key (the letter of `si`
both ways), the sentences to judge, the STOP for a pair with no picture files, the validator (each fault), `par` true and false,
`par_frases` (order and no text twice), `puntua`, `no_juntas` (rules a to e and symmetry), `tokens_extra_prohibidos`, the summary and
determinism. The app's file (--app, --check): what it holds, its bytes, the check of a stale or missing file, the clips of a word
alone. `dart test tool/test` does not see this file (it looks for *_test.dart).
"""
import contextlib
import hashlib
import io
import json
import sys
import tempfile
import unittest
from collections import Counter
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

# the picture pairs of the made-up course: word -> (clip, the pair's own sentence). tu's own sentence is also the sentence of an item (c_tu).
PAIR_SAYS = {"tú": ("eres_tu", "Eres tú."), "tu": ("tu_pan", "Tú tienes tu pan aquí."), "el": ("el_es", "El es mío."), "mira": ("mira_aqui", "Mira aquí."),
             "hola": ("di_hola", "Di hola."), "casa": ("esta_casa", "Esta es la casa."), "perro": ("el_perro", "El perro es grande.")}
PAIR_SI, PAIR_NO = (255, 0, 0), (0, 0, 255)

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
    dump("historia/cuentos/cual-x.json", {"id": "cual-x", "scene": "frente", "clips": {k: {"who": "narr", "text": t} for k, t in PAIR_SAYS.values()},
                                          "items": [{"w": w, "say": k, "si": {"cam": [1, 2, 3, 4]}, "no": {"cam": [5, 6, 7, 8]}} for w, (k, _) in PAIR_SAYS.items()]})
    # the captured pictures of the pairs: coqui/ref/escenas/frente/pairs.json and pairs/<png>. `mira` has no picture files (a STOP).
    (root / "coqui" / "ref" / "escenas" / "frente" / "pairs").mkdir(parents=True)
    dump("coqui/ref/escenas/frente/pairs.json", {"scene": "frente", "pairs": [
        {"file": "cual-x", "w": w, "say": k, "sayText": t, "si": {"png": "%s.si.png" % w}, "no": {"png": "%s.no.png" % w}} for w, (k, t) in PAIR_SAYS.items()]})
    from PIL import Image
    for w in PAIR_SAYS:
        if w != "mira":
            Image.new("RGB", (40, 12), PAIR_SI).save(root / "coqui" / "ref" / "escenas" / "frente" / "pairs" / ("%s.si.png" % w))
            Image.new("RGB", (40, 12), PAIR_NO).save(root / "coqui" / "ref" / "escenas" / "frente" / "pairs" / ("%s.no.png" % w))
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
        pair = {"clip": "x"}
        self.assertEqual(mr.puntua([it([], True)], pair), "cual")                          # a picture pair is what makes it cual
        self.assertEqual(mr.puntua([], pair), "cual")
        self.assertEqual(mr.puntua([it([], False)], pair), "cual")
        self.assertEqual(mr.puntua([it([2], True)], None), "que_oyes")                      # a wrong book picture no longer does
        self.assertEqual(mr.puntua([it([], True), it([4, 5], False)], None), "que_oyes")
        self.assertEqual(mr.puntua([it([4, 5], False), it([], True)], None), "que_oyes")
        self.assertEqual(mr.puntua([it([2], False)], None), "nada")
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


class VerdictsBase(unittest.TestCase):
    """The made-up repo with the sheets for the readers written, and the helpers to make made-up verdicts and run the tool. No test."""

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


class Verdicts(VerdictsBase):
    """The sheets for the readers, the verdict check and the final data, on the made-up repo and made-up verdicts."""

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
        # puntua: cual when the word has a picture pair (a wrong book picture no longer counts); else que_oyes with an item that has it; else nada
        self.assertEqual(self.word(fin, "flor")["puntua"], "que_oyes")             # an item with a wrong picture, but no pair
        self.assertEqual(self.word(fin, "casa")["puntua"], "cual")
        self.assertEqual(self.word(fin, "hola")["puntua"], "cual")
        self.assertEqual(self.word(fin, "mira")["puntua"], "cual")                 # a pair, though it has no sheet (a STOP)
        self.assertEqual(self.word(fin, "hay")["puntua"], "nada")                  # no pair, and no item at all
        # a word whose pictured sentence is in a book of one page: nothing is wrong there; heard-and-chosen only
        self.assertEqual(self.item(fin, "él", "a_el")["cual"], [])
        self.assertEqual(self.word(fin, "él")["puntua"], "que_oyes")
        self.assertEqual(self.word(fin, "nada")["puntua"], "que_oyes")             # a sentence with no page, 4 words
        # arma and que_oyes are the flags of stage 1
        self.assertEqual((self.item(fin, "perro", "p2")["arma"], self.item(fin, "perro", "p2")["que_oyes"]), (True, True))
        self.assertEqual((self.item(fin, "flor", "p1")["arma"], self.item(fin, "flor", "p1")["que_oyes"]), (False, True))   # "mira" ... 4 tokens, but "roja" is not taught
        for w in fin["palabras"]:
            self.assertEqual(list(w), ["word", "puntua", "par", "par_frases", "no_juntas", "dilo", "frases"])
            for i in w["frases"]:
                self.assertEqual(list(i), ["clip", "cuento", "text", "tokens", "pagina", "cual", "propia_dudosa", "arma", "que_oyes", "par", "tokens_extra_prohibidos"])
                self.assertLessEqual(len(i["cual"]), 3)
        self.assertEqual(list(fin), ["meta", "palabras", "paginas"])               # the book-page Parejas sets are gone

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
                       "`propia_dudosa`", "SHA-256"):
            self.assertIn(needle, text)
        # "El gato duerme aquí." is a candidate for el and for gato: two items, one sentence
        self.assertIn("| items with `propia_dudosa` (a picture of its own that the verdict does not put in si) | 2 |", text)
        self.assertIn("|   distinct sentences (book, text) with `propia_dudosa` | 1 |", text)


# ---------------------------------------------------------------------------------------------------------------- the pair step

def pairs_of(lst, rule):
    """The pairs of words (as frozensets) that no_juntas_pairs puts under a rule."""
    return {frozenset(p) for p in mr.no_juntas_pairs(lst)[rule]}


def fs(*ps):
    return {frozenset(p) for p in ps}


class NoJuntas(unittest.TestCase):
    """The words that must not meet, on plain lists of words."""

    def test_a_accent_twins(self):
        words = ["bebé", "bebe", "tú", "tu", "el", "él", "niño", "casa"]
        self.assertEqual(mr.no_juntas_pairs(words)["a"], [("bebé", "bebe"), ("tú", "tu"), ("el", "él")])      # course order, a before b
        self.assertEqual(pairs_of(["está", "esta", "¿cuál?", "cual", "papá", "papa"], "a"), fs(("está", "esta"), ("¿cuál?", "cual"), ("papá", "papa")))

    def test_b_a_whole_word_part_of_a_phrase(self):
        words = ["no", "no hay", "hay", "nada", "de nada", "otra", "otra vez", "está", "¿dónde está?", "casa", "nota", "tu", "¿y tú?", "hace", "hace calor", "mesa"]
        self.assertEqual(pairs_of(words, "b"), fs(("no", "no hay"), ("hay", "no hay"), ("nada", "de nada"), ("otra", "otra vez"), ("está", "¿dónde está?"),
                                                  ("tu", "¿y tú?"), ("hace", "hace calor")))          # "nota" is not part of anything; "tu" is "tú" with accents folded
        self.assertEqual(pairs_of(["esta", "¿dónde está?"], "b"), fs(("esta", "¿dónde está?")))                # accents folded here too
        self.assertEqual(pairs_of(["no hay", "no hay"], "b"), set())                                        # equal is not a part
        self.assertEqual(pairs_of(["de nada", "nadar"], "b"), set())                                        # part of a word is not a whole word

    def test_c_the_same_first_three_letters_or_four_for_a_phrase(self):
        words = ["quiero", "quiere", "quieres", "abre", "abierta", "come", "comida", "casa", "cama", "tú", "tus", "sol", "sola", "tengo hambre", "tengo sed",
                 "hasta mañana", "hasta", "hace", "hace calor", "hay", "hasta luego"]
        got = pairs_of(words, "c")
        self.assertEqual(got, fs(("quiero", "quiere"), ("quiero", "quieres"), ("quiere", "quieres"), ("come", "comida"), ("sol", "sola"),
                                 ("tengo hambre", "tengo sed"), ("hasta mañana", "hasta"), ("hace", "hace calor"), ("hasta mañana", "hasta luego"),
                                 ("hasta luego", "hasta")))
        # two single words: three letters. "abre" / "abierta" share two, "casa" / "cama" two
        self.assertNotIn(frozenset(("abre", "abierta")), got)
        self.assertNotIn(frozenset(("casa", "cama")), got)
        self.assertNotIn(frozenset(("tú", "tus")), got)                    # "tu" has fewer than three letters
        # a phrase: four letters. "hace calor" / "hay" share two only; "hasta mañana" / "hay": "ha" only
        self.assertNotIn(frozenset(("hace calor", "hay")), got)
        self.assertEqual(pairs_of(["hasta", "has"], "c"), fs(("hasta", "has")))                         # single words: "has" is three letters
        self.assertEqual(pairs_of(["hast ya", "has"], "c"), set())                                       # one is a phrase: four letters, "has" has three
        self.assertEqual(pairs_of(["sale bien", "salt"], "c"), set())                                    # a phrase: four letters, "sale" / "salt" differ
        self.assertEqual(pairs_of(["sale", "salt"], "c"), fs(("sale", "salt")))                          # two words: "sal" is the same
        self.assertEqual(pairs_of(["está", "esta", "ESTÁ"], "c"), fs(("está", "esta"), ("está", "ESTÁ"), ("esta", "ESTÁ")))    # accents and case folded
        self.assertEqual(pairs_of(["¿cuál?", "cuando"], "c"), fs(("¿cuál?", "cuando")))                  # signs are no letters; ¿cuál? is one word
        self.assertEqual((mr.NO_JUNTAS_PREFIX, mr.NO_JUNTAS_PREFIX_PHRASE), (3, 4))

    def test_d_one_letter_apart(self):
        words = ["tira", "mira", "este", "esta", "abuelo", "abuela", "gato", "pato", "no", "yo", "sol", "sal", "casa", "cosa", "tu", "tú", "niño", "niña", "casas", "papá", "para"]
        self.assertEqual(pairs_of(words, "d"), fs(("tira", "mira"), ("este", "esta"), ("abuelo", "abuela"), ("gato", "pato"), ("no", "yo"), ("sol", "sal"), ("casa", "cosa"),
                                                  ("niño", "niña"), ("papá", "para")))
        self.assertEqual(pairs_of(["mira", "pato", "casa", "gato"], "d"), fs(("pato", "gato")))              # two or three letters apart: no
        self.assertEqual(pairs_of(["tu", "tú", "casa", "casas"], "d"), set())                                # no letter apart, or not of equal length: no

    def test_e_plus_s_or_es(self):
        words = ["flor", "flores", "perro", "perros", "casa", "casas", "tu", "tus", "mes", "meses", "sol", "sola", "flor", "perras"]
        self.assertEqual(pairs_of(words[:-2], "e"), fs(("flor", "flores"), ("perro", "perros"), ("casa", "casas"), ("tu", "tus"), ("mes", "meses")))   # "sola" is no plural
        self.assertEqual(pairs_of(["flores", "flor"], "e"), fs(("flor", "flores")))                          # in either order
        self.assertEqual(pairs_of(["flor", "perros"], "e"), set())

    def test_symmetric_sorted_and_the_union_of_the_rules(self):
        words = ["quiero", "quiere", "quieres", "flor", "flores", "no", "no hay", "hay", "tira", "mira", "tú", "tu", "¿y tú?", "casa", "mesa"]
        nj = mr.no_juntas(words)
        self.assertEqual(list(nj), words)
        for w, lst in nj.items():
            self.assertEqual(lst, sorted(lst))
            self.assertNotIn(w, lst)
            for o in lst:
                self.assertIn(w, nj[o])
        self.assertEqual(nj["quiero"], ["quiere", "quieres"])
        self.assertEqual(nj["flor"], ["flores"])
        self.assertEqual(nj["flores"], ["flor"])
        self.assertEqual(nj["no"], ["no hay"])
        self.assertEqual(nj["no hay"], ["hay", "no"])
        self.assertEqual(nj["tu"], ["tú", "¿y tú?"])
        self.assertEqual(nj["tú"], ["tu", "¿y tú?"])
        self.assertEqual(nj["¿y tú?"], ["tu", "tú"])
        self.assertEqual(nj["tira"], ["mira"])
        self.assertEqual((nj["casa"], nj["mesa"]), ([], []))
        # the union of the pairs of every rule, each pair once on each side
        every = set().union(*[pairs_of(words, r) for r in "abcde"])
        self.assertEqual({frozenset((w, o)) for w, l in nj.items() for o in l}, every)

    def test_tokens_extra_prohibidos_rule(self):
        names = ["flor", "casa", "bebé", "bebe", "él", "el", "no hay", "no", "hay", "pan", "tu", "tú"]
        fts = [mr.ftoks(w) for w in names]
        tin = lambda text: mr.tracked_in(text, names, fts)
        self.assertEqual(tin("Las flores son rojas."), ["flor"])                       # a plural: flor + es
        self.assertEqual(tin("Dos casas."), ["casa"])                                   # casa + s
        self.assertEqual(tin("El bebé bebe agua ahora."), ["bebe", "bebé", "el", "él"])  # accents folded: él and el, bebé and bebe are all in it
        self.assertEqual(tin("No hay pan aquí ahora."), ["hay", "no", "no hay", "pan"])   # a word inside a tracked phrase is in the sentence too
        self.assertEqual(tin("No tengo hay."), ["hay", "no"])                           # the phrase needs its words one after the other
        self.assertEqual(tin("Tú tienes tu pan."), ["pan", "tu", "tú"])
        self.assertEqual(tin("¡Flor!"), ["flor"])                                       # signs and case
        self.assertEqual(tin("Una floreria."), [])                                      # a part of a word is not the word
        self.assertEqual(tin(""), [])


class PairBase(VerdictsBase):
    """The helpers of the pair step: the sheets, the pair verdicts, the merge. No test."""

    def sheets(self, **kw):
        """The book verdicts written, then --hojas-par run into self.out. -> (the book verdicts dir, the tool's output)."""
        d = self.write(self.verdicts(**kw), "pbook")
        code, text = self.run_cli("--veredictos", str(d), "--hojas-par")
        self.assertEqual(code, 0, text)
        return d, text

    def index(self):
        return json.loads((self.out / "par" / "indice.json").read_text(encoding="utf-8"))

    def claves(self):
        return json.loads((self.out / "par" / "claves.json").read_text(encoding="utf-8"))

    def doc(self, slug):
        return json.loads((self.out / "par" / slug / "frases.json").read_text(encoding="utf-8"))

    def pair_files(self, name, change=None, value=None):
        """A pair verdict file for every sheet: every sentence gets `value(slug, k)` (default: the letter of `si`). change(files) may spoil them.
        -> the directory."""
        files = {}
        for slug, word in self.index().items():
            files[slug] = {"palabra": word, "frases": {f["id"]: (value(slug, k) if value else self.claves()[slug]) for k, f in enumerate(self.doc(slug)["frases"], 1)}}
        if change:
            change(files)
        d = self.root / name
        d.mkdir(exist_ok=True)
        for old in d.glob("*.json"):
            old.unlink()
        for slug, v in files.items():
            (d / (slug + ".json")).write_text(json.dumps(v, ensure_ascii=False), encoding="utf-8")
        return d

    def merge(self, name, bdir, pdir, expect=0):
        f = self.root / (name + "-final") / "repaso-final.json"
        args = ["--veredictos", str(bdir)] + (["--veredictos-par", str(pdir)] if pdir else []) + ["--final", str(f)]
        code, text = self.run_cli(*args)
        self.assertEqual(code, expect, text)
        return (json.loads(f.read_text(encoding="utf-8")) if expect == 0 else None), f, text


class Pares(PairBase):
    """The pair step on the made-up repo. Words with a pair and a sheet, course order: el (B), tú (slug tu, B), tu (tu-2, B), hola (A), casa (B), perro (B);
    mira has a pair but no picture files (a STOP)."""

    SLUGS = [("el", "el"), ("tu", "tú"), ("tu-2", "tu"), ("hola", "hola"), ("casa", "casa"), ("perro", "perro")]

    # slugs
    def test_slugs(self):
        self.assertEqual(mr.slugify("¿cómo estás?"), "como-estas")
        self.assertEqual(mr.slugify("Niño"), "nino")
        self.assertEqual(mr.slugify("se sienta"), "se-sienta")
        self.assertEqual(mr.slugify("¿y tú?"), "y-tu")
        self.assertEqual(mr.slugify("¿?"), "palabra")
        self.assertEqual(mr.slugify(unicodedata_nfd("niño")), "nino")
        got = mr.pair_slugs(["tú", "tu", "bebé", "bebe", "¿dónde está?", "tu-2", "está", "esta"])
        self.assertEqual(list(got.values()), ["tu", "tu-2", "bebe", "bebe-2", "donde-esta", "tu-2-2", "esta", "esta-2"])     # unique; the first of a kind is plain
        self.assertEqual(len(set(got.values())), len(got))
        self.assertEqual(mr.pair_slugs(["tú", "tu", "bebé", "bebe", "¿dónde está?", "tu-2", "está", "esta"]), got)         # the same every time
        for slug in got.values():
            self.assertRegex(slug, r"^[a-z0-9]+(-[a-z0-9]+)*$")

    # the sheets
    def test_the_sheets_written(self):
        _, text = self.sheets()
        par = self.out / "par"
        self.assertEqual(list(self.index().items()), self.SLUGS)                                 # course order: el, tú, tu, (mira has none), hola, casa, perro
        self.assertEqual(sorted(p.name for p in par.iterdir() if p.is_dir()), sorted(s for s, _ in self.SLUGS))
        for slug, _ in self.SLUGS:
            self.assertEqual(sorted(p.name for p in (par / slug).iterdir()), ["frases.json", "par.png"])
        self.assertEqual(sorted(p.name for p in par.iterdir() if p.is_file()), ["claves.json", "grupos.json", "indice.json"])
        n = sum(len(self.doc(s)["frases"]) for s, _ in self.SLUGS)
        self.assertIn("words 6, sentences to judge %d (the pairs' own sentences 6, the others %d)" % (n, n - 6), text)
        # the largest and the smallest word
        counts = {w: len(self.doc(s)["frases"]) for s, w in self.SLUGS}
        self.assertIn("largest word: %s (%d sentences)" % (max(counts, key=lambda w: (counts[w], -list(counts).index(w))), max(counts.values())), text)
        self.assertIn("smallest: %d sentence" % min(counts.values()), text)

    def test_the_sentences_to_judge(self):
        d, _ = self.sheets()
        fin, _, _ = self.merge("pf", d, None)
        for slug, word in self.SLUGS:
            w = next(x for x in fin["palabras"] if x["word"] == word)
            doc = self.doc(slug)
            self.assertEqual(list(doc), ["palabra", "frases"])
            self.assertEqual(doc["palabra"], word)
            want = [w["par"]["text"]] + [t for t in dict.fromkeys(i["text"] for i in w["frases"]) if t != w["par"]["text"]]      # own first, then the items' texts in order, none twice
            self.assertEqual(doc["frases"], [{"id": "%s:%d" % (slug, k), "text": t} for k, t in enumerate(want, 1)])
            for f in doc["frases"]:
                self.assertEqual(sorted(f), ["id", "text"])                                    # nothing says which letter is which
        self.assertEqual([f["text"] for f in self.doc("casa")["frases"]][0], "Esta es la casa.")
        self.assertGreater(len(self.doc("casa")["frases"]), 3)
        self.assertEqual([f["text"] for f in self.doc("tu-2")["frases"]], ["Tú tienes tu pan aquí."])   # its own sentence is also an item's: one sentence
        self.assertEqual(mr.pair_texts("a", [{"text": "b"}, {"text": "a"}, {"text": "c"}, {"text": "b"}]), ["a", "b", "c"])
        # a sentence with no page and a sentence whose page the reader doubted are both there; one the final data leaves out is not
        self.sheets(duda=["uno:2"])                                                            # y_long: own page not si, no page-free use: left out of casa, pan, abuela
        self.assertNotIn("Abuela come pan aquí con mamá y papá en casa ahora.", [f["text"] for f in self.doc("casa")["frases"]])
        self.assertIn("Abuela come pan aquí con mamá y papá en casa ahora.", [i["text"] for i in next(x for x in fin["palabras"] if x["word"] == "casa")["frases"]])

    def test_the_key_and_the_order_of_the_pictures(self):
        from PIL import Image, ImageDraw
        self.sheets()
        claves = self.claves()
        self.assertEqual(claves, {slug: mr.pair_si_letter(word) for slug, word in self.SLUGS})
        self.assertEqual(set(claves.values()), {"A", "B"})                                     # the letter is shuffled: `si` is not always A
        self.assertEqual((claves["hola"], claves["casa"]), ("A", "B"))
        font = mr.load_font(36)
        for slug, _ in self.SLUGS:
            with Image.open(self.out / "par" / slug / "par.png") as im:
                sheet = im.convert("RGB")
            # 40x12 pictures at 4x: 160 x 48; margin 12, gap 16, 44 for the letters
            self.assertEqual(sheet.size, (12 * 2 + 160 * 2 + 16, 12 * 2 + 44 + 48))
            left, right = sheet.getpixel((12 + 3, 56 + 3)), sheet.getpixel((12 + 160 + 16 + 3, 56 + 3))
            self.assertEqual((left, right), (PAIR_SI, PAIR_NO) if claves[slug] == "A" else (PAIR_NO, PAIR_SI), slug)
            self.assertEqual(sheet.getpixel((12 + 159, 56 + 47)), left)                          # the whole picture is there
            self.assertEqual(sheet.getpixel((12 + 160 + 16 + 159, 56 + 47)), right)
            # only the letters above the pictures: the band over each picture is the letter drawn on the background, and nothing else is drawn
            blank = Image.new("RGB", sheet.size, (240, 240, 240))
            for x0, letter in ((12, "A"), (12 + 160 + 16, "B")):
                band = Image.new("RGB", (160, 44), (240, 240, 240))
                ImageDraw.Draw(band).text((80, 22), letter, fill=(20, 20, 20), font=font, anchor="mm")
                self.assertEqual(sheet.crop((x0, 12, x0 + 160, 56)).tobytes(), band.tobytes(), (slug, letter))
                blank.paste(sheet.crop((x0, 56, x0 + 160, 104)), (x0, 56))
                blank.paste(band, (x0, 12))
            self.assertEqual(sheet.tobytes(), blank.tobytes(), slug)                              # margins, gap and bands: the background

    def test_a_pair_without_picture_files_is_a_stop(self):
        _, text = self.sheets()
        self.assertIn("STOP, no sheet for the pair of mira: file not found: coqui/ref/escenas/frente/pairs/mira.si.png, coqui/ref/escenas/frente/pairs/mira.no.png", text)
        self.assertNotIn("mira", self.index().values())
        self.assertFalse((self.out / "par" / "mira").exists())
        plans, stops = mr.plan_pairs(self.R)
        self.assertEqual(stops, ["mira: file not found: coqui/ref/escenas/frente/pairs/mira.si.png, coqui/ref/escenas/frente/pairs/mira.no.png"])
        self.assertEqual([p["slug"] for p in plans.values()], [s for s, _ in self.SLUGS])
        fin, _, text = self.merge("pstop", self.root / "pbook", self.pair_files("pstop-par"))      # the merge goes on: mira has a pair, no sheet, no verdict
        self.assertIn("STOP, no sheet for the pair of mira", text)
        mira = next(w for w in fin["palabras"] if w["word"] == "mira")
        self.assertEqual((mira["puntua"], [x["clip"] for x in mira["par_frases"]], any(i["par"] for i in mira["frases"])), ("cual", ["mira_aqui"], False))
        self.assertEqual(fin["meta"]["pares_sin_hoja"], stops)

    def test_how_a_pair_finds_its_files(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            from PIL import Image
            for sc in ("uno", "otra"):
                (root / "coqui" / "ref" / "escenas" / sc / "pairs").mkdir(parents=True)
            for f in ("zz.si.png", "zz.no.png"):
                Image.new("RGB", (2, 2)).save(root / "coqui" / "ref" / "escenas" / "otra" / "pairs" / f)
            entry = {"file": "cual-x", "w": "zz", "say": "s", "sayText": "S.", "si": {"png": "zz.si.png"}, "no": {"png": "zz.no.png"}}
            pair = {"file": "cual-x", "scene": "uno", "say": "s"}
            # the scene folder of the story file has no entry: the others are searched (a pair drawn by another scene is listed in both)
            si, no, why = mr.find_pair_files(root, {"uno": [], "otra": [entry]}, "zz", pair)
            self.assertEqual((si.name, no.name, why, si.parent.parent.name), ("zz.si.png", "zz.no.png", None, "otra"))
            self.assertEqual(mr.find_pair_files(root, {"uno": [entry], "otra": []}, "zz", pair)[2], "file not found: coqui/ref/escenas/uno/pairs/zz.si.png, coqui/ref/escenas/uno/pairs/zz.no.png")
            self.assertEqual(mr.find_pair_files(root, {"uno": [], "otra": [entry]}, "yy", pair)[2], "no entry for file cual-x, word yy in any coqui/ref/escenas/*/pairs.json")
            self.assertEqual(mr.find_pair_files(root, {"otra": [dict(entry, say="t")]}, "zz", pair)[2], "coqui/ref/escenas/otra/pairs.json says the clip t, the story file says s")
            self.assertEqual(mr.find_pair_files(root, {"otra": [dict(entry, file="cual-y")]}, "zz", pair)[2], "no entry for file cual-x, word zz in any coqui/ref/escenas/*/pairs.json")

    def test_groups(self):
        self.assertEqual(mr.pair_groups([10] * 10), [[0, 1], [2, 3], [4, 5], [6, 7], [8, 9]])
        self.assertEqual(mr.pair_groups([1] * 5), [[0], [1], [2], [3], [4]])
        self.assertEqual(mr.pair_groups([5, 5, 5]), [[0], [1], [2]])                           # fewer words than groups
        self.assertEqual(mr.pair_groups([]), [])
        counts = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3, 2, 3, 8, 4, 6, 2, 6, 4, 3, 3, 8, 3, 2, 7, 9, 5]
        g = mr.pair_groups(counts)
        self.assertEqual([i for r in g for i in r], list(range(len(counts))))                  # every word once, in order
        self.assertEqual(len(g), 5)
        sums = [sum(counts[i] for i in r) for r in g]
        self.assertLessEqual(max(sums) - min(sums), 9)                                         # about equal: no more apart than the biggest word
        g = mr.pair_groups([50] + [1] * 9)
        self.assertTrue(all(r for r in g) and [i for r in g for i in r] == list(range(10)))
        self.sheets()
        groups = json.loads((self.out / "par" / "grupos.json").read_text(encoding="utf-8"))
        self.assertEqual(list(groups), ["1", "2", "3", "4", "5"])
        self.assertEqual([s for g in groups.values() for s in g], [s for s, _ in self.SLUGS])
        self.assertTrue(all(groups.values()))

    def test_the_sheets_refuse_a_bad_book_verdict_set(self):
        v = self.verdicts()
        del v["dos"]["frases"]["dos:3"]
        d = self.write(v, "pbad")
        code, text = self.run_cli("--veredictos", str(d), "--hojas-par")
        self.assertEqual(code, 1)
        self.assertIn("dos.json: missing sentence dos:3", text)
        with contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                mr.main(["--out", str(self.out), "--repo", self.tmp.name, "--hojas-par"])         # it needs the book verdicts
            with self.assertRaises(SystemExit):
                mr.main(["--out", str(self.out), "--repo", self.tmp.name, "--veredictos", str(d)])
            with self.assertRaises(SystemExit):
                mr.main(["--out", str(self.out), "--repo", self.tmp.name, "--veredictos-par", str(d), "--hojas-par", "--veredictos", str(d)])

    # the validator of the pair verdicts
    def pfaults(self, change, name="pf"):
        self.sheets()
        d = self.pair_files(name, change)
        return mr.valida_veredictos_par(d, self.out)[0]

    def test_pair_validator_accepts_a_good_set(self):
        self.sheets()
        d = self.pair_files("pok")
        self.assertEqual(mr.valida_veredictos_par(d, self.out), ([], []))
        code, text = self.run_cli("--valida-veredictos-par", str(d))
        self.assertEqual(code, 0)
        self.assertIn("ok: 6 files", text)
        # every one of the five values is accepted
        d = self.pair_files("pok5", value=lambda slug, k: mr.PAR_VALUES[(k - 1) % 5])
        self.assertEqual(mr.valida_veredictos_par(d, self.out)[0], [])

    def test_pair_validator_missing_sentence(self):
        def m(files):
            del files["casa"]["frases"]["casa:2"]
        self.assertEqual(self.pfaults(m), ["casa.json: missing sentence casa:2"])

    def test_pair_validator_unknown_id(self):
        def m(files):
            files["hola"]["frases"]["hola:9"] = "A"
            files["casa"]["frases"]["perro:1"] = "A"
        self.assertEqual(self.pfaults(m), ["casa.json: unknown sentence id perro:1", "hola.json: unknown sentence id hola:9"])

    def test_pair_validator_values(self):
        def m(files):
            files["casa"]["frases"]["casa:1"] = "C"
            files["casa"]["frases"]["casa:2"] = "a"                     # the letters are capitals
            files["hola"]["frases"]["hola:1"] = ["A"]
            files["hola"]["frases"]["hola:2"] = None
            files["perro"]["frases"]["perro:1"] = "Ambas"
            files["perro"]["frases"]["perro:2"] = ""
        got = self.pfaults(m)
        self.assertEqual(got, ['casa.json: casa:1: "C" is not one of A, B, ambas, ninguna, duda', 'casa.json: casa:2: "a" is not one of A, B, ambas, ninguna, duda',
                               'hola.json: hola:1: ["A"] is not one of A, B, ambas, ninguna, duda', 'hola.json: hola:2: null is not one of A, B, ambas, ninguna, duda',
                               'perro.json: perro:1: "Ambas" is not one of A, B, ambas, ninguna, duda', 'perro.json: perro:2: "" is not one of A, B, ambas, ninguna, duda'])

    def test_pair_validator_other_faults(self):
        def m(files):
            files["hola"]["palabra"] = "perro"
            files["casa"]["frases"] = ["A"]
            del files["perro"]["palabra"]
            files["el"] = ["not", "an", "object"]
        got = self.pfaults(m)
        self.assertIn('hola.json: `palabra` is "perro", not "hola"', got)
        self.assertIn("casa.json: `frases` is missing or is not an object", got)
        self.assertIn("casa.json: missing sentence casa:1", got)
        self.assertIn('perro.json: `palabra` is null, not "perro"', got)
        self.assertIn("el.json: not a JSON object", got)
        self.assertEqual(len(got), 4 + len(self.doc("casa")["frases"]))                          # the four above, and every sentence of casa is missing

    def test_pair_validator_files(self):
        self.sheets()
        d = self.pair_files("pfiles")
        (d / "mira.json").write_text("{}", encoding="utf-8")                                        # a word with no sheet
        (d / "perro.json").write_text("{ not json", encoding="utf-8")
        f = mr.valida_veredictos_par(d, self.out)[0]
        self.assertTrue(any(x.startswith("mira.json: not the file of a word with a sheet") for x in f), f)
        self.assertTrue(any(x.startswith("perro.json: cannot be read as JSON") for x in f), f)
        # a word with no file is only a note, until the merge asks for every word
        (d / "mira.json").unlink()
        (d / "perro.json").unlink()
        (d / "hola.json").unlink()
        faults, notes = mr.valida_veredictos_par(d, self.out)
        self.assertEqual(faults, [])
        self.assertEqual(len(notes), 1)
        self.assertIn("words with no verdict file yet: 2 of 6 (hola, perro)", notes[0])
        self.assertEqual(mr.valida_veredictos_par(d, self.out, require_all=True)[0], ["hola.json: no verdict file for this word", "perro.json: no verdict file for this word"])
        code, text = self.run_cli("--valida-veredictos-par", str(d))
        self.assertEqual(code, 0)
        self.assertIn("note: words with no verdict file yet", text)

    def test_pair_validator_exit_code_is_one_with_a_fault(self):
        self.sheets()
        d = self.pair_files("pbad2", lambda files: files["casa"]["frases"].pop("casa:3"))
        code, text = self.run_cli("--valida-veredictos-par", str(d))
        self.assertEqual(code, 1)
        self.assertIn("casa.json: missing sentence casa:3", text)
        self.assertIn("1 faults in 6 files", text)

    # the merge
    def test_par_is_true_when_the_verdict_is_the_letter_of_si_both_ways(self):
        bd, _ = self.sheets()
        claves = self.claves()
        for value in ("A", "B"):
            pd = self.pair_files("pv" + value, value=lambda slug, k: value)
            fin, _, _ = self.merge("pv" + value, bd, pd)
            for slug, word in self.SLUGS:
                w = next(x for x in fin["palabras"] if x["word"] == word)
                self.assertTrue(w["frases"], word)
                self.assertEqual([i["par"] for i in w["frases"]], [claves[slug] == value] * len(w["frases"]), (word, value))
            for w in fin["palabras"]:
                if not w["par"]:
                    self.assertFalse(any(i["par"] for i in w["frases"]))                           # no pair: false
            # mira has a pair but no sheet: false
            self.assertFalse(any(i["par"] for i in next(x for x in fin["palabras"] if x["word"] == "mira")["frases"]))
        self.assertEqual((claves["hola"], claves["casa"]), ("A", "B"))                                # one word each way

    def test_par_follows_each_sentence_and_ambas_ninguna_duda_are_false(self):
        bd, _ = self.sheets()
        letter = self.claves()["casa"]
        other = "A" if letter == "B" else "B"
        order = [letter, other, "ambas", "ninguna", "duda"]
        pd = self.pair_files("pmix", value=lambda slug, k: order[(k - 2) % 5])                      # the first item gets si's letter, the second the other, ...
        fin, _, _ = self.merge("pmix", bd, pd)
        casa = next(x for x in fin["palabras"] if x["word"] == "casa")
        self.assertEqual([i["par"] for i in casa["frases"]], [True, False, False, False])
        self.assertEqual(self.doc("casa")["frases"][0]["id"], "casa:1")
        for value in ("ambas", "ninguna", "duda"):
            pd = self.pair_files("pnone", value=lambda slug, k: value)
            fin, _, _ = self.merge("pnone", bd, pd)
            self.assertFalse(any(i["par"] for w in fin["palabras"] for i in w["frases"]), value)
            self.assertTrue(all(len(w["par_frases"]) == (1 if w["par"] else 0) for w in fin["palabras"]), value)
        # the own sentence's verdict does not matter for par_frases
        pd = self.pair_files("pown", value=lambda slug, k: "ninguna" if k == 1 else self.claves()[slug])
        fin, _, _ = self.merge("pown", bd, pd)
        casa = next(x for x in fin["palabras"] if x["word"] == "casa")
        self.assertEqual(casa["par_frases"][0], {"clip": "esta_casa", "text": "Esta es la casa."})
        self.assertEqual(len(casa["par_frases"]), 1 + len(casa["frases"]))

    def test_par_frases_order_and_no_text_twice(self):
        bd, _ = self.sheets()
        pd = self.pair_files("porder")
        fin, _, _ = self.merge("porder", bd, pd)
        casa = next(x for x in fin["palabras"] if x["word"] == "casa")
        self.assertEqual(casa["par_frases"][0], {"clip": "esta_casa", "text": "Esta es la casa."})        # the own sentence first
        self.assertEqual(casa["par_frases"][1:], [{"clip": i["clip"], "text": i["text"]} for i in casa["frases"]])   # then the items, in the word's order
        self.assertEqual([list(x) for x in casa["par_frases"]], [["clip", "text"]] * len(casa["par_frases"]))
        self.assertEqual([i["clip"] for i in casa["frases"]], [c["clip"] for c in mr.mix([c for c in self.R["cands"] if c["word"] == "casa"], "casa") if c["clip"] in {i["clip"] for i in casa["frases"]}])
        # tu: its own sentence is also the sentence of its one item, which is `par` but is not added again
        tu = next(x for x in fin["palabras"] if x["word"] == "tu")
        self.assertEqual([i["par"] for i in tu["frases"]], [True])
        self.assertEqual(tu["par_frases"], [{"clip": "tu_pan", "text": "Tú tienes tu pan aquí."}])
        # tú: its own sentence, then the item "Tú tienes tu pan aquí." (a sentence another word's pair has too: that does not matter)
        tu2 = next(x for x in fin["palabras"] if x["word"] == "tú")
        self.assertEqual([x["text"] for x in tu2["par_frases"]], ["Eres tú.", "Tú tienes tu pan aquí."])
        self.assertEqual(tu2["par_frases"][1]["clip"], "c_tu")
        # a word with no pair has none
        self.assertEqual(next(x for x in fin["palabras"] if x["word"] == "flor")["par_frases"], [])

    def test_without_pair_verdicts_the_tool_says_so(self):
        bd, _ = self.sheets()
        fin, f, text = self.merge("pnop", bd, None)
        self.assertIn("no --veredictos-par", text)
        self.assertFalse(fin["meta"]["veredictos_par"])
        self.assertFalse(any(i["par"] for w in fin["palabras"] for i in w["frases"]))
        for w in fin["palabras"]:
            self.assertEqual([x["clip"] for x in w["par_frases"]], [w["par"]["clip"]] if w["par"] else [])
        self.assertIn("Pair verdicts: NONE given", f.with_name("resumen-final.md").read_text(encoding="utf-8"))
        # and the merge with them says nothing of the kind
        fin, f, text = self.merge("pyes", bd, self.pair_files("pyes-par"))
        self.assertNotIn("no --veredictos-par", text)
        self.assertTrue(fin["meta"]["veredictos_par"])
        self.assertNotIn("NONE given", f.with_name("resumen-final.md").read_text(encoding="utf-8"))

    def test_the_merge_refuses_bad_or_stale_pair_files(self):
        bd, _ = self.sheets()
        # a word with no file
        pd = self.pair_files("pm1")
        (pd / "hola.json").unlink()
        _, f, text = self.merge("pm1", bd, pd, expect=1)
        self.assertIn("hola.json: no verdict file for this word", text)
        self.assertFalse(f.exists())
        # a fault in a file
        pd = self.pair_files("pm2", lambda files: files["casa"]["frases"].pop("casa:2"))
        _, f, text = self.merge("pm2", bd, pd, expect=1)
        self.assertIn("casa.json: missing sentence casa:2", text)
        self.assertFalse(f.exists())
        # the sheets are not what the tool makes now: a sentence changed, a key changed, the book verdicts changed
        pd = self.pair_files("pm3")
        p = self.out / "par" / "casa" / "frases.json"
        j = json.loads(p.read_text(encoding="utf-8"))
        j["frases"][1]["text"] = "Otra frase."
        p.write_text(json.dumps(j, ensure_ascii=False), encoding="utf-8")
        _, f, text = self.merge("pm3", bd, pd, expect=1)
        self.assertIn("par/casa/frases.json: is not what the tool makes", text)
        self.assertFalse(f.exists())
        self.sheets()
        c = self.claves()
        c["casa"] = "A" if c["casa"] == "B" else "B"
        (self.out / "par" / "claves.json").write_text(json.dumps(c), encoding="utf-8")
        _, f, text = self.merge("pm3", bd, pd, expect=1)
        self.assertIn("par/claves.json: the letter of casa is not what the tool makes", text)
        self.sheets()
        other = self.write(self.verdicts(duda=["uno:2"]), "pm4book")                               # y_long is left out of casa now: the sentences to judge changed
        _, f, text = self.merge("pm4", other, pd, expect=1)
        self.assertIn("par/casa/frases.json: is not what the tool makes", text)
        self.assertFalse(f.exists())
        # the sheets were never written
        out2 = self.root / "out-nopar"
        quiet(["--out", str(out2), "--repo", self.tmp.name, "--hojas-libro"])
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                mr.main(["--out", str(out2), "--repo", self.tmp.name, "--veredictos", str(bd), "--veredictos-par", str(pd), "--final", str(self.root / "nopar" / "f.json")])

    def test_tokens_extra_prohibidos_and_no_juntas_in_the_final_data(self):
        bd, _ = self.sheets()
        fin, _, _ = self.merge("pt", bd, None)
        tep = lambda w, clip: self.item(fin, w, clip)["tokens_extra_prohibidos"]
        self.assertEqual(tep("el", "b_el"), ["el", "pan", "perro", "él"])                                  # the accent twin is in it too
        self.assertEqual(tep("bebé", "e_bebe"), ["bebe", "bebé", "el", "él"])
        self.assertEqual(tep("no hay", "f_nohay"), ["hay", "no", "no hay", "pan"])
        self.assertEqual(tep("nada", "g_nada"), ["nada", "no"])
        self.assertEqual(tep("casa", "d_esta"), ["casa", "esta", "está"])
        self.assertEqual(tep("tu", "c_tu"), ["pan", "tu", "tú"])
        for w in fin["palabras"]:
            for i in w["frases"]:
                self.assertEqual(i["tokens_extra_prohibidos"], sorted(i["tokens_extra_prohibidos"]))
                self.assertIn(w["word"], i["tokens_extra_prohibidos"], (w["word"], i["text"]))        # the item's own word is in its sentence
        nj = {w["word"]: w["no_juntas"] for w in fin["palabras"]}
        self.assertEqual({w: l for w, l in nj.items() if l}, {"él": ["el"], "el": ["él"], "tú": ["tu"], "tu": ["tú"], "está": ["esta"], "esta": ["está"], "bebé": ["bebe"],
                                                             "bebe": ["bebé"], "no": ["no hay"], "hay": ["no hay"], "no hay": ["hay", "no"], "nada": ["de nada"],
                                                             "de nada": ["nada"]})

    def test_the_summary(self):
        bd, _ = self.sheets()
        pd = self.pair_files("psum", value=lambda slug, k: self.claves()[slug])
        fin, f, _ = self.merge("psum", bd, pd)
        text = f.with_name("resumen-final.md").read_text(encoding="utf-8")
        self.assertNotIn("## Parejas", text)
        for needle in ("## Sentences usable with a word's picture pair (`par_frases`)", "## Distribution of words with a pair by number of `par_frases`",
                       "| learner | words with a pair | 1 | 2 | 3-4 | 5-9 | 10+ |", "Words whose only `par_frases` is the pair's own sentence:",
                       "## Words that must not meet (`no_juntas`)", "| word | judged | items par | par_frases |"):
            self.assertIn(needle, text)
        # per word: sentences judged, items par, par_frases
        n = {w["word"]: (len(mr.pair_texts(w["par"]["text"], w["frases"])), sum(i["par"] for i in w["frases"]), len(w["par_frases"])) for w in fin["palabras"] if w["par"]}
        self.assertEqual(n["casa"], (5, 4, 5))
        self.assertEqual(n["tu"], (1, 1, 1))
        self.assertEqual(n["mira"][1:], (0, 1))                                                    # no sheet, no verdict: only its own sentence
        for word, (judged, par, pf) in n.items():
            self.assertIn("| %s | %d | %d | %d |" % (word, judged, par, pf), text)
        # the distribution: 1 / 2 / 3 to 4 / 5 to 9 / 10 and more
        counts = sorted(v[2] for v in n.values())
        want = [sum(1 for c in counts if c == 1), sum(1 for c in counts if c == 2), sum(1 for c in counts if 3 <= c <= 4), sum(1 for c in counts if 5 <= c <= 9), sum(1 for c in counts if c >= 10)]
        self.assertIn("| all words with a pair, all stories | %d | %s |" % (len(n), " | ".join(map(str, want))), text)
        self.assertEqual(sum(want), len(n))
        self.assertIn("| finished stories 1..3 | %d | %s |" % (len(n), " | ".join(map(str, want))), text)           # both stories are finished by 3
        only = [w for w, v in n.items() if v[2] == 1]
        self.assertIn("- all stories: %d words: %s" % (len(only), ", ".join(only)), text)
        # no_juntas by rule
        for row in ("| a | accent twins (equal after folding accents) | 4 | 4 |", "| c | the same first 3 letters after folding accents, both of at least 3 letters (4 when one of the two is a phrase) | 2 | 0 |",
                    "| e | one is the other plus a final s or es | 0 | 0 |", "Pairs of different words in all: 7."):
            self.assertIn(row, text)
        self.assertIn("(b) one is a whole-word part of the other, which is a phrase (accents folded): 3", text)

    def test_the_summary_counts_a_learner_by_the_stories_finished(self):
        bd, _ = self.sheets()
        pd = self.pair_files("pk", value=lambda slug, k: self.claves()[slug])
        fin, f, _ = self.merge("pk", bd, pd)
        el = next(x for x in fin["palabras"] if x["word"] == "el")
        stories = {i["cuento"] for i in el["frases"]}
        self.assertEqual(stories, {"uno", "dos"})                                                   # items in both stories
        all_n = len({el["par"]["text"]} | {i["text"] for i in el["frases"]})
        one_n = len({el["par"]["text"]} | {i["text"] for i in el["frases"] if i["cuento"] == "uno"})
        self.assertLess(one_n, all_n)
        saved = mr.KS
        mr.KS = (1,)
        try:
            fin, f, _ = self.merge("pk1", bd, pd)
        finally:
            mr.KS = saved
        text = f.with_name("resumen-final.md").read_text(encoding="utf-8")
        row = [x for x in text.splitlines() if x.startswith("| finished stories 1..1 |")][-1]       # the second table: words with a pair
        met = [w for w in fin["palabras"] if w["par"] and w["word"] in ("tú", "tu", "el")]          # the pair words first met in story 1
        want = Counter(mr_bucket(len({w["par"]["text"]} | {i["text"] for i in w["frases"] if i["par"] and i["cuento"] == "uno"})) for w in met)
        self.assertEqual(row, "| finished stories 1..1 | %d | %s |" % (len(met), " | ".join(str(want.get(b, 0)) for b in mr.PAR_BUCKETS)))

    # determinism
    def test_same_bytes_twice(self):
        outs = []
        bd = self.write(self.verdicts(), "pdet-book")
        for i in range(2):
            o = self.root / ("pdet%d" % i)
            quiet(["--out", str(o), "--repo", self.tmp.name, "--hojas-libro"])
            quiet(["--out", str(o), "--repo", self.tmp.name, "--veredictos", str(bd), "--hojas-par"])
            outs.append(o)
        files = sorted(p.relative_to(outs[0] / "par") for p in (outs[0] / "par").rglob("*") if p.is_file())
        self.assertEqual(len(files), 6 * 2 + 3)
        self.assertTrue(any(str(f).endswith(".png") for f in files))
        for f in files:
            self.assertEqual((outs[0] / "par" / f).read_bytes(), (outs[1] / "par" / f).read_bytes(), str(f))
        self.assertEqual((outs[0] / "par" / "casa" / "frases.json").read_bytes(), (self.root / "pdet0" / "par" / "casa" / "frases.json").read_bytes())
        # a second run into the same folder changes nothing, and leaves no folder of an earlier run
        stale = outs[0] / "par" / "gone"
        stale.mkdir()
        (stale / "par.png").write_bytes(b"x")
        before = {f: (outs[0] / "par" / f).read_bytes() for f in files}
        quiet(["--out", str(outs[0]), "--repo", self.tmp.name, "--veredictos", str(bd), "--hojas-par"])
        self.assertFalse(stale.exists())
        self.assertEqual({f: (outs[0] / "par" / f).read_bytes() for f in files}, before)
        # the merge, with pair verdicts and without
        pd = self.root / "pdet-par"
        pd.mkdir()
        for slug, word in self.SLUGS:
            doc = json.loads((outs[0] / "par" / slug / "frases.json").read_text(encoding="utf-8"))
            (pd / (slug + ".json")).write_text(json.dumps({"palabra": word, "frases": {f["id"]: ("A", "B", "ambas", "ninguna", "duda")[k % 5] for k, f in enumerate(doc["frases"])}}, ensure_ascii=False), encoding="utf-8")
        sums = []
        for o in outs:
            f1, f2 = o / "f1" / "final.json", o / "f2" / "final.json"
            self.assertEqual(quiet(["--out", str(o), "--repo", self.tmp.name, "--veredictos", str(bd), "--veredictos-par", str(pd), "--final", str(f1)]), 0)
            self.assertEqual(quiet(["--out", str(o), "--repo", self.tmp.name, "--veredictos", str(bd), "--final", str(f2)]), 0)
            sums.append([hashlib.sha256(p.read_bytes()).hexdigest() for p in (f1, f1.with_name("resumen-final.md"), f2, f2.with_name("resumen-final.md"))])
        self.assertEqual(sums[0], sums[1])
        self.assertNotEqual(sums[0][0], sums[0][2])                                                   # the pair verdicts did change the data


class AppFile(PairBase):
    """--app and --check: the app's slim file (historia/datos/repaso.json in the real repo), on the made-up repo."""

    def app(self, name, check=False, expect=0, target=None, pair=True):
        bd, _ = self.sheets()
        pd = self.pair_files(name + "-par") if pair else None
        f = target or (self.root / (name + "-app") / "repaso.json")
        args = ["--veredictos", str(bd)] + (["--veredictos-par", str(pd)] if pd else []) + ["--app", str(f)] + (["--check"] if check else [])
        code, text = self.run_cli(*args)
        self.assertEqual(code, expect, text)
        return f, text

    def load(self, f):
        return json.loads(f.read_text(encoding="utf-8"))

    def test_the_file_has_only_what_the_games_need(self):
        f, text = self.app("a1")
        self.assertIn("app file", text)
        app = self.load(f)
        self.assertEqual(list(app), ["v", "frases", "palabras"])
        self.assertEqual(app["v"], 1)
        self.assertEqual([w["w"] for w in app["palabras"]], [w["word"] for w in self.R["words"]])                 # every word, course order
        for w in app["palabras"]:
            self.assertEqual(list(w), ["w", "lugar", "puntua", "solo", "no_juntas", "cual", "frases", "donde", "dilo"])
            self.assertEqual(w["lugar"], "casa")
        for x in app["frases"]:
            self.assertEqual(list(x), ["clip", "cuento", "text", "tokens", "prohibidas", "img", "oyes", "arma"])
        # one record per (clip, story), however many words share it
        keys = [(x["clip"], x["cuento"]) for x in app["frases"]]
        self.assertEqual(len(keys), len(set(keys)))
        # what the final data says, word by word
        fin, _, _ = self.merge("a1m", self.root / "pbook", self.root / "a1-par")
        for w, fw in zip(app["palabras"], fin["palabras"]):
            self.assertEqual(w["puntua"], fw["puntua"])
            self.assertEqual(w["no_juntas"], fw["no_juntas"])
            want = [i for i in fw["frases"] if i["que_oyes"] or i["arma"]]
            got = [app["frases"][k] for k in w["frases"]]
            self.assertEqual([(g["clip"], g["text"], g["tokens"], g["prohibidas"], g["oyes"], g["arma"]) for g in got],
                             [(i["clip"], i["text"], i["tokens"], i["tokens_extra_prohibidos"], i["que_oyes"], i["arma"]) for i in want], w["w"])
            # the picture only where the readers put the own page in si
            self.assertEqual([g["img"] for g in got], [(i["pagina"]["img"] if i["pagina"] and not i["propia_dudosa"] else None) for i in want])
            # ¿Cuál?: the pair's own sentence (no story: always there), then the par items with their story
            self.assertEqual([(c["clip"], c["text"]) for c in w["cual"]], [(c["clip"], c["text"]) for c in fw["par_frases"]])
            if w["cual"]:
                self.assertIsNone(w["cual"][0]["cuento"])
                for c in w["cual"][1:]:
                    self.assertTrue(any(i["clip"] == c["clip"] and i["cuento"] == c["cuento"] and i["par"] for i in fw["frases"]), c)
            # ¿Dónde?: the items with fair wrong pictures, their own sentence and the wrong pages' pictures
            self.assertEqual([(app["frases"][d["frase"]]["clip"], d["otras"]) for d in w["donde"]],
                             [(i["clip"], ["img/dos-%d.png" % n for n in i["cual"]]) for i in fw["frases"] if i["cual"]])
            self.assertEqual([(d["clip"], d["cuento"], d["formas"], d["antes"]) for d in w["dilo"]],
                             [(d["clip"], d["cuento"], d["formas"], d["antes"]["clip"]) for d in fw["dilo"]])
        mira = next(w for w in app["palabras"] if w["w"] == "mira")
        self.assertEqual(mira["dilo"], [{"clip": "l_mira", "cuento": "uno", "text": "Mira el pan aquí.", "formas": ["mira", "mirá"], "antes": "k_corr", "img": None}])
        flor = next(w for w in app["palabras"] if w["w"] == "flor")
        self.assertTrue(flor["donde"])
        self.assertEqual(app["frases"][flor["donde"][0]["frase"]]["img"], "img/dos-1.png")

    def test_the_bytes_are_compact_and_the_same_twice(self):
        f1, _ = self.app("a2")
        f2, _ = self.app("a3")
        b = f1.read_bytes()
        self.assertEqual(b, f2.read_bytes())
        self.assertTrue(b.endswith(b"}\n"))
        self.assertNotIn(b"\n", b[:-1])
        self.assertNotIn(b"\\u00", b)                       # Spanish letters as they are
        self.assertEqual(b, mr.app_bytes(self.load(f1)))

    def test_check(self):
        f, _ = self.app("a4")
        before = f.read_bytes()
        _, text = self.app("a4", check=True, target=f)
        self.assertIn("ok:", text)
        # stale: one byte changed; the check says so, exits 1, and writes nothing
        f.write_bytes(before.replace(b'"v":1', b'"v":2'))
        _, text = self.app("a4", check=True, target=f, expect=1)
        self.assertIn("STALE", text)
        self.assertIn(b'"v":2', f.read_bytes())
        # missing
        g = self.root / "a4-missing" / "repaso.json"
        _, text = self.app("a4", check=True, target=g, expect=1)
        self.assertIn("missing", text)
        self.assertFalse(g.exists())
        # made without the pair verdicts, the file is not the one made with them
        f.write_bytes(before)
        self.app("a4", check=True, target=f, expect=1, pair=False)

    def test_the_arguments(self):
        for args in (["--app", "x.json"], ["--check"], ["--veredictos", "v", "--check"]):
            with self.assertRaises(SystemExit), contextlib.redirect_stderr(io.StringIO()):
                mr.main(["--out", str(self.out)] + args)

    def test_solo_clips(self):
        D = mr.Data()
        D.idx, D.dib = {"s1": 1, "s2": 2}, ["d1"]
        D.audio = {"a", "b", "c", "d", "e", "f"}
        D.story = {"s2": {"clips": {"a": {"text": "¡Hola!"}, "b": {"text": "Abuela dice: ¡Hola!"}}},
                   "s1": {"clips": {"c": {"text": "¿Tengo sed?"}, "d": {"text": "hola"}, "g": {"text": "Casa."}}},
                   "d1": {"clips": {"e": {"text": "Casa."}, "f": {"text": "Sí, casa."}}}}
        got = mr.solo_clips(D, ["casa", "hola", "tengo sed", "no", "sí"])
        # the first in course order; the whole text is the word (signs and case aside); a clip with no recording (g) is not used
        self.assertEqual(got, {"casa": "e", "hola": "d", "tengo sed": "c"})
        self.assertEqual(list(got), ["casa", "hola", "tengo sed"])


def unicodedata_nfd(s):
    import unicodedata
    return unicodedata.normalize("NFD", s)


def mr_bucket(n):
    return "1" if n == 1 else "2" if n == 2 else "3-4" if n <= 4 else "5-9" if n <= 9 else "10+"


class RealData(unittest.TestCase):
    """The tool on this repo's real stories with made-up verdicts (nothing about the real pictures is judged): sizes and invariants."""

    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[3]
        if not (cls.root / "historia" / "datos" / "curso.json").exists():
            raise unittest.SkipTest("no historia/ in this checkout")
        cls.R = mr.build(cls.root)
        cls.S = mr.sentences_by_book(cls.R)

    def book_verdicts(self):
        """The made-up verdicts of the test below: every sentence fits its own page, every other page is `no`."""
        return {b: {"frases": {s["id"]: verd(si=[s["own"]], no=[p for p in range(1, len(self.R["D"].book[b]["pages"]) + 1) if p != s["own"]]) for s in rows},
                    "parecidas": set()} for b, rows in self.S.items()}

    def pair_of(self, word):
        return next(w["pair"] for w in self.R["words"] if w["word"] == word)

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
        self.assertNotIn("parejas", fin)
        for w in fin["palabras"]:
            self.assertEqual(w["puntua"], mr.puntua(w["frases"], w["par"]))
            self.assertFalse(any(i["par"] for i in w["frases"]))                         # no pair verdicts given
            self.assertEqual([x["clip"] for x in w["par_frases"]], [w["par"]["clip"]] if w["par"] else [])
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
        # some of everything, with these verdicts
        self.assertTrue(any(v["falsas"] for v in fin["paginas"].values()))
        self.assertTrue(any(i["cual"] for w in fin["palabras"] for i in w["frases"]))

    def test_every_pair_has_its_pictures(self):
        plans, stops = mr.plan_pairs(self.R)
        self.assertEqual(stops, [])
        self.assertEqual(len(plans), 128)
        self.assertEqual(len({p["slug"] for p in plans.values()}), 128)
        self.assertTrue(all(p["si"].is_file() and p["no"].is_file() and p["letter"] in "AB" for p in plans.values()))
        self.assertEqual({p["letter"] for p in plans.values()}, {"A", "B"})
        self.assertEqual(list(plans), [w["word"] for w in self.R["words"] if w["pair"]])         # course order

    def test_made_up_pair_verdicts(self):
        items_of, _ = mr.collect_items(self.R, self.book_verdicts())
        plans, _ = mr.plan_pairs(self.R)
        cycle = ["si", "B-or-A", "ambas", "ninguna", "duda"]
        PV = {}
        for word, pl in plans.items():
            other = "B" if pl["letter"] == "A" else "A"
            texts = mr.pair_texts(self.pair_of(word)["text"], items_of[word])
            PV[pl["slug"]] = {"%s:%d" % (pl["slug"], k): {"si": pl["letter"], "B-or-A": other}.get(cycle[k % 5], cycle[k % 5]) for k in range(1, len(texts) + 1)}
        fin = mr.build_final(self.R, self.book_verdicts(), PV)
        n_par = 0
        for w in fin["palabras"]:
            pl = plans.get(w["word"])
            if not w["par"]:
                self.assertEqual(w["par_frases"], [])
                self.assertFalse(any(i["par"] for i in w["frases"]))
                continue
            self.assertEqual(w["par_frases"][0], {"clip": w["par"]["clip"], "text": w["par"]["text"]})
            texts = [x["text"] for x in w["par_frases"]]
            self.assertEqual(len(texts), len(set(texts)))
            self.assertEqual(texts[1:], [t for t in dict.fromkeys(i["text"] for i in w["frases"] if i["par"]) if t != w["par"]["text"]])
            ids = {t: k for k, t in enumerate(mr.pair_texts(w["par"]["text"], w["frases"]), 1)}
            for i in w["frases"]:
                self.assertEqual(i["par"], PV[pl["slug"]]["%s:%d" % (pl["slug"], ids[i["text"]])] == pl["letter"])
                n_par += i["par"]
        self.assertGreater(n_par, 100)
        self.assertGreater(sum(1 for w in fin["palabras"] if len(w["par_frases"]) > 1), 50)

    def test_no_juntas_on_the_real_words(self):
        words = [w["word"] for w in self.R["words"]]
        nj = mr.no_juntas(words)
        self.assertEqual(list(nj), words)
        for w, lst in nj.items():
            self.assertEqual(lst, sorted(lst))
            self.assertNotIn(w, lst)
            self.assertTrue(set(lst) <= set(words))
            for o in lst:
                self.assertIn(w, nj[o])                                                # symmetric
        self.assertIn("¿dónde está?", nj["está"])
        self.assertIn("no hay", nj["no"])
        self.assertIn("de nada", nj["nada"])
        self.assertIn("otra vez", nj["otra"])
        self.assertIn("quiere", nj["quiero"])
        self.assertIn("mira", nj["tira"])
        self.assertIn("esta", nj["este"])
        self.assertIn("abuela", nj["abuelo"])
        self.assertIn("tú", nj["tu"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
