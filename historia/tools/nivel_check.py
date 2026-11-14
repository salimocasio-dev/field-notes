# Plays the level check by machine (needs the local server on 8765): python3 historia/tools/nivel_check.py "" <outdir> todo   (plan "" = all right, or r/w per item; outdir must exist, or - for no frames; todo = every item)
"""Plays the level check by machine. python3 nivel_check.py <plan r/w per item, or 'k<N>' = right on the first N stories> <outdir|->"""
import sys,asyncio,json
from playwright.async_api import async_playwright
PLAN=sys.argv[1]; OUT=sys.argv[2] if len(sys.argv)>2 else "-"
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
        pg=await (await b.new_context(viewport={"width":390,"height":844},device_scale_factor=2,is_mobile=True,has_touch=True)).new_page();errs=[]
        pg.on("pageerror",lambda e: errs.append(str(e)))
        await pg.goto("http://127.0.0.1:8765/historia/nivel.html?fast=4&rec=1"+("&todo=1" if len(sys.argv)>3 else "")); await pg.wait_for_timeout(2500); await pg.evaluate("PAL.reset()"); await pg.click("#go")
        last=-1;k=0;n=0
        for i in range(4000):
            await pg.wait_for_timeout(60)
            st=await pg.evaluate("({pan:Nivel.pan,i:Nivel.i,listo:Nivel.listo,run:Nivel.running,fin:Nivel.fin,h:Nivel.hecho.length})")
            if st["pan"] and st["listo"] and st["i"]!=last:
                await pg.wait_for_timeout(150)
                if OUT!="-": n+=1; await pg.locator("#cv").screenshot(path=f"{OUT}/{n:02d}.png")
                right=[j for j,x in enumerate(st["pan"]) if x["right"]][0]
                print("KEY",n,right+1)
                if PLAN.startswith("k"):
                    s=await pg.evaluate("Nivel.NV[[...Array(Nivel.NV.length).keys()].find(j=>!Nivel.hecho.some(h=>h.i===j)&&Nivel.pan)]") # not used
                    q=await pg.evaluate("(()=>{const us=new Set(Nivel.hecho.map(h=>h.i));return null})()")
                want=PLAN[k] if (not PLAN.startswith("k") and k<len(PLAN)) else "r"; k+=1
                if PLAN.startswith("k"):
                    cur=await pg.evaluate("window.__cur")
                    want="r" if cur is not None and cur<=int(PLAN[1:]) else "w"
                tgt=right if want=="r" else (right+1)%4
                await pg.evaluate(f"Nivel.toca({tgt})"); last=st["i"]
            if st["fin"]: break
        print("asked:",json.dumps(await pg.evaluate("Nivel.hecho.map(h=>h.w+':'+h.s+(h.ok?'+':'-'))"),ensure_ascii=False))
        print("result:",json.dumps(await pg.evaluate("Nivel.fin"),ensure_ascii=False)[:400])
        print("fin card:",(await pg.evaluate("document.querySelector('#fin').innerText"))[:300].replace("\n"," | "))
        print("records:",json.dumps(await pg.evaluate("Object.values(PAL.db.palabras).slice(0,4).map(r=>({w:r.w,etapa:r.ear.etapa,due_h:Math.round((r.ear.due-Date.now())/36e5)}))"),ensure_ascii=False), "stories:",await pg.evaluate("Object.keys(PAL.db.cuentos).length"))
        if OUT!="-": await pg.screenshot(path=f"{OUT}/fin.png")
        print("errors:",errs[:3]); await b.close()
asyncio.run(main())
