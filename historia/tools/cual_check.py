"""Plays the ¿Cuál? pass by machine. python3 historia/tools/cual_check.py <plan r/w per item> [extra-query] [outdir]"""
import sys,asyncio,json
from playwright.async_api import async_playwright
PLAN=sys.argv[1]; EXTRA=sys.argv[2] if len(sys.argv)>2 else ""; OUT=sys.argv[3] if len(sys.argv)>3 else None
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
        pg=await (await b.new_context(viewport={"width":390,"height":844},device_scale_factor=2,is_mobile=True,has_touch=True)).new_page();errs=[]
        pg.on("pageerror",lambda e: errs.append(str(e)))
        await pg.goto("http://127.0.0.1:8765/historia/cual.html?fast=3&"+EXTRA); await pg.wait_for_timeout(2500); await pg.click("#go")
        k=0;last=-1;n=0
        for i in range(3000):
            await pg.wait_for_timeout(60)
            st=await pg.evaluate("({listo:Cual.listo,pan:Cual.pan,i:Cual.i,run:Cual.running,sp:Cual.speaking,lista:Cual.lista,cap:Story.cap})")
            if st["pan"] and st["i"]!=last and st["listo"]:
                await pg.wait_for_timeout(200)
                if OUT: n+=1; await pg.locator("#wrap").screenshot(path=f"{OUT}/{n:02d}_{st['lista'][st['i']]}.png")
                want=PLAN[k] if k<len(PLAN) else "r"; k+=1
                right=[j for j,x in enumerate(st["pan"]) if x["right"]][0]; tgt=right if want=="r" else 1-right
                await pg.evaluate(f"Cual.toca({tgt})"); last=st["i"]
                if want=="w":
                    await pg.wait_for_timeout(1500); await pg.evaluate(f"Cual.toca({right})")
            if i>40 and not st["run"]: break
        print("items:",st["lista"]); print("answers:",json.dumps(await pg.evaluate("Cual.hecho")))
        print("records:",json.dumps({w:{"etapa":r["ear"]["etapa"],"paso":r["ear"]["paso"],"n":r["ear"]["n"],"due_in_h":round((r["ear"]["due"]-await pg.evaluate("Date.now()"))/36e5,1)} for w,r in (await pg.evaluate("PAL.db.palabras")).items()},ensure_ascii=False))
        print("errors:",errs[:5]); await b.close()
asyncio.run(main())
