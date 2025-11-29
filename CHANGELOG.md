```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
