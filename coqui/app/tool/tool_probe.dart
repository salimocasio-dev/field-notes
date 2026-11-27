// Tool-only widget tree probes for screenshot/frame capture tools under
// coqui/app/tool/. Kept out of coqui/app/test/ so shell tests stay strictly
// on shell-owned keys and contracts.
import 'package:flutter_test/flutter_test.dart';

/// Widgets whose runtime type name equals [name].
Finder byTypeName(String name) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

/// The [State] of the one widget whose runtime type name equals [name].
dynamic stateNamed(WidgetTester tester, String name) =>
    tester.state(byTypeName(name));
