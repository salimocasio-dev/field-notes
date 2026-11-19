// The few JavaScript behaviours historia/palabras.js leans on, spelled out in Dart
// (page 12, section 6): truthiness, Number(x), Object.assign, JSON.stringify and the way
// JavaScript writes a number. Nothing here knows about words or schedules.
import 'dart:convert';

/// `if (x)`, `x || y`, `!x`: false for null (undefined), false, 0, NaN and "".
bool jsTruthy(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0 && !v.isNaN;
  if (v is String) return v.isNotEmpty;
  return true;
}

/// `Number(x)` for a value read out of the stored JSON (null is 0; a string is parsed).
/// A key that is missing altogether is `undefined`, which is NaN: see [jsNumberAt].
double jsToNumber(Object? v) {
  if (v is num) return v.toDouble();
  if (v == null) return 0;
  if (v is bool) return v ? 1 : 0;
  if (v is String) {
    final s = v.trim();
    return s.isEmpty ? 0 : (double.tryParse(s) ?? double.nan);
  }
  return double.nan;
}

/// `Number(m[key])`: a key that is not there is `undefined` (NaN), a stored null is 0.
double jsNumberAt(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v == null && !m.containsKey(key)) return double.nan;
  return jsToNumber(v);
}

/// A number as it is kept in the store: a whole value is an integer (as JSON.stringify writes
/// it, and as `jsonDecode` reads it back), anything else stays a double.
num jsNumberOut(double v) {
  if (v.isFinite && v == v.truncateToDouble() && v.abs() <= _maxSafe) {
    return v.toInt();
  }
  return v;
}

/// 2^53: up to here a whole double is exactly an integer.
const double _maxSafe = 9007199254740992;

/// `Object.assign(target, source)` for what `JSON.parse` can give: an object copies its keys,
/// an array its indexes, a string its characters; null and the other primitives copy nothing.
void jsAssign(Map<String, dynamic> target, Object? source) {
  if (source is Map) {
    for (final e in source.entries) {
      target['${e.key}'] = e.value;
    }
  } else if (source is List) {
    for (var i = 0; i < source.length; i++) {
      target['$i'] = source[i];
    }
  } else if (source is String) {
    for (var i = 0; i < source.length; i++) {
      target['$i'] = source[i];
    }
  }
}

/// The keys of [m] in the order JavaScript lists an object's own properties (`Object.keys`,
/// `Object.values`, `JSON.stringify`): the array indexes first, in ascending order (the canonical
/// whole numbers from "0" to "4294967294": "10" comes after "9" and before "casa"), then every
/// other key in the order it was added.
List<String> jsKeys(Map<dynamic, dynamic> m) {
  final indexes = <String>[];
  final others = <String>[];
  for (final k in m.keys) {
    final key = '$k';
    (_isArrayIndex(key) ? indexes : others).add(key);
  }
  if (indexes.isEmpty) return others;
  indexes.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  return [...indexes, ...others];
}

bool _isArrayIndex(String k) {
  if (k.isEmpty || k.length > 10) return false;
  if (k.length > 1 && k.codeUnitAt(0) == 0x30) return false; // no leading zero
  for (var i = 0; i < k.length; i++) {
    final c = k.codeUnitAt(i);
    if (c < 0x30 || c > 0x39) return false;
  }
  return int.parse(k) <= 4294967294;
}

/// `JSON.stringify(v)`: compact, keys in the order JavaScript lists them ([jsKeys]), numbers as
/// JavaScript writes them (a whole value without ".0"), NaN and Infinity as null.
String jsonStringify(Object? v) {
  final out = StringBuffer();
  _write(out, v);
  return out.toString();
}

void _write(StringBuffer out, Object? v) {
  if (v == null) {
    out.write('null');
  } else if (v is bool) {
    out.write(v ? 'true' : 'false');
  } else if (v is num) {
    // Not `v is int` / `v is double`: in a browser 5.0, -0.0 and Infinity are all ints.
    final d = v.toDouble();
    if (!d.isFinite) {
      out.write('null');
    } else if (d == d.truncateToDouble() && d.abs() <= _maxSafe) {
      out.write(d.toInt());
    } else {
      out.write(jsNumberToString(d));
    }
  } else if (v is String) {
    out.write(jsonEncode(v));
  } else if (v is Map) {
    out.write('{');
    var first = true;
    for (final k in jsKeys(v)) {
      if (!first) out.write(',');
      first = false;
      out.write(jsonEncode(k));
      out.write(':');
      _write(out, v[k]);
    }
    out.write('}');
  } else if (v is Iterable) {
    out.write('[');
    var first = true;
    for (final x in v) {
      if (!first) out.write(',');
      first = false;
      _write(out, x);
    }
    out.write(']');
  } else {
    // An object with a toJson(), as JSON.stringify honours toJSON().
    _write(out, jsonDecode(jsonEncode(v)));
  }
}

/// ECMAScript Number::toString(10) for a finite double: the shortest digits that read back
/// as the same number, 5 for 5.0, 1e+21 from 1e21, 1e-7 from 0.0000001.
String jsNumberToString(double v) {
  if (v == 0) return '0';
  final sign = v < 0 ? '-' : '';
  // "d.ddde+x": the shortest digits and the exponent (the same on the VM and in a browser).
  final e = v.abs().toStringAsExponential();
  final at = e.indexOf('e');
  final digits = e.substring(0, at).replaceAll('.', '');
  final exp = int.parse(e.substring(at + 1));
  final k = digits.length;
  final n = exp + 1; // the decimal point sits after n digits
  final String body;
  if (k <= n && n <= 21) {
    body = digits + '0' * (n - k);
  } else if (0 < n && n <= 21) {
    body = '${digits.substring(0, n)}.${digits.substring(n)}';
  } else if (-6 < n && n <= 0) {
    body = '0.${'0' * -n}$digits';
  } else {
    final x = n - 1;
    final xs = '${x < 0 ? '-' : '+'}${x.abs()}';
    body = k == 1
        ? '${digits}e$xs'
        : '${digits.substring(0, 1)}.${digits.substring(1)}e$xs';
  }
  return '$sign$body';
}
