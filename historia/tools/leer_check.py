# Checks the shelf, the book and Palabras of app.html by machine (page 10): python3 historia/tools/leer_check.py [--frames DIR]
# It serves the repository on port 8769 itself (if nothing answers there) and needs playwright with /usr/bin/google-chrome.
# Books: historia/libros/<id>.json are used when they exist; a book that is not there yet is faked for the check (a plain picture and the story's own "leer" list, three lines to a page) so the reader can be tested before the tool has made them.
# Prints one line per check (ok / FAIL) and exits 1 if any failed. With --frames DIR it also writes numbered phone-size frames (390x844 at 2x) into DIR.
import asyncio,io,json,re,subprocess,sys,time,unicodedata,urllib.request
from pathlib import Path
from playwright.async_api import async_playwright
ROOT=Path(__file__).resolve().parents[2]
PORT=8769;BASE="http://127.0.0.1:%d/historia/app.html"%PORT
FRAMES=None
if "--frames" in sys.argv: FRAMES=Path(sys.argv[sys.argv.index("--frames")+1]);FRAMES.mkdir(parents=True,exist_ok=True)
FAILS=[];N=[0]
def check(name,cond,extra=""):
    N[0]+=1
    if cond: print("ok   ",name,extra)
    else: print("FAIL ",name,extra);FAILS.append(name)
def norm(s): return " "+re.sub(r"[^a-z0-9]+"," ",unicodedata.normalize("NFD",s.lower()).encode("ascii","ignore").decode()).strip()+" "
def server():
    try: urllib.request.urlopen(BASE,timeout=2);return None
    except Exception: pass
    p=subprocess.Popen([sys.executable,"-m","http.server",str(PORT),"--bind","127.0.0.1"],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    for _ in range(50):
        try: urllib.request.urlopen(BASE,timeout=1);break
        except Exception: time.sleep(.1)
    return p
# ---- a book that does not exist yet, faked
def fake_book(sid):
    f=ROOT/"historia/cuentos"/(sid+".json")
    if not f.exists(): return None
    T=json.load(open(f));ids=[i for i in (T.get("leer") or list(T["clips"])) if i in T["clips"]]
    return {"id":sid,"title":T["title"],"pages":[{"img":"img/%s-%d.png"%(sid,n+1),"clips":ids[k:k+3]} for n,k in enumerate(range(0,len(ids),3))]}
def fake_png(n):
    from PIL import Image,ImageDraw
    im=Image.new("RGB",(196,216),(40+n*37%150,120,200-n*23%120));d=ImageDraw.Draw(im)
    for i in range(0,196,14): d.rectangle([i,150,i+7,215],fill=(60,160,70))
    d.text((90,70),str(n),fill=(255,255,255));b=io.BytesIO();im.save(b,"PNG");return b.getvalue()
FAKED=set()
async def libros_route(route):
    u=route.request.url.split("/historia/libros/")[1].split("?")[0]
    if (ROOT/"historia/libros"/u).exists(): await route.continue_();return
    if u.endswith(".json"):
        b=fake_book(u[:-5])
        if b is None: await route.fulfill(status=404,body="");return
        FAKED.add(u);await route.fulfill(status=200,content_type="application/json",body=json.dumps(b))
    else: await route.fulfill(status=200,content_type="image/png",body=fake_png(int(re.search(r"-(\d+)\.png",u).group(1))))
HOOK="""()=>{window.__log=[];const o=window.playClip;window.playClip=function(id){const e={id,t:performance.now(),end:null,ok:null};window.__log.push(e);const p=o.apply(this,arguments);p.then(ok=>{e.end=performance.now();e.ok=ok;});return p;};
 window.__lit=[];setInterval(()=>{const l=document.querySelector('#lbtxt .lbl.now'),id=l&&l.dataset.id;if(id&&window.__lit[window.__lit.length-1]!==id)window.__lit.push(id);},25);}"""
async def new_page(b,w=390,h=844,errs=None):
    ctx=await b.new_context(viewport={"width":w,"height":h},device_scale_factor=2,is_mobile=True,has_touch=True)
    pg=await ctx.new_page()
    pg.on("pageerror",lambda e: errs.append("pageerror:"+str(e)))
    pg.on("console",lambda m: errs.append("console:"+m.text) if m.type=="error" and "vibrate" not in m.text else None)
    await pg.route("**/historia/libros/**",libros_route)
    return ctx,pg
async def until(pg,js,ms=20000):
    t=time.time()
    while time.time()-t<ms/1000:
        try:
            if await pg.evaluate(js): return True
        except Exception: pass
        await pg.wait_for_timeout(100)
    return False
async def quiet(pg,ms=30000):   # the lines of the page are all done and nothing is playing
    return await until(pg,"()=>App.libro.lit.length===0&&speaking===0&&window.__log.length>0&&window.__log.every(e=>e.end!==null)&&!document.querySelector('#lbtxt .lbl.now')",ms)
async def swipe(cdp,x0,x1,y=420):
    await cdp.send("Input.dispatchTouchEvent",{"type":"touchStart","touchPoints":[{"x":x0,"y":y}]})
    for k in range(1,7):
        await cdp.send("Input.dispatchTouchEvent",{"type":"touchMove","touchPoints":[{"x":x0+(x1-x0)*k/6,"y":y}]})
    await cdp.send("Input.dispatchTouchEvent",{"type":"touchEnd","touchPoints":[]})
SHOT=[0]
async def shot(pg,name,full=False):
    if not FRAMES: return
    SHOT[0]+=1;fn="%02d_%s.png"%(SHOT[0],name);await pg.screenshot(path=str(FRAMES/fn),full_page=full);KEY.append((fn,name))
KEY=[]
async def main():
    srv=server();errs=[]
    try:
        async with async_playwright() as p:
            b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
            ctx,pg=await new_page(b,errs=errs);cdp=await ctx.new_cdp_session(pg)
            reqs=[];pg.on("request",lambda r: reqs.append(r.url) if "/audio/" in r.url and r.url.split("?")[0].endswith(".mp3") else None)
            await pg.goto(BASE);await until(pg,"()=>!!(window.App&&App.ready)",15000);await pg.evaluate("App.listo()");await pg.evaluate(HOOK)
            check("app ready",await pg.evaluate("!!App.ready"))
            # ------------------------------------------------------------- the shelf
            await pg.evaluate("App.ver('biblioteca')");await pg.wait_for_timeout(800)
            check("shelf empty: no rows, a plain line",await pg.evaluate("document.querySelectorAll('#t-biblioteca .bk').length")==0 and "Play a story" in await pg.inner_text("#t-biblioteca"))
            await pg.evaluate("""async()=>{for(const c of ['el-jugo','que-calor']){const T=await (await fetch('cuentos/'+c+'.json')).json();PAL.cuento(T,[]);}App.ver('biblioteca');}""")
            await until(pg,"()=>document.querySelectorAll('#t-biblioteca .bk').length>=2");await pg.wait_for_timeout(500)
            rows=await pg.evaluate("[...document.querySelectorAll('#t-biblioteca .bk')].map(r=>r.dataset.c)")
            check("shelf lists only the played stories",sorted(rows)==["el-jugo","que-calor"],str(rows))
            check("shelf: grouped under the place name",await pg.evaluate("document.querySelector('#t-biblioteca h2').textContent")=="La casa")
            r0=await pg.evaluate("""(()=>{const r=document.querySelector('.bk[data-c=\"que-calor\"]'),im=r.querySelector('.cov img'),bs=[...r.querySelectorAll('button')];
              return {title:r.querySelector('b').textContent,img:im&&im.getAttribute('src'),imgok:im&&im.complete&&im.naturalWidth>0,btn:bs.map(x=>x.textContent.trim()),h:bs.map(x=>x.getBoundingClientRect().height),on:bs.map(x=>x.getAttribute('onclick')),grey:document.querySelector('#t-biblioteca p.small.mut').textContent}})()""")
            check("shelf row: cover (first page), title, Listen and Read",r0["title"]=="¡Qué calor!" and r0["imgok"] and r0["img"].endswith("que-calor-1.png") and r0["btn"]==["Listen","Read"],str(r0["btn"]))
            check("shelf row: 48 px buttons",all(h>=48 for h in r0["h"]))
            check("shelf: Listen keeps the link (oir=1)","index.html?cuento=que-calor&oir=1&desde=app" in r0["on"][0])
            check("shelf: the grey count line",re.match(r"\d+ more open as you play the map",r0["grey"]) is not None,r0["grey"])
            await shot(pg,"shelf")
            # a finished place shows its picture stories and routines the same way, with the old link
            await pg.evaluate("""async()=>{const l=CURSO.lugares[0];for(const c of l.cuentos){const T=await (await fetch('cuentos/'+c+'.json')).json();PAL.cuento(T,[]);}App.ver('biblioteca');}""")
            await until(pg,"()=>document.querySelectorAll('#t-biblioteca .bk').length>=20");await pg.wait_for_timeout(500)
            d=await pg.evaluate("""(()=>{const r=document.querySelector('.bk[data-c=\"d-toc-toc\"]');return r?{on:r.querySelector('.btn.go').getAttribute('onclick'),n:document.querySelectorAll('#t-biblioteca .bk').length}:null})()""")
            check("shelf: picture stories and routines of a finished place, Listen without oir",d is not None and "oir=1" not in d["on"] and "cuento=d-toc-toc" in d["on"],str(d and d["n"]))
            # back to two played stories for the rest
            await pg.evaluate("""async()=>{const keep=['el-jugo','que-calor','la-lluvia'];for(const c of Object.keys(PAL.db.cuentos))if(!keep.includes(c))delete PAL.db.cuentos[c];for(const w of Object.keys(PAL.db.palabras))delete PAL.db.palabras[w];
              for(const c of keep){const T=await (await fetch('cuentos/'+c+'.json')).json();PAL.cuento(T,[]);}PAL.save();}""")
            # ------------------------------------------------------------- the book
            await pg.evaluate("App.ver('biblioteca')");await until(pg,"()=>document.querySelectorAll('#t-biblioteca .bk').length==3");await pg.wait_for_timeout(300)
            before=await pg.evaluate("JSON.stringify([PAL.db.palabras,PAL.db.dias,PAL.db.cuentos])")
            n_req=len(reqs);await pg.click('.bk[data-c="que-calor"] .btn.out')
            check("book opens full screen, tab bar hidden",await until(pg,"()=>App.libro.open&&App.libro.ids.length>0") and await pg.evaluate("getComputedStyle(document.querySelector('nav')).display")=="none" and await pg.evaluate("(()=>{const r=document.getElementById('libro').getBoundingClientRect();return r.width===innerWidth&&r.height===innerHeight})()"))
            lb=await pg.evaluate("App.libro");ids0=lb["ids"]
            check("book: up to three lines on the page",1<=len(ids0)<=3,str(ids0))
            await until(pg,"()=>App.libro.lit.length>0",15000);await shot(pg,"book_page_line_lit")
            check("page 1 plays its lines in order, each lit in turn",await quiet(pg) and [e["id"] for e in await pg.evaluate("window.__log")]==ids0 and await pg.evaluate("window.__lit")==ids0,str(ids0))
            check("page waits at its end (no auto-advance)",(await pg.evaluate("App.libro"))["i"]==0)
            got=set(re.sub(r".*/audio/|\.mp3.*","",u) for u in reqs[n_req:])
            lbk=await pg.evaluate("[App.libro.n,(()=>{const L=document.querySelectorAll('#lbtxt .lbl');return L.length})()]")
            pages=await pg.evaluate("(()=>{const o=[];return fetch('libros/que-calor.json').then(r=>r.ok?r.json():null).then(j=>j?j.pages.map(p=>p.clips):null)})()")
            if pages is None: pages=[x["clips"] for x in fake_book("que-calor")["pages"]]
            allowed=set(pages[0])|set(pages[1] if len(pages)>1 else [])
            check("audio is loaded per page (this page's clips and the next page's, not the story)",got<=allowed and len(got)>0 and len(allowed)<sum(len(x) for x in pages),"requested %d of %d clips"%(len(got),sum(len(x) for x in pages)))
            # the picture: whole-number scale, pixelated, in the viewport; the targets
            geo=await pg.evaluate("""(()=>{const im=document.getElementById('lbimg'),r=im.getBoundingClientRect(),dpr=devicePixelRatio,k=im.naturalWidth?r.width*dpr/im.naturalWidth:0,
               bt=id=>{const e=document.getElementById(id).getBoundingClientRect();return [e.width,e.height]};
               return {k,kh:im.naturalHeight?r.height*dpr/im.naturalHeight:0,rr:getComputedStyle(im).imageRendering,inview:r.left>=0&&r.right<=innerWidth&&r.top>=0&&r.bottom<=innerHeight,x:bt('lbx'),aa:bt('lbaa'),nx:bt('lbnext'),bk:bt('lbback'),
               ln:[...document.querySelectorAll('#lbtxt .lbl')].map(l=>l.getBoundingClientRect().height),fs:getComputedStyle(document.querySelector('.lbl')).fontSize,lh:getComputedStyle(document.querySelector('.lbl')).lineHeight,bar:!!document.querySelector('#lbbar i')&&document.getElementById('lbbar').getBoundingClientRect().height<=8}})()""")
            check("picture whole-number scaled, pixelated",abs(geo["k"]-round(geo["k"]))<1e-6 and geo["k"]>=1 and abs(geo["kh"]-geo["k"])<1e-6 and "pixelated" in geo["rr"] and geo["inview"],"k=%s"%geo["k"])
            check("close and text-size buttons 48 px, arrows 48 px or more",geo["x"]==[48,48] and geo["aa"]==[48,48] and geo["nx"][1]>=48 and geo["bk"][1]>=48,str((geo["x"],geo["aa"],geo["nx"])))
            check("lines are 48 px targets; text 20 px on 30; thin progress bar",all(h>=48 for h in geo["ln"]) and geo["fs"]=="20px" and geo["lh"]=="30px" and geo["bar"])
            who=await pg.evaluate("[...document.querySelectorAll('.lbl')].map(l=>[l.dataset.id,!!l.querySelector('.who'),l.textContent])")
            T=json.load(open(ROOT/"historia/cuentos/que-calor.json"))
            check("speaker label: a Coquí line has 'Coquí', the text is exactly as recorded",all(w[1]==(T["clips"][w[0]]["who"]=="tu") and w[2].replace("Coquí","",1 if w[1] else 0)==T["clips"][w[0]]["text"] for w in who),str(who[:2]))
            # a line tap plays that line only
            await pg.evaluate("window.__log.length=0;window.__lit.length=0")
            tid=ids0[1] if len(ids0)>1 else ids0[0]
            await pg.locator('#lbtxt .lbl').nth(1 if len(ids0)>1 else 0).click(position={"x":8,"y":20})
            ok=await quiet(pg)
            check("a tap on a line plays that line (lit), and only it",ok and [e["id"] for e in await pg.evaluate("window.__log")]==[tid] and await pg.evaluate("window.__lit")==[tid])
            # next / back / swipe
            await pg.evaluate("window.__log.length=0;window.__lit.length=0")
            await pg.click("#lbnext");await until(pg,"()=>App.libro.i===1")
            p1=(await pg.evaluate("App.libro"))["ids"]
            check("next arrow: page 2, its lines play in order",await quiet(pg) and [e["id"] for e in await pg.evaluate("window.__log")]==p1 and await pg.evaluate("window.__lit")==p1 and (await pg.evaluate("App.libro"))["i"]==1)
            await pg.click("#lbback");await until(pg,"()=>App.libro.i===0");check("back arrow: page 1",(await pg.evaluate("App.libro"))["i"]==0)
            await swipe(cdp,300,80);await until(pg,"()=>App.libro.i===1");check("swipe left: next page",(await pg.evaluate("App.libro"))["i"]==1)
            await swipe(cdp,80,300);await until(pg,"()=>App.libro.i===0");check("swipe right: previous page",(await pg.evaluate("App.libro"))["i"]==0)
            await swipe(cdp,200,230);await pg.wait_for_timeout(300);check("a short drag does not turn the page",(await pg.evaluate("App.libro"))["i"]==0)
            await quiet(pg)
            check("back arrow disabled on page 1",await pg.evaluate("document.getElementById('lbback').disabled"))
            # audio stops on page change and on close
            await pg.evaluate("App.cierraLibro()");await pg.wait_for_timeout(400)
            await pg.click('.bk[data-c="que-calor"] .btn.out');await until(pg,"()=>App.libro.open&&speaking>0",15000)
            await pg.evaluate("window.__log.length=0");await until(pg,"()=>speaking>0&&window.__log.length>0")
            n0=len(await pg.evaluate("window.__log"));await pg.click("#lbnext");await pg.wait_for_timeout(1200)
            lg=await pg.evaluate("window.__log");ids1=(await pg.evaluate("App.libro"))["ids"]
            check("page change: the playing line is cut off and the new page's lines follow",all(e["end"] is not None for e in lg[:n0]) and lg[0]["ok"] is False and all(e["id"] in ids1 for e in lg[n0:]),"%d before the turn"%n0)
            await until(pg,"()=>speaking>0",8000)
            await pg.click("#lbx");await pg.wait_for_timeout(300)
            st=await pg.evaluate("({sp:speaking,live:live.size,open:App.libro.open,nav:getComputedStyle(document.querySelector('nav')).display})")
            check("closing the book stops the sound, shows the shelf and the tab bar",st["sp"]==0 and st["live"]==0 and not st["open"] and st["nav"]!="none" and await pg.evaluate("TAB")=="biblioteca")
            await pg.wait_for_timeout(1500);check("nothing starts again after the close",await pg.evaluate("speaking")==0)
            # text size toggle persists
            await pg.click('.bk[data-c="que-calor"] .btn.out');await until(pg,"()=>App.libro.open")
            await pg.click("#lbaa");fs=await pg.evaluate("[getComputedStyle(document.querySelector('.lbl')).fontSize,getComputedStyle(document.querySelector('.lbl')).lineHeight,localStorage.getItem('coqui.leer.tam')]")
            check("size button: 24 px on 36, remembered",fs==["24px","36px","24"],str(fs))
            await pg.wait_for_timeout(300);await shot(pg,"book_page_big_text")
            await pg.click("#lbx");await pg.wait_for_timeout(300);await pg.click('.bk[data-c="que-calor"] .btn.out');await until(pg,"()=>App.libro.open")
            check("size persists after closing and opening again",await pg.evaluate("getComputedStyle(document.querySelector('.lbl')).fontSize")=="24px")
            await pg.reload();await until(pg,"()=>!!(window.App&&App.ready)",15000);await pg.evaluate(HOOK);await pg.evaluate("App.ver('biblioteca')");await until(pg,"()=>document.querySelectorAll('#t-biblioteca .bk').length==3");await pg.wait_for_timeout(300)
            await pg.click('.bk[data-c="que-calor"] .btn.out');await until(pg,"()=>App.libro.open")
            check("size persists after a reload",await pg.evaluate("getComputedStyle(document.querySelector('.lbl')).fontSize")=="24px")
            await pg.click("#lbaa");check("size button toggles back to 20 px",await pg.evaluate("[getComputedStyle(document.querySelector('.lbl')).fontSize,localStorage.getItem('coqui.leer.tam')]")==["20px","20"])
            await quiet(pg,40000)
            # word taps: a word that has a picture shows the card; any other word plays the line
            npg=(await pg.evaluate("App.libro"))["n"];found=None
            for i in range(npg):
                f=await pg.evaluate("""(()=>{const s=document.querySelector('#lbtxt .bw');return s?{k:s.dataset.k,txt:s.textContent,n:document.querySelectorAll('#lbtxt .bw[data-k=\"'+s.dataset.k+'\"]').length}:null})()""")
                if f: found=(i,f);break
                await pg.evaluate("App.pag(1)");await pg.wait_for_timeout(300)
            check("a page has a word with a picture (a .bw)",found is not None,str(found))
            if found:
                await quiet(pg,40000);await pg.evaluate("window.__log.length=0")
                box=await pg.evaluate("(()=>{const r=document.querySelector('#lbtxt .bw').getBoundingClientRect();return [r.left+r.width/2,r.top+r.height/2]})()")
                await pg.mouse.click(box[0],box[1]);await pg.wait_for_timeout(500)
                card=await pg.evaluate("""(()=>{const c=document.getElementById('lbcard'),cv=c.querySelector('canvas');let ink=0;if(cv){const d=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data;for(let i=3;i<d.length;i+=4*50)if(d[i])ink++;}
                    return {on:c.classList.contains('on'),word:c.querySelector('.cw')&&c.querySelector('.cw').textContent,ink,uw:document.querySelectorAll('#lbtxt .bw.uw').length,log:window.__log.length,w:cv&&cv.getBoundingClientRect().width}})()""")
                check("tap on a picture word: a card with its picture and the word",card["on"] and card["ink"]>50 and norm(card["word"]).strip() in norm(found[1]["txt"]).strip() or norm(found[1]["txt"]).strip() in norm(card["word"]),str(card))
                check("every place the word is on the page is underlined",card["uw"]==found[1]["n"] and card["uw"]>=1,"%d underlined"%card["uw"])
                check("the word tap plays nothing",card["log"]==0)
                await shot(pg,"book_word_card")
                await pg.mouse.click(40,60);await pg.wait_for_timeout(300)
                check("the card closes on any tap (and that tap does nothing else)",not await pg.evaluate("document.getElementById('lbcard').classList.contains('on')") and await pg.evaluate("window.__log.length")==0 and await pg.evaluate("App.libro.open"))
                await pg.wait_for_timeout(2600);check("the underline goes after a moment",await pg.evaluate("document.querySelectorAll('#lbtxt .bw.uw').length")==0)
                # another word: find a plain word of a line and tap on it
                pt=await pg.evaluate("""(()=>{for(const l of document.querySelectorAll('#lbtxt .lbl')){const tx=l.querySelector('span:not(.who)');for(const n of tx.childNodes){if(n.nodeType===3){const m=/[A-Za-zÁ-ú]{3,}/.exec(n.textContent);if(m){const r=document.createRange();r.setStart(n,m.index);r.setEnd(n,m.index+m[0].length);const q=r.getBoundingClientRect();return {x:q.left+q.width/2,y:q.top+q.height/2,id:l.dataset.id,w:m[0]};}}}}return null})()""")
                check("a plain word is on the page",pt is not None,str(pt))
                if pt:
                    await pg.mouse.click(pt["x"],pt["y"]);ok=await quiet(pg)
                    check("tap on another word plays the line, no card",ok and [e["id"] for e in await pg.evaluate("window.__log")]==[pt["id"]] and not await pg.evaluate("document.getElementById('lbcard').classList.contains('on')"),pt["w"])
            # the read check, and no word record
            await pg.evaluate("App.pag(%d)"%(npg))   # clamps: the last page
            last=npg-1
            for _ in range(npg): await pg.evaluate("App.pag(1)")
            await pg.wait_for_timeout(500)
            check("the last page offers Otra vez and Biblioteca",await pg.evaluate("[document.getElementById('lbagain')&&document.getElementById('lbagain').textContent,document.getElementById('lbshelf')&&document.getElementById('lbshelf').textContent]")==["Otra vez","Biblioteca"])
            check("read check stored when the last page is reached",await pg.evaluate("!!(PAL.db.leidos&&PAL.db.leidos['que-calor'])"))
            check("reading writes no word record (palabras, days, stories unchanged)",await pg.evaluate("JSON.stringify([PAL.db.palabras,PAL.db.dias,PAL.db.cuentos])")==before)
            await shot(pg,"book_last_page")
            await pg.click("#lbagain");await pg.wait_for_timeout(300);check("Otra vez: back to page 1",(await pg.evaluate("App.libro"))["i"]==0)
            for _ in range(npg): await pg.evaluate("App.pag(1)")
            await pg.click("#lbshelf");await pg.wait_for_timeout(600)
            check("Biblioteca: the book closes on the shelf, the row has its check",not await pg.evaluate("App.libro.open") and await pg.evaluate("TAB")=="biblioteca" and await until(pg,"()=>!!document.querySelector('.bk[data-c=\"que-calor\"] .okc')") and not await pg.evaluate("!!document.querySelector('.bk[data-c=\"el-jugo\"] .okc')"))
            await pg.click('.bk[data-c="el-jugo"] .btn.out');await until(pg,"()=>App.libro.open");await pg.go_back();await pg.wait_for_timeout(500)
            check("the back button closes the book",not await pg.evaluate("App.libro.open") and await pg.evaluate("speaking")==0)
            # ------------------------------------------------------------- Palabras
            await pg.evaluate("""async()=>{const ws=Object.values(PAL.db.palabras);ws.forEach((r,i)=>{r.ear.etapa=1+i%4;r.mouth.etapa=i%4;r.mouth.n=i%4;r.ear.due=Date.now()+(1+i%3)*864e5;});PAL.save();App.ver('palabras');}""")
            await until(pg,"()=>document.querySelectorAll('#t-palabras .wc').length>0");await pg.wait_for_timeout(1200)
            recs=await pg.evaluate("Object.values(PAL.db.palabras).map(r=>({w:r.w,e:r.ear.etapa,m:r.mouth.etapa}))")
            cards=await pg.evaluate("""[...document.querySelectorAll('#t-palabras .wc')].map(c=>{let h=c,place=null;const hs=[...document.querySelectorAll('#t-palabras h2')].filter(x=>x.compareDocumentPosition(c)&4);place=hs.length?hs[hs.length-1].textContent:null;
                return {key:c.dataset.w,shown:c.querySelector('.w').textContent,pic:!!c.querySelector('canvas'),tile:!!c.querySelector('.tile'),dots:[...c.querySelectorAll('.mt')].map(m=>[m.querySelector('.ml').textContent,m.querySelectorAll('.dts i.on').length,m.querySelectorAll('.dts i').length]),place}})""")
            check("Palabras: every word he has heard has a card",sorted(c["key"] for c in cards)==sorted(r["w"] for r in recs) and len(cards)>=8,"%d cards"%len(cards))
            sp=all(c["shown"]==(c["key"] if next(r for r in recs if r["w"]==c["key"])["e"]>=2 else "?") for c in cards)
            check("spelling shows from ear stage 2, a '?' before",sp and any(c["shown"]=="?" for c in cards) and any(c["shown"]!="?" for c in cards))
            check("Ear and Mouth meters: four dots, filled by stage",all(c["dots"][0][0]=="Ear" and c["dots"][1][0]=="Mouth" and c["dots"][0][2]==4==c["dots"][1][2] and c["dots"][0][1]==next(r for r in recs if r["w"]==c["key"])["e"] and c["dots"][1][1]==next(r for r in recs if r["w"]==c["key"])["m"] for c in cards))
            pair=await pg.evaluate("CU.items.map(i=>i.w)")
            check("a picture on a pair word, a plain tile on the others",all(c["pic"]==(c["key"] in pair) and c["tile"]==(c["key"] not in pair) for c in cards) and any(c["tile"] for c in cards) and any(c["pic"] for c in cards))
            inks=await pg.evaluate("[...document.querySelectorAll('#t-palabras .wc canvas')].map(cv=>{const d=cv.getContext('2d').getImageData(0,0,196,104).data;let n=0;for(let i=3;i<d.length;i+=4*40)if(d[i])n++;return n})")
            check("the pictures are drawn",all(n>100 for n in inks))
            # grouping by place, in story order, as the story files say
            lug=await pg.evaluate("CURSO.lugares.map(l=>({id:l.id,nombre:l.nombre,cuentos:l.cuentos||[]}))");played=await pg.evaluate("Object.keys(PAL.db.cuentos).filter(c=>PAL.db.cuentos[c].n)")
            where={};order=[]
            for key in ("focus_words","back_again"):
                for l in lug:
                    for c in l["cuentos"]:
                        if c in played:
                            for w in json.load(open(ROOT/"historia/cuentos"/(c+".json"))).get(key,[]):
                                if w not in where: where[w]=l["nombre"];order.append(w)
            check("words grouped by place, in story order",all(c["place"]==where.get(c["key"],"More words") for c in cards) and all([c["key"] for c in cards if c["place"]==pl and c["key"] in order]==sorted([c["key"] for c in cards if c["place"]==pl and c["key"] in order],key=order.index) for pl in set(c["place"] for c in cards)),str(sorted(set(c["place"] for c in cards))))
            check("place headings are h2 in place order",(await pg.evaluate("[...document.querySelectorAll('#t-palabras h2')].map(h=>h.textContent)"))[:1]==["La casa"])
            # the Repaso card
            rp=await pg.evaluate("[document.querySelector('#repaso').textContent,document.querySelector('#repaso').closest('.row').querySelector('.btn').textContent,document.querySelector('#repaso').parentNode.querySelector('b').textContent]")
            check("Repaso card, nothing due: 'Nothing due today' and Practice",rp==["Nothing due today","Practice","Repaso"],str(rp))
            await shot(pg,"palabras_top")
            await pg.evaluate("window.__PAL_NOW=Date.now()+3*864e5;App.ver('palabras')");await until(pg,"()=>document.querySelectorAll('#t-palabras .wc').length>0");await pg.wait_for_timeout(300)
            rp=await pg.evaluate("[document.querySelector('#repaso').textContent,document.querySelector('#repaso').closest('.row').querySelector('.btn').textContent]");due=await pg.evaluate("PAL.vence('ear').filter(w=>CU.items.some(i=>i.w===w)).length")
            m=re.match(r"(\d+) words? today · about (\d+) min$",rp[0])
            check("Repaso card, words due: 'N words today · about M min' and Start",m is not None and int(m.group(1))==due>0 and int(m.group(2))>=1 and rp[1]=="Start",str(rp))
            await shot(pg,"palabras_repaso_due")
            await pg.evaluate("window.__PAL_NOW=undefined;App.ver('palabras')");await until(pg,"()=>document.querySelectorAll('#t-palabras .wc').length>0");await pg.wait_for_timeout(300)
            # a long page, scrolled to a mixed part
            await pg.evaluate("window.scrollTo(0,900)");await pg.wait_for_timeout(300);await shot(pg,"palabras_cards")
            # word sheet
            pick=await pg.evaluate("""(()=>{const f=[...document.querySelectorAll('#t-palabras .wc')].find(c=>c.dataset.w==='agua')||[...document.querySelectorAll('#t-palabras .wc')].find(c=>c.querySelector('canvas'));return f.dataset.w})()""")
            await pg.evaluate("window.scrollTo(0,0)");await pg.click('#t-palabras .wc[data-w="%s"]'%pick);await until(pg,"()=>document.getElementById('sheet').classList.contains('on')&&document.querySelectorAll('#oido .li').length>=0");await pg.wait_for_timeout(700)
            sh=await pg.evaluate("""(()=>{const s=document.getElementById('sheet');return {on:s.classList.contains('on'),canvas:!!s.querySelector('canvas.wsp'),cw:s.querySelector('canvas.wsp')&&s.querySelector('canvas.wsp').getBoundingClientRect().width,word:s.querySelector('.wsw').textContent,dots:[...s.querySelectorAll('.mt')].map(m=>[m.querySelector('.ml').textContent,m.querySelectorAll('.dts i.on').length]),back:(s.querySelector('p.small.mut')||{}).textContent,
               lines:[...s.querySelectorAll('#oido .li')].map(l=>[l.querySelector('.grow').textContent,l.querySelector('.pb').dataset.id,l.querySelector('.pb').getBoundingClientRect().height]),h2:[...s.querySelectorAll('h2')].map(h=>h.textContent)}})()""")
            rec=next(r for r in recs if r["w"]==pick)
            check("word sheet: big picture, the word, Ear and Mouth meters",sh["on"] and sh["canvas"] and sh["cw"]>=196 and sh["word"]==(pick if rec["e"]>=2 else "?") and sh["dots"]==[["Ear",rec["e"]],["Mouth",rec["m"]]],str(sh["dots"]))
            check("word sheet: next return in English",re.match(r"Comes back (today|in \d+ days?)$",sh["back"] or "") is not None,sh["back"])
            check("word sheet: 'Heard in', up to five lines that contain the word, each with a 48 px play button",sh["h2"]==["Heard in"] and 1<=len(sh["lines"])<=5 and all(norm(pick) in norm(l[0]) and l[2]>=48 for l in sh["lines"]),"%d lines"%len(sh["lines"]))
            await shot(pg,"word_sheet")
            if sh["lines"]:
                await pg.evaluate("window.__log.length=0");await pg.click('#oido .li:first-child .pb');await until(pg,"()=>speaking>0",15000)
                check("a 'Heard in' line plays its own recording",await pg.evaluate("window.__log.map(e=>e.id)")==[sh["lines"][0][1]])
                await pg.click('#oido .li:first-child .pb');await pg.wait_for_timeout(300)
                check("a second touch stops it",await pg.evaluate("speaking")==0)
                await pg.click('#oido .li:first-child .pb');await until(pg,"()=>speaking>0",15000);await pg.click("#shead .x");await pg.wait_for_timeout(300)
                check("closing the sheet stops the sound",await pg.evaluate("speaking")==0 and await pg.evaluate("live.size")==0)
            # a word with no picture: the sheet has no picture
            tl=await pg.evaluate("(()=>{const c=[...document.querySelectorAll('#t-palabras .wc')].find(c=>c.querySelector('.tile'));return c&&c.dataset.w})()")
            if tl:
                await pg.evaluate("window.scrollTo(0,0)");await pg.evaluate("App.palabra(%s)"%json.dumps(tl));await pg.wait_for_timeout(500)
                check("word with no picture: sheet without a picture, with its meters",await pg.evaluate("!document.querySelector('#sheet canvas.wsp')&&document.querySelectorAll('#sheet .mt').length==2"),tl)
                await pg.click("#shead .x")
            # add a word or a goal
            await pg.fill("#extra","talk to my 1-year-old");await pg.click("#t-palabras .btn:text-is('Add')");await pg.wait_for_timeout(1000)
            tx=await pg.inner_text("#t-palabras")
            check("add a word or a goal: honest text and the saved list","Saved. Material for it comes later." in tx and "talk to my 1-year-old" in tx and "talk to my 1-year-old" in await pg.evaluate("JSON.stringify(PAL.db.extra)"))
            # no horizontal scroll
            check("390 px: no horizontal scroll (Palabras)",await pg.evaluate("document.documentElement.scrollWidth<=innerWidth"))
            await ctx.close()
            # ------------------------------------------------------------- 360 x 640
            ctx2,pg2=await new_page(b,360,640,errs)
            await pg2.goto(BASE);await until(pg2,"()=>!!(window.App&&App.ready)",15000);await pg2.evaluate("App.listo()");await pg2.evaluate(HOOK)
            await pg2.evaluate("""async()=>{for(const c of ['el-jugo','que-calor','la-lluvia']){const T=await (await fetch('cuentos/'+c+'.json')).json();PAL.cuento(T,[]);}App.ver('biblioteca');}""");await until(pg2,"()=>document.querySelectorAll('#t-biblioteca .bk').length>=3");await pg2.wait_for_timeout(500)
            check("360 px: shelf has no horizontal scroll",await pg2.evaluate("document.documentElement.scrollWidth<=360"))
            await pg2.click('.bk[data-c="que-calor"] .btn.out');await until(pg2,"()=>App.libro.open&&App.libro.ids.length>0");await pg2.wait_for_timeout(1000)
            ov=await pg2.evaluate("""(()=>{const l=document.getElementById('libro'),bad=[...l.querySelectorAll('*')].filter(e=>{const r=e.getBoundingClientRect();return r.width>0&&(r.right>360.5||r.left<-.5)&&getComputedStyle(e).position!=='absolute'}).map(e=>e.id||e.className);const im=document.getElementById('lbimg').getBoundingClientRect();
               return {sw:l.scrollWidth,bad,imh:im.height,imbottom:im.bottom,txt:document.getElementById('lbtxt').getBoundingClientRect().top,foot:document.getElementById('lbfoot').getBoundingClientRect().top,dsw:document.documentElement.scrollWidth}})()""")
            check("360x640: the book has no horizontal scroll, the picture clears the text and the buttons",ov["sw"]<=360 and ov["dsw"]<=360 and not ov["bad"] and ov["imbottom"]<=ov["txt"]+1 and ov["txt"]<ov["foot"],str(ov))
            await pg2.click("#lbaa");await pg2.wait_for_timeout(400)
            ov=await pg2.evaluate("(()=>{const l=document.getElementById('libro');return {sw:l.scrollWidth,txtb:document.getElementById('lbtxt').getBoundingClientRect().bottom,foot:document.getElementById('lbfoot').getBoundingClientRect().top,imh:document.getElementById('lbimg').getBoundingClientRect().height}})()")
            check("360x640 with the large text: nothing overlaps, no horizontal scroll",ov["sw"]<=360 and ov["txtb"]<=ov["foot"]+1 and ov["imh"]>40,str(ov))
            await pg2.evaluate("App.cierraLibro()");await pg2.evaluate("""()=>{Object.values(PAL.db.palabras).forEach((r,i)=>{r.ear.etapa=1+i%4;});PAL.save();App.ver('palabras');}""");await until(pg2,"()=>document.querySelectorAll('#t-palabras .wc').length>0");await pg2.wait_for_timeout(800)
            check("360 px: Palabras has no horizontal scroll",await pg2.evaluate("document.documentElement.scrollWidth<=360"))
            await pg2.click('#t-palabras .wc >> nth=0');await pg2.wait_for_timeout(600)
            check("360 px: the word sheet has no horizontal scroll",await pg2.evaluate("document.documentElement.scrollWidth<=360&&document.getElementById('sbody').scrollWidth<=document.getElementById('sbody').clientWidth+1"))
            await ctx2.close()
            # ------------------------------------------------------------- frames of a longer story, if wanted
            if FRAMES:
                ctx3,pg3=await new_page(b,errs=errs);await pg3.goto(BASE);await until(pg3,"()=>!!(window.App&&App.ready)",15000);await pg3.evaluate("App.listo()");await pg3.evaluate(HOOK)
                await pg3.evaluate("""async()=>{const l=CURSO.lugares[0];for(const c of l.cuentos.slice(0,5)){const T=await (await fetch('cuentos/'+c+'.json')).json();PAL.cuento(T,[]);}
                  const ws=Object.values(PAL.db.palabras);ws.forEach((r,i)=>{r.ear.etapa=1+(i*7)%4;r.mouth.etapa=(i*5)%4;r.mouth.n=r.mouth.etapa;r.ear.due=Date.now()+(1+i%3)*864e5;});PAL.db.leidos={'la-lluvia':Date.now()};PAL.save();window.__PAL_NOW=Date.now()+2*864e5;App.ver('biblioteca');}""")
                await until(pg3,"()=>document.querySelectorAll('#t-biblioteca .bk').length>=5");await pg3.wait_for_timeout(800)
                await shot(pg3,"shelf_five_played")
                await pg3.click('.bk[data-c="la-lluvia"] .btn.out');await until(pg3,"()=>App.libro.open&&App.libro.ids.length>0");await pg3.wait_for_timeout(1500);await shot(pg3,"book_first_page")
                await pg3.evaluate("App.pag(1)");await pg3.wait_for_timeout(1200);await shot(pg3,"book_second_page")
                await ctx3.close()
            check("no page errors",not [e for e in errs if e.startswith("pageerror")],str([e for e in errs if e.startswith("pageerror")][:3]))
            check("no console errors",not [e for e in errs if e.startswith("console")],str([e for e in errs if e.startswith("console")][:3]))
            await b.close()
    finally:
        if srv: srv.terminate()
    if FAKED: print("note: books faked for the check:",", ".join(sorted(FAKED)))
    if FRAMES: print("frames:",FRAMES)
    print("%d checks, %d failed"%(N[0],len(FAILS)));sys.exit(1 if FAILS else 0)
asyncio.run(main())
