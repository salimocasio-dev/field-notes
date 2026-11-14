# La mesa (place 3, scene 1): stories 24, 25, 26 and the scene's picture pairs. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/mesa.md
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
def mira(k): return [tw(k),{"wait":700},tw(None)]   # somebody twinkles for a moment: this is the one
NOM={"abuelo":"Abuelo","mama":"Mamá","papa":"Papá","carmen":"Carmen","luis":"Luis"}; nom=lambda p:NOM[p].lower() if p in("abuelo","mama","papa") else NOM[p]
nomm={"abuelo":"abuelo","mama":"mamá","papa":"papá","carmen":"Carmen"}
comunes={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!"),"p_n_luis":N("Este es Luis."),"p_n_carmen":N("Esta es Carmen."),"abuela":N("Esta es abuela."),
 "esta_es_mama":N("Esta es mamá."),"n_papa":N("Este es papá."),"n_abuelo":N("Este es abuelo."),"n_mesa":N("Es la mesa."),"m_n_bebe":N("Es el bebé."),"m_n_cocina":N("Es la cocina."),"c_n_perro":N("Es el perro. Se llama Canelo."),
 "cq_gracias_abuela":T("¡Gracias, abuela!")}
# What a free touch names. The things that decide a round (plates, cups, spoon, fork, knife, food, water) are never named.
BASE={"luis":"p_n_luis","carmen":"p_n_carmen","coqui":"yo_coqui","abuela":"abuela","mama":"esta_es_mama","papa":"n_papa","abuelo":"n_abuelo","mesa":"n_mesa","bebe":"m_n_bebe","cocina":"m_n_cocina","perro":"c_n_perro"}
T3=["cuchara","tenedor","cuchillo"]; ART={"cuchara":"la cuchara","tenedor":"el tenedor","cuchillo":"el cuchillo"}; UN={"cuchara":"Una cuchara","tenedor":"Un tenedor","cuchillo":"Un cuchillo","plato":"Un plato","taza":"Una taza"}
SIN={"cuchara":"cuchara","tenedor":"tenedor","cuchillo":"cuchillo","plato":"plato","taza":"taza"}

# ---------------- 24. La mesa ----------------
c=dict(comunes)
c.update({"c24_esta_mesa":N("Esta es la mesa."),"c24_aqui_plato":N("Aquí hay un plato."),"c24_aqui_taza":N("Y aquí hay una taza."),"c24_familia":N("La familia se sienta."),"c24_bebe_mama":N("El bebé está con mamá."),
 "c24_plato_para_abuelo":AB("Un plato para abuelo."),"c24_cq_pone_plato":N("Coquí pone el plato en la mesa."),"c24_ab_pone_bizcocho":N("Abuela pone el bizcocho en el plato."),
 "c24_cq_plato":T("¡Un plato!"),"c24_cq_taza":T("¡Una taza!"),"c24_luis_pone_taza":N("Luis pone la taza en la mesa."),"c24_y_chocolate":N("Y el chocolate, en la taza."),
 "c24_quien_no_taza":AB("¿Quién no tiene taza?"),"c24_quien_no_plato":AB("¿Quién no tiene plato?"),"c24_ahora_mama":N("Ahora mamá tiene un plato y una taza."),"c24_ahora_papa":N("Ahora papá tiene una taza y un plato."),
 "c24_cq_pone_taza":N("Coquí pone la taza en la mesa."),"c24_luis_pone_plato":N("Luis pone el plato en la mesa."),
 "c24_ay_bebe":N("¡Ay, no! ¡El bebé!"),"c24_otra_vez":AB("¡Otra vez!"),"c24_cq_pone_mesa":N("Coquí pone la mesa."),
 "c24_mesa_lista":N("La mesa está lista."),"c24_a_comer":AB("¡A comer!")})
for p in ("mama","papa","carmen"):
    for k in ("plato","taza"):
        c["c24_%s_para_%s"%(k,p)]=AB("%s para %s."%(UN[k],nomm[p])); c["c24_no_%s_%s"%(p,k)]=N("No, Coquí. Mira. %s no tiene %s."%(NOM[p],k))
DV=["di_plato","di_taza"]; VV={"di_plato":"c24_cq_plato","di_taza":"c24_cq_taza"}
s24={"id":"la-mesa","title":"La mesa","place":"La cocina","scene":"mesa","next":"la-cuchara",
 "goal":"Get a plate and a cup to each place, so that abuela can serve.","stake":{"thing":"merienda","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["mesa","plato","taza","pone"],"back_again":["abuela","abuelo","mamá","papá","bebé","familia","bizcocho","para","tiene","hay","aquí","no","mira","otra vez","gracias","¿quién?","se sienta"],
 "also_heard":["chocolate","lista","a comer"],"names":BASE,"clips":c,
 "beats":[act("inicio24"),{"wait":500},tw("mesa"),"c24_esta_mesa",act("muestra",k="plato"),tw("muestra"),"c24_aqui_plato",act("muestra",k="taza"),tw("muestra"),"c24_aqui_taza",tw(None),act("muestra",k=""),
  act("entran24",suelto=1),"c24_familia",act("ya"),tw("bebe"),"c24_bebe_mama",tw(None),
  {"dots":1},act("abuelaa",a="abuelo",sirve=1)]+mira("abuelo")+[
  ask("platos","c24_plato_para_abuelo",[act("sirve",a="abuelo",k="plato",suelto=1),"c24_ab_pone_bizcocho",act("ya")],[act("pon",k="plato",a="abuelo",suelto=1),"c24_cq_pone_plato",act("ya")]),
  act("casa")]+mira("abuelo")+[
  ask("di_taza",None,[act("sirve",a="abuelo",k="taza",suelto=1),"c24_y_chocolate",act("ya")],[act("luispone",k="taza",a="abuelo",suelto=1),"c24_luis_pone_taza",act("ya")],resp=DV,baraja=True,voces=VV,said={"di_taza":"c24_cq_taza"}),
  {"dots":2},act("abuelaa",centro=1),act("reparte24",p="mama",t="papa"),
  ask("mama","c24_quien_no_taza",["c24_ahora_mama"],[act("pon",k="taza",a="mama")]),
  ask("papa","c24_quien_no_plato",["c24_ahora_papa"],[act("pon",k="plato",a="papa")]),
  {"dots":3},act("casa"),act("entra",quien="carmen",silla=2)]+mira("carmen")+[
  ask("tazas","c24_taza_para_carmen",[],[act("pon",k="taza",a="carmen",suelto=1),"c24_cq_pone_taza",act("ya")]),
  act("casa")]+mira("carmen")+[
  ask("di_plato",None,[],[act("luispone",k="plato",a="carmen",suelto=1),"c24_luis_pone_plato",act("ya")],resp=DV,baraja=True,voces=VV,said={"di_plato":"c24_cq_plato"}),
  {"dots":4},act("abuelaa",nada=1),act("tira24"),"c24_ay_bebe",act("recoge24"),act("corta24"),"c24_otra_vez",act("rana",x=40,y=173,suelto=1),"c24_cq_pone_mesa",act("ya"),CARD,{"wait":400},
  {"reparte":["pa","pb","pc"],"options":["mama","papa","carmen"]},
  # A: which thing
  {"dots":5},{"draw":"ka","options":["plato","taza"],"other":"oa"},{"calc":"ga","cond":"ka=plato","then":"platos","else":"tazas"},act("abuelaa",a="$pa",sirve=1)]+mira("$pa")+[
  {"decide":"do","options":["platos","tazas"],"pick":"$ga","tests":"$ka","lock":True,"lead":[],"line":"c24_$ka_para_$pa",
   "right":[{"if":"ok","then":[act("pon",k="$ka",a="$pa"),act("sirve",a="$pa",k="$ka"),act("marca",que="ok"),act("luispone",k="$oa",a="$pa"),act("sirve",a="$pa",k="$oa")],
             "else":[act("pon",k="$ka",a="$pa"),act("sirve",a="$pa",k="$oa")]}],   # the redo: the right thing comes and stays empty; what he brought first is served
   "wrong":[act("pon",k="$x",a="$pa"),act("sirvemal",a="$pa",k="$ka")]+X+[{"calc":"fa","cond":"ok","then":"1","else":"1"},"c24_no_$pa_$ka"]},
  # B: who has none. After a miss in A she asks for the other thing, so that every place holds one that is full
  {"dots":6},act("casa"),act("reparte24",p="$pb",t="$pc"),act("sirve",a="$pb",k="plato"),act("sirve",a="$pc",k="taza"),
  {"draw":"kb","options":["plato","taza"]},{"if":"fa=1","then":[{"calc":"kb","cond":"ka=plato","then":"taza","else":"plato"}]},
  {"calc":"tb","cond":"kb=plato","then":"$pc","else":"$pb"},{"calc":"tc","cond":"kb=plato","then":"$pb","else":"$pc"},{"calc":"kc","cond":"kb=plato","then":"taza","else":"plato"},
  act("abuelaa",centro=1,sirve=1),
  {"decide":"do","options":["abuelo","mama","papa","carmen"],"pick":"$tb","tests":"$kb","lock":True,"lead":[],"line":"c24_quien_no_$kb",
   "right":[act("pon",k="$kb",a="$tb"),{"if":"ok","then":[act("sirve",a="$tb",k="$kb"),act("marca",que="ok")]}],
   "wrong":[act("pon",k="$kb",a="$x"),act("sirve",a="$x",k="$kb")]+X+["c24_no_$tb_$kb"]},
  # C: he calls for what is missing
  {"dots":7},act("casa"),act("abuelaa",centro=1)]+mira("$tc")+[
  {"decide":"say","options":DV,"baraja":True,"pick":"di_$kc","tests":"$kc","voces":VV,"said":VV,"lead":[],"line":None,
   "right":[act("luispone",k="$kc",a="$tc"),act("sirve",a="$tc",k="$kc"),ok()],
   "wrong":[act("luispone",k="$x",a="$tc")]+X+["c24_no_$tc_$kc"]}],
 "final":[{"dots":8},act("lista24"),"c24_mesa_lista","c24_a_comer",act("final24"),say("cq_gracias_abuela",300),act("fin")],
 "leer":["c24_esta_mesa","c24_aqui_plato","c24_aqui_taza","c24_familia","c24_bebe_mama","c24_plato_para_abuelo","c24_cq_pone_plato","c24_ab_pone_bizcocho","c24_cq_taza","c24_luis_pone_taza","c24_y_chocolate",
  "c24_quien_no_taza","c24_ahora_mama","c24_quien_no_plato","c24_ahora_papa","c24_taza_para_carmen","c24_cq_pone_taza","c24_cq_plato","c24_luis_pone_plato","c24_ay_bebe","c24_otra_vez","c24_cq_pone_mesa","c24_mesa_lista","c24_a_comer","cq_gracias_abuela"]}
json.dump(s24,open("cuentos/la-mesa.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 25. La cuchara ----------------
c=dict(comunes)
c.update({"c25_ab_tiene_comida":N("Abuela tiene la comida."),"c25_ab_pone_comida":N("Abuela pone la comida en la mesa."),"c25_aqui_cuchara":N("Aquí hay una cuchara."),"c25_aqui_tenedor":N("Aquí hay un tenedor."),"c25_aqui_cuchillo":N("Y aquí hay un cuchillo."),
 "c25_mama_come_cuchara":N("Mamá come con la cuchara."),"c25_papa_come_tenedor":N("Papá come con el tenedor."),"c25_ahora_abuelo":N("Ahora abuelo tiene el cuchillo."),"c25_abuelo_pan":N("Abuelo come pan."),
 "c25_cq_cuchara":T("¡Una cuchara!"),"c25_cq_tenedor":T("¡Un tenedor!"),"c25_cq_cuchillo":T("¡Un cuchillo!"),"c25_carmen_come":N("Carmen come con la cuchara."),"c25_mama_come_tenedor":N("Mamá come con el tenedor."),"c25_ahora_papa":N("Ahora papá tiene el cuchillo."),
 "c25_hay_mas":AB("¡Hay más comida!"),"c25_familia_come":N("La familia come."),"c25_cq_mmm":T("¡Mmm! ¡La comida de abuela!")})
for t in T3:
    c["c25_quien_"+t]=AB("¿Quién tiene %s?"%ART[t])
    for p in ("abuelo","mama","papa","carmen"):
        c["c25_%s_para_%s"%(t,p)]=AB("%s para %s."%(UN[t],nomm[p])); c["c25_no_%s_tiene_%s"%(p,t)]=N("No, Coquí. Mira. %s tiene %s."%(NOM[p],ART[t])); c["c25_no_%s_no_%s"%(p,t)]=N("No, Coquí. Mira. %s no tiene %s."%(NOM[p],t))
D3=["di_cuchara","di_tenedor","di_cuchillo"]; V3={"di_"+t:"c25_cq_"+t for t in T3}
def come(a): return [act("util",a=a,k="x")]
s25={"id":"la-cuchara","title":"La cuchara","place":"La cocina","scene":"mesa","next":"tengo-hambre",
 "goal":"Get the right thing to eat with to whoever is eating.","stake":{"thing":"mantel","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["cuchara","tenedor","cuchillo","comida"],"back_again":["mesa","plato","pone","tiene","come","para","con","hay","aquí","ahora","más","pan","¿quién?","no","mira"],
 "also_heard":[],"names":BASE,"clips":c,
 "beats":[act("inicio25"),{"wait":500},tw("olla"),"c25_ab_tiene_comida",tw(None),act("plato25",a="mama",d="sopa",suelto=1),"c25_ab_pone_comida",act("ya"),act("plato25",a="papa",d="espa"),
  act("muestra",k="cuchara"),tw("muestra"),"c25_aqui_cuchara",act("muestra",k="tenedor"),tw("muestra"),"c25_aqui_tenedor",act("muestra",k="cuchillo"),tw("muestra"),"c25_aqui_cuchillo",tw(None),act("muestra",k=""),
  {"dots":1}]+mira("mama")+[
  ask("cuchara","c25_cuchara_para_mama",["c25_mama_come_cuchara"],[act("util",a="mama",k="cuchara"),act("come25",a="mama")],resp=T3,baraja=True),
  act("casa")]+mira("papa")+[
  ask("tenedor","c25_tenedor_para_papa",["c25_papa_come_tenedor"],[act("util",a="papa",k="tenedor"),act("come25",a="papa")],resp=T3,baraja=True),
  {"dots":2},act("casa"),act("luisalza",k="cuchillo"),act("plato25",a="abuelo",d="pan"),
  ask("luis","c25_quien_cuchillo",["c25_abuelo_pan"],[act("util",a="abuelo",de="luis"),"c25_ahora_abuelo",act("come25",a="abuelo")]),
  {"dots":3},act("casa"),act("termina25",a="mama",queda=1),act("plato25",a="carmen",d="sopa")]+mira("carmen")+[
  ask("di_cuchara",None,["c25_carmen_come"],[act("llama",a="carmen",k="cuchara"),act("come25",a="carmen")],resp=D3,baraja=True,voces=V3,said={"di_cuchara":"c25_cq_cuchara"}),
  act("termina25",a="papa",queda=1),act("plato25",a="mama",d="espa")]+mira("mama")+[
  ask("di_tenedor",None,["c25_mama_come_tenedor"],[act("llama",a="mama",k="tenedor"),act("come25",a="mama")],resp=D3,baraja=True,voces=V3,said={"di_tenedor":"c25_cq_tenedor"}),
  act("termina25",a="abuelo",queda=1),act("plato25",a="papa",d="pan")]+mira("papa")+[
  ask("di_cuchillo",None,["c25_ahora_papa"],[act("llama",a="papa",k="cuchillo"),act("come25",a="papa")],resp=D3,baraja=True,voces=V3,said={"di_cuchillo":"c25_cq_cuchillo"}),
  # the turn: Luis takes the three out in the tray; abuela has more; he comes back and deals them out again
  {"dots":4},act("termina25",a="carmen,mama,papa"),act("turno25a"),tw("olla"),"c25_hay_mas",tw(None),{"reparte":["ha","hb","hc","pn"],"options":["abuelo","mama","papa","carmen"]},act("turno25b",ha="$ha",hb="$hb",hc="$hc"),CARD,{"wait":400},
  # A: who has it
  {"dots":5},{"draw":"ta","options":T3},{"calc":"qa","cond":"ta=cuchara","then":"$ha","else":"$hb"},{"calc":"qa","cond":"ta=cuchillo","then":"$hc","else":"$qa"}]+mira("$pn")+[
  {"decide":"do","options":["$ha","$hb","$hc"],"pick":"$qa","tests":"$ta","lock":True,"lead":[],"line":"c25_quien_$ta",
   "right":[{"if":"ok","then":[act("util",a="$pn",de="$qa"),act("plato25",a="$pn",para="$ta"),act("come25",a="$pn"),act("marca",que="ok")],"else":[act("util",a="$pn",de="$qa"),act("come25",a="$pn")]}],
   "wrong":[act("util",a="$pn",de="$x"),act("plato25",a="$pn",para="$ta"),act("come25",a="$pn")]+X+["c25_no_$qa_tiene_$ta"]},
  # B: he calls for what is missing. The one who ate in round A has finished and holds his thing up again
  {"dots":6},act("casa"),act("termina25",a="$pn"),act("elige25",no="$pn"),act("plato25",a="$pb",para="$tb")]+mira("$pb")+[
  {"decide":"say","options":D3,"baraja":True,"pick":"di_$tb","tests":"$tb","voces":V3,"said":V3,"lead":[],"line":None,
   "right":[act("llama",a="$pb",k="$tb"),act("come25",a="$pb"),ok()],
   "wrong":[act("llama",a="$pb",k="$x"),act("come25",a="$pb")]+X+["c25_no_$pb_no_$tb"]},
  # C: which one, by its picture
  {"dots":7},act("casa"),act("termina25",a="$pb"),{"draw":"tc","options":T3}]+mira("$qa")+[
  {"decide":"say","options":T3,"baraja":True,"pick":"$tc","tests":"$tc","lead":[],"line":"c25_$tc_para_$qa",
   "right":[{"if":"ok","then":[act("util",a="$qa",k="$tc"),act("plato25",a="$qa",para="$tc"),act("come25",a="$qa"),act("marca",que="ok")],"else":[act("util",a="$qa",k="$tc"),act("come25",a="$qa")]}],
   "wrong":[act("util",a="$qa",k="$x"),act("plato25",a="$qa",para="$tc"),act("come25",a="$qa")]+X+["c25_no_$qa_no_$tc"]}],
 "final":[{"dots":8},act("pan25"),"c25_familia_come",say("c25_cq_mmm",300),act("fin")],
 "leer":["c25_ab_tiene_comida","c25_ab_pone_comida","c25_aqui_cuchara","c25_aqui_tenedor","c25_aqui_cuchillo","c25_cuchara_para_mama","c25_mama_come_cuchara","c25_tenedor_para_papa","c25_papa_come_tenedor","c25_quien_cuchillo","c25_ahora_abuelo","c25_abuelo_pan",
  "c25_cq_cuchara","c25_carmen_come","c25_cq_tenedor","c25_mama_come_tenedor","c25_cq_cuchillo","c25_ahora_papa","c25_hay_mas","c25_familia_come","c25_cq_mmm"]}
json.dump(s25,open("cuentos/la-cuchara.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 26. Tengo hambre ----------------
c=dict(comunes)
H={"hambre":"¡Tengo hambre!","sed":"¡Tengo sed!"}
c.update({"c26_esta_cocina":N("Esta es la cocina de abuela."),"c26_ab_en_cocina":N("Abuela está en la cocina."),"c26_comida_lista":N("La comida está lista."),"c26_ab_listo":AB("¡Listo!"),
 "c26_luis_entra":N("Luis entra a la cocina."),"c26_luis_hambre":L(H["hambre"]),"c26_luis_tiene_hambre":N("Luis tiene hambre. Luis come."),"c26_carmen_sed":CA(H["sed"]),"c26_carmen_tiene_sed":N("Carmen tiene sed. Carmen bebe agua."),
 "c26_y_tu":AB("¿Y tú, Coquí?"),"c26_cq_hambre":T(H["hambre"]),"c26_cq_sed":T(H["sed"]),"c26_toma_agua":AB("Toma agua, Coquí."),"c26_y_ahora":AB("¿Y ahora?"),
 "c26_luis_sed":L(H["sed"]),"c26_carmen_hambre":CA(H["hambre"]),"c26_carmen_tiene_hambre":N("Carmen tiene hambre. Carmen come."),
 "c26_canelo_hambre":N("Canelo tiene hambre."),"c26_no_canelo":AB("No, Canelo. Esa es la comida de la familia."),
 "c26_no_tu_hambre":N("No, Coquí. Mira. Tú tienes hambre."),"c26_no_tu_sed":N("No, Coquí. Mira. Tú tienes sed."),
 "c26_familia_cocina":N("La familia come en la cocina."),"c26_y_canelo":AB("¿Y Canelo?"),"c26_cq_canelo":T("¡Canelo está contento!")})
for p in ("abuelo","mama","papa"):
    for w in ("hambre","sed"):
        c["c26_%s_%s"%(p,w)]=D(p,NOM[p],H[w]); c["c26_no_%s_%s"%(p,w)]=N("No, Coquí. Mira. %s tiene %s."%(NOM[p],w))
DH=["di_hambre","di_sed"]; VH={"di_hambre":"c26_cq_hambre","di_sed":"c26_cq_sed"}
s26={"id":"tengo-hambre","title":"Tengo hambre","place":"La cocina","scene":"mesa","next":"arroz-con-habichuelas",
 "goal":"Bring each one what he asks for: food, or water.","stake":{"thing":"almuerzo","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["tengo hambre","tengo sed","listo","cocina"],"back_again":["comida","agua","plato","vaso","toma","gracias","come","bebe","¿y tú?","ahora","perro","contento","familia","entra"],
 "also_heard":["tiene hambre","tiene sed","tienes","lista","esa"],"names":BASE,"palabras":{"hambre":"tengo hambre","sed":"tengo sed"},"clips":c,
 "beats":[act("inicio26"),{"wait":500},tw("cocina"),"c26_esta_cocina",tw("abuela"),"c26_ab_en_cocina",tw(None),act("tapa26"),"c26_comida_lista",
  act("llena26",n=2),"c26_ab_listo",act("abuelaa"),
  {"dots":1},act("entra",quien="luis",silla=1,suelto=1),"c26_luis_entra",act("ya"),
  ask("comidas","c26_luis_hambre",["c26_luis_tiene_hambre"],[act("lleva26",a="luis",k="comida"),act("toma26",a="luis")]),
  act("entra",quien="carmen",silla=2),
  ask("vasos","c26_carmen_sed",["c26_carmen_tiene_sed"],[act("lleva26",a="carmen",k="agua"),act("toma26",a="carmen")]),
  {"dots":2},act("casa"),act("piensa",quien="coqui",k="sed"),
  ask("di_sed","c26_y_tu",[act("ranatoma"),act("quita26")],[act("abuelada",k="sed",suelto=1),"c26_toma_agua",act("ya")],resp=DH,baraja=True,voces=VH,said={"di_sed":"c26_cq_sed"}),
  act("llena26",n=1,suelto=1),act("piensa",quien="coqui",k="hambre"),act("ya"),
  ask("di_hambre","c26_y_ahora",[act("ranatoma"),say("cq_gracias_abuela",300),act("quita26")],[act("abuelada",k="hambre",suelto=1),"c26_ab_listo",act("ya")],resp=DH,baraja=True,voces=VH,said={"di_hambre":"c26_cq_hambre"}),
  {"dots":3},act("acaba26",quien="luis,carmen"),act("llena26",n=1),act("ofrece26",k="comida"),tw("ofrece"),
  ask("carmen","c26_carmen_hambre",["c26_carmen_tiene_hambre",act("abuelalleva",a="luis",k="agua"),act("toma26",a="luis")],[act("lleva26",a="carmen",k="comida",de="abuela"),act("toma26",a="carmen")],lead=[say("c26_luis_sed")]),
  {"wait":600},act("salen26"),
  # the turn: four plates and four glasses, the pot and the jug are empty; Canelo comes in
  {"dots":4},act("llena26",n=4,fin=1),"c26_ab_listo",act("canelo26"),"c26_canelo_hambre","c26_no_canelo",act("echa26"),CARD,{"wait":400},
  # A: what he wants himself
  {"dots":5},{"draw":"wa","options":["hambre","sed"]},act("casa"),act("piensa",quien="coqui",k="$wa"),
  {"decide":"say","options":DH,"baraja":True,"pick":"di_$wa","tests":"$wa","voces":VH,"said":VH,"lead":[],"line":"c26_y_tu",
   "right":[act("abuelada",k="$wa"),act("ranatoma"),ok(),act("abuelaa")],
   "wrong":[act("abuelada",k="$x"),act("canelo",de="coqui"),act("abuelaa")]+X+["c26_no_tu_$wa"]},
  # B: food or water
  {"dots":6},act("entra",quien="abuelo",silla=0),{"draw":"wb","options":["hambre","sed"]},{"calc":"gb","cond":"wb=hambre","then":"comidas","else":"vasos"},
  {"decide":"do","options":["comidas","vasos"],"pick":"$gb","tests":"$wb","lock":True,"lead":[],"line":"c26_abuelo_$wb",
   "right":[act("lleva26",a="abuelo",k="$wb"),act("toma26",a="abuelo",k="$wb"),ok()],
   "wrong":[act("lleva26",a="abuelo",k="$x"),act("canelo",a="abuelo",k="$x"),act("piensa",quien="abuelo",k="$wb")]+X+["c26_no_abuelo_$wb"]},
  # C: who said it
  {"dots":7},act("casa"),act("entra",quien="mama",silla=1,suelto=1),act("entra",quien="papa",silla=2),act("ya"),
  {"draw":"wc","options":["hambre","sed"],"other":"wd"},{"draw":"oc","options":["m","p"]},{"draw":"kc","options":["hambre","sed"],"other":"kd"},
  {"calc":"mh","cond":"wc=hambre","then":"mama","else":"papa"},{"calc":"ms","cond":"wc=sed","then":"mama","else":"papa"},
  {"calc":"tc","cond":"kc=hambre","then":"$mh","else":"$ms"},{"calc":"uc","cond":"kc=hambre","then":"$ms","else":"$mh"},
  {"calc":"la","cond":"oc=m","then":"c26_mama_$wc","else":"c26_papa_$wd"},{"calc":"lb","cond":"oc=m","then":"c26_papa_$wd","else":"c26_mama_$wc"},
  act("ofrece26",k="$kc"),tw("ofrece"),
  {"decide":"do","options":["mama","papa"],"pick":"$tc","tests":"$kc","lock":True,"lead":[say("$la")],"line":"$lb",
   "right":[act("lleva26",a="$tc",k="$kc",de="abuela"),act("toma26",a="$tc",k="$kc"),ok(),act("abuelalleva",a="$uc",k="$kd"),act("toma26",a="$uc",k="$kd")],
   "wrong":[act("lleva26",a="$x",k="$kc",de="abuela"),act("canelo",a="$x",k="$kc"),act("piensa",quien="$tc",k="$kc")]+X+["c26_no_$tc_$kc"]}],
 "final":[{"dots":8},act("casa"),act("reparte26"),"c26_ab_listo",act("final26"),"c26_familia_cocina","c26_y_canelo",say("c26_cq_canelo",300),act("fin")],
 "leer":["c26_esta_cocina","c26_ab_en_cocina","c26_comida_lista","c26_ab_listo","c26_luis_entra","c26_luis_hambre","c26_luis_tiene_hambre","c26_carmen_sed","c26_carmen_tiene_sed","c26_y_tu","c26_cq_sed","c26_toma_agua","c26_y_ahora","c26_cq_hambre",
  "c26_luis_sed","c26_carmen_hambre","c26_carmen_tiene_hambre","c26_canelo_hambre","c26_no_canelo","c26_familia_cocina","c26_y_canelo","c26_cq_canelo"]}
json.dump(s26,open("cuentos/tengo-hambre.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- the next-day picture pairs ----------------
NO={"x":0,"y":0,"s":1,"dy":0,"al":1,"vis":0,"bub":None}
P0=lambda **kw:dict({"plato":None,"taza":None,"uts":[],"frente":[]},**kw)
def pic(cam,**kw): return {"cam":cam,"set":dict({"cq":NO,"gente":{},"sitio":{},"puestos":[P0(),P0(),P0(),P0()],"mostrador":{},"estufa":{},"mantel":0,"cosas":[],"perro":None,"muestra":None,"encima":None,"tarjeta":None,"afuera":0,"bandeja":[]},**kw)}
def de_pie(x=110,y=206,**kw): return dict({"x":x,"y":y,"dir":1},**kw)
def sent(i,**kw): return dict({"x":[104,128,152,176][i],"y":150,"dir":1,"sent":1},**kw)
CT=[84,100,113,60]; CE=[122,66,113,60]; CF=[54,150,113,60]; CA_=[127,116,113,60]; CZ=[100,126,56.5,30]
todos={**s24["clips"],**s25["clips"],**s26["clips"],"m_c_mi_plato":N("Mira mi plato."),"m_c_mi_taza":N("Mira mi taza."),"m_c_mi_cuchara":N("Mira mi cuchara."),"m_c_papa_tenedor":N("Papá tiene el tenedor."),"m_c_ab_cuchillo":N("Abuela tiene mi cuchillo."),
 "m_c_mira_comida":N("Mira la comida."),"m_c_carmen_pone":N("Carmen pone el plato en la mesa."),"m_c_bizcocho_listo":N("El bizcocho está listo.")}
usa=["n_mesa","m_c_mi_plato","m_c_mi_taza","m_c_mi_cuchara","m_c_papa_tenedor","m_c_ab_cuchillo","m_c_mira_comida","c26_ab_en_cocina","m_c_carmen_pone","c26_luis_hambre","c26_carmen_sed","m_c_bizcocho_listo","muy_bien","si_muy_bien"]
abu=lambda **kw:dict({"x":205,"y":170,"dir":-1},**kw)
cual={"id":"cual-mesa","title":"¿Cuál?","place":"La cocina","scene":"mesa","tipo":"cual","stake":{"thing":"none","steps":0},
 "note":"The next-day pass for La mesa.","clips":{k:todos[k] for k in usa},
 "items":[
  {"w":"mesa","say":"n_mesa","si":pic(CT,mantel=1,cosas=[{"k":"florero","x":140,"y":152,"z":300}]),"no":pic(CE,estufa={"olla":1,"vapor":1})},
  {"w":"plato","say":"m_c_mi_plato","si":pic(CF,gente={"luis":de_pie(alza="plato")}),"no":pic(CF,gente={"luis":de_pie(alza="taza")})},
  {"w":"taza","say":"m_c_mi_taza","si":pic(CF,gente={"carmen":de_pie(alza="tazall")}),"no":pic(CF,gente={"carmen":de_pie(alza="olla",alzax=26)})},
  {"w":"cuchara","say":"m_c_mi_cuchara","si":pic(CF,gente={"abuelo":de_pie(alza="cuchara")}),"no":pic(CF,gente={"abuelo":de_pie(alza="tenedor")})},
  {"w":"tenedor","say":"m_c_papa_tenedor","si":pic(CF,gente={"papa":de_pie(alza="tenedor")}),"no":pic(CF,gente={"papa":de_pie(alza="cuchillo")})},
  {"w":"cuchillo","say":"m_c_ab_cuchillo","si":pic(CA_,gente={"abuela":abu(alza="cuchillo")}),"no":pic(CA_,gente={"abuela":abu(alza="cuchara")})},
  {"w":"comida","say":"m_c_mira_comida","si":pic(CZ,mantel=1,puestos=[P0(),P0(plato={"n":1,"con":"espa","vapor":1}),P0(),P0()]),"no":pic(CZ,mantel=1,puestos=[P0(),P0(plato={"n":2,"con":None}),P0(),P0()])},
  {"w":"cocina","say":"c26_ab_en_cocina","si":pic([70,86,169.5,90],gente={"abuela":abu(x=176,y=172)},estufa={"olla":1,"vapor":1}),"no":pic([70,90,169.5,90],afuera=1,gente={"abuela":{"x":176,"y":176,"dir":-1}})},
  {"w":"pone","say":"m_c_carmen_pone","si":pic([127,104,113,60],mantel=1,gente={"carmen":{"x":206,"y":165,"dir":-1,"pose":"offer"}},cosas=[{"k":"plato","x":187,"y":150,"z":300}]),
                                     "no":pic([127,104,113,60],mantel=1,gente={"carmen":{"x":206,"y":165,"dir":-1,"pose":"offer"}},cosas=[{"k":"plato","x":178,"y":150,"z":300},{"k":"pano","x":187,"y":151,"z":301}])},
  {"w":"tengo hambre","say":"c26_luis_hambre","si":pic([84,84,113,60],gente={"luis":sent(1,piensa="hambre")},sitio={"luis":1}),"no":pic([84,84,113,60],gente={"luis":sent(1,piensa="sed")},sitio={"luis":1})},
  {"w":"tengo sed","say":"c26_carmen_sed","si":pic(CT,gente={"carmen":sent(1,hace="bebe",que="vaso")},sitio={"carmen":1}),"no":pic(CT,gente={"carmen":sent(1,hace="come",que="tenedor")},sitio={"carmen":1},puestos=[P0(),P0(plato={"n":1,"con":"comida"}),P0(),P0()])},
  {"w":"listo","say":"m_c_bizcocho_listo","si":pic(CT,mantel=1,cosas=[{"k":"entero","x":140,"y":153,"z":300}]),"no":pic(CA_,estufa={"horno":1})}]}
json.dump(cual,open("cuentos/cual-mesa.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# the story before this scene leads into it
p="cuentos/el-bebe-duerme.json"; d=json.load(open(p,encoding="utf-8"))
if d.get("next")!="la-mesa":
    d["next"]="la-mesa"; json.dump(d,open(p,"w",encoding="utf-8"),ensure_ascii=False,indent=1)

# clip ids are global: the same id must have the same text everywhere
seen={}; clash=0; new=0; chars=0
for f in sorted(glob.glob("cuentos/*.json")):
    if "zz-" in f or "zmesa" in f: continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items():
        key=(cl.get("who"),cl.get("text"))
        if cid in seen and seen[cid]!=key: print("CLASH",cid,seen[cid],key,f); clash+=1
        seen.setdefault(cid,key)
for cid,(who,text) in seen.items():
    if not os.path.exists(f"audio/{cid}.mp3"): new+=1; chars+=len(text)
print(len(seen),"clips,",new,"new,",chars,"characters to record,",clash,"clashes")
for st in (s24,s25,s26):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"(c(?:24|25|26)_[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
