# La música (place 10, El fuerte, scene 2 of 4): stories 111, 112, 113. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/musica.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `musica` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: the generators of places 4 to 9 first (each sees only what was recorded before it), then the four scenes of El fuerte in any order (subida, this one, regalos, muralla); inside this file 111, 112, 113 are written in that order.
#   Speaking turns of this scene: 111 sí, mucho, otro; 112 quiero, yo; 113 puedo, claro. All are words of places 1 to 9 EXCEPT `claro`, a new word of 112 (this scene): the check at the end sees it as the focus word of an earlier story of this run.
#   `feliz` (new in 113) is the word of a turn of story 118 (another scene of this place, another builder): no turn of this scene uses it.
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   Variable names have letters only (the engine fills `$name` with [a-z]+): qa qb wa wb pa pb pc pd pe ka kb ra om. A value that is a LIST cannot be filled by the engine: an act's list argument is one string, items joined by commas (113's `ronda113`).
#   111  `toca111` {quien, que, ok}: quien = musico1 (round A: "El músico", the one with the hat) or musico2 (round B: "El otro músico"); que = guitarra or tambor = what the frog pushes into his hands (on a wrong touch `$x`, the other one, ok 0).
#        Who asks is fixed by the round, the instrument is drawn on its own each round (the two may be the same): `wa`, `wb`. 4 asks (2 speakers x 2 instruments) and 4 corrections are clips. `cuelga111` ends every round (right: after the star; wrong: after the line).
#        The count `parejas` {n}: 3 at the start, 2 / 1 after a loss (resta), after the picture act (the couple walking off is the act's own) and the line, before the cross. `final111` {n} = what is left.
#        Step 4: `cambian111` (the change over and the second song) runs started loose with the two lines (con), then abuela's line, then `cuelga111`. The first song ("They play together, and stop") has no act of its own: see the report.
#   112  The person of each round is dealt by `reparte` among abuelo, luis, carmen (qa, qb: "another person"); what he does is drawn on its own each round (baila, canta): the two rounds may be the same. 6 asks and 6 corrections are clips.
#        `baila112` / `canta112` {quien, ok}: by the VERB asked; ok 1 = he does it at the right place, ok 0 = at the wrong one (dances at the microphone: the cable; sings on the floor: nobody hears). After a wrong touch the sign's touch runs the act again with ok 1.
#        `notas` {n}: 0 at the start (dark), the turn's `fuera112` lights all three; then 2 / 1 after a loss (resta); `final112` {n} = what is left. `vuelve112` {quien} ends each round (right: after the star).
#        The game: the músico with the hat looks at his guitar before each of his lines (`gesto` mira, a = guitarra: the script's "his eyes on his guitar").
#        Step 1: abuelo and abuela go onto the floor together (two baila112 started together). Step 2: Carmen's `llega` to ante_micro (the script: "runs to the microphone"). Step 4: abuelo at the microphone (canta112) and Carmen on the floor (baila112), together.
#        Step 5: after `fuera112` abuelo, Luis and Carmen go back to the spots they started on (espera1, espera3, espera4); abuela is left to `fuera112`. Step 9: abuelo goes to banco1 and fans himself.
#   113  The five people of the game are drawn by `reparte` (pa..pe) out of POOL113: the family (abuelo, luis, carmen) and the people of every place (senor, senora, joven, mujer, hombre: the script names no keys for them; the kit's own person keys).
#        Slot i of `ronda113` {quienes, que} = spot ronda_i: slot 1 laughs (rie), 2 sings at the microphone (canta), 3 yawns (bosteza: never asked), 4 dances (baila), 5 eats on the bench (come). Round A: pa..pe in the slots; round B: the same five, each moved one slot on (pb..pe, pa): everybody changes place AND thing ("they change places and things").
#        What is asked: one round (ra) is rie, the other is one of canta, baila, come (om); so each round's thing is drawn on its own, round B's is not round A's, the yawn is never asked. The asked person (ka, kb) is the one in that thing's slot.
#        The right line "¡Qué bueno! ¡Qué divertido!" and the star come only when the FIRST touch was right (the script: after a wrong one "a flash, and the photo goes into the album": nothing more). Wrong: the act `foto113` {a, ok 0} runs with abuela's line (con), then the count `hojas`, then the cross.
#        `hojas` {n}: 3 at the start; 2 / 1 after a loss (resta); `final113` {n} = what is left. Values for what each person does: rie, canta, bosteza, baila, come (the script names none).
#        Start spots (the script: "Luis and Carmen beside abuela, at the floor's edge"): abuela espera1, luis espera2, carmen espera3, the frog centro_coqui (the Needs list names no other frog spot for 113). Step 2: Luis goes to banco1. Step 5: abuela goes to banqueta_abuela.
#   Every story sets its own states at the start (hora noche): every story starts fresh.
import json,glob,os,re,collections,unicodedata
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); ABO=lambda t:D("abuelo","Abuelo",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
MU=lambda t:D("musico1","El músico",t); MO=lambda t:D("musico2","El otro músico",t)   # the músico with the hat; the other one, with the beard
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
START={"set":{"hora":"noche"}}                           # every story starts fresh (the scene has one state: night, lanterns)
MINE=("la-musica","quieres-bailar","que-bueno")          # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c111_a_$wa"): never renamed
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
# What he hears when he pokes a person already recorded (the músicos have no recorded name line: not a poke)
NM={"abuela":("abuela",N("Esta es abuela.")),"abuelo":("n_abuelo",N("Este es abuelo.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora.")),"joven":("b_n_joven",N("Es un joven.")),"mujer":("b_n_mujer",N("Es una mujer.")),"hombre":("b_n_hombre",N("Es un hombre."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}

# ---------------- 111. La música ----------------
# Two músicos on the stage, empty-handed; the instruments hang on their stand. Before each song the two shut their eyes; one asks for the instrument the song begins with: round A the músico with the hat, round B the other one.
# The instrument is drawn each round on its own. A miss: he plays what he gets, the other way (the guitar beaten like a drum, the drum strummed): a sour noise, a couple covers its ears and walks off to the bench; the sign is on the right instrument.
nm,nc=nombres("abuela","coqui"); c=dict(comunes); c.update(nc)
c.update({"c111_ab_musica":AB("Coquí, en una fiesta hay música. Mira."),"c111_mu_hola":MU("¡Hola, Coquí! ¿Quieres música?"),"c111_cq_si":T("¡Sí!"),
 "c111_mu_dame":MU("Dame la guitarra, por favor."),"c111_ab_bonita_guitarra":AB("¡Qué bonita la guitarra!"),
 "c111_mo_tambor":MO("Y para mí, el tambor."),"c111_ab_gusta_tambor":AB("Me gusta el tambor."),
 "c111_mu_cancion":MU("Esa es una canción. ¿Te gusta la canción?"),"c111_cq_mucho":T("¡Sí, mucho!"),
 "c111_mo_ahora_guitarra":MO("Ahora la guitarra, para mí."),"c111_mu_yo_tambor":MU("Y yo, el tambor."),"c111_ab_bonita_musica":AB("¡Qué bonita la música!"),
 "c111_mu_otra":MU("Ahora, otra canción."),
 "c111_ab_cancion":AB("¡Qué bonita canción! Coquí, ¿quieres otra?"),"c111_cq_otra":T("¡Otra, por favor!"),
 "c111_fin":N("En la fiesta hay música: una guitarra, un tambor y una canción.")})
INSTR={"guitarra":"la guitarra","tambor":"el tambor"}
for s,SP in (("a",MU),("b",MO)):   # the ask of each round (one per instrument) and its correction
    for k,w in INSTR.items():
        c["c111_%s_%s"%(s,k)]=SP("Para esta canción, %s."%w); c["c111_no_%s_%s"%(s,k)]=SP("¡No, Coquí! ¡%s!"%(w[0].upper()+w[1:])); DIN.update(["c111_%s_%s"%(s,k),"c111_no_%s_%s"%(s,k)])
VARS111={"wa":list(INSTR),"wb":list(INSTR)}
def ronda111(s,quien):
    # w: the instrument asked for (drawn). Right: he plays it, notes float up, the couples dance, a star, he hangs it back. Wrong: the one he touched (x), played wrongly, a couple walks off; the line; the wrong one is hung back; the count; the cross. Then the sign.
    w="w"+s
    return [{"draw":w,"options":list(INSTR)},
     {"decide":"do","options":list(INSTR),"pick":"$"+w,"tests":"$"+w,"lock":True,"lead":[],"line":"c111_%s_$%s"%(s,w),
      "right":[act("toca111",quien=quien,que="$"+w,ok=1),star,act("cuelga111")],
      "wrong":[act("toca111",quien=quien,que="$x",ok=0),"c111_no_%s_$%s"%(s,w),act("cuelga111"),resta(lambda n:act("parejas",n=n))]+X}]
s111={"id":"la-musica","title":"La música","place":"El fuerte","scene":"musica","next":"quieres-bailar",
 "goal":"Touch the instrument the músico asks for, the guitar or the drum, so that the three couples waiting on the open floor keep dancing: the wrong instrument in a músico's hands makes a sour noise, and a couple covers its ears and walks off to the bench.",
 "stake":{"thing":"parejas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["música","canción","guitarra","tambor"],"formas_foco":{},
 "back_again":["fiesta","noche","dame","para mí","quiere","otro","me gusta","mucho","bonito","ahora","yo","mira","por favor","gracias","sí","no"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START,act("parejas",n=3)]+juntos(act("llega",quien="musico1",a="taburete1"),act("llega",quien="musico2",a="taburete2"),act("llega",quien="abuela",a="junto_escenario"),act("ir",a="borde_coqui"))+[{"wait":500},
  # 1: abuela's line is the signed ask on the stage: the músico with the hat waves; he asks; a speaking turn (sí)
  {"dots":1},ask("escenario","c111_ab_musica",after=[gesto("musico1","saluda")]),"c111_mu_hola","c111_cq_si",
  # 2: the músico's line is the signed ask on the guitar: the frog pushes it into his hands, he strums, the couples sway (no act of their own named); abuela
  {"dots":2},ask("guitarra","c111_mu_dame",after=[act("toca111",quien="musico1",que="guitarra",ok=1)]),"c111_ab_bonita_guitarra",
  # 3: the other músico taps his knees (no act named); his line is the signed ask on the drum: the frog pushes it over, he beats it, the couples step; abuela
  {"dots":3},ask("tambor","c111_mo_tambor",after=[act("toca111",quien="musico2",que="tambor",ok=1)]),"c111_ab_gusta_tambor",
  # 4: they play together and stop (no act named); a speaking turn (mucho); they change over and play again the other way round, in time with their two lines; abuela; the instruments go back on their stand
  {"dots":4},"c111_mu_cancion","c111_cq_mucho"]+con(act("cambian111"),"c111_mo_ahora_guitarra","c111_mu_yo_tambor")+["c111_ab_bonita_musica",act("cuelga111"),
  # 5: the turn: the músicos sit with open hands, the couples stand ready and tap their feet, the músicos nod (no act named); the card shows two places
  {"dots":5},"c111_mu_otra",CARD,{"wait":400},
  # 6: A (the músico with the hat). 7: B (the other músico). The instrument: drawn afresh each round; both instruments hang on the stand before each song, and the músicos shut their eyes (no act named)
  {"dots":6}]+ronda111("a","musico1")+[{"dots":7}]+ronda111("b","musico2"),
 "final":[{"dots":8},baja3(lambda n:act("final111",n=n)),   # 8: the song goes on; the couples that are left dance (three: stars and a heart; two; one, and two watch from the bench)
  {"dots":9},"c111_ab_cancion","c111_cq_otra","c111_fin",act("fin")],   # 9: a speaking turn (otro)
 "leer":["c111_ab_musica","c111_mu_hola","c111_cq_si","c111_mu_dame","c111_ab_bonita_guitarra","c111_mo_tambor","c111_ab_gusta_tambor","c111_mu_cancion","c111_cq_mucho","c111_mo_ahora_guitarra","c111_mu_yo_tambor","c111_ab_bonita_musica","c111_mu_otra",
  "c111_a_tambor","c111_b_guitarra","c111_ab_cancion","c111_cq_otra","c111_fin"]}
s111=reuse(s111,{"c111_cq_si":TG(("sí",["sí","si"])),"c111_cq_mucho":TG(("mucho",["mucho","sí mucho"])),"c111_cq_otra":TG(("otro",["otra","otra por favor","otro"]))})
json.dump(s111,open("cuentos/la-musica.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 112. ¿Quieres bailar? ----------------
# Three big paper notes hang over the stage, dark: the long song's three parts; they light at the turn. The músico with the hat, his eyes on his guitar, says what one of the people does now (abuelo, Luis or Carmen, dealt; baila or canta, drawn on its own each round).
# The frog leads that one to the open floor (baila) or to the microphone (canta). A miss: he dances at the microphone and his foot catches its cable, or he sings on the floor where nobody hears: the music stops, a paper note goes dark; the sign is on the right place.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c112_abo_bailar":ABO("¿Quieres bailar?"),"c112_ab_claro":AB("¡Claro!"),"c112_l_mira":L("Mira, Coquí. Abuela baila con abuelo."),
 "c112_ca_canto":CA("¡Yo canto!"),"c112_mu_claro_carmen":MU("¡Claro, Carmen!"),"c112_l_canta":L("Carmen canta la canción."),"c112_ab_bonito":AB("¡Qué bonito canta Carmen!"),
 "c112_ca_luis":CA("Luis, ¿quieres bailar?"),"c112_ca_claro_si":CA("¡Claro que sí! Tú bailas y yo canto."),
 "c112_ab_abuelo_canta":AB("¡Abuelo canta y Carmen baila! Coquí, ¿quieres bailar?"),"c112_cq_quiero":T("¡Sí, quiero!"),"c112_ab_coqui_baila":AB("¡Coquí baila!"),
 "c112_abo_cansado":ABO("¡Ay! Estoy cansado. ¿Y tú, Coquí?"),"c112_cq_yo_no":T("¡Yo no!"),"c112_cq_canta":T("¡Coquí! ¡Coquí!"),
 "c112_fin":N("En la fiesta, la gente baila y canta. Coquí canta también.")})
PERS={"abuelo":"el abuelo","luis":"Luis","carmen":"Carmen"}   # the article: "Ahora el abuelo canta" but "Ahora Carmen baila"
for q,w in PERS.items():   # the six asks (3 people x baila, canta) and their six corrections
    for v in ("baila","canta"):
        c["c112_ahora_%s_%s"%(q,v)]=MU("Ahora %s %s."%(w,v)); c["c112_no_%s_%s"%(q,v)]=MU("¡No, Coquí! %s %s."%(w[0].upper()+w[1:],v)); DIN.update(["c112_ahora_%s_%s"%(q,v),"c112_no_%s_%s"%(q,v)])
VARS112={"qa":list(PERS),"qb":list(PERS),"wa":["baila","canta"],"wb":["baila","canta"]}
def ronda112(s):
    # q: who (dealt at the turn), w: what he does (drawn), p: the right place (the floor to dance, the microphone to sing).
    # Right: he does it there, a star, he walks back (the microphone stands upright). Wrong: the other place (x), the music stops, the line, a paper note goes dark, the cross; then the sign's touch leads him across.
    q,w,p="q"+s,"w"+s,"p"+s
    return [{"draw":w,"options":["baila","canta"]},{"calc":p,"cond":w+"=baila","then":"pista","else":"microfono"},gesto("musico1","mira",a="guitarra"),
     {"decide":"do","options":["pista","microfono"],"pick":"$"+p,"tests":"$"+w,"lock":True,"lead":[],"line":"c112_ahora_$%s_$%s"%(q,w),
      "right":[{"if":w+"=baila","then":[act("baila112",quien="$"+q,ok=1)],"else":[act("canta112",quien="$"+q,ok=1)]},star,act("vuelve112",quien="$"+q)],
      "wrong":[{"if":w+"=baila","then":[act("baila112",quien="$"+q,ok=0)],"else":[act("canta112",quien="$"+q,ok=0)]},"c112_no_$%s_$%s"%(q,w),resta(lambda n:act("notas",n=n))]+X}]
s112={"id":"quieres-bailar","title":"¿Quieres bailar?","place":"El fuerte","scene":"musica","next":"que-bueno",
 "goal":"Lead abuelo, Luis or Carmen to the open floor to dance or to the microphone to sing, as the músico says, so that the long song's three paper notes over the stage stay lit: at the wrong place someone trips on the microphone's cable, or sings where nobody hears, the music stops for a moment, and a note goes dark.",
 "stake":{"thing":"notas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["baila","canta","¿quieres bailar?","claro"],"formas_foco":{"baila":["bailas"],"canta":["canto"]},
 "back_again":["música","canción","guitarra","quiero","también","cansado","ahora","yo","tú","por favor","gracias","sí","no"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START,act("notas",n=0)]+juntos(act("llega",quien="musico1",a="taburete1"),act("llega",quien="musico2",a="taburete2"),act("llega",quien="abuelo",a="espera1"),act("llega",quien="abuela",a="espera2"),act("llega",quien="luis",a="espera3"),act("llega",quien="carmen",a="espera4"),act("ir",a="centro_coqui"))+[{"wait":500},
  # 1: abuelo bows to abuela; abuela's line is the signed ask on the open floor: the frog leads them onto the floor, they dance; Luis
  {"dots":1},gesto("abuelo","reverencia"),"c112_abo_bailar",ask("pista","c112_ab_claro",after=juntos(act("baila112",quien="abuelo",ok=1),act("baila112",quien="abuela",ok=1))),"c112_l_mira",
  # 2: Carmen runs to the microphone and says she sings; the músico's line is the signed ask on the microphone: the frog tips it down to her, she sings; Luis; abuela
  {"dots":2},act("llega",quien="carmen",a="ante_micro"),"c112_ca_canto",ask("microfono","c112_mu_claro_carmen",after=[act("canta112",quien="carmen",ok=1)]),"c112_l_canta","c112_ab_bonito",
  # 3: Carmen asks Luis; he shakes his head and looks at his feet; she pulls him onto the floor and he dances, stiff, then well (no act of its own named for her pulling)
  {"dots":3},"c112_ca_luis",gesto("luis","no"),gesto("luis","pies"),"c112_ca_claro_si",act("baila112",quien="luis",ok=1),
  # 4: abuelo goes to the microphone (tipped up to him) and sings, Carmen dances with abuela; a speaking turn (quiero); the frog hops in a circle (no act named)
  {"dots":4}]+juntos(act("canta112",quien="abuelo",ok=1),act("baila112",quien="carmen",ok=1))+["c112_ab_abuelo_canta","c112_cq_quiero","c112_ab_coqui_baila",
  # 5: the turn: the song ends, everybody comes off the floor, the microphone stands upright, the three notes light up; abuelo, Luis and Carmen stand ready at the right; the card shows two places. The people of the rounds are dealt here
  {"dots":5},act("fuera112")]+juntos(act("llega",quien="abuelo",a="espera1"),act("llega",quien="luis",a="espera3"),act("llega",quien="carmen",a="espera4"))+[CARD,{"reparte":["qa","qb"],"options":list(PERS)},{"wait":400},
  # 6: A. 7: B (another person). What he does: drawn afresh each round
  {"dots":6}]+ronda112("a")+[{"dots":7}]+ronda112("b"),
 "final":[{"dots":8},baja3(lambda n:act("final112",n=n)),   # 8: the song comes to its end: three notes lit (everybody dances, the one at the microphone sings), two, one (a short song)
  {"dots":9},act("llega",quien="abuelo",a="banco1"),gesto("abuelo","abanico"),"c112_abo_cansado","c112_cq_yo_no"]+con(act("coqui112"),"c112_cq_canta")+["c112_fin",act("fin")],   # 9: abuelo sits on the bench and fans himself; a speaking turn (yo); the frog sings into the microphone
 "leer":["c112_abo_bailar","c112_ab_claro","c112_l_mira","c112_ca_canto","c112_mu_claro_carmen","c112_l_canta","c112_ab_bonito","c112_ca_luis","c112_ca_claro_si","c112_ab_abuelo_canta","c112_cq_quiero","c112_ab_coqui_baila",
  "c112_ahora_abuelo_canta","c112_ahora_carmen_baila","c112_abo_cansado","c112_cq_yo_no","c112_cq_canta","c112_fin"]}
s112=reuse(s112,{"c112_cq_quiero":TG(("quiero",["quiero","sí quiero"])),"c112_cq_yo_no":TG(("yo",["yo no","no"]))})
json.dump(s112,open("cuentos/quieres-bailar.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 113. ¡Qué bueno! ----------------
# Abuela's camera makes paper photos; three spare sheets stick out of her pocket. Round the floor five people, each doing one thing (laughing, singing, yawning, dancing, eating). Abuela, her eyes on her album, asks who does one of four things for a photo; the frog touches one: a flash.
# A miss: the photo is of the wrong person: a sheet wasted, abuela loads a spare one; the sign is on the right person.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui","senor","senora","joven","mujer","hombre"); c=dict(comunes); c.update(nc)
c.update({"c113_ab_rie":AB("Mira, Coquí: Carmen se ríe."),"c113_ab_rie_mucho":AB("Carmen se ríe mucho. ¡Está feliz!"),
 "c113_l_divertido":L("¡Qué divertido!"),"c113_ab_luis_rie":AB("Luis se ríe también. La fiesta está divertida."),
 "c113_q_rie":AB("¿Quién se ríe? Quiero una foto."),"c113_ab_bueno_foto":AB("¡Qué bueno! Mira la foto: Carmen se ríe."),
 "c113_ab_tu":AB("Ahora tú, Coquí. ¿Puedes?"),"c113_cq_puedo":T("¡Sí, puedo!"),"c113_ab_bueno_feliz":AB("¡Qué bueno! Coquí está feliz."),
 "c113_ab_bueno_div":AB("¡Qué bueno! ¡Qué divertido!"),
 "c113_ab_bailar":AB("Coquí, ¿quieres bailar?"),"c113_cq_claro":T("¡Claro!"),"c113_fin":N("La fiesta está divertida. Todos se ríen. Coquí está feliz. ¡Qué bueno!")})
ASKED={"rie":"se ríe","canta":"canta","baila":"baila","come":"come"}   # the four things she asks who does (the yawn is never asked)
for k,w in ASKED.items():
    if k!="rie": c["c113_q_%s"%k]=AB("¿Quién %s? Quiero una foto."%w)   # "rie" is the opening's own line (c113_q_rie)
    c["c113_no_%s"%k]=AB("No, Coquí. ¿Quién %s?"%w); DIN.update(["c113_q_%s"%k,"c113_no_%s"%k])
VARS113={"wa":list(ASKED),"wb":list(ASKED)}
POOL113=["abuelo","luis","carmen","senor","senora","joven","mujer","hombre"]   # the family, and the people of every place
SLOTS113="rie,canta,bosteza,baila,come"                                         # what the people in slot 1 to 5 (ronda1 to ronda5) do
SLOT_A=["pa","pb","pc","pd","pe"]; SLOT_B=["pb","pc","pd","pe","pa"]            # round B: everybody has moved one slot on
def juego113(s,slot):
    # w: the thing asked (drawn at the turn); k: the person who does it (the one in that thing's slot). Right: a flash, into the album, abuela's line, a star. Wrong: a flash of the person touched (x), the photo goes under the stool and a spare sheet is loaded, in time with her line; the count; the cross; then the sign's touch.
    w,k="w"+s,"k"+s
    return [{"calc":k,"cond":w+"=rie","then":"$"+slot[0],"else":"$"+slot[4]},{"calc":k,"cond":w+"=canta","then":"$"+slot[1],"else":"$"+k},{"calc":k,"cond":w+"=baila","then":"$"+slot[3],"else":"$"+k},
     {"decide":"do","options":["$"+v for v in SLOT_A],"pick":"$"+k,"tests":"$"+w,"lock":True,"lead":[],"line":"c113_q_$"+w,
      "right":[act("foto113",a="$"+k,ok=1),{"if":"ok","then":["c113_ab_bueno_div",OK]}],
      "wrong":con(act("foto113",a="$x",ok=0),"c113_no_$"+w)+[resta(lambda n:act("hojas",n=n))]+X}]
s113={"id":"que-bueno","title":"¡Qué bueno!","place":"El fuerte","scene":"musica","next":"la-sorpresa",
 "goal":"Touch the person abuela asks about for her paper photo (who laughs, sings, dances or eats) so that the three spare sheets of photo paper stay in her pocket for the last photos: a photo of the wrong person is a sheet wasted, and abuela has to load a spare one.",
 "stake":{"thing":"hojas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["se ríe","feliz","divertido","¡qué bueno!"],"formas_foco":{"divertido":["divertida"],"se ríe":["se ríen"]},
 "back_again":["baila","canta","come","¿quién?","fiesta","quiero","puedes","puedo","claro","¿quieres bailar?","mira","también","mucho","ahora","tú","sí","no"],
 "also_heard":[],"names":nm,"palabras":{"rie":"se ríe"},"clips":c,
 "beats":[START,act("hojas",n=3)]+juntos(act("llega",quien="abuela",a="espera1"),act("llega",quien="luis",a="espera2"),act("llega",quien="carmen",a="espera3"),act("ir",a="centro_coqui"))+[{"wait":500},
  # 1: Luis speaks into Carmen's ear, she laughs bent double; abuela's line is the signed ask on Carmen: she laughs harder
  {"dots":1},gesto("luis","oido"),gesto("carmen","rie"),ask("carmen","c113_ab_rie",after=[gesto("carmen","rie")]),"c113_ab_rie_mucho",
  # 2: Luis laughs too; abuela; Luis wipes his eyes (no act named) and goes off to the bench to eat; Carmen is still laughing
  {"dots":2},"c113_l_divertido",gesto("luis","rie"),"c113_ab_luis_rie",act("llega",quien="luis",a="banco1"),
  # 3: abuela lifts her camera (no act named); her line is the signed ask on Carmen: a flash, a photo slides out; abuela
  {"dots":3},ask("carmen","c113_q_rie",after=[act("foto113",a="carmen",ok=1)]),"c113_ab_bueno_foto",
  # 4: abuela hangs the camera round the frog's neck (no act named); a speaking turn (puedo)
  {"dots":4},"c113_ab_tu","c113_cq_puedo","c113_ab_bueno_feliz",
  # 5: the turn: abuela sits on the stool with her album, the spare sheets in her pocket; five people dealt round the floor, each doing one thing; the card shows two places.
  #    Drawn here: which round asks who laughs (ra), the other round's thing (om), then each round's thing (wa, wb)
  {"dots":5},act("llega",quien="abuela",a="banqueta_abuela"),{"reparte":SLOT_A,"options":POOL113},
  {"draw":"ra","options":["a","b"]},{"draw":"om","options":["canta","baila","come"]},{"calc":"wa","cond":"ra=a","then":"rie","else":"$om"},{"calc":"wb","cond":"ra=a","then":"$om","else":"rie"},
  act("ronda113",quienes=",".join("$"+v for v in SLOT_A),que=SLOTS113),CARD,{"wait":400},
  # 6: A. 7: B (the same five, changed places and things)
  {"dots":6}]+juego113("a",SLOT_A)+[{"dots":7},act("ronda113",quienes=",".join("$"+v for v in SLOT_B),que=SLOTS113)]+juego113("b",SLOT_B),
 "final":[{"dots":8},baja3(lambda n:act("final113",n=n)),   # 8: abuela takes the camera back and uses the spare sheets that are left (three: the músicos, everybody on the floor, the frog; two; one)
  {"dots":9},"c113_ab_bailar","c113_cq_claro","c113_fin",act("fin")],   # 9: a speaking turn (claro); they dance (no act named)
 "leer":["c113_ab_rie","c113_ab_rie_mucho","c113_l_divertido","c113_ab_luis_rie","c113_q_rie","c113_ab_bueno_foto","c113_ab_tu","c113_cq_puedo","c113_ab_bueno_feliz",
  "c113_q_baila","c113_ab_bueno_div","c113_ab_bailar","c113_cq_claro","c113_fin"]}
s113=reuse(s113,{"c113_cq_puedo":TG(("puedo",["puedo","sí puedo"])),"c113_cq_claro":TG(("claro",["claro","claro que sí"]))})
json.dump(s113,open("cuentos/que-bueno.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files on disk, and the earlier stories of this run: 113's `claro` is 112's new word). `feliz` is a turn of story 118 (another scene): none here.
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s111,s112,s113):
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in EARLIER: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
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
for st,VARS in ((s111,VARS111),(s112,VARS112),(s113,VARS113)):
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
