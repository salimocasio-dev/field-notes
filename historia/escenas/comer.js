"use strict";
/* ============================================================
   Coquí · scene "A comer": abuela's kitchen table (place 3, La cocina, scene 4).
   The kitchen of La mesa with a deeper table: seen a little from above, four chairs behind it and a
   place at each (a plate in front). The counter (with a sink) at the left, the stove at the right with a
   shelf over it, the door to the yard at the left, out of the picture.
   The table top has three rows (the feet of what stands there): FILA at the back (the places), MED in the
   middle, FREN at the front (where the frog works). Whoever stands in front of the table hides what is
   behind him, so people stand at the two ends of the table (LE: left end, DER: right end) or behind it
   (their hands then reach over the table: what they hold is drawn over the table, never under it).
   Every move is a hand's: somebody walks to a thing, holds it, puts it down. Nothing flies.
   People live in W.gente, by name: {x,y (feet), dir, sent (sitting), pose, vis, tiene (what is held: a list
   of {k,v,dx,dy,e,flip,arm}, the middle of each thing measured from the feet, dx towards where he faces), come
   (a thing at his mouth), cara ("mal": a frown), dy, bebe2}.
   Everything on the table is a thing in W.cosas: {id,k,v,x,y,z,e,vis,vapor}.
   Stories 33 (¿Qué quieres?), 34 (Buen provecho) and 35 (Café con azúcar).
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round,tarjeta=KIT.tarjeta,mkPerro=KIT.mkPerro;
const PISO=142,MESA=[66,112,120,60],SILLA=[90,114,138,162],MOSTR=[24,106,44,12],ESTUFA=[190,108,38,38],ESTANTE=[194,96,28];   // the floor; the table top (x, y of its far edge, width, depth); the four chairs; the counter top; the stove; the shelf over the stove
const FILA=124,MED=148,FREN=170,TZ=173,ASIENTO=132,ATRAS=122,FR=212,FLO=154;   // the rows of the table top; where somebody sitting has his feet; the lane behind the table, a lane higher than the seated (drawn behind them, so a walker never crosses a face or a hand); the lane along the front of the table, below its legs; the floor in front of the counter and the stove, where somebody steps in under the cloth to go behind the table
// FOGON: where abuela stands by the stove (on the floor, in front of the oven door, so that what stands on the stove top is over her head, not behind it); AFOGON: where she stands to take something off the stove top
const LE=[66,190],CAR=[46,194],FOGON=[208,168],AFOGON=[208,153],DER=[208,176],PUERTA=[0,190];   // the left end of the table, where he who comes in stands; Carmen beside him; abuela at the stove; the right end; the door (out of the picture)
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,abuelo:Object.assign({},FAM.abuelo,{ropa:RP.grn.slice(1),detalle:(b,X,tc,rx,t)=>{b.rect(X,tc-8,1,t+6,RP.grn[0]);b.rect(X-5,tc-1,3,3,RP.grn[0]);b.rect(X+3,tc-1,3,3,RP.grn[0]);b.rect(X-5,tc-1,3,1,RP.grn[3]);b.rect(X+3,tc-1,3,1,RP.grn[3]);}}),mama:FAM.mama,papa:FAM.papa,abuela:{}};   // abuelo wears a green shirt here: the cream of his own would melt into the cream wall
const PLATO=["#2A5C9C","#4A86C8","#8CB8E8"];   // the plates are blue: nothing white is lost on them
const TAN=["#A8682C","#C8853C","#E2A85A"],CHOC=["#2A1408","#5A2E14","#8A5A34"],MANT="#FFE070",ARROZ=["#C88A10","#F2C028","#FFE870"];
const CERA=["#7A8AB8","#C4D0F0","#FFFFFF"];   // the white-blue china of the bowls
const LIQ={negro:"#0C0806",marron:"#3A1A0A",palido:"#EBD3AC",leche:"#FFFFFF",vacia:"#4A84E0",azu:"#0C0806"};   // seen from above: black coffee near black, a deep chocolate for much coffee, a very pale milky coffee for a little, pure white milk, and the empty cup shows its own mid blue inside   // what is in a cup, seen from above

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),Wd=RP.wood,M=MOSTR,E=ESTUFA;
  for(let y=0;y<PISO;y++)for(let x=0;x<SW;x++)b.px(x,y,y>PISO-5?"#C8B88A":hs(x>>2,y>>2)<6?"#F0E4B8":"#F6ECC4");
  for(let y=84;y<M[1];y++)for(let x=22;x<70;x++)b.px(x,y,(x%8===0||y%8===4)?"#B8D0D8":"#E4F0F4");
  for(let y=86;y<E[1];y++)for(let x=184;x<SW;x++)b.px(x,y,(x%8===2||y%8===0)?"#B8D0D8":"#E4F0F4");
  for(let y=PISO;y<SH;y++)for(let x=0;x<SW;x++){const ty=Math.floor((y-PISO)/12),tx=Math.floor((x+ty*6)/16);b.px(x,y,((y-PISO)%12===0||(x+ty*6)%16===0)?"#9A6A54":(tx+ty)%2?"#C8745A":"#E8D8B8");}
  for(let x=0;x<SW;x++)b.px(x,PISO-1,"#7A6A4A");
  // the door to the yard, at the left edge (out of the picture)
  b.rect(0,58,20,PISO-58,"#9CCBF5");b.rect(0,112,20,PISO-112,RP.grn[2]);b.rect(20,56,3,PISO-56,Wd[1]);b.rect(0,56,22,3,Wd[1]);
  // the window over the stove
  b.rect(190,24,34,34,"#9CCBF5");b.ell(216,50,10,8,RP.grn);b.frame(188,22,38,38,Wd[1]);b.frame(189,23,36,36,Wd[3]);b.rect(206,24,2,34,Wd[2]);b.rect(190,40,34,2,Wd[2]);
  // the shelf over the stove, with its brackets
  b.rect(ESTANTE[0],ESTANTE[1],ESTANTE[2],3,Wd[3]);b.rect(ESTANTE[0],ESTANTE[1]+3,ESTANTE[2],1,Wd[0]);b.frame(ESTANTE[0]-1,ESTANTE[1]-1,ESTANTE[2]+2,6,OUT);b.rect(ESTANTE[0]+3,ESTANTE[1]+4,2,5,Wd[1]);b.rect(ESTANTE[0]+ESTANTE[2]-5,ESTANTE[1]+4,2,5,Wd[1]);
  // the cupboard over the counter
  b.rect(27,34,42,40,Wd[2]);b.rect(27,34,42,2,Wd[4]);b.rect(27,72,42,2,Wd[0]);b.frame(26,33,44,42,OUT);b.rect(47,36,2,36,Wd[0]);[43,51].forEach(x=>b.rect(x,52,2,6,"#F0C020"));b.frame(30,38,16,32,Wd[1]);b.frame(50,38,16,32,Wd[1]);
  // the counter: a cabinet with two doors, a pale top seen a little from above, a sink set into it
  b.rect(M[0],M[1]+M[3],M[2],PISO+4-M[1]-M[3],Wd[2]);b.rect(M[0],M[1]+M[3],M[2],2,Wd[0]);b.frame(M[0]-1,M[1]+M[3]-1,M[2]+2,PISO+6-M[1]-M[3],OUT);
  b.rect(M[0]+20,M[1]+M[3]+3,2,20,Wd[0]);[M[0]+16,M[0]+26].forEach(x=>b.rect(x,M[1]+M[3]+9,2,5,"#F0C020"));
  b.rect(M[0]-2,M[1],M[2]+4,M[3],"#E8E8F0");b.rect(M[0]-2,M[1],M[2]+4,2,"#FFFFFF");b.rect(M[0]-2,M[1]+M[3]-2,M[2]+4,2,"#B8B8C8");b.frame(M[0]-3,M[1]-1,M[2]+6,M[3]+2,OUT);
  b.rect(46,M[1]+2,16,8,"#8A8EA0");b.rect(47,M[1]+3,14,6,"#C8CCDA");b.rect(47,M[1]+3,14,1,"#6A6E80");b.rect(54,M[1]-8,2,9,"#8A8EA0");b.rect(54,M[1]-9,6,2,"#8A8EA0");
  // the stove: a dark top with two burners, a white front with three knobs and an oven door
  b.rect(E[0],E[1],E[2],E[3],"#F2F2F8");b.rect(E[0],E[1],E[2],10,"#3A3A46");b.rect(E[0],E[1]+10,E[2],2,"#C8C8D4");b.frame(E[0]-1,E[1]-1,E[2]+2,E[3]+2,OUT);
  [E[0]+9,E[0]+27].forEach(x=>{b.ell(x,E[1]+5,6,2.6,["#16161E","#2A2A36"]);b.ell(x,E[1]+5,3.6,1.5,["#5A2018","#8A3028"]);});
  b.frame(E[0]+4,E[1]+20,E[2]-8,16,"#B8B8C8");b.rect(E[0]+8,E[1]+23,E[2]-16,2,"#8A8A9A");[E[0]+7,E[0]+17,E[0]+27].forEach(x=>b.rect(x,E[1]+14,3,3,"#D0302A"));
  // the four chairs: their backs show over the far edge of the table
  SILLA.forEach(x=>{b.rect(x-9,MESA[1]-26,2,44,Wd[0]);b.rect(x+7,MESA[1]-26,2,44,Wd[0]);[MESA[1]-26,MESA[1]-18].forEach(y=>{b.rect(x-9,y,18,4,Wd[2]);b.rect(x-9,y,18,1,Wd[4]);});b.frame(x-10,MESA[1]-27,20,10,OUT);});
  return b.done();}
// the table: a red and white cloth, drawn over the people who sit behind it; its legs stand in from the corners, so nobody at an end stands on one
function mkMesa(){const w=MESA[2],d=MESA[3],b=new Buf(w+12,d+34);
  for(let y=0;y<d;y++){const x0=R(6-y*6/d),ww=w+R(y*12/d);for(let x=0;x<ww;x++)b.px(x0+x,y,(((x>>2)+(y>>2))%2)?"#FFFFFF":"#F4B8B0");}
  for(let x=0;x<w+12;x++){b.px(x,d,"#D0302A");b.px(x,d+1,"#D8D8E4");b.px(x,d+2,"#D8D8E4");b.px(x,d+3,"#FFFFFF");b.px(x,d+4,(x>>2)%2?"#F4B8B0":"#FFFFFF");}
  [[10,d+5],[w-4,d+5]].forEach(p=>{b.rect(p[0],p[1],4,28,RP.wood[1]);b.rect(p[0],p[1],1,28,RP.wood[2]);});
  return b.outline().done();}
// the high chair of the baby (v="1": the baby is in it)
function mkSillaBebe(v){const b=new Buf(26,36),W=RP.wood;
  b.rect(3,18,2,17,W[0]);b.rect(19,18,2,17,W[0]);b.rect(3,30,18,2,W[1]);   // legs, a rung
  b.rect(2,16,20,3,W[2]);b.rect(2,16,20,1,W[4]);   // the seat
  b.rect(2,2,2,15,W[1]);b.rect(20,2,2,15,W[1]);b.rect(2,2,20,3,W[2]);b.rect(2,2,20,1,W[4]);   // the back
  if(v==="1"){   // a baby: a big round head with a tuft of hair, round cheeks, a smile, a white bib on a yellow shirt, one hand up holding a small spoon
    b.ell(12,14,7.6,5.6,["#B87A10","#E0A020","#F8C838"]);b.ell(12,15,4.4,3.6,["#E8F0FA","#FFFFFF"]);b.rect(8,12,8,1,"#8CB8E8");   // shirt and bib
    b.ell(12,7.2,6.6,6.4,RP.skin.slice(2));b.px(10,6,"#20140A");b.px(14,6,"#20140A");b.px(10,5,"#FFFFFF");b.px(14,5,"#FFFFFF");b.px(8,9,"#E08A70");b.px(16,9,"#E08A70");b.rect(11,10,3,1,"#7A2A1A");b.px(10,9,"#7A2A1A");b.px(14,9,"#7A2A1A");
    b.px(12,0,KIT.PELO.castano[2]);b.px(13,1,KIT.PELO.castano[2]);b.px(11,1,KIT.PELO.castano[2]);b.px(12,1,KIT.PELO.castano[2]);
    b.rect(16,12,3,2,RP.skin[2]);b.rect(18,9,3,4,RP.skin[2]);b.rect(19,8,2,2,RP.skin[2]);   // his arm, from the shoulder up to his fist
    b.ell(20,7,2.2,2.2,RP.skin.slice(2));b.rect(21,1,1,6,"#C8C8D4");b.ell(21.5,1,1.8,1.4,["#C8C8D4","#F8F8FF"]);   // a small spoon in his fist
  }else{b.rect(14,17,6,1,"#C8C8D4");b.ell(21,17,1.8,.9,["#C8C8D4","#F8F8FF"]);}   // the spoon lies on the tray while he is out of the chair
  b.rect(0,19,24,3,"#8CB8E8");b.rect(0,19,24,1,"#D8E8FA");   // the tray
  return b.outline().done();}

/* ---------- sprites ---------- */
const borra=(b,cx,cy,r)=>{for(let y=Math.floor(cy-r);y<=Math.ceil(cy+r);y++)for(let x=Math.floor(cx-r);x<=Math.ceil(cx+r);x++)if(x>=0&&y>=0&&x<b.w&&y<b.h&&(x+.5-cx)*(x+.5-cx)+(y+.5-cy)*(y+.5-cy)<=r*r)b.d[(y*b.w+x)*4+3]=0;};
// a copy turned by ang (radians, clockwise on the screen), nearest pixels, so it stays crisp; pico: a point of it (the lip of a pot) turned with it
function giro(cv,ang,pico){const w=cv.width,h=cv.height,r=Math.ceil(Math.hypot(w,h)),b=new Buf(r,r),sc=cv.getContext("2d").getImageData(0,0,w,h).data,cs=Math.cos(ang),sn=Math.sin(ang),cx=w/2,cy=h/2,ox=r/2,oy=r/2;
  for(let y=0;y<r;y++)for(let x=0;x<r;x++){const dx=x+.5-ox,dy=y+.5-oy,sx=Math.floor(dx*cs+dy*sn+cx),sy=Math.floor(-dx*sn+dy*cs+cy);if(sx<0||sy<0||sx>=w||sy>=h)continue;const i=(sy*w+sx)*4;if(sc[i+3]>0)b.px(x,y,"#"+[0,1,2].map(k=>sc[i+k].toString(16).padStart(2,"0")).join(""));}
  const out=b.done();if(pico){const dx=pico[0]-cx,dy=pico[1]-cy;out.pico=[ox+dx*cs-dy*sn,oy+dx*sn+dy*cs];}return out;}
function bola(b,x,y,rx,ry,col){b.ell(x,y,rx,ry,col);}
function rollitos(b,x,yb){   // a small split roll in the basket or on the tray: its foot at (x,yb), 10 x 6, with its own dark edge so that the rolls can be counted
  b.ell(x,yb-2.8,5.2,3.1,[OUT]);b.ell(x,yb-2.8,4.3,2.3,TAN);b.rect(x-3,yb-4,6,1,"#FFF0C8");b.rect(x-3,yb-2,6,1,"#8A5A18");b.px(x-2,yb-5,"#F4CC88");}
// a wedge of cake at (x0,y0), k its size: frosting white on top (a triangle), then sponge, jam, sponge down its front, a cherry
function tajada(b,x0,y0,k){k=k||1;const X=v=>Math.round(x0+v*k),Y=v=>Math.round(y0+v*k),W=Math.max(1,Math.round(14*k));
  for(let r=0;r<5;r++){const a=X(1+r*2),e=X(15),yy=Y(1+r);for(let x=a;x<=e;x++)b.px(x,yy,r===0?"#FFFFFF":"#FFF4E0");if(k>.8)b.px(e,yy,"#E8D8C0");}
  const fy=Y(6);for(let y=fy;y<fy+Math.max(2,Math.round(2*k));y++)for(let x=X(5);x<=X(15);x++)b.px(x,y,"#E8B050");
  for(let x=X(5);x<=X(15);x++)b.px(x,fy+Math.max(2,Math.round(2*k)),"#C8302A");
  const sy=fy+Math.max(3,Math.round(3*k));for(let y=sy;y<sy+Math.max(2,Math.round(3*k));y++)for(let x=X(5);x<=X(15);x++)b.px(x,y,"#D89A3C");
  b.px(X(11),Y(0),"#D0302A");b.px(X(12),Y(0),"#D0302A");b.px(X(11),Y(-1),"#48A848");}

// a cup, 17 x 17: foot, side with a handle, rim, what is in it. sp: a teaspoon stands in it
function mkTaza(v,sp){const b=new Buf(17,17);v=v||"";const monton=/\+$/.test(v);if(monton)v=v.slice(0,-1);const mitad=/_$/.test(v),L=LIQ[mitad?v.slice(0,-1):v]||LIQ.vacia;if(mitad)v=v.slice(0,-1);
  b.ell(6.6,13.2,5.4,3,["#1E4FA8","#2E6CD0","#4A8CE8"]);b.rect(1,7,11,6,"#2E6CD0");b.rect(1,7,3,6,"#4A8CE8");b.rect(9,7,3,6,"#1E4FA8");
  b.cap(12,9,15,9.6,1.1,["#1E4FA8","#2E6CD0"]);b.cap(15,9.6,13.2,12.4,1.1,["#1E4FA8","#2E6CD0"]);borra(b,14,10.6,.9);
  b.ell(6.6,7,6.2,2.7,["#B4C8F0","#E4ECFF","#FFFFFF"]);
  if(v==="vacia"){b.ell(6.6,7,4.9,2,[LIQ.vacia]);b.px(4,6,"#9CC0F4");b.px(5,6,"#9CC0F4");}   // empty: the cup's own mid blue inside, no liquid
  else if(mitad){b.ell(6.6,6.8,4.9,2.1,[LIQ.vacia]);b.ell(6.6,7.8,3.6,1.3,[L]);}
  else if(v==="leche")b.ell(6.6,7.1,4.8,1.9,["#FFFFFF"]);
  else{b.ell(6.6,7.1,4.8,1.9,[L]);if(v==="negro"||v==="azu")b.px(4,6,"#5A3A28");if(v==="marron")b.px(4,6,"#A87848");if(v==="palido")b.px(4,6,"#F0CC88");}
  if(v==="azu"){b.ell(6.6,6.4,3.8,2.2,["#C8BEA0","#E6DDC2","#F6F0DC"]);b.ell(6.6,4.8,2.2,1.5,["#E6DDC2","#F6F0DC"]);[[4,6],[6,5],[8,6],[5,7],[7,4],[9,7]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#9A8A66":"#FFFBEA"));sp=1;}   // too much sugar: an off-white heap of grains on the coffee, and a spoon
  if(monton){b.ell(6.6,6,3,1.8,["#C8CEE0","#FFFFFF"]);b.px(6,4,"#FFFFFF");b.px(8,5,"#FFFFFF");}   // a small white heap of sugar on the coffee, for a moment before it is stirred in
  if(sp){b.rect(7,0,2,8,"#E0E0EC");b.rect(8,0,1,8,"#8A8A9A");b.rect(7,0,1,1,"#FFFFFF");}
  return b.outline().done();}
const COSA={
  // a blue plate, 17 x 10 (15 wide: a little wider than a roll, narrower than a grown-up's shoulders); v: what lies on it. "r" rice, "r2" less, "r1" a little, "o" a mound, "rm" rice and a mound, "h" a mound mixed into the rice (a heap), "mi" crumbs, "p1".."p3" mounds
  plato(v){const b=new Buf(17,10);b.ell(8.5,5.4,7.4,3.1,PLATO);b.ell(8.5,5,5.2,2,["#6AA0DC","#A8CCF0"]);v=v||"";
    if(v==="r"||v==="rm"||v==="h"){b.ell(8.5,4.8,4.6,1.8,["#C88A10","#F2C028","#FFE060"]);[[6,4],[9,5],[11,4],[7,6]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    if(v==="r2"){b.ell(8.5,4.9,3.4,1.4,["#C88A10","#F2C028","#FFE060"]);[[7,5],[10,4]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    if(v==="r1"){b.ell(8.5,4.9,2,.9,["#C88A10","#F2C028","#FFE060"]);b.px(8,4,"#FFF4B0");}
    if(v==="o1"){b.ell(8.5,4.4,1.8,1.3,ARROZ);b.px(8,4,"#FFF4B0");}
    if(v==="rm"||v==="o"){b.ell(8.5,3.7,2.8,2.2,ARROZ);b.px(7,2,"#FFF4B0");b.px(9,3,"#FFF4B0");b.px(10,5,"#B87A10");}
    if(v==="h"){b.ell(6.8,3.8,2.7,2.1,ARROZ);b.ell(10.6,4,2.5,1.9,ARROZ);b.px(6,2,"#B87A10");b.px(11,3,"#B87A10");b.px(8,2,"#FFF4B0");}
    if(v==="mi"){[[6,5],[8,6],[11,5],[13,5],[9,4]].forEach(q=>b.px(q[0],q[1],"#C8853C"));}
    if(/^p[123]$/.test(v)){[[4.4,5.6],[12.6,5.6],[8.5,3.4]].slice(0,+v[1]).forEach(q=>{b.ell(q[0],q[1]+1.3,2.3,.9,["#B87A10"]);b.ell(q[0],q[1],1.9,1.5,ARROZ);b.px(q[0]-1,q[1]-1,"#FFF4B0");});}   // papá's mounds: three separate ones (two in front, one behind), each with its own shadow; the first two are the left and the right one
    return b.outline().done();},
  // a child's plate, 15 x 9 (13 wide); v "mi": crumbs
  platoc(v){const b=new Buf(15,9);b.ell(7.5,5,6.4,2.7,PLATO);b.ell(7.5,4.7,4.4,1.7,["#6AA0DC","#A8CCF0"]);if(v==="mi"){[[5,5],[7,6],[10,4],[9,6],[6,4]].forEach(q=>b.px(q[0],q[1],"#C8853C"));}return b.outline().done();},
  // a plate with an apple on it; a plate with a huge heap of rice; a white jug of milk; drops of water
  platoma(){const b=new Buf(26,20);b.ell(13,15.6,12.4,4.4,PLATO);b.ell(13,15,8.4,2.8,["#6AA0DC","#A8CCF0"]);b.ell(9.4,9.4,4.2,4.6,["#A01818","#D02828","#F05848"]);b.ell(15.6,9.4,4.2,4.6,["#A01818","#D02828","#F05848"]);b.rect(12,3,2,4,"#5A3A1A");b.rect(14,3,3,2,"#48A848");b.px(7,7,"#FFB0A0");b.px(8,6,"#FFB0A0");return b.outline().done();},
  platoH(){const b=new Buf(26,20);b.ell(13,15.6,12.4,4.4,PLATO);b.ell(13,15,8.4,2.8,["#6AA0DC","#A8CCF0"]);b.ell(13,12.4,8.6,3.8,["#F0F0F4","#FFFFFF"]);b.ell(13,8.6,7,5.4,["#E4E4EC","#F8F8FC","#FFFFFF"]);b.ell(13,4.8,4,3.2,["#E4E4EC","#F8F8FC","#FFFFFF"]);[[9,9],[14,7],[16,11],[11,12],[10,6],[13,4],[17,9]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#C8C8D8":"#FFFFFF"));return b.outline().done();},
  gotas(){const b=new Buf(14,10);[[1,6],[4,2],[7,5],[10,1],[12,6],[3,8],[9,8]].forEach(q=>{b.rect(q[0],q[1],2,2,"#78B8F0");b.px(q[0],q[1],"#E4F4FF");});return b.outline().done();},
  // the frog's own small plate
  platito(v){const b=new Buf(14,8);b.ell(7,4.6,5.8,2.4,PLATO);b.ell(7,4.3,3.8,1.5,["#6AA0DC","#A8CCF0"]);if(v==="o"){b.ell(7,3.4,2.4,1.9,ARROZ);b.px(6,2,"#FFF4B0");}else if(v==="o2"){b.ell(7,3.8,1.8,1.4,ARROZ);b.px(6,3,"#FFF4B0");}else if(v==="o1"){b.ell(7,4,1.1,.9,ARROZ);}if(v==="mi"){[[5,4],[8,5],[10,3]].forEach(q=>b.px(q[0],q[1],"#C8853C"));}return b.outline().done();},
  // a roll, 17 x 12: the same size as the rolls in the basket, everywhere (basket, board, hand, plate). "ab" cut open and empty, "ab:c"/"ab:m" open with chocolate / butter in it, "ce" closed, "ce:c"/"ce:m" closed with the filling showing at the seam, "mo:c"/"mo:m" with a bite out of it, "m2" half eaten
  rollo(v){const s=String(v||"ce").split(":"),st=s[0],con=s[1],F=con==="c"?CHOC[1]:MANT,FL=con==="c"?CHOC[2]:"#FFFBE0",b=new Buf(11,9),X=5.5;
    if(st==="ab"){b.ell(X,5.4,4.4,2.6,TAN);b.ell(X,4.3,3.5,1.5,["#FFF0C8","#FFFAE4"]);b.rect(3,6,5,1,"#8A5A18");if(con)b.ell(X,4.4,3,1.1,[F,F,FL]);}
    else if(st==="m2"){b.ell(4.3,5.5,3.2,2.4,TAN);b.rect(2,6,4,1,"#8A5A18");borra(b,8,4.2,2.1);b.ell(6.6,5.2,1.1,1.6,["#FFF0C8","#FFFAE4"]);if(con)b.ell(6.6,5.4,.7,.9,[F,F,FL]);b.px(8,7,"#C8853C");}
    else if(st==="mo"){b.ell(X,5.4,4.4,2.6,TAN);b.rect(3,6,5,1,"#8A5A18");b.px(3,4,"#F4CC88");b.px(4,4,"#F4CC88");borra(b,9.4,3.9,2.1);b.ell(8,5,1.3,1.6,["#FFF0C8","#FFFAE4"]);if(con)b.ell(8,5.2,.8,1,[F,F,FL]);else b.ell(8,5.2,.8,1,["#E8D4A0"]);}
    else{b.ell(X,5.4,4.4,2.6,TAN);b.rect(3,6,5,1,"#8A5A18");b.px(3,4,"#F4CC88");b.px(4,4,"#F4CC88");b.px(5,4,"#F4CC88");if(con){b.rect(2,5,7,1,F);b.rect(3,5,5,1,FL);}}
    return b.outline().done();},
  // the basket of rolls (36 x 21), low enough to leave the places behind it free. v: "n:c": n rolls (0 to 5), c = 1 the cloth lies over them; the cloth otherwise lies folded on the right rim, a small striped towel, inside the basket's outline, on the left rim
  cesta(v){const b=new Buf(36,21),s=String(v==null?"5:0":v).split(":"),n=+s[0],tapa=s[1]==="1",media=s[1]==="2",sin=s[1]==="4";
    if(!tapa){
      const P=[[12,13],[21,13],[30,13],[16.5,10],[25.5,10]];P.slice(0,n).slice().sort((p,q)=>p[1]-q[1]).forEach(p=>rollitos(b,p[0],p[1]));}
    b.rect(1,13,32,7,"#B07A3C");for(let x=2;x<33;x+=4)b.rect(x,13,2,7,"#8A5A2A");b.rect(0,12,34,2,"#D09A54");b.rect(0,19,34,1,"#7A4A1E");
    if(tapa&&n<=1){b.ell(19.5,11.4,2.8,2.2,TAN);b.px(18,10,"#F4CC88");b.ell(11,9.6,9.4,4.2,["#D0302A","#F4B8B0","#FFFFFF"]);for(let x=3;x<19;x+=4)b.rect(x,7+(x%8?0:1),2,4,"#FFFFFF");b.rect(1,11,21,2,"#F4B8B0");for(let x=2;x<21;x+=4)b.rect(x,11,2,2,"#D0302A");}   // one roll lies under a small cloth, its end showing
    else if(tapa){if(n>0){b.ell(31,9.5,3,2.6,TAN);b.px(29,8,"#F4CC88");}b.ell(16,9.6,15,4.6,["#D0302A","#F4B8B0","#FFFFFF"]);for(let x=3;x<30;x+=4)b.rect(x,7+(x%8?0:1),2,4,"#FFFFFF");b.rect(1,11,32,2,"#F4B8B0");for(let x=2;x<33;x+=4)b.rect(x,11,2,2,"#D0302A");}
    else if(media){b.ell(22,9.6,10,4.2,["#D0302A","#F4B8B0","#FFFFFF"]);for(let x=14;x<30;x+=4)b.rect(x,7,2,4,"#FFFFFF");}   // the cloth half over the rolls
    else if(sin){}   // no towel on the rim: it is in her hand
    else{b.rect(2,6,6,6,"#FFFFFF");b.rect(2,6,6,1,"#E8E8F0");b.rect(4,6,1,6,"#D0302A");b.rect(7,6,1,6,"#D0302A");b.rect(2,11,6,1,"#D0302A");}   // a folded towel on the left rim (where abuela reaches it): white with red stripes
    return b.outline().done();},
  // the two fillings: the same small bowl of blue and white china, 22 x 15. butter: a yellow block (v = how much is left, 1 to 5); chocolate: melted, dark brown and shiny, with a spoon in it (v: the same)
  mantequilla(v){const b=new Buf(22,15),n=Math.max(1,Math.min(5,+(v||5)));b.ell(11,10.4,10.2,4,CERA);b.ell(11,8.6,8.4,3,["#8A96C0","#C4D0F0"]);b.rect(3,11,16,1,"#2E6CD0");
    const w=5+n*1.6|0,h=2+(n*.8|0),x0=11-(w>>1),y0=9-h;   // a block of butter in the dish: it gets smaller as it is used
    b.rect(x0,y0+1,w,h-1,MANT);b.rect(x0+1,y0,w-1,1,"#FFFBE0");b.rect(x0+w-1,y0+1,1,h-1,"#E0C860");b.rect(x0,y0+h-1,w,1,"#E0C860");
    return b.outline().done();},
  // melted chocolate in the same bowl: dark, glossy, filling the bowl; a spoon handle stands in it
  choc(v){const b=new Buf(22,15),n=Math.max(1,Math.min(5,+(v||5)));b.ell(11,10.4,10.2,4,CERA);b.ell(11,8.6,8.4,3,["#8A96C0","#C4D0F0"]);b.rect(3,11,16,1,"#2E6CD0");
    const rx=3.6+n*1,ry=1.3+n*.35;b.ell(11,8.8,rx,ry,[CHOC[0],CHOC[1],CHOC[2]]);b.px(8,8,"#C89A74");b.px(9,8,"#C89A74");b.px(13,9,"#A0724C");
    b.cap(13,8,18,2,.7,["#8A8A9A","#C8C8D4"]);b.px(18,1,"#F8F8FF");
    return b.outline().done();},
  // a wooden board to fill the roll on
  tabla(){const b=new Buf(24,9),W=RP.wood;b.rect(1,2,22,5,W[3]);b.rect(1,2,22,1,W[4]);b.rect(1,6,22,1,W[1]);b.rect(1,7,22,1,W[0]);for(let x=3;x<20;x+=5){b.rect(x,4,3,1,W[2]);}b.rect(19,3,3,1,W[0]);return b.outline().done();},
  tenedor(v){const b=new Buf(7,15);[1,3,5].forEach(x=>b.rect(x,4,1,4,"#E8E8F2"));b.rect(1,7,5,2,"#D0D0DC");b.rect(3,9,1,6,"#D0D0DC");b.rect(4,9,1,6,"#9A9AAC");if(v==="c"){b.ell(3.5,3.6,3,2.2,ARROZ);b.px(2,2,"#FFF4B0");}
    if(v==="t"){b.rect(0,0,7,2,"#FFF8EC");b.rect(0,2,7,3,"#A8682C");b.rect(0,2,7,1,"#E0A458");b.px(6,0,"#FFFFFF");b.px(0,4,"#7A4A1E");b.px(6,4,"#7A4A1E");}return b.outline().done();},   // v "c": with a forkful of rice on it; "t": with a piece of cake (cream on top, brown sponge)   // v "c": with a forkful of rice on it; "t": with a bite of cake
  cuchara(){const b=new Buf(7,12);b.ell(3.5,3,2.4,3,["#8A8A9C","#C8C8D4","#F8F8FF"]);b.rect(3,5,1,7,"#C8C8D4");b.rect(4,5,1,7,"#8A8A9C");return b.outline().done();},
  // a fork lying flat, tines to the left, 18 x 8
  tenedorH(){const b=new Buf(18,8);[1,3,5].forEach(y=>b.rect(0,y,6,1,"#E8E8F2"));b.rect(5,1,2,5,"#D0D0DC");b.rect(7,3,10,2,"#D0D0DC");b.rect(7,4,10,1,"#9A9AAC");return b.outline().done();},
  // a mound of yellow rice, 10 x 8
  monton(v){const b=new Buf(6,5);if(v==="1"){b.ell(3,3,2,1.5,ARROZ);b.px(2,2,"#FFF4B0");}else if(v==="2"){b.ell(3,3.2,1.2,.9,ARROZ);}else{b.ell(3,2.8,2.5,1.9,ARROZ);b.px(2,1,"#FFF4B0");b.px(4,2,"#FFF4B0");b.rect(1,4,4,1,"#B87A10");}return b.done();},
  // the pot of rice on the table, 24 x 21: "lleno" (heaped, with its spoon), "lleno0" (no spoon), "vacio"
  olla(v){const b=new Buf(24,21);b.rect(3,7,18,12,"#8A8A9A");b.rect(3,7,5,12,"#B8B8C8");b.rect(3,16,18,3,"#5A5A6A");b.rect(0,9,3,3,"#3A3A46");b.rect(21,9,3,3,"#3A3A46");b.ell(12,7,9,3.2,["#5A5A6A","#9494A6","#C8C8D4"]);
    if(/^n[1-7]$/.test(v||"")){const L=+v[1];b.ell(12,7.2,7.4,2.6,["#1E1E28","#2A2A36"]);b.ell(12,6.8+L*.25,Math.max(2.4,7.4-L*.62),2.6-L*.14,["#C88A10","#F2C028","#FFE060"]);   // the rice goes down with every scoop: the surface is smaller and lower
      if(L<=3){b.ell(12,5.4+L*.5,Math.max(1.5,4.8-L*1.2),Math.max(1,2.8-L*.6),ARROZ);}[[8,7],[10,7],[14,7],[12,6]].forEach(q=>{if(Math.abs(q[0]-12)<7.4-L*.62)b.px(q[0],q[1]+(L>3?1:0),hs(q[0],q[1])%2?"#FFF4B0":"#B87A10");});}
    else if(v==="vacio"){b.ell(12,7.4,7.4,2.6,["#1E1E28","#2A2A36"]);b.px(8,7,"#FFF4B0");b.px(16,8,"#B87A10");}
    else if(v==="m1"){b.ell(12,7.4,7.4,2.6,["#1E1E28","#2A2A36"]);b.ell(12,8,4,1.4,["#C88A10","#F2C028"]);b.px(11,8,"#FFF4B0");}
    else if(v==="m2"){b.ell(12,7.2,7.4,2.6,["#1E1E28","#2A2A36"]);b.ell(12,7.8,6,2,["#C88A10","#F2C028","#FFE060"]);b.px(10,7,"#FFF4B0");b.px(14,8,"#B87A10");}
    else if(v==="m3"){b.ell(12,6.8,7.4,2.6,["#C88A10","#F2C028","#FFE060"]);[[8,6],[10,7],[14,6],[16,7],[12,6]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    else{b.ell(12,6.8,7.4,2.6,["#C88A10","#F2C028","#FFE060"]);b.ell(12,5,4.8,2.8,ARROZ);[[8,6],[10,7],[14,6],[16,7],[17,6],[9,5],[14,4]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    if(v==="lleno"){b.cap(16,6,20,1,.8,["#B07A3C","#D09A54"]);}
    const c=b.outline().done();c.pico=[2,7];return c;},
  // the platter for the second helpings, 28 x 17 (about as wide as abuela): a blue plate with a rim; the mounds lie on it (drawn by the scene), and papá's fork
  // v "c": lying on the stove, seen from the front, flat
  fuente(v){if(v==="c"){const b=new Buf(28,9);b.ell(14,5,13,3.4,["#2A5C9C","#4A86C8","#8CB8E8"]);b.ell(14,4.5,11,2,["#6AA0DC","#A8CCF0"]);return b.outline().done();}
    const b=new Buf(28,17);b.ell(14,9,13,6.6,["#2A5C9C","#4A86C8","#8CB8E8"]);b.ell(14,8.4,11,5,["#6AA0DC","#A8CCF0"]);b.rect(8,14,12,1,"#2E6CD0");return b.outline().done();},
  sillaBebe(v){return mkSillaBebe(v);},
  taburete(){return mkTaburete();},
  bebe(){return KIT.mkBebe("idle",0);},
  // the baby of the high chair, out of it, in somebody's hands: 16 x 20, the same head, shirt and bib
  bebeH(){const b=new Buf(16,20);b.ell(8,14.6,7.4,5.2,["#B87A10","#E0A020","#F8C838"]);b.ell(8,15.2,4.4,3.6,["#E8F0FA","#FFFFFF"]);b.rect(4,12,8,1,"#8CB8E8");b.ell(8,6.8,6.4,6.2,RP.skin.slice(2));b.px(6,6,"#20140A");b.px(10,6,"#20140A");b.px(6,5,"#FFFFFF");b.px(10,5,"#FFFFFF");b.px(4,9,"#E08A70");b.px(12,9,"#E08A70");b.rect(7,10,3,1,"#7A2A1A");b.px(6,9,"#7A2A1A");b.px(10,9,"#7A2A1A");[[8,0],[9,1],[7,1],[8,1]].forEach(q=>b.px(q[0],q[1],KIT.PELO.castano[2]));return b.outline().done();},
  // a thought: a mound with a heart; his own round belly with a hand on it beside his clean plate (full, content)
  montoncor(){const b=new Buf(20,19);b.ell(10,15.6,8.6,3,PLATO);b.ell(10,15,5.8,1.8,["#6AA0DC","#A8CCF0"]);b.ell(10,12.4,4,2.8,ARROZ);b.px(9,11,"#FFF4B0");const H=[".##.##.","#######","#######",".#####.","..###..","...#..."];H.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(7+i-3,0+j,j<2&&i<3?"#FF9A90":"#E8443C");});return b.outline().done();},
  barriga(){const b=new Buf(48,36),T=RP.tan;b.ell(7,32,6,2.4,PLATO);b.ell(7,31.6,4,1.4,["#A8CCF0"]);   // his clean plate
    b.ell(21,34,4.4,2,T);b.ell(37,34,4.4,2,T);   // his feet
    b.ell(29,22,15.4,11.6,[T[2]]);b.ell(29,22.4,13,9.4,["#EEDCB0","#FBF0D2"]);b.px(29,23,"#B89A6A");b.px(30,23,"#B89A6A");   // the big round belly, twice as wide as his head
    b.ell(29,8,7.6,4.8,T);[-5,5].forEach(dx=>{b.ell(29+dx,4.4,3,3,T);b.rect(29+dx-1.5,3.6,3,1,"#20140A");});b.rect(26,10,6,1,"#7A2A1A");b.px(25,9,"#7A2A1A");b.px(32,9,"#7A2A1A");   // eyes shut, a smile
    b.ell(19,20,3,2.4,[T[3]]);b.px(17,18,T[4]);b.px(19,17,T[4]);b.px(21,18,T[4]);b.ell(39,20,3,2.4,[T[3]]);b.px(37,18,T[4]);b.px(39,17,T[4]);b.px(41,18,T[4]);   // both hands on the belly
    return b.outline().done();},
  // cups seen a little from above, 17 x 17: a blue cup with a handle; v: what is in it (negro black coffee, marron dark brown, palido light tan, leche white milk, vacia empty: its dark inside)
  taza(v){return mkTaza(v,0);},
  // a cup with a spoon standing in it (sugar was stirred in)
  tazacu(v){return mkTaza(v,1);},
  // the sugar bowl, 22 x 20: a deep green bowl, a white heap of sugar over its rim, one spoon standing in it (v "0": the frog has taken the spoon)
  azucarera(v){const b=new Buf(22,20),n=Math.max(0,Math.min(3,+(v==null?3:v)));
    b.ell(11,15,9.4,4,["#1E5A3A","#2E8A5A","#4CBC80"]);b.rect(2,11,18,5,"#2E8A5A");b.rect(2,11,3,5,"#4CBC80");b.rect(16,11,4,5,"#1E5A3A");b.ell(11,16,8.6,3,["#1E5A3A","#2E8A5A"]);
    b.ell(11,10.6,9.4,2.8,["#4CBC80","#8CE0A8"]);
    b.ell(11,8,7.8,4.6,["#C8BEA0","#E6DDC2","#F6F0DC"]);b.ell(11,5.8,4.8,3,["#E6DDC2","#F6F0DC"]);[[8,7],[12,6],[14,8],[10,9],[13,10],[9,5],[13,4]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#9A8A66":"#FFFBEA"));
    if(n>0){b.rect(15,0,1,9,"#8A8A9A");b.rect(16,0,1,9,"#C8C8D4");b.ell(15.8,1,1.8,1.4,["#C8C8D4","#F8F8FF"]);}
    return b.outline().done();},
  // the big pot of coffee (enamel, blue, a spout and a handle), 18 x 21; pico: the lip
  cafetera(){const b=new Buf(18,21);b.rect(4,7,10,12,"#2A5C9C");b.rect(4,7,2,12,"#6AA0DC");b.rect(4,16,10,3,"#1A3C6C");b.ell(9,6.6,5.4,2,["#1A3C6C","#2A5C9C"]);b.rect(7,2,3,3,"#141418");b.rect(2,7,2,2,"#2A5C9C");b.rect(1,6,2,2,"#2A5C9C");b.rect(14,8,2,9,"#141418");b.rect(13,8,3,2,"#141418");b.rect(13,15,3,2,"#141418");b.px(7,11,"#FFFFFF");b.px(10,14,"#FFFFFF");const c=b.outline().done();c.pico=[1,7];return c;},
  // the greca: the little coffee pot, red, two chambers with a waist between them, a lid with a knob, a spout and a black handle, 14 x 16; pico: the spout
  jarrita(){const b=new Buf(14,16);b.rect(2,9,8,6,"#B0302A");b.rect(2,9,2,6,"#F08880");b.rect(2,13,8,2,"#7A1C1C");b.rect(3,7,6,3,"#8A2020");b.rect(3,7,1,3,"#C8403A");
    b.rect(2,2,8,6,"#B0302A");b.rect(2,2,2,6,"#F08880");b.rect(2,2,8,1,"#C8403A");b.rect(5,0,2,2,"#141418");b.rect(1,3,1,2,"#B0302A");
    b.rect(10,3,2,2,"#141418");b.rect(11,3,2,10,"#141418");b.rect(10,11,2,2,"#141418");b.px(5,12,"#FFFFFF");b.px(6,4,"#FFFFFF");const c=b.outline().done();c.pico=[1,3];return c;},
  // the milk pan: a saucepan, grey metal with a black handle and a pouring lip, v "1" with milk, "0" empty; 21 x 11; pico: the lip
  cazo(v){const b=new Buf(21,11);b.rect(2,4,11,6,"#8E92A6");b.rect(2,4,2,6,"#C8CCDA");b.rect(2,8,11,2,"#5A5E70");b.ell(7.5,4,6,2.2,["#6A6E80","#B8BCCC","#E8EAF2"]);b.ell(7.5,4,4.8,1.5,v==="0"?["#2A2A36","#4A4A58"]:["#E4DCC8","#F6F1E4","#FFFFFF"]);
    b.rect(13,4,6,2,"#141418");b.rect(17,3,2,4,"#141418");b.px(1,3,"#B8BCCC");b.px(0,3,"#B8BCCC");const c=b.outline().done();c.pico=[0,3];return c;},
  // the dog's bowl: with milk in it, or empty
  tazon(v){const b=new Buf(22,10);b.ell(11,6,10,3.6,["#2A5C9C","#4A86C8","#8CB8E8"]);b.ell(11,4.8,7.8,2.4,["#1E3A68","#2A5C9C"]);if(v==="1")b.ell(11,4.8,7.8,2.4,["#E4DCC8","#F6F1E4","#FFFFFF"]);else if(v==="2")b.ell(11,5.2,4.6,1.4,["#E4DCC8","#F6F1E4","#FFFFFF"]);return b.outline().done();},
  // a baking tray with n rolls on it, for abuela to carry: a metal tray with a rim all round and a handle at each end, 26 x 21 (about as wide as abuela): two rolls across and two rows, each roll apart from the next with its own dark edge, so that all four are counted at a glance
  bandeja(n){const b=new Buf(26,21);n=n==null?4:+n;b.rect(2,5,22,14,"#6A6E80");b.rect(3,6,20,12,"#E0D2A8");b.rect(3,6,20,1,"#B8A878");b.rect(2,4,22,2,"#D8DCEA");b.rect(0,10,3,4,"#4A4E60");b.rect(23,10,3,4,"#4A4E60");
    [[8,12],[18,12],[8,18],[18,18]].slice(0,n).forEach(p=>rollitos(b,p[0],p[1]));
    b.rect(2,18,22,2,"#6A6E80");b.rect(2,18,22,1,"#E8ECF8");b.rect(2,19,22,1,"#4A4E60");return b.outline().done();},
  pano(){const b=new Buf(12,10);b.rect(1,1,10,8,"#F8F8FF");b.rect(1,4,10,1,"#E0403A");b.rect(1,7,10,1,"#E0403A");return b.outline().done();},
  charco(){const b=new Buf(19,8);b.ell(8,4,5.4,1.8,["#6A3214"]);b.ell(12,3,3,1.4,["#6A3214"]);return b.outline().done();},
  // pictures of the pairs: a drumstick, a slice of cake, a bowl of rice for the dog, a jug, a glass
  muslo(v){const b=new Buf(24,14);b.ell(8,7,7.8,5.6,["#8A4A14","#C87A28","#E8A848"]);b.px(5,4,"#F8D890");b.px(6,3,"#F8D890");b.px(7,3,"#F8D890");b.rect(14,6,6,2,"#F2EAD8");b.ell(20,5.6,2.4,2.4,["#F2EAD8"]);b.ell(20,9.4,2.4,2.4,["#F2EAD8"]);
    if(v==="b"){borra(b,1,5,3.6);b.ell(4.6,6,1.6,2.6,["#F8E4B0"]);borra(b,1.6,5.2,2.8);}   // a bite out of it
    return b.outline().done();},
  manzana(){const b=new Buf(11,11);b.ell(3.6,6.4,3,4,["#A01818","#D02828","#F05848"]);b.ell(7.4,6.4,3,4,["#A01818","#D02828","#F05848"]);b.rect(5,1,1,3,"#5A3A1A");b.px(6,1,"#48A848");b.px(2,4,"#FFB0A0");return b.outline().done();},
  // a teaspoon lying on the table, 12 x 4: a handle and a small bowl
  cucharilla(){const b=new Buf(12,4);b.rect(1,1,7,1,"#C8C8D4");b.rect(1,2,6,1,"#8A8A9A");b.ell(9,1.8,1.9,1.2,["#8A8A9A","#F8F8FF"]);return b.outline().done();},
  // a slice of cake: a wedge with frosting on top and a layer of jam in its side. On a small plate (22 x 16); a bite of it on a fork (14 x 14); a whole slice on a fork (22 x 16)
  bizcocho(){const b=new Buf(22,16);b.ell(11,12.6,10.4,3.2,PLATO);b.ell(11,12,7.4,2,["#6AA0DC","#A8CCF0"]);tajada(b,3,1);return b.outline().done();},
  bizcochoT(){const b=new Buf(16,15);tajada(b,0,2,.55);b.rect(8,9,7,1,"#C8C8D4");b.rect(10,10,1,5,"#C8C8D4");b.rect(11,10,1,5,"#8A8A9A");b.rect(3,8,1,3,"#C8C8D4");b.rect(6,8,1,3,"#C8C8D4");return b.outline().done();},
  bizcochoL(){const b=new Buf(24,18);tajada(b,0,0,1);b.rect(15,12,8,1,"#C8C8D4");b.rect(17,13,1,5,"#C8C8D4");b.rect(18,13,1,5,"#8A8A9A");b.rect(4,11,1,4,"#C8C8D4");b.rect(8,11,1,4,"#C8C8D4");b.rect(12,11,1,4,"#C8C8D4");return b.outline().done();},
  entero(){const b=new Buf(26,16);b.ell(13,10,11.6,4.6,["#C88A30","#E8B050","#F8DC90"]);b.ell(13,6.8,11.6,4.2,["#F2E4D0","#FFF4E0","#FFFFFF"]);[7,13,19].forEach(x=>b.px(x,5,"#D0302A"));return b.outline().done();},
  hueso(){const b=new Buf(15,8);b.rect(4,3,7,2,"#F8F4E8");[[3,2],[3,5],[11,2],[11,5]].forEach(p=>b.ell(p[0],p[1],1.7,1.7,["#F8F4E8"]));return b.outline().done();},
  // the dog's bowl for the pair: the same bowl in both pictures. "limpio": clean inside, light and a shine; "lleno": heaped with white rice
  cuenco(v){const b=new Buf(30,18);b.ell(15,11,14,5.6,["#2A5C9C","#4A86C8","#8CB8E8"]);b.rect(2,11,26,1,"#1E3A68");
    if(v==="lleno"){b.ell(15,9.4,11.4,3.8,["#E4E4EC","#FFFFFF"]);b.ell(15,6.6,8.6,4.8,["#E4E4EC","#F8F8FC","#FFFFFF"]);b.ell(15,3.6,5,3,["#E4E4EC","#F8F8FC","#FFFFFF"]);[[9,8],[13,5],[18,6],[21,9],[12,10],[16,3],[19,10]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#B8B8CC":"#FFFFFF"));}
    else{b.ell(15,9.4,11.4,3.8,["#4A7EC0","#8CB4E4"]);b.ell(15,10.2,8.4,2,["#6A98D4","#A8C8EE"]);b.rect(7,7,7,1,"#FFFFFF");b.rect(8,8,3,1,"#FFFFFF");b.px(21,10,"#FFFFFF");}
    return b.outline().done();},
  sombra(){const b=new Buf(22,6);b.ell(11,3,10,2.4,["#E69C94"]);return b.done();},   // the shadow of a cup or a plate on the cloth, so that it sits and does not float
  granos(){const b=new Buf(8,5);[[1,1],[3,3],[5,0],[6,3]].forEach(q=>b.px(q[0],q[1],"#F6F0DC"));return b.outline().done();},
  grano(){const b=new Buf(2,2);b.rect(0,0,2,2,"#FFFFFF");return b.outline().done();},   // a grain falling from the spoon: two white pixels square
  jarra(v){const b=new Buf(23,29),n=v==null?4:+v;b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");if(n>0)b.rect(4,27-n*5,11,n*5,"#F08818");for(let i=1;i<=4;i++)b.rect(11,27-i*5,5,1,"#4A5A6A");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
  jugo(){const b=new Buf(23,29);b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");b.rect(4,27-20,11,20,"#F08818");b.rect(4,7,11,2,"#FFB040");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
  jugopoco(){const b=new Buf(23,29);b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");b.rect(4,25,11,2,"#F08818");b.rect(4,24,11,1,"#FFB040");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
  // the milk jug for the pair: a plain white pitcher with a pouring lip on the left and a ring handle on the right, 24 x 26; pico: the lip
  jarraleche(){const b=new Buf(24,26);b.rect(5,8,13,16,"#F8FAFE");b.rect(4,13,15,11,"#F8FAFE");b.rect(5,8,3,16,"#FFFFFF");b.rect(15,10,3,14,"#D4DCEC");b.rect(4,20,15,4,"#D4DCEC");
    b.rect(6,5,11,4,"#F8FAFE");b.rect(1,4,6,3,"#F8FAFE");b.rect(6,5,11,1,"#FFFFFF");   // the rim and the lip
    b.rect(19,9,4,2,"#D4DCEC");b.rect(21,10,2,10,"#D4DCEC");b.rect(19,19,4,2,"#D4DCEC");   // the handle: a ring (its hole stays open)
    const c=b.outline().done();c.pico=[0,5];return c;},
  // a glass of orange juice, 9 x 13
  vasojugo(){const b=new Buf(9,13);b.rect(1,1,7,11,"#DCF2FA");b.rect(1,1,2,11,"#F2FBFF");b.rect(2,4,5,8,"#F08818");b.rect(2,3,5,1,"#FFB040");return b.outline().done();},
  // a big hand, laid flat on the belly (v: the colour of the skin)
  manoG(v){const b=new Buf(10,8),c=v||"#D09460";b.ell(5,4.4,4.4,3.2,[c]);b.px(2,1,c);b.px(4,0,c);b.px(6,0,c);b.px(8,1,c);b.px(3,6,"#7A4A2A");b.px(5,6,"#7A4A2A");b.px(7,6,"#7A4A2A");return b.outline().done();},
  // a thing for a thought: a question mark; a heart
  interroga(){const b=new Buf(9,13);const Q=["..###..",".##.##.",".##.##.","....##.","...##..","..##...","..##...",".......","..##..."];Q.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(1+i,1+j,"#3A3A46");});return b.outline("#FFFFFF").done();},
  corazon(){const b=new Buf(9,8);const H=[".##.##.","#######","#######",".#####.","..###..","...#..."];H.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(1+i,1+j,j<2&&i<3?"#FF9A90":"#E8443C");});return b.outline().done();}};
// the pots that pour are made twice: standing, and tipped (at 50 degrees) to pour to the left; to the right they are turned over
// the platter with its mounds and the fork on it, in one picture (so that it can be tipped as a whole)
function fuenteComp(it){const cv=document.createElement("canvas");cv.width=52;cv.height=26;const g=cv.getContext("2d");g.imageSmoothingEnabled=false;g.drawImage(cosa("fuente",it.v),0,0);
  (it.montones||[]).slice().sort((m,n)=>(m.dy||0)-(n.dy||0)).forEach(m=>{const im=cosa("monton");g.drawImage(im,R(26+m.dx-im.width/2),R(13+8.5+(m.dy==null?-4:m.dy)-im.height/2));});
  if(it.tenedor){const im=cosa("tenedorH");g.drawImage(im,R(26+it.tenedor.dx-im.width/2),R(13+9-it.tenedor.dy-im.height/2));}return cv;}
function cosaIm(k,c){
  if(/^tilt/.test(k)){const base=k.slice(4),b=COSA[base](c==="suave"?undefined:c),g=giro(b,c==="suave"?-0.55:-0.9,b.pico);return g;}
  return (COSA[k]||COSA.plato)(c);}
const cosa=(k,c)=>spr("cm"+k+(c==null?"":c),()=>cosaIm(k,c));
// a thing drawn by its middle (x,y), at esc times its size; flip turns it over (to the right). Smoothing is off: it never blurs
function tenidaC(c,k,x,y,esc,v,flip){const im=cosa(k,v),e=esc||1,w=im.width*e,h=im.height*e;c.save();c.imageSmoothingEnabled=false;if(flip){c.translate(R(x),R(y));c.scale(-1,1);c.drawImage(im,R(-w/2),R(-h/2),w,h);}else c.drawImage(im,R(x-w/2),R(y-h/2),w,h);c.restore();}
// a thing drawn by its foot (the middle of its bottom edge)
function tenida(c,k,x,y,ang,esc,v){const im=cosa(k,v),e=esc||1;c.save();c.imageSmoothingEnabled=false;c.drawImage(im,R(x-im.width*e/2),R(y-im.height*e),im.width*e,im.height*e);c.restore();}

/* ---------- what is drawn by hand: steam, a stream, a long spoon, an arm ---------- */
const hex=(r,g,b)=>"#"+[r,g,b].map(v=>v.toString(16).padStart(2,"0")).join("").toUpperCase();
function recolor(cv,map){const c2=cv.getContext("2d"),d=c2.getImageData(0,0,cv.width,cv.height),p=d.data;for(let i=0;i<p.length;i+=4){if(!p[i+3])continue;const m=map[hex(p[i],p[i+1],p[i+2])];if(m){const v=rgb(m);p[i]=v[0];p[i+1]=v[1];p[i+2]=v[2];}}c2.putImageData(d,0,0);return cv;}
const APRON={"#B89A6A":"#2A8A8E","#D8BC8A":"#3AAAAA","#EEDCB0":"#5CCCC8","#FBF0D2":"#8CE0DA","#FFFBEA":"#B8F0EA"};   // abuela's apron is teal here, so that it is not the white of the rice and the sugar
const mkAbuelaC=(ps,hb)=>recolor(mkAbuela(ps,hb),APRON),mkAbuelaSC=(ps,hb)=>recolor(KIT.mkAbuelaS(ps,hb,0),APRON);
function ovalo(c,cx,cy,rx,ry,col){for(let j=-ry;j<=ry;j++){const hw=Math.round(rx*Math.sqrt(Math.max(0,1-(j*j)/((ry+.5)*(ry+.5)))));fr(c,cx-hw,cy+j,2*hw+1,1,col);}}
// steam: two soft wisps that rise, sway and fade
function vapor(c,x,y,n,h){const t=(F>>2)%12,H=Math.min(h||9,9);c.save();for(let i=0;i<(n||2);i++){const dx=i*7-3;for(let k=0;k<H;k++){const sw=Math.round(Math.sin((k+t*1.2+i*4)/2.4)*2.4);c.globalAlpha=Math.max(.12,.85-k*14/H*.065);fr(c,x+dx+sw-1,y-k,3,1,"#B8C4D4");fr(c,x+dx+sw,y-k,2,1,"#FFFFFF");}}c.restore();}
// a stream falling from y0 to y1: 4 pixels wide, solid, it leaves the lip sideways (dir: -1 to the left, 1 to the right) and bends down, and splashes
function chorro(c,x,y0,y1,col,dir){if(y1<=y0)return;const dd=dir||-1,n=y1-y0,wd=/^#F[BF]F[BF]F[4F]$/i.test(col)?6:4,h2=wd>>1;   // milk is a thick white stream (6 px), coffee a thinner one
  for(let j=0;j<n;j++){const t=j/Math.max(1,n),off=dd*Math.round(3*(1-Math.pow(1-t,2))*Math.min(1,n/6)),xx=x+off;fr(c,xx-h2-1,y0+j,1,1,OUT);fr(c,xx+h2,y0+j,1,1,OUT);fr(c,xx-h2,y0+j,wd,1,col);}
  const t=F%4,xb=x+dd*3;fr(c,xb-4,y1-1,9,2,OUT);fr(c,xb-3,y1-1,7,1,col);if(t<2){fr(c,xb-5,y1-3,2,2,col);fr(c,xb+4,y1-4,1,2,col);}else{fr(c,xb+4,y1-3,2,2,col);fr(c,xb-5,y1-4,1,2,col);}}
// a thick line (an arm, a handle) with a dark edge
function trazo(c,x0,y0,x1,y1,col,ancho){const n=Math.max(1,Math.ceil(Math.max(Math.abs(x1-x0),Math.abs(y1-y0)))),a=ancho||2;
  for(let i=0;i<=n;i++){const x=R(x0+(x1-x0)*i/n),y=R(y0+(y1-y0)*i/n);fr(c,x-1,y-1,a+2,a+2,OUT);}
  for(let i=0;i<=n;i++){const x=R(x0+(x1-x0)*i/n),y=R(y0+(y1-y0)*i/n);fr(c,x,y,a,a,col);}}
const mano=(c,x,y,pi)=>{const k=pi||RP.skin[2];fr(c,R(x)-3,R(y)-3,6,6,OUT);fr(c,R(x)-2,R(y)-2,4,4,k);fr(c,R(x)-2,R(y)-2,2,1,"#F4D8B8");};   // a hand: a skin block with a dark edge, a little lighter on its upper side
// a long spoon: its handle from the hand (x0,y0) to its bowl (x1,y1); the bowl faces us. load: what is in it ("monton" rice, "azu" sugar, "c"/"m" chocolate / butter, "" nothing)
function cucharon(c,x0,y0,x1,y1,load,o){o=o||{};const mad=o.plata?["#C8C8D4","#8A8A9A","#F8F8FF"]:["#B07A3C","#8A5A2A","#D09A54"];
  trazo(c,x0,y0,x1,y1,mad[0],2);const rx=o.rx||2,ry=o.ry||1,cx=R(x1),cy=R(y1);   // the handle: 2 px, a hand long; the bowl: a small oval, smaller than a fist
  ovalo(c,cx,cy,rx+1,ry+1,OUT);ovalo(c,cx,cy,rx,ry,mad[1]);ovalo(c,cx,cy,Math.max(1,rx-1),Math.max(0,ry-1),mad[2]);
  const heap=(w,h,col,hi)=>{ovalo(c,cx,cy-1,w+1,h+1,OUT);ovalo(c,cx,cy-1,w,h,col);if(hi)fr(c,cx-Math.max(0,w-2),cy-1-h+1,1,1,hi);};
  if(load==="monton")heap(2,1,"#F2C028","#FFF4B0");
  else if(load==="monton1"){heap(1,1,"#F2C028","#FFF4B0");}
  else if(load==="azu"){heap(rx,1,"#FFFFFF","#B4BEE0");fr(c,cx+1,cy-1,1,1,"#C8D0E8");}   // sugar: off-white grains in a small heap
  else if(load==="arr"){ovalo(c,cx,cy-2,4,3,OUT);ovalo(c,cx,cy-2,3,2,"#DCDCE8");ovalo(c,cx,cy-3,2,1,"#F0F0F6");fr(c,cx-1,cy-3,1,1,"#FFFFFF");ovalo(c,cx,cy+1,rx,ry,mad[1]);}   // one small scoop of white rice: a plain white mound in the bowl, about a third of the big one
  else if(load==="ARR"){ovalo(c,cx,cy-4,6,5,OUT);ovalo(c,cx,cy-4,5,4,"#DCDCE8");ovalo(c,cx,cy-5,4,3,"#F0F0F6");ovalo(c,cx,cy-6,2,2,"#FFFFFF");[[-3,-4],[2,-5],[3,-2],[0,-7]].forEach(g=>fr(c,cx+g[0],cy+g[1],1,1,"#B8B8CC"));ovalo(c,cx,cy,rx,ry,mad[1]);}   // one huge heaped scoop (the pair): a big heap over the small bowl
  else if(load==="c"){ovalo(c,cx,cy-1,rx,1,CHOC[1]);fr(c,cx-1,cy-2,1,1,"#C89A74");}
  else if(load==="m"){ovalo(c,cx,cy-1,rx,1,MANT);fr(c,cx-1,cy-2,1,1,"#FFFBE0");}}

/* ---------- what can be touched ---------- */
const alto=id=>{const w=QUIEN[id]||{},p=W.gente[id];return id==="abuela"?(p&&p.sent?48:51):w.nino?(p&&p.sent?37:44):(p&&p.sent?49:56);};
// somebody who sits behind the table is touched from his head down over the edge of the table: the middle of his box is his chest, so the stars of the signal fall beside and above his head, never on his face
const caja=id=>{const p=W.gente[id];if(!p||p.vis===0)return null;const h=alto(id);return p.sent?[R(p.x)-11,R(p.y)-h,22,Math.max(40,MESA[1]+26-(R(p.y)-h))]:[R(p.x)-11,R(p.y)-h,22,h];};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const ob=id=>(W.cosas||[]).find(o=>o.id===id);
const porId=(id,w,h,z)=>({id,si:w2=>!!(w2.cosas||[]).find(o=>o.id===id&&o.vis!==0),box:w2=>{const o=w2.cosas.find(o=>o.id===id);return [R(o.x)-(w>>1),R(o.y)-h,w,h];},m:1,z:z==null?1:z});
const COSAS=Object.keys(QUIEN).map(persona).concat(["di_buen","di_tambien","di_lleno","di_poco","di_mucho"].map(id=>({id,si:w=>true,box:w=>{const b=frogBox(w.cq);return [b.x+(b.w>>1)-8,b.y-27,16,10];},m:0}))).concat([porId("mant",26,18),porId("choc",26,18),porId("cesta",48,24,0),porId("cafetera",24,28,0),porId("azucarera",24,18,0),porId("olla",30,26,0),porId("fuente",56,22,0),porId("pl_papa",24,10,0),porId("pl_rana",18,9,0),
  {id:"silla_papa",si:w=>true,box:w=>[SILLA[(w.sitio&&w.sitio.papa!=null)?w.sitio.papa:3]-10,MESA[1]-26,20,36],m:0},{id:"mesa",box:[MESA[0]-6,MESA[1],MESA[2]+12,MESA[3]+6],m:0},{id:"cocina",box:[32,24,196,190],m:0}]);

/* ---------- drawing ---------- */
// where things are held: the shoulder and the mouth of each, from his feet (up)
const hombroY=(id,p)=>{const w=QUIEN[id]||{};return id==="abuela"?(p.sent?25:27):w.nino?(p.sent?19:22):(p.sent?27:34);};
const bocaY=(id,p)=>{const w=QUIEN[id]||{};return id==="abuela"?(p.sent?33:35):w.nino?(p.sent?25:28):(p.sent?33:40);};
const sleeve=id=>id==="abuela"?RP.purp[1]:((QUIEN[id]||{}).ropa||RP.cream)[1];
const piel=id=>id==="abuela"?RP.skin[2]:((QUIEN[id]||{}).piel||RP.skin)[2];
/* ---------- bodies without arms, arms that bend, legs that step ----------
   Every person is drawn here without arms; his arms are drawn over him (cuerpo: the arms at rest; objetos: the arms that hold, point or wave), each with an elbow, a sleeve and a hand.
   Whatever he holds is in a hand: nothing floats beside a person. */
function mkPersonaN(w,open,sent,pie){const t=w.nino?7:11,l=sent?4:(w.nino?7:11),rx=w.nino?6.5:8,H=18+2*t+l+4,b=new Buf(48,H+1),X=KIT.PX,S=w.piel,Rr=w.ropa,A=w.abajo||w.ropa,P=w.pelo,
    tc=18+t,hc=18+2*t-2,lt=hc+2,lb=lt+l,dark="#2A1810",lf=sent?0:2,L1=pie===1?lf:0,L2=pie===2?lf:0;
  if(w.falda){b.rect(X-4,lt,3,l-L1,S[2]);b.rect(X+1,lt,3,l-L2,S[1]);}else{b.rect(X-5,lt-2,4,l+2-L1,A[1]);b.rect(X+1,lt-2,4,l+2-L2,A[0]);b.rect(X-5,lt-2,1,l+2-L1,A[2]);}   // one foot is lifted when he steps
  b.ell(X-3.5,lb+1.5-L1,3.3,1.8,[w.zapato||"#3A2414"]);b.ell(X+3.5,lb+1.5-L2,3.3,1.8,[w.zapato||"#3A2414"]);
  const A2=[A[0],A[1],A[1]];
  if(w.falda){b.ell(X,tc,rx,t+1,Rr);b.ell(X,hc+1,rx+2.4,sent?4:5.5,Rr);}else{b.ell(X,hc,rx-.8,3.4,A2);b.ell(X,tc-1,rx,t,Rr);}
  if(sent&&!w.falda){b.ell(X-4,hc+2,4.2,3.2,A2);b.ell(X+4,hc+2,4.2,3.2,A2);}
  if(w.detalle)w.detalle(b,X,tc,rx,t);
  b.rect(X-2,16,4,4,S[1]);
  if(w.peinado==="largo"){b.ell(X,11,8,8.8,P);b.rect(X-8,11,3,t+2,P[1]);b.rect(X+5,11,3,t+2,P[0]);}
  b.ell(X,11.4,5.8,6.4,S);
  if(w.peinado==="calvo"){b.ell(X-6,9.5,2,3.4,P);b.ell(X+6,9.5,2,3.4,P);}
  else if(w.peinado==="trenzas"){b.ell(X,5.6,6.4,3,P);b.cap(X-7,9,X-8,19,1.6,P);b.cap(X+7,9,X+8,19,1.6,P);b.rect(X-10,19,4,3,w.lazo||"#FFE070");b.rect(X+6,19,4,3,w.lazo||"#FFE070");b.px(X,3,P[2]);}
  else{b.ell(X,5.4,6.4,w.peinado==="largo"?3.2:2.8,P);if(w.peinado==="corto"){b.rect(X-6,6,1,4,P[1]);b.rect(X+5,6,1,4,P[0]);}}
  if(w.dormido){b.rect(X-4,11,3,1,"#20140A");b.rect(X+1,11,3,1,"#20140A");}else{b.px(X-3,11,"#20140A");b.px(X+2,11,"#20140A");}b.px(X-4,13,"#E08A70");b.px(X+3,13,"#E08A70");
  if(w.gafas===1){b.frame(X-5,9,4,4,dark);b.frame(X,9,4,4,dark);b.px(X-1,10,dark);if(!w.dormido){b.px(X-3,11,"#20140A");b.px(X+2,11,"#20140A");}}
  else if(w.gafas==="arriba"){b.frame(X-5,3,4,3,dark);b.frame(X,3,4,3,dark);b.px(X-1,4,dark);b.rect(X-4,11,3,1,"#20140A");b.rect(X+1,11,3,1,"#20140A");}
  if(w.bigote){b.rect(X-4,14,8,2,P[2]);b.rect(X-4,15,2,1,P[1]);b.rect(X+2,15,2,1,P[1]);if(open)b.rect(X-1,16,3,1,"#7A1C1C");}
  else if(open)b.rect(X-1,15,3,2,"#7A1C1C");else{b.rect(X-2,15,4,1,"#7A2A1A");b.px(X-3,14,"#7A2A1A");b.px(X+2,14,"#7A2A1A");}
  return b.outline().done();}
// abuela standing, no arms (48 x 51, her middle at 24)
function mkAbuelaN(open,pie){const b=new Buf(48,51),X=24,S=RP.skin,P=RP.purp,lf=2,L1=pie===1?lf:0,L2=pie===2?lf:0;
  b.ell(X-4,47.5-L1,3.4,1.9,["#3A2414"]);b.ell(X+4,47.5-L2,3.4,1.9,["#3A2414"]);
  b.rect(X-5,41,3,6-L1,S[2]);b.rect(X+2,41,3,6-L2,S[1]);
  b.ell(X,31,9,12.5,P);b.ell(X,38,10.5,5,P);
  for(let i=0;i<9;i++)b.px(X-8+hs(i,3)%17,34+hs(i,5)%8,P[4]);
  b.ell(X,33,5.4,8.5,RP.cream);b.rect(X-5,24,10,1,RP.cream[1]);
  b.rect(X-2,17,4,4,S[1]);
  b.ell(X,10,8,8.6,RP.grey);b.ell(X,2.9,3.6,2.6,RP.grey);
  b.ell(X,12.4,5.8,6.4,S);b.ell(X,5.8,6.2,2.6,RP.grey);
  b.px(X-3,12,"#20140A");b.px(X+2,12,"#20140A");b.px(X-4,14,"#E08A70");b.px(X+3,14,"#E08A70");
  if(open)b.rect(X-1,15,3,2,"#7A1C1C");else{b.rect(X-2,15,4,1,"#7A2A1A");b.px(X-3,14,"#7A2A1A");b.px(X+2,14,"#7A2A1A");}
  b.px(X-6,14,"#F8C838");b.px(X+6,14,"#F8C838");
  return b.outline().done();}
// abuela sitting, no arms (52 x 50, her middle at 17, her knees to the right)
function mkAbuelaSN(open){const b=new Buf(52,50),X=17,S=RP.skin,P=RP.purp;
  b.ell(X+9,36.5,12,5.2,P);b.rect(X+15,40,3,6,S[2]);b.rect(X+19,40,3,6,S[1]);b.ell(X+17,47,3.2,1.7,["#3A2414"]);b.ell(X+22,47,3.2,1.7,["#3A2414"]);
  b.ell(X,28,8.6,9.6,P);for(let i=0;i<7;i++)b.px(X-7+hs(i,3)%15,29+hs(i,5)%8,P[4]);
  b.ell(X+1,30,5,6.6,RP.cream);b.rect(X-4,23,10,1,RP.cream[1]);
  b.rect(X-2,17,4,4,S[1]);
  b.ell(X,10,8,8.6,RP.grey);b.ell(X,2.9,3.6,2.6,RP.grey);
  b.ell(X,12.4,5.8,6.4,S);b.ell(X,5.8,6.2,2.6,RP.grey);
  b.px(X-3,12,"#20140A");b.px(X+2,12,"#20140A");b.px(X-4,14,"#E08A70");b.px(X+3,14,"#E08A70");
  if(open)b.rect(X-1,15,3,2,"#7A1C1C");else{b.rect(X-2,15,4,1,"#7A2A1A");b.px(X-3,14,"#7A2A1A");b.px(X+2,14,"#7A2A1A");}
  b.px(X-6,14,"#F8C838");b.px(X+6,14,"#F8C838");
  return b.outline().done();}
// a stool: a round wooden seat on three legs, 22 x 16
function mkTaburete(){const b=new Buf(22,16),W=RP.wood;b.rect(3,5,2,10,W[0]);b.rect(17,5,2,10,W[0]);b.rect(10,6,2,9,W[1]);b.rect(4,11,14,1,W[1]);b.ell(11,4.4,10,3.4,[W[1],W[2],W[3],W[4]]);return b.outline().done();}

// an arm of two bones (L each): shoulder (sx,sy) to hand (hx,hy), with an elbow, a sleeve and a hand. lado: -1 the arm on the left of the picture, 1 on the right (the elbow goes out and down)
const ALCANCE=[];window.__ALC=ALCANCE;   // a hand that is farther than his arm can reach (checked by machine: window.__ALC must stay empty)
function brazoJ(c,sx,sy,hx,hy,L,sl,pi,lado,quien){
  const d=Math.hypot(hx-sx,hy-sy)||.01,dd=Math.min(d,2*L-.4),ux=(hx-sx)/d,uy=(hy-sy)/d,a=dd/2,h=Math.sqrt(Math.max(0,L*L-a*a)),nx=-uy,ny=ux;
  if(d>2*L+1.5&&quien){const kk=quien+" "+Math.round(d)+">"+2*L+" at "+Math.round(hx)+","+Math.round(hy)+" from "+Math.round(sx)+","+Math.round(sy);if(ALCANCE.length<80&&!ALCANCE.includes(kk))ALCANCE.push(kk);}
  const e1=[sx+ux*a+nx*h,sy+uy*a+ny*h],e2=[sx+ux*a-nx*h,sy+uy*a-ny*h];
  const e=Math.abs(uy)>Math.abs(ux)*1.3?((e1[0]-sx)*lado>(e2[0]-sx)*lado?e1:e2):(e1[1]>e2[1]?e1:e2);
  const seg=(x0,y0,x1,y1,f)=>{const n=Math.max(1,Math.ceil(Math.max(Math.abs(x1-x0),Math.abs(y1-y0))));for(let i=0;i<=n;i++){const x=R(x0+(x1-x0)*i/n),y=R(y0+(y1-y0)*i/n);f(x,y,i/n);}};
  const th=L>=8?4:3;   // the upper arm is as thick as 4 (3 for a child) pixels, in his sleeve; the forearm is bare skin, 3
  seg(sx,sy,e[0],e[1],(x,y)=>fr(c,x-2,y-2,th+2,th+2,OUT));seg(e[0],e[1],hx,hy,(x,y)=>fr(c,x-2,y-2,5,5,OUT));
  seg(sx,sy,e[0],e[1],(x,y)=>fr(c,x-1,y-1,th,th,sl));seg(e[0],e[1],hx,hy,(x,y)=>fr(c,x-1,y-1,3,3,pi));
  return e;}
const GRIP={tazacu:[6,3],rollo:[-4,2],plato:[0,3],taza:[6,3],tenedor:[0,3],cuchara:[0,4],muslo:[8,0],vasojugo:[0,2],bizcochoT:[2,6],bizcochoL:[5,8],bebe:[0,8],bebeH:[0,8],pano:[0,0],cafetera:[7,6],jarrita:[5,2],cazo:[6,1],jarraleche:[8,3],bandeja:[10,3,1],olla:[10,1,1],fuente:[11,2,1],tenedorH:[0,0],monton:[0,2],platoma:[0,6],platoH:[0,6],bizcocho:[0,4],jarra:[0,2],jugo:[0,2]};
function agarres(it,ix,iy,fl){const base=String(it.k).replace(/^tilt/,""),e=it.e||1,g=GRIP[base]||[0,3];let gx=g[0]*e,gy=g[1]*e;if(/^tilt/.test(it.k)){const A=it.v==="suave"?-0.55:-0.9,cs=Math.cos(A),sn=Math.sin(A),nx=gx*cs-gy*sn,ny=gx*sn+gy*cs;gx=nx;gy=ny;}
  const sg=fl?-1:1;if(it.una)return [[ix,iy+gy]];if(it.dos){const h=typeof it.dos==="number"?it.dos:11;return [[ix-h,iy+gy],[ix+h,iy+gy]];}return g[2]?[[ix+sg*gx,iy+gy],[ix-sg*gx,iy+gy]]:[[ix+sg*gx,iy+gy]];}
const CONASA=new Set(["taza","cafetera","jarrita","cazo","jarraleche"]);   // what has its handle on the right of the drawing: it is turned so that the handle is on the side of his body
const comeFl=(co,d)=>CONASA.has(co.k)?d>0:(d<0&&co.k!=="tenedor");   // what is at the mouth: a cup has its handle on the side of the body
const CUE=id=>{const w=QUIEN[id]||{},p=(W&&W.gente&&W.gente[id])||{},c=id==="abuela"?{L:8,sx:7}:w.nino?{L:7,sx:5.5}:{L:9,sx:7};if(p.L)c.L=p.L;return c;};   // p.L: a longer arm for a moment (reaching over the table)
// the hands of somebody, absolute: [{x,y,s: side of the picture (-1 left, 1 right), it, k}] (those that hold, point, wave, or carry a thing to the mouth)
function manosDe(id,p,a){const x=R(p.x),y=R(p.y),d=p.dir<0?-1:1,hy=hombroY(id,p),cu=CUE(id),out=[];
  const side=(hx,pre)=>pre||(Math.abs(hx-x)<3?d:(hx>x?1:-1));
  const pon=(hx,hyy,it,pre,kind)=>out.push({x:hx,y:hyy,s:side(hx,pre),it,k:kind});
  for(const it of p.tiene||[]){if(it.vis===0)continue;
    if(it.k==="brazo"){pon(x+d*it.gx,y-it.gy,it,it.sh?it.sh*d:0,"brazo");continue;}
    if(it.k==="uten"){pon(x+d*it.ax,y-it.ay,it,it.side||(it.sh?it.sh*d:0),"uten");continue;}
    const ix=x+d*it.dx,iy=y-it.dy,fl=it.flip!=null?it.flip:(CONASA.has(String(it.k).replace(/^tilt/,""))?d>0:false);
    it._fl=fl;if(it.gx!=null){pon(x+d*it.gx,y-it.gy,it,0,"item");continue;}
    it._fl=fl;const H=agarres(it,ix,iy,fl);
    if(H.length>1){const L1=H[0][0]<H[1][0]?H[0]:H[1],R1=H[0][0]<H[1][0]?H[1]:H[0];pon(L1[0],L1[1],it,-1,"item");pon(R1[0],R1[1],it,1,"item");}
    else pon(H[0][0],H[0][1],it,it.sh?it.sh*d:0,"item");}
  if(p.come){const co=p.come,my=y-bocaY(id,p)+(a%2),cxx=x+d*(co.dx==null?13:co.dx),H=agarres(co,cxx,my+(co.dy||0),comeFl(co,d));pon(H[0][0],H[0][1],co,0,"come");}
  if(p.bebe2){const co={k:"taza"},H=agarres(co,x+d*14,y-bocaY(id,p)+3-(a%2),comeFl(co,d));pon(H[0][0],H[0][1],co,0,"come");}
  for(let i=1;i<out.length;i++){const m=out[i];if(out.slice(0,i).some(q=>q.s===m.s&&q.it!==m.it)&&!out.slice(0,i).some(q=>q.s===-m.s))m.s=-m.s;}   // two things never in the same hand: the second goes to the other arm
  // poses that need no thing: a hand out, up, on the chest
  const usado=s=>out.some(m=>m.s===s);
  const POSE=p.pose||"idle";
  if(POSE==="offer"||POSE==="tu"){if(!usado(d)&&!out.some(m=>m.k!=="come"&&m.it&&m.s===d))pon(x+d*(cu.sx+cu.L*2-3),y-hy+4,null,d,"pose");}
  else if(POSE==="wave0"||POSE==="wave1"){if(!usado(d))pon(x+d*(cu.sx+4+(POSE==="wave1"?2:0)),y-hy-cu.L-3,null,d,"pose");}
  else if(POSE==="yo"){if(p.sent){if(!usado(1))pon(x+4,y-hy+cu.L-2,null,1,"pose");}else{if(!usado(-1))pon(x-3,y-hy+cu.L-1,null,-1,"pose");if(!usado(1))pon(x+3,y-hy+cu.L-1,null,1,"pose");}}   // a hand on his belly: when he sits the belly is under the table, so one hand, at his chest, with its arm (not two blocks lying on the cloth)
  else if(POSE==="bless"){if(!usado(d))pon(x+d*3,y-hy+cu.L-1,null,d,"pose");}
  return out;}
// his arms at rest: the sides that are not busy, hanging; when he sits, resting on the lap
function brazosQuietos(c,id,p,a,vivos){const x=R(p.x),y=R(p.y),hy=hombroY(id,p),cu=CUE(id),sl=sleeve(id),pi=piel(id);
  [-1,1].forEach(s=>{if(vivos.some(m=>m.s===s))return;const sx=x+s*cu.sx,sy=y-hy,hx=x+s*(cu.sx+1.5),hyy=p.sent?sy+cu.L*1.25:sy+cu.L*1.7;brazoJ(c,sx,sy,hx,hyy,cu.L,sl,pi,s);mano(c,hx,hyy,pi);});}
function cuerpo(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1,pie=p.paso?(p.pie||0):0,bob=p.paso&&pie===0?-1:0;
  const vivos=manosDe(id,p,a);
  if(id==="abuela"){
    if(p.sent){const top=y-48,hb=(habla||p.abre||p.boca)?1:0;const im=spr("abSN"+hb,()=>recolor(mkAbuelaSN(hb),APRON));if(d<0){c.save();c.translate(x,top);c.scale(-1,1);c.drawImage(im,-17,0);c.restore();}else c.drawImage(im,x-17,top);brazosQuietos(c,id,p,a,vivos);return;}
    const top=y-50+bob,hb=(habla||p.abre||p.boca)?1:0;c.save();c.translate(x,top);if(d<0)c.scale(-1,1);c.drawImage(spr("abN"+hb+pie,()=>recolor(mkAbuelaN(hb,pie),APRON)),-24,0);c.restore();brazosQuietos(c,id,p,a,vivos);return;}
  const op=(habla||p.boca||p.sopla)?1:0,w2=p.cierra?Object.assign({},w,{dormido:1}):w,im=spr("pmN"+id+op+(p.sent?1:0)+pie+(p.cierra?"c":""),()=>mkPersonaN(w2,op,p.sent,pie)),top=y-im.height+1+bob+(p.dy||0);
  c.save();c.translate(x,top);if(d<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  brazosQuietos(c,id,p,a,vivos);
  const sk=(w.piel||RP.skin)[2];
  if(p.cara==="mal"){fr(c,x-6,top+11,13,9,sk);   // a big plain frown: eyes squeezed shut, thick brows sloping down to the nose, a wide mouth turned down, a red mark of being cross
    [[-6,8],[-5,8],[-4,9],[-3,9],[-2,10]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));[[6,8],[5,8],[4,9],[3,9],[2,10]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));
    [[-5,12],[-4,13],[-3,12],[-2,13]].forEach(q=>fr(c,x+q[0],top+q[1],1,1,"#20140A"));[[5,12],[4,13],[3,12],[2,13]].forEach(q=>fr(c,x+q[0],top+q[1],1,1,"#20140A"));
    fr(c,x-3,top+16,7,2,"#5A1A10");fr(c,x-5,top+17,2,2,"#5A1A10");fr(c,x+4,top+17,2,2,"#5A1A10");fr(c,x-6,top+19,2,1,"#5A1A10");fr(c,x+5,top+19,2,1,"#5A1A10");
    fr(c,x+7,top+1,1,4,"#D0302A");fr(c,x+6,top+2,3,1,"#D0302A");fr(c,x+8,top+3,1,1,"#D0302A");}
  if(p.cierra){if(w.gafas){fr(c,x-4,top+10,2,2,"#EEDCB0");fr(c,x+1,top+10,2,2,"#EEDCB0");fr(c,x-4,top+11,2,1,"#20140A");fr(c,x+1,top+11,2,1,"#20140A");}   // eyes shut inside his glasses: a short line in each lens
    else{[[-6,13],[-5,12],[-4,11],[-3,11],[-2,12],[-1,13]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));[[1,13],[2,12],[3,11],[4,11],[5,12],[6,13]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));
    fr(c,x-5,top+13,2,1,sk);fr(c,x+3,top+13,2,1,sk);}}
  if(p.cara==="ceno"){fr(c,x-5,top+13,11,5,sk);   // a plain frown, the eyes open: brows sloping down to the nose, a mouth turned down
    [[-6,8],[-5,8],[-4,9],[-3,9],[-2,10]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));[[6,8],[5,8],[4,9],[3,9],[2,10]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));
    fr(c,x-3,top+15,7,1,"#5A1A10");fr(c,x-4,top+16,2,1,"#5A1A10");fr(c,x+3,top+16,2,1,"#5A1A10");}
  if(p.cara==="calma"){fr(c,x-4,top+13,9,4,sk);fr(c,x-2,top+15,5,1,"#7A2A1A");}   // a calm face: a straight mouth
  if(p.sopla){   // cheeks puffed (round, each with its own dark edge, the moustache untouched), lips pursed (a small round mouth under the moustache), and three small breath dashes in a row from his lips to the steaming forkful he holds in front of him
    ovalo(c,x-5,top+16,3,2,OUT);ovalo(c,x-5,top+16,2,1,sk);ovalo(c,x+6,top+16,3,2,OUT);ovalo(c,x+6,top+16,2,1,sk);
    fr(c,x-1,top+16,3,2,OUT);fr(c,x,top+16,1,1,"#7A1C1C");
    [8,13,18].forEach(k=>{fr(c,x+d*k-2,top+16,5,3,OUT);fr(c,x+d*k-1,top+17,3,1,"#FFFFFF");});}}
// what he holds and eats, drawn after (over) his body; behind the table, after the table too. Each thing is in a hand at the end of an arm with an elbow
function objetos(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const x=R(p.x),y=R(p.y),d=p.dir<0?-1:1,hy=hombroY(id,p),pi=piel(id),sl=sleeve(id),cu=CUE(id),ms=manosDe(id,p,a);
  const brazo=m=>brazoJ(c,x+m.s*cu.sx,y-hy,m.x,m.y,cu.L,sl,pi,m.s,id+":"+(m.it?m.it.k:m.k));
  for(const m of ms)brazo(m);   // the arms first, the things over them, the hands last
  for(const it of p.tiene||[]){if(it.vis===0||it.k==="brazo")continue;const ix=x+d*it.dx,iy=y-it.dy,fl=it._fl!=null?it._fl:false;
    if(it.k==="uten"){cucharon(c,x+d*it.ax,y-it.ay,x+d*it.bx,y-it.by,it.load,it.o);continue;}
    const kk=it.k==="taza"&&it.sp?"tazacu":it.k;
    if(it.ang&&it.k==="fuente"){const g=giro(fuenteComp(it),it.ang);c.save();c.imageSmoothingEnabled=false;c.drawImage(g,R(ix-g.width/2),R(iy-g.height/2));c.restore();}
    else if(it.ang){const g=spr("cmg"+it.k+(it.v==null?"":it.v)+it.ang,()=>giro(cosa(it.k,it.v),it.ang));c.save();c.imageSmoothingEnabled=false;c.drawImage(g,R(ix-g.width/2),R(iy-g.height/2));c.restore();}else tenidaC(c,kk,ix,iy,it.e,it.v,fl);
    if(it.k==="plato")(it.rollos||[]).forEach(r=>rolloD(c,ix+(r.dx||0),iy+3,r,a));
    if(it.k==="fuente"&&!it.ang){(it.montones||[]).slice().sort((m,n)=>(m.dy||0)-(n.dy||0)).forEach(m=>tenidaC(c,"monton",ix+m.dx,iy+6+(m.dy==null?-4:m.dy)));if(it.tenedor)tenidaC(c,"tenedorH",ix+it.tenedor.dx,iy+4.5-it.tenedor.dy);}
    if(it.vapor)vapor(c,ix,iy-(it.e||1)*9-2,it.vn||1,it.vh);
    if(it.chorro){const im=cosa(it.k,it.v),e=it.e||1;if(im.pico){const px=ix+(im.pico[0]-im.width/2)*e*(fl?-1:1),py=iy+(im.pico[1]-im.height/2)*e+1;chorro(c,R(px),R(py),R(py)+it.chorro.h,it.chorro.col,fl?1:-1);}}}   // a stream from the lip of what he pours
  if(p.come){const co=p.come,my=y-bocaY(id,p)+(a%2),cxx=x+d*(co.dx==null?13:co.dx);tenidaC(c,co.k,cxx,my+(co.dy||0),co.e||1,co.v,comeFl(co,d));if(co.vapor)vapor(c,cxx,my-8,1);}
  if(p.bebe2)tenidaC(c,"taza",x+d*14,y-bocaY(id,p)+3-(a%2),1,p.bebe2,comeFl({k:"taza"},d));
  for(const m of ms)mano(c,m.x,m.y,pi);}
// the frog; his round belly (lleno) and his lying on his back (espalda) are drawn here
function mkRanaEsp(open){const b=new Buf(40,32),T=RP.tan;
  b.ell(7,15,4,6,T);b.ell(33,15,4,6,T);b.ell(9,28,5,3.4,T);b.ell(31,28,5,3.4,T);   // hands and feet in the air
  b.rect(4,6,3,6,T[2]);b.rect(33,6,3,6,T[2]);b.rect(6,24,3,5,T[2]);b.rect(31,24,3,5,T[2]);
  b.ell(20,19,14.4,11,T);b.ell(20,19.4,11.8,8.6,["#EEDCB0","#FBF0D2","#FFFBEA"]);b.px(20,20,"#B89A6A");b.px(21,20,"#B89A6A");   // the round belly, up
  b.ell(20,6,8,5,T);[-5,5].forEach(dx=>{b.ell(20+dx,3.4,3.4,3.4,["#FFFFFF"]);b.ell(20+dx+.6,2.8,1.6,1.8,["#20140A"]);});
  if(open)b.ell(20,9,2.8,1.8,["#7A1C1C"]);else b.line(17,9,23,9,OUT);
  return b.outline().done();}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui"||q.hace)&&a%2?1:0,dy=R(q.dy),cx=b.x+(b.w>>1),fy=b.y+b.h+dy;
  g.save();g.imageSmoothingEnabled=false;
  if(q.espalda){g.drawImage(spr("cqesp"+op,()=>mkRanaEsp(op)),cx-20,fy-31);g.restore();return;}
  if(q.caida){const ca=q.caida,gi=spr("cqcai"+ca,()=>giro(mkCoqui(1,0,0),ca*.75));g.drawImage(gi,cx-(gi.width>>1),b.y+dy+(b.h>>1)-(gi.height>>1));g.restore();return;}   // half way over
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;g.restore();
  if(q.lleno){const f=q.hinch==null?1:q.hinch/3;if(f>0){[[-7,0],[-9,1],[-10,2],[-10,3],[-9,4],[-7,5]].forEach(r=>{const x0=R(r[0]*f);fr(g,cx+x0-1,b.y+dy+12+r[1],-2*x0+2,1,"#FBF0D2");});fr(g,cx-R(10*f),b.y+dy+14,1,3,OUT);fr(g,cx+R(9*f),b.y+dy+14,1,3,OUT);fr(g,cx,b.y+dy+15,1,1,"#B89A6A");}}
  if(q.mal){const fx=cx,fy2=b.y+dy;   // a plain sour face, big: brows thick and sloping down to the nose, eyes squeezed, a wide mouth turned down
    [[-10,3],[-9,4],[-8,4],[-7,5],[-6,5],[-5,6]].forEach(r=>fr(g,fx+r[0],fy2+r[1]-1,1,3,OUT));[[10,3],[9,4],[8,4],[7,5],[6,5],[5,6]].forEach(r=>fr(g,fx+r[0]-1,fy2+r[1]-1,1,3,OUT));
    fr(g,fx-6,fy2+13,13,3,"#7A1C1C");fr(g,fx-8,fy2+15,3,3,"#7A1C1C");fr(g,fx+6,fy2+15,3,3,"#7A1C1C");fr(g,fx-7,fy2+12,2,1,OUT);fr(g,fx+6,fy2+12,2,1,OUT);}
  const sl=RP.tan[2],pi=RP.tan[3],its=(q.tiene||[]).filter(it=>it.vis!==0),hs_=[];
  its.forEach(it=>{const base=String(it.k).replace(/^tilt/,"");let H;
    if(it.k==="brazo")H=[[cx+it.gx,fy-it.gy]];else if(it.k==="uten")H=[[cx+it.ax,fy-it.ay]];else if(it.gx!=null)H=[[cx+it.gx,fy-it.gy]];else H=agarres(it,cx+it.dx,fy-it.dy,it.flip!=null?it.flip:(CONASA.has(base)&&it.dx>0));
    it._H=H;H.forEach(h=>{const s=h[0]>=cx?1:-1;brazoJ(g,cx+s*7,fy-12,h[0],h[1],7,sl,pi,s,"rana:"+it.k);});});
  its.forEach(it=>{if(it.k==="brazo")return;const ix=cx+it.dx,iy=fy-it.dy,base=String(it.k).replace(/^tilt/,""),fl=it.flip!=null?it.flip:(CONASA.has(base)&&it.dx>0);
    if(it.k==="uten")cucharon(g,cx+it.ax,fy-it.ay,cx+it.bx,fy-it.by,it.load,it.o);else tenidaC(g,it.k,ix,iy,it.e,it.v,fl);
    if(it.chorro){const im=cosa(it.k,it.v),e=it.e||1;if(im.pico){const px=ix+(im.pico[0]-im.width/2)*e*(fl?-1:1),py=iy+(im.pico[1]-im.height/2)*e+1;chorro(g,R(px),R(py),R(py)+it.chorro.h,it.chorro.col,fl?1:-1);}}
    if(it.vapor)vapor(g,ix,iy-(it.e||1)*9-2,it.vn||1);});
  its.forEach(it=>(it._H||[]).forEach(h=>mano(g,h[0],h[1],pi)));}
// a thought: an outlined cloud of round lobes, a trail of small circles that leads to the one who thinks, and a thing in it. (x,y): the top left of the cloud's box; aim: the head of the one who thinks
function nube(g,x,y,o,dir,aim){const im=cosa(o.k,o.v),e=o.e||1,w=Math.max(28,Math.round(im.width*e)+8),h=Math.max(20,Math.round(im.height*e)+6);
  const Lb=[[w*.27,h*.6,h*.36],[w*.5,h*.4,h*.41],[w*.73,h*.6,h*.36],[w*.5,h*.66,h*.36]].map(l=>[R(x+l[0]),R(y+l[1]),Math.max(3,R(l[2]))]);
  Lb.forEach(l=>ovalo(g,l[0],l[1],l[2]+1,l[2]+1,OUT));Lb.forEach(l=>ovalo(g,l[0],l[1],l[2],l[2],"#FFFFFF"));
  const cxn=x+w/2,cyn=y+h/2,A=aim||[cxn-6,y+h+14],vx=A[0]-cxn,vy=A[1]-cyn,dd=Math.hypot(vx,vy)||1,ux=vx/dd,uy=vy/dd,e0=Math.min(w/2/Math.max(.01,Math.abs(ux)),h/2/Math.max(.01,Math.abs(uy)))*.92;
  [[e0+3,3],[e0+8,2]].forEach(q=>{const px=R(cxn+ux*q[0]),py=R(cyn+uy*q[0]);ovalo(g,px,py,q[1]+1,q[1]+1,OUT);ovalo(g,px,py,q[1],q[1],"#FFFFFF");});
  tenidaC(g,o.k,x+(w>>1),y+(h>>1),e,o.v);}
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,6+20*(W.marcas||[]).length,24);   // two places: every story has two scored rounds
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m){g.fillStyle=OUT;for(let k=0;k<11;k++){g.fillRect(x+k,y+1+k,4,3);g.fillRect(x+10-k,y+1+k,4,3);}g.fillStyle="#C8401E";for(let k=0;k<11;k++){g.fillRect(x+1+k,y+2+k,2,1);g.fillRect(x+11-k,y+2+k,2,1);}}
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}
const marca=m=>{const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;};
const enMesa=o=>o.y>=FILA-1&&o.y<=FREN+3&&o.x>MESA[0]-8&&o.x<MESA[0]+MESA[2]+8;
// a roll with its state (st: ab open and empty, ce closed, mo with a bite out of it, m2 half eaten; con: chocolate or butter in it). Nothing grows on it: a roll that was not liked is only bitten
function rolloD(c,x,yb,r,a){tenida(c,"rollo",x,yb,0,1,r.st+(r.con?":"+r.con:""));}
function cosaDibuja(c,o,a){const k=o.k;
  if(k==="plato"||k==="platoc"){tenida(c,k,o.x,o.y,0,o.e,o.v);(o.rollos||[]).forEach(r=>rolloD(c,o.x+(r.dx||0),o.y-2,r,a));if(o.vapor)vapor(c,o.x,o.y-12,1);return;}
  if(k==="tabla"){tenida(c,"tabla",o.x,o.y);if(o.rollo)rolloD(c,o.x,o.y-3,o.rollo,a);return;}
  if(k==="fuente"){tenida(c,"fuente",o.x,o.y);(o.montones||[]).slice().sort((m,n)=>(m.dy||0)-(n.dy||0)).forEach(m=>tenida(c,"monton",o.x+m.dx,o.y+(m.dy==null?-4:m.dy)));if(o.tenedor)tenida(c,"tenedorH",o.x+o.tenedor.dx,o.y-(o.tenedor.dy==null?4:o.tenedor.dy),0,1);return;}
  if(k==="olla"){tenida(c,"olla",o.x,o.y,0,1,o.v);if(o.vapor&&o.v!=="vacio")vapor(c,o.x,o.y-22,2);return;}
  tenida(c,k==="taza"&&o.sp?"tazacu":k,o.x,o.y,0,o.e||1,k==="azucarera"?(o.tomada?"0":String(Math.min(3,o.spoons==null?3:o.spoons))):o.v);
  if(o.vapor&&!(k==="cesta"&&nCesta()<1))vapor(c,o.x+(o.vdx||0),o.y-(o.vdy==null?(k==="cesta"?18:k==="taza"?15:12):o.vdy),o.vn||2,o.vh);}
// ONE rule for the layers, for every scene and every frame: whoever is behind the table (not seated, his feet above the table's near edge and between its two ends) is drawn behind everybody who sits, together with everything he holds and his arms, and the cloth hides what is below its far edge; so a walker behind the table never shows a head, a tray, a plate or a hand over a seated face, and an arm never floats over the cloth while its body is hidden. The seated and the children at the corners (est) have their hands over the cloth; everybody else is sorted by his feet.
const detrasMesa=p=>!p.sent&&!p.est&&p.z==null&&p.y<TZ&&p.x>62&&p.x<190;
const capa=p=>p.z!=null?[p.z,p.z+.001]:(p.sent||p.est)?[p.y,TZ+.9]:detrasMesa(p)?[40+p.y/100,40.5+p.y/100]:[p.y,p.y<TZ?TZ+.9:p.y+.001];
function draw(c,W,a){const q=W.cq,Gt=W.gente||{};c.imageSmoothingEnabled=false;
  c.drawImage(spr("comer",fondo),0,0);
  const L=[];
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(!p||p.vis===0)return;const cp=capa(p);L.push({y:cp[0],d:()=>cuerpo(c,id,a)});L.push({y:cp[1],d:()=>objetos(c,id,a)});});
  L.push({y:TZ,d:()=>c.drawImage(spr("mesa",mkMesa),MESA[0]-6,MESA[1])});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:enMesa(o)?TZ+o.y/1000:o.y+1,d:()=>cosaDibuja(c,o,a)});});
  if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>{const o=W.perro,f=o.pose==="eat"||o.pose==="walk"||o.cola?(a>>1)%2:0,im=spr("pe"+o.pose+f,()=>mkPerro(o.pose,f));c.save();c.translate(R(o.x),R(o.y));const e=o.e||1;c.scale((o.dir<0?-1:1)*e,e);c.translate(0,-im.height+2);c.drawImage(im,-13,0);
    if(o.granos){[[24,10],[26,9],[28,11]].forEach(g=>fr(c,g[0]-13+1,g[1]-1,2,2,"#FFFFFF"));}   // a few grains of rice on his nose
    if(o.lengua){fr(c,14,13,5,3,OUT);fr(c,15,13,3,2,"#F07890");}   // his tongue out, into the bowl
    c.restore();}});
  if(q.vis)L.push({y:q.sobre===0?q.y+27:TZ+(q.y+27)/1000,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  (W.vuelos||[]).forEach(o=>{if(o.k==="chorro")chorro(c,o.x,o.y,o.y+o.h,o.col||"#5A2E14");else tenidaC(c,o.k,o.x,o.y,o.e||1,o.v,o.flip);});
  if(SINTXT){   // the words are hidden: whoever speaks has an empty speech bubble over him (a tail to his head), clear of what is around him
    const hab=(tx,ty,bcx)=>{const bw=17,bh=11,bx=bcx-8,by=ty-4-bh;fr(c,bx-1,by,bw+2,bh,OUT);fr(c,bx,by-1,bw,bh+2,OUT);fr(c,bx,by,bw,bh,"#FFFFFF");fr(c,bx,by,bw,1,"#F2F2F8");
      [-4,0,4].forEach(i=>fr(c,bcx+i-1,by+4,2,2,"#2A1810"));
      const ax=Math.max(bx+3,Math.min(bx+bw-3,tx));for(let r=0;r<5;r++){const px=Math.round(ax+(tx-ax)*r/4),hw=Math.max(0,3-r);fr(c,px-hw-1,by+bh+r-0,2*hw+3,1,OUT);if(r<4)fr(c,px-hw,by+bh+r,2*hw+1,1,"#FFFFFF");}};
    if(TALK==="coqui"&&q.vis){const b=frogBox(q),fx=b.x+(b.w>>1),fy=b.y+R(q.dy);hab(fx,fy-3,fx);}
    else if(TALK&&Gt[TALK]&&Gt[TALK].vis!==0){const t=talkAt(TALK,W),p=Gt[TALK];if(t){if(TALK==="abuela"&&p.x>190&&p.y<170)hab(t[0]-6,t[1]+9,t[0]-19);else hab(t[0],t[1]-1,t[0]);}}}
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.piensa&&p.vis!==0)nube(c,R(p.x)-20+(p.pdx||0),R(p.y)-alto(id)-38,p.piensa);});
  if(q.vis&&q.piensa){const b=frogBox(q),n=q.nube||[b.x+(b.w>>1)-20,b.y-44];nube(c,n[0],n[1],q.piensa,q.ndir,q.nubeAim);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1];}
function respIcon(g,k,x,y,w,h,a){}

/* ---------- the places of story 34 (the rice) and of story 35 (the coffee) ---------- */
const HIJA=[213,204],OLLA=[134,158],PLUIS=[100,172],PRANA=[150,174],CASA34=[172,168],EAT34=[162,176],LUIS34=[118,190],FU34=[96,160],PLAT34=[213,118],CONT34=[58,117],SIDE34=[194,166];   // the baby's high chair at the right end, on the floor in front of the stove (inside the picture, out of the way of the ways round the table's left end); the pot; Luis's plate; the frog's small plate; the frog's place; where he stands to eat from his plate; where Luis stands; the platter's place on the table; where the platter waits (the stove top); where a plate is set on the counter top; the way from the stove to the front of the table
async function aEncuentro34(){const l=G("luis");await ruta("luis",[[l.x,FR],[184,FR],[ENC34[0],ENC34[1]]]);l.dir=1;}   // Luis walks along the front to abuela, who is at the stove
async function deEncuentro34(){const l=G("luis");await ruta("luis",[[184,FR],[LUIS34[0],FR],[LUIS34[0],LUIS34[1]]]);l.dir=1;}
const SEAT34={mama:0,carmen:1,abuelo:2,papa:3};   // papá's chair (empty until the end) is the one at the right end: above the frog there is nobody to be covered by his thought
const ENC34=[192,182];   // where Luis and abuela meet for the big spoon: at the right end by the stove, with nothing of the table behind them
const NUBE34={barriga:[146,84],montoncor:[160,100]},AIM34=[172,141];   // the frog's thought stands right above him, clear of the seated and of the answer cards (they are at the top, y 22 to 58), its trail goes to his head
const TENE=(k,dx,dy,o)=>Object.assign({k,dx,dy},o||{});
const D1=p=>p.dir<0?-1:1;
// a long spoon in somebody's hand: the hand and the bowl move together, the handle is no longer than his forearm; where must the hand and the bowl be for the bowl to be at the point (wx,wy) of the picture
function cucharaPos(id,wx,wy,sp){const p=G(id),d=D1(p),cu=CUE(id),S=[R(p.x)+((sp&&sp.side)||d)*cu.sx,R(p.y)-hombroY(id,p)],vx=wx-S[0],vy=wy-S[1],dist=Math.hypot(vx,vy)||1,u=[vx/dist,vy/dist],HL=Math.min(2*cu.L-2,13),hd=Math.max(5,Math.min(2*cu.L-.5,dist-HL)),H=[S[0]+u[0]*hd,S[1]+u[1]*hd],B=[H[0]+u[0]*HL,H[1]+u[1]*HL];
  return [(H[0]-R(p.x))*d,R(p.y)-H[1],(B[0]-R(p.x))*d,R(p.y)-B[1]];}
async function cucharaA(id,sp,wx,wy,n){const t=cucharaPos(id,wx,wy,sp),a=[sp.ax,sp.ay,sp.bx,sp.by];n=n||4;for(let i=1;i<=n;i++){sp.ax=a[0]+(t[0]-a[0])*i/n;sp.ay=a[1]+(t[1]-a[1])*i/n;sp.bx=a[2]+(t[2]-a[2])*i/n;sp.by=a[3]+(t[3]-a[3])*i/n;await wait(TICK);}[sp.ax,sp.ay,sp.bx,sp.by]=t;}
const spoonOf=id=>(G(id).tiene||[]).find(t=>t.k==="uten");
const spoonW=(id,sp)=>{const p=G(id),d=D1(p);return {h:[R(p.x)+d*sp.ax,R(p.y)-sp.ay],b:[R(p.x)+d*sp.bx,R(p.y)-sp.by]};};
const bigSpoon=o=>Object.assign({k:"uten",ax:10,ay:24,bx:22,by:28,load:"",o:{rx:2,ry:1}},o||{});
// the frog's own hands: a spoon whose bowl is at (wx,wy)
function cucharaPosR(wx,wy,izq){const q=W.cq,sx=cx()+(izq?-7:7),sy=pies()-12,vx=wx-sx,vy=wy-sy,dist=Math.hypot(vx,vy)||1,u=[vx/dist,vy/dist],HL=10,hd=Math.max(4,Math.min(11.5,dist-HL)),H=[sx+u[0]*hd,sy+u[1]*hd],B=[H[0]+u[0]*HL,H[1]+u[1]*HL];return [H[0]-cx(),pies()-H[1],B[0]-cx(),pies()-B[1]];}
async function cucharaAR(sp,wx,wy,izq,n){const t=cucharaPosR(wx,wy,izq),a=[sp.ax,sp.ay,sp.bx,sp.by];n=n||4;for(let i=1;i<=n;i++){sp.ax=a[0]+(t[0]-a[0])*i/n;sp.ay=a[1]+(t[1]-a[1])*i/n;sp.bx=a[2]+(t[2]-a[2])*i/n;sp.by=a[3]+(t[3]-a[3])*i/n;sp.gx=sp.ax;sp.gy=sp.ay;await wait(TICK);}[sp.ax,sp.ay,sp.bx,sp.by]=t;sp.gx=sp.ax;sp.gy=sp.ay;}
// the spoon goes from a person's hand to another's (or the frog's), in view: the receiver's hand comes to the middle of the handle while the giver's hand is still on it (both hands on it for a moment), then the giver lets go and his arm goes back to rest
const luisRest=()=>{const l=G("luis");return [R(l.x)+7,R(l.y)-12];};   // where Luis rests his spoon: hanging low at his side, not held up
async function pasaCuchara(de,a){const sp=spoonOf(de);if(!sp)return;const W_=spoonW(de,sp),T=[W_.h[0]+(W_.b[0]-W_.h[0])*.6,W_.h[1]+(W_.b[1]-W_.h[1])*.6];
  const suelta2=async()=>{const g=G(de),d=D1(g),r=rel(de,W_.h[0],W_.h[1]),s=Math.abs(W_.h[0]-g.x)<3?d:(W_.h[0]>g.x?1:-1),hb={k:"brazo",_m:9,gx:r[0],gy:r[1],sh:s*d};g.tiene=g.tiene.filter(t=>t!==sp);g.tiene.push(hb);const rr=restHand(de);await manoA(de,rr[0]*hb.sh,rr[1],3);sinManos(de);};
  if(a==="rana"){const q=W.cq;await ranaA(T[0]+12,T[1]+15);const hb={k:"brazo",gx:-8,gy:3},g1=[T[0]-cx(),pies()-T[1]];q.tiene.push(hb);for(let i=1;i<=3;i++){hb.gx=-8+(g1[0]+8)*i/3;hb.gy=3+(g1[1]-3)*i/3;await wait(TICK);}await wait(TICK*3);
    const sp2={k:"uten",ax:T[0]-cx(),ay:pies()-T[1],bx:W_.b[0]-cx(),by:pies()-W_.b[1],load:sp.load,o:{rx:2,ry:1,plata:0},gx:0,gy:0};sp2.gx=sp2.ax;sp2.gy=sp2.ay;q.tiene=q.tiene.filter(t=>t!==hb);q.tiene.push(sp2);SFX.blip();await suelta2();return sp2;}
  const p=G(a),d=D1(p),r=rel(a,T[0],T[1]);await manoA(a,r[0],r[1],3,0);await wait(TICK*3);
  const sp2={k:"uten",ax:r[0],ay:r[1],bx:(W_.b[0]-R(p.x))*d,by:R(p.y)-W_.b[1],load:sp.load,o:sp.o};sinManos(a);p.tiene.push(sp2);SFX.blip();await suelta2();return sp2;}
// and from the frog's hands to a person's
async function cucharaDeRana(a){const q=W.cq,sp=q.tiene.find(t=>t.k==="uten");if(!sp)return null;const p=G(a),d=D1(p),H=[cx()+sp.ax,pies()-sp.ay],B=[cx()+sp.bx,pies()-sp.by],T=[H[0]+(B[0]-H[0])*.6,H[1]+(B[1]-H[1])*.6],r=rel(a,T[0],T[1]);
  await manoA(a,r[0],r[1],3,0);await wait(TICK*3);   // both hands on it
  const sp2={k:"uten",ax:r[0],ay:r[1],bx:(B[0]-R(p.x))*d,by:R(p.y)-B[1],load:sp.load,o:sp.o};sinManos(a);p.tiene.push(sp2);q.tiene=q.tiene.filter(t=>t!==sp);SFX.blip();await wait(TICK*2);return sp2;}
// the frog's place when he tips a mound onto the plate of the one at seat i (x): beside the plate on the cloth, the spoon in the hand on the side of the plate
const lado34=px=>px>150?{fx:px-17,fy:138,izq:0}:{fx:px+17,fy:138,izq:1};   // beside the plate, one hop from it: his hand is level with the plate and the spoon is only as long as its handle
// the mounds on the platter: g "m" a helping (front row), g "p" papá's (back row, at his end)
function fuenteMonton(g){const fu=ob("fuente");if(!fu||!fu.montones)return null;const m=fu.montones.filter(m=>m.g===g)[0];return m?{fu,m,x:fu.x+m.dx,y:fu.y+(m.dy==null?-4:m.dy)-3}:null;}
const origen=()=>{const fu=ob("fuente"),h=fuenteMonton("m");if(h&&fu&&fu.x<200)return {x:h.x,y:h.y,take:()=>{h.fu.montones.splice(h.fu.montones.indexOf(h.m),1);}};const ol=ob("olla");return {x:ol.x,y:ol.y-14,take:()=>{}};};


/* ---------- story 34: forks and forkfuls ---------- */
const tenedorDe=id=>(G(id).tiene||[]).find(t=>t.k==="tenedor");
const FRESTO=id=>id==="luis"?[-9,19]:[7,12];   // a fork at rest in a hand: low, at his plate
// he lays his fork down by his plate (it stays there), or takes it up again
async function dejaTenedor(id){const p=G(id),f=tenedorDe(id),pl=ob("pl_"+id);if(!f)return;const d=D1(p),dx=pl.x+(id==="luis"?-18:18);
  await mueveTiene(id,f,(dx-p.x)*d,p.y-(pl.y-1),3);W.cosas.push({id:"tf_"+id,k:"tenedorH",x:dx,y:pl.y-1});SFX.blip();await suelta(id,f);}
async function tomaTenedor(id){const p=G(id);if(tenedorDe(id))return tenedorDe(id);const c=ob("tf_"+id);const r=FRESTO(id);
  if(!c){const it={k:"tenedor",e:1,dx:r[0],dy:r[1]};p.tiene.push(it);return it;}
  const it=await toma(id,c,null,null,{n:3});it.k="tenedor";it.e=1;it.v="";W.cosas.splice(W.cosas.indexOf(c),1);await mueveTiene(id,it,r[0],r[1],3);return it;}
// forkfuls: the fork goes down to his plate, comes up with rice on it (the plate has less: niveles are the plate's states after each forkful), goes to his mouth, he chews; then the fork goes back to rest
async function forkfuls(id,pl,niveles){const p=G(id),f=await tomaTenedor(id);if(!f)return;const d=D1(p),pd=[(pl.x-p.x)*d,p.sent?17:p.y-(pl.y-6)];   // seated, the plate is far below his shoulder: the fork dips just over it
  for(const nv of niveles){await mueveTiene(id,f,pd[0],pd[1]-4,3);await wait(TICK*2);f.v="c";pl.v=nv;SFX.blip();await wait(TICK*4);
    await mueveTiene(id,f,p.sent?9:11,bocaY(id,p)-6,3);await wait(TICK*3);f.v="";p.boca=1;await wait(TICK*4);p.boca=0;await wait(TICK*2);}
  const r=FRESTO(id);await mueveTiene(id,f,r[0],r[1],3);}
// the level of rice in the pot at the n-th scoop
const nivelOlla=n=>n<=1?"lleno0":n>=18?"vacio":"n"+Math.min(7,Math.max(1,Math.ceil((n-1)*7/16)));   // 18 scoops in all (Luis's eight, the three small helpings, the seven mounds): a level for every other scoop

/* ---------- the places of story 35 ---------- */
const K1=[76,170],K2=[100,170],AZU=[138,170],TRANA=[172,170],GRECA35=[152,162],GRECA35B=[158,178],TABU=[186,154],CASA35=[110,166],CANELO=[48,208],TAZON=[98,208],STOOL=[210,178],NUBE35=[102,104],AIM35=[110,139],CAFE35=[199,118],CAZO35=[218,118];   // the children's cups; the sugar bowl; the frog's cup; the greca (the little coffee pot) and abuela's cup, at the right end of the table (a clear gap between them); the frog's place; Canelo and his bowl, at the left front, out of abuela's ways; abuela's stool; the big coffee pot and the milk pan on the stove
const copa=id=>ob("t_"+id);
const liq=(id,v,vapor)=>{const t=copa(id);if(t){t.v=v;if(vapor!=null)t.vapor=vapor;}};
// something he pours: its lip is put at (tx,ty); it is turned over to pour to the right (flip), the stream falls h from the lip. For a person (p) or the frog (p = "rana"). The hand is where the handle is
function vierteItem(p,k,v,tx,ty,flip,h,col,e){const im=cosa("tilt"+k,v),E=e||1,s=flip?-1:1,ox=(im.pico[0]-im.width/2)*E*s,oy=(im.pico[1]-im.height/2)*E,cxA=tx-ox,cyA=ty-oy;
  if(p==="rana")return {k:"tilt"+k,v,dx:cxA-cx(),dy:pies()-cyA,e:E,flip:!!flip,chorro:{h,col}};
  const d=p.dir<0?-1:1;return {k:"tilt"+k,v,dx:(cxA-p.x)*d,dy:p.y-cyA,e:E,flip:!!flip,chorro:{h,col}};}
// where must somebody stand so that his hand reaches the handle when the lip of what he pours is at (tx,ty): along his row, the place where the handle is nearest to his shoulder; he walks there (a few steps), then pours
function puestoVierte(id,k,v,tx,ty,flip,ys,dir){const cu=CUE(id);let best={x:Math.round(tx+19),y:ys[0],d:99};
  for(const y of ys){const hy=hombroY(id,{sent:0});for(let x=Math.round(tx-44);x<=tx+48;x+=2){if(Math.abs(x-tx)<14)continue;const fake={x,y,dir:dir||-1,sent:0},it=vierteItem(fake,k,v,tx,ty,flip,10,"#000"),d=fake.dir<0?-1:1,H=agarres(it,x+d*it.dx,y-it.dy,!!flip)[0],sy=y-hy,dd=Math.min(Math.hypot(H[0]-(x-cu.sx),H[1]-sy),Math.hypot(H[0]-(x+cu.sx),H[1]-sy));if(dd<best.d-.5||(Math.abs(dd-best.d)<=.5&&Math.abs(x-tx)<Math.abs(best.x-tx))){best={x,y,d:dd};}}}
  return best;}
const FRENTE=[176,180,184,188,192];   // the rows where abuela can stand round the table (the nearer to the table the higher her shoulder is over a cup)
window.__dev={get puestoVierte(){return puestoVierte;},get vierteItem(){return vierteItem;},get agarres(){return agarres;},get COSA(){return COSA;},get cosaIm(){return cosaIm;},get cuerpo(){return cuerpo;},get objetos(){return objetos;}};
async function vierteA(id,k,v,tx,ty,flip,h,col,ys){const p=G(id),pz=puestoVierte(id,k,v,tx,ty,flip,ys||FRENTE,p.dir);if(Math.abs(pz.x-p.x)>1||Math.abs(pz.y-p.y)>1){const d0=p.dir;await mueve(id,pz.x,pz.y);p.dir=d0;}return vierteItem(p,k,v,tx,ty,flip,h,col);}
const CUCHITA=()=>({k:"uten",ax:9,ay:12,bx:17,by:15,load:"",o:{plata:1,rx:1,ry:1},gx:9,gy:12});   // the frog's teaspoon: the handle is shorter than his forearm
// the frog's hands: he takes a thing in his hand (he must stand beside it) and holds it at (dx,dy) from his feet; he sets it down with its foot at (x,y)
async function ranaToma(o,dx,dy,opt){opt=opt||{};const q=W.cq,e=o.e||1,im=cosa(o.k,o.v),cxw=o.x,cyw=o.y-im.height*e/2,izq=cxw<cx(),it=Object.assign({k:o.k,v:o.v,e:o.e,dx:cxw-cx(),dy:pies()-cyw},opt.extra||{});if(o.sp)it.sp=o.sp;if(o.vapor)it.vapor=o.vapor;
  const fl=opt.flip!=null?opt.flip:(CONASA.has(o.k)?it.dx>0:false);it.flip=fl;const H=agarres(it,cxw,cyw,fl)[0],sd=H[0]>=cx()?1:-1,r=rest=>[sd*9,3];
  const hb={k:"brazo",gx:sd*9,gy:3};q.tiene.push(hb);const g1=[H[0]-cx(),pies()-H[1]];for(let i=1;i<=3;i++){hb.gx=sd*9+(g1[0]-sd*9)*i/3;hb.gy=3+(g1[1]-3)*i/3;await wait(TICK);}
  q.tiene=q.tiene.filter(t=>t!==hb);o.vis=0;q.tiene.push(it);SFX.blip();await wait(TICK);if(dx!=null){const x0=it.dx,y0=it.dy,n=opt.m||4;for(let i=1;i<=n;i++){it.dx=x0+(dx-x0)*i/n;it.dy=y0+(dy-y0)*i/n;await wait(TICK);}}return it;}
async function ranaPon(it,o,x,y,n){const q=W.cq,e=it.e||1,im=cosa(it.k,it.v),t=[x-cx(),pies()-(y-im.height*e/2)],x0=it.dx,y0=it.dy;n=n||4;for(let i=1;i<=n;i++){it.dx=x0+(t[0]-x0)*i/n;it.dy=y0+(t[1]-y0)*i/n;await wait(TICK);}
  Object.assign(o,{v:it.v,x,y,vis:1});if(it.sp)o.sp=it.sp;q.tiene=q.tiene.filter(t=>t!==it);SFX.blip();await wait(TICK);}
// his teaspoon: he takes the spoon that stands in the sugar bowl (the bowl shows none while he has it), dips it into the sugar and lifts it, heaped
const bowlSugar=()=>ob("azucarera");
async function ranaCucharita(){const q=W.cq,az=bowlSugar();let sp=q.tiene.find(t=>t.k==="uten");
  if(!sp){await ranaA(AZU[0]-14,AZU[1]-2);sp=CUCHITA();const w=[AZU[0]+5,AZU[1]-18];sp.ax=w[0]-cx();sp.ay=pies()-w[1];sp.bx=sp.ax+9;sp.by=sp.ay+3;sp.gx=sp.ax;sp.gy=sp.ay;q.tiene.push(sp);az.tomada=1;SFX.blip();await wait(TICK*3);}
  await ranaA(AZU[0]-14,AZU[1]-2);await cucharaAR(sp,AZU[0]+1,AZU[1]-9,false,4);await wait(TICK*2);sp.load="azu";SFX.blip();await wait(TICK*4);return sp;}
// grains of sugar fall from the spoon over a cup, one after the other (six white dots, two pixels each, over about ten ticks)
async function granosCaen(cxw,cyw){const xs=[-3,1,-1,2,0,-2],gs=xs.map(dx=>({k:"grano",x:cxw+dx,y:cyw-17,e:1}));SFX.blip();
  for(let t=0;t<xs.length+4;t++){gs.forEach((g,i)=>{const k=W.vuelos.indexOf(g);if(t>=i&&t<i+4){if(k<0)W.vuelos.push(g);g.y=cyw-17+(t-i)*3;}else if(t>=i+4&&k>=0)W.vuelos.splice(k,1);});await wait(TICK);}
  gs.forEach(g=>{const k=W.vuelos.indexOf(g);if(k>=0)W.vuelos.splice(k,1);});}
// the teaspoon with sugar is brought to a cup (the cup is at (cxw,cyw) at the moment): grains fall from it into the cup in three little falls, he stirs, and the spoon stays standing in the cup
async function azucarEn(cxw,cyw,sp,cup,mal,who){const q=W.cq;
  const fx=cxw<150?cxw-16:cxw+16,fy=146,iz=fx>cxw;await ranaA(fx,fy);await cucharaAR(sp,cxw+(iz?4:-4),cyw-12,iz,5);if(mal)W.lista35=1;await wait(TICK*3);
  sp.load="";await granosCaen(cxw,cyw);{const base=cup.v;cup.v=base+"+";await wait(TICK*5);cup.v=base;}   // the grains fall, a small white heap lies on the coffee for a moment, then he stirs
  if(mal)cup.v="azu";await wait(TICK*2);
  await ranaA(AZU[0]-14,AZU[1]-2);await cucharaAR(sp,AZU[0]+5,AZU[1]-17,false,4);q.tiene=q.tiene.filter(t=>t!==sp);bowlSugar().tomada=0;SFX.blip();await wait(TICK*3);   // the spoon goes back into the bowl (it is his, and only carries sugar)
  if(!mal&&who)await revuelve(who);}   // and the man stirs with his own teaspoon and leaves it standing in his cup
// each man has a teaspoon of his own lying by his cup: after the sugar goes in he takes it with his free hand, stirs, and leaves it standing in the cup; or he lays it down again (empty cups)
async function revuelve(id){const p=G(id),tc=ob("tc_"+id),cup=p.tiene.find(x=>x.k==="taza"||x.k==="tazacu");if(!tc||tc.vis===0||!cup)return;
  const it=await toma(id,tc,null,null,{n:3,m:3,flip:false});it.k="cucharilla";const dd=D1(p);
  await mueveTiene(id,it,cup.dx-2,cup.dy+8,3);for(let i=0;i<4;i++){it.dx+=i%2?3:-3;await wait(TICK*2);}   // he stirs
  cup.sp=1;cup.k="tazacu";SFX.blip();await suelta(id,it);await wait(TICK*2);}
async function dejaCuchara(id){const p=G(id),t=copa(id),tc=ob("tc_"+id);if(!tc||tc.vis!==0)return;
  const r=rel(id,t.x+1,t.y-16),hb={k:"brazo",_m:1,gx:0,gy:0,sh:1};p.tiene.push(hb);const rr=restHand(id);hb.gx=rr[0];hb.gy=rr[1];await manoA(id,r[0],r[1],3,1);t.sp=0;SFX.blip();
  const it={k:"cucharilla",e:1},c=centroPara(id,it,t.x+1,t.y-16);it.dx=c[0];it.dy=c[1];sinManos(id);p.tiene.push(it);await wait(TICK);
  await pon(id,it,tc,tc.x,tc.y,3);tc.vis=1;await wait(TICK);}
// somebody drinks from the cup he holds: lift, sip, the cup is lower (niveles: what is in it after each sip), down again
async function sorbos(id,it,niveles,dx0,dy0){const p=G(id);for(const nv of niveles){await mueveTiene(id,it,p.sent?10:12,bocaY(id,p)-2,4);await wait(TICK*3);it.ang=.5;p.boca=1;SFX.blip();await wait(TICK*5);it.v=nv;await wait(TICK*3);it.ang=0;p.boca=0;await wait(TICK*2);await mueveTiene(id,it,dx0,dy0,4);await wait(TICK*3);}}
// the half-full state of a cup: its colour and a low bar
const mitad=v=>(String(v).replace(/_$/,""))+"_";

/* ---------- moving: everybody walks, every thing is carried by a hand ---------- */
const PASO_PX=5;   // pixels a walker moves in one tick (about 70 a second)
// a walk: a straight line at a steady pace, one foot after the other. Nobody jumps from one place to another.
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y,dist=Math.hypot(x-x0,y-y0);if(dist<.5){p.x=x;p.y=y;return;}n=n||Math.max(1,Math.ceil(dist/PASO_PX));p.sent=0;p.est=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;
  for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;p.ci=(p.ci||0)+1;p.pie=[1,0,2,0][p.ci%4];await wait(TICK);}p.x=x;p.y=y;p.paso=0;p.pie=0;}
async function ruta(id,pts){for(const q of pts)await mueve(id,q[0],q[1]);}
// a thing falls or slides a short way (grains, a roll off a tipped tray, a drop): never from a table to a hand
async function vuela(o,x0,y0,x1,y1,n,arco){const v=Object.assign({x:x0,y:y0},o);W.vuelos.push(v);n=n||5;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(x1-x0)*t;v.y=y0+(y1-y0)*t-(arco==null?0:arco)*Math.sin(t*Math.PI);await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);}
// the thing a person holds changes place in his hand: it slides from where it is to (dx,dy) from his feet
async function mueveTiene(id,it,dx,dy,n){n=n||5;const x0=it.dx,y0=it.dy;for(let i=1;i<=n;i++){it.dx=x0+(dx-x0)*i/n;it.dy=y0+(dy-y0)*i/n;await wait(TICK);}it.dx=dx;it.dy=dy;}
const corre=(o,pr)=>{if(o&&o.suelto){W._mov=pr;return Promise.resolve();}return pr;};
async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(6,Math.ceil(d/26))));}   // a long way is several small hops (about 26 px each, five frames a hop): never 50 px between two pictures
const cx=()=>W.cq.x+16,pies=()=>W.cq.y+27;
// where somebody comes in from (out of the picture, at the left: he walks in), where he goes out to (he walks out). Nobody is seen with his feet above the floor outside the table (the counter and the stove fronts end at y 146): to go behind the table he walks on the floor to its end and in under the edge of the cloth (it hides him from the waist down), and up to the lane behind the table; to come out he does the same the other way.
const detrasOK=p=>p.y<148&&p.x>66&&p.x<190;   // already behind the table
const SUBE=[80,182];   // where somebody goes up (and comes down) between the floor and the lane behind the table, in under the cloth: at the left end, and at the right end
// to the lane behind the table (round the end of the table that is nearer to where he is going, so that nobody carries a roll across the table with his body hidden): along the floor to the end, in under the edge of the cloth, up to the lane
async function detras(id,x,y){const p=G(id);y=y==null?ATRAS:y;
  if(detrasOK(p)){await mueve(id,x,y);return;}
  if(x<125){const pts=[];if(p.x>66&&p.y<FR-2)pts.push([p.x,FR]);if(p.x>66)pts.push([48,FR]);pts.push([48,FLO],[SUBE[0],FLO],[SUBE[0],ATRAS],[x,y]);await ruta(id,pts);}
  else{const pts=[];if(p.x<186&&p.y<FR-2)pts.push([p.x,FR]);if(p.x<194)pts.push([194,FR]);pts.push([194,FLO],[SUBE[1],FLO],[SUBE[1],ATRAS],[x,y]);await ruta(id,pts);}}
async function delante(id,x,y){const p=G(id);
  if(!detrasOK(p)){await mueve(id,x,y);return;}
  if(x<125){const pts=[];if(p.x>SUBE[0])pts.push([SUBE[0],Math.min(p.y,ATRAS+6)]);pts.push([SUBE[0],FLO],[48,FLO]);if(x>66&&y>162)pts.push([48,FR],[Math.max(x,50),FR]);pts.push([x,y]);await ruta(id,pts);}
  else{const pts=[];if(p.x<SUBE[1])pts.push([SUBE[1],Math.min(p.y,ATRAS+6)]);pts.push([SUBE[1],FLO],[194,FLO]);if(x<194)pts.push([194,FR],[Math.min(x,194),FR]);pts.push([x,y]);await ruta(id,pts);}}
async function entra(id,x,y,dir){const p=G(id);p.sent=0;p.pose="idle";if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=y;}p.dir=1;p.tiene=p.tiene||[];await mueve(id,x,y);if(dir)p.dir=dir;}
async function sale(id){const p=G(id);if(p.vis===0)return;p.sent=0;p.est=0;p.come=null;p.cara=null;p.pose="idle";p.abre=0;
  if(detrasOK(p))await delante(id,46,190);
  else if(p.x>84&&p.y<FR-2)await mueve(id,p.x,FR);
  await mueve(id,PUERTA[0],Math.max(190,Math.min(p.y,FR)));p.vis=0;}
// to a chair behind the table (round the end of the table, in under the cloth, along the lane), and sits: the last step down is in view (the legs bend, the body lowers)
async function sienta(id,i){const p=G(id);if(p.vis!==0&&p.sent&&Math.abs(p.x-SILLA[i])<2)return;p.sent=0;p.est=0;if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=190;p.tiene=p.tiene||[];}
  await detras(id,SILLA[i]-3,ATRAS);await mueve(id,SILLA[i],ASIENTO,3);p.dir=1;p.pose="idle";p.tiene=p.tiene||[];
  p.sent=1;p.y=ASIENTO;p.dy=-4;await wait(TICK*4);p.dy=-2;await wait(TICK*4);p.dy=0;SFX.blip();await wait(TICK);}
// he stands up from his chair in steps (he leans forward and rises, then stands, then walks), and walks round the end of the table to (x,y) on the floor
async function levanta(id,x,y){const p=G(id);p.pose="idle";
  p.dy=-3;await wait(TICK*4);p.dy=-6;await wait(TICK*4);   // still sitting, rising: his head goes up in steps (3, 6, then upright: 7, then he steps back: 10, 17)
  p.sent=0;p.y=ASIENTO;p.dy=0;await wait(TICK*4);   // upright, the legs under the cloth
  await mueve(id,p.x,ASIENTO-3,1);await wait(TICK*2);await mueve(id,p.x,ATRAS,2);await delante(id,x,y);}

const SINTXT=new URLSearchParams(location.search).get("txt")==="no";   // with the words hidden a speaker still has an empty bubble over him, so that it is plain who speaks
const NINO=id=>!!(QUIEN[id]&&QUIEN[id].nino);
const LEP=id=>NINO(id)?[58,170]:[52,184];   // where somebody stands to ask: to the left of the table's end, on the floor, clear of the basket and of the table's leg; the basket and the frog's hand are within his arm
const platoNino=()=>({k:"plato",v:"",e:1,dx:-6,dy:14,sh:-1,rollos:[]});   // the plate a child holds in his back hand
/* ---------- hands: reach, take, carry, put down ---------- */
const rel=(id,wx,wy)=>{const p=G(id),d=p.dir<0?-1:1;return [(wx-p.x)*d,p.y-wy];};   // a point of the picture, from his feet, dx towards where he faces
const restHand=id=>{const p=G(id),cu=CUE(id);return [cu.sx+1.5,hombroY(id,p)-(p.sent?cu.L*1.25:cu.L*1.7)];};
// his empty hand goes to (gx,gy) (from his feet) in n ticks; s: the side of the picture of the shoulder it comes from (0: the side he faces)
async function manoA(id,gx,gy,n,s){const p=G(id),d=p.dir<0?-1:1,sh=s?s*d:1,tag=s||9;p.tiene=p.tiene||[];let b=p.tiene.find(t=>t.k==="brazo"&&t._m===tag);
  if(!b){const r=restHand(id);b={k:"brazo",_m:tag,gx:r[0]*(sh),gy:r[1],sh};if(!s)b.gx=r[0];p.tiene.push(b);}
  const x0=b.gx,y0=b.gy;n=n||4;for(let i=1;i<=n;i++){b.gx=x0+(gx-x0)*i/n;b.gy=y0+(gy-y0)*i/n;await wait(TICK);}b.gx=gx;b.gy=gy;return b;}
const sinManos=id=>{const p=G(id);p.tiene=(p.tiene||[]).filter(t=>!t._m);};
// where must the centre of the thing be for its (first) hand to be at the world point (wx,wy)
function centroPara(id,it,wx,wy){const p=G(id),d=p.dir<0?-1:1,fl=it.flip!=null?it.flip:(CONASA.has(String(it.k).replace(/^tilt/,""))?d>0:false),H=agarres(it,0,0,fl)[0];const ix=wx-H[0],iy=wy-H[1];return [(ix-p.x)*d,p.y-iy];}
// he takes thing o off the table in his hand: the hand goes to it, the thing leaves the table in it, and he holds it at (dx,dy) from his feet. Returns the item he holds
async function toma(id,o,dx,dy,opt){opt=opt||{};const p=G(id),d=p.dir<0?-1:1,im=cosa(o.k,o.v),e=o.e||1,cxw=o.x,cyw=o.y-im.height*e/2;
  const it=Object.assign({k:o.k,v:o.v,e:o.e,dx:(cxw-p.x)*d,dy:p.y-cyw},opt.extra||{});if(opt.flip!=null)it.flip=opt.flip;if(o.vapor&&opt.vapor!==0){it.vapor=o.vapor;it.vn=o.vn||1;}
  const fl=it.flip!=null?it.flip:(CONASA.has(String(o.k))?d>0:false),H=agarres(it,cxw,cyw,fl);
  if(H.length>1){const a1=rel(id,H[0][0],H[0][1]),a2=rel(id,H[1][0],H[1][1]);await Promise.all([manoA(id,a1[0],a1[1],opt.n||3,H[0][0]<H[1][0]?-1:1),manoA(id,a2[0],a2[1],opt.n||3,H[0][0]<H[1][0]?1:-1)]);}
  else{const a1=rel(id,H[0][0],H[0][1]),sd=Math.abs(H[0][0]-p.x)<3?0:(H[0][0]>p.x?1:-1);await manoA(id,a1[0],a1[1],opt.n||3,sd);}
  sinManos(id);o.vis=0;p.tiene.push(it);SFX.blip();await wait(TICK);
  if(dx!=null)await mueveTiene(id,it,dx,dy,opt.m||4);return it;}
// he sets the thing he holds down on the table, its foot at (x,y), and lets go: the hand goes back to rest
async function pon(id,it,o,x,y,n,opt){opt=opt||{};const p=G(id),d=p.dir<0?-1:1,im=cosa(it.k,it.v),e=it.e||1,t=[(x-p.x)*d,p.y-(y-im.height*e/2)];
  await mueveTiene(id,it,t[0],t[1],n||4);Object.assign(o,{v:it.v,x,y,vis:1});if(it.sp)o.sp=it.sp;if(opt.after)opt.after(o);SFX.blip();await suelta(id,it);}
// he lets go of the thing he holds (it stays where his hand is, or is gone) and his hand goes back to rest
async function suelta(id,it,quita){const p=G(id),d=p.dir<0?-1:1,fl=it.flip!=null?it.flip:(CONASA.has(String(it.k))?d>0:false),H=agarres(it,p.x+d*it.dx,p.y-it.dy,fl)[0],s=Math.abs(H[0]-p.x)<3?d:(H[0]>p.x?1:-1),r=rel(id,H[0],H[1]);
  p.tiene=p.tiene.filter(q=>q!==it);const b={k:"brazo",_m:9,gx:r[0],gy:r[1],sh:s*d};p.tiene.push(b);const rr=restHand(id);await manoA(id,rr[0]*b.sh,rr[1],3);sinManos(id);}
// the frog's spoon, in his right hand (0) or his left (1): the handle is as long as his forearm
const CUCH=lado=>lado?{k:"uten",ax:-10,ay:12,bx:-20,by:15,load:"",o:{rx:3,ry:2},gx:-10,gy:12}:{k:"uten",ax:10,ay:12,bx:20,by:15,load:"",o:{rx:3,ry:2},gx:10,gy:12};   // a wooden spoon with a plain round bowl (7 x 5): not a grey knife
/* ---------- the plates, the rolls ---------- */
const ROLLOS=pl=>pl.rollos||(pl.rollos=[]);
const nCesta=()=>+String(ob("cesta").v).split(":")[0];
const quitaCesta=()=>{const ce=ob("cesta"),n=nCesta();ce.v=(n-1)+":0";return n-1;};


/* ---------- story 33: where things and people are ---------- */
const CE33=[84,146],BU33=[112,164],CH33=[160,164],HOME33=[82,174],FETCH33=[112,152],HO33=[66,158],PA33=[136,150],PA33S=[146,150],SEAT33={abuelo:0,abuela:1,mama:2,papa:3},PA0=[SILLA[1],FILA],REST33=HOME33;   // the basket; the butter and chocolate dishes in the middle row (the frog stands to the left of the one he works at, his spoon in his right hand, and clear of the other dish); where the frog waits, at the left end of the table, by the one who asks; where he stands to take a roll from the basket (to the right of it); where a roll passes from one hand to the other (between the asker and the frog); where abuela's plate lies at the end, and where it lies at the start (front row, in front of nothing: she stands below it); the chairs (abuelo and mamá apart); abuela's place at the table; where it began
const EST33={luis:{x:72,y:126,pl:[74,124],dir:-1},carmen:{x:180,y:126,pl:[180,124],dir:1}};   // where the children stand to eat: behind the table at its two back corners, in the plane of the seated (the cloth hides them below the chest), clear of the counter and the stove, each by his own plate, facing outwards (what he eats is never over a neighbour)
const enEstacion=id=>{const p=G(id),e=EST33[id];return !!(e&&p&&p.vis!==0&&Math.abs(p.x-e.x)<3&&Math.abs(p.y-e.y)<3);};
// a child walks to his place (from the door or from the left end of the table); and back to the left end
async function vaEstacion(id){const p=G(id),e=EST33[id];if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=190;p.tiene=p.tiene||[];}p.sent=0;p.pose="idle";
  await detras(id,e.x,e.y);p.dir=e.dir;p.est=1;}
async function desdeEstacion(id){const p=G(id),lp=LEP(id);p.pose="idle";p.est=0;await delante(id,lp[0],lp[1]);p.dir=1;}
// the roll in his hand goes onto his plate (the hand puts it down and goes back to rest), or comes off it into his hand
async function ponPlato(id,it,pl){const p=G(id),d=p.dir<0?-1:1;await mueveTiene(id,it,(pl.x-p.x)*d,p.y-(pl.y-6),4);const v=String(it.v).split(":");ROLLOS(pl).push({st:v[0],con:v[1],dx:0});SFX.blip();await suelta(id,it);}
async function tomaPlato(id,pl){const p=G(id),d=p.dir<0?-1:1,ix=ROLLOS(pl).findIndex(r=>!r.mal),r=ROLLOS(pl)[ix];if(!r)return null;const w=[pl.x-4,pl.y-6],r0=rel(id,w[0],w[1]);await manoA(id,r0[0],r0[1],3);ROLLOS(pl).splice(ix,1);SFX.blip();   // a roll that was bitten and left stays on the plate: he takes the new one
  const it={k:"rollo",v:r.st+(r.con?":"+r.con:""),e:1},c=centroPara(id,it,w[0],w[1]);it.dx=c[0];it.dy=c[1];sinManos(id);p.tiene.push(it);await wait(TICK*2);return it;}
// the roll goes from the hand of the one who asks into the frog's hand: he holds it out, the frog's hand comes to its other end, both hands are on it for a moment, then the first lets go
async function rolloAFrog(id,it){const p=G(id),q=W.cq;await ranaA(HOME33[0],HOME33[1]);p.dir=1;
  const c=centroPara(id,it,HO33[0],HO33[1]);await mueveTiene(id,it,c[0],c[1],4);
  const wx=HO33[0]+10,wy=HO33[1]-1,hb={k:"brazo",gx:-9,gy:3},g1=[wx-cx(),pies()-wy];q.tiene.push(hb);for(let i=1;i<=3;i++){hb.gx=-9+(g1[0]+9)*i/3;hb.gy=3+(g1[1]-3)*i/3;await wait(TICK);}
  await wait(TICK*3);
  const fit={k:"rollo",v:it.v,e:1,flip:true,dx:HO33[0]+5-cx(),dy:pies()-(HO33[1]-2)};q.tiene=q.tiene.filter(t=>t!==hb);q.tiene.push(fit);SFX.blip();await suelta(id,it);
  await ranaMueve(fit,-17,17,3);return fit;}
// and the other way: the frog holds the filled roll out, the hand of the one who asked comes to its other end, both hands are on it, the frog lets go
async function rolloDelFrog(id,fit){const p=G(id),q=W.cq;await ranaA(HOME33[0],HOME33[1]);p.dir=1;
  await ranaMueve(fit,HO33[0]+5-cx(),pies()-(HO33[1]-2),4);
  const it={k:"rollo",v:fit.v,e:1};const c=centroPara(id,it,HO33[0],HO33[1]);it.dx=c[0];it.dy=c[1];
  const r0=rel(id,HO33[0],HO33[1]);await manoA(id,r0[0],r0[1],3);await wait(TICK*3);   // his hand is on the roll's left end, the frog's on its right
  sinManos(id);p.tiene.push(it);q.tiene=q.tiene.filter(t=>t!==fit);SFX.blip();await wait(TICK*2);return it;}
// something the frog holds moves in his hands to (dx,dy) from his feet
async function ranaMueve(it,dx,dy,n){n=n||4;const x0=it.dx,y0=it.dy;for(let i=1;i<=n;i++){it.dx=x0+(dx-x0)*i/n;it.dy=y0+(dy-y0)*i/n;await wait(TICK);}it.dx=dx;it.dy=dy;}
// the frog eats at his plate with his fork (it lies by the plate): his hand takes it, he takes a forkful from the plate (it has less), brings it to his mouth, and so three times; he lays the fork down again
async function ranaFork(niveles){const q=W.cq,pl=ob("pl_rana"),tf=ob("tf_rana");await ranaA(EAT34[0],EAT34[1]);
  const it=await ranaToma(tf,null,null,{n:3,m:3,flip:false});it.k="tenedor";it.v="";it.e=1;W.cosas.splice(W.cosas.indexOf(tf),1);await ranaMueve(it,12,9,3);
  const pd=[PRANA[0]+4-cx(),pies()-(PRANA[1]-1)+1];
  for(const nv of niveles){await ranaMueve(it,pd[0],pd[1],3);await wait(TICK*2);it.v="c";pl.v=nv;SFX.blip();await wait(TICK*3);
    await ranaMueve(it,-3,13,3);await wait(TICK*2);it.v="";q.hace="come";await wait(TICK*3);q.hace=null;await wait(TICK*2);SFX.blip();}
  await ranaMueve(it,pd[0]+8,pd[1]+3,3);W.cosas.push({id:"tf_rana",k:"tenedorH",x:PRANA[0]+12,y:PRANA[1]-1});q.tiene=q.tiene.filter(t=>t!==it);SFX.blip();await wait(TICK*2);}
// his belly swells over three frames, and (vuelca) he tips over on his back over two more; deflating is the same the other way
async function inflar(vuelca){const q=W.cq;q.lleno=1;for(let i=1;i<=3;i++){q.hinch=i;await wait(TICK*4);}
  if(vuelca){for(let i=1;i<=2;i++){q.caida=i;await wait(TICK*4);}q.espalda=1;q.caida=0;SFX.bonk();await wait(TICK*5);}}
async function desinflar(){const q=W.cq;if(q.espalda){q.espalda=0;for(let i=2;i>=1;i--){q.caida=i;await wait(TICK*4);}q.caida=0;await wait(TICK*3);}
  for(let i=2;i>=0;i--){q.hinch=i;await wait(TICK*4);}q.lleno=0;q.hinch=3;await wait(TICK*2);}
const acts={
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async ya(){const p=W._mov;W._mov=null;if(p)await p;},
  async g(o){const p=G(o.quien);if(!p)return;Object.keys(o).forEach(k=>{if(!["act","quien","ms"].includes(k))p[k]=o[k]===""?null:o[k];});if(o.ms)await wait(+o.ms);},
  async nota(o){V[o.k]=o.v==null?"1":String(o.v);},

  /* ----- story 33: ¿Qué quieres? ----- */
  // The five rolls come split in the basket (cut open, empty), steaming; the second tray waits on the stove. Whoever asks walks in to the left end of the table (to the left of it, on the floor, clear of the basket), takes a roll from the basket with his hand and holds it up (a beat at rest);
  // he gives it into the frog's hand (both hands on it for a moment) and walks out to wash his hands; the frog (his one spoon in his right hand, the roll in his left) fills the roll with the spoon and closes it; the asker walks in again, takes the roll from the frog's hand and eats it at his place, in three bites.
  // A roll he did not like is bitten once and left on his plate, to the end. The children eat at the two back corners of the table, by their plates, inside the cloth that hides their feet. Every move is a hand's, and everybody walks.
  async inicio33(){W.gente={abuela:{x:FOGON[0],y:FOGON[1],dir:-1,tiene:[]},abuelo:{vis:0,tiene:[]},mama:{vis:0,tiene:[]},papa:{vis:0,tiene:[]},luis:{vis:0,tiene:[]},carmen:{vis:0,tiene:[]}};W.sitio={};
    const pl=(id,x)=>({id,k:"plato",x,y:FILA,rollos:[]});
    W.cosas=[{id:"pl_abuela",k:"plato",x:PA33S[0],y:PA33S[1],rollos:[]},pl("pl_abuelo",SILLA[SEAT33.abuelo]),pl("pl_mama",SILLA[SEAT33.mama]),pl("pl_papa",SILLA[SEAT33.papa]),
      {id:"pl_luis",k:"platoc",x:EST33.luis.pl[0],y:EST33.luis.pl[1],rollos:[]},{id:"pl_carmen",k:"platoc",x:EST33.carmen.pl[0],y:EST33.carmen.pl[1],rollos:[]},
      {id:"cesta",k:"cesta",v:"5:0",x:CE33[0],y:CE33[1],vapor:1,vdx:2,vdy:18,vn:2},
      {id:"mant",k:"mantequilla",v:"5",x:BU33[0],y:BU33[1]},{id:"choc",k:"choc",v:"5",x:CH33[0],y:CH33[1]},
      {id:"bandeja",k:"bandeja",v:4,x:213,y:121,vapor:1,vdx:0,vdy:12,vn:2}];
    Object.assign(W.cq,{x:REST33[0]-16,y:REST33[1]-27,s:1,sobre:1,dy:0,vis:1,tiene:[CUCH(0)],lleno:0,espalda:0,piensa:null});},
  // abuela walks from the stove along the floor in front of the table (below it: nothing of the table is hidden), to stand in front of her plate; with one hand on its rim (it is within her arm's reach) she slides it a little towards the basket, a step at a time; she lets go and walks out to the yard
  async plato33(o){const ab=G("abuela"),pl=ob("pl_abuela");const pr=(async()=>{
      await ruta("abuela",[[FOGON[0],FR],[PA33S[0]-2,FR],[PA33S[0]-2,184]]);ab.dir=-1;await wait(TICK*2);
      const hb={k:"brazo",_m:1,gx:0,gy:0,sh:1};ab.tiene.push(hb);const hand=()=>[(pl.x-ab.x)*-1,ab.y-(pl.y-1)];const h0=restHand("abuela");const h1=hand();hb.gx=h0[0];hb.gy=h0[1];
      for(let i=1;i<=3;i++){hb.gx=h0[0]+(h1[0]-h0[0])*i/3;hb.gy=h0[1]+(h1[1]-h0[1])*i/3;await wait(TICK);}
      await wait(TICK*2);const n=4,x0=pl.x,ax0=ab.x;SFX.blip();
      for(let i=1;i<=n;i++){pl.x=x0+(PA33[0]-x0)*i/n;ab.x=ax0+(PA33[0]-2-ax0)*i/n;const h=hand();hb.gx=h[0];hb.gy=h[1];await wait(TICK*2);}
      await wait(TICK*2);const rr=restHand("abuela");await manoA("abuela",rr[0],rr[1],3,1);sinManos("abuela");await wait(TICK*3);await sale("abuela");})();return corre(o,pr);},
  // a person walks in to the left end of the table (on the floor, to the left of it); his hand takes a roll from the basket and he holds it up, cut open and empty, for a moment (the frog sees it)
  async viene33(o){const id=o.a,p=G(id),ce=ob("cesta"),lp=LEP(id);
    if(p.vis!==0&&p.sent){await levanta(id,lp[0],lp[1]);}else if(p.vis!==0&&EST33[id]){await desdeEstacion(id);}else await entra(id,lp[0],lp[1],1);
    p.dir=1;p.pose="idle";
    if(+o.rollo){const w=[ce.x-9,ce.y-5],r0=rel(id,w[0],w[1]);await manoA(id,r0[0],r0[1],3);quitaCesta();SFX.blip();   // his hand takes a roll out of the basket
      const it={k:"rollo",v:"ab",e:1},c=centroPara(id,it,w[0],w[1]);it.dx=c[0];it.dy=c[1];sinManos(id);p.tiene.push(it);await wait(TICK*2);
      await mueveTiene(id,it,15,NINO(id)?29:36,4);await wait(TICK*14);}},   // held up beside his face, the open side towards us, for a moment at rest
  // he gives the roll into the frog's hand (both hands on it for a moment), and walks out to wash his hands
  async sale33(o){const id=o.a,p=G(id);if(+o.fin)return;
    const it=(p.tiene||[]).find(t=>t.k==="rollo");
    if(it){await rolloAFrog(id,it);await wait(TICK*3);}
    await sale(id);},
  // the frog fills the roll in his left hand with his spoon (in his right): if he has none (the first rounds, a second roll after a miss) he goes to the right of the basket and takes one out of it; he goes to the dish, dips the spoon (the dish has less) and tips it into the roll and closes it
  async rellena33(o){const id=o.a,k=String(o.k),dish=ob(k==="choc"?"choc":"mant"),ce=ob("cesta"),q=W.cq;
    q.piensa=null;const sp=q.tiene.find(t=>t.k==="uten");let fit=q.tiene.find(t=>t.k==="rollo");
    if(!fit){await ranaA(FETCH33[0],FETCH33[1]);const ro={k:"rollo",v:"ab",x:ce.x+10,y:ce.y-5,vis:1};fit=await ranaToma(ro,-17,17,{n:3,m:3,flip:true});quitaCesta();await wait(TICK*2);}
    // the spoon into the dish (he stands to the left of it, the spoon in his right hand), up full
    await ranaA(dish.x-20,dish.y-2);sp.load="";SFX.blip();const bx=dish.x-cx(),by=pies()-(dish.y-7),bx0=sp.bx,by0=sp.by;for(let i=1;i<=3;i++){sp.bx=bx0+(bx-bx0)*i/3;sp.by=by0+(by-by0)*i/3;await wait(TICK);}await wait(TICK*3);
    sp.load=k==="choc"?"c":"m";dish.v=String(Math.max(1,+dish.v-1));SFX.blip();await wait(TICK*4);
    // the roll is held in front of him, the spoon comes over it, tips it in; he closes the roll
    await ranaMueve(fit,-9,16,3);await cucharaAR(sp,cx()-9,pies()-27,false,4);await wait(TICK*3);
    sp.load="";fit.v="ab:"+(k==="choc"?"c":"m");SFX.blip();await wait(TICK*6);fit.v="ce:"+(k==="choc"?"c":"m");SFX.blip();await wait(TICK*5);
    Object.assign(sp,CUCH(0));sp.load="";await ranaMueve(fit,-17,17,3);await ranaA(HOME33[0],HOME33[1]);},
  // he walks in again; the frog holds the filled roll out and the asker's hand takes it from his; he goes to his chair (the children to their place at the table, where they set it on their plate)
  async regresa33(o){const id=o.a,p=G(id),nino=NINO(id),lp=LEP(id),seat=SEAT33[id];
    if(p.vis!==0&&p.sent)await levanta(id,lp[0],lp[1]);else if(p.vis!==0&&EST33[id])await desdeEstacion(id);else await entra(id,lp[0],lp[1],1);p.dir=1;p.pose="idle";   // after a miss he is still at his place with the bitten roll: he walks round to the new one
    const it=await rolloDelFrog(id,W.cq.tiene.find(t=>t.k==="rollo"));
    await mueveTiene(id,it,13,nino?20:24,4);
    if(!nino){await sienta(id,seat);const i2=p.tiene.find(t=>t.k==="rollo");if(i2){i2.dx=8;i2.dy=22;}}
    else{await vaEstacion(id);const i2=p.tiene.find(t=>t.k==="rollo");await ponPlato(id,i2,ob("pl_"+id));await wait(TICK*3);}},
  // he eats the roll in three bites (it gets smaller, crumbs stay on his plate): right, he chews happily and eats it all; wrong, he bites once, makes a face, puts it down on his plate with the bite out of it and pushes the plate a little away: there it stays
  async come33(o){const id=o.a,p=G(id),nino=NINO(id),pl=ob("pl_"+id);const pr=(async()=>{
      let it=(p.tiene||[]).find(t=>t.k==="rollo");if(!it&&nino)it=await tomaPlato(id,pl);if(!it)return;
      const con=String(it.v).split(":")[1],d=p.dir<0?-1:1;it.flip=d<0;
      const chew=async n=>{for(let i=0;i<n;i++){p.boca=1;await wait(TICK*3);p.boca=0;await wait(TICK*3);}};
      const dxB=p.sent?8:(nino?10:12),alBoca=async()=>{await mueveTiene(id,it,dxB,bocaY(id,p)-2,3);await wait(TICK*2);},baja=async()=>{await mueveTiene(id,it,p.sent?8:13,p.sent?22:(nino?20:24),3);await wait(TICK*3);};
      await alBoca();it.v="mo:"+con;SFX.blip();
      if(+o.bien){await chew(2);await baja();await alBoca();it.v="m2:"+con;SFX.blip();await chew(2);await baja();await alBoca();   // the second bite and the last
        p.tiene=p.tiene.filter(t=>t!==it);SFX.blip();const rr=restHand(id);await manoA(id,rr[0],rr[1],3);sinManos(id);await chew(3);pl.v="mi";await wait(TICK*2);return;}
      p.cara="mal";SFX.bonk();p.dy=-2;await wait(TICK*3);p.dy=0;await wait(TICK*10);
      // the roll down on his plate with the bite out of it; he pushes the plate a little away with his hand, and the roll stays
      await mueveTiene(id,it,(pl.x-p.x)*d,p.y-(pl.y-7),5);ROLLOS(pl).push({st:"mo",con,dx:0,mal:1});SFX.blip();p.tiene=p.tiene.filter(q=>q!==it);
      const r0=rel(id,pl.x,pl.y-6),hb={k:"brazo",_m:9,gx:r0[0],gy:r0[1],sh:1};p.tiene.push(hb);
      await wait(TICK*2);for(let i=0;i<2;i++){pl.y+=2;hb.gy=p.y-(pl.y-6);hb.gx=(pl.x-p.x)*d;await wait(TICK*2);}await wait(TICK);
      const rr=restHand(id);await manoA(id,rr[0],rr[1],3);sinManos(id);p.cara=null;await wait(TICK*3);})();return corre(o,pr);},
  // the turn: the frog steps aside (to the right of the basket); abuela walks in from the yard along the floor below the table to the stove, takes the tray in both hands (four rolls on it, all four in view), carries it back along the same way (at her belly, below the table's edge: nothing is hidden), stands at the left end of the table and tips the tray towards the basket: the four hot rolls slide off its low edge into it, one after the other
  async turno33(o){const ab=G("abuela"),ce=ob("cesta"),tr=ob("bandeja"),q=W.cq;
    ab.tiene=[];ab.pose="idle";ab.vis=1;ab.x=PUERTA[0];ab.y=190;ab.dir=1;const aparte=ranaA(150,160);
    await ruta("abuela",[[46,FR],[196,FR],[200,170],[AFOGON[0],AFOGON[1]]]);ab.dir=-1;await wait(TICK*2);await aparte;
    const t0=await toma("abuela",tr,0,20,{n:3,vapor:0,m:3,extra:{dos:10}});t0.vapor=0;
    await ruta("abuela",[[200,170],[196,FR],[54,FR],[52,176]]);ab.dir=1;await mueveTiene("abuela",t0,11,28,3);await wait(TICK*3);
    // she tips the tray towards the basket, and the rolls slide off its low edge into the basket, one after the other
    const n0=+t0.v;t0.ang=.28;await wait(TICK*3);const base=()=>[R(ab.x)+t0.dx,R(ab.y)-t0.dy];
    for(let i=0;i<n0;i++){const b=base();t0.v=String(n0-1-i);await vuela({k:"rollo",v:"ab"},b[0]+11-i*2,b[1]+3,ce.x-4+i*6,ce.y-10,4,0);ce.v=(i+1)+":0";SFX.blip();await wait(TICK*2);}
    t0.ang=0;await wait(TICK*3);},
  async apunta33(){const ab=G("abuela"),t0=(ab.tiene||[]).find(t=>t.k==="bandeja");if(t0){t0.dos=0;t0.una=1;await mueveTiene("abuela",t0,-6,20,3);}ab.dir=1;ab.pose="offer";SFX.blip();await wait(TICK*12);ab.pose="idle";},
  async sale33a(){const ab=G("abuela");const t0=(ab.tiene||[]).find(t=>t.k==="bandeja");if(t0){t0.una=0;t0.dos=10;await mueveTiene("abuela",t0,0,20,3);}await sale("abuela");ab.tiene=[];},
  // papá and Carmen come in for the first time, stop at the left end, look at the full basket (a hand towards it), and go out again
  async miran33(){const pa=G("papa"),ca=G("carmen");pa.vis=ca.vis=0;pa.tiene=[];ca.tiene=[];
    await Promise.all([entra("papa",54,184,1),(async()=>{await wait(TICK*6);await entra("carmen",40,174,1);})()]);
    pa.pose="offer";ca.pose="tu";SFX.blip();await wait(TICK*4);pa.dy=-2;await wait(TICK*3);pa.dy=0;await wait(TICK*8);ca.dy=-2;await wait(TICK*3);ca.dy=0;await wait(TICK*4);pa.pose="idle";ca.pose="idle";
    await Promise.all([sale("papa"),(async()=>{await wait(TICK*4);await sale("carmen");})()]);},
  // the ending: the grown-ups who are not at the table walk in and sit, the children walk to their corners; abuela walks in to the left end of the table, takes a roll from the basket (it is within her reach there); if a second roll is left she takes the towel from the rim of the basket, holds it over that roll and lays it over it, in view;
  // she walks round along the front (below the table) with the roll in her hand to her plate, lays the roll on it, takes the plate in both hands and carries it round the end of the table and along the lane to her chair, sets it down at her place and sits; she eats the roll plain, in three bites, at her place
  async final33(o){const ce=ob("cesta"),ab=G("abuela"),n=nCesta();
    ab.tiene=[];const kids=["luis","carmen"].filter(id=>!enEstacion(id)),mayores=["abuelo","mama","papa"].filter(id=>!(G(id).vis!==0&&G(id).sent));
    await Promise.all(mayores.map((id,i)=>(async()=>{await wait(TICK*i*6);await sienta(id,SEAT33[id]);})()));
    const kp=Promise.all(kids.map((id,i)=>(async()=>{await wait(TICK*i*10);await vaEstacion(id);})()));
    const lp=[54,170];await entra("abuela",lp[0],lp[1],1);ab.dir=1;V.pan=n>0?"1":"";
    let it=null;
    if(n>0){const w=[ce.x-9,ce.y-5],r0=rel("abuela",w[0],w[1]);await manoA("abuela",r0[0],r0[1],3,1);quitaCesta();SFX.blip();it={k:"rollo",v:"ce",e:1,sh:1};const c=centroPara("abuela",it,w[0],w[1]);it.dx=c[0];it.dy=c[1];sinManos("abuela");ab.tiene.push(it);await wait(TICK*2);
      await mueveTiene("abuela",it,-3,24,3);await wait(TICK*2);it.sh=-1;await wait(TICK*2);}   // the roll comes to her belly and goes into her other hand
    if(n>1){   // the towel: she takes it off the rim, holds it over the roll that is left and lays it over it
      const tw=[ce.x-13,ce.y-11],r0=rel("abuela",tw[0],tw[1]);await manoA("abuela",r0[0],r0[1],3,1);ce.v="1:4";SFX.blip();sinManos("abuela");
      const pn={k:"pano",e:1,dx:r0[0],dy:r0[1],sh:1};ab.tiene.push(pn);await wait(TICK*3);
      const ov=rel("abuela",ce.x-7,ce.y-15);await mueveTiene("abuela",pn,ov[0],ov[1],3);await wait(TICK*3);
      ab.tiene=ab.tiene.filter(t=>t!==pn);ce.v="1:1";ce.vapor=0;SFX.blip();const hb2={k:"brazo",_m:1,gx:ov[0],gy:ov[1],sh:1};ab.tiene.push(hb2);await wait(TICK*3);
      const rr=restHand("abuela");await manoA("abuela",rr[0],rr[1],3,1);sinManos("abuela");}else ce.vapor=0;
    const pa=ob("pl_abuela");
    if(it){   // the roll goes onto her own plate (she stands in front of it, within reach), she takes the plate in her hands and carries it, with the roll on it, to her chair
      await ruta("abuela",[[54,FR],[PA33[0]-2,FR],[PA33[0]-2,183]]);ab.dir=1;await ponPlato("abuela",it,pa);await wait(TICK*3);
      const pit=await toma("abuela",pa,null,null,{n:3,extra:{rollos:pa.rollos,dos:7}});await mueveTiene("abuela",pit,0,18,3);
      await ruta("abuela",[[PA33[0],FR]]);await detras("abuela",SILLA[SEAT33.abuela]-11,ASIENTO);ab.dir=1;ab.est=1;await pon("abuela",pit,pa,PA0[0],PA0[1],4);await wait(TICK*2);}
    else{await ruta("abuela",[[54,FR]]);}
    await sienta("abuela",SEAT33.abuela);await kp;
    if(it){const r2=await tomaPlato("abuela",pa);if(r2){ab.dir=1;r2.flip=false;await mueveTiene("abuela",r2,8,bocaY("abuela",ab)-1,3);await wait(TICK*2);
      for(let i=0;i<3;i++){r2.v=i==0?"mo":"m2";SFX.blip();for(let j=0;j<2;j++){ab.boca=1;await wait(TICK*3);ab.boca=0;await wait(TICK*3);}if(i<2){await mueveTiene("abuela",r2,8,22,3);await wait(TICK*3);await mueveTiene("abuela",r2,8,bocaY("abuela",ab)-1,3);await wait(TICK*2);}}
      ab.tiene=ab.tiene.filter(t=>t!==r2);pa.v="mi";const rr=restHand("abuela");await manoA("abuela",rr[0],rr[1],2);sinManos("abuela");}}
    W.cq.hace=n>0?"come":null;await wait(TICK*8);},

  /* ----- story 34: Buen provecho ----- */
  // Lunch: yellow rice. Mamá (seat 1), Carmen (2) and abuelo (4) sit, a fork in each hand from the first picture; papá's chair (3) and plate are empty; the baby sits in his high chair on the floor at the right end, in front of the stove; Luis stands in front of the table by the pot of rice, his plate and the frog's small plate (his fork lies by it), a fork in his hand; abuela is at the stove with the big spoon hanging low at her side.
  // The platter waits on the stove top, empty, with papá's fork: abuela carries it to the table at the turn.
  async inicio34(){const tf=()=>TENE("tenedor",7,12,{e:1});
    W.gente={mama:{x:SILLA[0],y:ASIENTO,sent:1,dir:1,tiene:[tf()]},carmen:{x:SILLA[1],y:ASIENTO,sent:1,dir:1,tiene:[tf()]},abuelo:{x:SILLA[2],y:ASIENTO,sent:1,dir:1,tiene:[tf()]},papa:{vis:0,tiene:[]},luis:{x:LUIS34[0],y:LUIS34[1],dir:1,tiene:[TENE("tenedor",-9,19,{e:1})]},abuela:{x:FOGON[0],y:FOGON[1],dir:-1,tiene:[bigSpoon({ax:9,ay:23,bx:15,by:32})]}};W.sitio=SEAT34;W.turno=0;W.nO=0;
    const pl=(id,x,v)=>({id,k:"plato",x,y:FILA,v:v||"",rollos:[]});
    W.cosas=[pl("pl_mama",SILLA[0],"r"),pl("pl_carmen",SILLA[1],"r"),pl("pl_papa",SILLA[3]),pl("pl_abuelo",SILLA[2],"r"),
      {id:"pl_luis",k:"plato",x:PLUIS[0],y:PLUIS[1],v:"r",rollos:[]},{id:"pl_rana",k:"platito",x:PRANA[0],y:PRANA[1]},{id:"tf_rana",k:"tenedorH",x:PRANA[0]+12,y:PRANA[1]-1},
      {id:"olla",k:"olla",v:"lleno0",x:OLLA[0],y:OLLA[1],vapor:1},{id:"silla_bebe",k:"sillaBebe",v:"1",x:HIJA[0],y:HIJA[1]},{id:"fuente",k:"fuente",v:"c",x:PLAT34[0],y:PLAT34[1],montones:[],tenedor:{dx:-4,dy:3}}];
    Object.assign(W.cq,{x:CASA34[0]-16,y:CASA34[1]-27,s:1,sobre:1,dy:0,vis:1,tiene:[],lleno:0,espalda:0,piensa:null,nube:NUBE34.barriga,nubeAim:AIM34,ndir:-1});},
  // everybody lifts the fork he holds and waits
  async tenedores34(o){await Promise.all(["mama","carmen","abuelo","luis"].map(async id=>{const p=G(id),f=tenedorDe(id);if(f)await mueveTiene(id,f,12,bocaY(id,p)+8,4);}));SFX.blip();await wait(TICK*10);},
  // they eat: two forkfuls each (the rice on the plate goes down), then the fork lies by the plate
  async come34(o){const pr=(async()=>{await Promise.all(["mama","carmen","abuelo"].map((id,i)=>(async()=>{await wait(TICK*i*3);await forkfuls(id,ob("pl_"+id),["r2","r1"]);await dejaTenedor(id);})()));})();return corre(o,pr);},
  // Luis eats his last forkfuls: three, and his plate is clean
  async luisCome34(o){const pr=(async()=>{await forkfuls("luis",ob("pl_luis"),["r2","r1",""]);})();return corre(o,pr);},
  // Luis walks along the front to abuela, who stands at the stove with the big spoon in her hand (bowl and handle plain); she steps out to meet him, holds it out, he takes it (both hands on it for a moment) and walks back to his place with it in his hand
  async cuchara34(o){const ab=G("abuela"),l=G("luis");
    await aEncuentro34();await mueve("abuela",FOGON[0]-2,176);ab.dir=-1;
    const sp=spoonOf("abuela");await cucharaA("abuela",sp,ab.x-17,ab.y-22,4);await wait(TICK*3);
    const sp2=await pasaCuchara("abuela","luis");await cucharaA("luis",sp2,...luisRest(),5);await wait(TICK*2);
    await mueve("abuela",FOGON[0],FOGON[1]);ab.dir=-1;await deEncuentro34();},
  // Luis: sirve (he serves himself one mound onto his plate), come (he eats it with his fork, two forkfuls), cuchara (he lifts a mound onto the big spoon and holds it out to the frog: tiende), entrega (he hands the frog the spoon with the mound on it); de "p": the mound comes from papá's three. The one big spoon is always in somebody's hand: he never has a second one
  async luis34(o){const l=G("luis"),pl=ob("pl_luis"),pr=(async()=>{
      const sp=spoonOf("luis"),g=o.de==="p"?"p":"m";
      const toma=async()=>{let s=fuenteMonton(g);if(s&&s.fu.x>200)s=null;if(g==="p"&&!s)s=fuenteMonton("m");const src=origen(),pt=s?{x:s.x,y:s.y}:{x:src.x,y:src.y};
        await cucharaA("luis",sp,pt.x,pt.y+3,6);await wait(TICK*2);sp.load="monton";if(s)s.fu.montones.splice(s.fu.montones.indexOf(s.m),1);else{const ol=ob("olla");W.nO=(W.nO||0)+1;if(ol&&ol.vis!==0)ol.v=nivelOlla(W.nO);}SFX.blip();await wait(TICK*4);};
      const reposo=async n=>{const r=luisRest();await cucharaA("luis",sp,r[0],r[1],n||5);};
      if(o.que==="sirve"){await toma();await cucharaA("luis",sp,PLUIS[0],PLUIS[1]-6,6);await wait(TICK*2);sp.load="";pl.v="o";SFX.blip();await wait(TICK*3);await reposo(4);}
      else if(o.que==="come"){await forkfuls("luis",pl,["o1",""]);}
      else if(o.que==="cuchara"){await toma();await cucharaA("luis",sp,PRANA[0]-2,PRANA[1]-9,6);await wait(TICK*3);}   // he holds it out over the frog's plate
      else if(o.que==="entrega"){await toma();await cucharaA("luis",sp,PRANA[0]-5,PRANA[1]-10,5);await pasaCuchara("luis","rana");SFX.blip();await wait(TICK*2);}})();return corre(o,pr);},
  // a thought over the frog: what he would like (quiere) or his round belly with a hand on it beside the clean plate (lleno). Its trail leads to him.
  async piensa34(o){W.cq.nube=o.k==="lleno"?NUBE34.barriga:NUBE34.montoncor;W.cq.nubeAim=AIM34;W.cq.piensa=o.k==="lleno"?{k:"barriga"}:{k:"montoncor"};SFX.blip();await wait(TICK*4);},
  async calla34(){W.cq.piensa=null;},
  // the mound on Luis's spoon goes onto the frog's plate (he tips the spoon over it, then lowers it); the frog eats it at his plate with his fork, in three forkfuls; right after "lleno" his belly swells over three frames, and (entera) he tips over on his back
  async ranaCome34(o){const l=G("luis"),pl=ob("pl_rana"),q=W.cq;const pr=(async()=>{q.piensa=null;const sp=spoonOf("luis");
      if(sp){await cucharaA("luis",sp,PRANA[0],PRANA[1]-7,6);await wait(TICK*2);sp.load="";pl.v="o";SFX.blip();await wait(TICK*3);const r=luisRest();await cucharaA("luis",sp,r[0],r[1],4);}
      await ranaFork(["o2","o1",""]);pl.v="mi";SFX.blip();
      if(o.entera){await inflar(true);await wait(TICK*6);}else{if(o.lleno)await inflar(false);await ranaA(CASA34[0],CASA34[1]);}})();return corre(o,pr);},
  async levantaRana34(){const q=W.cq;await desinflar();SFX.blip();await wait(TICK*2);await ranaA(CASA34[0],CASA34[1]);},
  // Luis eats the mound on the spoon too (the spoon goes up to his mouth): two bites
  async luisCome2(o){const l=G("luis");const pr=(async()=>{W.cq.piensa=null;const sp=spoonOf("luis");if(sp){await cucharaA("luis",sp,l.x+9,l.y-bocaY("luis",l)-2,5);await wait(TICK*2);
      for(const ld of ["monton1",""]){sp.load=ld;SFX.blip();for(let i=0;i<2;i++){l.boca=1;await wait(TICK*2);l.boca=0;await wait(TICK*2);}}
      const r=luisRest();await cucharaA("luis",sp,r[0],r[1],4);}})();return corre(o,pr);},
  // Luis glances at papá's fork (his head turns to the platter) and takes one of papá's three for the frog (rana) or for himself (luis): the spoon goes to papá's end of the platter and takes one mound (the platter shows one less), and back
  async luisPapa34(o){const l=G("luis");l.dir=-1;await wait(TICK*9);l.dir=1;await wait(TICK*2);
    if(o.para==="rana"){await acts.luis34({que:"cuchara",de:"p"});await acts.ranaCome34({});}
    else{await acts.luis34({que:"sirve",de:"p"});await acts.luis34({que:"come"});}},
  // steps 5 and 6: the three at the table; whoever says "Yo estoy lleno/llena" puts a hand on his belly
  async mano34(o){const p=G(o.a);p.pose=o.pose||"yo";SFX.blip();await wait(TICK*3);},
  async plato34(o){const pl=ob("pl_"+o.a);pl.v=o.v||"";},
  // she eats what is left on her plate, in view (a forkful), and lays her fork down: her plate is clean
  async limpia34(o){const pl=ob("pl_"+o.a);await forkfuls(o.a,pl,[""]);await dejaTenedor(o.a);},
  // the frog hops along the cloth with the spoon (Luis handed it to him) to the plate of the one at his seat and tips the mound onto it, where it mixes into his rice (mezcla), or the one eats it with his fork; then he takes the spoon back to Luis: he holds it out, Luis's hand comes to it (both hands on it), the frog lets go
  async tipa34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),q=W.cq,l=G("luis");const pr=(async()=>{q.piensa=null;const L=lado34(pl.x),sp=q.tiene.find(t=>t.k==="uten");if(!sp)return;
      await ranaA(L.fx,L.fy);await cucharaAR(sp,pl.x+(L.izq?-3:3),pl.y-8,!!L.izq,5);await wait(TICK*3);sp.load="";
      if(+o.mezcla){pl.v="h";SFX.bonk();await wait(TICK*8);}else{pl.v="rm";SFX.blip();await wait(TICK*4);p.pose="idle";await forkfuls(id,pl,["r2","r1",""]);await dejaTenedor(id);}
      while(l.come||l.boca)await wait(TICK);
      await ranaA(144,172);await cucharaAR(sp,127,172,true,4);await wait(TICK*2);
      const sp2=await cucharaDeRana("luis");const r=luisRest();
      if(sp2)await cucharaA("luis",sp2,r[0],r[1],3);await ranaA(CASA34[0],CASA34[1]);})();return corre(o,pr);},
  // whoever was full only now puts a hand on his belly and pushes his plate a little away, and holds it so for a moment
  async llenoAhora34(o){const p=G(o.a),pl=ob("pl_"+o.a);p.pose="yo";SFX.blip();await wait(TICK*6);const r=rel(o.a,pl.x,pl.y-6),hb={k:"brazo",_m:9,gx:r[0],gy:r[1],sh:1};p.pose="idle";p.tiene.push(hb);for(let i=0;i<3;i++){pl.y+=2;hb.gy=p.y-(pl.y-6);await wait(TICK*2);}const rr=restHand(o.a);await manoA(o.a,rr[0],rr[1],2);sinManos(o.a);p.pose="yo";await wait(TICK*8);},
  // gets up and says it to the table (a line follows). mamá walks to the high chair and takes the baby in both hands (in the game she walks out with him); with a plate he lays his fork down, takes his plate, carries it to the counter, sets it on the counter top (it stays there) and goes out; otherwise he goes out
  async levanta34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),sb=ob("silla_bebe"),juego=!!W.turno;p.pose="idle";SFX.blip();
    const llevaPlato=id!=="mama"&&(+o.plato||(juego&&pl.v!=="h"));
    if(llevaPlato)await dejaTenedor(id);else if(tenedorDe(id))await dejaTenedor(id);
    p.sent=0;await wait(TICK*2);
    if(id==="mama"){await delante(id,188,206);p.dir=1;const bc=[HIJA[0],HIJA[1]-26];   // both her hands go to the baby, under his arms (from his left side, so that she does not stand in front of him)
      const rL=rel(id,bc[0]-6,bc[1]+7),rR=rel(id,bc[0]+1,bc[1]+7);await Promise.all([manoA(id,rL[0],rL[1],3,-1),manoA(id,rR[0],rR[1],3,1)]);await wait(TICK*3);
      const it={k:"bebeH",e:1,dos:3.5},c=centroPara(id,it,bc[0]-6,bc[1]+7);it.dx=c[0];it.dy=c[1];sinManos(id);p.tiene=[it];sb.v="0";SFX.blip();await wait(TICK*2);   // he is in her hands in the same moment the chair is empty
      await mueveTiene(id,it,3,26,5);if(juego)await sale(id);}
    else if(llevaPlato){const it=await toma(id,pl,null,null,{n:3});await mueveTiene(id,it,12,20,3);await delante(id,CONT34[0]-9,152);p.dir=-1;
      await mueveTiene(id,it,-8,p.y-CONT34[1]+2,4);await pon(id,it,pl,CONT34[0],CONT34[1],3,{after:q=>{q.z=CONT34[1];}});await wait(TICK*3);p.dir=1;if(juego)await sale(id);}
    else{await sale(id);}},
  // she comes back to her chair: mamá puts the baby back in his chair first (both arms, over a few frames); Carmen takes her plate from the counter, carries it to her place, sets it down in front of her and sits
  async vuelve34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),sb=ob("silla_bebe"),seat=SEAT34[id];
    if(id==="mama"){await delante(id,188,206);p.dir=1;const it=p.tiene.find(t=>t.k==="bebeH");await mueveTiene(id,it,(HIJA[0]-p.x)*1,p.y-(HIJA[1]-26),5);sb.v="1";SFX.blip();
      const hs=agarres(it,p.x+it.dx,p.y-it.dy,false),hb=hs.map(h=>{const r=rel(id,h[0],h[1]);return {k:"brazo",_m:h[0]<p.x+it.dx?1:2,gx:r[0],gy:r[1],sh:h[0]<p.x+it.dx?-1:1};});p.tiene=p.tiene.filter(t=>t!==it);hb.forEach(h=>p.tiene.push(h));
      const rr=restHand(id);await Promise.all(hb.map(h=>manoA(id,rr[0]*h.sh,rr[1],3,h.sh)));sinManos(id);await wait(TICK*2);await sienta(id,seat);return;}
    if(+o.plato){await delante(id,CONT34[0]-9,152);p.dir=-1;const cp=ob("pl_"+id);const it=await toma(id,cp,null,null,{n:3});await mueveTiene(id,it,12,20,3);
      await detras(id,SILLA[seat]-8,ASIENTO);p.dir=1;await pon(id,it,Object.assign(pl,{z:null}),SILLA[seat],FILA,4);await sienta(id,seat);}},
  // after a miss: a second mound, from papá's three, for the one who asked: Luis takes it with the spoon, hands it to the frog, the frog tips it onto his plate and he eats it
  async papaB34(o){await acts.luis34({que:"entrega",de:"p"});await acts.tipa34({a:o.a});},
  // the one who asked looks at the platter (his head turns to it)
  async mira34(o){const p=G(o.a);if(!p)return;p.dir=-1;await wait(TICK*10);p.dir=1;},
  // the turn. Luis walks to abuela at the stove and gives her the big spoon (both hands on it), and goes to wait at the left end; abuela takes the platter off the stove top in one hand (the spoon in the other) and carries it along the front to its place;
  // she lifts the pot by its handle, carries it along the front and round the right end to BEHIND the table, and serves the three plates from behind (abuelo, Carmen, mamá: she stands at each one's shoulder, the spoon dips into the pot she holds, the pot is lower, the helping goes over the plate); she carries the pot back and sets it on the table;
  // then she stands between the pot and the platter and scoops the pot onto the platter, mound by mound (seven: four helpings at the left, papá's three at his end), the rice going down at every scoop; she pushes papá's fork behind his three, lifts the pot, tips it towards us: empty; gives the spoon back to Luis at the stove (both hands on it) and walks out with the pot
  async turno34(o){const ab=G("abuela"),l=G("luis"),ol=ob("olla"),fu=ob("fuente");W.turno=1;
    await aEncuentro34();await mueve("abuela",FOGON[0]-2,176);ab.dir=-1;{const sL=spoonOf("luis");await cucharaA("luis",sL,l.x+13,l.y-22,3);await wait(TICK*2);}
    const spA=await pasaCuchara("luis","abuela");spA.side=-1;await cucharaA("abuela",spA,ab.x-17,ab.y-22,3);await wait(TICK*2);
    const lw=ruta("luis",[[184,FR],[58,FR],[58,190]]).then(()=>{l.dir=1;});
    await mueve("abuela",AFOGON[0],AFOGON[1]);ab.dir=-1;const pf=await toma("abuela",fu,0,20,{n:3,m:3,extra:{una:1,tenedor:fu.tenedor,montones:fu.montones}});pf.v="";
    await ruta("abuela",[[SIDE34[0],SIDE34[1]],[192,FR],[FU34[0],FR],[FU34[0],184]]);ab.dir=-1;await pon("abuela",pf,fu,FU34[0],FU34[1],4);fu.tenedor={dx:-4,dy:3};await wait(TICK*3);await lw;
    // the pot: she goes to its right side, takes it by its handle, and carries it with the spoon in her other hand
    await mueve("abuela",OLLA[0]+22,182);ab.dir=-1;const pot=await toma("abuela",ol,-9,19,{n:3,m:3,extra:{una:"h"}});pot.vapor=0;
    const sirve=async id=>{const pl=ob("pl_"+id);await detras("abuela",pl.x+13,130);ab.dir=-1;ab.est=1;await wait(TICK);
      await cucharaA("abuela",spA,R(ab.x)+9,R(ab.y)-25,4);await wait(TICK*2);spA.load="monton";pot.v=nivelOlla(++W.nO);SFX.blip();await wait(TICK*4);   // the spoon dips into the pot she holds: the rice in it is lower
      await cucharaA("abuela",spA,pl.x,pl.y-5,5);await wait(TICK*2);spA.load="";pl.v="o";SFX.blip();await wait(TICK*3);pl.v="r";await wait(TICK*3);};
    for(const id of ["abuelo","carmen","mama"])await sirve(id);
    ab.est=0;await delante("abuela",OLLA[0]-14,184);ab.dir=1;pot.dx=9;
    await pon("abuela",pot,ol,OLLA[0],OLLA[1],4);ol.v=nivelOlla(W.nO);await wait(TICK*3);
    // she stands between the pot and the platter and scoops it onto the platter with the big spoon, in view
    await mueve("abuela",OLLA[0]-16,186);ab.dir=-1;const xs=[-9,-4,-9,-4,4,9,7],ys=[-4,-4,-8,-8,-8,-8,-4];
    const scoop=async()=>{await cucharaA("abuela",spA,OLLA[0],OLLA[1]-14,4);await wait(TICK*2);spA.load="monton";ol.v=nivelOlla(++W.nO);SFX.blip();await wait(TICK*4);};
    for(let i=0;i<7;i++){await scoop();
      await cucharaA("abuela",spA,fu.x+xs[i],fu.y+ys[i]-6,5);await wait(TICK*2);spA.load="";fu.montones.push({dx:xs[i],dy:ys[i],g:i<4?"m":"p"});SFX.blip();await wait(TICK*3);}
    ol.v="vacio";await wait(TICK*2);
    // she pushes papá's fork behind his three mounds with the spoon (the fork lies along the back rim of the platter, hiding none of them)
    const f0=fu.tenedor,fx0=f0.dx,fy0=f0.dy;await cucharaA("abuela",spA,fu.x+fx0-6,fu.y-fy0-2,4);for(let i=1;i<=5;i++){f0.dx=fx0+(8-fx0)*i/5;f0.dy=fy0+(15-fy0)*i/5;await cucharaA("abuela",spA,fu.x+f0.dx-6,fu.y-f0.dy-2,1);await wait(TICK);}
    await wait(TICK*4);
    // the pot: she goes to its left side, takes it by its handle, lifts it and tips it towards us: empty
    await mueve("abuela",OLLA[0]-22,182);ab.dir=1;const pot2=await toma("abuela",ol,9,19,{n:3,m:3,extra:{una:"h"}});pot2.v="vacio";pot2.vapor=0;await mueveTiene("abuela",pot2,5,26,3);pot2.ang=.7;await wait(TICK*10);pot2.ang=0;await mueveTiene("abuela",pot2,9,19,3);
    // she walks to the stove with the pot and the spoon; Luis comes to her, takes the spoon (both hands on it) and goes back; she walks out with the pot
    await ruta("abuela",[[OLLA[0]-22,FR],[186,FR],[FOGON[0]-2,176]]);ab.dir=-1;pot2.dx=-9;await cucharaA("abuela",spA,ab.x-17,ab.y-22,3);
    await aEncuentro34();const spL2=await pasaCuchara("abuela","luis");await cucharaA("luis",spL2,...luisRest(),4);
    ab.tiene=ab.tiene.filter(t=>t!==spA);const back=deEncuentro34();await mueveTiene("abuela",pot2,-3,16,3);await sale("abuela");await back;},
  // papá walks in and sits; abuela walks in, Luis gives her the big spoon (both hands on it); she takes the platter with what is left of it (papá's end) in one hand, the spoon in the other, carries it along the front and round the right end to behind papá's chair, and moves his mounds onto his plate one at a time with the spoon, each leaving the platter in the spoon, in view (the platter shows one less each time); then his fork; she walks back to the stove with the platter, Luis takes the spoon back from her there, and she puts the platter on the stove
  async final34(o){const ab=G("abuela"),pa=G("papa"),l=G("luis"),fu=ob("fuente"),pl=ob("pl_papa");pa.vis=0;ab.vis=0;pa.tiene=[];ab.tiene=[];ab.pose="idle";
    const pr=sienta("papa",SEAT34.papa);await wait(TICK*7);await entra("abuela",FU34[0]-18,FR,1);await pr;
    ab.dir=1;await mueve("abuela",FU34[0]-18,184);ab.dir=1;{const sp0=spoonOf("luis");await cucharaA("luis",sp0,l.x-13,l.y-22,3);l.dir=-1;await wait(TICK);}
    const spA=await pasaCuchara("luis","abuela");spA.side=1;await cucharaA("abuela",spA,ab.x+14,ab.y-22,3);l.dir=1;await wait(TICK*2);
    await mueve("abuela",FU34[0],184);ab.dir=-1;const pf=await toma("abuela",fu,0,20,{n:3,m:3,extra:{una:1,tenedor:fu.tenedor,montones:fu.montones}});pf.v="";
    // along the front, round the right end, behind papá: the platter at her side, the spoon in her other hand
    await mueveTiene("abuela",pf,-11,22,3);await detras("abuela",pl.x+16,130);ab.dir=-1;ab.est=1;await wait(TICK*2);
    const n=fu.montones.filter(m=>m.g==="p").length;
    for(let i=0;i<n;i++){const m=fu.montones.filter(m=>m.g==="p")[0];if(!m)break;
      await cucharaA("abuela",spA,R(ab.x)-pf.dx+m.dx,R(ab.y)-pf.dy+6+(m.dy==null?-4:m.dy)-3,5);await wait(TICK*2);spA.load="monton";fu.montones.splice(fu.montones.indexOf(m),1);SFX.blip();await wait(TICK*3);
      await cucharaA("abuela",spA,pl.x,pl.y-5,5);await wait(TICK*2);spA.load="";pl.v="p"+(i+1);SFX.blip();await wait(TICK*4);}
    if(fu.tenedor){const f0=fu.tenedor,tx=pl.x+15,ty=pl.y-3;await cucharaA("abuela",spA,R(ab.x)-pf.dx+f0.dx-4,R(ab.y)-pf.dy+4-f0.dy,5);await wait(TICK*2);fu.tenedor=null;pf.tenedor=null;
      await cucharaA("abuela",spA,tx-5,ty-5,5);W.cosas.push({id:"tenedor_papa",k:"tenedorH",x:tx,y:ty,z:pl.y+.5});SFX.blip();await wait(TICK*3);}
    V.pmont=String(n);await wait(TICK*2);
    // back along the lane and the front to the stove; Luis takes the spoon; the platter goes back on the stove
    ab.est=0;await delante("abuela",196,FR);await ruta("abuela",[[186,FR],[FOGON[0]-2,176]]);ab.dir=-1;await cucharaA("abuela",spA,ab.x-17,ab.y-22,3);
    await aEncuentro34();const sL=await pasaCuchara("abuela","luis");await cucharaA("luis",sL,...luisRest(),3);const back=deEncuentro34();
    ab.tiene=ab.tiene.filter(t=>t!==spA);await mueve("abuela",AFOGON[0],AFOGON[1]);ab.dir=-1;pf.v="c";await pon("abuela",pf,fu,PLAT34[0],PLAT34[1],4);fu.x=PLAT34[0];fu.y=PLAT34[1];await back;},
  // he takes his fork off his plate and eats his mounds, forkful by forkful (three, two or one)
  async papaCome34(o){const pa=G("papa"),pl=ob("pl_papa");const pr=(async()=>{const fk=ob("tenedor_papa");
      if(fk&&fk.vis!==0){const it=await toma("papa",fk,null,null,{n:3});it.k="tenedor";it.e=1;it.v="";await mueveTiene("papa",it,7,12,3);}else if(!tenedorDe("papa"))pa.tiene.push({k:"tenedor",e:1,dx:7,dy:12});
      const n=+String(pl.v).replace(/\D/g,"")||0;
      if(o.fin){const lv=[];for(let i=n-1;i>=0;i--)lv.push(i?"p"+i:"mi");await forkfuls("papa",pl,lv.length?lv:["mi"]);}else if(n>0){await forkfuls("papa",pl,["p"+(n-1)]);}})();return corre(o,pr);},
  async papaMira34(){const pa=G("papa");pa.dir=1;pa.pose="idle";await wait(TICK*13);},
  /* ----- story 35: Café con azúcar ----- */
  // The table is cleared. Abuelo (chair 2) and papá (chair 4) have black coffee; Luis and Carmen hold cups of hot milk at the left end, beside their faces; the frog stands by the sugar bowl (a green bowl, a heap of sugar, a spoon), his own small cup by him. On the stove: the big blue coffee pot (left burner) and the milk pan (right burner);
  // the greca (the little red coffee pot) and abuela's own cup stand at the right end of the table; her stool stands by the stove, inside the picture. Canelo lies by his empty bowl.
  async inicio35(){const taza=()=>[TENE("taza",13,16,{v:"leche"})];
    W.gente={abuelo:{x:SILLA[0],y:ASIENTO,sent:1,dir:1,tiene:[]},papa:{x:SILLA[3],y:ASIENTO,sent:1,dir:-1,tiene:[]},luis:{x:72,y:178,dir:1,tiene:taza()},carmen:{x:88,y:186,dir:1,tiene:taza()},abuela:{x:FOGON[0],y:FOGON[1],dir:-1,tiene:[]},mama:{vis:0,tiene:[]}};W.sitio={abuelo:0,papa:3};
    W.cosas=[{id:"taburete",k:"taburete",x:STOOL[0],y:STOOL[1]},{id:"t_abuelo",k:"taza",x:SILLA[0],y:FILA,v:"negro",vapor:1,vdy:19,vh:6},{id:"t_papa",k:"taza",x:SILLA[3],y:FILA,v:"negro",vapor:1,vdy:19,vh:6},{id:"tc_abuelo",k:"cucharilla",x:SILLA[0]-12,y:FILA-1},{id:"tc_papa",k:"cucharilla",x:SILLA[3]+12,y:FILA-1},
      {id:"t_luis",k:"taza",x:K1[0],y:K1[1],v:"leche",vapor:1,vdy:20,vh:5,vis:0},{id:"t_carmen",k:"taza",x:K2[0],y:K2[1],v:"leche",vapor:1,vdy:20,vh:5,vis:0},
      {id:"azucarera",k:"azucarera",x:AZU[0],y:AZU[1],spoons:8},{id:"t_rana",k:"taza",x:TRANA[0],y:TRANA[1],v:"vacia",vapor:0},{id:"t_abuela",k:"taza",x:TABU[0],y:TABU[1],v:"vacia",vapor:0,e:1},
      {id:"cafetera",k:"cafetera",x:CAFE35[0],y:CAFE35[1],vapor:1,vdx:-2,vdy:26,vn:1,vh:6},{id:"cazo",k:"cazo",v:"1",x:CAZO35[0],y:CAZO35[1]},{id:"jarrita",k:"jarrita",x:GRECA35[0],y:GRECA35[1]+4},{id:"tazon",k:"tazon",v:"0",x:TAZON[0],y:TAZON[1]}];
    W.perro={x:CANELO[0],y:CANELO[1],pose:"lie",dir:1};W.pote={};
    Object.assign(W.cq,{x:CASA35[0]-16,y:CASA35[1]-27,s:1,sobre:1,dy:0,vis:1,tiene:[],lleno:0,espalda:0,piensa:null,mal:0,nube:NUBE35,nubeAim:AIM35,ndir:1});},
  // the men take their cups in their hands and hold them out over the table, looking at the middle (where abuela and the frog are); or set them down
  async tienden35(o){await Promise.all(String(o.a).split(",").map(id=>{const t=copa(id),p=G(id);if(p.tiene.some(x=>x.k==="taza"||x.k==="tazacu"))return Promise.resolve();return toma(id,t,14,16,{n:3,m:3,vapor:0,extra:t.sp?{sp:t.sp}:{}}).then(it=>{it.v=t.v;it.vapor=0;if(t.sp)it.sp=t.sp;});}));await wait(TICK*2);},
  async bajan35(o){await Promise.all(String(o.a).split(",").map(async id=>{const p=G(id),it=p.tiene.find(x=>x.k==="taza"),t=copa(id);if(!it)return;it.k=it.sp?"tazacu":"taza";const x=t.x,y=t.y;t.v=it.v;await pon(id,it,t,x,y,3,{after:q=>{q.v=it.v;q.vapor=/vacia|azu/.test(it.v)?0:1;q.vh=6;if(it.sp)q.sp=1;}});}));await wait(TICK);},
  // abuela takes the big pot off the stove and walks behind the table to the empty chair between the two men
  async trae35(o){const ab=G("abuela"),ce=ob("cafetera");ab.dir=-1;ab.pose="idle";if(!ab.tiene.some(t=>t.k==="cafetera")){if(Math.abs(ab.x-AFOGON[0])>6||Math.abs(ab.y-AFOGON[1])>6)await ruta("abuela",[[AFOGON[0],AFOGON[1]]]);ab.dir=-1;await toma("abuela",ce,9,20,{n:3,m:3,vapor:0});}
    await detras("abuela",150,ATRAS);await mueve("abuela",126,ASIENTO-2);ab.dir=-1;},
  async vuelve35(o){const ab=G("abuela"),ce=ob("cafetera"),it=ab.tiene.find(t=>t.k==="cafetera"||t.k==="tiltcafetera");if(!it)return;it.k="cafetera";await delante("abuela",AFOGON[0],AFOGON[1]);ab.dir=-1;await pon("abuela",it,ce,CAFE35[0],CAFE35[1],4);ce.vapor=1;},
  // the frog fills a teaspoon at the sugar bowl: he takes the spoon that stands in it and dips it into the sugar
  async llena35(){await ranaCucharita();},
  // the frog brings the teaspoon of sugar to the cup of the one touched (mal: it already had its sugar: two heaps): the grains fall into it in view, he stirs, and the spoon stays standing in the cup
  async azucar35(o){const id=o.a,p=G(id),mal=+o.mal;if(mal)W.lista35=0;const pr=(async()=>{const q=W.cq;let sp=q.tiene.find(t=>t.k==="uten");if(!sp||sp.load!=="azu")sp=await ranaCucharita();
      const it=p.tiene.find(x=>x.k==="taza"||x.k==="tazacu"),d=D1(p),cxw=R(p.x)+d*it.dx,cyw=R(p.y)-it.dy;await azucarEn(cxw,cyw,sp,it,mal,id);if(!mal)it.k="tazacu";await ranaA(CASA35[0],CASA35[1]);})();return corre(o,pr);},
  // abuela pours coffee into a cup from the big pot she holds, from beside the man (mal: the last finger, into the same cup): the cup fills in two stages
  async cafe35(o){const id=o.a,t=copa(id),ab=G("abuela"),p=G(id);const pr=(async()=>{if(+o.mal){let n=0;while(!W.lista35&&n++<200)await wait(TICK);}   // she pours in the same move as the frog tips his spoon: she waits until he is at the cup with it
      const cup=p.tiene.find(x=>x.k==="taza"||x.k==="tazacu"),dd=D1(p),cxx=cup?R(p.x)+dd*cup.dx:t.x,left=cxx<ab.x,tx=cxx+(left?7:-7),ty=cup?R(p.y)-cup.dy-12:t.y-24;ab.dir=left?-1:1;
      const up=ab.tiene.find(x=>x.k==="cafetera"),tilt=await vierteA("abuela","cafetera","",tx,ty,!left,12,"#2A160C",[ab.y]);ab.tiene=ab.tiene.filter(x=>x!==up);ab.tiene.push(tilt);SFX.blip();
      if(cup){await wait(+o.dedo?TICK*4:TICK*6);if(!+o.mal&&+o.llena)cup.v="negro_";await wait(+o.dedo?TICK*4:TICK*8);if(+o.mal)cup.v="azu";else if(+o.llena){cup.v="negro";cup.vapor=0;}}else{await wait(TICK*10);if(+o.mal)t.v="azu";}
      ab.tiene=ab.tiene.filter(x=>x!==tilt);ab.tiene.push(up);await wait(TICK*2);})();return corre(o,pr);},
  async prueba35(o){for(const id of String(o.a).split(",")){const p=G(id);p.dy=-2;await wait(TICK*3);p.dy=0;await wait(TICK*3);p.dy=-2;await wait(TICK*3);p.dy=0;await wait(TICK*2);}},
  // the man looks at his cup (two heaps of sugar) and sets it down at his own place; he is cross and stays so while it stands in front of him
  async empuja35(o){const id=o.a,p=G(id),it=p.tiene.find(x=>x.k==="taza"||x.k==="tazacu"),t=copa(id),d=D1(p);await wait(TICK*5);p.cara="mal";SFX.bonk();await wait(TICK*6);
    if(it){it.vapor=0;it.v="azu";t.v="azu";t.vapor=0;const x=t.x,y=t.y;await pon(id,it,t,x,y,4,{after:q=>{q.v="azu";q.vapor=0;q.sp=1;}});}await wait(TICK*3);
    {const hb={k:"brazo",_m:7,gx:0,gy:0,sh:1},hand=()=>rel(id,t.x-d*9,t.y-7),rr=restHand(id);p.tiene.push(hb);const h1=hand();
      for(let i=1;i<=3;i++){hb.gx=rr[0]+(h1[0]-rr[0])*i/3;hb.gy=rr[1]+(h1[1]-rr[1])*i/3;await wait(TICK*2);}
      for(let i=0;i<4;i++){t.x+=d*3;t.y+=2;const h=hand();hb.gx=h[0];hb.gy=h[1];await wait(TICK*2);}   // the cup slides towards the middle of the table under his hand
      const h2=hand();for(let i=1;i<=3;i++){hb.gx=h2[0]+(rr[0]-h2[0])*i/3;hb.gy=h2[1]+(rr[1]-h2[1])*i/3;await wait(TICK*2);}p.tiene=p.tiene.filter(x=>x!==hb);}
    await wait(TICK*3);},
  // abuela gives the frog the little pot: she takes the greca from the right end of the table, carries it to him and sets it where he can take it; he takes it in his hand. The children set their cups of milk in front of the frog (ponen), walk out (salen), walk in (vuelven) and drink (toman)
  async pote35(o){const ab=G("abuela"),jt=ob("jarrita"),q=W.cq;
    await ruta("abuela",[[FOGON[0],FR],[GRECA35[0]+4,FR],[GRECA35[0]+4,190]]);ab.dir=-1;const it=await toma("abuela",jt,6,22,{n:3,m:3});it.flip=true;
    await ruta("abuela",[[GRECA35B[0]-10,190]]);ab.dir=-1;},   // she stops in front of the frog with the little pot in her hands: "Toma." and his thanks come now
  // then she sets it down for him, walks back to the stove, and the frog fetches the pot and takes it home
  async pote35b(o){const ab=G("abuela"),jt=ob("jarrita"),it=ab.tiene.find(t=>t.k==="jarrita");
    await pon("abuela",it,jt,GRECA35B[0],GRECA35B[1],4);await ruta("abuela",[[GRECA35B[0],FR],[FOGON[0],FR],[AFOGON[0],AFOGON[1]]]);ab.dir=-1;
    await ranaA(GRECA35B[0]-6,GRECA35B[1]-6);const gi=await ranaToma(jt,-14,14,{n:3,m:3});gi.flip=true;await ranaA(CASA35[0],CASA35[1]);},
  async ninos35(o){const l=G("luis"),ca=G("carmen"),tl=copa("luis"),tc=copa("carmen"),cupOf=p=>p.tiene.find(x=>x.k==="taza");
    const fresco=async(id,x,y)=>{const p=G(id),it=cupOf(p);if(it&&it.v==="vacia"){await sale(id);it.v="leche";it.vapor=0;await entra(id,x,y,1);}};   // a child with an empty cup walks out and comes back with a fresh cup of milk
    if(o.que==="ponen"){await Promise.all([(async()=>{await fresco("luis",72,178);const it=cupOf(l);await mueveTiene("luis",it,16,22,2);await pon("luis",it,tl,K1[0],K1[1],6,{after:q=>{q.v="leche";q.vapor=1;q.vh=5;}});await wait(TICK*3);})(),
        (async()=>{await wait(TICK*3);await fresco("carmen",88,186);await mueve("carmen",86,186);const it=cupOf(ca);await mueveTiene("carmen",it,16,22,2);await pon("carmen",it,tc,K2[0],K2[1],6,{after:q=>{q.v="leche";q.vapor=1;q.vh=5;}});await wait(TICK*3);})()]);}
    else if(o.que==="salen"){await Promise.all([sale("luis"),(async()=>{await wait(TICK*3);await sale("carmen");})()]);}
    else if(o.que==="vuelven"){await Promise.all([entra("luis",72,178,1),(async()=>{await wait(TICK*3);await entra("carmen",88,186,1);})()]);}
    else if(o.que==="toman"){const pr=(async()=>{const drink=async(id,t)=>{const p=G(id),it=await toma(id,t,13,16,{n:3,m:3,vapor:0});it.v=t.v;it.vapor=0;const base=String(t.v).replace(/_$/,"");await sorbos(id,it,[mitad(base),"vacia"],13,16);};   // he keeps the empty cup in his hand
        await Promise.all([drink("luis",tl),(async()=>{await wait(TICK*4);await drink("carmen",tc);})()]);})();return corre(o,pr);}
    else if(o.que==="dejan"){await Promise.all([["luis",tl,K1],["carmen",tc,K2]].map(async([id,t,k],i)=>{await wait(TICK*3*i);const it=cupOf(G(id));if(!it)return;await pon(id,it,t,k[0],k[1],4,{after:q=>{q.v=it.v;q.vapor=0;}});}));}},
  // the frog pours as told from the greca in his hand: a long pour (mucho) turns the milk brown; a splash (poco) turns it pale
  async vierte35(o){const id=o.a,t=copa(id),q=W.cq,mucho=o.cant==="mucho",izq=t.x<90;const fx=izq?98:92,fy=148;await ranaA(fx,fy);
    const jt=q.tiene.find(i=>i.k==="jarrita"),up=jt;const tilt=vierteItem("rana","jarrita","",t.x,t.y-22,!izq,12,"#3E2414");q.tiene=q.tiene.filter(i=>i!==jt);q.tiene.push(tilt);SFX.blip();
    await wait(mucho?TICK*4:TICK*2);liq(id,"palido",1);if(mucho){await wait(TICK*10);liq(id,"marron",1);await wait(TICK*6);}else await wait(TICK*4);
    q.tiene=q.tiene.filter(i=>i!==tilt);q.tiene.push(Object.assign(up,{flip:true}));await wait(TICK*2);await ranaA(CASA35[0],CASA35[1]);},
  // the frog's own cup, the thoughts and answers of step 6
  async piensa35(o){const CO={poco:"palido",mucho:"marron"};W.cq.piensa=o.k?{k:"taza",v:CO[o.k]||o.k,e:1}:null;if(o.k)SFX.blip();await wait(TICK*4);},
  // abuela pours for the frog: the frog sets the little pot down beside his cup; abuela takes the little pot from beside his cup, pours a stream of coffee from it into his cup, sets it down; then, with her hands empty, she goes for the milk pan and pours the milk (a white stream); one pot at a time
  async sirve6(o){const mucho=o.cant==="mucho",q=W.cq,ab=G("abuela"),t=copa("rana"),cz=ob("cazo"),pote=ob("jarrita");q.piensa=null;
    const jt=q.tiene.find(i=>i.k==="jarrita");if(jt){await ranaA(TRANA[0]+16,TRANA[1]-2);await ranaPon(jt,pote,TRANA[0]+16,TRANA[1]+2,3);await ranaA(CASA35[0],CASA35[1]);}
    await ruta("abuela",[[FOGON[0],FR],[TRANA[0]+26,FR],[TRANA[0]+26,190]]);ab.dir=-1;const gr=await toma("abuela",pote,-9,20,{n:3,m:3});gr.flip=false;
    const pot=await vierteA("abuela","jarrita","",t.x,t.y-24,false,14,"#2A160C");ab.tiene=ab.tiene.filter(x=>x!==gr);ab.tiene.push(pot);SFX.blip();await wait(TICK*3);liq("rana",mucho?"negro_":"negro_",1);await wait(mucho?TICK*8:TICK*3);liq("rana","negro",1);await wait(mucho?TICK*3:TICK*2);
    ab.tiene=ab.tiene.filter(x=>x!==pot);ab.tiene.push(gr);await wait(TICK*2);await pon("abuela",gr,pote,TRANA[0]+16,TRANA[1]+2,3);
    await ruta("abuela",[[TRANA[0]+26,FR],[FOGON[0],FR],[AFOGON[0],AFOGON[1]],[CAZO35[0]-4,150]]);ab.dir=-1;const pan=await toma("abuela",cz,8,18,{n:3,m:3});
    await ruta("abuela",[[AFOGON[0],AFOGON[1]],[FOGON[0],FR],[TRANA[0]+26,FR],[TRANA[0]+26,190]]);ab.dir=-1;
    const mi=await vierteA("abuela","cazo","1",t.x,t.y-24,false,14,"#FBFBF4");ab.tiene=ab.tiene.filter(x=>x!==pan);ab.tiene.push(mi);SFX.blip();await wait(TICK*4);liq("rana","marron",1);await wait(mucho?TICK*7:TICK*3);liq("rana",mucho?"marron":"palido",1);await wait(mucho?TICK*3:TICK*12);
    ab.tiene=ab.tiene.filter(x=>x!==mi);ab.tiene.push(pan);await ruta("abuela",[[TRANA[0]+26,FR],[FOGON[0],FR],[AFOGON[0],AFOGON[1]]]);ab.dir=-1;await mueve("abuela",CAZO35[0]-4,150);ab.dir=-1;await pon("abuela",pan,cz,CAZO35[0],CAZO35[1],4);SFX.blip();},
  // the frog drinks his own cup: he takes it in his hand, lifts it, sips (it is half empty), sips again (empty), and sets it down
  async rana35bebe(o){const q=W.cq,t=copa("rana");await ranaA(TRANA[0]-14,TRANA[1]-2);const v=t.v,it=await ranaToma(t,-4,14,{n:3,m:3});it.vapor=0;
    for(const nv of [mitad(v),"vacia"]){await wait(TICK*2);q.hace="bebe";it.ang=.35;await wait(TICK*5);it.v=nv;it.ang=0;q.hace=null;await wait(TICK*4);}
    await ranaPon(it,t,TRANA[0],TRANA[1],3);t.v="vacia";t.vapor=0;await ranaA(CASA35[0],CASA35[1]);},
  // the turn: the cups are empty; abuela pours the last of the big pot (a half cup each for abuelo, papá and herself); she brings the sugar bowl to each man, who takes a spoon from it himself, sweetens his own half cup and nods; the last milk into the children's cups; the little pot, full, goes back to the right end of the table
  async turno35(o){const ab=G("abuela"),ce=ob("cafetera"),cz=ob("cazo"),tab=copa("abuela"),az=ob("azucarera");
    ["abuelo","papa","rana"].forEach(id=>{liq(id,"vacia",0);});
    await Promise.all(["abuelo","papa"].map(async(id,i)=>{await wait(TICK*i*4);if(copa(id).sp)await dejaCuchara(id);}));   // each man lays his teaspoon down by his cup
    await Promise.all([sale("luis"),(async()=>{await wait(TICK*3);await sale("carmen");})()]);   // with their empty cups
    await acts.trae35({});
    await acts.tienden35({a:"abuelo,papa"});for(const id of ["abuelo","papa"]){await acts.cafe35({a:id,dedo:0,llena:1});}await acts.bajan35({a:"abuelo,papa"});
    // her own cup, at the right end of the table, from the pot too (she stands in front of the table's end)
    await delante("abuela",198,176);ab.dir=-1;{const up=ab.tiene.find(x=>x.k==="cafetera"),tilt=await vierteA("abuela","cafetera","",tab.x+7,tab.y-24,false,12,"#2A160C");ab.tiene=ab.tiene.filter(x=>x!==up);ab.tiene.push(tilt);SFX.blip();await wait(TICK*5);liq("abuela","negro_",1);await wait(TICK*5);liq("abuela","negro",1);ab.tiene=ab.tiene.filter(x=>x!==tilt);ab.tiene.push(up);await wait(TICK*2);}
    await mueve("abuela",AFOGON[0],AFOGON[1]);ab.dir=-1;{const it=ab.tiene.find(x=>x.k==="cafetera");await pon("abuela",it,ce,CAFE35[0],CAFE35[1],4);}W.pote.dedo=1;
    // the sugar: she takes the bowl to the men, behind the table; each takes a spoon from it, sweetens his cup, tastes and nods
    await ruta("abuela",[[FOGON[0],FR],[AZU[0]+4,FR],[AZU[0]+4,188]]);ab.dir=-1;const bowl=await toma("abuela",az,9,26,{n:3,m:3});
    await ruta("abuela",[[196,FR-8]]);await detras("abuela",128,ATRAS);ab.dir=-1;
    const bw=()=>[R(ab.x)+D1(ab)*bowl.dx+5,R(ab.y)-bowl.dy-8];
    const hombre=async id=>{const p=G(id),t=copa(id);const b=bw(),r0=rel(id,b[0],b[1]);await manoA(id,r0[0],r0[1],3);bowl.v="0";SFX.blip();sinManos(id);
        const sp={k:"uten",ax:r0[0],ay:r0[1],bx:r0[0]+6,by:r0[1]+2,load:"azu",o:{plata:1,rx:1,ry:1}};p.tiene.push(sp);await wait(TICK*3);
        await cucharaA(id,sp,t.x,t.y-14,5);await wait(TICK*3);sp.load="";await granosCaen(t.x,t.y-2);{const base=t.v;t.v=base+"+";await wait(TICK*5);t.v=base;}
        {const b2=bw();await cucharaA(id,sp,b2[0]-3,b2[1]-8,4);}   // the big spoon goes back into the bowl, in his hand
        p.tiene=p.tiene.filter(x=>x!==sp);bowl.v=undefined;SFX.blip();const rr=restHand(id);await manoA(id,rr[0],rr[1],3);sinManos(id);await wait(TICK*2);
        await acts.tienden35({a:id});await revuelve(id);const it=p.tiene.find(x=>x.k==="taza"||x.k==="tazacu");await mueveTiene(id,it,12,bocaY(id,p)-2,3);await wait(TICK*4);p.dy=-2;await wait(TICK*3);p.dy=0;await wait(TICK*3);p.dy=-2;await wait(TICK*3);p.dy=0;await wait(TICK*2);await acts.bajan35({a:id});};
    await hombre("abuelo");
    await ruta("abuela",[[176,ATRAS]]);ab.dir=-1;await hombre("papa");
    // the bowl goes back to its place on the table, in front
    await delante("abuela",AZU[0]+4,188);ab.dir=-1;await pon("abuela",bowl,az,AZU[0],AZU[1],4);az.tomada=0;
    await Promise.all([entra("luis",72,178,1),(async()=>{await wait(TICK*3);await entra("carmen",88,186,1);})()]);await acts.ninos35({que:"dejan"});
    // the milk into the children's cups (they stand there with their hands empty)
    await ruta("abuela",[[AZU[0]+4,FR-8],[FOGON[0],FR],[AFOGON[0],AFOGON[1]]]);ab.dir=-1;await mueve("abuela",CAZO35[0]-4,150);ab.dir=-1;const pan=await toma("abuela",cz,8,18,{n:3,m:3});
    await ruta("abuela",[[FOGON[0],FR],[130,FR]]);ab.dir=-1;
    for(const [id,cup] of [["carmen",K2],["luis",K1]]){const pn=ab.tiene.find(x=>x.k==="cazo");ab.dir=-1;const mi=await vierteA("abuela","cazo","1",cup[0],cup[1]-24,false,14,"#FBFBF4");ab.tiene=ab.tiene.filter(x=>x!==pn);ab.tiene.push(mi);SFX.blip();await wait(TICK*4);liq(id,"leche",1);await wait(TICK*5);ab.tiene=ab.tiene.filter(x=>x!==mi);ab.tiene.push(pn);await wait(TICK*2);}
    W.pote.leche=1;
    // the pan goes back on the stove, the little pot, full, goes back to the right end of the table
    await ruta("abuela",[[FOGON[0],FR],[AFOGON[0],AFOGON[1]]]);ab.dir=-1;{const pn=ab.tiene.find(x=>x.k==="cazo");await mueve("abuela",CAZO35[0]-4,150);ab.dir=-1;await pon("abuela",pn,cz,CAZO35[0],CAZO35[1],4);cz.v="1";}
    await ruta("abuela",[[FOGON[0],FR],[TRANA[0]+26,FR],[TRANA[0]+26,190]]);ab.dir=-1;{const jp=ob("jarrita");if(jp.vis!==0&&jp.x>140&&jp.x<190){const it=await toma("abuela",jp,6,22,{n:3,m:3});it.flip=true;await ruta("abuela",[[GRECA35[0]+4,190]]);await pon("abuela",it,jp,GRECA35[0],GRECA35[1]+4,4);}}
    await mueve("luis",72,178);await mueve("carmen",88,186);},
  // she takes her own cup (from the table's end, or from the stool where it stands while she is up), walks to her stool and sits down with it
  async sientaAb35(o){const ab=G("abuela"),t=copa("abuela"),enBanco=Math.abs(t.x-STOOL[0])<4;
    if(!ab.tiene.some(x=>x.k==="taza")){
      if(enBanco){await ruta("abuela",[[STOOL[0]-16,STOOL[1]+8]]);ab.dir=1;}else{await ruta("abuela",[[TABU[0]+12,FR-8],[TABU[0]+12,178]]);ab.dir=-1;}
      const it=await toma("abuela",t,enBanco?-8:8,22,{n:3,m:3,vapor:0});it.v=t.v;it.vapor=0;}
    await ruta("abuela",[[STOOL[0]-8,STOOL[1]+10],[STOOL[0],STOOL[1]+8]]);ab.dir=-1;{const it=ab.tiene.find(x=>x.k==="taza");await mueveTiene("abuela",it,15,18,2);}ab.sent=1;ab.taburete=1;ab.y=STOOL[1]-4;ab.x=STOOL[0];SFX.blip();await wait(TICK*3);},
  // she gets up, sets her cup on the stool beside her (it stays with her), and goes for the pot
  async levantaAb35(){const ab=G("abuela"),t=copa("abuela"),cup=ab.tiene.find(x=>x.k==="taza");ab.sent=0;ab.taburete=0;ab.y=STOOL[1]+4;ab.x=STOOL[0]-14;ab.dir=-1;SFX.blip();await wait(TICK*3);
    if(cup){ab.dir=1;await pon("abuela",cup,t,STOOL[0],STOOL[1]-11,4,{after:q=>{q.v=cup.v;q.vapor=0;q.vis=1;}});ab.dir=-1;}await wait(TICK*2);},
  // round A: abuela gets up from her stool and takes the big pot with its last pour; the men hold their half cups out, looking at her
  async turnoA35(o){const ab=G("abuela"),ce=ob("cafetera");await acts.levantaAb35();
    await ruta("abuela",[[AFOGON[0],AFOGON[1]+8],[AFOGON[0],AFOGON[1]]]);ab.dir=-1;await toma("abuela",ce,9,20,{n:3,m:3,vapor:0});
    await detras("abuela",150,ATRAS);await mueve("abuela",126,ASIENTO-2);ab.dir=-1;await acts.tienden35({a:"abuelo,papa"});await acts.llena35();},
  // after A: abuela puts the empty big pot on the stove, takes the little pot from the right end of the table and sets it by the frog's cup; he stands it by his small cup; she goes back to her cup and sits
  async despuesA35(o){const ab=G("abuela"),jt=ob("jarrita"),ce=ob("cafetera"),q=W.cq;await acts.bajan35({a:"abuelo,papa"});ce.v="";
    await acts.vuelve35({});
    await ruta("abuela",[[FOGON[0],FR],[GRECA35[0]+4,FR],[GRECA35[0]+4,190]]);ab.dir=-1;const it=await toma("abuela",jt,6,22,{n:3,m:3});it.flip=true;
    await ruta("abuela",[[TRANA[0]+26,190]]);ab.dir=-1;await pon("abuela",it,jt,TRANA[0]+16,TRANA[1]+2,4);
    await acts.sientaAb35({});},
  // abuela asks the frog: she gets up, takes the little pot from beside his cup and holds it out to him, looking at him (the thought over him is his own wish)
  async pregunta35(o){const ab=G("abuela"),jt=ob("jarrita");await acts.levantaAb35();
    await ruta("abuela",[[STOOL[0]-16,FR-8],[TRANA[0]+26,FR-8],[TRANA[0]+26,190]]);ab.dir=-1;const gr=await toma("abuela",jt,-9,22,{n:3,m:3});gr.flip=false;await wait(TICK*3);},
  // round B: abuela pours from the little pot what he said into his cup, tips what is left of it into her own cup (on her stool), fills his cup to the brim with milk from the pan (a white stream); whatever is left in the pan she tips into Canelo's bowl, and Canelo gets up, laps it and lies down again
  async sirveB35(o){const ab=G("abuela"),mucho=String(o.cant).replace(/^di_/,"")==="mucho",cz=ob("cazo"),tz=ob("tazon"),pe=W.perro,t=copa("rana"),ta=copa("abuela"),q=W.cq;q.piensa=null;
    if(W.pote&&W.pote.pan)return;   // after a miss the same act comes round again with the right answer: everything is poured already, nothing more is poured
    let gr=ab.tiene.find(x=>x.k==="jarrita");ab.dir=-1;
    const pot=await vierteA("abuela","jarrita","",t.x,t.y-24,false,14,"#2A160C");ab.tiene=ab.tiene.filter(x=>x!==gr);ab.tiene.push(pot);SFX.blip();await wait(TICK*3);liq("rana","negro_",1);await wait(mucho?TICK*8:TICK*3);liq("rana","negro",1);await wait(mucho?TICK*3:TICK*2);ab.tiene=ab.tiene.filter(x=>x!==pot);ab.tiene.push(gr);await wait(TICK*2);
    // what is left of the little pot goes into her own cup, which stands on her stool
    await ruta("abuela",[[TRANA[0]+26,FR-8],[STOOL[0]-18,FR-8],[STOOL[0]-18,STOOL[1]+8]]);ab.dir=1;{const pot2=await vierteA("abuela","jarrita","",ta.x,ta.y-24,true,14,"#2A160C",[STOOL[1]+8,STOOL[1]+12]);ab.tiene=ab.tiene.filter(x=>x!==gr);ab.tiene.push(pot2);SFX.blip();await wait(TICK*4);ta.v="negro_";await wait(TICK*4);ta.v="negro";ab.tiene=ab.tiene.filter(x=>x!==pot2);ab.tiene.push(gr);await wait(TICK*2);}
    await ruta("abuela",[[STOOL[0]-18,FR-8],[GRECA35[0]+4,FR-8],[GRECA35[0]+4,190]]);ab.dir=-1;{const jt=ob("jarrita");await pon("abuela",gr,jt,GRECA35[0],GRECA35[1]+4,4);}
    await ruta("abuela",[[GRECA35[0]+4,FR],[FOGON[0],FR],[AFOGON[0],AFOGON[1]],[CAZO35[0]-4,150]]);ab.dir=-1;const pan=await toma("abuela",cz,8,18,{n:3,m:3});
    await ruta("abuela",[[AFOGON[0],AFOGON[1]],[FOGON[0],FR],[TRANA[0]+26,FR],[TRANA[0]+26,190]]);ab.dir=-1;
    {const mi=await vierteA("abuela","cazo","1",t.x,t.y-24,false,14,"#FBFBF4");ab.tiene=ab.tiene.filter(x=>x!==pan);ab.tiene.push(mi);SFX.blip();await wait(TICK*4);liq("rana",mucho?"marron":"palido",1);await wait(mucho?TICK*7:TICK*14);ab.tiene=ab.tiene.filter(x=>x!==mi);ab.tiene.push(pan);await wait(TICK*2);}
    // the rest of the milk into Canelo's bowl, and Canelo gets up, laps for a while and lies down again
    await ruta("abuela",[[TAZON[0]+18,FR]]);ab.dir=-1;{const mi2=await vierteA("abuela","cazo","1",TAZON[0],TAZON[1]-26,false,18,"#FBFBF4");ab.tiene=ab.tiene.filter(x=>x!==pan);ab.tiene.push(mi2);SFX.blip();await wait(TICK*7);tz.v="1";ab.tiene=ab.tiene.filter(x=>x!==mi2);pan.v="0";ab.tiene.push(pan);}
    pe.pose="sit";await wait(TICK*7);pe.pose="walk";pe.dir=1;await wait(TICK*3);while(pe.x<TAZON[0]-20){pe.x=Math.min(TAZON[0]-20,pe.x+3);await wait(TICK);}   // he gets up over several frames (lying, sitting, standing, walking) and walks to the bowl
    pe.pose="husmea";for(const nv of ["1","2","0"]){pe.lengua=1;await wait(TICK*3);pe.lengua=0;await wait(TICK*2);tz.v=nv;await wait(TICK*2);}
    pe.pose="walk";pe.dir=-1;while(pe.x>CANELO[0]){pe.x=Math.max(CANELO[0],pe.x-3);await wait(TICK);}pe.dir=1;pe.pose="sit";await wait(TICK*4);pe.pose="lie";pe.x=CANELO[0];pe.y=CANELO[1];await wait(TICK*2);
    await ruta("abuela",[[FOGON[0],FR],[AFOGON[0],AFOGON[1]]]);ab.dir=-1;await mueve("abuela",CAZO35[0]-4,150);ab.dir=-1;await pon("abuela",pan,cz,CAZO35[0],CAZO35[1],4);cz.v="0";W.pote.vacia=1;W.pote.pan=1;},
  // the frog tastes his cup once: he takes it, lifts it, tips it, makes a plain sour face (a big one) and puts the cup down by him, full to the brim and the wrong colour; the face stays sour while it stands there
  async pruebaB35(o){const q=W.cq,t=copa("rana");await ranaA(TRANA[0]-14,TRANA[1]-2);const it=await ranaToma(t,-4,14,{n:3,m:3});it.vapor=0;await wait(TICK*2);q.hace="come";it.ang=.35;await wait(TICK*7);q.hace=null;it.ang=0;q.mal=1;SFX.bonk();await wait(TICK*5);await ranaPon(it,t,TRANA[0],TRANA[1],3);await wait(TICK*3);await ranaA(CASA35[0],CASA35[1]);},
  // after a miss in B: abuela takes her own cup off her stool and drinks it off in view (sip after sip), a big pleased "ah", a hand on her chest; then she holds the empty cup up
  async bebeAb35(o){const ab=G("abuela"),t=copa("abuela"),q=W.cq;q.mal=0;await ruta("abuela",[[STOOL[0]-18,FR-8],[STOOL[0]-18,STOOL[1]+8]]);ab.dir=1;const it=await toma("abuela",t,-8,22,{n:3,m:3,vapor:0});it.v="negro";it.vapor=0;await mueveTiene("abuela",it,12,20,3);
    await sorbos("abuela",it,["negro_","vacia"],12,20);ab.abre=1;ab.pose="bless";SFX.blip();await wait(TICK*8);ab.abre=0;await wait(TICK*3);ab.pose="idle";
    await mueveTiene("abuela",it,10,34,3);await wait(TICK*8);},
  // she shows what is empty: the cup she holds up, then the little pot and the pan (she walks to each, takes it, tips it towards us for a moment), and sets each back
  async muestra35(o){const ab=G("abuela"),k=o.k;const cup=ab.tiene.find(x=>x.k==="taza");
    if(k==="taza"){if(cup){ab.dir=1;await mueveTiene("abuela",cup,12,38,3);await wait(TICK*8);}return;}
    if(cup){const t=copa("abuela");ab.dir=1;await pon("abuela",cup,t,STOOL[0],STOOL[1]-11,4,{after:q=>{q.v="vacia";q.vapor=0;q.vis=1;}});}
    const mostrar=async(ob_,x,y,v)=>{await ruta("abuela",[[x-4,FR-8],[x-4,y]]);ab.dir=-1;const it=await toma("abuela",ob_,-9,22,{n:3,m:3});it.flip=false;if(v!=null)it.v=v;await mueveTiene("abuela",it,-4,34,3);it.ang=-.8;await wait(TICK*10);it.ang=0;await mueveTiene("abuela",it,-9,22,3);await pon("abuela",it,ob_,ob_.x,ob_.y,3);};
    if(k==="jarrita"){const jt=ob("jarrita");await mostrar(jt,jt.x+4,190);}
    else{const cz=ob("cazo");await ruta("abuela",[[FOGON[0],FR],[AFOGON[0],AFOGON[1]],[CAZO35[0]-4,150]]);ab.dir=-1;const it=await toma("abuela",cz,8,18,{n:3,m:3});it.v="0";await mueveTiene("abuela",it,-2,32,3);it.ang=-.8;await wait(TICK*10);it.ang=0;await mueveTiene("abuela",it,8,18,3);await pon("abuela",it,cz,CAZO35[0],CAZO35[1],4);cz.v="0";}},
  // the ending: everybody drinks (they lift their cups, sip, set them down); a spoiled cup stands in front of its owner; abuela drinks at her stool
  async final35(o){const ab=G("abuela");if(!ab.sent)await acts.sientaAb35({});   // after a miss in B she has been walking about: she sits down on her stool with her cup
    await Promise.all([entra("luis",72,178,1),(async()=>{await wait(TICK*3);await entra("carmen",88,186,1);})()].slice(0,G("luis").vis===0?2:0));
    const ninos=acts.ninos35({que:"toman"});
    const men=Promise.all(["abuelo","papa"].map(async id=>{const t=copa(id),p=G(id);if(t.v==="azu"||t.vis===0)return;const it=await toma(id,t,13,16,{n:3,m:3,vapor:0});it.v=t.v;it.vapor=0;if(t.sp){it.sp=1;it.k="tazacu";}
      await sorbos(id,it,[mitad(t.v),"vacia"],13,16);await pon(id,it,t,t.x,t.y,3,{after:q=>{q.v="vacia";q.vapor=0;q.sp=1;}});}));
    const cup=ab.tiene.find(x=>x.k==="taza");V.cafe=cup?(cup.v!=="vacia"?"1":""):(copa("abuela").v!=="vacia"?"1":"");
    if(ab.sent&&cup&&V.cafe){await wait(TICK*6);await sorbos("abuela",cup,[mitad(cup.v),"vacia"],15,18);}
    await men;await ninos;W.cq.hace=null;await wait(TICK*6);},

  // everything at once, to look at the drawing
  async prueba(o){W.gente={};W.cosas=[];}
};
async function stake(lost,max,en){await wait(200);}
function poke(what){}
const estado=W=>{const C=W.cosas||[],f=C.find(o=>o.id==="fuente"),ce=C.find(o=>o.id==="cesta"),tb=C.find(o=>o.id==="tabla");return "gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)+(W.gente[k].sent?"s":"")+((W.gente[k].tiene||[]).length?"^"+W.gente[k].tiene.map(t=>t.k).join("+"):"")+(W.gente[k].come?"("+W.gente[k].come.k+")":"")).join(" ")
  +" cesta="+(ce?ce.v:"-")+" fuente="+(f?f.montones.filter(m=>m.g==="m").length+"m"+f.montones.filter(m=>m.g==="p").length+"p":"-")+" platos="+C.filter(o=>o.k==="plato"||o.k==="platoc").map(o=>o.id.slice(3)+":"+(o.v||"")+"/"+(o.rollos||[]).map(r=>(r.mal?"ma":r.st)+(r.con||"")).join("+")).concat(["abuela"].filter(k=>W.gente&&W.gente[k]).map(k=>{const pt=(W.gente[k].tiene||[]).find(t=>t.k==="plato");return pt?"ab_en_mano:"+(pt.v||"")+"/"+(pt.rollos||[]).map(r=>(r.mal?"ma":r.st)+(r.con||"")).join("+"):"ab_en_mano:/";})).join("|")
  +" tabla="+(tb&&tb.rollo?tb.rollo.st+(tb.rollo.con||""):"-")+" malos="+(tb&&tb.malos?tb.malos.length:0)+" mant="+((C.find(o=>o.id==="mant")||{}).v||"-")+" choc="+((C.find(o=>o.id==="choc")||{}).v||"-")
  +" tazas="+C.filter(o=>o.k==="taza").map(o=>o.id.slice(2)+":"+o.v+(o.vapor?"*":"")+(o.vis===0?"^":"")).join("|")+" pmont="+V.pmont+" marcas="+(W.marcas||[]).join(",");};
KIT.escena({id:"comer",CAM:{wide:[32,0,196,216]},heartAt:[130,22],lugar:{inicio:[124,141,1],centro:[124,141,1]},cosas:COSAS,
  fresh:()=>({respEn:[130,22],gente:{},sitio:{},cosas:[],vuelos:[],perro:null,tarjeta:null,marcas:null,cq:{x:108,y:141,s:1,dy:0,al:1,vis:1,sobre:1,bub:null,hace:null,piensa:null,tiene:[]}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
