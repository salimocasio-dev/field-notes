# El banco de la plaza (place 6, La plaza, scene 1): stories 60, 61, 62. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/plaza.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `plaza` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: the generators of places 4 and 5 first (each sees only what was recorded before it), then this one.
#
# Where the script or its Needs list leaves a value open, this file fixes it in ONE place (and the report says so):
#   BUBBLES (60): `burbuja_a` is the bubble at the LEFT, `burbuja_b` the one at the right; `burbujas` {izq} says which picture (insignia, manos) is at the left. `dice60` {cual} takes the picture (insignia, manos) whose line is said.
#     In the game the right bubble is worked out from the line said (`linea`: llamas = insignia, gusto = manos) and `izq` (both drawn). In the opening (step 3) the badge is at the left.
#   SPOTS: the script names no spot for a beat; these are used (all from the Needs list):
#     60: frog asiento2 at the start, asiento1 for "the seat's end", asiento2 again at the ending; Ana comes in to suelo1 (and sits at asiento1), her mamá to entrada, her abuela to frente2, Beto to frente3 (and climbs up to asiento3);
#         Carmen "comes up to her": frente1; mamá and abuela "walk up": suelo4, suelo5.  61: frog tablero2 at the start; the abuela comes over to frente1, the señora to frente2, the señor to frente3; the frog on the repisa for the cards.
#     62: frog carro_borde; the visitor (key `turista`, also for each later visitor at the cart) at turno; Ana and the first of each pair at ayuda1, the second of the pair at ayuda2; Ana comes back to ayuda1.
#   62: the pair of each round are things `senor`, `senora`, `hombre`, `mujer`, `joven` (dealt out, none twice over the two rounds: `reparte` of four of the five); the helper (ha/hb) and who speaks first (qa/qb) are drawn each round.
#   STAKE keys: `palomas` (60), `tarjetas` (61), `cola` (62): the Needs list names the acts, not the stake things.
#   hora / tablero / carrito: `hora` manana (60), tarde (61), mediodia (62); `tablero` 1 only in 61, `carrito` 1 only in 62 (the other stories set them to 0).
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); SA=lambda t:D("senora","La señora",t); SE=lambda t:D("senor","El señor",t)
AN=lambda t:D("ana","Ana",t); MA=lambda t:D("mama_ana","La mamá de Ana",t); AA=lambda t:D("abuela_ana","La abuela de Ana",t); PI=lambda t:D("piraguero","El piragüero",t)
HO=lambda t:D("hombre","El hombre",t); MU=lambda t:D("mujer","La mujer",t); JO=lambda t:D("joven","El joven",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
# The new words of stories 1 to 59 as they stand when this runs (the files of places 4 and 5 are made by their own generators; the lists are repeated here so that the check below does not depend on them).
FOCUS_48_59=["calle","carro","guagua","bicicleta","esquina","gente","cruza","pasa","viene","va","ahora","después","parada","¿para dónde vas?","voy","vas","se monta","se baja","llega","se va","cerca","lejos","temprano","tarde",
             "tienda","banco","farmacia","correo","edificio","alto","nuevo","escuela","hospital","abierto","cerrado","entra","izquierda","derecha","dobla","perdón","derecho","sigue","hasta","al lado de","al frente de","detrás","entre"]
MINE=("mucho-gusto","de-donde-eres","hablo-espanol")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c61_sa_$da_$qa"): never renamed
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
# What he hears when he pokes a person already recorded (the new ones add nothing: Ana and her family, the visitors, the things)
NM={"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora.")),"hombre":("b_n_hombre",N("Es un hombre.")),"mujer":("b_n_mujer",N("Es una mujer.")),"joven":("b_n_joven",N("Es un joven.")),
    "perro":("c_n_perro",N("Es el perro. Se llama Canelo.")),"piraguero":("b_n_piraguero",N("Es el piragüero."))}
def nombres(*ks):
    return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
PERSONAS=(("senor","El señor",SE),("senora","La señora",SA),("hombre","El hombre",HO),("mujer","La mujer",MU),("joven","El joven",JO))   # the five who can come up in 62

# ---------------- 60. Mucho gusto ----------------
# Two scored rounds, each on its own: a grown-up asks his name (llamas) or Ana tells her his name and she greets him (gusto), drawn; the two answer bubbles change sides, drawn.
# The bubble with the badge says "Me llamo Coquí." (insignia), the one with the two hands "¡Mucho gusto!" (manos). A miss: he says the other line, everybody laughs, a pigeon flies off, she says it again.
c=dict(comunes); nm,nc=nombres("luis","carmen","perro","coqui"); c.update(nc)
ME_LLAMO=best(("tu",None,"Me llamo Coquí.")) if ("tu",None,"Me llamo Coquí.") in EX else "c60_cq_llamas"   # "Me llamo Coquí." is recorded already (story 36): that id
c.update({"c60_nueva":N("Mira. Hay una niña nueva en la plaza."),"c60_luis_ven":L("Coquí, ven."),"c60_cq_voy":T("¡Voy!"),"c60_luis_nombre":L("¡Hola! ¿Cómo te llamas?"),"c60_ana_llamo":AN("Me llamo Ana."),
 "c60_luis_gusto":L("Mucho gusto, Ana. Yo me llamo Luis."),"c60_ana_gusto":AN("Mucho gusto."),
 "c60_ca_nombre":CA("Hola, Ana. Mi nombre es Carmen. Mucho gusto."),"c60_ana_perro":AN("¡Hola, perro! ¿Cómo te llamas?"),"c60_ca_canelo":CA("Su nombre es Canelo."),"c60_donde_canelo":N("¿Dónde está Canelo?"),
 "c60_ana_y_tu":AN("¿Y tú? ¿Cómo te llamas?"),"c60_que_dice":N("¿Qué dice Coquí?"),"c60_ana_gusto_cq":AN("¡Mucho gusto, Coquí! Me gusta el nombre."),"c60_y_ahora":N("¿Y ahora?"),
 ME_LLAMO:T("Me llamo Coquí."),"c60_cq_gusto_ana":T("¡Mucho gusto, Ana!"),"c60_cq_gusto":T("¡Mucho gusto!"),
 "c60_ana_es_coqui_m":AN("Mamá, es Coquí."),"c60_ana_es_coqui_a":AN("Abuela, es Coquí."),
 "c60_ana_pan":AN("¿Tienes pan para las palomas?"),"c60_cq_si_toma":T("¡Sí! Toma."),"c60_luis_jugar":L("¿Quieren jugar?"),"c60_amigos":N("Coquí tiene amigos nuevos.")})
for pre,F in (("ma",MA),("aa",AA)):   # mamá (round A) and abuela (round B): the grown-up's four lines; "No, no." only on the question, since the greeting is said again as it was
    c["c60_%s_llamas"%pre]=F("¡Hola! ¿Cómo te llamas?"); c["c60_%s_gusto"%pre]=F("¡Mucho gusto, Coquí!"); c["c60_%s_hola"%pre]=F("¡Hola, Coquí!"); c["c60_%s_no_llamas"%pre]=F("No, no. ¿Cómo te llamas?")
    DIN.update(["c60_%s_llamas"%pre,"c60_%s_gusto"%pre])
VARS60={"la":["llamas","gusto"],"lb":["llamas","gusto"]}
def ronda60(s,pre,quien,intro):
    # one round: l: the line said (llamas or gusto); i: which picture is at the left; r: the picture of the right bubble; p: the right bubble (burbuja_a is the left one)
    l,i,r,p="l"+s,"i"+s,"r"+s,"p"+s
    sent="c60_%s_$%s"%(pre,l)
    dice_llamas=con(act("dice60",cual="insignia"),ME_LLAMO); dice_gusto=con(act("dice60",cual="manos"),"c60_cq_gusto")
    return [{"draw":l,"options":["llamas","gusto"]},{"draw":i,"options":["insignia","manos"]},
     {"calc":r,"cond":l+"=llamas","then":"insignia","else":"manos"},
     {"calc":p,"cond":i+"=$"+r,"then":"burbuja_a","else":"burbuja_b"},
     act("burbujas",izq="$"+i)]+intro+[sent,
     {"decide":"do","options":["burbuja_a","burbuja_b"],"pick":"$"+p,"tests":"$"+l,"lock":True,"mudo":True,"lead":[],"line":sent,
      "right":[{"if":l+"=llamas","then":dice_llamas+["c60_%s_hola"%pre],"else":dice_gusto+[act("mano",a="coqui",b=quien)]},{"if":"ok","then":[OK]}],
      "wrong":[{"if":l+"=llamas","then":dice_gusto,"else":dice_llamas},act("rien60"),act("paloma_va")]+X+[{"if":l+"=llamas","then":["c60_%s_no_llamas"%pre],"else":["c60_%s_gusto"%pre]}]}]
s60={"id":"mucho-gusto","title":"Mucho gusto","place":"La plaza","scene":"plaza","next":"de-donde-eres",
 "goal":"Keep three pigeons walking along the seat's back towards the frog's bag of bread by answering each grown-up who greets him or asks his name: an answer that does not fit makes everybody laugh and a pigeon flies off.",
 "stake":{"thing":"palomas","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["¿cómo te llamas?","nombre","mucho gusto"],"formas_foco":{},
 "back_again":["me llamo","me gusta","hola","amigo","mamá","abuela","niña","perro","tiene","pan","sí","toma","mira","ven","voy","hay","nuevo"],
 "also_heard":["palomas","jugar"],"names":nm,"palabras":{"llamas":"¿cómo te llamas?","gusto":"mucho gusto"},"clips":c,
 "beats":[{"set":{"hora":"manana","tablero":0,"carrito":0}},act("palomas",n=3),act("ir",a="asiento2"),{"wait":500},
  # 1: Ana comes across the square with her mamá, her abuela and Beto and stops, shy; Luis waves the frog over (the first turn: voy); they meet
  act("llega",quien="mama_ana",a="entrada"),act("llega",quien="abuela_ana",a="frente2"),act("llega",quien="beto",a="frente3")]+con(act("llega",quien="ana",a="suelo1"),"c60_nueva")+[
  gesto("luis","saluda"),"c60_luis_ven","c60_cq_voy",act("ir",a="asiento1"),"c60_luis_nombre","c60_ana_llamo","c60_luis_gusto",act("mano",a="luis",b="ana"),"c60_ana_gusto",
  # 2: Carmen comes up; Ana kneels to Canelo and asks his name (signed ask on the dog)
  {"dots":1},act("llega",quien="carmen",a="frente1"),"c60_ca_nombre",gesto("ana","arrodilla"),"c60_ana_perro","c60_ca_canelo",ask("perro","c60_donde_canelo"),
  # 3: the two answer bubbles come in inside Ana's own meeting with the frog (two signed asks: the badge, then the hands)
  {"dots":2},"c60_ana_y_tu",act("burbujas",izq="insignia"),
  ask("burbuja_a","c60_que_dice",after=con(act("dice60",cual="insignia"),ME_LLAMO),then=["c60_ana_gusto_cq"]),
  ask("burbuja_b","c60_y_ahora",after=con(act("dice60",cual="manos"),"c60_cq_gusto_ana")+[act("mano",a="coqui",b="ana")]),
  # 4: the turn: her mamá and her abuela walk up; the card shows two places
  {"dots":3},act("llega",quien="mama_ana",a="suelo4"),act("llega",quien="abuela_ana",a="suelo5"),CARD,{"wait":400},
  # A: her mamá (asks his name, or is told it by Ana). B: her abuela (the same game; Ana always tells her first)
  {"dots":4}]+ronda60("a","ma","mama_ana",[{"if":"la=gusto","then":["c60_ana_es_coqui_m"]}])
  +[{"dots":5}]+ronda60("b","aa","abuela_ana",["c60_ana_es_coqui_a"]),
 "final":[{"dots":6},act("ir",a="asiento2"),act("llega",quien="ana",a="asiento1"),gesto("ana","sienta"),act("llega",quien="beto",a="asiento3"),"c60_ana_pan","c60_cq_si_toma",   # 7: the pigeons left decide the picture
  {"if":"lost=0","then":[act("final60",n=3)],"else":[{"if":"lost=1","then":[act("final60",n=2)],"else":[act("final60",n=1)]}]},
  {"dots":7},"c60_luis_jugar",act("sale",quien="luis"),act("sale",quien="carmen"),act("sale",quien="ana"),act("sale",quien="beto"),act("sale",quien="coqui"),"c60_amigos",act("fin")],
 "leer":["c60_nueva","c60_luis_ven","c60_cq_voy","c60_luis_nombre","c60_ana_llamo","c60_luis_gusto","c60_ana_gusto","c60_ca_nombre","c60_ana_perro","c60_ca_canelo","c60_donde_canelo","c60_ana_y_tu","c60_que_dice",ME_LLAMO,"c60_ana_gusto_cq",
  "c60_y_ahora","c60_cq_gusto_ana","c60_ma_llamas",ME_LLAMO,"c60_ma_hola","c60_ana_es_coqui_a","c60_aa_gusto","c60_cq_gusto","c60_ana_pan","c60_cq_si_toma","c60_luis_jugar","c60_amigos"]}
s60=reuse(s60,{"c60_cq_voy":TG(("voy",["voy"])),"c60_cq_si_toma":TG(("sí",["sí","si","sí toma"]))})
json.dump(s60,open("cuentos/mucho-gusto.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 61. ¿De dónde eres? ----------------
# Photos on the notice board: the island (fila_isla) and the city (fila_ciudad). A grown-up says where he is from (soy de) and where he lives (vivo en): one is the island, the other the city (`de` = where he is from, drawn),
# and which half is said first (`primero`: soy or vivo, drawn); each round on its own. The photo goes under the place he is FROM. A miss: the photo hung under the other picture is taken down again, the frog knocks the stone, the wind takes a card.
c=dict(comunes); nm,nc=nombres("luis","carmen","senor","senora","coqui"); c.update(nc)
c.update({"c61_fotos":N("Ana y Coquí tienen fotos de los amigos."),"c61_pr":AN("Esto es Puerto Rico."),"c61_ny":AN("Y esto es Nueva York. Está lejos."),
 "c61_luis_ana":L("Ana, ¿de dónde eres?"),"c61_ana_soy":AN("Soy de Nueva York. Ahora vivo en Puerto Rico."),"c61_q_ana":N("¿De dónde es Ana?"),
 "c61_ana_luis":AN("¿Y tú, Luis? ¿De dónde eres?"),"c61_luis_soy":L("Soy de Puerto Rico. Vivo aquí, cerca."),"c61_q_luis":N("¿De dónde es Luis?"),
 "c61_ana_abuela":AN("Mi abuela vive en Nueva York. Y es de Puerto Rico."),"c61_abuela_si":AA("Sí. Soy de Puerto Rico. Vivo en Nueva York."),"c61_q_abuela":N("¿De dónde es la abuela de Ana?"),
 "c61_ana_coqui":AN("¿Y tú, Coquí? ¿De dónde eres?"),"c61_cq_aqui":T("¡De aquí!"),"c61_ana_mas":AN("Mira, Coquí. ¡Más amigos!"),
 "c61_luis_sra":L("Señora, ¿de dónde es usted?"),"c61_q_sra":N("¿De dónde es la señora?"),"c61_ca_sr":CA("Señor, ¿de dónde es usted?"),"c61_q_sr":N("¿De dónde es el señor?"),
 "c61_ana_vives":AN("Ahora tú, Coquí. ¿Dónde vives?"),"c61_cq_cerca":T("¡Cerca!"),"c61_ana_linda":AN("¡Qué casa más linda!"),"c61_fin":N("Coquí es de Puerto Rico. Y Ana vive en Puerto Rico.")})
PL={"isla":"Puerto Rico","ciudad":"Nueva York"}; OTRA={"isla":"ciudad","ciudad":"isla"}
for pre,F in (("sa",SA),("se",SE)):   # the señora (round A) and the señor (round B): the four sentences the draw can make, and the correction for each place he is from
    for d in ("isla","ciudad"):
        c["c61_%s_%s_soy"%(pre,d)]=F("Soy de %s. Vivo en %s."%(PL[d],PL[OTRA[d]])); c["c61_%s_%s_vivo"%(pre,d)]=F("Vivo en %s. Soy de %s."%(PL[OTRA[d]],PL[d]))
        c["c61_%s_no_%s"%(pre,d)]=F("No, Coquí. Soy de %s."%PL[d])
        DIN.update(["c61_%s_%s_soy"%(pre,d),"c61_%s_%s_vivo"%(pre,d),"c61_%s_no_%s"%(pre,d)])
VARS61={"da":["isla","ciudad"],"db":["isla","ciudad"],"qa":["soy","vivo"],"qb":["soy","vivo"]}
def ronda61(s,quien,pre,l_ask,q_end):
    # one round: d: where he is from, n: the other place; q: which half is said first. The photo hangs under d; the señora (or señor) answers his hanging with a nod or a shake of the head
    d,n,q="d"+s,"n"+s,"q"+s
    sent="c61_%s_$%s_$%s"%(pre,d,q)
    return [{"draw":d,"options":["isla","ciudad"],"other":n},{"draw":q,"options":["soy","vivo"]},l_ask,sent,q_end,
     {"decide":"do","options":["fila_isla","fila_ciudad"],"pick":"fila_$"+d,"tests":"soy de","lock":True,"mudo":True,"lead":[],"line":sent,
      "right":[act("foto61",quien=quien,fila="$"+d,ok=1),{"if":"ok","then":[gesto(quien,"si"),OK]}],
      "wrong":con(act("foto61",quien=quien,fila="$"+n,ok=0),gesto(quien,"no"),"c61_%s_no_$%s"%(pre,d))+[act("vuela61"),{"if":"lost=0","then":[act("tarjetas",n=2)],"else":[act("tarjetas",n=1)]}]+X}]
s61={"id":"de-donde-eres","title":"¿De dónde eres?","place":"La plaza","scene":"plaza","next":"hablo-espanol",
 "goal":"Hang each friend's photo on the notice board under the place the person is from, island or city, and keep the three blank cards under the stone: a photo hung under the wrong picture has to come down again and the wind takes a card.",
 "stake":{"thing":"tarjetas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["¿de dónde eres?","soy de","vivo en"],"formas_foco":{"soy de":["es de"],"vivo en":["vive en","vives"],"¿de dónde eres?":["¿de dónde es?"]},
 "back_again":["casa","abuela","señor","señora","aquí","cerca","lejos","ahora","grande","mira","yo","tú","tiene","amigo","foto","es"],
 "also_heard":["foto","es usted","linda"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"tarde","tablero":1,"carrito":0}},act("tarjetas",n=3),act("ir",a="tablero2"),{"wait":500},
  # 1: the two pictures: the island and the city (Ana points at each)
  "c61_fotos",gesto("ana","senala",a="fila_isla"),"c61_pr",gesto("ana","senala",a="fila_ciudad"),"c61_ny",
  # 2: Ana's own photo (signed ask on the hooks under the city)
  {"dots":1},"c61_luis_ana","c61_ana_soy",ask("fila_ciudad","c61_q_ana",after=[act("foto61",quien="ana",fila="ciudad",ok=1)]),
  # 3: Luis's photo (signed ask on the hooks under the island)
  {"dots":2},"c61_ana_luis","c61_luis_soy",ask("fila_isla","c61_q_luis",after=[act("foto61",quien="luis",fila="isla",ok=1)]),
  # 4: Ana's abuela comes over from the seat: from the island, lives in the city; her photo (signed ask), then the frog's own (the turn: aquí)
  {"dots":3},act("llega",quien="abuela_ana",a="frente1"),"c61_ana_abuela","c61_abuela_si",ask("fila_isla","c61_q_abuela",after=[act("foto61",quien="abuela_ana",fila="isla",ok=1)]),
  "c61_ana_coqui","c61_cq_aqui",gesto("coqui","senala",a="fila_isla"),act("foto61",quien="coqui",fila="isla",ok=1),
  # 5: the turn: the señora and the señor walk up to look at the board; the card shows two places
  {"dots":4},act("llega",quien="senora",a="frente2"),act("llega",quien="senor",a="frente3"),"c61_ana_mas",CARD,{"wait":400},
  # A: the señora (Luis asks her). B: the señor (Carmen asks him). Where he is from and which half comes first are drawn afresh each round
  {"dots":5}]+ronda61("a","senora","sa","c61_luis_sra","c61_q_sra")+[{"dots":6}]+ronda61("b","senor","se","c61_ca_sr","c61_q_sr"),
 "final":[{"dots":7},"c61_ana_vives","c61_cq_cerca",act("ir",a="repisa"),   # 8: the pencil, the cards from under the stone; what he draws, by the cards left
  {"if":"lost=0","then":[act("dibuja61",n=3)],"else":[{"if":"lost=1","then":[act("dibuja61",n=2)],"else":[act("dibuja61",n=1)]}]},
  {"dots":8},"c61_ana_linda","c61_fin",act("fin")],
 "leer":["c61_fotos","c61_pr","c61_ny","c61_luis_ana","c61_ana_soy","c61_q_ana","c61_ana_luis","c61_luis_soy","c61_q_luis","c61_ana_abuela","c61_abuela_si","c61_q_abuela","c61_ana_coqui","c61_cq_aqui","c61_ana_mas",
  "c61_luis_sra","c61_sa_isla_soy","c61_q_sra","c61_ca_sr","c61_se_ciudad_vivo","c61_q_sr","c61_ana_vives","c61_cq_cerca","c61_ana_linda","c61_fin"]}
s61=reuse(s61,{"c61_cq_aqui":TG(("aquí",["aquí","aqui","de aquí"])),"c61_cq_cerca":TG(("cerca",["cerca"]))})
json.dump(s61,open("cuentos/de-donde-eres.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 62. Hablo español ----------------
# Visitors who speak only English (never heard: a bubble with a flag and a picture shows what they ask for). The piragüero asks "¿Quién habla inglés?"; two people come up (from the señor, the señora, the hombre, the mujer and the joven; nobody twice over the two rounds).
# Round A: the helper says "Yo hablo inglés.", the other "Yo solo hablo español." (tests inglés). Round B: the helper "Hablo inglés y español.", the other "No hablo inglés." (tests hablo). Who can help (ha, hb) and who speaks first (qa, qb: the helper h or the other n) are drawn each round.
# A miss: the one he touched listens, shrugs, says "Perdón. No entiendo."; the last one in the line looks at his watch and walks away (the line at the back: 3, 2, 1).
c=dict(comunes); nm,nc=nombres("luis","carmen","senor","senora","hombre","mujer","joven","piraguero","coqui"); c.update(nc)
c.update({"c62_pi_perdon":PI("Perdón. No entiendo. Yo hablo español. No hablo inglés."),"c62_q_habla":N("¿Quién habla inglés?"),
 "c62_ana_entiendes":AN("¿Entiendes, Coquí?"),"c62_cq_no":T("¡No!"),"c62_ana_entiendo":AN("Yo entiendo. Yo hablo inglés y español."),"c62_ana_turista":AN("La turista quiere una piragua."),
 "c62_pi_ahora_no_se":PI("¿Y ahora? No sé."),"c62_luis_no_se":L("Yo no sé. Yo hablo español."),"c62_ana_busca":AN("Busca la guagua."),"c62_ca_parada":CA("¡La parada está cerca!"),
 "c62_pi_no_se":PI("No entiendo. No sé. ¡Y Ana no está!"),"c62_pi_quien":PI("¿Quién habla inglés?"),"c62_pi_ahora_quien":PI("¿Y ahora? ¿Quién habla inglés?"),
 "c62_pi_quieres":PI("¿Quieres una piragua, Coquí?"),"c62_cq_si_favor":T("¡Sí, por favor!"),"c62_ana_yo_hablo":AN("Yo hablo inglés y español. ¡Y tú hablas español, Coquí!"),"c62_fin":N("Coquí habla español. Y come piragua.")})
for k,pre,F in PERSONAS:   # the five who can come up: what each says in round A (ah: the helper, an: the other) and in round B (bh, bn), and the line of the one who cannot help
    c["c62_ah_"+k]=F("Yo hablo inglés."); c["c62_an_"+k]=F("Yo solo hablo español."); c["c62_bh_"+k]=F("Hablo inglés y español."); c["c62_bn_"+k]=F("No hablo inglés."); c["c62_no_"+k]=F("Perdón. No entiendo.")
    DIN.update(["c62_%s_%s"%(x,k) for x in ("ah","an","bh","bn","no")])
VARS62={"ea":[k for k,_,_ in PERSONAS],"na":[k for k,_,_ in PERSONAS],"eb":[k for k,_,_ in PERSONAS],"nb":[k for k,_,_ in PERSONAS]}
def ronda62(s,u,v,l_q,tests):
    # one round: u, v: the two who come up (dealt); h: which of them can help (u or v), q: who speaks first (h: the helper, n: the other); e: the helper, n: the other
    h,q,e,n="h"+s,"q"+s,"e"+s,"n"+s
    return [act("llega",quien="$"+u,a="ayuda1"),act("llega",quien="$"+v,a="ayuda2"),
     {"draw":h,"options":["u","v"]},{"draw":q,"options":["h","n"]},
     {"calc":e,"cond":h+"=u","then":"$"+u,"else":"$"+v},{"calc":n,"cond":h+"=u","then":"$"+v,"else":"$"+u},
     l_q,{"if":q+"=h","then":["c62_%sh_$%s"%(s,e),"c62_%sn_$%s"%(s,n)],"else":["c62_%sn_$%s"%(s,n),"c62_%sh_$%s"%(s,e)]},
     {"decide":"do","options":["$"+u,"$"+v],"pick":"$"+e,"tests":tests,"lock":True,"mudo":True,"lead":[],"line":l_q,
      "right":[act("ayuda62",quien="$"+e,ok=1),act("traduce62",quien="$"+e),act("piragua62"),act("moneda"),{"if":"ok","then":[OK]}],
      "wrong":[act("ayuda62",quien="$"+n,ok=0),"c62_no_$"+n,act("se_va62"),{"if":"lost=0","then":[act("cola",n=2)],"else":[act("cola",n=1)]}]+X}]
s62={"id":"hablo-espanol","title":"Hablo español","place":"La plaza","scene":"plaza","next":"que-hora-es",
 "goal":"Help the visitors who line up at the piragüero's cart by pointing out who speaks English, and keep the three visitors at the back of the line: a helper who cannot help makes the last one in the line look at his watch and walk away.",
 "stake":{"thing":"cola","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["hablo","español","inglés","entiendo","no sé"],"formas_foco":{"hablo":["habla","hablas"],"entiendo":["entiendes"]},
 "back_again":["perdón","quiere","busca","guagua","parada","cerca","piragua","¿quién?","señor","señora","hombre","mujer","joven","yo","tú","sí","no","por favor","gracias","ahora","come"],
 "also_heard":["solo","turista"],"names":nm,"palabras":{"ingles":"inglés","hablo":"hablo"},"clips":c,
 "beats":[{"set":{"hora":"mediodia","tablero":0,"carrito":1}},act("ir",a="carro_borde"),gesto("piraguero","senala",a="carrito"),gesto("piraguero","guino"),{"wait":500},
  # 1: a visitor with a map and a camera walks up (her bubble: the flag and a small piragua); the piragüero cannot understand her; signed ask on her
  act("llega",quien="turista",a="turno"),act("pide62",quien="turista",cosa="piragua"),gesto("piraguero","cabeza"),"c62_pi_perdon",
  ask("turista","c62_q_habla",after=[gesto("turista","senala",a="carrito")]),
  # 2: Ana runs up (a bubble with both flags over her); the first turn: no; she listens, turns to the piragüero: a red piragua, a coin
  {"dots":1},act("llega",quien="ana",a="ayuda1"),"c62_ana_entiendes","c62_cq_no","c62_ana_entiendo",act("traduce62",quien="ana"),gesto("ana","mira",a="turista"),gesto("ana","mira",a="piraguero"),"c62_ana_turista",
  act("piragua62",color="rojo"),act("moneda"),
  # 3: one more thing: a guagua (the flag and a small guagua); nobody here knows; Carmen points across the square; Ana tells the visitor, who waves and goes
  {"dots":2},act("pide62",quien="turista",cosa="guagua"),"c62_pi_ahora_no_se","c62_luis_no_se","c62_ana_busca",gesto("carmen","senala",a="entrada"),"c62_ca_parada",
  act("traduce62",quien="ana"),gesto("turista","saluda"),act("sale",quien="turista"),
  # 4: the turn: her mamá calls, Ana runs off; five more visitors in a line (the first at the cart, three at the back); the card shows two places
  {"dots":3},gesto("mama_ana","llama"),act("sale",quien="ana"),act("llega",quien="turista",a="turno"),act("pide62",quien="turista",cosa="piragua"),act("cola",n=3),gesto("piraguero","hombros"),"c62_pi_no_se",CARD,{"wait":400},
  # the two rounds' four people: dealt out of the five, none twice
  {"reparte":["pa","pb","pc","pd"],"options":[k for k,_,_ in PERSONAS]},
  # A: the piragüero asks, the two answer (tests inglés). B: the next visitor steps up; "¿Y ahora?"; the two answer (tests hablo)
  {"dots":4}]+ronda62("a","pa","pb","c62_pi_quien","ingles")
  +[{"dots":5},act("llega",quien="turista",a="turno"),act("pide62",quien="turista",cosa="piragua")]+ronda62("b","pc","pd","c62_pi_ahora_quien","hablo"),
 "final":[{"dots":6},act("llega",quien="ana",a="ayuda1"),   # 7: Ana helps the visitors still at the back of the line; the jar and the piragua, by the visitors left
  {"if":"lost=0","then":[act("final62",n=3)],"else":[{"if":"lost=1","then":[act("final62",n=2)],"else":[act("final62",n=1)]}]},
  {"dots":7},"c62_pi_quieres","c62_cq_si_favor","c62_ana_yo_hablo","c62_fin",act("fin")],
 "leer":["c62_pi_perdon","c62_q_habla","c62_ana_entiendes","c62_cq_no","c62_ana_entiendo","c62_ana_turista","c62_pi_ahora_no_se","c62_luis_no_se","c62_ana_busca","c62_ca_parada","c62_pi_no_se",
  "c62_pi_quien","c62_ah_mujer","c62_an_hombre","c62_pi_ahora_quien","c62_bn_joven","c62_bh_senora","c62_pi_quieres","c62_cq_si_favor","c62_ana_yo_hablo","c62_fin"]}
s62=reuse(s62,{"c62_cq_no":TG(("no",["no"])),"c62_cq_si_favor":TG(("por favor",["por favor"]))})
json.dump(s62,open("cuentos/hablo-espanol.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# every id the steps name is in the story's clips (an id put together from variables: for every value the variable can take); every `leer` id too; every speaking turn is on a word of an earlier story (the new words of 48 to 59, the files on disk, and the stories of this run before it)
earlier=set(FOCUS_48_59)
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st,VARS in ((s60,VARS60),(s61,VARS61),(s62,VARS62)):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:60|61|62)_|si_|yo_|p_n_|b_n_|c_n_)[a-z_0-9$]+)"',txt))):
        if "$" in i:   # a built id: every value its variables can take must be a clip
            vs=re.findall(r"\$([a-z]+)",i); combos=[i]
            for v in dict.fromkeys(vs): combos=[x.replace("$"+v,val) for x in combos for val in VARS.get(v,["?"+v])]
            for x in combos:
                if x not in st["clips"]: print("MISSING BUILT CLIP",st["id"],i,x)
        elif i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for k,v in st["names"].items():
        if v not in st["clips"]: print("MISSING NAME",st["id"],k,v)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    earlier.update(st["focus_words"])

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
