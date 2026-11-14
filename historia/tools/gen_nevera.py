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

# ---------------- 32. Jugo de china ----------------
c=dict(comunes)
COL={"verde":"verde","amarillo":"amarillo","rojo":"rojo","azul":"azul"}; EST={"lleno":"lleno","vacio":"vacío"}
c.update({"c32_calor":N("Hace calor."),"c32_hace_jugo":N("Abuela hace jugo de china."),"c32_aqui_chinas":N("Aquí hay chinas."),"c32_aqui_mant":N("Y aquí hay mantequilla."),
 "c32_le_pone":N("Abuela le pone mantequilla al pan."),"c32_luis_come":N("Luis come pan con mantequilla."),
 "c32_ab_un_vaso":AB("Coquí, un vaso está vacío. Ponle jugo de china."),"c32_ahora_amarillo":N("Ahora el vaso amarillo está lleno."),
 "c32_luis_mi_vacio":L("Mi vaso está vacío."),"c32_luis_mi_lleno":L("Mi vaso está lleno."),"c32_carmen_mi_vacio":CA("Mi vaso está vacío."),"c32_carmen_mi_lleno":CA("Mi vaso está lleno."),
 "c32_luis_toma":N("Luis toma jugo de china."),"c32_carmen_quiero":CA("Quiero pan con mantequilla y jugo de china."),"c32_carmen_come":N("Carmen come pan con mantequilla."),
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
  # the opening: a round picture over a cup shows what is in it
  {"dots":1}]+vista("v_verde","c32_n_verde_lleno")+vista("v_amarillo","c32_n_amarillo_vacio")+[
  ask("v_amarillo","c32_ab_un_vaso",vista("v_amarillo","c32_ahora_amarillo"),[act("vierte",a="v_amarillo")]),
  {"dots":2},act("ninos32",que="toman",bebe="luis"),act("ninos32",que="dejan")]+vista("v_verde",say("c32_luis_mi_vacio"))+[act("vista",a="v_amarillo"),
  ask("v_verde","c32_carmen_mi_lleno",["c32_luis_toma"],[act("vista",a=""),act("vierte",a="v_verde")],alias=AL),
  {"dots":3},act("mama32",que="trae",vacio="azul"),act("vista",a="v_rojo"),
  ask("v_azul","c32_mama_rojo_lleno",[act("mama32",que="lleva")],[act("vista",a=""),act("vierte",a="v_azul")]),
  act("ninos32",que="toman",bebe="luis"),act("ninos32",que="dejan"),act("abuelapila"),act("vista",a="v_verde"),
  ask("v_verde","c32_ab_verde_vacio",[act("abuelavuelve"),say("c32_carmen_quiero")],[act("vista",a=""),act("lleva32",a="v_verde")]),
  # the turn: the last chinas
  {"dots":4},act("ultima32"),act("ninos32",que="salen",con=1),"c32_carmen_come",say("c32_luis_mas"),act("exprime",todo=1,suelto=1),"c32_mas_jugo",act("ya"),"c32_familia",CARD,{"wait":400},
  # A: two lines, the children's own
  {"dots":5},{"draw":"va","options":["verde","amarillo"],"other":"vb"},{"draw":"oa","options":["l","c"]},
  {"calc":"ll","cond":"va=verde","then":"c32_luis_mi_vacio","else":"c32_luis_mi_lleno"},{"calc":"lc","cond":"va=amarillo","then":"c32_carmen_mi_vacio","else":"c32_carmen_mi_lleno"},
  {"calc":"la","cond":"oa=l","then":"$ll","else":"$lc"},{"calc":"lb","cond":"oa=l","then":"$lc","else":"$ll"},
  act("ninos32",que="entran",vacio="$va"),act("ninos32",que="dejan"),
  {"decide":"do","options":V2,"pick":"v_$va","tests":"vacio","lock":True,"alias":AL,"lead":[say("$la")],"line":"$lb",
   "right":[act("vierte",a="v_$va"),ok()],
   "wrong":[act("vierte",a="$x")]+X+vista("v_$va","c32_no_$va_vacio")},
  act("ninos32",que="salen",con=1),
  # B: one line, mamá's, of the red cup or the blue one
  {"dots":6},{"draw":"ra","options":["rojo","azul"],"other":"rb"},{"draw":"fa","options":["lleno","vacio"]},{"calc":"rn","cond":"fa=vacio","then":"$ra","else":"$rb"},
  act("mama32",que="trae",vacio="$ra"),
  {"decide":"do","options":["v_rojo","v_azul"],"pick":"v_$ra","tests":"$fa","lock":True,"lead":[],"line":"c32_mama_$rn_$fa",
   "right":[act("vierte",a="v_$ra"),ok(),act("mama32",que="lleva")],
   "wrong":[act("vierte",a="$x")]+X+vista("v_$ra","c32_no_$ra_vacio")},
  # C: one line, abuela's; he carries a cup to the sink
  {"dots":7},{"draw":"ga","options":["verde","amarillo"],"other":"gb"},{"draw":"fc","options":["lleno","vacio"]},{"calc":"gn","cond":"fc=vacio","then":"$ga","else":"$gb"},
  act("ninos32",que="quedan",vacio="$ga"),act("abuelapila"),
  {"decide":"do","options":V2,"pick":"v_$ga","tests":"$fc","lock":True,"lead":[],"line":"c32_ab_$gn_$fc",
   "right":[act("lleva32",a="v_$ga"),ok()],
   "wrong":[act("lleva32",a="$x")]+X+vista("v_$ga","c32_no_$ga_vacio")+[act("mirapila")]}],
 "final":[{"dots":8},act("abuelavuelve"),act("final32"),"c32_ab_come",{"if":"rana","then":[say("cq_gracias_abuela",300)],"else":["c32_no_hay_mas"]},act("fin")],
 "leer":["c32_calor","c32_hace_jugo","c32_aqui_chinas","c32_aqui_mant","c32_le_pone","c32_luis_come","c32_n_verde_lleno","c32_n_amarillo_vacio","c32_ab_un_vaso","c32_ahora_amarillo","c32_luis_mi_vacio","c32_carmen_mi_lleno","c32_luis_toma",
  "c32_mama_rojo_lleno","c32_ab_verde_vacio","c32_carmen_quiero","c32_carmen_come","c32_luis_mas","c32_mas_jugo","c32_familia","c32_ab_come","cq_gracias_abuela"]}
json.dump(s32,open("cuentos/jugo-de-china.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

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
for st in (s32,):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"(c(?:30|31|32)_[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
