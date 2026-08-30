# Contributing to Student Management System

Thank you for your interest in contributing! 🎉

## Code of Conduct

Be respectful, inclusive, and professional.

## How to Contribute

### 1. Fork & Clone

```bash
git clone https://github.com/Mehdi-dev-sudo/student-management-bash.git
cd student-management-bash
```

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

### 3. Make Changes

- Follow existing code style
- Add comments for complex logic
- Test thoroughly
- Add tests for new features

### 4. Test

```bash
# Run the full test suite
./tests/run_tests.sh

# Run individual tests
./tests/test_validation.sh    # Validation functions
./tests/test_csv_parsing.sh   # CSV parsing functions
./tests/test_features.sh      # New v5.0 features

# Run the script in debug mode
./student_management.sh --debug

# Test bilingual support
./student_management.sh --lang fa
./student_management.sh --lang en
```

### 5. Commit

```bash
git add .
git commit -m "feat: add your feature description"
```

**Commit Message Format:**
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation
- `refactor:` code refactoring
- `test:` adding tests
- `chore:` maintenance
- `ui:` UI/UX improvements
- `i18n:` internationalization

### 6. Push & PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Code Style

### Bash Style Guide

```bash
# Use 4 spaces for indentation
function example() {
    local var="value"

    if [[ condition ]]; then
        echo "Good"
    fi
}

# Prefer [[ ]] over [ ]
# Use quotes around variables
# Use lowercase for local variables
# Use UPPERCASE for constants
```

### Function Template

```bash
# Brief description of what the function does
#
# Arguments:
#   $1 - First argument description
#   $2 - Second argument description
#
# Returns:
#   0 on success, 1 on failure
#
# Example:
#   my_function "arg1" "arg2"
my_function() {
    local arg1="$1"
    local arg2="$2"

    # Implementation
}
```

### UI Components

When adding new UI elements, use the existing component functions:

```bash
# Draw a box with title
draw_box "My Title" "$width"

# Print a menu item
print_menu_item "1" "➕" "My Feature"

# Print a section
print_section "My Section"

# Print a stat card
print_stat_card "Label" "Value" "📊" "$C_CYAN"
```

### Bilingual Support

When adding new user-facing strings:

1. Add English message to `MSG_EN` array
2. Add Persian message to `MSG_FA` array
3. Use `msg "key"` function to retrieve messages

```bash
# In the message arrays
declare -A MSG_EN=(
    ["my_feature"]="My Feature Description"
)

declare -A MSG_FA=(
    ["my_feature"]="توضیحات قابلیت من"
)

# In your function
echo "$(msg my_feature)"
```

## Testing Checklist

- [ ] Script runs without errors
- [ ] All menu options work
- [ ] Input validation works correctly
- [ ] CSV handling preserves data integrity
- [ ] Backups are created successfully
- [ ] Logs are written correctly
- [ ] No race conditions in concurrent scenarios
- [ ] Bilingual messages display correctly
- [ ] UI components render properly
- [ ] GPA Calculator works with edge cases
- [ ] CSV Import handles duplicates

## Project Structure

```
student-management-bash/
├── student_management.sh    # Main application
├── tests/
│   ├── run_tests.sh         # Test runner
│   ├── test_validation.sh   # Validation tests
│   ├── test_csv_parsing.sh  # CSV parsing tests
│   └── test_features.sh     # Feature tests
├── README.md               # Documentation
├── CHANGELOG.md            # Version history
├── CONTRIBUTING.md          # This file
├── LICENSE                  # MIT License
└── .gitignore              # Git ignore rules
```

## Questions?

Open an issue or contact: mehdi@code-watch.dev
