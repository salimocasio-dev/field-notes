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
 "c26_comida_lista":N("La comida está lista."),"c27_comen":N("Luis come. Carmen come. Abuela come."),"cq_gracias_abuela":T("¡Gracias, abuela!"),"c27_aqui_arroz":N("Aquí hay arroz.")})
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
  # A: which one. One cook, drawn fresh, asks for one, drawn fresh; only his pot is on the stove
  {"dots":5},{"draw":"ca","options":["abuela","luis"],"other":"cb"},{"draw":"ka","options":["arroz","hab"],"other":"kb"},{"calc":"ga","cond":"ka=arroz","then":"saco","else":"tazon"},
  act("unaolla",a="$ca"),act("g",quien="$ca",pose="offer",ms=300),
  {"decide":"do","options":["saco","tazon"],"pick":"$ga","tests":"$ka","lock":True,"lead":[],"line":"c27_$ca_dame_$ka",
   "right":[act("g",quien="$ca",pose="idle"),act("echa",k="$ka",a="$ca"),ok()],
   "wrong":[act("g",quien="$ca",pose="idle"),act("echa",k="$x",a="$ca"),act("saca",a="$ca"),act("nota",k="fa")]+X+["c27_no_aqui_$ka"]},
  act("unaolla",a="$cb"),act("carmenecha",k="$kb",a="$cb"),
  # B: what it needs more of. One cook, drawn fresh, holds an empty cup up; after a miss in A it is the cook of the food that was thrown away
  {"dots":6},{"draw":"cm","options":["abuela","luis"],"other":"cn"},{"calc":"cc","cond":"fa=1","then":"$cb","else":"$cm"},{"calc":"cd","cond":"fa=1","then":"$ca","else":"$cn"},{"calc":"kc","cond":"cc=$ca","then":"$ka","else":"$kb"},{"calc":"kd","cond":"cc=$ca","then":"$kb","else":"$ka"},act("pide",a="$cc"),
  {"decide":"say","options":DV,"baraja":True,"pick":"di_$kc","tests":"$kc","voces":VV,"said":VV,"lead":[],"line":None,
   "right":[act("pide",a="$cc",no=1),act("carmenecha",k="$kc",a="$cc"),ok()],
   "wrong":[act("pide",a="$cc",no=1),act("carmenecha",k="$x",a="$cc"),act("saca",a="$cc")]+X+["c27_no_$cc_hace_$kc"]},
  act("carmenecha",k="$kd",a="$cd"),act("ultimas27"),
  # C: which one is ready. Abuela says it from the plates, whoever cooked it; nobody but the frog is at the stove
  {"dots":7},{"draw":"ke","options":["arroz","hab"],"other":"kf"},{"calc":"pe","cond":"ke=$ka","then":"$ca","else":"$cb"},
  {"calc":"oe","cond":"pe=abuela","then":"olla1","else":"olla0"},{"calc":"of","cond":"pe=abuela","then":"olla0","else":"olla1"},act("platos27"),
  {"decide":"do","options":["olla0","olla1"],"pick":"$oe","tests":"$ke","lock":True,"lead":[],"line":"c27_listo_$ke",
   "right":[act("apaga",a="$oe"),{"if":"ok","then":[act("marca",que="ok"),{"wait":400},say("c27_listo_$kf"),act("apaga",a="$of")],"else":[act("enciende",a="$of"),{"wait":600},act("apaga",a="$of")]}],
   "wrong":[act("apaga",a="$of"),act("derrama",a="$oe")]+X+["c27_no_mira_$ke"]}],
 "final":[{"dots":8},act("sirve27"),"c26_comida_lista",act("final27",suelto=1),"c27_comen",act("ya"),say("cq_gracias_abuela",300),act("fin")],
 "leer":["c27_hace_comida","c27_una_olla","c27_otra_olla","c27_aqui_arroz","c27_aqui_hab","c27_abuela_dame_arroz","c27_cq_pone_arroz","c27_ab_hace_arroz","c27_luis_dame_hab","c27_luis_hace_hab","c27_cq_arroz","c27_mas_arroz","c27_cq_hab","c27_mas_hab",
  "c27_listo_arroz","c27_listo_hab","c27_familia_hambre","c27_familia_come","c27_luis_hambre","c26_comida_lista","c27_comen","cq_gracias_abuela"]}
json.dump(s27,open("cuentos/arroz-con-habichuelas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 28. El pollo y el huevo ----------------
c=dict(comunes)
PZ={"pollo":"el pollo","huevo":"el huevo"}; MA=lambda t:D("mama","Mamá",t)
c.update({"c28_hace":N("Abuela hace pollo y un huevo."),"c28_aqui_pollo":N("Aquí hay pollo."),"c28_aqui_huevo":N("Y aquí hay un huevo."),"c28_huele_bien":N("¡Mmm! ¡Huele bien!"),"c28_toma_sal":AB("Toma la sal, Coquí."),
 "c28_ponle_pollo":AB("Ponle sal al pollo."),"c28_ponle_huevo":AB("Y ponle sal al huevo."),"c28_pollo_tiene_sal":N("Ahora el pollo tiene sal."),"c28_huevo_tiene_sal":N("Ahora el huevo tiene sal."),
 "c28_mama_huele":MA("¡Mmm! ¡Huele bien!"),"c28_ab_mira":AB("Coquí, mira el pollo y el huevo."),"c28_cq_pollo":T("¡Abuela, el pollo!"),"c28_cq_huevo":T("¡Abuela, el huevo!"),"c28_ab_gracias":AB("¡Gracias, Coquí!"),
 "c28_bebe_quiere_pollo":MA("El bebé quiere el pollo."),"c28_bebe_quiere_huevo":MA("El bebé quiere el huevo."),"c28_ahora_bebe_huevo":MA("Ahora el bebé quiere el huevo."),"c28_bebe_come_pollo":N("El bebé come el pollo."),"c28_bebe_come_huevo":N("El bebé come el huevo."),
 "c28_luis_huele":L("¡Mmm! ¡Huele a pollo!"),"c28_carmen_huele":CA("¡Sí! ¡Huele bien!"),"c28_aqui_mas":AB("Aquí hay más."),"c28_no_hay":AB("No hay más."),
 "c28_para_coqui":AB("Y esto es para Coquí."),"c28_bebe_come":N("El bebé come."),"c28_cq_fin":T("¡Huele bien, abuela!")})
for k in PZ:
    c["c28_no_negro_"+k]=N("No, Coquí. Mira. %s está negro."%PZ[k].capitalize()); c["c28_carmen_mas_"+k]=CA("Más sal para %s, por favor."%PZ[k])
    c["c28_no_carmen_sal_"+k]=N("No, Coquí. Mira. Carmen quiere sal para %s."%PZ[k]); c["c28_no_bebe_"+k]=N("No, Coquí. Mira. El bebé quiere %s."%PZ[k])
DP=["di_pollo","di_huevo"]; VP={"di_pollo":"c28_cq_pollo","di_huevo":"c28_cq_huevo"}; DS=["salpollo","salhuevo"]
s28={"id":"el-pollo-y-el-huevo","title":"El pollo y el huevo","place":"La cocina","scene":"estufa","next":"cuidado",
 "goal":"Get every piece onto a plate golden and tasting right.","stake":{"thing":"comida","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["pollo","huevo","sal","huele"],"back_again":["hace","comida","más","por favor","para","quiere","tiene","ahora","mira","negro","bebé","hay","aquí","come","gracias","toma"],
 "also_heard":["huele a","no hay más","ponle"],"names":BASE,"clips":c,
 "beats":[act("inicio28"),{"wait":500},"c28_hace",tw("sarten"),"c28_aqui_pollo","c28_aqui_huevo",tw(None),"c28_huele_bien",act("toma28",suelto=1),"c28_toma_sal",act("ya"),
  {"dots":1},ask("salpollo","c28_ponle_pollo",[],[act("sala",k="pollo",suelto=1),"c28_pollo_tiene_sal",act("ya")],resp=DS,baraja=True),
  ask("salhuevo","c28_ponle_huevo",[act("toma28",deja=1)],[act("sala",k="huevo",suelto=1),"c28_huevo_tiene_sal",act("ya")],resp=DS,baraja=True),
  {"dots":2},act("entramama"),"c28_mama_huele","c28_ab_mira",act("mira28"),act("humo",k="pollo"),
  ask("di_pollo",None,["c28_ab_gracias"],[act("voltea",k="pollo",vuelta=1)],resp=DP,baraja=True,voces=VP,said={"di_pollo":"c28_cq_pollo"}),
  act("mira28"),act("humo",k="huevo"),
  ask("di_huevo",None,[],[act("voltea",k="huevo",vuelta=1)],resp=DP,baraja=True,voces=VP,said={"di_huevo":"c28_cq_huevo"}),
  {"dots":3},act("platobebe"),
  ask("pzpollo","c28_bebe_quiere_pollo",["c28_bebe_come_pollo"],[act("dabebe",k="pollo")]),
  ask("pzhuevo","c28_ahora_bebe_huevo",["c28_bebe_come_huevo",act("madrecome")],[act("dabebe",k="huevo")]),
  # the turn
  {"dots":4},act("entran28"),"c28_luis_huele","c28_carmen_huele",tw("bandeja"),"c28_aqui_mas",tw(None),CARD,{"wait":400},
  # A: the smoke. He calls the piece that smokes; abuela turns round into the smoke and turns the one he called
  {"dots":5},act("par"),"c28_ab_mira",act("mira28"),{"draw":"sa","options":["pollo","huevo"],"other":"oa"},act("humo",k="$sa"),
  {"decide":"say","options":DP,"baraja":True,"pick":"di_$sa","tests":"$sa","voces":VP,"said":VP,"lead":[],"line":None,
   "right":[{"if":"ok","then":[act("voltea",k="$sa",vuelta=1),act("marca",que="ok"),act("voltea",k="$oa")]},act("sirve28",a="luis"),{"if":"ok","then":[],"else":[act("cara",a="luis")]},act("come28",a="luis")],
   "wrong":[act("voltea",k="$x",vuelta=1),act("quema28",k="$sa")]+X+["c28_no_negro_$sa"]},
  # B: more salt. One piece of this pair got none; Carmen has tasted both, and names it
  {"dots":6},{"draw":"sb","options":["pollo","huevo"]},{"calc":"rb","cond":"sb=pollo","then":"salpollo","else":"salhuevo"},act("par",sinsal="$sb"),act("voltea",k="los dos",vuelta=1),act("sirve28",a="carmen"),act("muerde",a="carmen"),
  {"decide":"say","options":DS,"baraja":True,"pick":"$rb","tests":"$sb","lead":[],"line":"c28_carmen_mas_$sb",
   "right":[act("salplato",a="carmen",k="$sb"),ok(),act("piensa28",quien="carmen"),act("come28",a="carmen")],
   "wrong":[act("salplato",a="carmen",k="$x"),act("cara",a="carmen"),act("piensa28",quien="carmen",k="$sb")]+X+["c28_no_carmen_sal_$sb"]},
  # C: for the baby. The other piece of the last pair is the frog's
  {"dots":7},act("par"),act("vacia28"),"c28_no_hay",act("ultimo"),{"draw":"sc","options":["pollo","huevo"]},{"calc":"tc","cond":"sc=pollo","then":"pzpollo","else":"pzhuevo"},
  {"decide":"do","options":["pzpollo","pzhuevo"],"pick":"$tc","tests":"$sc","lock":True,"lead":[],"line":"c28_bebe_quiere_$sc",
   "right":[act("piensa28",quien="bebe"),act("dabebe",k="$sc"),{"if":"ok","then":[act("marca",que="ok"),act("parami",suelto=1),"c28_para_coqui",act("ya")]}],
   "wrong":[act("dabebe",k="$x",tira=1),act("piensa28",quien="bebe",k="$sc")]+X+["c28_no_bebe_$sc"]}],
 "final":[{"dots":8},act("final28"),"c28_bebe_come",say("c28_cq_fin",300),act("fin")],
 "leer":["c28_hace","c28_aqui_pollo","c28_aqui_huevo","c28_huele_bien","c28_toma_sal","c28_ponle_pollo","c28_pollo_tiene_sal","c28_ponle_huevo","c28_huevo_tiene_sal","c28_mama_huele","c28_ab_mira","c28_cq_pollo","c28_ab_gracias","c28_cq_huevo",
  "c28_bebe_quiere_pollo","c28_bebe_come_pollo","c28_ahora_bebe_huevo","c28_bebe_come_huevo","c28_luis_huele","c28_carmen_huele","c28_aqui_mas","c28_no_hay","c28_para_coqui","c28_bebe_come","c28_cq_fin"]}
json.dump(s28,open("cuentos/el-pollo-y-el-huevo.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 29. ¡Cuidado! ----------------
c=dict(comunes)
CH={"cal":"chocolate caliente","frio":"chocolate frío"}; NOMM={"abuelo":"Abuelo","mama":"Mamá","papa":"Papá","carmen":"Carmen"}
c.update({"c29_olla_caliente":N("La olla está caliente."),"c29_aqui_cal":N("Aquí hay chocolate caliente."),"c29_aqui_frio":N("Y aquí hay chocolate frío."),
 "c29_luis_ya":L("¡Ya está!"),"c29_ab_cuidado_caliente":AB("¡Cuidado! Está caliente."),
 "c29_ab_cuidado":AB("¡Cuidado, Coquí!"),"c29_cq_espera":N("Coquí espera."),"c29_ab_ya":AB("¡Ya está, Coquí!"),
 "c29_quien_cal":L("¿Quién quiere chocolate caliente?"),"c29_quien_frio":L("¿Quién quiere chocolate frío?"),"c29_ay_luis":AB("¡Ay, Luis!"),
 "c29_no_cuidado":N("No, Coquí. Mira. No está listo."),"c29_no_ya":N("No, Coquí. Mira. Está negro."),
 "c29_ya_fin":AB("¡Ya está!"),"c29_cq_carmen":T("¡Carmen, cuidado! Está caliente.")})
for p in NOMM:
    for k in CH:
        c["c29_%s_quiere_%s"%(p,k)]=D(p,NOMM[p],"Quiero %s."%CH[k]); c["c29_no_%s_quiere_%s"%(p,k)]=N("No, Coquí. Mira. %s quiere %s."%(NOMM[p],CH[k])); c["c29_%s_bebe_%s"%(p,k)]=N("%s bebe %s."%(NOMM[p],CH[k]))
DO=["espera","saca"]
s29={"id":"cuidado","title":"¡Cuidado!","place":"La cocina","scene":"estufa","next":None,
 "goal":"Fry the fritters, and bring everybody the chocolate he wants.","stake":{"thing":"merienda","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["caliente","frío","cuidado","ya"],"back_again":["olla","chocolate","quiero","quiere","¿quién?","bebe","toma","come","mira","espera","hay","aquí","está","listo"],
 "also_heard":["ya está"],"names":BASE,"palabras":{"cal":"caliente","frio":"frío"},"clips":c,
 "beats":[act("inicio29"),{"wait":500},tw("olla1"),"c29_olla_caliente","c29_aqui_cal",tw("jarra"),"c29_aqui_frio",tw(None),
  {"dots":1},act("viene",quien="papa"),act("copa"),
  ask("olla1","c29_papa_quiere_cal",["c29_papa_bebe_cal",act("aparte",quien="papa")],[act("ranallena",k="cal",a="papa",suelto=1),"c29_ab_cuidado_caliente",act("ya")]),
  act("viene",quien="carmen"),act("copa"),
  ask("jarra","c29_carmen_quiere_frio",["c29_carmen_bebe_frio",act("aparte",quien="carmen")],[act("ranallena",k="frio",a="carmen")]),
  {"dots":2},act("frie"),act("asoma"),
  ask("espera","c29_ab_cuidado",[],["c29_cq_espera"],resp=DO,baraja=True),
  act("asoma"),
  ask("saca","c29_ab_ya",[],[act("saca29")],resp=DO,baraja=True),
  {"dots":3},act("viene",quien="abuelo",suelto=1),act("viene",quien="mama",lugar=2),act("ya"),act("piensa",quien="abuelo",k="cal"),act("piensa",quien="mama",k="frio"),
  ask("abuelo","c29_quien_cal",["c29_abuelo_bebe_cal"],[act("llena",k="cal"),say("c29_luis_ya"),act("luisda",a="abuelo",suelto=1),"c29_ab_cuidado_caliente",act("ya")]),
  ask("mama","c29_quien_frio",["c29_mama_bebe_frio",act("aparte",quien="abuelo,mama")],[act("llena",k="frio"),say("c29_luis_ya"),act("luisda",a="mama")]),
  # the turn: Luis eats the first fritter
  {"dots":4},act("luiscome"),"c29_ay_luis",CARD,{"wait":400},
  # A: what he does himself. Abuela looks into the pan, turns away to wipe the plate, and calls over her shoulder
  {"dots":5},{"draw":"da","options":["cuidado","ya"]},{"calc":"ra","cond":"da=cuidado","then":"espera","else":"saca"},act("frie"),act("asoma"),act("limpia"),
  {"decide":"say","options":DO,"baraja":True,"pick":"$ra","tests":"$da","lead":[],"line":"c29_ab_$da",
   "right":[{"if":"da=cuidado","then":[act("dora"),act("asoma"),say("c29_ab_ya")]},act("saca29"),ok()],
   "wrong":[{"if":"da=cuidado","then":[act("saca29",cae=1)],"else":[act("quema29")]}]+X+["c29_no_$da",act("frie"),act("asoma"),say("c29_ab_$da")]},
  # B: which chocolate, by what he says. The frog fills the cup himself
  {"dots":6},{"reparte":["pb","pc","pd"],"options":["papa","mama","abuelo","carmen"]},{"draw":"wb","options":["cal","frio"]},{"calc":"gb","cond":"wb=cal","then":"olla1","else":"jarra"},act("viene",quien="$pb"),act("copa"),
  {"decide":"do","options":["olla1","jarra"],"pick":"$gb","tests":"$wb","lock":True,"lead":[],"line":"c29_$pb_quiere_$wb",
   "right":[act("ranallena",k="$gb",a="$pb"),ok(),act("aparte",quien="$pb")],
   "wrong":[act("ranallena",k="$x",a="$pb"),act("niega",a="$pb"),act("piensa",quien="$pb",k="$wb"),act("luisbebe",a="$pb")]+X+["c29_no_$pb_quiere_$wb",act("copa")]},
  # C: who wants it. Two come in; one thinks of hot chocolate, the other of cold
  {"dots":7},{"draw":"wc","options":["cal","frio"],"other":"wd"},{"draw":"kc","options":["cal","frio"],"other":"kd"},
  {"calc":"tc","cond":"kc=$wc","then":"$pc","else":"$pd"},{"calc":"uc","cond":"kc=$wc","then":"$pd","else":"$pc"},
  act("viene",quien="$pc",suelto=1),act("viene",quien="$pd",lugar=2),act("ya"),act("piensa",quien="$pc",k="$wc"),act("piensa",quien="$pd",k="$wd"),
  {"decide":"do","options":["$pc","$pd"],"pick":"$tc","tests":"$kc","lock":True,"lead":[],"line":"c29_quien_$kc",
   "right":[act("llena",k="$kc"),act("luisda",a="$tc"),ok(),act("llena",k="$kd"),act("luisda",a="$uc"),act("aparte",quien="$pc,$pd")],
   "wrong":[act("llena",k="$kc"),act("luisda",a="$x",queda=1),act("niega",a="$x"),act("luisbebe",a="$x")]+X+["c29_no_$tc_quiere_$kc"]}],
 "final":[{"dots":8},act("resto29"),"c29_ya_fin",act("viene",quien="carmen"),act("final29"),say("c29_cq_carmen",300),act("fin")],
 "leer":["c29_olla_caliente","c29_aqui_cal","c29_aqui_frio","c29_papa_quiere_cal","c29_ab_cuidado_caliente","c29_papa_bebe_cal","c29_carmen_quiere_frio","c29_carmen_bebe_frio","c29_ab_cuidado","c29_cq_espera","c29_ab_ya",
  "c29_quien_cal","c29_luis_ya","c29_abuelo_bebe_cal","c29_quien_frio","c29_mama_bebe_frio","c29_ay_luis","c29_ya_fin","c29_cq_carmen"]}
json.dump(s29,open("cuentos/cuidado.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- the next-day picture pairs ----------------
NO={"x":0,"y":0,"s":1,"dy":0,"al":1,"vis":0,"bub":None,"hace":None}
RANA={"x":110,"y":157,"s":1,"dy":0,"al":1,"vis":1,"bub":None,"hace":None}
def pic(cam,**kw): return {"cam":cam,"set":dict({"cq":NO,"gente":{},"fuegos":[{},{}],"izq":{},"der":{},"basura":[],"ventana":[],"ventanacome":0,"cosas":[],"vuelos":[],"banco":0,"encima":None,"tarjeta":None,"cubo":0,"salero":0,"mat":None,"plata":None,"estante":0,"repisa":0,"olor":None},**kw)}
OLLA=lambda con:{"k":"olla","con":con,"n":2,"llama":1,"vapor":1}
SART=lambda *cosas,**kw:dict({"k":"sarten","llama":1,"cosas":[{"k":k,"v":v} for k,v in cosas]},**kw)
C0=[70,84,75.3,40]; C1=[110,84,75.3,40]; CN=[52,148,94.2,50]; CB=[60,150,75.3,40]; CAB=[84,146,113,60]; CTZ=[98,100,56.5,30]; CPL=[157,84,75.3,40]; CRA=[98,148,94.2,50]; CPA=[60,92,113,60]; CMA=[116,86,105.5,56]
nino=lambda **kw:dict({"x":84,"y":196,"dir":1},**kw); abu=lambda **kw:dict({"x":112,"y":200,"dir":1,"pose":"wave0"},**kw); mam=lambda **kw:dict({"x":176,"y":152,"dir":-1},**kw); pap=lambda **kw:dict({"x":82,"y":158,"dir":1},**kw)
PAR={"m_e_mis_hab":N("Mira mis habichuelas."),"m_e_mi_olla":N("Mira mi olla."),"m_e_mama_hace":N("Mamá hace la comida."),"m_e_el_pollo":N("Mira el pollo."),"m_e_el_huevo":N("Mira el huevo."),"m_e_la_sal":N("Mira la sal."),
 "m_e_huele_bien":N("¡Huele bien!"),"m_e_choc_caliente":N("El chocolate está caliente."),"m_e_agua_fria":N("El agua está fría."),"m_e_cuidado_luis":N("¡Cuidado, Luis!"),"m_e_ya_esta":N("¡Ya está!")}
todos={**s27["clips"],**s28["clips"],**s29["clips"],**PAR}
usa=["c27_aqui_arroz"]+list(PAR)+["muy_bien","si_muy_bien"]
FRIT=SART(("fritura","burbujas"),vapor=1)
cual={"id":"cual-estufa","title":"¿Cuál?","place":"La cocina","scene":"estufa","tipo":"cual","stake":{"thing":"none","steps":0},
 "note":"The next-day pass for La estufa.","clips":{k:todos[k] for k in usa},
 "items":[
  {"w":"arroz","say":"c27_aqui_arroz","si":pic(C0,fuegos=[OLLA("arroz"),{}]),"no":pic(C0,fuegos=[OLLA("hab"),{}])},
  {"w":"habichuelas","say":"m_e_mis_hab","si":pic(CB,gente={"luis":nino(alza={"k":"tazon","v":"hab","e":1,"dx":15,"dy":2})}),"no":pic(CB,gente={"luis":nino(alza={"k":"tazon","v":"arroz","e":1,"dx":15,"dy":2})})},
  {"w":"olla","say":"m_e_mi_olla","si":pic(CAB,gente={"abuela":abu(alza={"k":"olla","v":"vacia","e":1,"dx":26})}),"no":pic(CAB,gente={"abuela":abu(alza={"k":"sarten","e":1,"dx":30,"dy":-8})})},
  {"w":"hace","say":"m_e_mama_hace","si":pic(CMA,gente={"mama":mam(pose="wave0")},fuegos=[{},OLLA("hab")],cosas=[{"k":"cucharon","x":150,"y":113,"rot":0.7,"z":999}]),
                                   "no":pic(CMA,gente={"mama":mam(dir=1,alza={"k":"platoc","v":"ah"},come={"k":"cucharac"})},fuegos=[{},OLLA("hab")])},
  {"w":"pollo","say":"m_e_el_pollo","si":pic(CPL,plata={"x":195,"y":123,"solo":1,"items":[{"k":"muslo","v":"dorado"}]}),"no":pic(CPL,plata={"x":195,"y":123,"solo":1,"items":[{"k":"frito","v":"dorado"}]})},
  {"w":"huevo","say":"m_e_el_huevo","si":pic(C0,fuegos=[SART(("frito","dorado")),{}]),"no":pic(CN,gente={"luis":nino(alza={"k":"salero"})})},
  {"w":"sal","say":"m_e_la_sal","si":pic(CRA,cq=RANA,banco=1,mat={"x":158,"y":196,"o":{"k":"frito","v":"dorado"}},vuelos=[{"k":"salero","x":150,"y":176,"rot":0.9},{"k":"grano","x":157,"y":181},{"k":"grano","x":158,"y":187}]),
                                 "no":pic(CRA,cq=RANA,banco=1,mat={"x":158,"y":196,"o":{"k":"frito","v":"dorado"}},vuelos=[{"k":"molinillo","x":150,"y":176,"rot":0.9},{"k":"granon","x":157,"y":181},{"k":"granon","x":158,"y":187}])},
  {"w":"huele","say":"m_e_huele_bien","si":pic(CPA,gente={"papa":pap(cierra=1)},fuegos=[SART(("muslo","dorado"),("frito","dorado"),vapor=1),{}],olor=[106,104,90,117]),
                                     "no":pic(CPA,gente={"papa":pap(come={"k":"muslo","v":"dorado"})},fuegos=[SART(("frito","dorado"),vapor=1),{}])},
  {"w":"caliente","say":"m_e_choc_caliente","si":pic(CTZ,cosas=[{"k":"taza","v":"cal","x":126,"y":127,"vapor":1}]),"no":pic(CTZ,cosas=[{"k":"vasochoco","x":126,"y":127}])},
  {"w":"frío","say":"m_e_agua_fria","si":pic(CTZ,cosas=[{"k":"vasoagua","x":126,"y":127}]),"no":pic(C1,fuegos=[{},{"k":"olla","con":"agua","n":0,"llama":1,"vapor":1}])},
  {"w":"cuidado","say":"m_e_cuidado_luis","si":pic([58,90,139,74],gente={"luis":{"x":84,"y":150,"dir":1,"pose":"wave0"},"abuela":{"x":156,"y":164,"dir":-1,"pose":"wave0"}},fuegos=[FRIT,{}]),
                                         "no":pic([58,104,139,74],gente={"luis":{"x":112,"y":178,"dir":1,"pose":"offer"},"abuela":{"x":150,"y":176,"dir":-1,"pose":"offer","lleva":{"k":"platof"}}},fuegos=[FRIT,{}])},
  {"w":"ya","say":"m_e_ya_esta","si":pic(CAB,gente={"abuela":abu(alza={"k":"fuentec","v":3,"e":2,"dx":34,"dy":6})}),"no":pic(CAB,gente={"abuela":abu(alza={"k":"cuenco","e":2,"dx":34,"dy":6})})}]}
json.dump(cual,open("cuentos/cual-estufa.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# the story before this scene leads into it
p="cuentos/tengo-hambre.json"; d=json.load(open(p,encoding="utf-8"))
if d.get("next")!="arroz-con-habichuelas":
    d["next"]="arroz-con-habichuelas"; json.dump(d,open(p,"w",encoding="utf-8"),ensure_ascii=False,indent=1)

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
for st in (s27,s28,s29):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"(c(?:27|28|29)_[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
