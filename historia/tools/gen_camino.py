# El camino (place 2, scene 1): stories 12, 13, 14 and the scene's picture pairs. Regenerates the JSON; never edit the JSON by hand.
import json,glob,os,re
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
A=lambda t:D("abuela","Abuela",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
tw=lambda k:{"set":{"twinkle":k}}
def act(_n,**k): return dict({"act":_n},**k)
pose=lambda q,p:act("pose",quien=q,que=p)
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
comunes={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!"),"abuela":N("Esta es abuela."),
 "p_n_luis":N("Este es Luis."),"p_n_carmen":N("Esta es Carmen."),"p_n_porton":N("Es el portón."),
 "c_n_perro":N("Es el perro. Se llama Canelo."),"c_n_gato":N("Es un gato."),"c_n_arbol":N("Es un árbol."),"c_n_grande":N("Es un árbol grande."),"c_n_banco":N("Es un banco."),"c_n_parque":N("Es el parque."),"c_n_pajaro":N("Es un pájaro."),"c_n_camino":N("Es el camino.")}
NOMBRES={"luis":"p_n_luis","carmen":"p_n_carmen","abuela":"abuela","perro":"c_n_perro","gato":"c_n_gato","arbol0":"c_n_arbol","arbol1":"c_n_arbol","arbol2":"c_n_arbol","grande":"c_n_grande","banco":"c_n_banco",
 "porton":"p_n_porton","camino":"c_n_camino","parque":"c_n_parque","coqui":"yo_coqui"}
for i in range(3):
    for k in range(3): NOMBRES[f"ave{i}{k}"]="c_n_pajaro"
MODOS=["camina","corre","espera"]; ES={"camina":"¡Camina!","corre":"¡Corre!","espera":"¡Espera!"}; es=lambda m:ES[m][1:-1].lower()

# ---------------- 12. Uno, dos, tres ----------------
c=dict(comunes)
c.update({"c12_parque":N("Este es el parque."),"c12_luis_carmen":N("Mira. Luis y Carmen están en el parque."),"c12_perro_abuela":N("Y este es el perro de abuela."),"c12_se_llama":N("El perro se llama Canelo."),"c12_cq_hola":T("¡Hola, Canelo!"),
 "c12_puedes":N("¿Puedes tocar al perro?"),"c12_vamos_jugar":L("¡Vamos a jugar! ¡Uno, dos, tres!"),"c12_camina":L("¡Camina!"),"c12_coqui_camina":N("Coquí camina. Carmen camina."),
 "c12_coqui_corre":N("Coquí corre. El perro corre también."),"c12_coqui_espera":N("Coquí espera. Carmen espera."),"c12_ahora_si":L("Ahora sí. ¡Uno, dos, tres! ¡Espera!"),"c12_no_canelo":L("¡No, Canelo! ¡Espera!"),
 "c12_ven":L("¡Ven, Coquí! ¡Ven, Canelo!"),"c12_juega_parque":N("Canelo juega en el parque."),"c12_cq_uno":T("¡Uno, dos, tres!")})
for m in MODOS:
    c["c12_uno_"+m]=L("¡Uno, dos, tres! "+ES[m]); c["c12_lento_"+m]=L("Uno. Dos. Tres. "+ES[m]); c["c12_no_"+m]=N("No. "+ES[m]); c["c12_no_coqui_"+m]=N(f"No. Coquí, ¡{es(m)}!")
    for k in MODOS:
        if k==m: continue
        c[f"c12_cf_{k}_{m}"]=L(f"¡Uno, dos, tres! ¡Carmen, {es(k)}! ¡Coquí, {es(m)}!"); c[f"c12_fc_{k}_{m}"]=L(f"¡Uno, dos, tres! ¡Coquí, {es(m)}! ¡Carmen, {es(k)}!")
quieto=lambda v,n:{"calc":n,"cond":f"{v}=espera","then":"1","else":"0"}
s12={"id":"uno-dos-tres","title":"Uno, dos, tres","place":"El parque","scene":"camino","next":"donde-esta-el-gato",
 "goal":"Do what Luis calls and get along the path to the big tree.","stake":{"thing":"puesto","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["parque","perro","camina","corre","espera","uno","dos","tres"],"back_again":["hola","mira","vamos","ahora","sí","no","juega","también"],
 "also_heard":["árbol","se llama","este","a jugar"],"names":NOMBRES,"palabras":{},"clips":c,
 "beats":[act("inicio12"),{"wait":500},"c12_parque","c12_luis_carmen",tw("perro"),"c12_perro_abuela","c12_se_llama",tw(None),act("ladra"),{"say":"c12_cq_hola","gap":300},
  {"dots":1},ask("perro","c12_puedes",[act("lame")]),
  act("cuenta"),{"say":"c12_vamos_jugar","gap":300},
  {"dots":2},ask("camina","c12_camina",["c12_coqui_camina"],[act("ronda",modo="camina")],resp=["camina","corre"],baraja=True),
  ask("corre","c12_uno_corre",["c12_coqui_corre"],[act("ronda",modo="corre")],resp=["corre","espera"],baraja=True),
  ask("espera","c12_uno_espera",["c12_coqui_espera"],[act("ronda",modo="espera")],resp=["espera","camina"],baraja=True,quieto=True),
  {"dots":3},ask("espera","c12_cf_corre_espera",[],[act("ronda2",f="espera",c="corre")],resp=MODOS,baraja=True,quieto=True),
  ask("camina","c12_fc_espera_camina",[],[act("ronda2",f="camina",c="espera")],resp=MODOS,baraja=True),
  {"dots":4},{"say":"c12_ahora_si","gap":100},act("demo"),{"say":"c12_no_canelo","gap":200},act("demo2"),
  {"dots":5},{"reparte":["la","oa","xa"],"options":MODOS},quieto("la","qa"),
  {"decide":"say","options":["$la","$oa"],"baraja":True,"pick":"$la","tests":"$la","lock":True,"quieto":"$qa","lead":[],"line":"c12_uno_$la","right":[act("ronda",modo="$la")],"wrong":[act("ronda",modo="$la",mal="$x"),"c12_no_$la",{"cost":1}]},
  {"dots":6},{"reparte":["lb","cb","xb"],"options":MODOS},{"draw":"ob","options":["cf","fc"]},quieto("lb","qb"),
  {"decide":"say","options":MODOS,"baraja":True,"pick":"$lb","tests":"$lb","lock":True,"quieto":"$qb","lead":[],"line":"c12_$ob_$cb_$lb","right":[act("ronda2",f="$lb",c="$cb")],"wrong":[act("ronda2",f="$lb",c="$cb",mal="$x"),"c12_no_coqui_$lb",{"cost":1}]},
  {"dots":7},{"draw":"lc","options":["$oa","$xa"]},quieto("lc","qc"),
  {"decide":"say","options":MODOS,"baraja":True,"pick":"$lc","tests":"$lc","lock":True,"quieto":"$qc","lead":[],"line":"c12_lento_$lc","right":[act("ronda",modo="$lc")],"wrong":[act("ronda",modo="$lc",mal="$x"),"c12_no_$lc",{"cost":1}]}],
 "final":[{"say":"c12_ven","gap":200},act("final12"),"c12_juega_parque",{"say":"c12_cq_uno","gap":300},act("ladra3"),{"wait":600}],
 "leer":["c12_parque","c12_luis_carmen","c12_perro_abuela","c12_se_llama","c12_cq_hola","c12_puedes","c12_vamos_jugar","c12_camina","c12_coqui_camina","c12_uno_corre","c12_coqui_corre","c12_uno_espera","c12_coqui_espera",
  "c12_cf_corre_espera","c12_fc_espera_camina","c12_ahora_si","c12_no_canelo","c12_ven","c12_juega_parque","c12_cq_uno"]}
json.dump(s12,open("cuentos/uno-dos-tres.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 13. ¿Dónde está el gato? ----------------
NUM={"1":"un pájaro","2":"dos pájaros","3":"tres pájaros"}; PERM=["123","132","213","231","312","321"]; NO123=[p for p in PERM if p!="123"]
c=dict(comunes)
c.update({"c13_un_gato":N("Mira. Un gato."),"c13_gato_parque":N("El gato está en el parque."),"c13_ven_gatito":CA("¡Ven, gatito! ¡Ven!"),"c13_puedes":N("¿Puedes tocar al gato?"),
 "c13_gato_corre":N("¡El gato corre! El gato está en el árbol."),"c13_mira_arboles":N("Mira los árboles."),"c13_un_arbol":N("Un árbol."),"c13_dos_arboles":N("Dos árboles."),"c13_tres_arboles":N("Tres árboles."),
 "c13_hay_1":N("En este árbol hay un pájaro. Uno."),"c13_hay_2":N("Aquí hay dos pájaros."),"c13_hay_3":N("Y aquí hay tres pájaros."),"c13_luis_donde":L("¿Dónde está el gato?"),"c13_car_donde":CA("¿Dónde está el gato?"),
 "c13_car_coqui_donde":CA("Coquí, ¿dónde está el gato?"),"c12_no_canelo":L("¡No, Canelo! ¡Espera!"),"c13_cuenta_1":N("Un pájaro."),"c13_cuenta_2":N("Dos pájaros."),"c13_cuenta_3":N("Tres pájaros."),
 "c13_aqui":N("El gato y el perro están aquí."),"c13_amigos":CA("Ahora son amigos."),"c13_cq_amigos":T("¡Amigos!")})
for n,t in NUM.items():
    c["c13_car_esta_"+n]=CA(f"Está en el árbol con {t}."); c["c13_luis_esta_"+n]=L(f"Está en el árbol con {t}."); c["c13_no_esta_"+n]=L(f"El gato no está en el árbol con {t}.")
    c["c13_y_no_esta_"+n]=L(f"Y no está en el árbol con {t}."); c["c13_cq_esta_"+n]=T(f"Está en el árbol con {t}."); c["c13_no_"+n]=N("No. "+t[0].upper()+t[1:]+".")
VC={"con_"+n:"c13_cq_esta_"+n for n in NUM}; TRES=["arbol0","arbol1","arbol2"]
def mueve_gato(perm,g,que,perms=PERM): return [{"draw":perm,"options":perms},act("esconde"),act("posan",p="$"+perm),{"draw":g,"options":["0","1","2"]},act("gatoarbol",en="$"+g,que=que)]
premio=[{"if":"ok","then":[act("saca"),act("gatocome")],"else":[act("acaricia")]}]
s13={"id":"donde-esta-el-gato","title":"¿Dónde está el gato?","place":"El parque","scene":"camino","next":"rapido-despacio",
 "goal":"Find the cat in the trees and get it into its basket.","stake":{"thing":"galletas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["gato","árbol","hay","uno","dos","tres","¿dónde está?"],"back_again":["perro","corre","espera","pájaro","no","mira","aquí","está","con"],
 "also_heard":["en","gatito"],"names":NOMBRES,"palabras":{"n1":"uno","n2":"dos","n3":"tres"},"clips":c,
 "beats":[act("inicio13"),{"draw":"pz","options":NO123},act("posan",p="$pz"),{"wait":500},tw("gato"),"c13_un_gato","c13_gato_parque",tw(None),{"say":"c13_ven_gatito","gap":300},
  {"dots":1},ask("gato","c13_puedes",[act("ronronea")]),
  act("ladra"),{"draw":"gz","options":["0","1","2"]},act("gatoarbol",en="$gz",que="cola"),"c13_gato_corre",
  "c13_mira_arboles",act("lit",n="1"),"c13_un_arbol",act("lit",n="2"),"c13_dos_arboles",act("lit",n="3"),"c13_tres_arboles",act("lit",n="0"),
  act("luzn",n="1"),"c13_hay_1",act("luzn",n="2"),"c13_hay_2",act("luzn",n="3"),"c13_hay_3",act("luzn",n="0"),
  {"dots":2},{"say":"c13_luis_donde","gap":250},ask("arbol$gz","c13_car_esta_$n",[],[act("ir",a="arbol$gz"),act("asoma")]),
  {"dots":3}]+mueve_gato("py","gy","cola")+[{"ask":"arbol$gy","lead":["c13_no_esta_$oa"],"line":"c13_y_no_esta_$ob","after":[act("ir",a="arbol$gy"),act("asoma")],"then":[]},
  {"dots":4}]+mueve_gato("px","gx","cola")+[act("ir",a="centro"),ask("con_$n","c13_car_coqui_donde",[act("carmenvuelve")],[act("carmenva",en="$gx"),act("asoma")],resp=["con_$n","con_$m"],baraja=True,voces=VC,said={"con_$n":"c13_cq_esta_$n"}),
  {"dots":5},act("escapa"),{"say":"c12_no_canelo","gap":200},act("agarra"),{"draw":"pw","options":NO123},act("posan",p="$pw"),
  act("luzn",n="1"),"c13_cuenta_1",act("luzn",n="2"),"c13_cuenta_2",act("luzn",n="3"),"c13_cuenta_3",act("luzn",n="0"),{"set":{"tarjeta":"galletas","marcas":[None,None,None]}},{"wait":500},
  {"dots":6}]+mueve_gato("pa","ga","nada")+[{"say":"c13_car_donde","gap":250},
  {"decide":"do","options":TRES,"pick":"arbol$ga","tests":"n$n","lock":True,"lead":[],"line":"c13_luis_esta_$n","right":[act("ir",a="arbol$ga")]+premio,"wrong":[act("ir",a="$x"),act("saca"),{"wait":500},act("perrocome"),"c13_no_$n",{"cost":1}]},
  {"dots":7}]+mueve_gato("pb","gb","nada")+[
  {"decide":"do","options":TRES,"pick":"arbol$gb","tests":"no","lock":True,"lead":["c13_no_esta_$oa"],"line":"c13_y_no_esta_$ob","right":[act("ir",a="arbol$gb")]+premio,"wrong":[act("ir",a="$x"),act("saca"),{"wait":500},act("perrocome"),"c13_no_$n",{"cost":1}]},
  {"dots":8},act("ir",a="centro")]+mueve_gato("pc","gc","cola")+[
  {"decide":"say","options":["con_$n","con_$m"],"baraja":True,"pick":"con_$n","tests":"n$n","voces":VC,"said":VC,"lead":[],"line":"c13_car_coqui_donde",
   "right":[act("carmenva",en="$gc"),act("gatocesta"),{"if":"ok","then":[act("galletacesta")]}],"wrong":[act("carmenva",en="$tm"),act("mirarriba"),act("perrocome2"),"c13_no_$n",{"cost":1}]}],
 "final":[act("final13"),"c13_aqui","c13_amigos",{"say":"c13_cq_amigos","gap":400},{"wait":600}],
 "leer":["c13_un_gato","c13_gato_parque","c13_ven_gatito","c13_puedes","c13_gato_corre","c13_mira_arboles","c13_un_arbol","c13_dos_arboles","c13_tres_arboles","c13_hay_1","c13_hay_2","c13_hay_3","c13_luis_donde","c13_car_esta_2",
  "c13_no_esta_1","c13_y_no_esta_3","c13_car_coqui_donde","c13_cq_esta_3","c12_no_canelo","c13_aqui","c13_amigos","c13_cq_amigos"]}
json.dump(s13,open("cuentos/donde-esta-el-gato.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- 14. Rápido, despacio ----------------
c=dict(comunes)
c.update({"c14_estan":N("Coquí y Canelo están en el parque."),"c14_guineos":N("Mira. Tres guineos para abuela."),"c14_vamos_ven":L("¡Vamos, Coquí! ¡Ven con el perro!"),"c14_donde_perro":N("¿Dónde está el perro?"),
 "c14_camina":N("El perro camina. Coquí camina."),"c14_corre_corre":N("¡El perro corre! ¡Corre!"),"c14_cq_despacio":T("¡Despacio, Canelo!"),"c14_cq_rapido":T("¡Rápido, Canelo!"),
 "c14_ahora_despacio":N("Ahora el perro camina despacio."),"c14_no_camina":N("El perro no camina."),"c14_ahora_rapido":N("Ahora el perro camina rápido."),
 "c14_luis_despacio":L("¡Coquí! ¡Camina despacio!"),"c14_luis_rapido":L("¡Coquí! ¡Camina rápido!"),"c14_luis_rapido_2":L("¡Camina rápido!"),"c14_no_despacio":N("No. ¡Despacio!"),"c14_no_rapido":N("No. ¡Rápido!"),
 "c14_corre":N("¡El perro corre!"),"c14_ab_gracias":A("¡Hola, Canelo! Gracias, Coquí."),"c14_cq_de_nada":T("De nada, abuela."),"c14_vamos_casa":L("¡Vamos a casa!")})
DI=["di_despacio","di_rapido"]; VD={"di_despacio":"c14_cq_despacio","di_rapido":"c14_cq_rapido"}; PASO=["despacio","rapido"]
def perro_hace(v):   # what the dog does is drawn fresh; r = the bubble that puts it right; t = the word that is filed
    return [{"draw":v,"options":["corre","para"]},{"calc":"r"+v,"cond":v+"=corre","then":"di_despacio","else":"di_rapido"},{"calc":"t"+v,"cond":v+"=corre","then":"despacio","else":"rapido"}]
decA=perro_hace("sa")+[act("situacion",que="$sa"),
 {"decide":"say","options":DI,"baraja":True,"pick":"$rsa","tests":"$tsa","voces":VD,"said":VD,"lead":[],"right":[act("trota")],"wrong":[act("masde",que="$sa"),act("cae"),"c14_no_$tsa",{"cost":1}]}]
decB=[{"draw":"wb","options":PASO},pose("luis","wave"),
 {"decide":"say","options":PASO,"baraja":True,"pick":"$wb","tests":"$wb","lock":True,"lead":[],"line":"c14_luis_$wb","right":[pose("luis","idle"),act("paseo",modo="$wb",d=".07")],
  "wrong":[act("desigual",p="$wb",f="$x"),act("cae"),act("vuelveperro"),"c14_no_$wb",{"cost":1}]}]
s14={"id":"rapido-despacio","title":"Rápido, despacio","place":"El parque","scene":"camino",
 "goal":"Walk the dog back to the gate with the three guineos for abuela.","stake":{"thing":"guineos","steps":3},"dots":7,"bien":"si_muy_bien",
 "focus_words":["rápido","despacio"],"back_again":["perro","camina","corre","parque","ven","vamos","no","abuela","gracias","tres","¿dónde está?"],
 "also_heard":["muy","guineos","para abuela"],"names":NOMBRES,"palabras":{"rapido":"rápido"},"clips":c,
 "beats":[act("inicio14"),{"wait":500},"c14_estan","c14_guineos",pose("luis","wave"),{"say":"c14_vamos_ven","gap":300},pose("luis","idle"),
  {"dots":1},ask("perro","c14_donde_perro",[act("ladra",n="1")]),
  act("paseo",modo="trota",d=".06"),"c14_camina",
  {"dots":2},act("situacion",que="corre"),{"say":"c14_corre_corre","gap":250},ask("di_despacio",None,["c14_ahora_despacio"],[act("paseo",modo="despacio",d=".03")],resp=DI,baraja=True,voces=VD,said={"di_despacio":"c14_cq_despacio"}),
  {"dots":3},act("para"),{"say":"c14_no_camina","gap":250},ask("di_rapido",None,["c14_ahora_rapido"],[act("paseo",modo="rapido",d=".05")],resp=DI,baraja=True,voces=VD,said={"di_rapido":"c14_cq_rapido"}),
  {"dots":4},pose("luis","wave"),ask("despacio","c14_luis_despacio",[],[act("paseo",modo="despacio",d=".03")],resp=PASO,baraja=True),
  ask("rapido","c14_luis_rapido_2",[pose("luis","idle")],[act("paseo",modo="rapido",d=".05")],resp=PASO,baraja=True),
  act("tropieza"),
  {"dots":5},{"draw":"orden","options":["ab","ba"]},{"if":"orden=ab","then":decA+[{"dots":6}]+decB,"else":decB+[{"dots":6}]+decA},
  {"dots":7},act("arbusto")]+perro_hace("sc")+[{"calc":"lc","cond":"sc=corre","then":"c14_corre","else":"c14_no_camina"},
  {"decide":"say","options":DI,"baraja":True,"pick":"$rsc","tests":"$tsc","voces":VD,"said":VD,"lead":[],"line":"$lc",
   "right":[act("sale",modo="trota")],"wrong":[{"if":"sc=corre","then":[act("sale",modo="corre")],"else":[act("tira")]},act("cae"),"c14_no_$tsc",{"cost":1}]}],
 "final":[act("final14"),{"say":"c14_ab_gracias","gap":300},{"say":"c14_cq_de_nada","gap":300},{"say":"c14_vamos_casa","gap":300},act("sevan"),{"wait":400}],
 "leer":["c14_estan","c14_guineos","c14_vamos_ven","c14_donde_perro","c14_camina","c14_corre_corre","c14_cq_despacio","c14_ahora_despacio","c14_no_camina","c14_cq_rapido","c14_ahora_rapido","c14_luis_despacio","c14_luis_rapido_2",
  "c14_ab_gracias","c14_cq_de_nada","c14_vamos_casa"]}
json.dump(s14,open("cuentos/rapido-despacio.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# ---------------- ¿Cuál? for El camino ----------------
P=lambda x,y,**k:dict({"x":x,"y":y,"pose":"idle"},**k)
cq=lambda x,y,s=1,**k:dict({"x":x-16,"y":y-27,"s":s,"dy":0,"al":1,"vis":1,"bub":None},**k)
NO=cq(0,0,vis=0)
perro=lambda x,y,pose="sit",**k:dict({"x":x,"y":y,"pose":pose,"dir":1},**k)
gato=lambda x,y,pose="sit",**k:dict({"x":x,"y":y,"pose":pose,"dir":1,"en":None},**k)
todos={**s12["clips"],**s13["clips"],**s14["clips"],"c_c_perro":N("Es un perro."),"c_c_luis_camina":N("Luis camina."),"c_c_perro_corre":N("El perro corre."),"c_c_carmen_espera":N("Carmen espera."),
 "c_c_rapido":N("El perro camina rápido."),"c_c_despacio":N("El gato camina despacio."),"c_c_hay_gato":N("Hay un gato en el árbol."),"c_c_uno":N("Hay un pájaro. Uno."),"c_c_dos":N("Hay dos pájaros."),"c_c_tres":N("Hay tres pájaros.")}
usa=["c_c_perro","c_n_gato","c_n_arbol","c_n_parque","c_c_luis_camina","c_c_perro_corre","c_c_carmen_espera","c_c_rapido","c_c_despacio","c_c_hay_gato","c_c_uno","c_c_dos","c_c_tres","muy_bien","si_muy_bien"]
C1=[70,128,113,60]; CT=[58,58,113,60]; CG=[62,96,100,53.1]; CA1=[62,60,100,53.1]; CP=[40,120,150,79.6]
cual={"id":"cual-camino","title":"¿Cuál?","place":"El parque","scene":"camino","tipo":"cual","stake":{"thing":"none","steps":0},
 "note":"The next-day pass for El camino. The parque pair's other picture is abuela's yard, drawn by the patio scene (the item says so).","clips":{k:todos[k] for k in usa},
 "items":[
  {"w":"perro","say":"c_c_perro","si":{"cam":C1,"set":{"perro":perro(126,180),"cq":NO}},"no":{"cam":C1,"set":{"gato":gato(126,180),"cq":NO}}},
  {"w":"gato","say":"c_n_gato","si":{"cam":CG,"set":{"gato":gato(113,134),"cq":NO}},"no":{"cam":CG,"set":{"pajaros":[0,0,0],"avebanco":1,"cq":NO}}},
  {"w":"árbol","say":"c_n_arbol","si":{"cam":[112,62,100,53.1],"set":{"cq":NO}},"no":{"cam":[78,118,75,39.8],"set":{"cq":NO}}},
  {"w":"parque","say":"c_n_parque","si":{"cam":[22,84,196,104],"set":{"cq":NO}},"no":{"cam":[22,30,196,104],"esc":"patio","set":{"cq":NO}}},
  {"w":"camina","say":"c_c_luis_camina","si":{"cam":CP,"set":{"gente":{"luis":P(116,172,paso=1)},"cq":NO}},"no":{"cam":CP,"set":{"gente":{"luis":P(116,172,paso=1,corre=1)},"polvo":{"x":98,"y":170,"dir":-1,"lin":1},"cq":NO}}},
  {"w":"corre","say":"c_c_perro_corre","si":{"cam":C1,"set":{"perro":perro(126,180,"run"),"polvo":{"x":108,"y":180,"dir":-1,"lin":1},"cq":NO}},"no":{"cam":C1,"set":{"perro":perro(126,180,"lie"),"cq":NO}}},
  {"w":"espera","say":"c_c_carmen_espera","si":{"cam":CP,"set":{"gente":{"carmen":P(118,176)},"cq":NO}},
   "no":{"cam":CP,"set":{"gente":{"carmen":P(118,176,paso=1,corre=1)},"polvo":{"x":100,"y":174,"dir":-1,"lin":1},"cq":NO}}},
  {"w":"rápido","say":"c_c_rapido","si":{"cam":C1,"set":{"perro":perro(126,180,"walk"),"polvo":{"x":106,"y":180,"dir":-1,"lin":1},"cq":NO}},"no":{"cam":C1,"set":{"perro":perro(126,180,"husmea"),"caracol":{"x":102,"y":185},"cq":NO}}},
  {"w":"despacio","say":"c_c_despacio","si":{"cam":C1,"set":{"gato":gato(126,180,"walk"),"caracol":{"x":102,"y":185},"cq":NO}},"no":{"cam":C1,"set":{"gato":gato(126,180,"run"),"polvo":{"x":106,"y":180,"dir":-1,"lin":1},"cq":NO}}},
  {"w":"hay","say":"c_c_hay_gato","si":{"cam":CT,"set":{"gato":{"x":0,"y":0,"pose":"cara","dir":1,"en":1},"cq":NO}},"no":{"cam":CT,"set":{"cq":NO}}},
  {"w":"uno","say":"c_c_uno","si":{"cam":CA1,"set":{"pajaros":[0,1,0],"cq":NO}},"no":{"cam":CA1,"set":{"pajaros":[0,3,0],"cq":NO}}},
  {"w":"dos","say":"c_c_dos","si":{"cam":CA1,"set":{"pajaros":[0,2,0],"cq":NO}},"no":{"cam":CA1,"set":{"pajaros":[0,1,0],"cq":NO}}},
  {"w":"tres","say":"c_c_tres","si":{"cam":CA1,"set":{"pajaros":[0,3,0],"cq":NO}},"no":{"cam":CA1,"set":{"pajaros":[0,2,0],"cq":NO}}}]}
json.dump(cual,open("cuentos/cual-camino.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# hasta-manana leads on to the park
p="cuentos/hasta-manana.json"; d=json.load(open(p,encoding="utf-8"))
if d.get("next")!="uno-dos-tres":
    nd={}
    for k,v in d.items():
        nd[k]=v
        if k=="scene": nd["next"]="uno-dos-tres"
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
for st in (s12,s13,s14):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"(c1[234]_[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
