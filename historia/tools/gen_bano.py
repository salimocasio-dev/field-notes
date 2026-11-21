# El baño (place 9, La casa un día entero, scene 2 of 4): stories 99, 100, 101. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/bano.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `bano` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: the generators of places 4 to 8 first (each sees only what was recorded before it), then the four of La casa in any order (this one, cuarto, sala_dia, noche).
#   Speaking turns: 99 `un poco` (cafe-con-azucar) and `caliente` (cuidado); 100 `yo` (quien-eres-tu) and `sí` (el-bizcocho); 101 `aquí` (las-flores) and `limpio`, a word of 99 (this generator's own story, in order).
#
# Where the script or its Needs list leaves a value open, this file fixes it in ONE place (and the report says so):
#   `stake.thing` is the name of the act that shows it: jabon (99), barras (100), tubo (101). The count `n` of those acts and of final99 / final100 / final101 is the steps of the stake left: 3, 2, 1 (the other scenes' baja3);
#       101's tube starts with 4 marks (the script), has 3 after Carmen's squeeze in the opening, and loses one mark for each wrong move (3 -> 2 -> 1).
#   99 `toallas99` {a, b}: the colours (rojo, azul, blanco, verde, amarillo) of the towel at the left (toalla_a) and at the right (toalla_b). In the opening: a = verde (the dirty one), b = amarillo (the clean one); the two are in abuela's hands there (the Needs list says "on the stool").
#       In the game: the two colours are drawn (an ordered pair of two of rojo, azul, blanco: which is at the left is drawn too; round B's pair is not round A's: a different SET of two colours), then which of the two is clean (qa/qb: a = the left one, b = the right one) and which is said first (oa/ob: lt = the clean one first).
#       `seca99` {cual, a, ok}: cual = the thing key (toalla_a / toalla_b), a = the child (in the opening, Carmen: her face is dried). `lava99` {quien, que}: que = manos (the game's child, step 2) or cara (Carmen, step 3).
#       The game's two children are dealt by `reparte` (Luis and Carmen, none twice): the first comes to `lavamanos1` and washes, the second waits at the door; round B: the first leaves (`sale`), the second comes to `lavamanos1`.
#   99 the wrong move runs in the order of the brief: seca99 ok=0 (the Needs list: muddy again, and washed again), the line, the loss (`jabon` n), the cross (X). The script puts "He washes again" AFTER the line; the act carries it (see the report).
#   100 `ducha100` / `llave100` {on}: 1 = runs, 0 = stops. The script never stops the water; each time the generator stops it (in the turn, between the rounds, before abuelo's turn) it says so in the comment. `va100` {quien, a, ok}: a = the spot the child goes to (ducha_dentro for the shower, lavamanos1 for the sink), whatever the tap that ran.
#       the children of the game are dealt by `reparte` (Luis and Carmen); what each does is drawn on its own each round (bana, lava), the two rounds may be the same. The wrong-move line is "¡No, Coquí! " + the round's own line (the script gives it for the first variant; the other follows it).
#   101 the shelf: `cosa_a` is the thing at the LEFT, `cosa_b` the one at the right; `repisa101` {izq}: "cepillo" or "peinilla", the one at the left. In the opening the shelf is the scene's default (the toothbrush at the left = cosa_a, the comb at the right = cosa_b; no `repisa101`, because it makes the brush carry a squeeze).
#       Round A's values (which child, which thing is asked for, which is at the left) are drawn in the turn (step 5), because the shelf is laid there (Carmen puts the squeeze on the brush); round B's are drawn at the start of round B. The two children are dealt by `reparte`.
#       `da101` {cual, a, ok}: cual = cosa_a / cosa_b. The wrong move: da101 ok=0 (the Needs list: used wrongly, the brush is washed and squeezed on again), the line, the loss (`tubo` n), the cross (X). In the opening (step 4) the frog's push of the comb is `da101` ok=1 (the nearest act named).
#   Every story sets its own states at the start (hora dia): every story starts fresh.
#   Beats with no act named in Needs are left out (and listed in the report): nothing is invented.
import json,glob,os,re,collections,unicodedata
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); ABO=lambda t:D("abuelo","Abuelo",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
KID={"luis":"Luis","carmen":"Carmen"}
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time (people walking in or out together): all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
START={"set":{"hora":"dia"}}                              # every story starts fresh
MINE=("limpio-y-sucio","se-bana","los-dientes")           # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c99_m_$oa_$ca_$da"): never renamed
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
def noacc(s): return "".join(ch for ch in unicodedata.normalize("NFD",s) if unicodedata.category(ch)!="Mn")
def TG(*p):
    # the script's bracketed forms, and each one again without its accent (lower case, no punctuation)
    out=[]
    for w,f in p:
        fs=[]
        for x in f:
            for y in (x,noacc(x)):
                if y not in fs: fs.append(y)
        out.append({"palabra":w,"formas":fs})
    return out
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}
# What he hears when he pokes a person already recorded
NM={"abuela":("abuela",N("Esta es abuela.")),"abuelo":("n_abuelo",N("Este es abuelo.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "perro":("c_n_perro",N("Es el perro. Se llama Canelo."))}
def nombres(*ks):
    return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
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

# ---------------- 99. Limpio y sucio ----------------
# Two folded towels of two colours lie on the stool (two of rojo, azul, blanco; the pair of round B is not round A's); abuela, from the shower, says in one breath which is clean and which is dirty (which first: drawn).
# A child (drawn, one of Luis and Carmen; round B's is the other) has washed his hands at the sink and holds them out, wet. A miss: he dries them on the dirty towel, the mud is back (on his nose too), the line, the soap gets smaller; the sign shows the clean towel.
nm,nc=nombres("abuela","luis","carmen","coqui","perro"); c=dict(comunes); c.update(nc)
COL={"rojo":"roja","azul":"azul","blanco":"blanca"}   # the three colours of the game, as "La toalla ___" says them
COLS=list(COL)
c.update({"c99_ab_sucios":AB("¡Ay! Luis está sucio. Carmen está sucia. ¡Y Canelo!"),"c99_donde_manos":N("¿Dónde están las manos sucias?"),
 "c99_ab_jabon":AB("Coquí, el jabón, por favor."),"c99_ab_luis_lava":AB("Luis se lava las manos con jabón."),"c99_l_limpias":L("¡Mira! Tengo las manos limpias."),
 "c99_ab_carmen_lava":AB("Ahora Carmen se lava la cara."),"c99_ca_ya":CA("¡Ya! Tengo la cara limpia."),
 "c99_ab_verde":AB("La toalla verde está sucia. La toalla amarilla está limpia."),"c99_cual_limpia":N("¿Cuál toalla está limpia?"),
 "c99_ab_y_tu":AB("¿Y tú, Coquí? ¿Estás sucio?"),"c99_cq_poco":T("¡Un poco!"),"c99_ab_pies":AB("Después te lavas los pies. Con mucho jabón."),
 "c99_ab_fria":AB("¿Agua fría o agua caliente, Coquí?"),"c99_cq_caliente":T("¡Caliente, por favor!"),"c99_fin":N("Coquí se lava con jabón. Ahora está limpio.")})
for t,w in COL.items():   # t: the dirty one; f: the clean one (never the same)
    c["c99_no_%s"%t]=AB("¡No, Coquí! La toalla %s está sucia."%w); DIN.add("c99_no_%s"%t)
    for f,x in COL.items():
        if f==t: continue
        c["c99_m_lt_%s_%s"%(f,t)]=AB("La toalla %s está limpia. La toalla %s está sucia."%(x,w))      # the clean one first
        c["c99_m_tl_%s_%s"%(f,t)]=AB("La toalla %s está sucia. La toalla %s está limpia."%(w,x))      # the dirty one first
        DIN.update(["c99_m_lt_%s_%s"%(f,t),"c99_m_tl_%s_%s"%(f,t)])
def sin_par(fa,ta,leaf):
    # a nested `if` on the two colours of round A (never the same): the leaf is given the pair and writes the steps that draw the pair of round B (a different SET of two colours)
    def por(v1):
        ts=[x for x in COLS if x!=v1]
        ch=leaf((v1,ts[-1]))
        for v2 in reversed(ts[:-1]): ch=[{"if":ta+"="+v2,"then":leaf((v1,v2)),"else":ch}]
        return ch
    ch=por(COLS[-1])
    for v1 in reversed(COLS[:-1]): ch=[{"if":fa+"="+v1,"then":por(v1),"else":ch}]
    return ch
def setup99(s,prev=None):
    # l, r: the colours at the left (toalla_a) and at the right (toalla_b); q: which of the two is the clean one (a = the left one); o: which is said first (lt: the clean one);
    # c, d: the clean and the dirty colour; p: the thing key of the clean towel
    l,r,e,q,o,c_,d,p=[v+s for v in ("l","r","e","q","o","c","d","p")]
    if prev is None: cols=[{"draw":l,"options":COLS},{"draw":e,"options":["1","2"]}]+otro(r,l,e,COLS)
    else:
        def hoja(vs):
            pares=[(x,y) for x in COLS for y in COLS if x!=y and {x,y}!=set(vs)]; ch=[]
            for var,j in ((l,0),(r,1)):
                v=[pr[j] for pr in pares]
                ch+=[{"calc":var,"cond":e+"=1","then":v[0],"else":v[1]}]+[{"calc":var,"cond":"%s=%d"%(e,i+1),"then":v[i],"else":"$"+var} for i in range(2,len(v))]
            return ch
        cols=[{"draw":e,"options":["1","2","3","4"]}]+sin_par(prev[0],prev[1],hoja)
    return cols+[{"draw":q,"options":["a","b"]},{"draw":o,"options":["lt","tl"]},
     {"calc":c_,"cond":q+"=a","then":"$"+l,"else":"$"+r},{"calc":d,"cond":q+"=a","then":"$"+r,"else":"$"+l},{"calc":p,"cond":q+"=a","then":"toalla_a","else":"toalla_b"}]
def juega99(s,k):
    # the child comes to the sink, washes his hands and holds them out wet; the decision. Right: he dries them on the clean one: clean, a star. Wrong: the dirty one, mud again; the line; the soap is smaller; the sign shows the clean towel.
    l,r,q,o,c_,d,p=[v+s for v in ("l","r","q","o","c","d","p")]
    return [act("llega",quien="$"+k,a="lavamanos1"),act("lava99",quien="$"+k,que="manos"),gesto("$"+k,"manos"),
     {"decide":"do","options":["toalla_a","toalla_b"],"pick":"$"+p,"tests":"sucio","lock":True,"lead":[],"line":"c99_m_$%s_$%s_$%s"%(o,c_,d),
      "right":[act("seca99",cual="$"+p,a="$"+k,ok=1),star],
      "wrong":[act("seca99",cual="$x",a="$"+k,ok=0),"c99_no_$"+d,resta(lambda n:act("jabon",n=n))]+X}]
s99={"id":"limpio-y-sucio","title":"Limpio y sucio","place":"La casa, un día entero","scene":"bano","next":"se-bana",
 "goal":"On the sink sits a big new bar of soap that abuela taps, and then the frog's muddy feet: when the muddy children have washed and dried their hands on the clean towel it is the frog's turn for a bath, and the bar left decides how much foam he gets, but every dirty towel puts the mud back on washed hands and the washing again shrinks the bar.",
 "stake":{"thing":"jabon","steps":3},"dots":10,"bien":"si_muy_bien",
 "focus_words":["sucio","limpio","se lava","jabón"],"formas_foco":{"sucio":["sucia","sucias"],"limpio":["limpia","limpias"],"se lava":["te lavas"]},
 "back_again":["mano","cara","pie","toalla","rojo","azul","blanco","verde","amarillo","agua","caliente","frío","un poco","mucho","tengo","mira","ahora","ya","con","después","por favor","no","sí"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START,act("jabon",n=3)]+juntos(act("llega",quien="luis",a="puerta1"),act("llega",quien="carmen",a="puerta2"))+[{"wait":500},
  # 1: abuela sees the mud; Luis holds up his hands; signed ask on them (mud drips: no act named)
  {"dots":1},"c99_ab_sucios",gesto("luis","manos"),ask("manos_luis","c99_donde_manos"),
  # 2: abuela's own line is the signed ask on the soap (the frog pushes it to Luis, bubbles: no act named); Luis washes his hands, the hands come out bright; Luis says they are clean
  {"dots":2},ask("jabon","c99_ab_jabon")]+con(act("lava99",quien="luis",que="manos"),"c99_ab_luis_lava")+["c99_l_limpias",
  # 3: Carmen washes her face; it shines
  {"dots":3}]+con(act("lava99",quien="carmen",que="cara"),"c99_ab_carmen_lava")+["c99_ca_ya",
  # 4: abuela holds out her two towels, a green one and a yellow one; she smells the green one; signed ask on the yellow one: the frog carries it to Carmen, she dries her face (the green one goes into the basket: no act named)
  {"dots":4},act("toallas99",a="verde",b="amarillo"),gesto("abuela","huele"),"c99_ab_verde",ask("toalla_b","c99_cual_limpia",after=[act("seca99",cual="toalla_b",a="carmen",ok=1)]),
  # 5: abuela asks the frog if he is dirty (he looks at his feet: no act named); a speaking turn (un poco)
  {"dots":5},"c99_ab_y_tu","c99_cq_poco","c99_ab_pies",
  # 6: the turn: abuela takes Canelo into the shower and washes him, her back to the room; the children run out to the patio and come in again with mud on their hands (no act named for the mud);
  # two folded towels lie on the stool; the card shows two places. Round A's values are drawn here (the towels are laid), the two children are dealt out
  {"dots":6},{"reparte":["ka","kb"],"options":list(KID)}]+setup99("a")+juntos(act("llega",quien="abuela",a="ducha_abuela"),act("llega",quien="perro",a="ducha_dentro"))+juntos(act("sale",quien="luis"),act("sale",quien="carmen"))
  +juntos(act("llega",quien="luis",a="puerta1"),act("llega",quien="carmen",a="puerta2"))+[act("toallas99",a="$la",b="$ra"),CARD,{"wait":400},
  # 7: A. 8: B (the first child leaves, the other comes to the sink; the pair of towels is not A's). Each drawn afresh
  {"dots":7}]+juega99("a","ka")
  +[{"dots":8},act("sale",quien="$ka")]+setup99("b",prev=("la","ra"))+[act("toallas99",a="$lb",b="$rb")]+juega99("b","kb"),
 "final":[{"dots":9},act("sale",quien="$kb"),act("ir",a="lavamanos_coqui"),baja3(lambda n:act("final99",n=n)),   # 9: the frog's turn: he sits in the sink; the foam by the soap left (a mountain and a hat; to the chin; a few bubbles)
  # 10: abuela has a hand on each tap (no act named); the turn (caliente); steam rises (the frog sighs: no act named)
  {"dots":10},"c99_ab_fria","c99_cq_caliente",act("agua99",que="caliente"),"c99_fin",act("fin")],
 "leer":["c99_ab_sucios","c99_donde_manos","c99_ab_jabon","c99_ab_luis_lava","c99_l_limpias","c99_ab_carmen_lava","c99_ca_ya","c99_ab_verde","c99_cual_limpia","c99_ab_y_tu","c99_cq_poco","c99_ab_pies",
  "c99_m_lt_azul_rojo","c99_m_tl_blanco_azul","c99_ab_fria","c99_cq_caliente","c99_fin"]}
s99=reuse(s99,{"c99_cq_poco":TG(("un poco",["un poco","sí un poco","un poquito"])),"c99_cq_caliente":TG(("caliente",["caliente","agua caliente"]))})
json.dump(s99,open("cuentos/limpio-y-sucio.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 100. Se baña ----------------
# A child (drawn, one of Luis and Carmen; round B's is the other) comes in from the rain in a raincoat with its hood up and stands in the middle; abuela, in the door, says what he does (drawn, each round on its own): "se baña" or "se lava las manos".
# Decision A and B: touch a tap (the shower's, the sink's; tests se baña against se lava). A miss: the wrong water runs, hot, with nobody under it, the child waits; "¡No, Coquí! <what he does>."; a red bar on the gauge goes out; the sign shows the right tap.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c100_ab_bano":AB("Mira, Coquí: el baño. Aquí está la ducha."),"c100_donde_ducha":N("¿Dónde está la ducha?"),
 "c100_ab_luis":AB("Luis está sucio. Luis se baña en la ducha."),"c100_donde_abres":N("¿Dónde abres el agua?"),
 "c100_ab_carmen":AB("Carmen no se baña. Carmen se lava las manos."),"c100_ca_espejo":CA("Mira en el espejo, Coquí. ¿Quién es?"),"c100_cq_yo":T("¡Yo!"),"c100_ca_si":CA("¡Sí! Coquí está en el espejo."),
 "c100_ab_ocupado":AB("El baño está ocupado, abuelo."),"c100_abo_despues":ABO("Yo me baño después. Agua caliente para mí, por favor."),
 "c100_abo_limpio":ABO("Coquí, ¿estoy limpio?"),"c100_cq_si":T("¡Sí!"),"c100_fin":N("Abuelo se baña en la ducha. Ahora el baño no está ocupado.")})
for k,nombre in KID.items():
    for w,t in (("bana","se baña"),("lava","se lava las manos")):
        c["c100_%s_%s"%(k,w)]=AB("%s %s."%(nombre,t)); c["c100_no_%s_%s"%(k,w)]=AB("¡No, Coquí! %s %s."%(nombre,t)); DIN.update(["c100_%s_%s"%(k,w),"c100_no_%s_%s"%(k,w)])
def ronda100(s,k,antes):
    # w: what the child does (bana, lava); p: the right tap. Right: the right water runs and the child goes to it (the other one is off). Wrong: the wrong water runs, he waits; the line; a bar goes out.
    w,p="w"+s,"p"+s
    return antes+[{"draw":w,"options":["bana","lava"]},{"calc":p,"cond":w+"=bana","then":"llave_ducha","else":"llave_lavamanos"},act("capa100",quien="$"+k),
     {"decide":"do","options":["llave_ducha","llave_lavamanos"],"pick":"$"+p,"tests":"$"+w,"lock":True,"lead":[],"line":"c100_$%s_$%s"%(k,w),
      "right":[{"if":w+"=bana","then":[act("llave100",on=0),act("ducha100",on=1),act("va100",quien="$"+k,a="ducha_dentro",ok=1)],"else":[act("ducha100",on=0),act("llave100",on=1),act("va100",quien="$"+k,a="lavamanos1",ok=1)]},star],
      "wrong":[{"if":w+"=bana","then":[act("llave100",on=1),act("va100",quien="$"+k,a="ducha_dentro",ok=0)],"else":[act("ducha100",on=1),act("va100",quien="$"+k,a="lavamanos1",ok=0)]},
               "c100_no_$%s_$%s"%(k,w),resta(lambda n:act("barras",n=n))]+X}]
s100={"id":"se-bana","title":"Se baña","place":"La casa, un día entero","scene":"bano","next":"los-dientes",
 "goal":"On the wall the water heater's gauge shows three red bars, and abuelo, in his robe with a towel over his shoulder, taps it and points at himself: when the muddy children have had the shower or the sink they need, the hot water left decides how warm his own shower is, but the wrong water, run with nobody under it, wastes a bar.",
 "stake":{"thing":"barras","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["baño","ducha","se baña","espejo"],"formas_foco":{"se baña":["me baño"]},
 "back_again":["se lava","sucio","limpio","mano","agua","caliente","ocupado","después","para mí","yo","mira","abre","ahora","por favor","no","sí"],
 "also_heard":["quién"],"names":nm,"palabras":{"bana":"se baña","lava":"se lava"},"clips":c,
 "beats":[START,act("barras",n=3),act("ir",a="repisa_coqui")]+juntos(act("llega",quien="luis",a="puerta1"),act("llega",quien="carmen",a="puerta2"))+[{"wait":500},
  # 1: abuela shows the bathroom; signed ask on the shower: water sprays for a moment (the frog jumps: no act named)
  {"dots":1},"c100_ab_bano",ask("ducha","c100_donde_ducha",after=[act("ducha100",on=1),{"wait":800},act("ducha100",on=0)]),
  # 2: Luis takes a shower; signed ask on the shower's tap: the shower runs, Luis steps in
  {"dots":2},"c100_ab_luis",ask("llave_ducha","c100_donde_abres",after=[act("ducha100",on=1),act("llega",quien="luis",a="ducha_dentro")]),
  # 3: Carmen holds up her painted hands; abuela's own line is the signed ask on the sink's tap: the tap runs, she washes (she looks up: no act named); the mirror; a speaking turn (yo)
  {"dots":3},gesto("carmen","manos"),ask("llave_lavamanos","c100_ab_carmen",after=[act("llega",quien="carmen",a="lavamanos1"),act("llave100",on=1)]),"c100_ca_espejo",act("espejo100"),"c100_cq_yo","c100_ca_si",
  # 4: abuelo comes to the door in his robe; he taps the heater's gauge
  {"dots":4},act("llega",quien="abuelo",a="puerta1"),"c100_ab_ocupado",gesto("abuelo","toca",a="calentador"),"c100_abo_despues",
  # 5: the turn: all morning the children run in and out (the water is stopped); abuelo waits on a chair outside the door; abuela stands in the door; the gauge shows three bars; the frog sits between the two taps; the card shows two places
  {"dots":5},act("ducha100",on=0),act("llave100",on=0)]+juntos(act("sale",quien="luis"),act("sale",quien="carmen"),act("llega",quien="abuelo",a="fuera"),act("llega",quien="abuela",a="junto_puerta"))
  +[act("ir",a="repisa_coqui"),act("barras",n=3),CARD,{"wait":400},
  # 6: A. 7: B (the first child leaves and the water is stopped; the other comes in). The child and what he does: drawn afresh each round
  {"reparte":["ka","kb"],"options":list(KID)},
  {"dots":6}]+ronda100("a","ka",[])
  +[{"dots":7}]+ronda100("b","kb",[act("ducha100",on=0),act("llave100",on=0),act("sale",quien="$ka")]),
 "final":[{"dots":8},act("ducha100",on=0),act("llave100",on=0),act("sale",quien="$kb"),act("llega",quien="abuelo",a="ducha_dentro"),baja3(lambda n:act("final100",n=n)),   # 8: abuelo's turn in the shower (his head over the low wall); steam, singing, by the bars left
  {"dots":9},act("llega",quien="abuelo",a="ante_espejo"),"c100_abo_limpio","c100_cq_si","c100_fin",act("fin")],   # 9: abuelo comes out, combed, before the mirror; a speaking turn (sí)
 "leer":["c100_ab_bano","c100_donde_ducha","c100_ab_luis","c100_donde_abres","c100_ab_carmen","c100_ca_espejo","c100_cq_yo","c100_ca_si","c100_ab_ocupado","c100_abo_despues",
  "c100_luis_bana","c100_carmen_lava","c100_abo_limpio","c100_cq_si","c100_fin"]}
s100=reuse(s100,{"c100_cq_yo":TG(("yo",["yo","soy yo"])),"c100_cq_si":TG(("sí",["sí","si"]))})
json.dump(s100,open("cuentos/se-bana.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 101. Los dientes ----------------
# On the shelf lie the toothbrush, with its squeeze of paste, and the comb (which is at the left is drawn each round). A child (drawn, one of Luis and Carmen; round B's is the other), under his towel, asks for one of them (drawn, each round on its own).
# Decision A and B: touch a thing (cosa_a at the left, cosa_b at the right; tests cepillo against peinilla). A miss: he uses what he gets, without looking, pulls the towel off, "¡No, Coquí! ¡<what he asked for>!"; the brush is washed and squeezed on again: one mark less on the tube; the sign shows the right thing.
nm,nc=nombres("abuela","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
THING={"cepillo":("el cepillo","¡El cepillo!"),"peinilla":("la peinilla","¡La peinilla!")}
c.update({"c101_ab_cepilla":AB("Ahora Carmen se cepilla los dientes."),"c101_donde_dientes":N("¿Dónde están los dientes de Carmen?"),
 "c101_ca_me_cepillo":CA("Me cepillo los dientes."),"c101_ca_peinilla":CA("Ahora, la peinilla."),"c101_ab_para":AB("El cepillo es para los dientes. La peinilla es para el pelo."),
 "c101_l_donde":L("¿Dónde está mi peinilla?"),"c101_cq_aqui":T("¡Aquí!"),
 "c101_ab_espejo":AB("Mira en el espejo, Coquí."),"c101_cq_limpio":T("¡Limpio!"),"c101_fin":N("El cepillo es para los dientes. Y Coquí tiene su cepillo.")})
for k,nombre in KID.items():
    for t,(art,excl) in THING.items():
        c["c101_%s_%s"%(k,t)]=D(k,nombre,"Coquí, %s, por favor."%art); c["c101_no_%s_%s"%(k,t)]=D(k,nombre,"¡No, Coquí! %s"%excl); DIN.update(["c101_%s_%s"%(k,t),"c101_no_%s_%s"%(k,t)])
def setup101(s):
    # i: which of the two is at the left of the shelf (cepillo, peinilla); t: what he asks for; k: the key of the toothbrush (cosa_a at the left, else cosa_b), z: the comb's; p: the right thing
    i,t,k,z,p=[v+s for v in ("i","t","k","z","p")]
    return [{"draw":i,"options":["cepillo","peinilla"]},{"draw":t,"options":["cepillo","peinilla"]},
     {"calc":k,"cond":i+"=cepillo","then":"cosa_a","else":"cosa_b"},{"calc":z,"cond":i+"=cepillo","then":"cosa_b","else":"cosa_a"},{"calc":p,"cond":t+"=cepillo","then":"$"+k,"else":"$"+z}]
def juega101(s,g):
    # right: he uses it under the towel (the hair flat, or the teeth shine), a star. Wrong: the other thing used wrongly; the towel off; the line; the tube loses a mark; the sign shows the right thing.
    t,p="t"+s,"p"+s
    return [{"decide":"do","options":["cosa_a","cosa_b"],"pick":"$"+p,"tests":"$"+t,"lock":True,"lead":[],"line":"c101_$%s_$%s"%(g,t),
      "right":[act("da101",cual="$"+p,a="$"+g,ok=1),star],
      "wrong":[act("da101",cual="$x",a="$"+g,ok=0),"c101_no_$%s_$%s"%(g,t),resta(lambda n:act("tubo",n=n))]+X}]
s101={"id":"los-dientes","title":"Los dientes","place":"La casa, un día entero","scene":"bano","next":"lee-y-escribe",
 "goal":"On the sink's edge stands a tube of toothpaste, nearly empty, with three marks on it, and beside it the frog's own tiny toothbrush: when the two children, rubbing their hair under their towels, have the toothbrush or the comb they ask for, the squeezes left decide how much paste the frog gets for his own brushing, but a wrong thing used without looking wastes the squeeze that was on the brush.",
 "stake":{"thing":"tubo","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["cepillo","dientes","peinilla"],"formas_foco":{},
 "back_again":["espejo","limpio","toalla","pelo","boca","aquí","para","mi","mira","ahora","por favor","gracias","no","sí"],
 "also_heard":["se cepilla"],"names":nm,"palabras":{},"clips":c,
 "beats":[START,act("tubo",n=4),act("ir",a="repisa_coqui"),act("llega",quien="carmen",a="banquito"),act("llega",quien="abuela",a="junto_puerta"),{"wait":500},
  # 1: Carmen shows her teeth to the mirror; signed ask on her: she grins, a sparkle
  {"dots":1},gesto("carmen","dientes"),"c101_ab_cepilla",ask("carmen","c101_donde_dientes",after=[gesto("carmen","dientes"),tw("carmen"),{"wait":700},tw(None)]),
  # 2: Carmen's own line is the signed ask on the toothbrush (the frog pushes it over): she squeezes the tube (three marks are left) and brushes: foam
  {"dots":2},ask("cosa_a","c101_carmen_cepillo",after=[act("cepilla101",quien="carmen"),act("tubo",n=3)]),"c101_ca_me_cepillo",
  # 3: Carmen's own line is the signed ask on the comb (the frog pushes it over): she combs her hair
  {"dots":3},ask("cosa_b","c101_ca_peinilla",after=[act("peina101",quien="carmen")]),"c101_ab_para",
  # 4: Luis comes in from the shower with a towel over his head and a hand out; a speaking turn (aquí); the frog pushes the comb into his hand
  {"dots":4},act("llega",quien="luis",a="lavamanos2"),act("toalla101",quien="luis"),"c101_l_donde","c101_cq_aqui",act("da101",cual="cosa_b",a="luis",ok=1),
  # 5: the turn: Carmen puts a squeeze of paste on the toothbrush and lays it on the shelf beside the comb; she taps the tube (three marks) and the frog's tiny brush; both children stand at the sink with towels over their heads, a hand out;
  # the card shows two places. Round A's values are drawn here (the shelf is laid), the two children are dealt out
  {"dots":5},{"reparte":["ga","gb"],"options":list(KID)}]+setup101("a")+[act("repisa101",izq="$ia"),gesto("carmen","toca",a="tubo"),gesto("carmen","toca",a="cepillito"),
  act("llega",quien="carmen",a="lavamanos1"),act("toalla101",quien="carmen"),act("toalla101",quien="luis"),CARD,{"wait":400},
  # 6: A. 7: B (the shelf is laid again: round B's own values). Each drawn afresh
  {"dots":6}]+juega101("a","ga")
  +[{"dots":7}]+setup101("b")+[act("repisa101",izq="$ib")]+juega101("b","gb"),
 "final":[{"dots":8},baja3(lambda n:act("final101",n=n)),   # 8: the frog's turn: Carmen squeezes what is left onto his tiny brush (three squeezes: a fat stripe, a beard of foam; two: a stripe; one: a dot)
  # 9: the frog brushes and rinses (no act named); abuela: look in the mirror; his mouth sparkles; a speaking turn (limpio)
  {"dots":9},"c101_ab_espejo",act("brilla101"),"c101_cq_limpio","c101_fin",act("fin")],
 "leer":["c101_ab_cepilla","c101_donde_dientes","c101_carmen_cepillo","c101_ca_me_cepillo","c101_ca_peinilla","c101_ab_para","c101_l_donde","c101_cq_aqui",
  "c101_luis_peinilla","c101_ab_espejo","c101_cq_limpio","c101_fin"]}
s101=reuse(s101,{"c101_cq_aqui":TG(("aquí",["aquí","aquí está"])),"c101_cq_limpio":TG(("limpio",["limpio","estoy limpio","limpia"]))})
# the opening's request (Carmen asks for the toothbrush) is the same line as the game's: one clip, c101_carmen_cepillo
json.dump(s101,open("cuentos/los-dientes.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files on disk, and the earlier stories of this run: `limpio` of 99 is the word of a turn in 101)
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s99,s100,s101):
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in EARLIER: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    EARLIER.update(st["focus_words"])
# every clip id the steps name (with no variable in it) is in the story's clips; an id put together from variables: for every value its variables can take; every `leer` id and every `names` clip too
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
VARS={"99":{"oa":["lt","tl"],"ob":["lt","tl"]},"100":{"ka":list(KID),"kb":list(KID),"wa":["bana","lava"],"wb":["bana","lava"]},"101":{"ga":list(KID),"gb":list(KID),"ta":list(THING),"tb":list(THING)}}
for st,vv in ((s99,VARS["99"]),(s100,VARS["100"]),(s101,VARS["101"])):
    for i in sorted(set(refs([st["beats"],st["final"]]))):
        if "$" in i:   # a built id: every value its variables can take must be a clip
            if i.startswith("c99_m_"):   # the two colours are never the same: the 12 lines are checked one by one
                for o in ("lt","tl"):
                    for f in COLS:
                        for t in COLS:
                            if f!=t and "c99_m_%s_%s_%s"%(o,f,t) not in st["clips"]: print("MISSING BUILT CLIP",st["id"],o,f,t)
                continue
            if i.startswith("c99_no_"):
                for t in COLS:
                    if "c99_no_%s"%t not in st["clips"]: print("MISSING BUILT CLIP",st["id"],i,t)
                continue
            combos=[i]
            for v in dict.fromkeys(re.findall(r"\$([a-z]+)",i)): combos=[x.replace("$"+v,val) for x in combos for val in vv.get(v,["?"+v])]
            for x in combos:
                if x not in st["clips"]: print("MISSING BUILT CLIP",st["id"],i,x)
        elif i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for k,v in st["names"].items():
        if v not in st["clips"]: print("MISSING NAME",st["id"],k,v)
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
