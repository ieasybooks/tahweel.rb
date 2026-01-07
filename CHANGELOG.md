## [Unreleased]

## [0.1.3] - 2026-01-07

### Changed

- Update Google OAuth credentials

## [0.1.2] - 2026-01-03

### Changed

- Normalize line endings in DOCX writer to proper OOXML line breaks
- Add Windows EXE build workflow

## [0.1.1] - 2025-12-03

### Changed

- Change from `AUTH_DRIVE` to `AUTH_DRIVE_FILE` permission scope in `Authorizer`

## [0.1.0] - 2025-12-02

### Added

#### Core Functionality
- PDF and image file OCR using Google Drive API
- Support for PDF files (split into images) and image files (JPG, JPEG, PNG)
- Multiple output formats:
  - **TXT**: Plain text with configurable page separators
  - **DOCX**: Formatted documents with text cleaning and alignment
  - **JSON**: Structured output with page-by-page content

#### Command-Line Interface
- Directory input support with recursive file discovery
- `-e, --extensions`: Filter files by extension (default: pdf, jpg, jpeg, png)
- `-p, --processor`: Select OCR processor (default: google_drive)
- `-F, --file-concurrency`: Control concurrent file processing (default: CPUs - 2)
- `-P, --page-concurrency`: Control concurrent OCR operations per file (default: 12)
- `--dpi`: Set DPI for PDF to image conversion (default: 150)
- `--page-separator`: Custom separator for TXT output (default: `\n\nPAGE_SEPARATOR\n\n`)
- `-f, --formats`: Specify output formats (comma-separated, default: txt,docx)
- `-o, --output`: Set output directory (preserves input directory structure)
- `-v, --version`: Display version information

#### Processing Features
- Concurrent processing at both file and page levels
- Real-time progress tracking with colored terminal UI showing:
  - Global progress (files completed/total)
  - Per-worker status (file name, stage, percentage, page count)
  - Elapsed time
- Skip logic: automatically skips files when all requested output formats already exist
- Directory structure preservation: maintains input directory hierarchy in output
- Text cleaning and normalization:
  - Collapses consecutive whitespace (spaces, newlines, tabs)
  - Normalizes line endings (converts `\r\n` to `\n`)
  - Removes Google Drive OCR separator lines
- Arabic text support: automatic right-to-left alignment in DOCX when Arabic characters dominate

#### Error Handling & Reliability
- OAuth 2.0 authorization flow with interactive browser-based authentication
- Credential caching using XDG Base Directory specification
- Exponential backoff retry logic for API rate limits and transient errors
- System resource limit detection (file descriptors) with helpful error messages
- Graceful error handling with user-friendly feedback
- Automatic cleanup of temporary files and Google Drive uploads

#### Technical Implementation
- Thread-based concurrency for true parallel processing
- Thread-safe progress tracking and state management
- Queue-based task distribution for worker threads
- Mutex-protected shared resources
- Comprehensive exception handling with error chain unwrapping
