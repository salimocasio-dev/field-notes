# La cuenta (place 8, La fonda, scene 4 of 4): stories 93, 94, 95. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/cuenta.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `cuenta` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: the generators of places 4 to 7 first (each sees only what was recorded before it), then the four of La fonda in any order (this one, entrada, pedido, comida).
#   Speaking turns of this place that take a word new in a story of ANOTHER scene of this place (written by another generator, not on disk when this one runs alone):
#     93: `para mí` (story 89, las-bebidas) and `delicioso` (story 92, mas-y-menos). The check at the end treats exactly these two as known (KNOWN_ELSEWHERE) while those two files are not on disk, and prints a NOTE; once they are on disk the check is strict.
#     94's `nada más` is a word of 93 and 95's `cuenta` a word of 94 (this generator's own stories, in order).
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   GUESTS: the guests of the games are drawn from the script's four (el señor, la señora, el joven, la mujer), one each round, never the same two rounds (the script says "another guest").
#     94: the señor of the opening (step 4) has paid already and is not drawn again ("more guests come up"): POOL94.
#   `sirve93` {que, a, ok}: que = what the frog does (flan, mantecado, nada), a = the guest, ok 1 = a nod, 0 = a hand held up. A wrong touch is turned into the same value by a short chain of calcs (xq).
#   `cobra94` {como, ok}: como = what the frog does (tarjeta = pushes the machine, efectivo = springs the drawer), ok 1 = a beep or bills laid down, 0 = a frown; on a wrong touch como is the other one (xc).
#   `guarda95` {donde, ok}: donde = the thing key (gaveta, frasco); ok 1 = they stay, 0 = he fishes them out and puts them right. A wrong move runs it started loose with the correction line (the act and the line go together).
#   `guagua` {n}: the state values of the script: no, lejos, medio, cerca. Each mix-up moves it one lamp nearer: lejos -> medio -> cerca.
#   `copa` {n}: 0 at the start, 1, 2, 3 as she fills it; a wrong move leaves 2 (first mix-up) or 1 (second). `frasco` {n}: 0 at the start, 1 after abuelo's coin; after a clean round the coins in it (A: 2; B: 3, or 2 if A was a muddle).
#   `final93` / `final94` / `final95` {n}: n = what is left (scoops, coins, lamps between the guagua and the stop) = 3 minus the steps lost (3: all right; 1: both rounds lost).
#   The opening of 94 and 95 is the Needs list's own: `cuenta94` {n=40}; `moneda94` {quien=abuelo, mete=1}; 95: the family goes to umbral1 to umbral4 in the order of the script's People line (abuela, abuelo, Luis, Carmen).
#   `ir`: only the spots the script names for the frog (carrito_coqui in 93; mostrador_coqui in 94 and 95). The family's own places at the start (silla1 to silla4, familia1 to familia4) are the scene's default: no `llega` is issued for them.
#   94, 95: at the turn the two guests of the rounds come up behind the one at the register (llega to fila1, fila2); each round the guest of it steps up to `paga`.
#     94: nobody leaves in the script until "the last guest goes" (step 9), and `paga` would be taken: the señor of the opening leaves after the change, and the guest of round A leaves at the start of round B (`sale`, the script's own act). Two lines to drop if the scene frees `paga` by itself.
#   `gesto` targets the script does not name: 94 step 6 points at the guests' coins (a = fila1, the first of the line) and at the jar (frasco); 95 step 3 Carmen looks at the dessert case (a = flanes). 95 step 3 "they laugh" = the four of the family.
#   `decide` of 94 in a muddle: the coin goes back in his pocket (`moneda94` mete=0) before the cross; the payment (`cobra94` with the right thing) follows the right touch, as for every wrong move, and drops no coin (the star and the coin only when the first touch was right).
#   Every story sets its own states at the start (hora noche, sillas abajo, guagua no): every story starts fresh.
import json,glob,os,re,collections,unicodedata
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); ABO=lambda t:D("abuelo","Abuelo",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
ME=lambda t:D("mesera","La mesera",t); MO=lambda t:D("mesero","El mesero",t); CO=lambda t:D("cocinero","El cocinero",t)
GUEST={"senor":"El señor","senora":"La señora","joven":"El joven","mujer":"La mujer"}
GU=lambda g,t:D(g,GUEST[g],t)
GUESTS=["senor","senora","joven","mujer"]
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time (people walking in or out together, everybody laughing): all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
START={"set":{"hora":"noche","sillas":"abajo","guagua":"no"}}   # every story starts fresh
MINE=("el-postre","la-cuenta-por-favor","buenas-noches")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c93_$ga_$da"): never renamed
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
# What he hears when he pokes a person already recorded (the new ones add nothing: the mesera, the mesero, the cocinero, abuelo)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora.")),"hombre":("b_n_hombre",N("Es un hombre.")),"mujer":("b_n_mujer",N("Es una mujer.")),"joven":("b_n_joven",N("Es un joven."))}
def nombres(*ks):
    return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
TENS={20:"veinte",30:"treinta",40:"cuarenta",50:"cincuenta",60:"sesenta",70:"setenta",80:"ochenta",90:"noventa"}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}

# ---------------- 93. El postre ----------------
# The cart rolls to the next table; a guest (drawn, one of the four) says one of three things (drawn): "Para mí, flan." / "Para mí, mantecado." / "Para mí, nada más."; each round on its own, the two guests differ.
# Decision A and B: touch a thing (the flans, the tub, the cover; tests flan, mantecado and nada más). A miss: the frog does the other thing, the guest holds up a hand, he says "No, Coquí. <what he said>.", a scoop in the cup melts away.
c=dict(comunes); nm,nc=nombres("abuela","luis","carmen","coqui","senor","senora","joven","mujer"); c.update(nc)
c.update({"c93_me_postre":ME("¿Postre? Hay flan y hay mantecado."),"c93_donde_flan":N("¿Dónde está el flan?"),"c93_l_postre":L("¡Postre! ¡Mantecado, por favor!"),"c93_donde_mantecado":N("Luis quiere mantecado. ¿Dónde está?"),
 "c93_ca_flan":CA("De postre, flan, por favor."),"c93_ab_flan":AB("Y para mí, flan también."),
 "c93_me_usted":ME("¿Y para usted? ¿Flan o mantecado?"),"c93_abo_nada":ABO("Para mí, nada más. Estoy lleno."),"c93_me_nada":ME("¿Nada más?"),"c93_toca_tapa":N("Abuelo no quiere nada más. ¿Qué toca Coquí?"),
 "c93_me_algo_mas":ME("Mantecado para Luis y flan para Carmen. ¿Algo más?"),"c93_ab_nada_gracias":AB("Nada más, gracias."),"c93_cq_para_mi":T("¿Y para mí?"),"c93_me_para_ti":ME("Mantecado para ti, Coquí. Después."),
 "c93_me_como":ME("¿Cómo está el mantecado, Coquí?"),"c93_cq_delicioso":T("¡Delicioso!"),"c93_fin":N("Coquí come mantecado. ¡Qué rico!")})
for g in GUESTS:   # the six sentences of each guest: what he asks for, and the correction for each
    for d,w in (("flan","flan"),("mantecado","mantecado"),("nada","nada más")):
        c["c93_%s_%s"%(g,d)]=GU(g,"Para mí, %s."%w); c["c93_no_%s_%s"%(g,d)]=GU(g,"No, Coquí. %s."%(w[0].upper()+w[1:]))
        DIN.update(["c93_%s_%s"%(g,d),"c93_no_%s_%s"%(g,d)])
VARS93={"ga":GUESTS,"gb":GUESTS,"da":["flan","mantecado","nada"],"db":["flan","mantecado","nada"]}
def ronda93(s,g):
    # one round: d: what the guest asks for (flan, mantecado, nada); k: the thing that does it. Right: the frog does it, a nod (after "nada más" he pats his belly). Wrong: another thing (xq: what he did).
    d,k=("d"+s),("k"+s)
    return [{"draw":d,"options":["flan","mantecado","nada"]},
     {"calc":k,"cond":d+"=flan","then":"flanes","else":"tapa"},{"calc":k,"cond":d+"=mantecado","then":"mantecado","else":"$"+k},
     {"decide":"do","options":["flanes","mantecado","tapa"],"pick":"$"+k,"tests":"$"+d,"lock":True,"lead":[],"line":"c93_$%s_$%s"%(g,d),
      "right":[act("sirve93",que="$"+d,a="$"+g,ok=1),{"if":d+"=nada","then":[gesto("$"+g,"barriga")]},star],
      "wrong":[{"calc":"xq","cond":"x=flanes","then":"flan","else":"nada"},{"calc":"xq","cond":"x=mantecado","then":"mantecado","else":"$xq"},
               act("sirve93",que="$xq",a="$"+g,ok=0),"c93_no_$%s_$%s"%(g,d),resta(lambda n:act("copa",n=n))]+X}]
s93={"id":"el-postre","title":"El postre","place":"La fonda","scene":"cuenta","next":"la-cuenta-por-favor",
 "goal":"Serve each guest at the next table the dessert he asks for (flan, ice cream, or nothing more) so that the little cup of three scoops of ice cream the mesera filled for him stays full: the night is warm, and every mix-up lets a scoop melt away.",
 "stake":{"thing":"copa","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["postre","flan","mantecado","nada más"],"formas_foco":{},
 "back_again":["delicioso","rico","para mí","lleno","mesera","quiere","también","hay","toca","come","después","¿algo más?","por favor","gracias","no"],
 "also_heard":["usted","estoy lleno"],"names":nm,"palabras":{"nada":"nada más"},"clips":c,
 "beats":[START,act("copa",n=0),act("carrito93",a="carrito"),act("ir",a="carrito_coqui"),{"wait":500},
  # 1: the mesera names the two desserts (signed ask on the flans; "it wobbles": no act named); Luis asks for ice cream (signed ask on the tub)
  {"dots":1},"c93_me_postre",ask("flanes","c93_donde_flan"),"c93_l_postre",ask("mantecado","c93_donde_mantecado",after=[act("sirve93",que="mantecado",a="luis",ok=1)]),
  # 2: Carmen and abuela each have a flan
  {"dots":2},"c93_ca_flan",act("sirve93",que="flan",a="carmen",ok=1),"c93_ab_flan",act("sirve93",que="flan",a="abuela",ok=1),
  # 3: the mesera turns to abuelo; he pats his belly; signed ask on the cover
  {"dots":3},gesto("mesera","mira",a="abuelo"),"c93_me_usted",gesto("abuelo","barriga"),"c93_abo_nada","c93_me_nada",ask("tapa","c93_toca_tapa",after=[act("sirve93",que="nada",a="abuelo",ok=1)]),
  # 4: the cover goes up again (no act named); "¿Algo más?"; a speaking turn (para mí); the mesera laughs and fills the cup: one scoop, two, three
  {"dots":4},"c93_me_algo_mas","c93_ab_nada_gracias","c93_cq_para_mi",gesto("mesera","rie"),act("copa",n=1),act("copa",n=2),act("copa",n=3),"c93_me_para_ti",
  # 5: the turn: the cart goes to the next table; the three scoops shine and a first drop runs down the cup (no act named); the card shows two places
  {"dots":5},act("carrito93",a="otra_mesa"),CARD,{"wait":400},
  # 6: A. 7: B. Which guest, and what he asks for, drawn afresh each round
  {"reparte":["ga","gb"],"options":GUESTS},
  {"dots":6}]+ronda93("a","ga")+[{"dots":7}]+ronda93("b","gb"),
 "final":[{"dots":8},baja3(lambda n:act("final93",n=n)),   # 8: the cup, by the scoops left (three; two in a little pool; one in a big pool); 9: the spoonful (no act named)
  {"dots":9},"c93_me_como","c93_cq_delicioso","c93_fin",act("fin")],
 "leer":["c93_me_postre","c93_donde_flan","c93_l_postre","c93_donde_mantecado","c93_ca_flan","c93_ab_flan","c93_me_usted","c93_abo_nada","c93_me_nada","c93_toca_tapa","c93_me_algo_mas","c93_ab_nada_gracias","c93_cq_para_mi","c93_me_para_ti",
  "c93_senor_mantecado","c93_mujer_nada","c93_me_como","c93_cq_delicioso","c93_fin"]}
s93=reuse(s93,{"c93_cq_para_mi":TG(("para mí",["y para mí","para mí"])),"c93_cq_delicioso":TG(("delicioso",["delicioso","está delicioso"]))})
json.dump(s93,open("cuentos/el-postre.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 94. La cuenta, por favor ----------------
# A guest (drawn) asks for the bill; the mesera reads the total (veinte to noventa, drawn; the two rounds differ) and asks "¿Tarjeta o efectivo?"; the guest answers (drawn): "Efectivo, por favor." / "Con tarjeta, por favor."
# Decision A and B: touch a thing (the card machine, the drawer; tests tarjeta against efectivo). A miss: the frog does the other thing, a frown, "No, Coquí. <how he pays>.", the guest puts his coin back in his pocket.
POOL94=["senora","joven","mujer"]   # the señor of the opening has paid already
c=dict(comunes); nm,nc=nombres("abuela","luis","carmen","coqui","senor","senora","joven","mujer"); c.update(nc)
c.update({"c94_ab_cuenta":ABO("La cuenta, por favor."),"c94_me_aqui_tiene":ME("La cuenta. Aquí tiene."),"c94_donde_cuenta":N("¿Dónde está la cuenta de abuelo?"),
 "c94_abo_cuanto":ABO("¿Cuánto es?"),"c94_me_total_40":ME("El total son cuarenta pesos."),"c94_ab_total":AB("Cuarenta pesos. Mira, Coquí: aquí está el total."),"c94_donde_total":N("¿Dónde está el total en la cuenta?"),
 "c94_me_tarjeta_o":ME("¿Tarjeta o efectivo?"),"c94_abo_tarjeta":ABO("Tarjeta."),"c94_paga_tarjeta":N("Abuelo paga con tarjeta. ¿Qué toca Coquí?"),"c94_me_con_tarjeta":ME("Con tarjeta. Gracias."),
 "c94_senor_cash":GU("senor","Cash."),"c94_me_en_efectivo":ME("En efectivo. Gracias."),"c94_paga_efectivo":N("El señor paga en efectivo. ¿Qué toca Coquí?"),"c94_me_cambio":ME("Aquí tiene el cambio."),
 "c94_me_toma":ME("Toma, Coquí. ¿Algo más?"),"c94_cq_nada_mas":T("Nada más, gracias."),
 "c94_me_esto":ME("Esto es para ti, Coquí."),"c94_cq_gracias":T("¡Gracias!"),"c94_fin":N("Todo está en la caja. La mesera cierra la caja.")})
for n,w in TENS.items():   # what the mesera says in the game (and in the opening, for 30)
    c["c94_t_%d"%n]=ME("El total son %s pesos. ¿Tarjeta o efectivo?"%w); DIN.add("c94_t_%d"%n)
for g in POOL94:
    c["c94_%s_cuenta"%g]=GU(g,"La cuenta, por favor."); c["c94_%s_efectivo"%g]=GU(g,"Efectivo, por favor."); c["c94_%s_tarjeta"%g]=GU(g,"Con tarjeta, por favor.")
    c["c94_no_%s_efectivo"%g]=GU(g,"No, Coquí. Efectivo."); c["c94_no_%s_tarjeta"%g]=GU(g,"No, Coquí. Tarjeta.")
    DIN.update(["c94_%s_cuenta"%g,"c94_%s_efectivo"%g,"c94_%s_tarjeta"%g,"c94_no_%s_efectivo"%g,"c94_no_%s_tarjeta"%g])
VARS94={"ga":POOL94,"gb":POOL94,"ca":["efectivo","tarjeta"],"cb":["efectivo","tarjeta"],"ta":[str(n) for n in TENS],"tb":[str(n) for n in TENS]}
def ronda94(s,g,t,primera,jar):
    # one round: the guest steps up and asks for the bill, the mesera reads the total (t), he answers how he pays (c, drawn). Right: the machine (tarjeta) or the drawer (efectivo), and his coin drops in the jar. Wrong: the other one, a frown; his coin goes back in his pocket.
    cc,k="c"+s,"k"+s
    return primera+[{"draw":cc,"options":["efectivo","tarjeta"]},{"calc":k,"cond":cc+"=efectivo","then":"gaveta","else":"maquina"},
     act("llega",quien="$"+g,a="paga"),"c94_$%s_cuenta"%g,"c94_t_$"+t,
     {"decide":"do","options":["maquina","gaveta"],"pick":"$"+k,"tests":"$"+cc,"lock":True,"lead":[],"line":"c94_$%s_$%s"%(g,cc),
      "right":[act("cobra94",como="$"+cc,ok=1),{"if":"ok","then":[act("moneda94",quien="$"+g,mete=1)]+jar+[OK]}],
      "wrong":[{"calc":"xc","cond":"x=maquina","then":"tarjeta","else":"efectivo"},act("cobra94",como="$xc",ok=0),"c94_no_$%s_$%s"%(g,cc),act("moneda94",quien="$"+g,mete=0)]+X}]
s94={"id":"la-cuenta-por-favor","title":"La cuenta, por favor","place":"La fonda","scene":"cuenta","next":"buenas-noches",
 "goal":"Take each guest's payment the way he says he pays (the card machine or the cash drawer) so that the glass jar beside the register collects the guests' coins, up to three, abuelo's first: a guest who gets a muddle puts his coin back in his pocket.",
 "stake":{"thing":"frasco","steps":3},"dots":10,"bien":"si_muy_bien",
 "focus_words":["cuenta","total","tarjeta","efectivo"],"formas_foco":{},
 "back_again":["nada más","¿algo más?","¿cuánto es?","peso","cambio","caja","paga","cierra","veinte","treinta","cuarenta","cincuenta","sesenta","setenta","ochenta","noventa","mesera","aquí tiene","toma","toca","con","todo","mira","por favor","gracias","no"],
 "also_heard":["cash"],"names":nm,"palabras":{},"clips":c,
 "beats":[START,act("frasco",n=0),act("ir",a="mostrador_coqui"),{"wait":500},
  # 1: abuelo asks for the bill; the mesera pulls a slip off the spike (no act named); signed ask on it ("the frog carries the slip to abuelo": no act named)
  {"dots":1},"c94_ab_cuenta","c94_me_aqui_tiene",ask("cuenta","c94_donde_cuenta"),
  # 2: abuelo holds the slip far off and near (no act named); the total is forty; the slip grows (signed ask on the number at its foot: the engine's twinkle)
  {"dots":2},"c94_abo_cuanto","c94_me_total_40",act("cuenta94",n=40),"c94_ab_total",ask("cuenta","c94_donde_total",after=[tw("cuenta"),{"wait":700},tw(None)]),
  # 3: tarjeta or efectivo; abuelo opens his wallet and takes out the card (no act named); signed ask on the machine; his coin in the jar
  {"dots":3},"c94_me_tarjeta_o","c94_abo_tarjeta",ask("maquina","c94_paga_tarjeta",after=[act("cobra94",como="tarjeta",ok=1)]),"c94_me_con_tarjeta",act("moneda94",quien="abuelo",mete=1),act("frasco",n=1),
  # 4: the señor steps up with bills (signed ask on the drawer); he goes after the change (`sale`: the script does not say, see the header)
  {"dots":4},act("llega",quien="senor",a="paga"),"c94_t_30","c94_senor_cash","c94_me_en_efectivo",ask("gaveta","c94_paga_efectivo",after=[act("cobra94",como="efectivo",ok=1)]),"c94_me_cambio",act("sale",quien="senor"),
  # 5: the mesera holds out the bowl of mints and he takes one (no act named); a speaking turn (nada más)
  {"dots":5},"c94_me_toma","c94_cq_nada_mas",
  # 6: the turn: two more guests come up behind one another (dealt out of the pool); the mesera shakes the jar and points at the guests' coins and at the jar; the card shows two places
  {"reparte":["ga","gb"],"options":POOL94},{"reparte":["ta","tb"],"options":[str(n) for n in TENS]},
  {"dots":6}]+juntos(act("llega",quien="$ga",a="fila1"),act("llega",quien="$gb",a="fila2"))+[gesto("mesera","agita"),gesto("mesera","senala",a="fila1"),gesto("mesera","senala",a="frasco"),CARD,{"wait":400},
  # 7: A. 8: B (the guest of A leaves, the other steps up). Which guest, the total and how he pays: drawn afresh each round
  {"dots":7}]+ronda94("a","ga","ta",[],[act("frasco",n=2)])
  +[{"dots":8}]+ronda94("b","gb","tb",[act("sale",quien="$ga")],[{"if":"lost=0","then":[act("frasco",n=3)],"else":[act("frasco",n=2)]}]),
 "final":[{"dots":9},act("sale",quien="$gb"),baja3(lambda n:act("final94",n=n)),   # 9: the last guest goes; the jar is tipped out: the coins left (three; two; one: abuelo's)
  {"dots":10},"c94_me_esto","c94_cq_gracias",act("cierra94"),"c94_fin",act("fin")],
 "leer":["c94_ab_cuenta","c94_me_aqui_tiene","c94_donde_cuenta","c94_abo_cuanto","c94_me_total_40","c94_ab_total","c94_donde_total","c94_me_tarjeta_o","c94_abo_tarjeta","c94_paga_tarjeta","c94_me_con_tarjeta","c94_t_30","c94_senor_cash","c94_me_en_efectivo","c94_paga_efectivo","c94_me_cambio",
  "c94_me_toma","c94_cq_nada_mas","c94_senora_cuenta","c94_t_60","c94_senora_efectivo","c94_joven_cuenta","c94_t_20","c94_joven_tarjeta","c94_me_esto","c94_cq_gracias","c94_fin"]}
s94=reuse(s94,{"c94_cq_nada_mas":TG(("nada más",["nada más","nada más gracias"])),"c94_cq_gracias":TG(("gracias",["gracias","muchas gracias"]))})
json.dump(s94,open("cuentos/la-cuenta-por-favor.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 95. Buenas noches ----------------
# A guest (drawn) holds out folded bills and says what they are for (drawn): "Esto es para la propina." / "Esto es para la cuenta."; the frog puts them in the register's drawer (cuenta) or in the jar (propina). Each round on its own; the two guests differ.
# Decision A and B: touch a thing (the drawer, the jar; tests propina against cuenta). A miss: the bills go in the wrong place, he says "No, Coquí. Para <what it was for>.", the frog puts them right, the guagua's lights come one lamp nearer.
c=dict(comunes); nm,nc=nombres("abuela","luis","carmen","coqui","senor","senora","joven","mujer"); c.update(nc)
c.update({"c95_mo_buenas_noches":MO("Buenas noches. ¿Algo más?"),"c95_cq_cuenta":T("La cuenta, por favor."),"c95_abo_cuenta":ABO("Esto es para la cuenta."),"c95_donde_cuenta":N("¿Dónde pones los pesos de la cuenta?"),
 "c95_abo_propina":ABO("Y esto es para la propina."),"c95_donde_propina":N("¿Dónde pones la propina?"),"c95_mo_gracias_propina":MO("¡Gracias por la propina!"),"c95_ab_otra_propina":AB("Y otra propina, para el cocinero. ¡El flan está delicioso!"),
 "c95_mo_todo_bien":MO("¿Todo bien?"),"c95_abo_todo_bien":ABO("Todo bien. Estoy lleno."),"c95_l_lleno":L("¡Yo también estoy lleno!"),"c95_ca_llena":CA("Yo no estoy llena. ¿Hay más flan?"),
 "c95_me_hasta_luego":ME("Buenas noches. ¡Hasta luego!"),"c95_ab_hasta_luego":AB("Buenas noches. Hasta luego."),"c95_co_hasta_luego":CO("¡Hasta luego, Luis! ¡Hasta luego, Carmen!"),"c95_ab_guagua":AB("¡La guagua! Vamos, Coquí."),
 "c95_me_caja":ME("¡Coquí, la caja, por favor!"),"c95_me_adios":ME("¡Buenas noches, Coquí! ¡Hasta luego!"),"c95_cq_adios":T("¡Adiós!"),"c95_fin":N("La familia va para casa. Buenas noches, fonda.")})
for g in GUESTS:
    for p in ("propina","cuenta"):
        c["c95_%s_%s"%(g,p)]=GU(g,"Esto es para la %s."%p); c["c95_no_%s_%s"%(g,p)]=GU(g,"No, Coquí. Para la %s."%p); DIN.update(["c95_%s_%s"%(g,p),"c95_no_%s_%s"%(g,p)])
    c["c95_a_%s"%g]=GU(g,"Gracias. Hasta luego."); c["c95_b_%s"%g]=GU(g,"Gracias. Buenas noches."); DIN.update(["c95_a_%s"%g,"c95_b_%s"%g])
VARS95={"ga":GUESTS,"gb":GUESTS,"pa":["propina","cuenta"],"pb":["propina","cuenta"]}
def ronda95(s,g):
    # one round: the guest holds out the bills (p: what they are for, drawn). Right: they go in the drawer (cuenta) or the jar (propina); he thanks and goes out past the family. Wrong: the other place (x), the frog puts them right; the guagua's lights come one lamp nearer.
    p,k=("p"+s),("k"+s)
    return [{"draw":p,"options":["propina","cuenta"]},{"calc":k,"cond":p+"=propina","then":"frasco","else":"gaveta"},
     act("llega",quien="$"+g,a="paga"),
     {"decide":"do","options":["gaveta","frasco"],"pick":"$"+k,"tests":"$"+p,"lock":True,"lead":[],"line":"c95_$%s_$%s"%(g,p),
      "right":[act("guarda95",donde="$"+k,ok=1),"c95_%s_$%s"%(s,g),act("sale",quien="$"+g),star],
      "wrong":con(act("guarda95",donde="$x",ok=0),"c95_no_$%s_$%s"%(g,p))+[{"if":"lost=0","then":[act("guagua",n="medio")],"else":[act("guagua",n="cerca")]}]+X}]
s95={"id":"buenas-noches","title":"Buenas noches","place":"La fonda","scene":"cuenta","next":None,
 "goal":"Put each last guest's folded bills where he says they are for, in the register's drawer for the bill or in the glass jar for the tip, so that the family catches the last guagua of the night: every mix-up takes time, and the guagua's lights come one lamp nearer.",
 "stake":{"thing":"guagua","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["propina","estoy lleno","hasta luego","buenas noches"],"formas_foco":{"estoy lleno":["estoy llena"]},
 "back_again":["cuenta","caja","peso","mesero","mesera","cocinero","flan","delicioso","para","otro","guagua","vamos","también","todo","bien","casa","adiós","esto","aquí","hay","más","¿algo más?","pone","por favor","gracias","no"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START,act("ir",a="mostrador_coqui"),act("llega",quien="mesero",a="junto_mesa"),act("llega",quien="cocinero",a="cocina"),{"wait":500},
  # 1: the mesero asks "¿algo más?"; abuelo looks at the frog and nods; a speaking turn (la cuenta por favor); the mesero brings the slip and abuelo lays bills on the counter (no act named); signed ask on the drawer
  {"dots":1},"c95_mo_buenas_noches",gesto("abuelo","mira",a="coqui"),gesto("abuelo","si"),"c95_cq_cuenta","c95_abo_cuenta",ask("gaveta","c95_donde_cuenta",after=[act("guarda95",donde="gaveta",ok=1)]),
  # 2: abuelo takes two more bills out of his pocket (no act named); signed ask on the jar; thanks; abuela's tip for the cocinero, who bows (her bills go into the jar: no act named)
  {"dots":2},"c95_abo_propina",ask("frasco","c95_donde_propina",after=[act("guarda95",donde="frasco",ok=1)]),"c95_mo_gracias_propina","c95_ab_otra_propina",gesto("cocinero","reverencia"),
  # 3: "¿Todo bien?"; abuelo and Luis are full; Carmen is not; they laugh
  {"dots":3},"c95_mo_todo_bien",gesto("abuelo","barriga"),"c95_abo_todo_bien","c95_l_lleno",gesto("carmen","mira",a="flanes"),"c95_ca_llena"]+juntos(*[gesto(q,"rie") for q in ("abuela","abuelo","luis","carmen")])+[
  # 4: the family goes to the door; the goodbyes; abuela sees the guagua, far off, under the last lamp
  {"dots":4}]+juntos(*[act("llega",quien=q,a="umbral%d"%i) for i,q in enumerate(("abuela","abuelo","luis","carmen"),1)])+["c95_me_hasta_luego","c95_ab_hasta_luego","c95_co_hasta_luego",
  gesto("abuela","mira",a="puerta"),act("guagua",n="lejos"),"c95_ab_guagua",
  # 5: the turn: the last guests come up with folded bills (dealt out of the four); the mesera is putting the chairs up and asks for the register; the family waits in the doorway; the card shows two places ("the frog turns to go": no act named)
  {"reparte":["ga","gb"],"options":GUESTS},
  {"dots":5}]+juntos(act("llega",quien="$ga",a="fila1"),act("llega",quien="$gb",a="fila2"),act("llega",quien="mesera",a="sillas_mesera"))+con(act("sillas95"),"c95_me_caja")+[gesto("abuela","mira",a="puerta"),CARD,{"wait":400},
  # 6: A. 7: B. Which guest, and what the bills are for: drawn afresh each round
  {"dots":6}]+ronda95("a","ga")+[{"dots":7}]+ronda95("b","gb"),
 "final":[{"dots":8}]+juntos(gesto("mesera","saluda"),gesto("mesero","saluda"),gesto("cocinero","saluda"))+["c95_me_adios","c95_cq_adios",   # 8: the frog hops across to the door (no spot named for it: not issued); the three wave; a speaking turn (adiós)
  {"dots":9},baja3(lambda n:act("final95",n=n)),"c95_fin",act("fin")],   # 9: the stop, by where the guagua's lights stood (far; the middle lamp; the stop)
 "leer":["c95_mo_buenas_noches","c95_cq_cuenta","c95_abo_cuenta","c95_donde_cuenta","c95_abo_propina","c95_donde_propina","c95_mo_gracias_propina","c95_ab_otra_propina","c95_mo_todo_bien","c95_abo_todo_bien","c95_l_lleno","c95_ca_llena",
  "c95_me_hasta_luego","c95_ab_hasta_luego","c95_co_hasta_luego","c95_ab_guagua","c95_me_caja","c95_senor_propina","c95_a_senor","c95_mujer_cuenta","c95_b_mujer","c95_me_adios","c95_cq_adios","c95_fin"]}
s95=reuse(s95,{"c95_cq_cuenta":TG(("cuenta",["la cuenta por favor","la cuenta"])),"c95_cq_adios":TG(("adiós",["adiós","adios"]))})
json.dump(s95,open("cuentos/buenas-noches.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files on disk, and the earlier stories of this run). Two words are new in stories of ANOTHER scene of this place, which another generator writes:
# while their files are not on disk they are known (and a NOTE says so); once they are on disk the check is strict.
KNOWN_ELSEWHERE={"para mí":"las-bebidas","delicioso":"mas-y-menos"}
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s93,s94,s95):
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
for st,VARS in ((s93,VARS93),(s94,VARS94),(s95,VARS95)):
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
