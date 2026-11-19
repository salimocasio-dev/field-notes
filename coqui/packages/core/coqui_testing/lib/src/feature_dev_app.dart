import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Runs one feature's module alone, for its dev entry (`tool/dev_main.dart`) and its tests:
/// the screen it gives for [route], or else its tab.
class FeatureDevApp extends StatelessWidget {
  const FeatureDevApp({
    super.key,
    required this.module,
    required this.services,
    this.route,
  });

  final FeatureModule module;
  final Services services;

  /// The route to open; null: the module's tab.
  final AppRoute? route;

  @override
  Widget build(BuildContext context) {
    final r = route;
    final tab = module.tab(services);
    return MaterialApp(
      title: module.id,
      home: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (context) =>
                (r == null ? null : module.screenFor(r, services)) ??
                tab?.builder(context) ??
                Center(child: Text('${module.id}: nothing to show')),
          ),
        ),
      ),
    );
  }
}
