# Checks the app page by machine (needs the local server on 8765): python3 historia/tools/app_check.py <outdir>   (outdir must exist; prints ready, plan, sheet, leer, errors)
import asyncio,json,sys
from playwright.async_api import async_playwright
OUT=sys.argv[1]
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
        pg=await (await b.new_context(viewport={"width":390,"height":844},device_scale_factor=2,is_mobile=True,has_touch=True)).new_page();errs=[]
        pg.on("pageerror",lambda e: errs.append(str(e))); pg.on("console",lambda m: errs.append("console:"+m.text) if m.type=="error" else None)
        await pg.goto("http://127.0.0.1:8765/historia/app.html"); await pg.wait_for_timeout(3000)
        print("ready",await pg.evaluate("!!(window.App&&App.ready)"))
        await pg.evaluate("App.listo()"); await pg.wait_for_timeout(300)
        print("plan",json.dumps(await pg.evaluate("App.plan()"),ensure_ascii=False)[:400])
        await pg.screenshot(path=OUT+"/app1.png")
        await pg.evaluate("App.lugar(0)"); await pg.wait_for_timeout(500); await pg.screenshot(path=OUT+"/app2.png")
        print("sheet",(await pg.evaluate("document.getElementById('sheet').innerText"))[:400].replace("\n"," | "))
        # mark the two new stories as played, with their words, and look at Palabras and Leer
        await pg.evaluate("""async()=>{for(const c of ['el-jugo','que-calor']){const T=await (await fetch('cuentos/'+c+'.json')).json();PAL.cuento(T,[]);}cierra();App.ver('palabras');}""")
        await pg.wait_for_timeout(1200); await pg.screenshot(path=OUT+"/app3.png",full_page=True)
        await pg.evaluate("App.ver('biblioteca')"); await pg.wait_for_timeout(300); await pg.evaluate("App.leer('que-calor')"); await pg.wait_for_timeout(1500); await pg.screenshot(path=OUT+"/app4.png")
        print("leer",(await pg.evaluate("document.getElementById('sheet').innerText"))[:500].replace("\n"," | "))
        print("errors",errs[:6]); await b.close()
asyncio.run(main())
