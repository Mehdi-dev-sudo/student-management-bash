# 🎓 Student Management System

A production-grade, thread-safe student management system written in pure Bash with bilingual support (English/Persian).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-5.0.0-cyan.svg)]()
[![Bash](https://img.shields.io/badge/Bash-4.4%2B-green.svg)]()

---

## Features

| Category | Feature |
|----------|---------|
| **CRUD** | Add, View, Edit, Delete students |
| **Search** | Multi-field case-insensitive search |
| **Import** | Batch CSV import with duplicate detection |
| **Export** | JSON & clean CSV export |
| **Analytics** | GPA statistics with visual charts |
| **Calculator** | Weighted GPA calculator |
| **Backup** | Auto backup with rotation & restore |
| **i18n** | English & Persian interface |
| **Logging** | Multi-level logging (DEBUG→ERROR) |

---

## Quick Start

```bash
# Clone & run
git clone https://github.com/Mehdi-dev-sudo/student-management-bash.git
cd student-management-bash
chmod +x student_management.sh
./student_management.sh

# Run in Persian
./student_management.sh --lang fa
```

---

## Commands

```
--help          Show help
--version       Show version
--debug         Enable debug mode
--performance   Enable performance metrics
--lang <en|fa>  Set language
--check-deps    Verify dependencies
--init          Initialize/repair system
--export-csv    Export to clean CSV
```

---

## Menu

```
┌─── CRUD Operations ──────────────┐
│  1) ➕ Add New Student            │
│  2) 📋 View All Students          │
│  3) 👤 View Details               │
│  4) ✏️  Edit Student               │
│  5) 🗑️  Delete Student            │
└───────────────────────────────────┘

┌─── Search & Reports ─────────────┐
│  6) 🔍 Search Students            │
│  7) 📊 Statistics & Analytics     │
│  8) 📤 Export to JSON             │
│  9) 📥 Import from CSV            │
│  10) 🧮 GPA Calculator            │
└───────────────────────────────────┘

┌─── System ───────────────────────┐
│  11) 💾 Create Backup             │
│  12) 🔄 Restore Backup            │
│  13) 📜 System Logs               │
│  14) ⚙️  Settings                  │
│  0)  🚪 Exit                      │
└───────────────────────────────────┘
```

---

## Configuration

Config file: `~/.config/student-mgmt/config`

```bash
MAX_BACKUPS=10          # Max backup files
LOCK_TIMEOUT=10        # Lock timeout (seconds)
MAX_RETRIES=3          # I/O retry attempts
LOG_LEVEL=INFO         # DEBUG, INFO, WARN, ERROR
LANG_MODE=en           # en or fa
```

---

## Testing

```bash
./tests/run_tests.sh        # Run all tests (120 tests)
./tests/test_validation.sh  # Validation functions
./tests/test_csv_parsing.sh # CSV operations
./tests/test_features.sh    # New features
```

---

## Architecture

```
~/.local/share/student-mgmt/
├── students.csv       # Main database
├── backups/           # Auto backups
├── app.log            # Logs
└── .lock/             # Lock directory

~/.config/student-mgmt/
└── config             # User settings
```

---

## Author

**Mehdi Khorshidi Far** — [mehdi@code-watch.dev](mailto:mehdi@code-watch.dev)  
GitHub: [@Mehdi-dev-sudo](https://github.com/Mehdi-dev-sudo)

## License

MIT License — see [LICENSE](LICENSE) for details.
