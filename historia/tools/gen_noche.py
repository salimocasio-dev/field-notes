# La noche (place 9, La casa, un día entero, scene 4 of 4): stories 105, 106, 107. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/noche.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `noche` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: the generators of places 4 to 8 first (each sees only what was recorded before it), then the four of La casa, un día entero in any order (cuarto, bano, sala_dia, this one).
#   Speaking turns of this scene: 105 también, gracias; 106 limpio, rico; 107 quiero, buenas noches. All are words of places 1 to 8 (buen-provecho, que-calor, buenas-noches of La fonda)
#   EXCEPT `limpio`, a word new in story 99 (limpio-y-sucio, scene bano: written by another builder, not on disk when this one runs alone). The check at the end treats exactly that one as known
#   (KNOWN_ELSEWHERE) while that file is not on disk, and prints a NOTE; once it is on disk the check is strict.
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   105  LAMPS: luz1 = the standing lamp (left), luz2 = the lamp on the shelf (middle), luz3 = the lamp on the small table (right). At the start luz2 is lit; the opening lights luz3 (step 2) and puts luz2 out (step 3), so
#        at the turn only luz3 is lit and the story's variables `la lb lc` (luz1 luz2 luz3; "1" lit, "0" dark) start at 0 0 1. The generator keeps them as the frog leaves them (round B reads them).
#        A request is right on ANY lamp of the kind it asks for (prende: a dark one; apaga: a lit one): the decision's `pick` is the first right lamp (luz1, luz2, luz3) and the others go in `vale`.
#        After a wrong first touch the sign is on `pick`; the lamp he changed wrongly goes back after he touches it (`vuelve105`); the lamp that ends changed is the one touched last (the first right touch, or the sign's).
#        Round B draws its request on its own. The script's sentence "in round B at least one is lit and one dark" does not hold after round A = apaga (the one lit lamp is out): then nothing is lit and the only request
#        with a right answer is prende, so B's request is prende (one calc, `wb`). Reported.
#        The speaker (Luis or Carmen) is drawn each round on its own (no exclusion in the script): the 4 lines (2 speakers x prende, apaga) and their 4 corrections are clips.
#        `luz105` {cual, ok}: cual = the lamp key the frog touched (luz1, luz2, luz3); `vuelve105` {cual}; `bufanda` {n}: 3 at the start, 2 / 1 after a loss (resta), final105 {n} = what is left.
#   106  `lleva106` {que, a, ok}: que = jugo, flan, queso, frutas; a = mesa or aparador (the place); with ok 0 the thing stays there while abuela turns and the candle burns down (the act's own words).
#        A: the cheese, B: the fruit (the script); antes / despues drawn each round on its own (the two may be the same). `vela` {n}: 3 at the start, 2 / 1 after a loss; the candle is lit at step 4 (`vela106`).
#        `perro106` {n}: n = 1 for the first time his paws go up on the table (step 3), 2 for the second (he comes back). The shoo to his bowl and the going back are `llega` perro plato_perro (the spot of the script's Needs). Reported.
#        The family's start spots: abuela junto_mesa, abuelo silla4 (the script: "abuelo at silla4"); Luis and Carmen come to the table: silla1, silla2 (the script names no other spot at the table); Canelo plato_perro.
#   107  `reloj107` {hora}: 8. `acuesta107` / `descansa107` {quien, ok}: quien = luis or carmen; right: ok 1; wrong: ok 0 (he stays where he was led, abuela turns a page down), the sign's touch then runs the right one with ok 1.
#        The child of round A is drawn, round B's is the other one (the script: "the other child"); what each does is drawn on its own. `paginas` {n}: 3 at the start, 2 / 1 after a loss; final107 {n} = what is left.
#        Step 9: the lamps go out = the state `oscuro` 1 (the script's States); the frog hops onto the sill (`ir` ventana_coqui); `canta107` runs with the sung line (`con`).
#   Every story sets its own states at the start (hora noche, tele, mesa, oscuro): every story starts fresh. The script's Start says nothing about which of the three lamps are lit in 106 and 107 (105's start is `luces105` a=0 b=1 c=0): there they are left as the scene has them. Reported.
#   `gesto` targets the script does not name: 105 step 5 "all four with their eyes on it": abuela knits (teje), the other three look at the television (mira, a = television); 106 step 9 "everybody looks at him": the four `mira` a = perro,
#   together with `nariz106`; 107 step 5 abuela looks at the clock and at her three pages (mira reloj, mira libro) and, after a wrong move, at the clock again (the script: "looks at the clock, and turns one page down").
import json,glob,os,re,collections,unicodedata
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); ABO=lambda t:D("abuelo","Abuelo",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
KID={"luis":"Luis","carmen":"Carmen"}
KD=lambda k,t:D(k,KID[k],t)   # a child speaks (105)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time (people walking in together, everybody looking): all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
def START(mesa=0): return {"set":{"hora":"noche","tele":0,"mesa":mesa,"oscuro":0}}   # every story starts fresh
MINE=("prende-y-apaga","antes-y-despues","se-acuesta")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c105_g_$qa_$wa"): never renamed
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
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}
def fija(var,val): return {"draw":var,"options":[val]}   # a variable set to one value (a draw with a single option)

# ---------------- 105. Prende y apaga ----------------
# The frog is at the lamps: Luis or Carmen (drawn), on the rug with their eyes on the screen, asks for a lamp to be lit (prende) or put out (apaga), drawn each round on its own.
# Right: any lamp of the kind asked for changes. A miss: the lamp he touched changes the wrong way, abuela's needles slip (a lamp put out) or abuelo starts and knocks the wool (a lamp lit), a stripe of the scarf comes undone; the sign is on a right lamp.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c105_abo_tele":ABO("Coquí, la televisión, por favor."),"c105_abo_gracias":ABO("Gracias, Coquí."),"c105_ab_prende_tele":AB("Coquí prende la televisión. Abuelo ve televisión."),
 "c105_ab_no_veo":AB("No veo. Coquí, prende una luz, por favor."),"c105_q_prendes":N("¿Qué luz prendes?"),"c105_ab_ahora_veo":AB("Gracias. Coquí prende la luz. Ahora veo."),
 "c105_abo_ay":ABO("¡Ay! No veo la televisión. Coquí, apaga una luz."),"c105_q_apagas":N("¿Qué luz apagas?"),"c105_abo_ahora":ABO("Gracias. Ahora veo la televisión."),"c105_ab_apaga_luz":AB("Coquí apaga la luz."),
 "c105_ca_quiero":CA("¡Yo quiero ver televisión! ¿Y tú, Coquí?"),"c105_cq_tambien":T("¡Yo también!"),
 "c105_ab_para_ti":AB("Para ti, Coquí."),"c105_cq_gracias":T("¡Gracias!"),"c105_fin":N("Por la noche abuelo ve televisión. Coquí prende y apaga la luz.")})
for k in ("luis","carmen"):   # the four requests and the four corrections
    for w in ("prende","apaga"):
        c["c105_g_%s_%s"%(k,w)]=KD(k,"Coquí, %s una luz, por favor."%w); c["c105_no_%s_%s"%(k,w)]=KD(k,"¡No, Coquí! ¡%s una luz!"%w.capitalize())
        DIN.update(["c105_g_%s_%s"%(k,w),"c105_no_%s_%s"%(k,w)])
VARS105={"qa":["luis","carmen"],"qb":["luis","carmen"],"wa":["prende","apaga"],"wb":["prende","apaga"]}
LAMPS=[("la","luz1"),("lb","luz2"),("lc","luz3")]
def ronda105(s):
    # q: who asks; w: prende or apaga; t: the state the right lamps are in now ("0" dark for prende, "1" lit for apaga); y1..y3: whether each lamp is a right one; p: the first right lamp (the sign's);
    # v1..v3: the right lamps (a wrong slot holds p again): the decision's `vale`; pl: the lamp that ends changed (the first touch if right, else the sign's); nv: its new state. la lb lc: the lamps as they stand.
    q,w,t,y1,y2,y3,p,v1,v2,v3,pl,nv=[v+s for v in ("q","w","t","ya","yb","yc","p","va","vb","vc","pl","nv")]
    pre=[{"draw":q,"options":["luis","carmen"]},{"draw":w,"options":["prende","apaga"]}]
    if s=="b":   # nothing lit (round A was apaga on the one lit lamp): the only request with a right answer is prende
        pre+=[{"calc":"hay","cond":"la=1","then":"1","else":"0"},{"calc":"hay","cond":"lb=1","then":"1","else":"$hay"},{"calc":"hay","cond":"lc=1","then":"1","else":"$hay"},{"calc":w,"cond":"hay=1","then":"$"+w,"else":"prende"}]
    pre+=[{"calc":t,"cond":w+"=apaga","then":"1","else":"0"},
     {"calc":y1,"cond":"la=$"+t,"then":"1","else":"0"},{"calc":y2,"cond":"lb=$"+t,"then":"1","else":"0"},{"calc":y3,"cond":"lc=$"+t,"then":"1","else":"0"},
     fija(p,"luz3"),{"calc":p,"cond":y2+"=1","then":"luz2","else":"$"+p},{"calc":p,"cond":y1+"=1","then":"luz1","else":"$"+p},
     {"calc":v1,"cond":y1+"=1","then":"luz1","else":"$"+p},{"calc":v2,"cond":y2+"=1","then":"luz2","else":"$"+p},{"calc":v3,"cond":y3+"=1","then":"luz3","else":"$"+p}]
    dec={"decide":"do","options":["luz1","luz2","luz3"],"pick":"$"+p,"vale":["$"+v1,"$"+v2,"$"+v3],"tests":"$"+w,"lock":True,"lead":[],"line":"c105_g_$%s_$%s"%(q,w),
      "right":[{"calc":pl,"cond":"ok","then":"$x","else":"$"+p},act("luz105",cual="$"+pl,ok=1),{"if":"ok","then":[gesto("$"+q,"si"),OK],"else":[act("vuelve105",cual="$x")]}],
      "wrong":[act("luz105",cual="$x",ok=0),"c105_no_$%s_$%s"%(q,w),resta(lambda n:act("bufanda",n=n))]+X}
    post=[{"calc":nv,"cond":w+"=prende","then":"1","else":"0"}]+[{"calc":v,"cond":pl+"="+lamp,"then":"$"+nv,"else":"$"+v} for v,lamp in LAMPS]
    return pre+[dec]+post
s105={"id":"prende-y-apaga","title":"Prende y apaga","place":"La casa, un día entero","scene":"noche","next":"antes-y-despues",
 "goal":"Light or put out the lamp that Luis or Carmen asks for, so that the little scarf abuela is knitting for the frog keeps its three stripes: a lamp put out when light was wanted makes her drop her stitches in the dark, a lamp lit when dark was wanted makes abuelo knock her wool, and either way a stripe comes undone.",
 "stake":{"thing":"bufanda","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["televisión","ve","prende","apaga"],"formas_foco":{"prende":["prendes"],"apaga":["apagas"],"ve":["veo","ver"]},
 "back_again":["luz","noche","quiero","también","gracias","por favor","mira","ahora","yo","tú","no","sí"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START(),act("bufanda",n=3),act("luces105",a=0,b=1,c=0),act("llega",quien="abuelo",a="sofa1"),act("llega",quien="abuela",a="butaca"),act("ir",a="brazo_coqui"),{"wait":500},
  # 1: abuelo asks for the television (his line is the signed ask on it): the screen lights up, music; he thanks; abuela says what the frog did
  {"dots":1},ask("television","c105_abo_tele",after=[act("tele105",on=1)]),"c105_abo_gracias","c105_ab_prende_tele",
  # 2: abuela holds her knitting close to her eyes (no act named); she asks for a light; signed ask on the dark lamp at the right
  {"dots":2},"c105_ab_no_veo",ask("luz3","c105_q_prendes",after=[act("luz105",cual="luz3",ok=1)]),"c105_ab_ahora_veo",
  # 3: abuelo squints at the screen (the middle lamp's light shines on it: no act named); he asks for a light to be put out; signed ask on the middle lamp; he thanks; abuela says what the frog did
  {"dots":3},gesto("abuelo","entorna"),"c105_abo_ay",ask("luz2","c105_q_apagas",after=[act("luz105",cual="luz2",ok=1)]),"c105_abo_ahora","c105_ab_apaga_luz",
  # 4: Luis and Carmen come in and sit on the rug; Carmen asks the frog; a speaking turn (también); abuela holds the small scarf against his neck (no act named)
  {"dots":4}]+juntos(act("llega",quien="luis",a="alfombra1"),act("llega",quien="carmen",a="alfombra2"))+["c105_ca_quiero","c105_cq_tambien",
  # 5: the turn: abuela knits; abuelo and the children watch the screen; of the three lamps only luz3 is lit; the card shows two places
  {"dots":5}]+juntos(gesto("abuela","teje"),gesto("abuelo","mira",a="television"),gesto("luis","mira",a="television"),gesto("carmen","mira",a="television"))+[CARD,{"wait":400},
  # 6: A. 7: B. Who asks and what for: drawn afresh each round; the lamps as the frog left them
  fija("la","0"),fija("lb","0"),fija("lc","1"),
  {"dots":6}]+ronda105("a")+[{"dots":7}]+ronda105("b"),
 "final":[{"dots":8},baja3(lambda n:act("final105",n=n)),   # 8: abuela bites off the wool and puts the scarf on the frog: twice round his neck (three stripes), once (two), a collar (one)
  {"dots":9},"c105_ab_para_ti","c105_cq_gracias","c105_fin",act("fin")],
 "leer":["c105_abo_tele","c105_abo_gracias","c105_ab_prende_tele","c105_ab_no_veo","c105_q_prendes","c105_ab_ahora_veo","c105_abo_ay","c105_q_apagas","c105_abo_ahora","c105_ab_apaga_luz","c105_ca_quiero","c105_cq_tambien",
  "c105_g_luis_apaga","c105_g_carmen_prende","c105_ab_para_ti","c105_cq_gracias","c105_fin"]}
s105=reuse(s105,{"c105_cq_tambien":TG(("también",["yo también","también"])),"c105_cq_gracias":TG(("gracias",["gracias","muchas gracias"]))})
json.dump(s105,open("cuentos/prende-y-apaga.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 106. Antes y después ----------------
# Abuela, her back to the room, names a thing on the frog's tray (A: the cheese, B: the fruit) and says whether it goes before dinner (antes: the table) or after it (después: the sideboard's shelf); drawn each round on its own (the two may be the same).
# A miss: the thing goes to the other place and stays there, abuela turns round to look and the candle burns down; the sign is on the right place; he touches it and the frog carries the thing across.
nm,nc=nombres("abuela","abuelo","luis","carmen","perro","coqui"); c=dict(comunes); c.update(nc)
c.update({"c106_ab_mira":AB("Coquí, mira: la cena. Está caliente."),"c106_q_cena":N("¿Dónde está la cena?"),
 "c106_ab_manos":AB("¡No, Luis! Antes de la cena te lavas las manos."),"c106_ab_limpias":AB("Las manos limpias, siempre. ¿Y tú, Coquí?"),"c106_cq_limpias":T("¡Sí, limpias!"),
 "c106_ab_perro":AB("¡Canelo! El perro nunca come en la mesa."),"c106_ca_nunca":CA("¡Nunca, Canelo! Tú comes antes de la cena."),
 "c106_ab_jugo":AB("El jugo va antes de la cena."),"c106_ab_flan":AB("El flan va después de la cena."),
 "c106_a_antes":AB("El queso va antes de la cena."),"c106_a_despues":AB("El queso va después de la cena."),"c106_b_antes":AB("Las frutas van antes de la cena."),"c106_b_despues":AB("Las frutas van después de la cena."),
 "c106_no_antes":AB("¡No, Coquí! Antes de la cena."),"c106_no_despues":AB("¡No, Coquí! Después de la cena."),
 "c106_abo_cena":ABO("¿Cómo está la cena, Coquí?"),"c106_cq_rica":T("¡Rica!"),"c106_ab_final":AB("Las manos limpias, siempre. El perro en la mesa, nunca.")})
DIN.update(["c106_a_antes","c106_a_despues","c106_b_antes","c106_b_despues","c106_no_antes","c106_no_despues"])
VARS106={"wa":["antes","despues"],"wb":["antes","despues"]}
def ronda106(s,que):
    # w: antes or despues (drawn); p: the right place (mesa for antes, aparador for despues). Right: the frog carries the thing there. Wrong: the other place, the thing stays there (`lleva106` ok 0), the candle burns down; then the sign's touch puts it right.
    w,p="w"+s,"p"+s
    return [{"draw":w,"options":["antes","despues"]},{"calc":p,"cond":w+"=antes","then":"mesa","else":"aparador"},
     {"decide":"do","options":["mesa","aparador"],"pick":"$"+p,"tests":"$"+w,"lock":True,"lead":[],"line":"c106_%s_$%s"%(s,w),
      "right":[act("lleva106",que=que,a="$"+p,ok=1),star],
      "wrong":[act("lleva106",que=que,a="$x",ok=0),"c106_no_$"+w,resta(lambda n:act("vela",n=n))]+X}]
s106={"id":"antes-y-despues","title":"Antes y después","place":"La casa, un día entero","scene":"noche","next":"se-acuesta",
 "goal":"Carry what is on the frog's tray to the dinner table or to the sideboard's shelf as abuela says, before dinner or after it, so that the tall candle on the table stays tall for dinner by candlelight: every mix-up takes time to put right and the candle burns down.",
 "stake":{"thing":"vela","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["cena","antes","siempre","nunca"],"formas_foco":{},
 "back_again":["después","limpio","mano","mesa","perro","come","jugo","queso","fruta","flan","caliente","rico","te lavas","va","pone","mira","tú","no","sí"],
 "also_heard":[],"names":nm,"palabras":{"despues":"después"},"clips":c,
 "beats":[START(1),act("vela",n=3),act("llega",quien="abuela",a="junto_mesa"),act("llega",quien="abuelo",a="silla4"),act("llega",quien="perro",a="plato_perro"),act("ir",a="aparador_coqui")]+juntos(act("llega",quien="luis",a="silla1"),act("llega",quien="carmen",a="silla2"))+[{"wait":500},
  # 1: abuela lifts a cover: steam; signed ask on the dinner table: the covers shine
  {"dots":1},act("tapa106"),"c106_ab_mira",ask("mesa","c106_q_cena",after=[tw("mesa"),{"wait":700},tw(None)]),
  # 2: Luis reaches for a dish, his hands grey with dirt (no act named); abuela sends him to wash; he comes back with them bright; the frog holds up his hands; a speaking turn (limpio)
  {"dots":2},"c106_ab_manos",act("manos106"),"c106_ab_limpias",gesto("coqui","manos"),"c106_cq_limpias",
  # 3: Canelo's front paws on the table; abuela's line is the signed ask on him: the frog shoos him to his bowl; he comes back and puts his paws up again; Carmen's line; he goes back to his bowl
  {"dots":3},act("perro106",n=1),ask("perro","c106_ab_perro",after=[act("llega",quien="perro",a="plato_perro")]),act("perro106",n=2),"c106_ca_nunca",act("llega",quien="perro",a="plato_perro"),
  # 4: abuela lights the tall candle; the jug before dinner (signed ask on the table), the flan after (signed ask on the sideboard's shelf)
  {"dots":4},act("vela106"),ask("mesa","c106_ab_jugo",after=[act("lleva106",que="jugo",a="mesa",ok=1)]),ask("aparador","c106_ab_flan",after=[act("lleva106",que="flan",a="aparador",ok=1)]),
  # 5: the turn: abuela turns to her bowl of salad at the sideboard's end, her back to the room; Luis and Carmen wait on the sofa; abuelo reads in his chair (no act named); the cheese and the fruit on the tray; the card shows two places
  {"dots":5},act("llega",quien="abuela",a="ensalada")]+juntos(act("llega",quien="luis",a="sofa2"),act("llega",quien="carmen",a="sofa3"))+[CARD,{"wait":400},
  # 6: A (the cheese). 7: B (the fruit). Before or after: drawn afresh each round
  {"dots":6}]+ronda106("a","queso")+[{"dots":7}]+ronda106("b","frutas"),
 "final":[{"dots":8},baja3(lambda n:act("final106",n=n)),   # 8: they all sit down and eat: a tall candle, half a candle, a stub (abuelo brings a lamp)
  {"dots":9},"c106_abo_cena","c106_cq_rica"]+juntos(act("nariz106"),*[gesto(q,"mira",a="perro") for q in ("abuela","abuelo","luis","carmen")])+["c106_ab_final",act("fin")],   # 9: Canelo's nose comes up at the table's edge; everybody looks at him; it goes down again
 "leer":["c106_ab_mira","c106_q_cena","c106_ab_manos","c106_ab_limpias","c106_cq_limpias","c106_ab_perro","c106_ca_nunca","c106_ab_jugo","c106_ab_flan",
  "c106_a_antes","c106_b_despues","c106_abo_cena","c106_cq_rica","c106_ab_final"]}
s106=reuse(s106,{"c106_cq_limpias":TG(("limpio",["sí limpias","limpias","están limpias","limpio"])),"c106_cq_rica":TG(("rico",["rica","está rica","muy rica","rico"]))})
json.dump(s106,open("cuentos/antes-y-despues.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 107. Se acuesta ----------------
# Abuela, her eyes on her book, says what one of the children does now (Luis or Carmen, drawn; round B's is the other child; what he does is drawn on its own each round): se acuesta (to the bed) or descansa un momento (to the sofa).
# A miss: the child goes to the other place and stays there, abuela looks at the clock and turns one page down; the sign is on the right place; he touches it and the frog leads the child across.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c107_ab_ocho":AB("Son las ocho de la noche. A las ocho, Carmen se acuesta."),"c107_ca_sueno":CA("Todos los días, a las ocho... Tengo sueño."),
 "c107_abo_descanso":ABO("Yo no tengo sueño. Yo descanso un momento."),"c107_ab_descansa":AB("Abuelo descansa todos los días. Carmen se acuesta."),
 "c107_l_yo":L("¿Y yo?"),"c107_ab_tu":AB("Abuelo descansa. Tú te acuestas. Todos los días, a las ocho."),
 "c107_ab_libro":AB("Después, un libro. ¿Quieres, Coquí?"),"c107_cq_quiero":T("¡Sí, quiero!"),
 "c107_ab_hasta":AB("Hasta mañana, Coquí."),"c107_cq_noches":T("¡Buenas noches!"),"c107_cq_canta":T("¡Coquí! ¡Coquí!"),"c107_fin":N("Todos los días, por la noche, la familia descansa. Y Coquí canta.")})
for k in ("luis","carmen"):   # abuela says what the child does (four lines) and, after a miss, what he does again (four lines)
    for w,t,u in (("acuesta","se acuesta","se acuesta"),("descansa","descansa un momento","descansa")):
        c["c107_%s_%s"%(k,w)]=AB("%s %s."%(KID[k],t)); c["c107_no_%s_%s"%(k,w)]=AB("No, Coquí. %s %s."%(KID[k],u))
        DIN.update(["c107_%s_%s"%(k,w),"c107_no_%s_%s"%(k,w)])
VARS107={"qa":["luis","carmen"],"qb":["luis","carmen"],"wa":["acuesta","descansa"],"wb":["acuesta","descansa"]}
def ronda107(s):
    # q: the child; w: acuesta or descansa (drawn); p: the right place (cama or sofa). Right: he goes there. Wrong: the other place (x): he stays there, abuela turns a page down; then the sign's touch leads him across.
    q,w,p="q"+s,"w"+s,"p"+s
    first=[{"draw":"qa","options":["luis","carmen"],"other":"qb"}] if s=="a" else []
    return first+[{"draw":w,"options":["acuesta","descansa"]},{"calc":p,"cond":w+"=acuesta","then":"cama","else":"sofa"},
     {"decide":"do","options":["cama","sofa"],"pick":"$"+p,"tests":"$"+w,"lock":True,"lead":[],"line":"c107_$%s_$%s"%(q,w),
      "right":[{"if":w+"=acuesta","then":[act("acuesta107",quien="$"+q,ok=1)],"else":[act("descansa107",quien="$"+q,ok=1)]},star],
      "wrong":[{"if":"x=cama","then":[act("acuesta107",quien="$"+q,ok=0)],"else":[act("descansa107",quien="$"+q,ok=0)]},"c107_no_$%s_$%s"%(q,w),gesto("abuela","mira",a="reloj"),resta(lambda n:act("paginas",n=n))]+X}]
s107={"id":"se-acuesta","title":"Se acuesta","place":"La casa, un día entero","scene":"noche","next":None,
 "goal":"Lead each child to the bed or to the sofa as abuela says, so that her storybook keeps its three pages for the bedtime reading: every mix-up takes time, and abuela looks at the clock and turns one page down.",
 "stake":{"thing":"paginas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["se acuesta","descansa","todos los días"],"formas_foco":{"se acuesta":["te acuestas"],"descansa":["descanso"]},
 "back_again":["tiene sueño","cama","libro","noche","son las","ocho","a las","después","quiero","buenas noches","hasta mañana","un momento","yo","tú","no","sí"],
 "also_heard":["canta"],"names":nm,"palabras":{"acuesta":"se acuesta"},"clips":c,
 "beats":[START(),act("reloj107",hora=8),act("paginas",n=3),act("llega",quien="abuela",a="butaca"),act("llega",quien="abuelo",a="ventana_abuelo")]+juntos(act("llega",quien="luis",a="alfombra1"),act("llega",quien="carmen",a="alfombra2"))+[act("ir",a="brazo_coqui")]+juntos(gesto("luis","bosteza"),gesto("carmen","bosteza"))+[{"wait":500},
  # 1: the hour; abuela's line is the signed ask on the bed: the frog turns the blanket back and Carmen gets in; she says she is sleepy
  {"dots":1},ask("cama","c107_ab_ocho",after=[act("acuesta107",quien="carmen",ok=1)]),"c107_ca_sueno",
  # 2: abuelo folds his newspaper; his line is the signed ask on the sofa: the frog pats the cushion and abuelo sits down with his feet up; abuela says what each does
  {"dots":2},gesto("abuelo","dobla"),ask("sofa","c107_abo_descanso",after=[act("descansa107",quien="abuelo",ok=1)]),"c107_ab_descansa",
  # 3: Luis asks; abuela answers; Luis gets into the bed, beside Carmen
  {"dots":3},"c107_l_yo","c107_ab_tu",act("acuesta107",quien="luis",ok=1),
  # 4: abuela holds up her open book (no act named); a speaking turn (quiero)
  {"dots":4},"c107_ab_libro","c107_cq_quiero",
  # 5: the turn: the children are up again, abuelo sleeps on the sofa's end; abuela looks at the clock and at her three pages; the card shows two places
  {"dots":5},act("levantados107"),gesto("abuela","mira",a="reloj"),gesto("abuela","mira",a="libro"),CARD,{"wait":400},
  # 6: A. 7: B (the other child). What he does: drawn afresh each round
  {"dots":6}]+ronda107("a")+[{"dots":7}]+ronda107("b"),
 "final":[{"dots":8},gesto("abuela","palmas"),baja3(lambda n:act("final107",n=n)),   # 8: both children get into the bed; abuela reads and the pictures of her pages float up (a boat, a star, a frog), by the pages left
  {"dots":9},{"set":{"oscuro":1}},act("ir",a="ventana_coqui"),"c107_ab_hasta","c107_cq_noches"]+con(act("canta107"),"c107_cq_canta")+["c107_fin",act("fin")],   # 9: the lamps go out; the frog on the sill; goodnight; he sings
 "leer":["c107_ab_ocho","c107_ca_sueno","c107_abo_descanso","c107_ab_descansa","c107_l_yo","c107_ab_tu","c107_ab_libro","c107_cq_quiero",
  "c107_luis_descansa","c107_no_luis_descansa","c107_carmen_acuesta","c107_ab_hasta","c107_cq_noches","c107_cq_canta","c107_fin"]}
s107=reuse(s107,{"c107_cq_quiero":TG(("quiero",["quiero","sí quiero"])),"c107_cq_noches":TG(("buenas noches",["buenas noches"]))})
json.dump(s107,open("cuentos/se-acuesta.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files on disk, and the earlier stories of this run). One word is new in a story of ANOTHER scene of this place, which another generator writes:
# while its file is not on disk it is known (and a NOTE says so); once it is on disk the check is strict.
KNOWN_ELSEWHERE={"limpio":"limpio-y-sucio"}
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s105,s106,s107):
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            w=t["palabra"]
            if w in EARLIER: continue
            if w in KNOWN_ELSEWHERE and not os.path.exists("cuentos/%s.json"%KNOWN_ELSEWHERE[w]): print("NOTE: the turn on '%s' (%s, %s) takes a word of story %s, written by another generator and not on disk here: taken as known"%(w,st["id"],cid,KNOWN_ELSEWHERE[w]))
            else: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,w)
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
for st,VARS in ((s105,VARS105),(s106,VARS106),(s107,VARS107)):
    for i in sorted(set(refs([st["beats"],st["final"]]))):
        if "$" in i:   # a built id: every value its variables can take must be a clip
            combos=[i]
            for v in dict.fromkeys(re.findall(r"\$([a-z]+)",i)): combos=[x.replace("$"+v,val) for x in combos for val in VARS.get(v,["?"+v])]
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
