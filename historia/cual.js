"use strict";
/* ============================================================
   Coquí · ¿Cuál? The next-day pass.
   A sentence. Two pictures. Only one fits. He touches it.
   It asks the words that are due (the scheduler in palabras.js decides), most overdue first.
   With nothing due it plays every word he has heard, and those answers do not move the schedule.
   Each answer goes into the word's ear record, with how long he took.
   It reuses the scene drawing and the recorded lines of the stories; nothing new is recorded.
   ============================================================ */
let CU=null,PAN=null,CQ={i:0,lista:[],hecho:[]};
const EMPTY=Ex=>Object.assign({cq:{x:0,y:0,s:1,dy:0,al:1,vis:0,bub:null},spot:null,twinkle:null,fx:[],heart:0,lost:0,resp:null},(Ex||E).fresh(S));
// the pairs of every scene built so far (curso.js lists the files), each one drawn by its own scene
async function cualCarga(){const fs=(typeof CURSO!=="undefined"&&CURSO.cual)||["cual-frente"],out={id:"cual",title:"¿Cuál?",tipo:"cual",scene:"frente",stake:{thing:"none",steps:0},clips:{},items:[]};
  for(const f of fs){const j=await (await fetch("cuentos/"+f+".json",{cache:"no-store"})).json();await cargaEscena(j.scene);Object.assign(out.clips,j.clips);for(const it of j.items){for(const k of ["si","no"])if(it[k].esc)await cargaEscena(it[k].esc);out.items.push(Object.assign({esc:j.scene},it));}}
  return out;}
function panelW(spec,Ex){const w=EMPTY(Ex);w.cq={x:123,y:150,s:.86,dy:0,al:1,vis:spec.set&&spec.set.resp?1:0,bub:null};return Object.assign(w,JSON.parse(JSON.stringify(spec.set||{})));}
const PH=104,GAP=8;   // two panels, one above the other
function dibujaPaneles(){const a=F>>1,keep=W;dc.imageSmoothingEnabled=false;dc.fillStyle="#0E1A24";dc.fillRect(0,0,DW,DH);
  if(!PAN){return;}
  PAN.forEach((p,k)=>{W=p.w;W.fx=p.fx;p.E.draw(c,W,a);if(W.resp)respDraw(c,a);
    W.fx=W.fx.filter(e=>F-e.f0<e.n);W.fx.forEach(e=>{if(e.t==="star")e.pts.forEach((q,i)=>star(c,q[0],q[1],(i+a)%2?4:2,(i+a)%2));});
    const y=k*(PH+GAP),cm=p.cam;dc.drawImage(sc,cm[0],cm[1],cm[2],cm[3],0,y,DW,PH);
    if(p.dim){dc.fillStyle="rgba(6,14,28,.55)";dc.fillRect(0,y,DW,PH);}
    if(p.sign){const e=(F>>1)%4<2?0:2;dc.fillStyle=OUT;[[0,y,DW,4+e],[0,y+PH-4-e,DW,4+e],[0,y,4+e,PH],[DW-4-e,y,4+e,PH]].forEach(r=>dc.fillRect(...r));
      dc.fillStyle=e?"#FFF4B0":"#FFE040";[[1,y+1,DW-2,2+e],[1,y+PH-3-e,DW-2,2+e],[1,y+1,2+e,PH-2],[DW-3-e,y+1,2+e,PH-2]].forEach(r=>dc.fillRect(...r));
      hand(dc,DW-48,y+PH-50,(F>>2)%2===1,3);}});
  W=keep;}
function cualLoop(){F++;dibujaPaneles();}
async function cualItem(it){const ok=Math.random()<.5?0:1;   // which panel holds the right picture: drawn fresh
  PAN=[0,1].map(k=>{const spec=k===ok?it.si:it.no,Ex=ESCENAS[spec.esc||it.esc];return {w:panelW(spec,Ex),E:Ex,cam:spec.cam,right:k===ok,fx:[],dim:0,sign:0};});   // a picture may name another scene to draw it
  await wait(500);const my=runId;let got=null,ms=0,tEnd=0,res;const p=new Promise(r=>res=r);
  CQ.toque=k=>{if(!tEnd||got!=null)return;got=k;ms=Math.round((performance.now()-tEnd)*FAST);res();};   // a touch before the sentence ends does not count
  await say(it.say,0);tEnd=performance.now();CQ.listo=CQ.i+1;
  const rep=setInterval(()=>{if(got==null&&!speaking&&my===runId)playClip(it.say);},9000/FAST);   // he waits: the sentence again. It costs nothing.
  await p;clearInterval(rep);const right=PAN[got].right;
  const vence=!!(PAL.db.palabras[it.w]&&PAL.db.palabras[it.w].ear.due<=Date.now());
  PAL.responde(it.w,"ear",right,ms,!vence);CQ.hecho.push({w:it.w,ok:right,ms});
  const sig=k=>{SFX.right();PAN[k].fx.push({t:"star",n:16,f0:F,pts:[[30,20],[160,24],[96,10],[60,70],[140,74]]});};
  if(right){sig(got);await bien("si_muy_bien");}
  else{SFX.bonk();PAN[got].dim=1;await wait(500);const k=1-got;PAN[k].sign=1;let res2;const p2=new Promise(r=>res2=r);got=null;
    CQ.toque=t=>{if(t===k){got=t;res2();}};await p2;PAN[k].sign=0;sig(k);await bien("muy_bien");}
  await wait(400);}
// which words this pass asks: the ones due, most overdue first; with nothing due, every word he has heard (those answers do not move the schedule)
function cualLista(){const due=PAL.vence("ear"),byW={};CU.items.forEach(it=>byW[it.w]=it);
  let lista=due.filter(w=>byW[w]).map(w=>byW[w]);
  if(!lista.length){const oidas=Object.keys(PAL.db.palabras).filter(w=>byW[w]);lista=(oidas.length&&!Q.get("todo")?oidas.map(w=>byW[w]):CU.items.slice());lista.sort(()=>Math.random()-.5);}
  if(Q.get("solo")){const so=Q.get("solo").split(",");lista=CU.items.filter(it=>so.includes(it.w));}   // for the machine check: only these words
  return lista.slice(0,+(Q.get("n")||8));}
async function cualRun(){runId++;hush();callaLetras();CQ.run=1;$("#go").style.display="none";pantalla("");foot(0,0,0);estado("play");
  await Promise.race([voiceReady,sleep(6000)]);
  const lista=CQ.lista;CQ.hecho=[];
  try{for(let i=0;i<lista.length;i++){step(i);CQ.i=i;await cualItem(lista[i]);}step(lista.length);}catch(e){if(e!=="stop")throw e;return;}
  PAN=null;CQ.run=0;cualFin();}
// the end: how many words and how many he got right the first time, and the way back to Palabras
function cualFin(){const n=CQ.hecho.length,m=CQ.hecho.filter(h=>h.ok).length;
  estado("end",true);pantalla("Done",[`${n} word${n===1?"":"s"} · ${m} right`]);
  $("#next").textContent="Back to Palabras";$("#next").onclick=()=>salir("app.html?tab=palabras");foot(1,0,0);}
async function cualArranca(){CU=await cualCarga();S=CU;E=ESCENAS.frente;SW=E.SW;SH=E.SH;sc.width=SW;sc.height=SH;
  document.title="Coquí · ¿Cuál?";SALIDA="app.html?tab=palabras";W=EMPTY();cam=E.CAM.wide.slice();voiceReady=loadVoice();setInterval(cualLoop,TICK);
  CQ.lista=cualLista();mkDots(CQ.lista.length);estado("start",true);pantalla("Review");fit();   // the start screen: a title and the disc; the bar has its true number of segments from the start
  cv.addEventListener("pointerdown",e=>{const r=cv.getBoundingClientRect(),y=(e.clientY-r.top)/r.height*DH;if(CQ.toque)CQ.toque(y<PH+GAP/2?0:1);});
  $("#go").onclick=()=>{try{ac().resume();}catch(e){}cualRun();};}
window.Cual={get pan(){return PAN?PAN.map(p=>({right:p.right,sign:p.sign})):null;},get i(){return CQ.i;},get listo(){return CQ.listo===CQ.i+1;},get lista(){return CQ.lista.map(x=>x.w);},get hecho(){return CQ.hecho;},toca(k){if(CQ.toque)CQ.toque(k);},get running(){return !!CQ.run;},get speaking(){return speaking;}};
