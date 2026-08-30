# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.0.0] - 2026-08-30

### Added
- **Bilingual Support**: Full English/Persian interface
  - `--lang en` and `--lang fa` command-line options
  - Settings menu language switcher
  - 30+ translated message strings
- **Professional Terminal UI**:
  - Unicode box drawing characters (╔═╗║╚═╝)
  - Color-coded GPA display (green/yellow/red)
  - Visual progress bars for statistics
  - Section headers with visual separators
  - Status bar showing system health
  - Professional menu system with icons and descriptions
- **GPA Calculator** (`menu option 10`)
  - Weighted GPA calculation
  - Course-by-course entry
  - Visual feedback and interpretation
- **Batch CSV Import** (`menu option 9`)
  - Import from external CSV files
  - Duplicate detection (student code)
  - Preview before import
  - Automatic backup before/after import
- **Settings Menu** (`menu option 14`)
  - Change language at runtime
  - Configure max backups
  - Change log level
  - Toggle performance metrics
- **Enhanced Statistics**:
  - Visual bar charts for GPA distribution
  - Data integrity score
  - Top/bottom student indicators
- **New Test Suite**: `tests/test_features.sh`
  - Bilingual support tests
  - UI component tests
  - Version and author info tests
- **Color System**:
  - Professional color palette with combos (C_HEADER, C_SUCCESS, C_ERROR, etc.)
  - Color-coded table rows
  - Dim/muted text for secondary information

### Changed
- Complete UI overhaul with professional terminal design
- Menu structure reorganized into 3 sections (CRUD, Search & Reports, System)
- Statistics display now includes visual charts
- Log viewer uses improved color coding
- Author email updated to mehdi@code-watch.dev
- Version bumped to 5.0.0

### Improved
- Input validation error messages now more descriptive
- Student details view uses light box drawing
- Table headers use proper separators (─ instead of ━)
- Menu items include descriptions for better UX
- Status bar shows live student count and backup count

## [4.1.0] - 2026-07-25

### Added
- `--export-csv` CLI flag for exporting clean CSV
- Test suite in `tests/` directory with validation and CSV parsing tests
- Test runner script (`tests/run_tests.sh`)
- Case-insensitive search (portable `tolower()` instead of gawk-specific `IGNORECASE`)
- `start_timer`/`end_timer` to `view_logs` and `list_backups` functions

### Changed
- Unified locking mechanism (removed mixed usage of directory lock + `flock` on fd 200)
- Simplified `log()` function (removed redundant `flock`; uses atomic append)
- Simplified `add_student()` append (uses directory lock, no extra `flock`)
- Made backup listing POSIX-compatible (replaced GNU `find -printf` with `ls -1t`)
- Made backup cleanup POSIX-compatible (portable `ls -t` + `tail` + `rm`)
- Removed redundant `-F','` from AWK calls that set `FPAT`
- Updated repository URL in help section

### Fixed
- `restore_backup()` now handles missing CSV file gracefully
- Safety backup in `restore_backup()` only created if CSV exists
- Fixed email in CONTRIBUTING.md

## [4.0.0] - 2025-11-29

### Added
- CLI argument parsing (`--help`, `--version`, `--debug`, `--performance`)
- Performance metrics tracking with timers
- Single instance protection via PID file
- Stack trace in debug mode
- Retry logic for I/O operations with exponential backoff
- `--check-deps` command to verify dependencies
- `--init` command to initialize/repair system
- Enhanced error handling with `set -Eeuo pipefail`
- System status in main menu (student count, backup count)
- Caller information in debug logs

### Changed
- Increased `MAX_BACKUPS` from 5 to 10
- Improved student code validation (checks uniqueness during edit)
- Enhanced confirmation prompts (type "DELETE" instead of "yes")
- Better colorization in log viewer
- Optimized CSV parsing performance

### Fixed
- Race condition in `get_next_id` with proper `flock` usage
- CSV parsing edge cases (nested quotes, commas in fields)
- Control character handling in input sanitization
- Lock file cleanup on abnormal termination

## [3.0.0] - 2025-11-28

### Added
- RFC 4180 compliant CSV parsing using AWK FPAT
- Thread-safe operations with `flock`
- Atomic writes with retry mechanism
- XDG Base Directory compliance
- Advanced logging system
- Automatic backup rotation

### Changed
- Complete rewrite of CSV handling
- Improved validation functions
- Enhanced menu system with icons

### Fixed
- CSV parsing with special characters
- Concurrent access issues
- Backup file corruption

## [2.0.0] - 2025-11-27

### Added
- Color-coded UI
- Student code validation
- Email and phone validation
- Search functionality
- Statistics and reporting

### Changed
- Modular function structure
- Improved error messages

## [1.0.0] - 2025-11-26

### Added
- Initial release
- Basic CRUD operations
- CSV storage
- Simple menu system
