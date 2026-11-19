// Coquí phone test (order 00): the output meter for Web Audio. It sits on the same bus the clips play into
// and sees every sample the speaker is sent, on the audio thread, frame by frame.
// It reports each quiet run of 50 ms or more (no sample at or above the trim threshold, 0.012, on channel 0)
// as {q0: last loud frame before it, q1: first loud frame after it}, in the context's frame count
// (the same clock as AudioContext.currentTime * sampleRate). It also counts loud frames, for "did it sound".
class CoquiMeter extends AudioWorkletProcessor {
  constructor() {
    super();
    this.th = 0.012;
    this.minQuiet = Math.round(sampleRate * 0.05);
    this.lastLoud = -1;
    this.loud = 0;
    this.port.onmessage = (e) => {
      if (e.data === "reset") { this.lastLoud = -1; this.loud = 0; }
      if (e.data === "count") this.port.postMessage({ count: this.loud, frame: currentFrame });
    };
  }
  process(inputs) {
    const ch = inputs[0] && inputs[0][0];
    if (ch) {
      for (let i = 0; i < ch.length; i++) {
        const v = ch[i];
        if (v >= this.th || v <= -this.th) {
          const f = currentFrame + i;
          if (this.lastLoud >= 0 && f - this.lastLoud > this.minQuiet) this.port.postMessage({ q0: this.lastLoud, q1: f });
          if (this.lastLoud < 0) this.port.postMessage({ first: f });
          this.lastLoud = f;
          this.loud++;
        }
      }
    }
    return true;
  }
}
registerProcessor("coqui-meter", CoquiMeter);
