const BAY=[0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5],bay=(x,y)=>(BAY[(y&3)*4+(x&3)]+.5)/16,_rgb={};
function rgb(h){return _rgb[h]||(_rgb[h]=[parseInt(h.slice(1,3),16),parseInt(h.slice(3,5),16),parseInt(h.slice(5,7),16)]);}
function hs(x,y){let n=(Math.imul(x,374761393)+Math.imul(y,668265263))|0;n=Math.imul(n^(n>>>13),1274126177);return((n^(n>>>16))>>>0)%100;}
const RP={tan:["#7A4A1E","#A8682C","#C8853C","#E2A85A","#F4CC88"],cream:["#B89A6A","#D8BC8A","#EEDCB0","#FBF0D2","#FFFBEA"],skin:["#7A4A2A","#9A6238","#B87A48","#D09460","#E4B080"],
  grey:["#6E6E80","#9494A6","#B8B8C8","#D8D8E4","#F2F2F8"],purp:["#4A2468","#6A3690","#8A4CB4","#A868D0","#C890E8"],grn:["#14532D","#1E7A3A","#2E9A48","#4CBC58","#84DC78"],
  red:["#7A1C1C","#A82A26","#D0403A","#EC6050","#FA9080"],teal:["#1A6E70","#249094","#34B0B0","#5CCCC8","#98E6DE"],wood:["#4A2A14","#6E4220","#92602E","#B88040","#D8A460"],
  blue:["#1E4FA8","#2E6CD0","#4A8CE8","#78B0F6","#B0D4FF"],yel:["#B87A10","#E0A020","#F8C838","#FFE070","#FFF4B0"],stone:["#6A5E50","#8E806C","#B4A68E","#D4C8B0","#EEE6D4"],
  orng:["#8A4212","#B8601C","#DC8430","#F2A650","#FBCB86"],sky:["#3A86E6","#559FF2","#78BAFA","#A2D3FF","#D0EAFF"],cloud:["#B4CCEA","#D6E6F8","#F0F7FF","#FFFFFF","#FFFFFF"],
  grass:["#62CC5A","#52BC4C","#44AA42","#389838","#2E8A34"]},OUT="#2A1810";
class Buf{
  constructor(w,h){this.w=w;this.h=h;this.cv=document.createElement("canvas");this.cv.width=w;this.cv.height=h;this.cx=this.cv.getContext("2d");this.im=this.cx.createImageData(w,h);this.d=this.im.data;}
  px(x,y,c){x=Math.floor(x);y=Math.floor(y);if(x<0||y<0||x>=this.w||y>=this.h)return;const v=rgb(c),i=(y*this.w+x)*4,d=this.d;d[i]=v[0];d[i+1]=v[1];d[i+2]=v[2];d[i+3]=255;}
  has(x,y){return x>=0&&y>=0&&x<this.w&&y<this.h&&this.d[(y*this.w+x)*4+3]>0;}
  rect(x,y,w,h,c){x=Math.round(x);y=Math.round(y);for(let j=0;j<h;j++)for(let i=0;i<w;i++)this.px(x+i,y+j,c);}
  ell(cx,cy,rx,ry,r){const n=r.length;for(let y=Math.floor(cy-ry);y<=Math.ceil(cy+ry);y++)for(let x=Math.floor(cx-rx);x<=Math.ceil(cx+rx);x++){
      const nx=(x+.5-cx)/rx,ny=(y+.5-cy)/ry,dd=nx*nx+ny*ny;if(dd>1)continue;if(n===1){this.px(x,y,r[0]);continue;}
      const v=(-nx*.5-ny*.62+Math.sqrt(1-dd)*.6)*.8+.22,i=Math.floor(Math.max(0,Math.min(.999,v))*(n-1)+bay(x,y));this.px(x,y,r[Math.max(0,Math.min(n-1,i))]);}}
  grad(x,y,w,h,r,hz){const n=r.length;for(let j=0;j<h;j++)for(let i=0;i<w;i++){const t=hz?i/w:j/h;this.px(x+i,y+j,r[Math.min(n-1,Math.floor(Math.min(.999,t)*(n-1)+bay(x+i,y+j)))]);}}
  cap(x0,y0,x1,y1,rad,r){const n=Math.max(1,Math.ceil(Math.hypot(x1-x0,y1-y0)));for(let i=0;i<=n;i++)this.ell(x0+(x1-x0)*i/n,y0+(y1-y0)*i/n,rad,rad,r);}
  line(x0,y0,x1,y1,c){const n=Math.max(1,Math.ceil(Math.max(Math.abs(x1-x0),Math.abs(y1-y0))));for(let i=0;i<=n;i++)this.px(Math.round(x0+(x1-x0)*i/n),Math.round(y0+(y1-y0)*i/n),c);}
  frame(x,y,w,h,c){this.rect(x,y,w,1,c);this.rect(x,y+h-1,w,1,c);this.rect(x,y,1,h,c);this.rect(x+w-1,y,1,h,c);}
  outline(c){const a=[];for(let y=0;y<this.h;y++)for(let x=0;x<this.w;x++)if(!this.has(x,y)&&(this.has(x-1,y)||this.has(x+1,y)||this.has(x,y-1)||this.has(x,y+1)))a.push(x,y);for(let i=0;i<a.length;i+=2)this.px(a[i],a[i+1],c||OUT);return this;}
  done(){this.cx.putImageData(this.im,0,0);return this.cv;}
}
const SP={};function spr(k,fn){return SP[k]||(SP[k]=fn());}
function fr(c,x,y,w,h,col){c.fillStyle=col;c.fillRect(Math.round(x),Math.round(y),w,h);}

/* ---- sprites ---- */
function mkCoqui(s,blink,open){const w=Math.round(30*s)+2,h=Math.round(25*s)+2,b=new Buf(w,h),cx=w/2,T=RP.tan;
  b.ell(cx-9*s,19.5*s,5*s,3.2*s,T);b.ell(cx+9*s,19.5*s,5*s,3.2*s,T);
  b.ell(cx,14*s,11*s,8*s,T);b.ell(cx,16.8*s,7*s,5*s,RP.cream);
  [-6,6].forEach(dx=>{b.ell(cx+dx*s,6.5*s,4.6*s,4.6*s,T);
    if(blink)b.rect(cx+dx*s-3*s,6.5*s,Math.round(6*s),1,OUT);
    else{b.ell(cx+dx*s,6.5*s,3.1*s,3.1*s,["#FFFFFF"]);b.ell(cx+dx*s+.8*s,7*s,1.7*s,1.9*s,["#20140A"]);if(s>.8)b.px(cx+dx*s,5.6*s,"#FFFFFF");}});
  if(open)b.ell(cx,12.4*s,3.4*s,2.1*s,["#7A1C1C"]);else{b.line(cx-4.5*s,12.4*s,cx+4.5*s,12.4*s,OUT);b.px(cx-5.5*s,11.6*s,OUT);b.px(cx+5*s,11.6*s,OUT);}
  b.ell(cx-5*s,22.4*s,3.4*s,1.7*s,[T[4]]);b.ell(cx+5*s,22.4*s,3.4*s,1.7*s,[T[4]]);
  return b.outline().done();}
const coqui=(s,f,open)=>{const bl=(f%19)===0?1:0;return spr("cq"+s+bl+(open?1:0),()=>mkCoqui(s,bl,open));};
function mkAbuela(pose,open){const b=new Buf(48,51),X=30,S=RP.skin,P=RP.purp;
  b.ell(X-4,47.5,3.4,1.9,["#3A2414"]);b.ell(X+4,47.5,3.4,1.9,["#3A2414"]);
  b.rect(X-5,41,3,6,S[2]);b.rect(X+2,41,3,6,S[1]);
  b.ell(X,31,9,12.5,P);b.ell(X,38,10.5,5,P);
  for(let i=0;i<9;i++)b.px(X-8+hs(i,3)%17,34+hs(i,5)%8,P[4]);
  b.ell(X,33,5.4,8.5,RP.cream);b.rect(X-5,24,10,1,RP.cream[1]);
  b.rect(X-2,17,4,4,S[1]);
  b.ell(X,10,8,8.6,RP.grey);b.ell(X,2.9,3.6,2.6,RP.grey);
  b.ell(X,12.4,5.8,6.4,S);b.ell(X,5.8,6.2,2.6,RP.grey);
  b.px(X-3,12,"#20140A");b.px(X+2,12,"#20140A");b.px(X-4,14,"#E08A70");b.px(X+3,14,"#E08A70");
  if(open)b.rect(X-1,15,3,2,"#7A1C1C");else{b.rect(X-2,15,4,1,"#7A2A1A");b.px(X-3,14,"#7A2A1A");b.px(X+2,14,"#7A2A1A");}
  b.px(X-6,14,"#F8C838");b.px(X+6,14,"#F8C838");
  if(pose==="wave0"||pose==="wave1"){b.cap(X+7,23,X+12,13,2,P);b.ell(X+12.5+(pose==="wave1"?1.6:0),10,2.3,2.3,S);}
  else if(pose==="dedo0"||pose==="dedo1"){const d=pose==="dedo1"?1:-1;b.cap(X+7,23,X+12,15,2,P);b.ell(X+12+d,12.5,2.6,2.6,S);b.rect(X+11+d*2,4,2,7,S[2]);b.rect(X+11+d*2,4,2,1,S[4]);b.px(X+10+d*2,4,OUT);b.px(X+13+d*2,4,OUT);}   // a wagging finger: not now
  else{b.cap(X+8,23,X+10,33,2,P);b.ell(X+10,35.5,2.1,2.1,S);}
  if(pose==="offer"){b.cap(X-7,24,X-16,27,2,P);b.ell(X-18.5,27,2.3,2.3,S);}
  else if(pose==="bless"){b.cap(X-7,23,X-15,19,2,P);b.ell(X-17.5,18,2.3,2.3,S);}
  else{b.cap(X-8,23,X-10,33,2,P);b.ell(X-10,35.5,2.1,2.1,S);}
  return b.outline().done();}
function mkDog(wag){const b=new Buf(68,50),D=RP.orng,C=RP.cream;
  [[14,30],[22,31],[40,30],[48,31]].forEach((q,i)=>{b.rect(q[0],q[1],5,14,i%2?D[2]:D[1]);b.ell(q[0]+3,45,4,2.2,[C[2]]);});
  b.cap(11,22,wag?4:7,wag?9:7,2,D);b.ell(30,26,20,10,D);b.ell(30,31,13,5,C);b.ell(24,21,5,3.5,[D[0]]);
  b.ell(47,19,7,8,D);b.ell(52,13,8.5,8,D);b.ell(60,16,5.5,4,C);b.rect(63,13,3,3,"#20140A");
  b.line(56,19,62,19,OUT);b.rect(58,20,3,4,RP.red[3]);b.rect(53,10,2,2,"#20140A");b.px(53,10,"#FFFFFF");
  b.ell(46,11,3.5,7.5,[D[0]]);b.rect(44,23,3,7,RP.red[2]);b.px(45,30,RP.yel[2]);
  return b.outline().done();}
function mkTree(){const b=new Buf(48,62);b.grad(21,34,7,25,[...RP.wood].reverse(),true);b.rect(19,57,3,2,RP.wood[1]);b.rect(28,57,3,2,RP.wood[0]);
  [[24,24,17,13],[13,28,10,8],[35,28,10,8],[24,13,12,10],[16,18,9,8],[32,17,9,8]].forEach(e=>b.ell(e[0],e[1],e[2],e[3],RP.grn));
  [[14,22],[30,12],[36,26],[20,30]].forEach(p=>b.px(p[0],p[1],RP.red[3]));
  return b.outline().done();}
function mkPalm(){const b=new Buf(56,74);
  for(let i=0;i<=44;i++){const t=i/44,x=26+Math.sin(t*1.6)*4,y=70-i;b.ell(x,y,2.6-t*.6,1.6,i%4<1?[RP.wood[0]]:RP.wood);}
  for(let k=0;k<7;k++){const a=-2.9+k*.45;let x=30,y=25,vx=Math.cos(a)*2.1,vy=Math.sin(a)*2.1;for(let i=0;i<12;i++){b.ell(x,y,3.2-i*.2,2.2-i*.12,RP.grn);x+=vx;y+=vy;vy+=.28;}}
  b.ell(28,27,2.2,2.2,RP.wood);b.ell(32,27,2,2,RP.wood);
  return b.outline().done();}
function mkBall(){const b=new Buf(22,22);b.ell(11,11,9,9,RP.red);b.rect(7,6,2,2,"#FFFFFF");b.rect(6,8,1,2,"#FFFFFF");for(let i=3;i<19;i++)b.px(i,12+Math.round(Math.sin(i/3)),RP.yel[3]);return b.outline().done();}
function mkCup(){const b=new Buf(22,30);b.rect(5,7,12,20,"#EAF4FF");b.grad(6,10,10,16,[RP.orng[4],RP.orng[3],RP.orng[2]]);b.rect(6,9,10,1,"#FFF4D0");b.rect(15,8,1,18,"#FFFFFF");b.line(12,1,10,13,RP.red[2]);b.line(13,1,11,13,"#FFFFFF");b.ell(5,7,4,4,RP.orng);b.rect(4,6,2,2,"#FFF4D0");return b.outline().done();}
function mkBush(){const b=new Buf(34,22);b.ell(12,13,10,8,RP.grn);b.ell(23,14,9,7,RP.grn);b.ell(17,9,8,7,RP.grn);[[10,9],[22,11],[16,5]].forEach(p=>b.px(p[0],p[1],"#FF8FB8"));return b.outline().done();}
function mkPot(){const b=new Buf(22,30);b.ell(11,9,7,6,RP.grn);b.ell(6,13,5,4,RP.grn);b.ell(16,13,5,4,RP.grn);b.rect(6,18,10,3,RP.orng[2]);b.rect(7,21,8,6,RP.orng[1]);b.rect(6,18,10,1,RP.orng[3]);return b.outline().done();}

/* ---- shared scene pieces ---- */
function sky(b,W,hz){b.grad(0,0,W,hz,RP.sky);
  b.ell(W-30,17,8,8,RP.yel.slice(2));
  [[36,16,1],[112,9,.7],[168,26,.8]].forEach(c=>{const s=c[2];b.ell(c[0],c[1],13*s,5*s,RP.cloud);b.ell(c[0]-9*s,c[1]+2,8*s,4*s,RP.cloud);b.ell(c[0]+10*s,c[1]+2,9*s,4*s,RP.cloud);b.ell(c[0]+2,c[1]-4*s,7*s,5*s,RP.cloud);});
  for(let x=0;x<W;x++){const y1=Math.round(hz-17-7*Math.sin(x*.03+1)-4*Math.sin(x*.08));for(let y=y1;y<hz;y++)b.px(x,y,y-y1<2?"#9CD0BC":bay(x,y)<(y-y1)/30?"#5E9E90":"#74B4A2");
    const y2=Math.round(hz-7-4*Math.sin(x*.05+3)-2*Math.sin(x*.13));for(let y=y2;y<hz;y++)b.px(x,y,y-y2<1?"#7CCB7A":"#4E9E5E");}}
function grass(b,y0,W,H){b.grad(0,y0,W,H-y0,RP.grass);
  for(let i=0;i<220;i++){const x=hs(i,11)*W/100+hs(i,7)%3,y=y0+2+hs(i,13)*(H-y0-3)/100;b.px(x,y,RP.grn[1]);b.px(x+1,y-1,RP.grn[4]);}
  for(let i=0;i<26;i++){const x=hs(i,21)*W/100,y=y0+4+hs(i,23)*(H-y0-8)/100;b.px(x,y,["#FFE070","#FF8FB8","#FFFFFF"][i%3]);b.px(x,y+1,RP.grn[0]);}}

/* ---- Casa ---- */
function bgCasa(open){const b=new Buf(240,150),T=RP.teal,C=RP.cream,W=RP.wood,ST=RP.stone;
  sky(b,240,96);grass(b,96,240,150);
  for(let y=118;y<150;y++){const t=(y-118)/31,xl=Math.round(142-108*t),xr=Math.round(188-38*t);for(let x=xl;x<=xr;x++)b.px(x,y,x===xl||x===xr?ST[0]:(y%6===0||(x+Math.floor(y/6)*7)%13===0)?ST[1]:hs(x,y)<8?ST[4]:ST[3]);}
  b.grad(70,44,144,60,[T[3],T[3],T[2],T[2],T[1]],true);
  for(let y=49;y<104;y+=5)for(let x=70;x<214;x++)b.px(x,y,T[1]);
  for(let y=44;y<51;y++)for(let x=70;x<214;x++)if(bay(x,y)<(51-y)/8)b.px(x,y,T[0]);
  b.rect(69,44,1,60,"#134A4C");b.rect(214,44,1,60,"#134A4C");
  for(let y=16;y<42;y++){const t=(y-16)/25,xl=Math.round(88-30*t),xr=Math.round(196+30*t),k=(y-16)%5,rw=Math.floor((y-16)/5);
    for(let x=xl;x<=xr;x++)b.px(x,y,x===xl||x===xr||y===41?"#4A1210":y===16?RP.red[4]:k===4?RP.red[0]:(x+rw*4)%8===0?RP.red[1]:bay(x,y)<t*.8?RP.red[2]:RP.red[3]);}
  b.rect(58,42,169,3,C[3]);b.rect(58,44,169,1,C[1]);b.frame(57,41,171,4,OUT);
  b.rect(86,58,7,26,"#FFFFFF");b.rect(131,58,7,26,"#FFFFFF");for(let y=60;y<84;y+=3){b.rect(86,y,7,1,ST[2]);b.rect(131,y,7,1,ST[2]);}
  b.frame(85,57,9,28,OUT);b.frame(130,57,9,28,OUT);
  b.rect(94,58,36,26,C[3]);b.grad(97,61,30,20,[RP.blue[4],RP.blue[3],RP.blue[2]]);b.rect(111,61,2,20,C[3]);b.rect(97,70,30,2,C[3]);
  for(let i=0;i<7;i++){b.px(100+i,67-i,"#FFFFFF");b.px(116+i,78-i,"#FFFFFF");}
  b.frame(93,57,38,28,OUT);b.frame(96,60,32,22,C[0]);
  b.rect(90,86,44,5,W[2]);b.rect(90,86,44,1,W[4]);b.frame(89,85,46,7,OUT);
  for(let i=0;i<9;i++){b.ell(93+i*4.8,83.5,2.2,2.2,[["#FF8FB8","#FFE070","#F4584A"][i%3]]);b.px(93+i*4.8,85,RP.grn[1]);}
  b.rect(150,50,32,54,C[3]);b.frame(149,49,34,56,OUT);
  if(open){b.grad(153,53,24,51,["#140A06","#22140C","#32201A"]);b.rect(177,53,4,51,W[2]);b.rect(177,53,1,51,W[4]);b.frame(152,52,26,53,OUT);}
  else{b.grad(153,53,26,51,[W[3],W[2],W[2],W[1]],true);b.frame(152,52,28,53,OUT);
    [[156,57,20,18],[156,80,20,20]].forEach(p=>{b.frame(p[0],p[1],p[2],p[3],W[0]);b.rect(p[0]+1,p[1]+1,p[2]-2,1,W[4]);b.rect(p[0]+1,p[1]+1,1,p[3]-2,W[4]);});
    b.rect(174,77,2,2,RP.yel[2]);}
  b.rect(187,60,4,6,RP.yel[3]);b.frame(186,59,6,8,OUT);b.rect(188,57,2,2,ST[0]);
  b.rect(62,104,160,6,ST[3]);b.rect(62,104,160,1,ST[4]);b.rect(62,109,160,1,ST[1]);b.frame(61,103,162,8,OUT);
  b.rect(146,111,38,4,ST[2]);b.rect(146,111,38,1,ST[4]);b.rect(142,115,46,4,ST[3]);b.rect(142,115,46,1,ST[4]);b.rect(142,118,46,1,ST[0]);b.rect(146,114,38,1,ST[0]);
  b.rect(153,104,24,2,RP.red[1]);
  const cv=b.done(),c=b.cx;c.drawImage(spr("palm",mkPalm),2,34);c.drawImage(spr("bush",mkBush),206,92);c.drawImage(spr("pot",mkPot),192,78);c.drawImage(spr("bush",mkBush),40,96);
  return cv;}

/* ---- Parque ---- */
function bgParque(){const b=new Buf(240,150),ST=RP.stone;
  sky(b,240,84);
  for(let x=0;x<240;x++){const h=7+Math.round(3*Math.sin(x*.21)+2*Math.sin(x*.07));for(let y=84-h;y<86;y++)b.px(x,y,y===84-h?RP.grn[3]:bay(x,y)<.4?RP.grn[1]:RP.grn[2]);}
  grass(b,86,240,150);
  for(let y=98;y<150;y++){const t=(y-98)/52,xc=118+Math.sin(t*2.2)*34,hw=8+t*10;for(let x=Math.round(xc-hw);x<=Math.round(xc+hw);x++)b.px(x,y,Math.abs(x-xc)>hw-1?RP.orng[1]:hs(x,y)<10?RP.cream[1]:RP.cream[2]);}
  [[162,112],[212,112]].forEach((p,i)=>{b.cap(p[0]-5,p[1],p[0],58,1.6,RP.red);b.cap(p[0]+5,p[1],p[0],58,1.6,RP.red);});
  b.rect(158,56,58,4,RP.red[2]);b.rect(158,56,58,1,RP.red[4]);b.rect(158,59,58,1,RP.red[0]);b.frame(157,55,60,6,OUT);
  b.rect(20,104,26,3,RP.wood[3]);b.rect(20,99,26,3,RP.wood[3]);b.rect(22,102,2,10,RP.wood[1]);b.rect(42,102,2,10,RP.wood[1]);b.frame(19,98,28,5,OUT);b.frame(19,103,28,5,OUT);
  const cv=b.done(),c=b.cx;c.drawImage(spr("tree",mkTree),4,28);c.drawImage(spr("bush",mkBush),92,74);c.drawImage(spr("bush",mkBush),-6,124);
  return cv;}

/* ---- icons, bubbles, pointers ---- */
const GL={heart:[".##.##.","#######","#######",".#####.","..###..","...#..."],up:["...#...","..###..",".#####.","#######","..###..","..###..","..###.."],
  go:["...#...","...##..","######.","#######","######.","...##..","...#..."],ven:["...#...","..##...",".######","#######",".######","..##...","...#..."],
  plus:["..###..","..###..","#######","#######","#######","..###..","..###.."],hand:["#.#.#..","#.#.#..","#.#.#.#","#####.#","######.",".####..",".####.."],
  q:[".###.","#...#","....#","...#.","..#..",".....","..#.."],eye:["..ooooo..",".owbbbwo.","owwbbbwwo",".owbbbwo.","..ooooo.."]},
  GC={heart:"#E0403A",up:"#2E6CD0",go:"#2E9A48",ven:"#2E6CD0",plus:"#2E9A48",hand:"#B87A48",q:"#2A1810"};
function glyph(c,k,x,y){GL[k].forEach((rw,j)=>{for(let i=0;i<rw.length;i++){const ch=rw[i];if(ch!==".")fr(c,x+i,y+j,1,1,ch==="#"?GC[k]:ch==="o"?OUT:ch==="w"?"#FFFFFF":"#2E6CD0");}});}
function face(c,cx,cy,ok){[[-1,-3,3],[-2,-2,5],[-3,-1,7],[-3,0,7],[-3,1,7],[-2,2,5],[-1,3,3]].forEach(r=>fr(c,cx+r[0],cy+r[1],r[2],1,ok?"#FFD84A":"#7CB4F0"));
  fr(c,cx-2,cy-1,1,1,OUT);fr(c,cx+1,cy-1,1,1,OUT);if(ok){fr(c,cx-2,cy+1,1,1,OUT);fr(c,cx-1,cy+2,3,1,OUT);fr(c,cx+2,cy+1,1,1,OUT);}else{fr(c,cx-2,cy+2,1,1,OUT);fr(c,cx-1,cy+1,3,1,OUT);fr(c,cx+2,cy+2,1,1,OUT);}}
// a speech bubble holding icons; tx,ty is where its tail points
function bubble(c,list,tx,ty,f){const ws=list.map(k=>k==="ok"||k==="sad"?7:GL[k][0].length),w=ws.reduce((a,b)=>a+b+3,3),h=13,x=Math.round(tx-w/2),y=ty-h-5-(f%2);
  fr(c,x-1,y-1,w+2,h+2,OUT);fr(c,x,y,w,h,"#FFFFFF");fr(c,x-1,y-1,1,1,"rgba(0,0,0,0)");
  fr(c,tx-2,y+h,5,1,"#FFFFFF");fr(c,tx-3,y+h,1,2,OUT);fr(c,tx+3,y+h,1,2,OUT);fr(c,tx-2,y+h+1,5,1,"#FFFFFF");fr(c,tx-2,y+h+2,5,1,OUT);fr(c,tx-1,y+h+2,3,1,"#FFFFFF");fr(c,tx-1,y+h+3,3,1,OUT);
  let px=x+3;list.forEach((k,i)=>{if(k==="ok"||k==="sad")face(c,px+3,y+6,k==="ok");else glyph(c,k,px,y+Math.floor((h-GL[k].length)/2));px+=ws[i]+3;});}
function pointer(c,b,f){const x=b[0],y=b[1],w=b[2],h=b[3],k=4,col="#FFE040";
  [[x-2,y-2,1,1],[x+w+1,y-2,-1,1],[x-2,y+h+1,1,-1],[x+w+1,y+h+1,-1,-1]].forEach(p=>{fr(c,Math.min(p[0],p[0]+p[2]*k),p[1]-(p[3]<0?0:0),k+1,2,OUT);fr(c,p[0]-(p[2]<0?1:0),Math.min(p[1],p[1]+p[3]*k),2,k+1,OUT);
    fr(c,Math.min(p[0],p[0]+p[2]*(k-1)),p[1]+(p[3]<0?0:0),k,1,col);fr(c,p[0]-(p[2]<0?0:0),Math.min(p[1],p[1]+p[3]*(k-1)),1,k,col);});
  const ax=Math.round(x+w/2),ay=y-12-(f%2)*2;[[-1,0,3],[-1,1,3],[-1,2,3],[-3,3,7],[-2,4,5],[-1,5,3],[0,6,1]].forEach(r=>{fr(c,ax+r[0]-1,ay+r[1],r[2]+2,2,OUT);});
  [[-1,0,3],[-1,1,3],[-1,2,3],[-3,3,7],[-2,4,5],[-1,5,3],[0,6,1]].forEach(r=>fr(c,ax+r[0],ay+r[1],r[2],1,col));}
function sparks(c,pts,f){pts.forEach((p,i)=>{if((i+f)%2){fr(c,p[0],p[1]-2,1,5,"#FFE040");fr(c,p[0]-2,p[1],5,1,"#FFE040");fr(c,p[0],p[1],1,1,"#FFFFFF");}else fr(c,p[0],p[1],1,1,"#FFE040");});}
function talk(c,x,y,f,dir){for(let i=0;i<2+(f%2);i++){fr(c,x+dir*i*3-1,y-i*2-1,3,5+4*i,OUT);}for(let i=0;i<2+(f%2);i++)fr(c,x+dir*i*3,y-i*2,1,3+4*i,"#FFFFFF");}
function shadow(c,x,y,w){for(let j=0;j<3;j++)for(let i=j===1?0:2;i<w-(j===1?0:2);i++)if((i+j)%2===0)fr(c,x+i,y+j,1,1,"#1E5A2A");}

