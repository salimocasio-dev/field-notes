// The web: the page the app runs in, by interop.
import 'dart:js_interop';

@JS('document.baseURI')
external String get _baseUri;

@JS('history.back')
external void _historyBack();

@JS('fetch')
external JSPromise<_Response> _fetch(JSString url, _Init init);

extension type _Init._(JSObject _) implements JSObject {
  external factory _Init({String cache});
}

extension type _Response._(JSObject _) implements JSObject {
  external bool get ok;
  external int get status;
  external JSPromise<JSString> text();
}

/// The app's base address: the page's `<base href>` (`/field-notes/app/` on the site), resolved by the browser.
Uri appBaseUri() => Uri.parse(_baseUri);

/// The browser's back (`history.back()`).
void historyBack() => _historyBack();

/// `fetch(url)` as text, with `cache: "no-store"` when [noStore] (as the old pages ask for audio/ready.json). Throws
/// when the answer is not 2xx or the network fails.
Future<String> httpText(Uri url, {required bool noStore}) async {
  final res = await _fetch(
    url.toString().toJS,
    _Init(cache: noStore ? 'no-store' : 'default'),
  ).toDart;
  if (!res.ok) throw StateError('${res.status} for $url');
  return (await res.text().toDart).toDart;
}
