import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
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
      type: FileType.audio,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPaper,
      body: Center(
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
                child: Icon(Icons.auto_stories, size: 64, color: kCrimson),
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
                      (_textPath != null && _audioPath != null && !_isLoading)
                      ? _initializeStudio
                      : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
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
              const SizedBox(height: 20),
              if (_textPath != null && _audioPath != null)
                Text(
                  "All systems ready.",
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLoaded
                ? Colors.green
                : crimson.withAlpha((255 * 0.3).toInt()),
            width: isLoaded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.03).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLoaded ? Icons.check_circle : icon,
              size: 32,
              color: isLoaded ? Colors.green : crimson,
            ),
            const SizedBox(height: 16),
            Text(
              isLoaded ? (filePath!.split('\\').last.split('/').last) : label,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: isLoaded ? FontWeight.w600 : FontWeight.w500,
                color: isLoaded ? Colors.green.shade700 : Colors.black87,
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
    );
  }
}
