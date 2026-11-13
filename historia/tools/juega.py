"""Plays any story by machine, at phone size, and reports every change of state.

  python3 historia/tools/juega.py <outdir|-> <plan> [cuento] [fast] [extra-query] [base-url]

  outdir   a folder for screenshots of the picture only (it must exist), or - for none
  plan     one letter per choice, in order: r = right, w = wrong. For a choice with no wrong
           answer, r takes the first option and w the second. Missing letters count as r.
  cuento   the story id (default la-lluvia)
  fast     speed (3 is good for a check, 1 is real speed)
  extra    more query, for example a=ventana&ave=puerta (fixes draws)
  base-url default http://127.0.0.1:8765/historia/index.html (serve the repo first: python3 -m http.server 8765)
  TL=1     prints when each spoken line starts and ends, and marks stretches with no voice.
  WRAP=1   screenshots include the words on screen (bubbles and caption), not only the picture.

Needs: pip install playwright, and a Chrome at /usr/bin/google-chrome.
It reads the game through window.Story (see historia/juego.js)."""
import sys, asyncio, json, time, os
from playwright.async_api import async_playwright
A=sys.argv; OUT=A[1]; PLAN=A[2]; CUENTO=A[3] if len(A)>3 else "la-lluvia"; FASTV=A[4] if len(A)>4 else "3"; EXTRA=A[5] if len(A)>5 else ""
BASE=A[6] if len(A)>6 else "http://127.0.0.1:8765/historia/index.html"
URL=f"{BASE}?cuento={CUENTO}&fast={FASTV}"+("&"+EXTRA if EXTRA else "")
STATE="""()=>{const W=Story.W,p=Story.pending,V=Story.V;return {live:p?p.live.join('|'):null,kind:p?p.kind:null,pick:p?p.pick:null,sign:p?p.sign:null,asked:p?p.asked:0,lock:p?p.lock:false,
 V:JSON.stringify(V),lost:W.lost,door:W.door,win:W.win,lamp:W.lamp,ab:W.ab?W.ab.en+'-'+W.ab.pose:null,vis:W.cq.vis,cq:W.cq.x+','+W.cq.y,bub:W.cq.bub,rain:W.rain,tab:W.tab,heart:W.heart,
 plato:W.plato,ave:W.ave?W.ave.mode+'-'+(W.ave.st||''):null,resp:W.resp?W.resp.join('|'):null,extra:Story.scene?Story.scene():'',
 running:Story.running,dots:document.querySelectorAll('.dot.on').length,cap:Story.cap,bubt:Story.bub}}"""
class Log(list):
    def append(self,x): super().append(x); print(x,flush=True)
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
        ctx=await b.new_context(viewport={"width":390,"height":844},device_scale_factor=2,is_mobile=True,has_touch=True)
        pg=await ctx.new_page(); msgs=[]
        pg.on("console",lambda m: msgs.append(m.type+": "+m.text)); pg.on("pageerror",lambda e: (msgs.append("PAGEERROR: "+str(e)),print("PAGEERROR:",str(e)[:300],flush=True)))
        await pg.goto(URL); await pg.wait_for_timeout(2500)
        print("ready:",await pg.evaluate("Story.ready"),"voice:",await pg.evaluate("Story.voice"),"clips:",await pg.evaluate("Story.clips"))
        shot=pg.locator("#wrap" if os.environ.get("WRAP") else "#cv"); n=0
        async def snap(tag):
            nonlocal n
            if OUT=="-": return
            n+=1; await pg.wait_for_timeout(320); await shot.screenshot(path=f"{OUT}/{n:02d}_{tag}.png")
        if os.environ.get("TL"):
            await pg.evaluate("""()=>{window.__t=[];const _p=playClip;playClip=function(id){const e={id,t0:performance.now()};__t.push(e);const pr=_p(id);pr.then(()=>{e.t1=performance.now();});return pr;};}""")
        t0=time.time(); await pg.click("#go"); last=None; seen=None; k=0; log=Log(); tapped=None
        for i in range(9000):
            await pg.wait_for_timeout(40)
            s=await pg.evaluate(STATE)
            sig=json.dumps({x:s[x] for x in ("live","sign","lost","door","win","lamp","ab","vis","rain","tab","heart","dots","bub","plato","ave","resp","cap","bubt","extra")})
            if sig!=last:
                last=sig; log.append(f"{time.time()-t0:5.1f}s d{s['dots']} CAP=[{s['cap']}] BUB=[{s['bubt']}] live={s['live']} sign={s['sign']} lost={s['lost']} door={s['door']} win={s['win']} ab={s['ab']} frog={'in' if not s['vis'] else s['cq']} cqbub={s['bub']} plato={s['plato']} ave={s['ave']} resp={s['resp']} {s['extra']}")
                key=(s["sign"],s["lost"],s["door"],s["win"],s["ab"],s["plato"],s["ave"],s["resp"],s["tab"],s["heart"],s["rain"],s["lamp"],s["extra"],s["bubt"] if os.environ.get("WRAP") else "")
                if key!=seen: seen=key; await snap(f"d{s['dots']}_L{s['lost']}")
            if not s["live"]: tapped=None
            if s["live"] and (s["asked"]) and (s["live"],s["pick"],s["sign"],s["cap"])!=tapped:
                live=s["live"].split("|")
                if len(live)==1: tgt=live[0]
                else:
                    want=PLAN[k] if k<len(PLAN) else "r"; k+=1
                    if s["kind"]=="decide": tgt=s["pick"] if want=="r" else [x for x in live if x!=s["pick"]][0]
                    else: tgt=live[0] if want=="r" else live[1]
                    log.append(f"        choice {k} ({s['kind']}): right={s['pick']} touching {tgt}  V={s['V']}"); await snap(f"choice{k}_waiting")
                await pg.wait_for_timeout(150)
                try: await pg.evaluate(f"Story.tapOn('{tgt}')")
                except Exception as e: log.append(f"        could not touch {tgt}: {str(e)[:160]}"); raise SystemExit(1)
                tapped=(s["live"],s["pick"],s["sign"],s["cap"]); await pg.wait_for_timeout(150)
            if not s["running"] and i>40: break
        await snap("end")
        print("took %.1fs at fast=%s"%(time.time()-t0,FASTV)); print("log:",await pg.evaluate("JSON.stringify(Story.log)"))
        if os.environ.get("TL"):
            tl=await pg.evaluate("__t"); base=tl[0]["t0"]; prev=None
            for e in tl:
                gap=(e["t0"]-prev["t1"])/1000 if prev and "t1" in prev else 0
                print("  %6.1fs  %-20s %.1fs%s"%((e["t0"]-base)/1000,e["id"],(e.get("t1",e["t0"])-e["t0"])/1000,("   <- %.1fs of no voice before this"%gap) if gap>=0.9 else "")); prev=e
        print("again button:",await pg.evaluate("getComputedStyle(document.querySelector('#again')).display"))
        for m in msgs[:12]: print("  ",m)
        await b.close()
asyncio.run(main())
