# Escuchar, place 1: picture stories (tipo "escucha") and do-this routines (tipo "haz"). Regenerates the JSON; never edit the JSON by hand.
import json,glob,os,re
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
A=lambda t:D("abuela","Abuela",t); AO=lambda t:D("abuelo","Abuelo",t); MA=lambda t:D("mama","Mamá",t); PA=lambda t:D("papa","Papá",t)
L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
LH=lambda t:D("hermano","Luis",t); CH=lambda t:D("hermana","Carmen",t)   # in La sala the children are drawn as hermano and hermana
AB=A
tw=lambda k:{"set":{"twinkle":k}}
def act(_n,**k): return dict({"act":_n},**k)
base={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}

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
def guarda(c,title,scene,tipo,dots,extra=None,names=None,mins=1):
    d={"id":c.id,"title":title,"place":"La casa","scene":scene,"tipo":tipo,"goal":"Escuchar. Nothing is scored.","stake":{"thing":"none","steps":9},"dots":dots,"bien":"muy_bien",
       "focus_words":[],"back_again":[],"also_heard":[],"names":names or {"coqui":"yo_coqui"},"clips":c.clips,"beats":c.beats,"final":[{"wait":900}],"leer":c.leer}
    if extra: d.update(extra)
    json.dump(d,open(f"cuentos/{c.id}.json","w",encoding="utf-8"),ensure_ascii=False,indent=1); return d

# =============== Cuentos con dibujos ===============
# ---- 1. Toc, toc (El frente) ----
c=Cuento("d-toc-toc","dt")
c.do({"wait":600},{"dots":1}); c.say(N("Esta es la casa de abuela."))
c.do({"cam":"puerta"}); c.say(N("La puerta está cerrada.")); c.do({"cam":"ventana"}); c.say(N("La ventana está cerrada.")); c.do({"cam":"wide"})
c.do({"dots":2},act("ir",a="puerta")); c.say(N("Coquí toca la puerta. ¡Toc, toc!"),gap=100); c.do(act("tocar",en="puerta"),{"wait":500}); c.say(N("Abuela no abre."))
c.do(act("ir",a="ventana")); c.say(N("Coquí toca la ventana. ¡Toc, toc!"),gap=100); c.do(act("tocar",en="ventana"),{"wait":500}); c.say(N("Abuela no abre la ventana."))
c.do({"dots":3},act("trueno"),act("atras"),act("burbuja",quien="cq",que="lluvia")); c.say(N("¡Mira! Ahí viene la lluvia."),gap=100); c.do(act("gotas"),act("calla"))
c.do(act("ir",a="puerta")); c.say(N("Coquí toca la puerta. ¡Toc, toc, toc!"),gap=100); c.do(act("tocar",en="puerta"),act("tocar",en="puerta"))
c.do(act("luz"),act("dentro",en="puerta")); c.say(AB("¿Quién es?"),gap=250); c.say(T("¡Soy yo, abuela! ¡Abre!"),gap=300); c.do(act("calla"))
c.do({"dots":4},act("abre",que="puerta")); c.say(N("Abuela abre la puerta.")); c.do(act("pose",que="wave")); c.say(AB("¡Hola, Coquí! Entra."),gap=300); c.do(act("pose",que="idle"))
c.say(N("Coquí entra a la casa."),gap=100); c.do(act("entra",por="puerta"),{"cam":"wide","n":9})
c.do({"dots":5},act("llueve")); c.say(N("Ahora está lloviendo.")); c.do(act("abcierra",que="puerta")); c.say(N("Abuela cierra la puerta."))
c.do(act("abre",que="ventana")); c.say(N("Abuela abre la ventana.")); c.do(act("cuadro")); c.say(N("Abuela y Coquí miran la lluvia.")); c.do(act("fin"))
guarda(c,"Toc, toc","frente","escucha",5)

# ---- 2. Agua para el pájaro (El balcón) ----
c=Cuento("d-agua-pajaro","da")
c.do({"set":{"calor":3,"door":1}},{"wait":600},{"dots":1},act("burbuja",quien="cq",que="calor")); c.say(N("Hace calor.")); c.do(act("calla"),act("pose",que="wave"))
c.say(AB("Ven al balcón, Coquí."),gap=250); c.do(act("pose",que="idle"),act("sube"))
c.do(act("absienta")); c.say(N("Abuela se sienta en la silla grande.")); c.do(act("ir",a="silla_pequena")); c.say(N("Coquí se sienta en la silla pequeña."))
c.do({"dots":2},act("abentra")); c.say(N("Abuela entra a la casa.")); c.do(act("absale")); c.say(N("¡Mira! Abuela tiene dos vasos.")); c.do(act("pone2")); c.say(N("Abuela pone los vasos en la mesa."))
c.do(tw("jugo")); c.say(N("Un vaso de jugo.")); c.do(tw("agua")); c.say(N("Y un vaso de agua.")); c.do(tw(None),act("absienta"))
c.do({"dots":3}); c.say(AB("El jugo es para ti, Coquí."),gap=250); c.say(N("Coquí toma el jugo."),gap=100); c.do(act("coge",en="jugo"),act("bebecq"))
c.do({"dots":4},act("aveva",en="agua")); c.say(N("¡Mira! El pájaro.")); c.say(N("El pájaro toma el agua."),gap=100); c.do(act("avebebe",en="agua"))
c.do({"dots":5},act("avesilla")); c.say(N("El pájaro se sienta en la silla pequeña.")); c.do(act("burbuja",quien="cq",que="mal")); c.say(T("¡Mi silla!"),gap=300); c.do(act("calla"),act("pose",que="wave"))
c.say(AB("Ven acá, Coquí."),gap=250); c.do(act("pose",que="idle"),act("ir",a="abuela"),act("burbuja",quien="cq",que="amor"),{"wait":1000},act("calla"))
guarda(c,"Agua para el pájaro","balcon","escucha",5)

# ---- 3. El bizcocho del bebé (La sala) ----
c=Cuento("d-bizcocho-bebe","db")
def reparto(c,quien,linea,gracias=None):
    c.say(linea,gap=200); c.do(act("dale"),act("da",en=quien),act("come",quien=quien))
    if gracias: c.say(gracias,gap=250)
c.do({"set":{"pastel":"tapado"}},act("duerme"),{"wait":600},{"dots":1}); c.say(N("Esta es la sala. Aquí está la familia.")); c.do(tw("abuelo")); c.say(N("Abuelo duerme.")); c.do(tw(None))
c.do(act("destapa")); c.say(N("¡Mira! Un bizcocho.")); c.do(act("pose",quien="abuela",que="wave")); c.say(A("¿Quién quiere bizcocho?"),gap=250); c.do(act("pose",quien="abuela",que="idle"))
c.do(act("pose",quien="mama",que="wave")); c.say(MA("¡Yo!"),gap=200); c.do(act("pose",quien="mama",que="idle"),act("pose",quien="papa",que="wave")); c.say(PA("¡Yo también!"),gap=200); c.do(act("pose",quien="papa",que="idle"))
c.do(act("saluda",quien="bebe")); c.say(N("El bebé también quiere."))
c.do({"dots":2}); reparto(c,"mama",A("Este es para mamá."),MA("Gracias, Coquí.")); reparto(c,"papa",A("Y este es para papá."),PA("Gracias."))
c.do({"dots":3},act("llora")); c.say(N("El bebé no tiene bizcocho. El bebé llora.")); reparto(c,"bebe",A("Este es para el bebé.")); c.do(act("llora",no="1"),act("saluda",quien="bebe")); c.say(N("Ahora el bebé no llora. El bebé come."))
c.do({"dots":4},tw("abuelo")); c.say(N("¿Y abuelo? Abuelo duerme.")); c.do(tw(None),act("ir",a="abuelo")); c.say(N("Coquí toca a abuelo."),gap=100); c.do(act("despierta"),act("ir",a="centro"))
c.say(AO("¿Bizcocho? ¡Sí, por favor!"),gap=250); c.do(act("dale"),act("da",en="abuelo"),act("come",quien="abuelo")); c.say(AO("Gracias, Coquí."),gap=250); c.say(T("De nada."),gap=300)
c.do({"dots":5},act("suplato")); c.say(A("Y este es para ti, Coquí."),gap=250); c.say(T("¡Gracias, abuela!"),gap=300); c.do(act("vuelve"),act("comen")); c.say(N("La familia come bizcocho.")); c.do({"set":{"heart":1}},{"wait":700})
guarda(c,"El bizcocho del bebé","sala","escucha",5)

# ---- 4. La foto de la familia (La sala) ----
c=Cuento("d-foto-familia","df")
def foto(c,quien,x0,y0,dice,linea):
    c.say(dice,gap=200); c.do(act("anda",quien=quien,x="120",y="146"),act("dispara",con=quien,ok="1",solo="1")); c.say(linea)
    if x0: c.do(act("anda",quien=quien,x=str(x0),y=str(y0)))
c.do({"wait":400},act("corren"),act("camara"),{"dots":1}); c.say(N("Abuelo tiene una cámara."))
foto(c,"hermana",84,200,AO("Carmen, ven. Una foto."),N("¡Mira! La foto de Carmen."))
c.do({"dots":2}); foto(c,"hermano",156,200,AO("Ahora Luis."),N("La foto de Luis."))
c.do({"dots":3}); foto(c,"mama",None,None,AO("Ahora mamá y el bebé."),N("La foto de mamá y el bebé.")); c.do(act("sientan"))
c.do({"dots":4},tw("fotos"),{"wait":700},tw(None),act("pose",quien="hermana",que="tu")); c.say(CH("¿Y tú, abuelo?"),gap=300); c.do(act("pose",quien="hermana",que="idle"))
c.say(N("Abuelo pone la cámara en la mesa."),gap=100); c.do(act("ponecamara")); c.say(AO("¡Vengan todos! ¡Ven, Coquí!"),gap=200); c.do(act("final7"))
c.do({"dots":5},act("retrato")); c.say(N("¡Mira! La foto de la familia.")); c.say(T("¡Y yo también!"),gap=500)
guarda(c,"La foto de la familia","sala","escucha",5)

# ---- 5. La bola (El patio) ----
c=Cuento("d-la-bola","dl")
c.do({"set":{"gente":{"luis":{"x":150,"y":150,"pose":"idle"},"carmen":{"x":84,"y":150,"pose":"idle","dir":1}},"bola":{"x":162,"y":150},"cq":{"x":30,"y":104,"s":.8,"dy":0,"al":1,"vis":1,"bub":None}}},act("flores"),{"wait":600})
c.do({"dots":1}); c.say(N("Luis y Carmen están en el patio.")); c.say(N("Luis juega con la bola."),gap=100); c.do(act("juega")); c.say(N("Carmen juega también."),gap=100); c.do(act("pelota"))
c.do({"dots":2}); c.say(L("¡Mira, Carmen! ¡Mira!"),gap=100); c.do(act("bolaarbol")); c.say(N("La bola está en el árbol."))
c.do(act("burbuja",quien="luis",que="q")); c.say(L("¡Mi bola!"),gap=250); c.do(act("calla"),act("apunta",quien="carmen")); c.say(CA("La bola está allá."),gap=300); c.do(act("apunta",quien="carmen",no="1"))
c.do({"dots":3},act("ir",a="arbol")); c.say(N("Coquí va al árbol.")); c.do(act("ojos",x="1",y="-1")); c.say(T("¡Amigo! ¡Mira! ¡La bola!"),gap=300)
c.do(act("avesale")); c.say(N("El pájaro mira la bola.")); c.say(N("El pájaro toca la bola."),gap=100); c.do(act("ojos",on="0"),act("avepica2")); c.say(N("¡La bola está aquí!"))
c.do({"dots":4},act("pose",quien="luis",que="wave")); c.say(L("¡Gracias, amigo!"),gap=200); c.do(act("pose",quien="luis",que="idle"),act("aveloop"))
c.do(act("ir",a="centro")); c.say(N("Ahora Luis juega, Carmen juega y Coquí juega."),gap=100); c.do(act("pelota3"),{"set":{"heart":1}},{"wait":700})
guarda(c,"La bola","patio","escucha",4)

# ---- 6. Buenas noches (El patio) ----
c=Cuento("d-buenas-noches","dn")
c.do(act("inicio11"),{"set":{"luces":[]}},act("pose",quien="carmen",que="idle"),act("deja",quien="abuelo"),act("pon",quien="luis",x="136",y="164"),act("pon",quien="carmen",x="170",y="160"),{"wait":600},{"dots":1}); c.say(N("Mira el sol."),gap=100); c.do(act("puesta")); c.say(N("¡Mira! Una estrella."))
c.do({"dots":2},act("llama",quien="mama")); c.say(MA("¡Niños! ¡Vamos para adentro!"),gap=300); c.do(act("pose",quien="mama",que="idle"))
c.do(act("pose",quien="carmen",que="wave")); c.say(CA("Hasta mañana, Coquí."),gap=200); c.do(act("pose",quien="carmen",que="idle"),act("pose",quien="luis",que="wave")); c.say(L("Hasta mañana, amigo."),gap=200); c.do(act("pose",quien="luis",que="idle")); c.say(T("¡Hasta mañana!"),gap=300)
c.say(N("Los niños entran a la casa."),gap=100); c.do(act("seva",quien="luis+carmen")); c.say(N("Mamá, papá y el bebé entran."),gap=100); c.do(act("seva",quien="papa+mama"))
c.do({"dots":3},act("pose",quien="abuelo",que="wave")); c.say(AO("Buenas noches, Coquí."),gap=200); c.do(act("pose",quien="abuela",que="wave")); c.say(A("Buenas noches."),gap=200); c.say(T("Buenas noches, abuela. Buenas noches, abuelo."),gap=300)
c.do(act("seva",quien="abuelo+abuela"),act("cierra")); c.say(N("Abuela cierra la puerta."))
c.do({"dots":4},act("noche")); c.say(N("Ahora es de noche.")); c.do(act("aveduerme")); c.say(N("El pájaro duerme."))
c.do(act("luzsale")); c.say(N("¡Mira! Un cucubano.")); c.do(act("luzsale"),act("luzsale")); c.say(N("Y otro. Y otro más."))
c.do({"dots":5}); c.say(N("Coquí no duerme. Coquí canta."),gap=100); c.do(act("canta")); c.say(N("Buenas noches, Coquí."),gap=500)
guarda(c,"Buenas noches","patio","escucha",5)

# =============== Haz esto ===============
def orden(c,linea,pick,ops,right,vale=None,mudo=None,clip=None,alias=None):
    if mudo: k=mudo
    else:
        k=c.say(clip or N(linea)); c.beats.pop()   # the line belongs to the decision, it is not a beat of its own
    d={"decide":"do","libre":True,"bien":False,"lock":True,"options":ops,"pick":pick,"lead":[],"line":k,"right":right}
    if vale: d["vale"]=vale
    if alias: d["alias"]=alias
    if mudo: d["mudo"]=True
    c.do(d); return k
def nos(c,m):
    for k,t in m.items(): c.clips["hz_no_"+k]=N("No. "+t)
fin=[{"wait":300},{"say":"muy_bien","gap":300},{"set":{"heart":1}},{"wait":600}]
def par(c,linea,a,b,ra,rb,tercero,despues,alias=None):
    """A line in two parts ("Toca a mamá y a papá"). Either order counts. Then the other one; a touch on the part already done is only a poke."""
    k=c.say(N(linea)); c.beats.pop()
    d1={"decide":"do","libre":True,"bien":False,"lock":True,"options":[a],"vale":[b],"pick":a,"lead":[],"line":k,"right":[{"if":"x="+a,"then":ra,"else":rb}]}
    d2={"decide":"do","libre":True,"bien":False,"mudo":True,"options":["$otro",tercero],"pick":"$otro","lead":[],"line":k,"right":[{"if":"otro="+a,"then":ra,"else":rb}]+despues}
    if alias: d1["alias"]=alias; d2["alias"]=alias
    c.do(d1,{"calc":"otro","cond":"x="+a,"then":b,"else":a},d2)

# ---- A. Abre y cierra (El frente) ----
c=Cuento("h-frente","ha"); PV=["puerta","ventana"]
nos(c,{"puerta":"Esa es la puerta.","ventana":"Esa es la ventana."})
hola=c.clip(AB("¡Hola!")); bien=c.clip(AB("¡Muy bien, Coquí!"))
c.do({"wait":600},{"dots":1}); orden(c,"Toca la puerta.","puerta",PV,[act("tocar",en="puerta")]); orden(c,"¿Dónde está la ventana?","ventana",PV,[act("tocar",en="ventana")])
c.do({"dots":2}); orden(c,"Abre la puerta.","puerta",PV,[act("abrir",que="puerta"),{"set":{"ab":{"en":"puerta","pose":"wave","bub":None,"al":1}}},{"say":hola,"gap":300},act("vete")]); orden(c,"Abre la ventana.","ventana",PV,[act("abrir",que="ventana")])
c.do({"dots":3}); orden(c,"Cierra la puerta.","puerta",PV,[act("cerrar",en="puerta")]); orden(c,"Cierra la ventana.","ventana",PV,[act("cerrar",en="ventana")])
c.do({"dots":4}); k=orden(c,"Abre la ventana y toca a abuela.","ventana",PV,[act("abrir",que="ventana"),{"set":{"ab":{"en":"ventana","pose":"idle","bub":None,"al":1}}},{"wait":300}])
orden(c,None,"abuela",["abuela","puerta"],[act("pose",que="wave"),{"say":bien,"gap":400},act("pose",que="idle"),{"set":{"heart":1}},{"wait":600}],mudo=k)
guarda(c,"Abre y cierra","frente","haz",4,names={"puerta":"puerta","ventana":"ventana","coqui":"yo_coqui"})

# ---- B. En el balcón (El balcón) ----
c=Cuento("h-balcon","hb")
nos(c,{"silla_grande":"Esa es la silla grande.","silla_pequena":"Esa es la silla pequeña.","mesa":"Esa es la mesa.","jugo":"Eso es jugo.","agua":"Eso es agua."})
hola=c.clip(AB("¡Hola!")); gracias=c.clip(AB("Gracias."))
S3=["silla_grande","silla_pequena","mesa"]; JA=["jugo","agua"]; SG={"abuela":"silla_grande"}   # while she sits on it, a touch on abuela is a touch on the big chair
c.do({"set":{"door":1}},{"wait":400},act("sube"),tw("mesa")); c.say(N("Esta es la mesa.")); c.do(tw(None))
c.do({"dots":1}); orden(c,"Toca la silla grande.","silla_grande",S3,[act("absienta")]); orden(c,"¿Dónde está la silla pequeña?","silla_pequena",S3,[act("ir",a="silla_pequena")],alias=SG)
orden(c,"Toca la mesa.","mesa",S3,[act("abentra"),act("absale"),act("pone2"),act("absienta"),act("ir",a="mesa")],alias=SG)
c.do({"dots":2}); orden(c,"¿Dónde está el jugo?","jugo",JA,[act("coge",en="jugo"),act("bebecq")]); orden(c,"Toca el agua.","agua",["agua","silla_pequena"],[act("coge",en="agua"),act("bebecq")])
c.do({"dots":3},{"set":{"vasos":[]}},act("pone"),act("ir",a="decir"),tw("jugo")); c.say(N("¡Mira! El jugo y el agua.")); c.do(tw(None))
orden(c,"El agua es para abuela.","agua",JA,[act("lleva",en="agua"),act("bebe"),{"say":gracias,"gap":300},act("deja")],vale=["abuela"])
orden(c,"El jugo es para abuela.","jugo",JA,[act("lleva",en="jugo"),act("bebe"),{"say":gracias,"gap":300},act("deja")],vale=["abuela"])
c.do({"dots":4},{"set":{"jarras":[]}},act("ir",a="mesa"))
par(c,"Toca la silla pequeña y la silla grande.","silla_pequena","silla_grande",[act("ir",a="silla_pequena")],[act("pose",que="wave"),{"say":hola,"gap":300},act("pose",que="idle")],"mesa",fin,alias=SG)
guarda(c,"En el balcón","balcon","haz",4)

# ---- C. La familia (La sala) ----
c=Cuento("h-sala","hc")
nos(c,{"mama":"Esa es mamá.","papa":"Ese es papá.","abuelo":"Ese es abuelo.","bebe":"Ese es el bebé.","hermano":"Ese es Luis.","hermana":"Esa es Carmen."})
hm=c.clip(MA("¡Hola!")); hp=c.clip(PA("¡Hola!")); gp=c.clip(PA("Gracias."))
G4=["mama","papa","abuelo","bebe"]; HH=["hermano","hermana"]
sal=lambda q:[act("saluda",quien=q)]
c.do({"set":{"pastel":"tapado"}},act("duerme"),act("ninos"),{"wait":400},{"dots":1}); orden(c,"Toca a mamá.","mama",G4,sal("mama")+[{"say":hm,"gap":250}]); orden(c,"¿Dónde está papá?","papa",G4,sal("papa")+[{"say":hp,"gap":250}])
c.do({"dots":2}); orden(c,"¿Dónde está el bebé?","bebe",G4,sal("bebe")); orden(c,"Toca a abuelo.","abuelo",G4,[act("despierta")])
orden(c,"Toca a Luis.","hermano",HH,sal("hermano")); orden(c,"¿Dónde está Carmen?","hermana",HH,sal("hermana"))
c.do({"dots":3},act("destapa")); c.say(N("¡Mira! El bizcocho."))
orden(c,"El bizcocho es para papá.","papa",G4,[act("dale"),act("da",en="papa"),act("come",quien="papa"),{"say":gp,"gap":250}],vale=["bizcocho"])
orden(c,"El bizcocho es para el bebé.","bebe",G4,[act("dale"),act("da",en="bebe"),act("come",quien="bebe")],vale=["bizcocho"])
c.do({"dots":4}); par(c,"Toca a mamá y a papá.","mama","papa",sal("mama"),sal("papa"),"abuelo",[act("todos")]+fin)
guarda(c,"La familia","sala","haz",4)

# ---- D. En el patio (El patio) ----
c=Cuento("h-patio","hd")
nos(c,{"luis":"Ese es Luis.","carmen":"Esa es Carmen.","sol":"Ese es el sol.","bola":"Esa es la bola.","pajaro":"Ese es el pájaro.","porton":"Ese es el portón.","puerta":"Esa es la puerta."})
c.do({"set":{"gente":{"luis":{"x":150,"y":150,"pose":"idle"},"carmen":{"x":84,"y":150,"pose":"idle","dir":1}},"bola":{"x":162,"y":150},"flores":{"L":[{"k":1,"c":0},{"k":1,"c":1}],"R":[{"k":1,"c":2},{"k":1,"c":3}]}}},{"wait":500},tw("porton"))
c.say(N("Mira el portón.")); c.do(tw(None)); NN=["luis","carmen"]
c.do({"dots":1}); orden(c,"Toca al niño.","luis",NN,[act("saluda",quien="luis")]); orden(c,"¿Dónde está la niña?","carmen",NN,[act("saluda",quien="carmen")])
c.do({"dots":2}); orden(c,"¿Dónde está el sol?","sol",["sol","bola","porton"],[act("brilla")]); orden(c,"Toca la bola.","bola",["sol","bola","porton"],[act("juega")])
orden(c,"Toca al pájaro.","pajaro",["pajaro","sol","bola"],[act("aveloop")]); orden(c,"Abre el portón.","porton",["porton","puerta"],[act("abreporton")])
c.do({"dots":3},{"set":{"caja":1}},act("ir",a="caja"),act("anda",quien="carmen",a="detras",cama="L"))
c.clips["hz_no_camaL"]=N("No. Allá."); c.clips["hz_no_camaR"]=N("No. Aquí.")
orden(c,None,"camaL",["camaL","camaR"],[act("planta",cama="L")],vale=["carmen"],clip=CA("Una flor aquí."))
orden(c,None,"camaR",["camaL","camaR"],[act("planta",cama="R")],clip=CA("Una flor allá."))
c.do({"dots":4},act("anda",quien="carmen",x="84",y="150")); par(c,"Toca al niño y a la niña.","luis","carmen",[act("saluda",quien="luis")],[act("saluda",quien="carmen")],"bola",[act("pelota")]+fin)
guarda(c,"En el patio","patio","haz",4)

# ---- clip ids are global: the same id must have the same text everywhere ----
seen={}; clash=0; new=0; chars=0
for f in sorted(glob.glob("cuentos/*.json")):
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items():
        key=(cl.get("who"),cl.get("text"))
        if cid in seen and seen[cid]!=key: print("CLASH",cid,seen[cid],key,f); clash+=1
        seen.setdefault(cid,key)
for cid,(who,text) in seen.items():
    if not os.path.exists(f"audio/{cid}.mp3"): new+=1; chars+=len(text)
print(len(seen),"clips,",new,"new,",chars,"characters to record,",clash,"clashes")
