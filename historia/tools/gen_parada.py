# La parada (place 5, La calle, scene 2): stories 51, 52, 53. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/parada.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `parada` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir).
# A beat that has no act named for it in the Needs list is left out (no act invented); the builder's report lists them.
# Run order for place 5: gen_esquina (48 to 50), gen_parada, gen_tiendas, gen_cruce (each sees only what was recorded before it).
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); SA=lambda t:D("senora","La señora",t); SE=lambda t:D("senor","El señor",t); CH=lambda t:D("chofer","El chofer",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's twinkle on a thing he can touch
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story of this place has two scored rounds: the card shows two places
# an earlier story's focus words that a speaking turn may use: stories 48 to 50 (not on disk when this was written; their new words, from the order)
FOCUS_48_50=["calle","carro","guagua","bicicleta","esquina","gente","cruza","pasa","viene","va","ahora","después"]
# this generator's stories and the ones after it: not seen (their files may be on disk; nothing here may depend on them)
MINE=("para-donde-vas","se-monta-y-se-baja","cerca-y-lejos","las-tiendas","el-edificio-alto","abierto-y-cerrado","izquierda-o-derecha","sigue-derecho","al-frente-y-detras")
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
DIN=set()   # ids that are put together in the story ("c51_a_$primero_$ab_$fr"): never renamed
def strs(o):   # every string in the steps (not the keys)
    if isinstance(o,str): yield o
    elif isinstance(o,list):
        for x in o: yield from strs(x)
    elif isinstance(o,dict):
        for x in o.values(): yield from strs(x)
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
    played=set(strs([out["beats"],out["final"]]))
    for cid,t in turnos.items():
        cid=ren.get(cid,cid)
        if cid in out["clips"] and cid in played: out["clips"][cid]["tu_turno"]=t
        else: print("MISSING TURN LINE",out["id"],cid)
    for cid,cl in out["clips"].items(): ex_add(cid,cl)
    return out
TG=lambda *p:[{"palabra":w,"formas":list(f)} for w,f in p]
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}
# What he hears when he pokes a person already recorded (the script gives no line for the chofer, Canelo, the guaguas, the doors, the post, the sun or the ball: nothing added for them)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora."))}
def nombres(*ks):
    return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
PL={"arbol":"al parque","toldo":"al colmado","casa":"a casa"}   # the picture of a guagua (tree, awning, house) and where it goes

# ---------------- 51. ¿Para dónde vas? ----------------
# Each round: two of the three pictures (a, b), which stands in front (frente), which is the frog's (mio), which half of abuela's line comes first (primero): all drawn afresh.
# ab is the picture of abuela's guagua, fr the frog's; every ordered pair, in both orders, has its line (12 per round; B's begins "Ahora"); the correction is "Yo voy... Tú vas..." (6, shared by both rounds).
c=dict(comunes); nm,nc=nombres("abuela","luis","carmen","senora","coqui"); c.update(nc)
c.update({"c51_estan":N("Abuela, Luis, Carmen y Coquí están en la parada."),"c51_donde_parada":N("¿Dónde está la parada?"),"c51_sra_dias":SA("¡Buenos días! ¿Estás cansado, Coquí?"),"c51_cq_no_bien":T("No. Estoy bien."),
 "c51_viene":N("La guagua viene a la parada."),"c51_sra_luis":SA("Luis, ¿para dónde vas?"),"c51_luis_voy":L("Voy al parque."),"c51_cual_luis":N("¿Cuál es la guagua de Luis?"),
 "c51_ch_para_donde":CH("¿Para dónde vas?"),"c51_luis_al_parque":L("¡Al parque!"),"c51_ab_carmen":AB("Carmen, tú vas al colmado."),"c51_carmen_voy":CA("Sí. Yo voy al colmado."),
 "c51_cual_carmen":N("¿Cuál es la guagua de Carmen?"),"c51_sra_casa":SA("Yo voy a casa. ¿Y tú, Coquí? ¿Para dónde vas?"),"c51_ab_hoy":AB("Coquí, hoy tú vas en la guagua."),
 "c51_ab_toma":AB("Toma, Coquí."),"c51_cq_gracias":T("¡Gracias, abuela!"),"c51_despues":N("Y después..."),"c51_ab_vamos":AB("Ahora vamos a casa."),
 "c51_ch_hasta":CH("¡Hasta mañana, Coquí!"),"c51_sra_hasta":SA("¡Hasta mañana, Coquí!"),"c51_cq_adios":T("¡Adiós!"),"c51_van":N("Abuela y Coquí van a casa.")})
for ab in PL:
    for fr in PL:
        if ab==fr: continue
        yo,tu="Yo voy %s."%PL[ab],"Tú vas %s."%PL[fr]
        c["c51_no_%s_%s"%(ab,fr)]=AB("No, Coquí. %s %s"%(yo,tu)); DIN.add("c51_no_%s_%s"%(ab,fr))
        for s,ahora in (("a",0),("b",1)):
            for o,(p1,p2) in (("yo",(yo,tu)),("tu",(tu,yo))):
                if ahora: p1="Ahora "+p1[0].lower()+p1[1:]
                i="c51_%s_%s_%s_%s"%(s,o,ab,fr); c[i]=AB("%s %s"%(p1,p2)); DIN.add(i)
def ronda51(s):
    # a, b: the two pictures; frente: which one stands in front (parada1); mio: which one is the frog's; primero: yo or tu comes first in abuela's line
    # pf, pt: the pictures in front and behind; fr, ab: the frog's and abuela's; k: the thing that is right (guagua_a is the one in front, guagua_b the one behind)
    line="c51_%s_$primero_$ab_$fr"%s
    return [{"reparte":["a","b"],"options":["arbol","toldo","casa"]},{"draw":"frente","options":["a","b"]},{"draw":"mio","options":["a","b"]},{"draw":"primero","options":["yo","tu"]},
     {"calc":"pf","cond":"frente=a","then":"$a","else":"$b"},{"calc":"pt","cond":"frente=a","then":"$b","else":"$a"},
     {"calc":"fr","cond":"mio=a","then":"$a","else":"$b"},{"calc":"ab","cond":"mio=a","then":"$b","else":"$a"},
     {"calc":"k","cond":"mio=$frente","then":"guagua_a","else":"guagua_b"},
     {"decide":"do","options":["guagua_a","guagua_b"],"pick":"$k","tests":"vas","lock":True,"mudo":True,
      "lead":[act("guagua",k="$pf",que="llega",a="parada1"),act("guagua",k="$pt",que="llega",a="parada2"),line],"line":line,
      "right":[act("sube",quien="coqui",k="$fr"),act("boleto",quien="coqui"),{"if":"ok","then":[act("sube",quien="abuela",k="$ab")]},
               act("guagua",k="$pf",que="sale",a="parada1"),act("guagua",k="$pt",que="sale",a="parada2"),{"if":"ok","then":[OK]}],
      "wrong":[act("sube",quien="abuela",k="$ab"),act("sube",quien="coqui",k="$ab"),act("boleto",quien="coqui"),gesto("abuela","no"),gesto("abuela","senala",a="$k")]+X+["c51_no_$ab_$fr"]}]
s51={"id":"para-donde-vas","title":"¿Para dónde vas?","place":"La calle","scene":"parada","next":"se-monta-y-se-baja",
 "goal":"Keep abuela's strip of four guagua tickets by sending the frog onto the right guagua each time: a wrong one tears a ticket off for nothing, and what is left decides how they go home.","stake":{"thing":"boletos","steps":2},"dots":7,"bien":"si_muy_bien",
 "focus_words":["parada","¿para dónde vas?","voy","vas"],"formas_foco":{},
 "back_again":["guagua","viene","va","parque","colmado","casa","yo","tú","¿cuál?","señora","abuela","gracias","toma","no","cansado","bien","adiós","hasta mañana","después","ahora","vamos"],
 "also_heard":[],"names":nm,"clips":c,
 "beats":[{"set":{"hora":"manana"}},act("boletos",n=4,quien="abuela"),gesto("senora","sienta"),act("ir",a="bordillo"),{"wait":500},
  # 1: the stop's sign twinkles; the signed ask on the sign and shelter; the señora asks if he is tired (a speaking turn)
  tw("parada"),"c51_estan",tw(None),
  ask("parada","c51_donde_parada",after=[gesto("coqui","salta")],then=["c51_sra_dias","c51_cq_no_bien"]),
  # 2: two guaguas (the tree, the awning); Luis's ride (signed ask on the guagua with the tree)
  {"dots":1},act("guagua",k="arbol",que="llega",a="parada1"),act("guagua",k="toldo",que="llega",a="parada2"),"c51_viene","c51_sra_luis","c51_luis_voy",
  ask("guagua_a","c51_cual_luis",then=["c51_ch_para_donde","c51_luis_al_parque",act("boleto",quien="luis"),act("sube",quien="luis",k="arbol")]),
  # 3: Carmen's ride (signed ask on the guagua with the awning); both drive away
  {"dots":2},"c51_ab_carmen","c51_carmen_voy",
  ask("guagua_b","c51_cual_carmen",then=[act("boleto",quien="carmen"),act("sube",quien="carmen",k="toldo"),act("guagua",k="arbol",que="sale",a="parada1"),act("guagua",k="toldo",que="sale",a="parada2")]),
  # 4: the señora's guagua (the house); where is the frog going?
  {"dots":3},act("guagua",k="casa",que="llega",a="parada1"),"c51_sra_casa",gesto("coqui","mira",a="abuela"),"c51_ab_hoy",act("sube",quien="senora",k="casa"),act("guagua",k="casa",que="sale",a="parada1"),
  # 5: the turn: the strip of four goes to the frog's hand; the card shows two places
  {"dots":4},act("boletos",n=4,quien="coqui"),"c51_ab_toma","c51_cq_gracias",CARD,{"wait":400},
  # 6: A. Then, both ways: a moment, "Y después...", the two guaguas come back
  {"dots":5}]+ronda51("a")+[{"wait":600},"c51_despues",act("vuelve51"),
  # 7: B (drawn afresh); they come back as in A; the sun is low; the señora is on the bench again
  {"dots":6}]+ronda51("b")+[{"wait":600},"c51_despues",act("vuelve51"),{"set":{"hora":"tarde"}},gesto("senora","sienta")],
 "final":[{"dots":7},   # 8: the guagua with the house; what is left of the strip (two, one or none) decides how they go home; 9: the turn, "Abuela y Coquí van a casa."
  act("guagua",k="casa",que="llega",a="parada1"),"c51_ab_vamos",
  {"if":"lost=0","then":[act("final51",n=2),"c51_ch_hasta"],"else":[{"if":"lost=1","then":[act("final51",n=1),"c51_ch_hasta"],"else":[act("final51",n=0),"c51_sra_hasta"]}]},
  "c51_cq_adios","c51_van",act("fin")],
 "leer":["c51_estan","c51_donde_parada","c51_sra_dias","c51_cq_no_bien","c51_viene","c51_sra_luis","c51_luis_voy","c51_cual_luis","c51_ch_para_donde","c51_luis_al_parque","c51_ab_carmen","c51_carmen_voy","c51_cual_carmen","c51_sra_casa","c51_ab_hoy","c51_ab_toma","c51_cq_gracias",
  "c51_a_yo_toldo_arbol","c51_despues","c51_b_yo_casa_toldo","c51_despues","c51_ab_vamos","c51_ch_hasta","c51_cq_adios","c51_van"]}
s51=reuse(s51,{"c51_cq_no_bien":TG(("no",["no"])),"c51_cq_gracias":TG(("gracias",["gracias"])),"c51_cq_adios":TG(("adiós",["adiós","adios"]))})
json.dump(s51,open("cuentos/para-donde-vas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 52. Se monta y se baja ----------------
# Both rounds are at abuela's guagua (the tree, at parada1). `dice` is sube or baja (drawn afresh each round; the values stay as names, the words said are "se monta" and "se baja": see `palabras`); the chofer says it, both groups wait, both doors are shut; he touches the door of the word said.
c=dict(comunes); nm,nc=nombres("abuela","luis","carmen","senor","coqui"); c.update(nc)
c.update({"c52_mira":N("Mira. Llega una guagua."),"c52_carmen_baja":N("Carmen se baja de la guagua."),"c52_donde_carmen":N("¿Por dónde se baja Carmen?"),"c52_se_va":N("La guagua se va."),
 "c52_otra":N("Ahora llega otra guagua. Va al parque."),"c52_ab_monta":N("Abuela se monta en la guagua."),"c52_donde_abuela":N("¿Por dónde se monta abuela?"),"c52_pan_huele":N("El pan huele rico. Canelo tiene hambre."),
 "c52_senor_baja":N("El señor se baja de la guagua."),"c52_donde_senor":N("¿Por dónde se baja el señor?"),"c52_senor_gracias":SE("¡Gracias! ¿Vas al parque, Coquí?"),"c52_cq_si":T("¡Sí!"),
 "c52_ahora_monta_luis":N("Ahora se monta Luis."),"c52_donde_luis":N("¿Por dónde se monta Luis?"),"c52_ch_muy_bien":CH("¡Muy bien, Coquí! Ahora tú."),"c52_llega_otra":N("Llega otra guagua."),
 "c52_ahora_baja":CH("Ahora se baja la gente."),"c52_ahora_sube":CH("Ahora se monta la gente."),"c52_no_baja":CH("No, Coquí. Ahora se baja la gente."),"c52_no_sube":CH("No, Coquí. Ahora se monta la gente."),
 "c52_ch_coqui_monta":CH("¡Coquí! ¡Móntate!"),"c52_ab_quieres":AB("¿Qué quieres, Coquí?"),"c52_cq_pan":T("¡Pan, por favor!"),"c52_se_va_parada":N("La guagua se va de la parada."),"c52_despues":N("Y después llega al parque.")})
def ronda52():
    # dice: sube or baja, drawn; k: the door of the word said
    return [{"draw":"dice","options":["sube","baja"]},{"calc":"k","cond":"dice=baja","then":"puerta_baja","else":"puerta_sube"},
     {"decide":"do","options":["puerta_sube","puerta_baja"],"pick":"$k","tests":"$dice","lock":True,"mudo":True,
      "lead":["c52_ahora_$dice"],"line":"c52_ahora_$dice",
      "right":[act("puerta",cual="$k",abre=1),{"if":"dice=baja","then":[act("gente52",que="baja")],"else":[act("gente52",que="sube")]},{"if":"ok","then":[OK]},
               {"if":"dice=baja","then":[act("gente52",que="sube")],"else":[act("gente52",que="baja")]}],
      "wrong":[act("puerta",cual="$x",abre=1),gesto("chofer","silba"),act("perro52")]+X+["c52_no_$dice"]}]
s52={"id":"se-monta-y-se-baja","title":"Se monta y se baja","place":"La calle","scene":"parada","next":"cerca-y-lejos",
 "goal":"Open the right door for each group, so the three warm rolls on abuela's window sill are still there for the picnic and Canelo, under the bench, gets none.","stake":{"thing":"panes","steps":2},"dots":7,"bien":"si_muy_bien",
 "focus_words":["se monta","se baja","llega","se va"],"formas_foco":{"se monta":["móntate"]},
 "back_again":["guagua","parada","gente","ahora","después","va","pan","huele","rico","tengo hambre","¿qué quieres?","abuela","señor","sí","parque","gracias"],
 "also_heard":[],"names":nm,"palabras":{"sube":"se monta","baja":"se baja"},"clips":c,
 "beats":[{"set":{"hora":"manana"}},act("ir",a="bordillo"),{"wait":500},
  # 1: a guagua with the awning; Carmen knocks at the back door; the button twinkles; signed ask on the back door; she gets off; the guagua drives away
  act("guagua",k="toldo",que="llega",a="parada1"),"c52_mira",act("llama52",quien="carmen"),tw("puerta_baja"),"c52_carmen_baja",tw(None),
  ask("puerta_baja","c52_donde_carmen",after=[act("puerta",cual="puerta_baja",abre=1),act("baja",quien="carmen",k="toldo")],then=[act("guagua",k="toldo",que="sale",a="parada1"),"c52_se_va"]),
  # 2: abuela's guagua (the tree); the button of the front door twinkles; signed ask on the front door; abuela sits at the window with the basket of three rolls
  {"dots":1},act("guagua",k="arbol",que="llega",a="parada1"),"c52_otra",tw("puerta_sube"),"c52_ab_monta",tw(None),
  ask("puerta_sube","c52_donde_abuela",after=[act("puerta",cual="puerta_sube",abre=1),act("sube",quien="abuela",k="arbol"),act("panes",n=3)],then=["c52_pan_huele"]),
  # 3: the señor knocks at the back door; signed ask; he gets off; a speaking turn
  {"dots":2},act("llama52",quien="senor"),"c52_senor_baja",
  ask("puerta_baja","c52_donde_senor",after=[act("puerta",cual="puerta_baja",abre=1),act("baja",quien="senor",k="arbol"),gesto("coqui","salta"),gesto("coqui","mira",a="guagua_a")],then=["c52_senor_gracias","c52_cq_si"]),
  # 4: Luis gets on at the front door
  {"dots":3},"c52_ahora_monta_luis",ask("puerta_sube","c52_donde_luis",after=[act("sube",quien="luis",k="arbol")]),
  # 5: the turn: thumb up; a guagua with the house stops behind; people at the kerb and at the back door's glass; the card shows two places
  {"dots":4},gesto("chofer","pulgar"),"c52_ch_muy_bien",act("guagua",k="casa",que="llega",a="parada2"),"c52_llega_otra",act("gente52",que="viene"),CARD,{"wait":400},
  # 6: A (sube or baja, drawn). Then, both ways: the guagua with the house drives away; new people come
  {"dots":5}]+ronda52()+[act("guagua",k="casa",que="sale",a="parada2"),"c52_se_va",act("gente52",que="viene"),
  # 7: B (the same game, drawn afresh)
  {"dots":6}]+ronda52(),
 "final":[{"dots":7},   # 8: the frog gets on; abuela lifts the cloth; "¿Qué quieres, Coquí?" (a speaking turn); what is left of the rolls (three, two or one); 9: the guagua drives away
  "c52_ch_coqui_monta",act("sube",quien="coqui",k="arbol"),"c52_ab_quieres","c52_cq_pan",
  {"if":"lost=0","then":[act("final52",n=3)],"else":[{"if":"lost=1","then":[act("final52",n=2)],"else":[act("final52",n=1)]}]},
  "c52_se_va_parada",act("guagua",k="arbol",que="sale",a="parada1"),"c52_despues",act("fin")],
 "leer":["c52_mira","c52_carmen_baja","c52_donde_carmen","c52_se_va","c52_otra","c52_ab_monta","c52_donde_abuela","c52_pan_huele","c52_senor_baja","c52_donde_senor","c52_senor_gracias","c52_cq_si","c52_ahora_monta_luis","c52_donde_luis","c52_ch_muy_bien","c52_llega_otra",
  "c52_ahora_baja","c52_se_va","c52_ahora_sube","c52_ch_coqui_monta","c52_ab_quieres","c52_cq_pan","c52_se_va_parada","c52_despues"]}
s52=reuse(s52,{"c52_cq_si":TG(("sí",["sí","si"])),"c52_cq_pan":TG(("pan",["pan"]))})
json.dump(s52,open("cuentos/se-monta-y-se-baja.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 53. Cerca y lejos ----------------
# Each box goes to a house (don Pepe's in A, the señora's in B); abuela says near or far (dice, drawn afresh each round); he walks (the post) or rides (the stop's sign).
# The sun's step (sol n, final53 n): n is the number of steps the sun has moved, 0 to 2 (the steps lost so far).
c=dict(comunes); nm,nc=nombres("abuela","luis","carmen","senor","coqui"); c.update(nc)
c.update({"c53_temprano":N("Es temprano. Abuela y Coquí están en la parada."),"c53_vamos_temprano":AB("Vamos temprano. No quiero llegar tarde."),"c53_cajas":N("Abuela tiene dos cajas. Una es para don Pepe. La otra es para la señora."),
 "c53_colmado_cerca":AB("El colmado está cerca."),"c53_por_donde":N("¿Por dónde camina Coquí?"),"c53_esta_cerca":N("Está cerca. Coquí camina."),"c53_parque_lejos":AB("El parque está lejos."),
 "c53_donde_parada":N("¿Dónde está la parada?"),"c53_esta_lejos":N("Está lejos. Coquí va en guagua."),
 "c53_senor":SE("¡Ay! El colmado está cerca. Pero el parque está lejos. Y hoy la guagua llega tarde."),"c53_espero":AB("Yo espero aquí. Coquí, ¿vas tú?"),"c53_cq_voy":T("Sí. Yo voy."),
 "c53_a_lejos":AB("Esto es para don Pepe. Su casa está lejos."),"c53_a_cerca":AB("Esto es para don Pepe. Su casa está cerca."),
 "c53_b_cerca":AB("Y esto es para la señora. Su casa está cerca."),"c53_b_lejos":AB("Y esto es para la señora. Su casa está lejos."),
 "c53_no_lejos":AB("No, Coquí. Su casa está lejos."),"c53_no_cerca":AB("No, Coquí. Su casa está cerca."),
 "c53_que_bien":AB("¡Qué bien! Es temprano. No es tarde."),"c53_ya_tarde":AB("Ya es tarde. Juega un poco, Coquí, y a casa."),"c53_muy_tarde":AB("Es muy tarde. Mañana jugamos."),
 "c53_cansado":AB("¿Estás cansado, Coquí?"),"c53_cq_no_bien":T("No. Estoy bien."),"c53_cq_cansado":T("Sí. Estoy cansado."),"c53_vamos_casa":AB("Vamos a casa. Está cerca.")})
def ronda53(s):
    # dice: cerca or lejos, drawn; k: the thing that is right (the stop's sign for far, the walking post for near)
    # wrong, far (he walks): the sun moves a step, he comes back late with the box, tongue out; wrong, near (he waits for a guagua): he droops, the sun moves a step
    sol=[{"if":"lost=0","then":[act("sol",n=1)],"else":[act("sol",n=2)]}]
    return [{"draw":"dice","options":["cerca","lejos"]},{"calc":"k","cond":"dice=lejos","then":"parada","else":"poste"},
     {"decide":"do","options":["poste","parada"],"pick":"$k","tests":"$dice","lock":True,"mudo":True,
      "lead":["c53_%s_$dice"%s],"line":"c53_%s_$dice"%s,
      "right":[{"if":"dice=lejos","then":[act("monta53",ok=1)],"else":[act("camina53",ok=1)]},{"if":"ok","then":[OK]}],
      "wrong":[{"if":"dice=lejos","then":[act("camina53",ok=0)]+sol+[gesto("coqui","lengua")],"else":[act("espera53")]+sol}]+X+["c53_no_$dice"]}]
s53={"id":"cerca-y-lejos","title":"Cerca y lejos","place":"La calle","scene":"parada",
 "goal":"Walk to the near houses and ride to the far ones, so the day stays early and there is time left to play with Luis and Carmen's ball.","stake":{"thing":"dia","steps":2},"dots":7,"bien":"si_muy_bien",
 "focus_words":["cerca","lejos","temprano","tarde"],"formas_foco":{},
 "back_again":["parada","guagua","llega","voy","vas","casa","colmado","parque","señor","caja","otro","toma","juega","cansado","bien","no","camina","vamos","espera","aquí","mañana"],
 "also_heard":[],"names":nm,"clips":c,
 "beats":[{"set":{"hora":"temprano"}},act("ir",a="bordillo"),{"wait":500},
  # 1: early morning; the sun twinkles; the two boxes
  tw("sol"),"c53_temprano",tw(None),"c53_vamos_temprano","c53_cajas",
  # 2: the colmado is near: signed ask on the walking post
  {"dots":1},gesto("abuela","senala",a="poste"),"c53_colmado_cerca",ask("poste","c53_por_donde",after=[act("camina53",ok=1)],then=["c53_esta_cerca"]),
  # 3: the park is far: signed ask on the stop's sign; a guagua with the tree takes him and brings him back
  {"dots":2},"c53_parque_lejos",ask("parada","c53_donde_parada",after=[act("guagua",k="arbol",que="llega",a="parada1"),act("monta53",ok=1)],then=["c53_esta_lejos"]),
  # 4: the señor sits down on the bench and complains
  {"dots":3},gesto("senor","sienta"),"c53_senor",
  # 5: the turn: abuela sits down by the ball; "¿vas tú?" (a speaking turn); the card shows two places and the sun
  {"dots":4},gesto("abuela","sienta"),"c53_espero","c53_cq_voy",CARD,{"wait":400},
  # 6: A, don Pepe's box. 7: B, the señora's box. Near or far, drawn afresh each round
  {"dots":5}]+ronda53("a")+[{"dots":6}]+ronda53("b"),
 "final":[{"dots":7},   # 8: the sun's step decides the last picture (no step lost, one lost, two lost); 9: abuela asks if he is tired; the last turn depends on the ending
  {"if":"lost=0","then":["c53_que_bien",act("final53",n=0)],
   "else":[{"if":"lost=1","then":["c53_ya_tarde",act("final53",n=1)],"else":["c53_muy_tarde",act("final53",n=2),gesto("coqui","bosteza")]}]},
  "c53_cansado",{"if":"lost=2","then":["c53_cq_cansado"],"else":["c53_cq_no_bien"]},"c53_vamos_casa",act("fin")],
 "leer":["c53_temprano","c53_vamos_temprano","c53_cajas","c53_colmado_cerca","c53_por_donde","c53_esta_cerca","c53_parque_lejos","c53_donde_parada","c53_esta_lejos","c53_senor","c53_espero","c53_cq_voy","c53_a_lejos","c53_b_cerca","c53_que_bien","c53_cansado","c53_cq_no_bien","c53_vamos_casa"]}
s53=reuse(s53,{"c53_cq_voy":TG(("voy",["voy"])),"c53_cq_no_bien":TG(("no",["no"])),"c53_cq_cansado":TG(("cansado",["cansado"]))})
json.dump(s53,open("cuentos/cerca-y-lejos.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files here, stories 48 to 50, and the earlier stories of this scene)
EARLIER=set(FOCUS_48_50)
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s51,s52,s53):
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in EARLIER: print("TURN ON A WORD IN NO EARLIER FOCUS_WORDS",st["id"],cid,t["palabra"])
    EARLIER.update(st["focus_words"])
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
# every clip id the steps name (with no variable in it) is in the story's clips; every `leer` id too
def refs(o):   # the clip ids a list of steps names: bare strings of the step lists, and the `line` / `say` / `bien` of a step
    if isinstance(o,str): yield o
    elif isinstance(o,list):
        for x in o: yield from refs(x)
    elif isinstance(o,dict):
        if "calc" in o: return   # a calc's then / else are values, not steps
        for k in ("lead","after","then","else","right","wrong"):
            if k in o: yield from refs(o[k])
        for k in ("line","say","bien"):
            if isinstance(o.get(k),str): yield o[k]
for st in (s51,s52,s53):
    for i in sorted(set(refs([st["beats"],st["final"]]))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    print(st["id"],":",len(st["clips"]),"clips,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
