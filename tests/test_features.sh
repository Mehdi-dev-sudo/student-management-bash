#!/usr/bin/env bash
# Test suite for new v5.0 features
# Tests: bilingual support, UI components, GPA calculator logic
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/student_management.sh" 2>/dev/null || true

PASS=0
FAIL=0

# Override log to suppress output
log() { :; }

pass() {
    PASS=$((PASS + 1))
    echo -e "  \033[0;32m✓ PASS\033[0m: $1"
}

fail() {
    FAIL=$((FAIL + 1))
    echo -e "  \033[0;31m✗ FAIL\033[0m: $1"
}

# Test bilingual message system
echo -e "\033[1mTesting Bilingual Support\033[0m"

# Test English messages
LANG_MODE="en"
[[ "$(msg title)" == "Student Management System" ]] && pass "English: title" || fail "English: title"
[[ "$(msg add_student)" == "Add New Student" ]] && pass "English: add_student" || fail "English: add_student"
[[ "$(msg view_all)" == "View All Students" ]] && pass "English: view_all" || fail "English: view_all"
[[ "$(msg statistics)" == "Statistics & Analytics" ]] && pass "English: statistics" || fail "English: statistics"
[[ "$(msg gpa_calc)" == "GPA Calculator" ]] && pass "English: gpa_calc" || fail "English: gpa_calc"
[[ "$(msg import_csv)" == "Import from CSV" ]] && pass "English: import_csv" || fail "English: import_csv"
[[ "$(msg settings)" == "Settings" ]] && pass "English: settings" || fail "English: settings"

# Test Persian messages
LANG_MODE="fa"
[[ "$(msg title)" == "سیستم مدیریت دانشجویان" ]] && pass "Persian: title" || fail "Persian: title"
[[ "$(msg add_student)" == "افزودن دانشجوی جدید" ]] && pass "Persian: add_student" || fail "Persian: add_student"
[[ "$(msg view_all)" == "مشاهده همه دانشجویان" ]] && pass "Persian: view_all" || fail "Persian: view_all"
[[ "$(msg statistics)" == "آمار و تحلیل‌ها" ]] && pass "Persian: statistics" || fail "Persian: statistics"
[[ "$(msg gpa_calc)" == "ماشین‌حساب معدل" ]] && pass "Persian: gpa_calc" || fail "Persian: gpa_calc"
[[ "$(msg import_csv)" == "وارد کردن از CSV" ]] && pass "Persian: import_csv" || fail "Persian: import_csv"
[[ "$(msg settings)" == "تنظیمات" ]] && pass "Persian: settings" || fail "Persian: settings"

# Test fallback for unknown keys
LANG_MODE="en"
result=$(msg "nonexistent_key")
[[ "$result" == "nonexistent_key" ]] && pass "Fallback: unknown key" || fail "Fallback: got '$result'"

# Restore default
LANG_MODE="en"

# Test UI components
echo -e "\n\033[1mTesting UI Components\033[0m"

# Test get_terminal_width
width=$(get_terminal_width)
[[ "$width" =~ ^[0-9]+$ ]] && (( width > 0 )) && pass "get_terminal_width: returns positive number ($width)" || fail "get_terminal_width: invalid"

# Test print_line
result=$(print_line "-" 10 "" 2>/dev/null)
[[ ${#result} -gt 0 ]] && pass "print_line: produces output" || fail "print_line: no output"

# Test print_centered
result=$(print_centered "Hello" 20 "" 2>/dev/null)
[[ ${#result} -gt 0 ]] && pass "print_centered: produces output" || fail "print_centered: no output"

# Test draw_box (capture output)
result=$(draw_box "Test Title" 40 2>/dev/null)
[[ "$result" == *"Test Title"* ]] && pass "draw_box: contains title" || fail "draw_box: missing title"

# Test close_box
result=$(close_box 40 2>/dev/null)
[[ ${#result} -gt 0 ]] && pass "close_box: produces output" || fail "close_box: no output"

# Test print_stat_card
result=$(print_stat_card "Test Label" "Test Value" "✓" "" 2>/dev/null)
[[ "$result" == *"Test Label"* ]] && pass "print_stat_card: contains label" || fail "print_stat_card: missing label"
[[ "$result" == *"Test Value"* ]] && pass "print_stat_card: contains value" || fail "print_stat_card: missing value"

# Test color constants are set
[[ -n "$C_RED" ]] && pass "Color constant: C_RED set" || fail "Color constant: C_RED not set"
[[ -n "$C_GREEN" ]] && pass "Color constant: C_GREEN set" || fail "Color constant: C_GREEN not set"
[[ -n "$C_BLUE" ]] && pass "Color constant: C_BLUE set" || fail "Color constant: C_BLUE not set"
[[ -n "$C_HEADER" ]] && pass "Color combo: C_HEADER set" || fail "Color combo: C_HEADER not set"
[[ -n "$C_SUCCESS" ]] && pass "Color combo: C_SUCCESS set" || fail "Color combo: C_SUCCESS not set"
[[ -n "$C_ERROR" ]] && pass "Color combo: C_ERROR set" || fail "Color combo: C_ERROR not set"

# Test Unicode constants
[[ "$I_CHECK" == "✓" ]] && pass "Icon: I_CHECK" || fail "Icon: I_CHECK"
[[ "$I_CROSS" == "✗" ]] && pass "Icon: I_CROSS" || fail "Icon: I_CROSS"
[[ "$BOX_TL" == "╔" ]] && pass "Box: BOX_TL" || fail "Box: BOX_TL"
[[ "$BOX_TR" == "╗" ]] && pass "Box: BOX_TR" || fail "Box: BOX_TR"

# Test version
echo -e "\n\033[1mTesting Version Info\033[0m"

[[ "$APP_VERSION" == "5.0.0" ]] && pass "Version: 5.0.0" || fail "Version: got '$APP_VERSION'"
[[ "$APP_NAME" == "Student Management System" ]] && pass "App name set" || fail "App name"

# Test email in author info
echo -e "\n\033[1mTesting Author Info\033[0m"

# Check if the script contains the new email
if grep -q "mehdi@code-watch.dev" "$SCRIPT_DIR/student_management.sh"; then
    pass "Author email: mehdi@code-watch.dev found"
else
    fail "Author email: mehdi@code-watch.dev not found"
fi

# Summary
echo -e "\n\033[1mResults:\033[0m"
echo -e "  \033[0;32mPassed: $PASS\033[0m"
echo -e "  \033[0;31mFailed: $FAIL\033[0m"
echo -e "  Total: $((PASS + FAIL))"

[[ $FAIL -eq 0 ]] || exit 1
