// A phone build: no page around the app.
import 'dart:convert';
import 'dart:io';

/// The default live site's address of the app for phone builds when
/// `COQUI_APP_BASE` is not provided at build time.
const String defaultAppBaseUrl =
    'https://salimocasio-dev.github.io/field-notes/app/';

const String _configuredAppBaseUrl = String.fromEnvironment(
  'COQUI_APP_BASE',
  defaultValue: defaultAppBaseUrl,
);

/// Parses and validates a build-time `COQUI_APP_BASE` value, falling back to
/// [defaultAppBaseUrl] when empty and ensuring a trailing `/` so relative
/// content resolution (`../historia/`) works cleanly.
Uri parseAppBaseUri(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return Uri.parse(defaultAppBaseUrl);
  final uri = Uri.parse(trimmed);
  if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
    throw FormatException('COQUI_APP_BASE must be an http(s) URL', trimmed);
  }
  if (uri.path.endsWith('/')) return uri;
  return uri.replace(path: '${uri.path}/');
}

/// The live site's address of the app. A phone build has no page to take it from, so it reads the old site's files
/// from `COQUI_APP_BASE` (defaulting to [defaultAppBaseUrl]), as the web app does from its own.
Uri appBaseUri() => parseAppBaseUri(_configuredAppBaseUrl);

/// No browser history in a phone build.
void historyBack() {}

/// Fetches [url] as text over HTTP. [noStore]: the answer is never a cached copy.
Future<String> httpText(Uri url, {required bool noStore}) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(url);
    if (noStore) req.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode < 200 || res.statusCode > 299) {
      throw HttpException('${res.statusCode} for $url', uri: url);
    }
    return body;
  } finally {
    client.close();
  }
}
