# Master Project Handover: ChronoScript Studio

> **Session Context**: This document is the definitive technical and philosophical guide for the project. It merges architectural rationale with project management standards built from December 22 to December 26, 2024.

## 1. Core Engineering Philosophy
The project prioritizes **Leanness, Performance, and Determinism**. We build production-grade tools, not prototypes.

### Architectural Principles
- **Critical Dependency Auditing**: Favor CLI tools (FFmpeg) or custom painters over heavy "black box" packages.
- **The "Windows First" Mindset**: Proactively address Windows-specific quirks (C++ interop, non-ASCII paths).
- **Latency Over Convenience**: Bypass sluggish wrappers for low-level performance.
- **Visual Excellence**: Strict adherence to the "Orthodox Vellum" theme (Crimson `#8B1538` / Pale Pink `#F5F1E8`).

## 2. Senior Decision Matrix: Key Technical Pivots

### Pivot: FFmpeg Sidecar vs. `just_waveform`
- **Issue**: `just_waveform` lacked Windows stability and struggled with hour-long recordings.
- **Senior Solution**: Custom `FfmpegWaveformService` calling the FFmpeg CLI.
- **Rationale**: Offloading peak extraction to a dedicated C++ process (FFmpeg) keeps the Flutter UI isolate fluid.
- **Implementation**: 4kHz downsampling and a fixed 200-peak resolution for sub-second analysis of large files.

### Pivot: Audio Staging and Format Hardening
- **Issue**: `flutter_soloud` fails on non-UTF8/non-ASCII Windows paths and has inconsistent `.m4a` support.
- **Senior Solution**: 
    1.  **Staging**: `AudioController` detects risky paths and copies audio to a normalized temp file before load.
    2.  **Constraints**: Restricted ingestion to `.mp3` and `.wav` via a hardened `FilePicker` in `home_page.dart`.

### Pivot: Specialized UI Rendering
- **Issue**: High-density waveform painting can cause UI jank during scrubbing.
- **Senior Solution**: Wrapped `WaveformScrubber` in a `RepaintBoundary` and utilized cached `Paint` objects to lock performance at 60FPS.

## 3. Software Management Standards

### GitHub Automation & Release Workflow
- **Naming Convention**: Use **Conventional Commits** (`feat:`, `fix:`, `chore:`, `refactor:`) to drive automation.
- **Release-Please**: We use `googleapis/release-please-action` for automated versioning and changelogs.
- **Bootstrapping**: The repo is baseline-tagged at `v2.0.0`. Future versions follow Semantic Versioning (SemVer).
- **Permissions**: Ensure "Allow GitHub Actions to create and approve pull requests" is enabled in repo settings.

### Project Context Map
- `lib/services/ffmpeg_waveform_service.dart`: Media processing logic.
- `lib/controllers/audio_controller.dart`: Audio engine and filesystem safety.
- `lib/providers/app_state.dart`: State machine for "Chain-Sync" logic.
- `lib/ui/startup_screen.dart`: Environment and FFmpeg prerequisite validator.

## 4. Development History (v1.0.0 → v1.2.0)
- **v1.0.0**: Initial baseline; Ge'ez ingestion; precision tapping grid.
- **v1.1.0**: Auto-save system; verification workflow; lifecycle management.
- **v1.1.1**: Ethiopic typography integration; massive linter cleanup.
- **v1.2.0**: FFmpeg migration; UI refactor; structured logging implementation.
- **v2.0.0**: Major Production Release; Frame-accurate seeking; Windows-style multi-selection; Hotkey interface; Dependency upgrade (SoLoud v3).

## 5. Future Roadmap
1. **Multi-File Batching**: Managing multiple audio assets in a unified studio session.
2. **Keyboard Mapping**: Production-ready hotkey customization (1-9 numeric triggers).
3. **Advanced Export**: Direct export to SRT, VTT, and tagged Markdown segments.

---
**Handover Instruction**: Review `project_context.md` alongside the `CHANGELOG.md`. The codebase is currently 100% lint-free and optimized for Windows Desktop. Maintain this rigor.
