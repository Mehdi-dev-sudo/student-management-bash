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
bash
git checkout -b feature

### 3. Make Changes
- Follow existing code style
- Add comments for complex logic
- Test thoroughly

### 4. Test
bash
# Run the script
./student_management.sh --debug

# Test edge cases
# - Empty database
# - Special characters in names
# - Concurrent operations

### 5. Commit
bash
git add .
git commit -m "feat: add your feature description"

**Commit Message Format:**
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation
- `refactor:` code refactoring
- `test:` adding tests
- `chore:` maintenance

### 6. Push & PR
bash
git push origin feature/your-feature-name

Then create a Pull Request on GitHub.

## Code Style

### Bash Style Guide
bash
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

### Function Template
bash
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

## Testing Checklist

- [ ] Script runs without errors
- [ ] All menu options work
- [ ] Input validation works correctly
- [ ] CSV handling preserves data integrity
- [ ] Backups are created successfully
- [ ] Logs are written correctly
- [ ] No race conditions in concurrent scenarios

## Questions?

Open an issue or contact: mehdi.khorshidi9339@gmail.com
