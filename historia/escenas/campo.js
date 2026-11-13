"use strict";
/* ============================================================
   Coquí · scene "El campo": the open field in the park (place 2, El parque).
   Flat grass. On the left one tree with a low fork; under it a worn
   patch of earth, Canelo's spot. On the right the ground drops to the
   pond: reeds, and water in the bottom right corner.
   People live in W.gente, the dog in W.perro: {x,y (feet), pose, dir, vis}.
   Balls live in W.bolas, by name: {k (which ball), x,y (where it rests
   on the ground), z (how high it is in the air), con (who carries it:
   a person, "cq" or "perro"), vis}. Every story set here uses this drawing.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,FAM=KIT.FAM,R=Math.round;
const QUIEN={luis:FAM.hermano,carmen:FAM.hermana},mkPerro=KIT.mkPerro,mkCesta=KIT.mkCesta,mano=KIT.mano,tarjeta=KIT.tarjeta;
const ARBOL=[60,152],COPA=[60,100,30,26],HORQ=[64,116],SITIO=[46,168];          // the tree's foot, its crown, the fork where a ball sticks, Canelo's spot
const AGUA=[232,228,74,54],JUNCOS=[[170,201],[184,190],[198,182],[211,177]];   // the pond (an ellipse off the corner) and the reeds along its edge
const enAgua=(x,y)=>{const dx=(x-AGUA[0])/AGUA[2],dy=(y-AGUA[1])/AGUA[3];return dx*dx+dy*dy<1;};

/* ---------- the picture ---------- */
function fondo(){const b=new Buf(SW,SH),G=RP.grn,Wd=RP.wood,Bl=RP.blue;
  sky(b,SW,100);grass(b,100,SW,SH);
  // the ground drops toward the pond: darker grass, then the bank, then water
  for(let y=120;y<SH;y++)for(let x=120;x<SW;x++){const dx=(x-AGUA[0])/AGUA[2],dy=(y-AGUA[1])/AGUA[3],d=Math.sqrt(dx*dx+dy*dy);
    if(d<1){const w=hs(x>>1,y)<14?Bl[4]:(y+(x>>2))%7===0?Bl[3]:Bl[2];b.px(x,y,d>.94?Bl[1]:w);}
    else if(d<1.07)b.px(x,y,hs(x,y)<40?"#C8A468":"#B08A54");
    else if(d<1.45){const t=(1.45-d)/.38;if(hs(x,y)<t*70)b.px(x,y,G[1]);else if(hs(x+7,y)<t*40)b.px(x,y,G[0]);}}
  // Canelo's spot: a worn patch of earth under the tree
  b.ell(SITIO[0],SITIO[1],15,5,["#B08A54","#C8A468","#D8B67A"]);
  // the tree: a trunk with a low fork, a round crown
  b.grad(ARBOL[0]-5,ARBOL[1]-40,10,41,[Wd[2],Wd[1],Wd[1],Wd[0]],true);b.rect(ARBOL[0]-6,ARBOL[1]-40,1,41,OUT);b.rect(ARBOL[0]+5,ARBOL[1]-40,1,41,OUT);b.rect(ARBOL[0]-9,ARBOL[1]-1,18,3,Wd[1]);b.frame(ARBOL[0]-10,ARBOL[1]-2,20,5,OUT);
  b.cap(ARBOL[0]-2,ARBOL[1]-34,ARBOL[0]-13,ARBOL[1]-50,2.6,[Wd[1]]);b.cap(ARBOL[0]+2,ARBOL[1]-34,ARBOL[0]+14,ARBOL[1]-50,2.6,[Wd[1]]);
  b.ell(COPA[0],COPA[1],COPA[2]+1,COPA[3]+1,[OUT]);b.ell(COPA[0],COPA[1],COPA[2],COPA[3],G);b.ell(COPA[0]-10,COPA[1]-9,11,7,[G[3],G[4]]);b.ell(COPA[0]+12,COPA[1]+6,9,6,[G[1],G[2]]);
  // the fork shows through the leaves: a dark hollow where a ball can sit
  b.ell(HORQ[0],HORQ[1]+2,7,4,[G[0],G[1]]);
  // reeds along the water
  JUNCOS.forEach((p,i)=>{for(let k=-2;k<=2;k++){const h=12+((i*3+k*5)&7),x=p[0]+k*3;b.rect(x,p[1]-h,1,h,k%2?G[1]:G[0]);if((i+k)%2===0){b.rect(x-1,p[1]-h-4,3,5,"#6E4220");b.px(x,p[1]-h-5,"#6E4220");}}});
  return b.done();}

/* ---------- the balls: told apart by size and pattern ---------- */
const BOLA={L:{r:7,c:["#B03A2E","#D8574A","#F08A7C"],m:"rayas"},C:{r:5.5,c:["#2E6CD0","#5A9AEA","#A8CCF8"],m:"puntos"},q:{r:4,c:["#C89A1C","#F0C83C","#FFE98C"],m:"estrella"}};
function mkBola(k){const d=BOLA[k],r=d.r,n=Math.ceil(r*2+3),b=new Buf(n,n),c=n/2;b.ell(c,c,r,r,d.c);
  if(d.m==="rayas"){for(let y=0;y<n;y++)for(let x=0;x<n;x++){const dx=x+.5-c,dy=y+.5-c;if(dx*dx+dy*dy<r*r-1&&((x+y)%6)<2)b.px(x,y,"#FFF4E0");}}
  else if(d.m==="puntos"){[[c-2.5,c-2],[c+2,c-1],[c-1,c+2.5],[c+2.5,c+3]].forEach(p=>b.rect(R(p[0]),R(p[1]),2,2,"#FFFFFF"));}
  else{b.rect(R(c)-1,R(c)-2,2,4,"#7A4A10");b.rect(R(c)-2,R(c)-1,4,2,"#7A4A10");}
  return b.outline().done();}
const radio=k=>BOLA[k].r;

const LUGAR={centro:[104,150,1],inicio:[104,150,1]};
const alto=id=>QUIEN[id].nino?44:56;
const caja=id=>{const p=W.gente[id];return p&&p.vis!==0?[R(p.x)-11,R(p.y)-alto(id),22,alto(id)]:null;};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id];
// where a ball is drawn: in somebody's hands, in the dog's mouth, or where it lies (z = how high it is in the air)
function bolaXY(o){const r=radio(o.k);
  if(o.con==="cq"){const b=frogBox(W.cq);return [b.x+(b.w>>1),b.y+R(W.cq.dy)+b.h-3,0];}
  if(o.con==="perro"&&W.perro){const p=W.perro;return [R(p.x)+(p.dir<0?-13:13),R(p.y)-5+(p.dy||0),0];}
  if(o.con&&G(o.con)){const p=G(o.con),h=alto(o.con),up=p.pose==="arriba"?-20:p.pose==="offer"?6:0;return [R(p.x)+(p.dir<0?-1:1)*(p.pose==="offer"?10:5),R(p.y)-h+30+up,0];}
  return [R(o.x),R(o.y),R(o.z||0)];}
const COSAS=["luis","carmen"].map(persona).concat([
  {id:"perro",si:w=>!!w.perro&&w.perro.vis!==0,box:w=>[R(w.perro.x)-14,R(w.perro.y)-20,28,22],m:2},
  {id:"arbol",box:[COPA[0]-COPA[2],COPA[1]-COPA[3],COPA[2]*2,COPA[3]*2+24],hand:[COPA[0],COPA[1]],m:0},
  {id:"agua",box:[164,172,56,44],hand:[190,192],m:0},
  {id:"campo",box:[0,100,240,116],m:0}]);

/* ---------- drawing ---------- */
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1;
  const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="arriba"?"wave0":(p.pose||"idle"),im=spr("pc"+id+pose+habla,()=>KIT.mkPersona(QUIEN[id],pose,habla,0));
  c.save();c.translate(x,y-im.height+1+((p.paso&&a%2)||(p.rie&&a%2)?-1:0)-(p.dy||0));if(p.corre){c.translate(0,im.height);c.rotate(.26*d);c.translate(0,-im.height);}if(d<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();}
function perro(c,a){const o=W.perro;if(!o||o.vis===0)return;const mueve=o.pose==="walk"||o.pose==="run"||o.pose==="bark"||o.pose==="eat"||o.pose==="husmea",f=mueve?(a>>(o.pose==="run"?0:1))%2:0,im=spr("pe"+o.pose+f,()=>mkPerro(o.pose,f)),d=o.dir<0?-1:1,sx=o.sacude?((F%2)?1:-1):0;
  c.save();c.translate(R(o.x)+sx,R(o.y)-im.height+2-(o.dy||0));if(d<0)c.scale(-1,1);c.drawImage(im,-13,0);c.restore();
  if(o.mojado){for(let i=0;i<3;i++){const dx=((F>>1)+i*7)%20-10;fr(c,R(o.x)+dx,R(o.y)-4+((F+i*3)%5),1,2,"#5A9AEA");}}                       // he drips
  if(o.sacude){for(let i=0;i<10;i++){const t=((F*3+i*11)%16),an=i*.63;fr(c,R(o.x)+R(Math.cos(an)*(6+t*1.4)),R(o.y)-10+R(Math.sin(an)*(4+t)),2,2,i%2?"#5A9AEA":"#A8CCF8");}}   // he shakes himself: water everywhere
  if(o.bub)bub2(c,o.bub,R(o.x),R(o.y)-22,a);}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui")&&a%2?1:0,dy=R(q.dy);
  for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5-(j===1?0:2);i++)if((i+j)%2===0)fr(g,b.x+2+i,q.y+25+j,1,1,"#2E8A34");
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function unaBola(c,o){if(!o||o.vis===0)return;const p=bolaXY(o),r=radio(o.k),im=spr("bola"+o.k,()=>mkBola(o.k));
  if(p[2]>2){c.globalAlpha=.25;fr(c,p[0]-R(r)+1,p[1]-1,R(r*2)-2,2,"#103010");c.globalAlpha=1;}   // its shadow, when it is in the air
  c.drawImage(im,p[0]-(im.width>>1),p[1]-p[2]-im.height+1);}
function draw(c,W,a){const q=W.cq,Gt=W.gente||{},B=W.bolas||{};
  c.drawImage(spr("campo",fondo),0,0);
  const L=[];
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.y,d:()=>gente(c,id,a)});});
  if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>perro(c,a)});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  if(W.cesta)L.push({y:W.cesta[1],d:()=>c.drawImage(spr("cesta",mkCesta),W.cesta[0]-10,W.cesta[1]-11)});
  Object.keys(B).forEach(k=>{const o=B[k];if(!o||o.vis===0)return;const p=bolaXY(o),y=o.con==='cq'?q.y+27.5:o.con==='perro'&&W.perro?W.perro.y+.5:o.con&&Gt[o.con]?Gt[o.con].y+.5:p[1]+.5;L.push({y,d:()=>unaBola(c,o)});});   // a ball in somebody's hands is drawn in front of them
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.bub?38:0)];}
function respIcon(g,k,x,y,w,h,a){}
function hud(g,W,a){}

const acts={
  async inicio15(){W.gente={luis:{x:92,y:176,pose:"idle",dir:1},carmen:{x:184,y:152,pose:"idle",dir:-1}};W.perro={x:SITIO[0],y:SITIO[1]+2,pose:"sit",dir:1};
    Object.assign(W.cq,{x:118,y:158,s:1});W.cesta=[160,200];
    W.bolas={luis:{k:"L",con:"luis"},carmen:{k:"C",con:"carmen"},cq:{k:"q",x:126,y:196},arbol:{k:"L",x:HORQ[0],y:HORQ[1]+3},agua:{k:"C",x:196,y:200},e1:{k:"q",x:154,y:192},e2:{k:"q",x:160,y:191},e3:{k:"q",x:166,y:192}};},
};
async function stake(lost,max,en){SFX.bonk();await wait(300);}
function poke(what){}
const estado=W=>"gente="+Object.keys(W.gente||{}).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)).join(" ");
KIT.escena({id:"campo",CAM:{wide:[22,0,196,216]},heartAt:[110,30],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({gente:{},perro:null,bolas:{},cesta:null,tarjeta:null,cq:{x:LUGAR.inicio[0],y:LUGAR.inicio[1],s:1,dy:0,al:1,vis:1,bub:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
