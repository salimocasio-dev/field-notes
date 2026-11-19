// Helpers for reading and writing today's JSON. Not exported.

/// A JSON number as an int. JSON written by JavaScript has no int type: 3 and
/// 3.0 are the same number.
int jsonInt(Object? v, [int orElse = 0]) =>
    v == null ? orElse : (v as num).toInt();

/// A JSON number as an int, or null.
int? jsonIntOrNull(Object? v) => v == null ? null : (v as num).toInt();

/// A JSON number as a double.
double jsonDouble(Object? v, [double orElse = 0]) =>
    v == null ? orElse : (v as num).toDouble();

/// A JSON number as it is, int or double, unrounded.
num jsonNum(Object? v, [num orElse = 0]) => v == null ? orElse : v as num;

/// A number as JavaScript's JSON.stringify writes it: a whole number has no ".0" (on the VM too).
num jsonNumber(num v) =>
    v is double && v.isFinite && v == v.truncateToDouble() ? v.toInt() : v;

/// A JSON list of strings.
List<String> jsonStrings(Object? v) =>
    v == null ? <String>[] : [for (final x in v as List) x as String];

/// A JSON object, as a map with string keys.
Map<String, dynamic> jsonMap(Object? v) =>
    v == null ? <String, dynamic>{} : Map<String, dynamic>.from(v as Map);
