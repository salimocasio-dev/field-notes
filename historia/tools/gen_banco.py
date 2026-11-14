# El banco (place 2, scene 4): stories 21, 22, 23 and the scene's picture pairs. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/banco.md
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
comunes={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!"),"p_n_luis":N("Este es Luis."),"p_n_carmen":N("Esta es Carmen."),"c_n_perro":N("Es el perro. Se llama Canelo."),
 "c_n_parque":N("Es el parque."),"l_n_pajaro":N("Es un pájaro."),"c_c_perro":N("Es un perro."),"abuela":N("Esta es abuela."),
 "b_n_banco":N("Es un banco."),"b_n_piraguero":N("Es el piragüero."),"b_n_hombre":N("Es un hombre."),"b_n_mujer":N("Es una mujer."),"b_n_senor":N("Es un señor."),"b_n_senora":N("Es una señora."),"b_n_joven":N("Es un joven."),"b_n_bebe":N("Es un bebé.")}
BASE={"luis":"p_n_luis","carmen":"p_n_carmen","coqui":"yo_coqui","parque":"c_n_parque","pajaro":"l_n_pajaro","banco0":"b_n_banco","banco1":"b_n_banco","banco2":"b_n_banco","piraguero":"b_n_piraguero","carro":"b_n_piraguero"}

# ---------------- 21. La piragua ----------------
c=dict(comunes)
c.update({"c21_un_hombre":N("Mira. Un hombre."),"c21_una_mujer":N("Y una mujer."),
 "c21_para_hombre":N("La piragua es para el hombre."),"c21_para_mujer":N("La piragua es para la mujer."),"c21_para_nino":N("La piragua es para el niño."),"c21_para_nina":N("La piragua es para la niña."),
 "c21_agua_mujer":N("El agua es para la mujer."),"c21_hombre_come":N("El hombre come."),"c21_mujer_bebe":N("La mujer bebe agua."),
 "c21_cq_come":T("¡El pájaro come!"),"c21_cq_bebe":T("¡El pájaro bebe!"),"c21_h_gracias":D("hombre","El hombre","¡Gracias!"),"c21_m_gracias":D("mujer","La mujer","¡Gracias!"),
 "c21_ca_come":CA("¡Come, Coquí!"),"c21_ca_bebe":CA("¡Bebe, Coquí!"),"c21_coqui_come":N("Coquí come piragua."),"c21_coqui_bebe":N("Coquí bebe agua."),
 "c21_ay":N("¡Ay, no! El pájaro se come la piragua de Coquí."),
 "c21_no_mira_come":N("No, Coquí. Mira. El pájaro come."),"c21_no_mira_bebe":N("No, Coquí. Mira. El pájaro bebe."),
 "c21_no_para_hombre":N("No, Coquí. La piragua es para el hombre."),"c21_no_para_mujer":N("No, Coquí. La piragua es para la mujer."),"c21_no_para_nino":N("No, Coquí. La piragua es para el niño."),"c21_no_para_nina":N("No, Coquí. La piragua es para la niña."),
 "c21_no_ca_come":{"who":"narr","habla":"carmen","text":"No, Coquí. Carmen dice: ¡Come!"},"c21_no_ca_bebe":{"who":"narr","habla":"carmen","text":"No, Coquí. Carmen dice: ¡Bebe!"},
 "c21_fin":N("Coquí come piragua. Carmen bebe agua."),"c21_y_pajaro":N("¿Y el pájaro? ¡El pájaro quiere más!"),"c17_cq_no_mas":T("¡No más!")})
DV=["di_come","di_bebe"]; VV={"di_come":"c21_cq_come","di_bebe":"c21_cq_bebe"}; DO=["come","bebe"]
s21={"id":"la-piragua","title":"La piragua","place":"El parque","scene":"banco","next":"senor-senora",
 "goal":"Get each thing to the one it is for, and keep it from the pigeons.","stake":{"thing":"palomas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["hombre","mujer","come","bebe"],"back_again":["pájaro","agua","para","niño","niña","quiere","mira","gracias","no más"],
 "also_heard":["piragua"],"names":dict(BASE,hombre="b_n_hombre",mujer="b_n_mujer"),"palabras":{"nino":"-","nina":"-"},"clips":c,
 "beats":[act("inicio21"),{"wait":500},tw("hombre"),"c21_un_hombre",tw("mujer"),"c21_una_mujer",tw(None),
  {"dots":1},act("pon",k="piragua"),ask("hombre","c21_para_hombre",["c21_hombre_come"],[act("lleva",a="hombre")]),
  act("pon",k="agua"),ask("mujer","c21_agua_mujer",["c21_mujer_bebe"],[act("lleva",a="mujer")]),
  {"dots":2},act("casa"),act("dejan"),act("paloma",k="come"),
  ask("di_come",None,[say("c21_h_gracias"),act("acaba",a="hombre")],[act("salva",k="come")],resp=DV,baraja=True,voces=VV,said={"di_come":"c21_cq_come"}),
  act("paloma",k="bebe"),
  ask("di_bebe",None,[say("c21_m_gracias"),act("acaba",a="mujer"),act("sinbandeja")],[act("salva",k="bebe")],resp=DV,baraja=True,voces=VV,said={"di_bebe":"c21_cq_bebe"}),
  {"dots":3},act("manos",i="piragua",d="agua"),
  ask("come","c21_ca_come",["c21_coqui_come",act("termina",que="come")],[act("empieza",que="come")],resp=DO,baraja=True),
  act("llena"),
  ask("bebe","c21_ca_bebe",["c21_coqui_bebe",act("termina",que="bebe")],[act("empieza",que="bebe")],resp=DO,baraja=True),
  {"dots":4},act("turno21"),"c21_ay",{"wait":300},act("limpia"),CARD,{"wait":400},
  {"dots":5},act("nuevas"),act("dejan"),{"draw":"pa","options":["come","bebe"]},{"calc":"qa","cond":"pa=come","then":"h","else":"m"},act("paloma",k="$pa"),
  {"decide":"say","options":DV,"baraja":True,"pick":"di_$pa","tests":"$pa","voces":VV,"said":VV,"lead":[],"line":None,
   "right":[{"if":"ok","then":[act("salva",k="$pa"),act("marca",que="ok"),say("c21_$qa_gracias")],"else":[act("salva",k="$pa",medio=1)]}],   # put right while the pigeon is still at it: half is saved, and the pigeon stays
   "wrong":[act("miraotra",k="$pa")]+X+["c21_no_mira_$pa"]},
  act("acaban"),
  {"dots":6},{"draw":"pb","options":["hombre","mujer","hombre","mujer","nino","nina"]},{"calc":"tb","cond":"pb=nino","then":"luis","else":"$pb"},{"calc":"tb","cond":"pb=nina","then":"carmen","else":"$tb"},
  act("pon",k="piragua",de="piraguero"),
  {"decide":"do","options":["hombre","mujer","luis","carmen"],"pick":"$tb","tests":"$pb","lock":True,"lead":[],"line":"c21_para_$pb",
   "right":[act("lleva",a="$tb"),ok()],
   "wrong":[act("llevamal",a="$x")]+X+[act("pon",k="piragua",de="piraguero"),"c21_no_para_$pb"]},
  act("casa"),act("sinbandeja"),act("tragan"),
  {"dots":7},{"draw":"mc","options":["pa","ap"]},{"draw":"vc","options":["come","bebe"]},
  {"if":"mc=pa","then":[act("manos",i="piragua",d="agua")],"else":[act("manos",i="agua",d="piragua")]},act("acecha"),
  {"decide":"say","options":DO,"baraja":True,"pick":"$vc","tests":"$vc","lead":[],"line":"c21_ca_$vc",
   "right":[act("empieza",que="$vc"),{"if":"ok","then":[act("sale",que="$vc",hizo="$vc")]},act("termina",que="$vc"),ok()],
   "wrong":[act("empieza",que="$x"),act("sale",que="$vc",hizo="$x"),act("termina",que="$x")]+X+[act("repone",que="$vc"),"c21_no_ca_$vc"]},   # only what the pigeon took is replaced
  act("otro",que="$vc"),act("limpia")],
 "final":[{"dots":8},act("final21"),"c21_fin",act("quiere"),"c21_y_pajaro",say("c17_cq_no_mas",300),act("fin21"),{"wait":600}],
 "leer":["c21_un_hombre","c21_una_mujer","c21_para_hombre","c21_hombre_come","c21_agua_mujer","c21_mujer_bebe","c21_cq_come","c21_h_gracias","c21_cq_bebe","c21_m_gracias","c21_ca_come","c21_coqui_come","c21_ca_bebe","c21_coqui_bebe",
  "c21_ay","c21_para_mujer","c21_fin","c21_y_pajaro","c17_cq_no_mas"]}
json.dump(s21,open("cuentos/la-piragua.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 22. ¡Señor! ¡Señora! ----------------
c=dict(comunes)
SE=lambda t:D("senor","El señor",t); SA=lambda t:D("mujer","La señora",t); JO=lambda t:D("joven","El joven",t)
c.update({"c22_un_senor":N("Mira. Un señor."),"c22_una_senora":N("Una señora."),"c22_un_joven":N("Y un joven."),"c22_perro_viejo":N("Un perro viejo."),"c22_perro_joven":N("Y un perro joven."),
 "c22_cq_senor":T("¡Señor!"),"c22_cq_senora":T("¡Señora!"),"c22_cq_joven":T("¡Joven!"),
 "c22_senor_sombrero":SE("¡Mi sombrero! ¡Gracias!"),"c22_cq_dn_senor":T("De nada, señor."),"c22_cq_dn_senora":T("De nada, señora."),
 "c22_senor_gracias":SE("¡Gracias!"),"c22_senora_gracias":SA("¡Gracias!"),"c22_joven_gracias":JO("¡Gracias!"),
 "c22_ca_es_senor":CA("¡Es del señor!"),"c22_ca_es_senora":CA("¡Es de la señora!"),"c22_ca_es_joven":CA("¡Es del joven!"),
 "c22_senor_gracias_coqui":SE("¡Gracias, Coquí!"),"c22_senora_gracias_coqui":SA("¡Gracias, Coquí!"),"c22_joven_gracias_coqui":JO("¡Gracias, Coquí!"),
 "c22_ca_perro_joven":CA("¡Es del perro joven!"),"c22_ca_perro_viejo":CA("¡Es del perro viejo!"),
 "c22_joven_corre":N("El perro joven corre."),"c22_viejo_no_corre":N("El perro viejo no corre."),"c22_viejo_camina":N("El perro viejo camina despacio."),
 "c22_ay":N("¡Ay, no!"),"c22_l_senor":L("¡Señor! ¡Señor!"),"c22_donde":N("¿Dónde está el hombre?"),
 "c22_no_es_senor":N("No, Coquí. Es un señor."),"c22_no_es_senora":N("No, Coquí. Es una señora."),"c22_no_es_joven":N("No, Coquí. Es un joven."),
 "c22_no_perro_viejo":N("No, Coquí. Es del perro viejo."),"c22_no_perro_joven":N("No, Coquí. Es del perro joven."),
 "c22_no_del_senor":N("No, Coquí. Es del señor."),"c22_no_del_senora":N("No, Coquí. Es de la señora."),"c22_no_del_joven":N("No, Coquí. Es del joven."),
 "c22_fin":N("El perro viejo camina despacio. El perro joven corre."),"c22_cq_adios":T("¡Adiós, señor!")})
DS=["di_senor","di_senora","di_joven"]; VS={"di_senor":"c22_cq_senor","di_senora":"c22_cq_senora","di_joven":"c22_cq_joven"}
s22={"id":"senor-senora","title":"¡Señor! ¡Señora!","place":"El parque","scene":"banco","next":"el-bebe-duerme",
 "goal":"Get each thing to its owner before the owner has gone home.","stake":{"thing":"cosas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["señor","señora","joven","viejo"],"back_again":["hombre","perro","camina","despacio","corre","¿dónde está?","gracias","de nada","adiós"],
 "also_heard":["del","de la","mi sombrero"],"names":dict(BASE,senor="b_n_senor",mujer="b_n_senora",joven="b_n_joven",hombre="b_n_hombre",perro_viejo="c_c_perro",perro_joven="c_c_perro"),
 "palabras":{"senor":"señor","senora":"señora"},"clips":c,
 "beats":[act("inicio22"),{"wait":500},tw("senor"),"c22_un_senor",tw("mujer"),"c22_una_senora",tw("joven"),"c22_un_joven",tw("perro_viejo"),"c22_perro_viejo",tw("perro_joven"),"c22_perro_joven",tw(None),
  {"dots":1},act("alcarro"),
  ask("di_senor",None,[say("c22_senor_sombrero"),say("c22_cq_dn_senor",200)],[act("vuelve22",a="senor")],resp=DS,baraja=True,voces=VS,said={"di_senor":"c22_cq_senor"}),
  ask("di_senora",None,[say("c22_senora_gracias"),say("c22_cq_dn_senora",200)],[act("vuelve22",a="mujer")],resp=DS,baraja=True,voces=VS,said={"di_senora":"c22_cq_senora"}),
  ask("di_joven",None,[say("c22_joven_gracias"),act("sientan")],[act("vuelve22",a="joven")],resp=DS,baraja=True,voces=VS,said={"di_joven":"c22_cq_joven"}),
  {"dots":2},act("bolsa"),ask("mujer","c22_ca_es_senora",[say("c22_senora_gracias_coqui"),act("casa")],[act("dabolsa",a="mujer")]),
  {"dots":3},act("hueso"),ask("perro_joven","c22_ca_perro_joven",[act("ronda"),"c22_joven_corre","c22_viejo_no_corre",act("ronda",fin=1)],[act("dahueso",a="perro_joven"),act("casa")]),
  act("hueso"),ask("perro_viejo","c22_ca_perro_viejo",[act("paseo"),"c22_viejo_camina",act("paseo",fin=1)],[act("dahueso",a="perro_viejo"),act("casa")]),
  {"dots":4},act("turno22"),"c22_ay",act("luisve"),say("c22_l_senor"),"c22_donde",act("luiscaja"),CARD,{"wait":400},
  {"dots":5},{"draw":"lb","options":["vj","jv"]},{"draw":"vb","options":["viejo","joven"]},act("perros22",lado="$lb"),act("hueso"),
  {"decide":"do","options":["perro_viejo","perro_joven"],"pick":"perro_$vb","tests":"$vb","lock":True,"lead":[],"line":"c22_ca_perro_$vb",
   "right":[{"if":"ok","then":[act("dahueso",a="perro_$vb"),act("marca",que="ok")],"else":[act("acaricia",a="perro_$vb")]}],             # there is no other bone
   "wrong":[act("dahueso",a="$x",echa=1),act("sinhueso",de="perro_$vb")]+X+[tw("perro_$vb"),"c22_no_perro_$vb",tw(None)]},
  act("casa"),
  {"dots":6},{"draw":"qa","options":["senora","senora","senor","joven"]},{"calc":"pa","cond":"qa=senora","then":"mujer","else":"$qa"},act("sale22",a="$pa"),
  {"decide":"say","options":DS,"baraja":True,"pick":"di_$qa","tests":"$qa","voces":VS,"said":VS,"lead":[],"line":None,
   "right":[{"if":"ok","then":[act("recoge",a="$pa"),say("c22_$qa_gracias"),act("marca",que="ok"),act("adios",a="$pa")],"else":[act("sevade",a="$pa"),act("luisguarda",k="cartera")]}],   # too late: a wave from beyond the gate
   "wrong":[act("duda",x="$x"),act("pasa",a="$pa")]+X+["c22_no_es_$qa"]},
  {"dots":7},{"draw":"kc","options":["a","b"]},{"draw":"lc","options":["ab","ba"]},act("cola22",k="$kc",lado="$lc"),act("bolsa"),
  {"decide":"do","options":["$ra","$rb"],"pick":"$pc","tests":"$qc","lock":True,"lead":[],"line":"c22_ca_es_$qc",
   "right":[{"if":"ok","then":[act("dabolsa",a="$pc"),say("c22_$qc_gracias_coqui"),act("marca",que="ok")],"else":[act("alza",a="$pc"),act("luisguarda",k="bolsa")]}],
   "wrong":[act("dabolsa",a="$x",no=1),act("pasa",a="$pc")]+X+["c22_no_del_$qc"]},
  act("sevan22")],
 "final":[{"dots":8},act("final22"),act("carrova"),"c22_fin",say("c22_cq_adios",300),act("carrofin"),{"wait":600}],
 "leer":["c22_un_senor","c22_una_senora","c22_un_joven","c22_perro_viejo","c22_perro_joven","c22_cq_senor","c22_senor_sombrero","c22_cq_dn_senor","c22_cq_senora","c22_senora_gracias","c22_cq_dn_senora","c22_cq_joven","c22_joven_gracias",
  "c22_ca_es_senora","c22_senora_gracias_coqui","c22_ca_perro_joven","c22_joven_corre","c22_viejo_no_corre","c22_ca_perro_viejo","c22_viejo_camina","c22_ay","c22_l_senor","c22_donde","c22_fin","c22_cq_adios"]}
json.dump(s22,open("cuentos/senor-senora.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 23. El bebé duerme ----------------
c=dict(comunes)
LA=lambda t:D("senora","La señora",t)
c.update({"c23_un_bebe":N("Mira. Un bebé."),"c23_duerme":N("El bebé duerme."),"c23_ca_shh":CA("Shh. El bebé duerme."),
 "c23_luis_cansado":N("Luis está cansado."),"c23_canelo_contento":N("Canelo está contento."),"c23_senor_triste":N("El señor está triste."),"c23_carmen_contenta":N("Y Carmen está contenta."),
 "c23_ca_quien_triste":CA("¿Quién está triste?"),"c23_ca_quien_cansado":CA("¿Quién está cansado?"),"c23_ca_quien_contento":CA("¿Quién está contento?"),
 "c23_ahora_senor":N("Ahora el señor está contento."),"c23_ab_como":AB("¿Cómo está Canelo?"),"c23_ab_y_ahora":AB("¿Y ahora? ¿Cómo está Canelo?"),
 "c23_cq_contento":T("¡Está contento!"),"c23_cq_cansado":T("¡Está cansado!"),"c23_cq_triste":T("¡Está triste!"),
 "c23_ahora_contento":N("Ahora Canelo está contento."),
 "c23_sa_shh_duerme":LA("Shh. El bebé duerme."),"c23_sa_ahora_contento":LA("Ahora el bebé está contento."),"c23_ahora_duerme":N("Ahora el bebé duerme."),
 "c23_ca_shh_coqui":CA("Shh, Coquí. El bebé duerme."),"c23_sa_duerme":LA("El bebé duerme."),"c23_sa_contento":LA("El bebé está contento."),
 "c23_no_shh":N("No, Coquí. Shh. Ahora el bebé duerme."),"c23_no_no_duerme":N("No, Coquí. Mira. El bebé no duerme."),
 "c23_no_mira_cansado":N("No, Coquí. Mira. Canelo está cansado."),"c23_no_mira_contento":N("No, Coquí. Mira. Canelo está contento."),"c23_no_mira_triste":N("No, Coquí. Mira. Canelo está triste."),
 "c23_no_canelo_cansado":N("No, Coquí. Canelo está cansado."),"c23_no_luis_triste":N("No, Coquí. Luis está triste."),"c23_no_senor_contento":N("No, Coquí. El señor está contento."),
 "c23_otra":D("hombre","El señor","¡Otra! ¡Gracias!"),
 "c23_fin_canelo":N("Canelo está cansado."),"c23_fin_coqui":N("Y Coquí está muy cansado."),"c23_ab_vamos":AB("Vamos a casa."),"p_cq_hm":T("¡Hasta mañana!")})
DF=["di_contento","di_cansado","di_triste"]; VF={"di_contento":"c23_cq_contento","di_cansado":"c23_cq_cansado","di_triste":"c23_cq_triste"}; DQ=["canta","quieto"]
s23={"id":"el-bebe-duerme","title":"El bebé duerme","place":"El parque","scene":"banco","next":None,"callado":True,
 "goal":"Look after everybody without waking the baby.","stake":{"thing":"juguetes","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["cansado","contento","triste","duerme"],"back_again":["bebé","perro","está","¿quién?","¿cómo estás?","señor","señora","mira","ahora","no"],
 "also_heard":["contenta","¿cómo está?"],"names":dict(BASE,senora="b_n_senora",hombre="b_n_senor",coche="b_n_bebe",perro="c_n_perro",abuela="abuela"),"clips":c,
 "beats":[act("inicio23"),{"wait":500},tw("coche"),"c23_un_bebe",tw(None),"c23_duerme",say("c23_ca_shh"),
  tw("luis"),"c23_luis_cansado",tw(None),act("cojin"),tw("perro"),"c23_canelo_contento",tw("hombre"),"c23_senor_triste",tw("carmen"),"c23_carmen_contenta",tw(None),
  {"dots":1},ask("hombre","c23_ca_quien_triste",["c23_ahora_senor"],[act("alegra",a="hombre")]),
  {"dots":2},act("abuelallega"),
  ask("di_contento","c23_ab_como",[act("pelota",n=2),act("cae")],[],resp=DF,baraja=True,voces=VF,said={"di_contento":"c23_cq_contento"}),
  ask("di_cansado","c23_ab_y_ahora",[act("chal")],[],resp=DF,baraja=True,voces=VF,said={"di_cansado":"c23_cq_cansado"}),
  act("canelo23",como="triste"),
  ask("di_triste","c23_ab_y_ahora",[act("caricia"),"c23_ahora_contento"],[],resp=DF,baraja=True,voces=VF,said={"di_triste":"c23_cq_triste"}),
  {"dots":3},act("capota",v=1),act("mira23"),
  ask("quieto","c23_sa_shh_duerme",[],[act("quieto")],resp=DQ,baraja=True),
  act("manita",v=1),act("mira23"),
  ask("canta","c23_sa_ahora_contento",[act("duerme"),act("capota",v=0),"c23_ahora_duerme"],[act("canta"),act("rie")],resp=DQ,baraja=True),
  {"dots":4},act("turno23a"),say("yo_coqui",200),act("turno23b"),say("c23_ca_shh_coqui"),CARD,{"wait":400},
  {"dots":5},{"draw":"va","options":["duerme","contento"]},{"calc":"ka","cond":"va=duerme","then":"quieto","else":"canta"},act("capota",v=1),act("mira23"),
  {"decide":"say","options":DQ,"baraja":True,"pick":"$ka","tests":"$va","lead":[],"line":"c23_sa_$va",
   "right":[{"if":"va=duerme","then":[act("quieto")],"else":[act("canta"),act("rie")]},ok(),act("duerme"),act("capota",v=0)],
   "wrong":[{"if":"va=duerme","then":[act("canta"),act("despierta")]+X+[act("capota",v=0),act("mece"),"c23_no_shh",act("capota",v=1)],
             "else":[act("quieto"),act("manita",v=1),{"wait":700},act("manita",v=0),act("despierta")]+X+[act("capota",v=0),"c23_no_no_duerme"]}]},   # nobody plays with him: the hand waves out, finds nobody, and drops
  {"dots":6},{"draw":"cb","options":["contento","cansado","triste"]},act("canelo23",como="$cb"),
  {"decide":"say","options":DF,"baraja":True,"pick":"di_$cb","tests":"$cb","voces":VF,"said":VF,"lead":[],"line":"c23_ab_como",
   "right":[act("abuelahace",que="$cb"),ok()],
   "wrong":[act("abuelamal",dijo="$x",es="$cb"),act("despierta")]+X+[act("mece"),"c23_no_mira_$cb"]},
  {"dots":7},act("tres23"),{"draw":"qc","options":["cansado","triste","contento"]},
  {"calc":"tc","cond":"qc=cansado","then":"perro","else":"luis"},{"calc":"tc","cond":"qc=contento","then":"hombre","else":"$tc"},
  {"calc":"nc","cond":"qc=cansado","then":"canelo_cansado","else":"luis_triste"},{"calc":"nc","cond":"qc=contento","then":"senor_contento","else":"$nc"},
  {"decide":"do","options":["perro","luis","hombre"],"pick":"$tc","tests":"$qc","lock":True,"lead":[],"line":"c23_ca_quien_$qc",
   "right":[act("ayuda",q="$qc"),ok()],
   "wrong":[act("ayudamal",q="$qc",x="$x"),{"if":"qc=triste","then":[{"if":"x=hombre","then":[say("c23_otra")]}]},act("despierta")]+X+[act("mece"),tw("$tc"),"c23_no_$nc",tw(None)]},
  act("resto")],
 "final":[{"dots":8},act("final23"),"c23_fin_canelo",act("ranacansada"),"c23_fin_coqui",say("c23_ab_vamos"),say("p_cq_hm",300),act("sevan23"),{"wait":600}],
 "leer":["c23_un_bebe","c23_duerme","c23_ca_shh","c23_luis_cansado","c23_canelo_contento","c23_senor_triste","c23_carmen_contenta","c23_ca_quien_triste","c23_ahora_senor","c23_ab_como","c23_cq_contento",
  "c23_ab_y_ahora","c23_cq_cansado","c23_cq_triste","c23_ahora_contento","c23_sa_shh_duerme","c23_sa_ahora_contento","c23_ahora_duerme","c23_ca_shh_coqui","c23_fin_canelo","c23_fin_coqui","c23_ab_vamos","p_cq_hm"]}
json.dump(s23,open("cuentos/el-bebe-duerme.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# the story before this scene leads into it
p="cuentos/cual.json"; d=json.load(open(p,encoding="utf-8"))
if d.get("next")!="la-piragua":
    d["next"]="la-piragua"; json.dump(d,open(p,"w",encoding="utf-8"),ensure_ascii=False,indent=1)

# clip ids are global: the same id must have the same text everywhere
seen={}; clash=0; new=0; chars=0
for f in sorted(glob.glob("cuentos/*.json")):
    if "zz-" in f or "zbanco" in f: continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items():
        key=(cl.get("who"),cl.get("text"))
        if cid in seen and seen[cid]!=key: print("CLASH",cid,seen[cid],key,f); clash+=1
        seen.setdefault(cid,key)
for cid,(who,text) in seen.items():
    if not os.path.exists(f"audio/{cid}.mp3"): new+=1; chars+=len(text)
print(len(seen),"clips,",new,"new,",chars,"characters to record,",clash,"clashes")
for st in (s21,s22,s23):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"(c(?:17|21|22|23)_[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
