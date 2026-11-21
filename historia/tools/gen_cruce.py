# El cruce (place 5, La calle, scene 4): stories 57, 58, 59. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/cruce.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `cruce` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: gen_esquina, gen_parada, gen_tiendas, gen_cruce (each sees only what was recorded before it).
#
# Where the Needs list leaves a value open, this file fixes it in ONE place (and the report says so):
#   TRAE: the thing `toma` brings back is named by the place it comes from (tienda: the kite, colmado: the loaf, farmacia: the small bag); no value is listed in Needs.
#   HORA: `hora` has three states in Needs ("mediodia, tarde, late afternoon"); the third has no key. 59 uses HORA59 until the designer names it.
#   SPOTS: "fila_atras 1 to 3" and "asiento 1, 2" are written fila_atras1.. and asiento1.. (no underscore before the digit).
#   `toma` {quien}: "abuela" is abuela WITH the frog (57 openings), "luis" is Luis on his bicycle WITH the frog (58), "coqui" is the frog alone, "carmen" is Carmen.
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); PE=lambda t:D("pepe","Don Pepe",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
SA=lambda t:D("senora","La señora",t); SE=lambda t:D("senor","El señor",t); PA=lambda t:D("papa","Papá",t)
OB=lambda t:D("obrero","El obrero",t); PI=lambda t:D("piraguero","El piragüero",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
HORA59="tarde"                                            # the script's third state ("late afternoon") has no key: placeholder, see the header
TRAE_FARMACIA="farmacia"
# The new words of stories 48 to 56 (their files are not on disk when this runs): the speaking turns of 57 to 59 may use them, and the back_again lists name them.
FOCUS_48_56=["calle","carro","guagua","bicicleta","esquina","gente","cruza","pasa","viene","va","ahora","después","parada","¿para dónde vas?","voy","vas","se monta","se baja","llega","se va","cerca","lejos","temprano","tarde",
             "tienda","banco","farmacia","correo","edificio","alto","nuevo","escuela","hospital","abierto","cerrado","entra"]
MINE=("izquierda-o-derecha","sigue-derecho","al-frente-y-detras")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c57_senor_$da"): never renamed
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
# What he hears when he pokes a person already recorded (the new ones add nothing: don Pepe, the obrero, the things)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora.")),"abuelo":("n_abuelo",N("Este es abuelo.")),"mama":("esta_es_mama",N("Esta es mamá.")),
    "papa":("n_papa",N("Este es papá.")),"bebe":("n_bebe",N("Este es el bebé.")),"perro":("c_n_perro",N("Es el perro. Se llama Canelo.")),"piraguero":("b_n_piraguero",N("Es el piragüero."))}
def nombres(*ks):
    return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}

# ---------------- 57. ¿Izquierda o derecha? ----------------
# The frog goes for a kite (tienda) and a loaf (colmado), in a drawn order (la: round A's place, lb: round B's). Each round on its own: the street said, izq or der (da, db).
# Round A asks the señor, round B asks Carmen. Nobody points in a round. A miss: the frog walks out along the other street, comes back, trips on abuela's bag: a part of the water runs out.
c=dict(comunes); nm,nc=nombres("abuela","coqui","senor","senora","carmen"); c.update(nc)
c.update({"c57_cruce":N("Abuela y Coquí están en el cruce."),"c57_ab_carta":AB("Tengo una carta."),"c57_pepe_hola":PE("¡Hola! Coquí, ¿para dónde vas?"),"c57_cq_correo":T("¡Para el correo!"),
 "c57_cq_pepe":T("Perdón, don Pepe. ¿Dónde está el correo?"),"c57_pepe_izq":PE("Dobla a la izquierda, Coquí. A la izquierda."),"c57_para_donde":N("¿Para dónde dobla Coquí?"),"c57_despues":N("Y después..."),
 "c57_ab_correo":AB("¡El correo está a la izquierda!"),"c57_cq_sra":T("Perdón, señora. ¿Dónde está la farmacia?"),"c57_sra_der":SA("Dobla a la derecha. Sí, a la derecha."),
 "c57_ab_farmacia":AB("¡La farmacia está a la derecha!"),"c57_ab_calor":AB("¡Qué calor! Estoy cansada. Coquí, ¿vas tú?"),"c57_cq_voy":T("¡Sí, yo voy!"),
 "c57_ab_gracias":AB("¡Gracias, Coquí! Toma agua."),"c57_cq_gracias":T("¡Gracias, abuela!"),"c57_ab_casa":AB("Y ahora, a casa.")})
for q,F,pre in (("senor",SE,"Perdón, señor. ¿Dónde está %s?"),("carmen",CA,"Carmen, ¿dónde está %s?")):
    for lg,art in (("tienda","la tienda"),("colmado","el colmado")):
        c["c57_cq_%s_%s"%(q,lg)]=T(pre%art); DIN.add("c57_cq_%s_%s"%(q,lg))
    for d,w in (("der","derecha"),("izq","izquierda")):
        c["c57_%s_%s"%(q,d)]=F("Dobla a la %s."%w); c["c57_%s_no_%s"%(q,d)]=F("No, Coquí. Dobla a la %s."%w); DIN.update(["c57_%s_%s"%(q,d),"c57_%s_no_%s"%(q,d)])
def ronda57(s,q,orden):
    # one round: the person stands at the crossing, the frog asks where the place is, the answer is a street (drawn); he touches it
    l,d,o="l"+s,"d"+s,"o"+s    # the place, the street said, the other street
    ir=([act("toma",quien="carmen",por="$"+d)] if q=="carmen" else [])+con(act("toma",quien="coqui",por="$"+d,trae="$"+l),"c57_despues")   # Carmen skips out along the same street ahead of him
    return [{"draw":d,"options":orden,"other":o},act("pasa",quien=q),"c57_cq_%s_$%s"%(q,l),
     {"decide":"do","options":["calle_izq","calle_der"],"pick":"calle_$"+d,"tests":"$"+d,"lock":True,"lead":[],"line":"c57_%s_$%s"%(q,d),
      "right":ir+[star],
      "wrong":[act("vuelve",quien="coqui",por="$"+o),gesto("coqui","lengua"),act("derrama57"),
               {"if":"lost=0","then":[act("botella",n=2)],"else":[act("botella",n=1)]}]+X+["c57_%s_no_$%s"%(q,d)]}]
s57={"id":"izquierda-o-derecha","title":"¿Izquierda o derecha?","place":"La calle","scene":"cruce","next":"sigue-derecho",
 "goal":"Fetch a kite from the tienda and a loaf from the colmado by asking the way at the crossing, and keep abuela's bottle of water: every wrong street ends with the frog tripping on her bag and a part of the water running out.",
 "stake":{"thing":"agua","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["izquierda","derecha","dobla","perdón"],"formas_foco":{},
 "back_again":["calle","correo","farmacia","tienda","colmado","¿para dónde vas?","voy","vas","yo","tú","señor","señora","agua","cansado","después","toma","gracias","casa","ahora","aquí"],
 "also_heard":[],"names":nm,"palabras":{"izq":"izquierda","der":"derecha"},"clips":c,
 "beats":[{"set":{"hora":"mediodia"}},act("botella",n=3),{"wait":500},
  # 1: the crossing; abuela's letter; don Pepe rides up; the first turn (correo)
  "c57_cruce",gesto("abuela","mira",a="calle_izq"),gesto("abuela","mira",a="calle_der"),gesto("abuela","mira",a="calle_recta"),"c57_ab_carta",act("pasa",quien="pepe"),"c57_pepe_hola","c57_cq_correo",
  # 2: don Pepe points left (signed ask on the left street): the post office
  {"dots":1},"c57_cq_pepe",act("senala",quien="pepe",a="izq"),tw("calle_izq"),"c57_pepe_izq",tw(None),
  ask("calle_izq","c57_para_donde",after=con(act("toma",quien="abuela",por="izq"),"c57_despues"),then=[gesto("abuela","manos"),"c57_ab_correo"]),
  # 3: the señora points right (signed ask on the right street): the farmacia, a small bag
  {"dots":2},act("pasa",quien="senora"),"c57_cq_sra",act("senala",quien="senora",a="der"),tw("calle_der"),"c57_sra_der",tw(None),
  ask("calle_der","c57_para_donde",after=con(act("toma",quien="abuela",por="der",trae=TRAE_FARMACIA),"c57_despues"),then=[gesto("abuela","manos"),"c57_ab_farmacia"]),
  # 4: the turn (voy): abuela sits in the shade with the bottle; the card shows two places
  {"dots":3},gesto("abuela","sienta"),gesto("abuela","abanica"),"c57_ab_calor","c57_cq_voy",CARD,{"wait":400},
  # A: the señor. B: Carmen. The kite's and the loaf's places are drawn (la, lb); the street said is drawn afresh each round
  {"dots":4},{"draw":"la","options":["tienda","colmado"],"other":"lb"}]+ronda57("a","senor",["der","izq"])+[{"dots":5}]+ronda57("b","carmen",["izq","der"]),
 "final":[{"dots":6},act("ir",a="asiento_plaza"),"c57_ab_gracias","c57_cq_gracias",   # 7: the two things on the seat; the water left, by what was lost
  {"if":"lost=0","then":[act("final57",n=3)],"else":[{"if":"lost=1","then":[act("final57",n=2)],"else":[act("final57",n=1)]}]},
  {"dots":7},"c57_ab_casa",act("fin")],
 "leer":["c57_cruce","c57_ab_carta","c57_pepe_hola","c57_cq_correo","c57_cq_pepe","c57_pepe_izq","c57_para_donde","c57_despues","c57_ab_correo","c57_cq_sra","c57_sra_der","c57_para_donde","c57_despues","c57_ab_farmacia","c57_ab_calor","c57_cq_voy",
  "c57_cq_senor_tienda","c57_senor_der","c57_despues","c57_cq_carmen_colmado","c57_carmen_izq","c57_despues","c57_ab_gracias","c57_cq_gracias","c57_ab_casa"]}
s57=reuse(s57,{"c57_cq_correo":TG(("correo",["correo"])),"c57_cq_voy":TG(("voy",["voy"])),"c57_cq_gracias":TG(("gracias",["gracias"]))})
json.dump(s57,open("cuentos/izquierda-o-derecha.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 58. Sigue derecho ----------------
# The street to the right is shut (cones, the obrero). The answer is "Sigue derecho..." (recta) or "Dobla a la izquierda y sigue..." (izq), drawn afresh each round; the señora is asked in A, Carmen in B.
# A miss: Luis rides out along the other street and back, puffing, the ice melts a size. After each ride the bicycle on the card moves a step nearer the cart (mapa58).
c=dict(comunes); nm,nc=nombres("luis","coqui","senor","senora","carmen","piraguero"); c.update(nc)
c.update({"c58_van":N("Luis y Coquí van en bicicleta. Tienen hielo para el piragüero."),"c58_luis_donde":L("¿Dónde está el piragüero? Ese señor sabe. ¡Coquí!"),"c58_cq_perdon":T("¡Perdón, señor!"),
 "c58_senor_recto":SE("¿El piragüero? Sigue derecho, hasta el árbol."),"c58_por_donde":N("¿Por dónde sigue Luis?"),"c58_luis_sigue":N("Luis sigue derecho."),"c58_despues":N("Y después..."),
 "c58_pepe_ruta":PE("¿El piragüero? Dobla a la izquierda. Después sigue derecho, hasta la esquina."),"c58_para_donde":N("¿Para dónde dobla Luis?"),"c58_obrero":OB("La calle está cerrada."),
 "c58_luis_hielo":L("¡El hielo! ¡Mira!"),"c58_cq_rapido":T("¡Rápido, Luis!"),"c58_luis_sra":L("Perdón, señora. ¿Dónde está el piragüero?"),
 "c58_pira_gracias":PI("¡Mi hielo! ¡Gracias, Luis! ¡Gracias, Coquí!"),"c58_pira_toma":PI("Toma, Coquí. ¿Está fría?"),"c58_cq_fria":T("¡Sí! ¡Muy fría!"),"c58_van_casa":N("Y después Luis y Coquí van a casa.")})
for q,F in (("sra",SA),("carmen",CA)):
    for d,t in (("recta","Sigue derecho, hasta la esquina."),("izq","Dobla a la izquierda y sigue hasta la esquina.")):
        c["c58_%s_%s"%(q,d)]=F(t); c["c58_%s_no_%s"%(q,d)]=F("No. "+t); DIN.update(["c58_%s_%s"%(q,d),"c58_%s_no_%s"%(q,d)])
def ronda58(s,q,orden,fin):
    # fin: what follows a right ride in this round (the card's bicycle, and in B the piragüero in the square)
    d,o="d"+s,"o"+s
    return [{"draw":d,"options":orden,"other":o},act("pasa",quien="senora" if q=="sra" else "carmen")]+(["c58_luis_sra"] if q=="sra" else [])+[
     {"decide":"do","options":["calle_recta","calle_izq"],"pick":"calle_$"+d,"tests":"$"+d,"lock":True,"lead":[],"line":"c58_%s_$%s"%(q,d),
      "right":con(act("toma",quien="luis",por="$"+d),"c58_despues")+fin,
      "wrong":[act("vuelve",quien="luis",por="$"+o),act("gotea"),{"if":"lost=0","then":[act("hielo",n=2)],"else":[act("hielo",n=1)]}]+X+["c58_%s_no_$%s"%(q,d)]}]
s58={"id":"sigue-derecho","title":"Sigue derecho","place":"La calle","scene":"cruce","next":"al-frente-y-detras",
 "goal":"Ride the block of ice to the piragüero by asking the way at the crossing, with the right street shut: every wrong street melts the block a size.",
 "stake":{"thing":"hielo","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["derecho","sigue","hasta"],"formas_foco":{},
 "back_again":["dobla","izquierda","perdón","calle","bicicleta","esquina","árbol","cerrado","rápido","frío","señor","señora","toma","gracias","van","después","mira","casa"],
 "also_heard":[],"names":nm,"palabras":{"recta":"derecho","izq":"dobla"},"clips":c,
 "beats":[{"set":{"hora":"tarde","cerrada":1}},act("hielo",n=3),act("mapa58",n=0),{"wait":500},
  # 1: the ice, the señor who knows; the first turn (perdón)
  "c58_van",act("pasa",quien="senor"),"c58_luis_donde","c58_cq_perdon",
  # 2: the señor says straight on, to the tree (signed ask on the street straight on); Luis stops under the tree on the way
  {"dots":1},"c58_senor_recto",act("senala",quien="senor",a="recta"),tw("calle_recta"),{"wait":600},tw("arbol"),{"wait":600},tw(None),
  ask("calle_recta","c58_por_donde",after=con(act("toma",quien="luis",por="recta",arbol=1),"c58_luis_sigue","c58_despues")),
  # 3: don Pepe says left, then straight on (signed ask on the left street)
  {"dots":2},act("pasa",quien="pepe"),"c58_pepe_ruta",ask("calle_izq","c58_para_donde",after=con(act("toma",quien="luis",por="izq"),"c58_despues")),
  # 4: the turn (rápido): the ice drips, the obrero says the street is shut; the card shows two places on its road
  {"dots":3},gesto("luis","mira",a="hielo"),act("gotea"),"c58_obrero","c58_luis_hielo",gesto("luis","mira",a="coqui"),"c58_cq_rapido",CARD,{"wait":400},
  # A: the señora (asked by Luis). B: Carmen. The answer is drawn afresh each round
  {"dots":4}]+ronda58("a","sra",["recta","izq"],[star,act("mapa58",n=1)])+[{"dots":5}]+ronda58("b","carmen",["izq","recta"],[act("piraguero58"),star,act("mapa58",n=2)]),
 "final":[{"dots":6},"c58_pira_gracias",act("piraguero58"),   # 7: the piragüero scrapes the block; the piraguas, by the ice left
  {"if":"lost=0","then":[act("final58",n=3)],"else":[{"if":"lost=1","then":[act("final58",n=2)],"else":[act("final58",n=1)]}]},
  {"dots":7},"c58_pira_toma","c58_cq_fria","c58_van_casa",act("fin")],
 "leer":["c58_van","c58_luis_donde","c58_cq_perdon","c58_senor_recto","c58_por_donde","c58_luis_sigue","c58_despues","c58_pepe_ruta","c58_para_donde","c58_despues","c58_obrero","c58_luis_hielo","c58_cq_rapido",
  "c58_luis_sra","c58_sra_recta","c58_despues","c58_carmen_izq","c58_despues","c58_pira_gracias","c58_pira_toma","c58_cq_fria","c58_van_casa"]}
s58=reuse(s58,{"c58_cq_perdon":TG(("perdón",["perdón","perdon"])),"c58_cq_rapido":TG(("rápido",["rápido","rapido"])),"c58_cq_fria":TG(("frío",["fría","fria","frío","frio"]))})
json.dump(s58,open("cuentos/sigue-derecho.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 59. Al frente y detrás ----------------
# Papá says where the frog goes. Round A is at Canelo: behind him or in front of him (da, drawn); round B is at abuela: beside her (the gap on the seat) or in front of her (db, drawn). The picture is spoiled by where he went:
# the wrong place of a "delante" is farther from the camera (only his eyes at an edge: ojos), the wrong place of a "detrás" or an "al lado de" is nearer (his back over a face: espalda).
c=dict(comunes); nm,nc=nombres("abuela","luis","carmen","abuelo","mama","papa","bebe","perro","coqui"); c.update(nc)
c.update({"c59_familia":N("La familia está en el cruce. Papá tiene una cámara."),"c59_pa_foto":PA("¡Una foto de la familia!"),"c59_pa_luis":PA("Luis, al frente de Carmen."),"c59_pa_abuela":PA("Abuela, al frente de mamá."),
 "c59_quien_delante":N("¿Quién está al frente de Carmen?"),"c59_detras":N("Carmen está detrás de Luis. Mamá está detrás de abuela."),
 "c59_lado_luis":N("Carmen está al lado de mamá. Y abuela está al lado de Luis."),"c59_quien_lado_luis":N("¿Quién está al lado de Luis?"),"c59_pa_canelo_aqui":PA("Canelo, ¡aquí!"),
 "c59_entre":N("El bebé está entre abuelo y mamá. Y mamá está entre abuelo y Carmen."),
 "c59_pa_coqui":PA("¿Y Coquí? ¿Dónde está Coquí?"),"c59_cq_aqui":T("¡Aquí!"),"c59_coqui_arbol":N("Coquí está detrás de papá."),"c59_pa_tres":PA("Tres fotos. Y Coquí va en las tres."),
 "c59_uno":PA("¡Uno, dos, tres!"),"c59_pa_yo":PA("¡Y ahora yo también! Coquí, aquí hay un lugar: ¡entre abuela y Luis!"),"c59_ab_mira":AB("Mira la foto. ¿Quién es?"),"c59_cq_soy":T("¡Soy yo!"),
 "c59_fin":N("Coquí está en la foto, entre abuela y Luis. La familia está contenta.")})
for d,w,W in (("detras","detrás","Detrás"),("delante","al frente","Al frente")):
    c["c59_a_%s_canelo"%d]=PA("Coquí, ¡%s de Canelo!"%w); c["c59_a_no_%s_canelo"%d]=PA("No, Coquí. %s de Canelo."%W); DIN.update(["c59_a_%s_canelo"%d,"c59_a_no_%s_canelo"%d])
for d,w,W in (("lado","al lado","Al lado"),("delante","al frente","Al frente")):
    c["c59_b_%s_abuela"%d]=PA("Coquí, ¡%s de abuela!"%w); c["c59_b_no_%s_abuela"%d]=PA("No, Coquí. %s de abuela."%W); DIN.update(["c59_b_%s_abuela"%d,"c59_b_no_%s_abuela"%d])
def ronda59(s,sitios,pick,linea,no,draw,hojas):
    # one round: papá says a place (drawn); he touches one of two places; the flash. `hojas`: the sheets left in the camera after this photo
    d,k="d"+s,"c"+s
    return [draw,{"calc":k,"cond":"%s=delante"%d,"then":"ojos","else":"espalda"},
     {"decide":"do","options":sitios,"pick":pick,"tests":"$"+d,"lock":True,"lead":[],"line":linea,
      "right":[{"if":"ok","then":[act("va59",donde=pick),"c59_uno",act("foto59",ok=1),act("hojas",n=hojas),OK],
                "else":[act("va59",donde=pick),gesto("papa","pulgar")]}],
      "wrong":[act("va59",donde="$x"),"c59_uno",act("foto59",ok=0,como="$"+k),gesto("papa","rie"),gesto("papa","no"),act("hojas",n=hojas)]+X+[no]}]
s59={"id":"al-frente-y-detras","title":"Al frente y detrás","place":"La calle","scene":"cruce","next":None,
 "goal":"Pose where papá says (in front of, behind, beside) for the family photo: every wrong place spoils one of the three photos, and the last one is always a good one.",
 "stake":{"thing":"fotos","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["al lado de","al frente de","detrás","entre"],"formas_foco":{},
 "back_again":["familia","abuela","abuelo","mamá","papá","bebé","aquí","uno","dos","tres","yo","soy","mira","también","contento","hay","ahora"],
 "also_heard":[],"names":nm,"palabras":{"detras":"detrás","delante":"al frente de","lado":"al lado de"},"clips":c,
 "beats":[{"set":{"hora":HORA59}},act("hojas",n=3),act("ir",a="tras_papa"),{"wait":500},
  # 1: the family, the camera; abuelo, mamá and Carmen stand in a row well behind the seat
  "c59_familia","c59_pa_foto",act("pone59",quien="abuelo",donde="fila_atras1"),act("pone59",quien="mama",donde="fila_atras2"),act("pone59",quien="carmen",donde="fila_atras3"),
  # 2: al frente de (signed ask on Luis)
  {"dots":1},"c59_pa_luis",act("pone59",quien="luis",donde="asiento2"),"c59_pa_abuela",act("pone59",quien="abuela",donde="asiento1"),
  ask("luis","c59_quien_delante",then=[gesto("luis","saluda")]),
  # 3: detrás
  {"dots":2},gesto("carmen","hombros"),"c59_detras",
  # 4: al lado de (signed ask on abuela: the one beside Luis); then Canelo comes and lies down in front of the seat
  {"dots":3},"c59_lado_luis",ask("abuela","c59_quien_lado_luis"),"c59_pa_canelo_aqui",act("pone59",quien="perro",donde="suelo_canelo"),
  # 5: entre: mamá holds the bebé up between herself and abuelo
  {"dots":4},act("pone59",quien="bebe",donde="bebe_alto"),"c59_entre",
  # 6: the turn (aquí): papá asks for the frog; the card shows two places and the three sheets
  {"dots":5},"c59_pa_coqui","c59_cq_aqui","c59_coqui_arbol","c59_pa_tres",CARD,{"wait":400},
  # A: at Canelo, behind or in front. B: at abuela, beside or in front. Each drawn afresh
  {"dots":6}]+ronda59("a",["detras_canelo","delante_canelo"],"$da_canelo","c59_a_$da_canelo","c59_a_no_$da_canelo",{"draw":"da","options":["detras","delante"]},2)
  +[{"dots":7}]+ronda59("b",["lado_abuela","delante_abuela"],"$db_abuela","c59_b_$db_abuela","c59_b_no_$db_abuela",{"draw":"db","options":["lado","delante"]},1),
 "final":[{"dots":8},"c59_pa_yo",act("pone59",quien="papa",donde="papa_rodillas"),act("va59",donde="hueco"),act("foto59",ok=1),act("hojas",n=0),   # 9: papá kneels at the seat's left end; the last photo, always a good one; the photos on the seat, by what was lost
  {"if":"lost=0","then":[act("final59",n=3)],"else":[{"if":"lost=1","then":[act("final59",n=2)],"else":[act("final59",n=1)]}]},
  {"dots":9},"c59_ab_mira","c59_cq_soy","c59_fin",act("fin")],
 "leer":["c59_familia","c59_pa_foto","c59_pa_luis","c59_pa_abuela","c59_quien_delante","c59_detras","c59_lado_luis","c59_quien_lado_luis","c59_pa_canelo_aqui","c59_entre","c59_pa_coqui","c59_cq_aqui","c59_coqui_arbol","c59_pa_tres",
  "c59_a_detras_canelo","c59_uno","c59_b_lado_abuela","c59_uno","c59_pa_yo","c59_ab_mira","c59_cq_soy","c59_fin"]}
s59=reuse(s59,{"c59_cq_aqui":TG(("aquí",["aquí","aqui"])),"c59_cq_soy":TG(("yo",["yo"]))})
json.dump(s59,open("cuentos/al-frente-y-detras.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
# every id the steps name (with no variable in it) is in the story's clips; every `leer` id too; every speaking turn is on a word of an earlier story (the new words of 48 to 56, the files on disk, and the stories of this run before it)
earlier=set(FOCUS_48_56)
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s57,s58,s59):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:57|58|59)_|si_|yo_|p_n_|b_n_|cq_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    earlier.update(st["focus_words"])
