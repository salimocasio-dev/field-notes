# El cuarto (place 9, La casa un día entero, scene 1 of 4): stories 96, 97, 98. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/cuarto.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `cuarto` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: this one first (each generator sees only what was recorded before it: places 1 to 8 must be on disk; gen_mostrador ... gen_cuenta). The speaking turns of this scene are all on words of places 1 to 8
#   (buenos días: El colmado; sí: La casa; son las: El reloj; despacio: El parque; camisa: La playa; rápido: El parque): no word of a later story of La casa un día entero is used.
#
# Where the script or its Needs list leaves a value open, this file fixes it in ONE place (and the report says so):
#   States: every story sets its own at the start (every story starts fresh): hora, luz, cuna, butaca. 96 alba, luz 0, no cradle, no armchair; 97 manana, luz 0, cradle and armchair; 98 manana, luz 0, neither.
#       (`luz` in the two morning stories: the script does not say; 0.) The Start's places are issued with `llega` (all started together: `juntos`) and `ir`, the spots the Needs list names for them.
#   `stake.thing` is the stake without its story's number, as gen_entrada's `mesas`: plato (act plato96), zetas (act zetas), pelo (act pelo98). `n` of plato96 / zetas / pelo98 / final96 / final97 / final98 is the steps of the stake left: 3, 2, 1 (the other scenes' baja3).
#   96 `busca96` {donde, que, ok}: donde = cama, almohada or silla (the same keys as the things touched, so a wrong touch `$x` goes in as it is); que = camisa (round A) or zapatos (round B). Round B's place is not round A's (a nested `if`, as gen_entrada's `otro`).
#   96 the wrong move runs in the order of the script: the frog's act (nothing found, Canelo takes a piece), the correction line, the plate's count (plato96), then the cross and one step (X).
#   97 `campana97` / `manta97` {quien, ok}: quien = luis (round A), abuelo (round B), carmen (the opening); ok 1 = the right effect, ok 0 = the noise (bell: he stays sitting and abuela calls again; blanket: he stands, cold, howls).
#       The round's thing keys: campana and manta_luis (A) / manta_abuelo (B). Each round draws on its own (despierta, levanta): the two may be the same. `reloj97` {hora}: 7, then 7.5. `final97` {n}: the Z's left; the baby's three fates and the tiptoe out are taken as part of it.
#   97 step 8: `corre97` is ONE act (Luis runs, stops, goes on tiptoe): started loose with the turn line, `ya` after it (`con`).
#   98 `silla98` {a, b} takes clothing keys (pantalon, zapatos / camisa, zapatos / sombrero, reloj); `ropa_a` is the thing at a, `ropa_b` the thing at b (the script's "two things on the chair"). The opening's chair holds the trousers (a) and the shoes (b):
#       the signed ask of step 2 is on the trousers, which the Needs list has no key for: taken as ropa_a. `viste98` {cual, ok}: cual = ropa_a or ropa_b (the thing pushed over: the right one, or on a wrong touch `$x`).
#   98 `zapatos98` is ONE act in the Needs list for the two halves of step 2 (the fall; after the touch, the shoes off, the trousers on, the shoes on): called twice, with no argument.
#   98 the wrong move: `viste98` with ok 0 carries the other first AND Carmen making him take it off and put both on again; started loose with her correction line (`con`); the correction line names the thing that goes FIRST
#       (the script's one example is "¡No! Primero la camisa."; the other three, and the one for each draw where the named thing goes afterwards, follow it).
#   Beats with no act named in Needs are left out (and listed in the report): nothing is invented.
import json,glob,os,re,collections,unicodedata
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time: all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
MINE=("buenos-dias","a-las-siete","se-viste")             # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c96_busca_$da"): never renamed
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
# What he hears when he pokes a person already recorded (the baby, the dog and abuelo are recorded in earlier places)
NM={"abuela":("abuela",N("Esta es abuela.")),"abuelo":("n_abuelo",N("Este es abuelo.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "perro":("c_n_perro",N("Es el perro. Se llama Canelo.")),"bebe":("n_bebe",N("Este es el bebé."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}
def otro(out,inv,e,opts):
    # out = the e-th (1 to len-1) of the options that are not `inv`: a second value that is never the first
    def rama(v):
        o=[x for x in opts if x!=v]
        return [{"calc":out,"cond":e+"=1","then":o[0],"else":o[1]}]+[{"calc":out,"cond":"%s=%d"%(e,i+1),"then":o[i],"else":"$"+out} for i in range(2,len(o))]
    ch=rama(opts[-1])
    for v in reversed(opts[:-1]): ch=[{"if":inv+"="+v,"then":rama(v),"else":ch}]
    return ch

# ---------------- 96. Buenos días ----------------
# Something of Luis's is lost (round A his shirt, round B his shoes); it lies out of sight near the bed, the big pillow or the chair. Carmen, from her bed, says where to look (drawn; round B's place is not round A's).
# A miss: the frog looks, nothing there, Canelo's nose goes up over the plate and a piece of bread is gone; the sign shows the right place.
PL=["cama","almohada","silla"]; PLN={"cama":"la cama","almohada":"la almohada","silla":"la silla"}
nm,nc=nombres("abuela","luis","carmen","perro","coqui"); c=dict(comunes); c.update(nc)
c.update({"c96_ab_buenos":AB("Buenos días, Coquí. Mira: el cuarto de Luis y Carmen. Luis duerme en la cama."),"c96_donde_cama":N("¿Dónde está la cama de Luis?"),"c96_l_no":L("No... Tengo sueño."),
 "c96_ab_luz":AB("Luis tiene sueño. Coquí, la luz, por favor."),"c96_l_luz_no":L("¡No! ¡La luz no!"),"c96_ca_ay":CA("¡Ay, la luz! ¡Hola, Coquí!"),"c96_cq_dias":T("¡Buenos días!"),
 "c96_ca_toma":CA("¡Luis, toma mi almohada!"),"c96_l_no_quiero":L("¡Ay! ¡No quiero tu almohada!"),"c96_donde_almohada":N("¿Dónde está la almohada de Carmen?"),"c96_l_camisa":L("¿Dónde está mi camisa?"),
 "c96_ca_se":CA("Yo sé dónde está. Yo tengo sueño... Busca tú, Coquí."),"c96_ab_cuarto":AB("¡Este cuarto! Vengo ahora."),
 "c96_l_zapatos":L("¿Y mis zapatos?"),"c96_l_gracias_camisa":L("¡Mi camisa! Gracias, Coquí."),"c96_l_gracias_zapatos":L("¡Mis zapatos! Gracias."),
 "c96_ab_tienes":AB("¿Y tú, Coquí? ¿Tienes sueño?"),"c96_cq_si":T("¡Sí!"),"c96_fin":N("Coquí tiene sueño. Duerme en la almohada.")})
for p in PL:   # Carmen says where to look; and the correction for each place
    c["c96_busca_%s"%p]=CA("Busca cerca de %s."%PLN[p]); c["c96_no_%s"%p]=CA("No, Coquí. Cerca de %s."%PLN[p]); DIN.update(["c96_busca_%s"%p,"c96_no_%s"%p])
VARS96={"da":PL,"db":PL}
def ronda96(d,sorteo,que,pregunta,gracias):
    # d: the place Carmen says (drawn). Right: the frog pulls the thing out, Luis thanks him. Wrong: he looks where he touched (nothing there, Canelo takes a piece), Carmen says it again, the plate's count, the cross.
    return sorteo+[pregunta,
     {"decide":"do","options":PL,"pick":"$"+d,"tests":"$"+d,"lock":True,"lead":[],"line":"c96_busca_$"+d,
      "right":[act("busca96",donde="$"+d,que=que,ok=1),gracias,star],
      "wrong":[act("busca96",donde="$x",que=que,ok=0),"c96_no_$"+d,resta(lambda n:act("plato96",n=n))]+X}]
s96={"id":"buenos-dias","title":"Buenos días","place":"La casa, un día entero","scene":"cuarto","next":"a-las-siete",
 "goal":"Find Luis's lost shirt and shoes by looking near the bed, the big pillow or the chair, where Carmen says, so that the three pieces of bread abuela set on the night table are still there for Luis: every wrong place lets Canelo take one.",
 "stake":{"thing":"plato","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["cuarto","cama","almohada","luz","tiene sueño"],"formas_foco":{"tiene sueño":["tengo sueño","tienes sueño"]},
 "back_again":["buenos días","hola","busca","cerca","silla","camisa","zapatos","duerme","perro","quiero","mira","¿dónde está?","mi","tu","yo","tú","no","sí","gracias","por favor","ahora","viene"],
 "also_heard":[],"names":nm,"palabras":{"cama":"cama","almohada":"almohada","silla":"silla"},"clips":c,
 "beats":[{"set":{"hora":"alba","luz":0,"cuna":0,"butaca":0}},act("plato96",n=3)]
  +juntos(act("llega",quien="luis",a="cama_luis"),act("llega",quien="carmen",a="cama_carmen"),act("llega",quien="abuela",a="puerta"),act("llega",quien="perro",a="bajo_cama"))+[act("ir",a="alfombra"),{"wait":500},
  # 1: abuela names the room; signed ask on Luis's bed: the frog hops onto it ("Luis groans and pulls the blanket over his head": no act named)
  {"dots":1},"c96_ab_buenos",ask("cama","c96_donde_cama",after=[act("ir",a="cama_coqui")]),"c96_l_no",
  # 2: the signed ask is abuela's own line, on the wall light's switch: the room is bright; Carmen sits up in her bed; a speaking turn (buenos días)
  {"dots":2},ask("luz","c96_ab_luz",after=[act("luz96",on=1)]),"c96_l_luz_no",act("llega",quien="carmen",a="sentado_carmen"),"c96_ca_ay","c96_cq_dias",
  # 3: Carmen throws her big pillow; signed ask on it on the floor: the frog bounces on it; Luis sits up and feels about with his hands
  {"dots":3},act("almohada96"),"c96_ca_toma","c96_l_no_quiero",ask("almohada","c96_donde_almohada",after=[act("ir",a="almohada_suelo")]),act("llega",quien="luis",a="sentado_luis"),gesto("luis","palpa"),"c96_l_camisa",
  # 4: Carmen lies back; abuela shakes her head and goes
  {"dots":4},"c96_ca_se",act("llega",quien="carmen",a="cama_carmen"),gesto("abuela","no"),"c96_ab_cuarto",act("sale",quien="abuela"),
  # 5: the turn: Canelo comes out from under the bed and sits by the night table; the card shows two places
  {"dots":5},act("llega",quien="perro",a="junto_mesita"),CARD,{"wait":400},
  # 6: A (his shirt; the place drawn). 7: B (his shoes; another place). Each drawn afresh
  {"dots":6}]+ronda96("da",[{"draw":"da","options":PL}],"camisa","c96_l_camisa","c96_l_gracias_camisa")
  +[{"dots":7}]+ronda96("db",[{"draw":"gb","options":["1","2"]}]+otro("db","da","gb",PL),"zapatos","c96_l_zapatos","c96_l_gracias_zapatos"),
 "final":[{"dots":8},baja3(lambda n:act("final96",n=n)),   # 8: Luis sits down on his bed with the plate; the bread left decides the last picture
  {"dots":9},act("llega",quien="abuela",a="puerta"),"c96_ab_tienes","c96_cq_si",act("duerme96"),"c96_fin",act("fin")],
 "leer":["c96_ab_buenos","c96_donde_cama","c96_l_no","c96_ab_luz","c96_l_luz_no","c96_ca_ay","c96_cq_dias","c96_ca_toma","c96_l_no_quiero","c96_donde_almohada","c96_l_camisa","c96_ca_se","c96_ab_cuarto",
  "c96_busca_almohada","c96_l_gracias_camisa","c96_l_zapatos","c96_busca_cama","c96_l_gracias_zapatos","c96_ab_tienes","c96_cq_si","c96_fin"]}
s96=reuse(s96,{"c96_cq_dias":TG(("buenos días",["buenos días","buenos dias"])),"c96_cq_si":TG(("sí",["sí","si"]))})
json.dump(s96,open("cuentos/buenos-dias.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 97. A las siete ----------------
# Abuela calls from the kitchen what a sleeper does now: he wakes, or he gets up (drawn, each round on its own: the two rounds may be the same). Round A is Luis in his bed, round B abuelo in the armchair.
# The bell always wakes a sleeper (he sits up); the blanket always gets him up (he stands, cold). A miss: the other thing is done and makes a noise, abuela says it again, a Z pops over the cradle; the sign shows the right thing.
nm,nc=nombres("abuela","abuelo","luis","carmen","bebe","coqui"); c=dict(comunes); c.update(nc)
c.update({"c97_ab_shh":AB("Shh. El bebé duerme. Despacio, Coquí."),"c97_donde_reloj":N("¿Dónde está el reloj, Coquí?"),"c97_ab_siete":AB("Son las siete de la mañana."),
 "c97_ab_carmen_despierta":AB("A las siete, Carmen se despierta."),"c97_ca_mmm":CA("Mmm. Buenos días."),"c97_ab_carmen_levanta":AB("Ahora Carmen se levanta."),"c97_ca_ya":CA("¡Ya me levanto!"),
 "c97_ab_que_hora":AB("Luis duerme. ¿Qué hora es, Coquí?"),"c97_cq_son_las":T("Son las siete."),"c97_ab_luis_despierta":AB("Sí. A las siete Luis se despierta."),"c97_ab_y_media":AB("Y a las siete y media se levanta."),
 "c97_ca_yo":CA("Luis se despierta. Yo me levanto."),"c97_cq_despacio":T("¡Despacio, Luis!"),
 "c97_fin":N("Son las siete y media de la mañana. Luis y Carmen se levantan.")})
for s,quien in (("a","Luis"),("b","abuelo")):   # what she calls in each round
    c["c97_%s_despierta"%s]=AB("¡Coquí! Ahora %s se despierta."%quien); c["c97_%s_levanta"%s]=AB("¡Coquí! Ahora %s se levanta."%quien); DIN.update(["c97_%s_despierta"%s,"c97_%s_levanta"%s])
c["c97_no_despierta"]=AB("¡No, Coquí! ¡Se despierta!"); c["c97_no_levanta"]=AB("¡No, Coquí! ¡Se levanta!"); DIN.update(["c97_no_despierta","c97_no_levanta"])
VARS97={"da":["despierta","levanta"],"db":["despierta","levanta"]}
def ronda97(s,quien,manta):
    # d: what she calls (despierta, levanta); k: the right thing (the bell wakes, the blanket gets up). Wrong: the other thing, with its noise (ok 0).
    d,k="d"+s,"k"+s
    return [{"draw":d,"options":["despierta","levanta"]},{"calc":k,"cond":d+"=despierta","then":"campana","else":manta},
     {"decide":"do","options":["campana",manta],"pick":"$"+k,"tests":"$"+d,"lock":True,"lead":[],"line":"c97_%s_$%s"%(s,d),
      "right":[{"if":d+"=despierta","then":[act("campana97",quien=quien,ok=1)],"else":[act("manta97",quien=quien,ok=1)]},star],
      "wrong":[{"if":d+"=despierta","then":[act("manta97",quien=quien,ok=0)],"else":[act("campana97",quien=quien,ok=0)]},"c97_no_$"+d,resta(lambda n:act("zetas",n=n))]+X}]
s97={"id":"a-las-siete","title":"A las siete","place":"La casa, un día entero","scene":"cuarto","next":"se-viste",
 "goal":"Wake or get up each sleeper the way abuela calls from the kitchen (the little bell wakes him, the blanket pulled off gets him up) so that the baby in the cradle keeps its three Z's of sleep: every mix-up makes a noise, and a Z pops.",
 "stake":{"thing":"zetas","steps":3},"dots":10,"bien":"si_muy_bien",
 "focus_words":["se despierta","se levanta","la mañana","a las siete"],"formas_foco":{"se levanta":["me levanto","se levantan"]},
 "back_again":["cuarto","cama","tiene sueño","bebé","duerme","despacio","reloj","¿qué hora es?","son las","y media","siete","toca","ahora","ya","buenos días","no","sí"],
 "also_heard":[],"names":nm,"palabras":{"despierta":"se despierta","levanta":"se levanta"},"clips":c,
 "beats":[{"set":{"hora":"manana","luz":0,"cuna":1,"butaca":1}},act("reloj97",hora=7),act("zetas",n=3)]
  +juntos(act("llega",quien="luis",a="cama_luis"),act("llega",quien="carmen",a="cama_carmen"),act("llega",quien="abuelo",a="butaca_abuelo"),act("llega",quien="abuela",a="puerta"))+[act("ir",a="mesita_coqui"),{"wait":500},
  # 1: abuela: a finger to her lips, points at the cradle; signed ask on the clock (it ticks: no act named)
  {"dots":1},gesto("abuela","silencio"),gesto("abuela","senala",a="cuna"),"c97_ab_shh",ask("reloj","c97_donde_reloj"),"c97_ab_siete",
  # 2: the signed ask is abuela's own line, on the bell: Carmen wakes and sits up
  {"dots":2},ask("campana","c97_ab_carmen_despierta",after=[act("campana97",quien="carmen",ok=1)]),"c97_ca_mmm",
  # 3: the signed ask is abuela's own line, on Carmen's blanket: the frog pulls it off, she stands up
  {"dots":3},ask("manta_carmen","c97_ab_carmen_levanta",after=[act("manta97",quien="carmen",ok=1)]),"c97_ca_ya",
  # 4: Luis snores (no act named); a speaking turn (son las); the frog rings the bell and Luis opens his eyes and shuts them again (no act named); Carmen points at her own two feet
  {"dots":4},"c97_ab_que_hora","c97_cq_son_las","c97_ab_luis_despierta","c97_ab_y_media",gesto("carmen","pies"),"c97_ca_yo",
  # 5: the turn: abuela goes to the kitchen on tiptoe; the card shows two places
  {"dots":5}]+juntos(gesto("abuela","puntillas"),act("sale",quien="abuela"))+[CARD,{"wait":400},
  # 6: A (Luis). 7: B (abuelo). What she calls: drawn afresh each round. 8: Luis runs for the door; a speaking turn (despacio); he stops and goes on tiptoe
  {"dots":6}]+ronda97("a","luis","manta_luis")+[{"dots":7}]+ronda97("b","abuelo","manta_abuelo")
  +[{"dots":8}]+con(act("corre97"),"c97_cq_despacio"),
 "final":[{"dots":9},act("reloj97",hora=7.5),act("llega",quien="abuela",a="puerta"),baja3(lambda n:act("final97",n=n)),   # 9: half past seven; abuela claps without a sound, all are on their feet; the Z's left decide what the baby does
  {"dots":10},"c97_fin",act("fin")],
 "leer":["c97_ab_shh","c97_donde_reloj","c97_ab_siete","c97_ab_carmen_despierta","c97_ca_mmm","c97_ab_carmen_levanta","c97_ca_ya","c97_ab_que_hora","c97_cq_son_las","c97_ab_luis_despierta","c97_ab_y_media","c97_ca_yo",
  "c97_a_despierta","c97_b_levanta","c97_cq_despacio","c97_fin"]}
s97=reuse(s97,{"c97_cq_son_las":TG(("son las",["son las siete"])),"c97_cq_despacio":TG(("despacio",["despacio","despacio luis"]))})
json.dump(s97,open("cuentos/a-las-siete.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 98. Se viste ----------------
# Two things lie on the chair (round A: the shirt and the shoes; round B: the hat and the watch). Carmen names one and says whether Luis puts it on first or afterwards (drawn, each round on its own). The frog pushes over the thing that goes on first.
# A miss: Luis puts the other on first; Carmen says what goes first and makes him take it off and put both on again in her order: a tuft of hair stands up (the second time: his shirt tail hangs out); the sign shows the right thing.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c98_ab_mira":AB("Mira, Coquí: la ropa de Luis está en la silla."),"c98_ab_viste":AB("Ahora Luis se viste."),"c98_ca_no":CA("¡No, Luis! Primero el pantalón, después los zapatos."),"c98_que_primero":N("¿Qué se pone Luis primero?"),
 "c98_ab_falta":AB("Luis se viste. ¿Qué falta, Coquí?"),"c98_cq_camisa":T("¡La camisa!"),"c98_ca_sim":CA("Sí. Primero la ropa, después la foto."),
 "c98_ab_listo":AB("¡Listo! ¡La guagua! ¡Vámonos!"),"c98_cq_rapido":T("¡Rápido, Luis!"),"c98_fin":N("Por la mañana Luis se viste: primero la ropa, después la escuela.")})
PR={"camisa":"la camisa","zapatos":"los zapatos","sombrero":"el sombrero","reloj":"el reloj"}   # each thing with its article, as the script writes them
for k,w in PR.items():
    c["c98_ca_primero_%s"%k]=CA("Primero Luis se pone %s."%w); c["c98_ca_despues_%s"%k]=CA("Luis se pone %s después."%w); c["c98_no_%s"%k]=CA("¡No! Primero %s."%w)
    DIN.update(["c98_ca_primero_%s"%k,"c98_ca_despues_%s"%k,"c98_no_%s"%k])
VARS98={"oa":["primero","despues"],"ob":["primero","despues"],"ca":["camisa","zapatos"],"cb":["sombrero","reloj"],"fa":["camisa","zapatos"],"fb":["sombrero","reloj"]}
def ronda98(s,A,B,antes):
    # c: the thing Carmen names (A at ropa_a, B at ropa_b); o: primero or despues; k: the thing named, u: the other; p: the thing that goes on first; f: its clothing name (for the correction)
    cc,o,k,u,p,f=[v+s for v in ("c","o","k","u","p","f")]
    return antes+[{"draw":cc,"options":[A,B]},{"draw":o,"options":["primero","despues"]},
     {"calc":k,"cond":cc+"="+A,"then":"ropa_a","else":"ropa_b"},{"calc":u,"cond":cc+"="+A,"then":"ropa_b","else":"ropa_a"},
     {"calc":p,"cond":o+"=primero","then":"$"+k,"else":"$"+u},{"calc":f,"cond":p+"=ropa_a","then":A,"else":B},
     {"decide":"do","options":["ropa_a","ropa_b"],"pick":"$"+p,"tests":"$"+o,"lock":True,"lead":[],"line":"c98_ca_$%s_$%s"%(o,cc),
      "right":[act("viste98",cual="$"+p,ok=1),star],
      "wrong":con(act("viste98",cual="$x",ok=0),"c98_no_$"+f)+[resta(lambda n:act("pelo98",n=n))]+X}]
s98={"id":"se-viste","title":"Se viste","place":"La casa, un día entero","scene":"cuarto","next":"limpio-y-sucio",
 "goal":"Help Luis dress in the order Carmen says, first or afterwards, so that he looks neat in abuela's photo for the first day of school: every thing put on out of turn has to come off and go on again, and it ruffles him, first a tuft of hair, then his shirt tail.",
 "stake":{"thing":"pelo","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["se viste","ropa","primero"],"formas_foco":{},
 "back_again":["después","se pone","camisa","pantalón","zapatos","sombrero","reloj","falta","cuarto","rápido","listo","guagua","escuela","mira","ahora","no","sí"],
 "also_heard":[],"names":nm,"palabras":{"primero":"primero","despues":"después"},"clips":c,
 "beats":[{"set":{"hora":"manana","luz":0,"cuna":0,"butaca":0}},act("pelo98",n=3),act("silla98",a="pantalon",b="zapatos")]
  +juntos(act("llega",quien="luis",a="vestir"),act("llega",quien="carmen",a="sentado_carmen"),act("llega",quien="abuela",a="puerta"))+[act("ir",a="alfombra"),{"wait":500},
  # 1: signed ask on the chair: the frog hops onto it
  {"dots":1},ask("silla","c98_ab_mira",after=[act("ir",a="silla_coqui")]),"c98_ab_viste",
  # 2: Luis pulls his shoes on, then his trousers stick, he falls onto the bed; Carmen laughs; signed ask on the trousers (the thing at a): the shoes come off, the trousers go on, then the shoes
  {"dots":2},act("zapatos98"),gesto("carmen","rie"),"c98_ca_no",ask("ropa_a","c98_que_primero",after=[act("zapatos98")]),
  # 3: Luis still has his pyjama top on; a speaking turn (camisa)
  {"dots":3},"c98_ab_falta","c98_cq_camisa","c98_ca_sim",
  # 4: the turn: abuela lifts her camera and lowers it, Luis takes his shoes off again (no act named); Carmen stands on her bed like a captain; the shirt and the shoes lie on the chair; the card shows two places
  {"dots":4},act("llega",quien="carmen",a="capitana"),act("silla98",a="camisa",b="zapatos"),CARD,{"wait":400},
  # 5: A (the shirt and the shoes). 6: B (the hat and the watch). The thing named, and first or afterwards: drawn afresh each round
  {"dots":5}]+ronda98("a","camisa","zapatos",[])+[{"dots":6}]+ronda98("b","sombrero","reloj",[act("silla98",a="sombrero",b="reloj")]),
 "final":[{"dots":7},act("llega",quien="abuela",a="foto"),baja3(lambda n:act("final98",n=n)),   # 7: abuela lifts her camera; a flash; the photo shows on its screen, by how neat he is
  {"dots":8},"c98_ab_listo","c98_cq_rapido","c98_fin",act("fin")],   # 8: the horn outside (no act named)
 "leer":["c98_ab_mira","c98_ab_viste","c98_ca_no","c98_que_primero","c98_ab_falta","c98_cq_camisa","c98_ca_sim","c98_ca_primero_camisa","c98_ca_despues_reloj","c98_ab_listo","c98_cq_rapido","c98_fin"]}
s98=reuse(s98,{"c98_cq_camisa":TG(("camisa",["la camisa","camisa"])),"c98_cq_rapido":TG(("rápido",["rápido","rapido"]))})
json.dump(s98,open("cuentos/se-viste.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files on disk, and the earlier stories of this run); places 1 to 8 must be on disk.
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s96,s97,s98):
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in EARLIER: print("TURN ON A WORD IN NO EARLIER FOCUS_WORDS",st["id"],cid,t["palabra"])
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
for st,VARS in ((s96,VARS96),(s97,VARS97),(s98,VARS98)):
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
