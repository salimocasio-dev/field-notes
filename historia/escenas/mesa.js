"use strict";
/* ============================================================
   Coquí · scene "La mesa": abuela's kitchen (place 3, La cocina).
   On the left a counter with a cupboard over it; in the middle the
   table, seen a little from above, with four chairs behind it; on the
   right the stove, and a window over it. The floor in front of the
   table is where the frog walks.
   People live in W.gente, by name: {x,y (feet), pose, dir, sent, vis,
   hace (come, bebe), que, lleva, animo}. A place at the table is
   W.puestos[i]: a list of the things that stand there, left to right:
   {k (plato, hondo, taza, vaso, cuchara, tenedor, cuchillo), con (what
   is in it: bizcocho, choco, arroz, sopa, agua), tapa}. What stands on
   the counter is W.mostrador, on the stove W.estufa. Stains on the
   cloth are W.manchas. Every story set here uses this drawing.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round,tarjeta=KIT.tarjeta,mkPerro=KIT.mkPerro;
const PISO=150,MESA=[92,130,96,30],SILLA=[104,128,152,176],MOSTR=[24,118,62,12],ESTUFA=[190,116,30,46],PUERTA=[22,70,0,0];   // where the floor starts; the table top (x, y of its far edge, width, depth); the four chairs; the counter top; the stove
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,abuelo:FAM.abuelo,mama:FAM.mama,papa:FAM.papa,abuela:{},bebe:{}};
const EN={platos:[36,MOSTR[1]+1],tazas:[56,MOSTR[1]],bandeja:[76,MOSTR[1]+1],comidas:[40,MOSTR[1]+1],vasos:[68,MOSTR[1]]};   // where each kind of thing stands on the counter

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),Wd=RP.wood;
  // the wall: pale yellow, a tiled strip behind the counter and the stove
  for(let y=0;y<PISO;y++)for(let x=0;x<SW;x++)b.px(x,y,y>132?"#C8B88A":hs(x>>2,y>>2)<6?"#F0E4B8":"#F6ECC4");
  for(let y=96;y<118;y++)for(let x=22;x<90;x++)b.px(x,y,(x%8===0||y%8===0)?"#B8D0D8":"#E4F0F4");
  for(let y=92;y<116;y++)for(let x=186;x<SW;x++)b.px(x,y,(x%8===2||y%8===4)?"#B8D0D8":"#E4F0F4");
  // the floor: red and cream tiles
  for(let y=PISO;y<SH;y++)for(let x=0;x<SW;x++){const ty=Math.floor((y-PISO)/11),tx=Math.floor((x+ty*6)/16);b.px(x,y,((y-PISO)%11===0||(x+ty*6)%16===0)?"#8A5A44":(tx+ty)%2?"#C8745A":"#E8D8B8");}
  for(let x=0;x<SW;x++)b.px(x,PISO-1,"#7A6A4A");
  // the window over the stove: sky, a tree, a frame
  b.rect(176,34,40,40,"#9CCBF5");b.ell(206,62,12,10,RP.grn);b.rect(176,34,40,3,"#DCEEFF");b.frame(174,32,44,44,Wd[1]);b.frame(175,33,42,42,Wd[3]);b.rect(195,34,2,40,Wd[2]);b.rect(176,53,40,2,Wd[2]);
  // the cupboard over the counter: two doors
  b.rect(26,36,58,44,Wd[2]);b.rect(26,36,58,2,Wd[4]);b.rect(26,78,58,2,Wd[0]);b.frame(25,35,60,46,OUT);b.rect(54,38,2,40,Wd[0]);[42,66].forEach(x=>b.rect(x,56,2,6,"#F0C020"));b.frame(29,40,24,36,Wd[1]);b.frame(57,40,24,36,Wd[1]);
  // the counter: a top, a cabinet with two doors under it
  b.rect(MOSTR[0],MOSTR[1]+MOSTR[3],MOSTR[2],PISO+8-MOSTR[1]-MOSTR[3],Wd[2]);b.rect(MOSTR[0],MOSTR[1]+MOSTR[3],MOSTR[2],2,Wd[0]);b.frame(MOSTR[0]-1,MOSTR[1]+MOSTR[3]-1,MOSTR[2]+2,PISO+10-MOSTR[1]-MOSTR[3],OUT);
  b.rect(54,MOSTR[1]+MOSTR[3]+3,2,22,Wd[0]);[46,62].forEach(x=>b.rect(x,MOSTR[1]+MOSTR[3]+10,2,5,"#F0C020"));
  b.rect(MOSTR[0]-2,MOSTR[1],MOSTR[2]+4,MOSTR[3],"#E8E8F0");b.rect(MOSTR[0]-2,MOSTR[1],MOSTR[2]+4,2,"#FFFFFF");b.rect(MOSTR[0]-2,MOSTR[1]+MOSTR[3]-2,MOSTR[2]+4,2,"#B8B8C8");b.frame(MOSTR[0]-3,MOSTR[1]-1,MOSTR[2]+6,MOSTR[3]+2,OUT);
  // the stove: white, four burners seen from the front edge, an oven door
  const E=ESTUFA;b.rect(E[0],E[1],E[2],E[3],"#F2F2F8");b.rect(E[0],E[1],E[2],4,"#3A3A46");b.rect(E[0],E[1]+4,E[2],2,"#C8C8D4");b.frame(E[0]-1,E[1]-1,E[2]+2,E[3]+2,OUT);
  b.rect(E[0]+4,E[1]+14,E[2]-8,20,"#3A3A46");b.rect(E[0]+6,E[1]+16,E[2]-12,16,"#5A5A6A");b.rect(E[0]+5,E[1]+11,E[2]-10,2,"#9494A6");[E[0]+6,E[0]+14,E[0]+22].forEach(x=>b.rect(x,E[1]+7,3,3,"#D0302A"));
  // the four chairs: backs showing over the far edge of the table
  SILLA.forEach(x=>{b.rect(x-9,MESA[1]-26,2,30,Wd[0]);b.rect(x+7,MESA[1]-26,2,30,Wd[0]);[MESA[1]-26,MESA[1]-18].forEach(y=>{b.rect(x-9,y,18,4,Wd[2]);b.rect(x-9,y,18,1,Wd[4]);});b.frame(x-10,MESA[1]-27,20,10,OUT);});
  return b.done();}
// the table: drawn over the people who sit behind it. mantel: a white cloth
function mkMesa(mantel){const b=new Buf(MESA[2]+12,64),Wd=RP.wood,w=MESA[2],d=MESA[3];
  for(let y=0;y<d;y++){const x0=R(6-y*6/d),ww=w+R(y*12/d);b.rect(x0,y,ww,1,mantel?(hs(y,3)<50?"#FBFBFF":"#F2F2F8"):y<2?Wd[4]:Wd[3]);}
  b.rect(0,d,w+12,5,mantel?"#D8D8E4":Wd[1]);if(mantel)for(let x=2;x<w+10;x+=6)b.rect(x,d+5,3,2,"#D8D8E4");
  [[3,d+5],[w+6,d+5]].forEach(p=>{b.rect(p[0],p[1],4,26,Wd[1]);b.rect(p[0],p[1],1,26,Wd[3]);});[[14,d+5],[w-6,d+5]].forEach(p=>b.rect(p[0],p[1],3,18,Wd[0]));
  return b.outline().done();}
// things on the table, on the counter, in a hand. Each is drawn with its foot at the bottom middle
const COSA={
  plato(){const b=new Buf(15,7);b.ell(7.5,3.5,6.6,2.8,["#C8C8D4","#F2F2F8","#FFFFFF"]);b.ell(7.5,3.2,4,1.5,["#E4E4EE"]);return b.outline().done();},
  hondo(){const b=new Buf(15,8);b.ell(7.5,4,6.6,3.2,["#C8C8D4","#F2F2F8","#FFFFFF"]);b.ell(7.5,3.4,4.6,1.8,["#D8B040","#F0D060"]);return b.outline().done();},
  taza(){const b=new Buf(11,9);b.rect(1,2,6,6,"#F2F2F8");b.rect(1,2,2,6,"#FFFFFF");b.rect(1,7,6,1,"#C8C8D4");b.rect(7,3,2,1,"#F2F2F8");b.rect(9,4,1,2,"#F2F2F8");b.rect(7,6,2,1,"#F2F2F8");b.rect(2,2,4,1,"#D0D0DC");return b.outline().done();},
  vaso(){const b=new Buf(8,11);b.rect(1,1,6,9,"#DCF2FA");b.rect(1,4,6,6,"#9CD8F0");b.rect(1,1,2,9,"#F2FBFF");return b.outline().done();},
  vacio(){const b=new Buf(8,11);b.rect(1,1,6,9,"#EAF6FA");b.rect(1,1,2,9,"#F8FDFF");return b.outline().done();},
  cuchara(){const b=new Buf(7,15);b.ell(3.5,3.5,2.4,3,["#9494A6","#C8C8D4","#F2F2F8"]);b.rect(3,6,1,8,"#C8C8D4");return b.outline().done();},
  tenedor(){const b=new Buf(7,15);[1,3,5].forEach(x=>b.rect(x,1,1,5,"#C8C8D4"));b.rect(1,5,5,2,"#C8C8D4");b.rect(3,7,1,7,"#C8C8D4");return b.outline().done();},
  cuchillo(){const b=new Buf(7,15);b.rect(2,1,3,8,"#E4E4EE");b.rect(2,1,1,8,"#FFFFFF");b.px(4,1,null);b.rect(2,9,3,5,"#5A3A1A");return b.outline().done();},
  bizcocho(){const b=new Buf(11,8);b.rect(1,3,9,4,"#E8B050");b.rect(1,3,9,1,"#F8DC90");b.rect(1,1,9,2,"#FFF4E0");b.px(5,0,"#D0302A");return b.outline().done();},
  entero(){const b=new Buf(24,13);b.ell(12,8,10.6,4,["#C88A30","#E8B050","#F8DC90"]);b.ell(12,5.5,10.6,3.6,["#F2E4D0","#FFF4E0","#FFFFFF"]);[6,12,18].forEach(x=>b.px(x,4,"#D0302A"));return b.outline().done();},
  olla(){const b=new Buf(24,16);b.rect(3,5,18,10,"#8A8A9A");b.rect(3,5,4,10,"#B8B8C8");b.rect(3,13,18,2,"#5A5A6A");b.rect(1,6,2,3,"#3A3A46");b.rect(21,6,2,3,"#3A3A46");b.rect(2,3,20,2,"#5A5A6A");b.rect(10,1,4,2,"#3A3A46");return b.outline().done();},
  jarra(){const b=new Buf(16,14);b.rect(3,3,9,10,"#A8482A");b.rect(3,3,3,10,"#D0704A");b.rect(2,2,11,2,"#7A2E18");b.rect(12,5,3,1,"#7A2E18");b.rect(14,6,1,4,"#7A2E18");b.rect(12,10,3,1,"#7A2E18");b.rect(0,3,3,2,"#A8482A");return b.outline().done();},
  pan(){const b=new Buf(20,10);b.ell(10,5.5,8.6,3.6,["#A8682C","#C8853C","#E2A85A"]);[6,10,14].forEach(x=>b.rect(x,3,1,3,"#F4CC88"));return b.outline().done();},
  tapa(){const b=new Buf(17,11);b.ell(8.5,9,7.6,7,["#9494A6","#C8C8D4","#F2F2F8"]);b.rect(0,9,17,2,null);b.rect(1,8,15,2,"#9494A6");b.rect(7,0,3,2,"#5A5A6A");return b.outline().done();},
  arroz(){const b=new Buf(11,6);b.ell(4,3.5,3.4,2.2,["#F2F2F8","#FFFFFF"]);b.ell(8,3.5,2.4,2,["#8A4A1E","#B8682C"]);return b.outline().done();},
  hueso(){const b=new Buf(13,7);b.rect(3,2,7,3,"#F8F4E8");[[2,1],[2,5],[10,1],[10,5]].forEach(p=>b.ell(p[0],p[1],1.6,1.6,["#F8F4E8"]));return b.outline().done();}};
const cosa=k=>spr("ms"+k,COSA[k]||COSA.plato);
const ANCHO={plato:15,hondo:15,taza:10,vaso:8,cuchara:6,tenedor:6,cuchillo:6};

const LUGAR={inicio:[18,150,1],centro:[120,182,1]};
const alto=id=>{const w=QUIEN[id]||{},p=W.gente[id];return id==="abuela"?51:id==="bebe"?28:w.nino?(p&&p.sent?40:44):(p&&p.sent?49:56);};
const caja=id=>{const p=W.gente[id];if(!p||p.vis===0)return null;const h=alto(id);return p.sent?[R(p.x)-11,R(p.y)-h,22,h-18]:[R(p.x)-11,R(p.y)-h,22,h];};   // somebody who sits behind the table is touched above its edge
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const enMostr=k=>({id:k,m:2,si:w=>!!(w.mostrador&&w.mostrador[k]),box:()=>[EN[k][0]-11,EN[k][1]-18,22,22]});
const G=id=>W.gente[id];
const COSAS=Object.keys(QUIEN).map(persona).concat(["platos","tazas","bandeja","comidas","vasos"].map(enMostr),[
  {id:"perro",si:w=>!!w.perro&&w.perro.vis!==0,box:w=>[R(w.perro.x)-14,R(w.perro.y)-20,28,22],m:1},
  {id:"mesa",box:[MESA[0]-4,MESA[1],MESA[2]+8,MESA[3]+8],m:0},{id:"estufa",box:[ESTUFA[0],ESTUFA[1]-18,28,64],m:0},
  {id:"cocina",box:[0,30,240,186],m:0}]);

/* ---------- drawing ---------- */
function animo(c,k,hx,hy){const t=(F>>3)%2;
  if(k==="triste"){fr(c,hx-3,hy+3,6,2,"#C89A70");fr(c,hx-2,hy+4,4,1,"#7A2A1A");fr(c,hx-5,hy+1,2,4+t,"#5AB4F4");fr(c,hx+3,hy+1,2,3+(1-t),"#5AB4F4");}
  else if(k==="contento"){fr(c,hx-3,hy+3,6,2,"#7A1C1C");fr(c,hx-2,hy+3,4,1,"#FFFFFF");}}
function tenida(c,k,x,y,girada){const im=cosa(k);if(girada){c.save();c.translate(x,y);c.rotate(girada);c.drawImage(im,-(im.width>>1),-im.height);c.restore();}else c.drawImage(im,R(x)-(im.width>>1),R(y)-im.height);}
// a thing with what is in it: a slice on a plate, chocolate in a cup (or the other way round)
function conTodo(c,o,x,y){tenida(c,o.k,x,y);const k=o.k,con=o.con;if(!con)return;
  if(k==="plato"||k==="hondo"){if(con==="bizcocho")tenida(c,"bizcocho",x,y-2);else if(con==="arroz")tenida(c,"arroz",x,y-2);else if(con==="choco"){fr(c,x-5,y-5,10,3,"#7A3A1A");fr(c,x-3,y-6,6,1,"#7A3A1A");}else if(con==="migas"){fr(c,x-3,y-4,1,1,"#E8B050");fr(c,x+2,y-5,1,1,"#E8B050");}}
  else if(k==="taza"){if(con==="choco")fr(c,x-4,y-8,5,2,"#7A3A1A");else if(con==="bizcocho"){fr(c,x-5,y-12,7,5,OUT);fr(c,x-4,y-11,5,4,"#E8B050");fr(c,x-4,y-11,5,1,"#FFF4E0");}}
  if(o.tapa)tenida(c,"tapa",x,y-1);}
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  if(id==="abuela"){const ps=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle");c.save();c.translate(x,y-50+((p.paso&&a%2)?-1:0));if(d<0)c.scale(-1,1);c.drawImage(spr("ab"+ps+habla,()=>mkAbuela(ps,habla)),-30,0);c.restore();if(p.lleva)conTodo(c,{k:p.lleva,con:p.con},x+d*13,y-16);return;}
  if(id==="bebe"){const e=p.est||"idle",im=spr("bb"+e+(a%2),()=>KIT.mkBebe(e,a%2));c.drawImage(im,x-13,y-28);return;}
  const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="arriba"?"wave0":(p.pose||"idle"),im=spr("pm"+id+pose+habla+(p.sent?1:0),()=>KIT.mkPersona(w,pose,habla,p.sent)),top=y-im.height+1+((p.paso&&a%2)?-1:0)-(p.dy||0);
  c.save();c.translate(x,top);if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  if(p.animo)animo(c,p.animo,x,top+11);
  if(p.hace==="come")tenida(c,p.que||"cuchara",x+d*5,top+26+(a%2));else if(p.hace==="bebe")tenida(c,p.que||"taza",x+d*6,top+22-(a%2));
  else if(p.lleva)conTodo(c,{k:p.lleva,con:p.con},x+d*10,top+(w.nino?34:38));}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui"||q.hace==="come")&&a%2?1:0,dy=R(q.dy),cx=b.x+(b.w>>1);
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.encima)conTodo(g,W.encima,cx,b.y+dy+2);
  if(W.piensa){const x=cx+14,y=b.y+dy-20;fr(g,x-1,y-1,22,18,OUT);fr(g,x,y,20,16,"#FFFFFF");fr(g,x-3,y+15,3,3,OUT);fr(g,x-6,y+19,2,2,OUT);conTodo(g,W.piensa,x+10,y+14);}}   // what he wants: a thought bubble with a picture
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{},M=W.mostrador||{},E=W.estufa||{};
  c.drawImage(spr("cocina",fondo),0,0);
  // on the stove
  if(E.olla){tenida(c,"olla",ESTUFA[0]+13,ESTUFA[1]+1);if(E.vapor){const t=(F>>2)%6;[[9,-18],[14,-22],[18,-17]].forEach((p,i)=>fr(c,ESTUFA[0]+p[0]+((t+i)%3)-1,ESTUFA[1]+p[1]-((t+i*2)%6),2,3,"#FFFFFF"));}}
  if(E.bizcocho)tenida(c,"entero",ESTUFA[0]+12,ESTUFA[1]+1);if(E.jarra)tenida(c,"jarra",ESTUFA[0]+24,ESTUFA[1]+1);
  // on the counter: stacks and rows
  for(let i=0;i<(M.platos||0);i++)tenida(c,"plato",EN.platos[0],EN.platos[1]-i*2);
  for(let i=0;i<(M.tazas||0);i++)tenida(c,"taza",EN.tazas[0]-6+(i%2)*10,EN.tazas[1]-(i>>1)*7);
  if(M.bandeja){const x=EN.bandeja[0],y=EN.bandeja[1];fr(c,x-11,y-5,22,6,OUT);fr(c,x-10,y-4,20,4,"#8A5A2A");["cuchara","tenedor","cuchillo"].forEach((k,i)=>tenida(c,k,x-6+i*6,y-1));}
  for(let i=0;i<(M.comidas||0);i++)conTodo(c,{k:"plato",con:"arroz"},EN.comidas[0]-4+(i%2)*14,EN.comidas[1]-(i>>1)*8);
  for(let i=0;i<(M.vasos||0);i++)tenida(c,"vaso",EN.vasos[0]-4+(i%2)*9,EN.vasos[1]-(i>>1)*4);
  const L=[];
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.z!=null?p.z:p.y,d:()=>gente(c,id,a)});});
  // the table, and what stands on it at each place
  L.push({y:MESA[1]+MESA[3]+6,d:()=>{c.drawImage(spr("mesa"+(W.mantel?1:0),()=>mkMesa(W.mantel)),MESA[0]-6,MESA[1]);
    (W.manchas||[]).forEach(m=>{fr(c,m[0]-4,m[1]-1,8,3,m[2]||"#C89A40");fr(c,m[0]-2,m[1]-2,5,5,m[2]||"#C89A40");});
    (W.puestos||[]).forEach((ps,i)=>{if(!ps)return;const tot=ps.reduce((s,o)=>s+(ANCHO[o.k]||8)-1,0);let x=SILLA[i]-tot/2;ps.forEach(o=>{const w=(ANCHO[o.k]||8)-1;conTodo(c,o,x+w/2,MESA[1]+16+(o.k==="plato"||o.k==="hondo"?2:0));x+=w;});});
    (W.enmesa||[]).forEach(o=>conTodo(c,o,o.x,o.y));}});
  if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>{const o=W.perro,f=o.pose==="bark"||o.pose==="walk"||o.pose==="eat"?(a>>1)%2:0,im=spr("pe"+o.pose+f,()=>mkPerro(o.pose,f));c.save();c.translate(R(o.x),R(o.y)-im.height+2-(o.dy||0));if(o.dir<0)c.scale(-1,1);c.drawImage(im,-13,0);c.restore();}});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>conTodo(c,o,o.x,o.y)});});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.bub?38:0)];}
// picture bubbles: a spoon, a fork, a knife, drawn big
function respIcon(g,k,x,y,w,h,a){if(!COSA[k])return;g.imageSmoothingEnabled=false;g.save();g.translate(x+(w>>1),y+h-3);g.scale(2,2);tenida(g,k,0,0);g.restore();}
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,66,24);
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m){g.fillStyle=OUT;for(let k=0;k<11;k++){g.fillRect(x+k,y+1+k,4,3);g.fillRect(x+10-k,y+1+k,4,3);}g.fillStyle="#C8401E";for(let k=0;k<11;k++){g.fillRect(x+1+k,y+2+k,2,1);g.fillRect(x+11-k,y+2+k,2,1);}}
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}
const marca=m=>{const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;};

/* ---------- moving things ---------- */
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/5));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;}
const cx=()=>W.cq.x+16,pies=()=>W.cq.y+27;
async function ranaA(x,y,h){const q=W.cq,d=Math.hypot(x-16-q.x,y-27-q.y);if(d<3)return;await hopTo(R(x-16),R(y-27),h||Math.max(1,Math.min(4,R(d/34))));}
const acasa=()=>ranaA(W.casa[0],W.casa[1]);

const acts={
  async pose(o){const p=G(o.quien);if(p)p.pose=o.que;},
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async casa(){await acasa();},
  // plain acts
  async g(o){const p=G(o.quien);if(!p)return;Object.keys(o).forEach(k=>{if(!["act","quien","ms"].includes(k))p[k]=o[k];});if(o.ms)await wait(o.ms);},
  async anda(o){const p=G(o.quien),pr=(async()=>{await mueve(o.quien,o.x,o.y);if(o.dir)p.dir=o.dir;if(o.sent){p.sent=1;p.dir=1;}if(o.fuera)p.vis=0;})();if(!o.suelto)await pr;},
  async saluda(o){const p=G(o.quien);if(!p)return;p.pose=o.que||"wave";await wait(o.ms||750);p.pose="idle";},
  async rana(o){await ranaA(o.x,o.y,o.h);},
  async encima(o){W.encima=o.k?{k:o.k,con:o.con}:null;SFX.blip();await wait(200);},
  // everybody at once, to look at the drawing
  async prueba(o){const n=+(o&&o.n||1);W.gente={abuela:{x:196,y:190,dir:-1},luis:{x:74,y:186,dir:1,lleva:"taza"},abuelo:{x:SILLA[0],y:150,dir:1,sent:1},mama:{x:SILLA[1],y:150,dir:1,sent:1},papa:{x:SILLA[2],y:150,dir:1,sent:1,hace:n===2?"come":null,que:"tenedor"},carmen:{x:SILLA[3],y:150,dir:1,sent:1}};
    W.gente.bebe={x:SILLA[1]+2,y:140,z:151};W.mostrador=n===3?{comidas:4,vasos:4}:{platos:4,tazas:4,bandeja:1};W.estufa=n===1?{bizcocho:1,jarra:1}:{olla:1,vapor:1};W.mantel=n===2?1:0;W.perro=n===3?{x:136,y:196,pose:"lie",dir:1}:null;
    W.puestos=n===1?[[{k:"plato",con:"bizcocho"},{k:"taza",con:"choco"}],[{k:"taza",con:"bizcocho"},{k:"taza",con:"choco"}],[{k:"plato",con:"choco"},{k:"plato",con:"bizcocho"}],[{k:"plato"}]]
      :n===2?[[{k:"hondo",con:"sopa"},{k:"cuchara"}],[{k:"plato",con:"arroz"},{k:"tenedor"},{k:"cuchillo"}],[{k:"plato",tapa:1}],[{k:"hondo",con:"sopa"},{k:"cuchara"},{k:"tenedor"},{k:"cuchillo"}]]
      :[[{k:"plato",con:"arroz"}],[{k:"vaso"}],[],[{k:"plato",con:"arroz"},{k:"vaso"}]];
    W.manchas=n===2?[[130,152],[160,148,"#B8682C"]]:[];Object.assign(W.cq,{x:104,y:158,s:1});W.encima=n===1?{k:"plato"}:n===3?{k:"plato",con:"arroz"}:null;W.piensa=n===3?{k:"vaso"}:null;},
};
async function stake(lost,max,en){SFX.bonk();await wait(300);}
function poke(what){}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)+(W.gente[k].lleva?"["+W.gente[k].lleva+"]":"")).join(" ")+" puestos="+(W.puestos||[]).map(p=>(p||[]).map(o=>o.k+(o.con?":"+o.con:"")+(o.tapa?"^":"")).join("+")).join("|")+" mostr="+JSON.stringify(W.mostrador||{})+" manchas="+(W.manchas||[]).length+" encima="+(W.encima?W.encima.k:"")+" marcas="+(W.marcas||[]).join(",");
KIT.escena({id:"mesa",CAM:{wide:[22,0,196,216]},heartAt:[110,22],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({respEn:[120,56],gente:{},puestos:[[],[],[],[]],mostrador:{},estufa:{},manchas:[],mantel:0,cosas:[],enmesa:[],perro:null,encima:null,piensa:null,tarjeta:null,marcas:null,cq:{x:LUGAR.centro[0],y:LUGAR.centro[1],s:1,dy:0,al:1,vis:1,bub:null,hace:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
