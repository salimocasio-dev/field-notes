import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/call/call_token.dart';
import 'package:coqui_platform/src/call/conv.dart';

/// The ElevenLabs client, self-hosted as a bundled web asset at the pinned
/// `@elevenlabs/client@1.25.0` version (llamada.js: SDK).
const elevenLabsClientUrl =
    'assets/packages/coqui_platform/assets/elevenlabs/lib.iife.js';

// llamada.js, inicia: the microphone line is shown when the error's name and message match this.
final _microphone = RegExp(
  r'NotAllowed|PermissionDenied|NotFound|Permission|microphone|denied',
  caseSensitive: false,
);

/// startSession's error as a [CallStartError]: microphone when llamada.js would say "The microphone is
/// off", else failed ("The call did not start"). The client's own name is kept.
CallStartError callStartError(String name, String message) => CallStartError(
  _microphone.hasMatch('$name $message')
      ? CallStartFailure.microphone
      : CallStartFailure.failed,
  message,
  name: name,
);

/// The live call, ported from llamada.js's connection: the library loaded once ahead (precarga),
/// `startSession` with either a server-minted [CallToken] (`signedUrl` or `conversationToken`,
/// no `agentId` or client `dynamicVariables`, when [tokenSource] is provided) or the legacy
/// `brief.agentId`, `connectionType: "websocket"`, and six dynamic variables (when [tokenSource]
/// is null), plus the `show_picture` tool, and the session's callbacks as [CallEvent]s, in the
/// order the client calls them: onConnect [Connected], onMessage [AgentLine] or [Heard] (role or
/// source "user"), onModeChange [Mode], show_picture [Tool], onError [CallError], onDisconnect [Ended].
///
/// [available]: false without a library (phone builds) or where calls are off; on the web false once a
/// try to load the library has failed. Reading it starts the load (the old page loads it when Hablar
/// shows the open card, before any tap); a failed load is tried again on the next read.
///
/// The shared sound is suspended at start ([beforeStart], as llamada.js) and given back when the call ends
/// ([afterCall], order 19b): at its [Ended], at a failed start, or at [end], once per start.
class ConvCallSession implements CallSession {
  ConvCallSession({
    required this.library,
    required this.callsAllowed,
    this.beforeStart,
    this.afterCall,
    this.tokenSource,
  });

  /// Null in a phone build.
  final ConvLibrary? library;
  final bool callsAllowed;

  /// Runs at start, before the library is asked for the call (llamada.js, inicia: `AC.suspend()`).
  final void Function()? beforeStart;

  /// Runs once when the call that [beforeStart] began is over (order 19b: the sound context resumed).
  final void Function()? afterCall;

  /// Optional call-token source (issue #249). When non-null, [start] fetches a short-lived
  /// [CallToken] and omits `agentId` and client `dynamicVariables` from `startSession`.
  final CallTokenSource? tokenSource;
  bool _suspended = false;

  void _resume() {
    if (!_suspended) return;
    _suspended = false;
    try {
      afterCall?.call();
    } catch (_) {}
  }

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
      throw const CallStartError(
        CallStartFailure.unavailable,
        'Calls are off on this build.',
      );
    }
    final my = ++_run;
    _conv = null;
    try {
      beforeStart?.call();
    } catch (_) {}
    _suspended = true;
    if (!await l.load()) {
      if (my == _run) _resume();
      throw const CallStartError(
        CallStartFailure.library,
        'The voice library did not load.',
      );
    }
    if (my != _run || _cancelled == my) return;

    final clientTools = <String, Object? Function(Object? parameters)>{
      'show_picture': (p) {
        _emit(my, Tool('show_picture', p is Map ? _map(p) : {'picture': p}));
        return 'shown';
      },
    };
    void onConnect(Object? _) => _emit(my, const Connected());
    void onDisconnect(Object? d) {
      if (my == _run) _resume();
      _emit(
        my,
        Ended(d is Map && d['reason'] is String ? d['reason'] as String : ''),
      );
    }

    void onError(Object? e) => _emit(my, CallError(_errorText(e)));
    void onMessage(Object? m) {
      if (m is! Map) return;
      final text = m['message'] ?? m['text'];
      if (text is! String || text.isEmpty) return;
      final user = m['role'] == 'user' || m['source'] == 'user';
      _emit(my, user ? Heard(text) : AgentLine(text));
    }

    void onModeChange(Object? m) {
      final mode = m is Map ? m['mode'] : null;
      if (mode is String) _emit(my, Mode(mode));
    }

    final ConvOptions options;
    final source = tokenSource;
    if (source != null) {
      CallToken token;
      try {
        token = await source.fetchToken(
          brief,
          wordsOpen: _wordList(variables['words_open']),
          wordsHeard: _wordList(variables['words_heard']),
        );
      } on CallStartError {
        if (my == _run) _resume();
        rethrow;
      } catch (e) {
        if (my == _run) _resume();
        throw CallStartError(CallStartFailure.failed, '$e');
      }
      if (my != _run || _cancelled == my) return;
      options = ConvOptions(
        signedUrl: token.signedUrl,
        conversationToken: token.conversationToken,
        connectionType: token.connectionType,
        clientTools: clientTools,
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onError: onError,
        onMessage: onMessage,
        onModeChange: onModeChange,
      );
    } else {
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
      options = ConvOptions(
        agentId: brief.agentId,
        connectionType: 'websocket',
        dynamicVariables: vars,
        clientTools: clientTools,
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onError: onError,
        onMessage: onMessage,
        onModeChange: onModeChange,
      );
    }

    Conv conv;
    try {
      conv = await l.startSession(options);
    } on ConvStartError catch (e) {
      if (my == _run) _resume();
      throw callStartError(e.name, e.message);
    } catch (e) {
      if (my == _run) _resume();
      throw CallStartError(CallStartFailure.failed, '$e');
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

  static List<String> _wordList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return [
      for (final part in raw.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
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
    _resume();
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
