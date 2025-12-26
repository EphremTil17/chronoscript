import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'services/font_service.dart';
import 'ui/startup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop Window Configuration
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(1024, 768),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'ChronoScript Studio',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Verify Font Availability
  final fontAvailable = await FontService.isFontAvailable();
  if (!fontAvailable) {
    debugPrint("WARNING: NotoSerifEthiopic font might be missing.");
  }

  runApp(const ProviderScope(child: ChronoScriptApp()));
}

class ChronoScriptApp extends StatelessWidget {
  const ChronoScriptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoScript',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSerifEthiopic',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D6E63),
          surface: const Color(0xFFFDF5E6),
          onSurface: Colors.black87,
          primary: const Color(0xFF5D4037),
          secondary: const Color(0xFF795548),
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF5E6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFDF5E6),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF5D4037),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSerifEthiopic',
          ),
          iconTheme: IconThemeData(color: Color(0xFF5D4037)),
        ),
      ),
      home: const StartupScreen(), // Start with prerequisite check
    );
  }
}
