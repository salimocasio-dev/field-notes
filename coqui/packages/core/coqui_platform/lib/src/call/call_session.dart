import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/call/conv.dart';

/// Danny, the agent (llamada.js: AGENT). It is locked to the published site's origin.
const dannyAgentId = 'agent_3301m795q3xtfpx8c99zc0s870vm';

/// The ElevenLabs client, at the version the old page pins (llamada.js: SDK).
const elevenLabsClientUrl =
    'https://cdn.jsdelivr.net/npm/@elevenlabs/client@1.25.0/+esm';

/// Why [CallSession.start] could not start a call: the client's own error (a refused microphone is
/// "NotAllowedError"), "LibraryError" when the voice library did not load, "NotAvailable" where calls
/// are off. The text is `<name>: <message>`.
class CallStartException implements Exception {
  const CallStartException(this.name, this.message);
  final String name;
  final String message;

  @override
  String toString() => '$name: $message';
}

/// The call with Danny, ported from llamada.js's connection: the library loaded once ahead (precarga),
/// `startSession` with the agent, `connectionType: "websocket"`, the six dynamic variables and the
/// `show_picture` tool, and the session's callbacks as [CallEvent]s, in the order the client calls them:
/// onConnect [Connected], onMessage [AgentLine] or [Heard] (role or source "user"), onModeChange [Mode],
/// show_picture [Tool], onError [CallError], onDisconnect [Ended].
///
/// [available]: false without a library (phone builds) or where calls are off; on the web false once a
/// try to load the library has failed. Reading it starts the load (the old page loads it when Hablar
/// shows the open card, before any tap); a failed load is tried again on the next read.
class ConvCallSession implements CallSession {
  ConvCallSession({
    required this.library,
    required this.callsAllowed,
    this.beforeStart,
  });

  /// Null in a phone build.
  final ConvLibrary? library;
  final bool callsAllowed;

  /// Runs at start, before the library is asked for the call (llamada.js, inicia: `AC.suspend()`).
  final void Function()? beforeStart;

  final StreamController<CallEvent> _events =
      StreamController<CallEvent>.broadcast(sync: true);
  int _run = 0;
  int _cancelled = -1;
  Conv? _conv;

  @override
  Stream<CallEvent> get events => _events.stream;

  @override
  bool get available {
    final l = library;
    if (!callsAllowed || l == null) return false;
    if (l.loaded != true) unawaited(l.load()); // precarga
    return l.loaded != false;
  }

  void _emit(int my, CallEvent e) {
    if (my == _run) _events.add(e);
  }

  @override
  Future<void> start(CallBrief brief, Map<String, String> variables) async {
    final l = library;
    if (!callsAllowed || l == null) {
      throw const CallStartException(
        'NotAvailable',
        'Calls are off on this build.',
      );
    }
    final my = ++_run;
    _conv = null;
    try {
      beforeStart?.call();
    } catch (_) {}
    if (!await l.load()) {
      throw const CallStartException(
        'LibraryError',
        'The voice library did not load.',
      );
    }
    if (my != _run || _cancelled == my) return;
    // llamada.js, inicia: {place, job, words_open, words_heard, minutes, opening}; job, minutes and opening
    // are the place's call (CallBrief), the rest the caller's; anything else the caller gives goes too.
    final vars = <String, String>{
      'place': variables['place'] ?? '',
      'job': brief.job,
      'words_open': variables['words_open'] ?? '',
      'words_heard': variables['words_heard'] ?? '',
      'minutes': '${brief.minutes}',
      'opening': brief.opening,
    };
    for (final e in variables.entries) {
      vars.putIfAbsent(e.key, () => e.value);
    }
    Conv conv;
    try {
      conv = await l.startSession(
        ConvOptions(
          agentId: dannyAgentId,
          connectionType: 'websocket',
          dynamicVariables: vars,
          clientTools: {
            'show_picture': (p) {
              _emit(
                my,
                Tool('show_picture', p is Map ? _map(p) : {'picture': p}),
              );
              return 'shown';
            },
          },
          onConnect: (_) => _emit(my, const Connected()),
          onDisconnect: (d) => _emit(
            my,
            Ended(
              d is Map && d['reason'] is String ? d['reason'] as String : '',
            ),
          ),
          onError: (e) => _emit(my, CallError(_errorText(e))),
          onMessage: (m) {
            if (m is! Map) return;
            final text = m['message'] ?? m['text'];
            if (text is! String || text.isEmpty) return;
            final user = m['role'] == 'user' || m['source'] == 'user';
            _emit(my, user ? Heard(text) : AgentLine(text));
          },
          onModeChange: (m) {
            final mode = m is Map ? m['mode'] : null;
            if (mode is String) _emit(my, Mode(mode));
          },
        ),
      );
    } on ConvStartError catch (e) {
      throw CallStartException(e.name, e.message);
    } catch (e) {
      throw CallStartException('Error', '$e');
    }
    if (my != _run || _cancelled == my) {
      // he closed the screen while it was still calling: the late answer is ended at once
      try {
        conv.endSession();
      } catch (_) {}
      return;
    }
    _conv = conv;
  }

  // llamada.js: String((e && e.message) || e || "")
  static String _errorText(Object? e) {
    if (e is Map) {
      final m = e['message'];
      if (m is String && m.isNotEmpty) return m;
      return '$e';
    }
    return e == null ? '' : '$e';
  }

  static Map<String, dynamic> _map(Map p) => {
    for (final e in p.entries) '${e.key}': e.value,
  };

  @override
  void send(String text) {
    try {
      _conv?.sendUserMessage(text);
    } catch (_) {}
  }

  @override
  void setVolume(double v) {
    try {
      _conv?.setVolume(v);
    } catch (_) {}
  }

  // llamada.js: safe(() => C.conv.getInputVolume(), 0)
  @override
  double inputVolume() {
    try {
      return _conv?.getInputVolume() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  double outputVolume() {
    try {
      return _conv?.getOutputVolume() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Ends the session. Still calling: the answer, when it comes, is ended at once.
  @override
  Future<void> end() async {
    final c = _conv;
    _conv = null;
    if (c == null) {
      _cancelled = _run;
      return;
    }
    try {
      c.endSession();
    } catch (_) {}
  }
}
