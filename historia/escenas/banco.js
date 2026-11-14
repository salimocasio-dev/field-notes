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
const SUELO=132,BANCOS=[[96,150],[144,150],[192,150]],CARRO=[47,178],FAROL=[168,154],BOTE=[211,176];   // where the paving starts; the three benches (the middle of the seat); the cart; the lamp post; the bin
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
  // the bin
  b.rect(BOTE[0]-5,BOTE[1]-15,10,15,"#2E7A44");b.rect(BOTE[0]-5,BOTE[1]-15,3,15,"#4EA864");b.rect(BOTE[0]-6,BOTE[1]-17,12,3,"#1E5A30");b.frame(BOTE[0]-6,BOTE[1]-16,12,17,OUT);
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
  sombrilla(){const b=new Buf(8,30);b.rect(3,0,2,3,"#3A3A46");for(let y=3;y<24;y++){const w=y<8?2+((y-3)>>1):y>19?4-((y-20)>>1):4;b.rect(4-(w>>1),y,w,1,y%4===0?"#C89A10":"#F0C020");}b.rect(3,24,2,5,"#8A5A2A");b.rect(3,28,4,1,"#8A5A2A");return b.outline().done();},
  mochila(){const b=new Buf(15,17);b.rect(1,3,13,13,"#E88A2A");b.rect(1,3,13,2,"#F8B860");b.rect(3,8,9,6,"#B85A14");b.rect(3,8,9,1,"#F8B860");b.rect(5,0,5,3,"#B85A14");b.px(7,11,"#F2F2F8");return b.outline().done();},
  baston(){const b=new Buf(8,30);b.rect(3,3,2,26,"#8A5A2A");b.rect(3,1,5,2,"#8A5A2A");b.rect(7,2,1,3,"#8A5A2A");b.rect(3,28,2,1,"#3A3A46");return b.outline().done();},
  cartera(){const b=new Buf(13,13);b.rect(1,5,11,7,"#A8283C");b.rect(1,5,11,2,"#D0485C");b.px(6,8,"#F0C020");b.rect(3,1,1,4,"#7A1C2A");b.rect(9,1,1,4,"#7A1C2A");b.rect(3,0,7,1,"#7A1C2A");return b.outline().done();},
  gorra(){const b=new Buf(14,7);b.rect(1,1,9,5,"#D0302A");b.rect(1,1,9,1,"#F0605A");b.rect(9,4,5,2,"#A82020");return b.outline().done();},
  periodico(){const b=new Buf(15,8);b.rect(1,1,13,6,"#F2F2F8");[2,4].forEach(y=>b.rect(2,y,11,1,"#9494A6"));b.rect(7,1,1,6,"#C8C8D4");return b.outline().done();},
  bolsa(){const b=new Buf(10,13);b.rect(1,3,8,9,"#C89A60");b.rect(1,3,3,9,"#E0B880");b.rect(1,1,8,2,"#A87A40");b.rect(2,0,6,1,"#C89A60");return b.outline().done();},
  hueso(){const b=new Buf(13,7);b.rect(3,2,7,3,"#F8F4E8");[[2,1],[2,5],[10,1],[10,5]].forEach(p=>b.ell(p[0],p[1],1.6,1.6,["#F8F4E8"]));return b.outline().done();},
  caja(){const b=new Buf(28,16);b.rect(1,5,26,10,"#C89A60");b.rect(1,5,26,2,"#E0B880");b.rect(1,13,26,2,"#A87A40");b.rect(3,2,22,3,"#8A6234");b.rect(12,8,4,2,"#8A6234");return b.outline().done();},
  sonajero(){const b=new Buf(8,12);b.ell(4,4,3,3,["#E86AA0","#F8A0C8"]);b.px(3,3,"#FFFFFF");b.rect(3,7,2,4,"#F0C020");return b.outline().done();},
  oso(){const b=new Buf(11,13);b.ell(5.5,8,3.6,4,["#8A5A2A","#B07A3C"]);b.ell(5.5,3.5,3,3,["#8A5A2A","#B07A3C"]);b.px(3,1,"#8A5A2A");b.px(8,1,"#8A5A2A");b.px(4,3,OUT);b.px(7,3,OUT);b.px(5,5,"#2A1A0E");return b.outline().done();},
  bloque(){const b=new Buf(9,9);b.rect(1,1,7,7,"#3A6AC8");b.rect(1,1,7,2,"#7AA0F0");b.rect(3,3,3,3,"#F0C020");return b.outline().done();},
  patito(){const b=new Buf(11,9);b.ell(5,5.5,4,2.6,["#C89A10","#F0C020","#FFE060"]);b.ell(8,2.5,2,2,["#F0C020","#FFE060"]);b.px(9,2,OUT);b.rect(10,3,1,1,"#E88A2A");return b.outline().done();},
  chal(){const b=new Buf(24,9);b.ell(12,5,11,3.6,["#5A3A8A","#7A56B0","#A07ED0"]);for(let x=2;x<22;x+=3)b.px(x,8,"#5A3A8A");return b.outline().done();},
  bola(){const b=new Buf(9,9);b.ell(4.5,4.5,3.6,3.6,["#C8401E","#F4683C","#FFA07A"]);b.rect(2,4,5,1,"#FFFFFF");return b.outline().done();},
  bandeja(){const b=new Buf(18,4);b.rect(1,1,16,2,"#C8C8D4");b.rect(1,1,16,1,"#F2F2F8");return b.outline().done();}};
const cosa=k=>spr("cs"+k,COSA[k]||COSA.bolsa);
// a pigeon: sitting, pecking (head down), flying (wings up and down)
function mkPaloma(pose,f){const b=new Buf(16,13),C=["#5A5A6A","#8A8A9A","#B8B8C8"],baja=pose==="come"&&f;
  if(pose==="vuela"){b.ell(7,7,4.4,2.6,C);b.cap(6,6,4,f?1:11,1.6,[C[2]]);b.cap(8,6,10,f?1:11,1.6,[C[1]]);}
  else{b.ell(6,7,4.6,3.2,C);b.cap(2,7,0,5,1.2,[C[0]]);b.rect(5,10,1,2,"#E0483A");b.rect(8,10,1,2,"#E0483A");}
  const hx=baja?11:10,hy=baja?8:4;b.ell(hx,hy,2.4,2.4,C);b.px(hx+1,hy-1,OUT);b.rect(hx+2,hy+(baja?1:0),2,1,"#E88A2A");if(!baja)b.rect(8,5,2,2,"#3E9A52");return b.outline().done();}
// a dog. tipo: canelo (brown), viejo (big, grey, a long white beard and eyebrows), joven (small, white with black patches)
function mkCan(tipo,pose,f){const b=new Buf(32,24),T={canelo:["#8A5A2A","#B07A3C","#D09A54","#E8BE80"],viejo:["#5A5A66","#7E7E8C","#A0A0AE","#B8B8C6"],joven:["#B8B8C8","#E6E6F0","#FFFFFF","#FFFFFF"]}[tipo]||[],v=tipo==="viejo",j=tipo==="joven",X=13,Y=13;
  const lie=pose==="lie"||pose==="cansado",sit=pose==="sit"||pose==="come"||pose==="bark"||pose==="triste",run=pose==="run",a=f?1:-1,k=j?.8:1;
  const cola=pose==="triste"||v?[X-12,Y+5]:j?[X-10,Y-3+(f?1:-1)]:[X-12,Y-6+(f?1:-1)];b.cap(X-9*k,Y+1,cola[0],cola[1],1.4,[T[1]]);
  if(lie){b.ell(X,Y+6,10*k,4,T);b.rect(X+6,Y+8,6,2,T[1]);}
  else if(sit){b.ell(X-1,Y+4,7*k,6*k+(v?1:0),T);b.rect(X+3,Y+5,2,6,T[1]);b.rect(X+6,Y+5,2,6,T[2]);b.ell(X-4,Y+9,4,2,[T[1]]);}
  else{b.ell(X,Y+2,10*k,(v?6:5)*k,T);
    if(run){b.cap(X-6,Y+5,X-11+a*2,Y+9,1.3,[T[1]]);b.cap(X-3,Y+5,X-7-a*2,Y+10,1.3,[T[0]]);b.cap(X+5,Y+5,X+10+a*2,Y+9,1.3,[T[1]]);b.cap(X+7,Y+5,X+12-a*2,Y+10,1.3,[T[2]]);}
    else{const w=pose==="walk"?a:0;b.rect(X-7+w,Y+6,2,5,T[1]);b.rect(X-4-w,Y+6,2,5,T[0]);b.rect(X+4+w,Y+6,2,5,T[1]);b.rect(X+7-w,Y+6,2,5,T[2]);}}
  if(j){b.ell(X-3,Y+(lie?5:sit?3:1),3,2.4,["#20202A"]);b.ell(X+4,Y+(lie?7:sit?6:3),2,1.6,["#20202A"]);}
  // the head
  const hx=X+10*k+(j?1:0),hy=lie?Y+4:pose==="triste"?Y-1:v?Y-2:Y-3;if(tipo==="canelo")b.rect(hx-4,hy+4,5,2,RP.red[2]);
  b.ell(hx,hy,5*k+(v?.6:0),4.6*k+(v?.4:0),T);b.ell(hx+4*k,hy+1.5,3*k,2.2*k,[T[3]]);
  const caidas=v||pose==="triste"||pose==="cansado";
  if(caidas){b.cap(hx-3,hy-3,hx-4,hy+3,1.6,[j?"#20202A":T[0]]);}else{b.cap(hx-3,hy-3,hx-5,hy+2,1.5,[j?"#20202A":T[0]]);b.cap(hx+1,hy-4,hx+2,hy-7,1.3,[j?"#20202A":T[0]]);}
  if(v){b.rect(hx+2,hy+3,6,2,"#FFFFFF");b.rect(hx+3,hy+5,4,1,"#FFFFFF");b.rect(hx+3,hy+1,5,2,"#FFFFFF");b.rect(hx,hy-3,4,1,"#FFFFFF");b.rect(hx+6,hy,2,2,OUT);}                                   // his long white beard, his white eyebrows
  if(pose==="cansado"){b.rect(hx,hy-1,2,2,OUT);b.px(hx,hy-1,"#FFFFFF");b.rect(hx+2,hy+3,4,f?3:2,"#7A1C1C");b.rect(hx+4,hy+5,2,f?4:3,"#F08AA0");}        // heavy open eyes, a yawn, his tongue out
  else{b.px(hx+1,hy-1,OUT);if(pose==="bark"&&f)b.rect(hx+3,hy+3,4,2,"#7A1C1C");else if(pose==="come")b.rect(hx+3,hy+3,3,2,f?"#7A1C1C":T[3]);else if(!v)b.px(hx+4,hy+3,"#7A2A1A");}
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
const alto=id=>{const w=QUIEN[id]||{},p=W.gente[id];return id==="abuela"?51:w.nino?(p&&p.sent?40:44):(p&&p.sent?49:56);};
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
function animo(c,k,hx,hy){if(k==="triste"){fr(c,hx-3,hy+3,6,2,"#C89A70");fr(c,hx-2,hy+4,4,1,"#7A2A1A");fr(c,hx-3,hy+5,1,1,"#7A2A1A");fr(c,hx+2,hy+5,1,1,"#7A2A1A");fr(c,hx-4,hy+1,1,3+((F>>3)%2),"#5A9AEA");}
  else if(k==="cansado"){fr(c,hx-4,hy-1,3,1,"#20140A");fr(c,hx+1,hy-1,3,1,"#20140A");fr(c,hx-2,hy+3,4,(F>>3)%3?4:2,"#7A1C1C");fr(c,hx+6,hy-6+((F>>3)%2),1,2,"#A8CCF8");}
  else if(k==="contento"){fr(c,hx-3,hy+3,6,2,"#7A1C1C");fr(c,hx-2,hy+3,4,1,"#FFFFFF");fr(c,hx-4,hy+2,1,1,"#7A1C1C");fr(c,hx+3,hy+2,1,1,"#7A1C1C");}}
function tenida(c,k,x,y,girada){const im=cosa(k);if(girada){c.save();c.translate(x,y);c.rotate(girada);c.drawImage(im,-(im.width>>1),-im.height);c.restore();}else c.drawImage(im,R(x)-(im.width>>1),R(y)-im.height);}
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  if(id==="abuela"){const ps=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle");c.save();c.translate(x,y-50);if(d<0)c.scale(-1,1);c.drawImage(spr("ab"+ps+habla,()=>mkAbuela(ps,habla)),-30,0);c.restore();if(p.lleva)tenida(c,p.lleva,x+d*12,y-14);return;}
  const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="arriba"?"wave0":(p.pose||"idle"),im=spr("pb"+id+pose+habla+(p.sent?1:0),()=>KIT.mkPersona(w,pose,habla,p.sent)),top=y-im.height+1+((p.paso&&a%2)?-1:0)-(p.dy||0)+(p.animo==="cansado"?2:0);
  c.save();c.translate(x,top);if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  (w.extra||[]).forEach(k=>extra(c,k,x,top+11,d,p,im));if(p.animo)animo(c,p.animo,x,top+11);
  if(p.hace==="come")tenida(c,p.que||"piragua",x+d*5,top+24+(a%2));else if(p.hace==="bebe")tenida(c,"agua",x+d*4,top+20,d*(a%2?1.9:1.6));
  else if(p.lleva)tenida(c,p.lleva,x+d*10,top+(w.nino?34:38));
  if(p.lee){fr(c,x-8,top+24,16,9,OUT);fr(c,x-7,top+25,14,7,"#F2F2F8");fr(c,x,top+25,1,7,"#C8C8D4");[27,29].forEach(yy=>{fr(c,x-6,top+yy,5,1,"#9494A6");fr(c,x+2,top+yy,4,1,"#9494A6");});}}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui"||q.hace==="canta"||q.hace==="come")&&a%2?1:0,dy=R(q.dy),cx=b.x+(b.w>>1),m=W.manos||{};
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.bandeja){g.drawImage(cosa("bandeja"),cx-9,b.y+dy-3);if(W.bandeja!==1)tenida(g,W.bandeja,cx,b.y+dy-2);}
  // what he holds: one thing in each hand; the one he is eating or drinking goes to his mouth
  [["i",-1],["d",1]].forEach(s=>{const k=m[s[0]];if(!k)return;const enboca=(q.hace==="come"&&k.startsWith("piragua"))||(q.hace==="bebe"&&k==="agua");
    if(enboca&&k==="agua")tenida(g,k,cx+s[1]*3,b.y+dy+10,s[1]*(a%2?2.2:1.9));else if(enboca)tenida(g,k,cx+s[1]*2,b.y+dy+21+(a%2));else tenida(g,k,cx+s[1]*17,b.y+dy+b.h-2);});
  if(q.hace==="canta"){const t=(F>>2)%4;[[14,-4],[20,-10]].forEach((n,i)=>{const nx=cx+n[0]+t,ny=b.y+dy+n[1]-t*(i+1);fr(g,nx,ny,1,6,OUT);fr(g,nx-2,ny+5,3,2,OUT);fr(g,nx+1,ny,2,1,OUT);});}
  if(q.hace==="quieto")mano(g,cx+16,b.y+dy+2);}
function perro(c,n,a){const o=W.perros[n];if(!o||o.vis===0)return;const anda=o.pose==="walk"||o.pose==="run"||o.pose==="bark"||o.pose==="come"||o.pose==="cansado"||o.pose==="triste"||o.mueve,f=anda?(a>>(o.pose==="run"?0:1))%2:0,tp=o.tipo||n,im=spr("can"+tp+o.pose+f,()=>mkCan(tp,o.pose,f));
  c.save();c.translate(R(o.x),R(o.y)-im.height+2-(o.dy||0));if(o.dir<0)c.scale(-1,1);c.drawImage(im,-13,0);
  if(o.lleva){const t=cosa(o.lleva);c.drawImage(t,(n==="joven"?12:15)-(t.width>>1),(o.pose==="lie"||o.pose==="cansado"?17:12));}
  if(o.chal)c.drawImage(cosa("chal"),-12,10);c.restore();
  if(o.correa){const [bx,by]=o.correa;c.strokeStyle="#A82020";c.lineWidth=1;c.beginPath();c.moveTo(R(o.x)+(o.dir<0?-5:5)+.5,R(o.y)-10.5);c.lineTo(bx+.5,by+.5);c.stroke();}}
function coche(c,a){const o=W.coche;if(!o)return;const f=(a>>1)%2,im=spr("coche"+(o.capota?1:0)+(o.bebe||"")+f,()=>mkCoche(o.capota,o.bebe,f)),sx=o.tiembla?(a%2?1:-1):o.mece?R(Math.sin(F/5)*2):0,x=R(o.x)-19+sx,y=R(o.y)-40;
  c.drawImage(im,x,y);
  if(o.bebe==="duerme"&&!o.capota){const t=(F>>3)%3;fr(c,x+27,y+2-t*3,3,1,"#FFFFFF");fr(c,x+28,y+3-t*3,1,1,"#FFFFFF");fr(c,x+27,y+4-t*3,3,1,"#FFFFFF");}   // z z z
  if(o.bebe==="llora"&&o.capota){const t=(F>>1)%6;[[-4,-1],[2,-3],[9,-2],[15,-1]].forEach((p,i)=>fr(c,x+10+p[0]+(i%2?t:-t),y+6+p[1]-((t*2+i*3)%9),1,2,"#5A9AEA"));}                   // tears fly out from under the hood
  if(o.bebe==="rie"&&o.capota){const t=(F>>2)%3;fr(c,x+12,y-2-t,2,1,"#F0C020");fr(c,x+18,y-4-t,2,1,"#F0C020");}}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{};
  c.drawImage(spr("banco",fondo),0,0);
  if(W.noche){c.fillStyle="rgba(40,30,90,.18)";c.fillRect(0,0,SW,SH);fr(c,FAROL[0]-5,36,11,11,"#FFF8C8");c.fillStyle="rgba(255,240,160,.16)";c.beginPath();c.ellipse(FAROL[0],FAROL[1]+18,46,22,0,0,7);c.fill();}
  const L=[];
  if(W.carro!==0)L.push({y:CARRO[1],d:()=>c.drawImage(spr("carro"+(W.carro==="cerrado"?1:0),()=>mkCarro(W.carro==="cerrado")),R(W.carroX!=null?W.carroX:CARRO[0])-24,CARRO[1]-72)});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.sent?p.y-8:p.y,d:()=>gente(c,id,a)});});
  (W.palomas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y,d:()=>{const f=(a>>(o.pose==="vuela"?0:1))%2,im=spr("pal"+(o.pose||"")+f,()=>mkPaloma(o.pose,f));c.save();c.translate(R(o.x),R(o.y));if(o.dir<0)c.scale(-1,1);c.drawImage(im,-7,-12);c.restore();}});});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>{tenida(c,o.k,o.x,o.y,o.rot);if(o.k==="caja")(W.encaja||[]).forEach((k,i)=>{const im=cosa(k);c.drawImage(im,R(o.x)-12+i*6,R(o.y)-10-Math.min(im.height,14)+(i%2)*2,im.width,Math.min(im.height,14));});
    if(o.k==="agua"&&o.charco){fr(c,R(o.x)-9,R(o.y)-1,16,2,"#9CD8F0");fr(c,R(o.x)-6,R(o.y)+1,10,1,"#9CD8F0");}}});});
  Object.keys(W.perros||{}).forEach(n=>{const o=W.perros[n];if(o&&o.vis!==0)L.push({y:o.y,d:()=>perro(c,n,a)});});
  if(W.coche)L.push({y:W.coche.y,d:()=>coche(c,a)});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.bub?38:0)];}
// the doing bubbles: the frog eating, drinking, singing, keeping still
function respIcon(g,k,x,y,w,h,a){const op=(k==="canta"||k==="come")&&(F>>2)%2?1:0,im=spr("cq.6_0"+op,()=>mkCoqui(.6,0,op)),cx=x+(w>>1),fy=y+h-im.height-3;
  g.drawImage(im,cx-(im.width>>1),fy);
  if(k==="come")tenida(g,"piragua",cx+1,fy+19+((F>>2)%2));
  else if(k==="bebe")tenida(g,"agua",cx+2,fy+8,(F>>2)%2?2.2:1.9);
  else if(k==="canta"){const t=(F>>2)%4;[[10,2],[15,-4]].forEach((n,i)=>{const nx=cx+n[0]+t,ny=fy+n[1]-t;fr(g,nx,ny,1,6,OUT);fr(g,nx-2,ny+5,3,2,OUT);fr(g,nx+1,ny,2,1,OUT);});}
  else if(k==="quieto")mano(g,cx+9,fy-4);}
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

const acts={
  async pose(o){const p=G(o.quien);if(p)p.pose=o.que;},
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  // everybody at once, to look at the drawing
  async prueba(o){const b=BANCOS,n=+(o&&o.n||1);
    W.gente={piraguero:{x:CARRO[0]+4,y:CARRO[1]-6,pose:"idle",dir:1}};W.palomas=[0,1,2,3,4].map(i=>({x:CABLE(i)[0],y:CABLE(i)[1],dir:i%2?1:-1}));W.cosas=[];W.perros={};
    if(n===1){Object.assign(W.gente,{hombre:{x:b[1][0]-10,y:b[1][1]+11,dir:1,sent:1,hace:"come"},mujer:{x:b[1][0]+10,y:b[1][1]+11,dir:1,sent:1,hace:"bebe"},luis:{x:b[2][0]-10,y:b[2][1]+11,dir:1,sent:1},carmen:{x:b[2][0]+10,y:b[2][1]+11,dir:1,sent:1,lleva:"agua"}});
      Object.assign(W.cq,{x:100,y:176,s:1});W.bandeja="piragua";W.manos={i:"piragua",d:"agua"};W.palomas[4]={x:RESP(0)[0],y:RESP(0)[1],dir:1};W.palomas[3]={x:b[0][0]+6,y:b[0][1]-2,dir:1,pose:"come"};W.cosas=[{k:"piragua",x:b[0][0]+13,y:b[0][1]-2},{k:"agua",x:b[0][0]-6,y:b[0][1]-2},{k:"piragua3",x:150,y:204},{k:"papel",x:170,y:204}];}
    if(n===5){W.gente={};W.palomas=[];W.carro=0;W.perros={};["idle","walk","sit","lie","come","triste","cansado","run"].forEach((ps,k)=>{W.perros["x"+k]={x:50+(k%4)*46,y:170+(k>3?30:0),pose:ps,dir:1,tipo:o.t};});W.cq.vis=0;return;}
    else if(n===2){Object.assign(W.gente,{senor:{x:b[0][0]-8,y:b[0][1]+11,dir:1,sent:1},mujer:{x:b[1][0]-8,y:b[1][1]+11,dir:1,sent:1},joven:{x:b[2][0]-10,y:b[2][1]+11,dir:1,sent:1},hombre:{x:b[2][0]+11,y:b[2][1]+11,dir:1,sent:1,lee:1},luis:{x:186,y:200,dir:-1},carmen:{x:150,y:204,dir:-1,lleva:"bolsa"}});
      Object.assign(W.cq,{x:112,y:180,s:1});W.perros={viejo:{x:34,y:204,pose:"lie",dir:1},joven:{x:66,y:206,pose:"sit",dir:1,lleva:"hueso"}};W.encaja=["periodico","baston"];
      W.cosas=[{k:"caja",x:FAROL[0],y:176},{k:"sombrilla",x:b[1][0]+14,y:b[1][1]+2},{k:"sombrero",x:b[0][0]+12,y:b[0][1]-2},{k:"cartera",x:120,y:206},{k:"gorra",x:136,y:206},{k:"mochila",x:92,y:208},{k:"hueso",x:150,y:190},{k:"baston",x:200,y:206}];}
    else{Object.assign(W.gente,{luis:{x:b[0][0]-6,y:b[0][1]+11,dir:1,sent:1,animo:"cansado"},senora:{x:b[1][0]-8,y:b[1][1]+11,dir:1,sent:1},hombre:{x:b[2][0]+4,y:b[2][1]+11,dir:1,sent:1,animo:"triste"},carmen:{x:60,y:200,dir:1,animo:"contento"},abuela:{x:84,y:204,dir:1}});
      Object.assign(W.cq,{x:104,y:180,s:1,hace:"canta"});W.coche={x:BANCOS[1][0]+22,y:172,capota:+(o.cap||0),bebe:o.bebe||"duerme"};W.perros={canelo:{x:140,y:204,pose:o.can||"triste",dir:1,correa:o.can==="triste"||!o.can?[BANCOS[1][0]-18,BANCOS[1][1]+10]:null}};
      W.cosas=[{k:"sonajero",x:176,y:186},{k:"oso",x:190,y:192},{k:"bloque",x:164,y:196},{k:"patito",x:182,y:204},{k:"bola",x:120,y:206},{k:"piragua",x:b[2][0]-10,y:204,rot:1.5}];W.noche=1;}},
};
async function stake(lost,max,en){SFX.bonk();await wait(300);}
function poke(what){if(what==="pajaro")pio();}
const estado=W=>"gente="+Object.keys(W.gente||{}).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)).join(" ")+" palomas="+(W.palomas||[]).map(o=>R(o.x)+","+R(o.y)).join(";")+" cosas="+(W.cosas||[]).filter(o=>o.vis!==0).map(o=>o.k).join(",")+" caja="+(W.encaja||[]).join(",")+" marcas="+(W.marcas||[]).join(",");
KIT.escena({id:"banco",CAM:{wide:[22,0,196,216]},heartAt:[110,30],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({gente:{},palomas:[],cosas:[],perros:{},coche:null,bandeja:null,manos:null,encaja:[],noche:0,carro:1,carroX:null,tarjeta:null,marcas:null,cq:{x:LUGAR.centro[0],y:LUGAR.centro[1],s:1,dy:0,al:1,vis:1,bub:null,hace:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
