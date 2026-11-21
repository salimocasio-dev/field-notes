# La muralla, de noche (place 10, El fuerte, scene 4 of 4): stories 117, 118, 119. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/muralla.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `muralla` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: the generators of places 4 to 9 first (each sees only what was recorded before it), then the four of El fuerte (subida, musica, regalos, this one); musica in order (112 before 113).
#   Speaking turns of this scene: 117 aquí, tres; 118 no, feliz; 119 hasta luego, adiós. All are words of places 1 to 9 (las-flores, uno-dos-tres, el-bizcocho, buenas-noches of La fonda, donde-esta-el-pajaro)
#   EXCEPT `feliz`, a word new in story 113 (que-bueno, scene musica: written by another builder, not on disk when this one runs alone). The check at the end treats exactly that one as known
#   (KNOWN_ELSEWHERE) while that file is not on disk, and prints a NOTE; once it is on disk the check is strict.
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   117  DOORS: the door he names and what is behind it are drawn apart: `ha` = the box with somebody in it (roja, azul), `na` = the door Luis names (roja, azul), `sa` = what he says: alguien when the two are the same, nadie when not.
#        The right door is `da` (puerta_roja or puerta_azul: the box with somebody). The four sentences (2 doors x alguien, nadie) are clips, and the four corrections ("¡No, Coquí! " + the same sentence). Each round draws on its own.
#        WHO IS GONE: the script says "one person" / "somebody else" and the Needs list says "who is gone" is a value: dealt out (`reparte`) of the five guests, none twice (pa, pb). Reported.
#        The gust (`viento117`) takes the person (quien) and the box he is in (donde = the thing key of the box); the script's Needs gives {quien} only. Reported. The gust of round A is step 5 (the turn), round B's is step 7 (as the script).
#        `abre117` {cual, ok}: cual = the thing key of the door (puerta_roja, puerta_azul); a wrong touch is `$x`, the empty box. `faroles` {n}: 3 at the start, 2 / 1 after a loss (resta); `final117` {n} and `foto117` {n} = what is left.
#        Start spots (the script names none for the group): abuelo centro1, Luis centro2, don Pepe centro3, la maestra centro4, el piragüero centro5, el señor centro6, la señora centro7 (the eight places of the Needs list: Carmen
#        takes the eighth when she comes out); Carmen is inside the red box from the start (`llega` dentro_roja: the script's step 2 finds her there). Abuela camara_abuela, the frog junto_camara.
#   118  Start spots: the músicos on the bench (banco1 with the hat, banco2); abuelo leans on the parapet (muro1); abuela baile1 and Carmen baile2 dance; Luis stands apart (muro2); don Pepe comes to muro2 when Luis has gone to dance (step 3);
#        abuelo dances at baile3 (step 4); the maestra and the piragüero come to the parapet at the turn (muro1, muro2). Where the others dance after drinking, eating or sitting is the act's own (`trae118`).
#        GAME: the maestra is round A's guest and the piragüero round B's (the script names them). Their reasons are dealt out (`reparte`, none twice): sed, hambre, cansado (ra, rb). Each reason has its thing: jugo, plato, silla (ta, tb).
#        Round B has the two things round A did not use: oa, ob (the script: "a thing that has been used stays with the one who used it"). The corrections of the script's example ("No, Coquí. Tengo sed.") are written for the other
#        reasons by the same pattern ("Tengo hambre.", "Estoy cansada." for the maestra; "Estoy cansado." for the piragüero). `aros` {n}: 3 at the start, 2 / 1 after a loss, 0 when the candle goes out (step 9). Reported.
#   119  Start spots: abuela escalera_abuela, abuelo escalera_abuelo, the four guests on the bench (don Pepe banco1, la señora banco2, el señor banco3, la maestra banco4: the order the script names them in). The músicos and Luis and
#        Carmen have no spot at the start (the script names none): the músicos `llega` to escalera1 when they come to the steps (steps 1, 2) and then to `baja`; Luis and Carmen come to the parapet only at the end (pretil3, pretil4).
#        GUESTS: dealt out (`reparte`, none twice) of don Pepe, la señora, el señor, la maestra (ga, gb); each has his thing: don Pepe la caja, la señora la bolsa, el señor el sombrero, la maestra el libro (ta, tb).
#        Round B has the three things round A did not use: oa, ob, oc (the script: "round A's thing has gone"). The thing is the word that decides: `tests` = the thing's key (caja, bolsa, sombrero, libro).
#        STAKE: 4 windows. `caras` {n}: 0 at the start; `entrega119` with ok 1 shows the face by itself; a miss costs the cross and one step (X) and no face: the guest is on the bench. `final119` {n} = the faces
#        in the windows at the end: 4 - lost (4, 3, 2). The horn of the script's step 7 is `bocina119`, run just before `final119` (the order of the two is the script's "go down. The horn; the guagua goes off" in two acts). Reported.
#        The right line ("¡Gracias! ¡Nos vemos!") runs in time with `entrega119` (`con`); after a miss the sign's touch runs `banco119` and no line (the script gives none).
#   `gesto` targets the script does not name: 117 step 4 abuela looks about her feet (mira a = junto_camara, the spot beside her camera where the frog stands).
#   Every story sets its own states at the start (hora noche; 119: tarde_noche): every story starts fresh.
import json,glob,os,re,collections,unicodedata
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); ABO=lambda t:D("abuelo","Abuelo",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
MU1=lambda t:D("musico1","El músico",t); MU2=lambda t:D("musico2","El otro músico",t); DP=lambda t:D("don_pepe","Don Pepe",t); MAE=lambda t:D("maestra","La maestra",t)
PI=lambda t:D("piraguero","El piragüero",t); GE=lambda t:D("gente","La gente",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time (people walking in together): all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
def START(hora="noche"): return {"set":{"hora":hora}}    # every story starts fresh
MINE=("todos-en-la-foto","por-que-no-bailas","nos-vemos")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c117_l_$na_$sa"): never renamed
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
def noacc(s): return "".join(ch for ch in unicodedata.normalize("NFD",s) if unicodedata.category(ch)!="Mn")
def TG(*p):
    # the script's bracketed forms, and each one again without its accent (lower case, no punctuation)
    out=[]
    for w,f in p:
        fs=[]
        for x in f:
            for y in (x,noacc(x)):
                if y not in fs: fs.append(y)
        out.append({"palabra":w,"formas":fs})
    return out
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}
# What he hears when he pokes a person already recorded (the maestra, don Pepe and the músicos have no poke line in the script or in an earlier story: nothing is made up for them)
NM={"abuela":("abuela",N("Esta es abuela.")),"abuelo":("n_abuelo",N("Este es abuelo.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora.")),"piraguero":("b_n_piraguero",N("Es el piragüero."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def baja4(n):
    # the same for 4 steps (119: four windows): 4 faces when nothing was lost, 3 after one miss, 2 after two
    return {"if":"lost=0","then":[n(4)],"else":[{"if":"lost=1","then":[n(3)],"else":[n(2)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}

# ---------------- 117. Todos en la foto ----------------
# Abuela's camera faces the middle of the walk. Somebody is gone from the group in each round (dealt out of the five guests, none twice) and hides in one of the two sentry boxes, the other is empty (drawn). Luis, back beside the frog with his eyes on abuela,
# says what is behind one door ("Detrás de la puerta roja, nadie."; the door he names is drawn on its own). Decision A and B: touch a door (the red, the blue; tests alguien against nadie).
# A miss: the empty box opens, the sleeping pigeons burst out and knock a lantern off the line (it goes out), "¡No, Coquí! ...", the cross; the sign is on the other door: somebody comes out to the others and the pigeons settle.
nm,nc=nombres("abuela","abuelo","luis","carmen","senor","senora","piraguero","coqui"); c=dict(comunes); c.update(nc)
c.update({"c117_ab_foto":AB("¡Una foto! ¡Todos aquí, por favor!"),"c117_ab_faltan":AB("Uno, dos, tres... No están todos. Falta alguien."),"c117_l_shh":L("¡Shh! Detrás de la puerta roja hay alguien."),
 "c117_ca_aqui_estoy":CA("¡Aquí estoy!"),"c117_ab_azul":AB("¿Y detrás de la puerta azul? ¿Hay alguien?"),"c117_l_no_nadie":L("No. Aquí no hay nadie."),"c117_ca_nadie":CA("¡Nadie! Hay un pájaro."),
 "c117_ab_ahora_si":AB("Puerta roja, nadie. Puerta azul, nadie. ¡Ahora sí están todos!"),"c117_ab_donde":AB("Coquí, ¿dónde estás?"),"c117_cq_aqui":T("¡Aquí!"),"c117_ab_otra_vez":AB("¡Ay! Otra vez falta alguien."),
 "c117_ab_uno_dos":AB("Ahora sí. Uno, dos..."),"c117_cq_tres":T("¡Tres!"),"c117_fin":N("En la foto están todos. No falta nadie.")})
DOORS=["roja","azul"]; DICE=["alguien","nadie"]
for h in DOORS:   # the four sentences Luis can say in the game, and the four corrections
    for w in DICE:
        c["c117_l_%s_%s"%(h,w)]=L("Detrás de la puerta %s, %s."%(h,w)); c["c117_no_%s_%s"%(h,w)]=L("¡No, Coquí! Detrás de la puerta %s, %s."%(h,w)); DIN.update(["c117_l_%s_%s"%(h,w),"c117_no_%s_%s"%(h,w)])
GUESTS117=["don_pepe","maestra","piraguero","senor","senora"]
VARS117={"na":DOORS,"nb":DOORS,"sa":DICE,"sb":DICE}
def sorteo117(s):
    # h: the box with somebody in it; n: the door Luis names; sd: what he says (alguien when he names the box with somebody, else nadie); d: the right door (the box with somebody)
    h,n,sd,d="h"+s,"n"+s,"s"+s,"d"+s
    return [{"draw":h,"options":DOORS},{"draw":n,"options":DOORS},{"calc":sd,"cond":n+"=$"+h,"then":"alguien","else":"nadie"},{"calc":d,"cond":h+"=roja","then":"puerta_roja","else":"puerta_azul"}]
def decision117(s):
    n,sd,d="n"+s,"s"+s,"d"+s
    return {"decide":"do","options":["puerta_roja","puerta_azul"],"pick":"$"+d,"tests":"$"+sd,"lock":True,"lead":[],"line":"c117_l_$%s_$%s"%(n,sd),
     "right":[act("abre117",cual="$"+d,ok=1),star],
     "wrong":[act("abre117",cual="$x",ok=0),"c117_no_$%s_$%s"%(n,sd),resta(lambda k:act("faroles",n=k))]+X}
s117={"id":"todos-en-la-foto","title":"Todos en la foto","place":"El fuerte","scene":"muralla","next":"por-que-no-bailas",
 "goal":"Open the sentry-box door with somebody behind it, as Luis says who is behind which door, so that abuela's three lanterns stay lit over the family photo: a door opened on an empty box lets the sleeping pigeons burst out and knock a lantern off the line, and a photo with fewer lanterns is darker.",
 "stake":{"thing":"faroles","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["todos","nadie","alguien"],"formas_foco":{},
 "back_again":["puerta","rojo","azul","detrás","hay","no hay","falta","aquí","¿dónde está?","pájaro","luz","viento","cuidado","otra vez","ahora","uno","dos","tres","por favor","sí","no"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START(),act("faroles",n=3),act("llega",quien="abuela",a="camara_abuela")]+juntos(*[act("llega",quien=q,a="centro%d"%i) for i,q in enumerate(("abuelo","luis","don_pepe","maestra","piraguero","senor","senora"),1)]+[act("llega",quien="carmen",a="dentro_roja"),act("ir",a="junto_camara")])+[{"wait":500},
  # 1: people move closer together (no act named); abuela counts heads on her fingers (in time with her line)
  {"dots":1},"c117_ab_foto"]+con(act("cuenta117"),"c117_ab_faltan")+[
  # 2: a giggle, the red box's window flickers (no act named); signed ask on the red door (Luis's own line): the frog pulls it open, Carmen with her hands over her mouth, her line, she runs to the others (`abre117`, in time with her line)
  {"dots":2},ask("puerta_roja","c117_l_shh",after=con(act("abre117",cual="puerta_roja",ok=1),"c117_ca_aqui_estoy")),
  # 3: signed ask on the blue door (abuela's own line): an empty box, a pigeon opens an eye, a lantern swings (`paloma117`); Luis shuts the door softly (no act named)
  {"dots":3},ask("puerta_azul","c117_ab_azul",after=[act("paloma117")]),"c117_l_no_nadie","c117_ca_nadie",
  # 4: abuela counts again, and nods; she looks about her feet; a speaking turn (aquí): he hops in front of the others
  {"dots":4},act("cuenta117"),gesto("abuela","si"),"c117_ab_ahora_si",gesto("abuela","mira",a="junto_camara"),"c117_ab_donde","c117_cq_aqui",act("ir",a="ante_todos"),
  # 5: the turn: abuela bends to her camera (no act named); the gust, the dark, one person gone, both doors shut (`viento117`, the person dealt out and the box he is in drawn here); abuela counts; Luis looks in at both windows; the card shows two places
  {"dots":5},{"reparte":["pa","pb"],"options":GUESTS117}]+sorteo117("a")+[act("viento117",quien="$pa",donde="$da"),act("cuenta117"),"c117_ab_otra_vez",act("mira117"),CARD,{"wait":400},
  # 6: A. 7: B (another gust, somebody else gone, Luis looks in again). The box, the door he names and what he says: drawn afresh each round
  {"dots":6},decision117("a"),
  {"dots":7}]+sorteo117("b")+[act("viento117",quien="$pb",donde="$db"),act("mira117"),decision117("b")],
 "final":[{"dots":8},baja3(lambda n:act("final117",n=n)),   # 8: everybody stands under the lanterns that are left (3: a bright photo; 2; 1: a dark one with white teeth)
  {"dots":9}]+con(gesto("abuela","cuenta"),"c117_ab_uno_dos")+["c117_cq_tres",baja3(lambda n:act("foto117",n=n)),"c117_fin",act("fin")],   # 9: abuela bends to her camera (no act named) and lifts a finger for each count; a speaking turn (tres); the flash, the photo slides out
 "leer":["c117_ab_foto","c117_ab_faltan","c117_l_shh","c117_ca_aqui_estoy","c117_ab_azul","c117_l_no_nadie","c117_ca_nadie","c117_ab_ahora_si","c117_ab_donde","c117_cq_aqui","c117_ab_otra_vez",
  "c117_l_roja_nadie","c117_no_roja_nadie","c117_l_azul_alguien","c117_ab_uno_dos","c117_cq_tres","c117_fin"]}
s117=reuse(s117,{"c117_cq_aqui":TG(("aquí",["aquí","estoy aquí"])),"c117_cq_tres":TG(("tres",["tres","y tres"]))})
json.dump(s117,open("cuentos/todos-en-la-foto.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 118. ¿Por qué no bailas? ----------------
# The last song lasts as long as the candle. Abuela, dancing, calls to one who does not dance; he says why not: the maestra in round A ("No, porque tengo sed."), the piragüero in round B ("Quiero bailar, pero tengo hambre.").
# The reasons are dealt out (none twice): sed, hambre, cansado. Decision A (the juice, the plate, the chair; tests porque) and B (the two things round A did not use; tests pero).
# A miss: the frog takes the guest another thing, she shakes her head, "No, Coquí. <her reason>.", the frog takes it back and the candle burns down past a ring; the sign is on the right thing; he touches it and she goes to dance.
nm,nc=nombres("abuela","abuelo","luis","carmen","piraguero","coqui"); c=dict(comunes); c.update(nc)
c.update({"c118_ca_por_que_no":CA("Abuelo, ¿por qué no bailas?"),"c118_abo_cansado":ABO("Porque estoy cansado."),"c118_abo_gracias":ABO("Gracias, Coquí."),
 "c118_ab_luis":AB("Luis, ¿por qué no bailas?"),"c118_l_sed":L("Porque tengo sed."),"c118_ab_pepe":AB("Pepe, ¿y tú? ¿Por qué no?"),"c118_dp_hambre":DP("Quiero bailar, pero tengo hambre."),
 "c118_abo_pero":ABO("Estoy cansado, pero quiero bailar."),"c118_ca_por_que":CA("¿Por qué, abuelo?"),"c118_abo_musica":ABO("¡Porque me gusta la música!"),"c118_ab_tu_cansado":AB("Coquí, ¿tú estás cansado?"),
 "c118_cq_no":T("¡No!"),"c118_ab_cansada":AB("Yo estoy cansada, pero contenta."),"c118_ab_maestra":AB("Maestra, ¿y tú? ¿No bailas?"),"c118_ab_piraguero":AB("¿Y tú? ¿Por qué no bailas?"),
 "c118_ab_noche":AB("¡Qué noche! Coquí, ¿cómo estás?"),"c118_cq_feliz":T("¡Feliz!"),"c118_fin":N("¿Por qué baila la gente? Porque está feliz.")})
REAS=["sed","hambre","cansado"]
# the guest's own words for each reason, and the correction (the script's example "No, Coquí. Tengo sed." for the other reasons by the same pattern)
MA_SAY={"sed":"No, porque tengo sed.","hambre":"No, porque tengo hambre.","cansado":"No, porque estoy cansada."}; MA_NO={"sed":"No, Coquí. Tengo sed.","hambre":"No, Coquí. Tengo hambre.","cansado":"No, Coquí. Estoy cansada."}
PI_SAY={"sed":"Quiero bailar, pero tengo sed.","hambre":"Quiero bailar, pero tengo hambre.","cansado":"Quiero bailar, pero estoy cansado."}; PI_NO={"sed":"No, Coquí. Tengo sed.","hambre":"No, Coquí. Tengo hambre.","cansado":"No, Coquí. Estoy cansado."}
for r in REAS:
    c["c118_ma_%s"%r]=MAE(MA_SAY[r]); c["c118_no_ma_%s"%r]=MAE(MA_NO[r]); c["c118_pi_%s"%r]=PI(PI_SAY[r]); c["c118_no_pi_%s"%r]=PI(PI_NO[r])
    DIN.update(["c118_ma_%s"%r,"c118_no_ma_%s"%r,"c118_pi_%s"%r,"c118_no_pi_%s"%r])
VARS118={"ra":REAS,"rb":REAS}
def cosa118(r,t):
    # the thing that answers a reason: sed the juice, hambre the plate, cansado the chair
    return [{"calc":t,"cond":r+"=sed","then":"jugo","else":"silla"},{"calc":t,"cond":r+"=hambre","then":"plato","else":"$"+t}]
def ronda118(s):
    # A: the maestra, three things. B: the piragüero, the two things round A did not use (oa, ob: round A's thing is the one left out).
    if s=="a":
        pre=cosa118("ra","ta")+["c118_ab_maestra"]; opts=["jugo","plato","silla"]; r,t,g,w,p="ra","ta","ma","maestra","porque"
    else:
        pre=cosa118("rb","tb")+[{"calc":"oa","cond":"ta=jugo","then":"plato","else":"jugo"},{"calc":"ob","cond":"ta=silla","then":"plato","else":"silla"},"c118_ab_piraguero"]; opts=["$oa","$ob"]; r,t,g,w,p="rb","tb","pi","piraguero","pero"
    return pre+[{"decide":"do","options":opts,"pick":"$"+t,"tests":p,"lock":True,"lead":[],"line":"c118_%s_$%s"%(g,r),
      "right":[act("trae118",que="$"+t,a=w,ok=1),star],
      "wrong":[act("trae118",que="$x",a=w,ok=0),"c118_no_%s_$%s"%(g,r),resta(lambda n:act("aros",n=n))]+X}]
s118={"id":"por-que-no-bailas","title":"¿Por qué no bailas?","place":"El fuerte","scene":"muralla","next":"nos-vemos",
 "goal":"Take each guest who is not dancing the thing that answers why not (the juice, the plate or the chair), so that the tall candle in the glass keeps its three red rings for the last song: a wrong thing carried to the guest and back is time, and the candle burns down a ring.",
 "stake":{"thing":"aros","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["¿por qué?","porque","pero"],"formas_foco":{"baila":["bailas"],"cansado":["cansada"]},
 "back_again":["baila","música","canción","tengo sed","tengo hambre","cansado","quiero","me gusta","jugo","silla","feliz","contento","¿cómo estás?","ahora","tú","gracias","sí","no"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START(),act("aros",n=3)]+juntos(act("llega",quien="musico1",a="banco1"),act("llega",quien="musico2",a="banco2"),act("llega",quien="abuelo",a="muro1"),act("llega",quien="abuela",a="baile1"),act("llega",quien="carmen",a="baile2"),act("llega",quien="luis",a="muro2"),act("ir",a="mesa_coqui"))+[{"wait":500},
  # 1: Carmen pulls at abuelo's hand (no act named); signed ask on the chair (abuelo's own line): the frog pushes it to him, he sits and breathes out
  {"dots":1},"c118_ca_por_que_no",ask("silla","c118_abo_cansado",after=[act("trae118",que="silla",a="abuelo",ok=1)]),"c118_abo_gracias",
  # 2: Luis stands apart with his tongue out; signed ask on the glass of juice (Luis's own line): the frog carries it over, he drinks it off and goes to dance
  {"dots":2},gesto("luis","lengua"),"c118_ab_luis",ask("jugo","c118_l_sed",after=[act("trae118",que="jugo",a="luis",ok=1)]),
  # 3: don Pepe comes to the parapet, a hand on his stomach; signed ask on the plate (his own line): the frog carries it over, he eats and goes to dance with the plate in his hand
  {"dots":3},act("llega",quien="don_pepe",a="muro2"),gesto("don_pepe","barriga"),"c118_ab_pepe",ask("plato","c118_dp_hambre",after=[act("trae118",que="plato",a="don_pepe",ok=1)]),
  # 4: abuelo gets up from his chair (no act named) and dances with abuela; Luis puts the chair, a new glass and a new plate back; a speaking turn (no)
  {"dots":4},"c118_abo_pero","c118_ca_por_que","c118_abo_musica",act("llega",quien="abuelo",a="baile3"),act("repone118"),"c118_ab_tu_cansado","c118_cq_no","c118_ab_cansada",
  # 5: the turn: the músico with the hat lifts his guitar, the last song begins; the maestra and the piragüero stand at the parapet; the card shows two places. The reasons of the two rounds are dealt out here (none twice)
  {"dots":5},act("cancion118")]+juntos(act("llega",quien="maestra",a="muro1"),act("llega",quien="piraguero",a="muro2"))+[CARD,{"reparte":["ra","rb"],"options":REAS},{"wait":400},
  # 6: A (the maestra). 7: B (the piragüero, with pero)
  {"dots":6}]+ronda118("a")+[{"dots":7}]+ronda118("b"),
 "final":[{"dots":8},baja3(lambda n:act("final118",n=n)),   # 8: everybody dances for as long as the candle (3: a long song, the moon moves; 2: a song and a bow; 1: the flame gutters, they stop with a foot in the air)
  {"dots":9},act("aros",n=0),"c118_ab_noche","c118_cq_feliz","c118_fin",act("fin")],   # 9: the candle goes out; the músicos put down the guitar and the drum (no act named); a speaking turn (feliz)
 "leer":["c118_ca_por_que_no","c118_abo_cansado","c118_abo_gracias","c118_ab_luis","c118_l_sed","c118_ab_pepe","c118_dp_hambre","c118_abo_pero","c118_ca_por_que","c118_abo_musica","c118_ab_tu_cansado","c118_cq_no","c118_ab_cansada",
  "c118_ab_maestra","c118_ma_sed","c118_ab_piraguero","c118_pi_hambre","c118_ab_noche","c118_cq_feliz","c118_fin"]}
s118=reuse(s118,{"c118_cq_no":TG(("no",["no","yo no"])),"c118_cq_feliz":TG(("feliz",["feliz","muy feliz"]))})
json.dump(s118,open("cuentos/por-que-no-bailas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 119. Nos vemos ----------------
# The guests go home by the guagua. A guest (dealt out of don Pepe, la señora, el señor and la maestra, none twice), his eyes on the guagua, asks for his own thing: "Mi caja, por favor." (each has his own).
# Decision A (the hat, the bag, the box, the book) and B (the three things round A did not use; a word he has decides: tests = the thing).
# A miss: he takes the wrong thing without a look and goes down the steps, climbs back out of breath, "¡No, Coquí! Mi caja.", puts it back and sits on the bench; the sign is on the right thing; he touches it and the frog takes it to him on the bench; the guagua goes without him.
nm,nc=nombres("abuela","abuelo","luis","carmen","senor","senora","coqui"); c=dict(comunes); c.update(nc)
c.update({"c119_ab_gracias":AB("¡Gracias por venir!"),"c119_m1_guitarra":MU1("¡Gracias a ustedes! ¿Y mi guitarra?"),"c119_m1_hasta":MU1("¡Gracias, Coquí! ¡Hasta pronto!"),
 "c119_abo_gracias":ABO("Gracias por venir. ¡Qué bonita la música! ¡Hasta pronto!"),"c119_m2_nos_vemos":MU2("¡Nos vemos, Coquí!"),"c119_cq_hasta_luego":T("¡Hasta luego!"),
 "c119_l_guagua":L("¡Mira, la guagua! ¡Ya mismo se va!"),"c119_ab_rapido":AB("¡Rápido! Gracias por venir. ¡Cuídense!"),"c119_ca_nos_vemos":CA("¡Nos vemos!"),
 "c119_abo_carro":ABO("Está bien. Vamos en mi carro."),"c119_gente":GE("¡Nos vemos, Coquí!"),"c119_cq_adios":T("¡Adiós!"),"c119_ab_buenas_noches":AB("Buenas noches, Coquí. Gracias por venir."),
 "c119_fin":N("La fiesta en el fuerte: la música, los regalos, la gente. Nos vemos. ¡Hasta pronto!")})
GU119={"don_pepe":("Don Pepe","caja"),"senora":("La señora","bolsa"),"senor":("El señor","sombrero"),"maestra":("La maestra","libro")}
GUESTS119=list(GU119)
for g,(pre,cosa) in GU119.items():   # what each guest asks for, the correction, and his thanks (the same words in his own voice)
    c["c119_%s_pide"%g]=D(g,pre,"Mi %s, por favor."%cosa); c["c119_no_%s"%g]=D(g,pre,"¡No, Coquí! Mi %s."%cosa); c["c119_gracias_%s"%g]=D(g,pre,"¡Gracias! ¡Nos vemos!")
    DIN.update(["c119_%s_pide"%g,"c119_no_%s"%g,"c119_gracias_%s"%g])
VARS119={"ga":GUESTS119,"gb":GUESTS119}
def cosa119(g,t):
    # each guest's own thing: don Pepe the box, la señora the bag, el señor the hat, la maestra the book
    return [{"calc":t,"cond":g+"=don_pepe","then":"caja","else":"libro"},{"calc":t,"cond":g+"=senora","then":"bolsa","else":"$"+t},{"calc":t,"cond":g+"=senor","then":"sombrero","else":"$"+t}]
def ronda119(s):
    # g: the guest (dealt out); t: his thing. A: the four things. B: the three things round A did not use (oa ob oc: round A's thing is the one left out).
    g,t="g"+s,"t"+s
    if s=="a": pre=cosa119(g,t); opts=["sombrero","bolsa","caja","libro"]
    else:
        pre=cosa119(g,t)+[{"calc":"oa","cond":"ta=sombrero","then":"bolsa","else":"sombrero"},
         {"calc":"ob","cond":"ta=sombrero","then":"caja","else":"bolsa"},{"calc":"ob","cond":"ta=bolsa","then":"caja","else":"$ob"},
         {"calc":"oc","cond":"ta=libro","then":"caja","else":"libro"}]
        opts=["$oa","$ob","$oc"]
    return pre+[{"decide":"do","options":opts,"pick":"$"+t,"tests":"$"+t,"lock":True,"lead":[],"line":"c119_$%s_pide"%g,
      "right":[{"if":"ok","then":con(act("entrega119",quien="$"+g,que="$"+t,ok=1),"c119_gracias_$"+g)+[OK],"else":[act("banco119",quien="$"+g,que="$"+t)]}],
      "wrong":[act("entrega119",quien="$"+g,que="$x",ok=0),"c119_no_$"+g]+X}]
s119={"id":"nos-vemos","title":"Nos vemos","place":"El fuerte","scene":"muralla","next":None,
 "goal":"Put into each guest's hand his own thing (the box, the bag, the hat or the book) as he asks, so that the guests catch the guagua below and fill its four windows: a guest who takes the wrong thing goes down the steps, has to climb them again out of breath, and the guagua goes without him.",
 "stake":{"thing":"caras","steps":4},"dots":9,"bien":"si_muy_bien",
 "focus_words":["nos vemos","hasta pronto","gracias por venir"],"formas_foco":{},
 "back_again":["guagua","se va","ya","rápido","guitarra","bolsa","sombrero","caja","libro","mi","música","bonito","cansado","está bien","carro","gente","hasta luego","adiós","buenas noches","por favor","gracias","sí","no"],
 "also_heard":["cuídense"],"names":nm,"palabras":{},"clips":c,
 "beats":[START("tarde_noche"),act("caras",n=0),act("llega",quien="abuela",a="escalera_abuela"),act("llega",quien="abuelo",a="escalera_abuelo")]+juntos(*[act("llega",quien=q,a="banco%d"%i) for i,q in enumerate(("don_pepe","senora","senor","maestra"),1)]+[act("ir",a="mesa_coqui")])+[{"wait":500},
  # 1: the músico with the hat comes to the steps; signed ask on the guitar (his own line): the frog pushes it to him and he slings it on his back (no act named); he goes down the steps
  {"dots":1},act("llega",quien="musico1",a="escalera1"),"c119_ab_gracias",ask("guitarra","c119_m1_guitarra"),"c119_m1_hasta",act("llega",quien="musico1",a="baja"),
  # 2: the other músico with his drum (no act named); a speaking turn (hasta luego); he goes down, and the two músicos walk off along the road
  {"dots":2},act("llega",quien="musico2",a="escalera1"),"c119_abo_gracias","c119_m2_nos_vemos","c119_cq_hasta_luego",act("llega",quien="musico2",a="baja"),act("musicos119"),
  # 3: the horn, the guagua's lights blink; the four guests hurry over from the bench; abuela kisses each on the cheek; Carmen waves
  {"dots":3},act("bocina119"),"c119_l_guagua"]+juntos(*[act("llega",quien=q,a="escalera%d"%i) for i,q in enumerate(GUESTS119,1)])+["c119_ab_rapido"]+[gesto("abuela","beso") for q in GUESTS119]+[gesto("carmen","saluda"),"c119_ca_nos_vemos",
  # 4: the turn: the four guests at the head of the steps, looking down, each with a hand held out behind him; the card shows two places. Which guest, and so which thing, is dealt out here (none twice)
  {"dots":4}]+juntos(*[gesto(q,"mano") for q in GUESTS119])+[CARD,{"reparte":["ga","gb"],"options":GUESTS119},{"wait":400},
  # 5: A. 6: B. Which guest asks (and so for what): dealt out
  {"dots":5}]+ronda119("a")+[{"dots":6}]+ronda119("b"),
 "final":[{"dots":7},act("bocina119"),baja4(lambda n:act("final119",n=n)),   # 7: the other two guests take their own things, wave and go down; the horn; the guagua goes off with its faces (4, 3, 2)
  {"if":"lost=0","then":[gesto("abuelo","saluda")],"else":["c119_abo_carro",gesto("abuelo","hombro")]},   # with somebody on the bench abuelo says "Está bien. Vamos en mi carro." and pats his shoulder; with four faces he only waves
  {"dots":8}]+juntos(*[act("llega",quien=q,a="pretil%d"%i) for i,q in enumerate(("abuela","abuelo","luis","carmen"),1)]+[act("ir",a="pretil5")])+["c119_gente","c119_cq_adios",gesto("coqui","saluda"),"c119_ab_buenas_noches",   # 8: the family and the frog at the parapet; a speaking turn (adiós); he waves with both arms
  {"dots":9},act("apaga119"),"c119_fin",act("fin")],   # 9: the lanterns go out one by one
 "leer":["c119_ab_gracias","c119_m1_guitarra","c119_m1_hasta","c119_abo_gracias","c119_m2_nos_vemos","c119_cq_hasta_luego","c119_l_guagua","c119_ab_rapido","c119_ca_nos_vemos","c119_don_pepe_pide","c119_no_don_pepe","c119_gracias_don_pepe",
  "c119_senora_pide","c119_abo_carro","c119_gente","c119_cq_adios","c119_ab_buenas_noches","c119_fin"]}
s119=reuse(s119,{"c119_cq_hasta_luego":TG(("hasta luego",["hasta luego","adiós"])),"c119_cq_adios":TG(("adiós",["adiós","adiós a todos"]))})
json.dump(s119,open("cuentos/nos-vemos.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files on disk, and the earlier stories of this run). One word is new in a story of ANOTHER scene of this place, which another generator writes:
# while its file is not on disk it is known (and a NOTE says so); once it is on disk the check is strict.
KNOWN_ELSEWHERE={"feliz":"que-bueno"}
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s117,s118,s119):
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            w=t["palabra"]
            if w in EARLIER: continue
            if w in KNOWN_ELSEWHERE and not os.path.exists("cuentos/%s.json"%KNOWN_ELSEWHERE[w]): print("NOTE: the turn on '%s' (%s, %s) takes a word of story %s, written by another generator and not on disk here: taken as known"%(w,st["id"],cid,KNOWN_ELSEWHERE[w]))
            else: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,w)
    EARLIER.update(st["focus_words"])
# every clip id the steps name (with no variable in it) is in the story's clips; an id put together from variables: for every value its variables can take; every `leer` id and every `names` clip too
def refs(o):   # the clip ids a list of steps names: bare strings of the step lists, and the `line` / `say` / `bien` of a step
    if isinstance(o,str): yield o
    elif isinstance(o,list):
        for x in o: yield from refs(x)
    elif isinstance(o,dict):
        if "calc" in o or "draw" in o or "reparte" in o: return   # a calc's then / else are values, not steps
        for k in ("lead","after","then","else","right","wrong"):
            if k in o: yield from refs(o[k])
        for k in ("line","say","bien"):
            if isinstance(o.get(k),str): yield o[k]
for st,VARS in ((s117,VARS117),(s118,VARS118),(s119,VARS119)):
    for i in sorted(set(refs([st["beats"],st["final"]]))):
        if "$" in i:   # a built id: every value its variables can take must be a clip
            combos=[i]
            for v in dict.fromkeys(re.findall(r"\$([a-z]+)",i)): combos=[x.replace("$"+v,val) for x in combos for val in VARS.get(v,["?"+v])]
            for x in combos:
                if x not in st["clips"]: print("MISSING BUILT CLIP",st["id"],i,x)
        elif i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for k,v in st["names"].items():
        if v not in st["clips"]: print("MISSING NAME",st["id"],k,v)
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
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
