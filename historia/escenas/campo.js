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
const BOLA={L:{r:7,c:["#B03A2E","#D8574A","#F08A7C"],m:"rayas"},C:{r:5.5,c:["#2E6CD0","#5A9AEA","#A8CCF8"],m:"puntos"},q:{r:5,c:["#D8A414","#F4CC30","#FFE878"],m:"linea"}};
function mkBola(k){const d=BOLA[k],r=d.r,n=Math.ceil(r*2+3),b=new Buf(n,n),c=n/2;b.ell(c,c,r,r,d.c);
  if(d.m==="rayas"){for(let y=0;y<n;y++)for(let x=0;x<n;x++){const dx=x+.5-c,dy=y+.5-c;if(dx*dx+dy*dy<r*r-1&&((x+y)%6)<2)b.px(x,y,"#FFF4E0");}}
  else if(d.m==="puntos"){[[c-2.5,c-2],[c+2,c-1],[c-1,c+2.5],[c+2.5,c+3]].forEach(p=>b.rect(R(p[0]),R(p[1]),2,2,"#FFFFFF"));}
  else{[[-4,1],[-3,0],[-2,-1],[-1,-1],[0,-1],[1,0],[2,1],[3,1]].forEach(d=>b.px(R(c)+d[0],R(c)+d[1],"#FFFFFF"));b.px(R(c)-2,R(c)-3,"#FFFFFF");}   // a white line, like a tennis ball
  return b.outline().done();}
const radio=k=>BOLA[k].r;

const LUGAR={centro:[120,150,1],inicio:[120,150,1]};
const CASA={luis:[88,178],carmen:[186,154]},PIES=[136,196],CESTA=[104,208],PILA=[[40,173],[52,174],[46,169],[46,177]];   // where the children stand, where the frog's ball lies, the basket, Canelo's pile
const FILA=[[112,194],[128,195],[144,194]],ORILLA=[190,198],JUNCO=[180,197];                                                // story 17's row of balls; the water's edge; where a ball hides in the reeds
const alto=id=>QUIEN[id].nino?44:56;
const caja=id=>{const p=W.gente[id];return p&&p.vis!==0?[R(p.x)-11,R(p.y)-alto(id),22,alto(id)]:null;};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const G=id=>W.gente[id],B=n=>W.bolas[n];
// where a ball is: [x, the ground under it, how high it is]. In somebody's hands, in the dog's mouth, or where it lies.
function manos(k){
  if(k==="cq"){const b=frogBox(W.cq);return [b.x+(b.w>>1),W.cq.y+28,3-R(W.cq.dy)];}
  if(k==="perro"){const p=W.perro;return [R(p.x)+(p.dir<0?-13:13),R(p.y)+1,5+(p.dy||0)];}
  const p=G(k),h=alto(k),d=p.dir<0?-1:1;return [R(p.x)+d*(p.pose==="offer"?11:p.pose==="arriba"?4:6),R(p.y)+1,(p.pose==="arriba"?h+2:p.pose==="offer"?h-27:h-24)+(p.dy||0)];}
function bolaXY(o){if(o.con)return manos(o.con);return [R(o.x),R(o.y),R(o.z||0)];}
const cajaBola=n=>w=>{const o=(w.bolas||{})[n];if(!o||o.vis===0)return null;const p=bolaXY(o),r=radio(o.k);return [p[0]-r-2,p[1]-p[2]-2*r-2,2*r+4,2*r+4];};
const bolaCosa=n=>({id:"bola_"+n,z:1,m:3,si:w=>!!(w.bolas&&w.bolas[n]&&w.bolas[n].vis!==0),box:cajaBola(n)});
const COSAS=["luis","carmen"].map(persona).concat(["luis","carmen","cq"].map(bolaCosa),[
  {id:"perro",si:w=>!!w.perro&&w.perro.vis!==0,box:w=>[R(w.perro.x)-14,R(w.perro.y)-20,28,22],m:2},
  {id:"cesta",si:w=>!!w.cesta,box:w=>[w.cesta[0]-11,w.cesta[1]-16,22,18],m:1},
  {id:"arbol",box:[COPA[0]-COPA[2],COPA[1]-COPA[3],COPA[2]*2,COPA[3]*2+26],hand:[COPA[0],COPA[1]],m:0},
  {id:"juncos",box:[160,168,60,48],hand:[188,190],m:0},
  {id:"campo",box:[0,100,240,116],m:0}]);

/* ---------- drawing ---------- */
function gotas(c,x,y,w,h,n){for(let i=0;i<n;i++){const dx=hs(i*7,3)%w,t=(F+i*5)%12;fr(c,x+dx,y+((hs(i*3,9)%h)+t)%h,1,2,i%2?"#5A9AEA":"#A8CCF8");}}
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const x=R(p.x),y=R(p.y),habla=TALK===id&&a%2?1:0,d=p.dir<0?-1:1,h=alto(id);
  const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="arriba"?"wave0":p.pose==="atras"?"idle":(p.pose||"idle"),im=spr("pc"+id+pose+habla,()=>KIT.mkPersona(QUIEN[id],pose,habla,0));
  c.save();c.translate(x,y-im.height+1+((p.paso&&a%2)||(p.rie&&a%2)?-1:0)-(p.dy||0));if(p.corre){c.translate(0,im.height);c.rotate(.26*d);c.translate(0,-im.height);}if((pose==="offer"?-d:d)<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();   // the kit draws the offering arm on the other side: turn it to the side he faces
  if(p.ojos){fr(c,x-7,y-h+9-(p.dy||0),14,4,QUIEN[id].piel[2]);fr(c,x-7,y-h+8-(p.dy||0),14,1,OUT);fr(c,x-7,y-h+13-(p.dy||0),14,1,OUT);}   // an arm across his eyes
  if(p.mojado)gotas(c,x-9,y-h+4,18,h-6,6);}
function perro(c,a){const o=W.perro;if(!o||o.vis===0)return;const anda=o.pose==="walk"||o.pose==="run"||o.pose==="bark"||o.pose==="eat"||o.pose==="husmea",f=anda?(a>>(o.pose==="run"?0:1))%2:0,im=spr("pe"+o.pose+f,()=>mkPerro(o.pose,f)),d=o.dir<0?-1:1,sx=o.sacude?((F%2)?1:-1):0;
  if((o.dy||0)>3){c.globalAlpha=.3;fr(c,R(o.x)-9,R(o.y),18,2,"#103010");c.globalAlpha=1;}   // his shadow, when he is in the air
  c.save();c.translate(R(o.x)+sx,R(o.y)-im.height+2-(o.dy||0));if(d<0)c.scale(-1,1);c.drawImage(im,-13,0);c.restore();
  if(o.polvo){for(let i=0;i<3;i++){fr(c,R(o.x)-d*(16+i*6)-2,R(o.y)-3-i%2*3,4,3,"#FFFFFF");fr(c,R(o.x)-d*(16+i*6)-1,R(o.y)-2-i%2*3,3,2,"#E8E0C8");}}   // dust behind him: he runs
  if(o.mojado)gotas(c,R(o.x)-11,R(o.y)-12,22,12,4);                                                                              // he drips
  if(o.sacude){for(let i=0;i<14;i++){const t=((F*3+i*11)%18),an=i*.45;fr(c,R(o.x)+R(Math.cos(an)*(6+t*1.6)),R(o.y)-10+R(Math.sin(an)*(4+t*1.1)),2,2,i%2?"#5A9AEA":"#A8CCF8");}}   // he shakes himself: water everywhere
  if(o.bub)bub2(c,o.bub,R(o.x),R(o.y)-22,a);}
function rana(g,q,a){const b=frogBox(q),bl=(W.cierra||(F%47)<2)?1:0,op=(q.bub==="hola"||TALK==="coqui")&&a%2?1:0,dy=R(q.dy);
  for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5-(j===1?0:2);i++)if((i+j)%2===0)fr(g,b.x+2+i,q.y+25+j,1,1,"#2E8A34");
  if(W.mojado>0){const rx=[0,b.w/2-3,b.w/2+6,b.w/2+18][W.mojado],ry=[0,2.5,4,6][W.mojado];g.fillStyle="#2E6CD0";g.beginPath();g.ellipse(b.x+b.w/2,q.y+28,rx+1,ry+1,0,0,7);g.fill();g.fillStyle="#5A9AEA";g.beginPath();g.ellipse(b.x+b.w/2,q.y+28,rx,ry,0,0,7);g.fill();g.fillStyle="#A8CCF8";g.fillRect(b.x+4,q.y+27,6,1);}   // the wetter he is, the wider the puddle he stands in
  g.globalAlpha=q.al;g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+dy);g.globalAlpha=1;
  if(W.mojado)gotas(g,b.x+2,b.y+dy+2,b.w-4,b.h,W.mojado*5);}
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function unaBola(c,o){const p=bolaXY(o),r=radio(o.k),im=spr("bola"+o.k,()=>mkBola(o.k));
  if(o.flota){const y=p[1]+((F>>3)%2);c.drawImage(im,0,0,im.width,im.height-R(r*.7),p[0]-(im.width>>1),y-im.height+R(r*.7),im.width,im.height-R(r*.7));fr(c,p[0]-R(r)-2,y,2*R(r)+4,1,"#A8CCF8");return;}   // in the pond: half under
  if(p[2]>3&&!o.con){c.globalAlpha=.3;fr(c,p[0]-R(r)+1,p[1]-1,R(r*2)-2,2,"#103010");c.globalAlpha=1;}   // its shadow, when it is in the air
  c.drawImage(im,p[0]-(im.width>>1),p[1]-p[2]-im.height+1);
  if(o.vuela){const v=o.vuela,ver=Math.abs(v[1])>Math.abs(v[0]);for(let i=1;i<=3;i++){const tx=p[0]-v[0]*(r+2+i*4),ty=p[1]-p[2]-R(r)-v[1]*(r+2+i*4);if(ver){fr(c,tx-1,ty-2,3,5,"#2E6CD0");fr(c,tx,ty-1,1,3,"#FFFFFF");}else{fr(c,tx-2,ty-1,5,3,"#2E6CD0");fr(c,tx-1,ty,3,1,"#FFFFFF");}}}}   // lines behind a ball in flight
function draw(c,W,a){const q=W.cq,Gt=W.gente||{},Bs=W.bolas||{};
  c.drawImage(spr("campo",fondo),0,0);
  if(W.tiembla){const t=F-W.tiembla.f;if(t<14)(W.tiembla.en==="arbol"?[[-26,-10],[24,-14],[-18,14],[22,10],[0,-28]]:[[-14,-8],[10,-14],[20,-4],[-4,-18]]).forEach((d,k)=>{const o=W.tiembla.en==="arbol"?[COPA[0],COPA[1]]:[190,186];fr(c,o[0]+d[0]+((F+k)%2)*2,o[1]+d[1],3,2,RP.grn[4]);});}
  (W.salpica||[]).forEach(e=>{const t=F-e.f;if(t<10)for(let i=0;i<7;i++){const an=Math.PI+i*Math.PI/6;fr(c,e.x+R(Math.cos(an)*(3+t*1.2)),e.y+R(Math.sin(an)*(2+t*1.4))+R(t*t*.12),2,2,i%2?"#A8CCF8":"#FFFFFF");}});
  const L=[];
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.vis!==0)L.push({y:p.y,d:()=>gente(c,id,a)});});
  if(W.perro&&W.perro.vis!==0)L.push({y:W.perro.y,d:()=>perro(c,a)});
  if(q.vis)L.push({y:q.y+27,d:()=>rana(c,q,a)});
  if(W.cesta)L.push({y:W.cesta[1],d:()=>{const x=W.cesta[0],y=W.cesta[1],im=spr("bolaq",()=>mkBola("q"));for(let i=0;i<(W.cestaN==null?4:W.cestaN);i++)c.drawImage(im,x-10+i*5,y-16-(i%2)*2);c.drawImage(spr("cesta",mkCesta),x-10,y-11);}});
  Object.keys(Bs).forEach(k=>{const o=Bs[k];if(!o||o.vis===0)return;const p=bolaXY(o),y=o.con==="cq"?q.y+27.5:o.con==="perro"&&W.perro?W.perro.y+.5:o.con&&Gt[o.con]?Gt[o.con].y+.5:p[1]+.5;L.push({y,d:()=>unaBola(c,o)});});   // a ball in somebody's hands is drawn in front of them
  if(W.flor){const x=W.flor[0],y=W.flor[1];L.push({y,d:()=>{fr(c,x,y-9,1,9,"#2E8A34");fr(c,x-3,y-4,3,2,"#2E8A34");[[-3,-13],[1,-13],[-3,-9],[1,-9],[-1,-15],[-1,-8],[-4,-11],[2,-11]].forEach(d=>fr(c,x+d[0],y+d[1],3,3,"#F06A9A"));fr(c,x-1,y-12,3,3,"#F0C020");}});}   // a flower (a picture pair)
  if(W.mariposa){const m=W.mariposa,f=(F>>1)%2;L.push({y:999,d:()=>{fr(c,R(m.x)-3-f,R(m.y)-2,3,4,"#F0A0D0");fr(c,R(m.x)+1+f,R(m.y)-2,3,4,"#F0A0D0");fr(c,R(m.x),R(m.y)-2,1,5,OUT);}});}
  L.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  Object.keys(Gt).forEach(id=>{const p=Gt[id];if(p&&p.bub&&p.vis!==0)bub2(c,p.bub,R(p.x),R(p.y)-alto(id)-1,a);});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
  if(W.oscuro){c.fillStyle="rgba(8,12,24,"+W.oscuro+")";c.fillRect(0,0,SW,SH);if(q.vis&&W.oscuro>.4)rana(c,q,a);}   // his eyes are shut: all is dark but him
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0)return null;return [R(p.x),R(p.y)-alto(k)-1-(p.bub?38:0)];}

/* ---------- the pictures in his answer bubbles ---------- */
function flecha(g,x,y,up){const C="#2E9A48";fr(g,x+2,y+(up?3:0),3,7,C);[[0,3,7,1],[1,2,5,1],[2,1,3,1],[3,0,1,1]].forEach(r=>fr(g,x+r[0],up?y+r[1]:y+9-r[1],r[2],r[3],C));}
function respIcon(g,k,x,y,w,h,a){const im=spr("cq.6_0",()=>mkCoqui(.6,0,0)),bq=spr("bolaq",()=>mkBola("q")),suelo=()=>fr(g,x+4,y+32,32,1,"#9494A6"),t=(F>>1)%8;
  suelo();
  const piel="#D09A54";
  const flechita=(fx,fy,dx,dy)=>{[[0,0],[-1,-1],[-1,1],[-2,-2],[-2,2]].forEach(d=>fr(g,fx+(dx?d[0]*dx:d[1]),fy+(dx?d[1]:d[0]*dy),2,2,"#2E6CD0"));};
  if(k==="tira"){g.drawImage(im,x+2,y+14);fr(g,x+16,y+24,8,4,OUT);fr(g,x+17,y+25,6,2,piel);const bx=x+22+t,by=y+13-R(Math.sin(t/7*Math.PI)*4);for(let i=1;i<=2;i++)fr(g,bx-1-i*4,by+5,3,1,"#2E6CD0");g.drawImage(bq,bx,by);flechita(x+37,y+10,1,0);}   // one arm forward; the ball flies away from him
  else if(k==="coge"){g.drawImage(im,x+11,y+16);[[9,10],[27,10]].forEach(p=>{fr(g,x+p[0],y+p[1],3,9,OUT);fr(g,x+p[0]+1,y+p[1]+1,1,7,piel);});const by=y+Math.min(t,4);g.drawImage(bq,x+14,by);flechita(x+34,y+12,0,1);}                                        // both hands up; the ball drops into them
  else if(k==="arriba"){g.save();g.translate(x+9,y+33);g.scale(1,1.3);g.drawImage(im,0,-im.height);g.restore();flecha(g,x+30,y+6,1);}                                                                   // stretched tall: up
  else if(k==="abajo"){g.save();g.translate(x+6,y+33);g.scale(1.15,.65);g.drawImage(im,0,-im.height);g.restore();flecha(g,x+31,y+12,0);}                                                                // crouched flat: down
  else if(k==="salta"){const up=[5,8,11,13,14,13,11,8][t];fr(g,x+14,y+31,13,2,"#B0B0C0");g.drawImage(im,x+11,y+13-up);[[13,0],[25,0]].forEach(d=>{fr(g,x+d[0],y+31-up+2,1,up-3,"#2E6CD0");});}        // in the air, his shadow below, lines down to the ground
  else if(k==="corre"){const up=(F%2)?2:0;g.save();g.translate(x+24,y+21-up);g.rotate(.3);g.drawImage(im,-10,-9);g.restore();for(let i=0;i<3;i++)fr(g,x+3+((F*2+i*5)%6),y+12+i*6,9,2,"#2E6CD0");}
  else if(k==="da"){g.drawImage(im,x+1,y+14);const hx=x+26,hy=y+25;fr(g,hx+5,hy-2,9,7,OUT);fr(g,hx+6,hy-1,7,5,"#3E9A52");fr(g,hx-1,hy-1,8,5,OUT);fr(g,hx,hy,7,3,"#C88A5A");g.drawImage(bq,hx-3,hy-11);[[0,0],[2,0],[4,0],[3,-1],[3,1]].forEach(d=>fr(g,x+19+d[0]+((F>>2)%2),y+12+d[1],2,1,"#2E9A48"));}   // the ball goes from him into a hand that reaches in from the edge
  else if(k==="aguanta"){g.drawImage(im,x+5,y+13);g.drawImage(bq,x+10,y+23);mano(g,x+27,y+6);}}                                                                                                  // holding the ball, the raised hand of "wait"

/* ---------- the card in the corner: three rounds; a star, or the mark of what went wrong ---------- */
function hud(g,W,a){if(!W.tarjeta)return;tarjeta(g,3,3,66,24);
  (W.marcas||[]).forEach((m,i)=>{const x=10+i*20,y=6;
    if(m==="ok"){const st=["......#......",".....###.....",".....###.....","#############",".###########.","..#########..","...#######...","..#########..",".####...####.",".###.....###.","##.........##"];g.fillStyle=OUT;st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i-1,y+j+1,3,3);});g.fillStyle="#F0C020";st.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")g.fillRect(x+i,y+j+2,1,1);});}
    else if(m==="pata"){g.fillStyle="#B07A3C";g.fillRect(x+3,y+7,8,7);[[1,3],[5,1],[9,1],[13,3]].forEach(d=>g.fillRect(x+d[0]-1,y+d[1]+1,3,4));}
    else if(m==="agua"||m==="gota"){g.fillStyle="#2E6CD0";[[6,0,2,3],[5,3,4,3],[4,6,6,3],[3,9,8,4],[4,13,6,1]].forEach(r=>g.fillRect(x+r[0],y+r[1],r[2],r[3]));g.fillStyle="#A8CCF8";g.fillRect(x+5,y+9,2,3);if(m==="agua"){g.fillStyle="#2E6CD0";g.fillRect(x,y+14,14,1);}}
    else{g.fillStyle="#C8C8D4";g.fillRect(x+1,y+13,12,1);g.fillRect(x+1,y+1,1,12);g.fillRect(x+12,y+1,1,12);g.fillRect(x+1,y+1,12,1);}});}

/* ---------- moving things ---------- */
async function mueve(id,x,y,n,corre){const p=G(id);if(!p)return;const x0=p.x,y0=p.y;n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/(corre?10:5)));p.paso=1;p.corre=corre?1:0;if(Math.abs(x-x0)>3)p.dir=x>x0?1:-1;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n;await wait(TICK);}p.x=x;p.y=y;p.paso=0;p.corre=0;}
async function perroA(x,y,pose,n){const o=W.perro;if(!o)return;const x0=o.x,y0=o.y;pose=pose||"run";n=n||Math.max(3,R(Math.hypot(x-x0,y-y0)/(pose==="run"?11:5)));o.pose=pose;if(Math.abs(x-x0)>3)o.dir=x>x0?1:-1;for(let i=1;i<=n;i++){o.x=x0+(x-x0)*i/n;o.y=y0+(y-y0)*i/n;await wait(TICK);}o.x=x;o.y=y;}
async function brinco(o,h,n){n=n||8;for(let i=1;i<=n;i++){o.dy=h*Math.sin(Math.PI*i/n);await wait(TICK);}o.dy=0;}                         // a person or the dog jumps (dy is up)
async function ranaSalta(h,n){const q=W.cq;n=n||10;SFX.hop();for(let i=1;i<=n;i++){q.dy=-h*Math.sin(Math.PI*i/n);await wait(TICK);}q.dy=0;}
const suelta=n=>{const o=B(n);if(!o)return;const p=bolaXY(o);o.con=null;o.x=p[0];o.y=p[1];o.z=p[2];};
// a ball flies (or, with alto 0, rolls) to a place on the ground, or into somebody's hands
async function vuela(n,a,alto,pasos,rastro){const o=B(n);if(!o)return;suelta(n);const x0=o.x,y0=o.y,z0=o.z,fin=typeof a==="string"?manos(a):[a[0],a[1],a[2]||0];
  pasos=pasos||Math.max(5,R(Math.hypot(fin[0]-x0,fin[1]-y0)/9));const dx=fin[0]-x0,dn=Math.hypot(dx,fin[1]-y0)||1;if(rastro!==0)o.vuela=[dx/dn,0];
  for(let i=1;i<=pasos;i++){const t=i/pasos,f=typeof a==="string"?manos(a):fin;o.x=x0+(f[0]-x0)*t;o.y=y0+(f[1]-y0)*t;o.z=z0+(f[2]-z0)*t+(alto||0)*4*t*(1-t);await wait(TICK);}
  o.vuela=null;if(typeof a==="string"){o.con=a;SFX.blip();}else{o.x=fin[0];o.y=fin[1];o.z=fin[2];}}
const ladra=async n=>{const o=W.perro,p0=o.pose;o.pose="bark";for(let k=0;k<(n||2);k++){tone(520,0,.07,"square",.05,300);tone(400,.07,.1,"square",.05,240);await wait(260);}o.pose=p0;};
async function sacude(ms){const o=W.perro;o.sacude=1;for(let k=0;k<6;k++){tone(900-k*60,0,.05,"triangle",.04,500);await wait((ms||900)/6);}o.sacude=0;}
function marca(m){const i=(W.marcas||[]).indexOf(null);if(i>=0)W.marcas[i]=m;}
// Canelo takes a ball (out of the air, off the grass or out of somebody's hands) and carries it to his pile
async function roba(n){const o=B(n),pe=W.perro;if(!o||!pe)return;const p=bolaXY(o);await perroA(p[0]-10,Math.min(206,p[1]+2),"run");if(p[2]>12)await brinco(pe,Math.min(26,p[2]-4),5);
  o.con="perro";o.z=0;SFX.bonk();await wait(150);const k=W.pila||0,q=PILA[Math.min(3,k)];await perroA(q[0]+16,q[1],"run");pe.dir=-1;o.con=null;o.x=q[0];o.y=q[1];o.z=0;W.pila=k+1;W.bolas["pila"+k]=o;delete W.bolas[n];
  await perroA(SITIO[0]+4,SITIO[1]+3,"walk",4);pe.pose="lie";pe.dir=1;await wait(250);}
// a ball rolls down to the water and in: plop. It floats there.
async function alagua(n){const o=B(n);if(!o)return;const k=W.flotan||0,d=[[196,205],[207,198],[200,212],[212,208]][Math.min(3,k)];await vuela(n,[ORILLA[0],ORILLA[1]],0,7,0);await vuela(n,d,4,5,0);
  o.flota=1;W.salpica=(W.salpica||[]).concat([{x:d[0],y:d[1]-2,f:F}]);tone(300,0,.12,"sine",.12,90);tone(180,.08,.2,"sine",.1,60);W.flotan=k+1;W.bolas["flota"+k]=o;delete W.bolas[n];await wait(500);}
// a new small ball out of the basket, to the frog's feet or into somebody's hands
async function nueva(a){W.bolas.cq={k:"q",x:W.cesta[0],y:W.cesta[1]-12,z:6};SFX.blip();W.twinkle="cesta";await wait(450);W.twinkle=null;if(a&&a!=="pies")await vuela("cq",a,10,6,0);else await vuela("cq",PIES,10,6,0);}

const acts={
  async pose(o){const p=G(o.quien);if(p)p.pose=o.que;},
  async mira(o){const p=G(o.quien);if(p)p.dir=+o.d;},
  async va(o){await mueve(o.quien,+o.x,+o.y,null,o.corre);if(o.d)G(o.quien).dir=+o.d;},
  async acasa(){await Promise.all(["luis","carmen"].map(async k=>{const p=G(k);if(!p)return;await mueve(k,CASA[k][0],CASA[k][1]);p.dir=k==="luis"?1:-1;p.pose="idle";}));},
  async marca(o){marca(o.que);SFX.blip();await wait(250);},
  async ladra(o){await ladra(+(o.n||2));},
  // one throws, another catches: de and a are luis, carmen or cq; b names the ball (it is in de's hands, or at the frog's feet)
  async pasa(o){const de=o.de,a=o.a,b=o.b||"cq";if(B(b).con!==de){B(b).con=de;SFX.blip();await wait(200);}if(de!=="cq"){const p=G(de);p.pose="arriba";await wait(160);}else{bounce(5);await wait(140);}
    if(a!=="cq"){G(a).pose="arriba";}await vuela(b,a,+(o.alto||26));if(de!=="cq")G(de).pose="idle";if(a==="cq")bounce(4);else{await wait(160);G(a).pose="idle";}},
  // a ball is put down, or rolled, to the frog's feet
  async alpie(o){const b=o.b||"cq";await vuela(b,PIES,o.rueda?0:6,o.rueda?8:5,0);},
  // the frog picks his ball up
  async recoge(){const o=B("cq");if(o&&!o.con){bounce(4);await wait(120);o.con="cq";}},
  // a child fetches the ball from the frog's feet and takes it home
  async sellevan(o){const k=o.quien,p=G(k),b=B(o.b||"cq"),xy=bolaXY(b);await mueve(k,xy[0]+(k==="luis"?-22:22),xy[1]+4);b.con=k;SFX.blip();await wait(150);await mueve(k,CASA[k][0],CASA[k][1]);p.dir=k==="luis"?1:-1;},
  // a child brings the ball over and puts it in the frog's hands
  async trae(o){const k=o.quien,p=G(k),b=B(o.b||"cq"),q=frogBox(W.cq);await mueve(k,k==="luis"?q.x-16:q.x+q.w+16,W.cq.y+30);p.pose="offer";await wait(250);b.con="cq";SFX.blip();bounce(4);await wait(250);p.pose="idle";if(!o.queda){await mueve(k,CASA[k][0],CASA[k][1]);p.dir=k==="luis"?1:-1;}},
  // the frog carries a ball over to a child and hands it across; the child keeps it, or (vuelve) gives it straight back
  async lleva(o){const k=o.a,p=G(k),b=B(o.b||"cq"),q=W.cq,x0=q.x,y0=q.y;b.con="cq";await hopTo(k==="luis"?p.x+8:p.x-40,p.y-30,2);p.pose="offer";await wait(200);b.con=k;SFX.blip();await wait(300);
    if(o.vuelve){await wait(200);b.con="cq";SFX.blip();}p.pose="idle";await hopTo(x0,y0,2);if(o.vuelve)await vuela(o.b||"cq",PIES,4,4,0);},
  async roba(o){await roba(o.b||"cq");},
  async nueva(o){await nueva(o.a);},
  async alagua(o){await alagua(o.b||"juego");},

  /* ----- story 15: La bola ----- */
  async inicio15(){W.gente={luis:{x:CASA.luis[0],y:CASA.luis[1],pose:"idle",dir:1},carmen:{x:CASA.carmen[0],y:CASA.carmen[1],pose:"idle",dir:-1}};W.perro={x:SITIO[0]+4,y:SITIO[1]+3,pose:"sit",dir:1};
    Object.assign(W.cq,{x:LUGAR.inicio[0],y:LUGAR.inicio[1],s:1});W.cesta=CESTA.slice();W.pila=0;
    W.bolas={luis:{k:"L",con:"luis"},carmen:{k:"C",con:"carmen"},cq:{k:"q",x:PIES[0],y:PIES[1],z:0}};},
  // Canelo dashes in and takes the frog's ball to his spot
  async turno15(){await roba("cq");await ladra(1);W.perro.pose="lie";},
  async mueverabo17(){const o=W.perro;for(let k=0;k<4;k++){o.dy=k%2?1:0;await wait(140);}o.dy=0;},   // he will not let go
  async mueverabo(){const o=W.perro;for(let k=0;k<4;k++){o.dir=-o.dir;await wait(140);}o.dir=1;},
  // the children put their own balls down in the grass beside them, in view
  async bajan(){await Promise.all([B("luis")&&B("luis").con==="luis"?vuela("luis",[CASA.luis[0]-13,CASA.luis[1]+5],3,4,0):0,B("carmen")&&B("carmen").con==="carmen"?vuela("carmen",[CASA.carmen[0]+14,CASA.carmen[1]+5],3,4,0):0]);},
  // decision A: Luis holds his big ball, the frog holds his small one
  async listoA(){await acts.acasa();const l=B("luis"),b=B("cq");if(l.con!=="luis"){l.con="luis";SFX.blip();}if(b&&b.con!=="cq"){bounce(4);await wait(120);b.con="cq";}await wait(250);},
  async bienA(o){const lu=G("luis");
    if(o.dijo==="tira"){const d=vuela("luis",[lu.x-13,lu.y+5],3,4,0);await acts.pasa({de:"cq",a:"luis",b:"cq"});await d;await vuela("cq",PIES,0,8,0);B("luis").con="luis";}
    else{const d=vuela("cq",PIES,3,4,0);await acts.pasa({de:"luis",a:"cq",b:"luis"});await d;await acts.pasa({de:"cq",a:"luis",b:"luis"});}},
  // decision A, wrong: he throws when he should catch / he waits to catch when he should throw
  async malA(o){const lu=G("luis"),q=frogBox(W.cq);
    if(o.dijo==="coge"){bounce(5);lu.pose="arriba";await wait(150);const p1=vuela("luis",[q.x+(q.w>>1),W.cq.y+28,22],24),p2=vuela("cq",[lu.x-24,lu.y-6,30],16,8);await Promise.all([p1,p2]);lu.pose="idle";SFX.bonk();bounce(3);const back=vuela("luis","luis",8,7,0);await roba("cq");await back;}
    else{await vuela("cq",PIES,3,4,0);W.cq.dy=-3;await wait(900);W.cq.dy=0;await roba("cq");}},
  // the hiding game: the two stand side by side, put their heads together, and face us with their hands behind their backs
  async esconden(o){const lu=G("luis"),ca=G("carmen"),b=B("cq");if(B("luis")&&B("luis").con==="luis")await vuela("luis",[CASA.luis[0]-12,CASA.luis[1]+4],3,4,0);if(B("carmen")&&B("carmen").con==="carmen")await vuela("carmen",[CASA.carmen[0]+14,CASA.carmen[1]+4],3,4,0);if(b&&b.con==="cq"){await vuela("cq",PIES,4,4,0);}if(b&&b.con!=="carmen")await acts.sellevan({quien:"carmen"});await Promise.all([mueve("luis",166,160),mueve("carmen",190,156)]);lu.dir=1;ca.dir=-1;
    for(let k=0;k<3;k++){lu.dy=2;ca.dy=2;await wait(140);lu.dy=0;ca.dy=0;await wait(140);}if(B("cq"))B("cq").vis=0;W.tieneBola=o.tiene;lu.dir=1;ca.dir=1;lu.pose="atras";ca.pose="atras";lu.dir=-1;await wait(300);},
  // the one he touched shows what is in his hands
  async ensena(o){const k=o.quien,p=G(k),b=B("cq");p.pose="offer";if(W.tieneBola===k&&b){b.vis=1;b.con=k;SFX.blip();}await wait(650);},
  async devuelve(){const k=W.tieneBola,b=B("cq");if(b&&b.con===k){await vuela("cq",PIES,0,8,0);}G("luis").pose="idle";G("carmen").pose="idle";W.tieneBola=null;await acts.acasa();},
  // decision B, wrong: Canelo takes it out of the hands that hold it
  async malB(){await roba("cq");G("luis").pose="idle";G("carmen").pose="idle";W.tieneBola=null;},
  // decision C: who holds the frog's ball (carmen) or (cq, and Carmen holds up her hands)
  async quien15(o){await acts.acasa();const b=B("cq");if(o.que==="carmen"){if(b.con!=="carmen")await acts.sellevan({quien:"carmen"});}else{if(b.con==="carmen")await acts.trae({quien:"carmen"});else await acts.recoge();G("carmen").pose="arriba";}await wait(250);},
  async duda(o){const ca=G("carmen");ca.pose=o.que==="carmen"?"offer":"tu";SFX.bonk();await wait(600);},
  async final15(){const n=(W.marcas||[]).filter(m=>m==="ok").length,lu=G("luis"),ca=G("carmen"),b=B("cq");await acts.acasa();B("luis").con="luis";if(b){b.vis=1;b.con="cq";}await wait(300);
    if(b){const p=bolaXY(b),h=n===3?70:34;b.con=null;b.x=p[0];b.y=p[1];bounce(8);for(let i=1;i<=14;i++){b.z=p[2]+h*Math.sin(Math.PI*i/14);await wait(TICK);}b.con="cq";}
    if(n===3){W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[70,60],[196,70],[136,50],[110,90],[170,96]]});}else if(n>0)SFX.win();else SFX.coqui();await wait(500);},

  /* ----- story 16: ¡Arriba! ¡Abajo! ----- */
  async inicio16(){W.gente={luis:{x:92,y:170,pose:"idle",dir:-1},carmen:{x:112,y:190,pose:"idle",dir:-1}};W.perro={x:46,y:178,pose:"sit",dir:1};Object.assign(W.cq,{x:132,y:142,s:1});W.cesta=[88,208];W.flotan=0;
    W.bolas={juego:{k:"L",x:HORQ[0],y:ARBOL[1],z:ARBOL[1]-HORQ[1]-3}};},
  async salta(o){if(o.quien==="cq"){await ranaSalta(+(o.h||14));return;}if(o.quien==="perro"){await brinco(W.perro,+(o.h||9),7);tone(520,0,.07,"square",.05,300);return;}
    const p=G(o.quien);p.pose="arriba";await brinco(p,+(o.h||9),8);p.pose="idle";},
  async bajoarbol(o){const k=o.quien;if(k==="cq"){await hopTo(52,138,2);return;}await mueve(k,k==="luis"?78:70,k==="luis"?166:172);G(k).dir=-1;},
  async aparta(o){const k=o.quien;await mueve(k,k==="luis"?92:112,k==="luis"?170:190);G(k).dir=-1;},
  // the frog jumps higher than anybody and knocks the ball out of the tree; it bounces and rolls down to the reeds
  async tumba(){await hopTo(50,140,2);const q=W.cq;SFX.hop();for(let i=1;i<=6;i++){q.dy=-46*Math.sin(Math.PI/2*i/6);await wait(TICK);}SFX.bonk();W.tiembla={en:"arbol",f:F};const v=vuela("juego",[104,190],8,7,0);for(let i=1;i<=6;i++){q.dy=-46*Math.cos(Math.PI/2*i/6);await wait(TICK);}q.dy=0;await v;},
  async ruedabajo(){await vuela("juego",[150,196],10,6,0);await vuela("juego",[JUNCO[0],JUNCO[1]],0,7,0);W.tiembla={en:"juncos",f:F};W.donde="abajo";},
  // Luis goes to where the frog said. arriba: under the tree he holds out his hands and the frog knocks the ball down to him; abajo: he looks in the reeds
  async luisbusca(o){const lu=G("luis"),b=B("juego"),ar=o.en==="arriba",hay=b&&W.donde===o.en,q=W.cq;lu.ojos=0;await mueve("luis",ar?82:166,ar?166:194,null,1);
    if(ar){lu.dir=-1;lu.pose="offer";await wait(400);if(hay){const x0=q.x,y0=q.y;await hopTo(44,138,2,1);SFX.hop();for(let i=1;i<=6;i++){q.dy=-44*Math.sin(Math.PI/2*i/6);await wait(TICK);}W.tiembla={en:"arbol",f:F};const v=vuela("juego","luis",4,7,0);for(let i=1;i<=6;i++){q.dy=-44*Math.cos(Math.PI/2*i/6);await wait(TICK);}q.dy=0;await v;await hopTo(x0,y0,2);}else{W.tiembla={en:"arbol",f:F};await wait(500);}lu.pose="idle";}
    else{W.tiembla={en:"juncos",f:F};await wait(500);if(hay){b.vis=1;b.con="luis";SFX.blip();}}
    await wait(300);if(hay){await mueve("luis",CASA.luis[0],CASA.luis[1]);lu.dir=1;}},
  // ready for the catching game: the frog with his back to the pond, Luis facing him with the ball at his chest
  async listos(){const lu=G("luis"),ca=G("carmen");await Promise.all([mueve("luis",CASA.luis[0],CASA.luis[1]),mueve("carmen",74,204),hopTo(136,150,2,1)]);lu.dir=1;ca.dir=1;const pe=W.perro;if(pe){await perroA(46,178,"walk");pe.pose="sit";pe.dir=1;}
    if(!B("juego")){W.bolas.juego={k:"q",x:W.cesta[0],y:W.cesta[1]-12,z:6};}await vuela("juego","luis",8,6,0);},
  async listo16(){const lu=G("luis");lu.ojos=0;if(Math.abs(W.cq.x-136)>3||Math.abs(W.cq.y-150)>3)await hopTo(136,150,2,1);if(Math.abs(lu.x-CASA.luis[0])>3)await mueve("luis",CASA.luis[0],CASA.luis[1]);lu.dir=1;
    if(!B("juego"))W.bolas.juego={k:"q",x:W.cesta[0],y:W.cesta[1]-12,z:6};if(B("juego").con!=="luis")await vuela("juego","luis",8,6,0);},
  // Luis throws high or rolls it low; the frog does what he chose (arriba: he jumps; abajo: he crouches)
  async tiro(o){const lu=G("luis"),q=W.cq,alto=o.como==="arriba",bien=o.hace===o.como;lu.pose=alto?"arriba":"offer";await wait(200);
    if(alto){const v=vuela("juego",bien?"cq":[178,186,30],bien?30:22,9);if(o.hace==="arriba"){await wait(260);await ranaSalta(16,8);}else{q.s=.86;await wait(500);}await v;}
    else{const v=vuela("juego",bien?"cq":[176,190,0],0,10,0);if(o.hace==="arriba"){await wait(200);await ranaSalta(16,8);}else{q.s=.86;await wait(450);}await v;}
    q.s=1;lu.pose="idle";if(bien){bounce(4);await wait(200);}else{await alagua("juego");}},
  async alacesta(){const b=B("juego");if(b){await vuela("juego",[W.cesta[0],W.cesta[1]-10,4],14,7,0);delete W.bolas.juego;}},
  // Canelo's go: he jumps when the ball comes low; it rolls under him and into the pond
  async turno16a(){const pe=W.perro;if(B("juego")&&B("juego").con!=="luis")await vuela("juego","luis",8,6,0);await hopTo(150,128,2);await perroA(140,180,"walk");pe.pose="sit";pe.dir=-1;await wait(300);},
  async turno16b(){const pe=W.perro,lu=G("luis");lu.pose="offer";await wait(200);const v=vuela("juego",[176,190,0],0,11,0);await wait(180);await brinco(pe,14,8);tone(520,0,.07,"square",.05,300);await v;lu.pose="idle";await alagua("juego");
    pe.dir=1;pe.pose="lie";await wait(500);},
  // after Canelo's miss: Luis takes a ball from the basket and throws it high to Carmen, who takes it over her head and throws it back
  async prepcarmen(){const ca=G("carmen");W.bolas.juego={k:"q",x:W.cesta[0],y:W.cesta[1]-12,z:6};await Promise.all([vuela("juego","luis",8,6,0),mueve("carmen",CASA.carmen[0],CASA.carmen[1])]);ca.dir=-1;},
  async acarmen(){const lu=G("luis"),ca=G("carmen");lu.pose="arriba";await wait(200);ca.pose="arriba";const v=vuela("juego","carmen",30,9);await wait(250);await brinco(ca,8,7);await v;lu.pose="idle";await wait(300);await vuela("juego","luis",22,8);ca.pose="idle";await mueve("carmen",74,204);ca.dir=1;},
  async trasturno(){const pe=W.perro;await perroA(46,178,"walk");pe.pose="sit";pe.dir=1;await hopTo(136,150,2);},
  // the picture goes dark: somebody hides the ball (arriba: in the tree; abajo: in the reeds)
  async esconde16(o){W.cierra=1;await wait(350);for(let i=1;i<=5;i++){W.oscuro=i*.19;await wait(TICK);}const lu=G("luis"),ca=G("carmen"),pe=W.perro;for(let k=0;k<4;k++){tone(140+k%2*30,0,.06,"square",.05,90);await wait(220);}
    lu.x=96;lu.y=180;lu.dir=1;lu.pose="idle";lu.ojos=0;ca.x=122;ca.y=184;ca.dir=-1;ca.pose="idle";if(pe){pe.x=110;pe.y=198;pe.pose="sit";pe.dir=1;}Object.assign(W.cq,{x:136,y:136,s:1});
    W.bolas.juego={k:"q",x:o.en==="arriba"?HORQ[0]-4:JUNCO[0],y:o.en==="arriba"?ARBOL[1]:JUNCO[1],z:o.en==="arriba"?ARBOL[1]-COPA[1]:0,vis:0};W.donde=o.en;
    for(let i=4;i>=0;i--){W.oscuro=i*.19;await wait(TICK);}W.oscuro=0;W.cierra=0;await wait(200);},
  // the frog goes to look (arriba: he jumps up into the leaves; abajo: he hops down to the reeds)
  async busca(o){const ar=o.en==="arriba",b=B("juego"),hay=b&&W.donde===o.en,q=W.cq;
    if(ar){await hopTo(46,140,3,1);SFX.hop();for(let i=1;i<=6;i++){q.dy=-44*Math.sin(Math.PI/2*i/6);await wait(TICK);}W.tiembla={en:"arbol",f:F};if(hay){b.vis=1;}await wait(200);const v=hay?vuela("juego",[84,188],6,6,0):null;for(let i=1;i<=6;i++){q.dy=-44*Math.cos(Math.PI/2*i/6);await wait(TICK);}q.dy=0;if(v){await v;await hopTo(70,160,1);b.con="cq";SFX.blip();}}
    else{await hopTo(160,166,3,1);W.tiembla={en:"juncos",f:F};await wait(400);if(hay){b.vis=1;b.con="cq";SFX.blip();}}
    if(!hay){SFX.bonk();await wait(400);}},
  // he was wrong: Canelo runs to where the ball really is (he jumps against the tree; or he noses into the reeds) and knocks it loose; he cannot hold it, and it rolls into the pond
  async perrotumba(){const b=B("juego"),pe=W.perro;if(!b)return;const ar=W.donde==="arriba";
    if(ar){await perroA(80,166,"run");pe.dir=-1;await ladra(1);await brinco(pe,9,6);W.tiembla={en:"arbol",f:F};SFX.bonk();b.vis=1;b.con=null;await vuela("juego",[98,188],6,7,0);const c=perroA(112,190,"run");await vuela("juego",[150,196],10,7,0);await c;await perroA(160,196,"run");}
    else{await perroA(166,198,"run");pe.pose="husmea";W.tiembla={en:"juncos",f:F};await wait(350);b.vis=1;b.con=null;await vuela("juego",[176,203],3,4,0);}
    await alagua("juego");pe.pose="sit";await wait(300);},
  // the frog gives the ball he holds to Luis
  async aluis(){const b=B("juego");if(b&&b.con!=="luis"){bounce(4);await vuela("juego","luis",12,7,0);}await wait(200);},
  async vuelve16(){await hopTo(136,136,3,1);},
  // decision C: Luis throws one up with the sun in his eyes; we see where it comes down
  async sol(o){const lu=G("luis"),ca=G("carmen"),pe=W.perro;await Promise.all([mueve("luis",104,180),mueve("carmen",76,202),hopTo(136,136,2,1)]);lu.dir=1;if(pe){await perroA(50,196,"walk");pe.pose="sit";pe.dir=1;}ca.dir=-1;ca.pose="offer";
    W.bolas.juego={k:"q",x:W.cesta[0],y:W.cesta[1]-12,z:6};await vuela("juego","luis",8,6,0);lu.pose="arriba";await wait(250);lu.ojos=1;lu.pose="idle";W.donde=o.en;
    if(o.en==="arriba"){await vuela("juego",[HORQ[0],ARBOL[1],ARBOL[1]-HORQ[1]-3],50,12);W.tiembla={en:"arbol",f:F};}else{await vuela("juego",[156,186],56,12);await vuela("juego",[JUNCO[0]-2,JUNCO[1]+2],5,6,0);W.tiembla={en:"juncos",f:F};}await wait(300);},
  async final16(){const n=(W.marcas||[]).filter(m=>m==="ok").length,lu=G("luis"),ca=G("carmen"),pe=W.perro;lu.ojos=0;ca.pose="idle";
    if(n===0){await Promise.all([mueve("luis",150,194),mueve("carmen",128,202),hopTo(148,146,2,1)]);lu.dir=1;ca.dir=1;SFX.coqui();await wait(700);}
    else{await Promise.all([mueve("luis",96,180),mueve("carmen",168,176),hopTo(118,142,2,1)]);lu.dir=1;ca.dir=-1;lu.pose="arriba";ca.pose="arriba";const k=n===3?3:1;
      for(let i=0;i<k;i++)W.bolas["f"+i]={k:"q",x:108+i*18,y:196,z:8};const sube=async(nm,d)=>{const o=B(nm),z0=o.z;await wait(d);for(let j=1;j<=14;j++){o.z=z0+52*Math.sin(Math.PI*j/14);await wait(TICK);}o.z=z0;};
      const s=[];for(let i=0;i<k;i++)s.push(sube("f"+i,i*120));await Promise.all(s.concat([ranaSalta(24,12)]));if(n===3){W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[70,60],[196,70],[136,50],[110,90],[170,96]]});}else SFX.win();lu.pose="idle";ca.pose="idle";}
    await wait(300);},
  async saltan(){const lu=G("luis"),ca=G("carmen");await Promise.all([brinco(lu,9,8),brinco(ca,9,8),ranaSalta(40,14)]);await ranaSalta(40,14);if(W.perro){W.perro.dir=1;await ladra(2);}},

  /* ----- story 17: ¡Otra vez! ----- */
  async inicio17(){W.gente={luis:{x:84,y:174,pose:"idle",dir:1},carmen:{x:58,y:198,pose:"idle",dir:1}};W.perro={x:196,y:204,pose:"walk",dir:-1,mojado:1};Object.assign(W.cq,{x:112,y:140,s:1});W.mojado=0;
    W.bolas={carmen:{k:"C",con:"carmen"},cq:{k:"q",x:FILA[2][0],y:FILA[2][1],z:0},luis:{k:"L",con:"perro"}};},
  async carmenfila(){const ca=G("carmen");ca.pose="idle";await mueve("carmen",FILA[1][0]-12,FILA[1][1]+2);const b=B("carmen");b.con=null;b.x=FILA[1][0];b.y=FILA[1][1];b.z=0;SFX.blip();await mueve("carmen",58,198);ca.dir=1;},
  // Canelo comes up from the water with the ball in his mouth and stops in front of the frog
  async sube17(){const pe=W.perro;await perroA(160,190,"walk");pe.pose="sit";pe.dir=-1;await wait(300);},
  // Canelo puts the ball he holds into its place in the row
  async alafila(o){const n=o.b,i={luis:0,carmen:1,cq:2}[n],pe=W.perro;await perroA(FILA[i][0]+16,FILA[i][1]-4,"walk");pe.dir=-1;const b=B(n);b.con=null;b.x=FILA[i][0];b.y=FILA[i][1];b.z=0;SFX.blip();await wait(200);await perroA(164,188,"walk");pe.pose="sit";pe.dir=-1;},
  // Canelo picks a ball out of the row and stands with it in front of the frog and Luis
  async perrocoge(o){const n=o.b,pe=W.perro,b=B(n),p=bolaXY(b);await perroA(p[0]+16,p[1]-3,"walk");pe.dir=-1;b.con="perro";SFX.blip();await wait(200);await perroA(160,190,"walk");pe.pose="sit";pe.dir=-1;await wait(200);},
  // Canelo drops the ball he holds at the frog's feet (the small ball's place in the row)
  async suelta17(o){const pe=W.perro,n=o.b||"cq",b=B(n);if(b&&b.con==="perro"){const i={luis:0,carmen:1,cq:2}[n];await vuela(n,FILA[i],4,5,0);}},
  // a ball is thrown down toward the pond (by the frog, or by Luis); Canelo fetches it (aire: he takes it out of the air) and puts it back in its place in the row. sacude: "no" = he does not shake himself by the water
  async tira17(o){const n=(o.b||"cq").replace("bola_",""),b=B(n),pe=W.perro,i={luis:0,carmen:1,cq:2}[n],de=o.de||"cq";if(b.con!==de){b.con=de;SFX.blip();await wait(150);}
    if(de==="cq"){bounce(6);await wait(160);}else{G(de).pose="arriba";await wait(200);}
    if(o.aire){const v=vuela(n,[176,186,22],26,9);await perroA(168,188,"run");await brinco(pe,16,5);await v;b.con="perro";SFX.blip();}
    else{const v=vuela(n,[ORILLA[0],ORILLA[1]+2],30,10);pe.pose="run";await wait(120);await perroA(ORILLA[0]-12,ORILLA[1]+2,"run");await v;W.salpica=(W.salpica||[]).concat([{x:ORILLA[0],y:ORILLA[1],f:F}]);tone(300,0,.12,"sine",.12,90);b.con="perro";pe.mojado=1;await wait(250);
      if(o.sacude!=="no"){pe.dir=-1;await sacude(700);}}
    if(de!=="cq")G(de).pose="idle";
    await perroA(FILA[i][0]+16,FILA[i][1]-4,"run");pe.dir=-1;b.con=null;b.x=FILA[i][0];b.y=FILA[i][1];b.z=0;SFX.blip();await wait(150);await perroA(164,188,"walk");pe.pose="sit";pe.dir=-1;},
  // he carries the small ball to Luis and puts it in his hands; Luis throws it for Canelo himself (solo: Luis only puts it back in the row)
  async da17(o){const b=B("cq"),lu=G("luis"),q=W.cq;b.con="cq";await hopTo(lu.x+8,lu.y-34,2);lu.pose="offer";await wait(200);b.con="luis";SFX.blip();await wait(250);lu.pose="idle";await hopTo(112,140,2);
    if(o&&o.solo){await mueve("luis",FILA[2][0]-14,FILA[2][1]-3);b.con=null;b.x=FILA[2][0];b.y=FILA[2][1];b.z=0;SFX.blip();await mueve("luis",84,174);lu.dir=1;}else await acts.tira17({b:"cq",de:"luis"});},
  // decision B: what he chose to do (mal: it was not what Luis called, so nothing follows from it)
  async hazB(o){const q=o.que;if(q==="tira")await acts.tira17({b:"cq",sacude:o.mal?"no":null});else if(q==="da")await acts.da17({solo:o.mal});else await acts.aguanta({bebe:o.mal?"no":null});},
  // decision A, wrong: he throws another ball; it lands a little way off and Canelo does not go after it
  async malA17(o){const n=(o.b||"cq").replace("bola_",""),b=B(n);b.con="cq";bounce(6);await wait(160);await vuela(n,[168,206],22,8);W.perro.pose="sit";await wait(500);},
  async vuelvefila(o){const n=(o.b||"cq").replace("bola_",""),i={luis:0,carmen:1,cq:2}[n],pe=W.perro;await perroA(180,204,"walk");pe.dir=-1;pe.pose="husmea";const v=vuela(n,FILA[i],0,10,0);await perroA(FILA[i][0]+16,FILA[i][1]-2,"walk");await v;await perroA(164,188,"walk");pe.pose="sit";pe.dir=-1;},
  async jadea(){const pe=W.perro;await perroA(150,192,"walk",8);pe.dir=-1;pe.pose="bark";await wait(700);pe.pose="sit";},
  async luisno(){const p=G("luis");for(let k=0;k<4;k++){p.dir=-p.dir;await wait(140);}p.dir=1;SFX.bonk();await wait(250);},
  async empuja2(){const pe=W.perro;pe.pose="husmea";await wait(500);pe.pose="lie";},
  async lleva17(o){const n=(o.b||"luis").replace("bola_",""),b=B(n),q=W.cq,lu=G("luis"),p=bolaXY(b);await hopTo(p[0]-16,p[1]-50,1);b.con="cq";SFX.blip();await hopTo(lu.x+8,lu.y-34,2);lu.pose="offer";await wait(200);b.con="luis";SFX.blip();await wait(250);await hopTo(112,140,2);},
  async luisfila(){const lu=G("luis");await mueve("luis",FILA[0][0]-12,FILA[0][1]-3);const b=B("luis");b.con=null;b.x=FILA[0][0];b.y=FILA[0][1];b.z=0;lu.pose="idle";SFX.blip();await mueve("luis",84,174);lu.dir=1;},
  async empuja(){const pe=W.perro;await perroA(FILA[2][0]+14,FILA[2][1]-4,"walk");pe.dir=-1;pe.pose="husmea";await wait(350);pe.pose="sit";await ladra(2);},
  // he holds the ball and stands still; Canelo goes down and drinks
  async aguanta(o){const b=B("cq"),pe=W.perro;bounce(4);await wait(120);b.con="cq";await wait(500);if(o&&o.bebe!=="no"){await perroA(ORILLA[0]-10,ORILLA[1]+2,"walk");pe.dir=1;pe.pose="eat";await wait(900);pe.mojado=1;await perroA(164,188,"walk");pe.pose="sit";pe.dir=-1;}await vuela("cq",FILA[2],4,4,0);},
  // Canelo shakes himself beside somebody: water everywhere
  async sacude(o){const pe=W.perro,k=o.junto;if(k==="cq"){const q=frogBox(W.cq);await perroA(q.x+q.w+12,W.cq.y+30,"walk");pe.dir=-1;pe.pose="sit";await wait(600);await sacude(900);W.mojado=Math.min(3,(W.mojado||0)+1);SFX.bonk();await wait(300);await perroA(164,188,"walk");pe.pose="sit";pe.dir=-1;}
    else{const p=G(k);await perroA(p.x+22,p.y+2,"walk");pe.dir=-1;pe.pose="sit";await wait(900);await sacude(900);p.mojado=1;SFX.bonk();await wait(300);}},
  // the turn: Carmen has the ball but watches a butterfly
  async turno17(){const ca=G("carmen");await acts.va({quien:"carmen",x:FILA[2][0]-12,y:FILA[2][1]-2});B("cq").con="carmen";SFX.blip();await mueve("carmen",58,198);ca.dir=-1;W.mariposa={x:40,y:150};for(let i=0;i<10;i++){W.mariposa.x=40-i*1.5+Math.sin(i)*3;W.mariposa.y=150-i+Math.cos(i*1.3)*3;await wait(TICK*2);}},
  async trasturno17(){const pe=W.perro,b=B("cq");W.mariposa=null;G("carmen").dir=1;await vuela("cq",FILA[2],0,9,0);await perroA(164,188,"walk");pe.pose="sit";pe.dir=-1;},
  async final17(){const n=(W.marcas||[]).filter(m=>m==="ok").length,pe=W.perro,ca=G("carmen"),lu=G("luis");const b=B("cq");await perroA(160,196,"walk");if(b){await vuela("cq",[170,197],0,4,0);}pe.pose="lie";pe.dir=1;await wait(400);
    if(n===3){ca.pose="tu";ca.rie=1;await wait(500);bounce(6);await wait(300);bounce(6);ca.rie=0;ca.pose="idle";W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[70,60],[196,70],[136,50],[110,90],[170,96]]});await wait(600);}
    else if(n>0){SFX.win();await wait(500);}else{SFX.coqui();await wait(700);}},
  async rien(){const lu=G("luis"),ca=G("carmen");lu.rie=1;ca.rie=1;bounce(5);await wait(700);lu.rie=0;ca.rie=0;},
};
async function stake(lost,max,en){SFX.bonk();await wait(300);}
function poke(what){if(what==="perro"&&W.perro)ladra(1);}
const estado=W=>"gente="+Object.keys(W.gente||{}).map(k=>k+"@"+R(W.gente[k].x)+","+R(W.gente[k].y)+":"+W.gente[k].pose).join(" ")+" perro="+(W.perro?R(W.perro.x)+","+R(W.perro.y)+":"+W.perro.pose:"-")+
  " bolas="+Object.keys(W.bolas||{}).map(k=>k+(W.bolas[k].con?">"+W.bolas[k].con:"@"+R(W.bolas[k].x)+","+R(W.bolas[k].y))+(W.bolas[k].vis===0?"(oculta)":"")).join(" ")+" marcas="+(W.marcas||[]).join("")+" pila="+(W.pila||0)+" flotan="+(W.flotan||0)+" mojado="+(W.mojado||0);
KIT.escena({id:"campo",CAM:{wide:[22,0,196,216]},heartAt:[110,30],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({gente:{},perro:null,bolas:{},cesta:null,cestaN:null,tarjeta:null,marcas:null,pila:0,flotan:0,mojado:0,oscuro:0,cierra:0,tiembla:null,salpica:null,mariposa:null,tieneBola:null,donde:null,cq:{x:LUGAR.inicio[0],y:LUGAR.inicio[1],s:1,dy:0,al:1,vis:1,bub:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
