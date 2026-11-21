# La comida (place 8, La fonda, scene 3 of 4): stories 90, 91, 92. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/comida.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `comida` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: the generators of places 4 to 7 first (gen_mostrador ... gen_cielo), then the four scenes of La fonda in any order. Every speaking turn of this scene is on a word of places 1 to 6
# (agua, no, aquí tiene, ¿algo más?, más, un poco): none uses a word that is new in another story of La fonda (para mí, nada más, cuenta), so nothing here needs those files.
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   Variable names are letters only (the engine fills `$name` with [a-z]+): ax ay az / bx by bz are the tastes on the three plates, qa qb who, ga gb the taste or the guest, pa pb the right thing, fa fb the wrong taste fed (90) or the thing missing (91), ha hb the thing there is plenty of (91),
#     oa ob which is said first (91), sa sb what the guest says (92), ra rb what the frog did (92), ea eb the draw that makes "another" (see below).
#   90 `platillos90` {orden}: the TASTE on each plate, left to right (platillo1, platillo2, platillo3) as ONE string with commas: salado = the tostones, dulce = the pineapple, picante = the red peppers ("salado,dulce,picante").
#       The opening keeps the Start's order (tostones, pineapple, peppers), so the signed asks of the opening are on platillo1 (salado), platillo2 (dulce); the pieces put on again (steps 4 and 5) go on in the same order.
#       In the game each round deals the three tastes out to the three plates (`reparte`: a random order, none twice); `da90` {cual} is the plate key (platillo1 to platillo3, so a wrong touch `$x` goes in as it is) and {a} the person's key (abuela, abuelo, luis, carmen).
#   "Another of the family" (90 B, 91 B) and "another guest" (92 B): round B's person is never round A's (the draw `e` and the `otro` chain); everything else is drawn on its own each round. Persons: the family is abuela, abuelo, luis, carmen; the guests are senor, senora, joven, mujer (the script's Needs list).
#   91: "two other things": the four things (sal, azucar, hielo, servilletas) are dealt out once to ha, fa (round A: plenty, missing) and hb, fb (round B), none twice (`reparte`), so round B's two things are the two that A did not use (the script's own examples: A sal and hielo, B servilleta and azúcar).
#       Which is said first, and who says it, are drawn each round. The thing keys are the drawn values (sal, azucar, hielo, servilletas): `trae91` {que} gets them as they are, a wrong touch `$x` too.
#   91 the miss is filed under bastante if he fetched the thing there was plenty of, else hielo / servilleta / falta: `tests` is "$fa.$ha.$x" (missing, plenty, touched) and `palabras` maps each of the 48 keys to the word.
#   92: `prueba92` {que}: prueba (the cocinero tastes), sal (he shakes salt in), salsa (he adds a drop from the red bottle). `sirve92` {que}: mas (a spoonful from the pot), menos (a spoonful off into the dog's bowl), bien (the plate pushed into the guest's hands); the draw `sa` is mas, menos or bien.
#       The three places to touch are olla, plato_perro and the guest (the guest's own key). `tazon` {n} is set one, two, three in step 1 (the script: "one, two, three") and the stake's count after a loss.
#   `tests` of the games: 90 the taste asked (salado, dulce, picante), 92 what the guest said (mas -> más, menos, bien -> está bien).
#   The wrong move runs in the order of the script: the frog's act, the line, the picture's loss, the count act, then the cross and one step (X). Where the act carries both the first part and the loss (90 `da90` ok=0: the face, then the glass filled and set aside;
#       92 `sirve92` ok=0: the guest's head, the plate to the dog, the new plate topped up) the act is started loose and the line is said in time with it (`con`), as gen_ropa does for `baja78`.
#   91 and 92 step 5/6 ("The mesera brings three bowls", guests come): the beat's act is `llega`; the soup is set down by `sopas` {n:3} (steaming) after her arrival. In 92 each person (opening) or guest (game) comes to `fila1` (`llega`), the heap is `monton92` {a: that person's key}.
#   Beats with no act named in Needs are left out (and listed in the report): nothing is invented. Words of the form notes ("(tostón: a form of tostones)", "(pique: heard)") are not tracked except `also_heard` = pique (92).
#   Ranges and forms in "Back again" are written as the earlier stories' words (cierra, abre, pone), the forms in brackets are not listed.
#   Turn formas: the script's bracketed lists, with the unaccented spelling of each form that has an accent (as the earlier generators do).
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); AU=lambda t:D("abuelo","Abuelo",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
ME=lambda t:D("mesera","La mesera",t); CO=lambda t:D("cocinero","El cocinero",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
MINE=("prueba","falta-algo","mas-y-menos")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c90_q_$qa_$ga" gives c90_q_luis_dulce): never renamed
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
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!")}
# What he hears when he pokes a person already recorded (the mesera and the cocinero are not recorded as named people: they add nothing)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "abuelo":("n_abuelo",N("Este es abuelo.")),"perro":("c_n_perro",N("Es el perro. Se llama Canelo.")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora.")),"mujer":("b_n_mujer",N("Es una mujer.")),"joven":("b_n_joven",N("Es un joven."))}
def nombres(*ks): return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}

def baja3(n):
    # the act that shows what is left of the stake, by what was lost (3 steps; two rounds, so up to two are lost)
    return {"if":"lost=0","then":[n(3)],"else":[{"if":"lost=1","then":[n(2)],"else":[n(1)]}]}
def resta(n):
    # the picture's count after a loss in this round: before the cross is counted, lost=0 means this is the first
    return {"if":"lost=0","then":[n(2)],"else":[n(1)]}
def otro(out,inv,e,opts):
    # out = the e-th (1 to len-1) of the options that are not `inv`: round B's person is never round A's
    def rama(v):
        o=[x for x in opts if x!=v]
        return [{"calc":out,"cond":e+"=1","then":o[0],"else":o[1]}]+[{"calc":out,"cond":"%s=%d"%(e,i+1),"then":o[i],"else":"$"+out} for i in range(2,len(o))]
    ch=rama(opts[-1])
    for v in reversed(opts[:-1]): ch=[{"if":inv+"="+v,"then":rama(v),"else":ch}]
    return ch
def tabla(out,var,pares,otro_val):
    # out = the value paired with `var`'s value, or `otro_val` for any other: a chain of calcs (the first sets the default)
    return [{"calc":out,"cond":"%s=%s"%(var,v),"then":r,"else":otro_val if i==0 else "$"+out} for i,(v,r) in enumerate(pares)]
def persona(s,q,opts):
    # round A: anybody; round B: anybody but round A's (`otro`)
    if s=="a": return [{"draw":q,"options":opts}]
    return [{"draw":"eb","options":[str(i) for i in range(1,len(opts))]}]+otro(q,"qa" if opts is FAM else "ga","eb",opts)
FAM=["abuela","abuelo","luis","carmen"]
PRE={"abuela":"Abuela","abuelo":"Abuelo","luis":"Luis","carmen":"Carmen"}

# ---------------- 90. Prueba ----------------
# Round A and round B: the three plates hold tostones, pineapple and red peppers in a dealt order; one of the family (drawn; B: another) shuts his eyes and says what he wants: algo salado, algo dulce, algo picante (drawn). Each round on its own.
# A miss: he chews the wrong thing and makes a face, fills a glass from the jar and gulps it down; the empty glass is set aside. Every (person, taste) has its request, its "right" line, and for each other taste its correction.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c90_ab_prueba":AB("Prueba, Coquí."),"c90_ab_salado":AB("El tostón es salado. Tiene sal."),"c90_cual_salado":N("¿Cuál es el plato salado?"),
 "c90_l_pina":L("Ahora, prueba la piña."),"c90_l_dulce":L("La piña es dulce. ¡Qué dulce!"),"c90_cual_dulce":N("¿Cuál es el plato dulce?"),
 "c90_au_esto":AU("Y ahora... prueba esto."),"c90_au_picante":AU("¡Picante!"),"c90_ab_ay":AB("¡Ay, no! Eso es picante, Coquí. ¿Qué quieres?"),"c90_cq_agua":T("¡Agua, por favor!"),
 "c90_ca_ahora":CA("Ahora yo. Cierro los ojos y abro la boca. Quiero algo salado."),"c90_cual_carmen":N("Carmen quiere algo salado. ¿Cuál es?"),"c90_ca_si":CA("¡Sí! Salado."),
 "c90_l_yo":L("¡Y yo quiero algo dulce!"),"c90_l_mmm":L("Mmm. Dulce."),"c90_au_yo":AU("Yo quiero algo picante."),"c90_au_gusta":AU("Picante. Me gusta."),
 "c90_ab_despues":AB("La limonada es para después."),
 "c90_au_otro":AU("¿Otro, Coquí? Prueba."),"c90_cq_no":T("¡No, gracias!"),"c90_ab_dulce":AB("Coquí quiere algo dulce.")})
G90=["salado","dulce","picante"]
for q in FAM:
    for g in G90:
        c["c90_q_%s_%s"%(q,g)]=D(q,PRE[q],"Quiero algo %s."%g); c["c90_ok_%s_%s"%(q,g)]=D(q,PRE[q],"¡%s! Gracias."%g.capitalize()); DIN.update(["c90_q_%s_%s"%(q,g),"c90_ok_%s_%s"%(q,g)])
        for f in G90:
            if f!=g: c["c90_no_%s_%s_%s"%(q,f,g)]=D(q,PRE[q],"¡No! Eso es %s. ¡Quiero algo %s!"%(f,g)); DIN.add("c90_no_%s_%s_%s"%(q,f,g))
def ronda90(s):
    # one round: the plates dealt (a b c: the taste on platillo1, 2, 3), who asks (q), the taste (g). Right: the frog feeds him from the right plate, he says thanks. Wrong: the other plate; he says no, fills a glass from the jar and gulps it down.
    a,b,cc,q,g,p,f=s+"x",s+"y",s+"z","q"+s,"g"+s,"p"+s,"f"+s
    return [{"reparte":[a,b,cc],"options":G90},act("platillos90",orden="$%s,$%s,$%s"%(a,b,cc))]+persona(s,q,FAM)+[{"draw":g,"options":G90},
     {"calc":p,"cond":"%s=$%s"%(a,g),"then":"platillo1","else":"platillo3"},{"calc":p,"cond":"%s=$%s"%(b,g),"then":"platillo2","else":"$"+p},
     gesto("$"+q,"ojos"),
     {"decide":"do","options":["platillo1","platillo2","platillo3"],"pick":"$"+p,"tests":"$"+g,"lock":True,"lead":[],"line":"c90_q_$%s_$%s"%(q,g),
      "right":[act("da90",cual="$"+p,a="$"+q,ok=1),"c90_ok_$%s_$%s"%(q,g),star],
      "wrong":tabla(f,"x",[("platillo1","$"+a),("platillo2","$"+b)],"$"+cc)+con(act("da90",cual="$x",a="$"+q,ok=0),"c90_no_$%s_$%s_$%s"%(q,f,g))+[resta(lambda n:act("jarra",n=n))]+X}]
s90={"id":"prueba","title":"Prueba","place":"La fonda","scene":"comida","next":"falta-algo",
 "goal":"Feed each of the family from the plate that matches the taste he asks for (salado, dulce or picante), so that the jar of lemonade and its three glasses are still full for afterwards: every wrong mouthful sends a glass of lemonade down to put the fire out, and the empty glass is set aside.",
 "stake":{"thing":"jarra","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["prueba","salado","dulce","picante"],"formas_foco":{},
 "back_again":["tostones","limonada","piña","sal","agua","quiero","quieres","me gusta","cierra","abre","ojo","boca","tiene","otro","eso","esto","ahora","después","no","sí","gracias","por favor"],
 "also_heard":[],"names":nm,"palabras":{"salado":"salado","dulce":"dulce","picante":"picante"},"clips":c,
 "beats":[{"set":{"hora":"noche"}},act("ir",a="mesa_coqui"),act("jarra",n=3),act("platillos90",orden="salado,dulce,picante"),{"wait":500},
  # 1: a tostón (abuela holds it out: no act named); the frog eats it; the signed ask on the tostones: the plate shines
  {"dots":1},"c90_ab_prueba",gesto("coqui","come"),"c90_ab_salado",ask("platillo1","c90_cual_salado",after=[tw("platillo1"),{"wait":700},tw(None)]),
  # 2: the pineapple; the signed ask on it
  {"dots":2},"c90_l_pina",gesto("coqui","come"),"c90_l_dulce",ask("platillo2","c90_cual_dulce"),
  # 3: the pepper (abuelo holds it out: no act named); the fire; the first turn (agua); abuela pours the water, steam off his head (no act named)
  {"dots":3},"c90_au_esto",act("fuego90"),"c90_au_picante","c90_ab_ay","c90_cq_agua",
  # 4: new pieces on the plates; Carmen shuts her eyes; the signed ask on the tostones: the frog feeds her; Luis, abuelo: the frog feeds them, no sign
  {"dots":4},act("platillos90",orden="salado,dulce,picante"),gesto("carmen","ojos"),"c90_ca_ahora",
  ask("platillo1","c90_cual_carmen",after=[act("da90",cual="platillo1",a="carmen",ok=1)]),"c90_ca_si",
  gesto("luis","ojos"),"c90_l_yo",act("da90",cual="platillo2",a="luis",ok=1),"c90_l_mmm",
  gesto("abuelo","ojos"),"c90_au_yo",act("da90",cual="platillo3",a="abuelo",ok=1),gesto("abuelo","come"),"c90_au_gusta",
  # 5: new pieces again; abuela taps the jar and the glasses; the turn: the card shows two places
  {"dots":5},act("platillos90",orden="salado,dulce,picante"),gesto("abuela","senala",a="jarra"),"c90_ab_despues",CARD,{"wait":400},
  # 6: A. 7: B. Each drawn afresh
  {"dots":6}]+ronda90("a")+[{"dots":7}]+ronda90("b"),
 "final":[{"dots":8},baja3(lambda n:act("final90",n=n)),   # 8: abuela pours what is left; the glasses, by what was lost
  # 9: another pepper (abuelo holds it out: no act named); the second turn (no); abuela laughs, gives him pineapple (no act named)
  {"dots":9},"c90_au_otro","c90_cq_no",gesto("abuela","rie"),"c90_ab_dulce",act("fin")],
 "leer":["c90_ab_prueba","c90_ab_salado","c90_cual_salado","c90_l_pina","c90_l_dulce","c90_cual_dulce","c90_au_esto","c90_au_picante","c90_ab_ay","c90_cq_agua","c90_ca_ahora","c90_cual_carmen","c90_ca_si","c90_l_yo","c90_l_mmm","c90_au_yo","c90_au_gusta",
  "c90_ab_despues","c90_q_luis_dulce","c90_ok_luis_dulce","c90_au_otro","c90_cq_no","c90_ab_dulce"]}
s90=reuse(s90,{"c90_cq_agua":TG(("agua",["agua","agua por favor"])),"c90_cq_no":TG(("no",["no","no gracias"]))})
json.dump(s90,open("cuentos/prueba.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 91. Falta algo ----------------
# One of the family (drawn; B: another) says in one breath what there is plenty of and what is missing: two of sal, azúcar, hielo and servilletas, never the same, which is said first drawn too. The frog fetches one of the four things from the side table.
# Round B's two things are the two that A did not use. A miss: the frog carries the wrong thing over, a shake of the head, another trip across the terrace: one bowl has stopped steaming and its spoon is put down.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui"); c=dict(comunes); c.update(nc)
c.update({"c91_me_mesero":ME("Coquí, ahora tú eres el mesero."),"c91_ab_falta_sal":AB("Mmm, tostones. ¡Ay! Falta sal."),"c91_donde_sal":N("¿Dónde está la sal para abuela?"),"c91_ab_ya_no":AB("Gracias. Ya no falta sal."),
 "c91_l_falta_hielo":L("Mi refresco está caliente. Falta hielo."),"c91_donde_hielo":N("¿Dónde hay hielo para Luis?"),"c91_l_hielo":L("¡Hielo! Gracias."),
 "c91_au_falta_serv":AU("¡Ay! Falta una servilleta."),"c91_donde_serv":N("¿Dónde están las servilletas?"),"c91_cq_aqui_tiene":T("¡Aquí tiene!"),"c91_au_gracias_serv":AU("Gracias por la servilleta, mesero."),"c91_ca_mi_serv":CA("Mi servilleta está aquí."),
 "c91_l_no_no":L("¡No, no! Hay bastante hielo. Mira."),"c91_ab_bastante":AB("Hay bastante hielo, Coquí. Falta azúcar."),"c91_que_falta":N("Hay bastante hielo. ¿Qué falta?"),"c91_ab_ahora":AB("Gracias. Ahora tiene bastante azúcar."),
 "c91_me_sopa":ME("La sopa. ¡Cuidado! Está caliente."),
 "c91_f3":N("La sopa está caliente."),"c91_f2":N("La sopa de abuelo está fría."),"c91_f1":N("Dos sopas están frías."),
 "c91_cq_algo_mas":T("¿Algo más?"),"c91_ab_ven":AB("Sí. ¡Falta Coquí! Ven acá, mesero."),"c91_fin":N("Ahora no falta nada.")})
K91=["sal","azucar","hielo","servilletas"]
HAY={"sal":"Hay bastante sal.","azucar":"Hay bastante azúcar.","hielo":"Hay bastante hielo.","servilletas":"Hay bastantes servilletas."}
FALTA={"sal":"Falta sal.","azucar":"Falta azúcar.","hielo":"Falta hielo.","servilletas":"Falta una servilleta."}
PAL91={}   # (missing, plenty, touched) -> the word a miss is filed under
for q in FAM:
    c["c91_gr_%s"%q]=D(q,PRE[q],"Gracias, mesero."); DIN.add("c91_gr_%s"%q)
    for f in K91:
        c["c91_no_%s_%s"%(q,f)]=D(q,PRE[q],"No, Coquí. "+FALTA[f]); DIN.add("c91_no_%s_%s"%(q,f))
        for h in K91:
            if h==f: continue
            c["c91_hf_%s_%s_%s"%(q,h,f)]=D(q,PRE[q],HAY[h]+" "+FALTA[f]); c["c91_fh_%s_%s_%s"%(q,h,f)]=D(q,PRE[q],FALTA[f]+" "+HAY[h]); DIN.update(["c91_hf_%s_%s_%s"%(q,h,f),"c91_fh_%s_%s_%s"%(q,h,f)])
for f in K91:
    for h in K91:
        for x in K91:
            if h!=f: PAL91["%s.%s.%s"%(f,h,x)]="bastante" if x==h else {"sal":"falta","azucar":"falta","hielo":"hielo","servilletas":"servilleta"}[f]
def ronda91(s):
    # one round: who speaks (q), what there is plenty of (h) and what is missing (f), dealt before the game, and which is said first (o: hf = the plenty first). Right: the frog carries the missing thing over. Wrong: another thing, waved away; another trip.
    h,f,q,o="h"+s,"f"+s,"q"+s,"o"+s
    return persona(s,q,FAM)+[{"draw":o,"options":["hf","fh"]},
     {"decide":"do","options":K91,"pick":"$"+f,"tests":"$%s.$%s.$x"%(f,h),"lock":True,"lead":[],"line":"c91_$%s_$%s_$%s_$%s"%(o,q,h,f),
      "right":[act("trae91",que="$"+f,a="$"+q,ok=1),"c91_gr_$"+q,star],
      "wrong":[act("trae91",que="$x",a="$"+q,ok=0),gesto("$"+q,"no"),"c91_no_$%s_$%s"%(q,f),resta(lambda n:act("sopas",n=n))]+X}]
s91={"id":"falta-algo","title":"Falta algo","place":"La fonda","scene":"comida","next":"mas-y-menos",
 "goal":"Fetch from the mesera's side table the thing a person says is missing (salt, ice, sugar or napkins), not the one there is plenty of, so that the three bowls of hot soup keep steaming: every wrong thing means another trip across the terrace, and by then a bowl has gone cold.",
 "stake":{"thing":"sopas","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["falta","bastante","hielo","servilleta"],"formas_foco":{"servilleta":["servilletas"],"bastante":["bastantes"]},
 "back_again":["sopa","tostones","refresco","ensalada","sal","azúcar","café","hay","tiene","caliente","frío","mesera","mesero","aquí tiene","¿algo más?","nada","ya","mira","ven","ahora","mi","cuidado","gracias","no","sí"],
 "also_heard":[],"names":nm,"palabras":dict(PAL91),"clips":c,
 "beats":[{"set":{"hora":"noche"}},act("ir",a="auxiliar_coqui"),act("llega",quien="mesera",a="junto_mesa"),{"wait":500},
  # 1: the mesera walks off; abuela bites a tostón; the signed ask on the salt: the frog carries the shaker over
  {"dots":1}]+con(act("sale",quien="mesera"),"c91_me_mesero")+[gesto("abuela","come"),"c91_ab_falta_sal",ask("sal","c91_donde_sal",after=[act("trae91",que="sal",a="abuela",ok=1)]),"c91_ab_ya_no",
  # 2: Luis looks into his cup (no act named); the signed ask on the ice: cubes in the tongs
  {"dots":2},"c91_l_falta_hielo",ask("hielo","c91_donde_hielo",after=[act("trae91",que="hielo",a="luis",ok=1)]),"c91_l_hielo",
  # 3: abuelo looks for a napkin (no act named); the signed ask on the napkins; the first turn (aquí tiene); Carmen lifts her napkin (no act named)
  {"dots":3},"c91_au_falta_serv",ask("servilletas","c91_donde_serv",after=[act("trae91",que="servilletas",a="abuelo",ok=1)]),"c91_cq_aqui_tiene","c91_au_gracias_serv","c91_ca_mi_serv",
  # 4: the frog carries the tongs to Luis again, he covers his cup; abuela looks into her cup (no act named); the signed ask on the sugar bowl
  {"dots":4},act("trae91",que="hielo",a="luis",ok=0),gesto("luis","tapa"),"c91_l_no_no","c91_ab_bastante",ask("azucar","c91_que_falta",after=[act("trae91",que="azucar",a="abuela",ok=1)]),"c91_ab_ahora",
  # 5: the mesera brings three bowls of soup and goes off; the three take up their spoons and look at the frog; the card shows two places
  {"dots":5},act("llega",quien="mesera",a="junto_mesa"),act("sopas",n=3),"c91_me_sopa",act("sale",quien="mesera"),
  gesto("abuela","cuchara"),gesto("abuelo","cuchara"),gesto("luis","cuchara"),gesto("abuela","mira",a="coqui"),gesto("abuelo","mira",a="coqui"),gesto("luis","mira",a="coqui"),CARD,{"wait":400},
  # 6: A. 7: B. Each drawn afresh; the four things are dealt out once, so that B's two are the two A did not use
  {"dots":6},{"reparte":["ha","fa","hb","fb"],"options":K91}]+ronda91("a")+[{"dots":7}]+ronda91("b"),
 "final":[{"dots":8},{"if":"lost=0","then":[act("final91",n=3),"c91_f3"],"else":[{"if":"lost=1","then":[act("final91",n=2),"c91_f2"],"else":[act("final91",n=1),"c91_f1"]}]},   # 8: the family eats; the soup, by what was lost
  # 9: the frog bows (no act named); the second turn (¿algo más?); the frog hops onto the table
  {"dots":9},"c91_cq_algo_mas","c91_ab_ven",act("sube91"),"c91_fin",act("fin")],
 "leer":["c91_me_mesero","c91_ab_falta_sal","c91_donde_sal","c91_ab_ya_no","c91_l_falta_hielo","c91_donde_hielo","c91_l_hielo","c91_au_falta_serv","c91_donde_serv","c91_cq_aqui_tiene","c91_au_gracias_serv","c91_ca_mi_serv","c91_l_no_no","c91_ab_bastante","c91_que_falta","c91_ab_ahora",
  "c91_me_sopa","c91_hf_abuelo_sal_hielo","c91_gr_abuelo","c91_f3","c91_cq_algo_mas","c91_ab_ven","c91_fin"]}
s91=reuse(s91,{"c91_cq_aqui_tiene":TG(("aquí tiene",["aquí tiene","aqui tiene"])),"c91_cq_algo_mas":TG(("¿algo más?",["algo más","algo mas"]))})
json.dump(s91,open("cuentos/falta-algo.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 92. Más y menos ----------------
# A guest (drawn; B: another of the four) holds out a plate with a heap of rice and says one of three things (drawn): Para mí, menos / más / así está bien. The frog adds a spoonful from the pot, takes one off into the dog's bowl, or pushes the plate into the guest's hands. Each round on its own.
# A miss: the guest shakes his head, the plate goes into the dog's bowl, the cocinero fills a new one, scrapes the pot and tops it up with a spoonful from the frog's bowl. Every (guest, saying) has its sentence and its correction.
nm,nc=nombres("abuela","abuelo","luis","carmen","coqui","perro","senor","senora","joven","mujer"); c=dict(comunes); c.update(nc)
c.update({"c92_co_arroz":CO("Arroz con pollo, Coquí. Prueba."),"c92_co_falta_sal":CO("Mmm... falta sal."),"c92_co_mejor":CO("Mejor."),"c92_co_delicioso":CO("¡Mejor! Ahora está delicioso. Prueba."),"c92_co_esto":CO("Esto es para ti. Después."),
 "c92_ab_menos":AB("Para mí, menos. Menos arroz, por favor."),"c92_donde_perro":N("Abuela quiere menos arroz. ¿Dónde pones el arroz?"),"c92_ab_asi":AB("Gracias. Así está bien. Mmm, delicioso."),
 "c92_l_mas":L("¡Para mí, más! Más arroz, por favor."),"c92_donde_mas":N("Luis quiere más arroz. ¿Dónde hay más arroz?"),"c92_l_mejor":L("Ahora está mejor. Así está bien."),
 "c92_ca_asi":CA("Para mí, así está bien."),"c92_donde_carmen":N("El plato de Carmen está bien. ¿Dónde está Carmen?"),"c92_ca_rico":CA("¡Qué rico! Está delicioso."),
 "c92_au_menos":AU("Para mí, menos."),"c92_au_asi":AU("Así está bien. Gracias."),"c92_co_tu":CO("¿Y tú, Coquí? ¿Más arroz o menos arroz?"),"c92_cq_mas":T("¡Más, por favor!"),
 "c92_co_pique":CO("¿Pique, Coquí?"),"c92_cq_poco":T("¡Un poco!"),"c92_fin":N("El arroz con pollo está delicioso. Y con un poco de pique, mejor.")})
G92={"senor":"El señor","senora":"La señora","joven":"El joven","mujer":"La mujer"}; S92=["mas","menos","bien"]
DICE={"mas":"Para mí, más.","menos":"Para mí, menos.","bien":"Para mí, así está bien."}; NO92={"mas":"¡Más!","menos":"¡Menos!","bien":"¡Así está bien!"}
for g in G92:
    for sy in S92:
        c["c92_q_%s_%s"%(g,sy)]=D(g,G92[g],DICE[sy]); c["c92_no_%s_%s"%(g,sy)]=D(g,G92[g],"No, Coquí. "+NO92[sy]); DIN.update(["c92_q_%s_%s"%(g,sy),"c92_no_%s_%s"%(g,sy)])
def ronda92(s):
    # one round: which guest (g) and what he says (sy), each drawn. The right place: the pot (más), the dog's bowl (menos), the guest (así está bien).
    g,sy,p,r="g"+s,"s"+s,"p"+s,"r"+s
    return persona(s,g,list(G92))+[{"draw":sy,"options":S92},
     {"calc":p,"cond":"%s=mas"%sy,"then":"olla","else":"$"+g},{"calc":p,"cond":"%s=menos"%sy,"then":"plato_perro","else":"$"+p},
     act("llega",quien="$"+g,a="fila1"),act("monton92",a="$"+g),
     {"decide":"do","options":["olla","plato_perro","$"+g],"pick":"$"+p,"tests":"$"+sy,"lock":True,"lead":[],"line":"c92_q_$%s_$%s"%(g,sy),
      "right":[act("sirve92",que="$"+sy,ok=1),star],
      "wrong":tabla(r,"x",[("olla","mas"),("plato_perro","menos")],"bien")+con(act("sirve92",que="$"+r,ok=0),"c92_no_$%s_$%s"%(g,sy))+[resta(lambda n:act("tazon",n=n))]+X}]
s92={"id":"mas-y-menos","title":"Más y menos","place":"La fonda","scene":"comida","next":"el-postre",
 "goal":"Serve each guest's plate the way the guest asks (a spoonful more from the pot, one less into the dog's bowl, or just as it is), so that the three spoonfuls the cocinero put in the frog's own small bowl are still there afterwards: every plate served wrong goes to the dog, and the new one is topped up out of the frog's bowl.",
 "stake":{"thing":"tazon","steps":3},"dots":10,"bien":"si_muy_bien",
 "focus_words":["menos","está bien","mejor","delicioso"],"formas_foco":{},
 "back_again":["más","prueba","falta","sal","arroz","pollo","para mí","cocinero","pone","rico","un poco","después","ahora","esto","por favor","gracias","no","sí"],
 "also_heard":["pique"],"names":nm,"palabras":{"mas":"más","menos":"menos","bien":"está bien"},"clips":c,
 "beats":[{"set":{"hora":"noche"}},act("ir",a="servir_coqui"),act("llega",quien="cocinero",a="detras_olla"),act("tazon",n=0),{"wait":500},
  # 1: the cocinero tastes, salts, tastes, adds a drop of the red sauce, tastes; the frog tastes; three spoonfuls in the frog's small bowl, he taps it
  {"dots":1},"c92_co_arroz",gesto("coqui","come"),act("prueba92",que="prueba"),"c92_co_falta_sal",act("prueba92",que="sal"),act("prueba92",que="prueba"),"c92_co_mejor",
  act("prueba92",que="salsa"),act("prueba92",que="prueba"),"c92_co_delicioso",gesto("coqui","come"),
  act("tazon",n=1),{"wait":300},act("tazon",n=2),{"wait":300},act("tazon",n=3),gesto("cocinero","senala",a="tazon"),"c92_co_esto",
  # 2: abuela's plate; the signed ask on the dog's bowl: the frog takes a spoonful off into it
  {"dots":2},act("llega",quien="abuela",a="fila1"),act("monton92",a="abuela"),"c92_ab_menos",ask("plato_perro","c92_donde_perro",after=[act("sirve92",que="menos",ok=1)]),"c92_ab_asi",
  # 3: Luis's plate; the signed ask on the pot: the frog adds a spoonful
  {"dots":3},act("llega",quien="luis",a="fila1"),act("monton92",a="luis"),"c92_l_mas",ask("olla","c92_donde_mas",after=[act("sirve92",que="mas",ok=1)]),"c92_l_mejor",
  # 4: Carmen's plate; the signed ask on Carmen: the frog pushes the plate into her hands; she tastes
  {"dots":4},act("llega",quien="carmen",a="fila1"),act("monton92",a="carmen"),"c92_ca_asi",ask("carmen","c92_donde_carmen",after=[act("sirve92",que="bien",ok=1)]),gesto("carmen","come"),"c92_ca_rico",
  # 5: abuelo's plate; the frog takes a spoonful off, no sign; the cocinero's question; the first turn (más); he laughs and taps the small bowl
  {"dots":5},act("llega",quien="abuelo",a="fila1"),act("monton92",a="abuelo"),"c92_au_menos",act("sirve92",que="menos",ok=1),"c92_au_asi","c92_co_tu","c92_cq_mas",gesto("cocinero","rie"),gesto("cocinero","senala",a="tazon"),
  # 6: the guests come (no spot or guest named for the line: each round's guest comes to the front of the line); the cocinero looks into the pot, taps the bowl; the card shows two places
  {"dots":6},gesto("cocinero","mira",a="olla"),gesto("cocinero","senala",a="tazon"),CARD,{"wait":400},
  # 7: A. 8: B. Each drawn afresh
  {"dots":7}]+ronda92("a")+[{"dots":8}]+ronda92("b"),
 "final":[{"dots":9},baja3(lambda n:act("final92",n=n)),   # 9: the guests are gone; the small bowl, by what was lost
  # 10: the cocinero holds the red bottle over the bowl (no act named); the second turn (un poco); one drop (no act named); the frog eats
  {"dots":10},"c92_co_pique","c92_cq_poco",gesto("coqui","come"),"c92_fin",act("fin")],
 "leer":["c92_co_arroz","c92_co_falta_sal","c92_co_mejor","c92_co_delicioso","c92_co_esto","c92_ab_menos","c92_donde_perro","c92_ab_asi","c92_l_mas","c92_donde_mas","c92_l_mejor","c92_ca_asi","c92_donde_carmen","c92_ca_rico","c92_au_menos","c92_au_asi","c92_co_tu","c92_cq_mas",
  "c92_q_senora_menos","c92_q_joven_bien","c92_co_pique","c92_cq_poco","c92_fin"]}
s92=reuse(s92,{"c92_cq_mas":TG(("más",["más","mas","más por favor","mas por favor"])),"c92_cq_poco":TG(("un poco",["un poco","sí un poco","si un poco","un poquito","sí un poquito","si un poquito"]))})
json.dump(s92,open("cuentos/mas-y-menos.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
# every id the steps name (with no variable in it) is in the story's clips; every `leer` id too; every speaking turn is on a word of an earlier story (the files on disk: places 1 to 7)
earlier=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s90,s91,s92):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:90|91|92)_|si_|yo_|p_n_|b_n_|n_|esta_|cq_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
