"use strict";
/* ============================================================
   Coquí · scene "La nevera": abuela's fridge (place 3, La cocina).
   The fridge stands at the left, open: three shelves with two
   places each, and a drawer. To its right a counter with the bread
   board, the fruit bowl, cups and plates. The frog stands on a stool
   between the two. People stand on the floor in front of the counter.
   The fridge is W.nev: {abierta, h:[six places: {k, v} or null]}.
   The counter is W.mos: {pan (slices left), frutero:{guineo, manzana,
   china}, vasos:[{de, x}], platos:[{de, x, items:[{k, v}]}]}.
   People live in W.gente, as in the other kitchen scenes.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round,tarjeta=KIT.tarjeta;
const PISO=150,ENC=112,NEV=[40,40,56,116],MOS=[110,108],BANCO=[104,190],VEN=[150,36,64,62],SILL=98,PATIO=120,MURO=70;   // the floor; the counter top; the fridge (x, y, width, height); the counter (x, width); the frog's stool
const HUECO=[[55,79],[81,79],[55,105],[81,105]];   // the four places on the two shelves of the fridge; under them, the drawer
const EN={pan:[160,ENC+10],frutero:[170,ENC+10],vasos:[202,ENC+9],pila:[124,ENC+10],cesta:[68,NEV[1]]};
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,abuelo:FAM.abuelo,mama:FAM.mama,papa:FAM.papa,abuela:{}};
const COLV={luis:["#2A8A3A","#58C868"],carmen:["#D05888","#F898C0"],abuelo:["#B8A070","#E8D8A8"],papa:["#2A60B0","#58A0F0"],mama:["#B02828","#F05858"],abuela:["#7A48A8","#B888E8"],coqui:["#D07818","#F8B050"],rojo:["#B02828","#F05858"],azul:["#2A60B0","#58A0F0"],gris:["#6A6E80","#B8BCCC"],amarillo:["#C89010","#F8D040"]};

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),Wd=RP.wood,[nx,ny,nw,nh]=NEV;
  for(let y=0;y<PISO;y++)for(let x=0;x<SW;x++)b.px(x,y,y>PISO-5?"#C8B88A":hs(x>>2,y>>2)<6?"#F0E4B8":"#F6ECC4");
  for(let y=72;y<ENC;y++)for(let x=MOS[0]-4;x<SW;x++)b.px(x,y,(x%8===0||y%8===0)?"#B8D0D8":"#E4F0F4");
  for(let y=PISO;y<SH;y++)for(let x=0;x<SW;x++){const ty=Math.floor((y-PISO)/12),tx=Math.floor((x+ty*6)/16);b.px(x,y,((y-PISO)%12===0||(x+ty*6)%16===0)?"#9A6A54":(tx+ty)%2?"#C8745A":"#E8D8B8");}
  for(let x=0;x<SW;x++)b.px(x,PISO-1,"#7A6A4A");
  // a wide window over the counter: sky, the yard wall, a hedge; its sill is a ledge things stand on
  b.rect(VEN[0],VEN[1],VEN[2],VEN[3],"#9CCBF5");b.ell(VEN[0]+50,VEN[1]+12,9,4,["#FFFFFF"]);b.rect(VEN[0],MURO+6,VEN[2],SILL-MURO-6,"#58A848");for(let x=VEN[0];x<VEN[0]+VEN[2];x+=5)b.rect(x,MURO+6+((x>>2)%2),3,2,"#3A8A3A");
  b.rect(VEN[0],MURO,VEN[2],7,"#E8D8B8");b.rect(VEN[0],MURO,VEN[2],1,"#FFF4D8");b.rect(VEN[0],MURO+6,VEN[2],1,"#A89878");for(let x=VEN[0]+6;x<VEN[0]+VEN[2];x+=12)b.rect(x,MURO+1,1,5,"#C8B898");
  // the counter: a cabinet, and a pale top seen a little from above
  b.rect(MOS[0],ENC+12,MOS[1],PISO+4-ENC-12,Wd[2]);b.rect(MOS[0],ENC+12,MOS[1],2,Wd[0]);b.frame(MOS[0]-1,ENC+11,MOS[1]+2,PISO+6-ENC-12,OUT);[36,72].forEach(d=>b.rect(MOS[0]+d,ENC+15,2,22,Wd[0]));
  b.rect(MOS[0]-2,ENC,MOS[1]+4,12,"#E8E8F0");b.rect(MOS[0]-2,ENC,MOS[1]+4,2,"#FFFFFF");b.rect(MOS[0]-2,ENC+10,MOS[1]+4,2,"#B8B8C8");b.frame(MOS[0]-3,ENC-1,MOS[1]+6,14,OUT);
  // the sink, set into the counter at its left end
  b.rect(EN.pila[0]-11,ENC+2,22,8,"#8A8EA0");b.rect(EN.pila[0]-10,ENC+3,20,6,"#C8CCDA");b.rect(EN.pila[0]-10,ENC+3,20,1,"#6A6E80");b.rect(EN.pila[0]-1,ENC-8,2,9,"#8A8EA0");b.rect(EN.pila[0]-1,ENC-9,6,2,"#8A8EA0");b.rect(EN.pila[0]+4,ENC-8,2,3,"#8A8EA0");
  // the fridge: its body, the freezer door at the top
  b.rect(nx,ny,nw,nh,"#D8DCE8");b.rect(nx,ny,3,nh,"#F2F4FA");b.rect(nx+nw-3,ny,3,nh,"#A8ACBC");b.frame(nx-1,ny-1,nw+2,nh+2,OUT);
  b.rect(nx+3,ny+3,nw-6,12,"#F2F4FA");b.frame(nx+2,ny+2,nw-4,14,"#8A8EA0");b.rect(nx+nw-12,ny+7,6,3,"#8A8EA0");
  b.rect(nx+2,ny+nh,5,3,"#3A3A46");b.rect(nx+nw-7,ny+nh,5,3,"#3A3A46");
  return b.done();}
const COSA={
  // a bottle of milk: n is how many cups are left in it (0 to 4)
  leche(n){const b=new Buf(12,19);n=n==null?4:+n;b.rect(2,6,8,12,"#BFE0F0");b.rect(4,2,4,4,"#BFE0F0");b.rect(2,6,2,12,"#E4F6FC");if(n>0){const h=3*n;b.rect(3,18-h,6,h,"#FFFFFF");}b.rect(4,0,4,2,"#3A70B0");return b.outline().done();},
  // a wedge of cheese with holes: n portions (0 to 3)
  queso(n){const b=new Buf(18,13);n=n==null?3:+n;if(n>0){const w=5+4*n;for(let i=0;i<w;i++){const h=3+Math.floor(i*6/(w-1));b.rect(1+i,11-h,1,h,"#F0A010");b.px(1+i,11-h,"#FFD050");}b.rect(1,10,w,1,"#C07808");[[4,8],[8,6],[12,8],[14,5],[10,9]].forEach(q=>{if(q[0]<w-1)b.rect(q[0],q[1],2,2,"#C07808");});}return b.outline().done();},
  // butter on a blue dish: n portions (0 to 3)
  mantequilla(n){const b=new Buf(20,11);n=n==null?3:+n;b.ell(10,8.4,9,2,["#3A70B0","#5A90D0","#8CB8E8"]);if(n>0){const w=3+3*n;b.rect(4,3,w,5,"#FFF0A0");b.rect(4,3,w,1,"#FFFBE0");b.rect(4,7,w,1,"#E0C860");b.rect(4+w-1,3,1,5,"#E0C860");}return b.outline().done();},
  // a sliced loaf on a board: n slices left (0 to 6)
  pan(n){const b=new Buf(36,16);n=n==null?6:+n;b.rect(1,12,34,3,"#B07A3C");b.rect(1,12,34,1,"#D09A54");for(let i=0;i<n;i++){const x=3+i*5;b.rect(x,3,4,9,"#F6E4B4");b.rect(x,2,4,2,"#B87A30");b.rect(x,3,1,9,"#B87A30");b.rect(x+3,3,1,9,"#D09A54");}return b.outline().done();},
  // one slice, lying flat: plain, or with cheese (q), butter (m), or both
  rebanada(v){const b=new Buf(13,9);v=v||"";b.ell(6.5,5,5.4,3,["#B87A30","#F6E4B4","#FFF6DC"]);if(v.includes("m"))b.ell(6.5,4.6,3.6,1.8,["#FFE890","#FFF8D0"]);if(v.includes("q")){b.rect(3,3,7,3,"#F0A010");b.px(5,4,"#C07808");b.px(8,3,"#C07808");}return b.outline().done();},
  frutero(){const b=new Buf(44,13);b.ell(22,9,18,3.6,["#8A5A2A","#B07A3C"]);b.ell(22,5,21,4.6,["#8A5A2A","#B07A3C","#D09A54"]);b.ell(22,4.6,18,3.2,["#5A3A1A"]);return b.outline().done();},
  guineo(v){const b=new Buf(16,10),C=v==="pardo"?["#4A2E12","#6A4A22","#8A6A32"]:v==="pelado"?["#E8DCB0","#FBF4D8","#FFFFFF"]:["#C89810","#F0C820","#FFE860"];b.cap(2,3,8,7,1.9,C);b.cap(8,7,13,3,1.9,C);b.px(1,1,"#5A3A1A");b.px(14,1,"#5A3A1A");if(v==="pelado"){b.rect(5,7,2,3,"#F0C820");b.rect(9,7,2,3,"#F0C820");}return b.outline().done();},
  manzana(v){const b=new Buf(11,11);if(v==="cortada"||v==="parda"){const C=v==="parda"?["#7A5A2A","#A8845A"]:["#F0E4B8","#FFF8E0"];b.ell(3,6.5,2.6,3.6,C);b.ell(8,6.5,2.6,3.6,C);b.rect(0,4,1,5,"#C02020");b.rect(10,4,1,5,"#C02020");b.px(3,6,"#5A3A1A");b.px(8,6,"#5A3A1A");return b.outline().done();}b.ell(5.5,6.4,4.4,4,["#A01818","#D02828","#F05848"]);b.rect(5,0,1,3,"#5A3A1A");b.rect(6,1,3,2,"#48A848");b.px(3,4,"#FFB0A0");return b.outline().done();},
  china(v){const b=new Buf(11,11);if(v==="cortada"||v==="seca"){const C=v==="seca"?["#A87A40","#C8A068"]:["#F08010","#FFB040"];b.ell(3,6.5,2.8,3.4,C);b.ell(8,6.5,2.8,3.4,C);b.px(3,6,"#FFE8B0");b.px(8,6,"#FFE8B0");return b.outline().done();}b.ell(5.5,6,4.4,4.2,["#D06808","#F08818","#FFB040"]);b.rect(5,1,2,1,"#48A848");b.px(4,7,"#D06808");b.px(7,5,"#D06808");return b.outline().done();},
  // a cup nobody can see into, in its owner's colour
  vaso(c){const b=new Buf(10,13),C=COLV[c]||["#9494A6","#C8C8D4"];b.rect(1,1,8,11,C[0]);b.rect(1,1,3,11,C[1]);b.rect(1,1,8,1,C[1]);return b.outline().done();},
  // the same cup seen from above: full of milk, or empty
  vasoarriba(v){const [c,n]=String(v||"").split(":"),b=new Buf(16,16),C=COLV[c]||["#9494A6","#C8C8D4"];b.ell(8,8,7,7,[C[0],C[1]]);b.ell(8,8,5,5,n==="1"?["#DCE8F4","#FFFFFF"]:["#3A3A46","#5A5A6A"]);return b.outline().done();},
  plato(){const b=new Buf(15,7);b.ell(7.5,3.5,6.6,2.8,["#3A70B0","#5A90D0","#8CB8E8"]);b.ell(7.5,3.2,4,1.5,["#4A80C0"]);return b.outline().done();},
  // a bread roll; a basket of them (n: 0 to 4); a plate of fruit; a paper bag in its owner's colour (v: "luis", "luis:1" with something in it)
  panecillo(v){const b=new Buf(13,8);b.ell(6.5,4.4,5.6,3,v==="viejo"?["#6A7A3A","#A89A5A","#C8B878"]:["#A86A20","#D09A48","#F0C880"]);b.rect(4,2,1,3,"#8A5A18");b.rect(8,2,1,3,"#8A5A18");if(v==="viejo"){b.rect(3,4,2,2,"#4A8A4A");b.rect(8,5,2,1,"#4A8A4A");}return b.outline().done();},
  cesta(n){const b=new Buf(34,15);n=n==null?4:+n;[[9,6],[17,5],[25,6],[13,3]].slice(0,n).forEach(q=>{b.ell(q[0],q[1],5,3,["#A86A20","#D09A48","#F0C880"]);b.rect(q[0]-1,q[1]-2,1,3,"#8A5A18");});b.rect(3,7,28,7,"#B07A3C");for(let x=4;x<31;x+=4)b.rect(x,7,2,7,"#8A5A2A");b.rect(2,7,30,2,"#D09A54");return b.outline().done();},
  platofruta(v){const b=new Buf(22,12);b.ell(11,8.4,10,3,["#3A70B0","#5A90D0","#8CB8E8"]);const g=v==="vieja"?["#4A2E12","#8A7A32","#B8A848"]:["#C89810","#F0C820","#FFE860"];b.cap(4,6,9,8,1.7,g);b.ell(15,5.4,3.6,3.4,v==="vieja"?["#6A2A18","#9A4A30"]:["#A01818","#D02828","#F05848"]);b.rect(15,1,1,2,"#5A3A1A");if(v==="vieja"){b.rect(13,5,2,2,"#4A3A1A");b.rect(6,7,2,1,"#3A2A0A");}return b.outline().done();},
  bolsa(v){const [c,n]=String(v||"").split(":"),b=new Buf(13,17),C=COLV[c]||["#B8A070","#E8D8A8"];b.rect(1,4,11,12,"#D8B888");b.rect(1,4,3,12,"#E8CCA0");b.rect(1,4,11,2,"#B89868");b.rect(3,9,7,4,C[0]);b.rect(4,10,5,2,C[1]);if(n==="1"){b.ell(6.5,3,4,2.4,["#A86A20","#D09A48"]);}return b.outline().done();},
  bandeja(){const b=new Buf(38,6);b.rect(1,2,36,3,"#9494A6");b.rect(1,2,36,1,"#C8C8D4");return b.outline().done();},
  // a coin; the tray with six dents (n coins in it); the jar with a piragua on it; a piragua; the piragua man's cart, far off
  moneda(){const b=new Buf(6,6);b.ell(3,3,2.6,2.6,["#C89010","#F0C020","#FFE870"]);return b.outline().done();},
  monedas(n){const b=new Buf(24,13);n=n==null?6:+n;b.rect(1,1,22,11,"#8A5A2A");b.rect(1,1,22,1,"#B07A3C");for(let i=0;i<6;i++){const x=5+(i%3)*7,y=4+Math.floor(i/3)*5;b.ell(x,y,2.6,2,["#5A3A1A"]);if(i<n)b.ell(x,y-0.4,2.4,1.8,["#C89010","#F0C020","#FFE870"]);}return b.outline().done();},
  piragua(){const b=new Buf(9,13);b.ell(4.5,4,3.6,3.4,["#C02040","#F04868","#FF98A8"]);for(let i=0;i<6;i++)b.rect(1+Math.floor(i/2),7+i,7-2*Math.floor(i/2),1,i%2?"#F2F2F8":"#DCDCE8");return b.outline().done();},
  tarro(){const b=new Buf(12,15);b.rect(1,3,10,11,"#DCF2FA");b.rect(1,3,2,11,"#F2FBFF");b.rect(2,1,8,2,"#9494A6");b.ell(6,7,2.4,2.2,["#C02040","#F04868"]);b.rect(5,9,2,3,"#F2F2F8");return b.outline().done();},
  carrito(){const b=new Buf(22,24);b.rect(10,2,1,12,"#5A3A1A");b.ell(10.5,3,9,2.6,["#C02040","#F04868","#FF98A8"]);b.rect(3,13,16,7,"#F2F2F8");b.rect(3,13,16,2,"#58B4EC");b.ell(7,21,2.4,2.4,["#3A3A46","#6A6A7A"]);b.ell(15,21,2.4,2.4,["#3A3A46","#6A6A7A"]);return b.outline().done();},
  // a bird on the wall: sitting (0), pecking (c0, c1)
  ave(v){const b=new Buf(11,9),pk=String(v).startsWith("c"),dn=v==="c1";b.ell(5,5,3.6,2.6,["#8A4A1A","#B8742A","#D8A050"]);b.ell(dn?8.4:8,dn?5.6:3,1.8,1.8,["#B8742A","#D8A050"]);b.rect(dn?10:10,dn?6:3,1,1,"#F0C020");b.px(dn?8:8,dn?5:2,"#20140A");b.rect(1,4,2,1,"#6A3A12");b.rect(4,8,1,1,"#F0C020");b.rect(6,8,1,1,"#F0C020");return b.outline().done();},
  // juice things: a net of chinas (n), a jug with four marks (n marks full), a clear glass (0 empty, 1 juice, leche), a puddle of juice
  red(n){const b=new Buf(18,13);n=n==null?4:+n;[[5,8],[12,8],[8,4],[14,4]].slice(0,n).forEach(q=>b.ell(q[0],q[1],3.6,3.4,["#D06808","#F08818","#FFB040"]));if(!n){b.rect(2,10,14,2,"#C8C8D4");}return b.outline().done();},
  jarra(n){const b=new Buf(17,20);n=n==null?4:+n;b.rect(2,2,10,17,"#DCF2FA");b.rect(2,2,2,17,"#F2FBFF");if(n>0)b.rect(3,18-n*4,8,n*4,"#F08818");for(let i=1;i<=4;i++)b.rect(9,18-i*4,3,1,"#5A6A7A");b.rect(12,5,2,1,"#B8D8E8");b.rect(14,6,1,7,"#B8D8E8");b.rect(12,13,2,1,"#B8D8E8");b.rect(0,2,2,2,"#DCF2FA");return b.outline().done();},
  claro(v){const b=new Buf(9,13);b.rect(1,1,7,11,"#DCF2FA");b.rect(1,1,2,11,"#F2FBFF");if(v==="1"||v===1)b.rect(2,3,5,9,"#F08818");if(v==="leche")b.rect(2,3,5,9,"#FFFFFF");return b.outline().done();},
  charcoj(){const b=new Buf(26,9);b.ell(12,5,10,3,["#C06008","#F08818","#FFB040"]);b.ell(22,3,2.4,1.4,["#F08818"]);b.ell(3,2,1.6,1,["#F08818"]);return b.outline().done();},
  exprimidor(){const b=new Buf(12,9);b.ell(6,6,5,2.4,["#9494A6","#C8C8D4","#F2F2F8"]);b.ell(6,3.4,2.6,2.6,["#C8C8D4","#F2F2F8"]);return b.outline().done();},
  platopan(n){const b=new Buf(17,10);n=n==null?2:+n;b.ell(8.5,6.6,7.6,2.8,["#3A70B0","#5A90D0","#8CB8E8"]);for(let i=0;i<n;i++){b.ell(6+i*5,4.6-i,3.6,2.2,["#B87A30","#F6E4B4","#FFF6DC"]);}return b.outline().done();},
  gotaj(){const b=new Buf(4,5);b.rect(1,0,2,4,"#F08818");return b.outline().done();},
  chorro(h){h=+h||26;const b=new Buf(7,h+2);b.rect(2,0,3,h-3,"#F08818");b.rect(2,0,1,h-3,"#FFB040");b.ell(3.5,h-2,2,2,["#C06008","#F08818"]);return b.outline().done();},
  // a cup seen from above, in a round picture: orange to the brim (1) or empty (0)
  vista(v){const [c,n]=String(v||"").split(":"),b=new Buf(24,24),C=COLV[c]||["#9494A6","#C8C8D4"];b.ell(12,12,11,11,["#FFFFFF"]);b.ell(12,12,7.4,7.4,[C[0],C[1]]);b.ell(12,12,5.2,5.2,n==="1"?["#C06008","#F08818","#FFB040"]:["#2A2A36","#4A4A58"]);if(n==="1")b.rect(9,9,2,2,"#FFD890");return b.outline().done();},
  charco(){const b=new Buf(26,9);b.ell(12,5,10,3,["#B8B8C8","#F2F2F8","#FFFFFF"]);b.ell(22,3,2.4,1.4,["#FFFFFF"]);b.ell(3,2,1.6,1,["#FFFFFF"]);return b.outline().done();},
  gota(){const b=new Buf(4,5);b.rect(1,0,2,4,"#FFFFFF");return b.outline().done();},
  banco(){const b=new Buf(26,20);b.rect(2,1,22,4,RP.wood[3]);b.rect(2,1,22,1,RP.wood[4]);b.rect(4,5,3,14,RP.wood[1]);b.rect(19,5,3,14,RP.wood[1]);b.rect(5,11,16,2,RP.wood[1]);return b.outline().done();}};
const cosa=(k,c)=>spr("nv"+k+(c==null?"":c),()=>(COSA[k]||COSA.plato)(c));
function tenida(c,k,x,y,ang,esc,v){const im=cosa(k,v);if(ang||esc){c.save();c.translate(R(x),R(y));if(ang)c.rotate(ang);if(esc)c.scale(esc,esc);c.drawImage(im,-(im.width>>1),-im.height);c.restore();}else c.drawImage(im,R(x)-(im.width>>1),R(y)-im.height);}
// the yard, seen in the window: the piragua cart, birds and what lies on the wall, whoever stands outside; then the frame and the sill, and what stands on the sill
function patio(c,a){const P=W.patio||{},Gt=W.gente||{},Wd=RP.wood;c.save();c.beginPath();c.rect(VEN[0],VEN[1],VEN[2],VEN[3]);c.clip();
  if(P.carrito)tenida(c,"carrito",P.carrito===1?VEN[0]+12:P.carrito,MURO+6);
  (P.cosas||[]).forEach(o=>tenida(c,o.k,o.x,MURO+1,0,0,o.v));
  (P.aves||[]).forEach((o,i)=>tenida(c,"ave",o.x,MURO+1-(o.come&&a%2?0:0),0,0,(o.come?"c":"")+(o.come&&a%2?"1":"0")));
  Object.keys(Gt).filter(id=>Gt[id]&&Gt[id].fuera&&Gt[id].vis!==0).sort((m,n)=>Gt[m].x-Gt[n].x).forEach(id=>gente(c,id,a));
  c.restore();
  fr(c,VEN[0]-2,VEN[1]-2,VEN[2]+4,2,Wd[1]);fr(c,VEN[0]-2,VEN[1],2,VEN[3],Wd[1]);fr(c,VEN[0]+VEN[2],VEN[1],2,VEN[3],Wd[1]);fr(c,VEN[0]-3,VEN[1]-3,VEN[2]+6,1,OUT);fr(c,VEN[0]-3,VEN[1]-2,1,VEN[3]+2,OUT);fr(c,VEN[0]+VEN[2]+2,VEN[1]-2,1,VEN[3]+2,OUT);
  fr(c,VEN[0]-6,SILL-1,VEN[2]+12,1,OUT);fr(c,VEN[0]-5,SILL,VEN[2]+10,4,"#F2F2F8");fr(c,VEN[0]-5,SILL+3,VEN[2]+10,1,"#B8B8C8");fr(c,VEN[0]-6,SILL+4,VEN[2]+12,1,OUT);fr(c,VEN[0]-6,SILL,1,4,OUT);fr(c,VEN[0]+VEN[2]+5,SILL,1,4,OUT);
  (W.repisa||[]).forEach(o=>{if(o.vis!==0)tenida(c,o.k,o.x,SILL+(o.dy||0),o.rot||0,o.e||0,o.v);});}
// the fridge: open (1), its inside shows; half shut (2), its door is towards us and only who stands at its side sees in; shut (0)
function nevera(c,a){const N=W.nev||{},[x,y,w,h]=NEV;
  if(W.cesta)tenida(c,"cesta",EN.cesta[0],EN.cesta[1],0,0,W.cesta.n);
  if(N.abierta===1){fr(c,x+3,y+18,w-6,h-22,"#EAF6FA");fr(c,x+3,y+18,w-6,2,"#B8D8E4");[80,106].forEach(sy=>{fr(c,x+3,sy,w-6,2,"#8AB4C8");});fr(c,x+5,112,w-10,38,"#D6ECF2");fr(c,x+5,112,w-10,1,"#8AB4C8");fr(c,x+5,149,w-10,1,"#8AB4C8");
    fr(c,x-14,y+15,14,h-15,OUT);fr(c,x-13,y+16,12,h-17,"#C8CCDA");fr(c,x-13,y+16,2,h-17,"#E8EAF2");[72,104,136].forEach(sy=>{fr(c,x-11,sy,9,2,"#8A8EA0");});
    (N.h||[]).forEach((o,i)=>{if(o&&HUECO[i])tenida(c,o.k,HUECO[i][0],HUECO[i][1],0,0,o.v);});
    const C=N.cajon||{};for(let i=0;i<(C.guineo||0);i++)tenida(c,"guineo",x+13+i*3,147-i*5);for(let i=0;i<(C.manzana||0);i++)tenida(c,"manzana",x+34+(i%2)*9,147-Math.floor(i/2)*9);
    fr(c,x+5,138,w-10,1,"#B8D8E4");}
  else{const ww=N.abierta===2?w-16:w-4;if(N.abierta===2){fr(c,x+w-14,y+17,12,h-19,"#3A4A5A");fr(c,x+w-14,y+17,3,h-19,"#EAF6FA");}fr(c,x+2,y+17,ww,h-19,"#F2F4FA");fr(c,x+2,y+17,ww,1,"#8A8EA0");fr(c,x+2,y+17,2,h-19,"#FFFFFF");fr(c,x+ww+1,y+17,1,h-19,"#8A8EA0");fr(c,x+ww-7,y+46,3,30,"#8A8EA0");fr(c,x+ww-6,y+46,1,30,"#C8CCDA");}}
const alto=id=>{const w=QUIEN[id]||{};return id==="abuela"?51:w.nino?44:56;};
const caja=id=>{const p=W.gente[id];if(!p||p.vis===0)return null;if(p.fuera)return [R(p.x)-12,VEN[1]+6,24,SILL-VEN[1]-6];const h=alto(id);return [R(p.x)-11,R(p.y)-h,22,h];};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const ob=id=>(W.cosas||[]).find(o=>o.id===id);
const porId=id=>({id,si:w=>!!(w.cosas||[]).find(o=>o.id===id&&o.vis!==0),box:w=>{const o=w.cosas.find(o=>o.id===id);return [R(o.x)-9,R(o.y)-19,18,23];},m:1,z:3});
const sinNombre=id=>Object.assign(porId(id),{m:0,z:1});
const enNevera=k=>({id:k,si:w=>!!(w.nev&&w.nev.abierta&&(w.nev.h||[]).some(o=>o&&o.k===k)),box:w=>{const i=w.nev.h.findIndex(o=>o&&o.k===k);return [HUECO[i][0]-13,HUECO[i][1]-23,26,26];},m:1,z:2});
const COSAS=Object.keys(QUIEN).map(persona).concat(["leche","queso","mantequilla"].map(enNevera)).concat(["red","mant","jarra"].map(sinNombre)).concat(["v_verde","v_amarillo","v_rojo","v_azul","t_pan","t_fruta","t_guineo","t_manzana"].map(porId)).concat([
  {id:"pan",si:w=>!!(w.mos&&w.mos.pan!=null),box:[EN.pan[0]-19,EN.pan[1]-18,38,22],m:1,z:1},
  {id:"guineo",si:w=>!!(w.mos&&w.mos.frutero&&w.mos.frutero.guineo>0),box:[EN.frutero[0]-22,EN.frutero[1]-22,15,22],m:1,z:2},
  {id:"manzana",si:w=>!!(w.mos&&w.mos.frutero&&w.mos.frutero.manzana>0),box:[EN.frutero[0]-7,EN.frutero[1]-22,14,22],m:1,z:2},
  {id:"china",si:w=>!!(w.mos&&w.mos.frutero&&w.mos.frutero.china>0),box:[EN.frutero[0]+7,EN.frutero[1]-22,15,22],m:1,z:2},
  {id:"nevera",box:[NEV[0],NEV[1],NEV[2],NEV[3]],m:0},{id:"cocina",box:[22,16,196,198],m:0}]);

/* ---------- drawing ---------- */
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  if(id==="abuela"){const ps=p.pose||"idle",top=y-50+((p.paso&&a%2)?-1:0);c.save();c.translate(x,top);if(((ps==="offer"||ps==="bless")?-d:d)<0)c.scale(-1,1);c.drawImage(spr("ab"+ps+habla,()=>mkAbuela(ps,habla)),-30,0);c.restore();
    if(p.lleva)tenida(c,p.lleva.k||p.lleva,x+d*14,y-17,0,0,p.lleva.v);if(p.bebe)tenida(c,"vaso",x+d*8,y-24-(a%2),0,0,p.bebe);if(p.alza)tenida(c,p.alza.k,x+d*(p.alza.dx||18),y-22+(p.alza.dy||0),0,p.alza.e||2,p.alza.v);if(p.come)tenida(c,p.come.k,x+d*7,y-30+(a%2),0,0,p.come.v);return;}
  const pose=p.pose||"idle",w2=p.cierra?Object.assign({},w,{dormido:1}):w,im=spr("pm"+id+pose+habla+"0"+(p.cierra?"c":""),()=>KIT.mkPersona(w2,pose,habla,0)),top=y-im.height+1+((p.paso&&a%2)?-1:0)+(p.dy||0);
  c.save();c.translate(x,top);if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  if(p.bebe&&id==="mama"){const e=p.bebe===1?"idle":p.bebe,bi=spr("bb"+e+(a%2),()=>KIT.mkBebe(e,a%2));c.drawImage(bi,x+d*2-13+d*8,y-42);}
  if(p.lleva)tenida(c,p.lleva.k||p.lleva,x+d*10,top+(w.nino?34:38),0,0,p.lleva.v);
  if(p.alza){const ax=x+d*(p.alza.dx||13),ay=top+(w.nino?30:34)+(p.alza.dy||0);tenida(c,p.alza.k||p.alza,ax,ay,0,p.alza.e||2,p.alza.v);}
  if(p.bebe&&id!=="mama")tenida(c,"vaso",x+d*6,top+(w.nino?26:30)-(a%2),0,0,p.bebe);if(p.come)tenida(c,p.come.k,x+d*6,top+22+(a%2),0,0,p.come.v);}
function nube(g,x,y,o){fr(g,x-1,y-1,28,22,OUT);fr(g,x,y,26,20,"#FFFFFF");fr(g,x+10,y+20,4,4,OUT);fr(g,x+11,y+21,2,2,"#FFFFFF");tenida(g,o.k,x+13,y+18,0,o.e||0,o.v);if(o.k2)tenida(g,o.k2,x+19,y+18,0,0,o.v2);}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui"||q.hace)&&a%2?1:0,dy=R(q.dy),cx=b.x+(b.w>>1);
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.encima)tenida(g,W.encima.k,cx,b.y+dy+3,0,0,W.encima.v);}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{},M=W.mos||{};
  c.drawImage(spr("nevera",fondo),0,0);patio(c,a);nevera(c,a);
  // the counter
  if(M.pan!=null)tenida(c,"pan",EN.pan[0],EN.pan[1],0,0,M.pan);
  if(M.frutero){const f=M.frutero,x=EN.frutero[0],y=EN.frutero[1];tenida(c,"frutero",x,y);for(let i=0;i<(f.guineo||0);i++)tenida(c,"guineo",x-14+i*2,y-5-i*4);for(let i=0;i<(f.manzana||0);i++)tenida(c,"manzana",x-1+(i%2)*4,y-5-i*5);for(let i=0;i<(f.china||0);i++)tenida(c,"china",x+13-(i%2)*4,y-5-i*5);}
  (M.vasos||[]).forEach((v,i)=>tenida(c,"vaso",v.x!=null?v.x:EN.vasos[0]-i*11,EN.vasos[1],0,0,v.de));
  (M.platos||[]).forEach((p,i)=>{const x=p.x!=null?p.x:150+i*20,y=ENC+10;tenida(c,"plato",x,y,0,2);(p.items||[]).forEach((o,j)=>tenida(c,o.k,x-5+j*10,y-3,0,0,o.v));});
  if(W.pila){fr(c,EN.pila[0]-10,ENC+3,20,6,W.pila==="j"?"#F0A040":"#DCEEF8");fr(c,EN.pila[0]-10,ENC+3,20,1,W.pila==="j"?"#C06008":"#9CC0D8");[[-7,5],[-2,4],[4,5],[7,4]].forEach(q=>fr(c,EN.pila[0]+q[0],ENC+q[1],2,2,"#FFFFFF"));}
  const L=[];
  if(W.banco)L.push({y:BANCO[1]+1,d:()=>tenida(c,"banco",BANCO[0],BANCO[1]+18)});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0&&!p.fuera)L.push({y:p.y,d:()=>gente(c,id,a)});});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>tenida(c,o.k,o.x,o.y,o.rot,o.e||0,o.v)});});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  (W.vuelos||[]).forEach(o=>tenida(c,o.k,o.x,o.y,o.rot,0,o.v));
  if(W.vista){const o=ob(W.vista.id);if(o)tenida(c,"vista",R(o.x),R(o.y)-16,0,0,o.v+":"+(o.n?1:0));}
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.piensa&&p.vis!==0)nube(c,R(p.x)-14+(p.pdx||0),R(p.y)-alto(id)-26,p.piensa);});
  if(q.vis&&q.piensa){const b=frogBox(q);nube(c,b.x+(b.w>>1)-13,b.y-24,q.piensa);}
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;if(p.fuera)return [R(p.x),R(p.y)-alto(k)-1];return [R(p.x),R(p.y)-alto(k)-1];}
function respIcon(g,k,x,y,w,h,a){g.imageSmoothingEnabled=false;}
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,66,24);   // the card steps aside while three picture bubbles stand at the top
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m){g.fillStyle=OUT;for(let k=0;k<11;k++){g.fillRect(x+k,y+1+k,4,3);g.fillRect(x+10-k,y+1+k,4,3);}g.fillStyle="#C8401E";for(let k=0;k<11;k++){g.fillRect(x+1+k,y+2+k,2,1);g.fillRect(x+11-k,y+2+k,2,1);}}
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}
const marca=m=>{const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;};

/* ---------- moving things ---------- */
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/6));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;}
async function vuela(o,x0,y0,x1,y1,n){const v=Object.assign({x:x0,y:y0},o);W.vuelos.push(v);n=n||5;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(x1-x0)*t;v.y=y0+(y1-y0)*t-Math.sin(t*Math.PI)*10;await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);}
const cx=()=>W.cq.x+16,pies=()=>W.cq.y+27;
async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(3,R(d/40))));}
const alBanco=()=>ranaA(BANCO[0],BANCO[1]);
const corre=(o,pr)=>{if(o&&o.suelto){W._mov=pr;return Promise.resolve();}return pr;};
const acts={
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async ya(){const p=W._mov;W._mov=null;if(p)await p;},
  async g(o){const p=G(o.quien);if(!p)return;Object.keys(o).forEach(k=>{if(!["act","quien","ms"].includes(k))p[k]=o[k]===""?null:o[k];});if(o.ms)await wait(+o.ms);},
  async nota(o){V[o.k]=o.v==null?"1":String(o.v);},

  /* ----- story 32: Jugo de china ----- */
  // Four metal cups: green and yellow are the children's, red and blue the grown-ups'. A cup is {id, n: 1 full, 0 empty}. The jug has four marks. Nobody sees into a metal cup from the side: a round picture shows it from above when W.vista names it.
  async inicio32(){W.gente={abuela:{x:140,y:178,dir:1},luis:{x:170,y:192,dir:-1},carmen:{x:190,y:198,dir:-1},papa:{x:164,y:PATIO,dir:1,fuera:1},mama:{x:184,y:PATIO,dir:1,fuera:1},abuelo:{x:204,y:PATIO,dir:-1,fuera:1}};
    W.nev={abierta:0,h:[]};W.cesta=null;W.patio={};W.repisa=[];W.pila="a";W.perdio=null;
    W.cosas=[{id:"red",k:"red",v:4,x:146,y:ENC+10,z:100},{id:"jarra",k:"jarra",v:3,x:162,y:ENC+10,z:100},
      {id:"v_rojo",k:"vaso",v:"rojo",x:177,y:ENC+10,z:100,n:1},{id:"v_azul",k:"vaso",v:"azul",x:187,y:ENC+10,z:100,n:0},{id:"v_verde",k:"vaso",v:"verde",x:199,y:ENC+10,z:100,n:1},{id:"v_amarillo",k:"vaso",v:"amarillo",x:210,y:ENC+10,z:100,n:0},
      {id:"pan32",k:"platopan",v:2,x:160,y:SILL,z:90},{id:"mant",k:"mantequilla",v:3,x:178,y:SILL,z:90},
      {id:"c1",k:"claro",v:0,x:60,y:NEV[1],z:90},{id:"c2",k:"claro",v:0,x:74,y:NEV[1],z:90}];},
  // abuela squeezes chinas into the jug: one (the jug is a mark higher), or todo: all that are left (the jug is full, the net empty)
  async exprime(o){const ab=G("abuela"),r=ob("red"),j=ob("jarra");const pr=(async()=>{await mueve("abuela",150,178);ab.dir=1;const n=o.todo?r.v:1;for(let i=0;i<n;i++){r.v--;ab.lleva={k:"china"};SFX.blip();await wait(300);ab.lleva={k:"china",v:"cortada"};await wait(250);ab.lleva=null;j.v=Math.min(4,j.v+(o.todo?2:1));SFX.blip();await wait(200);}if(o.todo)j.v=4;await wait(200);})();return corre(o,pr);},
  // abuela pours the last mark of the jug into the green cup
  async ultima32(){const ab=G("abuela"),j=ob("jarra"),v=ob("v_verde");ab.pose="idle";await mueve("abuela",176,180);ab.dir=1;j.vis=0;const jj={k:"jarra",v:j.v,x:v.x-8,y:v.y-13,rot:0.9};W.vuelos.push(jj);await wait(400);j.v=0;v.n=1;W.vuelos.splice(W.vuelos.indexOf(jj),1);j.vis=1;SFX.blip();await mueve("abuela",140,178);ab.dir=1;},
  // abuela butters a slice from the plate on the sill and gives it to somebody, who eats it
  async unta(o){const ab=G("abuela"),p=G(o.a),pl=ob("pan32"),m=ob("mant");const pr=(async()=>{await mueve("abuela",160,178);ab.dir=1;if(pl.v>0)pl.v--;ab.lleva={k:"rebanada"};SFX.blip();await wait(350);ab.lleva={k:"rebanada",v:"m"};SFX.blip();await wait(450);ab.lleva=null;if(p){p.come={k:"rebanada",v:"m"};await wait(+(o.ms||900));p.come=null;}pl.v=2;})();return corre(o,pr);},
  // the round picture over a cup: on, or off
  async vista(o){W.vista=o.a?{id:o.a}:null;if(o.a)SFX.blip();await wait(+(o.ms||200));},
  // the frog hops onto the counter with the jug and pours into a cup. Into a full cup the juice runs over: a puddle that stays, and a run down the cabinet or the wall. The jug is a mark lower either way
  async vierte(o){const v=ob(o.a),j=ob("jarra"),alta=v.y<ENC;const pr=(async()=>{await ranaA(j.x-12,ENC+9);j.vis=0;W.encima={k:"jarra",v:j.v};SFX.blip();await ranaA(v.x-20,ENC+9);W.encima=null;const jj={k:"jarra",v:j.v,x:v.x-8,y:v.y-13,rot:0.9};W.vuelos.push(jj);
      for(let i=0;i<3;i++){const g={k:"gotaj",x:v.x,y:v.y-12+i*2};W.vuelos.push(g);await wait(120);W.vuelos.splice(W.vuelos.indexOf(g),1);}
      if(v.n){V.der="1";W.cosas.push({k:"charcoj",x:v.x+3,y:v.y+4,z:101});W.cosas.push({k:"chorro",v:alta?ENC-SILL-4:26,x:v.x+3,y:alta?ENC:v.y+4+26,z:102});SFX.bonk();}else{v.n=1;V.der="";SFX.blip();}
      j.v=Math.max(0,j.v-1);jj.v=j.v;await wait(350);W.vuelos.splice(W.vuelos.indexOf(jj),1);W.encima={k:"jarra",v:j.v};await ranaA(j.x-12,ENC+9);W.encima=null;j.vis=1;await alBanco();})();return corre(o,pr);},
  // the children: toman (each takes his cup; bebe: that one drinks his up), dejan (they set the cups on the counter and turn to abuela), salen (out to the yard, with or without the cups), entran (in from the yard with their cups; vacio: whose is empty)
  async ninos32(o){const l=G("luis"),ca=G("carmen"),vv=ob("v_verde"),va=ob("v_amarillo"),bebe=async(p,v)=>{p.alza=null;p.bebe=v.v;SFX.blip();await wait(700);p.bebe=null;v.n=0;p.alza={k:"vaso",v:v.v,e:1,dx:10,dy:-4};};
    if(o.que==="toman"){await Promise.all([mueve("luis",188,190),mueve("carmen",208,196)]);vv.vis=0;va.vis=0;l.alza={k:"vaso",v:"verde",e:1,dx:10,dy:-4};ca.alza={k:"vaso",v:"amarillo",e:1,dx:-10,dy:-4};l.dir=-1;ca.dir=-1;SFX.blip();await wait(300);if(o.bebe==="luis")await bebe(l,vv);if(o.bebe==="carmen")await bebe(ca,va);}
    else if(o.que==="dejan"){l.alza=null;ca.alza=null;vv.vis=1;va.vis=1;vv.x=199;va.x=210;vv.y=va.y=ENC+10;SFX.blip();await wait(200);await Promise.all([mueve("luis",170,192),mueve("carmen",186,198)]);l.dir=-1;ca.dir=-1;}
    else if(o.que==="salen"){if(o.con){vv.vis=0;va.vis=0;l.alza={k:"vaso",v:"verde",e:1,dx:10,dy:-4};ca.alza={k:"vaso",v:"amarillo",e:1,dx:10,dy:-4};}await Promise.all([mueve("luis",240,192),mueve("carmen",244,198)]);l.vis=0;ca.vis=0;l.alza=null;ca.alza=null;}
    else if(o.que==="entran"){l.vis=1;ca.vis=1;l.x=240;ca.x=246;l.y=192;ca.y=198;vv.vis=0;va.vis=0;vv.n=o.vacio==="verde"?0:1;va.n=o.vacio==="amarillo"?0:1;l.alza={k:"vaso",v:"verde",e:1,dx:-10,dy:-4};ca.alza={k:"vaso",v:"amarillo",e:1,dx:-10,dy:-4};await Promise.all([mueve("luis",190,192),mueve("carmen",210,198)]);l.dir=-1;ca.dir=-1;}
    else if(o.que==="quedan"){vv.vis=1;va.vis=1;vv.x=199;va.x=210;vv.y=va.y=ENC+10;vv.n=o.vacio==="verde"?0:1;va.n=o.vacio==="amarillo"?0:1;SFX.blip();await wait(300);}},
  // mamá, at the window: trae (she sets the red cup and the blue cup on the sill and looks down into them; vacio: which is empty), va (she turns away to the yard), lleva (she carries the two cups out)
  async mama32(o){const m=G("mama"),vr=ob("v_rojo"),vz=ob("v_azul");
    if(o.que==="trae"){m.x=198;m.dir=-1;vr.vis=1;vz.vis=1;if(o.vacio){vr.n=o.vacio==="rojo"?0:1;vz.n=o.vacio==="azul"?0:1;}for(const v of [vr,vz]){const x1=v===vr?191:205;await vuela({k:"vaso",v:v.v},v.x,v.y-4,x1,SILL-2,6);v.x=x1;v.y=SILL;}SFX.blip();m.dy=2;await wait(500);m.dy=0;m.dir=1;await wait(200);}
    else if(o.que==="va"){m.dir=1;await mueve("mama",184,PATIO);m.dir=1;}
    else if(o.que==="lleva"){m.x=198;m.dir=-1;await wait(250);vr.vis=0;vz.vis=0;SFX.blip();await wait(200);m.dir=1;await mueve("mama",184,PATIO);vr.x=177;vz.x=187;vr.y=vz.y=ENC+10;}},
  // abuela looks into the green cup and the yellow one, goes to the sink and puts her hands in the dishwater, her back to the cups
  async abuelapila(o){const ab=G("abuela");await mueve("abuela",196,180);ab.dir=1;ab.paso=1;await wait(500);ab.paso=0;await mueve("abuela",128,176);ab.dir=-1;ab.pose="offer";SFX.blip();await wait(250);},
  // the frog carries a cup to abuela, who dips it in the dishwater without looking. A full one: the juice is in the dishwater. Then she washes it and it stands in its place again, empty
  async lleva32(o){const v=ob(o.a),x0=v.x,ab=G("abuela");await ranaA(v.x-18,ENC+9);v.vis=0;W.encima={k:"vaso",v:v.v};SFX.blip();await ranaA(EN.pila[0]+16,ENC+9);W.encima=null;await vuela({k:"vaso",v:v.v},EN.pila[0]+10,ENC,EN.pila[0],ENC+6,4);
    if(v.n){W.pila="j";W.perdio=v.id;V.der="1";SFX.bonk();await wait(600);}else{V.der="";SFX.blip();await wait(350);}
    v.n=0;await vuela({k:"vaso",v:v.v},EN.pila[0],ENC+4,x0,ENC+6,7);v.vis=1;v.x=x0;v.y=ENC+10;await alBanco();},
  async abuelavuelve(){const ab=G("abuela");ab.pose="idle";await mueve("abuela",140,178);ab.dir=1;},
  // whoever lost his juice in the dishwater comes to the window and looks at the sink
  async mirapila(){const id=W.perdio==="v_verde"?"luis":"carmen",p=G(id);p.vis=1;p.fuera=1;p.x=158;p.y=PATIO+8;p.dir=-1;SFX.blip();await wait(600);},
  // the ending: abuela takes the two clear glasses down and pours what is left: first into the cup of the child whose juice is gone, then into her own glass, then into the frog's
  async final32(){const ab=G("abuela"),j=ob("jarra"),c1=ob("c1"),c2=ob("c2");ab.pose="idle";await mueve("abuela",104,172);ab.dir=-1;await wait(200);c1.x=148;c2.x=136;c1.y=c2.y=ENC+10;c1.z=c2.z=100;SFX.blip();await mueve("abuela",150,178);ab.dir=1;await wait(200);
    const vierte=async(x,y)=>{j.vis=0;const jj={k:"jarra",v:j.v,x:x-8,y:y-13,rot:0.9};W.vuelos.push(jj);await wait(350);j.v--;W.vuelos.splice(W.vuelos.indexOf(jj),1);j.vis=1;SFX.blip();};
    if(W.perdio&&j.v>0){const v=ob(W.perdio);await vierte(v.x,v.y);v.n=1;W.vista={id:v.id};await wait(500);W.vista=null;}
    if(j.v>0){await vierte(c1.x,c1.y);c1.v=1;await wait(200);}
    if(j.v>0){await vierte(c2.x,c2.y);c2.v=1;await wait(200);}
    V.rana=c2.v?"1":"";c1.vis=0;ab.bebe=null;ab.lleva={k:"claro",v:c1.v};const q=W.cq;W.cosas.push({k:"claro",v:c2.v,x:cx()+22,y:pies()+2,z:400});c2.vis=0;if(c2.v)q.hace="come";await wait(700);},

  // everything at once, to look at the drawing
  async prueba(o){const n=+(o&&o.n||1);
    W.gente={abuela:{x:n===2?102:128,y:176,dir:-1},luis:{x:162,y:186,dir:1},carmen:{x:190,y:192,dir:-1,piensa:n===1?{k:"guineo"}:null},papa:{x:198,y:PATIO,dir:-1,fuera:1},mama:{x:170,y:PATIO,dir:1,fuera:1,vis:n===3?1:0}};
    W.nev={abierta:n===1?1:n===2?2:0,h:[{k:"leche",v:n===1?0:4},{k:"queso",v:2}],cajon:{guineo:3,manzana:3}};W.cesta=n===3?null:{n:4};
    W.mos=n===3?{}:{pan:4};W.patio={carrito:n===1?1:0,aves:[{x:158},{x:170,come:1}],cosas:[{k:"panecillo",x:170}]};
    W.repisa=n===1?[{k:"tarro",x:156},{k:"monedas",v:4,x:172},{k:"leche",v:4,x:190},{k:"queso",v:3,x:206}]:n===2?[{k:"bandeja",x:186,dy:1},{k:"panecillo",x:178},{k:"platofruta",v:"vieja",x:196}]:[{k:"claro",v:1,x:158},{k:"claro",v:0,x:168},{k:"vaso",v:"rojo",x:190},{k:"vaso",v:"azul",x:202}];
    W.cosas=n===2?[{k:"bolsa",v:"luis:1",x:132,y:ENC+10,z:300},{k:"bolsa",v:"carmen",x:147,y:ENC+10,z:300},{k:"bolsa",v:"coqui",x:162,y:ENC+10,z:300}]:n===3?[{k:"red",v:3,x:146,y:ENC+10,z:300},{k:"exprimidor",x:162,y:ENC+10,z:300},{k:"jarra",v:3,x:178,y:ENC+10,z:300},{k:"mantequilla",v:3,x:204,y:ENC+10,z:300},{k:"charcoj",x:150,y:204},{k:"piragua",x:60,y:200}]:[];
    W.banco=1;W.tarjeta="rondas";W.marcas=["ok","x",null];},
};
async function stake(lost,max,en){await wait(200);}
function poke(what){}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)).join(" ")+" pan="+((W.mos||{}).pan)+" marcas="+(W.marcas||[]).join(",");
KIT.escena({id:"nevera",CAM:{wide:[22,0,196,216]},heartAt:[124,24],lugar:{inicio:[BANCO[0]-16,BANCO[1]-27,1],centro:[BANCO[0]-16,BANCO[1]-27,1]},cosas:COSAS,
  fresh:()=>({respEn:[124,6],pila:null,vista:null,nev:{abierta:0,h:[]},mos:{},patio:{},repisa:[],cesta:null,gente:{},cosas:[],vuelos:[],banco:1,encima:null,tarjeta:null,marcas:null,cq:{x:BANCO[0]-16,y:BANCO[1]-27,s:1,dy:0,al:1,vis:1,bub:null,hace:null,piensa:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
