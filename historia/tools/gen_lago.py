# El lago (place 2, scene 3): stories 18, 19, 20 and the scene's picture pairs. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/lago.md
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
comunes={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!"),"p_n_luis":N("Este es Luis."),"p_n_carmen":N("Esta es Carmen."),"c_n_perro":N("Es el perro. Se llama Canelo."),
 "k_n_agua":N("Es el agua."),"l_n_pato":N("Es un pato."),"l_n_pez":N("Es un pez."),"l_n_pajaro":N("Es un pájaro."),"l_n_lago":N("Es el lago."),"l_n_bote":N("Es un bote."),"l_n_flor":N("Es una flor.")}
NOMBRES={"luis":"p_n_luis","carmen":"p_n_carmen","perro":"c_n_perro","agua":"k_n_agua","lago":"l_n_lago","juncos":"k_n_agua","coqui":"yo_coqui","flor":"l_n_flor",
 "pato_blanco":"l_n_pato","pato_negro":"l_n_pato","pato_amarillo":"l_n_pato","pez":"l_n_pez","pajaro":"l_n_pajaro","ave_blanco":"l_n_pajaro","ave_negro":"l_n_pajaro",
 "bote_rojo":"l_n_bote","bote_azul":"l_n_bote","bote_verde":"l_n_bote"}

# ---------------- 18. Pan para el pato ----------------
c=dict(comunes)
c.update({"c18_lago":N("Este es el lago."),"c18_hay_pato":N("Mira. Hay un pato."),"c18_pato_nada":N("El pato nada en el agua."),"c18_hay_pez":N("Hay un pez."),"c18_pez_nada":N("El pez nada en el agua."),"c18_hay_pajaro":N("Y hay un pájaro."),
 "c18_pajaro_vuela":N("El pájaro vuela."),"c18_tiene_pan":N("Carmen tiene pan."),"c18_ca_pato":CA("¡Pan para el pato!"),"c18_ca_pez":CA("¡Pan para el pez!"),"c18_ca_pajaro":CA("¡Pan para el pájaro!"),"c18_come":N("El pato come pan."),
 "c18_ca_quien_vuela":CA("¿Quién vuela?"),"c18_ca_quien_nada":CA("¿Quién nada?"),"c18_si_pajaro":N("¡Sí! El pájaro vuela."),"c18_si_pez":N("¡Sí! El pez nada."),
 "c18_l_y_pato":L("¿Y el pato?"),"c18_cq_vuela":T("¡El pato vuela!"),"c18_cq_nada":T("¡El pato nada!"),"c18_l_si_vuela":L("¡Sí! ¡El pato vuela!"),"c18_l_y_ahora":L("¿Y ahora?"),"c18_l_si_nada":L("Sí. Ahora el pato nada en el agua."),
 "c18_ay_pez":N("¡Ay, no! El pez se come el pan del pato."),"c18_ca_mas":CA("Mira. Hay más pan."),
 "c18_no_para_pato":N("No, Coquí. Este pan es para el pato."),"c18_no_para_pez":N("No, Coquí. Este pan es para el pez."),"c18_no_para_pajaro":N("No, Coquí. Este pan es para el pájaro."),
 "c18_no_mira_vuela":N("No, Coquí. Mira. El pájaro vuela."),"c18_no_mira_nada":N("No, Coquí. Mira. El pez nada en el agua."),
 "c18_no_ahora_vuela":N("No, Coquí. Mira. Ahora el pato vuela."),"c18_no_ahora_nada":N("No, Coquí. Mira. Ahora el pato nada en el agua."),
 "c18_fin_pez":N("El pez nada."),"c18_fin_pajaro":N("El pájaro vuela."),"c18_fin_pato":N("Y el pato nada y vuela."),"c18_cq_adios":T("¡Adiós, amigos!")})
DV=["di_vuela","di_nada"]; VV={"di_vuela":"c18_cq_vuela","di_nada":"c18_cq_nada"}; AN=["pato_blanco","pez","pajaro"]
s18={"id":"pan-para-el-pato","title":"Pan para el pato","place":"El parque","scene":"lago","next":"los-botes",
 "goal":"Give the duck, the fish and the bird each its piece of bread.","stake":{"thing":"pan","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["pato","pez","pájaro","nada","vuela"],"back_again":["agua","hay","mira","para","tiene","¿quién?","más","ahora","amigo"],
 "also_heard":["lago","pan","come"],"names":NOMBRES,"palabras":{"pato_blanco":"pato","pajaro":"pájaro"},"clips":c,
 "beats":[act("inicio18"),{"wait":500},"c18_lago",tw("pato_blanco"),"c18_hay_pato",tw(None),act("giro"),"c18_pato_nada",tw("pez"),"c18_hay_pez",tw(None),"c18_pez_nada",tw("pajaro"),"c18_hay_pajaro",tw(None),
  act("sube",quien="pajaro"),"c18_pajaro_vuela",act("baja",quien="pajaro"),pose("carmen","arriba"),"c18_tiene_pan",pose("carmen","idle"),
  {"dots":1},act("toma"),ask("pato_blanco","c18_ca_pato",[],[act("come",a="pato_blanco",sigue=1),"c18_come",act("traga")]),
  {"dots":2},act("orilla"),act("sube",quien="pajaro"),act("toma"),ask("pajaro","c18_ca_quien_vuela",["c18_si_pajaro"],[act("come",a="pajaro")]),
  act("toma"),ask("pez","c18_ca_quien_nada",["c18_si_pez",act("baja",quien="pajaro"),act("alagua")],[act("come",a="pez")]),
  {"dots":3},act("sube",quien="pato"),ask("di_vuela","c18_l_y_pato",[say("c18_l_si_vuela")],[],resp=DV,baraja=True,voces=VV,said={"di_vuela":"c18_cq_vuela"}),
  act("rema"),ask("di_nada","c18_l_y_ahora",[say("c18_l_si_nada"),act("baja",quien="pato")],[],resp=DV,baraja=True,voces=VV,said={"di_nada":"c18_cq_nada"}),
  {"dots":4},act("turno18"),"c18_ay_pez",act("vuelca"),say("c18_ca_mas"),CARD,{"wait":400},
  {"dots":5},act("toma"),{"draw":"aa","options":["pato","pez","pajaro"]},{"calc":"ra","cond":"aa=pato","then":"pato_blanco","else":"$aa"},
  {"decide":"do","options":AN,"pick":"$ra","tests":"$ra","lock":True,"lead":[],"line":"c18_ca_$aa",
   "right":[act("come",a="$ra"),ok()],"wrong":[act("come",a="$x"),act("seva",a="$ra"),act("marca",que="pan"),{"cost":1},act("toma"),act("vuelve",a="$ra"),"c18_no_para_$aa"]},
  {"dots":6},act("orilla"),act("sube",quien="pajaro"),act("toma"),{"draw":"vb","options":["vuela","nada"]},{"calc":"rb","cond":"vb=vuela","then":"pajaro","else":"pez"},
  {"decide":"do","options":["pajaro","pez"],"pick":"$rb","tests":"$vb","lock":True,"lead":[],"line":"c18_ca_quien_$vb",
   "right":[act("come",a="$rb"),ok()],"wrong":[act("come",a="$x"),act("marca",que="pan"),{"cost":1},act("toma"),"c18_no_mira_$vb"]},
  act("baja",quien="pajaro"),act("alagua"),
  {"dots":7},act("luispan"),{"draw":"sc","options":["vuela","nada"]},{"if":"sc=vuela","then":[act("sube",quien="pato")],"else":[act("rema")]},
  {"calc":"oc","cond":"sc=vuela","then":"pez","else":"pajaro"},
  {"decide":"say","options":DV,"baraja":True,"pick":"di_$sc","tests":"$sc","voces":VV,"said":VV,"lead":[],"line":"c18_l_y_pato",
   "right":[act("come",a="pato_blanco",de="luis"),ok()],"wrong":[act("come",a="$oc",de="luis"),act("marca",que="pan"),{"cost":1},"c18_no_ahora_$sc",act("luispan")]},
  act("baja",quien="pato")],
 "final":[{"dots":8},act("final18"),act("sale",a="pez"),"c18_fin_pez",act("sale",a="pajaro"),"c18_fin_pajaro",act("sale",a="pato_blanco"),"c18_fin_pato",say("c18_cq_adios",300),{"wait":600}],
 "leer":["c18_lago","c18_hay_pato","c18_pato_nada","c18_hay_pez","c18_pez_nada","c18_hay_pajaro","c18_pajaro_vuela","c18_tiene_pan","c18_ca_pato","c18_come","c18_ca_quien_vuela","c18_si_pajaro","c18_ca_quien_nada","c18_si_pez",
  "c18_l_y_pato","c18_cq_vuela","c18_l_si_vuela","c18_l_y_ahora","c18_cq_nada","c18_l_si_nada","c18_ay_pez","c18_ca_mas","c18_fin_pez","c18_fin_pajaro","c18_fin_pato","c18_cq_adios"]}
json.dump(s18,open("cuentos/pan-para-el-pato.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 19. Los botes ----------------
c=dict(comunes)
COL=["rojo","azul","verde"]
c.update({"c19_hay_tres":N("Mira. Hay tres botes."),"c19_un_rojo":N("Un bote rojo."),"c19_un_azul":N("Un bote azul."),"c19_un_verde":N("Y un bote verde."),
 "c19_l_dame_rojo":L("Coquí, ¡dame el bote rojo!"),"c19_l_dame_azul":L("Coquí, ¡dame el bote azul!"),"c19_l_dame_verde":L("Coquí, ¡dame el bote verde!"),"c19_luis_azul":N("Luis coge el bote azul."),"c19_luis_verde":N("Y el bote verde."),
 "c19_alla_van3":N("¡Allá van los botes! Rojo, azul y verde."),"c19_alla_van":N("¡Allá van los botes!"),
 "c19_l_un_pez":L("¿Un pez? ¿De qué color es?"),"c19_l_y_este":L("¿Y este pez? ¿De qué color es?"),"c19_cq_rojo":T("¡Es rojo!"),"c19_cq_azul":T("¡Es azul!"),"c19_cq_verde":T("¡Es verde!"),
 "c19_l_pez_bote_rojo":L("¡Un pez rojo y un bote rojo!"),"c19_l_pez_bote_verde":L("¡Un pez verde y un bote verde!"),
 "c19_l_pinta3":L("Coquí, ¡pinta tres botes! ¿De qué color? Uno rojo, uno azul y uno verde."),"c19_ay_rojo":N("¡Ay, no! ¡El bote rojo!"),
 "c19_no_este_rojo":N("No, Coquí. Este es el bote rojo."),"c19_no_este_azul":N("No, Coquí. Este es el bote azul."),"c19_no_este_verde":N("No, Coquí. Este es el bote verde."),
 "c19_no_es_rojo":N("No, Coquí. Mira. El pez es rojo."),"c19_no_es_azul":N("No, Coquí. Mira. El pez es azul."),"c19_no_es_verde":N("No, Coquí. Mira. El pez es verde."),
 "c19_no_uno_rojo":N("No, Coquí. Luis dice: ¡Uno rojo!"),"c19_no_uno_azul":N("No, Coquí. Luis dice: ¡Uno azul!"),"c19_no_uno_verde":N("No, Coquí. Luis dice: ¡Uno verde!"),
 "c19_fin":N("Un bote rojo. Un bote azul. Un bote verde."),"c19_cq_aqui":T("¡Aquí están los botes!")})
for a in COL:
    for b in COL:
        if a!=b: c[f"c19_l_dos_{a}_{b}"]=L(f"¡Ahora dos botes! Uno {a} y uno {b}.")
DC=["di_rojo","di_azul","di_verde"]; VC={"di_"+k:"c19_cq_"+k for k in COL}; BO=["bote_rojo","bote_azul","bote_verde"]; PO=["pote_rojo","pote_azul","pote_verde"]; ORD=["rav","rva","arv","avr","vra","var"]
PARES=[a+"_"+b for a in COL for b in COL if a!=b]
s19={"id":"los-botes","title":"Los botes","place":"El parque","scene":"lago","next":"cual",
 "goal":"Send the toy boats across the pond to Carmen.","stake":{"thing":"bote","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["rojo","azul","verde","¿de qué color?"],"back_again":["pez","nada","dame","hay","tres","dos","uno","mira","allá","aquí","ahora"],
 "also_heard":["bote","pinta","van"],"names":NOMBRES,"palabras":{"pote_rojo":"rojo","pote_azul":"azul","pote_verde":"verde"},"clips":c,
 "beats":[act("inicio19"),{"wait":500},"c19_hay_tres",tw("bote_rojo"),"c19_un_rojo",tw("bote_azul"),"c19_un_azul",tw("bote_verde"),"c19_un_verde",tw(None),
  {"dots":1},ask("bote_rojo","c19_l_dame_rojo",["c19_luis_azul",act("luiscoge",c="azul"),"c19_luis_verde",act("luiscoge",c="verde"),act("sopla"),"c19_alla_van3",act("llegan"),{"draw":"ordu","options":ORD},act("repone",o="$ordu")],[act("empuja",c="rojo")]),
  {"dots":2},act("bolso"),act("pezviene",c="rojo"),ask("di_rojo","c19_l_un_pez",[act("bolso",fin=1),act("saca",c="madera"),act("luispinta",c="rojo"),act("conpez"),say("c19_l_pez_bote_rojo"),act("llegapez")],[],resp=DC,baraja=True,voces=VC,said={"di_rojo":"c19_cq_rojo"}),
  act("bolso"),act("pezviene",c="verde"),ask("di_verde","c19_l_y_este",[act("bolso",fin=1),act("saca",c="madera"),act("luispinta",c="verde"),act("conpez"),say("c19_l_pez_bote_verde"),act("llegapez")],[],resp=DC,baraja=True,voces=VC,said={"di_verde":"c19_cq_verde"}),
  {"dots":3},act("saca",c="madera,madera,madera"),ask("pote_rojo","c19_l_pinta3",[],[act("ranapinta",c="rojo")],resp=PO,baraja=True),
  {"ask":"pote_azul","lead":[],"line":None,"after":[act("ranapinta",c="azul")],"then":[],"resp":["pote_azul","pote_verde"],"baraja":True},
  {"ask":"pote_verde","lead":[],"line":None,"after":[act("ranapinta",c="verde")],"then":[act("alagua19"),act("sopla"),"c19_alla_van",act("llegan")],"resp":["pote_verde"]},
  {"dots":4},act("saca",c="rojo"),act("alagua19"),pose("luis","wave"),act("deriva"),pose("luis","idle"),"c19_ay_rojo",CARD,{"wait":400},
  {"dots":5},{"draw":"ordd","options":ORD},act("repone",o="$ordd"),{"draw":"ca","options":COL},
  {"decide":"do","options":BO,"pick":"bote_$ca","tests":"$ca","lock":True,"lead":[],"line":"c19_l_dame_$ca",
   "right":[act("empuja",c="$ca"),act("sopla"),act("llegan"),act("repone"),ok()],
   "wrong":[act("miracarmen"),act("empuja",c="$x"),act("deriva"),act("miracarmen",fin=1),act("luisve"),act("marca",que="bote"),{"cost":1},act("repone"),tw("bote_$ca"),"c19_no_este_$ca",tw(None)]},
  {"dots":6},act("bolso"),{"draw":"cb","options":COL},act("pezviene",c="$cb"),
  {"decide":"say","options":DC,"baraja":True,"pick":"di_$cb","tests":"$cb","voces":VC,"said":VC,"lead":[],"line":"c19_l_un_pez",
   "right":[act("bolso",fin=1),act("saca",c="madera"),act("luispinta",c="$cb"),act("conpez"),act("llegapez"),ok()],
   "wrong":[{"calc":"xb","cond":"x=di_rojo","then":"rojo","else":"$x"},{"calc":"xb","cond":"x=di_azul","then":"azul","else":"$xb"},{"calc":"xb","cond":"x=di_verde","then":"verde","else":"$xb"},
    act("bolso",fin=1),act("saca",c="madera"),act("luispinta",c="$xb"),act("alagua19"),act("bolso"),act("pezsalta"),tw("pez"),"c19_no_es_$cb",tw(None),act("deriva"),act("marca",que="bote"),{"cost":1}]},
  {"dots":7},{"draw":"cc","options":PARES},
  {"if":"cc=rojo_azul","then":[act("dosbotes",c1="rojo",c2="azul")]},{"if":"cc=rojo_verde","then":[act("dosbotes",c1="rojo",c2="verde")]},{"if":"cc=azul_rojo","then":[act("dosbotes",c1="azul",c2="rojo")]},
  {"if":"cc=azul_verde","then":[act("dosbotes",c1="azul",c2="verde")]},{"if":"cc=verde_rojo","then":[act("dosbotes",c1="verde",c2="rojo")]},{"if":"cc=verde_azul","then":[act("dosbotes",c1="verde",c2="azul")]},
  {"decide":"say","options":PO,"baraja":True,"pick":"$falta","vale":["$vale"],"tests":"$falta","lock":True,"lead":[],"line":"c19_l_dos_$cc",
   "right":[act("pintado",x="$x")],"wrong":[act("pintamal",x="$x"),{"cost":1},"c19_no_uno_$fc"]},
  {"decide":"say","options":["$pu","$pd"],"baraja":True,"pick":"$falta","tests":"$falta","mudo":True,"lead":[],"line":None,"bien":False,
   "right":[act("pintado",x="$x"),act("findos")],"wrong":[act("pintamal",x="$x"),{"cost":1},"c19_no_uno_$fc"]}],
 "final":[{"dots":8},act("final19"),"c19_fin",say("c19_cq_aqui",300),{"wait":600}],
 "leer":["c19_hay_tres","c19_un_rojo","c19_un_azul","c19_un_verde","c19_l_dame_rojo","c19_luis_azul","c19_luis_verde","c19_alla_van3","c19_l_un_pez","c19_cq_rojo","c19_l_pez_bote_rojo","c19_l_y_este","c19_cq_verde",
  "c19_l_pez_bote_verde","c19_l_pinta3","c19_alla_van","c19_ay_rojo","c19_fin","c19_cq_aqui"]}
json.dump(s19,open("cuentos/los-botes.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 20. ¿Cuál? ----------------
c=dict(comunes)
BNA=["blanco","negro","amarillo"]; PT=["pato_blanco","pato_negro","pato_amarillo"]
c.update({"c20_flor":N("Mira. Una flor amarilla."),"c20_hay_tres":N("Y mira. Hay tres patos."),"c20_un_blanco":N("Un pato blanco."),"c20_un_negro":N("Un pato negro."),"c20_un_amarillo":N("Y un pato amarillo."),
 "c20_ca_cual_es_blanco":CA("¿Cuál es el pato blanco?"),"c20_ca_cual_es_negro":CA("¿Cuál es el pato negro?"),"c20_ca_cual_es_amarillo":CA("¿Cuál es el pato amarillo?"),
 "c20_ca_si_blanco":CA("¡Sí! El pato blanco."),"c20_ca_si_negro":CA("¡Sí! El pato negro."),"c20_ca_si_amarillo":CA("¡Sí! El pato amarillo."),
 "c20_dos_pajaros":N("Mira. Un pájaro blanco y un pájaro negro."),"c20_ca_mi_pan":CA("¡Mi pan! ¿Cuál pájaro?"),"c20_cq_p_negro":T("¡El pájaro negro!"),"c20_cq_p_blanco":T("¡El pájaro blanco!"),
 "c20_ca_pan_pato":CA("¡Pan para el pato!"),"c20_cq_cual":T("¿Cuál?"),"c20_ca_el_blanco":CA("El pato blanco."),"c20_ca_el_negro":CA("El pato negro."),"c20_ca_el_amarillo":CA("El pato amarillo."),
 "c20_ca_pan_blanco":CA("¡Pan para el pato blanco!"),"c20_ca_pan_negro":CA("¡Pan para el pato negro!"),"c20_ca_pan_amarillo":CA("¡Pan para el pato amarillo!"),
 "c20_ca_el_blanco_coqui":CA("¡El pato blanco, Coquí!"),"c20_ca_el_negro_coqui":CA("¡El pato negro, Coquí!"),"c20_ca_el_amarillo_coqui":CA("¡El pato amarillo, Coquí!"),
 "c20_l_no_canelo":L("¡No, Canelo!"),"c20_no_este_blanco":N("No, Coquí. Este es el pato blanco."),"c20_no_este_negro":N("No, Coquí. Este es el pato negro."),"c20_no_este_amarillo":N("No, Coquí. Este es el pato amarillo."),
 "c20_no_tiene_negro":N("No, Coquí. Mira. El pájaro negro tiene el pan."),"c20_no_tiene_blanco":N("No, Coquí. Mira. El pájaro blanco tiene el pan."),"c20_no_hay_tres":N("No, Coquí. Hay tres patos. ¿Cuál pato?"),
 "c20_fin":N("Un pato blanco. Un pato negro. Y un pato amarillo."),"c20_ca_tu_amigo":CA("¿Cuál es tu amigo, Coquí?"),"c20_cq_el_amarillo":T("¡El amarillo!")})
DP=["di_negro","di_blanco"]; VP={"di_negro":"c20_cq_p_negro","di_blanco":"c20_cq_p_blanco"}; VQ={"di_cual":"c20_cq_cual"}
def tocaC(col):   # the last decision, once he knows which duck: touch it
    return {"decide":"do","options":PT,"pick":"pato_"+col,"tests":col,"lock":True,"mudo":True,"lead":[],"line":None,
            "right":[act("come",a="pato_"+col),act("premio20")],
            "wrong":[act("come",a="$x"),act("ruido",a="pato_"+col),act("mueven",d=1),act("marcaC",que="onda"),{"cost":1},tw("pato_"+col),"c20_no_este_"+col,tw(None),act("toma20")]}
s20={"id":"cual","title":"¿Cuál?","place":"El parque","scene":"lago","next":None,
 "goal":"Bring the three ducks to the dock.","stake":{"thing":"patos","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["amarillo","blanco","negro","¿cuál?"],"back_again":["pato","pájaro","para","hay","tres","mira","flor","sí","amigo"],
 "also_heard":["amarilla","pan"],"names":NOMBRES,"palabras":{"cual":"¿cuál?"},"clips":c,
 "beats":[act("inicio20"),{"wait":500},tw("flor"),"c20_flor",tw(None),"c20_hay_tres",tw("pato_blanco"),"c20_un_blanco",tw("pato_negro"),"c20_un_negro",tw("pato_amarillo"),"c20_un_amarillo",tw(None),
  {"dots":1},act("toma20"),ask("pato_blanco","c20_ca_cual_es_blanco",[say("c20_ca_si_blanco")],[act("come",a="pato_blanco")]),
  act("toma20"),ask("pato_negro","c20_ca_cual_es_negro",[say("c20_ca_si_negro")],[act("come",a="pato_negro")]),
  {"dots":2},{"draw":"lado","options":["bn","nb"]},act("llegan20",lado="$lado"),"c20_dos_pajaros",act("roba",c="negro"),
  ask("di_negro","c20_ca_mi_pan",[],[act("palmas",c="negro",cerca="0")],resp=DP,baraja=True,voces=VP,said={"di_negro":"c20_cq_p_negro"}),
  {"dots":3},act("toma20"),act("miran"),{"set":{"resp":["di_cual"],"respVoz":VQ}},
  ask("di_cual","c20_ca_pan_pato",[say("c20_ca_el_negro")],[],voces=VQ,said={"di_cual":"c20_cq_cual"},bien=False),
  {"ask":"pato_negro","lead":[],"line":None,"after":[act("come",a="pato_negro")],"then":[]},
  act("toma20"),act("miran"),{"set":{"resp":["di_cual"],"respVoz":VQ}},ask("pato_amarillo","c20_ca_pan_amarillo",[say("c20_ca_si_amarillo")],[act("come",a="pato_amarillo")]),
  {"dots":4},act("turno20"),say("c20_l_no_canelo"),act("echado"),{"draw":"ladob","options":["bn","nb"]},act("posan20",lado="$ladob"),CARD,{"wait":400},
  {"dots":5},act("mueven",d=0,baraja=1),act("toma20"),{"draw":"ca","options":BNA},
  {"decide":"do","options":PT,"pick":"pato_$ca","tests":"$ca","lock":True,"lead":[],"line":"c20_ca_cual_es_$ca",
   "right":[act("come",a="pato_$ca"),{"if":"ok","then":[act("mueven",d=-1),act("marca",que="ok")]}],   # putting it right brings nobody nearer
   "wrong":[act("come",a="$x"),act("ruido",a="pato_$ca"),act("mueven",d=1),act("marca",que="onda"),{"cost":1},tw("pato_$ca"),"c20_no_este_$ca",tw(None),act("toma20")]},
  {"dots":6},{"draw":"cb","options":["negro","blanco"]},{"calc":"ob","cond":"cb=negro","then":"blanco","else":"negro"},act("roba",c="$cb"),
  {"decide":"say","options":DP,"baraja":True,"pick":"di_$cb","tests":"$cb","voces":VP,"said":VP,"lead":[],"line":"c20_ca_mi_pan",
   "right":[{"if":"ok","then":[act("palmas",c="$cb"),act("marca",que="ok")],"else":[act("palmas",c="$cb",cerca="0")]}],
   "wrong":[act("palmas",c="$ob"),act("marca",que="onda"),{"cost":1},"c20_no_tiene_$cb"]},
  {"dots":7},act("toma20"),{"draw":"dc","options":["si","no"]},{"draw":"cc","options":BNA},act("miran"),
  {"if":"dc=no","then":[
    {"decide":"do","options":PT,"burbujas":["di_cual"],"pick":"di_cual","tests":"cual","voces":VQ,"said":VQ,"lead":[],"line":"c20_ca_pan_pato","bien":False,
     "right":[{"if":"cc=blanco","then":[say("c20_ca_el_blanco"),tocaC("blanco")]},{"if":"cc=negro","then":[say("c20_ca_el_negro"),tocaC("negro")]},{"if":"cc=amarillo","then":[say("c20_ca_el_amarillo"),tocaC("amarillo")]}],
     "wrong":[act("rina",a="$x"),act("mueven",d=1),act("marcaC",que="onda"),{"cost":1},"c20_no_hay_tres",act("toma20")]}],
   "else":[
    {"if":"cc=blanco","then":[{"decide":"do","options":PT,"burbujas":["di_cual"],"pick":"pato_blanco","tests":"blanco","voces":VQ,"said":VQ,"gratis":{"di_cual":[say("c20_ca_el_blanco_coqui"),act("robamano"),act("toma20")]},"lead":[],"line":"c20_ca_pan_blanco",
      "right":[act("come",a="pato_blanco"),act("premio20")],"wrong":tocaC("blanco")["wrong"]}]},
    {"if":"cc=negro","then":[{"decide":"do","options":PT,"burbujas":["di_cual"],"pick":"pato_negro","tests":"negro","voces":VQ,"said":VQ,"gratis":{"di_cual":[say("c20_ca_el_negro_coqui"),act("robamano"),act("toma20")]},"lead":[],"line":"c20_ca_pan_negro",
      "right":[act("come",a="pato_negro"),act("premio20")],"wrong":tocaC("negro")["wrong"]}]},
    {"if":"cc=amarillo","then":[{"decide":"do","options":PT,"burbujas":["di_cual"],"pick":"pato_amarillo","tests":"amarillo","voces":VQ,"said":VQ,"gratis":{"di_cual":[say("c20_ca_el_amarillo_coqui"),act("robamano"),act("toma20")]},"lead":[],"line":"c20_ca_pan_amarillo",
      "right":[act("come",a="pato_amarillo"),act("premio20")],"wrong":tocaC("amarillo")["wrong"]}]}]}],
 "final":[{"dots":8},act("final20"),"c20_fin",say("c20_ca_tu_amigo"),say("c20_cq_el_amarillo",300),act("cuac"),{"wait":600}],
 "leer":["c20_flor","c20_hay_tres","c20_un_blanco","c20_un_negro","c20_un_amarillo","c20_ca_cual_es_blanco","c20_ca_si_blanco","c20_ca_cual_es_negro","c20_ca_si_negro","c20_dos_pajaros","c20_ca_mi_pan","c20_cq_p_negro",
  "c20_ca_pan_pato","c20_cq_cual","c20_ca_el_negro","c20_ca_pan_amarillo","c20_ca_si_amarillo","c20_l_no_canelo","c20_fin","c20_ca_tu_amigo","c20_cq_el_amarillo"]}
json.dump(s20,open("cuentos/cual.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- ¿Cuál? for El lago ----------------
NO={"x":0,"y":0,"s":1,"dy":0,"al":1,"vis":0,"bub":None}
pt=lambda k,x,y,pose="nada",**kw:dict({"k":k,"x":x,"y":y,"pose":pose,"dir":-1},**kw)
pz=lambda c,x,y,**kw:dict({"c":c,"x":x,"y":y,"dir":-1},**kw)
av=lambda c,x,y,**kw:dict({"c":c,"x":x,"y":y,"dir":-1},**kw)
bt=lambda c,x,y,en="agua":{"c":c,"x":x,"y":y,"en":en}
CW=[100,156,113,60]; CD=[44,112,113,60]; CS=[96,30,113,60]; CK=[120,84,113,60]
todos={**s18["clips"],**s19["clips"],**s20["clips"],"l_c_pato_nada":N("El pato nada."),"l_c_bote_rojo":N("Es un bote rojo."),"l_c_pez_azul":N("Es un pez azul."),"l_c_bote_verde":N("Es un bote verde."),
 "l_c_pato_amarillo":N("Es un pato amarillo."),"l_c_pajaro_blanco":N("Es un pájaro blanco."),"l_c_pato_negro":N("Es un pato negro.")}
usa=["l_n_pato","l_n_pez","l_n_pajaro","l_c_pato_nada","c18_pajaro_vuela","l_c_bote_rojo","l_c_pez_azul","l_c_bote_verde","l_c_pato_amarillo","l_c_pajaro_blanco","l_c_pato_negro","muy_bien","si_muy_bien"]
cual={"id":"cual-lago","title":"¿Cuál?","place":"El parque","scene":"lago","tipo":"cual","stake":{"thing":"none","steps":0},
 "note":"The next-day pass for El lago. '¿De qué color?' and '¿cuál?' have no pair: they are questions.","clips":{k:todos[k] for k in usa},
 "items":[
  {"w":"pato","say":"l_n_pato","si":{"cam":CD,"set":{"patos":{"a":pt("blanco",100,154,"anda")},"cq":NO}},"no":{"cam":CD,"set":{"aves":{"a":av("azul",100,154)},"cq":NO}}},
  {"w":"pez","say":"l_n_pez","si":{"cam":CW,"set":{"peces":{"a":pz("pardo",156,196,dy=16)},"cq":NO}},"no":{"cam":CW,"set":{"patos":{"a":pt("blanco",156,190,come=1)},"cq":NO}}},
  {"w":"pájaro","say":"l_n_pajaro","si":{"cam":[84,84,113,60],"set":{"aves":{"a":av("azul",140,119,pan=1)},"cq":NO}},"no":{"cam":CW,"set":{"peces":{"a":pz("pardo",156,186)},"pan":{"con":None,"x":143,"y":184,"z":0,"vis":1},"cq":NO}}},
  {"w":"nada","say":"l_c_pato_nada","si":{"cam":CW,"set":{"patos":{"a":pt("blanco",150,188)},"cq":NO}},"no":{"cam":CS,"set":{"patos":{"a":pt("blanco",150,62,"vuela")},"cq":NO}}},
  {"w":"vuela","say":"c18_pajaro_vuela","si":{"cam":CS,"set":{"aves":{"a":av("azul",152,60,vuela=1)},"cq":NO}},"no":{"cam":CD,"set":{"aves":{"a":av("azul",96,154,pan=1)},"cq":NO}}},
  {"w":"rojo","say":"l_c_bote_rojo","si":{"cam":CW,"set":{"botes":{"a":bt("rojo",150,190)},"cq":NO}},"no":{"cam":CW,"set":{"botes":{"a":bt("azul",150,190)},"cq":NO}}},
  {"w":"azul","say":"l_c_pez_azul","si":{"cam":CW,"set":{"peces":{"a":pz("azul",150,192)},"cq":NO}},"no":{"cam":CW,"set":{"peces":{"a":pz("verde",150,192)},"cq":NO}}},
  {"w":"verde","say":"l_c_bote_verde","si":{"cam":CD,"set":{"botes":{"a":bt("verde",96,153,"muelle")},"cq":NO}},"no":{"cam":CD,"set":{"botes":{"a":bt("rojo",96,153,"muelle")},"cq":NO}}},
  {"w":"amarillo","say":"l_c_pato_amarillo","si":{"cam":CW,"set":{"patos":{"a":pt("amarillo",150,190)},"cq":NO}},"no":{"cam":CW,"set":{"patos":{"a":pt("blanco",150,190)},"cq":NO}}},
  {"w":"blanco","say":"l_c_pajaro_blanco","si":{"cam":[84,116,100,53.1],"set":{"aves":{"a":av("blanco",133,140)},"cq":NO}},"no":{"cam":[84,116,100,53.1],"set":{"aves":{"a":av("negro",133,140)},"cq":NO}}},
  {"w":"negro","say":"l_c_pato_negro","si":{"cam":CW,"set":{"patos":{"a":pt("negro",150,190)},"cq":NO}},"no":{"cam":CW,"set":{"patos":{"a":pt("amarillo",150,190)},"cq":NO}}}]}
json.dump(cual,open("cuentos/cual-lago.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# the story before this scene leads into it
p="cuentos/otra-vez.json"; d=json.load(open(p,encoding="utf-8"))
if d.get("next")!="pan-para-el-pato":
    d["next"]="pan-para-el-pato"; json.dump(d,open(p,"w",encoding="utf-8"),ensure_ascii=False,indent=1)

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
for st in (s18,s19,s20):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"(c(?:18|19|20)_[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
