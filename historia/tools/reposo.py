"""Plays a story by machine and keeps a picture of every moment at rest: nothing moves between two looks, so no frame is caught mid-step.

  python3 historia/tools/reposo.py <outdir> <plan> <cuento> [extra-query] [fast] [base-url]

  outdir   a folder for the frames (it must exist); each is the canvas of the game as it is, upscaled 4 times with hard pixels
  plan     one letter per choice, in order: r = right, w = wrong (as in juega.py)
  extra    more query, for example ka=mant&ta=nt (fixes draws); txt=no is always added (no words on screen)
  fast     speed (2 is good: a rest shorter than two looks, about 130 ms, is not kept)
A frame is kept when the picture has not changed in two looks and differs from the last one kept. The signs, the stars and the words are part of the picture. Needs the local server on 8765."""
import sys, asyncio, json, time, base64, io
from playwright.async_api import async_playwright
from PIL import Image
A=sys.argv; OUT=A[1]; PLAN=A[2]; CUENTO=A[3]; EXTRA=A[4] if len(A)>4 else ""; FASTV=A[5] if len(A)>5 else "2"
BASE=A[6] if len(A)>6 else "http://127.0.0.1:8765/historia/index.html"
URL=f"{BASE}?cuento={CUENTO}&fast={FASTV}&txt=no"+("&"+EXTRA if EXTRA else "")
# what moves: where everybody and everything is. Steam, a blinking eye or the hand of a sign swinging do not count.
SIG="""()=>{const W=Story.W,p=Story.pending;const m=o=>o&&JSON.stringify(o,(k,v)=>k==='fx'?undefined:v);
 return JSON.stringify([m(W.gente),m(W.cosas),m(W.cq),m(W.perro),m(W.vuelos),W.resp,W.spot,W.marcas,W.heart,W.lost,p?p.live.join('|'):null,p?p.sign:null,Story.cap,W.twinkle,(W.fx||[]).length])}"""
STATE="()=>{const p=Story.pending;return {live:p?p.live.join('|'):null,kind:p?p.kind:null,pick:p?p.pick:null,sign:p?p.sign:null,asked:p?p.asked:0,running:Story.running,cap:Story.cap}}"
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
        ctx=await b.new_context(viewport={"width":390,"height":844},device_scale_factor=2,is_mobile=True,has_touch=True)
        pg=await ctx.new_page(); msgs=[]
        pg.on("pageerror",lambda e: (msgs.append(str(e)),print("PAGEERROR:",str(e)[:300],flush=True)))
        await pg.goto(URL); await pg.wait_for_timeout(2500)
        await pg.click("#go"); n=0; k=0; prev=None; last=None; tapped=None; still=0
        for i in range(60000):
            await pg.wait_for_timeout(55)
            s=await pg.evaluate(STATE)
            if not s["running"] and i>40: break
            sig=await pg.evaluate(SIG)
            if sig==prev: still+=1
            else: still=0
            prev=sig
            if still==2 and sig!=last:
                last=sig; url=await pg.evaluate("document.querySelector('#cv').toDataURL('image/png')")
                im=Image.open(io.BytesIO(base64.b64decode(url.split(",")[1]))).convert("RGB"); im=im.resize((im.width*4,im.height*4),Image.NEAREST)
                n+=1; im.save(f"{OUT}/{n:03d}.png")
            if not s["live"]: tapped=None
            if s["live"] and s["asked"] and (s["live"],s["pick"],s["sign"],s["cap"])!=tapped:
                live=s["live"].split("|")
                if len(live)==1: tgt=live[0]
                else:
                    want=PLAN[k] if k<len(PLAN) else "r"; k+=1
                    if s["kind"]=="decide": tgt=s["pick"] if want=="r" else [x for x in live if x!=s["pick"]][0]
                    else: tgt=live[0] if want=="r" else live[1]
                await pg.wait_for_timeout(150)
                try: await pg.evaluate(f"Story.tapOn('{tgt}')")
                except Exception as e: print("could not touch",tgt,str(e)[:160]); raise SystemExit(1)
                tapped=(s["live"],s["pick"],s["sign"],s["cap"]); await pg.wait_for_timeout(150)
        print("frames:",n,"errors:",msgs[:3]); await b.close()
asyncio.run(main())
