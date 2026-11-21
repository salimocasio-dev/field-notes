# El cielo (place 7, La playa, scene 4 of 4): stories 81, 82, 83. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/cielo.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `cielo` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: any order among the four scenes of La playa; every speaking turn's word comes from places 1 to 6 (the files of places 1 to 6 must be on disk first: gen_mostrador ... gen_calendario).
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   Draw variables: `viene` (81: viento, sol, nubes; 82: lluvia, frio, viento) and `quien` / `donde` (83), the names the Needs list gives; each round draws on its own (round B draws them again), nothing is excluded.
#       Round A and round B say the same three weathers, each in its own wording (the script's A lines and B lines): c81_a_*, c81_b_*, c82_a_*, c82_b_*. The wrong-move line is one per weather, shared by both rounds.
#   83: the caller is drawn (abuela, luis, carmen) and the place (luna, estrella): six call clips (c83_ll_<quien>_<donde>) and six wrong-move clips (c83_no_<quien>_<donde>); the same caller who calls corrects.
#       The script gives the correction only for the moon ("¡No, Coquí! ¡La luna!"): for the star it is "¡No, Coquí! ¡La estrella grande!" (the call's own words, without "mira").
#   `pick` of the games: a calc turns the drawn weather into the thing key (81: viento -> chiringa, sol -> sombrilla, nubes -> bola; 82: lluvia -> cuerda, frio -> chal, viento -> tapa).
#   `palabras`: the drawn value -> the word the miss is filed under ("nubes" -> nube; "frio" -> hace frío).
#   Right move: the thing's act and `tiempo81` / `tiempo82` {que} start together (`juntos`: the script says "as the wind arrives"). A wrong touch in 81 runs the weather and the failing act of the thing he touched ($x) together;
#       in 82 "what comes finds the table as it was": only `tiempo82` {que} runs, the thing he touched is not acted on. After the correction the `right` steps run again (the same pattern as the other generators).
#   83: `mira83` {a, cae}: cae=1 where the light goes by, 0 where nothing is; the right move is mira83 a=$donde cae=1 and Carmen's wish (`gesto ojos`) only when the first touch was right, and cae=0 after a correction ("only the moon").
#   83: `deseos` {n} is the stake's count of wishes still possible (3 at the start, 2 and 1 after a loss); the opening's two fingers ("two more") are `gesto dedos` n=2. The stake thing is `deseos` (the script's At stake names the three falling lights).
#   83 step 7: the frog's song before the three endings is `canta83` n=0 (the song with no voice answering yet); the voices that answer are `final83` {n}.
#   Counts of the stake after a wrong move (`jugos` 81, `velas` 82, `deseos` 83) are set from `lost`, after the picture and the line, before X (before the cross is counted, lost=0 means this is the first).
#   Start of each story: the sky state (azul / gris / noche), the frog's spot (manta / piso / telescopio) and the stake's count; 82 also puts the awning up, the shawl on the chair's arm, the cover on the floor (the script's Start); 83 puts the shawl on abuela.
#   Before round B (82): the three things back as they were with toldo abajo=0, chal puesto=0, tapa82 puesta=0 (their own acts). In 81 only the umbrella has an act that does it (sombrilla81 abierta=0).
#   (heard) words of a Back again list are in back_again as written AND in also_heard (the precedent of gen_caja).
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); RA=lambda t:D("radio","El radio",t)
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
MINE=("como-esta-el-tiempo","esta-lloviendo","la-luna")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c83_ll_$quien_$donde" gives c83_ll_luis_luna): never renamed
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
# What he hears when he pokes a person already recorded (the radio's man is only heard)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!"))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def sw(var,cases):
    # a chain of `if` on one variable: cases is [(value, steps), ...]; the last case is the `else` (the drawn values are all listed)
    out=cases[-1][1]
    for v,st in reversed(cases[:-1]): out=[{"if":"%s=%s"%(var,v),"then":st,"else":out}]
    return out
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}

# ---------------- 81. ¿Cómo está el tiempo? ----------------
# The radio says what is coming (viento, sol, nubes), drawn each round on its own; the frog gets the kite, the umbrella or the ball ready. A miss: what he got ready meets the weather and ends on the tray, a glass goes over.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c81_radio_cielo":RA("¿Cómo está el tiempo? Hay sol. El cielo está azul."),"c81_donde_cielo":N("¿Dónde está el cielo?"),"c81_ab_calor":AB("Coquí, ¿tienes calor?"),"c81_cq_poco":T("¡Un poco!"),
 "c81_ca_sombrilla":CA("Hay sol. ¡La sombrilla!"),"c81_donde_sombrilla":N("Hay sol. ¿Dónde está la sombrilla?"),
 "c81_radio_viento":RA("¿Cómo está el tiempo ahora? Hay viento. Viene mucho viento."),"c81_ab_viento":AB("¡Viento! ¡Cuidado con la sombrilla!"),"c81_que_vuela":N("Hay viento. ¿Qué vuela con el viento?"),"c81_l_vuela":L("¡Vuela! ¡Mira el cielo!"),
 "c81_l_nube":L("Mira: una nube. Una nube grande."),"c81_radio_nubes":RA("Ahora hay nubes. No hay sol."),"c81_ca_nubes":CA("¡Nubes! No hace calor. ¡A jugar bola!"),"c81_donde_bola":N("Hay nubes. ¿Dónde está la bola?"),
 "c81_ab_tiempo":AB("¿Cómo está el tiempo? Coquí, ¿qué dice el radio?"),
 "c81_ab_jugo":AB("¿Quieres jugo, Coquí?"),"c81_cq_quiero":T("¡Sí, quiero!"),"c81_fin":N("Hay una nube en el cielo. Y Coquí toma jugo.")})
A81={"viento":"Viene viento.","sol":"Sale el sol.","nubes":"Vienen nubes."}; B81={"nubes":"Ahora vienen nubes.","sol":"Ahora sale el sol.","viento":"Ahora viene viento."}
NO81={"viento":"Hay viento.","sol":"Hay sol.","nubes":"Hay nubes."}
for w in ("viento","sol","nubes"):
    c["c81_a_%s"%w]=RA(A81[w]); c["c81_b_%s"%w]=RA(B81[w]); c["c81_no_%s"%w]=AB("¡No, Coquí! "+NO81[w]); DIN.update(["c81_a_%s"%w,"c81_b_%s"%w,"c81_no_%s"%w])
def ronda81(s):
    # one round: the radio says what comes (drawn); he touches the thing to get ready (the umbrella, the kite, the ball)
    right=sw("viene",[("viento",juntos(act("tiempo81",que="viento"),act("vuela81",ok=1))),("sol",juntos(act("tiempo81",que="sol"),act("sombrilla81",abierta=1))),("nubes",juntos(act("tiempo81",que="nubes"),act("bola81",ok=1)))])
    mal=[{"if":"x=sombrilla","then":juntos(act("tiempo81",que="$viene"),act("sombrilla81",abierta=1)),
          "else":[{"if":"x=chiringa","then":juntos(act("tiempo81",que="$viene"),act("vuela81",ok=0)),"else":juntos(act("tiempo81",que="$viene"),act("bola81",ok=0))}]}]
    return [{"draw":"viene","options":["viento","sol","nubes"]},{"calc":"p","cond":"viene=viento","then":"chiringa","else":"bola"},{"calc":"p","cond":"viene=sol","then":"sombrilla","else":"$p"},
     {"decide":"do","options":["sombrilla","chiringa","bola"],"pick":"$p","tests":"$viene","lock":True,"lead":[],"line":"c81_%s_$viene"%s,
      "right":right+[star],
      "wrong":mal+[resta(lambda n:act("jugos",n=n)),"c81_no_$viene"]+X}]
s81={"id":"como-esta-el-tiempo","title":"¿Cómo está el tiempo?","place":"La playa","scene":"cielo","next":"esta-lloviendo",
 "goal":"Get the right thing ready for the weather the radio says is coming (the kite for wind, the umbrella for sun, the ball for clouds) so that the tray of three tall glasses of juice on the blanket stays upright: every wrong thing ends on the tray and a glass goes over.",
 "stake":{"thing":"jugos","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["cielo","nube","viento","¿cómo está el tiempo?"],"formas_foco":{"nube":["nubes"]},
 "back_again":["hace calor","sol","hay","no hay","azul","grande","pequeño","mira","vuela","viene","sale","ahora","jugo","vaso","bola","juega","quiero","un poco","cuidado","abuela","tres","con","sombrilla","chiringa"],
 "also_heard":["sombrilla","chiringa","a jugar"],"names":nm,"palabras":{"viento":"viento","sol":"sol","nubes":"nube"},"clips":c,
 "beats":[{"set":{"cielo":"azul"}},act("ir",a="manta"),act("jugos",n=3),act("sombrilla81",abierta=0),{"wait":500},
  # 1: the radio on; the signed ask on the sky; the first turn (un poco)
  {"dots":1},act("radio",on=1),"c81_radio_cielo",ask("cielo","c81_donde_cielo"),"c81_ab_calor","c81_cq_poco",
  # 2: the signed ask on the umbrella: it opens over the blanket
  {"dots":2},"c81_ca_sombrilla",ask("sombrilla","c81_donde_sombrilla",after=[act("sombrilla81",abierta=1)]),
  # 3: the music again, the leaves stir; Carmen shuts the umbrella; the signed ask on the kite: it climbs
  {"dots":3},act("radio",on=1),act("tiempo81",que="viento"),"c81_radio_viento","c81_ab_viento",act("sombrilla81",abierta=0),
  ask("chiringa","c81_que_vuela",after=[act("vuela81",ok=1)]),"c81_l_vuela",
  # 4: the cloud slides over the sun; the signed ask on the ball: the two kick it to and fro
  {"dots":4},act("tiempo81",que="nubes"),"c81_l_nube","c81_radio_nubes","c81_ca_nubes",ask("bola","c81_donde_bola",after=[act("bola81",ok=1)]),
  # 5: the turn: abuela holds up a hand; the sky is half cloud, half blue; the card shows two places
  {"dots":5},{"set":{"cielo":"nublado"}},gesto("abuela","mano"),"c81_ab_tiempo",CARD,{"wait":400},
  # 6: A. 7: B (the three things back where they were). Each drawn afresh
  {"dots":6}]+ronda81("a")+[{"dots":7},act("sombrilla81",abierta=0)]+ronda81("b"),
 "final":[{"dots":8},{"set":{"cielo":"rosa"}},"c81_ab_jugo","c81_cq_quiero",baja3(lambda n:act("final81",n=n)),   # 8: the sun low, the cloud pink; the tray, by the glasses left
  {"dots":9},"c81_fin",act("fin")],
 "leer":["c81_radio_cielo","c81_donde_cielo","c81_ab_calor","c81_cq_poco","c81_ca_sombrilla","c81_donde_sombrilla","c81_radio_viento","c81_ab_viento","c81_que_vuela","c81_l_vuela","c81_l_nube","c81_radio_nubes","c81_ca_nubes","c81_donde_bola","c81_ab_tiempo",
  "c81_a_viento","c81_b_nubes","c81_ab_jugo","c81_cq_quiero","c81_fin"]}
s81=reuse(s81,{"c81_cq_poco":TG(("un poco",["un poco"])),"c81_cq_quiero":TG(("quiero",["quiero","sí quiero","si quiero"]))})
json.dump(s81,open("cuentos/como-esta-el-tiempo.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 82. Está lloviendo ----------------
# The radio says what is coming (lluvia, frio, viento), drawn each round on its own; the frog makes ready with the awning's cord, the shawl or the glass cover. A miss: what comes finds the table as it was, a candle is lost.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c82_ca_feo":CA("Mira el cielo. Hay nubes grandes. ¡Qué feo!"),"c82_ab_feo":AB("Sí. El cielo está feo."),"c82_radio_lluvia":RA("¿Cómo está el tiempo? Viene lluvia. Mucha lluvia."),"c82_l_lluvia":L("¡Lluvia! ¡Está lloviendo!"),
 "c82_que_bajamos":N("Está lloviendo. ¿Qué bajamos?"),"c82_l_ya_no":L("Ya no está lloviendo."),"c82_ab_frio":AB("¡Uy! Ahora hace frío. Tengo frío."),"c82_que_necesita":N("Hace frío. ¿Qué necesita abuela?"),
 "c82_ab_gracias":AB("Gracias, Coquí. Ya no tengo frío."),"c82_ca_viento":CA("¡Viento!"),"c82_que_ponemos":N("Hay viento. ¿Qué ponemos en la mesa?"),"c82_radio_dia":RA("Hoy, lluvia, viento y frío. ¡Qué día feo! Mañana hay sol: un día bonito."),
 "c82_ca_bonito":CA("¡Un día bonito! Me gusta."),"c82_ab_hambre":AB("Coquí, ¿tienes hambre?"),"c82_cq_hambre":T("¡Sí, tengo hambre!"),"c82_ab_comer":AB("¡A comer! Coquí, ¿qué dice el radio?"),
 "c82_ca_gusta":CA("Mira, Coquí. Ahora el cielo está bonito. ¿Te gusta?"),"c82_cq_gusta":T("¡Sí, me gusta!"),"c82_fin":N("La comida está caliente. Y mañana hay sol.")})
A82={"lluvia":"Viene lluvia.","frio":"Viene frío.","viento":"Viene viento."}; B82={"lluvia":"Ahora viene lluvia.","frio":"Ahora viene frío.","viento":"Ahora viene viento."}
for w,F,t in (("lluvia",L,"¡No, Coquí! ¡Está lloviendo!"),("frio",AB,"¡No, Coquí! Hace frío."),("viento",CA,"¡No, Coquí! Hay viento.")):
    c["c82_no_%s"%w]=F(t); DIN.add("c82_no_%s"%w)
    if w=="viento":    # "El radio dice: Viene viento." / "Ahora viene viento." are word for word 81's lines: the same ids (nothing is recorded twice); `la` holds the id of the round's line
        c["c81_a_viento"]=s81["clips"]["c81_a_viento"]; c["c81_b_viento"]=s81["clips"]["c81_b_viento"]
    else: c["c82_a_%s"%w]=RA(A82[w]); c["c82_b_%s"%w]=RA(B82[w]); DIN.update(["c82_a_%s"%w,"c82_b_%s"%w])
def ronda82(s):
    # one round: the radio says what comes (drawn); he touches the cord, the shawl or the cover. A miss: the weather finds the table as it was.
    right=sw("viene",[("lluvia",juntos(act("toldo",abajo=1),act("tiempo82",que="lluvia"))),("frio",juntos(act("chal",puesto=1),act("tiempo82",que="frio"))),("viento",juntos(act("tapa82",puesta=1),act("tiempo82",que="viento")))])
    return [{"draw":"viene","options":["lluvia","frio","viento"]},{"calc":"p","cond":"viene=lluvia","then":"cuerda","else":"tapa"},{"calc":"p","cond":"viene=frio","then":"chal","else":"$p"},
     {"calc":"la","cond":"viene=viento","then":"c81_%s_viento"%s,"else":"c82_%s_$viene"%s},
     {"decide":"do","options":["cuerda","chal","tapa"],"pick":"$p","tests":"$viene","lock":True,"lead":[],"line":"$la",
      "right":right+[star],
      "wrong":[act("tiempo82",que="$viene"),resta(lambda n:act("velas",n=n)),"c82_no_$viene"]+X}]
s82={"id":"esta-lloviendo","title":"Está lloviendo","place":"La playa","scene":"cielo","next":"la-luna",
 "goal":"Make ready for the weather the radio says is coming (the awning's cord for rain, the shawl for cold, the glass cover for wind) so that the three candles burning on the porch table stay lit: every wrong thing lets the weather put one out or carry it indoors.",
 "stake":{"thing":"velas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["lluvia","está lloviendo","hace frío","bonito","feo"],"formas_foco":{},
 "back_again":["cielo","nube","viento","¿cómo está el tiempo?","hace calor","sol","viene","ahora","mañana","día","abuela","mesa","come","comida","caliente","frío","tengo","tengo hambre","gracias","no","sí","mira","grande","me gusta"],
 "also_heard":["bajamos"],"names":nm,"palabras":{"lluvia":"lluvia","frio":"hace frío","viento":"viento"},"clips":c,
 "beats":[{"set":{"cielo":"gris"}},act("ir",a="piso"),act("velas",n=3),act("toldo",abajo=0),act("chal",puesto=0),act("tapa82",puesta=0),{"wait":500},
  # 1: Carmen looks up; the radio on; the first drop; the signed ask on the awning's cord: it rolls down, the rain drums on it
  {"dots":1},gesto("carmen","mira",a="cielo"),"c82_ca_feo","c82_ab_feo",act("radio",on=1),"c82_radio_lluvia","c82_l_lluvia",
  ask("cuerda","c82_que_bajamos",after=[act("toldo",abajo=1),act("tiempo82",que="lluvia")]),
  # 2: the rain stops, Luis rolls the awning up; the cold: abuela rubs her arms; the signed ask on the shawl
  {"dots":2},act("toldo",abajo=0),"c82_l_ya_no",gesto("abuela","brazos"),"c82_ab_frio",ask("chal","c82_que_necesita",after=[act("chal",puesto=1)]),"c82_ab_gracias",
  # 3: the flames lean; the signed ask on the glass cover; the radio sums up the day, the small sun in its bubble
  {"dots":3},"c82_ca_viento",ask("tapa","c82_que_ponemos",after=[act("tapa82",puesta=1)]),act("radio",on=1),"c82_radio_dia",act("radio",sol=1),"c82_ca_bonito",
  # 4: a speaking turn (tengo hambre)
  {"dots":4},"c82_ab_hambre","c82_cq_hambre",
  # 5: the turn: the shawl off, the cover off, the awning up; the card shows two places
  {"dots":5},act("chal",puesto=0),act("tapa82",puesta=0),"c82_ab_comer",CARD,{"wait":400},
  # 6: A. 7: B (the three things back as they were). Each drawn afresh
  {"dots":6}]+ronda82("a")+[{"dots":7},act("toldo",abajo=0),act("chal",puesto=0),act("tapa82",puesta=0)]+ronda82("b"),
 "final":[{"dots":8},{"set":{"cielo":"rosa"}},baja3(lambda n:act("final82",n=n)),   # 8: the clouds out to sea, the sky pink; they eat; the table, by the candles left
  {"dots":9},"c82_ca_gusta","c82_cq_gusta","c82_fin",act("fin")],
 "leer":["c82_ca_feo","c82_ab_feo","c82_radio_lluvia","c82_l_lluvia","c82_que_bajamos","c82_l_ya_no","c82_ab_frio","c82_que_necesita","c82_ab_gracias","c82_ca_viento","c82_que_ponemos","c82_radio_dia","c82_ca_bonito","c82_ab_hambre","c82_cq_hambre","c82_ab_comer",
  "c82_a_lluvia","c82_b_frio","c82_ca_gusta","c82_cq_gusta","c82_fin"]}
s82=reuse(s82,{"c82_cq_hambre":TG(("tengo hambre",["tengo hambre","sí tengo hambre","si tengo hambre"])),"c82_cq_gusta":TG(("me gusta",["me gusta","sí me gusta","si me gusta"]))})
json.dump(s82,open("cuentos/esta-lloviendo.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 83. La luna ----------------
# Somebody (drawn: abuela, luis, carmen) calls where the next falling light comes (drawn: the moon or the big star), each round on its own; he turns the telescope there. A miss: the telescope swings to the other, the light is gone.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c83_noche":N("Es de noche. El cielo está bonito."),"c83_ab_luna":AB("Mira, Coquí: la luna. Una luna grande y blanca."),"c83_donde_luna":N("¿Dónde está la luna?"),
 "c83_ca_estrella":CA("Y allá hay una estrella. ¡Una estrella grande!"),"c83_donde_estrella":N("¿Dónde está la estrella grande?"),"c83_l_estrellas":L("Una estrella, dos estrellas, tres estrellas... ¡Muchas estrellas! ¡Qué noche bonita!"),
 "c83_ca_luz":CA("¡Mira! ¡Una luz! ¡Al lado de la luna!"),"c83_ab_noche":AB("Me gusta la noche. Coquí, ¿estás cansado?"),"c83_cq_no":T("¡No!"),
 "c83_l_ahora":L("Ahora tú, Coquí. ¡Avanza!"),
 "c83_ab_tarde":AB("Es tarde. A dormir, Coquí."),"c83_cq_hasta":T("¡Hasta mañana!"),"c83_fin":N("Es de noche. Hay luna y hay estrellas. Y Coquí duerme.")})
PRE={"abuela":"Abuela","luis":"Luis","carmen":"Carmen"}; LLAMA={"luna":"la luna","estrella":"la estrella grande"}; NOMBRA={"luna":"¡La luna!","estrella":"¡La estrella grande!"}
for q in PRE:
    for d in LLAMA:
        c["c83_ll_%s_%s"%(q,d)]=D(q,PRE[q],"¡Coquí, mira %s!"%LLAMA[d]); c["c83_no_%s_%s"%(q,d)]=D(q,PRE[q],"¡No, Coquí! "+NOMBRA[d]); DIN.update(["c83_ll_%s_%s"%(q,d),"c83_no_%s_%s"%(q,d)])
def ronda83():
    # one round: somebody calls the place (both drawn); he touches the moon or the big star: the telescope turns there
    return [{"draw":"quien","options":["abuela","luis","carmen"]},{"draw":"donde","options":["luna","estrella"],"other":"otro"},
     {"decide":"do","options":["luna","estrella"],"pick":"$donde","tests":"$donde","lock":True,"lead":[],"line":"c83_ll_$quien_$donde",
      "right":[{"if":"ok","then":[act("mira83",a="$donde",cae=1),gesto("carmen","ojos"),OK],"else":[act("mira83",a="$donde",cae=0)]}],
      "wrong":[act("mira83",a="$otro",cae=0),"c83_no_$quien_$donde",resta(lambda n:act("deseos",n=n))]+X}]
s83={"id":"la-luna","title":"La luna","place":"La playa","scene":"cielo","next":None,
 "goal":"Turn Luis's cardboard telescope to the moon or the big star, whichever is called, so Carmen can make her three wishes on the falling lights: every time it is turned to the wrong one the light is gone before it swings back.",
 "stake":{"thing":"deseos","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["luna","estrella","noche"],"formas_foco":{"estrella":["estrellas"]},
 "back_again":["cielo","nube","bonito","grande","blanco","mira","¿dónde está?","allá","hay","uno","dos","tres","mucho","duerme","cansado","no","me gusta","hasta mañana","abuela","al lado de","tarde","luz"],
 "also_heard":["luz","avanza","a dormir"],"names":nm,"palabras":{"luna":"luna","estrella":"estrella"},"clips":c,
 "beats":[{"set":{"cielo":"noche"}},act("ir",a="telescopio"),act("chal",puesto=1),act("deseos",n=3),{"wait":500},
  # 1: the signed ask on the moon: the telescope turns, the round picture opens
  {"dots":1},"c83_noche","c83_ab_luna",ask("luna","c83_donde_luna",after=[act("mira83",a="luna",cae=0)]),
  # 2: the signed ask on the big star: the telescope swings; Luis counts the stars
  {"dots":2},"c83_ca_estrella",ask("estrella","c83_donde_estrella",after=[act("mira83",a="estrella",cae=0)]),"c83_l_estrellas",
  # 3: a falling light beside the moon (seen without the telescope); the round picture; Carmen wishes; the frog sings, one voice answers; the first turn (no)
  {"dots":3},act("luz83",en="luna"),"c83_ca_luz",act("mira83",a="luna",cae=1),gesto("carmen","ojos"),act("canta83",n=1),"c83_ab_noche","c83_cq_no",
  # 4: the turn: Carmen holds up two fingers; nobody points; the card shows two places
  {"dots":4},gesto("carmen","dedos",n=2),gesto("luis","mira",a="cielo"),gesto("carmen","mira",a="cielo"),gesto("abuela","mira",a="cielo"),"c83_l_ahora",CARD,{"wait":400},
  # 5: A. 6: B. Each drawn afresh
  {"dots":5}]+ronda83()+[{"dots":6}]+ronda83(),
 "final":[{"dots":7},act("canta83",n=0),baja3(lambda n:act("final83",n=n)),   # 7: the frog sings; the voices of the night, by the wishes left
  {"dots":8},"c83_ab_tarde","c83_cq_hasta","c83_fin",act("fin")],
 "leer":["c83_noche","c83_ab_luna","c83_donde_luna","c83_ca_estrella","c83_donde_estrella","c83_l_estrellas","c83_ca_luz","c83_ab_noche","c83_cq_no","c83_l_ahora","c83_ll_luis_luna","c83_ll_abuela_estrella","c83_ab_tarde","c83_cq_hasta","c83_fin"]}
s83=reuse(s83,{"c83_cq_no":TG(("no",["no"])),"c83_cq_hasta":TG(("hasta mañana",["hasta mañana","hasta manana"]))})
json.dump(s83,open("cuentos/la-luna.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
for st in (s81,s82,s83):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:81|82|83)_|si_|yo_|p_n_|b_n_|n_|esta_|cq_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
