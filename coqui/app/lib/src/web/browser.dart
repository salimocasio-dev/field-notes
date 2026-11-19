/// What the shell needs of the page it runs in: its base address, a fetch, and the browser's history. On the web it
/// is the browser's own (`browser_web.dart`, by interop); in a phone build there is no page (`browser_io.dart`).
library;

export 'package:app/src/web/browser_io.dart'
    if (dart.library.js_interop) 'package:app/src/web/browser_web.dart'
    show appBaseUri, historyBack, httpText;
