# La ropa (place 7, La playa, scene 3 of 4): stories 78, 79, 80. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/ropa.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `ropa` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: any order among the four scenes of La playa; every speaking turn's word comes from places 1 to 6.
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   Thing keys are the script's own (camisa, pantalon, vestido, zapatos / sombrero, toalla, chancletas, gafas, traje / luis, carmen, chico_a, chico_b, chica_a, chica_b); the `que` of every act is the same key, so a wrong touch (`$x`) goes into an act as it is.
#   `stake.thing` is the name of the act that shows it: panes (78), bolsa (79), dedos (80). The count `n` of panes / bolsa / dedos / final78 / final79 / final80 is the steps of the stake left: 3, 2, 1 (the other scenes' baja3).
#   79 `flotan` {orden}: the things in the water, left to right, as ONE string with commas ("sombrero,chancletas,gafas,traje"), as gen_mesa writes `a="carmen,mama,papa"`. The opening's five things are in the order of the script's "Goal he can see"
#       (sombrero, gafas, chancletas, traje, toalla); the game's four are dealt by `reparte` (a random order of the four, none twice).
#   79 round B: the things still afloat are what A left (A's asked thing is in the bag when right; A's asked thing is far out and A's wrong thing is in the bag when wrong). The generator writes round B once for every set that can be left (flags fs, fc, fg, ft set in A).
#   80 `pareja80` {quienes, que, cual} has no value for who does what; the script's Values line names it `hace` (pone, quita: what HIS child does; the other child does the opposite): passed as an added key `hace`.
#       `quienes` is chicos or chicas; `cual` is a or b (which of the two is his); `busca80` {quien}: the thing key of the child he pulled (chico_a ...); the pair acts are started loose (`suelto`) and left running until he chooses: no `ya`.
#   80 state: `hora` ocaso (the sun is low), `guagua` 1 (the guagua at the stop); 78 and 79 set `hora` tarde only.
#   80 drawn lines that say the same words as a line of the opening ("Luis se pone la camisa.", "Carmen se pone el vestido.") are the same clip (one recording).
#   The wrong move runs in the order of the script: the frog's act, the line, the picture's loss (sacude78 / ola79 / bocina), the count act, then the cross and one step (X). In 78 the line is said in time with the act (`con`), because the act carries
#       both the bringing and the fall; in 79 and 80 the act comes first and then the line.
#   Beats with no act named in Needs are left out (and listed in the report): nothing is invented.
#   Ranges in "Back again" are written out; "(heard)" words are in back_again (as quiosco's "bizcocho"), words the steps mark "(x: heard)" and not in Back again are in also_heard.
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
MINE=("la-ropa-seca","mi-sombrero","se-pone-y-se-quita")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c78_a_$qa"): never renamed
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
# What he hears when he pokes a person already recorded
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "perro":("c_n_perro",N("Es el perro. Se llama Canelo."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}
def cadena(var,vals,f):
    # if var=v1 then f(v1) else if var=v2 ... else f(last)
    ch=f(vals[-1])
    for v in reversed(vals[:-1]): ch=[{"if":"%s=%s"%(var,v),"then":f(v),"else":ch}]
    return ch

# ---------------- 78. La ropa seca ----------------
# Abuela pegs a red shirt, blue trousers, a yellow dress on the line and sets the shoes on the bench; then she asks for one of the four (round A, drawn), and for one of the three that are left (round B, drawn).
# The frog brings it; she passes it through the curtain to whichever child is changing. A miss: the wrong piece is handed back and falls on the sand, she shakes it, the sand lands on a sandwich, the gulls take it.
K78=["camisa","pantalon","vestido","zapatos"]; A78={"camisa":"la camisa","pantalon":"el pantalón","vestido":"el vestido","zapatos":"los zapatos"}
nm,nc=nombres("abuela","luis","carmen","coqui","perro"); c=dict(comunes); c.update(nc)
c.update({"c78_agua":N("Luis y Carmen están en el agua. Abuela tiene la ropa seca."),"c78_ab_camisa":AB("Mira, Coquí: una camisa. La camisa roja de Luis."),"c78_donde_camisa":N("¿Dónde está la camisa?"),
 "c78_ab_pantalon":AB("Y un pantalón. El pantalón azul."),"c78_ab_vestido":AB("Un vestido. El vestido amarillo de Carmen."),"c78_cual_pantalon":N("¿Cuál es el pantalón?"),"c78_y_vestido":N("¿Y el vestido?"),
 "c78_ab_zapatos":AB("Y los zapatos. Zapatos blancos y zapatos negros."),"c78_donde_zapatos":N("¿Dónde están los zapatos?"),
 "c78_ab_ayudas":AB("Camisa, pantalón, vestido y zapatos: ¡la ropa está seca! Coquí, ¿me ayudas?"),"c78_cq_si":T("¡Sí!"),"c78_ab_primero":AB("Primero la ropa. Y después comemos."),
 "c78_ab_quieres":AB("¿Quieres un sándwich, Coquí?"),"c78_cq_quiero":T("¡Sí, quiero!"),"c78_fin":N("Luis y Carmen están secos. Y Coquí come.")})
for k in K78:
    c["c78_a_%s"%k]=AB("Coquí, dame %s."%A78[k]); c["c78_b_%s"%k]=AB("Y ahora, dame %s."%A78[k]); c["c78_no_%s"%k]=AB("No, Coquí. Dame %s."%A78[k])
    DIN.update(["c78_a_%s"%k,"c78_b_%s"%k,"c78_no_%s"%k])
def ronda78(s,opts):
    # one round: abuela asks for one of `opts` (drawn). Right: the frog brings it, she passes it through the curtain. Wrong: the frog brings another; she says no and hands it back, it falls, the sand lands on a sandwich.
    q="q"+s
    return [{"draw":q,"options":opts},
     {"decide":"do","options":opts,"pick":"$"+q,"tests":"$"+q,"lock":True,"lead":[],"line":"c78_%s_$%s"%(s,q),
      "right":[act("baja78",que="$"+q,ok=1),star],
      "wrong":con(act("baja78",que="$x",ok=0),"c78_no_$"+q)+[act("sacude78"),resta(lambda n:act("panes",n=n))]+X}]
rB78=cadena("qa",K78,lambda k:ronda78("b",[o for o in K78 if o!=k]))   # round B: the three that are left
s78={"id":"la-ropa-seca","title":"La ropa seca","place":"La playa","scene":"ropa","next":"mi-sombrero",
 "goal":"Hand abuela the piece of clothing she asks for (shirt, trousers, dress, shoes) so that the plate of three sandwiches stays clean: every wrong piece falls on the sand, and the sand lands on a sandwich that goes to the gulls.",
 "stake":{"thing":"panes","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["camisa","pantalón","vestido","zapatos"],"formas_foco":{},
 "back_again":["seco","mojado","rojo","azul","amarillo","blanco","dame","toma","gracias","come","quiero","quieres","¿dónde está?","¿cuál?","arena","sí","no","después","ropa","sándwich"],
 "also_heard":["me ayudas","primero","comemos"],"names":nm,"palabras":{"camisa":"camisa","pantalon":"pantalón","vestido":"vestido","zapatos":"zapatos"},"clips":c,
 "beats":[{"set":{"hora":"tarde"}},act("panes",n=3),{"wait":500},
  # 1: the clothes are dry; abuela pegs the shirt; signed ask on it
  {"dots":1},"c78_agua",act("tiende78",que="camisa"),"c78_ab_camisa",ask("camisa","c78_donde_camisa"),
  # 2: the trousers, the dress; signed asks on them
  {"dots":2},act("tiende78",que="pantalon"),"c78_ab_pantalon",act("tiende78",que="vestido"),"c78_ab_vestido",ask("pantalon","c78_cual_pantalon"),ask("vestido","c78_y_vestido"),
  # 3: the shoes on the bench's end; signed ask; the first turn (sí)
  {"dots":3},act("tiende78",que="zapatos"),"c78_ab_zapatos",ask("zapatos","c78_donde_zapatos"),"c78_ab_ayudas","c78_cq_si",
  # 4: the two come out of the sea; abuela lifts the cloth (no act named); she sits by the curtain (no act named); the card shows two places
  {"dots":4},act("salen78"),"c78_ab_primero",CARD,{"wait":400},
  # 5: A (one of four). 6: B (one of the three left). Each drawn afresh
  {"dots":5}]+ronda78("a",K78)+[{"dots":6}]+rB78,
 "final":[{"dots":7},baja3(lambda n:act("final78",n=n)),   # 7: the curtain opens; the sandwiches, by what was lost
  {"dots":8},"c78_ab_quieres","c78_cq_quiero","c78_fin",act("fin")],
 "leer":["c78_agua","c78_ab_camisa","c78_donde_camisa","c78_ab_pantalon","c78_ab_vestido","c78_cual_pantalon","c78_y_vestido","c78_ab_zapatos","c78_donde_zapatos","c78_ab_ayudas","c78_cq_si","c78_ab_primero",
  "c78_a_pantalon","c78_b_zapatos","c78_ab_quieres","c78_cq_quiero","c78_fin"]}
s78=reuse(s78,{"c78_cq_si":TG(("sí",["sí","si"])),"c78_cq_quiero":TG(("quiero",["quiero","sí quiero"]))})
json.dump(s78,open("cuentos/la-ropa-seca.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 79. ¡Mi sombrero! ----------------
# A big wave has taken the bag; things float in the water. Four of them (hat, sandals, glasses, swimming suit) in a dealt order: abuela asks for one (round A), then for one of those still afloat (round B).
# A miss: the frog brings in another thing (it stays in the bag), the next wave carries the asked one far out; the sign is on it, he touches it, the frog swims out and a second wave takes it out of sight.
T79=["sombrero","chancletas","gafas","traje"]; W79={"sombrero":"el sombrero","chancletas":"las chancletas","gafas":"las gafas","traje":"el traje de baño"}
F79={"sombrero":"fs","chancletas":"fc","gafas":"fg","traje":"ft"}   # after A: 1 if the thing is still afloat, 0 if it is in the bag or far out
nm,nc=nombres("abuela","luis","carmen","coqui","perro"); c=dict(comunes); c.update(nc)
c.update({"c79_ola":N("¡Una ola grande!"),"c79_ab_sombrero":AB("¡Ay! ¡Mi sombrero! Coquí, busca mi sombrero."),"c79_donde_sombrero":N("¿Dónde está el sombrero?"),"c79_ab_mojado":AB("Gracias. ¡El sombrero está mojado!"),
 "c79_l_toalla":L("Mira: una toalla. La toalla está allá."),"c79_donde_toalla":N("¿Dónde está la toalla?"),
 "c79_ab_chancletas":AB("Mira, ahí están las chancletas."),"c79_donde_chancletas":N("¿Dónde están las chancletas?"),"c79_ab_gafas":AB("Ahí están las gafas."),"c79_y_gafas":N("¿Y las gafas?"),
 "c79_ca_traje":CA("¡Y mi traje de baño!"),"c79_ab_traje":AB("Sí, ahí está el traje de baño. Las chancletas, las gafas, el traje de baño y mi sombrero."),"c79_l_avanza":L("¡Avanza, Coquí!"),"c79_cq_voy":T("¡Voy!"),
 "c79_ab_cuidado":AB("¡Cuidado! Viene una ola. Ahora tú, Coquí."),"c79_ab_toma":AB("Toma, Coquí. Una toalla seca."),"c79_cq_gracias":T("¡Gracias!"),"c79_fin":N("El sombrero está mojado. Y Coquí está seco.")})
for k in T79:
    c["c79_busca_%s"%k]=AB("¡Coquí, busca %s!"%W79[k]); c["c79_no_%s"%k]=AB("¡No! ¡%s!"%(W79[k][0].upper()+W79[k][1:])); DIN.update(["c79_busca_%s"%k,"c79_no_%s"%k])
def ronda79(s,cosas,flags=None):
    # one round: abuela asks for one of the things afloat (`cosas`, drawn). Right: the frog brings it in, it goes into the bag. Wrong: the frog brings in another thing, the wave carries the asked one out to sea.
    # `flags` (round A only): after the round, which things are still afloat (a flag per thing, for round B)
    q="q"+s
    def fl(mal):
        out=[]
        for t in T79:
            out.append({"calc":F79[t],"cond":"%s=%s"%(q,t),"then":"0","else":"1"})
            if mal: out.append({"calc":F79[t],"cond":"x=%s"%t,"then":"0","else":"$"+F79[t]})
        return out
    return [{"draw":q,"options":cosas},
     {"decide":"do","options":cosas,"pick":"$"+q,"tests":"$"+q,"lock":True,"lead":[],"line":"c79_busca_$"+q,
      "right":[{"if":"ok","then":[act("trae79",que="$"+q),OK]+(fl(False) if flags else []),"else":[act("lejos79",que="$"+q)]}],
      "wrong":[act("trae79",que="$x"),"c79_no_$"+q,act("ola79",lleva="$"+q),resta(lambda n:act("bolsa",n=n))]+(fl(True) if flags else [])+X}]
def arbolB(i=0,afloat=()):
    # round B, once for every set of things that can be afloat after A (three when A was right, two when it was wrong)
    if i==len(T79): return ronda79("b",list(afloat)) if len(afloat) in (2,3) else []
    t=T79[i]
    return [{"if":F79[t]+"=1","then":arbolB(i+1,afloat+(t,)),"else":arbolB(i+1,afloat)}]
s79={"id":"mi-sombrero","title":"¡Mi sombrero!","place":"La playa","scene":"ropa","next":"se-pone-y-se-quita",
 "goal":"Bring abuela the thing she asks for out of the water into her bag, so that nothing floats away to sea: every wrong thing the frog brings lets the next wave carry the one she asked for far out.",
 "stake":{"thing":"bolsa","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["chancletas","sombrero","gafas","traje de baño","toalla"],"formas_foco":{},
 "back_again":["mar","ola","playa","mojado","seco","mi","busca","¿dónde está?","mira","viene","se va","grande","cuidado","gracias","toma","sí","no","abuela","allá","está","ahí"],
 "also_heard":["avanza"],"names":nm,"palabras":{"sombrero":"sombrero","chancletas":"chancletas","gafas":"gafas","traje":"traje de baño"},"clips":c,
 "beats":[{"set":{"hora":"tarde"}},act("flotan",orden="sombrero,gafas,chancletas,traje,toalla"),act("bolsa",n=3),{"wait":500},
  # 1: the wave (the wave slides back, the small wave takes the hat out of her hand again: no act named); the hat; signed ask; the frog hops in and pushes it to the edge
  {"dots":1},"c79_ola","c79_ab_sombrero",ask("sombrero","c79_donde_sombrero",after=[act("trae79",que="sombrero")]),"c79_ab_mojado",
  # 2: Luis points at the towel; signed ask; the frog drags it in (Luis wrings it out and hangs it: no act named)
  {"dots":2},gesto("luis","senala",a="toalla"),"c79_l_toalla",ask("toalla","c79_donde_toalla",after=[act("trae79",que="toalla")]),
  # 3: abuela points at each thing in turn; signed asks on the sandals and on the glasses; Carmen calls her swimming suit (no act named for her); abuela says yes and lists them
  {"dots":3},gesto("abuela","senala",a="chancletas"),"c79_ab_chancletas",ask("chancletas","c79_donde_chancletas"),
  gesto("abuela","senala",a="gafas"),"c79_ab_gafas",ask("gafas","c79_y_gafas"),"c79_ca_traje",gesto("abuela","senala",a="traje"),"c79_ab_traje",
  # 4: Luis calls him; the second turn (voy); the frog hops to the edge (no spot named for him)
  {"dots":4},"c79_l_avanza","c79_cq_voy",
  # 5: four things in a dealt order; abuela holds the bag open; the wave is building; the card shows two places
  {"dots":5},{"reparte":["oa","ob","oc","od"],"options":T79},act("flotan",orden="$oa,$ob,$oc,$od"),act("bolsa",n=3),"c79_ab_cuidado",CARD,{"wait":400},
  # 6: A (one of four). 7: B (one of those afloat). Each drawn afresh
  {"dots":6}]+ronda79("a",T79,flags=True)+[{"dots":7}]+arbolB(),
 "final":[{"dots":8},gesto("abuela","mira",a="bolsa"),baja3(lambda n:act("final79",n=n)),   # 8: the last wave; the things on the line, by what was lost
  {"dots":9},"c79_ab_toma","c79_cq_gracias","c79_fin",act("fin")],
 "leer":["c79_ola","c79_ab_sombrero","c79_donde_sombrero","c79_ab_mojado","c79_l_toalla","c79_donde_toalla","c79_ab_chancletas","c79_donde_chancletas","c79_ab_gafas","c79_y_gafas","c79_ca_traje","c79_ab_traje","c79_l_avanza","c79_cq_voy",
  "c79_ab_cuidado","c79_busca_chancletas","c79_busca_gafas","c79_ab_toma","c79_cq_gracias","c79_fin"]}
s79=reuse(s79,{"c79_cq_voy":TG(("voy",["voy"])),"c79_cq_gracias":TG(("gracias",["gracias"]))})
json.dump(s79,open("cuentos/mi-sombrero.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 80. Se pone y se quita ----------------
# Luis and Carmen dress and undress in front of him. Then two pairs of children who look alike stand at the water's edge with their backs to us: two boys (round A), two girls (round B). One puts a thing on while the other takes it off, over and over.
# The narrator says what abuela's child is doing (se pone or se quita, with a thing drawn); which of the two is hers is drawn. A miss: the frog pulls a stranger by the leg, the horn sounds, the driver puts a finger down.
nm,nc=nombres("abuela","luis","carmen","coqui","perro"); c=dict(comunes); c.update(nc)
c.update({"c80_tarde":N("Es tarde. La guagua está esperando."),"c80_l_sombrero":N("Y se pone el sombrero."),"c80_quien_sombrero":N("¿Quién tiene puesto un sombrero?"),
 "c80_ca_gafas":N("Carmen tiene puestas las gafas."),"c80_ab_sol":AB("Carmen, ya no hay sol."),"c80_ca_quita":N("Carmen se quita las gafas."),"c80_quien_vestido":N("¿Quién tiene puesto un vestido?"),
 "c80_l_quita_pone":N("Luis se quita el sombrero... y se pone el sombrero."),"c80_ca_chancletas":N("Carmen se quita las chancletas."),"c80_l_vienes":L("Coquí, ¿vienes?"),"c80_cq_voy":T("¡Voy!"),
 "c80_ab_donde":AB("¿Dónde está Luis? ¿Dónde está Carmen? Coquí, búscalos."),"c80_ab_canelo":AB("¿Y Canelo? ¿Dónde está Canelo?"),"c80_cq_aqui":T("¡Aquí!"),
 "c80_fin":N("Canelo tiene puesto el sombrero de abuela. Y la guagua se va.")})
ART80={"sombrero":"el sombrero","camisa":"la camisa","vestido":"el vestido"}
for s,quien,cosas in (("a","Luis",["sombrero","camisa"]),("b","Carmen",["sombrero","vestido"])):
    for h,v in (("pone","se pone"),("quita","se quita")):
        for k in cosas:
            c["c80_%s_%s_%s"%(s,h,k)]=N("%s %s %s."%(quien,v,ART80[k])); c["c80_no_%s_%s_%s"%(s,h,k)]=AB("No, Coquí. %s %s %s."%(quien,v,ART80[k])); DIN.update(["c80_%s_%s_%s"%(s,h,k),"c80_no_%s_%s_%s"%(s,h,k)])
c["c80_a_pone_camisa"]=N("Luis se pone la camisa."); c["c80_b_pone_vestido"]=N("Carmen se pone el vestido.")   # the opening says the same words: one clip
def ronda80(s,quienes,cosas,pre):
    # one round: a thing (k), what HIS child does with it (h: pone or quita), and which of the two is his (cu: a or b), each drawn. The two do opposite things with the same thing until he chooses.
    h,k,cu="h"+s,"k"+s,"c"+s
    return [{"draw":h,"options":["pone","quita"]},{"draw":k,"options":cosas},{"draw":cu,"options":["a","b"]},
     dict(act("pareja80",quienes=quienes,que="$"+k,hace="$"+h,cual="$"+cu),suelto=1),
     {"decide":"do","options":[pre+"_a",pre+"_b"],"pick":pre+"_$"+cu,"tests":"$"+h,"lock":True,"lead":[],"line":"c80_%s_$%s_$%s"%(s,h,k),
      "right":[act("busca80",quien=pre+"_$"+cu,ok=1),star],
      "wrong":[act("busca80",quien="$x",ok=0),"c80_no_%s_$%s_$%s"%(s,h,k),act("bocina"),resta(lambda n:act("dedos",n=n))]+X}]
s80={"id":"se-pone-y-se-quita","title":"Se pone y se quita","place":"La playa","scene":"ropa","next":"como-esta-el-tiempo",
 "goal":"Find abuela's child (Luis, then Carmen) among two children who look alike by what the narrator says he is doing (puts on or takes off a hat, shirt or dress), so that the guagua driver keeps waiting: every wrong child makes him sound the horn and put a finger down.",
 "stake":{"thing":"dedos","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["se pone","se quita","tiene puesto"],"formas_foco":{"tiene puesto":["tiene puestas","tiene puesta"]},
 "back_again":["camisa","pantalón","vestido","zapatos","chancletas","sombrero","gafas","traje de baño","toalla","rojo","amarillo","guagua","se va","espera","¿dónde está?","¿quién?","busca","allá","ven","voy","aquí","ahora","tarde","sol","no hay","mira"],
 "also_heard":[],"names":nm,"palabras":{"pone":"se pone","quita":"se quita"},"clips":c,
 "beats":[{"set":{"hora":"ocaso","guagua":1}},{"wait":500},
  # 1: the guagua is waiting, three fingers; Luis puts on his shirt and his hat; signed ask on him
  {"dots":1},"c80_tarde",act("dedos",n=3),act("pone80",quien="luis",que="camisa"),"c80_a_pone_camisa",act("pone80",quien="luis",que="sombrero"),"c80_l_sombrero",ask("luis","c80_quien_sombrero"),
  # 2: Carmen puts on her dress and her glasses; abuela says no sun; she takes them off; signed ask on her (she spins)
  {"dots":2},act("pone80",quien="carmen",que="vestido"),"c80_b_pone_vestido",act("pone80",quien="carmen",que="gafas"),"c80_ca_gafas",gesto("abuela","no"),"c80_ab_sol",
  act("quita80",quien="carmen",que="gafas"),"c80_ca_quita",ask("carmen","c80_quien_vestido",after=[gesto("carmen","gira")]),
  # 3: Luis takes his hat off, fans himself, puts it on; Carmen kicks off her sandals; the first turn (voy); the two run off (no act named)
  {"dots":3},act("quita80",quien="luis",que="sombrero"),gesto("luis","abanica"),act("pone80",quien="luis",que="sombrero"),"c80_l_quita_pone",act("quita80",quien="carmen",que="chancletas"),"c80_ca_chancletas","c80_l_vienes","c80_cq_voy",
  # 4: the four children at the water's edge (no act named); abuela shades her eyes; the driver looks at his watch (no act named); the card shows two places
  {"dots":4},gesto("abuela","ojos"),"c80_ab_donde",CARD,{"wait":400},
  # 5: A (the two boys). 6: B (the two girls). Each drawn afresh
  {"dots":5}]+ronda80("a","chicos",["sombrero","camisa"],"chico")+[{"dots":6}]+ronda80("b","chicas",["sombrero","vestido"],"chica"),
 "final":[{"dots":7},baja3(lambda n:act("final80",n=n)),   # 7: the four run for the road; the driver's fingers, by what was lost
  {"dots":8},"c80_ab_canelo","c80_cq_aqui","c80_fin",act("fin")],
 "leer":["c80_tarde","c80_a_pone_camisa","c80_l_sombrero","c80_quien_sombrero","c80_b_pone_vestido","c80_ca_gafas","c80_ab_sol","c80_ca_quita","c80_quien_vestido","c80_l_quita_pone","c80_ca_chancletas","c80_l_vienes","c80_cq_voy","c80_ab_donde",
  "c80_a_quita_sombrero","c80_b_pone_sombrero","c80_ab_canelo","c80_cq_aqui","c80_fin"]}
s80=reuse(s80,{"c80_cq_voy":TG(("voy",["voy"])),"c80_cq_aqui":TG(("aquí",["aquí","aqui"]))})
json.dump(s80,open("cuentos/se-pone-y-se-quita.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
# every id the steps name (with no variable in it) is in the story's clips; every `leer` id too; every speaking turn is on a word of an earlier story (the files on disk: places 1 to 6)
earlier=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s78,s79,s80):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:78|79|80)_|si_|yo_|p_n_|b_n_|n_|esta_|cq_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
