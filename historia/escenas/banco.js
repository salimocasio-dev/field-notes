"use strict";
/* ============================================================
   Coquí · scene "El banco": the benches in the park (place 2, El parque).
   A paved corner: three wooden benches in a row, facing us; grass and
   trees behind; on the left a cart with an umbrella, where a man sells
   piraguas (shaved ice in paper cones) and water; a lamp post.
   People live in W.gente, by name: {x,y (feet), pose, dir, sent (sitting),
   vis, animo (contento, cansado, triste), dormido, lleva}. Six new
   people (QUIEN below), each drawn so that nobody is taken for another.
   Pigeons in W.palomas: {x,y, en (suelo, banco), pose}. Every story set
   here uses this drawing.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round,P=KIT.PIEL,H=KIT.PELO;
const mkPerro=KIT.mkPerro,tarjeta=KIT.tarjeta,mano=KIT.mano;
const SUELO=132,BANCOS=[[70,150],[122,150],[174,150]],CARRO=[34,176],FAROL=[206,150];   // where the paving starts; the three benches (the middle of the seat); the cart; the lamp post
// the people. extra: what is drawn over the kit's figure so that each one is his own (a beard, a cap, a bun, a shawl...)
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,
  hombre:{piel:P.b,pelo:H.negro,peinado:"corto",ropa:RP.blue,abajo:RP.grey,extra:"barba"},
  mujer:{piel:P.c,pelo:H.negro,peinado:"largo",ropa:RP.yel,falda:1,zapato:"#7A4A10"},
  sviejo:{piel:P.a,pelo:H.blanco,peinado:"corto",ropa:RP.wood,abajo:RP.grey,bigote:1,extra:"baston"},
  sjoven:{piel:P.b,pelo:H.castano,peinado:"corto",ropa:RP.cream.slice(1),abajo:RP.blue,extra:"gorra",zapato:"#F2F2F8"},
  svieja:{piel:P.c,pelo:H.blanco,peinado:"corto",ropa:["#5A3A8A","#7A56B0","#A07ED0","#C4A8E8"],falda:1,extra:"mono"},
  sjovena:{piel:P.a,pelo:H.castano,peinado:"corto",ropa:RP.grn,falda:1,extra:"cola",zapato:"#F2F2F8"},
  piraguero:{piel:P.a,pelo:H.negro,peinado:"calvo",ropa:["#C8C8D4","#E8E8F0","#FFFFFF","#FFFFFF"],abajo:RP.wood,bigote:1,extra:"delantal"}};

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),G=RP.grn,Wd=RP.wood,St=RP.stone;
  sky(b,SW,96);grass(b,92,SW,SUELO+1);
  // trees behind the benches
  [[52,96],[148,92],[226,98]].forEach((p,i)=>{b.rect(p[0]-3,p[1],6,34,Wd[1]);b.rect(p[0]-3,p[1],2,34,Wd[3]);b.ell(p[0],p[1]-12,24,20,[OUT]);b.ell(p[0],p[1]-12,23,19,G);b.ell(p[0]-8,p[1]-18,9,6,[G[3],G[4]]);});
  // the paving: big pale flags
  for(let y=SUELO;y<SH;y++)for(let x=0;x<SW;x++){const fy=Math.floor((y-SUELO)/14),fx=Math.floor((x+(fy%2)*12)/24),ed=((y-SUELO)%14===0)||((x+(fy%2)*12)%24===0);b.px(x,y,ed?"#B8AE98":hs(fx*7+3,fy*5+1)<60?"#E2DAC6":hs(x>>1,y>>1)<6?"#CEC6B0":"#D8D0BA");}
  for(let x=0;x<SW;x++){b.px(x,SUELO,"#8A8270");b.px(x,SUELO-1,G[0]);}
  // the benches: a back, a seat, legs
  BANCOS.forEach(q=>{const x=q[0]-22,y=q[1];b.rect(x+2,y-22,2,34,Wd[0]);b.rect(x+40,y-22,2,34,Wd[0]);[y-22,y-16,y-10].forEach(yy=>{b.rect(x,yy,44,4,Wd[2]);b.rect(x,yy,44,1,Wd[4]);b.rect(x,yy+3,44,1,Wd[1]);});b.rect(x-1,y-3,46,5,Wd[3]);b.rect(x-1,y-3,46,1,Wd[4]);b.rect(x-1,y+1,46,1,Wd[1]);b.frame(x-2,y-4,48,7,OUT);b.frame(x-1,y-23,46,17,OUT);b.rect(x+3,y+3,3,9,Wd[0]);b.rect(x+38,y+3,3,9,Wd[0]);});
  // the lamp post
  b.rect(FAROL[0]-1,FAROL[1]-58,3,62,"#3A3A46");b.rect(FAROL[0]-4,FAROL[1]+3,9,3,"#3A3A46");b.rect(FAROL[0]-5,FAROL[1]-68,11,11,"#FFE98C");b.frame(FAROL[0]-6,FAROL[1]-69,13,13,"#3A3A46");b.rect(FAROL[0]-4,FAROL[1]-71,9,2,"#3A3A46");
  return b.done();}
// the piragua cart: a box on two wheels, a block of ice, bottles of syrup, an umbrella
function mkCarro(){const b=new Buf(58,74),Wd=RP.wood;b.rect(27,14,2,34,"#6E6E80");
  for(let i=0;i<5;i++){const c=i%2?"#F2F2F8":"#E0483A";b.rect(4+i*10,6+Math.abs(2-i)*2,10,7-Math.abs(2-i),c);}b.rect(3,12,52,2,"#B8302A");b.ell(28,5,5,3,["#E0483A"]);
  b.rect(6,46,46,18,"#3A9AD0");b.rect(6,46,46,3,"#7AC4EC");b.rect(6,61,46,3,"#1E6A9A");b.frame(5,45,48,20,OUT);b.rect(12,51,34,7,"#F2F2F8");[[16,52,"#E0483A"],[24,52,"#F0C020"],[32,52,"#3E9A52"],[40,52,"#7A56B0"]].forEach(k=>b.rect(k[0],k[1],3,5,k[2]));
  b.rect(10,36,16,10,"#DCEEFF");b.rect(10,36,16,2,"#FFFFFF");b.frame(9,35,18,12,"#7AA8C8");[[32,38,"#E0483A"],[37,38,"#F0C020"],[42,38,"#3E9A52"]].forEach(k=>{b.rect(k[0],k[1],4,8,k[2]);b.rect(k[0]+1,k[1]-3,2,3,"#C8C8D4");});
  [14,44].forEach(x=>{b.ell(x,68,6,6,[OUT]);b.ell(x,68,5,5,["#5A5A6A","#8A8A9A"]);b.ell(x,68,1.5,1.5,["#C8C8D4"]);});return b.done();}
function mkPiragua(c){const b=new Buf(9,13),C={rojo:"#E0483A",amarillo:"#F0C020",azul:"#3A9AD0"}[c||"rojo"];b.ell(4.5,4,3.6,3.4,[C,"#FFFFFF","#FFFFFF"]);b.rect(2,2,2,2,C);for(let y=0;y<6;y++)b.rect(2+Math.floor(y*.42),7+y,5-Math.floor(y*.84),1,"#F4E2B4");b.px(4,12,"#D8BC8A");return b.outline().done();}
function mkBotella(){const b=new Buf(7,13);b.rect(1,4,5,8,"#9CD8F0");b.rect(1,4,2,8,"#DCF2FA");b.rect(2,1,3,3,"#9CD8F0");b.rect(2,0,3,2,"#2A5CC8");b.rect(1,7,5,2,"#FFFFFF");return b.outline().done();}
function mkPaloma(pose,f){const b=new Buf(14,12),C=["#5A5A6A","#8A8A9A","#B8B8C8"];b.ell(6,7,4.6,3.2,C);b.ell(10,4,2.4,2.4,C);b.px(11,3,OUT);b.rect(12,4,2,1,"#E88A2A");b.cap(2,7,0,5,1.2,[C[0]]);b.rect(8,5,2,2,"#3E9A52");
  if(pose==="come"&&f){b.ell(10,7,2.4,2.4,C);b.rect(12,8,2,1,"#E88A2A");}b.rect(5,10,1,2,"#E0483A");b.rect(8,10,1,2,"#E0483A");return b.outline().done();}

const LUGAR={inicio:[18,150,1],centro:[100,176,1]};
const alto=id=>{const w=QUIEN[id]||{},p=W.gente[id];return w.nino?(p&&p.sent?40:44):(p&&p.sent?49:56);};
const caja=id=>{const p=W.gente[id];return p&&p.vis!==0?[R(p.x)-11,R(p.y)-alto(id),22,alto(id)]:null;};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const COSAS=Object.keys(QUIEN).map(persona).concat([
  {id:"perro",si:w=>!!w.perro&&w.perro.vis!==0,box:w=>[R(w.perro.x)-14,R(w.perro.y)-20,28,22],m:2},
  {id:"carro",box:[CARRO[0]-28,CARRO[1]-72,56,74],m:0},{id:"farol",box:[FAROL[0]-7,FAROL[1]-70,14,76],m:0},
  {id:"banco0",box:[BANCOS[0][0]-23,BANCOS[0][1]-23,46,36],m:0},{id:"banco1",box:[BANCOS[1][0]-23,BANCOS[1][1]-23,46,36],m:0},{id:"banco2",box:[BANCOS[2][0]-23,BANCOS[2][1]-23,46,36],m:0},
  {id:"parque",box:[0,92,240,124],m:0}]);

/* ---------- drawing ---------- */
// what makes each of the new people his own, drawn over the kit's figure. hx,hy: the middle of the face
function extra(c,k,hx,hy,d,p,im){
  if(k==="barba"){fr(c,hx-5,hy+2,10,4,"#24160E");fr(c,hx-2,hy+3,4,1,"#7A2A1A");fr(c,hx-6,hy-1,1,4,"#24160E");fr(c,hx+5,hy-1,1,4,"#24160E");}
  else if(k==="gorra"){fr(c,hx-7,hy-8,14,5,OUT);fr(c,hx-6,hy-7,12,3,"#D0302A");fr(c,hx+d*5-(d<0?5:0),hy-4,6,2,OUT);fr(c,hx+d*5-(d<0?4:0),hy-4,5,1,"#D0302A");}
  else if(k==="mono"){fr(c,hx-4,hy-12,8,6,OUT);fr(c,hx-3,hy-11,6,4,"#C8C8D4");fr(c,hx-9,hy+7,18,5,"#7A56B0");fr(c,hx-9,hy+7,18,1,"#A07ED0");fr(c,hx-2,hy+9,4,5,"#5A3A8A");}                           // a grey bun; a shawl over her shoulders
  else if(k==="cola"){fr(c,hx-d*8-(d<0?0:3),hy-5,4,11,OUT);fr(c,hx-d*8-(d<0?-1:2),hy-4,2,9,"#44260E");fr(c,hx-d*6-(d<0?0:2),hy-6,3,3,"#F0C020");}                                                // a ponytail with a yellow band
  else if(k==="baston"&&!p.sinbaston){const bx=hx+d*12;fr(c,bx-1,hy+12,3,im.height-24,OUT);fr(c,bx,hy+13,1,im.height-26,"#8A5A2A");fr(c,bx-3,hy+11,6,3,OUT);fr(c,bx-2,hy+12,4,1,"#8A5A2A");}        // his cane
  else if(k==="delantal"){fr(c,hx-6,hy+12,12,14,"#F2F2F8");fr(c,hx-6,hy+12,12,1,"#C8C8D4");}}
// how somebody feels, drawn on the face: a tear and a turned-down mouth; a yawn and heavy eyes
function animo(c,k,hx,hy){if(k==="triste"){fr(c,hx-3,hy+3,6,2,"#C89A70");fr(c,hx-2,hy+4,4,1,"#7A2A1A");fr(c,hx-3,hy+5,1,1,"#7A2A1A");fr(c,hx+2,hy+5,1,1,"#7A2A1A");fr(c,hx-4,hy+1,1,3+((F>>3)%2),"#5A9AEA");}
  else if(k==="cansado"){fr(c,hx-4,hy-1,3,1,"#20140A");fr(c,hx+1,hy-1,3,1,"#20140A");fr(c,hx-2,hy+3,4,(F>>3)%3?3:2,"#7A1C1C");fr(c,hx+6,hy-6+((F>>3)%2),1,2,"#A8CCF8");}}
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=Object.assign({},QUIEN[id],p.dormido?{dormido:1}:{}),x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="arriba"?"wave0":(p.pose||"idle"),im=spr("pb"+id+pose+habla+(p.sent?1:0)+(p.dormido?1:0),()=>KIT.mkPersona(w,pose,habla,p.sent)),top=y-im.height+1+((p.paso&&a%2)?-1:0)-(p.dy||0);
  c.save();c.translate(x,top);if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  if(w.extra)extra(c,w.extra,x,top+11,d,p,im);if(p.animo)animo(c,p.animo,x,top+11);
  if(p.dormido){const t=(F>>3)%3;fr(c,x+8,top-2-t*3,3,1,"#FFFFFF");fr(c,x+9,top-1-t*3,1,1,"#FFFFFF");fr(c,x+8,top-t*3,3,1,"#FFFFFF");}   // z z z
  if(p.lleva==="piragua")c.drawImage(spr("pir",()=>mkPiragua("rojo")),x+d*9-4,top+22);else if(p.lleva==="agua")c.drawImage(spr("bot",mkBotella),x+d*9-3,top+22);}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui")&&a%2?1:0,dy=R(q.dy);
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.lleva==="piragua")g.drawImage(spr("pir",()=>mkPiragua("rojo")),b.x+(b.w>>1)-4,b.y+dy-10);else if(W.lleva==="agua")g.drawImage(spr("bot",mkBotella),b.x+(b.w>>1)-3,b.y+dy-10);}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{};
  c.drawImage(spr("banco",fondo),0,0);
  const L=[];
  L.push({y:CARRO[1],d:()=>c.drawImage(spr("carro",mkCarro),CARRO[0]-29,CARRO[1]-72)});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.sent?p.y-8:p.y,d:()=>gente(c,id,a)});});
  (W.palomas||[]).forEach((o,i)=>{if(o.vis!==0)L.push({y:o.y+(o.en==="banco"?-30:0),d:()=>{const f=(a>>1)%2,im=spr("pal"+(o.pose||"")+f,()=>mkPaloma(o.pose,f));c.save();c.translate(R(o.x),R(o.y));if(o.dir<0)c.scale(-1,1);c.drawImage(im,-7,-11);c.restore();}});});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.y+1,d:()=>{const im=o.k==="agua"?spr("bot",mkBotella):spr("pir"+(o.c||""),()=>mkPiragua(o.c));c.drawImage(im,R(o.x)-(im.width>>1),R(o.y)-im.height);}});});
  if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>{const o=W.perro,f=o.pose==="bark"||o.pose==="walk"?(a>>1)%2:0,im=spr("pe"+o.pose+f,()=>mkPerro(o.pose,f));c.save();c.translate(R(o.x),R(o.y)-im.height+2);if(o.dir<0)c.scale(-1,1);c.drawImage(im,-13,0);c.restore();}});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.bub?38:0)];}
function respIcon(g,k,x,y,w,h,a){}
function hud(g,W,a){}
const acts={
  // everybody at once, to look at the drawing
  async prueba(){const b=BANCOS;W.gente={piraguero:{x:CARRO[0]+6,y:CARRO[1]-6,pose:"idle",dir:1},luis:{x:74,y:204,pose:"idle",dir:1,animo:"cansado"},carmen:{x:100,y:206,pose:"idle",dir:1},
      hombre:{x:b[0][0]-9,y:b[0][1]+11,pose:"idle",dir:1,sent:1,lleva:"piragua"},mujer:{x:b[0][0]+11,y:b[0][1]+11,pose:"idle",dir:1,sent:1,lleva:"agua"},
      sviejo:{x:b[1][0]-10,y:b[1][1]+11,pose:"idle",dir:1,sent:1},sjoven:{x:b[1][0]+11,y:b[1][1]+11,pose:"idle",dir:1,sent:1,animo:"triste"},
      svieja:{x:b[2][0]-10,y:b[2][1]+11,pose:"idle",dir:1,sent:1,dormido:1},sjovena:{x:b[2][0]+11,y:b[2][1]+11,pose:"idle",dir:1,sent:1}};
    Object.assign(W.cq,{x:126,y:176,s:1});W.lleva="piragua";W.palomas=[{x:150,y:200,dir:1},{x:176,y:206,dir:-1,pose:"come"},{x:BANCOS[1][0],y:BANCOS[1][1]-22,en:"banco",dir:1}];W.cosas=[{k:"piragua",c:"amarillo",x:196,y:204},{k:"agua",x:206,y:206}];W.perro={x:190,y:188,pose:"sit",dir:-1};},
};
async function stake(lost,max,en){SFX.bonk();await wait(300);}
function poke(what){}
const estado=W=>"gente="+Object.keys(W.gente||{}).join(",");
KIT.escena({id:"banco",CAM:{wide:[22,0,196,216]},heartAt:[110,30],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({gente:{},palomas:[],cosas:[],perro:null,lleva:null,tarjeta:null,marcas:null,cq:{x:LUGAR.centro[0],y:LUGAR.centro[1],s:1,dy:0,al:1,vis:1,bub:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
