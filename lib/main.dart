import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/pages/desktop/desktop_screen.dart';
import 'presentation/pages/mobile/mobile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aman portfolio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LayoutBuilder(
        builder: (context, constraints) {
          // Common breakpoint for mobile is 600 pixels
          if (constraints.maxWidth < 600) {
            return const MobileScreen();
          } else {
            return const Desktop();
          }
        },
      ),
    );
  }
}
