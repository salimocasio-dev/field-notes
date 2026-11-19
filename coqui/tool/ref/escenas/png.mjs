// A small PNG writer for the frames: RGBA pixels in, a PNG out. Indexed (a palette of at most 256 colours, with transparency) when the
// picture has that few colours, else RGBA. zlib level 9. The same pixels always give the same bytes.
import zlib from "node:zlib";

const CRC = (() => { const t = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
const crc = b => { let c = 0xffffffff; for (const x of b) c = CRC[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
function chunk(type, data) {
  const t = Buffer.from(type, "ascii"), len = Buffer.alloc(4), cr = Buffer.alloc(4);
  len.writeUInt32BE(data.length); cr.writeUInt32BE(crc(Buffer.concat([t, data])));
  return Buffer.concat([len, t, data, cr]);
}

export function png(w, h, rgba) {
  const pal = new Map(), idx = new Uint8Array(w * h);
  let indexed = true;
  for (let i = 0; i < w * h; i++) {
    const k = rgba.readUInt32BE(i * 4);
    let j = pal.get(k);
    if (j === undefined) { if (pal.size >= 256) { indexed = false; break; } j = pal.size; pal.set(k, j); }
    idx[i] = j;
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = indexed ? 3 : 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  const parts = [Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk("IHDR", ihdr)];
  let raw;
  if (indexed) {
    const keys = [...pal.keys()], P = Buffer.alloc(keys.length * 3), T = Buffer.alloc(keys.length);
    keys.forEach((k, i) => { P[i * 3] = k >>> 24; P[i * 3 + 1] = (k >>> 16) & 255; P[i * 3 + 2] = (k >>> 8) & 255; T[i] = k & 255; });
    parts.push(chunk("PLTE", P));
    if (keys.some(k => (k & 255) !== 255)) parts.push(chunk("tRNS", T));
    raw = Buffer.alloc((w + 1) * h);
    for (let y = 0; y < h; y++) { raw[y * (w + 1)] = 0; for (let x = 0; x < w; x++) raw[y * (w + 1) + 1 + x] = idx[y * w + x]; }
  } else {
    raw = Buffer.alloc((w * 4 + 1) * h);
    for (let y = 0; y < h; y++) { raw[y * (w * 4 + 1)] = 0; rgba.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4); }
  }
  parts.push(chunk("IDAT", zlib.deflateSync(raw, { level: 9 })), chunk("IEND", Buffer.alloc(0)));
  return Buffer.concat(parts);
}
