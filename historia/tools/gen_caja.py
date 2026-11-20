# La caja (place 4, scene 4): stories 45, 46, 47. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/caja.md (draft 2, after the two reviews). Every quoted line of the script is exactly one clip, word for word.
# The scene `caja` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else.
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
PE=lambda t:D("pepe","Don Pepe",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); SA=lambda t:D("senora","La señora",t); SE=lambda t:D("senor","El señor",t)
def act(_n,**k): return dict({"act":_n},**k)
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star (the act `marca` with {que}; the register's window is `marca` with {n})
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story of this place has two scored rounds: the card shows two places
PAL={"10":"diez","11":"once","12":"doce","13":"trece","14":"catorce","15":"quince","16":"dieciséis","17":"diecisiete","18":"dieciocho","19":"diecinueve","20":"veinte"}
# an earlier story's focus words that a speaking turn may use (stories 36 to 44 are built elsewhere: their new words, from the order)
FOCUS_36_44=["colmado","buenos días","necesito","aquí tiene","¿tiene…?","¿algo más?","bolsa","compra","esto","eso","vende","buenas tardes","lata","botella","caja","¿cuántos?","cuatro","cinco","seis","siete",
             "ocho","nueve","diez","otro","tomate","cebolla","papa","plátano","aguacate","piña","limón","bueno","malo","libra","medio","fresco"]
MINE=("cuanto-es","caro-y-barato","el-cambio")
# a clip whose text and speaker are already recorded under another id keeps that id (nothing is recorded twice); the stories of this run feed it too, in order
EX=collections.defaultdict(collections.Counter)
for f in glob.glob("cuentos/*.json"):
    if any(m in f for m in MINE) or "/z" in f: continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items(): EX[(cl.get("who"),cl.get("habla"),cl["text"])][cid]+=1
DIN=set()   # ids that are put together in the story ("c45_pepe_$pa"): never renamed
def reuse(st,turnos):
    ren={}
    for cid,cl in list(st["clips"].items()):
        if "$" in cid or cid in DIN: continue
        k=(cl.get("who"),cl.get("habla"),cl["text"])
        if k in EX:
            best=EX[k].most_common(1)[0][0]
            if best!=cid: ren[cid]=best
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
    for cid,cl in out["clips"].items(): EX[(cl.get("who"),cl.get("habla"),cl["text"])][cid]+=1
    return out
TG=lambda *p:[{"palabra":w,"formas":list(f)} for w,f in p]
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!"),"p_n_luis":N("Este es Luis."),"b_n_senor":N("Es un señor."),"b_n_senora":N("Es una señora.")}

# ---------------- 45. ¿Cuánto es? ----------------
# The register's window and the two keys: the price is once, doce or trece (drawn afresh each round); the other key is the number beside it (10 to 14, drawn).
c=dict(comunes)
c.update({"c45_caja":N("Esta es la caja de don Pepe."),"c45_pepe_cuenta":PE("Uno, dos, tres. Tres dólares para ti, Coquí."),"c45_cq_gracias":T("¡Gracias, don Pepe!"),
 "c45_luis_cuanto":L("¿Cuánto es?"),"c45_donde_11":N("¿Dónde está el once?"),"c45_luis_paga":N("Luis paga once dólares."),
 "c45_senor_hola":SE("¡Hola, Coquí!"),"c45_cq_buenas":T("¡Buenas tardes, señor!"),"c45_senor_cuanto":SE("¿Cuánto es?"),"c45_toca_12":N("Toca el doce."),
 "c45_senora_cuanto":SA("¿Cuánto es?"),"c45_y_13":N("¿Y el trece?"),"c45_pepe_aviso":PE("¡Ay! Coquí, ¡la caja, por favor!"),
 "c45_toma3":PE("Toma, Coquí. Tres dólares."),"c45_toma2":PE("Toma, Coquí. Dos dólares."),"c45_toma1":PE("Toma, Coquí. Un dólar."),"c45_hasta":PE("¡Hasta mañana, Coquí!")})
for n in ("11","12","13"):
    w=PAL[n]
    c["c45_pepe_"+n]=PE("Son %s dólares."%w); c["c45_senora_paga_"+n]=N("La señora paga %s dólares."%w); c["c45_senor_paga_"+n]=N("El señor paga %s dólares."%w); c["c45_no_"+n]=N("No, Coquí. Mira. Son %s dólares."%w)
    DIN.update(["c45_pepe_"+n,"c45_senora_paga_"+n,"c45_senor_paga_"+n,"c45_no_"+n])
def ronda45(s,q):
    # one round: a customer asks, don Pepe reads a tag we cannot see, the frog rings it on one of two keys
    p,e,d,k,o,u,v="p"+s,"e"+s,"d"+s,"k"+s,"o"+s,"u"+s,"v"+s
    return [{"draw":p,"options":["11","12","13"]},{"draw":e,"options":["up","down"]},   # e: whether the other key is the number above the price or below it
     {"if":"%s=11"%p,"then":[{"calc":d,"cond":"%s=up"%e,"then":"12","else":"10"}],
      "else":[{"if":"%s=12"%p,"then":[{"calc":d,"cond":"%s=up"%e,"then":"13","else":"11"}],"else":[{"calc":d,"cond":"%s=up"%e,"then":"14","else":"12"}]}]},
     {"draw":k,"options":["tecla_a","tecla_b"],"other":o},
     {"calc":u,"cond":"%s=tecla_a"%k,"then":"$"+p,"else":"$"+d},{"calc":v,"cond":"%s=tecla_a"%k,"then":"$"+d,"else":"$"+p},
     {"decide":"do","options":["tecla_a","tecla_b"],"pick":"$"+k,"tests":"$"+p,"lock":True,"mudo":True,
      "lead":[act("cliente",quien=q,precio="$"+p,ver=0),"c45_%s_cuanto"%q,"c45_pepe_$"+p,act("teclas",a="$"+u,b="$"+v)],"line":"c45_pepe_$"+p,
      "right":[act("marca",n="$"+p),{"if":"ok","then":[act("etiqueta",ver=1),act("paga",quien=q,n="$"+p),"c45_%s_paga_$%s"%(q,p),OK],"else":[act("paga",quien=q,n="$"+p)]}],
      "wrong":[act("marca",n="$"+d),act("etiqueta",ver=1)]+X+["c45_no_$"+p,
               {"if":"%s=up"%e,"then":[act("clip",quita=1,a="cliente")],"else":[act("clip",quita=1,a="gaveta")]}]}]
s45={"id":"cuanto-es","title":"¿Cuánto es?","place":"El colmado","scene":"caja","next":"caro-y-barato",
 "goal":"Ring each price on the register's keys, so the three dollars under the clip are still there when don Pepe pays his helper.","stake":{"thing":"dólar","steps":2},"dots":7,"bien":"si_muy_bien",
 "focus_words":["¿cuánto es?","dólar","paga","once","doce","trece"],"back_again":["diez","tres","colmado","compra","buenas tardes","señor","señora","gracias","aquí tiene","olla","arroz"],
 "also_heard":[],"names":{"luis":"p_n_luis","senor":"b_n_senor","senora":"b_n_senora","coqui":"yo_coqui"},"palabras":{"11":"once","12":"doce","13":"trece"},"clips":c,
 "beats":[act("ir",a="repisa"),{"wait":500},
  # 1: the drawer, the three bills under the clip, thanks (a speaking turn)
  act("gaveta",abre=1),"c45_caja",act("clip",n=3),"c45_pepe_cuenta","c45_cq_gracias",
  # 2 to 4: three signed asks, one key each (the key 11, 12, 13); the other key is the number below
  {"dots":1},act("cliente",quien="luis",cosa="latas",precio="11",ver=1),"c45_luis_cuanto","c45_pepe_11",act("teclas",a="10",b="11"),
  ask("tecla_b","c45_donde_11",after=[act("marca",n="11")],then=[act("paga",quien="luis",n="11"),"c45_luis_paga"]),
  {"dots":2},act("cliente",quien="senor",cosa="olla",precio="12",ver=1),"c45_senor_hola","c45_cq_buenas","c45_senor_cuanto","c45_pepe_12",act("teclas",a="12",b="11"),
  ask("tecla_a","c45_toca_12",after=[act("marca",n="12")],then=[act("paga",quien="senor",n="12"),"c45_senor_paga_12"]),
  {"dots":3},act("cliente",quien="senora",cosa="arroz",precio="13",ver=1),"c45_senora_cuanto","c45_pepe_13",act("teclas",a="12",b="13"),
  ask("tecla_b","c45_y_13",after=[act("marca",n="13")],then=[act("paga",quien="senora",n="13"),"c45_senora_paga_13"]),
  # 5: the turn: a line forms, the tags turn their backs
  {"dots":4},act("cola",n=2),act("aviso"),"c45_pepe_aviso",CARD,{"wait":400},
  # 6: A, the señora; 7: B, the señor. Each drawn afresh
  {"dots":5}]+ronda45("a","senora")+[{"dots":6}]+ronda45("b","senor"),
 "final":[{"dots":7},   # 8: the shop is empty; what is left under the clip, by what was lost
  {"if":"lost=0","then":["c45_toma3",act("paga45",n=3),act("final")],"else":[{"if":"lost=1","then":["c45_toma2",act("paga45",n=2)],"else":["c45_toma1",act("paga45",n=1)]}]},
  "c45_hasta"],
 "leer":["c45_caja","c45_pepe_cuenta","c45_cq_gracias","c45_luis_cuanto","c45_pepe_11","c45_donde_11","c45_luis_paga","c45_senor_hola","c45_cq_buenas","c45_senor_cuanto","c45_pepe_12","c45_toca_12","c45_senor_paga_12",
  "c45_senora_cuanto","c45_pepe_13","c45_y_13","c45_senora_paga_13","c45_pepe_aviso","c45_senora_cuanto","c45_pepe_11","c45_senora_paga_11","c45_senor_cuanto","c45_pepe_13","c45_senor_paga_13","c45_toma3","c45_hasta"]}
s45=reuse(s45,{"c45_cq_gracias":TG(("gracias",["gracias"])),"c45_cq_buenas":TG(("buenas tardes",["buenas tardes"]),("señor",["señor","senor"]))})
json.dump(s45,open("cuentos/cuanto-es.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 46. Caro y barato ----------------
# Two things of one kind in front of the frog, each with its tag towards us: the prices are two of 14, 15, 16 (drawn), the dear one is the larger or finer. Round A is said by caro or barato, round B by the price.
c=dict(comunes)
c.update({"c46_compra":N("Coquí compra una taza."),"c46_pepe_cara":PE("Esta taza es cara: dieciséis dólares."),"c46_pepe_barata":PE("Y esta taza es barata: catorce dólares."),
 "c46_donde_taza":N("¿Dónde está la taza barata?"),"c46_cq_paga":N("Coquí paga catorce dólares."),"c46_pepe_quien":PE("¿Para quién es la taza?"),"c46_cq_abuela":T("Es para abuela."),
 "c46_pepe_ollas":PE("La olla grande es cara: dieciséis dólares. La olla pequeña es barata: quince dólares."),"c46_senora_olla":SA("Quiero la olla cara, por favor."),"c46_toca_olla":N("Toca la olla cara."),
 "c46_senora_paga16":N("La señora paga dieciséis dólares."),"c46_luis_cuanto":L("¿Cuánto es?"),"c46_pepe_platos":PE("Este, catorce dólares. Y este, quince dólares."),
 "c46_luis_plato":L("Quiero el plato de quince dólares."),"c46_donde_plato":N("¿Dónde está el plato de quince dólares?"),"c46_luis_paga15":N("Luis paga quince dólares."),
 "c46_luis_gracias":L("¡Gracias, Coquí!"),"c46_cq_denada":T("¡De nada!"),"c46_pepe_rapido":PE("¡Rápido, Coquí!"),
 "c46_pepe_abuela":PE("Y esto es para tu abuela."),"c46_no_hay_papel":N("No hay más papel."),"c46_cq_mira":T("¡Abuela! ¡Mira!")})
for w in ("caro","barato"):
    c["c46_vaso_"+w]=SE("Quiero el vaso %s, por favor."%w); c["c46_no_vaso_"+w]=N("No, Coquí. Mira. Este vaso es %s."%w); DIN.update(["c46_vaso_"+w,"c46_no_vaso_"+w])
for n in ("14","15","16"):
    c["c46_taza_"+n]=SA("Quiero la taza de %s dólares, por favor."%PAL[n]); c["c46_no_taza_"+n]=N("No, Coquí. Mira. Esta taza es de %s dólares."%PAL[n]); DIN.update(["c46_taza_"+n,"c46_no_taza_"+n])
def par46(s,kind):
    # the two prices (two of 14, 15, 16), which of the two spots holds the dear one, and what is on each spot
    q,l,h,k,e,u,v="q"+s,"l"+s,"h"+s,"c"+s,"e"+s,"u"+s,"v"+s
    return [{"draw":q,"options":["14-15","14-16","15-16"]},{"calc":l,"cond":"%s=15-16"%q,"then":"15","else":"14"},{"calc":h,"cond":"%s=14-15"%q,"then":"15","else":"16"},
     {"draw":k,"options":["cosa_a","cosa_b"],"other":e},   # k: where the dear one stands, e: where the cheap one
     {"calc":u,"cond":"%s=cosa_a"%k,"then":"$"+h,"else":"$"+l},{"calc":v,"cond":"%s=cosa_a"%k,"then":"$"+l,"else":"$"+h}]
def decide46(s,kind,quien,quien_pre,tests,line,noline,ka,pa):
    u,v="u"+s,"v"+s
    return {"decide":"do","options":["cosa_a","cosa_b"],"pick":"$"+ka,"tests":tests,"lock":True,"mudo":True,
      "lead":[act("par",k=kind,a="$"+u,b="$"+v),line],"line":line,
      "right":[act("empuja",cual="$"+ka),act("envuelve",ok=1),act("paga",quien=quien,n="$"+pa),{"if":"ok","then":[OK]}],
      "wrong":[act("empuja",cual="$x"),act("envuelve",ok=1)]+X+[noline,act("envuelve",ok=0)]}
s46={"id":"caro-y-barato","title":"Caro y barato","place":"El colmado","scene":"caja","next":"el-cambio",
 "goal":"Buy abuela a cup, then push to don Pepe the one each customer asks for: every wrong one he wraps tears a sheet of the gift paper that abuela's cup needs.","stake":{"thing":"papel","steps":2},"dots":7,"bien":"si_muy_bien",
 "focus_words":["caro","barato","catorce","quince","dieciséis"],
 "back_again":["taza","olla","plato","vaso","dólar","¿cuánto es?","paga","quiero","compra","once","doce","trece","grande","pequeño","abuela","por favor","gracias","de nada"],
 "also_heard":["papel"],"names":{"luis":"p_n_luis","senor":"b_n_senor","senora":"b_n_senora","coqui":"yo_coqui"},"palabras":{"14":"catorce","15":"quince","16":"dieciséis"},"clips":c,
 "beats":[act("papel",n=5),{"wait":500},
  # 1: the two cups, caro and barato said (taught), the signed ask on the cheap one, the frog pays
  {"dots":1},act("par",k="taza",a="16",b="14"),"c46_compra","c46_pepe_cara","c46_pepe_barata",
  ask("cosa_b","c46_donde_taza",then=[act("paga",quien="coqui",n="14"),"c46_cq_paga"]),
  # 2: for whom (a speaking turn)
  "c46_pepe_quien","c46_cq_abuela",
  # 3: the señora; the large pot (cara): the frog pushes it, don Pepe wraps it, four sheets left
  {"dots":2},act("par",k="olla",a="16",b="15"),"c46_pepe_ollas","c46_senora_olla",
  ask("cosa_a","c46_toca_olla",after=[act("empuja",cual="cosa_a"),act("envuelve",ok=1),act("papel",n=4)],then=[act("paga",quien="senora",n="16"),"c46_senora_paga16"]),
  # 4: Luis; the plate of fifteen; he has a bag of his own, no paper; his thanks, answered (a speaking turn)
  {"dots":3},act("par",k="plato",a="14",b="15"),"c46_luis_cuanto","c46_pepe_platos","c46_luis_plato",
  ask("cosa_b","c46_donde_plato",then=[act("paga",quien="luis",n="15"),"c46_luis_paga15","c46_luis_gracias","c46_cq_denada"]),
  # 5: the turn: a line of people with hats and balloons, don Pepe wraps without a look
  {"dots":4},act("cola",n=2),"c46_pepe_rapido",CARD,{"wait":400},
  # 6: A, the señor: caro or barato (drawn), two glasses
  {"dots":5}]+par46("a","vaso")+[{"draw":"wa","options":["caro","barato"],"other":"oa"},{"calc":"ka","cond":"wa=caro","then":"$ca","else":"$ea"},{"calc":"ra","cond":"wa=caro","then":"$ha","else":"$la"},
  decide46("a","vaso","senor","El señor","$wa","c46_vaso_$wa","c46_no_vaso_$oa","ka","ra"),
  # 7: B, the señora: the price asked for (drawn: the price of one of the two), two cups
  {"dots":6}]+par46("b","taza")+[{"draw":"wb","options":["caro","barato"]},{"calc":"kb","cond":"wb=caro","then":"$cb","else":"$eb"},
  {"calc":"nb","cond":"wb=caro","then":"$hb","else":"$lb"},{"calc":"ob","cond":"wb=caro","then":"$lb","else":"$hb"},
  decide46("b","taza","senora","La señora","$nb","c46_taza_$nb","c46_no_taza_$ob","kb","nb")],
 "final":[{"dots":7},   # 8: abuela's cup, by the sheets left (two sheets left = nothing lost); 9: the frog carries it out
  {"if":"lost=0","then":[act("regalo46",n=2),"c46_pepe_abuela",act("final")],"else":[{"if":"lost=1","then":[act("regalo46",n=1),"c46_pepe_abuela"],"else":[act("regalo46",n=0),"c46_no_hay_papel"]}]},
  "c46_cq_mira"],
 "leer":["c46_compra","c46_pepe_cara","c46_pepe_barata","c46_donde_taza","c46_cq_paga","c46_pepe_quien","c46_cq_abuela","c46_pepe_ollas","c46_senora_olla","c46_toca_olla","c46_senora_paga16","c46_luis_cuanto","c46_pepe_platos","c46_luis_plato","c46_donde_plato","c46_luis_paga15",
  "c46_luis_gracias","c46_cq_denada","c46_pepe_rapido","c46_vaso_barato","c46_taza_15","c46_pepe_abuela","c46_cq_mira"]}
s46=reuse(s46,{"c46_cq_abuela":TG(("abuela",["abuela"])),"c46_cq_denada":TG(("de nada",["de nada"]))})
json.dump(s46,open("cuentos/caro-y-barato.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 47. El cambio ----------------
# Every customer pays with one twenty. The price is diecisiete or dieciocho (drawn afresh each round); the keys are 17 and 18 for seventeen, 18 and 17 or 18 and 19 for eighteen (never sixteen beside seventeen).
c=dict(comunes); c["p_n_carmen"]=N("Esta es Carmen.")
c.update({"c47_aqui_ninos":N("Aquí están los niños."),"c47_pepe_quieren":PE("¿Qué quieren los niños?"),"c47_cq_bola":T("¡Una bola!"),"c47_aqui_chavos":N("Aquí están los chavos de los niños. Necesitan más chavos."),
 "c47_luis_cuanto":L("¿Cuánto es?"),"c47_donde_17":N("¿Dónde está el diecisiete?"),"c47_luis_paga20":N("Luis paga con veinte dólares."),
 "c47_pepe_cambio_luis":PE("Aquí tienes tu cambio: dieciocho, diecinueve y veinte."),"c47_toca_18":N("Toca el dieciocho."),"c47_pepe_cambio_carmen":PE("Aquí tienes tu cambio: diecinueve y veinte."),
 "c47_carmen_quien":CA("¿Para quién es el cambio?"),"c47_cq_ninos":T("¡Para los niños!"),"c47_pepe_aviso":PE("Coquí, ¡la caja, por favor!"),
 "c47_mas_chavos":N("Más chavos para la bola."),"c47_vengan":PE("¡Vengan, niños!"),"c47_compran":N("Los niños compran la bola."),"c47_cq_adios":T("¡Adiós, niños!"),
 "c47_faltan":N("Faltan chavos para la bola. ¡Mañana!"),"c47_pepe_gracias":PE("¡Gracias, Coquí! ¡Hasta mañana!")})
for n,cam in (("17","dieciocho, diecinueve y veinte"),("18","diecinueve y veinte")):
    w=PAL[n]
    c["c47_pepe_"+n]=PE("Son %s dólares."%w); c["c47_cambio_"+n]=PE("Aquí tiene su cambio: %s."%cam); c["c47_no_"+n]=N("No, Coquí. Mira. Son %s dólares."%w)
    DIN.update(["c47_pepe_"+n,"c47_cambio_"+n,"c47_no_"+n])
for q,SS in (("senora",SA),("senor",SE)):
    c["c47_%s_cuanto"%q]=SS("¿Cuánto es?"); c["c47_%s_paga20"%q]=N(("La señora" if q=="senora" else "El señor")+" paga con veinte dólares.")
def ronda47(s,q):
    p,e,d,k,o,u,v="p"+s,"e"+s,"d"+s,"k"+s,"o"+s,"u"+s,"v"+s
    return [{"draw":p,"options":["17","18"]},{"draw":e,"options":["17","19"]},{"calc":d,"cond":"%s=17"%p,"then":"18","else":"$"+e},   # the other key: 18 for seventeen; 17 or 19 for eighteen
     {"draw":k,"options":["tecla_a","tecla_b"],"other":o},
     {"calc":u,"cond":"%s=tecla_a"%k,"then":"$"+p,"else":"$"+d},{"calc":v,"cond":"%s=tecla_a"%k,"then":"$"+d,"else":"$"+p},
     {"decide":"do","options":["tecla_a","tecla_b"],"pick":"$"+k,"tests":"$"+p,"lock":True,"mudo":True,
      "lead":[act("cliente",quien=q,precio="$"+p,ver=0),"c47_%s_cuanto"%q,"c47_pepe_$"+p,act("paga",quien=q,n="$"+p,con=20),act("teclas",a="$"+u,b="$"+v)],"line":"c47_pepe_$"+p,
      "right":[act("marca",n="$"+p),{"if":"ok","then":[act("etiqueta",ver=1),"c47_%s_paga20"%q,"c47_cambio_$"+p,
                                                     {"if":"%s=17"%p,"then":[act("cambio",n=3,ok=1)],"else":[act("cambio",n=2,ok=1)]},"c47_mas_chavos",OK],
                       "else":[{"if":"%s=17"%p,"then":[act("cambio",n=3,ok=0)],"else":[act("cambio",n=2,ok=0)]}]}],
      "wrong":[act("marca",n="$"+d),act("etiqueta",ver=1)]+X+["c47_no_$"+p]}]
s47={"id":"el-cambio","title":"El cambio","place":"El colmado","scene":"caja",
 "goal":"Ring each price on the register's keys, so the change goes into the jar and the children can buy the ball.","stake":{"thing":"cambio","steps":2},"dots":6,"bien":"si_muy_bien",
 "focus_words":["cambio","chavos","diecisiete","dieciocho","diecinueve","veinte"],"back_again":["dólar","¿cuánto es?","paga","bola","niño","quiere","dieciséis","compra","para","aquí tiene","mañana"],
 "also_heard":["faltan","mañana"],"names":{"luis":"p_n_luis","carmen":"p_n_carmen","senor":"b_n_senor","senora":"b_n_senora","coqui":"yo_coqui"},"palabras":{"17":"diecisiete","18":"dieciocho"},"clips":c,
 "beats":[{"wait":500},
  # 1: the children at the window; the ball; a speaking turn
  act("ninos47",que="ventana"),"c47_aqui_ninos","c47_pepe_quieren","c47_cq_bola","c47_aqui_chavos",
  # 2 and 3: two signed asks (the key 17, the key 18); Luis and Carmen pay with a twenty and give the change to the children's jar
  {"dots":1},act("cliente",quien="luis",cosa="olla",precio="17",ver=1),act("paga",quien="luis",n="17",con=20),"c47_luis_cuanto","c47_pepe_17",act("teclas",a="17",b="18"),
  ask("tecla_a","c47_donde_17",after=[act("marca",n="17")],then=["c47_luis_paga20","c47_pepe_cambio_luis",act("cambio",n=3,ok=1)]),
  {"dots":2},act("cliente",quien="carmen",cosa="sarten",precio="18",ver=1),act("paga",quien="carmen",n="18",con=20),"c47_pepe_18",act("teclas",a="19",b="18"),
  ask("tecla_b","c47_toca_18",after=[act("marca",n="18")],then=["c47_pepe_cambio_carmen","c47_carmen_quien","c47_cq_ninos",act("cambio",n=2,ok=1)]),
  # 4: the turn: two fingers at the window, a line forms
  {"dots":3},act("ninos47",que="dos"),act("cola",n=2),"c47_pepe_aviso",CARD,{"wait":400},
  # 5: A, the señora; 6: B, the señor. Each drawn afresh
  {"dots":4}]+ronda47("a","senora")+[{"dots":5}]+ronda47("b","senor"),
 "final":[{"dots":6},"c47_vengan",act("ninos47",que="entran"),   # 7: the jar and its lines, by what was lost
  {"if":"lost=0","then":[{"set":{"vitrina":0}},"c47_compran",act("ninos47",que="salen"),"c47_cq_adios",act("final")],"else":["c47_faltan"]},
  "c47_pepe_gracias"],
 "leer":["c47_aqui_ninos","c47_pepe_quieren","c47_cq_bola","c47_aqui_chavos","c47_luis_cuanto","c47_pepe_17","c47_donde_17","c47_luis_paga20","c47_pepe_cambio_luis","c47_pepe_18","c47_toca_18","c47_pepe_cambio_carmen","c47_carmen_quien","c47_cq_ninos","c47_pepe_aviso",
  "c47_senora_cuanto","c47_pepe_17","c47_senora_paga20","c47_cambio_17","c47_mas_chavos","c47_senor_cuanto","c47_pepe_18","c47_senor_paga20","c47_cambio_18","c47_mas_chavos","c47_vengan","c47_compran","c47_cq_adios","c47_pepe_gracias"]}
s47=reuse(s47,{"c47_cq_bola":TG(("bola",["bola"])),"c47_cq_ninos":TG(("niño",["niños","ninos"]))})
json.dump(s47,open("cuentos/el-cambio.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
# every id the steps name (with no variable in it) is in the story's clips; every `leer` id too; every speaking turn is on a word of an earlier story
earlier=set(FOCUS_36_44)
for f in glob.glob("cuentos/*.json"):
    if any(m in f for m in MINE): continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s45,s46,s47):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:45|46|47)_|si_|yo_|p_n_|b_n_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
