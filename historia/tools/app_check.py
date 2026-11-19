# Checks the app page by machine (needs a local server of the repository; port 8765, or the one in PORT): python3 historia/tools/app_check.py <outdir>   (outdir must exist; prints ready, plan, sheet, shelf, book, palabras, errors; exits 1 on a page error or a missing piece)
# The shelf, the book and Palabras are checked in full by leer_check.py (port 8769).
import asyncio,json,os,sys
from playwright.async_api import async_playwright
OUT=sys.argv[1];PORT=os.environ.get("PORT","8765");FAIL=[]
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
        pg=await (await b.new_context(viewport={"width":390,"height":844},device_scale_factor=2,is_mobile=True,has_touch=True)).new_page();errs=[]
        pg.on("pageerror",lambda e: errs.append(str(e))); pg.on("console",lambda m: errs.append("console:"+m.text) if m.type=="error" else None)
        await pg.goto("http://127.0.0.1:%s/historia/app.html"%PORT); await pg.wait_for_timeout(3000)
        print("ready",await pg.evaluate("!!(window.App&&App.ready)"))
        await pg.evaluate("App.listo()"); await pg.wait_for_timeout(300)
        print("plan",json.dumps(await pg.evaluate("App.plan()"),ensure_ascii=False)[:400])
        await pg.screenshot(path=OUT+"/app1.png")
        await pg.evaluate("App.lugar(0)"); await pg.wait_for_timeout(500); await pg.screenshot(path=OUT+"/app2.png")
        print("sheet",(await pg.evaluate("document.getElementById('sheet').innerText"))[:400].replace("\n"," | "))
        # mark the two new stories as played, with their words, and look at Palabras, the shelf and a book
        # the stories to play: two plain ones, and the first story whose book reads well ("lee": true), so the book can be opened
        await pg.evaluate("""async()=>{const ids=['el-jugo','que-calor'];for(const c of CURSO.lugares.flatMap(l=>l.cuentos||[])){try{const r=await fetch('libros/'+c+'.json');if(r.ok&&(await r.json()).lee===true){ids.push(c);break;}}catch(e){}}
          for(const c of ids){const T=await (await fetch('cuentos/'+c+'.json')).json();PAL.cuento(T,[]);}cierra();App.ver('palabras');}""")
        await pg.wait_for_timeout(1500); await pg.screenshot(path=OUT+"/app3.png",full_page=True)
        n=await pg.evaluate("document.querySelectorAll('#t-palabras .wc').length"); print("palabras",n,"cards |",(await pg.evaluate("document.getElementById('repaso').textContent")))
        if not n: FAIL.append("no word cards")
        await pg.evaluate("App.ver('biblioteca')"); await pg.wait_for_timeout(1200); await pg.screenshot(path=OUT+"/app4.png")
        rows=await pg.evaluate("[...document.querySelectorAll('#t-biblioteca .bk')].map(r=>r.dataset.c)"); print("shelf",rows)
        if not rows: FAIL.append("empty shelf")
        # a book that exists (the tool makes them): open it; one without a book has no Read button
        rd=await pg.evaluate("[...document.querySelectorAll('#t-biblioteca .bk')].filter(r=>[...r.querySelectorAll('button')].some(b=>b.textContent.trim()==='Read')).map(r=>r.dataset.c)")
        if rd:
            await pg.evaluate("App.leer(%s)"%json.dumps(rd[0])); await pg.wait_for_timeout(2000); await pg.screenshot(path=OUT+"/app5.png")
            print("book",rd[0],json.dumps(await pg.evaluate("App.libro"),ensure_ascii=False)[:300])
            print("page text",(await pg.evaluate("document.getElementById('lbtxt').innerText"))[:300].replace("\n"," | "))
            if not await pg.evaluate("App.libro.open&&App.libro.ids.length>0"): FAIL.append("book did not open")
            await pg.evaluate("App.cierraLibro()")
        else: print("no book yet for a played story")
        errs=[e for e in errs if "vibrate" not in e]   # the browser refuses a haptic that a script (not a finger) asked for
        print("errors",errs[:6]); await b.close()
        if [e for e in errs if not e.startswith("console:")] or FAIL: print("FAIL",FAIL); sys.exit(1)
asyncio.run(main())
