# El mostrador (place 4, El colmado, scene 1): stories 36, 37, 38. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/mostrador.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `mostrador` is not built yet: the acts, things, spots and views used here are the script's "Needs" list, nothing else (plus the acts every scene has: marca, ya, fin, ir).
# Run order for the twelve stories of El colmado: gen_mostrador, gen_estantes, gen_frutas, gen_caja (each sees only what was recorded before it).
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); AB=lambda t:D("abuela","Abuela",t)
PE=lambda t:D("pepe","Don Pepe",t); SE=lambda t:D("senora","La señora",t); SO=lambda t:D("senor","El señor",t)
NI=lambda t:{"who":"narr","habla":"ninos","text":"Los niños dicen: "+t}          # plural: "dicen"
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's twinkle on a thing he can touch
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
ok=lambda:{"if":"ok","then":[act("marca",que="ok")]}                          # the star: only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}                        # every story of El colmado has two scored rounds: the card shows two places
MINE=("el-colmado","algo-mas","esto-y-eso","latas-y-botellas","siete-latas","diez-botellas","la-sopa-de-abuela","esta-bueno","una-libra","cuanto-es","caro-y-barato","el-cambio")   # this run and the ones after it: not seen
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
DIN=set()   # ids that are put together in the story ("c36_a_t_$ha_n_$na"): never renamed
def reuse(st):
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
    out=turnos(fx(st),ren)
    for cid,cl in out["clips"].items(): ex_add(cid,cl)    # the next story of this run reuses this one's lines
    return out
# Speaking turns (docs/hablar/03-para-historias-nuevas.md). A coquí clip with "tu_turno" is his turn. Targets and forms are the script's own: "[TURN: sí (sí, si)]" is the word "sí" with the forms "sí" and "si".
# The mark is put on the clip once its id is settled. A turn whose clip is not in the story, or is never played in it, is reported (MISSING TURN LINE) and not made up.
TG=lambda *p:[{"palabra":w,"formas":list(f)} for w,f in p]
TURNOS={"el-colmado":{"c36_cq_me_llamo":TG(("me llamo",["me llamo"])),                       # step 3 (set up by "¿Quién eres tú?")
                      "c36_cq_si_por_favor":TG(("sí",["sí","si"])),                           # step 10 ("¿Quieres un quesito, Coquí?"): a turn on sí only
                      "c36_cq_adios_pepe":TG(("adiós",["adiós","adios"]))},                   # step 11 ("¡Hasta mañana!")
        "algo-mas":{"c37_cq_luis_casa":TG(("casa",["casa"])),                                 # step 1 ("¿Dónde está Luis?")
                    "c37_cq_bien":TG(("bien",["bien"]))},                                     # step 6 ("¿Cómo estás?")
        "esto-y-eso":{"c38_cq_gracias":TG(("gracias",["gracias"])),                           # step 2 (the signed ask "toma eso")
                      "c38_cq_si_quiero":TG(("sí",["sí","si"]),("quiero",["quiero"]))}}      # step 4 ("¿quieres vender?")
def turnos(st,ren):
    def strs(o):   # every string in the steps (not the keys)
        if isinstance(o,str): yield o
        elif isinstance(o,list):
            for x in o: yield from strs(x)
        elif isinstance(o,dict):
            for x in o.values(): yield from strs(x)
    played=set(strs([st["beats"],st["final"]]))
    for cid,t in TURNOS.get(st["id"],{}).items():
        cid=ren.get(cid,cid)
        if cid in st["clips"] and cid in played: st["clips"][cid]["tu_turno"]=t
        else: print("MISSING TURN LINE",st["id"],cid)
    return st
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}
AQUI=("c36_cq_aqui_tiene",T("¡Aquí tiene!"))   # the frog's "¡Aquí tiene!": new in 36, shared with 38
# What he hears when he pokes a person already recorded (the new things add nothing: don Pepe, the children, the goods, the cart, the freezer)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora."))}
def nombres(*ks):
    return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}

# ---------------- 36. El colmado ----------------
POOL=["cafe","arroz","azucar"]; ES={"cafe":"café","arroz":"arroz","azucar":"azúcar"}   # the things the two customers may name: one place to change (each pair is one clip per customer)
c=dict(comunes); nm,nc=nombres("abuela","coqui","senora","senor"); c.update(nc); c[AQUI[0]]=AQUI[1]
c.update({"c36_van":N("Abuela y Coquí van al colmado."),"c36_mira":N("Mira. Este es el colmado de don Pepe."),"c36_donde_colmado":N("¿Dónde está el colmado?"),
 "c36_pepe_dias":PE("¡Buenos días!"),"c36_ab_dias":AB("¡Buenos días, don Pepe!"),"c36_pepe_quien":PE("¿Y tú? ¿Quién eres tú?"),"c36_cq_me_llamo":T("Me llamo Coquí."),
 "c36_ab_nec_leche":AB("Necesito leche, por favor."),"c36_donde_leche":N("¿Dónde está la leche?"),"c36_pepe_aqui":PE("Aquí tiene."),
 "c36_ab_nec_pan":AB("Y necesito pan."),"c36_toca_pan":N("Toca el pan."),"c36_ab_nec_mant":AB("Y necesito mantequilla."),"c36_pepe_no_hay":PE("Ay, aquí no hay. ¡Espere!"),
 "c36_ab_se_sienta":N("Abuela se sienta."),"c36_sra_dias":SE("¡Buenos días!"),"c36_cq_dias_sra":T("¡Buenos días, señora!"),"c36_sro_dias":SO("¡Buenos días!"),
 "c36_pepe_mant":PE("¡La mantequilla! Aquí tiene."),"c36_ab_quesito":AB("¿Quieres un quesito, Coquí?"),"c36_cq_si_por_favor":T("¡Sí, por favor!"),"c36_cq_mmm":T("¡Mmm! ¡Qué rico!"),
 "c36_pepe_gracias":PE("¡Gracias! ¡Hasta mañana!"),"c36_cq_adios_pepe":T("¡Adiós, don Pepe!"),"c36_van_casa":N("Abuela y Coquí van para la casa.")})
CLIENTE={"a":("senora",SE),"b":("senor",SO)}
for p,(_,F) in CLIENTE.items():
    for h in POOL:
        for n in POOL:
            if h==n: continue
            for i,t in (("c36_%s_t_%s_n_%s"%(p,h,n),"Tengo %s. Necesito %s."%(ES[h],ES[n])),("c36_%s_n_%s_t_%s"%(p,n,h),"Necesito %s. Tengo %s."%(ES[n],ES[h])),
                        ("c36_%s_no_%s_%s"%(p,h,n),"No, Coquí. Tengo %s. Necesito %s."%(ES[h],ES[n]))):
                c[i]=F(t); DIN.add(i)
def ronda36(p):
    # Each customer names two things: the one already in the shut basket (h) and the one she needs (n). Which two, which is said first, which side each stands on: drawn afresh each round.
    cu=CLIENTE[p][0]; n,h,o,s,l="n"+p,"h"+p,"o"+p,"s"+p,"l"+p
    return [{"reparte":[n,h],"options":POOL},{"draw":o,"options":["1","2"]},{"draw":s,"options":["1","2"]},
     {"calc":l,"cond":o+"=1","then":"c36_%s_t_$%s_n_$%s"%(p,h,n),"else":"c36_%s_n_$%s_t_$%s"%(p,n,h)},
     {"if":s+"=1","then":[act("pon2",a="$"+n,b="$"+h)],"else":[act("pon2",a="$"+h,b="$"+n)]},
     {"decide":"do","options":["$"+n,"$"+h],"pick":"$"+n,"tests":"necesito","lock":True,"lead":[],"line":"$"+l,
      "right":[act("sirve",k="$"+n,a=cu),AQUI[0],act("paga",quien=cu,n=1),act("sale",quien=cu,por="puerta"),ok()],
      "wrong":[act("sirve",k="$x",a=cu),gesto(cu,"no"),act("cesta",quien=cu,k="$x"),act("marca",que="x"),"c36_%s_no_$%s_$%s"%(p,h,n),act("bandeja",que="quita"),{"cost":1}]}]
s36={"id":"el-colmado","title":"El colmado","place":"El colmado","scene":"mostrador","next":"algo-mas",
 "goal":"Serve don Pepe's two customers what they need, and keep the warm quesitos for abuela and the frog.","stake":{"thing":"quesitos","steps":2},"dots":7,"bien":"si_muy_bien",
 "focus_words":["colmado","buenos días","necesito","aquí tiene"],"formas_foco":{},
 "back_again":["leche","pan","mantequilla","queso","café","arroz","azúcar","jugo","habichuelas","tengo","señora","señor","por favor","gracias","espera","no hay","huele","me llamo","se sienta"],
 "also_heard":["espere","quesito"],"names":nm,"clips":c,
 "beats":[{"set":{"hora":"manana","puerta":"shut","atras":"shut"}},{"cam":"calle","n":1},act("lista"),{"wait":500},
  # 1: the rooster, the shop twinkles
  act("gallo"),"c36_van",tw("colmado"),"c36_mira",tw(None),
  # 2 and 3: the opening, signed; they go in; don Pepe greets them and asks the frog's name (a speaking turn)
  {"dots":1},ask("colmado","c36_donde_colmado",after=[{"set":{"puerta":"open"}},{"cam":"dentro","n":1},act("entra",quien="abuela"),act("entra",quien="coqui")],
                 then=[gesto("pepe","saluda"),gesto("abuela","mira",a="quesitos"),gesto("coqui","mira",a="quesitos"),act("piensa",quien="coqui",k="quesito"),
                       "c36_pepe_dias","c36_ab_dias",gesto("pepe","agacha"),"c36_pepe_quien","c36_cq_me_llamo"]),
  # 4 to 6: the list, three things; the butter is not there
  {"dots":2},gesto("abuela","lista"),act("lista",k="leche",hecho=0),"c36_ab_nec_leche",
  ask("leche","c36_donde_leche",after=[act("baja",k="leche"),"c36_pepe_aqui"],then=[act("guarda",quien="abuela",k="leche"),act("lista",k="leche",hecho=1)]),
  {"dots":3},act("lista",k="pan",hecho=0),"c36_ab_nec_pan",
  ask("pan","c36_toca_pan",after=[act("baja",k="pan"),"c36_pepe_aqui"],then=[act("guarda",quien="abuela",k="pan"),act("lista",k="pan",hecho=1)]),
  act("lista",k="mantequilla",hecho=0),"c36_ab_nec_mant",act("nohay",k="mantequilla"),"c36_pepe_no_hay",
  # 7: the turn. Don Pepe leaves the tray with them and goes out at the back; the frog on the counter; the two customers come in
  {"dots":4},act("bandeja",que="da"),{"set":{"atras":"open"}},act("sale",quien="pepe",por="atras"),{"set":{"atras":"shut"}},act("abanico",quien="abuela"),"c36_ab_se_sienta",act("ir",a="mostrador_izq"),
  act("entra",quien="senora"),act("entra",quien="senor"),"c36_sra_dias","c36_cq_dias_sra",CARD,{"wait":400},
  # A: the señora. B: the señor
  {"dots":5}]+ronda36("a")+[{"dots":6},"c36_sro_dias"]+ronda36("b"),
 "final":[{"dots":7},act("trae",k="mantequilla"),"c36_pepe_mant",act("lista",k="mantequilla",hecho=1),gesto("pepe","mira",a="plato"),gesto("pepe","mira",a="bandeja"),"c36_ab_quesito","c36_cq_si_por_favor",
  {"if":"lost=0","then":[act("bandeja",que="comen",n=3),"c36_cq_mmm"],
   "else":[{"if":"lost=1","then":[act("bandeja",que="comen",n=2),"c36_cq_mmm"],"else":[act("bandeja",que="comen",n=1)]}]},
  "c36_pepe_gracias","c36_cq_adios_pepe",act("sale",quien="abuela",por="puerta"),act("sale",quien="coqui",por="puerta"),"c36_van_casa",act("fin")],
 "leer":["c36_van","c36_mira","c36_donde_colmado","c36_pepe_dias","c36_ab_dias","c36_pepe_quien","c36_cq_me_llamo","c36_ab_nec_leche","c36_donde_leche","c36_pepe_aqui","c36_ab_nec_pan","c36_toca_pan","c36_pepe_aqui","c36_ab_nec_mant","c36_pepe_no_hay",
  "c36_ab_se_sienta","c36_sra_dias","c36_cq_dias_sra","c36_a_t_cafe_n_arroz",AQUI[0],"c36_sro_dias","c36_b_n_azucar_t_cafe",AQUI[0],"c36_pepe_mant","c36_ab_quesito","c36_cq_si_por_favor","c36_cq_mmm","c36_pepe_gracias","c36_cq_adios_pepe","c36_van_casa"]}
s36=reuse(s36)
json.dump(s36,open("cuentos/el-colmado.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 37. ¿Algo más? ----------------
c=dict(comunes); nm,nc=nombres("carmen","coqui","senora"); c.update(nc)
c.update({"c37_estan":N("Carmen y Coquí están en el colmado."),"c37_ca_dias":CA("¡Buenos días, don Pepe!"),"c37_pepe_dias_luis":PE("¡Buenos días! ¿Dónde está Luis?"),"c37_cq_luis_casa":T("Luis está en casa."),
 "c37_ca_compra3":N("Carmen compra tres cosas para abuela."),"c37_ca_tiene_queso":CA("¿Tiene queso?"),"c37_donde_queso":N("¿Dónde está el queso?"),"c37_pepe_si_tienes":PE("Sí. Aquí tienes."),"c37_ca_compra_queso":N("Carmen compra queso."),
 "c37_pepe_algo_mas":PE("¿Algo más?"),"c37_ca_si_cafe":CA("Sí. ¿Tiene café?"),"c37_toca_cafe":N("Toca el café."),"c37_ca_si_azucar":CA("Sí. ¿Tiene azúcar?"),"c37_toca_azucar":N("Toca el azúcar."),
 "c37_ca_no_gracias":CA("No, gracias."),"c37_ca_tiene_bolsa":N("Carmen tiene una bolsa."),"c37_en_la_bolsa":N("El queso, el café y el azúcar van en la bolsa."),"c37_donde_bolsa":N("¿Dónde está la bolsa?"),
 "c37_sra_hola":SE("¡Hola, Coquí! ¿Cómo estás?"),"c37_cq_bien":T("¡Bien, gracias!"),"c37_sra_nec_pan":SE("Necesito pan."),"c37_pepe_aqui_bolsa":PE("Aquí tiene. ¿Tiene bolsa?"),"c37_sra_no_bolsa":SE("No. No tengo bolsa."),
 "c37_pepe_tienes_bolsa":PE("¿Tienes bolsa?"),"c37_cq_no_gracias":T("No, gracias."),"c37_cq_no":T("No."),"c37_cq_si":T("¡Sí!"),"c37_ca_tengo_todo":CA("¡No, Coquí! Tengo todo."),"c37_ca_tengo_bolsa":CA("¡No, Coquí! Tengo bolsa."),
 "c37_ca_adios":CA("¡Adiós, don Pepe!"),"c37_pepe_adios":PE("¡Adiós! ¡Gracias!"),"c37_ca_compra2":N("Carmen compra dos piraguas."),"c37_cq_gracias_carmen":T("¡Gracias, Carmen!"),
 "c37_ca_compra1":N("Carmen compra una piragua."),"c37_ca_no_compra":N("Carmen no compra piraguas."),"c37_van_casa":N("Carmen y Coquí van para la casa con la bolsa.")})
def ronda37(p):
    # Don Pepe asks one of his two questions (drawn afresh): "¿Algo más?" (right: no) or "¿Tienes bolsa?" (right: sí). A miss is filed under the question asked.
    # The sí bubble says "¡Sí!"; the no bubble says "No, gracias." to "¿Algo más?" and "No." to "¿Tienes bolsa?" (the script's Needs).
    q,r,l,n="q"+p,"r"+p,"l"+p,"n"+p
    return [{"draw":q,"options":["algomas","bolsa"]},{"calc":r,"cond":q+"=algomas","then":"no","else":"si"},{"calc":l,"cond":q+"=algomas","then":"c37_pepe_algo_mas","else":"c37_pepe_tienes_bolsa"},
     {"calc":n,"cond":q+"=algomas","then":"c37_cq_no_gracias","else":"c37_cq_no"},
     {"decide":"say","options":["si","no"],"baraja":True,"pick":"$"+r,"tests":"$"+q,"said":{"si":"c37_cq_si","no":"$"+n},"lead":[],"line":"$"+l,
      "right":[{"if":"ok","then":[{"if":q+"=algomas","then":[gesto("pepe","si")],"else":[gesto("carmen","bolsa")]},act("marca",que="ok")]}],
      "wrong":[{"if":q+"=algomas","then":[act("malta"),act("paga",quien="carmen",n=1),act("marca",que="x"),{"cost":1},"c37_ca_tengo_todo"],
                "else":[act("bolsapapel",a="carmen"),act("paga",quien="carmen",n=1),act("marca",que="x"),{"cost":1},"c37_ca_tengo_bolsa",gesto("carmen","bolsas")]}]}]
s37={"id":"algo-mas","title":"¿Algo más?","place":"El colmado","scene":"mostrador","next":"esto-y-eso",
 "goal":"Buy abuela's three things with Carmen's coins, and save what is left for piraguas.","stake":{"thing":"monedas","steps":2},"dots":8,"bien":"si_muy_bien",
 "focus_words":["¿tiene…?","¿algo más?","bolsa","compra"],"formas_foco":{"¿tiene…?":["¿tienes…?"]},
 "back_again":["buenos días","necesito","aquí tiene","colmado","queso","café","azúcar","pan","sí","no","tengo","gracias","todo","piragua","casa","bien"],
 "also_heard":[],"names":nm,"palabras":{"algomas":"¿algo más?","bolsa":"bolsa"},"clips":c,
 "beats":[{"set":{"hora":"manana"}},{"cam":"dentro","n":1},act("lista"),act("entra",quien="carmen"),act("entra",quien="coqui"),{"wait":500},
  # 1: greetings; the first turn
  "c37_estan","c37_ca_dias","c37_pepe_dias_luis","c37_cq_luis_casa",
  # 2 to 4: three things on abuela's list, three coins
  {"dots":1},act("monedas",n=5),tw("carrito"),act("piensa",quien="coqui",k="piragua"),"c37_ca_compra3",tw(None),act("lista",k="queso",hecho=0),"c37_ca_tiene_queso",
  ask("queso","c37_donde_queso",after=[act("baja",k="queso"),"c37_pepe_si_tienes"],then=[act("paga",quien="carmen",n=1),act("lista",k="queso",hecho=1),"c37_ca_compra_queso"]),
  {"dots":2},"c37_pepe_algo_mas",act("lista",k="cafe",hecho=0),"c37_ca_si_cafe",
  ask("cafe","c37_toca_cafe",after=[act("baja",k="cafe")],then=[act("paga",quien="carmen",n=1),act("lista",k="cafe",hecho=1)]),
  {"dots":3},"c37_pepe_algo_mas",act("lista",k="azucar",hecho=0),"c37_ca_si_azucar",
  ask("azucar","c37_toca_azucar",after=[act("baja",k="azucar")],then=[act("paga",quien="carmen",n=1),act("lista",k="azucar",hecho=1)]),
  "c37_pepe_algo_mas",gesto("carmen","lista"),"c37_ca_no_gracias",
  # 5: the cloth bag: she holds it open, don Pepe puts the three things in
  {"dots":4},"c37_ca_tiene_bolsa",act("guarda",quien="carmen",k="queso"),act("guarda",quien="carmen",k="cafe"),act("guarda",quien="carmen",k="azucar"),"c37_en_la_bolsa",
  ask("bolsa","c37_donde_bolsa",then=[gesto("carmen","bolsa")]),
  # 6: the turn. The señora has no bag: a paper bag, one more coin
  {"dots":5},act("entra",quien="senora"),"c37_sra_hola","c37_cq_bien","c37_sra_nec_pan",act("baja",k="pan"),"c37_pepe_aqui_bolsa",gesto("senora","manos"),"c37_sra_no_bolsa",
  act("bolsapapel",a="senora"),act("paga",quien="senora",n=1),act("sale",quien="senora",por="puerta"),CARD,{"wait":400},
  # A and B: his two questions, each drawn afresh
  {"dots":6}]+ronda37("a")+[{"dots":7}]+ronda37("b"),
 "final":[{"dots":8},gesto("carmen","monedas"),"c37_ca_adios","c37_pepe_adios",act("sale",quien="carmen",por="puerta"),act("sale",quien="coqui",por="puerta"),
  {"if":"lost=0","then":[act("piraguas",n=2),"c37_ca_compra2","c37_cq_gracias_carmen"],
   "else":[{"if":"lost=1","then":[act("piraguas",n=1),"c37_ca_compra1"],"else":[act("piraguas",n=0),"c37_ca_no_compra"]}]},
  "c37_van_casa",act("fin")],
 "leer":["c37_estan","c37_ca_dias","c37_pepe_dias_luis","c37_cq_luis_casa","c37_ca_compra3","c37_ca_tiene_queso","c37_donde_queso","c37_pepe_si_tienes","c37_ca_compra_queso","c37_pepe_algo_mas","c37_ca_si_cafe","c37_toca_cafe","c37_pepe_algo_mas","c37_ca_si_azucar","c37_toca_azucar",
  "c37_pepe_algo_mas","c37_ca_no_gracias","c37_ca_tiene_bolsa","c37_en_la_bolsa","c37_donde_bolsa","c37_sra_hola","c37_cq_bien","c37_sra_nec_pan","c37_pepe_aqui_bolsa","c37_sra_no_bolsa",
  "c37_pepe_algo_mas","c37_cq_no_gracias","c37_pepe_tienes_bolsa","c37_cq_si","c37_ca_adios","c37_pepe_adios","c37_ca_compra2","c37_cq_gracias_carmen","c37_van_casa"]}
s37=reuse(s37)
json.dump(s37,open("cuentos/algo-mas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 38. Esto y eso ----------------
c=dict(comunes); nm,nc=nombres("luis","coqui","senora","senor"); c.update(nc); c[AQUI[0]]=AQUI[1]
c.update({"c38_calor":N("Hace calor."),"c38_lu_tardes":L("¡Buenas tardes, don Pepe!"),"c38_pepe_tardes":PE("¡Buenas tardes!"),"c38_pepe_esto_limber":PE("Esto es un límber."),"c38_pepe_vende":N("Don Pepe vende límbers."),
 "c38_pepe_esto_luis":PE("Esto es para Luis."),"c38_pepe_eso_coqui":PE("Y eso es para Coquí."),"c38_pepe_toma_eso":PE("Coquí, toma eso."),"c38_cq_gracias":T("Gracias."),
 "c38_lu_compra":N("Luis compra un límber."),"c38_lu_frio":L("¡Mmm! ¡Esto está frío!"),"c38_lu_mira_eso":L("¡Mira eso!"),"c38_pepe_cansado":N("Don Pepe está cansado."),"c38_pepe_quieres":PE("Coquí, ¿quieres vender?"),
 "c38_cq_si_quiero":T("¡Sí, quiero!"),"c38_ahora_vende":N("Ahora Coquí vende límbers."),"c38_sra_tardes":SE("¡Buenas tardes!"),"c38_cq_tardes_sra":T("¡Buenas tardes, señora!"),"c38_sro_tardes":SO("¡Buenas tardes!"),
 "c38_vende_un":N("Coquí vende un límber."),"c38_vende_otro":N("Coquí vende otro límber."),"c38_pepe_vengan":PE("¡Vengan, niños!"),"c38_ni_tardes":NI("¡Buenas tardes!"),
 "c38_ni_compran":N("Los niños compran límbers. Están contentos."),"c38_un_nino":N("Un niño no tiene límber. Está triste."),"c38_dos_ninos":N("Dos niños no tienen límber. Están tristes."),"c38_pepe_gracias_coqui":PE("¡Gracias, Coquí!")})
for p,(_,F) in CLIENTE.items():
    c["c38_%s_quiero_esto"%p]=F("Quiero esto, por favor."); c["c38_%s_quiero_eso"%p]=F("Quiero eso, por favor.")
    c["c38_%s_no_esto"%p]=F("No, Coquí. Eso no. Quiero esto."); c["c38_%s_no_eso"%p]=F("No, Coquí. Esto no. Quiero eso.")   # she asked for "esto" and got the far one; she asked for "eso" and got the near one
    DIN.update(["c38_%s_quiero_esto"%p,"c38_%s_quiero_eso"%p,"c38_%s_no_esto"%p,"c38_%s_no_eso"%p])
def ronda38(p):
    # Two límbers of different colours: one beside the customer (cc), one far from her, beside the frog (cd). Which colour is where, and whether she asks for "esto" (the near one) or "eso" (the far one): drawn afresh each round.
    w,cc,cd,pa,pb,k="w"+p,"c"+p,"d"+p,"p"+p,"q"+p,"k"+p
    return [{"draw":w,"options":["esto","eso"]},{"draw":cc,"options":["a","b"],"other":cd},{"reparte":[pa,pb],"options":["white","orange"]},
     {"calc":k,"cond":w+"=esto","then":"limber_$"+cc,"else":"limber_$"+cd}]
def pon38(p):
    return act("limber",que="pon",col_a="$p"+p,col_b="$q"+p,cerca="$c"+p)
def dec38(p,vende):
    cu=CLIENTE[p][0]; w,k="w"+p,"k"+p
    return {"decide":"do","options":["limber_a","limber_b"],"pick":"$"+k,"tests":"$"+w,"lock":True,"lead":[],"line":"c38_%s_quiero_$%s"%(p,w),
      "right":[act("sirve",k="$"+k,a=cu),AQUI[0],act("paga",quien=cu,n=1),{"if":"ok","then":[act("limber",que="vuelve"),vende,act("marca",que="ok")]}],
      "wrong":[act("sirve",k="$x",a=cu),gesto(cu,"no"),act("marca",que="x"),"c38_%s_no_$%s"%(p,w),act("limber",que="derrite"),{"cost":1}]}
s38={"id":"esto-y-eso","title":"Esto y eso","place":"El colmado","scene":"mostrador","next":"latas-y-botellas",
 "goal":"Sell limbers on a hot afternoon, and keep enough in the freezer for the three waiting children.","stake":{"thing":"limbers","steps":2},"dots":6,"bien":"si_muy_bien",
 "focus_words":["esto","eso","vende","buenas tardes"],"formas_foco":{"vende":["vender"]},
 "back_again":["quiero","por favor","hace calor","frío","colmado","compra","aquí tiene","toma","mira","niño","triste","contento","cansado","gracias"],
 "also_heard":["límber","vender","otro","vengan"],"names":nm,"clips":c,
 "beats":[{"set":{"hora":"tarde"}},{"cam":"dentro","n":1},act("limber",que="bandeja"),act("entra",quien="luis"),{"wait":500},
  # 1: the heat; what a límber is
  "c38_calor","c38_lu_tardes","c38_pepe_tardes",gesto("pepe","mano",a="limber_a"),"c38_pepe_esto_limber","c38_pepe_vende",
  # 2: esto for Luis, eso for the frog (signed): the orange one by the frog
  {"dots":1},"c38_pepe_esto_luis",gesto("pepe","mira",a="mostrador"),"c38_pepe_eso_coqui",ask("limber_b","c38_pepe_toma_eso",after=[act("lame",quien="coqui"),"c38_cq_gracias"]),
  # 3 and 4: Luis buys the white one; don Pepe is tired and gives the shop to the frog
  act("paga",quien="luis",n=1),"c38_lu_compra",act("lame",quien="luis"),"c38_lu_frio",gesto("luis","mira",a="nevera"),"c38_lu_mira_eso",
  {"dots":2},act("abanico",quien="pepe"),"c38_pepe_cansado","c38_pepe_quieres","c38_cq_si_quiero","c38_ahora_vende",
  # 5: the turn. The señora comes in; two límbers come out of the freezer
  {"dots":3},act("entra",quien="senora"),"c38_sra_tardes","c38_cq_tardes_sra"]+
  ronda38("a")+[pon38("a"),CARD,{"wait":400},
  # A: the señora. B: the señor
  {"dots":4},dec38("a","c38_vende_un"),act("sale",quien="senora",por="puerta"),
  {"dots":5},act("entra",quien="senor"),"c38_sro_tardes"]+ronda38("b")+[pon38("b"),dec38("b","c38_vende_otro")],
 "final":[{"dots":6},gesto("pepe","levanta"),act("limber",que="cuenta"),"c38_pepe_vengan","c38_ni_tardes",    # `ninos` brings the children in itself (Needs, Values): no `entra`
  {"if":"lost=0","then":[act("ninos",n=3),"c38_ni_compran"],
   "else":[{"if":"lost=1","then":[act("ninos",n=2),"c38_un_nino"],"else":[act("ninos",n=1),"c38_dos_ninos"]}]},
  "c38_pepe_gracias_coqui",gesto("coqui","saluda"),act("fin")],
 "leer":["c38_calor","c38_lu_tardes","c38_pepe_tardes","c38_pepe_esto_limber","c38_pepe_vende","c38_pepe_esto_luis","c38_pepe_eso_coqui","c38_pepe_toma_eso","c38_cq_gracias","c38_lu_compra","c38_lu_frio","c38_lu_mira_eso","c38_pepe_cansado","c38_pepe_quieres","c38_cq_si_quiero","c38_ahora_vende",
  "c38_sra_tardes","c38_cq_tardes_sra","c38_a_quiero_esto",AQUI[0],"c38_vende_un","c38_sro_tardes","c38_b_quiero_eso",AQUI[0],"c38_vende_otro","c38_pepe_vengan","c38_ni_tardes","c38_ni_compran","c38_pepe_gracias_coqui"]}
s38=reuse(s38)
json.dump(s38,open("cuentos/esto-y-eso.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# the story before this scene (cafe-con-azucar) leads into this one: its `next` is set in gen_comer.py

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
for st in (s36,s37,s38):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:36|37|38)_|cq_|si_|muy_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
