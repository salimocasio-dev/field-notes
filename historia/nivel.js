"use strict";
/* ============================================================
   Coquí · the level check (the plan: "The level check and the fort check").
   For someone who already understands some Spanish. Touch only.
   A sentence; four pictures; he touches one. Items run easy to hard, in the
   order of the stories. A right answer moves it up, a miss moves it down.
   It stops where he starts to miss, or after 16 items.
   Nothing says right or wrong while it runs: it is a check, not a lesson.
   What it presumes he knows starts at "se queda" (holding), is due for a cold
   check the next morning, and opens for speaking at once (palabras.js, presume).
   It reuses the pictures and the recorded sentences of the ¿Cuál? pairs.
   It covers the stories built so far. Each new scene adds items to NV.
   ============================================================ */
// w: the word asked. s: the story (by its number in the course) that teaches it. p: four pictures, the first is the one that fits:
// [the pair's word, which of its two pictures, the x the square crop is centred on (default: the middle of the pair's camera)]
const NV=[
 {w:"abuela",s:1,p:[["abuela","si",166],["mamá","si"],["papá","si"],["hermana","si"]]},
 {w:"puerta",s:1,p:[["puerta","si",166],["ventana","si",112],["silla","si"],["sol","si"]]},
 {w:"abre",s:2,p:[["abre","si",112],["abre","no",112],["puerta","si",166],["jugo","si"]]},
 {w:"hola",s:2,p:[["hola","si",160],["adiós","si",160],["se sienta","si",80],["juega","si",130]]},
 {w:"silla",s:4,p:[["silla","si"],["silla","no"],["jugo","si"],["ventana","si",112]]},
 {w:"jugo",s:4,p:[["jugo","si"],["agua","si"],["silla","si"],["papá","si"]]},
 {w:"se sienta",s:4,p:[["se sienta","si",80],["se sienta","no",96],["niño","si"],["abuelo","si"]]},
 {w:"quiero",s:5,p:[["quiero","si",94],["quiero","no",94],["¿cómo estás?","si",94],["mamá","si"]]},
 {w:"mamá",s:6,p:[["mamá","si"],["papá","si"],["abuelo","si"],["hermana","si"]]},
 {w:"abuelo",s:6,p:[["abuelo","si"],["abuelo","no"],["papá","si"],["hermano","si"]]},
 {w:"familia",s:6,p:[["familia","si"],["mamá","si"],["hermano","si"],["niña","si",100]]},
 {w:"hermana",s:7,p:[["hermana","si"],["hermano","si"],["hermana","no"],["bebé","si",70]]},
 {w:"tú",s:8,p:[["tú","si",118],["tú","no",118],["yo","si",118],["hermano","si"]]},
 {w:"niña",s:9,p:[["niña","si",100],["niño","si"],["niña","no",100],["abuelo","si"]]},
 {w:"flor",s:9,p:[["flor","si",60],["flor","no",60],["sol","no",150],["silla","si"]]},
 {w:"juega",s:9,p:[["juega","si",130],["juega","no",130],["niña","si",100],["sol","si"]]},
 {w:"amigo",s:10,p:[["amigo","si",100],["amigo","no",100],["niño","si"],["mamá","si"]]},
 {w:"ven",s:10,p:[["ven","si",142],["ven","no",142],["niño","si"],["papá","si"]]},
 {w:"vamos",s:11,p:[["vamos","si",150],["vamos","no",150],["ven","no",142],["juega","si",130]]},
 {w:"hasta mañana",s:11,p:[["hasta mañana","si",120],["hasta mañana","no",120],["jugo","si"],["niña","si",100]]},
 // place 2, El parque
 {w:"perro",s:12,p:[["perro","si"],["perro","no"],["gato","no"],["árbol","si"]]},
 {w:"corre",s:12,p:[["corre","si"],["corre","no"],["camina","si",116],["despacio","si"]]},
 {w:"dos",s:13,p:[["dos","si"],["uno","si"],["tres","si"],["hay","no"]]},
 {w:"rápido",s:14,p:[["rápido","si"],["rápido","no"],["despacio","no"],["perro","si"]]},
 {w:"tira",s:15,p:[["tira","si",134],["tira","no",132],["dame","si",128],["tiene","si",130]]},
 {w:"coge",s:15,p:[["coge","si",138],["coge","no",134],["dame","no",128],["salta","si"]]},
 {w:"arriba",s:16,p:[["arriba","si",64],["arriba","no",176],["abajo","si",90],["salta","no"]]},
 {w:"mi",s:17,p:[["mi","si",114],["mi","no",126],["tira","si",134],["tiene","si",130]]},
 {w:"pato",s:18,p:[["pato","si",100],["pato","no",100],["pez","si",156],["pájaro","no",176]]},
 {w:"vuela",s:18,p:[["vuela","si",152],["vuela","no",96],["nada","si",150],["pez","si",156]]},
 {w:"rojo",s:19,p:[["rojo","si",150],["rojo","no",150],["verde","si",96],["azul","si",150]]},
 {w:"negro",s:20,p:[["negro","si",150],["negro","no",150],["amarillo","no",150],["blanco","si",133]]},
 {w:"come",s:21,p:[["come","si"],["come","no"],["bebe","si",152],["cansado","si"]]},
 {w:"señora",s:22,p:[["señora","si",146],["señora","no",146],["señor","si"],["mujer","no",146]]},
 {w:"viejo",s:22,p:[["viejo","si"],["viejo","no"],["duerme","no"],["triste","si"]]},
 {w:"triste",s:23,p:[["triste","si"],["triste","no"],["contento","si"],["cansado","si"]]},
 {w:"plato",s:24,p:[["plato","si"],["plato","no"],["cuchara","si"],["taza","no"]]},
 {w:"taza",s:24,p:[["taza","si"],["taza","no"],["plato","si"],["cuchara","no"]]},
 {w:"cuchara",s:25,p:[["cuchara","si"],["cuchara","no"],["tenedor","no"],["plato","si"]]},
 {w:"tengo hambre",s:26,p:[["tengo hambre","si"],["tengo hambre","no"],["tengo sed","si"],["comida","no"]]},
 {w:"arroz",s:27,p:[["arroz","si"],["arroz","no"],["pollo","si"],["olla","no"]]},
 {w:"olla",s:27,p:[["olla","si"],["olla","no"],["habichuelas","si"],["ya","si"]]},
 {w:"pollo",s:28,p:[["pollo","si"],["pollo","no"],["arroz","si"],["sal","si"]]},
 {w:"caliente",s:29,p:[["caliente","si"],["caliente","no"],["frío","si"],["olla","si"]]},
 {w:"leche",s:30,p:[["leche","si"],["leche","no"],["queso","si"],["pan","si"]]},
 {w:"queso",s:30,p:[["queso","si"],["queso","no"],["leche","si"],["fruta","si"]]},
 {w:"guineo",s:31,p:[["guineo","si"],["guineo","no"],["china","si"],["pan","no"]]},
 {w:"lleno",s:32,p:[["lleno","si"],["lleno","no"],["vacío","si"],["mantequilla","si"]]}];
const CW=96,CH=106;   // four cells, two by two (the gap between them, GAP, is set from the scale in cual.js)
const PASO=Math.max(2,Math.ceil(NV.length/14));   // how far a right answer moves him up: the list grows with every scene, the check must still reach its top in about a dozen items
let NQ={i:0,hecho:[],pos:0,run:0,toque:null,listo:-1,fin:null};
function celda(k){return [(k%2)*(CW+GAP),Math.floor(k/2)*(CH+GAP)];}
function nivelDibuja(){const a=F>>1,keep=W;dc.imageSmoothingEnabled=false;dc.clearRect(0,0,cv.width,cv.height);opcionesVer(!!PAN);
  if(PAN)PAN.forEach((p,k)=>{W=p.w;W.fx=[];p.E.draw(c,W,a);if(W.resp)respDraw(c,a);const xy=celda(k),cm=p.cam;dc.drawImage(sc,cm[0],cm[1],cm[2],cm[3],xy[0],xy[1],CW,CH);});
  W=keep;}
function nivelPanel(pic,byW){const it=byW[pic[0]],spec=it[pic[1]],E2=ESCENAS[spec.esc||it.esc],cm=spec.cam,h=cm[3],w=h*CW/CH,cx=pic[2]!=null?pic[2]:cm[0]+cm[2]/2;
  return {w:panelW(spec,E2),E:E2,cam:[Math.max(0,Math.min(E2.SW-w,cx-w/2)),cm[1],w,h]};}
async function nivelItem(q,byW){anillo(null);const orden=[0,1,2,3].sort(()=>Math.random()-.5),it=byW[q.p[0][0]];   // where the right picture sits is drawn fresh
  PAN=orden.map(k=>Object.assign(nivelPanel(q.p[k],byW),{right:k===0}));
  await wait(450);const my=runId;let got=null,ms=0,tEnd=0,res;const p=new Promise(r=>res=r);
  NQ.toque=k=>{if(!tEnd||got!=null||!PAN[k])return;got=k;ms=Math.round((performance.now()-tEnd)*FAST);anillo(k,"sel");res();};   // the ring only shows which one he touched: a check never says right or wrong   // a touch before the sentence ends does not count
  await say(it.say,0);tEnd=performance.now();NQ.listo=NQ.i;
  const rep=setInterval(()=>{if(got==null&&!speaking&&my===runId)playClip(it.say);},9000/FAST);
  await p;clearInterval(rep);SFX.blip();await wait(350);PAN=null;return {w:q.w,s:q.s,ok:!!PAN_OK(got,orden),ms};}
const PAN_OK=(got,orden)=>orden[got]===0;
// which stories he is presumed to know: every story up to the highest one where he was right on all its items and on three in four of everything asked up to there
function nivelFrontera(h){let S0=0;const tope=Math.max(...NV.map(q=>q.s));for(let s=1;s<=tope;s++){const de=h.filter(x=>x.s===s),hasta=h.filter(x=>x.s<=s);if(!de.length)continue;
    const bien=hasta.filter(x=>x.ok).length/hasta.length;if(de.every(x=>x.ok)&&bien>=.75)S0=s;}   // one slip low down does not hold him back if he is right on what comes after
  return S0;}
async function nivelRun(){runId++;hush();callaLetras();NQ={i:0,hecho:[],pos:0,run:1,toque:null,listo:-1,fin:null};$("#go").style.display="none";pantalla("");foot(0,0,0);estado("play");
  await Promise.race([voiceReady,sleep(6000)]);const byW={};CU.items.forEach(it=>byW[it.w]=it);
  const usados=new Set();let pos=0,seguidos=0,giros=0,ultimo=null;
  try{for(let n=0;n<(Q.get("todo")?NV.length:16);n++){   // ?todo=1 shows every item in order, for checking the pictures
      // the next item: the nearest one not yet asked, in the direction the last answer points
      let i=pos;const dir=ultimo===false?-1:1;while(i>=0&&i<NV.length&&usados.has(i))i+=dir;if(i<0||i>=NV.length){i=pos;while(i>=0&&i<NV.length&&usados.has(i))i-=dir;}if(i<0||i>=NV.length)break;
      if(Q.get("todo")){i=n;if(i>=NV.length)break;}usados.add(i);step(n);NQ.i=n;window.__cur=NV[i].s;const r=await nivelItem(NV[i],byW);NQ.hecho.push(Object.assign({i},r));step(NQ.hecho.length);   // the bar fills with the items he has answered
      if(ultimo!=null&&ultimo!==r.ok)giros++;ultimo=r.ok;seguidos=r.ok?0:seguidos+1;pos=r.ok?i+PASO:i-1;if(pos<0)pos=0;if(pos>=NV.length)pos=NV.length-1;
      const arriba=k=>NQ.hecho.some(h=>h.i===k&&h.ok);if(!Q.get("todo")&&(seguidos>=3||giros>=5||(arriba(NV.length-1)&&arriba(NV.length-2))))break;}                                   // three misses in a row, it has gone up and down enough, or he is right at the very top: this is his level
    mkDots(Math.max(1,NQ.hecho.length));step(NQ.hecho.length);}catch(e){if(e!=="stop")throw e;return;}   // it can stop early: the bar then shows exactly the items he was asked, all done
  PAN=null;const S0=nivelFrontera(NQ.hecho),ids=CURSO.lugares.flatMap(l=>l.cuentos||[]).slice(0,S0),pal=[];
  for(const id of ids){try{const j=await (await fetch("cuentos/"+id+".json")).json();(j.focus_words||[]).forEach(w=>{if(!pal.includes(w))pal.push(w);});}catch(e){}}
  if(!Q.get("fast")||Q.get("rec"))PAL.presume(pal,ids,NQ.hecho);
  NQ.fin={S0,ids,pal};NQ.run=0;const sig=CURSO.lugares.flatMap(l=>l.cuentos||[])[S0],T=id=>CURSO.cuentos[id].t;
  pantalla("Level check done",[S0?`You already understand the first ${S0} ${S0===1?"story":"stories"}. Their ${pal.length} words are yours to keep: each gets one cold check tomorrow, and they are open for speaking now.`:"You start at the beginning. Nothing was skipped.",
    sig?`You start at: <b>${T(sig)}</b>.`:"Every story built so far is open as done. More are being built."]);
  estado("end",true);$("#next").textContent="To the map";$("#next").classList.add("blu");$("#next").onclick=()=>salir("app.html?tab=mapa");foot(1,0,0);}
async function nivelArranca(){CU=await cualCarga();S=CU;E=ESCENAS.frente;SW=E.SW;SH=E.SH;sc.width=SW;sc.height=SH;
  document.title="Coquí · Level check";W=EMPTY();cam=E.CAM.wide.slice();voiceReady=loadVoice();setInterval(()=>{F++;nivelDibuja();},TICK);
  cualSize(2,2,CW,CH);mkOpts(4,k=>{if(NQ.toque)NQ.toque(k);});
  mkDots(Q.get("todo")?NV.length:16);estado("start",true);pantalla("Level check");fit();   // the start screen: a title and the disc; the bar has its true number of segments (16 at most) from the start
  $("#go").onclick=()=>{try{ac().resume();}catch(e){}nivelRun();};}
window.Nivel={get pan(){return PAN?PAN.map(p=>({right:p.right})):null;},get i(){return NQ.i;},get listo(){return NQ.listo===NQ.i;},get hecho(){return NQ.hecho;},get fin(){return NQ.fin;},toca(k){if(NQ.toque)NQ.toque(k);},get running(){return !!NQ.run;},frontera:nivelFrontera,NV};
