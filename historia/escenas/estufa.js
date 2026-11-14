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
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,abuelo:FAM.abuelo,mama:FAM.mama,papa:FAM.papa,abuela:{}};
const LADO=[[82,174],[171,176]],AYUDA=[42,176],PUERTA=[200,180];   // where a cook stands at the left and at the right of the stove; the helper at the left counter; whoever comes in for something
const EN={saco:[37,ENC+9],tazon:[63,ENC+9],platos:[184,ENC+9],basura:[207,ENC+10],jarra:[36,ENC+9],tazas:[60,ENC+9],fuente:[190,ENC+9],apartes:[196,ENC+9]};

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),Wd=RP.wood,E=EST;
  for(let y=0;y<PISO;y++)for(let x=0;x<SW;x++)b.px(x,y,y>PISO-5?"#C8B88A":hs(x>>2,y>>2)<6?"#F0E4B8":"#F6ECC4");
  for(let y=72;y<ENC;y++)for(let x=22;x<SW;x++)b.px(x,y,(x%8===0||y%8===0)?"#B8D0D8":"#E4F0F4");
  for(let y=PISO;y<SH;y++)for(let x=0;x<SW;x++){const ty=Math.floor((y-PISO)/12),tx=Math.floor((x+ty*6)/16);b.px(x,y,((y-PISO)%12===0||(x+ty*6)%16===0)?"#9A6A54":(tx+ty)%2?"#C8745A":"#E8D8B8");}
  for(let x=0;x<SW;x++)b.px(x,PISO-1,"#7A6A4A");
  // a window, a shelf with jars
  b.rect(176,22,38,36,"#9CCBF5");b.ell(204,48,10,9,RP.grn);b.frame(174,20,42,40,Wd[1]);b.frame(175,21,40,38,Wd[3]);b.rect(194,22,2,36,Wd[2]);b.rect(176,39,38,2,Wd[2]);
  b.rect(26,50,50,3,Wd[2]);b.rect(26,53,50,1,Wd[0]);[[32,"#D0302A"],[44,"#F0C020"],[56,"#48A848"],[67,"#58B4EC"]].forEach(j=>{b.rect(j[0],40,7,10,j[1]);b.rect(j[0],38,7,2,"#F2F2F8");b.frame(j[0]-1,37,9,14,OUT);});
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
  saco(){const b=new Buf(20,22);b.rect(2,5,16,16,"#D8C8A0");b.rect(2,5,4,16,"#EADCB8");b.rect(2,18,16,3,"#B8A478");b.ell(10,5,7,2.6,["#DCDCE8","#FFFFFF"]);[[6,11],[10,13],[13,10],[8,15],[12,16]].forEach(q=>b.rect(q[0],q[1],2,1,"#FFFFFF"));return b.outline().done();},
  tazon(){const b=new Buf(22,13);b.ell(11,9,8,3.4,["#3A70B0","#5A90D0"]);b.ell(11,5,9.6,4,["#3A70B0","#5A90D0","#8CB8E8"]);b.ell(11,4.6,7.6,2.8,["#7A2416","#B84A2E"]);[[6,4],[10,5],[14,4],[9,3],[13,6]].forEach(q=>b.rect(q[0],q[1],2,1,"#4A1408"));return b.outline().done();},
  medida(c){const b=new Buf(11,10);b.rect(1,3,7,6,"#F0C020");b.rect(1,3,2,6,"#FFE070");b.rect(8,4,2,1,"#F0C020");b.rect(9,5,1,3,"#F0C020");b.rect(2,2,5,2,c==="hab"?"#B84A2E":c==="arroz"?"#FFFFFF":"#C8A018");return b.outline().done();},
  basura(){const b=new Buf(24,13);b.ell(12,9,9,3.4,["#6A6A7A","#9494A6"]);b.ell(12,5,10.6,4,["#6A6A7A","#9494A6","#C8C8D4"]);b.ell(12,4.8,8.6,2.8,["#3A3A46"]);return b.outline().done();},
  monton(c){const b=new Buf(11,7),C=c==="hab"?["#7A2416","#B84A2E"]:c==="negro"?["#141418","#3A3028"]:["#DCDCE8","#FFFFFF"];b.ell(5.5,4,4.4,2.4,C);b.px(3,3,C[0]);b.px(7,5,C[0]);return b.outline().done();},
  plato(){const b=new Buf(15,7);b.ell(7.5,3.5,6.6,2.8,["#B8B8C8","#F2F2F8","#FFFFFF"]);b.ell(7.5,3.2,4,1.5,["#DCDCE8"]);return b.outline().done();},
  espumadera(){const b=new Buf(18,8);b.ell(5,4,4,2.6,["#9494A6","#C8C8D4"]);b.px(4,4,"#5A5A6A");b.px(6,3,"#5A5A6A");b.rect(8,3,9,2,"#6A3E1A");return b.outline().done();},
  cucharon(){const b=new Buf(6,18);b.rect(2,1,2,12,"#B07A3C");b.ell(3,14,2.6,3,["#8A5A2A","#B07A3C"]);return b.outline().done();},
  jarra(){const b=new Buf(20,22);b.rect(3,3,12,18,"#E4F4FA");b.rect(3,8,12,13,"#7A3A1A");b.rect(3,3,3,18,"#F8FDFF");[[6,9],[10,8],[12,11]].forEach(q=>{b.rect(q[0],q[1],3,3,"#DCF2FA");b.px(q[0],q[1],"#FFFFFF");});b.rect(15,6,2,1,"#B8D8E8");b.rect(17,7,1,7,"#B8D8E8");b.rect(15,14,2,1,"#B8D8E8");b.rect(1,3,2,2,"#E4F4FA");return b.outline().done();},
  taza(c){const b=new Buf(12,12);b.rect(1,4,7,7,"#F2F2F8");b.rect(1,4,2,7,"#FFFFFF");b.rect(1,10,7,1,"#C8C8D4");b.rect(8,5,2,1,"#F2F2F8");b.rect(10,6,1,3,"#F2F2F8");b.rect(8,9,2,1,"#F2F2F8");b.rect(2,4,5,2,c?"#6A3214":"#C8C8D4");
    if(c==="frio"){b.rect(3,3,2,2,"#DCF2FA");b.rect(5,4,2,2,"#FFFFFF");b.rect(6,0,1,5,"#E0403A");}return b.outline().done();},
  banco(){const b=new Buf(26,20);b.rect(2,1,22,4,RP.wood[3]);b.rect(2,1,22,1,RP.wood[4]);b.rect(4,5,3,14,RP.wood[1]);b.rect(19,5,3,14,RP.wood[1]);b.rect(5,11,16,2,RP.wood[1]);return b.outline().done();}};
const cosa=(k,c)=>spr("es"+k+(c==null?"":c),()=>(COSA[k]||COSA.plato)(c));
function tenida(c,k,x,y,ang,esc,v){const im=cosa(k,v);if(ang||esc){c.save();c.translate(R(x),R(y));if(ang)c.rotate(ang);if(esc)c.scale(esc,esc);c.drawImage(im,-(im.width>>1),-im.height);c.restore();}else c.drawImage(im,R(x)-(im.width>>1),R(y)-im.height);}
// a flame under a pot, steam over it, smoke from a burnt one
function llama(c,x,a){const t=(F>>2)%2;[[-8,2],[-3,3],[2,2],[7,3]].forEach((q,i)=>{fr(c,x+q[0],FY-1-q[1]-((i+t)%2),3,q[1]+2,"#F08020");fr(c,x+q[0]+1,FY-q[1],1,q[1],"#58B4EC");});}
function vapor(c,x,y,negro){const t=(F>>2)%6;[[-7,0],[0,-4],[6,-1]].forEach((p,i)=>{const yy=y+p[1]-((t+i*2)%6)*(negro?2:1);fr(c,x+p[0]+((t+i)%3)-1,yy,negro?3:2,negro?4:3,negro?"#3A3A46":"#FFFFFF");});}
function fuego(c,i,a){const f=W.fuegos[i];if(!f||!f.k)return;const x=FX[i];
  if(f.llama)llama(c,x,a);
  if(f.k==="olla"){tenida(c,"olla",x,FY+1,0,0,f.negra&&!f.n?"negra":f.n?f.con:(f.con==="agua"||f.con==="choco"?f.con:"vacia"));if(f.negra)c.drawImage(cosa("quemada"),x-17,FY-23);
    if(f.humo)vapor(c,x,FY-26,1);else if(f.vapor)vapor(c,x,FY-22,0);}
  else{tenida(c,"sarten",x+6,FY+1);(f.cosas||[]).forEach((o,j)=>tenida(c,o.k,x-6+j*11,FY-4,0,0,o.v));if(f.humo)vapor(c,x,FY-14,1);}}
const alto=id=>{const w=QUIEN[id]||{};return id==="abuela"?51:w.nino?44:56;};
const caja=id=>{const p=W.gente[id];if(!p||p.vis===0)return null;const h=alto(id);return [R(p.x)-11,R(p.y)-h,22,h];};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const COSAS=Object.keys(QUIEN).map(persona).concat([
  {id:"olla0",si:w=>!!(w.fuegos[0]&&w.fuegos[0].k),box:[FX[0]-17,FY-24,34,28],m:1,z:1},{id:"olla1",si:w=>!!(w.fuegos[1]&&w.fuegos[1].k),box:[FX[1]-17,FY-24,34,28],m:1,z:1},
  {id:"saco",si:w=>!!w.izq.saco,box:[EN.saco[0]-11,EN.saco[1]-22,22,24],m:2,z:1},{id:"tazon",si:w=>!!w.izq.tazon,box:[EN.tazon[0]-12,EN.tazon[1]-16,24,18],m:2,z:1},
  {id:"estufa",box:[EST[0],EST[1]-2,EST[2],EST[3]],m:0},{id:"cocina",box:[22,16,196,198],m:0}]);

/* ---------- drawing ---------- */
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const w=QUIEN[id],x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  if(id==="abuela"){const ps=p.pose||"idle",top=y-50+((p.paso&&a%2)?-1:0);c.save();c.translate(x,top);if(d<0)c.scale(-1,1);c.drawImage(spr("ab"+ps+habla,()=>mkAbuela(ps,habla)),-30,0);c.restore();
    if(p.lleva)tenida(c,p.lleva.k||p.lleva,x+d*14,y-17,0,0,p.lleva.v);return;}
  const pose=p.pose||"idle",im=spr("pm"+id+pose+habla+"0",()=>KIT.mkPersona(w,pose,habla,0)),top=y-im.height+1+((p.paso&&a%2)?-1:0)+(p.dy||0);
  c.save();c.translate(x,top);if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  if(p.lleva)tenida(c,p.lleva.k||p.lleva,x+d*10,top+(w.nino?34:38),0,0,p.lleva.v);
  if(p.alza){const ax=x+d*13,ay=top+(w.nino?30:34);tenida(c,p.alza.k||p.alza,ax,ay,0,2,p.alza.v);}}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui"||q.hace)&&a%2?1:0,dy=R(q.dy),cx=b.x+(b.w>>1);
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.encima)tenida(g,W.encima.k,cx,b.y+dy+3,0,0,W.encima.v);}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{},I=W.izq||{},D=W.der||{};
  c.drawImage(spr("estufa",fondo),0,0);
  fuego(c,0,a);fuego(c,1,a);
  // the left counter
  if(I.saco)tenida(c,"saco",EN.saco[0],EN.saco[1]);if(I.tazon)tenida(c,"tazon",EN.tazon[0],EN.tazon[1]);
  if(I.jarra)tenida(c,"jarra",EN.jarra[0],EN.jarra[1]);for(let i=0;i<(I.tazas||0);i++)tenida(c,"taza",EN.tazas[0]-4+(i%2)*11,EN.tazas[1]-(i>>1)*5);
  // the right counter: plates, the waste bowl and what lies in it
  (D.platos||[]).forEach((p,i)=>{const x=EN.platos[0]-6+(i%2)*14,y=EN.platos[1]-(i>>1)*6;tenida(c,"plato",x,y);if(p.arroz)tenida(c,"monton",x-2,y-2,0,0,p.negro==="arroz"?"negro":"arroz");if(p.hab)tenida(c,"monton",x+3,y-1,0,0,"hab");});
  if(D.basura){tenida(c,"basura",EN.basura[0],EN.basura[1]);(W.basura||[]).forEach((k,i)=>tenida(c,"monton",EN.basura[0]-4+i*4,EN.basura[1]-5-i*2,0,0,k));}
  (D.apartes||[]).forEach((k,i)=>tenida(c,"taza",EN.apartes[0]-10+i*12,EN.apartes[1],0,0,k));
  const L=[];
  if(W.banco)L.push({y:BANCO[1]+1,d:()=>tenida(c,"banco",BANCO[0],BANCO[1]+18)});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.y,d:()=>gente(c,id,a)});});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>tenida(c,o.k,o.x,o.y,o.rot,0,o.v)});});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  (W.vuelos||[]).forEach(o=>tenida(c,o.k,o.x,o.y,o.rot,0,o.v));
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1];}
function respIcon(g,k,x,y,w,h,a){}
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,66,24);   // the card steps aside while three picture bubbles stand at the top
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m){g.fillStyle=OUT;for(let k=0;k<11;k++){g.fillRect(x+k,y+1+k,4,3);g.fillRect(x+10-k,y+1+k,4,3);}g.fillStyle="#C8401E";for(let k=0;k<11;k++){g.fillRect(x+1+k,y+2+k,2,1);g.fillRect(x+11-k,y+2+k,2,1);}}
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}
const marca=m=>{const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;};


/* ---------- moving things ---------- */
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/6));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;}
async function vuela(o,x0,y0,x1,y1,n){const v=Object.assign({x:x0,y:y0},o);W.vuelos.push(v);n=n||5;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(x1-x0)*t;v.y=y0+(y1-y0)*t-Math.sin(t*Math.PI)*8;await wait(TICK);}W.vuelos.splice(W.vuelos.indexOf(v),1);}
const acts={
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  // everything at once, to look at the drawing
  async prueba(o){const n=+(o&&o.n||1);
    W.gente={abuela:{x:LADO[1][0],y:LADO[1][1],dir:-1},luis:{x:LADO[0][0],y:LADO[0][1],dir:1},carmen:{x:AYUDA[0],y:AYUDA[1],dir:1,lleva:{k:"medida",v:"arroz"}},papa:{x:PUERTA[0],y:PUERTA[1]+6,dir:-1,vis:n===2?1:0}};
    W.fuegos=n===1?[{k:"olla",con:"arroz",n:2,llama:1,vapor:1},{k:"olla",con:"hab",n:1,llama:1,humo:1,negra:1}]:n===2?[{k:"olla",con:"agua",n:0,llama:1,vapor:1},{k:"olla",con:"vacia",n:0,llama:0}]:[{k:"sarten",llama:1,cosas:[]},{k:"olla",con:"choco",n:2,llama:1,vapor:1}];
    W.izq=n===3?{jarra:1,tazas:4}:{saco:1,tazon:1};W.der={platos:n===1?[{arroz:1,hab:1},{arroz:1},{}]:[{},{},{}],basura:1,apartes:n===3?["frio","cal"]:[]};W.basura=n===1?["hab","arroz"]:[];
    W.banco=1;Object.assign(W.cq,{x:BANCO[0]-16,y:BANCO[1]-27,s:1});W.encima=n===2?{k:"medida",v:"hab"}:null;W.tarjeta="rondas";W.marcas=["ok","x",null];},
};
async function stake(lost,max,en){await wait(200);}
function poke(what){}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)).join(" ")+" fuegos="+(W.fuegos||[]).map(f=>f&&f.k?f.k+":"+(f.con||"")+f.n+(f.llama?"*":"")+(f.negra?"#":""):"-").join("|")+" basura="+(W.basura||[]).join("+")+" marcas="+(W.marcas||[]).join(",");
KIT.escena({id:"estufa",CAM:{wide:[22,0,196,216]},heartAt:[124,24],lugar:{inicio:[BANCO[0]-16,BANCO[1]-27,1],centro:[BANCO[0]-16,BANCO[1]-27,1]},cosas:COSAS,
  fresh:()=>({respEn:[125,46],gente:{},fuegos:[{},{}],izq:{},der:{},basura:[],cosas:[],vuelos:[],banco:1,encima:null,tarjeta:null,marcas:null,cq:{x:BANCO[0]-16,y:BANCO[1]-27,s:1,dy:0,al:1,vis:1,bub:null,hace:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
