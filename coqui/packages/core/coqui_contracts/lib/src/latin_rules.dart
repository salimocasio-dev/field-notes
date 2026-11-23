import 'package:coqui_contracts/src/normalize_table.dart';

/// Today's PAL.norm, moved here unchanged (the rules of every Latin-script language; Spanish is the one course).
///
/// palabras.js (and llamada.js, norm):
/// `" "+String(s==null?"":s).toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g,"").replace(/[^a-z0-9]+/g," ").trim()+" "`
///
/// Accents, case and punctuation are ignored; ñ is n; every run of anything that
/// is not a-z or 0-9 is one space; one space each side. Dart has no NFD, so what
/// the first three steps do to each character is read from [normalizeTable],
/// made from the old code by coqui/tool/contracts/make_fixtures.mjs.
String normalizeLatin(String? s) {
  final out = StringBuffer();
  for (final rune in (s ?? '').runes) {
    if ((rune >= 0x61 && rune <= 0x7a) || (rune >= 0x30 && rune <= 0x39)) {
      out.writeCharCode(rune);
    } else {
      out.write(_fold[rune] ?? ' ');
    }
  }
  return ' ${out.toString().replaceAll(_notWord, ' ').trim()} ';
}

final RegExp _notWord = RegExp('[^a-z0-9]+');

/// [normalizeTable], by code point.
final Map<int, String> _fold = {
  for (final e in normalizeTable.entries)
    for (final rune in e.value.runes) rune: e.key,
};
