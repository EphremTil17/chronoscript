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

### Studio Session Persistence & Restoration
ChronoScript Studio now supports full session persistence and intelligent restoration. 
- **Auto-Save**: A background persistence layer automatically backups progress every 60 seconds to a localized auto-save file.
- **Manual Save**: Operators can save their work to a custom location to resume later.
- **Intelligent Restoration**: The system can resume sessions even if the original audio has been moved. It employs a three-tier safety logic (filename match, fuzzy match override, and a hardware duration guard) to ensure project integrity during restoration.
- **Full State Recovery**: Resuming a session restores the exact UI state, including the last selected verse, tab index, and all granular synchronization data.

### Granular Progress Tracking
The application provides real-time feedback on project completion to ensure production targets are met.
- **Overall Completion Header**: A persistent progress bar at the top of the studio sidebar summarizes total project synchronization.
- **Verse-Level Metrics**: Every verse in the navigation list displays a numerical percentage and a mini progress bar, with 100% complete sections clearly highlighted in green.

### Karaoke Style Preview Mode
A dedicated "Preview" tab provides a real-time, interactive environment to verify synchronization quality.
- **Dynamic Highlighting**: Words illuminate in real-time as the audio plays, using the production "Crimson" theme.
- **Visual Confidence**: A 50% synchronization threshold ensures that only verses with sufficient data are available for preview, maintaining high production standards.
- **Tabbed Workflow**: Seamlessly switch between the "Synchronization" grid and the "Preview" flow using the Chrome-inspired tabbed interface.

### Desktop-First Architecture
Designed as a dedicated Windows application using Flutter, ChronoScript Studio leverages system-level window management for a premium production feel, supporting large-screen layouts and high-resolution typography specialized for Ethiopic and other complex scripts. The **"Crimson & Parchment"** design system was developed specifically to provide a high-contrast, low-fatigue environment for long-form transcription sessions.

## Technical Specifications

### Tech Stack & Rationale
- **Framework**: Flutter (Desktop/Windows) — *Selected for its 60FPS rendering performance and native x64 compilation.*
- **State Management**: Riverpod (StateNotifier) — *Enables a reactive, unidirectional data flow that keeps the playback timer, UI word cards, and preview state in perfect synchronization.*
- **Audio Engine**: flutter_soloud (C++) — *Utilized for its low-level memory-mapped decoding, ensuring frame-accurate seeking at any playback speed.*
- **Process Management**: FFmpeg — *The industrial standard for media analysis, used here for high-speed, asynchronous waveform peak extraction.*
- **Typography**: Lexend and Noto Serif Ethiopic — *Chosen for their specialized optical kerning and superior ligature rendering for complex scripts.*

### Key Infrastructure
- `flutter_riverpod`: Handles the high-frequency state updates required for real-time playhead tracking.
- `flutter_soloud`: Powers the high-performance audio scrubbing and speed-neutralization seeking logic.
- `file_picker`: Integrated for professional file handling during session saves and exports.
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
2. **Entry Point**:
   - **New Project**: Select "INITIALIZE STUDIO" after uploading source text (`.txt`/`.md`) and audio (`.mp3`/`.wav`).
   - **Resume Session**: Select "RESUME EXISTING SESSION" to load a previously saved `.json` project file.
3. **Synchronization**:
   - Use the Play button to start audio playback.
   - Click the "**TRANSCRIBE**" button to mark the beginning of a word.
   - Use the "**CHAIN**" button or designated shortcuts (`Space`) to concurrently end the current word and start the next.
   - Use the "**Reset Word**" button to clear synchronization data for the selected word if corrections are needed.
4. **Saving**: Use the "**Save**" button or `Ctrl+S` to persist your studio session.
5. **Verification & Preview**: 
   - Switch to the "**Preview**" tab to see the live Karaoke-style playback.
   - Scrub through the optimized waveform to verify word placements. Individual word cards will highlight in alignment with the audio playhead.
6. **Export**: Export the final synchronized outputs (JSON & Tagged Markdown) once the verse is fully perfected.

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
