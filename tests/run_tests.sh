#!/usr/bin/env bash
# Test runner for Student Management System
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

echo -e "\033[1;36m═══════════════════════════════════════════════════\033[0m"
echo -e "\033[1;36m  Student Management System - Test Suite\033[0m"
echo -e "\033[1;36m═══════════════════════════════════════════════════\033[0m"
echo ""

for test_file in "$SCRIPT_DIR"/test_*.sh; do
    test_name="$(basename "$test_file")"
    echo -e "\033[1mRunning: $test_name\033[0m"
    
    if bash "$test_file"; then
        echo -e "\033[0;32m  ✓ $test_name passed\033[0m\n"
        PASS=$((PASS + 1))
    else
        echo -e "\033[0;31m  ✗ $test_name failed\033[0m\n"
        FAIL=$((FAIL + 1))
    fi
done

echo -e "\033[1;36m═══════════════════════════════════════════════════\033[0m"
echo -e "Results: \033[0;32m$PASS passed\033[0m, \033[0;31m$FAIL failed\033[0m"
echo -e "\033[1;36m═══════════════════════════════════════════════════\033[0m"

[[ $FAIL -eq 0 ]] || exit 1
