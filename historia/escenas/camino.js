"use strict";
/* ============================================================
   Coquí · scene "El camino": the path in the park (place 2, El parque).
   A dirt path runs from the park gate on the left, past three small
   trees and a bench, up to one very big tree on the right. Three flat
   stones lie on the path. Luis and Carmen are here with abuela's dog,
   Canelo. A grey cat lives in the park. Birds sit in the three trees.
   People live in W.gente, the dog in W.perro, the cat in W.gato:
   {x,y (feet), pose, dir, vis}. W.pajaros = how many birds sit in each
   of the three trees. Every story set here uses this drawing.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round;
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana};
// the path: seven marks from the gate (0) to the big tree (6); 1 to 5 are the stones
const MARCA=[[66,182],[86,172],[106,163],[126,155],[146,148],[164,142],[184,137]];
const ARBOL=[[70,120],[112,116],[154,112]],GRAN=[200,128],BANCO=[98,128,30,16];
const NIDO=[[-9,-31],[8,-36],[0,-21]];   // where up to three birds sit in a small tree, from its foot

/* ---------- the picture ---------- */
function fondo(gran){const b=new Buf(SW,SH),G=RP.grn,Wd=RP.wood,ST=RP.stone;
  sky(b,SW,100);grass(b,100,SW,SH);
  // the path, wider toward us
  for(let i=0;i<=200;i++){const t=i/200,x=30+170*t,y=198-66*t-8*Math.sin(Math.PI*t),hw=13-5*t;for(let dy=-hw;dy<=hw;dy++)for(let dx=-2;dx<=2;dx++){const px=x+dx,py=y+dy*.62;b.px(px,py,Math.abs(dy)>hw-1.2?"#C8A468":hs(R(px),R(py))<10?"#D8B67A":"#E8CE96");}}
  // the three stones
  [1,2,3,4,5].forEach(i=>{const m=MARCA[i];b.ell(m[0],m[1]+1,8,3.4,[OUT]);b.ell(m[0],m[1],7,2.8,[ST[1],ST[2],ST[3],ST[4]]);});
  // the park gate: two posts and an arch
  [24,50].forEach(x=>{b.rect(x,134,6,40,ST[3]);b.rect(x,134,2,40,ST[4]);b.rect(x+4,134,2,40,ST[1]);b.rect(x-1,130,8,5,ST[2]);b.frame(x-1,130,8,45,OUT);b.ell(x+3,127,3,3,[ST[3],ST[4]]);});
  for(let a=0;a<=40;a++){const t=Math.PI*a/40,x=40-13*Math.cos(t),y=134-11*Math.sin(t);b.rect(x,y,2,2,"#3A3A46");}
  // three small trees and the bench
  ARBOL.forEach((p,i)=>{b.rect(p[0]-2,p[1]-22,5,22,Wd[1]);b.rect(p[0]-2,p[1]-22,1,22,Wd[3]);b.rect(p[0]-3,p[1]-1,7,2,Wd[0]);b.ell(p[0],p[1]-30,17,14,[OUT]);b.ell(p[0],p[1]-30,16,13,G);b.ell(p[0]-6,p[1]-34,6,4,[G[3],G[4]]);});
  b.rect(BANCO[0],BANCO[1]+5,BANCO[2],3,Wd[3]);b.rect(BANCO[0],BANCO[1],BANCO[2],3,Wd[3]);b.rect(BANCO[0]+2,BANCO[1]+8,2,7,Wd[1]);b.rect(BANCO[0]+BANCO[2]-4,BANCO[1]+8,2,7,Wd[1]);b.rect(BANCO[0],BANCO[1]+5,BANCO[2],1,Wd[4]);b.frame(BANCO[0]-1,BANCO[1]-1,BANCO[2]+2,10,OUT);
  // the big tree on its rise (story 13 is at the other end of the path: no big tree)
  if(gran){b.ell(GRAN[0],GRAN[1]+4,34,8,[G[1],G[2],G[3]]);b.grad(GRAN[0]-8,GRAN[1]-58,16,60,[Wd[2],Wd[1],Wd[1],Wd[0]],true);b.rect(GRAN[0]-9,GRAN[1]-56,1,58,OUT);b.rect(GRAN[0]+8,GRAN[1]-56,1,58,OUT);b.rect(GRAN[0]-13,GRAN[1],26,3,Wd[1]);
  [[GRAN[0],GRAN[1]-82,40,30],[GRAN[0]-26,GRAN[1]-64,18,14],[GRAN[0]+24,GRAN[1]-62,18,14]].forEach(e=>b.ell(e[0],e[1],e[2],e[3],G));}
  return b.done();}
function mkPerro(pose,f){const b=new Buf(30,22),T=["#8A5A2A","#B07A3C","#D09A54","#E8BE80"],X=13,Y=12;
  const lie=pose==="lie"||pose==="panza",sit=pose==="sit"||pose==="eat"||pose==="bark",baja=pose==="husmea";
  if(pose==="panza"){b.ell(X,15,10,4.5,T);b.ell(X+1,13,7,2.6,["#F4E0B8"]);[[X-6,9],[X-1,8],[X+4,8],[X+8,9]].forEach(p=>b.rect(p[0],p[1],2,4,T[1]));b.ell(X+11,15,4.6,4,T);b.px(X+13,14,OUT);b.rect(X+14,16,2,1,OUT);return b.outline().done();}
  // tail, body, legs
  b.cap(X-9,Y-1,X-12,Y-6+(f?1:-1),1.4,[T[1]]);
  if(lie){b.ell(X,Y+5,10,4,T);b.rect(X+6,Y+7,6,2,T[1]);}
  else if(sit){b.ell(X-1,Y+3,7,6,T);b.rect(X+3,Y+4,2,6,T[1]);b.rect(X+6,Y+4,2,6,T[2]);b.ell(X-4,Y+8,4,2,[T[1]]);}
  else{const run=pose==="run",a=f?1:-1;b.ell(X,Y+1,10,5,T);
    if(run){b.cap(X-6,Y+4,X-11+a*2,Y+8,1.3,[T[1]]);b.cap(X-3,Y+4,X-7-a*2,Y+9,1.3,[T[0]]);b.cap(X+5,Y+4,X+10+a*2,Y+8,1.3,[T[1]]);b.cap(X+7,Y+4,X+12-a*2,Y+9,1.3,[T[2]]);}
    else{b.rect(X-7+a,Y+5,2,5,T[1]);b.rect(X-4-a,Y+5,2,5,T[0]);b.rect(X+4+a,Y+5,2,5,T[1]);b.rect(X+7-a,Y+5,2,5,T[2]);}}
  // head: one ear up, one down; a red collar
  const hx=X+10,hy=lie?Y+3:baja?Y+5:Y-4;b.rect(hx-4,hy+(baja?-2:4),5,2,RP.red[2]);
  b.ell(hx,hy,5,4.6,T);b.ell(hx+4,hy+1.5,3,2.2,[T[3]]);b.cap(hx-3,hy-3,hx-5,hy+2,1.5,[T[0]]);b.cap(hx+1,hy-4,hx+2,hy-7,1.3,[T[0]]);
  b.px(hx+1,hy-1,OUT);b.px(hx+6,hy+1,OUT);
  if(pose==="bark"&&f){b.rect(hx+3,hy+3,4,2,"#7A1C1C");}else if(pose==="eat"){b.rect(hx+3,hy+3,3,2,f?"#7A1C1C":T[3]);}else b.px(hx+4,hy+3,"#7A2A1A");
  if(pose==="lie"){b.rect(hx,hy-1,2,1,OUT);}
  return b.outline().done();}
function mkGato(pose,f){const b=new Buf(26,20),Gr=["#5A5A6A","#7E7E90","#A2A2B2","#C8C8D4"],X=12,Y=11;
  if(pose==="cara"){b.ell(X,Y,6,5,Gr);b.rect(X-6,Y-7,3,4,Gr[1]);b.rect(X+3,Y-7,3,4,Gr[1]);b.px(X-5,Y-6,"#FF8FB8");b.px(X+4,Y-6,"#FF8FB8");b.rect(X-3,Y-1,2,2,"#F8C838");b.rect(X+2,Y-1,2,2,"#F8C838");b.px(X-3,Y,OUT);b.px(X+2,Y,OUT);b.px(X,Y+2,"#FF8FB8");return b.outline().done();}
  if(pose==="cola"){b.cap(X,1,X+(f?2:-2),12,2.2,Gr);b.cap(X+(f?2:-2),12,X+(f?5:-5),15,2.2,Gr);[4,8,12].forEach(y=>b.rect(X-2+(f?1:-1)*(y>8?1:0),y,5,1,Gr[0]));return b.outline().done();}
  if(pose==="duerme"){b.ell(X,Y+4,9,5,Gr);b.ell(X+5,Y+3,4,3.4,Gr);b.rect(X+3,Y-1,2,2,Gr[1]);b.rect(X+7,Y-1,2,2,Gr[1]);b.rect(X+4,Y+3,2,1,OUT);b.cap(X-8,Y+6,X-2,Y+8,1.3,[Gr[1]]);return b.outline().done();}
  const run=pose==="run",low=pose==="walk",a=f?1:-1;
  b.cap(X-8,Y+(run?0:1),X-11,Y-(run?2:6),1.3,[Gr[1]]);
  if(pose==="sit"||pose==="lava"){b.ell(X-1,Y+3,5.6,6,Gr);b.rect(X+2,Y+4,2,6,Gr[1]);b.ell(X-3,Y+8,4,2,[Gr[1]]);if(pose==="lava"&&f)b.rect(X+4,Y,2,5,Gr[2]);}
  else{b.ell(X,Y+(low?3:1),9,low?3.6:4.4,Gr);
    if(run){b.cap(X-5,Y+4,X-10+a*2,Y+8,1.2,[Gr[1]]);b.cap(X+5,Y+4,X+10+a*2,Y+8,1.2,[Gr[1]]);b.cap(X+7,Y+4,X+12-a,Y+9,1.2,[Gr[2]]);}
    else{b.rect(X-6+a,Y+5,2,4,Gr[1]);b.rect(X-3-a,Y+5,2,4,Gr[0]);b.rect(X+4+a,Y+5,2,4,Gr[1]);b.rect(X+6-a,Y+5,2,low?3:4,Gr[2]);}}
  const hx=X+8,hy=(pose==="sit"||pose==="lava")?Y-4:Y-(low?0:3);b.ell(hx,hy,4.6,4.2,Gr);b.rect(hx-4,hy-6,3,3,Gr[1]);b.rect(hx+2,hy-6,3,3,Gr[1]);b.px(hx-1,hy-1,"#F8C838");b.px(hx+2,hy-1,"#F8C838");b.px(hx+1,hy+1,"#FF8FB8");
  return b.outline().done();}
function mkCaracol(f){const b=new Buf(18,13),e=f?1:0;b.rect(1,9,13+e,3,"#EAD9A2");b.rect(12+e,4,2,6,"#EAD9A2");b.rect(15+e,5,1,5,"#EAD9A2");b.px(12+e,3,OUT);b.px(15+e,4,OUT);b.ell(6,6,5,4.6,[RP.orng[0],RP.orng[2],RP.orng[3]]);b.ell(6,6,2.6,2.4,[RP.orng[1]]);b.px(6,6,RP.orng[4]);return b.outline().done();}
function mkArbusto(){const b=new Buf(44,30),G=RP.grn;b.ell(14,18,13,11,G);b.ell(30,17,13,12,G);b.ell(22,11,12,10,G);for(let i=0;i<10;i++)b.px(6+hs(i,3)%32,8+hs(i,7)%16,G[4]);return b.outline().done();}
function mkPajarito(f){const b=new Buf(11,9),B=RP.blue;b.ell(5,5,3.6,2.8,B);b.ell(7.6,3,2.2,2,B);b.px(8,3,OUT);b.rect(10,3,1,1,RP.yel[2]);b.cap(2,5,0,4+(f?1:0),1,[B[1]]);return b.outline().done();}
// small things: a fish biscuit, a guineo (small banana), a basket
function galleta(g,x,y,k){k=k||1;const C="#E8B060",u=(a,b,w,h,col)=>fr(g,x+a*k,y+b*k,w*k,h*k,col);   // a biscuit in the shape of a fish
  [[1,0,5,5],[0,1,7,3],[7,0,1,5],[8,-1,1,7],[6,1,1,3]].forEach(r=>fr(g,x+r[0]*k-1,y+r[1]*k-1,r[2]*k+2,r[3]*k+2,OUT));u(1,0,5,5,C);u(0,1,7,3,C);u(6,1,1,3,C);u(7,0,1,5,C);u(8,-1,1,7,C);u(1,1,1,1,OUT);u(3,3,2,1,"#B07A3C");}
function guineo(g,x,y,k){k=k||1;const Y=RP.yel;[[0,2,2,2],[1,3,3,2],[3,4,4,2],[6,3,3,2],[8,1,2,3]].forEach(r=>{fr(g,x+r[0]*k-1,y+r[1]*k-1,r[2]*k+2,r[3]*k+2,OUT);});[[0,2,2,2],[1,3,3,2],[3,4,4,2],[6,3,3,2],[8,1,2,3]].forEach(r=>fr(g,x+r[0]*k,y+r[1]*k,r[2]*k,r[3]*k,Y[2]));fr(g,x+9*k,y,k,k,RP.wood[1]);}
function mkCesta(){const b=new Buf(20,12),T=RP.orng;b.rect(1,3,18,8,T[2]);for(let y=3;y<11;y+=2)for(let x=1;x<19;x+=2)b.px(x+(y>>1)%2,y,T[0]);b.rect(0,2,20,2,T[3]);return b.outline().done();}

/* ---------- where things are ---------- */
const ranaEn=i=>[MARCA[i][0]-22,MARCA[i][1]-34,Math.round((.96-.02*i)*100)/100];           // the frog walks on the far side of the path, so his answer bubbles stand clear of Carmen
const ninaEn=i=>[MARCA[i][0]+20,MARCA[i][1]+15];                               // Carmen on our side
const LUGAR={inicio:ranaEn(0),centro:[100,176,1],banco:[74,128,.86],arbol0:[44,122,.8],arbol1:[126,122,.8],arbol2:[166,118,.8],gran:[166,126,.84]};
const alto=id=>id==="abuela"?51:QUIEN[id].nino?(W.gente[id]&&W.gente[id].sent?40:44):56;
const caja=id=>{const p=W.gente[id];return p&&p.vis!==0?[R(p.x)-11,R(p.y)-alto(id),22,alto(id)]:null;};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const AVES=[];for(let i=0;i<3;i++)for(let k=0;k<3;k++)AVES.push({id:"ave"+i+k,m:1,si:w=>(w.pajaros||[])[i]>k,box:[ARBOL[i][0]+NIDO[k][0]-8,ARBOL[i][1]+NIDO[k][1]-6,15,12]});
const COSAS=["luis","carmen","abuela"].map(persona).concat(AVES,[
  {id:"perro",si:w=>!!w.perro&&w.perro.vis!==0,box:w=>[R(w.perro.x)-14,R(w.perro.y)-20,28,22],m:2},
  {id:"gato",si:w=>!!w.gato&&w.gato.vis!==0&&w.gato.en==null,box:w=>[R(w.gato.x)-12,R(w.gato.y)-18,24,20],m:2},
  {id:"arbol0",box:[ARBOL[0][0]-17,ARBOL[0][1]-46,34,48],hand:[ARBOL[0][0],ARBOL[0][1]-12],m:0},{id:"arbol1",box:[ARBOL[1][0]-17,ARBOL[1][1]-46,34,48],hand:[ARBOL[1][0],ARBOL[1][1]-12],m:0},{id:"arbol2",box:[ARBOL[2][0]-17,ARBOL[2][1]-46,34,48],hand:[ARBOL[2][0],ARBOL[2][1]-12],m:0},
  {id:"banco",box:[BANCO[0]-1,BANCO[1]-2,BANCO[2]+2,18],m:1},{id:"grande",box:[GRAN[0]-40,GRAN[1]-112,58,116],m:0},{id:"porton",box:[22,116,36,60],m:0},
  {id:"camino",box:[30,128,170,76],m:0},{id:"parque",box:[0,100,240,116],m:0}]);

/* ---------- drawing ---------- */
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1,h=alto(id);c.globalAlpha=p.al==null?1:p.al;
  if(id==="abuela"){const ps=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle");c.save();c.translate(x,y-50);if(d<0)c.scale(-1,1);c.drawImage(spr("ab"+ps+habla,()=>mkAbuela(ps,habla)),-30,0);c.restore();if(p.lleva==="cesta"){c.drawImage(spr("cesta",mkCesta),x+2,y-26);for(let i=0;i<(p.guineos||0);i++)guineo(c,x+3+i*6,y-31-(i%2),.7);}c.globalAlpha=1;return;}
  const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="alto"?"wave0":p.pose==="dedos"?"wave0":(p.pose||"idle"),im=spr("pc"+id+pose+habla+(p.sent?1:0),()=>KIT.mkPersona(QUIEN[id],pose,habla,p.sent));
  c.save();c.translate(x,y-im.height+1+((p.paso&&a%2)||(p.rie&&a%2)?-1:0));if(p.corre){c.translate(0,im.height);c.rotate(.26*d);c.translate(0,-im.height);}if(d<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  if(p.lleva==="cesta"){fr(c,x-8,y-h+20,2,7,RP.orng[0]);fr(c,x+6,y-h+20,2,7,RP.orng[0]);fr(c,x-8,y-h+19,16,2,RP.orng[0]);c.drawImage(spr("cesta",mkCesta),x-10,y-h+26);if(W.gato&&W.gato.en==="cesta")c.drawImage(spr("gtduerme0",()=>mkGato("duerme",0)),x-13,y-h+12);}
  if(p.dedos){for(let i=0;i<p.dedos;i++){fr(c,x+d*9+i*4-1,y-h-9,4,8,OUT);fr(c,x+d*9+i*4,y-h-8,2,6,QUIEN[id].piel[3]);}}   // counting on his fingers
  c.globalAlpha=1;}
function animal(c,k,a){const o=W[k];if(!o||o.vis===0||o.en!=null)return;const f=(o.pose==="walk"||o.pose==="husmea"||o.pose==="run"||o.pose==="bark"||o.pose==="eat"||o.pose==="lava")?(a>>(o.pose==="run"?0:1))%2:0,
    im=k==="perro"?spr("pe"+o.pose+f,()=>mkPerro(o.pose,f)):spr("gt"+o.pose+f,()=>mkGato(o.pose,f)),d=o.dir<0?-1:1;
  c.save();c.translate(R(o.x),R(o.y)-im.height+2+(o.dy||0));if(d<0)c.scale(-1,1);c.drawImage(im,-13,0);c.restore();
  if(o.bub)bub2(c,o.bub,R(o.x),R(o.y)-22,a);}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui")&&a%2?1:0,dy=R(q.dy);
  for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5-(j===1?0:2);i++)if((i+j)%2===0)fr(g,b.x+2+i,q.y+25+j,1,1,"#2E8A34");
  g.globalAlpha=q.al;const im=spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op));
  if(W.arrastra){g.save();g.translate(b.x+b.w/2,b.y+dy+b.h/2-5);g.rotate(-.5*(W.arrastra<0?-1:1));g.drawImage(im,-b.w/2,-b.h/2);g.restore();}else g.drawImage(im,b.x,b.y+dy);g.globalAlpha=1;   // pulled off his feet by the leash
  if(W.guineos!=null){const cx=b.x+(b.w>>1)+R(W.tumbo||0);g.drawImage(spr("cesta",mkCesta),cx-10,b.y+dy-9);for(let i=0;i<W.guineos;i++)guineo(g,cx-9+i*6,b.y+dy-14-(i%2),.7);}
  if(W.galleta)galleta(g,b.x+(b.w>>1)-4,b.y+dy-8,1);}
Object.assign(BUBL,{q:["q"]});
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,G=W.gente||{};
  c.drawImage(spr("camino"+(W.sinGran?0:1),()=>fondo(!W.sinGran)),0,0);
  (W.lit||[]).forEach(i=>{const p=ARBOL[i];c.strokeStyle=(F>>2)%2?"#FFE040":"#FFF4B0";c.lineWidth=2;c.beginPath();c.ellipse(p[0],p[1]-30,19,16,0,0,7);c.stroke();});   // a tree that has been counted stays lit
  // the birds in the three trees; the cat's tail or face, if it is up one
  if(W.tiembla&&F-W.tiembla<10)ARBOL.forEach((p,i)=>{[[-18,-36],[16,-40],[-14,-18],[18,-22]].forEach((d,k)=>fr(c,p[0]+d[0]+((F+k)%2)*2,p[1]+d[1],3,2,RP.grn[4]));});
  (W.pajaros||[]).forEach((n,i)=>{for(let k=0;k<n;k++){const p=NIDO[k],im=spr("pj"+((F>>3)+k)%2,()=>mkPajarito(((F>>3)+k)%2));c.imageSmoothingEnabled=false;c.drawImage(im,ARBOL[i][0]+p[0]-8,ARBOL[i][1]+p[1]-6-(W.vuelan?R(W.vuelan):0),15,12);}});
  if(W.gato&&W.gato.en!=null&&typeof W.gato.en==="number"){const p=ARBOL[W.gato.en],f=(F>>3)%2;if(W.gato.pose==="cara")c.drawImage(spr("gtcara0",()=>mkGato("cara",0)),p[0]-12,p[1]-34);else if(W.gato.pose==="cola")c.drawImage(spr("gtcola"+f,()=>mkGato("cola",f)),p[0]+(W.gato.lado||1)*9-12,p[1]-20);}
  const L=[];
  Object.keys(G).forEach(id=>{const p=G[id];if(p&&p.vis!==0)L.push({y:p.y,d:()=>gente(c,id,a)});});
  ["perro","gato"].forEach(k=>{if(W[k]&&W[k].vis!==0&&W[k].en==null)L.push({y:W[k].y,d:()=>animal(c,k,a)});});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  if(W.caracol)L.push({y:W.caracol.y,d:()=>c.drawImage(spr("car"+((F>>3)%2),()=>mkCaracol((F>>3)%2)),R(W.caracol.x)-9,R(W.caracol.y)-12)});
  if(W.arbusto)L.push({y:W.arbusto[1]+2,d:()=>{c.drawImage(spr("arbusto",mkArbusto),W.arbusto[0]-22,W.arbusto[1]-28);if(W.perro&&W.perro.vis===0&&W.correaA){const x=W.arbusto[0]-25,y=W.arbusto[1]-9;fr(c,x-1,y-1,7,5,OUT);fr(c,x-3,y-5,5,6,OUT);fr(c,x,y,5,3,"#C88A4A");fr(c,x-2,y-4,3,4,"#C88A4A");}}});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  // the leash, from the frog's hand to the dog's collar
  if(W.correa&&W.perro&&(q.vis||W.correaDe)){const b=frogBox(q),lu=W.correaDe&&G[W.correaDe],x0=lu?R(lu.x)+(W.perro.x<lu.x?-10:10):(W.perro.x<q.x+16?b.x+3:b.x+b.w-3),y0=lu?R(lu.y)-18:b.y+R(q.dy)+b.h-9,x1=W.correaA?W.correaA[0]:R(W.perro.x)+(W.perro.dir<0?-8:8),y1=W.correaA?W.correaA[1]:R(W.perro.y)-11,n=14,sag=W.correa==="floja"?6:1;c.fillStyle="#7A1C1C";for(let i=0;i<=n;i++){const t=i/n;c.fillRect(R(x0+(x1-x0)*t),R(y0+(y1-y0)*t+Math.sin(Math.PI*t)*sag),2,1);}}
  if(W.vuela){const v=W.vuela;(v.k==="guineo"?guineo:galleta)(c,R(v.x),R(v.y),1);}
  if(W.polvo){const p=W.polvo;for(let i=0;i<3;i++){fr(c,p.x+p.dir*(4+i*6)-2,p.y-2-i%2*3,4,3,"#FFFFFF");fr(c,p.x+p.dir*(4+i*6)-1,p.y-1-i%2*3,3,2,"#E8E0C8");}if(p.lin)for(let i=0;i<3;i++){const lx=p.x+p.dir*10-(i%2)*4,ly=p.y-10-i*5;fr(c,lx-1,ly-1,16,4,"#2E6CD0");fr(c,lx,ly,14,2,"#FFFFFF");}}
  if(W.avebanco){const im=spr("pj0",()=>mkPajarito(0));c.imageSmoothingEnabled=false;c.drawImage(im,BANCO[0]+8,BANCO[1]-11,15,12);}   // a bird on the bench (a picture pair)
  Object.keys(G).forEach(id=>{const p=G[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2-(W.guineos!=null?16:0),a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.bub?38:0)];}
// the doing bubbles, moving pictures: camina (easy steps), corre (flat out, dust), espera (quite still), despacio (tiny steps, a snail keeps up), rapido (long quick steps)
function mano(g,x,y){const C="#E8A468",u=(a,b,w,h,col)=>fr(g,x+a,y+b,w,h,col);   // an open raised hand: wait
  [[0,4,2,6],[3,1,2,9],[6,0,2,10],[9,1,2,9],[0,9,11,6],[11,8,3,3],[2,15,7,2]].forEach(r=>u(r[0]-1,r[1]-1,r[2]+2,r[3]+2,OUT));
  [[0,4,2,6],[3,1,2,9],[6,0,2,10],[9,1,2,9],[0,9,11,6],[11,8,3,3],[2,15,7,2]].forEach(r=>u(r[0],r[1],r[2],r[3],C));}
function respIcon(g,k,x,y,w,h,a){const im=spr("cq.6_0",()=>mkCoqui(.6,0,0)),suelo=()=>fr(g,x+4,y+32,32,1,"#9494A6"),lin=(n,l,col)=>{for(let i=0;i<n;i++)fr(g,x+3+((F*2+i*5)%6),y+12+i*6,l,2,col);};
  suelo();
  if(k==="espera"){g.drawImage(im,x+6,y+12);fr(g,x+9,y+30,5,2,RP.tan[1]);fr(g,x+18,y+30,5,2,RP.tan[1]);mano(g,x+27,y+5);}
  else if(k==="corre"){const up=(F%2)?2:0;g.save();g.translate(x+24,y+21-up);g.rotate(.3);g.drawImage(im,-10,-9);g.restore();lin(3,9,"#2E6CD0");[[5,29],[11,27]].forEach((p,i)=>{fr(g,x+p[0]-(F%3),y+p[1],4,3,"#C8C8D4");});}
  else if(k==="rapido"){const up=(F%2)?2:0;g.drawImage(im,x+15,y+12-up);lin(3,6,"#2E6CD0");[[18,30],[27,30]].forEach((p,i)=>fr(g,x+p[0]+((F+i)%2)*3,y+p[1],5,2,RP.tan[1]));}
  else if(k==="despacio"){const up=(F>>3)%2?1:0;g.drawImage(im,x+14,y+12-up);g.drawImage(spr("car"+((F>>3)%2),()=>mkCaracol((F>>3)%2)),x+2,y+23);[[18,30],[25,30]].forEach((p,i)=>fr(g,x+p[0],y+p[1],4,2,RP.tan[1]));}
  else{const up=(F>>2)%2?3:0;g.drawImage(im,x+17,y+11-up);[[3,30],[8,27],[13,30]].forEach((p,i)=>{if(((F>>2)+i)%3)fr(g,x+p[0],y+p[1],4,2,"#6E4220");});}}

/* ---------- what is at stake, in the corner of the screen ---------- */
function tarjeta(g,x,y,w,h){g.fillStyle=OUT;g.fillRect(x-1,y,w+2,h);g.fillRect(x,y-1,w,h+2);g.fillStyle="#FFFDF4";g.fillRect(x,y,w,h);}
function hud(g,W,a){
  if(W.tarjeta==="galletas"){tarjeta(g,3,3,88,30);g.drawImage(spr("gtsit0",()=>mkGato("sit",0)),5,7);   // one biscuit a round: a heart if the cat got it, a paw mark if Canelo did
    (W.marcas||[]).forEach((m,i)=>{const x=34+i*18,y=10;if(m==="c")heart(g,x,y+1,2);else if(m==="p"){g.fillStyle="#B07A3C";g.fillRect(x+3,y+8,8,7);[[1,3],[5,1],[9,1],[13,3]].forEach(d=>g.fillRect(x+d[0]-1,y+d[1]+1,3,4));}else galleta(g,x,y+3,1.5);});}
  if(W.tarjeta==="guineos"){tarjeta(g,3,3,84,30);g.drawImage(spr("cesta",mkCesta),5,13);for(let i=0;i<3;i++){if(i<(W.guineos||0))guineo(g,30+i*17,10,1.5);else{g.fillStyle="#D8D8E4";g.fillRect(30+i*17,24,12,2);}}}
}

/* ---------- what can happen here ---------- */
const G=id=>W.gente[id];
async function mueve(id,x,y,n,corre){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/(corre?10:5)));p.sent=0;p.paso=1;p.corre=corre?1:0;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;p.corre=0;}
async function animalA(k,x,y,pose,n){const o=W[k];if(!o)return;const x0=o.x,y0=o.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/(pose==="run"?11:5)));o.pose=pose;if(Math.abs(x-x0)>3)o.dir=x>x0?1:-1;for(let i=1;i<=n;i++){o.x=x0+(x-x0)*i/n;o.y=y0+(y-y0)*i/n;await wait(TICK);}o.x=x;o.y=y;}
const enT=t=>{const x=40+146*t,y=194-58*t-8*Math.sin(Math.PI*t);return [R(x-10),R(y-14),1-.14*t];};
const perroT=t=>{const tt=Math.max(0,t-.12),x=40+146*tt,y=194-58*tt-8*Math.sin(Math.PI*tt);return [R(x)-2,R(y)+16];};
const ranaXY=()=>{const b=frogBox(W.cq);return [b.x+(b.w>>1),b.y+6];};
const junto=()=>{const b=frogBox(W.cq);return [b.x+6,b.y+b.h+15];};      // where the dog stands: in front of the frog, in plain sight
const ladra=async n=>{const o=W.perro;o.pose="bark";for(let k=0;k<(n||2);k++){tone(520,0,.07,"square",.05,300);tone(400,.07,.1,"square",.05,240);await wait(330);}o.pose="sit";};
const acts={
  async anda(o){await mueve(o.quien,+o.x,+o.y,null,o.corre);if(o.dir)G(o.quien).dir=+o.dir;},
  async burbuja(o){if(o.quien==="cq"){W.cq.bub=o.que;SFX.coqui();bounce(6);}else if(o.quien==="perro"||o.quien==="gato")W[o.quien].bub=o.que;else if(G(o.quien))G(o.quien).bub=o.que;},
  async calla(){Object.values(W.gente).forEach(p=>{if(p)p.bub=null;});W.cq.bub=null;if(W.perro)W.perro.bub=null;if(W.gato)W.gato.bub=null;},
  async pose(o){if(o.quien==="perro"||o.quien==="gato"){W[o.quien].pose=o.que;return;}const p=G(o.quien);if(p){p.pose=o.que;if(o.dir)p.dir=+o.dir;}},
  async saluda(o){const p=G(o.quien);if(!p)return;p.pose="wave";await wait(+o.ms||700);p.pose="idle";},
  async rie(o){const p=G(o.quien);if(!p)return;p.rie=1;await wait(+o.ms||700);p.rie=0;},
  async ladra(o){await ladra(+o.n||2);},
  async perroa(o){const j=o.a==="junto"?junto():[+o.x,+o.y];await animalA("perro",j[0],j[1],o.corre?"run":"walk");W.perro.pose=o.que||"sit";if(o.dir)W.perro.dir=+o.dir;},
  async gatoa(o){W.gato.en=null;await animalA("gato",+o.x,+o.y,o.corre?"run":"walk");W.gato.pose=o.que||"sit";if(o.dir)W.gato.dir=+o.dir;},
  // Luis counts on his fingers: one, two, three
  async cuenta(o){const p=G(o.quien||"luis");p.pose="dedos";for(let i=1;i<=3;i++){p.dedos=i;SFX.blip();await wait(+o.ms||330);}await wait(250);p.dedos=0;p.pose="idle";},
  async lame(){const f=ranaXY(),o=W.perro;await animalA("perro",f[0]-14,f[1]+22,"walk");o.dir=1;o.pose="eat";W.cq.bub="amor";SFX.coqui();bounce(5);await wait(900);W.cq.bub=null;o.pose="sit";},
  /* ---- story 12: do what Luis calls ---- */
  async inicio12(){W.gente={luis:{x:174,y:138,pose:"wave",dir:-1},carmen:{x:ninaEn(0)[0],y:ninaEn(0)[1],pose:"idle"}};W.pos={cq:0,carmen:0};const L=ranaEn(0);Object.assign(W.cq,{x:L[0],y:L[1],s:L[2]});const j=junto();W.perro={x:j[0],y:j[1],pose:"bark",dir:1};await wait(500);G("luis").pose="idle";W.perro.pose="sit";},
  // one of them goes to a stone, in one of three ways: camina (easy steps), corre (flat out, dust), espera (stands quite still)
  async va(o){const quien=o.quien,modo=o.modo,i=Math.max(0,Math.min(6,+o.a));
    if(quien==="carmen"){const p=G("carmen"),t=ninaEn(i);if(modo==="espera"){p.pose="idle";await wait(900);}else{await mueve("carmen",t[0],t[1],null,modo==="corre");}W.pos.carmen=modo==="espera"?W.pos.carmen:i;return;}
    const q=W.cq,L=ranaEn(i);if(modo==="espera"){await wait(900);return;}
    if(modo==="corre"){W.polvo={x:frogBox(q).x,y:q.y+26,dir:-1,lin:1};const pe=animalA("perro",L[0]+22,L[1]+42,"run");await hopTo(L[0],L[1],1,L[2]);await pe;W.polvo=null;}
    else{const pe=animalA("perro",L[0]+22,L[1]+42,"walk",16);await hopTo(L[0],L[1],3,L[2]);await pe;}
    W.perro.pose="sit";W.perro.dir=1;W.pos.cq=i;},
  async luisno(){const p=G("luis");for(let k=0;k<4;k++){p.dir=-p.dir;await wait(140);}p.dir=-1;SFX.bonk();await wait(250);},
  async luisrie(){const p=G("luis");p.rie=1;p.pose="wave";await wait(650);p.rie=0;p.pose="idle";},
  // one call for both of them. Right (or under the sign): both do it and end one stone on. After a wrong move that was put right: the frog does it on the spot.
  async ronda(o){const m=o.modo,bien=V.ok!=="",mal=o.mal,pc=W.pos.cq,pk=W.pos.carmen;
    if(mal){const mov=mal!=="espera";await Promise.all([acts.va({quien:"cq",modo:mal,a:mov?pc+1:pc}),acts.va({quien:"carmen",modo:m,a:pk+1})]);await acts.luisno();if(mov){await acts.va({quien:"cq",modo:"camina",a:pc});}return;}
    if(!bien){if(m==="espera"){await wait(700);await acts.luisrie();await acts.va({quien:"carmen",modo:"camina",a:pk+1});}else{bounce(m==="corre"?9:5);await wait(350);bounce(m==="corre"?9:5);await wait(500);}return;}
    if(m==="espera"){await Promise.all([acts.va({quien:"cq",modo:"espera",a:pc}),acts.va({quien:"carmen",modo:"espera",a:pk})]);await acts.luisrie();await Promise.all([acts.va({quien:"cq",modo:"camina",a:pc+1}),acts.va({quien:"carmen",modo:"camina",a:pk+1})]);}
    else await Promise.all([acts.va({quien:"cq",modo:m,a:pc+1}),acts.va({quien:"carmen",modo:m,a:pk+1})]);},
  // a call for each of them: f is the frog's, c is Carmen's
  async ronda2(o){const f=o.f,cm=o.c,bien=V.ok!=="",mal=o.mal,pc=W.pos.cq,pk=W.pos.carmen,car=async()=>{if(cm==="espera"){await acts.va({quien:"carmen",modo:"espera",a:pk});}else await acts.va({quien:"carmen",modo:cm,a:pk+1});};
    if(mal){const mov=mal!=="espera";await Promise.all([acts.va({quien:"cq",modo:mal,a:mov?pc+1:pc}),car()]);await acts.luisno();if(mov)await acts.va({quien:"cq",modo:"camina",a:pc});if(cm==="espera"){await acts.luisrie();await acts.va({quien:"carmen",modo:"camina",a:pk+1});}return;}
    if(!bien){if(f==="espera"){await wait(700);}else{bounce(f==="corre"?9:5);await wait(350);bounce(f==="corre"?9:5);await wait(500);}return;}
    await Promise.all([acts.va({quien:"cq",modo:f,a:f==="espera"?pc:pc+1}),car()]);
    if(f==="espera"||cm==="espera"){await acts.luisrie();await Promise.all([f==="espera"?acts.va({quien:"cq",modo:"camina",a:pc+1}):0,cm==="espera"?acts.va({quien:"carmen",modo:"camina",a:pk+1}):0]);}},
  async alinicio(){await Promise.all([acts.va({quien:"cq",modo:"camina",a:0}),mueve("carmen",ninaEn(0)[0],ninaEn(0)[1])]);W.pos={cq:0,carmen:0};G("carmen").dir=1;},
  // the rule, shown once: Canelo cannot wait; Luis shakes his head; Canelo walks back
  async demo(){const o=W.perro,L=ranaEn(Math.min(6,W.pos.cq+1));await wait(300);await animalA("perro",L[0]+22,L[1]+42,"run");o.pose="sit";await acts.luisno();},
  async demo2(){const o=W.perro,j=junto();await animalA("perro",j[0],j[1],"walk",14);o.pose="sit";o.dir=1;await wait(300);},
  async final12(){const n=W.lost||0,ca=G("carmen"),q=W.cq,L=LUGAR.gran,car=()=>mueve("carmen",160,146),yo=async()=>{const pe=animalA("perro",L[0]-12,L[1]+28,"run");await hopTo(L[0],L[1],3,L[2]);await pe;W.perro.pose="sit";};
    if(!n){await Promise.all([car(),yo()]);bounce(8);W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[150,60],[196,70],[176,50],[160,90],[200,96]]});await wait(900);}
    else if(n<3){await car();ca.pose="wave";await yo();ca.pose="idle";SFX.win();await wait(600);}
    else{await car();ca.sent=1;G("luis").sent=1;await wait(500);await yo();SFX.coqui();await wait(600);}
    ca.sent=1;G("luis").sent=1;await wait(400);},
  async ladra3(){await ladra(3);},
  /* ---- story 13: the cat in the trees ---- */
  async inicio13(){W.sinGran=1;W.gente={luis:{x:62,y:188,pose:"idle",dir:1},carmen:{x:92,y:198,pose:"idle",lleva:"cesta"}};W.perro={x:54,y:206,pose:"sit",dir:1};W.correa="floja";W.correaDe="luis";
    W.gato={x:113,y:134,pose:"lava",dir:-1,en:null};const L=LUGAR.centro;Object.assign(W.cq,{x:L[0],y:L[1],s:L[2]});},
  // the birds fly up and settle again: how many sit in each tree
  async posan(o){const n=o.p?o.p.split("").map(Number):[+o.a,+o.b,+o.c];if(W.pajaros.some(x=>x)){SFX.pio();for(let i=1;i<=6;i++){W.vuelan=i*5;await wait(TICK);}}W.pajaros=n;for(let i=6;i>=0;i--){W.vuelan=i*5;await wait(TICK);}W.vuelan=0;SFX.pio();await wait(200);},
  // the cat goes to a tree; the story learns which count sits in it (n), the other two (oa, ob, in an order drawn fresh), and one other for a bubble (m)
  async gatoarbol(o){const i=+o.en,g=W.gato,otros=[0,1,2].filter(k=>k!==i).map(k=>String(W.pajaros[k]));if(Math.random()<.5)otros.reverse();
    V.n=String(W.pajaros[i]);V.oa=otros[0];V.ob=otros[1];V.m=otros[Math.random()<.5?0:1];V.tm=String(W.pajaros.indexOf(+V.m));
    if(g.en==null){g.pose="run";await animalA("gato",ARBOL[i][0],ARBOL[i][1],"run");SFX.swoop();}else if(o.que!=="nada"){SFX.swoop();await wait(250);}
    g.en=i;g.pose=o.que||"cola";g.lado=i===2?-1:1;await wait(300);},
  async asoma(o){const g=W.gato;if(o.en!=null)g.en=+o.en;g.pose="cara";SFX.blip();tone(700,0,.18,"sine",.05,900);await wait(500);},
  async lit(o){W.lit=o.n==="0"?null:[0,1,2].slice(0,+o.n);SFX.blip();await wait(150);},
  async saca(){W.galleta=1;SFX.blip();await wait(250);},
  async ronronea(){const g=W.gato;g.pose="sit";g.bub="amor";tone(180,0,.5,"sawtooth",.02,160);await wait(900);g.bub=null;g.pose="lava";},
  // the tree with that many birds twinkles
  async luzn(o){W.twinkle=o.n==="0"?null:"arbol"+W.pajaros.indexOf(+o.n);await wait(80);},
  // the cat's face goes back in; all three trees shake; where it goes next is not seen
  async esconde(){const g=W.gato;if(g.en==="cesta")return;g.pose="nada";W.tiembla=F;SFX.swoop();await wait(350);SFX.swoop();await wait(350);},
  async carmenvuelve(){await mueve("carmen",92,198);G("carmen").dir=1;},
  // the cat eats this round's biscuit: a heart in the corner, for good
  async gatocome(o){const i=W.marcas?W.marcas.indexOf(null):-1;await acts.asoma({});await wait(200);W.galleta=0;SFX.munch();if(i>=0&&V.ok!=="")W.marcas[i]="c";await wait(600);},
  // Canelo jumps and gobbles it: a paw mark in the corner
  async perrocome(){const o=W.perro,f=ranaXY(),i=W.marcas.indexOf(null);W.correa=0;await animalA("perro",f[0]-12,f[1]+20,"run");o.pose="eat";o.dy=-6;W.galleta=0;SFX.munch();if(i>=0)W.marcas[i]="p";await wait(500);o.dy=0;await wait(300);await animalA("perro",54,206,"walk");o.pose="sit";o.dir=1;W.correa="floja";},
  async acaricia(){await acts.asoma({});W.cq.bub="amor";SFX.coqui();bounce(4);await wait(800);W.cq.bub=null;},
  // the dog pulls loose; the birds fly up; the cat jumps about and is gone in the leaves
  async escapa(){const o=W.perro,g=W.gato;await ladra(2);W.correa=0;const corre=animalA("perro",150,150,"run");SFX.pio();for(let i=1;i<=6;i++){W.vuelan=i*5;await wait(TICK);}for(let k=0;k<5;k++){g.en=k%3;g.pose="cola";SFX.swoop();await wait(200);}g.pose="nada";await corre;await ladra(1);},
  async agarra(){await animalA("perro",54,206,"walk");W.perro.pose="sit";W.perro.dir=1;W.correa="floja";await wait(200);},
  async cuentaaves(){for(const n of [1,2,3]){W.twinkle="arbol"+W.pajaros.indexOf(n);await wait(60);}},
  async carmenva(o){const i=+o.en;await mueve("carmen",ARBOL[i][0]+18,ARBOL[i][1]+12);G("carmen").dir=-1;await wait(250);},
  async mirarriba(){G("carmen").bub="q";await wait(700);G("carmen").bub=null;},
  async gatocesta(){const g=W.gato;SFX.swoop();await wait(300);g.en="cesta";g.pose="duerme";SFX.luz();await wait(500);},
  async galletacesta(){const i=W.marcas?W.marcas.indexOf(null):-1;SFX.munch();if(i>=0&&V.ok!=="")W.marcas[i]="c";await wait(600);},
  async perrocome2(){const o=W.perro,c=G("carmen"),i=W.marcas.indexOf(null);W.correa=0;await animalA("perro",c.x-14,c.y+2,"run");o.pose="eat";SFX.munch();if(i>=0)W.marcas[i]="p";await wait(700);await animalA("perro",54,206,"walk");o.pose="sit";o.dir=1;W.correa="floja";},
  async final13(){const n=(W.marcas||[]).filter(m=>m==="c").length,c=G("carmen"),o=W.perro;await mueve("carmen",156,196);c.dir=-1;
    if(n>=3){W.heart=1;SFX.win();fx({t:"star",n:30,pts:[[90,150],[150,150],[120,130],[100,176],[140,176]]});await wait(900);}else if(n){SFX.win();await wait(700);}else{SFX.coqui();await wait(700);}
    W.correa=0;await animalA("perro",c.x-26,c.y+4,"walk");o.pose="lie";o.dir=1;o.bub="amor";await wait(900);o.bub=null;},
  /* ---- story 14: the walk back with the dog ---- */
  async inicio14(){W.gente={abuela:{x:66,y:182,pose:"idle",dir:1},luis:{x:88,y:200,pose:"idle"},carmen:{x:46,y:202,pose:"idle"}};W.guineos=3;W.t=1;{const p=perroT(.46);W.arbusto=[R(p[0])+16,R(p[1])+5];}const f=enT(1);Object.assign(W.cq,{x:f[0],y:f[1],s:f[2]});const d=perroT(1);W.perro={x:d[0],y:d[1],pose:"sit",dir:-1};W.correa="floja";},
  // the two of them go on down the path. modo: trota (his easy trot), husmea (creeping, the snail keeps up), corre (flat out, the frog pulled off his feet), ligero (long quick steps)
  async paseo(o){const m=o.modo==="despacio"?"husmea":o.modo==="rapido"?"ligero":o.modo,d=+(o.d||.1),t1=Math.max(.02,W.t-d),pasos=m==="husmea"?26:m==="corre"?7:m==="ligero"?9:15,q=W.cq,pe=W.perro,t0=W.t,solo=o.solo;
    pe.pose=m==="corre"?"run":"walk";pe.dir=-1;W.correa=m==="corre"?"tensa":"floja";if(m==="corre"&&!solo)W.arrastra=-1;if(m==="husmea")W.caracol={x:pe.x-4,y:pe.y+8};else if(solo!=="cq")W.caracol=null;
    for(let i=1;i<=pasos;i++){const t=t0+(t1-t0)*i/pasos,f=enT(solo==="perro"?t0:t),p=perroT(solo==="cq"?t0:t);if(solo!=="perro"){q.x=f[0];q.y=f[1]-(m==="corre"?4:0);q.s=f[2];q.dy=m==="corre"?0:-(i%2)*(m==="ligero"?3:2);}if(solo!=="cq"){pe.x=p[0];pe.y=p[1];}
      if(W.caracol){W.caracol.x=pe.x-4;W.caracol.y=pe.y+8;}if(m==="corre"||m==="ligero")W.polvo={x:R(pe.x)+10,y:R(pe.y),dir:1};if(i%3===0)(m==="corre"?SFX.hop:SFX.blip)();await wait(TICK);}
    q.dy=0;W.polvo=null;W.arrastra=0;if(!solo)W.t=t1;if(m==="corre"){const f=enT(W.t);q.y=f[1];}pe.pose="sit";},
  // the dog stops dead, nose in a flower
  async para(){const pe=W.perro;W.caracol=null;pe.pose="husmea";W.correa="floja";SFX.blip();await wait(700);},
  // what the dog is doing, for him to see: he bolts and keeps pulling, or he has stopped
  async situacion(o){const pe=W.perro;if(o.que==="corre"){await acts.paseo({modo:"corre",d:.03});pe.pose="run";W.correa="tensa";W.arrastra=-1;}else await acts.para();},
  // wrong word: even more of the same
  async masde(o){const pe=W.perro;if(o.que==="corre"){await acts.paseo({modo:"corre",d:.03});}else{pe.pose="lie";await wait(600);}},
  // the dog goes at the pace that was called, the frog at the other: the leash jerks
  async desigual(o){await Promise.all([acts.paseo({modo:o.p,d:.07,solo:"perro"}),acts.paseo({modo:o.f,d:.03,solo:"cq"})]);W.caracol=null;},
  async vuelveperro(){const p=perroT(W.t);await animalA("perro",p[0],p[1],"walk");W.perro.pose="sit";W.perro.dir=-1;},
  async trota(){W.caracol=null;W.perro.pose="sit";W.correa="floja";await acts.paseo({modo:"trota",d:.06});},
  async tropieza(){const q=W.cq;SFX.bonk();for(const x of [3,-3,4,-2,0]){W.tumbo=x;q.dy=-Math.abs(x);await wait(TICK*1.5);}q.dy=0;W.perro.pose="bark";await wait(300);W.perro.pose="sit";W.tarjeta="guineos";SFX.luz();await wait(600);},
  // the leash jerks, a guineo falls out, and Canelo eats it
  async cae(){const q=W.cq,b=frogBox(q),pe=W.perro;SFX.bonk();W.correa="tensa";for(const x of [4,-4,3,0]){W.tumbo=x;await wait(TICK);}W.guineos=Math.max(0,W.guineos-1);
    W.vuela={k:"guineo",x:b.x+b.w/2,y:b.y-12};for(let i=1;i<=6;i++){W.vuela.x=b.x+b.w/2+(pe.x-b.x-b.w/2)*i/6;W.vuela.y=b.y-12+(pe.y-10-b.y+12)*i/6-Math.sin(Math.PI*i/6)*10;await wait(TICK);}W.vuela=null;pe.pose="eat";SFX.munch();await wait(700);pe.pose="sit";W.correa="floja";},
  // behind the bush: only the leash shows
  async arbusto(){const pe=W.perro;await animalA("perro",W.arbusto[0]+2,W.arbusto[1]-4,"walk");pe.vis=0;W.correaA=[W.arbusto[0]+6,W.arbusto[1]-10];await wait(300);},
  async sale(o){const pe=W.perro;if(pe.vis!==0){await acts.trota();return;}pe.vis=1;W.correaA=null;const p=perroT(W.t-.16);pe.x=W.arbusto[0]-8;pe.y=W.arbusto[1];await animalA("perro",p[0],p[1],o.modo==="corre"?"run":"walk");pe.pose="sit";pe.dir=-1;W.t=W.t-.1;const f=enT(W.t);await hopTo(f[0],f[1],2,f[2]);},
  async tira(){const q=W.cq;W.correa="tensa";for(let k=0;k<3;k++){q.dy=-3;SFX.hop();await wait(160);q.dy=0;await wait(160);}},
  async final14(){const n=W.guineos||0,ab=G("abuela"),q=W.cq,pe=W.perro;W.caracol=null;const f=enT(.06);pe.pose="walk";await Promise.all([hopTo(f[0],f[1],2,f[2]),animalA("perro",ab.x+16,ab.y+10,"walk")]);pe.pose="sit";W.t=.06;await wait(250);
    ab.pose="offer";await wait(300);W.guineos=null;W.tarjeta=null;ab.lleva="cesta";ab.guineos=n;SFX.blip();await wait(400);ab.pose="idle";
    if(n>=3){W.heart=1;SFX.win();fx({t:"star",n:30,pts:[[40,120],[90,130],[64,110],[50,150],[90,160]]});await wait(900);}else if(n){SFX.win();await wait(700);}else{pe.pose="eat";ab.rie=1;SFX.coqui();await wait(900);ab.rie=0;pe.pose="sit";}
    W.correa="floja";W.correaDe="abuela";pe.bub="amor";await wait(700);pe.bub=null;},
  async sevan(){const q=W.cq;W.correa=0;const fuera=async id=>{const p=G(id);for(let i=0;i<8;i++){p.x-=4;p.al=1-i/8;await wait(TICK);}p.vis=0;};await Promise.all([fuera("abuela"),fuera("luis"),fuera("carmen"),animalA("perro",-10,W.perro.y,"walk"),hopTo(8,q.y,2,q.s)]);q.vis=0;W.perro.vis=0;await wait(500);},
};
async function stake(lost,max,en){SFX.bonk();await wait(300);}
function poke(what){const p=W.gente&&W.gente[what];if(p&&!p.bub){p.bub="amor";const my=runId;setTimeout(()=>{if(my===runId&&p.bub==="amor")p.bub=null;},1400/FAST);}
  if(what==="perro"&&W.perro){ladra(1);}}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k]&&W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)).join(" ")+" perro="+(W.perro?R(W.perro.x)+","+R(W.perro.y)+":"+W.perro.pose:"-")+" gato="+(W.gato?(W.gato.en!=null?"en"+W.gato.en:R(W.gato.x)+","+R(W.gato.y))+":"+W.gato.pose:"-")+
  " pajaros="+(W.pajaros||[]).join("")+" galletas="+W.galletas+" guineos="+W.guineos+" correa="+(W.correa||0);
KIT.escena({id:"camino",CAM:{wide:[22,0,196,216]},heartAt:[110,30],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({gente:{},perro:null,gato:null,pajaros:[0,0,0],vuelan:0,sinGran:0,lit:null,caracol:null,arbusto:null,arrastra:0,correaDe:null,marcas:null,pos:{cq:0,carmen:0},t:1,correaA:null,tiembla:0,avebanco:0,correa:0,guineos:null,galletas:null,galleta:0,tarjeta:null,vuela:null,polvo:null,tumbo:0,ave:null,cq:{x:LUGAR.inicio[0],y:LUGAR.inicio[1],s:1,dy:0,al:1,vis:1,bub:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
window.CAMINO={MARCA,ARBOL,LUGAR,ranaEn,ninaEn};
})();
