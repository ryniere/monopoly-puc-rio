import 'package:flutter/material.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const QuarteiraoApp());
}

class QuarteiraoApp extends StatelessWidget {
  const QuarteiraoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quarteirão — protótipo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF43A047),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
