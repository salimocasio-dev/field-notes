# El patio: stories 9, 10, 11 and the scene's picture pairs. Regenerates the JSON; never edit the JSON by hand.
import json,glob,os
os.chdir("/home/user/field-notes/historia")
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
A=lambda t:D("abuela","Abuela",t); AO=lambda t:D("abuelo","Abuelo",t); MA=lambda t:D("mama","Mamá",t); PA=lambda t:D("papa","Papá",t)
L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
tw=lambda k:{"set":{"twinkle":k}}
pose=lambda q,p:{"act":"pose","quien":q,"que":p}
comunes={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"abuela":N("Esta es abuela."),"puerta":N("Es la puerta."),"yo_coqui":T("¡Coquí!"),
 "esta_es_mama":N("Esta es mamá."),"n_papa":N("Este es papá."),"n_abuelo":N("Este es abuelo."),"n_bebe":N("Este es el bebé."),
 "p_n_luis":N("Este es Luis."),"p_n_carmen":N("Esta es Carmen."),"p_n_bola":N("Es la bola."),"p_n_saco":N("Es el saco de Luis."),"p_n_flores":N("Son las flores de abuela."),"p_n_sol":N("Es el sol."),
 "p_n_porton":N("Es el portón."),"p_n_nido":N("Es la casa del pájaro."),"p_n_arbol":N("Es el árbol."),"p_n_casa":N("Es la casa de abuela."),"p_n_patio":N("Es el patio."),"p_n_pajaro":N("Es el pájaro.")}
NOMBRES={"luis":"p_n_luis","carmen":"p_n_carmen","abuela":"abuela","abuelo":"n_abuelo","mama":"esta_es_mama","papa":"n_papa","bebe":"n_bebe","bola":"p_n_bola","saco":"p_n_saco","caja":"p_n_flores","camaL":"p_n_flores","camaR":"p_n_flores",
 "sol":"p_n_sol","porton":"p_n_porton","nido":"p_n_nido","arbol":"p_n_arbol","puerta":"puerta","casa":"p_n_casa","patio":"p_n_patio","pajaro":"p_n_pajaro","coqui":"yo_coqui"}
ask=lambda k,line,then=None,after=None,**kw:dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)

# ---------------- 9. Las flores ----------------
c=dict(comunes)
c.update({"p_es_el_patio":N("Este es el patio de abuela."),"p_mira_luis_carmen":N("Mira. Luis y Carmen."),"p_luis_nino":N("Luis es un niño."),"p_carmen_nina":N("Carmen es una niña."),
 "p_puedes_nino":N("¿Puedes tocar al niño?"),"p_luis_hola_coqui":L("¡Hola, Coquí!"),"p_nino_juega_bola":N("El niño juega con la bola."),
 "p_donde_nina":N("¿Y la niña? ¿Dónde está la niña?"),"p_carmen_hola":CA("¡Hola!"),"p_nina_tiene_flor":N("La niña tiene una flor."),
 "p_mira_el_sol":N("Mira el sol."),"p_donde_sol":N("¿Dónde está el sol?"),"p_es_el_sol":N("Es el sol."),
 "p_carmen_flor_aqui":CA("Una flor aquí."),"p_carmen_flor_alla":CA("Una flor allá."),"p_luis_flor_aqui":L("Una flor aquí."),"p_luis_flor_alla":L("Una flor allá."),
 "p_carmen_si_esta_aqui":CA("¡Sí! La flor está aquí."),"p_carmen_y_flor_alla":CA("Y una flor allá."),"p_carmen_esta_alla":CA("La flor está allá."),
 "p_luis_esta_aqui":L("La flor está aquí."),"p_luis_esta_alla":L("La flor está allá."),
 "p_carmen_ahora_tu":CA("Ahora tú, Coquí."),"p_no_aqui":N("No. Aquí."),"p_no_alla":N("No. Allá."),
 "p_ab_flor_para_nino":A("Una flor para el niño."),"p_ab_flor_para_nina":A("Una flor para la niña."),"p_no_para_nino":N("No. Para el niño."),"p_no_para_nina":N("No. Para la niña."),
 "p_nino_nina_juegan":N("El niño juega. La niña juega."),"p_cq_yo_tambien":T("¡Yo también!")})
for q,F in (("luis",L),("carmen",CA)):
    c[f"p_{q}_no_alla_a"]=F("¡Aquí no! ¡Allá!"); c[f"p_{q}_no_alla_b"]=F("¡Allá! ¡Aquí no!"); c[f"p_{q}_no_aqui_a"]=F("¡Allá no! ¡Aquí!"); c[f"p_{q}_no_aqui_b"]=F("¡Aquí! ¡Allá no!")
def cama(q,oq,c_,oc,w,t,line):
    return [{"draw":q,"options":["luis","carmen"],"other":oq},{"draw":c_,"options":["L","R"],"other":oc},{"draw":w,"options":["aqui","alla"]},{"calc":t,"cond":f"{w}=aqui","then":f"${c_}","else":f"${oc}"},
     {"act":"anda","quien":f"${oq}","a":"espera"},{"act":"anda","quien":f"${q}","a":"detras","cama":f"${c_}"},
     {"decide":"do","options":["camaL","camaR"],"pick":f"cama${t}","tests":f"${w}","lock":True,"lead":[],"line":line,
      "right":[{"act":"planta","cama":f"${t}","mari":"1"}],"wrong":[{"act":"planta","cama":"$x","ok":"0"},f"p_no_${w}",{"cost":1}]}]
flores={"id":"las-flores","title":"Las flores","place":"La casa","scene":"patio","next":"que-es-esto",
 "goal":"Plant abuela's flowers while there is daylight.","stake":{"thing":"sol","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["niño","niña","juega","flor","sol","aquí","allá"],"back_again":["hola","no","sí","tiene","para","ahora","tú","yo","también"],
 "also_heard":["patio","bola","con","una","está"],
 "names":NOMBRES,"palabras":{"aqui":"aquí","alla":"allá","nino":"niño","nina":"niña"},"clips":c,
 "beats":[{"act":"inicio9"},{"wait":400},{"act":"sale"},"p_es_el_patio",
  {"dots":1},"p_mira_luis_carmen",tw("luis"),"p_luis_nino",tw("carmen"),"p_carmen_nina",tw(None),
  ask("luis","p_puedes_nino",[pose("luis","wave"),{"say":"p_luis_hola_coqui","gap":250},pose("luis","idle"),{"act":"juega"},"p_nino_juega_bola"]),
  ask("carmen","p_donde_nina",[pose("carmen","wave"),{"say":"p_carmen_hola","gap":250},{"act":"maceta","quien":"carmen"},"p_nina_tiene_flor",{"act":"maceta","quien":"carmen","suelta":"1"}]),
  {"dots":2},tw("sol"),"p_mira_el_sol",tw(None),ask("sol","p_donde_sol",[{"act":"brilla"},"p_es_el_sol"]),
  {"dots":3},{"act":"ir","a":"caja"},{"act":"anda","quien":"carmen","a":"detras","cama":"L"},
  ask("camaL","p_carmen_flor_aqui",[{"act":"planta","cama":"L"},"p_carmen_si_esta_aqui"]),
  ask("camaR","p_carmen_y_flor_alla",[{"act":"planta","cama":"R"},"p_carmen_esta_alla"]),
  {"dots":4},{"act":"anda","quien":"carmen","a":"espera"},{"act":"anda","quien":"luis","a":"detras","cama":"R"},
  ask("camaR","p_luis_flor_aqui",[{"act":"planta","cama":"R"},"p_luis_esta_aqui"]),
  ask("camaL","p_luis_no_alla_a",[{"act":"planta","cama":"L"},"p_luis_esta_alla"]),
  {"act":"anda","quien":"luis","a":"espera"},{"act":"anda","quien":"carmen","x":"86","y":"136"},{"say":"p_carmen_ahora_tu","gap":300},{"act":"ensena"},
  {"dots":5}]+cama("qa","oqa","ca","oca","wa","ta","p_$qa_flor_$wa")+[
  {"dots":6},{"act":"lados"},{"act":"asoma"},{"draw":"n","options":["nino","nina"]},{"calc":"pn","cond":"n=nino","then":"luis","else":"carmen"},
  {"decide":"do","options":["luis","carmen"],"pick":"$pn","tests":"$n","lock":True,"lead":[],"line":"p_ab_flor_para_$n",
   "right":[{"act":"dale","a":"$pn"}],"wrong":[{"act":"dale","a":"$x","ok":"0"},"p_no_para_$n",{"cost":1}]},
  {"act":"entra"},{"act":"manos"},
  {"dots":7}]+cama("qc","oqc","cc","occ","wc","tc","p_$qc_no_$wc_$ord")[:3]+[{"draw":"ord","options":["a","b"]}]+cama("qc","oqc","cc","occ","wc","tc","p_$qc_no_$wc_$ord")[3:],
 "final":[{"act":"final9"},{"recuerda":"flores","valor":"$flores"},{"act":"pelota"},"p_nino_nina_juegan",{"act":"pelota2"},{"say":"p_cq_yo_tambien","gap":400},{"wait":700}],
 "leer":["p_es_el_patio","p_luis_nino","p_carmen_nina","p_puedes_nino","p_luis_hola_coqui","p_nino_juega_bola","p_donde_nina","p_nina_tiene_flor","p_mira_el_sol","p_es_el_sol","p_carmen_flor_aqui","p_carmen_si_esta_aqui",
  "p_carmen_y_flor_alla","p_carmen_esta_alla","p_luis_flor_aqui","p_luis_no_alla_a","p_carmen_ahora_tu","p_ab_flor_para_nina","p_nino_nina_juegan","p_cq_yo_tambien"]}
json.dump(flores,open("cuentos/las-flores.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 10. ¿Qué es esto? ----------------
c=dict(comunes)
c.update({"p_luis_ven_coqui":L("¡Ven, Coquí!"),"p_luis_hola_amigo":L("¡Hola, amigo!"),"p_cq_hola_luis_amigo":T("¡Hola, Luis! Tú eres mi amigo."),
 "p_carmen_mira_pajaro":CA("¡Mira, Coquí! ¡El pájaro!"),"p_luis_pajaro_amigo":L("El pájaro es mi amigo."),"p_cq_hola_amigo":T("¡Hola, amigo!"),
 "p_carmen_ven_ven":CA("¡Ven, Coquí! ¡Ven!"),"p_carmen_coqui_amigo":CA("Coquí es mi amigo."),"p_luis_mira_mira":L("¡Mira, Coquí! ¡Mira!"),
 "p_luis_que_es_esto":L("¿Qué es esto?"),"p_cq_es_flor":T("Es una flor."),"p_cq_es_vaso":T("Es un vaso."),"p_cq_es_silla":T("Es una silla."),"p_cq_es_bizcocho":T("Es un bizcocho."),
 "p_luis_si_es_flor":L("¡Sí! Es una flor."),"p_luis_si_es_silla":L("¡Sí! Es una silla."),"p_luis_si_es_bizcocho":L("¡Sí! Es un bizcocho."),
 "p_luis_no_es_silla":L("No. Es una silla."),"p_luis_no_es_bizcocho":L("No. Es un bizcocho."),
 "p_cq_que_es_esto":T("¿Qué es esto?"),"p_cq_como_estas":T("¿Cómo estás?"),"p_cq_quien_eres":T("¿Quién eres tú?"),"p_luis_es_un_vaso":L("Es un vaso."),
 "p_luis_no_amigo":L("¡No, amigo! ¡No!"),"p_carmen_ven_coqui":CA("¡Ven, Coquí!"),"p_carmen_mira_coqui":CA("¡Mira, Coquí!"),"p_no_ven_coqui":N("No. ¡Ven, Coquí!"),"p_no_mira_coqui":N("No. ¡Mira, Coquí!"),
 "p_luis_es_bola":L("Es una bola. ¡Es mi bola!"),"p_luis_resp_como":L("Bien."),"p_luis_resp_quien":L("Yo soy Luis."),"p_no_que_es_esto":N("No. ¿Qué es esto?"),
 "p_luis_coqui_amigo":L("Coquí es mi amigo."),"p_cq_y_tu_amigo":T("¡Y tú eres mi amigo!"),"p_cq_y_tu_tambien":T("¡Y tú también, amigo!")})
HACER=["ir","ver"]
VZ={"es_flor":"p_cq_es_flor","es_vaso":"p_cq_es_vaso","es_silla":"p_cq_es_silla","es_bizcocho":"p_cq_es_bizcocho"}
VQ={"q_que":"p_cq_que_es_esto","q_como":"p_cq_como_estas","q_quien":"p_cq_quien_eres"}
que={"id":"que-es-esto","title":"¿Qué es esto?","place":"La casa","scene":"patio","next":"hasta-manana",
 "goal":"Fill his basket with what comes out of Luis's sack, before the bird takes it.","stake":{"thing":"cosas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["¿qué es esto?","amigo","mira","ven"],"back_again":["pájaro","flor","vaso","silla","bizcocho","sí","no","tú","eres","¿cómo estás?"],
 "also_heard":["esto","mi","bola","es","un","una"],
 "names":NOMBRES,"palabras":{"que":"¿qué es esto?"},"clips":c,
 "beats":[{"act":"inicio10"},{"wait":600},
  {"dots":1},ask("ir","p_luis_ven_coqui",["p_luis_hola_amigo",{"say":"p_cq_hola_luis_amigo","gap":300}],[{"act":"ir","a":"luis"}],resp=HACER,baraja=True),
  {"dots":2},{"act":"aveloop"},ask("ver","p_carmen_mira_pajaro",[{"act":"ojos","on":"0"},"p_luis_pajaro_amigo",{"say":"p_cq_hola_amigo","gap":300},{"act":"avenido"}],[{"act":"ojos","x":"1","y":"-1"},{"act":"avecabeza"}],resp=HACER,baraja=True),
  {"dots":3},ask("ir","p_carmen_ven_ven",["p_carmen_coqui_amigo"],[{"act":"ir","a":"carmen"},{"act":"acaricia","quien":"carmen"}],resp=HACER,baraja=True),
  {"dots":4},ask("ver","p_luis_mira_mira",[{"act":"ojos","on":"0"},{"act":"ir","a":"luis"}],[{"act":"ojos","x":"1","y":"0"},{"act":"saca","que":"flor"}],resp=HACER,baraja=True),
  ask("es_flor","p_luis_que_es_esto",["p_luis_si_es_flor",{"act":"alpelo"}],resp=["es_flor","es_vaso"],baraja=True,voces=VZ,said={"es_flor":"p_cq_es_flor"}),
  {"dots":5},{"act":"turno","que":"vaso"},ask("q_que",None,["p_luis_es_un_vaso",{"act":"acarmen"}],resp=["q_que","q_como"],baraja=True,voces=VQ,said={"q_que":"p_cq_que_es_esto"}),
  {"act":"avepica"},{"say":"p_luis_no_amigo","gap":200},{"act":"avenido"},{"act":"marcador"},
  {"dots":6},{"act":"prepA"},{"draw":"wa","options":["ven","mira"]},{"calc":"pa","cond":"wa=ven","then":"ir","else":"ver"},
  {"decide":"say","options":HACER,"baraja":True,"pick":"$pa","tests":"$wa","lock":True,"lead":[],"line":"p_carmen_$wa_coqui",
   "right":[{"if":"wa=ven","then":[{"act":"llega"}],"else":[{"act":"gira"}]}],
   "wrong":[{"if":"wa=ven","then":[{"act":"mirasolo"}],"else":[{"act":"choca"}]},"p_no_$wa_coqui",{"cost":1}]},
  {"act":"ojos","on":"0"},{"act":"pose","quien":"carmen","que":"idle"},{"act":"anda","quien":"carmen","x":"50","y":"160"},
  {"dots":7},{"act":"ir","a":"luis"},{"draw":"tb","options":["silla","bizcocho"],"other":"otb"},{"draw":"ob","options":["flor","$otb"]},{"act":"saca","que":"$tb"},
  {"decide":"say","options":["es_$tb","es_$ob"],"baraja":True,"pick":"es_$tb","tests":"$tb","voces":VZ,"said":VZ,"lead":[],"line":"p_luis_que_es_esto",
   "right":["p_luis_si_es_$tb",{"act":"alcanasta"}],"wrong":["p_luis_no_es_$tb",{"act":"roba","de":"luis"},{"cost":1}]},
  {"dots":8},{"act":"turno","que":"bola"},{"draw":"dc","options":["como","quien"]},
  {"decide":"say","options":["q_que","q_$dc"],"baraja":True,"pick":"q_que","tests":"que","voces":VQ,"said":VQ,"lead":[],
   "right":["p_luis_es_bola",{"act":"rie","quien":"luis"},{"act":"alcanasta","de":"cq"}],"wrong":["p_luis_resp_$dc",{"act":"encoge"},{"act":"roba","de":"cq"},{"cost":1},"p_no_que_es_esto"]}],
 "final":[{"act":"final10"},"p_luis_coqui_amigo",{"say":"p_cq_y_tu_amigo","gap":300},{"say":"p_cq_y_tu_tambien","gap":400},{"wait":700}],
 "leer":["p_luis_ven_coqui","p_luis_hola_amigo","p_cq_hola_luis_amigo","p_carmen_mira_pajaro","p_luis_pajaro_amigo","p_cq_hola_amigo","p_carmen_ven_ven","p_carmen_coqui_amigo","p_luis_mira_mira","p_luis_que_es_esto","p_cq_es_flor","p_luis_si_es_flor",
  "p_cq_que_es_esto","p_luis_es_un_vaso","p_luis_no_amigo","p_luis_es_bola","p_luis_coqui_amigo","p_cq_y_tu_amigo","p_cq_y_tu_tambien"]}
json.dump(que,open("cuentos/que-es-esto.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 11. Hasta mañana ----------------
c=dict(comunes)
c.update({"p_mira_el_sol":N("Mira el sol."),"p_luis_vamos_vamos":L("¡Vamos, Coquí! ¡Vamos al portón!"),"p_cq_vamos":T("¡Vamos!"),"p_ab_coqui_ven":A("¡Coquí! ¡Ven!"),
 "p_ab_adios_hm":A("Adiós, Coquí. ¡Hasta mañana!"),"p_cq_hm_abuela":T("¡Hasta mañana, abuela!"),"p_cq_hola_abuela":T("¡Hola, abuela!"),
 "p_mama_hm_coqui":MA("¡Hasta mañana, Coquí!"),"p_papa_hm":PA("¡Hasta mañana!"),"p_cq_hm":T("¡Hasta mañana!"),"p_carmen_vamos_coqui":CA("¡Vamos, Coquí!"),
 "p_carmen_adios_coqui":CA("Adiós, Coquí."),"p_cq_hola":T("¡Hola!"),"p_cq_de_nada":T("De nada."),"p_no_hasta_manana":N("No. ¡Hasta mañana!"),
 "p_ao_para_ti":AO("Para ti, Coquí."),"p_cq_gracias_abuelo":T("¡Gracias, abuelo!"),"p_cq_hola_abuelo":T("¡Hola, abuelo!"),"p_ao_de_nada":AO("De nada."),"p_no_gracias":N("No. ¡Gracias!"),
 "p_luis_ven_coqui":L("¡Ven, Coquí!"),"p_luis_vamos_porton":L("¡Vamos al portón!"),"p_no_ven_coqui":N("No. ¡Ven, Coquí!"),"p_no_vamos_porton":N("No. ¡Vamos al portón!"),
 "p_familia_adios_hm":D("abuela","La familia","¡Adiós, Coquí! ¡Hasta mañana!"),"p_cq_adios_hm":T("¡Adiós! ¡Hasta mañana!")})
VB={"hm":"p_cq_hm","hola":"p_cq_hola","denada":"p_cq_de_nada","gracias_abuelo":"p_cq_gracias_abuelo","hola_abuelo":"p_cq_hola_abuelo","hm_abuela":"p_cq_hm_abuela","hola_abuela":"p_cq_hola_abuela"}
decA=[{"act":"viene","quien":"carmen"},{"draw":"da","options":["hola","denada"]},
 {"decide":"say","options":["hm","$da"],"baraja":True,"pick":"hm","tests":"hasta","voces":VB,"said":VB,"lead":[],"line":"p_carmen_adios_coqui",
  "right":[{"act":"luz","cual":"carmen"},{"act":"saluda","quien":"carmen"},{"act":"anda","quien":"carmen","x":"198","y":"166","dir":"-1"}],
  "wrong":[{"act":"duda","quien":"carmen"},{"cost":1,"en":"carmen"},"p_no_hasta_manana"]}]
decB=[{"act":"viene","quien":"abuelo"},{"draw":"db","options":["denada","hola_abuelo"]},
 {"decide":"say","options":["gracias_abuelo","$db"],"baraja":True,"pick":"gracias_abuelo","tests":"gracias","voces":VB,"said":VB,"lead":[],"line":"p_ao_para_ti",
  "right":[{"act":"toma"},{"act":"luz","cual":"abuelo"},{"say":"p_ao_de_nada","gap":300},{"act":"guarda"},{"act":"anda","quien":"abuelo","x":"62","y":"128","dir":"1"}],
  "wrong":[{"act":"duda","quien":"abuelo"},{"cost":1,"en":"abuelo"},"p_no_gracias"]}]
hasta={"id":"hasta-manana","title":"Hasta mañana","place":"La casa","scene":"patio",
 "goal":"Say goodbye and go home, with the fireflies to light the way.","stake":{"thing":"luces","steps":3},"dots":6,"bien":"si_muy_bien",
 "focus_words":["vamos","hasta mañana"],"back_again":["adiós","hola","ven","gracias","de nada","abuela","abuelo","mamá","papá","sol","mira","para"],
 "also_heard":["portón","al","ti"],
 "names":NOMBRES,"palabras":{"hasta":"hasta mañana"},"clips":c,
 "beats":[{"act":"inicio11"},{"wait":600},"p_mira_el_sol",{"act":"puesta"},
  {"dots":1},ask("porton","p_luis_vamos_vamos",[{"say":"p_cq_vamos","gap":300}],[{"act":"juntos"}]),
  {"dots":2},pose("abuela","wave"),ask("abuela","p_ab_coqui_ven",[{"act":"vuelveluis"}],[{"act":"ir","a":"abuela"}]),
  {"dots":3},ask("hm_abuela","p_ab_adios_hm",[pose("abuela","idle")],resp=["hm_abuela","hola_abuela"],baraja=True,voces=VB,said={"hm_abuela":"p_cq_hm_abuela"}),
  pose("mama","wave"),{"say":"p_mama_hm_coqui","gap":250},pose("mama","idle"),pose("papa","wave"),{"say":"p_papa_hm","gap":250},pose("papa","idle"),{"act":"saluda","quien":"bebe"},{"say":"p_cq_hm","gap":300},
  {"act":"junto","quien":"carmen"},{"say":"p_carmen_vamos_coqui","gap":250},{"act":"alcentro","quien":"carmen","x":"186","y":"170"},
  {"act":"oscurece"},
  {"dots":4},{"draw":"orden","options":["ab","ba"]},{"if":"orden=ab","then":decA+[{"dots":5}]+decB,"else":decB+[{"dots":5}]+decA},
  {"dots":6},{"act":"ir","a":"centro"},{"draw":"wc","options":["ven","vamos"]},{"calc":"pc","cond":"wc=ven","then":"luis","else":"porton"},
  {"calc":"lc","cond":"wc=ven","then":"p_luis_ven_coqui","else":"p_luis_vamos_porton"},{"calc":"nc","cond":"wc=ven","then":"p_no_ven_coqui","else":"p_no_vamos_porton"},
  {"decide":"do","options":["luis","porton"],"pick":"$pc","tests":"$wc","lock":True,"lead":[],"line":"$lc",
   "right":[{"if":"wc=ven","then":[{"act":"ir","a":"luisC"},{"act":"abrazo"},{"act":"luz","cual":"medio"},{"say":"p_luis_vamos_porton","gap":250},{"act":"juntos"}],"else":[{"act":"juntos"},{"act":"luz","cual":"medio"}]}],
   "wrong":[{"if":"wc=ven","then":[{"act":"ir","a":"porton"},{"act":"duda","quien":"cq"}],"else":[{"act":"luiscorre"},{"act":"ir","a":"luisC"},{"act":"duda","quien":"cq"}]},{"cost":1,"en":"medio"},"$nc"]},
  {"act":"abre"}],
 "final":[{"act":"adios"},"p_familia_adios_hm",{"say":"p_cq_adios_hm","gap":300},{"act":"final11"},{"act":"sevan"},{"wait":500}],
 "leer":["p_mira_el_sol","p_luis_vamos_vamos","p_cq_vamos","p_ab_coqui_ven","p_ab_adios_hm","p_cq_hm_abuela","p_mama_hm_coqui","p_papa_hm","p_cq_hm","p_carmen_vamos_coqui","p_carmen_adios_coqui","p_ao_para_ti","p_cq_gracias_abuelo","p_ao_de_nada",
  "p_luis_ven_coqui","p_luis_vamos_porton","p_familia_adios_hm","p_cq_adios_hm"]}
json.dump(hasta,open("cuentos/hasta-manana.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- ¿Cuál? for El patio ----------------
P=lambda x,y,**k:dict({"x":x,"y":y,"pose":"idle"},**k)
cq=lambda x,y,s=1,**k:dict({"x":x-16,"y":y-27,"s":s,"dy":0,"al":1,"vis":1,"bub":None},**k)
NO=cq(0,0,vis=0)
F1=lambda k:{"L":[{"k":1,"c":2}] if k=="L" else [],"R":[{"k":1,"c":2}] if k=="R" else []}
FAMILIA=dict(abuela=P(34,136,pose="wave",dir=1),abuelo=P(60,126,pose="wave"),mama=P(86,136,pose="wave"),papa=P(112,126,pose="wave"))
todos={**flores["clips"],**que["clips"],**hasta["clips"],"p_c_nino":N("Es un niño."),"p_c_nina":N("Es una niña."),"p_c_juega":N("El niño juega."),"p_c_flor":N("Es una flor."),
 "p_c_aqui":CA("La flor está aquí."),"p_c_amigo":L("Es mi amigo."),"p_c_mira":L("¡Mira, Coquí!")}
usa=["p_c_nino","p_c_nina","p_c_juega","p_c_flor","p_n_sol","p_c_aqui","p_luis_esta_alla","p_c_amigo","p_carmen_ven_coqui","p_c_mira","p_carmen_vamos_coqui","p_cq_hm","muy_bien","si_muy_bien"]
CB=[42,118,156,82.8]; CM=[40,100,170,90.2]
cual={"id":"cual-patio","title":"¿Cuál?","place":"La casa","scene":"patio","tipo":"cual","stake":{"thing":"none","steps":0},
 "note":"The next-day pass for El patio.","clips":{k:todos[k] for k in usa},
 "items":[
  {"w":"niño","say":"p_c_nino","si":{"cam":[64,118,113,60],"set":{"gente":{"luis":P(120,170)},"cq":NO}},"no":{"cam":[64,118,113,60],"set":{"gente":{"carmen":P(120,170)},"cq":NO}}},
  {"w":"niña","say":"p_c_nina","si":{"cam":[40,80,113,60],"set":{"gente":{"carmen":P(86,136)},"caja":1,"cq":NO}},"no":{"cam":[40,80,113,60],"set":{"gente":{"mama":P(86,138)},"caja":1,"cq":NO}}},
  {"w":"juega","say":"p_c_juega","si":{"cam":[30,124,150,79.6],"set":{"gente":{"luis":P(126,172,pose="wave")},"bola":{"x":140,"y":172,"h":30},"flores":F1("L"),"cq":NO}},
   "no":{"cam":[30,124,150,79.6],"set":{"gente":{"luis":P(126,172,pose="ojos",lleva="maceta")},"bola":{"x":146,"y":174},"flores":F1("L"),"cq":NO}}},
  {"w":"flor","say":"p_c_flor","si":{"cam":[16,146,113,60],"set":{"flores":F1("L"),"cq":NO}},"no":{"cam":[16,146,113,60],"set":{"bola":{"x":48,"y":188},"cq":NO}}},
  {"w":"sol","say":"p_n_sol","si":{"cam":[30,0,170,90.2],"set":{"cq":NO}},"no":{"cam":[30,0,170,90.2],"set":{"noche":1,"luna":1,"osc":.6,"cq":NO}}},
  {"w":"aquí","say":"p_c_aqui","si":{"cam":CB,"set":{"gente":{"carmen":P(68,176)},"flores":F1("L"),"cq":NO}},"no":{"cam":CB,"set":{"gente":{"carmen":P(68,176)},"flores":F1("R"),"cq":NO}}},
  {"w":"allá","say":"p_luis_esta_alla","si":{"cam":CB,"set":{"gente":{"luis":P(68,176)},"flores":F1("R"),"cq":NO}},"no":{"cam":CB,"set":{"gente":{"luis":P(68,176)},"flores":F1("L"),"cq":NO}}},
  {"w":"amigo","say":"p_c_amigo","si":{"cam":[50,130,113,60],"set":{"gente":{"luis":P(118,180,pose="offer")},"cq":cq(88,184)}},"no":{"cam":[50,130,113,60],"set":{"gente":{"luis":P(118,180,pose="offer")},"bola":{"x":90,"y":182},"cq":NO}}},
  {"w":"ven","say":"p_carmen_ven_coqui","si":{"cam":CM,"set":{"gente":{"carmen":P(170,176,pose="offer")},"cq":cq(128,180,dy=-8),"polvo":{"x":106,"y":178,"dir":-1}}},
   "no":{"cam":CM,"set":{"gente":{"carmen":P(170,176,pose="alto",dir=-1)},"cq":cq(80,180,ojos=1,ojx=1,ojy=-1),"ave":{"mode":"fly","x":124,"y":128,"dir":1,"st":"n"},"rizo":{"x":124,"y":124,"r":12}}}},
  {"w":"mira","say":"p_c_mira","si":{"cam":CM,"set":{"gente":{"luis":P(160,178,pose="alto",dir=-1)},"cq":cq(118,182,ojos=1,ojx=0,ojy=-1),"ave":{"mode":"fly","x":124,"y":128,"dir":1,"st":"n"},"rizo":{"x":124,"y":124,"r":12}}},
   "no":{"cam":CM,"set":{"gente":{"luis":P(170,178,pose="offer")},"cq":cq(128,182,dy=-8),"polvo":{"x":106,"y":180,"dir":-1},"ave":{"mode":"none"}}}},
  {"w":"vamos","say":"p_carmen_vamos_coqui","si":{"cam":[70,62,150,79.6],"set":{"porton":1,"gente":{"carmen":P(168,120,dir=-1)},"cq":cq(144,126,.85,dy=-6),"polvo":{"x":134,"y":132,"dir":-1}}},
   "no":{"cam":[70,62,150,79.6],"set":{"gente":{"carmen":P(170,138,sent=1,pose="ojos",lleva="vaso")},"cq":cq(138,138,.85),"lleva":"vaso"}}},
  {"w":"hasta mañana","say":"p_cq_hm","si":{"cam":[24,40,180,95.5],"set":{"sol":3,"soly":73,"osc":.2,"pdoor":1,"porton":1,"gente":FAMILIA,"cq":cq(146,128,.85)}},
   "no":{"cam":[24,40,180,95.5],"set":{"pdoor":1,"gente":FAMILIA,"cq":cq(134,132,.9)}}}]}
json.dump(cual,open("cuentos/cual-patio.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# quien-eres-tu leads on to las-flores
p="cuentos/quien-eres-tu.json"; d=json.load(open(p,encoding="utf-8"))
if d.get("next")!="las-flores":
    nd={}
    for k,v in d.items():
        nd[k]=v
        if k=="scene": nd["next"]="las-flores"
    json.dump(nd,open(p,"w",encoding="utf-8"),ensure_ascii=False,indent=1)
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
# every line used in a story must exist as a clip
import re
for st in (flores,que,hasta):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    ids=set(re.findall(r'"(p_[a-z_$]+)"',txt))
    for i in sorted(ids):
        if "$" in i: continue
        if i not in st["clips"]: print("MISSING CLIP",st["id"],i)
