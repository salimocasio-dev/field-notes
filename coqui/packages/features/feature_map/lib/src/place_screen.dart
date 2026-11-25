import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_model.dart';
import 'package:material_ui/material_ui.dart';

/// Chooses the hero [PictureRef] for [place], preferring [preferredScene] when
/// it matches a pair in [course.pairs] and falling back to [sceneMatchesPlace].
@visibleForTesting
PictureRef? pickPlaceHeroPictureRef({
  required Place place,
  required CourseCatalog course,
  String? preferredScene,
}) {
  final pairs = course.pairs;
  if (pairs.isEmpty) return null;
  final language = course.language;
  if (preferredScene != null) {
    final target = normalizeSceneName(language, preferredScene);
    if (target.isNotEmpty) {
      for (final pair in pairs) {
        final scene = pair.yes.scene ?? pair.scene;
        if (normalizeSceneName(language, scene) == target) {
          return PictureRef.of(pair, pair.yes);
        }
      }
    }
  }
  for (final pair in pairs) {
    final scene = pair.yes.scene ?? pair.scene;
    if (sceneMatchesPlace(language, scene, place)) {
      return PictureRef.of(pair, pair.yes);
    }
  }
  return null;
}

/// Chooses a [PictureRef] for story tile [storyIndex] inside [place], preferring
/// pairs matching [storyScene] (cycling by `storyIndex % matches.length`) and
/// falling back to [sceneMatchesPlace].
@visibleForTesting
PictureRef? pickStoryTilePictureRef({
  required Place place,
  required int storyIndex,
  required CourseCatalog course,
  String? storyScene,
}) {
  final pairs = course.pairs;
  if (pairs.isEmpty) return null;
  final language = course.language;
  if (storyScene != null) {
    final target = normalizeSceneName(language, storyScene);
    if (target.isNotEmpty) {
      final sceneMatches = <ReviewPair>[
        for (final pair in pairs)
          if (normalizeSceneName(language, pair.yes.scene ?? pair.scene) ==
              target)
            pair,
      ];
      if (sceneMatches.isNotEmpty) {
        final chosen = sceneMatches[storyIndex % sceneMatches.length];
        return PictureRef.of(chosen, chosen.yes);
      }
    }
  }
  final placeMatches = <ReviewPair>[
    for (final pair in pairs)
      if (sceneMatchesPlace(language, pair.yes.scene ?? pair.scene, place))
        pair,
  ];
  if (placeMatches.isNotEmpty) {
    final chosen = placeMatches[storyIndex % placeMatches.length];
    return PictureRef.of(chosen, chosen.yes);
  }
  return null;
}

/// Full-screen place view (`Noche-Lugar.dc.html`, story N4.2): full-bleed
/// scene hero with floating back button and `"Place X of Y"` counter, place
/// title and heard count, horizontal story tiles (`104 x 80`), outline action
/// pills (`Listen again`, `Read`, `Call <partner>`), and the pinned orange
/// [NochePlayBar] above the floating tab bar.
class PlaceScreen extends StatefulWidget {
  const PlaceScreen({
    super.key,
    required this.placeId,
    required this.services,
    this.entitlements = const AllowAllEntitlements(),
  });

  final String placeId;
  final Services services;

  /// Injected entitlements until `Services.entitlements` lands in `coqui_ui`
  /// (see `coqui/requests/5-coqui-contracts-needs-coqui-ui-services-entitlements.md`).
  final Entitlements entitlements;

  @override
  State<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<PlaceScreen> {
  StreamSubscription<void>? _changes;
  StreamSubscription<void>? _entitlementChanges;
  int _serviceGen = 0;
  final Map<String, String?> _storyScenes = {};
  final Set<String> _loadingScenes = {};
  final Map<String, bool> _bookAvailable = {};
  final Set<String> _loadingBooks = {};

  Services get _s => widget.services;

  @override
  void initState() {
    super.initState();
    _changes = _s.progress.changes.listen((_) => _onProgressChanged());
    _entitlementChanges = widget.entitlements.changes.listen((_) {
      if (mounted) setState(() {});
    });
    _loadData(_serviceGen);
  }

  @override
  void didUpdateWidget(PlaceScreen old) {
    super.didUpdateWidget(old);
    if (old.entitlements != widget.entitlements) {
      _entitlementChanges?.cancel();
      _entitlementChanges = widget.entitlements.changes.listen((_) {
        if (mounted) setState(() {});
      });
    }
    if (old.services != widget.services || old.placeId != widget.placeId) {
      final gen = ++_serviceGen;
      if (old.services != widget.services) {
        _changes?.cancel();
        _changes = _s.progress.changes.listen((_) => _onProgressChanged());
        _storyScenes.clear();
        _loadingScenes.clear();
        _bookAvailable.clear();
        _loadingBooks.clear();
      }
      _loadData(gen);
    }
  }

  @override
  void dispose() {
    _serviceGen++;
    _changes?.cancel();
    _entitlementChanges?.cancel();
    super.dispose();
  }

  Place? _findPlace() {
    for (final p in _s.course.places) {
      if (p.id == widget.placeId) return p;
    }
    return null;
  }

  Future<void> _loadData(int gen) async {
    if (_s.course.places.isEmpty) {
      try {
        await _s.course.load();
      } on Object {
        return;
      }
      if (!mounted || gen != _serviceGen) return;
      setState(() {});
    }
    final place = _findPlace();
    if (place == null) return;
    _primeStoryScenes(place, gen);
    _primeLastHeardBook(place, gen);
  }

  void _onProgressChanged() {
    if (!mounted) return;
    final place = _findPlace();
    if (place != null) {
      _primeLastHeardBook(place, _serviceGen);
    }
    setState(() {});
  }

  void _primeStoryScenes(Place place, int gen) {
    for (final id in place.stories) {
      if (_storyScenes.containsKey(id) || _loadingScenes.contains(id)) continue;
      _loadingScenes.add(id);
      unawaited(() async {
        String? scene;
        try {
          final data = await _s.course.story(id);
          final raw = data['scene'];
          if (raw is String && raw.isNotEmpty) scene = raw;
        } on Object {
          scene = null;
        } finally {
          if (gen == _serviceGen) _loadingScenes.remove(id);
        }
        if (!mounted || gen != _serviceGen) return;
        if (_storyScenes[id] != scene) {
          setState(() => _storyScenes[id] = scene);
        } else {
          _storyScenes[id] = scene;
        }
      }());
    }
  }

  void _primeLastHeardBook(Place place, int gen) {
    final lastId = lastHeardStory(_s.progress, place);
    if (lastId == null) return;
    if (_bookAvailable.containsKey(lastId) || _loadingBooks.contains(lastId)) {
      return;
    }
    _loadingBooks.add(lastId);
    unawaited(() async {
      var available = false;
      try {
        final b = await _s.course.book(lastId);
        available = b != null;
      } on Object {
        available = false;
      } finally {
        if (gen == _serviceGen) _loadingBooks.remove(lastId);
      }
      if (!mounted || gen != _serviceGen) return;
      if (_bookAvailable[lastId] != available) {
        setState(() => _bookAvailable[lastId] = available);
      } else {
        _bookAvailable[lastId] = available;
      }
    }());
  }

  void _goBack() {
    _s.haptics.tick();
    _s.nav.go(const TabRoute(NocheTabs.map));
  }

  void _openStory(Place place, String storyId, {bool listen = false}) {
    if (!placeInPlan(place, _s.course.places, widget.entitlements)) return;
    _s.haptics.tick();
    _s.nav.go(StoryRoute(storyId, listen: listen));
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final places = _s.course.places;
    final place = _findPlace();

    if (place == null) {
      return ColoredBox(
        color: NocheColors.ground,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PositionedDirectional(
              start: 16,
              top: pad.top + 16,
              child: _BackButton(onPressed: _goBack),
            ),
          ],
        ),
      );
    }

    final lang = _s.course.language;
    final locale = Locale(lang.code);
    final hasStories = place.stories.isNotEmpty;
    final inPlan = placeInPlan(place, places, widget.entitlements);
    final heardCount = storiesPlayed(_s.progress, place);
    final nextId = nextUnheardStory(_s.progress, place);
    final nextIndex = nextId == null ? -1 : place.stories.indexOf(nextId);
    final lastHeard = lastHeardStory(_s.progress, place);
    final calls = _s.course.callsFor(place.id);

    final heroPreferredScene = nextId != null
        ? _storyScenes[nextId]
        : (place.stories.isNotEmpty ? _storyScenes[place.stories.first] : null);
    final heroRef = pickPlaceHeroPictureRef(
      place: place,
      course: _s.course,
      preferredScene: heroPreferredScene,
    );

    final showReadPill =
        lastHeard != null && (_bookAvailable[lastHeard] ?? false);
    final pills = <Widget>[
      if (lastHeard != null)
        NochePill.outline(
          key: const Key('place-pill-listen'),
          label: 'Listen again',
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
          onPressed: () => _openStory(place, lastHeard, listen: true),
        ),
      if (showReadPill)
        NochePill.outline(
          key: const Key('place-pill-read'),
          label: 'Read',
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
          onPressed: () {
            _s.haptics.tick();
            _s.nav.go(BookRoute(lastHeard));
          },
        ),
      if (calls.isNotEmpty)
        NochePill.outline(
          key: const Key('place-pill-call'),
          label: 'Call ${lang.partnerName}',
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
          onPressed: () {
            _s.haptics.tick();
            _s.nav.go(CallRoute(place.id));
          },
        ),
    ];

    final scrollBottom = hasStories
        ? NocheSize.aboveTabBar +
              (inPlan ? NocheSize.playBarHeight + 16 : 220) +
              pad.bottom
        : NocheSize.aboveTabBar + 16 + pad.bottom;

    return ColoredBox(
      color: NocheColors.ground,
      child: DefaultTextStyle.merge(
        style: NocheType.body.copyWith(color: NocheColors.text),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: EdgeInsetsDirectional.only(bottom: scrollBottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 296 + pad.top,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _SceneArtBox(
                          key: const Key('place-hero-picture'),
                          pictures: _s.pictures,
                          pictureRef: heroRef,
                          placeholder: ColoredBox(
                            color: NocheColors.panel,
                            child: const Center(
                              child: NocheIcon(
                                NocheIcons.map,
                                size: 48,
                                color: NocheColors.line,
                              ),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          start: 16,
                          top: pad.top + 16,
                          child: _BackButton(onPressed: _goBack),
                        ),
                        PositionedDirectional(
                          end: 16,
                          top: pad.top + 20,
                          child: Semantics(
                            readOnly: true,
                            child: Container(
                              key: const Key('place-counter'),
                              height: 40,
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 16,
                              ),
                              alignment: AlignmentDirectional.center,
                              decoration: BoxDecoration(
                                color: NocheColors.ground,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Place ${place.n} of ${places.length}',
                                maxLines: 1,
                                softWrap: false,
                                style: NocheType.button.copyWith(
                                  color: NocheColors.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      24,
                      16,
                      0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            locale: locale,
                            style: NocheType.forScript(
                              NocheType.placeTitle,
                              lang.script,
                            ).copyWith(color: NocheColors.text),
                          ),
                        ),
                        if (hasStories) ...[
                          const SizedBox(width: 12),
                          Text(
                            '$heardCount of ${place.stories.length} stories heard',
                            style: NocheType.body.copyWith(
                              color: NocheColors.label,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasStories) ...[
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 16,
                            ),
                            child: NocheSectionLabel(
                              'All ${place.stories.length} stories',
                              trailing: !inPlan
                                  ? const NochePill.planTag(
                                      key: Key('place-plan-tag'),
                                      label: 'Course',
                                    )
                                  : null,
                            ),
                          ),
                          SingleChildScrollView(
                            key: const Key('place-stories-scroll'),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (
                                  var i = 0;
                                  i < place.stories.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(width: 16),
                                  _buildStoryTile(
                                    place: place,
                                    index: i,
                                    storyId: place.stories[i],
                                    inPlan: inPlan,
                                    isNext:
                                        inPlan && place.stories[i] == nextId,
                                    lang: lang,
                                    locale: locale,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (inPlan && pills.isNotEmpty)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          24,
                          16,
                          0,
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < pills.length; i++) ...[
                              if (i > 0) const SizedBox(width: NocheSize.grid),
                              Expanded(
                                child: SizedBox(
                                  height: NocheSize.touch,
                                  child: LayoutBuilder(
                                    builder: (context, c) => FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: c.maxWidth,
                                        ),
                                        child: pills[i],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ] else
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        24,
                        16,
                        0,
                      ),
                      child: NocheCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              placeOpen(_s.progress, place) ? 'Not built yet.' : 'Locked until the places before it are done.',
                              style: NocheType.body.copyWith(
                                color: NocheColors.text,
                              ),
                            ),
                            if (place.scenes.isNotEmpty) ...[
                              const SizedBox(height: NocheSize.grid),
                              Text(
                                'Scenes: ${place.scenes.join(' · ')}',
                                locale: locale,
                                style: NocheType.forScript(
                                  NocheType.bodySmall,
                                  lang.script,
                                ).copyWith(color: NocheColors.label),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (hasStories)
              PositionedDirectional(
                start: 16,
                end: 16,
                bottom: NocheSize.aboveTabBar + pad.bottom,
                child: inPlan
                    ? _buildPlayBar(
                        place: place,
                        nextId: nextId,
                        nextIndex: nextIndex,
                        calls: calls,
                        lang: lang,
                        locale: locale,
                      )
                    : _buildPlanCard(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryTile({
    required Place place,
    required int index,
    required String storyId,
    required bool inPlan,
    required bool isNext,
    required Language lang,
    required Locale locale,
  }) {
    final isHeard = _s.progress.played(storyId);
    final title = _s.course.meta(storyId)?.title ?? storyId;
    final tileRef = pickStoryTilePictureRef(
      place: place,
      storyIndex: index,
      course: _s.course,
      storyScene: _storyScenes[storyId],
    );
    final statusSuffix = !inPlan
        ? ', in Course'
        : isHeard
        ? ', heard'
        : isNext
        ? ', up next'
        : '';

    return SizedBox(
      width: 104,
      child: Pressable(
        key: Key('story-tile-$storyId'),
        semanticLabel: 'Story ${index + 1}: $title$statusSuffix',
        onPressed: inPlan ? () => _openStory(place, storyId) : null,
        builder: (context, pressed) => Transform.scale(
          scale: pressed ? 0.98 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 104,
                height: 80,
                foregroundDecoration: isNext
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          NocheSize.tileRadius,
                        ),
                        border: Border.all(color: NocheColors.next, width: 3),
                      )
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(NocheSize.tileRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _SceneArtBox(
                        pictures: _s.pictures,
                        pictureRef: tileRef,
                        placeholder: ColoredBox(
                          color: NocheColors.chip,
                          child: const Center(
                            child: NocheIcon(
                              NocheIcons.map,
                              size: 28,
                              color: NocheColors.label,
                            ),
                          ),
                        ),
                      ),
                      if (isHeard)
                        PositionedDirectional(
                          start: 8,
                          top: 8,
                          child: Container(
                            key: Key('story-heard-$storyId'),
                            width: 24,
                            height: 24,
                            alignment: AlignmentDirectional.center,
                            decoration: const BoxDecoration(
                              color: NocheColors.ground,
                              shape: BoxShape.circle,
                            ),
                            child: const NocheIcon(
                              NocheIcons.check,
                              size: 14,
                              color: NocheColors.text,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: NocheSize.grid),
              Text(
                '${index + 1} · $title',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                locale: locale,
                style:
                    NocheType.forScript(
                      isNext ? NocheType.buttonStrong : NocheType.button,
                      lang.script,
                    ).copyWith(
                      color: isHeard ? NocheColors.label : NocheColors.text,
                      height: lang.script == 'Latn' ? 18 / 14 : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard() => NocheCard(
    key: const Key('place-plan-card'),
    variant: NocheCardVariant.highlight,
    padding: const EdgeInsetsDirectional.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'This place is in Course',
          style: NocheType.sheetTitle.copyWith(color: NocheColors.text),
        ),
        const SizedBox(height: NocheSize.grid),
        Text(
          'Every place and every story are in Course.',
          style: NocheType.body.copyWith(color: NocheColors.label),
        ),
        const SizedBox(height: 16),
        NochePrimaryButton(
          key: const Key('place-see-plans'),
          label: 'See plans',
          onPressed: () {
            _s.haptics.tick();
            _s.nav.go(const PlansRoute());
          },
        ),
      ],
    ),
  );

  Widget _buildPlayBar({
    required Place place,
    required String? nextId,
    required int nextIndex,
    required List<CallBrief> calls,
    required Language lang,
    required Locale locale,
  }) {
    if (nextId != null) {
      final nextMeta = _s.course.meta(nextId);
      return NochePlayBar(
        key: const Key('place-play-bar'),
        eyebrow: 'Play next · Story ${nextIndex + 1}',
        title: nextMeta?.title ?? nextId,
        meta: nextMeta != null ? '${nextMeta.minutes} min' : null,
        icon: NocheIcons.play,
        script: lang.script,
        locale: locale,
        onPressed: () {
          _s.haptics.tick();
          _s.nav.go(StoryRoute(nextId));
        },
      );
    }
    if (calls.isNotEmpty) {
      final mainCall = calls.firstWhere(
        (c) => c.isMain,
        orElse: () => calls.first,
      );
      return NochePlayBar(
        key: const Key('place-play-bar'),
        eyebrow: 'All stories heard',
        title: 'Call ${lang.partnerName}',
        meta: mainCall.minutes > 0 ? '${mainCall.minutes} min' : null,
        icon: NocheIcons.mic,
        onPressed: () {
          _s.haptics.tick();
          _s.nav.go(CallRoute(place.id));
        },
      );
    }
    return NochePlayBar(
      key: const Key('place-play-bar'),
      eyebrow: 'All stories heard',
      title: 'Review',
      meta: null,
      icon: NocheIcons.play,
      onPressed: () {
        _s.haptics.tick();
        _s.nav.go(const ReviewRoute());
      },
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: const Key('place-back'),
      semanticLabel: 'Back to the map',
      onPressed: onPressed,
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.96 : 1,
        child: Container(
          width: NocheSize.touch,
          height: NocheSize.touch,
          alignment: AlignmentDirectional.center,
          decoration: const BoxDecoration(
            color: NocheColors.ground,
            shape: BoxShape.circle,
          ),
          child: const NocheIcon(
            NocheIcons.back,
            size: 24,
            color: NocheColors.text,
          ),
        ),
      ),
    );
  }
}

class _SceneArtBox extends StatelessWidget {
  const _SceneArtBox({
    super.key,
    required this.pictures,
    required this.pictureRef,
    required this.placeholder,
  });

  static const int _picW = 196;
  static const int _picH = 104;

  final PictureSource pictures;
  final PictureRef? pictureRef;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final ref = pictureRef;
    if (ref == null) return placeholder;
    final dpr =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, c) {
          final scale = math.max(
            1,
            math.max(
              (c.maxWidth * dpr / _picW - 1e-6).ceil(),
              (c.maxHeight * dpr / _picH - 1e-6).ceil(),
            ),
          );
          final availW = _picW * scale / dpr;
          final availH = _picH * scale / dpr;
          return ClipRect(
            child: OverflowBox(
              minWidth: availW,
              maxWidth: availW,
              minHeight: availH,
              maxHeight: availH,
              alignment: AlignmentDirectional.center,
              child: pictures.of(ref, width: _picW, height: _picH),
            ),
          );
        },
      ),
    );
  }
}
