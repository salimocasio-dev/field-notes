# Las frutas (place 4, scene 3): stories 42, 43, 44. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/frutas.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene is not built yet: nothing here can be played. The checker (historia/tools/revisa_cuento.py) is the only test.
# Acts are only the ones the script's "Needs" list names (plus the shared marca / ya / fin, the card of rounds and the cost step, as in A comer).
# A beat that has no act in the Needs list is left out (no act invented); the report lists them.
# Run order for the twelve stories of El colmado: gen_mostrador, gen_estantes, gen_frutas, gen_caja (each sees only what was recorded before it).
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
PE=lambda t:D("pepe","Don Pepe",t); AB=lambda t:D("abuela","Abuela",t); SE=lambda t:D("senora","La señora",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's twinkle on a thing he can touch
def act(_n,**k): return dict({"act":_n},**k)
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
ok=lambda:{"if":"ok","then":[act("marca",que="ok")]}
X=[act("marca",que="x"),{"cost":1}]
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story of Las frutas has two scored rounds: the card shows two places
BIG="fruta_a"   # open point: the script says "fruta_a, fruta_b (the two abuela holds, a big one and a small one)" and "`huele` grande: ... (fruta_a)"; fruta_a is the big one, fruta_b the small one
MINE=("la-sopa-de-abuela","esta-bueno","una-libra","cuanto-es","caro-y-barato","el-cambio")   # this generator's stories and the ones after them: not seen
# a clip whose text and speaker are already recorded under another id keeps that id (nothing is recorded twice). Ties go to the id most used, then to the earliest story of the course.
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
DIN=set()   # ids that are put together in the story ("c42_ab_dame_$ka"): never renamed
def strs(o):   # every string in the steps (not the keys)
    if isinstance(o,str): yield o
    elif isinstance(o,list):
        for x in o: yield from strs(x)
    elif isinstance(o,dict):
        for x in o.values(): yield from strs(x)
def reuse(st,turns):
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
    # Speaking turns: one entry per target; "palabra" is the word as it is in an earlier story's focus_words; "formas" are the script's own. The mark goes on the clip once its id is settled.
    played=set(strs([out["beats"],out["final"]]))
    for cid,t in turns.items():
        fid=ren.get(cid,cid)
        if fid in out["clips"] and fid in played: out["clips"][fid]["tu_turno"]=t
        else: print("MISSING TURN LINE",out["id"],cid)
    for cid,cl in out["clips"].items(): ex_add(cid,cl)    # the next story of this run reuses this one's lines
    return out
TG=lambda *p:[{"palabra":w,"formas":list(f)} for w,f in p]
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!"),"abuela":N("Esta es abuela.")}
BASE={"coqui":"yo_coqui","abuela":"abuela"}   # the free poke lines of people already recorded; Don Pepe, the goat and the things are new: nothing added

# ---------------- 42. La sopa de abuela ----------------
c=dict(comunes)
c.update({"c42_pepe_buenos_dias":PE("¡Buenos días!"),"c42_cq_buenos_dias":T("¡Buenos días, don Pepe!"),"c42_ab_compra_sopa":N("Abuela compra las cosas para la sopa."),
 "c42_pepe_aqui_tc":PE("Aquí hay tomates. Y aquí hay cebollas."),"c42_ab_necesito_tomate":AB("Necesito un tomate."),"c42_donde_tomates":N("¿Dónde están los tomates?"),"c42_ab_compra_tomate":N("Abuela compra un tomate."),
 "c42_pepe_algo_mas":PE("¿Algo más?"),"c42_ab_si_cebolla":AB("Sí. Una cebolla, por favor."),"c42_toca_cebollas":N("Toca las cebollas."),"c42_ab_compra_cebolla":N("Abuela compra una cebolla."),
 "c42_ab_si_pp":AB("Sí. Necesito papas y plátanos."),"c42_pepe_aqui_pp":PE("Aquí hay papas. Y aquí hay plátanos."),
 "c42_cabra_platano":N("¡Ay! La cabra se come un plátano."),"c42_pepe_no_para_ti":PE("¡No! Las papas y los plátanos no son para ti."),
 "c42_ab_dame_papas":AB("Coquí, dame una papa."),"c42_ab_dame_platanos":AB("Coquí, dame un plátano."),
 "c42_ab_compra_papas":N("Abuela compra una papa."),"c42_ab_compra_platanos":N("Abuela compra un plátano."),
 "c42_no_papas":N("No, Coquí. Mira. Estas son las papas."),"c42_no_platanos":N("No, Coquí. Mira. Estos son los plátanos."),
 "c42_ab_tienes_hambre":AB("Coquí, ¿tienes hambre?"),"c42_cq_tengo_hambre":T("¡Sí, tengo hambre!"),
 "c42_ab_dos_guineos":N("Abuela compra dos guineos."),"c42_ab_un_guineo":N("Abuela compra un guineo."),"cq_gracias_abuela":T("¡Gracias, abuela!"),
 "c42_ab_adios":AB("¡Adiós, don Pepe! Vamos a casa, Coquí.")})   # cq_gracias_abuela is recorded already
DIN.update(["c42_ab_dame_papas","c42_ab_dame_platanos","c42_ab_compra_papas","c42_ab_compra_platanos","c42_no_papas","c42_no_platanos"])
def ronda42(v):   # the soup takes one more papa or plátano: abuela asks for one (drawn afresh); he touches the bin. Tests the word asked.
    return [{"draw":v,"options":["papas","platanos"]},
     {"decide":"do","options":["papas","platanos"],"pick":"$"+v,"tests":"$"+v,"lock":True,"lead":[],"line":"c42_ab_dame_$"+v,
      "right":[act("tira",k="$"+v,ok=1),"c42_ab_compra_$"+v,ok()],
      "wrong":[act("tira",k="$x",ok=0)]+X+["c42_no_$"+v]}]
def dos_cestos(a,b,linea):   # don Pepe lays a hand on two bins, each twinkles; then he says what is in them
    return [act("mano",k=a),tw(a),{"wait":450},act("mano",k=b),tw(b),linea,tw(None)]
s42={"id":"la-sopa-de-abuela","title":"La sopa de abuela","place":"El colmado","scene":"frutas","next":"esta-bueno",
 "goal":"Buy the four things for abuela's soup, and keep the coins for her guineos.","stake":{"thing":"monedas","steps":2},"dots":9,"bien":"si_muy_bien",
 "focus_words":["tomate","cebolla","papa","plátano"],"formas_foco":{"tomate":["tomates"],"cebolla":["cebollas"],"papa":["papas"],"plátano":["plátanos"]},
 "back_again":["necesito","compra","dame","tira","coge","buenos días","tengo hambre","guineo","come","hay","aquí","por favor","¿algo más?"],
 "also_heard":["sopa","cabra"],"names":BASE,"palabras":{"papas":"papa","platanos":"plátano"},"clips":c,
 "beats":[act("piensa",quien="coqui",k="guineo"),{"dots":1},"c42_pepe_buenos_dias","c42_cq_buenos_dias",act("piensa",quien="abuela",k="sopa"),"c42_ab_compra_sopa",act("monedas",n=6),
  # the opening: two signed touches
  {"dots":2}]+dos_cestos("tomates","cebollas","c42_pepe_aqui_tc")+[act("lista",k="tomates",hecho=0),"c42_ab_necesito_tomate",
  ask("tomates","c42_donde_tomates",after=[act("tira",k="tomates",ok=1)],then=["c42_ab_compra_tomate",act("lista",k="tomates",hecho=1)]),
  {"dots":3},"c42_pepe_algo_mas",act("lista",k="cebollas",hecho=0),"c42_ab_si_cebolla",
  ask("cebollas","c42_toca_cebollas",after=[act("tira",k="cebollas",ok=1)],then=["c42_ab_compra_cebolla",act("lista",k="cebollas",hecho=1)]),
  {"dots":4},"c42_pepe_algo_mas","c42_ab_si_pp"]+dos_cestos("papas","platanos","c42_pepe_aqui_pp")+[
  # the turn: the goat takes a plátano; abuela puts her list away; the card shows two places
  {"dots":5},act("cabra",que="roba"),act("cabra",que="mastica"),"c42_cabra_platano",act("aparta42"),"c42_pepe_no_para_ti",act("abuela",a="junto_cabra",que="guarda"),CARD,{"wait":400},
  # A and B: touch a bin (papas or plátanos), drawn afresh each round
  {"dots":6}]+ronda42("ka")+[{"dots":7}]+ronda42("kb"),
 "final":[{"dots":8},act("abuela",que="monedas"),"c42_ab_tienes_hambre","c42_cq_tengo_hambre",
  {"if":"lost=0","then":["c42_ab_dos_guineos",act("guineos",n=2),"cq_gracias_abuela"],
   "else":[{"if":"lost=1","then":["c42_ab_un_guineo",act("guineos",n=1),"cq_gracias_abuela"],"else":[act("guineos",n=0)]}]},
  {"dots":9},"c42_ab_adios",act("fin")],
 "leer":["c42_pepe_buenos_dias","c42_cq_buenos_dias","c42_ab_compra_sopa","c42_pepe_aqui_tc","c42_ab_necesito_tomate","c42_donde_tomates","c42_ab_compra_tomate","c42_pepe_algo_mas","c42_ab_si_cebolla","c42_toca_cebollas","c42_ab_compra_cebolla",
  "c42_ab_si_pp","c42_pepe_aqui_pp","c42_cabra_platano","c42_pepe_no_para_ti","c42_ab_dame_papas","c42_ab_compra_papas","c42_ab_dame_platanos","c42_ab_compra_platanos","c42_ab_tienes_hambre","c42_cq_tengo_hambre","c42_ab_dos_guineos","cq_gracias_abuela","c42_ab_adios"]}
T42={"c42_cq_buenos_dias":TG(("buenos días",["buenos días","buenos dias"])),"c42_cq_tengo_hambre":TG(("tengo hambre",["tengo hambre"]))}
s42=reuse(s42,T42)
json.dump(s42,open("cuentos/la-sopa-de-abuela.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 43. ¿Está bueno? ----------------
c=dict(comunes)
FO=AB("¡Fo!")   # also in 44
c.update({"c43_ab_necesito_fruta":AB("Necesito fruta."),"c43_pepe_aqui_aguacates":PE("Aquí hay aguacates."),"c43_pepe_aguacate_bueno":PE("¡Mira! Este aguacate está bueno."),"c43_pepe_te_gusta":PE("¿Te gusta el aguacate?"),
 "c43_cq_me_gusta":T("¡Sí, me gusta!"),"c43_pepe_aguacate_malo":PE("¡Fo! Este aguacate está malo."),"c43_aguacate_malo_cabra":N("El aguacate malo es para la cabra."),
 "c43_ab_tiene_limones":AB("¿Tiene limones?"),"c43_pepe_si_limones":PE("Sí. Aquí hay limones."),"c43_ab_limon_gp":AB("El limón grande está bueno. El limón pequeño está malo."),
 "c43_donde_limon_bueno":N("¿Dónde está el limón bueno?"),"c43_limon_malo_cabra":N("El limón malo es para la cabra."),
 "c43_ab_mira_pinas":AB("¡Mira, Coquí! Piñas."),"c43_senora_cuanto":SE("¡Don Pepe! ¿Cuánto es?"),"c43_pepe_espere":PE("¡Espere, por favor!"),
 "c43_ab_fo":FO,"c43_no_aguacate":N("No, Coquí. Mira. Este aguacate está malo."),"c43_no_pina":N("No, Coquí. Mira. Esta piña está mala."),
 "c43_pepe_que_compra":PE("¿Qué compra tu abuela?"),"c43_cq_fruta":T("Abuela compra fruta."),
 "c43_ab_tiene_todo":N("Abuela tiene un limón, un aguacate y una piña. ¡La fruta está buena!"),"c43_ab_no_limon":AB("¡Ay! No hay limón."),"c43_ab_no_aguacate":AB("¡Ay! No hay aguacate."),
 "c43_ab_adios":AB("¡Adiós, don Pepe!")})
for t,tx in (("grande","grande"),("pequeno","pequeño")):
    for w in ("bueno","malo"):
        c["c43_ag_%s_%s"%(t,w)]=AB("El aguacate %s está %s."%(tx,w)); DIN.add("c43_ag_%s_%s"%(t,w))
        c["c43_pi_%s_%s"%(t,w)]=AB("La piña %s está %s."%("grande" if t=="grande" else "pequeña","buena" if w=="bueno" else "mala")); DIN.add("c43_pi_%s_%s"%(t,w))
DIN.update(["c43_no_aguacate","c43_no_pina"])
def ronda43(g,h,w,n,t,kind,pl,k,m):
    # g: the good fruit (fruta_a or fruta_b), h: the other; w: the word of the line (bueno or malo), drawn; n: the fruit the line is about (the good one if the line says bueno, the other if it says malo); t: its size word
    # four lines: grande/pequeño x bueno/malo, each true of what abuela holds; he touches the good one
    return [{"draw":g,"options":["fruta_a","fruta_b"],"other":h},{"draw":w,"options":["bueno","malo"]},
     {"calc":n,"cond":w+"=bueno","then":"$"+g,"else":"$"+h},{"calc":t,"cond":n+"="+BIG,"then":"grande","else":"pequeno"},
     act("huele",k=k,grande=BIG),
     {"decide":"do","options":["fruta_a","fruta_b"],"pick":"$"+g,"tests":"$"+w,"lock":True,"lead":[],"line":"c43_%s_$%s_$%s"%(pl,t,w),
      "right":[act("pone43",cual="$"+g,ok=1),{"if":"ok","then":[act("suelta",quien="abuela",que="otra"),act("cabra",que="come"),act("marca",que="ok")]}],
      "wrong":[act("pone43",cual="$x",ok=0)]+X+["c43_ab_fo","c43_no_"+kind,act("suelta",quien="abuela",que="ambas"),act("cabra",que="come")]},
     {"calc":m,"cond":"ok","then":"bien","else":"mal"}]
s43={"id":"esta-bueno","title":"¿Está bueno?","place":"El colmado","scene":"frutas","next":"una-libra",
 "goal":"Fill abuela's basket with good fruit only: a bad one spoils the one beside it.","stake":{"thing":"fruta","steps":2},"dots":8,"bien":"si_muy_bien",
 "focus_words":["aguacate","piña","limón","bueno","malo"],"formas_foco":{"aguacate":["aguacates"],"piña":["piñas"],"limón":["limones"],"bueno":["buena"],"malo":["mala"]},
 "back_again":["grande","pequeño","fruta","compra","necesito","me gusta","fo","mira","¿tiene…?","no hay"],
 "also_heard":["te gusta","¿cuánto es?","espere","canasta"],"names":BASE,"palabras":{},"clips":c,
 "beats":[{"dots":1},"c43_ab_necesito_fruta",act("mano",k="aguacates"),"c43_pepe_aqui_aguacates",act("corta",k="aguacates",bueno=1),"c43_pepe_aguacate_bueno",act("prueba43"),"c43_pepe_te_gusta","c43_cq_me_gusta",
  {"dots":2},act("corta",k="aguacates",bueno=0),"c43_pepe_aguacate_malo",act("suelta",quien="pepe",que="aguacate"),act("cabra",que="come"),"c43_aguacate_malo_cabra",
  # the opening: one signed touch (the big lemon is the good one)
  {"dots":3},"c43_ab_tiene_limones","c43_pepe_si_limones",act("huele",k="limones",grande=BIG),"c43_ab_limon_gp",
  ask(BIG,"c43_donde_limon_bueno",after=[act("pone43",cual=BIG,ok=1)],then=[act("suelta",quien="abuela",que="limon"),act("cabra",que="come"),"c43_limon_malo_cabra"]),
  # the turn: nobody can cut a fruit open now; the card shows two places
  {"dots":4},tw("pinas"),"c43_ab_mira_pinas",tw(None),act("llama43"),"c43_senora_cuanto",act("sale",quien="pepe",a="tienda"),"c43_pepe_espere",CARD,{"wait":400},
  # A: two aguacates. B: two piñas. Which one is good, and which of the four lines, is drawn afresh each round
  {"dots":5}]+ronda43("ga","ha","wa","na","ta","aguacate","ag","aguacates","ma")+[{"dots":6}]+ronda43("gb","hb","wb","nb","tb","pina","pi","pinas","mb"),
 "final":[{"dots":7},act("vuelve",quien="pepe",a="tienda"),"c43_pepe_que_compra","c43_cq_fruta",act("canasta43"),
  {"if":"lost=0","then":["c43_ab_tiene_todo"],
   "else":[{"if":"ma=mal","then":["c43_ab_no_limon"]},{"if":"mb=mal","then":["c43_ab_no_aguacate"]}]},
  {"dots":8},"c43_ab_adios",act("cabra",que="mastica"),act("fin")],
 "leer":["c43_ab_necesito_fruta","c43_pepe_aqui_aguacates","c43_pepe_aguacate_bueno","c43_pepe_te_gusta","c43_cq_me_gusta","c43_pepe_aguacate_malo","c43_aguacate_malo_cabra","c43_ab_tiene_limones","c43_pepe_si_limones","c43_ab_limon_gp","c43_donde_limon_bueno","c43_limon_malo_cabra",
  "c43_ab_mira_pinas","c43_senora_cuanto","c43_pepe_espere","c43_ag_grande_bueno","c43_pi_grande_malo","c43_pepe_que_compra","c43_cq_fruta","c43_ab_tiene_todo","c43_ab_adios"]}
T43={"c43_cq_me_gusta":TG(("me gusta",["me gusta"])),"c43_cq_fruta":TG(("fruta",["fruta"]))}
s43=reuse(s43,T43)
json.dump(s43,open("cuentos/esta-bueno.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 44. Una libra ----------------
c=dict(comunes)
c.update({"c44_pepe_frescos":PE("¡Buenos días! ¡Mira! ¡Tomates frescos! ¡Cebollas frescas!"),"c44_tomates_malos":N("Y estos tomates están malos."),"c44_donde_tomates_frescos":N("¿Dónde están los tomates frescos?"),
 "c44_ab_tiene_limones_frescos":AB("¿Tiene limones frescos?"),"c44_pepe_toma":PE("Sí. Toma, Coquí. Un limón fresco."),"c44_cq_gracias_pepe":T("¡Gracias, don Pepe!"),
 "c44_ab_media_libra":AB("Media libra, por favor."),"c44_pepe_media_limones":PE("Media libra de limones."),"c44_pepe_una_libra":PE("Y esto es una libra."),"c44_ab_compra_media_limones":N("Abuela compra media libra de limones."),
 "c44_ab_necesito":AB("Necesito una libra de tomates y una libra de cebollas. Para la sopa."),"c44_pepe_ojo":PE("Coquí, ¡ojo con la cabra!"),
 "c43_ab_fo":FO,"c44_ab_vamos":AB("¡Vamos, Coquí! Voy a hacer la sopa."),"c44_cq_hambre":T("¡Tengo hambre!")})   # c44_cq_hambre is recorded already (La cocina's tengo hambre)
KIND={"tomates":("Los tomates %s son para %s.","Estos tomates están %s.",{"fresco":"frescos","malo":"malos"},{"fresco":"la sopa","malo":"la cabra"}),
      "cebollas":("Las cebollas %s son para %s.","Estas cebollas están %s.",{"fresco":"frescas","malo":"malas"},{"fresco":"la sopa","malo":"la cabra"})}
for k,(ln,no,adj,para) in KIND.items():
    for w in ("fresco","malo"):
        c["c44_ab_%s_%s"%(k,w)]=AB(ln%(adj[w],para[w])); c["c44_no_%s_%s"%(k,w)]=N("No, Coquí. Mira. "+no%adj[w]); DIN.update(["c44_ab_%s_%s"%(k,w),"c44_no_%s_%s"%(k,w)])
    c["c44_libra_%s_una"%k]=N("Una libra de %s."%k); c["c44_libra_%s_media"%k]=N("Media libra de %s."%k)
for ua in ("una","media"):
    for ub in ("una","media"):
        c["c44_fin_%s_%s"%(ua,ub)]=N("Abuela compra %s libra de tomates y %s libra de cebollas."%(ua,ub)); DIN.add("c44_fin_%s_%s"%(ua,ub))
def ronda44(l,o,w,p,u,k):
    # l: the side of the fresh crate (a or b), o: the other side; w: the word of the line (fresco or malo), drawn; p: the crate he touches (the fresh one for fresco, yesterday's for malo)
    return [{"draw":l,"options":["a","b"],"other":o},{"draw":w,"options":["fresco","malo"]},
     {"calc":p,"cond":w+"=fresco","then":"cajon_$"+l,"else":"cajon_$"+o},
     act("cajones",k=k,lado="$"+l),
     {"decide":"do","options":["cajon_a","cajon_b"],"pick":"$"+p,"tests":"$"+w,"lock":True,"lead":[],"line":"c44_ab_%s_$%s"%(k,w),
      "right":[{"if":w+"=malo","then":[act("empuja44",cual="$"+p),act("cabra",que="caja")]},
               {"if":"ok","then":[act("pesa",k=k,n=1),"c44_libra_%s_una"%k,ok()],"else":[act("pesa",k=k,n=0.5),"c44_libra_%s_media"%k]}],
      "wrong":[{"if":w+"=fresco","then":[act("vuelca44",k=k),act("cabra",que="come"),"c43_ab_fo"],"else":[act("empuja44",cual="$x"),act("cabra",que="caja")]}]+X+["c44_no_%s_$%s"%(k,w)]},
     {"calc":u,"cond":"ok","then":"una","else":"media"}]
s44={"id":"una-libra","title":"Una libra","place":"El colmado","scene":"frutas","next":"cuanto-es",
 "goal":"Get a pound of fresh tomatoes and a pound of fresh onions for abuela's soup: a wrong move feeds half a crate to the goat.","stake":{"thing":"frescos","steps":2},"dots":9,"bien":"si_muy_bien",
 "focus_words":["libra","medio","fresco"],"formas_foco":{"medio":["media"],"fresco":["frescos","frescas"]},
 "back_again":["tomate","cebolla","limón","malo","necesito","para","buenos días","compra","gracias","tengo hambre"],
 "also_heard":["sopa","cabra","ojo con","voy a hacer"],"names":BASE,"palabras":{},"clips":c,
 "beats":[{"set":{"camion":1}},{"dots":1},act("cajones",k="tomates",lado="a"),tw("cajon_a"),"c44_pepe_frescos",tw(None),act("ayer44",k="tomates"),"c44_tomates_malos",
  # the opening: one signed touch (the fresh tomatoes)
  ask("cajon_a","c44_donde_tomates_frescos"),
  {"dots":2},"c44_ab_tiene_limones_frescos",act("limon44"),"c44_pepe_toma","c44_cq_gracias_pepe",
  {"dots":3},"c44_ab_media_libra",act("pesa",k="limones",n=0.5),act("marca44",que="medio"),"c44_pepe_media_limones",act("marca44",que="libra"),"c44_pepe_una_libra","c44_ab_compra_media_limones",
  {"dots":4},act("abuela",que="lista"),"c44_ab_necesito",
  # the turn: don Pepe goes to move his truck; abuela looks into her purse; the card shows two places
  {"dots":5},act("sale",quien="pepe",a="camion"),"c44_pepe_ojo",act("abuela",que="monedero"),CARD,{"wait":400},
  # A: the tomatoes. B: the onions. Which side the fresh crate is on, and which of the two lines, is drawn afresh each round
  {"dots":6}]+ronda44("la","oa","wa","pa","ua","tomates")+[{"dots":7}]+ronda44("lb","ob","wb","pb","ub","cebollas"),
 "final":[{"dots":8},act("vuelve",quien="pepe",a="camion"),act("bolsas44"),"c44_fin_$ua_$ub",
  {"dots":9},"c44_ab_vamos","c44_cq_hambre",act("fin")],
 "leer":["c44_pepe_frescos","c44_tomates_malos","c44_donde_tomates_frescos","c44_ab_tiene_limones_frescos","c44_pepe_toma","c44_cq_gracias_pepe","c44_ab_media_libra","c44_pepe_media_limones","c44_pepe_una_libra","c44_ab_compra_media_limones","c44_ab_necesito","c44_pepe_ojo",
  "c44_ab_tomates_fresco","c44_libra_tomates_una","c44_ab_cebollas_malo","c44_libra_cebollas_una","c44_fin_una_una","c44_ab_vamos","c44_cq_hambre"]}
T44={"c44_cq_gracias_pepe":TG(("gracias",["gracias"])),"c44_cq_hambre":TG(("tengo hambre",["tengo hambre"]))}
s44=reuse(s44,T44)
json.dump(s44,open("cuentos/una-libra.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files here, A comer's generator, and the earlier stories of this place)
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words",[]))
for m in re.findall(r'"focus_words":(\[[^\]]*\])',open("tools/gen_comer.py",encoding="utf-8").read()): EARLIER.update(json.loads(m))
EARLIER.update(["colmado","buenos días","necesito","aquí tiene","¿tiene…?","¿algo más?","bolsa","compra","esto","eso","vende","buenas tardes","lata","botella","caja","¿cuántos?","cuatro","cinco","seis","siete","ocho","nueve","diez","otro"])   # stories 36 to 41 (in cuentos/ too)
for st in (s42,s43,s44):
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno",[]):
            if t["palabra"] not in EARLIER: print("TURN ON A WORD IN NO EARLIER FOCUS_WORDS",st["id"],cid,t["palabra"])
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
for st in (s42,s43,s44):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:42|43|44|26)_|cq_|si_|muy_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    print(st["id"],":",len(st["clips"]),"clips,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
