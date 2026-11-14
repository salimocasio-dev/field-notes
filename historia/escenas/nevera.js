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
const PISO=150,ENC=112,NEV=[40,28,56,128],MOS=[110,108],BANCO=[104,190];   // the floor; the counter top; the fridge (x, y, width, height); the counter (x, width); the frog's stool
const HUECO=[[54,65],[82,65],[54,93],[82,93],[54,121],[82,121]];   // the six places in the fridge: where a thing stands
const EN={pan:[130,ENC+10],frutero:[170,ENC+10],vasos:[202,ENC+9]};
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,abuelo:FAM.abuelo,mama:FAM.mama,papa:FAM.papa,abuela:{}};
const COLV={luis:["#2A8A3A","#58C868"],carmen:["#D05888","#F898C0"],abuelo:["#B8A070","#E8D8A8"],papa:["#2A60B0","#58A0F0"],mama:["#B02828","#F05858"],abuela:["#7A48A8","#B888E8"],coqui:["#D07818","#F8B050"]};

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),Wd=RP.wood,[nx,ny,nw,nh]=NEV;
  for(let y=0;y<PISO;y++)for(let x=0;x<SW;x++)b.px(x,y,y>PISO-5?"#C8B88A":hs(x>>2,y>>2)<6?"#F0E4B8":"#F6ECC4");
  for(let y=72;y<ENC;y++)for(let x=MOS[0]-4;x<SW;x++)b.px(x,y,(x%8===0||y%8===0)?"#B8D0D8":"#E4F0F4");
  for(let y=PISO;y<SH;y++)for(let x=0;x<SW;x++){const ty=Math.floor((y-PISO)/12),tx=Math.floor((x+ty*6)/16);b.px(x,y,((y-PISO)%12===0||(x+ty*6)%16===0)?"#9A6A54":(tx+ty)%2?"#C8745A":"#E8D8B8");}
  for(let x=0;x<SW;x++)b.px(x,PISO-1,"#7A6A4A");
  // a window over the counter
  b.rect(170,24,40,36,"#9CCBF5");b.ell(198,50,10,9,RP.grn);b.frame(168,22,44,40,Wd[1]);b.frame(169,23,42,38,Wd[3]);b.rect(189,24,2,36,Wd[2]);b.rect(170,41,40,2,Wd[2]);
  // the counter: a cabinet, and a pale top seen a little from above
  b.rect(MOS[0],ENC+12,MOS[1],PISO+4-ENC-12,Wd[2]);b.rect(MOS[0],ENC+12,MOS[1],2,Wd[0]);b.frame(MOS[0]-1,ENC+11,MOS[1]+2,PISO+6-ENC-12,OUT);[36,72].forEach(d=>b.rect(MOS[0]+d,ENC+15,2,22,Wd[0]));
  b.rect(MOS[0]-2,ENC,MOS[1]+4,12,"#E8E8F0");b.rect(MOS[0]-2,ENC,MOS[1]+4,2,"#FFFFFF");b.rect(MOS[0]-2,ENC+10,MOS[1]+4,2,"#B8B8C8");b.frame(MOS[0]-3,ENC-1,MOS[1]+6,14,OUT);
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
  charco(){const b=new Buf(26,9);b.ell(12,5,10,3,["#B8B8C8","#F2F2F8","#FFFFFF"]);b.ell(22,3,2.4,1.4,["#FFFFFF"]);b.ell(3,2,1.6,1,["#FFFFFF"]);return b.outline().done();},
  gota(){const b=new Buf(4,5);b.rect(1,0,2,4,"#FFFFFF");return b.outline().done();},
  banco(){const b=new Buf(26,20);b.rect(2,1,22,4,RP.wood[3]);b.rect(2,1,22,1,RP.wood[4]);b.rect(4,5,3,14,RP.wood[1]);b.rect(19,5,3,14,RP.wood[1]);b.rect(5,11,16,2,RP.wood[1]);return b.outline().done();}};
const cosa=(k,c)=>spr("nv"+k+(c==null?"":c),()=>(COSA[k]||COSA.plato)(c));
function tenida(c,k,x,y,ang,esc,v){const im=cosa(k,v);if(ang||esc){c.save();c.translate(R(x),R(y));if(ang)c.rotate(ang);if(esc)c.scale(esc,esc);c.drawImage(im,-(im.width>>1),-im.height);c.restore();}else c.drawImage(im,R(x)-(im.width>>1),R(y)-im.height);}
// the fridge: open, its inside shows; shut, its door
function nevera(c,a){const N=W.nev||{},[x,y,w,h]=NEV;
  if(N.abierta){fr(c,x+3,y+18,w-6,h-22,"#EAF6FA");fr(c,x+3,y+18,w-6,2,"#B8D8E4");[66,94,122].forEach(sy=>{fr(c,x+3,sy,w-6,2,"#8AB4C8");});fr(c,x+5,126,w-10,24,"#CFE6EE");fr(c,x+5,126,w-10,1,"#8AB4C8");fr(c,x+22,131,12,2,"#8AB4C8");
    fr(c,x-14,y+15,14,h-15,OUT);fr(c,x-13,y+16,12,h-17,"#C8CCDA");fr(c,x-13,y+16,2,h-17,"#E8EAF2");[60,96,132].forEach(sy=>{fr(c,x-11,sy,9,2,"#8A8EA0");});
    (N.h||[]).forEach((o,i)=>{if(o)tenida(c,o.k,HUECO[i][0],HUECO[i][1],0,0,o.v);});}
  else{fr(c,x+2,y+17,w-4,h-19,"#F2F4FA");fr(c,x+2,y+17,w-4,1,"#8A8EA0");fr(c,x+2,y+17,2,h-19,"#FFFFFF");fr(c,x+w-10,y+46,3,30,"#8A8EA0");fr(c,x+w-9,y+46,1,30,"#C8CCDA");}}
const alto=id=>{const w=QUIEN[id]||{};return id==="abuela"?51:w.nino?44:56;};
const caja=id=>{const p=W.gente[id];if(!p||p.vis===0)return null;const h=alto(id);return [R(p.x)-11,R(p.y)-h,22,h];};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const enNevera=k=>({id:k,si:w=>!!(w.nev&&w.nev.abierta&&(w.nev.h||[]).some(o=>o&&o.k===k)),box:w=>{const i=w.nev.h.findIndex(o=>o&&o.k===k);return [HUECO[i][0]-13,HUECO[i][1]-23,26,26];},m:1,z:2});
const COSAS=Object.keys(QUIEN).map(persona).concat(["leche","queso","mantequilla"].map(enNevera)).concat([
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
  c.drawImage(spr("nevera",fondo),0,0);nevera(c,a);
  // the counter
  if(M.pan!=null)tenida(c,"pan",EN.pan[0],EN.pan[1],0,0,M.pan);
  if(M.frutero){const f=M.frutero,x=EN.frutero[0],y=EN.frutero[1];tenida(c,"frutero",x,y);for(let i=0;i<(f.guineo||0);i++)tenida(c,"guineo",x-14+i*2,y-5-i*4);for(let i=0;i<(f.manzana||0);i++)tenida(c,"manzana",x-1+(i%2)*4,y-5-i*5);for(let i=0;i<(f.china||0);i++)tenida(c,"china",x+13-(i%2)*4,y-5-i*5);}
  (M.vasos||[]).forEach((v,i)=>tenida(c,"vaso",v.x!=null?v.x:EN.vasos[0]-i*11,EN.vasos[1],0,0,v.de));
  (M.platos||[]).forEach((p,i)=>{const x=p.x!=null?p.x:150+i*20,y=ENC+10;tenida(c,"plato",x,y,0,2);(p.items||[]).forEach((o,j)=>tenida(c,o.k,x-5+j*10,y-3,0,0,o.v));});
  const L=[];
  if(W.banco)L.push({y:BANCO[1]+1,d:()=>tenida(c,"banco",BANCO[0],BANCO[1]+18)});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.y,d:()=>gente(c,id,a)});});
  (W.cosas||[]).forEach(o=>{if(o.vis!==0)L.push({y:o.z!=null?o.z:o.y+1,d:()=>tenida(c,o.k,o.x,o.y,o.rot,o.e||0,o.v)});});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  (W.vuelos||[]).forEach(o=>tenida(c,o.k,o.x,o.y,o.rot,0,o.v));
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.piensa&&p.vis!==0)nube(c,R(p.x)-14+(p.pdx||0),R(p.y)-alto(id)-26,p.piensa);});
  if(q.vis&&q.piensa){const b=frogBox(q);nube(c,b.x+(b.w>>1)-13,b.y-24,q.piensa);}
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1];}
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

  // everything at once, to look at the drawing
  async prueba(o){const n=+(o&&o.n||1);
    W.gente={abuela:{x:128,y:176,dir:-1},luis:{x:162,y:182,dir:1,alza:{k:"vaso",v:"luis",e:1,dx:10,dy:-6}},carmen:{x:190,y:190,dir:-1,piensa:{k:"guineo"}},papa:{x:206,y:204,dir:-1,vis:n===2?1:0}};
    W.nev={abierta:n!==3,h:[{k:"leche",v:4},{k:"leche",v:1},{k:"queso",v:3},{k:"mantequilla",v:3},null,{k:"queso",v:1}]};
    W.mos={pan:n===2?2:6,frutero:{guineo:3,manzana:3,china:3},vasos:[{de:"luis"},{de:"carmen"},{de:"abuelo"}],platos:n===2?[{de:"luis",x:150,items:[{k:"rebanada",v:"q"}]}]:[]};
    W.cosas=[{k:"charco",x:160,y:200},{k:"guineo",v:"pelado",x:140,y:ENC+8,z:300},{k:"manzana",v:"cortada",x:152,y:ENC+8,z:300},{k:"china",v:"cortada",x:214,y:ENC+8,z:300},{k:"guineo",v:"pardo",x:120,y:210},{k:"vasoarriba",v:"luis:1",x:60,y:200},{k:"vasoarriba",v:"carmen:0",x:80,y:200}];
    W.banco=1;W.tarjeta="rondas";W.marcas=["ok","x",null];},
};
async function stake(lost,max,en){await wait(200);}
function poke(what){}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)).join(" ")+" pan="+((W.mos||{}).pan)+" marcas="+(W.marcas||[]).join(",");
KIT.escena({id:"nevera",CAM:{wide:[22,0,196,216]},heartAt:[124,24],lugar:{inicio:[BANCO[0]-16,BANCO[1]-27,1],centro:[BANCO[0]-16,BANCO[1]-27,1]},cosas:COSAS,
  fresh:()=>({respEn:[125,46],nev:{abierta:1,h:[]},mos:{},gente:{},cosas:[],vuelos:[],banco:1,encima:null,tarjeta:null,marcas:null,cq:{x:BANCO[0]-16,y:BANCO[1]-27,s:1,dy:0,al:1,vis:1,bub:null,hace:null,piensa:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
