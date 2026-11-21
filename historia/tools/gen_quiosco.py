# El quiosco (place 6, La plaza, scene 3): stories 66, 67, 68. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/quiosco.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `quiosco` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: gen_plaza, gen_reloj, gen_quiosco, gen_calendario (each sees only what was recorded before it). The files of places 1 to 5 must be on disk first (gen_mostrador ... gen_cruce).
#
# Where the Needs list leaves a value open, this file fixes it in ONE place (and the report says so):
#   COSAS: the keys of the things in the box (story 67) that Needs does not name (it names bulto and delantal): libro, gorro, estetoscopio, libretas, gorra.
#   BARRA: the frog's place at the start of 66 and 68 ("on the counter beside the tray"): no spot has that name; START_BARRA is the one value.
#   COLA: the people who come to the counter in 67 (and the niño and niña in 68) stand at cola1, cola2 (the two of a round) and cola3, cola4 (the next two): the next two step up to cola1, cola2 for round B.
#   TERCERA: the third candle of 68 ("one more number"): any of 1 to 12, never the years or the brothers' number, never seis with siete or once with doce on one tray.
#   Speaker keys: beto, ana, mama_ana (the plaza script lists ana and mama_ana; beto follows the same rule: the thing's key).
#   back_again of 68: "the tens" is listed as the two tens the story says (treinta, setenta).
#   The order of a costed wrong move is the script's: what happens, the correction line, the stake's picture, then the card's cross (X) and the next cup, candle or step; the brief's usual order (X before the line) is one move of X in ronda66, decide67 and ronda68.
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
SA=lambda t:D("senora","La señora",t); SE=lambda t:D("senor","El señor",t)
VE=lambda t:D("vendedor","El vendedor",t); MT=lambda t:D("maestra","La maestra",t); PO=lambda t:D("policia","El policía",t)
HO=lambda t:D("hombre","El hombre",t); MU=lambda t:D("mujer","La mujer",t); JO=lambda t:D("joven","El joven",t); LJ=lambda t:D("la_joven","La joven",t)
NI=lambda t:D("nino","El niño",t); NA=lambda t:D("nina","La niña",t)
BE=lambda t:D("beto","Beto",t); AN=lambda t:D("ana","Ana",t); MA=lambda t:D("mama_ana","La mamá de Ana",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time (people walking in or out together, everybody clapping): all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
START_BARRA="barra1"                                      # the frog on the counter beside the tray (66, 68): see the header
MINE=("un-cafe-para-la-maestra","en-que-trabajas","cuantos-anos-tienes")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c66_pide_$qa_$pa"): never renamed
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
# What he hears when he pokes a person already recorded (the new ones add nothing: the vendedor, the maestra, the doctor, the cocinero, the policía, la joven, the niño, the niña, Ana, Beto, Ana's mamá)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora.")),"hombre":("b_n_hombre",N("Es un hombre.")),"mujer":("b_n_mujer",N("Es una mujer.")),"joven":("b_n_joven",N("Es un joven."))}
def nombres(*ks):
    return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
NUM={"1":"uno","2":"dos","3":"tres","4":"cuatro","5":"cinco","6":"seis","7":"siete","8":"ocho","9":"nueve","10":"diez","11":"once","12":"doce"}

# ---------------- 66. Un café para la maestra ----------------
# The vendedor fills a cup or a glass and says who it is for: one of the four on the stools (drawn), and what is in it (un café, un jugo de china, un vaso de leche; drawn). Each round on its own.
# A miss: the cup goes to the wrong person, who pushes the tray back: it spills; the one named holds out empty hands; the vendedor sets a quesito from under the dome on a saucer for her.
# Every order has its sentence (A: "Un café para la maestra."; B: "Y un café para la maestra."): 12 each; the correction repeats the drink and the person: 12.
c=dict(comunes); nm,nc=nombres("luis","carmen","coqui"); c.update(nc)
c.update({"c66_mediodia":N("Es mediodía. La gente viene al quiosco."),"c66_ve_tardes_maestra":VE("¡Buenas tardes, maestra!"),"c66_ca_maestra":CA("¡Mira! Es mi maestra. La maestra viene de la escuela."),
 "c66_donde_maestra":N("¿Dónde está la maestra?"),"c66_ve_tardes_doctor":VE("¡Buenas tardes, doctor!"),"c66_luis_doctor":L("El doctor viene del hospital."),"c66_ca_hola_doctor":CA("¡Hola, doctor!"),
 "c66_luis_cocinero":L("¡Mira, un cocinero! El cocinero hace la comida."),"c66_ca_policia":CA("Y un policía. El policía mira los carros."),"c66_quien_cocinero":N("¿Quién es el cocinero?"),
 "c66_ve_ayudas":VE("Coquí, ¿me ayudas?"),"c66_cq_si":T("¡Sí!"),"c66_quien_policia":N("¿Quién es el policía?"),"c66_cq_aqui_tiene":T("¡Aquí tiene!"),"c66_po_gracias":PO("Gracias."),
 "c66_ve_ahora_tu":VE("Ahora tú, Coquí."),"c66_ma_gracias":MT("Gracias. Buenas tardes."),"c66_ve_quesito":VE("¿Quieres un quesito, Coquí?"),"c66_cq_si_quiero":T("¡Sí, quiero!"),
 "c66_fin":N("La maestra va a la escuela. El doctor va al hospital. Y Coquí come.")})
PERS66=["maestra","doctor","cocinero","policia"]
QUE66={"cafe":"un café","jugo":"un jugo de china","leche":"un vaso de leche"}; ART66={"cafe":"El café","jugo":"El jugo de china","leche":"El vaso de leche"}   # what the order says; the correction's subject
PARA66={"maestra":"la maestra","doctor":"el doctor","cocinero":"el cocinero","policia":"el policía"}
for q in QUE66:
    for p in PERS66:
        for i,t in (("c66_pide_%s_%s","Un %s para %s."),("c66_pide_y_%s_%s","Y un %s para %s.")):
            c[i%(q,p)]=VE(t%(QUE66[q][3:],PARA66[p])); DIN.add(i%(q,p))
        c["c66_no_%s_%s"%(q,p)]=VE("No, Coquí. %s es para %s."%(ART66[q],PARA66[p])); DIN.add("c66_no_%s_%s"%(q,p))
def ronda66(s,ln):
    # p: who the cup is for (drawn); q: what is in it (drawn). Right: the tray slides to her, "Aquí tiene.", she takes it and nods. Wrong: it goes to another, spills; the dome loses a quesito (the one the vendedor sets on a saucer for the one named); then he fills another cup and the sign shows her.
    p,q="p"+s,"q"+s
    return [{"draw":p,"options":PERS66},{"draw":q,"options":["cafe","jugo","leche"]},act("sirve66",que="$"+q),
     {"decide":"do","options":PERS66,"pick":"$"+p,"tests":"$"+p,"lock":True,"lead":[],"line":"c66_%s_$%s_$%s"%(ln,q,p),
      "right":[{"if":"ok","then":con(act("lleva66",a="$"+p,ok=1),"c66_cq_aqui_tiene")+[OK],"else":[act("lleva66",a="$"+p,ok=1)]}],
      "wrong":[act("lleva66",a="$x",ok=0),gesto("$"+p,"manos"),"c66_no_$%s_$%s"%(q,p),act("quesito66",a="$"+p),
               {"if":"lost=0","then":[act("quesitos",n=2)],"else":[act("quesitos",n=1)]}]+X+[act("sirve66",que="$"+q)]}]
s66={"id":"un-cafe-para-la-maestra","title":"Un café para la maestra","place":"La plaza","scene":"quiosco","next":"en-que-trabajas",
 "goal":"Serve each cup to the person it is named for, so the three quesitos under the glass dome are still there for the helpers after the work: every cup taken to the wrong person spills, and a quesito goes to the one who was left waiting.",
 "stake":{"thing":"quesitos","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["maestra","doctor","cocinero","policía"],"formas_foco":{},
 "back_again":["café","jugo","china","leche","vaso","quiere","para","aquí tiene","buenas tardes","hola","gracias","por favor","escuela","hospital","hace","comida","carro","viene","va","mira","¿quién?","sí","come","ahora","tú"],
 "also_heard":["mediodía","me ayudas","quesito"],"names":nm,"palabras":{"policia":"policía"},"clips":c,
 "beats":[{"set":{"hora":"mediodia"}},act("quesitos",n=3),act("ir",a=START_BARRA),{"wait":500},
  # 1: midday; the maestra sits on the first stool; Carmen waves; signed ask on the maestra
  "c66_mediodia",act("llega",quien="maestra",a="taburete1"),"c66_ve_tardes_maestra",gesto("carmen","saluda"),"c66_ca_maestra",ask("maestra","c66_donde_maestra"),
  # 2: the doctor sits on the second stool
  {"dots":1},act("llega",quien="doctor",a="taburete2"),"c66_ve_tardes_doctor","c66_luis_doctor","c66_ca_hola_doctor",
  # 3: the cocinero and the policía come together and take the last two stools; signed ask on the cocinero
  {"dots":2}]+juntos(act("llega",quien="cocinero",a="taburete3"),act("llega",quien="policia",a="taburete4"))+["c66_luis_cocinero","c66_ca_policia",gesto("policia","gorra"),ask("cocinero","c66_quien_cocinero"),
  # 4: "¿me ayudas?" (a speaking turn); a coffee for the policía (signed ask on the policía): the frog slides the tray to him
  {"dots":3},"c66_ve_ayudas","c66_cq_si",act("sirve66",que="cafe"),"c66_pide_cafe_policia",
  ask("policia","c66_quien_policia",after=con(act("lleva66",a="policia",ok=1),"c66_cq_aqui_tiene","c66_po_gracias"),then=[gesto("policia","pito")]),
  # 5: the turn: the vendedor taps the dome and winks; the card shows two places
  {"dots":4},gesto("vendedor","guino"),"c66_ve_ahora_tu",CARD,{"wait":400},
  # A and B: who the cup is for and what is in it, each drawn afresh
  {"dots":5}]+ronda66("a","pide")+[{"dots":6}]+ronda66("b","pide_y"),
 "final":[{"dots":7},"c66_ma_gracias",gesto("policia","pito")]+juntos(*[act("sale",quien=q) for q in PERS66])+[   # 8: the four go; the vendedor lifts the dome: the quesitos left decide the last picture; 9: the turn (por favor)
  {"if":"lost=0","then":[act("final66",n=3)],"else":[{"if":"lost=1","then":[act("final66",n=2)],"else":[act("final66",n=1)]}]},
  "c66_ve_quesito","c66_cq_si_quiero","c66_fin",act("fin")],
 "leer":["c66_mediodia","c66_ve_tardes_maestra","c66_ca_maestra","c66_donde_maestra","c66_ve_tardes_doctor","c66_luis_doctor","c66_ca_hola_doctor","c66_luis_cocinero","c66_ca_policia","c66_quien_cocinero","c66_ve_ayudas","c66_cq_si",
  "c66_pide_cafe_policia","c66_quien_policia","c66_cq_aqui_tiene","c66_po_gracias","c66_ve_ahora_tu","c66_pide_leche_maestra","c66_cq_aqui_tiene","c66_pide_y_jugo_doctor","c66_cq_aqui_tiene","c66_ma_gracias","c66_ve_quesito","c66_cq_si_quiero","c66_fin"]}
s66=reuse(s66,{"c66_cq_si":TG(("sí",["sí","si"])),"c66_cq_si_quiero":TG(("quiero",["quiero","sí quiero","si quiero"]))})
json.dump(s66,open("cuentos/un-cafe-para-la-maestra.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 67. ¿En qué trabajas? ----------------
# The frog lifts one thing out of the box; abuela asks the two at the counter what they do; one of them is the owner. Who is what, and who speaks first, is drawn, each round on its own.
# Round A: the thing is a stethoscope, the exercise books with an apple or the cap with a whistle (needs a doctor, a maestra or a policía); the señora and the hombre each hold one of the three jobs, never the same; either can be the owner.
# Round B: the thing is the school bag (an estudiante's) or the apron (a vendedora's); the mujer and la joven: one is an estudiante, the other a vendedora, either way round.
# A miss: the frog carries it to the other, who turns it over and gives it back ("No, eso no es mío. Yo soy ..."): one limber melts. The job keys are doctor, maestra, policia, estudiante, vendedor (the words said are doctora/doctor, maestra/maestro, policía, estudiante, vendedora: formas_foco).
c=dict(comunes); nm,nc=nombres("abuela","luis","carmen","coqui","senor","senora","hombre","mujer","joven"); c.update(nc)
c.update({"c67_mira_vendedor":N("Mira al vendedor. El vendedor trabaja en el quiosco."),"c67_ve_trabajo":VE("Yo trabajo aquí. Soy vendedor. ¡Y tengo mucho trabajo!"),"c67_que_hay_caja":N("¿Qué hay en la caja?"),
 "c67_ab_y_tu":AB("Y tú, ¿en qué trabajas?"),"c67_jo_estudiante":JO("No trabajo. Soy estudiante. Voy a la universidad."),"c67_ab_estudiante":AB("¡Un estudiante! Muy bien."),"c67_quien_estudiante":N("¿Quién es el estudiante?"),
 "c67_jo_libro":JO("¡Mi libro! ¡Gracias, Coquí!"),"c67_cq_toma":T("¡Toma!"),"c67_ab_usted_trabaja":AB("¿Y usted? ¿En qué trabaja?"),"c67_se_cocinero":SE("Soy cocinero. Trabajo en la escuela."),
 "c67_quien_escuela":N("¿Quién trabaja en la escuela?"),"c67_luis_y_tu":L("Y tú, Coquí, ¿en qué trabajas?"),"c67_ab_no_trabaja":AB("Coquí no trabaja. ¡Coquí juega!"),"c67_ve_ahora_tu":VE("Ahora tú, Coquí."),
 "c67_ab_y_usted":AB("¿Y usted?"),"c67_ab_y_tu_corto":AB("¿Y tú?"),
 "c67_ve_gracias":VE("¡Gracias, Coquí! ¡Buen trabajo!"),"c67_ve_limber":VE("¿Quieres un limber, Coquí?"),"c67_cq_si_gracias":T("¡Sí, gracias!"),"c67_ab_fin":AB("¡Mira! Ahora Coquí también trabaja.")})
TRAB67={"doctor":("doctora","doctor","Trabajo en el hospital."),"maestra":("maestra","maestro","Trabajo en la escuela."),"policia":("policía","policía","Trabajo aquí, en la plaza.")}   # job key -> (said by a woman, said by a man, where)
for p,F,g in (("senora",SA,0),("hombre",HO,1)):
    for j,(fem,mas,lug) in TRAB67.items():
        w=(fem,mas)[g]
        c["c67_%s_%s"%(p,j)]=F("Soy %s. %s"%(w,lug)); c["c67_no_%s_%s"%(p,j)]=F("No, eso no es mío. Yo soy %s."%w); DIN.update(["c67_%s_%s"%(p,j),"c67_no_%s_%s"%(p,j)])
    c["c67_%s_gracias"%p]=F("¡Gracias, Coquí!"); DIN.add("c67_%s_gracias"%p)
for p,F in (("mujer",MU),("la_joven",LJ)):
    for j,w,t in (("estudiante","estudiante","No trabajo. Soy estudiante."),("vendedor","vendedora","Soy vendedora. Trabajo en una tienda.")):
        c["c67_%s_%s"%(p,j)]=F(t); c["c67_no_%s_%s"%(p,j)]=F("No, eso no es mío. Yo soy %s."%w); DIN.update(["c67_%s_%s"%(p,j),"c67_no_%s_%s"%(p,j)])
    c["c67_%s_gracias"%p]=F("¡Gracias, Coquí!"); DIN.add("c67_%s_gracias"%p)
TODOS67=["abuela","luis","carmen","joven"]
def decide67(par,owner,tests,cosa,nono,linea,gracias):
    # par: the two people (the options); owner: the variable that names the owner; nono: the id of the other one's correction
    return {"decide":"do","options":par,"pick":"$"+owner,"tests":"$"+tests,"lock":True,"lead":[],"line":linea,
      "right":[{"if":"ok","then":[act("lleva67",cosa="$"+cosa,a="$"+owner,ok=1),gracias,OK],"else":[act("lleva67",cosa="$"+cosa,a="$"+owner,ok=1)]}],
      "wrong":[act("lleva67",cosa="$"+cosa,a="$x",ok=0),nono,act("derrite67")]+X}
# Round A: ta the thing, ja the owner's job, oa the owner (senora or hombre), na the other one, ea the other one's job, js and jh the jobs of the señora and the hombre, pa who speaks first, qa the second, jf and jg their jobs
ronda67a=[{"draw":"ta","options":["estetoscopio","libretas","gorra"]},{"calc":"ja","cond":"ta=estetoscopio","then":"doctor","else":"maestra"},{"calc":"ja","cond":"ta=gorra","then":"policia","else":"$ja"},
 {"draw":"oa","options":["senora","hombre"],"other":"na"},{"draw":"ua","options":["u","v"]},
 {"if":"ja=doctor","then":[{"calc":"ea","cond":"ua=u","then":"maestra","else":"policia"}],
  "else":[{"if":"ja=maestra","then":[{"calc":"ea","cond":"ua=u","then":"doctor","else":"policia"}],"else":[{"calc":"ea","cond":"ua=u","then":"doctor","else":"maestra"}]}]},
 {"draw":"pa","options":["senora","hombre"],"other":"qa"},
 {"calc":"js","cond":"oa=senora","then":"$ja","else":"$ea"},{"calc":"jh","cond":"oa=senora","then":"$ea","else":"$ja"},
 {"calc":"jf","cond":"pa=senora","then":"$js","else":"$jh"},{"calc":"jg","cond":"pa=senora","then":"$jh","else":"$js"},
 act("saca67",cosa="$ta"),"c67_ab_usted_trabaja","c67_$pa_$jf","c67_ab_y_usted",
 decide67(["senora","hombre"],"oa","ja","ta","c67_no_$na_$ea","c67_$qa_$jg","c67_$oa_gracias")]
# Round B: jb the owner's job (estudiante or vendedor), tb the thing, eb the other one's job, ob the owner (mujer or la joven), nb the other one, jm and jl the jobs of the mujer and of la joven, pb who speaks first, qb the second, jfb and jgb their jobs
ronda67b=[{"draw":"jb","options":["estudiante","vendedor"]},{"calc":"tb","cond":"jb=estudiante","then":"bulto","else":"delantal"},{"calc":"eb","cond":"jb=estudiante","then":"vendedor","else":"estudiante"},
 {"draw":"ob","options":["mujer","la_joven"],"other":"nb"},{"calc":"jm","cond":"ob=mujer","then":"$jb","else":"$eb"},{"calc":"jl","cond":"ob=mujer","then":"$eb","else":"$jb"},
 {"draw":"pb","options":["mujer","la_joven"],"other":"qb"},{"calc":"jfb","cond":"pb=mujer","then":"$jm","else":"$jl"},{"calc":"jgb","cond":"pb=mujer","then":"$jl","else":"$jm"},
 act("saca67",cosa="$tb"),{"if":"pb=mujer","then":["c67_ab_usted_trabaja"],"else":["c67_ab_y_tu"]},"c67_$pb_$jfb",{"if":"qb=mujer","then":["c67_ab_y_usted"],"else":["c67_ab_y_tu_corto"]},
 decide67(["mujer","la_joven"],"ob","jb","tb","c67_no_$nb_$eb","c67_$qb_$jgb","c67_$ob_gracias")]
s67={"id":"en-que-trabajas","title":"¿En qué trabajas?","place":"La plaza","scene":"quiosco","next":"cuantos-anos-tienes",
 "goal":"Give each forgotten thing back to its owner by what each person says he or she does for work, so the three frosty limbers at the end of the counter are still there when the box is empty: every wrong person melts one.",
 "stake":{"thing":"limbers","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["trabajo","trabaja","¿en qué trabajas?","vendedor","estudiante"],
 "formas_foco":{"trabaja":["trabajas"],"¿en qué trabajas?":["¿en qué trabaja?"],"vendedor":["vendedora"],"maestra":["maestro"],"doctor":["doctora"]},
 "back_again":["maestra","doctor","cocinero","policía","escuela","hospital","tienda","plaza","soy","es","caja","hay","eso","aquí","gracias","de nada","quiero","quieres","juega","joven","señor","señora","hombre","mujer","abuela","mucho","también","voy"],
 "also_heard":["universidad","libro","mío","limber"],"names":nm,"palabras":{"policia":"policía"},"clips":c,
 "beats":[{"set":{"hora":"tarde"}},act("limbers",n=3),act("ir",a="mesa"),{"wait":500},
  # 1: the vendedor works here; the box, its lid off; signed ask on the box: the frog lifts out a thick book
  "c67_mira_vendedor","c67_ve_trabajo",act("tapa67"),gesto("vendedor","no"),ask("caja","c67_que_hay_caja",after=[act("saca67",cosa="libro")]),
  # 2: a young man sits down; "no trabajo, soy estudiante"; signed ask on him: the frog carries the book over; a speaking turn (de nada)
  {"dots":1},act("llega",quien="joven",a="taburete1"),"c67_ab_y_tu","c67_jo_estudiante","c67_ab_estudiante",gesto("coqui","mira",a="joven"),
  ask("joven","c67_quien_estudiante",after=[act("lleva67",cosa="libro",a="joven",ok=1)]),"c67_cq_toma","c67_jo_libro",
  # 3: the señor sits beside him; "soy cocinero. Trabajo en la escuela"; signed ask on him: the frog brings the tall hat; everybody claps
  {"dots":2},act("llega",quien="senor",a="taburete2"),"c67_ab_usted_trabaja","c67_se_cocinero",act("saca67",cosa="gorro"),
  ask("senor","c67_quien_escuela",after=[act("lleva67",cosa="gorro",a="senor",ok=1)],then=juntos(*[gesto(q,"aplaude") for q in TODOS67])),
  # 4: Luis asks the frog; he shakes his head; "Coquí no trabaja. ¡Coquí juega!"
  {"dots":3},"c67_luis_y_tu",gesto("coqui","no"),"c67_ab_no_trabaja",
  # 5: the turn: the young man and the señor go; four people walk up to the counter; the vendedor looks at the limbers and at the box; the card shows two places
  {"dots":4}]+juntos(act("sale",quien="joven"),act("sale",quien="senor"))+juntos(act("llega",quien="senora",a="cola1"),act("llega",quien="hombre",a="cola2"),act("llega",quien="mujer",a="cola3"),act("llega",quien="la_joven",a="cola4"))
  +[gesto("vendedor","mira",a="limbers"),gesto("vendedor","mira",a="caja"),"c67_ve_ahora_tu",CARD,{"wait":400},
  # A: the señora and the hombre, their jobs and who speaks first drawn. B: the mujer and la joven (they step up to the counter when the others have gone), drawn on their own
  {"dots":5}]+ronda67a+juntos(act("sale",quien="senora"),act("sale",quien="hombre"))+juntos(act("llega",quien="mujer",a="cola1"),act("llega",quien="la_joven",a="cola2"))+[{"dots":6}]+ronda67b,
 "final":[{"dots":7},"c67_ve_gracias",   # 8: the box is empty; the limbers left decide the last picture; 9: the turn (quiero)
  {"if":"lost=0","then":[act("final67",n=3)],"else":[{"if":"lost=1","then":[act("final67",n=2)],"else":[act("final67",n=1)]}]},
  "c67_ve_limber","c67_cq_si_gracias","c67_ab_fin",act("fin")],
 "leer":["c67_mira_vendedor","c67_ve_trabajo","c67_que_hay_caja","c67_ab_y_tu","c67_jo_estudiante","c67_ab_estudiante","c67_quien_estudiante","c67_cq_toma","c67_jo_libro","c67_ab_usted_trabaja","c67_se_cocinero","c67_quien_escuela","c67_luis_y_tu","c67_ab_no_trabaja",
  "c67_ve_ahora_tu","c67_ab_usted_trabaja","c67_senora_doctor","c67_ab_y_usted","c67_hombre_maestra","c67_senora_gracias","c67_ab_y_tu","c67_la_joven_estudiante","c67_ab_y_usted","c67_mujer_vendedor","c67_mujer_gracias","c67_ve_gracias","c67_ve_limber","c67_cq_si_gracias","c67_ab_fin"]}
s67=reuse(s67,{"c67_cq_toma":TG(("toma",["toma"])),"c67_cq_si_gracias":TG(("gracias",["gracias","sí gracias","si gracias"]))})
json.dump(s67,open("cuentos/en-que-trabajas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 68. ¿Cuántos años tienes? ----------------
# A child at the counter says how old he is and how many brothers or sisters he has (which is said first is drawn). Three number candles lie on the tray: his years, his brothers or sisters, one more number.
# Years: 5 to 12; brothers or sisters: 2 to 4; the third: 1 to 12, not the years, not the brothers' number, never seis with siete or once with doce on one tray. Each round on its own: niño (hermanos) in A, niña (hermanas) in B.
# A miss: the frog pushes the wrong number into a bizcocho; the child says "¡No! Tengo nueve años."; the candle comes out, the bizcocho breaks, Canelo eats it; the vendedor takes a whole one from Beto's tower.
c=dict(comunes); nm,nc=nombres("abuela","luis","carmen","coqui"); c.update(nc)
c.update({"c68_cumple":N("Es el cumpleaños de Beto."),"c68_ve_cuantos_beto":VE("Beto, ¿cuántos años tienes?"),"c68_be_cinco":BE("¡Cinco! Tengo cinco años."),"c68_donde_cinco":N("¿Dónde está el cinco?"),
 "c68_be_y_tu_ana":BE("¿Y tú, Ana? ¿Cuántos años tienes?"),"c68_an_ocho":AN("Tengo ocho años."),"c68_ca_ocho":CA("¡Yo también! Tengo ocho años."),"c68_donde_ocho":N("¿Y dónde está el ocho?"),
 "c68_l_diez":L("Yo tengo diez años. Y tengo una hermana."),"c68_l_abuela":L("Abuela, ¿cuántos años tienes?"),"c68_ab_setenta":AB("¡Ay! Tengo setenta años."),"c68_ma_treinta":MA("Y yo tengo treinta y ocho años."),
 "c68_an_y_tu_coqui":AN("¿Y tú, Coquí? ¿Cuántos años tienes?"),"c68_cq_tres":T("¡Tres!"),"c68_ve_cada":VE("Un bizcocho para cada niño. ¡Con su número!"),
 "c68_ve_cuantos_a":VE("¿Cuántos años tienes?"),"c68_ve_cuantos_b":VE("¿Y tú? ¿Cuántos años tienes?"),
 "c68_be_quieres":BE("Coquí, ¿quieres bizcocho?"),"c68_cq_un_poco":T("¡Un poco!"),"c68_fin":N("Beto tiene cinco años. Y Coquí tiene tres.")})
AGES68=[str(i) for i in range(5,13)]; SIBS68=["2","3","4"]
# Each child's answer is two clips, one for each sentence, played one after the other with the same speaker key (so the draws share their recordings):
# the first has the speaker ("El niño dice: Tengo nueve años." / "El niño dice: Tengo dos hermanos."), the second has none ("Y tengo dos hermanos." / "Y tengo nueve años.").
# The first is the `lead` of the decision and the second its `line` (the engine asks the line again every 9 s: only the second sentence is said again). The correction after a wrong move stays one clip.
SEG=lambda kind,t:{"who":"narr","habla":kind,"text":t}
for kind,F,her in (("nino",NI,"hermanos"),("nina",NA,"hermanas")):
    for e in AGES68:
        c["c68_%s_no_%s"%(kind,e)]=F("¡No! Tengo %s años."%NUM[e]); DIN.add("c68_%s_no_%s"%(kind,e))
        c["c68_%s_edad_%s"%(kind,e)]=F("Tengo %s años."%NUM[e]); c["c68_%s_y_edad_%s"%(kind,e)]=SEG(kind,"Y tengo %s años."%NUM[e])       # the years: said first (with the speaker) or second
        DIN.update(["c68_%s_edad_%s"%(kind,e),"c68_%s_y_edad_%s"%(kind,e)])
    for h in SIBS68:
        c["c68_%s_herm_%s"%(kind,h)]=F("Tengo %s %s."%(NUM[h],her)); c["c68_%s_y_herm_%s"%(kind,h)]=SEG(kind,"Y tengo %s %s."%(NUM[h],her))   # the brothers or sisters: first or second
        DIN.update(["c68_%s_herm_%s"%(kind,h),"c68_%s_y_herm_%s"%(kind,h)])
def tercera68(e,h,t):
    # the third candle, drawn from the numbers that may lie beside these years and this number of brothers or sisters (a nested `if` on the years, then on the brothers; the leaf is the draw)
    def permitidos(ev,hv):
        no={ev,hv}|{"6":{"7"},"7":{"6"},"11":{"12"},"12":{"11"}}.get(ev,set())
        return [str(i) for i in range(1,13) if str(i) not in no]
    def cadena(var,vals,hoja):
        out=hoja(vals[-1])
        for v in reversed(vals[:-1]): out=[{"if":"%s=%s"%(var,v),"then":hoja(v),"else":out}]
        return out
    return cadena(e,AGES68,lambda ev:cadena(h,SIBS68,lambda hv:[{"draw":t,"options":permitidos(ev,hv)}]))
def ronda68(s,kind,quien,pregunta):
    # e: the years, h: the brothers or sisters, t: the third number, o: which is said first (ed: the years, he: the brothers or sisters)
    # p, q, r: what the candles a, b, c hold (edad, herm, otro: dealt out); u, v, w: the numbers on them; k: the candle with the years; n: the number on the candle he touched
    # f, g: the first clip (with the speaker) and the second clip of his answer
    e,h,t,o,p,q,r,u,v,w,k,n,f,g="e"+s,"h"+s,"t"+s,"o"+s,"p"+s,"q"+s,"r"+s,"u"+s,"v"+s,"w"+s,"k"+s,"n"+s,"f"+s,"g"+s
    return [{"draw":e,"options":AGES68},{"draw":h,"options":SIBS68}]+tercera68(e,h,t)+[{"draw":o,"options":["ed","he"]},
     {"calc":f,"cond":o+"=ed","then":"c68_%s_edad_$%s"%(kind,e),"else":"c68_%s_herm_$%s"%(kind,h)},{"calc":g,"cond":o+"=ed","then":"c68_%s_y_herm_$%s"%(kind,h),"else":"c68_%s_y_edad_$%s"%(kind,e)},
     {"reparte":[p,q,r],"options":["edad","herm","otro"]},
     {"calc":u,"cond":p+"=edad","then":"$"+e,"else":"$"+t},{"calc":u,"cond":p+"=herm","then":"$"+h,"else":"$"+u},
     {"calc":v,"cond":q+"=edad","then":"$"+e,"else":"$"+t},{"calc":v,"cond":q+"=herm","then":"$"+h,"else":"$"+v},
     {"calc":w,"cond":r+"=edad","then":"$"+e,"else":"$"+t},{"calc":w,"cond":r+"=herm","then":"$"+h,"else":"$"+w},
     {"calc":k,"cond":p+"=edad","then":"vela_a","else":"vela_b"},{"calc":k,"cond":r+"=edad","then":"vela_c","else":"$"+k},
     act("velas",a="$"+u,b="$"+v,c="$"+w),pregunta,
     {"decide":"do","options":["vela_a","vela_b","vela_c"],"pick":"$"+k,"tests":"tengo … años","lock":True,"lead":["$"+f],"line":"$"+g,
      "right":[{"if":"ok","then":[act("vela68",n="$"+e,a=quien,ok=1),OK],"else":[act("vela68",n="$"+e,a=quien,ok=1)]}],
      "wrong":[{"calc":n,"cond":"x=vela_a","then":"$"+u,"else":"$"+v},{"calc":n,"cond":"x=vela_c","then":"$"+w,"else":"$"+n},
               act("vela68",n="$"+n,a=quien,ok=0),gesto(quien,"no"),"c68_%s_no_$%s"%(kind,e),act("quita68")]+X}]
s68={"id":"cuantos-anos-tienes","title":"¿Cuántos años tienes?","place":"La plaza","scene":"quiosco","next":"el-lunes-hay-frutas",
 "goal":"Push the right number candle into each child's bizcocho by how old the child says he or she is, so Beto's tower of three bizcochos stays whole: every wrong number breaks a bizcocho and the vendedor has to take a whole one from the tower.",
 "stake":{"thing":"bizcochos","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["¿cuántos años tienes?","tengo … años"],"formas_foco":{"tengo … años":["tiene … años"]},
 "back_again":["uno","dos","tres","cuatro","cinco","seis","siete","ocho","nueve","diez","once","doce","treinta","setenta","niño","niña","hermano","hermana","mamá","abuela","tiene","tengo","también","¿dónde está?","quieres","un poco","sí","no","bizcocho"],
 "also_heard":["cumpleaños","cada","número"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"tarde","fiesta":1}},act("torre68",n=3),act("velas",a="5",b="8",c="3"),act("ir",a=START_BARRA),{"wait":500},
  # 1: Beto's birthday; "¿cuántos años tienes?"; five fingers; the 5 twinkles in the box; signed ask on the 5: it goes into the top of Beto's tower
  "c68_cumple","c68_ve_cuantos_beto",gesto("beto","dedos",n=5),"c68_be_cinco",tw("vela_a"),{"wait":600},tw(None),ask("vela_a","c68_donde_cinco",after=[act("vela68",n="5",a="torre",ok=1)]),
  # 2: Ana and Carmen are eight; signed ask on the 8: an 8 for each of them
  {"dots":1},"c68_be_y_tu_ana","c68_an_ocho","c68_ca_ocho",ask("vela_b","c68_donde_ocho",after=[act("vela68",n="8",a="ana",ok=1),act("vela68",n="8",a="carmen",ok=1)]),
  # 3: Luis is ten (a sister: Carmen); abuela is seventy; Ana's mamá is thirty-eight
  {"dots":2},"c68_l_diez",gesto("luis","senala",a="carmen"),"c68_l_abuela","c68_ab_setenta"]+juntos(*[gesto(q,"rie") for q in ("abuela","luis","carmen","ana","beto","mama_ana")])+["c68_ma_treinta",
  # 4: "¿Y tú, Coquí?": three fingers as the question lands; a speaking turn (tres); the 3 goes into the smallest bizcocho
  {"dots":3}]+con(gesto("coqui","dedos",n=3),"c68_an_y_tu_coqui")+["c68_cq_tres",act("vela68",n="3",a="coqui",ok=1),
  # 5: the turn: a niño and a niña run up; the vendedor points at Beto's tower; Beto hugs it; the card shows two places
  {"dots":4}]+juntos(act("llega",quien="nino",a="cola1"),act("llega",quien="nina",a="cola2"))+[gesto("vendedor","senala",a="torre"),"c68_ve_cada",gesto("beto","abraza"),CARD,{"wait":400},
  # A: the niño. B: the niña (she steps up when he has gone). Years, brothers or sisters, the third number and which is said first: drawn afresh each round
  {"dots":5}]+ronda68("a","nino","nino","c68_ve_cuantos_a")+[act("sale",quien="nino"),act("llega",quien="nina",a="cola1"),{"dots":6}]+ronda68("b","nina","nina","c68_ve_cuantos_b"),
 "final":[{"dots":7},gesto("beto","sopla"),   # 8: every child has a bizcocho; the 5 on the tower is lit and blown out; the bizcochos left in the tower decide the last picture; 9: the turn (un poco)
  {"if":"lost=0","then":[act("final68",n=3)],"else":[{"if":"lost=1","then":[act("final68",n=2)],"else":[act("final68",n=1)]}]},
  "c68_be_quieres","c68_cq_un_poco","c68_fin",act("fin")],
 "leer":["c68_cumple","c68_ve_cuantos_beto","c68_be_cinco","c68_donde_cinco","c68_be_y_tu_ana","c68_an_ocho","c68_ca_ocho","c68_donde_ocho","c68_l_diez","c68_l_abuela","c68_ab_setenta","c68_ma_treinta","c68_an_y_tu_coqui","c68_cq_tres","c68_ve_cada",
  "c68_ve_cuantos_a","c68_nino_edad_9","c68_nino_y_herm_2","c68_ve_cuantos_b","c68_nina_herm_3","c68_nina_y_edad_7","c68_be_quieres","c68_cq_un_poco","c68_fin"]}
s68=reuse(s68,{"c68_cq_tres":TG(("tres",["tres"])),"c68_cq_un_poco":TG(("un poco",["un poco"]))})
json.dump(s68,open("cuentos/cuantos-anos-tienes.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files here, and the earlier stories of this run); the places 1 to 5 must be on disk
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s66,s67,s68):
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in EARLIER: print("TURN ON A WORD IN NO EARLIER FOCUS_WORDS",st["id"],cid,t["palabra"])
    EARLIER.update(st["focus_words"])
# every clip id the steps name (with no variable in it) is in the story's clips; every `leer` id too
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
for st in (s66,s67,s68):
    for i in sorted(set(refs([st["beats"],st["final"]]))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
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
