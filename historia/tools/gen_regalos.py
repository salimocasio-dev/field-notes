# Los regalos (place 10, El fuerte, scene 3 of 4): stories 114, 115, 116. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/regalos.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `regalos` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: the generators of places 4 to 9 first (each sees only what was recorded before it), then the four of El fuerte in order (subida, musica, this one, muralla).
#   Speaking turns of this scene: 114 me gusta, contento; 115 tú, un poco; 116 ella, para mí. All are words of places 1 to 9 (que-quieres, el-bebe-duerme, quien-eres-tu, cafe-con-azucar, la-foto, las-bebidas):
#   no word of another story of place 10 is a turn here. The check at the end warns (TURN ON A WORD IN NO EARLIER FOCUS LIST) if one is not.
#
# Where the script or its Needs list leaves a value open, this file fixes it in ONE place (and the report says so):
#   Things as act values: a thing he can touch is passed to the acts as its own key (the convention of the other scenes). `lleva114` {que}: bizcocho, regalo, flores. `foto115` {cual}: foto_3m, foto_3a, foto_7m, foto_7a.
#       `empuja116` {a}: carmen, abuelo, or the guest's key (pepe, maestra, piraguero). A wrong touch (`$x`) is the thing key itself.
#   114: `cortina114` {como}: the script names the argument and not its values: "cierra" (the one use: the frog pulls the curtain shut, step 1). `suena114` {quien}: abuelo (step 3, before the ask), coqui (after the touch).
#       `pinzas` {n} = the curtain's pegs: 3 at the start, 2 / 1 after a loss; `final114` {n} = what is left. A wrong move runs `lleva114` ok 0 started loose with the correction line (the script puts the line between the carrying and the hurrying back).
#       Round A: touch one of three (bizcocho, regalo, flores); round B: the thing round A did not ask for, or the flowers (round A's thing is on the table: the script's "one in two in round B"). Which comes first is drawn (qa; qb the other).
#   115: the stake is 7 candles (the script) but a miss costs two of them: `velas` {n} = 7 once lit (`prende115`), 5 after the first miss, 3 after the second; `final115` {n} = 7, 5, 3. The engine counts one loss per miss (lost 0, 1, 2).
#       The photos are keyed foto_3m, foto_3a, foto_7m, foto_7a (the Needs list's things); the draws use their codes: na (3 or 7; nb the other pair), ma / mb (m or a): "foto_$na$ma". Round B's options are the three photos still on the table
#       (the pair of round B and the photo of round A's pair that was not asked: the script's "one in three in round B"). `tests`: mes or año (the variable holds "ano", `palabras` maps it).
#       The photos' order on the table is drawn (`reparte` into fa fb fc fd) and given to `viento115` as fotos1..fotos4 (the spots' names): the Needs list names no argument for this value (reported).
#       Step 7: `final115` {n} is taken to hang the last two photos and bring abuelo down (no act of its own); `sopla115` in step 8 after abuela's line.
#   116: guests: ga, gb are dealt out of pepe, maestra, piraguero (`reparte`: round B's is not round A's); what each does (va, vb: da or recibe) is drawn on its own. The 12 lines of the game are clips: "Don Pepe da el regalo." ... "El piragüero recibe el regalo."
#       and their 6 corrections ("¡No, Coquí! La maestra da el regalo."). Right: `empuja116` {a, ok 1}: a = the one who receives (carmen if the guest gives, the guest if he receives); the other claps (`aplaude`) and the star, both only when the first touch was right.
#       Wrong: `empuja116` {a = the one touched, ok 0}, the correction, the loss, the cross; the sign's touch then runs `empuja116` ok 1 on the right one. `sorpresas` {n} = 3 at the start, 2 / 1 after a loss; `final116` {n}.
#       `abre116` {quien, que}: que = sombrero (Carmen's hat), abanico (abuelo's fan), sombrerito (the frog's very small hat): the script names the things, not these keys.
#       `empuja116` is used for every push, in the opening too (ok 1); the opening's openings are `abre116`. If `empuja116` opens by itself (its Needs text says "he opens it"), steps 1 to 3 would open twice (reported).
#       Between the rounds guest A goes back to his waiting place (`llega` to espera1 / 2 / 3: pepe, maestra, piraguero: the order of the script's Start), so guest B has the stool's right side to himself.
#   Where the people stand at the start (`llega`, `ir`), from the spots of the Needs list (the scene has no default for them):
#       114: abuela tras_mesa, luis arco, abuelo junto_banco, the frog mesa_coqui (the script's Start). 115: carmen tras_mesa2, abuela tras_mesa (beside her), abuelo junto_banco (the script says "beside the table": no such spot), luis arco,
#       pepe espera1 and maestra espera2 (the script says "behind": the Needs list has no such spot), the frog mesa_coqui. 116: carmen banqueta_izq, abuelo banqueta_der (he gives across the stool), abuela tras_mesa, luis arco,
#       the guests espera1 to espera3, the frog mesa_coqui; at the turn abuelo goes to junto_banco, so the guest can come to banqueta_der.
#   114, step 7: "Everybody gets down behind it" = `llega` abuela, abuelo, luis to `escondidos` (the Needs list's spot), then `final114` {n} (Carmen at the arch and the curtain, by the pegs). "Luis puts the flowers on the table" has no act (reported).
#   `gesto` targets the script does not name: 114 step 4 "everybody stands still" = abuela, abuelo, luis (`quieto`) while the shadow comes and goes; 115 step 1 Luis counts on his fingers (`dedos`) while the frog carries the candles;
#       116 the round's "each with both hands held out, both looking at abuela" = `manos` and `mira` a = abuela, Carmen and the guest; step 7 "everybody looks at the frog" = the seven people (`mira` a = coqui).
#   Every story sets its own states at the start (hora noche, the count): every story starts fresh.
import json,glob,os,re,collections,unicodedata
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); ABO=lambda t:D("abuelo","Abuelo",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
PE=lambda t:D("pepe","Don Pepe",t); MAE=lambda t:D("maestra","La maestra",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def juntos(*acts): return [dict(a,suelto=1) for a in acts]+[act("ya")]        # several acts at the same time (people walking in together, everybody looking): all loose, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
START={"set":{"hora":"noche"}}                            # every story starts fresh
MINE=("la-sorpresa","las-velas","para-ti")               # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c116_pepe_da"): never renamed
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
    # the script's bracketed forms (lower case, no punctuation), and each one again without its accent
    out=[]
    for w,f in p:
        fs=[]
        for x in f:
            x=re.sub(r"[^\w ]","",x.lower()).strip()
            for y in (x,noacc(x)):
                if y not in fs: fs.append(y)
        out.append({"palabra":w,"formas":fs})
    return out
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}
# What he hears when he pokes a person already recorded (don Pepe and la maestra have no such clip: not made up)
NM={"abuela":("abuela",N("Esta es abuela.")),"abuelo":("n_abuelo",N("Este es abuelo.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "piraguero":("b_n_piraguero",N("Es el piragüero."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}
def baja7(n):
    # 115: seven candles, a miss puts out two: 7, 5, 3
    return {"if":"lost=0","then":[n(7)],"else":[{"if":"lost=1","then":[n(5)],"else":[n(3)]}]}
def resta7(n):
    return {"if":"lost=0","then":[n(5)],"else":[n(3)]}

# ---------------- 114. La sorpresa ----------------
# Abuela, smoothing the cloth with her eyes on her hands, asks for a thing from the bench: the present (el regalo) or the cake (el bizcocho), which comes first drawn; the flowers are touched in both rounds and never asked for.
# A miss: the frog carries another thing over, abuela says no, he hurries it back to the bench, runs into the curtain's edge and a peg flies off; the curtain sags; the sign is on the right thing and he touches it.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c114_ab_cumple":AB("Coquí, hoy es el cumpleaños de Carmen."),"c114_l_shh":L("¡Shh! Es una sorpresa."),"c114_l_baila":L("Carmen baila. No ve la sorpresa."),
 "c114_ab_bizcocho":AB("Para el cumpleaños hay un bizcocho."),"c114_ab_este":AB("Este es el bizcocho de Carmen."),"c114_l_gusta":L("Coquí, ¿te gusta el bizcocho?"),"c114_cq_gusta":T("¡Sí, me gusta!"),
 "c114_abo_regalo":ABO("Y yo tengo un regalo para Carmen."),"c114_l_regalo":L("El regalo es una sorpresa también."),"c114_ab_grande":AB("¡Qué regalo grande!"),
 "c114_l_ahi":L("¡Ahí viene Carmen!"),"c114_l_no_baila":L("No. Carmen baila."),
 "c114_l_sorpresa":L("¡Sorpresa!"),"c114_ca_bizcocho":CA("¡Un bizcocho! ¡Y un regalo! Coquí, ¿cómo estás?"),"c114_cq_contento":T("¡Contento!"),
 "c114_fin":N("Hoy es el cumpleaños de Carmen. Hay un bizcocho, un regalo y una sorpresa.")})
for k in ("regalo","bizcocho"):   # the request (the two things) and its correction
    c["c114_trae_%s"%k]=AB("Coquí, trae el %s, por favor."%k); c["c114_no_%s"%k]=AB("No, Coquí. El %s."%k); DIN.update(["c114_trae_%s"%k,"c114_no_%s"%k])
VARS114={"qa":["regalo","bizcocho"],"qb":["regalo","bizcocho"]}
def ronda114(s):
    # q: the thing asked for (drawn in A; B's is the other one). A: three things to touch; B: the thing asked for or the flowers (round A's thing is on the table).
    # Right: the frog carries it to the table, abuela sets it on the cloth. Wrong: the other thing (x) carried, the line, a peg flies off (loose, with the line), the pegs' count, the cross; the sign's touch carries the right one.
    q="q"+s
    first=[{"draw":"qa","options":["regalo","bizcocho"],"other":"qb"}] if s=="a" else []
    ops=["bizcocho","regalo","flores"] if s=="a" else ["$qb","flores"]
    return first+[{"decide":"do","options":ops,"pick":"$"+q,"tests":"$"+q,"lock":True,"lead":[],"line":"c114_trae_$"+q,
      "right":[act("lleva114",que="$"+q,ok=1),star],
      "wrong":con(act("lleva114",que="$x",ok=0),"c114_no_$"+q)+[resta(lambda n:act("pinzas",n=n))]+X}]
s114={"id":"la-sorpresa","title":"La sorpresa","place":"El fuerte","scene":"regalos","next":"las-velas",
 "goal":"Lay Carmen's surprise birthday table behind the curtain across the arch, fetching from the bench the present or the cake that abuela asks for, so that the curtain keeps its three pegs: a wrong thing has to be hurried back to the bench, the frog runs into the curtain's edge, a peg flies off, and more of the table shows from the dance floor.",
 "stake":{"thing":"pinzas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["regalo","bizcocho","cumpleaños","sorpresa"],"formas_foco":{},
 "back_again":["fiesta","hoy","baila","ve","trae","flor","mesa","grande","bonito","me gusta","contento","¿cómo estás?","viene","tengo","también","por favor","gracias","sí","no"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START,act("pinzas",n=3)]+juntos(act("llega",quien="abuela",a="tras_mesa"),act("llega",quien="luis",a="arco"),act("llega",quien="abuelo",a="junto_banco"),act("ir",a="mesa_coqui"))+[{"wait":500},
  # 1: abuela says it is Carmen's birthday; Luis lays a finger on his lips; his line is the signed ask on the curtain: the frog pulls it shut across the arch, the three pegs hold it
  {"dots":1},"c114_ab_cumple",gesto("luis","silencio"),ask("cortina","c114_l_shh",after=[act("cortina114",como="cierra")]),"c114_l_baila",
  # 2: abuela's line is the signed ask on the cake: the frog lifts its cover off; a speaking turn (me gusta)
  {"dots":2},ask("bizcocho","c114_ab_bizcocho",after=[act("tapa114")]),"c114_ab_este","c114_l_gusta","c114_cq_gusta",
  # 3: abuelo shakes the box by his ear; his line is the signed ask on the box: the frog shakes it too (abuelo puts it back on the bench: no act named)
  {"dots":3},act("suena114",quien="abuelo"),ask("regalo","c114_abo_regalo",after=[act("suena114",quien="coqui")]),"c114_l_regalo","c114_ab_grande",
  # 4: the turn: abuela shakes out the bright cloth (and smooths it: `mantel114` is both); Carmen's shadow comes to the curtain and goes while Luis says she is coming; everybody stands still; the card shows two places
  {"dots":4},act("mantel114")]+[dict(gesto(q,"quieto"),suelto=1) for q in ("abuela","abuelo","luis")]+con(act("sombra114"),"c114_l_ahi")+["c114_l_no_baila",CARD,{"wait":400},
  # 5: A. 6: B. Which thing comes first: drawn
  {"dots":5}]+ronda114("a")+[{"dots":6}]+ronda114("b"),
 "final":[{"dots":7}]+juntos(act("llega",quien="abuela",a="escondidos"),act("llega",quien="abuelo",a="escondidos"),act("llega",quien="luis",a="escondidos"))+[baja3(lambda n:act("final114",n=n)),   # 7: Luis puts the flowers on the table (no act named); everybody down behind it; Carmen comes to the arch: the curtain by the pegs left
  {"dots":8},"c114_l_sorpresa","c114_ca_bizcocho","c114_cq_contento","c114_fin",act("fin")],   # 8: "¡Sorpresa!"; a speaking turn (contento)
 "leer":["c114_ab_cumple","c114_l_shh","c114_l_baila","c114_ab_bizcocho","c114_ab_este","c114_l_gusta","c114_cq_gusta","c114_abo_regalo","c114_l_regalo","c114_ab_grande","c114_l_ahi","c114_l_no_baila",
  "c114_trae_regalo","c114_trae_bizcocho","c114_l_sorpresa","c114_ca_bizcocho","c114_cq_contento","c114_fin"]}
s114=reuse(s114,{"c114_cq_gusta":TG(("me gusta",["me gusta","sí me gusta"])),"c114_cq_contento":TG(("contento",["contento","muy contento"]))})
json.dump(s114,open("cuentos/la-sorpresa.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 115. Las velas ----------------
# Abuelo, on his stool with his eyes on the line and its pegs, asks for a photo by how old Carmen is in it: tres meses, tres años, siete meses, siete años. The four photos are two pairs with the same number; round A asks one photo of one pair (drawn),
# round B one photo of the other pair (drawn): the number leaves two photos, only meses or años says which. A miss: abuelo hangs it, looks, says no, takes it down; the wind gets past abuela's hands and two candles go out.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c115_ab_feliz":AB("¡Feliz cumpleaños, Carmen! ¿Cuántos años tienes?"),"c115_ca_siete":CA("¡Tengo siete años!"),"c115_pepe_felicidades":PE("¡Felicidades, Carmen!"),
 "c115_ab_velas":AB("Coquí, trae las velas, por favor."),"c115_l_cuenta":L("Una, dos, tres, cuatro, cinco, seis... ¡siete velitas!"),
 "c115_abo_bebe":ABO("Mira, Coquí. Aquí Carmen es una bebé. Tiene tres meses."),"c115_abo_tres":ABO("Y aquí Carmen tiene tres años."),"c115_ca_chiquita":CA("¿Tres meses? ¡Qué chiquita!"),
 "c115_abo_siete":ABO("Aquí tiene siete meses. Y aquí, siete años."),"c115_ca_quien":CA("Mira, Coquí. ¿Quién es?"),"c115_cq_tu":T("¡Tú!"),"c115_ca_momento":CA("¡Un momento! Faltan mis fotos."),
 "c115_ab_feliz2":AB("¡Feliz cumpleaños, Carmen!"),"c115_mae_felicidades":MAE("¡Felicidades!"),"c115_abo_quieres":ABO("Coquí, ¿quieres bizcocho?"),"c115_cq_poco":T("¡Sí, un poco!"),
 "c115_fin":N("Carmen tiene siete años. Hay siete velitas en el bizcocho. ¡Felicidades!")})
FOTO={"3m":"tres meses","3a":"tres años","7m":"siete meses","7a":"siete años"}
for k,w in FOTO.items():   # the request (four photos) and its correction
    c["c115_foto_%s"%k]=ABO("Ahora, la foto de los %s."%w); c["c115_no_%s"%k]=ABO("¡No, Coquí! La foto de los %s."%w); DIN.update(["c115_foto_%s"%k,"c115_no_%s"%k])
VARS115={"na":["3","7"],"nb":["3","7"],"ma":["m","a"],"mb":["m","a"]}
def ronda115(s):
    # n: the number of the pair (3 or 7), m: m (meses) or a (años), both drawn; round B's pair is the other pair. t: the word that decides (mes, año). The photo asked is "foto_$n$m".
    # A: the four photos. B: the three still on the table (the two of its pair, and the one of A's pair that was not asked): bm, bn = the two of B's pair, oa = the letter of A's other photo.
    n,m,t="n"+s,"m"+s,"t"+s
    pre=[{"draw":"na","options":["3","7"],"other":"nb"}] if s=="a" else []
    pre+=[{"draw":m,"options":["m","a"]},{"calc":t,"cond":m+"=m","then":"mes","else":"ano"}]
    if s=="a": ops=["foto_3m","foto_3a","foto_7m","foto_7a"]
    else:
        pre+=[{"calc":"oa","cond":"ma=m","then":"a","else":"m"},{"calc":"bm","cond":"nb=3","then":"foto_3m","else":"foto_7m"},{"calc":"bn","cond":"nb=3","then":"foto_3a","else":"foto_7a"}]
        ops=["$bm","$bn","foto_$na$oa"]
    return pre+[{"decide":"do","options":ops,"pick":"foto_$%s$%s"%(n,m),"tests":"$"+t,"lock":True,"lead":[],"line":"c115_foto_$%s$%s"%(n,m),
      "right":[act("foto115",cual="foto_$%s$%s"%(n,m),ok=1),star],
      "wrong":con(act("foto115",cual="$x",ok=0),"c115_no_$%s$%s"%(n,m))+[resta7(lambda n:act("velas",n=n))]+X}]
s115={"id":"las-velas","title":"Las velas","place":"El fuerte","scene":"regalos","next":"para-ti",
 "goal":"Hang the photo abuelo asks for, by how old Carmen is in it (tres or siete, meses or años), on the line over the table, so that the seven candles on her cake keep burning in the wind: a wrong photo has to come down again, and while abuelo changes it the wind gets past abuela's hands and blows out two candles.",
 "stake":{"thing":"velas","steps":7},"dots":8,"bien":"si_muy_bien",
 "focus_words":["vela","año","mes","¡felicidades!"],"formas_foco":{"mes":["meses"],"año":["años"],"vela":["velas","velitas"]},
 "back_again":["cumpleaños","bizcocho","feliz","bebé","¿cuántos años tienes?","tengo … años","siete","tres","¿quién?","tú","trae","falta","un momento","viento","un poco","aquí","ahora","tiene","mira","sí","no"],
 "also_heard":[],"names":nm,"palabras":{"ano":"año"},"clips":c,
 "beats":[START]+juntos(act("llega",quien="carmen",a="tras_mesa2"),act("llega",quien="abuela",a="tras_mesa"),act("llega",quien="abuelo",a="junto_banco"),act("llega",quien="luis",a="arco"),act("llega",quien="pepe",a="espera1"),act("llega",quien="maestra",a="espera2"),act("ir",a="mesa_coqui"))+[{"wait":500},
  # 1: abuela asks Carmen her age; don Pepe's line; abuela asks for the candles (signed ask on the box); the frog carries them to the cake one by one while Luis counts on his fingers
  {"dots":1},"c115_ab_feliz","c115_ca_siete","c115_pepe_felicidades",ask("caja_velas","c115_ab_velas")]+[dict(gesto("luis","dedos"),suelto=1),dict(act("velas115"),suelto=1),"c115_l_cuenta",act("ya")]+[
  # 2: abuelo takes two photos out of his envelope (no act named); his line is the signed ask on the baby's photo: the frog holds it up, abuelo hangs it; the second line is the signed ask on the girl with the ball
  {"dots":2},ask("foto_3m","c115_abo_bebe",after=[act("foto115",cual="foto_3m",ok=1)]),ask("foto_3a","c115_abo_tres",after=[act("foto115",cual="foto_3a",ok=1)]),"c115_ca_chiquita",
  # 3: two more photos (no act named); abuelo names them and hangs them: four photos from the smallest Carmen to the biggest; Carmen holds up the first photo's twin (no act named); a speaking turn (tú)
  {"dots":3},"c115_abo_siete",act("foto115",cual="foto_7m",ok=1),act("foto115",cual="foto_7a",ok=1),"c115_ca_quien","c115_cq_tu",
  # 4: the turn: a gust, the four photos flutter down onto the table's end (their order is drawn); abuela lights the seven candles; Carmen says the photos are missing; abuelo steps up on the stool (abuela cups her hands round the flames: no act named); the card shows two places
  {"dots":4},{"reparte":["fa","fb","fc","fd"],"options":["foto_3m","foto_3a","foto_7m","foto_7a"]},act("viento115",fotos1="$fa",fotos2="$fb",fotos3="$fc",fotos4="$fd"),act("prende115"),act("velas",n=7),"c115_ca_momento",act("llega",quien="abuelo",a="taburete"),CARD,{"wait":400},
  # 5: A. 6: B (the other pair). Which photo: drawn afresh each round
  {"dots":5}]+ronda115("a")+[{"dots":6}]+ronda115("b"),
 "final":[{"dots":7},baja7(lambda n:act("final115",n=n)),   # 7: abuelo hangs the last two photos himself and comes down (no act of its own); the candles that burn: 7, 5, 3 (the others black, with their threads of smoke)
  {"dots":8},"c115_ab_feliz2",act("sopla115"),"c115_mae_felicidades","c115_abo_quieres","c115_cq_poco","c115_fin",act("fin")],   # 8: Carmen blows them out; a speaking turn (un poco); abuelo cuts him a piece (no act named)
 "leer":["c115_ab_feliz","c115_ca_siete","c115_pepe_felicidades","c115_ab_velas","c115_l_cuenta","c115_abo_bebe","c115_abo_tres","c115_ca_chiquita","c115_abo_siete","c115_ca_quien","c115_cq_tu","c115_ca_momento",
  "c115_foto_3m","c115_no_3m","c115_foto_7a","c115_ab_feliz2","c115_mae_felicidades","c115_abo_quieres","c115_cq_poco","c115_fin"]}
s115=reuse(s115,{"c115_cq_tu":TG(("tú",["tú","eres tú"])),"c115_cq_poco":TG(("un poco",["un poco","sí un poco"]))})
json.dump(s115,open("cuentos/las-velas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 116. Para ti ----------------
# Abuela, her eyes on her sheet, says what a guest (don Pepe, la maestra or el piragüero, drawn) does: he gives (da) or he receives (recibe), each round on its own. Carmen and the guest stand on either side of the stool, both hands held out.
# The frog pushes the packet to one of them: to Carmen if the guest gives, to the guest if he receives. A miss: the one who was giving opens it before abuela can speak, the paper torn and the bow off; the sign is on the right person.
nm,nc=nombres("abuela","abuelo","luis","carmen","piraguero","coqui"); c=dict(comunes); c.update(nc)
c.update({"c116_ab_tiene":AB("Carmen, abuelo tiene un regalo."),"c116_abo_para_ti":ABO("Para ti, Carmen."),"c116_ab_da":AB("Abuelo le da el regalo a Carmen. Carmen recibe el regalo."),
 "c116_ca_sombrero":CA("¡Un sombrero! ¡Gracias, abuelo!"),"c116_ca_tengo":CA("Y yo tengo un regalo para ti, abuelo."),"c116_ab_ahora":AB("Ahora Carmen da y abuelo recibe."),
 "c116_l_doy":L("Yo también te doy un regalo. Para ti, Carmen."),"c116_ab_luis_da":AB("Luis da. ¿Y quién recibe?"),"c116_cq_ella":T("¡Ella!"),"c116_ab_si":AB("¡Sí! Carmen recibe."),
 "c116_ab_viento":AB("¡Ay, el viento!"),"c116_ca_para_ti":CA("Coquí, este regalo es para ti."),"c116_cq_para_mi":T("¿Para mí?"),"c116_ca_si":CA("¡Sí, para ti!"),
 "c116_fin":N("Carmen recibe regalos. Y Carmen da regalos también.")})
GUEST={"pepe":"Don Pepe","maestra":"La maestra","piraguero":"El piragüero"}
for g,w in GUEST.items():   # the six sentences the draw can make (3 guests x da, recibe) and the six corrections
    for v in ("da","recibe"):
        c["c116_%s_%s"%(g,v)]=AB("%s %s el regalo."%(w,v)); c["c116_no_%s_%s"%(g,v)]=AB("¡No, Coquí! %s %s el regalo."%(w,v)); DIN.update(["c116_%s_%s"%(g,v),"c116_no_%s_%s"%(g,v)])
VARS116={"ga":list(GUEST),"gb":list(GUEST),"va":["da","recibe"],"vb":["da","recibe"]}
def ronda116(s):
    # g: the guest (dealt out), v: what he does (drawn), p: the one who receives (the right touch), o: the other (the giver, who claps). Right: the packet goes across, the receiver opens it, the other claps, the star (the clap and the star only on a first right touch).
    # Wrong: the one touched (x) gets it and opens it, torn paper, the line, a surprise less, the cross; the sign's touch then sends it across (in its torn paper).
    g,v,p,o="g"+s,"v"+s,"p"+s,"o"+s
    pre=[{"reparte":["ga","gb"],"options":list(GUEST)}] if s=="a" else []
    pre+=[{"draw":v,"options":["da","recibe"]},{"calc":p,"cond":v+"=da","then":"carmen","else":"$"+g},{"calc":o,"cond":v+"=da","then":"$"+g,"else":"carmen"}]
    if s=="a":   # where guest A goes back to wait: espera1 (pepe), espera2 (maestra), espera3 (piraguero)
        pre+=[{"calc":"ea","cond":"ga=pepe","then":"espera1","else":"espera3"},{"calc":"ea","cond":"ga=maestra","then":"espera2","else":"$ea"}]
    else: pre=[act("llega",quien="$ga",a="$ea")]+pre
    pre+=[act("pareja116",quien="$"+g)]+juntos(gesto("carmen","manos"),gesto("$"+g,"manos"),gesto("carmen","mira",a="abuela"),gesto("$"+g,"mira",a="abuela"))
    return pre+[{"decide":"do","options":["carmen","$"+g],"pick":"$"+p,"tests":"$"+v,"lock":True,"lead":[],"line":"c116_$%s_$%s"%(g,v),
      "right":[act("empuja116",a="$"+p,ok=1),{"if":"ok","then":[gesto("$"+o,"aplaude"),OK]}],
      "wrong":[act("empuja116",a="$x",ok=0),"c116_no_$%s_$%s"%(g,v),resta(lambda n:act("sorpresas",n=n))]+X}]
s116={"id":"para-ti","title":"Para ti","place":"El fuerte","scene":"regalos","next":"todos-en-la-foto",
 "goal":"Push each packet across the stool to the one who gets it, Carmen or the guest, as abuela says whether the guest gives or receives, so that the three packets stay a surprise: a packet pushed to the one who was giving it is opened by him on the spot, the paper torn and the bow off, and everybody has seen what is inside before the right person gets it.",
 "stake":{"thing":"sorpresas","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["da","recibe","para ti"],"formas_foco":{"da":["doy"]},
 "back_again":["regalo","cumpleaños","sorpresa","sombrero","ella","él","tiene","tengo","¿quién?","viento","para mí","también","ahora","bonito","gracias","sí","no"],
 "also_heard":[],"names":nm,"palabras":{},"clips":c,
 "beats":[START,act("sorpresas",n=3)]+juntos(act("llega",quien="carmen",a="banqueta_izq"),act("llega",quien="abuelo",a="banqueta_der"),act("llega",quien="abuela",a="tras_mesa"),act("llega",quien="luis",a="arco"),
   act("llega",quien="pepe",a="espera1"),act("llega",quien="maestra",a="espera2"),act("llega",quien="piraguero",a="espera3"),act("ir",a="mesa_coqui"))+[{"wait":500},
  # 1: abuela says abuelo has a present; abuelo puts his box on the stool (no act named); his line is the signed ask on Carmen: the frog pushes the box across to her
  {"dots":1},"c116_ab_tiene",ask("carmen","c116_abo_para_ti",after=[act("empuja116",a="carmen",ok=1)]),"c116_ab_da",
  # 2: Carmen opens it: a straw hat; she puts a small thing on the stool (no act named); her line is the signed ask on abuelo: the frog pushes it across; he opens it: a paper fan
  {"dots":2},act("abre116",quien="carmen",que="sombrero"),"c116_ca_sombrero",ask("abuelo","c116_ca_tengo",after=[act("empuja116",a="abuelo",ok=1),act("abre116",quien="abuelo",que="abanico")]),"c116_ab_ahora",
  # 3: Luis puts a small thing on the stool (no act named); the frog pushes it across; the frog points at Carmen; a speaking turn (ella)
  {"dots":3},"c116_l_doy",act("empuja116",a="carmen",ok=1),"c116_ab_luis_da",gesto("coqui","senala",a="carmen"),"c116_cq_ella","c116_ab_si",
  # 4: the turn: a gust, the tags fly off the three packets; abuela holds up her sheet (no act named); abuelo goes to the bench's side, a guest comes to the stool's right and abuelo puts the first packet on it; the card shows two places
  {"dots":4},act("etiquetas116"),"c116_ab_viento",act("llega",quien="abuelo",a="junto_banco"),CARD,{"wait":400},
  # 5: A. 6: B (another guest; the second packet). The guest and what he does: drawn afresh each round
  {"dots":5}]+ronda116("a")+[{"dots":6}]+ronda116("b"),
 "final":[{"dots":7},baja3(lambda n:act("final116",n=n))]+juntos(*[gesto(q,"mira",a="coqui") for q in ("abuela","abuelo","luis","carmen","pepe","maestra","piraguero")])+[   # 7: one packet left; abuela looks up at the frog and everybody looks at him; the torn papers by the stool, by what was lost
  {"dots":8},"c116_ca_para_ti","c116_cq_para_mi",act("abre116",quien="coqui",que="sombrerito"),"c116_ca_si","c116_fin",act("fin")],   # 8: Carmen puts the last packet on the stool in front of the frog (no act named); a speaking turn (para mí); he opens it: a very small straw hat
 "leer":["c116_ab_tiene","c116_abo_para_ti","c116_ab_da","c116_ca_sombrero","c116_ca_tengo","c116_ab_ahora","c116_l_doy","c116_ab_luis_da","c116_cq_ella","c116_ab_si","c116_ab_viento",
  "c116_pepe_da","c116_no_pepe_da","c116_maestra_recibe","c116_ca_para_ti","c116_cq_para_mi","c116_ca_si","c116_fin"]}
s116=reuse(s116,{"c116_cq_ella":TG(("ella",["ella","carmen"])),"c116_cq_para_mi":TG(("para mí",["para mí","¿para mí?"]))})
json.dump(s116,open("cuentos/para-ti.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- checks ----------------
# every speaking turn is on a word of an EARLIER story's focus_words (the files on disk, and the earlier stories of this run). None of this scene's turns is on a word of another story of place 10.
EARLIER=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    EARLIER.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s114,s115,s116):
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
for st,VARS in ((s114,VARS114),(s115,VARS115),(s116,VARS116)):
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
