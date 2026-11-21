# La sala, de día (place 9, La casa, un día entero, scene 3 of 4): stories 102, 103, 104. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/sala_dia.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `sala_dia` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: this one after the generators of places 4 to 8 (each sees only what was recorded before it); it is independent of the other three scenes of place 9.
# Every speaking turn of this scene is on a word of places 1 to 7 (me llamo: Quién eres tú; bonito: Está lloviendo; bien: Qué calor; hasta mañana: Hasta mañana; aquí: Las flores; me gusta: Qué quieres):
# no word of another story of place 9 is used (the `limpio` of 99 is not a turn of this scene).
#
# Where the script or its Needs list leaves a value open, this file fixes it in ONE place (and the report says so):
#   Things as act values: a thing he can touch is passed to the acts as its own key. `da102` {que}: "libro" (the book) or "papel" (a sheet of the pad); `pone103` {donde}: "oreja_abuelo" or "boca_abuelo";
#       `pega104` {pagina}: "pagina1" (the morning), "pagina2" (the afternoon), "pagina3" (the night). A wrong touch (`$x`) is the thing key itself: no chain of calcs is needed.
#   Start of every story: the people and the frog are placed at the spots the script's "Start" names (`llega`, `ir`), since the scene has no default for them (their places change from story to story):
#       102: luis cojin1, carmen cojin2 (the order the script names them in), abuela estante, the frog mesa_coqui. 103: abuelo butaca, luis cojin1, carmen cojin2, abuela ventana_abuela, the frog brazo_coqui.
#       104: luis escritorio, carmen cojin2 (the script says only "at the low table"), the frog mesa_coqui; the script does not say where abuela is (see the report): no `llega` for her.
#   Counts: `hojas` (102), `bateria` (103), `estrellas` (104) {n} = what is left. 102: the pad has 5 sheets; `hojas` goes 5, 4 (Carmen's sheet), 3 (Luis's sheet); the game then costs one clean sheet a miss (2, then 1).
#       103: `bateria` 3 at the start and at step 4 ("the battery shows three bars"), then 2, then 1 after each miss. 104: `estrellas` 3 at the start, then 2, 1. `final102`, `final103`, `final104` {n} = what is left at the end (3 minus what was lost).
#   102, the game: round A and round B each draw the child (luis, carmen) and what he does (lee, escribe) on their own: the two rounds may be the same. Abuela looks at her hands (`gesto harina`) before each of her lines of the game.
#   103, the game: what abuelo does (escucha, habla) is drawn each round on its own: the two rounds may be the same. In a miss, when abuelo should talk (the phone was at his ear) mamá's small voice says "¿Hola? ¿Hola?"
#       (a narrator clip with habla mama and exactly that text: the script gives no "Mamá dice:"). A right "escucha" ends with abuelo's nod (`gesto si`).
#   103, the opening's second ask ("Carmen dice: Ahora abuelo habla.") and the game's line are the same clip (same speaker, same words): `c103_ahora_habla`.
#   104, the game: one of the two rounds (drawn: `ra`) is la tarde, the other la mañana or la noche (drawn: `om`). The photo of each round is dealt out of the script's five (`reparte`): round B's is not round A's ("another photo").
#       Photo keys of `foto104` {que}: abuelo_lee, abuela_escribe, carmen_juega, luis_lee, abuela_juega (the game), luis_computadora and abuela_libro (the opening's two).
#   104, a miss runs `pega104` ok=0 in time with the correction line (the script puts the line between the sticking and the peeling); the star goes with the tear, `estrellas` shows what is left.
#   104, step 2: the three pages glow one after another, then Carmen names them: `pagina104` {n} glows one page and the engine runs loose acts together, so the three run in a row before the line.
#   Every story sets its own states at the start (hora tarde, the count): every story starts fresh.
import json,glob,os,re,collections,unicodedata
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); ABO=lambda t:D("abuelo","Abuelo",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); MA=lambda t:D("mama","Mamá",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time (people going to their places): all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
MINE=("lee-y-escribe","el-telefono","por-la-tarde")      # this generator's stories: not seen
# a clip whose text and speaker are already recorded under another id keeps that id (nothing is recorded twice); the stories of this run feed it too, in order.
# Ties go to the id most used, then to the earliest story of the course.
ORD={}
for i,s in enumerate(re.findall(r'"([a-z0-9-]+)"',"".join(re.findall(r'cuentos:\[(.*?)\]',open("curso.js",encoding="utf-8").read(),re.S)))): ORD.setdefault(s,i)
EX=collections.defaultdict(dict)   # (who, habla, text) -> {clip id: [stories that have it, first place in the course]}
def ex_add(cid,cl,o=9999):
    e=EX[(cl.get("who"),cl.get("habla"),cl["text"])].setdefault(cid,[0,o]); e[0]+=1; e[1]=min(e[1],o)
for f in sorted(glob.glob("cuentos/*.json")):
    nm=os.path.basename(f)[:-5]
    if nm in MINE or nm.startswith("z"): continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items(): ex_add(cid,cl,ORD.get(nm,9999))
def best(k): return min(EX[k],key=lambda cid:(-EX[k][cid][0],EX[k][cid][1],cid))
DIN=set()   # ids that are put together in the story ("c102_ahora_$qa_$wa"): never renamed
def reuse(st,turnos):
    ren={}
    for cid,cl in list(st["clips"].items()):
        if "$" in cid or cid in DIN: continue
        k=(cl.get("who"),cl.get("habla"),cl["text"])
        if k in EX and EX[k]:
            b=best(k)
            if b!=cid: ren[cid]=b
    def fx(o):
        if isinstance(o,str): return ren.get(o,o)
        if isinstance(o,list): return [fx(x) for x in o]
        if isinstance(o,dict): return {fx(k) if k in ren else k:fx(v) for k,v in o.items()}
        return o
    out=fx(st)
    # Speaking turns, put on the clip once its id is settled. A turn whose clip is not in the story, or is never played in it, is reported (MISSING TURN LINE) and not made up.
    def strs(o):
        if isinstance(o,str): yield o
        elif isinstance(o,list):
            for x in o: yield from strs(x)
        elif isinstance(o,dict):
            for x in o.values(): yield from strs(x)
    played=set(strs([out["beats"],out["final"]]))
    for cid,t in turnos.items():
        cid=ren.get(cid,cid)
        if cid in out["clips"] and cid in played: out["clips"][cid]["tu_turno"]=t
        else: print("MISSING TURN LINE",out["id"],cid)
    for cid,cl in out["clips"].items(): ex_add(cid,cl)
    return out
def noacc(s): return "".join(ch for ch in unicodedata.normalize("NFD",s) if unicodedata.category(ch)!="Mn")
def TG(*p):
    # the script's bracketed forms, and each one again without its accent (lower case, no punctuation)
    out=[]
    for w,f in p:
        fs=[]
        for x in f:
            for y in (x,noacc(x)):
                if y not in fs: fs.append(y)
        out.append({"palabra":w,"formas":fs})
    return out
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}
# What he hears when he pokes a person already recorded (mamá is only a photo and a voice on the telephone: not a thing he can poke)
NM={"abuela":("abuela",N("Esta es abuela.")),"abuelo":("n_abuelo",N("Este es abuelo.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!"))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}

# ---------------- 102. Lee y escribe ----------------
# Abuela leaves for the kitchen; the book and the pad lie between the children. She says what one child does now (child and verb drawn, each round on its own): "Ahora Luis lee." / "Ahora Carmen escribe." ...
# Decision A and B: touch a thing (the book, the pad; tests lee against escribe). A miss: a sheet where a book should be (a paper plane out of the window) or the book where a sheet should be (written in, Carmen tears a sheet out); a clean sheet is gone.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c102_ab_libro":AB("Coquí, mira: un libro."),"c102_ab_lee_luis":AB("Luis lee el libro."),"c102_ab_papel":AB("Y aquí hay papel."),"c102_ab_escribe_carmen":AB("Carmen escribe en el papel."),
 "c102_ca_nombre":CA("Escribo mi nombre. ¿Y tú? ¿Cómo te llamas?"),"c102_cq_llamo":T("¡Me llamo Coquí!"),"c102_l_yo_escribo":L("Ahora yo escribo."),"c102_ca_yo_leo":CA("Y yo leo."),
 "c102_donde_libro":N("Ahora Carmen lee. ¿Dónde está el libro?"),"c102_ab_luis_carmen":AB("Luis escribe. Carmen lee."),"c102_ca_para_ti":CA("Después, el papel es para ti, Coquí."),
 "c102_ca_te_gusta":CA("Para ti, Coquí. ¿Te gusta?"),"c102_cq_bonito":T("¡Qué bonito!"),"c102_fin":N("Luis lee un libro. Carmen escribe en el papel: Coquí.")})
KIDS=(("luis","Luis"),("carmen","Carmen"))
for k,K in KIDS:
    for w in ("lee","escribe"):
        c["c102_ahora_%s_%s"%(k,w)]=AB("Ahora %s %s."%(K,w)); c["c102_no_%s_%s"%(k,w)]=AB("¡No, Coquí! %s %s."%(K,w)); DIN.update(["c102_ahora_%s_%s"%(k,w),"c102_no_%s_%s"%(k,w)])
VARS102={"qa":["luis","carmen"],"qb":["luis","carmen"],"wa":["lee","escribe"],"wb":["lee","escribe"]}
def ronda102(s):
    # q: the child (drawn), w: what he does (drawn), p: the right thing (the book to read, a sheet of the pad to write).
    # Right: he reads (pictures float up) or writes (letters appear). Wrong: the other thing (x), the line, a clean sheet is gone (hojas), the cross.
    q,w,p="q"+s,"w"+s,"p"+s
    return [{"draw":q,"options":["luis","carmen"]},{"draw":w,"options":["lee","escribe"]},{"calc":p,"cond":w+"=lee","then":"libro","else":"papel"},gesto("abuela","harina"),
     {"decide":"do","options":["libro","papel"],"pick":"$"+p,"tests":"$"+w,"lock":True,"lead":[],"line":"c102_ahora_$%s_$%s"%(q,w),
      "right":[act("da102",que="$"+p,a="$"+q,ok=1),star],
      "wrong":[act("da102",que="$x",a="$"+q,ok=0),"c102_no_$%s_$%s"%(q,w),resta(lambda n:act("hojas",n=n))]+X}]
s102={"id":"lee-y-escribe","title":"Lee y escribe","place":"La casa, un día entero","scene":"sala_dia","next":"el-telefono",
 "goal":"Give each child what abuela says he does now (the book to read, a sheet of paper to write) so that Carmen's pad keeps its three clean sheets for the big frog she draws at the end: a sheet given to a reader flies out of the window as a paper plane, and a book given to a writer gets written in, so Carmen tears a clean sheet out to cover the page.",
 "stake":{"thing":"hojas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["libro","papel","lee","escribe"],"formas_foco":{"lee":["leo"],"escribe":["escribo"]},
 "back_again":["me llamo","¿cómo te llamas?","nombre","bonito","me gusta","mira","ahora","yo","mi","después","para","ventana","no","sí"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"tarde"}},act("hojas",n=5)]+juntos(act("llega",quien="luis",a="cojin1"),act("llega",quien="carmen",a="cojin2"),act("llega",quien="abuela",a="estante"),act("ir",a="mesa_coqui"))+[{"wait":500},
  # 1: abuela lays a book on the table (no act named); signed ask on the book (abuela's own line is the ask): the frog pushes it to Luis, who reads
  {"dots":1},ask("libro","c102_ab_libro",after=[act("lee102",quien="luis")]),"c102_ab_lee_luis",
  # 2: abuela lays the pad on the table (no act named); signed ask on the pad: the frog pulls a sheet to Carmen, who writes; a speaking turn (me llamo); she writes the frog's name under her own
  {"dots":2},ask("papel","c102_ab_papel",after=[act("escribe102",quien="carmen"),act("hojas",n=4)]),"c102_ab_escribe_carmen","c102_ca_nombre","c102_cq_llamo",act("nombres102"),
  # 3: Luis writes (a sheet to him); Carmen will read; signed ask on the book: the frog pushes it to Carmen
  {"dots":3},"c102_l_yo_escribo",act("escribe102",quien="luis"),act("hojas",n=3),"c102_ca_yo_leo",ask("libro","c102_donde_libro",after=[act("lee102",quien="carmen")]),"c102_ab_luis_carmen",
  # 4: Carmen counts the three clean sheets and draws a very small frog in the corner of the top one
  {"dots":4},act("cuenta102"),"c102_ca_para_ti",
  # 5: the turn: abuela goes to the kitchen's door, her hands white with flour; the book and the pad lie between the children, the window is open (no act named); the card shows two places
  {"dots":5},act("llega",quien="abuela",a="cocina"),gesto("abuela","harina"),CARD,{"wait":400},
  # 6: A. 7: B. Each drawn afresh
  {"dots":6}]+ronda102("a")+[{"dots":7}]+ronda102("b"),
 "final":[{"dots":8},baja3(lambda n:act("final102",n=n)),   # 8: Carmen draws on the clean sheets left (three: a frog as big as the table; two: as big as the frog; one: a small frog)
  {"dots":9},"c102_ca_te_gusta","c102_cq_bonito","c102_fin",act("fin")],   # 9: she holds it up (no act named); a speaking turn (bonito)
 "leer":["c102_ab_libro","c102_ab_lee_luis","c102_ab_papel","c102_ab_escribe_carmen","c102_ca_nombre","c102_cq_llamo","c102_l_yo_escribo","c102_ca_yo_leo","c102_donde_libro","c102_ab_luis_carmen","c102_ca_para_ti",
  "c102_ahora_luis_lee","c102_ahora_carmen_escribe","c102_ca_te_gusta","c102_cq_bonito","c102_fin"]}
s102=reuse(s102,{"c102_cq_llamo":TG(("me llamo",["me llamo coquí","me llamo coqui","coquí"])),"c102_cq_bonito":TG(("bonito",["qué bonito","bonito","muy bonito"]))})
json.dump(s102,open("cuentos/lee-y-escribe.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 103. El teléfono ----------------
# Abuela is in the kitchen; the frog is on the armchair's arm with the telephone, beside abuelo's head. Carmen says what abuelo does now (drawn, each round on its own): "Ahora abuelo escucha." / "Ahora abuelo habla."
# Decision A and B: touch a place (abuelo's ear, abuelo's mouth; tests escucha against habla). A miss: the telephone at the wrong end, the call runs on and nobody hears anybody; a bar of the battery blinks and goes.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c103_ab_telefono":AB("¡El teléfono! Coquí, por favor."),"c103_ab_llama":AB("Llama mamá. ¡Hola!"),"c103_ma_hola":MA("¡Hola! ¿Cómo estás?"),"c103_ab_escucho":AB("Yo escucho... y ahora hablo. Bien, gracias."),
 "c103_abo_quien":ABO("¿Quién llama?"),"c103_ab_oreja":AB("Llama mamá por teléfono. Abuelo escucha."),"c103_l_escucha_mama":L("Abuelo escucha a mamá."),"c103_ahora_habla":CA("Ahora abuelo habla."),"c103_abo_hola":ABO("¡Hola! Yo estoy bien."),"c103_ab_habla_con":AB("Abuelo habla con mamá."),
 "c103_ma_coqui":MA("¿Y Coquí? ¿Cómo estás, Coquí?"),"c103_cq_bien":T("¡Bien, gracias!"),
 "c103_ahora_escucha":CA("Ahora abuelo escucha."),"c103_no_escucha":CA("¡No, Coquí! Abuelo escucha."),"c103_no_habla":CA("¡No, Coquí! Abuelo habla."),
 "c103_ma_hola_hola":{"who":"narr","habla":"mama","text":"¿Hola? ¿Hola?"},
 "c103_ma_hasta_luego":MA("¡Hasta luego, Coquí!"),"c103_cq_hasta_manana":T("¡Hasta mañana!"),"c103_fin":N("Mamá llama por teléfono. Abuelo escucha, y habla. Y Coquí también.")})
DIN.update(["c103_ahora_habla","c103_ahora_escucha","c103_no_escucha","c103_no_habla"])
VARS103={"wa":["escucha","habla"],"wb":["escucha","habla"]}
def ronda103(s):
    # w: what abuelo does (drawn), p: the right place (his ear to listen, his mouth to talk). Right: the pictures go in or come out; for escucha he nods. Wrong: the other place (x), then (when he should talk) mamá's small voice, the line, a bar goes, the cross.
    w,p="w"+s,"p"+s
    return [{"draw":w,"options":["escucha","habla"]},{"calc":p,"cond":w+"=escucha","then":"oreja_abuelo","else":"boca_abuelo"},
     {"decide":"do","options":["oreja_abuelo","boca_abuelo"],"pick":"$"+p,"tests":"$"+w,"lock":True,"lead":[],"line":"c103_ahora_$"+w,
      "right":[act("pone103",donde="$"+p,ok=1),{"if":w+"=escucha","then":[gesto("abuelo","si")]},star],
      "wrong":[{"if":w+"=habla","then":con(act("pone103",donde="$x",ok=0),"c103_ma_hola_hola"),"else":[act("pone103",donde="$x",ok=0)]},"c103_no_$"+w,resta(lambda n:act("bateria",n=n))]+X}]
s103={"id":"el-telefono","title":"El teléfono","place":"La casa, un día entero","scene":"sala_dia","next":"por-la-tarde",
 "goal":"Hold the telephone to abuelo's ear when carmen says he listens and before his mouth when she says he talks, so that its battery keeps its three bars for the frog's song at the end: held the wrong way the call runs on and nobody hears anybody, and a bar blinks and goes.",
 "stake":{"thing":"bateria","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["teléfono","llama","habla","escucha"],"formas_foco":{"escucha":["escucho"]},
 "back_again":["mamá","abuelo","oreja","boca","hola","bien","¿cómo estás?","hablo","hasta luego","hasta mañana","pone","ahora","yo","con","por favor","gracias","no","sí"],
 "also_heard":["quién"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"tarde"}},act("bateria",n=3)]+juntos(act("llega",quien="abuelo",a="butaca"),act("llega",quien="luis",a="cojin1"),act("llega",quien="carmen",a="cojin2"),act("llega",quien="abuela",a="ventana_abuela"),act("ir",a="brazo_coqui"))+[{"wait":500},
  # 1: the telephone rings; signed ask on it (abuela's own line is the ask): the frog carries it to abuela (no act named)
  {"dots":1},act("suena103"),ask("telefono","c103_ab_telefono"),"c103_ab_llama",
  # 2: mamá speaks; abuela holds the telephone to her ear and then before her mouth
  {"dots":2},"c103_ma_hola",act("oido103",quien="abuela"),act("boca103",quien="abuela"),"c103_ab_escucho",
  # 3: abuelo wakes and cups a hand behind his ear; signed ask on his ear (the line is the ask): the telephone at his ear, mamá's voice as small pictures (abuelo smiles: no act named); signed ask on his mouth: the telephone before it
  {"dots":3},gesto("abuelo","oreja"),"c103_abo_quien",ask("oreja_abuelo","c103_ab_oreja",after=[act("pone103",donde="oreja_abuelo",ok=1)]),"c103_l_escucha_mama",
  ask("boca_abuelo","c103_ahora_habla",after=[act("pone103",donde="boca_abuelo",ok=1)]),"c103_abo_hola","c103_ab_habla_con",
  # 4: mamá asks for the frog; a speaking turn (bien); the frog opens his mouth to sing and abuela lays a finger on her lips; the battery shows three bars
  {"dots":4},"c103_ma_coqui","c103_cq_bien",act("anillos103"),gesto("abuela","silencio"),act("bateria",n=3),
  # 5: the turn: abuela goes to the kitchen; the frog is on the armchair's arm with the telephone, beside abuelo's head; the card shows two places
  {"dots":5},act("llega",quien="abuela",a="cocina"),act("ir",a="brazo_coqui"),CARD,{"wait":400},
  # 6: A. 7: B. Each drawn afresh
  {"dots":6}]+ronda103("a")+[{"dots":7}]+ronda103("b"),
 "final":[{"dots":8},"c103_ma_hasta_luego","c103_cq_hasta_manana",baja3(lambda n:act("final103",n=n)),   # 8: abuelo holds the telephone out (no act named); a speaking turn (hasta mañana); the frog sings into it, by the bars left
  {"dots":9},"c103_fin",act("fin")],
 "leer":["c103_ab_telefono","c103_ab_llama","c103_ma_hola","c103_ab_escucho","c103_abo_quien","c103_ab_oreja","c103_l_escucha_mama","c103_ahora_habla","c103_abo_hola","c103_ab_habla_con","c103_ma_coqui","c103_cq_bien",
  "c103_ahora_escucha","c103_ahora_habla","c103_ma_hasta_luego","c103_cq_hasta_manana","c103_fin"]}
s103=reuse(s103,{"c103_cq_bien":TG(("bien",["bien","muy bien","bien gracias"])),"c103_cq_hasta_manana":TG(("hasta mañana",["hasta mañana","hasta manana"]))})
json.dump(s103,open("cuentos/el-telefono.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 104. Por la tarde ----------------
# Carmen holds a photo (people of the house indoors, reading, writing or playing: nothing of the time of day) and says when it happens and who does what: "Por la tarde, abuelo lee."; one round is la tarde, the other la mañana or la noche.
# Decision A and B: touch a page (the morning's, the afternoon's, the night's; tests la tarde against la mañana and la noche). A miss: the photo is stuck on the wrong page, peeled off, its corner tears and a gold star goes on the tear.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c104_ab_tres":AB("Son las tres de la tarde. Luis estudia."),"c104_donde_compu":N("Luis estudia en la computadora. ¿Dónde está?"),"c104_ca_mira":CA("Mira, Coquí: mi día. La mañana, la tarde y la noche."),
 "c104_donde_tarde":N("¿Dónde está la tarde?"),"c104_ca_tarde_luis":CA("Por la tarde, Luis estudia."),"c104_ca_noche_abuela":CA("Por la noche, abuela lee."),
 "c104_ca_aveces":CA("A veces Luis estudia en la computadora. A veces estudia con un libro."),"c104_ab_aveces":AB("A veces, Luis. Ahora no."),"c104_ca_estrellas":CA("Coquí, ¿dónde están mis estrellas?"),"c104_cq_aqui":T("¡Aquí!"),
 "c104_ca_dia":CA("Este es mi día. ¿Te gusta, Coquí?"),"c104_cq_gusta":T("¡Sí, me gusta!"),"c104_fin":N("Por la tarde Luis estudia. A veces en la computadora, a veces con un libro.")})
TIEMPO={"tarde":"la tarde","manana":"la mañana","noche":"la noche"}
PHOTOS={"abuelo_lee":"abuelo lee","abuela_escribe":"abuela escribe","carmen_juega":"Carmen juega","luis_lee":"Luis lee","abuela_juega":"abuela juega"}
for t,w in TIEMPO.items():
    c["c104_no_%s"%t]=CA("No, Coquí. Por %s."%w); DIN.add("c104_no_%s"%t)
    for f,x in PHOTOS.items(): c["c104_%s_%s"%(t,f)]=CA("Por %s, %s."%(w,x)); DIN.add("c104_%s_%s"%(t,f))
VARS104={"ta":list(TIEMPO),"tb":list(TIEMPO),"fa":list(PHOTOS),"fb":list(PHOTOS)}
def ronda104(s,t,f):
    # t: the time of day of this round (tarde, manana, noche), f: the photo (dealt out), p: the right page. Right: the photo stays. Wrong: stuck on the page he touched (x), peeled off and torn, a star goes on the tear, the cross.
    p="p"+s
    return [{"calc":p,"cond":t+"=tarde","then":"pagina2","else":"pagina1"},{"calc":p,"cond":t+"=noche","then":"pagina3","else":"$"+p},act("foto104",que="$"+f),
     {"decide":"do","options":["pagina1","pagina2","pagina3"],"pick":"$"+p,"tests":"$"+t,"lock":True,"lead":[],"line":"c104_$%s_$%s"%(t,f),
      "right":[act("pega104",pagina="$"+p,ok=1),star],
      "wrong":con(act("pega104",pagina="$x",ok=0),"c104_no_$"+t)+[resta(lambda n:act("estrellas",n=n))]+X}]
s104={"id":"por-la-tarde","title":"Por la tarde","place":"La casa, un día entero","scene":"sala_dia","next":"prende-y-apaga",
 "goal":"Stick each photo Carmen holds on the album's page for the time of day she says (the morning, the afternoon or the night) so that her three gold stars stay in the box for the cover, round the frog's photo: a photo on the wrong page is peeled off, its corner tears, and a star goes on the tear.",
 "stake":{"thing":"estrellas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["estudia","computadora","la tarde","a veces"],"formas_foco":{},
 "back_again":["la mañana","noche","son las","tres","lee","escribe","libro","juega","bola","día","me gusta","aquí","pone","mira","con","mi","yo","no","sí"],
 "also_heard":[],"names":nm,"palabras":{"tarde":"la tarde","manana":"la mañana","noche":"noche"},"clips":c,
 "beats":[{"set":{"hora":"tarde"}},act("estrellas",n=3)]+juntos(act("llega",quien="luis",a="escritorio"),act("llega",quien="carmen",a="cojin2"),act("ir",a="mesa_coqui"))+[{"wait":500},
  # 1: abuela says the time and that Luis studies (the clock shows three: no act named); signed ask on the computer: its screen lights up (Luis looks from the screen to his notebook and writes: no act named)
  {"dots":1},"c104_ab_tres",ask("computadora","c104_donde_compu",after=[act("pantalla104")]),
  # 2: Carmen opens her album (no act named): the three pages glow, she names them; signed ask on the afternoon's page: it glows
  {"dots":2},act("pagina104",n=1),act("pagina104",n=2),act("pagina104",n=3),"c104_ca_mira",ask("pagina2","c104_donde_tarde",after=[act("pagina104",n=2)]),
  # 3: a photo of Luis at the computer; signed ask on the afternoon's page (Carmen's own line is the ask): the frog sticks it on; a photo of abuela with a book: the frog sticks it on the page with the moon
  {"dots":3},act("foto104",que="luis_computadora"),ask("pagina2","c104_ca_tarde_luis",after=[act("pega104",pagina="pagina2",ok=1)]),
  act("foto104",que="abuela_libro"),"c104_ca_noche_abuela",act("pega104",pagina="pagina3",ok=1),
  # 4: two small pictures change places over Luis; he shuts the notebook and picks up his ball (no act named), looks at abuela; the stars are in the box under the frog's foot; a speaking turn (aquí); she holds the stars against the cover and puts them back (no act named)
  {"dots":4}]+con(act("aveces104"),"c104_ca_aveces")+[gesto("luis","mira",a="abuela"),"c104_ab_aveces","c104_ca_estrellas","c104_cq_aqui",
  # 5: the turn: Carmen takes more photos out of her box, the album lies open at its three pages (no act named); the card shows two places. Which round is the afternoon (ra), the other round's time (om) and the two photos are drawn here
  {"dots":5},CARD,{"draw":"ra","options":["a","b"]},{"draw":"om","options":["manana","noche"]},{"calc":"ta","cond":"ra=a","then":"tarde","else":"$om"},{"calc":"tb","cond":"ra=a","then":"$om","else":"tarde"},
  {"reparte":["fa","fb"],"options":list(PHOTOS)},{"wait":400},
  # 6: A. 7: B
  {"dots":6}]+ronda104("a","ta","fa")+[{"dots":7}]+ronda104("b","tb","fb"),
 "final":[{"dots":8},baja3(lambda n:act("final104",n=n)),   # 8: Carmen shuts the album and sticks the stars that are left on its cover, round the frog's photo
  {"dots":9},"c104_ca_dia","c104_cq_gusta","c104_fin",act("fin")],
 "leer":["c104_ab_tres","c104_donde_compu","c104_ca_mira","c104_donde_tarde","c104_ca_tarde_luis","c104_ca_noche_abuela","c104_ca_aveces","c104_ab_aveces","c104_ca_estrellas","c104_cq_aqui",
  "c104_tarde_abuelo_lee","c104_manana_abuela_escribe","c104_ca_dia","c104_cq_gusta","c104_fin"]}
s104=reuse(s104,{"c104_cq_aqui":TG(("aquí",["aquí","aquí están"])),"c104_cq_gusta":TG(("me gusta",["me gusta","sí me gusta"]))})
json.dump(s104,open("cuentos/por-la-tarde.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files on disk, and the earlier stories of this run). None of this scene's turns is on a word of another story of place 9.
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s102,s103,s104):
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in EARLIER: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    EARLIER.update(st["focus_words"])
# every clip id the steps name (with no variable in it) is in the story's clips; an id put together from variables: for every value its variables can take; every `leer` id and every `names` clip too
def refs(o):   # the clip ids a list of steps names: bare strings of the step lists, and the `line` / `say` / `bien` of a step
    if isinstance(o,str): yield o
    elif isinstance(o,list):
        for x in o: yield from refs(x)
    elif isinstance(o,dict):
        if "calc" in o or "draw" in o or "reparte" in o: return   # a calc's then / else are values, not steps
        for k in ("lead","after","then","else","right","wrong"):
            if k in o: yield from refs(o[k])
        for k in ("line","say","bien"):
            if isinstance(o.get(k),str): yield o[k]
for st,VARS in ((s102,VARS102),(s103,VARS103),(s104,VARS104)):
    for i in sorted(set(refs([st["beats"],st["final"]]))):
        if "$" in i:   # a built id: every value its variables can take must be a clip
            combos=[i]
            for v in dict.fromkeys(re.findall(r"\$([a-z]+)",i)): combos=[x.replace("$"+v,val) for x in combos for val in VARS.get(v,["?"+v])]
            for x in combos:
                if x not in st["clips"]: print("MISSING BUILT CLIP",st["id"],i,x)
        elif i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for k,v in st["names"].items():
        if v not in st["clips"]: print("MISSING NAME",st["id"],k,v)
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
# clip ids are global: the same id must have the same text everywhere
seen={}; clash=0; new=0; chars=0
for f in sorted(glob.glob("cuentos/*.json")):
    if "zz-" in f or "/z" in f: continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items():
        key=(cl.get("who"),cl.get("text"))
        if cid in seen and seen[cid]!=key: print("CLASH",cid,seen[cid],key,f); clash+=1
        seen.setdefault(cid,key)
for cid,(who,text) in seen.items():
    if not os.path.exists(f"audio/{cid}.mp3"): new+=1; chars+=len(text)
print(len(seen),"clips,",new,"new,",chars,"characters to record,",clash,"clashes")
