// Made by tool/llamada_stub.mjs from historia/llamada.js (installStub, as it is). Do not edit by hand.
// The old page's fake ElevenLabs client: the Chrome tests run the interop against it.

const llamadaInstallStub = r'''
  function installStub(){if(window.ELConv)return;
    const S=window.CallStub={sent:[],sentAt:[],opts:null,ended:false,names:[],log:[]};
    const ph={inp:"quiet",say:0};
    window.ELConv={startSession(o){S.opts=o;S.o=o;return new Promise((res,rej)=>{
      if(STUBOPT.has("mic")){setTimeout(()=>{const e=new Error("Permission denied");e.name="NotAllowedError";rej(e);},400);return;}
      if(STUBOPT.has("fail")){setTimeout(()=>rej(new Error("The call did not start.")),600);return;}
      let t0=0;const mode=m=>{S.log.push(m);o.onModeChange&&o.onModeChange({mode:m});},
        msg=(who,t)=>{o.onMessage&&o.onMessage(who==="user"?{role:"user",source:"user",message:t}:{role:"agent",source:"ai",message:t});};
      let nb=0;const loop=()=>{if(S.ended)return;ph.say=1;mode("speaking");msg("agent",nb++%2?"Adiós.":"Hasta mañana.");setTimeout(()=>{ph.say=0;mode("listening");setTimeout(loop,1200);},1800);};   // the goodbye loop: a line every 3 s
      const c={sendUserMessage(t){S.sent.push(t);S.sentAt.push(t0?Math.round((performance.now()-t0)/1000*CLK):0);if(t==="(fin)"&&!STUBOPT.has("nofin")&&!STUBOPT.has("loop"))setTimeout(()=>{ph.say=1;mode("speaking");msg("agent","Eso. Hasta mañana.");setTimeout(()=>{ph.say=0;mode("listening");},2000);},400);},
        endSession(){if(S.ended)return Promise.resolve();S.ended=true;setTimeout(()=>o.onDisconnect&&o.onDisconnect({reason:"user"}),30);return Promise.resolve();},
        getInputVolume(){return ph.inp==="talk"?.10+.08*Math.abs(Math.sin(performance.now()/90))+Math.random()*.04:.004;},
        getOutputVolume(){return ph.say?.10+.10*Math.abs(Math.sin(performance.now()/130)):0;},setMicMuted(){}};
      const steps={connect(){t0=performance.now();o.onConnect&&o.onConnect({conversationId:"stub"});res(c);},
        danny1(){ph.say=1;mode("speaking");msg("agent","¡Hola! Soy Danny. ¿Cómo estás?");},
        you1(){ph.say=0;ph.inp="quiet";mode("listening");},talk1(){ph.inp="talk";},quiet1(){ph.inp="quiet";},heard1(){msg("user","Hola. Bien, gracias.");},
        danny2(){ph.inp="quiet";ph.say=1;mode("speaking");msg("agent","Eso. Mira. ¿Quieres jugo?");setTimeout(()=>{try{o.clientTools.show_picture({picture:"jugo"});}catch(e){}},500);},
        you2(){ph.say=0;ph.inp="quiet";mode("listening");},talk2(){ph.inp="talk";},quiet2(){ph.inp="quiet";},heard2(){msg("user","Sí, quiero jugo.");},
        you3(){ph.say=0;ph.inp="quiet";mode("listening");},talk3(){ph.inp="talk";},quiet3(){ph.inp="quiet";},heard3(){msg("user",STUBOPT.has("hasta")?"Hasta mañana.":"Adiós.");if(STUBOPT.has("loop"))setTimeout(loop,300);},
        danny3(){ph.inp="quiet";ph.say=1;mode("speaking");msg("agent","Sí. Hasta mañana.");setTimeout(()=>{ph.say=0;mode("listening");if(STUBOPT.has("loop"))setTimeout(loop,1200);},1800);},
        end(){S.ended=true;o.onDisconnect&&o.onDisconnect({reason:"agent"});}};
      S.names=Object.keys(steps);S.go=n=>{if(S.ended&&n!=="connect")return;steps[n]();};
      if(STUBOPT.has("manual"))return;   // the test steps it: CallStub.go("connect"), ...
      const seq=[["connect",1200],["danny1",2800],["you1",700],["talk1",1500],["quiet1",900],["heard1",1100],["danny2",3000],["you2",700],["talk2",1500],["quiet2",900],["heard2",0]];
      let i=0;const next=()=>{if(S.ended)return;if(i<seq.length){const [n,d]=seq[i++];steps[n]();setTimeout(next,d);return;}
        // then, a moment later, the learner says goodbye (or, with dannybye, Danny does)
        setTimeout(()=>{if(STUBOPT.has("dannybye")){steps.danny3();return;}steps.you3();setTimeout(()=>{steps.talk3();setTimeout(()=>{steps.quiet3();setTimeout(()=>steps.heard3(),900);},1200);},500);},1500);};
      next();});}};}
''';
