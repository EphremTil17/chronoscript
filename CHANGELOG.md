# Changelog

All notable changes to the ChronoScript Studio project are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2025-12-29

### Added
- **Session Restoration System**: Added "RESUME EXISTING SESSION" functionality on the Home Page, allowing operators to pick up exactly where they left off with full state recovery (selected verse, tab index, and synchronization progress).
- **Advanced Audio Safety Guard**:
    - **Intelligent Relinking**: If an audio file has been moved on disk, the system prompts the user to relocate it by name.
    - **Three-Tier Verification**: Implemented a safety pipeline that checks for filename perfect matches, provides warnings for fuzzy matches, and enforces a "Hard Block" duration check if the new audio is shorter than existing synchronization timestamps.
- **Studio Lifecycle Management**: 
    - Added "Exit to Main Menu" with a multi-choice safety dialog (Save, Discard, or Cancel).
    - Integrated native window-close interception to ensure background engines (SoLoud, FFmpeg) are terminated reliably on application exit.
- **Granular Progress Visualization**: 
    - Added an "Overall Completion" tracker with a large progress indicator in the Verse Sidebar.
    - Implemented persistent sync-percentage displays and mini-progress bars for every verse in the navigation list.
    - Visual indicators now highlight 100% completed verses in "Success Green."

### Fixed
- **Metadata Robustness**: Resolved an issue where project files would save with an "unknown" audio filename. The system now intelligently derives the filename from the path via the `path` package.
- **Process Cleanup**: Fixed a critical bug where background services would persist in the Task Manager after the application window was closed.
- **Memory Optimization**: Refactored FFmpeg extraction to be more stable and balanced the audio engine's memory footprint for long-form sessions.

## [2.1.0] - 2025-12-28

### Added
- **Studio Save System**: Full project state persistence (`.json`) with support for manual and automatic saving.
- **Karaoke Style Preview Mode**: A new tabbed interface to preview synchronization in real-time with verse-based highlighting.
- **Dynamic Lock**: Preview mode is protected by a 50% synchronization threshold per verse to ensure data quality.
- **Tabbed UI**: Professional tabbed interface for switching between "Synchronization" and "Preview" modes.
- **Hotkeys**: Added `Ctrl+S` (Save) and refined `Space/Enter` behavior for seamless mode switching.

### Changed
- **UI Refinement**: Compacted the control hub and word grid to maximize screen real estate on smaller displays.
- **Button Styling**: Simplified "Save Session" to "Save" and standardized icon prominent colors.
- **Model Efficiency**: Refactored internal models to be immutable for better Riverpod performance.

### Fixed
- Fixed alignment gaps in the right-side studio panel for a pixel-perfect layout.
- Corrected hover splash layering on active Crimson-themed buttons.
- Resolved "Silent Fail" typos in the export logging.

## [2.0.0] - 2025-12-26
> **Major Production Milestone**: This release transforms ChronoScript Studio into a hardened production environment, focusing on frame-accurate temporal precision and high-throughput studio workflows.

### Added
- **Frame-Accurate Seeking Fix**: 
    - Resolved a critical engine-level seeking mismatch caused by internal scaling math during variable-speed playback.
    - Implemented **"Speed-Neutralization"**: a logic sandwich that temporarily resets play speed to 1.0x during seeks to ensure bit-perfect landing on absolute media timestamps.
    - Enforced `LoadMode.memory` for all audio ingestion to provide stable performance on Windows and eliminate compressed bitrate estimation jitters.
- **Multi-Word Selection System**:
    - Implemented industry-standard selection logic: `Ctrl+Click` for individual toggles and `Shift+Click` for range selection.
    - Refactored state management to utilize a highly efficient Set-based indexing for multi-selection.
    - Integrated a **"Reset (N)"** batch action, allowing operators to clear timestamps for a selected group of words in a single click.
    - **Logic Lock**: The "TRANSCRIBE" button now intelligently disables during multi-selection to prevent conflicting timing cues.
- **Hotkey Reference & Accessibility**:
    - Added a permanent keyboard icon to the status bar providing an on-demand reference for professional hotkeys (Space, Enter, P, and Arrows).
    - Standardized "Undo" and navigation shortcuts to align with professional production audio suites.

### Changed
- **Infrastructure Overhaul**: Upgraded `flutter_soloud` (v3.x), `window_manager` (v0.5.x), and `file_picker` (v10.x) to their latest major versions for enhanced Windows stability.
- **Design System Unification**: Fully unified the **"Crimson & Parchment"** visual theme across all entry screens and modernized the `README.md` with technical architecture rationales.
- **Technical Documentation**: Formalized the design system logic and technical pillars in the project documentation.

## [1.3.0] - 2025-12-26
### Added
- **Custom Title Bar**: Implemented a native-feel Crimson title bar with integrated window controls (Min/Max/Close) using `window_manager`.
- **Reset Word**: Added a "Reset Word" action in the control hub to clear timing data for specific words.
- **Enhanced Hover Effects**: Implemented system-wide interactive feedback for buttons, word cards, and sidebar items using `InkWell` and `Material` composites.

### Changed
- **UI Refinement**: Renamed the "START" recording action to "TRANSCRIBE" for improved clarity.
- **Layout Stability**: Fixed width constraints for recording controls to prevent UI jitter during state transitions.
- **Visual Polish**: Adjusted color palettes for consistent branding across success indicators and highlights.
- **Hover Logic**: Refactored widget layering to ensure hover overlays are correctly painted over opaque backgrounds.
- **Documentation**: Updated `README.md` usage instructions to align with new UI labels.

## [1.2.0] - 2025-12-26 [dbc1aeb]
### Added
- **FFmpeg Integration**: Introduced `FfmpegWaveformService` and `PrerequisiteService` to replace `just_waveform`. This enables high-performance peak extraction (4kHz sampling, 200-peak fixed resolution).
- **Startup Workflow**: Added `StartupScreen` to handle environment validation, FFmpeg detection, and provided user-oriented installation instructions.
- **Hierarchical Navigation**: Added `VerseSidebar` for multi-verse navigation and `Verse` model to support more complex document structures.
- **UI Components**: Implemented `LiturgyControlHub` and `WaveformScrubber` (via `simple_timeline_scrubber.dart`) to provide integrated playback controls.

### Changed
- **UI/UX Refactor**: Comprehensive redesign of the interface and theme consistency.
- **Performance Optimization**: Enhanced `WaveformPainter` using `RepaintBoundary` and cached `Paint` objects to ensure smooth rendering.
- **Improved Interaction**: Centered and enlarged chain icons; functionalized the audio speed adjuster (0.5x - 1.5x).
- **Code Maintenance**: Hardened the codebase by updating deprecated members, implementing structured logging via the `logging` package, and cleaning up dependencies (`path`, `logging`).

### Removed
- **Redundancy**: Deleted `lib/ui/widgets/word_button.dart` in favor of internal `_WordCard` implementation.
- **Package Reduction**: Removed `just_waveform` dependency due to compatibility issues.

## [1.1.1] - 2025-12-26 [02028a2]
### Added
- **Typography**: Integrated `toto_serif_ethiopic.ttf` font asset to ensure consistent rendering of Ge'ez scripture.

### Changed
- **Linter Cleanup**: Resolved numerous lint warnings and addressed deprecated members across the codebase.
- **Stability**: Refined `font_service.dart`, `export_service.dart`, and `ingestion_service.dart` to improve error handling and asset loading.

## [1.1.0] - 2025-12-25 [6e5ab2c]
### Added
- **Persistence**: Implemented an auto-save system in `TappingPage` that triggers every 60 seconds; added `saveAutoSave` to `ExportService` using `path_provider`.

### Changed
- **Lifecycle Management**: Improved state disposal and added missing `dart:async` imports.
- **Workflow Finalization**: Completed the verification mode logic and integrated native keyboard shortcuts for synchronization.

## [1.0.0] - 2025-12-22 [5ff7694]
### Added
- **Initial Baseline**: Established the Windows Desktop baseline with the 'Orthodox Vellum' high-contrast theme.
- **Core Services**: 
    - `IngestionService`: Support for Ge'ez text and Markdown parsing.
    - `AudioController`: Native playback with variable speed and seek logic.
    - `ExportService`: Generation of `sync.json` and tagged Markdown files.
- **Tapping Interface**: Precision UI featuring 'Progressive Fill' visual feedback for real-time synchronization.
- **Shortcuts**: Integrated global hotkeys for Undo, Rewind, Play/Pause, and Footnote placement.
- **Cleanup**: Stripped unnecessary cross-platform boilerplate to focus exclusively on Windows Desktop performance.
