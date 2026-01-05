import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'services/font_service.dart';
import 'services/ffmpeg_waveform_service.dart';
import 'ui/startup_screen.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/log_service.dart';
import 'package:logging/logging.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Global Logging
  LogService().init();
  final logger = Logger('ChronoScript');
  logger.info("Application starting...");

  // Desktop Window Configuration
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(1024, 768),
    center: true,
    backgroundColor: const Color(0xFF8B1538),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'ChronoScript Studio',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    // Set the icon for Taskbar/Task Manager
    await windowManager.setIcon('assets/icons/app_icon.png');
  });

  // Verify Font Availability
  final fontAvailable = await FontService.isFontAvailable();
  if (!fontAvailable) {
    debugPrint("WARNING: NotoSerifEthiopic font might be missing.");
  }

  runApp(const ProviderScope(child: ChronoScriptApp()));
}

class ChronoScriptApp extends StatefulWidget {
  const ChronoScriptApp({super.key});

  @override
  State<ChronoScriptApp> createState() => _ChronoScriptAppState();
}

class _ChronoScriptAppState extends State<ChronoScriptApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    // Prevent default close behavior to allow cleanup
    windowManager.setPreventClose(true);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      // 1. Cleanup Audio
      if (SoLoud.instance.isInitialized) {
        SoLoud.instance.deinit();
      }
      // 2. Cleanup FFmpeg (Active processes)
      FfmpegWaveformService.killAll();

      // 3. Destroy window and Exit
      await windowManager.destroy();
      exit(0);
    }
  }

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
        tooltipTheme: TooltipThemeData(
          textStyle: GoogleFonts.lexend(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
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
