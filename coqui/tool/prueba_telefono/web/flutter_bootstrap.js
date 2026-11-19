{{flutter_js}}
{{flutter_build_config}}

// No service worker on purpose: a stale cached build on a phone would be worse than no cache.
_flutter.loader.load();
