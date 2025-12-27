import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final Color backgroundColor;
  final bool translucent;

  const CustomTitleBar({
    super.key,
    this.backgroundColor = const Color(0xFF8B1538),
    this.translucent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: translucent
          ? backgroundColor.withValues(alpha: 0.9)
          : backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                windowManager.startDragging();
              },
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              child: Container(
                color: Colors.transparent, // Capture taps
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icon/icon.png', // Assuming icon exists, or fallback
                      width: 14,
                      height: 14,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.auto_stories,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ChronoScript Studio',
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Window Controls
          _WindowButton(
            icon: Icons.minimize,
            onTap: () => windowManager.minimize(),
          ),
          _WindowButton(
            icon: Icons.check_box_outline_blank, // Restore/Max square
            onTap: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
            size: 14,
          ),
          _WindowButton(
            icon: Icons.close,
            onTap: () => windowManager.close(),
            isClose: true,
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(32);
}

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;
  final double size;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: isClose ? Colors.red : Colors.white.withValues(alpha: 0.1),
      child: Container(
        width: 46,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
