"""Checks the speaking-turns engine (docs/hablar/01-decisiones.md) by machine.

  python3 historia/tools/habla_motor_check.py <outdir> [port]      (outdir must exist; port default 8770; needs playwright and /usr/bin/google-chrome)

It builds a scratch site in a temp folder: symlinks to everything in historia/, and in its cuentos/ two scratch stories made from el-bizcocho
(zprueba-habla: "tu_turno" on one plain coqui line, one signed ask and one elige; zprueba-habla5: two more marks, for the cap of 4 turns). Nothing is written
into historia/cuentos/. It serves that site itself, drives the lesson page with the test switches (?mic=stub:..., ?mic=off, ?abiertas=todas) and, for the real
recogniser code path, with a fake SpeechRecognition, and prints one line per check and "FAILED: n" at the end (exit 1 when n > 0).
Not part of this check (order 5): the 31 real stories, which are marked later."""
import asyncio,json,os,sys,tempfile,threading,time,functools
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from playwright.async_api import async_playwright
OUT=sys.argv[1]; PORT=int(sys.argv[2]) if len(sys.argv)>2 else 8770
HERE=os.path.dirname(os.path.abspath(__file__)); HIST=os.path.abspath(os.path.join(HERE,".."))
SITE=tempfile.mkdtemp(prefix="habla_site_"); os.makedirs(SITE+"/historia/cuentos")
for n in os.listdir(HIST):
    if n!="cuentos": os.symlink(os.path.join(HIST,n),os.path.join(SITE,"historia",n))
for n in os.listdir(HIST+"/cuentos"):
    if n.endswith(".json"): os.symlink(os.path.join(HIST,"cuentos",n),os.path.join(SITE,"historia","cuentos",n))
def T(w,*f): return [{"palabra":w,"formas":list(f)}]
j=json.load(open(HIST+"/cuentos/el-bizcocho.json",encoding="utf-8")); j["id"]="zprueba-habla"; j["title"]="Prueba"; j["next"]=None
c=j["clips"]; c["cq_si"]["tu_turno"]=T("sí","si"); c["cq_no"]["tu_turno"]=T("no","no"); c["cq_si_gracias"]["tu_turno"]=T("sí","si"); c["cq_no_gracias"]["tu_turno"]=T("no","no")
json.dump(j,open(SITE+"/historia/cuentos/zprueba-habla.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
k=json.loads(json.dumps(j)); k["id"]="zprueba-habla5"; k["clips"]["cq_ay"]["tu_turno"]=T("ay","ay"); k["clips"]["no_pajaro"]["tu_turno"]=T("pájaro","pajaro")
json.dump(k,open(SITE+"/historia/cuentos/zprueba-habla5.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
class H(SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
    def end_headers(self): self.send_header("Cache-Control","no-store"); super().end_headers()
srv=ThreadingHTTPServer(("127.0.0.1",PORT),functools.partial(H,directory=SITE)); threading.Thread(target=srv.serve_forever,daemon=True).start()
BASE=f"http://127.0.0.1:{PORT}/historia/"
FAILS=[]
def ck(name,ok,detail=""):
    print(("ok   " if ok else "FAIL ")+name+(" | "+str(detail) if detail!="" else ""),flush=True)
    if not ok: FAILS.append(name)

STATE="""()=>{const p=Story.pending,H=Story.hab,W=Story.W;return {live:p?p.live.join('|'):null,kind:p?p.kind:null,pick:p?p.pick:null,asked:p?p.asked:0,sign:p?p.sign:null,spot:W.spot||null,respOn:W.respOn||null,
 est:H.est,bub:H.bub,at:H.at,mic:H.mic,n:H.n,log:H.log,running:Story.running,speaking:Story.speaking,lost:W.lost,disp:H.disp}}"""
SPY="""()=>{window.__resp=[];const r=PAL.responde;PAL.responde=function(...a){window.__resp.push(a);return r.apply(this,a);};window.__right=0;const o=SFX.right;SFX.right=function(){window.__right++;return o.apply(this,arguments);};
 window.__c=[];const _p=playClip;playClip=function(id){window.__c.push(id);return _p(id);};}"""
FAKE="""(()=>{window.__fakeQ=[];window.__fakeProps=[];window.__fakeCalls={start:0,stop:0,abort:0,t:{}};window.__resume=0;
 try{const r=AudioContext.prototype.resume;AudioContext.prototype.resume=function(){window.__resume++;return r.apply(this,arguments);};}catch(e){}
 class FakeSR{constructor(){this.lang="";this.interimResults=null;this.maxAlternatives=null;this.continuous=null;}
  start(){__fakeCalls.start++;__fakeCalls.t.start=performance.now();__fakeProps.push({lang:this.lang,interim:this.interimResults,max:this.maxAlternatives,cont:this.continuous,speaking:(window.Story?Story.speaking:-1)});
   const q=__fakeQ.shift()||{err:"no-speech"};this._q=q;const on=(n,d)=>{if(this["on"+n])this["on"+n](d||{});};
   if(q.hang)return;
   if(q.err){setTimeout(()=>{on("error",{error:q.err});on("end");},q.t||200);return;}
   const t0=q.onset||250;setTimeout(()=>on("speechstart"),t0);setTimeout(()=>{on("speechend");on("audioend");},t0+200);
   setTimeout(()=>{const alt=q.alts.map(t=>({transcript:t,confidence:.8}));on("result",{results:[alt],resultIndex:0});on("end");},t0+400);}
  stop(){__fakeCalls.stop++;__fakeCalls.t.stop=performance.now();if(this._q&&this._q.hang&&!this._q.noend)setTimeout(()=>{if(this.onend)this.onend({});},100);}
  abort(){__fakeCalls.abort++;__fakeCalls.t.abort=performance.now();}}
 window.webkitSpeechRecognition=FakeSR;window.SpeechRecognition=FakeSR;})();"""
def seed_js(words):
    now=int(time.time()*1000)
    sk=lambda e,n=0:{"etapa":e,"paso":1,"seguidas":0,"fallos":0,"gap":0,"due":now+864000000,"aciertos":[],"ultima":0,"aparcada":0,"marca":0,"n":n,"bien":0}
    db={"palabras":{w:{"w":w,"primera":now,"oida":1,"ear":sk(e),"mouth":sk(0,m)} for w,(e,m) in words.items()},"dias":{},"cuentos":{},"ajustes":{"min":30,"todo":0,"bienvenida":1,"habla":1},"minutos":0,"v":1}
    return "try{if(!localStorage.getItem('coqui.palabras.v1'))localStorage.setItem('coqui.palabras.v1',%s)}catch(e){}"%json.dumps(json.dumps(db))
SWOFF="try{localStorage.setItem('coqui.palabras.v1',JSON.stringify({palabras:{},dias:{},cuentos:{},ajustes:{min:30,todo:0,bienvenida:1,habla:0},minutos:0,v:1}))}catch(e){}"
SEM=asyncio.Semaphore(6)
async def newpage(br,vp,init):
    ctx=await br.new_context(viewport={"width":vp[0],"height":vp[1]},device_scale_factor=2,is_mobile=True,has_touch=True)
    for s in init: await ctx.add_init_script(s)
    pg=await ctx.new_page(); errs=[]
    pg.on("pageerror",lambda e: errs.append("pageerror:"+str(e))); pg.on("console",lambda m: errs.append("console:"+m.text) if m.type=="error" else None)
    return ctx,pg,errs
async def play(br,query,story="zprueba-habla",vp=(390,844),mic="tap",touch_elige=False,init=(),fake=None,budget=170,on_poll=None,fast=6):
    """Plays one story by machine and returns what happened. mic='tap': tap the mic when it is ready; 'never': never tap it. Touches: the right answer of a decide, the first live thing of an ask,
    the first option of an elige (not while a speaking turn is in progress, unless touch_elige). fake: a list of results for the fake recogniser (used with no ?mic at all)."""
    async with SEM:
        ctx,pg,errs=await newpage(br,vp,list(init)+([FAKE] if fake is not None else []))
        R={"errs":errs,"inv":[],"seen":[],"finished":False,"hang":False}
        await pg.goto(f"{BASE}index.html?cuento={story}&fast={fast}&rec=1&a=ventana&ave=puerta&c=ventana&{query}")   # the story's draws fixed, so every run plays the same story; await pg.wait_for_function("window.Story&&Story.ready",timeout=20000); await pg.wait_for_timeout(1200)
        await pg.evaluate(SPY)
        if fake is not None: await pg.evaluate("q=>{window.__fakeQ=q}",fake)
        await pg.click("#go"); t0=time.time(); tapped=None; last=None; micw=0
        for i in range(9000):
            await pg.wait_for_timeout(40); s=await pg.evaluate(STATE)
            sig=(s["est"],s["bub"],s["at"])
            if sig!=last: last=sig; R["seen"].append(sig)
            logs=s["log"]
            if logs and logs[-1]["tipo"]=="ask" and logs[-1]["est"]=="" and s["est"]!="":   # a signed ask is being answered by voice: no sign, no speaking bubble, no touch
                if s["spot"] or s["respOn"] or s["sign"] or s["asked"]: R["inv"].append("ask turn showed sign/voice/touch: %s"%{k:s[k] for k in("spot","respOn","sign","asked")})
            if on_poll: await on_poll(pg,s,R)
            if not s["live"]: tapped=None
            if (mic=="tap" or (mic=="manual" and R.get("tap_ok"))) and s["mic"]=="ready":
                micw+=1
                if micw>=4: micw=0; await pg.click("#mic")
            else: micw=0
            if s["live"] and s["asked"] and (s["live"],s["est"])!=tapped and (s["est"]=="" or (s["kind"]=="elige" and touch_elige)):
                live=s["live"].split("|"); tgt=s["pick"] if s["kind"]=="decide" and s["pick"] in live else live[0]
                await pg.wait_for_timeout(150)
                try: await pg.evaluate(f"Story.tapOn('{tgt}')")
                except Exception as e: R["errs"].append("could not touch "+tgt)
                tapped=(s["live"],s["est"]); await pg.wait_for_timeout(150)
            if not s["running"] and i>40: R["finished"]=True; break
            if time.time()-t0>budget: R["hang"]=True; break
        R["secs"]=round(time.time()-t0,1)
        for k,e in (("log","Story.hab.log"),("hab","Story.hab"),("clips","__c"),("rights","__right"),("resp","__resp"),("lost","Story.W.lost"),
                    ("words","Object.fromEntries(Object.entries(PAL.db.palabras).map(([k,v])=>[k,{ear:[v.ear.n,v.ear.bien,v.ear.etapa],mouth:[v.mouth.n,v.mouth.bien]}]))"),
                    ("nd","(()=>{try{return sessionStorage.getItem('coqui.habla.nodisp')}catch(e){return 'x'}})()")): R[k]=await pg.evaluate(e)
        if fake is not None: R["fake"]=await pg.evaluate("[__fakeProps,__fakeCalls,window.__resume]")
        R["bad_errs"]=[e for e in errs if "vibrate" not in e]
        await ctx.close(); return R
def ear(R): return {w:v["ear"] for w,v in R["words"].items()}
def mouth(R,w): return R["words"].get(w,{}).get("mouth",[0,0])
def seq(R,a,b):
    """the clips played between the first a and the next b (None when there are none)"""
    c=R["clips"]
    if a not in c: return None
    i=c.index(a); k=[x for x in range(i+1,len(c)) if c[x]==b]
    return c[i+1:k[0]] if k else None
def ests(R):
    o=[]
    for s in R["seen"]:
        if s[0] and (not o or o[-1]!=s[0]): o.append(s[0])
    return o
def kinds(R): return [(x["tipo"],x["est"]) for x in R["log"]]
def base(name,R,turns=None):
    ck(name+": no page errors",not R["bad_errs"],R["bad_errs"][:2]); ck(name+": the story reaches its end",R["finished"] and not R["hang"],"%ss"%R.get("secs"))
    ck(name+": no ask turn showed the sign, a voice, or let a touch through",not R["inv"],R["inv"][:2])
    if turns is not None: ck(name+": turns "+str(turns),kinds(R)==turns,[(x["tipo"],x["est"],x["intentos"]) for x in R["log"]])
def seen(R,*pairs): return all(p in [(s[1],s[2]) for s in R["seen"]] for p in pairs)
SI3="mic=stub:si|no|si%20gracias"
async def main():
    async with async_playwright() as p:
        br=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
        A="abiertas=todas&"; runs={}
        async def go(k,*a,**kw): runs[k]=await play(br,*a,**kw)
        await asyncio.gather(go("off",A+"mic=off"),go("noab",SI3),go("ok",A+SI3),go("try2",A+"mic=stub:none|si|none|no|none|none"),go("miss2",A+"mic=stub:none|none|none|none|none|none"),
            go("err",A+"mic=stub:error:not-allowed|si|no|si"),go("other2",A+"mic=stub:si|si|si|none|none"),go("cap4",A+"mic=stub:si|ay|no|pajaro|si%20gracias",story="zprueba-habla5"),
            go("oir",A+"oir=1&"+SI3),go("swoff",A+SI3,init=[SWOFF]),go("txtno",A+"txt=no&"+SI3),go("elige_touch",A+"mic=stub:si|no|none",touch_elige=True),
            go("elige_both",A+"mic=stub:si|no|si%20no%20gracias|si%20gracias"),go("open_a",SI3,init=[seed_js({"sí":(3,0),"no":(0,0)})]),go("open_b",SI3,init=[seed_js({"sí":(2,0),"no":(2,0)})]),
            go("open_c",SI3,init=[seed_js({"sí":(1,1),"no":(1,1)})]),go("open_d",SI3,init=[seed_js({"sí":(3,0),"no":(3,0)})]))
        off=runs["off"]
        base("mic=off",off,[]); ck("mic=off: the mic never showed, speaking reports unavailable",not any(s[0] for s in off["seen"]) and not off["hab"]["disp"],off["seen"][:3])
        ck("mic=off: no mouth record written",all(v["mouth"][0]==0 for v in off["words"].values())); ck("mic=off: the stake is 0 (the reference for the other runs)",off["lost"]==0,off["lost"])
        r=runs["noab"]; base("no ?abiertas on a first play",r,[]); ck("no ?abiertas: no mic shown, nothing recorded",not any(s[0] for s in r["seen"]) and all(v["mouth"][0]==0 for v in r["words"].values()))
        ck("no ?abiertas: the same clips as a run with the mic off",r["clips"]==off["clips"])
        r=runs["swoff"]; base("Yo switch off",r,[]); ck("Yo switch off: the same clips as today, no mic",r["clips"]==off["clips"] and not any(s[0] for s in r["seen"]))
        r=runs["oir"]; base("?oir=1",r,[]); ck("?oir=1: no mic and no mouth record",not any(s[0] for s in r["seen"]) and all(v["mouth"][0]==0 for v in r["words"].values()))
        # heard right
        r=runs["ok"]; base("heard right",r,[("linea","ok"),("ask","ok"),("elige","ok")])
        ck("heard right: three turns (the marked clips inside the decide were not turns)",r["hab"]["n"]==3 and len(r["log"])==3,r["hab"]["n"])
        ck("heard right: a new word: the coqui's line first, then Ahora tu",seq(r,"quieres_hola","ahora_no")==["cq_si","ahora_tu"],seq(r,"quieres_hola","ahora_no"))
        ck("heard right (ask): the question, then the turn; said[t] did not play; bien came (st.bien)",seq(r,"puerta_cerrada_q","mira_pajaro")==["muy_bien"],seq(r,"puerta_cerrada_q","mira_pajaro"))
        ck("heard right (elige): said[option] did not play again, the option's steps ran",seq(r,"quieres_bizcocho","cq_mmm")==["toma"],seq(r,"quieres_bizcocho","cq_mmm"))
        ck("once per play: the first ask's said clip (cq_si) had been a turn already, so it played as today",seq(r,"abre_puerta_q","abre_puerta")==["cq_si","muy_bien"],seq(r,"abre_puerta_q","abre_puerta"))
        ck("heard right: mouth right, one answer per target word (sí twice, no once)",mouth(r,"sí")==[2,2] and mouth(r,"no")==[1,1],(mouth(r,"sí"),mouth(r,"no")))
        ck("heard right: ms is the tap to speechstart (the stub: about 120 ms)",all(90<=a[3]<=700 for a in r["resp"]),[a[3] for a in r["resp"]])
        ck("heard right: only PAL.responde(word,'mouth',ok,ms,false), three calls, never the ear",all(a[1]=="mouth" and a[4] is False and a[2] is True for a in r["resp"]) and len(r["resp"])==3,r["resp"])
        ck("heard right: the stake is the same as without turns",r["lost"]==off["lost"],(r["lost"],off["lost"])); ck("heard right: the ear records are the same as without turns",ear(r)==ear(off))
        ck("heard right: one right signal more than without turns (the plain line's)",r["rights"]==off["rights"]+1,(r["rights"],off["rights"]))
        ck("heard right: the bubble held the mic at the frog, then the tick",seen(r,("mic","coqui"),("ok","coqui")),[s[1:] for s in r["seen"]][:10])
        ck("heard right: the mic went dead, ready, listening, processing, ok",ests(r)[:5]==["dead","ready","listening","processing","ok"],ests(r)[:8])
        # right on the second try
        r=runs["try2"]; base("heard right on try 2",r,[("linea","ok"),("ask","ok"),("elige","fallo")])
        ck("try 2: the plain line's first miss played Ahora tu again",r["log"][0]["intentos"]==2 and r["clips"].count("ahora_tu")==2,(r["log"][0],r["clips"].count("ahora_tu")))
        ck("try 2: right on try 2 is right (mouth right for sí and no)",mouth(r,"sí")==[1,1] and mouth(r,"no")==[1,1],(mouth(r,"sí"),mouth(r,"no")))
        # two misses
        r=runs["miss2"]; base("two misses",r,[("linea","fallo"),("ask","fallo"),("elige","fallo")])
        ck("two misses: Ahora tu after the first miss, the model after the second (cq_si twice)",seq(r,"quieres_hola","ahora_no")==["cq_si","ahora_tu","ahora_tu","cq_si"],seq(r,"quieres_hola","ahora_no"))
        ck("two misses: mouth answers written, none right",mouth(r,"sí")==[1,0] and mouth(r,"no")==[1,0],(mouth(r,"sí"),mouth(r,"no")))
        ck("two misses: no right signal for the plain line, the stake unchanged",r["rights"]==off["rights"] and r["lost"]==off["lost"],(r["rights"],off["rights"],r["lost"]))
        ck("two misses (ask): the question was asked again, the touch worked, said played as today",r["clips"].count("puerta_cerrada_q")==2 and seq(r,"puerta_cerrada_q","mira_pajaro") is not None and "cq_no" in seq(r,"puerta_cerrada_q","mira_pajaro"),seq(r,"puerta_cerrada_q","mira_pajaro"))
        ck("two misses (elige): the bubbles worked after the mic went (said played as today)",seq(r,"quieres_bizcocho","cq_mmm") is not None and "cq_si_gracias" in seq(r,"quieres_bizcocho","cq_mmm"),seq(r,"quieres_bizcocho","cq_mmm"))
        ck("two misses: the ear records are the same as without turns",ear(r)==ear(off))
        # the ask: the other option said twice
        r=runs["other2"]; base("ask: the other option said twice",r,[("linea","ok"),("ask","fallo"),("elige","fallo")])
        ck("ask, other option twice: written wrong, never right",mouth(r,"no")==[1,0],mouth(r,"no"))
        ck("ask, other option twice: the sign and the voices came back and the touch worked",r["clips"].count("puerta_cerrada_q")==2 and "cq_no" in (seq(r,"puerta_cerrada_q","mira_pajaro") or []))
        # an error that says speaking cannot work
        r=runs["err"]; base("error:not-allowed on the first turn",r,[("linea","nodisp")])
        ck("not-allowed: the line played as today (the model again), nothing recorded",seq(r,"quieres_hola","ahora_no")==["cq_si","ahora_tu","cq_si"] and all(v["mouth"][0]==0 for v in r["words"].values()),seq(r,"quieres_hola","ahora_no"))
        ck("not-allowed: no more turns; the session is flagged, speaking reports unavailable",r["nd"]=="1" and not r["hab"]["disp"] and r["hab"]["n"]==1,(r["nd"],r["hab"]["disp"],r["hab"]["n"]))
        ck("not-allowed: the rest played as today (ask and elige by touch, same stake)",r["lost"]==off["lost"] and "cq_si_gracias" in r["clips"])
        # at most 4 turns; a plain line inside a decide's right can be a turn
        r=runs["cap4"]; base("cap of 4 turns (5 marked, one inside a decide's right)",r,[("linea","ok"),("linea","ok"),("ask","ok"),("linea","ok")])
        ck("cap: the 5th (the elige) played as today, by touch; never more than 4; the stake unchanged",r["hab"]["n"]==4 and "cq_si_gracias" in r["clips"] and r["lost"]==off["lost"],(r["hab"]["n"],r["lost"]))
        # elige: both options matched, a touch while the mic is up
        r=runs["elige_both"]; base("elige: both options matched, then one",r,[("linea","ok"),("ask","ok"),("elige","ok")])
        ck("elige: 'si no gracias' matches both options (a miss); the next try took one option",r["log"][2]["intentos"]==2 and r["log"][2].get("op")=="si",r["log"][2])
        r=runs["elige_touch"]; base("elige: touch while the mic is up",r)
        ck("elige: a touch was taken while the mic was up; nothing written for the elige",kinds(r)[:2]==[("linea","ok"),("ask","ok")] and mouth(r,"sí")==[1,1] and "cq_si_gracias" in r["clips"],(r["log"],mouth(r,"sí")))
        # which words are open
        r=runs["open_a"]; base("open: sí at stage 3, no not open",r,[("linea","ok")])
        r=runs["open_b"]; base("open: stage 2 only",r,[]); ck("open: stage 2 with no mouth answer opens nothing",not any(s[0] for s in r["seen"]))
        r=runs["open_c"]; base("open: the mouth already has an answer (stage 1, mouth.n 1)",r,[("linea","ok"),("ask","ok"),("elige","ok")])
        ck("open: no model when every target has been said before (straight to the mic)",seq(r,"quieres_hola","ahora_no")==[],seq(r,"quieres_hola","ahora_no")); ck("open: the mouth answers add up",mouth(r,"sí")==[3,2] and mouth(r,"no")==[2,1],(mouth(r,"sí"),mouth(r,"no")))
        r=runs["open_d"]; base("open: both at stage 3",r,[("linea","ok"),("ask","ok"),("elige","ok")])
        r=runs["txtno"]; base("?txt=no",r,[("linea","ok"),("ask","ok"),("elige","ok")]); ck("?txt=no: the mic bubble and the tick still show",seen(r,("mic","coqui"),("ok","coqui")))

        # the real recogniser code path, with a fake recogniser (no ?mic at all)
        r2={}
        async def touch_listening(pg,s,R):   # an elige: he touches an option while the mic is listening
            if s["kind"]=="elige" and s["est"]=="listening" and "t" not in R: R["t"]=1; await pg.evaluate("Story.tapOn('no')")
        async def silence_after_turn(pg,s,R):   # iPhone: after a turn a clip may never report its end. Here no clip even starts; every clip is let go after its length + 1 s
            if s["log"] and s["log"][0]["est"]=="ok" and "n0" not in R:
                await pg.evaluate("AudioBufferSourceNode.prototype.start=function(){}"); R["n0"]=await pg.evaluate("__c.length"); R["t0"]=time.time()
        async def go2(k,q,**kw): r2[k]=await play(br,"abiertas=todas",fake=q,**kw)
        await asyncio.gather(go2("alt",[{"alts":["ese","si"],"onset":400},{"alts":["no","si"]},{"alts":["si gracias"]}]),
                             go2("errs",[{"err":"no-speech"},{"alts":["si"]},{"err":"aborted"},{"err":"aborted"},{"err":"audio-capture"}]),
                             go2("hang",[{"hang":True},{"alts":["si"]},{"hang":True,"noend":True},{"hang":True,"noend":True},{"alts":["si gracias"]}]),
                             go2("elige_listen",[{"alts":["si"]},{"alts":["no"]},{"hang":True,"noend":True}],on_poll=touch_listening),
                             go2("limit",[{"alts":["si"]},{"alts":["no"]},{"alts":["si gracias"]}],on_poll=silence_after_turn,budget=40))
        r=r2["alt"]; base("real recogniser: heard right in the second alternative",r,[("linea","ok"),("ask","ok"),("elige","ok")])
        ck("real recogniser: ms is the tap to the fake's speechstart (400 ms)",bool(r["resp"]) and r["resp"][0][3]>=300,[a[3] for a in r["resp"]])
        ck("real recogniser: lang es-US, interimResults false, maxAlternatives 5, continuous false",all(x["lang"]=="es-US" and x["interim"] is False and x["max"]==5 and x["cont"] is False for x in r["fake"][0]),r["fake"][0][:1])
        ck("real recogniser: nothing was playing when it started (hush first)",all(x["speaking"]==0 for x in r["fake"][0]),[x["speaking"] for x in r["fake"][0]])
        ck("iPhone: ac().resume() was called after every recognition ended",r["fake"][2]>=3,r["fake"][2])
        r=r2["errs"]; base("real recogniser: no-speech and aborted are misses, audio-capture is unavailable",r,[("linea","ok"),("ask","fallo"),("elige","nodisp")])
        ck("real recogniser: no-speech on try 1, right on try 2",r["log"][0]["intentos"]==2,r["log"][0]); ck("real recogniser: audio-capture flagged the session",r["nd"]=="1",r["nd"])
        r=r2["hang"]; base("real recogniser: it hangs: stop() at 6 s (1 s at fast=6), then a forced end (a miss)",r,[("linea","ok"),("ask","fallo"),("elige","ok")])
        ck("hang: stop() was called, and abort() when stop() was not enough",r["fake"][1]["stop"]>=3 and r["fake"][1]["abort"]>=2,r["fake"][1])

        r=r2["elige_listen"]; base("elige: touched while the mic is listening",r)
        ck("elige touched while listening: the mic went, the touched option's said clip played as today, nothing written for it",kinds(r)[2:]==[("elige","")] and "cq_no_gracias" in r["clips"] and "abuela_no" in r["clips"] and len(r["resp"])==2,(r["log"][2:],len(r["resp"])))
        r=r2["limit"]; grown=len(r["clips"])-r.get("n0",10**6)
        ck("iPhone: after a turn the story does not hang on a clip that never ends (5 or more clips went by in about 35 s, each let go after its length + 1 s)",grown>=5 and not r["bad_errs"],(grown,r.get("secs"),r["bad_errs"][:1]))
        # the rules, as units, in the page itself
        ctx,pg,errs=await newpage(br,(390,844),[]); await pg.goto(BASE+"app.html?tab=yo"); await pg.wait_for_function("window.App&&App.ready",timeout=20000)
        norms=["¡Sí, Adiós!","Ñandú","  Hola,   ABUELA  ","¿Cómo estás?","por favor","1, 2, 3","","  ","Árbol-ñ","a_b","ÜÖ"]
        same=await pg.evaluate("n=>n.map(s=>PAL.norm(s)===Llamada.norm(s))",norms); ck("PAL.norm gives the same as llamada.js's norm()",all(same),same)
        ck("PAL.norm pads a space each side, drops accents, turns n-tilde into n",await pg.evaluate("PAL.norm('¡Sí, Ñandú!')===' si nandu '"))
        cases=[(["hola abuela"],[("hola",["hola"]),("abuela",["abuela"])],True),(["abuela hola"],[("hola",["hola"]),("abuela",["abuela"])],True),(["ola abuela","hola abuela"],[("hola",["hola"]),("abuela",["abuela"])],True),
               (["ola abuela"],[("hola",["hola"]),("abuela",["abuela"])],False),(["Sí, gracias, abuela"],[("sí",["si"])],True),(["sin azúcar"],[("sí",["si"])],False),(["quiero jugo por favor"],[("quiero",["quiero"]),("jugo",["jugo"])],True),
               (["favor"],[("por favor",["por favor"])],False),(["uno dos tres"],[("uno",["uno","1"]),("tres",["tres","3"])],True),(["1 2 3"],[("uno",["uno","1"]),("tres",["tres","3"])],True),(["uno dos"],[("uno",["uno","1"]),("tres",["tres","3"])],False),
               (["¿Cómo estás tú?"],[("¿cómo estás?",["como estas"])],True),([""],[("hola",["hola"])],False),([],[("hola",["hola"])],False)]
        okc=await pg.evaluate("""cs=>cs.map(([alts,T,exp])=>{const ns=alts.map(PAL.norm);return T.every(([p,fs])=>fs.some(f=>{const g=PAL.norm(f).trim();return g!==''&&ns.some(a=>a.indexOf(' '+g+' ')>=0);}))===exp;})""",[[a,[[w,f] for w,f in t],e] for a,t,e in cases])
        ck("the heard-right rule: whole words, any alternative, any order, extra words fine, 'favor' alone is not 'por favor'",all(okc),okc)
        ab=await pg.evaluate("""()=>{const sk=(e,n)=>({etapa:e,paso:1,seguidas:0,fallos:0,gap:0,due:0,aciertos:[],ultima:0,aparcada:0,marca:0,n:n||0,bien:0});const d=PAL.db.palabras;
          d.x3={w:'x3',ear:sk(3),mouth:sk(0)};d.x2={w:'x2',ear:sk(2),mouth:sk(0)};d.x2m={w:'x2m',ear:sk(2),mouth:sk(0,1)};d.x4={w:'x4',ear:sk(4),mouth:sk(0)};
          return ['x3','x2','x2m','x4','nope'].map(w=>PAL.abiertaHabla(w));}""")
        ck("PAL.abiertaHabla: ear stage 3 or more, or a mouth answer; not stage 2; not a word with no record",ab==[True,False,True,True,False],ab)
        ck("the Yo switch is on by default",await pg.evaluate("PAL.db.ajustes.habla")==1); ck("the unit page had no errors",not errs,errs[:2]); await ctx.close()

        # the Yo screen: the switch and the once-a-day note
        async def yo(q,init=()):
            ctx,pg,errs=await newpage(br,(390,844),init)
            await pg.goto(BASE+"app.html?tab=yo"+q); await pg.wait_for_function("window.App&&App.ready",timeout=20000); await pg.evaluate("App.listo()"); await pg.wait_for_timeout(300); t1=await pg.inner_text("#t-yo")
            await pg.evaluate("document.querySelector('.sw[aria-label=\"Speak in stories\"]').click()"); await pg.wait_for_timeout(100); t1b=await pg.inner_text("#t-yo"); sw=await pg.evaluate("PAL.db.ajustes.habla")
            await pg.reload(); await pg.wait_for_function("window.App&&App.ready",timeout=20000); await pg.wait_for_timeout(300); t2=await pg.inner_text("#t-yo"); await ctx.close(); return t1,t1b,sw,t2,errs
        NOTE="Speaking in stories isn't available on this phone right now."
        t1,t1b,sw,t2,errs=await yo("&mic=off")
        ck("Yo: the switch 'Speak in stories' is there and toggles ajustes.habla (on to off)","Speak in stories" in t1 and sw==0,sw); ck("Yo: the note shows when speaking is unavailable (?mic=off)",NOTE in t1,t1[-250:])
        ck("Yo: the note stays while the page is open, also after a re-render",NOTE in t1b); ck("Yo: the note does not come again the same day",NOTE not in t2); ck("Yo: no page errors",not errs,errs[:2])
        old="try{if(!localStorage.getItem('coqui.palabras.v1'))localStorage.setItem('coqui.palabras.v1',JSON.stringify({palabras:{},dias:{},cuentos:{},ajustes:{min:30,todo:0,bienvenida:1,habla:1,notaHabla:'2000-01-01'},minutos:0,v:1}))}catch(e){}"
        t1,_,_,_,_=await yo("&mic=off",init=[old]); ck("Yo: the note comes back on a later day",NOTE in t1)
        t1,_,_,_,_=await yo(""); ck("Yo: no note when speaking is available",NOTE not in t1)

        # layout in three screen sizes
        lay={}
        def lay_poll(name):
            async def f(pg,s,R):
                if s["mic"]=="ready" and "rect" not in R:
                    await pg.wait_for_timeout(300)
                    R["rect"]=await pg.evaluate("""()=>{const r=id=>{const b=document.getElementById(id).getBoundingClientRect();return [b.left,b.top,b.width,b.height]};return {mic:r('mic'),bub:r('bub'),cv:r('cv'),vw:innerWidth,vh:innerHeight,bg:getComputedStyle(document.getElementById('mic')).backgroundColor,vis:document.getElementById('bub').classList.contains('on')}}""")
                    await pg.screenshot(path=f"{OUT}/turno_{name}_ready.png")
            return f
        async def one(name,vp): lay[name]=await play(br,A+SI3,vp=vp,on_poll=lay_poll(name),mic="never",budget=45)
        await asyncio.gather(one("390x844",(390,844)),one("360x640",(360,640)),one("844x390",(844,390)))
        for name,R in lay.items():
            r=R.get("rect")
            if not r: ck("layout "+name+": the mic became ready",False); continue
            mx,my,mw,mh=r["mic"]; cx,cy,cw,ch=r["cv"]; bx,by,bw,bh=r["bub"]
            ck("layout "+name+": the mic is at least 72 px and whole on screen",mw>=72 and mh>=72 and mx>=0 and my>=0 and mx+mw<=r["vw"] and my+mh<=r["vh"],r["mic"])
            ck("layout "+name+": the mic does not cover the picture",not(mx<cx+cw and mx+mw>cx and my<cy+ch and my+mh>cy),(r["mic"],r["cv"]))
            if name=="844x390": ck("layout "+name+": on its side the mic is in the right column, at the bottom",mx>=cx+cw and my+mh>r["vh"]-32,r["mic"])
            else: ck("layout "+name+": upright the mic is bottom centre",abs(mx+mw/2-r["vw"]/2)<=1 and my+mh>r["vh"]-60,r["mic"])
            ck("layout "+name+": the mic bubble shows, on screen",r["vis"] and bx>=0 and by>=0 and bx+bw<=r["vw"],r["bub"])
            ck("layout "+name+": the ready mic is green",r["bg"]=="rgb(23, 128, 63)",r["bg"])
        # the frog is not on screen: the bubble sits just above the mic button
        async def hide(pg,s,R):
            if s["log"] and s["log"][-1]["tipo"]=="ask" and s["est"]=="dead" and "hid" not in R: R["hid"]=1; await pg.evaluate("Story.W.cq.vis=0")
            if "hid" in R and s["mic"]=="ready" and "rect" not in R:
                await pg.wait_for_timeout(300); R["rect"]=await pg.evaluate("""()=>{const r=id=>{const b=document.getElementById(id).getBoundingClientRect();return [b.left,b.top,b.width,b.height]};return {mic:r('mic'),bub:r('bub'),at:Story.hab.at}}""")
                await pg.screenshot(path=f"{OUT}/turno_sin_rana.png")
        R=await play(br,A+SI3,on_poll=hide,budget=90); r=R.get("rect")
        ck("frog not on screen: the bubble is placed at the mic",bool(r) and r["at"]=="mic",r)
        if r: ck("frog not on screen: the bubble sits just above the mic button, centred on it",r["bub"][1]+r["bub"][3]<=r["mic"][1] and abs(r["bub"][0]+r["bub"][2]/2-(r["mic"][0]+r["mic"][2]/2))<=2,(r["bub"],r["mic"]))
        base("frog not on screen",R,[("linea","ok"),("ask","ok"),("elige","ok")])

        # real time (fast=1): the 9 s repeat, nothing repeats while listening, the frog does nothing while listening, the 6 s stop; an elige touched while listening
        T1={}
        async def live(pg,s,R):
            now=time.time()
            if s["mic"]=="ready" and "ready" not in T1: T1["ready"]=now; T1["c0"]=await pg.evaluate("__c.filter(x=>x==='ahora_tu').length")
            if "ready" in T1 and "tapped" not in T1 and now-T1["ready"]>10.2:
                T1["rep"]=await pg.evaluate("__c.filter(x=>x==='ahora_tu').length")-T1["c0"]; await pg.click("#mic"); T1["tapped"]=now; R["tap_ok"]=True
            if s["est"]=="listening" and "tapped" in T1 and "lis" not in T1:
                T1["lis"]=now; T1["c1"]=await pg.evaluate("__c.length"); await pg.wait_for_timeout(300); await pg.evaluate("Story.tapOn('coqui')"); await pg.wait_for_timeout(500)
                T1["frog"]=await pg.evaluate("__c.length")-T1["c1"]
            if s["est"]=="processing" and "lis" in T1 and "proc" not in T1: T1["proc"]=now; T1["c2"]=await pg.evaluate("__c.length")
            if s["est"]=="dead" and "proc" in T1 and "after" not in T1: T1["after"]=now
        R=await play(br,A.rstrip("&"),fake=[{"hang":True},{"alts":["si"]},{"alts":["no"]},{"alts":["si gracias"]}],fast=1,mic="manual",on_poll=live,budget=120)
        ck("9 s idle: Ahora tu played again after about 9 s of waiting (before the tap)",T1.get("rep",0)>=1,T1.get("rep"))
        ck("listening: a touch on the frog did nothing (no clip played)",T1.get("frog")==0,T1.get("frog"))
        ck("the 6 s stop: processing showed at about 6 s after the tap",5.3<=T1.get("proc",0)-T1.get("tapped",0)<=7.5,round(T1.get("proc",0)-T1.get("tapped",0),2))
        ck("hang: stop() was called once the 6 s were up",R["fake"][1]["stop"]>=1,R["fake"][1])
        print("  (fast=1 run: %ss, turns %s)"%(R["secs"],[(x["tipo"],x["est"],x["intentos"]) for x in R["log"]]))
        await br.close()
    print("FAILED: %d"%len(FAILS))
    for f in FAILS: print("  -",f)
asyncio.run(main())
sys.exit(1 if FAILS else 0)
