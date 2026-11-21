# La entrada (place 8, La fonda, scene 1 of 4): stories 84, 85, 86. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/entrada.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `entrada` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: gen_entrada first (each generator sees only what was recorded before it: places 1 to 7 must be on disk; gen_mostrador ... gen_cielo).
# Every speaking turn of this scene is on a word of places 1 to 4 (buenas tardes: El colmado; tengo hambre, listo: La cocina; gracias, sí, quiero: La casa): no word of a later story of La fonda is used.
#
# Where the script or its Needs list leaves a value open, this file fixes it in ONE place (and the report says so):
#   Tables (the script now says it): mesa1 is the FAR table (by the kitchen's door), mesa2 the middle one (the family's in 86), mesa3 the NEAR one. In 84 the table with the flowers and the star card is mesa3 (the best), then mesa2, then mesa1 (the worst).
#   FLORES: that table, `mesa3` (84). `mesas84` and `final84` {n} count the good tables left, best first: 3 = all three, 2 = mesa2 and mesa1 (the flowers' is gone), 1 = only mesa1.
#   TRAMO: `avanza84` / `espera84` {tramo}: "a" = from the doormat to the stand (round A and the opening's hop), "b" = from the stand past the rope (round B).
#   FAMILIA: the family's spots at the door (84): abuela puerta1, abuelo puerta2, luis puerta3, carmen puerta4 (the order the script names them in).
#   85, the two game tables: `mesa2` (red in the opening) and `mesa3` (blue in the opening); nobody sits at `mesa1` (kept for a party). `manteles` {a, b}: a is the cloth of mesa2, b of mesa3; cloths are the plan's words rojo, azul, verde, amarillo, blanco.
#   85, who asks each round: drawn from the five people of El parque (señor, señora, hombre, mujer, joven); round B's is not round A's. Round B's two colours are drawn from the three not used in A.
#       A says "Una mesa para dos, por favor.", B "Para dos, por favor." (the script's two examples).
#   85, `sienta85` {quienes}: the key of the one who asks (the act is to add the other of the couple); `ante_cuerda1` is where the asker waits.
#   86, `cosa_a` is the thing at the LEFT of the tray, `cosa_b` the one at the right; `bandeja86` {izq}: "con" or "sin", the one at the left; `da86` {cual}: cosa_a or cosa_b, {a}: the key of the one who asked.
#   86, the opening's tray: water, izq=con (cosa_a has the lemon, cosa_b has none).
#   `hora`: 84 ocaso (dusk); 85 noche, and tarde_noche from step 5 on (the window darker); 86 noche.
#   `cuerda`: set to "abierta" at the end of round B's right branch (she unhooks the rope); the act may also do it.
#   Counts: `mesas84`, `dulces`, `velas` {n} = what is left (3 at the start); `final84`, `final85`, `final86` {n} = what is left at the end.
#   The wrong move runs in the order of the script: what happens, the correction line, the picture's loss, then the card's cross (X); in 84 the script puts the cross BEFORE the best table is gone, so `mesas84` follows X there
#   (its n is worked out from `lost` before X: `ma`).
#   84, B: behind the family stand the señor and the señora (still at cola1, cola2) when round A was right; when it was wrong (they have their table) the hombre and the mujer come in to cola1, cola2.
#   86, B's speaker is not A's.
import json,glob,os,re,collections,itertools
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); ABO=lambda t:D("abuelo","Abuelo",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
ME=lambda t:D("mesera","La mesera",t); MO=lambda t:D("mesero","El mesero",t)
SA=lambda t:D("senora","La señora",t); SE=lambda t:D("senor","El señor",t); HO=lambda t:D("hombre","El hombre",t); MU=lambda t:D("mujer","La mujer",t); JO=lambda t:D("joven","El joven",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time (people walking in together): all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
FLORES="mesa3"                                            # the table with the flowers and the star card (84)
TRAMO_A,TRAMO_B="a","b"                                   # the two stretches of the way in (84)
FAMILIA=(("abuela","puerta1"),("abuelo","puerta2"),("luis","puerta3"),("carmen","puerta4"))   # the family in the open door, behind the frog (84)
MINE=("bienvenidos","esta-libre","con-y-sin")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c85_pa_$qa"): never renamed
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
# What he hears when he pokes a person already recorded (the mesera and the mesero are new: they add nothing)
NM={"abuela":("abuela",N("Esta es abuela.")),"abuelo":("n_abuelo",N("Este es abuelo.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora.")),"hombre":("b_n_hombre",N("Es un hombre.")),"mujer":("b_n_mujer",N("Es una mujer.")),"joven":("b_n_joven",N("Es un joven."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}
def otro(out,inv,e,opts):
    # out = the e-th (1 to len-1) of the options that are not `inv`: a second value that is never the first
    def rama(v):
        o=[x for x in opts if x!=v]
        return [{"calc":out,"cond":e+"=1","then":o[0],"else":o[1]}]+[{"calc":out,"cond":"%s=%d"%(e,i+1),"then":o[i],"else":"$"+out} for i in range(2,len(o))]
    ch=rama(opts[-1])
    for v in reversed(opts[:-1]): ch=[{"if":inv+"="+v,"then":rama(v),"else":ch}]
    return ch

# ---------------- 84. Bienvenidos ----------------
# The way in has two stretches (doormat to the stand, the stand past the rope). At each the mesera calls "¡Adelante, por favor!" or "Un momento, por favor." (drawn, each round on its own): the frog hops up to her, or sits on the bench.
# A miss: the other thing is done, the pair behind them (A: the señor and the señora; B: the señor and the señora if round A was right, the hombre and the mujer if it was wrong) get the best table that is free; the sign shows the right place.
# The family sits only in the ending, at the best table left (mesa3 with the flowers, then mesa2, then mesa1).
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui","senor","senora","hombre","mujer"); c=dict(comunes); c.update(nc)
c.update({"c84_ab_mira":AB("Mira, Coquí: la fonda. Aquí comemos."),"c84_me_hola":ME("¡Hola! ¡Bienvenidos!"),"c84_cq_tardes":T("¡Buenas tardes!"),"c84_donde_mesera":N("¿Dónde está la mesera de la fonda?"),
 "c84_donde_espera":N("¿Dónde espera Coquí un momento?"),"c84_abo_momento":ABO("Un momento, Coquí. Espera aquí."),
 "c84_me_adelante":ME("¡Adelante!"),"c84_ab_adelante":AB("Adelante, Coquí. Vamos."),"c84_donde_adelante":N("¡Adelante! ¿A dónde va Coquí?"),
 "c84_me_bienvenido":ME("Bienvenido, Coquí. ¿Cuántos son?"),"c84_ab_somos":AB("Somos cuatro... y Coquí."),"c84_me_gente":ME("Un momento. Hay mucha gente."),
 "c84_pf_adelante":ME("¡Adelante, por favor!"),"c84_pf_momento":ME("Un momento, por favor."),
 "c84_no_adelante":ME("¡No, Coquí! ¡Adelante!"),"c84_no_momento":ME("¡No, Coquí! ¡Un momento!"),
 "c84_me_bienvenidos":ME("Bienvenidos. ¿Tienen hambre?"),"c84_cq_hambre":T("¡Sí, tengo hambre!"),"c84_fin":N("La familia está en la fonda. Y Coquí tiene hambre.")})
DIN.update(["c84_pf_adelante","c84_pf_momento","c84_no_adelante","c84_no_momento"])
def ronda84(s,tramo,antes,despues):
    # d: what she calls (adelante, momento); p: the right place (the mesera for adelante, the bench for momento); m: what is left of the good tables after this miss
    d,p,m="d"+s,"p"+s,"m"+s
    return antes+[{"draw":d,"options":["adelante","momento"]},{"calc":p,"cond":d+"=adelante","then":"mesera","else":"banco"},
     {"decide":"do","options":["mesera","banco"],"pick":"$"+p,"tests":"$"+d,"lock":True,"lead":[],"line":"c84_pf_$"+d,
      "right":[{"if":d+"=adelante","then":[act("avanza84",tramo=tramo,ok=1)],"else":[act("espera84",tramo=tramo,ok=1)]},star]+despues,
      "wrong":[{"if":d+"=adelante","then":[act("espera84",tramo=tramo,ok=0)],"else":[act("avanza84",tramo=tramo,ok=0)]},"c84_no_$"+d,
               {"calc":m,"cond":"lost=0","then":"2","else":"1"}]+X+[{"if":m+"=2","then":[act("mesas84",n=2)],"else":[act("mesas84",n=1)]}]}]
s84={"id":"bienvenidos","title":"Bienvenidos","place":"La fonda","scene":"entrada","next":"esta-libre",
 "goal":"Lead the family into the fonda to the table with the flowers and the star card: when the mesera calls them on they hop up to her, when she says to wait a moment they wait on the bench, and every time the frog does the other the people behind them get the best table that is left.",
 "stake":{"thing":"mesas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["fonda","mesera","bienvenido","adelante","un momento"],"formas_foco":{"bienvenido":["bienvenidos"]},
 "back_again":["buenas tardes","hola","tengo hambre","familia","gente","mucho","hay","espera","va","vamos","aquí","cuatro","por favor","sí","mira"],
 "also_heard":["comemos","son","somos","tienen"],"names":nm,"palabras":{"momento":"un momento"},"clips":c,
 "beats":[{"set":{"hora":"ocaso","cuerda":"puesta"}},act("mesas84",n=3),act("ir",a="felpudo"),{"wait":500},tw(FLORES),{"wait":600},tw(None),
  # 1: abuela points at the table with the flowers; the mesera greets them; a speaking turn (buenas tardes); signed ask on the mesera: she bows
  {"dots":1},gesto("abuela","senala",a=FLORES),"c84_ab_mira"]+con(gesto("mesera","saluda"),"c84_me_hola")+["c84_cq_tardes",ask("mesera","c84_donde_mesera",after=[gesto("mesera","reverencia")]),
  # 2: a mesero crosses with the plates, the mesera holds up a hand; signed ask on the bench: the frog sits there while the plates go by
  {"dots":2},dict(act("pasa84",que="platos"),suelto=1),gesto("mesera","mano"),"c84_pf_momento",ask("banco","c84_donde_espera",after=[act("ir",a="banco_coqui")]),act("ya"),"c84_abo_momento",
  # 3: the mesera waves them on; signed ask on the mesera: the frog hops up to her stand and the family after him
  {"dots":3},gesto("mesera","pasa"),"c84_me_adelante","c84_ab_adelante",ask("mesera","c84_donde_adelante",after=[act("avanza84",tramo=TRAMO_A,ok=1)]),"c84_me_bienvenido","c84_ab_somos",
  # 4: the mesera looks at her list and at the room (more people come in at the door: no act named); she walks the family back to the doormat, the frog in front (no act named for the walk: ir and llega)
  {"dots":4},gesto("mesera","lista"),"c84_me_gente",act("ir",a="felpudo")]+juntos(*[act("llega",quien=q,a=sp) for q,sp in FAMILIA])+[
  # 5: the turn: the señor and the señora look at the table with the flowers; the mesera reads her list; the card shows two places
  {"dots":5},gesto("senor","mira",a=FLORES),gesto("senora","mira",a=FLORES),gesto("mesera","lista"),CARD,{"wait":400},
  # 6: A (the doormat to the stand). 7: B (the stand past the rope; the mesera now stands beyond it; behind the family the señor and the señora, still at cola1, cola2, when A was right; the hombre and the mujer come in to cola1, cola2 when A was wrong). Each drawn afresh
  {"dots":6}]+ronda84("a",TRAMO_A,[],[])
  +[{"dots":7}]+ronda84("b",TRAMO_B,[act("llega",quien="mesera",a="tras_cuerda"),{"if":"lost=0","then":[],"else":juntos(act("llega",quien="hombre",a="cola1"),act("llega",quien="mujer",a="cola2"))}],[{"set":{"cuerda":"abierta"}}]),
 "final":[{"dots":8},baja3(lambda n:act("final84",n=n)),   # 8: the mesera leads the family to the best table left
  {"dots":9},"c84_me_bienvenidos","c84_cq_hambre","c84_fin",act("fin")],
 "leer":["c84_ab_mira","c84_me_hola","c84_cq_tardes","c84_donde_mesera","c84_pf_momento","c84_donde_espera","c84_abo_momento","c84_me_adelante","c84_ab_adelante","c84_donde_adelante","c84_me_bienvenido","c84_ab_somos","c84_me_gente",
  "c84_pf_adelante","c84_pf_momento","c84_me_bienvenidos","c84_cq_hambre","c84_fin"]}
s84=reuse(s84,{"c84_cq_tardes":TG(("buenas tardes",["buenas tardes"])),"c84_cq_hambre":TG(("tengo hambre",["tengo hambre","sí tengo hambre"]))})
json.dump(s84,open("cuentos/bienvenidos.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 85. ¿Está libre? ----------------
# The middle table (mesa2) and the near one (mesa3) stand empty, with cloths of two colours (drawn each round from rojo, azul, verde, amarillo, blanco; the two never the same; round B's two are not round A's); one of them is taken (which, drawn).
# The mesero says in one breath which is free and which is taken (which first, drawn). Who asks is drawn each round (round B's is not round A's). A miss: the couple sits at the taken table, its people come back, the couple gets up and takes a sweet and sits at the other one; the sweets on the saucer go down by one.
nm,nc=nombres("senor","senora","hombre","mujer","joven","coqui"); c=dict(comunes); c.update(nc)
COL={"rojo":"roja","azul":"azul","verde":"verde","amarillo":"amarilla","blanco":"blanca"}   # the five cloths, as "La mesa ___" says them
COLS=list(COL)
ASK85=(("senor",SE),("senora",SA),("hombre",HO),("mujer",MU),("joven",JO))
c.update({"c85_pie":N("El mesero tiene un pie malo."),"c85_donde_mesero":N("¿Dónde está el mesero?"),"c85_me_ahora":MO("Coquí, ahora tú eres el mesero."),
 "c85_se_noches":SA("Buenas noches. Una mesa para dos, por favor."),"c85_cual_libre":N("Una mesa para dos. ¿Cuál mesa está libre?"),
 "c85_jo_libre":JO("¿Hay una mesa libre? Para dos."),"c85_me_no":MO("No. La mesa roja está ocupada. La mesa azul está ocupada."),"c85_me_momento":MO("Un momento, por favor."),
 "c85_me_vamos":MO("La gente espera, Coquí. ¿Vamos?"),"c85_cq_listo":T("¡Listo!"),"c85_perdon":MO("¡Perdón! Toma."),
 "c85_me_toma":MO("Toma, Coquí. Son para ti."),"c85_cq_gracias":T("¡Gracias!"),"c85_fin":N("La fonda está llena. No hay mesas libres.")})
DIN.add("c85_perdon")
for t,w in COL.items():
    c["c85_no_%s"%t]=MO("¡No, Coquí! La mesa %s está ocupada."%w); DIN.add("c85_no_%s"%t)
    for f,x in COL.items():
        if f==t: continue
        c["c85_m_lt_%s_%s"%(f,t)]=MO("La mesa %s está libre. La mesa %s está ocupada."%(x,w))      # which is free first
        c["c85_m_tl_%s_%s"%(f,t)]=MO("La mesa %s está ocupada. La mesa %s está libre."%(w,x))      # which is taken first
        DIN.update(["c85_m_lt_%s_%s"%(f,t),"c85_m_tl_%s_%s"%(f,t)])
for k,F in ASK85:
    c["c85_pa_%s"%k]=F("Una mesa para dos, por favor."); c["c85_pb_%s"%k]=F("Para dos, por favor."); DIN.update(["c85_pa_%s"%k,"c85_pb_%s"%k])
ASKERS=[k for k,_ in ASK85]
def sin_usados(fa,ta,leaf):
    # a nested `if` on the two colours of round A (never the same): the leaf is given the set of the two and writes the steps that draw from the other three
    def por(v1):
        ts=[x for x in COLS if x!=v1]
        ch=leaf({v1,ts[-1]})
        for v2 in reversed(ts[:-1]): ch=[{"if":ta+"="+v2,"then":leaf({v1,v2}),"else":ch}]
        return ch
    ch=por(COLS[-1])
    for v1 in reversed(COLS[:-1]): ch=[{"if":fa+"="+v1,"then":por(v1),"else":ch}]
    return ch
def ronda85(s,pre,antes,prev=None):
    # f: the free table's colour; t: the taken one's (never the same); l: which table is free (mesa2 or mesa3); o: which the mesero says first (lt: the free one); q: who asks
    # a, b: the cloths of mesa2 and mesa3. Right: the frog leads the couple to the free table, the mesero nods. Wrong: the couple sits at the taken table and has to get up; a sweet; the sign shows the free one.
    # prev (round B): the names of round A's (free colour, taken colour, asker): B's colours are drawn from the three not used in A (one of the six ordered pairs: e), B's asker is not A's (g)
    f,t,e,l,o,q,a,b,g=[v+s for v in ("f","t","e","l","o","q","a","b","g")]
    if prev is None: cols=[{"draw":f,"options":COLS},{"draw":e,"options":["1","2","3","4"]}]+otro(t,f,e,COLS); quien=[{"draw":q,"options":ASKERS}]
    else:
        def hoja(usados):
            rem=[x for x in COLS if x not in usados]; pares=list(itertools.permutations(rem,2)); ch=[]
            for var,j in ((f,0),(t,1)):
                v=[pr[j] for pr in pares]
                ch+=[{"calc":var,"cond":e+"=1","then":v[0],"else":v[1]}]+[{"calc":var,"cond":"%s=%d"%(e,i+1),"then":v[i],"else":"$"+var} for i in range(2,len(v))]
            return ch
        cols=[{"draw":e,"options":[str(i) for i in range(1,7)]}]+sin_usados(prev[0],prev[1],hoja); quien=[{"draw":g,"options":["1","2","3","4"]}]+otro(q,prev[2],g,ASKERS)
    return antes+cols+[{"draw":l,"options":["mesa2","mesa3"]},{"draw":o,"options":["lt","tl"]}]+quien+[
     {"calc":a,"cond":l+"=mesa2","then":"$"+f,"else":"$"+t},{"calc":b,"cond":l+"=mesa2","then":"$"+t,"else":"$"+f},act("manteles",a="$"+a,b="$"+b),
     act("llega",quien="$"+q,a="ante_cuerda1"),"c85_p%s_$%s"%(pre,q),
     {"decide":"do","options":["mesa2","mesa3"],"pick":"$"+l,"tests":"ocupado","lock":True,"lead":[],"line":"c85_m_$%s_$%s_$%s"%(o,f,t),
      "right":[{"if":"ok","then":[act("sienta85",quienes="$"+q,mesa="$"+l,ok=1),OK]}],
      "wrong":con(act("sienta85",quienes="$"+q,mesa="$x",ok=0),"c85_no_$"+t,"c85_perdon")+[resta(lambda n:act("dulces",n=n))]+X}]
s85={"id":"esta-libre","title":"¿Está libre?","place":"La fonda","scene":"entrada","next":"con-y-sin",
 "goal":"Be the mesero's helper and lead each couple to the table that is free, so the saucer still holds its three wrapped sweets for the frog at the end: every couple sent to a taken table has to get up again, and the mesero gives them a sweet to say sorry.",
 "stake":{"thing":"dulces","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["mesero","libre","ocupado","para dos"],"formas_foco":{"ocupado":["ocupada"],"libre":["libres"]},
 "back_again":["fonda","mesera","un momento","mesa","rojo","azul","verde","amarillo","blanco","dos","señor","señora","hombre","mujer","joven","gente","espera","listo","perdón","toma","hay","no hay","gracias","por favor","pie","malo"],
 "also_heard":["buenas noches","llena"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"noche"}},act("dulces",n=3),act("manteles",a="rojo",b="azul"),act("ir",a="taburete_coqui"),{"wait":500},
  # 1: the mesero's bad foot; signed ask on him: he lifts his stick; the bow tie goes on the frog
  {"dots":1},"c85_pie",ask("mesero","c85_donde_mesero",after=[gesto("mesero","baston")]),"c85_me_ahora",act("corbata85"),
  # 2: the señora asks for a table for two; he points with his stick at the two empty tables in turn (mesa2 red, mesa3 blue); signed ask on the red table: the frog leads the couple there, the two at the vellonera come back and sit at the blue one
  {"dots":2},"c85_se_noches",gesto("mesero","baston",a="mesa2"),gesto("mesero","baston",a="mesa3"),"c85_m_lt_rojo_azul",
  ask("mesa2","c85_cual_libre",after=[act("sienta85",quienes="senora",mesa="mesa2",ok=1),act("vuelven85",mesa="mesa3")]),
  # 3: the joven comes in with a friend; the mesero shakes his head; the two wait on the bench
  {"dots":3},"c85_jo_libre",gesto("mesero","no"),"c85_me_no","c85_me_momento",act("banco85",quien="joven"),
  # 4: more people come in at the door (no act named); a speaking turn (listo)
  {"dots":4},"c85_me_vamos","c85_cq_listo",
  # 5: later: the window is darker; the tables are cleared and new cloths go on; the mesero taps the saucer and points at the frog; the card shows two places
  {"dots":5},{"set":{"hora":"tarde_noche"}},act("tarde85"),gesto("mesero","senala",a="dulces"),gesto("mesero","senala",a="coqui"),CARD,{"wait":400},
  # 6: A. 7: B (later again: new cloths, new people at the vellonera). Each drawn afresh
  {"dots":6}]+ronda85("a","a",[])+[{"dots":7}]+ronda85("b","b",[act("tarde85")],prev=("fa","ta","qa")),
 "final":[{"dots":8},baja3(lambda n:act("final85",n=n)),   # 8: every table is taken (the party has come to mesa1); the saucer held out, by the sweets left
  {"dots":9},"c85_me_toma","c85_cq_gracias","c85_fin",act("fin")],
 "leer":["c85_pie","c85_donde_mesero","c85_me_ahora","c85_se_noches","c85_m_lt_rojo_azul","c85_cual_libre","c85_jo_libre","c85_me_no","c85_me_momento","c85_me_vamos","c85_cq_listo",
  "c85_pa_mujer","c85_m_tl_amarillo_verde","c85_pb_joven","c85_m_lt_blanco_rojo","c85_me_toma","c85_cq_gracias","c85_fin"]}
s85=reuse(s85,{"c85_cq_listo":TG(("listo",["listo"])),"c85_cq_gracias":TG(("gracias",["gracias","muchas gracias"]))})
json.dump(s85,open("cuentos/esta-libre.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 86. Con y sin ----------------
# One of the family (drawn) asks for something with or without (drawn). The tray shows the two of it, side by side (which is at the left, drawn). Round A is bread, with butter or without; round B is water, with lemon or without.
# A miss: the frog pushes the other one across, she shakes her head and says so; the mesero snatches it back and a glass tips: a candle goes out.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
ASK86=(("abuela","Abuela"),("abuelo","Abuelo"),("luis","Luis"),("carmen","Carmen"))
c.update({"c86_me_menu":ME("Aquí tiene el menú."),"c86_donde_menu":N("¿Dónde está el menú?"),"c86_ab_gracias":AB("Gracias. Mira el menú, Coquí."),
 "c86_me_quieren":ME("¿Qué quieren tomar?"),"c86_l_sed":L("Tengo sed. Agua con limón, por favor."),"c86_cual_luis":N("Luis quiere agua con limón. ¿Cuál es?"),
 "c86_ca_sin":CA("Para mí, agua sin limón."),"c86_cual_sin":N("¿Cuál es el agua sin limón?"),
 "c86_abo_cafe":ABO("Un café con leche, por favor."),"c86_ab_negro":AB("Y para mí, un café negro. Sin leche."),
 "c86_me_y_tu":ME("¿Y tú, Coquí? ¿Quieres agua?"),"c86_cq_si":T("¡Sí, por favor!"),"c86_me_conosin":ME("¿Con limón o sin limón?"),
 "c86_mo_ay":MO("¡Ay! ¿Con limón? ¿Sin limón? ¡Ayúdame, Coquí!"),
 "c86_ab_pan":AB("Coquí, ¿quieres pan?"),"c86_cq_quiero":T("¡Sí, quiero!"),"c86_ab_con":AB("¿Con mantequilla o sin mantequilla?"),"c86_fin":N("Coquí quiere pan con mantequilla.")})
for k,pre in ASK86:
    for w in ("con","sin"):
        c["c86_a_%s_%s"%(k,w)]=D(k,pre,"Para mí, pan %s mantequilla."%w); c["c86_b_%s_%s"%(k,w)]=D(k,pre,"Agua %s limón, por favor."%w)
        c["c86_noa_%s_%s"%(k,w)]=D(k,pre,"No, Coquí. %s mantequilla."%w.capitalize()); c["c86_nob_%s_%s"%(k,w)]=D(k,pre,"No, Coquí. %s limón."%w.capitalize())
        DIN.update(["c86_%s_%s_%s"%(x,k,w) for x in ("a","b","noa","nob")])
def ronda86(s,que,pat,no,prev=None):
    # q: who asks (round B's is not round A's: prev, g); c: con or sin; i: which of the two is at the left of the tray; k: the thing that is "con", z: the one that is "sin"; p: the right one
    q,cc,i,k,z,p,g=[v+s for v in ("q","c","i","k","z","p","g")]
    quien=[{"draw":q,"options":[x for x,_ in ASK86]}] if prev is None else [{"draw":g,"options":["1","2","3"]}]+otro(q,prev,g,[x for x,_ in ASK86])
    return quien+[{"draw":cc,"options":["con","sin"]},{"draw":i,"options":["con","sin"]},
     {"calc":k,"cond":i+"=con","then":"cosa_a","else":"cosa_b"},{"calc":z,"cond":i+"=con","then":"cosa_b","else":"cosa_a"},{"calc":p,"cond":cc+"=con","then":"$"+k,"else":"$"+z},
     act("bandeja86",que=que,izq="$"+i),
     {"decide":"do","options":["cosa_a","cosa_b"],"pick":"$"+p,"tests":"$"+cc,"lock":True,"lead":[],"line":"c86_%s_$%s_$%s"%(pat,q,cc),
      "right":[act("da86",cual="$"+p,a="$"+q,ok=1),star],
      "wrong":con(act("da86",cual="$x",a="$"+q,ok=0),"c86_%s_$%s_$%s"%(no,q,cc))+[resta(lambda n:act("velas",n=n))]+X}]
s86={"id":"con-y-sin","title":"Con y sin","place":"La fonda","scene":"entrada","next":"que-hay-de-comer",
 "goal":"Push across the glass or plate each person asked for, with or without, so the three candles on the family's table stay lit: every wrong one is snatched back with a splash and a candle goes out.",
 "stake":{"thing":"velas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["menú","con","sin"],"formas_foco":{},
 "back_again":["mesero","mesera","café","leche","agua","limón","pan","mantequilla","negro","quiero","quieres","para","tengo sed","toma","aquí tiene","por favor","gracias","sí","no","mira"],
 "also_heard":["quieren","tomar","ayúdame"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"hora":"noche"}},act("velas",n=3),act("ir",a="mesa2_coqui"),{"wait":500},
  # 1: the mesera gives abuela the menu; signed ask on it: she hands it over (menu86) and abuela opens it
  {"dots":1},"c86_me_menu",ask("menu","c86_donde_menu",after=[act("menu86")]),"c86_ab_gracias",
  # 2: the drinks; the mesero's tray holds two glasses of water, one with lemon (cosa_a) and one without (cosa_b); two signed asks: Luis's glass, Carmen's glass
  {"dots":2},"c86_me_quieren","c86_l_sed",act("llega",quien="mesero",a="bandeja"),act("bandeja86",que="agua",izq="con"),
  ask("cosa_a","c86_cual_luis",after=[act("da86",cual="cosa_a",a="luis",ok=1)]),"c86_ca_sin",ask("cosa_b","c86_cual_sin",after=[act("da86",cual="cosa_b",a="carmen",ok=1)]),
  # 3: the coffees: the mesero sets the pale cup before abuelo and the black one before abuela
  {"dots":3},"c86_abo_cafe","c86_ab_negro",act("cafes86"),
  # 4: the mesera asks the frog; a speaking turn (sí); with or without lemon; the frog points at the lemon (no act named) and a small glass comes
  {"dots":4},"c86_me_y_tu","c86_cq_si","c86_me_conosin",act("vasito86"),
  # 5: the turn: the mesero comes back with a full tray (two glasses of water and two small plates of bread: no act shows both; the candles flicker: no act named) and looks lost; the card shows two places
  {"dots":5},act("llega",quien="mesero",a="bandeja"),"c86_mo_ay",CARD,{"wait":400},
  # 6: A (bread). 7: B (water). Each drawn afresh
  {"dots":6}]+ronda86("a","pan","a","noa")+[{"dots":7}]+ronda86("b","agua","b","nob",prev="qa"),
 "final":[{"dots":8},baja3(lambda n:act("final86",n=n)),   # 8: the lamps go low; the candles left decide the last picture
  {"dots":9},"c86_ab_pan","c86_cq_quiero","c86_ab_con","c86_fin",act("fin")],   # 9: the frog points at the butter (no act named)
 "leer":["c86_me_menu","c86_donde_menu","c86_ab_gracias","c86_me_quieren","c86_l_sed","c86_cual_luis","c86_ca_sin","c86_cual_sin","c86_abo_cafe","c86_ab_negro","c86_me_y_tu","c86_cq_si","c86_me_conosin","c86_mo_ay",
  "c86_a_carmen_sin","c86_b_abuelo_con","c86_ab_pan","c86_cq_quiero","c86_ab_con","c86_fin"]}
s86=reuse(s86,{"c86_cq_si":TG(("sí",["sí","si"])),"c86_cq_quiero":TG(("quiero",["quiero","sí quiero"]))})
json.dump(s86,open("cuentos/con-y-sin.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files here, and the earlier stories of this run); places 1 to 7 must be on disk.
# Words that are new in a later story of La fonda, written by another builder (para mí: story 89; delicioso: story 92), count as known; none of this scene's turns uses them.
EARLIER={"para mí","delicioso"}
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s84,s85,s86):
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
for st in (s84,s85,s86):
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
