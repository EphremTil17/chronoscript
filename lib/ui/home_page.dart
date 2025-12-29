import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoscript/ui/widgets/custom_title_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chronoscript/services/export_service.dart';
import 'package:chronoscript/services/ingestion_service.dart';
import 'package:chronoscript/providers/app_state.dart';
import 'package:chronoscript/controllers/audio_controller.dart';
import 'package:chronoscript/ui/tapping_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _textPath;
  String? _audioPath;
  bool _isLoading = false;

  final kCrimson = const Color(0xFF8B1538);
  final kPaper = const Color(0xFFF5F1E8);

  Future<void> _pickText() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Scripture Text',
      type: FileType.custom,
      allowedExtensions: ['txt', 'md'],
    );
    if (result != null) {
      setState(() => _textPath = result.files.single.path);
    }
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Audio Recording',
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
    );
    if (result != null) {
      setState(() => _audioPath = result.files.single.path);
    }
  }

  Future<void> _initializeStudio() async {
    if (_textPath == null || _audioPath == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. Load Scripture
      final verses = await IngestionService.ingestFile(_textPath!);
      ref.read(tappingProvider.notifier).setVerses(verses);

      // 2. Load Audio
      final audioCtrl = ref.read(audioControllerProvider);
      await audioCtrl.setAudioFile(_audioPath!);

      // 3. Store Metadata
      ref.read(audioPathProvider.notifier).state = _audioPath!;

      // 4. Navigate
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const TappingPage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resumeSession() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Studio Session',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      final String path = result.files.single.path!;
      final sessionData = await ExportService.loadSession(path);

      final metadata = sessionData['metadata'] as Map<String, dynamic>;
      String originalFileName = metadata['audio_file'] as String? ?? 'unknown';
      final String? audioFilePathSaved = metadata['audio_file_path'];

      // Fallback: If name it unknown but path exists, extract name from path using p.basename
      if (originalFileName == 'unknown' &&
          audioFilePathSaved != null &&
          audioFilePathSaved != 'unknown') {
        originalFileName = p.basename(audioFilePathSaved);
      }

      String? audioPath = audioFilePathSaved;

      bool needsRelink =
          audioPath == null ||
          audioPath == 'unknown' ||
          !await File(audioPath).exists();

      if (needsRelink) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Audio file not found at original path. Please locate '$originalFileName'.",
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: Colors.orange[800],
            ),
          );
        }

        FilePickerResult? audioResult = await FilePicker.platform.pickFiles(
          dialogTitle: 'Locate Audio: $originalFileName',
          type: FileType.custom,
          allowedExtensions: ['mp3', 'wav'],
        );

        if (audioResult == null) {
          throw Exception("Audio file is required to resume session.");
        }

        final selectedFile = audioResult.files.single;
        final selectedName = selectedFile.name;

        // --- SAFETY CHECK 1: Filename Match ---
        if (selectedName.toLowerCase() != originalFileName.toLowerCase()) {
          final proceed = await _showSafetyDialog(
            originalFileName,
            selectedName,
          );
          if (proceed != true) {
            throw Exception("Session load cancelled due to audio mismatch.");
          }
        }
        audioPath = selectedFile.path;
      }

      // --- SAFETY CHECK 2: Duration Validation ---
      final audioCtrl = ref.read(audioControllerProvider);
      await audioCtrl.setAudioFile(audioPath!);

      // Calculate max timestamp in session
      int maxMs = 0;
      final versesJson = sessionData['verses'] as List<dynamic>? ?? [];
      for (var v in versesJson) {
        final words = v['words'] as List<dynamic>? ?? [];
        for (var w in words) {
          final end = w['endTime'] as int?;
          if (end != null && end > maxMs) maxMs = end;
        }
      }

      final mediaDurationMs = audioCtrl.totalDuration.inMilliseconds;
      if (mediaDurationMs < maxMs) {
        throw Exception(
          "Safety Block: The selected audio (${mediaDurationMs}ms) is shorter than the synchronization data (${maxMs}ms). "
          "Loading this file could lead to data corruption.",
        );
      }

      // 1. Finalise Setup
      ref.read(audioPathProvider.notifier).state = audioPath;

      // 2. Initialise State
      final loadedState = TappingState.fromJson(sessionData);
      ref.read(tappingProvider.notifier).loadSession(loadedState);

      // 4. Navigate
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const TappingPage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll("Exception: ", ""),
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showSafetyDialog(String original, String selected) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Audio Name Mismatch",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "The selected file name does not match the original session metadata:",
              style: GoogleFonts.lexend(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildDialogInfoBlock("Original", original, Colors.grey.shade600),
            const SizedBox(height: 8),
            _buildDialogInfoBlock("Selected", selected, kCrimson),
            const SizedBox(height: 16),
            Text(
              "Are you sure you want to use this audio file?",
              style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "CANCEL",
              style: GoogleFonts.lexend(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kCrimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("!Load Anyway!", style: GoogleFonts.lexend()),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoBlock(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPaper,
      body: Column(
        children: [
          const CustomTitleBar(),
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kCrimson, width: 2),
                      ),
                      child: Icon(
                        Icons.auto_stories,
                        size: 64,
                        color: kCrimson,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      "ChronoScript Studio",
                      style: GoogleFonts.lexend(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: kCrimson,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      "Professional Liturgy Studio for precise audio-text synchronization",
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),

                    // Upload Slots
                    Row(
                      children: [
                        Expanded(
                          child: _UploadCard(
                            label: "Scripture Text",
                            icon: Icons.description_outlined,
                            filePath: _textPath,
                            onTap: _pickText,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _UploadCard(
                            label: "Audio Session (WAV)",
                            icon: Icons.audiotrack_outlined,
                            filePath: _audioPath,
                            onTap: _pickAudio,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),

                    // Initialize Button
                    SizedBox(
                      width: 300,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kCrimson,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: kCrimson.withAlpha(
                            (255 * 0.1).toInt(),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed:
                            (_textPath != null &&
                                _audioPath != null &&
                                !_isLoading)
                            ? _initializeStudio
                            : null,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                "INITIALIZE STUDIO",
                                style: GoogleFonts.lexend(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resume Button
                    SizedBox(
                      width: 300,
                      height: 56,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: kCrimson, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _resumeSession,
                        child: Text(
                          "RESUME EXISTING SESSION",
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kCrimson,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_textPath != null && _audioPath != null)
                      Text(
                        "All systems ready.",
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: kCrimson,
                          fontWeight: FontWeight.bold,
                        ),
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

class _UploadCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? filePath;
  final VoidCallback onTap;

  const _UploadCard({
    required this.label,
    required this.icon,
    required this.filePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLoaded = filePath != null;
    final crimson = const Color(0xFF8B1538);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: crimson.withValues(alpha: 0.1),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLoaded ? crimson : crimson.withValues(alpha: 0.3),
              width: isLoaded ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLoaded ? Icons.check_circle : icon,
                size: 32,
                color: crimson,
              ),
              const SizedBox(height: 16),
              Text(
                isLoaded ? (filePath!.split('\\').last.split('/').last) : label,
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: isLoaded ? FontWeight.w600 : FontWeight.w500,
                  color: isLoaded ? crimson : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isLoaded)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Click to upload",
                    style: GoogleFonts.lexend(
                      fontSize: 10,
                      color: Colors.black38,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
