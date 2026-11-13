"use strict";
/* ============================================================
   Coquí · word records and the scheduler.
   Every word has its own record per skill: ear (listening) and mouth (speaking).
   A miss in one skill never touches the other.
   The rules are the plan's ("Progression logic" and "Misses"):
   - Stages he sees: heard, found, holding, good.
   - When a word comes back is set by his own answers: right stretches the gap,
     right but slow keeps it, a miss shortens it and brings the word back later in the session.
   - How he is asked on a return: step 1 to 4. Two right in a row moves up a step, a miss moves down one.
   - Good: right on at least three returns, spread over two weeks or more.
   - Three misses in a row on returns: parked for a week, and flagged as a likely bad picture.
   Progress lives on this one phone (localStorage), as the plan says, until accounts come.
   ============================================================ */
const PAL=(()=>{
  const KEY="coqui.palabras.v1",DAY=864e5,SLOW=2000,STAGES=["nuevo","oído","encontrado","se queda","bien"];
  let db={palabras:{},dias:{},cuentos:{},ajustes:{min:30,todo:0,bienvenida:0},minutos:0,v:1};
  try{const t=localStorage.getItem(KEY);if(t)db=Object.assign(db,JSON.parse(t));}catch(e){}
  db.cuentos=db.cuentos||{};db.ajustes=Object.assign({min:30,todo:0,bienvenida:0},db.ajustes||{});
  const save=()=>{try{localStorage.setItem(KEY,JSON.stringify(db));}catch(e){}};
  const now=()=>(typeof window!=="undefined"&&window.__PAL_NOW)||Date.now();   // a fixed clock for checks
  const nextMorning=t=>{const d=new Date(t);d.setHours(4,0,0,0);return d.getTime()+DAY;};
  function rec(w){if(!db.palabras[w])db.palabras[w]={w,primera:now(),oida:0,ear:skill(),mouth:skill()};return db.palabras[w];}
  function skill(){return {etapa:0,paso:1,seguidas:0,fallos:0,gap:0,due:0,aciertos:[],ultima:0,aparcada:0,marca:0,n:0,bien:0};}
  // the first meeting: he heard it in a story. It comes back the next day for ¿Cuál?
  function oida(w){const r=rec(w);r.oida++;const e=r.ear;if(e.etapa<1)e.etapa=1;if(!e.due){e.due=nextMorning(now());e.gap=1;}return r;}
  // one answer in one skill. intro=true while the word is still being introduced (inside its own story):
  // it moves the stage to "found" but does not move the schedule.
  function responde(w,sk,ok,ms,intro){const r=rec(w),e=r[sk],t=now();e.n++;if(ok)e.bien++;e.ultima=t;
    if(intro){if(ok&&e.etapa<2)e.etapa=2;if(e.etapa<1)e.etapa=1;if(!e.due){e.due=nextMorning(t);e.gap=1;}save();return e;}
    if(ok){e.fallos=0;e.seguidas++;if(e.seguidas>=2&&e.paso<4){e.paso++;e.seguidas=0;}
      const slow=ms!=null&&ms>SLOW;if(!slow)e.gap=Math.max(1,(e.gap||1)*2.5);   // right but slow: counts as right, the gap is not stretched
      e.aciertos.push(t);e.due=t+e.gap*DAY;if(e.etapa<2)e.etapa=2;if(e.etapa<3&&e.aciertos.length>=1)e.etapa=3;
      const a=e.aciertos;if(a.length>=3&&a[a.length-1]-a[0]>=14*DAY)e.etapa=4;}
    else{e.seguidas=0;e.fallos++;if(e.paso>1)e.paso--;if(e.etapa>3)e.etapa=3;e.gap=Math.max(1,(e.gap||1)/3);e.due=t+10*6e4;   // back later in this session, and sooner after it
      if(e.fallos>=3){e.aparcada=t+7*DAY;e.due=e.aparcada;e.marca=1;e.fallos=0;e.etapa=Math.min(e.etapa,2);e.aciertos=[];}}   // parked for a week; flagged
    save();return e;}
  // a finished story: every word it brings is heard; each decision is an answer on the ear record.
  function cuento(S,log){const t=now(),pend=w=>{const r=db.palabras[w];return !!(r&&r.ear.due&&r.ear.due<=t);};
    const ret=new Set((log||[]).filter(x=>x.word&&pend(x.word)).map(x=>x.word));   // words that were due: this play is their return
    [...(S.focus_words||[]),...(S.back_again||[])].forEach(w=>oida(w));
    (log||[]).forEach(x=>{if(x.word)responde(x.word,"ear",x.ok,x.ms,!ret.has(x.word));});
    const d=new Date(now()).toISOString().slice(0,10);db.dias[d]=(db.dias[d]||0)+1;
    db.cuentos=db.cuentos||{};const c=db.cuentos[S.id]||(db.cuentos[S.id]={n:0,primera:t});c.n++;c.ultima=t;c.perdido=(S._lost||0);save();}
  // the level check: words he is presumed to know start at "se queda", are due for a cold check the next morning, and open for speaking at once.
  // The stories that teach them count as done, so the map starts him further along. He can still play them.
  function presume(words,stories,log){const t=now();(words||[]).forEach(w=>{const r=rec(w),e=r.ear;if(e.etapa<3){e.etapa=3;e.paso=Math.max(e.paso,2);e.gap=1;e.due=nextMorning(t);e.presunta=1;}});
    (stories||[]).forEach(id=>{const c=db.cuentos[id]||(db.cuentos[id]={n:0,primera:t});if(!c.n){c.n=1;c.ultima=t;c.presunto=1;}});
    db.nivel={t,log:log||[],historias:(stories||[]).length};const d=new Date(t).toISOString().slice(0,10);db.dias[d]=db.dias[d]||1;save();}
  function oido(id){db.oidos=db.oidos||{};db.oidos[id]=(db.oidos[id]||0)+1;save();}   // Escuchar: how often a piece was heard to the end. Nothing is scored.
  function minutos(m){db.minutos=(db.minutos||0)+m;const d=new Date(now()).toISOString().slice(0,10);db.dias[d]=db.dias[d]||1;save();}
  function vence(sk,t){t=t||now();return Object.values(db.palabras).filter(r=>r[sk].etapa>0&&r[sk].due&&r[sk].due<=t&&!(r[sk].aparcada>t)).sort((a,b)=>a[sk].due-b[sk].due).map(r=>r.w);}
  function racha(){let n=0,d=new Date(now());for(;;){const k=d.toISOString().slice(0,10);if(db.dias[k]){n++;d.setDate(d.getDate()-1);}else break;}return n;}
  return {rec,oida,responde,cuento,presume,oido,minutos,vence,racha,save,get db(){return db;},STAGES,reset(){db={palabras:{},dias:{},cuentos:{},ajustes:{min:30,todo:0,bienvenida:0},minutos:0,v:1};save();}};
})();
