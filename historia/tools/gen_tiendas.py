# Las tiendas (place 5, La calle, scene 3): stories 54, 55, 56. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/tiendas.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `tiendas` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir).
# Values of act arguments that the script names in words but not as keys (the pictures on the list card, what comes out of a door, the hour, the two sides) are the script's own words:
#   lista k: letter, purse, bottle (54), bag, umbrella (56); va54 trae: letter, purse, bag, plasters, envelope, parcel, and lollipop, pencil, top in a wrong place;
#   puerta56 trae: stamp, bag, umbrella, with quien (abuela pushes the doors of the opening, the frog those of the game); hora: manana, mediodia, tarde; lado: left, right.
# Run order for the stories of La calle: the generators of stories 48 to 53 first (each sees only what was recorded before it), then this one.
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); L=lambda t:D("luis","Luis",t); MA=lambda t:D("mama","Mamá",t); PAP=lambda t:D("papa","Papá",t); SA=lambda t:D("senora","La señora",t); SE=lambda t:D("senor","El señor",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's twinkle on a thing he can touch
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story of this place has two scored rounds: the card shows two places
# earlier stories' focus words that a speaking turn may use and that are not on disk here: stories 48 to 53 (La esquina, La parada), from the order of the course
FOCUS_48_53=["calle","carro","guagua","bicicleta","esquina","gente","cruza","pasa","viene","va","ahora","luego","parada","¿adónde vas?","voy","vas","sube","baja","llega","sale","cerca","lejos","temprano","tarde"]
MINE=("las-tiendas","el-edificio-alto","abierto-y-cerrado")   # this generator's stories: not seen
# a clip whose text and speaker are already recorded under another id keeps that id (nothing is recorded twice); the stories of this run feed it too, in order.
# Ties go to the id most used, then to the earliest story of the course.
ORD={}
for i,s in enumerate(re.findall(r'"([a-z0-9-]+)"',"".join(re.findall(r'cuentos:\[(.*?)\]',open("curso.js",encoding="utf-8").read(),re.S)))): ORD.setdefault(s,i)
EX=collections.defaultdict(dict)   # (who, habla, text) -> {clip id: [stories that have it, first place in the course]}
def ex_add(cid,cl,o=9999):
    e=EX[(cl.get("who"),cl.get("habla"),cl["text"])].setdefault(cid,[0,o]); e[0]+=1; e[1]=min(e[1],o)
for f in sorted(glob.glob("cuentos/*.json")):
    nm=os.path.basename(f)[:-5]
    if nm in MINE or nm.startswith("z"): continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items(): ex_add(cid,cl,ORD.get(nm,9999))
def best(k): return min(EX[k],key=lambda cid:(-EX[k][cid][0],EX[k][cid][1],cid))
DIN=set()   # ids that are put together in the story ("c54_a_$pa"): never renamed
def reuse(st,turnos):
    ren={}
    for cid,cl in list(st["clips"].items()):
        if "$" in cid or cid in DIN: continue
        k=(cl.get("who"),cl.get("habla"),cl["text"])
        if k in EX and EX[k]:
            b=best(k)
            if b!=cid: ren[cid]=b
    def fx(o):
        if isinstance(o,str): return ren.get(o,o)
        if isinstance(o,list): return [fx(x) for x in o]
        if isinstance(o,dict): return {fx(k) if k in ren else k:fx(v) for k,v in o.items()}
        return o
    out=fx(st)
    # Speaking turns, put on the clip once its id is settled. A turn whose clip is not in the story, or is never played in it, is reported (MISSING TURN LINE) and not made up.
    def strs(o):
        if isinstance(o,str): yield o
        elif isinstance(o,list):
            for x in o: yield from strs(x)
        elif isinstance(o,dict):
            for x in o.values(): yield from strs(x)
    played=set(strs([out["beats"],out["final"]]))
    for cid,t in turnos.items():
        cid=ren.get(cid,cid)
        if cid in out["clips"] and cid in played: out["clips"][cid]["tu_turno"]=t
        else: print("MISSING TURN LINE",out["id"],cid)
    for cid,cl in out["clips"].items(): ex_add(cid,cl)
    return out
TG=lambda *p:[{"palabra":w,"formas":list(f)} for w,f in p]
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!")}
# the free poke: the lines of the people who are already recorded (the new things add nothing)
NM={"abuela":("abuela",N("Esta es abuela.")),"bebe":("n_bebe",N("Este es el bebé.")),"luis":("p_n_luis",N("Este es Luis.")),"mama":("esta_es_mama",N("Esta es mamá.")),"papa":("n_papa",N("Este es papá.")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora.")),"coqui":("yo_coqui",T("¡Coquí!"))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}

# ---------------- 54. Las tiendas ----------------
# Round A: one of the banco, the farmacia and the correo (drawn); round B: one of the two that are left (drawn). The four fronts can all be touched.
nm,nc=nombres("abuela","bebe","coqui"); c=dict(comunes); c.update(nc)
c.update({"c54_calle":N("Abuela, el bebé y Coquí están en la calle de las tiendas."),"c54_mira":N("Mira. Aquí, en la tienda, hay un caballito."),
 "c54_ab_gusta":AB("¿Te gusta el caballito, Coquí?"),"c54_cq_gusta":T("¡Sí, me gusta!"),"c54_ab_luego":AB("Luego, Coquí. Ahora tengo tres cosas que hacer."),
 "c54_ab_carta":AB("Tengo una carta. ¿Dónde está el correo?"),"c54_donde_correo":N("¿Dónde está el correo?"),"c54_ab_aqui_correo":AB("¡Aquí está el correo!"),
 "c54_ab_chavos":AB("Ahora necesito chavos. Vamos al banco."),"c54_donde_banco":N("¿Dónde está el banco?"),
 "c54_ab_farmacia":AB("Y abuelo necesita algo de la farmacia."),"c54_donde_farmacia":N("¿Dónde está la farmacia?"),"c54_ab_listo":AB("El correo, el banco, la farmacia... ¡Listo!"),
 "c54_ab_ay":AB("¡Ay! Mamá necesita dos cosas más."),
 "c54_ab_ahora_si":AB("Ahora sí. ¡Vamos al caballito de la tienda, Coquí!"),"c54_cq_gracias":T("¡Gracias, abuela!"),"c54_ab_casa":AB("¡Qué día, Coquí! Vamos a casa.")})
# the three places the game can name: the line of round A, the line of round B, and the correction (the place that was named: "Esta no es la farmacia"; el banco and el correo are masculine)
for p,(al,art,este) in {"banco":("al banco","el banco","Este"),"farmacia":("a la farmacia","la farmacia","Esta"),"correo":("al correo","el correo","Este")}.items():
    c["c54_a_"+p]=AB("Ahora vamos %s."%al); c["c54_b_"+p]=AB("Y ahora, %s."%al); c["c54_no_"+p]=AB("No, Coquí. %s no es %s."%(este,art))
    DIN.update(["c54_a_"+p,"c54_b_"+p,"c54_no_"+p])
def ronda54(p,t,ln):
    # p: the place named; t: what that place gives (a box of plasters, an envelope, a parcel); the bebé takes a lollipop in the farmacia, a top in the tienda, a pencil in the banco or the correo.
    # Right: they go in at that door and come out with the thing. Wrong: they go in at the door he touched, the bebé will not let go of what he took, abuela pays a coin; then the sign shows the right front.
    return [{"calc":t,"cond":p+"=farmacia","then":"plasters","else":"parcel"},{"calc":t,"cond":p+"=banco","then":"envelope","else":"$"+t},
     {"decide":"do","options":["tienda","banco","farmacia","correo"],"pick":"$"+p,"tests":"$"+p,"lock":True,"lead":[],"line":"c54_%s_$%s"%(ln,p),
      "right":[act("va54",a="$"+p,ok=1,trae="$"+t),{"if":"ok","then":[OK]}],
      "wrong":[{"calc":"toma","cond":"x=farmacia","then":"lollipop","else":"pencil"},{"calc":"toma","cond":"x=tienda","then":"top","else":"$toma"},
               act("va54",a="$x",ok=0,trae="$toma"),gesto("abuela","no")]+X+["c54_no_$"+p]}]
s54={"id":"las-tiendas","title":"Las tiendas","place":"La calle","scene":"tiendas","next":"el-edificio-alto",
 "goal":"Take abuela through her three errands and keep her coins, so the frog and the bebé can ride the little horse in front of the tienda.","stake":{"thing":"monedas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["tienda","banco","farmacia","correo"],"formas_foco":{"tienda":["tiendas"]},
 "back_again":["calle","abuela","abuelo","bebé","mamá","necesito","chavos","me gusta","tengo","cosa","dos","tres","ahora","luego","vamos","aquí","gracias","casa","listo"],
 "also_heard":["caballito","carta"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"fila":"tiendas","hora":"manana"}},act("lista"),{"wait":500},
  # 1: the street, the little horse; a speaking turn; the three coins
  {"dots":1},"c54_calle",tw("tienda"),gesto("bebe","senala",a="caballito"),"c54_mira",tw(None),"c54_ab_gusta","c54_cq_gusta",act("monedas",n=3),"c54_ab_luego",
  # 2 to 4: three signed asks (the correo, the banco, the farmacia); each errand lights on the card, then gets its tick
  {"dots":2},act("lista",k="letter",hecho=0),
  ask("correo","c54_donde_correo",lead=["c54_ab_carta"],after=[act("va54",a="correo",ok=1,trae="letter")],then=["c54_ab_aqui_correo",act("lista",k="letter",hecho=1)]),
  {"dots":3},act("lista",k="purse",hecho=0),
  ask("banco","c54_donde_banco",lead=["c54_ab_chavos"],after=[act("va54",a="banco",ok=1,trae="purse")],then=[act("lista",k="purse",hecho=1)]),
  {"dots":4},act("lista",k="bottle",hecho=0),
  ask("farmacia","c54_donde_farmacia",lead=["c54_ab_farmacia"],after=[act("va54",a="farmacia",ok=1,trae="bag")],then=[act("lista",k="bottle",hecho=1),act("cuenta54"),"c54_ab_listo"]),
  # 5: the turn: abuela's telephone; the card shows two places
  {"dots":5},act("telefono"),CARD,"c54_ab_ay",gesto("abuela","mira",a="caballito"),gesto("abuela","mira",a="coqui"),{"wait":400},
  # A: one of the three places (drawn). B: one of the two that are left (drawn)
  {"dots":6},{"draw":"pa","options":["banco","farmacia","correo"]}]+ronda54("pa","ta","a")+[{"dots":7},
  {"draw":"eb","options":["u","v"]},
  {"if":"pa=banco","then":[{"calc":"pb","cond":"eb=u","then":"farmacia","else":"correo"}],
   "else":[{"if":"pa=farmacia","then":[{"calc":"pb","cond":"eb=u","then":"banco","else":"correo"}],"else":[{"calc":"pb","cond":"eb=u","then":"banco","else":"farmacia"}]}]}]+ronda54("pb","tb","b"),
 "final":[{"dots":8},act("ir",a="caballito"),   # 8: they stop at the horse; abuela takes out the coins that are left (nn); the frog's thanks; the ride, by the coins left
  {"calc":"nn","cond":"lost=0","then":"3","else":"1"},{"calc":"nn","cond":"lost=1","then":"2","else":"$nn"},act("monedas",n="$nn"),"c54_ab_ahora_si","c54_cq_gracias",
  {"if":"lost=0","then":[act("caballito54",n=3)],"else":[{"if":"lost=1","then":[act("caballito54",n=2)],"else":[act("caballito54",n=1)]}]},
  "c54_ab_casa",act("fin")],
 "leer":["c54_calle","c54_mira","c54_ab_gusta","c54_cq_gusta","c54_ab_luego","c54_ab_carta","c54_donde_correo","c54_ab_aqui_correo","c54_ab_chavos","c54_donde_banco","c54_ab_farmacia","c54_donde_farmacia","c54_ab_listo","c54_ab_ay",
  "c54_a_farmacia","c54_b_correo","c54_ab_ahora_si","c54_cq_gracias","c54_ab_casa"]}
s54=reuse(s54,{"c54_cq_gusta":TG(("me gusta",["me gusta"])),"c54_cq_gracias":TG(("gracias",["gracias"]))})
json.dump(s54,open("cuentos/las-tiendas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 55. El edificio alto ----------------
# Two pairs of buildings (par a for the opening and round A, par b for round B): a tall old one and a low new one, which side each is on drawn per pair. The word said (alto or nuevo) is drawn each round on its own.
nm,nc=nombres("luis","mama","papa","senor","senora","coqui"); c=dict(comunes); c.update(nc)
c.update({"c55_van":N("Luis y Coquí van por la calle en bicicleta."),"c55_comida":N("Esta es la comida de abuela. Es para mamá y papá. Está caliente."),
 "c55_mira_alto":N("Mira este edificio. Es un edificio alto."),"c55_donde_alto":N("¿Dónde está el edificio alto?"),"c55_luis_alto":L("¡Qué alto!"),
 "c55_es_nuevo":N("Y este edificio es nuevo."),"c55_donde_nuevo":N("¿Dónde está el edificio nuevo?"),"c55_luis_nuevo":L("¡Este es nuevo!"),
 "c55_senor_hola":SE("¡Hola! ¿La comida es para ti, Coquí?"),"c55_cq_mama":T("¡No! Para mamá y papá."),
 "c55_luis_trabaja":L("Mamá trabaja en el hospital. Papá trabaja en la escuela. Pero ¿dónde está el hospital?"),
 "c55_mama_gracias":MA("¡Mi comida! ¡Gracias!"),"c55_ahora_escuela":N("Ahora van a la calle de la escuela."),"c55_papa_gracias":PAP("¡Qué rico! ¡Gracias!"),
 "c55_luis_hambre":L("¿Tienes hambre, Coquí?"),"c55_cq_hambre":T("¡Sí! Tengo hambre."),
 "c55_come3":L("¡El arroz está caliente! ¡Qué rico!"),"c55_come2":L("¡Qué rico!"),"c55_come1":L("El arroz está un poco frío. Pero está rico."),"c55_casa":N("Luis y Coquí van a casa en bicicleta.")})
for w in ("alto","nuevo"):   # the word said, and the correction that repeats it; round A is the señor's (the hospital), round B the señora's (the escuela)
    c["c55_hosp_"+w]=SE("El hospital es el edificio %s."%w); c["c55_no_hosp_"+w]=SE("No. El hospital es el edificio %s."%w)
    c["c55_no_esc_"+w]=SA("No. La escuela es el edificio %s."%w)
    DIN.update(["c55_hosp_"+w,"c55_no_hosp_"+w,"c55_no_esc_"+w])
c["c55_esc_nuevo"]=SA("¿La escuela? La escuela es el edificio nuevo."); c["c55_esc_alto"]=SA("La escuela es el edificio alto."); DIN.update(["c55_esc_nuevo","c55_esc_alto"])
def lado55(v):   # which side the tall building is on in this pair: drawn (the state `lado`)
    return [{"draw":v,"options":["left","right"]},{"if":v+"=left","then":[{"set":{"lado":"left"}}],"else":[{"set":{"lado":"right"}}]}]
def ronda55(w,quien,ln,gracias):
    # w: the word said (alto or nuevo), drawn. He touches the building it names. Right: the parent comes to the door, hangs the sign, takes the tin.
    # Wrong: they run in at the other door; a head at a window sends them back; one wisp is gone from every tin (before the cross).
    return [{"draw":w,"options":["alto","nuevo"]},
     {"decide":"do","options":["alto","nuevo"],"pick":"$"+w,"tests":"$"+w,"lock":True,"lead":[],"line":"c55_%s_$%s"%(ln,w),
      "right":[act("entra55",a="$"+w,ok=1,quien=quien),gracias,{"if":"ok","then":[OK]}],
      "wrong":[act("entra55",a="$x",ok=0),{"if":"lost=0","then":[act("vapor",n=2)],"else":[act("vapor",n=1)]}]+X+["c55_no_%s_$%s"%(ln,w)]}]
s55={"id":"el-edificio-alto","title":"El edificio alto","place":"La calle","scene":"tiendas","next":"abierto-y-cerrado",
 "goal":"Carry the three hot lunch tins to the right buildings without letting them cool, so Luis and the frog can eat theirs hot.","stake":{"thing":"vapor","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["edificio","alto","nuevo","escuela","hospital"],"formas_foco":{},
 "back_again":["calle","bicicleta","va","mamá","papá","comida","caliente","frío","arroz","rico","un poco","tengo hambre","gracias","también","no","para","este","ahora"],
 "also_heard":["trabaja"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"fila":"altos","par":"a","hora":"mediodia"}}]+lado55("la")+[{"wait":500},
  # 1: the tins and their steam
  {"dots":1},"c55_van",tw("comida"),act("vapor",n=3),"c55_comida",tw(None),
  # 2 and 3: two signed asks (the tall one, the new one)
  {"dots":2},tw("alto"),"c55_mira_alto",tw(None),ask("alto","c55_donde_alto",after=[act("ventana55"),act("cuenta55",a="alto")],then=["c55_luis_alto"]),
  {"dots":3},tw("nuevo"),"c55_es_nuevo",tw(None),ask("nuevo","c55_donde_nuevo",after=[act("pintor55"),act("cuenta55",a="nuevo")],then=["c55_luis_nuevo"]),
  # 4: the señor and a speaking turn
  {"dots":4},gesto("senor","mira",a="comida"),"c55_senor_hola","c55_cq_mama",
  # 5: the turn: Luis's paper with a red cross and a bell; the card shows two places
  {"dots":5},gesto("luis","papel"),"c55_luis_trabaja",CARD,{"wait":400},
  # A: the señor says which is the hospital (alto or nuevo, drawn). 7: they ride on to the second pair; B: the señora says which is the escuela (drawn on its own)
  {"dots":6}]+ronda55("da","mama","hosp","c55_mama_gracias")
  +[{"dots":7}]+con(act("otra55"),"c55_ahora_escuela")+lado55("lb")
  +[{"draw":"db","options":["alto","nuevo"]},{"calc":"lc","cond":"db=nuevo","then":"c55_esc_nuevo","else":"c55_esc_alto"},
    {"decide":"do","options":["alto","nuevo"],"pick":"$db","tests":"$db","lock":True,"lead":[],"line":"$lc",
     "right":[act("entra55",a="$db",ok=1,quien="papa"),"c55_papa_gracias",{"if":"ok","then":[OK]}],
     "wrong":[act("entra55",a="$x",ok=0),{"if":"lost=0","then":[act("vapor",n=2)],"else":[act("vapor",n=1)]}]+X+["c55_no_esc_$db"]}],
 "final":[{"dots":8},act("ir",a="bordillo"),gesto("luis","sienta"),"c55_luis_hambre","c55_cq_hambre",   # 8: one tin is left; they sit on the kerb; what is eaten, by the wisps left
  {"if":"lost=0","then":[act("come55",n=3),"c55_come3"],"else":[{"if":"lost=1","then":[act("come55",n=2),"c55_come2"],"else":[act("come55",n=1),"c55_come1"]}]},
  act("ir",a="bici"),"c55_casa",act("fin")],
 "leer":["c55_van","c55_comida","c55_mira_alto","c55_donde_alto","c55_luis_alto","c55_es_nuevo","c55_donde_nuevo","c55_luis_nuevo","c55_senor_hola","c55_cq_mama","c55_luis_trabaja","c55_hosp_alto","c55_mama_gracias",
  "c55_ahora_escuela","c55_esc_nuevo","c55_papa_gracias","c55_luis_hambre","c55_cq_hambre","c55_come3","c55_casa"]}
s55=reuse(s55,{"c55_cq_mama":TG(("mamá",["mamá","mama"])),"c55_cq_hambre":TG(("tengo hambre",["tengo hambre"]))})
json.dump(s55,open("cuentos/el-edificio-alto.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 56. Abierto y cerrado ----------------
# Each round: two of the tienda, the banco and the farmacia; the señora says which is open now and which is shut. Which is open, which is shut and which half of her line comes first are drawn each round on its own.
# The third front (the correo is never named) can be touched too: it is not an option, so it is only a free poke (it rattles, the scene's own).
nm,nc=nombres("abuela","senora","coqui"); c=dict(comunes); c.update(nc)
c.update({"c56_calle":N("Abuela y Coquí están en la calle de las tiendas."),"c56_ab_rapido":AB("¡Rápido, Coquí! ¡Ahí viene la lluvia!"),
 "c56_correo_abierto":N("El correo está abierto."),"c56_por_donde_abuela":N("¿Por dónde entra abuela?"),
 "c56_banco_cerrado":N("El banco está cerrado. Abuela no entra."),"c56_toca_banco":N("Toca la puerta del banco."),"c56_esta_cerrado":N("Está cerrado."),
 "c56_senora_tienda":SA("¡Buenas tardes! La tienda está abierta. Pero el banco está cerrado. Mira, Coquí. ¿Te gusta?"),"c56_cq_gusta":T("¡Sí, me gusta!"),
 "c56_ab_entra":AB("Coquí, entra tú. Busca una puerta abierta. Yo espero aquí con el pan."),
 "c56_ab_bolsa":AB("Necesito una bolsa para el pan."),"c56_ab_sombrilla":AB("Y necesito una sombrilla."),"c56_por_donde_coqui":N("¿Por dónde entra Coquí?"),
 "c56_ab_todo":AB("¡Gracias, Coquí! ¿Tienes todo?"),"c56_cq_todo":T("¡Sí, todo!"),"c56_casa":N("Abuela y Coquí van a casa. ¡Adiós, lluvia!")})
FR={"tienda":("la","La","abierta","cerrada"),"banco":("el","El","abierto","cerrado"),"farmacia":("la","La","abierta","cerrada")}   # the front, its article (small, capital), open, shut
for ab in FR:
    for ce in FR:
        if ab==ce: continue
        a1,A1,o1,_=FR[ab]; a2,A2,_,c2=FR[ce]
        c["c56_s_%s_%s_ab"%(ab,ce)]=SA("Ahora %s %s está %s. %s %s está %s."%(a1,ab,o1,A2,ce,c2))      # the open one first
        c["c56_s_%s_%s_ce"%(ab,ce)]=SA("Ahora %s %s está %s. %s %s está %s."%(a2,ce,c2,A1,ab,o1))      # the shut one first
        c["c56_no_%s_%s"%(ab,ce)]=SA("No, Coquí. %s %s está %s. %s %s está %s."%(A2,ce,c2,A1,ab,o1))     # the correction: the one he pushed is shut, the other is open
        DIN.update(["c56_s_%s_%s_ab"%(ab,ce),"c56_s_%s_%s_ce"%(ab,ce),"c56_no_%s_%s"%(ab,ce)])
def ronda56(s,tarjeta,necesito,hecho_k):
    # s: the round's suffix. o: the open front, c: the shut front (both drawn from the tienda, the banco and the farmacia), q: which half of the señora's line comes first (ab: the open one)
    o,e,k,q="o"+s,"e"+s,"c"+s,"q"+s
    return [{"draw":o,"options":["tienda","banco","farmacia"]},{"draw":e,"options":["u","v"]},
     {"if":o+"=tienda","then":[{"calc":k,"cond":e+"=u","then":"banco","else":"farmacia"}],
      "else":[{"if":o+"=banco","then":[{"calc":k,"cond":e+"=u","then":"tienda","else":"farmacia"}],"else":[{"calc":k,"cond":e+"=u","then":"tienda","else":"banco"}]}]},
     {"draw":q,"options":["ab","ce"]},
     {"decide":"do","options":["$"+o,"$"+k],"pick":"$"+o,"tests":"abierto","lock":True,"mudo":True,
      "lead":[act("lista",k=hecho_k,hecho=0),necesito,"c56_s_$%s_$%s_$%s"%(o,k,q),"c56_por_donde_coqui"],"line":"c56_s_$%s_$%s_$%s"%(o,k,q),
      "right":[act("puerta56",k="$"+o,ok=1,trae=hecho_k,quien="coqui"),{"if":"ok","then":[OK]},act("lista",k=hecho_k,hecho=1)],
      "wrong":[act("puerta56",k="$x",ok=0,quien="coqui"),{"if":"lost=0","then":[act("nube",n=1)],"else":[act("nube",n=2)]}]+X+["c56_no_$%s_$%s"%(o,k)]}]
s56={"id":"abierto-y-cerrado","title":"Abierto y cerrado","place":"La calle","scene":"tiendas","next":"izquierda-o-derecha",
 "goal":"Get a bag for the bread and an umbrella from whichever shop is open, before the rain comes.","stake":{"thing":"nube","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["abierto","cerrado","entra"],"formas_foco":{"abierto":["abierta"],"cerrado":["cerrada"]},
 "back_again":["tienda","banco","farmacia","correo","calle","puerta","lluvia","necesito","bolsa","pan","busca","todo","me gusta","rápido","espera","aquí","ahora","gracias","casa","viene","adiós"],
 "also_heard":["sombrilla"],"names":nm,"palabras":{},"clips":c,
 "beats":[{"set":{"fila":"tiendas","hora":"tarde","nube":0}},{"wait":500},
  # 1: the street, the cloud at the edge
  {"dots":1},"c56_calle",gesto("abuela","mira",a="nube"),"c56_ab_rapido",
  # 2 and 3: the correo's door opens; the banco's door does not (two signed asks)
  {"dots":2},"c56_correo_abierto",ask("correo","c56_por_donde_abuela",after=[act("puerta56",k="correo",ok=1,trae="stamp",quien="abuela")]),
  {"dots":3},act("puerta56",k="banco",ok=0,quien="abuela"),"c56_banco_cerrado",ask("banco","c56_toca_banco",after=[act("puerta56",k="banco",ok=0,quien="coqui")],then=["c56_esta_cerrado"]),
  # 4: the señora and the kite; a speaking turn
  {"dots":4},"c56_senora_tienda",gesto("senora","cometa"),"c56_cq_gusta",
  # 5: the turn: the bell, every door is pulled shut; abuela sits down; the card shows two places
  {"dots":5},act("cierran56"),gesto("abuela","sienta"),"c56_ab_entra",CARD,{"wait":400},
  # A: the bag. B: the umbrella. Each drawn afresh
  {"dots":6}]+ronda56("a","bolsa","c56_ab_bolsa","bag")+[{"dots":7}]+ronda56("b","sombrilla","c56_ab_sombrilla","umbrella"),
 "final":[{"dots":8},act("ir",a="banco_acera"),"c56_ab_todo","c56_cq_todo",   # 8: the frog is back with the umbrella; the ending by the steps of the dry time that were lost
  {"if":"lost=0","then":[act("final56",n=0)],"else":[{"if":"lost=1","then":[act("final56",n=1)],"else":[act("final56",n=2),gesto("coqui","baila")]}]},
  "c56_casa",act("fin")],
 "leer":["c56_calle","c56_ab_rapido","c56_correo_abierto","c56_por_donde_abuela","c56_banco_cerrado","c56_toca_banco","c56_esta_cerrado","c56_senora_tienda","c56_cq_gusta","c56_ab_entra","c56_ab_bolsa","c56_s_farmacia_tienda_ab","c56_por_donde_coqui",
  "c56_ab_sombrilla","c56_s_banco_farmacia_ab","c56_ab_todo","c56_cq_todo","c56_casa"]}
s56=reuse(s56,{"c56_cq_gusta":TG(("me gusta",["me gusta"])),"c56_cq_todo":TG(("todo",["todo"]))})
json.dump(s56,open("cuentos/abierto-y-cerrado.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# clip ids are global: the same id must have the same text everywhere
seen={}; clash=0; new=0; chars=0
for f in sorted(glob.glob("cuentos/*.json")):
    if "zz-" in f or "/z" in f: continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items():
        key=(cl.get("who"),cl.get("text"))
        if cid in seen and seen[cid]!=key: print("CLASH",cid,seen[cid],key,f); clash+=1
        seen.setdefault(cid,key)
for cid,(who,text) in seen.items():
    if not os.path.exists(f"audio/{cid}.mp3"): new+=1; chars+=len(text)
print(len(seen),"clips,",new,"new,",chars,"characters to record,",clash,"clashes")
# every id the steps name (with no variable in it) is in the story's clips; every `leer` id too; every speaking turn is on a word of an earlier story
earlier=set(FOCUS_48_53)
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s54,s55,s56):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:54|55|56)_|si_|yo_|p_n_|b_n_|n_|esta_|cq_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
