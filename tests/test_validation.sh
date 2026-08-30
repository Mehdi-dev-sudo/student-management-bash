#!/usr/bin/env bash
# Test suite for Student Management System validation functions
# Version 5.0.0
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/student_management.sh" 2>/dev/null || {
    echo "Loading validation functions..."
}

PASS=0
FAIL=0

pass() {
    PASS=$((PASS + 1))
    echo -e "  \033[0;32m✓ PASS\033[0m: $1"
}

fail() {
    FAIL=$((FAIL + 1))
    echo -e "  \033[0;31m✗ FAIL\033[0m: $1"
}

# Override log to suppress output during tests
log() { :; }

# Test validate_gpa
echo -e "\033[1mTesting validate_gpa()\033[0m"

# Valid GPAs
validate_gpa "0" && pass "GPA: 0 (valid)" || fail "GPA: 0 (should be valid)"
validate_gpa "20" && pass "GPA: 20 (valid)" || fail "GPA: 20 (should be valid)"
validate_gpa "15.5" && pass "GPA: 15.5 (valid)" || fail "GPA: 15.5 (should be valid)"
validate_gpa "18.75" && pass "GPA: 18.75 (valid)" || fail "GPA: 18.75 (should be valid)"
validate_gpa "10" && pass "GPA: 10 (valid)" || fail "GPA: 10 (should be valid)"
validate_gpa "0.0" && pass "GPA: 0.0 (valid)" || fail "GPA: 0.0 (should be valid)"
validate_gpa "20.0" && pass "GPA: 20.0 (valid)" || fail "GPA: 20.0 (should be valid)"
validate_gpa "19.99" && pass "GPA: 19.99 (valid)" || fail "GPA: 19.99 (should be valid)"

# Invalid GPAs
validate_gpa "-1" && fail "GPA: -1 (should be invalid)" || pass "GPA: -1 (invalid)"
validate_gpa "21" && fail "GPA: 21 (should be invalid)" || pass "GPA: 21 (invalid)"
validate_gpa "abc" && fail "GPA: abc (should be invalid)" || pass "GPA: abc (invalid)"
validate_gpa "15.555" && fail "GPA: 15.555 (should be invalid)" || pass "GPA: 15.555 (invalid)"
validate_gpa "" && fail "GPA: empty (should be invalid)" || pass "GPA: empty (invalid)"
validate_gpa "-0.1" && fail "GPA: -0.1 (should be invalid)" || pass "GPA: -0.1 (invalid)"
validate_gpa "20.1" && fail "GPA: 20.1 (should be invalid)" || pass "GPA: 20.1 (invalid)"
validate_gpa "100" && fail "GPA: 100 (should be invalid)" || pass "GPA: 100 (invalid)"
validate_gpa "  15  " && fail "GPA: '  15  ' (should be invalid)" || pass "GPA: '  15  ' (invalid)"

# Test validate_email
echo -e "\n\033[1mTesting validate_email()\033[0m"

validate_email "user@example.com" && pass "Email: user@example.com (valid)" || fail "Email: user@example.com (should be valid)"
validate_email "user.name+tag@example.co.uk" && pass "Email: user.name+tag@example.co.uk (valid)" || fail "Email: user.name+tag@example.co.uk (should be valid)"
validate_email "test123@test.org" && pass "Email: test123@test.org (valid)" || fail "Email: test123@test.org (should be valid)"
validate_email "mehdi@code-watch.dev" && pass "Email: mehdi@code-watch.dev (valid)" || fail "Email: mehdi@code-watch.dev (should be valid)"
validate_email "" && fail "Email: empty (should be invalid)" || pass "Email: empty (invalid)"
validate_email "not-an-email" && fail "Email: not-an-email (should be invalid)" || pass "Email: not-an-email (invalid)"
validate_email "@example.com" && fail "Email: @example.com (should be invalid)" || pass "Email: @example.com (invalid)"
validate_email "user@" && fail "Email: user@ (should be invalid)" || pass "Email: user@ (invalid)"
validate_email "user@.com" && fail "Email: user@.com (should be invalid)" || pass "Email: user@.com (invalid)"
validate_email "user@com" && fail "Email: user@com (should be invalid)" || pass "Email: user@com (invalid)"

# Test validate_phone
echo -e "\n\033[1mTesting validate_phone()\033[0m"

validate_phone "09123456789" && pass "Phone: 09123456789 (valid)" || fail "Phone: 09123456789 (should be valid)"
validate_phone "02112345678" && pass "Phone: 02112345678 (valid)" || fail "Phone: 02112345678 (should be valid)"
validate_phone "0912 345 6789" && pass "Phone: 0912 345 6789 (valid)" || fail "Phone: 0912 345 6789 (should be valid)"
validate_phone "0912-345-6789" && pass "Phone: 0912-345-6789 (valid)" || fail "Phone: 0912-345-6789 (should be valid)"
validate_phone "09351234567" && pass "Phone: 09351234567 (valid)" || fail "Phone: 09351234567 (should be valid)"
validate_phone "12345" && fail "Phone: 12345 (should be invalid)" || pass "Phone: 12345 (invalid)"
validate_phone "0912345678" && fail "Phone: 0912345678 (should be invalid)" || pass "Phone: 0912345678 (invalid)"
validate_phone "" && fail "Phone: empty (should be invalid)" || pass "Phone: empty (invalid)"
validate_phone "12345678901" && fail "Phone: 12345678901 (should be invalid)" || pass "Phone: 12345678901 (invalid)"
validate_phone "+98912345678" && fail "Phone: +98912345678 (should be invalid)" || pass "Phone: +98912345678 (invalid)"

# Test validate_student_code
echo -e "\n\033[1mTesting validate_student_code()\033[0m"

validate_student_code "12345678" && pass "Code: 12345678 (valid)" || fail "Code: 12345678 (should be valid)"
validate_student_code "1234567890" && pass "Code: 1234567890 (valid)" || fail "Code: 1234567890 (should be valid)"
validate_student_code "123456789" && pass "Code: 123456789 (valid)" || fail "Code: 123456789 (should be valid)"
validate_student_code "12345" && fail "Code: 12345 (should be invalid)" || pass "Code: 12345 (invalid)"
validate_student_code "abc12345" && fail "Code: abc12345 (should be invalid)" || pass "Code: abc12345 (invalid)"
validate_student_code "" && fail "Code: empty (should be invalid)" || pass "Code: empty (invalid)"
validate_student_code "1234567" && fail "Code: 1234567 (should be invalid)" || pass "Code: 1234567 (invalid)"
validate_student_code "12345678901" && fail "Code: 12345678901 (should be invalid)" || pass "Code: 12345678901 (invalid)"

# Test sanitize_input
echo -e "\n\033[1mTesting sanitize_input()\033[0m"

result=$(sanitize_input "  hello  ")
[[ "$result" == "hello" ]] && pass "Trim: '  hello  ' -> 'hello'" || fail "Trim: got '$result'"
result=$(sanitize_input $'hello\x01world')
[[ "$result" == "helloworld" ]] && pass "Control chars: removed" || fail "Control chars: got '$result'"
result=$(sanitize_input "")
[[ -z "$result" ]] && pass "Empty: returns empty" || fail "Empty: got '$result'"
result=$(sanitize_input "  test 123  ")
[[ "$result" == "test 123" ]] && pass "Trim with numbers: '  test 123  ' -> 'test 123'" || fail "Trim with numbers: got '$result'"
result=$(sanitize_input "normal text")
[[ "$result" == "normal text" ]] && pass "Normal text: unchanged" || fail "Normal text: got '$result'"
result=$(sanitize_input $'\x02test\x03')
[[ "$result" == "test" ]] && pass "Multiple control chars: removed" || fail "Multiple control chars: got '$result'"

# Test msg function (language support)
echo -e "\n\033[1mTesting msg() (bilingual support)\033[0m"

LANG_MODE="en"
result=$(msg "title")
[[ "$result" == "Student Management System" ]] && pass "msg EN: title" || fail "msg EN: title got '$result'"

LANG_MODE="fa"
result=$(msg "title")
[[ "$result" == "سیستم مدیریت دانشجویان" ]] && pass "msg FA: title" || fail "msg FA: title got '$result'"

LANG_MODE="en"
result=$(msg "add_student")
[[ "$result" == "Add New Student" ]] && pass "msg EN: add_student" || fail "msg EN: add_student got '$result'"

LANG_MODE="fa"
result=$(msg "add_student")
[[ "$result" == "افزودن دانشجوی جدید" ]] && pass "msg FA: add_student" || fail "msg FA: add_student got '$result'"

# Summary
echo -e "\n\033[1mResults:\033[0m"
echo -e "  \033[0;32mPassed: $PASS\033[0m"
echo -e "  \033[0;31mFailed: $FAIL\033[0m"
echo -e "  Total: $((PASS + FAIL))"

[[ $FAIL -eq 0 ]] || exit 1
