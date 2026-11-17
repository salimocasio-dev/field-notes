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
const PISO=142,MESA=[66,112,120,60],SILLA=[90,114,138,162],MOSTR=[24,106,52,12],ESTUFA=[190,108,38,38],ESTANTE=[194,96,28];   // the floor; the table top (x, y of its far edge, width, depth); the four chairs; the counter top; the stove; the shelf over the stove
const FILA=127,MED=148,FREN=170,TZ=173,ASIENTO=132,ATRAS=140;   // the rows of the table top; where somebody sitting has his feet; the lane behind the table
const LE=[64,180],CAR=[44,190],FOGON=[208,158],DER=[208,176],PUERTA=[18,184];   // the left end of the table, where he who comes in stands; Carmen beside him; abuela at the stove; the right end; the door (out of the picture)
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,abuelo:FAM.abuelo,mama:FAM.mama,papa:FAM.papa,abuela:{}};
const PLATO=["#2A5C9C","#4A86C8","#8CB8E8"];   // the plates are blue: nothing white is lost on them
const TAN=["#A8682C","#C8853C","#E2A85A"],CHOC=["#2A1408","#5A2E14","#8A5A34"],MANT="#FFE070",ARROZ=["#C88A10","#F2C028","#FFE870"];
const CERA=["#7A8AB8","#C4D0F0","#FFFFFF"];   // the white-blue china of the bowls
const LIQ={negro:"#1A0C06",marron:"#7A4A28",palido:"#D9B77F",leche:"#FBFBF4",vacia:"#B4BCD0",azu:"#1A0C06"};   // what is in a cup, seen from above

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),Wd=RP.wood,M=MOSTR,E=ESTUFA;
  for(let y=0;y<PISO;y++)for(let x=0;x<SW;x++)b.px(x,y,y>PISO-5?"#C8B88A":hs(x>>2,y>>2)<6?"#F0E4B8":"#F6ECC4");
  for(let y=84;y<M[1];y++)for(let x=22;x<76;x++)b.px(x,y,(x%8===0||y%8===4)?"#B8D0D8":"#E4F0F4");
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
  b.rect(M[0]+24,M[1]+M[3]+3,2,20,Wd[0]);[M[0]+20,M[0]+30].forEach(x=>b.rect(x,M[1]+M[3]+9,2,5,"#F0C020"));
  b.rect(M[0]-2,M[1],M[2]+4,M[3],"#E8E8F0");b.rect(M[0]-2,M[1],M[2]+4,2,"#FFFFFF");b.rect(M[0]-2,M[1]+M[3]-2,M[2]+4,2,"#B8B8C8");b.frame(M[0]-3,M[1]-1,M[2]+6,M[3]+2,OUT);
  b.rect(54,M[1]+2,18,8,"#8A8EA0");b.rect(55,M[1]+3,16,6,"#C8CCDA");b.rect(55,M[1]+3,16,1,"#6A6E80");b.rect(62,M[1]-8,2,9,"#8A8EA0");b.rect(62,M[1]-9,6,2,"#8A8EA0");
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
  if(v==="1"){b.ell(12,13,8,5.4,["#B87A10","#E0A020","#F8C838"]);b.ell(12,7,5.6,5.6,RP.skin.slice(2));const S=KIT.PIEL.a;b.px(10,6,"#20140A");b.px(14,6,"#20140A");b.px(9,8,"#E08A70");b.px(15,8,"#E08A70");b.rect(11,9,3,1,"#7A2A1A");b.px(12,0,KIT.PELO.castano[2]);b.px(13,1,KIT.PELO.castano[2]);b.px(11,1,KIT.PELO.castano[2]);}
  b.rect(0,19,24,3,"#8CB8E8");b.rect(0,19,24,1,"#D8E8FA");   // the tray
  return b.outline().done();}

/* ---------- sprites ---------- */
const borra=(b,cx,cy,r)=>{for(let y=Math.floor(cy-r);y<=Math.ceil(cy+r);y++)for(let x=Math.floor(cx-r);x<=Math.ceil(cx+r);x++)if(x>=0&&y>=0&&x<b.w&&y<b.h&&(x+.5-cx)*(x+.5-cx)+(y+.5-cy)*(y+.5-cy)<=r*r)b.d[(y*b.w+x)*4+3]=0;};
// a copy turned by ang (radians, clockwise on the screen), nearest pixels, so it stays crisp; pico: a point of it (the lip of a pot) turned with it
function giro(cv,ang,pico){const w=cv.width,h=cv.height,r=Math.ceil(Math.hypot(w,h)),b=new Buf(r,r),sc=cv.getContext("2d").getImageData(0,0,w,h).data,cs=Math.cos(ang),sn=Math.sin(ang),cx=w/2,cy=h/2,ox=r/2,oy=r/2;
  for(let y=0;y<r;y++)for(let x=0;x<r;x++){const dx=x+.5-ox,dy=y+.5-oy,sx=Math.floor(dx*cs+dy*sn+cx),sy=Math.floor(-dx*sn+dy*cs+cy);if(sx<0||sy<0||sx>=w||sy>=h)continue;const i=(sy*w+sx)*4;if(sc[i+3]>0)b.px(x,y,"#"+[0,1,2].map(k=>sc[i+k].toString(16).padStart(2,"0")).join(""));}
  const out=b.done();if(pico){const dx=pico[0]-cx,dy=pico[1]-cy;out.pico=[ox+dx*cs-dy*sn,oy+dx*sn+dy*cs];}return out;}
function bola(b,x,y,rx,ry,col){b.ell(x,y,rx,ry,col);}
function rollitos(b,x,yb){   // a small split roll in the basket: its foot at (x,yb), with its own dark edge so the rolls can be counted
  b.ell(x,yb-3.6,7,4.6,[OUT]);b.ell(x,yb-3.6,6,3.8,TAN);b.rect(x-5,yb-4,10,1,"#FFF0C8");b.rect(x-4,yb-3,8,1,"#8A5A18");b.px(x-3,yb-6,"#F4CC88");b.px(x-2,yb-6,"#F4CC88");}
// a wedge of cake at (x0,y0), k its size: frosting white on top (a triangle), then sponge, jam, sponge down its front, a cherry
function tajada(b,x0,y0,k){k=k||1;const X=v=>Math.round(x0+v*k),Y=v=>Math.round(y0+v*k),W=Math.max(1,Math.round(14*k));
  for(let r=0;r<5;r++){const a=X(1+r*2),e=X(15),yy=Y(1+r);for(let x=a;x<=e;x++)b.px(x,yy,r===0?"#FFFFFF":"#FFF4E0");if(k>.8)b.px(e,yy,"#E8D8C0");}
  const fy=Y(6);for(let y=fy;y<fy+Math.max(2,Math.round(2*k));y++)for(let x=X(5);x<=X(15);x++)b.px(x,y,"#E8B050");
  for(let x=X(5);x<=X(15);x++)b.px(x,fy+Math.max(2,Math.round(2*k)),"#C8302A");
  const sy=fy+Math.max(3,Math.round(3*k));for(let y=sy;y<sy+Math.max(2,Math.round(3*k));y++)for(let x=X(5);x<=X(15);x++)b.px(x,y,"#D89A3C");
  b.px(X(11),Y(0),"#D0302A");b.px(X(12),Y(0),"#D0302A");b.px(X(11),Y(-1),"#48A848");}
const COSA={
  // a blue plate; v: what lies on it. "r" rice, "o" a mound, "rm" rice and a mound, "h" a mound mixed into the rice (a heap), "mi" crumbs, "p1".."p3" mounds
  plato(v){const b=new Buf(26,12);b.ell(13,6.8,12.6,4.8,PLATO);b.ell(13,6.2,9,3.2,["#6AA0DC","#A8CCF0"]);v=v||"";
    if(v==="r"||v==="rm"||v==="h"){b.ell(13,6,8.4,3,["#C88A10","#F2C028","#FFE060"]);[[8,5],[11,6],[15,5],[17,6],[10,7],[13,4]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    if(v==="rm"||v==="o"){b.ell(13,4.2,4.8,3.6,ARROZ);b.px(11,2,"#FFF4B0");b.px(14,3,"#FFF4B0");b.px(15,5,"#B87A10");}
    if(v==="h"){b.ell(10,4.2,4.6,3.6,ARROZ);b.ell(16,4.6,4.2,3.2,ARROZ);b.px(9,2,"#B87A10");b.px(17,3,"#B87A10");b.px(13,2,"#FFF4B0");}
    if(v==="mi"){[[8,5],[11,7],[15,6],[18,5],[13,4]].forEach(q=>b.px(q[0],q[1],"#C8853C"));}
    if(/^p[123]$/.test(v)){[[8,5],[13,4],[18,5]].slice(0,+v[1]).forEach(q=>{b.ell(q[0],q[1],3.8,2.8,ARROZ);b.px(q[0]-1,q[1]-1,"#FFF4B0");});}
    return b.outline().done();},
  // a plate with an apple on it; a plate with a huge heap of rice; a white jug of milk; drops of water
  platoma(){const b=new Buf(26,20);b.ell(13,15.6,12.4,4.4,PLATO);b.ell(13,15,8.4,2.8,["#6AA0DC","#A8CCF0"]);b.ell(9.4,9.4,4.2,4.6,["#A01818","#D02828","#F05848"]);b.ell(15.6,9.4,4.2,4.6,["#A01818","#D02828","#F05848"]);b.rect(12,3,2,4,"#5A3A1A");b.rect(14,3,3,2,"#48A848");b.px(7,7,"#FFB0A0");b.px(8,6,"#FFB0A0");return b.outline().done();},
  platoH(){const b=new Buf(26,20);b.ell(13,15.6,12.4,4.4,PLATO);b.ell(13,15,8.4,2.8,["#6AA0DC","#A8CCF0"]);b.ell(13,12.4,8.6,3.8,["#F0F0F4","#FFFFFF"]);b.ell(13,8.6,7,5.4,["#E4E4EC","#F8F8FC","#FFFFFF"]);b.ell(13,4.8,4,3.2,["#E4E4EC","#F8F8FC","#FFFFFF"]);[[9,9],[14,7],[16,11],[11,12],[10,6],[13,4],[17,9]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#C8C8D8":"#FFFFFF"));return b.outline().done();},
  gotas(){const b=new Buf(14,10);[[1,6],[4,2],[7,5],[10,1],[12,6],[3,8],[9,8]].forEach(q=>{b.rect(q[0],q[1],2,2,"#78B8F0");b.px(q[0],q[1],"#E4F4FF");});return b.outline().done();},
  // the frog's own small plate
  platito(v){const b=new Buf(18,9);b.ell(9,5.2,8.4,3.2,PLATO);b.ell(9,4.6,5.4,1.9,["#6AA0DC","#A8CCF0"]);if(v==="o"){b.ell(9,3.2,3.6,2.6,ARROZ);b.px(8,2,"#FFF4B0");}if(v==="mi"){[[7,4],[10,5],[12,3]].forEach(q=>b.px(q[0],q[1],"#C8853C"));}return b.outline().done();},
  // a roll, 22 x 14. "ab" cut open and empty, "ab:c"/"ab:m" open with chocolate / butter in it, "ce" closed, "ce:c"/"ce:m" closed with the filling showing at the seam, "mo:c"/"mo:m" with a bite out of it
  rollo(v){let s=String(v||"ce").split(":");const k=s[0]==="s"?.64:1;if(s[0]==="s")s=s.slice(1);const st=s[0],con=s[1],F=con==="c"?CHOC[1]:MANT,FL=con==="c"?CHOC[2]:"#FFFBE0",b=new Buf(Math.round(22*k),Math.round(14*k));
    const E=(x,y,rx,ry,c)=>b.ell(x*k,y*k,rx*k,ry*k,c),Rc=(x,y,w,h,c)=>b.rect(Math.round(x*k),Math.round(y*k),Math.max(1,Math.round(w*k)),Math.max(1,Math.round(h*k)),c),P=(x,y,c)=>b.px(Math.round(x*k),Math.round(y*k),c);
    if(st==="ab"){E(11,4.4,9.2,3.8,TAN);E(11,9.6,10.2,4,TAN);E(11,8.2,8.4,2.4,["#FFF0C8","#FFFAE4"]);P(5,2,"#F4CC88");P(6,2,"#F4CC88");
      if(con){E(11,7.6,6,2.2,[F,F,FL]);P(8,6,FL);P(9,6,FL);}}
    else if(st==="mo"){E(11,8,10.2,5.2,TAN);Rc(2,8,18,1,"#8A5A18");P(7,4,"#F4CC88");P(8,4,"#F4CC88");borra(b,19*k,5.4*k,5*k);
      E(15,8,3.4,3.6,["#FFF0C8","#FFFAE4"]);if(con)E(15.6,8.4,2.4,2,[F,F,FL]);else E(15.6,8.4,2.4,2,["#E8D4A0"]);borra(b,19.4*k,5.2*k,3.6*k);}
    else{E(11,8,10.2,5.2,TAN);Rc(2,8,18,1,"#8A5A18");P(7,4,"#F4CC88");P(8,4,"#F4CC88");P(9,4,"#F4CC88");if(con){Rc(1,7,20,4,F);Rc(2,7,18,1,FL);E(1.5,9,1.8,2.2,[F]);E(20.5,9,1.8,2.2,[F]);Rc(1,10,20,1,con==="c"?CHOC[0]:"#E0C860");}}
    return b.outline().done();},
  // the basket of rolls (48 x 24), low enough to leave the places behind it free. v: "n:c": n rolls (0 to 5), c = 1 the cloth lies over them; the cloth otherwise lies folded back at the right
  cesta(v){const b=new Buf(40,24),s=String(v==null?"5:0":v).split(":"),n=+s[0],tapa=s[1]==="1";
    if(!tapa){
      const P=[[7,17],[19,17],[31,17],[13,14],[25,14]];P.slice(0,n).slice().sort((p,q)=>p[1]-q[1]).forEach(p=>rollitos(b,p[0],p[1]));}
    b.rect(1,15,34,8,"#B07A3C");for(let x=2;x<35;x+=4)b.rect(x,15,2,8,"#8A5A2A");b.rect(0,14,36,2,"#D09A54");b.rect(0,22,36,1,"#7A4A1E");
    if(tapa){if(n>0){b.ell(33,12,4,3.4,TAN);b.px(31,10,"#F4CC88");}b.ell(18,12,17,5.4,["#D0302A","#F4B8B0","#FFFFFF"]);for(let x=3;x<34;x+=4)b.rect(x,9+(x%8?0:1),2,5,"#FFFFFF");b.rect(1,14,34,3,"#F4B8B0");for(let x=2;x<35;x+=4)b.rect(x,14,2,3,"#D0302A");}
    else{b.rect(28,13,11,9,"#FFFFFF");for(let x=28;x<39;x+=4)for(let y=13;y<21;y+=4){b.rect(x,y,2,2,"#F4B8B0");b.rect(x+2,y+2,2,2,"#F4B8B0");}b.rect(28,20,11,2,"#D0302A");b.px(39,15,"#FFFFFF");b.px(39,17,"#F4B8B0");}
    return b.outline().done();},
  // the two fillings: the same bowl of blue and white china, 26 x 16. butter: a yellow block (v = how much is left, 1 to 5); chocolate: melted, dark brown and shiny, with a spoon in it (v: the same)
  mantequilla(v){const b=new Buf(22,16),n=Math.max(1,Math.min(5,+(v||5)));b.ell(11,10.4,10.4,5.4,CERA);b.ell(11,8.8,8.4,3.6,["#8A96C0","#B4BEE0"]);b.rect(2,10,18,1,"#2E6CD0");
    const w=4+n*2,h=2+n;b.rect(11-(w>>1),8-h+2,w,h,MANT);b.rect(11-(w>>1),8-h+2,w,1,"#FFFBE0");b.rect(11-(w>>1)+w-1,8-h+3,1,h-1,"#E0C860");b.rect(11-(w>>1),8,w,1,"#E0C860");
    b.rect(11-(w>>1)+1,8-h+4,2,1,"#E0C860");
    return b.outline().done();},
  choc(v){const b=new Buf(22,16),n=Math.max(1,Math.min(5,+(v||5)));b.ell(11,10.4,10.4,5.4,CERA);b.ell(11,8.8,8.4,3.6,["#8A96C0","#B4BEE0"]);b.rect(2,10,18,1,"#2E6CD0");
    const rx=2.6+n*1.1,ry=1.2+n*.5;b.ell(11,8.4,rx,ry,CHOC);b.px(9,8,"#C89A74");b.px(10,8,"#C89A74");b.px(13,9,"#A0724C");
    b.rect(13,0,2,9,"#C8C8D4");b.rect(14,0,1,9,"#8A8A9A");b.ell(14,2,2.6,1.8,["#B07A3C","#D09A54"]);b.rect(12,2,3,1,CHOC[1]);   // a spoon stands in it
    return b.outline().done();},
  // a wooden board to fill the roll on
  tabla(){const b=new Buf(32,10),W=RP.wood;b.rect(1,2,30,6,W[3]);b.rect(1,2,30,1,W[4]);b.rect(1,7,30,1,W[1]);b.rect(1,8,30,1,W[0]);for(let x=4;x<28;x+=5){b.rect(x,4,3,1,W[2]);b.rect(x+2,6,2,1,W[2]);}b.rect(26,3,4,2,W[0]);return b.outline().done();},
  tenedor(){const b=new Buf(8,18);[1,3,5].forEach(x=>b.rect(x,0,1,6,"#E8E8F2"));b.rect(1,5,5,2,"#D0D0DC");b.rect(3,7,1,10,"#D0D0DC");b.rect(4,7,1,10,"#9A9AAC");return b.outline().done();},
  cuchara(){const b=new Buf(9,18);b.ell(4.5,5,3,4,["#8A8A9C","#C8C8D4","#F8F8FF"]);b.rect(4,9,1,8,"#C8C8D4");return b.outline().done();},
  // a mound of yellow rice, 12 x 9
  monton(){const b=new Buf(12,9);b.ell(6,5.4,5.4,3.6,ARROZ);b.px(4,3,"#FFF4B0");b.px(7,3,"#FFF4B0");b.px(6,7,"#B87A10");b.px(8,6,"#B87A10");b.px(3,6,"#B87A10");return b.outline().done();},
  // the pot of rice on the table, 30 x 26: "lleno" (heaped, with its spoon), "lleno0" (no spoon), "vacio"
  olla(v){const b=new Buf(30,26);b.rect(4,9,22,15,"#8A8A9A");b.rect(4,9,6,15,"#B8B8C8");b.rect(4,20,22,4,"#5A5A6A");b.rect(1,12,3,4,"#3A3A46");b.rect(26,12,3,4,"#3A3A46");b.ell(15,9,11,4,["#5A5A6A","#9494A6","#C8C8D4"]);
    if(v==="vacio"){b.ell(15,9.4,9.2,3.2,["#1E1E28","#2A2A36"]);b.px(10,9,"#FFF4B0");b.px(20,10,"#B87A10");}else{b.ell(15,8.6,9.2,3.2,["#C88A10","#F2C028","#FFE060"]);b.ell(15,6.4,6,3.4,ARROZ);[[10,8],[13,9],[17,8],[20,9],[22,8],[12,6],[17,5]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    if(v==="lleno"){b.cap(20,8,26,1,1,["#B07A3C","#D09A54"]);}
    const c=b.outline().done();c.pico=[3,9];return c;},
  // the platter for the second helpings, 56 x 22: the mounds lie on it (drawn by the scene), and papá's fork
  fuente(){const b=new Buf(48,28);b.ell(24,15,23,12,["#2A5C9C","#4A86C8","#8CB8E8"]);b.ell(24,14,19.6,9.4,["#6AA0DC","#A8CCF0"]);b.rect(9,22,30,1,"#2E6CD0");return b.outline().done();},
  sillaBebe(v){return mkSillaBebe(v);},
  bebe(){return KIT.mkBebe("idle",0);},
  // a thought: a mound with a heart; his own round belly beside a clean plate (full)
  montoncor(){const b=new Buf(24,20);b.ell(12,15.6,10,4.4,PLATO);b.ell(12,15,6.6,2.6,["#6AA0DC","#A8CCF0"]);b.ell(12,12.4,5,3.6,ARROZ);b.px(10,10,"#FFF4B0");const H=[".##.##.","#######","#######",".#####.","..###..","...#..."];H.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(9+i-3,0+j,j<2&&i<3?"#FF9A90":"#E8443C");});return b.outline().done();},
  barriga(){const b=new Buf(34,22);b.ell(8,17,7.4,3.2,PLATO);b.ell(8,16.4,5,2,["#A8CCF0"]);   // a clean plate
    b.ell(24,13,9.6,7.4,["#A8682C","#C8853C","#E2A85A"]);b.ell(24,14.4,7.4,5.8,["#EEDCB0","#FBF0D2"]);b.px(24,15,"#B89A6A");   // the round belly
    b.ell(19,4.6,3.6,3.6,["#C8853C","#E2A85A"]);b.ell(29,4.6,3.6,3.6,["#C8853C","#E2A85A"]);b.px(19,4,"#20140A");b.px(29,4,"#20140A");b.rect(22,8,5,1,"#7A2A1A");   // his face above it
    b.rect(14,9,3,2,"#E2A85A");b.rect(31,10,3,2,"#E2A85A");   // two hands on the belly
    return b.outline().done();},
  // cups seen a little from above, 22 x 18: a blue cup with a handle; v: what is in it
  taza(v){const b=new Buf(22,18),L=LIQ[v]||LIQ.vacia;
    b.ell(8,13,6.8,4,["#1E4FA8","#2E6CD0","#4A8CE8"]);b.rect(1,6,14,7,"#2E6CD0");b.rect(1,6,3,7,"#4A8CE8");b.rect(12,6,3,7,"#1E4FA8");
    b.cap(14.6,8.6,19,9.4,1.2,["#1E4FA8","#2E6CD0"]);b.cap(19,9.4,17.2,13,1.2,["#1E4FA8","#2E6CD0"]);b.ell(16,10.6,1.2,1.6,["#C4D0F0"]);borra(b,17.6,10.6,1.2);
    b.ell(8,6,7.4,3.2,["#B4C8F0","#E4ECFF","#FFFFFF"]);b.ell(8,6.2,5.8,2.4,[L]);
    if(v==="negro"||v==="azu")b.px(5,5,"#4A2A18");if(v==="marron")b.px(5,5,"#A87848");
    if(v==="azu"){b.ell(8,4.6,3.8,2.4,["#D8DCE8","#F4F6FF","#FFFFFF"]);b.px(7,3,"#FFFFFF");b.px(9,4,"#C8CCDA");b.rect(10,0,2,6,"#C8C8D4");b.rect(11,0,1,6,"#8A8A9A");}   // too much sugar: a white heap and a spoon
    return b.outline().done();},
  // a cup with a spoon in it (being stirred)
  tazacu(v){const b=COSA.taza(v);const c=b.getContext("2d");c.fillStyle=OUT;c.fillRect(11,0,4,7);c.fillStyle="#C8C8D4";c.fillRect(12,0,2,6);c.fillStyle="#8A8A9A";c.fillRect(13,0,1,6);return b;},
  // the sugar bowl, 24 x 18: white china with a blue band, heaped with white sugar and a spoon in it
  azucarera(v){const b=new Buf(24,18);b.ell(12,12.4,10.4,4.8,CERA);b.rect(2,11,20,1,"#2E6CD0");b.ell(12,10,9,3,["#8A96C0","#B4BEE0"]);
    if(v!=="0"){b.ell(12,7.8,7.6,4.4,["#DCE2F0","#F4F6FF","#FFFFFF"]);[[8,6],[12,5],[15,7],[10,9],[13,8],[9,8]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#B4BEE0":"#FFFFFF"));b.rect(15,0,2,9,"#C8C8D4");b.rect(16,0,1,9,"#8A8A9A");b.ell(16,1.6,2.4,1.6,["#C8C8D4","#F8F8FF"]);}
    return b.outline().done();},
  // the big pot of coffee (enamel, blue, a spout and a handle), 24 x 28; pico: the lip
  cafetera(){const b=new Buf(24,28);b.rect(5,9,14,17,"#2A5C9C");b.rect(5,9,3,17,"#6AA0DC");b.rect(5,23,14,3,"#1A3C6C");b.ell(12,8,7.4,2.6,["#1A3C6C","#2A5C9C"]);b.rect(10,3,4,4,"#141418");b.rect(3,10,3,2,"#2A5C9C");b.rect(1,8,3,3,"#2A5C9C");b.rect(19,11,3,12,"#141418");b.rect(18,11,4,2,"#141418");b.rect(18,21,4,2,"#141418");b.px(9,14,"#FFFFFF");b.px(13,18,"#FFFFFF");const c=b.outline().done();c.pico=[1,9];return c;},
  // the little pouring pot (red), 16 x 16; pico: the lip
  jarrita(){const b=new Buf(16,16);b.rect(4,5,8,10,"#B0302A");b.rect(4,5,2,10,"#F08880");b.rect(4,12,8,3,"#7A1C1C");b.ell(8,4.4,4.6,1.8,["#7A1C1C","#B0302A"]);b.rect(1,6,3,2,"#B0302A");b.px(1,5,"#B0302A");b.rect(12,6,3,6,"#141418");b.rect(11,6,4,2,"#141418");b.rect(11,10,4,2,"#141418");const c=b.outline().done();c.pico=[1,5];return c;},
  // the milk pan: v "1" with milk, "0" empty; 24 x 10; pico: the lip
  cazo(v){const b=new Buf(22,10);b.ell(9,6.2,8.6,3.4,["#6A6E80","#B8BCCC","#E8EAF2"]);b.ell(9,4.6,7.2,2.4,v==="0"?["#2A2A36","#4A4A58"]:["#E4DCC8","#F6F1E4","#FFFFFF"]);b.rect(16,4,5,2,"#3A3A46");const c=b.outline().done();c.pico=[1,5];return c;},
  // the dog's bowl: with milk in it, or empty
  tazon(v){const b=new Buf(22,10);b.ell(11,6,10,3.6,["#2A5C9C","#4A86C8","#8CB8E8"]);b.ell(11,4.8,7.8,2.4,v==="1"?["#E4DCC8","#F6F1E4","#FFFFFF"]:["#1E3A68","#2A5C9C"]);return b.outline().done();},
  // a tray with n rolls, for abuela to carry
  bandeja(n){const b=new Buf(40,14);n=n==null?4:+n;b.rect(1,8,38,3,"#9494A6");b.rect(1,8,38,1,"#C8C8D4");b.rect(0,7,40,1,"#C8C8D4");for(let i=0;i<n;i++)rollitos(b,7+i*8.4,9);return b.outline().done();},
  pano(){const b=new Buf(12,10);b.rect(1,1,10,8,"#F8F8FF");b.rect(1,4,10,1,"#E0403A");b.rect(1,7,10,1,"#E0403A");return b.outline().done();},
  charco(){const b=new Buf(19,8);b.ell(8,4,5.4,1.8,["#6A3214"]);b.ell(12,3,3,1.4,["#6A3214"]);return b.outline().done();},
  // pictures of the pairs: a drumstick, a slice of cake, a bowl of rice for the dog, a jug, a glass
  muslo(v){const b=new Buf(24,14);b.ell(8,7,7.8,5.6,["#8A4A14","#C87A28","#E8A848"]);b.px(5,4,"#F8D890");b.px(6,3,"#F8D890");b.px(7,3,"#F8D890");b.rect(14,6,6,2,"#F2EAD8");b.ell(20,5.6,2.4,2.4,["#F2EAD8"]);b.ell(20,9.4,2.4,2.4,["#F2EAD8"]);
    if(v==="b"){borra(b,1,5,3.6);b.ell(4.6,6,1.6,2.6,["#F8E4B0"]);borra(b,1.6,5.2,2.8);}   // a bite out of it
    return b.outline().done();},
  manzana(){const b=new Buf(11,11);b.ell(3.6,6.4,3,4,["#A01818","#D02828","#F05848"]);b.ell(7.4,6.4,3,4,["#A01818","#D02828","#F05848"]);b.rect(5,1,1,3,"#5A3A1A");b.px(6,1,"#48A848");b.px(2,4,"#FFB0A0");return b.outline().done();},
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
  granos(){const b=new Buf(8,5);[[1,1],[3,3],[5,0],[6,3]].forEach(q=>b.px(q[0],q[1],"#FFFFFF"));return b.outline().done();},
  jarra(v){const b=new Buf(23,29),n=v==null?4:+v;b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");if(n>0)b.rect(4,27-n*5,11,n*5,"#F08818");for(let i=1;i<=4;i++)b.rect(11,27-i*5,5,1,"#4A5A6A");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
  jugo(){const b=new Buf(23,29);b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");b.rect(4,27-20,11,20,"#F08818");b.rect(4,7,11,2,"#FFB040");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
  jugopoco(){const b=new Buf(23,29);b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");b.rect(4,25,11,2,"#F08818");b.rect(4,24,11,1,"#FFB040");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
  // the milk jug for the pair, 20 x 22, white; pico: the lip
  jarraleche(){const b=new Buf(20,22);b.rect(3,3,12,18,"#E8F0FA");b.rect(3,3,2,18,"#FFFFFF");b.rect(3,17,12,4,"#C8D4E8");b.rect(15,5,3,2,"#E8F0FA");b.rect(16,4,3,1,"#C8D4E8");b.rect(0,3,4,2,"#E8F0FA");b.rect(15,7,3,10,"#C8D4E8");const c=b.outline().done();c.pico=[0,4];return c;},
  // a glass of orange juice, 9 x 13
  vasojugo(){const b=new Buf(9,13);b.rect(1,1,7,11,"#DCF2FA");b.rect(1,1,2,11,"#F2FBFF");b.rect(2,4,5,8,"#F08818");b.rect(2,3,5,1,"#FFB040");return b.outline().done();},
  // a big hand, laid flat on the belly (v: the colour of the skin)
  manoG(v){const b=new Buf(10,8),c=v||"#D09460";b.ell(5,4.4,4.4,3.2,[c]);b.px(2,1,c);b.px(4,0,c);b.px(6,0,c);b.px(8,1,c);b.px(3,6,"#7A4A2A");b.px(5,6,"#7A4A2A");b.px(7,6,"#7A4A2A");return b.outline().done();},
  // a thing for a thought: a question mark; a heart
  interroga(){const b=new Buf(9,13);const Q=["..###..",".##.##.",".##.##.","....##.","...##..","..##...","..##...",".......","..##..."];Q.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(1+i,1+j,"#3A3A46");});return b.outline("#FFFFFF").done();},
  corazon(){const b=new Buf(9,8);const H=[".##.##.","#######","#######",".#####.","..###..","...#..."];H.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(1+i,1+j,j<2&&i<3?"#FF9A90":"#E8443C");});return b.outline().done();}};
// the pots that pour are made twice: standing, and tipped (at 50 degrees) to pour to the left; to the right they are turned over
function cosaIm(k,c){
  if(/^tilt/.test(k)){const base=k.slice(4),b=COSA[base](c),g=giro(b,-0.9,b.pico);return g;}
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
function vapor(c,x,y,n){const t=(F>>2)%12;c.save();for(let i=0;i<(n||2);i++){const dx=i*7-3;for(let k=0;k<14;k++){const sw=Math.round(Math.sin((k+t*1.2+i*4)/2.4)*2.4);c.globalAlpha=Math.max(.12,.85-k*.065);fr(c,x+dx+sw-1,y-k,3,1,"#B8C4D4");fr(c,x+dx+sw,y-k,2,1,"#FFFFFF");}}c.restore();}
// a stream falling from y0 to y1
function chorro(c,x,y0,y1,col){if(y1<=y0)return;fr(c,x-1,y0,3,y1-y0,OUT);fr(c,x,y0,1,y1-y0,col);fr(c,x+1,y0,1,y1-y0,col);const t=F%4;fr(c,x-3,y1-1,7,2,OUT);fr(c,x-2,y1-1,5,1,col);if(t<2)fr(c,x-4,y1-3,2,1,col);else fr(c,x+3,y1-3,2,1,col);}
// a thick line (an arm, a handle) with a dark edge
function trazo(c,x0,y0,x1,y1,col,ancho){const n=Math.max(1,Math.ceil(Math.max(Math.abs(x1-x0),Math.abs(y1-y0)))),a=ancho||2;
  for(let i=0;i<=n;i++){const x=R(x0+(x1-x0)*i/n),y=R(y0+(y1-y0)*i/n);fr(c,x-1,y-1,a+2,a+2,OUT);}
  for(let i=0;i<=n;i++){const x=R(x0+(x1-x0)*i/n),y=R(y0+(y1-y0)*i/n);fr(c,x,y,a,a,col);}}
const mano=(c,x,y,pi)=>{fr(c,R(x)-2,R(y)-2,5,5,OUT);fr(c,R(x)-1,R(y)-1,3,3,pi||RP.skin[2]);};
// a long spoon: its handle from the hand (x0,y0) to its bowl (x1,y1); the bowl faces us. load: what is in it ("monton" rice, "azu" sugar, "c"/"m" chocolate / butter, "" nothing)
function cucharon(c,x0,y0,x1,y1,load,o){o=o||{};const mad=o.plata?["#C8C8D4","#8A8A9A","#F8F8FF"]:["#B07A3C","#8A5A2A","#D09A54"];
  trazo(c,x0,y0,x1,y1,mad[0],o.plata?2:3);const rx=o.rx||6,ry=o.ry||4,cx=R(x1),cy=R(y1);
  ovalo(c,cx,cy,rx+1,ry+1,OUT);ovalo(c,cx,cy,rx,ry,mad[1]);ovalo(c,cx,cy+(o.plata?0:1),rx-1,ry-1,mad[2]);
  if(load==="monton")tenidaC(c,"monton",cx,cy-3,1);
  else if(load==="azu"){ovalo(c,cx,cy-2,rx-1,ry-1,"#F4F6FF");ovalo(c,cx,cy-4,rx-3,ry-2,"#FFFFFF");fr(c,cx-2,cy-4,1,1,"#B4BEE0");fr(c,cx+2,cy-3,1,1,"#B4BEE0");}
  else if(load==="arr"){ovalo(c,cx,cy-2,6,4,OUT);ovalo(c,cx,cy-2,5,3,"#DCDCE8");ovalo(c,cx,cy-3,4,2,"#FFFFFF");fr(c,cx-2,cy-3,1,1,"#B8B8CC");fr(c,cx+1,cy-2,1,1,"#B8B8CC");}   // one small scoop of white rice
  else if(load==="ARR"){ovalo(c,cx,cy-5,11,9,OUT);ovalo(c,cx,cy-5,10,8,"#DCDCE8");ovalo(c,cx,cy-8,8,6,"#F0F0F6");ovalo(c,cx,cy-11,5,3,"#FFFFFF");[[-5,-3],[3,-5],[6,-2],[-2,-8],[1,-10],[-7,-6]].forEach(g=>fr(c,cx+g[0],cy+g[1],1,1,"#B8B8CC"));}   // one huge heaped scoop
  else if(load==="c"){ovalo(c,cx,cy-2,rx-1,ry-1,CHOC[1]);ovalo(c,cx,cy-3,rx-3,ry-2,CHOC[2]);fr(c,cx-1,cy-4,2,1,"#C89A74");}
  else if(load==="m"){ovalo(c,cx,cy-2,rx-1,ry-1,"#E0C860");ovalo(c,cx,cy-3,rx-3,ry-2,MANT);fr(c,cx-1,cy-4,2,1,"#FFFBE0");}}

/* ---------- what can be touched ---------- */
const alto=id=>{const w=QUIEN[id]||{},p=W.gente[id];return id==="abuela"?(p&&p.sent?48:51):w.nino?(p&&p.sent?37:44):(p&&p.sent?49:56);};
// somebody who sits behind the table is touched from his head down over the edge of the table: the middle of his box is his chest, so the stars of the signal fall beside and above his head, never on his face
const caja=id=>{const p=W.gente[id];if(!p||p.vis===0)return null;const h=alto(id);return p.sent?[R(p.x)-11,R(p.y)-h,22,Math.max(40,MESA[1]+26-(R(p.y)-h))]:[R(p.x)-11,R(p.y)-h,22,h];};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const ob=id=>(W.cosas||[]).find(o=>o.id===id);
const porId=(id,w,h,z)=>({id,si:w2=>!!(w2.cosas||[]).find(o=>o.id===id&&o.vis!==0),box:w2=>{const o=w2.cosas.find(o=>o.id===id);return [R(o.x)-(w>>1),R(o.y)-h,w,h];},m:1,z:z==null?1:z});
const COSAS=Object.keys(QUIEN).map(persona).concat([porId("mant",26,16),porId("choc",26,16),porId("cesta",48,24,0),porId("cafetera",24,28,0),porId("azucarera",24,18,0),porId("olla",30,26,0),porId("fuente",56,22,0),porId("pl_papa",24,10,0),porId("pl_rana",18,9,0),
  {id:"silla_papa",si:w=>true,box:[SILLA[3]-10,MESA[1]-26,20,36],m:0},{id:"mesa",box:[MESA[0]-6,MESA[1],MESA[2]+12,MESA[3]+6],m:0},{id:"cocina",box:[32,24,196,190],m:0}]);

/* ---------- drawing ---------- */
// where things are held: the shoulder and the mouth of each, from his feet (up)
const hombroY=(id,p)=>{const w=QUIEN[id]||{};return id==="abuela"?(p.sent?25:27):w.nino?(p.sent?19:22):(p.sent?27:34);};
const bocaY=(id,p)=>{const w=QUIEN[id]||{};return id==="abuela"?(p.sent?33:35):w.nino?(p.sent?25:28):(p.sent?33:40);};
const sleeve=id=>id==="abuela"?RP.purp[2]:((QUIEN[id]||{}).ropa||RP.cream)[2];
const piel=id=>id==="abuela"?RP.skin[2]:((QUIEN[id]||{}).piel||RP.skin)[2];
function cuerpo(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  if(id==="abuela"){
    if(p.sent){const ps=p.pose||"idle",top=y-48,hb=(habla||p.abre||p.boca)?1:0;if(p.taburete)tenida(c,"taburete",x,y+2);c.drawImage(spr("abSC"+ps+hb,()=>mkAbuelaSC(ps,hb)),x-17,top);return;}
    const ps=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle"),top=y-50+((p.paso&&a%2)?-1:0),hb=(habla||p.abre||p.boca)?1:0;c.save();c.translate(x,top);if(((ps==="offer"||ps==="bless")?-d:d)<0)c.scale(-1,1);c.drawImage(spr("abC"+ps+hb,()=>mkAbuelaC(ps,hb)),-30,0);c.restore();return;}
  const pose=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle"),op=(habla||p.boca||p.sopla)?1:0,w2=p.cierra?Object.assign({},w,{dormido:1},w.gafas?{gafas:"arriba"}:{}):w,im=spr("pmx"+id+pose+op+(p.sent?1:0)+(p.cierra?"c":""),()=>KIT.mkPersona(w2,pose,op,p.sent)),top=y-im.height+1+((p.paso&&a%2)?-1:0)+(p.dy||0);
  c.save();c.translate(x,top);if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  const sk=(w.piel||RP.skin)[2];
  if(p.cara==="mal"){fr(c,x-5,top+13,11,6,sk);   // a big frown: a wide dark arc, and thick brows that slope down to the nose, and the red mark of being cross
    fr(c,x-2,top+14,5,2,"#5A1A10");fr(c,x-4,top+15,2,2,"#5A1A10");fr(c,x+3,top+15,2,2,"#5A1A10");fr(c,x-5,top+17,2,1,"#5A1A10");fr(c,x+4,top+17,2,1,"#5A1A10");
    [[-7,6],[-6,6],[-5,7],[-4,7],[-3,8],[-2,8]].forEach(q=>fr(c,x+q[0],top+q[1],1,2,"#20140A"));[[6,6],[5,6],[4,7],[3,7],[2,8],[1,8]].forEach(q=>fr(c,x+q[0],top+q[1],1,2,"#20140A"));
    fr(c,x+6,top+1,1,4,"#D0302A");fr(c,x+5,top+2,3,1,"#D0302A");fr(c,x+7,top+3,1,1,"#D0302A");}
  if(p.cierra){[[-6,13],[-5,12],[-4,11],[-3,11],[-2,12],[-1,13]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));[[1,13],[2,12],[3,11],[4,11],[5,12],[6,13]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));   // eyes shut: two curved lines
    fr(c,x-5,top+13,2,1,sk);fr(c,x+3,top+13,2,1,sk);}
  if(p.sopla){fr(c,x-9,top+11,5,6,sk);fr(c,x+5,top+11,5,6,sk);fr(c,x-10,top+12,1,4,OUT);fr(c,x+10,top+12,1,4,OUT);fr(c,x-9,top+10,5,1,OUT);fr(c,x+5,top+10,5,1,OUT);fr(c,x-9,top+17,5,1,OUT);fr(c,x+5,top+17,5,1,OUT);   // puffed cheeks, a round mouth, and a breath
    fr(c,x-3,top+14,7,3,sk);fr(c,x-1,top+14,3,3,"#7A1C1C");
    const t=(F>>2)%3;[[0,0],[6,2],[12,0]].forEach((q,i)=>{fr(c,x+d*(7+q[0]+t),top+14+q[1],5,1,i===t?"#FFFFFF":"#B8C4D4");fr(c,x+d*(7+q[0]+t),top+15+q[1],3,1,"#B8C4D4");});}}
// what he holds and eats, drawn after (over) his body; behind the table, after the table too
function objetos(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const x=R(p.x),y=R(p.y),d=p.dir<0?-1:1,hy=hombroY(id,p),pi=piel(id),sl=sleeve(id);
  for(const it of p.tiene||[]){if(it.vis===0)continue;const ix=x+d*it.dx,iy=y-it.dy,fl=it.flip!=null?it.flip:(it.dirf?d>0:false),sh=it.sh||1;
    if(it.arm||it.k==="brazo"){const gx=x+d*(it.gx==null?it.dx:it.gx),gy=y-(it.gy==null?it.dy:it.gy);trazo(c,x+d*sh*7,y-hy,gx,gy,sl,3);}
    if(it.k==="brazo"){mano(c,x+d*it.gx,y-it.gy,pi);continue;}
    if(it.k==="uten")cucharon(c,x+d*it.ax,y-it.ay,x+d*it.bx,y-it.by,it.load,it.o);
    else tenidaC(c,it.k,ix,iy,it.e,it.v,fl);
    if(it.vapor)vapor(c,ix,iy-(it.e||1)*9-2,it.vn||1);
    if(it.chorro){const im=cosa(it.k,it.v),e=it.e||1;if(im.pico){const px=ix+(im.pico[0]-im.width/2)*e*(fl?-1:1),py=iy+(im.pico[1]-im.height/2)*e+1;chorro(c,R(px),R(py),R(py)+it.chorro.h,it.chorro.col);}}   // a stream from the lip of what he pours
    if(it.arm){const gx=x+d*(it.gx==null?it.dx:it.gx),gy=y-(it.gy==null?it.dy:it.gy);mano(c,gx,gy,pi);}}
  if(p.come){const co=p.come,my=y-bocaY(id,p)+(a%2),cxx=x+d*(co.dx==null?13:co.dx);tenidaC(c,co.k,cxx,my+(co.dy||0),co.e||1,co.v,d<0&&co.k!=="tenedor");if(co.vapor)vapor(c,cxx,my-8,1);}
  if(p.bebe2)tenidaC(c,"taza",x+d*14,y-bocaY(id,p)+3-(a%2),1,p.bebe2);}
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
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;g.restore();
  if(q.lleno){[[-7,0],[-9,1],[-10,2],[-10,3],[-9,4],[-7,5]].forEach(r=>{fr(g,cx+r[0]-1,b.y+dy+12+r[1],-2*r[0]+2,1,"#FBF0D2");});fr(g,cx-10,b.y+dy+14,1,3,OUT);fr(g,cx+9,b.y+dy+14,1,3,OUT);fr(g,cx,b.y+dy+15,1,1,"#B89A6A");}
  for(const it of q.tiene||[]){if(it.vis===0)continue;const ix=cx+it.dx,iy=fy-it.dy;
    if(it.k==="uten")cucharon(g,cx+it.ax,fy-it.ay,cx+it.bx,fy-it.by,it.load,it.o);else tenidaC(g,it.k,ix,iy,it.e,it.v,it.flip);
    if(it.chorro){const im=cosa(it.k,it.v),e=it.e||1;if(im.pico){const px=ix+(im.pico[0]-im.width/2)*e*(it.flip?-1:1),py=iy+(im.pico[1]-im.height/2)*e+1;chorro(g,R(px),R(py),R(py)+it.chorro.h,it.chorro.col);}}
    if(it.gx!=null)mano(g,cx+it.gx,fy-it.gy,RP.tan[3]);}}
// a thought: a round white cloud with its trail of two small ones, and a thing in it. At (x,y): its top left.
function nube(g,x,y,o,dir){const w=40,h=30,t=dir||1;fr(g,x-1,y+3,w+2,h-6,OUT);fr(g,x+3,y-1,w-6,h+2,OUT);fr(g,x+1,y+1,w-2,h-2,OUT);
  fr(g,x,y+3,w,h-6,"#FFFFFF");fr(g,x+3,y,w-6,h,"#FFFFFF");fr(g,x+1,y+1,w-2,h-2,"#FFFFFF");
  const tx=x+(t>0?8:w-8);[[tx,y+h+3,5],[tx+t*(-3),y+h+9,3]].forEach(q=>{fr(g,q[0]-(q[2]>>1)-1,q[1]-1,q[2]+2,q[2]+2,OUT);fr(g,q[0]-(q[2]>>1),q[1],q[2],q[2],"#FFFFFF");});
  tenidaC(g,o.k,x+(w>>1),y+(h>>1),o.e||1,o.v);}
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,6+20*(W.marcas||[]).length,24);   // two places: every story has two scored rounds
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m){g.fillStyle=OUT;for(let k=0;k<11;k++){g.fillRect(x+k,y+1+k,4,3);g.fillRect(x+10-k,y+1+k,4,3);}g.fillStyle="#C8401E";for(let k=0;k<11;k++){g.fillRect(x+1+k,y+2+k,2,1);g.fillRect(x+11-k,y+2+k,2,1);}}
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}
const marca=m=>{const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;};
const enMesa=o=>o.y>=FILA-1&&o.y<=FREN+3&&o.x>MESA[0]-8&&o.x<MESA[0]+MESA[2]+8;
// a roll with its state (st, con, mal: spoiled, with its smell)
function rolloD(c,x,yb,r,a){tenida(c,"rollo",x,yb,0,1,(r.peq?"s:":"")+r.st+(r.con?":"+r.con:""));
  if(r.mal){const t=(F>>2)%6,h=r.peq?10:15,s=r.peq?.64:1;   // spoiled: green mould on it and a smell rising
    [[-5,-6],[0,-8],[5,-5]].forEach(m=>{const mx=R(x+m[0]*s),my=R(yb+m[1]*s);fr(c,mx-1,my-1,4,3,"#3E7A2A");fr(c,mx,my,2,1,"#9AD468");});
    c.save();[[-6,0],[0,3],[6,0]].forEach((q,i)=>{for(let k=0;k<13;k++){const sw=Math.round(Math.sin((k+t+i*2)/1.8)*2);c.globalAlpha=Math.max(.25,1-k*.06);fr(c,x+q[0]+sw-1,yb-h-k-q[1],4,1,"#2E6A1E");fr(c,x+q[0]+sw,yb-h-k-q[1],2,1,"#7ACC48");}});c.restore();}}
function cosaDibuja(c,o,a){const k=o.k;
  if(k==="plato"){tenida(c,"plato",o.x,o.y,0,o.e,o.v);(o.rollos||[]).forEach(r=>{r.peq=1;rolloD(c,o.x+(r.dx||0),o.y-2,r,a);});if(o.vapor)vapor(c,o.x,o.y-12,1);return;}
  if(k==="tabla"){tenida(c,"tabla",o.x,o.y);const ml=o.malos||[];ml.forEach((r,i)=>rolloD(c,o.x-9+i*2,o.y-3,r,a));if(o.rollo)rolloD(c,o.x+(ml.length?8:0),o.y-3,o.rollo,a);return;}
  if(k==="fuente"){tenida(c,"fuente",o.x,o.y);(o.montones||[]).forEach(m=>tenida(c,"monton",o.x+m.dx,o.y+(m.dy==null?-4:m.dy)));if(o.tenedor)tenida(c,"tenedor",o.x+o.tenedor.dx,o.y-(o.tenedor.dy==null?4:o.tenedor.dy),0,1);return;}
  if(k==="olla"){tenida(c,"olla",o.x,o.y,0,1,o.v);if(o.vapor&&o.v!=="vacio")vapor(c,o.x,o.y-22,2);return;}
  tenida(c,k==="taza"&&o.sp?"tazacu":k,o.x,o.y,0,o.e||1,o.v);
  if(o.vapor)vapor(c,o.x+(o.vdx||0),o.y-(o.vdy==null?(k==="cesta"?18:k==="taza"?15:12):o.vdy),o.vn||2);}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{};c.imageSmoothingEnabled=false;
  c.drawImage(spr("comer",fondo),0,0);
  const L=[];
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(!p||p.vis===0)return;L.push({y:p.z!=null?p.z:p.y,d:()=>cuerpo(c,id,a)});L.push({y:p.z!=null?p.z+.001:(p.y<TZ?TZ+.9:p.y+.001),d:()=>objetos(c,id,a)});});
  L.push({y:TZ,d:()=>c.drawImage(spr("mesa",mkMesa),MESA[0]-6,MESA[1])});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:enMesa(o)?TZ+o.y/1000:o.y+1,d:()=>cosaDibuja(c,o,a)});});
  if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>{const o=W.perro,f=o.pose==="eat"||o.pose==="walk"||o.cola?(a>>1)%2:0,im=spr("pe"+o.pose+f,()=>mkPerro(o.pose,f));c.save();c.translate(R(o.x),R(o.y));const e=o.e||1;c.scale((o.dir<0?-1:1)*e,e);c.translate(0,-im.height+2);c.drawImage(im,-13,0);
    if(o.granos){[[24,10],[26,9],[28,11]].forEach(g=>fr(c,g[0]-13+1,g[1]-1,2,2,"#FFFFFF"));}   // a few grains of rice on his nose
    if(o.lengua){fr(c,14,13,5,3,OUT);fr(c,15,13,3,2,"#F07890");}   // his tongue out, into the bowl
    c.restore();}});
  if(q.vis)L.push({y:q.sobre===0?q.y+27:TZ+(q.y+27)/1000,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  (W.vuelos||[]).forEach(o=>{if(o.k==="chorro")chorro(c,o.x,o.y,o.y+o.h,o.col||"#5A2E14");else tenidaC(c,o.k,o.x,o.y,o.e||1,o.v,o.flip);});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.piensa&&p.vis!==0)nube(c,R(p.x)-20+(p.pdx||0),R(p.y)-alto(id)-38,p.piensa);});
  if(q.vis&&q.piensa){const b=frogBox(q),n=q.nube||[b.x+(b.w>>1)-20,b.y-44];nube(c,n[0],n[1],q.piensa,q.ndir);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1];}
function respIcon(g,k,x,y,w,h,a){}

/* ---------- the places of story 34 (the rice) and of story 35 (the coffee) ---------- */
const HIJA=[48,142],OLLA=[96,154],PLUIS=[84,172],PRANA=[106,172],CASA34=[134,168];   // the baby's high chair at the left end; the pot (then the platter) by Luis; his plate; the frog's small plate; the frog's place
const SEAT34={mama:0,carmen:1,papa:2,abuelo:3};
const TENE=(k,dx,dy,o)=>Object.assign({k,dx,dy},o||{});
const GRANDE=(bx,by,load)=>({k:"uten",ax:17,ay:29,bx,by,load:load||"",o:{rx:6,ry:4},arm:1,gx:17,gy:29});   // the big wooden spoon in the right hand of somebody who faces right; its bowl at (bx,by) from his feet
const luisSp=()=>((G("luis").tiene||[]).find(t=>t.k==="uten"));
const enL=(X,Y)=>{const l=G("luis");return [X-l.x,l.y-Y];};   // a point of the table, measured from Luis's feet (he faces right)
async function bolaA(it,bx,by,n){n=n||5;const x0=it.bx,y0=it.by;for(let i=1;i<=n;i++){it.bx=x0+(bx-x0)*i/n;it.by=y0+(by-y0)*i/n;await wait(TICK);}it.bx=bx;it.by=by;}
async function cucharaL(X,Y,n){const sp=luisSp();if(!sp)return;const b=enL(X,Y);await bolaA(sp,b[0],b[1],n);}
const REPOSO=()=>enL(116,158);   // where Luis rests the spoon: out to the right, over the frog's plate
// where the next mound is: on the platter (a helping, g "m", or papá's, g "p") or in the pot
function fuenteMonton(g){const fu=ob("fuente");if(!fu||!fu.montones)return null;const m=fu.montones.filter(m=>m.g===g)[0];return m?{fu,m,x:fu.x+m.dx,y:fu.y+(m.dy==null?-4:m.dy)-3}:null;}
const origen=()=>{const h=fuenteMonton("m");if(h&&ob("fuente").x<200)return {x:h.x,y:h.y,take:()=>{h.fu.montones.splice(h.fu.montones.indexOf(h.m),1);}};const ol=ob("olla");return {x:ol.x,y:ol.y-18,take:()=>{}};};
// the frog's place when he tips a mound onto the plate of the one at seat i (x): to the left of the plate with the spoon in his right hand, or to its right with the spoon in his left
const lado34=px=>px>140?{fx:px-24,fy:152,izq:0}:{fx:px+24,fy:152,izq:1};
const cuchaRana=(izq,bx,by,load)=>({k:"uten",ax:izq?-13:13,ay:12,bx,by,load:load||"",o:{rx:6,ry:4},gx:izq?-13:13,gy:12});

/* ---------- the places of story 35 ---------- */
const K1=[76,170],K2=[100,170],AZU=[146,170],TRANA=[168,170],POTE=[184,170],TABU=[182,150],CASA35=[122,166],CANELO=[216,203],TAZON=[188,200];
const copa=id=>ob("t_"+id);
const liq=(id,v,vapor)=>{const t=copa(id);if(t){t.v=v;if(vapor!=null)t.vapor=vapor;}};
// something he pours: its lip is put at (tx,ty); it is turned over to pour to the right (flip), the stream falls h from the lip. For a person (p) or the frog (p = "rana")
function vierteItem(p,k,v,tx,ty,flip,h,col,e){const im=cosa("tilt"+k,v),E=e||1,s=flip?-1:1,ox=(im.pico[0]-im.width/2)*E*s,oy=(im.pico[1]-im.height/2)*E,cxA=tx-ox,cyA=ty-oy;
  if(p==="rana")return {k:"tilt"+k,v,dx:cxA-cx(),dy:pies()-cyA,e:E,flip:!!flip,chorro:{h,col}};
  const d=p.dir<0?-1:1;return {k:"tilt"+k,v,dx:(cxA-p.x)*d,dy:p.y-cyA,e:E,flip:!!flip,chorro:{h,col},arm:1,gx:(cxA+(flip?-1:1)*(im.width/2-3)*E-p.x)*d,gy:p.y-cyA-2};}
const SPA=()=>({k:"uten",ax:13,ay:12,bx:30,by:20,load:"azu",o:{plata:1,rx:6,ry:4},gx:13,gy:12});   // the frog's big spoon with its heap of sugar

/* ---------- moving: everybody walks, everything is carried ---------- */
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/6));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;}
async function ruta(id,pts){for(const q of pts)await mueve(id,q[0],q[1]);}
// a thing flies a short way: from a hand to a table, from a table to a hand (never farther than an arm and a hop)
async function vuela(o,x0,y0,x1,y1,n){const v=Object.assign({x:x0,y:y0},o);W.vuelos.push(v);n=n||5;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(x1-x0)*t;v.y=y0+(y1-y0)*t-Math.sin(t*Math.PI)*5;await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);}
// the thing a person holds changes place in his hand: it slides from where it is to (dx,dy) from his feet
async function mueveTiene(id,it,dx,dy,n){n=n||5;const x0=it.dx,y0=it.dy;for(let i=1;i<=n;i++){it.dx=x0+(dx-x0)*i/n;it.dy=y0+(dy-y0)*i/n;await wait(TICK);}it.dx=dx;it.dy=dy;}
const corre=(o,pr)=>{if(o&&o.suelto){W._mov=pr;return Promise.resolve();}return pr;};
async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(3,R(d/40))));}
const cx=()=>W.cq.x+16,pies=()=>W.cq.y+27;
// where somebody comes in from (out of the picture, at the left), where he goes out to
async function entra(id,x,y,dir){const p=G(id);p.sent=0;if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=y;}p.dir=1;p.tiene=p.tiene||[];await mueve(id,x,y);if(dir)p.dir=dir;}
async function sale(id){const p=G(id);if(p.vis===0)return;const front=p.y>150;p.sent=0;p.come=null;p.cara=null;p.pose="idle";if(!front)await mueve(id,48,ATRAS);else await mueve(id,44,Math.min(p.y,184));await mueve(id,PUERTA[0],front?Math.min(p.y,184):ATRAS);p.vis=0;p.tiene=[];}
// from the left end of the table to a chair behind it (round the end of the table, then along the lane behind), and sits; from the chair back to the left end
async function sienta(id,i){const p=G(id);if(p.vis!==0&&p.sent&&Math.abs(p.x-SILLA[i])<2)return;p.sent=0;if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=ATRAS;p.tiene=[];}
  if(p.y>150){await mueve(id,46,Math.min(p.y,176));await mueve(id,50,ATRAS+4);}
  await mueve(id,SILLA[i]-3,ATRAS);await mueve(id,SILLA[i],ASIENTO,3);p.sent=1;p.y=ASIENTO;p.dir=1;p.pose="idle";p.tiene=p.tiene||[];SFX.blip();}
async function levanta(id,x,y){const p=G(id);p.sent=0;p.pose="idle";const x0=p.x;p.y=ATRAS;await wait(150);await mueve(id,Math.max(70,x0-3),ATRAS);await ruta(id,[[50,ATRAS+4],[44,Math.min(176,y)],[x,y]]);}

// the frog's spoon, in his right hand (0) or his left (1)
const CUCH=lado=>lado?{k:"uten",ax:-13,ay:12,bx:-30,by:18,load:"",o:{plata:1,rx:5,ry:3},gx:-13,gy:12}:{k:"uten",ax:13,ay:12,bx:30,by:18,load:"",o:{plata:1,rx:5,ry:3},gx:13,gy:12};
/* ---------- the plates, the rolls ---------- */
const ROLLOS=pl=>pl.rollos||(pl.rollos=[]);
const nCesta=()=>+String(ob("cesta").v).split(":")[0];
const quitaCesta=()=>{const ce=ob("cesta"),n=nCesta();ce.v=(n-1)+":0";return n-1;};

const acts={
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async ya(){const p=W._mov;W._mov=null;if(p)await p;},
  async g(o){const p=G(o.quien);if(!p)return;Object.keys(o).forEach(k=>{if(!["act","quien","ms"].includes(k))p[k]=o[k]===""?null:o[k];});if(o.ms)await wait(+o.ms);},
  async nota(o){V[o.k]=o.v==null?"1":String(o.v);},

  /* ----- story 33: ¿Qué quieres? ----- */
  // The five rolls come split in the basket (cut open, empty), steaming; the second tray waits on the stove. Whoever asks takes a roll from the basket with his hand and holds it up; he sets it on the board and goes out to wash his hands; the frog spoons the filling in and closes the roll; he comes back, takes it and eats it at his chair. A roll he did not like is left on his plate, spoiled, to the end.
  async inicio33(){W.gente={abuela:{x:FOGON[0],y:FOGON[1],dir:-1,tiene:[]},abuelo:{vis:0},mama:{vis:0},papa:{vis:0},luis:{vis:0},carmen:{vis:0}};W.sitio={};
    const pl=(id,x)=>({id,k:"plato",x,y:FILA,rollos:[]});
    W.cosas=[pl("pl_abuela",SILLA[0]),pl("pl_abuelo",SILLA[1]),pl("pl_mama",SILLA[2]),pl("pl_papa",SILLA[3]),
      {id:"cesta",k:"cesta",v:"5:0",x:88,y:152,vapor:1,vdx:-2,vdy:18,vn:2},{id:"tabla",k:"tabla",x:84,y:170,rollo:null,malos:[]},
      {id:"mant",k:"mantequilla",v:"5",x:150,y:170},{id:"choc",k:"choc",v:"5",x:176,y:170},
      {id:"bandeja",k:"bandeja",v:4,x:204,y:119,vapor:1,vdx:0,vdy:12,vn:2}];
    Object.assign(W.cq,{x:124-16,y:FREN-2-27,s:1,sobre:1,dy:0,vis:1,tiene:[CUCH(0)],lleno:0,espalda:0,piensa:null});},
  // abuela walks to her chair (round behind the table) and sets her plate close to the basket; then she goes out to the yard
  async plato33(o){const ab=G("abuela"),pl=ob("pl_abuela");const pr=(async()=>{await ruta("abuela",[[196,150],[188,ATRAS],[SILLA[0]+8,ATRAS]]);ab.dir=-1;ab.pose="offer";await wait(250);
      const y0=pl.y;for(let i=1;i<=4;i++){pl.y=y0+i*.5;await wait(TICK);}SFX.blip();await wait(250);ab.pose="idle";await sale("abuela");})();return corre(o,pr);},
  // a person comes in at the left end of the table (hand: he takes a roll from the basket and holds it up, cut open and empty)
  async viene33(o){const id=o.a,p=G(id);
    if(p.vis!==0&&p.sent){await levanta(id,LE[0],LE[1]);}else await entra(id,LE[0],LE[1],1);
    p.dir=1;p.pose="idle";
    if(o.rollo){p.pose="offer";await wait(220);quitaCesta();const r={k:"rollo",v:"ab",dx:22,dy:30,gx:17,gy:30};p.tiene=[r];SFX.blip();await wait(320);   // his hand takes a roll out of the basket
      p.dir=-1;p.pose="wave0";await mueveTiene(id,r,17,52,4);r.gx=11;r.gy=46;await wait(260);}},   // he holds it up on the side away from the basket, where nothing is behind it
  // he sets the roll he holds on the board and goes out to wash his hands (fin: he is already done)
  async sale33(o){const id=o.a,p=G(id),tb=ob("tabla");if(+o.fin)return;
    if(p.tiene&&p.tiene[0]&&p.tiene[0].k==="rollo"){const it=p.tiene[0];p.dir=1;p.pose="offer";it.dx=-24;await mueveTiene(id,it,22,30,4);it.gx=17;it.gy=30;await mueveTiene(id,it,20,18,3);tb.rollo={st:"ab",dx:0};p.tiene=[];p.pose="idle";SFX.blip();await wait(200);}
    await sale(id);},
  // the frog fills the roll on the board: his spoon takes the filling from its dish (the dish has less), he comes to the board, tips it into the roll and closes it. If there is no roll on the board yet he takes one from the basket first, in his hand
  async rellena33(o){const id=o.a,k=String(o.k),dish=ob(k==="choc"?"choc":"mant"),tb=ob("tabla"),q=W.cq,F0=ranaA;
    q.piensa=null;
    if(!tb.rollo){await ranaA(124,152);const r={k:"rollo",v:"ab",dx:-18,dy:16,gx:-13,gy:13};q.tiene=[r];quitaCesta();SFX.blip();await wait(300);   // he takes a roll out of the basket
      await ranaA(116,168);q.tiene=[];tb.rollo={st:"ab",dx:0};SFX.blip();await wait(250);q.tiene=[CUCH(0)];}
    // the spoon into the dish
    if(k==="choc")await ranaA(160,154);else await ranaA(124,168);
    const sp=q.tiene[0];sp.load="";SFX.blip();
    const bx0=sp.bx,by0=sp.by;const tx=(dish.x-cx()),ty=pies()-(dish.y-6);sp.bx=tx;sp.by=pies()-(dish.y-6);await wait(300);
    sp.load=k==="choc"?"c":"m";dish.v=String(Math.max(1,+dish.v-1));SFX.blip();await wait(300);
    // to the board, the spoon in his other hand
    await ranaA(116,168);Object.assign(sp,CUCH(1));sp.load=k==="choc"?"c":"m";await wait(350);
    SFX.blip();sp.load="";tb.rollo.con=k==="choc"?"c":"m";await wait(500);
    tb.rollo.st="ce";SFX.blip();await wait(350);Object.assign(sp,CUCH(0));
    await ranaA(124,168);},
  // he comes back from washing his hands: he takes the filled roll from the board, and goes to his chair (or stays at the end of the table)
  async regresa33(o){const id=o.a,p=G(id),tb=ob("tabla"),fin=id==="luis"||id==="carmen";
    await entra(id,LE[0],LE[1],1);p.dir=1;p.pose="offer";await wait(250);
    const r=tb.rollo;tb.rollo=null;const it={k:"rollo",v:r.st+(r.con?":"+r.con:""),dx:20,dy:18,gx:17,gy:26};p.tiene=[it];SFX.blip();await wait(250);p.pose="idle";await mueveTiene(id,it,21,26,3);
    if(!fin){const seat={abuelo:1,mama:2,papa:3,abuela:0}[id];await sienta(id,seat);const it2=p.tiene[0];if(it2){it2.dx=19;it2.dy=14;}}
    else if(id==="luis"){await mueve("luis",CAR[0],CAR[1]);p.dir=1;}},
  // he bites the roll: right, he chews happily and sets it down on his plate; wrong, he makes a face and sets it down on his plate, spoiled
  async come33(o){const id=o.a,p=G(id),fin=id==="luis"||id==="carmen",pl=fin?null:ob("pl_"+id);const pr=(async()=>{
      const it=(p.tiene||[])[0];if(!it)return;const v=it.v,con=String(v).split(":")[1];
      p.tiene=[];p.come={k:"rollo",v:v,dx:13};SFX.blip();await wait(450);   // the roll at his mouth
      p.come={k:"rollo",v:"mo:"+con,dx:13};await wait(350);
      if(+o.bien){await wait(300);}
      else{p.cara="mal";SFX.bonk();p.dy=-2;await wait(250);p.dy=0;await wait(500);}
      p.come=null;
      const r={st:"mo",con,dx:0,mal:+o.bien?0:1};
      if(fin){if(id==="carmen"&&!+o.bien){ob("tabla").malos.push(r);}else p.tiene=[{k:"rollo",v:"mo:"+con,dx:21,dy:24}];}
      else{const rs=ROLLOS(pl);r.dx=rs.length?6:0;if(rs.length)rs[0].dx=-6;rs.push(r);}
      SFX.blip();await wait(300);})();return corre(o,pr);},
  // the turn: abuela takes the tray off the stove, carries it to the basket and tips four hot rolls into it; she points at her own plate; papá and Carmen look in and go out again
  async turno33(o){const ab=G("abuela"),ce=ob("cesta"),tr=ob("bandeja");
    ab.dir=-1;ab.pose="offer";await wait(200);tr.vis=0;ab.tiene=[{k:"bandeja",v:4,dx:0,dy:24,e:1,gx:-16,gy:24}];ab.pose="idle";SFX.blip();await wait(300);
    await ruta("abuela",[[DER[0],DER[1]+8],[SILLA[1]+6,184],[LE[0]+2,LE[1]]]);ab.dir=1;ab.pose="offer";await mueveTiene("abuela",ab.tiene[0],31,28,4);await wait(250);
    const t0=ab.tiene[0];
    for(let i=0;i<4;i++){t0.v=String(3-i);await vuela({k:"rollo",v:"ab"},ab.x+31-12+i*8,ab.y-33,ce.x-8+i*7,ce.y-14,5);ce.v=(i+1)+":0";SFX.blip();await wait(80);}
    ab.tiene=[];ab.pose="idle";await wait(200);},
  async apunta33(){const ab=G("abuela");ab.dir=1;ab.pose="offer";SFX.blip();await wait(900);ab.pose="idle";},
  async sale33a(){await sale("abuela");},
  async miran33(){const pa=G("papa"),ca=G("carmen");pa.vis=ca.vis=0;await Promise.all([entra("papa",LE[0],LE[1],1),entra("carmen",CAR[0],CAR[1],1)]);await wait(600);await Promise.all([sale("papa"),sale("carmen")]);},
  // the ending: the family comes in and sits; abuela eats a roll that is left, plain; the other, if any, lies under the cloth. Everybody who got a roll has it in front of him
  async final33(o){const ce=ob("cesta"),ab=G("abuela"),n=nCesta();
    await Promise.all([sienta("abuelo",1),sienta("mama",2),sienta("papa",3),entra("luis",CAR[0],CAR[1],1).then(()=>{G("luis").dir=1;}),entra("carmen",LE[0],LE[1],1)]);
    G("carmen").dir=1;
    await sienta("abuela",0);V.pan=n>0?"1":"";
    if(n>0){ab.pose="offer";await wait(200);quitaCesta();ab.tiene=[{k:"rollo",v:"ce",dx:20,dy:14,arm:1,gx:19,gy:16}];SFX.blip();await wait(400);ab.tiene=[];ab.come={k:"rollo",v:"ce",dx:13};ab.pose="idle";await wait(800);ab.come=null;ob("pl_abuela").v="mi";}
    if(n>1){ab.pose="offer";await wait(200);ce.v="1:1";ce.vapor=0;SFX.blip();await wait(500);ab.pose="idle";}else ce.vapor=0;
    await wait(300);
    // each who got a roll eats from it, and puts it down again in front of him
    await Promise.all(["abuelo","mama","papa"].map(async id=>{const p=G(id),pl=ob("pl_"+id),rs=ROLLOS(pl).filter(r=>!r.mal);if(!rs.length)return;const r=rs[0],i=pl.rollos.indexOf(r);pl.rollos.splice(i,1);p.come={k:"rollo",v:"mo:"+r.con,dx:13};await wait(900);p.come=null;pl.rollos.splice(i,0,r);}));
    W.cq.hace=n>0?"come":null;await wait(500);},


  /* ----- story 34: Buen provecho ----- */
  // Lunch: yellow rice. Mamá (seat 1), Carmen (2) and abuelo (4) sit; papá's chair (3) and plate are empty; the baby sits in his high chair at the left end; Luis stands at the left end of the table, by the pot of rice, his plate and the frog's small plate; abuela is at the stove with the big spoon in her hand. The platter comes at the turn: abuela brings it.
  async inicio34(){const abu={k:"uten",ax:14,ay:24,bx:20,by:40,load:"",o:{rx:6,ry:4},arm:1,gx:14,gy:24};
    W.gente={mama:{x:SILLA[0],y:ASIENTO,sent:1,dir:1,tiene:[]},carmen:{x:SILLA[1],y:ASIENTO,sent:1,dir:1,tiene:[]},abuelo:{x:SILLA[3],y:ASIENTO,sent:1,dir:1,tiene:[]},papa:{vis:0},luis:{x:LE[0],y:LE[1],dir:1,tiene:[]},abuela:{x:FOGON[0],y:FOGON[1],dir:-1,tiene:[abu]}};W.sitio=SEAT34;
    const pl=(id,x,v)=>({id,k:"plato",x,y:FILA,v:v||"",rollos:[]});
    W.cosas=[pl("pl_mama",SILLA[0],"r"),pl("pl_carmen",SILLA[1],"r"),pl("pl_papa",SILLA[2]),pl("pl_abuelo",SILLA[3],"r"),
      {id:"pl_luis",k:"plato",x:PLUIS[0],y:PLUIS[1],v:"r",rollos:[]},{id:"pl_rana",k:"platito",x:PRANA[0],y:PRANA[1]},
      {id:"olla",k:"olla",v:"lleno",x:OLLA[0],y:OLLA[1],vapor:1},{id:"silla_bebe",k:"sillaBebe",v:"1",x:HIJA[0],y:HIJA[1]},{id:"fuente",k:"fuente",x:98,y:OLLA[1],montones:[],vis:0}];
    Object.assign(W.cq,{x:CASA34[0]-16,y:CASA34[1]-27,s:1,sobre:1,dy:0,vis:1,tiene:[],lleno:0,espalda:0,piensa:null,nube:[150,134],ndir:1});},
  // everybody holds a fork up and waits; then they eat
  async tenedores34(o){[["mama",46],["carmen",39],["abuelo",46],["luis",42]].forEach(a=>{const p=G(a[0]);p.pose="wave0";p.tiene=[TENE("tenedor",17,a[1],{e:1})];});SFX.blip();await wait(500);},
  async come34(o){const pr=(async()=>{["mama","carmen","abuelo"].forEach(id=>{const p=G(id);p.tiene=[];p.pose="idle";p.come={k:"tenedor",dx:11};});await wait(1200);["mama","carmen","abuelo"].forEach(id=>{G(id).come=null;});})();return corre(o,pr);},
  // Luis eats his last forkfuls: his plate is clean
  async luisCome34(o){const l=G("luis"),pl=ob("pl_luis");const pr=(async()=>{l.tiene=[];l.pose="idle";l.come={k:"tenedor",dx:11};await wait(1100);l.come=null;pl.v="";})();return corre(o,pr);},
  // abuela walks to Luis with the big spoon and gives it to him; he takes it; she goes back to the stove
  async cuchara34(o){const ab=G("abuela"),l=G("luis");
    await ruta("abuela",[[DER[0],DER[1]+10],[110,192],[46,192]]);ab.dir=1;ab.pose="offer";ab.tiene=[{k:"uten",ax:18,ay:27,bx:36,by:33,load:"",o:{rx:6,ry:4},arm:1,gx:18,gy:27}];SFX.blip();await wait(450);
    const b=[46+36-l.x,l.y-(192-33)];ab.tiene=[];l.tiene=[GRANDE(b[0],b[1])];const r=REPOSO();await bolaA(luisSp(),r[0],r[1],5);ab.pose="idle";await wait(250);
    await ruta("abuela",[[110,192],[DER[0],DER[1]+10],[FOGON[0],FOGON[1]]]);ab.dir=-1;},
  // Luis: sirve (he serves himself one mound onto his plate), come (he eats it), cuchara (he lifts a mound onto the big spoon and holds it out to the frog: tiende), entrega (he hands the frog the spoon with the mound on it); de "p": the mound comes from papá's three
  async luis34(o){const l=G("luis"),pl=ob("pl_luis"),pr=(async()=>{
      if(!luisSp())l.tiene=[GRANDE(...REPOSO())];const sp=luisSp(),g=o.de==="p"?"p":"m";
      const toma=async()=>{let s=fuenteMonton(g);if(s&&s.fu.x>200)s=null;if(g==="p"&&!s)s=fuenteMonton("m");const ol=ob("olla"),src=s?{x:s.x,y:s.y}:{x:ol.x,y:ol.y-18};await cucharaL(src.x,src.y+3,6);sp.load="monton";if(s)s.fu.montones.splice(s.fu.montones.indexOf(s.m),1);SFX.blip();await wait(250);};
      if(o.que==="sirve"){await toma();await cucharaL(PLUIS[0],PLUIS[1]-6,6);sp.load="";pl.v="o";SFX.blip();await wait(250);const r=REPOSO();await bolaA(sp,r[0],r[1],4);}
      else if(o.que==="come"){l.come={k:"tenedor",dx:11};pl.v="";SFX.blip();await wait(800);l.come=null;}
      else if(o.que==="cuchara"){await toma();const r=REPOSO();await bolaA(sp,r[0],r[1],5);await wait(250);}
      else if(o.que==="entrega"){await toma();const r=REPOSO();await bolaA(sp,r[0],r[1],5);await ranaA(130,168);const q=W.cq,bx=116-cx(),by=pies()-158;l.tiene=[];q.tiene=[cuchaRana(1,bx,by,"monton")];SFX.blip();await wait(300);}})();return corre(o,pr);},
  // a thought over the frog: what he would like (quiere) or his belly beside the clean plate (lleno). It stands on the tablecloth, where nobody sits.
  async piensa34(o){W.cq.piensa=o.k==="lleno"?{k:"barriga"}:{k:"montoncor"};SFX.blip();await wait(300);},
  async calla34(){W.cq.piensa=null;},
  // the mound on Luis's spoon goes onto the frog's plate (he tips the spoon over it) and he eats it
  async ranaCome34(o){const l=G("luis"),pl=ob("pl_rana"),q=W.cq;const pr=(async()=>{q.piensa=null;const sp=luisSp();if(sp){const b=enL(PRANA[0],PRANA[1]-8);await bolaA(sp,b[0],b[1],4);sp.load="";}pl.v="o";SFX.blip();await wait(300);if(sp){const r=REPOSO();await bolaA(sp,r[0],r[1],4);}
      q.hace="come";await wait(800);q.hace=null;pl.v="mi";if(o.lleno)q.lleno=1;if(o.entera){q.espalda=1;pl.v="mi";SFX.bonk();await wait(700);}})();return corre(o,pr);},
  async levantaRana34(){W.cq.espalda=0;SFX.blip();await wait(250);},
  // Luis eats the mound on the spoon too (the spoon goes up to his mouth)
  async luisCome2(o){const l=G("luis");const pr=(async()=>{W.cq.piensa=null;const sp=luisSp();if(sp){await bolaA(sp,13,38,5);sp.load="";}l.come={k:"tenedor",dx:11};SFX.blip();await wait(800);l.come=null;if(sp){const r=REPOSO();await bolaA(sp,r[0],r[1],4);}})();return corre(o,pr);},
  // Luis glances at papá's fork and takes one of papá's three for the frog (rana) or for himself (luis)
  async luisPapa34(o){const l=G("luis");await wait(450);
    if(o.para==="rana"){await acts.luis34({que:"cuchara",de:"p"});await acts.ranaCome34({});}
    else{await acts.luis34({que:"sirve",de:"p"});await acts.luis34({que:"come"});}},
  // steps 5 and 6: the three at the table; whoever says "Yo estoy lleno/llena" puts a hand on his belly
  async mano34(o){const p=G(o.a);p.pose=o.pose||"yo";SFX.blip();await wait(150);},
  async plato34(o){const pl=ob("pl_"+o.a);pl.v=o.v||"";},
  // the frog tips the mound on the spoon onto the plate of the one at his seat (he walks round to it with the spoon), where it mixes into his rice (mezcla), or the one eats it; then he gives the spoon back to Luis
  async tipa34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),q=W.cq,l=G("luis");const pr=(async()=>{q.piensa=null;const L=lado34(pl.x),sp=q.tiene[0];if(!sp)return;
      await ranaA(L.fx,L.fy);const izq=L.izq?1:0;Object.assign(sp,cuchaRana(izq,0,0,"monton"));const bx=pl.x-cx()+(izq?-2:2),by=pies()-(pl.y-10);sp.bx=(izq?-14:14);sp.by=14;await bolaA(sp,bx,by,5);
      sp.load="";if(+o.mezcla){pl.v="h";SFX.bonk();await wait(450);}else{pl.v="rm";SFX.blip();await wait(300);p.pose="idle";p.come={k:"tenedor",dx:11};await wait(800);p.come=null;pl.v="";}
      await ranaA(130,168);const b=REPOSO();l.tiene=[GRANDE(b[0],b[1])];q.tiene=[];SFX.blip();await wait(200);})();return corre(o,pr);},
  // whoever was full only now puts a hand on his belly and pushes his plate a little away
  async llenoAhora34(o){const p=G(o.a),pl=ob("pl_"+o.a);p.pose="yo";pl.y+=5;SFX.blip();await wait(500);},
  // gets up and says it to the table (a line follows). mamá goes to the high chair and takes the baby (in the game she goes out with him); with plato he carries his plate to the counter and leaves it in the sink; otherwise he goes out
  async levanta34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),x0=p.x,sb=ob("silla_bebe"),juego=!!W.turno;p.sent=0;p.y=ATRAS;p.pose="idle";SFX.blip();await wait(300);
    await ruta(id,[[Math.max(72,x0-3),ATRAS]]);
    if(id==="mama"){await ruta(id,[[70,ATRAS+2]]);p.dir=-1;sb.v="0";p.tiene=[TENE("bebe",18,30,{arm:1,gx:12,gy:26})];SFX.blip();await wait(250);p.dir=1;if(juego)await sale(id);}
    else if(+o.plato){pl.vis=0;p.pose="wave0";p.tiene=[TENE("plato",23,50,{v:pl.v})];await ruta(id,[[50,ATRAS+6],[58,150]]);p.dir=1;SFX.blip();await wait(200);p.tiene=[];p.pose="idle";Object.assign(pl,{x:60,y:118,z:119,vis:1});await wait(250);}
    else{await sale(id);}},
  // she comes back to her chair: mamá puts the baby back in his chair first; Carmen takes her plate from the sink
  async vuelve34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),sb=ob("silla_bebe"),seat=SEAT34[id];
    if(id==="mama"){p.dir=-1;await wait(200);sb.v="1";p.tiene=[];SFX.blip();await wait(250);p.dir=1;await mueve(id,SILLA[0]-3,ATRAS);await mueve(id,SILLA[0],ASIENTO,3);p.sent=1;p.y=ASIENTO;p.dir=1;p.pose="idle";SFX.blip();return;}
    if(+o.plato){p.pose="offer";await wait(200);pl.vis=0;p.pose="wave0";p.tiene=[TENE("plato",23,50,{v:pl.v})];SFX.blip();await wait(250);await ruta(id,[[62,ATRAS+4],[SILLA[seat]-3,ATRAS]]);await mueve(id,SILLA[seat],ASIENTO,3);p.sent=1;p.y=ASIENTO;p.dir=1;p.pose="idle";p.tiene=[];Object.assign(pl,{x:SILLA[seat],y:FILA,z:null,vis:1});SFX.blip();}},
  // after a miss: a second mound, from papá's three, for the one who asked: Luis takes it with the spoon, hands it to the frog, the frog tips it onto his plate and he eats it
  async papaB34(o){await acts.luis34({que:"entrega",de:"p"});await acts.tipa34({a:o.a});},
  async mira34(o){const l=G("luis");l.dir=1;await wait(500);},
  // the turn. Luis steps aside. Abuela walks to the pot, lifts it with its spoon, gives a small spoon of rice to each of the three at the table (she reaches up to each plate from the front edge), goes out of the door with the pot and comes back with the platter; she sets the platter where the pot was and scrapes the pot out onto it (seven mounds); she tips the pot towards us, empty; she pushes three of the mounds to papá's end and lays his fork on them; she goes out to the gate, with the pot
  async turno34(o){const ab=G("abuela"),l=G("luis"),ol=ob("olla"),fu=ob("fuente");W.turno=1;
    await mueve("luis",46,192);l.dir=1;
    ab.tiene=[];await ruta("abuela",[[DER[0],DER[1]+10],[96,186],[LE[0]+4,LE[1]+2]]);ab.dir=1;ab.pose="offer";await wait(250);
    ol.v="lleno0";ab.pose="idle";const pot=TENE("olla",30,22,{v:"lleno0",e:1}),cu={k:"uten",ax:18,ay:30,bx:40,by:40,load:"monton",o:{rx:6,ry:4},arm:1,gx:18,gy:30};ol.vis=0;ab.tiene=[pot,cu];SFX.blip();await wait(400);
    for(const id of ["mama","carmen","abuelo"]){const pl=ob("pl_"+id),px=pl.x,sx=px<130?px+12:px-12;await ruta("abuela",[[sx,184]]);ab.dir=px>sx?1:-1;ab.y=184;const d=ab.dir;cu.bx=d*(px-sx)>0?(px-sx)*d:0;
      cu.load="monton";const bx=d*(px-ab.x),by=184-(pl.y-6);await bolaA(cu,bx,by,5);cu.load="";pl.v="r";SFX.blip();await wait(300);await bolaA(cu,22,36,3);}
    ab.dir=-1;await ruta("abuela",[[110,186],[LE[0]+4,LE[1]+4],[48,186],[PUERTA[0]+4,184]]);ab.vis=0;await wait(500);
    ab.vis=1;ab.x=PUERTA[0];ab.y=184;ab.dir=1;ab.tiene=[TENE("fuente",2,26,{e:1}),pot];cu.load="";pot.dx=26;pot.dy=18;await mueve("abuela",LE[0]+2,LE[1]+2);ab.pose="offer";await wait(300);
    await mueveTiene("abuela",ab.tiene[0],32,26,5);ab.tiene=[pot];fu.vis=1;fu.montones=[];fu.tenedor={dx:-20,dy:5};SFX.blip();await wait(250);   // the platter is set down where the pot was
    ab.pose="idle";pot.v="lleno0";await mueveTiene("abuela",pot,30,44,5);pot.v="lleno0";
    const xs=[-16,-6,4,14,-8,2,12],ys=[-6,-6,-6,-6,-6,-6,-6];for(let i=0;i<7;i++){fu.montones.push({dx:xs[i],dy:ys[i],g:i<4?"m":"p"});SFX.blip();await wait(220);}
    pot.v="vacio";await mueveTiene("abuela",pot,26,34,4);SFX.blip();await wait(900);   // she tips the pot towards us: empty
    // three mounds go to papá's end, with a gap, and his fork on them
    for(const m of fu.montones.filter(m=>m.g==="p")){m.dy=-16;}await wait(300);fu.montones.filter(m=>m.g==="p").forEach((m,i)=>m.dx=[-2,8,18][i]);fu.montones.filter(m=>m.g==="m").forEach((m,i)=>{m.dx=[-18,-9,0,9][i];m.dy=-6;});SFX.blip();await wait(500);
    fu.tenedor={dx:8,dy:14};SFX.blip();await wait(500);
    ab.dir=-1;ab.tiene=[pot];await ruta("abuela",[[48,186],[PUERTA[0]+4,184]]);ab.vis=0;ab.tiene=[];
    await mueve("luis",LE[0],LE[1]);l.dir=1;},
  // papá comes in with abuela; he sits; abuela takes the big spoon from Luis and serves what is left at his end of the platter onto his plate, one mound at a time
  async final34(o){const ab=G("abuela"),pa=G("papa"),l=G("luis"),fu=ob("fuente"),pl=ob("pl_papa");pa.vis=1;pa.sent=0;pa.x=PUERTA[0];pa.y=ATRAS;pa.tiene=[];ab.vis=1;ab.x=PUERTA[0]-4;ab.y=188;ab.dir=1;ab.tiene=[];
    const pr=(async()=>{await mueve("abuela",44,190);ab.dir=1;})();await sienta("papa",2);await pr;
    const n=fu.montones.filter(m=>m.g==="p").length;
    // Luis gives abuela the big spoon
    const sp=luisSp();if(sp){await bolaA(sp,38,26,4);}ab.pose="offer";await wait(250);if(sp){l.tiene=[];ab.tiene=[{k:"uten",ax:18,ay:27,bx:36,by:30,load:"",o:{rx:6,ry:4},arm:1,gx:18,gy:27}];}ab.pose="idle";SFX.blip();await wait(300);
    await ruta("abuela",[[118,184]]);ab.dir=1;const cu=ab.tiene[0];
    for(let i=0;i<n;i++){const m=fu.montones.filter(m=>m.g==="p")[0];if(!m)break;await bolaA(cu,fu.x+m.dx-ab.x,184-(fu.y+m.dy-4),5);cu.load="monton";fu.montones.splice(fu.montones.indexOf(m),1);SFX.blip();await wait(250);await bolaA(cu,pl.x-ab.x,184-(pl.y-8),5);cu.load="";pl.v="p"+(i+1);SFX.blip();await wait(300);}
    fu.tenedor=null;V.pmont=String(n);await wait(300);
    await ruta("abuela",[[LE[0]+30,186],[DER[0],DER[1]+8],[FOGON[0],FOGON[1]]]);ab.dir=-1;ab.tiene=[];},
  async papaCome34(o){const pa=G("papa"),pl=ob("pl_papa");const pr=(async()=>{pa.come={k:"tenedor",dx:11};await wait(1100);if(o.fin){pa.come=null;pl.v="mi";}})();return corre(o,pr);},
  async papaMira34(){const pa=G("papa");pa.dir=1;pa.pose="idle";await wait(900);},

  /* ----- story 35: Café con azúcar ----- */
  // The table is cleared. Abuelo (chair 2) and papá (chair 4) have black coffee; Luis and Carmen hold cups of hot milk at the left end; the frog stands by the sugar bowl with its big spoon in his hand, his own small cup by him. On the stove: the big coffee pot, the milk pan; the little pouring pot on the shelf. Canelo lies by his empty bowl. Cups: a blue cup with a handle; black is coffee, brown much coffee in milk, tan a little, white milk, grey empty; a spoon stands in a sweetened cup.
  async inicio35(){const taza=(x)=>[TENE("taza",0,19,{v:"leche",vapor:1,arm:1,gx:9,gy:17})];
    W.gente={abuelo:{x:SILLA[1],y:ASIENTO,sent:1,dir:1,tiene:[]},papa:{x:SILLA[3],y:ASIENTO,sent:1,dir:-1,tiene:[]},luis:{x:LE[0]+2,y:LE[1]+2,dir:1,pose:"idle",tiene:taza()},carmen:{x:CAR[0],y:CAR[1],dir:1,tiene:taza()},abuela:{x:FOGON[0],y:FOGON[1],dir:-1,tiene:[]},mama:{vis:0}};W.sitio={abuelo:1,papa:3};
    W.cosas=[{id:"t_abuelo",k:"taza",x:SILLA[1],y:FILA,v:"negro",vapor:1,vdy:20},{id:"t_papa",k:"taza",x:SILLA[3],y:FILA,v:"negro",vapor:1,vdy:20},
      {id:"t_luis",k:"taza",x:K1[0],y:K1[1],v:"leche",vapor:1,vdy:20,vis:0},{id:"t_carmen",k:"taza",x:K2[0],y:K2[1],v:"leche",vapor:1,vdy:20,vis:0},
      {id:"azucarera",k:"azucarera",x:AZU[0],y:AZU[1]},{id:"t_rana",k:"taza",x:TRANA[0],y:TRANA[1],v:"vacia",vapor:0},{id:"t_abuela",k:"taza",x:TABU[0],y:TABU[1],v:"vacia",vapor:0},
      {id:"cafetera",k:"cafetera",x:196,y:118,vapor:1,vdx:-2,vdy:30,vn:1},{id:"cazo",k:"cazo",v:"1",x:217,y:118},{id:"jarrita",k:"jarrita",x:207,y:97},{id:"tazon",k:"tazon",v:"0",x:TAZON[0],y:TAZON[1]}];
    W.perro={x:CANELO[0],y:CANELO[1],pose:"lie",dir:-1};W.pote={};
    Object.assign(W.cq,{x:CASA35[0]-16,y:CASA35[1]-27,s:1,sobre:1,dy:0,vis:1,tiene:[SPA()],lleno:0,espalda:0,piensa:null,nube:[84,124],ndir:1});},
  // abuela takes the big pot from the stove and walks behind the table to the empty chair between the two men
  async trae35(o){const ab=G("abuela"),ce=ob("cafetera");ab.dir=-1;ab.pose="offer";await wait(200);ce.vis=0;ab.tiene=[TENE("cafetera",0,15,{arm:1,gx:12,gy:14})];ab.dir=-1;ab.pose="idle";SFX.blip();await wait(250);
    await ruta("abuela",[[200,146],[188,ATRAS],[150,ATRAS],[138,ASIENTO-2]]);ab.dir=-1;},
  async vuelve35(o){const ab=G("abuela"),ce=ob("cafetera");ab.tiene=[TENE("cafetera",0,15,{arm:1,gx:12,gy:14})];await ruta("abuela",[[150,ATRAS],[188,ATRAS],[200,146],[FOGON[0],FOGON[1]]]);ab.dir=-1;ab.pose="offer";await wait(200);ab.tiene=[];ce.vis=1;ab.pose="idle";SFX.blip();},
  // the men hold their cups out over the table; or set them down
  async tienden35(o){for(const id of String(o.a).split(",")){const t=copa(id),p=G(id);t.vis=0;p.tiene=[TENE("taza",4,-6,{v:t.v,vapor:t.vapor,arm:1,gx:12,gy:-4,sp:t.sp})];}SFX.blip();await wait(400);},
  async bajan35(o){for(const id of String(o.a).split(",")){const t=copa(id),p=G(id),it=p.tiene&&p.tiene[0];if(it){t.v=it.v;t.vapor=it.vapor;}p.tiene=[];t.vis=1;}await wait(200);},
  // the frog tips the heaped spoon into a cup (mal: it already had its sugar: two heaps), stirs; the sweetened cup keeps its spoon
  async azucar35(o){const id=o.a,t=copa(id),q=W.cq,p=G(id),mal=+o.mal;const pr=(async()=>{const hold=p.tiene&&p.tiene[0],cup=hold?hold:null,dd=p.dir<0?-1:1;const px=cup?p.x+dd*cup.dx:t.x,top=cup?p.y-cup.dy-9:t.y-17;
      await ranaA(px-22,166);const sp=q.tiene.find(i=>i.k==="uten");await bolaA(sp,22,166-top+6,5);
      sp.load="";SFX.blip();for(let i=0;i<3;i++){W.vuelos.push({k:"granos",x:px+1,y:top-8+i*4,e:1});await wait(110);W.vuelos.pop();}
      if(cup){if(mal)cup.v="azu";else cup.sp=1;}else{if(mal)t.v="azu";else t.sp=1;}
      for(let k=0;k<3;k++){sp.bx=22+(k%2?3:-3);await wait(TICK);}await bolaA(sp,30,22,3);})();return corre(o,pr);},
  // abuela pours coffee into a cup from the big pot (mal: the last finger, into the same cup)
  async cafe35(o){const id=o.a,t=copa(id),ab=G("abuela"),p=G(id);const pr=(async()=>{const cup=p.tiene&&p.tiene[0],dd=p.dir<0?-1:1,cxx=cup?p.x+dd*cup.dx:t.x,left=cxx<ab.x,tx=cxx+(left?7:-7),ty=cup?p.y-cup.dy-14:t.y-24;ab.dir=left?-1:1;
      const up=ab.tiene[0],tilt=vierteItem(ab,"cafetera","",tx,ty,!left,12,"#2A160C");ab.tiene=[tilt];SFX.blip();await wait(+o.dedo?600:1000);
      if(cup){if(+o.mal)cup.v="azu";else if(+o.llena){cup.v="negro";cup.vapor=1;}}else{if(+o.mal)t.v="azu";}
      ab.tiene=[up];await wait(150);})();return corre(o,pr);},
  async llena35(){const q=W.cq,sp=q.tiene.find(i=>i.k==="uten");await ranaA(CASA35[0],CASA35[1]);Object.assign(sp,SPA());SFX.blip();await wait(250);},
  async prueba35(o){for(const id of String(o.a).split(",")){const p=G(id);p.dy=-2;await wait(150);p.dy=0;await wait(150);}},
  // he looks into his cup, and pushes it to the middle of the table
  async empuja35(o){const id=o.a,p=G(id),it=p.tiene&&p.tiene[0],t=copa(id);await wait(500);p.cara="mal";SFX.bonk();
    if(it){const dd=p.dir<0?-1:1;it.vapor=0;it.v="azu";t.v="azu";t.vapor=0;t.x=p.x+dd*it.dx;t.y=p.y-it.dy+9;t.vis=1;it.vis=0;}const x0=t.x,y0=t.y;p.tiene=[TENE("brazo",0,0,{k:"brazo",gx:8,gy:12,sh:1})];for(let i=1;i<=8;i++){t.x=x0+(140-x0)*i/8;t.y=y0+(138-y0)*i/8;p.tiene[0].gx=8+(t.x-x0)*(p.dir<0?-1:1);p.tiene[0].gy=12+(y0-t.y);await wait(TICK);}p.tiene=[];await wait(300);p.cara=null;},
  // abuela gives the frog the little pot: she takes it from the shelf and sets it where he can take it; the children set their cups of milk in front of the frog (ponen), go out (salen), come back (vuelven) and drink (toman)
  async pote35(o){const ab=G("abuela"),jt=ob("jarrita"),q=W.cq;ab.dir=-1;ab.pose="wave0";await wait(250);jt.vis=0;ab.tiene=[TENE("jarrita",18,54,{arm:1,gx:13,gy:46})];SFX.blip();await wait(250);ab.pose="idle";
    await ruta("abuela",[[DER[0],DER[1]+6],[TRANA[0]+36,186]]);ab.dir=-1;ab.pose="offer";await wait(250);
    await ranaA(158,168);ab.tiene=[];q.tiene.push({k:"jarrita",dx:-14,dy:14,e:1,gx:-12,gy:12});SFX.blip();await wait(300);ab.pose="idle";
    await ruta("abuela",[[DER[0],DER[1]+6],[FOGON[0],FOGON[1]]]);ab.dir=-1;await ranaA(CASA35[0],CASA35[1]);},
  async ninos35(o){const l=G("luis"),ca=G("carmen"),tl=copa("luis"),tc=copa("carmen");
    if(o.que==="ponen"){l.pose="offer";await wait(200);l.tiene=[];tl.v="leche";tl.vapor=1;tl.vis=1;SFX.blip();await wait(300);l.pose="idle";
      await ruta("carmen",[[84,190]]);ca.dir=1;ca.pose="offer";await wait(200);ca.tiene=[];tc.v="leche";tc.vapor=1;tc.vis=1;SFX.blip();await wait(300);ca.pose="idle";}
    else if(o.que==="salen"){await Promise.all([sale("luis"),sale("carmen")]);}
    else if(o.que==="vuelven"){await Promise.all([entra("luis",LE[0],LE[1],1),entra("carmen",CAR[0],CAR[1],1)]);}
    else if(o.que==="toman"){const pr=(async()=>{l.pose="offer";await wait(200);tl.vis=0;l.tiene=[TENE("taza",0,19,{v:tl.v,vapor:tl.vapor})];l.pose="idle";SFX.blip();await wait(250);
        await ruta("carmen",[[84,190]]);ca.pose="offer";await wait(200);tc.vis=0;ca.tiene=[TENE("taza",0,19,{v:tc.v,vapor:tc.vapor})];ca.pose="idle";SFX.blip();await wait(250);
        l.tiene=[];ca.tiene=[];l.bebe2=tl.v;ca.bebe2=tc.v;SFX.blip();await wait(1000);l.bebe2=ca.bebe2=null;tl.v=tc.v="vacia";tl.vapor=tc.vapor=0;
        l.pose="offer";await wait(150);tl.vis=1;l.pose="idle";ca.pose="offer";await wait(150);tc.vis=1;ca.pose="idle";})();return corre(o,pr);}},
  // the frog pours as told: a long pour (mucho) turns the milk brown; a splash (poco) turns it pale
  async vierte35(o){const id=o.a,t=copa(id),q=W.cq,mucho=o.cant==="mucho",izq=t.x<90;const fx=izq?98:92,fy=146;await ranaA(fx,fy);
    const jt=q.tiene.find(i=>i.k==="jarrita"||i.k==="tiltjarrita"),up={k:"jarrita",dx:-14,dy:14,e:1,gx:-12,gy:12};
    const tilt=vierteItem("rana","jarrita","",t.x,t.y-22,!izq,12,"#3E2414");q.tiene=q.tiene.filter(i=>i!==jt);q.tiene.push(tilt);SFX.blip();
    await wait(mucho?300:150);liq(id,"palido",1);if(mucho){await wait(700);liq(id,"marron",1);await wait(400);}else await wait(250);
    q.tiene=q.tiene.filter(i=>i!==tilt);q.tiene.push(up);await wait(150);await ranaA(CASA35[0],CASA35[1]);},
  // the frog's own cup, the thoughts and answers of step 6
  async piensa35(o){W.cq.piensa=o.k?{k:"taza",v:o.k,e:1}:null;if(o.k)SFX.blip();await wait(250);},
  async sirve6(o){const mucho=o.cant==="mucho",q=W.cq,ab=G("abuela"),t=copa("rana"),jt=q.tiene.find(i=>i.k==="jarrita"),cz=ob("cazo"),pote=ob("jarrita");q.piensa=null;
    // the frog sets the little pot down beside his cup; abuela comes for it, pours from it, then milk from the pan
    if(jt){await ranaA(160,168);q.tiene=q.tiene.filter(i=>i!==jt);Object.assign(pote,{x:POTE[0],y:POTE[1],vis:1});SFX.blip();await wait(250);await ranaA(CASA35[0],CASA35[1]);}
    ab.dir=-1;ab.pose="wave0";await wait(200);cz.vis=0;ab.tiene=[TENE("cazo",20,26,{v:"1",arm:1,gx:12,gy:26})];SFX.blip();await wait(250);ab.pose="idle";
    await ruta("abuela",[[DER[0],DER[1]+2]]);ab.dir=-1;ab.pose="offer";await wait(200);pote.vis=0;
    const pan=ab.tiene[0],pot=vierteItem(ab,"jarrita","",t.x,t.y-24,false,14,"#2A160C");ab.tiene=[pan,pot];SFX.blip();await wait(mucho?300:150);liq("rana","negro",1);await wait(mucho?900:350);
    Object.assign(pote,{x:POTE[0],y:POTE[1],vis:1});ab.tiene=[pan];await wait(200);
    const mi=vierteItem(ab,"cazo","1",t.x,t.y-24,false,14,"#F6F1E4");ab.tiene=[mi];SFX.blip();await wait(300);liq("rana",mucho?"marron":"palido",1);await wait(mucho?500:1000);
    ab.tiene=[];cz.vis=1;ab.pose="idle";await ruta("abuela",[[FOGON[0],FOGON[1]]]);ab.dir=-1;SFX.blip();},
  async rana35bebe(o){const q=W.cq,t=copa("rana");q.hace="bebe";const v=t.v;t.vis=0;q.tiene=q.tiene.filter(i=>i.k==="uten");q.tiene.push({k:"taza",v,dx:-14,dy:14,e:1,gx:-12,gy:12,vapor:1});await wait(900);q.hace=null;q.tiene=q.tiene.filter(i=>i.k==="uten");t.vis=1;t.v="vacia";t.vapor=0;SFX.blip();await wait(200);},
  // the turn: the cups are empty; abuela pours the last of the big pot (a half cup each for abuelo, papá and herself), the men sweeten and nod; the last milk into the children's cups; the little pot, full, goes up on the shelf; she sits down at the stove with her own cup
  async turno35(o){const ab=G("abuela"),l=G("luis"),ca=G("carmen"),q=W.cq,ce=ob("cafetera"),cz=ob("cazo");
    ["abuelo","papa","rana"].forEach(id=>{liq(id,"vacia",0);const t=copa(id);t.sp=0;});copa("abuela").vis=1;copa("abuela").v="vacia";
    await Promise.all([sale("luis"),sale("carmen")]);
    await acts.trae35({});
    await acts.tienden35({a:"abuelo,papa"});for(const id of ["abuelo","papa"]){await acts.cafe35({a:id,dedo:0,llena:1});}await acts.bajan35({a:"abuelo,papa"});
    // her own cup, at the right end, from the pot too
    await acts.vuelve35({});ab.pose="offer";await wait(150);ce.vis=0;ab.tiene=[TENE("cafetera",0,24,{arm:1,gx:12,gy:22})];await wait(200);const tab=copa("abuela"),tilt=vierteItem(ab,"cafetera","",tab.x,tab.y-24,false,12,"#2A160C");ab.tiene=[tilt];await mueve("abuela",DER[0],DER[1]-4);ab.dir=-1;
    SFX.blip();await wait(700);liq("abuela","negro",1);ab.tiene=[];ce.vis=1;W.pote.dedo=1;
    for(const id of ["abuelo","papa"]){const t=copa(id);await acts.tienden35({a:id});await acts.azucar35({a:id,mal:0});await acts.llena35();await acts.bajan35({a:id});}
    await acts.prueba35({a:"abuelo,papa"});
    await acts.ninos35({que:"vuelven"});
    // the milk into the children's cups
    ab.dir=-1;ab.pose="wave0";await wait(200);cz.vis=0;ab.tiene=[TENE("cazo",20,26,{v:"1",arm:1,gx:12,gy:26})];SFX.blip();await wait(250);ab.pose="idle";
    await ruta("abuela",[[DER[0],DER[1]+10],[96,188]]);ab.dir=-1;await wait(200);
    for(const [id,cup] of [["carmen",K2],["luis",K1]]){const t=copa(id),pn=ab.tiene[0];t.vis=1;t.v="vacia";const mi=vierteItem(ab,"cazo","1",cup[0],cup[1]-24,false,14,"#F6F1E4");ab.tiene=[mi];await mueve("abuela",cup[0]+18,188);ab.dir=-1;SFX.blip();await wait(600);liq(id,"leche",1);ab.tiene=[pn];await wait(200);}
    W.pote.leche=1;
    // the little pot, full, goes up on the shelf; abuela sits down at the stove with her cup
    ab.tiene=[];cz.v="1";cz.vis=1;await ruta("abuela",[[DER[0],DER[1]+10],[FOGON[0],FOGON[1]]]);await mueve("luis",LE[0],LE[1]);await mueve("carmen",CAR[0],CAR[1]);},
  async sientaAb35(o){const ab=G("abuela"),t=copa("abuela");ab.dir=-1;t.vis=0;ab.sent=1;ab.taburete=1;ab.y=FOGON[1]+8;ab.x=FOGON[0]-6;ab.tiene=[TENE("taza",16,22,{v:t.v,vapor:t.v!=="vacia"?1:0})];SFX.blip();await wait(300);},
  // round A: abuela gets up with the big pot and its last pour; the men hold their half cups out
  async turnoA35(o){const ab=G("abuela"),ce=ob("cafetera");ab.sent=0;ab.taburete=0;ab.tiene=[];ab.y=FOGON[1];SFX.blip();await wait(200);ab.pose="offer";ce.vis=0;ab.tiene=[TENE("cafetera",0,15,{arm:1,gx:12,gy:14})];ab.pose="idle";await wait(200);
    await ruta("abuela",[[200,146],[188,ATRAS],[150,ATRAS],[138,ASIENTO-2]]);ab.dir=-1;await acts.tienden35({a:"abuelo,papa"});await acts.llena35();},
  // after A: abuela puts the empty big pot on the stove, takes the little pot down from the shelf and hands it to the frog, full; he stands it by his small cup
  async despuesA35(o){const ab=G("abuela"),jt=ob("jarrita"),ce=ob("cafetera"),q=W.cq;await acts.bajan35({a:"abuelo,papa"});ce.v="";
    await acts.vuelve35({});ab.pose="wave0";await wait(250);jt.vis=0;ab.tiene=[TENE("jarrita",18,54,{arm:1,gx:13,gy:46})];SFX.blip();await wait(250);ab.pose="idle";
    await ruta("abuela",[[DER[0],DER[1]+6]]);ab.dir=-1;ab.pose="offer";await wait(250);ab.tiene=[];Object.assign(jt,{x:POTE[0],y:POTE[1],vis:1});SFX.blip();await wait(250);ab.pose="idle";
    await ranaA(CASA35[0],CASA35[1]);await mueve("abuela",FOGON[0]-6,FOGON[1]+8);ab.dir=-1;ab.sent=1;ab.taburete=1;ab.tiene=[TENE("taza",16,22,{v:copa("abuela").v,vapor:1})];},
  // round B: abuela gets up, takes the little pot from beside his cup and pours from it what he said; tips what is left into her own cup, fills his cup to the brim with milk from the pan; tips the rest of the pan into Canelo's bowl; the pan is empty
  async sirveB35(o){const ab=G("abuela"),mucho=String(o.cant).replace(/^di_/,"")==="mucho",jt=ob("jarrita"),cz=ob("cazo"),tz=ob("tazon"),pe=W.perro,t=copa("rana"),ta=copa("abuela");W.cq.piensa=null;
    ab.sent=0;ab.taburete=0;ab.tiene=[];ab.y=FOGON[1];ab.x=FOGON[0];ab.dir=-1;ta.vis=1;ta.v=ta.v||"vacia";await wait(200);
    ab.pose="wave0";cz.vis=0;ab.tiene=[TENE("cazo",20,26,{v:"1",arm:1,gx:12,gy:26})];SFX.blip();await wait(250);ab.pose="idle";
    await ruta("abuela",[[DER[0],DER[1]+2]]);ab.dir=-1;ab.pose="offer";await wait(200);jt.vis=0;
    const pan=ab.tiene[0];let pot=vierteItem(ab,"jarrita","",t.x,t.y-24,false,14,"#2A160C");ab.tiene=[pan,pot];SFX.blip();await wait(mucho?300:150);liq("rana","negro",1);await wait(mucho?900:350);
    pot=vierteItem(ab,"jarrita","",ta.x,ta.y-24,false,14,"#2A160C");ab.tiene=[pan,pot];SFX.blip();await wait(500);ta.v="negro";ta.vapor=1;   // what is left goes into her own cup
    Object.assign(jt,{x:POTE[0],y:POTE[1],vis:1});
    const mi=vierteItem(ab,"cazo","1",t.x,t.y-24,false,14,"#F6F1E4");ab.tiene=[mi];SFX.blip();await wait(300);liq("rana",mucho?"marron":"palido",1);await wait(mucho?500:1000);
    // the rest of the milk goes into Canelo's bowl, and Canelo laps it
    await ruta("abuela",[[TAZON[0]+18,184]]);ab.dir=-1;const mi2=vierteItem(ab,"cazo","1",TAZON[0],TAZON[1]-26,false,18,"#F6F1E4");ab.tiene=[mi2];SFX.blip();await wait(500);tz.v="1";ab.tiene=[TENE("cazo",16,24,{v:"0"})];
    pe.pose="eat";pe.x=TAZON[0]-28;pe.y=TAZON[1];pe.dir=1;await wait(900);tz.v="0";pe.pose="lie";pe.x=CANELO[0];pe.y=CANELO[1];pe.dir=-1;
    ab.tiene=[];cz.v="0";cz.vis=1;await ruta("abuela",[[DER[0],DER[1]+2]]);ab.dir=-1;W.pote.vacia=1;W.pote.pan=1;},
  async pruebaB35(o){const q=W.cq,t=copa("rana");q.hace="come";await wait(500);q.hace=null;t.vapor=0;SFX.bonk();await wait(500);},
  // after a miss in B: abuela drinks her own cup off, happy (a big pleased "ah", a hand on her chest), then shows her empty cup, the little pot and the pan
  async bebeAb35(o){const ab=G("abuela"),t=copa("abuela");ab.vis=1;ab.sent=0;ab.taburete=0;ab.pose="idle";t.vis=0;ab.tiene=[TENE("taza",18,36,{v:"negro",vapor:1,arm:1,gx:12,gy:32})];ab.abre=1;ab.pose="bless";SFX.blip();await wait(900);ab.tiene=[TENE("taza",18,36,{v:"vacia",arm:1,gx:12,gy:32})];ab.abre=0;ab.pose="idle";await wait(700);},
  async muestra35(o){const ab=G("abuela"),it=o.k;ab.pose="offer";ab.dir=-1;const spec=it==="taza"?{k:"taza",v:"vacia"}:it==="jarrita"?{k:"jarrita"}:{k:"cazo",v:"0"};ab.tiene=[Object.assign(TENE(spec.k,20,34,{e:2,arm:1,gx:14,gy:28}),spec)];SFX.blip();await wait(800);ab.tiene=[];ab.pose="idle";},
  // the ending: everybody drinks; a spoiled cup stands in the middle of the table; abuela drinks at the stove
  async final35(o){const ab=G("abuela");
    await Promise.all([entra("luis",LE[0],LE[1],1),entra("carmen",CAR[0],CAR[1],1)]);
    const ninos=acts.ninos35({que:"toman"});
    const pr=(async()=>{for(const id of ["abuelo","papa"]){const t=copa(id),p=G(id);if(t.v!=="azu"&&t.vis!==0){t.vis=0;p.tiene=[TENE("taza",14,30,{v:t.v,vapor:1})];p.bebe2=t.v;}}await wait(1000);for(const id of ["abuelo","papa"]){const t=copa(id),p=G(id);if(p.bebe2){p.bebe2=null;p.tiene=[];t.vis=1;t.v="vacia";t.vapor=0;}}})();
    ab.sent=1;ab.taburete=1;ab.tiene=[TENE("taza",16,22,{v:copa("abuela").v,vapor:copa("abuela").v!=="vacia"?1:0})];V.cafe=copa("abuela").v!=="vacia"?"1":"";await pr;await ninos;W.cq.hace=null;await wait(500);},

  // everything at once, to look at the drawing
  async prueba(o){W.gente={};W.cosas=[];}
};
async function stake(lost,max,en){await wait(200);}
function poke(what){}
const estado=W=>{const C=W.cosas||[],f=C.find(o=>o.id==="fuente"),ce=C.find(o=>o.id==="cesta"),tb=C.find(o=>o.id==="tabla");return "gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)+(W.gente[k].sent?"s":"")+((W.gente[k].tiene||[]).length?"^"+W.gente[k].tiene.map(t=>t.k).join("+"):"")+(W.gente[k].come?"("+W.gente[k].come.k+")":"")).join(" ")
  +" cesta="+(ce?ce.v:"-")+" fuente="+(f?f.montones.filter(m=>m.g==="m").length+"m"+f.montones.filter(m=>m.g==="p").length+"p":"-")+" platos="+C.filter(o=>o.k==="plato").map(o=>o.id.slice(3)+":"+(o.v||"")+"/"+(o.rollos||[]).map(r=>(r.mal?"ma":r.st)+(r.con||"")).join("+")).join("|")
  +" tabla="+(tb&&tb.rollo?tb.rollo.st+(tb.rollo.con||""):"-")+" malos="+(tb&&tb.malos?tb.malos.length:0)+" mant="+((C.find(o=>o.id==="mant")||{}).v||"-")+" choc="+((C.find(o=>o.id==="choc")||{}).v||"-")
  +" tazas="+C.filter(o=>o.k==="taza").map(o=>o.id.slice(2)+":"+o.v+(o.vapor?"*":"")+(o.vis===0?"^":"")).join("|")+" pmont="+V.pmont+" marcas="+(W.marcas||[]).join(",");};
KIT.escena({id:"comer",CAM:{wide:[32,0,196,216]},heartAt:[130,22],lugar:{inicio:[124,141,1],centro:[124,141,1]},cosas:COSAS,
  fresh:()=>({respEn:[130,3],gente:{},sitio:{},cosas:[],vuelos:[],perro:null,tarjeta:null,marcas:null,cq:{x:108,y:141,s:1,dy:0,al:1,vis:1,sobre:1,bub:null,hace:null,piensa:null,tiene:[]}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
