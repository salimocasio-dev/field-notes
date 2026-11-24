// NOT CHECKED BY AN ARABIC SPEAKER. Test-only Arabic fixture for RTL, script-font, and multi-language tests.

import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/src/sample_files.dart';

// NOT CHECKED BY AN ARABIC SPEAKER. Test-only Arabic fixture for RTL, script-font, and multi-language tests.
/// Test-only Arabic [Language] fixture (`ar`, [LanguageDirection.rtl],
/// `script: 'Arab'`, partner `Tariq`, test agent `agent_arabic_test`).
final Language arabicTestLanguage = Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-SA',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  partnerName: 'Tariq',
  callAgentId: 'agent_arabic_test',
  micWords: const {
    'ready': 'اضغط وتكلم',
    'listening': 'أسمعك',
    'thinking': 'لحظة',
    'theySpeak': 'استمع',
    'right': 'ممتاز',
    'notYet': 'مرة أخرى',
  },
  tabNames: const {
    'library': 'المكتبة',
    'words': 'الكلمات',
    'map': 'الخريطة',
    'speak': 'تكلم',
    'me': 'أنا',
  },
);

// NOT CHECKED BY AN ARABIC SPEAKER. Test-only Arabic fixture for RTL, script-font, and multi-language tests.
const Map<String, String> _arabicWords = {
  'casa': 'بيت',
  'puerta': 'باب',
  'ventana': 'نافذة',
  'abuela': 'جدة',
  'abre': 'افتح',
  'cierra': 'أغلق',
  'hola': 'مرحباً',
  'adiós': 'وداعاً',
  'sí': 'نعم',
  'no': 'لا',
  'grande': 'كبير',
  'pequeña': 'صغير',
  'toca': 'المس',
};

// NOT CHECKED BY AN ARABIC SPEAKER. Test-only Arabic fixture for RTL, script-font, and multi-language tests.
const Map<String, String> _arabicStoryTitles = {
  'la-lluvia': 'المطر',
  'el-bizcocho': 'الكعكة',
  'donde-esta-el-pajaro': 'أين الطائر؟',
};

// NOT CHECKED BY AN ARABIC SPEAKER. Test-only Arabic fixture for RTL, script-font, and multi-language tests.
const Map<String, String> _arabicClipTexts = {
  // All 20 clips in sample/audio/marcas.json:
  'esta_casa': 'هذا بيت جدة.',
  'mira_casa': 'انظر إلى بيت جدة.',
  'puedes_casa': 'هل يمكنك لمس بيت جدة؟',
  'muy_bien': 'ممتاز!',
  'esta_puerta': 'هذا باب بيت جدة.',
  'cerrada': 'هو مغلق.',
  'donde_puerta': 'أين باب البيت؟',
  'mira_ventana': 'انظر إلى نافذة البيت.',
  'ventana_cerrada': 'هذه نافذة مغلقة.',
  'puedes_abrir': 'هل يمكنك أن تفتح نافذة؟',
  'si_muy_bien': 'نعم! ممتاز!',
  'tiene_bizcocho': 'انظر. جدة لديها كعكة.',
  'quieres_hola': 'تقول جدة: مرحباً! هل تريد كعكة؟',
  'cq_si': 'نعم!',
  'grande_casa': 'بيت جدة كبير.',
  'puedes_casa_grande': 'هل يمكنك لمس بيت كبير؟',
  'casa_del_pajaro': 'انظر. هذا بيت الطائر.',
  'es_pequena': 'هو صغير.',
  'donde_pequena': 'أين بيت صغير؟',
  'mira_palmas': 'انظر إلى النخيل.',
  // Additional clips used in cual-frente.json, libros/la-lluvia.json, and fijos.json:
  'ab_cierra_puerta': 'جدة أغلق باب البيت.',
  'abre_ventana': 'جدة افتح نافذة البيت.',
  'abuela': 'هذه جدة.',
  'adios_abuela': 'وداعاً يا جدة!',
  'cq_no': 'لا!',
  'hola_abuela': 'مرحباً يا جدة!',
  'n_casa_grande': 'هذا بيت كبير.',
  'n_casa_pequena': 'هذا بيت صغير.',
  'puerta': 'هذا باب.',
  'ventana': 'هذه نافذة.',
  'tambien_cerrada': 'هي أيضاً مغلقة.',
  'viene_lluvia': 'انظر! جاء المطر.',
  'ay_lluvia': 'آه، المطر!',
  'abuela_en_ventana': 'جدة عند نافذة البيت.',
  'hola_quien': 'تقول جدة: مرحباً! من هناك؟',
  'soy_yo': 'أنا هنا يا جدة! افتح!',
  'ahora_en_puerta': 'الآن جدة عند باب البيت.',
  'abre_puerta_tu': 'افتح باب البيت يا جدة!',
  'abre_puerta': 'جدة افتح باب البيت.',
  'es_abuela': 'انظر! هذه جدة.',
  'abuela_dice': 'تقول جدة: مرحباً! كيف حالك؟',
  'ahora_tu': 'دورك الآن.',
};

void _overlayClips(Map<String, dynamic> doc) {
  final clips = doc['clips'];
  if (clips is Map<String, dynamic>) {
    for (final entry in clips.entries) {
      final replacement = _arabicClipTexts[entry.key];
      if (replacement != null && entry.value is Map<String, dynamic>) {
        (entry.value as Map<String, dynamic>)['text'] = replacement;
      }
    }
  }
}

/// Reads a file from [sampleFiles] with an in-memory Arabic text overlay
/// (unchecked by an Arabic speaker), keeping all structural IDs and marks
/// identical to the Spanish sample course.
Future<String> arabicSampleFile(String path) async {
  final base = sampleFiles[path];
  if (base == null) {
    throw StateError('no file "$path" in the sample course');
  }

  switch (path) {
    case 'datos/curso.json':
      final doc = jsonDecode(base) as Map<String, dynamic>;
      final lugares = doc['lugares'];
      if (lugares is List) {
        for (final lugar in lugares) {
          if (lugar is Map<String, dynamic>) {
            lugar['nombre'] = 'البيت';
            lugar['escenas'] = ['الأمام', 'الشرفة', 'الغرفة', 'الفناء'];
          }
        }
      }
      final cuentos = doc['cuentos'];
      if (cuentos is Map<String, dynamic>) {
        for (final entry in cuentos.entries) {
          final title = _arabicStoryTitles[entry.key];
          if (title != null && entry.value is Map<String, dynamic>) {
            (entry.value as Map<String, dynamic>)['t'] = title;
          }
        }
      }
      return jsonEncode(doc);

    case 'datos/fijos.json':
      final doc = jsonDecode(base) as Map<String, dynamic>;
      doc['despedidas'] = ['وداعاً', 'إلى الغد'];
      final lineas = doc['lineas'];
      if (lineas is Map<String, dynamic>) {
        final ahoraTu = lineas['ahora_tu'];
        if (ahoraTu is Map<String, dynamic>) {
          ahoraTu['text'] = 'دورك الآن.';
        }
      }
      return jsonEncode(doc);

    case 'datos/llamadas.json':
      final doc = jsonDecode(base) as Map<String, dynamic>;
      final casa = doc['casa'];
      if (casa is Map<String, dynamic>) {
        casa['opening'] = 'مرحباً! أنا طارق. كيف حالك؟';
        casa['foto'] = 'بيت';
      }
      return jsonEncode(doc);

    case 'datos/nivel.json':
      final list = jsonDecode(base) as List<dynamic>;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final w = item['w'];
          if (w is String) {
            item['w'] = _arabicWords[w] ?? w;
          }
          final pics = item['p'];
          if (pics is List) {
            for (final p in pics) {
              if (p is List && p.isNotEmpty && p[0] is String) {
                final pw = p[0] as String;
                p[0] = _arabicWords[pw] ?? pw;
              }
            }
          }
        }
      }
      return jsonEncode(list);

    case 'libros/la-lluvia.json':
      final doc = jsonDecode(base) as Map<String, dynamic>;
      doc['title'] = _arabicStoryTitles['la-lluvia'];
      return jsonEncode(doc);

    case 'cuentos/cual-frente.json':
      final doc = jsonDecode(base) as Map<String, dynamic>;
      doc['title'] = 'أيهما؟';
      doc['place'] = 'البيت';
      _overlayClips(doc);
      final items = doc['items'];
      if (items is List) {
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final w = item['w'];
            if (w is String) {
              item['w'] = _arabicWords[w] ?? w;
            }
          }
        }
      }
      return jsonEncode(doc);

    case 'cuentos/la-lluvia.json':
    case 'cuentos/el-bizcocho.json':
    case 'cuentos/donde-esta-el-pajaro.json':
      final doc = jsonDecode(base) as Map<String, dynamic>;
      final id = doc['id'];
      if (id is String && _arabicStoryTitles.containsKey(id)) {
        doc['title'] = _arabicStoryTitles[id];
      }
      doc['place'] = 'البيت';
      for (final field in const ['focus_words', 'back_again']) {
        final words = doc[field];
        if (words is List) {
          doc[field] = [
            for (final w in words) w is String ? (_arabicWords[w] ?? w) : w,
          ];
        }
      }
      final palabras = doc['palabras'];
      if (palabras is Map<String, dynamic>) {
        for (final key in palabras.keys.toList()) {
          final v = palabras[key];
          if (v is String) {
            palabras[key] = _arabicWords[v] ?? v;
          }
        }
      }
      _overlayClips(doc);
      return jsonEncode(doc);

    default:
      return base;
  }
}
