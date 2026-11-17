# Checks the call with Danny by machine, with the page's own stub (?callstub=1; needs the local server on 8765, or on the port in LLAMADA_PORT):
#   python3 historia/tools/llamada_check.py <outdir>      (outdir must exist; makes one folder of numbered frames per screen size, prints one line per check and "FAILED: n" at the end)
# Per size (390x844, 360x640, 844x390): Hablar with nothing played, with 10 of 11 La casa stories played (both locked), with all 11 (open); the stepped call (every mic state, picture, Help, X, summary, back;
# the learner's "Adiós." at under a minute sends "(fin)" at once); the natural call with a fast clock (the learner says goodbye a moment after the second exchange, the page sends "(fin)", the call ends after Danny's goodbye).
# The variables: words_open = every place word of La casa, words_heard empty. At 390x844 only: refused microphone, failed start, X while calling, Danny hangs up, pagehide,
# the learner's "Hasta mañana.", Danny's own goodbye (nothing is sent, the call ends after his line), the goodbye loop of the first real call (the call ends after the first line, not at the 15 s cap),
# no goodbye (15 s cap), the 7-minute stop, the 6-minute "(fin)", and the page without the stub (nothing breaks while the voice library cannot load).
import asyncio,json,os,sys,time
from playwright.async_api import async_playwright
OUT=sys.argv[1]; BASE="http://127.0.0.1:%s/historia/app.html"%os.environ.get("LLAMADA_PORT","8765"); HERE=os.path.dirname(os.path.abspath(__file__))
CASA=["la-lluvia","el-bizcocho","donde-esta-el-pajaro","el-jugo","que-calor","la-familia","la-foto","quien-eres-tu","las-flores","que-es-esto","hasta-manana"]
WORDS=[]
for c in CASA:
    for w in json.load(open(os.path.join(HERE,"..","cuentos",c+".json"),encoding="utf-8")).get("focus_words",[]):
        if w not in WORDS: WORDS.append(w)
OPEN=WORDS[:14]   # the words whose ear stage is 3 (the call no longer looks at the stage: every word of the place is open)
SAID=["hola","bien","gracias","sí","quiero","jugo","adiós"]   # the words of La casa in the stub's three learner lines
FAILS=[]; ERRS=[]
def ck(name,ok,detail=""):
    print(("ok   " if ok else "FAIL ")+name+(" | "+str(detail) if detail!="" else ""));
    if not ok: FAILS.append(name)
def seed(played):
    t=int(time.time()*1000); sk=lambda e:{"etapa":e,"paso":1,"seguidas":0,"fallos":0,"gap":0,"due":t+864000000 if e<3 else 0,"aciertos":[],"ultima":0,"aparcada":0,"marca":0,"n":0,"bien":0}
    return {"palabras":{w:{"w":w,"primera":t,"oida":1,"ear":sk(3 if w in OPEN else 1),"mouth":sk(0)} for w in WORDS},"dias":{},"cuentos":{c:{"n":1,"primera":t,"ultima":t,"perdido":0} for c in played},"ajustes":{"min":30,"todo":0,"bienvenida":1},"minutos":0,"v":1}
# records the timers made by the call's own code (llamada.js, outside the stub: found by "function installStub" to "if(STUB)installStub();") so that we can see none is left
_L=open(os.path.join(HERE,"..","llamada.js"),encoding="utf-8").read().split("\n")
STUB_A=next(i for i,l in enumerate(_L,1) if "function installStub" in l); STUB_B=next(i for i,l in enumerate(_L,1) if l.strip()=="if(STUB)installStub();")
TIMERS="""(()=>{const P=window.__tm={t:new Map(),i:new Map()};
const line=()=>{for(const l of (new Error().stack||"").split("\\n")){const m=l.match(/llamada\\.js[^:]*:(\\d+):/);if(m)return +m[1];}return 0;};
const prod=n=>n>0&&!(n>=@A@&&n<=@B@),st=window.setTimeout,si=window.setInterval,ct=window.clearTimeout,ci=window.clearInterval;
window.setTimeout=function(f,d,...a){const n=line();if(!prod(n))return st.call(window,f,d,...a);let id;const w=function(){P.t.delete(id);return typeof f==="function"?f.apply(this,arguments):undefined;};id=st.call(window,w,d,...a);P.t.set(id,n);return id;};
window.setInterval=function(f,d,...a){const n=line();const id=si.call(window,f,d,...a);if(prod(n))P.i.set(id,n);return id;};
window.clearTimeout=function(id){P.t.delete(id);return ct.call(window,id);};window.clearInterval=function(id){P.i.delete(id);return ci.call(window,id);};})();""".replace("@A@",str(STUB_A)).replace("@B@",str(STUB_B))
LAY="""()=>{const out={};for(const s of ['.lx','.lt','canvas','.ld','.lh','.ldisc','.ll','.lo','.lhelp','.lerr','.lsb h1','.ls1','.lchips','.lbk']){const e=document.querySelector('#llam '+s);if(!e)continue;const r=e.getBoundingClientRect(),cs=getComputedStyle(e);
 out[s]={x:r.left,y:r.top,r:r.right,b:r.bottom,w:r.width,h:r.height,vis:cs.visibility!=='hidden'&&cs.display!=='none'&&r.width>0&&r.height>0,fs:cs.fontSize,col:cs.color,bg:cs.backgroundColor};}
 return {el:out,vw:innerWidth,vh:innerHeight,sw:document.documentElement.scrollWidth,sh:document.documentElement.scrollHeight};}"""
def layout(L,tag,over=("canvas",".ld",".lh",".ldisc",".ll",".lo",".lhelp",".lx",".lt")):
    el={k:v for k,v in L["el"].items() if v["vis"]}; bad=[]
    for k,v in el.items():
        if v["x"]<-.5 or v["y"]<-.5 or v["r"]>L["vw"]+.5 or v["b"]>L["vh"]+.5: bad.append("outside:"+k)
    ks=[k for k in over if k in el]
    for i,a in enumerate(ks):
        for b in ks[i+1:]:
            A,B=el[a],el[b]
            if min(A["r"],B["r"])-max(A["x"],B["x"])>1 and min(A["b"],B["b"])-max(A["y"],B["y"])>1: bad.append("overlap:"+a+"+"+b)
    if L["sw"]>L["vw"]: bad.append("scrollwidth %d>%d"%(L["sw"],L["vw"]))
    ck(tag+" layout inside the screen, no overlaps",not bad,bad)
async def newpage(b,vw,vh,played,qs,tab="hablar"):
    ctx=await b.new_context(viewport={"width":vw,"height":vh},device_scale_factor=2,is_mobile=True,has_touch=True)
    await ctx.add_init_script(TIMERS); await ctx.add_init_script("try{if(!localStorage.getItem('coqui.palabras.v1'))localStorage.setItem('coqui.palabras.v1',%s)}catch(e){}"%json.dumps(json.dumps(seed(played))))
    pg=await ctx.new_page(); pg.errs=[]
    pg.on("pageerror",lambda e: pg.errs.append("pageerror:"+str(e))); pg.on("console",lambda m: pg.errs.append("console:"+m.text) if m.type=="error" else None)
    await pg.goto(BASE+"?tab="+tab+qs); await pg.wait_for_function("window.App&&App.ready",timeout=20000); await pg.wait_for_timeout(500); return pg,ctx
async def close(pg,ctx,tag):
    bad=[e for e in pg.errs if "navigator.vibrate" not in e and "vibrate" not in e]; ERRS.extend(bad)
    ck(tag+" no page errors (the vibrate line aside)",not bad,bad[:3]); await ctx.close()
async def tm(pg): return await pg.evaluate("[window.__tm.t.size,window.__tm.i.size]")
async def leftover(pg,tag,wait=900):
    await pg.wait_for_timeout(wait); t=await tm(pg); ck(tag+" no timers of the call left",t==[0,0],t)
async def step(pg,name,exp=None):
    return await pg.evaluate("""async([n,e])=>{const t0=performance.now();CallStub.go(n);if(!e)return 0;const r=document.getElementById('llam');while(r.dataset.s!==e&&performance.now()-t0<3000)await new Promise(x=>requestAnimationFrame(x));return r.dataset.s===e?Math.round(performance.now()-t0):-1;}""",[name,exp])
STATE="document.getElementById('llam')&&document.getElementById('llam').dataset.s"
async def shot(pg,d,cnt,name):
    cnt[0]+=1; await pg.screenshot(path="%s/%02d_%s.png"%(d,cnt[0],name))
async def view(b,label,vw,vh):
    d=OUT+"/p"+label; os.makedirs(d,exist_ok=True); n=[0]; T=label+" "
    # ---- Hablar locked: nothing played, then 10 of 11
    for k,(played,nm) in enumerate([([],"locked_none"),(CASA[:10],"locked_10of11")]):
        pg,ctx=await newpage(b,vw,vh,played,"&callstub=1"); await pg.wait_for_timeout(300); await shot(pg,d,n,nm)
        info=await pg.evaluate("""()=>{const c=[...document.querySelectorAll('#t-hablar .card.cc')];return {n:c.length,lk:c.filter(x=>x.classList.contains('lk')).length,t0:c[0].innerText.replace(/\\n/g,' | '),bg:getComputedStyle(c[0]).opacity,old:document.getElementById('t-hablar').innerText.includes('open later'),pb:c.filter(x=>x.querySelector('.pb')).length}}""")
        ck(T+nm+": ten Call Danny cards, all locked, La casa says Opens when you finish La casa",info["n"]==10 and info["lk"]==10 and info["pb"]==0 and "Opens when you finish La casa" in info["t0"] and not info["old"],info)
        await pg.click("#t-hablar .card.cc >> nth=0"); await pg.wait_for_timeout(300); ck(T+nm+": a touch on the locked card opens nothing",await pg.evaluate("!Llamada.activo&&!document.getElementById('llam')"))
        await close(pg,ctx,T+nm)
    # ---- Hablar open
    pg,ctx=await newpage(b,vw,vh,CASA,"&callstub=1&stub=manual,nofin"); await shot(pg,d,n,"hablar_open")   # nofin: the learner's "Adiós." sends (fin) at once, and the X, not Danny's goodbye, ends this stepped call
    info=await pg.evaluate("""()=>{const c=[...document.querySelectorAll('#t-hablar .card.cc')],o=c.filter(x=>!x.classList.contains('lk')),b=o[0]&&o[0].querySelector('.pb'),r=b&&b.getBoundingClientRect();return {n:c.length,open:o.length,t:o[0]&&o[0].innerText.replace(/\\n/g,' | '),w:r&&r.width,h:r&&r.height,bg:b&&getComputedStyle(b).backgroundColor,first:c[0]===o[0],sw:document.documentElement.scrollWidth,vw:innerWidth}}""")
    ck(T+"open: La casa's card is first and open, 'Call Danny' / 'La casa · about 5 min', green 48 px disc",info["open"]==1 and info["first"] and info["t"].startswith("Call Danny | La casa · about 5 min") and info["w"]==48 and info["h"]==48 and info["bg"]=="rgb(23, 128, 63)",info)
    ck(T+"open: no horizontal scroll on Hablar",info["sw"]<=info["vw"],info["sw"])
    mouth0=await pg.evaluate("Object.fromEntries(%s.map(w=>[w,PAL.db.palabras[w].mouth.n+'/'+PAL.db.palabras[w].mouth.bien]))"%json.dumps(SAID)); min0=await pg.evaluate("PAL.db.minutos")
    await pg.evaluate("window.__calls=[];const o=PAL.responde;PAL.responde=function(...a){window.__calls.push(a);return o.apply(this,a);};0")
    await pg.click("#t-hablar .card.cc >> nth=0"); await pg.wait_for_timeout(300)
    # ---- idle screen
    await shot(pg,d,n,"idle"); L=await pg.evaluate(LAY); E=L["el"]
    ck(T+"idle: dark #1B1B1F screen, tab bar covered, label 'Start call', X 48 px, timer 12 px, disc 72 px, Help hidden",await pg.evaluate("""()=>{const r=document.getElementById('llam'),nv=document.querySelector('nav').getBoundingClientRect(),e=document.elementFromPoint(innerWidth/2,nv.top+nv.height/2);return getComputedStyle(r).backgroundColor==='rgb(27, 27, 31)'&&r.contains(e)&&r.dataset.s==='idle'&&r.querySelector('.ll').textContent==='Start call'&&document.body.style.overflow==='hidden'}""")
       and E[".lx"]["w"]==48 and E[".lx"]["h"]==48 and E[".lt"]["fs"]=="12px" and E[".ldisc"]["w"]==72 and not E[".lhelp"]["vis"],{k:(round(v["w"]),round(v["h"]),v["fs"]) for k,v in E.items() if k in(".lx",".lt",".ldisc")})
    layout(L,T+"idle")
    cw=E["canvas"]["w"]; ck(T+"idle: the picture (La casa) is a whole number of device pixels per art pixel",abs(cw*2/196-round(cw*2/196))<1e-6 and E["canvas"]["vis"],(cw,cw*2/196,E["canvas"]["h"]))
    # ---- connecting (within 200 ms of the tap)
    t=await pg.evaluate("""async()=>{const t0=performance.now();document.querySelector('#llam .ldisc').click();const r=document.getElementById('llam');while(r.dataset.s!=='connecting'&&performance.now()-t0<1000)await new Promise(x=>requestAnimationFrame(x));return [Math.round(performance.now()-t0),r.querySelector('.ll').textContent];}""")
    ck(T+"connecting: shows within 200 ms, label 'Calling…'",t[0]<200 and t[1]=="Calling…",t); await pg.wait_for_timeout(250); await shot(pg,d,n,"connecting")
    ck(T+"connecting: the disc pulses",await pg.evaluate("getComputedStyle(document.querySelector('#llam .ldisc')).animationName")=="lpul")
    ck(T+"the call was started once, with the agent, websocket, no overrides, no signed URL, from the tap",await pg.evaluate("""()=>{const o=CallStub.opts;return o.agentId==='agent_3301m795q3xtfpx8c99zc0s870vm'&&o.connectionType==='websocket'&&!o.overrides&&!o.signedUrl&&!o.conversationToken&&Llamada.ocupado}"""))
    v=await pg.evaluate("CallStub.opts.dynamicVariables"); ao=[x.strip() for x in v["words_open"].split(",")]
    ck(T+"variables: place, job, minutes 5, opening; words_open = every place word of La casa (%d, in the list's order, the %d the ear had not held included); words_heard empty; the six variables, no more"%(len(WORDS),len(WORDS)-len(OPEN)),v["place"]=="La casa" and v["minutes"]=="5" and v["opening"]=="¡Hola! Soy Danny. ¿Cómo estás?" and v["job"].startswith("Say hello") and ao==WORDS and v["words_heard"]=="" and sorted(v)==sorted(["place","job","words_open","words_heard","minutes","opening"]),{"open":len(ao),"heard":v["words_heard"],"keys":sorted(v)})
    # ---- stepped call
    lat={}
    await pg.evaluate("CallStub.go('connect')"); await pg.wait_for_timeout(120); await shot(pg,d,n,"danny_wave"); L=await pg.evaluate(LAY)
    ck(T+"danny: state, label 'Danny', blue wave #3B5BDB animating",await pg.evaluate("""()=>{const r=document.getElementById('llam'),w=document.querySelector('#llam .lw');return r.dataset.s==='danny'&&r.querySelector('.ll').textContent==='Danny'&&getComputedStyle(w).borderTopColor==='rgb(59, 91, 219)'&&getComputedStyle(w).animationName==='lwave'}"""))
    ck(T+"timer shows 00:00 at the start",await pg.evaluate("document.querySelector('#llam .lt').textContent")=="00:00")
    await step(pg,"danny1"); await pg.wait_for_timeout(100); await shot(pg,d,n,"danny_line"); L=await pg.evaluate(LAY); E=L["el"]
    ck(T+"danny's line shown in white 18 px, at most 2 lines",await pg.evaluate("document.querySelector('#llam .ld').textContent")=="¡Hola! Soy Danny. ¿Cómo estás?" and E[".ld"]["fs"]=="18px" and E[".ld"]["col"]=="rgb(255, 255, 255)" and E[".ld"]["h"]<=48.5,(E[".ld"]["fs"],E[".ld"]["col"],E[".ld"]["h"])); layout(L,T+"danny")
    lat["you"]=await step(pg,"you1","you"); await pg.wait_for_timeout(250); await shot(pg,d,n,"you_ring"); L=await pg.evaluate(LAY)
    ck(T+"you: green ring, label 'Your turn', Help visible 48 px",await pg.evaluate("""()=>{const r=document.getElementById('llam');return r.dataset.s==='you'&&r.querySelector('.ll').textContent==='Your turn'&&getComputedStyle(document.querySelector('#llam .lg')).opacity==='1'&&getComputedStyle(document.querySelector('#llam .lg')).boxShadow.includes('rgb(63, 174, 107)')}""") and L["el"][".lhelp"]["vis"] and L["el"][".lhelp"]["h"]>=48,L["el"][".lhelp"]["h"]); layout(L,T+"you")
    await step(pg,"talk1"); await pg.wait_for_timeout(500); rt=await pg.evaluate("parseFloat(document.getElementById('llam').style.getPropertyValue('--rt'))"); await shot(pg,d,n,"you_talking")
    await step(pg,"quiet1"); t0=time.time(); await pg.wait_for_function("document.getElementById('llam').dataset.s==='proc'",timeout=3000); lat["proc_after_quiet_ms"]=round((time.time()-t0)*1000); await pg.wait_for_timeout(150); await shot(pg,d,n,"processing_dots")
    rt0=await pg.evaluate("1")  # (the ring is hidden in 'proc')
    ck(T+"you: the ring thickness follows the microphone level (quiet 3 px, talking %.1f px)"%rt,rt>5,rt)
    ck(T+"processing: dots shown, label 'One moment' (no ring)",await pg.evaluate("""()=>{const r=document.getElementById('llam');return r.dataset.s==='proc'&&getComputedStyle(document.querySelector('#llam .dts')).display==='flex'&&getComputedStyle(document.querySelector('#llam .lg')).opacity==='0'}"""))
    await step(pg,"heard1"); await pg.wait_for_timeout(100); await shot(pg,d,n,"heard_line"); L=await pg.evaluate(LAY); E=L["el"]
    ck(T+"what the app heard is shown, 16 px #9AD5A8",await pg.evaluate("document.querySelector('#llam .lh').textContent")=="Hola. Bien, gracias." and E[".lh"]["fs"]=="16px" and E[".lh"]["col"]=="rgb(154, 213, 168)",(E[".lh"]["fs"],E[".lh"]["col"])); layout(L,T+"heard")
    lat["danny2"]=await step(pg,"danny2","danny"); before=await pg.evaluate("document.querySelector('#llam canvas').toDataURL().length+':'+document.querySelector('#llam canvas').toDataURL().slice(-80)"); await pg.wait_for_timeout(900)
    after=await pg.evaluate("document.querySelector('#llam canvas').toDataURL().length+':'+document.querySelector('#llam canvas').toDataURL().slice(-80)"); await shot(pg,d,n,"danny_picture_jugo")
    ck(T+"show_picture('jugo') changes the picture; unknown keys are ignored; the tool answers 'shown'",before!=after and await pg.evaluate("""()=>{const c=document.querySelector('#llam canvas'),a=c.toDataURL(),r1=CallStub.o.clientTools.show_picture({picture:'zzz'}),r2=CallStub.o.clientTools.show_picture('nada'),r3=CallStub.o.clientTools.show_picture({picture:'bizcocho'});return r1==='shown'&&r2==='shown'&&r3==='shown'&&c.toDataURL()===a}"""))
    lat["you2"]=await step(pg,"you2","you"); await step(pg,"talk2"); await pg.wait_for_timeout(600); await step(pg,"quiet2"); await pg.wait_for_function("document.getElementById('llam').dataset.s==='proc'",timeout=3000); await step(pg,"heard2"); await pg.wait_for_timeout(100)
    await step(pg,"you3","you"); await step(pg,"talk3"); await pg.wait_for_timeout(500); await step(pg,"quiet3"); await pg.wait_for_timeout(100)
    await pg.click("#llam .lhelp"); await pg.wait_for_timeout(120); await shot(pg,d,n,"help_pressed")
    ck(T+"Help sends (ayuda)",await pg.evaluate("CallStub.sent.includes('(ayuda)')"),await pg.evaluate("CallStub.sent"))
    ck(T+"every change of state showed within 200 ms (Danny speaking / your turn): %s ms; the dots came %s ms after the learner went quiet"%(json.dumps({k:v for k,v in lat.items() if k!="proc_after_quiet_ms"}),lat["proc_after_quiet_ms"]),all(0<=v<200 for k,v in lat.items() if k!="proc_after_quiet_ms"),lat)
    await step(pg,"heard3"); await pg.wait_for_timeout(150)
    ck(T+"the learner's 'Adiós.' at under a minute of call time sends (fin) at once (no waiting for 2 minutes), after the Help message",await pg.evaluate("CallStub.sent.join(' ')=='(ayuda) (fin)'&&CallStub.sentAt[1]<60&&Llamada.fin&&!CallStub.ended"),await pg.evaluate("[CallStub.sent,CallStub.sentAt]"))
    # the timer runs
    ck(T+"the timer counts (mm:ss)",await pg.evaluate("/^\\d\\d:\\d\\d$/.test(document.querySelector('#llam .lt').textContent)"),await pg.evaluate("document.querySelector('#llam .lt').textContent"))
    # ---- X ends the live call with the summary
    await pg.click("#llam .lx"); await pg.wait_for_timeout(250); await shot(pg,d,n,"summary"); L=await pg.evaluate(LAY); E=L["el"]
    sm=await pg.evaluate("""()=>({s:document.getElementById('llam').dataset.s,h:document.querySelector('#llam .lsb h1').textContent,l:document.querySelector('#llam .ls1').textContent,chips:[...document.querySelectorAll('#llam .lchips span')].map(x=>x.textContent),btn:document.querySelector('#llam .lbk').textContent,bg:getComputedStyle(document.querySelector('#llam .lbk')).backgroundColor,bh:document.querySelector('#llam .lbk').getBoundingClientRect().height,ended:CallStub.ended,oc:Llamada.ocupado,why:Llamada.motivo})""")
    ck(T+"summary: 'Call done', 'N min · M words said', chips of the %d words said, blue 'Back to Hablar' (>= 48 px), call ended, lock released"%len(SAID),sm["s"]=="done" and sm["h"]=="Call done" and sm["l"]=="1 min · 7 words said" and sorted(sm["chips"])==sorted(SAID) and sm["btn"]=="Back to Hablar" and sm["bg"]=="rgb(59, 91, 219)" and sm["bh"]>=48 and sm["ended"] and not sm["oc"] and sm["why"]=="x",sm)
    layout({"el":{k:v for k,v in E.items() if k in(".lsb h1",".ls1",".lchips",".lbk")},"vw":L["vw"],"vh":L["vh"],"sw":L["sw"],"sh":L["sh"]},T+"summary",over=(".lsb h1",".ls1",".lchips",".lbk"))
    await leftover(pg,T+"after the X")
    mouth1=await pg.evaluate("Object.fromEntries(%s.map(w=>[w,PAL.db.palabras[w].mouth.n+'/'+PAL.db.palabras[w].mouth.bien]))"%json.dumps(SAID)); calls=await pg.evaluate("window.__calls"); min1=await pg.evaluate("PAL.db.minutos")
    ck(T+"mouth records saved: each of the 7 matched words 0/0 -> 1/1, nothing else recorded, ms given",all(mouth0[w]=="0/0" and mouth1[w]=="1/1" for w in SAID) and len(calls)==7 and all(c[1]=="mouth" and c[2] is True for c in calls) and all(c[3] is None or isinstance(c[3],int) for c in calls),{"before":mouth0,"after":mouth1,"ms":[c[3] for c in calls]})
    ck(T+"minutes listened went up with the call (%.2f -> %.2f)"%(min0,min1),min1>min0)
    await pg.click("#llam .lbk"); await pg.wait_for_timeout(400); await shot(pg,d,n,"back_to_hablar")
    ck(T+"back to Hablar: call screen gone, tab bar back, La casa's card open, scrolling restored, nothing active",await pg.evaluate("""()=>{const nv=document.querySelector('nav').getBoundingClientRect(),e=document.elementFromPoint(innerWidth/2,nv.top+nv.height/2);return !document.getElementById('llam')&&!Llamada.activo&&!Llamada.ocupado&&document.querySelector('nav').contains(e)&&document.body.style.overflow===''&&!!document.querySelector('#t-hablar .card.cc:not(.lk) .pb')&&document.querySelector('#t-hablar').classList.contains('on')}"""))
    await leftover(pg,T+"after Back to Hablar",200)
    await pg.click("#t-hablar .card.cc >> nth=0"); await pg.wait_for_timeout(300); ck(T+"the call can be opened again",await pg.evaluate("Llamada.estado==='idle'&&Llamada.activo")); await pg.click("#llam .lx"); await pg.wait_for_timeout(200)
    ck(T+"X before the call starts closes the screen",await pg.evaluate("!document.getElementById('llam')&&!Llamada.ocupado")); await close(pg,ctx,T+"stepped call")
    # ---- natural call, fast clock: the learner says goodbye a moment after the second exchange (well before 2 call-minutes), the page sends (fin)
    pg,ctx=await newpage(b,vw,vh,CASA,"&callstub=1&clock=3"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.wait_for_timeout(300)
    await pg.evaluate("window.__seq=[];new MutationObserver(()=>{const s=document.getElementById('llam').dataset.s,q=window.__seq;if(q[q.length-1]!==s)q.push(s);}).observe(document.getElementById('llam'),{attributes:true,attributeFilter:['data-s']});window.__seq.push('idle')")
    await pg.click("#llam .ldisc"); got=0
    for i in range(120):
        await pg.wait_for_timeout(500); s=await pg.evaluate(STATE)
        if not got and await pg.evaluate("CallStub.sent.includes('(fin)')") and s=="danny": await shot(pg,d,n,"natural_goodbye"); got=1
        if s=="done": break
    await pg.wait_for_timeout(300); await shot(pg,d,n,"natural_summary")
    sq=await pg.evaluate("window.__seq"); sm=await pg.evaluate("""()=>({l:document.querySelector('#llam .ls1').textContent,chips:[...document.querySelectorAll('#llam .lchips span')].map(x=>x.textContent),why:Llamada.motivo,sent:CallStub.sent,ended:CallStub.ended,oc:Llamada.ocupado,t:document.querySelector('#llam .lt').textContent})""")
    ck(T+"natural call: states idle > connecting > danny > (you > proc > danny)... > done, ends by itself after the goodbye ('fin')",sq[:3]==["idle","connecting","danny"] and sq[-1]=="done" and sq.count("proc")>=3 and sm["why"]=="fin" and sm["sent"]==["(fin)"] and sm["ended"] and not sm["oc"],{"seq":sq,"sent":sm["sent"],"why":sm["why"]})
    tt=sm["t"].split(":"); secs=int(tt[0])*60+int(tt[1]); fa=await pg.evaluate("CallStub.sentAt[0]")
    ck(T+"natural call: (fin) went out at %s s of call time and the call ended under 2 minutes (timer %s), so no 2-minute wait is left; the summary's minutes agree with the timer and say '7 words said'"%(fa,sm["t"]),0<fa<90 and secs<120 and sm["l"] in("%d min · 7 words said"%max(1,round(secs/60)),"%d min · 7 words said"%max(1,round((secs+1)/60))) and sorted(sm["chips"])==sorted(SAID),sm["l"])
    await leftover(pg,T+"after the natural call"); await pg.click("#llam .lbk"); await pg.wait_for_timeout(300); await close(pg,ctx,T+"natural call")
    # ---- error screen
    pg,ctx=await newpage(b,vw,vh,CASA,"&callstub=1&stub=mic"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.wait_for_timeout(200); await pg.click("#llam .ldisc"); await pg.wait_for_function("document.getElementById('llam').dataset.s==='err'",timeout=4000); await pg.wait_for_timeout(150); await shot(pg,d,n,"mic_refused"); L=await pg.evaluate(LAY)
    ck(T+"refused microphone: one plain line and the X",await pg.evaluate("document.querySelector('#llam .lerr').textContent")=="The microphone is off. Allow it in your browser to call." and L["el"][".lx"]["vis"],None); await pg.click("#llam .lx"); await pg.wait_for_timeout(200)
    ck(T+"the X closes it, the lock is free",await pg.evaluate("!document.getElementById('llam')&&!Llamada.ocupado")); await close(pg,ctx,T+"mic refused")
async def extras(b):
    T="390x844 "
    # X while calling: hang up before it picks up; the late answer is ended
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&stub=manual"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.wait_for_timeout(300)
    ck(T+"still calling (connecting) before the X",await pg.evaluate("Llamada.estado==='connecting'&&Llamada.ocupado")); await pg.click("#llam .lx"); await pg.wait_for_timeout(200)
    ck(T+"X while calling: screen gone, lock free",await pg.evaluate("!document.getElementById('llam')&&!Llamada.ocupado&&!Llamada.activo")); await pg.evaluate("CallStub.go('connect')"); await pg.wait_for_timeout(300)
    ck(T+"the late answer is ended at once, nothing shows",await pg.evaluate("CallStub.ended&&!document.getElementById('llam')&&!Llamada.ocupado")); await leftover(pg,T+"X while calling",100); await close(pg,ctx,T+"X while calling")
    # failed start
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&stub=fail"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.wait_for_function("document.getElementById('llam').dataset.s==='err'",timeout=4000)
    ck(T+"failed start: a plain line",await pg.evaluate("document.querySelector('#llam .lerr').textContent")=="The call did not start. Check your connection and try again."); await pg.click("#llam .lx"); await close(pg,ctx,T+"failed start")
    # Danny hangs up; the same call also checks one lock: a second tap on the disc does nothing
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&stub=manual"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.evaluate("document.querySelector('#llam .ldisc').click()"); await pg.evaluate("CallStub.go('connect')"); await pg.evaluate("CallStub.go('danny1')"); await pg.wait_for_timeout(300); await pg.evaluate("CallStub.go('end')"); await pg.wait_for_timeout(300)
    ck(T+"Danny ends the call: summary, why=disc, lock free",await pg.evaluate("Llamada.estado==='done'&&Llamada.motivo==='disc'&&!Llamada.ocupado")); await leftover(pg,T+"Danny hung up"); await close(pg,ctx,T+"Danny hangs up")
    # pagehide while live
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&stub=manual"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.evaluate("CallStub.go('connect')"); await pg.evaluate("CallStub.go('danny1')"); await pg.wait_for_timeout(1200); m0=await pg.evaluate("PAL.db.minutos"); await pg.evaluate("dispatchEvent(new Event('pagehide'))"); await pg.wait_for_timeout(200)
    ck(T+"pagehide ends the session, clears the timers, frees the lock, counts the minutes",await pg.evaluate("CallStub.ended&&!Llamada.ocupado")and (await pg.evaluate("PAL.db.minutos"))>m0,(m0,await pg.evaluate("PAL.db.minutos"))); await leftover(pg,T+"after pagehide",100); await close(pg,ctx,T+"pagehide")
    # the learner says "Hasta mañana." (not "Adiós.") a moment after the second exchange: (fin) at once, the call ends after Danny's goodbye
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&stub=hasta"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.wait_for_function("Llamada.estado==='done'",timeout=60000); await pg.wait_for_timeout(200)
    r=await pg.evaluate("[Llamada.motivo,CallStub.sent,CallStub.sentAt,CallStub.ended,[...document.querySelectorAll('#llam .lchips span')].map(x=>x.textContent)]")
    ck(T+"the learner's 'Hasta mañana.' at under a minute: (fin) sent once at once, the call ends after Danny's goodbye (why=fin), 'hasta mañana' counted as a word said",r[0]=="fin" and r[1]==["(fin)"] and r[2][0]<60 and r[3] and "hasta mañana" in r[4],r); await leftover(pg,T+"after 'Hasta mañana.'",100); await close(pg,ctx,T+"hasta mañana")
    # Danny says goodbye on his own (the learner says nothing): nothing is sent, the call ends when his line is over
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&stub=dannybye"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.wait_for_function("document.getElementById('llam').dataset.s==='done'||CallStub.log.filter(x=>x==='speaking').length>=3",timeout=60000)
    t0=time.time(); await pg.wait_for_function("Llamada.estado==='done'",timeout=20000); dt=time.time()-t0; r=await pg.evaluate("[Llamada.motivo,CallStub.sent,CallStub.ended,CallStub.log.filter(x=>x==='speaking').length,document.querySelector('#llam .ld')&&1]")
    ck(T+"Danny's own goodbye: the call ends when his line is over (%.1f s after it began, not the 15 s cap), nothing is sent (no (fin)), why=fin"%dt,r[0]=="fin" and r[1]==[] and r[2] and r[3]==3 and dt<5,r); await leftover(pg,T+"after Danny's own goodbye",100); await close(pg,ctx,T+"Danny's own goodbye")
    # the goodbye loop of the first real call: the learner says "Adiós.", Danny goes on saying goodbyes every 3 s for ever; the page ends the call after the first line
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&stub=loop"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.wait_for_function("CallStub.sent.includes('(fin)')",timeout=60000)
    t0=time.time(); await pg.wait_for_function("Llamada.estado==='done'",timeout=20000); dt=time.time()-t0; await pg.wait_for_timeout(4000)
    r=await pg.evaluate("[Llamada.motivo,CallStub.sent,CallStub.ended,CallStub.log.filter(x=>x==='speaking').length,Llamada.estado]")
    ck(T+"goodbye loop (learner's 'Adiós.', Danny repeats goodbyes every 3 s): (fin) once, the call ends after the first goodbye line (%.1f s after (fin), not the 15 s cap, not 20 s of loop), one goodbye line heard in all, why=fin"%dt,r[0]=="fin" and r[1]==["(fin)"] and r[2] and r[3]==3 and dt<5 and r[4]=="done",r); await leftover(pg,T+"after the loop",100); await close(pg,ctx,T+"goodbye loop")
    # Danny's own goodbye, then the loop: still ends after his first line, nothing sent
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&stub=dannybye,loop"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.wait_for_function("CallStub.log.filter(x=>x==='speaking').length>=3",timeout=60000)
    t0=time.time(); await pg.wait_for_function("Llamada.estado==='done'",timeout=20000); dt=time.time()-t0; await pg.wait_for_timeout(4000)
    r=await pg.evaluate("[Llamada.motivo,CallStub.sent,CallStub.ended,CallStub.log.filter(x=>x==='speaking').length]")
    ck(T+"Danny's own goodbye followed by the loop: the call ends after his first goodbye line (%.1f s), nothing is sent, no second goodbye line, why=fin"%dt,r[0]=="fin" and r[1]==[] and r[2] and r[3]==3 and dt<5,r); await leftover(pg,T+"after his own goodbye and the loop",100); await close(pg,ctx,T+"own goodbye and loop")
    # clock x60, Danny never answers (fin): the 7-minute stop
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&clock=60&stub=nofin"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.wait_for_function("Llamada.estado==='done'",timeout=40000); await pg.wait_for_timeout(200)
    r=await pg.evaluate("[Llamada.motivo,CallStub.sent,CallStub.ended,document.querySelector('#llam .ls1').textContent]")
    ck(T+"7-minute stop: (fin) sent at 6 min, the call ended by the page at 7 min even with no answer (why=max)",r[0]=="max" and r[1]==["(fin)"] and r[2],r); await leftover(pg,T+"after the 7-minute stop",100); await close(pg,ctx,T+"7-minute stop")
    # clock x10, stepped by hand so that no learner goodbye comes first: the page sends (fin) at 6 call-minutes, Danny says goodbye, the call ends
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&clock=10&stub=manual"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.evaluate("CallStub.go('connect')"); await pg.evaluate("CallStub.go('danny1')"); await pg.evaluate("CallStub.go('you1')"); t0=time.time()
    await pg.wait_for_function("Llamada.estado==='done'",timeout=70000); r=await pg.evaluate("[Llamada.motivo,CallStub.sent,CallStub.ended,document.querySelector('#llam .ls1').textContent,document.querySelector('#llam .lt').textContent]")
    ck(T+"6-minute rule: (fin) sent once at 6 call-minutes (%.0f s real at clock 10), the call ends when Danny has said goodbye (why=fin, before 7 min)"%(time.time()-t0),r[0]=="fin" and r[1]==["(fin)"] and r[2],r); await leftover(pg,T+"after the 6-minute rule",100); await close(pg,ctx,T+"6-minute rule")
    # no goodbye: the 15 s cap
    pg,ctx=await newpage(b,390,844,CASA,"&callstub=1&clock=6&stub=nofin"); await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); t0=time.time(); await pg.wait_for_function("Llamada.estado==='done'",timeout=70000); dt=time.time()-t0; r=await pg.evaluate("[Llamada.motivo,CallStub.sent,CallStub.ended]")
    ck(T+"no answer to (fin): the page ends the call 15 s later (why=cap, %.0f s in all)"%dt,r[0]=="cap" and r[1]==["(fin)"] and r[2],r); await leftover(pg,T+"after the cap",100); await close(pg,ctx,T+"15 s cap")
    # the page without the stub: the library cannot load here (no network to the CDN); the tap must give the plain line, never a crash. If it did load, the tap is not made (it would place a real call).
    pg,ctx=await newpage(b,390,844,CASA,""); await pg.wait_for_timeout(4000); r=await pg.evaluate("({el:typeof window.ELConv,err:window.ELConvError||null,stub:typeof window.CallStub,card:!!document.querySelector('#t-hablar .card.cc:not(.lk) .pb')})")
    ck(T+"without ?callstub=1: no stub, the card is open, the voice library %s"%("loaded" if r["el"]!="undefined" else "could not load here (no network to the CDN)"),r["stub"]=="undefined" and r["card"],r)
    if r["el"]=="undefined":
        await pg.click("#t-hablar .card.cc >> nth=0"); await pg.click("#llam .ldisc"); await pg.wait_for_function("document.getElementById('llam').dataset.s==='err'",timeout=15000)
        ck(T+"without the library: the tap gives 'The voice part did not load. Check your connection and try again.', the X closes, the lock is free",await pg.evaluate("document.querySelector('#llam .lerr').textContent")=="The voice part did not load. Check your connection and try again." and not await pg.evaluate("Llamada.ocupado")); await pg.click("#llam .lx")
    pg.errs=[e for e in pg.errs if "ERR_TUNNEL_CONNECTION_FAILED" not in e]   # the sandbox's proxy refusing the CDN: not the page
    await close(pg,ctx,T+"no stub")
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
        for label,vw,vh in [("390x844",390,844),("360x640",360,640),("844x390",844,390)]: print("=== "+label); await view(b,label,vw,vh)
        print("=== extras"); await extras(b); await b.close()
    print("page errors (all runs, the vibrate line aside):",ERRS); print("FAILED: %d %s"%(len(FAILS),FAILS))
asyncio.run(main())
