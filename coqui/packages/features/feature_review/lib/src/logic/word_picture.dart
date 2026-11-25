/// Dedicated single-word picture assets for Repaso (`¿Cuál?`) under issue #10.
///
/// Salim's `#10` rule:
/// - No story-book screenshots (`img/...` / `libros/...`) and no camera crops of story scenes (`ScenePictures`) may
///   be used as word flashcards.
/// - Only dedicated individual single-word assets under `word_assets/` (drawn or pulled individually for a single
///   word) may be shown in `¿Cuál?`.
/// - Abstract/unpicturable words have `picturable: false` (or no asset) and are never tested with pictures.
/// - No Spanish vocabulary strings or clip IDs are hardcoded in `lib/`.
library;

/// Whether [path] is a valid dedicated single-word asset path under `word_assets/`.
///
/// Rejects empty paths, leading `/`, story-book paths (`img/...`, `libros/...`), path traversal (`..`), and
/// backslashes (`\`), and requires a non-empty file name after `word_assets/`.
bool isDedicatedWordAssetPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('/')) return false;
  if (trimmed.startsWith('img/')) return false;
  if (trimmed.startsWith('libros/')) return false;
  if (trimmed.contains('..')) return false;
  if (trimmed.contains(r'\')) return false;
  if (trimmed.endsWith('/') || trimmed.contains('//')) return false;
  const prefix = 'word_assets/';
  if (!trimmed.startsWith(prefix)) return false;
  return trimmed.length > prefix.length;
}

/// Dedicated single-word picture pair for one concrete vocabulary word (`#10`).
///
/// Unpicturable words must set [picturable] to `false` (or be omitted) and are never shown with pictures.
class WordPictureAsset {
  const WordPictureAsset({
    required this.word,
    required this.yesAsset,
    required this.noAsset,
    this.picturable = true,
  });

  /// The vocabulary word this asset pair depicts.
  final String word;

  /// Dedicated `word_assets/...` path for the matching picture.
  final String yesAsset;

  /// Dedicated `word_assets/...` path for the contrasting wrong picture.
  final String noAsset;

  /// Whether the word is concrete/picturable (`false` for abstract/unpicturable words).
  final bool picturable;

  /// Whether this asset pair may be used in `¿Cuál?` under `#10`.
  bool get isUsable =>
      picturable &&
      isDedicatedWordAssetPath(yesAsset) &&
      isDedicatedWordAssetPath(noAsset) &&
      yesAsset.trim() != noAsset.trim();
}
