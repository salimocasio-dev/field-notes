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
  else{b.rect(97,61,30,20,"#FFFFFF");for(let y=63;y<81;y+=3)b.rect(97,y,30,1,ST[2]);b.rect(111,61,2,20,ST[1]);b.rect(108,70,2,2,OUT);b.rect(114,70,2,2,OUT);}
  b.frame(93,57,38,28,OUT);b.frame(96,60,32,22,C[0]);
  b.rect(90,86,44,5,Wd[2]);b.rect(90,86,44,1,Wd[4]);b.frame(89,85,46,7,OUT);
  for(let i=0;i<9;i++){b.ell(93+i*4.8,83.5,2.2,2.2,[["#FF8FB8","#FFE070","#F4584A"][i%3]]);b.px(93+i*4.8,85,RP.grn[1]);}
  // the door
  b.rect(150,50,32,54,C[3]);b.frame(149,49,34,56,OUT);
  if(door===1){b.grad(153,53,24,51,["#140A06","#22140C","#32201A"]);b.rect(177,53,4,51,Wd[2]);b.rect(177,53,1,51,Wd[4]);b.frame(152,52,26,53,OUT);}
  else if(door===.5){b.grad(153,53,11,51,["#140A06","#22140C","#32201A"]);b.grad(164,53,15,51,[Wd[3],Wd[2],Wd[1],Wd[0]],true);b.rect(164,53,1,51,Wd[4]);b.frame(152,52,28,53,OUT);b.rect(163,52,1,53,OUT);b.rect(167,77,2,2,RP.yel[2]);}
  else{b.grad(153,53,26,51,[Wd[3],Wd[2],Wd[2],Wd[1]],true);b.frame(152,52,28,53,OUT);
    [[156,57,20,18],[156,80,20,20]].forEach(p=>{b.frame(p[0],p[1],p[2],p[3],Wd[0]);b.rect(p[0]+1,p[1]+1,p[2]-2,1,Wd[4]);b.rect(p[0]+1,p[1]+1,1,p[3]-2,Wd[4]);});
    b.rect(154,77,2,2,RP.yel[2]);}
  // the porch lamp, between the window and the door
  b.rect(143,55,3,2,ST[0]);b.rect(142,58,5,8,lamp?RP.yel[4]:"#7C92A2");if(lamp)b.rect(143,60,3,4,"#FFFFFF");b.frame(141,57,7,10,OUT);b.rect(143,67,3,1,OUT);
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
function mkNube(){const b=new Buf(72,18);b.ell(36,10,25,6,NB);b.ell(17,11,14,5,NB);b.ell(55,11,14,5,NB);b.ell(29,6,12,5,NB);b.ell(45,6,11,5,NB);return b.outline().done();}
const BOLT=["..##","..#.",".##.","###.",".##.",".#..","##..","#..."];
function rain(g){for(let i=0;i<64;i++){const x=(i*61+F*3)%SW,y=(i*97+F*13)%SH;fr(g,x,y,1,4,"#C4DCF6");fr(g,x-1,y+4,1,2,"#C4DCF6");}
  for(let i=0;i<9;i++){const x=(i*83+((F>>1)*37))%SW,y=126+((i*29+(F>>1)*11)%84);fr(g,x-2,y,5,1,"#DCEBFA");}}
function towel(g,x,y){   // draped over his head, hanging down both sides
  fr(g,x-2,y-1,17,5,OUT);fr(g,x-2,y+3,5,10,OUT);fr(g,x+10,y+3,5,10,OUT);
  fr(g,x-1,y,15,3,"#FFFFFF");fr(g,x-1,y+3,3,8,"#FFFFFF");fr(g,x+11,y+3,3,8,"#FFFFFF");
  fr(g,x-1,y+8,3,1,"#3A86E6");fr(g,x+11,y+8,3,1,"#3A86E6");fr(g,x-1,y+1,15,1,"#D6E6F8");}

const ABAT={puerta:[135,55],ventana:[82,61]};
function draw(c,W,a){const q=W.cq,AB=(pose,op)=>spr("ab"+pose+op,()=>mkAbuela(pose,op));
  c.drawImage(spr("fr"+W.door+"_"+W.win+"_"+W.lamp,()=>bg(W.door,W.win,W.lamp)),0,0);
  if(!W.storm)ambient(c);
  if(W.peek&&W.door===.5){c.save();c.beginPath();c.rect(153,53,11,51);c.clip();c.drawImage(AB("idle",0),135,55);c.restore();}   // she is behind the door as it opens
  const ab=W.ab;
  if(ab){const pose=ab.pose==="wave"?"wave"+(a%2):"idle",op=ab.bub&&ab.bub!=="amor"&&a%2?1:0;c.globalAlpha=ab.al==null?1:ab.al;
    if(ab.en==="ventana"){c.save();c.beginPath();c.rect(97,61,30,20);c.clip();c.drawImage(AB(pose,op),W.tab?75:82,61);   // head and shoulders in the window
      if(W.tab){const bl=(F%47)<2?1:0,sh=W.shake&&a%2?1:0;c.drawImage(spr("cq.42_"+bl,()=>mkCoqui(.42,bl,0)),112+sh,67);   // and the frog beside her
        if(W.tab==="mojado")towel(c,113,65);}
      c.restore();
      if(W.tab==="gotas"&&W.shake)[[110,64],[120,62],[127,66]].forEach((p,i)=>fr(c,p[0]+(a%2?1:-1)*(i-1),p[1]-(a%3),1,2,"#8CC4F8"));}
    else c.drawImage(AB(pose,op),ABAT.puerta[0],ABAT.puerta[1]);
    c.globalAlpha=1;}
  if(q.vis){c.globalAlpha=q.al;frog(c,q,a);c.globalAlpha=1;const b=frogBox(q);
    if(W.wet)for(let k=0;k<3;k++)fr(c,b.x+3+k*Math.round(b.w/3),b.y+((F*2+k*5)%12),1,2,"#8CC4F8");
    if(W.gotas){const t=F-W.gotas;for(let k=0;k<3;k++){const y=Math.min(b.y+2,b.y-26+(t-k*3)*5);if(t>=k*3)fr(c,b.x+5+k*Math.round(b.w/4),y,2,3,"#8CC4F8");}}}
  if(W.dark){c.fillStyle="rgba(14,22,46,"+W.dark+")";c.fillRect(0,0,SW,SH);}
  if(W.lamp){c.fillStyle="rgba(255,232,140,.2)";c.beginPath();c.arc(144.5,62,15,0,7);c.fill();c.fillStyle="rgba(255,240,170,.3)";c.beginPath();c.arc(144.5,62,8,0,7);c.fill();fr(c,142,58,5,8,RP.yel[4]);fr(c,143,60,3,4,"#FFFFFF");}
  [W.nube3,W.nube2,W.nube].forEach(n=>{if(!n)return;n.x+=(n.tx-n.x)*.14;if(Math.abs(n.tx-n.x)<.6)n.x=n.tx;const x=Math.round(n.x);c.drawImage(spr("nube",mkNube),x,0);
    if(!W.rain)for(let i=0;i<11;i++)fr(c,x+7+(i*23+F*2)%58,17+(i*7+F*4)%24,1,3,"#C4DCF6");});   // rain already falling from the cloud, far off
  if(W.rain)rain(c);
  if(W.flash&&F-W.flash<3){c.fillStyle="rgba(255,255,255,.5)";c.fillRect(0,0,SW,SH);if(W.nube)BOLT.forEach((rw,j)=>{for(let i=0;i<rw.length;i++)if(rw[i]==="#")fr(c,Math.round(W.nube.x)+30+i*2,17+j*2,2,2,"#FFF4B0");});}
  // bubbles last, so they stay bright
  if(ab&&ab.bub){const at=ab.en==="ventana"?[112,60]:[ab.bub==="como"?141:147,ab.bub==="como"?66:69];bub(c,ab.bub,at[0],at[1],a);}
  if(W.dentro)bub(c,"quien",W.dentro==="ventana"?112:166,W.dentro==="ventana"?59:53,a);
  if(q.vis&&q.bub){const b=frogBox(q);bub(c,q.bub,b.x+(b.w>>1),b.y,a);}
}
function box(k,W){if(k==="abuela")return W&&W.ab&&W.ab.en==="ventana"?[97,61,30,20]:[151,56,29,49];
  if(k==="nube")return [Math.round(W&&W.nube?W.nube.x:0),0,72,18];
  return {casa:[60,17,166,90],puerta:[151,51,30,54],ventana:[93,57,38,28]}[k];}
function hit(x,y,W){const inb=b=>x>=b[0]&&x<b[0]+b[2]&&y>=b[1]&&y<b[1]+b[3];
  if(W.ab&&inb(box("abuela",W)))return "abuela";
  const q=W.cq,fb=frogBox(q);if(q.vis&&x>=fb.x&&x<fb.x+fb.w&&y>=fb.y&&y<fb.y+fb.h)return "coqui";
  if(W.storm&&W.nube&&inb([W.nube.x-2,0,76,20]))return "nube";
  if(inb([145,46,42,62]))return "puerta";        // a finger slightly off still counts
  if(inb([82,53,61,42]))return "ventana";
  if(y>=16&&y<42){const t=(y-16)/25;if(x>=88-30*t&&x<=196+30*t)return "casa";}
  if(inb([57,41,171,70]))return "casa";
  if(!W.storm&&(x-210)*(x-210)+(y-17)*(y-17)<144)return "sol";
  if(inb([34,36,30,70]))return "palma";
  return null;}
function poke(what){if(what==="nube"){SFX.trueno(.35);W.flash=F;}
  else if(what==="abuela"&&W.ab&&!W.ab.bub){W.ab.bub="amor";const my=runId;setTimeout(()=>{if(my===runId&&W.ab&&W.ab.bub==="amor")W.ab.bub=null;},1500/FAST);}}

/* ---------- what can happen here ---------- */
const LUGAR={puerta:[150,104,.72],ventana:[96,104,.72],patio:[123,150,.86]},NX=[38,92,150];
const acts={
  async ir(o){const L=LUGAR[o.a||o.en],q=W.cq,d=Math.hypot(q.x-L[0],q.y-L[1]);if(d<3)return;await hopTo(L[0],L[1],Math.max(1,Math.min(4,Math.round(d/28))),L[2]);},
  // the frog goes there and knocks
  async tocar(o){await acts.ir({a:o.en});const b=box(o.en,W);SFX.toc();bounce(5);fx({t:"knock",n:7,x:Math.round(b[0]+b[2]/2),y:Math.round(b[1]+b[3]/2)});await wait(560);},
  async luz(){W.lamp=1;SFX.luz();fx({t:"star",n:12,pts:[[136,56],[153,57],[144,48],[138,70],[151,71]]});await wait(450);},
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
  async trueno(){W.storm=1;W.flash=F;SFX.trueno();W.dark=.18;W.nube={x:-70,tx:NX[0]};await wait(1000);},
  async atras(){await hopTo(LUGAR.patio[0],LUGAR.patio[1],2,LUGAR.patio[2]);},
  async llueve(){W.nube.tx=NX[2];W.nube2={x:-80,tx:62};W.nube3={x:250,tx:186};W.dark=.32;SFX.trueno(.5);W.flash=F;await wait(700);W.rain=1;SFX.lluvia();if(W.cq.vis)W.wet=1;await wait(700);},
  // a few drops catch him just before he is in
  async gotas(){W.gotas=F;for(let k=0;k<3;k++){await wait(210);SFX.drop();}bounce(4);await wait(500);},
  // the last picture: grandma and the frog at the window
  async cuadro(){W.tab=W.lost>=S.stake.steps?"mojado":W.lost?"gotas":"seco";if(!W.ab)W.ab={en:"ventana",pose:"idle",bub:null,al:1};W.ab.en="ventana";await camGo("ventana");
    if(W.tab==="seco"){W.ab.pose="wave";await wait(900);}
    else if(W.tab==="gotas"){W.shake=1;SFX.drop();await wait(250);SFX.drop();await wait(700);W.shake=0;W.tab="seco";W.ab.bub="bien";await wait(1100);W.ab.bub=null;}
    else await wait(500);},
  async fin(){W.heart=W.lost?0:1;SFX.win();const b=cam;fx({t:"star",n:40,pts:[[b[0]+8,b[1]+14],[b[0]+b[2]-8,b[1]+16],[b[0]+b[2]/2-20,b[1]+8],[b[0]+b[2]/2+22,b[1]+10],[b[0]+6,b[1]+b[3]/2],[b[0]+b[2]-6,b[1]+b[3]/2]].map(p=>[Math.round(p[0]),Math.round(p[1])])});await wait(1700);}
};
// the thing at stake takes a step: the cloud comes closer. At the last step it rains.
async function stake(lost,max){if(lost>=max){await acts.llueve();return;}
  SFX.trueno(.6);W.flash=F;W.nube.tx=NX[Math.min(2,Math.round(lost*2/max))];W.dark=.18+.07*lost;await wait(900);}

ESCENAS.frente={SW,SH,CAM:{wide:[44,0,196,216],casa:[56,0,172,190],puerta:[117,30,98,108],ventana:[63,22,98,108]},
  handAt:{casa:[141,24],puerta:[166,76],ventana:[112,72]},heartAt:[103,26],
  fresh:()=>({door:0,win:0,lamp:0,peek:0,ab:null,storm:0,nube:null,nube2:null,nube3:null,dark:0,rain:0,wet:0,gotas:0,flash:0,dentro:null,tab:null,shake:0}),
  draw,box,hit,poke,acts,stake};
})();
