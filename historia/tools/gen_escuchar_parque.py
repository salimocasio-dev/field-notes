# Escuchar, place 2 (El parque): picture stories (tipo "escucha") and do-this routines (tipo "haz"). Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/escuchar-parque.md
import json,glob,os,re
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); AB=lambda t:D("abuela","Abuela",t)
tw=lambda k:{"set":{"twinkle":k}}
def act(_n,**k): return dict({"act":_n},**k)
base={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}
CORAZON=[{"set":{"heart":1}},{"wait":1200}]

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
    d={"id":c.id,"title":title,"place":"El parque","scene":scene,"tipo":tipo,"goal":"Escuchar. Nothing is scored.","stake":{"thing":"none","steps":9},"dots":dots,"bien":"muy_bien",
       "focus_words":[],"back_again":[],"also_heard":[],"names":names or {"coqui":"yo_coqui"},"clips":c.clips,"beats":c.beats,"final":[{"wait":900}],"leer":c.leer}
    if extra: d.update(extra)
    json.dump(d,open(f"cuentos/{c.id}.json","w",encoding="utf-8"),ensure_ascii=False,indent=1); return d

# ---- Haz esto: the same helpers as place 1 ----
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
def nobur(c,ks):
    for k in ks: c.clips["hz_no_"+k]=N("No.")
fin=[{"wait":300},{"say":"muy_bien","gap":300},{"set":{"heart":1}},{"wait":600}]
def par(c,linea,a,b,ra,rb,tercero,despues,alias=None):
    """A line in two parts ("Toca a mamá y a papá"). Either order counts. Then the other one; a touch on the part already done is only a poke."""
    k=c.say(N(linea)); c.beats.pop()
    d1={"decide":"do","libre":True,"bien":False,"lock":True,"options":[a],"vale":[b],"pick":a,"lead":[],"line":k,"right":[{"if":"x="+a,"then":ra,"else":rb}]}
    d2={"decide":"do","libre":True,"bien":False,"mudo":True,"options":["$otro",tercero],"pick":"$otro","lead":[],"line":k,"right":[{"if":"otro="+a,"then":ra,"else":rb}]+despues}
    if alias: d1["alias"]=alias; d2["alias"]=alias
    c.do(d1,{"calc":"otro","cond":"x="+a,"then":b,"else":a},d2)

# =============== El camino ===============
GATO={"x":113,"y":134,"pose":"lava","dir":-1,"en":None}
# ---- 1. ¡Corre! ----
c=Cuento("d-corre","qa")
c.do(act("inicio12"),{"set":{"gato":GATO}},act("pose",quien="perro",que="sit"),act("pose",quien="luis",que="idle"),{"wait":600},{"dots":1})
c.say(N("Este es el parque."))
c.do(act("saluda",quien="luis")); c.say(N("Luis está allá.")); c.do(tw("grande")); c.say(N("¡Mira! El árbol grande.")); c.do(tw(None))
c.say(N("Carmen y Coquí están aquí. Y Canelo también."))
c.do({"dots":2},act("cuenta",queda=1)); c.say(L("Uno. Dos. Tres. ¡A correr!"),gap=200); c.do(act("cuenta",fin=1))
c.do(act("ronda",modo="corre")); c.say(N("Carmen corre. Coquí corre. Y Canelo corre rápido."),gap=100); c.do(act("ronda",modo="corre"))
c.do({"dots":3},tw("gato")); c.say(N("¡Mira! Un gato.")); c.do(tw(None),act("pose",quien="perro",que="bark",dir=-1)); c.say(N("Canelo mira al gato."))
c.do(act("gatoa",x=46,y=172,corre=1,que="sit",dir=1),act("perroa",x=70,y=186,corre=1,que="bark",dir=-1)); c.say(N("El gato corre. ¡Y Canelo corre!"))
c.say(L("¡No, Canelo! ¡Ven aquí!"),gap=200); c.do(act("luisno"))
c.do({"dots":4}); c.say(N("Coquí espera."),gap=300); c.do(act("va",quien="carmen",modo="corre",a=5)); c.say(N("Carmen corre y corre."),gap=100); c.do(act("va",quien="carmen",modo="corre",a=8))
c.do(act("pose",quien="carmen",que="offer",dir=1)); c.say(N("Carmen toca el árbol grande.")); c.do(act("pose",quien="carmen",que="idle"),act("luisrie")); c.say(N("¡Carmen gana!")); c.say(L("¡Muy bien, Carmen!"),gap=200)
c.do(act("ranaa",a=4)); c.say(N("Ahora Coquí corre también."),gap=100); c.do(act("ranaa",a=6))
c.do({"dots":5},act("gatoarbol",en=0),act("asoma"),tw("arbol0"),act("perroa",x=88,y=134,corre=1,que="bark",dir=-1)); c.say(N("¿Y el gato? El gato está arriba, en el árbol.")); c.do(tw(None)); c.say(N("Canelo está abajo."))
c.do(act("pose",quien="perro",que="lie")); c.say(N("Canelo está cansado.")); c.say(N("Y el gato está contento.")); c.do(*CORAZON)
guarda(c,"¡Corre!","camino","escucha",5)

# ---- A. En el camino ----
c=Cuento("h-camino","ra"); MODOS=["camina","corre","espera"]
nos(c,{"perro":"ese es Canelo.","gato":"ese es el gato.","grande":"ese es el árbol grande.","arbol0":"ese es el árbol con dos pájaros.","arbol1":"ese es el árbol con tres pájaros.","arbol2":"ese es el árbol con un pájaro."})
c.clips.update({"hz_no_carmen":N("No. Esa es Carmen."),"hz_no_luis":N("No. Ese es Luis.")}); nobur(c,MODOS)
T3=["arbol0","arbol1","arbol2"]
c.do(act("inicio12"),{"set":{"gato":GATO}},act("pose",quien="perro",que="sit"),act("pose",quien="luis",que="idle"),act("posan",p="231"),{"set":{"respEn":[96,30]}},{"wait":400})   # the answer bubbles stand in the sky, clear of Carmen and the cat
c.do({"dots":1}); orden(c,"Toca al perro.","perro",["perro","gato","carmen"],[act("ladra",n=1)]); orden(c,"¿Dónde está el gato?","gato",["gato","perro","carmen"],[act("ronronea")])
c.do({"dots":2}); orden(c,"Toca el árbol grande.","grande",["grande"]+T3,[act("sacude",en="grande")])
orden(c,"Toca el árbol con tres pájaros.","arbol1",T3,[act("luzn",n="3"),{"wait":700},act("luzn",n="0")],vale=["ave10","ave11","ave12"])
orden(c,"Toca el árbol con un pájaro.","arbol2",T3,[act("luzn",n="1"),{"wait":700},act("luzn",n="0")],vale=["ave20"])
c.do({"dots":3}); orden(c,None,"corre",MODOS,[act("va",quien="cq",modo="corre",a=1)],clip=L("¡Corre, Coquí!"),resp=True)
orden(c,None,"espera",MODOS,[act("va",quien="cq",modo="espera",a=1),act("luisrie")],clip=L("¡Espera!"),resp=True)
orden(c,None,"corre",MODOS,[act("va",quien="cq",modo="corre",a=2)],clip=L("¡Corre!"),resp=True)
c.do({"dots":4}); par(c,"Toca al niño y a la niña.","luis","carmen",[act("saluda",quien="luis")],[act("saluda",quien="carmen")],"gato",fin)
guarda(c,"En el camino","camino","haz",4)

# =============== El campo ===============
# ---- 2. La bola de Canelo ----
c=Cuento("d-bola-canelo","qb")
c.do(act("inicio15"),act("quita",b="carmen"),act("quita",b="cq"),{"wait":600},{"dots":1})
c.say(N("Luis tiene una bola."))
c.say(N("Luis tira la bola."),gap=100); c.do(act("pasa",de="luis",a="carmen",b="luis")); c.say(N("Carmen coge la bola."))
c.do({"dots":2}); c.say(N("Carmen tira la bola para arriba."),gap=100); c.do(act("alta",de="carmen",b="luis")); c.say(N("Coquí salta. ¡Coquí coge la bola!"))
c.do({"dots":3},act("pasa",de="cq",a="luis",b="luis"),act("roba",b="luis")); c.say(N("¡Ay! Canelo tiene la bola de Luis."))
c.say(L("¡Dame la bola, Canelo!"),gap=250); c.do(act("mueverabo")); c.say(N("Canelo no quiere."))
c.do({"dots":4},tw("cesta")); c.say(N("Hay otra bola en la canasta.")); c.do(tw(None),act("nueva",a="carmen")); c.say(N("Carmen tiene la otra bola."))
c.do(act("pasa",de="carmen",a="cq",b="cq"),act("perro",x=168,y=192,modo="run",que="bark",dir=-1)); c.say(N("Ahora Canelo quiere la otra bola.")); c.do(act("salta",quien="perro"),act("salta",quien="perro")); c.say(N("Canelo salta y salta."))
c.do({"dots":5},act("sellevan",quien="luis",b="pila0")); c.say(N("Luis tiene su bola. La bola de Luis."))
c.say(N("Coquí tira la bola."),gap=100); c.do(act("pasa",de="cq",a="carmen",b="cq",alto=40),act("perro",x=176,y=176,modo="run",que="bark",dir=1),act("rien")); c.say(L("¡Corre, Canelo!"),gap=200); c.do(*CORAZON)
guarda(c,"La bola de Canelo","campo","escucha",5)

# ---- B. En el campo ----
c=Cuento("h-campo","rb"); B3=["bola_luis","bola_carmen","bola_cq"]; CSC=["coge","salta","corre"]; TSC=["tira","salta","corre"]
nos(c,{"perro":"ese es Canelo.","bola_luis":"esa es la bola de Luis.","bola_carmen":"esa es la bola de Carmen.","bola_cq":"esa es tu bola."})
c.clips.update({"hz_no_carmen":N("No. Esa es Carmen."),"hz_no_luis":N("No. Ese es Luis.")}); nobur(c,["tira","coge","salta","corre"])
c.do(act("inicio15"),{"set":{"respEn":[112,40]}},{"wait":500})
c.do({"dots":1}); orden(c,None,"bola_luis",B3,[act("saluda",quien="luis",que="arriba")],clip=L("Toca mi bola."),alias={"luis":"bola_luis","carmen":"bola_carmen"})
orden(c,"¿Dónde está Canelo?","perro",["perro","luis","carmen"],[act("ladra",n=1)],alias={"bola_luis":"luis","bola_carmen":"carmen"})   # a touch on the ball in a child's hands is a touch on the child
orden(c,None,"bola_cq",B3,[act("salta",quien="cq",h=6)],clip=CA("Toca tu bola."),alias={"luis":"bola_luis","carmen":"bola_carmen"})
c.do({"dots":2}); orden(c,None,"coge",CSC,[act("pasa",de="luis",a="cq",b="luis")],clip=L("¡Coge la bola!"),resp=True)
c.do({"dots":3}); orden(c,None,"salta",TSC,[act("salta",quien="cq"),act("salta",quien="perro")],clip=CA("¡Salta!"),resp=True)
orden(c,None,"tira",TSC,[act("pasa",de="cq",a="luis",b="luis")],clip=L("¡Tira la bola!"),resp=True)
c.do({"dots":4}); par(c,"Toca tu bola y toca a Carmen.","bola_cq","carmen",[act("salta",quien="cq",h=6)],[act("saluda",quien="carmen")],"perro",fin,alias={"bola_carmen":"carmen"})
guarda(c,"En el campo","campo","haz",4)

# =============== El lago ===============
GL={"luis":{"x":96,"y":118,"pose":"idle","dir":1,"sent":1},"carmen":{"x":42,"y":154,"pose":"idle","dir":1}}
def rana(x,y): return {"x":x,"y":y,"s":1,"dy":0,"al":1,"vis":1,"bub":None}
# ---- 3. Pan para el pato pequeño ----
c=Cuento("d-pato-pequeno","qc")
c.do(act("inicio20"),{"set":{"perro":None,"flor":None,"gente":GL,"bolsa":[58,153],"cq":rana(86,125)}},act("mueven",d=-2),{"wait":600},{"dots":1})
c.say(N("Este es el lago.")); c.say(N("Hay tres patos."))
c.do(tw("pato_blanco")); c.say(N("Un pato blanco.")); c.do(tw("pato_negro")); c.say(N("Un pato negro.")); c.do(tw("pato_amarillo")); c.say(N("Y un pato pequeño.")); c.say(N("¿De qué color es el pato pequeño? Es amarillo.")); c.do(tw(None))
c.do({"dots":2},act("saluda",quien="carmen",que="arriba",ms=500)); c.say(N("Carmen tiene pan."))
c.say(CA("Pan para el pato pequeño."),gap=100); c.do(act("tirapan",x=178,y=184),act("gana",k="blanco")); c.say(N("¡Ay! El pato blanco es rápido. El pato blanco come el pan."))
c.say(CA("Otra vez. Pan para el pato pequeño."),gap=100); c.do(act("tirapan",x=164,y=200),act("gana",k="negro")); c.say(N("¡Ay, no! Ahora el pato negro come el pan."))
c.do({"dots":3},act("cuacp",k="amarillo")); c.say(N("El pato pequeño no tiene pan. Está triste."))
c.say(CA("Toma, Coquí."),gap=200); c.do(act("toma20"))
c.do(act("saluda",quien="carmen",que="arriba",ms=300),act("pose",quien="carmen",que="arriba"),act("patoa",k="blanco",x=104,y=172,dir=-1),act("patoa",k="negro",x=124,y=176,dir=-1)); c.say(N("Carmen tiene más pan. El pato blanco y el pato negro miran a Carmen."))
c.do({"dots":4},act("ranaa",x=104,y=125,h=1)); c.say(N("Coquí va despacio."),gap=100); c.do(act("patoa",k="amarillo",x=152,y=178,dir=-1))
c.say(T("Pan para el pato pequeño."),gap=250); c.do(act("come",a="pato_amarillo",sigue=1)); c.say(N("¡El pato pequeño come el pan!")); c.do(act("traga"),act("pose",quien="carmen",que="idle"))
c.do({"dots":5},act("saluda",quien="luis")); c.say(L("¡Muy bien, Coquí!"),gap=200); c.do(act("cuacp",k="amarillo")); c.say(N("Ahora el pato pequeño está contento.")); c.do(*CORAZON)
guarda(c,"Pan para el pato pequeño","lago","escucha",5)

# ---- C. En el lago ----
c=Cuento("h-lago","rc"); PT=["pato_blanco","pato_negro","pato_amarillo"]; BT=["bote_verde","bote_azul","bote_rojo"]; AN=["pajaro","pez"]+PT
nos(c,{"pato_blanco":"ese es el pato blanco.","pato_negro":"ese es el pato negro.","pato_amarillo":"ese es el pato amarillo.","bote_rojo":"ese es el bote rojo.","bote_azul":"ese es el bote azul.","bote_verde":"ese es el bote verde.","pez":"ese es el pez."})
c.clips.update({"hz_no_pajaro":N("No. Ese es el pájaro.")})
c.do(act("inicio20"),{"set":{"perro":None,"flor":None,"gente":{"luis":GL["luis"],"carmen":{"x":64,"y":118,"pose":"idle","dir":1}},"bolsa":None,"cq":rana(108,125)}},act("mueven",d=-2),act("repone",o="var"),{"wait":500})
c.do({"dots":1}); orden(c,"Toca el pato blanco.","pato_blanco",PT,[act("cuacp",k="blanco")]); orden(c,"¿Cuál es el pato amarillo?","pato_amarillo",PT,[act("cuacp",k="amarillo")])
c.do(act("toma20")); orden(c,None,"pato_blanco",PT,[act("come",a="pato_blanco")],clip=CA("Pan para el pato blanco."))
c.do({"dots":2}); orden(c,"¿Dónde está el bote rojo?","bote_rojo",BT,[act("mecebote",c="rojo")]); orden(c,"Toca el bote verde.","bote_verde",BT,[act("mecebote",c="verde")])
c.do({"dots":3},{"set":{"aves":{"a":{"c":"azul","x":152,"y":122,"dir":-1}},"peces":{"a":{"c":"pardo","x":192,"y":192,"dir":-1,"circula":1}}}},act("sube",quien="pajaro"))
orden(c,"¿Quién vuela?","pajaro",AN,[act("dip")]); orden(c,"¿Dónde está el pez?","pez",AN,[act("pezsalta1")])
c.do({"dots":4}); par(c,"Toca el bote azul y el pato negro.","bote_azul","pato_negro",[act("mecebote",c="azul")],[act("cuacp",k="negro")],"bote_rojo",fin)
guarda(c,"En el lago","lago","haz",4)

# =============== El banco ===============
B=[[96,150],[144,150],[192,150]]; PORTON=[188,197]
def cq(x,y): return {"x":x-16,"y":y-27,"s":1,"dy":0,"al":1,"vis":1,"bub":None,"hace":None}
def cable(*i): return [{"i":k,"x":66+k*17,"y":round(50+7*(1-((66+k*17-120)/98)**2)),"dir":1 if k%2 else -1,"en":"cable"} for k in i]
PIR={"x":51,"y":172,"dir":1}
def per(x,y,**kw): return dict({"x":x,"y":y,"dir":1},**kw)
def sen(i,dx=-9,**kw): return dict({"x":B[i][0]+dx,"y":161,"dir":1,"sent":1},**kw)

# ---- 4. La piragua de Luis ----
c=Cuento("d-piragua-luis","qd")
c.do({"set":{"gente":{"piraguero":PIR,"luis":per(86,190,lleva="piragua"),"carmen":per(62,206,lleva="piragua")},"palomas":cable(2),"cosas":[],"perros":{},"casa":[104,208],"cq":cq(104,208)}},{"wait":600},{"dots":1},tw("piraguero"))
c.say(N("Este es el piragüero.")); c.do(tw(None)); c.say(N("Luis tiene una piragua. Carmen también tiene una piragua."))
c.do({"dots":2},act("anda",quien="luis",x=150,y=186,suelto=1)); c.say(N("Luis corre."),gap=500)
c.do(act("g",quien="luis",lleva="papel"),act("cosa",id="hielo",k="piragua",x=158,y=190,rot=1.5708,son="bonk"),act("g",quien="luis",dir=1,ms=400)); c.say(N("¡Ay, no! La piragua se cae."))
c.do(act("g",quien="luis",animo="triste",ms=300)); c.say(N("Luis está triste."))
c.do({"dots":3},act("anda",quien="carmen",x=124,y=188),act("g",quien="carmen",pose="offer",ms=800)); c.say(CA("Toma, Luis. Toma mi piragua."),gap=250)
c.do(act("g",quien="carmen",pose="idle",lleva=None),act("g",quien="luis",lleva=None,hace="come",que="piragua",animo="contento",dir=-1,ms=500)); c.say(N("Ahora Luis está contento."))
c.do({"dots":4},act("rana",x=78,y=200)); c.say(T("Dos piraguas, por favor."),gap=300)
c.do(act("saluda",quien="piraguero",que="offer",ms=500),act("manos",v={"d":"piragua"}),act("encima",k="piragua"),act("rana",x=104,y=208),act("encima",k=None),act("g",quien="carmen",lleva="piragua",dir=-1,ms=300)); c.say(N("Una piragua para Carmen."))
c.say(CA("¡Gracias, Coquí!"),gap=250); c.do(act("g",quien="carmen",lleva=None,hace="come",que="piragua",animo="contento",ms=400),act("hace",que="come")); c.say(N("Y una piragua para Coquí. Carmen está contenta."))
c.do({"dots":5},act("pal",x=170,y=191,pose="come",dir=-1,z=192)); c.say(N("¿Y el pájaro? El pájaro come.")); c.say(N("El pájaro también está contento."))
c.do(*CORAZON)
guarda(c,"La piragua de Luis","banco","escucha",5)

# ---- 5. Vamos a casa ----
c=Cuento("d-vamos-a-casa","qe")
c.do({"set":{"gente":{"piraguero":PIR,"senor":sen(0),"mujer":sen(1),"abuela":per(76,200),"luis":per(104,204),"carmen":per(126,208)},"palomas":cable(2),"cosas":[],
  "perros":{"canelo":{"x":92,"y":210,"pose":"cansado","dir":1}},"tarde":1,"casa":[44,210],"cq":cq(44,210)}},{"wait":600},{"dots":1},act("luz",v=1,luna=1))
c.say(N("Ahora es de noche.")); c.say(N("¡Mira! La luna."))
c.do({"dots":2},act("anda",quien="senor",x=PORTON[0],y=PORTON[1],lento=1,suelto=1)); c.say(N("El señor camina despacio."),gap=900); c.say(T("¡Adiós, señor!"),gap=300)
c.do(act("saluda",quien="senor",dir=-1),act("anda",quien="senor",x=246,y=PORTON[1],fuera=1))
c.do(act("anda",quien="mujer",x=PORTON[0],y=PORTON[1])); c.say(T("¡Adiós, señora!"),gap=300); c.do(act("saluda",quien="mujer",dir=-1),act("anda",quien="mujer",x=246,y=PORTON[1],fuera=1))
c.do({"dots":3},act("pal",i=0,pose="duerme")); c.say(N("El pájaro duerme."))
c.say(AB("Vamos a casa."),gap=250); c.do(act("anda",quien="luis",x=168,y=196),act("anda",quien="carmen",x=186,y=204),act("g",quien="luis",dir=-1),act("g",quien="carmen",dir=-1))
c.say(AB("¡Ven, Canelo!"),gap=250); c.do(act("can",n="canelo",pose="lie",ms=500),act("can",n="canelo",pose="cansado",ms=300)); c.say(N("Canelo no quiere. Canelo está cansado."))
c.say(L("¡Vamos, Canelo!"),gap=250); c.do(act("can",n="canelo",pose="duerme",zzz=1,ms=400)); c.say(N("Canelo duerme."))
c.do({"dots":4},act("g",quien="abuela",lleva="bola",ms=400)); c.say(N("Abuela tiene una bola."))
c.do(act("g",quien="abuela",lleva=None),act("cosa",id="bola",k="bola",x=118,y=208),act("rebota",id="bola",n=3),act("can",n="canelo",pose="lie",zzz=0,ms=300),act("can",n="canelo",pose="idle",mueve=1),act("brinco",quien="perro",h=6)); c.say(N("¡Mira! Ahora Canelo no está cansado."))
c.do(act("rueda",id="bola",x=240,y=202,n=16,fuera=1,suelto=1),act("can",n="canelo",x=250,y=208,modo="run",vis=0,suelto=1))
c.say(N("Canelo corre rápido."),gap=300); c.do(act("anda",quien="luis",x=246,y=198,fuera=1,suelto=1),act("anda",quien="carmen",x=246,y=204,fuera=1))
c.do({"dots":5},act("anda",quien="abuela",x=PORTON[0],y=PORTON[1]+3,lento=1,suelto=1)); c.say(N("Y abuela camina despacio."),gap=1200); c.do(act("anda",quien="abuela",x=250,y=PORTON[1]+3,fuera=1))
c.say(T("Hasta mañana, parque."),gap=400); c.do(act("sale"),*CORAZON)
guarda(c,"Vamos a casa","banco","escucha",5)

# ---- D. En el banco ----
c=Cuento("h-banco","rd")
nos(c,{"mujer":"esa es la señora.","senor":"ese es el señor.","joven":"ese es el joven.","perro_viejo":"ese es el perro viejo.","perro_joven":"ese es el perro joven."})
G3=["senor","mujer","joven"]; P3=["perro_viejo","perro_joven","joven"]
c.do({"set":{"gente":{"piraguero":PIR,"mujer":sen(0,0,hace="come",que="piragua"),"joven":sen(1,-6,animo="cansado",sin={"mochila":1}),"senor":sen(2,0,hace="bebe")},"palomas":cable(0,1,2,3,4),
  "cosas":[{"id":"mochila","k":"mochila","x":160,"y":150}],"perros":{"viejo":{"x":54,"y":194,"pose":"duerme","dir":1,"zzz":1},"joven":{"x":90,"y":194,"pose":"sit","dir":1}},"casa":[134,206],"cq":cq(134,206)}},{"wait":600})
c.do({"dots":1}); orden(c,"Toca al señor.","senor",G3,[act("saluda",quien="senor")],vale=["piraguero"]); orden(c,"¿Dónde está el joven?","joven",G3,[act("saluda",quien="joven")])
c.do({"dots":2}); orden(c,"¿Quién bebe agua?","senor",G3,[act("saluda",quien="senor",que="arriba")]); orden(c,"¿Quién está cansado?","joven",G3,[act("brinco",quien="joven",h=-2)])
c.do({"dots":3}); orden(c,"¿Quién duerme?","perro_viejo",P3,[act("can",n="viejo",pose="lie",zzz=0,ms=600),act("can",n="viejo",pose="duerme",zzz=1)]); orden(c,"¿Dónde está la señora?","mujer",G3,[act("saluda",quien="mujer")])
c.do({"dots":4}); par(c,"¿Dónde están el perro viejo y la señora?","perro_viejo","mujer",[act("can",n="viejo",pose="lie",zzz=0,ms=600),act("can",n="viejo",pose="duerme",zzz=1)],[act("saluda",quien="mujer")],"perro_joven",fin)
c.clips.update({"c_c_perro":N("Es un perro."),"l_n_pajaro":N("Es un pájaro."),"b_n_banco":N("Es un banco."),"b_n_piraguero":N("Es el piragüero.")})
guarda(c,"En el banco","banco","haz",4,names={"coqui":"yo_coqui","perro_viejo":"c_c_perro","perro_joven":"c_c_perro","pajaro":"l_n_pajaro","banco0":"b_n_banco","banco1":"b_n_banco","banco2":"b_n_banco","piraguero":"b_n_piraguero","carro":"b_n_piraguero"})

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
