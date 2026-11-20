# Los estantes (place 4, El colmado, scene 2): stories 39, 40, 41. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/estantes.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `estantes` is not built yet: its acts are the ones of the script's Needs list; `marca` (the card's tick), `ya` and `fin` are the acts every scene has.
# Run order for the twelve stories of El colmado: gen_mostrador, gen_estantes, gen_frutas, gen_caja (each sees only what was recorded before it).
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
PE=lambda t:D("pepe","Don Pepe",t); LU=lambda t:D("luis","Luis",t); SA=lambda t:D("senora","La señora",t); SO=lambda t:D("senor","El señor",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's twinkle on a thing he can touch
def act(_n,**k): return dict({"act":_n},**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
ok=lambda:{"if":"ok","then":[act("marca",que="ok")]}
X=[act("marca",que="x"),{"cost":1}]
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story of this scene has two scored rounds: the card shows two places
# a variable that starts at a value (a one-option draw), and counts that go down by one
start=lambda v,n:{"draw":v,"options":[n]}
dec2=lambda v:{"calc":v,"cond":v+"=2","then":"1","else":"0"}      # 2 -> 1 -> 0 (what is left in the box)
dec3=lambda v:{"calc":v,"cond":v+"=3","then":"2","else":"1"}      # 3 -> 2 -> 1 (what the shelf will hold for the customer)
MINE=("latas-y-botellas","siete-latas","diez-botellas","la-sopa-de-abuela","esta-bueno","una-libra","cuanto-es","caro-y-barato","el-cambio")   # this generator's stories and the ones after them: not seen
# a clip whose text and speaker are already recorded under another id keeps that id (nothing is recorded twice). Ties go to the id most used, then to the earliest story of the course.
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
DIN=set()   # ids that are put together in the story ("c39_dame_$ka"): never renamed
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
    out["leer"]=list(dict.fromkeys(out["leer"]))     # a reading text names a line once
    out=mark_turns(out,{ren.get(c,c):t for c,t in turnos.items()})
    for cid,cl in out["clips"].items(): ex_add(cid,cl)    # the next story of this run reuses this one's lines
    return out
# Speaking turns: a coquí clip with "tu_turno" is his turn. The word is as it is in an earlier story's focus_words; the forms are the script's own ("[TURN: sí (sí, si)]" is "sí" with the forms "sí" and "si").
# The mark is put on the clip once its id is settled (reuse() ends here). It adds no line and no clip: a turn whose clip is never played in the story is reported.
TG=lambda *p:[{"palabra":w,"formas":list(f)} for w,f in p]
def mark_turns(st,turnos):
    def strs(o):   # every string in the steps (not the keys)
        if isinstance(o,str): yield o
        elif isinstance(o,list):
            for x in o: yield from strs(x)
        elif isinstance(o,dict):
            for x in o.values(): yield from strs(x)
    played=set(strs([st["beats"],st["final"]]))
    for cid,t in turnos.items():
        if cid in st["clips"] and cid in played: st["clips"][cid]["tu_turno"]=t
        else: print("MISSING TURN LINE",st["id"],cid)
    return st
# the clips every story of the scene shares: the praise, and the lines of the free poke for the people who are already recorded
comunes={"si_muy_bien":N("¡Sí! ¡Muy bien!"),"p_n_luis":N("Este es Luis."),"yo_coqui":T("¡Coquí!"),"b_n_senor":N("Es un señor."),"b_n_senora":N("Es una señora."),"c_n_perro":N("Es el perro. Se llama Canelo.")}
def comun(*ids): return {i:comunes[i] for i in ids}
NOM={"luis":"p_n_luis","coqui":"yo_coqui","senor":"b_n_senor","senora":"b_n_senora","perro":"c_n_perro"}
def nombres(*ks): return {k:NOM[k] for k in ks}
VARS={}   # every value a $variable of a clip id can take: checked at the end, so that no built id is missing

# ---------------- 39. Latas y botellas ----------------
c=comun("si_muy_bien","p_n_luis","yo_coqui","b_n_senor","b_n_senora")
c.update({"c39_caja":N("Don Pepe tiene una caja grande."),"c39_hay_latas":N("En la caja hay latas. Esta es una lata."),"c39_esta_botella":N("Y esta es una botella."),
 "c39_dame_lata":PE("Coquí, dame una lata."),"c39_dame_botella":PE("Coquí, dame una botella."),"c39_tira_lata":N("Coquí tira la lata. ¡Don Pepe coge la lata!"),"c39_ahora_botella":PE("Ahora, dame una botella."),
 "c39_l_latas":LU("¿Cuántas latas hay? Una, dos. Dos latas."),"c39_l_botellas":LU("¿Y cuántas botellas hay?"),"c39_cq_dos":T("¡Dos!"),
 "c39_no_veo":PE("¡Ay! No veo nada. ¡Ayúdame, Coquí!"),"c39_no_lata":N("No, Coquí. Mira. Esta es una lata."),"c39_no_botella":N("No, Coquí. Mira. Esta es una botella."),
 "c39_luis_busca":N("Luis busca en la caja."),"c39_aqui_tiene":LU("¡Aquí tiene, don Pepe!"),
 "c39_sa_buenos_dias":SA("¡Buenos días!"),"c39_cq_buenos_dias":T("¡Buenos días, señora!"),"c39_sa_necesito":SA("Necesito tres botellas."),"c39_so_necesito":SO("Y yo necesito tres latas."),
 "c39_p_cuantas":PE("¿Cuántas botellas hay?"),"c39_p_tres":PE("Una, dos, tres. Aquí tiene."),"c39_p_dos":PE("Una, dos. No hay más botellas."),"c39_p_uno":PE("Una. No hay más botellas."),"c39_p_no_latas":PE("No hay más latas.")})
DIN.update(["c39_dame_lata","c39_dame_botella","c39_no_lata","c39_no_botella"]); VARS.update({"ka":["lata","botella"],"kb":["lata","botella"]})
def ronda39(k,dots):
    # a can or a bottle, drawn afresh. Right: the frog tosses the kind asked for and it is caught. Wrong: the frog tosses the other kind: it breaks, or rolls out; what the box and the shelf hold goes down
    return [{"dots":dots},{"draw":k,"options":["lata","botella"]},
     {"decide":"do","options":["lata","botella"],"pick":"$"+k,"tests":"$"+k,"lock":True,"lead":[],"line":"c39_dame_$"+k,
      "right":[{"if":k+"=lata","then":[dec2("ca")],"else":[dec2("bo")]},act("lanza",k="$"+k,ok=1),ok()],
      "wrong":[{"if":"x=lata","then":[dec2("ca"),dec3("pl")],"else":[dec2("bo"),dec3("pb")]},act("lanza",k="$x",ok=0)]+X+["c39_no_$"+k]}]
def resto39():   # the frog tosses up what is left in the box, one by one
    return [{"if":"ca=2","then":[act("lanza",k="lata",ok=1),act("lanza",k="lata",ok=1)]},{"if":"ca=1","then":[act("lanza",k="lata",ok=1)]},
            {"if":"bo=2","then":[act("lanza",k="botella",ok=1),act("lanza",k="botella",ok=1)]},{"if":"bo=1","then":[act("lanza",k="botella",ok=1)]}]
s39={"id":"latas-y-botellas","title":"Latas y botellas","place":"El colmado","scene":"estantes","next":"siete-latas",
 "goal":"Toss don Pepe the cans and bottles he asks for, so the shelf is full for the two customers.","stake":{"thing":"cosas","steps":2},"dots":7,"bien":"si_muy_bien",
 "focus_words":["lata","botella","caja","¿cuántos?"],"formas_foco":{"lata":["latas"],"botella":["botellas"],"¿cuántos?":["¿cuántas?"]},
 "back_again":["uno","dos","tres","hay","dame","tira","coge","aquí","colmado","necesito","aquí tiene","buenos días"],
 "also_heard":["no veo nada","ayúdame"],"names":nombres("luis","coqui","senor","senora"),"clips":c,
 "beats":[act("cliente",quien="senora",lleva="botella",n=3),act("cliente",quien="senor",lleva="lata",n=3),
  # the opening: the box, a can, a bottle; two signed asks; Luis counts what is left
  {"dots":1},"c39_caja",act("abre39"),act("saca",k="lata"),"c39_hay_latas",act("saca",k="botella"),"c39_esta_botella",
  {"dots":2},act("sube"),ask("lata","c39_dame_lata",after=con(act("lanza",k="lata",ok=1),"c39_tira_lata")),
  {"dots":3},ask("botella","c39_ahora_botella",after=[act("lanza",k="botella",ok=1)]),
  {"dots":4}]+con(act("cuenta",k="lata",n=2,quien="luis"),"c39_l_latas")+[act("cuenta",k="botella",n=2,quien="luis"),"c39_l_botellas","c39_cq_dos",
  # the turn: his glasses fall into the box
  act("gafas",que="caen"),act("busca39"),"c39_no_veo",CARD,{"wait":400},
  start("ca","2"),start("bo","2"),start("pb","3"),start("pl","3")]    # two cans and two bottles left in the box; three bottles and three cans for the shelf, less what is lost
  +ronda39("ka",5)+ronda39("kb",6),
 "final":[{"dots":7},"c39_luis_busca",act("gafas",que="halla"),"c39_aqui_tiene",{"set":{"gafas":1}}]+resto39()+[
  # the customers: what the shelf holds is what they get. Don Pepe counts the bottles aloud, finger on each
  "c39_sa_buenos_dias","c39_cq_buenos_dias","c39_sa_necesito","c39_so_necesito","c39_p_cuantas",
  {"if":"pb=3","then":con(act("cuenta",k="botella",n=3,quien="pepe"),"c39_p_tres"),
   "else":[{"if":"pb=2","then":con(act("cuenta",k="botella",n=2,quien="pepe"),"c39_p_dos"),"else":con(act("cuenta",k="botella",n=1,quien="pepe"),"c39_p_uno")}]},
  act("cliente",quien="senora",lleva="botella",n="$pb"),{"if":"!pb=3","then":[act("mira",quien="senora",a="mano")]},
  act("cliente",quien="senor",lleva="lata",n="$pl"),{"if":"!pl=3","then":["c39_p_no_latas"]},
  act("fin")],
 "leer":["c39_caja","c39_hay_latas","c39_esta_botella","c39_dame_lata","c39_tira_lata","c39_ahora_botella","c39_l_latas","c39_l_botellas","c39_cq_dos","c39_no_veo","c39_dame_botella","c39_dame_lata",
  "c39_luis_busca","c39_aqui_tiene","c39_sa_buenos_dias","c39_cq_buenos_dias","c39_sa_necesito","c39_so_necesito","c39_p_cuantas","c39_p_tres"]}
s39=reuse(s39,{"c39_cq_dos":TG(("dos",["dos"])),"c39_cq_buenos_dias":TG(("buenos días",["buenos días","buenos dias"]))})
json.dump(s39,open("cuentos/latas-y-botellas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 40. Siete latas ----------------
c=comun("si_muy_bien","p_n_luis","yo_coqui","c_n_perro")
c.update({"c40_muchas":N("Don Pepe tiene muchas latas."),"c40_siete":PE("Una, dos, tres, cuatro, cinco, seis, siete. ¡Siete latas!"),"c40_seis_latas":PE("Una, dos, tres, cuatro, cinco, seis. Seis latas."),
 "c40_l_redes":LU("Aquí hay cinco latas. Y aquí hay cuatro."),"c40_op_cinco":PE("Coquí, dame cinco latas."),"c40_cinco":PE("¡Cinco!"),"c40_op_cuatro":PE("Y ahora, cuatro latas."),
 "c40_ay_canelo":N("¡Ay, no! ¡Canelo!"),"c40_ven_aca":LU("¡Canelo, ven acá!"),"c40_otra_vez":PE("¿Otra vez, Coquí?"),"c40_cq_mas":T("¡Sí, más latas!"),
 "c40_siete_aqui":PE("Siete latas aquí."),"c40_dame_seis":PE("Dame seis latas."),"c40_seis":PE("¡Seis!"),"c40_no_seis":N("No, Coquí. Mira. Aquí hay seis latas."),
 "c40_dame_cinco":PE("Dame cinco latas."),"c40_no_cinco":N("No, Coquí. Mira. Aquí hay cinco latas."),
 "c40_cuantas":PE("¿Cuántas latas hay?"),"c40_cuatro":PE("Una, dos, tres, cuatro. ¡Cuatro latas!"),"c40_dos":PE("Una, dos. Dos latas."),"c40_no_hay":N("No hay más latas."),
 "c40_l_donde":LU("¿Dónde está Canelo?"),"c40_cq_aqui":T("¡Aquí está!")})
def ronda40(r,dots,pido,otra,l_pido,seg,l_no):
    # two nets on the crate: the number he asks for, and one that is two more or two fewer. Which net is the right one is drawn, so that no side is the answer
    # (the script draws nothing here: see the report). A wrong net: don Pepe counts it, shakes his head, and two cans fall out of it on the way back
    return [{"dots":dots},{"draw":r,"options":["red_a","red_b"]},
     {"calc":"p"+r,"cond":r+"=red_a","then":str(pido),"else":str(otra)},{"calc":"q"+r,"cond":r+"=red_a","then":str(otra),"else":str(pido)},
     act("redes",a="$p"+r,b="$q"+r),
     {"decide":"do","options":["red_a","red_b"],"pick":"$"+r,"tests":seg,"lock":True,"lead":[],"line":l_pido,
      "right":[act("pone",n=pido,ok=1),{"if":"ok","then":[("c40_"+seg),act("marca",que="ok")]}],
      "wrong":[act("pone",n=otra,ok=0)]+X+[l_no,act("cuenta",k="lata",n=pido,quien="luis")]}]
s40={"id":"siete-latas","title":"Siete latas","place":"El colmado","scene":"estantes","next":"diez-botellas",
 "goal":"Build don Pepe's pyramid of cans by carrying over the net with the number of cans he asks for.","stake":{"thing":"latas","steps":2},"dots":7,"bien":"si_muy_bien",
 "focus_words":["cuatro","cinco","seis","siete"],"formas_foco":{},"back_again":["uno","dos","tres","lata","¿cuántas?","hay","dame","más","mucho","mira","otra vez","aquí"],
 "also_heard":["acá"],"names":nombres("luis","coqui","perro"),"clips":c,
 "beats":[
  # the opening: two rows laid can by can, counted; two nets, two signed asks
  {"dots":1},act("mira",quien="pepe",a="dibujo"),"c40_muchas"]+con(act("fila",n=7,una=1),"c40_siete")+con(act("fila",n=6,una=1),"c40_seis_latas")+[
  {"dots":2},act("redes",a=5,b=4),"c40_l_redes",ask("red_a","c40_op_cinco",after=[act("pone",n=5,ok=1),"c40_cinco"]),
  {"dots":3},ask("red_b","c40_op_cuatro",after=[act("pone",n=4,ok=1),act("bandera")]),
  # the turn: Canelo brings the pyramid down
  {"dots":4}]+con(act("tumba"),"c40_ay_canelo","c40_ven_aca")+[act("mira",quien="pepe",a="coqui"),"c40_otra_vez","c40_cq_mas",CARD,{"wait":400}]
  # the game: the bottom row again, then two rounds
  +con(act("fila",n=7,una=1),"c40_siete_aqui")
  +ronda40("ra",5,6,4,"c40_dame_seis","seis","c40_no_seis")+ronda40("rb",6,5,7,"c40_dame_cinco","cinco","c40_no_cinco"),
 "final":[{"dots":7},{"calc":"rn","cond":"lost=1","then":"2","else":"0"},{"calc":"rn","cond":"!lost","then":"4","else":"$rn"},act("resto",n="$rn"),"c40_cuantas",
  {"if":"lost","then":[{"if":"lost=1","then":["c40_dos"],"else":["c40_no_hay"]}],"else":["c40_cuatro",act("bandera")]},
  # Canelo is back, good now
  act("mira",quien="luis",a="tienda"),"c40_l_donde","c40_cq_aqui",act("fin")],
 "leer":["c40_muchas","c40_siete","c40_seis_latas","c40_l_redes","c40_op_cinco","c40_cinco","c40_op_cuatro","c40_ay_canelo","c40_ven_aca","c40_otra_vez","c40_cq_mas","c40_siete_aqui","c40_dame_seis","c40_seis","c40_dame_cinco","c40_cinco",
  "c40_cuantas","c40_cuatro","c40_l_donde","c40_cq_aqui"]}
s40=reuse(s40,{"c40_cq_mas":TG(("más",["más","mas"]),("lata",["latas"])),"c40_cq_aqui":TG(("aquí",["aquí","aqui"]))})
json.dump(s40,open("cuentos/siete-latas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 41. Diez botellas ----------------
c=comun("si_muy_bien","p_n_luis","yo_coqui","b_n_senor","b_n_senora")
c.update({"c41_necesita":LU("Abuela necesita diez botellas."),"c41_cuantas_caja":N("¿Cuántas botellas hay en la caja? Una, dos, tres, cuatro, cinco, seis, siete."),
 "c41_cuidado":PE("¡Ay! ¡Cuidado!"),"c41_otra_botella":PE("Aquí va otra botella."),"c41_cuantas_ahora":N("¿Cuántas hay ahora?"),"c41_ocho":N("¡Ocho! Ocho botellas."),
 "c41_otra_q":PE("¿Otra?"),"c41_cq_si_favor":T("¡Sí, por favor!"),"c41_y_ahora":N("¿Y ahora?"),"c41_nueve":N("¡Nueve! Nueve botellas."),
 "c41_y_otra":PE("Y otra."),"c41_diez_abuela":N("¡Diez! Diez botellas para abuela."),
 "c41_sa_buenos_nec":SA("¡Buenos días! Necesito diez botellas."),"c41_so_tambien":SO("Y yo también. Diez botellas."),
 "c41_q_senora":PE("Coquí, ¿cuántas botellas tiene la señora?"),"c41_q_senor":PE("¿Y cuántas botellas tiene el señor?"),
 "c41_cq_ocho":T("¡Ocho!"),"c41_cq_nueve":T("¡Nueve!"),"c41_cq_siete":T("¡Siete!"),"c41_cq_diez":T("¡Diez!"),   # the four voices of the number bubbles (the script's Needs)
 "c41_diez_8":PE("Otra. Y otra. ¡Diez!"),"c41_diez_9":PE("Otra. ¡Diez!"),"c41_no_ocho":N("No, Coquí. Mira. Hay ocho."),"c41_no_nueve":N("No, Coquí. Mira. Hay nueve."),
 "c41_para_ti":PE("Y esta es para ti, Coquí."),"c41_cq_gracias_pepe":T("¡Gracias, don Pepe!"),"c41_no_hay":N("No hay más botellas."),"c41_senor_nueve":N("El señor tiene nueve botellas. No hay más."),
 "c41_sa_gracias":SA("¡Gracias!"),"c41_cq_adios":T("¡Adiós, señora!"),"c41_van":N("Luis y Coquí van para la casa con diez botellas.")})
DIN.update(["c41_diez_8","c41_diez_9","c41_no_ocho","c41_no_nueve"]); VARS.update({"na":["8","9"],"nb":["8","9"],"wa":["ocho","nueve"],"wb":["ocho","nueve"]})
BUB={"di_siete":"c41_cq_siete","di_ocho":"c41_cq_ocho","di_nueve":"c41_cq_nueve","di_diez":"c41_cq_diez"}   # a number bubble speaks its word: the coquí says it
def caja41(n,w,o,p,m,quien):
    # a box of ten holes holds 8 or 9 bottles, drawn on its own; the number asked for and one beside it (for nine: eight or ten, drawn); how many bottles are missing
    return [{"draw":n,"options":["8","9"]},{"calc":w,"cond":n+"=8","then":"ocho","else":"nueve"},{"draw":o,"options":["ocho","diez"]},{"calc":p,"cond":n+"=8","then":"nueve","else":"$"+o},
            {"calc":m,"cond":n+"=8","then":"2","else":"1"},act("cliente",quien=quien,lleva="caja",n="$"+n),act("cajade",quien=quien,n="$"+n)]
def ronda41(quien,n,w,p,m,l_q,dots):
    # the box he is asked about twinkles once (the key is "caja_" and the customer: the Needs name no key), then the two number bubbles
    return [{"dots":dots},tw("caja_"+quien),{"wait":700},tw(None),
     {"decide":"say","options":["di_$"+w,"di_$"+p],"baraja":True,"pick":"di_$"+w,"tests":"$"+w,"voces":BUB,"said":BUB,"lead":[],"line":l_q,
      "right":[{"if":"!ok","then":[act("sube")]}]+con(act("pasa",a=quien,n="$"+m),"c41_diez_$"+n)+[ok()],
      "wrong":[act("niega41"),act("baja",tiembla=1)]+X+["c41_no_$"+w,act("cuenta",k="botella",n="$"+n,quien="luis")]}]
s41={"id":"diez-botellas","title":"Diez botellas","place":"El colmado","scene":"estantes","next":"la-sopa-de-abuela",
 "goal":"Fill abuela's box with ten bottles, then fill the two customers' boxes to ten from the top shelf.","stake":{"thing":"maltas","steps":2},"dots":7,"bien":"si_muy_bien",
 "focus_words":["ocho","nueve","diez","otro"],"formas_foco":{"otro":["otra"]},
 "back_again":["cuatro","cinco","seis","siete","botella","caja","¿cuántas?","hay","necesito","sí","por favor","más","también","cuidado","gracias"],
 "also_heard":[],"names":nombres("luis","coqui","senor","senora"),"clips":c,
 "beats":[
  # the opening: seven bottles counted; two bottles come down, a number bubble each; the third fills the box
  {"dots":1},act("cajade",quien="abuela",n=7),act("nota41"),"c41_necesita"]+con(act("cuenta",k="botella",n=7,quien="coqui"),"c41_cuantas_caja")+[
  {"dots":2},act("sube"),act("tiembla"),"c41_cuidado"]+con(act("pasa",a="abuela",n=1),"c41_otra_botella")+[
  ask("di_ocho","c41_cuantas_ahora",then=["c41_ocho"],resp=["di_ocho","di_siete"],baraja=True,voces=BUB),
  {"dots":3},"c41_otra_q","c41_cq_si_favor",act("pasa",a="abuela",n=1),
  ask("di_nueve","c41_y_ahora",then=["c41_nueve"],resp=["di_nueve","di_ocho"],baraja=True,voces=BUB)]+con(act("pasa",a="abuela",n=1),"c41_y_otra")+["c41_diez_abuela",act("lleva",quien="abuela"),
  # the turn: the two customers come in with boxes; don Pepe goes up and cannot see into them
  {"dots":4}]+caja41("na","wa","oa","pa","ma","senora")+caja41("nb","wb","ob","pb","mb","senor")+["c41_sa_buenos_nec","c41_so_tambien",act("sube"),CARD,{"wait":400}]
  +ronda41("senora","na","wa","pa","ma","c41_q_senora",5)+ronda41("senor","nb","wb","pb","mb","c41_q_senor",6),
 "final":[{"dots":7},act("lleva",quien="senora"),act("lleva",quien="senor"),act("mira",quien="pepe",a="estante"),
  {"if":"!lost","then":[act("abre41"),"c41_para_ti","c41_cq_gracias_pepe"],"else":[{"if":"lost=1","then":["c41_no_hay"],"else":["c41_senor_nueve",act("mira",quien="senor",a="hueco")]}]},
  act("saluda",quien="senora"),"c41_sa_gracias","c41_cq_adios",act("lleva",quien="abuela"),"c41_van",act("fin")],
 "leer":["c41_necesita","c41_cuantas_caja","c41_cuidado","c41_otra_botella","c41_cuantas_ahora","c41_ocho","c41_otra_q","c41_cq_si_favor","c41_y_ahora","c41_nueve","c41_y_otra","c41_diez_abuela","c41_sa_buenos_nec","c41_so_tambien",
  "c41_q_senora","c41_cq_ocho","c41_diez_8","c41_q_senor","c41_cq_nueve","c41_diez_9","c41_para_ti","c41_cq_gracias_pepe","c41_sa_gracias","c41_cq_adios","c41_van"]}
s41=reuse(s41,{"c41_cq_si_favor":TG(("sí",["sí","si"])),"c41_cq_adios":TG(("adiós",["adiós","adios"]))})
json.dump(s41,open("cuentos/diez-botellas.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)

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
for st in (s39,s40,s41):
    mine=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(mine),"new,",sum(len(st["clips"][i]["text"]) for i in mine),"characters")
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:39|40|41)_|si_|p_n_|b_n_|yo_|c_n_)[a-z_0-9$]+)"',txt))):
        if "$" in i:   # a built id: every value it can take must be a clip
            m=re.search(r"\$([a-z]+)",i)
            for v in VARS.get(m.group(1),[]):
                if i.replace("$"+m.group(1),v) not in st["clips"]: print("MISSING BUILT CLIP",st["id"],i,v)
        elif i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for k,v in st["names"].items():
        if v not in st["clips"]: print("MISSING NAME",st["id"],k,v)
