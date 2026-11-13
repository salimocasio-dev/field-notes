"use strict";
/* ============================================================
   Coquí · scene "La sala": abuela's living room, and her family.
   A warm wall with three picture frames, the door to the porch on
   the left, a window on the right. A long sofa, abuelo's armchair
   (la butaca), a floor lamp, a low table, the baby's blanket on the
   tile floor. The family are people, like abuela: mamá, papá,
   abuelo, el hermano, la hermana, el bebé.
   People live in W.gente: {id:{x,y (feet), pose, sent, bub, al, dir, vis}}.
   Every story set here uses this drawing and these actions.
   ============================================================ */
(function(){
const SW=KIT.SW,SH=KIT.SH,P=KIT.PIEL,H=KIT.PELO,SOFA=["#1F5A52","#2E7A6E","#3E9A8A","#62B8A6","#8AD0BE"],SPONGE="#F2D08A",FROST="#FF8FB8";
const FAM={
  mama:{piel:P.a,pelo:H.castano,peinado:"largo",ropa:RP.red,falda:1,zapato:"#7A1C1C"},
  papa:{piel:P.b,pelo:H.negro,peinado:"corto",ropa:RP.blue,abajo:RP.wood},
  abuelo:{piel:P.a,pelo:H.blanco,peinado:"calvo",ropa:RP.cream.slice(1),abajo:RP.grey,bigote:1,gafas:1,detalle:(b,X,tc,rx,t)=>{b.rect(X,tc-8,1,t+6,"#B89A6A");b.rect(X-5,tc-2,3,3,"#D8BC8A");b.rect(X+3,tc-2,3,3,"#D8BC8A");}},
  hermano:{nino:1,piel:P.b,pelo:H.negro,peinado:"corto",ropa:RP.grn,abajo:RP.blue,zapato:"#F2F2F8"},
  hermana:{nino:1,piel:P.a,pelo:H.castano,peinado:"trenzas",ropa:["#B8407A","#E0609A","#FF8FB8","#FFB8D4"],falda:1,lazo:"#FFE070",zapato:"#F2F2F8"}};

/* ---------- the room ---------- */
function bg(){const b=new Buf(SW,SH),C=RP.cream,Wd=RP.wood,ST=RP.stone;
  b.grad(0,0,SW,122,["#F8E8C0","#F4E0B0","#EED6A0"]);for(let y=6;y<118;y+=12)for(let x=0;x<SW;x++)if((x+y)%24<1)b.px(x,y,"#EACD92");
  // the tile floor, wider towards us
  for(let y=122;y<SH;y++){const t=(y-122)/(SH-122),hw=120+90*t,row=Math.floor(t*t*3+t*3);
    for(let x=0;x<SW;x++){const u=(x-120)/hw*8+8,col=Math.floor(u),e=u-col,f=(t*t*3+t*3)-row;b.px(x,y,e<.03||f<.06?"#B89A6A":(col+row)%2?"#EEDCB0":"#E2CA98");}}
  b.rect(0,118,SW,4,Wd[2]);b.rect(0,118,SW,1,Wd[4]);b.rect(0,121,SW,1,Wd[0]);
  // the door to the porch, open: daylight, a post, green
  b.rect(27,42,34,80,C[3]);b.frame(26,41,36,82,OUT);b.grad(30,45,28,77,RP.sky.slice(1));b.rect(30,96,28,26,"#52BC4C");b.rect(30,96,28,1,"#84DC78");b.rect(30,112,28,10,"#EEDCB0");
  b.rect(42,45,5,67,C[3]);b.rect(42,45,1,67,C[4]);b.rect(46,45,1,67,C[1]);b.frame(29,44,30,79,OUT);
  b.rect(20,44,7,78,Wd[2]);b.rect(20,44,1,78,Wd[4]);b.frame(19,43,9,80,OUT);b.rect(23,82,2,2,RP.yel[2]);
  // the window, with curtains
  b.rect(167,38,40,44,C[3]);b.frame(166,37,42,46,OUT);b.grad(170,41,34,38,RP.sky.slice(1));b.ell(198,52,9,4,RP.grn);b.ell(190,48,7,3,RP.grn);b.rect(186,41,2,38,C[3]);b.rect(170,59,34,2,C[3]);b.frame(169,40,36,40,C[0]);
  [[164,10],[200,10]].forEach(p=>{b.grad(p[0],36,p[1],48,["#FFD9E6","#FFB8D4","#F090B8"],true);for(let y=38;y<84;y+=4)b.px(p[0]+(y%8?3:6),y,"#E87AA8");b.frame(p[0]-1,35,p[1]+2,50,OUT);});
  b.rect(160,33,54,3,Wd[2]);b.frame(159,32,56,5,OUT);
  // a plant in the corner
  const out=b.done(),x=b.cx;x.drawImage(spr("pot",mkPot),212,94);
  return out;}
function mkSofa(){const b=new Buf(92,46),S=SOFA;
  b.rect(8,0,76,26,S[1]);b.rect(8,0,76,2,S[3]);for(let x=10;x<84;x+=3)for(let y=4;y<24;y+=3)if((x+y)%2)b.px(x,y,S[2]);b.rect(45,2,2,24,S[0]);
  b.rect(8,22,37,9,S[3]);b.rect(47,22,37,9,S[3]);b.rect(8,22,76,1,S[4]);b.rect(8,30,76,1,S[1]);b.rect(45,22,2,9,S[0]);
  b.rect(0,10,9,30,S[2]);b.rect(83,10,9,30,S[2]);b.rect(0,10,9,2,S[4]);b.rect(83,10,9,2,S[4]);b.rect(7,12,1,28,S[0]);b.rect(84,12,1,28,S[0]);
  b.rect(8,31,76,9,S[1]);b.rect(8,39,76,1,S[0]);b.rect(4,40,4,5,RP.wood[0]);b.rect(84,40,4,5,RP.wood[0]);
  return b.outline().done();}
function mkButaca(){const b=new Buf(42,44),O=RP.orng;   // abuelo's armchair
  b.rect(6,0,30,24,O[2]);b.rect(6,0,30,2,O[4]);for(let y=5;y<22;y+=6)for(let x=10;x<34;x+=6)b.px(x,y,O[0]);
  b.rect(6,21,30,8,O[3]);b.rect(6,21,30,1,O[4]);b.rect(0,10,7,28,O[1]);b.rect(35,10,7,28,O[1]);b.rect(0,10,7,2,O[3]);b.rect(35,10,7,2,O[3]);
  b.rect(6,29,30,9,O[1]);b.rect(6,37,30,1,O[0]);b.rect(3,38,4,5,RP.wood[0]);b.rect(35,38,4,5,RP.wood[0]);
  return b.outline().done();}
function mkMesita(){const b=new Buf(46,18),Wd=RP.wood;b.rect(4,5,4,12,Wd[1]);b.rect(38,5,4,12,Wd[1]);b.rect(0,0,46,5,Wd[3]);b.rect(0,0,46,1,Wd[4]);b.rect(0,4,46,1,Wd[0]);b.rect(8,10,30,2,Wd[0]);return b.outline().done();}
function mkLampara(on){const b=new Buf(20,64),Y=RP.yel;b.rect(9,14,2,46,RP.grey[0]);b.rect(4,60,12,3,RP.grey[0]);b.rect(4,60,12,1,RP.grey[2]);
  for(let y=0;y<14;y++){const h=4+Math.round(y*.42);b.rect(10-h,y,2*h,1,on?(y<2?Y[4]:Y[3]):(y<2?C4:C3));}return b.outline().done();}
const C4="#FFFBEA",C3="#EEDCB0";
function manta(g){fr(g,49,177,58,22,OUT);fr(g,50,178,56,20,"#A8D8F0");for(let y=180;y<197;y+=4)for(let x=52;x<104;x+=4)if(((x>>2)+(y>>2))%2)fr(g,x,y,2,2,"#FFFFFF");fr(g,50,178,56,1,"#DCEEFF");}
// a picture frame; with a photo in it once one is taken. Crooked when it came out wrong.
// f = {q:[who is in it], ok, pata:1 (only the frog's foot at the edge), pies:1 (abuelo's slippers)}
function marco(g,i,f){const x=76+i*24,y=38;g.save();g.translate(x+10,y+2);if(f&&!f.ok)g.rotate(.24+.05*Math.sin(F/6+i));
  fr(g,-11,-1,22,26,OUT);fr(g,-10,0,20,24,RP.wood[2]);fr(g,-10,0,20,1,RP.wood[4]);fr(g,-8,2,16,20,f?"#BFE0F0":"#FBF0D2");
  if(f){g.save();g.beginPath();g.rect(-8,2,16,20);g.clip();
    if(f.pies){fr(g,-8,14,16,8,"#E2CA98");[[-6,10],[1,11]].forEach(p=>{fr(g,p[0]-1,p[1]-1,7,9,OUT);fr(g,p[0],p[1],5,7,"#7A4A1E");fr(g,p[0],p[1],5,2,"#A8682C");});}
    else{const q=f.q||[];q.forEach((id,k)=>{if(id==="coqui"){g.drawImage(spr("cq.5_f",()=>mkCoqui(.5,0,0)),q.length>1?-1:-8,12);return;}
        const im=id==="abuela"?spr("abidle0",()=>mkAbuela("idle",0)):spr("pf"+id,()=>KIT.mkPersona(FAM[id],"idle",0,0)),sx=id==="abuela"?22:KIT.PX-8;g.drawImage(im,sx,0,16,22,q.length>1?-10+k*2:-8,3,16,22);});
      if(f.pata){fr(g,5,17,4,5,OUT);fr(g,6,18,3,4,RP.tan[3]);}}
    g.restore();}
  fr(g,0,-3,1,3,OUT);g.restore();}
// a slice of abuela's cake, and the cake itself
function trozo(g,x,y,k,mord){k=k||1;const w=Math.round(9*k),h=Math.round(8*k);fr(g,x-1,y-1,w+2,h+2,OUT);fr(g,x,y,w,h,SPONGE);fr(g,x,y,w,Math.round(3*k),FROST);
  if(mord){const m=Math.max(2,Math.round(4*k));fr(g,x+w-m,y-1,m+1,m+1,OUT);fr(g,x+w-m+1,y-1,m,m,"#FFFDF4");}else fr(g,x+Math.round(3*k),y-Math.round(2*k),Math.round(2*k)+1,Math.round(2*k),RP.red[2]);}
function bizcocho(g,x,y,n){fr(g,x-4,y+9,34,3,OUT);fr(g,x-3,y+9,32,2,"#FFFFFF");
  if(n==="tapado"){g.fillStyle=OUT;g.beginPath();g.ellipse(x+13,y+9,15,13,0,Math.PI,0);g.fill();g.fillStyle="#D8D8E4";g.beginPath();g.ellipse(x+13,y+9,14,12,0,Math.PI,0);g.fill();fr(g,x+6,y+1,3,5,"#F2F2F8");fr(g,x+11,y-5,4,3,OUT);fr(g,x+12,y-4,2,2,"#9494A6");
    for(let k=0;k<3;k++)for(let j=0;j<3;j++)fr(g,x+5+k*8+(((F>>2)+j+k)%2),y-8-j*4-((F>>1)+k*2)%3,2,2,j===2?"#E8F0F8":"#FFFFFF");return;}   // steam: it is hot
  for(let i=0;i<n;i++){const sx=x-4+i*5;fr(g,sx-1,y-1,6,11,OUT);fr(g,sx,y,4,9,SPONGE);fr(g,sx,y,4,3,FROST);fr(g,sx+1,y-2,2,2,RP.red[2]);}}
function plato(g,x,y){fr(g,x-6,y,12,2,OUT);fr(g,x-5,y,10,1,"#FFFFFF");fr(g,x-2,y-1,1,1,SPONGE);fr(g,x+2,y-1,1,1,FROST);}   // an empty plate, a crumb or two

/* ---------- where things are ---------- */
const SITIO={mama:[97,127,1],papa:[131,127,1],abuelo:[181,127,1],bebe:[70,193],abuela:[42,168],hermano:[150,198],hermana:[180,198]};
const LUGAR={puerta:[30,104,.7],centro:[104,183,1],huele:[72,146,.9],abuela:[58,155,1],mama:[82,125,.9],papa:[116,125,.9],abuelo:[166,125,.9],bebe:[88,175,1],izq:[44,183,1]};
const PARADOS=[[100,136],[140,136]],APARTE=[[70,198],[170,198]],JUNTOS=[[96,196],[144,196]],CAMARA=[198,176];
const alto=id=>id==="abuela"?51:id==="bebe"?28:(FAM[id].nino?44:(W.gente[id]&&W.gente[id].sent?49:56));
const caja=id=>{const p=W.gente[id];return p&&p.vis!==0&&(p.al==null||p.al>.3)?[Math.round(p.x)-11,Math.round(p.y)-alto(id),22,alto(id)]:null;};
const persona=id=>({id,m:1,si:w=>!!(w.gente&&w.gente[id]&&w.gente[id].vis!==0),box:()=>caja(id)});
const COSAS=["bebe","hermano","hermana","abuela","mama","papa","abuelo"].map(persona).concat([
  {id:"bizcocho",si:w=>w.pastel>0,box:[106,138,30,16],m:1},{id:"mesita",box:[98,148,46,18],m:0},{id:"sofa",box:[68,84,92,44],m:0},{id:"butaca",box:[160,86,42,42],m:0},
  {id:"fotos",box:[64,34,82,30],m:0},{id:"lampara",box:[146,62,20,64],m:0},{id:"puerta",box:[20,42,42,80],m:0},{id:"ventana",box:[160,32,56,54],m:0},{id:"sala",box:[0,122,240,94],m:0}]);

/* ---------- drawing ---------- */
function gente(c,id,a){const p=W.gente[id];if(!p||p.vis===0)return;const x=Math.round(p.x),y=Math.round(p.y),habla=TALK===id&&a%2?1:0,h=alto(id);c.globalAlpha=p.al==null?1:p.al;
  if(id==="bebe"){const e=p.est||"idle",im=spr("bb"+e+(a%2),()=>KIT.mkBebe(e,a%2));c.drawImage(im,x-13,y-28);}
  else if(id==="abuela"){const pose=p.pose==="wave"?"wave"+(a%2):p.pose==="dedo"?"dedo"+((a>>1)%2):(p.pose||"idle"),im=spr("ab"+pose+habla,()=>mkAbuela(pose,habla));c.save();c.translate(x,y-50);if(p.dir<0)c.scale(-1,1);c.drawImage(im,-30,0);c.restore();
    if(p.lleva){const hx=x+(p.dir<0?16:-22),hy=y-27;if(p.lleva==="plato"){fr(c,hx-3,hy+7,16,3,OUT);fr(c,hx-2,hy+7,14,2,"#FFFFFF");for(let k=0;k<3;k++)trozo(c,hx-2+k*5,hy-1,.6,k<(W.lost||0));}else trozo(c,hx,hy);}}
  else{const pose=p.pose==="wave"?"wave"+(a%2):(p.pose||"idle"),w=(p.gafas||p.dormido)?Object.assign({},FAM[id],p.gafas?{gafas:p.gafas}:{},{dormido:p.dormido}):FAM[id],k="p"+id+pose+habla+(p.sent?1:0)+(p.gafas||"")+(p.dormido?"z":""),im=spr(k,()=>KIT.mkPersona(w,pose,habla,p.sent));
    c.save();c.translate(x,y-im.height+1+(p.rie&&a%2?-1:0));if(p.dir<0)c.scale(-1,1);c.drawImage(im,-KIT.PX,0);c.restore();
    if(p.dormido){const z=(F>>3)%3;fr(c,x+9+z*2,y-h-4-z*2,5,1,"#FFFFFF");fr(c,x+12+z*2,y-h-3-z*2,1,1,"#FFFFFF");fr(c,x+11+z*2,y-h-2-z*2,1,1,"#FFFFFF");fr(c,x+10+z*2,y-h-1-z*2,1,1,"#FFFFFF");fr(c,x+9+z*2,y-h-z*2,5,1,"#FFFFFF");}
    if(pose==="taza"){const d=p.dir<0?-1:1,cx=x+d*13,cy=y-h+26;taza(c,cx-4,cy-8,W.relleno?3:Math.max(0,3-(W.lost||0)),1);}}
  if(p.trozo)trozo(c,x-4,y-Math.round(h*.52),1,p.trozo==="mordido");
  else if(p.servido&&id!=="bebe")plato(c,x,y-Math.round(h*(p.sent?.36:.5)));
  c.globalAlpha=1;}
// abuelo's cup of coffee: three sips full, less after every spill
function taza(g,x,y,n,k){k=k||1;fr(g,x-k,y,9*k+2*k,8*k,OUT);fr(g,x,y+8*k,9*k,k,OUT);fr(g,x+9*k+k,y+2*k,3*k,k,OUT);fr(g,x+11*k+k,y+3*k,k,3*k,OUT);fr(g,x+9*k+k,y+6*k,3*k,k,OUT);fr(g,x,y,9*k,8*k,"#FFFFFF");
  const hgt=[0,2,4,6][n]*k;if(hgt)fr(g,x+k,y+8*k-hgt-k,7*k,hgt,"#5A3418");if(hgt)fr(g,x+k,y+8*k-hgt-k,7*k,k,"#8A5A38");fr(g,x,y+7*k,9*k,k,"#D8D8E4");}
function rana(g,q,a){const b=frogBox(q),bl=(F%47)<2?1:0,op=(q.bub==="hola"||TALK==="coqui")&&a%2?1:0;
  for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5-(j===1?0:2);i++)if((i+j)%2===0)fr(g,b.x+2+i,q.y+25+j,1,1,"#A8875A");
  g.drawImage(spr("cq"+q.s+"_"+bl+op,()=>mkCoqui(q.s,bl,op)),b.x,b.y+Math.round(q.dy));}
GL.biz=["...oo....","..o##o...",".ooooooo.","owwwwwwwo","o#######o","o#######o","ooooooooo"];GC.biz="#F2D08A";GL.gaf=["ooo.ooo","o.ooo.o","ooo.ooo"];
Object.assign(BUBL,{bizcocho:["biz"],q:["q"],gafas_q:["gaf","q"],feliz:["ok"]});
function bub2(c,k,tx,ty,a){c.save();c.translate(tx,ty);c.scale(2,2);bub(c,k,0,0,a);c.restore();}
function draw(c,W,a){const q=W.cq,G=W.gente||{};
  c.drawImage(spr("sala",bg),0,0);
  for(let i=0;i<3;i++)marco(c,i,(W.fotos||[])[i]);
  c.drawImage(spr("lamp"+(W.luz?1:0),()=>mkLampara(W.luz)),146,62);
  c.drawImage(spr("sofa",mkSofa),68,84);c.drawImage(spr("butaca",mkButaca),160,86);
  manta(c);
  // everyone, and the low table, from the back of the room to the front
  const lista=Object.keys(G).filter(id=>G[id]&&G[id].vis!==0).map(id=>({y:G[id].z||G[id].y,d:()=>gente(c,id,a)}));
  lista.push({y:165,d:()=>{c.drawImage(spr("mesita",mkMesita),98,148+(W.golpe&&F-W.golpe<4?-2:0));if(W.pastel!=null)bizcocho(c,107,138,W.pastel);if(W.camMesa){fr(c,113,139,16,10,OUT);fr(c,114,140,14,8,"#3A3A46");fr(c,118,142,5,5,"#9CCBF5");}}});
  if(q.vis)lista.push({y:q.y+27,d:()=>{c.globalAlpha=q.al;rana(c,q,a);c.globalAlpha=1;const b=frogBox(q),dy=Math.round(q.dy);if(W.lleva)trozo(c,b.x+Math.round(b.w/2)-4,b.y+dy-9);
    if(W.tapaojos){[.3,.7].forEach(u=>{c.fillStyle=OUT;c.beginPath();c.arc(b.x+b.w*u,b.y+dy+7*q.s,5.2*q.s,0,7);c.fill();c.fillStyle=FAM[W.tapaojos].piel[3];c.beginPath();c.arc(b.x+b.w*u,b.y+dy+7*q.s,4.2*q.s,0,7);c.fill();});}}});   // a child's hands over his eyes
  lista.sort((m,n)=>m.y-n.y).forEach(o=>o.d());
  if(W.vuela){const v=W.vuela;trozo(c,Math.round(v.x)-4,Math.round(v.y)-4,v.k||1,v.mord);}
  if(W.gotas&&F-W.gotas.f<10){const t=F-W.gotas.f;for(let i=0;i<4;i++)fr(c,Math.round(W.gotas.x+(i-1.5)*3*(1+t/4)),Math.round(W.gotas.y+t*t/3-t+i%2*2),2,2,"#5A3418");}   // coffee slops out
  if(W.borroso){const t=spr("bor",()=>{const k=document.createElement("canvas");k.width=20;k.height=18;return k;}),g=t.getContext("2d");g.imageSmoothingEnabled=true;g.drawImage(sc,0,0,SW,SH,0,0,20,18);
    c.save();c.imageSmoothingEnabled=true;c.drawImage(t,0,0,20,18,0,0,SW,SH);c.restore();c.imageSmoothingEnabled=false;}   // what abuelo sees without his glasses
  if(W.flash&&F-W.flash<3){c.fillStyle="rgba(255,255,255,.75)";c.fillRect(0,0,SW,SH);}
  Object.keys(G).forEach(id=>{const p=G[id];if(p&&p.bub&&p.vis!==0){const at=talkAt(id,W);if(at)bub2(c,p.bub,at[0],at[1]+38,a);}});
  if(q.vis&&q.bub){const b=frogBox(q);bub2(c,q.bub,b.x+(b.w>>1),b.y+2,a);}
}
function talkAt(k,W){const p=W.gente&&W.gente[k];if(!p||p.vis===0||(p.al!=null&&p.al<.5))return null;return [Math.round(p.x),Math.round(p.y)-alto(k)-1-(p.bub?38:0)];}

/* ---------- what is at stake, in the corner of the screen ---------- */
function tarjeta(g,x,y,w,h){g.fillStyle=OUT;g.fillRect(x-1,y,w+2,h);g.fillRect(x,y-1,w,h+2);g.fillStyle="#FFFDF4";g.fillRect(x,y,w,h);}
function hud(g,W,a){
  if(W.plato!=null){tarjeta(g,3,3,78,29);g.drawImage(spr("cq.7_0",()=>mkCoqui(.7,0,0)),5,7);g.fillStyle=OUT;g.fillRect(29,25,48,3);g.fillStyle="#FFFFFF";g.fillRect(30,25,46,2);
    for(let i=0;i<W.plato;i++)trozo(g,32+i*15,11,1.3,i>=W.plato-(W.lost||0));}   // three slices: whole, or with a bite out
  if(W.cafe){tarjeta(g,3,3,44+(W.aciertos||0)*13,36);taza(g,8,9,W.relleno?3:Math.max(0,3-(W.lost||0)),3);for(let i=0;i<(W.aciertos||0);i++)heart(g,49+i*13,15,1);}
  if(W.visor){const im=spr("pf"+W.visor.quien,()=>KIT.mkPersona(FAM[W.visor.quien],"idle",0,0));tarjeta(g,3,3,50,50);g.fillStyle="#BFE0F0";g.fillRect(5,5,46,46);
    if(W.visor.nitido){g.imageSmoothingEnabled=false;g.drawImage(im,KIT.PX-11,0,22,23,6,5,44,46);}
    else{const t=spr("vis",()=>{const k=document.createElement("canvas");k.width=5;k.height=5;return k;}),x=t.getContext("2d");x.fillStyle="#BFE0F0";x.fillRect(0,0,5,5);x.imageSmoothingEnabled=true;x.drawImage(im,KIT.PX-11,0,22,23,0,0,5,5);g.imageSmoothingEnabled=true;g.drawImage(t,0,0,5,5,5,5,46,46);g.imageSmoothingEnabled=false;}
    g.fillStyle=OUT;g.fillRect(27,5,1,6);g.fillRect(27,45,1,6);g.fillRect(5,27,6,1);g.fillRect(45,27,6,1);}   // what the camera sees
}

/* ---------- what can happen here ---------- */
const G=id=>W.gente[id],azar=()=>Math.random()<.5;
async function mueve(id,x,y,n){const p=G(id);if(!p)return;const x0=p.x,y0=p.y,bb=id==="mama"&&G("bebe")&&G("bebe").z?G("bebe"):null;if(bb)setTimeout(function sigue(){bb.x=p.x+(p.sent?0:9);bb.y=p.y-(p.sent?15:26);bb.z=p.y+1;if(Math.abs(p.x-x)+Math.abs(p.y-y)>1)setTimeout(sigue,TICK);},TICK);n=n||Math.max(3,Math.round(Math.hypot(x-x0,y-y0)/6));p.sent=0;for(let i=1;i<=n;i++){p.x=x0+(x-x0)*i/n;p.y=y0+(y-y0)*i/n-(i%2);await wait(TICK);}p.x=x;p.y=y;}
async function vuelaA(x0,y0,x1,y1,mord,k){W.vuela={x:x0,y:y0,mord,k:k||1};for(let i=1;i<=7;i++){W.vuela.x=x0+(x1-x0)*i/7;W.vuela.y=y0+(y1-y0)*i/7-Math.sin(Math.PI*i/7)*10;await wait(TICK);}W.vuela=null;}
const flashazo=()=>{W.flash=F;tone(1800,0,.05,"square",.06);tone(2400,.04,.12,"sine",.05);};
const nFotos=()=>(W.fotos||[]).filter(Boolean).length;
const acts={
  async anda(o){const L=SITIO[o.a]||[+o.x,+o.y];await mueve(o.quien,L[0],L[1]);},
  async entra(){const q=W.cq,L=LUGAR.centro;q.x=LUGAR.puerta[0];q.y=LUGAR.puerta[1];q.s=LUGAR.puerta[2];q.vis=1;await wait(200);await hopTo(L[0],L[1],3,L[2]);},
  async burbuja(o){if(o.quien==="cq"){W.cq.bub=o.que;SFX.coqui();bounce(6);}else if(G(o.quien))G(o.quien).bub=o.que;},
  async calla(){Object.values(W.gente).forEach(p=>{if(p)p.bub=null;});W.cq.bub=null;},
  async pose(o){const p=G(o.quien||"abuela");if(p)p.pose=o.que;},
  async saluda(o){const p=G(o.quien);if(!p)return;if(o.quien==="bebe"){p.est="clap";SFX.pio();}else p.pose="wave";await wait(+o.ms||700);if(o.quien==="bebe")p.est="idle";else p.pose="idle";},
  /* ---- story 6: a slice for everyone ---- */
  // the frog goes straight to the covered cake and sniffs; abuela wags a finger
  async huele(){const q=W.cq,L=LUGAR.puerta;q.x=L[0];q.y=L[1];q.s=L[2];q.vis=1;await wait(200);await acts.ir({a:"huele"});q.bub="bizcocho";SFX.coqui();bounce(5);await wait(600);G("abuela").pose="dedo";},
  async atras(){G("abuela").pose="idle";W.cq.bub=null;await acts.ir({a:"centro"});},
  async beso(){const p=G("mama");p.pose="wave";p.bub="amor";await wait(900);p.bub=null;p.pose="idle";},
  async despierta(){const p=G("abuelo");p.dormido=0;p.rie=1;SFX.blip();bounce(4);await wait(500);p.rie=0;p.pose="wave";await wait(600);p.pose="idle";},
  // the cover comes off: seven slices. Three fly to his plate in the corner.
  async duerme(){G("abuelo").dormido=1;},
  async destapa(){SFX.luz();W.pastel=7;fx({t:"star",n:10,pts:[[108,134],[132,134],[120,128]]});await wait(600);},
  async tres(){W.plato=0;for(let i=0;i<3;i++){W.pastel--;SFX.blip();await vuelaA(120,140,50,24);W.plato++;}await wait(300);},
  // abuela puts a slice from the dish in the frog's hands
  async dale(){const ab=G("abuela");await acts.ir({a:"abuela"});ab.pose="offer";W.pastel=Math.max(0,W.pastel-1);ab.lleva=1;SFX.blip();await wait(350);ab.lleva=0;W.lleva=1;ab.pose="idle";await wait(250);await acts.ir({a:"centro"});},
  // the frog carries it to someone
  async da(o){await acts.ir({a:o.en});await wait(150);W.lleva=0;const p=G(o.en);p.trozo=1;SFX.blip();await wait(350);},
  // one happy bite; the slice stays on that person's plate until everyone eats together at the end
  async come(o){const p=G(o.quien);if(!p)return;SFX.munch();p.trozo="mordido";if(o.quien==="bebe"){p.est="clap";SFX.pio();}else p.rie=1;await wait(600);p.rie=0;if(o.quien==="bebe")p.est="idle";await acts.ir({a:"centro"});},
  async comen(){for(let k=0;k<3;k++){SFX.munch();await wait(260);}Object.keys(W.gente).forEach(id=>{const p=G(id);if(p.trozo){p.trozo=0;if(id==="bebe")p.est="come";else p.servido=1;}});await wait(800);},
  // the wrong person takes one bite. The bitten slice goes onto the frog's plate.
  async muerde(o){const p=G(o.quien);if(!p)return;SFX.munch();p.trozo="mordido";if(o.quien==="bebe")p.est="come";await wait(700);if(o.quien==="bebe")p.est="idle";},
  // abuela swaps: the bitten slice to his plate, a whole one from his plate to the one who was named
  async abda(o){const ab=G("abuela"),x=G(o.de),p=G(o.a),h=SITIO[o.a];if(x){x.trozo=0;await vuelaA(x.x,x.y-30,50,24,1);}
    ab.lleva=1;ab.pose="offer";await mueve("abuela",h[0]+(o.a==="bebe"?22:-2),o.a==="bebe"?h[1]-4:150);await wait(150);ab.lleva=0;p.trozo=1;SFX.blip();await wait(300);},
  async vuelve(){const ab=G("abuela");ab.pose="idle";await mueve("abuela",SITIO.abuela[0],SITIO.abuela[1]);await acts.ir({a:"centro"});},
  // the last slice on the dish goes to the one who has had none
  async ultimo(o){const ab=G("abuela"),h=SITIO[o.a];W.pastel=0;ab.lleva=1;ab.pose="offer";await mueve("abuela",h[0]+(o.a==="bebe"?22:-2),o.a==="bebe"?h[1]-4:150);await wait(150);ab.lleva=0;G(o.a).trozo=1;SFX.blip();await wait(300);},
  // she brings the frog his own plate
  async suplato(){const ab=G("abuela");ab.lleva="plato";ab.pose="offer";W.plato=null;await mueve("abuela",158,200);ab.dir=1;await wait(300);},
  async final6(){const ab=G("abuela"),q=W.cq,enteros=3-(W.lost||0);ab.lleva=0;ab.pose="idle";W.plato=3;
    for(let i=0;i<3;i++){W.plato=2-i;SFX.munch();bounce(3);await wait(300);}
    if(enteros<=0){const b=G("bebe");await mueve("bebe",q.x-2,q.y+26,8);b.est="clap";b.trozo=0;W.vuela=null;await vuelaA(b.x,b.y-14,q.x+16,q.y+8,1,.8);SFX.munch();q.bub="amor";await wait(900);q.bub=null;}
    else if(enteros>=3){W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[60,30],[180,34],[120,22],[96,44],[150,40]]});await wait(900);}
    else{q.bub="amor";SFX.coqui();await wait(800);q.bub=null;}},
  /* ---- story 7: three photos ---- */
  // the boy and the girl run in and hug the baby
  async corren(){const a=G("hermano"),b=G("hermana");a.vis=1;b.vis=1;a.x=40;a.y=126;b.x=34;b.y=124;await Promise.all([mueve("hermano",94,198,10),mueve("hermana",48,200,10)]);G("bebe").est="clap";SFX.pio();await wait(800);G("bebe").est="idle";},
  // two people take their places, left and right; which side each is on is drawn fresh
  async lados(o){const s=azar()?0:1,P=o.donde==="juntos"?JUNTOS:o.donde==="parados"?PARADOS:APARTE;if(o.donde==="parados"){G(o.a).servido=0;G(o.b).servido=0;}await Promise.all([mueve(o.a,P[s][0],P[s][1]),mueve(o.b,P[1-s][0],P[1-s][1])]);},
  async sientan(){await Promise.all([mueve("mama",SITIO.mama[0],SITIO.mama[1]),mueve("papa",SITIO.papa[0],SITIO.papa[1])]);G("mama").sent=1;G("papa").sent=1;},
  async camara(){const ab=G("abuelo");await mueve("abuelo",CAMARA[0],CAMARA[1]);ab.dir=-1;ab.pose="foto";await wait(250);},
  // the frog hops beside someone
  async junto(o){const p=G(o.en),q=W.cq,cx=p.x+(p.x<120?-24:24),s=p.y<150?.9:1;await hopTo(Math.round(cx-16),Math.round(p.y+5-27),2,s);},
  // a photo under the sign: a flash, and it pops up for a moment
  async prueba(o){flashazo();await wait(300);const p=G(o.con);fx({t:"star",n:8,pts:[[Math.round(p.x),Math.round(p.y)-50]]});await wait(500);},
  // a photo for the wall. ok: the frog and that person, straight. Not ok: that person alone, the frog's foot at the edge, crooked.
  async dispara(o){const ok=o.ok==="1"||o.ok===1,i=nFotos(),p=G(o.con);if(!ok){p.pose="wave";await wait(300);}flashazo();await wait(350);W.fotos[i]=ok?{q:o.solo?[o.con]:["coqui",o.con],ok:1}:{q:[o.con],ok:0,pata:1};SFX.blip();
    fx({t:"star",n:ok?10:4,pts:[[86+i*24,50]]});await wait(700);p.pose="idle";},
  // the camera goes off at abuelo's feet: a photo of his slippers
  async pies(){const ab=G("abuelo"),i=nFotos();ab.pose="idle";ab.bub="q";await wait(500);flashazo();await wait(350);W.fotos[i]={ok:0,pies:1};SFX.bonk();ab.bub=null;await wait(700);ab.pose="foto";},
  // one child alone in the middle; the camera's little window shows a blur
  async solo(o){const otro=o.quien==="hermano"?"hermana":"hermano";await Promise.all([mueve(o.quien,120,146),mueve(otro,44,204),acts.ir({a:"centro"})]);W.visor={quien:o.quien,nitido:0};
    W.apodo={[o.quien]:o.quien==="hermano"?"el_dice_hola":"ella_dice_hola"};await wait(400);},   // while abuelo asks who it is, a poke on the child gets a hello, not a name
  async nitido(){if(W.visor)W.visor.nitido=1;SFX.luz();await wait(450);},
  async quitavisor(){W.visor=null;W.apodo=null;},
  // the wall, then everyone together for one last photo
  async final7(){const ok=(W.fotos||[]).filter(f=>f&&f.ok).length;W.visor=null;
    V.fotos=(W.fotos||[]).map(f=>!f?"":f.pies?"pies":f.q.filter(k=>k!=="coqui")[0]+"."+(f.ok?1:0)+(f.pata?"p":"")+(f.q.includes("coqui")?"c":"")).join("-");   // the wall as he left it, for the next storyfx({t:"star",n:14,pts:(W.fotos||[]).map((f,i)=>f&&f.ok?[86+i*24,50]:null).filter(Boolean)});await wait(900);
    if(ok>=3){W.heart=1;SFX.win();}else SFX.coqui();await wait(500);
    const ab=G("abuelo");ab.pose="idle";ab.dir=1;G("mama").servido=0;G("papa").servido=0;
    await Promise.all([mueve("mama",98,146),mueve("papa",142,146),mueve("abuelo",172,160),mueve("abuela",66,160),mueve("hermano",140,190),mueve("hermana",100,190),acts.ir({a:"centro"})]);G("bebe").x=106;G("bebe").y=124;G("bebe").z=147;await wait(300);},
  async flash(){flashazo();await wait(500);},
  /* ---- story 8: abuelo cannot find his glasses ---- */
  // the start of story 8: the children by the frog, abuelo wandering with his coffee, his glasses up on his head; the photos from La foto on the wall
  async inicio8(){const a=G("hermano"),b=G("hermana"),ab=G("abuelo");a.vis=1;b.vis=1;a.x=156;a.y=200;a.dir=-1;b.x=84;b.y=200;ab.sent=0;ab.x=190;ab.y=150;ab.pose="taza";ab.gafas="arriba";ab.dir=-1;const bb=G("bebe");bb.x=97;bb.y=112;bb.z=128;   // the baby is on mamá's lap
    (V.mem_fotos||"").split("-").forEach((t,i)=>{if(!t||i>2)return;if(t==="pies"){W.fotos[i]={ok:0,pies:1};return;}const m=t.split("."),f=m[1]||"";W.fotos[i]={q:(f.includes("c")?["coqui"]:[]).concat([m[0]]),ok:f[0]==="1"?1:0,pata:f.includes("p")?1:0};});},
  async tropieza(){const ab=G("abuelo");await mueve("abuelo",162,176);W.golpe=F;SFX.bonk();ab.rie=1;await wait(600);ab.rie=0;W.borroso=1;await wait(1100);W.borroso=0;await wait(200);},
  async acerca(){await acts.ir({a:"centro"});await mueve("abuelo",122,180);G("abuelo").dir=-1;await wait(200);},
  async palmada(){W.cq.bub="amor";SFX.coqui();bounce(5);await wait(700);W.cq.bub=null;},
  async rie(o){const p=G(o.quien||"abuelo");p.rie=1;await wait(700);p.rie=0;},
  // a child creeps up behind the frog and covers his eyes
  async tapa(o){const q=W.cq,ab=G("abuelo");await acts.ir({a:"centro"});if(Math.abs(ab.x-120)<30)await mueve("abuelo",164,178);await mueve(o.quien,q.x+16,q.y+22);G(o.quien).pose="ojos";W.tapaojos=o.quien;SFX.blip();await wait(400);},
  async suelta(o){W.tapaojos=null;G(o.quien).pose="idle";await mueve(o.quien,o.quien==="hermano"?152:86,200);},
  async gira(){const ab=G("abuelo");ab.dir=-(ab.dir||1);await wait(200);},
  // abuelo walks over to mamá or papá
  async abva(o){const p=G(o.a),ab=G("abuelo");await mueve("abuelo",p.x+(p.x<120?-22:22),p.y+10);ab.dir=p.x<ab.x?-1:1;await wait(200);},
  // the baby, on mamá's arm, pulls the glasses down onto his nose
  async espejuelos(){const m=G("mama"),b=G("bebe"),ab=G("abuelo");m.servido=0;if(m.sent)await mueve("mama",PARADOS[0][0],PARADOS[0][1]);b.x=m.x+9;b.y=m.y-26;b.z=m.y+1;await mueve("abuelo",m.x+28,m.y+6);ab.dir=-1;await wait(300);b.est="clap";SFX.pio();await wait(400);ab.gafas=1;SFX.luz();fx({t:"star",n:10,pts:[[Math.round(ab.x),Math.round(ab.y)-58]]});await wait(700);b.est="idle";},
  async fin8(){await wait(900);},
  async corazon(){W.aciertos=(W.aciertos||0)+1;SFX.luz();await wait(300);},   // right the first time: a heart that stays by abuelo's cup
  async final8(){const ab=G("abuela"),ao=G("abuelo"),n=3-(W.lost||0);ao.pose="taza";
    if(n>=3){for(let k=0;k<3;k++){glu();await wait(300);}W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[60,30],[180,34],[120,22],[96,44],[150,40]]});await wait(900);}
    else if(n>0){for(let k=0;k<n;k++){glu();await wait(300);}SFX.coqui();await wait(600);}
    else{ao.bub="q";SFX.drop();await wait(700);ao.bub=null;await mueve("abuela",ao.x-30,ao.y+2);ab.pose="offer";ab.dir=1;SFX.luz();W.relleno=1;await wait(900);ab.pose="idle";}},
};
const glu=()=>tone(300,0,.09,"sine",.09,170);
// the thing at stake takes a step
async function stake(lost,max,en){const t=S.stake.thing;
  if(t==="cafe"){const ab=G("abuelo");W.gotas={x:ab.x+(ab.dir<0?-13:13),y:ab.y-28,f:F};SFX.drop();await wait(250);SFX.drop();await wait(500);return;}
  if(t==="fotos"){SFX.bonk();await wait(300);return;}
  SFX.bonk();await wait(300);}
function poke(what){const p=W.gente&&W.gente[what];if(p&&!p.bub){p.bub="amor";const my=runId;setTimeout(()=>{if(my===runId&&p.bub==="amor")p.bub=null;},1400/FAST);}}
const estado=W=>"gente="+Object.keys(W.gente||{}).filter(k=>W.gente[k]&&W.gente[k].vis!==0).map(k=>k+"@"+Math.round(W.gente[k].x)+","+Math.round(W.gente[k].y)+(W.gente[k].sent?"s":"")+(W.gente[k].bub?"["+W.gente[k].bub+"]":"")).join(" ")+" plato="+W.plato+" pastel="+W.pastel+" lleva="+(W.lleva||0)+" fotos="+JSON.stringify(W.fotos||[])+" visor="+(W.visor?W.visor.quien+W.visor.nitido:"-")+" tapa="+(W.tapaojos||"-")+" cafe="+(W.cafe||0);
const G0=()=>({mama:{x:SITIO.mama[0],y:SITIO.mama[1],sent:1,pose:"idle"},papa:{x:SITIO.papa[0],y:SITIO.papa[1],sent:1,pose:"idle"},abuelo:{x:SITIO.abuelo[0],y:SITIO.abuelo[1],sent:1,pose:"idle"},
  bebe:{x:SITIO.bebe[0],y:SITIO.bebe[1],est:"idle"},abuela:{x:SITIO.abuela[0],y:SITIO.abuela[1],pose:"idle",dir:-1},hermano:{x:SITIO.hermano[0],y:SITIO.hermano[1],pose:"idle",vis:0},hermana:{x:SITIO.hermana[0],y:SITIO.hermana[1],pose:"idle",vis:0}});
KIT.escena({id:"sala",CAM:{wide:[22,0,196,216],sofa:[52,48,150,165.3]},heartAt:[107,6],lugar:LUGAR,cosas:COSAS,
  fresh:()=>({gente:G0(),fotos:[null,null,null],luz:1,pastel:null,plato:null,lleva:0,vuela:null,flash:0,ave:null,cafe:0,relleno:0,aciertos:0,apodo:null,visor:null,borroso:0,tapaojos:null,golpe:0,gotas:null,camMesa:0,cq:{x:LUGAR.centro[0],y:LUGAR.centro[1],s:1,dy:0,al:1,vis:1,bub:null}}),
  draw,hud,poke,acts,stake,talkAt,estado});
window.SALA={FAM,SITIO,LUGAR,trozo};
})();
