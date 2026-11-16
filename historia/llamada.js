"use strict";
/* ============================================================
   Coquí · the call with Danny (Hablar tab).
   One object, `Llamada`, in its own scope: nothing here touches the story engine's globals, and the old test page's code is not used.
   It reads (never writes) the app's globals CURSO, CU (the ¿Cuál? items) and PAL (the records), and calls hush() and miniatura() once each.
   The call: a speaking call. Danny talks, the page shows his last line, the picture he asks for, and what it heard the learner say.
   Every word of the place the learner says becomes a mouth record: PAL.responde(word,"mouth",true,ms).
   The page ends the call (Danny cannot hang up): "(fin)" at 6 minutes, or from 2 minutes when the learner says adiós / hasta mañana;
   then the session ends when Danny has finished his goodbye (15 s at the latest); 7 minutes is the hard stop.
   Test without a real call: add ?callstub=1 to app.html. A fake Conversation then walks through the modes (see installStub below);
   without that parameter nothing here can place a call from anywhere but a tap on the green disc.
   ============================================================ */
const Llamada=(()=>{
  const Q=new URLSearchParams(location.search),STUB=Q.get("callstub")==="1",STUBOPT=new Set((Q.get("stub")||"").split(",")),CLK=STUB?Math.max(1,+(Q.get("clock")||1)||1):1;   // CLK: the stub's fast clock (call time runs CLK times faster)
  const AGENT="agent_3301m795q3xtfpx8c99zc0s870vm",SDK="https://cdn.jsdelivr.net/npm/@elevenlabs/client@1.25.0/+esm";
  const BYE_FROM=120,FIN_AT=360,MAX_AT=420,FIN_CAP=15000;   // seconds of call time; the 15 s cap after "(fin)" is real time
  // the calls built so far: place id -> what Danny is told. Only La casa has one in version 1.
  const LLAMADAS={casa:{minutos:5,job:"Say hello, say who you are, accept a drink, say thanks and say goodbye.",opening:"¡Hola! Soy Danny. ¿Cómo estás?",foto:"casa"}};
  const norm=s=>" "+String(s==null?"":s).toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g,"").replace(/[^a-z0-9]+/g," ").trim()+" ";   // accents, case and punctuation ignored
  const dice=(texto,palabra)=>{const w=norm(palabra);return w.trim()!==""&&texto.indexOf(w)>=0;};   // does the normalised text hold the word or phrase, on word boundaries
  const safe=(f,d)=>{try{const v=f();return v==null?d:v;}catch(e){return d;}};
  const SVGI=p=>`<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${p}</svg>`;
  const IC={x:SVGI('<path d="M6 6l12 12M18 6L6 18"/>'),phone:SVGI('<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>'),mic:SVGI('<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>')};

  /* ---------- the place's words ---------- */
  const PW={};   // place id -> promise of its words (the focus_words of its stories)
  function palabrasDe(l){if(PW[l.id])return PW[l.id];
    return PW[l.id]=Promise.all((l.cuentos||[]).map(c=>fetch("cuentos/"+c+".json").then(r=>r.ok?r.json():null).catch(()=>null))).then(js=>{const out=[];
      js.forEach(j=>{if(j&&(!j.place||j.place===l.nombre))(j.focus_words||[]).forEach(w=>{if(!out.includes(w))out.push(w);});});
      if(!out.length)delete PW[l.id];return out;});}
  const abierta=w=>{const r=PAL.db.palabras[w];return !!(r&&r.ear&&r.ear.etapa>=3);};   // open for speaking: the ear has held it

  /* ---------- the voice library: preloaded when Hablar opens, never imported inside the tap ---------- */
  let SDKP=null;
  function precarga(){if(window.ELConv)return Promise.resolve(true);if(SDKP)return SDKP;
    SDKP=new Promise(res=>{addEventListener("elconv",()=>{if(!window.ELConv)SDKP=null;res(!!window.ELConv);},{once:true});
      const s=document.createElement("script");s.type="module";
      s.textContent='try{const m=await import("'+SDK+'");window.ELConv=m.Conversation;}catch(e){window.ELConvError=String(e);}dispatchEvent(new Event("elconv"));';
      document.head.appendChild(s);});
    return SDKP;}

  /* ---------- the stub (only with ?callstub=1) ----------
     A fake Conversation: startSession() resolves a fake call that walks through the modes, sends two of Danny's lines
     (the second asks for a picture) and learner lines, then, after 2 minutes of call time, a learner "Adiós.", and answers "(fin)" with a goodbye.
     ?stub=manual   nothing moves by itself; step with CallStub.go("connect"), ("danny1") ... (names in CallStub.names)
     ?stub=mic      the microphone is refused;  ?stub=fail  the call does not start;  ?stub=nofin  Danny does not answer "(fin)"  (join with commas: stub=manual,nofin)
     ?clock=N       the call's clock runs N times faster (timer, 2 / 6 / 7 minutes); the 15 s cap stays real. The walk takes about 15 s: use clock=6 to see "Adiós." after 2 call-minutes */
  function installStub(){if(window.ELConv)return;
    const S=window.CallStub={sent:[],opts:null,ended:false,names:[],log:[]};
    const ph={inp:"quiet",say:0};
    window.ELConv={startSession(o){S.opts=o;S.o=o;return new Promise((res,rej)=>{
      if(STUBOPT.has("mic")){setTimeout(()=>{const e=new Error("Permission denied");e.name="NotAllowedError";rej(e);},400);return;}
      if(STUBOPT.has("fail")){setTimeout(()=>rej(new Error("The call did not start.")),600);return;}
      let t0=0;const mode=m=>{S.log.push(m);o.onModeChange&&o.onModeChange({mode:m});},
        msg=(who,t)=>{o.onMessage&&o.onMessage(who==="user"?{role:"user",source:"user",message:t}:{role:"agent",source:"ai",message:t});};
      const c={sendUserMessage(t){S.sent.push(t);if(t==="(fin)"&&!STUBOPT.has("nofin"))setTimeout(()=>{ph.say=1;mode("speaking");msg("agent","Eso. Hasta mañana.");setTimeout(()=>{ph.say=0;mode("listening");},2000);},400);},
        endSession(){if(S.ended)return Promise.resolve();S.ended=true;setTimeout(()=>o.onDisconnect&&o.onDisconnect({reason:"user"}),30);return Promise.resolve();},
        getInputVolume(){return ph.inp==="talk"?.10+.08*Math.abs(Math.sin(performance.now()/90))+Math.random()*.04:.004;},
        getOutputVolume(){return ph.say?.10+.10*Math.abs(Math.sin(performance.now()/130)):0;},setMicMuted(){}};
      const steps={connect(){t0=performance.now();o.onConnect&&o.onConnect({conversationId:"stub"});res(c);},
        danny1(){ph.say=1;mode("speaking");msg("agent","¡Hola! Soy Danny. ¿Cómo estás?");},
        you1(){ph.say=0;ph.inp="quiet";mode("listening");},talk1(){ph.inp="talk";},quiet1(){ph.inp="quiet";},heard1(){msg("user","Hola. Bien, gracias.");},
        danny2(){ph.inp="quiet";ph.say=1;mode("speaking");msg("agent","Eso. Mira. ¿Quieres jugo?");setTimeout(()=>{try{o.clientTools.show_picture({picture:"jugo"});}catch(e){}},500);},
        you2(){ph.say=0;ph.inp="quiet";mode("listening");},talk2(){ph.inp="talk";},quiet2(){ph.inp="quiet";},heard2(){msg("user","Sí, quiero jugo.");},
        you3(){ph.say=0;ph.inp="quiet";mode("listening");},talk3(){ph.inp="talk";},quiet3(){ph.inp="quiet";},heard3(){msg("user","Adiós.");},
        end(){S.ended=true;o.onDisconnect&&o.onDisconnect({reason:"agent"});}};
      S.names=Object.keys(steps);S.go=n=>{if(S.ended&&n!=="connect")return;steps[n]();};
      if(STUBOPT.has("manual"))return;   // the test steps it: CallStub.go("connect"), ...
      const seq=[["connect",1200],["danny1",2800],["you1",700],["talk1",1500],["quiet1",900],["heard1",1100],["danny2",3000],["you2",700],["talk2",1500],["quiet2",900],["heard2",0]];
      let i=0;const next=()=>{if(S.ended)return;if(i<seq.length){const [n,d]=seq[i++];steps[n]();setTimeout(next,d);return;}
        // then the call idles until 2 minutes and a few seconds of call time have passed, and the learner says goodbye
        const wait=Math.max(1500,(BYE_FROM+5)/CLK*1000-(performance.now()-t0));
        setTimeout(()=>{steps.you3();setTimeout(()=>{steps.talk3();setTimeout(()=>{steps.quiet3();setTimeout(()=>steps.heard3(),900);},1200);},500);},wait);};
      next();});}};}
  if(STUB)installStub();

  /* ---------- the screen ---------- */
  const CSS=`
#llam{position:fixed;left:0;top:0;right:0;bottom:0;z-index:40;background:#1B1B1F;color:#fff;overflow:hidden;font:400 16px/1.5 system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  display:grid;grid-template-columns:minmax(0,1fr);grid-template-rows:auto minmax(0,1fr) auto;grid-template-areas:"bar" "main" "zone";padding-top:env(safe-area-inset-top)}
#llam *{box-sizing:border-box}
#llam button{font:inherit;color:inherit;cursor:pointer}
#llam .lb{grid-area:bar;display:flex;align-items:center;justify-content:space-between;height:56px;padding:8px 16px 0 8px}
#llam .lx{width:48px;height:48px;border:0;border-radius:24px;background:none;display:flex;align-items:center;justify-content:center;color:#fff}
#llam .lx svg{width:24px;height:24px}
#llam .lt{font-size:12px;line-height:16px;font-weight:500;color:#A7A7B0;font-variant-numeric:tabular-nums}
#llam .lm{grid-area:main;min-height:0;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:0 16px}
#llam .lp{flex:none;line-height:0}
#llam canvas{display:block;image-rendering:pixelated;image-rendering:crisp-edges;background:#222;box-shadow:0 0 0 1.5px #4A4A52}
#llam .ltx{flex:none;width:100%;max-width:560px;margin-top:16px}
#llam .ld{width:100%;height:48px;font-size:18px;line-height:24px;text-align:center;color:#fff;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical}
#llam .ld.q{color:#A7A7B0;font-size:16px}
#llam .lh{width:100%;height:24px;margin-top:8px;font-size:16px;line-height:24px;text-align:center;color:#9AD5A8;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#llam .lz{grid-area:zone;display:flex;flex-direction:column;align-items:center;padding:0 16px calc(32px + env(safe-area-inset-bottom))}
#llam .lmic{position:relative;flex:none;width:96px;height:96px;display:flex;align-items:center;justify-content:center}
#llam .ldisc{position:relative;z-index:2;width:72px;height:72px;border:0;border-radius:36px;padding:0;background:#17803F;color:#fff;display:flex;align-items:center;justify-content:center;transition:background .12s}
#llam .ldisc svg{width:32px;height:32px}
#llam .ldisc .ims,#llam .ldisc .imm,#llam .ldisc .dts{display:none}
#llam[data-s=idle] .ldisc .ims,#llam[data-s=connecting] .ldisc .ims,#llam[data-s=danny] .ldisc .imm,#llam[data-s=you] .ldisc .imm{display:flex}
#llam[data-s=proc] .ldisc .dts{display:flex;gap:6px}
#llam .dts i{width:9px;height:9px;border-radius:50%;background:#fff;animation:ldot 1s infinite}.dts i:nth-child(2){animation-delay:.18s}.dts i:nth-child(3){animation-delay:.36s}
@keyframes ldot{0%,70%,100%{opacity:.3;transform:scale(.8)}35%{opacity:1;transform:scale(1.15)}}
#llam[data-s=danny] .ldisc,#llam[data-s=proc] .ldisc{background:#2B2B33}
#llam[data-s=danny] .ldisc .imm{color:#A7A7B0}
#llam[data-s=connecting] .ldisc{animation:lpul .9s ease-in-out infinite}
@keyframes lpul{50%{transform:scale(1.1)}}
#llam .lw{position:absolute;left:12px;top:12px;width:72px;height:72px;border-radius:50%;border:3px solid #3B5BDB;opacity:0;pointer-events:none;z-index:1}
#llam[data-s=danny] .lw{animation:lwave 1.5s ease-out infinite}#llam[data-s=danny] .lw:nth-child(2){animation-delay:.5s}#llam[data-s=danny] .lw:nth-child(3){animation-delay:1s}
@keyframes lwave{0%{transform:scale(1);opacity:.85}100%{transform:scale(var(--wv,1.5));opacity:0}}
#llam .lg{position:absolute;left:12px;top:12px;width:72px;height:72px;border-radius:50%;box-shadow:0 0 0 var(--rt,3px) #3FAE6B;opacity:0;pointer-events:none;transition:box-shadow .08s linear}
#llam[data-s=you] .lg{opacity:1}
#llam .ll{flex:none;margin-top:8px;min-height:24px;font-size:16px;line-height:24px;font-weight:600;color:#fff;text-align:center}
#llam .lo{flex:none;min-height:20px;margin-top:4px;font-size:14px;line-height:20px;color:#A7A7B0;text-align:center}
#llam .lhelp{flex:none;min-width:136px;min-height:48px;margin-top:12px;padding:0 24px;border:1.5px solid #4A4A52;border-radius:12px;background:transparent;font-weight:600;color:#fff;transition:background .15s}
#llam .lhelp.p{background:#33333B}
#llam[data-s=idle] .lhelp,#llam[data-s=connecting] .lhelp{visibility:hidden}
#llam .lerr,#llam .lsum{display:none}
#llam[data-s=err] .lm,#llam[data-s=err] .lz,#llam[data-s=done] .lm,#llam[data-s=done] .lz{display:none}
#llam[data-s=err] .lerr{grid-row:2/4;grid-column:1/-1;display:flex;align-items:center;justify-content:center;padding:0 24px;text-align:center;font-size:18px;line-height:24px}
#llam[data-s=done] .lsum{grid-row:2/4;grid-column:1/-1;display:flex;flex-direction:column;min-height:0;padding:0 16px calc(24px + env(safe-area-inset-bottom));width:100%;max-width:560px;margin:0 auto}
#llam[data-s=done] .lt{visibility:hidden}
#llam .lsb{flex:1;min-height:0;overflow:auto;padding-top:calc(35vh - 56px)}
#llam .lsb h1{margin:0 0 8px;font-size:24px;line-height:32px;font-weight:600;color:#fff}
#llam .lsb p{margin:0;font-size:16px;line-height:24px;color:#C9C9D1}
#llam .lchips{display:flex;flex-wrap:wrap;gap:8px;margin-top:16px}
#llam .lchips span{display:inline-flex;align-items:center;min-height:32px;padding:0 12px;border:1.5px solid #4A4A52;border-radius:16px;font-size:14px;color:#fff}
#llam .lbk{flex:none;width:100%;min-height:56px;margin-top:16px;border:0;border-radius:12px;background:#3B5BDB;color:#fff;font-weight:600}
@media (orientation:landscape) and (max-height:500px){
  #llam{grid-template-columns:auto minmax(280px,1fr);grid-template-rows:auto 1fr auto;grid-template-areas:"main bar" "main txt" "main zone";padding-top:0}
  #llam .lb{padding:8px 16px 0 8px}
  #llam .lm{display:contents}
  #llam .lp{grid-area:main;align-self:center;margin:0 16px;padding:0}
  #llam .ltx{grid-area:txt;align-self:start;padding:0 16px 0 0;min-width:0}
  #llam .ltx{margin-top:0;max-width:none}#llam .ld{text-align:left}#llam .lh{text-align:left}
  #llam .lz{display:grid;grid-template-columns:96px minmax(0,1fr);column-gap:8px;align-items:center;justify-items:start;padding:0 16px 16px 0}
  #llam .lmic{grid-row:1/4}#llam .ll,#llam .lo{text-align:left;margin-top:0}#llam .lhelp{margin-top:8px}
  #llam[data-s=done] .lsum{grid-row:2/4;grid-column:1/-1}#llam[data-s=err] .lerr{grid-row:2/4}
  #llam .lsb{padding-top:8px}
}
@media (prefers-reduced-motion:reduce){#llam *{animation:none!important;transition:none!important}}`;
  const ltxHTML='<div class="ltx"><div class="ld"></div><div class="lh"></div></div>';
  let UI=null,LOCK=false,RUN=0,CALL=null;   // LOCK: one call at a time, from the tap until everything is cleaned up

  function est(s,label){if(!UI)return;UI.root.dataset.s=s;ST=s;
    const L={idle:"Start call",connecting:"Calling…",danny:"Danny",you:"Your turn",proc:"One moment"};if(L[s])UI.ll.textContent=L[s];
    UI.disc.setAttribute("aria-label",s==="idle"?"Start call":L[s]||"");}
  let ST="idle";

  function fit(){if(!UI)return;const dpr=window.devicePixelRatio||1,land=matchMedia("(orientation:landscape) and (max-height:500px)").matches,vw=document.documentElement.clientWidth||innerWidth,vh=innerHeight;
    // whole-number scale: device pixels per art pixel = the largest that fits (the picture may be smaller than the screen)
    const aw=land?vw-16-16-16-300:Math.min(vw,560)-32,ah=land?vh-32:vh-56-248-48-24-40;
    const s=Math.max(1,Math.min(Math.floor(aw*dpr/196),Math.floor(ah*dpr/104)));
    UI.cv.style.width=196*s/dpr+"px";UI.cv.style.height=104*s/dpr+"px";}

  function dibuja(w){const it=(CU&&CU.items||[]).find(x=>norm(x.w)===norm(w));if(!it)return false;
    try{miniatura(UI.cv,it.si,it.esc);}catch(e){return false;}return true;}   // the same drawing as a Palabras card: the "si" picture of the word's pair

  function abre(id,o){if(LOCK||UI)return;const l=CURSO.lugares.find(x=>x.id===id),cfg=LLAMADAS[id];if(!l||!cfg)return;
    if(!document.getElementById("llam-css")){const s=document.createElement("style");s.id="llam-css";s.textContent=CSS;document.head.appendChild(s);}
    const root=document.createElement("div");root.id="llam";root.setAttribute("role","dialog");root.setAttribute("aria-label","Call Danny");
    root.innerHTML=`<div class="lb"><button class="lx" aria-label="Close">${IC.x}</button><span class="lt" aria-hidden="true">00:00</span></div>
      <div class="lm"><div class="lp"><canvas width="196" height="104"></canvas></div>${ltxHTML}</div>
      <div class="lerr" role="alert"></div>
      <div class="lsum"><div class="lsb"><h1>Call done</h1><p class="ls1"></p><div class="lchips"></div></div><button class="lbk">Back to Hablar</button></div>
      <div class="lz"><div class="lmic"><i class="lw"></i><i class="lw"></i><i class="lw"></i><i class="lg"></i><button class="ldisc"><span class="ims">${IC.phone}</span><span class="imm">${IC.mic}</span><span class="dts"><i></i><i></i><i></i></span></button></div>
        <div class="ll" aria-live="polite"></div><div class="lo" aria-live="polite"></div><button class="lhelp">Help</button></div>`;
    document.body.appendChild(root);document.body.style.overflow="hidden";
    const q=s=>root.querySelector(s);
    UI={root,cv:q("canvas"),ld:q(".ld"),lh:q(".lh"),ll:q(".ll"),lo:q(".lo"),lt:q(".lt"),disc:q(".ldisc"),help:q(".lhelp"),err:q(".lerr"),sum:q(".lsum"),alCerrar:o&&o.alCerrar};
    CALL={id,l,cfg,words:null,said:new Map(),conv:null,t0:0,done:0,fin:null,mode:"listening",turn:null,floor:.008,lvl:0,last:""};
    UI.disc.onclick=()=>{if(ST==="idle")inicia();};UI.help.onclick=ayuda;q(".lx").onclick=cierraX;q(".lbk").onclick=cierra;
    addEventListener("resize",fit);
    const dib=dibuja(cfg.foto||"casa");UI.cv.style.visibility=dib?"":"hidden";
    UI.ld.textContent=l.nombre+" · about "+cfg.minutos+" min";UI.ld.classList.add("q");
    est("idle");fit();
    palabrasDe(l);precarga();}   // the words and the library are ready before the tap

  function cierra(){if(!UI)return;removeEventListener("resize",fit);const al=UI.alCerrar;UI.root.remove();UI=null;CALL=null;document.body.style.overflow="";if(al)try{al();}catch(e){}}
  function cierraX(){if(!UI)return;
    if(CALL&&CALL.t0&&!CALL.done){finish("x");return;}   // a live call: the X ends it, with the summary
    if(CALL&&!CALL.t0&&LOCK){RUN++;CALL.done=1;stopTimers();LOCK=false;}   // still calling: hang up before it picks up (a late answer is ended below)
    cierra();}

  function fallo(texto){if(!UI)return;CALL.done=1;stopTimers();UI.err.textContent=texto;est("err");LOCK=false;}   // one plain line and the X

  /* ---------- the call ---------- */
  let LOOP=0,CAP=0;
  function stopTimers(){clearInterval(LOOP);LOOP=0;clearTimeout(CAP);CAP=0;}
  const elapsed=()=>CALL&&CALL.t0?(performance.now()-CALL.t0)/1000*CLK:0;
  const mmss=s=>{s=Math.floor(s);return String(Math.floor(s/60)).padStart(2,"0")+":"+String(s%60).padStart(2,"0");};

  async function inicia(){if(LOCK||!UI||!CALL||ST!=="idle")return;LOCK=true;const my=++RUN,C=CALL;
    try{hush();SFX.calla();callaLetras();}catch(e){}   // every other sound stops before the microphone opens
    try{if(AC)AC.suspend();}catch(e){}
    est("connecting");UI.ld.textContent="";UI.ld.classList.remove("q");
    let words;try{words=await palabrasDe(C.l);}catch(e){words=[];}
    if(my!==RUN)return;if(!words.length){fallo("The call did not start. Check your connection and try again.");return;}
    C.words=words;const abiertas=words.filter(abierta),oidas=words.filter(w=>!abierta(w));
    if(!await precarga()||!window.ELConv){if(my===RUN)fallo("The voice part did not load. Check your connection and try again.");return;}
    if(my!==RUN)return;
    const vars={place:C.l.nombre,job:C.cfg.job,words_open:abiertas.length?abiertas.join(", "):"(none yet)",words_heard:oidas.length?oidas.join(", "):"(none yet)",minutes:String(C.cfg.minutos),opening:C.cfg.opening};
    let conv;
    try{conv=await window.ELConv.startSession({agentId:AGENT,connectionType:"websocket",dynamicVariables:vars,
      clientTools:{show_picture:p=>{if(my===RUN)muestra(p);return "shown";}},
      onConnect:()=>conecta(my),onDisconnect:d=>desconecta(my,d),onError:e=>{if(CALL===C)C.err=String((e&&e.message)||e||"");},
      onMessage:m=>mensaje(my,m),onModeChange:m=>modo(my,m&&m.mode)});}
    catch(e){if(my!==RUN)return;const t=String((e&&e.name)||"")+" "+String((e&&e.message)||e||"");
      fallo(/NotAllowed|PermissionDenied|NotFound|Permission|microphone|denied/i.test(t)?"The microphone is off. Allow it in your browser to call.":"The call did not start. Check your connection and try again.");return;}
    if(my!==RUN){try{conv.endSession();}catch(e){}return;}   // he closed the screen while it was still calling
    C.conv=conv;}

  function conecta(my){if(my!==RUN||!CALL||CALL.t0)return;CALL.t0=performance.now();est("danny");UI.lt.textContent="00:00";
    LOOP=setInterval(bucle,50);}

  function desconecta(my,d){if(my!==RUN||!CALL||CALL.done)return;
    if(!CALL.t0){fallo(CALL.err&&/microphone|permission/i.test(CALL.err)?"The microphone is off. Allow it in your browser to call.":"The call did not start. Check your connection and try again.");return;}
    finish("disc");}

  function modo(my,m){if(my!==RUN||!CALL||CALL.done)return;const C=CALL,antes=C.mode;C.mode=m;
    if(C.fin){if(m==="speaking")C.fin.seen=true;else if(m==="listening"&&C.fin.seen){C.fin.seen=false;if(--C.fin.n<=0){setTimeout(()=>{if(CALL===C)finish("fin");},400);}}}
    if(!C.t0)return;
    if(m==="speaking"){C.turn=null;est("danny");}
    else if(m==="listening"){C.turn={t:performance.now(),loud0:0,lastLoud:0,onset:0,spoke:0};UI.lh.textContent="";C.lvl=0;UI.root.style.setProperty("--rt","3px");est("you");}}

  function mensaje(my,m){if(my!==RUN||!CALL||CALL.done||!m)return;const C=CALL,text=m.message||m.text;if(!text)return;
    const user=m.role==="user"||m.source==="user";
    if(!user){C.last=text;UI.ld.classList.remove("q");UI.ld.textContent=text;return;}
    if(/^\s*\(/.test(text))return;   // our own "(ayuda)" and "(fin)" come back as messages: they are not his words
    UI.lh.textContent=text;UI.lh.title=text;
    if(ST==="you")est("proc");   // his line is in: Danny is about to answer
    oye(text);
    const n=norm(text);
    if(!C.fin&&elapsed()>=BYE_FROM&&(dice(n,"adiós")||dice(n,"hasta mañana")))enviaFin();}

  // every word of the place he said (once per call each) becomes a mouth record; ms = how long he took to start speaking
  function oye(text){const C=CALL,n=norm(text),ms=C.turn&&C.turn.onset?Math.max(0,Math.round(C.turn.onset-C.turn.t)):null;
    (C.words||[]).forEach(w=>{if(C.said.has(w)||!dice(n,w))return;C.said.set(w,ms);try{PAL.responde(w,"mouth",true,ms);}catch(e){}});}

  function muestra(p){if(!UI||!CALL||CALL.done)return;let k=p;if(p&&typeof p==="object")k=p.picture||p.key||p.word||p.name||p.id||"";
    const n=norm(k),w=(CALL.words||[]).find(x=>norm(x)===n);if(!w)return;   // only a word of this place; anything else is ignored
    if(dibuja(w)){UI.cv.style.visibility="";}}

  function ayuda(){if(!UI||!CALL||!CALL.t0||CALL.done||!CALL.conv)return;
    enviar("(ayuda)");UI.help.classList.add("p");setTimeout(()=>UI&&UI.help.classList.remove("p"),600);
    UI.lo.textContent="Danny will say it again, slowly.";clearTimeout(CALL.noteT);const C=CALL;C.noteT=setTimeout(()=>{if(UI&&CALL===C)UI.lo.textContent="";},5000);}
  function enviar(t){try{if(CALL&&CALL.conv)CALL.conv.sendUserMessage(t);}catch(e){}}

  // the page ends the call: "(fin)", then the session ends when Danny has finished his goodbye (15 s at the latest)
  function enviaFin(){const C=CALL;if(!C||C.fin||C.done)return;
    C.fin={n:C.mode==="speaking"?2:1,seen:C.mode==="speaking"};   // if he is mid-line, that line ends first: the goodbye is the second one
    enviar("(fin)");CAP=setTimeout(()=>{if(CALL===C)finish("cap");},FIN_CAP);}

  function bucle(){const C=CALL;if(!C||!UI||C.done||!C.t0)return;const el=elapsed();
    const t=mmss(el);if(UI.lt.textContent!==t)UI.lt.textContent=t;
    if(C.conv){
      if(ST==="danny"){const o=safe(()=>C.conv.getOutputVolume(),0);UI.root.style.setProperty("--wv",(1.3+Math.min(1,o*4)*.6).toFixed(2));}
      if(ST==="you"&&C.turn){const raw=safe(()=>C.conv.getInputVolume(),0),thr=C.floor+.025,loud=raw>thr,now=performance.now();   // the level: a quiet floor that follows the room, and a threshold just above it
        if(!loud)C.floor=C.floor*.98+raw*.02;
        const target=loud?Math.min(1,(raw-C.floor)*5):0;C.lvl+=(target-C.lvl)*.5;UI.root.style.setProperty("--rt",(3+C.lvl*9).toFixed(1)+"px");
        if(loud){C.turn.lastLoud=now;if(!C.turn.loud0)C.turn.loud0=now;if(now-C.turn.loud0>=100){C.turn.spoke=1;if(!C.turn.onset)C.turn.onset=C.turn.loud0;}}
        else{C.turn.loud0=0;if(C.turn.spoke&&now-C.turn.lastLoud>=300)est("proc");}}}   // he spoke, and has been quiet for 300 ms: the dots, until Danny speaks
    if(!C.fin&&el>=FIN_AT)enviaFin();
    if(el>=MAX_AT)finish("max");}

  // every way out ends here once: the session, the timers, the lock
  function finish(why){const C=CALL;if(!C||C.done)return;C.done=1;stopTimers();
    const secs=elapsed(),conv=C.conv;C.conv=null;try{if(conv)conv.endSession();}catch(e){}
    LOCK=false;clearTimeout(C.noteT);
    if(!UI)return;
    const dicho=[...C.said.keys()],min=Math.max(1,Math.round(secs/60));
    UI.sum.querySelector(".ls1").textContent=min+" min · "+dicho.length+" word"+(dicho.length===1?"":"s")+" said";
    UI.sum.querySelector(".lchips").innerHTML=dicho.map(w=>`<span>${w.replace(/[<>&]/g,"")}</span>`).join("");
    C.why=why;est("done");}
  addEventListener("pagehide",()=>{const C=CALL;if(C&&C.conv){const c=C.conv;C.conv=null;C.done=1;stopTimers();try{c.endSession();}catch(e){}LOCK=false;}});

  return {abre,precarga,tiene:id=>!!LLAMADAS[id],minutos:id=>LLAMADAS[id].minutos,cierra,
    get estado(){return ST;},get activo(){return !!UI;},get ocupado(){return LOCK;},
    get dicho(){return CALL?[...CALL.said.keys()]:[];},get fin(){return !!(CALL&&CALL.fin);},get motivo(){return CALL?CALL.why||"":"";},
    palabras:id=>{const l=CURSO.lugares.find(x=>x.id===id);return palabrasDe(l);},
    norm,dice};
})();
