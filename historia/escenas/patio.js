"use strict";
/* ============================================================
   Coquí · scene "El patio": abuela's back yard.
   The back wall of the house with its door on the left, a wooden
   fence with a garden gate (el portón), a flamboyán with the bird's
   nest on the right, two flower beds, a sun that can sink to the
   fence, and night with fireflies. Luis and Carmen play here; the
   family comes to the back door to say goodbye.
   People live in W.gente, as in La sala. Flowers live in W.flores
   ({L:[...],R:[...]}, each {k:1 open | 0 a shut bud, c:colour}).
   Every story set here uses this drawing and these actions.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round;
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana,mama:FAM.mama,papa:FAM.papa,abuelo:FAM.abuelo};
const CAMA={L:[40,176,56,20],R:[144,176,56,20]},SOLX=100,SOLY=[24,40,56,73],FLOR=["#FF8FB8","#FFE070","#F4584A","#FFFFFF","#C890E8"];
const CIELO=[RP.sky,["#4E98EC","#7CB8F6","#B0D6FA","#E8E2C8","#FCE4A8"],["#6A84D0","#A892CC","#E8A088","#F8B468","#FFD27C"],["#34306E","#74448A","#C4546C","#EE7444","#FFAE3C"],["#0A0E2A","#10163E","#182052","#22306A","#2E3E80"]];

/* ---------- the picture ---------- */
function cielo(n){const b=new Buf(SW,116);b.grad(0,0,SW,116,CIELO[n]);
  if(n<2)[[52,16,1],[150,10,.8]].forEach(c=>{const s=c[2];b.ell(c[0],c[1],13*s,5*s,RP.cloud);b.ell(c[0]-9*s,c[1]+2,8*s,4*s,RP.cloud);b.ell(c[0]+10*s,c[1]+2,9*s,4*s,RP.cloud);});
  return b.done();}
function fondo(pt,pd){const b=new Buf(SW,SH),T=RP.teal,C=RP.cream,Wd=RP.wood,ST=RP.stone,G=RP.grn;
  b.ell(165,102,82,25,["#2E7A4A","#3A8E58","#4AA468"]);b.ell(40,106,72,20,["#3A8E58","#4AA468","#5CB878"]);
  grass(b,110,SW,SH);
  // the fence
  for(let x=60;x<SW;x++){if(x>=127&&x<=166)continue;const k=(x-60)%7,top=82+(k===0||k===5?1:0)-(k===2||k===3?1:0);if(k===6){b.rect(x,85,1,27,Wd[0]);continue;}
    for(let y=top;y<112;y++)b.px(x,y,k===0?Wd[4]:k===5?Wd[2]:Wd[3]);b.px(x,top-1,OUT);}
  [[60,67],[167,73]].forEach(p=>{b.rect(p[0],90,p[1],2,Wd[1]);b.rect(p[0],104,p[1],2,Wd[1]);});b.rect(60,112,180,1,OUT);
  // el portón, between two posts
  if(pt){b.grad(131,76,32,36,["#3A8E58","#4AA468","#62CC5A","#62CC5A"]);for(let y=84;y<112;y++){const hw=3+(y-84)*.34;b.rect(R(147-hw),y,R(2*hw),1,y%3?"#E8D098":"#D4B67A");}
    b.rect(131,80,4,32,C[1]);b.rect(131,80,1,32,C[3]);b.frame(130,79,6,34,OUT);}
  else{for(let x=131;x<163;x++){const k=(x-131)%6,top=80-R(4*Math.sin(Math.PI*(x-131)/31));if(k===5){b.rect(x,top+2,1,110-top,C[0]);continue;}for(let y=top;y<112;y++)b.px(x,y,k===0?C[4]:C[3]);b.px(x,top-1,OUT);}
    b.rect(131,91,32,2,C[1]);b.rect(131,103,32,2,C[1]);b.rect(157,95,3,4,RP.yel[2]);b.frame(156,94,5,6,OUT);}
  [127,163].forEach(x=>{b.rect(x,73,4,40,Wd[1]);b.rect(x,73,1,40,Wd[3]);b.rect(x-1,71,6,3,Wd[2]);b.frame(x-1,70,6,43,OUT);});
  // the back of the house
  b.grad(0,30,60,82,[T[3],T[3],T[2],T[2],T[1]],true);for(let y=35;y<112;y+=5)b.rect(0,y,60,1,T[1]);b.rect(59,30,1,82,"#134A4C");b.rect(60,30,1,83,OUT);
  for(let y=14;y<30;y++){const k=(y-14)%5,rw=Math.floor((y-14)/5),xr=62+Math.floor((y-14)/3);for(let x=0;x<=xr;x++)b.px(x,y,x===xr||y===29?"#4A1210":y===14?RP.red[4]:k===4?RP.red[0]:(x+rw*4)%8===0?RP.red[1]:RP.red[3]);}
  b.rect(0,30,62,3,C[3]);b.rect(0,32,62,1,C[1]);b.rect(0,33,62,1,OUT);
  b.rect(28,58,28,54,C[3]);b.frame(27,57,30,56,OUT);
  if(pd){b.grad(31,61,22,51,["#140A06","#22140C","#32201A"]);b.rect(50,61,3,51,Wd[2]);b.rect(50,61,1,51,Wd[4]);}
  else{b.grad(31,61,22,51,[Wd[3],Wd[2],Wd[2],Wd[1]],true);[[34,65,16,18],[34,88,16,20]].forEach(p=>{b.frame(p[0],p[1],p[2],p[3],Wd[0]);b.rect(p[0]+1,p[1]+1,p[2]-2,1,Wd[4]);});b.rect(49,86,2,2,RP.yel[2]);}
  b.frame(30,60,24,53,OUT);
  b.rect(22,112,40,4,ST[3]);b.rect(22,112,40,1,ST[4]);b.rect(22,115,40,1,ST[1]);b.frame(21,111,42,6,OUT);
  // the flamboyán, and the nest
  b.grad(198,56,12,58,[Wd[2],Wd[1],Wd[1],Wd[0]],true);b.rect(197,58,1,56,OUT);b.rect(210,58,1,56,OUT);b.rect(194,112,20,3,Wd[1]);b.rect(193,115,22,1,OUT);
  b.cap(200,75,182,72,1.8,[Wd[1]]);
  [[204,34,38,27],[180,46,17,13],[229,48,17,14]].forEach(e=>b.ell(e[0],e[1],e[2],e[3],G));
  for(let i=0;i<70;i++){const x=168+hs(i,3)*.7,y=9+hs(i,5)*.5;if(((x-204)/36)**2+((y-34)/25)**2<1)b.rect(x,y,2,2,i%3?RP.red[3]:RP.orng[3]);}
  b.ell(181,70,10,5,[Wd[0],Wd[1],Wd[2]]);b.ell(181,67.5,8,2.2,["#2A1408"]);for(let i=0;i<8;i++)b.px(172+hs(i,9)%18,70+hs(i,4)%4,RP.tan[3]);
  // two beds of earth, five holes in each
  for(const k in CAMA){const c=CAMA[k],cx=c[0]+28,cy=c[1]+10;b.ell(cx,cy,29,11,[OUT]);b.ell(cx,cy,28,10,["#4A2A14","#5E3A1E","#7A4E2A","#8E6034"]);for(let i=0;i<5;i++)b.ell(c[0]+8+i*10,cy,3,1.6,["#2A1408"]);}
  return b.done();}
function sol(c,x,y,n,brilla){const col=n>=3?["#E8502C","#F47A3C","#FFA050"]:n===2?["#F09A28","#F8B838","#FFD860"]:["#F8C838","#FFE070","#FFF4B0"],r=11,ray=brilla?10:(F>>3)%2?5:4;
  for(let k=0;k<8;k++){const an=k*Math.PI/4+((F>>3)%2?0:.39),x1=x+Math.cos(an)*(r+3),y1=y+Math.sin(an)*(r+3);for(let i=0;i<ray;i++)fr(c,R(x1+Math.cos(an)*i)-1,R(y1+Math.sin(an)*i)-1,2,2,col[1]);}
  c.fillStyle=OUT;c.beginPath();c.arc(x,y,r+1,0,7);c.fill();c.fillStyle=col[1];c.beginPath();c.arc(x,y,r,0,7);c.fill();c.fillStyle=col[2];c.beginPath();c.arc(x-2,y-2,r-4,0,7);c.fill();}
function luna(c,x,y){c.fillStyle="#FFFBEA";c.beginPath();c.arc(x,y,9,0,7);c.fill();c.fillStyle=CIELO[4][1];c.beginPath();c.arc(x+4,y-2,8,0,7);c.fill();}
const ESTRELLAS=[[60,18],[84,40],[124,12],[150,36],[40,46],[112,58],[72,64],[140,60]];
function mkCaja(){const b=new Buf(32,24),Wd=RP.wood;b.rect(1,12,30,11,Wd[3]);for(let x=1;x<31;x+=6)b.rect(x,12,1,11,Wd[1]);b.rect(1,12,30,1,Wd[4]);b.rect(1,17,30,1,Wd[2]);b.rect(1,22,30,1,Wd[0]);
  for(let i=0;i<5;i++){const x=4+i*6;b.rect(x,6,1,6,RP.grn[1]);b.ell(x+.5,4,2.6,2.6,[FLOR[i%FLOR.length]]);b.px(x,4,RP.orng[2]);b.rect(x+1,9,2,1,RP.grn[3]);}
  return b.outline().done();}
function mkSaco(ab){const b=new Buf(26,24),T=RP.tan;b.ell(13,15,11,8.5,T.slice(1));b.ell(8,13,4,3,[T[3],T[4]]);b.ell(17,17,4,3,[T[2],T[3]]);
  if(ab){b.ell(13,7,8,3.2,["#2A1408"]);b.rect(5,6,16,1,T[4]);}else{b.rect(10,3,6,5,T[2]);b.rect(9,6,8,1,RP.red[2]);b.rect(8,1,10,3,T[3]);}
  return b.outline().done();}
function mkCanasta(){const b=new Buf(18,17),T=RP.orng;for(let a=0;a<=24;a++){const t=Math.PI*a/24;b.px(9-7*Math.cos(t),7-6*Math.sin(t),T[1]);b.px(9-7*Math.cos(t),8-6*Math.sin(t),T[1]);}
  b.rect(2,8,14,8,T[2]);for(let y=8;y<16;y+=2)for(let x=2;x<16;x+=2)b.px(x+(y>>1)%2,y,T[0]);b.rect(1,7,16,2,T[3]);return b.outline().done();}
// the small things of this place, one drawing each: flor, vaso, silla, bizcocho, bola, maceta
function mkCosa(k){const b=new Buf(14,14),Wd=RP.wood;
  if(k==="flor"){b.rect(6,6,1,8,RP.grn[1]);b.rect(3,9,3,2,RP.grn[3]);b.rect(7,10,3,2,RP.grn[3]);b.ell(6.5,4,4,4,["#FF8FB8"]);b.ell(6.5,4,1.6,1.6,[RP.yel[2]]);}
  else if(k==="vaso"){for(let y=3;y<13;y++){const i=y>=10?1:0;b.rect(3+i,y,8-2*i,1,y>=6?RP.orng[3]:"#E8F4FF");}b.rect(3,6,8,1,RP.orng[4]);b.rect(4,3,1,9,"#FFFFFF");b.rect(3,2,8,1,"#FFFFFF");b.rect(8,0,1,8,RP.red[2]);b.px(9,0,RP.red[2]);}
  else if(k==="silla"){b.rect(3,1,2,12,Wd[2]);b.rect(3,2,7,1,Wd[3]);b.rect(3,4,7,1,Wd[3]);b.rect(9,1,1,6,Wd[2]);b.rect(3,7,9,2,Wd[3]);b.rect(10,9,2,4,Wd[2]);}
  else if(k==="bizcocho"){b.rect(1,12,12,1,"#FFFFFF");b.rect(2,7,10,5,"#F2D08A");b.rect(2,5,10,3,"#FF8FB8");b.rect(2,9,10,1,"#FFFDF4");b.rect(6,3,2,2,RP.red[2]);b.px(4,8,"#FF8FB8");b.px(9,8,"#FF8FB8");}
  else if(k==="bola"){b.ell(7,7.5,5.5,5.5,RP.red.slice(1));b.rect(2,7,10,2,"#FFFFFF");}
  else{b.rect(4,9,6,1,RP.orng[3]);b.rect(5,10,4,3,RP.orng[1]);b.rect(6,5,1,4,RP.grn[1]);b.ell(6.5,3,3,3,["#FFE070"]);b.px(6,3,RP.orng[2]);b.rect(8,6,2,1,RP.grn[3]);}
  return b.outline().done();}
function cosa(g,k,x,y,s){s=s||1;const im=spr("cosa"+k,()=>mkCosa(k));g.imageSmoothingEnabled=false;g.drawImage(im,R(x-7*s),R(y-14*s),R(14*s),R(14*s));}
// a flower in a bed: open, or a bud that stays shut
function florEn(g,x,y,f){
  if(!f.k){fr(g,x,y-5,1,6,RP.grn[1]);fr(g,x-2,y-10,5,6,OUT);fr(g,x-1,y-9,3,4,RP.grn[3]);fr(g,x,y-10,1,1,RP.grn[4]);return;}
  const col=FLOR[f.c%FLOR.length];fr(g,x,y-9,1,10,RP.grn[1]);fr(g,x-3,y-4,3,2,RP.grn[3]);fr(g,x+1,y-6,3,2,RP.grn[3]);
  fr(g,x-3,y-18,7,9,OUT);fr(g,x-4,y-17,9,7,OUT);fr(g,x-2,y-17,5,7,col);fr(g,x-3,y-16,7,5,col);fr(g,x-1,y-15,3,3,col==="#FFE070"?RP.orng[2]:RP.yel[2]);}
const hoyo=(k,i)=>[k==="L"?CAMA.L[0]+8+i*10:CAMA.R[0]+48-i*10,CAMA[k][1]+10];

/* ---------- where things are ---------- */
const LUGAR={puerta:[30,104,.8],inicio:[52,150,1],centro:[104,178,1],caja:[104,150,1],camaL:[90,164,.9],camaR:[118,164,.9],
  luis:[112,140,1],carmen:[62,130,1],carmenA:[112,116,.9],abuela:[70,170,1],porton:[128,104,.85],luisC:[96,140,.95],sale:[134,84,.5]};
const DETRAS={L:[68,176],R:[172,176]},ESPERA={luis:[160,128],carmen:[80,128]},LADOS=[[84,172],[156,172]];
const alto=id=>id==="abuela"?51:id==="bebe"?28:(QUIEN[id].nino?(W.gente[id]&&W.gente[id].sent?40:44):(W.gente[id]&&W.gente[id].sent?49:56));
const caja=id=>{const p=W.gente[id];return p&&p.vis!==0?[R(p.x)-11,R(p.y)-alto(id),22,alto(id)]:null;};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const COSAS=["luis","carmen","bebe","abuela","abuelo","mama","papa"].map(persona).concat([
  {id:"bola",si:w=>!!w.bola,box:w=>[R(w.bola.x)-7,R(w.bola.y)-13,14,14],m:2},{id:"saco",si:w=>!!w.saco,box:w=>[R(w.saco.x)-13,R(w.saco.y)-23,26,24],m:1},
  {id:"caja",si:w=>!!w.caja,box:[104,112,32,24],m:0},{id:"camaL",box:[40,160,56,38],m:2},{id:"camaR",box:[144,160,56,38],m:2},
  {id:"sol",si:w=>!w.noche&&w.soly<80,box:w=>[SOLX-14,R(w.soly)-14,28,28],m:3},{id:"porton",box:[127,70,40,43],m:1},{id:"nido",box:[170,60,22,16],m:1},{id:"arbol",box:[168,8,60,106],m:0},
  {id:"puerta",box:[27,57,30,56],m:0},{id:"casa",box:[0,14,61,100],m:0},{id:"cerca",box:[60,80,180,33],m:0},{id:"patio",box:[0,113,240,103],m:0}]);

/* ---------- drawing ---------- */
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,h=alto(id),d=p.dir<0?-1:1;c.globalAlpha=p.al==null?1:p.al;
  if(id==="bebe"){const e=p.est||"idle";c.drawImage(spr("bb"+e+(a%2),()=>KIT.mkBebe(e,a%2)),x-13,y-28);}
  else if(id==="abuela"){const pose=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle");c.save();c.translate(x,y-50);if(d<0)c.scale(-1,1);c.drawImage(spr("ab"+pose+habla,()=>mkAbuela(pose,habla)),-30,0);c.restore();}
  else{const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="alto"?"wave0":(p.pose||"idle"),im=spr("pp"+id+pose+habla+(p.sent?1:0),()=>KIT.mkPersona(QUIEN[id],pose,habla,p.sent));
    c.save();c.translate(x,y-im.height+1+(p.rie&&a%2?-1:0));if(d<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
    if(p.pelo){fr(c,x+3,y-h+2,6,6,OUT);fr(c,x+4,y-h+3,4,4,"#FF8FB8");fr(c,x+5,y-h+4,2,2,RP.yel[2]);}}   // a flower in her hair
  if(p.lleva){if(p.pose==="alto")cosa(c,p.lleva,x+d*14,y-h+13,2);else if(p.pose==="offer")cosa(c,p.lleva,x-d*20,y-h+30,1.4);else cosa(c,p.lleva,x,y-h+(p.sent?34:38),1.4);}
  if(p.encima)cosa(c,p.encima,x,y-h+3,1.4);
  c.globalAlpha=1;}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui")&&a%2?1:0,dy=R(q.dy);
  for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5-(j===1?0:2);i++)if((i+j)%2===0)fr(g,b.x+2+i,q.y+25+j,1,1,"#2E8A34");
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);
  if(q.ojos)[.3,.7].forEach(u=>{const ex=b.x+b.w*u,ey=b.y+dy+7*q.s,r=5.4*q.s;g.fillStyle=OUT;g.beginPath();g.arc(ex,ey,r+1,0,7);g.fill();g.fillStyle="#FFFFFF";g.beginPath();g.arc(ex,ey,r,0,7);g.fill();
    g.fillStyle="#20140A";g.beginPath();g.arc(ex+(q.ojx||0)*1.6*q.s,ey+(q.ojy==null?-1:q.ojy)*1.6*q.s,r*.5,0,7);g.fill();});   // eyes wide: he is looking
  g.globalAlpha=1;
  if(W.lleva)cosa(g,W.lleva,b.x+(b.w>>1),b.y+dy+1,1.4);
  if(W.canasta)g.drawImage(spr("canasta",mkCanasta),b.x+b.w-6,b.y+b.h-17);}
Object.assign(BUBL,{q:["q"]});
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
// a firefly: where it is. en = with someone (Carmen's finger, abuelo's napkin, or the middle of the yard); con = flying beside the frog.
function luzPos(l,i){const G=W.gente||{},q=W.cq,b=frogBox(q);
  if(l.est==="en"){if(l.id==="carmen"&&G.carmen){const p=G.carmen,d=p.dir<0?-1:1;return [p.x+d*13,p.y-alto("carmen")+4];}
    if(l.id==="abuelo"&&G.abuelo){const p=G.abuelo;return [p.x+(p.pose==="offer"?-(p.dir<0?-1:1)*20:0),p.y-alto("abuelo")+14];}
    return [l.x0+4*Math.sin(F/9+i),l.y0+3*Math.cos(F/7+i)];}
  if(l.est==="con"){const an=F/8+i*2.09,rr=W.aro?20:15;return [b.x+b.w/2+rr*Math.cos(an),b.y+4+(W.aro?9:6)*Math.sin(an)-4];}
  return [l.x,l.y];}
function luciernaga(c,x,y,br,al){x=R(x);y=R(y);c.globalAlpha=al==null?1:al;
  if(br){const k=(F>>2)%3;c.fillStyle="rgba(240,255,120,"+(k?.28:.16)+")";c.beginPath();c.arc(x+1,y+1,k?7:5,0,7);c.fill();fr(c,x-1,y-1,4,4,"#F4FF9A");fr(c,x,y,2,2,"#FFFFFF");}
  else{fr(c,x-1,y-1,4,4,"#5A6A30");fr(c,x,y,2,2,(F>>3)%2?"#F4FF9A":"#C8D870");}
  c.globalAlpha=1;}
function draw(c,W,a){const q=W.cq,G=W.gente||{},n=W.noche?4:Math.min(3,W.sol||0);
  c.drawImage(spr("cielo"+n,()=>cielo(n)),0,0);
  if(W.estrella||W.noche)ESTRELLAS.slice(0,W.noche?8:1).forEach((p,i)=>{const t=(F+i*7)%24<3;fr(c,p[0],p[1],t?1:2,t?1:2,"#FFFFFF");if(!t){fr(c,p[0]-1,p[1],4,1,"#FFF4B0");fr(c,p[0],p[1]-1,1,4,"#FFF4B0");}});
  if(W.luna)luna(c,150,26);else if(W.soly<110)sol(c,SOLX,R(W.soly),n,W.brilla&&F-W.brilla<10);
  c.drawImage(spr("patio"+(W.porton?1:0)+(W.pdoor?1:0),()=>fondo(W.porton,W.pdoor)),0,0);
  const L=[];
  Object.keys(G).forEach(id=>{const p=G[id];if(p&&p.vis!==0)L.push({y:p.z||p.y,d:()=>gente(c,id,a)});});
  for(const k in CAMA){const fl=(W.flores||{})[k]||[];L.push({y:CAMA[k][1]+12,d:()=>fl.forEach((f,i)=>{const h=hoyo(k,i);florEn(c,h[0],h[1],f);})});}
  if(W.caja)L.push({y:136,d:()=>c.drawImage(spr("caja",mkCaja),104,112)});
  if(W.saco)L.push({y:W.saco.y+1,d:()=>c.drawImage(spr("saco"+(W.saco.ab?1:0),()=>mkSaco(W.saco.ab)),R(W.saco.x)-13,R(W.saco.y)-23)});
  if(W.bola)L.push({y:W.bola.y,d:()=>cosa(c,"bola",W.bola.x,W.bola.y-(W.bola.h||0),1)});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  if(W.polvo){const p=W.polvo;for(let i=0;i<3;i++){fr(c,p.x+p.dir*(4+i*6)-2,p.y-2-i%2*3,4,3,"#FFFFFF");fr(c,p.x+p.dir*(4+i*6)-1,p.y-1-i%2*3,3,2,"#E8E0C8");}for(let i=0;i<3;i++)fr(c,p.x+p.dir*8,p.y-12-i*5,9,1,"#FFFFFF");}   // dust and speed lines behind a hop
  if(W.rizo){const z=W.rizo;c.strokeStyle="#FFFFFF";c.lineWidth=1;c.setLineDash([2,3]);c.beginPath();c.arc(z.x,z.y,z.r||12,0,7);c.stroke();c.setLineDash([]);}   // the loop the bird has just flown
  if(W.ave&&W.ave.mode!=="none"){KIT.drawAve(c,W.ave);if(W.ave.lleva){const p=KIT.avePos(W.ave);cosa(c,W.ave.lleva,p[0]+(W.ave.dir||1)*9,p[1]+8,1);}}
  (W.mari||[]).forEach((m,i)=>{const x=R(m.x+5*Math.sin(F/6+i*2)),y=R(m.y+3*Math.cos(F/5+i)),w=(F>>1)%2?4:2,col=FLOR[(i+1)%FLOR.length];fr(c,x-w-1,y-3,w+2,7,OUT);fr(c,x,y-3,w+2,7,OUT);fr(c,x-w,y-2,w,5,col);fr(c,x+1,y-2,w,5,col);fr(c,x,y-2,1,5,OUT);});
  if(W.vuela){const v=W.vuela;cosa(c,v.k,v.x,v.y,v.s||1);}
  // the light of the hour, over everything in the yard
  if(!W.noche&&n>=2){c.fillStyle=n===2?"rgba(255,150,50,.10)":"rgba(230,90,70,.17)";c.fillRect(0,0,SW,SH);}
  if(W.osc){c.fillStyle="rgba(12,16,56,"+(.5*W.osc)+")";c.fillRect(0,0,SW,SH);}
  (W.luces||[]).forEach((l,i)=>{if(l.est==="fuera")return;const p=luzPos(l,i);luciernaga(c,p[0],p[1],W.brillo||l.est==="con",l.al);});
  Object.keys(G).forEach(id=>{const p=G[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2-(W.lleva?18:0),a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.bub?38:0)];}
// the two doing bubbles: ir = the frog in the middle of a hop; ver = his two big eyes
function respIcon(g,k,x,y,w,h,a){
  if(k==="ir"){const up=a%2?1:0;fr(g,x+4,y+32,32,1,"#9494A6");for(let i=0;i<=12;i++){const t=i/12,px=x+5+30*t,py=y+31-22*Math.sin(Math.PI*t);if(i%2===0)fr(g,R(px),R(py),2,2,"#2E9A48");}
    g.drawImage(spr("cq.6_0",()=>mkCoqui(.6,0,0)),x+10,y+2-up);fr(g,x+15,y+29,10,2,"#C8C8D4");}
  else{[13,27].forEach(ex=>{g.fillStyle=OUT;g.beginPath();g.arc(x+ex,y+17,8,0,7);g.fill();g.fillStyle="#FFFFFF";g.beginPath();g.arc(x+ex,y+17,7,0,7);g.fill();g.fillStyle="#2E6CD0";g.beginPath();g.arc(x+ex,y+16-(a%2),4,0,7);g.fill();g.fillStyle="#20140A";g.beginPath();g.arc(x+ex,y+16-(a%2),2,0,7);g.fill();});
    [[4,6],[20,3],[36,6]].forEach(p=>fr(g,x+p[0],y+p[1],1,4,"#F8C838"));}}

/* ---------- what is at stake, in the corner of the screen ---------- */
function tarjeta(g,x,y,w,h){g.fillStyle=OUT;g.fillRect(x-1,y,w+2,h);g.fillRect(x,y-1,w,h+2);g.fillStyle="#FFFDF4";g.fillRect(x,y,w,h);}
function hud(g,W,a){
  if(W.tarjeta==="sol"){const k=W.muestra!=null?W.muestra:(W.lost||0);tarjeta(g,3,3,34,52);g.fillStyle="#BFE0F0";g.fillRect(5,5,30,40);   // the sun on its way down to the fence
    for(let i=0;i<4;i++){const y=11+i*10;if(i===k){g.fillStyle=OUT;g.beginPath();g.arc(20,y,6,0,7);g.fill();g.fillStyle=i>=3?"#F47A3C":"#F8C838";g.beginPath();g.arc(20,y,5,0,7);g.fill();}else{g.fillStyle=i<k?"#DCEEFF":"#FFFFFF";g.fillRect(18,y-1,4,3);}}
    for(let x=5;x<35;x+=5){g.fillStyle=RP.wood[2];g.fillRect(x,43,4,10);g.fillStyle=RP.wood[4];g.fillRect(x,43,1,10);}g.fillStyle=OUT;g.fillRect(5,42,30,1);}
  if(W.tanteo){const mio=W.canasta||[],suyo=W.nido||[];tarjeta(g,3,3,24+Math.max(3,mio.length)*15,26);g.drawImage(spr("canasta",mkCanasta),5,7);mio.forEach((k,i)=>cosa(g,k,36+i*15,25,1));
    const w=28+3*15;tarjeta(g,DW-w-3,3,w,26);g.drawImage(spr("kaven0",()=>KIT.mkAve("n",0)),DW-24,8);g.fillStyle=RP.wood[1];g.fillRect(DW-27,22,22,4);suyo.forEach((k,i)=>cosa(g,k,DW-w+6+i*15,25,1));}
  if(W.tarjeta==="luces"){tarjeta(g,3,3,84,30);g.drawImage(spr("cq.7_0",()=>mkCoqui(.7,0,0)),5,9);(W.luces||[]).slice(0,3).forEach((l,i)=>{const x=42+i*15,y=18;
      if(l.est==="con"){g.fillStyle="rgba(248,224,64,.4)";g.beginPath();g.arc(x,y,7,0,7);g.fill();g.fillStyle=OUT;g.fillRect(x-4,y-4,8,8);g.fillStyle="#F8E040";g.fillRect(x-3,y-3,6,6);g.fillStyle="#FFFFFF";g.fillRect(x-1,y-1,2,2);}
      else if(l.est==="ido"){g.fillStyle="#9494A6";g.fillRect(x-4,y-4,8,8);g.fillStyle="#FFFDF4";g.fillRect(x-3,y-3,6,6);g.fillStyle="#B8B8C8";for(let k=-2;k<=2;k++){g.fillRect(x+k,y+k,1,1);g.fillRect(x+k,y-k,1,1);}}
      else{g.fillStyle="#6E6E80";g.fillRect(x-3,y-3,6,6);g.fillStyle="#D8E890";g.fillRect(x-2,y-2,4,4);}});}
}

/* ---------- what can happen here ---------- */
const G=id=>W.gente[id],azar=()=>Math.random()<.5;
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/6));p.sent=0;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n-(i%2);await wait(TICK);}p.x=x;p.y=y;}
async function vuelaA(k,x0,y0,x1,y1,s){W.vuela={k,x:x0,y:y0,s:s||1};for(let i=1;i<=7;i++){W.vuela.x=x0+(x1-x0)*i/7;W.vuela.y=y0+(y1-y0)*i/7-Math.sin(Math.PI*i/7)*12;await wait(TICK);}W.vuela=null;}
const ranaXY=()=>{const b=frogBox(W.cq);return [b.x+(b.w>>1),b.y+6];};
const mira=id=>{const p=G(id),q=W.cq;if(p)p.dir=q.x+16<p.x?-1:1;};
const bolaA=async(x,y,n)=>{const b=W.bola,x0=b.x,y0=b.y;n=n||6;for(let i=1;i<=n;i++){b.x=x0+(x-x0)*i/n;b.y=y0+(y-y0)*i/n;b.h=Math.sin(Math.PI*i/n)*18;await wait(TICK);}b.h=0;SFX.blip();};
const cantidad=()=>(W.flores.L.length+W.flores.R.length);
function camas(){const m=(V.mem_flores||"11111-11111").split("-");let n=0;["L","R"].forEach((k,j)=>{W.flores[k]=(m[j]||"11111").slice(0,5).split("").map(ch=>({k:ch==="1"?1:0,c:n++}));});}
function siembra(k,ok){const fl=W.flores[k];if(fl.length>=5)return;fl.push({k:ok?1:0,c:cantidad()});const h=hoyo(k,fl.length-1);if(ok){SFX.luz();fx({t:"star",n:8,pts:[[h[0],h[1]-14]]});}else SFX.drop();return h;}
async function luzA(l,x,y,n,al){const p=luzPos(l,W.luces.indexOf(l));l.est="mov";l.x=p[0];l.y=p[1];const x0=l.x,y0=l.y;n=n||10;for(let i=1;i<=n;i++){l.x=x0+(x-x0)*i/n;l.y=y0+(y-y0)*i/n-Math.sin(Math.PI*i/n)*8;if(al!=null)l.al=1+(al-1)*i/n;await wait(TICK);}}
const acts={
  async anda(o){const L=o.a==="espera"?ESPERA[o.quien]:o.a==="detras"?DETRAS[o.cama]:[+o.x,+o.y];await mueve(o.quien,L[0],L[1]);if(o.dir)G(o.quien).dir=+o.dir;else if(o.a)G(o.quien).dir=1;},
  async burbuja(o){if(o.quien==="cq"){W.cq.bub=o.que;SFX.coqui();bounce(6);}else if(G(o.quien))G(o.quien).bub=o.que;},
  async calla(){Object.values(W.gente).forEach(p=>{if(p)p.bub=null;});W.cq.bub=null;},
  async pose(o){const p=G(o.quien);if(p)p.pose=o.que;},
  async saluda(o){const p=G(o.quien);if(!p)return;if(o.quien==="bebe"){p.est="clap";SFX.pio();}else p.pose="wave";await wait(+o.ms||700);if(o.quien==="bebe")p.est="idle";else p.pose="idle";},
  async rie(o){const p=G(o.quien);if(!p)return;p.rie=1;await wait(+o.ms||700);p.rie=0;},
  async ojos(o){const q=W.cq;q.ojos=o.on==="0"?0:1;q.ojx=+o.x||0;q.ojy=o.y==null?-1:+o.y;if(q.ojos){SFX.blip();await wait(350);}},
  /* ---- story 9: the flowers ---- */
  async inicio9(){W.gente={luis:{x:160,y:128,pose:"idle"},carmen:{x:86,y:136,pose:"idle"}};W.caja=1;W.bola={x:174,y:128};W.cq.vis=0;},
  async sale(){const q=W.cq,L=LUGAR.puerta;W.pdoor=1;SFX.creak();q.x=L[0];q.y=L[1]-14;q.s=.7;q.vis=1;await wait(250);await hopTo(L[0],L[1],1,L[2]);await acts.ir({a:"inicio"});W.pdoor=0;},
  // Luis kicks the ball up and catches it
  async juega(o){const p=G(o.quien||"luis"),b=W.bola;b.x=p.x+12;b.y=p.y;for(let k=0;k<2;k++){p.pose="wave";SFX.blip();for(let i=1;i<=8;i++){b.h=Math.sin(Math.PI*i/8)*30;await wait(TICK);}b.h=0;}p.pose="idle";},
  async maceta(o){const p=G(o.quien);p.lleva=o.suelta?null:"maceta";p.pose=o.suelta?"idle":"alto";SFX.blip();await wait(500);},
  async brilla(){W.brilla=F;SFX.luz();await wait(700);},
  // the frog takes a pot from the crate to a bed and plants it; open if it is the right bed, a shut bud if not. Then back to the crate.
  async planta(o){const k=o.cama.slice(-1),ok=o.ok!=="0";await acts.ir({a:"caja"});W.lleva="maceta";SFX.blip();await wait(200);await acts.ir({a:"cama"+k});await wait(120);W.lleva=null;siembra(k,ok);await wait(450);
    if(ok&&o.mari){W.mari.push({x:hoyo(k,W.flores[k].length-1)[0],y:CAMA[k][1]-14});}await acts.ir({a:"caja"});},
  // the sun card shows once what it is for
  async ensena(){W.tarjeta="sol";for(const k of [0,1,2,3]){W.muestra=k;if(k)SFX.drop();await wait(k?420:600);}await wait(300);W.muestra=0;SFX.luz();await wait(500);W.muestra=null;},
  // the two children left and right of the crate, hands out; which side each is on is drawn fresh
  async lados(){const s=azar()?0:1;await Promise.all([mueve("luis",LADOS[s][0],LADOS[s][1]),mueve("carmen",LADOS[1-s][0],LADOS[1-s][1])]);["luis","carmen"].forEach(id=>{G(id).pose="ojos";G(id).dir=1;});},
  async asoma(){W.pdoor=1;SFX.creak();W.gente.abuela={x:42,y:116,pose:"wave",dir:1};await wait(500);G("abuela").pose="idle";},
  async entra(){if(G("abuela")){G("abuela").vis=0;}W.pdoor=0;},
  // the frog hands a pot to a child, who plants it in the nearer bed
  async dale(o){const p=G(o.a),ok=o.ok!=="0",k=p.x<120?"L":"R",x0=p.x,y0=p.y,f=ranaXY();await acts.ir({a:"caja"});await vuelaA("maceta",f[0],f[1],p.x,p.y-24);p.lleva="maceta";SFX.blip();await wait(250);
    await mueve(o.a,DETRAS[k][0],DETRAS[k][1]);p.lleva=null;siembra(k,ok);await wait(350);if(ok){p.pose="wave";p.rie=1;await wait(600);p.rie=0;}p.pose="ojos";await mueve(o.a,x0,y0);p.dir=1;},
  async manos(){["luis","carmen"].forEach(id=>{if(G(id))G(id).pose="idle";});},
  // the children plant what is left in the crate; then the yard as the sun left it
  async final9(){const n=W.lost||0;["luis","carmen"].forEach(id=>{G(id).pose="idle";});await Promise.all([mueve("carmen",DETRAS.L[0],DETRAS.L[1]),mueve("luis",DETRAS.R[0],DETRAS.R[1])]);
    for(const k of ["L","R"])while(W.flores[k].length<5){W.flores[k].push({k:1,c:cantidad()});SFX.blip();await wait(160);}
    V.flores=W.flores.L.map(f=>f.k).join("")+"-"+W.flores.R.map(f=>f.k).join("");   // the beds as he left them, for the next stories
    await acts.ir({a:"caja"});await wait(300);
    if(!n){W.mari=[];for(let i=0;i<7;i++)W.mari.push({x:48+i*24+(i%2)*6,y:150+(i%3)*8});W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[60,150],[180,150],[120,120],[90,170],[150,170]]});await wait(1200);}
    else if(n>=3){W.luces=[{id:"medio",est:"en",x0:150,y0:150}];W.brillo=1;SFX.coqui();await wait(1200);}
    else{SFX.win();await wait(900);}},
  // the ball goes from one to the other, and then to the frog's head
  async pelota(){const l=G("luis"),ca=G("carmen"),b=W.bola,q=W.cq;await Promise.all([mueve("luis",166,150),mueve("carmen",60,150)]);l.dir=-1;ca.dir=1;b.x=l.x-12;b.y=l.y;l.pose="wave";await bolaA(ca.x+12,ca.y,7);l.pose="idle";ca.pose="wave";await bolaA(l.x-12,l.y,7);ca.pose="idle";},
  async pelota2(){const l=G("luis"),b=W.bola,f=ranaXY();l.pose="wave";await bolaA(f[0],f[1]+4,7);l.pose="idle";W.bola=null;W.lleva="bola";for(let k=0;k<3;k++){bounce(8);SFX.blip();await wait(380);}},
  /* ---- story 10: the sack ---- */
  async inicio10(){camas();W.gente={luis:{x:190,y:160,pose:"idle",sent:1,dir:1},carmen:{x:50,y:160,pose:"idle",dir:1}};W.saco={x:164,y:165,ab:0};W.canasta=[];W.nido=[];const q=W.cq,L=LUGAR.puerta;q.x=L[0];q.y=L[1];q.s=L[2];},
  // the bird flies a loop over the tree and comes back to its nest
  async aveloop(){const v=W.ave;v.mode="fly";SFX.pio();const cx=150,cy=40,r=18;W.rizo=null;for(let i=0;i<=20;i++){const an=-Math.PI/2+Math.PI*2*i/20+1.2;v.x=cx+r*Math.cos(an);v.y=cy+r*Math.sin(an);v.dir=Math.sin(an)<0?1:-1;await wait(TICK);}W.rizo={x:cx,y:cy,r};await KIT.aveVa(181,66,7,-1);},
  async avecabeza(){W.rizo=null;const f=ranaXY();await KIT.aveVa(f[0],f[1]-2,8);W.ave.mode="head";W.ave.st="feliz";SFX.pio();await wait(900);},
  async avenido(){W.ave.st="n";W.ave.lleva=null;await KIT.aveVa(181,66,8,-1);},
  async acaricia(o){const p=G(o.quien||"carmen");mira(o.quien||"carmen");p.pose="offer";p.dir=-p.dir;p.bub="amor";SFX.blip();await wait(900);p.bub=null;p.pose="idle";},
  // Luis pulls a thing out of the sack and holds it up
  async saca(o){const p=G("luis");W.saco.ab=1;SFX.blip();await wait(250);p.dir=1;p.lleva=o.que;p.pose="alto";W.saco.ab=0;fx({t:"star",n:6,pts:[[R(p.x)+14,R(p.y)-58]]});await wait(400);},
  // what Luis holds goes to Carmen's hair, or into the frog's basket
  async alpelo(){const p=G("luis"),ca=G("carmen");if(!p.lleva)return;p.lleva=null;p.pose="idle";await vuelaA("flor",p.x+14,p.y-50,ca.x+5,ca.y-40);ca.pelo=1;SFX.luz();await wait(400);},
  async alcanasta(o){const de=o.de||"luis",p=G(de),f=ranaXY();
    if(de==="cq"){if(!W.lleva)return;const k=W.lleva;await wait(200);W.lleva=null;W.canasta.push(k);SFX.luz();fx({t:"star",n:8,pts:[[f[0]+12,f[1]+12]]});await wait(500);return;}
    if(!p||!p.lleva)return;const k=p.lleva;p.lleva=null;p.encima=null;p.pose="idle";await vuelaA(k,p.x,p.y-40,f[0]+12,f[1]+12);W.canasta.push(k);SFX.luz();fx({t:"star",n:8,pts:[[f[0]+12,f[1]+12]]});await wait(500);},
  // the frog's turn at the sack: he pulls something out and does not know what it is
  async turno(o){const q=W.cq;W.saco.ab=1;await acts.ir({a:"luis"});SFX.blip();await wait(300);W.lleva=o.que;W.saco.ab=0;bounce(5);await wait(300);q.bub="q";SFX.coqui();await wait(1000);q.bub=null;},
  async quita(){W.cq.bub=null;},
  // the frog hands what he holds to Carmen
  async acarmen(){const ca=G("carmen"),f=ranaXY(),k=W.lleva;if(!k)return;W.lleva=null;await vuelaA(k,f[0],f[1],ca.x,ca.y-24);ca.lleva=k;ca.pose="ojos";SFX.blip();await wait(300);},
  // the bird comes down and pulls at the sack; from now on the two scores show
  async avepica(){await KIT.aveVa(W.saco.x-2,W.saco.y-20,9,1);for(let k=0;k<3;k++){W.ave.dip=3;SFX.pio();W.saco.x+=1;await wait(170);W.ave.dip=0;W.saco.x-=1;await wait(170);}},
  async marcador(){W.tanteo=1;SFX.luz();await wait(600);},
  // decision A: Carmen across the yard with the glass; the frog back at the door
  async prepA(){const ca=G("carmen");await Promise.all([mueve("carmen",150,140),acts.ir({a:"puerta"})]);ca.dir=-1;ca.pose="ojos";if(!ca.lleva)ca.lleva="vaso";await wait(200);},
  // she said ven and he came: the glass goes in his basket (or her hands are empty, and she laughs)
  async llega(){const ca=G("carmen");await acts.ir({a:"carmenA"});if(ca.lleva)await acts.alcanasta({de:"carmen"});else{ca.pose="ojos";await acts.rie({quien:"carmen"});ca.pose="idle";}},
  // she said mira and he looked: she spins with the glass on her head, bows, and brings it over
  async gira(){const ca=G("carmen"),k=ca.lleva;W.cq.ojos=1;W.cq.ojx=1;W.cq.ojy=0;ca.lleva=null;ca.encima=k;ca.pose="idle";for(let i=0;i<8;i++){ca.dir=-ca.dir;SFX.blip();await wait(130);}ca.dir=-1;fx({t:"star",n:10,pts:[[R(ca.x),R(ca.y)-54]]});ca.rie=1;await wait(500);ca.rie=0;
    W.cq.ojos=0;if(k){ca.encima=null;ca.lleva=k;ca.pose="ojos";const b=frogBox(W.cq);if(Math.abs(b.x+b.w/2-ca.x)>40)await mueve("carmen",b.x+b.w+16,b.y+b.h+2);await acts.alcanasta({de:"carmen"});}},
  // wrong: he only looked. She waits, arm out; the bird takes the glass.
  async mirasolo(){const ca=G("carmen");W.cq.ojos=1;W.cq.ojx=1;W.cq.ojy=0;ca.pose="offer";ca.dir=1;await wait(900);await acts.roba({de:"carmen"});W.cq.ojos=0;ca.pose="idle";ca.dir=-1;},
  // wrong: he hopped over as she began her spin. A bump; the glass flies up; the bird catches it.
  async choca(){const ca=G("carmen"),k=ca.lleva;ca.lleva=null;ca.encima=k;ca.pose="idle";ca.dir=1;await acts.ir({a:"carmenA"});SFX.bonk();ca.rie=1;bounce(5);ca.encima=null;
    W.vuela={k,x:ca.x,y:ca.y-50,s:1.4};const fly=(async()=>{for(let i=1;i<=6;i++){W.vuela.y=ca.y-50-i*5;await wait(TICK);}})();await Promise.all([fly,KIT.aveVa(ca.x,ca.y-84,7)]);W.vuela=null;ca.rie=0;W.ave.lleva=k;SFX.pio();await wait(250);await acts.alnido();ca.dir=-1;},
  // the bird snatches what someone holds and takes it to its nest
  async roba(o){const de=o.de,p=de==="cq"?null:G(de),f=ranaXY(),k=p?p.lleva:W.lleva;if(!k)return;const at=p?[p.x+(p.pose==="alto"?(p.dir<0?-14:14):p.pose==="offer"?-(p.dir<0?-1:1)*20:0),p.y-(p.pose==="alto"?alto(de):alto(de)-24)]:[f[0],f[1]-8];
    await KIT.aveVa(at[0],at[1],8);if(p){p.lleva=null;if(p.pose==="alto")p.pose="idle";}else W.lleva=null;W.ave.lleva=k;SFX.pio();await wait(200);await acts.alnido();},
  async alnido(){const k=W.ave.lleva;await KIT.aveVa(181,66,9,-1);W.ave.lleva=null;if(k)W.nido.push(k);SFX.drop();await wait(300);},
  async encoge(o){const p=G(o.quien||"luis");p.bub="q";await wait(800);p.bub=null;},
  async final10(){const mio=W.canasta.length,f=ranaXY();W.saco.ab=0;G("luis").pose="idle";G("luis").lleva=null;
    if(mio>=3){W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[60,40],[150,44],[104,30],[80,60],[130,56]]});await wait(1000);}else if(mio){SFX.win();await wait(700);}else{SFX.coqui();await wait(700);}
    const k=W.nido.length?W.nido.pop():"flor";W.ave.lleva=k;W.ave.st="feliz";await KIT.aveVa(f[0]+14,f[1]-6,10);W.ave.lleva=null;W.canasta.push(k);SFX.luz();fx({t:"star",n:8,pts:[[f[0]+12,f[1]+12]]});await wait(500);await KIT.aveVa(f[0],f[1]-2,4);W.ave.mode="head";await wait(500);},
  /* ---- story 11: going home ---- */
  async inicio11(){camas();W.gente={abuela:{x:34,y:136,pose:"idle",dir:1},abuelo:{x:60,y:126,pose:"ojos",lleva:"bizcocho",dir:1},mama:{x:86,y:136,pose:"idle"},bebe:{x:97,y:109,z:137,est:"idle"},papa:{x:112,y:126,pose:"idle"},
      luis:{x:150,y:190,pose:"idle",dir:-1},carmen:{x:186,y:178,pose:"alto",dir:-1}};W.pdoor=1;W.sol=3;W.soly=SOLY[3];W.osc=.12;W.ave={mode:"sit",x:178,y:83,dir:-1,st:"n"};
    W.luces=[{id:"carmen",est:"en"},{id:"abuelo",est:"en"},{id:"medio",est:"en",x0:120,y0:156}];},
  async puesta(){for(let i=0;i<=12;i++){W.soly=SOLY[3]+i*3;W.osc=.12+.015*i;await wait(TICK);}W.estrella=1;SFX.luz();await wait(600);},
  // two go to the gate together, side by side
  async juntos(o){const id=o.quien||"luis",p=G(id);p.pose="idle";await Promise.all([mueve(id,170,124),acts.ir({a:"porton"})]);p.dir=-1;},
  async vuelveluis(){await mueve("luis",138,138);G("luis").dir=1;},
  async alcentro(o){const p=G(o.quien);await Promise.all([mueve(o.quien,+o.x||160,+o.y||190),acts.ir({a:"centro"})]);p.dir=-1;},
  async junto(o){const p=G(o.quien),b=frogBox(W.cq);await mueve(o.quien,b.x+b.w+14,b.y+b.h+2);p.dir=-1;},
  async oscurece(){for(let i=0;i<=10;i++){W.osc=.3+.03*i;await wait(TICK);}W.noche=1;W.brillo=1;SFX.luz();await wait(300);W.tarjeta="luces";await wait(500);},
  // someone comes up to the frog for a goodbye: Carmen from the right, abuelo from the left
  async viene(o){if(o.quien==="carmen"){await mueve("carmen",186,174);G("carmen").dir=-1;G("carmen").pose="alto";}else{await mueve("abuelo",52,174);G("abuelo").dir=1;G("abuelo").pose="ojos";}},
  // that one's firefly comes to the frog, for good (if it has not gone)
  async luz(o){const l=W.luces.find(x=>x.id===o.cual);if(!l||l.est!=="en")return;const f=ranaXY();await luzA(l,f[0]+12,f[1]-8,10);l.est="con";SFX.luz();fx({t:"star",n:6,pts:[[f[0]+12,f[1]-8]]});await wait(350);},
  async toma(){const p=G("abuelo"),f=ranaXY();if(p.lleva){const k=p.lleva;p.lleva=null;p.pose="idle";await vuelaA(k,p.x,p.y-24,f[0],f[1]-2);W.lleva=k;SFX.blip();await wait(400);}},
  async guarda(){W.lleva=null;},
  async duda(o){const p=o.quien==="cq"?W.cq:G(o.quien);p.bub="q";if(o.quien==="cq")SFX.coqui();await wait(700);p.bub=null;},
  async abrazo(){const p=G("luis");p.pose="offer";p.dir=1;W.cq.bub="amor";SFX.coqui();bounce(5);await wait(800);W.cq.bub=null;p.pose="idle";},
  async luiscorre(){await mueve("luis",170,124,8);G("luis").dir=-1;},
  async abre(){const p=G("luis");p.pose="offer";p.dir=1;await wait(250);W.porton=1;SFX.creak();await wait(500);p.pose="idle";},
  async adios(){["abuela","abuelo","mama","papa","carmen","luis"].forEach(id=>{const p=G(id);if(p){p.pose="wave";p.lleva=null;}});G("bebe").est="clap";SFX.pio();await wait(300);},
  // by the fireflies he has; then he sings and they blink back; with none, one comes out of the dark
  async final11(){const con=W.luces.filter(l=>l.est==="con").length;
    if(con>=3){W.aro=1;W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[110,70],[170,66],[140,56],[124,96],[160,96]]});await wait(1100);}else if(con){SFX.win();await wait(700);}else await wait(700);
    SFX.coqui();bounce(7);await wait(700);
    if(con){for(let k=0;k<3;k++){W.brillo=0;W.luces.forEach(l=>{if(l.est==="con")l.al=.3;});await wait(150);W.luces.forEach(l=>{l.al=1;});await wait(200);}W.brillo=1;}
    else{const l={id:"nueva",est:"mov",x:214,y:120,al:0};W.luces.push(l);const f=ranaXY();await luzA(l,f[0]+12,f[1]-8,14,1);l.est="con";SFX.luz();fx({t:"star",n:6,pts:[[f[0]+12,f[1]-8]]});await wait(500);}},
  // out through the gate, the bird beside him
  async sevan(){const q=W.cq,L=LUGAR.sale;W.ave.mode="fly";const av=(async()=>{await KIT.aveA(150,70,10);})();await hopTo(L[0],L[1],3,L[2]);await av;for(let i=1;i<=6;i++){q.al=1-i/6;W.luces.forEach(l=>{if(l.est==="con")l.al=1-i/8;});await wait(TICK);}q.vis=0;W.luces.forEach(l=>{if(l.est==="con")l.al=0;});W.ave.mode="none";await wait(500);tone(1500,0,.11,"sine",.04);tone(2300,.17,.2,"sine",.04,2750);await wait(900);},
};
// the thing at stake takes a step
async function stake(lost,max,en){const t=S.stake.thing;
  if(t==="sol"){const y0=W.soly,y1=SOLY[Math.min(3,lost)];SFX.drop();for(let i=1;i<=10;i++){W.soly=y0+(y1-y0)*i/10;await wait(TICK);}W.sol=Math.min(3,lost);tone(300,0,.25,"triangle",.07,150);await wait(500);return;}
  if(t==="luces"){const l=W.luces.find(x=>x.id===en);if(l&&l.est==="en"){SFX.drop();await luzA(l,226,58,14,0);l.est="ido";}await wait(300);return;}
  SFX.bonk();await wait(300);}
function poke(what){const p=W.gente&&W.gente[what];if(p&&!p.bub){p.bub="amor";const my=runId;setTimeout(()=>{if(my===runId&&p.bub==="amor")p.bub=null;},1400/FAST);}}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k]&&W.gente[k].vis!==0).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)+(W.gente[k].lleva?"("+W.gente[k].lleva+")":"")+(W.gente[k].bub?"["+W.gente[k].bub+"]":"")).join(" ")+
  " flores=L"+(W.flores.L.map(f=>f.k).join(""))+" R"+(W.flores.R.map(f=>f.k).join(""))+" sol="+W.sol+" lleva="+(W.lleva||"-")+" canasta="+(W.canasta?W.canasta.join("+"):"-")+" nido="+(W.nido||[]).join("+")+" luces="+(W.luces||[]).map(l=>l.id+":"+l.est).join(",")+" porton="+W.porton+" ojos="+(W.cq.ojos||0);
KIT.escena({id:"patio",CAM:{wide:[22,0,196,216]},heartAt:[118,36],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({gente:{},flores:{L:[],R:[]},sol:0,soly:SOLY[0],osc:0,noche:0,luna:0,estrella:0,porton:0,pdoor:0,caja:0,bola:null,saco:null,canasta:null,nido:[],tanteo:0,tarjeta:null,muestra:null,luces:[],brillo:0,aro:0,mari:[],lleva:null,vuela:null,
    polvo:null,rizo:null,brilla:0,ave:{mode:"sit",x:181,y:66,dir:-1,st:"n"},cq:{x:LUGAR.centro[0],y:LUGAR.centro[1],s:1,dy:0,al:1,vis:1,bub:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
window.PATIO={LUGAR,DETRAS,CAMA,hoyo};
})();
