"use strict";
/* ============================================================
   Coquí · scene "La estufa": abuela's stove (place 3, La cocina).
   The stove stands in the middle, seen from the front and a little
   from above, with two burners. A pot or a pan is open at the top, so
   what is in it shows. On the left a counter for what goes into the
   pots; on the right a counter for plates and cups, and a waste bowl.
   The cooks stand at the two sides of the stove, lower than the pots;
   the frog stands on a stool in front.
   A burner is W.fuegos[i]: {k (olla, sarten), con (agua, arroz,
   hab, choco), n (how full: 0 to 2), llama, vapor, humo, negra,
   cosas:[{k, lado, negro, sal}]} (cosas: what fries in a pan).
   The left counter is W.izq, the right counter W.der, the waste bowl
   W.basura (a list of what was thrown in it). People live in W.gente,
   as in the kitchen scene (mesa.js).
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round,tarjeta=KIT.tarjeta;
const PISO=150,ENC=112,EST=[86,106,80,54],FX=[107,145],FY=121,IZQ=[24,54],DER=[172,46],BANCO=[126,184];   // the floor; the counter tops; the stove (x, y of its top, width, height); the two burners; the left and right counters (x, width); the frog's stool
const REP=[EST[0]+66,FY+9],ESX=EST[0]+26,CUBO=[34,208],SALX=EST[0]+40;   // cups that were put aside stand on the front of the stove
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,abuelo:FAM.abuelo,mama:FAM.mama,papa:FAM.papa,abuela:{}};
const LADO=[[82,174],[171,176]],AYUDA=[42,176],PUERTA=[200,180];   // where a cook stands at the left and at the right of the stove; the helper at the left counter; whoever comes in for something
const EN={saco:[38,ENC+10],tazon:[64,ENC+10],platos:[184,ENC+9],basura:[207,ENC+10],jarra:[181,ENC+9],tazas:[195,ENC+9],masa:[38,ENC+9],fuente:[64,ENC+9],apartes:[222,ENC+9]};

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),Wd=RP.wood,E=EST;
  for(let y=0;y<PISO;y++)for(let x=0;x<SW;x++)b.px(x,y,y>PISO-5?"#C8B88A":hs(x>>2,y>>2)<6?"#F0E4B8":"#F6ECC4");
  for(let y=72;y<ENC;y++)for(let x=22;x<SW;x++)b.px(x,y,(x%8===0||y%8===0)?"#B8D0D8":"#E4F0F4");
  for(let y=PISO;y<SH;y++)for(let x=0;x<SW;x++){const ty=Math.floor((y-PISO)/12),tx=Math.floor((x+ty*6)/16);b.px(x,y,((y-PISO)%12===0||(x+ty*6)%16===0)?"#9A6A54":(tx+ty)%2?"#C8745A":"#E8D8B8");}
  for(let x=0;x<SW;x++)b.px(x,PISO-1,"#7A6A4A");
  // a window, a shelf with jars
  b.rect(176,22,38,36,"#9CCBF5");b.ell(204,48,10,9,RP.grn);b.frame(174,20,42,40,Wd[1]);b.frame(175,21,40,38,Wd[3]);b.rect(194,22,2,36,Wd[2]);b.rect(176,39,38,2,Wd[2]);
  b.rect(26,50,50,3,Wd[2]);b.rect(26,53,50,1,Wd[0]);[[58,"#48A848"],[68,"#58B4EC"]].forEach(j=>{b.rect(j[0],40,7,10,j[1]);b.rect(j[0],38,7,2,"#F2F2F8");b.frame(j[0]-1,37,9,14,OUT);});
  // the hood over the stove
  b.rect(96,18,60,18,"#C8C8D4");b.rect(96,18,60,2,"#F2F2F8");b.rect(90,36,72,6,"#9494A6");b.frame(95,17,62,20,OUT);b.frame(89,35,74,8,OUT);
  // the two counters: a cabinet, and a pale top seen a little from above
  [IZQ,DER].forEach(m=>{b.rect(m[0],ENC+12,m[1],PISO+4-ENC-12,Wd[2]);b.rect(m[0],ENC+12,m[1],2,Wd[0]);b.frame(m[0]-1,ENC+11,m[1]+2,PISO+6-ENC-12,OUT);b.rect(m[0]+(m[1]>>1)-1,ENC+15,2,20,Wd[0]);
    b.rect(m[0]-2,ENC,m[1]+4,12,"#E8E8F0");b.rect(m[0]-2,ENC,m[1]+4,2,"#FFFFFF");b.rect(m[0]-2,ENC+10,m[1]+4,2,"#B8B8C8");b.frame(m[0]-3,ENC-1,m[1]+6,14,OUT);});
  // the stove: a top with two burners, a front with two knobs and an oven door
  b.rect(E[0],E[1],E[2],E[3],"#F2F2F8");b.rect(E[0],E[1],E[2],20,"#4A4A58");b.rect(E[0],E[1],E[2],2,"#6A6A7A");b.rect(E[0],E[1]+20,E[2],2,"#C8C8D4");b.frame(E[0]-1,E[1]-1,E[2]+2,E[3]+2,OUT);
  FX.forEach(x=>{b.ell(x,FY-4,15,5,["#2A2A36"]);b.ell(x,FY-4,11,3.4,["#3A3A46"]);});
  b.frame(E[0]+6,E[1]+32,E[2]-12,18,"#B8B8C8");b.rect(E[0]+14,E[1]+35,E[2]-28,2,"#8A8A9A");
  return b.done();}
const COSA={
  // a pot, open at the top: what is in it shows. c: the colours of what is in it, light to dark
  olla(c){const b=new Buf(34,24),C={agua:["#58A8E0","#8CCBF5"],arroz:["#DCDCE8","#FFFFFF"],hab:["#7A2416","#B84A2E"],choco:["#4A220C","#7A3A1A"],vacia:["#2A2A36","#3A3A46"],negra:["#141418","#2A2420"]}[c]||["#2A2A36","#3A3A46"];
    b.rect(4,8,26,14,"#8A8A9A");b.rect(4,8,5,14,"#B8B8C8");b.rect(4,19,26,3,"#5A5A6A");b.rect(1,10,3,4,"#3A3A46");b.rect(30,10,3,4,"#3A3A46");
    b.ell(17,8,13,5,["#5A5A6A","#9494A6","#C8C8D4"]);b.ell(17,8.4,11,3.8,C);
    if(c==="arroz"){[[10,8],[15,7],[20,9],[24,8],[13,10],[19,6]].forEach(q=>b.px(q[0],q[1],"#B8B8C8"));}
    if(c==="hab"){[[10,8],[15,7],[20,9],[24,8],[13,10],[19,6]].forEach(q=>b.rect(q[0],q[1],2,1,"#4A1408"));}
    return b.outline().done();},
  quemada(){const b=new Buf(34,24);[[6,10,3,10],[12,13,2,8],[20,11,4,10],[27,12,2,9]].forEach(q=>b.rect(q[0],q[1],q[2],q[3],"#1A1410"));return b.done();},
  sarten(){const b=new Buf(46,14);b.ell(17,8,15,5,["#1E1E28","#3A3A46","#5A5A6A"]);b.ell(17,7.4,12.6,3.6,["#8A6A20","#C8A040"]);b.rect(31,7,13,3,"#3A2414");b.rect(31,7,13,1,"#5A3A1A");return b.outline().done();},
  saco(v){const b=new Buf(20,22);if(v==="vacio"){b.rect(2,14,16,7,"#D8C8A0");b.rect(2,14,4,7,"#EADCB8");b.rect(2,18,16,3,"#B8A478");b.rect(4,12,13,2,"#B8A478");b.rect(12,10,6,2,"#D8C8A0");return b.outline().done();}b.rect(2,5,16,16,"#D8C8A0");b.rect(2,5,4,16,"#EADCB8");b.rect(2,18,16,3,"#B8A478");b.ell(10,5,7,2.6,["#DCDCE8","#FFFFFF"]);[[6,11],[10,13],[13,10],[8,15],[12,16]].forEach(q=>b.rect(q[0],q[1],2,1,"#FFFFFF"));return b.outline().done();},
  tazon(){const b=new Buf(22,13);b.ell(11,9,8,3.4,["#3A70B0","#5A90D0"]);b.ell(11,5,9.6,4,["#3A70B0","#5A90D0","#8CB8E8"]);b.ell(11,4.6,7.6,2.8,["#7A2416","#B84A2E"]);[[6,4],[10,5],[14,4],[9,3],[13,6]].forEach(q=>b.rect(q[0],q[1],2,1,"#4A1408"));return b.outline().done();},
  medida(c){const b=new Buf(11,10);b.rect(1,3,7,6,"#F0C020");b.rect(1,3,2,6,"#FFE070");b.rect(8,4,2,1,"#F0C020");b.rect(9,5,1,3,"#F0C020");b.rect(2,2,5,2,c==="hab"?"#B84A2E":c==="arroz"?"#FFFFFF":"#C8A018");return b.outline().done();},
  basura(){const b=new Buf(24,13);b.ell(12,9,9,3.4,["#6A6A7A","#9494A6"]);b.ell(12,5,10.6,4,["#6A6A7A","#9494A6","#C8C8D4"]);b.ell(12,4.8,8.6,2.8,["#3A3A46"]);return b.outline().done();},
  monton(c){const b=new Buf(11,7),C=c==="hab"?["#7A2416","#B84A2E"]:c==="negro"?["#141418","#3A3028"]:["#DCDCE8","#FFFFFF"];b.ell(5.5,4,4.4,2.4,C);b.px(3,3,C[0]);b.px(7,5,C[0]);return b.outline().done();},
  plato(){const b=new Buf(15,7);b.ell(7.5,3.5,6.6,2.8,["#B8B8C8","#F2F2F8","#FFFFFF"]);b.ell(7.5,3.2,4,1.5,["#DCDCE8"]);return b.outline().done();},
  espatula(){const b=new Buf(6,16);b.rect(1,1,4,5,"#9494A6");b.rect(2,6,2,9,"#3A2414");return b.outline().done();},
  espumadera(){const b=new Buf(18,8);b.ell(5,4,4,2.6,["#9494A6","#C8C8D4"]);b.px(4,4,"#5A5A6A");b.px(6,3,"#5A5A6A");b.rect(8,3,9,2,"#6A3E1A");return b.outline().done();},
  cucharon(){const b=new Buf(6,18);b.rect(2,1,2,12,"#B07A3C");b.ell(3,14,2.6,3,["#8A5A2A","#B07A3C"]);return b.outline().done();},
  jarra(){const b=new Buf(20,22);b.rect(3,3,12,18,"#E4F4FA");b.rect(3,8,12,13,"#7A3A1A");b.rect(3,3,3,18,"#F8FDFF");[[6,9],[10,8],[12,11]].forEach(q=>{b.rect(q[0],q[1],3,3,"#DCF2FA");b.px(q[0],q[1],"#FFFFFF");});b.rect(15,6,2,1,"#B8D8E8");b.rect(17,7,1,7,"#B8D8E8");b.rect(15,14,2,1,"#B8D8E8");b.rect(1,3,2,2,"#E4F4FA");return b.outline().done();},
  taza(c){const b=new Buf(12,12);b.rect(1,4,7,7,"#F2F2F8");b.rect(1,4,2,7,"#FFFFFF");b.rect(1,10,7,1,"#C8C8D4");b.rect(8,5,2,1,"#F2F2F8");b.rect(10,6,1,3,"#F2F2F8");b.rect(8,9,2,1,"#F2F2F8");b.rect(2,4,5,2,c?"#6A3214":"#C8C8D4");
    if(c==="frio"){b.rect(2,3,3,3,"#58B4EC");b.rect(5,2,3,3,"#A8DCF8");b.px(2,3,"#FFFFFF");b.px(5,2,"#FFFFFF");b.rect(8,0,1,5,"#E0403A");b.rect(7,0,2,1,"#E0403A");}if(c==="cal"){b.rect(3,0,1,3,"#FFFFFF");b.rect(6,1,1,2,"#FFFFFF");}return b.outline().done();},
  fritura(v){if(v==="burbujas"){const g=new Buf(15,9);g.ell(7.5,5,6,3,["#C8A040","#E8C860"]);[[3,4],[6,2],[9,4],[11,6],[5,6],[8,6]].forEach(q=>{g.rect(q[0],q[1],2,2,"#FFF4C0");g.px(q[0],q[1],"#FFFFFF");});return g.done();}const b=new Buf(13,8),C=v==="negra"?["#141418","#2A2420","#3A3028"]:v==="cruda"?["#D8C890","#F0E4B8","#FBF4D8"]:["#B87A20","#E0A838","#F8D070"];b.ell(6.5,4,5,2.8,C);b.px(3,3,C[0]);b.px(9,5,C[0]);b.px(6,2,C[2]);return b.outline().done();},
  masa(n){const b=new Buf(24,10);b.rect(1,6,22,3,"#B07A3C");b.rect(1,6,22,1,"#D09A54");b.outline();[[4,5],[9,5],[14,5],[19,5]].slice(0,n==null?4:+n).forEach(q=>{b.ell(q[0],q[1]-1,2.4,2.2,["#D8C890","#F0E4B8","#FBF4D8"]);b.frame(q[0]-3,q[1]-4,6,6,OUT);});return b.done();},
  fuente(){const b=new Buf(24,9);b.ell(12,5,10.6,3.4,["#B8B8C8","#F2F2F8","#FFFFFF"]);b.ell(12,4.6,7.6,2,["#DCDCE8"]);return b.outline().done();},
  pinzas(){const b=new Buf(6,16);b.rect(1,1,1,13,"#9494A6");b.rect(4,1,1,13,"#C8C8D4");b.rect(1,0,4,2,"#5A5A6A");return b.outline().done();},
  platito(){const b=new Buf(11,6);b.ell(5.5,3,4.6,2.2,["#3A70B0","#F2F2F8","#FFFFFF"]);return b.outline().done();},
  // a drumstick and a fried egg: raw, golden, black
  muslo(v){const b=new Buf(16,10),C=v==="negro"?["#141418","#2A2420","#3A3028"]:v==="crudo"?["#D08A78","#F0B0A0","#FBD0C4"]:["#8A4A14","#C87A28","#E8A848"];b.ell(6,5,5,3.6,C);b.rect(10,4,4,2,v==="negro"?"#2A2420":"#F2EAD8");b.ell(14,4,1.4,1.4,[v==="negro"?"#2A2420":"#F2EAD8"]);b.ell(14,6,1.4,1.4,[v==="negro"?"#2A2420":"#F2EAD8"]);return b.outline().done();},
  frito(v){const b=new Buf(14,9),W1=v==="negro"?["#141418","#2A2420"]:v==="crudo"?["#F2F2F8","#FFFFFF"]:["#E8D8A8","#FFFFFF"];b.ell(7,4.5,5.6,3.4,W1);b.ell(7,4,2.2,1.8,[v==="negro"?"#3A3028":"#E8A020",v==="negro"?"#3A3028":"#FFD040"]);if(v==="dorado"){b.px(2,5,"#B87A28");b.px(11,6,"#B87A28");b.px(4,7,"#B87A28");}return b.outline().done();},
  huevo(){const b=new Buf(8,9);b.ell(4,4.6,2.8,3.6,["#D8C8A8","#F2E8D0","#FFFAEE"]);return b.outline().done();},
  salero(){const b=new Buf(8,12);b.rect(1,4,6,7,"#F2F2F8");b.rect(1,4,2,7,"#FFFFFF");b.rect(1,1,6,3,"#9494A6");b.px(2,2,"#3A3A46");b.px(4,2,"#3A3A46");b.rect(2,7,4,2,"#58B4EC");return b.outline().done();},
  mantelito(){const b=new Buf(34,7);b.rect(1,1,32,5,"#FFFFFF");for(let x=1;x<33;x+=4)b.rect(x,1,2,5,"#E0403A");b.rect(1,3,32,1,"#FFFFFF");return b.outline().done();},
  grano(){const b=new Buf(5,5);b.px(1,1,"#FFFFFF");b.px(3,2,"#FFFFFF");b.px(2,4,"#FFFFFF");b.px(0,3,"#DCDCE8");return b.done();},
  monticulo(){const b=new Buf(9,6);b.ell(4.5,4,3.6,2,["#DCDCE8","#FFFFFF"]);b.px(4,1,"#FFFFFF");b.px(5,2,"#FFFFFF");return b.outline().done();},
  bandeja(){const b=new Buf(46,9);b.rect(1,3,44,5,"#9494A6");b.rect(1,3,44,1,"#C8C8D4");b.rect(2,4,42,3,"#6A6A7A");return b.outline().done();},
  cubo(){const b=new Buf(22,20);b.rect(3,5,16,14,"#5A8A5A");b.rect(3,5,4,14,"#7AAA7A");b.rect(3,16,16,3,"#3A6A3A");b.ell(11,5,8.6,3,["#3A6A3A","#5A8A5A","#9ACA9A"]);b.ell(11,5,6.6,2,["#2A3A2A"]);return b.outline().done();},
  frasco(v){const b=new Buf(14,18);b.rect(1,4,12,13,"#E4F4FA");b.rect(1,4,2,13,"#F8FDFF");if(v!=="vacio"){b.rect(2,7,10,10,"#B84A2E");[[3,8],[7,9],[10,8],[4,12],[8,13],[5,15],[10,15]].forEach(q=>b.rect(q[0],q[1],2,1,"#4A1408"));}b.rect(2,1,10,3,"#9494A6");b.rect(2,1,10,1,"#C8C8D4");return b.outline().done();},
  platoc(v){const b=new Buf(15,9);v=v||"";b.ell(7.5,5.5,6.6,2.8,["#B8B8C8","#F2F2F8","#FFFFFF"]);if(v.includes("a"))b.ell(v.includes("h")?5:7.5,4,3,2,["#B8B8C8","#FFFFFF"]);if(v.includes("h"))b.ell(v.includes("a")?10:7.5,4.4,3,2,["#7A2416","#B84A2E"]);return b.outline().done();},
  fuentec(n){const b=new Buf(24,12);b.ell(12,8,10.6,3.4,["#B8B8C8","#F2F2F8","#FFFFFF"]);[[7,6],[13,5],[17,7],[10,8]].slice(0,n==null?3:+n).forEach(q=>{b.ell(q[0],q[1],3.4,2,["#B87A20","#E0A838","#F8D070"]);});return b.outline().done();},
  platof(){const b=new Buf(13,9);b.ell(6.5,6,5.6,2.4,["#3A70B0","#F2F2F8","#FFFFFF"]);b.ell(6.5,4,3.6,2,["#B87A20","#E0A838","#F8D070"]);return b.outline().done();},
  granon(){const b=new Buf(5,5);b.px(1,1,"#20140A");b.px(3,2,"#20140A");b.px(2,4,"#20140A");b.px(0,3,"#3A3028");return b.done();},
  molinillo(){const b=new Buf(8,13);b.rect(2,4,4,8,"#5A3A1A");b.rect(2,4,1,8,"#8A5A2A");b.ell(4,3,2.6,2.2,["#3A2414","#5A3A1A"]);b.rect(3,0,2,2,"#C8C8D4");return b.outline().done();},
  vasoagua(){const b=new Buf(10,14);b.rect(1,1,8,12,"#DCF2FA");b.rect(1,4,8,9,"#58B4EC");b.rect(1,1,2,12,"#F2FBFF");b.rect(3,3,3,3,"#FFFFFF");b.rect(5,6,3,3,"#E4F6FF");return b.outline().done();},
  cuenco(){const b=new Buf(22,13);b.ell(11,9,8,3.4,["#B84A2E","#D8704A"]);b.ell(11,5,9.6,4,["#B84A2E","#D8704A","#F09A70"]);b.ell(11,4.6,7.6,2.8,["#D8C890","#F0E4B8"]);b.rect(13,0,2,5,"#8A5A2A");return b.outline().done();},
  banco(){const b=new Buf(26,20);b.rect(2,1,22,4,RP.wood[3]);b.rect(2,1,22,1,RP.wood[4]);b.rect(4,5,3,14,RP.wood[1]);b.rect(19,5,3,14,RP.wood[1]);b.rect(5,11,16,2,RP.wood[1]);return b.outline().done();}};
const cosa=(k,c)=>spr("es"+k+(c==null?"":c),()=>(COSA[k]||COSA.plato)(c));
function tenida(c,k,x,y,ang,esc,v){const im=cosa(k,v);if(ang||esc){c.save();c.translate(R(x),R(y));if(ang)c.rotate(ang);if(esc)c.scale(esc,esc);c.drawImage(im,-(im.width>>1),-im.height);c.restore();}else c.drawImage(im,R(x)-(im.width>>1),R(y)-im.height);}
// a flame under a pot, steam over it, smoke from a burnt one
function llama(c,x,a){const t=(F>>2)%2;[[-13,4],[-7,6],[-1,5],[5,6],[11,4]].forEach((q,i)=>{const h=q[1]+((i+t)%2);fr(c,x+q[0],FY+4-h,3,h,"#F08020");fr(c,x+q[0]+1,FY+5-h+1,1,h-2,"#FFE070");});}
function vapor(c,x,y,negro){const t=(F>>2)%6;[[-7,0],[0,-4],[6,-1]].forEach((p,i)=>{const yy=y+p[1]-((t+i*2)%6)*(negro?2:1);fr(c,x+p[0]+((t+i)%3)-1,yy,negro?3:2,negro?4:3,negro?"#3A3A46":"#FFFFFF");});}
function fuego(c,i,a){const f=W.fuegos[i];if(!f||!f.k)return;const x=FX[i];
  if(f.k==="olla"){tenida(c,"olla",x,FY+1,0,0,f.negra&&!f.n?"negra":f.n?f.con:(f.con==="agua"||f.con==="choco"?f.con:"vacia"));if(f.negra)c.drawImage(cosa("quemada"),x-17,FY-23);
    if(f.mal)tenida(c,"monton",x,FY-13,0,0,f.mal);if(f.espuma){const E1=f.espuma==="hab"?"#E8B8A8":"#FFFFFF",Q=[[-20,-17,4,17],[16,-17,4,17],[-27,-2,10,4],[17,-2,10,4],[-14,-21,28,4]];Q.forEach(q=>fr(c,x+q[0]-1,FY+q[1]-1,q[2]+2,q[3]+2,OUT));Q.forEach(q=>fr(c,x+q[0],FY+q[1],q[2],q[3],E1));}if(f.humo)vapor(c,x,FY-26,1);else if(f.vapor&&f.llama)vapor(c,x,FY-22,0);}
  else{tenida(c,"sarten",x+6,FY+1);(f.cosas||[]).forEach((o,j)=>{const px=x+j*12-((f.cosas.length-1)*6);pieza(c,o,px,FY-3);if(o.humo)vapor(c,px,FY-14,1);});if(f.humo)vapor(c,x,FY-14,1);else if(f.vapor)vapor(c,x,FY-14,0);}
  if(f.llama)llama(c,x,a);}
function pieza(c,o,x,y,esc){tenida(c,o.k,x,y,0,esc||0,o.v);const e=esc||1;if(o.sal>=2)tenida(c,"monticulo",x,y-3*e,0,esc||0);}
const alto=id=>{const w=QUIEN[id]||{};return id==="abuela"?51:w.nino?44:56;};
const caja=id=>{const p=W.gente[id];if(!p||p.vis===0)return null;const h=alto(id);return [R(p.x)-11,R(p.y)-h,22,h];};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const COSAS=Object.keys(QUIEN).map(persona).concat([
  {id:"olla0",si:w=>!!(w.fuegos[0]&&w.fuegos[0].k==="olla"),box:[FX[0]-17,FY-24,34,28],m:1,z:1},{id:"olla1",si:w=>!!(w.fuegos[1]&&w.fuegos[1].k==="olla"),box:[FX[1]-17,FY-24,34,28],m:1,z:1},
  {id:"saco",si:w=>!!w.izq.saco,box:[EN.saco[0]-12,EN.saco[1]-16,24,18],m:1,z:1},{id:"tazon",si:w=>!!w.izq.tazon,box:[EN.tazon[0]-12,EN.tazon[1]-16,24,18],m:1,z:1},
  {id:"pzpollo",si:w=>!!w.plata,box:w=>[w.plata.x-24,w.plata.y-22,24,24],m:0,z:3},{id:"pzhuevo",si:w=>!!w.plata,box:w=>[w.plata.x,w.plata.y-22,24,24],m:0,z:3},
  {id:"sarten",si:w=>!!(w.fuegos[0]&&w.fuegos[0].k==="sarten"),box:[FX[0]-17,FY-14,36,16],m:0},{id:"bandeja",si:w=>!!w.izq.bandeja,box:[28,ENC-4,46,16],m:0},
  {id:"jarra",si:w=>!!w.izq.jarra,box:[EN.jarra[0]-11,EN.jarra[1]-22,20,24],m:1,z:2},
  {id:"estufa",box:[EST[0],EST[1]-2,EST[2],EST[3]],m:0},{id:"cocina",box:[22,16,196,198],m:0}]);

/* ---------- drawing ---------- */
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  if(id==="abuela"){const ps=p.pose||"idle",top=y-50+((p.paso&&a%2)?-1:0);c.save();c.translate(x,top);if(d<0)c.scale(-1,1);c.drawImage(spr("ab"+ps+habla,()=>mkAbuela(ps,habla)),-30,0);c.restore();
    if(p.lleva)tenida(c,p.lleva.k||p.lleva,x+d*14,y-17,0,0,p.lleva.v);if(p.bebe)tenida(c,"taza",x+d*8,y-24-(a%2),0,0,p.bebe);if(p.alza)tenida(c,p.alza.k,x+d*(p.alza.dx||18),y-22,0,p.alza.e||2,p.alza.v);if(p.come)tenida(c,p.come.k,x+d*7,y-30+(a%2),0,0,p.come.v);return;}
  const pose=p.pose||"idle",w2=p.cierra?Object.assign({},w,{dormido:1}):w,im=spr("pm"+id+pose+habla+"0"+(p.cierra?"c":""),()=>KIT.mkPersona(w2,pose,habla,0)),top=y-im.height+1+((p.paso&&a%2)?-1:0)+(p.dy||0);
  c.save();c.translate(x,top);if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  if(p.bebe&&id==="mama"){const e=p.bebe===1?"idle":p.bebe,bi=spr("bb"+e+(a%2),()=>KIT.mkBebe(e,a%2));c.drawImage(bi,x+d*2-13+d*8,y-42);}
  if(p.lleva)tenida(c,p.lleva.k||p.lleva,x+d*10,top+(w.nino?34:38),0,0,p.lleva.v);
  if(p.alza){const ax=x+d*13,ay=top+(w.nino?30:34);tenida(c,p.alza.k||p.alza,ax,ay,0,2,p.alza.v);}
  if(p.bebe&&id!=="mama")tenida(c,"taza",x+d*6,top+(w.nino?26:30)-(a%2),0,0,p.bebe);if(p.come)tenida(c,p.come.k,x+d*6,top+22+(a%2),0,0,p.come.v);}
function nube2(g,x,y,o,sal){fr(g,x-1,y-1,28,22,OUT);fr(g,x,y,26,20,"#FFFFFF");fr(g,x+10,y+20,4,4,OUT);fr(g,x+11,y+21,2,2,"#FFFFFF");tenida(g,o.k,x+13,y+18,0,0,o.v);if(sal)tenida(g,"salero",x+19,y+11,0.6);}
function nube(g,x,y,v){fr(g,x-1,y-1,22,20,OUT);fr(g,x,y,20,18,"#FFFFFF");fr(g,x+8,y+18,4,4,OUT);fr(g,x+9,y+19,2,2,"#FFFFFF");tenida(g,"taza",x+10,y+16,0,0,v);if(v==="cal"){const t=(F>>3)%2;fr(g,x+6+t,y+1,1,3,"#B8B8C8");fr(g,x+10-t,y,1,3,"#B8B8C8");}}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui"||q.hace)&&a%2?1:0,dy=R(q.dy),cx=b.x+(b.w>>1);
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.encima)tenida(g,W.encima.k,cx,b.y+dy+3,0,0,W.encima.v);}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{},I=W.izq||{},D=W.der||{};
  c.drawImage(spr("estufa",fondo),0,0);
  if(W.ventana&&W.ventana.length){c.save();c.beginPath();c.rect(176,22,38,36);c.clip();W.ventana.forEach((id,j)=>{const w=QUIEN[id],im=spr("pm"+id+"idle00",()=>KIT.mkPersona(w,"idle",0,0));c.drawImage(im,176+j*12-KIT.PX+7,30+(j%2)*3);if(W.ventanacome)tenida(c,"plato",183+j*12,57);});c.restore();}
  if(W.estante){const v=W.estante===2?"vacio":null;tenida(c,"saco",38,50,0,0,v);tenida(c,"frasco",50,50,0,0,v);}
  fuego(c,0,a);fuego(c,1,a);
  if(W.repisa)tenida(c,"plato",REP[0],REP[1]);
  if(W.olor){const o=W.olor,t=(F>>3)%2;for(let j=0;j<3;j++)for(let i=0;i<7;i++){const u=i/6,xx=o[0]+(o[2]-o[0])*u+j*4-4,yy=o[1]+(o[3]-o[1])*u+((i+t)%2?1:-1);fr(c,R(xx),R(yy),2,2,"#C8A040");}}
  // the left counter
  if(I.llenando){tenida(c,"saco",EN.saco[0]-8,EN.saco[1]-12);tenida(c,"frasco",EN.tazon[0]+8,EN.tazon[1]-12);}
  [["saco","arroz"],["tazon","hab"]].forEach(e=>{const n=I[e[0]]||0,q=EN[e[0]];[[0,-5],[-6,0],[6,0]].slice(0,n).forEach(d=>tenida(c,"medida",q[0]+d[0],q[1]+d[1],0,0,e[1]));});
  if(I.bandeja){const t=I.bandeja;if(t.volcada){fr(c,28,ENC-12,46,20,OUT);fr(c,29,ENC-11,44,18,"#9494A6");fr(c,31,ENC-9,40,14,"#6A6A7A");}else tenida(c,"bandeja",50,ENC+11);for(let i=0;i<t.pollo;i++)tenida(c,"muslo",36+i*8,ENC+8-(i%2),0,0,"crudo");for(let i=0;i<t.huevo;i++)tenida(c,"huevo",58+i*7,ENC+8-(i%2));}
  (D.servidos||[]).forEach((pl,i)=>{const x=183+i*20,y=ENC+10;tenida(c,"plato",x,y,0,2);pl.items.forEach((o,j)=>pieza(c,o,x-6+j*12+(o.aparte?(j?5:-5):0),y-3-(o.aparte?6:0)));});
  if(I.jarra)tenida(c,"jarra",EN.jarra[0],EN.jarra[1]);for(let i=(I.tazas||0)-1;i>=0;i--)tenida(c,"taza",EN.tazas[0]-3+(i%3)*9,EN.tazas[1]-Math.floor(i/3)*6);for(let i=0;i<(I.sucias||0);i++){const sx=ESX+28+i*17;tenida(c,"taza",sx,PISO-22,1.57);fr(c,sx+12,PISO-18,4,2,"#6A3214");fr(c,sx+15,PISO-17,2,1,"#6A3214");}
  // the right counter: plates, the waste bowl and what lies in it
  (D.platos||[]).forEach((p,i)=>{const x=EN.platos[0]-8+i*13,y=EN.platos[1]+(i%2);tenida(c,"plato",x,y);if(p.arroz)tenida(c,"monton",x-2,y-2,0,0,p.negro==="arroz"?"negro":"arroz");if(p.hab)tenida(c,"monton",x+3,y-1,0,0,p.negrohab?"negro":"hab");});
  for(let i=0;i<(D.pila||0);i++)tenida(c,"plato",EN.platos[0]+12,EN.platos[1]-9-i*2);if(D.platito)tenida(c,"platito",EN.platos[0]-10,EN.platos[1]-10);

  if(D.masa!=null)tenida(c,"masa",EN.masa[0],EN.masa[1],0,0,D.masa);if(D.fuente){tenida(c,"fuente",EN.fuente[0],EN.fuente[1]);(D.frituras||[]).forEach((v,i)=>tenida(c,"fritura",EN.fuente[0]-6+i*6,EN.fuente[1]-3-(i%2),0,0,v));}

  const L=[];
  if(W.cubo)L.push({y:CUBO[1]+1,d:()=>{tenida(c,"cubo",CUBO[0],CUBO[1]);(W.basura||[]).forEach((k,i)=>tenida(c,"monton",CUBO[0]-4+i*5,CUBO[1]-13-i*2,0,0,k));}});
  if(W.banco)L.push({y:BANCO[1]+1,d:()=>tenida(c,"banco",BANCO[0],BANCO[1]+18)});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.y,d:()=>gente(c,id,a)});});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>{tenida(c,o.k,o.x,o.y,o.rot,0,o.v);if(o.vapor)vapor(c,o.x-1,o.y-15,0);}});});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  if(W.plata){const P=W.plata;tenida(c,"plato",P.x,P.y,0,3);P.items.forEach((o,j)=>pieza(c,o,P.solo?P.x:P.x-11+j*22,P.y-6,2));}
  if(W.mat){tenida(c,"platito",W.mat.x,W.mat.y,0,2);if(W.mat.o)pieza(c,W.mat.o,W.mat.x,W.mat.y-4);}
  if(W.salero)tenida(c,"salero",SALX,FY+6);
  (W.vuelos||[]).forEach(o=>tenida(c,o.k,o.x,o.y,o.rot,0,o.v));
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.piensa&&p.vis!==0){if(p.piensa.k)nube2(c,R(p.x)-14+(p.piensa.dx||0),R(p.y)-alto(id)-26,p.piensa,p.piensa.sal);else nube(c,R(p.x)-14,R(p.y)-alto(id)-24-(p.sube?22:0),p.piensa);}});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1];}
function respIcon(g,k,x,y,w,h,a){g.imageSmoothingEnabled=false;if(k==="espera"){KIT.mano(g,x+(w>>1)-14,y+(h>>1)-9);KIT.mano(g,x+(w>>1)+1,y+(h>>1)-9);}else if(k==="salpollo"||k==="salhuevo"){tenida(g,k==="salpollo"?"muslo":"frito",x+(w>>1)-2,y+h-3,0,2,"dorado");tenida(g,"salero",x+(w>>1)+8,y+h-14,0.7,2);}else if(k==="saca"){tenida(g,"pinzas",x+(w>>1)-4,y+h-8,0.5,2);tenida(g,"fritura",x+(w>>1)+6,y+h-4,0,2,"dorada");}}
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,66,24);   // the card steps aside while three picture bubbles stand at the top
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m){g.fillStyle=OUT;for(let k=0;k<11;k++){g.fillRect(x+k,y+1+k,4,3);g.fillRect(x+10-k,y+1+k,4,3);}g.fillStyle="#C8401E";for(let k=0;k<11;k++){g.fillRect(x+1+k,y+2+k,2,1);g.fillRect(x+11-k,y+2+k,2,1);}}
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}
const marca=m=>{const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;};


/* ---------- moving things ---------- */
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/6));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;}
async function vuela(o,x0,y0,x1,y1,n){const v=Object.assign({x:x0,y:y0},o);W.vuelos.push(v);n=n||5;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(x1-x0)*t;v.y=y0+(y1-y0)*t-Math.sin(t*Math.PI)*8;await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);}
async function vuela(o,x0,y0,x1,y1,n){const v=Object.assign({x:x0,y:y0},o);W.vuelos.push(v);n=n||5;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(x1-x0)*t;v.y=y0+(y1-y0)*t-Math.sin(t*Math.PI)*10;await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);}
const cx=()=>W.cq.x+16,pies=()=>W.cq.y+27;
async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(3,R(d/40))));}
async function cae28(x,y){const v={k:"salero",x:x+4,y:y-4,rot:0.7};W.vuelos.push(v);for(let i=0;i<3;i++){const g={k:"grano",x:x-2+i*2,y:y+i*2};W.vuelos.push(g);await wait(110);W.vuelos.splice(W.vuelos.indexOf(g),1);}SFX.blip();await wait(150);W.vuelos.splice(W.vuelos.indexOf(v),1);}
const alBanco=()=>ranaA(BANCO[0],BANCO[1]);
const corre=(o,pr)=>{if(o&&o.suelto){W._mov=pr;return Promise.resolve();}return pr;};
const olla=a=>a==="abuela"?1:a==="luis"?0:+String(a).replace("olla","");   // which burner: by its cook, or by its name
const cocinero=i=>i?"abuela":"luis";
const pz=k=>{k=String(k||"").replace(/^di_|^pz|^sal/,"");return k==="pollo"||k==="muslo"?"muslo":"frito";};
const clase=k=>{k=String(k||"").replace(/^di_/,"");return k==="saco"||k==="arroz"?"arroz":"hab";};
// a cup of rice or of beans goes into a pot. If the pot cooks the other thing, it lies on top and has to come out again
function cae(i,k){const f=W.fuegos[i];if(!f.n||f.con===k){f.con=k;f.n=Math.min(3,(f.n||0)+1);f.mal=null;SFX.blip();return 0;}f.mal=k;SFX.bonk();return 1;}
function caeAgua(i,k){const f=W.fuegos[i];if(f.con==="agua"||f.con===k)return cae(i,k);return cae(i,k);}
const acts={
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async ya(){const p=W._mov;W._mov=null;if(p)await p;},
  async g(o){const p=G(o.quien);if(!p)return;Object.keys(o).forEach(k=>{if(!["act","quien","ms"].includes(k))p[k]=o[k]===""?null:o[k];});if(o.ms)await wait(+o.ms);},

  /* ----- story 27: Arroz con habichuelas ----- */
  // Three cups of rice and three of beans for three plates: one cup is one plate's worth. W.fuegos[i].n is how many cups are in the pot.
  async inicio27(){W.gente={abuela:{x:LADO[1][0],y:LADO[1][1],dir:-1},luis:{x:LADO[0][0],y:LADO[0][1],dir:1},carmen:{x:AYUDA[0],y:AYUDA[1],dir:1},abuelo:{vis:0},mama:{vis:0},papa:{vis:0}};
    W.fuegos=[{k:"olla",con:"agua",n:0,llama:1,vapor:1},{k:"olla",con:"agua",n:0,llama:1,vapor:1}];W.izq={saco:3,tazon:3};W.der={platos:[],pila:6,platito:1};W.cubo=1;W.basura=[];W.ventana=[];W.estante=1;V.fa="";},
  async nota(o){V[o.k]=o.v==null?"1":String(o.v);},
  // the frog tips a cup of rice or of beans into a cook's pot
  async echa(o){const k=clase(o.k),i=olla(o.a),key=k==="arroz"?"saco":"tazon",e=EN[key];const pr=(async()=>{await ranaA(e[0]+6,186);if(W.izq[key])W.izq[key]--;W.encima={k:"medida",v:k};SFX.blip();await ranaA(FX[i],190);await wait(100);W.encima=null;await vuela({k:"medida",v:k},FX[i],165,FX[i],FY-18,5);V.mal=cae(i,k)?"1":"";await wait(250);await alBanco();})();return corre(o,pr);},
  // Carmen tips one in
  async carmenecha(o){const k=clase(o.k),i=olla(o.a),c=G("carmen"),key=k==="arroz"?"saco":"tazon",e=EN[key];if(!W.izq[key])return;const pr=(async()=>{await mueve("carmen",e[0]+4,AYUDA[1]);W.izq[key]--;c.lleva={k:"medida",v:k};SFX.blip();await mueve("carmen",FX[i]-(i?10:22),AYUDA[1]+8);await wait(100);c.lleva=null;await vuela({k:"medida",v:k},c.x+8,c.y-30,FX[i],FY-18,5);V.mal=cae(i,k)?"1":"";await wait(250);await mueve("carmen",AYUDA[0],AYUDA[1]);c.dir=1;})();return corre(o,pr);},
  // each cook tips in the last cup of his own thing, if one is left
  async ultimas27(){for(const i of [0,1]){const f=W.fuegos[i],key=f.con==="arroz"?"saco":"tazon";while(f.n&&f.n<3&&W.izq[key]>0){W.izq[key]--;await vuela({k:"medida",v:f.con},EN[key][0],EN[key][1]-8,FX[i],FY-18,6);cae(i,f.con);await wait(150);}}},
  // the cook shakes his head and lifts out what does not belong in his pot, into the waste bucket
  async saca(o){const i=olla(o.a),f=W.fuegos[i],k=f.mal||(f.n?f.con:null);if(!k)return;const id=cocinero(i),p=G(id);for(const d of [-1,1,-1,1]){p.dir=d;await wait(150);}p.dir=i?-1:1;p.lleva="espumadera";await wait(350);if(f.mal)f.mal=null;else{f.n=0;f.con="agua";}await vuela({k:"monton",v:k},FX[i],FY-16,CUBO[0],CUBO[1]-14,9);W.basura.push(k);p.lleva=null;SFX.bonk();await wait(400);},
  async cuchara(o){const p=G(o.a);const pr=(async()=>{p.lleva="cucharon";await wait(+(o.ms||900));p.lleva=null;})();return corre(o,pr);},
  // a cook holds an empty cup up: his pot wants more
  async pide(o){const p=G(o.a);p.alza=o.no?null:{k:"medida"};if(!o.no)SFX.blip();await wait(250);},
  // abuela, Luis and Carmen go to the right counter and set three plates out; only the frog is at the stove. vuelve: they come back
  async platos27(o){const ab=G("abuela"),l=G("luis"),ca=G("carmen");if(o.vuelve){await Promise.all([mueve("abuela",LADO[1][0],LADO[1][1]),mueve("luis",LADO[0][0],LADO[0][1]),mueve("carmen",AYUDA[0],AYUDA[1])]);ab.dir=-1;l.dir=1;ca.dir=1;return;}
    await Promise.all([mueve("abuela",EN.platos[0]+4,LADO[1][1]+4),mueve("luis",EN.platos[0]-16,LADO[1][1]+12),mueve("carmen",EN.platos[0]+22,LADO[1][1]+12)]);ab.dir=1;l.dir=1;ca.dir=-1;while(W.der.platos.length<3&&W.der.pila>0){W.der.pila--;W.der.platos.push({});SFX.blip();await wait(180);}},
  // the flame under a pot goes out, or is lit again; a pot that stays on after it is ready boils over: foam down the stove, its flame out, a cup's worth gone
  async apaga(o){const i=olla(o.a);W.fuegos[i].llama=0;SFX.blip();await wait(350);},
  async enciende(o){const i=olla(o.a);W.fuegos[i].llama=1;SFX.blip();await wait(300);},
  async derrama(o){const i=olla(o.a),f=W.fuegos[i],q=W.cq;await wait(400);f.espuma=f.con;SFX.bonk();q.dy=4;await wait(700);f.n=Math.max(0,f.n-1);await wait(400);q.dy=0;},
  // one pot of water goes on the stove, at its cook's burner
  async unaolla(o){const i=olla(o.a);W.fuegos[i]={k:"olla",con:"agua",n:0,llama:1,vapor:1};SFX.blip();await wait(300);},
  // the plates are filled: one cup's worth of each on a plate, as far as the pots go; from a burnt pot the food is black
  async sirve27(o){const ab=G("abuela"),P=W.der.platos;await acts.platos27({});ab.dir=-1;ab.lleva="cucharon";
    for(const i of [0,1]){const f=W.fuegos[i];if(!f.n)continue;const arroz=f.con==="arroz";for(const j of (arroz?[0,2,1]:[1,2,0])){if(!f.n||!P[j])continue;f.n--;await vuela({k:"monton",v:f.con},FX[i],FY-16,EN.platos[0]-8+j*13,EN.platos[1]-6,4);if(arroz)P[j].arroz=1;else P[j].hab=1;SFX.blip();}}
    ab.lleva=null;ab.dir=1;W.fuegos.forEach(f=>{f.n=0;f.con="vacia";f.llama=0;});await wait(300);},
  // the family looks in at the window; Carmen hands the plates out, and they eat there
  async familia27(){W.ventana=["abuelo","mama","papa"];SFX.blip();await wait(500);},
  async ventana27(o){const c=G("carmen");const pr=(async()=>{await mueve("carmen",EN.platos[0]-18,AYUDA[1]+10);c.lleva="plato";W.der.platos=[];SFX.blip();await wait(300);c.lleva=null;W.ventanacome=1;SFX.blip();await wait(1200);await mueve("carmen",AYUDA[0],AYUDA[1]);c.dir=1;})();return corre(o,pr);},
  // the pots come off; Carmen fills three cups from the sack of rice and three from the jar of beans
  async otravez27(){W.ventana=[];W.ventanacome=0;await acts.platos27({vuelve:1});W.fuegos=[{},{}];const c=G("carmen");await mueve("carmen",46,AYUDA[1]-2);c.pose="wave0";await wait(300);W.estante=0;W.izq.llenando=1;c.pose="idle";SFX.blip();await wait(400);for(const k of ["saco","tazon"])for(let i=1;i<=3;i++){W.izq[k]=i;SFX.blip();await wait(160);}c.pose="wave0";await wait(250);W.izq.llenando=0;W.estante=2;c.pose="idle";await mueve("carmen",AYUDA[0],AYUDA[1]);c.dir=1;await wait(300);},
  // the plates are in their hands: Luis's is the left one, abuela's the middle one, Carmen's the right one. Whoever has a short plate looks into it first
  async final27(o){const pr=(async()=>{const D=W.der,ids=["luis","abuela","carmen"],pl=D.platos.slice(),lleno=q=>q&&q.arroz&&q.hab;D.platos=[];await Promise.all([mueve("luis",157,202),mueve("carmen",208,202)]);G("luis").dir=1;G("carmen").dir=-1;G("abuela").dir=-1;
    ids.forEach((id,j)=>{const q=pl[j]||{};G(id).alza={k:"platoc",v:(q.arroz?"a":"")+(q.hab?"h":""),e:2,dx:16};});SFX.blip();await wait(pl.every(lleno)?300:1100);
    ids.forEach((id,j)=>{const q=pl[j]||{};if(q.arroz||q.hab)G(id).come={k:"monton",v:q.arroz?"arroz":"hab"};});
    if(!W.lost){D.platito=0;W.cosas.push({k:"platito",x:cx()-24,y:pies()+4});W.cosas.push({k:"monton",v:"arroz",x:cx()-26,y:pies()+2});W.cosas.push({k:"monton",v:"hab",x:cx()-21,y:pies()+3});W.cq.hace="come";SFX.blip();}await wait(1500);ids.forEach(id=>G(id).come=null);})();return corre(o,pr);},

  /* ----- story 28: El pollo y el huevo ----- */
  // Abuela and the wide pan are on the left, with the tray; mamá and the baby stand beside her. Luis and Carmen eat at the right counter. Pieces are fried two at a time, a drumstick and an egg. The shaker stands on the edge of the stove.
  async inicio28(){W.gente={abuela:{x:LADO[0][0],y:LADO[0][1],dir:1},mama:{vis:0,bebe:1},luis:{vis:0},carmen:{vis:0},abuelo:{vis:0},papa:{vis:0}};
    W.fuegos=[{k:"sarten",llama:1,cosas:[{k:"muslo",v:"crudo",sal:0},{k:"frito",v:"crudo",sal:0}]},{k:"olla",con:"arroz",n:2,llama:0}];W.izq={bandeja:{pollo:3,huevo:3}};W.der={servidos:[{de:"luis",items:[]},{de:"carmen",items:[]}]};W.mat={x:BANCO[0]+30,y:BANCO[1]+24,o:null};W.plata=null;W.salero=1;W.repisa=1;},
  // the frog takes the shaker, or puts it back
  async toma28(o){const pr=(async()=>{if(o.deja){W.encima=null;await vuela({k:"salero"},cx(),pies()-24,SALX,FY+6,5);W.salero=1;SFX.blip();return;}W.salero=0;await vuela({k:"salero"},SALX,FY+6,cx(),pies()-24,5);W.encima={k:"salero"};SFX.blip();})();return corre(o,pr);},
  // the frog shakes salt over the drumstick or the egg in the pan
  async sala(o){const k=pz(o.k),f=W.fuegos[0],j=f.cosas.findIndex(c=>c.k===k),px=FX[0]+j*12-6;const pr=(async()=>{W.encima=null;await vuela({k:"salero"},cx(),pies()-24,px+4,FY-18,5);await cae28(px,FY-12);await cae28(px,FY-12);f.cosas[j].sal=(f.cosas[j].sal||0)+1;W.encima={k:"salero"};})();return corre(o,pr);},
  async entramama(){const m=G("mama");m.vis=1;m.x=20;m.y=LADO[0][1]+6;await mueve("mama",AYUDA[0]-2,LADO[0][1]+6);m.dir=1;},
  // abuela turns to the baby; her back is to the pan
  async mira28(){const ab=G("abuela"),m=G("mama");ab.dir=-1;m.bebe="clap";await wait(400);},
  async humo(o){const k=pz(o.k),c=W.fuegos[0].cosas.find(c=>c.k===k);c.humo=1;SFX.blip();await wait(400);},
  // she turns round: by now the smoke hangs over the whole pan. She turns the piece he called: golden if it was the one that smoked, and then the smoke clears
  async voltea(o){const ab=G("abuela"),f=W.fuegos[0],ks=o.k==="los dos"?["muslo","frito"]:[pz(o.k)];if(o.vuelta){ab.dir=1;G("mama").bebe=1;if(f.cosas.some(c=>c.humo)){f.humo=1;await wait(350);}}ab.lleva="espatula";for(const k of ks){const c=f.cosas.find(c=>c.k===k);await wait(250);if(c.v!=="negro")c.v="dorado";c.humo=0;SFX.blip();}await wait(250);ab.lleva=null;if(!f.cosas.some(c=>c.humo))f.humo=0;},
  async quema28(o){const f=W.fuegos[0],c=f.cosas.find(c=>c.k===pz(o.k)),ab=G("abuela");await wait(500);ab.lleva="espatula";await wait(400);c.v="negro";c.humo=0;f.humo=0;SFX.bonk();await wait(300);ab.lleva=null;await wait(300);},
  // a new pair from the tray goes into the pan, and abuela shakes salt over the pan. sinsal: that piece got none, and nobody can see it
  async par(o){const t=W.izq.bandeja,f=W.fuegos[0],ab=G("abuela");ab.dir=1;G("mama").bebe=1;f.cosas=[];t.pollo--;await vuela({k:"muslo",v:"crudo"},40,ENC+4,FX[0]-6,FY-6,5);f.cosas.push({k:"muslo",v:"crudo",sal:0});SFX.blip();t.huevo--;await vuela({k:"huevo"},60,ENC+4,FX[0]+6,FY-6,5);f.cosas.push({k:"frito",v:"crudo",sal:0});SFX.blip();await wait(250);
    W.salero=0;await vuela({k:"salero"},SALX,FY+6,FX[0],FY-18,4);await cae28(FX[0]-4,FY-12);f.cosas.forEach(c=>c.sal=o&&o.sinsal&&pz(o.sinsal)===c.k?0:1);await vuela({k:"salero"},FX[0],FY-18,SALX,FY+6,4);W.salero=1;await wait(200);},
  // the pair goes onto somebody's plate at the right counter; he eats what is good and leaves what is black or too salty
  async sirve28(o){const f=W.fuegos[0],its=f.cosas.map(c=>({k:c.k,v:c.v,sal:c.sal})),i=W.der.servidos.findIndex(s=>s.de===o.a);f.cosas=[];await vuela({k:"plato"},FX[0],FY-8,183+i*20,ENC+6,7);W.der.servidos[i].items=its;SFX.blip();await wait(250);},
  async come28(o){const p=G(o.a),pl=W.der.servidos.find(s=>s.de===o.a);if(!pl)return;for(const it of pl.items.slice()){if(it.v==="negro"||it.sal>=2)continue;p.come={k:it.k,v:it.v};pl.items.splice(pl.items.indexOf(it),1);SFX.blip();await wait(600);p.come=null;}await wait(200);},
  async muerde(o){const p=G(o.a);for(const k of ["muslo","frito"]){p.come={k,v:"dorado"};await wait(350);p.come=null;await wait(150);}},
  // the frog salts a piece on somebody's plate: a second helping is a white heap
  async salplato(o){const k=pz(o.k),i=W.der.servidos.findIndex(s=>s.de===o.a),pl=W.der.servidos[i],it=pl.items.find(c=>c.k===k),j=pl.items.indexOf(it),px=183+i*20-6+j*12;if(W.salero){W.salero=0;await vuela({k:"salero"},SALX,FY+6,cx(),pies()-24,5);}W.encima=null;await ranaA(px-18,196);await vuela({k:"salero"},cx(),pies()-24,px+4,ENC-6,5);await cae28(px,ENC+2);it.sal=(it.sal||0)+1;await alBanco();await vuela({k:"salero"},cx(),pies()-24,SALX,FY+6,5);W.salero=1;},
  async cara(o){const p=G(o.a),pl=W.der.servidos.find(s=>s.de===o.a),it=pl&&pl.items.find(c=>c.sal>=2||c.v==="negro");if(!it)return;await wait(300);p.pose="wave0";p.dy=-2;SFX.bonk();await wait(500);it.aparte=1;await wait(500);p.pose="idle";p.dy=0;},
  async piensa28(o){const k=pz(o.k),p=o.quien==="bebe"?G("mama"):G(o.quien);p.piensa=o.k?{k,v:"dorado",sal:o.quien!=="bebe",dx:o.quien==="bebe"?12:0}:null;if(o.k)SFX.blip();await wait(250);},
  // Luis and Carmen run in to the right counter
  async entran28(){["luis","carmen"].forEach((id,j)=>{const p=G(id);p.vis=1;p.x=236;p.y=LADO[1][1]+4+j*8;});await Promise.all([mueve("luis",180,LADO[1][1]+4),mueve("carmen",200,LADO[1][1]+12)]);G("luis").dir=-1;G("carmen").dir=-1;},
  // abuela holds both pieces out on a plate; the baby waves its arms at it
  async platobebe(){const f=W.fuegos[0],ab=G("abuela");ab.dir=1;W.repisa=0;W.plata={x:BANCO[0]-2,y:PISO+10,items:f.cosas.map(c=>({k:c.k,v:c.v,sal:c.sal}))};f.cosas=[];G("mama").bebe="clap";SFX.blip();await wait(400);},
  // the frog takes a piece from that plate to the baby: it eats it, or throws it on the floor
  async dabebe(o){const k=pz(o.k),P=W.plata,m=G("mama"),it=P.items.find(c=>c.k===k);if(!it)return;P.items.splice(P.items.indexOf(it),1);await vuela({k:it.k,v:it.v},P.x,P.y-8,m.x+12,m.y-36,7);
    if(o.tira){m.bebe="llora";SFX.bonk();await vuela({k:it.k,v:it.v},m.x+12,m.y-36,m.x+26,PISO+30,6);W.cosas.push({k:it.k,v:it.v,x:m.x+26,y:PISO+30});await wait(500);m.bebe="clap";return;}
    m.bebe="come";SFX.blip();await wait(800);m.bebe=P.items.length?"clap":1;},
  async madrecome(){const m=G("mama");W.plata=null;W.repisa=1;m.bebe=1;await wait(300);},
  // the tray is empty: she tips it towards us
  async vacia28(){const ab=G("abuela");ab.dir=1;W.izq.bandeja.volcada=1;SFX.blip();await wait(500);},
  async ultimo(){await acts.voltea({k:"los dos"});await acts.platobebe();},
  // the other piece of the last pair is the frog's
  async parami(o){const P=W.plata;const pr=(async()=>{const it=P.items[0];if(it){P.items=[];await vuela({k:it.k,v:it.v},P.x,P.y-8,W.mat.x,W.mat.y-4,6);W.mat.o=it;SFX.blip();}W.plata=null;W.repisa=1;await wait(300);})();return corre(o,pr);},
  async final28(){W.plata=null;W.repisa=1;G("mama").bebe="come";G("abuela").dir=1;W.encima=null;if(!W.lost&&W.mat.o)W.cq.hace="come";SFX.blip();await wait(600);},

  /* ----- story 29: ¡Cuidado! ----- */
  // Abuela, the pan, the board of batter and the fritter plate are on the left; Luis, the pot of hot chocolate, the jug of cold chocolate and the cups are on the right, where people come in.
  async inicio29(){W.gente={abuela:{x:LADO[0][0],y:LADO[0][1],dir:1},luis:{x:LADO[1][0]+4,y:LADO[1][1],dir:1},carmen:{vis:0},abuelo:{vis:0},mama:{vis:0},papa:{vis:0}};
    W.fuegos=[{k:"sarten",llama:1,cosas:[]},{k:"olla",con:"choco",n:2,llama:1,vapor:1}];W.izq={jarra:1,tazas:9,sucias:0};W.der={masa:4,fuente:1,frituras:[]};},
  // somebody comes in at the door and stands at the right; lugar 2: a second one beside him
  async viene(o){const p=G(o.quien),x=o.lugar==2?209:196,y=PUERTA[1]+(o.lugar==2?14:6);p.bebe=null;p.piensa=null;p.sube=o.lugar==2?1:0;p.vis=1;p.x=236;p.y=y;const pr=(async()=>{await mueve(o.quien,x,y);p.dir=-1;})();return corre(o,pr);},
  // whoever has his cup goes out with it
  async aparte(o){for(const id of String(o.quien).split(",")){const p=G(id);p.piensa=null;await wait(300);await mueve(id,238,p.y);p.vis=0;p.bebe=null;}},
  async piensa(o){G(o.quien).piensa=o.k||null;if(o.k)SFX.blip();await wait(250);},
  // Luis gives the frog a clean cup; the frog fills it at the pot or at the jug and carries it over
  async copa(){const l=G("luis");if(W.izq.tazas)W.izq.tazas--;l.lleva={k:"taza"};SFX.blip();await wait(250);l.lleva=null;await vuela({k:"taza"},l.x+8,l.y-24,cx(),pies()-24,5);W.encima={k:"taza"};},
  async ranallena(o){const k=["olla1","cal","di_cal"].includes(o.k)?"cal":"frio",p=G(o.a);const pr=(async()=>{if(!W.encima)await acts.copa();if(k==="cal"){await ranaA(FX[1],192);const cu={k:"cucharon",x:FX[1]+9,y:FY-5,z:999};W.cosas.push(cu);await wait(450);W.cosas.splice(W.cosas.indexOf(cu),1);}else{await ranaA(EN.jarra[0]-4,192);await wait(150);}W.encima={k:"taza",v:k};SFX.blip();await wait(250);await ranaA(p.x-22,p.y+8);await wait(100);W.encima=null;p.bebe=k;SFX.blip();await wait(200);await alBanco();})();return corre(o,pr);},
  // Luis fills a clean cup himself, and hands it over
  async llena(o){const l=G("luis"),k=["olla1","cal","di_cal"].includes(o.k)?"cal":"frio";if(W.izq.tazas)W.izq.tazas--;l.lleva={k:"taza",v:k};SFX.blip();await wait(350);V.taza=k;},
  async luisda(o){const l=G("luis"),p=G(o.a),k=V.taza;const pr=(async()=>{await mueve("luis",p.x-20,p.y+2);await wait(100);l.lleva=null;p.bebe=k;SFX.blip();await wait(200);if(!o.queda){await mueve("luis",LADO[1][0]+4,LADO[1][1]);l.dir=1;}})();return corre(o,pr);},
  // the cup is not the one he wanted: he shakes his head; Luis takes it, drinks it himself, and lays the empty cup on its side
  async niega(o){const p=G(o.a);for(const d of [1,-1,1,-1]){p.dir=d;await wait(170);}},
  async luisbebe(o){const l=G("luis"),p=G(o.a),k=p.bebe;if(Math.hypot(l.x-p.x,l.y-p.y)>30)await mueve("luis",p.x-20,p.y+2);p.bebe=null;l.bebe=k;SFX.blip();await wait(900);l.bebe=null;await mueve("luis",LADO[1][0]+4,LADO[1][1]);l.dir=1;W.izq.sucias=(W.izq.sucias||0)+1;SFX.bonk();await wait(300);},
  // abuela drops a ball of batter into the pan; the oil bubbles over it, and it fries a moment; she looks in
  async frie(){const f=W.fuegos[0],ab=G("abuela");ab.dir=1;if(W.der.masa>0)W.der.masa--;await vuela({k:"fritura",v:"cruda"},EN.masa[0],EN.masa[1]-8,FX[0],FY-8,5);f.cosas=[{k:"fritura",v:"cruda"}];SFX.blip();await wait(350);f.cosas[0].v="burbujas";await wait(600);},
  async asoma(){const ab=G("abuela");ab.dir=1;ab.paso=1;await wait(450);ab.paso=0;await wait(150);},
  // she turns away to wipe the plate, her back to the pan
  async limpia(){G("abuela").dir=-1;await wait(300);},
  async dora(){await wait(700);},
  // the frog lifts the fritter out, golden, onto the plate; or, too soon, it is pale and soft and falls on the floor beside the stove
  async saca29(o){const f=W.fuegos[0];W.cq.dy=-4;await wait(120);W.cq.dy=0;f.cosas=[];
    if(o.cae){await vuela({k:"fritura",v:"cruda"},FX[0],FY-10,FX[0]-4,PISO+34,7);W.cosas.push({id:"caida",k:"fritura",v:"cruda",x:FX[0]-4,y:PISO+34});SFX.bonk();await wait(400);return;}
    await vuela({k:"fritura",v:"dorada"},FX[0],FY-10,EN.fuente[0],EN.fuente[1]-6,6);W.der.frituras.push("dorada");SFX.blip();await wait(250);},
  // too long: smoke; abuela turns round and lifts a black fritter out onto the edge of the stove
  async quema29(){const f=W.fuegos[0],ab=G("abuela");await wait(500);f.humo=1;SFX.bonk();await wait(600);ab.dir=1;await wait(300);f.humo=0;f.cosas=[];W.cosas.push({id:"negra",k:"fritura",v:"negra",x:FX[0]+20,y:FY+6,z:0});await wait(300);},
  async resto29(){G("abuela").dir=1;while(W.der.masa>0){await acts.frie();await acts.saca29({});}},
  // the turn: Luis crosses to the plate, takes the first fritter and eats it
  async luiscome(){const l=G("luis");await mueve("luis",EN.fuente[0]+18,LADO[0][1]+16);W.der.frituras.pop();l.come={k:"fritura",v:"dorada"};SFX.blip();await wait(800);l.come=null;SFX.blip();await wait(300);await mueve("luis",LADO[1][0]+4,LADO[1][1]);l.dir=1;},
  // the ending: Carmen and abuela take a fritter each; the third, if there is one, is the frog's. A clean cup for abuela, and one for the frog, as far as they go
  async final29(){const ab=G("abuela"),ca=G("carmen"),D=W.der;ab.dir=1;
    if(D.frituras.length){D.frituras.pop();ca.come={k:"fritura",v:"dorada"};SFX.blip();await wait(250);}if(D.frituras.length){D.frituras.pop();ab.lleva={k:"fritura",v:"dorada"};SFX.blip();await wait(250);}
    if(D.frituras.length){D.frituras.pop();W.cosas.push({k:"fritura",v:"dorada",x:cx()+22,y:pies()+4});W.cq.hace="come";SFX.blip();await wait(250);}
    if(W.izq.tazas>0){W.izq.tazas--;ab.bebe="cal";SFX.blip();await wait(250);}
    if(W.izq.tazas>0){W.izq.tazas--;W.cosas.push({k:"taza",v:"cal",x:cx()-22,y:pies()+4});SFX.blip();}await wait(700);},

  // everything at once, to look at the drawing
  async prueba(o){const n=+(o&&o.n||1);
    W.gente={abuela:{x:LADO[1][0],y:LADO[1][1],dir:-1},luis:{x:LADO[0][0],y:LADO[0][1],dir:1},carmen:{x:AYUDA[0],y:AYUDA[1],dir:1,lleva:{k:"medida",v:"arroz"}},papa:{x:PUERTA[0],y:PUERTA[1]+6,dir:-1,vis:n===2?1:0}};
    W.fuegos=n===1?[{k:"olla",con:"arroz",n:2,llama:1,vapor:1},{k:"olla",con:"hab",n:1,llama:1,humo:1,negra:1}]:n===2?[{k:"olla",con:"agua",n:0,llama:1,vapor:1},{k:"olla",con:"vacia",n:0,llama:0}]:[{k:"sarten",llama:1,cosas:[]},{k:"olla",con:"choco",n:2,llama:1,vapor:1}];
    W.izq=n===3?{jarra:1,tazas:9,sucias:2}:{saco:3,tazon:2};W.ventana=n===2?["abuelo","mama","papa"]:[];W.ventanacome=1;W.der={platos:n===1?[{arroz:1,hab:1},{arroz:1},{}]:[{},{},{}],pila:3,platito:1,masa:n===3?3:null,fuente:n===3?1:0,frituras:n===3?["dorada","dorada"]:[]};W.basura=n===1?["hab","arroz"]:[];
    W.cubo=1;W.banco=1;Object.assign(W.cq,{x:BANCO[0]-16,y:BANCO[1]-27,s:1});W.encima=n===2?{k:"medida",v:"hab"}:null;W.tarjeta="rondas";W.marcas=["ok","x",null];},
};
async function stake(lost,max,en){await wait(200);}
function poke(what){}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)).join(" ")+" fuegos="+(W.fuegos||[]).map(f=>f&&f.k?f.k+":"+(f.con||"")+f.n+(f.llama?"*":"")+(f.negra?"#":""):"-").join("|")+" basura="+(W.basura||[]).join("+")+" marcas="+(W.marcas||[]).join(",");
KIT.escena({id:"estufa",CAM:{wide:[22,0,196,216]},heartAt:[124,24],lugar:{inicio:[BANCO[0]-16,BANCO[1]-27,1],centro:[BANCO[0]-16,BANCO[1]-27,1]},cosas:COSAS,
  fresh:()=>({respEn:[125,46],estante:0,repisa:0,olor:null,mat:null,plata:null,cubo:0,salero:0,gente:{},fuegos:[{},{}],izq:{},der:{},basura:[],ventana:[],ventanacome:0,cola:[],cosas:[],vuelos:[],banco:1,encima:null,tarjeta:null,marcas:null,cq:{x:BANCO[0]-16,y:BANCO[1]-27,s:1,dy:0,al:1,vis:1,bub:null,hace:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
