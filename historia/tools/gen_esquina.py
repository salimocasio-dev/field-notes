# La esquina (place 5, La calle, scene 1): stories 48, 49, 50. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/esquina.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `esquina` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir, gesto).
# A beat that has no act in the Needs list is left out (no act invented); the builder's report lists them.
# Open points (the script does not settle them; each is marked OPEN below and listed in the builder's report): the sides a thing comes from, the colour of the car, which spot is the front one, the rider of the bicycle, the values of `lado`.
# Run order: after gen_mostrador, gen_estantes, gen_frutas, gen_caja (each sees only what was recorded before it); the stories of the other scenes of place 5 are not seen.
import json,glob,os,re,collections,itertools
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); MA=lambda t:D("mama","Mamá",t); PA=lambda t:D("papa","Papá",t); PE=lambda t:D("pepe","Don Pepe",t); L=lambda t:D("luis","Luis",t)
SA=lambda t:D("senora","La señora",t); SE=lambda t:D("senor","El señor",t); OB=lambda t:D("obrero","El obrero",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's twinkle on a thing he can touch
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def junto(a,b,*lines): return [dict(a,suelto=1),dict(b,suelto=1)]+list(lines)+[act("ya")]   # two acts at the same time: both loose; the engine keeps the last one for `ya`, so the one that takes longer goes second
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
okc=lambda:{"if":"ok","then":[OK]}                        # the star only for a first-try right move
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story of this place has two scored rounds: the card shows two places
def resta(nombre):   # what is left of the stake after a cost (the stake has 3 steps and 2 rounds: lost is 1 or 2 here)
    return {"if":"lost=1","then":[act(nombre,n=2)],"else":[act(nombre,n=1)]}
def quedan(hist):   # the ending, by what was lost: three, two or one left
    return {"if":"lost=0","then":[act(hist,n=3)],"else":[{"if":"lost=1","then":[act(hist,n=2)],"else":[act(hist,n=1)]}]}
LEFT,RIGHT="izq","der"   # OPEN: the script says "comes one way ... the other way" (48.3) and names no side values; these two are mine
MINE=("la-calle","la-esquina","ahora-y-despues","para-donde-vas","se-monta-y-se-baja","cerca-y-lejos","las-tiendas","el-edificio-alto","abierto-y-cerrado","izquierda-o-derecha","sigue-derecho","al-frente-y-detras")   # this generator's stories and the ones after them: not seen
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
DIN=set()   # ids that are put together in the story ("c48_ab_mama_$ea"): never renamed
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
    out["leer"]=list(dict.fromkeys(out["leer"]))     # a reading text names a line once
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
# What he hears when he pokes a person already recorded (as in El colmado: the new things add nothing; don Pepe and the obrero have no line)
NM={"abuela":("abuela",N("Esta es abuela.")),"mama":("esta_es_mama",N("Esta es mamá.")),"papa":("n_papa",N("Este es papá.")),"bebe":("n_bebe",N("Este es el bebé.")),
    "luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),"senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!")}
ART={"carro":"el carro","guagua":"la guagua","bicicleta":"la bicicleta"}

# ---------------- 48. La calle ----------------
# Every round: a car and a guagua pull up one behind the other (which is in front: drawn), mamá or papá is in one of them (which: drawn). He touches the one abuela names.
nm,nc=nombres("abuela","bebe","mama","papa","luis","senor","senora","coqui")
c=dict(comunes); c.update(nc)
c.update({"c48_en_calle":N("Abuela, el bebé y Coquí están en la calle."),"c48_mira_calle":N("Mira la calle. Es larga."),
 "c48_viene_carro":N("Por la calle viene un carro. El carro es rojo."),"c48_toca_carro":N("Toca el carro."),
 "c48_viene_guagua":N("Ahora viene una guagua. La guagua es grande."),"c48_donde_guagua":N("¿Dónde está la guagua?"),
 "c48_viene_bici":N("Y ahora viene una bicicleta. El señor viene en bicicleta."),"c48_toca_bici":N("Toca la bicicleta."),
 "c48_senor_hola":SE("¡Hola, Coquí! ¿Cómo estás?"),"c48_cq_bien":T("Bien, gracias."),
 "c48_flores":N("El bebé tiene tres flores: una para mamá, una para papá y una para Luis."),"c48_ab_ya_vienen":AB("Ya vienen mamá y papá."),
 "c48_senora_gracias":SA("¿Para mí? ¡Gracias!"),"c48_pepe_gracias":PE("¿Para mí? ¡Gracias!"),
 "c48_mama_hola":MA("¡Hola! ¿Y mi bebé?"),"c48_cq_aqui":T("¡Aquí está!"),
 "c48_y_luis":N("Y Luis viene en bicicleta."),"c48_papa_vamos":PA("¿Vamos a casa?"),"c48_cq_si_papa":T("¡Sí, papá!"),"c48_familia_casa":N("La familia va a casa.")})
for w in ("guagua","carro"):
    for q,Q in (("mama","Mamá"),("papa","Papá")):
        c["c48_ab_%s_%s"%(q,w)]=AB("%s viene en %s."%(Q,ART[w])); c["c48_no_%s_%s"%(q,w)]=AB("No, Coquí. %s viene en %s."%(Q,ART[w]))
        DIN.update(["c48_ab_%s_%s"%(q,w),"c48_no_%s_%s"%(q,w)])
def ronda48(s,q,color,quien):
    # s: the round's letter; q: mama or papa; color: the car of this round; quien: the stranger at the window (senora in A, pepe in B)
    f,t,e,o="f"+s,"t"+s,"e"+s,"o"+s    # f: in front at the kerb, t: behind it; e: where mamá/papá is (the right one), o: the other
    linea="c48_ab_%s_$%s"%(q,e)
    return [{"draw":f,"options":["carro","guagua"],"other":t},{"draw":e,"options":["carro","guagua"],"other":o},
     {"decide":"do","options":["carro","guagua"],"pick":"$"+e,"tests":"$"+e,"lock":True,"mudo":True,
      "lead":junto(act("llega",k="$"+f,color=color,a="parada1"),act("llega",k="$"+t,color=color,a="parada2"),linea),"line":linea,   # OPEN: parada1 is taken as the front one
      "right":[act("ir",a="$"+e),gesto("coqui","saluda"),act("baja48",quien=q,de="$"+e),okc(),{"if":"ok","then":[act("sigue",k="$"+o)]}],
      "wrong":[act("ir",a="$x"),act("ventanilla",k="$x",quien=quien),act("flor",a=quien),"c48_%s_gracias"%("senora" if quien=="senora" else "pepe"),act("sigue",k="$x")]+X+[resta("flores"),"c48_no_%s_$%s"%(q,e)]}]
s48={"id":"la-calle","title":"La calle","place":"La calle","scene":"esquina","next":"la-esquina",
 "goal":"Stop the right car or guagua for mamá and for papá, so the bebé still has a flower for each of them and for Luis: every wrong stop gives a flower to a stranger.","stake":{"thing":"flores","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["calle","carro","guagua","bicicleta"],"formas_foco":{},
 "back_again":["abuela","bebé","mamá","papá","flor","tres","grande","rojo","señor","señora","tiene","aquí","bien","sí","gracias","casa","vamos","¿cómo estás?"],
 "also_heard":["larga"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"tarde"}},act("ir",a="acera"),act("flores",n=3),{"wait":500},
  # 1: the street twinkles; far off, a car turns in (it is the red car of step 2: one `llega`, started here, joined by `ya` there)
  "c48_en_calle",tw("calle"),"c48_mira_calle",tw(None),dict(act("llega",k="carro",color="rojo"),suelto=1),
  # 2 to 4: three signed asks (the car, the guagua, the bicycle)
  {"dots":1},tw("carro"),"c48_viene_carro",tw(None),act("ya"),
  ask("carro","c48_toca_carro",after=[act("bocina",k="carro"),act("bocina",k="carro")],then=[act("sigue",k="carro")]),
  {"dots":2},dict(act("llega",k="carro",color="azul",de=RIGHT),suelto=1),dict(act("llega",k="guagua",de=LEFT),suelto=1),tw("guagua"),"c48_viene_guagua",tw(None),act("ya"),   # the blue car goes by the other way
  ask("guagua","c48_donde_guagua",after=[act("bocina",k="guagua")],then=[act("sigue",k="guagua")]),
  {"dots":3},dict(act("llega",k="bicicleta",quien="senor"),suelto=1),tw("bicicleta"),"c48_viene_bici",tw(None),act("ya"),
  ask("bicicleta","c48_toca_bici",after=[act("bocina",k="bicicleta")],then=["c48_senor_hola","c48_cq_bien",act("sigue",k="bicicleta")]),
  # 5: the turn: each flower is for a named person; abuela looks along the street; the card shows two places
  {"dots":4},gesto("bebe","saluda"),"c48_flores",gesto("abuela","mira",a="calle"),"c48_ab_ya_vienen",CARD,{"wait":400},
  # 6: A, mamá (the red car); 7: B, papá (the blue car). Each drawn afresh
  {"dots":5}]+ronda48("a","mama","rojo","senora")+["c48_mama_hola","c48_cq_aqui",act("sigue",k="$ea"),
  {"dots":6}]+ronda48("b","papa","azul","pepe")+[gesto("bebe","rie"),act("sigue",k="$eb")],
 "final":[{"dots":7},act("bocina",k="bicicleta")]+con(act("llega",k="bicicleta",quien="luis",a="acera"),"c48_y_luis")+[   # 8: Luis rides up; the bebé gives the flowers, by what was lost
  quedan("da48"),
  "c48_papa_vamos","c48_cq_si_papa","c48_familia_casa",act("fin")],     # 9
 "leer":["c48_en_calle","c48_mira_calle","c48_viene_carro","c48_toca_carro","c48_viene_guagua","c48_donde_guagua","c48_viene_bici","c48_toca_bici","c48_senor_hola","c48_cq_bien","c48_flores","c48_ab_ya_vienen",
  "c48_ab_mama_guagua","c48_mama_hola","c48_cq_aqui","c48_ab_papa_carro","c48_y_luis","c48_papa_vamos","c48_cq_si_papa","c48_familia_casa"]}
s48=reuse(s48,{"c48_cq_bien":TG(("bien",["bien"])),"c48_cq_aqui":TG(("aquí",["aquí","aqui"])),"c48_cq_si_papa":TG(("sí",["sí","si"]))})
json.dump(s48,open("cuentos/la-calle.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 49. La esquina ----------------
# The four people (señora, señor, Luis, Carmen) are dealt out once to the two rounds: A has two, B the two others. In each round one of the two crosses (drawn), who is named first is drawn, which side each stands on is drawn.
nm,nc=nombres("abuela","bebe","mama","luis","carmen","senor","senora","coqui")
c=dict(comunes); c.update(nc)
c.update({"c49_ab_toma":AB("Toma, Coquí. Los globos son para el bebé."),"c49_ab_espera":AB("Espera aquí, en la esquina."),"c49_cq_esquina":N("Coquí está en la esquina."),"c49_donde_esquina":N("¿Dónde está la esquina?"),
 "c49_hay_gente":N("Mira. Hay mucha gente en la esquina. La gente espera."),"c49_donde_gente":N("¿Dónde está la gente?"),"c49_sra_hola":SA("¡Hola, Coquí! ¿Dónde está tu abuela?"),"c49_cq_colmado":T("Está en el colmado."),
 "c49_pasa":N("Pasa un carro y pasa la guagua."),"c49_pasa_bici":N("Ahora pasa una bicicleta."),"c48_toca_bici":N("Toca la bicicleta."),"c49_luis_globos":L("¡Globos! ¿Cuántos tienes?"),"c49_cq_tres":T("¡Tres!"),
 "c49_toca_boton":N("Toca el botón, Coquí."),"c49_gente_cruza":N("Ahora la gente cruza la calle."),"c49_sra_carmen_cruzan":N("La señora cruza. Carmen cruza."),"c49_senor_luis_pasan":N("El señor y Luis pasan por la esquina."),
 "c49_pepe_muy_bien":PE("¡Muy bien, Coquí! Ahora viene más gente."),
 "c49_ab_cruzan":N("Ahora abuela y Coquí cruzan la calle."),"c49_mama_globos":MA("¡Globos! ¿Son para mí?"),"c49_cq_bebe":T("¡No! Son para el bebé."),
 "c49_van_casa":N("Abuela, mamá, el bebé y Coquí van a casa.")})
GENTE={"senora":"La señora","senor":"El señor","luis":"Luis","carmen":"Carmen"}
for cr in GENTE:
    for pa in GENTE:
        if cr==pa: continue
        cc=GENTE[cr]+" cruza."; pp=GENTE[pa]+" pasa por la esquina."
        c["c49_pepe_c_%s_%s"%(cr,pa)]=PE(cc+" "+pp); c["c49_pepe_p_%s_%s"%(cr,pa)]=PE(pp+" "+cc); c["c49_no_%s_%s"%(cr,pa)]=PE("No, Coquí. "+pp+" "+cc)   # the correction always names the one who passes first and ends on the one who crosses, as in the script's example
        DIN.update(["c49_pepe_c_%s_%s"%(cr,pa),"c49_pepe_p_%s_%s"%(cr,pa),"c49_no_%s_%s"%(cr,pa)])
def ronda49(s):
    # c: the one who crosses, p: the one who only passes; o: which half of the line is said first (c: the crosser's, p: the passer's); d: which of the two stands on which side
    cr,pa,o,d="c"+s,"p"+s,"o"+s,"d"+s
    linea="c49_pepe_$%s_$%s_$%s"%(o,cr,pa)
    return [{"draw":o,"options":["c","p"]},{"draw":d,"options":["1","2"]},   # OPEN: `lado` 1 = the first of the pair on bordillo1, 2 = on bordillo2
     {"decide":"do","options":["$"+cr,"$"+pa],"pick":"$"+cr,"tests":"cruza","lock":True,"mudo":True,
      "lead":[act("par49",a="$"+cr,b="$"+pa,lado="$"+d),linea],"line":linea,
      "right":[act("luz",roja=1),act("cruza",quien="$"+cr),{"if":"ok","then":[act("pasa",quien="$"+pa)]},act("luz",roja=0),okc()],
      "wrong":[act("luz",roja=1),act("pasa",quien="$x"),act("bocina",k="guagua"),act("globo_va")]+X+[resta("globos"),"c49_no_$%s_$%s"%(cr,pa)]}]
s49={"id":"la-esquina","title":"La esquina","place":"La calle","scene":"esquina","next":"ahora-y-despues",
 "goal":"Press the button only for the person who is crossing, so the three balloons in his hand reach the bebé on the far pavement: every wrong press stops the traffic for nobody and a balloon gets away.","stake":{"thing":"globos","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["esquina","gente","cruza","pasa"],"formas_foco":{"cruza":["cruzan"],"pasa":["pasan"]},
 "back_again":["calle","carro","guagua","bicicleta","colmado","espera","hay","mucho","señora","señor","abuela","bebé","mamá","tres","¿cuántos?","toma","tiene","aquí","no","ahora","casa"],
 "also_heard":["globos","botón"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"tarde"}},act("ir",a="esquina"),{"wait":500},
  # 1: abuela gives him the balloons and goes back in; the corner twinkles; signed ask on the corner (the people walk up)
  {"dots":1},act("globos",n=3),"c49_ab_toma","c49_ab_espera",tw("esquina"),"c49_cq_esquina",tw(None),
  ask("esquina","c49_donde_esquina",after=[act("gente",que="viene")]),
  # 2: the people; signed ask on them; the señora asks for abuela (a speaking turn)
  {"dots":2},tw("gente"),"c49_hay_gente",tw(None),
  ask("gente","c49_donde_gente",after=[act("gente",que="saluda")],then=["c49_sra_hola","c49_cq_colmado"]),
  # 3: traffic goes by; signed ask on the bicycle; Luis asks how many (a speaking turn)
  {"dots":3}]+junto(act("llega",k="carro",color="rojo"),act("llega",k="guagua"),"c49_pasa")+[dict(act("llega",k="bicicleta"),suelto=1),"c49_pasa_bici",act("ya"),
  ask("bicicleta","c48_toca_bici",after=[act("bocina",k="bicicleta")],then=[act("sigue",k="bicicleta"),gesto("luis","mira",a="coqui"),"c49_luis_globos","c49_cq_tres"]),
  # 4: the button twinkles; signed ask on it: the light turns red; the señora and Carmen cross, the señor and Luis go round the corner; green again
  {"dots":4},tw("boton"),ask("boton","c49_toca_boton",after=[tw(None),act("luz",roja=1)],
   then=["c49_gente_cruza"]+junto(act("cruza",quien="senora"),act("cruza",quien="carmen"),"c49_sra_carmen_cruzan")+junto(act("pasa",quien="senor"),act("pasa",quien="luis"),"c49_senor_luis_pasan")+[act("luz",roja=0)]),
  # 5: the turn: don Pepe at his door; the card shows two places
  {"dots":5},gesto("pepe","mira",a="esquina"),"c49_pepe_muy_bien",CARD,{"wait":400},
  # 6: A; 7: B (the two others). The four are dealt out once: A has ca and pa, B has cb and pb
  {"reparte":["ca","pa","cb","pb"],"options":["senora","senor","luis","carmen"]},
  {"dots":6}]+ronda49("a")+[{"dots":7}]+ronda49("b"),
 "final":[{"dots":8},act("luz",roja=1)]+junto(act("cruza",quien="abuela"),act("ir",a="enfrente"),"c49_ab_cruzan")+[act("luz",roja=0),   # 8: abuela and the frog cross; the bebé takes the balloons, by what was lost
  "c49_mama_globos","c49_cq_bebe",quedan("da49"),
  "c49_van_casa",act("fin")],     # 9
 "leer":["c49_ab_toma","c49_ab_espera","c49_cq_esquina","c49_donde_esquina","c49_hay_gente","c49_donde_gente","c49_sra_hola","c49_cq_colmado","c49_pasa","c49_pasa_bici","c48_toca_bici","c49_luis_globos","c49_cq_tres",
  "c49_toca_boton","c49_gente_cruza","c49_sra_carmen_cruzan","c49_senor_luis_pasan","c49_pepe_muy_bien","c49_pepe_c_senora_senor","c49_ab_cruzan","c49_mama_globos","c49_cq_bebe","c49_van_casa"]}
s49=reuse(s49,{"c49_cq_colmado":TG(("colmado",["colmado"])),"c49_cq_tres":TG(("tres",["tres"])),"c49_cq_bebe":TG(("bebé",["bebé","bebe"]))})
json.dump(s49,open("cuentos/la-esquina.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 50. Ahora y después ----------------
# Every round: two of the car, the guagua and the bicycle wait at the two ends of the lane; the obrero says which goes now and which goes after (which half of his line comes first: drawn). B's pair is not A's pair.
nm,nc=nombres("luis","coqui")
c=dict(comunes); c.update(nc)
c.update({"c50_obrero_arregla":N("Coquí y Luis están en la esquina. Un obrero arregla la calle."),"c50_obrero_cuidado":OB("¡Cuidado, Coquí! Mira."),"c50_cq_que_es":T("¿Qué es esto?"),"c50_obrero_cemento":OB("Esto es cemento. No está listo."),
 "c50_viene_carro_guagua":N("Viene un carro y viene la guagua."),"c50_cual_ahora":N("¿Cuál va ahora?"),"c50_y_despues_guagua":N("Y después va la guagua."),
 "c50_viene_bici":N("Ahora viene una bicicleta."),"c50_y_despues_carro":N("Y después va el carro."),
 "c50_obrero_banderas":OB("Tengo sed. Quiero agua. Toma las banderas, Coquí."),"c50_cq_gracias":T("¡Gracias!"),
 "c50_espera":OB("¡Espera, Coquí!"),"c50_obrero_listo":OB("Ahora está listo. Ahora tú, Coquí."),"c50_y_despues_tu":OB("Y después tú, Luis."),
 "c50_obrero_gusta":OB("Mira. ¿Te gusta?"),"c50_cq_me_gusta":T("¡Sí, me gusta!"),"c50_viene_carro_casa":N("Viene un carro. Coquí y Luis van a casa.")})
for ahora in ART:
    for despues in ART:
        if ahora==despues: continue
        Lu=ART[despues][0].upper()+ART[despues][1:]
        c["c50_ob_a_%s_%s"%(ahora,despues)]=OB("Ahora va %s. Después va %s."%(ART[ahora],ART[despues]))          # his line, the "now" half first
        c["c50_ob_l_%s_%s"%(ahora,despues)]=OB("%s va después. Ahora va %s."%(Lu,ART[ahora]))                 # drawn: the "after" half first
        c["c50_no_%s_%s"%(ahora,despues)]=OB("No. Ahora va %s. Después va %s."%(ART[ahora],ART[despues]))        # the correction, as in the script's example
        DIN.update(["c50_ob_a_%s_%s"%(ahora,despues),"c50_ob_l_%s_%s"%(ahora,despues),"c50_no_%s_%s"%(ahora,despues)])
def ronda50(s,u,v):
    # u waits at carril_a, v at carril_b (variables dealt for the game); n: the one that goes now, l: the one that goes after; o: which half of the line is said first (a: the "now" half, l: the "after" half)
    n,l,o="n"+s,"l"+s,"o"+s
    linea="c50_ob_$%s_$%s_$%s"%(o,n,l)
    return [{"draw":n,"options":["$"+u,"$"+v],"other":l},{"draw":o,"options":["a","l"]},
     {"decide":"do","options":["$"+u,"$"+v],"pick":"$"+n,"tests":"ahora","lock":True,"mudo":True,
      "lead":junto(act("llega",k="$"+u,a="carril_a"),act("llega",k="$"+v,a="carril_b"))+[linea],"line":linea,
      "right":[act("bandera",a="$"+n),act("sigue",k="$"+n),act("sigue",k="$"+l),okc()],
      "wrong":[act("bandera",a="$x")]+con(act("atras50",k="$x"),gesto("obrero","silba"),"c50_espera")+X+[resta("cemento"),"c50_no_$%s_$%s"%(n,l)]}]
s50={"id":"ahora-y-despues","title":"Ahora y después","place":"La calle","scene":"esquina","next":"para-donde-vas",
 "goal":"Send the right one through the one-lane roadwork first with the flags, so the fresh cement stays smooth for the frog's and Luis's prints: a wrong one backs up and leaves a wheel track in it.","stake":{"thing":"cemento","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["viene","va","ahora","después"],"formas_foco":{},
 "back_again":["carro","guagua","bicicleta","calle","esquina","cuidado","listo","¿qué es esto?","¿cuál?","me gusta","mira","tú","tengo sed","agua","quiero","toma","gracias","casa"],
 "also_heard":["obrero","arregla","banderas"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"manana","obra":1}},act("cemento",n=3),{"wait":500},
  # 1: the obrero stops the frog; the frog asks what it is (a speaking turn)
  {"dots":1},"c50_obrero_arregla","c50_obrero_cuidado",gesto("obrero","mira",a="cemento"),tw("cemento"),"c50_cq_que_es",tw(None),"c50_obrero_cemento",gesto("coqui","pie"),
  # 2 and 3: two signed asks (the car; the bicycle): who goes now
  {"dots":2}]+junto(act("llega",k="carro",color="rojo",a="carril_a"),act("llega",k="guagua",a="carril_b"),"c50_viene_carro_guagua")+["c50_ob_a_carro_guagua",
  ask("carro","c50_cual_ahora",after=[act("paleta",a="carril_a"),act("sigue",k="carro")],then=["c50_y_despues_guagua",act("sigue",k="guagua")]),
  {"dots":3}]+junto(act("llega",k="bicicleta",a="carril_a"),act("llega",k="carro",color="azul",a="carril_b"),"c50_viene_bici")+["c50_ob_a_bicicleta_carro",
  ask("bicicleta","c50_cual_ahora",after=[act("paleta",a="carril_a"),act("bocina",k="bicicleta"),act("sigue",k="bicicleta")],then=["c50_y_despues_carro",act("sigue",k="carro")]),
  # 4: the turn: the obrero sits down and hands over the flags; thanks (a speaking turn); the card shows two places
  {"dots":4},gesto("obrero","bebe"),"c50_obrero_banderas","c50_cq_gracias",act("banderas"),CARD,{"wait":400},
  # 5: A; 6: B. The three things are dealt once: A is ua and va, B is va and wa (not A's pair)
  {"reparte":["ua","va","wa"],"options":["carro","guagua","bicicleta"]},
  {"dots":5}]+ronda50("a","ua","va")+[{"dots":6}]+ronda50("b","va","wa"),
 "final":[{"dots":7},"c50_obrero_listo",act("ir",a="cemento"),   # 7: the obrero tests the cement; the frog hops on it; the prints, by what was lost
  {"if":"lost=0","then":con(act("huellas",n=3),"c50_y_despues_tu"),"else":[{"if":"lost=1","then":[act("huellas",n=2)],"else":[act("huellas",n=1)]}]},
  "c50_obrero_gusta","c50_cq_me_gusta",act("llega",k="carro",a="carril_a"),"c50_viene_carro_casa",act("fin")],     # 8
 "leer":["c50_obrero_arregla","c50_obrero_cuidado","c50_cq_que_es","c50_obrero_cemento","c50_viene_carro_guagua","c50_ob_a_carro_guagua","c50_cual_ahora","c50_y_despues_guagua","c50_viene_bici","c50_ob_a_bicicleta_carro","c50_y_despues_carro",
  "c50_obrero_banderas","c50_cq_gracias","c50_ob_a_guagua_carro","c50_obrero_listo","c50_y_despues_tu","c50_obrero_gusta","c50_cq_me_gusta","c50_viene_carro_casa"]}
s50=reuse(s50,{"c50_cq_que_es":TG(("¿qué es esto?",["¿qué es esto?","que es esto"])),"c50_cq_gracias":TG(("gracias",["gracias"])),"c50_cq_me_gusta":TG(("me gusta",["me gusta"]))})
json.dump(s50,open("cuentos/ahora-y-despues.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
# every id the steps name (with no variable in it) is in the story's clips; every `leer` id too; every speaking turn is on a word of an earlier story
earlier=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s48,s49,s50):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"([a-z0-9_$]+)"',txt))):
        if "$" not in i and i in seen and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in sorted(set(re.findall(r'"((?:c(?:48|49|50)_|si_|yo_|p_n_|b_n_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    print(" ",st["id"],":",len(st["clips"]),"clips,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
print(len(seen),"clips,",new,"new,",chars,"characters to record,",clash,"clashes")
