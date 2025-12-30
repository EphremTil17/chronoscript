import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chronoscript/ui/widgets/custom_title_bar.dart';
import '../services/prerequisite_service.dart';
import 'home_page.dart';
import 'package:logging/logging.dart';

/// Startup screen that checks prerequisites before allowing the app to proceed.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  static final _logger = Logger('StartupScreen');
  final List<String> _logs = [];
  bool _ready = false;
  bool _ffmpegMissing = false;

  // Theme colors - ONLY Crimson and Pale Pink
  static const Color crimson = Color(0xFF8B1538);
  static const Color palePink = Color(0xFFF5F1E8);
  static const Color logBackground = Color(
    0xFFEDE8DF,
  ); // Slightly darker pale pink
  static const Color darkGray = Color(0xFF4A4A4A);

  @override
  void initState() {
    super.initState();
    _runStartupChecks();
  }

  void _log(String message) {
    _logger.info(message);
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _runStartupChecks() async {
    _log("[ChronoScript] Initializing...");
    await Future.delayed(const Duration(milliseconds: 300));

    _log("[Prerequisites] Checking for FFmpeg...");
    final ffmpegError = await PrerequisiteService.checkFfmpeg();

    if (ffmpegError != null) {
      _log("[Prerequisites] FFmpeg not found!");
      _log("");
      _log("═══════════════════════════════════════════════════════════");
      _log("  FFmpeg is REQUIRED for waveform visualization");
      _log("═══════════════════════════════════════════════════════════");
      _log("");
      _log("INSTALLATION (Windows PowerShell as Admin):");
      _log("─────────────────────────────────────────────");
      _log(
        "  winget install Gyan.FFmpeg --accept-package-agreements --accept-source-agreements",
      );
      _log("");
      _log("AFTER INSTALLATION:");
      _log("─────────────────────────────────────────────");
      _log("  1. Close ALL PowerShell/terminal windows");
      _log("  2. Open a NEW PowerShell window");
      _log("  3. Verify with: ffmpeg -version");
      _log("  4. If not found, restart your computer");
      _log("  5. Then restart this application");
      _log("");
      _log("MANUAL ALTERNATIVE:");
      _log("  Download from: https://ffmpeg.org/download.html");
      _log("  Add the bin folder to your system PATH");
      _log("");
      setState(() {
        _ffmpegMissing = true;
      });
    } else {
      final version = await PrerequisiteService.getFfmpegVersion();
      _log("[Prerequisites] ✓ FFmpeg found!");
      _log("[Prerequisites] $version");
      _log("[ChronoScript] Ready!");
      setState(() {
        _ready = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palePink,
      body: Column(
        children: [
          const CustomTitleBar(),
          Expanded(
            child: Center(
              child: Container(
                width: 650,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo/Title
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/app_icon.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ChronoScript Studio',
                          style: GoogleFonts.lexend(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: darkGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Log Display - Light background with crimson border
                    Container(
                      height: 380,
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: logBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: crimson, width: 2),
                      ),
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];

                          // Default: dark gray text
                          Color textColor = darkGray;
                          FontWeight fontWeight = FontWeight.normal;

                          // Highlights in crimson
                          if (log.contains('not found') ||
                              log.contains('REQUIRED') ||
                              log.contains('INSTALLATION') ||
                              log.contains('AFTER INSTALLATION') ||
                              log.contains('MANUAL ALTERNATIVE')) {
                            textColor = crimson;
                            fontWeight = FontWeight.w600;
                          } else if (log.contains('✓') ||
                              log.contains('Ready')) {
                            textColor = crimson;
                            fontWeight = FontWeight.w600;
                          }

                          return SelectableText(
                            log,
                            style: GoogleFonts.firaCode(
                              fontSize: 11,
                              color: textColor,
                              height: 1.5,
                              fontWeight: fontWeight,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Status/Action
                    if (_ffmpegMissing)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _logs.clear();
                              _ffmpegMissing = false;
                            });
                            _runStartupChecks();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: crimson,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Retry Check',
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else if (!_ready)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            backgroundColor: crimson.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation(crimson),
                            minHeight: 2,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Hardening environment...",
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
