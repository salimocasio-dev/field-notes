# El calendario (place 6, La plaza, scene 4 of 4): stories 69, 70, 71. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/calendario.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `calendario` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: any order among the four scenes of La plaza; every speaking turn's word comes from places 1 to 5.
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   `dia` of every act (luce, cuelga, quita, sol71, the draw variables): "1" to "7" as strings, or "arco" (and "todos" for luce): the script's own values. A wrong touch (`$x`, a thing key such as "dia3")
#       is turned into the same value by a short chain of calcs (xnum), so the acts never see a thing key.
#   `carta` values (the picture cards): frutas, bola, bingo, bicicleta, guitarra, piragua (the opening's), and cafe, flores, pan, pollo, jugo (the game's): the script's own words, no ASCII accents.
#   Cards are drawn independently each round (the script says "each round on its own" and excludes nothing): round B may show the card of round A again.
#   70, "el fin de semana": the arch and the two orange columns are all right. `decide` has `vale` for this (the engine reads it; the kit page does not list it): the draw "arco" gets a decide with vale [dia6, dia7].
#       A right touch on a column then hangs the card there and `cuelga` on the arch slides it up (a second `cuelga`: no act of its own is named for the slide).
#   The wrong move runs in the order of the script: the frog hangs the card, the señora's correction, the picture's loss (revienta69 / canelo70 / se_va71 and the count act), then the cross and one step (X).
#   The counts (`globos` / `lazos` / `gente`) are set after the picture act, from `lost`, before X (as the other generators do with `botella`, `hielo`).
#   Start state of 70: the four opening cards are hung by `cuelga` (quien senora) before the first beat; the act animates unless the scene's designer makes it instant at the start of a story.
#   Ranges in "Back again" ("lunes to domingo", "uno to siete") are written out.
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); SA=lambda t:D("senora","La señora",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
MINE=("el-lunes-hay-frutas","el-fin-de-semana","hoy-y-manana")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c69_a_$da_$ca"): never renamed
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
# What he hears when he pokes a person already recorded (don Tito and Beto are not recorded as named people: they add nothing)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora.")),"perro":("c_n_perro",N("Es el perro. Se llama Canelo."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}

DIA={"1":"lunes","2":"martes","3":"miércoles","4":"jueves","5":"viernes","6":"sábado","7":"domingo"}
CN={"cafe":"café","flores":"flores","pan":"pan","jugo":"jugo","pollo":"pollo"}   # the five cards of the games, as the line says them ("hay café")

def xnum(n,arco=False):
    # the thing he touched (`$x`: "dia3", or "arco") as the act value: "3", or "arco" (in `xd`)
    ks=[("dia%d"%i,str(i)) for i in range(1,n+1)]+([("arco","arco")] if arco else [])
    return [{"calc":"xd","cond":"x="+k,"then":v,"else":"0" if i==0 else "$xd"} for i,(k,v) in enumerate(ks)]
def succ(src,out,lo,hi):
    # out = src + 1 for src from lo to hi
    return [{"calc":out,"cond":"%s=%d"%(src,v),"then":str(v+1),"else":str(hi+1) if v==lo else "$"+out} for v in range(lo,hi)]
def otro(out,inv,e,opts):
    # out = the e-th (1 to len-1) of the options that are not `inv`: a second card that is never the first
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

# ---------------- 69. El lunes hay frutas ----------------
# The señora hangs picture cards on the first four columns (lunes to jueves). Round A and round B: a day (1 to 4) and a card (café, flores, pan, jugo), each drawn on its own. A miss: she pulls the tack, a balloon bursts.
nm,nc=nombres("senora","luis","abuela","coqui"); c=dict(comunes); c.update(nc)
c.update({"c69_trabaja":N("La señora trabaja en la plaza."),"c69_sa_buenos":SA("¡Buenos días, Coquí!"),"c69_cq_buenos":T("¡Buenos días!"),"c69_sa_cuenta":SA("Lunes, martes, miércoles, jueves."),
 "c69_donde_lunes":N("¿Dónde está el lunes?"),"c69_sa_lunes":SA("El lunes hay frutas en la plaza."),"c69_donde_frutas":N("¿Dónde ponemos las frutas?"),
 "c69_sa_martes":SA("El martes los niños juegan bola. ¿Vienes el martes, Beto?"),"c69_donde_bola":N("¿Y dónde ponemos la bola?"),
 "c69_sa_miercoles":SA("El miércoles hay bingo."),"c69_ab_miercoles":AB("¡El miércoles! Yo voy el miércoles."),"c69_donde_miercoles":N("¿Dónde está el miércoles?"),
 "c69_sa_jueves":SA("Y el jueves corren bicicleta."),"c69_l_jueves":L("¡El jueves voy yo!"),"c69_donde_bici":N("¿Dónde ponemos la bicicleta?"),
 "c69_sa_muybien":SA("Lunes, martes, miércoles y jueves. ¡Muy bien!"),"c69_sa_mas":SA("Hay más. Ahora tú, Coquí."),
 "c69_sa_vienes":SA("¿Vienes el lunes, Coquí?"),"c69_cq_voy":T("¡Sí, voy!"),"c69_fin":N("El lunes hay frutas en la plaza. Y Coquí va.")})
C69=["cafe","flores","pan","jugo"]
for d in "1234":
    for k in C69:
        c["c69_a_%s_%s"%(d,k)]=SA("El %s hay %s."%(DIA[d],CN[k])); c["c69_b_%s_%s"%(d,k)]=SA("Y el %s hay %s."%(DIA[d],CN[k])); c["c69_no_%s_%s"%(d,k)]=SA("No, Coquí. Hay %s el %s."%(CN[k],DIA[d]))
        DIN.update(["c69_a_%s_%s"%(d,k),"c69_b_%s_%s"%(d,k),"c69_no_%s_%s"%(d,k)])
def ronda69(s):
    # one round: the señora holds up a card and says its day (both drawn). Right: the frog hangs it there, the column lights. Wrong: he hangs it under another day; she says no, pulls the tack, a balloon bursts.
    d,k="d"+s,"c"+s
    return [{"draw":d,"options":["1","2","3","4"]},{"draw":k,"options":C69},act("muestra",carta="$"+k),
     {"decide":"do","options":["dia1","dia2","dia3","dia4"],"pick":"dia$"+d,"tests":"$"+d,"lock":True,"lead":[],"line":"c69_%s_$%s_$%s"%(s,d,k),
      "right":[act("cuelga",carta="$"+k,dia="$"+d,quien="coqui"),act("luce",dia="$"+d),star],
      "wrong":xnum(4)+[act("cuelga",carta="$"+k,dia="$xd",quien="coqui"),"c69_no_$%s_$%s"%(d,k),act("revienta69"),resta(lambda n:act("globos",n=n))]+X}]
s69={"id":"el-lunes-hay-frutas","title":"El lunes hay frutas","place":"La plaza","scene":"calendario","next":"el-fin-de-semana",
 "goal":"Hang the señora's picture cards under the right day of the week (lunes to jueves) so that Beto's three balloons stay tied to the board's post: every card under the wrong day costs a balloon, which bursts.",
 "stake":{"thing":"globos","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["lunes","martes","miércoles","jueves"],"formas_foco":{},
 "back_again":["hay","fruta","bola","bicicleta","juega","corre","niños","voy","va","vienes","café","flor","pan","jugo","pone","buenos días","trabaja","¿dónde está?","sí","ahora","más","tú"],
 "also_heard":[],"names":nm,"palabras":{"1":"lunes","2":"martes","3":"miércoles","4":"jueves"},"clips":c,
 "beats":[{"set":{"hora":"manana","tela":1}},act("globos",n=3),{"wait":500},
  # 1: the señora; a speaking turn (buenos días); the four columns light as she names them; the signed ask on the first column; the frog hops under it
  {"dots":1},"c69_trabaja","c69_sa_buenos","c69_cq_buenos"]+con(act("cuenta",de=1,a=4),"c69_sa_cuenta")+[
  ask("dia1","c69_donde_lunes",after=[act("luce",dia="1"),act("ir",a="escalon1")]),
  # 2: the fruit on the first column; the ball on the second; Beto nods hard
  {"dots":2},act("muestra",carta="frutas"),"c69_sa_lunes",ask("dia1","c69_donde_frutas",after=[act("cuelga",carta="frutas",dia="1",quien="coqui")]),
  act("muestra",carta="bola"),"c69_sa_martes",gesto("beto","si"),ask("dia2","c69_donde_bola",after=[act("cuelga",carta="bola",dia="2",quien="coqui")]),
  # 3: abuela walks by (no act named); the bingo on the third; Luis rides up (no act named); the bicycle on the fourth
  {"dots":3},act("muestra",carta="bingo"),"c69_sa_miercoles","c69_ab_miercoles",ask("dia3","c69_donde_miercoles",after=[act("cuelga",carta="bingo",dia="3",quien="coqui")]),
  "c69_sa_jueves","c69_l_jueves",ask("dia4","c69_donde_bici",after=[act("cuelga",carta="bicicleta",dia="4",quien="coqui")]),
  # 4: the señora steps back and looks at the four cards
  {"dots":4},gesto("senora","mira",a="tabla"),"c69_sa_muybien",
  # 5: the box of more cards, a tack, Beto pulls at the balloons (no act named); the card shows two places
  {"dots":5},"c69_sa_mas",CARD,{"wait":400},
  # 6: A. 7: B. Each drawn afresh
  {"dots":6}]+ronda69("a")+[{"dots":7}]+ronda69("b"),
 "final":[{"dots":8},gesto("senora","mira",a="tabla"),baja3(lambda n:act("final69",n=n)),   # 8: the balloons, by what was lost
  {"dots":9},"c69_sa_vienes","c69_cq_voy","c69_fin",act("fin")],
 "leer":["c69_trabaja","c69_sa_buenos","c69_cq_buenos","c69_sa_cuenta","c69_donde_lunes","c69_sa_lunes","c69_donde_frutas","c69_sa_martes","c69_donde_bola","c69_sa_miercoles","c69_ab_miercoles","c69_donde_miercoles",
  "c69_sa_jueves","c69_l_jueves","c69_donde_bici","c69_sa_muybien","c69_sa_mas","c69_a_4_cafe","c69_b_2_flores","c69_sa_vienes","c69_cq_voy","c69_fin"]}
s69=reuse(s69,{"c69_cq_buenos":TG(("buenos días",["buenos días","buenos dias"])),"c69_cq_voy":TG(("voy",["voy","sí voy"]))})
json.dump(s69,open("cuentos/el-lunes-hay-frutas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 70. El fin de semana ----------------
# The señora says when a card is (a card of flores, pan, pollo, jugo, and the day: viernes, sábado, domingo or el fin de semana), each drawn on its own. For el fin de semana the arch and the two orange columns are all right.
# A miss: the card flutters down onto the kite's tail, Canelo jumps on it, a bow comes off.
nm,nc=nombres("senora","luis","carmen","perro","coqui"); c=dict(comunes); c.update(nc)
c.update({"c70_vienen":N("Luis y Carmen vienen de la escuela."),"c70_sa_viernes":SA("Lunes, martes, miércoles, jueves... y viernes."),"c70_ca_clases":CA("El viernes hay clases."),"c70_donde_viernes":N("¿Dónde está el viernes?"),
 "c70_sa_despues":SA("Y después, sábado y domingo."),"c70_l_sabado":L("¡El sábado no hay clases! ¡Y el domingo tampoco!"),"c70_donde_sabado":N("¿Dónde está el sábado?"),"c70_donde_domingo":N("¿Y dónde está el domingo?"),
 "c70_sa_finde":SA("El sábado y el domingo son el fin de semana."),"c70_ca_gusta":CA("¡Me gusta el fin de semana!"),"c70_l_ati":L("¿Y a ti, Coquí?"),"c70_cq_tambien":T("¡A mí también!"),
 "c70_sa_musica":SA("El viernes hay música en la plaza."),"c70_l_musica":L("¡Música! Me gusta la música."),"c70_donde_musica":N("¿Dónde ponemos la música?"),
 "c70_sa_piraguas":SA("Y el fin de semana hay piraguas."),"c70_donde_piraguas":N("¿Dónde ponemos las piraguas?"),
 "c70_l_chiringa":L("¡Mira la chiringa! El sábado la volamos."),"c70_ca_canelo":CA("¡Canelo, no!"),
 "c70_l_vamos":L("¡Es sábado! ¡Vamos!"),"c70_ca_vienes":CA("Coquí, ¿vienes el domingo también?"),"c70_cq_si":T("¡Sí!"),"c70_fin":N("El sábado y el domingo no hay clases. ¡Es el fin de semana!")})
C70=["flores","pan","pollo","jugo"]; W70={"5":"viernes","6":"sábado","7":"domingo","arco":"fin de semana"}
for d,w in W70.items():
    for k in C70:
        c["c70_a_%s_%s"%(d,k)]=SA("El %s hay %s."%(w,CN[k])); c["c70_b_%s_%s"%(d,k)]=SA("Y el %s hay %s."%(w,CN[k])); c["c70_no_%s_%s"%(d,k)]=SA("No, Coquí. Hay %s el %s."%(CN[k],w))
        DIN.update(["c70_a_%s_%s"%(d,k),"c70_b_%s_%s"%(d,k),"c70_no_%s_%s"%(d,k)])
OP70=["dia1","dia2","dia3","dia4","dia5","dia6","dia7","arco"]
def ronda70(s):
    # one round: a card (flores, pan, pollo, jugo) and when (5, 6, 7 or arco), each drawn. The right place is the day's column, or the arch; for arco the two orange columns count too (vale), and the card then slides up to the arch.
    d,k,p="d"+s,"c"+s,"p"+s
    def decide(vale):
        st={"decide":"do","options":OP70,"pick":"$"+p,"tests":"$"+d,"lock":True,"lead":[],"line":"c70_%s_$%s_$%s"%(s,d,k),
            "right":xnum(7,True)+[{"calc":"pl","cond":"ok","then":"$xd","else":"$"+d},act("cuelga",carta="$"+k,dia="$pl",quien="coqui"),
                                  {"if":d+"=arco","then":[{"if":"pl=arco","then":[],"else":[act("cuelga",carta="$"+k,dia="arco",quien="coqui")]}]},star],
            "wrong":xnum(7,True)+[act("cuelga",carta="$"+k,dia="$xd",quien="coqui"),"c70_no_$%s_$%s"%(d,k),act("canelo70"),resta(lambda n:act("lazos",n=n)),"c70_ca_canelo"]+X}
        if vale: st["vale"]=vale
        return st
    return [{"draw":d,"options":["5","6","7","arco"]},{"draw":k,"options":C70},{"calc":p,"cond":d+"=arco","then":"arco","else":"dia$"+d},act("muestra",carta="$"+k),
     {"if":d+"=arco","then":[decide(["dia6","dia7"])],"else":[decide(None)]}]
s70={"id":"el-fin-de-semana","title":"El fin de semana","place":"La plaza","scene":"calendario","next":"hoy-y-manana",
 "goal":"Hang the señora's cards under the right day (viernes, sábado, domingo) or on the arch for the fin de semana, so that the kite Luis and Carmen made keeps its three paper bows: every wrong place lets Canelo tear one off.",
 "stake":{"thing":"lazos","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["viernes","sábado","domingo","fin de semana"],"formas_foco":{},
 "back_again":["lunes","martes","miércoles","jueves","hay","no hay","me gusta","también","después","vamos","vienes","flor","pan","pollo","jugo","piragua","pone","vuela","mira","sí","no"],
 "also_heard":["clases","tampoco","música","chiringa"],"names":nm,"palabras":dict(W70),"clips":c,
 "beats":[{"set":{"hora":"tarde"}},act("lazos",n=3),
  act("cuelga",carta="frutas",dia="1",quien="senora"),act("cuelga",carta="bola",dia="2",quien="senora"),act("cuelga",carta="bingo",dia="3",quien="senora"),act("cuelga",carta="bicicleta",dia="4",quien="senora"),{"wait":500},
  # 1: Luis and Carmen come from school (no act named); the fifth column; Carmen holds up her school bag
  {"dots":1},"c70_vienen",gesto("senora","senala",a="tabla"),"c70_sa_viernes",act("luce",dia="5"),gesto("carmen","bulto"),"c70_ca_clases",ask("dia5","c70_donde_viernes",after=[act("luce",dia="5")]),
  # 2: the two orange columns; Luis throws his school bag into the air; two signed asks (sábado, domingo)
  {"dots":2}]+con(act("cuenta",de=6,a=7),"c70_sa_despues")+[gesto("luis","bulto"),"c70_l_sabado",
  ask("dia6","c70_donde_sabado",after=[act("luce",dia="6")]),ask("dia7","c70_donde_domingo",after=[act("luce",dia="7")]),
  # 3: the arch of flags; a speaking turn (también)
  {"dots":3},gesto("senora","senala",a="arco"),"c70_sa_finde",tw("arco"),{"wait":600},tw(None),"c70_ca_gusta","c70_l_ati","c70_cq_tambien",
  # 4: the guitar on the fifth column; the piragua on the arch
  {"dots":4},act("muestra",carta="guitarra"),"c70_sa_musica","c70_l_musica",ask("dia5","c70_donde_musica",after=[act("cuelga",carta="guitarra",dia="5",quien="coqui")]),
  act("muestra",carta="piragua"),"c70_sa_piraguas",ask("arco","c70_donde_piraguas",after=[act("cuelga",carta="piragua",dia="arco",quien="coqui")]),
  # 5: Luis lifts the kite and lays it down, Canelo puts a paw on the tail (no act named); more cards; the card shows two places
  {"dots":5},"c70_l_chiringa","c70_ca_canelo",CARD,{"wait":400},
  # 6: A. 7: B. Each drawn afresh
  {"dots":6}]+ronda70("a")+[{"dots":7}]+ronda70("b"),
 "final":[{"dots":8},{"set":{"hora":"manana"}},act("luce",dia="6"),"c70_l_vamos",baja3(lambda n:act("final70",n=n)),   # 8: the next morning, the sixth column lit; the kite, by the bows left
  {"dots":9},"c70_ca_vienes","c70_cq_si","c70_fin",act("fin")],
 "leer":["c70_vienen","c70_sa_viernes","c70_ca_clases","c70_donde_viernes","c70_sa_despues","c70_l_sabado","c70_donde_sabado","c70_donde_domingo","c70_sa_finde","c70_ca_gusta","c70_l_ati","c70_cq_tambien","c70_sa_musica","c70_l_musica","c70_donde_musica",
  "c70_sa_piraguas","c70_donde_piraguas","c70_l_chiringa","c70_ca_canelo","c70_a_7_flores","c70_b_arco_pollo","c70_l_vamos","c70_ca_vienes","c70_cq_si","c70_fin"]}
s70=reuse(s70,{"c70_cq_tambien":TG(("también",["también","tambien","a mí también"])),"c70_cq_si":TG(("sí",["sí","si"]))})
json.dump(s70,open("cuentos/el-fin-de-semana.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 71. Hoy y mañana ----------------
# The sun peg is on a day: round A on lunes to jueves (drawn), round B on the day after. The señora holds one card and says two things, what there is today and what there is tomorrow: the two cards are two of
# café, flores, pan, pollo, jugo (never the same), which is said first is drawn, and whether the card she holds is today's or tomorrow's is drawn; each round on its own. A miss: one of the three goes home with his basket empty.
nm,nc=nombres("senora","abuela","senor","coqui"); c=dict(comunes); c.update(nc)
c.update({"c71_nuevo":N("Es un nuevo día en la plaza. Y es una semana nueva."),"c71_sa_hoy_lunes":SA("Buenos días. Hoy es lunes."),"c71_cual_hoy":N("¿Cuál es el día de hoy?"),
 "c71_sa_manana_martes":SA("Y mañana es martes."),"c71_cual_manana":N("¿Y cuál es el día de mañana?"),"c71_sa_cuenta":SA("Un día, dos días, tres días, cuatro, cinco, seis, siete. Siete días son una semana."),
 "c71_toca_semana":N("Toca toda la semana."),"c71_sa_hoy_frutas":SA("Hoy hay frutas."),"c71_donde_frutas":N("¿Dónde ponemos las frutas?"),"c71_sa_manana_bola":SA("Y mañana los niños juegan bola."),"c71_donde_bola":N("¿Y dónde ponemos la bola?"),
 "c71_ab_que_dia":AB("¿Qué día es hoy?"),"c71_sa_martes":SA("Hoy es martes. Hoy juegan bola. Y mañana hay bingo."),"c71_ab_bingo":AB("Coquí, ¿hay bingo hoy?"),"c71_cq_no":T("¡No!"),"c71_sa_hoy_no":SA("Hoy no. Mañana."),
 "c71_sa_otra":SA("Otra semana. Ahora tú, Coquí."),"c71_sa_tarde":SA("Ya es tarde, Coquí. Adiós."),"c71_cq_hasta":T("¡Hasta mañana!"),"c71_fin":N("Mañana es otro día en la plaza.")})
for d in "1234": c["c71_a_%s"%d]=SA("Hoy es %s."%DIA[d]); DIN.add("c71_a_%s"%d)
for d in "2345": c["c71_b_%s"%d]=SA("Otro día. Hoy es %s."%DIA[d]); DIN.add("c71_b_%s"%d)
C71=["cafe","flores","pan","pollo","jugo"]
for t in C71:
    c["c71_no_hoy_%s"%t]=SA("No, Coquí. Hoy hay %s."%CN[t]); c["c71_no_manana_%s"%t]=SA("No, Coquí. Mañana hay %s."%CN[t]); DIN.update(["c71_no_hoy_%s"%t,"c71_no_manana_%s"%t])
    for u in C71:
        if u==t: continue
        c["c71_hm_%s_%s"%(t,u)]=SA("Hoy hay %s. Mañana hay %s."%(CN[t],CN[u])); c["c71_mh_%s_%s"%(t,u)]=SA("Mañana hay %s. Hoy hay %s."%(CN[u],CN[t])); DIN.update(["c71_hm_%s_%s"%(t,u),"c71_mh_%s_%s"%(t,u)])
OP71=["dia%d"%i for i in range(1,8)]
def ronda71(s,primera):
    # one round. s: the sun's day, n: the day after; t: today's card, u: tomorrow's; o: which is said first; h: whether the card she holds is today's (hoy) or tomorrow's (manana); z: the card she holds, k: the other; g, i: the days they go under; p: the right column
    S,Nn,t,u,e,o,h,z,k,g,i,p=[v+s for v in ("s","n","t","u","e","o","h","z","k","g","i","p")]
    return primera+[{"draw":t,"options":C71},{"draw":e,"options":["1","2","3","4"]}]+otro(u,t,e,C71)+[{"draw":o,"options":["hm","mh"]},{"draw":h,"options":["hoy","manana"]},
     {"calc":z,"cond":h+"=hoy","then":"$"+t,"else":"$"+u},{"calc":k,"cond":h+"=hoy","then":"$"+u,"else":"$"+t},
     {"calc":g,"cond":h+"=hoy","then":"$"+S,"else":"$"+Nn},{"calc":i,"cond":h+"=hoy","then":"$"+Nn,"else":"$"+S},{"calc":p,"cond":h+"=hoy","then":"dia$"+S,"else":"dia$"+Nn},
     act("muestra",carta="$"+z),
     {"decide":"do","options":OP71,"pick":"$"+p,"tests":"$"+h,"lock":True,"lead":[],"line":"c71_$%s_$%s_$%s"%(o,t,u),
      "right":[act("cuelga",carta="$"+z,dia="$"+g,quien="coqui"),act("lee71",ok=1),star,act("cuelga",carta="$"+k,dia="$"+i,quien="senora")],
      "wrong":xnum(7)+[act("cuelga",carta="$"+z,dia="$xd",quien="coqui"),act("lee71",ok=0),"c71_no_$%s_$%s"%(h,z),act("quita",dia="$xd"),
                       {"if":"lost=0","then":[act("se_va71",quien="senor"),act("gente",n=2)],"else":[act("se_va71",quien="tito"),act("gente",n=1)]}]+X}]
rA=ronda71("a",[{"draw":"sa","options":["1","2","3","4"]}]+succ("sa","na",1,4)+[act("sol71",dia="$sa"),"c71_a_$sa"])
rB=ronda71("b",[act("noche71")]+succ("sa","sb",1,4)+succ("sb","nb",2,5)+[act("sol71",dia="$sb"),"c71_b_$sb"])
s71={"id":"hoy-y-manana","title":"Hoy y mañana","place":"La plaza","scene":"calendario","next":"la-playa",
 "goal":"Hang the card the señora holds under the right day, today's or tomorrow's, so that abuela, don Tito and the señor stay on the seat with their baskets and go home with something in them: every card under the wrong day sends one of them home with an empty basket.",
 "stake":{"thing":"gente","steps":3},"dots":10,"bien":"si_muy_bien",
 "focus_words":["hoy","mañana","día","semana"],"formas_foco":{"día":["días"]},
 "back_again":["lunes","martes","miércoles","jueves","viernes","sábado","domingo","hay","no hay","otro","nuevo","todo","uno","dos","tres","cuatro","cinco","seis","siete","buenos días","adiós","hasta mañana","fruta","bola","juega","café","flor","pan","pollo","jugo","pone","tarde","ya","no"],
 "also_heard":[],"names":nm,"palabras":{"hoy":"hoy","manana":"mañana"},"clips":c,
 "beats":[{"set":{"hora":"manana"}},act("gente",n=3),{"wait":500},
  # 1: a new week; the sun on the first column; the signed ask on it (the sun shines)
  {"dots":1},"c71_nuevo",act("sol71",dia="1"),"c71_sa_hoy_lunes",ask("dia1","c71_cual_hoy",after=[tw("sol"),{"wait":700},tw(None)]),
  # 2: mañana is martes (signed ask on the second column)
  {"dots":2},gesto("senora","senala",a="dia2"),"c71_sa_manana_martes",ask("dia2","c71_cual_manana",after=[act("luce",dia="2")]),
  # 3: the seven columns in turn; a week; the signed ask on the whole board
  {"dots":3}]+con(act("cuenta",de=1,a=7),"c71_sa_cuenta")+[ask("tabla","c71_toca_semana",after=[act("luce",dia="todos")]),
  # 4: the fruit under the sun (abuela fills her basket); the ball under the second column
  {"dots":4},act("muestra",carta="frutas"),"c71_sa_hoy_frutas",ask("dia1","c71_donde_frutas",after=[act("cuelga",carta="frutas",dia="1",quien="coqui")]),act("cesta71",quien="abuela"),
  act("muestra",carta="bola"),"c71_sa_manana_bola",ask("dia2","c71_donde_bola",after=[act("cuelga",carta="bola",dia="2",quien="coqui")]),
  # 5: a night; the sun on the second column; the bingo under the third; abuela half gets up; a speaking turn (no)
  {"dots":5},act("noche71"),act("sol71",dia="2"),"c71_ab_que_dia","c71_sa_martes",act("cuelga",carta="bingo",dia="3",quien="senora"),gesto("abuela","levanta"),"c71_ab_bingo","c71_cq_no","c71_sa_hoy_no",
  # 6: every card comes down; the card shows two places
  {"dots":6},act("vacia"),"c71_sa_otra",CARD,{"wait":400},
  # 7: A. 8: B. Each drawn afresh
  {"dots":7}]+rA+[{"dots":8}]+rB,
 "final":[{"dots":9},{"set":{"hora":"noche"}},baja3(lambda n:act("final71",n=n)),   # 9: the lamps; the seat, by who was lost
  {"dots":10},"c71_sa_tarde","c71_cq_hasta","c71_fin",act("fin")],
 "leer":["c71_nuevo","c71_sa_hoy_lunes","c71_cual_hoy","c71_sa_manana_martes","c71_cual_manana","c71_sa_cuenta","c71_toca_semana","c71_sa_hoy_frutas","c71_donde_frutas","c71_sa_manana_bola","c71_donde_bola","c71_ab_que_dia","c71_sa_martes","c71_ab_bingo","c71_cq_no","c71_sa_hoy_no",
  "c71_sa_otra","c71_a_3","c71_hm_flores_pan","c71_b_4","c71_mh_cafe_jugo","c71_sa_tarde","c71_cq_hasta","c71_fin"]}
s71=reuse(s71,{"c71_cq_no":TG(("no",["no"])),"c71_cq_hasta":TG(("hasta mañana",["hasta mañana","hasta manana"]))})
json.dump(s71,open("cuentos/hoy-y-manana.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
# every id the steps name (with no variable in it) is in the story's clips; every `leer` id too; every speaking turn is on a word of an earlier story (the files on disk: places 1 to 5)
earlier=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s69,s70,s71):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:69|70|71)_|si_|yo_|p_n_|b_n_|n_|esta_|cq_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
