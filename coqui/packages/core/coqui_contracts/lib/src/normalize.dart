import 'package:coqui_contracts/src/language.dart';

/// Today's PAL.norm, copied exactly.
///
/// palabras.js (and llamada.js, norm):
/// `" "+String(s==null?"":s).toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g,"").replace(/[^a-z0-9]+/g," ").trim()+" "`
///
/// Accents, case and punctuation are ignored; ñ is n; every run of anything that
/// is not a-z or 0-9 is one space; one space each side. Dart has no NFD, so what
/// the first three steps do to each character is read from [normalizeTable],
/// made from the old code by coqui/tool/contracts/make_fixtures.mjs.
///
/// Deprecated: the word rules now live on [Language.normalize] (use
/// `course.language.normalize` or `Language.spanish.normalize`). This global
/// stays, returning the same strings, until N2.11 removes it. (Not annotated
/// with `@Deprecated` yet because 8 packages outside `coqui_contracts` still
/// call it and `flutter analyze` fails on `deprecated_member_use` infos.)
String normalize(String? s) => Language.spanish.normalize(s);
