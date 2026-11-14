# La estufa (place 3, scene 2): stories 27, 28, 29 and the scene's picture pairs. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/estufa.md
import json,glob,os,re
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); AB=lambda t:D("abuela","Abuela",t)
tw=lambda k:{"set":{"twinkle":k}}
def act(_n,**k): return dict({"act":_n},**k)
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
say=lambda c,gap=250:{"say":c,"gap":gap}
ok=lambda:{"if":"ok","then":[act("marca",que="ok")]}
X=[act("marca",que="x"),{"cost":1}]
CARD={"set":{"tarjeta":"rondas","marcas":[None,None,None]}}
NOM={"abuelo":"Abuelo","mama":"Mamá","papa":"Papá","carmen":"Carmen","luis":"Luis","abuela":"Abuela"}
comunes={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!"),"p_n_luis":N("Este es Luis."),"p_n_carmen":N("Esta es Carmen."),"abuela":N("Esta es abuela."),
 "esta_es_mama":N("Esta es mamá."),"n_papa":N("Este es papá."),"n_abuelo":N("Este es abuelo."),"m_n_cocina":N("Es la cocina.")}
BASE={"luis":"p_n_luis","carmen":"p_n_carmen","coqui":"yo_coqui","abuela":"abuela","mama":"esta_es_mama","papa":"n_papa","abuelo":"n_abuelo","cocina":"m_n_cocina"}
ES={"arroz":"arroz","hab":"habichuelas"}; LISTO={"arroz":"El arroz está listo.","hab":"Las habichuelas están listas."}; MIRA={"arroz":"Mira el arroz.","hab":"Mira las habichuelas."}

# ---------------- 27. Arroz con habichuelas ----------------
c=dict(comunes)
c.update({"c27_hace_comida":N("Abuela hace la comida."),"c27_una_olla":N("Aquí hay una olla."),"c27_otra_olla":N("Y aquí hay otra olla."),"c27_aqui_arroz":N("Aquí hay arroz."),"c27_aqui_hab":N("Y aquí hay habichuelas."),
 "c27_cq_pone_arroz":N("Coquí pone el arroz en la olla."),"c27_ab_hace_arroz":N("Abuela hace arroz."),"c27_luis_hace_hab":N("Luis hace habichuelas."),
 "c27_cq_arroz":T("¡Arroz!"),"c27_cq_hab":T("¡Habichuelas!"),"c27_mas_arroz":N("Más arroz para abuela."),"c27_mas_hab":N("Más habichuelas para Luis."),
 "c27_listo_arroz":AB(LISTO["arroz"]),"c27_listo_hab":AB(LISTO["hab"]),
 "c27_familia_hambre":N("La familia tiene hambre."),"c27_familia_come":N("La familia come arroz con habichuelas."),"c27_luis_hambre":L("¡Tengo hambre!"),
 "c27_no_aqui_arroz":N("No, Coquí. Mira. Aquí hay arroz."),"c27_no_aqui_hab":N("No, Coquí. Mira. Aquí hay habichuelas."),
 "c27_no_mira_arroz":N("No, Coquí. "+MIRA["arroz"]),"c27_no_mira_hab":N("No, Coquí. "+MIRA["hab"]),
 "c27_fin":N("Aquí hay arroz con habichuelas."),"c24_a_comer":AB("¡A comer!"),"c27_cq_fin":T("¡Arroz con habichuelas!")})
for p in ("abuela","luis"):
    for k in ("arroz","hab"):
        c["c27_%s_dame_%s"%(p,k)]=D(p,NOM[p],"Dame %s, por favor."%ES[k]); c["c27_no_%s_hace_%s"%(p,k)]=N("No, Coquí. Mira. %s hace %s."%(NOM[p],ES[k]))
DV=["di_arroz","di_hab"]; VV={"di_arroz":"c27_cq_arroz","di_hab":"c27_cq_hab"}
s27={"id":"arroz-con-habichuelas","title":"Arroz con habichuelas","place":"La cocina","scene":"estufa","next":"el-pollo-y-el-huevo",
 "goal":"Help abuela and Luis cook the rice and the beans.","stake":{"thing":"comida","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["arroz","habichuelas","olla","hace"],"back_again":["pone","dame","por favor","más","para","hay","aquí","otra","listo","mira","tengo hambre","familia","come"],
 "also_heard":["listas"],"names":BASE,"palabras":{"hab":"habichuelas"},"clips":c,
 "beats":[act("inicio27"),{"wait":500},"c27_hace_comida",tw("olla0"),"c27_una_olla",tw("olla1"),"c27_otra_olla",tw("saco"),"c27_aqui_arroz",tw("tazon"),"c27_aqui_hab",tw(None),
  {"dots":1},ask("saco","c27_abuela_dame_arroz",[act("cuchara",a="abuela",suelto=1),"c27_ab_hace_arroz"],[act("echa",k="arroz",a="abuela",suelto=1),"c27_cq_pone_arroz",act("ya")]),
  ask("tazon","c27_luis_dame_hab",[act("cuchara",a="luis",suelto=1),"c27_luis_hace_hab"],[act("echa",k="hab",a="luis")]),
  {"dots":2},act("pide",a="abuela"),
  ask("di_arroz",None,[],[act("pide",a="abuela",no=1),act("carmenecha",k="arroz",a="abuela",suelto=1),"c27_mas_arroz",act("ya")],resp=DV,baraja=True,voces=VV,said={"di_arroz":"c27_cq_arroz"}),
  act("pide",a="luis"),
  ask("di_hab",None,[act("ultimas27")],[act("pide",a="luis",no=1),act("carmenecha",k="hab",a="luis",suelto=1),"c27_mas_hab",act("ya")],resp=DV,baraja=True,voces=VV,said={"di_hab":"c27_cq_hab"}),
  {"dots":3},act("platos27"),ask("olla1","c27_listo_arroz",[],[act("apaga",a="olla1")]),
  ask("olla0","c27_listo_hab",[],[act("apaga",a="olla0")]),
  # the turn: the family eats it all; the pots are filled with water again
  {"dots":4},act("familia27"),"c27_familia_hambre",act("sirve27"),act("ventana27",suelto=1),"c27_familia_come",act("ya"),say("c27_luis_hambre"),act("otravez27"),CARD,{"wait":400},
  # A: which one. One cook, drawn fresh, asks for one, drawn fresh
  {"dots":5},{"draw":"ca","options":["abuela","luis"],"other":"cb"},{"draw":"ka","options":["arroz","hab"],"other":"kb"},{"calc":"ga","cond":"ka=arroz","then":"saco","else":"tazon"},
  act("g",quien="$ca",pose="offer",ms=300),
  {"decide":"do","options":["saco","tazon"],"pick":"$ga","tests":"$ka","lock":True,"lead":[],"line":"c27_$ca_dame_$ka",
   "right":[act("g",quien="$ca",pose="idle"),act("echa",k="$ka",a="$ca"),ok(),act("carmenecha",k="$kb",a="$cb")],
   "wrong":[act("g",quien="$ca",pose="idle"),act("echa",k="$x",a="$ca"),act("saca",a="$ca")]+X+["c27_no_aqui_$ka"]},
  # B: what it needs more of. One cook, drawn fresh, holds an empty cup up
  {"dots":6},{"draw":"cc","options":["abuela","luis"],"other":"cd"},{"calc":"kc","cond":"cc=$ca","then":"$ka","else":"$kb"},{"calc":"kd","cond":"cc=$ca","then":"$kb","else":"$ka"},act("pide",a="$cc"),
  {"decide":"say","options":DV,"baraja":True,"pick":"di_$kc","tests":"$kc","voces":VV,"said":VV,"lead":[],"line":None,
   "right":[act("pide",a="$cc",no=1),act("carmenecha",k="$kc",a="$cc"),ok(),act("carmenecha",k="$kd",a="$cd")],
   "wrong":[act("pide",a="$cc",no=1),act("carmenecha",k="$x",a="$cc"),act("saca",a="$cc")]+X+["c27_no_$cc_hace_$kc"]},
  act("ultimas27"),
  # C: which one is ready. Abuela says it, whoever cooks it
  {"dots":7},{"draw":"ke","options":["arroz","hab"]},{"calc":"pe","cond":"ke=$ka","then":"$ca","else":"$cb"},{"calc":"pf","cond":"ke=$ka","then":"$cb","else":"$ca"},
  {"calc":"oe","cond":"pe=abuela","then":"olla1","else":"olla0"},{"calc":"of","cond":"pe=abuela","then":"olla0","else":"olla1"},act("platos27"),
  {"decide":"do","options":["olla0","olla1"],"pick":"$oe","tests":"$ke","lock":True,"lead":[],"line":"c27_listo_$ke",
   "right":[act("apaga",a="$oe"),{"if":"ok","then":[act("marca",que="ok"),{"wait":500},act("abuelamira"),act("apaga",a="$of")],"else":[act("enciende",a="$of"),{"wait":600},act("apaga",a="$of")]}],
   "wrong":[act("apaga",a="$of"),act("quema",a="$oe")]+X+["c27_no_mira_$ke"]}],
 "final":[{"dots":8},act("sirve27"),"c27_fin","c24_a_comer",act("final27"),say("c27_cq_fin",300),act("fin")],
 "leer":["c27_hace_comida","c27_una_olla","c27_otra_olla","c27_aqui_arroz","c27_aqui_hab","c27_abuela_dame_arroz","c27_cq_pone_arroz","c27_ab_hace_arroz","c27_luis_dame_hab","c27_luis_hace_hab","c27_cq_arroz","c27_mas_arroz","c27_cq_hab","c27_mas_hab",
  "c27_listo_arroz","c27_listo_hab","c27_familia_hambre","c27_familia_come","c27_luis_hambre","c27_fin","c24_a_comer","c27_cq_fin"]}
json.dump(s27,open("cuentos/arroz-con-habichuelas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 29. ¡Cuidado! ----------------
c=dict(comunes)
CH={"cal":"chocolate caliente","frio":"chocolate frío"}; NOMM={"abuelo":"Abuelo","mama":"Mamá","papa":"Papá","carmen":"Carmen"}
c.update({"c29_olla_caliente":N("La olla está caliente."),"c29_aqui_cal":N("Aquí hay chocolate caliente."),"c29_aqui_frio":N("Y aquí hay chocolate frío."),
 "c29_luis_ya":L("¡Ya está!"),"c29_luis_toma":L("Toma."),"c29_ab_cuidado_caliente":AB("¡Cuidado! Está caliente."),
 "c29_ab_cuidado":AB("¡Cuidado, Coquí!"),"c29_cq_espera":N("Coquí espera."),"c29_ab_ya":AB("¡Ya está, Coquí!"),"c29_cq_cal":T("¡Caliente!"),"c29_cq_frio":T("¡Frío!"),
 "c29_mas_chocolate":N("La familia dice: ¡Más chocolate!"),"c24_otra_vez":AB("¡Otra vez!"),
 "c29_no_cuidado":N("No, Coquí. Abuela dice: ¡Cuidado!"),"c29_no_ya":N("No, Coquí. Abuela dice: ¡Ya está!"),
 "c29_familia_bebe":N("La familia bebe chocolate."),"c29_cq_mmm":T("¡Mmm! ¡Chocolate!")})
for p in NOMM:
    for k in CH:
        c["c29_%s_quiere_%s"%(p,k)]=D(p,NOMM[p],"Quiero %s."%CH[k]); c["c29_no_%s_quiere_%s"%(p,k)]=N("No, Coquí. Mira. %s quiere %s."%(NOMM[p],CH[k])); c["c29_%s_bebe_%s"%(p,k)]=N("%s bebe %s."%(NOMM[p],CH[k]))
DO=["espera","saca"]; DT=["di_cal","di_frio"]; VT={"di_cal":"c29_cq_cal","di_frio":"c29_cq_frio"}
def sirve(p,k,mode):   # an opening step: one cup for one person
    return [act("viene",quien=p)]+([act("piensa",quien=p,k=k)] if mode=="di" else [])
s29={"id":"cuidado","title":"¡Cuidado!","place":"La cocina","scene":"estufa","next":None,
 "goal":"Fry the fritters, and bring everybody the chocolate he wants.","stake":{"thing":"merienda","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["caliente","frío","cuidado","ya"],"back_again":["olla","chocolate","quiero","bebe","más","mira","espera","hay","aquí","otra vez","familia"],
 "also_heard":[],"names":BASE,"palabras":{"cal":"caliente","frio":"frío"},"clips":c,
 "beats":[act("inicio29"),{"wait":500},tw("olla0"),"c29_olla_caliente","c29_aqui_cal",tw("jarra"),"c29_aqui_frio",tw(None),
  {"dots":1},act("viene",quien="papa"),
  ask("olla0","c29_papa_quiere_cal",["c29_papa_bebe_cal",act("aparte",quien="papa")],[act("llena",k="cal"),say("c29_luis_ya"),act("lleva29",a="papa",suelto=1),"c29_ab_cuidado_caliente",act("ya")]),
  act("viene",quien="carmen"),
  ask("jarra","c29_carmen_quiere_frio",["c29_carmen_bebe_frio",act("aparte",quien="carmen")],[act("llena",k="frio"),say("c29_luis_ya"),act("lleva29",a="carmen")]),
  {"dots":2},act("frie"),
  ask("espera","c29_ab_cuidado",[act("dora")],["c29_cq_espera"],resp=DO,baraja=True),
  ask("saca","c29_ab_ya",[],[act("saca29")],resp=DO,baraja=True),
  {"dots":3},act("viene",quien="abuelo"),act("piensa",quien="abuelo",k="cal"),
  ask("di_cal",None,["c29_abuelo_bebe_cal",act("aparte",quien="abuelo")],[act("llena",k="cal"),act("luisda",a="abuelo",suelto=1),say("c29_luis_toma"),act("ya"),act("piensa",quien="abuelo")],resp=DT,baraja=True,voces=VT,said={"di_cal":"c29_cq_cal"}),
  act("viene",quien="mama"),act("piensa",quien="mama",k="frio"),
  ask("di_frio",None,["c29_mama_bebe_frio",act("aparte",quien="mama")],[act("llena",k="frio"),act("luisda",a="mama",suelto=1),say("c29_luis_toma"),act("ya"),act("piensa",quien="mama")],resp=DT,baraja=True,voces=VT,said={"di_frio":"c29_cq_frio"}),
  # the turn
  {"dots":4},act("turno29"),"c29_mas_chocolate","c24_otra_vez",CARD,{"wait":400},
  # A: what he does himself
  {"dots":5},{"draw":"da","options":["cuidado","ya"]},{"calc":"ra","cond":"da=cuidado","then":"espera","else":"saca"},act("frie"),
  {"decide":"say","options":DO,"baraja":True,"pick":"$ra","tests":"$da","lead":[],"line":"c29_ab_$da",
   "right":[{"if":"ok","then":[act("dora"),act("saca29"),act("marca",que="ok")],"else":[act("frie"),act("dora"),act("saca29")]}],
   "wrong":[{"if":"da=cuidado","then":[act("saca29",cae=1)],"else":[act("quema29")]}]+X+["c29_no_$da"]},
  act("resto29"),
  # B: which chocolate, by what he says
  {"dots":6},{"reparte":["pb","pc"],"options":["papa","mama","abuelo","carmen"]},{"draw":"wb","options":["cal","frio"]},{"calc":"gb","cond":"wb=cal","then":"olla0","else":"jarra"},act("viene",quien="$pb"),
  {"decide":"do","options":["olla0","jarra"],"pick":"$gb","tests":"$wb","lock":True,"lead":[],"line":"c29_$pb_quiere_$wb",
   "right":[act("llena",k="$gb"),act("lleva29",a="$pb"),ok(),act("aparte",quien="$pb")],
   "wrong":[act("llena",k="$x"),act("lleva29",a="$pb"),act("sorbo",a="$pb"),act("piensa",quien="$pb",k="$wb")]+X+["c29_no_$pb_quiere_$wb"]},
  # C: which chocolate, by what he thinks of
  {"dots":7},{"draw":"wc","options":["cal","frio"]},act("viene",quien="$pc"),act("piensa",quien="$pc",k="$wc"),
  {"decide":"say","options":DT,"baraja":True,"pick":"di_$wc","tests":"$wc","voces":VT,"said":VT,"lead":[],"line":None,
   "right":[act("llena",k="di_$wc"),act("luisda",a="$pc"),act("piensa",quien="$pc"),ok(),act("aparte",quien="$pc")],
   "wrong":[act("llena",k="$x"),act("luisda",a="$pc"),act("sorbo",a="$pc")]+X+["c29_no_$pc_quiere_$wc"]}],
 "final":[{"dots":8},act("final29"),"c29_familia_bebe",say("c29_cq_mmm",300),act("fin")],
 "leer":["c29_olla_caliente","c29_aqui_cal","c29_aqui_frio","c29_papa_quiere_cal","c29_luis_ya","c29_ab_cuidado_caliente","c29_papa_bebe_cal","c29_carmen_quiere_frio","c29_carmen_bebe_frio","c29_ab_cuidado","c29_cq_espera","c29_ab_ya",
  "c29_cq_cal","c29_abuelo_bebe_cal","c29_cq_frio","c29_mama_bebe_frio","c29_mas_chocolate","c24_otra_vez","c29_familia_bebe","c29_cq_mmm"]}
json.dump(s29,open("cuentos/cuidado.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# clip ids are global: the same id must have the same text everywhere
seen={}; clash=0; new=0; chars=0
for f in sorted(glob.glob("cuentos/*.json")):
    if "zz-" in f or "zmesa" in f or "zestufa" in f: continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items():
        key=(cl.get("who"),cl.get("text"))
        if cid in seen and seen[cid]!=key: print("CLASH",cid,seen[cid],key,f); clash+=1
        seen.setdefault(cid,key)
for cid,(who,text) in seen.items():
    if not os.path.exists(f"audio/{cid}.mp3"): new+=1; chars+=len(text)
print(len(seen),"clips,",new,"new,",chars,"characters to record,",clash,"clashes")
for st in (s27,s29):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"(c(?:27|28|29)_[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
