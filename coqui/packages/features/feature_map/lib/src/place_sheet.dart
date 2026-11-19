import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_model.dart';
import 'package:material_ui/material_ui.dart';

/// The body of the place sheet (app.html: `lugar`; the title is in the sheet's header bar): a line naming the
/// place, then a row for each of its stories with its green play disc, or, for a place with no stories, what
/// is wrong with it. The strings are app.html's, word for word; the place's English name and its scenes come
/// from the catalog.
class PlaceSheetBody extends StatelessWidget {
  const PlaceSheetBody({
    super.key,
    required this.place,
    required this.progress,
    required this.course,
    required this.onPlay,
  });

  final Place place;
  final ProgressStore progress;
  final CourseCatalog course;

  /// A story's play disc: where the learner goes (`nav.go(StoryRoute(id))`).
  final void Function(String storyId) onPlay;

  @override
  Widget build(BuildContext context) {
    final l = place;
    final open = placeOpen(progress, l);
    // the green disc is only on the first story not yet played; every other row has the outline disc
    String? prox;
    for (final c in l.stories) {
      if (!progress.played(c)) {
        prox = c;
        break;
      }
    }
    return CollapsingColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `.plhead{display:none}` on a phone on its side
        if (!CoquiLayout.compact(context))
          Block(
            bottom: 8,
            child: Text(
              'Place ${l.n} · ${l.en}${l.fork != null ? " · a fork: either place first" : ""}',
              style: CoquiText.smallMuted,
            ),
          ),
        if (l.stories.isNotEmpty)
          DividedRows(
            rows: [
              for (final c in l.stories)
                _row(c, played: progress.played(c), first: c == prox),
            ],
          )
        else ...[
          Block(
            top: 16,
            bottom: 16,
            child: Text(
              open
                  ? 'Not built yet.'
                  : 'Locked until the places before it are done.',
              style: CoquiText.bodyMuted,
            ),
          ),
          Block(
            top: 14,
            bottom: 14,
            child: Text(
              'Scenes: ${l.scenes.join(" · ")}',
              style: CoquiText.smallMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(String id, {required bool played, required bool first}) {
    final meta = course.meta(id);
    final title = meta?.title ?? id;
    return ListRow(
      title: ListRowTitle(title),
      subtitle: Text.rich(
        TextSpan(
          children: [
            if (played)
              TextSpan(text: 'Played', style: CoquiText.ok)
            else
              const TextSpan(text: 'New'),
            TextSpan(text: ' · about ${meta?.minutes ?? 0} min'),
          ],
        ),
      ),
      trailing: PlayButton(
        quiet: !first,
        semanticLabel: '${played ? "Play again" : "Play"}: $title',
        onPressed: () => onPlay(id),
      ),
    );
  }
}
