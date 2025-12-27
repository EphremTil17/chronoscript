# ChronoScript Studio

ChronoScript Studio is a specialized production tool designed for the precision synchronization of textual content with spoken-word audio. While originally developed to streamline the creation of time-aligned liturgical and educational transcripts, the application provides a general-purpose, high-performance environment for mapping individual words to specific timestamps in any long-form audio recording.

## Background and Objective

In various fields such as modern education, accessibility, and cultural preservation (e.g., liturgical archives), traditional transcription methods often lack the temporal granularity required for interactive media. ChronoScript Studio addresses this by providing a professional "Tapping" interface where operators can synchronize raw text with audio in real-time. The objective is to produce highly accurate synchronization data that can be exported for use in captioning systems, language learning platforms, or synchronized reading applications.

## Key Features

### FFmpeg-Powered Waveform Visualization
The application features a custom-built waveform extraction system that utilizes FFmpeg for high-speed audio analysis. Unlike standard library-based visualizations, our implementation:
- Performs asynchronous peak extraction using optimized PCM sample processing.
- Downsamples audio to 4kHz to ensure near-instant visualization of hour-long recordings.
- Employs a fixed-resolution caching layer (200 high-fidelity peaks) to minimize CPU overhead and storage footprint.
- Utilizes `RepaintBoundary` and cached `Paint` objects for 60FPS fluid scrubbing on desktop hardware.

### "Chain-Sync" Workflow
To handle the fast pace of spoken content, the studio implements a "Chain-Sync" logic. This allows the operator to mark the end of one word and the start of the next with a single interaction, ensuring zero-gap transitions and maintaining a continuous synchronous flow.

### Desktop-First Architecture
Designed as a dedicated Windows application using Flutter, ChronoScript Studio leverages system-level window management for a premium production feel, supporting large-screen layouts and high-resolution typography specialized for Ethiopic and other complex scripts. The **"Crimson & Parchment"** design system was developed specifically to provide a high-contrast, low-fatigue environment for long-form transcription sessions.

## Technical Specifications

### Tech Stack & Rationale
- **Framework**: Flutter (Desktop/Windows) — *Selected for its 60FPS rendering performance and native x64 compilation.*
- **State Management**: Riverpod (StateNotifier) — *Enables a reactive, unidirectional data flow that keeps the playback timer and UI word cards in perfect synchronization.*
- **Audio Engine**: flutter_soloud (C++) — *Utilized for its low-level memory-mapped decoding, ensuring frame-accurate seeking at any playback speed.*
- **Process Management**: FFmpeg — *The industrial standard for media analysis, used here for high-speed, asynchronous waveform peak extraction.*
- **Typography**: Lexend and Noto Serif Ethiopic — *Chosen for their specialized optical kerning and superior ligature rendering for complex scripts.*

### Key Infrastructure
- `flutter_riverpod`: Handles the high-frequency state updates required for real-time playhead tracking.
- `flutter_soloud`: Powers the high-performance audio scrubbing and speed-neutralization seeking logic.
- `path_provider`: Manages the secure local caching of generated waveform datasets.
- `window_manager`: Handles native Windows window lifecycle and the custom integrated title bar.

## Prerequisites

### FFmpeg Installation (Required)
The application requires FFmpeg to be installed and accessible via the system PATH for waveform generation.

**Windows Installation:**
1. Open PowerShell as Administrator.
2. Execute the following command:
   ```powershell
   winget install Gyan.FFmpeg --accept-package-agreements --accept-source-agreements
   ```
3. Restart the computer to ensure the system environment variables are refreshed.

**Manual Installation:**
- Download the FFmpeg release build from [ffmpeg.org](https://ffmpeg.org/download.html).
- Extract the binaries and add the `bin` folder to your Windows System Environment Variables (PATH).

## Usage Guide

1. **Initialization**: Upon launch, the application performs a prerequisite check. Ensure FFmpeg is detected before proceeding.
2. **Ingestion**: Upload the raw source text (`.txt` or `.md`) and the corresponding audio file (`.mp3` or `.wav`).
3. **Synchronization**:
   - Use the Play button to start audio playback.
   - Click the "**TRANSCRIBE**" button to mark the beginning of a word.
   - Use the "**CHAIN**" button or designated shortcuts to concurrently end the current word and start the next.
   - Use the "**Reset Word**" button to clear synchronization data for the selected word if corrections are needed.
4. **Verification**: Scrub through the optimized waveform to verify word placements. Individual word cards will highlight in alignment with the audio playhead.
5. **Export**: Data is exported in a structured JSON format containing time-aligned textual segments and word objects.

## Local Development

To run the project locally, ensure you have the Flutter SDK installed and configured for Windows desktop development.

```bash
# Clone the repository
git clone [repository-url]

# Install dependencies
flutter pub get

# Generate JSON models
flutter pub run build_runner build --delete-conflicting-outputs

# Run for Windows
flutter run -d windows
```
