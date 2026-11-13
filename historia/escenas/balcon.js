"use strict";
/* ============================================================
   Coquí · scene "El balcón": abuela's porch, seen from the yard.
   A teal wall with a window in the middle and a door on the right.
   Abuela's big chair on the left, a small round table, a small
   yellow chair on the right. A hot day.
   States: door open or shut, shutters open or shut, glasses or jugs
   on the table, abuela standing, walking or sitting, a breeze, a
   fierce sun. Every story set here uses this drawing and these actions.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,JUGO=["#C86A10","#F2A024","#FFD070"],AGUA=["#5A9AE0","#9CCBF5","#DCEEFF"];

/* ---------- the picture that does not move ---------- */
function bg(door,win){const b=new Buf(SW,SH),T=RP.teal,C=RP.cream,Wd=RP.wood,ST=RP.stone;
  sky(b,SW,150);grass(b,150,SW,SH);
  for(let y=176;y<SH;y++){const t=(y-176)/(SH-176),xl=Math.round(96-18*t),xr=Math.round(144+18*t);
    for(let x=xl;x<=xr;x++)b.px(x,y,x===xl||x===xr?ST[0]:(y%6===0||(x+Math.floor(y/6)*7)%13===0)?ST[1]:hs(x,y)<8?ST[4]:ST[3]);}
  // the wall
  b.grad(42,33,156,89,[T[3],T[3],T[2],T[2],T[1]],true);
  for(let y=38;y<122;y+=5)for(let x=42;x<198;x++)b.px(x,y,T[1]);
  for(let y=33;y<46;y++)for(let x=42;x<198;x++)if(bay(x,y)<(46-y)/14)b.px(x,y,T[0]);   // shade under the roof
  // the floor: big tiles, wider at the front
  for(let y=122;y<156;y++){const t=(y-122)/34,hw=78+12*t,row=Math.floor(t*3.2);
    for(let x=Math.round(120-hw);x<=Math.round(120+hw);x++){const u=(x-120)/hw*6+6,col=Math.floor(u),e=u-col;
      b.px(x,y,e<.035||Math.floor((t*3.2-row)*10)===0?"#B89A6A":(col+row)%2?"#EEDCB0":"#E0C690");}}
  b.rect(42,120,156,2,T[0]);b.rect(42,122,156,2,"#B89A6A");
  // the edge of the porch, its base and the two steps
  b.rect(31,162,178,14,ST[2]);for(let x=31;x<209;x++)for(let y=162;y<176;y++)if((y===168)||((x+(y>168?9:0))%18===0))b.px(x,y,ST[1]);b.frame(30,161,180,16,OUT);
  b.rect(28,156,184,5,ST[3]);b.rect(28,156,184,1,ST[4]);b.rect(28,160,184,1,ST[1]);b.frame(27,155,186,7,OUT);
  b.rect(99,162,42,7,ST[3]);b.rect(99,162,42,1,ST[4]);b.rect(99,168,42,1,ST[0]);b.frame(98,161,44,9,OUT);
  b.rect(95,169,50,8,ST[3]);b.rect(95,169,50,1,ST[4]);b.rect(95,176,50,1,ST[0]);b.frame(94,168,52,10,OUT);
  // the window: wooden shutters, with a box of flowers
  const wx=101,wy=56;b.rect(wx+1,wy+1,36,26,C[3]);
  if(win){b.rect(wx-7,wy+1,7,26,"#FFFFFF");b.rect(wx+38,wy+1,7,26,"#FFFFFF");for(let y=wy+3;y<wy+27;y+=3){b.rect(wx-7,y,7,1,ST[2]);b.rect(wx+38,y,7,1,ST[2]);}
    b.frame(wx-8,wy,9,28,OUT);b.frame(wx+37,wy,9,28,OUT);b.grad(wx+4,wy+4,30,20,["#1A0E08","#2C1A10","#402818"]);
    b.rect(wx+4,wy+4,30,3,"#FFF4D0");for(let x=wx+4;x<wx+34;x+=4)b.rect(x,wy+7,2,2,"#FFF4D0");}   // a little curtain
  else{b.rect(wx+4,wy+4,30,20,"#FFFFFF");for(let y=wy+6;y<wy+24;y+=3)b.rect(wx+4,y,30,1,ST[2]);b.rect(wx+18,wy+4,2,20,ST[1]);b.rect(wx+15,wy+13,2,2,OUT);b.rect(wx+21,wy+13,2,2,OUT);}
  b.frame(wx,wy,38,28,OUT);b.frame(wx+3,wy+3,32,22,C[0]);
  b.rect(wx-3,wy+29,44,5,Wd[2]);b.rect(wx-3,wy+29,44,1,Wd[4]);b.frame(wx-4,wy+28,46,7,OUT);
  for(let i=0;i<9;i++){b.ell(wx+i*4.8,wy+26.5,2.2,2.2,[["#FF8FB8","#FFE070","#F4584A"][i%3]]);b.px(wx+i*4.8,wy+28,RP.grn[1]);}
  // the door
  b.rect(162,54,32,68,C[3]);b.frame(161,53,34,70,OUT);
  if(door===1){b.grad(165,57,24,65,["#140A06","#22140C","#32201A"]);b.rect(189,57,4,65,Wd[2]);b.rect(189,57,1,65,Wd[4]);b.frame(164,56,26,67,OUT);}
  else if(door===.5){b.grad(165,57,11,65,["#140A06","#22140C","#32201A"]);b.grad(176,57,15,65,[Wd[3],Wd[2],Wd[1],Wd[0]],true);b.rect(176,57,1,65,Wd[4]);b.frame(164,56,28,67,OUT);b.rect(175,56,1,67,OUT);b.rect(179,90,2,2,RP.yel[2]);}
  else{b.grad(165,57,26,65,[Wd[3],Wd[2],Wd[2],Wd[1]],true);b.frame(164,56,28,67,OUT);
    [[168,61,20,24],[168,90,20,27]].forEach(p=>{b.frame(p[0],p[1],p[2],p[3],Wd[0]);b.rect(p[0]+1,p[1]+1,p[2]-2,1,Wd[4]);b.rect(p[0]+1,p[1]+1,1,p[3]-2,Wd[4]);});
    b.rect(166,87,2,2,RP.yel[2]);}
  // two hanging plants
  [72,150].forEach(x=>{b.rect(x,33,1,7,OUT);b.ell(x,45,7,5,RP.grn);b.ell(x-6,48,4,4,RP.grn);b.ell(x+6,48,4,4,RP.grn);b.rect(x-3,40,7,4,RP.orng[2]);b.rect(x-3,40,7,1,RP.orng[4]);b.frame(x-4,39,9,6,OUT);});
  // the posts and the roof
  [34,198].forEach(x=>{b.grad(x,36,8,112,[C[4],C[3],C[2]],true);b.frame(x-1,35,10,114,OUT);b.rect(x-2,147,12,6,C[3]);b.rect(x-2,147,12,1,C[4]);b.frame(x-3,146,14,8,OUT);b.rect(x-2,34,12,3,C[3]);b.frame(x-3,33,14,5,OUT);});
  for(let y=0;y<28;y++){const t=y/27,xl=Math.round(40-22*t),xr=Math.round(200+22*t),k=y%5,rw=Math.floor(y/5);
    for(let x=xl;x<=xr;x++)b.px(x,y,x===xl||x===xr||y===27?"#4A1210":k===4?RP.red[0]:(x+rw*4)%8===0?RP.red[1]:bay(x,y)<t*.8?RP.red[2]:RP.red[3]);}
  b.rect(17,28,206,5,C[3]);b.rect(17,32,206,1,C[1]);b.frame(16,27,208,7,OUT);
  const out=b.done(),x=b.cx;x.drawImage(spr("bush",mkBush),14,158);x.drawImage(spr("bush",mkBush),190,158);
  return out;}

/* ---------- the furniture ---------- */
function mkSillaG(){const b=new Buf(40,48),Wd=RP.wood;   // abuela's big wooden chair, with a woven back
  b.rect(3,31,4,16,Wd[1]);b.rect(33,31,4,16,Wd[1]);b.rect(7,40,26,2,Wd[0]);
  b.rect(3,2,4,30,Wd[2]);b.rect(33,2,4,30,Wd[2]);b.rect(3,2,1,30,Wd[4]);b.rect(33,2,1,30,Wd[4]);
  b.rect(7,5,26,20,"#EAD9A8");for(let y=5;y<25;y+=2)for(let x=7+(y%4?1:0);x<33;x+=2)b.px(x,y,"#C9A866");
  b.rect(2,0,36,5,Wd[2]);b.rect(2,0,36,1,Wd[4]);b.rect(2,4,36,1,Wd[0]);b.rect(7,25,26,2,Wd[1]);
  b.rect(0,20,6,3,Wd[3]);b.rect(34,20,6,3,Wd[3]);b.rect(0,20,6,1,Wd[4]);b.rect(34,20,6,1,Wd[4]);
  b.rect(1,29,38,5,Wd[3]);b.rect(1,29,38,1,Wd[4]);b.rect(1,33,38,1,Wd[0]);
  return b.outline().done();}
function mkSillaP(){const b=new Buf(24,30),Y=RP.yel;   // a small yellow chair
  b.rect(3,17,3,12,Y[0]);b.rect(18,17,3,12,Y[0]);b.rect(6,23,12,2,Y[0]);
  b.rect(3,0,3,17,Y[2]);b.rect(18,0,3,17,Y[2]);b.rect(3,0,1,17,Y[4]);b.rect(18,0,1,17,Y[4]);
  b.rect(6,2,12,3,Y[2]);b.rect(6,2,12,1,Y[4]);b.rect(6,8,12,3,Y[2]);b.rect(6,8,12,1,Y[4]);
  b.rect(1,14,22,4,Y[3]);b.rect(1,14,22,1,Y[4]);b.rect(1,17,22,1,Y[0]);
  return b.outline().done();}
function mkMesa(){const b=new Buf(52,24),Wd=RP.wood;   // a small round table
  b.rect(24,6,4,14,Wd[1]);b.rect(24,6,1,14,Wd[3]);b.rect(14,20,24,3,Wd[1]);b.rect(14,20,24,1,Wd[3]);
  b.ell(26,3.5,25,3.5,[Wd[4],Wd[4],Wd[3]]);b.rect(2,5,48,2,Wd[2]);b.rect(4,7,44,1,Wd[0]);
  return b.outline().done();}
// a glass: t = n (plain), g (big), p (small); k = jugo or agua; lv = how full, 0 to 1
const VT={n:[9,13],g:[11,17],p:[7,9]};
function vaso(g,cx,by,t,k,lv){const w=VT[t][0],h=VT[t][1],x=Math.round(cx-w/2),y=by-h,col=k==="agua"?AGUA:JUGO,n=Math.round((h-3)*Math.max(0,Math.min(1,lv)));
  fr(g,x-1,y,w+2,h,OUT);fr(g,x,y+h,w,1,OUT);fr(g,x,y,w,h,"#F4FAFF");
  if(n>0){fr(g,x,y+h-1-n,w,n,col[1]);fr(g,x,y+h-1-n,w,1,col[2]);fr(g,x+w-2,y+h-n,1,n-1,col[0]);
    if(k==="agua"&&n>4){fr(g,x+2,y+h-n+1,2,2,"#FFFFFF");if(w>7)fr(g,x+w-4,y+h-n+3,2,2,"#FFFFFF");}}   // ice in the water
  fr(g,x,y+h-1,w,1,"#C8DDF2");fr(g,x+1,y+1,1,h-3,"#FFFFFF");
  if(k==="jugo"&&lv>0){fr(g,x+w-3,y-4,1,5,OUT);fr(g,x+w-2,y-4,1,5,"#EC6050");fr(g,x+w-1,y-4,1,5,OUT);fr(g,x+w-3,y-5,3,1,OUT);}}   // a straw in the juice
// a jug: orange for juice, clear blue for water. A narrow neck with a spout, a wide belly, a handle.
function jarra(g,cx,by,k){const col=k==="agua"?AGUA:JUGO,x=cx-6,y=by-21,G="#F4FAFF";
  fr(g,x+1,y,9,7,OUT);fr(g,x-2,y,4,3,OUT);fr(g,x-1,y+6,13,15,OUT);fr(g,x,y+21,11,1,OUT);                 // outline: neck, spout, belly
  fr(g,x+11,y+7,4,2,OUT);fr(g,x+14,y+8,2,8,OUT);fr(g,x+11,y+15,4,2,OUT);                                 // handle
  fr(g,x+2,y+1,7,6,G);fr(g,x-1,y+1,3,1,G);fr(g,x,y+7,11,13,G);fr(g,x+12,y+8,2,1,G);fr(g,x+14,y+9,1,6,G);fr(g,x+12,y+15,2,1,G);
  fr(g,x,y+9,11,11,col[1]);fr(g,x,y+9,11,1,col[2]);fr(g,x+9,y+10,2,10,col[0]);fr(g,x+1,y+8,1,11,"#FFFFFF");fr(g,x+3,y+2,1,4,"#FFFFFF");
  if(k==="agua"){fr(g,x+3,y+11,2,2,"#FFFFFF");fr(g,x+6,y+14,2,2,"#FFFFFF");}else{fr(g,x+4,y+12,3,3,JUGO[2]);fr(g,x+5,y+13,1,1,JUGO[0]);}}   // ice in the water; a slice of orange in the juice

/* ---------- where things are ---------- */
const X2=[108,132],X4=[101,113,127,139],MESA_Y=128,SILLA=[48,102],SILLITA=[148,120],ABS=[51,96],PERCH=[120,86],ASIENTO=[160,135];
const AB={puerta:[178,125],mesa:[158,141],lado:[94,147]};                                  // where abuela stands (her feet)
const LUGAR={jardin:[104,185,1],balcon:[106,130,.8],mesa:[106,130,.8],junto:[118,130,.8],decir:[134,130,.8],silla_pequena:[144,109,.72],suelo:[150,132,.8],abuela:[84,129,.8],silla_grande:[84,129,.8],puerta:[162,125,.76],ventana:[106,130,.8]};
const IDS=["jugo","agua","vaso_silla","vaso_mesa","vaso_grande","vaso_pequeno"];
const enMesa=id=>(W.vasos||[]).find(v=>v.id===id)||(W.jarras||[]).find(v=>v.id===id);
const cajaDe=v=>{if(v.t){const s=VT[v.t],y=v.y||MESA_Y;return [Math.round(v.x-s[0]/2)-4,y-s[1]-6,s[0]+8,s[1]+9];}return [v.x-9,MESA_Y-24,26,27];};
const cosaMesa=id=>({id,m:0,si:w=>!!enMesa(id)&&!enMesa(id).mano,box:()=>cajaDe(enMesa(id))});
const abCaja=w=>w.ab.en==="silla"?[55,96,34,50]:[Math.round(w.ab.x)-13,Math.round(w.ab.y)-50,26,50];
const COSAS=IDS.map(cosaMesa).concat([
  {id:"abuela",si:w=>!!w.ab&&w.ab.al>.5,box:abCaja,m:1},
  {id:"mesa",box:[94,124,52,25],m:0},{id:"silla_pequena",box:[SILLITA[0],SILLITA[1],24,30],m:2},{id:"silla_grande",box:[SILLA[0],SILLA[1],40,48],m:2},
  {id:"puerta",box:[162,54,32,68],m:2,hand:[178,84]},{id:"ventana",box:[93,54,54,36],m:1,hand:[120,70]},{id:"balcon",box:[42,122,156,34],m:0}]);

/* ---------- drawing ---------- */
GL.sol=["...#...",".#.#.#.","..###..","#######","..###..",".#.#.#.","...#..."];GC.sol="#F0A010";
GL.jugo=["o...o","o###o","o###o","o###o","o###o","o###o",".ooo."];GC.jugo=JUGO[1];
GL.agua=["o...o","obbbo","obbbo","obbbo","obbbo","obbbo",".ooo."];GC.agua=AGUA[0];
GL.equis=["#...#",".#.#.","..#..",".#.#.","#...#"];GC.equis="#D0403A";
Object.assign(BUBL,{calor:["sol","sad"],no:["equis"],q:["q"],quiere_agua:["agua"],no_jugo_si_agua:["jugo","equis","agua"],jugo_q:["jugo","q"],agua_q:["agua","q"],feliz:["ok"]});
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui")&&a%2?1:0,sent=Math.abs(q.x-LUGAR.silla_pequena[0])<3&&Math.abs(q.y-LUGAR.silla_pequena[1])<3&&!q.dy;
  if(!sent){const col=q.y>158?"#1E5A2A":"#A8875A";for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5-(j===1?0:2);i++)if((i+j)%2===0)fr(g,b.x+2+i,q.y+25+j,1,1,col);}
  g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+Math.round(q.dy));}
function draw(c,W,a){const q=W.cq,ab=W.ab;
  c.drawImage(spr("bal"+W.door+"_"+W.win,()=>bg(W.door,W.win)),0,0);
  const habla=ab&&(TALK==="abuela"&&a%2)?1:0;
  const dePie=()=>{const pose=ab.pose==="wave"?"wave"+(a%2):(ab.pose==="offer"||ab.trae)?"offer":"idle",x=Math.round(ab.x)-30,y=Math.round(ab.y)-50;c.globalAlpha=ab.al==null?1:ab.al;
    if(ab.en==="puerta"){c.save();c.beginPath();c.rect(165,57,24,69);c.clip();c.drawImage(spr("ab"+pose+habla,()=>mkAbuela(pose,habla)),x,y);c.restore();}else c.drawImage(spr("ab"+pose+habla,()=>mkAbuela(pose,habla)),x,y);
    if(ab.trae){fr(c,x+1,y+26,22,3,OUT);fr(c,x+2,y+26,20,2,RP.wood[3]);vaso(c,x+7,y+26,"n","jugo",1);vaso(c,x+18,y+26,"n","agua",1);}c.globalAlpha=1;};
  if(ab&&ab.en!=="silla"&&ab.y<144)dePie();                                             // behind the furniture
  c.drawImage(spr("sillaG",mkSillaG),SILLA[0],SILLA[1]);
  if(ab&&ab.en==="silla"){const f=ab.pose==="fan"?"fan"+((F>>2)%2):ab.pose,pose=["fan0","fan1","vaso","bebe","zzz"].includes(f)?f:"idle";
    c.drawImage(spr("abS"+pose+habla,()=>KIT.mkAbuelaS(pose,habla,0)),ABS[0],ABS[1]);
    if(W.abvaso){const bb=ab.pose==="bebe";vaso(c,ABS[0]+(bb?30:36),ABS[1]+(bb?17:28),"n",W.abvaso.k,W.abvaso.lv);}
    if(W.sobre){jarra(c,ABS[0]+19,ABS[1]-4,"agua");}
    for(let k=0;k<(W.sudor||0);k++)fr(c,ABS[0]+6+k*11,ABS[1]+5+((F+k*5)%9),1,2,"#8CC4F8");}   // she is hot: drops of sweat
  c.drawImage(spr("sillaP",mkSillaP),SILLITA[0],SILLITA[1]);
  c.drawImage(spr("mesa",mkMesa),94,125);
  (W.vasos||[]).forEach(v=>{if(!v.mano)vaso(c,v.x,v.y||MESA_Y,v.t,v.k,v.lv);});
  if(W.fanMesa)medio(c,121,MESA_Y,0);
  if(W.enSuelo)[[100,152,"#FFE070"],[108,154,"#FF8FB8"]].forEach(d=>{fr(c,d[0]-1,d[1]-1,7,5,OUT);fr(c,d[0],d[1],5,3,d[2]);});   // the two halves of her fan, on the floor
  (W.jarras||[]).forEach(v=>{if(!v.mano)jarra(c,v.x,MESA_Y,v.k);});
  if(ab&&ab.en!=="silla"&&ab.y>=144)dePie();
  if(W.trozos&&F-W.trozos<14){const t=F-W.trozos;[[-3,"#FFE070"],[4,"#FF8FB8"]].forEach((d,i)=>{fr(c,ABS[0]+32+d[0]*(1+t/3),ABS[1]+8+t*3,4,5,OUT);fr(c,ABS[0]+33+d[0]*(1+t/3),ABS[1]+9+t*3,2,3,d[1]);});}   // the two halves of her paper fan fall
  if(q.vis){c.globalAlpha=q.al;rana(c,q,a);c.globalAlpha=1;const b=frogBox(q),dy=Math.round(q.dy);
    for(let k=0;k<(W.calor||0);k++){const x=b.x+3+k*Math.round(b.w/3),y=b.y-5+((F+k*4)%10);fr(c,x-1,y,3,3,"#2E6CD0");fr(c,x,y-1,1,4,"#8CC4F8");}   // drops of sweat: one for every drink he still needs
    if(W.cqfan)medio(c,b.x-3,b.y+dy+Math.round(b.h*.55),(F>>2)%2?1:-1);   // his half of the fan: he keeps it, and fans himself
    if(W.hielo){fr(c,b.x+Math.round(b.w/2)-4,b.y+dy-5,8,7,OUT);fr(c,b.x+Math.round(b.w/2)-3,b.y+dy-4,6,5,"#DCEEFF");fr(c,b.x+Math.round(b.w/2)-2,b.y+dy-3,2,2,"#FFFFFF");}   // an ice cube on his head
    const m=(W.vasos||[]).find(v=>v.mano);if(m)vaso(c,b.x+b.w+1,b.y+dy+Math.round(b.h*.8),m.t,m.k,m.lv);
    const j=(W.jarras||[]).find(v=>v.mano===1);if(j)jarra(c,Math.round(b.x+b.w/2),b.y+dy+1,j.k);}
  if(W.vierte){const x=ABS[0]+36,y0=ABS[1]+8;for(let i=0;i<7;i++)fr(c,x,y0+((i*2+F)%12),1,2,W.vierte==="agua"?AGUA[1]:JUGO[1]);}   // pouring into her glass
  KIT.drawAve(c,W.ave);
  if(W.splash){const t=F-W.splash;for(let i=0;i<14;i++){const x=ABS[0]+5+(i*37)%26,y=ABS[1]-2+((t*4+i*9)%42);fr(c,x,y,1,3,AGUA[1]);}}   // water over her own head
  if(W.rojo&&F-W.rojo<5){c.fillStyle="rgba(255,90,40,.28)";c.fillRect(0,0,SW,SH);}
  if(W.azul&&F-W.azul<5){c.fillStyle="rgba(90,170,255,.22)";c.fillRect(0,0,SW,SH);}
  if(ab&&ab.bub){const at=talkAt("abuela",W);bub(c,ab.bub,at[0],at[1]+20,a);}
  if(q.vis&&q.bub){const b=frogBox(q);bub(c,q.bub,b.x+(b.w>>1),b.y,a);}
}
function talkAt(k,W){if(k!=="abuela"||!W.ab||W.ab.al<.5)return null;const ab=W.ab;
  return ab.en==="silla"?[ABS[0]+17,ABS[1]-(ab.bub?21:1)]:[Math.round(ab.x),Math.round(ab.y)-51-(ab.bub?20:0)];}
// the picture answers of the Say move: a glass of juice, a glass of water
function respIcon(g,k,x,y,w,h){vaso(g,x+w/2,y+h-7,"g",k,1);}

/* ---------- what is at stake, in the corner of the screen ---------- */
function mini(g,x,y){fr(g,x-1,y,10,13,OUT);fr(g,x,y+13,8,1,OUT);fr(g,x,y,8,13,"#F4FAFF");fr(g,x,y+3,8,9,AGUA[1]);fr(g,x,y+3,8,1,AGUA[2]);fr(g,x+1,y+1,1,10,"#FFFFFF");}
function tanteo(g,x,y,n,who){const ic=who==="cq"?spr("cq.7_0",()=>mkCoqui(.7,0,0)):spr("kaven0",()=>KIT.mkAve("n",0)),gx=who==="cq"?x+27:x+2,ix=who==="cq"?x:x+41;
  g.fillStyle="rgba(14,26,36,.6)";g.fillRect(x-3,y-3,who==="cq"?67:65,25);g.drawImage(ic,ix,y+(who==="cq"?0:3));
  for(let i=0;i<3;i++){if(i<n)mini(g,gx+i*12,y+3);else{g.fillStyle="rgba(255,255,255,.3)";g.fillRect(gx+i*12,y+4,8,12);}}}
const nivel=W=>Math.max(0,Math.min(4,2+(W.lost||0)-(W.fresco||0)));   // how hot abuela is: every drink brings it down, every wrong move sends it up
function termo(g,x,y,n,a){const hot=n>=3&&a%2,m=Math.min(3,n),red=hot?"#FF7A60":"#E8443C";g.fillStyle="rgba(14,26,36,.6)";g.fillRect(x-4,y-4,42,52);
  fr(g,x+1,y-1,10,35,OUT);fr(g,x+2,y,8,34,"#FFFFFF");g.fillStyle=OUT;g.beginPath();g.arc(x+6,y+36,8,0,7);g.fill();g.fillStyle=red;g.beginPath();g.arc(x+6,y+36,6.5,0,7);g.fill();
  const hgt=[3,10,17,24,31][n];fr(g,x+4,y+32-hgt,4,hgt+2,red);for(let i=0;i<5;i++)fr(g,x+10,y+1+i*7,3,1,OUT);   // five marks; it starts on the third
  const sx=x+26,sy=y+13,r=4+m;g.fillStyle=OUT;g.beginPath();g.arc(sx,sy,r+1,0,7);g.fill();g.fillStyle=n>=3?"#FF8A20":n?"#FFC030":"#FFE680";g.beginPath();g.arc(sx,sy,r,0,7);g.fill();
  if(n)for(let k=0;k<8;k++){const an=k*Math.PI/4+(a%2?.2:0);fr(g,Math.round(sx+Math.cos(an)*(r+3))-1,Math.round(sy+Math.sin(an)*(r+3))-1,2,2,n>=3?"#FF8A20":"#FFC030");}}
// half a paper fan
function medio(g,x,y,d){for(let k=-2;k<=2;k++){const ex=x+k*2+d,ey=y-7+Math.abs(k);for(let t=0;t<=6;t++)fr(g,Math.round(x+(ex-x)*t/6),Math.round(y+(ey-y)*t/6),1,1,k%2?"#FFE070":"#FF8FB8");}fr(g,x-4+d,y-7,9,1,"#D0403A");fr(g,x,y,1,2,OUT);}
function hud(g,W,a){if(W.rondas){tanteo(g,6,6,W.mios||0,"cq");tanteo(g,DW-65,6,W.lost||0,"ave");}if(W.termo)termo(g,8,8,nivel(W),a);}

/* ---------- what can happen here ---------- */
const glu=()=>tone(300,0,.09,"sine",.09,170),chorro=()=>{for(let i=0;i<4;i++)tone(700+i*90,i*.07,.08,"sine",.05,500);},azar=()=>Math.random()<.5;
async function abCamina(tx,ty){const ab=W.ab;if(ab.en==="silla"){ab.x=AB.lado[0];ab.y=AB.lado[1];}ab.en="camina";if(ab.pose!=="offer")ab.pose="idle";const x0=ab.x,y0=ab.y,n=Math.max(3,Math.round(Math.hypot(tx-x0,ty-y0)/6));
  for(let i=1;i<=n;i++){ab.x=x0+(tx-x0)*i/n;ab.y=y0+(ty-y0)*i/n-(i%2);await wait(TICK);}ab.x=tx;ab.y=ty;}
// the glasses abuela fills: one is his, one is hers. Where each one stands is drawn fresh.
function dos(que){const s=azar()?0:1,g=(id,k,t,x,y)=>({id,k,t,lv:1,x,y});
  if(que==="gp")return [g("vaso_grande","jugo","g",X2[s]),g("vaso_pequeno","jugo","p",X2[1-s])];
  if(que==="sm")return [g("vaso_silla","agua","n",ASIENTO[0],ASIENTO[1]-1),g("vaso_mesa","agua","n",120)];   // one on the small chair, one on the table
  if(que==="fin")return [g("fin1","agua","n",X2[0]),g("fin2","agua","n",X2[1])];
  return [g("jugo","jugo","n",X2[s]),g("agua","agua","n",X2[1-s])];}
const brillo=()=>fx({t:"star",n:8,pts:(W.vasos||[]).map(v=>[v.x,(v.y||MESA_Y)-20])});
const acts={
  async sube(){await hopTo(LUGAR.jardin[0],168,1,.9);await hopTo(LUGAR.balcon[0],LUGAR.balcon[1],2,LUGAR.balcon[2]);},
  // abuela walks to her chair and sits down
  async absienta(){const ab=W.ab;if(ab.en==="silla")return;ab.pose="idle";ab.trae=0;await abCamina(AB.lado[0],AB.lado[1]);await wait(150);ab.en="silla";SFX.blip();await wait(450);},
  // she gets up and goes in through the door
  async abentra(){const ab=W.ab;await abCamina(AB.puerta[0],AB.puerta[1]);ab.en="puerta";for(let i=4;i>=0;i--){ab.al=i/5;await wait(TICK);}await wait(200);},
  // and comes back with two glasses for the table
  async absale(){const ab=W.ab;ab.trae=1;ab.en="puerta";for(let i=1;i<=5;i++){ab.al=i/5;await wait(TICK);}await abCamina(AB.mesa[0],AB.mesa[1]);await wait(200);},
  async pone2(){W.ab.trae=0;W.vasos=dos("ja");SFX.blip();brillo();await wait(450);},
  // she fills fresh glasses
  async sirve(o){if(W.ab&&W.ab.en==="silla")W.ab.pose="vaso";W.vasos=dos(o.que);chorro();brillo();await wait(650);},
  // the frog picks a glass up from the table, puts it back, or drinks the one he holds
  async coge(o){const v=enMesa(o.en);await acts.ir({a:v&&v.y?"junto":"mesa"});if(!v)return;await wait(120);v.mano=1;SFX.blip();await wait(350);},
  async suelta(){const v=(W.vasos||[]).find(x=>x.mano);if(v){await wait(150);v.mano=0;SFX.blip();await wait(250);}},
  async bebecq(){const v=(W.vasos||[]).find(x=>x.mano);if(!v)return;for(const l of [.66,.33,0]){v.lv=l;glu();bounce(3);await wait(300);}W.calor=Math.max(0,(W.calor||0)-1);W.azul=F;await wait(200);v.mano=0;await wait(200);},
  // abuela takes a glass (from the table, or back out of the frog's hand) and drinks it: that one was hers
  async abcoge(o){const v=(W.vasos||[]).find(x=>x.id===o.en);if(!v)return;await wait(150);W.vasos=W.vasos.filter(x=>x!==v);W.ab.pose="vaso";W.abvaso={k:v.k,lv:v.lv};SFX.blip();await wait(350);},
  async abbebe(){const ab=W.ab;if(!W.abvaso)return;ab.pose="bebe";for(const l of [.66,.33,0]){W.abvaso.lv=Math.min(W.abvaso.lv,l);glu();await wait(300);}ab.pose="vaso";await wait(250);W.abvaso=null;},
  async aveventana(){if(W.ave&&W.ave.mode!=="none"&&Math.abs(W.ave.x-PERCH[0])+Math.abs(W.ave.y-PERCH[1])>3){await KIT.aveVa(PERCH[0],PERCH[1],9,-1);await wait(200);}},
  // the bird flies down beside a glass, drinks it, and goes to sit on the small chair
  async aveva(o){const v=(W.vasos||[]).find(x=>x.id===o.en);if(!v)return;const lado=v.x<120?1:-1;await KIT.aveVa(v.x+lado*15,v.y||MESA_Y,9,-lado);SFX.pio();await wait(250);},
  async avebebe(o){const v=(W.vasos||[]).find(x=>x.id===o.en),a=W.ave;if(!v||!a)return;for(const l of [.66,.33,0]){a.dip=3;v.lv=l;glu();await wait(240);a.dip=0;await wait(160);}a.st="feliz";SFX.pio();await wait(450);a.st="n";},
  async avesilla(){await KIT.aveVa(ASIENTO[0],ASIENTO[1],9,-1);SFX.pio();await wait(350);},
  async gana(){W.mios=(W.mios||0)+1;SFX.right();W.cq.bub="amor";await wait(800);W.cq.bub=null;},
  // the ending of El jugo: who drank more decides who gets the small chair
  async marcador(){const a=W.ave,mio=W.mios||0,suyo=W.lost||0,gano=mio>suyo,amigo=V.mem_amigo==="1";if(W.ab)W.ab.pose="idle";W.vasos=[];await camGo("wide",9);
    if(gano||amigo){if(a)await acts.aveventana();await acts.ir({a:"silla_pequena"});
      if(gano){W.heart=1;SFX.win();if(mio>=3)fx({t:"star",n:30,pts:[[60,50],[180,54],[120,42],[96,64],[150,60]]});}else{W.cq.bub="amor";SFX.coqui();}}
    else{if(a){await KIT.aveVa(ASIENTO[0],ASIENTO[1],9,-1);a.st="round";SFX.pio();}await acts.ir({a:"balcon"});W.cq.bub="mal";SFX.coqui();}
    await wait(1500);W.cq.bub=null;},
  /* ---- story 5: abuela is hot ---- */
  // the frog carries a jug to her and fills her glass
  async lleva(o){const j=enMesa(o.en);if(!j)return;await acts.ir({a:"mesa"});await wait(120);j.mano=1;SFX.blip();await wait(250);await acts.ir({a:"abuela"});W.ab.pose="vaso";W.abvaso={k:o.en,lv:0};await wait(200);
    W.vierte=o.en;chorro();for(const l of [.4,.7,1]){W.abvaso.lv=l;await wait(170);}W.vierte=null;await wait(250);await acts.ir({a:"mesa"});j.mano=0;await wait(150);await acts.ir({a:"decir"});},
  // she drinks, and cools down a step
  async bebe(){const ab=W.ab;if(!W.abvaso)return;ab.pose="bebe";for(const l of [.66,.33,0]){W.abvaso.lv=l;glu();await wait(330);}ab.pose="vaso";W.fresco=(W.fresco||0)+1;W.azul=F;W.sudor=Math.min(3,nivel(W));SFX.luz();await wait(500);W.abvaso=null;ab.pose=W.abanico?"fan":"idle";},
  // she will not drink that one: she puts the glass down on the table, and it stays there
  async aparta(){if(!W.abvaso)return;const k=W.abvaso.k;await wait(300);W.abvaso=null;W.vasos.push({id:"aparte",k,t:"n",lv:1,x:120});SFX.blip();await wait(400);W.ab.pose=W.abanico?"fan":"idle";},
  // the frog, eager, holds up a jug to show her; then puts it back
  async muestra(o){const j=enMesa(o.en);if(!j)return;await acts.ir({a:"mesa"});await wait(120);j.mano=1;SFX.blip();bounce(4);await wait(300);},
  async deja(){(W.jarras||[]).forEach(j=>{if(j.mano===1)j.mano=0;});SFX.blip();await wait(250);await acts.ir({a:"decir"});},
  // he picks up the two halves of her fan and gives them to her. She fans herself with one half, and keeps it.
  async recoge(){await acts.ir({a:"abuela"});await wait(150);W.enSuelo=0;SFX.blip();bounce(4);await wait(350);W.abanico=1;W.ab.pose="fan";SFX.luz();await wait(450);await acts.ir({a:"decir"});},
  // her paper fan tears in two
  // she hands him the other half; or, after a wrong answer, it is left on the table
  async dafan(){await acts.ir({a:"abuela"});W.ab.bub="amor";await wait(300);W.cqfan=1;SFX.luz();bounce(5);await wait(600);W.ab.bub=null;await acts.ir({a:"decir"});},
  async fanmesa(){W.fanMesa=1;SFX.blip();await wait(500);},
  async rompe(){W.abanico=0;W.ab.pose="idle";W.trozos=F;tone(900,0,.12,"sawtooth",.05,200);tone(500,.1,.15,"sawtooth",.04,120);W.sudor=2;await wait(950);W.enSuelo=1;await wait(300);},
  // she fills a glass for the frog and holds it out; he takes it
  async ofrece(o){W.ab.pose="vaso";W.abvaso={k:o.en,lv:1};chorro();await wait(500);},
  async recibe(){await acts.ir({a:"abuela"});const k=W.abvaso?W.abvaso.k:"agua";W.abvaso=null;W.ab.pose=W.abanico?"fan":"idle";W.vasos.push({id:"mio",k,t:"n",lv:1,x:132,mano:1});SFX.blip();await wait(250);await acts.ir({a:"decir"});},
  // the two jugs on the table. Which side each is on is drawn fresh.
  async pone(){const s=azar()?0:1;W.jarras=[{id:"jugo",k:"jugo",x:X2[s]},{id:"agua",k:"agua",x:X2[1-s]}];},
  async cqbebe(){const v=(W.vasos||[]).find(x=>x.mano);if(!v)return;for(const l of [.66,.33,0]){v.lv=l;glu();bounce(3);await wait(300);}W.vasos=W.vasos.filter(x=>x!==v);W.cq.bub="amor";await wait(600);W.cq.bub=null;},
  async cqhielo(){const v=(W.vasos||[]).find(x=>x.mano);if(!v)return;for(const l of [.66,.33,0]){v.lv=l;glu();bounce(3);await wait(300);}W.vasos=W.vasos.filter(x=>x!==v);W.hielo=1;SFX.luz();bounce(6);await wait(700);},   // he drinks the water, and an ice cube ends up on his head
  // the last picture, by how hot it got
  async final(){const ab=W.ab,n=nivel(W);
    if(n<=0){ab.pose="idle";W.sudor=0;ab.bub="feliz";await wait(1100);ab.bub=null;}
    else if(n===1){ab.pose=W.abanico?"fan":"idle";W.sudor=0;await wait(900);}
    else if(n===2){ab.pose=W.abanico?"fan":"idle";W.sudor=1;await wait(1000);}
    else{const j=(W.jarras||[]).find(v=>v.k==="agua");if(j)j.mano=2;W.sobre=1;await wait(500);W.splash=F;chorro();SFX.drop();await wait(300);SFX.drop();W.sudor=0;await wait(1100);W.splash=0;W.sobre=0;if(j)j.mano=0;ab.bub="feliz";await wait(700);ab.bub=null;}},
  async fin(){if(S.stake.thing==="calor"?nivel(W)<=0:(W.mios||0)>(W.lost||0)){W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[60,50],[180,54],[120,42],[96,64],[150,60]]});}else SFX.coqui();await wait(1600);}
};
// the thing at stake takes a step: the bird gets a glass, or the heat climbs
async function stake(lost,max,en){if(S.stake.thing==="calor"){W.rojo=F;W.sudor=Math.min(3,nivel(W));tone(400,0,.4,"sawtooth",.03,1200);await wait(800);return;}   // she waits; the sun flares; the thermometer climbs
  SFX.munch();await wait(450);}
function poke(what){if(what==="pajaro")SFX.pio();
  else if(what==="abuela"&&W.ab&&!W.ab.bub){W.ab.bub="amor";const my=runId;setTimeout(()=>{if(my===runId&&W.ab&&W.ab.bub==="amor")W.ab.bub=null;},1500/FAST);}}
const estado=W=>"vasos="+(W.vasos||[]).map(v=>v.id+"@"+v.x+":"+v.lv+(v.mano?"m":"")).join(",")+" jarras="+(W.jarras||[]).map(v=>v.id+(v.mano?"m":"")).join(",")+" mios="+(W.mios||0)+" abvaso="+(W.abvaso?W.abvaso.k+":"+W.abvaso.lv:"-")+" nivel="+nivel(W)+" abanico="+(W.abanico||0)+" suelo="+(W.enSuelo||0)+" hielo="+(W.hielo||0)+" cqfan="+(W.cqfan||0)+" fanMesa="+(W.fanMesa||0)+" calor="+(W.calor||0)+" sudor="+(W.sudor||0)+" splash="+(W.splash?1:0)+" ave="+(W.ave?W.ave.mode+"/"+(W.ave.st||"")+"@"+Math.round(W.ave.x)+","+Math.round(W.ave.y):"-");

KIT.escena({id:"balcon",CAM:{wide:[22,0,196,216],mesa:[50,36,127,140],porche:[35,20,170,187.3]},heartAt:[107,31],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({door:0,win:0,ab:{en:"puerta",x:AB.puerta[0],y:AB.puerta[1],pose:"idle",bub:null,al:1,trae:0},ave:null,vasos:[],jarras:[],abvaso:null,vierte:null,sobre:0,abanico:0,trozos:0,enSuelo:0,hielo:0,cqfan:0,fanMesa:0,
    calor:0,fresco:0,sudor:0,rojo:0,azul:0,splash:0,rondas:0,mios:0,termo:0,cq:{x:LUGAR.jardin[0],y:LUGAR.jardin[1],s:1,dy:0,al:1,vis:1,bub:null}}),
  draw,hud,poke,acts,stake,talkAt,respIcon,estado});
})();
