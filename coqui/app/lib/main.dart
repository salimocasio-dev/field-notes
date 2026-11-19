import 'package:flutter/widgets.dart';

void main() => runApp(const CoquiApp());

/// The empty app. The tabs and routes come with order 26.
class CoquiApp extends StatelessWidget {
  const CoquiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Coquí',
      color: const Color(0xFFFFFFFF),
      builder: (context, _) => const ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Center(
          child: Text(
            'Coquí',
            textDirection: TextDirection.ltr,
            style: TextStyle(color: Color(0xFF000000), fontSize: 32),
          ),
        ),
      ),
    );
  }
}
