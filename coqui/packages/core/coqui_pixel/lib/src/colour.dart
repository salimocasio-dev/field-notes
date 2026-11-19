/// `"#RRGGBB"` as the int `0xFFBBGGRR` (page 12, section 6: a colour is converted once, to the picture's own order).
///
/// For a colour that is made once, such as a sprite's, and for the palette tables. A colour drawn every frame is a
/// constant written out where it is used.
int hexColour(String h) {
  final r = int.parse(h.substring(1, 3), radix: 16),
      g = int.parse(h.substring(3, 5), radix: 16),
      b = int.parse(h.substring(5, 7), radix: 16);
  return 0xFF000000 | (b << 16) | (g << 8) | r;
}

/// [hexColour] of each of [hs].
List<int> hexColours(List<String> hs) => [for (final h in hs) hexColour(h)];
