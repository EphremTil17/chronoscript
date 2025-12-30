import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/log_service.dart';
import 'package:logging/logging.dart';

class LogOverlay extends StatelessWidget {
  const LogOverlay({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Close Logs",
      barrierColor: Colors.black54, // Dim background
      transitionDuration: Duration.zero, // No animation
      pageBuilder: (context, _, _) => const LogOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color crimson = Color(0xFF8B1538);
    const Color palePink = Color(0xFFF5F1E8);
    const Color logBackground = Color(0xFFEDE8DF);
    const Color darkGray = Color(0xFF4A4A4A);

    return Stack(
      children: [
        // Backdrop Blur for 'Out of Focus' look
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.transparent),
          ),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 800,
              height: 600,
              decoration: BoxDecoration(
                color: palePink,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.terminal, color: crimson, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          "System Logs",
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkGray,
                          ),
                        ),
                        const Spacer(),
                        // Clear Logs Button
                        TextButton.icon(
                          onPressed: () => LogService().clear(),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: crimson,
                          ),
                          label: Text(
                            "CLEAR",
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: crimson,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: darkGray),
                          onPressed: () => Navigator.pop(context),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Log View
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: logBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: crimson.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                      child: ValueListenableBuilder<List<LogRecord>>(
                        valueListenable: LogService().logsNotifier,
                        builder: (context, logs, _) {
                          if (logs.isEmpty) {
                            return Center(
                              child: Text(
                                "Waiting for activity...",
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          return SelectionArea(
                            child: ListView.builder(
                              itemCount: logs.length,
                              itemBuilder: (context, index) {
                                final log = logs[index];

                                Color textColor = darkGray;
                                FontWeight fontWeight = FontWeight.normal;

                                if (log.level >= Level.SEVERE) {
                                  textColor = crimson;
                                  fontWeight = FontWeight.w600;
                                } else if (log.level >= Level.WARNING) {
                                  textColor = const Color(0xFFB8860B);
                                  fontWeight = FontWeight.w500;
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    "[${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}] ${log.message}",
                                    style: GoogleFonts.firaCode(
                                      fontSize: 11,
                                      color: textColor,
                                      fontWeight: fontWeight,
                                      height: 1.4,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
