# El pedido (place 8, La fonda, scene 2 of 4): stories 87, 88, 89. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/pedido.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `pedido` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle).
# Run order for the place: any order among the four scenes of La fonda; every speaking turn's word comes from places 1 to 3 (the files of places 1 to 7 must be on disk first: gen_mostrador ... gen_cielo).
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   Variable names are letters only (the engine's `$name` is /\$([a-z]+)/): readable stems, the round's letter at the end (disha, dishb); every `$` in an id is followed by `_` or the end.
#   87: the three plates on the shelf are the things plato1 to plato3 (the spots repisa1 to repisa3); the dish called (`dish`) is drawn first (round B: never the dish of round A, `otro`), its slot (1 to 3) is drawn, and the other two dishes
#       are dealt (`reparte`) from the three that are left: 4 dishes x 3 slots x 6 pairs, every one possible. `saca87` {cual}: the thing he touched (plato1 to plato3); `platos87` {a, b, c}: the dish on slot 1, 2, 3.
#       The wrong-move line says what he pushed and what was called ("Esto es carne. ¡El pescado!"): 12 clips, c87_no_<pushed>_<called>.
#   88: the board's four places are the things cuadro1 to cuadro4. At the start they hold, in the order the script lists them: carne con tostones, carne con mofongo, pescado con tostones, pescado con mofongo (so the señor's plate is cuadro1, the señora's cuadro4).
#       In a round the four plates are dealt to the four places (`reparte`); `tablero88` {orden} is the plates in the order of cuadro1 to cuadro4, comma-separated ("pescado_mofongo,carne_tostones,..."). `pide88` {cual}: the thing he touched.
#       Guests: the two named in the game, joven (A's example) and mujer (B's); the script's "another guest" is read as: A drawn, B the other one (`other`). Each says the order and the correction in his own voice (8 + 8 clips).
#       A miss is filed under what was wrong (the script's "A miss is filed under"): tostones or mofongo if that half was wrong (also for a right touch: that half is the new word), carne or pescado if only the other half was wrong.
#       The engine reads `tests` after the touch, so the key is "<plato>_<con>_<place of the plate with the same con and the other plato>_<place touched>" and `palabras` has the 64 keys (the word is the plato only when he touched that sibling plate).
#   89 A: asker (abuelo, abuela, luis) and drink (refresco, limonada) are drawn each on its own; the tray's three drinks (refresco, limonada, cafe) are dealt to bebida1 to bebida3; `bandeja89` {orden}: the drinks in the order of bebida1 to bebida3.
#       The wrong-move line says what he pushed: "Esto es limonada" or "Esto es café": 12 clips, c89_na_<asker>_<asked>_<pushed>. `da89` {que, a, ok}: que = the drink (refresco, limonada, cafe), a = the person (abuelo, abuela, luis).
#   89 B: the drink lifted (refresco, limonada, cafe: the three on the tray), who answers (abuelo or luis) and para (mi, el, ella) are drawn each on its own; the person it is for is mi: the one who answers, el: the other man, ella: abuela.
#       `tests`: A the drink asked for; B "para mí" / "para él" / "ella" (palabras maps mi, el, ella).
#   `cuadro` {n}: n is a picture's number (1 to 4). Where the script lights the board's pictures "as she says its word" (87 step 1, 89 step 1) one act runs in time with the line: n="todos" (this value is mine; the Needs gives n only as a picture's number).
#       Where the four light up "together" (89 step 1's ask) it is four loose acts n=1..4 and `ya`.
#   Start of each story: the hour, the board state (87 comida, 88 platos), the frog's spot, the stake's count; the people who are not in the picture at first (mesera, mesero, señor, señora) arrive with `llega`; 89 sends Carmen out with `sale`.
#       The family, the cocinero in the hatch and the cat are taken as the set's own (Needs: "in the set"); the script names no act for them.
#   Wrong-move order: the act that shows the touch and what comes back (saca87, pide88, da89 with ok=0), then the correction line, then the picture's loss (platito / platanos / sorbo89 + jugo: set from `lost`, before the cross is counted), then the cross (X).
#   (heard) words: "quieren", "comer" (forms of quiere, come; 87), "te gustan" (a form of me gusta; 88), "quién" and "tomar" (the infinitive of "toma (tomar)", heard in "¿Qué quieres de tomar?"; 89) are in also_heard, as gen_sombrilla does for "jugamos".
#       "para ella" (89: "and para ella, made of words he has") is not a new word of the story (not in focus_words: a miss on it is filed under `ella`) but is heard: also_heard. 89's bebida is also heard as "bebidas" (formas_foco): the script's count of 3 needs it.
#   The things the script's beats lean on that have no key of their own: the food board as a whole (87: "Abuela points at the board": `senala a=cuadro1`); the hatch ("the mesera reads from her pad, towards the hatch": `mira a=cocinero`); the plates the cocinero shows in 88 steps 1 and 2
#       (the tostones, then the dome: plato1, plato2, as the signed asks' things); the frog's own plate in 88 (platito, the Needs' only plate at the shelf's end); the mesera "at the next table" (88: spot otra_mesa, where the señor and the señora also stand: one spot, the last to arrive is taken to replace).
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); ABO=lambda t:D("abuelo","Abuelo",t); L=lambda t:D("luis","Luis",t)
MS=lambda t:D("mesera","La mesera",t); MO=lambda t:D("mesero","El mesero",t); CO=lambda t:D("cocinero","El cocinero",t)
SE=lambda t:D("senor","El señor",t); SA=lambda t:D("senora","La señora",t); JO=lambda t:D("joven","El joven",t); MU=lambda t:D("mujer","La mujer",t)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def conj(acts,*lines): return [dict(a,suelto=1) for a in acts]+list(lines)+[act("ya")]   # several acts in time with a line
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time: all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
TODOS="todos"                                             # `cuadro` n: all the board's pictures in turn, in time with the line (see the header)
MINE=("que-hay-de-comer","tostones-y-mofongo","las-bebidas")   # this generator's stories: not seen
LATER8=("prueba","falta-algo","mas-y-menos","el-postre","la-cuenta-por-favor","buenas-noches")   # the place's later scenes (90 to 95): never "earlier" for a speaking turn
EXTRA_KNOWN=["delicioso"]   # new in 92 (mas-y-menos, another builder's story): known to the warning below as the brief says (no turn of 87 to 89 uses it); para mí is 89's own word, known only after 89
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
DIN=set()   # ids that are put together in the story ("c87_pide_$disha" gives c87_pide_sopa) or shared by a literal and a built name: never renamed
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
TG=lambda *p:[{"palabra":w,"formas":list(f)} for w,f in p]
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}
# What he hears when he pokes a person already recorded (the mesera, the mesero and the cocinero are not recorded as named people: they add nothing)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),"abuelo":("n_abuelo",N("Este es abuelo."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def otro(out,inv,e,opts):
    # out = the e-th (1 to len-1) of the options that are not `inv`: a second dish that is never the first
    def rama(v):
        o=[x for x in opts if x!=v]
        return [{"calc":out,"cond":e+"=1","then":o[0],"else":o[1]}]+[{"calc":out,"cond":"%s=%d"%(e,i+1),"then":o[i],"else":"$"+out} for i in range(2,len(o))]
    ch=rama(opts[-1])
    for v in reversed(opts[:-1]): ch=[{"if":inv+"="+v,"then":rama(v),"else":ch}]
    return ch
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}

# ---------------- 87. ¿Qué hay de comer? ----------------
# The mesera calls a dish from a table across the room (sopa, carne, pescado, ensalada: drawn; the two rounds never call the same one); three plates stand on the hatch's shelf: the called dish and two of the other three, in a drawn order.
# A miss: the plate comes back, the mesera holds it up, and the cat's paw takes a golden round from the cocinero's small plate.
DISHES=["sopa","carne","pescado","ensalada"]; ART={"sopa":"La sopa","carne":"La carne","pescado":"El pescado","ensalada":"La ensalada"}
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c87_ms_quieren":MS("¿Qué quieren comer?"),"c87_ab_menu":AB("Mira el menú, Coquí. Hay sopa. Hay carne. Hay pescado. Y hay ensalada."),"c87_donde_sopa":N("¿Dónde está la sopa en el menú?"),
 "c87_ab_sopa":AB("Yo quiero sopa."),"c87_abo_pescado":ABO("Yo, pescado."),"c87_l_carne":L("¡Carne! Yo quiero carne."),"c87_ca_ensalada":D("carmen","Carmen","Y yo quiero ensalada."),
 "c87_abo_quiere":N("Abuelo quiere pescado. ¿Dónde está el pescado?"),"c87_ms_pad":MS("Una sopa, un pescado, una carne y una ensalada."),"c87_co_carne":CO("¡La carne!"),
 "c87_donde_carne":N("¿Dónde está la carne de Luis?"),"c87_ab_huele":AB("Mmm. ¿Cómo huele, Coquí?"),"c87_cq_rico":T("¡Rico!"),
 "c87_ms_sirve":MS("La sopa para abuela, el pescado para abuelo y la ensalada para Carmen."),"c87_ms_ven":MS("Coquí, ven acá, por favor."),
 "c87_fam_come":N("La familia come. Abuela come sopa. Abuelo come pescado."),"c87_cq_provecho":T("¡Buen provecho!"),"c87_ab_gracias":AB("¡Gracias, Coquí!")})
for d in DISHES:
    c["c87_pide_%s"%d]=MS("¡Coquí! %s, por favor."%ART[d]); DIN.add("c87_pide_%s"%d)
    for w in DISHES:
        if w!=d: c["c87_no_%s_%s"%(w,d)]=MS("No, Coquí. Esto es %s. ¡%s!"%(w,ART[d])); DIN.add("c87_no_%s_%s"%(w,d))
def ronda87(s,primera):
    # one round: a dish is called (round B: not round A's), a slot (1 to 3) for it, and two other dishes dealt to the other slots; the bell, three plates; he pushes one to the hatch's edge
    ds,ks,e1,e2,p1,p2,p3,wr=[b+s for b in ("dish","slot","extraone","extratwo","plateone","platetwo","platethree","wrong")]
    sorteo=[{"draw":ds,"options":DISHES}] if primera else [{"draw":"roll","options":["1","2","3"]}]+otro(ds,"disha","roll",DISHES)
    deal=lambda o:{"reparte":[e1,e2],"options":o}
    resto=[{"if":ds+"=sopa","then":[deal(["carne","pescado","ensalada"])],"else":[{"if":ds+"=carne","then":[deal(["sopa","pescado","ensalada"])],"else":[{"if":ds+"=pescado","then":[deal(["sopa","carne","ensalada"])],"else":[deal(["sopa","carne","pescado"])]}]}]}]
    sitio=[{"calc":p1,"cond":ks+"=1","then":"$"+ds,"else":"$"+e1},                                                    # slot 1, 2, 3: the called dish where `slot` says, the others in the order dealt
           {"calc":p2,"cond":ks+"=2","then":"$"+ds,"else":"$"+e2},{"calc":p2,"cond":ks+"=1","then":"$"+e1,"else":"$"+p2},
           {"calc":p3,"cond":ks+"=3","then":"$"+ds,"else":"$"+e2}]
    dec={"decide":"do","options":["plato1","plato2","plato3"],"pick":"plato$"+ks,"tests":"$"+ds,"lock":True,"lead":[],"line":"c87_pide_$"+ds,
         "right":[act("saca87",cual="plato$"+ks,ok=1),star],
         "wrong":[{"calc":wr,"cond":"x=plato1","then":"$"+p1,"else":"$"+p2},{"calc":wr,"cond":"x=plato3","then":"$"+p3,"else":"$"+wr},    # the dish he pushed
                  act("saca87",cual="$x",ok=0),"c87_no_$%s_$%s"%(wr,ds),resta(lambda n:act("platito",n=n))]+X}
    return sorteo+[{"draw":ks,"options":["1","2","3"]}]+resto+sitio+[act("platos87",a="$"+p1,b="$"+p2,c="$"+p3),dec]
def pide(q,d): return act("pide87",quien=q,que=d)
s87={"id":"que-hay-de-comer","title":"¿Qué hay de comer?","place":"La fonda","scene":"pedido","next":"tostones-y-mofongo",
 "goal":"Push the plate the mesera calls for (soup, meat, fish or salad) to the edge of the hatch's shelf so that the cocinero's small plate of three golden rounds stays whole for the frog: every wrong plate comes back, and while he is busy with it the cat takes a round.",
 "stake":{"thing":"platito","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["sopa","carne","pescado","ensalada"],"formas_foco":{},
 "back_again":["mesera","cocinero","menú","quiero","hay","come","huele","rico","gato","mira","ven","para","por favor","gracias","buen provecho","yo","esto","no"],
 "also_heard":["quieren","comer"],"names":nm,"palabras":{d:d for d in DISHES},"clips":c,
 "beats":[{"set":{"hora":"noche","tablero":"comida"}},act("ir",a="mesa_coqui"),act("llega",quien="mesera",a="junto_mesa"),act("platito",n=3),gesto("cocinero","guina"),{"wait":500},
  # 1: the mesera asks; abuela points at the board, each picture lights as she says its word; the signed ask on the soup's picture
  {"dots":1},"c87_ms_quieren",gesto("abuela","senala",a="cuadro1")]+con(act("cuadro",n=TODOS),"c87_ab_menu")+[ask("cuadro1","c87_donde_sopa",after=[act("cuadro",n=1)]),
  # 2: each one orders, a small picture over the one who speaks; the signed ask on the fish's picture, abuelo nods
  {"dots":2}]+con(pide("abuela","sopa"),"c87_ab_sopa")+con(pide("abuelo","pescado"),"c87_abo_pescado")+con(pide("luis","carne"),"c87_l_carne")+con(pide("carmen","ensalada"),"c87_ca_ensalada")+[
  ask("cuadro3","c87_abo_quiere",after=[act("cuadro",n=3),gesto("abuelo","si")]),
  # 3: the mesera reads her pad towards the hatch (flames in the hatch: no act named); a bell, the plate of meat; the signed ask on the plate (it steams: no act named); the first turn (rico)
  {"dots":3},gesto("mesera","mira",a="cocinero"),"c87_ms_pad",act("campana",que="carne"),"c87_co_carne",ask("plato1","c87_donde_carne",after=[act("lleva87",que="carne",a="luis")]),"c87_ab_huele","c87_cq_rico",
  # 4: the bell three times, the three plates are carried and set down one by one, the small pictures go out
  {"dots":4},act("campana",que="sopa"),act("campana",que="pescado"),act("campana",que="ensalada")]+con(act("sirve87"),"c87_ms_sirve")+[
  # 5: the fonda fills up (no act named); the mesera lifts the frog onto the shelf; the cocinero taps the small plate (the cat looks up at it: no act named); the card shows two places
  {"dots":5},act("ir",a="repisa_coqui"),"c87_ms_ven",gesto("cocinero","senala",a="platito"),CARD,{"wait":400},
  # 6: A, at a table across the room. 7: B, a new bell and another dish. Each drawn afresh
  {"dots":6},act("llega",quien="mesera",a="lejos")]+ronda87("a",True)+[{"dots":7}]+ronda87("b",False),
 "final":[{"dots":8},act("ir",a="mesa_coqui"),baja3(lambda n:act("final87",n=n)),   # 8: the last plates go out (no act named); he hops down with the small plate; the rounds left, by what was lost
  {"dots":9}]+conj([gesto(q,"come") for q in ("abuela","abuelo","luis","carmen")],"c87_fam_come")+["c87_cq_provecho","c87_ab_gracias",act("fin")],
 "leer":["c87_ms_quieren","c87_ab_menu","c87_donde_sopa","c87_ab_sopa","c87_abo_pescado","c87_l_carne","c87_ca_ensalada","c87_abo_quiere","c87_ms_pad","c87_co_carne","c87_donde_carne","c87_ab_huele","c87_cq_rico","c87_ms_sirve","c87_ms_ven",
  "c87_pide_pescado","c87_fam_come","c87_cq_provecho","c87_ab_gracias"]}
s87=reuse(s87,{"c87_cq_rico":TG(("rico",["rico","qué rico","que rico"])),"c87_cq_provecho":TG(("buen provecho",["buen provecho"]))})
json.dump(s87,open("cuentos/que-hay-de-comer.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 88. Tostones y mofongo ----------------
# A guest at the next table (joven or mujer: A drawn, B the other) asks for carne or pescado, con tostones or con mofongo (each drawn); the board shows the four plates in a drawn order; he touches one.
# A miss: the plate goes out, comes back, and the cocinero makes the right one with one of the three plantains tied with the ribbon.
PLAT=["carne","pescado"]; CON=["tostones","mofongo"]
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c88_co_mira":CO("Mira, Coquí. Un plátano."),"c88_co_tostones":CO("¡Tostones!"),"c88_donde_tostones":N("¿Dónde están los tostones?"),"c88_co_cuidado":CO("¡Cuidado! Los tostones están calientes."),
 "c88_cq_otro":T("¡Otro, por favor!"),"c88_co_mofongo":CO("Y esto es mofongo."),"c88_donde_mofongo":N("¿Dónde está el mofongo?"),"c88_co_dos":CO("Tostones y mofongo. Los dos son de plátano."),
 "c88_se_pide":SE("Me da carne con tostones, por favor."),"c88_sa_pide":SA("Y a mí me da pescado con mofongo."),"c88_cual":N("La señora quiere pescado con mofongo. ¿Cuál es?"),
 "c88_se_gracias":SE("¡Tostones! Gracias."),"c88_sa_rico":SA("Mmm. El mofongo está rico."),"c88_ms_ahora":MS("Ahora tú, Coquí. Mira el menú. ¿Qué plato quieren?"),
 "c88_co_para":CO("Tostones para Coquí."),"c88_ab_gustan":AB("¿Te gustan los tostones, Coquí?"),"c88_cq_mucho":T("¡Sí, mucho!"),"c88_fin_come":N("Coquí come tostones con la familia.")})
for g,F in (("joven",JO),("mujer",MU)):
    for p in PLAT:
        for k in CON:
            c["c88_o_%s_%s_%s"%(g,p,k)]=F("Me da %s con %s, por favor."%(p,k)); c["c88_no_%s_%s_%s"%(g,p,k)]=F("No, eso no. %s con %s, por favor."%(p.capitalize(),k))
            DIN.update(["c88_o_%s_%s_%s"%(g,p,k),"c88_no_%s_%s_%s"%(g,p,k)])
PL88={"cuadro1":"carne_tostones","cuadro2":"carne_mofongo","cuadro3":"pescado_tostones","cuadro4":"pescado_mofongo"}
def ronda88(s,g):
    # one round: the order (plato, con) and the board's places are drawn; he touches one of the four plates
    pl,cn,op,ha,hb,hc,hd,pk,sc=[b+s for b in ("plate","side","otherplate","laya","layb","layc","layd","pickplace","sibplace")]
    code="$%s_$%s"%(pl,cn); hermana="$%s_$%s"%(op,cn)    # the plate called; its sibling (the other plato with the same con)
    lugar=lambda out,c_:[{"calc":out,"cond":ha+"="+c_,"then":"cuadro1","else":"cuadro4"},{"calc":out,"cond":hb+"="+c_,"then":"cuadro2","else":"$"+out},{"calc":out,"cond":hc+"="+c_,"then":"cuadro3","else":"$"+out}]
    sorteo=[{"draw":pl,"options":PLAT},{"draw":cn,"options":CON},{"reparte":[ha,hb,hc,hd],"options":list(PL88.values())},{"calc":op,"cond":pl+"=carne","then":"pescado","else":"carne"}]+lugar(pk,code)+lugar(sc,hermana)
    dec={"decide":"do","options":["cuadro1","cuadro2","cuadro3","cuadro4"],"pick":"$"+pk,"tests":"$%s_$%s_$%s_$x"%(pl,cn,sc),"lock":True,"lead":[],"line":"c88_o_$%s_$%s_$%s"%(g,pl,cn),
         "right":[act("pide88",cual="$"+pk,ok=1),star],
         "wrong":[act("pide88",cual="$x",ok=0),"c88_no_$%s_$%s_$%s"%(g,pl,cn),resta(lambda n:act("platanos",n=n))]+X}
    return sorteo+[act("tablero88",orden="$%s,$%s,$%s,$%s"%(ha,hb,hc,hd)),gesto("$"+g,"mira",a="coqui"),dec]
PAL88={}
for pl in PLAT:
    for cn in CON:
        for sc in ("cuadro1","cuadro2","cuadro3","cuadro4"):
            for xx in ("cuadro1","cuadro2","cuadro3","cuadro4"):
                PAL88["%s_%s_%s_%s"%(pl,cn,sc,xx)]=pl if xx==sc else cn   # filed under the plato only when he touched the sibling plate; else under the con
s88={"id":"tostones-y-mofongo","title":"Tostones y mofongo","place":"La fonda","scene":"pedido","next":"las-bebidas",
 "goal":"Touch the plate on the board that the guest asks for (meat or fish, with tostones or with mofongo) so that the three green plantains tied with a red ribbon stay on the hook for the frog's own plate: every wrong plate comes back and the cocinero has to use one of the three to make the right one.",
 "stake":{"thing":"platanos","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["tostones","mofongo","me da"],"formas_foco":{},
 "back_again":["carne","pescado","con","plátano","cocinero","mesera","menú","plato","caliente","cuidado","rico","me gusta","mucho","otro","familia","come","esto","eso","mira","ahora","por favor","gracias","sí","no"],
 "also_heard":["te gustan"],"names":nm,"palabras":PAL88,"clips":c,
 "beats":[{"set":{"hora":"noche","tablero":"platos"}},act("ir",a="repisa_coqui"),act("platanos",n=3),act("llega",quien="senor",a="otra_mesa"),act("llega",quien="senora",a="otra_mesa"),{"wait":500},
  # 1: a plantain, the tostones are made; the signed ask on the plate (the cocinero gives him one and the frog juggles it: no act named); the first turn (otro): the cocinero laughs, gives him one more (no act named)
  {"dots":1},"c88_co_mira",act("frie88",que="tostones"),"c88_co_tostones",ask("plato1","c88_donde_tostones"),"c88_co_cuidado",gesto("coqui","come"),"c88_cq_otro",gesto("cocinero","rie"),
  # 2: the mofongo is made; the signed ask on the dome, the frog tastes and nods
  {"dots":2},act("frie88",que="mofongo"),"c88_co_mofongo",ask("plato2","c88_donde_mofongo",after=[gesto("coqui","come"),gesto("coqui","si")]),"c88_co_dos",
  # 3: the mesera at the next table taps the board (the plate of meat with tostones is the first place), the cocinero makes it (no act named); the signed ask on the fish with a dome (the fourth place): both plates go out
  {"dots":3},act("llega",quien="mesera",a="otra_mesa"),"c88_se_pide",gesto("mesera","senala",a="cuadro1"),act("cuadro",n=1),"c88_sa_pide",
  ask("cuadro4","c88_cual",after=[act("pide88",cual="cuadro4",ok=1)]),"c88_se_gracias","c88_sa_rico",
  # 4: the mesera is called away; the cocinero holds up the three plantains with the ribbon (no act named) and points at the frog's empty plate; new guests sit down; the card shows two places
  {"dots":4}]+con(act("sale",quien="mesera"),"c88_ms_ahora")+[gesto("cocinero","senala",a="platito"),{"draw":"guesta","options":["joven","mujer"],"other":"guestb"},act("llega",quien="$guesta",a="otra_mesa"),CARD,{"wait":400},
  # 5: A. 6: B, another guest. Each drawn afresh
  {"dots":5}]+ronda88("a","guesta")+[{"dots":6},act("llega",quien="$guestb",a="otra_mesa")]+ronda88("b","guestb"),
 "final":[{"dots":7},baja3(lambda n:act("final88",n=n)),act("ir",a="mesa_coqui"),   # 7: the cocinero fries the plantains left and fills the frog's plate; the frog carries it to the family's table; the plate, by what was lost
  {"dots":8},"c88_co_para","c88_ab_gustan","c88_cq_mucho"]+con(gesto("coqui","come"),"c88_fin_come")+[act("fin")],
 "leer":["c88_co_mira","c88_co_tostones","c88_donde_tostones","c88_co_cuidado","c88_cq_otro","c88_co_mofongo","c88_donde_mofongo","c88_co_dos","c88_se_pide","c88_sa_pide","c88_cual","c88_se_gracias","c88_sa_rico","c88_ms_ahora",
  "c88_o_joven_pescado_tostones","c88_co_para","c88_ab_gustan","c88_cq_mucho","c88_fin_come"]}
s88=reuse(s88,{"c88_cq_otro":TG(("otro",["otro","otro por favor"])),"c88_cq_mucho":TG(("mucho",["mucho","sí mucho","si mucho"]))})
json.dump(s88,open("cuentos/tostones-y-mofongo.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 89. Las bebidas ----------------
# A: abuelo, abuela or luis (drawn) asks for the soda or the lemonade (drawn); the tray holds a soda, a lemonade and a coffee in a drawn order; he touches a drink.
# B: the mesero lifts a drink (drawn); abuelo or luis (drawn) says para mí, para él or para ella (drawn); he touches the person. A miss: the mesero pulls at the straw of the tall glass: a third of the juice is gone.
DRK={"refresco":"un refresco","limonada":"una limonada"}; NDRK={"refresco":"Un refresco","limonada":"Una limonada"}; CAFE={"refresco":"refresco","limonada":"limonada","cafe":"café"}
PARA={"mi":"Para mí.","el":"Para él.","ella":"Para ella."}; NPARA={"mi":"No, Coquí. Para mí.","el":"No, Coquí. Para él.","ella":"No, Coquí. Para ella."}
QUIEN={"abuelo":ABO,"abuela":AB,"luis":L}
nm,nc=nombres("abuela","abuelo","luis","coqui"); c=dict(comunes); c.update(nc)
c.update({"c89_l_calor":L("¡Hace calor! Tengo sed."),"c89_mo_bebidas":MO("Aquí están las bebidas. Hay refresco, hay limonada, hay jugo de china y hay café."),"c89_donde_bebidas":N("¿Dónde están las bebidas?"),
 "c89_mo_refresco":MO("¿El refresco?"),"c89_l_mi":L("¡Para mí, para mí! Me gusta el refresco."),"c89_quien_refresco":N("¿Para quién es el refresco?"),"c89_mo_cafe":MO("¿El café?"),
 "c89_quien_el":N("El café es para él. ¿Quién es él?"),"c89_abo_gracias":ABO("Sí, para mí. Gracias."),"c89_mo_limonada_y":MO("¿Y la limonada?"),"c89_quien_ella":N("La limonada es para ella. ¿Quién es ella?"),
 "c89_ab_mi":AB("Para mí. Mmm, limonada."),"c89_l_todos":L("El café es para él, la limonada es para ella... ¡y el refresco es para mí!"),"c89_mo_ti":MO("¿Y para ti, Coquí? ¿Qué quieres de tomar?"),
 "c89_cq_jugo":T("Jugo de china, por favor."),"c89_mo_bebida":MO("Una bebida para Coquí. Ahora no. Después."),"c89_mo_limonada":MO("¿La limonada?"),
 "c89_l_otro":L("¡Yo quiero otro refresco!"),"c89_cq_tambien":T("¡Yo también!"),"c89_ab_agua":AB("No, no. Ahora, agua.")})
for q,F in QUIEN.items():
    for d in ("refresco","limonada"):
        c["c89_a_%s_%s"%(q,d)]=F("Para mí, %s, por favor."%DRK[d]); DIN.add("c89_a_%s_%s"%(q,d))
        for w in CAFE:
            if w!=d: c["c89_na_%s_%s_%s"%(q,d,w)]=F("No, Coquí. Esto es %s. %s, por favor."%(CAFE[w],NDRK[d])); DIN.add("c89_na_%s_%s_%s"%(q,d,w))
for q in ("abuelo","luis"):
    for p in PARA:
        c["c89_r_%s_%s"%(q,p)]=QUIEN[q](PARA[p]); c["c89_nb_%s_%s"%(q,p)]=QUIEN[q](NPARA[p]); DIN.update(["c89_r_%s_%s"%(q,p),"c89_nb_%s_%s"%(q,p)])
def ronda89a():
    # A: who asks and which drink are drawn each on its own; the three drinks are dealt to the tray's places; he touches a drink
    q,d,t1,t2,t3,pk,wr="asker","drink","trayone","traytwo","traythree","pickplace","wrongdrink"
    dec={"decide":"do","options":["bebida1","bebida2","bebida3"],"pick":"$"+pk,"tests":"$"+d,"lock":True,"lead":[],"line":"c89_a_$%s_$%s"%(q,d),
         "right":[act("da89",que="$"+d,a="$"+q,ok=1),star],
         "wrong":[{"calc":wr,"cond":"x=bebida1","then":"$"+t1,"else":"$"+t2},{"calc":wr,"cond":"x=bebida3","then":"$"+t3,"else":"$"+wr},    # the drink he pushed
                  act("da89",que="$"+wr,a="$"+q,ok=0),"c89_na_$%s_$%s_$%s"%(q,d,wr),act("sorbo89"),resta(lambda n:act("jugo",n=n))]+X}
    return [{"draw":q,"options":["abuelo","abuela","luis"]},{"draw":d,"options":["refresco","limonada"]},{"reparte":[t1,t2,t3],"options":["refresco","limonada","cafe"]},
     {"calc":pk,"cond":t1+"=$"+d,"then":"bebida1","else":"bebida3"},{"calc":pk,"cond":t2+"=$"+d,"then":"bebida2","else":"$"+pk},
     act("bandeja89",orden="$%s,$%s,$%s"%(t1,t2,t3)),gesto("$"+q,"mira",a="coqui"),dec]
def ronda89b():
    # B: the drink lifted, who answers (abuelo or luis) and para (mi, el, ella) are drawn each on its own; he touches the person
    dec={"decide":"do","options":["abuelo","abuela","luis"],"pick":"$target","tests":"$para","lock":True,"lead":[],"line":"c89_r_$answerer_$para",
         "right":[act("da89",que="$lifted",a="$target",ok=1),star],
         "wrong":[act("da89",que="$lifted",a="$x",ok=0),"c89_nb_$answerer_$para",act("sorbo89"),resta(lambda n:act("jugo",n=n))]+X}
    return [{"draw":"lifted","options":["refresco","limonada","cafe"]},{"draw":"answerer","options":["abuelo","luis"]},{"draw":"para","options":["mi","el","ella"]},
     {"calc":"otherman","cond":"answerer=abuelo","then":"luis","else":"abuelo"},{"calc":"target","cond":"para=mi","then":"$answerer","else":"abuela"},{"calc":"target","cond":"para=el","then":"$otherman","else":"$target"},
     act("bandeja89",orden="refresco,limonada,cafe"),act("alza89",que="$lifted"),"c89_mo_$lifted",gesto("$answerer","mira",a="coqui"),dec]
DIN.update(["c89_mo_refresco","c89_mo_limonada","c89_mo_cafe"])
s89={"id":"las-bebidas","title":"Las bebidas","place":"La fonda","scene":"pedido","next":"prueba",
 "goal":"Give each drink to whoever it is for (the soda or the lemonade by name, or the person by para mí, para él, para ella) so that the tall glass of orange juice the mesero made for the frog stays full: at each mix-up the hot, flustered mesero takes a long pull at its straw and a third is gone.",
 "stake":{"thing":"jugo","steps":3},"dots":10,"bien":"si_muy_bien",
 "focus_words":["bebida","refresco","limonada","para mí","para él"],"formas_foco":{"bebida":["bebidas"]},
 "back_again":["mesero","jugo","china","café","agua","hay","ella","él","quiero","quieres","toma","también","otro","tengo sed","hace calor","me gusta","después","ahora","aquí","esto","por favor","gracias","sí","no"],
 "also_heard":["quién","tomar","para ella"],"names":nm,"palabras":{"refresco":"refresco","limonada":"limonada","mi":"para mí","el":"para él","ella":"ella"},"clips":c,
 "beats":[{"set":{"hora":"noche"}},act("ir",a="mesa_coqui"),act("sale",quien="carmen"),act("llega",quien="mesero",a="junto_mesa"),{"wait":500},
  # 1: Luis is hot; the mesero points at the second board, each picture lights as he says its word; the signed ask on the board: the four light up together
  {"dots":1},"c89_l_calor",gesto("mesero","senala",a="bebidas")]+con(act("cuadro",n=TODOS),"c89_mo_bebidas")+[ask("bebidas","c89_donde_bebidas",after=juntos(*[act("cuadro",n=i) for i in (1,2,3,4)])),
  # 2: the tray; he lifts the bottle; the signed ask on Luis: the frog pushes the bottle to him
  {"dots":2},act("llega",quien="mesero",a="bandeja"),act("bandeja89",orden="refresco,cafe,limonada"),act("alza89",que="refresco"),"c89_mo_refresco","c89_l_mi",ask("luis","c89_quien_refresco",after=[act("da89",que="refresco",a="luis",ok=1)]),
  # 3: the cup; Luis nods towards abuelo; the signed ask on abuelo: the frog pushes the cup across
  {"dots":3},act("alza89",que="cafe"),"c89_mo_cafe",gesto("luis","cabeza",a="abuelo"),"c89_r_luis_el",ask("abuelo","c89_quien_el",after=[act("da89",que="cafe",a="abuelo",ok=1)]),"c89_abo_gracias",
  # 4: the glass; abuelo nods towards abuela; the signed ask on abuela; Luis points at each in turn, and at himself
  {"dots":4},act("alza89",que="limonada"),"c89_mo_limonada_y",gesto("abuelo","cabeza",a="abuela"),"c89_r_abuelo_ella",ask("abuela","c89_quien_ella",after=[act("da89",que="limonada",a="abuela",ok=1)]),"c89_ab_mi",
  gesto("luis","senala",a="abuelo"),gesto("luis","senala",a="abuela"),gesto("luis","senala",a="luis"),"c89_l_todos",
  # 5: the first turn (jugo de china); the tall glass of orange juice, full, on the tray's corner
  {"dots":5},"c89_mo_ti","c89_cq_jugo",act("jugo",n=3),"c89_mo_bebida",
  # 6: the glasses on the table are empty (no act named); a full tray; he fans himself, looks at the tall glass, and then from the drinks to the faces (no act named), taps the frog's nose (no act named); the card shows two places
  {"dots":6},act("llega",quien="mesero",a="bandeja"),gesto("mesero","abanico"),gesto("mesero","mira",a="vasito"),CARD,{"wait":400},
  # 7: A, touch a drink. 8: B, touch a person. Each drawn afresh
  {"dots":7}]+ronda89a()+[{"dots":8}]+ronda89b(),
 "final":[{"dots":9},baja3(lambda n:act("final89",n=n)),   # 9: the mesero puts the tall glass down in front of the frog; the juice left, by what was lost
  {"dots":10},"c89_l_otro","c89_cq_tambien","c89_ab_agua",act("fin")],
 "leer":["c89_l_calor","c89_mo_bebidas","c89_donde_bebidas","c89_mo_refresco","c89_l_mi","c89_quien_refresco","c89_mo_cafe","c89_r_luis_el","c89_quien_el","c89_abo_gracias","c89_mo_limonada_y","c89_r_abuelo_ella","c89_quien_ella","c89_ab_mi","c89_l_todos",
  "c89_mo_ti","c89_cq_jugo","c89_mo_bebida","c89_a_abuelo_refresco","c89_mo_limonada","c89_r_luis_ella","c89_l_otro","c89_cq_tambien","c89_ab_agua"]}
s89=reuse(s89,{"c89_cq_jugo":TG(("jugo",["jugo de china","un jugo de china","jugo"])),"c89_cq_tambien":TG(("también",["también","tambien","yo también","yo tambien"]))})
json.dump(s89,open("cuentos/las-bebidas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
# every id the steps name (with no variable in it) is in the story's clips; every `leer` id too; every speaking turn is on a word of an earlier story
# (the files on disk of places 1 to 7 and La fonda's entrada, the stories of this run before it, and the words the brief names as known); a word new in a later story (90 to 95) is never earlier
earlier=set(EXTRA_KNOWN)
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE+LATER8: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s87,s88,s89):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:87|88|89)_|si_|yo_|p_n_|b_n_|n_|esta_|cq_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    earlier.update(st["focus_words"])
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
