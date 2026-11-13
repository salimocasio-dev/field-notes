"use strict";
/* ============================================================
   Coquí · the story game.
   A story is a data file (cuentos/<id>.json): beats, asks and decisions.
   A scene (escenas/<id>.js) draws a place and knows what can happen in it.
   This file holds what is the same in every story: the voice, the big
   sign, the signal for a right move, a decision, the thing at stake.
   ============================================================ */
const $=s=>document.querySelector(s),sleep=ms=>new Promise(r=>setTimeout(r,ms));
const Q=new URLSearchParams(location.search),FAST=+(Q.get("fast")||1),CUENTO=(Q.get("cuento")||"la-lluvia").replace(/[^a-z0-9-]/g,""),OIR=Q.get("oir")==="1";   // oir=1: the story told straight through, nothing to touch (Escuchar: Otra vez)
const DW=196,DH=216,TICK=70,ESCENAS={};
const cv=$("#cv"),dc=cv.getContext("2d"),sc=document.createElement("canvas"),c=sc.getContext("2d");
let S=null,E=null,SW=240,SH=216,W={fx:[]},V={},cam=[0,0,DW,DH],camA=null,F=0,pending=null,running=false,runId=0,muted=false,LOG=[];
let ULT={},MEM={};try{ULT=JSON.parse(localStorage.getItem("coqui.juego.ult")||"{}");MEM=JSON.parse(localStorage.getItem("coqui.juego.mem")||"{}");}catch(e){}   // MEM: what one story passes to a later one

function fresh(){W=Object.assign({cq:{x:150,y:178,s:1,dy:0,al:1,vis:1,bub:null},spot:null,twinkle:null,glow:null,fx:[],heart:0,lost:0,resp:null},E.fresh(S));cam=E.CAM.wide.slice();camA=null;pending=null;V={};LOG=[];
  for(const k in MEM)V["mem_"+k]=MEM[k];
  (Q.get("mem")||"").split(",").filter(Boolean).forEach(kv=>{const i=kv.indexOf(":");V["mem_"+kv.slice(0,i)]=kv.slice(i+1);});}   // for checking: ?mem=amigo:1

/* ---------- signs and marks, the same in every scene ---------- */
const HAND=["....oo......","...owwo.....","...owwo.....","...owwo.....","...owwooo...","...owwowwoo.","oo.owwowwowo","owoowwwwwwwo","owwowwwwwwwo",".owwwwwwwwwo",".owwwwwwwwwo","..owwwwwwwo.","..owwwwwwwo.","...owwwwwo..","...ooooooo.."];
function hand(g,x,y,down,k){const o=down?0:3*k;HAND.forEach((rw,j)=>{for(let i=0;i<rw.length;i++){const ch=rw[i];if(ch!==".")fr(g,x+i*k,y+j*k+o,k,k,ch==="o"?OUT:"#FFFFFF");}});
  if(down){[[-4,-1],[2,-4],[8,-1]].forEach(p=>{fr(g,x+2*k+p[0]*k-1,y+p[1]*k-1,k+3,k+3,OUT);fr(g,x+2*k+p[0]*k,y+p[1]*k,k+1,k+1,"#FFE040");});}}
const HEART=[".##...##.","####.####","#########","#########",".#######.","..#####..","...###...","....#...."];
function heart(g,x,y,s){HEART.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#"){fr(g,x+i*s-1,y+j*s-1,s+2,s+2,OUT);}});
  HEART.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")fr(g,x+i*s,y+j*s,s,s,j<2&&i<3?"#FF9A90":"#E8443C");});}
function star(g,x,y,s,hot){const col=hot?"#FFFFFF":"#FFE040";fr(g,x-1,y-s-1,3,2*s+3,OUT);fr(g,x-s-1,y-1,2*s+3,3,OUT);fr(g,x,y-s,1,2*s+1,col);fr(g,x-s,y,2*s+1,1,col);fr(g,x-1,y-1,3,3,col);}
// the big "touch this" sign: everything else goes dim, a thick pulsing frame, and (drawn later) a big tapping hand
function spot(g,b,a){const e=a%4<2?0:2,x0=Math.max(0,b[0]-5-e),y0=Math.max(0,b[1]-5-e),x1=Math.min(SW,b[0]+b[2]+5+e),y1=Math.min(SH,b[1]+b[3]+5+e);
  g.fillStyle="rgba(6,14,28,.6)";g.fillRect(0,0,SW,y0);g.fillRect(0,y1,SW,SH-y1);g.fillRect(0,y0,x0,y1-y0);g.fillRect(x1,y0,SW-x1,y1-y0);
  const ring=(o,t,col)=>{fr(g,x0-o,y0-o,x1-x0+2*o,t,col);fr(g,x0-o,y1+o-t,x1-x0+2*o,t,col);fr(g,x0-o,y0-o,t,y1-y0+2*o,col);fr(g,x1+o-t,y0-o,t,y1-y0+2*o,col);};
  ring(5,5,OUT);ring(4,3,e?"#FFF4B0":"#FFE040");}
function twinkle(g,b){const cx=b[0]+b[2]/2,cy=b[1]+b[3]/2;for(let k=0;k<3;k++){const an=F/7+k*2.094;star(g,Math.round(cx+(b[2]/2+5)*Math.cos(an)),Math.round(cy+(b[3]/2+5)*Math.sin(an)),(F>>2)%2?3:2,k===(F>>3)%3);}}
const G_HAND=["..#.#.#..","..#.#.#.#","..#.#.#.#","..#.#.#.#","#.#####.#","#.######.","########.",".#######.","..#####..","..#####.."],G_HEART=[".##.##.","#######","#######",".#####.","..###..","...#..."];
GL.gota=["..#..","..#..",".###.",".###.","#####","#####",".###."];GC.gota="#3A86E6";   // a rain drop, for bubbles
const BUB={hola:[G_HAND,"#B46A30"],amor:[G_HEART,"#E0403A"]},BUBL={como:["ok","q","sad"],bien:["ok"],mal:["sad"],quien:["hand","q"],lluvia:["gota","sad"]};
function bub(g,k,tx,ty,a){if(BUBL[k]){bubble(g,BUBL[k],tx,ty,a);return;}
  const rows=BUB[k][0],col=BUB[k][1],w=rows[0].length+6,h=rows.length+6,x=Math.round(tx-w/2),y=ty-h-5-(a%2);
  fr(g,x-1,y,w+2,h,OUT);fr(g,x,y-1,w,h+2,OUT);fr(g,x,y,w,h,"#FFFFFF");
  fr(g,tx-2,y+h,5,1,"#FFFFFF");fr(g,tx-2,y+h+1,5,1,OUT);fr(g,tx-1,y+h+1,3,1,"#FFFFFF");fr(g,tx-1,y+h+2,3,1,OUT);fr(g,tx,y+h+2,1,1,"#FFFFFF");fr(g,tx,y+h+3,1,1,OUT);
  rows.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")fr(g,x+3+i,y+3+j,1,1,col);});}
const BANG=[".....#.....","#....#....#",".#...#...#.","..#.###.#..","...#####...","###########","...#####...","..#.###.#..",".#...#...#.","#....#....#",".....#....."];
function bang(g,cx,cy,s){const x0=cx-Math.floor(5.5*s),y0=cy-Math.floor(5.5*s);
  BANG.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")fr(g,x0+i*s-1,y0+j*s-1,s+2,s+2,OUT);});
  BANG.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")fr(g,x0+i*s,y0+j*s,s,s,Math.abs(i-5)<2&&Math.abs(j-5)<2?"#FFFFFF":"#FFE040");});}
function frogBox(q){const w=Math.round(30*q.s)+2,h=Math.round(25*q.s)+2;return {x:Math.round(q.x+(32-w)/2),y:q.y+27-h,w,h};}
function frog(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui")&&a%2?1:0;   // his mouth moves while he talks
  shadow(g,b.x+2,q.y+25,b.w-5);g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+Math.round(q.dy));}

/* the two answer bubbles of the Say move: the frog nodding (sí) and the frog shaking his head (no) */
function respBox(k){if(!W.resp||!W.resp.includes(k))return null;const q=W.cq,b=frogBox(q),n=W.resp.length,i=W.resp.indexOf(k),m=n>2?76:60,cx=Math.max(cam[0]+m,Math.min(cam[0]+cam[2]-m,b.x+b.w/2)),y=Math.max(4,b.y-46);
  return n>2?[Math.round(cx-70+i*50),y,40,36]:i===0?[Math.round(cx-50),y,40,36]:[Math.round(cx+10),y,40,36];}   // two answer bubbles, or three in a row
const bx=k=>respBox(k)||((k==="si"||k==="no")?null:E.box(k,W))||(b=>[b.x,b.y,b.w,b.h])(frogBox(W.cq));   // an answer bubble that is gone stands for the frog who said it
function respDraw(g,a){(W.resp||[]).forEach(k=>{const b=respBox(k),x=b[0],y=b[1],w=b[2],h=b[3],t=(F>>1)%8,o=[0,1,2,1,0,-1,-2,-1][t];
  fr(g,x-1,y,w+2,h,OUT);fr(g,x,y-1,w,h+2,OUT);fr(g,x,y,w,h,"#FFFFFF");
  const tx=W.resp.indexOf(k)===0?x+w-8:x+8;fr(g,tx-3,y+h,7,1,"#FFFFFF");fr(g,tx-3,y+h+1,7,1,OUT);fr(g,tx-2,y+h+1,5,1,"#FFFFFF");fr(g,tx-2,y+h+2,5,1,OUT);fr(g,tx-1,y+h+2,3,1,"#FFFFFF");fr(g,tx-1,y+h+3,3,1,OUT);
  if(W.respVoz&&W.respVoz[k]){const on=W.respOn===k,m=on&&a%2?1:0,col=on?"#2E9A48":"#9AA4B0",n=on?1+(F>>1)%3:3;   // an answer that cannot be drawn: the bubble says it aloud, and he picks by ear
    if(on){fr(g,x+1,y+1,w-2,2,"#FFE040");fr(g,x+1,y+h-3,w-2,2,"#FFE040");fr(g,x+1,y+1,2,h-2,"#FFE040");fr(g,x+w-3,y+1,2,h-2,"#FFE040");}
    g.drawImage(spr("cqv"+m,()=>mkCoqui(.5,0,m)),x+4,y+11-(on?m:0));for(let i=0;i<n;i++)fr(g,x+25+i*4,y+17-i*3,2,4+i*6,col);return;}
  if(k!=="si"&&k!=="no"){if(E.respIcon)E.respIcon(g,k,x,y,w,h,a);return;}   // a picture answer: the scene draws what is in the bubble
  const hx=x+Math.round(w/2)-11+(k==="no"?o*2:0),hy=y+7+(k==="si"?o*2:0);g.drawImage(spr("cq.7_0",()=>mkCoqui(.7,0,0)),hx,hy);
  const col=k==="si"?"#2E9A48":"#D0403A";   // motion marks: up and down for sí, side to side for no
  if(k==="si"){[[x+4,y+9],[x+w-6,y+9]].forEach(p=>{fr(g,p[0],p[1],2,14,col);fr(g,p[0]-1,p[1]+1,4,1,col);fr(g,p[0]-1,p[1]+12,4,1,col);});}
  else{[[x+5,y+4],[x+5,y+h-6]].forEach(p=>{fr(g,p[0],p[1],w-10,2,col);fr(g,p[0]+1,p[1]-1,1,4,col);fr(g,p[0]+w-12,p[1]-1,1,4,col);});}});}
function draw(){if(!E)return;const a=F>>1;
  E.draw(c,W,a);if(W.resp)respDraw(c,a);
  if(W.twinkle&&bx(W.twinkle))twinkle(c,bx(W.twinkle));
  if(W.spot)spot(c,bx(W.spot),a);
  W.fx=W.fx.filter(e=>F-e.f0<e.n);
  W.fx.forEach(e=>{const k=F-e.f0;if(e.t==="star")e.pts.forEach((p,i)=>star(c,p[0],p[1],(i+a)%2?4:2,(i+a)%2));
    else if(e.t==="knock"){const s=cam[2]>150?2:1;if(k<2)bang(c,e.x,e.y,s);else if(k>=3&&k<6)bang(c,e.x+3*s,e.y-2*s,s);}});
  if(W.heart)heart(c,E.heartAt[0],E.heartAt[1]-(a%2),3);
  if(camA){const t=Math.min(1,(F-camA.f0)/camA.n),e=t*t*(3-2*t);for(let i=0;i<4;i++)cam[i]=camA.a[i]+(camA.b[i]-camA.a[i])*e;if(t>=1){cam=camA.b.slice();const r=camA.res;camA=null;r();}}
  dc.imageSmoothingEnabled=false;dc.fillStyle="#0E1A24";dc.fillRect(0,0,DW,DH);
  dc.drawImage(sc,cam[0],cam[1],cam[2],cam[3],0,0,DW,DH);
  if(E.hud)E.hud(dc,W,a);
  if(W.spot){const rb=respBox(W.spot),p=rb?[rb[0]+rb[2]/2,rb[1]+rb[3]-6]:E.handAt[W.spot],z=DW/cam[2],k=3,hx=Math.round((p[0]-cam[0])*z)-4*k,hy=Math.round((p[1]-cam[1])*z);hand(dc,hx,hy,(F>>2)%2===1,k);}
}
function loop(){F++;draw();placeBub();}

/* ---------- sound: effects, and the recorded voice ---------- */
let AC=null;const ac=()=>AC||(AC=new (window.AudioContext||window.webkitAudioContext)());
let master=null;const out=()=>{const A=ac();if(!master){master=A.createGain();master.connect(A.destination);}master.gain.value=muted?0:1;return master;};
function tone(f0,at,dur,type,vol,f1){if(muted)return;try{const A=ac(),t=A.currentTime+at,o=A.createOscillator(),g=A.createGain();o.type=type||"square";o.frequency.setValueAtTime(f0,t);if(f1)o.frequency.exponentialRampToValueAtTime(f1,t+dur);
  g.gain.setValueAtTime(vol||.05,t);g.gain.exponentialRampToValueAtTime(.0008,t+dur);o.connect(g);g.connect(A.destination);o.start(t);o.stop(t+dur+.02);}catch(e){}}
let NOISE=null,RAIN=null;
function noise(){const A=ac();if(!NOISE){NOISE=A.createBuffer(1,A.sampleRate*2,A.sampleRate);const d=NOISE.getChannelData(0);for(let i=0;i<d.length;i++)d[i]=Math.random()*2-1;}return NOISE;}
const SFX={right(){tone(784,0,.1,"triangle",.14);tone(1047,.09,.1,"triangle",.14);tone(1319,.18,.26,"triangle",.14);},
  toc(){tone(950,0,.07,"sine",.22,480);tone(950,.17,.07,"sine",.22,480);},
  blip(){tone(520,0,.06,"sine",.07,640);},creak(){tone(210,0,.5,"sawtooth",.025,120);tone(330,.05,.4,"sawtooth",.012,170);},
  hop(){tone(320,0,.07,"square",.025,520);},coqui(){tone(1500,0,.11,"sine",.09);tone(2300,.17,.2,"sine",.09,2750);},win(){[523,659,784,1047].forEach((f,i)=>tone(f,i*.11,.2,"square",.04));},
  luz(){tone(1320,0,.09,"sine",.1);tone(1760,.08,.22,"sine",.1);},drop(){tone(1400,0,.05,"sine",.06,700);},
  trueno(v){try{const A=ac(),s=A.createBufferSource(),f=A.createBiquadFilter(),g=A.createGain(),t=A.currentTime;s.buffer=noise();f.type="lowpass";f.frequency.setValueAtTime(900,t);f.frequency.exponentialRampToValueAtTime(70,t+1.3);
    g.gain.setValueAtTime((v||1)*.5,t);g.gain.exponentialRampToValueAtTime(.001,t+1.5);s.connect(f);f.connect(g);g.connect(out());s.start(t);s.stop(t+1.6);}catch(e){}},
  lluvia(){try{if(RAIN)return;const A=ac(),s=A.createBufferSource(),f=A.createBiquadFilter(),g=A.createGain();s.buffer=noise();s.loop=true;f.type="highpass";f.frequency.value=1800;g.gain.value=.03;s.connect(f);f.connect(g);g.connect(out());s.start();RAIN=s;}catch(e){}},
  calla(){try{if(RAIN)RAIN.stop();}catch(e){}RAIN=null;}};
Object.assign(SFX,{pio(){tone(2600,0,.06,"sine",.07,3400);tone(2900,.09,.08,"sine",.07,3800);},slam(){tone(140,0,.12,"square",.05,70);tone(90,.02,.18,"sine",.12,50);},
  bonk(){tone(600,0,.06,"square",.05,200);tone(300,.06,.2,"triangle",.08,120);},munch(){[0,.16,.32].forEach(t=>tone(260,t,.06,"square",.03,180));},swoop(){tone(1800,0,.35,"sine",.04,600);}});
let SINLETRAS=0,TALK=null,LINES={},VOICE=false,CLIPS={},speaking=0,live=new Set(),voiceReady=null;
function trim(b){const d=b.getChannelData(0),sr=b.sampleRate,th=.012;let i=0,j=d.length-1;while(i<j&&Math.abs(d[i])<th)i++;while(j>i&&Math.abs(d[j])<th)j--;return {buf:b,t0:Math.max(0,i/sr-.03),t1:Math.min(b.duration,j/sr+.1)};}   // the recordings carry silence at both ends; the pauses are set here instead
async function loadVoice(){LINES=S.clips||{};
  try{const r=await fetch("audio/ready.json",{cache:"no-store"});if(!r.ok)return;const j=await r.json(),A=ac(),have=new Set(j.clips||[]);
    await Promise.all(Object.keys(LINES).filter(id=>have.has(id)).map(async id=>{try{const b=await (await fetch("audio/"+id+".mp3?v="+(j.v||0))).arrayBuffer();CLIPS[id]=trim(await new Promise((ok,no)=>A.decodeAudioData(b,ok,no)));}catch(e){}}));
    VOICE=Object.keys(LINES).every(id=>CLIPS[id]);}catch(e){}}
const words=id=>((LINES[id]||{}).text||"x x").split(/\s+/).length;
const dur=id=>VOICE&&CLIPS[id]?CLIPS[id].t1-CLIPS[id].t0:(360*words(id)+300)/1000;
function playClip(id){return new Promise(res=>{const cl=CLIPS[id];if(!VOICE||!cl){res(false);return;}
  const s=ac().createBufferSource();s.buffer=cl.buf;s.connect(out());speaking++;live.add(s);TALK=partes(id).quien;letras(id);
  s._end=v=>{if(s._done)return;s._done=1;speaking=Math.max(0,speaking-1);live.delete(s);TALK=null;letrasFin(id,v);res(v);};s.onended=()=>s._end(true);s.start(0,cl.t0,Math.max(.05,cl.t1-cl.t0));});}
function hush(){[...live].forEach(s=>{try{s.stop();}catch(e){}s._end(false);});}
function say(id,gap){const my=runId,g=(gap==null?420:gap)/FAST;
  return (VOICE&&CLIPS[id]?playClip(id).then(ok=>ok?sleep(g):0):(TALK=partes(id).quien,letras(id),sleep(dur(id)*1000/FAST).then(()=>{TALK=null;letrasFin(id,true);return sleep(g);}))).then(()=>{if(my!==runId)throw "stop";});}

/* ---------- the words on screen: speech bubbles and captions ----------
   The frog's lines and grandma's lines show in a bubble at the speaker. The narrator's lines show as a caption under the picture.
   If the speaker cannot be seen, the caption carries the whole line. Spanish only, exactly what is said.
   When the words show is one setting, TXT: "con" = while the line is spoken (Salim's ask), "tras" = right after it, "no" = never.
   ?txt=tras or ?txt=no overrides it for one visit. */
const TXT=["con","tras","no"].includes(Q.get("txt"))?Q.get("txt"):"con";
const capEl=$("#cap"),bubEl=$("#bub");let BUBQ=null,capT=null,bubT=null;
function partes(id){const cl=LINES[id]||{},t=cl.text||"";
  if(cl.who==="tu")return {cap:null,quien:"coqui",bub:t,all:t};
  if(cl.habla){const i=t.indexOf(": ");if(i>0)return {cap:t.slice(0,i+1),quien:cl.habla,bub:t.slice(i+2),all:t};}
  return {cap:t,quien:null,bub:null,all:t};}
function donde(quien){if(!quien||!E)return null;
  if(quien==="coqui"){const q=W.cq;if(!q.vis)return null;const b=frogBox(q);return [b.x+b.w/2,b.y+Math.round(q.dy)-(q.bub?19:1)];}
  return E.talkAt?E.talkAt(quien,W):null;}
function muestra(id){const p=partes(id);let cap=p.cap,bub=p.bub;
  if(bub&&!donde(p.quien)){cap=p.all;bub=null;}
  clearTimeout(capT);clearTimeout(bubT);
  capEl.textContent=cap||"";capEl.classList.toggle("on",!!cap);
  if(bub){BUBQ=p.quien;bubEl.textContent=bub;bubEl.classList.add("on");placeBub();}else{BUBQ=null;bubEl.classList.remove("on");}}
function borra(ms){clearTimeout(capT);clearTimeout(bubT);capT=setTimeout(()=>capEl.classList.remove("on"),ms);bubT=setTimeout(()=>{bubEl.classList.remove("on");BUBQ=null;},ms*.7);}
function letras(id){if(TXT==="con"&&!SINLETRAS)muestra(id);}
function letrasFin(id,done){if(TXT==="no"||SINLETRAS)return;if(TXT==="tras"){if(!done)return;muestra(id);borra(Math.max(1800,((LINES[id]||{}).text||"").length*70)/FAST);return;}borra(1700/FAST);}
function callaLetras(){clearTimeout(capT);clearTimeout(bubT);capEl.classList.remove("on");bubEl.classList.remove("on");BUBQ=null;}
function placeBub(){if(!BUBQ)return;const a=donde(BUBQ);if(!a){bubEl.classList.remove("on");return;}
  const cw=cv.clientWidth,ch=cv.clientHeight,X=v=>(v-cam[0])/cam[2]*cw,Y=v=>(v-cam[1])/cam[3]*ch,bw=bubEl.offsetWidth,bh=bubEl.offsetHeight;
  if(BUBQ==="coqui"){   // the frog talks from beside himself, so his bubble never hides abuela
    const b=frogBox(W.cq),xr=X(b.x+b.w)+4,xl=X(b.x)-4,y=Y(b.y+b.h*.45+Math.round(W.cq.dy)),rR=cw-xr-18,rL=xl-18,right=rR>=rL,room=Math.min(right?rR:rL,cw*.72);
    if(room>=110){bubEl.style.maxWidth=Math.floor(room)+"px";bubEl.className="on "+(right?"der":"izq");bubEl.style.left=Math.round(right?xr+12:xl-12)+"px";bubEl.style.top=Math.round(Math.max(bh/2+4,Math.min(ch-bh/2-4,y)))+"px";return;}}
  bubEl.style.maxWidth="";bubEl.className="on";const x=X(a[0]),y=Y(a[1]),l=Math.max(bw/2+4,Math.min(cw-bw/2-4,x));
  bubEl.style.left=Math.round(l)+"px";bubEl.style.top=Math.round(Math.max(bh+4,y))+"px";bubEl.style.setProperty("--tx",Math.round(Math.max(14,Math.min(bw-14,x-l+bw/2)))+"px");}
const wait=ms=>{const my=runId;return sleep(ms/FAST).then(()=>{if(my!==runId)throw "stop";});};

/* ---------- moving things ---------- */
const at=k=>E.CAM[k].every((v,i)=>Math.abs(v-cam[i])<.5);
function camGo(k,n){return at(k)?Promise.resolve():new Promise(res=>{camA={a:cam.slice(),b:E.CAM[k].slice(),f0:F,n:n||9,res};});}
async function hopTo(x,y,hops,s1){const q=W.cq,x0=q.x,y0=q.y,s0=q.s;if(s1==null)s1=s0;for(let h=0;h<hops;h++){SFX.hop();q.s=Math.round((s0+(s1-s0)*(h+1)/hops)*100)/100;const n=5;for(let i=1;i<=n;i++){const t=(h+i/n)/hops;q.x=Math.round(x0+(x-x0)*t);q.y=Math.round(y0+(y-y0)*t);q.dy=-7*Math.sin(Math.PI*i/n);await wait(TICK);}q.dy=0;await wait(110);}}
function bounce(h){const q=W.cq;let i=0;const t=setInterval(()=>{i++;q.dy=-(h||6)*Math.sin(Math.PI*i/5);if(i>=5){q.dy=0;clearInterval(t);}},TICK);}
function fx(e){e.f0=F;W.fx.push(e);}

/* ---------- waiting for a touch ---------- */
// Wait for a touch on one of the live things. A touch on one of them counts from the first word of the lead-in.
async function espera(liveSet,lead,line,o){o=o||{};const my=runId;
  const me={live:liveSet,res:null,line,asked:0,busy:0,done:0,p:null,got:null,loose:!!o.loose,lock:!!o.lock||!!o.voces,sign:o.sign||null,kind:o.kind||"ask",pick:o.pick||null,alias:o.alias||null},gotP=new Promise(r=>{me.res=r;});pending=me;
  for(const st of lead||[]){if(me.done)break;if(typeof st==="string"){W.twinkle=o.sign||null;await say(sub(st));}else{W.twinkle=null;await paso(st);}}
  W.twinkle=null;let timer=null;const voz=o.voces?(o.orden||liveSet):[];me.voz=voz.length>0;
  // each speaking bubble says its line in turn, with no words on screen: he picks by ear
  const voces=async()=>{for(let i=0;i<voz.length;i++){if(me.done||pending!==me||my!==runId)break;const id=o.voces[voz[i]];W.respOn=voz[i];SINLETRAS=1;if(VOICE&&CLIPS[id])await playClip(id);else await sleep(dur(id)*1000/FAST);SINLETRAS=0;W.respOn=null;if(i<voz.length-1)await sleep(700/FAST);}W.respOn=null;};
  me.repite=()=>{if(pending===me&&!me.done&&my===runId&&!speaking&&!me.rep){me.rep=1;me.nrep=(me.nrep||0)+1;if(o.ayuda&&me.nrep>=2)W.spot=o.ayuda;   // a routine: after the second repeat the sign shows what to touch
    (line?playClip(line).then(()=>sleep(300/FAST)):Promise.resolve()).then(voces).then(()=>{me.rep=0;});}};
  if(OIR){if(line)await say(line,350);const w=o.pick||o.sign||liveSet[0],b=bx(w);me.done=1;me.got=w;me.ms=0;me.p={x:Math.round(b[0]+b[2]/2),y:Math.round(b[1]+b[3]/2)};pending=null;return me;}   // told straight through: the story answers itself
  if(!me.done){if(o.sign)W.spot=o.sign;if(!me.voz)me.asked=1;if(line&&!o.mudo)await say(line,me.voz?300:0);if(!me.done)await voces();me.asked=1;me.tEnd=performance.now();   // the bubbles are dead until both have spoken once
    if(!me.done&&(line||me.voz))timer=setInterval(me.repite,9000/FAST);}   // he waits: the line plays again. It costs nothing.
  await gotP;clearInterval(timer);if(pending===me)pending=null;W.spot=null;W.twinkle=null;W.respOn=null;if(my!==runId)throw "stop";
  return me;}
// a touch that is not an answer: it reacts and gets its name. Poking around is free.
function poke(what,p){if(what==="coqui"){bounce(6);const nm=S.names&&S.names.coqui;if(nm&&VOICE&&CLIPS[nm]){if(!speaking)playClip(nm);}else SFX.coqui();return;}   // touch the frog: he says his name
  SFX.blip();fx({t:"star",n:7,pts:[[p.x-7,p.y-4],[p.x+8,p.y+2],[p.x,p.y-10]]});if(E.poke)E.poke(what,p);}
function tap(x,y){if(!E||!S)return;const inb=b=>b&&x>=b[0]-3&&x<b[0]+b[2]+3&&y>=b[1]-3&&y<b[1]+b[3]+3,
    what=(W.resp||[]).find(k=>inb(respBox(k)))||E.hit(x,y,W),p={x:Math.round(x),y:Math.round(y)};if(!what)return;
  const pn=pending,nm=(W.apodo&&W.apodo[what])||(S.names&&S.names[what]);   // a scene may give a thing another line for a while (W.apodo)
  if(pn&&!pn.done){let w=what;if(pn.loose&&(w==="puerta"||w==="ventana"))w="casa";if(pn.alias&&pn.alias[w])w=pn.alias[w];   // before the door has a name, the door is the house
    if(pn.live.includes(w)&&!(pn.lock&&!pn.asked)){pn.done=1;pn.ms=pn.tEnd?Math.round((performance.now()-pn.tEnd)*FAST):0;pn.p=p;pn.got=w;hush();pn.res();return;}
    if((W.resp||[]).includes(what))return;                               // a bubble that is still speaking: the touch does nothing
    if(pn.voz&&what==="coqui"&&pn.asked){bounce(5);pn.repite();return;}     // touch the frog: the bubbles speak again
    poke(what,p);if(what==="coqui")return;
    if(nm&&!speaking&&!pn.busy){pn.busy=1;playClip(nm).then(()=>sleep(300)).then(()=>pending===pn&&!pn.done&&pn.asked&&pn.line?playClip(pn.line):0).then(()=>{pn.busy=0;});}   // name what was touched, then ask again
    return;}
  if(running){const busy=speaking;poke(what,p);if(what!=="coqui"&&nm&&!busy)playClip(nm);}}
cv.addEventListener("pointerdown",e=>{e.preventDefault();const r=cv.getBoundingClientRect(),px=(e.clientX-r.left)/r.width*DW,py=(e.clientY-r.top)/r.height*DH;tap(cam[0]+px/DW*cam[2],cam[1]+py/DH*cam[3]);});

/* ---------- the signal for a right move: the same every time ---------- */
function senal(t,p,quieto){if(OIR){if(!quieto)bounce(4);return;}const R=Math.round,rb=respBox(t),b=rb?(f=>[f.x,f.y,f.w,f.h])(frogBox(W.cq)):bx(t);if(rb||!p)p={x:R(b[0]+b[2]/2),y:R(b[1]+b[3]/2)};
  SFX.right();if(!quieto)bounce(8);fx({t:"star",n:16,pts:[[b[0]+4,b[1]+2],[b[0]+b[2]-4,b[1]+4],[R(b[0]+b[2]/2),b[1]-6],[b[0]-4,R(b[1]+b[3]/2)],[b[0]+b[2]+4,R(b[1]+b[3]/2)],[p.x,p.y-9]]});}
const bien=id=>OIR?Promise.resolve():wait(300).then(()=>say(id||S.bien||"muy_bien",350));

/* ---------- reading a story ---------- */
const sub=s=>typeof s==="string"?s.replace(/\$([a-z]+)/g,(m,k)=>V[k]!=null?V[k]:m):s;
const val=k=>V[k]!=null?V[k]:W[k];
function cond(e){const neg=e[0]==="!";if(neg)e=e.slice(1);const i=e.indexOf("="),r=i<0?!!val(e):String(val(e.slice(0,i)))===sub(e.slice(i+1));return neg?!r:r;}
async function pasos(list){for(const st of list||[])await paso(st);}
async function paso(st){
  if(typeof st==="string")return say(sub(st));                 // a line
  if(st.say)return say(sub(st.say),st.gap);
  if(st.wait!=null)return wait(st.wait);
  if(st.cam)return camGo(st.cam,st.n);
  if(st.dots!=null)return step(st.dots);
  if(st.set){Object.assign(W,st.set);return;}
  if(st.if)return pasos(cond(st.if)?st.then:st.else);
  if(st.act){const o={};for(const k in st)o[k]=sub(st[k]);const fn=E.acts[st.act];if(!fn)throw new Error("the scene has no act "+st.act);return fn(o);}
  if(st.ask)return ask(st);
  if(st.decide)return decide(st);
  if(st.elige)return elige(st);
  if(st.draw){const ops=st.options.map(sub),f=Q.get(st.draw),v=ops.includes(f)?f:ops[Math.floor(Math.random()*ops.length)];V[st.draw]=v;if(st.other)V[st.other]=ops.find(x=>x!==v);return;}   // a fresh draw; ?name=value fixes it
  if(st.reparte){const ops=st.options.slice();for(let i=ops.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[ops[i],ops[j]]=[ops[j],ops[i]];}   // deals the options out to several names, none twice; ?name=value fixes one
    st.reparte.forEach(k=>{const f=Q.get(k);if(ops.includes(f)){ops.splice(ops.indexOf(f),1);V[k]=f;}else V[k]=null;});st.reparte.forEach(k=>{if(V[k]==null)V[k]=ops.shift();});return;}
  if(st.calc){V[st.calc]=cond(st.cond)?sub(st.then):sub(st.else);return;}
  if(st.recuerda){MEM[st.recuerda]=sub(String(st.valor));V["mem_"+st.recuerda]=MEM[st.recuerda];try{localStorage.setItem("coqui.juego.mem",JSON.stringify(MEM));}catch(e){}return;}
  if(st.cost){W.lost++;return E.stake(W.lost,S.stake.steps,sub(st.en||""));}
  throw new Error("a step the game does not know");}
// An ask, with the big sign. Nothing can go wrong here.
const baraja=a=>{a=a.slice();for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;};
const vmapa=m=>m?Object.fromEntries(Object.entries(m).map(e=>[sub(e[0]),sub(e[1])])):null;   // a map from answers to lines, with the story's variables filled in on both sides
async function ask(st){const t=sub(st.ask),voz=vmapa(st.voces),said=vmapa(st.said);   // an ask can use answer bubbles too: this is where a new kind of bubble is taught, with the big sign
  if(st.resp&&!OIR){W.resp=st.resp.map(sub);if(st.baraja)W.resp=baraja(W.resp);W.respVoz=voz;}
  const me=await espera([t],st.lead,st.line?sub(st.line):null,{sign:t,loose:st.loose,voces:voz,orden:voz?W.resp:null});
  senal(t,me.p,sub(st.quieto)==="1"||st.quieto===true);if(said&&said[t]){await wait(250);W.resp=null;await say(said[t],200);}W.resp=null;await pasos(st.after);await bien(st.bien);await pasos(st.then);}
// He picks what the frog says, and there is no wrong answer: each answer leads somewhere else.
async function elige(st){const ops=st.options;W.respVoz=null;W.resp=st.kind==="say"&&!OIR?ops:null;const me=await espera(ops,st.lead,sub(st.line),{kind:"elige"});V.elegido=me.got;
  LOG.push({word:null,asked:"libre",got:me.got,ok:true});SFX.blip();bounce(5);
  if(st.said&&st.said[me.got]){await wait(250);W.resp=null;await say(sub(st.said[me.got]),300);}W.resp=null;await pasos(st[me.got]);}
// A decision. Two things he could do; only the Spanish says which. A wrong one costs a step of the thing at stake,
// what he did stays done, and then the big sign shows the right one.
async function decide(st){let ops=st.options.map(sub);const key=CUENTO+"."+(st.as||"x"),voz=vmapa(st.voces),said=vmapa(st.said);let pick;
  if(st.baraja)ops=baraja(ops);   // which side each answer bubble is on is drawn fresh
  if(st.pick)pick=sub(st.pick);
  else{const forced=Q.get(st.as||""),last=ULT[key];pick=ops.includes(forced)?forced:st.alterna&&ops.includes(last)?ops.find(x=>x!==last):ops[Math.floor(Math.random()*ops.length)];ULT[key]=pick;try{localStorage.setItem("coqui.juego.ult",JSON.stringify(ULT));}catch(e){}}
  if(st.as)V[st.as]=pick;if(st.other)V[st.other]=ops.find(x=>x!==pick);
  if(st.decide==="say"&&!OIR){W.resp=ops;W.respVoz=voz;}
  const line=sub(st.line),vale=(st.vale||[]).map(sub);let me=await espera(ops.concat(vale),st.lead,line,{lock:st.lock,kind:"decide",pick,voces:voz,orden:voz?ops:null,mudo:st.mudo,ayuda:st.libre?pick:null,alias:st.alias});const first=me.got===pick||vale.includes(me.got);V.ok=first?"1":"";V.x=me.got;
  if(!OIR&&!st.libre){const w=sub(st.tests||pick);LOG.push({word:(S.palabras&&S.palabras[w])||w,asked:pick,got:me.got,ok:first,ms:me.ms||0});}
  if(said&&said[me.got]){SFX.blip();bounce(5);await wait(250);W.resp=null;await say(said[me.got],300);}
  W.resp=null;
  if(st.do)await E.acts[st.do]({en:me.got});
  if(!first&&st.libre){await wait(300);SFX.bonk();const k="hz_no_"+me.got,nm=S.names&&S.names[me.got];if(LINES[k])await say(k,300);else if(nm&&LINES[nm])await say(nm,300);}   // Haz esto: a wrong touch costs nothing. "No." and the name of what he touched; then the sign.
  else if(!first){await wait(500);const costs=JSON.stringify(st.wrong||[]).includes('"cost"');await pasos(st.wrong);if(!costs){W.lost++;await E.stake(W.lost,S.stake.steps,me.got);}}
  if(!first){
    if(st.noretry)return;   // one guess: the story shows the right one, then goes on
    if(st.decide==="say"){W.resp=ops;W.respVoz=voz;}
    me=await espera([pick],[],line,{sign:pick,voces:voz,orden:voz?[pick]:null,alias:st.alias,mudo:st.mudo});W.resp=null;if(st.do)await E.acts[st.do]({en:pick});
    if(st.decide==="say"&&said&&said[pick]){SFX.blip();bounce(5);await wait(200);await say(said[pick],250);}}
  senal(pick,st.decide==="say"?null:me.p,sub(st.quieto)==="1"||st.quieto===true);if(st.bien!==false)await bien(st.bien);await pasos(st.right);}

/* ---------- running it ---------- */
let dots=[...document.querySelectorAll(".dot")];const step=n=>dots.forEach((d,i)=>d.classList.toggle("on",i<n));
function mkDots(n){dots.forEach(d=>d.remove());const bar=$("#bar"),snd=$("#snd");dots=[];for(let i=0;i<n;i++){const d=document.createElement("span");d.className="dot";bar.insertBefore(d,snd);dots.push(d);}}
let T0=0;async function run(){T0=performance.now();runId++;const my=runId;hush();SFX.calla();callaLetras();fresh();running=true;step(0);if($("#nota"))$("#nota").style.display="none";$("#go").style.display="none";$("#again").style.display="none";$("#next").style.display="none";
  await Promise.race([voiceReady,sleep(6000)]);if(my!==runId)return;
  try{await pasos(S.beats);await pasos(S.final);}catch(e){if(e!=="stop")throw e;return;}
  if(window.PAL&&(!Q.get("fast")||Q.get("rec"))){if(!OIR&&!S.tipo){S._lost=W.lost;PAL.cuento(S,LOG);}else if(PAL.oido)PAL.oido(CUENTO);PAL.minutos((performance.now()-T0)/6e4);}   // the words he heard and how he answered go into his word records
  running=false;$("#again").style.display="flex";if($("#home"))$("#home").style.display="flex";if(S.next&&!OIR){$("#next").style.display="flex";$("#again").classList.add("two");}}
const VER=((document.querySelector('script[src*="juego.js"]')||{src:""}).src.split("v=")[1]||"0");
function cargaEscena(id){return ESCENAS[id]?Promise.resolve():new Promise((ok,no)=>{const s=document.createElement("script");s.src="escenas/"+id+".js?v="+VER;s.onload=ok;s.onerror=()=>no(new Error("no scene "+id));document.head.appendChild(s);});}
async function arranca(){S=await (await fetch("cuentos/"+CUENTO+".json",{cache:"no-store"})).json();await cargaEscena(S.scene);E=ESCENAS[S.scene];if(S.cam)E.CAM=Object.assign({},E.CAM,S.cam);SW=E.SW;SH=E.SH;sc.width=SW;sc.height=SH;document.title="Coquí · "+S.title;mkDots(S.dots||5);
  if(S.nota&&$("#nota")){$("#nota").textContent=S.nota;$("#nota").style.display="block";}   // the one plain English line before a new grammar pattern: on the opening card, gone before any Spanish plays
  fresh();voiceReady=loadVoice();setInterval(loop,TICK);draw();
  $("#go").onclick=()=>{try{ac().resume();}catch(e){}run();};$("#again").onclick=()=>run();
  $("#next").onclick=()=>{const q=new URLSearchParams(location.search);q.set("cuento",S.next);location.search=q.toString();};}
$("#snd").onclick=()=>{muted=!muted;$("#snd").classList.toggle("off",muted);if(master)master.gain.value=muted?0:1;};
function fit(){const vw=window.innerWidth,vh=window.innerHeight,w=Math.floor(Math.min(vw-12,500,(vh-130)*DW/DH));cv.style.width=w+"px";cv.style.height=Math.round(w*DH/DW)+"px";}
fit();addEventListener("resize",fit);
/* for checking the game by machine */
window.Story={scene(){return E&&E.estado?E.estado(W):"";},get W(){return W;},get V(){return V;},get pending(){return pending&&!pending.done?pending:null;},tapOn(k){const h=!respBox(k)&&E.handAt&&E.handAt[k];if(h){tap(h[0],h[1]+3);return;}const b=bx(k);tap(b[0]+b[2]/2,b[1]+b[3]/2);},tapAt(x,y){tap(x,y);},
  get running(){return running;},get cam(){return cam;},get voice(){return VOICE;},get speaking(){return speaking;},get clips(){return Object.keys(CLIPS).length;},get log(){return LOG;},get ready(){return !!S;},get cap(){return capEl.classList.contains('on')?capEl.textContent:'';},get bub(){return bubEl.classList.contains('on')?bubEl.textContent:'';},get txt(){return TXT;}};
