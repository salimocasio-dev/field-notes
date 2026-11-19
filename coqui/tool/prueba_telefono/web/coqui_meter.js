// Coquí phone test (order 00). Loaded in <head>, before Flutter starts. Plain script, no module.
//
// 1. Page-start marks for test 6 (the engine's own "flutter-first-frame" event, in ms since navigation start).
// 2. The speech shim: speech_to_text's web code never sets maxAlternatives (it stays at the browser's 1), and
//    docs/hablar/01-decisiones.md asks for 5. The shim makes every recogniser the plugin creates ask for 5.
//    Nothing else is changed; the plugin's own lang, continuous and interimResults are kept.
// 3. The media watch for test 1: just_audio plays through one <audio> element that it keeps private. The
//    wrapper on HTMLMediaElement.prototype.play only notes which element was played (then calls the real play);
//    the watch then samples that element's clock (currentTime) every few ms, on a timer and on its own events.
// 4. Errors that reach the window are kept, so the copied results show them.
(function () {
  "use strict";
  var W = window;
  W.__coquiFirstFrame = null;
  W.addEventListener("flutter-first-frame", function () {
    if (W.__coquiFirstFrame == null) W.__coquiFirstFrame = performance.now();
  });

  W.__coquiErrors = [];
  W.addEventListener("error", function (e) {
    try { W.__coquiErrors.push("error: " + (e && (e.message || (e.error && e.error.message)) || "unknown")); } catch (x) {}
  });
  W.addEventListener("unhandledrejection", function (e) {
    try { var r = e && e.reason; W.__coquiErrors.push("unhandled rejection: " + (r && (r.name ? r.name + ": " : "") + (r && r.message ? r.message : String(r)))); } catch (x) {}
  });

  // A safety net for the audio unlock: on every tap, if the page's AudioContext (made by Dart in the first
  // tap) is not running, resume it here, inside the browser's own event, and count it. If the count stays 0,
  // Flutter's tap alone kept the audio unlocked.
  W.__coquiNet = 0;
  ["touchend", "pointerup", "click", "keydown"].forEach(function (n) {
    document.addEventListener(n, function () {
      var ac = W.__coquiAC;
      if (ac && ac.state !== "running" && ac.state !== "closed") {
        W.__coquiNet++;
        try { ac.resume(); } catch (x) {}
      }
    }, true);
  });

  // 2. speech shim
  W.__coquiShim = { wrapped: false, made: 0, last: null };
  try {
    var SR = W.webkitSpeechRecognition;
    if (typeof SR === "function") {
      var Wrapped = function () {
        var r = new SR();
        try { r.maxAlternatives = 5; } catch (x) {}
        W.__coquiShim.made++;
        W.__coquiShim.last = r;
        return r;
      };
      Wrapped.prototype = SR.prototype;
      W.webkitSpeechRecognition = Wrapped;
      W.__coquiShim.wrapped = true;
    }
  } catch (x) {}

  // 3. media watch
  var M = { els: [], on: false, samples: [], timer: 0 };
  W.__coquiMedia = M;
  function sample(el, why) {
    if (!M.on) return;
    M.samples.push({ w: performance.now(), i: M.els.indexOf(el), src: el.currentSrc || el.src || "", ct: el.currentTime, p: el.paused, rs: el.readyState, e: why });
  }
  var EV = ["playing", "play", "pause", "seeking", "seeked", "timeupdate", "ended", "loadstart", "loadeddata", "canplay", "waiting", "emptied"];
  function track(el) {
    if (M.els.indexOf(el) >= 0) return;
    M.els.push(el);
    EV.forEach(function (n) { el.addEventListener(n, function () { sample(el, n); }); });
  }
  try {
    var realPlay = HTMLMediaElement.prototype.play;
    HTMLMediaElement.prototype.play = function () {
      try { track(this); sample(this, "play()"); } catch (x) {}
      return realPlay.apply(this, arguments);
    };
  } catch (x) {}
  M.start = function () {
    M.samples = [];
    M.on = true;
    clearInterval(M.timer);
    M.timer = setInterval(function () { for (var k = 0; k < M.els.length; k++) sample(M.els[k], ""); }, 2);
  };
  M.stop = function () {
    M.on = false;
    clearInterval(M.timer);
    return JSON.stringify(M.samples);
  };
  M.count = function () { return M.els.length; };
})();
