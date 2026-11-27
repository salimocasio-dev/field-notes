/// All screen wording for `feature_library`.
///
/// Screens in `feature_library/lib/` and tests in `feature_library/test/` both
/// read from this file so changing a phrase is a single-line edit.
library;

/// Single source of truth for user-visible and semantic wording in
/// `feature_library`.
abstract final class LibraryWording {
  // Library home (`ReadingHome`).
  static const String libraryTitle = 'Library';
  static const String addYourOwnPill = '+ Add your own';
  static const String writeStorySection =
      'A new story at your level · about what?';
  static const String writeMyStory = 'Write my story';
  static const String noStoryMatchEmpty =
      'There’s no new story that fits your known words yet.';
  static const String noStoryMatchFocused =
      'There’s no new story that fits both your practice words and your current level.';
  static const String storySaveFailed =
      'The story couldn’t be saved. Try again.';
  static const String yourShelf = 'Your shelf';
  static const String yourShelfBeforeA2 = 'Your shelf · reading counts from A2';
  static const String filterAll = 'All';
  static const String filterStories = 'Stories';
  static const String filterBooks = 'Books';
  static const String emptyShelfAll =
      'Stories you make and books you add appear here.';
  static const String emptyShelfStories = 'No stories on your shelf yet.';
  static const String emptyShelfBooks = 'No books on your shelf yet.';
  static const String typeStory = 'Story';
  static const String typeBook = 'Book';
  static const String continueReading = 'Continue reading';
  static const String practiceWordsLabel = 'Practice words (optional)';
  static const String practiceWordsHelper =
      'Separate words or phrases with commas. Leave blank for review.';
  static const String cancel = 'Cancel';

  static String keepReadingPageProgress({
    required int page,
    required int totalPages,
    required int minutesLeft,
  }) => 'Page $page of $totalPages · $minutesLeft min left in the chapter';

  static String keepReadingPageSemantic({
    required int page,
    required int totalPages,
  }) => 'Page $page of $totalPages';

  // Import screen (`ImportScreen`), paste screen (`PasteTextScreen`),
  // importer (`BookImporter`), and coverage (`BookCoverage`).
  static const String importTitle = 'Add your own';
  static const String importClose = 'Close';
  static const String addingNowHeading = 'Adding now';
  static const String readyHeading = 'Ready';
  static const String stepOpeningDetail =
      'Opening the file. Then: reading the pages.';
  static const String stepReadingDetail =
      'Reading the pages. Then: checking its words against yours.';
  static const String stepCheckingDetail = 'Checking its words against yours.';
  static const String formatTxt = 'TXT';
  static const String formatPasted = 'Text';

  static const String coveragePhraseStretch =
      'A stretch for now. Reading gets easy near 98%.';
  static const String coveragePhraseClose =
      'Close. Reading gets easy near 98%.';
  static const String coveragePhraseEasy = 'Easy to read now.';

  static const String pasteTextTile = 'Paste text';
  static const String chooseFileButton = 'Choose a file';
  static const String pasteScreenTitle = 'Paste text';
  static const String pasteTitleLabel = 'Title (optional)';
  static const String pasteBodyHint = 'Paste or type text here';
  static const String pasteAddButton = 'Add';
  static const String untitledBook = 'Untitled text';

  static const String errorLockedBook =
      "Locked by the store it came from. Coquí can't open locked books.";
  static const String errorInvalidText =
      "Couldn't read this file as plain text.";
  static const String errorEmptyText = 'This file has no text to read.';
  static const String errorStorageFull =
      "Couldn't save this book on this device.";
  static const String errorPickerUnavailable =
      "Choosing a file isn't available here yet. Use Paste text meanwhile.";

  static String formatList(List<String> formats) {
    if (formats.isEmpty) return '';
    if (formats.length == 1) return formats.first;
    if (formats.length == 2) return '${formats[0]} or ${formats[1]}';
    final head = formats.sublist(0, formats.length - 1).join(', ');
    return '$head or ${formats.last}';
  }

  static String importIntro(List<String> formats) =>
      'Books and documents in ${formatList(formats)}. Only you can see what you add.';

  static String stepOfTotal(int step, {int total = 3}) =>
      'Step $step of $total.';

  static String stepSemanticLabel(int step, {int total = 3}) =>
      'Step $step of $total';

  static String stepReadingPagesDetail(int done, int total) =>
      'Reading the pages, $done of $total. Then: checking its words against yours.';

  static String bookMetaLine({
    required String format,
    required int pages,
    int? chapters,
  }) {
    final pagesText = pages == 1 ? '1 page' : '$pages pages';
    if (chapters != null && chapters > 1) {
      return '$format · $pagesText · $chapters chapters';
    }
    return '$format · $pagesText';
  }

  static String coverageHeadline(int percent) =>
      "You've heard $percent% of its words.";

  static String coverageSemanticLabel(int percent) =>
      'You know $percent percent of its words';

  static String errorUnsupportedFormat(List<String> formats) =>
      'Only ${formatList(formats)} files can be opened right now.';

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(bytes < 10 * 1024 ? 1 : 0)} KB';
    }
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
