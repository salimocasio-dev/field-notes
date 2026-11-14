"use strict";
/* ============================================================
   Coquí · scene "La mesa": abuela's kitchen (place 3, La cocina).
   On the left a counter with a cupboard over it; in the middle the
   table, seen a little from above, with four chairs behind it; on the
   right the stove, and a window over it. Whoever walks in front of the
   table stands lower in the picture than its top, so nothing on the
   table is ever hidden.
   People live in W.gente, by name: {x,y (feet), pose, dir, sent, vis,
   hace (come, bebe), que, lleva, lleva2, alza (held up to be seen),
   mano (held in the hand), piensa (a thought bubble), bebe}.
   Who sits where is W.sitio[name] = 0..3. A place at the table is
   W.puestos[i]: {plato:{n,con,plano}, taza:{n,con,k}, uts:[...],
   frente:[...]}: a plate or bowl (n of them, one on the other, with
   what is in the top one), a cup or glass, what lies beside them, and
   the messes in front. What stands on the counter is W.mostrador, on
   the stove W.estufa. Every story set here uses this drawing.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round,tarjeta=KIT.tarjeta,mkPerro=KIT.mkPerro;
const PISO=142,MESA=[92,130,96,30],SILLA=[104,128,152,176],MOSTR=[24,106,62,12],ESTUFA=[190,104,30,42],FILA=148,FRENTE=159;   // where the floor starts; the table top (x, y of its far edge, width, depth); the four chairs; the counter top; the stove; the row where things stand on the table, and the row for messes
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,abuelo:FAM.abuelo,mama:FAM.mama,papa:FAM.papa,abuela:{}};
const EN={platos:[36,MOSTR[1]+7],tazas:[54,MOSTR[1]+6],bandeja:[44,MOSTR[1]+8],comidas:[38,MOSTR[1]+8],vasos:[61,MOSTR[1]+8],jarron:[78,MOSTR[1]+6]};   // where each kind of thing stands on the counter
const LUIS=[75,160],FOGON=[205,170],CAN=[196,204];   // where Luis waits at the counter, where abuela stands at the stove, where Canelo lies
const UTIL={sopa:"cuchara",espa:"tenedor",pan:"cuchillo"},PLATODE={cuchara:"sopa",tenedor:"espa",cuchillo:"pan"},TINTE={sopa:"#E8A030",espa:"#D0302A",pan:"#F0D040"};
const solo=k=>String(k||"").replace(/^di_/,"").replace(/^(plato|taza|comida|vaso)s$/,"$1");
const cual=k=>{k=solo(k);return k==="hambre"||k==="comida"?"comida":"agua";},cosaDe=k=>cual(k)==="comida"?{k:"plato",con:"comida"}:{k:"vaso",con:"agua"};

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),Wd=RP.wood,M=MOSTR,E=ESTUFA;
  for(let y=0;y<PISO;y++)for(let x=0;x<SW;x++)b.px(x,y,y>PISO-5?"#C8B88A":hs(x>>2,y>>2)<6?"#F0E4B8":"#F6ECC4");
  for(let y=84;y<M[1];y++)for(let x=22;x<90;x++)b.px(x,y,(x%8===0||y%8===4)?"#B8D0D8":"#E4F0F4");
  for(let y=80;y<E[1];y++)for(let x=186;x<SW;x++)b.px(x,y,(x%8===2||y%8===0)?"#B8D0D8":"#E4F0F4");
  // the floor: red and cream tiles
  for(let y=PISO;y<SH;y++)for(let x=0;x<SW;x++){const ty=Math.floor((y-PISO)/12),tx=Math.floor((x+ty*6)/16);b.px(x,y,((y-PISO)%12===0||(x+ty*6)%16===0)?"#9A6A54":(tx+ty)%2?"#C8745A":"#E8D8B8");}
  for(let x=0;x<SW;x++)b.px(x,PISO-1,"#7A6A4A");
  // the door to the yard, at the left edge
  b.rect(0,58,20,PISO-58,"#9CCBF5");b.rect(0,112,20,PISO-112,RP.grn[2]);b.rect(20,56,3,PISO-56,Wd[1]);b.rect(0,56,22,3,Wd[1]);
  // the window over the stove
  b.rect(182,28,34,36,"#9CCBF5");b.ell(208,54,10,9,RP.grn);b.frame(180,26,38,40,Wd[1]);b.frame(181,27,36,38,Wd[3]);b.rect(198,28,2,36,Wd[2]);b.rect(182,45,34,2,Wd[2]);
  // the cupboard over the counter
  b.rect(27,34,42,40,Wd[2]);b.rect(27,34,42,2,Wd[4]);b.rect(27,72,42,2,Wd[0]);b.frame(26,33,44,42,OUT);b.rect(47,36,2,36,Wd[0]);[43,51].forEach(x=>b.rect(x,52,2,6,"#F0C020"));b.frame(30,38,16,32,Wd[1]);b.frame(50,38,16,32,Wd[1]);
  // the counter: a cabinet with two doors, and a pale top seen a little from above
  b.rect(M[0],M[1]+M[3],M[2],PISO+4-M[1]-M[3],Wd[2]);b.rect(M[0],M[1]+M[3],M[2],2,Wd[0]);b.frame(M[0]-1,M[1]+M[3]-1,M[2]+2,PISO+6-M[1]-M[3],OUT);
  b.rect(54,M[1]+M[3]+3,2,20,Wd[0]);[48,60].forEach(x=>b.rect(x,M[1]+M[3]+9,2,5,"#F0C020"));
  b.rect(M[0]-2,M[1],M[2]+4,M[3],"#E8E8F0");b.rect(M[0]-2,M[1],M[2]+4,2,"#FFFFFF");b.rect(M[0]-2,M[1]+M[3]-2,M[2]+4,2,"#B8B8C8");b.frame(M[0]-3,M[1]-1,M[2]+6,M[3]+2,OUT);
  // the stove
  b.rect(E[0],E[1],E[2],E[3],"#F2F2F8");b.rect(E[0],E[1],E[2],5,"#3A3A46");b.rect(E[0],E[1]+5,E[2],2,"#C8C8D4");b.frame(E[0]-1,E[1]-1,E[2]+2,E[3]+2,OUT);
  b.rect(E[0]+4,E[1]+16,E[2]-8,20,"#3A3A46");b.rect(E[0]+6,E[1]+18,E[2]-12,16,"#5A5A6A");b.rect(E[0]+5,E[1]+13,E[2]-10,2,"#9494A6");[E[0]+6,E[0]+14,E[0]+22].forEach(x=>b.rect(x,E[1]+8,3,3,"#D0302A"));
  // the four chairs: their backs show over the far edge of the table
  SILLA.forEach(x=>{b.rect(x-9,MESA[1]-26,2,44,Wd[0]);b.rect(x+7,MESA[1]-26,2,44,Wd[0]);[MESA[1]-26,MESA[1]-18].forEach(y=>{b.rect(x-9,y,18,4,Wd[2]);b.rect(x-9,y,18,1,Wd[4]);});b.frame(x-10,MESA[1]-27,20,10,OUT);});
  return b.done();}
// the table: drawn over the people who sit behind it. mantel: a white cloth
function mkPuesto(){const b=new Buf(SW,SH);for(let y=0;y<SH;y++)for(let x=0;x<SW;x++)b.px(x,y,y<150?"#9CCBF5":(hs(x>>1,y>>1)<40?"#D8C8A0":"#E4D6B0"));
  for(let x=96;x<200;x++)for(let y=96;y<112;y++)b.px(x,y,((x-96)>>3)%2?"#E0403A":"#FFFFFF");b.frame(95,95,106,18,OUT);b.rect(98,112,3,60,RP.wood[1]);b.rect(195,112,3,60,RP.wood[1]);
  b.rect(100,150,96,22,RP.wood[2]);b.rect(100,150,96,2,RP.wood[4]);b.frame(99,149,98,24,OUT);[[110,"#F0A020"],[120,"#F0A020"],[115,"#F0A020"],[136,"#E0403A"],[146,"#E0403A"],[141,"#E0403A"],[164,"#F0D040"],[174,"#F0D040"],[184,"#48A848"],[179,"#48A848"]].forEach((f,i)=>b.ell(f[0],146-(i%3===2?5:0),4.4,4,[f[1]]));
  return b.done();}
function mkMesa(mantel){const b=new Buf(MESA[2]+12,66),w=MESA[2],d=MESA[3],T=["#8A6238","#B08450","#D8B078","#ECCB96"];
  for(let y=0;y<d;y++){const x0=R(6-y*6/d),ww=w+R(y*12/d);b.rect(x0,y,ww,1,mantel?(hs(y,3)<50?"#FBFBFF":"#F4F4FA"):y<2?T[3]:(y%7===3?"#CCA468":T[2]));}
  b.rect(0,d,w+12,5,mantel?"#D8D8E4":T[1]);if(mantel)for(let x=2;x<w+10;x+=6)b.rect(x,d+5,3,2,"#D8D8E4");
  [[3,d+5],[w+6,d+5]].forEach(p=>{b.rect(p[0],p[1],4,26,T[0]);b.rect(p[0],p[1],1,26,T[1]);});
  return b.outline().done();}
// things on the table, on the counter, in a hand. Each is drawn with its foot at the bottom middle
const COSA={
  plato(){const b=new Buf(13,7);b.ell(6.5,3.5,5.6,2.8,["#B8B8C8","#F2F2F8","#FFFFFF"]);b.ell(6.5,3.2,3.2,1.4,["#DCDCE8"]);return b.outline().done();},
  hondo(){const b=new Buf(13,9);b.ell(6.5,5.5,4.4,3,["#B8B8C8","#DCDCE8"]);b.ell(6.5,3.6,5.6,3,["#B8B8C8","#F2F2F8","#FFFFFF"]);b.ell(6.5,3.4,4,1.9,["#D88820","#F0A838"]);return b.outline().done();},
  taza(){const b=new Buf(10,10);b.rect(1,2,6,7,"#F2F2F8");b.rect(1,2,2,7,"#FFFFFF");b.rect(1,8,6,1,"#C8C8D4");b.rect(7,3,1,1,"#F2F2F8");b.rect(8,4,1,3,"#F2F2F8");b.rect(7,7,1,1,"#F2F2F8");b.rect(2,2,4,2,"#C8C8D4");return b.outline().done();},
  tazall(){const b=new Buf(10,10);b.rect(1,2,6,7,"#F2F2F8");b.rect(1,2,2,7,"#FFFFFF");b.rect(1,8,6,1,"#C8C8D4");b.rect(7,3,1,1,"#F2F2F8");b.rect(8,4,1,3,"#F2F2F8");b.rect(7,7,1,1,"#F2F2F8");b.rect(2,2,4,2,"#6A3214");return b.outline().done();},
  vaso(){const b=new Buf(10,14);b.rect(1,1,8,12,"#DCF2FA");b.rect(1,5,8,8,"#58B4EC");b.rect(1,5,8,1,"#A8DCF8");b.rect(1,1,2,12,"#F2FBFF");return b.outline().done();},
  vacio(){const b=new Buf(10,14);b.rect(1,1,8,12,"#E4F4FA");b.rect(1,1,2,12,"#F8FDFF");return b.outline().done();},
  caido(){const b=new Buf(14,10);b.rect(1,1,12,8,"#E4F4FA");b.rect(1,1,12,2,"#F8FDFF");return b.outline().done();},
  cuchara(){const b=new Buf(9,18);b.ell(4.5,5,3,4,["#8A8A9C","#C8C8D4","#F8F8FF"]);b.rect(4,9,1,8,"#C8C8D4");return b.outline().done();},
  tenedor(){const b=new Buf(9,18);[1,4,7].forEach(x=>b.rect(x,1,1,6,"#D8D8E4"));b.rect(1,7,7,2,"#C8C8D4");b.rect(4,9,1,8,"#C8C8D4");return b.outline().done();},
  cuchillo(){const b=new Buf(9,18);b.ell(4.5,3,1.6,2.2,["#E8E8F2"]);b.rect(3,3,3,8,"#E8E8F2");b.rect(3,2,1,9,"#FFFFFF");b.rect(4,2,2,3,"#F8E060");b.rect(3,11,3,6,"#6A3E1A");return b.outline().done();},
  bizcocho(){const b=new Buf(10,9);b.rect(1,4,8,4,"#E8B050");b.rect(1,4,8,1,"#F8DC90");b.rect(1,2,8,2,"#FFF4E0");b.px(4,1,"#D0302A");b.px(5,1,"#D0302A");return b.outline().done();},
  tabla(n){const b=new Buf(20,11);b.rect(0,8,20,2,"#8A5A2A");[[1,3],[7,3],[13,3]].slice(0,n==null?3:+n).forEach(p=>{b.rect(p[0],p[1]+2,6,3,"#E8B050");b.rect(p[0],p[1],6,2,"#FFF4E0");b.px(p[0]+2,p[1]-1,"#D0302A");});return b.outline().done();},
  pastel(){const b=new Buf(11,11);b.rect(2,6,7,4,"#C87838");b.rect(3,6,1,4,"#E09A58");b.rect(6,6,1,4,"#E09A58");b.ell(5.5,5,4.4,2.6,["#F2A0C0","#FFC8DC","#FFFFFF"]);b.rect(5,1,2,2,"#D0302A");return b.outline().done();},
  tazacaida(){const b=new Buf(12,9);b.rect(2,2,8,6,"#F2F2F8");b.rect(2,2,8,2,"#FFFFFF");b.rect(1,3,2,4,"#6A3214");b.rect(4,0,3,2,"#F2F2F8");return b.outline().done();},
  cesta(){const b=new Buf(22,13);b.rect(2,6,18,6,"#C8853C");for(let x=2;x<20;x+=3)b.rect(x,6,1,6,"#8A5A2A");b.rect(1,5,20,2,"#E2A85A");[[6,4],[11,3],[16,4]].forEach(p=>b.ell(p[0],p[1],3,2.4,["#A8682C","#C8853C","#E2A85A"]));return b.outline().done();},
  panecillo(){const b=new Buf(9,7);b.ell(4.5,3.5,3.6,2.6,["#A8682C","#C8853C","#E2A85A"]);b.rect(4,2,1,2,"#F4CC88");return b.outline().done();},
  ollavacia(){const b=new Buf(24,18);b.ell(12,9,9,8,["#5A5A6A","#8A8A9A","#B8B8C8"]);b.ell(12,9,7,6,["#1E1E28","#2A2A36"]);b.rect(1,8,2,3,"#3A3A46");b.rect(21,8,2,3,"#3A3A46");return b.outline().done();},
  jarronv(){const b=new Buf(14,17);b.rect(2,2,8,14,"#E4F4FA");b.rect(2,2,2,14,"#F8FDFF");b.rect(10,5,2,1,"#B8D8E8");b.rect(12,6,1,5,"#B8D8E8");b.rect(10,11,2,1,"#B8D8E8");b.rect(0,2,2,2,"#E4F4FA");return b.outline().done();},
  entero(){const b=new Buf(24,13);b.ell(12,8,10.6,4,["#C88A30","#E8B050","#F8DC90"]);b.ell(12,5.5,10.6,3.6,["#F2E4D0","#FFF4E0","#FFFFFF"]);[6,12,18].forEach(x=>b.px(x,4,"#D0302A"));return b.outline().done();},
  roto(){const b=new Buf(15,7);b.rect(1,3,5,3,"#E8B050");b.rect(1,2,5,1,"#FFF4E0");b.rect(8,4,4,2,"#E8B050");b.px(7,2,"#E8B050");b.px(13,5,"#F8DC90");b.px(6,5,"#F8DC90");b.px(12,2,"#FFF4E0");return b.outline().done();},
  charco(){const b=new Buf(17,7);b.ell(8,3.5,7,2.4,["#4A220C","#6A3214","#8A4A22"]);b.ell(13,2.5,2.4,1.4,["#6A3214"]);return b.outline().done();},
  agua(){const b=new Buf(17,7);b.ell(8,3.5,7,2.4,["#3A90D0","#58B4EC","#A8DCF8"]);return b.outline().done();},
  olla(){const b=new Buf(24,16);b.rect(3,5,18,10,"#8A8A9A");b.rect(3,5,4,10,"#B8B8C8");b.rect(3,13,18,2,"#5A5A6A");b.rect(1,6,2,3,"#3A3A46");b.rect(21,6,2,3,"#3A3A46");b.rect(3,4,18,2,"#C87020");return b.outline().done();},
  tapa(){const b=new Buf(22,7);b.ell(11,7,9.6,5,["#6A6A7A","#9494A6","#C8C8D4"]);b.rect(9,0,4,2,"#3A3A46");return b.outline().done();},
  jarra(){const b=new Buf(15,14);b.rect(3,3,8,10,"#A8482A");b.rect(3,3,3,10,"#D0704A");b.rect(2,2,10,2,"#7A2E18");b.rect(11,5,2,1,"#7A2E18");b.rect(13,6,1,4,"#7A2E18");b.rect(11,10,2,1,"#7A2E18");b.rect(0,3,3,2,"#A8482A");return b.outline().done();},
  jarron(){const b=new Buf(14,17);b.rect(2,2,8,14,"#DCF2FA");b.rect(2,6,8,10,"#58B4EC");b.rect(2,2,2,14,"#F2FBFF");b.rect(10,5,2,1,"#B8D8E8");b.rect(12,6,1,5,"#B8D8E8");b.rect(10,11,2,1,"#B8D8E8");b.rect(0,2,2,2,"#DCF2FA");return b.outline().done();},
  espa(){const b=new Buf(13,7);b.ell(6.5,4,5,2.4,["#D8B050","#F0D488","#FBE8B0"]);b.ell(6.5,2.6,3,1.6,["#A81C18","#D0302A"]);b.px(2,5,"#F0D488");b.px(10,5,"#F0D488");return b.outline().done();},
  pan(){const b=new Buf(14,8);b.ell(4.5,4.5,3.6,3,["#A8682C","#C8853C","#E2A85A"]);b.rect(4,3,1,2,"#F4CC88");b.rect(9,3,4,4,"#F8E060");b.rect(9,3,4,1,"#FFF4A0");return b.outline().done();},
  comida(){const b=new Buf(13,7);b.ell(4.5,4,3.6,2.4,["#DCDCE8","#FFFFFF"]);b.ell(9,4,3,2.2,["#7A2E18","#A8482A"]);b.px(8,3,"#D0704A");return b.outline().done();},
  hueso(){const b=new Buf(15,8);b.rect(4,3,7,2,"#F8F4E8");[[3,2],[3,5],[11,2],[11,5]].forEach(p=>b.ell(p[0],p[1],1.7,1.7,["#F8F4E8"]));return b.outline().done();},
  lio(){const b=new Buf(30,16);b.ell(15,10,13,5.4,["#C8C8D4","#F2F2F8","#FFFFFF"]);b.ell(8,6,5,2,["#B8B8C8","#F2F2F8"]);b.ell(20,5,5,2,["#B8B8C8","#F2F2F8"]);b.rect(13,2,5,5,"#F2F2F8");b.rect(18,3,2,3,"#F2F2F8");b.rect(4,11,8,1,"#D8D8E4");b.rect(16,12,9,1,"#D8D8E4");return b.outline().done();},
  bandeja(){const b=new Buf(30,8);b.rect(1,2,28,5,"#8A5A2A");b.rect(1,2,28,1,"#B07A3C");b.rect(2,3,26,3,"#6A421C");return b.outline().done();},
  florero(){const b=new Buf(13,20);b.rect(4,11,5,8,"#58B4EC");b.rect(4,11,2,8,"#A8DCF8");[[3,5,"#E0403A"],[9,4,"#F0C020"],[6,2,"#FF8FB8"]].forEach(f=>{b.rect(f[0],f[1]+2,1,9-f[1]+2,RP.grn[1]);b.ell(f[0]+.5,f[1],2.2,2.2,[f[2]]);});return b.outline().done();},
  pano(){const b=new Buf(12,10);b.rect(1,1,10,8,"#F8F8FF");b.rect(1,4,10,1,"#E0403A");b.rect(1,7,10,1,"#E0403A");return b.outline().done();},
  mancha(c){const b=new Buf(15,8);b.ell(7,4,5.4,2.6,[c]);b.ell(11,2.5,2,1.3,[c]);b.px(2,6,c);b.px(13,6,c);return b.done();}};
const cosa=(k,c)=>spr("ms"+k+(c==null?"":c),()=>(COSA[k]||COSA.plato)(c));
function tenida(c,k,x,y,ang,esc,v){const im=cosa(k,v);if(ang||esc){c.save();c.translate(R(x),R(y));if(ang)c.rotate(ang);if(esc)c.scale(esc,esc);c.drawImage(im,-(im.width>>1),-im.height);c.restore();}else c.drawImage(im,R(x)-(im.width>>1),R(y)-im.height);}
// a plate or a cup with what is in it
function conTodo(c,o,x,y){const k=o.k,con=o.con;
  if(k==="plato"){const n=o.n||1,hondo=con==="sopa";for(let j=0;j<n;j++){if(j===1&&o.plano){fr(c,x-6,y-4,12,2,OUT);fr(c,x-5,y-4,10,1,"#E8B050");}tenida(c,hondo&&j===n-1?"hondo":"plato",x,y-j*3);}
    const yt=y-(n-1)*3;if(con==="bizcocho")tenida(c,"bizcocho",x,yt-2);else if(con==="choco")tenida(c,"charco",x,yt-1);else if(con==="espa"||con==="pan"||con==="comida")tenida(c,con,x,yt-2);if(o.vapor){const t=(F>>3)%2;fr(c,x-3+t,yt-10,1,3,"#FFFFFF");fr(c,x+1-t,yt-12,1,3,"#FFFFFF");fr(c,x+4+t,yt-9,1,2,"#FFFFFF");}
    if(con==="migas"){fr(c,x-3,yt-4,1,1,"#C89A40");fr(c,x+2,yt-5,1,1,"#C89A40");fr(c,x,yt-3,1,1,"#C89A40");}return;}
  if(k==="taza"){const n=o.n||1;tenida(c,con==="choco"&&n===1?"tazall":"taza",x,y);if(n>1)tenida(c,con==="choco"?"tazall":"taza",x+1,y-4);if(con==="choco"){const t=(F>>3)%2;fr(c,x-3+t,y-13,1,2,"#FFFFFF");fr(c,x-t,y-15,1,2,"#FFFFFF");}return;}
  if(k==="vaso"){tenida(c,con==="agua"?"vaso":"vacio",x,y);return;}
  tenida(c,k,x,y);}
const BX={cuchara:-9,tenedor:0,cuchillo:9};
// what stands at a place, left to right, with the x of each
function fila(i){const ps=W.puestos[i],L=[];if(!ps)return L;const q=Object.keys(W.sitio||{}).find(id=>W.sitio[id]===i),bebe=q&&W.gente[q]&&W.gente[q].hace==="bebe",tz=ps.taza&&!bebe,dos=ps.plato&&tz;
  if(tz)L.push({key:"taza",o:Object.assign({},ps.taza,{k:ps.taza.k||"taza"}),x:SILLA[i]+(dos?6:0),dy:dos?-3:0});
  if(ps.plato)L.push({key:"plato",o:Object.assign({k:"plato"},ps.plato),x:SILLA[i]-(dos?4:0),dy:0});
  return L;}
const xDe=(i,key)=>{const e=fila(i).find(e=>e.key===key);return e?e.x:SILLA[i];},dyDe=(i,key)=>{const e=fila(i).find(e=>e.key===key);return e?e.dy:0;};

const LUGAR={inicio:[104,161,1],centro:[104,161,1]};
const alto=id=>{const w=QUIEN[id]||{},p=W.gente[id];return id==="abuela"?51:w.nino?(p&&p.sent?37:44):(p&&p.sent?49:56);};
const caja=id=>{const p=W.gente[id];if(!p||p.vis===0)return null;const h=alto(id);return p.sent?[R(p.x)-11,R(p.y)-h,22,FILA+3-(R(p.y)-h)]:[R(p.x)-11,R(p.y)-h,22,h];};   // somebody who sits behind the table is touched above its edge
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const enMostr=k=>({id:k,m:2,z:1,si:w=>!!(w.mostrador&&w.mostrador[k]),box:()=>k==="comidas"?[EN[k][0]-15,EN[k][1]-16,30,18]:k==="vasos"?[EN[k][0]-9,EN[k][1]-18,19,20]:[EN[k][0]-12,EN[k][1]-18,24,22]});
const G=id=>W.gente[id];
const COSAS=Object.keys(QUIEN).map(persona).concat(["platos","tazas","bandeja","comidas","vasos"].map(enMostr),[
  {id:"muestra",si:w=>!!w.muestra,box:w=>[w.muestra.x-9,w.muestra.y-(w.muestra.g?38:14),18,w.muestra.g?40:16],m:0},
  {id:"ofrece",si:w=>!!(w.gente.abuela&&w.gente.abuela.ofrece),box:w=>{const p=w.gente.abuela;return [R(p.x)-29,R(p.y)-42,20,18];},m:0},
  {id:"bebe",si:w=>!!(w.gente.mama&&w.gente.mama.bebe&&w.gente.mama.vis!==0),box:w=>{const p=w.gente.mama;return [R(p.x)+1,R(p.y)-38,18,18];},m:1},
  {id:"perro",si:w=>!!w.perro&&w.perro.vis!==0,box:w=>[R(w.perro.x)-14,R(w.perro.y)-20,28,22],m:1},
  {id:"olla",si:w=>!!(w.estufa&&w.estufa.olla),box:[ESTUFA[0]+1,ESTUFA[1]-16,26,20],m:1},
  {id:"mesa",box:[MESA[0]-4,MESA[1],MESA[2]+8,MESA[3]+8],m:0},{id:"estufa",box:[ESTUFA[0],ESTUFA[1]-4,28,46],m:0},
  {id:"cocina",box:[22,24,196,190],m:0}]);

/* ---------- drawing ---------- */
function nube(g,x,y,o){fr(g,x-1,y-1,24,20,OUT);fr(g,x,y,22,18,"#FFFFFF");fr(g,x-4,y+17,4,4,OUT);fr(g,x-3,y+18,2,2,"#FFFFFF");fr(g,x-8,y+22,3,3,OUT);conTodo(g,o,x+11,y+16);}   // a thought: what he would like
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  if(id==="abuela"){const ps=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle"),top=y-50+((p.paso&&a%2)?-1:0);c.save();c.translate(x,top);if(d<0)c.scale(-1,1);c.drawImage(spr("ab"+ps+habla,()=>mkAbuela(ps,habla)),-30,0);c.restore();
    if(p.lleva)tenida(c,p.lleva,x-14,y-17,0,0,p.lleva==="tabla"?Math.max(0,Math.min(3,W.reb)):undefined);if(p.lleva2)tenida(c,p.lleva2,x+13,y-15);
    if(p.alza)tenida(c,p.alza,x-19,y-18,0,2);
    if(p.ofrece){fr(c,x-16,y-27,7,3,OUT);fr(c,x-15,y-26,6,2,RP.skin[2]);conTodo(c,p.ofrece,x-19,y-26);}return;}
  const pose=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle"),im=spr("pm"+id+pose+habla+(p.sent?1:0),()=>KIT.mkPersona(w,pose,habla,p.sent)),top=y-im.height+1+((p.paso&&a%2)?-1:0)+(p.dy||0);
  c.save();c.translate(x,top);if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  if(p.bebe){const e=p.bebe===1?"idle":p.bebe,bi=spr("bb"+e+(a%2),()=>KIT.mkBebe(e,a%2));c.drawImage(bi,x-3,y-(p.sent?39:40));}
  const hy=top+(w.nino?22:26);
  if(p.hace==="come"){if(p.que==="bizcocho"||p.que==="pan"||p.que==="panecillo")tenida(c,p.que==="pan"?"panecillo":p.que,x+5,hy+4+(a%2)*2);else tenida(c,p.que||"cuchara",x+6,hy+12+(a%2)*2);}
  else if(p.hace==="bebe")tenida(c,p.que==="vaso"?"vaso":"tazall",x+6,hy+6-(a%2));
  else if(p.mano)tenida(c,p.mano,x+8,p.sent?MESA[1]+7:hy+18);
  if(p.alza)tenida(c,p.alza,x+(p.sent?0:d*13),p.sent?top+3:hy+8,0,2);   // held up to be seen: over the head of somebody who sits, beside the head of somebody who stands
  if(p.lleva){const o=typeof p.lleva==="string"?{k:p.lleva}:p.lleva;conTodo(c,o,x+d*10,top+(w.nino?34:38));}
  if(p.lleva2){const o=typeof p.lleva2==="string"?{k:p.lleva2}:p.lleva2;conTodo(c,o,x-d*10,top+(w.nino?34:38));}}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui"||q.hace)&&a%2?1:0,dy=R(q.dy),cx=b.x+(b.w>>1);
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.encima)conTodo(g,W.encima,cx,b.y+dy+3);}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{},M=W.mostrador||{},E=W.estufa||{};
  c.drawImage(W.afuera?spr("puesto",mkPuesto):spr("cocina",fondo),0,0);
  if(E.horno){fr(c,ESTUFA[0]+6,ESTUFA[1]+18,ESTUFA[2]-12,16,"#B84818");fr(c,ESTUFA[0]+8,ESTUFA[1]+27,14,6,"#F4E4C0");fr(c,ESTUFA[0]+8,ESTUFA[1]+26,14,2,"#FFF8E8");}
  // on the stove
  if(E.olla===2)tenida(c,"ollavacia",ESTUFA[0]+13,ESTUFA[1]+3);else if(E.olla){tenida(c,"olla",ESTUFA[0]+13,ESTUFA[1]+3);if(E.tapa)tenida(c,"tapa",ESTUFA[0]+13,ESTUFA[1]-9);if(E.vapor){const t=(F>>2)%6;[[9,-14],[14,-18],[18,-13]].forEach((p,i)=>fr(c,ESTUFA[0]+p[0]+((t+i)%3)-1,ESTUFA[1]+p[1]-((t+i*2)%6),2,3,"#FFFFFF"));}}
  if(E.bizcocho)tenida(c,"entero",ESTUFA[0]+11,ESTUFA[1]+5);if(E.jarra)tenida(c,"jarra",ESTUFA[0]+25,ESTUFA[1]-1);if(E.pastel)tenida(c,"pastel",ESTUFA[0]+6,ESTUFA[1]-3);
  // on the counter
  for(let i=0;i<(M.platos||0);i++)tenida(c,"plato",EN.platos[0],EN.platos[1]-i*2);
  for(let i=0;i<(M.tazas||0);i++)tenida(c,"taza",EN.tazas[0]-5+(i%2)*11,EN.tazas[1]-(i>>1)*5);
  if(M.bandeja){tenida(c,"bandeja",EN.bandeja[0],EN.bandeja[1]);(W.bandeja||[]).forEach(k=>tenida(c,k,EN.bandeja[0]+BX[k],EN.bandeja[1]-2));}
  for(let i=0;i<(M.comidas||0);i++)conTodo(c,{k:"plato",con:"comida"},EN.comidas[0]-7+(i%2)*15,EN.comidas[1]-(i>>1)*6);
  for(let i=0;i<(M.vasos||0);i++)tenida(c,"vaso",EN.vasos[0]-4+(i%2)*9,EN.vasos[1]-(i>>1)*3);
  if(M.jarron)tenida(c,M.jarron===2?"jarronv":"jarron",EN.jarron[0]+4,EN.jarron[1]);
  const L=[];
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.z!=null?p.z:p.y,d:()=>gente(c,id,a)});});
  // the table, and what stands on it at each place
  if(!W.afuera)L.push({y:MESA[1]+MESA[3]+6,d:()=>{c.drawImage(spr("mesa"+(W.mantel?1:0),()=>mkMesa(W.mantel)),MESA[0]-6,MESA[1]);
    (W.puestos||[]).forEach((ps,i)=>{if(!ps)return;const dy=ps.alza?-12:0,dx=ps.dx||0;fila(i).forEach(e=>conTodo(c,e.o,e.x+dx,FILA+dy+e.dy));
      (ps.frente||[]).forEach((m,j)=>{const x=SILLA[i]-4+j*7,y=FRENTE+(j%2)*2;if(m.k==="mancha")c.drawImage(cosa("mancha",m.c),x-5,y-7);else if(m.o)conTodo(c,m.o,x+2,y);else tenida(c,m.k,x,y);});});}});
  if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>{const o=W.perro,f=o.pose==="bark"||o.pose==="walk"||o.pose==="eat"||o.cola?(a>>1)%2:0,im=spr("pe"+o.pose+f,()=>mkPerro(o.pose,f));c.save();c.translate(R(o.x),R(o.y)-im.height+2-(o.dy||0));if(o.dir<0)c.scale(-1,1);c.drawImage(im,-13,0);c.restore();
    if(o.lleva)conTodo(c,o.lleva,R(o.x)+o.dir*16,R(o.y));}});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>{if(o.rot)tenida(c,o.k,o.x,o.y,o.rot);else conTodo(c,o,o.x,o.y);}});});
  (W.suelo||[]).forEach(o=>L.push({y:o.y-4,d:()=>tenida(c,o.k,o.x,o.y,o.rot)}));
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  // things in the air, the jug that pours, what is held up to be looked at
  (W.vuelos||[]).forEach(o=>{if(o.rot)tenida(c,o.k,o.x,o.y,o.rot);else conTodo(c,o,o.x,o.y);});
  if(W.vierte){const v=W.vierte;tenida(c,"jarra",v.x+9,v.y-6,-0.8);fr(c,v.x+1,v.y-10,2,v.h||10,"#6A3214");}
  if(W.muestra){const m=W.muestra;if(m.g)tenida(c,m.k,m.x,m.y,0,2);else conTodo(c,{k:m.k},m.x,m.y);}
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.piensa&&p.vis!==0)nube(c,R(p.x)+7,R(p.y)-alto(id)-21,cosaDe(p.piensa));});
  if(q.vis&&q.piensa){const b=frogBox(q);nube(c,b.x+(b.w>>1)+12,b.y-24,cosaDe(q.piensa));}
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.alza&&p.sent?34:0)];}
// picture bubbles: a spoon, a fork, a knife, drawn big
function respIcon(g,k,x,y,w,h,a){if(!COSA[k])return;g.imageSmoothingEnabled=false;tenida(g,k,x+(w>>1),y+h-2,0,2);}
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,66,24);
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m){g.fillStyle=OUT;for(let k=0;k<11;k++){g.fillRect(x+k,y+1+k,4,3);g.fillRect(x+10-k,y+1+k,4,3);}g.fillStyle="#C8401E";for(let k=0;k<11;k++){g.fillRect(x+1+k,y+2+k,2,1);g.fillRect(x+11-k,y+2+k,2,1);}}
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}
const marca=m=>{const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;};

/* ---------- moving things ---------- */
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/6));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;}
async function vuela(o,x0,y0,x1,y1,n){const v=Object.assign({x:x0,y:y0},o);W.vuelos.push(v);n=n||5;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(x1-x0)*t;v.y=y0+(y1-y0)*t-Math.sin(t*Math.PI)*8;await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);}
const cx=()=>W.cq.x+16,pies=()=>W.cq.y+27;
async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(3,R(d/40))));}
const acasa=()=>ranaA(W.casa[0],W.casa[1]);
const sitio=a=>W.sitio[a];
// a walk to the chair and down onto it; a walk in at the door first for whoever is outside
async function sienta(id,i){const p=G(id);W.sitio[id]=i;if(p.vis===0){p.vis=1;p.x=6;p.y=152;p.sent=0;}await mueve(id,p.x,152,2);await mueve(id,SILLA[i],152);p.sent=1;p.y=150;p.dir=1;SFX.blip();}
async function sale(id){const p=G(id);p.sent=0;p.hace=null;p.mano=null;await mueve(id,p.x,152,2);await mueve(id,4,152);p.vis=0;delete W.sitio[id];}
async function abuelaEn(i){const ab=G("abuela"),x=i==null?FOGON[0]:SILLA[i]+17,y=i==null?FOGON[1]:204;if(Math.hypot(ab.x-x,ab.y-y)>3)await mueve("abuela",x,y);ab.dir=-1;}
function alBebe(si){const m=G("mama"),ab=G("abuela");if(!m||!m.bebe||!W.contado)return;m.bebe=si?"clap":1;if(si&&m.x>ab.x)ab.dir=1;}
async function luisEn(i){const p=G("luis"),x=i==null?LUIS[0]:SILLA[i]-15,y=i==null?LUIS[1]:202;if(Math.hypot(p.x-x,p.y-y)>3)await mueve("luis",x,y);p.dir=1;}
async function perroA(x,y){const pe=W.perro,x0=pe.x,y0=pe.y,n=Math.max(3,R(Math.hypot(x-x0,y-y0)/7));pe.pose="walk";pe.dir=x<x0?-1:1;for(let s=1;s<=n;s++){pe.x=x0+(x-x0)*s/n;pe.y=y0+(y-y0)*s/n;await wait(TICK);}}
// a thing is set down at a place. Where the same thing already stands it goes on top of it, and what was in that one is ruined
function coloca(i,k){const ps=W.puestos[i],o=ps[k];if(!o){ps[k]={n:1,con:null};SFX.blip();return 0;}
  if(o.con&&o.con!=="migas"){if(k==="plato"){o.n=2;ps.frente.push({k:"roto"});}else ps.frente.push({k:"charco"});o.con=null;SFX.bonk();return 1;}if(k==="plato")o.n=2;SFX.blip();return 0;}
async function ranaTrae(k,de){const M=W.mostrador;
  if(de){const p=G(de),j=sitio(de);await ranaA(j!=null?SILLA[j]-10:p.x-16,j!=null?190:p.y+8);}
  else{const key=k+"s",e=EN[M[key]!=null?key:"bandeja"];await ranaA(e[0]+2,171);if(M[key])M[key]--;}}
const ranaAl=i=>ranaA(SILLA[i]-10,190);
const tiene=id=>{const p=G(id);return p?(p.mano||p.alza||null):null;},quienTiene=k=>Object.keys(W.gente).find(id=>G(id).vis!==0&&tiene(id)===k)||null;
function pone26(id,k){const ps=W.puestos[sitio(id)];if(k==="comida")ps.plato={n:1,con:"comida"};else ps.taza={n:1,con:"agua",k:"vaso"};(W.tuvo[id]=W.tuvo[id]||{})[k]=1;}
const corre=(o,pr)=>{if(o&&o.suelto){W._mov=pr;return Promise.resolve();}return pr;};

const acts={
  async pose(o){const p=G(o.quien);if(p)p.pose=o.que;},
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async casa(){await acasa();},
  async ya(){const p=W._mov;W._mov=null;if(p)await p;},
  async g(o){const p=G(o.quien);if(!p)return;Object.keys(o).forEach(k=>{if(!["act","quien","ms"].includes(k))p[k]=o[k]===""?null:o[k];});if(o.ms)await wait(+o.ms);},
  async entra(o){return corre(o,sienta(o.quien,+o.silla));},
  async sale(o){return corre(o,sale(o.quien));},
  async rana(o){return corre(o,ranaA(+o.x,+o.y,o.h));},
  // one of a kind is lifted off the counter, or out of the tray, to be looked at
  async muestra(o){const k=solo(o.k);if(!k){W.muestra=null;return;}const b=!!W.mostrador.bandeja,e=EN[b?"bandeja":k+"s"]||EN.platos;W.muestra={k,g:b,x:e[0]+(b?({cuchara:-9,tenedor:0,cuchillo:9})[k]:0),y:e[1]-(b?6:20)};SFX.blip();await wait(200);},
  // abuela goes to somebody's place, or back to the stove. sirve: with the slices and the jug in her hands
  async abuelaa(o){const ab=G("abuela");const pr=(async()=>{if(o.nada){ab.lleva=null;ab.lleva2=null;ab.ofrece=null;if(W.estufa.bizcocho)W.estufa.jarra=1;}if(o.centro)await mueve("abuela",142,207);else await abuelaEn(o.a?sitio(o.a):null);ab.dir=-1;if(o.sirve){ab.lleva="tabla";ab.lleva2="jarra";W.estufa.jarra=0;}})();return corre(o,pr);},

  /* ----- story 24: La mesa ----- */
  async inicio24(){W.mantel=1;W.mostrador={platos:6,tazas:6};W.estufa={bizcocho:1,jarra:1,pastel:1};W.reb=3;W.choc=9;W.contado=0;W.gente={abuela:{x:FOGON[0],y:FOGON[1],dir:-1},luis:{x:LUIS[0],y:LUIS[1],dir:1},abuelo:{vis:0},papa:{vis:0},mama:{vis:0,bebe:1},carmen:{vis:0}};W.casa=[120,188];Object.assign(W.cq,{x:104,y:161,s:1});},
  async entran24(o){const pr=(async()=>{const a=sienta("abuelo",0);await wait(TICK*6);const b=sienta("papa",1);await wait(TICK*6);await sienta("mama",2);await a;await b;})();return corre(o,pr);},
  // the frog fetches a plate or a cup from the counter and sets it down at somebody's place
  async pon(o){const k=solo(o.k),i=sitio(o.a);const pr=(async()=>{await ranaTrae(k);W.encima={k};SFX.blip();await ranaAl(i);await wait(120);W.encima=null;V.lio=coloca(i,k)?"1":"";await wait(250);})();return corre(o,pr);},
  async luispone(o){const k=solo(o.k),i=sitio(o.a),p=G("luis");const pr=(async()=>{await luisEn(null);const key=k+"s";if(W.mostrador[key])W.mostrador[key]--;p.lleva=k;SFX.blip();await luisEn(i);await wait(120);p.lleva=null;V.lio=coloca(i,k)?"1":"";await wait(250);await luisEn(null);})();return corre(o,pr);},
  // abuela serves: the slice onto the plate, the chocolate into the cup
  async sirve(o){const k=solo(o.k),i=sitio(o.a),ps=W.puestos[i],ab=G("abuela");const pr=(async()=>{await abuelaEn(i);if(!ab.lleva){ab.lleva="tabla";ab.lleva2="jarra";W.estufa.jarra=0;}if(!ps[k])return;if(W.contado&&(k==="plato"?W.reb:W.choc)<=0)return;if(W.contado){if(k==="plato")W.reb--;else W.choc--;}alBebe(1);
    if(k==="plato"){await vuela({k:"bizcocho"},ab.x-14,ab.y-24,xDe(i,"plato"),FILA-2-(ps.plato.n-1)*3,5);ps.plato.con="bizcocho";}
    else{ab.lleva2=null;W.vierte={x:xDe(i,"taza")-2,y:FILA-8+dyDe(i,"taza")};await wait(TICK*6);W.vierte=null;ab.lleva2="jarra";ps.taza.con="choco";}SFX.blip();await wait(250);alBebe(0);})();return corre(o,pr);},
  // she serves what she asked for onto what he brought: the slice breaks on the cup, the chocolate runs off the plate
  async sirvemal(o){const k=solo(o.k),i=sitio(o.a),ps=W.puestos[i],ab=G("abuela");await abuelaEn(i);if(!ab.lleva){ab.lleva="tabla";ab.lleva2="jarra";W.estufa.jarra=0;}if(W.contado){if(k==="plato")W.reb--;else W.choc--;}alBebe(1);
    if(k==="plato"){const x=xDe(i,"taza");await vuela({k:"bizcocho"},ab.x-14,ab.y-24,x-1,FILA-8,5);const v={k:"bizcocho",x:x-1,y:FILA-8};W.vuelos.push(v);await wait(TICK*5);v.x-=3;v.y+=3;v.rot=-0.6;await wait(TICK*3);W.vuelos.splice(W.vuelos.indexOf(v),1);ps.frente.push({k:"roto"});}
    else{const x=xDe(i,"plato");ab.lleva2=null;W.vierte={x:x-2,y:FILA-6,h:8};await wait(TICK*4);ps.plato.con="choco";await wait(TICK*5);W.vierte=null;ab.lleva2="jarra";await wait(TICK*3);ps.plato.con=null;ps.frente.push({k:"charco"});}
    SFX.bonk();await wait(500);alBebe(0);},
  // Luis deals: a plate to one, a cup to the other
  async reparte24(o){const p=G("luis"),a=sitio(o.p),b=sitio(o.t);await luisEn(null);W.mostrador.platos--;W.mostrador.tazas--;p.lleva="plato";p.lleva2="taza";SFX.blip();const pri=a<b?[[a,"plato","lleva"],[b,"taza","lleva2"]]:[[b,"taza","lleva2"],[a,"plato","lleva"]];
    for(const e of pri){await luisEn(e[0]);await wait(120);p[e[2]]=null;coloca(e[0],e[1]);await wait(200);}await luisEn(null);},
  // the baby pulls the cloth: everything slides to mamá's end and over the edge. Abuelo lifts his in time
  async tira24(){const m=G("mama"),im=sitio("mama");m.bebe="clap";SFX.blip();await wait(400);W.puestos[sitio("abuelo")].alza=1;
    for(let s=1;s<=5;s++){W.puestos.forEach((ps,i)=>{if(!ps.alza)ps.dx=(SILLA[im]-SILLA[i])*s/5;});await wait(TICK);}
    W.puestos.forEach(ps=>{if(!ps.alza){ps.plato=null;ps.taza=null;ps.dx=0;}});W.mantel=0;W.cosas.push({id:"lio",k:"lio",x:SILLA[im]-6,y:200});SFX.bonk();await wait(500);m.bebe=1;},
  async recoge24(){const p=G("luis");await mueve("luis",SILLA[sitio("mama")]-26,204);await wait(150);W.cosas=W.cosas.filter(o=>o.id!=="lio");p.lleva="lio";SFX.blip();await mueve("luis",4,190);p.vis=0;p.lleva=null;W.puestos[sitio("abuelo")].alza=0;SFX.blip();await wait(300);
    p.vis=1;p.x=6;p.y=170;p.lleva="plato";p.lleva2="taza";await luisEn(null);p.lleva=null;p.lleva2=null;W.mostrador.platos+=3;W.mostrador.tazas+=3;SFX.blip();await wait(200);},
  // after the turn: three slices on the board, three cups of chocolate in the jug
  async corta24(){const ab=G("abuela");await abuelaEn(null);W.reb=3;W.choc=3;W.contado=1;W.estufa.bizcocho=0;W.estufa.jarra=0;ab.lleva="tabla";ab.lleva2="jarra";SFX.blip();await wait(300);},
  async lista24(){const ab=G("abuela");ab.lleva=null;ab.lleva2=null;await abuelaEn(null);await acasa();},
  async final24(){Object.keys(W.sitio).forEach((id,j)=>{const ps=W.puestos[sitio(id)],p=G(id),bz=ps.plato&&ps.plato.con==="bizcocho",ch=ps.taza&&ps.taza.con==="choco";if(bz&&(j%2===0||!ch)){p.hace="come";p.que="bizcocho";ps.plato.con="migas";}else if(ch){p.hace="bebe";p.que="taza";}});SFX.blip();await wait(900);
    if(!W.lost){const ab=G("abuela");W.estufa.pastel=0;ab.ofrece={k:"pastel"};await mueve("abuela",cx()+40,pies()+8);ab.dir=-1;await wait(200);ab.ofrece=null;W.cosas.push({k:"pastel",x:cx()+15,y:pies()+3});W.cq.hace="come";SFX.blip();}
    await wait(900);},

  /* ----- story 25: La cuchara ----- */
  // There is one spoon, one fork and one knife. Each is in the tray (W.bandeja), held up (alza) or in a hand at a dish (mano).
  async inicio25(){W.mantel=1;W.mostrador={bandeja:1};W.bandeja=["cuchara","tenedor","cuchillo"];W.estufa={olla:1,vapor:1};W.gente={abuela:{x:FOGON[0],y:FOGON[1],dir:-1},luis:{x:LUIS[0],y:LUIS[1],dir:1},abuelo:{x:SILLA[0],y:150,sent:1,dir:1},mama:{x:SILLA[1],y:150,sent:1,dir:1},papa:{x:SILLA[2],y:150,sent:1,dir:1},carmen:{x:SILLA[3],y:150,sent:1,dir:1}};W.sitio={abuelo:0,mama:1,papa:2,carmen:3};W.casa=[120,190];W.origen={};Object.assign(W.cq,{x:104,y:163,s:1});},
  // abuela brings a dish from the stove. d: sopa, espa, pan; or para: the thing it is eaten with
  async plato25(o){const i=sitio(o.a),ps=W.puestos[i],ab=G("abuela"),d=o.d||PLATODE[solo(o.para)];if(ps.plato)return;const pr=(async()=>{await abuelaEn(null);ab.ofrece={k:"plato",con:d};SFX.blip();await abuelaEn(i);await wait(120);ab.ofrece=null;ps.plato={n:1,con:d};SFX.blip();await wait(200);if(!o.queda)await abuelaEn(null);})();return corre(o,pr);},
  // the frog takes a spoon, a fork or a knife to somebody: out of the tray, or from whoever has it. vuelve: the wrong one in that hand goes back to where it came from
  async util(o){const i=sitio(o.a),p=G(o.a);let de=o.de&&o.de!=="bandeja"?o.de:null,k=solo(o.k);if(de)k=tiene(de);else if(!W.bandeja.includes(k))de=quienTiene(k);
    if(de===o.a){p.mano=k;p.alza=null;return;}
    await ranaTrae(k,de);if(de){G(de).alza=null;G(de).mano=null;G(de).hace=null;}else W.bandeja=W.bandeja.filter(x=>x!==k);W.encima={k};SFX.blip();await ranaAl(i);await wait(120);W.encima=null;
    const vieja=tiene(o.a);p.alza=null;p.hace=null;p.mano=k;SFX.blip();await wait(200);
    if(vieja){const a=W.origen[vieja],q=a&&a!==o.a?G(a):null;if(q){await vuela({k:vieja},p.x+8,p.y-24,q.x,q.y-alto(a)-4,6);q.alza=vieja;}else W.bandeja.push(vieja);SFX.blip();}
    W.origen[k]=de||null;},
  async luisalza(o){const p=G("luis"),k=solo(o.k);await luisEn(null);W.bandeja=W.bandeja.filter(x=>x!==k);p.alza=k;SFX.blip();await wait(300);},
  // the frog calls for one: whoever has it passes it along and gets the other one's thing back
  async llama(o){const a=o.a,p=G(a),k=solo(o.k),de=quienTiene(k),mia=tiene(a);
    if(de===a||!de){p.dy=-3;await wait(250);p.dy=0;await wait(200);p.mano=mia;p.alza=null;return;}   // he has it already: he holds it up, shrugs, and keeps it
    const q=G(de);q.alza=null;q.mano=null;q.hace=null;p.alza=null;p.mano=null;SFX.blip();
    await Promise.all([vuela({k},q.x,q.y-alto(de)-4,p.x+8,p.y-22,6),mia?vuela({k:mia},p.x,p.y-alto(a)-4,q.x,q.y-alto(de)-4,6):Promise.resolve()]);
    p.mano=k;if(mia)q.alza=mia;SFX.blip();await wait(200);},
  // he eats with what he has in his hand; with the wrong thing the food drops onto the cloth
  async come25(o){const i=sitio(o.a),ps=W.puestos[i],p=G(o.a);if(!ps.plato||!p.mano)return;const d=ps.plato.con;p.que=p.mano;p.hace="come";
    if(UTIL[d]===p.mano){V.lio="";if(d==="pan")p.que="pan";await wait(500);return;}
    await wait(800);p.hace=null;ps.frente.push({k:"mancha",c:TINTE[d]});V.lio="1";SFX.bonk();await wait(500);},
  // a dish is finished: abuela takes it, and the thing goes up to be seen
  async termina25(o){const ab=G("abuela");for(const id of String(o.a).split(",")){const i=sitio(id),ps=W.puestos[i],p=G(id);if(!ps.plato)continue;p.hace=null;await abuelaEn(i);ps.plato=null;if(p.mano){p.alza=p.mano;p.mano=null;}SFX.blip();await wait(150);}if(!o.queda)await abuelaEn(null);},
  // whoever went without the thing for his dish gets it back from the one who holds it
  async arregla25(){for(const id of Object.keys(W.sitio)){const ps=W.puestos[sitio(id)],p=G(id);if(ps.plato&&p.mano!==UTIL[ps.plato.con]){const k=UTIL[ps.plato.con];if(quienTiene(k)&&quienTiene(k)!==id){await acts.llama({a:id,k});p.que=ps.plato.con==="pan"?"pan":k;p.hace="come";}}}},
  // the turn: Luis gathers the three into the tray and takes it out; abuela has more; he comes back and deals them out again
  async turno25a(){const l=G("luis");await luisEn(null);W.mostrador.bandeja=0;l.lleva="bandeja";SFX.blip();for(let i=0;i<4;i++){const id=Object.keys(W.sitio).find(x=>sitio(x)===i),p=G(id);if(!tiene(id))continue;await luisEn(i);p.alza=null;p.mano=null;SFX.blip();await wait(150);}await mueve("luis",4,196);l.vis=0;},
  async turno25b(o){const l=G("luis");W.estufa.tapa=0;l.vis=1;l.x=6;l.y=196;l.lleva="bandeja";for(const e of [[o.ha,"cuchara"],[o.hb,"tenedor"],[o.hc,"cuchillo"]].sort((a,b)=>sitio(a[0])-sitio(b[0]))){await luisEn(sitio(e[0]));G(e[0]).alza=e[1];W.origen[e[1]]=null;SFX.blip();await wait(200);}await luisEn(null);l.lleva=null;W.mostrador.bandeja=1;W.bandeja=[];},
  // round B: one of the two who still hold a thing up gets the dish for the other one's thing
  async elige25(o){const hs2=Object.keys(W.sitio).filter(id=>G(id).alza&&id!==o.no),f=Q.get("pb"),pb=hs2.includes(f)?f:hs2[Math.floor(Math.random()*hs2.length)],ops=["cuchara","tenedor","cuchillo"].filter(k=>k!==G(pb).alza),g=Q.get("tb");V.pb=pb;V.tb=ops.includes(g)?g:ops[Math.floor(Math.random()*ops.length)];},
  // bread for everybody
  async pan25(){const ab=G("abuela"),l=G("luis");await luisEn(null);W.mostrador.bandeja=0;l.lleva="bandeja";for(let i=0;i<4;i++){const id=Object.keys(W.sitio).find(x=>sitio(x)===i),p=G(id);if(!p.alza)continue;await luisEn(i);W.bandeja.push(p.alza);p.alza=null;SFX.blip();await wait(120);}await luisEn(null);l.lleva=null;W.mostrador.bandeja=1;
    await abuelaEn(null);ab.lleva="cesta";for(let i=3;i>=0;i--){const id=Object.keys(W.sitio).find(x=>sitio(x)===i),p=G(id),ps=W.puestos[i];await abuelaEn(i);if(!(p.hace==="come")){p.hace="come";p.que="panecillo";}SFX.blip();await wait(120);}
    if(!W.lost){await acasa();await mueve("abuela",cx()+40,pies()+8);ab.dir=-1;await wait(200);W.cosas.push({k:"panecillo",x:cx()+15,y:pies()+3});W.cq.hace="come";SFX.blip();}else await abuelaEn(null);
    ab.lleva=null;await wait(900);},

  /* ----- story 26: Tengo hambre ----- */
  // From the turn on there are four plates and four glasses, one of each for abuelo, mamá, papá and the frog. W.tuvo[who] is what he has had; W.perdio[who] is what Canelo had instead.
  async inicio26(){W.mantel=0;W.mostrador={jarron:1};W.estufa={olla:1,tapa:1};W.gente={abuela:{x:FOGON[0],y:FOGON[1],dir:-1},luis:{vis:0},carmen:{vis:0},abuelo:{vis:0},mama:{vis:0},papa:{vis:0}};W.casa=[70,192];W.vacios=[];W.tuvo={};W.perdio={};Object.assign(W.cq,{x:54,y:165,s:1});},
  async tapa26(){W.estufa.tapa=0;W.estufa.vapor=1;SFX.blip();await wait(400);},
  // abuela fills plates and glasses and stands them on the counter. fin: the pot and the jug are empty after that
  async llena26(o){const M=W.mostrador,n=+(o.n||2),ab=G("abuela");const pr=(async()=>{await mueve("abuela",EN.jarron[0]+26,182);ab.dir=-1;for(const k of ["comidas","vasos"])while((M[k]||0)<n){M[k]=(M[k]||0)+1;SFX.blip();await wait(200);}if(o.fin){W.tuvo={};W.perdio={};await abuelaEn(null);W.estufa.vapor=0;W.estufa.olla=2;M.jarron=2;SFX.blip();await wait(500);}})();return corre(o,pr);},
  // a thought: what he would like
  async piensa(o){const k=o.k?cual(o.k):null;if(o.quien==="coqui")W.cq.piensa=k;else G(o.quien).piensa=k;if(k)SFX.blip();await wait(250);},
  // abuela takes a plate or a glass off the counter and puts it on the floor in front of the frog
  async abuelada(o){const ab=G("abuela"),k=cual(o.k),it=cosaDe(k),key=k==="comida"?"comidas":"vasos";const pr=(async()=>{await mueve("abuela",EN.jarron[0]+26,182);ab.dir=-1;if(W.mostrador[key])W.mostrador[key]--;ab.ofrece=it;SFX.blip();await mueve("abuela",cx()+46,pies()+10);ab.dir=-1;await wait(150);ab.ofrece=null;W.cosas.push(Object.assign({id:"cq"+k,x:cx()+(k==="comida"?16:29),y:pies()+3},it));V.cq=k;SFX.blip();await wait(250);})();return corre(o,pr);},
  // the frog has what stands in front of him
  async ranatoma(){const k=V.cq,c=W.cosas.find(o=>o.id==="cq"+k);if(!c)return;W.cq.hace=k==="comida"?"come":"bebe";W.cq.piensa=null;(W.tuvo.coqui=W.tuvo.coqui||{})[k]=1;await wait(1100);W.cq.hace=null;c.con=k==="comida"?"migas":null;SFX.blip();await wait(200);},
  async quita26(){W.cosas=W.cosas.filter(o=>!String(o.id||"").startsWith("cq"));},
  // abuela takes a plate or a glass off the counter and holds it out
  async ofrece26(o){const ab=G("abuela"),k=cual(o.k),key=k==="comida"?"comidas":"vasos";await mueve("abuela",EN.jarron[0]+26,182);ab.dir=-1;if(W.mostrador[key])W.mostrador[key]--;ab.ofrece=cosaDe(k);SFX.blip();await wait(300);},
  // the frog takes a plate or a glass to somebody: from the counter, or out of abuela's hand
  async lleva26(o){const k=cual(o.k),i=sitio(o.a),ab=G("abuela"),ps=W.puestos[i];
    if(ab.ofrece&&o.de==="abuela"){await ranaA(ab.x-30,ab.y+10);await wait(120);ab.ofrece=null;}else{const key=k==="comida"?"comidas":"vasos";await ranaA(EN[key][0]+4,173);if(W.mostrador[key])W.mostrador[key]--;}
    W.encima=cosaDe(k);SFX.blip();await ranaAl(i);await wait(120);W.encima=null;pone26(o.a,k);SFX.blip();await wait(250);},
  async abuelalleva(o){const k=cual(o.k),i=sitio(o.a),ab=G("abuela"),key=k==="comida"?"comidas":"vasos";await mueve("abuela",EN.jarron[0]+26,182);ab.dir=-1;if(W.mostrador[key])W.mostrador[key]--;ab.ofrece=cosaDe(k);SFX.blip();await abuelaEn(i);await wait(120);ab.ofrece=null;pone26(o.a,k);SFX.blip();await wait(200);await abuelaEn(null);},
  // he eats, or drinks, what stands in front of him
  async toma26(o){const p=G(o.a),ps=W.puestos[sitio(o.a)];p.piensa=null;if(ps.plato&&ps.plato.con==="comida"&&!(o.k&&cual(o.k)==="agua")){p.hace="come";p.que="tenedor";}else if(ps.taza&&ps.taza.con){p.hace="bebe";p.que="vaso";}await wait(600);},
  async acaba26(o){for(const id of String(o.quien).split(",")){const p=G(id),ps=W.puestos[sitio(id)];ps.plato=null;ps.taza=null;p.hace=null;}SFX.blip();await wait(300);},
  // Canelo has it: what was put aside at the edge of the table, or what stands untouched in front of the frog
  async canelo(o){const pe=W.perro;let c,k;
    if(o.de==="coqui"){k=V.cq;c=W.cosas.find(x=>x.id==="cq"+k);if(!c)return;await wait(500);await perroA(c.x+18,c.y+2);(W.perdio.coqui=W.perdio.coqui||{})[k]=1;}
    else{const i=sitio(o.a),ps=W.puestos[i],p=G(o.a);k=cual(o.k);for(const d of [-1,1,-1,1]){p.dir=d;await wait(180);}const it=cosaDe(k);if(k==="comida")ps.plato=null;else ps.taza=null;ps.frente.push({k:"aparte",o:it});(W.perdio[o.a]=W.perdio[o.a]||{})[k]=1;if(W.tuvo[o.a])delete W.tuvo[o.a][k];SFX.blip();await wait(500);
      await perroA(SILLA[i]+16,194);pe.pose="sit";pe.dir=-1;pe.dy=5;await wait(300);ps.frente=ps.frente.filter(m=>m.k!=="aparte");c=Object.assign({x:SILLA[i]-2,y:FRENTE},it);W.cosas.push(c);for(let s=1;s<=4;s++){c.y=FRENTE+(202-FRENTE)*s/4;await wait(TICK);}pe.dy=0;}
    // he drags it to his corner and has it there
    W.cosas=W.cosas.filter(x=>x!==c);pe.lleva={k:c.k,con:c.con};await perroA(CAN[0],CAN[1]);
    pe.lleva=null;pe.dir=-1;const j=W.vacios.length,vx=CAN[0]-24-j*17;
    if(c.k==="plato"){const v={k:"plato",con:"comida",x:vx,y:CAN[1]+6};W.cosas.push(v);pe.pose="eat";SFX.blip();await wait(900);v.con=null;}
    else{W.cosas.push({k:"agua",x:vx-1,y:CAN[1]+8,z:0});W.cosas.push({k:"caido",x:vx,y:CAN[1]+5});SFX.bonk();pe.pose="husmea";await wait(900);}
    W.vacios.push(c.k);pe.pose="lie";pe.cola=1;await wait(400);pe.cola=0;},
  async salen26(){const a=sale("luis");await wait(TICK*4);await sale("carmen");await a;W.puestos.forEach(ps=>{ps.plato=null;ps.taza=null;});},
  // the turn: Canelo comes in, sits down in front of the counter and whines
  async canelo26(){W.perro={x:4,y:200,pose:"walk",dir:1};const pe=W.perro;await perroA(EN.comidas[0]+52,198);pe.pose="sit";pe.dir=-1;await wait(300);pe.pose="bark";await wait(600);pe.pose="sit";},
  async echa26(){const pe=W.perro;await perroA(CAN[0],CAN[1]);pe.dir=-1;pe.pose="lie";await wait(300);},
  // the ending: what is left on the counter goes round, a plate and a glass for each, as far as it goes
  async reparte26(){const ab=G("abuela"),M=W.mostrador;await mueve("abuela",EN.jarron[0]+26,182);ab.dir=-1;
    for(const id of ["abuelo","mama","papa","coqui"])for(const k of ["comida","agua"]){if((W.tuvo[id]&&W.tuvo[id][k])||(W.perdio[id]&&W.perdio[id][k]))continue;const key=k==="comida"?"comidas":"vasos";if(!M[key])continue;M[key]--;
      const x1=id==="coqui"?cx()+(k==="comida"?16:29):SILLA[sitio(id)],y1=id==="coqui"?pies()+3:FILA;await vuela(cosaDe(k),EN[key][0],EN[key][1],x1,y1,6);if(id==="coqui"){W.cosas.push(Object.assign({id:"cq"+k,x:x1,y:y1},cosaDe(k)));(W.tuvo.coqui=W.tuvo.coqui||{})[k]=1;}else pone26(id,k);SFX.blip();await wait(120);}
    await abuelaEn(null);},
  async final26(){Object.keys(W.sitio).forEach(id=>{const p=G(id),ps=W.puestos[sitio(id)];p.piensa=null;if(ps.plato&&ps.plato.con==="comida"){p.hace="come";p.que="tenedor";}else if(ps.taza&&ps.taza.con){p.hace="bebe";p.que="vaso";}else p.hace=null;});W.cq.hace=W.cosas.some(c=>String(c.id||"").startsWith("cq"))?"come":null;await wait(700);
    const pe=W.perro;if(!W.lost){const ab=G("abuela");ab.lleva="hueso";await mueve("abuela",CAN[0]-34,CAN[1]-8);ab.dir=1;await wait(200);ab.lleva=null;W.cosas.push({k:"hueso",x:CAN[0]-14,y:CAN[1]+6});pe.pose="sit";pe.cola=1;SFX.blip();}else{pe.pose="lie";pe.cola=1;}
    await wait(900);},

  // everybody at once, to look at the drawing
  async prueba(o){const n=+(o&&o.n||1);
    W.gente={abuela:{x:FOGON[0],y:FOGON[1],dir:-1,lleva:n===1?"tabla":null,lleva2:n===1?"jarra":null,ofrece:n===3?{k:"plato",con:"comida"}:null},luis:{x:LUIS[0],y:LUIS[1],dir:1,alza:n===2?"cuchillo":null},abuelo:{x:SILLA[0],y:150,dir:1,sent:1,alza:n===2?"cuchara":null,piensa:n===3?"sed":null},papa:{x:SILLA[1],y:150,dir:1,sent:1,hace:n===2?"come":null,que:"tenedor"},mama:{x:SILLA[2],y:150,dir:1,sent:1,bebe:n===1?1:0,mano:n===2?"cuchillo":null},carmen:{x:SILLA[3],y:150,dir:1,sent:1,alza:n===2?"tenedor":null,hace:n===3?"bebe":null,que:"vaso"}};W.sitio={abuelo:0,papa:1,mama:2,carmen:3};
    W.mostrador=n===3?{comidas:4,vasos:4,jarron:2}:n===2?{bandeja:1}:{platos:5,tazas:4};W.bandeja=["cuchara","cuchillo"];W.reb=2;W.estufa=n===1?{bizcocho:1,pastel:1}:{olla:n===3?2:1,vapor:n===2?1:0};W.mantel=n===2?1:0;W.perro=n===3?{x:CAN[0],y:CAN[1],pose:"lie",dir:-1}:null;
    const P=(pl,tz,uts,fr)=>({plato:pl||null,taza:tz||null,uts:uts||[],frente:fr||[]});
    W.puestos=n===1?[P({n:1,con:"bizcocho"},{n:1,con:"choco"}),P({n:2,con:"bizcocho",plano:1},{n:1},[],[{k:"roto"}]),P({n:1},{n:1},[],[{k:"charco"},{k:"tazacaida"}]),P({n:1,con:"choco"},null,[],[{k:"roto"},{k:"charco"}])]
      :n===2?[P({n:1,con:"sopa"},null,["cuchara"]),P({n:1,con:"espa"}),P({n:1,con:"pan"},null,["tenedor"],[{k:"mancha",c:TINTE.sopa},{k:"mancha",c:TINTE.espa}]),P({n:1,con:"sopa"},null,["cuchillo"],[{k:"mancha",c:TINTE.pan}])]
      :[P({n:1,con:"comida"}),P(null,{n:1,con:"agua",k:"vaso"}),P(null,null,[],[{k:"aparte",o:{k:"plato",con:"comida"}}]),P()];
    W.cosas=n===3?[{k:"plato",x:CAN[0]-24,y:CAN[1]+3},{k:"agua",x:CAN[0]-42,y:CAN[1]+5,z:0},{k:"caido",x:CAN[0]-41,y:CAN[1]+2}]:n===1?[{k:"lio",x:146,y:200}]:[];
    W.suelo=n===2?[{k:"cuchara",x:110,y:196,rot:1},{k:"tenedor",x:140,y:204,rot:2.2},{k:"cuchillo",x:166,y:192,rot:0.6}]:[];
    Object.assign(W.cq,{x:104,y:163,s:1});W.encima=n===1?{k:"plato"}:n===2?{k:"cuchara"}:{k:"vaso",con:"agua"};W.cq.piensa=n===3?"hambre":null;W.muestra=n===2?{k:"tenedor",g:1,x:EN.bandeja[0],y:EN.bandeja[1]-6}:null;W.tarjeta="rondas";W.marcas=["ok","x",null];},
};
async function stake(lost,max,en){await wait(200);}
function poke(what){}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)+(W.gente[k].sent?"s":"")+(W.gente[k].alza?"^"+W.gente[k].alza:"")+(W.gente[k].mano?"["+W.gente[k].mano+"]":"")+(W.gente[k].hace?"("+W.gente[k].hace+")":"")).join(" ")
  +" puestos="+(W.puestos||[]).map(p=>(p.plato?"P"+p.plato.n+(p.plato.con?":"+p.plato.con:"")+(p.plato.plano?"_":""):"")+(p.taza?"T"+p.taza.n+(p.taza.con?":"+p.taza.con:""):"")+(p.uts.length?"u:"+p.uts.join("+"):"")+(p.frente.length?"!"+p.frente.map(m=>m.k).join("+"):"")).join("|")
  +" mostr="+JSON.stringify(W.mostrador||{})+" vacios="+(W.vacios||[]).join("+")+" marcas="+(W.marcas||[]).join(",");
KIT.escena({id:"mesa",CAM:{wide:[22,0,196,216]},heartAt:[124,22],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({respEn:[125,28],gente:{},sitio:{},puestos:[0,1,2,3].map(()=>({plato:null,taza:null,uts:[],frente:[]})),mostrador:{},estufa:{},mantel:0,cosas:[],afuera:0,vuelos:[],suelo:[],vacios:[],bandeja:[],origen:{},tuvo:{},perdio:{},reb:3,choc:9,contado:0,perro:null,encima:null,muestra:null,vierte:null,casa:[120,188],tarjeta:null,marcas:null,cq:{x:104,y:161,s:1,dy:0,al:1,vis:1,bub:null,hace:null,piensa:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
