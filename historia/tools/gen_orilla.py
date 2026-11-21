# La orilla (place 7, La playa, scene 1 of 4): stories 72, 73, 74. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/orilla.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `orilla` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: any order among the four scenes of La playa; every speaking turn's word comes from places 1 to 6 (checked against every story that is not one of the twelve of place 7).
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   EDGE: the frog's spot at the water's edge in 72 (step 2) is orilla1 (the script names orilla1 to orilla4 and no owner). HIGH: "the highest tower" is torre2 (the middle one; the script names no height).
#   Colours in act arguments: rojo, azul, amarillo, verde, blanco, as written in the script's lines and Needs ("rojo", never "roja": the act value is the masculine word; the lines of 74 say roja, amarilla).
#   72, `en`: "mar" or "arena", as in the script's Needs (the value of the act and of the thing he touches).
#   72, `corona72` {n} is the tower a shell goes on: the first tower in the turn (Luis, no touch); in the game the next bare one: 2 in round A; 3 in round B if round A cost nothing, 2 if it did.
#   72, `conchas` {n}: three at the start and when Luis shows them again (step 5); then 3 minus the shells lost, set after the picture's loss and before the cross (as `globos`/`lazos` in the model generators).
#   73, `conchas` {n} is the stake display too (the Needs list tags it 72; the sprite is the same shells): 3 at the start, then 3 minus the shells lost. `collar` {n}: 0 when Carmen holds up the string, 1 when the opening's shell is tied on,
#       then 2 after a right round A; round B: 3 if nothing was lost, else 2. The colours of round A are drawn in step 4 (the turn) so that the two boats Luis sets down there are round A's boats; round B draws at its start.
#   74, the colours of round A are drawn in step 4 (the turn) for the same reason: the two folded towels hung on the rope there are round A's. `toallas` {n}: 3, then 3 minus the towels lost, set after the picture's loss and before the cross.
#   74, round B: "Right and wrong as in A" with Luis the child: his own "¡Uy! ¡Está mojada!" (the towel is feminine, so the words are the same) is a clip of its own, since Carmen's clip is said by Carmen.
#   74, the wrong move: the frog's bringing, Carmen's "¡Uy!" in time with it (`con`), then the pile's count, then abuela's correction (the script's order), then the cross.
#   74, the right touch after a wrong move: the right towel twinkles on the rope (the script says so); the engine's twinkle needs the thing key, so it is picked by the draw of the side (`k`).
#   Draws: each round on its own (colours, which is said first, which side). Where the script gives a pattern with a colour that is drawn, every sentence it can make is a clip: 73 has 12 + 3, 74 has 24 + 4.
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
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
EDGE="orilla1"; HIGH="torre2"
MINE=("la-playa","flota","puedo")   # this generator's stories: not seen
PLACE7=MINE+("la-cara","la-cabeza-y-los-brazos","me-duele","la-ropa-seca","mi-sombrero","se-pone-y-se-quita","como-esta-el-tiempo","esta-lloviendo","la-luna")   # the twelve stories of place 7: never an "earlier" story
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
DIN=set()   # ids that are put together in the story ("c73_fn_rojo_azul"): never renamed
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
def otro(out,inv,e,opts):
    # out = the e-th (1 to len-1) of the options that are not `inv`: a second colour that is never the first
    def rama(v):
        o=[x for x in opts if x!=v]
        return [{"calc":out,"cond":e+"=1","then":o[0],"else":o[1]}]+[{"calc":out,"cond":"%s=%d"%(e,i+1),"then":o[i],"else":"$"+out} for i in range(2,len(o))]
    ch=rama(opts[-1])
    for v in reversed(opts[:-1]): ch=[{"if":inv+"="+v,"then":rama(v),"else":ch}]
    return ch

# ---------------- 72. La playa ----------------
# Luis hides a shell in the sand or at the sea's edge (`e`, drawn each round on its own); Carmen says where (only mar / arena differs); he touches the patch of sand or the sea's edge.
# A miss: the frog looks in the other place (nothing); the wave takes the shell (hidden at the edge) or Canelo digs it out and runs off (hidden in the sand).
nm,nc=nombres("abuela","luis","carmen","perro","coqui"); c=dict(comunes); c.update(nc)
c.update({"c72_mira":N("Mira: la playa. Hace calor."),"c72_ca_playa":CA("¡La playa! ¡Me gusta la playa!"),"c72_ab_mar":AB("Mira el mar, Coquí. El mar es grande."),"c72_donde_mar":N("¿Dónde está el mar?"),"c72_l_ola":L("¡Una ola!"),
 "c72_l_arena":L("Aquí hay arena. ¡Mucha arena!"),"c72_l_torre":L("Una torre de arena."),"c72_ca_agua":CA("¡Al agua!"),"c72_cq_vamos":T("¡Vamos!"),"c72_ca_viene":CA("Viene una ola... y se va."),
 "c72_ca_busca":CA("Coquí, busca. La concha está en la arena."),"c72_donde_arena":N("¿Dónde hay arena?"),"c72_ca_ahora_mar":CA("Ahora la concha está en el mar."),"c72_ab_cuidado":AB("¡Cuidado! ¡Una ola grande!"),
 "c72_ab_torres":AB("Tres torres. Y después, la foto."),"c72_ab_foto":AB("Coquí, ven acá. ¡La foto!"),"c72_cq_voy":T("¡Voy!"),"c72_fin":N("Hay mucha arena en la playa. Y el mar es grande.")})
for w,art in (("mar","el mar"),("arena","la arena")):
    c["c72_a_"+w]=CA("Coquí, la concha está en %s."%art); c["c72_b_"+w]=CA("Ahora está en %s."%art); c["c72_no_"+w]=CA("¡No, Coquí! Está en %s."%art)
    DIN.update(["c72_a_"+w,"c72_b_"+w,"c72_no_"+w])
def ronda72(s):
    # one round: Luis hides the shell (e: mar or arena, drawn); Carmen says where; he touches the patch of sand (arena) or the sea's edge (mar)
    e="e"+s
    corona=[act("corona72",n=2)] if s=="a" else [{"if":"lost=0","then":[act("corona72",n=3)],"else":[act("corona72",n=2)]}]
    return [{"draw":e,"options":["mar","arena"]},act("esconde72",en="$"+e),
     {"decide":"do","options":["arena","mar"],"pick":"$"+e,"tests":"$"+e,"lock":True,"lead":[],"line":"c72_%s_$%s"%(s,e),
      "right":[{"if":"ok","then":[act("busca72",en="$"+e,ok=1)]+corona+[OK],"else":[act("busca72",en="$"+e,ok=0)]}],
      "wrong":[act("busca72",en="$x",ok=0),"c72_no_$"+e,act("pierde72",en="$"+e),resta(lambda n:act("conchas",n=n))]+X}]
s72={"id":"la-playa","title":"La playa","place":"La playa","scene":"orilla","next":"flota",
 "goal":"Find the pink shell Luis hides, in the sand or at the sea's edge as Carmen says (arena or mar), so that all three towers of the sand castle get their shell: a wrong place lets a wave take the shell or Canelo run off with it.",
 "stake":{"thing":"conchas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["playa","mar","arena","ola"],"formas_foco":{},
 "back_again":["agua","hay","mucho","grande","mira","me gusta","cuidado","viene","se va","vamos","voy","ven","aquí","busca","¿dónde está?","está","no","perro"],
 "also_heard":["concha","torre","foto","hace calor","acá"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"manana","castillo":0,"manta":0}},act("conchas",n=3),{"wait":500},
  # 1: the walk in from the palms (no act named); Carmen runs to the water's edge (no act named); the signed ask on the sea: a small wave over the frog's feet
  {"dots":1},"c72_mira","c72_ca_playa","c72_ab_mar",ask("mar","c72_donde_mar",after=[act("ola",t="pequena")]),"c72_l_ola",
  # 2: Luis kneels, sand through his fingers; the three towers (the first one, then Carmen's two); a speaking turn (vamos); the frog at the edge; a wave comes and goes
  {"dots":2},gesto("luis","arrodilla"),"c72_l_arena"]+con(act("torres72"),"c72_l_torre")+["c72_ca_agua","c72_cq_vamos",act("ir",a=EDGE)]+con(act("ola",t="pequena"),"c72_ca_viene")+[
  # 3: Luis shows the three shells and hides one in the dry sand; the signed ask on the smooth patch; the shell goes on the first tower
  {"dots":3},gesto("luis","senala",a="conchas"),act("esconde72",en="arena"),"c72_ca_busca",ask("arena","c72_donde_arena",after=[act("busca72",en="arena",ok=1)]),act("corona72",n=1),
  # 4: a shell dropped in the shallow water; the signed ask on the sea; the shell goes on the second tower; a big wave runs up
  {"dots":4},act("esconde72",en="mar"),"c72_ca_ahora_mar",ask("mar","c72_donde_mar",after=[act("busca72",en="mar",ok=1)]),act("corona72",n=2)]+con(act("ola",t="grande"),"c72_ab_cuidado")+[
  # 5: the turn: Luis takes the two shells off and shows three again (the taking off: no act named); Canelo sits up, abuela takes out her camera (no act named); the first shell goes on, no touch; the card shows two places
  {"dots":5},act("conchas",n=3),act("corona72",n=1),"c72_ab_torres",CARD,{"wait":400},
  # 6: A. 7: B. Each drawn afresh
  {"dots":6}]+ronda72("a")+[{"dots":7}]+ronda72("b"),
 "final":[{"dots":8},baja3(lambda n:act("final72",n=n)),   # 8: the castle, by the shells left
  {"dots":9},"c72_ab_foto","c72_cq_voy",act("ir",a=HIGH),act("foto"),"c72_fin",act("fin")],
 "leer":["c72_mira","c72_ca_playa","c72_ab_mar","c72_donde_mar","c72_l_ola","c72_l_arena","c72_l_torre","c72_ca_agua","c72_cq_vamos","c72_ca_viene","c72_ca_busca","c72_donde_arena","c72_ca_ahora_mar","c72_ab_cuidado","c72_ab_torres",
  "c72_a_mar","c72_b_arena","c72_ab_foto","c72_cq_voy","c72_fin"]}
s72=reuse(s72,{"c72_cq_vamos":TG(("vamos",["vamos"])),"c72_cq_voy":TG(("voy",["voy"]))})
json.dump(s72,open("cuentos/la-playa.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 73. ¿Flota? ----------------
# Two toy boats on the wet sand; their colours are two of rojo, azul, amarillo (never the opening's verde and blanco), drawn each round; Luis says which floats and which does not (which is said first: drawn; which colour floats: drawn; which side: drawn).
# A miss: the boat goes down just short of Carmen, in the deep water; the frog swims back; the shell is gone.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c73_l_mira":L("Mira, Coquí: allá hay un bote. Es grande. Está lejos."),"c73_donde_bote":N("¿Dónde está el bote?"),"c73_ca_no_hondo":CA("Aquí no está hondo."),"c73_ca_hondo":CA("¡Uy! Aquí está hondo."),
 "c73_ab_cuidado":AB("¡Carmen, cuidado! Allá está hondo."),"c73_l_dos":L("Yo tengo dos botes. El bote verde flota."),"c73_l_flota":L("¡Mira! ¡Flota!"),"c73_l_no_flota":L("El bote blanco no flota. No flota."),
 "c73_cual_flota":N("¿Cuál bote flota?"),"c73_l_quieres":L("Coquí, ¿quieres ir en el bote?"),"c73_cq_quiero":T("¡Sí, quiero!"),"c73_l_mas":L("Mira: dos botes más."),"c73_ca_ay":CA("¡Ay! Aquí está hondo."),
 "c73_ca_toma":CA("Toma, Coquí."),"c73_cq_gracias":T("¡Gracias!"),"c73_fin":N("El bote grande flota. Y se va.")})
COL73=["rojo","azul","amarillo"]
for f in COL73:
    c["c73_no_"+f]=L("No, Coquí. El bote %s no flota."%f); DIN.add("c73_no_"+f)
    for z in COL73:
        if z==f: continue
        c["c73_fn_%s_%s"%(f,z)]=L("El bote %s flota. El bote %s no flota."%(f,z)); c["c73_nf_%s_%s"%(f,z)]=L("El bote %s no flota. El bote %s flota."%(z,f))
        DIN.update(["c73_fn_%s_%s"%(f,z),"c73_nf_%s_%s"%(f,z)])
def sorteo73(s):
    # one round's draw, and Luis sets the two boats down: f: the colour that floats, z: the one that does not (never the same), o: which is said first (fn: flota first, nf: no flota first), k: the side of the one that floats; a, b: the colours at bote_a, bote_b
    f,z,e,o,k,j,a,b="f"+s,"z"+s,"e"+s,"o"+s,"k"+s,"j"+s,"c"+s,"d"+s
    return [{"draw":f,"options":COL73},{"draw":e,"options":["1","2"]}]+otro(z,f,e,COL73)+[{"draw":o,"options":["fn","nf"]},{"draw":k,"options":["bote_a","bote_b"],"other":j},
     {"calc":a,"cond":k+"=bote_a","then":"$"+f,"else":"$"+z},{"calc":b,"cond":k+"=bote_a","then":"$"+z,"else":"$"+f},act("botes",a="$"+a,b="$"+b)]
def ronda73(s):
    # one round: Luis says which boat floats (the line); he touches a boat. Right: he rides it out with a shell and Carmen ties it on. Wrong: the boat goes down short of Carmen, the shell is gone.
    f,z,o,k="f"+s,"z"+s,"o"+s,"k"+s
    collar=[act("collar",n=2)] if s=="a" else [{"if":"lost=0","then":[act("collar",n=3)],"else":[act("collar",n=2)]}]
    return [{"decide":"do","options":["bote_a","bote_b"],"pick":"$"+k,"tests":"flota","lock":True,"lead":[],"line":"c73_$%s_$%s_$%s"%(o,f,z),
      "right":[{"if":"ok","then":[act("navega73",color="$"+f,ok=1,concha=1)]+collar+[OK],"else":[act("navega73",color="$"+f,ok=1,concha=0)]}],
      "wrong":[act("navega73",color="$"+z,ok=0,concha=1),gesto("carmen","no"),resta(lambda n:act("conchas",n=n)),"c73_ca_ay","c73_no_$"+z]+X}]
s73={"id":"flota","title":"¿Flota?","place":"La playa","scene":"orilla","next":"puedo",
 "goal":"Ride the toy boat that floats out to Carmen, as Luis says by colour, so that all three shells end up on her necklace: a boat that does not float goes down just short of her, in the deep water, and the shell it carried is lost.",
 "stake":{"thing":"conchas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["bote","flota","hondo"],"formas_foco":{"bote":["botes"]},
 "back_again":["mar","ola","playa","agua","rojo","azul","verde","amarillo","blanco","¿cuál?","tengo","dos","grande","cuidado","aquí","allá","lejos","quiero","quieres","gracias","toma","mira","sí","no","es","está","hay"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"mediodia","castillo":0,"manta":0}},act("conchas",n=3),{"wait":500},
  # 1: Luis points out to sea; the signed ask on the fishing boat (it rocks, a gull flies up: no act named)
  {"dots":1},gesto("luis","senala",a="bote"),"c73_l_mira",ask("bote","c73_donde_bote"),
  # 2: Carmen wades, to the ankles, then to the knees; abuela calls; Carmen holds up her string
  {"dots":2},act("vadea",quien="carmen",a="agua1"),"c73_ca_no_hondo",act("vadea",quien="carmen",a="agua2"),"c73_ca_hondo","c73_ab_cuidado",act("collar",n=0),
  # 3: Luis's two boats: the green floats, the white fills (pouring the water away: no act named); the signed ask on the green boat; a speaking turn (quiero); the frog rides it out with a shell, Carmen ties it on
  {"dots":3},act("botes",a="verde",b="blanco"),"c73_l_dos",act("prueba73",color="verde",ok=1),"c73_l_flota",act("prueba73",color="blanco",ok=0),"c73_l_no_flota",
  ask("bote_a","c73_cual_flota"),"c73_l_quieres","c73_cq_quiero",act("navega73",color="verde",ok=1,concha=1),act("collar",n=1),
  # 4: the turn: the frog rides back (no act named); two more boats on the wet sand (round A's colours, drawn here); the card shows two places
  {"dots":4}]+sorteo73("a")+["c73_l_mas",CARD,{"wait":400},
  # 5: A. 6: B (draws afresh, Luis sets down two more boats)
  {"dots":5}]+ronda73("a")+[{"dots":6}]+sorteo73("b")+ronda73("b"),
 "final":[{"dots":7},baja3(lambda n:act("final73",n=n)),   # 7: Carmen wades back in; the string, by the shells on it
  {"dots":8},"c73_ca_toma","c73_cq_gracias"]+con(act("bote_va"),"c73_fin")+[act("fin")],
 "leer":["c73_l_mira","c73_donde_bote","c73_ca_no_hondo","c73_ca_hondo","c73_ab_cuidado","c73_l_dos","c73_l_flota","c73_l_no_flota","c73_cual_flota","c73_l_quieres","c73_cq_quiero","c73_l_mas",
  "c73_fn_rojo_azul","c73_nf_rojo_amarillo","c73_ca_toma","c73_cq_gracias","c73_fin"]}
s73=reuse(s73,{"c73_cq_quiero":TG(("quiero",["quiero","sí quiero","si quiero"])),"c73_cq_gracias":TG(("gracias",["gracias"]))})
json.dump(s73,open("cuentos/flota.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 74. ¿Puedo? ----------------
# Two folded towels on the rope; their colours are two of rojo, azul, amarillo, verde, drawn each round; one has dried and one is still wet; abuela says which (which is said first: drawn; which colour is dry: drawn; which side: drawn).
# Round A is Carmen, round B Luis. A miss: the frog brings the wet one; the child jumps; abuela gives a dry one from the pile.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c74_calor":N("Hace calor en la playa. ¡Hace mucho calor!"),"c74_l_puedo_agua":L("Abuela, hace calor. ¿Puedo ir al agua?"),"c74_ab_si_puedes":AB("Sí, puedes."),"c74_ca_puedo_bote":CA("Abuela, ¿puedo ir al bote?"),
 "c74_ab_no_puedes":AB("No, no puedes. Allá está hondo."),"c74_ca_puedo_comer":CA("¿Puedo comer?"),"c74_ab_si_toma":AB("Sí, puedes. Toma."),"c74_l_mojado":L("¡Estoy mojado!"),"c74_ab_toma_seca":AB("Toma. Esta toalla está seca."),
 "c74_l_ahora":L("Ahora la toalla está mojada. Y yo estoy seco."),"c74_donde_secas":N("¿Dónde hay toallas secas?"),"c74_ab_quieres_agua":AB("Coquí, ¿quieres ir al agua?"),"c74_cq_si":T("¡Sí!"),"c74_ca_coqui_mojado":CA("¡Coquí está mojado!"),
 "c74_cual_seca":N("¿Cuál toalla está seca?"),"c74_ab_tu":AB("Coquí, ahora tú. Quiero tres toallas secas."),"c74_ca_mojada":CA("¡Estoy mojada!"),"c74_ca_uy":CA("¡Uy! ¡Está mojada!"),"c74_l_uy":L("¡Uy! ¡Está mojada!"),
 "c74_l_manana":L("Abuela, ¿puedo venir mañana?"),"c74_ab_si_tu":AB("Sí, puedes. ¿Y tú, Coquí?"),"c74_cq_tambien":T("¡Yo también!"),"c74_fin":N("Coquí está seco. Y hace calor.")})
COL74=["rojo","azul","amarillo","verde"]; FEM={"rojo":"roja","azul":"azul","amarillo":"amarilla","verde":"verde"}
for d in COL74:
    c["c74_no_"+d]=AB("No, Coquí. La toalla %s está mojada."%FEM[d]); DIN.add("c74_no_"+d)
    for w in COL74:
        if w==d: continue
        c["c74_sm_%s_%s"%(d,w)]=AB("La toalla %s está seca. La toalla %s está mojada."%(FEM[d],FEM[w])); c["c74_ms_%s_%s"%(d,w)]=AB("La toalla %s está mojada. La toalla %s está seca."%(FEM[w],FEM[d]))
        DIN.update(["c74_sm_%s_%s"%(d,w),"c74_ms_%s_%s"%(d,w)])
def sorteo74(s):
    # one round's draw, and the two folded towels on the rope: d: the colour that is dry, w: the one that is wet (never the same), o: which is said first (sm: seca first, ms: mojada first), k: the side of the dry one; a, b: the colours at toalla_a, toalla_b
    d,w,e,o,k,j,a,b="d"+s,"w"+s,"e"+s,"o"+s,"k"+s,"j"+s,"a"+s,"b"+s
    return [{"draw":d,"options":COL74},{"draw":e,"options":["1","2","3"]}]+otro(w,d,e,COL74)+[{"draw":o,"options":["sm","ms"]},{"draw":k,"options":["toalla_a","toalla_b"],"other":j},
     {"calc":a,"cond":k+"=toalla_a","then":"$"+d,"else":"$"+w},{"calc":b,"cond":k+"=toalla_a","then":"$"+w,"else":"$"+d},act("toallas_cuerda",a="$"+a,b="$"+b)]
def ronda74(s,quien,dice,uy):
    # one round: the child comes out dripping and says so; abuela says which towel is dry (the line); he brings a towel from the rope
    d,w,o,k="d"+s,"w"+s,"o"+s,"k"+s
    return [act("sale74",quien=quien),dice,
     {"decide":"do","options":["toalla_a","toalla_b"],"pick":"$"+k,"tests":"seco","lock":True,"lead":[],"line":"c74_$%s_$%s_$%s"%(o,d,w),
      "right":[{"if":"ok","then":[act("seca74",quien=quien,color="$"+d,ok=1),OK],
                "else":[{"if":k+"=toalla_a","then":[tw("toalla_a"),{"wait":700},tw(None)],"else":[tw("toalla_b"),{"wait":700},tw(None)]}]}],
      "wrong":con(act("seca74",quien=quien,color="$"+w,ok=0),uy)+[resta(lambda n:act("toallas",n=n)),"c74_no_$"+w]+X}]
s74={"id":"puedo","title":"¿Puedo?","place":"La playa","scene":"orilla","next":"la-cara",
 "goal":"Bring each dripping child the dry towel from the rope, as abuela says by colour which is dry and which is wet, so that the three dry towels of the pile stay for the way home: a wet towel handed over costs a dry one from the pile.",
 "stake":{"thing":"toallas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["puedo","puedes","mojado","seco","hace calor"],"formas_foco":{"mojado":["mojada"],"seco":["seca","secas"]},
 "back_again":["playa","mar","agua","bote","hondo","rojo","azul","amarillo","verde","come","pan","abuela","sí","no","cuidado","ahora","mañana","tengo","toma","gracias","también","allá","lejos"],
 "also_heard":["toalla","ir"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"tarde","castillo":0,"manta":1}},act("toallas",n=3),act("toallas_cuerda",a="rojo",b="azul"),act("ir",a="manta_coqui"),gesto("luis","abanica"),gesto("carmen","abanica"),{"wait":500},
  # 1: Luis asks to go to the water and may; Carmen asks to go to the fishing boat and may not (abuela gives her bread from the basket: no act named); Carmen sits down
  {"dots":1},"c74_calor",gesto("luis","senala",a="mar"),"c74_l_puedo_agua","c74_ab_si_puedes",act("al_agua",quien="luis"),gesto("carmen","senala",a="bote"),"c74_ca_puedo_bote","c74_ab_no_puedes",gesto("carmen","sienta"),"c74_ca_puedo_comer","c74_ab_si_toma",
  # 2: Luis comes back dripping; abuela feels the red towel (he rubs himself and hangs it back, dripping: no act named); the signed ask on the pile; a speaking turn (sí); the frog in the water, out, shaking
  {"dots":2},act("sale74",quien="luis"),"c74_l_mojado",gesto("abuela","toca"),"c74_ab_toma_seca","c74_l_ahora",ask("toallas","c74_donde_secas",after=[tw("toallas"),{"wait":700},tw(None)]),
  "c74_ab_quieres_agua","c74_cq_si",act("al_agua",quien="coqui"),act("sale74",quien="coqui"),"c74_ca_coqui_mojado",
  # 3: abuela feels the two towels on the rope; the signed ask on the blue one; abuela rubs the frog dry with it
  {"dots":3},gesto("abuela","toca"),"c74_sm_azul_rojo",ask("toalla_b","c74_cual_seca",after=[act("seca74",quien="coqui",color="azul",ok=1)]),
  # 4: the turn: abuela lies back, her hat over her face; two folded towels on the rope (round A's colours, drawn here); the children run into the water; abuela pats the pile (no act named); the card shows two places
  {"dots":4},gesto("abuela","acuesta")]+sorteo74("a")+[act("al_agua",quien="luis"),act("al_agua",quien="carmen"),"c74_ab_tu",CARD,{"wait":400},
  # 5: A (Carmen). 6: B (Luis; draws afresh, two folded towels on the rope)
  {"dots":5}]+ronda74("a","carmen","c74_ca_mojada","c74_ca_uy")+[{"dots":6}]+sorteo74("b")+ronda74("b","luis","c74_l_mojado","c74_l_uy"),
 "final":[{"dots":7},{"set":{"hora":"ocaso"}},baja3(lambda n:act("final74",n=n)),   # 7: the sun is low; abuela counts the pile (packing the basket: no act named); the towels, by what is left
  {"dots":8},"c74_l_manana","c74_ab_si_tu","c74_cq_tambien","c74_fin",act("fin")],
 "leer":["c74_calor","c74_l_puedo_agua","c74_ab_si_puedes","c74_ca_puedo_bote","c74_ab_no_puedes","c74_ca_puedo_comer","c74_ab_si_toma","c74_l_mojado","c74_ab_toma_seca","c74_l_ahora","c74_donde_secas","c74_ab_quieres_agua","c74_cq_si","c74_ca_coqui_mojado",
  "c74_sm_azul_rojo","c74_cual_seca","c74_ab_tu","c74_sm_amarillo_verde","c74_ms_azul_rojo","c74_l_manana","c74_ab_si_tu","c74_cq_tambien","c74_fin"]}
s74=reuse(s74,{"c74_cq_si":TG(("sí",["sí","si"])),"c74_cq_tambien":TG(("también",["también","tambien","yo también","yo tambien"]))})
json.dump(s74,open("cuentos/puedo.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
# every id the steps name (with no variable in it) is in the story's clips; every `leer` id too; every speaking turn is on a word of an earlier story (the files on disk: places 1 to 6, not the twelve of place 7)
earlier=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in PLACE7: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s72,s73,s74):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:72|73|74)_|si_|yo_|p_n_|b_n_|c_n_|n_|esta_|cq_|abuela)[a-z_0-9$]*)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
