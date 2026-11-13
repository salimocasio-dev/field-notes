"use strict";
/* ============================================================
   Coquí · the scene kit.
   What every scene after El frente shares: the bird, abuela sitting,
   and escena(), which turns a short description of a place (its
   things, where the frog stands at each, what can happen) into a
   scene the game can run. El frente was written before the kit and
   keeps its own copy of the bird.
   ============================================================ */
const KIT=(()=>{
const SW=240,SH=216;

/* ---------- the bird ---------- */
function mkAve(st,fl){const R=st==="round",b=new Buf(R?24:18,R?18:14),B=RP.blue,cx=R?11:8,cy=R?10:8;
  b.cap(cx-6,cy-1,cx-9,cy-3,1.2,[B[1]]);
  b.ell(cx,cy,R?8:5.5,R?6.5:4.2,B);b.ell(cx-1,cy+(R?2.5:1.5),R?5:3.4,R?3.4:2.2,["#E8F4FF"]);
  b.ell(cx+(R?6:5),cy-(R?4:3),R?3.8:3.3,R?3.6:3.1,B);
  if(st==="sleep"||R){b.rect(cx+(R?6:5),cy-(R?4:3),2,1,OUT);}else{b.px(cx+6,cy-4,"#FFFFFF");b.px(cx+6,cy-3,"#20140A");b.px(cx+7,cy-3,"#20140A");}
  b.rect(cx+(R?9:8),cy-(R?4:3),R?3:2,R?2:1,RP.yel[2]);b.px(cx+(R?9:8),cy-(R?2:2),RP.orng[2]);
  if(fl)b.ell(cx-1,cy-4,3.6,2,[B[0],B[1]]);else b.ell(cx-1,cy+1,3.6,2,[B[0],B[1]]);
  if(!R){b.px(cx-1,cy+4,RP.orng[1]);b.px(cx+2,cy+4,RP.orng[1]);}
  return b.outline().done();}
const AVK=1.6;   // drawn bigger than its pixels, so it reads at phone size
// v = {mode:none|fly|sit|head, x, y (its feet), dir, st:n|sleep|feliz|round, dip}
function avePos(v){if(v.mode==="head"){const b=frogBox(W.cq);return [b.x+b.w/2,b.y+Math.round(W.cq.dy)+2];}return [Math.round(v.x),Math.round(v.y+(v.dip||0))];}
function drawAve(c,v){if(!v||v.mode==="none")return;const p=avePos(v),st=v.st||"n",fl=v.mode==="fly"?(F>>1)%2:0,
    im=spr("kave"+st+fl,()=>mkAve(st,fl)),w=im.width,h=im.height,dir=v.dir||1,H=Math.round(h*AVK);
  c.save();c.imageSmoothingEnabled=false;c.translate(p[0],p[1]-H+2);if(v.dip){c.translate(0,H);c.rotate(dir*.5);c.translate(0,-H);}c.scale(dir*AVK,AVK);c.drawImage(im,-Math.round(w/2),0);c.restore();
  if(st==="round"){const z=(F>>3)%3,zx=p[0]+12+z*2,zy=p[1]-H-4-z*2;fr(c,zx,zy,4,1,"#FFFFFF");fr(c,zx+3,zy+1,1,1,"#FFFFFF");fr(c,zx+2,zy+2,1,1,"#FFFFFF");fr(c,zx+1,zy+3,1,1,"#FFFFFF");fr(c,zx,zy+4,4,1,"#FFFFFF");}
  if(st==="feliz"&&(F>>2)%2){fr(c,p[0]-2,p[1]-H-5,2,2,"#FF8FB8");fr(c,p[0]+1,p[1]-H-5,2,2,"#FF8FB8");fr(c,p[0]-1,p[1]-H-3,3,2,"#FF8FB8");}}
async function aveA(tx,ty,n){const v=W.ave,x0=v.x,y0=v.y;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(tx-x0)*t;v.y=y0+(ty-y0)*t-Math.sin(Math.PI*t)*6;await wait(TICK);}v.x=tx;v.y=ty;}
// the bird flies to a spot and lands there
async function aveVa(tx,ty,n,dir){if(!W.ave||W.ave.mode==="none")W.ave={mode:"fly",x:SW+12,y:30,dir:-1,st:"n"};const v=W.ave,p=avePos(v);v.x=p[0];v.y=p[1];v.dip=0;v.mode="fly";v.dir=tx>=v.x?1:-1;SFX.swoop();await aveA(tx,ty,n||9);v.mode="sit";if(dir)v.dir=dir;}
function aveHit(x,y){const v=W.ave;if(!v||v.mode==="none")return false;const p=avePos(v);return Math.abs(x-p[0])<16&&y>p[1]-24&&y<p[1]+5;}

/* ---------- abuela, sitting. Poses: idle, fan (a paper fan, two frames), vaso (a glass held out), bebe (the glass at her mouth), zzz, and pies (her feet up) ---------- */
function mkAbuelaS(pose,open,pies){const b=new Buf(52,50),X=17,S=RP.skin,P=RP.purp;
  // legs and lap first, the body over them
  if(pies){b.cap(X+8,36,X+27,35,3.4,P);b.rect(X+26,33,8,4,S[2]);b.ell(X+35,33.5,2.2,3.4,["#3A2414"]);b.ell(X+35,37.5,2.2,2.6,["#3A2414"]);}
  else{b.ell(X+9,36.5,12,5.2,P);b.rect(X+15,40,3,6,S[2]);b.rect(X+19,40,3,6,S[1]);b.ell(X+17,47,3.2,1.7,["#3A2414"]);b.ell(X+22,47,3.2,1.7,["#3A2414"]);}
  b.ell(X,28,8.6,9.6,P);for(let i=0;i<7;i++)b.px(X-7+hs(i,3)%15,29+hs(i,5)%8,P[4]);
  b.ell(X+1,30,5,6.6,RP.cream);b.rect(X-4,23,10,1,RP.cream[1]);
  b.rect(X-2,17,4,4,S[1]);
  b.ell(X,10,8,8.6,RP.grey);b.ell(X,2.9,3.6,2.6,RP.grey);
  b.ell(X,12.4,5.8,6.4,S);b.ell(X,5.8,6.2,2.6,RP.grey);
  if(pose==="zzz"){b.rect(X-4,12,3,1,"#20140A");b.rect(X+1,12,3,1,"#20140A");}else{b.px(X-3,12,"#20140A");b.px(X+2,12,"#20140A");}
  b.px(X-4,14,"#E08A70");b.px(X+3,14,"#E08A70");
  if(open)b.rect(X-1,15,3,2,"#7A1C1C");else{b.rect(X-2,15,4,1,"#7A2A1A");b.px(X-3,14,"#7A2A1A");b.px(X+2,14,"#7A2A1A");}
  b.px(X-6,14,"#F8C838");b.px(X+6,14,"#F8C838");
  b.cap(X-7,23,X-6,31,2,P);b.ell(X-5,33.5,2.1,2.1,S);                                   // her left arm rests
  if(pose==="fan0"||pose==="fan1"){const d=pose==="fan1"?2:0;b.cap(X+7,23,X+12,18,2,P);b.ell(X+13,16,2.2,2.2,S);   // a paper fan by her face
    for(let k=-3;k<=3;k++)b.line(X+13,15,X+16+d+k,6+Math.abs(k),k%2?"#FFE070":"#FF8FB8");b.line(X+13+d,7,X+19+d,7,"#D0403A");}
  else if(pose==="vaso"){b.cap(X+7,24,X+14,29,2,P);b.ell(X+16,29.5,2.2,2.2,S);}
  else if(pose==="bebe"){b.cap(X+7,24,X+11,19,2,P);b.ell(X+10,17.5,2.2,2.2,S);}
  else{b.cap(X+8,24,X+11,31,2,P);b.ell(X+12,33,2.1,2.1,S);}
  return b.outline().done();}

/* ---------- a place, from its description ----------
   d.cosas: the things that can be touched, front to back: {id, box:[x,y,w,h] or (W)=>box, si:(W)=>shown, hand:[x,y], m:slack, z:1 if in front of the frog}
   d.lugar: where the frog stands at each thing: {id:[x,y,size]}
   d.acts:  what can happen here (added to the few every place has) */
function escena(d){const cosa=k=>d.cosas.find(t=>t.id===k),B=(t,w)=>typeof t.box==="function"?t.box(w||W):t.box,ve=(t,w)=>!t.si||t.si(w);
  const box=(k,w)=>{const t=cosa(k);return t?B(t,w):null;};
  function hit(x,y,w){const inb=(b,m)=>b&&x>=b[0]-m&&x<b[0]+b[2]+m&&y>=b[1]-m&&y<b[1]+b[3]+m,slack=t=>t.m==null?3:t.m;
    for(const t of d.cosas)if(t.z&&ve(t,w)&&inb(B(t,w),slack(t)))return t.id;
    if(aveHit(x,y))return "pajaro";
    const q=w.cq,fb=frogBox(q);if(q.vis&&x>=fb.x&&x<fb.x+fb.w&&y>=fb.y&&y<fb.y+fb.h)return "coqui";
    for(const t of d.cosas)if(!t.z&&ve(t,w)&&inb(B(t,w),slack(t)))return t.id;
    return null;}
  const handAt=new Proxy({},{get(_,k){const t=cosa(k);if(!t)return undefined;if(t.hand)return typeof t.hand==="function"?t.hand(W):t.hand;const b=B(t,W);return [Math.round(b[0]+b[2]/2),Math.round(b[1]+b[3]/2)];}});
  const comunes={
    async ir(o){const L=d.lugar[o.a||o.en];if(!L)return;const q=W.cq,dd=Math.hypot(q.x-L[0],q.y-L[1]);if(dd<3){q.s=L[2];return;}await hopTo(L[0],L[1],Math.max(1,Math.min(4,Math.round(dd/30))),L[2]);},
    async burbuja(o){if(o.quien==="cq"){W.cq.bub=o.que;SFX.coqui();bounce(6);}else if(W.ab)W.ab.bub=o.que;},
    async calla(){if(W.ab)W.ab.bub=null;W.cq.bub=null;},
    async pose(o){if(W.ab)W.ab.pose=o.que;},
    async fin(){const b=cam;if(!W.lost){W.heart=1;SFX.win();fx({t:"star",n:40,pts:[[b[0]+8,b[1]+14],[b[0]+b[2]-8,b[1]+16],[b[0]+b[2]/2-20,b[1]+8],[b[0]+b[2]/2+22,b[1]+10]].map(p=>[Math.round(p[0]),Math.round(p[1])])});}
      else if(W.lost<S.stake.steps)SFX.win();else SFX.coqui();await wait(1700);}
  },acts=d.acts=d.acts||{};for(const k in comunes)if(!(k in acts))acts[k]=comunes[k];   // the scene's own actions win; the shared ones are added to the same list, so a scene action can call them
  ESCENAS[d.id]=Object.assign({SW,SH,CAM:d.CAM,heartAt:d.heartAt||[120,30],fresh:d.fresh,draw:d.draw,hud:d.hud,poke:d.poke,stake:d.stake,talkAt:d.talkAt,respIcon:d.respIcon,estado:d.estado,box,hit,handAt,acts});
  return ESCENAS[d.id];}

return {SW,SH,mkAve,avePos,drawAve,aveA,aveVa,aveHit,mkAbuelaS,escena};
})();
