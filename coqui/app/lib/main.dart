import 'package:material_ui/material_ui.dart';

void main() => runApp(const CoquiApp());

/// The empty app. The tabs and routes come with order 26.
class CoquiApp extends StatelessWidget {
  const CoquiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Coquí',
      home: Scaffold(body: Center(child: Text('Coquí'))),
    );
  }
}
