"use strict";
/* ============================================================
   Coquí · scene "A comer": abuela's kitchen table (place 3, La cocina, scene 4).
   The table of La mesa, deeper: in the middle, seen a little from above, with
   four chairs behind it and a place at each (a plate in front, a cup behind it).
   The counter (with a sink) at the left, the stove at the right with a shelf
   over it, the door to the yard at the left edge. The table has two halves:
   the back row (the places, y=FILA) and the front half, where the frog stands
   with the dishes. Whoever stands in front of the table stands at one of its
   two ends, lower in the picture than its top, so nothing on the table is hidden.
   People live in W.gente, by name: {x,y (feet), dir, sent (sitting), pose, vis,
   alza {k,v,e,dx,dy} (held up at twice the size in a raised hand), come {k,v},
   piensa (a thought), cara ("mal": a frown), mano, dy, bebe}.
   Everything on the table is a thing in W.cosas: {id,k,v,x,y,z,e,rot,vis,vapor}.
   Stories 33 (¿Qué quieres?), 34 (Buen provecho) and 35 (Café con azúcar).
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round,tarjeta=KIT.tarjeta,mkPerro=KIT.mkPerro;
const PISO=142,MESA=[76,128,124,44],SILLA=[104,128,152,176],MOSTR=[24,106,52,12],ESTUFA=[182,104,36,42],ESTANTE=[190,72,28];   // the floor; the table top (x, y of its far edge, width, depth); the four chairs; the counter top; the stove; the shelf over the stove
const FILA=141,MED=155,FREN=168,TZ=173;   // the rows on the table (the feet of what stands there): the places, the middle, the front; TZ: what stands on the table is drawn just after it
const IZQ=[58,176],DER=[204,181],FOGON=[204,172],PUERTA=[12,184],ALPIE=[72,186];   // where somebody stands at the left end of the table, at its right end; abuela at the stove; the door at the left edge; the sink
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,abuelo:FAM.abuelo,mama:FAM.mama,papa:FAM.papa,abuela:{}};
const PLATO=["#2A5C9C","#4A86C8","#8CB8E8"];   // the plates are blue: nothing white is lost on them

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),Wd=RP.wood,M=MOSTR,E=ESTUFA;
  for(let y=0;y<PISO;y++)for(let x=0;x<SW;x++)b.px(x,y,y>PISO-5?"#C8B88A":hs(x>>2,y>>2)<6?"#F0E4B8":"#F6ECC4");
  for(let y=84;y<M[1];y++)for(let x=22;x<76;x++)b.px(x,y,(x%8===0||y%8===4)?"#B8D0D8":"#E4F0F4");
  for(let y=86;y<E[1];y++)for(let x=186;x<SW;x++)b.px(x,y,(x%8===2||y%8===0)?"#B8D0D8":"#E4F0F4");
  for(let y=PISO;y<SH;y++)for(let x=0;x<SW;x++){const ty=Math.floor((y-PISO)/12),tx=Math.floor((x+ty*6)/16);b.px(x,y,((y-PISO)%12===0||(x+ty*6)%16===0)?"#9A6A54":(tx+ty)%2?"#C8745A":"#E8D8B8");}
  for(let x=0;x<SW;x++)b.px(x,PISO-1,"#7A6A4A");
  // the door to the yard, at the left edge
  b.rect(0,58,20,PISO-58,"#9CCBF5");b.rect(0,112,20,PISO-112,RP.grn[2]);b.rect(20,56,3,PISO-56,Wd[1]);b.rect(0,56,22,3,Wd[1]);
  // the window over the stove, a shelf under it
  b.rect(184,24,34,34,"#9CCBF5");b.ell(210,50,10,8,RP.grn);b.frame(182,22,38,38,Wd[1]);b.frame(183,23,36,36,Wd[3]);b.rect(200,24,2,34,Wd[2]);b.rect(184,40,34,2,Wd[2]);
  b.rect(ESTANTE[0],ESTANTE[1],ESTANTE[2],3,Wd[3]);b.rect(ESTANTE[0],ESTANTE[1]+3,ESTANTE[2],1,Wd[0]);b.frame(ESTANTE[0]-1,ESTANTE[1]-1,ESTANTE[2]+2,6,OUT);
  // the cupboard over the counter
  b.rect(27,34,42,40,Wd[2]);b.rect(27,34,42,2,Wd[4]);b.rect(27,72,42,2,Wd[0]);b.frame(26,33,44,42,OUT);b.rect(47,36,2,36,Wd[0]);[43,51].forEach(x=>b.rect(x,52,2,6,"#F0C020"));b.frame(30,38,16,32,Wd[1]);b.frame(50,38,16,32,Wd[1]);
  // the counter: a cabinet with two doors, a pale top seen a little from above, a sink set into it
  b.rect(M[0],M[1]+M[3],M[2],PISO+4-M[1]-M[3],Wd[2]);b.rect(M[0],M[1]+M[3],M[2],2,Wd[0]);b.frame(M[0]-1,M[1]+M[3]-1,M[2]+2,PISO+6-M[1]-M[3],OUT);
  b.rect(M[0]+24,M[1]+M[3]+3,2,20,Wd[0]);[M[0]+20,M[0]+30].forEach(x=>b.rect(x,M[1]+M[3]+9,2,5,"#F0C020"));
  b.rect(M[0]-2,M[1],M[2]+4,M[3],"#E8E8F0");b.rect(M[0]-2,M[1],M[2]+4,2,"#FFFFFF");b.rect(M[0]-2,M[1]+M[3]-2,M[2]+4,2,"#B8B8C8");b.frame(M[0]-3,M[1]-1,M[2]+6,M[3]+2,OUT);
  b.rect(54,M[1]+2,18,8,"#8A8EA0");b.rect(55,M[1]+3,16,6,"#C8CCDA");b.rect(55,M[1]+3,16,1,"#6A6E80");b.rect(62,M[1]-8,2,9,"#8A8EA0");b.rect(62,M[1]-9,6,2,"#8A8EA0");
  // the stove
  b.rect(E[0],E[1],E[2],E[3],"#F2F2F8");b.rect(E[0],E[1],E[2],6,"#3A3A46");b.rect(E[0],E[1]+6,E[2],2,"#C8C8D4");b.frame(E[0]-1,E[1]-1,E[2]+2,E[3]+2,OUT);
  b.frame(E[0]+3,E[1]+18,E[2]-6,22,"#B8B8C8");b.rect(E[0]+7,E[1]+21,E[2]-14,2,"#8A8A9A");[E[0]+5,E[0]+12,E[0]+19].forEach(x=>b.rect(x,E[1]+10,3,3,"#D0302A"));
  // the four chairs: their backs show over the far edge of the table
  SILLA.forEach(x=>{b.rect(x-9,MESA[1]-26,2,44,Wd[0]);b.rect(x+7,MESA[1]-26,2,44,Wd[0]);[MESA[1]-26,MESA[1]-18].forEach(y=>{b.rect(x-9,y,18,4,Wd[2]);b.rect(x-9,y,18,1,Wd[4]);});b.frame(x-10,MESA[1]-27,20,10,OUT);});
  return b.done();}
// the table: a red and white cloth, deeper than the one of La mesa; drawn over the people who sit behind it
function mkMesa(){const w=MESA[2],d=MESA[3],b=new Buf(w+12,d+34);
  for(let y=0;y<d;y++){const x0=R(6-y*6/d),ww=w+R(y*12/d);for(let x=0;x<ww;x++)b.px(x0+x,y,(((x>>2)+(y>>2))%2)?"#FFFFFF":"#F4B8B0");}
  for(let x=0;x<w+12;x++){b.px(x,d,"#D0302A");b.px(x,d+1,"#D8D8E4");b.px(x,d+2,"#D8D8E4");b.px(x,d+3,"#FFFFFF");b.px(x,d+4,(x>>2)%2?"#F4B8B0":"#FFFFFF");}
  [[3,d+5],[w+6,d+5]].forEach(p=>{b.rect(p[0],p[1],4,28,RP.wood[1]);b.rect(p[0],p[1],1,28,RP.wood[2]);});
  return b.outline().done();}

/* ---------- things on the table, on the counter, in a hand. Each is drawn with its foot at the bottom middle ---------- */
const TAN=["#A8682C","#C8853C","#E2A85A"],CHOC=["#2A1408","#5A2E14","#8A5A34"],MANT="#FFE070";
const COSA={
  // a blue plate; v: what lies on it. rice: "r" (rice), "rm" (rice with a mound), "o" (a mound), "h" (a mound mixed into the rice: a heap), "mi" (crumbs)
  plato(v){const b=new Buf(22,10);b.ell(11,5.6,10.4,4,PLATO);b.ell(11,5,6.8,2.4,["#6AA0DC","#A8CCF0"]);v=v||"";
    if(v==="r"||v==="rm"||v==="h"){b.ell(11,5,6.6,2.4,["#C88A10","#F2C028","#FFE060"]);[[7,4],[10,5],[13,4],[15,5],[9,6],[12,3]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    if(v==="rm"||v==="o"){b.ell(11,3.4,3.6,2.6,["#C88A10","#F2C028","#FFE870"]);b.px(10,2,"#FFF4B0");b.px(12,3,"#B87A10");}
    if(v==="h"){b.ell(9,3.2,3.8,2.8,["#C88A10","#F2C028","#FFE870"]);b.ell(14,3.6,3.4,2.6,["#C88A10","#F2C028","#FFE870"]);b.px(8,2,"#B87A10");b.px(15,3,"#B87A10");b.px(12,2,"#FFF4B0");}
    if(v==="mi"){[[7,4],[9,6],[13,5],[15,4],[11,3]].forEach(q=>b.px(q[0],q[1],"#C8853C"));}
    if(/^p[123]$/.test(v)){[[6,4],[11,3],[16,4]].slice(0,+v[1]).forEach(q=>{b.ell(q[0],q[1],3.4,2.4,["#C88A10","#F2C028","#FFE870"]);b.px(q[0]-1,q[1]-1,"#FFF4B0");});}
    return b.outline().done();},
  // a plate with an apple on it; a plate with a huge heap of rice; a white jug of milk; drops of water
  platoma(){const b=new Buf(22,18);b.ell(11,13.6,10.4,4,PLATO);b.ell(11,13,6.8,2.4,["#6AA0DC","#A8CCF0"]);b.ell(8,8.4,3.4,4,["#A01818","#D02828","#F05848"]);b.ell(13,8.4,3.4,4,["#A01818","#D02828","#F05848"]);b.rect(10,3,1,3,"#5A3A1A");b.px(11,3,"#48A848");b.px(6,6,"#FFB0A0");return b.outline().done();},
  platoH(){const b=new Buf(22,18);b.ell(11,13.6,10.4,4,PLATO);b.ell(11,13,6.8,2.4,["#6AA0DC","#A8CCF0"]);b.ell(11,11,7.4,3.4,["#C88A10","#F2C028","#FFE060"]);b.ell(11,7.6,6.2,5,["#C88A10","#F2C028","#FFE870"]);b.ell(11,4.4,3.6,3,["#C88A10","#F2C028","#FFE870"]);[[8,8],[12,6],[14,9],[10,11],[9,5],[12,3],[15,11]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));return b.outline().done();},
  jarrale(){const b=new Buf(23,29);b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");b.rect(4,8,11,19,"#FFFFFF");b.rect(4,8,11,1,"#C8C8D4");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
  gotas(){const b=new Buf(14,10);[[1,6],[4,2],[7,5],[10,1],[12,6],[3,8],[9,8]].forEach(q=>{b.rect(q[0],q[1],2,2,"#78B8F0");b.px(q[0],q[1],"#E4F4FF");});return b.outline().done();},
  // the frog's own small plate
  platito(v){const b=new Buf(16,8);b.ell(8,4.6,7.4,3,PLATO);b.ell(8,4,4.6,1.8,["#6AA0DC","#A8CCF0"]);if(v==="o"){b.ell(8,3,3.2,2.2,["#C88A10","#F2C028","#FFE870"]);b.px(7,2,"#FFF4B0");}if(v==="mi"){[[6,4],[9,5],[11,3]].forEach(q=>b.px(q[0],q[1],"#C8853C"));}return b.outline().done();},
  // a roll. v: "ab" open and empty, "ab:c"/"ab:m" with chocolate/butter in it, "ce" closed, "mo:c"/"mo:m" bitten (what is inside shows)
  rollo(v){const b=new Buf(13,9),s=String(v||"ce").split(":"),st=s[0],con=s[1],F=con==="c"?CHOC[1]:MANT;
    if(st==="ab"){b.ell(6.5,6,5.6,2.4,TAN);b.ell(6.5,5.6,4,1.4,["#FFF0C8"]);if(con)b.ell(6.5,5.4,3.8,1.3,con==="c"?[CHOC[0],CHOC[1],CHOC[2]]:[MANT,"#FFF4A8"]);b.ell(4,2.8,4.2,2.2,TAN);b.rect(2,3,2,1,"#F4CC88");}
    else if(st==="mo"){b.ell(6.5,5,5.6,3,TAN);b.rect(4,3,1,2,"#8A5A18");b.rect(9,2,4,5,F);b.px(9,2,"#FFF0C8");b.px(9,6,"#FFF0C8");b.px(12,3,"#FFF0C8");b.ell(11.5,4.4,1.6,1.8,[F]);}
    else{b.ell(6.5,5,5.6,3,TAN);b.rect(4,3,1,3,"#8A5A18");b.rect(7,3,1,3,"#8A5A18");b.px(5,2,"#F4CC88");}
    return b.outline().done();},
  // the basket of rolls, low enough to leave the places behind it free. v: "n:c" n rolls (0 to 5), c = 1 the cloth lies over them
  cesta(v){const b=new Buf(42,16),s=String(v==null?"5:0":v).split(":"),n=+s[0],tapa=s[1]==="1";
    if(!tapa)[7,14,21,28,35].slice(0,n).forEach(x=>{b.ell(x+.5,7.5,3.9,4.4,TAN);b.rect(x-1,4,1,5,"#8A5A18");b.rect(x+2,4,1,5,"#8A5A18");b.px(x-2,3,"#F4CC88");});
    b.rect(1,9,40,6,"#B07A3C");for(let x=2;x<40;x+=4)b.rect(x,9,2,6,"#8A5A2A");b.rect(0,8,42,2,"#D09A54");
    if(tapa){b.ell(21,7,19,5,["#D0302A","#F4B8B0","#FFFFFF"]);for(let x=5;x<38;x+=4)b.rect(x,4+(x%8?0:1),2,5,"#FFFFFF");}
    else{b.rect(34,10,7,5,"#FFFFFF");b.rect(34,12,7,1,"#E8786E");b.rect(36,10,1,5,"#E8786E");b.frame(34,10,7,5,"#C8C8D4");}
    return b.outline().done();},
  mantequilla(){const b=new Buf(22,11);b.ell(11,8.4,10,2.4,["#2A5C9C","#4A86C8","#8CB8E8"]);b.rect(5,3,12,5,MANT);b.rect(5,3,12,1,"#FFFBE0");b.rect(5,7,12,1,"#E0C860");b.rect(16,3,1,5,"#E0C860");b.rect(8,5,6,1,"#E0C860");return b.outline().done();},
  // the pot of melted chocolate, with its spoon
  choc(){const b=new Buf(20,15);b.rect(3,6,12,8,"#A8A8B8");b.rect(3,6,3,8,"#D8D8E4");b.rect(3,12,12,2,"#6A6A7A");b.rect(15,8,4,2,"#3A3A46");b.ell(9,6,6.4,2.6,["#8A8A9A","#C8C8D4"]);b.ell(9,6,5.2,1.9,CHOC);b.px(7,5,"#C89A74");b.px(10,6,"#C89A74");b.rect(11,0,2,7,"#B07A3C");b.rect(10,0,4,2,"#8A5A2A");return b.outline().done();},
  tenedor(){const b=new Buf(9,18);[1,4,7].forEach(x=>b.rect(x,1,1,6,"#D8D8E4"));b.rect(1,7,7,2,"#C8C8D4");b.rect(4,9,1,8,"#C8C8D4");return b.outline().done();},
  cuchara(){const b=new Buf(9,18);b.ell(4.5,5,3,4,["#8A8A9C","#C8C8D4","#F8F8FF"]);b.rect(4,9,1,8,"#C8C8D4");return b.outline().done();},
  // the big spoon, with a heap: "" empty, "a" sugar, "m" a mound of rice
  cucharon(v){const b=new Buf(16,22);b.rect(6,9,2,10,"#B07A3C");b.rect(6,9,1,10,"#D09A54");b.ell(7,7,5,2.6,["#8A5A2A","#B07A3C","#D09A54"]);
    if(v==="a"){b.ell(7,4.6,4.2,3,["#C8C8D8","#F2F2F8","#FFFFFF"]);b.px(5,3,"#FFFFFF");b.px(9,4,"#FFFFFF");b.px(7,2,"#FFFFFF");}
    if(v==="m"){b.ell(7,4.2,4.2,3.2,["#C88A10","#F2C028","#FFE870"]);b.px(6,3,"#FFF4B0");b.px(9,4,"#B87A10");}
    if(v==="t"){b.ell(7,5.4,1.8,1.4,["#C88A10","#F2C028","#FFE870"]);}
    if(v==="M"){b.ell(7,3.6,6.4,4.6,["#C88A10","#F2C028","#FFE870"]);b.ell(7,1.8,3.6,2.4,["#C88A10","#F2C028","#FFE870"]);[[5,3],[9,4],[7,1],[10,6],[4,6]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    return b.outline().done();},
  // a mound of yellow rice
  monton(){const b=new Buf(10,8);b.ell(5,5,4.6,3,["#C88A10","#F2C028","#FFE870"]);b.px(3,4,"#FFF4B0");b.px(6,3,"#FFF4B0");b.px(5,6,"#B87A10");b.px(7,5,"#B87A10");b.px(2,6,"#B87A10");return b.outline().done();},
  // the pot of rice on the table: "lleno" or "vacio"
  olla(v){const b=new Buf(26,22);b.rect(4,8,18,12,"#8A8A9A");b.rect(4,8,5,12,"#B8B8C8");b.rect(4,17,18,3,"#5A5A6A");b.rect(1,10,3,4,"#3A3A46");b.rect(22,10,3,4,"#3A3A46");b.ell(13,8,10,4,["#5A5A6A","#9494A6","#C8C8D4"]);
    if(v==="vacio"){b.ell(13,8.4,8.2,3,["#1E1E28","#2A2A36"]);b.px(8,8,"#FFF4B0");b.px(18,9,"#B87A10");}else{b.ell(13,8,8.2,3,["#C88A10","#F2C028","#FFE060"]);[[8,7],[11,9],[14,7],[17,9],[19,7],[10,6],[15,8]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    return b.outline().done();},
  // the platter for the second helpings
  fuente(){const b=new Buf(70,16);b.ell(35,9,34,6.2,["#2A5C9C","#4A86C8","#8CB8E8"]);b.ell(35,8.4,29,4.4,["#6AA0DC","#A8CCF0"]);return b.outline().done();},
  // a thought: a mound with a heart; a round belly beside a clean plate
  montoncor(){const b=new Buf(18,15);b.ell(9,11,7,3.6,["#C88A10","#F2C028","#FFE870"]);b.px(6,9,"#FFF4B0");b.px(11,10,"#B87A10");const H=[".##.##.","#######","#######",".#####.","..###..","...#..."];H.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(5+i,0+j,j<2&&i<3?"#FF9A90":"#E8443C");});return b.outline().done();},
  barriga(){const b=new Buf(22,13);b.ell(6,8,5.6,2.4,PLATO);b.ell(6,7.6,3.6,1.4,["#A8CCF0"]);b.ell(16,7,5.6,5.4,["#C8853C","#E2A85A","#FBF0D2"]);b.ell(16,8,3.4,3.4,["#EEDCB0","#FBF0D2"]);b.px(16,8,"#B89A6A");return b.outline().done();},
  // a cup seen from above (the table is seen a little from above too). v: the colour of the coffee
  taza(v){const b=new Buf(16,11),L={negro:["#140A04","#2A160C","#3E2414"],marron:["#5E2C10","#8A4A20","#B8743C"],palido:["#B89060","#D8B07C","#EED0A0"],leche:["#E8E4D8","#F6F4EC","#FFFFFF"],vacia:["#B8B8C8","#DCDCE8","#F2F2F8"],azu:["#5E2C10","#8A4A20","#B8743C"]};
    b.ell(8,5.6,7,4.4,["#8A8A9C","#D8D8E4","#FFFFFF"]);b.rect(13,4,3,2,"#F2F2F8");b.px(15,5,"#F2F2F8");b.ell(7.6,5.2,5,3.2,L[v]||L.vacia);
    if(v==="azu"){[[5,4],[8,3],[10,5],[7,6],[6,5],[9,6]].forEach(q=>b.px(q[0],q[1],"#FFFFFF"));}
    return b.outline().done();},
  // the sugar bowl, heaped
  azucarera(v){const b=new Buf(18,14);b.ell(9,10,7.6,3.4,["#B0302A","#D0504A","#F08880"]);b.rect(2,6,14,5,"#D0504A");b.rect(2,6,3,5,"#F08880");b.ell(9,6,7.6,2.4,["#8A2018","#B0302A"]);
    if(v!=="0"){b.ell(9,4.4,6.4,3.4,["#C8C8D8","#F2F2F8","#FFFFFF"]);[[6,3],[9,2],[12,4],[8,5],[11,3]].forEach(q=>b.px(q[0],q[1],"#FFFFFF"));}
    return b.outline().done();},
  // the big pot of coffee (enamel, blue, a spout and a handle), the little pouring pot (red), the milk pan
  cafetera(v){const b=new Buf(22,24);b.rect(5,6,12,16,"#2A5C9C");b.rect(5,6,3,16,"#6AA0DC");b.rect(5,19,12,3,"#1A3C6C");b.ell(11,5,6.4,2.2,["#1A3C6C","#2A5C9C"]);b.rect(9,1,4,3,"#141418");b.rect(2,8,3,2,"#2A5C9C");b.rect(0,6,3,3,"#2A5C9C");b.rect(17,10,2,9,"#141418");b.rect(15,10,4,2,"#141418");b.rect(15,17,4,2,"#141418");b.px(8,12,"#FFFFFF");b.px(12,15,"#FFFFFF");return b.outline().done();},
  jarrita(){const b=new Buf(15,14);b.rect(4,4,8,9,"#B0302A");b.rect(4,4,2,9,"#F08880");b.rect(4,11,8,2,"#7A1C1C");b.ell(8,3.4,4.6,1.6,["#7A1C1C","#B0302A"]);b.rect(1,5,3,2,"#B0302A");b.px(1,4,"#B0302A");b.rect(12,5,3,5,"#141418");return b.outline().done();},
  cazo(v){const b=new Buf(22,9);b.ell(9,5.6,8.4,3,["#6A6E80","#B8BCCC","#E8EAF2"]);b.ell(9,4,7,2.2,v==="0"?["#2A2A36","#4A4A58"]:["#E4DCC8","#F6F1E4","#FFFFFF"]);b.rect(16,4,6,2,"#3A3A46");return b.outline().done();},
  // a stool for abuela at the stove
  taburete(){const b=new Buf(24,18);b.rect(2,2,20,4,RP.wood[3]);b.rect(2,2,20,1,RP.wood[4]);b.rect(4,6,3,11,RP.wood[1]);b.rect(17,6,3,11,RP.wood[1]);return b.outline().done();},
  // the dog's bowl: with milk in it, or empty
  tazon(v){const b=new Buf(20,9);b.ell(10,5.6,9,3.2,["#2A5C9C","#4A86C8","#8CB8E8"]);b.ell(10,4.6,7,2.2,v==="1"?["#E4DCC8","#F6F1E4","#FFFFFF"]:["#1E3A68","#2A5C9C"]);return b.outline().done();},
  // a tray with n rolls, for abuela to carry
  bandeja(n){const b=new Buf(34,12);n=n==null?4:+n;b.rect(1,7,32,3,"#9494A6");b.rect(1,7,32,1,"#C8C8D4");for(let i=0;i<n;i++){const x=6+i*7;b.ell(x,5,3.4,2.4,TAN);b.rect(x-1,3,1,3,"#8A5A18");}return b.outline().done();},
  pano(){const b=new Buf(12,10);b.rect(1,1,10,8,"#F8F8FF");b.rect(1,4,10,1,"#E0403A");b.rect(1,7,10,1,"#E0403A");return b.outline().done();},
  charco(){const b=new Buf(19,8);b.ell(8,4,5.4,1.8,["#6A3214"]);b.ell(12,3,3,1.4,["#6A3214"]);return b.outline().done();},
  // pictures of the pairs: a drumstick, an apple on a plate, a slice of cake, a bowl of rice for the dog, an orange jug, a glass
  muslo(){const b=new Buf(16,10);b.ell(6,5,5,3.6,["#8A4A14","#C87A28","#E8A848"]);b.rect(10,4,4,2,"#F2EAD8");b.ell(14,4,1.4,1.4,["#F2EAD8"]);b.ell(14,6,1.4,1.4,["#F2EAD8"]);return b.outline().done();},
  manzana(){const b=new Buf(11,11);b.ell(3.6,6.4,3,4,["#A01818","#D02828","#F05848"]);b.ell(7.4,6.4,3,4,["#A01818","#D02828","#F05848"]);b.rect(5,1,1,3,"#5A3A1A");b.px(6,1,"#48A848");b.px(2,4,"#FFB0A0");return b.outline().done();},
  bizcocho(){const b=new Buf(10,9);b.rect(1,4,8,4,"#E8B050");b.rect(1,4,8,1,"#F8DC90");b.rect(1,2,8,2,"#FFF4E0");b.px(4,1,"#D0302A");b.px(5,1,"#D0302A");return b.outline().done();},
  jarra(v){const b=new Buf(23,29),n=v==null?4:+v;b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");if(n>0)b.rect(4,27-n*5,11,n*5,"#F08818");for(let i=1;i<=4;i++)b.rect(11,27-i*5,5,1,"#4A5A6A");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
  jugo(){const b=new Buf(23,29);b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");b.rect(4,27-20,11,20,"#F08818");b.rect(4,7,11,2,"#FFB040");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
  jugopoco(){const b=new Buf(23,29);b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");b.rect(4,25,11,2,"#F08818");b.rect(4,24,11,1,"#FFB040");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
  vasojugo(){const b=new Buf(9,13);b.rect(1,1,7,11,"#DCF2FA");b.rect(1,1,2,11,"#F2FBFF");b.rect(2,3,5,9,"#F08818");return b.outline().done();},
  entero(){const b=new Buf(24,13);b.ell(12,8,10.6,4,["#C88A30","#E8B050","#F8DC90"]);b.ell(12,5.5,10.6,3.6,["#F2E4D0","#FFF4E0","#FFFFFF"]);[6,12,18].forEach(x=>b.px(x,4,"#D0302A"));return b.outline().done();},
  // a slice that steams, a drumstick with a bite out of it, a bone
  hueso(){const b=new Buf(15,8);b.rect(4,3,7,2,"#F8F4E8");[[3,2],[3,5],[11,2],[11,5]].forEach(p=>b.ell(p[0],p[1],1.7,1.7,["#F8F4E8"]));return b.outline().done();},
  // a bowl for a dog: "limpio" (licked clean), "lleno" (still heaped)
  cuenco(v){const b=new Buf(22,11);b.ell(11,7,10,3.6,["#B0302A","#D0504A","#F08880"]);b.ell(11,5.6,8.4,2.6,v==="lleno"?["#C88A10","#F2C028","#FFE060"]:["#8A2018","#B0302A"]);
    if(v==="lleno"){b.ell(11,3.6,5.4,2.6,["#C88A10","#F2C028","#FFE870"]);[[8,3],[11,2],[14,3],[10,5],[13,5]].forEach(q=>b.px(q[0],q[1],hs(q[0],q[1])%2?"#FFF4B0":"#B87A10"));}
    return b.outline().done();},
  granos(){const b=new Buf(6,4);[[1,1],[3,2],[4,0]].forEach(q=>b.px(q[0],q[1],"#F2C028"));return b.done();},
  // a thing for a thought: a question mark; a heart
  interroga(){const b=new Buf(9,13);const Q=["..###..",".##.##.",".##.##.","....##.","...##..","..##...","..##...",".......","..##..."];Q.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(1+i,1+j,"#3A3A46");});return b.outline("#FFFFFF").done();},
  corazon(){const b=new Buf(9,8);const H=[".##.##.","#######","#######",".#####.","..###..","...#..."];H.forEach((rw,j)=>{for(let i=0;i<7;i++)if(rw[i]==="#")b.px(1+i,1+j,j<2&&i<3?"#FF9A90":"#E8443C");});return b.outline().done();}};
const cosa=(k,c)=>spr("cm"+k+(c==null?"":c),()=>(COSA[k]||COSA.plato)(c));
function tenida(c,k,x,y,ang,esc,v){const im=cosa(k,v);if(ang||esc){c.save();c.translate(R(x),R(y));if(ang)c.rotate(ang);if(esc)c.scale(esc,esc);c.drawImage(im,-(im.width>>1),-im.height);c.restore();}else c.drawImage(im,R(x)-(im.width>>1),R(y)-im.height);}
// steam: two soft wisps that sway
function vapor(c,x,y,n){const t=(F>>3)%4;for(let i=0;i<(n||2);i++){const dx=i*5-2;for(let k=0;k<9;k++){const sw=Math.round(Math.sin((k+t*2+i*3)/2.6)*1.4);fr(c,x+dx+sw-1,y-k,3,1,"#B8C4D4");fr(c,x+dx+sw,y-k,1,1,"#FFFFFF");}}}

/* ---------- what can be touched ---------- */
const alto=id=>{const w=QUIEN[id]||{},p=W.gente[id];return id==="abuela"?(p&&p.sent?48:51):w.nino?(p&&p.sent?37:44):(p&&p.sent?49:56);};
const caja=id=>{const p=W.gente[id];if(!p||p.vis===0)return null;const h=alto(id);return p.sent?[R(p.x)-11,R(p.y)-h,22,MESA[1]+6-(R(p.y)-h)]:[R(p.x)-11,R(p.y)-h,22,h];};   // somebody who sits behind the table is touched above its edge
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const ob=id=>(W.cosas||[]).find(o=>o.id===id);
const porId=(id,dx,dy,w,h,z)=>({id,si:w2=>!!(w2.cosas||[]).find(o=>o.id===id&&o.vis!==0),box:w2=>{const o=w2.cosas.find(o=>o.id===id);return [R(o.x)-dx,R(o.y)-dy,w,h];},m:1,z:z==null?1:z});
const COSAS=Object.keys(QUIEN).map(persona).concat([porId("mant",11,13,22,15),porId("choc",10,17,20,19),porId("cesta",19,22,38,24,0),porId("cafetera",12,28,24,30,0),porId("azucarera",9,14,18,16,0),porId("olla",13,22,26,24,0),porId("fuente",30,14,64,16,0),porId("pl_papa",11,10,22,10,0),porId("pl_rana",8,8,16,8,0),
  {id:"silla_papa",si:w=>true,box:[SILLA[2]-10,MESA[1]-26,20,36],m:0},{id:"mesa",box:[MESA[0]-6,MESA[1],MESA[2]+12,MESA[3]+6],m:0},{id:"cocina",box:[22,24,196,190],m:0}]);

/* ---------- drawing ---------- */
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  if(id==="abuela"){
    if(p.sent){const ps=p.pose||"idle",top=y-48,hb=(habla||p.abre||p.boca)?1:0;if(p.taburete)tenida(c,"taburete",x,y+2);c.drawImage(spr("abS"+ps+hb,()=>KIT.mkAbuelaS(ps,hb,0)),x-17,top);if(p.lleva)tenida(c,p.lleva.k,x+14,top+32,0,0,p.lleva.v);if(p.come)tenida(c,p.come.k,x+6,top+22+(a%2),0,0,p.come.v);if(p.bebe)tenida(c,"taza",x+8,top+24-(a%2),0,0,p.bebe);return;}
    const ps=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle"),top=y-50+((p.paso&&a%2)?-1:0),hb=(habla||p.abre||p.boca)?1:0;c.save();c.translate(x,top);if(((ps==="offer"||ps==="bless")?-d:d)<0)c.scale(-1,1);c.drawImage(spr("ab"+ps+hb,()=>mkAbuela(ps,hb)),-30,0);c.restore();
    if(p.lleva)tenida(c,p.lleva.k,x+d*(p.lleva.dx==null?-14:p.lleva.dx),y-(p.lleva.dy==null?17:p.lleva.dy),0,p.lleva.e||0,p.lleva.v);
    if(p.alza)tenida(c,p.alza.k,x+d*(p.alza.dx==null?-19:p.alza.dx),y-(p.alza.dy==null?18:p.alza.dy),0,p.alza.e==null?2:p.alza.e,p.alza.v);
    if(p.come)tenida(c,p.come.k,x+d*6,y-32+(a%2),0,0,p.come.v);
    if(p.bebe)tenida(c,"taza",x+d*8,y-31-(a%2),0,0,p.bebe);return;}
  const pose=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle"),op=(habla||p.boca)?1:0,w2=p.cierra?Object.assign({},w,{dormido:1}):w,im=spr("pm"+id+pose+op+(p.sent?1:0)+(p.cierra?"c":""),()=>KIT.mkPersona(w2,pose,op,p.sent)),top=y-im.height+1+((p.paso&&a%2)?-1:0)+(p.dy||0);
  c.save();c.translate(x,top);if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  if(p.bebe){const e=p.bebe===1?"idle":p.bebe,bi=spr("bb"+e+(a%2),()=>KIT.mkBebe(e,a%2));c.drawImage(bi,x-13+d*2,y-(p.sent?39:40)-(p.sent?0:0));}
  if(p.cara==="mal"){const sk=(w.piel||RP.skin)[2];fr(c,x-3,top+14,7,3,sk);fr(c,x-2,top+16,5,1,"#7A2A1A");fr(c,x-3,top+17,1,1,"#7A2A1A");fr(c,x+3,top+17,1,1,"#7A2A1A");fr(c,x-5,top+8,4,1,"#20140A");fr(c,x+2,top+8,4,1,"#20140A");}
  if(p.come)tenida(c,p.come.k,x+d*(p.come.dx==null?6:p.come.dx),top+(w.nino?18:21)+(p.come.dy||0)+(a%2),0,p.come.e||0,p.come.v);
  if(p.bebe2)tenida(c,"taza",x+d*8,top+(w.nino?20:23)-(a%2),0,0,p.bebe2);
  if(p.mano)tenida(c,p.mano.k,x+d*(p.mano.dx==null?9:p.mano.dx),top+(w.nino?32:36)+(p.mano.dy||0),p.mano.rot?p.mano.rot*d:0,p.mano.e||0,p.mano.v);
  if(p.alza){const A=p.alza,ax=x+d*(A.dx==null?19:A.dx),ay=top+(w.nino?30:34)+(A.dy==null?-18:A.dy),e=A.e==null?2:A.e;tenida(c,A.k,ax,ay,0,e,A.v);if(A.vapor)vapor(c,ax,ay-8*e,2);fr(c,ax-d*5-2,ay-3,5,4,OUT);fr(c,ax-d*5-1,ay-2,3,2,(w.piel||RP.skin)[2]);}}
function nube(g,x,y,o){fr(g,x-1,y-1,28,22,OUT);fr(g,x,y,26,20,"#FFFFFF");fr(g,x+10,y+20,4,4,OUT);fr(g,x+11,y+21,2,2,"#FFFFFF");tenida(g,o.k,x+13,y+18,0,o.e||0,o.v);}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui"||q.hace)&&a%2?1:0,dy=R(q.dy),cx=b.x+(b.w>>1);
  g.save();if(q.espalda){g.translate(cx,b.y+dy+(b.h>>1));g.rotate(Math.PI);g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),-(b.w>>1),-(b.h>>1));g.restore();
    [[-6,-4,12],[-8,-3,16],[-9,-2,18],[-8,-1,16],[-6,0,12]].forEach(r=>fr(g,cx+r[0],b.y+dy+(b.h>>1)+r[1]-4,r[2]+(r[2]>>3),1,"#FBF0D2"));return;}
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;g.restore();
  if(q.lleno){[[-7,0],[-9,1],[-10,2],[-10,3],[-9,4],[-7,5]].forEach(r=>{fr(g,cx+r[0]-1,b.y+dy+12+r[1],-2*r[0]+2,1,"#FBF0D2");});fr(g,cx-10,b.y+dy+14,1,3,OUT);fr(g,cx+9,b.y+dy+14,1,3,OUT);fr(g,cx,b.y+dy+15,1,1,"#B89A6A");}
  if(q.mano)tenida(g,q.mano.k,cx+(q.mano.dx==null?13:q.mano.dx),b.y+dy+(q.mano.dy==null?12:q.mano.dy),0,q.mano.e||0,q.mano.v);}
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,6+20*(W.marcas||[]).length,24);
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m){g.fillStyle=OUT;for(let k=0;k<11;k++){g.fillRect(x+k,y+1+k,4,3);g.fillRect(x+10-k,y+1+k,4,3);}g.fillStyle="#C8401E";for(let k=0;k<11;k++){g.fillRect(x+1+k,y+2+k,2,1);g.fillRect(x+11-k,y+2+k,2,1);}}
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}
const marca=m=>{const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;};
const enMesa=o=>o.y>=FILA-1&&o.y<=FREN+3&&o.x>MESA[0]-6&&o.x<MESA[0]+MESA[2]+8;
function cosaDibuja(c,o,a){const k=o.k;
  if(k==="plato"){tenida(c,"plato",o.x,o.y,o.rot,o.e,o.v);(o.rollos||[]).forEach(r=>tenida(c,"rollo",o.x+(r.dx||0),o.y-3,0,0,r.st+(r.con?":"+r.con:"")));return;}
  if(k==="fuente"){tenida(c,"fuente",o.x,o.y);(o.montones||[]).forEach(m=>tenida(c,"monton",o.x+m.dx,o.y-4+(m.dy||0)));if(o.tenedor)tenida(c,"tenedor",o.x+o.tenedor.dx,o.y-3,1.2);return;}
  tenida(c,k,o.x,o.y,o.rot,o.e||0,o.v);
  if(o.vapor)vapor(c,o.x+(o.vdx||0),o.y-(o.vdy==null?(k==="cesta"?18:k==="taza"?7:12):o.vdy),o.vn||2);}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{};
  c.drawImage(spr("comer",fondo),0,0);
  const L=[];
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.z!=null?p.z:p.y,d:()=>gente(c,id,a)});});
  L.push({y:TZ,d:()=>c.drawImage(spr("mesa",mkMesa),MESA[0]-6,MESA[1])});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:enMesa(o)?TZ+o.y/1000:o.y+1,d:()=>cosaDibuja(c,o,a)});});
  if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>{const o=W.perro,f=o.pose==="eat"||o.pose==="walk"||o.cola?(a>>1)%2:0,im=spr("pe"+o.pose+f,()=>mkPerro(o.pose,f));c.save();c.translate(R(o.x),R(o.y)-im.height+2);if(o.dir<0)c.scale(-1,1);c.drawImage(im,-13,0);c.restore();}});
  if(q.vis)L.push({y:q.sobre===0?q.y+27:TZ+(q.y+27)/1000,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  (W.vuelos||[]).forEach(o=>{if(o.k==="chorro"){fr(c,o.x,o.y,2,o.h,o.col||"#5A2E14");fr(c,o.x,o.y,1,o.h,"#8A5A34");}else tenida(c,o.k,o.x,o.y,o.rot,o.e||0,o.v);});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.piensa&&p.vis!==0)nube(c,R(p.x)-12+(p.pdx||0),R(p.y)-alto(id)-26,p.piensa);});
  if(q.vis&&q.piensa){const b=frogBox(q);nube(c,b.x+(b.w>>1)-13,b.y-26,q.piensa);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1];}
function respIcon(g,k,x,y,w,h,a){}

/* ---------- moving things ---------- */
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/6));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;}
async function vuela(o,x0,y0,x1,y1,n){const v=Object.assign({x:x0,y:y0},o);W.vuelos.push(v);n=n||5;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(x1-x0)*t;v.y=y0+(y1-y0)*t-Math.sin(t*Math.PI)*10;await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);}
const cx=()=>W.cq.x+16,pies=()=>W.cq.y+27;
async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(3,R(d/40))));}
const corre=(o,pr)=>{if(o&&o.suelto){W._mov=pr;return Promise.resolve();}return pr;};
const mano=id=>{const p=G(id),d=p.dir<0?-1:1;return [R(p.x)+d*19,R(p.y)-alto(id)+16];};
async function entra(id,x,y,dir){const p=G(id);p.sent=0;if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=y;}p.dir=1;await mueve(id,x,y);if(dir)p.dir=dir;}
async function sale(id){const p=G(id);if(p.vis===0)return;const y=p.sent||p.y<150?148:p.y;p.sent=0;p.alza=null;p.come=null;p.cara=null;p.pose="idle";await mueve(id,PUERTA[0],y);p.vis=0;}
async function sienta(id,i){const p=G(id);p.sent=0;if(p.vis===0){p.vis=1;p.x=PUERTA[0];p.y=148;}if(p.y>150)await mueve(id,p.x,148,3);await mueve(id,SILLA[i],148);p.sent=1;p.y=148;p.dir=1;SFX.blip();}

/* ---------- cups, pots, pouring (story 35) ---------- */
const copa=id=>ob("t_"+id);
const posCopa=id=>{const t=copa(id);if(t&&t.vis!==0)return [t.x,t.y-6];const p=G(id);if(!p)return [140,150];const d=p.dir<0?-1:1,h=alto(id);return [R(p.x)+d*26,R(p.y)-h+1+34-14-3];};
const liq=(id,v,vapor)=>{const t=copa(id);if(t){t.v=v;if(vapor!=null)t.vapor=vapor;}const p=G(id);if(p&&p.alza&&p.alza.k==="taza"){p.alza.v=v;if(vapor!=null)p.alza.vapor=vapor;}if(p&&p.mano&&p.mano.k==="taza")p.mano.v=v;if(p&&p.lleva&&p.lleva.k==="taza")p.lleva.v=v;};
const toma=id=>{const t=copa(id),p=G(id);t.vis=0;p.pose="wave0";p.alza={k:"taza",v:t.v,e:2,dx:26,dy:-14,vapor:t.vapor};};
const baja=id=>{const t=copa(id),p=G(id);if(p.alza&&p.alza.k==="taza"){t.v=p.alza.v;t.vapor=p.alza.vapor;}p.alza=null;p.pose="idle";t.vis=1;};
// a pot (or the sugar spoon) flies to above a cup, tipped, and pours; the liquid changes at the times given (pasos: [[ms, liquid, steam]]); then it flies back (mano: into the frog's hand)
async function echa(de,aId,ms,col,pasos,mano){const t=ob(de),c=posCopa(aId),x0=mano?cx()+14:t.x,y0=mano?pies()-12:t.y,v={k:t.k,v:t.v,x:x0,y:y0,rot:0};t.vis=0;if(mano)W.cq.mano=null;W.vuelos.push(v);const tx=c[0]+9,ty=c[1]-17,n=6;
  for(let i=1;i<=n;i++){const u=i/n;v.x=x0+(tx-x0)*u;v.y=y0+(ty-y0)*u-Math.sin(u*Math.PI)*8;v.rot=-0.75*u;await wait(TICK);}
  const st={k:"chorro",x:c[0],y:ty+3,h:Math.max(3,c[1]-(ty+3)),col:col||"#3E2414"};W.vuelos.push(st);SFX.blip();let t0=0;
  for(const p of pasos||[]){if(p[0]>t0){await wait(p[0]-t0);t0=p[0];}liq(aId,p[1],p[2]);}if(ms>t0)await wait(ms-t0);W.vuelos.splice(W.vuelos.indexOf(st),1);
  for(let i=1;i<=n;i++){const u=i/n;v.x=tx+(x0-tx)*u;v.y=ty+(y0-ty)*u-Math.sin(u*Math.PI)*8;v.rot=-0.75*(1-u);await wait(TICK);}
  W.vuelos.splice(W.vuelos.indexOf(v),1);if(mano)W.cq.mano={k:t.k,dx:14,dy:-12};else t.vis=1;}
// the heaped spoon: flies above a cup and tips; the cup is stirred (mal: it already had its sugar: two heaps)
async function azucar(aId,mal){const q=W.cq,c=posCopa(aId),x0=cx()+13,y0=pies()-14,v={k:"cucharon",v:"a",x:x0,y:y0,rot:0},tx=c[0]+7,ty=c[1]-12,n=6;q.mano=null;W.vuelos.push(v);
  for(let i=1;i<=n;i++){const u=i/n;v.x=x0+(tx-x0)*u;v.y=y0+(ty-y0)*u-Math.sin(u*Math.PI)*8;v.rot=-0.9*u;await wait(TICK);}
  v.v="";const g={k:"chorro",x:c[0]+1,y:ty+2,h:Math.max(3,c[1]-ty-2),col:"#FFFFFF"};W.vuelos.push(g);SFX.blip();await wait(300);W.vuelos.splice(W.vuelos.indexOf(g),1);
  if(mal)liq(aId,"azu",0);for(let k=0;k<3;k++){v.rot=-0.9+(k%2?0.3:-0.1);await wait(TICK);}
  for(let i=1;i<=n;i++){const u=i/n;v.x=tx+(x0-tx)*u;v.y=ty+(y0-ty)*u-Math.sin(u*Math.PI)*8;v.rot=-0.9*(1-u);await wait(TICK);}
  W.vuelos.splice(W.vuelos.indexOf(v),1);q.mano={k:"cucharon",v:"a",dx:13,dy:-14,e:0};}
const acts={
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async ya(){const p=W._mov;W._mov=null;if(p)await p;},
  async g(o){const p=G(o.quien);if(!p)return;Object.keys(o).forEach(k=>{if(!["act","quien","ms"].includes(k))p[k]=o[k]===""?null:o[k];});if(o.ms)await wait(+o.ms);},
  async nota(o){V[o.k]=o.v==null?"1":String(o.v);},

  /* ----- story 33: ¿Qué quieres? ----- */
  // The five rolls come split in the basket (cut open, empty). Whoever asks takes one and holds it up; he goes out to wash his hands and puts it on his plate; the frog spoons the filling in and closes it. A bitten roll stays on the plate of whoever bit it.
  async inicio33(){W.gente={abuela:{vis:0},abuelo:{vis:0},mama:{vis:0},papa:{vis:0},luis:{vis:0},carmen:{vis:0}};W.sitio={};
    const pl=(id,x,y)=>({id,k:"plato",x,y,rollos:[]});
    W.cosas=[pl("pl_abuelo",SILLA[0],FILA),pl("pl_mama",SILLA[1],FILA),pl("pl_papa",SILLA[2],FILA),pl("pl_abuela",SILLA[3],FILA),pl("pl_luis",86,MED-1),pl("pl_carmen",192,MED-1),
      {id:"cesta",k:"cesta",v:"5:0",x:120,y:MED,vapor:1,vdx:-10,vdy:11,vn:2},{id:"mant",k:"mantequilla",x:108,y:FREN},{id:"choc",k:"choc",x:181,y:MED}];
    Object.assign(W.cq,{x:140,y:FREN-27,s:1,sobre:1,dy:0,vis:1,mano:null});},
  // abuela slides her empty plate close to the basket, and goes out to the yard
  async plato33(o){const ab=G("abuela"),pl=ob("pl_abuela");const pr=(async()=>{await entra("abuela",IZQ[0]+4,IZQ[1]);ab.dir=1;ab.pose="offer";await wait(250);const x0=pl.x,y0=pl.y;for(let i=1;i<=6;i++){pl.x=x0+(155-x0)*i/6;pl.y=y0+(MED-y0)*i/6;await wait(TICK);}SFX.blip();await wait(300);ab.pose="idle";await sale("abuela");})();return corre(o,pr);},
  // a person comes in to the end of the table (hand: he takes a roll from the basket and holds it up, cut open and empty)
  async viene33(o){const id=o.a,p=G(id),E=id==="carmen"?DER:IZQ;await entra(id,E[0],E[1],id==="carmen"?-1:1);p.dir=id==="carmen"?-1:1;
    if(o.rollo){const ce=ob("cesta"),n=+String(ce.v).split(":")[0];ce.v=(n-1)+":0";p.pose="wave0";p.alza={k:"rollo",v:"ab",e:2,dx:19,dy:-18};SFX.blip();await wait(300);}},
  // he sets the roll on his plate (if he holds one) and goes out to wash his hands
  async sale33(o){const id=o.a,p=G(id),pl=ob(id==="abuela"?"pl_abuela":"pl_"+id);if(p.alza){const m=mano(id);p.alza=null;p.pose="idle";const r={st:"ab"};await vuela({k:"rollo",v:"ab"},m[0],m[1],pl.x+(pl.rollos.length?5:0),pl.y-4,6);r.dx=pl.rollos.length?5:0;pl.rollos.push(r);}await sale(id);},
  // the frog spoons the filling into the roll on that plate (taking one split roll from the basket if there is none yet) and closes it
  async rellena33(o){const id=o.a,pl=ob("pl_"+id),k=String(o.k),dish=ob(k==="choc"?"choc":"mant"),ce=ob("cesta"),q=W.cq,fin=id==="luis"||id==="carmen";
    let r=pl.rollos.filter(x=>x.st==="ab").pop();
    await ranaA(fin?(id==="luis"?pl.x+26:pl.x-26):pl.x,FREN);
    if(!r){const n=+String(ce.v).split(":")[0];ce.v=(n-1)+":0";SFX.blip();await vuela({k:"rollo",v:"ab"},ce.x,ce.y-8,pl.x+(pl.rollos.length?5:0),pl.y-4,6);r={st:"ab",dx:pl.rollos.length?5:0};pl.rollos.push(r);}
    q.mano={k:"cucharon",v:"",dx:fin?(id==="luis"?-13:13):0,dy:-10,e:0};await wait(200);
    SFX.blip();await vuela({k:"cucharon",v:k==="choc"?"c":"m"},dish.x,dish.y-14,pl.x+(r.dx||0),pl.y-8,7);r.con=k==="choc"?"c":"m";SFX.blip();await wait(450);
    q.mano=null;r.st="ce";SFX.blip();await wait(300);await ranaA(156,FREN);},
  // he comes back to his chair, or to his place at the end of the table
  async regresa33(o){const id=o.a,fin=id==="luis"||id==="carmen";if(fin){const E=id==="carmen"?DER:IZQ;await entra(id,E[0],E[1],id==="carmen"?-1:1);G(id).dir=id==="carmen"?-1:1;}else await sienta(id,{abuelo:0,mama:1,papa:2,abuela:3}[id]);},
  // he takes the roll off his plate and bites it: right, he eats it; wrong, he makes a face and puts it down on his plate, bitten
  async come33(o){const id=o.a,p=G(id),pl=ob("pl_"+id);const pr=(async()=>{const r=pl.rollos.filter(x=>x.st==="ce").pop();if(!r)return;pl.rollos.splice(pl.rollos.indexOf(r),1);p.come={k:"rollo",v:"ce"};SFX.blip();await wait(650);
    if(+o.bien){p.come=null;SFX.blip();pl.v="mi";await wait(450);}
    else{p.come={k:"rollo",v:"mo:"+r.con};p.cara="mal";SFX.bonk();p.dy=-2;await wait(250);p.dy=0;await wait(450);p.come=null;pl.rollos.push({st:"mo",con:r.con,dx:-5});await wait(450);p.cara=null;}})();return corre(o,pr);},
  // the turn: abuela brings the second tray from the oven and tips four rolls into the basket; she points at her empty plate; papá and Carmen look in and go out again
  async turno33(o){const ab=G("abuela"),ce=ob("cesta"),pl=ob("pl_abuela");await entra("abuela",FOGON[0],FOGON[1]);ab.lleva={k:"bandeja",v:4,dx:-14,dy:19};SFX.blip();await wait(400);await mueve("abuela",IZQ[0]+4,IZQ[1]);ab.dir=1;await wait(150);
    ab.lleva=null;for(let i=0;i<4;i++){vuela({k:"rollo",v:"ab",e:0},ab.x+14,ab.y-26,ce.x-12+i*8,ce.y-10,6);await wait(TICK*2);}await wait(TICK*4);ce.v="4:0";SFX.blip();},
  async apunta33(){const ab=G("abuela"),pl=ob("pl_abuela");ab.dir=1;ab.pose="offer";SFX.blip();await wait(900);ab.pose="idle";},
  async sale33a(){await sale("abuela");},
  async miran33(){const pa=G("papa"),ca=G("carmen");pa.vis=ca.vis=0;await Promise.all([entra("papa",IZQ[0],IZQ[1],1),entra("carmen",DER[0],DER[1],-1)]);await wait(600);await Promise.all([sale("papa"),sale("carmen")]);},
  // the ending: the family comes in; abuela eats a roll that is left, plain; the other, if any, lies under the cloth
  async final33(o){const ce=ob("cesta"),pl=ob("pl_abuela"),ab=G("abuela");pl.x=SILLA[3];pl.y=FILA;const n=+String(ce.v).split(":")[0];
    await Promise.all([sienta("abuelo",0),sienta("mama",1),sienta("papa",2),entra("luis",IZQ[0],IZQ[1],1),entra("carmen",DER[0],DER[1],-1)]);
    await sienta("abuela",3);V.pan=n>0?"1":"";
    if(n>0){ce.v=(n-1)+":0";ab.come={k:"rollo",v:"ce"};SFX.blip();await wait(900);ab.come=null;pl.v="mi";}
    if(n>1){ce.v="1:1";ce.vapor=0;SFX.blip();await wait(500);}else ce.vapor=0;
    await wait(500);W.cq.hace=n>0?"come":null;await wait(400);},

  /* ----- story 34: Buen provecho ----- */
  // Lunch: yellow rice. Abuelo, mamá (with the baby) and Carmen sit; papá's chair and plate are empty; Luis stands at the left end; the frog and his small plate are on the table, and the pot of rice. Luis has the big spoon from step 3. The platter (after the turn): W.cosas "fuente" {montones:[{dx, g:"m" helping | "p" papá's}]}
  async inicio34(){W.gente={abuelo:{x:SILLA[0],y:148,sent:1,dir:1},mama:{x:SILLA[1],y:148,sent:1,dir:1,bebe:1},papa:{vis:0},carmen:{x:SILLA[3],y:148,sent:1,dir:1},luis:{x:IZQ[0],y:IZQ[1],dir:1},abuela:{x:FOGON[0],y:FOGON[1],dir:-1}};W.sitio={abuelo:0,mama:1,papa:2,carmen:3};
    const pl=(id,x,y,v)=>({id,k:"plato",x,y,v:v||"",rollos:[]});
    W.cosas=[pl("pl_abuelo",SILLA[0],FILA,"r"),pl("pl_mama",SILLA[1],FILA,"r"),pl("pl_papa",SILLA[2],FILA),pl("pl_carmen",SILLA[3],FILA,"r"),pl("pl_luis",86,MED-1,"r"),
      {id:"pl_rana",k:"platito",x:196,y:FREN},{id:"olla",k:"olla",v:"lleno",x:118,y:FREN,vapor:1,vdx:0,vdy:19,vn:2}];
    Object.assign(W.cq,{x:156,y:FREN-27,s:1,sobre:1,dy:0,vis:1,mano:null,lleno:0,espalda:0});},
  // everybody holds a fork up and waits; then they eat
  async tenedores34(o){["abuelo","mama","carmen","luis"].forEach(id=>{const p=G(id);p.pose="wave0";p.alza={k:"tenedor",e:1,dx:13,dy:-12};});SFX.blip();await wait(500);},
  async come34(o){const pr=(async()=>{["abuelo","mama","carmen"].forEach(id=>{const p=G(id);p.alza=null;p.pose="idle";p.come={k:"tenedor"};});await wait(1200);["abuelo","mama","carmen"].forEach(id=>{G(id).come=null;});})();return corre(o,pr);},
  // Luis eats his last forkfuls: his plate is clean
  async luisCome34(o){const l=G("luis"),pl=ob("pl_luis");const pr=(async()=>{l.alza=null;l.pose="idle";l.come={k:"tenedor"};await wait(1100);l.come=null;pl.v="";})();return corre(o,pr);},
  // abuela gives Luis the big spoon
  async cuchara34(o){const ab=G("abuela"),l=G("luis");await mueve("abuela",IZQ[0]+30,IZQ[1]+8);ab.dir=-1;ab.pose="offer";SFX.blip();await wait(450);l.mano={k:"cucharon",v:"",dx:14,dy:-14,e:0};ab.pose="idle";await wait(250);await mueve("abuela",FOGON[0],FOGON[1]);ab.dir=-1;},
  // Luis: sirve (he serves himself one mound onto his plate), come (he eats it), cuchara (he lifts a mound onto the big spoon, and holds it out to the frog: tiende), entrega (he hands the frog the spoon with the mound on it)
  async luis34(o){const l=G("luis"),pl=ob("pl_luis"),fu=ob("fuente"),pr=(async()=>{
      const src=()=>{if(fu&&fu.montones){const m=fu.montones.filter(m=>m.g==="m")[0];if(m){fu.montones.splice(fu.montones.indexOf(m),1);return [fu.x+m.dx,fu.y-6];}}const ol=ob("olla");return ol?[ol.x,ol.y-16]:[120,150];};
      if(o.que==="sirve"){W.cq.mano=null;l.mano={k:"cucharon",v:"",dx:14,dy:-14,e:0};const a=src();await vuela({k:"monton"},a[0],a[1],pl.x,pl.y-5,7);pl.v="o";SFX.blip();await wait(250);}
      else if(o.que==="come"){l.come={k:"monton"};pl.v="";SFX.blip();await wait(800);l.come=null;}
      else if(o.que==="cuchara"){const a=src();await vuela({k:"monton"},a[0],a[1],l.x+14,l.y-alto("luis")+22,7);l.mano={k:"cucharon",v:"m",dx:14,dy:-14,e:0,rot:+o.tiende?0.9:0};SFX.blip();await wait(300);}
      else if(o.que==="entrega"){const a=src();await vuela({k:"monton"},a[0],a[1],l.x+14,l.y-alto("luis")+22,7);l.mano=null;W.cq.mano={k:"cucharon",v:"m",dx:13,dy:-14,e:0};SFX.blip();await wait(300);}})();return corre(o,pr);},
  // a thought over the frog: what he would like (quiere) or his belly beside the clean plate (lleno)
  async piensa34(o){W.cq.piensa=o.k==="lleno"?{k:"barriga"}:{k:"montoncor"};SFX.blip();await wait(300);},
  async calla34(){W.cq.piensa=null;},
  // the mound on the big spoon goes to the frog's plate and he eats it (an act for the frog's own plate)
  async ranaCome34(o){const l=G("luis"),pl=ob("pl_rana"),q=W.cq;const pr=(async()=>{q.piensa=null;const m=l.mano||q.mano;if(m&&m.v==="m"){m.v="";}await vuela({k:"monton"},l.x+14,l.y-alto("luis")+22,pl.x,pl.y-4,8);pl.v="o";SFX.blip();await wait(250);q.hace="come";await wait(800);q.hace=null;pl.v="mi";if(o.lleno)q.lleno=1;l.mano=null;if(o.entera){q.espalda=1;pl.v="mi";SFX.bonk();await wait(700);}})();return corre(o,pr);},
  async levantaRana34(){W.cq.espalda=0;SFX.blip();await wait(250);},
  // Luis eats the mound on the spoon too
  async luisCome2(o){const l=G("luis");const pr=(async()=>{if(l.mano)l.mano.v="";l.piensa=null;W.cq.piensa=null;l.come={k:"monton"};SFX.blip();await wait(800);l.come=null;l.mano=null;})();return corre(o,pr);},
  // Luis glances at papá's fork and takes one of papá's three for the frog (rana) or for himself (luis)
  async luisPapa34(o){const l=G("luis"),fu=ob("fuente"),q=W.cq;await wait(450);const g=fu.montones.filter(m=>m.g==="p");const m=g[0];if(!m)return;fu.montones.splice(fu.montones.indexOf(m),1);const a=[fu.x+m.dx,fu.y-6];
    if(o.para==="rana"){const pl=ob("pl_rana");await vuela({k:"monton"},a[0],a[1],pl.x,pl.y-4,8);pl.v="o";SFX.blip();await wait(250);q.hace="come";await wait(800);q.hace=null;pl.v="mi";}
    else{const pl=ob("pl_luis");await vuela({k:"monton"},a[0],a[1],pl.x,pl.y-5,8);pl.v="o";SFX.blip();await wait(250);l.come={k:"monton"};await wait(800);l.come=null;pl.v="";}},
  // steps 5 and 6: the three at the table; whoever says "Yo estoy lleno/llena" puts a hand on his belly
  async mano34(o){const p=G(o.a);p.pose=o.pose||"yo";SFX.blip();await wait(150);},
  async plato34(o){const pl=ob("pl_"+o.a);pl.v=o.v||"";},
  // the frog tips the mound on the spoon onto that one's plate, where it mixes into his rice (o.mezcla), or he eats it (o.come)
  async tipa34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),q=W.cq;const pr=(async()=>{await wait(150);const m=q.mano;if(m)m.v="";await vuela({k:"monton"},q.x+29,q.y+10,pl.x,pl.y-5,8);
      if(+o.mezcla){pl.v="h";SFX.bonk();await wait(450);}else{pl.v="rm";SFX.blip();await wait(300);p.pose="idle";p.come={k:"tenedor"};await wait(800);p.come=null;pl.v="";}q.mano=null;})();return corre(o,pr);},
  // whoever was full only now puts a hand on his belly and pushes his plate a little away
  async llenoAhora34(o){const p=G(o.a),pl=ob("pl_"+o.a);p.pose="yo";pl.x+=6;pl.y+=2;SFX.blip();await wait(500);},
  // gets up (with the baby), says it to the table (a line follows), and goes to the counter; con: carries his plate there
  async levanta34(o){const id=o.a,p=G(id),pl=ob("pl_"+id);p.sent=0;p.y=148;p.pose="idle";SFX.blip();await wait(300);const xs=[IZQ[0]+8];
    if(+o.plato){pl.vis=0;p.mano={k:"plato",v:pl.v,dx:10,dy:-6,e:0};}
    await mueve(id,IZQ[0]+14,150);p.dir=-1;if(+o.plato){p.mano=null;pl.x=62;pl.y=MOSTR[1]+8;pl.vis=1;pl.z=140;}SFX.blip();await wait(200);},
  async vuelve34(o){const id=o.a,p=G(id),pl=ob("pl_"+id);if(+o.plato){pl.vis=0;p.mano={k:"plato",v:pl.v,dx:10,dy:-6,e:0};}await mueve(id,SILLA[{abuelo:0,mama:1,papa:2,carmen:3}[id]],148);p.sent=1;p.y=148;p.dir=1;if(+o.plato){p.mano=null;pl.x=SILLA[3];pl.y=FILA;pl.z=null;pl.vis=1;}SFX.blip();},
  // after a miss: a second mound, from papá's three, for the one who asked; he eats it
  async papaB34(o){const id=o.a,p=G(id),pl=ob("pl_"+id),fu=ob("fuente");const m=fu.montones.filter(m=>m.g==="p")[0];if(m){fu.montones.splice(fu.montones.indexOf(m),1);await vuela({k:"monton"},fu.x+m.dx,fu.y-6,pl.x,pl.y-5,8);}pl.v="rm";SFX.blip();await wait(300);p.come={k:"tenedor"};await wait(800);p.come=null;pl.v="";},
  async mira34(o){const l=G("luis");l.dir=1;await wait(500);},
  // the turn: abuela gives each of the three a small spoon of rice, scrapes the pot out onto a platter (seven mounds), tips the pot towards us, pushes three mounds to papá's end and lays his fork on them, takes her shawl and goes to the gate
  async turno34(o){const ab=G("abuela"),ol=ob("olla");
    await mueve("abuela",DER[0],DER[1]);ab.dir=-1;ab.pose="offer";await wait(200);
    for(const id of ["abuelo","mama","carmen"]){const pl=ob("pl_"+id);await vuela({k:"monton",e:0},ab.x-16,ab.y-30,pl.x,pl.y-5,8);pl.v="r";SFX.blip();await wait(200);}
    ab.pose="idle";await wait(200);W.cosas=W.cosas.filter(x=>x!==ol);ab.lleva={k:"olla",v:"lleno",dx:-16,dy:6};SFX.blip();await wait(500);
    const fu={id:"fuente",k:"fuente",x:127,y:FREN+1,montones:[]};W.cosas.push(fu);
    const xs=[-24,-16,-8,0,10,18,26],gs=["m","m","m","m","p","p","p"];for(let i=0;i<7;i++){fu.montones.push({dx:xs[i]-(i>3?0:0),g:gs[i]});SFX.blip();await wait(220);}
    ab.lleva={k:"olla",v:"vacio",dx:-12,dy:34,e:2};SFX.blip();await wait(900);ab.lleva=null;
    fu.tenedor={dx:18};SFX.blip();await wait(500);
    await mueve("abuela",PUERTA[0]+8,184);ab.vis=0;},
  // papá comes in with abuela; he sits; abuela scrapes what is left at his end of the platter onto his plate
  async final34(o){const ab=G("abuela"),pa=G("papa"),fu=ob("fuente"),pl=ob("pl_papa");pa.vis=1;pa.sent=0;pa.x=PUERTA[0];pa.y=148;ab.vis=1;ab.x=PUERTA[0]-4;ab.y=186;ab.dir=1;
    const pr=(async()=>{await mueve("abuela",IZQ[0]+30,184);ab.dir=1;})();await sienta("papa",2);await pr;const n=fu.montones.filter(m=>m.g==="p").length;W.cosas=W.cosas.filter(x=>x.id!=="pl_papa_f");
    SFX.blip();await wait(400);await mueve("abuela",DER[0],DER[1]);ab.dir=-1;ab.pose="offer";await wait(300);
    fu.montones=fu.montones.filter(m=>m.g!=="p");fu.tenedor=null;pl.v="p"+Math.max(1,Math.min(3,n));V.pmont=String(n);SFX.blip();await wait(500);ab.pose="idle";await mueve("abuela",FOGON[0],FOGON[1]);ab.dir=-1;},
  async papaCome34(o){const pa=G("papa"),pl=ob("pl_papa");const pr=(async()=>{pa.come={k:"tenedor"};await wait(1100);if(o.fin){pa.come=null;pl.v="mi";}})();return corre(o,pr);},
  async papaMira34(){const pa=G("papa");pa.dir=1;pa.pose="idle";await wait(900);},

  /* ----- story 35: Café con azúcar ----- */
  // The table is cleared. Abuelo (chair 2) and papá (chair 3) have black coffee; Luis and Carmen hold cups of hot milk at the left end; the frog stands by the sugar bowl with its big spoon, his own small cup by him. On the stove: the big coffee pot, the little pouring pot, the milk pan. Canelo lies by his empty bowl. A cup is the thing "t_<who>"; held up, it is the person's `alza`. Cups show their colour from above.
  async inicio35(){W.gente={abuelo:{x:SILLA[1],y:148,sent:1,dir:-1},papa:{x:SILLA[3],y:148,sent:1,dir:1},luis:{x:IZQ[0],y:IZQ[1],dir:1,mano:{k:"taza",v:"leche",dx:9,dy:-4}},carmen:{x:34,y:184,dir:1,mano:{k:"taza",v:"leche",dx:9,dy:-4}},abuela:{x:FOGON[0],y:FOGON[1],dir:-1},mama:{vis:0}};W.sitio={abuelo:1,papa:3};
    W.cosas=[{id:"t_abuelo",k:"taza",x:SILLA[1],y:FILA,v:"negro",vapor:1},{id:"t_papa",k:"taza",x:SILLA[3],y:FILA,v:"negro",vapor:1},{id:"t_luis",k:"taza",x:118,y:FREN,v:"leche",vapor:1,vis:0},{id:"t_carmen",k:"taza",x:134,y:FREN,v:"leche",vapor:1,vis:0},
      {id:"azucarera",k:"azucarera",x:92,y:FREN},{id:"t_rana",k:"taza",x:184,y:FREN,v:"vacia",vapor:0},{id:"t_abuela",k:"taza",x:186,y:112,v:"vacia",vapor:0,vis:0},
      {id:"cafetera",k:"cafetera",x:192,y:106,vapor:1,vdx:-2,vdy:22,vn:1},{id:"jarrita",k:"jarrita",x:210,y:106},{id:"cazo",k:"cazo",v:"1",x:200,y:112},{id:"tazon",k:"tazon",v:"0",x:168,y:208}];
    W.perro={x:205,y:203,pose:"lie",dir:-1};W.pote={};
    Object.assign(W.cq,{x:140,y:FREN-27,s:1,sobre:1,dy:0,vis:1,mano:{k:"cucharon",v:"a",dx:13,dy:-14,e:0},lleno:0,espalda:0});},
  // abuela comes to the end of the table with the big pot
  async trae35(o){const ab=G("abuela");SFX.blip();await mueve("abuela",DER[0]-4,DER[1]);ab.dir=-1;ab.pose="offer";await wait(200);ab.pose="idle";},
  async vuelve35(o){const ab=G("abuela");await mueve("abuela",FOGON[0],FOGON[1]);ab.dir=-1;},
  // the men hold their cups out; or set them down
  async tienden35(o){String(o.a).split(",").forEach(id=>toma(id));SFX.blip();await wait(400);},
  async bajan35(o){String(o.a).split(",").forEach(id=>baja(id));await wait(200);},
  // the frog tips the heaped spoon into a cup, and stirs (mal: the cup already had its sugar); abuela pours coffee into a cup (mal: the last finger, into the same cup)
  async azucar35(o){const pr=(async()=>{await azucar(o.a,+o.mal);})();return corre(o,pr);},
  async cafe35(o){const id=o.a,pr=(async()=>{await echa("cafetera",id,+o.dedo?600:1000,"#2A160C",[[200,+o.mal?"azu":"negro",+o.mal?0:1]]);if(+o.vacia){W.pote.vacia=1;}})();return corre(o,pr);},
  async llena35(){W.cq.mano={k:"cucharon",v:"a",dx:13,dy:-14,e:0};SFX.blip();await wait(200);},
  async prueba35(o){for(const id of String(o.a).split(",")){const p=G(id);p.dy=-2;await wait(150);p.dy=0;await wait(150);}},
  // he looks into his cup, and pushes it to the middle of the table
  async empuja35(o){const id=o.a,p=G(id),t=copa(id);const al=p.alza;await wait(500);p.alza=null;p.pose="idle";t.vis=1;t.vapor=0;t.v="azu";const x0=t.x,y0=t.y;SFX.bonk();for(let i=1;i<=8;i++){t.x=x0+(138-x0)*i/8;t.y=y0+(MED-y0)*i/8;await wait(TICK);}await wait(300);},
  // steps 4 and 5: abuela gives the frog the little pot; the children stand their cups of milk in front of the frog (ponen), go out (salen), come back and drink (vuelven)
  async pote35(o){const jt=ob("jarrita"),q=W.cq;jt.vis=0;if(q.mano&&q.mano.k==="cucharon"){W.cosas.push({id:"cucharon",k:"cucharon",v:"a",x:104,y:FREN-3,rot:1.3});q.mano=null;}await vuela({k:"jarrita"},jt.x,jt.y,cx()+14,pies()-12,8);q.mano={k:"jarrita",dx:14,dy:-12,e:0};SFX.blip();await wait(250);},
  async ninos35(o){const l=G("luis"),ca=G("carmen"),tl=copa("luis"),tc=copa("carmen");
    if(o.que==="ponen"){tl.v="leche";tc.v="leche";tl.vapor=tc.vapor=1;l.mano=ca.mano=null;await Promise.all([vuela({k:"taza",v:"leche"},l.x+9,l.y-alto("luis")+26,tl.x,tl.y-4,7),vuela({k:"taza",v:"leche"},ca.x+9,ca.y-alto("carmen")+26,tc.x,tc.y-4,9)]);tl.vis=tc.vis=1;SFX.blip();await wait(250);}
    else if(o.que==="salen"){await Promise.all([sale("luis"),sale("carmen")]);}
    else if(o.que==="vuelven"){await Promise.all([entra("luis",IZQ[0],IZQ[1],1),entra("carmen",34,184,1)]);}
    else if(o.que==="toman"){const pr=(async()=>{tl.vis=tc.vis=0;await Promise.all([vuela({k:"taza",v:tl.v},tl.x,tl.y-4,l.x+9,l.y-alto("luis")+26,7),vuela({k:"taza",v:tc.v},tc.x,tc.y-4,ca.x+9,ca.y-alto("carmen")+26,9)]);l.mano={k:"taza",v:tl.v,dx:9,dy:-4};ca.mano={k:"taza",v:tc.v,dx:9,dy:-4};await wait(200);
        l.bebe2=tl.v;ca.bebe2=tc.v;l.mano=ca.mano=null;SFX.blip();await wait(1000);l.bebe2=ca.bebe2=null;tl.v=tc.v="vacia";tl.vapor=tc.vapor=0;l.mano={k:"taza",v:"vacia",dx:9,dy:-4};ca.mano={k:"taza",v:"vacia",dx:9,dy:-4};})();return corre(o,pr);}},
  // the frog pours as told: a long pour (mucho) turns the milk brown; a splash (poco) turns it pale
  async vierte35(o){const id=o.a,t=copa(id),q=W.cq,mucho=o.cant==="mucho";await ranaA(t.x+24,FREN);await echa("jarrita",id,mucho?1400:450,"#3E2414",mucho?[[300,"palido",1],[900,"marron",1]]:[[200,"palido",1]],1);await ranaA(156,FREN);},
  // the frog's own cup, the thoughts and answers of step 6
  async piensa35(o){W.cq.piensa=o.k?{k:"taza",v:o.k,e:1}:null;if(o.k)SFX.blip();await wait(250);},
  async sirve6(o){const mucho=o.cant==="mucho",jt=ob("jarrita");W.cq.piensa=null;const ps=mucho?[[200,"negro",1]]:[[150,"negro",1]];
    if(W.cq.mano&&W.cq.mano.k==="jarrita"){W.cq.mano=null;jt.x=198;jt.y=FREN;jt.vis=1;}
    await echa("jarrita","rana",mucho?1300:450,"#2A160C",ps);await echa("cazo","rana",mucho?500:1100,"#F6F1E4",[[200,mucho?"marron":"palido",1]]);SFX.blip();},
  async rana35bebe(o){const q=W.cq;q.hace="bebe";copa("rana").vis=0;q.mano={k:"taza",v:copa("rana").v,dx:0,dy:-4,e:0};await wait(900);q.hace=null;q.mano=null;const t=copa("rana");t.vis=1;t.v="vacia";t.vapor=0;SFX.blip();await wait(200);},
  // the turn: the cups are empty; abuela pours the last of the big pot (a half cup each for abuelo, papá and herself), the men sweeten and nod; the last milk into the children's cups; the little pot, full, goes up on the shelf; she sits down at the stove with her own cup
  async turno35(o){const ab=G("abuela"),l=G("luis"),ca=G("carmen"),pe=W.perro;
    ["abuelo","papa","rana"].forEach(id=>liq(id,"vacia",0));["luis","carmen"].forEach(id=>{liq(id,"vacia",0);});copa("abuela").vis=1;copa("abuela").v="vacia";
    await mueve("abuela",DER[0]-4,DER[1]);ab.dir=-1;
    await echa("cafetera","abuelo",700,"#2A160C",[[200,"negro",1]]);await echa("cafetera","papa",700,"#2A160C",[[200,"negro",1]]);await echa("cafetera","abuela",700,"#2A160C",[[200,"negro",1]]);W.pote.dedo=1;
    W.cq.mano={k:"cucharon",v:"a",dx:13,dy:-14,e:0};await azucar("abuelo",0);await azucar("papa",0);await acts.prueba35({a:"abuelo,papa"});
    l.mano=ca.mano=null;l.alza={k:"taza",v:"vacia",e:2,dx:15,dy:-14};ca.alza={k:"taza",v:"vacia",e:2,dx:15,dy:-14};await wait(300);
    const tl=copa("luis");tl.vis=0;const lx=l.x,lyy=l.y;
    for(const id of ["luis","carmen"]){const p=G(id);const c=posCopa(id);const jj=ob("cazo");const x0=jj.x,y0=jj.y;jj.vis=0;const v={k:"cazo",v:"1",x:x0,y:y0,rot:0};W.vuelos.push(v);const tx=c[0]+10,ty=c[1]-14;for(let i=1;i<=6;i++){const u=i/6;v.x=x0+(tx-x0)*u;v.y=y0+(ty-y0)*u-Math.sin(u*Math.PI)*8;v.rot=-0.6*u;await wait(TICK);}
      const st={k:"chorro",x:c[0],y:ty+3,h:Math.max(3,c[1]-ty-3),col:"#F6F1E4"};W.vuelos.push(st);p.alza.v="leche";p.alza.vapor=1;SFX.blip();await wait(600);W.vuelos.splice(W.vuelos.indexOf(st),1);for(let i=1;i<=6;i++){const u=i/6;v.x=tx+(x0-tx)*u;v.y=ty+(y0-ty)*u-Math.sin(u*Math.PI)*8;v.rot=-0.6*(1-u);await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);jj.vis=1;}
    l.alza=null;ca.alza=null;l.mano={k:"taza",v:"leche",dx:9,dy:-4};ca.mano={k:"taza",v:"leche",dx:9,dy:-4};W.pote.leche=1;
    const jt=ob("jarrita"),x0=jt.x,y0=jt.y;jt.vis=0;await vuela({k:"jarrita"},x0,y0,203,72,8);jt.x=203;jt.y=72;jt.vis=1;SFX.blip();await wait(300);
    // she sits down at the stove with her own cup
    await mueve("abuela",FOGON[0]-4,FOGON[1]+2);ab.dir=-1;},
  async sientaAb35(o){const ab=G("abuela"),t=copa("abuela");ab.dir=-1;t.vis=0;ab.sent=1;ab.taburete=1;ab.y=FOGON[1]+8;ab.x=FOGON[0]-6;ab.lleva={k:"taza",v:t.v};SFX.blip();await wait(300);},
  // round A: abuela gets up with the big pot and its last pour; the men hold their half cups out
  async turnoA35(o){const ab=G("abuela");ab.sent=0;ab.taburete=0;ab.lleva=null;ab.y=FOGON[1];SFX.blip();await mueve("abuela",DER[0]-4,DER[1]);ab.dir=-1;toma("abuelo");toma("papa");W.cq.mano={k:"cucharon",v:"a",dx:13,dy:-14,e:0};await wait(400);},
  // after A: abuela puts the big pot on the stove, takes the little pot down from the shelf and hands it to the frog, full; he stands it by his small cup
  async despuesA35(o){const ab=G("abuela"),jt=ob("jarrita");baja("abuelo");baja("papa");W.cq.mano=null;await wait(200);await vuela({k:"jarrita"},jt.x,jt.y,198,FREN,8);jt.vis=1;jt.x=198;jt.y=FREN;SFX.blip();await wait(300);await mueve("abuela",FOGON[0]-6,FOGON[1]+8);ab.dir=-1;ab.sent=1;ab.taburete=1;ab.lleva={k:"taza",v:copa("abuela").v};},
  // round B: abuela pours from the little pot what he said, tips what is left into her own cup, fills his cup to the brim with milk, tips the rest of the pan into Canelo's bowl; the pan is empty
  async sirveB35(o){const ab=G("abuela"),mucho=String(o.cant).replace(/^di_/,"")==="mucho",jt=ob("jarrita"),cz=ob("cazo"),tz=ob("tazon"),pe=W.perro,t=copa("abuela");W.cq.piensa=null;ab.sent=0;ab.taburete=0;ab.lleva=null;copa("abuela").vis=1;
    await mueve("abuela",DER[0]-4,DER[1]);ab.dir=-1;
    await echa("jarrita","rana",mucho?1300:450,"#2A160C",[[200,"negro",1]]);
    t.v="negro";t.vis=1;await wait(200);   // what is left in the little pot goes into her own cup
    await echa("cazo","rana",mucho?500:1100,"#F6F1E4",[[200,mucho?"marron":"palido",1]]);
    // what is left in the pan goes into Canelo's bowl
    cz.vis=0;const v={k:"cazo",v:"1",x:cz.x,y:cz.y,rot:0};W.vuelos.push(v);const x0=cz.x,y0=cz.y,tx=tz.x+10,ty=tz.y-26;for(let i=1;i<=8;i++){const u=i/8;v.x=x0+(tx-x0)*u;v.y=y0+(ty-y0)*u-Math.sin(u*Math.PI)*10;v.rot=-0.5*u;await wait(TICK);}
    const st={k:"chorro",x:tz.x,y:ty+4,h:Math.max(3,tz.y-ty-9),col:"#F6F1E4"};W.vuelos.push(st);tz.v="1";SFX.blip();await wait(500);W.vuelos.splice(W.vuelos.indexOf(st),1);cz.v="0";v.v="0";
    for(let i=1;i<=6;i++){const u=i/6;v.x=tx+(x0-tx)*u;v.y=ty+(y0-ty)*u;v.rot=-0.5*(1-u);await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);cz.vis=1;
    pe.pose="eat";pe.x=tz.x+22;pe.y=tz.y+1;pe.dir=-1;await wait(900);tz.v="0";pe.pose="lie";pe.x=205;pe.y=203;pe.dir=-1;
    W.pote.vacia=1;W.pote.pan=1;},
  async pruebaB35(o){const q=W.cq,t=copa("rana");q.hace="come";await wait(500);q.hace=null;t.vapor=0;SFX.bonk();await wait(500);},
  // after a miss in B: abuela drinks her own cup off, happy (a big pleased "ah", a hand on her chest), then shows her empty cup, the little pot and the pan
  async bebeAb35(o){const ab=G("abuela"),t=copa("abuela"),jt=ob("jarrita"),cz=ob("cazo");ab.vis=1;ab.sent=0;ab.taburete=0;ab.pose="bless";ab.abre=1;t.vis=0;ab.alza={k:"taza",v:"negro",e:2,dx:-12,dy:34};SFX.blip();await wait(900);ab.alza={k:"taza",v:"vacia",e:2,dx:-12,dy:34};ab.abre=0;ab.pose="idle";await wait(700);},
  async muestra35(o){const ab=G("abuela"),jt=ob("jarrita"),cz=ob("cazo");const it=o.k;ab.pose="offer";ab.dir=-1;
    if(it==="taza")ab.alza={k:"taza",v:"vacia",e:2,dx:-16,dy:30};else if(it==="jarrita"){ab.alza={k:"jarrita",e:2,dx:-16,dy:30};}else{ab.alza={k:"cazo",v:"0",e:2,dx:-16,dy:30};}SFX.blip();await wait(800);ab.alza=null;ab.pose="idle";},
  // the ending: everybody drinks; a spoiled cup stands in the middle of the table; abuela drinks at the stove
  async final35(o){const ab=G("abuela");const b=[["abuelo"],["papa"]];for(const id of ["abuelo","papa"]){const t=copa(id);if(t.vis!==0&&t.v!=="azu"&&t.x<=SILLA[3]+2){/* stays on the table */}}
    const pr=(async()=>{for(const id of ["abuelo","papa"]){const t=copa(id),p=G(id);if(t.v!=="azu"&&t.vis!==0){p.bebe2=t.v;t.vis=0;}}await wait(1000);for(const id of ["abuelo","papa"]){const t=copa(id),p=G(id);if(p.bebe2){p.bebe2=null;t.vis=1;t.v="vacia";t.vapor=0;}}})();
    ab.sent=1;ab.taburete=1;ab.lleva={k:"taza",v:copa("abuela").v};V.cafe=copa("abuela").v!=="vacia"?"1":"";await pr;W.cq.hace=null;await wait(500);},

  // everything at once, to look at the drawing
  async prueba(o){W.gente={};W.cosas=[];}
};
async function stake(lost,max,en){await wait(200);}
function poke(what){}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)+(W.gente[k].sent?"s":"")+(W.gente[k].alza?"^"+W.gente[k].alza.k:"")+(W.gente[k].come?"("+W.gente[k].come.k+")":"")).join(" ")+" cesta="+(((W.cosas||[]).find(o=>o.id==="cesta")||{}).v)+" platos="+(W.cosas||[]).filter(o=>o.k==="plato").map(o=>(o.v||"")+"/"+(o.rollos||[]).map(r=>r.st+(r.con||"")).join("+")).join("|")+" marcas="+(W.marcas||[]).join(",");
KIT.escena({id:"comer",CAM:{wide:[22,0,196,216]},heartAt:[124,22],lugar:{inicio:[124,141,1],centro:[124,141,1]},cosas:COSAS,
  fresh:()=>({respEn:[125,28],gente:{},sitio:{},cosas:[],vuelos:[],perro:null,tarjeta:null,marcas:null,cq:{x:140,y:141,s:1,dy:0,al:1,vis:1,sobre:1,bub:null,hace:null,piensa:null,mano:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
