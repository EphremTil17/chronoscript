import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:chronoscript/services/ingestion_service.dart';
import 'package:chronoscript/providers/app_state.dart';
import 'package:chronoscript/controllers/audio_controller.dart';
import 'package:chronoscript/ui/tapping_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _pickFiles(BuildContext context, WidgetRef ref) async {
    try {
      // 1. Pick Text File
      FilePickerResult? textResult = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Scripture Text (.txt, .md)',
        type: FileType.custom,
        allowedExtensions: ['txt', 'md'],
      );

      if (textResult == null) return; // User canceled
      String textPath = textResult.files.single.path!;

      // 2. Pick Audio File
      FilePickerResult? audioResult = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Audio Recording (.mp3, .wav)',
        type: FileType.audio,
      );

      if (audioResult == null) return; // User canceled
      String audioPath = audioResult.files.single.path!;

      // 3. Process & Load
      final words = await IngestionService.ingestFile(textPath);
      ref.read(tappingProvider.notifier).setWords(words);

      final audioCtrl = ref.read(audioControllerProvider);
      await audioCtrl.setAudioFile(audioPath);

      // 4. Navigate
      if (context.mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const TappingPage()));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading files: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("ChronoScript Studio")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mic_external_on,
              size: 80,
              color: Color(0xFF5D4037),
            ),
            const SizedBox(height: 24),
            const Text(
              "Start New Session",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text("You will need a .txt/.md file and an audio file"),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _pickFiles(context, ref),
              icon: const Icon(Icons.folder_open),
              label: const Text("Open Project Files"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
