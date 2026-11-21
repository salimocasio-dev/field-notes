# El camino al fuerte (place 10, El fuerte, scene 1 of 4, scene id `subida`): stories 108, 109, 110. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/subida.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `subida` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: the generators of places 4 to 9 first (each sees only what was recorded before it), then the four of El fuerte in order (this one, musica, regalos, muralla).
#   Speaking turns of this scene: 108 quiero, bonito; 109 bien, gracias; 110 también, tengo hambre. All are focus words of stories of places 1 to 9 (que-calor, esta-lloviendo, buen-provecho, tengo-hambre). None needs a word of this place.
#   The other stories of this place (111 to 119) are never read by this file: not as earlier words, not for clip reuse (the stories of El fuerte are written by four generators at once).
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   SPEAKER KEY OF DON PEPE: the script's Needs list says `don_pepe`; the 135 clips of places 1 to 9 that he speaks carry `habla: "pepe"` (and the acts `pasa`/`llega` take `pepe`). This file uses `pepe` (PEPE below: one line to change).
#   PEOPLE THE SCRIPT DOES NOT NAME BY KEY: the boy with his dog is `nino` and the girl `nina` (108; the third passer-by of 109 is `nino`); the speakers' keys are the script's: abuela luis carmen pepe maestra piraguero senora joven.
#   PATH SPOTS: camino1 is the one nearest the gate, camino4 the one at the foot; people arriving in a line take camino1, camino2, ... in the order of arrival. The script's start places for people it does not place are
#     108: Luis camino3, Carmen camino4 (the family comes up the path), the boy camino2, Luis camino4 and the girl camino3 when he goes down to stop her (step 5), then Luis camino1, the boy camino2, the girl camino3 (step 9).
#     110: abuela puerta_abuela and the frog ante_puerta at the start; guests who "come in at the gate" stop at camino1; Carmen starts on the grass (grama3), Luis runs in to grama1, Carmen jumps out to grama2;
#          Don Pepe, the maestra and Carmen go to mesa_comida, mesa_jugos, hamaca_dentro when they settle in the opening (the script: "the frog leads him there": the lines of the opening use `llega`, because `lleva110` lights a lantern).
#   108  The two rounds ask the wall and the flag in a drawn order (pa, then pb the other one). Both rounds can be touched on the wall, the flag or the gate; the gate is never asked for.
#        Right: `farol108` {donde, ok 1}, the frog back to Carmen (`ir` junto_carmen), the star. Wrong: `farol108` {donde = the thing he touched, ok 0} runs in time with the correction line (`con`: he holds it up, the line, the gust), then the cross and one step of the stake.
#        After the sign's touch (ok 0): the frog hops to the hook of the right place (`ir` gancho_<place>) and back to Carmen (`ir` junto_carmen); nothing hangs.
#        `faroles` {donde}: this file gives it the two places the frog hung a lantern at, "muralla,bandera" in round order, "-" for a round that was lost ("-,-" when both were); the gate's lantern is Carmen's (`final108`). Reported.
#        The stake has no count-act in the script's Needs: the basket's three lanterns at the start and the one that goes over the wall are `farol108`'s own; nothing here sets a count.
#   109  Who stops at the paper (ga, gb) is dealt from the two the script names (senora, joven); the third passer-by (step 7) is `nino`, who speaks nothing. The question of each round is drawn on its own (qa, qb): both can be the same.
#        `pregunta109` {quien, ok}: ok 1 goes up to the fort (after the line "¡Ah! Gracias. Voy."), ok 0 shrugs and walks on (after the correction line); the passer-by is brought to the paper with `llega` junto_cartel before the question.
#        The wrong move: the other picture shines (`cartel109` cual = the thing he touched), the passer-by looks at it (`gesto mira`: the script says "frowns"), the line, `pregunta109` ok 0, the cross. After the touch: the right picture shines, too late.
#        The script quotes the correction only as "No... ¿Cuándo?"; its mirror for the other question is "No... ¿De quién?" (derived, not quoted).
#        `invitados` {n}: set to 0 at the turn (no one at the gate yet); the guests' climb and the final count are `pregunta109` and `final109` {n}.
#   110  Who comes in (ga, gb) is dealt from the two the script names (piraguero, senora); the third guest (step 8) is `joven`, who speaks nothing. The three plans are dealt out (pa, pb, pc): A's and B's differ and the third guest's plan is the one left (pc).
#        `lleva110` {quien, a, ok}: a = the place (comida, jugos, hamaca, or grama for a wrong touch); right: ok 1 (he settles, abuela lights a lantern), wrong: ok 0 runs in time with the correction line (`con`) and Luis takes him across, as the Needs list words it;
#        the sign's touch after a wrong move then has nothing left to do (no lantern lights). `encendidos` {n}: 0 at the turn (nothing lit); `final110` {n} = the lanterns lit = 3 minus the steps lost.
#        `tests` is the literal "voy a" (the script: a miss is filed under voy a).
#   `gesto` targets the script does not name: 108 step 2 Carmen points at the wall (a = muralla); 110 step 4 "as she names each, he lifts a hand" = three `mano` of the frog run in time with her line.
#   Every story sets its own states at the start (hora, fiesta): every story starts fresh. 108 and 109 start in the afternoon (tarde) without the party table; 110 at night (noche: the lamps at the gate are lit) with it (fiesta 1);
#   108's ending sets hora ocaso ("Evening comes").
import json,glob,os,re,collections,unicodedata
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
PEPE="pepe"   # the script says `don_pepe`; the recorded clips of Don Pepe carry `pepe` (see the header)
AB=lambda t:D("abuela","Abuela",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
PE=lambda t:D(PEPE,"Don Pepe",t); MA=lambda t:D("maestra","La maestra",t); PI=lambda t:D("piraguero","El piragüero",t)
GUEST={"senora":"La señora","joven":"El joven","piraguero":"El piragüero"}
GU=lambda g,t:D(g,GUEST[g],t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time (people walking in together): all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
def START(hora,fiesta=0): return {"set":{"hora":hora,"fiesta":fiesta}}   # every story starts fresh
MINE=("la-fiesta","de-quien-cuando","vamos-a-jugar")   # this generator's stories: not seen
PLACE10=MINE+("la-musica","quieres-bailar","que-bueno","la-sorpresa","las-velas","para-ti","todos-en-la-foto","por-que-no-bailas","nos-vemos")   # the stories of El fuerte: none is read here (neither for reuse nor as earlier words)
# a clip whose text and speaker are already recorded under another id keeps that id (nothing is recorded twice); the stories of this run feed it too, in order.
# Ties go to the id most used, then to the earliest story of the course.
ORD={}
for i,s in enumerate(re.findall(r'"([a-z0-9-]+)"',"".join(re.findall(r'cuentos:\[(.*?)\]',open("curso.js",encoding="utf-8").read(),re.S)))): ORD.setdefault(s,i)
EX=collections.defaultdict(dict)   # (who, habla, text) -> {clip id: [stories that have it, first place in the course]}
def ex_add(cid,cl,o=9999):
    e=EX[(cl.get("who"),cl.get("habla"),cl["text"])].setdefault(cid,[0,o]); e[0]+=1; e[1]=min(e[1],o)
for f in sorted(glob.glob("cuentos/*.json")):
    nm=os.path.basename(f)[:-5]
    if nm in PLACE10 or nm.startswith("z"): continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items(): ex_add(cid,cl,ORD.get(nm,9999))
def best(k): return min(EX[k],key=lambda cid:(-EX[k][cid][0],EX[k][cid][1],cid))
DIN=set()   # ids that are put together in the story ("c109_$ga_$qa"): never renamed
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
# What he hears when he pokes a person or a thing already recorded (the new ones add nothing: don Pepe, la maestra, the wall, the flag, the paper, the lanterns, the food, the jugs, the hammock, the grass)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "piraguero":("b_n_piraguero",N("Es el piragüero.")),"senora":("b_n_senora",N("Es una señora.")),"joven":("b_n_joven",N("Es un joven.")),"puerta":("puerta",N("Es la puerta."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}

# ---------------- 108. La fiesta ----------------
# Carmen, untangling the lanterns' strings, says where the next lantern goes: the wall or the flag's pole (which comes first is drawn: pa, pb the other one). The gate has a hook too and can be touched; it is never asked for.
# Right: the frog hangs it there and comes back. A miss: he holds it up at the place he touched, "No, Coquí. En la <place>.", a gust takes it over the wall; the sign is on the right place; he hops there with nothing to hang and comes back.
nm,nc=nombres("luis","carmen","coqui","puerta"); c=dict(comunes); c.update(nc)
c.update({"c108_l_fuerte":L("Mira, Coquí: el fuerte. Es grande y es viejo."),"c108_q_puerta":N("¿Dónde está la puerta del fuerte?"),"c108_l_fiesta":L("Hoy hay una fiesta en el fuerte. ¿Quieres venir?"),"c108_cq_quiero":T("¡Sí, quiero!"),
 "c108_ca_muralla":CA("Esta es la muralla del fuerte."),"c108_q_muralla":N("¿Dónde está la muralla?"),"c108_ca_cuidado":CA("¡Cuidado, Coquí! La muralla es alta."),
 "c108_l_bandera":L("Y allá arriba está la bandera."),"c108_q_bandera":N("¿Dónde está la bandera?"),"c108_ca_viento":CA("Hay viento. Mira la bandera."),
 "c108_l_hola":L("¡Hola! Hoy hay una fiesta en el fuerte. ¿Quieres venir?"),"c108_ca_para":CA("Para la fiesta: una luz en la puerta, una en la muralla y una en la bandera."),
 "c108_l_hola2":L("¡Hola! Hay una fiesta. ¿Quieres venir?"),
 "c108_ca_gusta":CA("Mira, Coquí. ¿Te gusta?"),"c108_cq_bonito":T("¡Qué bonito!"),"c108_fin":N("Hoy hay una fiesta en el fuerte. ¡Hay luz en el fuerte!")})
for p in ("muralla","bandera"):   # what Carmen says about the next lantern, and the correction for each
    c["c108_va_%s"%p]=CA("Esta luz va en la %s."%p); c["c108_no_%s"%p]=CA("No, Coquí. En la %s."%p); DIN.update(["c108_va_%s"%p,"c108_no_%s"%p])
VARS108={"pa":["muralla","bandera"],"pb":["muralla","bandera"]}
def ronda108(s):
    # p: the place of this round; h: the place a lantern hangs at when the round ends (p when the first touch was right, "-" when the lantern was lost). Options: the wall, the flag, the gate (never asked for).
    p,h="p"+s,"h"+s
    return [{"decide":"do","options":["muralla","bandera","puerta"],"pick":"$"+p,"tests":"$"+p,"lock":True,"lead":[],"line":"c108_va_$"+p,
      "right":[{"calc":h,"cond":"ok","then":"$"+p,"else":"-"},
               {"if":"ok","then":[act("farol108",donde="$"+p,ok=1),act("ir",a="junto_carmen"),OK],"else":[act("ir",a="gancho_$"+p),act("ir",a="junto_carmen")]}],
      "wrong":con(act("farol108",donde="$x",ok=0),"c108_no_$"+p)+X}]
s108={"id":"la-fiesta","title":"La fiesta","place":"El fuerte","scene":"subida","next":"de-quien-cuando",
 "goal":"Hang each paper lantern from Carmen's basket where she says (on the wall or on the flag's pole) so that the three lanterns for tonight's party are all lit by the fort at evening: a lantern held up at the wrong place is taken out of the frog's hands by a gust of wind and sails over the wall.",
 "stake":{"thing":"faroles","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["fuerte","muralla","bandera","fiesta","¿quieres venir?"],"formas_foco":{},
 "back_again":["puerta","luz","hoy","hay","viento","grande","viejo","mira","quiero","aquí","allá","arriba","noche","bonito","me gusta","sí","no","gracias","hola"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START("tarde")]+juntos(act("llega",quien="luis",a="camino3"),act("llega",quien="carmen",a="camino4"))+[{"wait":500},
  # 1: Luis shows the fort; signed ask on the gate: the frog hops up the path to it; Luis invites the frog; a speaking turn (quiero)
  {"dots":1},"c108_l_fuerte",ask("puerta","c108_q_puerta",after=[act("ir",a="ante_puerta")]),"c108_l_fiesta","c108_cq_quiero",
  # 2: Carmen points along the wall; signed ask on the wall (away from the gate): the frog hops onto it and walks along its top
  {"dots":2},gesto("carmen","senala",a="muralla"),"c108_ca_muralla",ask("muralla","c108_q_muralla",after=[act("ir",a="muro_coqui")]),"c108_ca_cuidado",
  # 3: the flag snaps in the wind; signed ask on the flag: it waves
  {"dots":3},act("bandera108"),"c108_l_bandera",ask("bandera","c108_q_bandera",after=[act("bandera108")]),"c108_ca_viento",
  # 4: a boy comes by with his dog (Luis unrolls his paper, the dog barks, Carmen lifts a lantern and it glows: no act named); the boy nods hard; Carmen names the three places and each hook shines in turn
  {"dots":4},act("llega",quien="nino",a="camino2"),"c108_l_hola",gesto("nino","si")]+con(act("ganchos108"),"c108_ca_para")+[
  # 5: the turn: Luis goes down the path and stops a girl; Carmen sits by the tree, the frog hops down beside her (she takes out the first lantern and the wind pulls at it: no act named); the card shows two places
  {"dots":5}]+juntos(act("llega",quien="luis",a="camino4"),act("llega",quien="nina",a="camino3"))+["c108_l_hola2"]+juntos(act("llega",quien="carmen",a="arbol"),act("ir",a="junto_carmen"))+[CARD,{"wait":400},
  # 6: A. 7: B. Which place comes first: drawn (pb is the other one)
  {"draw":"pa","options":["muralla","bandera"],"other":"pb"},
  {"dots":6}]+ronda108("a")+[{"dots":7}]+ronda108("b"),
 "final":[{"dots":8},{"set":{"hora":"ocaso"}},act("faroles",donde="$ha,$hb"),act("final108"),   # 8: evening comes; Carmen hangs the last lantern on the gate herself; the lanterns lit, each where it hangs (the wall's and the flag's only if the round was right)
  {"dots":9}]+juntos(act("llega",quien="luis",a="camino1"),act("llega",quien="nino",a="camino2"),act("llega",quien="nina",a="camino3"))+["c108_ca_gusta","c108_cq_bonito","c108_fin",act("fin")],   # 9: Luis comes back with people behind him; a speaking turn (bonito)
 "leer":["c108_l_fuerte","c108_q_puerta","c108_l_fiesta","c108_cq_quiero","c108_ca_muralla","c108_q_muralla","c108_ca_cuidado","c108_l_bandera","c108_q_bandera","c108_ca_viento","c108_l_hola","c108_ca_para","c108_l_hola2",
  "c108_va_muralla","c108_no_muralla","c108_va_bandera","c108_ca_gusta","c108_cq_bonito","c108_fin"]}
s108=reuse(s108,{"c108_cq_quiero":TG(("quiero",["quiero","sí quiero"])),"c108_cq_bonito":TG(("bonito",["bonito","qué bonito","sí bonito"]))})
json.dump(s108,open("cuentos/la-fiesta.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 109. ¿De quién? ¿Cuándo? ----------------
# A passer-by (dealt from the señora and the joven: ga, gb) stops at Luis's paper and asks one of two questions (drawn each round on its own: qa, qb): "¿De quién es?" or "¿Cuándo es?". The frog touches abuela's face (cartel_quien) or the moon over the clock (cartel_cuando).
# Right: the picture shines, "¡Ah! Gracias. Voy.", he goes up to the fort. A miss: the other picture shines, "No... <the question>", he shrugs and walks on; the sign is on the right picture; it shines, too late. The third passer-by (nino) reads the paper himself and goes up.
GUESTS109=["senora","joven"]
nm,nc=nombres("abuela","luis","coqui","piraguero","senora","joven"); c=dict(comunes); c.update(nc)
c.update({"c109_ab_invito":AB("Hoy hay una fiesta en el fuerte. Yo invito a todos."),"c109_l_quien":L("Mira, Coquí. ¿De quién es la fiesta? De abuela."),"c109_l_cuando":L("¿Y cuándo es la fiesta? Hoy, a las siete."),
 "c109_pe_hola":PE("¡Hola, Luis! ¿Una fiesta? ¿De quién es?"),"c109_pe_invita":PE("¡Tu abuela invita! ¿Y cuándo es?"),"c109_l_siete":L("Hoy, a las siete de la noche. Abuela invita a todos."),
 "c109_pe_voy":PE("Voy. Yo traigo jugo."),"c109_l_trae":L("Don Pepe trae jugo. ¿Y quién trae hielo?"),"c109_pi_yo":PI("¡Yo! ¿Cuándo?"),"c109_l_hoy":L("Hoy, a las siete."),
 "c109_pi_hola":PI("¡Hola, Coquí! ¿Cómo estás?"),"c109_cq_bien":T("¡Bien, gracias!"),
 "c109_pi_hielo":PI("Aquí está el hielo. Coquí, ¿quieres una piragua?"),"c109_cq_gracias":T("¡Sí, gracias!"),"c109_fin":N("Abuela invita. La gente trae jugo y hielo. Hoy, a las siete, hay fiesta.")})
for g in GUESTS109:   # the question of each passer-by, the correction for each, and his thanks
    c["c109_%s_quien"%g]=GU(g,"¿Una fiesta? ¿De quién es?"); c["c109_%s_cuando"%g]=GU(g,"¿Una fiesta? ¿Cuándo es?")
    c["c109_no_%s_quien"%g]=GU(g,"No... ¿De quién?"); c["c109_no_%s_cuando"%g]=GU(g,"No... ¿Cuándo?"); c["c109_voy_%s"%g]=GU(g,"¡Ah! Gracias. Voy.")
    DIN.update(["c109_%s_quien"%g,"c109_%s_cuando"%g,"c109_no_%s_quien"%g,"c109_no_%s_cuando"%g,"c109_voy_%s"%g])
VARS109={"ga":GUESTS109,"gb":GUESTS109,"qa":["quien","cuando"],"qb":["quien","cuando"]}
def ronda109(s):
    # g: the passer-by (dealt); q: the question (drawn); k: the picture that answers it. Right: it shines, he thanks and goes up. Wrong: the other picture (x) shines, he frowns at it, "No... <question>", he shrugs and walks on.
    g,q,k="g"+s,"q"+s,"k"+s
    return [{"draw":q,"options":["quien","cuando"]},{"calc":k,"cond":q+"=quien","then":"cartel_quien","else":"cartel_cuando"},act("llega",quien="$"+g,a="junto_cartel"),
     {"decide":"do","options":["cartel_quien","cartel_cuando"],"pick":"$"+k,"tests":"$"+q,"lock":True,"lead":[],"line":"c109_$%s_$%s"%(g,q),
      "right":[act("cartel109",cual="$"+k),{"if":"ok","then":["c109_voy_$"+g,act("pregunta109",quien="$"+g,ok=1),OK]}],
      "wrong":[act("cartel109",cual="$x"),gesto("$"+g,"mira",a="$x"),"c109_no_$%s_$%s"%(g,q),act("pregunta109",quien="$"+g,ok=0)]+X}]
s109={"id":"de-quien-cuando","title":"¿De quién? ¿Cuándo?","place":"El fuerte","scene":"subida","next":"vamos-a-jugar",
 "goal":"Answer each passer-by's question about Luis's paper by touching abuela's face (whose party) or the moon over the clock (when) so that the three people who come up the path become guests at the fort's gate: someone who gets the wrong answer shrugs and walks on.",
 "stake":{"thing":"invitados","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["invita","trae","¿quién?","¿cuándo?"],"formas_foco":{"invita":["invito"],"trae":["traigo"]},
 "back_again":["fiesta","fuerte","abuela","mi","tu","hoy","noche","a las siete","jugo","hielo","voy","yo","¿cómo estás?","bien","gracias","hola","sí","no"],
 "also_heard":[],"names":nm,"palabras":{"quien":"¿quién?","cuando":"¿cuándo?"},"clips":c,
 "beats":[START("tarde"),act("ir",a="piedra"),act("llega",quien="abuela",a="camino2"),{"wait":500},
  # 1: abuela invites everyone and goes up to the gate with her list; Luis taps the paper; signed ask on abuela's picture (his own line), then on the moon over the clock: each shines
  {"dots":1},"c109_ab_invito",act("llega",quien="abuela",a="puerta_abuela"),gesto("luis","senala",a="cartel"),ask("cartel_quien","c109_l_quien",after=[act("cartel109",cual="cartel_quien")]),ask("cartel_cuando","c109_l_cuando",after=[act("cartel109",cual="cartel_cuando")]),
  # 2: don Pepe stops at the paper and asks; signed ask on abuela's picture (his own line): it shines and abuela waves at the gate; signed ask on the moon over the clock (his own line); Luis answers
  {"dots":2},act("llega",quien=PEPE,a="junto_cartel"),ask("cartel_quien","c109_pe_hola",after=[act("cartel109",cual="cartel_quien"),gesto("abuela","saluda")]),ask("cartel_cuando","c109_pe_invita",after=[act("cartel109",cual="cartel_cuando")]),"c109_l_siete",
  # 3: don Pepe brings juice (a small jug on the paper's foot) and goes up; the piragüero comes by, lifts his hand: he brings ice (a block of ice on the paper's foot); he greets the frog; a speaking turn (bien)
  {"dots":3},"c109_pe_voy",act("lista109",que="jugo"),act("sale",quien=PEPE),act("llega",quien="piraguero",a="junto_cartel"),"c109_l_trae",gesto("piraguero","mano"),"c109_pi_yo","c109_l_hoy",act("lista109",que="hielo"),"c109_pi_hola","c109_cq_bien",
  # 4: the turn: Luis runs up to the fort with his list; the frog stays on his stone; three people come up the path, one after another; the card shows two places
  {"dots":4},act("sale",quien="luis"),act("invitados",n=0),{"reparte":["ga","gb"],"options":GUESTS109}]+juntos(act("llega",quien="$ga",a="camino1"),act("llega",quien="$gb",a="camino2"),act("llega",quien="nino",a="camino3"))+[CARD,{"wait":400},
  # 5: A. 6: B (another passer-by). Which passer-by (dealt out of the two) and which question (drawn): afresh each round
  {"dots":5}]+ronda109("a")+[{"dots":6}]+ronda109("b"),
 "final":[{"dots":7},act("llega",quien="nino",a="junto_cartel"),gesto("nino","mira",a="cartel"),act("pregunta109",quien="nino",ok=1),baja3(lambda n:act("final109",n=n)),   # 7: the third passer-by reads the paper himself and goes up; at the gate three guests wait with abuela, two, or one
  {"dots":8},act("llega",quien="piraguero",a="camino1"),"c109_pi_hielo","c109_cq_gracias",act("piragua109"),"c109_fin",act("fin")],   # 8: the piragüero pushes his cart up to the gate; a speaking turn (gracias); he gets a small piragua
 "leer":["c109_ab_invito","c109_l_quien","c109_l_cuando","c109_pe_hola","c109_pe_invita","c109_l_siete","c109_pe_voy","c109_l_trae","c109_pi_yo","c109_l_hoy","c109_pi_hola","c109_cq_bien",
  "c109_senora_cuando","c109_voy_senora","c109_no_senora_cuando","c109_joven_quien","c109_voy_joven","c109_pi_hielo","c109_cq_gracias","c109_fin"]}
s109=reuse(s109,{"c109_cq_bien":TG(("bien",["bien","muy bien","bien gracias"])),"c109_cq_gracias":TG(("gracias",["gracias","sí gracias"]))})
json.dump(s109,open("cuentos/de-quien-cuando.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 110. Vamos a jugar ----------------
# A guest (dealt from the piragüero and the señora: ga, gb) comes in at the gate and says what he is going to do (dealt out of the three plans: pa, pb, and the third guest's pc is the one left): "Voy a comer." / "Voy a tomar algo." / "Voy a dormir."
# The frog touches the food, the jugs, the hammock or the grass. Right: he leads him there and abuela lights a lantern. A miss: he leads him to the place he touched, "No, Coquí. <what he said>", Luis takes him across, no lantern.
GUESTS110=["piraguero","senora"]
PLAN={"comer":("comida","Voy a comer."),"tomar":("jugos","Voy a tomar algo."),"dormir":("hamaca","Voy a dormir.")}
nm,nc=nombres("abuela","luis","carmen","coqui","piraguero","senora","joven","puerta"); c=dict(comunes); c.update(nc)
c.update({"c110_pe_hambre":PE("¡Tengo hambre! Voy a comer."),"c110_pe_acomer":PE("¡A comer!"),"c110_ma_sed":MA("¡Tengo sed! Voy a tomar algo."),"c110_ma_atomar":MA("¡A tomar jugo!"),
 "c110_ca_sueno":CA("Tengo sueño. Voy a dormir."),"c110_ca_adormir":CA("A dormir..."),
 "c110_ab_van":AB("Don Pepe va a comer, la maestra va a tomar algo y Carmen va a dormir."),"c110_l_vamos":L("¡Carmen! ¡Vamos a jugar!"),"c110_ca_si":CA("¡Sí! Vamos a jugar juntos. Coquí, ¿tú también?"),"c110_cq_tambien":T("¡Yo también!"),"c110_l_tres":L("¡Los tres juntos!"),
 "c110_ab_hambre":AB("¿Y tú, Coquí? ¿Tienes hambre o tienes sed?"),"c110_cq_hambre":T("¡Tengo hambre!"),"c110_ab_vamos":AB("¡Vamos a comer juntos!"),"c110_fin":N("En la fiesta, la gente come, toma jugo y juega. Juntos.")})
for g in GUESTS110:   # what each guest says he is going to do, and the correction for each
    for pl,(lugar,frase) in PLAN.items():
        c["c110_%s_%s"%(g,pl)]=GU(g,frase); c["c110_no_%s_%s"%(g,pl)]=GU(g,"No, Coquí. "+frase); DIN.update(["c110_%s_%s"%(g,pl),"c110_no_%s_%s"%(g,pl)])
VARS110={"ga":GUESTS110,"gb":GUESTS110,"pa":list(PLAN),"pb":list(PLAN)}
def ronda110(s):
    # g: the guest (dealt); p: his plan (dealt); k: the place of the plan (comida, jugos, hamaca). Right: the frog leads him there and abuela lights a lantern. Wrong: he is led to the place touched (x), the correction, Luis takes him across; no lantern.
    g,p,k="g"+s,"p"+s,"k"+s
    return [{"calc":k,"cond":p+"=comer","then":"comida","else":"jugos"},{"calc":k,"cond":p+"=dormir","then":"hamaca","else":"$"+k},act("llega",quien="$"+g,a="camino1"),
     {"decide":"do","options":["comida","jugos","hamaca","grama"],"pick":"$"+k,"tests":"voy a","lock":True,"lead":[],"line":"c110_$%s_$%s"%(g,p),
      "right":[{"if":"ok","then":[act("lleva110",quien="$"+g,a="$"+k,ok=1),OK]}],
      "wrong":con(act("lleva110",quien="$"+g,a="$x",ok=0),"c110_no_$%s_$%s"%(g,p))+X}]
s110={"id":"vamos-a-jugar","title":"Vamos a jugar","place":"El fuerte","scene":"subida","next":"la-musica",
 "goal":"Lead each guest who comes in at the gate to the food, the jugs or the hammock, as he says what he is going to do, so that abuela lights a paper lantern for each of the three guests: a guest led to the wrong place stands there lost, Luis has to fetch him, and no lantern is lit for him.",
 "stake":{"thing":"encendidos","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["voy a","vamos a","juntos"],"formas_foco":{"voy a":["va a"]},
 "back_again":["come","toma","duerme","juega","fiesta","mesa","jugo","bola","tengo hambre","tengo sed","tiene sueño","¿algo más?","también","tres","yo","tú","sí","no","gracias"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START("noche",1),act("llega",quien="abuela",a="puerta_abuela"),act("ir",a="ante_puerta"),act("llega",quien="carmen",a="grama3"),{"wait":500},
  # 1: don Pepe comes in rubbing his stomach; his line is the signed ask on the food: the frog leads him there; he eats (no act named)
  {"dots":1},act("llega",quien=PEPE,a="camino1"),gesto(PEPE,"barriga"),ask("comida","c110_pe_hambre",after=[act("llega",quien=PEPE,a="mesa_comida")]),"c110_pe_acomer",
  # 2: the maestra comes in fanning herself; her line is the signed ask on the jugs; she pours a glass (no act named)
  {"dots":2},act("llega",quien="maestra",a="camino1"),gesto("maestra","abanico"),ask("jugos","c110_ma_sed",after=[act("llega",quien="maestra",a="mesa_jugos")]),"c110_ma_atomar",
  # 3: Carmen yawns; her line is the signed ask on the hammock: she climbs in
  {"dots":3},gesto("carmen","bosteza"),ask("hamaca","c110_ca_sueno",after=[act("llega",quien="carmen",a="hamaca_dentro")]),"c110_ca_adormir",
  # 4: abuela says what each is going to do and, as she names each, the frog lifts a hand; Luis runs in with the ball; Carmen jumps out; a speaking turn (también); they play with the ball
  {"dots":4}]+[gesto("coqui","mano",suelto=1),gesto("coqui","mano",suelto=1),gesto("coqui","mano",suelto=1),"c110_ab_van",act("ya"),act("llega",quien="luis",a="grama1"),"c110_l_vamos",act("llega",quien="carmen",a="grama2"),"c110_ca_si","c110_cq_tambien",act("juegan110"),"c110_l_tres",
  # 5: the turn: the food, the jugs, the hammock and the grass are left empty; the frog goes back to the gate (abuela is there with her match); nothing is lit; the card shows two places
  {"dots":5},act("despeja110"),act("ir",a="ante_puerta"),act("encendidos",n=0),CARD,{"wait":400},
  # 6: A. 7: B. Which guest (dealt out of the two) and what he is going to do (dealt out of the three plans, none twice): afresh each round
  {"reparte":["ga","gb"],"options":GUESTS110},{"reparte":["pa","pb","pc"],"options":list(PLAN)},
  {"dots":6}]+ronda110("a")+[{"dots":7}]+ronda110("b"),
 "final":[{"dots":8},{"calc":"kc","cond":"pc=comer","then":"comida","else":"jugos"},{"calc":"kc","cond":"pc=dormir","then":"hamaca","else":"$kc"},act("llega",quien="joven",a="camino1"),act("lleva110",quien="joven",a="$kc",ok=1),baja3(lambda n:act("final110",n=n)),   # 8: the third guest finds his own place (the plan that is left) and abuela lights a lantern for him; three lit, two, or one
  {"dots":9},"c110_ab_hambre","c110_cq_hambre","c110_ab_vamos",act("ir",a="mesa_comida"),act("llega",quien="abuela",a="mesa_jugos"),"c110_fin",act("fin")],   # 9: abuela puts down her match (no act named); a speaking turn (tengo hambre); they go to the table
 "leer":["c110_pe_hambre","c110_pe_acomer","c110_ma_sed","c110_ma_atomar","c110_ca_sueno","c110_ca_adormir","c110_ab_van","c110_l_vamos","c110_ca_si","c110_cq_tambien","c110_l_tres",
  "c110_piraguero_dormir","c110_no_piraguero_dormir","c110_senora_comer","c110_ab_hambre","c110_cq_hambre","c110_ab_vamos","c110_fin"]}
s110=reuse(s110,{"c110_cq_tambien":TG(("también",["yo también","también"])),"c110_cq_hambre":TG(("tengo hambre",["tengo hambre","hambre"]))})
json.dump(s110,open("cuentos/vamos-a-jugar.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files on disk of places 1 to 9, and the earlier stories of this run).
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in PLACE10: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s108,s109,s110):
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            w=t["palabra"]
            if w not in EARLIER: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,w)
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
for st,VARS in ((s108,VARS108),(s109,VARS109),(s110,VARS110)):
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
