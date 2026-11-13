"use strict";
/* ============================================================
   Coquí · scene "El frente": the front of grandma's house.
   Drawn once, with its states: door open or shut, shutters open or
   shut, porch lamp on or off, a storm cloud that comes closer, rain.
   Every story set here uses this drawing and these actions.
   ============================================================ */
(function(){
const SW=240,SH=216;

/* ---------- the picture ---------- */
function bg(door,win,lamp){const b=new Buf(SW,SH),T=RP.teal,C=RP.cream,Wd=RP.wood,ST=RP.stone;
  sky(b,SW,96);grass(b,96,SW,SH);
  for(let y=119;y<SH;y++){const t=(y-119)/(SH-119),xl=Math.round(142-34*t),xr=Math.round(188+34*t);
    for(let x=xl;x<=xr;x++)b.px(x,y,x===xl||x===xr?ST[0]:(y%6===0||(x+Math.floor(y/6)*7)%13===0)?ST[1]:hs(x,y)<8?ST[4]:ST[3]);}
  b.grad(70,44,144,60,[T[3],T[3],T[2],T[2],T[1]],true);
  for(let y=49;y<104;y+=5)for(let x=70;x<214;x++)b.px(x,y,T[1]);
  for(let y=44;y<51;y++)for(let x=70;x<214;x++)if(bay(x,y)<(51-y)/8)b.px(x,y,T[0]);
  b.rect(69,44,1,60,"#134A4C");b.rect(214,44,1,60,"#134A4C");
  for(let y=16;y<42;y++){const t=(y-16)/25,xl=Math.round(88-30*t),xr=Math.round(196+30*t),k=(y-16)%5,rw=Math.floor((y-16)/5);
    for(let x=xl;x<=xr;x++)b.px(x,y,x===xl||x===xr||y===41?"#4A1210":y===16?RP.red[4]:k===4?RP.red[0]:(x+rw*4)%8===0?RP.red[1]:bay(x,y)<t*.8?RP.red[2]:RP.red[3]);}
  b.rect(58,42,169,3,C[3]);b.rect(58,44,169,1,C[1]);b.frame(57,41,171,4,OUT);
  // the window: wooden shutters. Shut, they hide who is behind them.
  b.rect(94,58,36,26,C[3]);
  if(win){b.rect(86,58,7,26,"#FFFFFF");b.rect(131,58,7,26,"#FFFFFF");for(let y=60;y<84;y+=3){b.rect(86,y,7,1,ST[2]);b.rect(131,y,7,1,ST[2]);}
    b.frame(85,57,9,28,OUT);b.frame(130,57,9,28,OUT);b.grad(97,61,30,20,["#1A0E08","#2C1A10","#402818"]);}
  else{b.rect(97,61,30,20,lamp?"#FFF6C8":"#FFFFFF");for(let y=63;y<81;y+=3)b.rect(97,y,30,1,lamp?RP.yel[2]:ST[2]);b.rect(111,61,2,20,lamp?RP.yel[1]:ST[1]);b.rect(108,70,2,2,OUT);b.rect(114,70,2,2,OUT);}   // lit from inside when the lights are on
  b.frame(93,57,38,28,OUT);b.frame(96,60,32,22,C[0]);
  b.rect(90,86,44,5,Wd[2]);b.rect(90,86,44,1,Wd[4]);b.frame(89,85,46,7,OUT);
  for(let i=0;i<9;i++){b.ell(93+i*4.8,83.5,2.2,2.2,[["#FF8FB8","#FFE070","#F4584A"][i%3]]);b.px(93+i*4.8,85,RP.grn[1]);}
  // the door
  b.rect(150,50,32,54,C[3]);b.frame(149,49,34,56,OUT);
  if(door===1){b.grad(153,53,24,51,["#140A06","#22140C","#32201A"]);b.rect(177,53,4,51,Wd[2]);b.rect(177,53,1,51,Wd[4]);b.frame(152,52,26,53,OUT);}
  else if(door===.5){b.grad(153,53,11,51,["#140A06","#22140C","#32201A"]);b.grad(164,53,15,51,[Wd[3],Wd[2],Wd[1],Wd[0]],true);b.rect(164,53,1,51,Wd[4]);b.frame(152,52,28,53,OUT);b.rect(163,52,1,53,OUT);b.rect(167,77,2,2,RP.yel[2]);}
  else{b.grad(153,53,26,51,[Wd[3],Wd[2],Wd[2],Wd[1]],true);b.frame(152,52,28,53,OUT);
    [[156,57,20,18],[156,80,20,20]].forEach(p=>{b.frame(p[0],p[1],p[2],p[3],Wd[0]);b.rect(p[0]+1,p[1]+1,p[2]-2,1,Wd[4]);b.rect(p[0]+1,p[1]+1,1,p[3]-2,Wd[4]);});
    b.rect(154,77,2,2,RP.yel[2]);
    if(lamp){b.rect(153,53,26,1,RP.yel[3]);b.rect(153,53,1,51,RP.yel[3]);b.rect(178,53,1,51,RP.yel[3]);b.rect(153,102,26,2,RP.yel[4]);}}   // light around the edges of the shut door
  b.rect(62,104,160,6,ST[3]);b.rect(62,104,160,1,ST[4]);b.rect(62,109,160,1,ST[1]);b.frame(61,103,162,8,OUT);
  b.rect(146,111,38,4,ST[2]);b.rect(146,111,38,1,ST[4]);b.rect(142,115,46,4,ST[3]);b.rect(142,115,46,1,ST[4]);b.rect(142,118,46,1,ST[0]);b.rect(146,114,38,1,ST[0]);
  b.rect(153,104,24,2,RP.red[1]);
  const out=b.done(),x=b.cx;x.drawImage(spr("palm",mkPalm),30,34);x.drawImage(spr("bush",mkBush),206,92);x.drawImage(spr("pot",mkPot),192,78);x.drawImage(spr("bush",mkBush),44,96);
  return out;}
// small living things, so the place is never still
function mkCloud(){const b=new Buf(40,15);b.ell(20,9,13,5,RP.cloud);b.ell(11,10,8,4,RP.cloud);b.ell(30,10,9,4,RP.cloud);b.ell(22,5,7,4.5,RP.cloud);return b.done();}
const FLY=[["pp...pp","ppp.ppp",".ppdpp.","..pdp..","...d..."],[".......","ppp.ppp","pppdppp",".ppdpp.","...d..."]];
function fly(g,x,y,col,fl){FLY[fl].forEach((rw,j)=>{for(let i=0;i<rw.length;i++){const ch=rw[i];if(ch!==".")fr(g,x+i,y+j,1,1,ch==="d"?OUT:col);}});}
function ambient(g){g.drawImage(spr("cloud",mkCloud),Math.round(250-(F/4)%310),0);
  fly(g,Math.round(98+34*Math.sin(F/41)+6*Math.sin(F/7)),Math.round(97+9*Math.sin(F/29)+3*Math.sin(F/5)),"#FF8FB8",(F>>1)%2);
  fly(g,Math.round(203+13*Math.sin(F/33+2)+4*Math.sin(F/6)),Math.round(72+7*Math.sin(F/19)+2*Math.sin(F/4)),"#FFE070",((F>>1)+1)%2);}
// the storm cloud: the thing at stake when rain is coming
const NB=["#2E3848","#414C60","#566378","#6E7B90","#8A96A8"];
function mkNube(){const b=new Buf(98,22);b.ell(49,13,34,7,NB);b.ell(23,14,19,6,NB);b.ell(75,14,19,6,NB);b.ell(38,8,16,6,NB);b.ell(60,8,15,6,NB);return b.outline().done();}
const BOLT=["..##","..#.",".##.","###.",".##.",".#..","##..","#..."];
function rain(g){for(let i=0;i<64;i++){const x=(i*61+F*3)%SW,y=(i*97+F*13)%SH;fr(g,x,y,1,4,"#C4DCF6");fr(g,x-1,y+4,1,2,"#C4DCF6");}
  for(let i=0;i<9;i++){const x=(i*83+((F>>1)*37))%SW,y=126+((i*29+(F>>1)*11)%84);fr(g,x-2,y,5,1,"#DCEBFA");}}
const TOWEL=["...####....","..######...",".#########.","###########","#bbbbbbbbb#","###########"];
function towel(g,x,y){TOWEL.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]!==".")fr(g,x+i-1,y+j-1,3,3,OUT);});   // wrapped on top of his head, like after a bath
  TOWEL.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]!==".")fr(g,x+i,y+j,1,1,rw[i]==="b"?"#3A86E6":"#FFFFFF");});}

const ABAT={puerta:[135,55],ventana:[82,61]};
/* ---------- story 2: the cake, its plate, and the bird ---------- */
const SPONGE="#F2D08A",FROST="#FF8FB8";
function mesa(c){fr(c,108,75,20,2,RP.wood[3]);fr(c,108,77,20,1,RP.wood[0]);fr(c,110,78,2,3,RP.wood[1]);fr(c,124,78,2,3,RP.wood[1]);   // a table inside, with the cake on it
  fr(c,111,74,14,1,"#FFFFFF");fr(c,112,68,12,6,SPONGE);fr(c,112,67,12,2,FROST);fr(c,111,67,1,7,OUT);fr(c,124,67,1,7,OUT);fr(c,112,66,12,1,OUT);fr(c,117,65,2,2,RP.red[2]);
  if(W.caliente)for(let k=0;k<3;k++)for(let j=0;j<3;j++){const y=64-j*3-((F>>1)+k*2)%3,x=113+k*4+(((F>>2)+j+k)%2);fr(c,x,y,2,2,j===2?"#E8F0F8":"#FFFFFF");}}   // steam: it is hot   // steam: it is hot
function mkAve(st,fl){const R=st==="round",b=new Buf(R?24:18,R?18:14),B=RP.blue,cx=R?11:8,cy=R?10:8;
  b.cap(cx-6,cy-1,cx-9,cy-3,1.2,[B[1]]);
  b.ell(cx,cy,R?8:5.5,R?6.5:4.2,B);b.ell(cx-1,cy+(R?2.5:1.5),R?5:3.4,R?3.4:2.2,["#E8F4FF"]);
  b.ell(cx+(R?6:5),cy-(R?4:3),R?3.8:3.3,R?3.6:3.1,B);
  if(st==="sleep"||R){b.rect(cx+(R?6:5),cy-(R?4:3),2,1,OUT);}else{b.px(cx+6,cy-4,"#FFFFFF");b.px(cx+6,cy-3,"#20140A");b.px(cx+7,cy-3,"#20140A");}
  b.rect(cx+(R?9:8),cy-(R?4:3),R?3:2,R?2:1,RP.yel[2]);b.px(cx+(R?9:8),cy-(R?2:2),RP.orng[2]);
  if(fl)b.ell(cx-1,cy-4,3.6,2,[B[0],B[1]]);else b.ell(cx-1,cy+1,3.6,2,[B[0],B[1]]);
  if(!R){b.px(cx-1,cy+4,RP.orng[1]);b.px(cx+2,cy+4,RP.orng[1]);}
  return b.outline().done();}
const PERCH={ventana:[112,57],puerta:[166,49]},HOLE={ventana:[112,71],puerta:[166,80]};
function avePos(v){if(v.mode==="circle")return [Math.round(150+56*Math.cos(F/13)),Math.round(22+7*Math.sin(F/13*2))];if(v.mode==="head"){const b=frogBox(W.cq);return [b.x+b.w/2,b.y+Math.round(W.cq.dy)+2];}return [Math.round(v.x),Math.round(v.y)];}
const AVK=1.6;   // the bird is drawn bigger than its pixels, so it reads at phone size
function drawAve(c,v){if(!v||v.mode==="none")return;const p=avePos(v),st=v.st||"n",fl=(v.mode==="circle"||v.mode==="fly")?(F>>1)%2:0,
    im=spr("ave"+st+fl,()=>mkAve(st==="round"?"round":st,fl)),w=im.width,h=im.height,dir=v.mode==="circle"?(Math.sin(F/13)>0?-1:1):(v.dir||1),H=Math.round(h*AVK);
  c.save();c.imageSmoothingEnabled=false;c.translate(p[0],p[1]-H+2);c.scale(dir*AVK,AVK);c.drawImage(im,-Math.round(w/2),0);c.restore();
  if(v.slice){const sx=p[0]+(dir<0?-19:11),sy=p[1]-14;fr(c,sx-1,sy-1,9,7,OUT);fr(c,sx,sy,7,5,SPONGE);fr(c,sx,sy,7,2,FROST);}
  if(st==="round"){const z=(F>>3)%3,zx=p[0]+12+z*2,zy=p[1]-H-4-z*2;fr(c,zx,zy,4,1,"#FFFFFF");fr(c,zx+3,zy+1,1,1,"#FFFFFF");fr(c,zx+2,zy+2,1,1,"#FFFFFF");fr(c,zx+1,zy+3,1,1,"#FFFFFF");fr(c,zx,zy+4,4,1,"#FFFFFF");}   // z: asleep
  if(st==="feliz"&&(F>>2)%2){fr(c,p[0]-2,p[1]-H-5,2,2,"#FF8FB8");fr(c,p[0]+1,p[1]-H-5,2,2,"#FF8FB8");fr(c,p[0]-1,p[1]-H-3,3,2,"#FF8FB8");}}
// the plate at stake, always in the same corner of the screen
function hud(g,W){if(W.plato==null)return;const x=5,y=5,k=2;   // the plate at stake, in the corner of the screen, at double size
  fr(g,x-2,y+21,3*13*k/2+8,8,OUT);fr(g,x-1,y+22,3*13*k/2+6,6,"#FFFFFF");fr(g,x+1,y+26,3*13*k/2+2,1,RP.grey[3]);
  for(let i=0;i<3;i++){const sx=x+3+i*19;if(i<W.plato){fr(g,sx-1,y+1,16,21,OUT);fr(g,sx,y+8,14,13,SPONGE);fr(g,sx,y+2,14,6,FROST);fr(g,sx+5,y-1,4,4,RP.red[2]);fr(g,sx+6,y-2,2,1,OUT);fr(g,sx,y+13,14,1,"#E0B060");}
    else{fr(g,sx+3,y+19,3,2,SPONGE);fr(g,sx+9,y+20,2,1,SPONGE);fr(g,sx+6,y+18,1,1,FROST);}}}
function draw(c,W,a){const q=W.cq,AB=(pose,op)=>spr("ab"+pose+op,()=>mkAbuela(pose,op));
  c.drawImage(spr("fr"+W.door+"_"+W.win+"_"+W.lamp,()=>bg(W.door,W.win,W.lamp)),0,0);
  if(!W.storm)ambient(c);
  if(W.peek&&W.door===.5){c.save();c.beginPath();c.rect(153,53,11,51);c.clip();c.drawImage(AB("idle",0),135,55);c.restore();}   // she is behind the door as it opens
  const ab=W.ab;
  if(ab){const pose=ab.pose==="wave"?"wave"+(a%2):ab.pose==="dedo"?"dedo"+((a>>1)%2):(ab.pose||"idle"),op=((ab.bub&&ab.bub!=="amor")||TALK==="abuela")&&a%2?1:0;c.globalAlpha=ab.al==null?1:ab.al;
    if(ab.en==="ventana"){c.save();c.beginPath();c.rect(97,61,30,20);c.clip();if(W.win===1&&W.mesa)mesa(c);c.drawImage(AB(pose,op),W.tab||W.mesa?75:82,61);   // head and shoulders in the window
      if(W.tab){const bl=(F%47)<2?1:0,sh=W.shake&&a%2?1:0;c.drawImage(spr("cq.42_"+bl,()=>mkCoqui(.42,bl,0)),112+sh,W.tab==="mojado"?68:67);   // and the frog beside her
        if(W.tab==="mojado"){towel(c,114,62);for(let k=0;k<2;k++)fr(c,113+k*13,70+((F+k*4)%8),1,2,"#8CC4F8");}}
      c.restore();
      if(W.tab==="gotas"&&W.shake)[[110,64],[120,62],[127,66]].forEach((p,i)=>fr(c,p[0]+(a%2?1:-1)*(i-1),p[1]-(a%3),1,2,"#8CC4F8"));}
    else c.drawImage(AB(pose,op),ABAT.puerta[0],ABAT.puerta[1]);
    c.globalAlpha=1;}
  if(q.vis){c.globalAlpha=q.al;frog(c,q,a);c.globalAlpha=1;const b=frogBox(q);
    if(W.wet)for(let k=0;k<3;k++)fr(c,b.x+3+k*Math.round(b.w/3),b.y+((F*2+k*5)%12),1,2,"#8CC4F8");
    if(W.gotas){const t=F-W.gotas;for(let k=0;k<3;k++){const y=Math.min(b.y+2,b.y-26+(t-k*3)*5);if(t>=k*3)fr(c,b.x+5+k*Math.round(b.w/4),y,2,3,"#8CC4F8");}}}
  drawAve(c,W.ave);
  if(W.storm){c.fillStyle="rgba(150,160,176,.62)";c.beginPath();c.arc(210,17,10,0,7);c.fill();}   // the sun goes pale
  if(W.dark){c.fillStyle="rgba(14,22,46,"+W.dark+")";c.fillRect(0,0,SW,SH);}
  if(W.lamp){c.fillStyle="rgba(255,232,140,.16)";if(!W.win)c.fillRect(88,53,48,36);if(!W.door)c.fillRect(146,47,40,60);c.fillStyle="rgba(255,240,170,.14)";if(!W.win)c.fillRect(92,56,40,30);if(!W.door)c.fillRect(149,49,34,56);}   // the lights are on inside: window and door glow alike
  [W.nube3,W.nube2,W.nube].forEach(n=>{if(!n)return;n.x+=(n.tx-n.x)*.14;if(Math.abs(n.tx-n.x)<.6)n.x=n.tx;const x=Math.round(n.x);c.drawImage(spr("nube",mkNube),x,0);
    if(!W.rain)for(let i=0;i<16;i++)fr(c,x+9+(i*23+F*2)%80,21+(i*7+F*4)%26,1,4,"#C4DCF6");});   // rain already falling from the cloud, far off
  if(W.rain)rain(c);
  if(W.flash&&F-W.flash<3){c.fillStyle="rgba(255,255,255,.5)";c.fillRect(0,0,SW,SH);if(W.nube)BOLT.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")fr(c,Math.round(W.nube.x)+44+i*2,21+j*2,2,2,"#FFF4B0");});}
  // bubbles last, so they stay bright
  if(ab&&ab.bub){const at=ab.en==="ventana"?[112,60]:[ab.bub==="como"?141:147,ab.bub==="como"?66:69];bub(c,ab.bub,at[0],at[1],a);}
  if(W.dentro)bub(c,"quien",W.dentro==="ventana"?112:166,W.dentro==="ventana"?59:53,a);
  if(q.vis&&q.bub){const b=frogBox(q);bub(c,q.bub,b.x+(b.w>>1),b.y,a);}
}
// where a speech bubble points: just above the speaker's head (or above the picture bubble, if one shows). null = not seen.
function talkAt(k,W){if(k!=="abuela")return null;const ab=W.ab;
  if(ab){if(ab.en==="ventana")return [W.mesa?105:112,ab.bub?38:60];return [ab.bub==="como"?141:156,ab.bub?47:56];}
  if(W.dentro)return W.dentro==="ventana"?[112,37]:[166,31];
  return null;}
function box(k,W){if(k==="abuela")return W&&W.ab&&W.ab.en==="ventana"?[97,61,30,20]:[151,56,29,49];
  if(k==="nube")return [Math.round(W&&W.nube?W.nube.x:0),0,98,22];
  return {casa:[60,17,166,90],puerta:[151,51,30,54],ventana:[93,57,38,28]}[k];}
function hit(x,y,W){const inb=b=>x>=b[0]&&x<b[0]+b[2]&&y>=b[1]&&y<b[1]+b[3];
  if(W.ab&&inb(box("abuela",W)))return "abuela";
  if(W.ave&&W.ave.mode!=="none"){const p=avePos(W.ave);if(Math.abs(x-p[0])<16&&y>p[1]-24&&y<p[1]+5)return "pajaro";}
  if(W.plato!=null){const cx=cam[0]+(x-cam[0]),sx=(x-cam[0])*DW/cam[2],sy=(y-cam[1])*DH/cam[3];if(sx<66&&sy<36)return "bizcocho";}
  const q=W.cq,fb=frogBox(q);if(q.vis&&x>=fb.x&&x<fb.x+fb.w&&y>=fb.y&&y<fb.y+fb.h)return "coqui";
  if(W.storm&&W.nube&&inb([W.nube.x-2,0,102,24]))return "nube";
  if(inb([145,46,42,62]))return "puerta";        // a finger slightly off still counts
  if(inb([82,53,61,42]))return "ventana";
  if(y>=16&&y<42){const t=(y-16)/25;if(x>=88-30*t&&x<=196+30*t)return "casa";}
  if(inb([57,41,171,70]))return "casa";
  if(!W.storm&&(x-210)*(x-210)+(y-17)*(y-17)<144)return "sol";
  if(inb([34,36,30,70]))return "palma";
  return null;}
function poke(what){if(what==="pajaro")SFX.pio();
  if(what==="nube"){SFX.trueno(.35);W.flash=F;}
  else if(what==="abuela"&&W.ab&&!W.ab.bub){W.ab.bub="amor";const my=runId;setTimeout(()=>{if(my===runId&&W.ab&&W.ab.bub==="amor")W.ab.bub=null;},1500/FAST);}}

/* ---------- what can happen here ---------- */
const LUGAR={puerta:[150,104,.72],ventana:[96,104,.72],patio:[123,150,.86]},NX=[22,76,140];
const acts={
  async ir(o){const L=LUGAR[o.a||o.en],q=W.cq,d=Math.hypot(q.x-L[0],q.y-L[1]);if(d<3)return;await hopTo(L[0],L[1],Math.max(1,Math.min(4,Math.round(d/28))),L[2]);},
  // the frog goes there and knocks
  async tocar(o){await acts.ir({a:o.en});const b=box(o.en,W);SFX.toc();bounce(5);fx({t:"knock",n:7,x:Math.round(b[0]+b[2]/2),y:Math.round(b[1]+b[3]/2)});await wait(560);},
  async luz(){W.lamp=1;SFX.luz();fx({t:"star",n:12,pts:[[92,54],[132,56],[112,50],[150,47],[182,49],[166,43]]});await wait(450);},   // the lights come on inside
  async dentro(o){W.dentro=o.en;},                         // her voice, from behind the shut door or window
  async calla(){W.dentro=null;if(W.ab)W.ab.bub=null;W.cq.bub=null;},
  async burbuja(o){if(o.quien==="cq"){W.cq.bub=o.que;SFX.coqui();bounce(6);}else if(W.ab)W.ab.bub=o.que;},
  async pose(o){if(W.ab)W.ab.pose=o.que;},
  async abre(o){if(o.que==="puerta"){await camGo("puerta");SFX.creak();W.peek=1;W.door=.5;await wait(650);W.door=1;W.peek=0;W.ab={en:"puerta",pose:"idle",bub:null,al:1};await wait(250);}
    else{await camGo("ventana");SFX.creak();await wait(350);W.win=1;W.ab={en:"ventana",pose:"idle",bub:null,al:1};await wait(350);}},
  // in he goes: by the door, or with a jump through the window
  async entra(o){const q=W.cq;
    if(o.por==="puerta"){for(let i=4;i>=0;i--){W.ab.al=i/5;await wait(TICK);}W.ab=null;await wait(200);
      await hopTo(150,80,2,.72);await wait(120);SFX.hop();for(let i=4;i>=0;i--){q.al=i/5;q.y-=2;await wait(TICK);}q.vis=0;W.wet=0;W.gotas=0;await wait(300);
      SFX.creak();W.door=.5;await wait(420);W.door=0;await wait(350);}
    else{SFX.hop();const x0=q.x,y0=q.y,n=9;for(let i=1;i<=n;i++){const t=i/n;q.x=Math.round(x0+(98-x0)*t);q.y=Math.round(y0+(58-y0)*t);q.dy=-12*Math.sin(Math.PI*t);q.s=Math.round((.72-.26*t)*100)/100;if(i>n-3)q.al=(n-i)/3;await wait(TICK);}
      q.vis=0;q.dy=0;W.wet=0;W.gotas=0;await wait(350);}},
  // thunder: the storm cloud shows at the edge of the sky
  async trueno(){W.storm=1;W.flash=F;SFX.trueno();W.dark=.22;W.nube={x:-100,tx:NX[0]};await wait(1000);},
  async atras(){await hopTo(LUGAR.patio[0],LUGAR.patio[1],2,LUGAR.patio[2]);},
  async llueve(){W.nube.tx=NX[2];W.nube2={x:-100,tx:44};W.nube3={x:250,tx:176};W.dark=.33;SFX.trueno(.5);W.flash=F;await wait(700);W.rain=1;SFX.lluvia();if(W.cq.vis)W.wet=1;await wait(700);},
  // a few drops catch him just before he is in
  async gotas(){W.gotas=F;for(let k=0;k<3;k++){await wait(210);SFX.drop();}bounce(4);await wait(500);},
  // the last picture: grandma and the frog at the window
  async cuadro(){W.tab=W.lost>=S.stake.steps?"mojado":W.lost?"gotas":"seco";if(!W.ab)W.ab={en:"ventana",pose:"idle",bub:null,al:1};W.ab.en="ventana";await camGo("ventana");
    if(W.tab==="seco"){W.ab.pose="wave";await wait(900);}
    else if(W.tab==="gotas"){W.shake=1;SFX.drop();await wait(250);SFX.drop();await wait(700);W.shake=0;W.tab="seco";W.ab.bub="bien";await wait(1100);W.ab.bub=null;}
    else await wait(500);},
  /* ---- story 2 ---- */
  async abrir(o){const k=o.que;await acts.ir({a:k});SFX.creak();await wait(250);if(k==="ventana")W.win=1;else{W.door=.5;await wait(300);W.door=1;}   // the frog opens it
    if(W.abIn===k)W.ab={en:k,pose:"idle",bub:null,al:1};await wait(350);},
  async cerrar(o){const k=o.en;await acts.ir({a:k});bounce(5);SFX.slam();if(k==="ventana")W.win=0;else{W.door=.5;await wait(120);W.door=0;}   // the frog shuts it
    if(W.ab&&W.ab.en===k)W.ab=null;fx({t:"star",n:6,pts:[HOLE[k]]});await wait(380);},
  async abcierra(o){const k=o.que;await camGo(k);SFX.slam();if(k==="ventana")W.win=0;else W.door=0;W.ab=null;W.abIn=k;await wait(450);},   // abuela shuts it from inside
  async vete(){for(let i=4;i>=0;i--){if(W.ab)W.ab.al=i/5;await wait(TICK);}W.ab=null;W.abIn=null;W.mesa=0;W.caliente=0;await wait(200);},   // she goes off to the back, with the cake
  async asoma(){await acts.ir({a:"ventana"});const q=W.cq;SFX.hop();for(let i=1;i<=4;i++){q.y-=3;await wait(TICK);}await wait(300);},   // the frog leans in at the window
  async baja(){const q=W.cq;bounce(4);for(let i=1;i<=4;i++){q.y+=3;await wait(TICK);}},
  async pajaro(){W.ave={mode:"fly",x:-12,y:40,dir:1,st:"n"};SFX.pio();await aveA(150+56,22,12);W.ave.mode="circle";await wait(500);},
  async bonk(o){const v=W.ave,h=HOLE[o.en];v.x=avePos(v)[0];v.y=avePos(v)[1];v.mode="fly";v.dir=h[0]>=v.x?1:-1;SFX.swoop();await aveA(h[0],h[1],8);
    SFX.bonk();fx({t:"knock",n:7,x:h[0],y:h[1]-4});v.st="sleep";await aveA(h[0]-v.dir*6,h[1]+10,4);await wait(350);v.st="n";await aveA(150,26,10);v.mode="circle";},
  async posa(o){const v=W.ave,p=PERCH[o.en];v.x=avePos(v)[0];v.y=avePos(v)[1];v.mode="fly";v.dir=p[0]>=v.x?1:-1;await aveA(p[0],p[1],10);v.mode="sit";v.dir=o.en==="puerta"?-1:1;SFX.pio();await wait(400);},
  async come(){const k=W.ab?W.ab.en:"puerta";await acts.ir({a:k});await wait(200);W.plato=Math.max(0,W.plato-1);SFX.munch();bounce(4);W.cq.bub="amor";await wait(900);W.cq.bub=null;},
  async regala(){const v=W.ave,k=W.ab?W.ab.en:"puerta",h=HOLE[k];W.plato=Math.max(0,W.plato-1);v.x=avePos(v)[0];v.y=avePos(v)[1];v.mode="fly";v.dir=h[0]>=v.x?1:-1;SFX.pio();
    await aveA(h[0],h[1]-6,8);v.slice=1;await wait(300);const b=frogBox(W.cq);v.dir=b.x+b.w/2>=v.x?1:-1;await aveA(b.x+b.w/2,b.y+2,10);v.slice=0;v.mode="head";SFX.munch();await wait(250);SFX.pio();W.cq.bub="amor";await wait(1000);W.cq.bub=null;},
  async fin2(){await camGo("wide",9);const v=W.ave;
    if(v&&v.mode!=="head"){v.x=avePos(v)[0];v.y=avePos(v)[1];v.mode="fly";v.dir=1;await aveA(196,30,10);v.mode="sit";v.st=W.lost>=2?"round":W.lost?"feliz":"n";SFX.pio();}
    else if(v)v.st=W.lost>=2?"round":W.lost?"feliz":"n";
    if(!W.lost){W.heart=1;SFX.win();const b=cam;fx({t:"star",n:40,pts:[[b[0]+8,b[1]+14],[b[0]+b[2]-8,b[1]+16],[b[0]+b[2]/2-20,b[1]+8],[b[0]+b[2]/2+22,b[1]+10]].map(p=>[Math.round(p[0]),Math.round(p[1])])});}
    else SFX.coqui();await wait(1800);},
  async fin(){const b=cam;   // only the dry ending is a celebration
    if(!W.lost){W.heart=1;SFX.win();fx({t:"star",n:40,pts:[[b[0]+8,b[1]+14],[b[0]+b[2]-8,b[1]+16],[b[0]+b[2]/2-20,b[1]+8],[b[0]+b[2]/2+22,b[1]+10],[b[0]+6,b[1]+b[3]/2],[b[0]+b[2]-6,b[1]+b[3]/2]].map(p=>[Math.round(p[0]),Math.round(p[1])])});}
    else if(W.lost<S.stake.steps)SFX.win();else SFX.coqui();
    await wait(1700);}
};
async function aveA(tx,ty,n){const v=W.ave,x0=v.x,y0=v.y;for(let i=1;i<=n;i++){const t=i/n;v.x=x0+(tx-x0)*t;v.y=y0+(ty-y0)*t-Math.sin(Math.PI*t)*6;await wait(TICK);}v.x=tx;v.y=ty;}
// the bird takes a slice: in through the open place, out with it in its beak
async function roba(en){const v=W.ave,h=HOLE[en]||HOLE.ventana;v.x=avePos(v)[0];v.y=avePos(v)[1];v.mode="fly";v.dir=h[0]>=v.x?1:-1;SFX.swoop();await aveA(h[0],h[1],8);
  v.mode="none";await wait(400);W.plato=Math.max(0,W.plato-1);SFX.munch();v.mode="fly";v.slice=1;v.x=h[0];v.y=h[1];v.dir=1;SFX.pio();await aveA(h[0]+30,24,9);await wait(250);v.slice=0;v.mode="circle";await wait(300);}
// the thing at stake takes a step. Rain: the cloud comes closer, and at the last step it rains. Cake: the bird takes a slice.
async function stake(lost,max,en){if(S.stake.thing==="bizcocho"){await roba(en);return;}
  if(lost>=max){await acts.llueve();return;}
  SFX.trueno(.6);W.flash=F;W.nube.tx=NX[Math.min(2,Math.round(lost*2/max))];W.dark=.22+.05*lost;await wait(900);}

ESCENAS.frente={SW,SH,CAM:{wide:[44,0,196,216],casa:[56,0,172,190],puerta:[117,30,98,108],ventana:[63,22,98,108]},
  handAt:{casa:[141,24],puerta:[166,76],ventana:[112,72]},heartAt:[103,26],
  fresh:()=>({ave:null,plato:null,mesa:0,abIn:null,caliente:0,door:0,win:0,lamp:0,peek:0,ab:null,storm:0,nube:null,nube2:null,nube3:null,dark:0,rain:0,wet:0,gotas:0,flash:0,dentro:null,tab:null,shake:0}),
  draw,box,hit,poke,acts,stake,talkAt,hud};
})();
