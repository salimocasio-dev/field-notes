import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/about_sheet.dart';
import 'package:feature_profile/src/install_hint.dart';
import 'package:feature_profile/src/js.dart';
import 'package:feature_profile/src/language_chip.dart';
import 'package:feature_profile/src/me_data.dart';
import 'package:feature_profile/src/texts.dart';
import 'package:feature_profile/src/welcome.dart';
import 'package:material_ui/material_ui.dart';

/// The day the "speaking is not available" note was first shown on this page
/// (`app.html: NOTAPAG`). Lives as long as [Services] does.
final Expando<String> _notePage = Expando<String>('NOTAPAG');

/// The Noche Me tab (`docs/proyecto/noche/Noche-Yo.dc.html`, story N4.7 /
/// issue #107): header ("Me" + "How Coquí works"), stats card with 7-day
/// minutes bar chart, language card with place dashes and skill bars,
/// "Minutes a day" segmented control, "Your plan" row, and the existing
/// scrolling settings rows ("Open every place", "Speak in stories",
/// "Level check", "About", and build number).
class YoScreen extends StatefulWidget {
  const YoScreen({
    super.key,
    required this.services,
    this.howItWorksStep,
    this.aboutOpen = false,
    this.minutesOn,
    this.streakFreezes,
    this.stageMax,
    this.entitlements,
    this.level,
  });

  final Services services;

  /// For a dev entry and its screenshots: open "How it works" at this step
  /// (0 to 2) as soon as the screen is up.
  final int? howItWorksStep;

  /// For a dev entry and its screenshots: open the About sheet as soon as the
  /// screen is up.
  final bool aboutOpen;

  /// Optional daily-minutes reader until request 87
  /// (`LanguageProgressStore.minutesOn`) lands in `coqui_contracts`.
  final double Function(DateTime day)? minutesOn;

  /// Optional saved streak freezes count (`int?`, null today per Part 1.7)
  /// until request 87 (`LanguageProgressStore.streakFreezes`) lands.
  final int? streakFreezes;

  /// Optional maximum mastery stage until request 87
  /// (`LanguageProgressStore.stageMax`) lands; defaults to [defaultStageMax].
  final int? stageMax;

  /// Optional entitlements override; defaults to [Services.entitlements].
  final Entitlements? entitlements;

  /// Optional CEFR level override; defaults to `levelResult['cefr']` or `A1`.
  final String? level;

  @override
  State<YoScreen> createState() => _YoScreenState();
}

class _YoScreenState extends State<YoScreen> {
  StreamSubscription<void>? _changes;
  StreamSubscription<void>? _entitlementChanges;

  /// notaHabla(): whether the speech-unavailable note is on this draw.
  bool _note = false;

  /// Guards concurrent `speech.available()` calls across rapid store saves.
  bool _asking = false;

  /// One-time iOS browser install hint.
  bool _hint = false;

  Services get _s => widget.services;
  ProgressStore get _progress => _s.progress;
  Entitlements get _entitlements => widget.entitlements ?? _s.entitlements;

  @override
  void initState() {
    super.initState();
    final step = widget.howItWorksStep;
    if (step != null || widget.aboutOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (step != null) {
          _openHow(step);
        } else {
          _openAbout();
        }
      });
    }
    _listen();
    _listenEntitlements();
    _initHint();
    _checkNote();
  }

  void _listen() {
    _changes?.cancel();
    _changes = _progress.changes.listen((_) {
      if (!mounted) return;
      setState(() {});
      _checkNote();
    });
  }

  void _listenEntitlements() {
    _entitlementChanges?.cancel();
    _entitlementChanges = _entitlements.changes.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(YoScreen old) {
    super.didUpdateWidget(old);
    if (old.services != widget.services) {
      _listen();
      _checkNote();
    }
    if ((old.entitlements ?? old.services.entitlements) != _entitlements) {
      _listenEntitlements();
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    _entitlementChanges?.cancel();
    super.dispose();
  }

  // ---- the install hint ----

  /// On an iPhone in the browser, not installed, and not shown before: show it,
  /// and remember in this feature's own storage space so it is shown once.
  void _initHint() {
    final i = _s.info;
    if (!(i.isWeb && i.isIos && !i.installed)) return;
    final store = _s.storage(installHintSpace);
    if (store.read(installHintKey) != null) return;
    _hint = true;
    store.write(installHintKey, '1');
  }

  // ---- notaHabla (app.html:466) ----

  Future<void> _checkNote() async {
    if (_asking) return;
    _asking = true;
    final bool available;
    try {
      available = await _s.speech.available();
    } finally {
      _asking = false;
    }
    if (!mounted) return;
    var show = false;
    if (!available) {
      final today = DateTime.fromMillisecondsSinceEpoch(
        _s.clock.nowMs(),
        isUtc: true,
      ).toIso8601String().substring(0, 10);
      if (_notePage[_s] != today) {
        if (_progress.setting('notaHabla') != today) {
          _progress.setSetting('notaHabla', today);
          _notePage[_s] = today;
          show = true;
        }
      } else {
        show = true;
      }
    }
    if (show != _note) setState(() => _note = show);
  }

  // ---- the sheets ----

  // app.html: bienvenida(0). Opens the Noche welcome sheet (N4.8b, #109).
  void _openHow([int step = 0]) {
    final seen = jsTruthy(_progress.setting('bienvenida'));
    final steps = ValueNotifier<int>(step);
    unawaited(
      showNocheSheet<void>(
        context,
        dismissible: seen,
        builder: (context, close) => welcomeRouteBody(
          services: _s,
          step: steps,
          onNew: () {
            _progress.setSetting('bienvenida', 1);
            close();
          },
          onLeave: close,
        ),
      ),
    );
  }

  void _openAbout() => unawaited(
    showNocheSheet<void>(
      context,
      title: aboutRow,
      builder: (context, close) => aboutSheetBody(),
    ),
  );

  // ---- the page ----

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final setting = progress.setting;
    final levelResult = progress.levelResult;
    final data = buildMeViewData(
      services: _s,
      minutesOn: widget.minutesOn,
      streakFreezes: widget.streakFreezes,
      stageMax: widget.stageMax,
      entitlements: _entitlements,
      level: widget.level,
    );
    final courseLocale = Locale(data.language.code);
    final pad = MediaQuery.paddingOf(context);
    final levelSuffix = levelResult != null
        ? meLevelCheckDoneSuffix(
            jsString(levelResult['historias']),
            plural(
              levelResult['historias'] is num
                  ? levelResult['historias'] as num
                  : double.nan,
              'story',
              'stories',
            ),
          )
        : yoLevelCheckNotDone;
    final levelHelp = '$yoLevelCheckHelp $levelSuffix';

    return ColoredBox(
      color: NocheColors.ground,
      child: DefaultTextStyle.merge(
        style: NocheType.body.copyWith(color: NocheColors.text),
        child: IconTheme.merge(
          data: const IconThemeData(color: NocheColors.text),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: pad.top,
              bottom: NocheSize.aboveTabBar + pad.bottom,
            ),
            child: ClipRect(
              child: SingleChildScrollView(
                key: const Key('me-scroll'),
                padding: const EdgeInsetsDirectional.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MeHeader(onHowItWorks: _openHow),
                    if (_hint)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        child: KeyedSubtree(
                          key: const Key('install-hint'),
                          child: NocheCard(
                            padding: installHintPadding,
                            child: InstallHint(
                              onDismiss: () => setState(() => _hint = false),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 16,
                      ),
                      child: _StatsCard(data: data),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: _LanguageCard(
                        data: data,
                        courseLocale: courseLocale,
                        onOpenLanguages: () {
                          _s.haptics.tick();
                          _s.nav.go(const LanguagesRoute());
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const NocheSectionLabel(
                            yoMinutesADay,
                            bottomGap: NocheSize.grid,
                          ),
                          NocheSegmented<int>(
                            key: const Key('yo-minutes-segmented'),
                            semanticLabel: yoMinutesADay,
                            role: NocheSegmentedRole.radioGroup,
                            large: true,
                            selected: data.selectedMinutePill ?? -1,
                            options: [
                              for (final m in minutePills)
                                NocheSegmentOption<int>(value: m, label: '$m'),
                            ],
                            onChanged: (m) {
                              progress.setSetting('min', m);
                              _s.haptics.tick();
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: _PlanRow(
                        planName: data.planName,
                        onPressed: () {
                          _s.haptics.tick();
                          _s.nav.go(const PlansRoute());
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: NocheCard(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            NocheSwitchRow(
                              key: const Key('yo-todo'),
                              label: yoOpenEveryPlace,
                              subtitle: yoOpenEveryPlaceHelp,
                              showTopBorder: false,
                              value: jsTruthy(setting('todo')),
                              onChanged: (_) {
                                progress.setSetting(
                                  'todo',
                                  jsTruthy(setting('todo')) ? 0 : 1,
                                );
                                _s.haptics.tick();
                              },
                            ),
                            NocheSwitchRow(
                              key: const Key('yo-habla'),
                              label: yoSpeakInStories,
                              subtitle: yoSpeakInStoriesHelp,
                              showTopBorder: true,
                              value: setting('habla') != 0,
                              onChanged: (_) {
                                progress.setSetting(
                                  'habla',
                                  setting('habla') == 0 ? 1 : 0,
                                );
                                _s.haptics.tick();
                              },
                            ),
                            if (_note)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  top: 4,
                                  bottom: 12,
                                ),
                                child: Text(
                                  yoSpeechNote,
                                  key: const Key('yo-speech-note'),
                                  style: NocheType.bodySmall.copyWith(
                                    color: NocheColors.label,
                                  ),
                                ),
                              ),
                            _LevelCheckRow(
                              help: levelHelp,
                              onStart: () {
                                _s.haptics.tick();
                                _s.nav.go(const LevelCheckRoute());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: _AboutRow(onTap: _openAbout),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: Center(
                        child: Text(
                          meBuildLabel(_s.info.build),
                          key: const Key('build-number'),
                          style: NocheType.bodySmall.copyWith(
                            fontSize: 12,
                            height: 16 / 12,
                            color: NocheColors.label,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Top 64-high header: `"Me"` at start, outline pill `"How Coquí works"` at end
/// (`Noche-Yo.dc.html:19-22`).
class _MeHeader extends StatelessWidget {
  const _MeHeader({required this.onHowItWorks});

  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            header: true,
            child: Text(
              meTitle,
              style: NocheType.pageTitle.copyWith(color: NocheColors.text),
            ),
          ),
          NochePill.outline(
            key: const Key('yo-how-it-works'),
            label: meHowCoquiWorks,
            onPressed: onHowItWorks,
          ),
        ],
      ),
    );
  }
}

/// Stats card (`Noche-Yo.dc.html:24-45`): total minutes listened across all
/// languages, streak flame + days (hidden at 0) with optional saved freezes
/// (shown only when non-null), and the 7-day minutes bar chart with goal line.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.data});

  final MeViewData data;

  @override
  Widget build(BuildContext context) {
    return NocheCard(
      key: const Key('me-stats-card'),
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.bottomStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${data.totalMinutes}',
                        key: const Key('me-total-minutes'),
                        style: NocheType.statNumber.copyWith(
                          color: NocheColors.text,
                        ),
                      ),
                      const SizedBox(width: NocheSize.grid),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meMinutesListened,
                            maxLines: 1,
                            softWrap: false,
                            style: NocheType.button.copyWith(
                              height: 16 / 14,
                              color: NocheColors.text,
                            ),
                          ),
                          Text(
                            meAllLanguages,
                            maxLines: 1,
                            softWrap: false,
                            style: NocheType.body.copyWith(
                              height: 16 / 14,
                              color: NocheColors.label,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (data.streak > 0) ...[
                const SizedBox(width: NocheSize.grid),
                Column(
                  key: const Key('me-streak'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NocheIcon(
                          NocheIcons.flame,
                          size: 18,
                          color: NocheColors.next,
                        ),
                        const SizedBox(width: NocheSize.grid),
                        Text(
                          data.streakLabel,
                          style: NocheType.rowTitle.copyWith(
                            height: 16 / 16,
                            color: NocheColors.text,
                          ),
                        ),
                      ],
                    ),
                    if (data.streakFreezesLabel != null) ...[
                      const SizedBox(height: NocheSize.grid),
                      Text(
                        data.streakFreezesLabel!,
                        key: const Key('me-streak-freezes'),
                        style: NocheType.bodySmall.copyWith(
                          fontSize: 12,
                          height: 16 / 12,
                          color: NocheColors.label,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          NocheBarChart(
            key: const Key('me-week-chart'),
            showValues: false,
            goal: data.goalMinutes,
            barAreaHeight: 64,
            semanticLabel: data.weekChartSemanticLabel,
            items: [
              for (final day in data.weekBars)
                NocheBarItem(
                  label: day.label,
                  value: day.minutes,
                  highlighted: day.isToday,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Language card (`Noche-Yo.dc.html:47-80`): language pill, level + place
/// progress, place dashes, Listening and Speaking progress bars, and Reading.
class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.data,
    required this.courseLocale,
    required this.onOpenLanguages,
  });

  final MeViewData data;
  final Locale courseLocale;
  final VoidCallback onOpenLanguages;

  @override
  Widget build(BuildContext context) {
    final place = data.currentPlace;
    return NocheCard(
      key: const Key('me-language-card'),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LanguageChip(
                key: const Key('me-language-chip'),
                language: data.language,
                onPanel: true,
                onPressed: onOpenLanguages,
              ),
              if (place != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        mePlaceProgressLabel(
                          level: data.level,
                          placeNumber: place.n,
                          placeTotal: data.placeTotal,
                        ),
                        key: const Key('me-place-progress'),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NocheType.rowTitle.copyWith(
                          color: NocheColors.text,
                        ),
                      ),
                      Text(
                        place.name,
                        key: const Key('me-place-name'),
                        locale: courseLocale,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NocheType.forScript(
                          NocheType.body.copyWith(
                            height: 16 / 14,
                            color: NocheColors.label,
                          ),
                          data.language.script,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (data.placeDashes.isNotEmpty) ...[
            const SizedBox(height: 16),
            NocheDashes(
              key: const Key('me-place-dashes'),
              states: data.placeDashes,
              gap: NocheSize.grid,
              semanticLabel: data.placeDashesSemanticLabel,
            ),
          ],
          const SizedBox(height: NocheSize.grid),
          _SkillProgressRow(
            key: const Key('me-skill-listening'),
            label: meListening,
            good: data.listeningGood,
            total: data.totalWords,
            fraction: data.listeningFraction,
          ),
          _SkillProgressRow(
            key: const Key('me-skill-speaking'),
            label: meSpeaking,
            good: data.speakingGood,
            total: data.totalWords,
            fraction: data.speakingFraction,
          ),
          _ReadingRow(
            key: const Key('me-skill-reading'),
            tracksReading: data.tracksReading,
          ),
        ],
      ),
    );
  }
}

class _SkillProgressRow extends StatelessWidget {
  const _SkillProgressRow({
    super.key,
    required this.label,
    required this.good,
    required this.total,
    required this.fraction,
  });

  final String label;
  final int good;
  final int total;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NocheType.button.copyWith(color: NocheColors.text),
            ),
          ),
          const SizedBox(width: NocheSize.grid),
          Expanded(
            child: NocheProgressBar(
              value: fraction,
              color: NocheColors.text,
              trackColor: NocheColors.line,
              height: 8,
              semanticLabel: meSkillGoodSemanticLabel(good, total),
            ),
          ),
          const SizedBox(width: NocheSize.grid),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96),
            child: Text(
              meSkillGoodLabel(good, total),
              textAlign: TextAlign.end,
              maxLines: 1,
              softWrap: false,
              style: NocheType.button.copyWith(color: NocheColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({super.key, required this.tracksReading});

  final bool tracksReading;

  @override
  Widget build(BuildContext context) {
    // Reading word mastery is not tracked in WordRecord yet, so show the honest
    // status line rather than inventing a 0-of-N progress count.
    final note = tracksReading ? meReadingOpenNote : meReadingNote;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              meReading,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NocheType.button.copyWith(color: NocheColors.text),
            ),
          ),
          const SizedBox(width: NocheSize.grid),
          Expanded(
            child: Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NocheType.body.copyWith(
                height: 14 / 14,
                color: NocheColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `"Your plan  <plan>   Manage ›"` pill row (`Noche-Yo.dc.html:92`).
/// Routes to [PlansRoute] (N3.2).
class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.planName, required this.onPressed});

  final String planName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: const Key('me-plan-row'),
      onPressed: onPressed,
      semanticLabel: mePlanSemanticLabel(planName),
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.99 : 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: NocheSize.primaryHeight),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: NocheColors.line, width: 1),
            borderRadius: BorderRadius.circular(NocheSize.primaryRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meYourPlan,
                      maxLines: 1,
                      softWrap: false,
                      style: NocheType.button.copyWith(
                        color: NocheColors.label,
                      ),
                    ),
                    const SizedBox(width: NocheSize.grid),
                    Flexible(
                      child: Text(
                        planName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NocheType.button.copyWith(
                          color: NocheColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: NocheSize.grid),
              Text(
                meManage,
                maxLines: 1,
                softWrap: false,
                style: NocheType.button.copyWith(color: NocheColors.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCheckRow extends StatelessWidget {
  const _LevelCheckRow({required this.help, required this.onStart});

  final String help;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: NocheColors.line, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  yoLevelCheck,
                  style: NocheType.rowTitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 20 / 15,
                    color: NocheColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  help,
                  style: NocheType.bodySmall.copyWith(
                    fontSize: 12,
                    height: 16 / 12,
                    color: NocheColors.label,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          NocheOutlineButton(
            key: const Key('yo-level-check'),
            label: yoStart,
            expand: false,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NocheCard(
      key: const Key('about-row'),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      onPressed: onTap,
      semanticLabel: aboutRow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            aboutRow,
            style: NocheType.rowTitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              height: 20 / 15,
              color: NocheColors.text,
            ),
          ),
          ExcludeSemantics(
            child: Text(
              '›',
              style: NocheType.rowTitle.copyWith(color: NocheColors.label),
            ),
          ),
        ],
      ),
    );
  }
}
