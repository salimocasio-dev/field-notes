/// The time zone this test process runs in, as the recordings name it (a folder of
/// coqui/ref/progress/), or null when it is neither of the two they were made in.
///
/// The test process takes its zone from the TZ environment variable (on the VM) or from the
/// browser (which takes it from the TZ of the process that started it).
String? detectedZone() {
  final january = DateTime(2026, 1, 15).timeZoneOffset;
  final july = DateTime(2026, 7, 15).timeZoneOffset;
  if (january == Duration.zero && july == Duration.zero) return 'UTC';
  if (january == const Duration(hours: -5) &&
      july == const Duration(hours: -4)) {
    return 'America_New_York';
  }
  return null;
}

/// What the offsets are, for a message.
String zoneOffsets() {
  final january = DateTime(2026, 1, 15).timeZoneOffset;
  final july = DateTime(2026, 7, 15).timeZoneOffset;
  return 'January ${_hours(january)}, July ${_hours(july)}';
}

String _hours(Duration d) {
  final sign = d.isNegative ? '-' : '+';
  final m = d.abs().inMinutes;
  return '$sign${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
}
