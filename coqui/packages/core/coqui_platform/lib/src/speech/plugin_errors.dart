/// The speech plugin's error names (speech_to_text, Android and iOS) as the Web Speech names juego.js
/// knows, so a phone build's errors are counted as the web's are: a miss ("no-speech", "aborted") or
/// "speaking cannot work here" (the names in SpeechSettings.unavailableErrors).
String webSpeechError(String pluginError) {
  switch (pluginError) {
    case 'error_no_match':
    case 'error_speech_timeout':
      return 'no-speech';
    case 'error_network':
    case 'error_network_timeout':
    case 'error_server':
    case 'error_server_disconnected':
    case 'error_too_many_requests':
      return 'network';
    case 'error_audio_error':
      return 'audio-capture';
    case 'error_permission':
    case 'error_speech_recognizer_request_not_authorized':
      return 'not-allowed';
    case 'error_language_not_supported':
    case 'error_language_unavailable':
    case 'error_assets_not_installed':
      return 'language-not-supported';
    case 'error_speech_recognizer_disabled':
    case 'error_listen_failed':
      return 'service-not-allowed';
    case 'error_busy':
    case 'error_client':
    case 'error_request_cancelled':
    case 'error_retry':
    case 'error_speech_recognizer_already_active':
    case 'error_speech_recognizer_connection_interrupted':
    case 'error_speech_recognizer_connection_invalidated':
      return 'aborted';
  }
  return pluginError.isEmpty ? 'error' : pluginError;
}
