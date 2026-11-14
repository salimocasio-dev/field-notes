# La nevera (place 3, scene 3): stories 30, 31, 32 and the scene's picture pairs. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/nevera.md
import json,glob,os,re
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); AB=lambda t:D("abuela","Abuela",t); MA=lambda t:D("mama","Mamá",t); AO=lambda t:D("abuelo","Abuelo",t)
tw=lambda k:{"set":{"twinkle":k}}
def act(_n,**k): return dict({"act":_n},**k)
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
say=lambda c,gap=250:{"say":c,"gap":gap}
ok=lambda:{"if":"ok","then":[act("marca",que="ok")]}
X=[act("marca",que="x"),{"cost":1}]
CARD={"set":{"tarjeta":"rondas","marcas":[None,None,None]}}
comunes={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!"),"p_n_luis":N("Este es Luis."),"p_n_carmen":N("Esta es Carmen."),"abuela":N("Esta es abuela."),
 "esta_es_mama":N("Esta es mamá."),"n_papa":N("Este es papá."),"n_abuelo":N("Este es abuelo."),"m_n_cocina":N("Es la cocina."),"c30_nevera":N("Esta es la nevera.")}
BASE={"luis":"p_n_luis","carmen":"p_n_carmen","coqui":"yo_coqui","abuela":"abuela","mama":"esta_es_mama","papa":"n_papa","abuelo":"n_abuelo","cocina":"m_n_cocina","nevera":"c30_nevera"}

# ---------------- 30. No hay leche ----------------
c=dict(comunes)
LQ={"leche":"leche","queso":"queso"}; EL={"leche":"la leche","queso":"el queso"}
c.update({"c30_aqui_leche":N("Aquí hay leche."),"c30_aqui_queso":N("Y aquí hay queso."),"c30_bebe_toma":N("El bebé toma leche."),"c30_carmen_come":N("Carmen come pan con queso."),
 "c30_ab_mira_hay":AB("Coquí, mira en la nevera. ¿Hay leche? ¿Hay queso?"),"c30_ab_mira":AB("Coquí, mira en la nevera."),
 "c30_cq_piragua":T("¡Una piragua!"),"c30_ahora_los2":N("Ahora hay leche y queso."),"c30_cq_gracias_papa":T("¡Gracias, papá!"),"c30_no_piragua":N("No hay piragua para Coquí.")})
for k in LQ:
    o="queso" if k=="leche" else "leche"
    c["c30_cq_no_"+k]=T("¡Papá, no hay %s!"%k); c["c30_busca_"+k]=N("Papá busca %s."%EL[k]); c["c30_ahora_"+k]=N("Ahora hay %s."%k)
    c["c30_si_%s_no_%s"%(o,k)]=AB("Sí hay %s. No hay %s."%(o,k)); c["c30_no_%s_si_%s"%(k,o)]=AB("No hay %s. Sí hay %s."%(k,o))
    c["c30_ab_si_"+k]=AB("Sí hay %s."%k); c["c30_ab_no_"+k]=AB("No hay %s."%k); c["c30_no_"+k]=N("No, Coquí. Mira. No hay %s."%k)
DN=["di_leche","di_queso"]; VN={"di_leche":"c30_cq_no_leche","di_queso":"c30_cq_no_queso"}; DC=["c_leche","c_queso"]
def ida(k,**kw): return [act("sale30"),act("mandado",k=k,suelto=1,**kw),"c30_busca_"+k,act("ya")]
def ronda(k):   # what follows a touch in a scored round: the first errand is paid from the sill; a second one, after a miss, from the frog's own jar
    return {"right":[{"if":"ok","then":[act("sale30")]},act("mandado",k="$"+k,suelto=1,carta=1),"c30_busca_$"+k,act("ya"),{"if":"ok","then":[act("marca",que="ok")],"else":[act("comparten")]},act("abuelavuelve")],
            "wrong":[act("sale30"),act("mandado",k="$x",carta=1)]+X+["c30_no_$"+k]}
s30={"id":"no-hay-leche","title":"No hay leche","place":"La cocina","scene":"nevera","next":"para-los-pajaros",
 "goal":"Keep the fridge stocked, and keep your three coins for a piragua.","stake":{"thing":"monedas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["leche","queso","no hay","busca"],"back_again":["hay","sí","aquí","ahora","mira","come","toma","bebé","pan","con","piragua","tira","coge","gracias"],
 "also_heard":["nevera"],"names":BASE,"palabras":{"nohay":"no hay"},"clips":c,
 "beats":[act("inicio30"),{"wait":500},tw("nevera"),"c30_nevera",tw("leche"),"c30_aqui_leche",tw("queso"),"c30_aqui_queso",tw(None),act("consume30",suelto=1),"c30_bebe_toma","c30_carmen_come",act("ya"),
  # the opening: say (twice), picture cards with both halves (twice), picture cards with one line (twice)
  {"dots":1},act("mira30",abre="todo"),
  ask("di_leche","c30_ab_mira_hay",["c30_ahora_leche",act("abuelavuelve")],ida("leche"),resp=DN,baraja=True,voces=VN,said={"di_leche":"c30_cq_no_leche"}),
  act("mira30",abre="todo",toma=1),
  ask("di_queso","c30_ab_mira",["c30_ahora_queso",act("abuelavuelve")],ida("queso"),resp=DN,baraja=True,voces=VN,said={"di_queso":"c30_cq_no_queso"}),
  {"dots":2},act("setnev",falta="leche"),act("mira30",abre="poco"),
  ask("c_leche","c30_si_queso_no_leche",[act("abuelavuelve")],ida("leche",carta=1),resp=DC,baraja=True),
  act("setnev",falta="queso"),act("mira30",abre="poco"),
  ask("c_queso","c30_no_queso_si_leche",[act("abuelavuelve")],ida("queso",carta=1),resp=DC,baraja=True),
  {"dots":3},act("setnev",falta="queso"),act("mira30",abre="poco"),
  ask("c_queso","c30_ab_si_leche",[act("abuelavuelve")],ida("queso",carta=1),resp=DC,baraja=True),
  act("setnev",falta="leche"),act("mira30",abre="poco"),
  ask("c_leche","c30_ab_no_leche",[act("abuelavuelve")],ida("leche",carta=1),resp=DC,baraja=True),
  # the turn: the piragua man's bell
  {"dots":4},act("turno30"),say("c30_cq_piragua"),CARD,{"wait":400},
  # A: he sees in, and says what there is none of
  {"dots":5},{"draw":"fa","options":["leche","queso"]},act("setnev",falta="$fa"),act("mira30",abre="todo"),
  dict({"decide":"say","options":DN,"baraja":True,"pick":"di_$fa","tests":"$fa","voces":VN,"said":VN,"lead":[],"line":"c30_ab_mira"},**ronda("fa")),
  # B: she says both halves; he answers with a picture card
  {"dots":6},{"draw":"fb","options":["leche","queso"],"other":"gb"},{"draw":"ob","options":["1","2"]},{"calc":"lb","cond":"ob=1","then":"c30_si_$gb_no_$fb","else":"c30_no_$fb_si_$gb"},
  act("setnev",falta="$fb"),act("mira30",abre="poco"),
  dict({"decide":"say","options":DC,"baraja":True,"pick":"c_$fb","tests":"nohay","lead":[],"line":"$lb"},**ronda("fb")),
  # C: she says one line; he answers with a picture card
  {"dots":7},{"draw":"fc","options":["leche","queso"],"other":"gc"},{"draw":"sc","options":["si","no"]},{"calc":"lc","cond":"sc=no","then":"c30_ab_no_$fc","else":"c30_ab_si_$gc"},
  act("setnev",falta="$fc"),act("mira30",abre="poco"),
  dict({"decide":"say","options":DC,"baraja":True,"pick":"c_$fc","tests":"nohay","lead":[],"line":"$lc"},**ronda("fc"))],
 "final":[{"dots":8},"c30_ahora_los2",act("final30"),{"if":"pir","then":[say("c30_cq_gracias_papa",300)],"else":["c30_no_piragua"]},act("fin")],
 "leer":["c30_nevera","c30_aqui_leche","c30_aqui_queso","c30_bebe_toma","c30_carmen_come","c30_ab_mira_hay","c30_cq_no_leche","c30_busca_leche","c30_ahora_leche","c30_ab_mira","c30_cq_no_queso","c30_busca_queso","c30_ahora_queso",
  "c30_si_queso_no_leche","c30_no_queso_si_leche","c30_ab_si_leche","c30_ab_no_leche","c30_cq_piragua","c30_ahora_los2","c30_cq_gracias_papa"]}
json.dump(s30,open("cuentos/no-hay-leche.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 31. Para los pájaros ----------------
c=dict(comunes)
ART={"pan":"El pan","fruta":"La fruta","guineo":"El guineo","manzana":"La manzana"}
c.update({"c31_vamos":AB("Vamos al parque."),"c31_busca":N("Abuela busca comida para el parque."),"c31_aqui_pan":N("Aquí hay pan."),"c31_aqui_fruta":N("Y aquí hay fruta."),"c31_aqui_gm":N("Aquí hay guineos y manzanas."),
 "c31_huele_pan":N("Abuela huele el pan."),"c31_fo_pan":AB("¡Fo! Este pan no huele bien."),"c31_para_pajaros":AB("Este pan es para los pájaros."),"c31_tira_pan":N("Coquí tira el pan."),"c31_pajaro_pan":N("El pájaro come pan."),"c31_carmen_fruta":N("Carmen come fruta."),
 "c31_huele_fruta":N("Abuela huele la fruta."),"c31_esta_fruta":AB("Esta fruta no huele bien."),"c31_tira_fruta":N("Coquí tira la fruta."),"c31_pajaro_fruta":N("El pájaro come fruta."),"c31_luis_pan":N("Luis come pan."),
 "c31_este_guineo":AB("Este guineo no huele bien."),"c31_guineo_pajaros":N("El guineo es para los pájaros."),"c31_carmen_manzana":N("Carmen come la manzana."),
 "c31_esta_manzana":AB("Esta manzana no huele bien."),"c31_manzana_pajaros":N("La manzana es para los pájaros."),"c31_luis_guineo":N("Luis come el guineo."),
 "c31_abuelo_mira":AO("Coquí, mira la fruta."),"c31_cq_guineo":T("¡El guineo no huele bien!"),"c31_cq_manzana":T("¡La manzana no huele bien!"),"c31_abuelo_manzana":N("Abuelo come la manzana."),"c31_abuelo_guineo":N("Abuelo come el guineo."),
 "c31_abuelo_vamos":AO("¡Vamos al parque!"),"c31_aqui_pan_fruta":AB("Aquí hay pan y fruta para el parque."),"c31_van":N("Luis y Carmen van al parque."),"c31_cq_adios":T("¡Adiós, abuela!")})
for k in ART:
    c["c31_ab_%s_no"%k]=AB("%s no huele bien."%ART[k]); c["c31_no_%s"%k]=N("No, Coquí. Mira. %s no huele bien."%ART[k])
DG=["di_guineo","di_manzana"]; VG={"di_guineo":"c31_cq_guineo","di_manzana":"c31_cq_manzana"}
s31={"id":"para-los-pajaros","title":"Para los pájaros","place":"La cocina","scene":"nevera","next":"jugo-de-china",
 "goal":"Fill the picnic basket with good things for the park.","stake":{"thing":"comida","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["fruta","guineo","manzana","pan"],"back_again":["huele","bien","tira","busca","pájaro","come","hay","aquí","vamos","parque","para","comida","este","esta","mira","adiós"],
 "also_heard":["fo","van"],"names":BASE,"clips":c,
 "beats":[act("inicio31"),{"wait":500},"c31_vamos","c31_busca",tw("cesta"),"c31_aqui_pan",tw("frutas"),"c31_aqui_fruta",tw(None),act("cajon31",ver=1),"c31_aqui_gm",act("cajon31",ver=0),
  # the opening: touch a thing (twice), touch a person (twice), say (twice)
  {"dots":1},act("lote",viejo="pan",izq="pan"),act("huele31",a="pan",suelto=1),"c31_huele_pan",act("ya"),"c31_fo_pan",
  ask("t_pan","c31_para_pajaros",["c31_pajaro_pan",act("resto31",a="carmen",suelto=1),"c31_carmen_fruta",act("ya")],[act("tira31",a="t_pan",suelto=1),"c31_tira_pan",act("ya")]),
  act("lote",viejo="fruta",izq="fruta"),act("huele31",a="fruta",suelto=1),"c31_huele_fruta",act("ya"),
  ask("t_fruta","c31_esta_fruta",["c31_pajaro_fruta",act("resto31",a="luis",suelto=1),"c31_luis_pan",act("ya")],[act("tira31",a="t_fruta",suelto=1),"c31_tira_fruta",act("ya")]),
  {"dots":2},act("sostienen",luis="guineo"),act("huelemanos",orden=1),
  ask("luis","c31_este_guineo",["c31_guineo_pajaros",act("nino31",a="carmen",suelto=1),"c31_carmen_manzana",act("ya")],[act("quita",a="luis")]),
  act("sostienen",luis="guineo"),act("huelemanos",orden=2),
  ask("carmen","c31_esta_manzana",["c31_manzana_pajaros",act("nino31",a="luis",suelto=1),"c31_luis_guineo",act("ya")],[act("quita",a="carmen")]),
  {"dots":3},act("abuelaa31"),act("abuelo31",que="trae",viejo="guineo"),
  ask("di_guineo","c31_abuelo_mira",[act("abuelo31",que="come",suelto=1),"c31_abuelo_manzana",act("ya")],[act("abuelo31",que="tira",k="guineo")],resp=DG,baraja=True,voces=VG,said={"di_guineo":"c31_cq_guineo"}),
  act("abuelo31",que="trae",viejo="manzana"),
  ask("di_manzana","c31_abuelo_mira",[act("abuelo31",que="come",suelto=1),"c31_abuelo_guineo",act("ya")],[act("abuelo31",que="tira",k="manzana")],resp=DG,baraja=True,voces=VG,said={"di_manzana":"c31_cq_manzana"}),
  # the turn: abuelo with his hat on; the three last lots, one for each hollow
  {"dots":4},{"draw":"ka","options":["pan","fruta"],"other":"kb"},{"draw":"za","options":["pan","fruta"]},{"draw":"ha","options":["1","2"]},
  {"draw":"kc","options":["guineo","manzana"],"other":"kd"},{"draw":"qb","options":["guineo","manzana"]},{"draw":"hb","options":["1","2"]},{"draw":"ke","options":["guineo","manzana"],"other":"kf"},
  {"calc":"pv","cond":"kc=$qb","then":"luis","else":"carmen"},{"calc":"pw","cond":"kc=$qb","then":"carmen","else":"luis"},
  act("turno31"),say("c31_abuelo_vamos"),act("lotes31",viejo="$ka",izq="$za",luis="$qb",abuelo="$ke"),"c31_aqui_pan_fruta",CARD,{"wait":400},
  # A: bread or fruit, on the tray
  {"dots":5},act("huele31",orden="$ha",pano=1),act("abuelaa31",pano=1),
  {"decide":"do","options":["t_pan","t_fruta"],"pick":"t_$ka","tests":"$ka","lock":True,"lead":[],"line":"c31_ab_$ka_no",
   "right":[act("tira31",a="t_$ka"),{"if":"ok","then":[act("marca",que="ok"),act("resto31",guarda=1)]}],
   "wrong":[act("tira31",a="$x",bueno=1),act("resto31",voltea=1)]+X+["c31_no_$ka"]},
  # B: guineo or manzana, in the children's hands
  {"dots":6},act("huelemanos",orden="$hb"),
  {"decide":"do","options":["luis","carmen"],"pick":"$pv","tests":"$kc","lock":True,"lead":[],"line":"c31_ab_$kc_no",
   "right":[act("quita",a="$pv"),{"if":"ok","then":[act("marca",que="ok"),act("nino31",a="$pw",guarda=1)]}],
   "wrong":[act("quita",a="$x",bueno=1),act("nino31",a="$pv",manchas=1)]+X+["c31_no_$kc"]},
  # C: he sees the spots and says which; abuelo, who sees only the backs, throws what he names
  {"dots":7},act("abuelaa31"),act("abuelo31",que="pone"),
  {"decide":"say","options":DG,"baraja":True,"pick":"di_$ke","tests":"$ke","voces":VG,"said":VG,"lead":[],"line":"c31_abuelo_mira",
   "right":[act("abuelo31",que="tira",k="$ke"),{"if":"ok","then":[act("marca",que="ok"),act("abuelo31",que="da")]}],
   "wrong":[act("abuelo31",que="tira",k="$x"),act("abuelo31",que="mira")]+X+["c31_no_$ke"]}],
 "final":[{"dots":8},act("final31"),"c31_van",say("c31_cq_adios",300),act("fin")],
 "leer":["c31_vamos","c31_busca","c31_aqui_pan","c31_aqui_fruta","c31_aqui_gm","c31_huele_pan","c31_fo_pan","c31_para_pajaros","c31_tira_pan","c31_pajaro_pan","c31_carmen_fruta","c31_huele_fruta","c31_esta_fruta","c31_tira_fruta","c31_pajaro_fruta","c31_luis_pan",
  "c31_este_guineo","c31_guineo_pajaros","c31_carmen_manzana","c31_esta_manzana","c31_manzana_pajaros","c31_luis_guineo","c31_abuelo_mira","c31_cq_guineo","c31_abuelo_manzana","c31_cq_manzana","c31_abuelo_guineo",
  "c31_abuelo_vamos","c31_aqui_pan_fruta","c31_van","c31_cq_adios"]}
json.dump(s31,open("cuentos/para-los-pajaros.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 32. Jugo de china ----------------
c=dict(comunes)
COL={"verde":"verde","amarillo":"amarillo","rojo":"rojo","azul":"azul"}; EST={"lleno":"lleno","vacio":"vacío"}
c.update({"c32_calor":N("Hace calor."),"c32_hace_jugo":N("Abuela hace jugo de china."),"c32_aqui_chinas":N("Aquí hay chinas."),"c32_aqui_mant":N("Y aquí hay mantequilla."),
 "c32_le_pone":N("Abuela le pone mantequilla al pan."),"c32_luis_come":N("Luis come pan con mantequilla."),
 "c32_ab_un_vaso":AB("Coquí, un vaso está vacío. Ponle jugo de china."),"c32_ahora_amarillo":N("Ahora el vaso amarillo está lleno."),
 "c32_luis_mi_vacio":L("Mi vaso está vacío."),"c32_luis_mi_lleno":L("Mi vaso está lleno."),"c32_carmen_mi_vacio":CA("Mi vaso está vacío."),"c32_carmen_mi_lleno":CA("Mi vaso está lleno."),
 "c32_luis_toma":N("Luis toma jugo de china."),"c32_carmen_toma":N("Carmen toma jugo de china."),"c32_carmen_quiero":CA("Quiero pan con mantequilla y jugo de china."),"c32_carmen_come":N("Carmen come pan con mantequilla."),
 "c32_luis_mas":L("¡Más pan con mantequilla, por favor!"),"c32_mas_jugo":N("Abuela hace más jugo de china."),"c32_familia":N("La familia toma jugo de china."),
 "c32_ab_come":N("Abuela come pan con mantequilla."),"cq_gracias_abuela":T("¡Gracias, abuela!"),"c32_no_hay_mas":N("No hay más jugo.")})
for k in COL:
    for e in EST:
        c["c32_n_%s_%s"%(k,e)]=N("El vaso %s está %s."%(COL[k],EST[e]))
    c["c32_no_%s_vacio"%k]=N("No, Coquí. Mira. El vaso %s está vacío."%COL[k])
for k in ("rojo","azul"):
    for e in EST: c["c32_mama_%s_%s"%(k,e)]=MA("El vaso %s está %s."%(COL[k],EST[e]))
for k in ("verde","amarillo"):
    for e in EST: c["c32_ab_%s_%s"%(k,e)]=AB("El vaso %s está %s."%(COL[k],EST[e]))
AL={"luis":"v_verde","carmen":"v_amarillo"}; V2=["v_verde","v_amarillo"]
def vista(a,*pasos): return [act("vista",a=a)]+list(pasos)+[act("vista",a="")]
s32={"id":"jugo-de-china","title":"Jugo de china","place":"La cocina","scene":"nevera","next":None,
 "goal":"Give everybody juice from the last jug.","stake":{"thing":"jugo","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["china","mantequilla","lleno","vacío"],"back_again":["vaso","jugo","hace calor","hace","pone","pan","toma","mi","quiero","más","por favor","ahora","familia","verde","amarillo","rojo","azul","gracias","no hay"],
 "also_heard":["ponle","le pone"],"names":BASE,"palabras":{"vacio":"vacío"},"clips":c,
 "beats":[act("inicio32"),{"wait":500},"c32_calor",act("exprime",suelto=1),"c32_hace_jugo",act("ya"),tw("red"),"c32_aqui_chinas",tw("mant"),"c32_aqui_mant",tw(None),act("unta",a="luis",suelto=1),"c32_le_pone","c32_luis_come",act("ya"),
  # the opening: a round picture over a cup shows what is in it. Six signed steps: pour (two lines; the children's two lines; one line "lleno"; one line "vacío"), to the sink (one line "vacío"; one line "lleno")
  {"dots":1}]+vista("v_verde","c32_n_verde_lleno")+vista("v_amarillo","c32_n_amarillo_vacio")+[
  ask("v_amarillo","c32_ab_un_vaso",vista("v_amarillo","c32_ahora_amarillo"),[act("vierte",a="v_amarillo")]),
  act("ninos32",que="toman",bebe="carmen"),act("ninos32",que="dejan")]+vista("v_amarillo",say("c32_carmen_mi_vacio"))+[act("vista",a="v_verde"),
  ask("v_amarillo","c32_luis_mi_lleno",["c32_carmen_toma"],[act("vista",a=""),act("vierte",a="v_amarillo")],alias=AL),
  {"dots":2},act("mama32",que="trae",vacio="azul"),act("vista",a="v_rojo"),
  ask("v_azul","c32_mama_rojo_lleno",[act("mama32",que="lleva")],[act("vista",a=""),act("vierte",a="v_azul")]),
  act("ninos32",que="toman",bebe="luis"),act("ninos32",que="dejan"),act("abuelamira"),act("vista",a="v_verde"),
  ask("v_verde","c32_ab_verde_vacio",["c32_luis_toma"],[act("vista",a=""),act("vierte",a="v_verde")],alias=AL),
  {"dots":3},act("mama32",que="trae",vacio="rojo"),act("vista",a="v_rojo"),
  ask("v_rojo","c32_mama_rojo_vacio",[act("mama32",que="lleva")],[act("vista",a=""),act("lleva32",a="v_rojo")]),
  act("ninos32",que="toman",bebe="carmen"),act("ninos32",que="dejan"),act("abuelamira",sale=1),act("vista",a="v_verde"),
  ask("v_amarillo","c32_ab_verde_lleno",[act("abuelasale"),say("c32_carmen_quiero")],[act("vista",a=""),act("lleva32",a="v_amarillo")],alias=AL),
  # the turn: the last chinas
  {"dots":4},act("abuelavuelve"),act("exprime",todo=1,suelto=1),"c32_mas_jugo",act("ya"),act("mama32",que="lleva"),act("ninos32",que="toman"),act("ninos32",que="salen",con=1),"c32_carmen_come","c32_luis_mas",act("abuelamira",sale=1),act("abuelasale"),"c32_familia",CARD,{"wait":400},
  # A: two lines, the children's own
  {"dots":5},{"draw":"va","options":["verde","amarillo"],"other":"vb"},{"draw":"oa","options":["l","c"]},
  {"calc":"ll","cond":"va=verde","then":"c32_luis_mi_vacio","else":"c32_luis_mi_lleno"},{"calc":"lc","cond":"va=amarillo","then":"c32_carmen_mi_vacio","else":"c32_carmen_mi_lleno"},
  {"calc":"la","cond":"oa=l","then":"$ll","else":"$lc"},{"calc":"lb","cond":"oa=l","then":"$lc","else":"$ll"},
  act("ninos32",que="entran",vacio="$va"),act("ninos32",que="dejan"),
  {"decide":"do","options":V2,"pick":"v_$va","tests":"vacio","lock":True,"alias":AL,"lead":[say("$la")],"line":"$lb",
   "right":[act("vierte",a="v_$va"),ok()],
   "wrong":[act("vierte",a="$x")]+X+vista("v_$va","c32_no_$va_vacio")},
  act("ninos32",que="toman"),act("ninos32",que="salen",con=1),
  # B: one line, mamá's, of the red cup or the blue one
  {"dots":6},{"draw":"ra","options":["rojo","azul"],"other":"rb"},{"draw":"fa","options":["lleno","vacio"]},{"calc":"rn","cond":"fa=vacio","then":"$ra","else":"$rb"},
  act("mama32",que="trae",vacio="$ra"),
  {"decide":"do","options":["v_rojo","v_azul"],"pick":"v_$ra","tests":"$fa","lock":True,"lead":[],"line":"c32_mama_$rn_$fa",
   "right":[act("vierte",a="v_$ra"),ok(),act("mama32",que="lleva")],
   "wrong":[act("vierte",a="$x")]+X+vista("v_$ra","c32_no_$ra_vacio")},
  # C: one line, abuela's; he carries a cup to the sink
  {"dots":7},{"draw":"ga","options":["verde","amarillo"],"other":"gb"},{"draw":"fc","options":["lleno","vacio"]},{"calc":"gn","cond":"fc=vacio","then":"$ga","else":"$gb"},
  act("ninos32",que="entran",vacio="$ga"),act("ninos32",que="corren"),act("abuelamira",sale=1),
  {"decide":"do","options":V2,"pick":"v_$ga","tests":"$fc","lock":True,"lead":[],"line":"c32_ab_$gn_$fc",
   "right":[act("abuelasale"),act("lleva32",a="v_$ga"),ok()],
   "wrong":[act("abuelasale"),act("lleva32",a="$x")]+X+vista("v_$ga","c32_no_$ga_vacio")+[act("mirapila")]}],
 "final":[{"dots":8},act("abuelavuelve"),act("final32"),"c32_ab_come",{"if":"rana","then":[say("cq_gracias_abuela",300)],"else":["c32_no_hay_mas"]},act("fin")],
 "leer":["c32_calor","c32_hace_jugo","c32_aqui_chinas","c32_aqui_mant","c32_le_pone","c32_luis_come","c32_n_verde_lleno","c32_n_amarillo_vacio","c32_ab_un_vaso","c32_ahora_amarillo","c32_carmen_mi_vacio","c32_luis_mi_lleno","c32_carmen_toma",
  "c32_mama_rojo_lleno","c32_ab_verde_vacio","c32_luis_toma","c32_mama_rojo_vacio","c32_ab_verde_lleno","c32_carmen_quiero","c32_carmen_come","c32_luis_mas","c32_mas_jugo","c32_familia","c32_ab_come","cq_gracias_abuela"]}
json.dump(s32,open("cuentos/jugo-de-china.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- the next-day picture pairs ----------------
NO={"x":0,"y":0,"s":1,"dy":0,"al":1,"vis":0,"bub":None,"hace":None,"piensa":None}
def pic(cam,**kw): return {"cam":cam,"set":dict({"cq":NO,"gente":{},"nev":{"abierta":0,"h":[]},"mos":{},"patio":{},"repisa":[],"cesta":None,"canasta":None,"cosas":[],"vuelos":[],"banco":0,"encima":None,"tarjeta":None,"pila":None,"vista":None},**kw)}
ENC=112
def nino(**kw): return dict({"x":150,"y":200,"dir":1},**kw)
def adulto(**kw): return dict({"x":150,"y":204,"dir":1},**kw)
CN=[118,154,94.2,50]; CT=[124,152,56.5,30]; CP=[116,142,75.3,40]; CA=[110,146,113,60]; CM=[132,92,75.3,40]; CZ=[132,97,56.5,30]; CF=[36,50,75.3,40]; CV=[127,36,113,60]
PAR={"m_n_carmen_leche":N("Carmen toma leche."),"m_n_el_queso":N("Mira el queso."),"m_n_no_hay_leche":N("No hay leche."),"m_n_papa_busca":N("Papá busca el pan."),"m_n_mi_fruta":N("Mira mi fruta."),"m_n_bebe_guineo":N("El bebé come guineo."),
 "m_n_mi_manzana":N("Mira mi manzana."),"m_n_tu_china":N("Dame tu china, por favor."),"m_n_plato_lleno":N("El plato está lleno."),"m_n_mi_vaso_vacio":N("Mi vaso está vacío.")}
todos={**s30["clips"],**s31["clips"],**s32["clips"],**PAR}
usa=list(PAR)+["c31_aqui_pan","c32_le_pone","muy_bien","si_muy_bien"]
FR=lambda h:{"abierta":1,"soporte":1,"h":h}
cual={"id":"cual-nevera","title":"¿Cuál?","place":"La cocina","scene":"nevera","tipo":"cual","stake":{"thing":"none","steps":0},
 "note":"The next-day pass for La nevera.","clips":{k:todos[k] for k in usa},
 "items":[
  {"w":"leche","say":"m_n_carmen_leche","si":pic(CT,gente={"carmen":nino(bebe={"k":"claro","v":"leche"})}),"no":pic(CT,gente={"carmen":nino(bebe={"k":"claro","v":1})})},
  {"w":"queso","say":"m_n_el_queso","si":pic(CZ,cosas=[{"k":"platoazul","x":160,"y":ENC+11,"z":300},{"k":"queso","v":3,"x":160,"y":ENC+9,"z":301}]),"no":pic(CZ,cosas=[{"k":"mantequilla","v":3,"x":160,"y":ENC+10,"z":300}])},
  {"w":"no hay","say":"m_n_no_hay_leche","si":pic(CF,nev=FR([None,{"k":"queso","v":3}])),"no":pic(CF,nev=FR([{"k":"leche","v":4},None]))},
  {"w":"busca","say":"m_n_papa_busca","si":pic(CV,gente={"papa":{"x":184,"y":120,"dir":1,"fuera":1,"alza":{"k":"bolsa","v":"abuelo","e":1,"dx":12,"dy":2},"piensa":{"k":"panecillo","e":2}}}),"no":pic(CV,gente={"papa":{"x":184,"y":120,"dir":-1,"fuera":1,"come":{"k":"rebanada"}}})},
  {"w":"fruta","say":"m_n_mi_fruta","si":pic(CA,gente={"abuelo":adulto(alza={"k":"platofruta","dx":16,"dy":12})}),"no":pic(CA,gente={"abuelo":adulto(alza={"k":"platorollo","dx":16,"dy":12})})},
  {"w":"guineo","say":"m_n_bebe_guineo","si":pic(CA,gente={"mama":adulto(bebe="come",bebecosa={"k":"guineo","v":"medio"})}),"no":pic(CA,gente={"mama":adulto(bebe="come",bebecosa={"k":"manzana"})})},
  {"w":"manzana","say":"m_n_mi_manzana","si":pic(CN,gente={"luis":nino(alza={"k":"manzana"})}),"no":pic(CN,gente={"luis":nino(alza={"k":"china"})})},
  {"w":"china","say":"m_n_tu_china","si":pic(CA,gente={"carmen":{"x":140,"y":204,"dir":1,"pose":"offer"},"abuelo":{"x":184,"y":204,"dir":-1,"alza":{"k":"china","dx":16,"dy":10}}}),"no":pic(CA,gente={"carmen":{"x":140,"y":204,"dir":1,"pose":"offer"},"abuelo":{"x":184,"y":204,"dir":-1,"alza":{"k":"guineo","dx":18,"dy":10}}})},
  {"w":"pan","say":"c31_aqui_pan","si":pic(CM,cosas=[{"k":"cesta","v":4,"x":166,"y":ENC+10,"z":300}]),"no":pic(CM,cosas=[{"k":"ollaarroz","x":166,"y":ENC+10,"z":300}])},
  {"w":"mantequilla","say":"c32_le_pone","si":pic(CM,gente={"abuela":{"x":158,"y":157,"dir":1,"pose":"offer"}},cosas=[{"k":"mantequilla","v":3,"x":178,"y":ENC+7,"z":300},{"k":"untando","x":198,"y":ENC+12,"z":301}]),"no":pic(CM,gente={"abuela":{"x":158,"y":157,"dir":1,"pose":"offer"}},cosas=[{"k":"platoazul","x":178,"y":ENC+8,"z":300},{"k":"queso","v":3,"x":178,"y":ENC+6,"z":301},{"k":"conqueso","x":198,"y":ENC+12,"z":302}])},
  {"w":"lleno","say":"m_n_plato_lleno","si":pic(CN,gente={"luis":nino(alza={"k":"platolleno","dx":15,"dy":10})}),"no":pic(CN,gente={"luis":nino(alza={"k":"plato","dx":15,"dy":10})})},
  {"w":"vacío","say":"m_n_mi_vaso_vacio","si":pic(CP,gente={"papa":adulto(alza={"k":"claroalreves","dx":15,"dy":-4})}),"no":pic(CP,gente={"papa":adulto(bebe={"k":"claro","v":1})})}]}
json.dump(cual,open("cuentos/cual-nevera.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# the story before this scene leads into it
p="cuentos/cuidado.json"; d=json.load(open(p,encoding="utf-8"))
if d.get("next")!="no-hay-leche":
    d["next"]="no-hay-leche"; json.dump(d,open(p,"w",encoding="utf-8"),ensure_ascii=False,indent=1)

# clip ids are global: the same id must have the same text everywhere
seen={}; clash=0; new=0; chars=0
for f in sorted(glob.glob("cuentos/*.json")):
    if "zz-" in f or "zmesa" in f or "zestufa" in f or "znevera" in f: continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items():
        key=(cl.get("who"),cl.get("text"))
        if cid in seen and seen[cid]!=key: print("CLASH",cid,seen[cid],key,f); clash+=1
        seen.setdefault(cid,key)
for cid,(who,text) in seen.items():
    if not os.path.exists(f"audio/{cid}.mp3"): new+=1; chars+=len(text)
print(len(seen),"clips,",new,"new,",chars,"characters to record,",clash,"clashes")
for st in (s30,s31,s32):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"(c(?:30|31|32)_[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
