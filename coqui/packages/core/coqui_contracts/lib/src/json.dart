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

/// A double as JavaScript's JSON.stringify writes it: a whole number has no ".0".
num jsonNumber(double v) =>
    v == v.truncateToDouble() && v.isFinite ? v.toInt() : v;

/// A JSON list of strings.
List<String> jsonStrings(Object? v) =>
    v == null ? <String>[] : [for (final x in v as List) x as String];

/// A JSON object, as a map with string keys.
Map<String, dynamic> jsonMap(Object? v) =>
    v == null ? <String, dynamic>{} : Map<String, dynamic>.from(v as Map);
