"use strict";
/* ============================================================
   Coquí · Repaso (¿Cuál?). The review session (docs/proyecto/10-leer-y-repaso.md).
   A sentence. Two pictures. Only one fits. He touches it.
   It asks up to 10 words a session: the ones that are due (the scheduler in palabras.js decides), most overdue first; the rest wait.
   With nothing due it plays words he has heard, and those answers do not move the schedule.
   Each answer goes into the word's ear record, with how long he took.
   No touch 6 s after the sentence ends: it plays again. 6 s after that the right picture is shown (green ring and the sign) and he touches it; that is a miss.
   A miss comes back once in the same session, three items later (or at the end), the pictures drawn in a new random order; that second ask is not scored and writes nothing.
   The end shows the session's words with their pictures: "Moving up" (right on the scored ask) and "Coming back soon" (missed). No score number.
   It reuses the scene drawing and the recorded lines of the stories; nothing new is recorded.
   ============================================================ */
let CU=null,PAN=null,CQ={i:0,lista:[],cola:[],hecho:[],rehecho:[],tt:[],fin:null};
const CAP=10,SIX=6000;   // the most words in a session; the silence (ms) after a sentence before it plays again, and again before the answer is shown
const EMPTY=Ex=>Object.assign({cq:{x:0,y:0,s:1,dy:0,al:1,vis:0,bub:null},spot:null,twinkle:null,fx:[],heart:0,lost:0,resp:null},(Ex||E).fresh(S));
// the pairs of every scene built so far (curso.js lists the files), each one drawn by its own scene
async function cualCarga(){const fs=(typeof CURSO!=="undefined"&&CURSO.cual)||["cual-frente"],out={id:"cual",title:"¿Cuál?",tipo:"cual",scene:"frente",stake:{thing:"none",steps:0},clips:{},items:[]};
  for(const f of fs){const j=await (await fetch("cuentos/"+f+".json",{cache:"no-store"})).json();await cargaEscena(j.scene);Object.assign(out.clips,j.clips);for(const it of j.items){for(const k of ["si","no"])if(it[k].esc)await cargaEscena(it[k].esc);out.items.push(Object.assign({esc:j.scene},it));}}
  return out;}
function panelW(spec,Ex){const w=EMPTY(Ex);w.cq={x:123,y:150,s:.86,dy:0,al:1,vis:spec.set&&spec.set.resp?1:0,bub:null};return Object.assign(w,JSON.parse(JSON.stringify(spec.set||{})));}
const PH=104;   // two panels, one above the other, each 196 x 104 art pixels
let GAP=12;     // the art pixels between them: set from the scale so that the gap on screen is at least 22 CSS px (16 between the rings of two options)
const gapFor=(kd,dpr)=>Math.ceil(22*dpr/kd);
// the options are drawn on the one canvas; over each picture sits an HTML frame (1.5 px, #4A4A52) that takes the touch and shows the answer as a ring
let OPT=[];
function mkOpts(n,onTouch){const o=$("#opts");o.innerHTML="";OPT=[];for(let k=0;k<n;k++){const d=document.createElement("button");d.className="opt";d.setAttribute("aria-label","Picture "+(k+1));d.addEventListener("pointerdown",e=>{e.preventDefault();onTouch(k);});o.appendChild(d);OPT.push(d);}}
function placeOpts(rects,kd,dpr){const z=kd/dpr;rects.forEach((r,k)=>{if(OPT[k])OPT[k].style.cssText=`left:${r[0]*z}px;top:${r[1]*z}px;width:${r[2]*z}px;height:${r[3]*z}px`;});}
function anillo(k,c){OPT.forEach((d,i)=>{if(k==null||i===k)d.classList.remove("ok","bad","sel");});if(k!=null&&c)OPT[k].classList.add(c);}   // anillo(null): no ring on any option
const opcionesVer=on=>{const o=$("#opts");if(o)o.style.visibility=on?"":"hidden";};   // no frames over an empty canvas
function cualSize(cols,rows,pw,ph){   // the block of cols x rows pictures of pw x ph art pixels: its size on screen, and sizing the canvas and the frames once the scale is known
  blockDim=(kd,dpr)=>{const g=gapFor(kd,dpr);return [(cols*pw+(cols-1)*g)*kd/dpr,(rows*ph+(rows-1)*g)*kd/dpr];};
  blockFit=(kd,dpr)=>{GAP=gapFor(kd,dpr);const w=cols*pw+(cols-1)*GAP,h=rows*ph+(rows-1)*GAP;if(cv.width!==w)cv.width=w;if(cv.height!==h)cv.height=h;cv.style.borderRadius="0";
    placeOpts([...Array(cols*rows).keys()].map(k=>[(k%cols)*(pw+GAP),Math.floor(k/cols)*(ph+GAP),pw,ph]),kd,dpr);};}
function dibujaPaneles(){const a=F>>1,keep=W;dc.imageSmoothingEnabled=false;dc.clearRect(0,0,cv.width,cv.height);opcionesVer(!!PAN);
  if(!PAN){return;}
  PAN.forEach((p,k)=>{W=p.w;W.fx=p.fx;p.E.draw(c,W,a);if(W.resp)respDraw(c,a);
    const y=k*(PH+GAP),cm=p.cam;dc.drawImage(sc,cm[0],cm[1],cm[2],cm[3],0,y,DW,PH);
    if(p.dim){dc.fillStyle="rgba(6,14,28,.55)";dc.fillRect(0,y,DW,PH);}});
  W=keep;}
function cualLoop(){F++;dibujaPaneles();}
async function cualItem(it,re){anillo(null);const ok=Math.random()<.5?0:1;   // which panel holds the right picture: drawn fresh at every ask, the second ask of a missed word too
  PAN=[0,1].map(k=>{const spec=k===ok?it.si:it.no,Ex=ESCENAS[spec.esc||it.esc];return {w:panelW(spec,Ex),E:Ex,cam:spec.cam,right:k===ok,fx:[],dim:0,sign:0};});   // a picture may name another scene to draw it
  await wait(500);const my=runId;let got=null,ms=0,tEnd=0,res;const p=new Promise(r=>res=r),T={i:CQ.i,w:it.w,re:!!re};CQ.tt.push(T);
  CQ.toque=k=>{if(!tEnd||got!=null)return;got=k;ms=Math.round((performance.now()-tEnd)*FAST);res();};   // a touch before the sentence ends does not count
  await say(it.say,0);tEnd=T.fin=performance.now();CQ.listo=CQ.i+1;
  // he waits: 6 s after the sentence ends it plays again (a touch while it plays counts); 6 s after that the right picture is shown, and that is a miss
  await Promise.race([p,wait(SIX)]);
  if(got==null){T.rep=performance.now();await Promise.race([p,say(it.say,0)]);if(got==null){T.repFin=performance.now();await Promise.race([p,wait(SIX)]);}}
  const auto=got==null;if(auto){ms=Math.round((performance.now()-tEnd)*FAST);T.auto=performance.now();}else if(speaking)hush();   // a touch while the sentence plays again stops it
  const right=auto?false:PAN[got].right;T.ok=right;
  if(!re){const vence=PAL.vence("ear").includes(it.w);   // due now, by the palabras clock (window.__PAL_NOW in a check), not Date.now()
    PAL.responde(it.w,"ear",right,ms,!vence);CQ.hecho.push(auto?{w:it.w,ok:false,ms,auto:1}:{w:it.w,ok:right,ms});}
  else CQ.rehecho.push({w:it.w,ok:right});   // the second ask of a missed word is not scored: nothing is written
  if(right){anillo(got,"ok");SFX.right();await bien("si_muy_bien");}   // a green ring on the right one
  else{let k;if(auto)k=PAN.findIndex(x=>x.right);   // he did not touch: the right picture is shown at once
    else{SFX.bonk();PAN[got].dim=1;anillo(got,"bad");await wait(500);k=1-got;}   // red-orange on his, then the green ring shows the right one
    PAN[k].sign=1;anillo(k,"ok");let res2;const p2=new Promise(r=>res2=r);   // the green ring and the sign: he touches it
    CQ.toque=t=>{if(t===k)res2();};await p2;PAN[k].sign=0;SFX.right();await bien("muy_bien");}
  await wait(400);return right;}
// which words this pass asks: the ones due, most overdue first; with nothing due, every word he has heard (those answers do not move the schedule)
function cualLista(){const due=PAL.vence("ear"),byW={};CU.items.forEach(it=>byW[it.w]=it);
  let lista=due.filter(w=>byW[w]).map(w=>byW[w]);
  if(!lista.length){const oidas=Object.keys(PAL.db.palabras).filter(w=>byW[w]);lista=(oidas.length&&!Q.get("todo")?oidas.map(w=>byW[w]):CU.items.slice());lista.sort(()=>Math.random()-.5);}
  if(Q.get("solo")){const so=Q.get("solo").split(",");lista=CU.items.filter(it=>so.includes(it.w));}   // for the machine check: only these words
  return lista.slice(0,+(Q.get("n")||CAP));}
async function cualRun(){runId++;hush();callaLetras();CQ.run=1;$("#go").style.display="none";pantalla("");foot(0,0,0);estado("play");
  await Promise.race([voiceReady,sleep(6000)]);
  const q=CQ.cola=CQ.lista.map(it=>({it,re:0}));CQ.hecho=[];CQ.rehecho=[];CQ.tt=[];CQ.fin=null;
  try{for(let i=0;i<q.length;i++){step(i);CQ.i=i;const ok=await cualItem(q[i].it,q[i].re);
      if(!ok&&!q[i].re){q.splice(Math.min(i+3,q.length),0,{it:q[i].it,re:1});mkDots(q.length);}}   // a miss comes back once, three items later (at the end when fewer are left); the bar grows by that one
    step(q.length);}catch(e){if(e!=="stop")throw e;return;}
  PAN=null;CQ.run=0;cualFin();}
// the end: the session's words, each with its picture, under "Moving up" (right on the scored ask) and "Coming back soon" (missed), and the way back to Palabras. No score.
function miniatura(it){const spec=it.si,Ex=ESCENAS[spec.esc||it.esc],keep=W,a=F>>1,t=document.createElement("canvas"),g=t.getContext("2d");t.width=DW;t.height=PH;g.imageSmoothingEnabled=false;
  W=panelW(spec,Ex);W.fx=[];Ex.draw(c,W,a);if(W.resp)respDraw(c,a);const cm=spec.cam;g.drawImage(sc,cm[0],cm[1],cm[2],cm[3],0,0,DW,PH);W=keep;   // the right picture of the word, drawn as it was in the session
  t.setAttribute("aria-hidden","true");return t;}
function cualGrupo(f,titulo,its){if(!its.length)return;const h=document.createElement("h2"),ul=document.createElement("ul");h.textContent=titulo;ul.className="gw";
  its.forEach(it=>{const li=document.createElement("li"),sp=document.createElement("span");sp.textContent=it.w;li.appendChild(miniatura(it));li.appendChild(sp);ul.appendChild(li);});f.appendChild(h);f.appendChild(ul);}
// the pictures are scaled by a whole number of screen pixels (kd); as many columns as fit at the biggest scale that fits, 16 px apart
function cualGrid(){const f=$("#fin"),us=f.querySelectorAll(".gw");if(!us.length)return;const dpr=window.devicePixelRatio||1,cs=getComputedStyle(f),w=Math.min(480,f.clientWidth-(parseFloat(cs.paddingLeft)||0)-(parseFloat(cs.paddingRight)||0));let best=null;
  for(const n of [3,2,1]){const kd=Math.floor(((w-(n-1)*16)/n)*dpr/DW+.001);if(kd>=1&&(!best||kd>best.kd))best={n,kd};}   // a tie goes to more columns
  if(!best)best={n:1,kd:1};us.forEach(u=>u.style.setProperty("--c",best.n));
  f.querySelectorAll(".gw canvas").forEach(t=>{t.style.width=DW*best.kd/dpr+"px";t.style.height=PH*best.kd/dpr+"px";});}
addEventListener("resize",()=>{if(CQ.fin)cualGrid();});
function cualFin(){const up=[],soon=[];CQ.lista.forEach(it=>{const h=CQ.hecho.find(x=>x.w===it.w);if(h)(h.ok?up:soon).push(it);});
  CQ.fin={up:up.map(x=>x.w),soon:soon.map(x=>x.w)};
  estado("end",true);pantalla("Done");const f=$("#fin");f.classList.add("lis");cualGrupo(f,"Moving up",up);cualGrupo(f,"Coming back soon",soon);f.scrollTop=0;cualGrid();
  $("#next").textContent="Back to Palabras";$("#next").classList.add("blu");$("#next").onclick=()=>salir("app.html?tab=palabras");foot(1,0,0);}
async function cualArranca(){CU=await cualCarga();S=CU;E=ESCENAS.frente;SW=E.SW;SH=E.SH;sc.width=SW;sc.height=SH;
  document.title="Coquí · ¿Cuál?";SALIDA="app.html?tab=palabras";W=EMPTY();cam=E.CAM.wide.slice();voiceReady=loadVoice();setInterval(cualLoop,TICK);
  cualSize(1,2,DW,PH);mkOpts(2,k=>{if(CQ.toque)CQ.toque(k);});
  CQ.lista=cualLista();mkDots(CQ.lista.length);estado("start",true);const n=CQ.lista.length,min=Math.max(1,Math.round(n*10/60));   // about 10 s a word
  pantalla("Review",n?[`${n} word${n===1?"":"s"} \u00b7 about ${min} min`]:[]);fit();   // the start screen: a title, how long it is, and the disc; the bar has its true number of segments from the start
  $("#go").onclick=()=>{try{ac().resume();}catch(e){}cualRun();};}
window.Cual={get pan(){return PAN?PAN.map(p=>({right:p.right,sign:p.sign})):null;},get i(){return CQ.i;},get listo(){return CQ.listo===CQ.i+1;},get lista(){return CQ.lista.map(x=>x.w);},get cola(){return CQ.cola.map(x=>({w:x.it.w,re:!!x.re}));},get hecho(){return CQ.hecho;},get rehecho(){return CQ.rehecho;},get tt(){return CQ.tt;},get fin(){return CQ.fin;},toca(k){if(CQ.toque)CQ.toque(k);},get running(){return !!CQ.run;},get speaking(){return speaking;}};
