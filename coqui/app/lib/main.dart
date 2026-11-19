import 'package:material_ui/material_ui.dart';

/// The build number the site workflow puts in with
/// `--dart-define=COQUI_BUILD=<n>` (coqui/BUILD). `dev` when there is none.
const String coquiBuild = String.fromEnvironment(
  'COQUI_BUILD',
  defaultValue: 'dev',
);

void main() => runApp(const CoquiApp());

/// The empty app. The tabs and routes come with order 26.
class CoquiApp extends StatelessWidget {
  const CoquiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Coquí',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Coquí'),
              Text('build $coquiBuild', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
