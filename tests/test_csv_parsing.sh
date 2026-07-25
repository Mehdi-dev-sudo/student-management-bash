#!/usr/bin/env bash
# Test suite for CSV parsing functions
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/student_management.sh" 2>/dev/null || true

PASS=0
FAIL=0

# Override log to suppress output
log() { :; }

pass() {
    ((PASS++))
    echo -e "  \033[0;32m✓ PASS\033[0m: $1"
}

fail() {
    ((FAIL++))
    echo -e "  \033[0;31m✗ FAIL\033[0m: $1"
}

echo -e "\033[1mTesting csv_escape()\033[0m"

result=$(csv_escape "simple")
[[ "$result" == "simple" ]] && pass "Simple text: 'simple'" || fail "Simple text: got '$result'"

result=$(csv_escape "has,comma")
[[ "$result" == '"has,comma"' ]] && pass "Text with comma: 'has,comma'" || fail "Text with comma: got '$result'"

result=$(csv_escape 'has"quote')
[[ "$result" == '"has""quote"' ]] && pass 'Text with quote: has"quote' || fail "Text with quote: got '$result'"

result=$(csv_escape 'both, and "quote"')
[[ "$result" == '"both, and ""quote"""' ]] && pass 'Complex: both, and "quote"' || fail "Complex: got '$result'"

result=$(csv_escape "")
[[ "$result" == "" ]] && pass "Empty string" || fail "Empty string: got '$result'"

echo -e "\n\033[1mTesting csv_parse_line()\033[0m"

result=$(csv_parse_line "1,abc,def,ghi" | tr '\n' ' ')
[[ "$result" == "1 abc def ghi " ]] && pass "Simple CSV: 1,abc,def,ghi" || fail "Simple CSV: got '$result'"

result=$(csv_parse_line '1,"has,comma",def' | tr '\n' ' ')
[[ "$result" == "1 has,comma def " ]] && pass "Quoted comma: 1,\"has,comma\",def" || fail "Quoted comma: got '$result'"

result=$(csv_parse_line '1,"has""quote",def' | tr '\n' ' ')
[[ "$result" == "1 has\"quote def " ]] && pass 'Quoted quote: 1,"has""quote",def' || fail "Quoted quote: got '$result'"

result=$(csv_parse_line "1,2,3" | tr '\n' ' ')
[[ "$result" == "1 2 3 " ]] && pass "Numeric fields: 1,2,3" || fail "Numeric fields: got '$result'"

# Multi-line field (CSV with newline in quoted field - unescaped content spans multiple lines)
result=$(csv_parse_line $'1,"line1\nline2",end' | awk 'END {print NR}')
# The 2nd field contains a newline, so output is 4 lines (field1, field2_line1, field2_line2, field3)
(( result == 4 )) && pass "Multi-line field: output has 4 lines" || fail "Multi-line field: got $result lines (expected 4)"

echo -e "\n\033[1mTesting get_csv_field()\033[0m"

result=$(get_csv_field "1,abc,def,ghi" 2)
[[ "$result" == "abc" ]] && pass "Field 2: 'abc'" || fail "Field 2: got '$result'"

result=$(get_csv_field '1,"has,comma",def' 2)
[[ "$result" == "has,comma" ]] && pass "Field 2 (quoted): 'has,comma'" || fail "Field 2 (quoted): got '$result'"

result=$(get_csv_field "1,2,3,4,5" 5)
[[ "$result" == "5" ]] && pass "Field 5: '5'" || fail "Field 5: got '$result'"

echo -e "\n\033[1mTesting CSV header parsing\033[0m"

header="ID,StudentCode,FirstName,LastName,Email,Phone,GPA,RegistrationDate"
result=$(csv_parse_line "$header" | tr '\n' ' ')
for field in ID StudentCode FirstName LastName Email Phone GPA RegistrationDate; do
    if [[ "$result" == *"$field"* ]]; then
        pass "Header contains '$field'"
    else
        fail "Header missing '$field'"
    fi
done

# Summary
echo -e "\n\033[1mResults:\033[0m"
echo -e "  \033[0;32mPassed: $PASS\033[0m"
echo -e "  \033[0;31mFailed: $FAIL\033[0m"
echo -e "  Total: $((PASS + FAIL))"

[[ $FAIL -eq 0 ]] || exit 1
