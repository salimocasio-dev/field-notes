"""Plays a story by machine, at phone size, and reports every change of state.

  python3 historia/tools/juega.py <outdir|-> <plan> <a> [fast] [early] [base-url]

  outdir   a folder for screenshots (it must exist), or - for none
  plan     one letter per decision: r = right, w = wrong (rr, wr, rw, ww)
  a        what decision 1 should draw, for example ventana or puerta
  fast     speed (3 is good for a check, 1 is real speed)
  early    any word here: touch during the lead-in, before the question
  base-url default http://127.0.0.1:8765/historia/index.html
           (serve the repo first:  python3 -m http.server 8765)
  TL=1 in the environment prints when each spoken line starts and ends, and marks stretches with no voice.

Needs: pip install playwright, and a Chrome at /usr/bin/google-chrome (change the path below if it is elsewhere).
It reads the game through window.Story (see historia/juego.js)."""
import sys, asyncio, json, time, os
from playwright.async_api import async_playwright
OUT=sys.argv[1]; PLAN=sys.argv[2]; A=sys.argv[3]; FASTV=sys.argv[4] if len(sys.argv)>4 else "3"; EARLY=len(sys.argv)>5
BASE=sys.argv[6] if len(sys.argv)>6 else "http://127.0.0.1:8765/historia/index.html"
URL=f"{BASE}?fast={FASTV}&a={A}"
STATE="""()=>{const W=Story.W,p=Story.pending;return {live:p?p.live.join('|'):null,sign:p?p.sign:null,asked:p?p.asked:0,a:Story.V.a||'',b:Story.V.b||'',lost:W.lost,door:W.door,win:W.win,lamp:W.lamp,
 ab:W.ab?W.ab.en+'-'+W.ab.pose+'-'+(W.ab.bub||''):null,vis:W.cq.vis,cq:W.cq.x+','+W.cq.y,bub:W.cq.bub,storm:W.storm,rain:W.rain,wet:W.wet,gotas:W.gotas?1:0,tab:W.tab,spot:W.spot,dentro:W.dentro,heart:W.heart,
 running:Story.running,dots:document.querySelectorAll('.dot.on').length,nube:W.nube?Math.round(W.nube.tx):null,cam:Story.cam.map(Math.round).join(','),speaking:Story.speaking}}"""
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path="/usr/bin/google-chrome", args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
        ctx = await b.new_context(viewport={"width":390,"height":844}, device_scale_factor=2, is_mobile=True, has_touch=True)
        pg = await ctx.new_page(); msgs=[]
        pg.on("console", lambda m: msgs.append(m.type+": "+m.text)); pg.on("pageerror", lambda e: msgs.append("PAGEERROR: "+str(e)))
        await pg.goto(URL); await pg.wait_for_timeout(2500)
        print("ready:", await pg.evaluate("Story.ready"), "voice:", await pg.evaluate("Story.voice"), "clips:", await pg.evaluate("Story.clips"))
        cvs=pg.locator("#cv"); n=0
        async def snap(tag):
            nonlocal n
            if OUT=="-": return
            n+=1; await pg.wait_for_timeout(320); await cvs.screenshot(path=f"{OUT}/{n:02d}_{tag}.png")
        if os.environ.get("TL"):
            await pg.evaluate("""()=>{window.__t=[];const _p=playClip;playClip=function(id){const e={id,t0:performance.now()};__t.push(e);const pr=_p(id);pr.then(()=>{e.t1=performance.now();});return pr;};}""")
        t0=time.time(); await pg.click("#go")
        last=None; dec=0; seen=None; log=[]; done_tab=False
        for i in range(6000):
            await pg.wait_for_timeout(40)
            s=await pg.evaluate(STATE)
            sig=json.dumps({k:s[k] for k in ("live","sign","lost","door","win","lamp","ab","vis","storm","rain","tab","dentro","heart","dots","bub","gotas")})
            if sig!=last:
                last=sig; log.append(f"{time.time()-t0:5.1f}s d{s['dots']} live={s['live']} sign={s['sign']} a={s['a']} b={s['b']} lost={s['lost']} door={s['door']} win={s['win']} lamp={s['lamp']} ab={s['ab']} frog={'in' if not s['vis'] else s['cq']} bub={s['bub']} storm={s['storm']} nube={s['nube']} rain={s['rain']} wet={s['wet']} gotas={s['gotas']} tab={s['tab']} dentro={s['dentro']} heart={s['heart']} cam={s['cam']}")
                key=(s["lamp"],s["storm"],s["rain"],s["tab"],s["dentro"],s["heart"],s["ab"],s["sign"],s["lost"],s["win"],s["door"])
                if key!=seen:
                    seen=key; await snap(f"d{s['dots']}_L{s['lost']}_{'sign-'+s['sign'] if s['sign'] else ''}{'_lamp' if s['lamp'] else ''}{'_in-'+s['dentro'] if s['dentro'] else ''}{'_'+s['ab'] if s['ab'] else ''}{'_rain' if s['rain'] else ''}{'_'+s['tab'] if s['tab'] else ''}{'_heart' if s['heart'] else ''}")
            if s["live"] and (s["asked"] or EARLY):
                live=s["live"].split("|")
                if len(live)==1: tgt=live[0]
                else:
                    right=s["a"] if dec==0 else s["b"]; want=PLAN[dec] if dec<len(PLAN) else "r"
                    tgt=right if want=="r" else [x for x in live if x!=right][0]; dec+=1
                    log.append(f"        decision {dec}: the voice asked for {right}; touching {tgt}")
                    await snap(f"decision{dec}_waiting")
                await pg.wait_for_timeout(150); await pg.evaluate(f"Story.tapOn('{tgt}')"); await pg.wait_for_timeout(120)
            if not s["running"] and i>40: break
        await snap("end")
        print("\n".join(log)); print("took %.1fs at fast=%s"%(time.time()-t0,FASTV)); print("log:", await pg.evaluate("JSON.stringify(Story.log)"))
        if os.environ.get("TL"):
            tl=await pg.evaluate("__t"); base=tl[0]["t0"]; prev=None
            for e in tl:
                gap=(e["t0"]-prev["t1"])/1000 if prev and "t1" in prev else 0
                print("  %6.1fs  %-18s %.1fs%s"%((e["t0"]-base)/1000,e["id"],(e.get("t1",e["t0"])-e["t0"])/1000,("   <- %.1fs of no voice before this"%gap) if gap>=0.9 else "")); prev=e
        print("again button:", await pg.evaluate("getComputedStyle(document.querySelector('#again')).display"))
        for m in msgs[:12]: print("  ", m)
        await b.close()
asyncio.run(main())
