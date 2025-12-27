# Changelog

All notable changes to the ChronoScript Studio project are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0 (2025-12-27)


### Features

* Add AGPL-3.0 license, changelog, initial home page, and update README. ([ba53f07](https://github.com/EphremTil17/chronoscript/commit/ba53f07afd50961e0839bacd1f59a03b2dad8b00))
* implement auto-save system and finalize verification workflow ([6e5ab2c](https://github.com/EphremTil17/chronoscript/commit/6e5ab2c38b8f2e254b4eda9ad344f49041d12503))
* Implement FFmpeg-based waveform extraction and prerequisite system. ([dbc1aeb](https://github.com/EphremTil17/chronoscript/commit/dbc1aeb7c3b3a8b284f11851dbfbb5f85daf3817))
* initial implementation of ChronoScript Studio ([5ff7694](https://github.com/EphremTil17/chronoscript/commit/5ff76941aa652cabd7493996a223b5907b2463ff))

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
