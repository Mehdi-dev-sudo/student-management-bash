# 🎓 Student Management System v5.0.0

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash Version](https://img.shields.io/badge/Bash-4.4%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue.svg)]()
[![Version](https://img.shields.io/badge/Version-5.0.0-cyan.svg)]()

[![GitHub](https://img.shields.io/badge/GitHub-Mehdi--dev--sudo-blue?logo=github)](https://github.com/Mehdi-dev-sudo)
[![Email](https://img.shields.io/badge/Email-mehdi%40code--watch.dev-red?logo=gmail)](mailto:mehdi@code-watch.dev)

> A production-grade, thread-safe student management system written in pure Bash. Features enterprise-level error handling, RFC 4180 compliant CSV operations, bilingual support, and a professional terminal UI with charts and visual indicators.

---

## ✨ Features

### 🔒 Enterprise-Grade Reliability
- **Thread-safe operations** with directory-based locking
- **RFC 4180 compliant** CSV parsing (handles quotes, commas, newlines)
- **Atomic writes** with retry logic
- **Single instance protection** via PID file
- **POSIX-compatible** (no GNU-specific dependencies)

### 📊 Core Functionality
- ➕ **CRUD Operations**: Add, Edit, Delete, View students
- 🔍 **Search**: Multi-field case-insensitive search (name, code, email)
- 📈 **Statistics**: GPA distribution with visual charts, averages, rankings
- 📤 **Export**: JSON and clean CSV export with metadata
- 📥 **Import**: Batch CSV import with duplicate detection
- 🧮 **GPA Calculator**: Weighted GPA calculation with visual feedback

### 🌐 Bilingual Support
- 🇺🇸 **English** interface
- 🇮🇷 **فارسی (Persian)** interface
- Easy language switching from settings menu
- Command-line language selection: `--lang fa`

### 🎨 Professional Terminal UI
- **Box drawing characters** for clean layout
- **Color-coded GPA** indicators (green/yellow/red)
- **Visual progress bars** for statistics
- **Professional menu system** with icons and descriptions
- **Status bar** showing system health
- **Section headers** with visual separators

### 🛡️ Security & Validation
- ✅ Input sanitization (removes control characters)
- ✅ Email validation (RFC 5322 compliant)
- ✅ Phone number validation (Iranian format)
- ✅ Student code uniqueness checks (8-10 digits)
- ✅ GPA validation (0-20 range)

### 🔧 System Management
- 💾 **Automatic backups** with rotation (keeps last 10)
- 📜 **Multi-level logging** (DEBUG, INFO, WARN, ERROR)
- ⚡ **Performance metrics** tracking
- 🔄 **Backup restore** with safety snapshot
- ⚙️ **Settings menu** for runtime configuration

---

## 📋 Requirements

### System Requirements
- **OS**: Linux or macOS
- **Bash**: 4.4 or higher
- **Tools**: `awk`, `sed`, `grep`, `flock` (util-linux)

### Check dependencies:
```bash
./student_management.sh --check-deps
```

---

## 🚀 Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/Mehdi-dev-sudo/student-management-bash.git
cd student-management-bash
```

### 2. Make executable
```bash
chmod +x student_management.sh
chmod +x tests/run_tests.sh
```

### 3. Run
```bash
./student_management.sh
```

### 4. Run in Persian
```bash
./student_management.sh --lang fa
```

### 5. Run tests
```bash
./tests/run_tests.sh
```

---

## 📖 Usage

### Basic Commands
```bash
# Run normally
./student_management.sh

# Show help
./student_management.sh --help

# Show version
./student_management.sh --version

# Enable debug mode
./student_management.sh --debug

# Enable performance metrics
./student_management.sh --performance

# Set language to Persian
./student_management.sh --lang fa

# Set language to English
./student_management.sh --lang en

# Export database to clean CSV
./student_management.sh --export-csv

# Check dependencies
./student_management.sh --check-deps

# Initialize/repair system directories
./student_management.sh --init
```

### Configuration

Edit `~/.config/student-mgmt/config`:

```bash
# Maximum number of backups to keep
MAX_BACKUPS=10

# Lock timeout in seconds
LOCK_TIMEOUT=10

# Maximum retry attempts for I/O operations
MAX_RETRIES=3

# Logging level (DEBUG, INFO, WARN, ERROR)
LOG_LEVEL=INFO

# Enable performance metrics
ENABLE_PERFORMANCE_METRICS=false

# Language mode (en or fa)
LANG_MODE=en
```

---

### Main Menu

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║           🎓 Student Management System v5.0.0                                ║
║                    Professional Edition                                       ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

  🗄 Students: 0  |  🛡 Backups: 0  |  ⚡ Status: Healthy

┌─── CRUD Operations - Manage student records ───┐
                                                  │
  1) ➕ Add New Student                           │
  2) 📋 View All Students                         │
  3) 👤 View Student Details                      │
  4) ✏️  Edit Student                              │
  5) 🗑️  Delete Student                           │
└─────────────────────────────────────────────────┘

┌─── Search & Reports - Find and analyze data ───┐
                                                  │
  6) 🔍 Search Students                           │
  7) 📊 Statistics & Analytics                    │
  8) 📤 Export to JSON                            │
  9) 📥 Import from CSV                           │
  10) 🧮 GPA Calculator                           │
└─────────────────────────────────────────────────┘

┌─── System - Backup, logs, settings ────────────┐
                                                  │
  11) 💾 Create Manual Backup                     │
  12) 🔄 Restore Backup                           │
  13) 📜 System Logs                              │
  14) ⚙️  Settings                                 │
  0) 🚪 Exit                                      │
└─────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
  💡 Tip: Use --lang fa for Persian, --lang en for English
```

---

## 🏗️ Architecture

### File Structure

```
~/.local/share/student-mgmt/
├── students.csv              # Main database
└── backups/                  # Automatic backups
    ├── students_20250929_143022_auto.csv
    └── students_20250929_120000_manual.csv

~/.config/student-mgmt/
└── config                    # User configuration

~/.cache/student-mgmt/        # Cache directory
~/.local/share/student-mgmt/
├── app.log                   # Application logs
└── .lock/                    # Lock directory
```

### CSV Format (RFC 4180)

```csv
ID,StudentCode,FirstName,LastName,Email,Phone,GPA,RegistrationDate
1,STU001,John,Doe,john@example.com,09123456789,18.50,2025-11-29 14:30:22
2,STU002,Jane,Smith,jane@example.com,09187654321,16.75,2025-11-29 14:31:05
```

### Key Technical Details

#### 1. Thread-Safe Operations
```bash
acquire_lock() {
    while ! mkdir "$LOCK_FILE" 2>/dev/null; do
        sleep 1
    done
}
```

#### 2. RFC 4180 CSV Parsing
```bash
awk 'BEGIN { FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")" }'
```

#### 3. Atomic Writes with Retry
```bash
atomic_write() {
    local temp_file
    temp_file="$(mktemp "${target}.XXXXXX")"
    cat > "$temp_file" && mv "$temp_file" "$target"
}
```

#### 4. Bilingual Message System
```bash
declare -A MSG_EN=(
    ["title"]="Student Management System"
    ["add_student"]="Add New Student"
)

declare -A MSG_FA=(
    ["title"]="سیستم مدیریت دانشجویان"
    ["add_student"]="افزودن دانشجوی جدید"
)

msg() {
    local key="$1"
    if [[ "$LANG_MODE" == "fa" ]]; then
        echo "${MSG_FA[$key]:-$key}"
    else
        echo "${MSG_EN[$key]:-$key}"
    fi
}
```

---

## 🧪 Testing

```bash
# Run all tests
./tests/run_tests.sh

# Run individual test suites
./tests/test_validation.sh
./tests/test_csv_parsing.sh
./tests/test_features.sh
```

### Test Coverage

| Test Suite | Tests |
|-----------|-------|
| **Validation** | GPA, email, phone, student code, input sanitization, bilingual support |
| **CSV Parsing** | Escape, parse, roundtrip, special characters, Persian text, emoji |
| **Features** | Bilingual support, UI components, version info, author info |

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Permission Denied
```bash
chmod +x student_management.sh
```

#### 2. Lock Timeout
```bash
# Increase timeout in config
LOCK_TIMEOUT=30
```

#### 3. Bash Version Too Old
```bash
# Check version
bash --version

# Upgrade (Ubuntu/Debian)
sudo apt update && sudo apt install --only-upgrade bash
```

#### 4. Corrupted Database
```bash
# Restore from backup
./student_management.sh
# Select option 12 (Restore Backup)
```

---

## 📊 Performance

| Operation | Time (1000 records) |
|-----------|---------------------|
| Add | ~0.05s |
| Search | ~0.02s |
| Edit | ~0.08s |
| Delete | ~0.06s |
| Export JSON | ~0.15s |
| Import CSV | ~0.10s |

*Tested on: Intel i5-8250U, 8GB RAM, SSD*

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./tests/run_tests.sh`
5. Submit a pull request

### Code Style

- Use 4 spaces for indentation
- Follow existing naming conventions
- Keep functions focused on single responsibility
- Add tests for new features

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

### v5.0.0 (2026-08-30)
- ✨ Bilingual support (English/Persian)
- ✨ Professional terminal UI with box drawing and charts
- ✨ GPA Calculator with weighted calculation
- ✨ Batch CSV import with duplicate detection
- ✨ Settings menu for runtime configuration
- ✨ Visual progress bars and status indicators
- ✨ Color-coded GPA display
- ✨ Enhanced statistics with visual charts
- ✨ Comprehensive test suite (validation, CSV, features)
- 🔧 Improved code organization and documentation
- 🔧 Updated author email to mehdi@code-watch.dev

### v4.1.0 (2026-07-25)
- Unified locking mechanism
- POSIX-compatible backup operations
- Test suite with validation and CSV parsing tests
- Case-insensitive search
- Clean CSV export

### v4.0.0 (2025-11-29)
- CLI arguments
- Performance metrics
- Single instance protection

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Mehdi Khorshidi Far**

- GitHub: [@Mehdi-dev-sudo](https://github.com/Mehdi-dev-sudo)
- Email: [mehdi@code-watch.dev](mailto:mehdi@code-watch.dev)
- Location: Amol, Iran

---

## 🙏 Acknowledgments

- Inspired by modern CLI best practices
- Built with ❤️ using pure Bash
- Special thanks to the Bash community

---

## 📚 Additional Resources

- [Bash Best Practices](https://google.github.io/shellguide/)
- [RFC 4180 (CSV Format)](https://tools.ietf.org/html/rfc4180)
- [AWK Programming Guide](https://www.gnu.org/software/gawk/manual/)
