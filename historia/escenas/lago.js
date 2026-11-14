"use strict";
/* ============================================================
   Coquí · scene "El lago": the pond in the park (place 2, El parque).
   Water fills the lower half. On the left bank a short wooden dock.
   A post stands in the water. Reeds along the right bank; the far bank
   runs along the top of the water.
   People live in W.gente: {x,y (feet), pose, dir, vis}.
   Ducks in W.patos, by name: {k (blanco, negro, amarillo), x,y, pose
   (nada, vuela, anda), dir, dy, vis}. Fish in W.peces: {c (a colour), x,y
   (where it swims), dy (how high it has jumped), vis}. Birds in W.aves:
   {c, x,y, vuela}. Toy boats in W.botes: {c (rojo, azul, verde, madera),
   x,y, en (muelle, agua, juncos)}. Every story set here uses this drawing.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round;
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana},mkPerro=KIT.mkPerro,tarjeta=KIT.tarjeta;
const AGUA=118,MUELLE=[26,152,112,13],POSTE=[152,146],PM=[[40,141],[133,141]],JUNCOS=[[190,150],[200,144],[210,152],[196,158],[206,162]],ORILLA=[178,116];   // where the water starts; the dock; the post; the reeds; Carmen's place on the far bank
// light orange-red, middle blue, dark blue-green: the three differ in lightness too, for eyes that cannot tell red from green
const COLOR={rojo:["#C8401E","#F4683C","#FFA07A"],azul:["#1A3C8E","#2A5CC8","#5A8AE8"],verde:["#2A520E","#4A8420","#7AB03C"],pardo:["#4A3A1E","#7A6234","#A88E58"],amarillo:["#B8860C","#F0B81C","#FFD84A"],
  blanco:["#B8B8C8","#E6E6F0","#FFFFFF"],negro:["#16161E","#30303C","#50505E"],naranja:["#B85A14","#E88A2A","#F8B860"],madera:["#8A5A2A","#B8854A","#D8AA70"]};

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),G=RP.grn,Wd=RP.wood,Bl=RP.blue;
  sky(b,SW,100);grass(b,94,SW,AGUA+2);
  // the water: lighter far away, ripples
  for(let y=AGUA;y<SH;y++)for(let x=0;x<SW;x++){const t=(y-AGUA)/(SH-AGUA),rip=((y*3+((x+(y>>2)*5)>>3))%11)===0;b.px(x,y,rip&&hs(x>>2,y)<60?"#EAF6FA":t<.25?"#BFE0EA":hs(x>>1,y>>1)<8?"#BFE0EA":"#A6D2E0");}
  for(let x=0;x<SW;x++){b.px(x,AGUA,"#C8A468");b.px(x,AGUA+1,hs(x,3)<50?"#B08A54":"#7FB4C8");}
  // the left bank: grass coming down beside the dock
  for(let y=AGUA;y<SH;y++){const w=44-R((y-AGUA)*.12)+R(Math.sin(y/9)*3);for(let x=0;x<w;x++)b.px(x,y,x>w-2?"#B08A54":x>w-4?"#C8A468":hs(x,y)<18?G[1]:hs(x+5,y)<10?G[3]:G[2]);}
  // the dock: planks on posts
  const M=MUELLE;[M[0]+18,M[0]+56,M[0]+M[2]-6].forEach(x=>{b.rect(x,M[1]+M[3]-2,4,16,Wd[0]);b.rect(x,M[1]+M[3]-2,1,16,Wd[2]);b.frame(x-1,M[1]+M[3]-3,6,18,OUT);});
  b.rect(M[0],M[1],M[2],M[3],Wd[2]);for(let x=M[0]+6;x<M[0]+M[2];x+=9)b.rect(x,M[1],1,M[3],Wd[0]);b.rect(M[0],M[1],M[2],2,Wd[4]);b.rect(M[0],M[1]+M[3]-2,M[2],2,Wd[1]);b.frame(M[0]-1,M[1]-1,M[2]+2,M[3]+2,OUT);
  // two short posts at the ends of the dock, where a bird can sit
  PM.forEach(q=>{b.rect(q[0]-2,q[1],4,M[1]-q[1]+2,Wd[1]);b.rect(q[0]-2,q[1],1,M[1]-q[1]+2,Wd[3]);b.rect(q[0]-3,q[1]-1,6,2,Wd[2]);b.frame(q[0]-3,q[1]-2,6,M[1]-q[1]+4,OUT);});
  // the post in the water
  b.rect(POSTE[0]-3,POSTE[1]-22,6,30,Wd[1]);b.rect(POSTE[0]-3,POSTE[1]-22,2,30,Wd[3]);b.rect(POSTE[0]-4,POSTE[1]-24,8,3,Wd[2]);b.frame(POSTE[0]-4,POSTE[1]-24,8,33,OUT);b.ell(POSTE[0],POSTE[1]+8,7,2,["#EAF6FA"]);
  return b.done();}
function mkJunco(i){const b=new Buf(22,34),G=["#8A6E3A","#B89858","#D8BE80"];for(let k=-3;k<=3;k++){const h=18+((i*5+k*7)&11),x=11+k*3;b.rect(x,33-h,1,h,k%2?G[1]:G[0]);b.rect(x+1,33-h+2,1,h-2,G[2]);if((i+k)%2===0){b.rect(x-1,33-h-5,3,6,"#6E4220");b.px(x,33-h-6,"#6E4220");}}return b.done();}

/* ---------- the animals and the things ---------- */
// a duck, side on. nada: on the water, feet hidden; vuela: wings out; anda: on its feet
function mkPato(k,pose,f){const C=COLOR[k],b=new Buf(26,22),X=11,Y=12,pico="#E88A2A";
  if(pose==="vuela"){b.ell(X,Y,8,4,C);b.ell(X+8,Y-3,3.6,3.2,C);b.rect(X+11,Y-3,4,2,pico);b.px(X+9,Y-4,k==="negro"?"#FFFFFF":OUT);
    if(f){b.cap(X-2,Y-2,X-8,Y-10,2.4,[C[2]]);b.cap(X+1,Y-2,X-3,Y-11,2.2,[C[1]]);}else{b.cap(X-2,Y,X-9,Y+6,2.4,[C[2]]);b.cap(X+1,Y,X-4,Y+7,2.2,[C[1]]);}
    b.rect(X-9,Y+1,3,2,C[1]);return b.outline().done();}
  b.ell(X,Y+1,8,5,C);b.cap(X-7,Y,X-10,Y-4,1.6,[C[2]]);b.ell(X+6,Y-5,3.6,3.4,C);b.rect(X+4,Y-3,4,4,C[1]);b.rect(X+9,Y-5,4,2,pico);b.px(X+7,Y-6,k==="negro"?"#FFFFFF":OUT);b.ell(X-1,Y+1,4,2.4,[C[0],C[1]]);
  if(pose==="anda"){b.rect(X-3+(f?1:0),Y+6,2,4,pico);b.rect(X+2-(f?1:0),Y+6,2,4,pico);b.rect(X-4+(f?1:0),Y+9,4,1,pico);b.rect(X+1-(f?1:0),Y+9,4,1,pico);}
  return b.outline().done();}
function mkPez(c){const C=COLOR[c],b=new Buf(18,11);b.ell(8,5,6,3.4,C);b.cap(13,5,16,2,1.4,[C[1]]);b.cap(13,5,16,8,1.4,[C[1]]);b.px(4,4,OUT);b.px(4,3,"#FFFFFF");b.rect(7,2,3,1,C[0]);return b.outline().done();}
function mkPajaro(c,f,vuela){const C=COLOR[c],b=new Buf(15,12);b.ell(6,7,4.4,3.2,C);b.ell(10,4.5,2.8,2.6,C);b.px(11,4,c==="negro"?"#FFFFFF":OUT);b.rect(13,5,2,1,"#F0C020");b.cap(2,7,0,5,1.2,[C[0]]);
  if(vuela){if(f)b.cap(6,6,3,0,1.8,[C[2]]);else b.cap(6,8,3,11,1.6,[C[2]]);}else{b.ell(5,7,2.6,1.8,[C[0],C[1]]);b.rect(6,10,1,2,"#F0C020");b.rect(8,10,1,2,"#F0C020");}
  return b.outline().done();}
// a toy boat: a hull and one sail, all one colour (madera: bare wood, a white sail)
function mkBote(c){const C=COLOR[c],b=new Buf(20,20),V=c==="madera"?COLOR.blanco:C;b.rect(9,2,1,13,"#5A3A1A");for(let y=0;y<11;y++)b.rect(10,3+y,1+Math.floor(y*.7),1,V[y<3?2:1]);for(let y=0;y<8;y++)b.rect(8-Math.floor(y*.5),6+y,Math.floor(y*.5)+1,1,V[2]);
  b.rect(2,15,16,2,C[1]);b.rect(3,17,14,1,C[1]);b.rect(4,18,12,1,C[0]);b.rect(2,15,16,1,C[2]);return b.outline().done();}
function mkPote(c){const C=COLOR[c],b=new Buf(16,16);b.rect(1,4,14,11,"#C8C8D4");b.rect(1,4,3,11,"#E8E8F0");b.ell(8,4,7,2.6,[C[0],C[1],C[2]]);b.rect(3,8,10,5,C[1]);b.rect(3,8,10,1,C[2]);return b.outline().done();}
function mkPan(){const b=new Buf(11,10);b.rect(1,2,9,7,"#F4E2B4");b.ell(3.5,2.5,2.6,2,["#F4E2B4"]);b.ell(7.5,2.5,2.6,2,["#F4E2B4"]);b.rect(1,8,9,1,"#B07A3C");b.rect(1,3,1,6,"#C8904A");b.rect(9,3,1,6,"#C8904A");b.px(4,5,"#E0C890");b.px(6,6,"#E0C890");return b.outline().done();}
function mkBolsa(){const b=new Buf(12,13);b.rect(1,3,10,9,"#C8A468");b.rect(1,3,3,9,"#D8B67A");b.rect(1,3,10,2,"#B08A54");[[2,0],[5,1],[8,0]].forEach(p=>b.ell(p[0]+1,p[1]+2,1.8,1.6,["#D8AA70","#F0D8A8"]));return b.outline().done();}

const LUGAR={inicio:[100,125,1],muelle:[100,125,1]};
const FX=[46,68,90],FY=165,SALE=[[150,172],[168,180],[152,190]],PEGA=[[182,166],[196,172],[210,168],[190,178]];   // the row of boats along the front of the dock; where a boat is set on the water; where boats stick in the reeds
const slotC=i=>[98+(i%13)*6,119+(i>=13?4:0)];                                                                 // the row at Carmen's feet on the far bank
const P7=i=>[134+(i-1)*9.5,177+(i-1)*2],OFF=[[-14,-9],[14,-7],[0,12]],PK=["blanco","negro","amarillo"];           // story 20: seven places for the three ducks, from the dock outward
const alto=id=>QUIEN[id].nino?(W.gente[id]&&W.gente[id].sent?40:44):56;
const caja=id=>{const p=W.gente[id];return p&&p.vis!==0?[R(p.x)-11,R(p.y)-alto(id),22,alto(id)]:null;};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const patoCosa=n=>({id:"pato_"+n,z:1,m:0,si:w=>!!(w.patos&&w.patos[n]&&w.patos[n].vis!==0),box:w=>{const o=w.patos[n];return [R(o.x)-12,R(o.y)-17-(o.dy||0),24,18];}});
const aveCosa=n=>({id:"ave_"+n,z:1,m:3,si:w=>!!(w.aves&&w.aves[n]&&w.aves[n].vis!==0),box:w=>{const o=w.aves[n];return [R(o.x)-10,R(o.y)-15,20,18];}});
const boteCosa=c=>({id:"bote_"+c,z:1,m:1,si:w=>!!(w.botes&&w.botes["f_"+c]),box:w=>{const o=w.botes["f_"+c];return [R(o.x)-10,R(o.y)-20,20,22];}});
const COSAS=["luis","carmen"].map(persona).concat(PK.map(patoCosa),["blanco","negro"].map(aveCosa),["rojo","azul","verde"].map(boteCosa),[
  {id:"pez",z:1,m:3,si:w=>!!(w.peces&&w.peces.a&&w.peces.a.vis!==0),box:w=>{const o=w.peces.a;return [R(o.x)-11,R(o.y)-10-(o.dy||0),22,18];}},
  {id:"pajaro",z:1,m:3,si:w=>!!(w.aves&&w.aves.a&&w.aves.a.vis!==0),box:w=>{const o=w.aves.a;return [R(o.x)-10,R(o.y)-15,20,18];}},
  {id:"perro",si:w=>!!w.perro&&w.perro.vis!==0,box:w=>[R(w.perro.x)-14,R(w.perro.y)-14,28,16],m:1},
  {id:"flor",si:w=>!!w.flor,box:w=>[w.flor[0]-5,w.flor[1]-16,10,17],m:2},
  {id:"juncos",box:[178,120,40,46],m:0},{id:"poste",box:[POSTE[0]-5,POSTE[1]-26,10,36],m:1},{id:"muelle",box:[MUELLE[0],MUELLE[1]-2,MUELLE[2],MUELLE[3]+4],m:0},
  {id:"agua",box:[0,AGUA,240,98],m:0},{id:"lago",box:[0,94,240,122],m:0}]);

/* ---------- drawing ---------- */
// things that go on moving while he chooses: a bird or the duck flying round, the duck paddling round the post, a fish swimming to and fro or in a circle, things on their way somewhere
function anima(){
  Object.values(W.aves||{}).forEach(o=>{if(!o)return;if(o.ronda){const t=F/16+(o.fase||0);o.x=150+46*Math.cos(t);o.y=58+16*Math.sin(t);o.dir=Math.sin(t)<0?1:-1;o.vuela=1;}else if(o.sale){o.x+=2.2;o.y-=1.1;o.vuela=1;o.dir=1;if(o.x>250)o.vis=0;}});
  Object.values(W.patos||{}).forEach(o=>{if(!o)return;if(o.ronda){const t=F/16+(o.fase||0);o.x=150+46*Math.cos(t);o.y=58+16*Math.sin(t);o.dir=Math.sin(t)<0?1:-1;o.pose="vuela";}
    else if(o.rema){const t=F/22+(o.fase||0);o.x=POSTE[0]+20*Math.cos(t);o.y=POSTE[1]+16+7*Math.sin(t);o.dir=Math.sin(t)<0?1:-1;o.pose="nada";}
    else if(o.sale){o.sale++;o.dir=1;if(o.sale<26){o.x+=1.3;o.pose="nada";}else{o.x+=2.2;o.y-=2;o.pose="vuela";}if(o.x>250||o.y<-10)o.vis=0;}});
  Object.values(W.peces||{}).forEach(o=>{if(!o)return;if(o.vaiven){const t=F/14;o.x=o.x0+12*Math.sin(t);o.dir=Math.cos(t)>0?1:-1;}else if(o.circula){const t=F/12;o.x=120+13*Math.cos(t);o.y=192+4*Math.sin(t);o.dir=Math.sin(t)<0?1:-1;}
    else if(o.sale){o.x+=1.8;o.dir=1;if(o.x>236)o.vis=0;}else if(o.sigue&&W.botes[o.sigue]){const b=W.botes[o.sigue];o.x=b.x-4;o.y=b.y+9;o.dir=1;}});
  Object.values(W.botes||{}).forEach(o=>{if(!o||!o.meta)return;const dx=o.meta[0]-o.x,dy=o.meta[1]-o.y,d=Math.hypot(dx,dy),v=o.meta[2]||1.5;if(d<=v){o.x=o.meta[0];o.y=o.meta[1];o.meta=null;}else{o.x+=dx/d*v;o.y+=dy/d*v;}});}
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1,h=alto(id);
  const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="arriba"?"wave0":(p.pose||"idle"),im=spr("pc"+id+pose+habla+(p.sent?1:0),()=>KIT.mkPersona(QUIEN[id],pose,habla,p.sent));
  c.save();c.translate(x,y-im.height+1+((p.paso&&a%2)||(p.rie&&a%2)?-1:0)-(p.dy||0));if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  if(p.lleva==="bolsa")c.drawImage(spr("bolsa",mkBolsa),x+d*6-6,y-h+22);
  if(p.pan)c.drawImage(spr("pan",mkPan),x+d*9-5,y-h+22);
  (p.botes||[]).forEach((k,i)=>{const im2=spr("bt"+k,()=>mkBote(k));c.drawImage(im2,x+d*(8+i*9)-10,y-h+10+i*2);});   // boats in his hands
  if(p.pincel){fr(c,x+d*14,y-h+12,1,8,"#5A3A1A");fr(c,x+d*14-1,y-h+19,3,3,COLOR[p.pincel]?COLOR[p.pincel][1]:"#E8E8F0");}}
function pato(c,o,a){if(!o||o.vis===0)return;const anim=o.pose==="vuela"||o.pose==="anda"||o.come||o.aletea,f=anim?(a>>1)%2:0,pose=o.aletea?"vuela":(o.pose||"nada"),im=spr("pt"+o.k+pose+f,()=>mkPato(o.k,pose,f)),d=o.dir<0?-1:1,s=o.k==="amarillo"?.78:1,x=R(o.x),y=R(o.y)-(o.dy||0);
  c.save();c.translate(x,y);if(d<0)c.scale(-1,1);c.scale(s,s);if(pose==="nada"){c.drawImage(im,0,0,26,18,-13,-18+(o.come&&f?2:0),26,18);}else c.drawImage(im,-13,-21);c.restore();
  if(pose==="nada"){fr(c,x-R(11*s),y,R(22*s),1,"#EAF6FA");if((F>>3)%2)fr(c,x-d*R(14*s)-2,y+1,4,1,"#EAF6FA");}}   // the water line; a wake behind it
function pez(c,o){if(!o||o.vis===0)return;const im=spr("pz"+o.c,()=>mkPez(o.c)),d=o.dir<0?-1:1,x=R(o.x),y=R(o.y)-R(o.dy||0),fuera=(o.dy||0)>4;
  c.save();c.translate(x,y);if(d>0)c.scale(-1,1);if(fuera)c.rotate(-.5);c.drawImage(im,-9,-6);c.restore();
  if(!fuera){fr(c,x-9,y-7,18,1,"#EAF6FA");fr(c,x-6,y+5,12,1,"#7FB4C8");}}   // just under the clear water: its colour shows
function ave(c,o,a){if(!o||o.vis===0)return;const f=(a>>1)%2,v=o.vuela||o.aletea?1:0,im=spr("pj"+o.c+f+v,()=>mkPajaro(o.c,f,v)),d=o.dir<0?-1:1,y=R(o.y)-(o.dy||0);c.save();c.translate(R(o.x),y);if(d<0)c.scale(-1,1);c.drawImage(im,-7,-12);c.restore();
  if(o.pan)c.drawImage(spr("pan",mkPan),R(o.x)+d*9-5,y-11);}
function bote(c,o){if(!o||o.vis===0)return;const im=spr("bt"+o.c,()=>mkBote(o.c)),x=R(o.x),y=R(o.y),enAgua=o.en==="agua"||o.en==="juncos",bob=enAgua?((F>>3)%2):0;
  c.save();c.translate(x,y+bob);if(o.en==="juncos")c.rotate(.3);c.drawImage(im,-10,-19);c.restore();if(enAgua)fr(c,x-10,y+bob,20,1,"#EAF6FA");}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui")&&a%2?1:0,dy=R(q.dy);
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.pan&&W.pan.con==="cq")g.drawImage(spr("pan",mkPan),b.x+(b.w>>1)-5,b.y+dy+b.h-11);
  if(W.pincel){fr(g,b.x+b.w-4,b.y+dy+10,1,9,"#5A3A1A");fr(g,b.x+b.w-5,b.y+dy+8,3,3,COLOR[W.pincel]?COLOR[W.pincel][1]:"#E8E8F0");}}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{};anima();
  c.drawImage(spr("lago",fondo),0,0);
  if(W.flor){const x=W.flor[0],y=W.flor[1];fr(c,x,y-10,1,10,"#2E8A34");fr(c,x-3,y-5,3,2,"#2E8A34");[[-3,-14],[1,-14],[-3,-10],[1,-10],[-1,-16],[-1,-9],[-4,-12],[2,-12]].forEach(d=>fr(c,x+d[0],y+d[1],3,3,COLOR.amarillo[1]));fr(c,x-1,y-13,3,3,"#B85A14");}
  const L=[];
  Object.keys(W.peces||{}).forEach(k=>{const o=W.peces[k];if(o&&o.vis!==0)L.push({y:(o.dy||0)>4?o.y+40:AGUA+1,d:()=>pez(c,o)});});
  JUNCOS.forEach((p,i)=>L.push({y:p[1],d:()=>c.drawImage(spr("jn"+i,()=>mkJunco(i)),p[0]-11,p[1]-33)}));
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.y,d:()=>gente(c,id,a)});});
  Object.keys(W.patos||{}).forEach(k=>{const o=W.patos[k];if(o&&o.vis!==0)L.push({y:o.pose==="vuela"?o.y+200:o.y,d:()=>pato(c,o,a)});});
  Object.keys(W.aves||{}).forEach(k=>{const o=W.aves[k];if(o&&o.vis!==0)L.push({y:o.y+200,d:()=>ave(c,o,a)});});
  Object.keys(W.botes||{}).forEach(k=>{const o=W.botes[k];if(o&&o.vis!==0)L.push({y:o.y+(o.en==="juncos"?14:1),d:()=>bote(c,o)});});
  for(let i=0;i<(W.fila||0);i++)L.push({y:FY+1,d:()=>c.drawImage(spr("pan",mkPan),36+i*12-5,FY-8)});                 // the row of bread along the front of the dock
  if(W.bolsa)L.push({y:W.bolsa[1],d:()=>c.drawImage(spr("bolsa",mkBolsa),W.bolsa[0]-6,W.bolsa[1]-12)});
  if(W.saco)L.push({y:W.saco[1],d:()=>{const x=W.saco[0],y=W.saco[1];fr(c,x-8,y-10,16,11,OUT);fr(c,x-7,y-9,14,9,"#B89858");fr(c,x-7,y-9,4,9,"#D8BE80");fr(c,x-5,y-12,10,3,"#8A6E3A");}});
  if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>{const o=W.perro,f=o.pose==="bark"?(a>>1)%2:0,im=spr("pe"+o.pose+f,()=>mkPerro(o.pose,f));c.save();c.translate(R(o.x),R(o.y)-im.height+2);if(o.dir<0)c.scale(-1,1);c.drawImage(im,-13,0);c.restore();}});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  if(W.pan&&W.pan.con==null&&W.pan.vis!==0)L.push({y:999,d:()=>c.drawImage(spr("pan",mkPan),R(W.pan.x)-5,R(W.pan.y)-R(W.pan.z||0)-7)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  (W.salpica||[]).forEach(e=>{const t=F-e.f;if(t<10)for(let i=0;i<7;i++){const an=Math.PI+i*Math.PI/6;fr(c,e.x+R(Math.cos(an)*(3+t*1.2)),e.y+R(Math.sin(an)*(2+t*1.4))+R(t*t*.12),2,2,i%2?"#7FB4C8":"#FFFFFF");}});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.bub?38:0)];}
// the picture in an answer bubble: a pot of paint
function respIcon(g,k,x,y,w,h,a){const c=k.replace("pote_","");if(!COLOR[c])return;const im=spr("po"+c,()=>mkPote(c));g.imageSmoothingEnabled=false;g.drawImage(im,x+Math.round(w/2)-14,y+4,28,28);}

/* ---------- the card in the corner: three rounds; a star, or the mark of what went wrong ---------- */
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,66,24);
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m){g.fillStyle=OUT;for(let k=0;k<11;k++){g.fillRect(x+k,y+1+k,4,3);g.fillRect(x+10-k,y+1+k,4,3);}g.fillStyle="#C8401E";for(let k=0;k<11;k++){g.fillRect(x+1+k,y+2+k,2,1);g.fillRect(x+11-k,y+2+k,2,1);}}   // a cross: this round went wrong (what went wrong shows in the picture)
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}

/* ---------- moving things ---------- */
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/5));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;}
async function patoA(n,x,y,pose,pasos){const o=W.patos[n];if(!o)return;const x0=o.x,y0=o.y;pose=pose||o.pose||"nada";pasos=pasos||Math.max(4,R(Math.hypot(x-x0,y-y0)/(pose==="vuela"?8:3)));o.pose=pose;if(Math.abs(x-x0)>3)o.dir=x>x0?1:-1;
  for(let i=1;i<=pasos;i++){o.x=x0+(x-x0)*i/pasos;o.y=y0+(y-y0)*i/pasos;await wait(TICK);}o.x=x;o.y=y;}
const salpica=(x,y)=>{W.salpica=(W.salpica||[]).filter(e=>F-e.f<12).concat([{x:R(x),y:R(y),f:F}]);tone(300,0,.1,"sine",.1,90);};
const cuac=n=>{for(let k=0;k<(n||1);k++){tone(420,k*.16,.07,"sawtooth",.05,330);tone(330,k*.16+.07,.06,"sawtooth",.04,280);}};
const pio=()=>{tone(1500,0,.05,"sine",.06,2000);tone(1800,.06,.05,"sine",.05,1500);};
async function pezSalta(n,h){const o=W.peces[n];if(!o)return;salpica(o.x,o.y-6);for(let i=1;i<=10;i++){o.dy=(h||22)*Math.sin(Math.PI*i/10);await wait(TICK);}o.dy=0;salpica(o.x,o.y-6);}
async function pezA(n,x,y,pasos){const o=W.peces[n];if(!o)return;const x0=o.x,y0=o.y;pasos=pasos||Math.max(4,R(Math.hypot(x-x0,y-y0)/4));if(Math.abs(x-x0)>3)o.dir=x>x0?1:-1;for(let i=1;i<=pasos;i++){o.x=x0+(x-x0)*i/pasos;o.y=y0+(y-y0)*i/pasos;await wait(TICK);}}
async function aveA(n,x,y,pasos){const o=W.aves[n];if(!o)return;const x0=o.x,y0=o.y;pasos=pasos||Math.max(5,R(Math.hypot(x-x0,y-y0)/7));o.vuela=1;if(Math.abs(x-x0)>3)o.dir=x>x0?1:-1;for(let i=1;i<=pasos;i++){const t=i/pasos;o.x=x0+(x-x0)*t;o.y=y0+(y-y0)*t-10*Math.sin(Math.PI*t);await wait(TICK);}o.x=x;o.y=y;o.vuela=0;}
// the bread flies from whoever has it to a place (a place, or a function that says where its mark is now); then it is there
async function panA(a,alto,pasos){const pn=W.pan;if(!pn)return;let x0,y0;if(pn.con==="cq"){const b=frogBox(W.cq);x0=b.x+(b.w>>1);y0=W.cq.y+18;bounce(5);}else if(pn.con&&G(pn.con)){const p=G(pn.con);x0=p.x+8;y0=p.y-22;p.pan=0;}else{x0=pn.x;y0=pn.y;}
  pn.con=null;pn.vis=1;pasos=pasos||9;for(let i=1;i<=pasos;i++){const t=i/pasos,f=typeof a==="function"?a():a;pn.x=x0+(f[0]-x0)*t;pn.y=y0+(f[1]-y0)*t;pn.z=(alto||18)*4*t*(1-t);await wait(TICK);}pn.z=0;}
async function boteA(n,x,y,pasos){const o=W.botes[n];if(!o)return;const x0=o.x,y0=o.y;pasos=pasos||Math.max(5,R(Math.hypot(x-x0,y-y0)/3));for(let i=1;i<=pasos;i++){o.x=x0+(x-x0)*i/pasos;o.y=y0+(y-y0)*i/pasos;await wait(TICK);}o.x=x;o.y=y;}
const llegan=async()=>{for(let k=0;k<400&&Object.values(W.botes).some(o=>o&&o.meta);k++)await wait(TICK);};
function marca(m){const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;}
const quien=a=>a==="pez"?W.peces.a:a==="pajaro"?W.aves.a:a.startsWith("ave_")?W.aves[a.slice(4)]:W.patos[a.replace("pato_","")||"blanco"]||W.patos.blanco;
// where the mouth of an animal is now
const boca=a=>()=>{const o=quien(a);if(a==="pez")return [o.x,o.y-8];if(a==="pajaro"||a.startsWith("ave_"))return [o.x+(o.dir<0?-6:6),o.y-6];return [o.x+(o.dir<0?-11:11),o.y-(o.pose==="nada"?6:10)];};
// an animal gets the bread that is in somebody's hands (de: cq, luis, carmen) and eats it
async function come(a,de){if(!W.pan)W.pan={con:de||"cq"};else if(de)W.pan.con=de;const o=quien(a);if(de&&de!=="cq"&&G(de)){G(de).pose="arriba";await wait(200);}
  if(a==="pez"){const v=o.vaiven,ci=o.circula;o.vaiven=0;o.circula=0;await panA([o.x,o.y-8],18);salpica(o.x,o.y-8);W.pan=null;await pezSalta("a",7);o.vaiven=v;o.circula=ci;}
  else if(a==="pajaro"||a.startsWith("ave_")){await panA(boca(a),o.ronda?8:20);W.pan=null;pio();o.dy=2;await wait(150);o.dy=0;}
  else{await panA(boca(a),o.pose==="vuela"?8:20);W.pan=null;o.come=1;cuac(1);await wait(450);if(!W.sigueComiendo)o.come=0;}
  if(de&&de!=="cq"&&G(de))G(de).pose="idle";await wait(200);}

const acts={
  async pose(o){const p=G(o.quien);if(p)p.pose=o.que;},
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async come(o){W.sigueComiendo=o.sigue?1:0;await come(o.a,o.de);W.sigueComiendo=0;},
  async traga(){Object.values(W.patos||{}).forEach(d=>{d.come=0;});},

  /* ----- story 18: Pan para el pato ----- */
  async inicio18(){W.gente={luis:{x:44,y:154,pose:"idle",dir:1,sent:1},carmen:{x:72,y:154,pose:"idle",dir:1,lleva:"bolsa"}};Object.assign(W.cq,{x:100,y:125,s:1});
    W.patos={blanco:{k:"blanco",x:142,y:184,pose:"nada",dir:-1}};W.peces={a:{c:"pardo",x:92,y:192,x0:92,dir:1,vaiven:1}};W.aves={a:{c:"azul",x:POSTE[0],y:POSTE[1]-24,dir:-1}};W.fila=0;W.pan=null;},
  // the bird, or the duck, takes off and goes on flying round over the pond
  async sube(o){const a0=Math.PI*.7,tx=150+46*Math.cos(a0),ty=58+16*Math.sin(a0);if(o.quien==="pato"){const d=W.patos.blanco;d.rema=0;cuac(1);await patoA("blanco",tx,ty,"vuela");d.fase=a0-F/16;d.ronda=1;}else{const b=W.aves.a;pio();await aveA("a",tx,ty);b.vuela=1;b.fase=a0-F/16;b.ronda=1;}},
  async baja(o){if(o.quien==="pato"){const d=W.patos.blanco;d.ronda=0;d.rema=0;await patoA("blanco",142,184,d.pose==="vuela"?"vuela":"nada");if(d.pose==="vuela")salpica(142,184);d.pose="nada";d.dir=-1;}else{const b=W.aves.a;b.ronda=0;await aveA("a",POSTE[0],POSTE[1]-24);b.dir=-1;}},
  // the duck paddles round and round the post
  async rema(){const d=W.patos.blanco;d.ronda=0;await patoA("blanco",POSTE[0]+20,POSTE[1]+16,"nada");d.fase=-F/22;d.rema=1;},
  async giro(o){const d=W.patos.blanco,x0=d.x;for(let k=0;k<2;k++){await patoA("blanco",x0-10,d.y+3,"nada",6);await patoA("blanco",x0,d.y-3,"nada",6);}d.dir=-1;},
  // the duck climbs out onto the far bank and stands there; alagua: it slides back in and paddles home
  async orilla(){const d=W.patos.blanco;d.rema=0;d.ronda=0;await patoA("blanco",124,126,"nada");d.pose="anda";await patoA("blanco",120,118,"anda",4);d.dir=-1;for(let k=0;k<3;k++){d.dy=1;await wait(100);d.dy=0;await wait(100);}},
  async alagua(){const d=W.patos.blanco;if(d.pose==="anda"){await patoA("blanco",124,126,"anda",4);d.pose="nada";salpica(124,128);}d.rema=0;d.ronda=0;await patoA("blanco",142,184,"nada");d.dir=-1;},
  // the frog takes a piece of bread: from Carmen's bag, or (once the row is out) from the row on the dock
  async toma(){if(W.fila>0)W.fila--;W.pan={con:"cq"};SFX.blip();bounce(4);await wait(250);},
  async luispan(){const lu=G("luis");if(W.fila>0)W.fila--;W.pan={con:"luis"};lu.pan=1;SFX.blip();await wait(300);},
  // the one the bread was for goes off a little way; then it comes back
  async seva(o){const a=o.a,ob=quien(a);if(a==="pez"){salpica(ob.x,ob.y-6);ob.vis=0;}else ob.dir=1;await wait(450);},
  async vuelve(o){const a=o.a,ob=quien(a);if(a==="pez")ob.vis=1;else ob.dir=-1;await wait(300);},
  async turno18(){await acts.luispan();await come("pez","luis");const d=W.patos.blanco;d.dir=1;await wait(500);},
  async vuelca(){const ca=G("carmen");ca.pose="offer";ca.lleva=null;W.patos.blanco.dir=-1;for(let i=1;i<=6;i++){W.fila=i;SFX.blip();await wait(120);}ca.pose="idle";await wait(300);},
  async final18(){const n=Math.min(3,W.fila||0),ca=G("carmen"),d=W.patos.blanco;d.rema=0;d.ronda=0;const quienes=[["pato_blanco","carmen"],["pez","luis"],["pajaro","cq"]];
    for(let i=0;i<n;i++){W.fila--;W.pan={con:quienes[i][1]};await come(quienes[i][0],quienes[i][1]);}
    if(n===3){W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[70,60],[196,70],[136,50],[110,90],[170,96]]});await wait(700);}else if(n>0){SFX.win();await wait(500);}else{ca.pose="tu";SFX.coqui();await wait(900);ca.pose="idle";}},
  // the goodbye: each goes its own way, and goes on going while the line is said
  async sale(o){const ob=quien(o.a);if(o.a==="pez"){ob.vaiven=0;ob.circula=0;}else if(o.a==="pajaro"){ob.ronda=0;pio();}else{ob.rema=0;ob.ronda=0;cuac(1);}ob.sale=1;await wait(350);},

  /* ----- story 19: Los botes ----- */
  async inicio19(){W.gente={luis:{x:128,y:154,pose:"idle",dir:1},carmen:{x:ORILLA[0]+18,y:ORILLA[1]+1,pose:"idle",dir:-1}};Object.assign(W.cq,{x:60,y:125,s:1});W.saco=[110,153];W.botes={};W.nb=0;W.enC=0;W.enJ=0;W.peces={};W.aves={};W.patos={};
    await acts.repone({o:"rav"});},
  // the row on the dock always holds a red, a blue and a green boat (o: their order, e.g. "var")
  async repone(o){const C={r:"rojo",a:"azul",v:"verde"},ord=(o.o||W.ord19||"rav").split("");W.ord19=ord.join("");ord.forEach((k,i)=>{const c=C[k],id="f_"+c;if(!W.botes[id]){W.botes[id]={c,x:FX[i],y:FY,en:"muelle"};SFX.blip();}else{W.botes[id].x=FX[i];}});await wait(250);},
  // the frog pushes a boat from the row along the dock to Luis, who sets it on the water
  async empuja(o){const c=o.c.replace("bote_",""),b=W.botes["f_"+c],lu=G("luis"),k=Object.values(W.botes).filter(x=>x.en==="agua"&&!x.meta).length,id="b"+(W.nb++);bounce(5);delete W.botes["f_"+c];W.botes[id]=b;await boteA(id,134,FY,7);lu.pose="offer";await wait(150);await boteA(id,SALE[k%3][0],SALE[k%3][1],5);b.en="agua";salpica(b.x,b.y);lu.pose="idle";await wait(200);},
  async luiscoge(o){const c=o.c,b=W.botes["f_"+c],lu=G("luis"),k=Object.values(W.botes).filter(x=>x.en==="agua"&&!x.meta).length,id="b"+(W.nb++);await mueve("luis",b.x+16,154);lu.pose="offer";lu.dir=-1;await wait(200);delete W.botes["f_"+c];W.botes[id]=b;b.y=FY-6;b.x=lu.x-8;SFX.blip();const g=mueve("luis",128,154);await boteA(id,134,FY-6,8);await g;lu.dir=1;await boteA(id,SALE[k%3][0],SALE[k%3][1],5);b.en="agua";salpica(b.x,b.y);lu.pose="idle";await wait(200);},
  // Luis has his head down in his bag; mira: he looks at Carmen, away from the water
  async bolso(o){const lu=G("luis");lu.dir=-1;lu.pose=o.fin?"idle":"offer";if(o.fin)lu.dir=1;await wait(250);},
  async miracarmen(o){const lu=G("luis");lu.dir=1;lu.pose=o.fin?"idle":"wave";await wait(250);},
  // Luis blows: every boat waiting by the dock sails across to Carmen (it does not wait for them to arrive)
  async sopla(){const lu=G("luis");lu.pose="ojos";tone(700,0,.3,"sine",.05,500);Object.values(W.botes).filter(b=>b.en==="agua"&&!b.meta&&!b.deriva).forEach((b,i)=>{const s=slotC(W.enC++);b.meta=[s[0],s[1],1.9];b.rumbo="carmen";});await wait(400);lu.pose="idle";},
  async llegan(){await llegan();Object.values(W.botes).forEach(b=>{if(b.rumbo==="carmen"){b.en="carmen";b.rumbo=null;}});const ca=G("carmen");ca.pose="offer";await wait(250);ca.pose="idle";},
  // a boat on the water that nobody blows drifts out to the reeds and sticks there
  async deriva(){const e=Object.entries(W.botes).filter(x=>x[1].en==="agua"&&!x[1].meta&&!x[1].rumbo);if(!e.length)return;const id=e[e.length-1][0],b=e[e.length-1][1],s=PEGA[Math.min(3,W.enJ)];b.deriva=1;await wait(500);await boteA(id,s[0],s[1],34);b.en="juncos";W.enJ++;SFX.bonk();await wait(400);},
  // Luis takes a boat out of his bag (c: a colour, or madera for a bare one) and holds it; alagua19: he sets what he holds on the water
  async saca(o){const lu=G("luis");lu.botes=(lu.botes||[]).concat((o.c||"madera").split(","));SFX.blip();await wait(300);},
  async alagua19(){const lu=G("luis");for(const c of (lu.botes||[])){const k=Object.values(W.botes).filter(x=>x.en==="agua"&&!x.meta).length,id="b"+(W.nb++);W.botes[id]={c,x:lu.x+10,y:lu.y-20,en:"agua"};await boteA(id,SALE[k%3][0],SALE[k%3][1],6);salpica(SALE[k%3][0],SALE[k%3][1]);}lu.botes=[];await wait(200);},
  async luisve(){const lu=G("luis");for(let k=0;k<4;k++){lu.dir=-lu.dir;await wait(140);}lu.dir=1;SFX.bonk();await wait(250);},
  // a fish of one colour swims up to the dock, jumps once and circles there
  async pezviene(o){W.peces={a:{c:o.c,x:232,y:192,dir:-1}};await pezA("a",134,192,16);await pezSalta("a",24);W.peces.a.circula=1;await wait(300);},
  async pezsalta(){const f=W.peces.a;if(!f)return;const ci=f.circula;f.circula=0;await pezSalta("a",24);f.circula=ci;},
  async pezseva(){const f=W.peces.a;if(f){f.circula=0;f.sigue=null;f.sale=1;}await wait(300);},
  // Luis paints the first bare boat he holds (c: the colour)
  async luispinta(o){const lu=G("luis"),i=(lu.botes||[]).indexOf("madera");if(i<0)return;lu.pincel=o.c;await wait(350);lu.botes[i]=o.c;SFX.blip();await wait(350);lu.pincel=null;},
  // the frog paints the first bare boat Luis holds out
  async ranapinta(o){const lu=G("luis"),c=(o.c||"").replace("pote_",""),i=(lu.botes||[]).indexOf("madera");if(i<0)return;const q=W.cq,x0=q.x;W.pincel=c;await hopTo(lu.x-44,q.y,1);await wait(250);lu.botes[i]=c;SFX.blip();await wait(300);W.pincel=null;await hopTo(x0,q.y,1);},
  // the boat Luis holds goes onto the water and across, the fish swimming beside it
  async conpez(){const lu=G("luis"),c=(lu.botes||[])[0],id="b"+(W.nb++),f=W.peces.a;lu.botes=[];W.botes[id]={c,x:lu.x+10,y:lu.y-20,en:"agua"};await boteA(id,SALE[0][0],SALE[0][1],6);salpica(SALE[0][0],SALE[0][1]);if(f){f.circula=0;await pezA("a",SALE[0][0]-4,SALE[0][1]+9,6);f.sigue=id;}const sl=slotC(W.enC++),b=W.botes[id];b.meta=[sl[0],sl[1],1.6];b.rumbo="carmen";await wait(300);},   // no one blows: the fish pushes it
  async llegapez(){await acts.llegan();const f=W.peces.a;if(f){f.sigue=null;f.sale=1;}},
  // the last decision: which of the two colours he has done, and what is still to do (it sets V for the story file)
  async dosbotes(o){const lu=G("luis");lu.botes=["madera","madera"];W.c2=[o.c1,o.c2];W.hechos=[];V.falta="pote_"+o.c1;V.fc=o.c1;V.vale="pote_"+o.c2;V.pu="pote_rojo";V.pd="pote_azul";SFX.blip();await wait(300);},
  async pintado(o){const c=(V.ok!==""?o.x:V.falta).replace("pote_","");await acts.ranapinta({c});W.hechos.push(c);const resto=W.c2.filter(k=>!W.hechos.includes(k));V.falta=resto.length?"pote_"+resto[0]:"";V.fc=resto[0]||"";V.vale="";const libres=["rojo","azul","verde"].filter(k=>!W.hechos.includes(k));V.pu="pote_"+libres[0];V.pd="pote_"+libres[1];},
  async pintamal(o){const lu=G("luis"),c=o.x.replace("pote_","");await acts.ranapinta({c});const i=lu.botes.indexOf(c);lu.botes.splice(i,1);const id="b"+(W.nb++);W.botes[id]={c,x:lu.x+10,y:lu.y-20,en:"agua"};await boteA(id,SALE[2][0],SALE[2][1],6);salpica(SALE[2][0],SALE[2][1]);await acts.luisve();await acts.deriva();if(W.marcas&&W.marcas[2]===null)marca("bote");lu.botes.push("madera");},
  async findos(){await acts.alagua19();await acts.sopla();await acts.llegan();if(W.marcas&&W.marcas[2]===null){marca("ok");SFX.blip();}},
  async final19(){const n=W.enJ,ca=G("carmen");ca.pose="ojos";tone(700,0,.3,"sine",.05,500);const bs=Object.values(W.botes).filter(b=>b.en==="carmen"||(n<=1&&b.en==="juncos"));   // with nothing else lost, the line knocks the first boat free on its way homebs.forEach((b,i)=>{b.en="agua";b.meta=[150+((i%6)*11),176+Math.floor(i/6)*12+(i%6)*2,1.3];});await wait(500);ca.pose="idle";
    if(n<=1){W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[70,60],[196,70],[136,50],[110,90],[170,96]]});}else if(n<4)SFX.win();else SFX.coqui();await wait(1200);},

  /* ----- story 20: ¿Cuál? ----- */
  async inicio20(){W.gente={luis:{x:74,y:118,pose:"idle",dir:1,sent:1},carmen:{x:112,y:154,pose:"idle",dir:-1}};Object.assign(W.cq,{x:62,y:125,s:1});W.bolsa=[96,153];W.flor=[196,119];W.perro={x:46,y:119,pose:"lie",dir:1};
    W.lugarP=3;W.orden=[0,1,2];W.patos={};PK.forEach(k=>{W.patos[k]={k,x:0,y:0,pose:"nada",dir:-1};});W.aves={};W.pan=null;W.botes={};W.peces={};acts._pon();},
  _pon(){const p=P7(W.lugarP);PK.forEach((k,i)=>{const o=OFF[W.orden[i]];W.patos[k].x=p[0]+o[0];W.patos[k].y=p[1]+o[1];});},
  // the ducks paddle d places (minus: nearer the dock); baraja: they stop in a new order
  async mueven(o){const d=+(o.d||0);W.lugarP=Math.max(1,Math.min(7,W.lugarP+d));if(o.baraja){const a=W.orden.slice();for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]];}if(a.join()===W.orden.join())a.push(a.shift());W.orden=a;}
    const p=P7(W.lugarP);await Promise.all(PK.map((k,i)=>{const f=OFF[W.orden[i]];return patoA(k,p[0]+f[0],p[1]+f[1],"nada",o.baraja?12:null);}));PK.forEach(k=>{W.patos[k].dir=-1;});},
  async toma20(){W.pan={con:"cq"};SFX.blip();bounce(4);await wait(250);},
  async miran(){PK.forEach(k=>{W.patos[k].dy=2;});await wait(160);PK.forEach(k=>{W.patos[k].dy=0;});await wait(120);},
  // the one that was left out flaps and squawks; the noise sends the ducks out
  async ruido(o){const ob=quien(o.a);ob.aletea=1;if(o.a.startsWith("ave_"))for(let k=0;k<3;k++){pio();ob.dy=4;await wait(130);ob.dy=0;await wait(110);}else{cuac(3);for(let k=0;k<3;k++){ob.dy=3;await wait(130);ob.dy=0;await wait(110);}}ob.aletea=0;},
  // he throws the bread out without knowing which duck: all three go for it
  async rina(o){const ob=quien(o.a),x=ob.x,y=ob.y;await panA([x,y-4],20);salpica(x,y-4);W.pan=null;cuac(3);await Promise.all(PK.map(k=>patoA(k,x+(Math.random()*10-5),y+(Math.random()*6-3),"nada",5)));PK.forEach(k=>{W.patos[k].aletea=1;});await wait(600);PK.forEach(k=>{W.patos[k].aletea=0;});},
  // two birds land on the posts of the dock (lado: "bn" = white on the left, black on the right; "nb" the other way)
  async llegan20(o){const izq=o.lado==="nb"?"negro":"blanco",der=izq==="negro"?"blanco":"negro";W.aves={[izq]:{c:izq,x:-10,y:60,dir:1,casa:[PM[0][0],PM[0][1]-1]},[der]:{c:der,x:250,y:50,dir:-1,casa:[PM[1][0],PM[1][1]-1]}};pio();await Promise.all([aveA(izq,PM[0][0],PM[0][1]-1),aveA(der,PM[1][0],PM[1][1]-1)]);W.aves[izq].dir=1;W.aves[der].dir=-1;},
  // one bird hops down, takes a crust from beside Carmen's bag and goes back to its post with the crust in its beak
  async roba(o){const ca=G("carmen"),b=W.aves[o.c],h=b.casa;ca.pose="offer";ca.dir=-1;await wait(350);await aveA(o.c,W.bolsa[0]+10,W.bolsa[1]-1,5);await wait(200);b.pan=1;SFX.blip();await aveA(o.c,h[0],h[1],6);b.dir=h[0]<80?1:-1;W.ladron=o.c;await wait(250);ca.pose="idle";ca.dy=2;await wait(150);ca.dy=0;},
  // Carmen claps her hands at one bird. If it has the crust, it drops it in the water and the crust floats out to the ducks; if not, it squawks, and the other one flies off to the post with the crust
  async palmas(o){const ca=G("carmen"),c=o.c,b=W.aves[c],t=W.aves[W.ladron],enposte=Math.abs(b.x-POSTE[0])<4;ca.dir=enposte?1:(b.casa[0]<80?-1:1);ca.pose="arriba";for(let k=0;k<2;k++){tone(900,0,.03,"square",.06,700);ca.dy=2;await wait(120);ca.dy=0;await wait(120);}ca.pose="idle";
    if(c===W.ladron){b.pan=0;if(o.cerca!=="0")await acts.mueven({d:-1});const p=P7(W.lugarP);W.pan={con:null,x:b.x,y:b.y-4,z:0,vis:1};b.dy=3;await panA([b.x+(enposte?-8:10),172],4,6);b.dy=0;salpica(W.pan.x,W.pan.y);await panA([p[0],p[1]-6],0,22);W.pan=null;cuac(2);PK.forEach(k=>{W.patos[k].come=1;});await wait(500);PK.forEach(k=>{W.patos[k].come=0;});
      if(enposte){await aveA(c,b.casa[0],b.casa[1]);b.dir=b.casa[0]<80?1:-1;}}
    else{await acts.ruido({a:"ave_"+c});await acts.mueven({d:1});await aveA(W.ladron,POSTE[0],POSTE[1]-24);t.dir=-1;}},

  async turno20(){const pe=W.perro;pe.pose="bark";for(let k=0;k<3;k++){tone(520,0,.07,"square",.05,300);tone(400,.07,.1,"square",.05,240);await wait(260);}cuac(3);PK.forEach(k=>{W.patos[k].aletea=1;});const up=Object.keys(W.aves).map(n=>aveA(n,W.aves[n].x+(W.aves[n].x<80?30:-30),70,6));await Promise.all(up);PK.forEach(k=>{W.patos[k].aletea=0;});await acts.mueven({d:1});},
  // the birds, lifted by the bark, land again: which post each takes is drawn fresh
  async posan20(o){const izq=o.lado==="nb"?"negro":"blanco",der=izq==="negro"?"blanco":"negro";W.aves[izq].casa=[PM[0][0],PM[0][1]-1];W.aves[der].casa=[PM[1][0],PM[1][1]-1];await Promise.all([aveA(izq,PM[0][0],PM[0][1]-1),aveA(der,PM[1][0],PM[1][1]-1)]);W.aves[izq].dir=1;W.aves[der].dir=-1;},
  async echado(){W.perro.pose="lie";await wait(200);},
  // the last decision: he asked when she had already said which one
  // he asked when she had already said which one: while he waits for her to say it again, a bird takes the bread out of his hand
  async robamano(){const n=Object.keys(W.aves)[0],b=W.aves[n];if(!b)return;const q=frogBox(W.cq);await aveA(n,q.x+(q.w>>1),q.y+12,6);W.pan=null;b.pan=1;SFX.bonk();await aveA(n,POSTE[0],POSTE[1]-24,7);await wait(300);b.pan=0;await aveA(n,b.casa[0],b.casa[1]);b.dir=b.casa[0]<80?1:-1;if(W.marcas&&W.marcas[2]===null){marca("pan");SFX.blip();}},
  async premio20(){if(W.marcas&&W.marcas[2]!==null)return;await acts.mueven({d:-1});marca("ok");SFX.blip();await wait(250);},
  async marcaC(o){if(W.marcas&&W.marcas[2]===null){marca(o.que);SFX.blip();await wait(250);}},
  async final20(){const ca=G("carmen");if(W.lugarP===1){const xs=[104,118,131];await Promise.all(PK.map(async(k,i)=>{const d=W.patos[k];await patoA(k,136,172,"nada",6);d.pose="anda";await patoA(k,xs[i],154,"anda",8);d.dir=-1;}));cuac(2);W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[70,60],[196,70],[136,50],[110,90],[170,96]]});await wait(700);}
    else{W.pan={con:"carmen"};ca.dir=1;await come("pato_blanco","carmen");ca.dir=-1;const n=(W.marcas||[]).filter(m=>m==="ok").length;if(n)SFX.win();else SFX.coqui();await wait(500);}},
  /* ----- Escuchar: plain acts for the picture story and the routine ----- */
  async avea(o){const b=W.aves[o.c];if(!b)return;pio();if(o.sobre){const d=quien(o.sobre);await aveA(o.c,d.x-4,d.y-46);}else if(o.casa){await aveA(o.c,b.casa[0],b.casa[1]);b.dir=b.casa[0]<80?1:-1;}else await aveA(o.c,o.x,o.y);if(o.ronda){b.vuela=1;}},
  async suelta(o){const b=W.aves[o.c];if(!b)return;b.pan=0;const p=W.pan={con:null,x:b.x,y:b.y+4,z:0,vis:1},y1=o.y||178;SFX.blip();for(let i=1;i<=8;i++){p.y=b.y+4+(y1-b.y-4)*i/8;await wait(TICK);}salpica(p.x,p.y);await wait(250);},
  async cuacp(o){const d=W.patos[o.k];if(!d)return;cuac(1);for(let k=0;k<2;k++){d.dy=3;await wait(140);d.dy=0;await wait(120);}},
  async sevanp(o){await Promise.all((o.k||"negro,amarillo").split(",").map(async k=>{const d=W.patos[k];if(!d)return;d.dir=1;await patoA(k,252,d.y+8,"nada");d.vis=0;}));},
  async mecebote(o){const id=Object.keys(W.botes).find(k=>W.botes[k].c===o.c),b=W.botes[id];if(!b)return;SFX.blip();const y0=b.y;for(const d of [-2,1,-1,0]){b.y=y0+d;await wait(110);}b.y=y0;if(b.en==="agua")salpica(b.x,b.y);},
  async pezsalta1(){await pezSalta("a",20);},
  async anda(o){await mueve(o.quien,o.x,o.y);if(o.dir)G(o.quien).dir=o.dir;},
  async saluda(o){const p=G(o.quien);if(!p)return;p.pose=o.que||"wave";await wait(o.ms||700);p.pose="idle";},
  async ranaa(o){await hopTo(o.x,o.y,o.h||2);},
  // a piece of bread is thrown onto the water; the ducks race for it: the one named gets there first and eats it, the small yellow one is too slow
  async tirapan(o){const ca=G(o.de||"carmen");W.pan={con:o.de||"carmen"};ca.pose="arriba";await wait(250);await panA([o.x,o.y],22);salpica(o.x,o.y);W.pan={con:null,x:o.x,y:o.y,z:0,vis:1};ca.pose="idle";await wait(150);},
  async gana(o){const p=W.pan,d=W.patos[o.k],am=W.patos.amarillo;if(!p)return;const x=p.x,y=p.y;await Promise.all([patoA(o.k,x+(d.x<x?-11:11),y+5,"nada",6),patoA("amarillo",am.x+(x-am.x)*.45,am.y+(y+5-am.y)*.45,"nada",9)]);d.dir=d.x<x?1:-1;W.pan=null;d.come=1;cuac(1);await wait(600);d.come=0;am.dy=-2;await wait(300);am.dy=0;},
  async patoa(o){const d=W.patos[o.k];await patoA(o.k,o.x,o.y,"nada",o.pasos);if(o.dir)d.dir=o.dir;},
  async dip(){const b=W.aves.a;if(!b)return;pio();b.dy=6;await wait(250);b.dy=0;await wait(200);},
  async cuac(){cuac(1);const d=W.patos.amarillo;if(d){d.dy=3;await wait(150);d.dy=0;}},
};
async function stake(lost,max,en){SFX.bonk();await wait(300);}
function poke(what){if(what.startsWith("pato_"))cuac(1);else if(what==="pajaro"||what.startsWith("ave_"))pio();}
const estado=W=>"patos="+Object.keys(W.patos||{}).map(k=>k+"@"+R(W.patos[k].x)+","+R(W.patos[k].y)+":"+W.patos[k].pose).join(" ")+" lugar="+(W.lugarP||0)+" fila="+(W.fila||0)+" enC="+(W.enC||0)+" enJ="+(W.enJ||0)+" botes="+Object.keys(W.botes||{}).length+" marcas="+(W.marcas||[]).join("");
KIT.escena({id:"lago",CAM:{wide:[22,0,196,216]},heartAt:[110,30],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({gente:{},patos:{},peces:{},aves:{},botes:{},pan:null,fila:0,bolsa:null,saco:null,flor:null,perro:null,pincel:null,tarjeta:null,marcas:null,salpica:null,lugarP:0,orden:null,ladron:null,pregunto:0,nb:0,enC:0,enJ:0,cq:{x:LUGAR.inicio[0],y:LUGAR.inicio[1],s:1,dy:0,al:1,vis:1,bub:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
