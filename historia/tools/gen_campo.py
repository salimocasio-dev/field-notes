# El campo (place 2, scene 2): stories 15, 16, 17 and the scene's picture pairs. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/campo.md
import json,glob,os,re
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
tw=lambda k:{"set":{"twinkle":k}}
def act(_n,**k): return dict({"act":_n},**k)
pose=lambda q,p:act("pose",quien=q,que=p)
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
say=lambda c,gap=250:{"say":c,"gap":gap}
ok=lambda que="ok":{"if":"ok","then":[act("marca",que=que)]}
CARD={"set":{"tarjeta":"rondas","marcas":[None,None,None]}}
comunes={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!"),"p_n_luis":N("Este es Luis."),"p_n_carmen":N("Esta es Carmen."),
 "c_n_perro":N("Es el perro. Se llama Canelo."),"c_n_arbol":N("Es un árbol."),"c_n_parque":N("Es el parque."),
 "k_n_bola_luis":N("Es la bola de Luis."),"k_n_bola_carmen":N("Es la bola de Carmen."),"k_n_bola_coqui":N("Es la bola de Coquí."),"k_n_agua":N("Es el agua."),"k_n_cesta":N("Hay más bolas.")}
NOMBRES={"luis":"p_n_luis","carmen":"p_n_carmen","perro":"c_n_perro","arbol":"c_n_arbol","juncos":"k_n_agua","campo":"c_n_parque","coqui":"yo_coqui",
 "bola_luis":"k_n_bola_luis","bola_carmen":"k_n_bola_carmen","bola_cq":"k_n_bola_coqui","cesta":"k_n_cesta"}

# ---------------- 15. La bola ----------------
c=dict(comunes)
c.update({"c15_luis_tiene":N("Mira. Luis tiene una bola."),"c15_carmen_tiene":N("Carmen tiene una bola."),"c15_coqui_tiene":N("Y Coquí tiene una bola también."),"c15_cq_mi":T("¡Mi bola!"),
 "c15_vamos_coge":L("¡Vamos a jugar! Coquí, ¡coge la bola!"),"c15_l_tira_c_coge":N("Luis tira la bola. Coquí coge la bola."),"c15_ahora_tira":L("Ahora, ¡tira la bola!"),"c15_c_tira_l_coge":N("Coquí tira la bola. Luis coge la bola."),
 "c15_ahora_carmen":N("Ahora Carmen tiene la bola."),"c15_cq_dame":T("¡Dame la bola!"),"c15_cq_coge":T("¡Coge la bola!"),"c15_toma":CA("Toma."),"c15_cq_gracias":T("Gracias."),"c15_c_tira_ca_coge":N("Coquí tira la bola. Carmen coge la bola."),
 "c15_quien":N("¿Quién tiene la bola?"),"c15_carmen_tiene_la":N("Carmen tiene la bola."),"c15_luis_tiene_la":N("Luis tiene la bola."),"c15_luis_no":N("Luis no tiene la bola."),"c15_carmen_no":N("Carmen no tiene la bola."),
 "c15_carmen_no_luis_si":N("Carmen no tiene la bola. Luis tiene la bola."),"c15_ay_canelo":N("¡Ay! Coquí no tiene la bola. ¡Canelo tiene la bola!"),"c15_cq_canelo_dame":T("Canelo, ¡dame la bola!"),"c15_l_canelo_dame":L("Canelo, ¡dame la bola!"),
 "c15_hay_mas":L("Mira. Hay más bolas."),"c15_l_tira":L("Coquí, ¡tira la bola!"),"c15_l_coge":L("Coquí, ¡coge la bola!"),"c15_no_tira":N("No, Coquí. Luis dice: ¡Tira la bola!"),"c15_no_coge":N("No, Coquí. Luis dice: ¡Coge la bola!"),
 "c15_no_carmen_tiene":N("No, Coquí. Carmen tiene la bola."),"c15_no_luis_tiene":N("No, Coquí. Luis tiene la bola."),"c15_no_carmen_no":N("No, Coquí. Carmen no tiene la bola."),
 "c15_fin1":N("Luis tira la bola. Carmen coge la bola."),"c15_fin2":N("¿Y Canelo? ¡Canelo no suelta la bola!"),"c15_cq_ay":T("¡Ay, Canelo!")})
DI15=["di_dame","di_coge"]; VD15={"di_dame":"c15_cq_dame","di_coge":"c15_cq_coge"}; TC=["tira","coge"]
s15={"id":"la-bola","title":"La bola","place":"El parque","scene":"campo","next":"arriba-abajo",
 "goal":"Play ball with Luis and Carmen. Do not let Canelo get the ball.","stake":{"thing":"bola","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["bola","tiene","tira","coge","dame"],"back_again":["mira","vamos","toma","gracias","perro","también","no","ahora","¿quién?"],
 "also_heard":["más","no suelta"],"names":NOMBRES,"palabras":{},"clips":c,
 "beats":[act("inicio15"),{"wait":500},tw("bola_luis"),"c15_luis_tiene",tw("bola_carmen"),"c15_carmen_tiene",tw("bola_cq"),"c15_coqui_tiene",tw(None),say("c15_cq_mi",300),
  {"dots":1},ask("coge","c15_vamos_coge",["c15_l_tira_c_coge"],[act("pasa",de="luis",a="cq",b="luis")],resp=TC,baraja=True),
  ask("tira","c15_ahora_tira",["c15_c_tira_l_coge",act("bajan")],[act("pasa",de="cq",a="luis",b="luis")],resp=TC,baraja=True),
  {"dots":2},act("sellevan",quien="carmen"),"c15_ahora_carmen",
  ask("di_dame",None,[],[act("trae",quien="carmen",queda=1),say("c15_toma"),say("c15_cq_gracias"),act("acasa")],resp=DI15,baraja=True,voces=VD15,said={"di_dame":"c15_cq_dame"}),
  pose("carmen","arriba"),ask("di_coge",None,["c15_c_tira_ca_coge",act("alpie",b="cq",rueda=1)],[act("pasa",de="cq",a="carmen",b="cq")],resp=DI15,baraja=True,voces=VD15,said={"di_coge":"c15_cq_coge"}),
  {"dots":3},act("esconden",tiene="carmen"),say("c15_quien"),ask("carmen","c15_carmen_tiene_la",[],[act("ensena",quien="carmen")]),
  act("esconden",tiene="luis"),say("c15_quien"),ask("luis","c15_carmen_no",["c15_carmen_no_luis_si",act("devuelve")],[act("ensena",quien="luis"),act("ensena",quien="carmen")]),
  {"dots":4},act("turno15"),"c15_ay_canelo",say("c15_cq_canelo_dame",300),act("mueverabo"),say("c15_l_canelo_dame",300),act("mueverabo"),
  tw("cesta"),say("c15_hay_mas"),tw(None),act("nueva"),CARD,{"wait":500},
  {"dots":5},act("listoA"),{"draw":"la","options":TC},
  {"decide":"say","options":TC,"baraja":True,"pick":"$la","tests":"$la","lock":True,"lead":[],"line":"c15_l_$la",
   "right":[act("bienA",dijo="$la"),ok()],"wrong":[act("malA",dijo="$la"),"c15_no_$la",act("marca",que="pata"),{"cost":1},act("nueva",a="cq")]},
  {"dots":6},act("bajan"),{"draw":"tb","options":["luis","carmen"]},{"draw":"nb","options":["si","no"]},
  {"if":"nb=si","then":[{"calc":"lb","cond":"tb=luis","then":"c15_luis_tiene_la","else":"c15_carmen_tiene_la"},{"calc":"wb","cond":"nb=si","then":"-","else":"-"}],
   "else":[{"calc":"lb","cond":"tb=luis","then":"c15_carmen_no","else":"c15_luis_no"},{"calc":"wb","cond":"nb=si","then":"no","else":"no"}]},
  act("esconden",tiene="$tb"),say("c15_quien"),
  {"decide":"do","options":["luis","carmen"],"pick":"$tb","tests":"$wb","lock":True,"lead":[],"line":"$lb",
   "right":[act("ensena",quien="$tb"),ok(),act("devuelve")],
   "wrong":[act("ensena",quien="$x"),act("ensena",quien="$tb"),"c15_no_$tb_tiene",act("malB"),act("marca",que="pata"),{"cost":1},act("nueva"),act("esconden",tiene="$tb")]},
  {"dots":7},{"draw":"qc","options":["carmen","cq"]},{"calc":"rc","cond":"qc=carmen","then":"di_dame","else":"di_coge"},{"calc":"tc","cond":"qc=carmen","then":"dame","else":"coge"},
  {"calc":"nc","cond":"qc=carmen","then":"c15_no_carmen_tiene","else":"c15_no_carmen_no"},act("quien15",que="$qc"),
  {"decide":"say","options":DI15,"baraja":True,"pick":"$rc","tests":"$tc","voces":VD15,"said":VD15,"lead":[],
   "right":[{"if":"qc=carmen","then":[act("trae",quien="carmen")],"else":[act("pasa",de="cq",a="carmen",b="cq"),act("alpie",b="cq",rueda=1)]},ok()],
   "wrong":[act("duda",que="$qc"),"$nc",act("roba"),pose("carmen","idle"),act("marca",que="pata"),{"cost":1},
    {"if":"qc=carmen","then":[act("nueva",a="carmen")],"else":[act("nueva",a="cq"),pose("carmen","arriba")]}]}],
 "final":[{"dots":8},act("final15"),act("pasa",de="luis",a="carmen",b="luis"),"c15_fin1","c15_fin2",say("c15_cq_ay",300),act("mueverabo"),{"wait":500}],
 "leer":["c15_luis_tiene","c15_carmen_tiene","c15_coqui_tiene","c15_cq_mi","c15_vamos_coge","c15_l_tira_c_coge","c15_ahora_tira","c15_c_tira_l_coge","c15_ahora_carmen","c15_cq_dame","c15_toma","c15_cq_gracias",
  "c15_cq_coge","c15_c_tira_ca_coge","c15_quien","c15_carmen_tiene_la","c15_carmen_no","c15_carmen_no_luis_si","c15_ay_canelo","c15_cq_canelo_dame","c15_hay_mas","c15_fin1","c15_fin2","c15_cq_ay"]}
json.dump(s15,open("cuentos/la-bola.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 16. ¡Arriba! ¡Abajo! ----------------
c=dict(comunes)
c.update({"c16_mira_arriba":N("¡Mira! La bola está arriba."),"c16_l_ay":L("¡Ay, no! Mi bola está arriba, en el árbol."),"c16_luis_salta":N("Luis salta."),"c16_carmen_salta":N("Carmen salta."),"c16_canelo_salta":N("Canelo salta."),
 "c16_l_salta":L("Coquí, ¡salta!"),"c16_coqui_salta":N("¡Coquí salta! ¡Arriba!"),"c16_ahora_abajo":N("Ahora la bola está abajo."),"c16_l_donde":L("¿Dónde está la bola?"),
 "c16_cq_arriba":T("¡Está arriba!"),"c16_cq_abajo":T("¡Está abajo!"),"c16_luis_tiene":N("Luis tiene la bola."),"c16_l_vamos":L("¡Vamos a jugar!"),"c16_ca_arriba":CA("¡Está arriba!"),"c16_ca_abajo":CA("¡Está abajo!"),
 "c16_coqui_tiene":N("Coquí tiene la bola."),"c16_l_coge_arriba":L("Ahora, ¡coge la bola! ¡Por arriba!"),"c16_va_arriba":N("La bola va por arriba. Coquí salta."),"c16_l_por_abajo":L("¡Por abajo!"),"c16_l_por_arriba":L("¡Por arriba!"),
 "c16_va_abajo":N("La bola va por abajo."),"c16_l_canelo":L("Canelo, ¡por abajo!"),"c16_ay_agua":N("¡Ay, no! La bola está en el agua."),"c16_hay_mas":L("Mira. Hay más bolas."),"c16_l_carmen_arriba":L("Carmen, ¡por arriba!"),
 "c16_no_por_arriba":N("No, Coquí. Luis dice: ¡Por arriba!"),"c16_no_por_abajo":N("No, Coquí. Luis dice: ¡Por abajo!"),"c16_no_esta_arriba":N("No, Coquí. La bola está arriba."),"c16_no_esta_abajo":N("No, Coquí. La bola está abajo."),
 "c16_l_salta_coqui":L("¡Salta, Coquí!"),"c16_fin":N("Luis salta. Carmen salta. ¡Y Coquí salta, salta, salta!")})
DI16=["di_arriba","di_abajo"]; VD16={"di_arriba":"c16_cq_arriba","di_abajo":"c16_cq_abajo"}; AB=["arriba","abajo"]
s16={"id":"arriba-abajo","title":"¡Arriba! ¡Abajo!","place":"El parque","scene":"campo","next":"otra-vez",
 "goal":"Get the ball out of the tree. Then do not lose the balls to the pond.","stake":{"thing":"bola","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["arriba","abajo","salta"],"back_again":["bola","tira","coge","tiene","árbol","¿dónde está?","hay","agua","mira","ahora"],
 "also_heard":["por arriba","por abajo","va","mi","más"],"names":NOMBRES,"palabras":{},"clips":c,
 "beats":[act("inicio16"),{"wait":500},"c16_mira_arriba",say("c16_l_ay"),
  act("bajoarbol",quien="luis"),act("salta",quien="luis"),"c16_luis_salta",act("aparta",quien="luis"),
  act("bajoarbol",quien="carmen"),act("salta",quien="carmen"),"c16_carmen_salta",act("aparta",quien="carmen"),act("salta",quien="perro"),"c16_canelo_salta",
  {"dots":1},ask("salta","c16_l_salta",["c16_coqui_salta"],[act("tumba")],resp=["salta","corre"],baraja=True),
  {"dots":2},act("ruedabajo"),"c16_ahora_abajo",ask("di_abajo","c16_l_donde",["c16_luis_tiene"],[act("luisbusca",en="abajo")],resp=DI16,baraja=True,voces=VD16,said={"di_abajo":"c16_cq_abajo"}),
  {"dots":3},say("c16_l_vamos",200),act("esconde16",en="arriba"),{"ask":"arbol","lead":["c16_l_donde"],"line":"c16_ca_arriba","after":[act("busca",en="arriba")],"then":["c16_coqui_tiene",act("vuelve16")]},
  act("aluis"),act("esconde16",en="abajo"),{"ask":"juncos","lead":["c16_l_donde"],"line":"c16_ca_abajo","after":[act("busca",en="abajo")],"then":["c16_coqui_tiene"]},
  {"dots":4},act("listos"),ask("arriba","c16_l_coge_arriba",["c16_va_arriba"],[act("tiro",como="arriba",hace="arriba")],resp=AB,baraja=True),
  act("listo16"),ask("abajo","c16_l_por_abajo",["c16_va_abajo"],[act("tiro",como="abajo",hace="abajo")],resp=AB,baraja=True),
  {"dots":5},act("turno16a"),say("c16_l_canelo",200),act("turno16b"),"c16_ay_agua",act("trasturno"),
  tw("cesta"),say("c16_hay_mas",200),tw(None),act("prepcarmen"),say("c16_l_carmen_arriba",150),act("acarmen"),CARD,{"wait":400},
  {"dots":6},act("listo16"),{"draw":"la","options":AB},
  {"decide":"say","options":AB,"baraja":True,"pick":"$la","tests":"$la","lock":True,"lead":[],"line":"c16_l_por_$la",
   "right":[act("tiro",como="$la",hace="$la"),ok(),act("alacesta")],"wrong":[act("tiro",como="$la",hace="$x"),"c16_no_por_$la",act("marca",que="agua"),{"cost":1},act("listo16")]},
  {"dots":7},{"draw":"lb","options":AB},{"calc":"pb","cond":"lb=arriba","then":"arbol","else":"juncos"},{"calc":"ob","cond":"lb=arriba","then":"abajo","else":"arriba"},act("esconde16",en="$lb"),
  {"decide":"do","options":["arbol","juncos"],"pick":"$pb","tests":"$lb","lock":True,"lead":["c16_l_donde"],"line":"c16_ca_$lb",
   "right":[act("busca",en="$lb"),ok(),act("vuelve16"),act("alacesta")],
   "wrong":[act("busca",en="$ob"),"c16_no_esta_$lb",act("perrotumba"),act("marca",que="agua"),{"cost":1},act("vuelve16"),act("esconde16",en="$lb")]},
  {"dots":8},{"draw":"lc","options":AB},{"calc":"oc","cond":"lc=arriba","then":"abajo","else":"arriba"},act("sol",en="$lc"),
  {"decide":"say","options":DI16,"baraja":True,"pick":"di_$lc","tests":"$lc","voces":VD16,"said":VD16,"lead":[],"line":"c16_l_donde",
   "right":[act("luisbusca",en="$lc"),ok()],"wrong":[act("luisbusca",en="$oc"),"c16_no_esta_$lc",act("perrotumba"),act("marca",que="agua"),{"cost":1},act("sol",en="$lc")]}],
 "final":[{"dots":9},act("final16"),say("c16_l_salta_coqui",200),act("saltan"),"c16_fin",{"wait":500}],
 "leer":["c16_mira_arriba","c16_l_ay","c16_luis_salta","c16_carmen_salta","c16_canelo_salta","c16_l_salta","c16_coqui_salta","c16_ahora_abajo","c16_l_donde","c16_cq_abajo","c16_luis_tiene","c16_l_vamos","c16_ca_arriba","c16_coqui_tiene",
  "c16_ca_abajo","c16_l_coge_arriba","c16_va_arriba","c16_l_por_abajo","c16_va_abajo","c16_l_canelo","c16_ay_agua","c16_hay_mas","c16_l_carmen_arriba","c16_l_salta_coqui","c16_fin"]}
json.dump(s16,open("cuentos/arriba-abajo.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 17. ¡Otra vez! ----------------
c=dict(comunes)
c.update({"c17_canelo_tiene":N("Mira. Canelo tiene una bola."),"c17_l_es_mi":L("Es mi bola."),"c17_ca_esta_mi":CA("Esta es mi bola."),"c17_l_esta_tu":L("Coquí, esta es tu bola."),"c15_cq_mi":T("¡Mi bola!"),
 "c17_cq_es_mi":T("¡Es mi bola!"),"c17_cq_es_tu":T("¡Es tu bola!"),"c17_l_si_mi":L("Sí. Es mi bola."),"c17_l_si_tu":L("Sí, Coquí. Es tu bola."),
 "c17_ca_tira_tu":CA("Coquí, ¡tira tu bola!"),"c17_ca_tira_mi":CA("Coquí, ¡tira mi bola!"),"c17_l_tira_tu":L("Coquí, ¡tira tu bola!"),"c17_l_tira_mi":L("Coquí, ¡tira mi bola!"),
 "c17_tira_coge":N("Coquí tira la bola. Canelo coge la bola."),"c17_quiere_mas":N("Canelo quiere más."),"c17_l_otra":L("¡Otra vez!"),"c17_tira_otra":N("Coquí tira la bola otra vez."),"c17_quiere_mas_otra":N("Canelo quiere más. ¡Otra vez!"),
 "c17_l_dame":L("Coquí, ¡dame la bola!"),"c17_luis_tira_otra":N("Luis tira la bola. ¡Otra vez!"),"c17_l_no_mas_agua":L("¡No más! Canelo quiere agua."),"c17_no_mas":N("No más."),"c17_l_nomas":L("¡No más!"),
 "c17_l_otra_carmen":L("¡Otra vez, Carmen!"),"c17_l_carmen_dame":L("Carmen, ¡dame la bola!"),"c15_l_canelo_dame":L("Canelo, ¡dame la bola!"),"c17_ca_ahora_mi":CA("Ahora, ¡tira mi bola!"),"c17_ca_no_mas":CA("¡Ay! ¡No más, Canelo! ¡No más!"),
 "c17_no_l_mi":N("No, Coquí. Luis dice: ¡Tira mi bola!"),"c17_no_l_tu":N("No, Coquí. Luis dice: ¡Tira tu bola!"),"c17_no_ca_mi":N("No, Coquí. Carmen dice: ¡Tira mi bola!"),"c17_no_ca_tu":N("No, Coquí. Carmen dice: ¡Tira tu bola!"),
 "c17_no_otra":N("No, Coquí. Luis dice: ¡Otra vez!"),"c17_no_dame":N("No, Coquí. Luis dice: ¡Dame la bola!"),"c17_no_nomas":L("¡Coquí, no más! ¡No más!"),
 "c17_l_mira":L("¡Mira! Canelo tiene una bola."),"c17_no_de_luis":N("No, Coquí. Es la bola de Luis."),"c17_no_de_coqui":N("No, Coquí. Es la bola de Coquí."),
 "c17_no_quiere":N("Canelo no quiere más."),"c17_l_otra_q":L("¿Otra vez?"),"c17_cq_no_mas":T("¡No más!")})
DM=["di_mi","di_tu"]; VM={"di_mi":"c17_cq_es_mi","di_tu":"c17_cq_es_tu"}; H3=["tira","aguanta","da"]; BOLAS=["bola_luis","bola_carmen","bola_cq"]
si_mi=[pose("luis","yo"),say("c17_l_si_mi"),pose("luis","idle")]; si_tu=[pose("luis","tu"),say("c17_l_si_tu"),pose("luis","idle")]
s17={"id":"otra-vez","title":"¡Otra vez!","place":"El parque","scene":"campo","next":None,
 "goal":"Throw the ball for Canelo. Stay dry.","stake":{"thing":"seco","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["mi","tu","más","otra vez"],"back_again":["bola","tira","dame","tiene","quiere","agua","perro","no","gracias","sí"],
 "also_heard":["esta es","no más","de Luis"],"names":NOMBRES,"palabras":{"otra":"otra vez","nomas":"-"},"clips":c,
 "beats":[act("inicio17"),act("sube17"),"c17_canelo_tiene",pose("luis","offer"),say("c15_l_canelo_dame",300),act("mueverabo17"),say("c17_l_es_mi"),pose("luis","idle"),
  pose("carmen","arriba"),tw("bola_carmen"),say("c17_ca_esta_mi"),tw(None),act("carmenfila"),pose("luis","offer"),tw("bola_cq"),say("c17_l_esta_tu"),tw(None),pose("luis","idle"),say("c15_cq_mi",300),
  {"dots":1},ask("di_tu",None,[],si_mi+[act("alafila",b="luis")],resp=DM,baraja=True,voces=VM,said={"di_tu":"c17_cq_es_tu"}),
  act("perrocoge",b="cq"),ask("di_mi",None,[],si_tu+[act("alafila",b="cq")],resp=DM,baraja=True,voces=VM,said={"di_mi":"c17_cq_es_mi"}),
  {"dots":2},ask("bola_cq","c17_ca_tira_tu",["c17_tira_coge"],[act("tira17",b="cq")]),ask("bola_carmen","c17_ca_ahora_mi",[],[act("tira17",b="carmen")]),
  {"dots":3},act("empuja"),"c17_quiere_mas",ask("tira","c17_l_otra",["c17_tira_otra",act("ladra",n=2),"c17_quiere_mas_otra"],[act("tira17",b="cq",aire=1)],resp=H3,baraja=True),
  ask("da","c17_l_dame",["c17_luis_tira_otra"],[act("da17")],resp=H3,baraja=True),
  act("jadea"),ask("aguanta","c17_l_no_mas_agua",["c17_no_mas"],[act("aguanta")],resp=H3,baraja=True,quieto=True),
  {"dots":4},act("turno17"),say("c17_l_otra_carmen"),{"wait":500},say("c17_l_carmen_dame"),act("sacude",junto="carmen"),say("c17_ca_no_mas"),act("rien"),act("trasturno17"),CARD,{"wait":400},
  {"dots":5},{"draw":"ba","options":["luis","carmen","cq"]},{"draw":"qx","options":["l","ca"]},   # each of the three balls is the right one as often as the others
  {"if":"ba=cq","then":[{"calc":"qa","cond":"qx=l","then":"l","else":"ca"},{"calc":"pa","cond":"ba=cq","then":"tu","else":"tu"}],"else":[{"calc":"qa","cond":"ba=luis","then":"l","else":"ca"},{"calc":"pa","cond":"ba=cq","then":"mi","else":"mi"}]},
  {"calc":"ra","cond":"ba=cq","then":"bola_cq","else":"bola_$ba"},
  {"decide":"do","options":BOLAS,"pick":"$ra","tests":"$pa","lock":True,"lead":[],"line":"c17_$qa_tira_$pa",
   "right":[act("tira17",b="$ra"),ok()],"wrong":[act("malA17",b="$x"),{"if":"qa=l","then":[act("luisno")]},"c17_no_$qa_$pa",act("sacude",junto="cq"),act("marca",que="gota"),{"cost":1},act("vuelvefila",b="$x")]},
  {"dots":6},act("empuja"),{"draw":"lb","options":["otra","dame","nomas"]},
  {"if":"lb=otra","then":[{"calc":"rb","cond":"lb=otra","then":"tira","else":"tira"}],"else":[{"calc":"rb","cond":"lb=dame","then":"da","else":"aguanta"}]},{"calc":"qb","cond":"lb=nomas","then":"1","else":"0"},
  {"decide":"say","options":H3,"baraja":True,"pick":"$rb","tests":"$lb","lock":True,"quieto":"$qb","lead":[],"line":"c17_l_$lb",
   "right":[act("hazB",que="$rb"),ok()],"wrong":[act("hazB",que="$x",mal=1),act("luisno"),"c17_no_$lb",act("sacude",junto="cq"),act("marca",que="gota"),{"cost":1}]},
  {"dots":7},{"draw":"bc","options":["luis","cq"]},{"calc":"rc","cond":"bc=cq","then":"di_mi","else":"di_tu"},{"calc":"tc","cond":"bc=cq","then":"mi","else":"tu"},{"calc":"nc","cond":"bc=cq","then":"c17_no_de_coqui","else":"c17_no_de_luis"},
  act("perrocoge",b="$bc"),
  {"decide":"say","options":DM,"baraja":True,"pick":"$rc","tests":"$tc","voces":VM,"said":VM,"lead":[],"line":"c17_l_mira",
   "right":[{"if":"bc=cq","then":si_tu+[act("alafila",b="cq"),act("tira17",b="cq")],"else":si_mi+[act("alafila",b="luis")]},ok()],
   "wrong":[act("luisno"),"$nc",act("sacude",junto="cq"),act("marca",que="gota"),{"cost":1}]}],
 "final":[{"dots":8},act("final17"),"c17_no_quiere",act("empuja2"),say("c17_l_otra_q",200),say("c17_cq_no_mas",300),act("rien"),{"wait":500}],
 "leer":["c17_canelo_tiene","c15_l_canelo_dame","c17_l_es_mi","c17_ca_esta_mi","c17_l_esta_tu","c15_cq_mi","c17_cq_es_tu","c17_l_si_mi","c17_cq_es_mi","c17_l_si_tu","c17_ca_tira_tu","c17_tira_coge","c17_ca_ahora_mi","c17_quiere_mas","c17_l_otra","c17_tira_otra",
  "c17_l_dame","c17_luis_tira_otra","c17_l_no_mas_agua","c17_no_mas","c17_l_otra_carmen","c17_l_carmen_dame","c17_ca_no_mas","c17_no_quiere","c17_l_otra_q","c17_cq_no_mas"]}
json.dump(s17,open("cuentos/otra-vez.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- ¿Cuál? for El campo ----------------
P=lambda x,y,**k:dict({"x":x,"y":y,"pose":"idle","dir":1},**k)
cq=lambda x,y,s=1,**k:dict({"x":x-16,"y":y-27,"s":s,"dy":0,"al":1,"vis":1,"bub":None},**k)
NO=cq(0,0,vis=0)
perro=lambda x,y,pose="sit",**k:dict({"x":x,"y":y,"pose":pose,"dir":1},**k)
bl=lambda k,**kw:dict({"k":k},**kw)
CP=[74,126,113,60]; CB=[100,150,75,39.8]; CT=[14,78,150,79.6]
todos={**s15["clips"],**s16["clips"],**s17["clips"],"k_c_bola":N("Es una bola."),"k_c_tiene":N("Canelo tiene la bola."),"k_c_tira":N("Luis tira la bola."),"k_c_coge":N("Carmen coge la bola."),"k_c_salta":N("El perro salta."),
 "k_c_dame":D("carmen","Carmen","¡Dame la bola!"),"k_c_mi":L("Es mi bola."),"k_c_tu":D("carmen","Carmen","Luis, es tu bola."),"k_c_arriba":N("La bola está arriba."),"k_c_abajo":N("Coquí está abajo."),"k_c_mas":N("Canelo quiere más.")}
todos["k_c_mi"]=todos["c17_l_es_mi"]; todos["k_c_mas"]=todos["c17_quiere_mas"]
usa=["k_c_bola","k_c_tiene","k_c_tira","k_c_coge","k_c_salta","k_c_dame","c17_l_es_mi","k_c_tu","k_c_arriba","k_c_abajo","c17_quiere_mas","muy_bien","si_muy_bien"]
cual={"id":"cual-campo","title":"¿Cuál?","place":"El parque","scene":"campo","tipo":"cual","stake":{"thing":"none","steps":0},
 "note":"The next-day pass for El campo. 'Otra vez' has no pair: a still picture cannot show 'again'.","clips":{k:todos[k] for k in usa},
 "items":[
  {"w":"bola","say":"k_c_bola","si":{"cam":CB,"set":{"bolas":{"a":bl("L",x=137,y=178)},"cq":NO}},"no":{"cam":CB,"set":{"flor":[137,178],"cq":NO}}},
  {"w":"tiene","say":"k_c_tiene","si":{"cam":CP,"set":{"perro":perro(124,182,"lie"),"bolas":{"a":bl("q",x=138,y=183)},"cq":NO}},
   "no":{"cam":CP,"set":{"perro":perro(124,182,"run",dy=8),"bolas":{"a":bl("q",x=142,y=183,z=40)},"cq":NO}}},
  {"w":"tira","say":"k_c_tira","si":{"cam":CP,"set":{"gente":{"luis":P(104,182,pose="offer")},"bolas":{"a":bl("L",x=154,y=182,z=30,vuela=[1,0])},"cq":NO}},
   "no":{"cam":CP,"set":{"gente":{"luis":P(104,182,pose="arriba")},"bolas":{"a":bl("L",x=109,y=183,z=52,vuela=[0,1])},"cq":NO}}},
  {"w":"coge","say":"k_c_coge","si":{"cam":CP,"set":{"gente":{"carmen":P(130,182,pose="arriba")},"bolas":{"a":bl("C",x=135,y=183,z=50,vuela=[0,1])},"cq":NO}},
   "no":{"cam":CP,"set":{"gente":{"carmen":P(118,182,pose="offer")},"bolas":{"a":bl("C",x=164,y=182,z=30,vuela=[1,0])},"cq":NO}}},
  {"w":"salta","say":"k_c_salta","si":{"cam":CB,"set":{"perro":perro(137,184,"run",dy=16),"cq":NO}},"no":{"cam":CB,"set":{"perro":perro(137,184,"run",polvo=1),"cq":NO}}},
  {"w":"dame","say":"k_c_dame","si":{"cam":CP,"set":{"gente":{"carmen":P(150,182,pose="offer",dir=-1)},"bolas":{"a":bl("q",con="cq")},"cq":cq(104,182)}},
   "no":{"cam":CP,"set":{"gente":{"carmen":P(150,182,pose="offer",dir=-1)},"bolas":{"a":bl("q",con="carmen")},"cq":cq(104,182)}}},
  {"w":"mi","say":"c17_l_es_mi","si":{"cam":CP,"set":{"gente":{"luis":P(110,182,pose="yo")},"bolas":{"a":bl("L",con="luis"),"b":bl("q",x=152,y=184)},"cq":cq(160,180)}},
   "no":{"cam":CP,"set":{"gente":{"luis":P(110,182,pose="tu")},"bolas":{"a":bl("L",x=92,y=184),"b":bl("q",x=140,y=184)},"cq":cq(160,180)}}},
  {"w":"tu","say":"k_c_tu","si":{"cam":CP,"set":{"gente":{"carmen":P(112,182,pose="tu"),"luis":P(150,182,dir=-1)},"bolas":{"a":bl("L",con="luis"),"b":bl("C",x=94,y=184)},"cq":NO}},
   "no":{"cam":CP,"set":{"gente":{"carmen":P(112,182,pose="yo"),"luis":P(150,182,dir=-1)},"bolas":{"a":bl("L",con="luis"),"b":bl("C",con="carmen")},"cq":NO}}},
  {"w":"arriba","say":"k_c_arriba","si":{"cam":[4,84,113,60],"set":{"bolas":{"a":bl("L",x=64,y=152,z=33)},"cq":NO}},"no":{"cam":[120,150,113,60],"set":{"bolas":{"a":bl("L",x=176,y=196)},"cq":NO}}},
  {"w":"abajo","say":"k_c_abajo","si":{"cam":CT,"set":{"cq":cq(96,154)}},"no":{"cam":CT,"set":{"cq":cq(62,114,.9)}}},
  {"w":"más","say":"c17_quiere_mas","si":{"cam":[108,150,113,60],"set":{"perro":perro(160,188,"husmea",dir=-1,mojado=1),"bolas":{"a":bl("q",x=143,y=189)},"cq":cq(124,186)}},
   "no":{"cam":[108,150,113,60],"set":{"perro":perro(178,197,"eat",dir=1,mojado=1),"bolas":{"a":bl("q",x=143,y=189)},"cq":cq(124,186)}}}]}
json.dump(cual,open("cuentos/cual-campo.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# the story before this scene leads into it
p="cuentos/rapido-despacio.json"; d=json.load(open(p,encoding="utf-8"))
if d.get("next")!="la-bola":
    d["next"]="la-bola"; json.dump(d,open(p,"w",encoding="utf-8"),ensure_ascii=False,indent=1)

# clip ids are global: the same id must have the same text everywhere
seen={}; clash=0; new=0; chars=0
for f in sorted(glob.glob("cuentos/*.json")):
    if "zz-" in f: continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items():
        key=(cl.get("who"),cl.get("text"))
        if cid in seen and seen[cid]!=key: print("CLASH",cid,seen[cid],key,f); clash+=1
        seen.setdefault(cid,key)
for cid,(who,text) in seen.items():
    if not os.path.exists(f"audio/{cid}.mp3"): new+=1; chars+=len(text)
print(len(seen),"clips,",new,"new,",chars,"characters to record,",clash,"clashes")
for st in (s15,s16,s17):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"(c1[567]_[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
