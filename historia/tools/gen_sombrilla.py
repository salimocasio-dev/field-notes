# La sombrilla (place 7, La playa, scene 2 of 4): stories 75, 76, 77. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/sombrilla.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `sombrilla` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: any order among the four scenes of La playa; every speaking turn's word comes from places 1 to 6 (this file ignores the stories of the other scenes of place 7 even when they are on disk).
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   Variable names are lower-case letters only (the engine's `$name` reads [a-z]+): pa, pb (the part of each round), ka, kb (the thing that is right), ea, eb (the place the piece goes), ta, tb (77: the thing that helps), qa, qb (77: who speaks).
#   The part of each round is drawn on its own (the script excludes nothing): round B may be the same part as round A. 75: ojo, nariz, boca. 76: cabeza, brazo, mano. 77: cabeza, ojo, pie (the words that are filed: tests).
#   75, 76: the speaker of each round is the one the script's game lines name (75: A Carmen, B Luis; 76: A Luis, B Carmen), and the wrong move is "Luis: ¡No!" then "Carmen: ¡No, Coquí! Va en ..." (75) and "Luis: No, Coquí. Es para ..." (76) in both rounds
#       ("Right and wrong as in A"). Needs says `quien` is a value each round; this file does not draw it (it would double the lines): see the report.
#   75, 76: where the part has two things (the two eyes, the two arms, the two hands) the sign is on the first (ojo_izq, brazo_izq, mano_izq) and the other one is accepted too (`vale`); the piece then goes where he touched, or on the sign's thing after a miss.
#   77: the speaker of round A is drawn (abuela or Carmen), round B is the other (`other`); the part is drawn each round. The line of a round is "Coquí, " + the sentence for the part (the script's A examples drop "Coquí," in the drawn sentences: this file keeps it in all of them).
#       The thing that helps: cabeza -> sombreros, ojo -> gafas, pie -> chancletas.
#   `en` of concha75 / pone76 is a thing key of the face / the figure (ojo_izq, ojo_der, nariz, boca; cabeza, brazo_izq, ..., mano_der); `que` of pone76: pelo, orejas, estrella, piedra; `que` of trae77: the thing key (sombreros, gafas, chancletas).
#   `donde` of duele77: pies, cabeza, ojos (the script's `parte` values); `quien`: carmen, abuela, luis.
#   The wrong move runs in the order of the script: what the frog does, the line(s), the picture's loss (despierta75 / canelo76 / fuera77 and the count act), then the cross and one step (X).
#   concha75 and pone76 with ok=0 are one act in Needs (dropped or put on, and taken out again): called once, at the drop, before the lines.
#   The counts (`zetas` / `caracoles` / `jugadores`) are set after the picture act, from `lost`, before X (as the other generators do).
#   Start spot of the frog: cubo (75, 76), bolsa (77): the spots the script's "Start" names.
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
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time: all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
twk=lambda k:[tw(k),{"wait":600},tw(None)]                # the twinkle of a thing, for a moment
IDS=("la-cara","la-cabeza-y-los-brazos","me-duele")
P7=IDS+("la-playa","flota","puedo","la-ropa-seca","mi-sombrero","se-pone-y-se-quita","como-esta-el-tiempo","esta-lloviendo","la-luna")   # place 7: never seen by this generator
MINE=IDS
# a clip whose text and speaker are already recorded under another id keeps that id (nothing is recorded twice); the stories of this run feed it too, in order.
# Ties go to the id most used, then to the earliest story of the course.
ORD={}
for i,s in enumerate(re.findall(r'"([a-z0-9-]+)"',"".join(re.findall(r'cuentos:\[(.*?)\]',open("curso.js",encoding="utf-8").read(),re.S)))): ORD.setdefault(s,i)
EX=collections.defaultdict(dict)   # (who, habla, text) -> {clip id: [stories that have it, first place in the course]}
def ex_add(cid,cl,o=9999):
    e=EX[(cl.get("who"),cl.get("habla"),cl["text"])].setdefault(cid,[0,o]); e[0]+=1; e[1]=min(e[1],o)
for f in sorted(glob.glob("cuentos/*.json")):
    nm=os.path.basename(f)[:-5]
    if nm in P7 or nm.startswith("z"): continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items(): ex_add(cid,cl,ORD.get(nm,9999))
def best(k): return min(EX[k],key=lambda cid:(-EX[k][cid][0],EX[k][cid][1],cid))
DIN=set()   # ids that are put together in the story ("c75_a_$pa"): never renamed
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
# What he hears when he pokes a person already recorded (the things of the scene that are not people have no line in the script: nothing is made up for them)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "perro":("c_n_perro",N("Es el perro. Se llama Canelo."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}

# ---------------- 75. La cara ----------------
# Abuela sleeps; Luis or Carmen says where the next shell goes: an eye, the nose or the mouth (drawn, each round on its own). The two eyes count as one answer.
# A miss: the shell lands on another with a clack; "¡No!" and the correction; the children clap their hands over their mouths too late: abuela stirs and a Z goes.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c75_durmiendo":N("Abuela está durmiendo."),"c75_ca_mira":CA("Mira, Coquí: una cara. La cara de abuela."),"c75_donde_cara":N("¿Dónde está la cara?"),
 "c75_ca_ojos":CA("Abuela tiene dos ojos. Un ojo va aquí."),"c75_ca_otro_ojo":CA("¿Y el otro ojo?"),
 "c75_l_nariz":L("Y una nariz. Abuela tiene una nariz pequeña."),"c75_donde_nariz":N("¿Dónde va la nariz?"),
 "c75_l_boca":L("Y la boca. Una boca grande."),"c75_ca_boca_no":CA("¡No! La boca de abuela es pequeña."),"c75_donde_boca":N("¿Dónde va la boca?"),
 "c75_ca_mas":CA("Más conchas. Ahora tú, Coquí."),"c75_l_no":L("¡No!"),
 "c75_ab_cara":AB("¡Una cara! ¿Quién es?"),"c75_cq_abuela":T("¡Abuela!"),"c75_ab_linda":AB("¿Soy yo? ¡Qué cara más linda! Estoy contenta.")})
EN75={"ojo":"un ojo","nariz":"la nariz","boca":"la boca"}
for p,t in EN75.items():
    c["c75_a_"+p]=CA("Esta concha va en %s."%t); c["c75_b_"+p]=L("Y esta concha va en %s."%t); c["c75_no_"+p]=CA("¡No, Coquí! Va en %s."%t)
    DIN.update(["c75_a_"+p,"c75_b_"+p,"c75_no_"+p])
def ronda75(s):
    # p: the part (drawn); k: the thing the sign is on (the first eye for ojo); e: where the shell goes. Right: the frog presses the shell in beside the others, Carmen nods. Wrong: it lands on a shell with a clack, ...
    p,k,e="p"+s,"k"+s,"e"+s
    def decide(vale):
        d={"decide":"do","options":["ojo_izq","ojo_der","nariz","boca"],"pick":"$"+k,"tests":"$"+p,"lock":True,"lead":[],"line":"c75_%s_$%s"%(s,p),
           "right":[{"calc":e,"cond":"ok","then":"$x","else":"$"+k},act("concha75",en="$"+e,ok=1),{"if":"ok","then":[gesto("carmen","si"),OK]}],
           "wrong":[act("concha75",en="$x",ok=0),"c75_l_no","c75_no_$"+p]+juntos(gesto("luis","calla"),gesto("carmen","calla"))+[act("despierta75"),resta(lambda n:act("zetas",n=n))]+X}
        if vale: d["vale"]=vale
        return d
    return [{"draw":p,"options":["ojo","nariz","boca"]},{"calc":k,"cond":p+"=ojo","then":"ojo_izq","else":"$"+p},{"if":p+"=ojo","then":[decide(["ojo_der"])],"else":[decide(None)]}]
s75={"id":"la-cara","title":"La cara","place":"La playa","scene":"sombrilla","next":"la-cabeza-y-los-brazos",
 "goal":"Press the shells into the right places of the face the children drew in the sand (an eye, the nose, the mouth) as Luis and Carmen say, so that abuela sleeps on under her umbrella until the surprise is ready: every shell in the wrong place clacks, and one of her three Z's goes.",
 "stake":{"thing":"zetas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["cara","ojo","nariz","boca"],"formas_foco":{"ojo":["ojos"]},
 "back_again":["abuela","duerme","grande","pequeño","dos","uno","una","otro","va","aquí","mira","tiene","cuidado","sí","no","contento","¿dónde está?","¿quién?","es","soy","yo","más","concha","arena"],
 "also_heard":["durmiendo","linda"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"mediodia","dibujo":"circulo"}},act("zetas",n=3),act("ir",a="cubo"),{"wait":500},
  # 1: abuela sleeps; Carmen whispers, a finger to her lips; the signed ask on the circle
  {"dots":1},"c75_durmiendo",gesto("carmen","calla"),"c75_ca_mira",ask("cara","c75_donde_cara",after=twk("cara")),
  # 2: Carmen points at the circle; presses a shell in; the signed ask on the place of the second eye (Carmen's own question)
  {"dots":2},gesto("carmen","senala",a="cara"),"c75_ca_ojos",act("concha75",en="ojo_izq",ok=1),ask("ojo_der","c75_ca_otro_ojo",after=[act("concha75",en="ojo_der",ok=1)]),
  # 3: the nose
  {"dots":3},"c75_l_nariz",ask("nariz","c75_donde_nariz",after=[act("concha75",en="nariz",ok=1)]),
  # 4: the wide mouth, Carmen giggles, Luis hushes her; she rubs it out and draws a small one; the signed ask on it
  {"dots":4},act("boca75",t="grande"),"c75_l_boca",gesto("carmen","rie"),gesto("luis","calla"),"c75_ca_boca_no",act("boca75",t="borrada"),act("boca75",t="pequena"),
  ask("boca","c75_donde_boca",after=[act("concha75",en="boca",ok=1)]),
  # 5: the turn: more shells; the card shows two places
  {"dots":5},"c75_ca_mas",CARD,{"wait":400},
  # 6: A. 7: B. Each drawn afresh
  {"dots":6}]+ronda75("a")+[{"dots":7}]+ronda75("b"),
 "final":[{"dots":8},baja3(lambda n:act("final75",n=n)),   # 8: the last shells and the sun hat; abuela, by the Z's left
  {"dots":9},"c75_ab_cara","c75_cq_abuela","c75_ab_linda",act("fin")],
 "leer":["c75_durmiendo","c75_ca_mira","c75_donde_cara","c75_ca_ojos","c75_ca_otro_ojo","c75_l_nariz","c75_donde_nariz","c75_l_boca","c75_ca_boca_no","c75_donde_boca","c75_ca_mas","c75_a_boca","c75_b_nariz","c75_ab_cara","c75_cq_abuela","c75_ab_linda"]}
s75=reuse(s75,{"c75_cq_abuela":TG(("abuela",["abuela"]))})
json.dump(s75,open("cuentos/la-cara.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 76. La cabeza y los brazos ----------------
# Luis or Carmen holds out a flat stone and says where it goes: the head, an arm or a hand (drawn, each round on its own). The two arms count as one answer, the two hands as one.
# A miss: the stone is put elsewhere and taken off again; Luis carries it back; Canelo takes a spiral shell and buries it.
nm,nc=nombres("abuela","luis","carmen","coqui","perro"); c=dict(comunes); c.update(nc)
c.update({"c76_ca_cabeza":CA("Mira: la cabeza de abuela. Una cabeza grande."),"c76_donde_cabeza":N("¿Dónde está la cabeza?"),"c76_ab_pelo":AB("¿Mi cabeza? ¿Y mi pelo?"),
 "c76_l_pelo":L("Aquí tengo pelo. ¡Pelo verde!"),"c76_ab_pelo_verde":AB("¡Tengo el pelo verde!"),
 "c76_ca_orejas":CA("Y dos orejas. Una oreja aquí, y otra oreja aquí."),"c76_ab_orejas":AB("¡Qué orejas más grandes tengo!"),
 "c76_l_brazos":L("Dos brazos. Un brazo... y otro brazo."),"c76_donde_brazo":N("¿Dónde hay un brazo?"),
 "c76_l_manos":L("Y dos manos. Una mano aquí y otra mano aquí."),"c76_ab_dame":AB("Coquí, dame la mano."),"c76_cq_toma":T("¡Toma!"),
 "c76_ca_estrella":CA("Mira, Coquí: una estrella."),"c76_donde_mano":N("¿Dónde hay una mano?"),"c76_ca_canelo":CA("¡Canelo, no!"),
 "c76_botones3":N("La abuela de arena tiene tres botones."),"c76_botones2":N("La abuela de arena tiene dos botones. Y Canelo tiene uno."),"c76_botones1":N("La abuela de arena tiene un botón. Y Canelo tiene dos."),
 "c76_ab_tengo":AB("Tengo cabeza, pelo, orejas, brazos y manos. ¡Soy yo! ¿Te gusta, Coquí?"),"c76_cq_gusta":T("¡Sí, me gusta!")})
EN76={"brazo":"el brazo","mano":"la mano","cabeza":"la cabeza"}
for p,t in EN76.items():
    c["c76_a_"+p]=L("Toma, Coquí. Esto es para %s de abuela."%t); c["c76_b_"+p]=CA("Y esto es para %s de abuela."%t); c["c76_no_"+p]=L("No, Coquí. Es para %s."%t)
    DIN.update(["c76_a_"+p,"c76_b_"+p,"c76_no_"+p])
def ronda76(s):
    # p: the part (drawn); k: the thing the sign is on (the first arm, the first hand); e: where the stone goes. Right: the stone is set there (a bracelet, a ring, a hat pin). Wrong: it is set elsewhere, taken off, and Canelo buries a spiral shell.
    p,k,e="p"+s,"k"+s,"e"+s
    def decide(vale):
        d={"decide":"do","options":["cabeza","brazo_izq","brazo_der","mano_izq","mano_der"],"pick":"$"+k,"tests":"$"+p,"lock":True,"lead":[],"line":"c76_%s_$%s"%(s,p),
           "right":[{"calc":e,"cond":"ok","then":"$x","else":"$"+k},act("pone76",que="piedra",en="$"+e,ok=1),star],
           "wrong":[act("pone76",que="piedra",en="$x",ok=0),"c76_no_$"+p,act("canelo76"),resta(lambda n:act("caracoles",n=n))]+X}
        if vale: d["vale"]=vale
        return d
    return [{"draw":p,"options":["cabeza","brazo","mano"]},{"calc":k,"cond":p+"=brazo","then":"brazo_izq","else":"$"+p},{"calc":k,"cond":p+"=mano","then":"mano_izq","else":"$"+k},
     {"if":p+"=brazo","then":[decide(["brazo_der"])],"else":[{"if":p+"=mano","then":[decide(["mano_der"])],"else":[decide(None)]}]}]
s76={"id":"la-cabeza-y-los-brazos","title":"La cabeza y los brazos","place":"La playa","scene":"sombrilla","next":"me-duele",
 "goal":"Lay the flat stones on the head, the arms and the hands of the sand abuela where Luis and Carmen say, so that the three spiral shells are still beside her to be her buttons: every stone in the wrong place sends Luis back to the bucket, and Canelo buries a spiral shell.",
 "stake":{"thing":"caracoles","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["cabeza","pelo","oreja","brazo","mano"],"formas_foco":{"brazo":["brazos"],"mano":["manos"],"oreja":["orejas"]},
 "back_again":["cara","ojo","nariz","boca","dos","grande","otro","va","aquí","tiene","tengo","mira","perro","no","sí","dame","toma","más","verde","también","me gusta","soy","yo","es","para","esto"],
 "also_heard":["estrella","botones"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"tarde","dibujo":"figura"}},act("caracoles",n=3),act("ir",a="cubo"),{"wait":500},act("boton76"),
  # 1: the head; the signed ask on it; abuela: "¿Y mi pelo?"; Luis lays seaweed along the top of the head; abuela laughs
  {"dots":1},"c76_ca_cabeza",ask("cabeza","c76_donde_cabeza",after=twk("cabeza")),"c76_ab_pelo","c76_l_pelo",act("pone76",que="pelo",en="cabeza",ok=1),gesto("abuela","rie"),"c76_ab_pelo_verde",
  # 2: the two ears, one at each side of the head
  {"dots":2},"c76_ca_orejas",act("pone76",que="orejas",en="cabeza",ok=1),"c76_ab_orejas",
  # 3: the arms; the signed ask on an arm; the hands; abuela waves her hand: "dame la mano"; a speaking turn (toma); the frog puts his hand in hers
  {"dots":3},"c76_l_brazos",ask("brazo_izq","c76_donde_brazo",after=twk("brazo_izq")),"c76_l_manos",gesto("abuela","saluda"),"c76_ab_dame","c76_cq_toma",act("ir",a="manta"),gesto("coqui","mano"),
  # 4: the starfish; the signed ask on a hand of the figure: Carmen lays the starfish in it
  {"dots":4},"c76_ca_estrella",ask("mano_izq","c76_donde_mano",after=[act("pone76",que="estrella",en="mano_izq",ok=1)]),
  # 5: the turn: the flat stones; Carmen wags a finger at Canelo; the card shows two places
  {"dots":5},gesto("carmen","no"),"c76_ca_canelo",CARD,{"wait":400},
  # 6: A. 7: B. Each drawn afresh
  {"dots":6}]+ronda76("a")+[{"dots":7}]+ronda76("b"),
 "final":[{"dots":8},{"if":"lost=0","then":[act("final76",n=3),"c76_botones3"],"else":[{"if":"lost=1","then":[act("final76",n=2),"c76_botones2"],"else":[act("final76",n=1),"c76_botones1"]}]},   # 8: the buttons, by the spiral shells left
  {"dots":9},"c76_ab_tengo","c76_cq_gusta",act("fin")],
 "leer":["c76_ca_cabeza","c76_donde_cabeza","c76_ab_pelo","c76_l_pelo","c76_ab_pelo_verde","c76_ca_orejas","c76_ab_orejas","c76_l_brazos","c76_donde_brazo","c76_l_manos","c76_ab_dame","c76_cq_toma","c76_ca_estrella","c76_donde_mano","c76_ca_canelo",
  "c76_a_brazo","c76_b_cabeza","c76_botones3","c76_ab_tengo","c76_cq_gusta"]}
s76=reuse(s76,{"c76_cq_toma":TG(("toma",["toma"])),"c76_cq_gusta":TG(("me gusta",["me gusta","sí me gusta","si me gusta"]))})
json.dump(s76,open("cuentos/la-cabeza-y-los-brazos.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 77. Me duele ----------------
# Abuela in one round and Carmen in the other (which comes first is drawn) stands still and says what hurts: the head, the eyes or the feet (drawn, each round on its own). The frog brings a hat, glasses or sandals.
# A miss: she holds the wrong thing and shakes her head; she lies down on the blanket, out of the game.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c77_l_piernas":L("Mira, Coquí. Dos piernas. Una pierna... y otra pierna."),"c77_ca_pies":CA("Y dos pies. Un pie aquí. Y otro pie aquí."),"c77_donde_pies":N("¿Dónde están los pies?"),
 "c77_ca_ay":CA("¡Ay! ¡Una concha! ¡Me duele un pie!"),"c77_ca_pies_duelen":CA("¡Me duelen los pies!"),"c77_que_carmen":N("¿Qué necesita Carmen?"),"c77_ca_gracias":CA("Gracias, Coquí. Ya no me duelen."),
 "c77_ab_sol":AB("¡Qué sol! Me duele la cabeza."),"c77_que_abuela":N("¿Qué necesita abuela?"),"c77_l_ojos":L("Y a mí me duelen los ojos."),"c77_y_luis":N("¿Y Luis? ¿Qué necesita?"),
 "c77_l_jugamos":L("¿Jugamos, Coquí?"),"c77_cq_vamos":T("¡Vamos!"),"c77_l_ay":L("¡Ay, ay, ay!"),
 "c77_l_duele":L("Coquí, ¿te duele la cabeza?"),"c77_cq_no":T("¡No!"),"c77_fin":N("A Coquí no le duele la cabeza. ¡Coquí juega!")})
DUELE77={"cabeza":"me duele la cabeza","ojo":"me duelen los ojos","pie":"me duelen los pies"}
for q,F in (("abuela",AB),("carmen",CA)):
    for p,t in DUELE77.items():
        c["c77_%s_%s"%(q,p)]=F("Coquí, %s."%t); c["c77_no_%s_%s"%(q,p)]=F("No, Coquí. %s%s."%(t[0].upper(),t[1:])); DIN.update(["c77_%s_%s"%(q,p),"c77_no_%s_%s"%(q,p)])
def ronda77(s,q):
    # q: who speaks (drawn: abuela or carmen); p: the part that hurts (drawn); t: the thing that helps. Right: the frog brings it, she puts it on and takes her place again. Wrong: she holds the other thing, shakes her head, and lies down on the blanket.
    p,t="p"+s,"t"+s
    return [{"draw":p,"options":["cabeza","ojo","pie"]},{"calc":t,"cond":p+"=cabeza","then":"sombreros","else":"chancletas"},{"calc":t,"cond":p+"=ojo","then":"gafas","else":"$"+t},
     {"decide":"do","options":["sombreros","gafas","chancletas"],"pick":"$"+t,"tests":"$"+p,"lock":True,"lead":[],"line":"c77_$%s_$%s"%(q,p),
      "right":[act("trae77",que="$"+t,a="$"+q,ok=1),star],
      "wrong":[act("trae77",que="$x",a="$"+q,ok=0),"c77_no_$%s_$%s"%(q,p),act("fuera77",quien="$"+q),resta(lambda n:act("jugadores",n=n))]+X}]
s77={"id":"me-duele","title":"Me duele","place":"La playa","scene":"sombrilla","next":"la-ropa-seca",
 "goal":"Bring abuela and Carmen the hat, the dark glasses or the sandals for the part that hurts (the head, the eyes, the feet) so that all three players are still in the ball game with Luis: whoever is brought the wrong thing gives up and goes to lie down on the blanket.",
 "stake":{"thing":"jugadores","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["pierna","pie","me duele"],"formas_foco":{"me duele":["me duelen","le duele","te duele"],"pie":["pies"],"pierna":["piernas"]},
 "back_again":["cabeza","ojo","mano","brazo","sol","arena","juega","bola","vamos","toma","gracias","ya","también","sí","no","necesito","abuela","otro","hay","concha","sombrero","gafas","chancletas"],
 "also_heard":["jugamos"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"sol","dibujo":"figura"}},act("jugadores",n=3),act("ir",a="bolsa"),{"wait":500},
  # 1: the two legs, the two feet; the signed ask on the feet
  {"dots":1},"c77_l_piernas","c77_ca_pies",ask("pies","c77_donde_pies",after=twk("pies")),
  # 2: Carmen steps on a shell and hops; the sandals twinkle; the signed ask on them
  {"dots":2},act("duele77",quien="carmen",donde="pies"),"c77_ca_ay",act("duele77",quien="carmen",donde="pies"),"c77_ca_pies_duelen"]+twk("chancletas")+[
  ask("chancletas","c77_que_carmen",after=[act("trae77",que="chancletas",a="carmen",ok=1)]),"c77_ca_gracias",
  # 3: abuela's head and the sun hats; Luis's eyes and the dark glasses
  {"dots":3},act("duele77",quien="abuela",donde="cabeza"),"c77_ab_sol",ask("sombreros","c77_que_abuela",after=[act("trae77",que="sombreros",a="abuela",ok=1)]),
  act("duele77",quien="luis",donde="ojos"),"c77_l_ojos",ask("gafas","c77_y_luis",after=[act("trae77",que="gafas",a="luis",ok=1)]),
  # 4: "¿Jugamos?"; a speaking turn (vamos)
  {"dots":4},"c77_l_jugamos","c77_cq_vamos",
  # 5: the turn: a gust of wind; the three things are back beside the bag; abuela and Carmen each with a hand out; the card shows two places
  {"dots":5},act("viento77")]+juntos(gesto("abuela","mano"),gesto("carmen","mano"))+["c77_l_ay",CARD,{"wait":400},
  # 6: A. 7: B. Who comes first is drawn; each part drawn afresh
  {"dots":6},{"draw":"qa","options":["abuela","carmen"],"other":"qb"}]+ronda77("a","qa")+[{"dots":7}]+ronda77("b","qb"),
 "final":[{"dots":8},baja3(lambda n:act("final77",n=n)),   # 8: the ball, by the players left
  {"dots":9},"c77_l_duele","c77_cq_no","c77_fin",act("fin")],
 "leer":["c77_l_piernas","c77_ca_pies","c77_donde_pies","c77_ca_ay","c77_ca_pies_duelen","c77_que_carmen","c77_ca_gracias","c77_ab_sol","c77_que_abuela","c77_l_ojos","c77_y_luis","c77_l_jugamos","c77_cq_vamos","c77_l_ay",
  "c77_abuela_pie","c77_carmen_cabeza","c77_l_duele","c77_cq_no","c77_fin"]}
s77=reuse(s77,{"c77_cq_vamos":TG(("vamos",["vamos"])),"c77_cq_no":TG(("no",["no"]))})
json.dump(s77,open("cuentos/me-duele.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
    if os.path.basename(f)[:-5] in P7: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s75,s76,s77):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:75|76|77)_|si_|yo_|p_n_|b_n_|n_|esta_|cq_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
