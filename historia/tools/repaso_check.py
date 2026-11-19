"""Checks the Repaso session (historia/cual.html, cual.js) by machine; spec: docs/proyecto/10-leer-y-repaso.md, "Repaso (¿Cuál?): the session".
Needs a local server on the repo root: COQUI_BASE=http://127.0.0.1:8768 python3 historia/tools/repaso_check.py [only-test-name ...]
It seeds word records into localStorage (due or not by the palabras clock, window.__PAL_NOW) and plays sessions by touching the options (Cual.toca).
Prints PASS/FAIL per point and exits 1 if any failed. Tests: cap, order, six, early, reask, end, clock, switches."""
import sys,os,json,asyncio,glob,re,time
from playwright.async_api import async_playwright
BASE=os.environ.get("COQUI_BASE","http://127.0.0.1:8765"); DAY=864e5
HERE=os.path.dirname(os.path.abspath(__file__)); CUENTOS=os.path.join(HERE,"..","cuentos")
RES=[]
def ok(name,cond,detail=""):
    RES.append((name,bool(cond))); print(("PASS " if cond else "FAIL ")+name+(("  "+str(detail)) if detail!="" else ""),flush=True)
# the words that have a picture pair, in file order
def pair_words():
    out=[]
    for f in sorted(glob.glob(os.path.join(CUENTOS,"cual-*.json"))):
        for it in json.load(open(f))["items"]:
            if it["w"] not in out: out.append(it["w"])
    return out
WORDS=pair_words()
def skill(): return dict(etapa=0,paso=1,seguidas=0,fallos=0,gap=0,due=0,aciertos=[],ultima=0,aparcada=0,marca=0,n=0,bien=0)
def rec(w,due,etapa=1,gap=1):
    e=skill(); e.update(etapa=etapa,gap=gap,due=due)
    return {"w":w,"primera":due-DAY,"oida":1,"ear":e,"mouth":skill()}
def seed(recs,now=None,count=False):
    """init script: the records (and a fixed palabras clock), a counter of the sentences started (AudioBufferSourceNode.start)"""
    db={"palabras":{r["w"]:r for r in recs},"dias":{},"cuentos":{},"ajustes":{"min":30,"todo":0,"bienvenida":0,"habla":1},"minutos":0,"v":1}
    js="try{if(!localStorage.getItem('coqui.palabras.v1'))localStorage.setItem('coqui.palabras.v1',%s);}catch(e){}"%json.dumps(json.dumps(db))
    if now is not None: js+="window.__PAL_NOW=%d;"%now
    js+="window.__starts=0;try{const o=AudioBufferSourceNode.prototype.start;AudioBufferSourceNode.prototype.start=function(){window.__starts++;return o.apply(this,arguments);};}catch(e){}"
    return js
async def newpage(b,init,vp=(390,844),dpr=2,mobile=True):
    ctx=await b.new_context(viewport={"width":vp[0],"height":vp[1]},device_scale_factor=dpr,is_mobile=mobile,has_touch=mobile)
    await ctx.add_init_script(init); pg=await ctx.new_page(); pg.errs=[]
    pg.on("pageerror",lambda e: pg.errs.append(str(e))); return pg
async def open_(pg,q):
    await pg.goto(BASE+"/historia/cual.html?"+q); await pg.wait_for_function("typeof Cual!=='undefined'&&Cual.lista!==undefined&&document.querySelector('#fin h1')"); await pg.wait_for_timeout(1200)
async def start(pg): await pg.click("#go")
async def rec_of(pg,w): return await pg.evaluate("w=>JSON.parse(JSON.stringify(PAL.db.palabras[w]||null))",w)
async def drive(pg,plan="",every=None,limit=300,after=None):
    """plays the session: plan[k] = 'r' right, 'w' wrong, 'n' no touch (waits for the auto-show) for the k-th ask in the queue (the second asks too); every(pg,k,st) is called when ask k is ready; the rest right.
    returns the list of the asks seen: {k, w, re, rec before}"""
    seen=[]; last=-1; t0=time.time(); n=0
    while time.time()-t0<limit:   # limit in seconds
        n+=1; await pg.wait_for_timeout(40)
        st=await pg.evaluate("({pan:Cual.pan,i:Cual.i,listo:Cual.listo,run:Cual.running,cola:Cual.cola})")
        if st["pan"] and st["listo"] and st["i"]!=last:
            k=st["i"]; last=k; item=st["cola"][k]; before=await rec_of(pg,item["w"])
            seen.append({"k":k,"w":item["w"],"re":item["re"],"before":before,"right":[j for j,x in enumerate(st["pan"]) if x["right"]][0],"cola":st["cola"]})
            if every: await every(pg,k,st)
            want=plan[k] if k<len(plan) else "r"; right=seen[-1]["right"]
            if want=="n":   # no touch: the sentence plays again, then the right picture shows by itself
                await pg.wait_for_function("Cual.pan&&Cual.pan.some(p=>p.sign)",timeout=60000)
                await pg.evaluate("Cual.toca(%d)"%right)
            else:
                await pg.evaluate("Cual.toca(%d)"%(right if want=="r" else 1-right))
                if want=="w":
                    await pg.wait_for_function("Cual.pan&&Cual.pan.some(p=>p.sign)",timeout=20000)
                    await pg.evaluate("Cual.toca(%d)"%right)
        if not st["run"] and last>=0 and n>25:
            if await pg.evaluate("!!Cual.fin"): break
    if after: await after(pg,seen)
    return seen
def due_recs(n,now,spread=1.0):
    """n words due before now, the first ones the most overdue (but written in a shuffled order so the order has to come from the due times)"""
    ws=WORDS[:n]; recs=[rec(w,now-(n-i)*spread*3600e3) for i,w in enumerate(ws)]
    recs=recs[::2]+recs[1::2]; return ws,recs
async def text_of(pg,sel): return await pg.evaluate("s=>document.querySelector(s)?document.querySelector(s).innerText:''",sel)

# ---------------------------------------------------------------- 1. the cap of 10, due first, most overdue first, the start line
async def t_cap(b):
    NOW=int(1.9e12)
    ws,recs=due_recs(14,NOW)
    pg=await newpage(b,seed(recs,NOW)); await open_(pg,"fast=4")
    lista=await pg.evaluate("Cual.lista"); line=await text_of(pg,"#fin p"); title=await text_of(pg,"#fin h1")
    ok("cap: 14 due, the session asks 10",len(lista)==10,len(lista))
    ok("cap: the 10 most overdue, most overdue first",lista==ws[:10],lista)
    ok("cap: the start line is for this session only: 10 words · about 2 min",line=="10 words · about 2 min",repr(line))
    ok("cap: the start screen keeps its title",title=="Review",title)
    ok("cap: the progress bar has 10 segments",await pg.evaluate("document.querySelectorAll('#bar .dot').length")==10)
    await start(pg); seen=await drive(pg)
    ok("cap: all 10 asked, once each, none of the 4 waiting",[s["w"] for s in seen]==ws[:10],[s["w"] for s in seen])
    waiting=[await rec_of(pg,w) for w in ws[10:]]
    ok("cap: the 4 that wait are untouched",all(r["ear"]["n"]==0 and r["ear"]["due"]<NOW for r in waiting))
    done=[await rec_of(pg,w) for w in ws[:10]]
    ok("cap: the 10 asked were scored (one right answer each, due moved on)",all(len(r["ear"]["aciertos"])==1 and r["ear"]["due"]>NOW for r in done))
    ok("cap: no page errors",not pg.errs,pg.errs[:2]); await pg.context.close()
    # fewer due than 10: only those; the line counts them
    ws,recs=due_recs(3,NOW); pg=await newpage(b,seed(recs,NOW)); await open_(pg,"fast=4")
    ok("cap: 3 due, 3 asked, 3 words · about 1 min",await pg.evaluate("Cual.lista")==ws and await text_of(pg,"#fin p")=="3 words · about 1 min",await text_of(pg,"#fin p")); await pg.context.close()
    # the order comes from the due times: reverse them
    ws=WORDS[:12]; recs=[rec(w,NOW-(i+1)*3600e3) for i,w in enumerate(ws)]   # the first is the least overdue
    pg=await newpage(b,seed(recs,NOW)); await open_(pg,"fast=4")
    ok("order: most overdue first, whatever the order of the words",await pg.evaluate("Cual.lista")==ws[::-1][:10],await pg.evaluate("Cual.lista")); await pg.context.close()

# ---------------------------------------------------------------- 2. the 6 s rule at real speed: 6 s, it plays again; 6 s more, the right picture shows (a miss); he touches it
async def t_six(b):
    NOW=int(1.9e12)
    async def one(tag,wait_first):
        pg=await newpage(b,seed([rec("casa",NOW-3600e3)],NOW)); await open_(pg,"solo=casa&txt=no&n=1")   # fast=1: real seconds
        await start(pg); await pg.wait_for_function("Cual.pan&&Cual.listo",timeout=30000)
        n0=await pg.evaluate("window.__starts"); return pg,n0
    # a) no touch at all
    pg,n0=await one("a",0)
    cap=await pg.evaluate("Story.cap")
    ok("six: ?txt=no keeps the sentence text off the screen",await pg.evaluate("Story.txt")=="no" and cap=="",repr(cap))
    t0=await pg.evaluate("performance.now()")
    await pg.wait_for_timeout(5000); mid=await pg.evaluate("({s:window.__starts,pan:Cual.pan,ring:[...document.querySelectorAll('.opt')].map(o=>o.className)})")
    ok("six: 5 s of silence: the sentence has not played again, no ring",mid["s"]==n0 and not any(p["sign"] for p in mid["pan"]) and not any("ok" in r for r in mid["ring"]),mid)
    await pg.wait_for_function("Cual.tt.length&&Cual.tt[0].rep",timeout=10000); await pg.wait_for_timeout(300)
    tt=await pg.evaluate("Cual.tt[0]"); gap1=(tt["rep"]-tt["fin"])/1000
    ok("six: 6 s after the sentence ended it played again (%.2f s)"%gap1,5.9<=gap1<=6.5,gap1)
    ok("six: the sentence was started again (audio)",await pg.evaluate("window.__starts")==n0+1 if await pg.evaluate("Story.voice") else True,await pg.evaluate("[window.__starts,Story.voice]"))
    during=await pg.evaluate("Cual.pan"); ok("six: while it plays again no picture is shown yet",not any(p["sign"] for p in during))
    await pg.wait_for_function("Cual.tt[0].auto",timeout=20000); await pg.wait_for_timeout(100)
    tt=await pg.evaluate("Cual.tt[0]"); gap2=(tt["auto"]-tt["repFin"])/1000
    ok("six: 6 s after it ended again the right picture was shown (%.2f s)"%gap2,5.9<=gap2<=6.5,gap2)
    st=await pg.evaluate("({pan:Cual.pan,rings:[...document.querySelectorAll('.opt')].map(o=>o.className),hecho:Cual.hecho,rec:PAL.db.palabras.casa.ear})")
    r=[j for j,x in enumerate(st["pan"]) if x["right"]][0]
    ok("six: the right picture has the green ring and the sign, the other none",st["pan"][r]["sign"]==1 and st["pan"][1-r]["sign"]==0 and "ok" in st["rings"][r] and "ok" not in st["rings"][1-r] and "bad" not in " ".join(st["rings"]),st)
    ok("six: it counts as a miss: recorded wrong, one fall, due in about 10 min",st["hecho"]==[{"w":"casa","ok":False,"ms":st["hecho"][0]["ms"],"auto":1}] and st["rec"]["fallos"]==1 and abs(st["rec"]["due"]-(NOW+10*6e4))<5e3 and len(st["rec"]["aciertos"])==0,[st["hecho"],st["rec"]["fallos"],st["rec"]["due"]-NOW])
    await pg.wait_for_timeout(2500); still=await pg.evaluate("Cual.pan&&Cual.pan.some(p=>p.sign)")
    ok("six: he has to touch it: nothing moves on while he waits",still is True and await pg.evaluate("Cual.i")==0)
    await pg.evaluate("Cual.toca(%d)"%(1-r)); await pg.wait_for_timeout(300)
    ok("six: touching the other one does nothing",await pg.evaluate("Cual.pan&&Cual.pan.some(p=>p.sign)") is True)
    await pg.evaluate("Cual.toca(%d)"%r)
    await pg.wait_for_function("Cual.cola.length===2&&Cual.i===1&&Cual.listo",timeout=20000)
    ok("six: after the shown touch the word comes back once (the end of a one-word session)",await pg.evaluate("Cual.cola")==[{"w":"casa","re":False},{"w":"casa","re":True}],await pg.evaluate("Cual.cola"))
    ok("six: no page errors",not pg.errs,pg.errs[:2]); await pg.context.close()
    # b) a touch after 7 s (the sentence has played again): it counts, no auto-show
    pg,n0=await one("b",0); await pg.wait_for_function("Cual.tt.length&&Cual.tt[0].rep",timeout=12000)
    right=await pg.evaluate("Cual.pan.findIndex(p=>p.right)"); await pg.evaluate("Cual.toca(%d)"%right); await pg.wait_for_timeout(1500)
    h=await pg.evaluate("[Cual.hecho,Cual.tt[0]]")
    ok("six: a touch while/after it plays again counts as an answer (right, no auto)",len(h[0])==1 and h[0][0]["ok"] is True and "auto" not in h[0][0] and "auto" not in h[1],h)
    ok("six: ...and its time is from the end of the first sentence (>= 6 s)",h[0][0]["ms"]>=6000,h[0][0]["ms"])
    ok("six: no page errors",not pg.errs,pg.errs[:2]); await pg.context.close()
    # c) a touch at 3 s: no replay at all
    pg,n0=await one("c",0); await pg.wait_for_timeout(3000)
    right=await pg.evaluate("Cual.pan.findIndex(p=>p.right)"); await pg.evaluate("Cual.toca(%d)"%(1-right)); await pg.wait_for_timeout(1200)
    tt=await pg.evaluate("Cual.tt[0]")
    ok("six: a touch before 6 s: no replay, a wrong touch is a plain miss (not auto)",("rep" not in tt) and "auto" not in tt and (await pg.evaluate("Cual.hecho"))[0]["ok"] is False and "auto" not in (await pg.evaluate("Cual.hecho"))[0],tt)
    await pg.context.close()

# ---------------------------------------------------------------- 3. a touch before the sentence ends does not count; the answer records are what they were
async def t_early(b):
    NOW=int(1.9e12); pg=await newpage(b,seed([rec("casa",NOW-3600e3),rec("puerta",NOW-1800e3)],NOW)); await open_(pg,"fast=2")
    await start(pg); await pg.wait_for_function("Cual.pan",timeout=20000)
    for _ in range(8): await pg.evaluate("Cual.toca(0);Cual.toca(1)"); await pg.wait_for_timeout(40)
    early=await pg.evaluate("[Cual.hecho.length,Cual.listo]")
    ok("early: touches before the sentence ends are ignored",early[0]==0 and early[1] is False,early)
    await pg.wait_for_function("Cual.listo",timeout=20000); right=await pg.evaluate("Cual.pan.findIndex(p=>p.right)"); await pg.evaluate("Cual.toca(%d)"%right); await pg.wait_for_timeout(200)
    h=await pg.evaluate("Cual.hecho"); r=await rec_of(pg,h[0]["w"]) if h else None
    ok("early: the touch after it counts and goes into the word's ear record (PAL.responde)",len(h)==1 and h[0]["ok"] is True and r["ear"]["n"]==1 and r["ear"]["bien"]==1 and len(r["ear"]["aciertos"])==1,[h,r and r["ear"]["n"]])
    ok("early: no page errors",not pg.errs,pg.errs[:2]); await pg.context.close()

# ---------------------------------------------------------------- 4. a miss comes back once, three items later (the end if fewer are left), unscored, writing nothing
async def t_reask(b):
    NOW=int(1.9e12); ws,recs=due_recs(7,NOW); snaps={}
    pg=await newpage(b,seed(recs,NOW)); await open_(pg,"fast=4"); await start(pg)
    # asks in the queue order: a (miss) b c [a again] d e f (miss, the end) g [f again, wrong]
    seen=await drive(pg,plan="wrrrrrwrw",limit=300)   # by ask: 0 a wrong, 1 b, 2 c, 3 a* right, 4 d, 5 e, 6 f wrong, 7 g, 8 f* wrong
    cola=[(s["w"],s["re"]) for s in seen]
    a,bw,c,d,e,f,g=ws
    want=[(a,False),(bw,False),(c,False),(a,True),(d,False),(e,False),(f,False),(g,False),(f,True)]
    ok("reask: the queue is a b c a* d e f g f* (a back three items later, f, the sixth of seven, at the end)",cola==want,cola)
    ok("reask: a missed word comes back once only (f* wrong: no third ask)",len(seen)==9 and [x for x in cola].count((f,True))==1,len(seen))
    hecho=await pg.evaluate("Cual.hecho"); reh=await pg.evaluate("Cual.rehecho")
    ok("reask: the scored answers are the 7 words only (a wrong, f wrong, the rest right)",[(h["w"],h["ok"]) for h in hecho]==[(a,False),(bw,True),(c,True),(d,True),(e,True),(f,False),(g,True)],hecho)
    ok("reask: the second asks are kept apart: a* right, f* wrong",[(h["w"],h["ok"]) for h in reh]==[(a,True),(f,False)],reh)
    # records: what a word's record was just before its second ask equals what it is after it
    by_k={s["k"]:s for s in seen}
    ra_before=by_k[3]["before"]; rf_before=by_k[8]["before"]
    ra_after=await rec_of(pg,a); rf_after=await rec_of(pg,f)
    ok("reask: a's record is the same before and after its second ask (unscored: nothing written)",ra_before==ra_after,[ra_before["ear"]["n"],ra_after["ear"]["n"]])
    ok("reask: f's record is the same before and after its (wrong) second ask",rf_before==rf_after,[rf_before["ear"]["n"],rf_after["ear"]["n"]])
    ok("reask: the miss itself was scored once: a n=1, one fall, due in 10 min; f the same",ra_after["ear"]["n"]==1 and ra_after["ear"]["fallos"]==1 and rf_after["ear"]["n"]==1 and rf_after["ear"]["fallos"]==1 and abs(ra_after["ear"]["due"]-(NOW+10*6e4))<6e4,[ra_after["ear"],])
    rr=[await rec_of(pg,w) for w in (bw,c,d,e,g)]
    ok("reask: the right ones were scored once (n=1, one right)",all(r["ear"]["n"]==1 and len(r["ear"]["aciertos"])==1 for r in rr))
    ok("reask: the bar grew with the two second asks (9 segments, all lit at the end)",await pg.evaluate("[document.querySelectorAll('#bar .dot').length,document.querySelectorAll('#bar .dot.on').length]")==[9,9],await pg.evaluate("[document.querySelectorAll('#bar .dot').length,document.querySelectorAll('#bar .dot.on').length]"))
    ok("reask: no page errors",not pg.errs,pg.errs[:2]); await pg.context.close()

async def t_reask_order(b):   # the second ask draws the two pictures afresh: over 10 misses it is neither always the same position nor always the other (chance of a false alarm 2 in 1024)
    NOW=int(1.9e12); ws,recs=due_recs(10,NOW); pg=await newpage(b,seed(recs,NOW)); await open_(pg,"fast=4&n=10"); await start(pg)
    seen=await drive(pg,plan="w"*20,limit=400)   # every ask wrong, the second ones too
    first={s["w"]:s["right"] for s in seen if not s["re"]}; second={s["w"]:s["right"] for s in seen if s["re"]}
    same=sum(1 for w in second if second[w]==first[w])
    ok("reask: 10 missed words came back, each once",len(second)==10 and len(seen)==20,len(seen))
    ok("reask: the second ask's pictures are drawn afresh (same place in %d of 10, not 0 and not 10)"%same,0<same<10,same)
    await pg.context.close()

# ---------------------------------------------------------------- 5. the end screen
async def t_end(b):
    NOW=int(1.9e12); ws,recs=due_recs(9,NOW); results={}
    async def go(vp,dpr,mobile,plan,tag,shot=None):
        pg=await newpage(b,seed(recs,NOW),vp,dpr,mobile); await open_(pg,"fast=4"); await start(pg)
        await drive(pg,plan,limit=300)
        await pg.wait_for_selector("#fin.lis h2",timeout=20000); await pg.wait_for_timeout(300)
        info=await pg.evaluate("""()=>{const f=document.querySelector('#fin'),dpr=devicePixelRatio,cs=e=>getComputedStyle(e),rgb=c=>c.match(/[\\d.]+/g).slice(0,3).map(Number),L=c=>{const v=rgb(c).map(x=>{x/=255;return x<=.03928?x/12.92:Math.pow((x+.055)/1.055,2.4)});return .2126*v[0]+.7152*v[1]+.0722*v[2]},cr=(a,b)=>{const x=L(a),y=L(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05)},bg=cs(document.body).backgroundColor;
          const groups=[...f.querySelectorAll('h2')].map(h=>({h:h.textContent,words:[...h.nextElementSibling.querySelectorAll('li span')].map(s=>s.textContent),pics:[...h.nextElementSibling.querySelectorAll('li canvas')].map(c=>{const r=c.getBoundingClientRect(),x=c.getContext('2d'),d=x.getImageData(0,0,c.width,c.height).data,seen=new Set();for(let i=0;i<d.length;i+=4*97)seen.add(d[i]+','+d[i+1]+','+d[i+2]);return {w:r.width,h:r.height,dpr,kd:r.width*dpr/196,colours:seen.size,cw:c.width,ch:c.height}})}));
          const btn=document.querySelector('#next'),bb=btn.getBoundingClientRect(),fb=f.getBoundingClientRect(),h1=f.querySelector('h1'),h2=f.querySelector('h2'),sp=f.querySelector('li span');
          return {text:f.innerText,h1:h1&&h1.textContent,groups,btn:{t:btn.textContent,h:bb.height,top:bb.top,w:bb.width,vis:bb.height>0},fin:{bottom:fb.bottom,sw:f.scrollWidth,cw:f.clientWidth,sh:f.scrollHeight,ch:f.clientHeight},
            sizes:{h1:cs(h1).fontSize,h2:cs(h2).fontSize,span:cs(sp).fontSize,btn:cs(btn).fontSize},contrast:{h1:cr(cs(h1).color,bg),h2:cr(cs(h2).color,bg),span:cr(cs(sp).color,bg),btn:cr(cs(btn).color,cs(btn).backgroundColor)},cols:cs(f.querySelector('.gw')).gridTemplateColumns.split(' ').length,
            fin_state:window.Cual.fin,dots:[document.querySelectorAll('#bar .dot').length,document.querySelectorAll('#bar .dot.on').length]}}""")
        if shot: await pg.screenshot(path=shot)
        info["pg"]=pg; return info
    info=await go((390,844),2,True,"wrrrw","portrait")   # by ask: 0 wrong, 4 wrong (two scored misses), the rest right
    hec=await info["pg"].evaluate("Cual.hecho"); up=[h["w"] for h in hec if h["ok"]]; soon=[h["w"] for h in hec if not h["ok"]]
    gs={g["h"]:g for g in info["groups"]}
    ok("end: two groups, Moving up then Coming back soon",[g["h"] for g in info["groups"]]==["Moving up","Coming back soon"],[g["h"] for g in info["groups"]])
    ok("end: Moving up holds the words right on the scored ask, in session order",gs["Moving up"]["words"]==up,[gs["Moving up"]["words"],up])
    ok("end: Coming back soon holds the missed ones (%d)"%len(soon),gs["Coming back soon"]["words"]==soon and len(soon)>=1,[gs["Coming back soon"]["words"],soon])
    ok("end: every word of the session is there once (9)",sorted(gs["Moving up"]["words"]+gs["Coming back soon"]["words"])==sorted(ws) and info["fin_state"]=={"up":up,"soon":soon},info["fin_state"])
    ok("end: a missed word that is right on its second ask is still under Coming back soon",all(w in gs["Coming back soon"]["words"] for w in soon))
    pics=[p for g in info["groups"] for p in g["pics"]]
    ok("end: each word has its picture (a 196 x 104 canvas with more than one colour)",len(pics)==9 and all(p["cw"]==196 and p["ch"]==104 and p["colours"]>3 for p in pics),[(p["cw"],p["ch"],p["colours"]) for p in pics][:3])
    ok("end: pictures are scaled by a whole number of screen pixels (kd=%s)"%pics[0]["kd"],all(abs(p["kd"]-round(p["kd"]))<.005 and p["kd"]>=1 for p in pics),[p["kd"] for p in pics])
    ok("end: no score number on the screen",not re.search(r"\d",info["text"]),info["text"].replace("\n"," | "))
    ok("end: the title is Done, the button says Back to Palabras and is 48 px or more high",info["h1"]=="Done" and info["btn"]["t"]=="Back to Palabras" and info["btn"]["h"]>=48,[info["h1"],info["btn"]])
    ok("end: sizes: title 24, group headings 18, words 16, button 16",[info["sizes"][k] for k in ("h1","h2","span","btn")]==["24px","18px","16px","16px"],info["sizes"])
    ok("end: contrast of the title, headings, words and button text is at least 4.5",all(v>=4.5 for v in info["contrast"].values()),info["contrast"])
    ok("end: nothing runs sideways; the list ends above the button",info["fin"]["sw"]<=info["fin"]["cw"] and info["fin"]["bottom"]<=info["btn"]["top"]+1,[info["fin"],info["btn"]["top"]])
    ok("end: the progress bar is full",info["dots"][0]==info["dots"][1]==9+len(soon),info["dots"])
    # the button leads back to Palabras
    pgx=info["pg"]; await pgx.click("#next"); await pgx.wait_for_timeout(600); ok("end: Back to Palabras goes to app.html?tab=palabras","app.html?tab=palabras" in pgx.url,pgx.url)
    ok("end: no page errors",not pgx.errs,pgx.errs[:2]); await pgx.context.close()
    # a session with only right answers has one group; all wrong has one group
    info=await go((390,844),2,True,"","allright"); ok("end: all right: only Moving up",[g["h"] for g in info["groups"]]==["Moving up"] and len(info["groups"][0]["words"])==9,[g["h"] for g in info["groups"]]); await info["pg"].context.close()
    # other screens: no sideways run, the pictures stay on whole scales, the button is reachable
    for vp,dpr,mob,tag in (((360,640),3,True,"small phone 360x640 @3x"),((844,390),2,True,"landscape 844x390 @2x"),((393,852),3,True,"393x852 @3x")):
        info=await go(vp,dpr,mob,"wrwrrwrr",tag)
        pics=[p for g in info["groups"] for p in g["pics"]]
        ok("end: %s: whole-number scale %.2f, %d columns, no sideways run, button %dx%d in view"%(tag,round(pics[0]["kd"]),info["cols"],info["btn"]["w"],info["btn"]["h"]),all(abs(p["kd"]-round(p["kd"]))<.005 for p in pics) and info["fin"]["sw"]<=info["fin"]["cw"] and info["btn"]["h"]>=48 and info["btn"]["top"]+info["btn"]["h"]<=vp[1]+1,[info["fin"],info["btn"]])
        await info["pg"].context.close()

# ---------------------------------------------------------------- 6. the clock: the due check uses the palabras clock (window.__PAL_NOW), not Date.now()
async def t_clock(b):
    real=await b.new_context(); pgr=await real.new_page(); await pgr.goto("about:blank"); realnow=await pgr.evaluate("Date.now()"); await real.close()
    # a) the palabras clock is far ahead: records due a day before it are due by it (but not yet by Date.now())
    NOW=int(realnow+60*DAY); ws,recs=due_recs(4,NOW)
    pg=await newpage(b,seed(recs,NOW)); await open_(pg,"fast=2"); await start(pg); seen=await drive(pg,"rrrr")
    rs=[await rec_of(pg,w) for w in ws]
    ok("clock: the palabras clock is ahead of Date.now(): the due words are asked as due (list = the due words, most overdue first)",[s["w"] for s in seen]==ws,[s["w"] for s in seen])
    ok("clock: ...and their right answers are scored by that clock (schedule moved from NOW, 2.5 days)",all(len(r["ear"]["aciertos"])==1 and abs(r["ear"]["due"]-(NOW+2.5*DAY))<60e3 for r in rs),[(len(r["ear"]["aciertos"]),round((r["ear"]["due"]-NOW)/DAY,2)) for r in rs])
    ok("clock: no page errors",not pg.errs,pg.errs[:2]); await pg.context.close()
    # b) the palabras clock is behind: records due after it are not due by it, though Date.now() is past them: practice, nothing scored
    NOW=int(realnow-60*DAY); ws=WORDS[:4]; recs=[rec(w,NOW+DAY*(i+1)) for i,w in enumerate(ws)]
    pg=await newpage(b,seed(recs,NOW)); await open_(pg,"fast=4&solo="+",".join(ws)); await start(pg); seen=await drive(pg,"rrww")
    rs=[await rec_of(pg,w) for w in ws]
    ok("clock: the palabras clock is behind Date.now(): the same words are not due, so the answers are not scored (no schedule moved, no fall)",all(len(r["ear"]["aciertos"])==0 and r["ear"]["fallos"]==0 and r["ear"]["due"]==NOW+DAY*(i+1) for i,r in enumerate(rs)),[(len(r["ear"]["aciertos"]),r["ear"]["fallos"],round((r["ear"]["due"]-NOW)/DAY,2)) for r in rs])
    ok("clock: ...yet each answer is still counted (n=1 each)",all(r["ear"]["n"]==1 for r in rs),[r["ear"]["n"] for r in rs])
    ok("clock: no page errors",not pg.errs,pg.errs[:2]); await pg.context.close()

# ---------------------------------------------------------------- 7. the test switches and nothing else moved
async def t_switches(b):
    NOW=int(1.9e12); ws,recs=due_recs(12,NOW)
    pg=await newpage(b,seed(recs,NOW)); await open_(pg,"fast=4&n=4"); ok("switches: ?n=4 asks 4 (of 12 due)",await pg.evaluate("Cual.lista")==ws[:4],await pg.evaluate("Cual.lista")); await pg.context.close()
    pg=await newpage(b,seed(recs,NOW)); await open_(pg,"fast=4&solo=casa,puerta"); ok("switches: ?solo= asks just those words",sorted(await pg.evaluate("Cual.lista"))==["casa","puerta"],await pg.evaluate("Cual.lista")); await pg.context.close()
    pg=await newpage(b,seed([],NOW)); await open_(pg,"fast=4&todo=1&n=200"); ok("switches: ?todo=1&n=200 lists every pair (%d)"%len(WORDS),len(await pg.evaluate("Cual.lista"))==len(WORDS),len(await pg.evaluate("Cual.lista"))); await pg.context.close()
    pg=await newpage(b,seed([],NOW)); await open_(pg,"fast=4"); ok("switches: nothing heard and nothing due: a practice list of up to 10 (%d)"%len(await pg.evaluate("Cual.lista")),len(await pg.evaluate("Cual.lista"))==10); await pg.context.close()
    pg=await newpage(b,seed(recs,NOW)); await open_(pg,"fast=3&txt=no&solo=casa"); await start(pg); caps=[]
    for _ in range(40): caps.append(await pg.evaluate("Story.cap+'|'+Story.bub")); await pg.wait_for_timeout(60)
    ok("switches: ?txt=no shows no sentence text during the session",all(c=="|" for c in caps),set(caps))
    ok("switches: no page errors",not pg.errs,pg.errs[:2]); await pg.context.close()

TESTS={"cap":t_cap,"six":t_six,"early":t_early,"reask":t_reask,"reask_order":t_reask_order,"end":t_end,"clock":t_clock,"switches":t_switches}
async def main():
    names=sys.argv[1:] or list(TESTS)
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
        for n in names: await TESTS[n](b)   # one after another: sessions run in real time (the voice), and a loaded machine slows them
        await b.close()
    bad=[n for n,c in RES if not c]; print("\n%d checks, %d passed, %d failed"%(len(RES),len(RES)-len(bad),len(bad)))
    for n in bad: print("  FAILED:",n)
    sys.exit(1 if bad else 0)
if __name__=="__main__": asyncio.run(main())   # imported (as repaso_frames.py does) it only gives its helpers
