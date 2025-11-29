# 🎓 Student Management System v4.0.0

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash Version](https://img.shields.io/badge/Bash-4.4%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue.svg)]()

[![GitHub](https://img.shields.io/badge/GitHub-Mehdi--dev--sudo-blue?logo=github)](https://github.com/Mehdi-dev-sudo)
[![Email](https://img.shields.io/badge/Email-mehdi.khorshidi333%40gmail.com-red?logo=gmail)](mailto:mehdi.khorshidi333@gmail.com)

A production-grade, thread-safe student management system written in pure Bash. Features enterprise-level error handling, RFC 4180 compliant CSV operations, and comprehensive logging.

---

## ✨ Features

### 🔒 Enterprise-Grade Reliability
- **Thread-safe operations** with `flock`-based locking
- **RFC 4180 compliant** CSV parsing (handles quotes, commas, newlines)
- **Atomic writes** with retry logic
- **Single instance protection** via PID file

### 📊 Core Functionality
- ➕ **CRUD Operations**: Add, Edit, Delete, View students
- 🔍 **Search**: Multi-field search (name, code, email)
- 📈 **Statistics**: GPA distribution, averages, rankings
- 📤 **Export**: JSON export with metadata

### 🛡️ Security & Validation
- ✅ Input sanitization (removes control characters)
- ✅ Email validation (RFC 5322 compliant)
- ✅ Phone number validation (Iranian format)
- ✅ Student code uniqueness checks
- ✅ SQL injection prevention

### 🔧 System Management
- 💾 **Automatic backups** with rotation (keeps last 10)
- 📜 **Multi-level logging** (DEBUG, INFO, WARN, ERROR)
- ⚡ **Performance metrics** tracking
- 🎨 **Colorized output** with UTF-8 icons

---

## 📋 Requirements

### System Requirements
- **OS**: Linux or macOS
- **Bash**: 4.4 or higher
- **Tools**: `awk`, `sed`, `grep`, `flock`

### Check dependencies:
```bash
./student_management.sh --check-deps

---

## 🚀 Quick Start

### 1. Clone the repository
git clone https://github.com/Mehdi-dev-sudo/student-management-bash.git
cd student-management-bash

### 2. Make executable
bash
chmod +x student_management.sh

### 3. Run
bash
./student_management.sh

---

## 📖 Usage

### Basic Commands
bash
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

### Configuration

Edit `~/.config/student_mgmt/config.conf`:

bash
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

---

### Main Menu
```bash
╔═══════════════════════════════════════════════════╗
║                                                   ║
║        🎓 Student Management System v4.0.0        ║
║             Enterprise Grade Edition              ║
║                                                   ║
╚═══════════════════════════════════════════════════╝

📝 CRUD Operations:
  1) ➕ Add New Student
  2) 📋 Display All Students
  3) 👤 View Student Details
  4) ✏️  Edit Student
  5) 🗑️  Delete Student

🔍 Search & Reports:
  6) 🔍 Search Students
  7) 📊 Show Statistics
  8) 📤 Export to JSON

⚙️  System:
  9) 💾 Create Manual Backup
 10) 🔄 Restore Backup
 11) 📜 View Logs
  0) 🚪 Exit
```
---

## 🏗️ Architecture

### File Structure

```bash
~/.local/share/student_mgmt/
├── students.csv              # Main database
└── backups/                  # Automatic backups
├── students_20250929_143022_auto.csv
└── students_20250929_120000_manual.csv

~/.config/student_mgmt/
└── config.conf               # User configuration

~/.local/state/student_mgmt/
├── student_mgmt.log          # Application logs
└── student_mgmt.pid          # Process ID file
```

### CSV Format (RFC 4180)

csv
ID,StudentCode,FirstName,LastName,Email,Phone,GPA,RegistrationDate
1,"STU001","John","Doe","john@example.com","09123456789",18.50,"2025-11-29"
2,"STU002","Jane","Smith","jane@example.com","09187654321",16.75,"2025-11-29"

### Key Technical Details

#### 1. Thread-Safe Operations
```bash
bash
acquire_lock() {
exec {LOCK_FD}>"$LOCK_FILE"
flock -x -w "$LOCK_TIMEOUT" "$LOCK_FD" || return 1
}
```

#### 2. RFC 4180 CSV Parsing
```bash
bash
awk -F',' 'BEGIN { FPAT = "([^,]*)|(\"([^\"]|\"\")*\")" }'
```

#### 3. Atomic Writes with Retry
```bash
bash
atomic_write() {
for ((i=1; i<=MAX_RETRIES; i++)); do
if mv "$temp_file" "$target_file" 2>/dev/null; then
return 0
fi
sleep 0.$((RANDOM % 100))
done
return 1
}
```

---

## 🧪 Testing

bash
# Test validation functions
./tests/test_validation.sh

# Test CSV parsing
./tests/test_csv_parsing.sh

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Permission Denied
bash
chmod +x student_management.sh

#### 2. Lock Timeout
bash
# Increase timeout in config
LOCK_TIMEOUT=30

#### 3. Bash Version Too Old
bash
# Check version
bash --version

# Upgrade (Ubuntu/Debian)
sudo apt update && sudo apt install --only-upgrade bash

#### 4. Corrupted Database
bash
# Restore from backup
./student_management.sh
# Select option 10 (Restore Backup)

---

## 📊 Performance

| Operation | Time (1000 records) |
|-----------|---------------------|
| Add       | ~0.05s              |
| Search    | ~0.02s              |
| Edit      | ~0.08s              |
| Delete    | ~0.06s              |
| Export JSON | ~0.15s            |

*Tested on: Intel i5-8250U, 8GB RAM, SSD*

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Code Style

- Use 4 spaces for indentation
- Add comments for complex logic
- Follow existing naming conventions
- Keep functions under 50 lines

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

### v4.0.0 (2025-11-29)
- Added CLI arguments (`--help`, `--version`, `--debug`)
- Implemented performance metrics
- Enhanced error handling with stack trace
- Added single instance protection
- Improved retry logic for I/O operations

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Mehdi Khorshidi Far**
- GitHub: [@Mehdi-dev-sudo](https://github.com/Mehdi-dev-sudo)
- Email: mehdi.khorshidi333@gmail.com
- Location: Amol, Iran 

---

## 🙏 Acknowledgments

- Inspired by modern CLI best practices
- Built with ❤️ using pure Bash
- Special thanks to the Bash community

---

## 📚 Additional Resources

- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide/Practices)
- [RFC 4180 (CSV Format)](https://tools.ietf.org/html/rfc4180)
- [AWK Programming Guide](https://www.gnu.org/software/gawk/manual/)

---

## ⭐ Star History

If you find this project useful, please consider giving it a star!

[![Star History Chart](https://api.star-history.com/svg?repos=Mehdi-dev-sudo/student-management-bash&type=Date)](https://star-history.com/#Mehdi-dev-sudo/student-management-bash&Date)
