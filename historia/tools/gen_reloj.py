# El reloj (place 6, La plaza, scene 2): stories 63, 64, 65. Regenerates the JSON; never edit the JSON by hand.
# Script: historia/notas/guiones/reloj.md (draft 2, with its Needs list as it stands now). Every quoted line of the script is exactly one clip, word for word.
# The scene `reloj` is not built yet: acts, things, spots and speaker keys are the ones of the script's Needs list, nothing else (plus the acts every scene has: marca, ya, fin, ir; gesto; and the engine's own twinkle `tw`).
# Run order for the place: gen_mostrador, gen_estantes, gen_frutas, gen_caja, gen_esquina, gen_parada, gen_tiendas, gen_cruce, then this one (it sees only what was recorded before it: places 1 to 5).
#
# Where the script leaves a value open, this file fixes it in ONE place (and the report says so):
#   PIE: the frog's own spot at the tower's foot is pie1 (the script names pie1 to pie4 and no owner).
#   Time cards: in the opening (63: 2 to 4) the cards are listed "right one first" in the script, so the right card is carta_a there; in the game the side is drawn (`ka`).
#   Numbers in act arguments: hours and counts that the script gives as numbers are numbers in the opening and strings ("$ha") where a draw fills them.
#   `corta` {h, media}: the short hand follows every reading the script speaks (64: 1, 2, 3 and the game), media=1 for "y media" and 0 for "en punto".
#   `figuras64`, `final63`, `final65` {n}: n = what is left (figures, golden pastelillos, prizes) = 3 minus the steps lost.
#   `pastelillos` {n}: the raw pastelillos left on the counter: 3 at the start, 2 after the first is dropped into the oil, 1 after the second.
#   `premios` {n}: the prizes left on the shelf: 3 at the start, then after each wrong move (a rival takes the best one) 2, then 1.
#   65 `orden`: the order of 60, 80 and 100 is drawn as na (round A), nb (round B), nc (the ending).
import json,glob,os,re,collections
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),".."))
N=lambda t:{"who":"narr","text":t}
T=lambda t:{"who":"tu","text":t}
def D(quien,pre,t): return {"who":"narr","habla":quien,"text":pre+" dice: "+t}
AB=lambda t:D("abuela","Abuela",t); L=lambda t:D("luis","Luis",t); CA=lambda t:D("carmen","Carmen",t)
SA=lambda t:D("senora","La señora",t); SE=lambda t:D("senor","El señor",t); TI=lambda t:D("tito","Don Tito",t); VE=lambda t:D("vendedor","El vendedor",t)
tw=lambda k:{"set":{"twinkle":k}}                                              # the engine's own twinkle on a thing he can touch (the script's `brilla`)
def act(_n,**k): return dict({"act":_n},**k)
def gesto(quien,que,**k): return act("gesto",quien=quien,que=que,**k)
def con(a,*lines): return [dict(a,suelto=1)]+list(lines)+[act("ya")]          # an act that runs in time with a spoken line: started loose, the line, then `ya`
def ask(k,line,then=None,after=None,**kw): return dict({"ask":k,"lead":[],"line":line,"then":then or [],"after":after or []},**kw)
X=[act("marca",que="x"),{"cost":1}]                      # the card's cross, then one step of the stake
OK=act("marca",que="ok")                                  # the card's star
star={"if":"ok","then":[OK]}                              # the star only when the first touch was right
CARD={"set":{"tarjeta":"rondas","marcas":[None,None]}}   # every story has two scored rounds: the card shows two places
PIE="pie1"
HR={1:"una",2:"dos",3:"tres",4:"cuatro",5:"cinco",6:"seis",7:"siete",8:"ocho",9:"nueve",10:"diez",11:"once",12:"doce"}
DEC={10:"diez",20:"veinte",30:"treinta",40:"cuarenta",50:"cincuenta",60:"sesenta",70:"setenta",80:"ochenta",90:"noventa",100:"cien"}
MINE=("que-hora-es","y-media","bingo")   # this generator's stories: not seen
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
DIN=set()   # ids that are put together in the story ("c63_tito_son_$ha"): never renamed
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
# What he hears when he pokes a person already recorded (the new ones, don Tito and the vendedor, add nothing)
NM={"abuela":("abuela",N("Esta es abuela.")),"luis":("p_n_luis",N("Este es Luis.")),"carmen":("p_n_carmen",N("Esta es Carmen.")),"coqui":("yo_coqui",T("¡Coquí!")),
    "senor":("b_n_senor",N("Es un señor.")),"senora":("b_n_senora",N("Es una señora."))}
def nombres(*ks):
    return {k:NM[k][0] for k in ks},{NM[k][0]:NM[k][1] for k in ks}
def sw(var,cases):
    # a chain of `if` on one variable: cases is [(value, steps), ...]; the last case is the `else` (the drawn values are all listed)
    out=cases[-1][1]
    for v,st in reversed(cases[:-1]): out=[{"if":"%s=%s"%(var,v),"then":st,"else":out}]
    return out
dr=lambda v,xs,**k:dict({"draw":v,"options":[str(x) for x in xs]},**k)
UNO_DOCE=[HR[i] if i>1 else "uno" for i in range(1,13)]
DOS_DOCE=UNO_DOCE[1:]

# ---------------- 63. ¿Qué hora es? ----------------
# Two time cards (the hour said and another, drawn; never dos with doce, seis with siete, once with doce; the other is as often the earlier hour as the later one: a coin first, then the hour; where one side is empty, the other).
# Round A says an hour from 4 to 8; round B a later one (to 12). Which card is at the left is drawn (ka). A miss: the frog sets the other hour, the pastelillo burns.
c=dict(comunes); nm,nc=nombres("luis","carmen","coqui"); c.update(nc)
c.update({"c63_mira":N("Mira el reloj de la plaza. Es un reloj grande y viejo. Y no camina."),"c63_donde_reloj":N("¿Dónde está el reloj?"),
 "c63_tito_hola":TI("¡Hola! ¿Cómo te llamas?"),"c63_cq_me_llamo":T("Me llamo Coquí."),"c63_tito_mucho_gusto":TI("Mucho gusto, Coquí. Yo soy Tito."),
 "c63_luis_hora":L("Don Tito, ¿qué hora es?"),"c63_tito_es_una":TI("Es la una."),"c63_en_cual_una":N("¿En cuál reloj es la una?"),"c63_ve_es_una":VE("¡Es la una!"),
 "c63_carmen_ahora":CA("Don Tito, ¿y ahora qué hora es?"),"c63_tito_son_dos":TI("Son las dos."),"c63_en_cual_dos":N("¿En cuál reloj son las dos?"),
 "c63_ve_son_tres":VE("¿Qué hora es? ¿Son las tres?"),"c63_tito_ya_tres":TI("Sí, ya son las tres."),"c63_en_cual_tres":N("¿Y en cuál reloj son las tres?"),
 "c63_ve_pastelillos":VE("Con el reloj, los pastelillos salen bien."),"c63_ve_hora":VE("Don Tito, ¿qué hora es?"),
 "c63_tito_ya":TI("¡Ya! El reloj camina."),"c63_ve_quieres":VE("¿Quieres un pastelillo, Coquí?"),"c63_cq_si":T("¡Sí, gracias!"),"c63_camina":N("El reloj de la plaza camina otra vez.")})
for h in range(4,9): c["c63_tito_son_%d"%h]=TI("Son las %s."%HR[h]); DIN.add("c63_tito_son_%d"%h)
for h in range(5,13): c["c63_tito_ahora_%d"%h]=TI("Ahora son las %s."%HR[h]); DIN.add("c63_tito_ahora_%d"%h)
for h in range(4,13): c["c63_tito_no_%d"%h]=TI("No, Coquí. Son las %s."%HR[h]); DIN.add("c63_tito_no_%d"%h)
PARES63={2:(12,),12:(2,11),6:(7,),7:(6,),11:(12,)}   # the pairs never set against each other
def otras63(h):
    ok=[x for x in range(1,13) if x!=h and x not in PARES63.get(h,())]
    return [x for x in ok if x<h],[x for x in ok if x>h]
def otra63(h,d,o,hs):
    # the other card's hour: a coin (e: earlier, l: later), then an hour of that side; with no hour on that side, the other side
    cases=[]
    for x in hs:
        e,l=otras63(x)
        cases.append((x,[{"if":"%s=e"%d,"then":[dr(o,e or l)],"else":[dr(o,l or e)]}]))
    return sw(h,cases)
def ronda63(s,hs,extra,linea,quedan):
    # one round: the vendedor drops a pastelillo into the oil, two cards appear (the hour said and another), don Tito reads the hour; he touches a card
    h,d,o,k,j,u,v="h"+s,"d"+s,"o"+s,"k"+s,"j"+s,"u"+s,"v"+s
    return [{"draw":d,"options":["e","l"]}]+otra63(h,d,o,hs)+[
     {"draw":k,"options":["carta_a","carta_b"],"other":j},
     {"calc":u,"cond":"%s=carta_a"%k,"then":"$"+h,"else":"$"+o},{"calc":v,"cond":"%s=carta_a"%k,"then":"$"+o,"else":"$"+h},
     {"decide":"do","options":["carta_a","carta_b"],"pick":"$"+k,"tests":"$"+h,"lock":True,"lead":[act("echa63"),act("pastelillos",n=quedan),act("cartas",a="$"+u,b="$"+v)]+extra,"line":linea,
      "right":[act("pone63",h="$"+h),act("campana",n="$"+h),{"if":"ok","then":[act("frie63",ok=1),OK]}],
      "wrong":[act("pone63",h="$"+o),act("campana",n="$"+o)]+con(act("frie63",ok=0),"c63_tito_no_$"+h)+X}]
s63={"id":"que-hora-es","title":"¿Qué hora es?","place":"La plaza","scene":"reloj","next":"y-media",
 "goal":"Set the stopped clock tower's clock to the hour don Tito reads from his watch, so the vendedor can fry the three pastelillos by the bell: every wrong hour leaves one in the oil until it burns black.",
 "stake":{"thing":"pastelillos","steps":3},"dots":9,"bien":"si_muy_bien",
 "focus_words":["reloj","hora","¿qué hora es?","es la una","son las"],"formas_foco":{},
 "back_again":UNO_DOCE+["me llamo","mucho gusto","¿cómo te llamas?","camina","grande","viejo","come","sí","gracias","mira","ahora","ya","otra vez","quieres"],
 "also_heard":["pastelillos","salen"],"names":nm,"palabras":{str(h):HR[h] for h in range(4,13)},"clips":c,
 "beats":[{"set":{"hora":"mediodia"}},act("ir",a=PIE),act("pastelillos",n=3),{"wait":500},
  # 1: the clock that does not walk (signed ask on the face); don Tito looks down; the first turn (me llamo)
  "c63_mira",ask("reloj","c63_donde_reloj",then=[gesto("tito","mira",a="coqui")]),"c63_tito_hola","c63_cq_me_llamo","c63_tito_mucho_gusto",
  # 2: es la una (signed ask on the one o'clock card)
  {"dots":1},"c63_luis_hora","c63_tito_es_una",act("cartas",a=1,b=4),
  ask("carta_a","c63_en_cual_una",after=[act("pone63",h=1),act("campana",n=1)],then=["c63_ve_es_una"]),
  # 3: son las dos (signed ask on the two o'clock card); the frog comes down first
  {"dots":2},act("ir",a=PIE),"c63_carmen_ahora","c63_tito_son_dos",act("cartas",a=2,b=1),
  ask("carta_a","c63_en_cual_dos",after=[act("pone63",h=2),act("campana",n=2)]),
  # 4: son las tres (signed ask on the three o'clock card); the vendedor counts the rings
  {"dots":3},"c63_ve_son_tres","c63_tito_ya_tres",act("cartas",a=3,b=9),
  ask("carta_a","c63_en_cual_tres",after=[act("pone63",h=3),act("campana",n=3),gesto("vendedor","dedos")]),
  # 5: the turn: the plate of raw pastelillos; don Tito hands over the oil can and sits down; the card shows two places
  {"dots":4},gesto("vendedor","senala",a="pastelillos"),gesto("vendedor","senala",a="reloj"),"c63_ve_pastelillos",gesto("tito","sienta"),CARD,{"wait":400},
  # A: an hour from 4 to 8 (drawn); the vendedor asks don Tito
  {"dots":5},dr("ha",range(4,9))]+ronda63("a",range(4,9),["c63_ve_hora"],"c63_tito_son_$ha",2)
  # B: a later hour (drawn from the hours after A's, to 12)
  +[{"dots":6}]+sw("ha",[(a,[dr("hb",range(a+1,13))]) for a in range(4,9)])+ronda63("b",range(5,13),[],"c63_tito_ahora_$hb",1),
 "final":[{"dots":7},gesto("tito","llave"),"c63_tito_ya",   # 8: don Tito winds the clock; the plate, by the pastelillos that came out golden
  {"if":"lost=0","then":[act("final63",n=3)],"else":[{"if":"lost=1","then":[act("final63",n=2)],"else":[act("final63",n=1)]}]},
  {"dots":8},"c63_ve_quieres","c63_cq_si",{"dots":9},"c63_camina",act("fin")],
 "leer":["c63_mira","c63_donde_reloj","c63_tito_hola","c63_cq_me_llamo","c63_tito_mucho_gusto","c63_luis_hora","c63_tito_es_una","c63_en_cual_una","c63_ve_es_una","c63_carmen_ahora","c63_tito_son_dos","c63_en_cual_dos","c63_ve_son_tres","c63_tito_ya_tres","c63_en_cual_tres",
  "c63_ve_pastelillos","c63_ve_hora","c63_tito_son_5","c63_tito_ahora_8","c63_tito_ya","c63_ve_quieres","c63_cq_si","c63_camina"]}
s63=reuse(s63,{"c63_cq_me_llamo":TG(("me llamo",["me llamo"])),"c63_cq_si":TG(("sí",["sí","si","sí gracias","si gracias"]))})
json.dump(s63,open("cuentos/que-hora-es.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 64. Y media ----------------
# The long hand goes to the top (en punto) or the bottom (y media); the words said are drawn each round on its own, and so is the hour: round A from 4 to 10, round B a later one (to 11).
# A miss: the long hand swings the other way, the works grind, a spring jumps out and a shutter of the little door sticks.
c=dict(comunes); nm,nc=nombres("luis","carmen","coqui"); c.update(nc)
c.update({"c64_tito_hola":TI("¡Hola, Coquí! ¿Cómo estás?"),"c64_cq_bien":T("¡Bien, gracias!"),"c64_tito_mira":TI("Mira. Son las dos en punto."),"c64_arriba_abajo":N("¿Arriba o abajo?"),
 "c64_tito_media_dos":TI("Un minuto, dos minutos... ¡treinta minutos! Ahora son las dos y media."),"c64_y_ahora":N("¿Y ahora? ¿Arriba o abajo?"),
 "c64_tito_tres_punto":TI("Treinta minutos más... Son las tres en punto."),"c64_luis_tres":L("¿Las tres en punto?"),"c64_tito_si_luis":TI("Sí, Luis. En punto."),
 "c64_tito_tres_media":TI("Y en treinta minutos, las tres y media."),"c64_carmen_tres_media":CA("¡Las tres y media! ¡Luis, vamos!"),"c64_tito_espera":TI("Espera, Coquí. Ahora, con cuidado."),
 "c64_tito_mira_coqui":TI("Mira, Coquí: un coquí pequeño."),"c64_cq_me_gusta":T("¡Me gusta!"),"c64_tito_media_hora":TI("En media hora salen otra vez.")})
for h in range(4,12):
    for d,w in (("punto","en punto"),("media","y media")):
        c["c64_tito_%d_%s"%(h,d)]=TI("Son las %s %s."%(HR[h],w)); c["c64_no_%d_%s"%(h,d)]=TI("No, Coquí. Son las %s %s."%(HR[h],w))
        DIN.update(["c64_tito_%d_%s"%(h,d),"c64_no_%d_%s"%(h,d)])
def ronda64(s,linea,no):
    # one round: don Tito reads the hour and the words (drawn); the frog pushes the long hand to the top (punto) or the bottom (media)
    h,d,o,p,m="h"+s,"d"+s,"o"+s,"p"+s,"m"+s
    return [{"draw":d,"options":["punto","media"],"other":o},{"calc":p,"cond":"%s=punto"%d,"then":"arriba","else":"abajo"},{"calc":m,"cond":"%s=media"%d,"then":"1","else":"0"},
     {"decide":"do","options":["arriba","abajo"],"pick":"$"+p,"tests":"$"+d,"lock":True,"lead":[],"line":linea,
      "right":[act("larga",a="$"+d),act("corta",h="$"+h,media="$"+m),star],
      "wrong":[act("larga",a="$"+o),act("resorte64")]+X+[no]}]
s64={"id":"y-media","title":"Y media","place":"La plaza","scene":"reloj","next":"bingo",
 "goal":"Push the clock's long hand to the top or the bottom as don Tito says (on the hour or half past), so the three painted figures can come out of the little door: every wrong push jams one shutter.",
 "stake":{"thing":"figuras","steps":3},"dots":8,"bien":"si_muy_bien",
 "focus_words":["y media","en punto","minuto","treinta"],"formas_foco":{"minuto":["minutos"]},
 "back_again":["reloj","hora","¿qué hora es?","son las"]+DOS_DOCE+["¿cómo estás?","bien","espera","arriba","abajo","cuidado","me gusta","mira","ahora","pequeño","vamos","medio"],
 "also_heard":["media hora"],"names":nm,"palabras":{"punto":"en punto","media":"y media"},"clips":c,
 "beats":[{"set":{"hora":"tarde"}},act("ir",a=PIE),act("corta",h=1,media=1),{"wait":500},
  # 1: the frog climbs onto the long hand; the 12 and the 6 twinkle (signed ask on the top of the face); the first turn (bien)
  "c64_tito_hola","c64_cq_bien",act("ir",a="escalera"),act("ir",a="manecilla"),"c64_tito_mira",tw("arriba"),{"wait":600},tw("abajo"),{"wait":600},tw(None),
  ask("arriba","c64_arriba_abajo",after=[act("larga",a="punto"),act("corta",h=2,media=0),act("campana",n=1)]),
  # 2: treinta minutos: the hand goes down (signed ask on the bottom of the face)
  {"dots":1},"c64_tito_media_dos",ask("abajo","c64_y_ahora",after=[act("larga",a="media"),act("corta",h=2,media=1)]),
  # 3: the wheel again: en punto, y media; Luis and Carmen leave
  {"dots":2},act("larga",a="punto"),act("corta",h=3,media=0),"c64_tito_tres_punto","c64_luis_tres","c64_tito_si_luis",act("larga",a="media"),act("corta",h=3,media=1),"c64_tito_tres_media","c64_carmen_tres_media",
  # 4: the turn: the flap, the big spring; the long hand slips to the side (the 9); the card shows two places
  {"dots":3},gesto("tito","senala",a="puertita"),act("larga",a="lado"),"c64_tito_espera",CARD,{"wait":400},
  # A: an hour from 4 to 10 and the words (drawn)
  {"dots":4},dr("ha",range(4,11))]+ronda64("a","c64_tito_$ha_$da","c64_no_$ha_$da")
  # B: don Tito turns the wheel and the hand goes back to the 9; a later hour (drawn from the hours after A's, to 11) and the words (drawn on their own)
  +[{"dots":5},act("larga",a="lado")]+sw("ha",[(a,[dr("hb",range(a+1,12))]) for a in range(4,11)])+ronda64("b","c64_tito_$hb_$db","c64_no_$hb_$db"),
 "final":[{"dots":6},gesto("tito","llave"),   # 7: the flap shut, the key; the little door, by the shutters that stuck
  {"if":"lost=0","then":[act("figuras64",n=3)],"else":[{"if":"lost=1","then":[act("figuras64",n=2)],"else":[act("figuras64",n=1)]}]},
  {"dots":7},"c64_tito_mira_coqui","c64_cq_me_gusta",{"dots":8},"c64_tito_media_hora",act("fin")],
 "leer":["c64_tito_hola","c64_cq_bien","c64_tito_mira","c64_arriba_abajo","c64_tito_media_dos","c64_y_ahora","c64_tito_tres_punto","c64_luis_tres","c64_tito_si_luis","c64_tito_tres_media","c64_carmen_tres_media","c64_tito_espera",
  "c64_tito_5_media","c64_tito_7_punto","c64_tito_mira_coqui","c64_cq_me_gusta","c64_tito_media_hora"]}
s64=reuse(s64,{"c64_cq_bien":TG(("bien",["bien","bien gracias"])),"c64_cq_me_gusta":TG(("me gusta",["me gusta"]))})
json.dump(s64,open("cuentos/y-media.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


# ---------------- 65. ¡Bingo! ----------------
# Abuela's card: 40, 60, 80, 90, 100. The señora calls 60, 80 and 100 in a drawn order (na in round A, nb in round B, nc in the ending); no ball is held up and no digit is spelled in the scored calls.
# A miss: the wrong bean is moved, another ball drops and another player (the señor, or don Tito if the señor already won) takes the best prize left.
c=dict(comunes); nm,nc=nombres("abuela","luis","senor","senora","coqui"); c.update(nc)
c.update({"c65_bingo":N("En la plaza hay bingo."),"c65_ab_tengo":AB("Tengo el cuarenta, el sesenta, el ochenta, el noventa y el cien."),"c65_luis_tengo":L("Yo tengo el treinta, el cincuenta y el setenta."),
 "c65_sra_cuenta":SA("Diez, veinte, treinta, cuarenta, cincuenta, sesenta, setenta, ochenta, noventa... ¡y cien! ¿Empezamos?"),"c65_cq_listos":T("¡Listos!"),
 "c65_sra_90":SA("¡Noventa! Nueve, cero. ¡El noventa!"),"c65_donde_hab":N("¿Dónde ponemos la habichuela?"),
 "c65_sra_50":SA("¡Cincuenta! Cinco, cero."),"c65_ab_no_50":AB("No tengo el cincuenta."),"c65_sra_40":SA("¡Cuarenta! Cuatro, cero. ¡El cuarenta!"),"c65_y_ahora":N("¿Y ahora? ¿Dónde está el cuarenta?"),
 "c65_sra_70":SA("¡Setenta! Siete, cero."),"c65_luis_70":L("¡Tengo el setenta!"),"c65_ab_quiero":AB("Ahora quiero el sesenta, el ochenta y el cien."),"c65_ab_tu":AB("Coquí, ahora tú. ¡Yo no miro!"),
 "c65_sra_30":SA("¡Treinta!"),"c65_senor_bingo":SE("¡Bingo!"),"c65_sra_20":SA("¡Veinte!"),"c65_tito_bingo":TI("¡Bingo!"),"c65_ab_bingo":AB("¡Bingo!"),
 "c65_ab_toma":AB("Toma, Coquí."),"c65_cq_gracias":T("¡Gracias, abuela!"),"c65_sra_otro":SA("¡Otro bingo en diez minutos!")})
for n in (60,80,100):
    c["c65_sra_%d"%n]=SA("¡%s! ¡El %s!"%(DEC[n].capitalize(),DEC[n])); c["c65_ab_no_%d"%n]=AB("No, Coquí. ¡El %s!"%DEC[n]); DIN.update(["c65_sra_%d"%n,"c65_ab_no_%d"%n])
def ronda65(s,opts,pick,linea,no,rival):
    # one round: the señora calls a number (the ball is not held up); he touches a square of abuela's card. rival: the steps of a wrong move's other player
    n,x="n"+s,"xn"
    return [{"decide":"do","options":opts,"pick":pick,"tests":"$"+n,"lock":True,"lead":[act("bola65",n="$"+n,muestra=0)],"line":linea,
      "right":[act("frijol",carton="abuela",n="$"+n),{"if":"ok","then":[gesto("abuela","ojos"),gesto("abuela","si"),OK]}],
      "wrong":[{"calc":x,"cond":"x=n60","then":"60","else":"100"},{"calc":x,"cond":"x=n80","then":"80","else":"$"+x},act("frijol",carton="abuela",n="$"+x),no]+rival+
              [{"if":"lost=0","then":[act("premios",n=2)],"else":[act("premios",n=1)]}]+X}]
quita=lambda *lines:con(act("quita65"),*lines)
A_RIVAL=quita(act("bola65",n=30,muestra=0),"c65_sra_30")+con(act("rival65",quien="senor"),"c65_senor_bingo")
B_RIVAL=[{"if":"lost=0","then":A_RIVAL,"else":quita(act("bola65",n=20,muestra=0),"c65_sra_20")+con(act("rival65",quien="tito"),"c65_tito_bingo")}]   # the señor if round A cost nothing, don Tito if it did
s65={"id":"bingo","title":"¡Bingo!","place":"La plaza","scene":"reloj","next":"un-cafe-para-la-maestra",
 "goal":"Lay abuela's beans on the numbers the señora calls so she can win the bingo and take the biggest prize: every wrong bean lets another player win and take the best prize left.",
 "stake":{"thing":"premios","steps":3},"dots":10,"bien":"si_muy_bien",
 "focus_words":["cuarenta","cincuenta","sesenta","setenta","ochenta","noventa","cien"],"formas_foco":{},
 "back_again":["diez","veinte","treinta","habichuelas","tengo","no tengo","quiero","también","abuela","señor","señora","listo","toma","gracias","ahora","tú","mira","otro","minuto"],
 "also_heard":["bingo","empezamos"],"names":nm,"palabras":{"60":"sesenta","80":"ochenta","100":"cien"},"clips":c,
 "beats":[{"set":{"hora":"ocaso","mesas":1}},act("ir",a="mesa_abuela"),act("premios",n=3),{"wait":500},
  # 1: the bingo; abuela's card and Luis's
  "c65_bingo",gesto("abuela","senala",a="n40"),"c65_ab_tengo",gesto("luis","senala"),"c65_luis_tengo",
  # 2: the señora holds the balls up in a row and counts them out; the first turn (listo)
  {"dots":1}]+[act("bola65",n=n,muestra=1) for n in range(10,101,10)]+["c65_sra_cuenta","c65_cq_listos",
  # 3: the 90 (signed ask on abuela's 90)
  {"dots":2},act("bola65",n=90,muestra=1),"c65_sra_90",ask("n90","c65_donde_hab",after=[act("frijol",carton="abuela",n=90)]),
  # 4: the 50 is not abuela's; the 40 is (signed ask on abuela's 40)
  {"dots":3},act("bola65",n=50,muestra=1),"c65_sra_50",gesto("abuela","no"),"c65_ab_no_50",act("frijol",carton="luis",n=50),
  act("bola65",n=40,muestra=1),"c65_sra_40",ask("n40","c65_y_ahora",after=[act("frijol",carton="abuela",n=40)]),
  # 5: the 70 is Luis's; the señor and don Tito are one square short
  {"dots":4},act("bola65",n=70,muestra=1),"c65_sra_70","c65_luis_70",act("frijol",carton="luis",n=70),act("frijol",carton="senor"),act("frijol",carton="tito"),
  # 6: the turn: the señor holds up one finger; abuela covers her eyes; the card shows two places
  {"dots":5},gesto("senor","uno"),gesto("abuela","mira",a="n60"),"c65_ab_quiero",gesto("abuela","ojos"),"c65_ab_tu",CARD,{"wait":400},
  # the order of 60, 80 and 100 (drawn): na in round A, nb in round B, nc in the ending
  dr("na",[60,80,100])]
  +sw("na",[(60,[dr("nb",[80,100],other="nc")]),(80,[dr("nb",[60,100],other="nc")]),(100,[dr("nb",[60,80],other="nc")])])
  # A: three squares empty
  +[{"dots":6}]+ronda65("a",["n60","n80","n100"],"n$na","c65_sra_$na","c65_ab_no_$na",A_RIVAL)
  # B: two squares empty (the two numbers left)
  +[{"dots":7}]+ronda65("b",["n$nb","n$nc"],"n$nb","c65_sra_$nb","c65_ab_no_$nb",B_RIVAL),
 "final":[{"dots":8},act("bola65",n="$nc",muestra=0),"c65_sra_$nc",act("frijol",carton="abuela",n="$nc"),"c65_ab_bingo",   # 9: the last number; abuela wins; the prize, by what is left on the shelf
  {"if":"lost=0","then":[act("final65",n=3)],"else":[{"if":"lost=1","then":[act("final65",n=2)],"else":[act("final65",n=1)]}]},
  {"dots":9},"c65_ab_toma","c65_cq_gracias",{"dots":10},"c65_sra_otro",act("fin")],
 "leer":["c65_bingo","c65_ab_tengo","c65_luis_tengo","c65_sra_cuenta","c65_cq_listos","c65_sra_90","c65_donde_hab","c65_sra_50","c65_ab_no_50","c65_sra_40","c65_y_ahora","c65_sra_70","c65_luis_70","c65_ab_quiero","c65_ab_tu",
  "c65_sra_100","c65_sra_60","c65_sra_80","c65_ab_bingo","c65_ab_toma","c65_cq_gracias","c65_sra_otro"]}
s65=reuse(s65,{"c65_cq_listos":TG(("listo",["listo","listos"])),"c65_cq_gracias":TG(("gracias",["gracias","gracias abuela"]))})
json.dump(s65,open("cuentos/bingo.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)


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
# every id the steps name (with no variable in it) is in the story's clips; every `leer` id too; every speaking turn is on a word of an earlier story (the files on disk: places 1 to 5)
earlier=set()
for f in glob.glob("cuentos/*.json"):
    if os.path.basename(f)[:-5] in MINE: continue
    earlier.update(json.load(open(f,encoding="utf-8")).get("focus_words") or [])
for st in (s63,s64,s65):
    txt=json.dumps({"b":st["beats"],"f":st["final"]},ensure_ascii=False)
    for i in sorted(set(re.findall(r'"((?:c(?:63|64|65)_|si_|yo_|p_n_|b_n_|n_|esta_|cq_|bien_|abuela)[a-z_0-9$]*)"',txt))):
        if "$" not in i and i not in st["clips"]: print("MISSING CLIP",st["id"],i)
    for i in st["leer"]:
        if i not in st["clips"]: print("MISSING LEER",st["id"],i)
    for cid,cl in st["clips"].items():
        for t in cl.get("tu_turno") or []:
            if t["palabra"] not in earlier: print("TURN ON A WORD IN NO EARLIER FOCUS LIST:",st["id"],cid,t["palabra"])
    nw=[cid for cid in st["clips"] if not os.path.exists(f"audio/{cid}.mp3")]
    print(" ",st["id"],":",len(st["clips"]),"clips,",len(nw),"new,",sum(len(st["clips"][i]["text"]) for i in nw),"characters,",sum(1 for cl in st["clips"].values() if cl.get("tu_turno")),"speaking turns")
