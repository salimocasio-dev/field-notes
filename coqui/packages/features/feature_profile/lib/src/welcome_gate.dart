import 'dart:async';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/js.dart';
import 'package:feature_profile/src/welcome.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the welcome over [child] while the `bienvenida` setting says it has not been finished.
///
/// app.html: at the start, `if(!AJ().bienvenida) bienvenida(0)`. The welcome is a modal sheet over the
/// whole app, the tab bar too: a tap outside does nothing, and it comes back at every start until it is
/// finished. "I'm new to Spanish" (`listo()`) writes the setting and closes it; "I understand some
/// Spanish" writes the setting and goes to the level check. Once the setting is set it never shows again.
///
/// The shell wraps the app in it: `WelcomeGate(services: s, child: app)`.
class WelcomeGate extends StatefulWidget {
  const WelcomeGate({
    super.key,
    required this.services,
    required this.child,
    this.initialStep = 0,
  });

  final Services services;
  final Widget child;

  /// For a dev entry and its screenshots: the step (0 to 2) the welcome starts at. The app starts at 0.
  final int initialStep;

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  StreamSubscription<void>? _changes;
  late int _step = widget.initialStep;

  /// The first frame is drawn: the sheet slides in (app.html adds the class `on` after the page is built).
  bool _shown = false;
  late bool _needed;

  bool _check() => !jsTruthy(widget.services.progress.setting('bienvenida'));

  @override
  void initState() {
    super.initState();
    _needed = _check();
    _listen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  void _listen() {
    _changes?.cancel();
    _changes = widget.services.progress.changes.listen((_) {
      if (!mounted) return;
      final now = _check();
      setState(() {
        if (now && !_needed) {
          _step = 0; // the store was reset: the welcome starts again
        }
        _needed = now;
      });
    });
  }

  @override
  void didUpdateWidget(WelcomeGate old) {
    super.didUpdateWidget(old);
    if (old.services.progress != widget.services.progress) {
      _needed = _check();
      _listen();
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  // app.html: listo
  void _listo() => widget.services.progress.setSetting('bienvenida', 1);

  @override
  Widget build(BuildContext context) {
    final open = _needed && _shown;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        ExcludeSemantics(
          excluding: !open,
          child: CoquiSheetLayer(
            open: open,
            modal: true,
            sheet: welcomeSheet(
              services: widget.services,
              step: _step,
              onStep: (k) => setState(() => _step = k),
              onNew: _listo,
            ),
          ),
        ),
      ],
    );
  }
}
