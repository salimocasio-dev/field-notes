# A comer (place 3, scene 4): stories 33, 34, 35 and the scene's picture pairs. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/comer.md (final). Every line of the script is exactly one clip, word for word.
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t); AB=lambda t:D("abuela","Abuela",t); MA=lambda t:D("mama","Mamá",t); AO=lambda t:D("abuelo","Abuelo",t); PA=lambda t:D("papa","Papá",t)
tw=lambda k:{"set":{"twinkle":k}}
def act(_n,**k): return dict({"act":_n},**k)
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
say=lambda c,gap=250:{"say":c,"gap":gap}
ok=lambda:{"if":"ok","then":[act("marca",que="ok")]}
X=[act("marca",que="x"),{"cost":1}]
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story of A comer has two scored rounds: the card shows two places
MINE=("que-quieres","buen-provecho","cafe-con-azucar","cual-comer")
# a clip whose text and speaker are already recorded under another id keeps that id (nothing is recorded twice)
EX=collections.defaultdict(collections.Counter)
for f in glob.glob("cuentos/*.json"):
    if any(m in f for m in MINE) or "/z" in f: continue
    for cid,cl in json.load(open(f,encoding="utf-8")).get("clips",{}).items(): EX[(cl.get("who"),cl.get("habla"),cl["text"])][cid]+=1
def reuse(st):
    ren={}
    for cid,cl in list(st["clips"].items()):
        if "$" in cid or cid in DIN: continue
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
    return turnos(out)
# Speaking turns (docs/hablar/01-decisiones.md and 03; the six turns of the script comer.md, "Speaking turns", and comer-turnos-decisiones.md). A coquí clip with "tu_turno" is his turn.
# One target word and one accepted form each; no near-miss spellings. The mark is put on the clip once its id is settled (reuse() ends here). It adds no line and no clip: a turn whose
# clip is not in the story, or is never played in it, is reported (MISSING TURN LINE) and not made up.
TG=lambda w,f:[{"palabra":w,"formas":[f]}]
TURNOS={"que-quieres":{"bien_gracias":TG("bien","bien"),"cq_gracias_abuela":TG("gracias","gracias")},          # step 1 (set up by abuela_dice), step 7 (right after c33_ab_mas_pan)
        "buen-provecho":{"c34_cq_lleno":TG("lleno","lleno"),"c34_cq_bp_papa":TG("papá","papa")},              # step 4 (the signed ask di_lleno), the ending (after c34_papa_hola)
        "cafe-con-azucar":{"bien_gracias":TG("bien","bien"),"cq_gracias_abuela":TG("gracias","gracias")}}    # step 1 (set up by papa_hola_como), step 4 (after toma)
def turnos(st):
    def strs(o):   # every string in the steps (not the keys)
        if isinstance(o,str): yield o
        elif isinstance(o,list):
            for x in o: yield from strs(x)
        elif isinstance(o,dict):
            for x in o.values(): yield from strs(x)
    played=set(strs([st["beats"],st["final"]]))
    for cid,t in TURNOS.get(st["id"],{}).items():
        if cid in st["clips"] and cid in played: st["clips"][cid]["tu_turno"]=t
        else: print("MISSING TURN LINE",st["id"],cid)
    return st
DIN=set()   # ids that are put together in the story ("c33_papa_$ta_$na"): never renamed
comunes={"muy_bien":N("¡Muy bien!"),"si_muy_bien":N("¡Sí! ¡Muy bien!"),"yo_coqui":T("¡Coquí!"),"p_n_luis":N("Este es Luis."),"p_n_carmen":N("Esta es Carmen."),"abuela":N("Esta es abuela."),
 "esta_es_mama":N("Esta es mamá."),"n_papa":N("Este es papá."),"n_abuelo":N("Este es abuelo."),"m_n_cocina":N("Es la cocina.")}
BASE={"luis":"p_n_luis","carmen":"p_n_carmen","coqui":"yo_coqui","abuela":"abuela","mama":"esta_es_mama","papa":"n_papa","abuelo":"n_abuelo","cocina":"m_n_cocina"}
NOM={"abuelo":"Abuelo","mama":"Mamá","papa":"Papá","carmen":"Carmen","luis":"Luis","abuela":"Abuela"}
COS={"choc":"chocolate","mant":"mantequilla"}; ART={"choc":"el chocolate","mant":"la mantequilla"}; CON={"choc":"con chocolate","mant":"con mantequilla"}

# ---------------- 33. ¿Qué quieres? ----------------
c=dict(comunes)
c.update({"c33_caliente":N("El pan está caliente."),"c33_aqui_mant":N("Aquí hay mantequilla."),"c33_aqui_choc":N("Aquí hay chocolate."),"c31_aqui_pan":N("Aquí hay pan."),"c33_ab_mg_pan":AB("Me gusta el pan."),
 "c33_q_abuelo":T("¿Qué quieres, abuelo?"),"c33_q_mama":T("¿Qué quieres, mamá?"),"c33_q_luis":T("¿Qué quieres, Luis?"),"c33_q_papa":T("¿Qué quieres, papá?"),"c33_q_carmen":T("¿Qué quieres, Carmen?"),
 "c33_abuelo_mg_choc":AO("Me gusta el chocolate."),"c33_abuelo_nmg_mant":AO("No me gusta la mantequilla."),"c33_abuelo_come_choc":N("Abuelo come pan con chocolate."),
 "c33_mama_nmg_choc":MA("No me gusta el chocolate."),"c33_mama_mg_mant":MA("Me gusta la mantequilla."),"c33_mama_come_mant":N("Mamá come pan con mantequilla."),
 "c33_abuelo_nt_choc":AO("Mi pan no tiene chocolate."),"c33_luis_nmg_mant":L("No me gusta la mantequilla."),"c33_luis_come_choc":N("Luis come pan con chocolate."),"c33_mama_nt_mant":MA("Mi pan no tiene mantequilla."),
 "c33_ab_mas_pan":AB("Aquí hay más pan."),"c33_plato_no_tiene":N("El plato de abuela no tiene pan."),"c33_familia_come":N("La familia come pan."),"c33_cq_pan_abuela":T("¡Me gusta el pan de abuela!")})
for p,F in (("papa",PA),("carmen",CA)):
    for ty,txt in (("nmg","No me gusta %s."),("nt","Mi pan no tiene %s.")):
        for k in COS:
            i="c33_%s_%s_%s"%(p,ty,k); c[i]=F(txt%(ART[k] if ty=="nmg" else COS[k])); DIN.add(i)
    for k in COS:
        i="c33_no_%s_%s"%(p,k); c[i]=N("No, Coquí. Mira. %s quiere pan %s."%(NOM[p],CON[k])); DIN.add(i)
def paso33(p,lineas,k,comeline,rollo=0):
    # the person comes in (with a roll in his hand), is asked, says his lines, goes out; the sign is on the thing; the frog spoons it in; he comes back and eats it, during the line
    return [act("viene33",a=p,rollo=rollo),"c33_q_"+p]+lineas+[act("sale33",a=p),
      ask(k,None,then=[act("regresa33",a=p),act("come33",a=p,bien=1,suelto=1),comeline,act("ya")],after=[act("rellena33",a=p,k=k)])]
def juego33(p,Q,draws,lineid,ka,tt):
    return draws+[act("viene33",a=p,rollo=1),
     {"decide":"do","options":["mant","choc"],"pick":"$"+ka,"tests":"$"+tt,"lock":True,"mudo":True,"lead":["c33_q_"+p,lineid,act("sale33",a=p)],"line":lineid,
      "right":[{"if":"ok","then":[act("rellena33",a=p,k="$"+ka),act("regresa33",a=p),act("come33",a=p,bien=1),act("marca",que="ok")],
                "else":[act("rellena33",a=p,k="$"+ka),act("regresa33",a=p),act("come33",a=p,bien=1)]}],
      "wrong":[act("rellena33",a=p,k="$x"),act("regresa33",a=p),act("come33",a=p,bien=0)]+X+["c33_no_%s_$%s"%(p,ka)]}]
s33={"id":"que-quieres","title":"¿Qué quieres?","place":"La cocina","scene":"comer","next":"buen-provecho",
 "goal":"Fill each roll with what its eater likes.","stake":{"thing":"pan","steps":2},"dots":9,"bien":"si_muy_bien",
 "focus_words":["quieres","¿qué quieres?","me gusta","no me gusta"],"back_again":["pan","mantequilla","chocolate","caliente","tiene","quiere","come","aquí","más"],
 "also_heard":[],"names":BASE,"palabras":{"nmg":"no me gusta","nt":"tiene"},"clips":c,
 "beats":[act("inicio33"),{"wait":500},tw("cesta"),"c31_aqui_pan","c33_caliente",tw("mant"),"c33_aqui_mant",tw("choc"),"c33_aqui_choc",tw(None),act("plato33",suelto=1),"c33_ab_mg_pan",act("ya"),
  # the opening: five signed touches on a thing
  {"dots":1}]+paso33("abuelo",["c33_abuelo_mg_choc","c33_abuelo_nmg_mant"],"choc","c33_abuelo_come_choc")+[
  {"dots":2}]+paso33("mama",["c33_mama_nmg_choc","c33_mama_mg_mant"],"mant","c33_mama_come_mant")+[
  {"dots":3}]+paso33("abuelo",["c33_abuelo_nt_choc"],"choc","c33_abuelo_come_choc",rollo=1)+[
  {"dots":4}]+paso33("luis",["c33_luis_nmg_mant"],"choc","c33_luis_come_choc",rollo=1)+[
  {"dots":5}]+paso33("mama",["c33_mama_nt_mant"],"mant","c33_mama_come_mant",rollo=1)+[
  # the turn
  {"dots":6},act("turno33"),"c33_ab_mas_pan",act("apunta33",suelto=1),"c33_plato_no_tiene",act("ya"),act("sale33a"),act("miran33"),CARD,{"wait":400},
  # A: papá. One line of four, drawn: the answer, then which kind of line
  {"dots":7}]+juego33("papa","c33_q_papa",[{"draw":"ka","options":["choc","mant"],"other":"ja"},{"draw":"ta","options":["nmg","nt"],"other":"ua"},{"calc":"na","cond":"ta=nt","then":"$ka","else":"$ja"}],"c33_papa_$ta_$na","ka","ta")+[
  # B: Carmen. First a fair draw of the answer, then a line for that answer that A did not use
  {"dots":8}]+juego33("carmen","c33_q_carmen",[{"draw":"kb","options":["choc","mant"],"other":"jb"},{"draw":"tr","options":["nmg","nt"],"other":"ur"},{"calc":"tb","cond":"kb=$ka","then":"$ua","else":"$tr"},{"calc":"nb","cond":"tb=nt","then":"$kb","else":"$jb"}],"c33_carmen_$tb_$nb","kb","tb"),
 "final":[{"dots":9},act("final33",suelto=1),"c33_familia_come",act("ya"),{"if":"pan","then":[say("c33_cq_pan_abuela",300)]},act("fin")],
 "leer":["c31_aqui_pan","c33_caliente","c33_aqui_mant","c33_aqui_choc","c33_ab_mg_pan","c33_q_abuelo","c33_abuelo_mg_choc","c33_abuelo_nmg_mant","c33_abuelo_come_choc","c33_q_mama","c33_mama_nmg_choc","c33_mama_mg_mant","c33_mama_come_mant","c33_abuelo_nt_choc",
  "c33_q_luis","c33_luis_nmg_mant","c33_luis_come_choc","c33_mama_nt_mant","c33_ab_mas_pan","c33_plato_no_tiene","c33_familia_come","c33_cq_pan_abuela"]}
s33=reuse(s33)
json.dump(s33,open("cuentos/que-quieres.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 34. Buen provecho ----------------
c=dict(comunes)
LT={"abuelo":AO,"mama":MA,"carmen":CA}
c.update({"c34_papa_no_esta":N("Papá no está aquí."),"c34_plato_papa":N("Este plato es para papá."),"c34_cq_buen":T("¡Buen provecho!"),"cq_gracias_abuela":T("¡Gracias, abuela!"),"c34_familia_bp":N("La familia dice: ¡Buen provecho!"),
 "c34_abuelo_rico":AO("¡El arroz está rico!"),"c34_luis_rico":L("¡El arroz está rico!"),"c34_luis_todo":N("Luis se come todo el arroz."),"c34_luis_quiero":L("Quiero más arroz, por favor."),"c34_luis_y_tu":L("¿Y tú, Coquí?"),
 "c34_cq_tambien":T("¡Y yo también!"),"c34_cq_lleno":T("Yo estoy lleno."),"c34_cq_todo":N("Coquí se come todo el arroz."),
 "c34_mama_todo":N("Mamá se come todo el arroz."),"c34_abuelo_todo":N("Abuelo se come todo el arroz."),
 "c34_papa_hola":PA("¡Hola, familia!"),"c34_cq_bp_papa":T("¡Buen provecho, papá!"),"c34_papa_rico":PA("¡El arroz está rico!"),"c34_papa_todo":N("Papá se come todo el arroz."),
 "c34_no_quiere":N("No, Coquí. Mira. Tú quieres más arroz."),"c34_no_lleno":N("No, Coquí. Mira. Tú estás lleno.")})
for p,F in LT.items():
    c["c34_%s_tambien"%p]=F("Y yo también."); c["c34_%s_lleno"%p]=F("Yo estoy lleno." if p=="abuelo" else "Yo estoy llena."); c["c34_%s_levanto"%p]=F("Yo me levanto."); c["c34_%s_bp"%p]=F("¡Buen provecho!")
    c["c34_no_%s"%p]=N("No, Coquí. Mira. %s quiere más arroz."%NOM[p])
    for k in ("tambien","lleno","levanto","bp"): DIN.add("c34_%s_%s"%(p,k))
    DIN.add("c34_no_%s"%p)
DIN.update(["c34_no_quiere","c34_no_lleno"])
VT={"di_tambien":"c34_cq_tambien","di_lleno":"c34_cq_lleno"}
def dice(p):   # what each of the three says in round B: who says "también", who is full, who gets up, drawn (nobody shows a hand on the belly before the touch)
    return {"if":"qt=%s"%p,"then":["c34_%s_tambien"%p],"else":[{"if":"qf=%s"%p,"then":["c34_%s_lleno"%p],"else":["c34_%s_levanto"%p]}]}
CUARTO=[act("luis34",que="sirve"),act("luis34",que="entrega"),act("luis34",que="come",suelto=1)]
s34={"id":"buen-provecho","title":"Buen provecho","place":"La cocina","scene":"comer","next":"cafe-con-azucar",
 "goal":"Keep papá's lunch for him.","stake":{"thing":"arroz","steps":2},"dots":9,"bien":"si_muy_bien",
 "focus_words":["buen provecho","también","rico","todo"],"back_again":["arroz","más","quiero","quieres","quiere","por favor","gracias","come","aquí","hola","familia"],
 "also_heard":[],"names":BASE,"palabras":{"quiere":"también","lleno":"lleno","tambien":"también"},"clips":c,
 "beats":[act("inicio34"),{"wait":500},tw("silla_papa"),"c34_papa_no_esta",tw("pl_papa"),"c34_plato_papa",tw(None),
  # 2: he says it, taught
  {"dots":1},act("tenedores34"),
  ask("di_buen",None,then=["c34_abuelo_rico"],after=[act("come34",suelto=1),"c34_familia_bp",act("ya")],resp=["di_buen","di_gracias"],voces={"di_buen":"c34_cq_buen","di_gracias":"cq_gracias_abuela"},said={"di_buen":"c34_cq_buen"}),
  # 3: he says it, taught again (the first bubble first)
  {"dots":2},act("luisCome34",suelto=1),"c34_luis_rico","c34_luis_todo",act("ya"),"c34_luis_quiero",act("cuchara34"),act("luis34",que="sirve"),act("luis34",que="come"),act("luis34",que="cuchara",tiende=1),act("piensa34",k="quiere"),"c34_luis_y_tu",
  ask("di_tambien",None,after=[act("ranaCome34",lleno=1,suelto=1),"c34_cq_todo",act("ya")],resp=["di_tambien","di_lleno"],voces=VT,said={"di_tambien":"c34_cq_tambien"}),
  # 4: the other way round: the frog is full
  {"dots":3},"c34_luis_quiero",act("luis34",que="sirve"),act("luis34",que="come"),act("luis34",que="cuchara",tiende=1),act("piensa34",k="lleno"),"c34_luis_y_tu",
  ask("di_lleno",None,after=[act("luisCome2")],resp=["di_lleno","di_tambien"],voces=VT,said={"di_lleno":"c34_cq_lleno"}),
  # 5: touch a person of three, taught
  {"dots":4},act("plato34",a="carmen",v=""),"c34_luis_quiero",act("luis34",que="sirve"),act("luis34",que="entrega"),act("luis34",que="come",suelto=1),"c34_mama_tambien",act("mano34",a="abuelo"),"c34_abuelo_lleno","c34_carmen_levanto",act("ya"),
  ask("mama",None,after=[act("tipa34",a="mama",suelto=1),"c34_mama_todo",act("ya")],then=[act("mano34",a="abuelo",pose="idle"),act("levanta34",a="carmen",plato=1,suelto=1),"c34_carmen_bp",act("ya")]),
  # 6: and again, with the three in other places
  {"dots":5},act("vuelve34",a="carmen",plato=1),"c34_luis_quiero",act("luis34",que="sirve"),act("luis34",que="entrega"),act("luis34",que="come",suelto=1),"c34_abuelo_tambien",act("mano34",a="carmen"),"c34_carmen_lleno","c34_mama_levanto",act("ya"),
  ask("abuelo",None,after=[act("tipa34",a="abuelo",suelto=1),"c34_abuelo_todo",act("ya")],then=[act("mano34",a="carmen",pose="idle"),act("levanta34",a="mama",suelto=1),"c34_mama_bp",act("ya")]),
  # the turn
  {"dots":6},act("vuelve34",a="mama"),act("turno34"),CARD,{"wait":400},
  # A: say (his own wish). The thought is drawn: a mound with a heart, or his belly beside the clean plate
  {"dots":7},{"draw":"wa","options":["quiere","lleno"]},{"calc":"pa","cond":"wa=quiere","then":"di_tambien","else":"di_lleno"},
  "c34_luis_quiero",act("luis34",que="sirve"),act("luis34",que="come"),act("luis34",que="cuchara",tiende=1),act("piensa34",k="$wa"),"c34_luis_y_tu",
  {"decide":"say","options":["di_tambien","di_lleno"],"baraja":True,"pick":"$pa","tests":"$wa","voces":VT,"said":VT,"lead":[],"line":None,
   "right":[{"if":"ok","then":[{"if":"wa=quiere","then":[act("ranaCome34")],"else":[act("luisCome2")]},act("marca",que="ok")],
             "else":[{"if":"wa=quiere","then":[act("luisPapa34",para="rana")],"else":[act("levantaRana34"),act("luisPapa34",para="luis")]}]}],
   "wrong":[{"if":"wa=quiere","then":[act("luisCome2")],"else":[act("ranaCome34",entera=1)]}]+X+["c34_no_$wa"]},
  # B: touch a person of three
  {"dots":8},{"reparte":["qt","qf","ql"],"options":["abuelo","mama","carmen"]},"c34_luis_quiero"]+CUARTO+[dice("abuelo"),dice("mama"),dice("carmen"),act("ya"),
  {"decide":"do","options":["abuelo","mama","carmen"],"pick":"$qt","tests":"tambien","lock":True,"lead":[],"line":None,
   "right":[{"if":"ok","then":[act("tipa34",a="$qt"),act("marca",que="ok"),act("levanta34",a="$ql",suelto=1),"c34_$ql_bp",act("ya")],
             "else":[act("papaB34",a="$qt")]}],
   "wrong":[act("tipa34",a="$x",mezcla=1),{"if":"x=$qf","then":[act("llenoAhora34",a="$x")]},act("levanta34",a="$ql",suelto=1),"c34_$ql_bp",act("ya"),act("mira34",a="$qt")]+X+["c34_no_$qt"]}],
 "final":[{"dots":9},act("final34",suelto=1),"c34_papa_hola",act("ya"),say("c34_cq_bp_papa",300),act("papaCome34",suelto=1),"c34_papa_rico",act("ya"),act("papaCome34",fin=1,suelto=1),"c34_papa_todo",act("ya"),{"if":"pmont=1","then":[act("papaMira34")]},act("fin")],
 "leer":["c34_papa_no_esta","c34_plato_papa","c34_familia_bp","c34_abuelo_rico","c34_luis_rico","c34_luis_todo","c34_luis_quiero","c34_luis_y_tu","c34_cq_todo","c34_mama_tambien","c34_abuelo_lleno","c34_carmen_levanto","c34_mama_todo","c34_carmen_bp",
  "c34_abuelo_tambien","c34_carmen_lleno","c34_mama_levanto","c34_abuelo_todo","c34_mama_bp","c34_papa_hola","c34_cq_bp_papa","c34_papa_rico","c34_papa_todo"]}
s34=reuse(s34)
json.dump(s34,open("cuentos/buen-provecho.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 35. Café con azúcar ----------------
c=dict(comunes)
c.update({"c35_hace":N("Abuela hace café."),"c35_aqui_cafe":N("Aquí hay café."),"c35_aqui_azucar":N("Aquí hay azúcar."),"c35_huele":N("Huele a café."),"c35_coqui_pone":N("Coquí le pone azúcar al café."),
 "c35_luis_mucho":L("Mucho café, por favor."),"c35_carmen_poco":CA("Un poco de café, por favor."),"c35_carmen_mucho":CA("Mucho café, por favor."),"c35_luis_poco":L("Un poco de café, por favor."),
 "c35_luis_toma":N("Luis toma mucho café."),"c35_carmen_toma":N("Carmen toma un poco de café."),
 "c35_ab_quieres":AB("¿Quieres café, Coquí?"),"c35_cq_poco":T("Sí, un poco, por favor."),"c35_cq_mucho":T("Sí, mucho, por favor."),"c35_cq_rico":T("¡El café está rico!"),
 "c35_ab_cafe_mi":AB("¡Y café para mí!"),"c35_no_mucho":N("No, Coquí. Mira. Tú quieres mucho café."),"c35_no_poco":N("No, Coquí. Mira. Tú quieres un poco de café."),
 "c35_no_hay_cafe":AB("No hay más café."),"c35_no_hay_leche":AB("No hay más leche."),"c35_ab_toma":N("Abuela toma café."),"c35_cq_huele":T("¡Huele a café!")})
for p,F in (("abuelo",AO),("papa",PA)):
    c["c35_%s_azucar"%p]=F("Más azúcar, por favor."); c["c35_%s_cafe"%p]=F("Más café, por favor."); DIN.update(["c35_%s_azucar"%p,"c35_%s_cafe"%p])
    c["c35_no_%s"%p]=N("No, Coquí. Mira. %s quiere más café."%NOM[p]); DIN.add("c35_no_%s"%p)
VC={"di_poco":"c35_cq_poco","di_mucho":"c35_cq_mucho"}
def paso35(p,q,pq,qq,sign):   # step 2/3: abuelo and papá ask; the sign is on the one who asks for sugar
    return [act("tienden35",a="abuelo,papa"),act("trae35"),act("llena35"),pq,qq,
      ask(sign,None,after=[act("azucar35",a=sign,suelto=1),"c35_coqui_pone",act("ya"),act("cafe35",a="papa" if sign=="abuelo" else "abuelo")],then=[act("bajan35",a="abuelo,papa"),act("vuelve35")])]
s35={"id":"cafe-con-azucar","title":"Café con azúcar","place":"La cocina","scene":"comer","next":None,
 "goal":"Give everybody the cup he asks for.","stake":{"thing":"café","steps":2},"dots":9,"bien":"si_muy_bien",
 "focus_words":["café","azúcar","un poco","mucho"],"back_again":["leche","taza","toma","más","por favor","huele a","le pone","no hay","rico","sí","quieres"],
 "also_heard":[],"names":BASE,"palabras":{"azucar":"azúcar","poco":"un poco","mucho":"mucho"},"clips":c,
 "beats":[act("inicio35"),{"wait":500},"c35_hace",tw("cafetera"),"c35_aqui_cafe",tw("azucarera"),"c35_aqui_azucar",tw(None),"c35_huele",
  # 2 and 3: touch a person (sugar), taught twice, the lines the other way round
  {"dots":1}]+paso35("abuelo","papa","c35_abuelo_azucar","c35_papa_cafe","abuelo")+[
  {"dots":2}]+paso35("abuelo","papa","c35_abuelo_cafe","c35_papa_azucar","papa")+[
  # 4 and 5: scenes, no sign
  {"dots":3},act("pote35"),act("ninos35",que="ponen"),"c35_luis_mucho","c35_carmen_poco",act("ninos35",que="salen"),act("vierte35",a="luis",cant="mucho"),act("vierte35",a="carmen",cant="poco"),act("ninos35",que="vuelven"),act("ninos35",que="toman",suelto=1),"c35_luis_toma","c35_carmen_toma",act("ya"),
  {"dots":4},act("ninos35",que="ponen"),"c35_carmen_mucho","c35_luis_poco",act("ninos35",que="salen"),act("vierte35",a="carmen",cant="mucho"),act("vierte35",a="luis",cant="poco"),act("ninos35",que="vuelven"),act("ninos35",que="toman"),
  # 6: he says it, taught twice
  {"dots":5},act("piensa35",k="palido"),"c35_ab_quieres",
  ask("di_poco",None,after=[act("sirve6",cant="poco"),act("rana35bebe")],resp=["di_poco","di_mucho"],voces=VC,said={"di_poco":"c35_cq_poco"}),
  act("piensa35",k="marron"),"c35_ab_quieres",
  ask("di_mucho",None,after=[act("sirve6",cant="mucho"),act("rana35bebe")],then=[say("c35_cq_rico",300)],resp=["di_poco","di_mucho"],voces=VC,said={"di_mucho":"c35_cq_mucho"}),
  # the turn
  {"dots":6},act("turno35"),"c35_ab_cafe_mi",act("sientaAb35"),CARD,{"wait":400},
  # A: touch a person (sugar). Who asks for sugar and who speaks first are drawn
  {"dots":7},{"draw":"sa","options":["abuelo","papa"],"other":"ca"},{"draw":"oa","options":["1","2"]},act("turnoA35"),
  {"if":"oa=1","then":["c35_$sa_azucar","c35_$ca_cafe"],"else":["c35_$ca_cafe","c35_$sa_azucar"]},
  {"decide":"do","options":["abuelo","papa"],"pick":"$sa","tests":"azucar","lock":True,"lead":[],"line":None,
   "right":[{"if":"ok","then":[act("azucar35",a="$sa",suelto=1),act("cafe35",a="$ca",dedo=1),act("ya"),act("marca",que="ok")],
             "else":[act("llena35"),act("azucar35",a="$sa")]},act("despuesA35")],
   "wrong":[act("azucar35",a="$x",mal=1,suelto=1),act("cafe35",a="$x",dedo=1,mal=1),act("ya"),act("empuja35",a="$x")]+X+["c35_no_$x"]},
  # B: say (his own cup)
  {"dots":8},{"draw":"wb","options":["poco","mucho"],"other":"vb"},act("piensa35",k="$wb"),act("pregunta35"),"c35_ab_quieres",
  {"decide":"say","options":["di_poco","di_mucho"],"baraja":True,"pick":"di_$wb","tests":"$wb","voces":VC,"said":VC,"lead":[],"line":None,
   "right":[act("sirveB35",cant="$wb"),{"if":"ok","then":[act("rana35bebe"),act("marca",que="ok")],"else":[act("bebeAb35"),{"if":"wb=mucho","then":[act("muestra35",k="taza"),act("muestra35",k="jarrita"),act("muestra35",k="cazo"),"c35_no_hay_cafe"],"else":[act("muestra35",k="taza"),act("muestra35",k="jarrita"),act("muestra35",k="cazo"),"c35_no_hay_leche"]}]}],
   "wrong":[act("sirveB35",cant="$x"),act("pruebaB35")]+X+["c35_no_$wb"]}],
 "final":[{"dots":9},act("final35",suelto=1),{"if":"cafe","then":["c35_ab_toma"]},act("ya"),say("c35_cq_huele",300),act("fin")],
 "leer":["c35_hace","c35_aqui_cafe","c35_aqui_azucar","c35_huele","c35_abuelo_azucar","c35_papa_cafe","c35_coqui_pone","c35_abuelo_cafe","c35_papa_azucar","c35_luis_mucho","c35_carmen_poco","c35_luis_toma","c35_carmen_toma","c35_carmen_mucho","c35_luis_poco","c35_ab_quieres","c35_cq_poco","c35_cq_mucho","c35_cq_rico","c35_ab_cafe_mi","c35_ab_toma","c35_cq_huele"]}
s35=reuse(s35)
json.dump(s35,open("cuentos/cafe-con-azucar.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- the next-day picture pairs ----------------
# Every picture has the same framing (CAMP: the table, the floor in front of it, the heads of those who sit), nothing is cropped, nothing is blurred.
NO={"x":0,"y":0,"s":1,"dy":0,"al":1,"vis":0,"bub":None,"hace":None,"piensa":None,"tiene":[],"sobre":1}
CAMP=[32,80,196,104]
def pic(cam=None,**kw): return {"cam":cam or CAMP,"set":dict({"cq":NO,"gente":{},"cosas":[],"vuelos":[],"perro":None,"tarjeta":None,"marcas":None,"sitio":{}},**kw)}
def P(x,y,dir=1,**kw): return dict({"x":x,"y":y,"dir":dir},**kw)
def ti(k,dx,dy,**kw): return dict({"k":k,"dx":dx,"dy":dy},**kw)
def Q(x,y,e=2): return {"k":"interroga","x":x,"y":y,"e":e,"z":900}
def cosa(k,x,y,**kw): return dict({"k":k,"x":x,"y":y},**kw)
def corazon(x,y): return cosa("corazon",x,y,e=2,z=900)
PL=lambda id,x,v="": {"id":id,"k":"plato","x":x,"y":127,"v":v,"rollos":[]}
PARC={"m_c_quieres":N("¿Quieres pan?"),"m_c_que_quieres":AB("¿Qué quieres?"),"m_c_me_gusta":L("Me gusta el pollo."),"m_c_no_me_gusta":CA("No me gusta la manzana."),"m_c_rico":N("¡El bizcocho está rico!"),"m_c_buen_provecho":N("¡Buen provecho!"),
 "m_c_tambien":N("Luis come pan. Carmen también."),"m_c_todo":N("Canelo se lo come todo."),"m_c_cafe":N("Mamá toma café."),"m_c_azucar":N("Abuela le pone azúcar al café."),"m_c_un_poco":N("Un poco de arroz, por favor."),"m_c_mucho":N("Aquí hay mucho jugo.")}
USA=list(PARC)+["muy_bien","si_muy_bien"]
todos={**c,**s33["clips"],**s34["clips"],**s35["clips"],**PARC}
# two pots with a spoon over each, in abuela's two hands: each spoon is as long as her forearm, the hand at her side, the bowl over its pot
def dosCucharas(): return [dict(k="uten",ax=10,ay=34,bx=24,by=27,load="",o={"plata":1,"rx":4,"ry":3}),dict(k="uten",ax=-10,ay=34,bx=-24,by=27,load="",o={"plata":1,"rx":4,"ry":3})]
plato_manzana=lambda x:cosa("platoma",x,160,e=2)
CERCA1=[30,128,98,52]; CERCA2=[142,128,98,52]   # the closer pictures: waist up, so that the faces read; the kitchen stays behind them (the counter at the left, the stove at the right)
cualj={"id":"cual-comer","title":"¿Cuál?","place":"La cocina","scene":"comer","tipo":"cual","stake":{"thing":"none","steps":0},
 "note":"The next-day pass for A comer.","clips":{k:todos[k] for k in USA},
 "items":[
  {"w":"quieres","say":"m_c_quieres","si":pic(gente={"abuela":P(96,184,1,pose="offer",tiene=[ti("rollo",27,30,v="ce")]),"luis":P(150,184,-1,pose="offer")}),
                                    "no":pic(gente={"abuela":P(112,184,1),"luis":P(152,184,-1,tiene=[ti("plato",14,24,dos=11,v="")])},cosas=[cosa("cesta",88,172,v="4:0",e=1),Q(152,118)])},
  {"w":"¿qué quieres?","say":"m_c_que_quieres","si":pic(gente={"abuela":P(140,184,-1,tiene=dosCucharas()),"carmen":P(76,184,1)},cosas=[cosa("olla",116,176,v="lleno0",vapor=1,e=1),cosa("olla",164,176,v="lleno0",vapor=1,e=1),Q(140,118)]),
                                              "no":pic(gente={"abuela":P(142,184,-1,pose="offer",tiene=[ti("plato",24,30,e=1,v="rm")]),"carmen":P(94,184,1)},cosas=[Q(142,118)])},
  {"w":"me gusta","say":"m_c_me_gusta","si":pic(gente={"luis":P(124,184,1,boca=1,come={"k":"muslo","v":"b","e":1,"dx":15})},cosas=[corazon(150,132)]),
                                      "no":pic(gente={"luis":P(104,184,1,tiene=[ti("muslo",24,30)]),"carmen":P(172,184,-1,pose="offer")})},
  {"w":"no me gusta","say":"m_c_no_me_gusta","si":pic(CERCA1,gente={"carmen":P(68,194,1,cara="ceno",tiene=[ti("platoma",24,24,dos=11)])}),
                                               "no":pic(CERCA1,gente={"carmen":P(68,194,1,cara="calma",tiene=[ti("platoma",24,24),dict(k="brazo",gx=3,gy=13,sh=-1)])})},
  {"w":"rico","say":"m_c_rico","si":pic(CERCA2,gente={"abuelo":P(176,194,1,cierra=1,boca=1,come={"k":"tenedor","v":"t","e":1,"dx":11},tiene=[dict(k="brazo",gx=3,gy=14,sh=-1)])},cosas=[cosa("bizcocho",156,166,e=1)]),
                               "no":pic(CERCA2,gente={"abuelo":P(176,194,1,sopla=1,come={"k":"tenedor","v":"t","e":1,"dx":14,"vapor":1})},cosas=[cosa("bizcocho",156,166,e=1)])},
  {"w":"buen provecho","say":"m_c_buen_provecho","si":pic(gente={"mama":P(90,132,1,sent=1,come={"k":"tenedor","dx":12}),"abuelo":P(114,132,1,sent=1,come={"k":"tenedor","dx":12}),"carmen":P(138,132,1,sent=1,come={"k":"tenedor","dx":12}),"luis":P(200,168,-1,pose="wave0",tiene=[ti("plato",20,30,v="")])},
                                                    cosas=[PL("pl_mama",90,"r"),PL("pl_abuelo",114,"r"),PL("pl_carmen",138,"r")]),
                                       "no":pic(gente={"luis":P(50,152,1,boca=1,tiene=[ti("plato",15,36,e=1)]),"carmen":P(72,152,1,boca=1,z=200,tiene=[ti("plato",15,34,e=1)]),"abuelo":P(112,182,-1,boca=1,tiene=[ti("plato",16,26,e=1)])})},
  {"w":"también","say":"m_c_tambien","si":pic(gente={"luis":P(100,182,1,come={"k":"rollo","v":"mo:c","e":1,"dx":14}),"carmen":P(152,182,-1,come={"k":"rollo","v":"mo:m","e":1,"dx":14})}),
                                      "no":pic(gente={"luis":P(100,182,1,come={"k":"rollo","v":"mo:c","e":1,"dx":14}),"carmen":P(152,182,-1)})},
  {"w":"todo","say":"m_c_todo","si":pic(perro=dict(x=108,y=177,pose="eat",dir=1,lengua=1,e=2),cosas=[cosa("cuenco",164,177,v="limpio",e=2)]),
                                "no":pic(perro=dict(x=118,y=177,pose="walk",dir=-1,granos=1,e=2),cosas=[cosa("cuenco",164,177,v="lleno",e=2)])},
  {"w":"café","say":"m_c_cafe","si":pic(gente={"mama":P(108,184,1,tiene=[ti("taza",15,32,v="negro",vapor=1,vn=1)])},cosas=[cosa("cafetera",160,160,e=1,vapor=1,vdy=24,vn=1)]),
                              "no":pic(gente={"mama":P(108,184,1,tiene=[ti("vasojugo",14,30)])},cosas=[cosa("cafetera",160,160,e=1)])},
  {"w":"azúcar","say":"m_c_azucar","si":pic(gente={"abuela":P(116,184,1,tiene=[dict(k="uten",ax=14,ay=34,bx=27,by=40,load="azu",o={"plata":1,"rx":4,"ry":3})])},cosas=[cosa("taza",146,168,v="negro",vapor=1,vn=1),cosa("granos",143,152,e=1,z=900),cosa("granos",147,156,e=1,z=900),cosa("granos",144,160,e=1,z=900)]),
                                "no":pic(gente={"abuela":P(116,184,1,tiene=[ti("tiltjarraleche",22,40,e=1,v="suave",flip=True,chorro={"h":18,"col":"#FFFFFF"})])},cosas=[cosa("taza",150,168,v="negro",vapor=1,vn=1)])},
  {"w":"un poco","say":"m_c_un_poco","si":pic(gente={"abuela":P(108,184,1,tiene=[dict(k="uten",ax=14,ay=32,bx=28,by=38,load="arr",o={"plata":1,"rx":5,"ry":3})]),"carmen":P(178,184,-1)},cosas=[cosa("plato",142,172)]),
                                  "no":pic(gente={"abuela":P(108,184,1,tiene=[dict(k="uten",ax=14,ay=32,bx=28,by=38,load="ARR",o={"plata":1,"rx":5,"ry":3})]),"carmen":P(178,184,-1)},cosas=[cosa("plato",142,172)])},
  {"w":"mucho","say":"m_c_mucho","si":pic(cosas=[cosa("jugo",128,164)]),"no":pic(cosas=[cosa("jugopoco",128,164)])}]}
for it in cualj["items"]:
    for k in ("si","no"):
        for o in it[k]["set"]["cosas"]:
            if o.get("z") is None and o["k"] in ("corazon","interroga"): o["z"]=900
json.dump(cualj,open("cuentos/cual-comer.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

# the story before this scene leads into it (jugo-de-china: set in gen_nevera.py)

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
for st in (s33,s34,s35):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:31|33|34|35|26)_|cq_|si_|muy_)[a-z_0-9$]+)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
