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
  guineo(v){const b=new Buf(16,10),C=v==="pardo"?["#4A2E12","#6A4A22","#8A6A32"]:v==="pelado"?["#E8DCB0","#FBF4D8","#FFFFFF"]:["#C89810","#F0C820","#FFE860"];b.cap(2,3,8,7,1.9,C);b.cap(8,7,13,3,1.9,C);b.px(1,1,"#5A3A1A");b.px(14,1,"#5A3A1A");if(v==="pelado"){b.rect(5,7,2,3,"#F0C820");b.rect(9,7,2,3,"#F0C820");}if(v==="manchas"){[[4,4],[7,6],[10,5],[12,3]].forEach(q=>{b.rect(q[0],q[1],2,2,"#20140A");});b.px(6,5,"#6A8A4A");b.px(9,6,"#6A8A4A");}return b.outline().done();},
  manzana(v){const b=new Buf(11,11);if(v==="cortada"||v==="parda"){const C=v==="parda"?["#7A5A2A","#A8845A"]:["#F0E4B8","#FFF8E0"];b.ell(3,6.5,2.6,3.6,C);b.ell(8,6.5,2.6,3.6,C);b.rect(0,4,1,5,"#C02020");b.rect(10,4,1,5,"#C02020");b.px(3,6,"#5A3A1A");b.px(8,6,"#5A3A1A");return b.outline().done();}b.ell(5.5,6.4,4.4,4,["#A01818","#D02828","#F05848"]);b.rect(5,0,1,3,"#5A3A1A");b.rect(6,1,3,2,"#48A848");b.px(3,4,"#FFB0A0");if(v==="manchas"){[[3,6],[6,8],[7,5]].forEach(q=>b.rect(q[0],q[1],2,2,"#20140A"));b.px(5,7,"#6A8A4A");}return b.outline().done();},
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
  canasta(v){const b=new Buf(44,20);b.rect(2,8,40,11,"#B07A3C");for(let x=3;x<41;x+=4)b.rect(x,8,2,11,"#8A5A2A");b.rect(1,7,42,2,"#D09A54");[8,22,36].forEach(x=>b.ell(x,8,5.4,2.4,["#5A3A1A","#7A5226"]));if(v==="tapa"){b.rect(1,3,24,5,"#C88A44");b.rect(1,3,24,1,"#E0A860");}return b.outline().done();},
  pano(){const b=new Buf(16,7);b.rect(1,1,14,5,"#FFFFFF");for(let x=1;x<15;x+=4)b.rect(x,1,2,5,"#E0403A");return b.outline().done();},
  sombrero(){const b=new Buf(18,8);b.ell(9,6,8,1.8,["#C8A860","#E8D090"]);b.ell(9,3.4,4.6,3,["#C8A860","#E8D090","#F8E8B0"]);b.rect(5,5,8,1,"#8A5A2A");return b.outline().done();},
  bandeja(){const b=new Buf(38,6);b.rect(1,2,36,3,"#9494A6");b.rect(1,2,36,1,"#C8C8D4");return b.outline().done();},
  // a coin; the tray with six dents (n coins in it); the jar with a piragua on it; a piragua; the piragua man's cart, far off
  moneda(){const b=new Buf(6,6);b.ell(3,3,2.6,2.6,["#C89010","#F0C020","#FFE870"]);return b.outline().done();},
  monedas(n){const b=new Buf(24,13);n=n==null?6:+n;b.rect(1,1,22,11,"#8A5A2A");b.rect(1,1,22,1,"#B07A3C");for(let i=0;i<6;i++){const x=5+(i%3)*7,y=4+Math.floor(i/3)*5;b.ell(x,y,2.6,2,["#5A3A1A"]);if(i<n)b.ell(x,y-0.4,2.4,1.8,["#C89010","#F0C020","#FFE870"]);}return b.outline().done();},
  piragua(n){n=n==null?1:+n;const b=new Buf(11,9+4*n),C=[["#C02040","#F04868","#FF98A8"],["#C89010","#F0C020","#FFE870"],["#2A60B0","#58A0F0","#A8D0FF"]];for(let i=0;i<6;i++)b.rect(2+Math.floor(i/2),3+4*n+i,7-2*Math.floor(i/2),1,i%2?"#F2F2F8":"#DCDCE8");for(let i=0;i<n;i++)b.ell(5.5,4*n-4*i,3.8,3.2,C[i%3]);return b.outline().done();},
  tarro(n){n=n==null?3:+n;const b=new Buf(16,19);b.rect(1,4,14,14,"#DCF2FA");b.rect(1,4,2,14,"#F2FBFF");b.rect(3,1,10,3,"#9494A6");b.rect(3,1,10,1,"#C8C8D4");b.ell(5.5,8,2.6,2,["#48A848","#78D068"]);b.px(4,7,"#20140A");b.px(6,7,"#20140A");b.ell(11,8,1.8,1.6,["#F04868"]);b.rect(10,9,3,2,"#F2F2F8");for(let i=0;i<n;i++)b.ell(8,16-i*2.4,4,1.4,["#C89010","#F0C020","#FFE870"]);return b.outline().done();},
  carta(k){const b=new Buf(14,17);b.rect(1,2,12,14,"#FFFDF0");b.rect(6,0,2,3,"#8A5A2A");if(k==="leche"){b.rect(5,6,4,8,"#FFFFFF");b.rect(6,4,2,2,"#FFFFFF");b.rect(6,3,2,1,"#3A70B0");b.frame(4,5,6,10,"#8AB4C8");}else{for(let i=0;i<8;i++){const h=2+Math.floor(i*4/7);b.rect(3+i,13-h,1,h,"#F0A010");}b.px(6,11,"#C07808");b.px(9,10,"#C07808");}return b.outline().done();},
  corteza(){const b=new Buf(12,6);b.rect(1,3,10,2,"#C07808");b.rect(1,2,2,1,"#F0A010");b.rect(9,2,2,1,"#F0A010");return b.outline().done();},
  soporte(){const b=new Buf(14,7);b.rect(1,4,12,2,"#8A8EA0");b.rect(1,1,1,4,"#8A8EA0");b.rect(12,1,1,4,"#8A8EA0");return b.done();},
  platoazul(){const b=new Buf(20,6);b.ell(10,3,9,2,["#3A70B0","#5A90D0","#8CB8E8"]);return b.outline().done();},
  carrito(){const b=new Buf(22,24);b.rect(10,2,1,12,"#5A3A1A");b.ell(10.5,3,9,2.6,["#C02040","#F04868","#FF98A8"]);b.rect(3,13,16,7,"#F2F2F8");b.rect(3,13,16,2,"#58B4EC");b.ell(7,21,2.4,2.4,["#3A3A46","#6A6A7A"]);b.ell(15,21,2.4,2.4,["#3A3A46","#6A6A7A"]);return b.outline().done();},
  // a bird on the wall: sitting (0), pecking (c0, c1)
  ave(v){const b=new Buf(11,9),pk=String(v).startsWith("c"),dn=v==="c1";b.ell(5,5,3.6,2.6,["#8A4A1A","#B8742A","#D8A050"]);b.ell(dn?8.4:8,dn?5.6:3,1.8,1.8,["#B8742A","#D8A050"]);b.rect(dn?10:10,dn?6:3,1,1,"#F0C020");b.px(dn?8:8,dn?5:2,"#20140A");b.rect(1,4,2,1,"#6A3A12");b.rect(4,8,1,1,"#F0C020");b.rect(6,8,1,1,"#F0C020");return b.outline().done();},
  // juice things: a net of chinas (n), a jug with four marks (n marks full), a clear glass (0 empty, 1 juice, leche), a puddle of juice
  red(n){const b=new Buf(18,13);n=n==null?4:+n;[[5,8],[12,8],[8,4],[14,4]].slice(0,n).forEach(q=>b.ell(q[0],q[1],3.6,3.4,["#D06808","#F08818","#FFB040"]));if(!n){b.rect(2,10,14,2,"#C8C8D4");}return b.outline().done();},
  jarra(n){const b=new Buf(23,29);n=n==null?4:+n;b.rect(3,3,13,25,"#DCF2FA");b.rect(3,3,2,25,"#F2FBFF");if(n>0)b.rect(4,27-n*5,11,n*5,"#F08818");for(let i=1;i<=4;i++)b.rect(11,27-i*5,5,1,"#4A5A6A");b.rect(16,7,3,1,"#B8D8E8");b.rect(19,8,1,11,"#B8D8E8");b.rect(16,19,3,1,"#B8D8E8");b.rect(1,3,2,2,"#DCF2FA");return b.outline().done();},
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
  Object.keys(Gt).filter(id=>Gt[id]&&Gt[id].fuera&&Gt[id].vis!==0).sort((m,n)=>Gt[m].x-Gt[n].x).forEach(id=>{gente(c,id,a);if(Gt[id].gorro)tenida(c,"sombrero",R(Gt[id].x),R(Gt[id].y)-alto(id)+6);});
  c.restore();
  fr(c,VEN[0]-2,VEN[1]-2,VEN[2]+4,2,Wd[1]);fr(c,VEN[0]-2,VEN[1],2,VEN[3],Wd[1]);fr(c,VEN[0]+VEN[2],VEN[1],2,VEN[3],Wd[1]);fr(c,VEN[0]-3,VEN[1]-3,VEN[2]+6,1,OUT);fr(c,VEN[0]-3,VEN[1]-2,1,VEN[3]+2,OUT);fr(c,VEN[0]+VEN[2]+2,VEN[1]-2,1,VEN[3]+2,OUT);
  fr(c,VEN[0]-6,SILL-1,VEN[2]+12,1,OUT);fr(c,VEN[0]-5,SILL,VEN[2]+10,4,"#F2F2F8");fr(c,VEN[0]-5,SILL+3,VEN[2]+10,1,"#B8B8C8");fr(c,VEN[0]-6,SILL+4,VEN[2]+12,1,OUT);fr(c,VEN[0]-6,SILL,1,4,OUT);fr(c,VEN[0]+VEN[2]+5,SILL,1,4,OUT);
  (W.repisa||[]).forEach(o=>{if(o.vis!==0)tenida(c,o.k,o.x,SILL+(o.dy||0),o.rot||0,o.e||0,o.v);});}
// the fridge: open (1), its inside shows; half shut (2), its door is towards us and only who stands at its side sees in; shut (0)
function nevera(c,a){const N=W.nev||{},[x,y,w,h]=NEV;
  if(W.cesta)tenida(c,"cesta",EN.cesta[0],EN.cesta[1],0,0,W.cesta.n);
  if(N.abierta===1){fr(c,x+3,y+18,w-6,h-22,"#EAF6FA");fr(c,x+3,y+18,w-6,2,"#B8D8E4");[80,106].forEach(sy=>{fr(c,x+3,sy,w-6,2,"#8AB4C8");});fr(c,x+5,112,w-10,38,"#D6ECF2");fr(c,x+5,112,w-10,1,"#8AB4C8");fr(c,x+5,149,w-10,1,"#8AB4C8");
    fr(c,x-14,y+15,14,h-15,OUT);fr(c,x-13,y+16,12,h-17,"#C8CCDA");fr(c,x-13,y+16,2,h-17,"#E8EAF2");[72,104,136].forEach(sy=>{fr(c,x-11,sy,9,2,"#8A8EA0");});
    if(N.soporte){tenida(c,"soporte",HUECO[0][0],HUECO[0][1]);tenida(c,"platoazul",HUECO[1][0],HUECO[1][1]+1);}
    (N.h||[]).forEach((o,i)=>{if(o&&HUECO[i])tenida(c,o.k,HUECO[i][0],HUECO[i][1],0,0,o.v);});
    const C=N.cajon||{};if(N.cajonver){fr(c,x+3,110,w-6,42,OUT);fr(c,x+4,111,w-8,40,"#EAF6FA");for(let i=0;i<(C.guineo||0);i++)tenida(c,"guineo",x+15,148-i*11);for(let i=0;i<(C.manzana||0);i++)tenida(c,"manzana",x+38,148-i*12);}
    else if(N.cajon){fr(c,x+5,112,w-10,38,"#F2F4FA");fr(c,x+5,112,w-10,1,"#8A8EA0");fr(c,x+5,149,w-10,1,"#8A8EA0");fr(c,x+20,118,16,3,"#8A8EA0");}}
  else{const ww=N.abierta===2?w-16:w-4;if(N.abierta===2){fr(c,x+w-14,y+17,12,h-19,"#3A4A5A");fr(c,x+w-14,y+17,3,h-19,"#EAF6FA");}fr(c,x+2,y+17,ww,h-19,"#F2F4FA");fr(c,x+2,y+17,ww,1,"#8A8EA0");fr(c,x+2,y+17,2,h-19,"#FFFFFF");fr(c,x+ww+1,y+17,1,h-19,"#8A8EA0");fr(c,x+ww-7,y+46,3,30,"#8A8EA0");fr(c,x+ww-6,y+46,1,30,"#C8CCDA");}}
const alto=id=>{const w=QUIEN[id]||{};return id==="abuela"?51:w.nino?44:56;};
const caja=id=>{const p=W.gente[id];if(!p||p.vis===0)return null;if(p.fuera)return [R(p.x)-12,VEN[1]+6,24,SILL-VEN[1]-6];const h=alto(id);return [R(p.x)-11,R(p.y)-h,22,h];};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const ob=id=>(W.cosas||[]).find(o=>o.id===id);
const porId=id=>({id,si:w=>!!(w.cosas||[]).find(o=>o.id===id&&o.vis!==0),box:w=>{const o=w.cosas.find(o=>o.id===id);return [R(o.x)-9,R(o.y)-19,18,23];},m:1,z:3});
const sinNombre=id=>Object.assign(porId(id),{m:0,z:1});
const enNevera=k=>({id:k,si:w=>!!(w.nev&&w.nev.abierta&&(w.nev.h||[]).some(o=>o&&o.k===k)),box:w=>{const i=w.nev.h.findIndex(o=>o&&o.k===k);return [HUECO[i][0]-13,HUECO[i][1]-23,26,26];},m:1,z:2});
const COSAS=Object.keys(QUIEN).map(persona).concat(["leche","queso","mantequilla"].map(enNevera)).concat(["red","mant","jarra"].map(sinNombre)).concat(["v_verde","v_amarillo","v_rojo","v_azul","t_pan","t_fruta"].map(porId)).concat([{id:"cesta",si:w=>!!w.cesta,box:[EN.cesta[0]-18,EN.cesta[1]-16,36,18],m:0},{id:"frutas",si:w=>!!(w.nev&&w.nev.abierta===1),box:[NEV[0]+4,NEV[1]+20,NEV[2]-8,48],m:0}]).concat([
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
  if(W.canasta){const K=W.canasta;tenida(c,"canasta",K.x,ENC+11,0,0,K.tapa?"tapa":null);(K.items||[]).forEach((o,i)=>{if(!(K.tapa&&i<2))tenida(c,o.k,K.x-14+i*14,ENC-1,0,0,o.v);});}
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
function respIcon(g,k,x,y,w,h,a){g.imageSmoothingEnabled=false;if(k==="c_leche")tenida(g,"leche",x+(w>>1),y+h-3,0,2,4);else if(k==="c_queso")tenida(g,"queso",x+(w>>1),y+h-5,0,2,3);}
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
// a thing flies out of the window and lands on the yard wall; a bird hops to it and pecks. What was thrown before is gone, unless it was good food (bueno): that stays with its bird
async function alMuro(o,x0,y0,bueno){const P=W.patio;P.cosas=P.cosas.filter(q=>q.bueno);P.aves.forEach(a=>{if(!a.fijo)a.come=0;});const n=P.cosas.length,x=158+n*11;await vuela(o,x0,y0,x,MURO+2,8);P.cosas.push(Object.assign({x,bueno:bueno?1:0},o));SFX.blip();
  const av=P.aves.find(a=>!a.fijo);if(av){av.x=x+7;av.come=1;if(bueno)av.fijo=1;}await wait(bueno?700:450);}
const corre=(o,pr)=>{if(o&&o.suelto){W._mov=pr;return Promise.resolve();}return pr;};
const acts={
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async ya(){const p=W._mov;W._mov=null;if(p)await p;},
  async g(o){const p=G(o.quien);if(!p)return;Object.keys(o).forEach(k=>{if(!["act","quien","ms"].includes(k))p[k]=o[k]===""?null:o[k];});if(o.ms)await wait(+o.ms);},
  async nota(o){V[o.k]=o.v==null?"1":String(o.v);},

  /* ----- story 30: No hay leche ----- */
  // The fridge has one holder for the bottle of milk and one dish for the cheese: W.nev.h[0], W.nev.h[1]. Papá, in the yard, fetches what the frog sends him for, for a coin. Whatever he brings, Luis carries to the fridge: a thing whose place is taken stays on the counter.
  async inicio30(){W.gente={abuela:{x:142,y:180,dir:1,lleva:{k:"platopan",v:2}},luis:{x:174,y:192,dir:-1},carmen:{x:190,y:198,dir:-1},mama:{x:208,y:204,dir:-1,bebe:1},papa:{x:198,y:PATIO,dir:-1,fuera:1},abuelo:{vis:0}};
    W.nev={abierta:1,soporte:1,h:[{k:"leche",v:4},{k:"queso",v:3}]};W.cesta=null;W.canasta=null;W.pila=null;W.patio={};W.repisa=[{id:"tarro",k:"tarro",v:3,x:158}];W.sobras=0;
    W.cosas=[{k:"carta",v:"leche",x:114,y:86,z:50},{k:"carta",v:"queso",x:132,y:86,z:50},{k:"pan",v:5,x:152,y:ENC+10,z:99}];},
  // the first picture: mamá fills the baby's bottle (the holder is empty); abuela lays cheese on bread for Luis
  async consume30(o){const m=G("mama"),ab=G("abuela"),l=G("luis"),N=W.nev;const pr=(async()=>{await vuela({k:"leche",v:4},HUECO[0][0],HUECO[0][1],m.x-8,m.y-34,9);N.h[0]=null;m.bebe="come";SFX.blip();await wait(900);N.h[1].v=1;await vuela({k:"queso",v:1},HUECO[1][0],HUECO[1][1],l.x,l.y-30,8);l.come={k:"rebanada",v:"q"};SFX.blip();await wait(900);l.come=null;m.bebe=1;})();return corre(o,pr);},
  // what is in the fridge now, whether we see it or not (falta: the thing that has run out)
  async setnev(o){const N=W.nev;N.h[0]=o.falta==="leche"?null:{k:"leche",v:4};N.h[1]=o.falta==="queso"?null:{k:"queso",v:3};},
  // abuela: opens the fridge wide (abre "todo"), or a little and looks in and shuts it (abre "poco"); takes the last cheese for her plate (toma); lays a coin on the sill; and goes to the door with her plate
  async sale30(o){const ab=G("abuela"),N=W.nev;ab.vis=1;ab.pose="idle";if(o.abre||o.toma){ab.lleva=null;await mueve("abuela",102,176);ab.dir=-1;if(o.abre==="poco"){N.abierta=2;SFX.blip();ab.paso=1;await wait(600);ab.paso=0;N.abierta=0;}else{N.abierta=1;SFX.blip();await wait(250);}
      if(o.toma){N.h[1]=null;SFX.blip();await wait(300);}}
    await mueve("abuela",170,180);ab.dir=1;W.repisa.push({id:"moneda",k:"moneda",x:176});SFX.blip();await wait(250);ab.lleva={k:"platopan",v:2};await mueve("abuela",216,194);ab.dir=1;},
  // the errand. The frog tosses papá the coin from the sill, or one out of his own jar when the sill is bare (carta: he holds that card up first); papá goes off and is back with the thing; Luis carries it to the fridge. Its place is empty: he puts it in. Its place is taken: he throws a hand up and stands it on the counter
  async mandado(o){const k=String(o.k).replace(/^di_|^c_/,""),pa=G("papa"),l=G("luis"),N=W.nev,i=k==="leche"?0:1,R2=W.repisa,mon=R2.find(q=>q.id==="moneda"),tar=R2.find(q=>q.id==="tarro");
    const pr=(async()=>{await ranaA(150,ENC+9);if(o.carta){W.encima={k:"carta",v:k};SFX.blip();await wait(450);}
      if(mon){R2.splice(R2.indexOf(mon),1);await vuela({k:"moneda"},mon.x,SILL-4,pa.x,SILL-22,6);}else if(tar&&tar.v>0){tar.v--;await vuela({k:"moneda"},tar.x,SILL-10,pa.x,SILL-22,8);}SFX.blip();
      pa.dir=1;await mueve("papa",236,PATIO);W.encima=null;await alBanco();await wait(300);pa.alza={k,v:k==="leche"?4:3,e:1,dx:-10,dy:-8};await mueve("papa",198,PATIO);pa.dir=-1;
      await mueve("luis",190,190);pa.alza=null;await vuela({k,v:k==="leche"?4:3},pa.x-8,SILL-10,l.x,l.y-34,5);l.alza={k,v:k==="leche"?4:3,e:1,dx:-9,dy:-4};SFX.blip();await mueve("luis",124,180);l.dir=-1;const antes=N.abierta;N.abierta=1;SFX.blip();await wait(350);
      if(!N.h[i]){l.alza=null;await vuela({k,v:k==="leche"?4:3},l.x-10,l.y-30,HUECO[i][0],HUECO[i][1],5);N.h[i]={k,v:k==="leche"?4:3};V.puso="1";SFX.blip();await wait(300);if(antes!==1)N.abierta=0;}
      else{V.puso="";l.pose="wave0";SFX.bonk();await wait(600);l.pose="idle";l.alza=null;W.cosas.push({id:"sobra",k,v:k==="leche"?4:3,x:186+W.sobras*14,y:ENC+10,z:300});await wait(300);}
      await mueve("luis",174,192);l.dir=-1;})();return corre(o,pr);},
  // mamá and the children share out what stands on the counter: its empty bottle, or its rind, stays there
  async comparten(){const t=ob("sobra");if(!t)return;const m=G("mama"),ca=G("carmen");if(t.k==="leche"){m.bebe="come";ca.bebe="carmen";}else{ca.come={k:"queso",v:1};G("luis").come={k:"queso",v:1};}SFX.blip();await wait(900);m.bebe=1;ca.bebe=null;ca.come=null;G("luis").come=null;t.id=null;if(t.k==="leche")t.v=0;else{t.k="corteza";t.v=null;}W.sobras++;},
  // the turn: the piragua man's cart; the frog hops to his jar; abuela shows the three coins she has left
  async turno30(){W.patio.carrito=1;SFX.right&&SFX.blip();await wait(400);await ranaA(150,ENC+9);const t=W.repisa.find(q=>q.id==="tarro");for(let i=0;i<3;i++){t.dy=-2;await wait(110);t.dy=0;await wait(110);}await alBanco();const ab=G("abuela");ab.pose="offer";ab.lleva={k:"moneda"};await wait(700);ab.pose="idle";ab.lleva={k:"platopan",v:2};},
  // the ending: the frog tosses papá the coins left in his jar; papá buys a piragua at the cart: one scoop for each coin
  async final30(){const pa=G("papa"),t=W.repisa.find(q=>q.id==="tarro"),n=t.v;V.pir=n>0?"1":"";await ranaA(150,ENC+9);for(let i=0;i<n;i++){t.v--;await vuela({k:"moneda"},t.x,SILL-10,pa.x,SILL-22,5);SFX.blip();}
    if(n>0){pa.dir=-1;await mueve("papa",170,PATIO);await wait(500);pa.alza={k:"piragua",v:n,e:1,dx:10,dy:-8};pa.dir=1;await mueve("papa",198,PATIO);pa.dir=-1;await wait(200);pa.alza=null;await vuela({k:"piragua",v:n},pa.x-8,SILL-12,170,ENC+2,6);await alBanco();W.cosas.push({k:"piragua",v:n,x:cx()+24,y:pies()+2,z:400});W.cq.hace="come";SFX.blip();}
    else{await alBanco();W.cq.dy=2;}await wait(600);},

  /* ----- story 31: Para los pájaros ----- */
  // The tray stands on the counter under the window: two places. What the frog or abuelo throws out lands on the yard wall, and a bird comes to it. A good thing thrown out stays there with its bird to the end (bueno); an old one is gone by the next throw.
  async inicio31(){W.gente={abuela:{x:102,y:176,dir:-1},luis:{x:160,y:194,dir:1},carmen:{x:176,y:200,dir:1},abuelo:{x:204,y:PATIO,dir:-1,fuera:1},mama:{vis:0},papa:{vis:0}};
    W.nev={abierta:1,h:[{k:"platofruta"},{k:"platofruta"},{k:"platofruta"},null],cajon:{guineo:3,manzana:3}};W.cesta={n:3};W.canasta={x:150,items:[]};W.pila=null;
    W.patio={aves:[{x:156},{x:166}],cosas:[]};W.repisa=[];W.cosas=[{k:"bandeja",x:190,y:ENC+11,z:99}];},
  // abuela pulls the drawer out and tips it towards us (ver), or pushes it shut
  async cajon31(o){const ab=G("abuela");const pr=(async()=>{await mueve("abuela",102,176);ab.dir=-1;W.nev.cajonver=o.ver?1:0;SFX.blip();await wait(+(o.ms||300));})();return corre(o,pr);},
  // abuela sets a roll and a plate of fruit on the tray. viejo: which of the two is old; izq: which stands at the left
  async lote(o){const ab=G("abuela"),xs=o.izq==="fruta"?{fruta:181,pan:199}:{pan:181,fruta:199};ab.pose="idle";await mueve("abuela",102,176);const i=W.nev.h.findIndex(q=>q);if(i>=0)W.nev.h[i]=null;if(W.cesta.n>0)W.cesta.n--;ab.lleva={k:"platofruta"};SFX.blip();await mueve("abuela",186,178);ab.lleva=null;
    W.cosas.push({id:"t_pan",k:"panecillo",x:xs.pan,y:ENC+9,z:300,viejo:o.viejo==="pan"});W.cosas.push({id:"t_fruta",k:"platofruta",x:xs.fruta,y:ENC+10,z:300,viejo:o.viejo==="fruta"});SFX.blip();await wait(250);},
  // abuela bends over the tray and smells without lifting: one thing (a), or both, one after the other (orden: which first)
  async huele31(o){const ab=G("abuela"),ids=o.a?["t_"+o.a]:(String(o.orden)==="2"?["t_fruta","t_pan"]:["t_pan","t_fruta"]);const pr=(async()=>{ab.lleva=o.pano?{k:"pano"}:null;for(const id of ids){const t=ob(id);await mueve("abuela",t.x-2,160);ab.dir=1;ab.paso=1;await wait(500);ab.paso=0;await wait(150);}await mueve("abuela",166,182);ab.dir=-1;})();return corre(o,pr);},
  // the frog hops onto the counter and tosses a thing from the tray out of the window onto the wall; a bird has it
  async tira31(o){const t=ob(o.a);const pr=(async()=>{await ranaA(t.x-22,ENC+9);t.vis=0;await alMuro({k:t.k,v:t.v},t.x,t.y-6,!!o.bueno);W.cosas.splice(W.cosas.indexOf(t),1);await alBanco();})();return corre(o,pr);},
  // abuela gives what is left on the tray to a child, who eats it; or (guarda) lays it in the picnic basket; or (voltea) turns it over: spots
  async resto31(o){const ab=G("abuela"),t=(W.cosas||[]).find(q=>q.id==="t_pan"||q.id==="t_fruta");if(!t)return;const pr=(async()=>{ab.lleva=null;await mueve("abuela",t.x-6,178);ab.dir=1;
      if(o.voltea){ab.pose="wave0";SFX.bonk();await wait(450);ab.pose="idle";t.v=t.k==="panecillo"?"viejo":"vieja";await wait(500);return;}
      W.cosas.splice(W.cosas.indexOf(t),1);ab.lleva={k:t.k};SFX.blip();
      if(o.guarda){await mueve("abuela",152,180);ab.lleva=null;W.canasta.items.push({k:t.k});SFX.blip();await wait(250);}
      else{const p=G(o.a);await mueve("abuela",p.x-16,p.y-4);ab.lleva=null;p.come={k:t.k};SFX.blip();await wait(900);p.come=null;}})();return corre(o,pr);},
  // abuela takes a guineo and a manzana out of the drawer; Luis holds one and Carmen the other (luis: which Luis holds)
  async sostienen(o){const ab=G("abuela"),l=G("luis"),ca=G("carmen"),C=W.nev.cajon,kl=o.luis,kc=kl==="guineo"?"manzana":"guineo";ab.pose="idle";ab.lleva=null;
    if(!o.ya){await mueve("abuela",102,176);ab.dir=-1;await wait(250);}C.guineo--;C.manzana--;SFX.blip();if(!o.ya)await mueve("abuela",148,186);l.alza={k:kl,e:1,dx:10,dy:-2};ca.alza={k:kc,e:1,dx:10,dy:-2};l.dir=1;ca.dir=1;SFX.blip();await wait(250);},
  // she bends to the hands of one, then of the other (orden: which first), and turns to the picnic basket
  async huelemanos(o){const ab=G("abuela"),ids=String(o.orden)==="2"?["carmen","luis"]:["luis","carmen"];for(const id of ids){const p=G(id);await mueve("abuela",p.x+16,p.y-2);ab.dir=-1;ab.paso=1;await wait(500);ab.paso=0;await wait(150);}await mueve("abuela",146,182);ab.dir=1;},
  // the frog takes the fruit out of a child's hands and tosses it out of the window
  async quita(o){const p=G(o.a),f=p.alza;if(!f)return;await ranaA(p.x-18,p.y+2);p.alza=null;SFX.blip();await alMuro({k:f.k,v:f.v},p.x+8,p.y-30,!!o.bueno);await alBanco();},
  // a child: eats the fruit in his hands (come), lays it in the picnic basket (guarda), or turns it over: black spots (manchas)
  async nino31(o){const p=G(o.a),f=p.alza;if(!f)return;const pr=(async()=>{if(o.manchas){p.pose="wave0";SFX.bonk();await wait(400);p.pose="idle";f.v="manchas";await wait(500);return;}
      if(o.guarda){await mueve(o.a,170,196);p.alza=null;W.canasta.items.push({k:f.k});SFX.blip();await wait(250);return;}
      p.alza=null;p.come={k:f.k};SFX.blip();await wait(900);p.come=null;})();return corre(o,pr);},
  // abuelo, in the yard at the window: trae (he lays a guineo and a manzana on the sill; viejo: the one with black spots on our side), tira (he tosses the one named to the birds), come (he eats the one that is left), da (he hands it in and abuela lays it in the picnic basket), mira (he turns the one that is left: spots)
  async abuelo31(o){const ao=G("abuelo"),R2=W.repisa,k=String(o.k||"").replace(/^di_/,""),it=R2.find(q=>q.id==="s_"+k);
    if(o.que==="trae"){ao.x=204;ao.dir=-1;ao.alza=null;W.repisa=[{id:"s_guineo",k:"guineo",v:o.viejo==="guineo"?"manchas":null,x:180,viejo:o.viejo==="guineo"},{id:"s_manzana",k:"manzana",v:o.viejo==="manzana"?"manchas":null,x:193,viejo:o.viejo==="manzana"}];SFX.blip();await wait(400);}
    else if(o.que==="alza"){ao.alza={k:"guineo",e:1,dx:-9,dy:-22};ao.lleva={k:"manzana"};SFX.blip();await wait(300);}
    else if(o.que==="tira"){R2.splice(R2.indexOf(it),1);ao.pose="wave0";await alMuro({k:it.k,v:it.viejo?"manchas":null},it.x,SILL-8,!it.viejo);ao.pose="idle";}
    else if(o.que==="come"){const r=R2[0];if(!r)return;const pr=(async()=>{W.repisa=[];ao.come={k:r.k};SFX.blip();await wait(900);ao.come=null;})();return corre(o,pr);}
    else if(o.que==="da"){const r=R2[0];if(!r)return;const ab=G("abuela");ab.lleva=null;await mueve("abuela",184,178);W.repisa=[];ab.lleva={k:r.k};SFX.blip();await mueve("abuela",152,180);ab.lleva=null;W.canasta.items.push({k:r.k});SFX.blip();await wait(250);}
    else if(o.que==="mira"){ao.pose="wave0";SFX.bonk();await wait(700);ao.pose="idle";}},
  async abuelaa31(o){const ab=G("abuela");ab.pose="idle";ab.lleva=o.pano?{k:"pano"}:null;await mueve("abuela",146,182);ab.dir=1;},
  // the turn: abuelo puts his hat on; three more birds; the three last lots come out, one for each hollow: the last roll and plate on the tray (izq, viejo), the last guineo and manzana out of the drawer into the children's hands (luis), and the two abuelo holds up
  async turno31(o){const ao=G("abuelo"),P=W.patio;ao.gorro=1;SFX.blip();await wait(300);for(const x of [176,186,196])if(P.aves.length<5){P.aves.push({x});SFX.blip();await wait(140);}},
  async lotes31(o){await acts.lote({viejo:o.viejo,izq:o.izq});const ab=G("abuela");await mueve("abuela",102,176);ab.dir=-1;W.nev.cajonver=1;SFX.blip();await wait(500);await acts.sostienen({luis:o.luis,ya:1});await wait(300);W.nev.cajonver=0;await acts.abuelo31({que:"alza"});await mueve("abuela",146,182);ab.dir=1;},
  // the ending: the lid half shut; Luis carries the picnic basket, and they go
  async final31(){const ab=G("abuela"),l=G("luis"),ca=G("carmen"),K=W.canasta;ab.lleva=null;l.alza=null;ca.alza=null;await mueve("abuela",146,182);K.tapa=1;SFX.blip();await wait(700);if(K.items.length<3){await mueve("luis",166,192);l.dir=-1;l.dy=2;await wait(700);l.dy=0;}await wait(300);},

  /* ----- story 32: Jugo de china ----- */
  // Four metal cups: green and yellow are the children's, red and blue the grown-ups'. A cup is {id, n: 1 full, 0 empty}. The jug has four marks. Nobody sees into a metal cup from the side: a round picture shows it from above when W.vista names it.
  async inicio32(){W.gente={abuela:{x:140,y:180,dir:1},luis:{x:166,y:192,dir:-1},carmen:{x:184,y:198,dir:-1},papa:{x:160,y:PATIO,dir:1,fuera:1},abuelo:{x:176,y:PATIO,dir:-1,fuera:1},mama:{x:200,y:PATIO,dir:-1,fuera:1}};
    W.nev={abierta:0,h:[]};W.cesta=null;W.patio={};W.repisa=[];W.pila="a";W.perdio=null;
    W.cosas=[{id:"red",k:"red",v:4,x:144,y:ENC+10,z:100},{id:"jarra",k:"jarra",v:3,x:160,y:ENC+10,z:100},
      {id:"v_rojo",k:"vaso",v:"rojo",x:175,y:ENC+10,z:100,n:1},{id:"v_azul",k:"vaso",v:"azul",x:185,y:ENC+10,z:100,n:0},{id:"v_verde",k:"vaso",v:"verde",x:196,y:ENC+10,z:100,n:1},{id:"v_amarillo",k:"vaso",v:"amarillo",x:206,y:ENC+10,z:100,n:0},
      {id:"pan32",k:"platopan",v:2,x:160,y:SILL,z:90},{id:"mant",k:"mantequilla",v:3,x:178,y:SILL,z:90},
      {id:"c1",k:"claro",v:0,x:60,y:NEV[1],z:90},{id:"c2",k:"claro",v:0,x:74,y:NEV[1],z:90}];},
  // abuela squeezes a china into the jug (one mark more); todo: the last ones: she fills the green cup and the yellow cup, and the jug to its fourth mark; the net is empty
  async exprime(o){const ab=G("abuela"),r=ob("red"),j=ob("jarra");const pr=(async()=>{ab.pose="idle";await mueve("abuela",148,180);ab.dir=1;const n=o.todo?r.v:1;for(let i=0;i<n;i++){r.v--;ab.lleva={k:"china"};SFX.blip();await wait(280);ab.lleva={k:"china",v:"cortada"};await wait(220);ab.lleva=null;if(!o.todo)j.v=Math.min(4,j.v+1);SFX.blip();await wait(150);}
      if(o.todo){for(const id of ["v_verde","v_amarillo"]){const v=ob(id);v.vis=1;v.x=id==="v_verde"?196:206;v.y=ENC+10;v.n=1;SFX.blip();await wait(200);}j.v=4;SFX.blip();}await wait(200);})();return corre(o,pr);},
  // abuela butters a slice from the plate on the sill and gives it to somebody, who eats it
  async unta(o){const ab=G("abuela"),p=G(o.a),pl=ob("pan32");const pr=(async()=>{await mueve("abuela",158,180);ab.dir=1;if(pl.v>0)pl.v--;ab.lleva={k:"rebanada"};SFX.blip();await wait(350);ab.lleva={k:"rebanada",v:"m"};SFX.blip();await wait(450);ab.lleva=null;if(p){p.come={k:"rebanada",v:"m"};await wait(+(o.ms||900));p.come=null;}pl.v=2;await mueve("abuela",140,180);ab.dir=1;})();return corre(o,pr);},
  // the round picture over a cup: on, or off
  async vista(o){W.vista=o.a?{id:o.a}:null;if(o.a)SFX.blip();await wait(+(o.ms||200));},
  // the frog hops onto the counter and tips the big jug from behind it: he cannot see into the cup. Into a full cup the juice runs over: a puddle beside the cup and one under it, with drops between. They stay. The jug is a mark lower either way
  async vierte(o){const v=ob(o.a),j=ob("jarra"),alta=v.y<ENC;const pr=(async()=>{await ranaA(j.x-16,ENC+9);j.vis=0;W.encima={k:"jarra",v:j.v};SFX.blip();await ranaA(v.x-26,ENC+9);W.encima=null;const jj={k:"jarra",v:j.v,x:v.x-12,y:v.y-10,rot:0.8};W.vuelos.push(jj);
      for(let i=0;i<3;i++){const g={k:"gotaj",x:v.x,y:v.y-12+i*2};W.vuelos.push(g);await wait(120);W.vuelos.splice(W.vuelos.indexOf(g),1);}
      if(v.n){V.der="1";const y2=alta?ENC+11:PISO+16;W.cosas.push({k:"charcoj",x:v.x+4,y:v.y+4,z:101});[0.35,0.7].forEach(t=>W.cosas.push({k:"gotaj",x:v.x+8,y:R(v.y+4+(y2-v.y-10)*t),z:500}));W.cosas.push({k:"charcoj",x:v.x+6,y:y2,z:alta?101:1});SFX.bonk();}else{v.n=1;V.der="";SFX.blip();}
      j.v=Math.max(0,j.v-1);jj.v=j.v;await wait(350);W.vuelos.splice(W.vuelos.indexOf(jj),1);W.encima={k:"jarra",v:j.v};await ranaA(j.x-16,ENC+9);W.encima=null;j.vis=1;await alBanco();})();return corre(o,pr);},
  // the children: toman (each takes his cup; bebe: that one drinks his up), dejan (they set the cups on the counter and take bread in both hands, their backs to the cups), salen (out of the door, con: with the cups), entran (in at the door with their cups; vacio: whose is empty), corren (they set the cups down and run out)
  async ninos32(o){const l=G("luis"),ca=G("carmen"),vv=ob("v_verde"),va=ob("v_amarillo"),AL={k:"vaso",v:"verde",e:1,dx:10,dy:-4},AC={k:"vaso",v:"amarillo",e:1,dx:10,dy:-4},
      pon=()=>{l.alza=null;ca.alza=null;vv.vis=1;va.vis=1;vv.x=196;va.x=206;vv.y=va.y=ENC+10;SFX.blip();},bebe=async(p,v,A)=>{p.alza=null;p.bebe=v.v;SFX.blip();await wait(700);p.bebe=null;v.n=0;p.alza=A;};
    if(o.que==="toman"){l.alza=null;ca.alza=null;await Promise.all([mueve("luis",186,190),mueve("carmen",206,198)]);vv.vis=0;va.vis=0;l.alza=AL;ca.alza=AC;l.dir=1;ca.dir=1;SFX.blip();await wait(300);if(o.bebe==="luis")await bebe(l,vv,AL);if(o.bebe==="carmen")await bebe(ca,va,AC);}
    else if(o.que==="dejan"){pon();await wait(200);await Promise.all([mueve("luis",164,192),mueve("carmen",180,198)]);l.dir=-1;ca.dir=-1;l.alza={k:"rebanada",v:"m",e:1,dx:8,dy:-2};ca.alza={k:"rebanada",v:"m",e:1,dx:8,dy:-2};}
    else if(o.que==="salen"){if(o.con){vv.vis=0;va.vis=0;l.alza=AL;ca.alza=AC;}await Promise.all([mueve("luis",240,192),mueve("carmen",246,198)]);l.vis=0;ca.vis=0;l.alza=null;ca.alza=null;}
    else if(o.que==="entran"){l.vis=1;ca.vis=1;l.fuera=0;ca.fuera=0;l.x=240;ca.x=250;l.y=190;ca.y=198;vv.vis=0;va.vis=0;vv.n=o.vacio==="verde"?0:1;va.n=o.vacio==="amarillo"?0:1;l.alza=Object.assign({},AL,{dx:-10});ca.alza=Object.assign({},AC,{dx:-10});await Promise.all([mueve("luis",186,190),mueve("carmen",206,198)]);}
    else if(o.que==="corren"){pon();await wait(250);await Promise.all([mueve("luis",240,190),mueve("carmen",246,198)]);l.vis=0;ca.vis=0;}},
  // mamá, at the window: trae (she sets the red cup and the blue cup on the sill, looks down into them, and turns her face away; vacio: which is empty), lleva (she carries out the cups that stand on the sill)
  async mama32(o){const m=G("mama"),vr=ob("v_rojo"),vz=ob("v_azul");
    if(o.que==="trae"){m.x=200;m.dir=-1;vr.vis=1;vz.vis=1;if(o.vacio){vr.n=o.vacio==="rojo"?0:1;vz.n=o.vacio==="azul"?0:1;}for(const v of [vr,vz]){const x1=v===vr?192:206;if(v.y>SILL)await vuela({k:"vaso",v:v.v},v.x,v.y-4,x1,SILL-2,6);v.x=x1;v.y=SILL;}SFX.blip();m.dy=2;await wait(500);m.dy=0;m.dir=1;await wait(200);}
    else if(o.que==="lleva"){m.dir=-1;await wait(250);vr.vis=0;vz.vis=0;SFX.blip();await wait(200);m.dir=1;await wait(300);}},
  // abuela looks into the green cup and the yellow one; then she turns to the bread, or (sale) goes to the door with a plate of bread, her back to the cups
  async abuelamira(o){const ab=G("abuela");ab.vis=1;ab.pose="idle";await mueve("abuela",200,184);ab.dir=1;ab.paso=1;await wait(550);ab.paso=0;if(o.sale){ab.lleva={k:"platopan",v:2};await mueve("abuela",216,196);ab.dir=1;}else{await mueve("abuela",158,180);ab.dir=-1;}await wait(150);},
  async abuelasale(){const ab=G("abuela");if(ab.vis===0)return;await mueve("abuela",244,196);ab.vis=0;ab.lleva=null;},
  async abuelavuelve(){const ab=G("abuela");if(ab.vis===0){ab.vis=1;ab.x=244;ab.y=196;}ab.lleva=null;ab.pose="idle";await mueve("abuela",140,180);ab.dir=1;},
  // the frog carries a cup to the sink and tips it over the dishwater. A full one: the juice is in the dishwater. The cup goes in to be washed
  async lleva32(o){const v=ob(o.a);await ranaA(v.x-20,ENC+9);v.vis=0;W.encima={k:"vaso",v:v.v};SFX.blip();await ranaA(EN.pila[0]+22,ENC+9);W.encima=null;const vv={k:"vaso",v:v.v,x:EN.pila[0]+8,y:ENC+2,rot:-1.9};W.vuelos.push(vv);await wait(250);
    if(v.n){for(let i=0;i<4;i++){const g={k:"gotaj",x:EN.pila[0]+1,y:ENC+2+i};W.vuelos.push(g);await wait(110);W.vuelos.splice(W.vuelos.indexOf(g),1);}W.pila="j";W.perdio=v.id;V.der="1";SFX.bonk();await wait(500);}else{V.der="";SFX.blip();await wait(400);}
    v.n=0;W.vuelos.splice(W.vuelos.indexOf(vv),1);await alBanco();},
  // whoever lost his juice in the dishwater comes to the window and looks in
  async mirapila(){const id=W.perdio==="v_verde"?"luis":"carmen",p=G(id);p.vis=1;p.fuera=1;p.alza=null;p.x=158;p.y=PATIO+8;p.dir=1;SFX.blip();await wait(600);},
  // the ending: abuela takes the two clear glasses down and pours what is left: first into the cup of the child whose juice is gone, then into her own glass, then into the frog's
  async final32(){const ab=G("abuela"),j=ob("jarra"),c1=ob("c1"),c2=ob("c2");await mueve("abuela",102,174);ab.dir=-1;await wait(200);c1.x=132;c2.x=143;c1.y=c2.y=ENC+10;c1.z=c2.z=100;SFX.blip();await mueve("abuela",146,180);ab.dir=1;await wait(200);
    const vierte=async(x,y)=>{j.vis=0;const jj={k:"jarra",v:j.v,x:x+12,y:y-10,rot:-0.8};W.vuelos.push(jj);await wait(400);j.v--;W.vuelos.splice(W.vuelos.indexOf(jj),1);j.vis=1;SFX.blip();};
    if(W.perdio&&j.v>0){const v=ob(W.perdio);v.vis=1;v.x=W.perdio==="v_verde"?196:206;v.y=ENC+10;await vierte(v.x-24,v.y);v.n=1;W.vista={id:v.id};await wait(600);W.vista=null;}
    if(j.v>0){await vierte(c1.x,c1.y);c1.v=1;await wait(200);}
    if(j.v>0){await vierte(c2.x,c2.y);c2.v=1;await wait(200);}
    V.rana=c2.v?"1":"";c1.vis=0;ab.lleva={k:"claro",v:c1.v};W.cosas.push({k:"claro",v:c2.v,x:cx()+24,y:pies()+2,z:400});c2.vis=0;if(c2.v)W.cq.hace="come";await wait(700);},

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
  fresh:()=>({respEn:[124,6],canasta:null,pila:null,vista:null,nev:{abierta:0,h:[]},mos:{},patio:{},repisa:[],cesta:null,gente:{},cosas:[],vuelos:[],banco:1,encima:null,tarjeta:null,marcas:null,cq:{x:BANCO[0]-16,y:BANCO[1]-27,s:1,dy:0,al:1,vis:1,bub:null,hace:null,piensa:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
