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
const FILA=124,MED=148,FREN=170,TZ=173,ASIENTO=132,ATRAS=140;   // the rows of the table top; where somebody sitting has his feet; the lane behind the table
const LE=[66,190],CAR=[46,194],FOGON=[208,154],DER=[208,176],PUERTA=[0,190];   // the left end of the table, where he who comes in stands; Carmen beside him; abuela at the stove; the right end; the door (out of the picture)
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
  if(v==="1"){   // a baby: a big round head with a tuft of hair, round cheeks, a smile, a white bib on a yellow shirt, one hand up holding a small spoon
    b.ell(12,14,7.6,5.6,["#B87A10","#E0A020","#F8C838"]);b.ell(12,15,4.4,3.6,["#E8F0FA","#FFFFFF"]);b.rect(8,12,8,1,"#8CB8E8");   // shirt and bib
    b.ell(12,7.2,6.6,6.4,RP.skin.slice(2));b.px(10,6,"#20140A");b.px(14,6,"#20140A");b.px(10,5,"#FFFFFF");b.px(14,5,"#FFFFFF");b.px(8,9,"#E08A70");b.px(16,9,"#E08A70");b.rect(11,10,3,1,"#7A2A1A");b.px(10,9,"#7A2A1A");b.px(14,9,"#7A2A1A");
    b.px(12,0,KIT.PELO.castano[2]);b.px(13,1,KIT.PELO.castano[2]);b.px(11,1,KIT.PELO.castano[2]);b.px(12,1,KIT.PELO.castano[2]);
    b.ell(19.5,12,1.8,1.8,RP.skin.slice(2));b.rect(19,6,1,6,"#C8C8D4");b.ell(19.5,5,1.6,1.2,["#C8C8D4","#F8F8FF"]);   // a small spoon in his fist
  }
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
    else if(st==="m2"){E(7,8,6.4,4.6,TAN);Rc(1,8,10,1,"#8A5A18");P(5,5,"#F4CC88");borra(b,13*k,5.4*k,3.4*k);borra(b,13.6*k,10.4*k,3.2*k);E(11,8,2.4,3.4,["#FFF0C8","#FFFAE4"]);if(con)E(11.4,8.4,1.6,1.8,[F,F,FL]);}
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
  mantequilla(v){const b=new Buf(26,18),n=Math.max(1,Math.min(5,+(v||5)));b.ell(13,12.8,12.4,5.2,CERA);b.ell(13,10.4,10.4,3.8,["#8A96C0","#C4D0F0"]);b.rect(3,13,20,1,"#2E6CD0");
    const w=6+n*2,h=3+n,x0=13-(w>>1),y0=11-h;   // a block of butter in the dish: it gets smaller as it is used
    b.rect(x0,y0+2,w,h-2,MANT);b.rect(x0+1,y0,w-1,2,"#FFFBE0");b.rect(x0+w-1,y0+2,1,h-2,"#E0C860");b.rect(x0,y0+h-1,w,1,"#E0C860");b.rect(x0+1,y0+4,2,1,"#E0C860");
    return b.outline().done();},
  // melted chocolate in the same bowl: dark, glossy, filling the bowl; a spoon handle stands in it
  choc(v){const b=new Buf(26,18),n=Math.max(1,Math.min(5,+(v||5)));b.ell(13,12.8,12.4,5.2,CERA);b.ell(13,10.4,10.4,3.8,["#8A96C0","#C4D0F0"]);b.rect(3,13,20,1,"#2E6CD0");
    const rx=4.4+n*1.2,ry=1.6+n*.42;b.ell(13,10.6,rx,ry,[CHOC[0],CHOC[1],CHOC[2]]);b.px(9,10,"#C89A74");b.px(10,10,"#C89A74");b.px(15,11,"#A0724C");b.px(7,11,"#8A5A34");
    b.cap(16,10,22,2,.9,["#8A8A9A","#C8C8D4"]);b.px(22,1,"#F8F8FF");
    return b.outline().done();},
  // a wooden board to fill the roll on
  tabla(){const b=new Buf(32,10),W=RP.wood;b.rect(1,2,30,6,W[3]);b.rect(1,2,30,1,W[4]);b.rect(1,7,30,1,W[1]);b.rect(1,8,30,1,W[0]);for(let x=4;x<28;x+=5){b.rect(x,4,3,1,W[2]);b.rect(x+2,6,2,1,W[2]);}b.rect(26,3,4,2,W[0]);return b.outline().done();},
  tenedor(){const b=new Buf(8,18);[1,3,5].forEach(x=>b.rect(x,0,1,6,"#E8E8F2"));b.rect(1,5,5,2,"#D0D0DC");b.rect(3,7,1,10,"#D0D0DC");b.rect(4,7,1,10,"#9A9AAC");return b.outline().done();},
  cuchara(){const b=new Buf(9,18);b.ell(4.5,5,3,4,["#8A8A9C","#C8C8D4","#F8F8FF"]);b.rect(4,9,1,8,"#C8C8D4");return b.outline().done();},
  // a fork lying flat, tines to the left, 18 x 8
  tenedorH(){const b=new Buf(18,8);[1,3,5].forEach(y=>b.rect(0,y,6,1,"#E8E8F2"));b.rect(5,1,2,5,"#D0D0DC");b.rect(7,3,10,2,"#D0D0DC");b.rect(7,4,10,1,"#9A9AAC");return b.outline().done();},
  // a mound of yellow rice, 12 x 9
  monton(){const b=new Buf(12,9);b.ell(6,5.4,5.4,3.6,ARROZ);b.px(4,3,"#FFF4B0");b.px(7,3,"#FFF4B0");b.px(6,7,"#B87A10");b.px(8,6,"#B87A10");b.px(3,6,"#B87A10");return b.outline().done();},
  // the pot of rice on the table, 30 x 26: "lleno" (heaped, with its spoon), "lleno0" (no spoon), "vacio"
  olla(v){const b=new Buf(30,26);b.rect(4,9,22,15,"#8A8A9A");b.rect(4,9,6,15,"#B8B8C8");b.rect(4,20,22,4,"#5A5A6A");b.rect(1,12,3,4,"#3A3A46");b.rect(26,12,3,4,"#3A3A46");b.ell(15,9,11,4,["#5A5A6A","#9494A6","#C8C8D4"]);
    if(v==="vacio"){b.ell(15,9.4,9.2,3.2,["#1E1E28","#2A2A36"]);b.px(10,9,"#FFF4B0");b.px(20,10,"#B87A10");}else{b.ell(15,8.6,9.2,3.2,["#C88A10","#F2C028","#FFE060"]);b.ell(15,6.4,6,3.4,ARROZ);[[10,8],[13,9],[17,8],[20,9],[22,8],[12,6],[17,5]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    if(v==="lleno"){b.cap(20,8,26,1,1,["#B07A3C","#D09A54"]);}
    const c=b.outline().done();c.pico=[3,9];return c;},
  // the platter for the second helpings, 44 x 26: a big blue plate with a rim; the mounds lie on it (drawn by the scene), and papá's fork
  // v "c": lying on the stove, seen from the front, flat
  fuente(v){if(v==="c"){const b=new Buf(44,12);b.ell(22,7,21,4.6,["#2A5C9C","#4A86C8","#8CB8E8"]);b.ell(22,6,17.6,2.8,["#6AA0DC","#A8CCF0"]);return b.outline().done();}
    const b=new Buf(44,26);b.ell(22,14,21,11,["#2A5C9C","#4A86C8","#8CB8E8"]);b.ell(22,13,17.6,8.4,["#6AA0DC","#A8CCF0"]);b.rect(9,21,26,1,"#2E6CD0");return b.outline().done();},
  sillaBebe(v){return mkSillaBebe(v);},
  taburete(){return mkTaburete();},
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
  azucarera(v){const b=new Buf(24,20),n=Math.max(0,Math.min(3,+(v==null?3:v)));b.ell(12,14.4,10.4,4.8,CERA);b.rect(2,13,20,1,"#2E6CD0");b.ell(12,12,9,3,["#8A96C0","#B4BEE0"]);
    b.ell(12,9.6,7.6,4.4,["#DCE2F0","#F4F6FF","#FFFFFF"]);[[8,8],[12,7],[15,9],[10,11],[13,10],[9,10]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#B4BEE0":"#FFFFFF"));
    [[15,1,17,10],[12,2,13,10],[18,3,19,10]].slice(0,n).forEach(q=>{b.rect(q[0],q[1],1,q[3]-q[1],"#8A8A9A");b.rect(q[2],q[1],1,q[3]-q[1],"#C8C8D4");b.ell(q[0]+.5,q[1]+.6,1.6,1.1,["#C8C8D4","#F8F8FF"]);});   // teaspoons stand in the sugar
    return b.outline().done();},
  // the big pot of coffee (enamel, blue, a spout and a handle), 24 x 28; pico: the lip
  cafetera(){const b=new Buf(24,28);b.rect(5,9,14,17,"#2A5C9C");b.rect(5,9,3,17,"#6AA0DC");b.rect(5,23,14,3,"#1A3C6C");b.ell(12,8,7.4,2.6,["#1A3C6C","#2A5C9C"]);b.rect(10,3,4,4,"#141418");b.rect(3,10,3,2,"#2A5C9C");b.rect(1,8,3,3,"#2A5C9C");b.rect(19,11,3,12,"#141418");b.rect(18,11,4,2,"#141418");b.rect(18,21,4,2,"#141418");b.px(9,14,"#FFFFFF");b.px(13,18,"#FFFFFF");const c=b.outline().done();c.pico=[1,9];return c;},
  // the greca: the little coffee pot, red, two chambers with a waist between them, a lid with a knob, a spout and a black handle, 20 x 22; pico: the spout
  jarrita(){const b=new Buf(20,22);b.rect(3,13,12,8,"#B0302A");b.rect(3,13,3,8,"#F08880");b.rect(3,19,12,2,"#7A1C1C");b.rect(5,10,8,4,"#8A2020");b.rect(5,10,2,4,"#C8403A");
    b.rect(3,3,12,8,"#B0302A");b.rect(3,3,3,8,"#F08880");b.rect(3,3,12,1,"#C8403A");b.rect(8,0,3,3,"#141418");b.rect(2,3,2,2,"#B0302A");b.px(1,3,"#B0302A");
    b.rect(15,5,3,2,"#141418");b.rect(17,5,2,12,"#141418");b.rect(15,15,3,2,"#141418");b.px(8,16,"#FFFFFF");b.px(9,6,"#FFFFFF");const c=b.outline().done();c.pico=[1,3];return c;},
  // the milk pan: a saucepan, grey metal with a black handle and a pouring lip, v "1" with milk, "0" empty; 26 x 14; pico: the lip
  cazo(v){const b=new Buf(26,14);b.rect(3,5,14,8,"#8E92A6");b.rect(3,5,3,8,"#C8CCDA");b.rect(3,11,14,2,"#5A5E70");b.ell(10,5,7.6,2.8,["#6A6E80","#B8BCCC","#E8EAF2"]);b.ell(10,5,6,1.9,v==="0"?["#2A2A36","#4A4A58"]:["#E4DCC8","#F6F1E4","#FFFFFF"]);
    b.rect(17,6,8,2,"#141418");b.rect(23,5,2,4,"#141418");b.px(2,4,"#B8BCCC");b.px(1,4,"#B8BCCC");const c=b.outline().done();c.pico=[1,4];return c;},
  // the dog's bowl: with milk in it, or empty
  tazon(v){const b=new Buf(22,10);b.ell(11,6,10,3.6,["#2A5C9C","#4A86C8","#8CB8E8"]);b.ell(11,4.8,7.8,2.4,v==="1"?["#E4DCC8","#F6F1E4","#FFFFFF"]:["#1E3A68","#2A5C9C"]);return b.outline().done();},
  // a baking tray with n rolls on it, for abuela to carry: a metal tray with a rim all round and a handle at each end, 44 x 18
  bandeja(n){const b=new Buf(44,18);n=n==null?4:+n;b.rect(2,6,40,10,"#6A6E80");b.rect(3,7,38,8,"#E0D2A8");b.rect(3,7,38,1,"#B8A878");b.rect(2,5,40,2,"#D8DCEA");b.rect(0,8,3,4,"#4A4E60");b.rect(41,8,3,4,"#4A4E60");
    for(let i=0;i<n;i++)rollitos(b,8+i*9.4,13);
    b.rect(2,13,40,3,"#6A6E80");b.rect(2,13,40,1,"#E8ECF8");b.rect(2,15,40,1,"#4A4E60");return b.outline().done();},
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
  // the milk jug for the pair: a white pitcher, wider at the foot, a ring for a handle on the right, a pouring lip on the left, a blue band; 24 x 26; pico: the lip
  jarraleche(){const b=new Buf(24,26);b.rect(5,7,13,17,"#F2F6FC");b.rect(4,12,15,12,"#F2F6FC");b.rect(5,7,3,17,"#FFFFFF");b.rect(16,10,2,14,"#C8D4E8");b.rect(4,20,15,4,"#C8D4E8");b.rect(4,14,15,2,"#2E6CD0");
    b.rect(6,5,11,3,"#F2F6FC");b.rect(2,4,5,2,"#F2F6FC");b.px(1,4,"#C8D4E8");b.rect(6,5,11,1,"#FFFFFF");   // the rim and the lip
    b.rect(19,9,3,2,"#C8D4E8");b.rect(21,10,2,10,"#C8D4E8");b.rect(19,18,3,2,"#C8D4E8");b.rect(20,11,1,8,"#F2F6FC");   // the handle: a ring
    const c=b.outline().done();c.pico=[1,4];return c;},
  // a glass of orange juice, 9 x 13
  vasojugo(){const b=new Buf(9,13);b.rect(1,1,7,11,"#DCF2FA");b.rect(1,1,2,11,"#F2FBFF");b.rect(2,4,5,8,"#F08818");b.rect(2,3,5,1,"#FFB040");return b.outline().done();},
  // a big hand, laid flat on the belly (v: the colour of the skin)
  manoG(v){const b=new Buf(10,8),c=v||"#D09460";b.ell(5,4.4,4.4,3.2,[c]);b.px(2,1,c);b.px(4,0,c);b.px(6,0,c);b.px(8,1,c);b.px(3,6,"#7A4A2A");b.px(5,6,"#7A4A2A");b.px(7,6,"#7A4A2A");return b.outline().done();},
  // a thing for a thought: a question mark; a heart
  interroga(){const b=new Buf(9,13);const Q=["..###..",".##.##.",".##.##.","....##.","...##..","..##...","..##...",".......","..##..."];Q.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(1+i,1+j,"#3A3A46");});return b.outline("#FFFFFF").done();},
  corazon(){const b=new Buf(9,8);const H=[".##.##.","#######","#######",".#####.","..###..","...#..."];H.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(1+i,1+j,j<2&&i<3?"#FF9A90":"#E8443C");});return b.outline().done();}};
// the pots that pour are made twice: standing, and tipped (at 50 degrees) to pour to the left; to the right they are turned over
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
function vapor(c,x,y,n,h){const t=(F>>2)%12,H=h||14;c.save();for(let i=0;i<(n||2);i++){const dx=i*7-3;for(let k=0;k<H;k++){const sw=Math.round(Math.sin((k+t*1.2+i*4)/2.4)*2.4);c.globalAlpha=Math.max(.12,.85-k*14/H*.065);fr(c,x+dx+sw-1,y-k,3,1,"#B8C4D4");fr(c,x+dx+sw,y-k,2,1,"#FFFFFF");}}c.restore();}
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
const COSAS=Object.keys(QUIEN).map(persona).concat([porId("mant",26,18),porId("choc",26,18),porId("cesta",48,24,0),porId("cafetera",24,28,0),porId("azucarera",24,18,0),porId("olla",30,26,0),porId("fuente",56,22,0),porId("pl_papa",24,10,0),porId("pl_rana",18,9,0),
  {id:"silla_papa",si:w=>true,box:w=>[SILLA[(w.sitio&&w.sitio.papa!=null)?w.sitio.papa:3]-10,MESA[1]-26,20,36],m:0},{id:"mesa",box:[MESA[0]-6,MESA[1],MESA[2]+12,MESA[3]+6],m:0},{id:"cocina",box:[32,24,196,190],m:0}]);

/* ---------- drawing ---------- */
// where things are held: the shoulder and the mouth of each, from his feet (up)
const hombroY=(id,p)=>{const w=QUIEN[id]||{};return id==="abuela"?(p.sent?25:27):w.nino?(p.sent?19:22):(p.sent?27:34);};
const bocaY=(id,p)=>{const w=QUIEN[id]||{};return id==="abuela"?(p.sent?33:35):w.nino?(p.sent?25:28):(p.sent?33:40);};
const sleeve=id=>id==="abuela"?RP.purp[2]:((QUIEN[id]||{}).ropa||RP.cream)[2];
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
const ALCANCE=[];   // a hand that is farther than his arm can reach (checked by machine: it must stay empty)
function brazoJ(c,sx,sy,hx,hy,L,sl,pi,lado,quien){
  const d=Math.hypot(hx-sx,hy-sy)||.01,dd=Math.min(d,2*L-.4),ux=(hx-sx)/d,uy=(hy-sy)/d,a=dd/2,h=Math.sqrt(Math.max(0,L*L-a*a)),nx=-uy,ny=ux;
  if(d>2*L+1.5&&quien&&ALCANCE.length<40)ALCANCE.push(quien+" "+Math.round(d)+">"+2*L);
  const e1=[sx+ux*a+nx*h,sy+uy*a+ny*h],e2=[sx+ux*a-nx*h,sy+uy*a-ny*h];
  const e=Math.abs(uy)>Math.abs(ux)*1.3?((e1[0]-sx)*lado>(e2[0]-sx)*lado?e1:e2):(e1[1]>e2[1]?e1:e2);
  const seg=(x0,y0,x1,y1,f)=>{const n=Math.max(1,Math.ceil(Math.max(Math.abs(x1-x0),Math.abs(y1-y0))));for(let i=0;i<=n;i++){const x=R(x0+(x1-x0)*i/n),y=R(y0+(y1-y0)*i/n);f(x,y,i/n);}};
  seg(sx,sy,e[0],e[1],(x,y)=>fr(c,x-2,y-2,5,5,OUT));seg(e[0],e[1],hx,hy,(x,y)=>fr(c,x-2,y-2,5,5,OUT));
  seg(sx,sy,e[0],e[1],(x,y)=>fr(c,x-1,y-1,3,3,sl));seg(e[0],e[1],hx,hy,(x,y,t)=>fr(c,x-1,y-1,3,3,t>.7?pi:sl));
  return e;}
const GRIP={tazacu:[7,2],rollo:[-6,4],plato:[0,4],taza:[7,2],tenedor:[0,6],cuchara:[0,6],muslo:[8,0],vasojugo:[0,2],bizcochoT:[2,6],bizcochoL:[5,8],bebe:[0,8],pano:[0,0],cafetera:[9,8],jarrita:[6,2],cazo:[8,1],jarraleche:[8,3],bandeja:[14,4,1],olla:[13,1,1],fuente:[18,2,1],tenedorH:[0,0],monton:[0,2],platoma:[0,6],platoH:[0,6],bizcocho:[0,4],jarra:[0,2],jugo:[0,2]};
function agarres(it,ix,iy,fl){const base=String(it.k).replace(/^tilt/,""),e=it.e||1,g=GRIP[base]||[0,3];let gx=g[0]*e,gy=g[1]*e;if(/^tilt/.test(it.k)){const A=it.v==="suave"?-0.55:-0.9,cs=Math.cos(A),sn=Math.sin(A),nx=gx*cs-gy*sn,ny=gx*sn+gy*cs;gx=nx;gy=ny;}
  const sg=fl?-1:1;if(it.una)return [[ix,iy+gy]];if(it.dos){const h=typeof it.dos==="number"?it.dos:11;return [[ix-h,iy+gy],[ix+h,iy+gy]];}return g[2]?[[ix+sg*gx,iy+gy],[ix-sg*gx,iy+gy]]:[[ix+sg*gx,iy+gy]];}
const CONASA=new Set(["taza","cafetera","jarrita","cazo","jarraleche"]);   // what has its handle on the right of the drawing: it is turned so that the handle is on the side of his body
const comeFl=(co,d)=>CONASA.has(co.k)?d>0:(d<0&&co.k!=="tenedor");   // what is at the mouth: a cup has its handle on the side of the body
const CUE=id=>{const w=QUIEN[id]||{};return id==="abuela"?{L:8,sx:7}:w.nino?{L:7,sx:5.5}:{L:9,sx:7};};
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
  else if(POSE==="yo"){if(!usado(-1))pon(x-3,y-hy+cu.L-1,null,-1,"pose");if(!usado(1))pon(x+3,y-hy+cu.L-1,null,1,"pose");}
  else if(POSE==="bless"){if(!usado(d))pon(x+d*3,y-hy+cu.L-1,null,d,"pose");}
  return out;}
// his arms at rest: the sides that are not busy, hanging; when he sits, resting on the lap
function brazosQuietos(c,id,p,a,vivos){const x=R(p.x),y=R(p.y),hy=hombroY(id,p),cu=CUE(id),sl=sleeve(id),pi=piel(id);
  [-1,1].forEach(s=>{if(vivos.some(m=>m.s===s))return;const sx=x+s*cu.sx,sy=y-hy,hx=x+s*(cu.sx+1.5),hyy=p.sent?sy+cu.L*1.25:sy+cu.L*1.7;brazoJ(c,sx,sy,hx,hyy,cu.L,sl,pi,s);mano(c,hx,hyy,pi);});}
function cuerpo(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1,pie=p.paso?(p.pie||0):0,bob=p.paso&&pie===0?-1:0;
  const vivos=manosDe(id,p,a);
  if(id==="abuela"){
    if(p.sent){const top=y-48,hb=(habla||p.abre||p.boca)?1:0;if(p.taburete)tenida(c,"taburete",x+3,y+3);c.drawImage(spr("abSN"+hb,()=>recolor(mkAbuelaSN(hb),APRON)),x-17,top);brazosQuietos(c,id,p,a,vivos);return;}
    const top=y-50+bob,hb=(habla||p.abre||p.boca)?1:0;c.save();c.translate(x,top);if(d<0)c.scale(-1,1);c.drawImage(spr("abN"+hb+pie,()=>recolor(mkAbuelaN(hb,pie),APRON)),-24,0);c.restore();brazosQuietos(c,id,p,a,vivos);return;}
  const op=(habla||p.boca||p.sopla)?1:0,w2=p.cierra?Object.assign({},w,{dormido:1},w.gafas?{gafas:"arriba"}:{}):w,im=spr("pmN"+id+op+(p.sent?1:0)+pie+(p.cierra?"c":""),()=>mkPersonaN(w2,op,p.sent,pie)),top=y-im.height+1+bob+(p.dy||0);
  c.save();c.translate(x,top);if(d<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  brazosQuietos(c,id,p,a,vivos);
  const sk=(w.piel||RP.skin)[2];
  if(p.cara==="mal"){fr(c,x-6,top+11,13,9,sk);   // a big plain frown: eyes squeezed shut, thick brows sloping down to the nose, a wide mouth turned down, a red mark of being cross
    [[-6,8],[-5,8],[-4,9],[-3,9],[-2,10]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));[[6,8],[5,8],[4,9],[3,9],[2,10]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));
    [[-5,12],[-4,13],[-3,12],[-2,13]].forEach(q=>fr(c,x+q[0],top+q[1],1,1,"#20140A"));[[5,12],[4,13],[3,12],[2,13]].forEach(q=>fr(c,x+q[0],top+q[1],1,1,"#20140A"));
    fr(c,x-3,top+16,7,2,"#5A1A10");fr(c,x-5,top+17,2,2,"#5A1A10");fr(c,x+4,top+17,2,2,"#5A1A10");fr(c,x-6,top+19,2,1,"#5A1A10");fr(c,x+5,top+19,2,1,"#5A1A10");
    fr(c,x+7,top+1,1,4,"#D0302A");fr(c,x+6,top+2,3,1,"#D0302A");fr(c,x+8,top+3,1,1,"#D0302A");}
  if(p.cierra){[[-6,13],[-5,12],[-4,11],[-3,11],[-2,12],[-1,13]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));[[1,13],[2,12],[3,11],[4,11],[5,12],[6,13]].forEach(q=>fr(c,x+q[0],top+q[1]-1,1,2,"#20140A"));
    fr(c,x-5,top+13,2,1,sk);fr(c,x+3,top+13,2,1,sk);}
  if(p.sopla){fr(c,x-9,top+11,5,6,sk);fr(c,x+5,top+11,5,6,sk);fr(c,x-10,top+12,1,4,OUT);fr(c,x+10,top+12,1,4,OUT);fr(c,x-9,top+10,5,1,OUT);fr(c,x+5,top+10,5,1,OUT);fr(c,x-9,top+17,5,1,OUT);fr(c,x+5,top+17,5,1,OUT);   // puffed cheeks, a round mouth, and a breath
    fr(c,x-3,top+14,7,3,sk);fr(c,x-1,top+14,3,3,"#7A1C1C");
    const t=(F>>2)%3;[[0,0],[6,2],[12,0]].forEach((q,i)=>{fr(c,x+d*(7+q[0]+t),top+14+q[1],5,1,i===t?"#FFFFFF":"#B8C4D4");fr(c,x+d*(7+q[0]+t),top+15+q[1],3,1,"#B8C4D4");});}}
// what he holds and eats, drawn after (over) his body; behind the table, after the table too. Each thing is in a hand at the end of an arm with an elbow
function objetos(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const x=R(p.x),y=R(p.y),d=p.dir<0?-1:1,hy=hombroY(id,p),pi=piel(id),sl=sleeve(id),cu=CUE(id),ms=manosDe(id,p,a);
  const brazo=m=>brazoJ(c,x+m.s*cu.sx,y-hy,m.x,m.y,cu.L,sl,pi,m.s,id+":"+(m.it?m.it.k:m.k));
  for(const m of ms)brazo(m);   // the arms first, the things over them, the hands last
  for(const it of p.tiene||[]){if(it.vis===0||it.k==="brazo")continue;const ix=x+d*it.dx,iy=y-it.dy,fl=it._fl!=null?it._fl:false;
    if(it.k==="uten"){cucharon(c,x+d*it.ax,y-it.ay,x+d*it.bx,y-it.by,it.load,it.o);continue;}
    const kk=it.k==="taza"&&it.sp?"tazacu":it.k;
    if(it.ang){const g=spr("cmg"+it.k+(it.v==null?"":it.v)+it.ang,()=>giro(cosa(it.k,it.v),it.ang));c.save();c.imageSmoothingEnabled=false;c.drawImage(g,R(ix-g.width/2),R(iy-g.height/2));c.restore();}else tenidaC(c,kk,ix,iy,it.e,it.v,fl);
    if(it.k==="plato")(it.rollos||[]).forEach(r=>rolloD(c,ix+(r.dx||0),iy+3,r,a));
    if(it.k==="fuente"){(it.montones||[]).forEach(m=>tenidaC(c,"monton",ix+m.dx,iy+13+(m.dy==null?-4:m.dy)-4.5));if(it.tenedor)tenidaC(c,"tenedorH",ix+it.tenedor.dx,iy+13-it.tenedor.dy-4);}
    if(it.vapor)vapor(c,ix,iy-(it.e||1)*9-2,it.vn||1,it.vh);
    if(it.chorro){const im=cosa(it.k,it.v),e=it.e||1;if(im.pico){const px=ix+(im.pico[0]-im.width/2)*e*(fl?-1:1),py=iy+(im.pico[1]-im.height/2)*e+1;chorro(c,R(px),R(py),R(py)+it.chorro.h,it.chorro.col);}}}   // a stream from the lip of what he pours
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
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;g.restore();
  if(q.lleno){[[-7,0],[-9,1],[-10,2],[-10,3],[-9,4],[-7,5]].forEach(r=>{fr(g,cx+r[0]-1,b.y+dy+12+r[1],-2*r[0]+2,1,"#FBF0D2");});fr(g,cx-10,b.y+dy+14,1,3,OUT);fr(g,cx+9,b.y+dy+14,1,3,OUT);fr(g,cx,b.y+dy+15,1,1,"#B89A6A");}
  if(q.mal){const fx=cx,fy2=b.y+dy;[[-9,5],[-8,6],[-7,6],[-6,7]].forEach(r=>fr(g,fx+r[0],fy2+r[1]-2,1,2,OUT));[[9,5],[8,6],[7,6],[6,7]].forEach(r=>fr(g,fx+r[0]-1,fy2+r[1]-2,1,2,OUT));fr(g,fx-4,fy2+14,9,1,"#7A1C1C");fr(g,fx-5,fy2+15,2,1,"#7A1C1C");fr(g,fx+4,fy2+15,2,1,"#7A1C1C");}
  const sl=RP.tan[2],pi=RP.tan[3],its=(q.tiene||[]).filter(it=>it.vis!==0),hs_=[];
  its.forEach(it=>{const base=String(it.k).replace(/^tilt/,"");let H;
    if(it.k==="brazo")H=[[cx+it.gx,fy-it.gy]];else if(it.k==="uten")H=[[cx+it.ax,fy-it.ay]];else if(it.gx!=null)H=[[cx+it.gx,fy-it.gy]];else H=agarres(it,cx+it.dx,fy-it.dy,it.flip!=null?it.flip:(CONASA.has(base)&&it.dx>0));
    it._H=H;H.forEach(h=>{const s=h[0]>=cx?1:-1;brazoJ(g,cx+s*7,fy-12,h[0],h[1],6,sl,pi,s,"rana:"+it.k);});});
  its.forEach(it=>{if(it.k==="brazo")return;const ix=cx+it.dx,iy=fy-it.dy,base=String(it.k).replace(/^tilt/,""),fl=it.flip!=null?it.flip:(CONASA.has(base)&&it.dx>0);
    if(it.k==="uten")cucharon(g,cx+it.ax,fy-it.ay,cx+it.bx,fy-it.by,it.load,it.o);else tenidaC(g,it.k,ix,iy,it.e,it.v,fl);
    if(it.chorro){const im=cosa(it.k,it.v),e=it.e||1;if(im.pico){const px=ix+(im.pico[0]-im.width/2)*e*(fl?-1:1),py=iy+(im.pico[1]-im.height/2)*e+1;chorro(g,R(px),R(py),R(py)+it.chorro.h,it.chorro.col);}}
    if(it.vapor)vapor(g,ix,iy-(it.e||1)*9-2,it.vn||1);});
  its.forEach(it=>(it._H||[]).forEach(h=>mano(g,h[0],h[1],pi)));}
// a thought: a round white cloud with its trail of two small ones, and a thing in it. At (x,y): its top left.
function nube(g,x,y,o,dir,aim){const w=40,h=30,t=dir||1;fr(g,x-1,y+3,w+2,h-6,OUT);fr(g,x+3,y-1,w-6,h+2,OUT);fr(g,x+1,y+1,w-2,h-2,OUT);
  fr(g,x,y+3,w,h-6,"#FFFFFF");fr(g,x+3,y,w-6,h,"#FFFFFF");fr(g,x+1,y+1,w-2,h-2,"#FFFFFF");
  const tx=x+(t>0?8:w-8);const tr=aim?(()=>{const cxn=x+w/2,cyn=y+h/2,vx=aim[0]-cxn,vy=aim[1]-cyn,dd=Math.hypot(vx,vy)||1,ux=vx/dd,uy=vy/dd,e0=Math.min(w/2/Math.max(.01,Math.abs(ux)),h/2/Math.max(.01,Math.abs(uy)));return [[cxn+ux*(e0+4),cyn+uy*(e0+4),5],[cxn+ux*(e0+10),cyn+uy*(e0+10),3]];})():[[tx,y+h+3,5],[tx+t*(-3),y+h+9,3]];tr.forEach(q=>{fr(g,q[0]-(q[2]>>1)-1,q[1]-1,q[2]+2,q[2]+2,OUT);fr(g,q[0]-(q[2]>>1),q[1],q[2],q[2],"#FFFFFF");});
  tenidaC(g,o.k,x+(w>>1),y+(h>>1),o.e||1,o.v);}
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
  if(k==="plato"){tenida(c,"plato",o.x,o.y,0,o.e,o.v);(o.rollos||[]).forEach(r=>rolloD(c,o.x+(r.dx||0),o.y-3,r,a));if(o.vapor)vapor(c,o.x,o.y-12,1);return;}
  if(k==="tabla"){tenida(c,"tabla",o.x,o.y);if(o.rollo)rolloD(c,o.x,o.y-3,o.rollo,a);return;}
  if(k==="fuente"){tenida(c,"fuente",o.x,o.y);(o.montones||[]).slice().sort((m,n)=>(m.dy||0)-(n.dy||0)).forEach(m=>tenida(c,"monton",o.x+m.dx,o.y+(m.dy==null?-4:m.dy)));if(o.tenedor)tenida(c,"tenedorH",o.x+o.tenedor.dx,o.y-(o.tenedor.dy==null?4:o.tenedor.dy),0,1);return;}
  if(k==="olla"){tenida(c,"olla",o.x,o.y,0,1,o.v);if(o.vapor&&o.v!=="vacio")vapor(c,o.x,o.y-22,2);return;}
  tenida(c,k==="taza"&&o.sp?"tazacu":k,o.x,o.y,0,o.e||1,k==="azucarera"?String(Math.min(3,o.spoons==null?3:o.spoons)):o.v);
  if(o.vapor)vapor(c,o.x+(o.vdx||0),o.y-(o.vdy==null?(k==="cesta"?18:k==="taza"?15:12):o.vdy),o.vn||2,o.vh);}
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
  if(SINTXT){const hab=(x,y)=>{fr(c,x-7,y-10,15,9,OUT);fr(c,x-6,y-11,13,11,OUT);fr(c,x-6,y-10,13,9,"#FFFFFF");[-3,0,3].forEach(i=>fr(c,x+i,y-6,1,1,"#2A1810"));fr(c,x-1,y-1,3,1,OUT);fr(c,x-1,y-1,2,1,"#FFFFFF");fr(c,x,y,1,1,OUT);};
    if(TALK==="coqui"&&q.vis){const b=frogBox(q);hab(b.x+(b.w>>1),b.y+R(q.dy)-3);}
    else if(TALK&&Gt[TALK]&&Gt[TALK].vis!==0){const t=talkAt(TALK,W);if(t)hab(t[0],t[1]-1);}}
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.piensa&&p.vis!==0)nube(c,R(p.x)-20+(p.pdx||0),R(p.y)-alto(id)-38,p.piensa);});
  if(q.vis&&q.piensa){const b=frogBox(q),n=q.nube||[b.x+(b.w>>1)-20,b.y-44];nube(c,n[0],n[1],q.piensa,q.ndir,q.nubeAim);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1];}
function respIcon(g,k,x,y,w,h,a){}

/* ---------- the places of story 34 (the rice) and of story 35 (the coffee) ---------- */
const HIJA=[46,150],OLLA=[134,162],PLUIS=[100,172],PRANA=[148,172],CASA34=[170,168],LUIS34=[112,188],FU34=[96,152],PLAT34=[206,121];   // the baby's high chair at the left end; the pot (the platter goes by it); Luis's plate; the frog's small plate; the frog's place; where Luis stands; the platter's place on the table; where the platter waits (the stove)
const SEAT34={mama:0,carmen:1,papa:2,abuelo:3};
const TENE=(k,dx,dy,o)=>Object.assign({k,dx,dy},o||{});
const D1=p=>p.dir<0?-1:1;
// a long spoon in somebody's hand: the hand and the bowl move together, the handle is no longer than his forearm; where must the hand and the bowl be for the bowl to be at the point (wx,wy) of the picture
function cucharaPos(id,wx,wy,sp){const p=G(id),d=D1(p),cu=CUE(id),S=[R(p.x)+((sp&&sp.side)||d)*cu.sx,R(p.y)-hombroY(id,p)],vx=wx-S[0],vy=wy-S[1],dist=Math.hypot(vx,vy)||1,u=[vx/dist,vy/dist],HL=2*cu.L-2,hd=Math.max(5,Math.min(2*cu.L-.5,dist-HL)),H=[S[0]+u[0]*hd,S[1]+u[1]*hd],B=[H[0]+u[0]*HL,H[1]+u[1]*HL];
  return [(H[0]-R(p.x))*d,R(p.y)-H[1],(B[0]-R(p.x))*d,R(p.y)-B[1]];}
async function cucharaA(id,sp,wx,wy,n){const t=cucharaPos(id,wx,wy,sp),a=[sp.ax,sp.ay,sp.bx,sp.by];n=n||4;for(let i=1;i<=n;i++){sp.ax=a[0]+(t[0]-a[0])*i/n;sp.ay=a[1]+(t[1]-a[1])*i/n;sp.bx=a[2]+(t[2]-a[2])*i/n;sp.by=a[3]+(t[3]-a[3])*i/n;await wait(TICK);}[sp.ax,sp.ay,sp.bx,sp.by]=t;}
const spoonOf=id=>(G(id).tiene||[]).find(t=>t.k==="uten");
const spoonW=(id,sp)=>{const p=G(id),d=D1(p);return {h:[R(p.x)+d*sp.ax,R(p.y)-sp.ay],b:[R(p.x)+d*sp.bx,R(p.y)-sp.by]};};
const bigSpoon=o=>Object.assign({k:"uten",ax:10,ay:24,bx:22,by:28,load:"",o:{rx:6,ry:4}},o||{});
// the frog's own hands: a spoon whose bowl is at (wx,wy)
function cucharaPosR(wx,wy,izq){const q=W.cq,sx=cx()+(izq?-7:7),sy=pies()-12,vx=wx-sx,vy=wy-sy,dist=Math.hypot(vx,vy)||1,u=[vx/dist,vy/dist],HL=10,hd=Math.max(4,Math.min(11.5,dist-HL)),H=[sx+u[0]*hd,sy+u[1]*hd],B=[H[0]+u[0]*HL,H[1]+u[1]*HL];return [H[0]-cx(),pies()-H[1],B[0]-cx(),pies()-B[1]];}
async function cucharaAR(sp,wx,wy,izq,n){const t=cucharaPosR(wx,wy,izq),a=[sp.ax,sp.ay,sp.bx,sp.by];n=n||4;for(let i=1;i<=n;i++){sp.ax=a[0]+(t[0]-a[0])*i/n;sp.ay=a[1]+(t[1]-a[1])*i/n;sp.bx=a[2]+(t[2]-a[2])*i/n;sp.by=a[3]+(t[3]-a[3])*i/n;sp.gx=sp.ax;sp.gy=sp.ay;await wait(TICK);}[sp.ax,sp.ay,sp.bx,sp.by]=t;sp.gx=sp.ax;sp.gy=sp.ay;}
// where Luis rests his spoon: held up in front of him, the bowl a little over the frog's plate
const luisRest=()=>{const l=G("luis");return [R(l.x)+22,R(l.y)-34];};
// the spoon goes from a person's hand to another's (or the frog's): his hand reaches it where it is held, the other hand takes it there
async function pasaCuchara(de,a){const sp=spoonOf(de);if(!sp)return;const W_=spoonW(de,sp);
  if(a==="rana"){const q=W.cq;await ranaA(W_.h[0]+12,W_.h[1]+12);const sp2={k:"uten",ax:W_.h[0]-cx(),ay:pies()-W_.h[1],bx:W_.b[0]-cx(),by:pies()-W_.b[1],load:sp.load,o:{rx:6,ry:4,plata:0},gx:0,gy:0};sp2.gx=sp2.ax;sp2.gy=sp2.ay;q.tiene=[sp2];G(de).tiene=G(de).tiene.filter(t=>t!==sp);SFX.blip();await wait(TICK*2);return sp2;}
  const p=G(a),d=D1(p),r=rel(a,W_.h[0],W_.h[1]);await manoA(a,r[0],r[1],3,0);
  const sp2={k:"uten",ax:r[0],ay:r[1],bx:(W_.b[0]-R(p.x))*d,by:R(p.y)-W_.b[1],load:sp.load,o:sp.o};sinManos(a);p.tiene.push(sp2);G(de).tiene=G(de).tiene.filter(t=>t!==sp);SFX.blip();await wait(TICK*2);return sp2;}
// the frog's place when he tips a mound onto the plate of the one at seat i (x): beside the plate on the cloth, the spoon in the hand on the side of the plate
const lado34=px=>px>150?{fx:px-17,fy:146,izq:0}:{fx:px+17,fy:146,izq:1};
// the mounds on the platter: g "m" a helping (front row), g "p" papá's (back row, at his end)
function fuenteMonton(g){const fu=ob("fuente");if(!fu||!fu.montones)return null;const m=fu.montones.filter(m=>m.g===g)[0];return m?{fu,m,x:fu.x+m.dx,y:fu.y+(m.dy==null?-4:m.dy)-3}:null;}
const origen=()=>{const fu=ob("fuente"),h=fuenteMonton("m");if(h&&fu&&fu.x<200)return {x:h.x,y:h.y,take:()=>{h.fu.montones.splice(h.fu.montones.indexOf(h.m),1);}};const ol=ob("olla");return {x:ol.x,y:ol.y-14,take:()=>{}};};

/* ---------- the places of story 35 ---------- */
const K1=[76,170],K2=[100,170],AZU=[146,170],TRANA=[168,170],GRECA35=[156,150],TABU=[178,150],CASA35=[122,166],CANELO=[204,203],TAZON=[172,203],STOOL=[204,166],CAFE35=[199,118],CAZO35=[218,118];   // the children's cups; the sugar bowl; the frog's cup; the greca (the little coffee pot) and abuela's cup, at the right end of the table; the frog's place; Canelo and his bowl; abuela's stool; the big coffee pot and the milk pan on the stove
const copa=id=>ob("t_"+id);
const liq=(id,v,vapor)=>{const t=copa(id);if(t){t.v=v;if(vapor!=null)t.vapor=vapor;}};
// something he pours: its lip is put at (tx,ty); it is turned over to pour to the right (flip), the stream falls h from the lip. For a person (p) or the frog (p = "rana"). The hand is where the handle is
function vierteItem(p,k,v,tx,ty,flip,h,col,e){const im=cosa("tilt"+k,v),E=e||1,s=flip?-1:1,ox=(im.pico[0]-im.width/2)*E*s,oy=(im.pico[1]-im.height/2)*E,cxA=tx-ox,cyA=ty-oy;
  if(p==="rana")return {k:"tilt"+k,v,dx:cxA-cx(),dy:pies()-cyA,e:E,flip:!!flip,chorro:{h,col}};
  const d=p.dir<0?-1:1;return {k:"tilt"+k,v,dx:(cxA-p.x)*d,dy:p.y-cyA,e:E,flip:!!flip,chorro:{h,col}};}
const CUCHITA=()=>({k:"uten",ax:9,ay:12,bx:17,by:15,load:"",o:{plata:1,rx:3,ry:2},gx:9,gy:12});   // the frog's teaspoon: the handle is shorter than his forearm
// the frog's hands: he takes a thing in his hand (he must stand beside it) and holds it at (dx,dy) from his feet; he sets it down with its foot at (x,y)
async function ranaToma(o,dx,dy,opt){opt=opt||{};const q=W.cq,e=o.e||1,im=cosa(o.k,o.v),cxw=o.x,cyw=o.y-im.height*e/2,izq=cxw<cx(),it=Object.assign({k:o.k,v:o.v,e:o.e,dx:cxw-cx(),dy:pies()-cyw},opt.extra||{});if(o.sp)it.sp=o.sp;if(o.vapor)it.vapor=o.vapor;
  const fl=CONASA.has(o.k)?it.dx>0:false;it.flip=fl;const H=agarres(it,cxw,cyw,fl)[0],sd=H[0]>=cx()?1:-1,r=rest=>[sd*9,3];
  const hb={k:"brazo",gx:sd*9,gy:3};q.tiene.push(hb);const g1=[H[0]-cx(),pies()-H[1]];for(let i=1;i<=3;i++){hb.gx=sd*9+(g1[0]-sd*9)*i/3;hb.gy=3+(g1[1]-3)*i/3;await wait(TICK);}
  q.tiene=q.tiene.filter(t=>t!==hb);o.vis=0;q.tiene.push(it);SFX.blip();await wait(TICK);if(dx!=null){const x0=it.dx,y0=it.dy,n=opt.m||4;for(let i=1;i<=n;i++){it.dx=x0+(dx-x0)*i/n;it.dy=y0+(dy-y0)*i/n;await wait(TICK);}}return it;}
async function ranaPon(it,o,x,y,n){const q=W.cq,e=it.e||1,im=cosa(it.k,it.v),t=[x-cx(),pies()-(y-im.height*e/2)],x0=it.dx,y0=it.dy;n=n||4;for(let i=1;i<=n;i++){it.dx=x0+(t[0]-x0)*i/n;it.dy=y0+(t[1]-y0)*i/n;await wait(TICK);}
  Object.assign(o,{v:it.v,x,y,vis:1});if(it.sp)o.sp=it.sp;q.tiene=q.tiene.filter(t=>t!==it);SFX.blip();await wait(TICK);}
// his teaspoon: where is its bowl, the frog's hand to take sugar from the bowl and take it to a cup
const bowlSugar=()=>ob("azucarera");
async function ranaCucharita(){const q=W.cq,az=bowlSugar();let sp=q.tiene.find(t=>t.k==="uten");
  if(!sp){await ranaA(AZU[0]-12,AZU[1]-2);sp=CUCHITA();const w=[AZU[0]+3,AZU[1]-17];sp.ax=w[0]-cx();sp.ay=pies()-w[1];sp.bx=sp.ax+8;sp.by=sp.ay+3;sp.gx=sp.ax;sp.gy=sp.ay;q.tiene.push(sp);az.spoons=Math.max(0,(az.spoons==null?8:az.spoons)-1);SFX.blip();await wait(TICK*2);}   // he takes one of the teaspoons that stand in the bowl
  await ranaA(AZU[0]-12,AZU[1]-2);await cucharaAR(sp,AZU[0]+1,AZU[1]-8,false,4);sp.load="azu";SFX.blip();await wait(TICK*2);return sp;}
// the teaspoon with sugar is brought to a cup (the cup is at (cxw,cyw) at the moment): the grains fall into it, he stirs, and the spoon stays standing in the cup (o: the cup, on the table, or the item a man holds)
async function azucarEn(cxw,cyw,sp,cup,mal){const q=W.cq,izq=cxw<cx()+0?true:false;
  const fx=cxw<150?cxw-16:cxw+16,fy=146,iz=fx>cxw;await ranaA(fx,fy);await cucharaAR(sp,cxw+(iz?4:-4),cyw-12,iz,5);
  sp.load="";SFX.blip();for(let i=0;i<4;i++){W.vuelos.push({k:"granos",x:cxw+(i%2?1:-1),y:cyw-13+i*2,e:1});await wait(TICK);W.vuelos.pop();}
  if(mal)cup.v="azu";else cup.sp=1;
  for(let k=0;k<4;k++){sp.bx+=(k%2?3:-3);await wait(TICK);}
  q.tiene=q.tiene.filter(t=>t!==sp);cup.sp=1;SFX.blip();await wait(TICK*2);}   // the spoon stays standing in the cup

/* ---------- moving: everybody walks, every thing is carried by a hand ---------- */
const PASO_PX=5;   // pixels a walker moves in one tick (about 70 a second)
// a walk: a straight line at a steady pace, one foot after the other. Nobody jumps from one place to another.
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y,dist=Math.hypot(x-x0,y-y0);if(dist<.5){p.x=x;p.y=y;return;}n=n||Math.max(1,Math.ceil(dist/PASO_PX));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;
  for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;p.ci=(p.ci||0)+1;p.pie=[1,0,2,0][p.ci%4];await wait(TICK);}p.x=x;p.y=y;p.paso=0;p.pie=0;}
async function ruta(id,pts){for(const q of pts)await mueve(id,q[0],q[1]);}
// a thing falls or slides a short way (grains, a roll off a tipped tray, a drop): never from a table to a hand
async function vuela(o,x0,y0,x1,y1,n,arco){const v=Object.assign({x:x0,y:y0},o);W.vuelos.push(v);n=n||5;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(x1-x0)*t;v.y=y0+(y1-y0)*t-(arco==null?0:arco)*Math.sin(t*Math.PI);await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);}
// the thing a person holds changes place in his hand: it slides from where it is to (dx,dy) from his feet
async function mueveTiene(id,it,dx,dy,n){n=n||5;const x0=it.dx,y0=it.dy;for(let i=1;i<=n;i++){it.dx=x0+(dx-x0)*i/n;it.dy=y0+(dy-y0)*i/n;await wait(TICK);}it.dx=dx;it.dy=dy;}
const corre=(o,pr)=>{if(o&&o.suelto){W._mov=pr;return Promise.resolve();}return pr;};
async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(3,R(d/40))));}
const cx=()=>W.cq.x+16,pies=()=>W.cq.y+27;
// where somebody comes in from (out of the picture, at the left: he walks in), where he goes out to (he walks out)
async function entra(id,x,y,dir){const p=G(id);p.sent=0;p.pose="idle";if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=y;}p.dir=1;p.tiene=p.tiene||[];await mueve(id,x,y);if(dir)p.dir=dir;}
async function sale(id){const p=G(id);if(p.vis===0)return;const front=p.y>150;p.sent=0;p.come=null;p.cara=null;p.pose="idle";p.abre=0;
  if(!front){await mueve(id,Math.min(p.x,SILLA[0]-12),ATRAS);await ruta(id,[[50,ATRAS+4],[PUERTA[0]+10,ATRAS+6]]);p.vis=0;return;}
  if(p.x>60)await mueve(id,50,Math.min(p.y,PUERTA[1]));await mueve(id,PUERTA[0],Math.min(p.y,PUERTA[1]));p.vis=0;}
// from the left end of the table to a chair behind it (round the end of the table, then along the lane behind), and sits
async function sienta(id,i){const p=G(id);if(p.vis!==0&&p.sent&&Math.abs(p.x-SILLA[i])<2)return;p.sent=0;if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=ATRAS+6;p.tiene=p.tiene||[];}
  if(p.y>150){if(p.x>56)await mueve(id,48,Math.min(p.y,180));await mueve(id,50,ATRAS+4);}
  await mueve(id,SILLA[i]-3,ATRAS);await mueve(id,SILLA[i],ASIENTO,3);p.sent=1;p.y=ASIENTO;p.dir=1;p.pose="idle";p.tiene=p.tiene||[];SFX.blip();}
// he stands up from his chair and walks round the end of the table to (x,y)
async function levanta(id,x,y){const p=G(id);p.sent=0;p.pose="idle";const x0=p.x;p.y=ATRAS;await wait(TICK*2);await mueve(id,Math.max(70,x0-3),ATRAS);await ruta(id,[[50,ATRAS+4],[48,Math.min(176,y)],[x,y]]);}

const SINTXT=new URLSearchParams(location.search).get("txt")==="no";   // with the words hidden a speaker still has an empty bubble over him, so that it is plain who speaks
const NINO=id=>!!(QUIEN[id]&&QUIEN[id].nino);
const LEP=id=>NINO(id)?[72,178]:LE;   // where somebody stands at the left end of the table: the children closer in, so that their short arms reach the basket and the board
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
const CUCH=lado=>lado?{k:"uten",ax:-10,ay:12,bx:-20,by:15,load:"",o:{plata:1,rx:5,ry:3},gx:-10,gy:12}:{k:"uten",ax:10,ay:12,bx:20,by:15,load:"",o:{plata:1,rx:5,ry:3},gx:10,gy:12};
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
  // The five rolls come split in the basket (cut open, empty), steaming; the second tray waits on the stove. Whoever asks walks in, takes a roll from the basket with his hand and holds it up; he sets it on the board and walks out to wash his hands;
  // the frog spoons the filling in and closes the roll; he walks in again, takes the roll off the board and bites it. A roll he did not like is bitten once and left on his plate, to the end. Every move is a hand's, and everybody walks.
  async inicio33(){W.gente={abuela:{x:FOGON[0],y:FOGON[1],dir:-1,tiene:[]},abuelo:{vis:0,tiene:[]},mama:{vis:0,tiene:[]},papa:{vis:0,tiene:[]},luis:{vis:0,tiene:[platoNino()]},carmen:{vis:0,tiene:[platoNino()]}};W.sitio={};
    const pl=(id,x)=>({id,k:"plato",x,y:FILA,rollos:[]});
    W.cosas=[pl("pl_abuela",SILLA[0]),pl("pl_abuelo",SILLA[1]),pl("pl_mama",SILLA[2]),pl("pl_papa",SILLA[3]),
      {id:"cesta",k:"cesta",v:"5:0",x:88,y:152,vapor:1,vdx:-2,vdy:18,vn:2},{id:"tabla",k:"tabla",x:84,y:170,rollo:null,malos:[]},
      {id:"mant",k:"mantequilla",v:"5",x:150,y:170},{id:"choc",k:"choc",v:"5",x:176,y:170},
      {id:"bandeja",k:"bandeja",v:4,x:206,y:121,vapor:1,vdx:0,vdy:12,vn:2}];
    Object.assign(W.cq,{x:134-16,y:FREN-2-27,s:1,sobre:1,dy:0,vis:1,tiene:[CUCH(0)],lleno:0,espalda:0,piensa:null});},
  // abuela walks round the table to her chair, takes her plate in her hand, carries it round the end of the table and sets it down close up to the basket; then she walks out to the yard
  async plato33(o){const ab=G("abuela"),pl=ob("pl_abuela");const pr=(async()=>{
      await ruta("abuela",[[FOGON[0],190],[56,190],[50,176],[48,ATRAS+4],[SILLA[0]+13,ATRAS]]);ab.dir=-1;await wait(TICK*2);
      const it=await toma("abuela",pl,null,null,{n:3});await mueveTiene("abuela",it,it.dx+1,it.dy+3,2);
      await ruta("abuela",[[50,ATRAS+4],[48,176],[58,190],[113,190]]);ab.dir=1;
      await pon("abuela",it,pl,113,151,4);await wait(TICK*2);await sale("abuela");})();return corre(o,pr);},
  // a person walks in to the left end of the table (hand: he takes a roll from the basket and holds it up, cut open and empty)
  async viene33(o){const id=o.a,p=G(id),ce=ob("cesta"),lp=LEP(id);
    if(p.vis!==0&&p.sent){await levanta(id,lp[0],lp[1]);}else await entra(id,lp[0],lp[1],1);
    p.dir=1;p.pose="idle";
    if(o.rollo){const w=[ce.x-5,ce.y-9],r0=rel(id,w[0],w[1]);await manoA(id,r0[0],r0[1],3);quitaCesta();SFX.blip();   // his hand takes a roll out of the basket
      const it={k:"rollo",v:"ab",e:1},c=centroPara(id,it,w[0],w[1]);it.dx=c[0];it.dy=c[1];sinManos(id);p.tiene.push(it);await wait(TICK*2);
      await mueveTiene(id,it,16,NINO(id)?27:34,4);await wait(TICK*3);}},   // he holds it up, beside his face, for the frog to see
  // he sets the roll he holds on the board, and walks out to wash his hands (fin: he is already done)
  async sale33(o){const id=o.a,p=G(id),tb=ob("tabla");if(+o.fin)return;
    const it=(p.tiene||[]).find(t=>t.k==="rollo");
    if(it){p.dir=1;await pon(id,it,{},tb.x,tb.y-3,4,{after:()=>{tb.rollo={st:"ab",dx:0};}});await wait(TICK*2);}
    await sale(id);},
  // the frog fills the roll on the board: his spoon takes the filling from its dish (the dish has less), he comes to the board, tips it into the roll and closes it. If there is no roll on the board yet he takes one from the basket
  // in his other hand, the spoon still in his right hand, and sets it on the board
  async rellena33(o){const id=o.a,k=String(o.k),dish=ob(k==="choc"?"choc":"mant"),tb=ob("tabla"),ce=ob("cesta"),q=W.cq;
    q.piensa=null;const sp=q.tiene.find(t=>t.k==="uten");
    if(!tb.rollo){await ranaA(122,160);   // beside the basket
      const hb={k:"brazo",gx:-8,gy:3};q.tiene.push(hb);for(let i=1;i<=3;i++){hb.gx=-8+(ce.x+2-cx()+8)*i/3;hb.gy=3+(pies()-(ce.y-8)-3)*i/3;await wait(TICK);}
      quitaCesta();SFX.blip();q.tiene=q.tiene.filter(t=>t!==hb);
      const r={k:"rollo",v:"ab",flip:true,dx:-12,dy:14};r.dx=ce.x+2-cx()+6;r.dy=pies()-(ce.y-8)+4;q.tiene.push(r);await wait(TICK*2);
      await ranaA(104,168);                                       // he hops with the roll in his left hand to the board
      const rt=[tb.x-cx()+6,pies()-(tb.y-3-7)-0];for(let i=1;i<=4;i++){r.dx+=(rt[0]-r.dx)/(5-i+1);r.dy+=(rt[1]-r.dy)/(5-i+1);await wait(TICK);}
      q.tiene=q.tiene.filter(t=>t!==r);tb.rollo={st:"ab",dx:0};SFX.blip();await wait(TICK*3);}
    // the spoon into the dish: he stands by it, the handle in his hand, the bowl in the dish
    const dx=k==="choc"?dish.x-17:dish.x-15,dyy=dish.y-9;await ranaA(dx,dyy);
    sp.load="";SFX.blip();const bx=dish.x-cx(),by=pies()-(dish.y-6);const bx0=sp.bx,by0=sp.by;for(let i=1;i<=4;i++){sp.bx=bx0+(bx-bx0)*i/4;sp.by=by0+(by-by0)*i/4;await wait(TICK);}await wait(TICK*2);
    sp.load=k==="choc"?"c":"m";dish.v=String(Math.max(1,+dish.v-1));SFX.blip();await wait(TICK*4);
    // to the board, the spoon in his other hand
    await ranaA(tb.x+34,tb.y-2);Object.assign(sp,CUCH(1));sp.load=k==="choc"?"c":"m";await wait(TICK*4);
    const bt=[tb.x-cx(),pies()-(tb.y-9)];const b0=[sp.bx,sp.by];for(let i=1;i<=3;i++){sp.bx=b0[0]+(bt[0]-b0[0])*i/3;sp.by=b0[1]+(bt[1]-b0[1])*i/3;await wait(TICK);}
    SFX.blip();sp.load="";tb.rollo.con=k==="choc"?"c":"m";await wait(TICK*6);
    tb.rollo.st="ce";SFX.blip();await wait(TICK*4);Object.assign(sp,CUCH(0));
    await ranaA(134,168);},
  // he walks in again and his hand takes the filled roll off the board; he goes to his chair (the children stay at the end of the table)
  async regresa33(o){const id=o.a,p=G(id),tb=ob("tabla"),nino=NINO(id),lp=LEP(id),seat={abuelo:1,mama:2,papa:3,abuela:0}[id];
    await entra(id,lp[0],lp[1],1);p.dir=1;p.pose="idle";
    const r=tb.rollo,v=r.st+(r.con?":"+r.con:""),w=[tb.x-6,tb.y-7],r0=rel(id,w[0],w[1]);
    await manoA(id,r0[0],r0[1],3);tb.rollo=null;SFX.blip();const it={k:"rollo",v,e:1},c=centroPara(id,it,w[0],w[1]);it.dx=c[0];it.dy=c[1];sinManos(id);p.tiene.push(it);await wait(TICK*2);
    await mueveTiene(id,it,16,nino?24:30,4);
    if(!nino){await sienta(id,seat);const i2=p.tiene.find(t=>t.k==="rollo");if(i2){i2.dx=16;i2.dy=24;}}},
  // he bites the roll (he lifts it to his mouth): right, he chews happily and eats it all, crumbs on his plate; wrong, he makes a face, puts it down on his plate with a bite out of it and pushes it a little away: there it stays
  async come33(o){const id=o.a,p=G(id),nino=NINO(id),pl=nino?null:ob("pl_"+id);const pr=(async()=>{
      const it=(p.tiene||[]).find(t=>t.k==="rollo");if(!it)return;const con=String(it.v).split(":")[1];
      const holder=nino?p.tiene.find(t=>t.k==="plato"):null,d=p.dir<0?-1:1;it.flip=d>0;
      const chew=async n=>{for(let i=0;i<n;i++){p.boca=1;await wait(TICK);p.boca=0;await wait(TICK);}};
      await mueveTiene(id,it,12,bocaY(id,p)-1,3);   // the roll at his mouth
      it.v="mo:"+con;SFX.blip();
      if(+o.bien){await chew(4);it.v="m2:"+con;SFX.blip();await chew(4);await suelta(id,it);SFX.blip();await chew(3);   // he eats it all
        if(pl)pl.v="mi";else if(holder)holder.v="mi";return;}
      p.cara="mal";SFX.bonk();p.dy=-2;await wait(TICK*3);p.dy=0;await wait(TICK*10);
      // he puts it down on his plate (seated: the plate in front of him; standing: the plate in his other hand) with the bite out of it, and pushes it a little away: there it stays
      if(pl){await mueveTiene(id,it,(pl.x-p.x)*d,p.y-(pl.y-10),5);ROLLOS(pl).push({st:"mo",con,dx:0,mal:1});SFX.blip();
        const r0=rel(id,pl.x,pl.y-8),hb={k:"brazo",_m:9,gx:r0[0],gy:r0[1],sh:1};p.tiene=p.tiene.filter(q=>q!==it);p.tiene.push(hb);
        await wait(TICK*2);for(let i=0;i<2;i++){pl.y+=2;hb.gy=p.y-(pl.y-8);await wait(TICK);}await wait(TICK);
        const rr=restHand(id);await manoA(id,rr[0],rr[1],3);sinManos(id);p.cara=null;}
      else{await mueveTiene(id,it,holder.dx,holder.dy+4,5);ROLLOS(holder).push({st:"mo",con,dx:0,mal:1});SFX.blip();await suelta(id,it);
        await mueveTiene(id,holder,holder.dx+4,holder.dy,3);await wait(TICK*4);p.cara=null;}   // he holds the plate away from him a little
      await wait(TICK*2);})();return corre(o,pr);},
  // the turn: abuela walks in from the yard, takes the tray off the stove in both hands, carries it along the front of the table to the basket and tips four hot rolls into it; she points at her own plate; she walks out with the tray
  async turno33(o){const ab=G("abuela"),ce=ob("cesta"),tr=ob("bandeja");
    ab.tiene=[];ab.pose="idle";ab.vis=1;ab.x=PUERTA[0];ab.y=190;ab.dir=1;
    await ruta("abuela",[[DER[0]-4,190],[FOGON[0],FOGON[1]]]);ab.dir=-1;await wait(TICK*2);
    const t0=await toma("abuela",tr,0,24,{n:3,vapor:1,m:3});t0.vapor=1;t0.vdy=12;
    await ruta("abuela",[[FOGON[0],190],[96,190]]);ab.dir=-1;await wait(TICK*3);
    // she tips the tray towards the basket, and the rolls slide off it into the basket, one after the other
    const n0=+t0.v;for(let i=0;i<n0;i++){t0.ang=.28;t0.v=String(n0-1-i);const ox=ab.x-ab.dir*6+0,oy=ab.y-24-2;await vuela({k:"rollo",v:"ab"},ox-8+i*4,oy-2,ce.x-6+i*5,ce.y-14,4,4);ce.v=(i+1)+":0";SFX.blip();await wait(TICK);}
    t0.ang=0;t0.vapor=0;await wait(TICK*3);},
  async apunta33(){const ab=G("abuela"),t0=(ab.tiene||[]).find(t=>t.k==="bandeja");if(t0){t0.una=1;await mueveTiene("abuela",t0,-12,22,3);}ab.dir=1;ab.pose="wave0";SFX.blip();await wait(TICK*10);ab.pose="idle";},
  async sale33a(){const ab=G("abuela");const t0=(ab.tiene||[]).find(t=>t.k==="bandeja");if(t0)await mueveTiene("abuela",t0,0,24,3);await sale("abuela");ab.tiene=[];},
  async miran33(){const pa=G("papa"),ca=G("carmen");pa.vis=ca.vis=0;pa.tiene=[];ca.tiene=[platoNino()];
    await Promise.all([entra("papa",LE[0],LE[1],1),(async()=>{await wait(TICK*7);await entra("carmen",86,186,1);})()]);await wait(TICK*9);
    await Promise.all([sale("papa"),(async()=>{await wait(TICK*4);await sale("carmen");})()]);},
  // the ending: the family walks in and sits (the children stand at the end of the table with their plates); abuela takes the roll that is left from the basket, eats it plain; the other, if any, she pulls the cloth over
  async final33(o){const ce=ob("cesta"),ab=G("abuela"),n=nCesta(),st=(t,fn)=>(async()=>{await wait(TICK*t);return fn();})();
    ab.tiene=[];
    await Promise.all([sienta("abuelo",1),st(6,()=>sienta("mama",2)),st(12,()=>sienta("papa",3)),st(3,()=>entra("luis",74,180,1)),st(9,()=>entra("carmen",56,186,1))]);
    G("luis").dir=1;G("carmen").dir=1;
    await entra("abuela",LE[0],LE[1],1);ab.dir=1;V.pan=n>0?"1":"";
    let it=null;
    if(n>0){const w=[ce.x-5,ce.y-9],r0=rel("abuela",w[0],w[1]);await manoA("abuela",r0[0],r0[1],3);quitaCesta();SFX.blip();it={k:"rollo",v:"ce",e:1};const c=centroPara("abuela",it,w[0],w[1]);it.dx=c[0];it.dy=c[1];sinManos("abuela");ab.tiene.push(it);await wait(TICK*2);await mueveTiene("abuela",it,14,24,3);}
    if(n>1){const w=[ce.x+12,ce.y-12],r0=rel("abuela",w[0],w[1]);const b=await manoA("abuela",r0[0],r0[1],4,-1);ce.v="1:1";ce.vapor=0;SFX.blip();await wait(TICK*3);sinManos("abuela");}else ce.vapor=0;
    await sienta("abuela",0);
    if(it){const bm=[12,bocaY("abuela",ab)-1];ab.dir=1;it.flip=true;await mueveTiene("abuela",it,bm[0],bm[1],3);
      for(let i=0;i<3;i++){it.v="mo";for(let j=0;j<3;j++){ab.boca=1;await wait(TICK);ab.boca=0;await wait(TICK);}it.v=i==0?"mo":"m2";SFX.blip();}
      ab.tiene=ab.tiene.filter(t=>t!==it);ob("pl_abuela").v="mi";const rr=restHand("abuela");await manoA("abuela",rr[0],rr[1],2);sinManos("abuela");}
    W.cq.hace=n>0?"come":null;await wait(TICK*8);},


  /* ----- story 34: Buen provecho ----- */
  // Lunch: yellow rice. Mamá (seat 1), Carmen (2) and abuelo (4) sit; papá's chair (3) and plate are empty; the baby sits in his high chair at the left end; Luis stands in front of the table, by the pot of rice, his plate and the frog's small plate; abuela is at the stove with the big spoon in her hand.
  // The platter waits on the stove, empty, with papá's fork on it: abuela carries it to the table at the turn.
  async inicio34(){
    W.gente={mama:{x:SILLA[0],y:ASIENTO,sent:1,dir:1,tiene:[]},carmen:{x:SILLA[1],y:ASIENTO,sent:1,dir:1,tiene:[]},abuelo:{x:SILLA[3],y:ASIENTO,sent:1,dir:1,tiene:[]},papa:{vis:0,tiene:[]},luis:{x:LUIS34[0],y:LUIS34[1],dir:1,tiene:[]},abuela:{x:FOGON[0],y:FOGON[1],dir:-1,tiene:[bigSpoon({ax:8,ay:24,bx:11,by:38})]}};W.sitio=SEAT34;W.turno=0;
    const pl=(id,x,v)=>({id,k:"plato",x,y:FILA,v:v||"",rollos:[]});
    W.cosas=[pl("pl_mama",SILLA[0],"r"),pl("pl_carmen",SILLA[1],"r"),pl("pl_papa",SILLA[2]),pl("pl_abuelo",SILLA[3],"r"),
      {id:"pl_luis",k:"plato",x:PLUIS[0],y:PLUIS[1],v:"r",rollos:[]},{id:"pl_rana",k:"platito",x:PRANA[0],y:PRANA[1]},
      {id:"olla",k:"olla",v:"lleno0",x:OLLA[0],y:OLLA[1],vapor:1},{id:"silla_bebe",k:"sillaBebe",v:"1",x:HIJA[0],y:HIJA[1]},{id:"fuente",k:"fuente",v:"c",x:PLAT34[0],y:PLAT34[1],montones:[],tenedor:{dx:-13,dy:3}}];
    Object.assign(W.cq,{x:CASA34[0]-16,y:CASA34[1]-27,s:1,sobre:1,dy:0,vis:1,tiene:[],lleno:0,espalda:0,piensa:null,nube:[184,128],nubeAim:[184,150],ndir:1});},
  // everybody holds a fork up and waits; then they eat
  async tenedores34(o){[["mama",46],["carmen",39],["abuelo",46],["luis",40]].forEach(a=>{const p=G(a[0]);p.tiene=[TENE("tenedor",15,a[1],{e:1})];});SFX.blip();await wait(TICK*8);},
  async come34(o){const pr=(async()=>{["mama","carmen","abuelo"].forEach(id=>{const p=G(id);p.tiene=[];p.pose="idle";p.come={k:"tenedor",dx:11};});await wait(TICK*17);["mama","carmen","abuelo"].forEach(id=>{G(id).come=null;});})();return corre(o,pr);},
  // Luis eats his last forkfuls: his plate is clean
  async luisCome34(o){const l=G("luis"),pl=ob("pl_luis");const pr=(async()=>{l.tiene=[];l.pose="idle";l.come={k:"tenedor",dx:11};await wait(TICK*16);l.come=null;pl.v="";})();return corre(o,pr);},
  // abuela walks to Luis with the big spoon, holds it out and he takes it in his hand; she goes back to the stove
  async cuchara34(o){const ab=G("abuela"),l=G("luis");
    await ruta("abuela",[[FOGON[0],190],[LUIS34[0]+22,190]]);ab.dir=-1;const sp=spoonOf("abuela");await cucharaA("abuela",sp,ab.x-26,ab.y-27,4);await wait(TICK*2);
    const sp2=await pasaCuchara("abuela","luis");await cucharaA("luis",sp2,...luisRest(),5);await wait(TICK*2);
    await ruta("abuela",[[FOGON[0],190],[FOGON[0],FOGON[1]]]);ab.dir=-1;},
  // Luis: sirve (he serves himself one mound onto his plate), come (he eats it), cuchara (he lifts a mound onto the big spoon and holds it out to the frog: tiende), entrega (he hands the frog the spoon with the mound on it); de "p": the mound comes from papá's three
  async luis34(o){const l=G("luis"),pl=ob("pl_luis"),pr=(async()=>{
      if(!spoonOf("luis"))l.tiene.push(bigSpoon());const sp=spoonOf("luis"),g=o.de==="p"?"p":"m";
      const toma=async()=>{let s=fuenteMonton(g);if(s&&s.fu.x>200)s=null;if(g==="p"&&!s)s=fuenteMonton("m");const src=origen(),pt=s?{x:s.x,y:s.y}:{x:src.x,y:src.y};
        await cucharaA("luis",sp,pt.x,pt.y+3,6);sp.load="monton";if(s)s.fu.montones.splice(s.fu.montones.indexOf(s.m),1);SFX.blip();await wait(TICK*3);};
      const reposo=async n=>{const r=luisRest();await cucharaA("luis",sp,r[0],r[1],n||5);};
      if(o.que==="sirve"){await toma();await cucharaA("luis",sp,PLUIS[0],PLUIS[1]-6,6);sp.load="";pl.v="o";SFX.blip();await wait(TICK*3);await reposo(4);}
      else if(o.que==="come"){l.come={k:"tenedor",dx:11};pl.v="";SFX.blip();await wait(TICK*11);l.come=null;}
      else if(o.que==="cuchara"){await toma();await cucharaA("luis",sp,PRANA[0]-4,PRANA[1]-14,6);await wait(TICK*3);}   // he holds it out towards the frog
      else if(o.que==="entrega"){await toma();await cucharaA("luis",sp,PRANA[0]-10,PRANA[1]-14,5);await pasaCuchara("luis","rana");SFX.blip();await wait(TICK*2);}})();return corre(o,pr);},
  // a thought over the frog: what he would like (quiere) or his belly beside the clean plate (lleno). Its trail leads to him.
  async piensa34(o){W.cq.piensa=o.k==="lleno"?{k:"barriga"}:{k:"montoncor"};SFX.blip();await wait(TICK*4);},
  async calla34(){W.cq.piensa=null;},
  // the mound on Luis's spoon goes onto the frog's plate (he tips the spoon over it); the frog takes it in his hand and eats it
  async ranaCome34(o){const l=G("luis"),pl=ob("pl_rana"),q=W.cq;const pr=(async()=>{q.piensa=null;const sp=spoonOf("luis");
      if(sp){await cucharaA("luis",sp,PRANA[0],PRANA[1]-7,6);sp.load="";pl.v="o";SFX.blip();await wait(TICK*3);const r=luisRest();await cucharaA("luis",sp,r[0],r[1],4);}
      await ranaA(PRANA[0]+14,PRANA[1]-4);const m={k:"monton",dx:-12,dy:3};q.tiene.push(m);pl.v="";SFX.blip();await wait(TICK*2);
      for(let i=1;i<=3;i++){m.dx=-12+12*i/3;m.dy=3+9*i/3;await wait(TICK);}   // he lifts it to his mouth
      q.hace="come";await wait(TICK*8);q.hace=null;q.tiene=q.tiene.filter(t=>t!==m);pl.v="mi";if(o.lleno)q.lleno=1;SFX.blip();
      if(o.entera){q.espalda=1;SFX.bonk();await wait(TICK*10);}else await ranaA(CASA34[0],CASA34[1]);})();return corre(o,pr);},
  async levantaRana34(){const q=W.cq;q.espalda=0;SFX.blip();await wait(TICK*3);await ranaA(CASA34[0],CASA34[1]);},
  // Luis eats the mound on the spoon too (the spoon goes up to his mouth)
  async luisCome2(o){const l=G("luis");const pr=(async()=>{W.cq.piensa=null;const sp=spoonOf("luis");if(sp){await cucharaA("luis",sp,l.x+9,l.y-bocaY("luis",l)-2,5);sp.load="";l.boca=1;SFX.blip();for(let i=0;i<4;i++){l.boca=1;await wait(TICK);l.boca=0;await wait(TICK);}const r=luisRest();await cucharaA("luis",sp,r[0],r[1],4);}})();return corre(o,pr);},
  // Luis glances at papá's fork and takes one of papá's three for the frog (rana) or for himself (luis)
  async luisPapa34(o){const l=G("luis");await wait(TICK*6);
    if(o.para==="rana"){await acts.luis34({que:"cuchara",de:"p"});await acts.ranaCome34({});}
    else{await acts.luis34({que:"sirve",de:"p"});await acts.luis34({que:"come"});}},
  // steps 5 and 6: the three at the table; whoever says "Yo estoy lleno/llena" puts a hand on his belly
  async mano34(o){const p=G(o.a);p.pose=o.pose||"yo";SFX.blip();await wait(TICK*2);},
  async plato34(o){const pl=ob("pl_"+o.a);pl.v=o.v||"";},
  // the frog hops along the cloth with the spoon (Luis handed it to him) to the plate of the one at his seat and tips the mound onto it, where it mixes into his rice (mezcla), or the one eats it; then he takes the spoon back to Luis
  async tipa34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),q=W.cq,l=G("luis");const pr=(async()=>{q.piensa=null;const L=lado34(pl.x),sp=q.tiene.find(t=>t.k==="uten");if(!sp)return;
      await ranaA(L.fx,L.fy);await cucharaAR(sp,pl.x+(L.izq?-3:3),pl.y-8,!!L.izq,5);sp.load="";
      if(+o.mezcla){pl.v="h";SFX.bonk();await wait(TICK*6);}else{pl.v="rm";SFX.blip();await wait(TICK*4);p.pose="idle";p.come={k:"tenedor",dx:11};await wait(TICK*11);p.come=null;pl.v="";}
      const r=luisRest();await ranaA(r[0]+12,r[1]+12);await cucharaAR(sp,r[0],r[1],false,3);
      const sp2={k:"uten",ax:0,ay:0,bx:0,by:0,load:"",o:sp.o},w_={h:[cx()+sp.ax,pies()-sp.ay],b:[cx()+sp.bx,pies()-sp.by]},rr=rel("luis",w_.h[0],w_.h[1]);await manoA("luis",rr[0],rr[1],3,0);
      Object.assign(sp2,{ax:rr[0],ay:rr[1],bx:w_.b[0]-R(l.x),by:R(l.y)-w_.b[1]});sinManos("luis");l.tiene.push(sp2);q.tiene=q.tiene.filter(t=>t!==sp);SFX.blip();await wait(TICK*2);
      await cucharaA("luis",sp2,r[0],r[1],3);await ranaA(CASA34[0],CASA34[1]);})();return corre(o,pr);},
  // whoever was full only now puts a hand on his belly and pushes his plate a little away
  async llenoAhora34(o){const p=G(o.a),pl=ob("pl_"+o.a);p.pose="yo";SFX.blip();await wait(TICK*3);const r=rel(o.a,pl.x,pl.y-8),hb={k:"brazo",_m:9,gx:r[0],gy:r[1],sh:1};p.pose="idle";p.tiene.push(hb);for(let i=0;i<2;i++){pl.y+=2;hb.gy=p.y-(pl.y-8);await wait(TICK);}const rr=restHand(o.a);await manoA(o.a,rr[0],rr[1],2);sinManos(o.a);p.pose="yo";await wait(TICK*3);},
  // gets up and says it to the table (a line follows). mamá walks to the high chair and takes the baby in her hands (in the game she walks out with him); with plato he takes his plate, carries it to the counter and leaves it there; otherwise he goes out
  async levanta34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),x0=p.x,sb=ob("silla_bebe"),juego=!!W.turno;p.pose="idle";SFX.blip();await mueve(id,x0,ATRAS,2);
    if(id==="mama"){await ruta(id,[[66,ATRAS+4],[HIJA[0]+13,HIJA[1]]]);p.dir=-1;const bw=[HIJA[0]-1,HIJA[1]-26];   // her hands reach for the baby
      const r=rel(id,bw[0],bw[1]+7);await manoA(id,r[0],r[1],3);sb.v="0";const it={k:"bebe",e:1};const c=centroPara(id,it,bw[0],bw[1]+7);it.dx=c[0];it.dy=c[1];sinManos(id);p.tiene=[it];SFX.blip();await wait(TICK*2);   // he is in her hands in the same moment the chair is empty
      await mueveTiene(id,it,8,26,4);if(juego)await sale(id);}
    else if(+o.plato){const it=await toma(id,pl,null,null,{n:3});await mueveTiene(id,it,16,30,3);await ruta(id,[[50,ATRAS+4],[52,142],[60,146]]);p.dir=-1;await pon(id,it,pl,56,118,4,{after:q=>{q.z=119;}});p.dir=1;}
    else{await sale(id);}},
  // she comes back to her chair: mamá puts the baby back in his chair first; Carmen takes her plate from the counter, carries it to her place, sets it down in front of her and sits
  async vuelve34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),sb=ob("silla_bebe"),seat=SEAT34[id];
    if(id==="mama"){await ruta(id,[[HIJA[0]+13,HIJA[1]]]);p.dir=-1;const it=p.tiene.find(t=>t.k==="bebe");await mueveTiene(id,it,1,28,3);sb.v="1";await suelta(id,it);SFX.blip();await wait(TICK*2);await sienta(id,seat);return;}
    if(+o.plato){p.dir=-1;const it=await toma(id,pl,16,30,{n:3});await ruta(id,[[50,ATRAS+4],[SILLA[seat]-8,ATRAS]]);p.dir=1;await pon(id,it,Object.assign(pl,{z:null}),SILLA[seat],FILA,4);await sienta(id,seat);}},
  // after a miss: a second mound, from papá's three, for the one who asked: Luis takes it with the spoon, hands it to the frog, the frog tips it onto his plate and he eats it
  async papaB34(o){await acts.luis34({que:"entrega",de:"p"});await acts.tipa34({a:o.a});},
  async mira34(o){const l=G("luis");l.dir=1;await wait(TICK*7);},
  // the turn. Abuela takes the platter off the stove in both hands and carries it to the table; Luis gives her the big spoon and steps aside; she lifts the pot with one hand and carries it behind the table, where she gives each of the three at the table a small spoon of rice;
  // she brings the pot back to the platter and scoops it onto it, mound by mound (seven: four helpings in front, papá's three behind, at his end), moves papá's fork on to them with the spoon, gives the spoon back to Luis and walks out with the pot
  async turno34(o){const ab=G("abuela"),l=G("luis"),ol=ob("olla"),fu=ob("fuente");W.turno=1;
    const pf=await toma("abuela",fu,0,22,{n:3,m:3,extra:{tenedor:fu.tenedor,montones:fu.montones}});pf.v="";
    await ruta("abuela",[[FOGON[0],190],[FU34[0]+8,190]]);ab.dir=-1;await pon("abuela",pf,fu,FU34[0],FU34[1],4);await wait(TICK*2);
    // Luis gives her the spoon
    await ruta("abuela",[[LUIS34[0]+20,190]]);ab.dir=-1;const spL=spoonOf("luis");await cucharaA("luis",spL,l.x+22,l.y-30,3);await wait(TICK);
    const spA=await pasaCuchara("luis","abuela");spA.side=1;await mueve("luis",58,190);l.dir=1;
    // she lifts the pot by its handle
    await ruta("abuela",[[OLLA[0]+4,190]]);ab.dir=-1;
    const pot=await toma("abuela",ol,-2,24,{n:3,m:3,extra:{una:"h"}});
    const potW=()=>[R(ab.x)+D1(ab)*pot.dx,R(ab.y)-pot.dy];
    const scoop=async(wx,wy)=>{const pw=potW();await cucharaA("abuela",spA,pw[0],pw[1]-5,4);spA.load="monton";SFX.blip();await wait(TICK*2);await cucharaA("abuela",spA,wx,wy,5);spA.load="";};
    // round the left end of the table to the lane behind it, and a small spoon of rice onto each of the three plates
    await ruta("abuela",[[50,188],[50,ATRAS+6]]);
    for(const id of ["mama","carmen","abuelo"]){const pl=ob("pl_"+id),sx=pl.x+11;await mueve("abuela",sx,ATRAS);ab.dir=-1;await scoop(pl.x,pl.y-7);pl.v="r";SFX.blip();await wait(TICK*3);}
    // back along the right end of the table to the front of the platter
    await ruta("abuela",[[196,ATRAS+4],[196,188],[FU34[0]+14,190]]);ab.dir=-1;
    const xs=[-16,-6,4,14,-14,-4,6],ys=[-2,-2,-2,-2,-12,-12,-12];
    for(let i=0;i<7;i++){await scoop(fu.x+xs[i],fu.y+ys[i]-6);fu.montones.push({dx:xs[i],dy:ys[i],g:i<4?"m":"p"});SFX.blip();await wait(TICK*2);}
    pot.v="vacio";ol.v="vacio";await wait(TICK*3);
    // she moves papá's fork on to his three mounds with the spoon, and lays it flat there
    const f0=fu.tenedor,fx=fu.x+f0.dx,fy=fu.y-f0.dy;await cucharaA("abuela",spA,fx-5,fy,4);for(let i=1;i<=4;i++){f0.dx=-13+(-4+13)*i/4;f0.dy=5+(18-5)*i/4;await cucharaA("abuela",spA,fu.x+f0.dx-5,fu.y-f0.dy,1);}
    await wait(TICK*3);
    // she gives the spoon back to Luis and walks out with the pot
    await ruta("abuela",[[LUIS34[0]+22,190]]);ab.dir=-1;await cucharaA("abuela",spA,ab.x-26,ab.y-27,3);l.dir=1;await mueve("luis",LUIS34[0],LUIS34[1]);
    const spL2=await pasaCuchara("abuela","luis");await cucharaA("luis",spL2,...luisRest(),4);
    ab.tiene=ab.tiene.filter(t=>t!==spA);await sale("abuela");},
  // papá walks in with abuela; he sits; abuela carries the platter with what is left of it round to his chair and tips it onto his plate (the fork too), then takes the platter back to the stove
  async final34(o){const ab=G("abuela"),pa=G("papa"),l=G("luis"),fu=ob("fuente"),pl=ob("pl_papa");pa.vis=0;ab.vis=0;pa.tiene=[];ab.tiene=[];ab.pose="idle";
    const pr=sienta("papa",2);await wait(TICK*7);await entra("abuela",FU34[0]+8,190,-1);await pr;
    const pf=await toma("abuela",fu,0,22,{n:3,m:3,extra:{tenedor:fu.tenedor,montones:fu.montones}});
    await ruta("abuela",[[196,188],[196,ATRAS+4],[SILLA[2]+13,ATRAS]]);ab.dir=-1;await wait(TICK*2);
    const n=fu.montones.filter(m=>m.g==="p").length;
    pf.ang=-.3;const base=[R(ab.x)+D1(ab)*pf.dx,R(ab.y)-pf.dy];
    for(let i=0;i<n;i++){const m=fu.montones.filter(m=>m.g==="p")[0];if(!m)break;fu.montones.splice(fu.montones.indexOf(m),1);await vuela({k:"monton"},base[0]-14,base[1]-2,pl.x,pl.y-8,4,5);pl.v="p"+(i+1);SFX.blip();await wait(TICK);}
    if(fu.tenedor){const f0=fu.tenedor;fu.tenedor=null;pf.tenedor=null;await vuela({k:"tenedorH"},base[0]-14,base[1]-2,pl.x+2,pl.y-12,4,5);W.cosas.push({id:"tenedor_papa",k:"tenedorH",x:pl.x+2,y:pl.y-9,z:pl.y+.5});SFX.blip();}
    pf.ang=0;V.pmont=String(n);await wait(TICK*3);
    await ruta("abuela",[[196,ATRAS+4],[196,188],[FOGON[0],190],[PLAT34[0],155]]);ab.dir=-1;pf.v="c";await pon("abuela",pf,fu,PLAT34[0],PLAT34[1],4);ab.dir=-1;},
  async papaCome34(o){const pa=G("papa"),pl=ob("pl_papa");const pr=(async()=>{const fk=ob("tenedor_papa");
      if(fk&&fk.vis!==0){const it=await toma("papa",fk,null,null,{n:3});it.k="tenedor";it.e=1;const m=await mueveTiene("papa",it,11,bocaY("papa",pa)-6,3);pa.tiene=pa.tiene.filter(t=>t!==it);pa.come={k:"tenedor",dx:11};}else pa.come={k:"tenedor",dx:11};
      await wait(TICK*16);if(o.fin){pa.come=null;pl.v="mi";}})();return corre(o,pr);},
  async papaMira34(){const pa=G("papa");pa.dir=1;pa.pose="idle";await wait(TICK*13);},
  /* ----- story 35: Café con azúcar ----- */
  // The table is cleared. Abuelo (chair 2) and papá (chair 4) have black coffee; Luis and Carmen hold cups of hot milk at the left end, beside their faces; the frog stands by the sugar bowl (teaspoons stand in it), his own small cup by him. On the stove: the big blue coffee pot (left burner) and the milk pan (right burner);
  // the greca (the little red coffee pot) and abuela's own big cup stand at the right end of the table; her stool stands by the stove. Canelo lies by his empty bowl.
  async inicio35(){const taza=()=>[TENE("taza",13,16,{v:"leche",vapor:1,vh:6})];
    W.gente={abuelo:{x:SILLA[1],y:ASIENTO,sent:1,dir:1,tiene:[]},papa:{x:SILLA[3],y:ASIENTO,sent:1,dir:-1,tiene:[]},luis:{x:72,y:178,dir:1,tiene:taza()},carmen:{x:88,y:186,dir:1,tiene:taza()},abuela:{x:FOGON[0],y:FOGON[1],dir:-1,tiene:[]},mama:{vis:0,tiene:[]}};W.sitio={abuelo:1,papa:3};
    W.cosas=[{id:"taburete",k:"taburete",x:STOOL[0],y:STOOL[1]},{id:"t_abuelo",k:"taza",x:SILLA[1],y:FILA,v:"negro",vapor:1,vdy:19,vh:7},{id:"t_papa",k:"taza",x:SILLA[3],y:FILA,v:"negro",vapor:1,vdy:19,vh:7},
      {id:"t_luis",k:"taza",x:K1[0],y:K1[1],v:"leche",vapor:1,vdy:20,vis:0},{id:"t_carmen",k:"taza",x:K2[0],y:K2[1],v:"leche",vapor:1,vdy:20,vis:0},
      {id:"azucarera",k:"azucarera",x:AZU[0],y:AZU[1],spoons:8},{id:"t_rana",k:"taza",x:TRANA[0],y:TRANA[1],v:"vacia",vapor:0},{id:"t_abuela",k:"taza",x:TABU[0],y:TABU[1],v:"vacia",vapor:0,e:1},
      {id:"cafetera",k:"cafetera",x:CAFE35[0],y:CAFE35[1],vapor:1,vdx:-2,vdy:30,vn:1},{id:"cazo",k:"cazo",v:"1",x:CAZO35[0],y:CAZO35[1]},{id:"jarrita",k:"jarrita",x:GRECA35[0],y:GRECA35[1]+4},{id:"tazon",k:"tazon",v:"0",x:TAZON[0],y:TAZON[1]}];
    W.perro={x:CANELO[0],y:CANELO[1],pose:"lie",dir:-1};W.pote={};
    Object.assign(W.cq,{x:CASA35[0]-16,y:CASA35[1]-27,s:1,sobre:1,dy:0,vis:1,tiene:[],lleno:0,espalda:0,piensa:null,mal:0,nube:[60,112],nubeAim:[124,146],ndir:-1});},
  // the men take their cups in their hands and hold them out over the table, looking at the middle (where abuela and the frog are); or set them down
  async tienden35(o){await Promise.all(String(o.a).split(",").map(id=>{const t=copa(id),p=G(id);if(p.tiene.some(x=>x.k==="taza"||x.k==="tazacu"))return Promise.resolve();return toma(id,t,14,16,{n:3,m:3,extra:t.sp?{sp:t.sp}:{}}).then(it=>{it.v=t.v;if(t.sp)it.sp=t.sp;});}));await wait(TICK*2);},
  async bajan35(o){await Promise.all(String(o.a).split(",").map(async id=>{const p=G(id),it=p.tiene.find(x=>x.k==="taza"),t=copa(id);if(!it)return;it.k=it.sp?"tazacu":"taza";const x=t.x,y=t.y;t.v=it.v;t.vapor=it.vapor;await pon(id,it,t,x,y,3,{after:q=>{q.v=it.v;q.vapor=it.vapor;if(it.sp)q.sp=1;}});}));await wait(TICK);},
  // abuela takes the big pot off the stove and walks behind the table to the empty chair between the two men
  async trae35(o){const ab=G("abuela"),ce=ob("cafetera");ab.dir=-1;ab.pose="idle";if(!ab.tiene.some(t=>t.k==="cafetera")){if(Math.abs(ab.x-FOGON[0])>6||Math.abs(ab.y-FOGON[1])>6)await ruta("abuela",[[FOGON[0],FOGON[1]]]);ab.dir=-1;await toma("abuela",ce,9,15,{n:3,m:3,vapor:1});}
    await ruta("abuela",[[196,146],[188,ATRAS],[150,ATRAS],[138,ASIENTO-2]]);ab.dir=-1;},
  async vuelve35(o){const ab=G("abuela"),ce=ob("cafetera"),it=ab.tiene.find(t=>t.k==="cafetera"||t.k==="tiltcafetera");if(!it)return;it.k="cafetera";await ruta("abuela",[[150,ATRAS],[188,ATRAS],[196,146],[FOGON[0],FOGON[1]]]);ab.dir=-1;await pon("abuela",it,ce,CAFE35[0],CAFE35[1],4);ce.vapor=1;},
  // the frog fills a teaspoon at the sugar bowl: a spoon from among the others, dipped into the sugar
  async llena35(){await ranaCucharita();},
  // the frog brings the teaspoon of sugar to the cup of the one touched (mal: it already had its sugar: two heaps): the grains fall into it in view, he stirs, and the spoon stays standing in the cup
  async azucar35(o){const id=o.a,p=G(id),mal=+o.mal;const pr=(async()=>{const q=W.cq;let sp=q.tiene.find(t=>t.k==="uten");if(!sp||sp.load!=="azu")sp=await ranaCucharita();
      const it=p.tiene.find(x=>x.k==="taza"||x.k==="tazacu"),d=D1(p),cxw=R(p.x)+d*it.dx,cyw=R(p.y)-it.dy;await azucarEn(cxw,cyw,sp,it,mal);if(!mal)it.k="tazacu";await ranaA(CASA35[0],CASA35[1]);})();return corre(o,pr);},
  // abuela pours coffee into a cup from the big pot she holds (mal: the last finger, into the same cup)
  async cafe35(o){const id=o.a,t=copa(id),ab=G("abuela"),p=G(id);const pr=(async()=>{const cup=p.tiene.find(x=>x.k==="taza"||x.k==="tazacu"),dd=D1(p),cxx=cup?R(p.x)+dd*cup.dx:t.x,left=cxx<ab.x,tx=cxx+(left?7:-7),ty=cup?R(p.y)-cup.dy-12:t.y-24;ab.dir=left?-1:1;
      const up=ab.tiene.find(x=>x.k==="cafetera"),tilt=vierteItem(ab,"cafetera","",tx,ty,!left,12,"#2A160C");ab.tiene=ab.tiene.filter(x=>x!==up);ab.tiene.push(tilt);SFX.blip();await wait(+o.dedo?TICK*8:TICK*14);
      if(cup){if(+o.mal)cup.v="azu";else if(+o.llena){cup.v="negro";cup.vapor=1;}}else{if(+o.mal)t.v="azu";}
      ab.tiene=ab.tiene.filter(x=>x!==tilt);ab.tiene.push(up);await wait(TICK*2);})();return corre(o,pr);},
  async prueba35(o){for(const id of String(o.a).split(",")){const p=G(id);p.dy=-2;await wait(TICK*2);p.dy=0;await wait(TICK*2);}},
  // the man looks at his cup (two heaps of sugar) and sets it down at his own place; he is cross and stays so while it stands in front of him
  async empuja35(o){const id=o.a,p=G(id),it=p.tiene.find(x=>x.k==="taza"||x.k==="tazacu"),t=copa(id);await wait(TICK*5);p.cara="mal";SFX.bonk();await wait(TICK*4);
    if(it){it.vapor=0;it.v="azu";t.v="azu";t.vapor=0;const x=t.x,y=t.y;await pon(id,it,t,x,y,4,{after:q=>{q.v="azu";q.vapor=0;q.sp=1;}});}await wait(TICK*3);},
  // abuela gives the frog the little pot: she takes the greca from the right end of the table, carries it to him and sets it where he can take it; he takes it in his hand. The children set their cups of milk in front of the frog (ponen), walk out (salen), walk in (vuelven) and drink (toman)
  async pote35(o){const ab=G("abuela"),jt=ob("jarrita"),q=W.cq;
    await ruta("abuela",[[FOGON[0],190],[GRECA35[0]+4,190]]);ab.dir=-1;const it=await toma("abuela",jt,6,24,{n:3,m:3});it.flip=true;
    await ruta("abuela",[[150,190]]);ab.dir=-1;await pon("abuela",it,jt,138,172,4);
    await ruta("abuela",[[FOGON[0],190],[FOGON[0],FOGON[1]]]);ab.dir=-1;
    await ranaA(150,170);const gi=await ranaToma(jt,-14,14,{n:3,m:3});gi.flip=true;await ranaA(CASA35[0],CASA35[1]);},
  async ninos35(o){const l=G("luis"),ca=G("carmen"),tl=copa("luis"),tc=copa("carmen"),cupOf=p=>p.tiene.find(x=>x.k==="taza");
    const fresco=async(id,x,y)=>{const p=G(id),it=cupOf(p);if(it&&it.v==="vacia"){await sale(id);it.v="leche";it.vapor=1;it.vh=6;await entra(id,x,y,1);}};   // a child with an empty cup walks out and comes back with a fresh cup of milk
    if(o.que==="ponen"){await Promise.all([(async()=>{await fresco("luis",72,178);const it=cupOf(l);await mueveTiene("luis",it,16,22,2);await pon("luis",it,tl,K1[0],K1[1],4,{after:q=>{q.v="leche";q.vapor=1;}});})(),
        (async()=>{await wait(TICK*3);await fresco("carmen",88,186);await mueve("carmen",86,186);const it=cupOf(ca);await mueveTiene("carmen",it,16,22,2);await pon("carmen",it,tc,K2[0],K2[1],4,{after:q=>{q.v="leche";q.vapor=1;}});})()]);}
    else if(o.que==="salen"){await Promise.all([sale("luis"),(async()=>{await wait(TICK*3);await sale("carmen");})()]);}
    else if(o.que==="vuelven"){await Promise.all([entra("luis",72,178,1),(async()=>{await wait(TICK*3);await entra("carmen",88,186,1);})()]);}
    else if(o.que==="toman"){const pr=(async()=>{const drink=async(id,t)=>{const p=G(id),it=await toma(id,t,13,16,{n:3,m:3});it.v=t.v;it.vapor=0;it.vh=0;await mueveTiene(id,it,12,bocaY(id,p)-2,3);it.ang=.35;SFX.blip();for(let i=0;i<5;i++){p.boca=1;await wait(TICK);p.boca=0;await wait(TICK);}it.ang=0;it.v="vacia";await mueveTiene(id,it,13,16,3);};   // he keeps the empty cup in his hand
        await Promise.all([drink("luis",tl),(async()=>{await wait(TICK*4);await drink("carmen",tc);})()]);})();return corre(o,pr);}
    else if(o.que==="dejan"){await Promise.all([["luis",tl,K1],["carmen",tc,K2]].map(async([id,t,k],i)=>{await wait(TICK*3*i);const it=cupOf(G(id));if(!it)return;await pon(id,it,t,k[0],k[1],4,{after:q=>{q.v=it.v;q.vapor=0;}});}));}},
  // the frog pours as told from the greca in his hand: a long pour (mucho) turns the milk brown; a splash (poco) turns it pale
  async vierte35(o){const id=o.a,t=copa(id),q=W.cq,mucho=o.cant==="mucho",izq=t.x<90;const fx=izq?98:92,fy=148;await ranaA(fx,fy);
    const jt=q.tiene.find(i=>i.k==="jarrita"),up=jt;const tilt=vierteItem("rana","jarrita","",t.x,t.y-22,!izq,12,"#3E2414");q.tiene=q.tiene.filter(i=>i!==jt);q.tiene.push(tilt);SFX.blip();
    await wait(mucho?TICK*4:TICK*2);liq(id,"palido",1);if(mucho){await wait(TICK*10);liq(id,"marron",1);await wait(TICK*6);}else await wait(TICK*4);
    q.tiene=q.tiene.filter(i=>i!==tilt);q.tiene.push(Object.assign(up,{flip:true}));await wait(TICK*2);await ranaA(CASA35[0],CASA35[1]);},
  // the frog's own cup, the thoughts and answers of step 6
  async piensa35(o){W.cq.piensa=o.k?{k:"taza",v:o.k,e:1}:null;if(o.k)SFX.blip();await wait(TICK*4);},
  // abuela pours for the frog: the frog sets the little pot down beside his cup; abuela takes the milk pan off the stove, takes the little pot from beside his cup, pours a stream of coffee from it into his cup, sets it down, and pours the milk (a white stream)
  async sirve6(o){const mucho=o.cant==="mucho",q=W.cq,ab=G("abuela"),t=copa("rana"),cz=ob("cazo"),pote=ob("jarrita");q.piensa=null;
    const jt=q.tiene.find(i=>i.k==="jarrita");if(jt){await ranaA(TRANA[0]+16,TRANA[1]-2);await ranaPon(jt,pote,TRANA[0]+16,TRANA[1]+2,3);await ranaA(CASA35[0],CASA35[1]);}
    await ruta("abuela",[[FOGON[0],FOGON[1]]]);ab.dir=-1;const pan=await toma("abuela",cz,8,18,{n:3,m:3});
    await ruta("abuela",[[FOGON[0],190],[TRANA[0]+26,190]]);ab.dir=-1;const gr=await toma("abuela",pote,-9,20,{n:3,m:3});gr.flip=false;
    const pot=vierteItem(ab,"jarrita","",t.x,t.y-24,false,14,"#2A160C");ab.tiene=ab.tiene.filter(x=>x!==gr);ab.tiene.push(pot);SFX.blip();await wait(mucho?TICK*4:TICK*2);liq("rana","negro",1);await wait(mucho?TICK*12:TICK*5);
    ab.tiene=ab.tiene.filter(x=>x!==pot);ab.tiene.push(gr);await wait(TICK*2);await pon("abuela",gr,pote,TRANA[0]+16,TRANA[1]+2,3);
    const panI=ab.tiene.find(x=>x.k==="cazo"),mi=vierteItem(ab,"cazo","1",t.x,t.y-24,false,14,"#FBFBF4");ab.tiene=ab.tiene.filter(x=>x!==panI);ab.tiene.push(mi);SFX.blip();await wait(TICK*4);liq("rana","marron",1);await wait(mucho?TICK*7:TICK*3);liq("rana",mucho?"marron":"palido",1);await wait(mucho?TICK*3:TICK*12);
    ab.tiene=ab.tiene.filter(x=>x!==mi);ab.tiene.push(panI);await ruta("abuela",[[FOGON[0],190],[FOGON[0],FOGON[1]]]);ab.dir=-1;await pon("abuela",panI,cz,CAZO35[0],CAZO35[1],4);SFX.blip();},
  // the frog drinks his own cup: he takes it in his hand, lifts it, tips it and sets it down empty
  async rana35bebe(o){const q=W.cq,t=copa("rana");await ranaA(TRANA[0]-14,TRANA[1]-2);const v=t.v,it=await ranaToma(t,-4,14,{n:3,m:3});it.vapor=0;
    q.hace="bebe";it.ang=.35;await wait(TICK*10);q.hace=null;it.ang=0;it.v="vacia";await ranaPon(it,t,TRANA[0],TRANA[1],3);t.v="vacia";t.vapor=0;await ranaA(CASA35[0],CASA35[1]);},
  // the turn: the cups are empty; abuela pours the last of the big pot (a half cup each for abuelo, papá and herself), the men sweeten and nod; the last milk into the children's cups; the little pot, full, goes back to the right end of the table; she sits down on her stool with her own cup
  async turno35(o){const ab=G("abuela"),l=G("luis"),ca=G("carmen"),q=W.cq,ce=ob("cafetera"),cz=ob("cazo"),tab=copa("abuela");
    ["abuelo","papa","rana"].forEach(id=>{liq(id,"vacia",0);});
    await Promise.all([sale("luis"),(async()=>{await wait(TICK*3);await sale("carmen");})()]);   // with their empty cups
    await acts.trae35({});
    await acts.tienden35({a:"abuelo,papa"});for(const id of ["abuelo","papa"]){await acts.cafe35({a:id,dedo:0,llena:1});}await acts.bajan35({a:"abuelo,papa"});
    // her own cup, at the right end of the table, from the pot too
    await ruta("abuela",[[150,ATRAS],[188,ATRAS],[200,150],[198,168]]);ab.dir=-1;{const up=ab.tiene.find(x=>x.k==="cafetera"),tilt=vierteItem(ab,"cafetera","",tab.x+7,tab.y-24,false,12,"#2A160C");ab.tiene=ab.tiene.filter(x=>x!==up);ab.tiene.push(tilt);SFX.blip();await wait(TICK*10);liq("abuela","negro",1);ab.tiene=ab.tiene.filter(x=>x!==tilt);ab.tiene.push(up);await wait(TICK*2);}
    await ruta("abuela",[[200,150],[FOGON[0],FOGON[1]]]);{const it=ab.tiene.find(x=>x.k==="cafetera");await pon("abuela",it,ce,CAFE35[0],CAFE35[1],4);}W.pote.dedo=1;
    for(const id of ["abuelo","papa"]){await acts.tienden35({a:id});await acts.azucar35({a:id,mal:0});await acts.bajan35({a:id});}
    await acts.prueba35({a:"abuelo,papa"});
    await Promise.all([entra("luis",72,178,1),(async()=>{await wait(TICK*3);await entra("carmen",88,186,1);})()]);await acts.ninos35({que:"dejan"});
    // the milk into the children's cups (they stand there with their hands empty)
    ab.dir=-1;const pan=await toma("abuela",cz,8,18,{n:3,m:3});
    await ruta("abuela",[[FOGON[0],190],[110,190]]);ab.dir=-1;
    for(const [id,cup] of [["carmen",K2],["luis",K1]]){const t=copa(id);const pn=ab.tiene.find(x=>x.k==="cazo");await mueve("abuela",cup[0]+18,190);ab.dir=-1;const mi=vierteItem(ab,"cazo","1",cup[0],cup[1]-24,false,14,"#FBFBF4");ab.tiene=ab.tiene.filter(x=>x!==pn);ab.tiene.push(mi);SFX.blip();await wait(TICK*8);liq(id,"leche",1);ab.tiene=ab.tiene.filter(x=>x!==mi);ab.tiene.push(pn);await wait(TICK*2);}
    W.pote.leche=1;
    // the pan goes back on the stove, the little pot, full, goes back to the right end of the table; then she takes her cup and sits down
    await ruta("abuela",[[FOGON[0],190],[FOGON[0],FOGON[1]]]);ab.dir=-1;{const pn=ab.tiene.find(x=>x.k==="cazo");await pon("abuela",pn,cz,CAZO35[0],CAZO35[1],4);cz.v="1";}
    await ruta("abuela",[[FOGON[0],190],[150,190],[TRANA[0]+16,190]]);ab.dir=-1;{const jp=ob("jarrita");if(jp.vis!==0&&jp.x>140&&jp.x<190){const it=await toma("abuela",jp,6,24,{n:3,m:3});it.flip=true;await ruta("abuela",[[GRECA35[0]+4,190]]);await pon("abuela",it,jp,GRECA35[0],GRECA35[1]+4,4);}}
    await mueve("luis",72,178);await mueve("carmen",88,186);},
  // she takes her own cup in her hand, walks to her stool and sits down with it
  async sientaAb35(o){const ab=G("abuela"),t=copa("abuela");await ruta("abuela",[[GRECA35[0]+8,190],[TABU[0]+10,190]]);ab.dir=-1;const it=await toma("abuela",t,8,22,{n:3,m:3});it.v=t.v;if(t.v!=="vacia")it.vapor=1;
    await ruta("abuela",[[STOOL[0]+6,186],[STOOL[0],STOOL[1]+2]]);ab.dir=-1;await mueveTiene("abuela",it,16,20,2);ab.sent=1;ab.taburete=1;ab.y=STOOL[1]-4;SFX.blip();await wait(TICK*3);},
  // round A: abuela gets up from her stool and takes the big pot with its last pour; the men hold their half cups out, looking at her
  async turnoA35(o){const ab=G("abuela"),ce=ob("cafetera");const cup=ab.tiene.find(x=>x.k==="taza");ab.sent=0;ab.taburete=0;ab.y=STOOL[1];SFX.blip();await wait(TICK*3);
    if(cup){await ruta("abuela",[[GRECA35[0]+8,190],[TABU[0]+10,190]]);ab.dir=-1;const t=copa("abuela");await pon("abuela",cup,t,TABU[0],TABU[1],4,{after:q=>{q.v=cup.v;q.vapor=cup.vapor;}});}
    await ruta("abuela",[[FOGON[0],FOGON[1]+8],[FOGON[0],FOGON[1]]]);ab.dir=-1;await toma("abuela",ce,9,15,{n:3,m:3,vapor:1});
    await ruta("abuela",[[196,146],[188,ATRAS],[150,ATRAS],[138,ASIENTO-2]]);ab.dir=-1;await acts.tienden35({a:"abuelo,papa"});await acts.llena35();},
  // after A: abuela puts the empty big pot on the stove, takes the little pot from the right end of the table and sets it by the frog's cup; he stands it by his small cup; she goes back to her cup and sits
  async despuesA35(o){const ab=G("abuela"),jt=ob("jarrita"),ce=ob("cafetera"),q=W.cq;await acts.bajan35({a:"abuelo,papa"});ce.v="";
    await acts.vuelve35({});
    await ruta("abuela",[[FOGON[0],190],[GRECA35[0]+4,190]]);ab.dir=-1;const it=await toma("abuela",jt,6,24,{n:3,m:3});it.flip=true;
    await ruta("abuela",[[TRANA[0]+26,190]]);ab.dir=-1;await pon("abuela",it,jt,TRANA[0]+16,TRANA[1]+2,4);
    await acts.sientaAb35({});},
  // abuela asks the frog: she gets up, takes the little pot from beside his cup and holds it out to him, looking at him (the thought over him is his own wish)
  async pregunta35(o){const ab=G("abuela"),jt=ob("jarrita");const cup=ab.tiene.find(x=>x.k==="taza");ab.sent=0;ab.taburete=0;ab.y=STOOL[1];SFX.blip();await wait(TICK*3);
    if(cup){await ruta("abuela",[[GRECA35[0]+8,190],[TABU[0]+10,190]]);ab.dir=-1;const t=copa("abuela");await pon("abuela",cup,t,TABU[0],TABU[1],4,{after:q=>{q.v=cup.v;q.vapor=cup.vapor;}});}
    await ruta("abuela",[[TRANA[0]+26,190]]);ab.dir=-1;const gr=await toma("abuela",jt,-9,24,{n:3,m:3});gr.flip=false;await wait(TICK*2);},
  // round B: abuela pours from the little pot what he said into his cup, tips what is left of it into her own cup, fills his cup to the brim with milk from the pan (a white stream); whatever is left in the pan she tips into Canelo's bowl, and Canelo laps it
  async sirveB35(o){const ab=G("abuela"),mucho=String(o.cant).replace(/^di_/,"")==="mucho",cz=ob("cazo"),tz=ob("tazon"),pe=W.perro,t=copa("rana"),ta=copa("abuela"),q=W.cq;q.piensa=null;
    let gr=ab.tiene.find(x=>x.k==="jarrita");ab.dir=-1;
    const pot=vierteItem(ab,"jarrita","",t.x,t.y-24,false,14,"#2A160C");ab.tiene=ab.tiene.filter(x=>x!==gr);ab.tiene.push(pot);SFX.blip();await wait(mucho?TICK*4:TICK*2);liq("rana","negro",1);await wait(mucho?TICK*12:TICK*5);ab.tiene=ab.tiene.filter(x=>x!==pot);ab.tiene.push(gr);await wait(TICK*2);
    // what is left of the little pot goes into her own cup (she walks to it)
    await ruta("abuela",[[TABU[0]+18,190]]);ab.dir=-1;{const pot2=vierteItem(ab,"jarrita","",ta.x,ta.y-24,false,14,"#2A160C");ab.tiene=ab.tiene.filter(x=>x!==gr);ab.tiene.push(pot2);SFX.blip();await wait(TICK*7);ta.v="negro";ta.vapor=1;ab.tiene=ab.tiene.filter(x=>x!==pot2);ab.tiene.push(gr);await wait(TICK*2);}
    await ruta("abuela",[[GRECA35[0]+4,190]]);ab.dir=-1;{const jt=ob("jarrita");await pon("abuela",gr,jt,GRECA35[0],GRECA35[1]+4,4);}
    await ruta("abuela",[[FOGON[0],190],[FOGON[0],FOGON[1]]]);ab.dir=-1;const pan=await toma("abuela",cz,8,18,{n:3,m:3});
    await ruta("abuela",[[FOGON[0],190],[TRANA[0]+26,190]]);ab.dir=-1;
    {const mi=vierteItem(ab,"cazo","1",t.x,t.y-24,false,14,"#FBFBF4");ab.tiene=ab.tiene.filter(x=>x!==pan);ab.tiene.push(mi);SFX.blip();await wait(TICK*4);liq("rana",mucho?"marron":"palido",1);await wait(mucho?TICK*7:TICK*14);ab.tiene=ab.tiene.filter(x=>x!==mi);ab.tiene.push(pan);await wait(TICK*2);}
    // the rest of the milk into Canelo's bowl, and Canelo laps it
    await ruta("abuela",[[TAZON[0]+18,190]]);ab.dir=-1;{const mi2=vierteItem(ab,"cazo","1",TAZON[0],TAZON[1]-26,false,18,"#FBFBF4");ab.tiene=ab.tiene.filter(x=>x!==pan);ab.tiene.push(mi2);SFX.blip();await wait(TICK*7);tz.v="1";ab.tiene=ab.tiene.filter(x=>x!==mi2);pan.v="0";ab.tiene.push(pan);}
    pe.pose="eat";pe.x=TAZON[0]-28;pe.y=TAZON[1];pe.dir=1;await wait(TICK*13);tz.v="0";pe.pose="lie";pe.x=CANELO[0];pe.y=CANELO[1];pe.dir=-1;
    await ruta("abuela",[[FOGON[0],190],[FOGON[0],FOGON[1]]]);ab.dir=-1;await pon("abuela",pan,cz,CAZO35[0],CAZO35[1],4);cz.v="0";W.pote.vacia=1;W.pote.pan=1;},
  async pruebaB35(o){const q=W.cq,t=copa("rana");await ranaA(TRANA[0]-14,TRANA[1]-2);const it=await ranaToma(t,-4,14,{n:3,m:3});q.hace="come";it.ang=.35;await wait(TICK*7);q.hace=null;it.ang=0;q.mal=1;SFX.bonk();await ranaPon(it,t,TRANA[0],TRANA[1],3);await wait(TICK*8);q.mal=0;await ranaA(CASA35[0],CASA35[1]);},
  // after a miss in B: abuela drinks her own cup off, happy (a big pleased "ah", a hand on her chest), then shows her empty cup, the little pot and the pan
  async bebeAb35(o){const ab=G("abuela"),t=copa("abuela");await ruta("abuela",[[TABU[0]+10,190]]);ab.dir=-1;const it=await toma("abuela",t,8,22,{n:3,m:3});it.v="negro";it.vapor=1;await mueveTiene("abuela",it,12,bocaY("abuela",ab)-3,3);it.ang=.35;ab.abre=1;SFX.blip();await wait(TICK*10);it.ang=0;it.v="vacia";it.vapor=0;ab.abre=0;ab.pose="bless";await wait(TICK*8);ab.pose="idle";
    await mueveTiene("abuela",it,10,24,3);},
  async muestra35(o){const ab=G("abuela"),k=o.k;ab.dir=-1;const cup=ab.tiene.find(x=>x.k==="taza");
    if(k==="taza"){if(cup){await mueveTiene("abuela",cup,12,34,3);await wait(TICK*8);await mueveTiene("abuela",cup,10,24,3);}return;}
    const spec=k==="jarrita"?ob("jarrita"):ob("cazo");const it=Object.assign({k:spec.k,v:k==="cazo"?"0":spec.v,e:1,flip:false},{dx:0,dy:0});const c=centroPara("abuela",it,R(ab.x)-14,R(ab.y)-24);it.dx=c[0];it.dy=c[1];ab.tiene.push(it);SFX.blip();await mueveTiene("abuela",it,it.dx,it.dy+10,3);await wait(TICK*8);ab.tiene=ab.tiene.filter(x=>x!==it);},
  // the ending: everybody drinks (they lift their cups, tip them and set them down); a spoiled cup stands in front of its owner; abuela drinks at her stool
  async final35(o){const ab=G("abuela");
    await Promise.all([entra("luis",72,178,1),(async()=>{await wait(TICK*3);await entra("carmen",88,186,1);})()].slice(0,G("luis").vis===0?2:0));
    const ninos=acts.ninos35({que:"toman"});
    const men=Promise.all(["abuelo","papa"].map(async id=>{const t=copa(id),p=G(id);if(t.v==="azu"||t.vis===0)return;const it=await toma(id,t,13,16,{n:3,m:3});it.v=t.v;it.vapor=0;await mueveTiene(id,it,11,bocaY(id,p)-1,3);it.ang=.35;SFX.blip();for(let i=0;i<5;i++){p.boca=1;await wait(TICK);p.boca=0;await wait(TICK);}it.ang=0;it.v="vacia";await pon(id,it,t,t.x,t.y,3,{after:q=>{q.v="vacia";q.vapor=0;q.sp=1;}});}));
    V.cafe=copa("abuela").v!=="vacia"?"1":"";
    if(ab.sent){const it=ab.tiene.find(x=>x.k==="taza");if(it&&V.cafe){await wait(TICK*6);await mueveTiene("abuela",it,12,bocaY("abuela",ab)-3,3);it.ang=.35;await wait(TICK*8);it.ang=0;it.v="vacia";it.vapor=0;await mueveTiene("abuela",it,16,20,3);}}
    await men;await ninos;W.cq.hace=null;await wait(TICK*6);},

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
  fresh:()=>({respEn:[130,12],gente:{},sitio:{},cosas:[],vuelos:[],perro:null,tarjeta:null,marcas:null,cq:{x:108,y:141,s:1,dy:0,al:1,vis:1,sobre:1,bub:null,hace:null,piensa:null,tiene:[]}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
