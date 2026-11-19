// A phone build: no page around the app.
import 'dart:convert';
import 'dart:io';

/// The live site's address of the app. A phone build has no page to take it from, so it reads the old site's files
/// from the live site, as the web app does from its own.
Uri appBaseUri() =>
    Uri.parse('https://salimocasio-dev.github.io/field-notes/app/');

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
