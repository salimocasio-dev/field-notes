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
const AGUA=112,MUELLE=[26,150,84,12],POSTE=[152,150],JUNCOS=[[186,150],[196,140],[206,152],[214,142],[200,162],[212,166]],ORILLA=[176,112];   // where the water starts; the dock; the post; the reeds; Carmen's place on the far bank
const COLOR={rojo:["#8E2018","#C83A2E","#F06A5A"],azul:["#1E4A9A","#2E6CD0","#6AA0F0"],verde:["#1E6A2A","#2E9A48","#6CCB74"],amarillo:["#C89A1C","#F0C83C","#FFE98C"],
  blanco:["#B8B8C8","#E6E6F0","#FFFFFF"],negro:["#16161E","#30303C","#50505E"],naranja:["#B85A14","#E88A2A","#F8B860"],madera:["#8A5A2A","#B8854A","#D8AA70"]};

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),G=RP.grn,Wd=RP.wood,Bl=RP.blue;
  sky(b,SW,100);grass(b,96,SW,AGUA+2);
  // the water: lighter far away, ripples
  for(let y=AGUA;y<SH;y++)for(let x=0;x<SW;x++){const t=(y-AGUA)/(SH-AGUA),rip=((y*3+((x+(y>>2)*5)>>3))%11)===0;b.px(x,y,rip&&hs(x>>2,y)<60?Bl[4]:t<.25?Bl[3]:hs(x>>1,y>>1)<8?Bl[3]:Bl[2]);}
  for(let x=0;x<SW;x++){b.px(x,AGUA,"#C8A468");b.px(x,AGUA+1,hs(x,3)<50?"#B08A54":Bl[1]);}
  // the left bank: grass coming down beside the dock
  for(let y=AGUA;y<SH;y++){const w=44-R((y-AGUA)*.12)+R(Math.sin(y/9)*3);for(let x=0;x<w;x++)b.px(x,y,x>w-2?"#B08A54":x>w-4?"#C8A468":hs(x,y)<18?G[1]:hs(x+5,y)<10?G[3]:G[2]);}
  // the dock: planks on posts
  const M=MUELLE;[M[0]+18,M[0]+46,M[0]+M[2]-6].forEach(x=>{b.rect(x,M[1]+M[3]-2,4,16,Wd[0]);b.rect(x,M[1]+M[3]-2,1,16,Wd[2]);b.frame(x-1,M[1]+M[3]-3,6,18,OUT);});
  b.rect(M[0],M[1],M[2],M[3],Wd[2]);for(let x=M[0]+6;x<M[0]+M[2];x+=9)b.rect(x,M[1],1,M[3],Wd[0]);b.rect(M[0],M[1],M[2],2,Wd[4]);b.rect(M[0],M[1]+M[3]-2,M[2],2,Wd[1]);b.frame(M[0]-1,M[1]-1,M[2]+2,M[3]+2,OUT);
  // the post in the water
  b.rect(POSTE[0]-3,POSTE[1]-22,6,30,Wd[1]);b.rect(POSTE[0]-3,POSTE[1]-22,2,30,Wd[3]);b.rect(POSTE[0]-4,POSTE[1]-24,8,3,Wd[2]);b.frame(POSTE[0]-4,POSTE[1]-24,8,33,OUT);b.ell(POSTE[0],POSTE[1]+8,7,2,[Bl[4]]);
  return b.done();}
function mkJunco(i){const b=new Buf(22,34),G=RP.grn;for(let k=-3;k<=3;k++){const h=18+((i*5+k*7)&11),x=11+k*3;b.rect(x,33-h,1,h,k%2?G[1]:G[0]);if((i+k)%2===0){b.rect(x-1,33-h-5,3,6,"#6E4220");b.px(x,33-h-6,"#6E4220");}}return b.done();}

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
function mkPote(c){const C=COLOR[c],b=new Buf(11,11);b.rect(1,3,9,7,"#C8C8D4");b.rect(1,3,2,7,"#E8E8F0");b.rect(1,2,9,2,C[1]);b.rect(2,2,7,1,C[2]);b.rect(3,6,5,2,C[1]);return b.outline().done();}
function mkPan(){const b=new Buf(8,6);b.ell(4,3,3.2,2.2,["#B07A3C","#D8AA70","#F0D8A8"]);return b.outline().done();}
function mkBolsa(){const b=new Buf(12,13);b.rect(1,3,10,9,"#C8A468");b.rect(1,3,3,9,"#D8B67A");b.rect(1,3,10,2,"#B08A54");[[2,0],[5,1],[8,0]].forEach(p=>b.ell(p[0]+1,p[1]+2,1.8,1.6,["#D8AA70","#F0D8A8"]));return b.outline().done();}

const LUGAR={inicio:[76,123,1],muelle:[76,123,1]};
const alto=id=>QUIEN[id].nino?(W.gente[id]&&W.gente[id].sent?40:44):56;
const caja=id=>{const p=W.gente[id];return p&&p.vis!==0?[R(p.x)-11,R(p.y)-alto(id),22,alto(id)]:null;};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
const patoCosa=n=>({id:"pato_"+n,z:1,m:3,si:w=>!!(w.patos&&w.patos[n]&&w.patos[n].vis!==0),box:w=>{const o=w.patos[n],s=o.k==="amarillo"?.75:1;return [R(o.x)-R(13*s),R(o.y)-R(18*s)-(o.dy||0),R(26*s),R(20*s)];}});
const COSAS=["luis","carmen"].map(persona).concat(["blanco","negro","amarillo"].map(patoCosa),[
  {id:"pez",z:1,m:4,si:w=>!!(w.peces&&w.peces.a&&w.peces.a.vis!==0),box:w=>{const o=w.peces.a;return [R(o.x)-10,R(o.y)-8-(o.dy||0),20,14];}},
  {id:"pajaro",z:1,m:4,si:w=>!!(w.aves&&w.aves.a&&w.aves.a.vis!==0),box:w=>{const o=w.aves.a;return [R(o.x)-9,R(o.y)-12,18,14];}},
  {id:"cielo",box:[150,40,68,70],hand:[190,80],m:0},{id:"juncos",box:[168,116,50,60],hand:[176,160],m:0},
  {id:"poste",box:[POSTE[0]-5,POSTE[1]-26,10,36],m:1},{id:"muelle",box:[MUELLE[0],MUELLE[1]-2,MUELLE[2],MUELLE[3]+4],m:0},
  {id:"agua",box:[0,AGUA,240,104],m:0},{id:"lago",box:[0,96,240,120],m:0}]);

/* ---------- drawing ---------- */
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1,h=alto(id);
  const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="arriba"?"wave0":(p.pose||"idle"),im=spr("pc"+id+pose+habla+(p.sent?1:0),()=>KIT.mkPersona(QUIEN[id],pose,habla,p.sent));
  c.save();c.translate(x,y-im.height+1+((p.paso&&a%2)||(p.rie&&a%2)?-1:0)-(p.dy||0));if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
  if(p.lleva==="bolsa")c.drawImage(spr("bolsa",mkBolsa),x+d*6-6,y-h+22);}
function pato(c,o,a){if(!o||o.vis===0)return;const mueve=o.pose==="vuela"||o.pose==="anda"||o.come,f=mueve?(a>>1)%2:0,pose=o.pose||"nada",im=spr("pt"+o.k+pose+f,()=>mkPato(o.k,pose,f)),d=o.dir<0?-1:1,s=o.k==="amarillo"?.75:1,x=R(o.x),y=R(o.y)-(o.dy||0);
  c.save();c.translate(x,y);if(d<0)c.scale(-1,1);c.scale(s,s);if(pose==="nada"){c.drawImage(im,0,0,26,17,-13,-17+(o.come&&f?2:0),26,17);}else c.drawImage(im,-13,-21);c.restore();
  if(pose==="nada"){fr(c,x-R(11*s),y,R(22*s),1,"#A8CCF8");if((F>>3)%2)fr(c,x-d*R(14*s)-2,y+1,4,1,"#A8CCF8");}   // the water line; a wake behind it
  if(o.espalda){}}
function pez(c,o){if(!o||o.vis===0)return;const im=spr("pz"+o.c,()=>mkPez(o.c)),d=o.dir<0?-1:1,x=R(o.x),y=R(o.y)-(o.dy||0),fuera=(o.dy||0)>4;
  c.save();c.translate(x,y);if(d>0)c.scale(-1,1);if(fuera)c.rotate(-.5);c.globalAlpha=fuera?1:.62;c.drawImage(im,-9,-6);c.restore();c.globalAlpha=1;
  if(!fuera){fr(c,x-7,y-7,14,1,"#6AA0F0");}}
function ave(c,o,a){if(!o||o.vis===0)return;const f=(a>>1)%2,im=spr("pj"+o.c+f+(o.vuela?1:0),()=>mkPajaro(o.c,f,o.vuela)),d=o.dir<0?-1:1;c.save();c.translate(R(o.x),R(o.y));if(d<0)c.scale(-1,1);c.drawImage(im,-7,-12);c.restore();}
function bote(c,o){if(!o||o.vis===0)return;const im=spr("bt"+o.c,()=>mkBote(o.c)),x=R(o.x),y=R(o.y),enAgua=o.en==="agua"||o.en==="juncos",bob=enAgua?((F>>3)%2):0;
  c.save();c.translate(x,y+bob);if(o.en==="juncos")c.rotate(.35);c.drawImage(im,-10,-19);c.restore();if(enAgua)fr(c,x-10,y+bob,20,1,"#A8CCF8");}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui")&&a%2?1:0,dy=R(q.dy);
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.pan&&W.pan.con==="cq")g.drawImage(spr("pan",mkPan),b.x+(b.w>>1)-4,b.y+dy+b.h-9);}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{};
  c.drawImage(spr("lago",fondo),0,0);
  const L=[];
  Object.keys(W.peces||{}).forEach(k=>{const o=W.peces[k];if(o&&o.vis!==0)L.push({y:(o.dy||0)>4?o.y+40:AGUA+1,d:()=>pez(c,o)});});
  JUNCOS.forEach((p,i)=>L.push({y:p[1],d:()=>c.drawImage(spr("jn"+i,()=>mkJunco(i)),p[0]-11,p[1]-33)}));
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.y,d:()=>gente(c,id,a)});});
  Object.keys(W.patos||{}).forEach(k=>{const o=W.patos[k];if(o&&o.vis!==0)L.push({y:o.pose==="vuela"?o.y+60:o.y,d:()=>pato(c,o,a)});});
  Object.keys(W.aves||{}).forEach(k=>{const o=W.aves[k];if(o&&o.vis!==0)L.push({y:o.y+70,d:()=>ave(c,o,a)});});
  Object.keys(W.botes||{}).forEach(k=>{const o=W.botes[k];if(o&&o.vis!==0)L.push({y:o.y+(o.en==="muelle"?1:0),d:()=>bote(c,o)});});
  (W.potes||[]).forEach(p=>L.push({y:p.y,d:()=>c.drawImage(spr("po"+p.c,()=>mkPote(p.c)),R(p.x)-5,R(p.y)-10)}));
  if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>{const o=W.perro,im=spr("pe"+o.pose+"0",()=>mkPerro(o.pose,0));c.save();c.translate(R(o.x),R(o.y)-im.height+2);if(o.dir<0)c.scale(-1,1);c.drawImage(im,-13,0);c.restore();}});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  if(W.pan&&W.pan.con==null&&W.pan.vis!==0)L.push({y:W.pan.y+80,d:()=>c.drawImage(spr("pan",mkPan),R(W.pan.x)-4,R(W.pan.y)-(W.pan.z||0)-5)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  (W.salpica||[]).forEach(e=>{const t=F-e.f;if(t<10)for(let i=0;i<7;i++){const an=Math.PI+i*Math.PI/6;fr(c,e.x+R(Math.cos(an)*(3+t*1.2)),e.y+R(Math.sin(an)*(2+t*1.4))+R(t*t*.12),2,2,i%2?"#A8CCF8":"#FFFFFF");}});
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.bub?38:0)];}
function respIcon(g,k,x,y,w,h,a){}
/* ---------- the card in the corner: three rounds; a star, or the mark of what went wrong ---------- */
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,66,24);
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m==="pan"){g.fillStyle=OUT;g.fillRect(x+1,y+4,12,9);g.fillStyle="#D8AA70";g.fillRect(x+2,y+5,10,7);g.fillStyle="#FFFDF4";[[8,5,4,3],[10,8,2,2],[6,5,2,1]].forEach(r=>g.fillRect(x+r[0],y+r[1],r[2],r[3]));}                 // a bitten crust
    else if(m==="bote"){g.drawImage(spr("btmadera",()=>mkBote("madera")),x-1,y-3,14,14);g.fillStyle="#1E6A2A";[[0,4],[4,2],[10,3],[13,5]].forEach(d=>g.fillRect(x+d[0],y+d[1],1,11-d[1]));}                                            // a boat in the reeds
    else if(m==="onda"){g.strokeStyle="#2E6CD0";g.lineWidth=1.5;[5,2.5].forEach(r=>{g.beginPath();g.ellipse(x+7,y+9,r+1.5,r*.5+1,0,0,7);g.stroke();});}                                                                                    // rings on the water: the ducks went off
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}

/* ---------- moving things ---------- */
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/5));p.sent=0;p.paso=1;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;}
// a duck paddles, or flies, to a place
async function patoA(n,x,y,pose,pasos){const o=W.patos[n];if(!o)return;const x0=o.x,y0=o.y;pose=pose||o.pose||"nada";pasos=pasos||Math.max(4,R(Math.hypot(x-x0,y-y0)/(pose==="vuela"?8:3)));o.pose=pose;if(Math.abs(x-x0)>3)o.dir=x>x0?1:-1;
  for(let i=1;i<=pasos;i++){o.x=x0+(x-x0)*i/pasos;o.y=y0+(y-y0)*i/pasos;await wait(TICK);}o.x=x;o.y=y;}
const salpica=(x,y)=>{W.salpica=(W.salpica||[]).filter(e=>F-e.f<12).concat([{x:R(x),y:R(y),f:F}]);tone(300,0,.1,"sine",.1,90);};
const cuac=n=>{for(let k=0;k<(n||1);k++){tone(420,k*.16,.07,"sawtooth",.05,330);tone(330,k*.16+.07,.06,"sawtooth",.04,280);}};
// a fish jumps out of the water and falls back
async function pezSalta(n,h){const o=W.peces[n];if(!o)return;salpica(o.x,o.y-6);for(let i=1;i<=10;i++){o.dy=(h||22)*Math.sin(Math.PI*i/10);await wait(TICK);}o.dy=0;salpica(o.x,o.y-6);}
async function pezA(n,x,y,pasos){const o=W.peces[n];if(!o)return;const x0=o.x,y0=o.y;pasos=pasos||Math.max(4,R(Math.hypot(x-x0,y-y0)/4));if(Math.abs(x-x0)>3)o.dir=x>x0?1:-1;for(let i=1;i<=pasos;i++){o.x=x0+(x-x0)*i/pasos;o.y=y0+(y-y0)*i/pasos;await wait(TICK);}}
async function aveA(n,x,y,pasos){const o=W.aves[n];if(!o)return;const x0=o.x,y0=o.y;pasos=pasos||Math.max(5,R(Math.hypot(x-x0,y-y0)/7));o.vuela=1;if(Math.abs(x-x0)>3)o.dir=x>x0?1:-1;for(let i=1;i<=pasos;i++){const t=i/pasos;o.x=x0+(x-x0)*t;o.y=y0+(y-y0)*t-10*Math.sin(Math.PI*t);await wait(TICK);}o.x=x;o.y=y;o.vuela=0;}
// the bread flies from whoever has it to a place (z: how high it ends); then it is there
async function panA(x,y,z,alto,pasos){const pn=W.pan;if(!pn)return;let x0,y0,z0;if(pn.con==="cq"){const b=frogBox(W.cq);x0=b.x+(b.w>>1);y0=W.cq.y+28;z0=8;bounce(5);}else if(pn.con&&G(pn.con)){const p=G(pn.con);x0=p.x+8;y0=p.y;z0=24;}else{x0=pn.x;y0=pn.y;z0=pn.z||0;}
  pn.con=null;pn.vis=1;pasos=pasos||9;for(let i=1;i<=pasos;i++){const t=i/pasos;pn.x=x0+(x-x0)*t;pn.y=y0+(y-y0)*t;pn.z=z0+((z||0)-z0)*t+(alto||18)*4*t*(1-t);await wait(TICK);}pn.x=x;pn.y=y;pn.z=z||0;}
async function boteA(n,x,y,pasos){const o=W.botes[n];if(!o)return;const x0=o.x,y0=o.y;pasos=pasos||Math.max(5,R(Math.hypot(x-x0,y-y0)/3));for(let i=1;i<=pasos;i++){o.x=x0+(x-x0)*i/pasos;o.y=y0+(y-y0)*i/pasos;await wait(TICK);}o.x=x;o.y=y;}
function marca(m){const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;}


const acts={
  async inicio18(){W.gente={luis:{x:44,y:152,pose:"idle",dir:1,sent:1},carmen:{x:66,y:152,pose:"idle",dir:1,lleva:"bolsa"}};Object.assign(W.cq,{x:84,y:123,s:1});
    W.patos={blanco:{k:"blanco",x:126,y:168,pose:"nada",dir:-1},negro:{k:"negro",x:160,y:186,pose:"nada",dir:-1},amarillo:{k:"amarillo",x:140,y:196,pose:"nada",dir:-1},v:{k:"blanco",x:120,y:70,pose:"vuela",dir:1}};
    W.peces={a:{c:"naranja",x:112,y:182,dir:1},b:{c:"azul",x:150,y:140,dy:14,dir:1},r:{c:"rojo",x:176,y:196,dir:-1}};W.aves={a:{c:"azul",x:POSTE[0],y:POSTE[1]-24,dir:-1},b:{c:"amarillo",x:180,y:60,vuela:1,dir:1},n:{c:"negro",x:90,y:50,vuela:1},w:{c:"blanco",x:60,y:70,vuela:1}};
    W.botes={r:{c:"rojo",x:36,y:150,en:"muelle"},a:{c:"azul",x:150,y:204,en:"agua"},v:{c:"verde",x:196,y:176,en:"juncos"},m:{c:"madera",x:100,y:206,en:"agua"}};W.potes=[{c:"rojo",x:30,y:164},{c:"azul",x:20,y:170},{c:"verde",x:34,y:176}];
    W.pan={con:"cq"};W.perro={x:22,y:128,pose:"lie",dir:1};},
};
async function stake(lost,max,en){SFX.bonk();await wait(300);}
function poke(what){}
const estado=W=>"patos="+Object.keys(W.patos||{}).map(k=>k+"@"+R(W.patos[k].x)+","+R(W.patos[k].y)+":"+W.patos[k].pose).join(" ");
KIT.escena({id:"lago",CAM:{wide:[22,0,196,216]},heartAt:[110,30],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({gente:{},patos:{},peces:{},aves:{},botes:{},potes:null,pan:null,perro:null,tarjeta:null,marcas:null,salpica:null,cq:{x:LUGAR.inicio[0],y:LUGAR.inicio[1],s:1,dy:0,al:1,vis:1,bub:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
