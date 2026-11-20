# Escuchar, place 3 (La cocina): picture stories (tipo "escucha") and do-this routines (tipo "haz"). Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/escuchar-cocina.md (draft 2, after the two reviews). Every quoted line of the script is exactly one clip, word for word.
# Built here: stories 1 to 4 (d-cuchara-abuelo, d-comida-coqui, d-chocolate-luis, d-comida-parque) and routines A to C (h-mesa, h-estufa, h-nevera).
# Not built yet (scene A comer): story 5 and routine D.
# Content only: every beat is staged with acts the scenes already have (mesa.js, estufa.js, nevera.js) and `set` steps on world values their draw already reads.
# Beats staged with the nearest thing the scene can do, or not staged (script step: what it asked -> what is staged):
#  Story 1: setup: Carmen is hidden (the script seats three). 3: Luis walks out of the picture with the tray and comes back round the table (turno25b always enters him from the door).
#           4: "shakes his head" = he turns left and right. 5: papá "pokes his bread with the fork; it skids on the plate" = the scene's wrong-utensil mess (a yellow smear on the cloth); mamá's spaghetti "slides off" = a red smear.
#  Story 2: 4: "the frog turns to her": not staged (the frog has no facing). 6: "Canelo looks at the plate" = he sits in his corner facing it. 8: "Canelo drinks it" = he drags the glass to his corner, where it lies spilled.
#           9: "the frog laughs": NOT STAGED. "Canelo lies down beside him" = a cut (set) of the dog to the frog's side: no act walks him there.
#  Story 3: the thoughts show a cup (cold, or steaming), not the jug and the pot. 3: "lays the empty cup on its side" = the empty cup goes into the waste bucket, tilted (Luis's two cups end there, not beside him).
#           5: "Abuela turns round" = asoma; "Luis smiles": NOT STAGED. 4 and 6: a cup held by mamá is drawn as the baby in this scene, so Luis and the frog walk to a hidden stand-in (mama2) and mamá holds the cup (lleva) from then on:
#           in 6 her cup shows up when the frog is back at his stool. 7: "they drink" = papá's cup at his mouth, mamá holds hers.
#  Story 4: 1: the picnic basket is not a thing that can twinkle: the box of the bread board, which stands in the same place, twinkles. 5: abuelo is at the window from the start (he does not come). While abuela takes the guineo
#           (the act clears the sill) a copy of the manzana stands in the same place, and is swapped back for the bite. 6: "a roll on the tray" = lote sets a roll and a plate of fruit; the plate is taken off at once.
#           "A bird lands" = a bird appears on the wall. 9: Luis takes the basket, and Luis and Carmen go out; "the frog last": NOT STAGED (the frog stays on his stool).
#  Routine A: "bare table" = no plates, no cups; the cloth stays as in story 24. B: the scene's cooks are the other way round (abuela at the right pot, Luis at the left): the acts pour by cook, so the scene's sides are kept.
#  Routine C: the cups are spaced so that a round picture sits over the red cup and another over the blue one (the scene draws one round picture at a time: these are two list items of the sill, W.repisa); bread and clear glasses taken off.
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
L=lambda t:D("luis","Luis",t); AB=lambda t:D("abuela","Abuela",t); AO=lambda t:D("abuelo","Abuelo",t); MA=lambda t:D("mama","Mamá",t); PA=lambda t:D("papa","Papá",t)
tw=lambda k:{"set":{"twinkle":k}}
def act(_n,**k): return dict({"act":_n},**k)
g=lambda quien,**k: act("g",quien=quien,**k)
base={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}
CORAZON=[{"set":{"heart":1}},{"wait":1200}]
MIOS=("d-cuchara-abuelo","d-comida-coqui","d-chocolate-luis","d-comida-parque","h-mesa","h-estufa","h-nevera")

# a line whose text and speaker are already recorded under another id keeps that id (nothing is recorded twice). The hz_no_ clips are looked up by name by the game: they never change id.
EX=collections.defaultdict(collections.Counter)
for f in glob.glob("cuentos/*.json"):
    if any(os.path.basename(f)==m+".json" for m in MIOS) or os.path.basename(f).startswith("z"): continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items(): EX[(cl.get("who"),cl.get("habla"),cl["text"])][cid]+=1
REUSADOS=[]
def reuse(st):
    ren={}
    for cid,cl in list(st["clips"].items()):
        if cid.startswith("hz_no_") or "$" in cid: continue
        k=(cl.get("who"),cl.get("habla"),cl["text"])
        if k in EX:
            best=EX[k].most_common(1)[0][0]
            if best!=cid: ren[cid]=best
    def fx(o):
        if isinstance(o,str): return ren.get(o,o)
        if isinstance(o,list): return [fx(x) for x in o]
        if isinstance(o,dict): return {fx(k) if k in ren else k:fx(v) for k,v in o.items()}
        return o
    out=fx(st)
    for old,new in ren.items(): REUSADOS.append((st["id"],old,new,st["clips"][new]["text"] if new in st["clips"] else out["clips"][new]["text"]))
    for cid,cl in out["clips"].items(): EX[(cl.get("who"),cl.get("habla"),cl["text"])][cid]+=1   # the next story of this set reuses this one's ids too
    return out

class Cuento:
    """A piece being written: lines get their clip ids as they are added."""
    def __init__(s,cid,pre): s.id=cid; s.pre=pre; s.clips=dict(base); s.beats=[]; s.n=0; s.leer=[]
    def say(s,clip,gap=None,lee=True):
        s.n+=1; k=f"{s.pre}{s.n:02d}"; s.clips[k]=clip
        if lee: s.leer.append(k)
        s.beats.append(k if gap is None else {"say":k,"gap":gap}); return k
    def clip(s,clip):
        s.n+=1; k=f"{s.pre}{s.n:02d}"; s.clips[k]=clip; return k
    def do(s,*steps): s.beats.extend(steps)
def guarda(c,title,scene,tipo,dots,extra=None,names=None):
    d={"id":c.id,"title":title,"place":"La cocina","scene":scene,"tipo":tipo,"goal":"Escuchar. Nothing is scored.","stake":{"thing":"none","steps":9},"dots":dots,"bien":"muy_bien",
       "focus_words":[],"back_again":[],"also_heard":[],"names":names or {"coqui":"yo_coqui"},"clips":c.clips,"beats":c.beats,"final":[{"wait":900}],"leer":c.leer}
    if extra: d.update(extra)
    d=reuse(d)
    json.dump(d,open(f"cuentos/{c.id}.json","w",encoding="utf-8"),ensure_ascii=False,indent=1); return d

# ---- Haz esto: the same helpers as El parque's ----
def orden(c,linea,pick,ops,right,vale=None,mudo=None,clip=None,alias=None,resp=False):
    if mudo: k=mudo
    else:
        k=c.say(clip or N(linea)); c.beats.pop()   # the line belongs to the decision, it is not a beat of its own
    d={"decide":"say" if resp else "do","libre":True,"bien":False,"options":ops,"pick":pick,"lead":[],"line":k,"right":right}
    if not resp: d["lock"]=True
    else: d["baraja"]=True
    if vale: d["vale"]=vale
    if alias: d["alias"]=alias
    if mudo: d["mudo"]=True
    c.do(d); return k
def nos(c,m):
    for k,t in m.items(): c.clips["hz_no_"+k]=N("No, "+t)
fin=[{"wait":300},{"say":"muy_bien","gap":300},{"set":{"heart":1}},{"wait":600}]
def par(c,linea,a,b,ra,rb,tercero,despues,alias=None):
    """A line in two parts ("Toca a mamá y a papá"). Either order counts. Then the other one; a touch on the part already done is only a poke."""
    k=c.say(N(linea)); c.beats.pop()
    d1={"decide":"do","libre":True,"bien":False,"lock":True,"options":[a],"vale":[b],"pick":a,"lead":[],"line":k,"right":[{"if":"x="+a,"then":ra,"else":rb}]}
    d2={"decide":"do","libre":True,"bien":False,"mudo":True,"options":["$otro",tercero],"pick":"$otro","lead":[],"line":k,"right":[{"if":"otro="+a,"then":ra,"else":rb}]+despues}
    if alias: d1["alias"]=alias; d2["alias"]=alias
    c.do(d1,{"calc":"otro","cond":"x="+a,"then":b,"else":a},d2)

# what a free touch names: the lines already recorded for the people and the places (as in La mesa)
BASE={"luis":"p_n_luis","carmen":"p_n_carmen","coqui":"yo_coqui","abuela":"abuela","mama":"esta_es_mama","papa":"n_papa","abuelo":"n_abuelo","bebe":"m_n_bebe","cocina":"m_n_cocina"}
BASECLIPS={"p_n_luis":N("Este es Luis."),"p_n_carmen":N("Esta es Carmen."),"yo_coqui":T("¡Coquí!"),"abuela":N("Esta es abuela."),"esta_es_mama":N("Esta es mamá."),"n_papa":N("Este es papá."),"n_abuelo":N("Este es abuelo."),
 "m_n_bebe":N("Es el bebé."),"m_n_cocina":N("Es la cocina.")}

# ---- La mesa (scene mesa.js): where things stand ----
SILLA=[104,128,152,176]; FOGON=[205,170]; LUIS=[75,160]; CAN=[196,204]; EN_JARRON=[78,112]
def puesto(plato=None,taza=None): return {"plato":plato,"taza":taza,"uts":[],"frente":[]}
def sienta(quien,i,**kw): return g(quien,vis=1,x=SILLA[i],y=150,sent=1,dir=1,**kw)   # sat down already (what sienta() in mesa.js ends with)

# =============== La mesa ===============
# ---- 1. La cuchara de abuelo ----
c=Cuento("d-cuchara-abuelo","ka")
c.do(act("inicio25"),g("carmen",vis=0),g("luis",lleva="bandeja"),{"set":{"mostrador":{}}},{"wait":600},{"dots":1})   # three at the table; Luis stands with the tray in his hands (one spoon, one fork, one knife)
c.do(act("piensa",quien="abuelo",k="hambre"),act("piensa",quien="mama",k="hambre"),act("piensa",quien="papa",k="hambre"))
c.say(N("La familia tiene hambre."))
c.do(g("abuela",ofrece={"k":"plato","con":"comida"})); c.say(N("Abuela tiene la comida."))
c.do({"dots":2},act("plato25",a="abuelo",d="sopa",suelto=1)); c.say(N("Aquí hay sopa para abuelo.")); c.do(act("ya"),act("piensa",quien="abuelo"))
c.do(act("plato25",a="mama",d="espa",suelto=1)); c.say(N("Aquí hay espaguetis para mamá.")); c.do(act("ya"),act("piensa",quien="mama"))
c.do(act("plato25",a="papa",d="pan",suelto=1)); c.say(N("Y aquí hay pan para papá.")); c.do(act("ya"),act("piensa",quien="papa"))
c.do({"dots":3},act("sale",quien="luis"),act("turno25b",ha="mama",hb="papa",hc="abuelo")); c.say(N("Luis pone un cuchillo, una cuchara y un tenedor. Luis va rápido."))
c.say(N("Abuelo tiene sopa. Y tiene un cuchillo."))
c.do(g("abuelo",dir=-1,ms=170),g("abuelo",dir=1,ms=170),g("abuelo",dir=-1,ms=170),g("abuelo",dir=1,ms=170)); c.say(AO("¿Y mi cuchara?"))
c.do({"dots":4},g("mama",alza="",mano="cuchara"),act("come25",a="mama")); c.say(N("Mamá tiene la cuchara. ¡Ay! Los espaguetis se caen."))
c.do(g("papa",alza="",mano="tenedor"),act("come25",a="papa")); c.say(N("Y papá tiene pan y un tenedor."))
c.do({"dots":5},act("rana",x=SILLA[1]-14,y=190)); c.say(T("¡Mamá! La cuchara es para abuelo."))
c.do(act("llama",a="abuelo",k="cuchara")); c.say(N("Ahora abuelo tiene la cuchara."))
c.do(act("come25",a="abuelo")); c.say(N("Abuelo come con la cuchara."))
c.do(act("rana",x=SILLA[2]-14,y=190)); c.say(T("¡Papá! El tenedor es para mamá."))
c.do(act("llama",a="mama",k="tenedor")); c.say(N("Ahora mamá tiene el tenedor. Y papá tiene el cuchillo."))
c.do(act("come25",a="mama"),g("papa",alza="",mano="cuchillo"),act("come25",a="papa")); c.say(N("Mamá come con el tenedor. Papá come pan."))
c.say(AB("¡Muy bien, Coquí!")); c.say(N("La familia come.")); c.do(*CORAZON)
guarda(c,"La cuchara de abuelo","mesa","escucha",5)

# ---- 2. La comida de Coquí ----
c=Cuento("d-comida-coqui","kb")
LLENO=puesto({"n":1,"con":"comida"},{"n":1,"con":"agua","k":"vaso"})
c.do(act("inicio26"),{"set":{"mostrador":{"comidas":2,"vasos":2,"jarron":1},"estufa":{"olla":1,"vapor":1},"sitio":{"abuelo":0,"mama":1,"papa":2},"puestos":[LLENO,LLENO,LLENO,puesto()]}},
  sienta("abuelo",0,hace="come",que="tenedor"),sienta("mama",1,hace="bebe",que="vaso"),sienta("papa",2,hace="come",que="tenedor"),g("abuela",x=EN_JARRON[0]+26,y=182,dir=-1),{"wait":600},{"dots":1})
c.say(N("La familia come en la cocina."))
c.do({"dots":2},act("canelo26")); c.say(N("Canelo entra. Canelo tiene hambre."))
c.do(act("abuelada",k="hambre",suelto=1)); c.say(AB("Toma, Coquí. Tu comida.")); c.do(act("ya"))
c.say(T("¡Gracias, abuela!"))
c.do({"dots":3},act("canelo",de="coqui")); c.say(N("¡Ay, no! Canelo se come la comida de Coquí."))
c.say(AB("¡Canelo! ¡Esa es la comida de Coquí!"))
c.do(act("abuelada",k="hambre",suelto=1)); c.say(AB("Toma, Coquí. Más comida.")); c.do(act("ya"))
c.do({"set":{"perro":{"x":CAN[0],"y":CAN[1],"pose":"sit","dir":-1}}},act("rana",x=104,y=192)); c.say(N("Canelo mira la comida. Y Coquí mira a Canelo."))
c.do({"dots":4},act("ranatoma")); c.say(N("¡Ahora Coquí come rápido!")); c.say(T("¡Mmm! ¡Qué rico!")); c.do(act("quita26"),act("casa"))
c.do({"set":{"perro":{"x":CAN[0],"y":CAN[1],"pose":"bark","dir":-1}}},act("abuelada",k="sed",suelto=1)); c.say(AB("Y agua para Coquí.")); c.do(act("ya"))
c.do({"dots":5},act("canelo",de="coqui")); c.say(N("¡Ay! Canelo se bebe el agua de Coquí."))
c.say(T("¡Canelo tiene sed!"))
c.do(act("abuelada",k="sed",suelto=1)); c.say(AB("Toma más agua, Coquí.")); c.do(act("ya"),act("ranatoma"),{"set":{"perro":{"x":132,"y":202,"pose":"lie","dir":-1,"cola":1}}})
c.say(N("Coquí bebe agua. Y Canelo está contento.")); c.do(*CORAZON)
guarda(c,"La comida de Coquí","mesa","escucha",5)

# =============== La estufa ===============
# ---- 3. El chocolate de Luis ----
# In the stove scene a cup held by "mama" is drawn as the baby (draw: p.bebe on mama is the baby), so mamá's cups go through a stand-in person, mama2, who is never drawn (vis 0) and
# stands where mamá stands: the acts that walk Luis and the frog to somebody walk them to her, and mamá herself holds the cup in her hand (lleva) from the same moment.
GENTE29={"abuela":{"x":82,"y":174,"dir":1},"luis":{"x":160,"y":176,"dir":1},"carmen":{"vis":0},"abuelo":{"vis":0},"mama":{"vis":0},"papa":{"vis":0},"mama2":{"x":207,"y":212,"dir":-1,"vis":0}}
TAZA=lambda v:{"k":"taza","v":v}
c=Cuento("d-chocolate-luis","kc")
c.do(act("inicio29"),{"set":{"gente":GENTE29}},{"wait":500},{"dots":1},act("frie"))
c.say(N("Abuela hace la comida.")); c.say(N("Luis tiene chocolate caliente. Y chocolate frío."))
c.do({"dots":2},act("viene",quien="papa"),act("piensa",quien="papa",k="frio")); c.say(PA("Tengo sed. Quiero chocolate frío, por favor."))
c.do(act("llena",k="cal")); c.say(L("Toma, papá."))
c.do(act("luisda",a="papa",queda=1),act("niega",a="papa")); c.say(PA("No, Luis. Ese chocolate está caliente."))
c.do(act("luisbebe",a="papa")); c.say(N("Luis se bebe el chocolate caliente."))
c.do({"dots":3},act("viene",quien="mama",lugar=2),act("piensa",quien="mama",k="cal")); c.say(MA("Yo quiero chocolate caliente, por favor."))
c.do(act("llena",k="frio"),act("luisda",a="mama2",queda=1),g("mama",lleva=TAZA("frio")),act("niega",a="mama")); c.say(MA("No, Luis. Ese chocolate está frío."))
c.do(g("mama",lleva=""),act("luisbebe",a="mama2")); c.say(N("Luis se bebe el chocolate frío."))
c.do({"dots":4},act("asoma")); c.say(AB("¡Ay, Luis!")); c.say(N("Luis ya no tiene sed. Luis está contento."))
c.do({"dots":5}); c.say(T("¡Ahora yo!"))
c.do(act("ranallena",k="frio",a="papa",suelto=1)); c.say(N("Este chocolate frío es para papá.")); c.do(act("ya"),act("piensa",quien="papa"))
c.do(act("ranallena",k="cal",a="mama2",suelto=1)); c.say(N("Y este chocolate caliente es para mamá.")); c.do(act("ya"),g("mama",lleva=TAZA("cal"),pose="taza"),act("piensa",quien="mama"))
c.say(PA("¡Gracias, Coquí!")); c.say(N("Papá bebe chocolate. Y mamá también."))
c.do(g("luis",lleva={"k":"taza"},dir=-1,pose="offer")); c.say(L("¿Y para mí?"))
c.do(act("niega",a="abuela")); c.say(AB("No, Luis. ¡No más chocolate!")); c.do(*CORAZON)
guarda(c,"El chocolate de Luis","estufa","escucha",5)

# =============== La nevera ===============
# ---- 4. Comida para el parque ----
ENC=112; SILL=98
TRAY={"k":"bandeja","x":196,"y":ENC+11,"z":99}
NEV31=lambda **kw:dict({"abierta":1,"h":[{"k":"platofruta"},{"k":"platofruta"},{"k":"platofruta"},None],"cajon":{"guineo":2,"manzana":2}},**kw)
SILLFRUTA=lambda k,x:{"id":"s_"+k,"k":k,"v":None,"x":x,"e":2,"viejo":False}
c=Cuento("d-comida-parque","kd")
c.do(act("inicio31"),{"set":{"patio":{"aves":[],"cosas":[]}}},{"wait":500},{"dots":1})
c.say(AB("Vamos al parque.")); c.do(tw("pan")); c.say(N("Abuela busca comida para el parque.")); c.do(tw(None))
c.do({"dots":2},act("cajon31",ver=1),act("sostienen",luis="guineo",ya=1),{"set":{"nev":NEV31()}}); c.say(N("Aquí hay un guineo y una manzana.")); c.say(AB("La fruta es para el parque."))
c.do(act("nino31",a="carmen",guarda=1)); c.say(N("Carmen pone la manzana en la canasta."))
c.do({"dots":3},act("nino31",a="luis",suelto=1)); c.say(N("¿Y Luis? ¡Luis se come el guineo!")); c.do(act("ya")); c.say(AB("¡Luis! El guineo es para el parque."))
c.do({"dots":4},act("abuelo31",que="trae")); c.say(N("Abuelo tiene más fruta."))
c.do({"set":{"repisa":[SILLFRUTA("guineo",166)],"cosas":[TRAY,{"k":"manzana","x":186,"y":SILL,"e":2,"z":999}]}},act("abuelo31",que="da"),{"set":{"repisa":[SILLFRUTA("manzana",186)],"cosas":[TRAY]}},act("abuelo31",que="come",suelto=1))
c.say(N("Abuela pone el guineo en la canasta. Y abuelo se come la manzana.")); c.do(act("ya")); c.say(AB("¡Ay, abuelo!"))
c.do({"dots":5},act("lote",izq="pan"),{"set":{"cosas":[TRAY,{"id":"t_pan","k":"panecillo","x":187,"y":ENC+9,"z":300,"viejo":False}],"patio":{"aves":[{"x":153}],"cosas":[]}}}); c.say(N("Aquí hay pan para el parque."))
c.do(act("tira31",a="t_pan",suelto=1)); c.say(N("¡Coquí le tira el pan al pájaro! El pájaro se come el pan.")); c.do(act("ya"))
c.say(AB("¡Coquí! ¡El pan es para el parque!")); c.say(T("¡El pájaro tiene hambre!"))
c.do(act("abuelaa31")); c.say(N("En la canasta hay una manzana y un guineo.")); c.say(AB("No hay mucha comida."))
c.say(AB("¡Vamos al parque!"))
c.do(g("luis",alza={"k":"canasta","e":1,"dx":6,"dy":-6}),{"set":{"canasta":None}},act("ninos32",que="salen")); c.say(N("Luis y Carmen van al parque. Y Coquí también."))
c.say(T("¡Adiós, pajarito!")); c.do(*CORAZON)
guarda(c,"Comida para el parque","nevera","escucha",5)

# =============== Haz esto ===============
def mueve_mano(quien,n=2):   # a wave: the hand goes up and down
    return [g(quien,pose="wave0",ms=250),g(quien,pose="wave1",ms=250)]*n+[g(quien,pose="idle")]
def lee(c,k): c.leer.append(k); return k

# ---- A. En la mesa ----
c=Cuento("h-mesa","wa")
nos(c,{"platos":"esos son los platos.","tazas":"esas son las tazas.","mesa_m":"esa es la mesa."})   # the touch on the table is aliased to mesa_m: hz_no_mesa already means "No. Esa es la mesa." (h-balcon)
c.clips.update({k:BASECLIPS[k] for k in ("p_n_luis","abuela","esta_es_mama","n_papa","n_abuelo","m_n_bebe","m_n_cocina","yo_coqui")})
c.do(act("inicio24"),{"set":{"sitio":{"abuelo":0,"papa":1,"mama":3}}},sienta("abuelo",0),sienta("papa",1),sienta("mama",3),g("abuela",x=48,y=168,dir=1),{"wait":500})   # abuela and Luis at the counter, three at the table, the plates and cups on the counter
MU=lambda k:[act("muestra",k=k),{"wait":700},act("muestra",k="")]
AMESA={"mesa":"mesa_m"}
c.do({"dots":1}); orden(c,"¿Dónde están los platos?","platos",["platos","tazas","mesa_m"],MU("plato"),alias=AMESA)
orden(c,"Toca las tazas.","tazas",["platos","tazas","mesa_m"],MU("taza"),alias=AMESA)
c.do({"dots":2}); orden(c,None,"platos",["platos","tazas"],[act("pon",k="plato",a="abuelo"),act("casa")],clip=AB("Un plato para abuelo."))
orden(c,None,"tazas",["platos","tazas"],[act("pon",k="taza",a="mama"),act("casa")],clip=AB("Una taza para mamá."))
orden(c,None,"platos",["platos","tazas"],[act("pon",k="plato",a="papa"),act("casa")],clip=AB("Un plato para papá."))
c.do({"dots":3}); orden(c,"¿Quién tiene una taza?","mama",["mama","abuelo","papa"],[act("pose",quien="mama",que="wave"),{"wait":1000},act("pose",quien="mama",que="idle")])
c.do({"dots":4}); par(c,"Toca al bebé y a papá.","bebe","papa",[g("mama",bebe="clap"),{"wait":1000},g("mama",bebe=1)],[act("pose",quien="papa",que="wave"),{"wait":1000},act("pose",quien="papa",que="idle")],"abuelo",fin)
guarda(c,"En la mesa","mesa","haz",4,names={"coqui":"yo_coqui","luis":"p_n_luis","abuela":"abuela","mama":"esta_es_mama","papa":"n_papa","abuelo":"n_abuelo","bebe":"m_n_bebe","cocina":"m_n_cocina"})

# ---- B. En la estufa ----
c=Cuento("h-estufa","wb")
nos(c,{"olla":"esa es una olla.","saco":"ese es el arroz.","tazon":"esas son las habichuelas.","olla_fria":"esa olla está fría."})   # the touch on either pot is aliased to olla; on Luis's pot, in line 6, to olla_fria
c.clips.update({k:BASECLIPS[k] for k in ("p_n_luis","p_n_carmen","abuela","m_n_cocina","yo_coqui")})
c.do(act("inicio27"),{"wait":500})
AOLLA={"olla0":"olla","olla1":"olla"}
c.do({"dots":1}); orden(c,"¿Dónde está el arroz?","saco",["saco","tazon","olla"],[tw("saco"),{"wait":800},tw(None)],alias=AOLLA)
orden(c,"Toca las habichuelas.","tazon",["saco","tazon","olla"],[tw("tazon"),{"wait":800},tw(None)],alias=AOLLA)
c.do({"dots":2}); orden(c,None,"saco",["saco","tazon"],[act("echa",k="arroz",a="abuela")],clip=AB("Dame arroz, por favor."))
orden(c,None,"tazon",["saco","tazon"],[act("echa",k="hab",a="luis")],clip=L("Dame habichuelas, por favor."))
orden(c,None,"saco",["saco","tazon"],[act("echa",k="arroz",a="abuela")],clip=AB("Más arroz, por favor."))
c.do({"dots":3},act("apaga",a="luis"))   # the flame under Luis's pot goes out just before the question
k=c.clip(AB("¡Cuidado! Está caliente."))
orden(c,"¿Cuál olla está caliente?","olla1",["olla1","olla_fria"],[g("abuela",pose="wave0"),k,g("abuela",pose="idle")],alias={"olla0":"olla_fria"}); lee(c,k)
c.do({"dots":4}); par(c,"Toca a abuela y a Luis.","abuela","luis",mueve_mano("abuela"),mueve_mano("luis"),"carmen",fin)
guarda(c,"En la estufa","estufa","haz",4,names={"coqui":"yo_coqui","luis":"p_n_luis","carmen":"p_n_carmen","abuela":"abuela","cocina":"m_n_cocina"})

# ---- C. En la nevera ----
c=Cuento("h-nevera","wc")
nos(c,{"nevera":"esa es la nevera.","red":"esas son las chinas.","mant":"esa es la mantequilla.","jarra":"ese es el jugo.","v_verde":"ese es el vaso verde.","v_amarillo":"ese es el vaso amarillo.","v_rojo":"ese es el vaso rojo.","v_azul":"ese es el vaso azul.","v_rojo_l":"ese vaso está lleno."})   # in lines 5 and 6 the touch on the red cup is aliased to v_rojo_l
c.clips.update({k:BASECLIPS[k] for k in ("abuela","m_n_cocina","yo_coqui")})
COSA32=lambda i,k,v,x,y,**kw:dict({"id":i,"k":k,"v":v,"x":x,"y":y,"z":100},**kw)
c.do(act("inicio32"),g("luis",vis=0),g("carmen",vis=0),g("papa",vis=0),g("abuelo",vis=0),g("mama",vis=0),
  {"set":{"cosas":[COSA32("red","red",4,142,ENC+10),COSA32("jarra","jarra",3,156,ENC+10),COSA32("v_rojo","vaso","rojo",170,ENC+10,n=1),COSA32("v_verde","vaso","verde",182,ENC+10,n=1),
    COSA32("v_amarillo","vaso","amarillo",194,ENC+10,n=0),COSA32("v_azul","vaso","azul",206,ENC+10,n=0),COSA32("mant","mantequilla",3,178,SILL,z=90)]}},{"wait":500})   # the bread on the sill and the two clear glasses are not in the script's picture; the cups are spaced so that the red one and the blue one are far enough apart for a round picture over each; the round pictures float above the sill, clear of the butter
V4=["v_verde","v_amarillo","v_rojo","v_azul"]
c.do({"dots":1}); orden(c,"¿Dónde están las chinas?","red",["red","mant","jarra"],[tw("red"),{"wait":800},tw(None)])
orden(c,"Toca la mantequilla.","mant",["red","mant","jarra"],[tw("mant"),{"wait":800},tw(None)])
c.do({"dots":2}); orden(c,"Toca el vaso verde.","v_verde",V4,[tw("v_verde"),{"wait":800},tw(None)])
orden(c,"¿Cuál es el vaso amarillo?","v_amarillo",V4,[tw("v_amarillo"),{"wait":800},tw(None)])
VISTAS=lambda azul:[{"k":"vista","v":"rojo:1","x":170,"dy":-12},{"k":"vista","v":"azul:"+azul,"x":206,"dy":-12}]   # the two round pictures, over the red cup and over the blue one
c.do({"dots":3},{"set":{"repisa":VISTAS("0")}}); orden(c,"¿Cuál vaso está vacío?","v_azul",["v_azul","v_rojo_l"],[tw("v_azul"),{"wait":800},tw(None)],alias={"v_rojo":"v_rojo_l"})
orden(c,None,"v_azul",["v_azul","v_rojo_l"],[act("vierte",a="v_azul"),{"set":{"repisa":VISTAS("1")}}],clip=AB("Coquí, ponle jugo al vaso vacío."),alias={"v_rojo":"v_rojo_l"})
c.do({"dots":4}); par(c,"Toca la nevera y el vaso verde.","nevera","v_verde",[{"set":{"nev":{"abierta":1,"h":[]}}},{"wait":900},{"set":{"nev":{"abierta":0,"h":[]}}}],[tw("v_verde"),{"wait":800},tw(None)],"v_amarillo",fin)
guarda(c,"En la nevera","nevera","haz",4,names={"coqui":"yo_coqui","abuela":"abuela","cocina":"m_n_cocina"})

# ---- clip ids are global: the same id must have the same text everywhere ----
seen={}; clash=0; new=0; chars=0
for f in sorted(glob.glob("cuentos/*.json")):
    if os.path.basename(f).startswith("z"): continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items():
        key=(cl.get("who"),cl.get("text"))
        if cid in seen and seen[cid]!=key: print("CLASH",cid,seen[cid],key,f); clash+=1
        seen.setdefault(cid,key)
for cid,(who,text) in seen.items():
    if not os.path.exists(f"audio/{cid}.mp3"): new+=1; chars+=len(text)
print(len(seen),"clips,",new,"new,",chars,"characters to record,",clash,"clashes")
for r in REUSADOS: print("reuses:",r)
