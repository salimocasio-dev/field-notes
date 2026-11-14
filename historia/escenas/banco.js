"use strict";
/* ============================================================
   Coquí · scene "El banco": the benches in the park (place 2, El parque).
   A paved corner: three wooden benches in a row, facing us; grass and
   trees behind; on the left a cart with an umbrella, where a man sells
   piraguas (shaved ice in paper cones) and water; a lamp post, and a
   wire across the top where the pigeons sit.
   People live in W.gente, by name: {x,y (feet), pose, dir, sent (sitting),
   vis, animo (contento, cansado, triste), lleva (held low), hace (come,
   bebe: held at the mouth), sin (what he has left behind: sombrero...)}.
   Pigeons in W.palomas: {x,y, pose (come, vuela), dir}. Things lying
   about in W.cosas: {k, x,y}. Dogs in W.perros, by name: {x,y, pose, dir,
   lleva}. The pushchair in W.coche: {x,y, capota, bebe, tiembla}.
   Every story set here uses this drawing.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round,P=KIT.PIEL,H=KIT.PELO;
const tarjeta=KIT.tarjeta,mano=KIT.mano;
const SUELO=132,BANCOS=[[96,150],[144,150],[192,150]],CARRO=[47,178],FAROL=[168,154],PORTON=[188,197];   // where the paving starts; the three benches (the middle of the seat); the cart; the lamp post; where one stands at the gate
const cableY=x=>R(50+7*(1-Math.pow((x-120)/98,2)));                                                    // the wire sags in the middle
const CABLE=i=>[66+i*17,cableY(66+i*17)];                                                              // where the pigeons sit on it
const RESP=i=>[BANCOS[i][0],BANCOS[i][1]-23];                                                          // the top of the back of a bench
// the people. extra: what is drawn over the kit's figure so that each one is his own
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,abuela:{},
  hombre:{piel:P.b,pelo:H.negro,peinado:"corto",ropa:RP.blue,abajo:RP.grey,extra:["barba"]},
  mujer:{piel:P.c,pelo:H.negro,peinado:"largo",ropa:RP.yel,falda:1,zapato:"#7A4A10"},
  senor:{piel:P.a,pelo:H.blanco,peinado:"corto",ropa:RP.wood,abajo:RP.grey,bigote:1,extra:["sombrero","baston"]},
  joven:{piel:P.b,pelo:H.castano,peinado:"corto",ropa:RP.cream.slice(1),abajo:RP.blue,extra:["gorra","mochila"],zapato:"#F2F2F8"},
  senora:{piel:P.a,pelo:H.castano,peinado:"corto",ropa:RP.grn,falda:1,extra:["cola"],zapato:"#F2F2F8"},
  piraguero:{piel:P.a,pelo:H.negro,peinado:"calvo",ropa:["#C8C8D4","#E8E8F0","#FFFFFF","#FFFFFF"],abajo:RP.wood,bigote:1,extra:["delantal"]}};

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),G=RP.grn,Wd=RP.wood;
  sky(b,SW,96);grass(b,92,SW,SUELO+1);
  // trees behind the benches
  [[40,98],[122,94],[218,98]].forEach(p=>{b.rect(p[0]-3,p[1],6,34,Wd[1]);b.rect(p[0]-3,p[1],2,34,Wd[3]);b.ell(p[0],p[1]-10,24,17,[OUT]);b.ell(p[0],p[1]-10,23,16,G);b.ell(p[0]-8,p[1]-15,9,5,[G[3],G[4]]);});
  // the paving: big pale flags
  for(let y=SUELO;y<SH;y++)for(let x=0;x<SW;x++){const fy=Math.floor((y-SUELO)/14),fx=Math.floor((x+(fy%2)*12)/24),ed=((y-SUELO)%14===0)||((x+(fy%2)*12)%24===0);b.px(x,y,ed?"#B8AE98":hs(fx*7+3,fy*5+1)<60?"#E2DAC6":hs(x>>1,y>>1)<6?"#CEC6B0":"#D8D0BA");}
  for(let x=0;x<SW;x++){b.px(x,SUELO,"#8A8270");b.px(x,SUELO-1,G[0]);}
  // the lamp post, behind the benches, and a pole at the left; the wire between them and on to the edge
  b.rect(FAROL[0]-1,48,3,FAROL[1]-44,"#3A3A46");b.rect(FAROL[0]-4,FAROL[1]+3,9,3,"#3A3A46");b.rect(FAROL[0]-5,36,11,11,"#FFE98C");b.frame(FAROL[0]-6,35,13,13,"#3A3A46");b.rect(FAROL[0]-4,33,9,2,"#3A3A46");
  b.rect(21,48,3,90,"#3A3A46");
  for(let x=22;x<SW;x++){b.px(x,cableY(x),"#3A3A46");}
  // the benches: a back, a seat, legs
  BANCOS.forEach(q=>{const x=q[0]-21,y=q[1];b.rect(x+2,y-22,2,34,Wd[0]);b.rect(x+38,y-22,2,34,Wd[0]);[y-22,y-16,y-10].forEach(yy=>{b.rect(x,yy,42,4,Wd[2]);b.rect(x,yy,42,1,Wd[4]);b.rect(x,yy+3,42,1,Wd[1]);});b.rect(x-1,y-3,44,5,Wd[3]);b.rect(x-1,y-3,44,1,Wd[4]);b.rect(x-1,y+1,44,1,Wd[1]);b.frame(x-2,y-4,46,7,OUT);b.frame(x-1,y-23,44,17,OUT);b.rect(x+3,y+3,3,9,Wd[0]);b.rect(x+36,y+3,3,9,Wd[0]);});
  // the hedge along the right edge, and the gate in it: the way home. Two stone posts with a ball on top; the paving runs out between them
  for(let y=160;y<SH;y++)for(let x=203;x<SW;x++){if(y>180&&y<200)continue;b.px(x,y,x===203||y===160?OUT:hs(x,y)<20?G[4]:hs(x+3,y)<34?G[0]:hs(x,y+5)<50?G[1]:G[2]);}
  [[160,20],[198,16]].forEach(q=>{b.rect(197,q[0],8,q[1],"#D8D0BA");b.rect(197,q[0],2,q[1],"#F2ECDA");b.rect(203,q[0],2,q[1],"#A89E88");b.frame(196,q[0]-1,10,q[1]+2,OUT);b.rect(195,q[0]-3,12,3,"#A89E88");b.frame(194,q[0]-4,14,5,OUT);b.ell(201,q[0]-7,3.4,3.4,[OUT]);b.ell(201,q[0]-7,2.6,2.6,["#A89E88","#D8D0BA","#F2ECDA"]);});
  for(let y=181;y<200;y++)for(let x=206;x<SW;x++)b.px(x,y,hs(x>>1,y>>1)<8?"#CEC6B0":"#D8D0BA");
  return b.done();}
// the piragua cart: a box on two wheels, a block of ice, bottles of syrup, an umbrella
function mkCarro(cerrado){const b=new Buf(48,74),Wd=RP.wood;b.rect(23,14,2,34,"#6E6E80");
  if(cerrado){b.rect(21,2,6,26,"#E0483A");b.rect(23,2,2,26,"#F2F2F8");b.frame(20,1,8,28,OUT);}
  else{for(let i=0;i<5;i++){const c=i%2?"#F2F2F8":"#E0483A";b.rect(4+i*8,6+Math.abs(2-i)*2,8,7-Math.abs(2-i),c);}b.rect(3,12,42,2,"#B8302A");b.ell(24,5,4,3,["#E0483A"]);}
  b.rect(5,46,38,18,"#3A9AD0");b.rect(5,46,38,3,"#7AC4EC");b.rect(5,61,38,3,"#1E6A9A");b.frame(4,45,40,20,OUT);b.rect(10,51,28,7,"#F2F2F8");[[13,52,"#E0483A"],[19,52,"#F0C020"],[25,52,"#3E9A52"],[31,52,"#7A56B0"]].forEach(k=>b.rect(k[0],k[1],3,5,k[2]));
  b.rect(8,36,13,10,"#DCEEFF");b.rect(8,36,13,2,"#FFFFFF");b.frame(7,35,15,12,"#7AA8C8");[[26,38,"#E0483A"],[31,38,"#F0C020"],[36,38,"#3E9A52"]].forEach(k=>{b.rect(k[0],k[1],4,8,k[2]);b.rect(k[0]+1,k[1]-3,2,3,"#C8C8D4");});
  [12,36].forEach(x=>{b.ell(x,68,6,6,[OUT]);b.ell(x,68,5,5,["#5A5A6A","#8A8A9A"]);b.ell(x,68,1.5,1.5,["#C8C8D4"]);});return b.done();}
// small things. Each is drawn with its foot at the bottom middle
const COSA={
  piragua(){const b=new Buf(9,13);b.ell(4.5,4,3.6,3.4,["#E0483A","#FFFFFF","#FFFFFF"]);b.rect(2,2,2,2,"#E0483A");for(let y=0;y<6;y++)b.rect(2+Math.floor(y*.42),7+y,5-Math.floor(y*.84),1,"#F4E2B4");b.px(4,12,"#D8BC8A");return b.outline().done();},
  piragua3(){const b=new Buf(13,18);b.ell(6.5,6,5.6,5.2,["#FFFFFF"]);b.rect(1,5,4,4,"#E0483A");b.rect(5,1,4,7,"#F0C020");b.rect(9,5,3,4,"#3A9AD0");b.rect(3,2,2,3,"#E0483A");b.rect(9,2,2,3,"#3A9AD0");for(let y=0;y<8;y++)b.rect(3+Math.floor(y*.45),10+y,7-Math.floor(y*.9),1,"#F4E2B4");b.px(6,17,"#D8BC8A");return b.outline().done();},
  papel(){const b=new Buf(7,8);for(let y=0;y<6;y++)b.rect(1+Math.floor(y*.42),1+y,5-Math.floor(y*.84),1,"#F4E2B4");b.px(3,7,"#D8BC8A");return b.outline().done();},
  agua(){const b=new Buf(7,13);b.rect(1,4,5,8,"#9CD8F0");b.rect(1,4,2,8,"#DCF2FA");b.rect(2,1,3,3,"#DCF2FA");b.rect(1,6,5,1,"#FFFFFF");b.rect(2,0,3,1,"#7AA8C8");return b.outline().done();},
  vacia(){const b=new Buf(7,13);b.rect(1,4,5,8,"#EAF6FA");b.rect(2,1,3,3,"#EAF6FA");b.rect(1,11,5,1,"#9CD8F0");b.rect(2,0,3,1,"#7AA8C8");return b.outline().done();},
  sombrero(){const b=new Buf(16,8);b.rect(4,1,8,5,"#6A4A2A");b.rect(4,1,8,1,"#8A6A44");b.rect(4,4,8,1,"#2A1A0E");b.rect(1,6,14,1,"#6A4A2A");return b.outline().done();},
  sombrilla(){const b=new Buf(11,32);b.rect(5,6,1,24,"#3A3A46");for(let y=8;y<28;y++){const w=y<12?1+((y-8)>>1):y>23?3-((y-24)>>1):3;b.rect(5-w,y,w*2+1,1,(y+((y>>2)%2))%5===0?"#16203A":"#2A3C6E");}b.rect(5,1,1,6,"#8A5A2A");b.rect(6,0,3,1,"#8A5A2A");b.rect(9,1,1,3,"#8A5A2A");b.rect(5,30,1,2,"#C8C8D4");return b.outline().done();},
  billetera(){const b=new Buf(15,11);b.rect(1,1,13,9,"#8A5A2A");b.rect(1,1,13,2,"#B8854A");b.rect(1,5,13,1,"#5A3A1A");b.rect(6,4,3,3,"#F0C020");return b.outline().done();},
  mochila(){const b=new Buf(15,17);b.rect(1,3,13,13,"#E88A2A");b.rect(1,3,13,2,"#F8B860");b.rect(3,8,9,6,"#B85A14");b.rect(3,8,9,1,"#F8B860");b.rect(5,0,5,3,"#B85A14");b.px(7,11,"#F2F2F8");return b.outline().done();},
  baston(){const b=new Buf(8,30);b.rect(3,3,2,26,"#8A5A2A");b.rect(3,1,5,2,"#8A5A2A");b.rect(7,2,1,3,"#8A5A2A");b.rect(3,28,2,1,"#3A3A46");return b.outline().done();},
  cartera(){const b=new Buf(13,13);b.rect(1,5,11,7,"#A8283C");b.rect(1,5,11,2,"#D0485C");b.px(6,8,"#F0C020");b.rect(3,1,1,4,"#7A1C2A");b.rect(9,1,1,4,"#7A1C2A");b.rect(3,0,7,1,"#7A1C2A");return b.outline().done();},
  gorra(){const b=new Buf(14,7);b.rect(1,1,9,5,"#D0302A");b.rect(1,1,9,1,"#F0605A");b.rect(9,4,5,2,"#A82020");return b.outline().done();},
  periodico(){const b=new Buf(15,8);b.rect(1,1,13,6,"#F2F2F8");[2,4].forEach(y=>b.rect(2,y,11,1,"#9494A6"));b.rect(7,1,1,6,"#C8C8D4");return b.outline().done();},
  bolsa(){const b=new Buf(10,13);b.rect(1,3,8,9,"#C89A60");b.rect(1,3,3,9,"#E0B880");b.rect(1,1,8,2,"#A87A40");b.rect(2,0,6,1,"#C89A60");return b.outline().done();},
  hueso(){const b=new Buf(13,7);b.rect(3,2,7,3,"#F8F4E8");[[2,1],[2,5],[10,1],[10,5]].forEach(p=>b.ell(p[0],p[1],1.6,1.6,["#F8F4E8"]));return b.outline().done();},
  caja(){const b=new Buf(28,16);b.rect(1,5,26,10,"#C89A60");b.rect(1,5,26,2,"#E0B880");b.rect(1,13,26,2,"#A87A40");b.rect(3,2,22,3,"#8A6234");b.rect(12,8,4,2,"#8A6234");return b.outline().done();},
  sonajero(){const b=new Buf(8,12);b.ell(4,4,3,3,["#E86AA0","#F8A0C8"]);b.px(3,3,"#FFFFFF");b.rect(3,7,2,4,"#F0C020");return b.outline().done();},
  oso(){const b=new Buf(15,10);b.rect(1,4,13,3,"#D0302A");b.rect(4,1,7,3,"#D0302A");b.rect(5,2,2,2,"#BFE0EA");b.rect(8,2,2,2,"#BFE0EA");b.rect(1,4,13,1,"#F0605A");[4,11].forEach(x=>{b.ell(x,7.5,1.8,1.8,["#20202A"]);b.px(x,7,"#C8C8D4");});return b.outline().done();},
  bloque(){const b=new Buf(9,9);b.rect(1,1,7,7,"#3A6AC8");b.rect(1,1,7,2,"#7AA0F0");b.rect(3,3,3,3,"#F0C020");return b.outline().done();},
  patito(){const b=new Buf(11,9);b.ell(5,5.5,4,2.6,["#C89A10","#F0C020","#FFE060"]);b.ell(8,2.5,2,2,["#F0C020","#FFE060"]);b.px(9,2,OUT);b.rect(10,3,1,1,"#E88A2A");return b.outline().done();},
  chal(){const b=new Buf(20,10);b.ell(10,5,9,4,["#5A3A8A","#7A56B0","#A07ED0"]);for(let x=2;x<18;x+=3)b.px(x,9,"#5A3A8A");return b.outline().done();},
  bola(){const b=new Buf(9,9);b.ell(4.5,4.5,3.6,3.6,["#C8401E","#F4683C","#FFA07A"]);b.rect(2,4,5,1,"#FFFFFF");return b.outline().done();},
  bandeja(){const b=new Buf(22,6);b.rect(1,2,20,3,"#8A5A2A");b.rect(1,2,20,1,"#D8AA70");b.rect(0,1,2,2,"#8A5A2A");b.rect(20,1,2,2,"#8A5A2A");return b.outline().done();}};
const cosa=k=>spr("cs"+k,COSA[k]||COSA.bolsa);
// a pigeon: sitting, pecking (head down), flying (wings up and down)
function mkPaloma(pose,f){const b=new Buf(18,13),C=["#5A5A6A","#8A8A9A","#B8B8C8"],baja=pose==="come"&&f,bebe=pose==="bebe";
  if(pose==="vuela"){b.ell(7,7,4.4,2.6,C);b.cap(6,6,4,f?1:11,1.6,[C[2]]);b.cap(8,6,10,f?1:11,1.6,[C[1]]);}
  else{b.ell(6,7,4.6,3.2,C);b.cap(2,7,0,5,1.2,[C[0]]);b.rect(5,10,1,2,"#E0483A");b.rect(8,10,1,2,"#E0483A");}
  const duerme=pose==="duerme",hx=baja?11:bebe?12:duerme?9:10,hy=baja?8:bebe?(f?2:3):duerme?6:4;if(bebe)b.cap(9,6,hx,hy+1,1.4,[C[1]]);b.ell(hx,hy,2.4,2.4,C);if(duerme)b.rect(hx,hy-1,2,1,OUT);else b.px(hx+1,hy-1,OUT);if(!duerme)b.rect(hx+2,hy+(baja||bebe?1:0),2,1,"#E88A2A");if(!baja&&!bebe)b.rect(8,5,2,2,"#3E9A52");
  if(pose==="come"&&!f){b.px(14,11,"#F2F2F8");b.px(16,10,"#E0483A");}if(bebe&&f)b.rect(15,6,1,2,"#5AB4EA");return b.outline().done();}
// a dog. tipo: canelo (brown), viejo (big, grey, a long white beard and eyebrows), joven (small, white with black patches)
function mkCan(tipo,pose,f,pena){const b=new Buf(32,24),T={canelo:["#8A5A2A","#B07A3C","#D09A54","#E8BE80"],viejo:["#5A5A66","#7E7E8C","#A0A0AE","#B8B8C6"],joven:["#B8B8C8","#E6E6F0","#FFFFFF","#FFFFFF"]}[tipo]||[],v=tipo==="viejo",j=tipo==="joven",X=13,Y=13;
  const lie=pose==="lie"||pose==="cansado"||pose==="duerme",sit=pose==="sit"||pose==="come"||pose==="bark"||pose==="triste",run=pose==="run",a=f?1:-1,k=1;
  const cola=pose==="triste"||v||pena?[X-12,Y+5]:j?[X-10,Y-3+(f?1:-1)]:[X-12,Y-6+(f?1:-1)];b.cap(X-9*k,Y+1,cola[0],cola[1],1.4,[T[1]]);
  if(lie){b.ell(X,Y+6,10*k,4,T);b.rect(X+6,Y+8,6,2,T[1]);}
  else if(sit){b.ell(X-1,Y+4,7*k,6*k+(v?1:0),T);b.rect(X+3,Y+5,2,6,T[1]);b.rect(X+6,Y+5,2,6,T[2]);b.ell(X-4,Y+9,4,2,[T[1]]);}
  else{b.ell(X,Y+2,10*k,(v?6:5)*k,T);
    if(run){b.cap(X-6,Y+5,X-11+a*2,Y+9,1.3,[T[1]]);b.cap(X-3,Y+5,X-7-a*2,Y+10,1.3,[T[0]]);b.cap(X+5,Y+5,X+10+a*2,Y+9,1.3,[T[1]]);b.cap(X+7,Y+5,X+12-a*2,Y+10,1.3,[T[2]]);}
    else{const w=pose==="walk"?a:0;b.rect(X-7+w,Y+6,2,5,T[1]);b.rect(X-4-w,Y+6,2,5,T[0]);b.rect(X+4+w,Y+6,2,5,T[1]);b.rect(X+7-w,Y+6,2,5,T[2]);}}
  if(j){b.ell(X-3,Y+(lie?5:sit?3:1),3,2.4,["#20202A"]);b.ell(X+4,Y+(lie?7:sit?6:3),2,1.6,["#20202A"]);}
  // the head
  const hx=X+10*k+(j?1:0),hy=(lie?Y+4:pose==="triste"?Y-1:v?Y-2:Y-3)+(pena&&!lie?2:0);if(tipo==="canelo")b.rect(hx-4,hy+4,5,2,RP.red[2]);
  b.ell(hx,hy,5*k+(v?.6:0),4.6*k+(v?.4:0),T);b.ell(hx+4*k,hy+1.5,3*k,2.2*k,[T[3]]);
  const caidas=pena||pose==="triste"||pose==="cansado"||pose==="duerme";
  if(caidas){b.cap(hx-3,hy-3,hx-4,hy+3,1.6,[j?"#20202A":T[0]]);}else{b.cap(hx-3,hy-3,hx-5,hy+2,1.5,[j?"#20202A":T[0]]);b.cap(hx+1,hy-4,hx+2,hy-7,1.3,[j?"#20202A":T[0]]);}
  if(v){b.rect(hx+2,hy+3,6,2,"#FFFFFF");b.rect(hx+3,hy+5,4,1,"#FFFFFF");b.rect(hx+3,hy+1,5,2,"#FFFFFF");b.rect(hx,hy-3,4,1,"#FFFFFF");b.rect(hx+6,hy,2,2,OUT);}                                   // his long white beard, his white eyebrows
  if(pose==="cansado"){b.rect(hx,hy-1,2,2,OUT);b.px(hx,hy-1,"#FFFFFF");b.rect(hx+2,hy+3,4,f?3:2,"#7A1C1C");b.rect(hx+4,hy+5,2,f?4:3,"#F08AA0");b.rect(hx-1,hy-6+(f?1:0),2,3,"#A8DCF8");}        // heavy open eyes, a yawn, his tongue out
  else{if(pose==="duerme")b.rect(hx,hy-1,3,1,OUT);else b.px(hx+1,hy-1,OUT);if(pose==="bark"&&f)b.rect(hx+3,hy+3,4,2,"#7A1C1C");else if(pose==="come")b.rect(hx+3,hy+3,3,2,f?"#7A1C1C":T[3]);else if(!v)b.px(hx+4,hy+3,"#7A2A1A");}
  if(!v)b.px(hx+6*k,hy+1,OUT);
  if(pose==="triste"){b.rect(hx+2,hy+1,1,2+(f?1:0),"#5A9AEA");}                                                                              // a tear
  return b.outline().done();}
// the pushchair. capota: the hood is down over the baby. bebe: duerme, llora, rie
function mkCoche(capota,bebe,f){const b=new Buf(38,42),Az=["#1E5A8A","#3A8AC8","#6AB4E8"];
  [10,28].forEach(x=>{b.ell(x,37,4,4,[OUT]);b.ell(x,37,3,3,["#5A5A6A","#8A8A9A"]);b.px(x,37,"#C8C8D4");});
  b.rect(9,31,20,2,"#5A5A6A");b.cap(33,9,29,30,1,["#5A5A6A"]);b.rect(31,7,6,2,"#3A3A46");
  b.rect(4,19,26,12,Az[1]);b.rect(4,19,26,2,Az[2]);b.rect(4,29,26,2,Az[0]);
  if(capota){b.ell(15,15,12,10,Az);b.rect(3,17,26,3,Az[0]);for(let x=6;x<26;x+=5)b.rect(x,8,1,9,Az[0]);}
  else{b.ell(8,14,6,9,[Az[0],Az[1]]);b.rect(12,16,16,4,"#F8F4E8");
    b.ell(19,12,5.4,5.2,[P.b[1],P.b[2],P.b[3]]);b.rect(16,6,6,2,"#44260E");
    if(bebe==="llora"){b.rect(16,11,2,1,OUT);b.rect(21,11,2,1,OUT);b.rect(17,13,5,3,"#7A1C1C");b.rect(15,12,1,3+(f?1:0),"#5A9AEA");b.rect(23,12,1,3+(f?0:1),"#5A9AEA");}
    else if(bebe==="rie"){b.px(17,11,OUT);b.px(21,11,OUT);b.rect(17,13,5,2,"#7A1C1C");b.rect(18,13,3,1,"#FFFFFF");}
    else{b.rect(16,11,2,1,OUT);b.rect(21,11,2,1,OUT);b.px(19,14,"#7A2A1A");}}
  return b.outline().done();}

const LUGAR={inicio:[18,150,1],centro:[104,180,1]};
const alto=id=>{const w=QUIEN[id]||{},p=W.gente[id];return id==="abuela"?(p&&p.sent?48:51):w.nino?(p&&p.sent?40:44):(p&&p.sent?49:56);};
const caja=id=>{const p=W.gente[id];return p&&p.vis!==0?[R(p.x)-11,R(p.y)-alto(id),22,alto(id)]:null;};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const perroC=n=>({id:n==="canelo"?"perro":"perro_"+n,m:2,si:w=>!!(w.perros&&w.perros[n]&&w.perros[n].vis!==0),box:w=>[R(w.perros[n].x)-15,R(w.perros[n].y)-22,30,24]});
const G=id=>W.gente[id];
const COSAS=Object.keys(QUIEN).map(persona).concat(["viejo","joven","canelo"].map(perroC),[
  {id:"coche",si:w=>!!w.coche,box:w=>[R(w.coche.x)-19,R(w.coche.y)-42,38,44],m:1},
  {id:"pajaro",si:w=>(w.palomas||[]).some(o=>o.vis!==0),box:w=>{const o=(w.palomas||[]).filter(o=>o.vis!==0),xs=o.map(q=>q.x),ys=o.map(q=>q.y);return [Math.min(...xs)-9,Math.min(...ys)-14,Math.max(...xs)-Math.min(...xs)+18,Math.max(...ys)-Math.min(...ys)+18];},m:0},
  {id:"carro",box:[CARRO[0]-24,CARRO[1]-72,48,74],m:0},{id:"farol",box:[FAROL[0]-7,34,14,FAROL[1]-28],m:0},
  {id:"banco0",box:[BANCOS[0][0]-22,BANCOS[0][1]-23,44,36],m:0},{id:"banco1",box:[BANCOS[1][0]-22,BANCOS[1][1]-23,44,36],m:0},{id:"banco2",box:[BANCOS[2][0]-22,BANCOS[2][1]-23,44,36],m:0},
  {id:"parque",box:[0,60,240,156],m:0}]);

/* ---------- drawing ---------- */
// what makes each of the new people his own, drawn over the kit's figure. hx,hy: the middle of the face
function extra(c,k,hx,hy,d,p,im){const sin=p.sin||{};
  if(k==="barba"){fr(c,hx-5,hy+2,10,4,"#24160E");fr(c,hx-2,hy+3,4,1,"#7A2A1A");fr(c,hx-6,hy-1,1,4,"#24160E");fr(c,hx+5,hy-1,1,4,"#24160E");}
  else if(k==="gorra"&&!sin.gorra){fr(c,hx-7,hy-8,14,5,OUT);fr(c,hx-6,hy-7,12,3,"#D0302A");fr(c,hx+d*5-(d<0?5:0),hy-4,6,2,OUT);fr(c,hx+d*5-(d<0?4:0),hy-4,5,1,"#D0302A");}
  else if(k==="mochila"&&!sin.mochila){fr(c,hx-d*11-(d<0?-1:5),hy+8,6,16,OUT);fr(c,hx-d*11-(d<0?0:4),hy+9,4,14,"#E88A2A");fr(c,hx-6,hy+10,1,12,"#B85A14");fr(c,hx+5,hy+10,1,12,"#B85A14");}   // a rucksack on his back, its straps on his chest
  else if(k==="sombrero"&&!sin.sombrero){fr(c,hx-6,hy-13,12,7,OUT);fr(c,hx-5,hy-12,10,5,"#6A4A2A");fr(c,hx-5,hy-8,10,1,"#2A1A0E");fr(c,hx-9,hy-7,18,3,OUT);fr(c,hx-8,hy-6,16,1,"#6A4A2A");}
  else if(k==="cola"){fr(c,hx-d*8-(d<0?0:3),hy-5,4,11,OUT);fr(c,hx-d*8-(d<0?-1:2),hy-4,2,9,"#44260E");fr(c,hx-d*6-(d<0?0:2),hy-6,3,3,"#F0C020");}                                                // a ponytail with a yellow band
  else if(k==="baston"&&!sin.baston){const bx=hx+d*12;fr(c,bx-1,hy+12,3,im.height-24,OUT);fr(c,bx,hy+13,1,im.height-26,"#8A5A2A");fr(c,bx-3,hy+11,6,3,OUT);fr(c,bx-2,hy+12,4,1,"#8A5A2A");}        // his cane
  else if(k==="delantal"){fr(c,hx-6,hy+12,12,14,"#F2F2F8");fr(c,hx-6,hy+12,12,1,"#C8C8D4");}}
// how somebody feels, drawn on the face: a tear and a turned-down mouth; a yawn and heavy eyes; a wide smile
function animo(c,k,hx,hy){const t=(F>>3)%2;
  if(k==="triste"){fr(c,hx-3,hy+3,6,2,"#C89A70");fr(c,hx-2,hy+4,4,1,"#7A2A1A");fr(c,hx-3,hy+5,1,1,"#7A2A1A");fr(c,hx+2,hy+5,1,1,"#7A2A1A");fr(c,hx-5,hy-3,2,1,"#20140A");fr(c,hx-3,hy-4,1,1,"#20140A");fr(c,hx+3,hy-3,2,1,"#20140A");fr(c,hx+2,hy-4,1,1,"#20140A");
    fr(c,hx-5,hy+1,2,4+t,"#5AB4F4");fr(c,hx+3,hy+1,2,3+(1-t),"#5AB4F4");fr(c,hx-5,hy+8+t*2,2,2,"#5AB4F4");}                                                  // slanted brows, a turned-down mouth, tears down both cheeks
  else if(k==="cansado"){fr(c,hx-4,hy-1,3,1,"#20140A");fr(c,hx+1,hy-1,3,1,"#20140A");fr(c,hx-4,hy,3,1,"#C89A70");fr(c,hx+1,hy,3,1,"#C89A70");fr(c,hx-3,hy+3,6,2,"#C89A70");fr(c,hx-2,hy+4,4,1,"#7A2A1A");
    fr(c,hx+6,hy-7+t,2,3,"#A8DCF8");fr(c,hx-8,hy-5-t,2,3,"#A8DCF8");[[8,2],[11,-1],[14,-4]].forEach((q,i)=>{if((F>>2)%4>i){fr(c,hx+q[0]-1,hy+q[1]-1,5,4,OUT);fr(c,hx+q[0],hy+q[1],3,2,"#FFFFFF");}});}   // heavy lids, a flat mouth, sweat, puffs of breath
  else if(k==="contento"){fr(c,hx-3,hy+3,6,2,"#7A1C1C");fr(c,hx-2,hy+3,4,1,"#FFFFFF");fr(c,hx-4,hy+2,1,1,"#7A1C1C");fr(c,hx+3,hy+2,1,1,"#7A1C1C");}}
function tenida(c,k,x,y,girada){const im=cosa(k);if(girada){c.save();c.translate(x,y);c.rotate(girada);c.drawImage(im,-(im.width>>1),-im.height);c.restore();}else c.drawImage(im,R(x)-(im.width>>1),R(y)-im.height);}
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  if(id==="abuela"){if(p.sent){const ps=p.pose||"idle",top=y-48;c.drawImage(spr("abS"+ps+habla,()=>KIT.mkAbuelaS(ps,habla,0)),x-17,top);if(p.ojos){fr(c,x-4,top+12,3,1,"#20140A");fr(c,x+1,top+12,3,1,"#20140A");}if(p.lleva)tenida(c,p.lleva,x+14,top+16);return;}
    const ps=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle");c.save();c.translate(x,y-50+((p.paso&&a%2)?-1:0));if(d<0)c.scale(-1,1);c.drawImage(spr("ab"+ps+habla,()=>mkAbuela(ps,habla)),-30,0);c.restore();if(p.lleva)tenida(c,p.lleva,x+d*12,y-14);return;}
  const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="arriba"?"wave0":(p.pose||"idle"),im=spr("pb"+id+pose+habla+(p.sent?1:0),()=>KIT.mkPersona(w,pose,habla,p.sent)),top=y-im.height+1+((p.paso&&a%2)?-1:0)-(p.dy||0)+(p.animo==="cansado"?3:p.animo==="triste"?1:0);
  c.save();c.translate(x,top);if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  (w.extra||[]).forEach(k=>extra(c,k,x,top+11,d,p,im));if(p.animo)animo(c,p.animo,x,top+11);
  if(p.hace==="come")tenida(c,p.que||"piragua",x+d*5,top+24+(a%2));else if(p.hace==="bebe")tenida(c,"agua",x+d*11,top+7,-d*(a%2?2.3:2.45));
  else if(p.lleva)tenida(c,p.lleva,x+d*10,top+(w.nino?34:38));
  if(p.lleva2)tenida(c,p.lleva2,x-d*11,top+(p.sent?40:46));
  if(p.lee){fr(c,x-8,top+24,16,9,OUT);fr(c,x-7,top+25,14,7,"#F2F2F8");fr(c,x,top+25,1,7,"#C8C8D4");[27,29].forEach(yy=>{fr(c,x-6,top+yy,5,1,"#9494A6");fr(c,x+2,top+yy,4,1,"#9494A6");});}}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2||q.hace==="cansado"?1:0,op=(q.bub==="hola"||TALK==="coqui"||q.hace==="canta"||q.hace==="come")&&a%2?1:0,dy=R(q.dy)+(q.hace==="cansado"?2:0),cx=b.x+(b.w>>1),m=W.manos||{};
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.bandeja){g.drawImage(cosa("bandeja"),cx-11,b.y+dy-4);if(W.bandeja!==1)tenida(g,W.bandeja,cx,b.y+dy-2);}
  // what he holds: one thing in each hand; the one he is eating or drinking goes to his mouth
  [["i",-1],["d",1]].forEach(s=>{const k=m[s[0]];if(!k)return;const enboca=(q.hace==="come"&&k.startsWith("piragua"))||(q.hace==="bebe"&&k==="agua");
    if(enboca&&k==="agua")tenida(g,k,cx+s[1]*3,b.y+dy+10,s[1]*(a%2?2.2:1.9));else if(enboca)tenida(g,k,cx+s[1]*2,b.y+dy+21+(a%2));else tenida(g,k,cx+s[1]*17,b.y+dy+b.h-2);});
  if(q.hace==="canta"){const t=(F>>2)%4;nota(g,cx+15+t,b.y+dy-8-t);}
  if(q.hace==="quieto")nota(g,cx+18,b.y+dy-6,1);
  if(q.hace==="cansado"){const t=(F>>3)%2;fr(g,cx+13,b.y+dy+3+t,1,2,"#A8CCF8");fr(g,cx-14,b.y+dy+5-t,1,2,"#A8CCF8");}
  if(W.encima)tenida(g,W.encima,cx,b.y+dy+2);}
function perro(c,n,a){const o=W.perros[n];if(!o||o.vis===0)return;
  if(o.ronda){const t=(F-o.fase)%44,u=t<22?t/22:(44-t)/22;o.x=o.x0+u*34;o.dir=t<22?1:-1;}        // the young dog runs to and fro
  if(o.paseo){const t=(F-o.fase)%130,u=t<65?t/65:(130-t)/65;o.x=o.x0-u*16;o.dir=t<65?-1:1;}   // the old dog walks slowly, there and back
  const anda=o.pose==="walk"||o.pose==="run"||o.pose==="bark"||o.pose==="come"||o.pose==="cansado"||o.pose==="triste"||o.mueve,f=anda?(a>>(o.pose==="run"?0:1))%2:0,tp=o.tipo||n,im=spr("can"+tp+o.pose+f+(o.pena?1:0),()=>mkCan(tp,o.pose,f,o.pena));
  c.save();c.translate(R(o.x),R(o.y)-im.height+2-(o.dy||0));if(o.dir<0)c.scale(-1,1);c.drawImage(im,-13,0);
  if(o.lleva){const t=cosa(o.lleva);c.drawImage(t,16-(t.width>>1),(o.pose==="lie"||o.pose==="cansado"?17:12));}
  if(o.chal)c.drawImage(cosa("chal"),-14,10);c.restore();
  if(o.zzz){const t=(F>>3)%3,Z=["#####","...#.","..#..",".#...","#####"];[[14,-20],[21,-27]].forEach((q,k)=>{if(k&&t<1)return;Z.forEach((rw,jj)=>{for(let ii=0;ii<5;ii++)if(rw[ii]==="#"){fr(c,R(o.x)+q[0]+ii-1,R(o.y)+q[1]+jj-1,3,3,OUT);}});Z.forEach((rw,jj)=>{for(let ii=0;ii<5;ii++)if(rw[ii]==="#")fr(c,R(o.x)+q[0]+ii,R(o.y)+q[1]+jj,1,1,"#FFFFFF");});});}
  if(o.correa){const [bx,by]=o.correa;c.strokeStyle="#A82020";c.lineWidth=1;c.beginPath();c.moveTo(R(o.x)+(o.dir<0?-5:5)+.5,R(o.y)-10.5);c.lineTo(bx+.5,by+.5);c.stroke();}}
function coche(c,a){const o=W.coche;if(!o)return;const f=(a>>1)%2,im=spr("coche"+(o.capota?1:0)+(o.bebe||"")+f,()=>mkCoche(o.capota,o.bebe,f)),sx=o.tiembla?(a%2?1:-1):o.mece?R(Math.sin(F/5)*2):0,x=R(o.x)-19+sx,y=R(o.y)-40;
  c.drawImage(im,x,y);
  if(o.bebe==="duerme"&&!o.capota){const t=(F>>3)%3;fr(c,x+27,y+2-t*3,3,1,"#FFFFFF");fr(c,x+28,y+3-t*3,1,1,"#FFFFFF");fr(c,x+27,y+4-t*3,3,1,"#FFFFFF");}   // z z z
  if(o.bebe==="llora"){const t=(F>>1)%6;[[-4,-1],[2,-3],[9,-2],[15,-1]].forEach((p,i)=>fr(c,x+10+p[0]+(i%2?t:-t),y+6+p[1]-((t*2+i*3)%9),1,2,"#5A9AEA"));}                   // tears fly out from under the hood
  if(o.mano){const t=(F>>2)%2;fr(c,x+13+t*2,y+1,5,6,OUT);fr(c,x+14+t*2,y+2,3,4,P.b[2]);}
  if(o.bebe==="rie"&&o.capota){const t=(F>>2)%3;fr(c,x+12,y-2-t,2,1,"#F0C020");fr(c,x+18,y-4-t,2,1,"#F0C020");}}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{};
  c.drawImage(spr("banco",fondo),0,0);
  if(W.luna){c.fillStyle=OUT;c.beginPath();c.arc(64,26,9,0,7);c.fill();c.fillStyle="#FFF8D8";c.beginPath();c.arc(64,26,8,0,7);c.fill();c.fillStyle="#E8DCA8";c.fillRect(60,22,3,3);c.fillRect(66,28,2,2);}   // the moon
  if(W.noche){c.drawImage(spr("banco",fondo),84,6,46,38,196,6,46,38);c.fillStyle="rgba(30,24,90,.32)";c.fillRect(0,0,SW,SH);fr(c,FAROL[0]-5,36,11,11,"#FFF8C8");c.fillStyle="rgba(255,240,160,.16)";c.beginPath();c.ellipse(FAROL[0],FAROL[1]+18,46,22,0,0,7);c.fill();}
  if(W.tarde&&!W.noche){c.fillStyle="rgba(255,150,60,.10)";c.fillRect(0,0,SW,SH);}
  if(W.seva===1||W.seva===3){const pi=Gt.piraguero,v=W.perros.viejo,j=W.perros.joven;W.carroX-=1.1;if(pi)pi.x=W.carroX+30;if(v)v.x-=.35;if(j){const t=F-j.fase,x=j.x0-t*.5+34*Math.sin(t/7);j.dir=x<j.x?-1:1;j.x=x;}}   // the cart goes home, the dogs with it: the old one walks, the young one runs to and fro ahead
  const L=[];
  if(W.carro!==0)L.push({y:CARRO[1],d:()=>c.drawImage(spr("carro"+(W.carro==="cerrado"?1:0),()=>mkCarro(W.carro==="cerrado")),R(W.carroX!=null?W.carroX:CARRO[0])-24,CARRO[1]-72)});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.sent?p.y-8:p.y,d:()=>gente(c,id,a)});});
  (W.palomas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y,d:()=>{const f=(a>>(o.pose==="vuela"?0:1))%2,im=spr("pal"+(o.pose||"")+f,()=>mkPaloma(o.pose,f));c.save();c.translate(R(o.x),R(o.y));if(o.dir<0)c.scale(-1,1);c.drawImage(im,-7,-12);c.restore();}});});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>{tenida(c,o.k,o.x,o.y,o.rot);if(o.k==="caja")(W.encaja||[]).forEach((k,i)=>{const im=cosa(k);c.drawImage(im,R(o.x)-13+i*9,R(o.y)-9-im.height+(i%2)*2);});
    if(o.k==="agua"&&o.charco){fr(c,R(o.x)-9,R(o.y)-1,16,2,"#9CD8F0");fr(c,R(o.x)-6,R(o.y)+1,10,1,"#9CD8F0");}}});});
  Object.keys(W.perros||{}).forEach(n=>{const o=W.perros[n];if(o&&o.vis!==0)L.push({y:o.y,d:()=>perro(c,n,a)});});
  if(W.coche)L.push({y:W.coche.y,d:()=>coche(c,a)});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.bub?38:0)];}
// a note of music; and the same note crossed out: not a sound
function nota(g,x,y,no){[[OUT,1],["#2A3C8E",0]].forEach(k=>{const m=k[1],u=(a,b,w,h)=>fr(g,x+a-m,y+b-m,w+2*m,h+2*m,k[0]);u(3,0,1,10);u(11,0,1,9);u(3,0,9,2);u(0,8,4,3);u(8,7,4,3);});
  if(no)for(let i=0;i<15;i++){fr(g,x-2+i,y-2+i,3,2,"#D0302A");fr(g,x+12-i,y-2+i,3,2,"#D0302A");}}
// the doing bubbles: the frog eating, drinking, singing, keeping still. The thing is drawn big beside him
function respIcon(g,k,x,y,w,h,a){const t=(F>>2)%2,op=(k==="canta"||k==="come")&&t?1:0,im=spr("cq.6_0"+op,()=>mkCoqui(.6,0,op)),fx=x+2,fy=y+h-im.height-3;g.imageSmoothingEnabled=false;
  g.drawImage(im,fx,fy);
  if(k==="come"){g.save();g.translate(x+28-t,y+32);g.scale(2,2);tenida(g,"piragua",0,0);g.restore();}
  else if(k==="bebe"){g.save();g.translate(x+31,y+31);g.scale(2,2);tenida(g,"agua",0,0,-.75-t*.15);g.restore();}
  else if(k==="canta"){nota(g,x+24,y+5-t*2);g.fillStyle="#2A3C8E";[[22,24],[26,27],[31,23]].forEach(q=>g.fillRect(x+q[0],y+q[1]+t,2,2));}
  else if(k==="quieto")nota(g,x+24,y+10,1);}
/* ---------- the card in the corner: three rounds; a star, or a cross ---------- */
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,66,24);
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m){g.fillStyle=OUT;for(let k=0;k<11;k++){g.fillRect(x+k,y+1+k,4,3);g.fillRect(x+10-k,y+1+k,4,3);}g.fillStyle="#C8401E";for(let k=0;k<11;k++){g.fillRect(x+1+k,y+2+k,2,1);g.fillRect(x+11-k,y+2+k,2,1);}}
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}
const marca=m=>{const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;};

/* ---------- moving things ---------- */
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/5));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;}
async function sienta(id,i,lado){const q=BANCOS[i],p=G(id);await mueve(id,q[0]+(lado||0)*10,q[1]+11);p.sent=1;p.dir=1;}
async function palomaA(o,x,y,pasos){const x0=o.x,y0=o.y;pasos=pasos||Math.max(5,R(Math.hypot(x-x0,y-y0)/9));o.pose="vuela";o.z=400;if(Math.abs(x-x0)>3)o.dir=x>x0?1:-1;for(let i=1;i<=pasos;i++){const t=i/pasos;o.x=x0+(x-x0)*t;o.y=y0+(y-y0)*t-Math.sin(Math.PI*t)*8;await wait(TICK);}o.x=x;o.y=y;o.pose="";}
async function perroA(n,x,y,pose,pasos){const o=W.perros[n];if(!o)return;const x0=o.x,y0=o.y,fin=o.pose;pose=pose||"walk";pasos=pasos||Math.max(4,R(Math.hypot(x-x0,y-y0)/(pose==="run"?8:n==="viejo"?2:4)));o.pose=pose;if(Math.abs(x-x0)>3)o.dir=x>x0?1:-1;for(let i=1;i<=pasos;i++){o.x=x0+(x-x0)*i/pasos;o.y=y0+(y-y0)*i/pasos;await wait(TICK);}o.x=x;o.y=y;o.pose=fin==="walk"||fin==="run"?"idle":fin;}
const pio=()=>{tone(1500,0,.05,"sine",.04,1900);tone(1300,.07,.05,"sine",.04,1700);};
const ladra=n=>{for(let k=0;k<(n||1);k++){tone(520,k*.26,.07,"square",.05,300);tone(400,k*.26+.07,.1,"square",.05,240);}};

/* ---------- helpers for the stories ---------- */
const B=BANCOS,ASIENTO=149,POSA=[[110,127],[158,127],[176,127],[208,127]],JUG=["sonajero","oso","bloque","patito"],JUGEN=[[182,188],[195,196],[183,209],[196,211]];
const cx=()=>W.cq.x+16,pies=()=>W.cq.y+27;
async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(4,R(d/34))));}
const acasa=()=>ranaA(W.casa[0],W.casa[1]);
async function carmenDa(f){const ca=G("carmen"),x0=ca.x,y0=ca.y;await mueve("carmen",cx()-30,pies()+1);ca.dir=1;ca.pose="offer";await wait(250);f();SFX.blip();await wait(300);ca.pose="idle";await mueve("carmen",x0,y0);ca.dir=1;}   // she walks over and hands it to him
const cosaDe=id=>(W.cosas||[]).find(o=>o.id===id);
const quita=id=>{W.cosas=(W.cosas||[]).filter(o=>o.id!==id);};
const libre=()=>W.palomas.find(o=>o.en==="cable");
async function alcable(o){const p=CABLE(o.i);await palomaA(o,p[0],p[1]);o.en="cable";o.z=null;o.dir=o.i%2?1:-1;}
async function posa(o){const p=POSA[Math.min(3,W.posadas||0)];W.posadas=(W.posadas||0)+1;await palomaA(o,p[0],p[1]);o.en="banco";o.z=140;o.dir=-1;}
async function niega(p){for(let k=0;k<4;k++){p.dir=-p.dir;await wait(150);}}
const perroDe=a=>W.perros[a==="perro"?"canelo":a.replace("perro_","")];
const llanto=()=>{[0,.24,.48].forEach(t=>tone(760,t,.2,"triangle",.07,520));};
const risa=()=>{[0,.12,.24,.36].forEach((t,i)=>tone(420+(i%2)*90,t,.09,"square",.05,380));};
const sollozo=()=>{[0,.3].forEach(t=>tone(330,t,.24,"sine",.08,240));};
const gime=()=>{tone(620,0,.45,"sine",.07,860);};
const grune=()=>{tone(120,0,.45,"sawtooth",.05,90);};
const coquiS=()=>{[0,.5].forEach(t=>{tone(1400,t,.09,"sine",.025,1500);tone(2100,t+.12,.14,"sine",.025,2500);});};
const palmas=()=>{[0,.14].forEach(t=>tone(900,t,.04,"square",.06,500));};
async function despierta(){const o=W.coche,n=W.juguetes||0,k=JUG[Math.min(3,n)],d=JUGEN[Math.min(3,n)];o.bebe="llora";o.tiembla=1;o.mano=0;llanto();await wait(350);
  const t={id:"jug"+n,k,x:o.x,y:o.y-30,z:400};W.cosas.push(t);W.juguetes=n+1;for(let i=1;i<=8;i++){const u=i/8;t.x=o.x+(d[0]-o.x)*u;t.y=o.y-30+(d[1]-o.y+30)*u-Math.sin(Math.PI*u)*16;await wait(TICK);}t.x=d[0];t.y=d[1];t.z=null;SFX.bonk();await wait(450);}
async function mece(){const o=W.coche;o.tiembla=0;o.mece=1;await wait(1500);o.mece=0;o.bebe="duerme";await wait(300);}

const acts={
  async pose(o){const p=G(o.quien);if(p)p.pose=o.que;},
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async casa(){await acasa();},

  /* ----- story 21: La piragua ----- */
  async inicio21(){W.gente={piraguero:{x:CARRO[0]+4,y:CARRO[1]-6,dir:1},carmen:{x:62,y:206,dir:1},hombre:{x:B[0][0]-9,y:161,dir:1,sent:1},mujer:{x:B[1][0]-9,y:161,dir:1,sent:1},luis:{x:B[2][0],y:161,dir:1,sent:1}};
    W.palomas=[0,1,2,3,4].map(i=>({i,x:CABLE(i)[0],y:CABLE(i)[1],dir:i%2?1:-1,en:"cable"}));W.casa=[124,206];Object.assign(W.cq,{x:W.casa[0]-16,y:W.casa[1]-27,s:1});W.bandeja=1;W.posadas=0;W.cosas=[];},
  async pon(o){const de=G(o.de||"carmen");await acasa();de.pose="offer";await wait(250);W.bandeja=o.k;SFX.blip();await wait(300);de.pose="idle";},
  async lleva(o){const p=G(o.a),k=W.bandeja;await ranaA(p.sent?p.x:p.x+26,p.sent?p.y+22:p.y);W.bandeja=1;p.que=k;p.hace=k==="agua"?"bebe":"come";SFX.blip();await wait(500);},
  async llevamal(o){const p=G(o.a);await ranaA(p.sent?p.x:p.x+26,p.sent?p.y+22:p.y);await niega(p);p.dir=1;W.cq.dy=-4;await wait(300);const pg=libre();pio();await palomaA(pg,cx(),pies()-30);pg.pose="come";pg.z=400;await wait(900);W.bandeja=1;pg.pose="";W.cq.dy=0;await posa(pg);},
  async dejan(){const h=G("hombre"),m=G("mujer");h.hace=null;h.lleva=null;h.lee=1;m.hace=null;m.lleva=null;m.dir=-1;W.cosas.push({id:"pir",k:"piragua",x:101,y:ASIENTO-4,rot:Math.PI/2},{id:"bot",k:"agua",x:153,y:ASIENTO});await wait(500);},
  async nuevas(){const ca=G("carmen");await mueve("carmen",104,182);G("hombre").hace="come";G("hombre").que="piragua";SFX.blip();await wait(250);await mueve("carmen",150,182);G("mujer").hace="bebe";SFX.blip();await wait(250);await mueve("carmen",62,206);ca.dir=1;await wait(500);},
  async paloma(o){const pg=libre();W.ladrona=pg;pio();if(o.k==="come"){await palomaA(pg,119,ASIENTO);pg.dir=-1;pg.pose="come";}else{await palomaA(pg,163,ASIENTO);pg.dir=-1;pg.pose="bebe";}pg.z=152;await wait(700);},
  async salva(o){const come=o.k==="come",p=G(come?"hombre":"mujer"),pg=W.ladrona;if(come){p.lee=0;quita("pir");p.lleva="piragua";}else{p.dir=1;quita("bot");p.lleva="agua";}SFX.blip();p.dy=3;await wait(150);p.dy=0;if(pg){pg.pose="";if(o.medio)await posa(pg);else await alcable(pg);}W.ladrona=null;await wait(250);},
  async miraotra(o){const come=o.k==="come",p=G(come?"mujer":"hombre");if(come){quita("bot");p.lleva="agua";}else{p.lee=0;quita("pir");p.lleva="piragua";}SFX.blip();await niega(p);p.dir=1;await wait(300);},
  async acaban(o){const h=G("hombre"),m=G("mujer"),ca=G("carmen");if(cosaDe("pir")){quita("pir");}if(cosaDe("bot")){quita("bot");}h.lee=0;h.lleva=null;m.lleva=null;m.dir=1;h.hace="come";h.que="piragua";m.hace="bebe";await wait(900);h.hace=null;m.hace=null;h.lleva="papel";m.lleva="vacia";
    await mueve("carmen",104,182);h.lleva=null;await mueve("carmen",150,182);m.lleva=null;await mueve("carmen",62,206);ca.dir=1;W.bandeja=o&&o.bandeja==="no"?null:1;await wait(200);},
  async sinbandeja(){W.bandeja=null;await wait(150);},
  async manos(o){await carmenDa(()=>{W.manos=Object.assign({},W.manos||{},o.i?{i:o.i}:{},o.d?{d:o.d}:{});});},
  async llena(){const m=W.manos||{i:null,d:null},vale=k=>!!k&&(k==="agua"||k.startsWith("piragua")),hay=k=>["i","d"].some(q=>vale(m[q])&&(k==="agua"?m[q]==="agua":m[q].startsWith("piragua"))),falta=["piragua","agua"].filter(k=>!hay(k));await carmenDa(()=>{["i","d"].forEach(q=>{if(!vale(m[q]))m[q]=falta.shift()||null;});W.manos=m;});},
  async acaba(o){const p=G(o.a);p.hace=p.lleva==="agua"?"bebe":"come";p.que=p.lleva==="agua"?"agua":"piragua";p.lleva=null;await wait(900);p.hace=null;},
  async tragan(){Object.values(W.gente).forEach(p=>{p.hace=null;p.lleva=null;});await wait(200);},
  async empieza(o){const q=W.cq;q.hace=o.que;if(o.que==="come")[0,.2,.4].forEach(t=>tone(300,t,.05,"square",.03,240));else[0,.25,.5].forEach(t=>tone(500,t,.08,"sine",.04,380));await wait(650);},
  async termina(o){const q=W.cq,m=W.manos||{};await wait(350);["i","d"].forEach(s=>{if(o.que==="come"&&m[s]&&m[s].startsWith("piragua"))m[s]="papel";if(o.que==="bebe"&&m[s]==="agua")m[s]="vacia";});q.hace=null;await wait(250);},
  async otro(o){const que=o.que==="come"?"bebe":"come",m=W.manos||{},cual=que==="come"?"piragua":"agua";if(!["i","d"].some(q=>m[q]&&m[q].startsWith(cual)))return;await acts.empieza({que});await acts.termina({que});},
  async repone(o){const m=W.manos||{},cual=o.que==="come"?"piragua":"agua",l=["i","d"].find(q=>!m[q]||m[q]==="papel"&&cual==="piragua"||m[q]===null)||["i","d"].find(q=>m[q]==="papel"||m[q]==="vacia");await carmenDa(()=>{["i","d"].forEach(q=>{if(m[q]==="papel"||m[q]==="vacia")m[q]=null;});m[l||"i"]=cual;W.manos=m;});},
  async limpia(){W.manos=null;await wait(200);},
  async turno21(){const q=W.cq,m=W.manos,s=m.i&&m.i.startsWith("piragua")?-1:1,pg=libre();q.dy=-5;await wait(500);pio();await palomaA(pg,cx()+s*17,pies()-9);pg.pose="come";pg.z=400;pg.dir=-s;await wait(1100);m[s<0?"i":"d"]="papel";q.dy=0;pg.pose="";SFX.bonk();await wait(400);await posa(pg);await wait(300);},
  async acecha(){const pg=libre();W.ladrona=pg;pio();await palomaA(pg,cx()-3,W.cq.y+9);pg.pose="";pg.dir=1;pg.z=W.cq.y+10;await wait(500);},   // behind him, dead centre: only the top of it shows
  async sale(o){const m=W.manos,pg=W.ladrona,cual=o.que==="come"?"piragua":"agua",l=m.i&&m.i.startsWith(cual)?"i":m.d&&m.d.startsWith(cual)?"d":null,s=l==="i"?-1:1;if(!pg)return;pg.z=400;
    if(o.hizo===o.que||!l){await palomaA(pg,cx()+s*22,pies(),4);pg.dir=-s;await wait(450);G("carmen").pose="wave";palmas();await wait(350);G("carmen").pose="idle";await alcable(pg);}
    else if(cual==="piragua"){await palomaA(pg,cx()+s*17,pies()-9,4);pg.dir=-s;pg.pose="come";await wait(1000);m[l]="papel";pg.pose="";SFX.bonk();await wait(300);await posa(pg);}
    else{await palomaA(pg,cx()+s*17,pies()-9,4);m[l]=null;const t={id:"tirada",k:"agua",x:cx()+s*26,y:pies()-3,rot:s*Math.PI/2,charco:1};W.cosas.push(t);SFX.bonk();await palomaA(pg,cx()+s*36,pies(),3);pg.dir=-s;pg.pose="come";await wait(1000);pg.pose="";quita("tirada");await posa(pg);}
    W.ladrona=null;},
  async final21(){const n=W.posadas||0,ca=G("carmen"),q=W.cq;await acasa();await mueve("carmen",cx()+46,pies()+2);ca.dir=-1;ca.pose="offer";await wait(300);W.manos={i:n<=1?"piragua3":"piragua"};ca.pose="idle";ca.hace="bebe";SFX.blip();q.hace="come";
    if(n>=4){const en=[[-34,2],[-22,12],[26,14],[44,-6]];await Promise.all(W.palomas.filter(o=>o.en==="banco").map((o,i)=>palomaA(o,cx()+en[i%4][0],pies()+en[i%4][1]).then(()=>{o.dir=en[i%4][0]<0?1:-1;o.z=null;})));}await wait(400);},
  async quiere(){const o=W.palomas.find(p=>p.en==="banco");if(o){pio();o.dy=2;await wait(200);o.x+=o.dir*3;await wait(300);}},
  async fin21(){W.cq.hace=null;G("carmen").hace=null;await wait(300);},

  /* ----- story 22: ¡Señor! ¡Señora! ----- */
  async inicio22(){W.gente={piraguero:{x:CARRO[0]+4,y:CARRO[1]-6,dir:1},senor:{x:B[0][0]-9,y:161,dir:1,sent:1},mujer:{x:B[1][0]-9,y:161,dir:1,sent:1},joven:{x:B[2][0]-9,y:161,dir:1,sent:1,sin:{mochila:1}},hombre:{x:B[0][0]+11,y:161,dir:1,sent:1,lee:1},carmen:{x:176,y:208,dir:-1},luis:{x:148,y:186,dir:1}};
    W.cosas=[{id:"sombrilla",k:"sombrilla",x:72,y:163},{id:"cartera",k:"cartera",x:157,y:ASIENTO},{id:"mochila",k:"mochila",x:204,y:ASIENTO+1},{id:"caja",k:"caja",x:167,y:187}];W.encaja=[];
    W.perros={viejo:{x:90,y:193,pose:"sit",dir:1},joven:{x:38,y:193,pose:"sit",dir:1}};W.palomas=[0,1,2,3,4].map(i=>({i,x:CABLE(i)[0],y:CABLE(i)[1],dir:i%2?1:-1,en:"cable"}));
    W.casa=[124,205];Object.assign(W.cq,{x:W.casa[0]-16,y:W.casa[1]-27,s:1});W.tarde=1;W.fuera=null;W.sinhueso=null;},
  async alcarro(){const en={senor:[80,184],mujer:[96,188],joven:[112,184]};await Promise.all(Object.keys(en).map(async id=>{await mueve(id,en[id][0],en[id][1]);G(id).dir=-1;}));await wait(400);},
  async vuelve22(o){const id=o.a,p=G(id),i={senor:0,mujer:1,joven:2}[id];p.dir=1;await wait(350);await mueve(id,B[i][0]-9,172);if(id==="joven"){p.sin={};quita("mochila");}else if(id==="senor"){quita("sombrilla");p.lleva2="sombrilla";}else{quita("cartera");p.lleva2="cartera";}SFX.blip();p.dy=3;await wait(160);p.dy=0;await wait(250);},
  async sientan(){await Promise.all([["senor",0,-9,"piragua"],["mujer",1,-9,"agua"],["joven",2,-9,"piragua"]].map(async k=>{const p=G(k[0]);await mueve(k[0],B[k[1]][0]+k[2],161);p.sent=1;p.dir=1;p.lleva=k[3];}));await wait(300);},
  async bolsa(){await mueve("carmen",122,174);G("carmen").lleva="bolsa";SFX.blip();await mueve("carmen",158,210);G("carmen").dir=-1;G("carmen").pose="arriba";await wait(300);},
  async dabolsa(o){const p=G(o.a),ca=G("carmen");ca.lleva=null;ca.pose="idle";W.encima="bolsa";SFX.blip();await ranaA(p.sent?p.x:p.x+2,p.sent?p.y+22:p.y+25);if(o.no){await niega(p);p.dir=p.sent?1:-1;return;}W.encima=null;p.lleva="bolsa";SFX.blip();await wait(400);},
  async hueso(){const ca=G("carmen");await mueve("carmen",146,176);ca.lleva="hueso";SFX.blip();await mueve("carmen",158,210);ca.dir=-1;await acasa();ca.lleva=null;W.encima="hueso";SFX.blip();await wait(300);},
  async dahueso(o){const d=perroDe(o.a);await ranaA(d.x+30,d.y+4);W.encima=null;d.lleva="hueso";d.pose=o.echa?"lie":"come";SFX.blip();await wait(500);},
  async ronda(o){const d=W.perros.joven;d.ronda=o.fin?0:1;if(o.fin){d.pose="come";d.x=d.x0;d.dir=1;}else{d.x0=d.x;d.pose="run";d.fase=F;}await wait(200);},
  async paseo(o){const d=W.perros.viejo;d.paseo=o.fin?0:1;if(o.fin){d.pose="sit";d.x=d.x0;d.dir=1;}else{d.x0=d.x;d.pose="walk";d.fase=F;}await wait(200);},
  async turno22(){const h=G("hombre");h.lee=0;W.cosas.push({id:"periodico",k:"periodico",x:108,y:ASIENTO});await wait(400);await mueve("hombre",PORTON[0],PORTON[1]);await mueve("hombre",244,PORTON[1]);h.vis=0;await wait(300);},
  async luisve(){const l=G("luis");l.dir=1;await wait(300);await mueve("luis",112,178);quita("periodico");l.lleva="periodico";await mueve("luis",PORTON[0]-4,PORTON[1]+2);l.dir=1;l.pose="arriba";await wait(200);},
  async luiscaja(){const l=G("luis");l.pose="idle";for(let k=0;k<3;k++){l.dir=-l.dir;await wait(160);}await mueve("luis",148,186);l.dir=1;l.lleva=null;W.encaja.push("periodico");SFX.blip();await wait(300);},
  async sale22(o){const p=G(o.a),v=W.perros.viejo,j=W.perros.joven;v.lleva=null;j.lleva=null;await Promise.all([perroA("viejo",36,193,"walk"),perroA("joven",64,194,"run")]);v.pose="sit";j.pose="sit";v.dir=1;j.dir=1;W.casa=[100,205];await acasa();
    p.lleva=null;p.sent=0;await mueve(o.a,p.x+4,176);const t={id:"billetera",k:"billetera",x:p.x-8,y:p.y-22,z:400};W.cosas.push(t);for(let i=1;i<=6;i++){t.y=p.y-22+26*i/6;await wait(TICK);}t.y=p.y+4;t.z=null;SFX.bonk();t.y-=3;await wait(90);t.y+=3;await wait(350);   // it drops from a pocket, in plain sight
    await mueve(o.a,PORTON[0],PORTON[1]);p.dir=1;W.fuera=o.a;await wait(300);},
  async recoge(o){const p=G(o.a),t=cosaDe("billetera");p.dir=-1;await wait(300);await mueve(o.a,t.x+10,t.y+2);quita("billetera");SFX.blip();p.dy=3;await wait(160);p.dy=0;await wait(200);},
  async adios(o){const p=G(o.a);p.dir=-1;p.pose="wave";await wait(600);p.pose="idle";await mueve(o.a,PORTON[0],PORTON[1]);await mueve(o.a,246,PORTON[1]);p.vis=0;},
  async pasa(o){const p=G(o.a);await mueve(o.a,PORTON[0],PORTON[1]);await mueve(o.a,PORTON[0]+8,PORTON[1]);p.dir=-1;await wait(300);},
  async duda(o){const id={di_senor:"senor",di_senora:"mujer",di_joven:"joven"}[o.x]||o.x,p=G(id);if(!p||p.vis===0)return;p.dy=3;await wait(200);p.dy=0;await niega(p);p.dir=p.sent?1:-1;},
  async sevade(o){const p=G(o.a);p.dir=-1;p.pose="wave";await wait(700);p.pose="idle";p.dir=1;await mueve(o.a,246,PORTON[1]);p.vis=0;},
  async luisguarda(o){const l=G("luis"),t=cosaDe(o.k);if(t){await mueve("luis",t.x+10,t.y+6);quita(o.k);}else{await mueve("luis",cx()+22,pies());W.encima=null;W.cq.dy=0;}l.lleva=o.k;await mueve("luis",148,186);l.dir=1;l.lleva=null;W.encaja.push(o.k);SFX.blip();await wait(300);},
  async perros22(o){const v=W.perros.viejo,j=W.perros.joven,L=[38,193],D=[90,193],pv=o.lado==="vj"?L:D,pj=o.lado==="vj"?D:L;v.lleva=null;j.lleva=null;v.paseo=0;j.ronda=0;await Promise.all([perroA("viejo",pv[0],pv[1],"walk"),perroA("joven",pj[0],pj[1],"run")]);v.pose="sit";j.pose="sit";v.dir=1;j.dir=1;await acasa();await wait(300);},
  async sinhueso(o){const d=W.perros[o.de.replace("perro_","")];d.pose="triste";d.pena=1;W.sinhueso=o.de.replace("perro_","");await wait(500);},
  async acaricia(o){const d=perroDe(o.a);await ranaA(d.x+30,d.y+4);bounce(4);await wait(500);d.pose="sit";d.pena=1;},
  async cola22(o){const rem=["senor","mujer","joven"].filter(k=>k!==W.fuera),own=rem[o.k==="a"?0:1],oth=rem[o.k==="a"?1:0],ord=o.lado==="ab"?rem:rem.slice().reverse(),en=[[82,186],[104,186]];
    V.pc=own;V.oc=oth;V.qc=own==="mujer"?"senora":own;V.ra=rem[0];V.rb=rem[1];W.casa=[128,205];await acasa();await Promise.all(ord.map(async(id,i)=>{const p=G(id);p.lleva=null;await mueve(id,en[i][0],en[i][1]);p.dir=-1;}));await wait(300);},
  async sevan22(){await Promise.all(["senor","mujer","joven"].filter(k=>G(k).vis!==0).map(async(id,i)=>{await wait(i*350);const p=G(id);await mueve(id,PORTON[0],PORTON[1]);await mueve(id,246,PORTON[1]);p.vis=0;}));},
  async alza(o){const p=G(o.a);W.cq.dy=-7;await wait(500);p.pose="wave";await wait(700);p.pose="idle";p.dir=1;await mueve(o.a,246,PORTON[1]);p.vis=0;W.cq.dy=0;},
  async final22(){W.noche=1;W.casa=[124,190];await Promise.all([acasa(),mueve("carmen",190,204)]);G("carmen").dir=-1;await wait(500);if((W.marcas||[]).every(m=>m==="ok")){const h=G("hombre"),l=G("luis");h.vis=1;h.x=244;h.y=PORTON[1];await mueve("hombre",PORTON[0]-4,PORTON[1]);for(let k=0;k<3;k++){h.dir=-h.dir;await wait(200);}W.encaja=[];l.lleva="periodico";l.pose="arriba";l.dir=1;SFX.blip();await wait(400);await mueve("hombre",l.x+20,l.y);l.lleva=null;l.pose="idle";h.lleva="periodico";SFX.blip();h.dir=-1;h.pose="wave";await wait(700);h.pose="idle";await mueve("hombre",246,PORTON[1]);h.vis=0;}else{const l=G("luis");l.dir=1;await niega(l);l.dir=1;await wait(300);}},
  async carrova(){const pi=G("piraguero"),v=W.perros.viejo,j=W.perros.joven;W.carro="cerrado";SFX.blip();await wait(400);pi.x=CARRO[0]+30;pi.y=CARRO[1]+2;pi.dir=-1;pi.paso=1;v.lleva=null;j.lleva=null;v.paseo=0;j.ronda=0;W.carroX=CARRO[0];v.pose="walk";j.pose="run";v.dir=-1;v.y=196;j.y=204;j.x0=Math.max(j.x,70);j.fase=F;v.pena=W.sinhueso==="viejo"?1:0;j.pena=W.sinhueso==="joven"?1:0;W.seva=1;await wait(300);},
  async carrofin(){const pi=G("piraguero");W.seva=2;pi.paso=0;pi.pose="wave";pi.dir=1;await wait(900);pi.pose="idle";pi.dir=-1;pi.paso=1;W.seva=3;await wait(1400);},

  /* ----- story 23: El bebé duerme ----- */
  async inicio23(){W.gente={piraguero:{x:CARRO[0]+4,y:CARRO[1]-6,dir:1},senora:{x:B[1][0]-9,y:161,dir:1,sent:1},luis:{x:B[0][0]-13,y:161,dir:1,sent:1,animo:"cansado"},hombre:{x:B[2][0]+2,y:161,dir:1,sent:1,animo:"triste"},carmen:{x:38,y:210,dir:1,lleva:"mochila"}};
    W.coche={x:164,y:176,capota:0,bebe:"duerme"};W.perros={canelo:{x:112,y:208,pose:"idle",dir:1,mueve:1}};W.cosas=[{id:"caida",k:"piragua",x:184,y:178,rot:Math.PI/2}];W.juguetes=0;W.concojin=0;
    W.palomas=[0,1,2,3,4].map(i=>({i,x:CABLE(i)[0],y:CABLE(i)[1],dir:i%2?1:-1,en:"cable"}));W.casa=[156,207];Object.assign(W.cq,{x:W.casa[0]-16,y:W.casa[1]-27,s:1});W.tarde=1;},
  async alegra(o){const p=G(o.a),k=o.k||"piragua";await ranaA(70,190);W.encima=k;SFX.blip();await ranaA(p.sent?p.x-4:p.x+26,p.sent?p.y+22:p.y+2);W.encima=null;if(o.no)return;if(o.a==="hombre")quita("caida");quita("hielo");p.animo=o.a==="hombre"?"contento":null;p.hace="come";p.que="piragua";p.lleva=null;SFX.blip();await wait(700);p.hace=null;p.lleva="piragua";await acasa();},
  async cojin(){const ca=G("carmen");await mueve("carmen",B[0][0]-4,180);ca.lleva=null;W.cosas.push({id:"cojin",k:"mochila",x:B[0][0]-21,y:ASIENTO+1,z:150});SFX.blip();await wait(400);await mueve("carmen",38,210);ca.dir=1;},
  async abuelallega(){W.gente.abuela={x:250,y:204,dir:-1,paso:1};await mueve("abuela",B[0][0]+6,176);const a=G("abuela");a.sent=1;a.x=B[0][0]+5;a.y=161;a.dir=1;await wait(400);a.ojos=1;await perroA("canelo",124,180,"walk");const c=W.perros.canelo;c.pose="idle";c.mueve=1;c.dir=1;await wait(300);},
  async canelo23(o){const c=W.perros.canelo,a=G("abuela");if(c.chal){a.pose="vaso";await wait(350);c.chal=0;SFX.blip();await wait(250);}c.correa=null;c.mueve=0;a.lleva=null;a.pose="idle";
    if(o.como==="contento"){a.pose="fan0";a.lleva="bola";c.pose="idle";c.mueve=1;SFX.blip();await wait(600);}
    else if(o.como==="cansado"){for(let k=0;k<2;k++){await perroA("canelo",196,208,"run");await perroA("canelo",124,180,"run");}c.dir=1;c.pose="cansado";await wait(500);}
    else{a.pose="vaso";await wait(350);c.correa=[B[0][0]+19,160];c.pose="triste";SFX.blip();a.pose="idle";await wait(500);}},
  async pelota(o){const c=W.perros.canelo,a=G("abuela"),n=+(o&&o.n||1);a.pose="vaso";a.lleva=null;for(let k=0;k<n;k++){const t={id:"bola",k:"bola",x:a.x+16,y:178};W.cosas.push(t);for(let i=1;i<=7;i++){t.x=a.x+16+(o&&o.corta?6:0)*i/7;t.y=178+((o&&o.corta)?2:30)*i/7;await wait(TICK);}if(o&&o.corta)return;c.mueve=0;await perroA("canelo",t.x-14,t.y+2,"run");quita("bola");c.lleva="bola";await perroA("canelo",124,180,"run");c.dir=1;c.lleva=null;c.pose="idle";c.mueve=1;await wait(200);}a.pose="idle";},
  async cae(){const c=W.perros.canelo;c.mueve=0;c.pose="cansado";await wait(500);},
  async chal(o){const c=W.perros.canelo,a=G("abuela");a.pose="vaso";await wait(300);c.chal=1;if(!o||!o.mal){c.pose="cansado";c.mueve=0;}SFX.blip();await wait(400);a.pose="idle";},
  async caricia(o){const c=W.perros.canelo,a=G("abuela");a.pose="vaso";await wait(600);if(!o||!o.mal){c.correa=null;c.pose="idle";c.mueve=1;}await wait(400);a.pose="idle";},
  async abuelamal(o){const c=W.perros.canelo,dijo=o.dijo.replace("di_",""),es=o.es,x0=c.x;
    if(dijo==="contento"){if(es==="cansado"){await acts.pelota({corta:1});quita("bola");G("abuela").pose="idle";c.dy=3;ladra(1);await wait(400);c.dy=0;}
      else{const t={id:"bola",k:"bola",x:G("abuela").x+16,y:178};W.cosas.push(t);for(let i=1;i<=7;i++){t.x+=8;t.y+=2.5;await wait(TICK);}c.pose="walk";for(let i=0;i<4;i++){c.x+=3;await wait(TICK);}c.pose="triste";gime();await wait(600);c.x=x0;quita("bola");}}
    else if(dijo==="cansado"){await acts.chal({mal:1});if(es==="contento"){grune();for(let i=0;i<8;i++){c.x=x0+(i%2?3:-3);await wait(90);}c.x=x0;ladra(1);}else{gime();await wait(700);}c.chal=0;}
    else{await acts.caricia({mal:1});if(es==="cansado"){grune();await wait(700);}else{c.pose="bark";for(let k=0;k<2;k++){c.dy=7;ladra(1);await wait(220);c.dy=0;await wait(160);}c.pose="idle";}}
    await wait(200);},
  async abuelahace(o){if(o.que==="contento")await acts.pelota({n:1});else if(o.que==="cansado")await acts.chal();else await acts.caricia();G("abuela").lleva=null;},
  async capota(o){const s=G("senora");s.pose="offer";s.dir=-1;await wait(300);W.coche.capota=+o.v;SFX.blip();await wait(350);s.pose="idle";s.dir=1;},   // she reaches over and pulls the hood
  async mira23(){const s=G("senora");s.x+=4;await wait(700);s.x-=4;await wait(250);},
  async manita(o){W.coche.mano=+o.v;if(+o.v)W.coche.bebe="rie";await wait(400);},
  async quieto(){const q=W.cq;q.hace="quieto";await wait(1300);q.hace=null;},
  async canta(){const q=W.cq;q.hace="canta";coquiS();await wait(1300);q.hace=null;},
  async rie(){const o=W.coche;o.bebe="rie";o.tiembla=0;[0,.12,.24].forEach((t,i)=>tone(900+i*120,t,.07,"sine",.03,1100));await wait(800);o.mano=0;},
  async duerme(){const o=W.coche;o.bebe="duerme";o.mano=0;o.tiembla=0;await wait(300);},
  async despierta(){await despierta();},
  async mece(){await mece();},
  async turno23a(){const l=G("luis");l.animo=null;l.sent=0;l.pose="arriba";await wait(500);l.pose="idle";await mueve("luis",92,192);l.dir=-1;await wait(300);l.lleva="piragua";l.dir=1;SFX.blip();const pg=libre();W.ladrona=pg;pio();await palomaA(pg,W.coche.x+14,W.coche.y-33);pg.z=400;await wait(400);},
  async turno23b(){const pg=W.ladrona;bounce(8);await wait(200);await Promise.all([alcable(pg),despierta()]);W.ladrona=null;await wait(500);await mece();},
  async tres23(){const c=W.perros.canelo,l=G("luis"),h=G("hombre"),a=G("abuela"),pg=libre();if(c.chal){a.pose="vaso";await wait(300);c.chal=0;a.pose="idle";}c.correa=null;c.mueve=0;a.lleva=null;a.pose="idle";pio();
    await Promise.all([(async()=>{await palomaA(pg,190,204);await wait(200);await palomaA(pg,150,150);await alcable(pg);})(),(async()=>{await wait(250);await perroA("canelo",196,204,"run");await perroA("canelo",124,199,"run");c.dir=1;c.pose="cansado";})(),
      (async()=>{await wait(500);l.lleva="papel";W.cosas.push({id:"hielo",k:"piragua",x:70,y:196,rot:Math.PI/2});SFX.bonk();await wait(300);l.animo="triste";})(),(async()=>{await wait(900);h.lleva=null;h.lee=1;h.animo="contento";h.paso=1;})()]);await wait(500);},
  async ayuda(o){const q=o.q,c=W.perros.canelo;if(q==="cansado"){await ranaA(B[0][0]-8,184);quita("cojin");W.encima="mochila";SFX.blip();await ranaA(c.x+46,c.y+2);W.encima=null;W.cosas.push({id:"cojin",k:"mochila",x:c.x+13,y:c.y+1,z:c.y-1});W.concojin=1;SFX.blip();await wait(400);}
    else if(q==="triste"){await acts.alegra({a:"luis"});}
    else{const h=G("hombre");await ranaA(h.x-2,h.y+24);h.dy=2;await wait(200);h.dy=0;for(let k=0;k<3;k++){W.cq.dy=-3;await wait(140);W.cq.dy=0;await wait(140);}}
    await acasa();},
  async ayudamal(o){const q=o.q,x=o.x,c=W.perros.canelo,p=x==="perro"?null:G(x),tx=p?(p.sent?p.x-4:p.x+24):c.x+36,ty=p?(p.sent?p.y+22:p.y+2):c.y;
    if(q==="cansado"){await ranaA(B[0][0]-8,184);const t=cosaDe("cojin");if(t)t.vis=0;W.encima="mochila";await ranaA(tx,ty);if(x==="luis"){p.dy=3;sollozo();await wait(700);p.dy=0;}else{risa();p.dy=2;await wait(700);p.dy=0;}await ranaA(B[0][0]-8,184);W.encima=null;if(t)t.vis=1;}
    else if(q==="triste"){await ranaA(70,190);W.encima="piragua";await ranaA(tx,ty);if(x==="perro"){W.encima=null;c.pose="come";await wait(500);c.pose="cansado";c.dy=4;ladra(1);await wait(400);c.dy=0;}else{W.encima=null;p.lleva="piragua";SFX.blip();await wait(300);}}
    else{await ranaA(tx,ty);for(let k=0;k<2;k++){W.cq.dy=-5;await wait(150);W.cq.dy=0;await wait(150);}if(x==="perro"){grune();c.dy=2;await wait(700);c.dy=0;}else{sollozo();p.dy=3;await wait(700);p.dy=0;}}
    await acasa();},
  async resto(){const c=W.perros.canelo,l=G("luis"),ca=G("carmen"),t=cosaDe("cojin");if(!W.concojin){await mueve("carmen",B[0][0]-6,180);if(t)quita("cojin");ca.lleva="mochila";await mueve("carmen",c.x+30,c.y+2);ca.lleva=null;W.cosas.push({id:"cojin",k:"mochila",x:c.x+13,y:c.y+1,z:c.y-1});W.concojin=1;SFX.blip();await wait(300);}
    if(l.animo==="triste"){await mueve("carmen",70,196);ca.lleva="piragua";await mueve("carmen",l.x+18,l.y+4);ca.lleva=null;quita("hielo");l.lleva="piragua";l.animo=null;SFX.blip();await wait(300);}
    await mueve("carmen",38,210);ca.dir=1;},
  async final23(){W.perros.canelo.pose="cansado";const a=G("abuela"),n=W.juguetes||0,jug=()=>W.cosas.filter(o=>o.id&&o.id.startsWith("jug"));G("hombre").animo=null;G("hombre").lee=0;G("hombre").paso=0;a.ojos=0;await wait(400);a.sent=0;a.x=B[0][0]+10;a.y=180;await wait(300);
    if(n<=1){const t=jug()[0];if(t){await ranaA(t.x-14,t.y+6);quita(t.id);W.encima="sonajero";await ranaA(W.coche.x-28,W.coche.y+10);W.encima=null;await wait(300);}}
    else{const sn=G("senora"),t=jug()[0];await mueve("senora",t.x-12,t.y+2);quita(t.id);sn.lleva=t.k;sn.dir=1;await wait(300);}   // the other toys stay where they fell: that is what the day cost
    await acasa();},
  async ranacansada(){W.cq.hace="cansado";await wait(500);},
  async sevan23(){W.cq.hace=null;const c=W.perros.canelo;c.pose="walk";quita("cojin");G("carmen").lleva="mochila";await Promise.all([mueve("abuela",250,200),mueve("carmen",250,206),mueve("luis",250,196),perroA("canelo",250,210,"walk"),(async()=>{await wait(500);await ranaA(232,204,4);})()]);},

  /* ----- Escuchar: plain acts that the picture stories and the routines are written with ----- */
  async g(o){const p=G(o.quien);if(!p)return;Object.keys(o).forEach(k=>{if(!["act","quien","ms"].includes(k))p[k]=o[k];});if(o.ms)await wait(o.ms);},                       // set anything on a person
  async anda(o){const p=G(o.quien),d=Math.hypot(o.x-p.x,o.y-p.y),pr=(async()=>{await mueve(o.quien,o.x,o.y,o.lento?Math.max(4,R(d/2)):null);if(o.dir)p.dir=o.dir;if(o.sent){p.sent=1;p.dir=1;}if(o.fuera)p.vis=0;})();if(!o.suelto)await pr;},   // suelto: the line is said while he walks
  async saluda(o){const p=G(o.quien);if(!p)return;const d=p.dir;if(o.dir)p.dir=o.dir;p.pose=o.que||"wave";await wait(o.ms||750);p.pose="idle";p.dir=d;},
  async brinco(o){const p=o.quien==="perro"?W.perros[o.n||"canelo"]:G(o.quien);for(let k=0;k<(o.n2||2);k++){p.dy=o.h||4;await wait(130);p.dy=0;await wait(130);}},
  async rana(o){const pr=ranaA(o.x,o.y,o.h);if(!o.suelto)await pr;},
  async sale(){const q=W.cq;await ranaA(PORTON[0]+4,PORTON[1]+2);await ranaA(236,PORTON[1]+2,2);q.vis=0;},
  async encima(o){W.encima=o.k||null;SFX.blip();await wait(200);},
  async can(o){const d=W.perros[o.n];if(!d)return;const pr=(async()=>{if(o.x!=null)await perroA(o.n,o.x,o.y,o.modo||"walk");Object.keys(o).forEach(k=>{if(!["act","n","x","y","modo","ms","suelto"].includes(k))d[k]=o[k];});})();if(!o.suelto)await pr;if(o.ms)await wait(o.ms);},
  async pal(o){const pg=o.i!=null?W.palomas[o.i]:libre();if(!pg)return;if(o.cable)await alcable(pg);else if(o.x!=null){pio();await palomaA(pg,o.x,o.y);pg.en="suelo";}pg.pose=o.pose||"";if(o.dir)pg.dir=o.dir;if(o.z)pg.z=o.z;await wait(o.ms||200);},
  async cosa(o){if(o.quita){quita(o.quita);return;}W.cosas.push({id:o.id,k:o.k,x:o.x,y:o.y,rot:o.rot||0,z:o.z});if(o.son&&SFX[o.son])SFX[o.son]();await wait(o.ms||150);},
  async rueda(o){const t=cosaDe(o.id);if(!t)return;const x0=t.x,y0=t.y,n=o.n||10,pr=(async()=>{for(let i=1;i<=n;i++){t.x=x0+(o.x-x0)*i/n;t.y=y0+(o.y-y0)*i/n;await wait(TICK);}if(o.fuera)quita(o.id);})();if(!o.suelto)await pr;},
  async luz(o){W.noche=o.v;if(o.luna)W.luna=1;SFX.blip();await wait(500);},
  async rebota(o){const t=cosaDe(o.id);if(!t)return;const y0=t.y;for(let k=0;k<(o.n||3);k++){for(const d of [-6,-10,-6,0]){t.y=y0+d;await wait(60);}SFX.hop();}},
  async manos(o){W.manos=o.v||null;SFX.blip();await wait(200);},
  async hace(o){W.cq.hace=o.que||null;await wait(o.ms||200);},
  async ladra(o){ladra(o.n||1);const d=W.perros[o.quien||"canelo"];if(d){for(let k=0;k<(o.n||1);k++){d.dy=3;await wait(140);d.dy=0;await wait(140);}}},
  async ronda1(o){const d=W.perros[o.n||"joven"];d.x0=d.x;d.pose="run";d.fase=F;d.ronda=1;await wait(o.ms||1500);d.ronda=0;d.pose="sit";d.x=d.x0;d.dir=1;},

  // everybody at once, to look at the drawing
  async prueba(o){const b=BANCOS,n=+(o&&o.n||1);
    W.gente={piraguero:{x:CARRO[0]+4,y:CARRO[1]-6,pose:"idle",dir:1}};W.palomas=[0,1,2,3,4].map(i=>({i,x:CABLE(i)[0],y:CABLE(i)[1],dir:i%2?1:-1,en:"cable"}));W.cosas=[];W.perros={};
    if(n===5){W.gente={};W.palomas=[];W.carro=0;["idle","walk","sit","lie","come","triste","cansado","run","duerme"].forEach((ps,k)=>{W.perros["x"+k]={x:50+(k%4)*46,y:160+(k>>2)*26,pose:ps,dir:1,tipo:o.t,pena:+(o.pena||0)};});W.cq.vis=0;return;}
    if(n===2){Object.assign(W.gente,{senor:{x:b[0][0]-8,y:b[0][1]+11,dir:1,sent:1},mujer:{x:b[1][0]-8,y:b[1][1]+11,dir:1,sent:1},joven:{x:b[2][0]-10,y:b[2][1]+11,dir:1,sent:1},hombre:{x:b[2][0]+11,y:b[2][1]+11,dir:1,sent:1,lee:1},luis:{x:186,y:200,dir:-1},carmen:{x:150,y:204,dir:-1,lleva:"bolsa"}});
      Object.assign(W.cq,{x:112,y:180,s:1});W.perros={viejo:{x:40,y:204,pose:"lie",dir:1},joven:{x:68,y:206,pose:"sit",dir:1,lleva:"hueso"}};W.encaja=["periodico","cartera"];W.cosas=[{k:"caja",x:FAROL[0],y:206},{k:"sombrilla",x:b[1][0]+14,y:b[1][1]+5}];}
    else{Object.assign(W.gente,{luis:{x:b[0][0]-13,y:b[0][1]+11,dir:1,sent:1,animo:"cansado"},abuela:{x:b[0][0]+5,y:161,dir:1,sent:1,ojos:1},senora:{x:b[1][0]-9,y:b[1][1]+11,dir:1,sent:1},hombre:{x:b[2][0]+2,y:b[2][1]+11,dir:1,sent:1,animo:o.h||"triste"},carmen:{x:52,y:208,dir:1,animo:"contento"}});
      Object.assign(W.cq,{x:130,y:175,s:1,hace:o.rana||"canta"});W.coche={x:164,y:176,capota:+(o.cap||0),bebe:o.bebe||"duerme",mano:+(o.mano||0)};W.perros={canelo:{x:124,y:180,pose:o.can||"triste",dir:1,chal:+(o.chal||0),correa:o.can==="triste"||!o.can?[B[0][0]+19,160]:null}};
      W.cosas=JUG.map((k,i)=>({k,x:JUGEN[i][0],y:JUGEN[i][1]}));W.tarde=1;}},
};
async function stake(lost,max,en){SFX.bonk();await wait(300);}
function poke(what){if(what==="pajaro")pio();}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)+(W.gente[k].lleva?"["+W.gente[k].lleva+"]":"")).join(" ")+" palomas="+(W.palomas||[]).map(o=>o.en||"?").join("")+" posadas="+(W.posadas||0)+" cosas="+(W.cosas||[]).filter(o=>o.vis!==0).map(o=>o.id||o.k).join(",")+" caja="+(W.encaja||[]).join(",")+" manos="+JSON.stringify(W.manos||{})+" bandeja="+W.bandeja+" jug="+(W.juguetes||0)+" marcas="+(W.marcas||[]).join(",")+" perros="+Object.keys(W.perros||{}).map(k=>k+":"+W.perros[k].pose+(W.perros[k].lleva?"+"+W.perros[k].lleva:"")).join(",")+(W.coche?" bebe="+W.coche.bebe+"/"+(W.coche.capota?"capota":"abierto"):"");
KIT.escena({id:"banco",CAM:{wide:[22,0,196,216]},heartAt:[110,30],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({respEn:[120,64],gente:{},palomas:[],cosas:[],perros:{},coche:null,bandeja:null,encima:null,manos:null,encaja:[],noche:0,tarde:0,carro:1,carroX:null,seva:0,posadas:0,juguetes:0,tarjeta:null,marcas:null,cq:{x:LUGAR.centro[0],y:LUGAR.centro[1],s:1,dy:0,al:1,vis:1,bub:null,hace:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
