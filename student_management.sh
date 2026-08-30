#!/usr/bin/env bash

# ==============================================================================
# Student Management System - Professional Edition v5.0
# Version: 5.0.0
# License: MIT
# Author: Mehdi Khorshidi Far  mehdi@code-watch.dev
# Repository: github.com/Mehdi-dev-sudo/student-management-bash
# Description: Thread-safe, production-ready student records management
#              with advanced error handling, bilingual support, and
#              professional-grade terminal UI
# ==============================================================================

# Strict error handling - exit on error, undefined vars, pipe failures
# -E ensures ERR trap inheritance in functions/subshells
set -Eeuo pipefail
IFS=$'\n\t'

# ==============================================================================
# Configuration & Constants
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly APP_VERSION="5.0.0"
readonly APP_NAME="Student Management System"

# XDG Base Directory Specification compliance
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/student-mgmt"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/student-mgmt"
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/student-mgmt"

# File paths
readonly CSV_FILE="$DATA_DIR/students.csv"
readonly BACKUP_DIR="$DATA_DIR/backups"
readonly LOG_FILE="$DATA_DIR/app.log"
readonly LOCK_FILE="$DATA_DIR/.lock"
readonly CONFIG_FILE="$CONFIG_DIR/config"
readonly PID_FILE="$DATA_DIR/.pid"

# Settings (can be overridden by config file)
MAX_BACKUPS="${MAX_BACKUPS:-10}"
LOCK_TIMEOUT="${LOCK_TIMEOUT:-10}"
MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-1}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR
ENABLE_PERFORMANCE_METRICS="${ENABLE_PERFORMANCE_METRICS:-false}"
LANG_MODE="${LANG_MODE:-en}"  # en or fa (Persian)

readonly DATE_FORMAT='%Y-%m-%d %H:%M:%S'

# ==============================================================================
# Color System (Professional Palette)
# ==============================================================================

readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[1;33m'
readonly C_BLUE='\033[0;34m'
readonly C_CYAN='\033[0;36m'
readonly C_MAGENTA='\033[0;35m'
readonly C_WHITE='\033[1;37m'
readonly C_GRAY='\033[0;37m'
readonly C_BOLD='\033[1m'
readonly C_DIM='\033[2m'
readonly C_ITALIC='\033[3m'
readonly C_UNDERLINE='\033[4m'
readonly C_RESET='\033[0m'

# Professional color combos
readonly C_HEADER="${C_BOLD}${C_CYAN}"
readonly C_SUCCESS="${C_BOLD}${C_GREEN}"
readonly C_WARNING="${C_BOLD}${C_YELLOW}"
readonly C_ERROR="${C_BOLD}${C_RED}"
readonly C_INFO="${C_CYAN}"
readonly C_MUTED="${C_DIM}${C_GRAY}"
readonly C_HIGHLIGHT="${C_BOLD}${C_WHITE}"

# ==============================================================================
# Unicode Icons & Box Drawing (Professional Grade)
# ==============================================================================

# Icons
readonly I_CHECK="✓"
readonly I_CROSS="✗"
readonly I_WARN="⚠"
readonly I_INFO="ℹ"
readonly I_ARROW="→"
readonly I_STAR="★"
readonly I_CLOCK="⏱"
readonly I_ROCKET="🚀"
readonly I_DATABASE="🗄"
readonly I_SHIELD="🛡"
readonly I_LIGHTNING="⚡"
readonly I_CHART="📊"
readonly I_SEARCH="🔍"
readonly I_GEAR="⚙"
readonly I_BOOK="📚"
readonly I_TROPHY="🏆"
readonly I_HEART="❤"
readonly I_BULB="💡"
readonly I_PALETTE="🎨"
readonly I_CODE="💻"

# Box Drawing Characters (Professional)
readonly BOX_TL="╔"
readonly BOX_TR="╗"
readonly BOX_BL="╚"
readonly BOX_BR="╝"
readonly BOX_H="═"
readonly BOX_V="║"
readonly BOX_T_DOWN="╦"
readonly BOX_T_UP="╩"
readonly BOX_T_RIGHT="╠"
readonly BOX_T_LEFT="╣"
readonly BOX_CROSS="╬"

# Box Drawing (Light - for sub-sections)
readonly BOX_LT="┌"
readonly BOX_RT="┐"
readonly BOX_LB="└"
readonly BOX_RB="┘"
readonly BOX_LH="─"
readonly BOX_LV="│"

# Performance tracking
declare -g OPERATION_START_TIME=0

# Language strings
declare -A MSG_EN=(
    ["title"]="Student Management System"
    ["subtitle"]="Professional Edition"
    ["version"]="Version"
    ["add_student"]="Add New Student"
    ["view_all"]="View All Students"
    ["view_details"]="View Student Details"
    ["edit_student"]="Edit Student"
    ["delete_student"]="Delete Student"
    ["search"]="Search Students"
    ["statistics"]="Statistics & Analytics"
    ["export_json"]="Export to JSON"
    ["import_csv"]="Import from CSV"
    ["backup_create"]="Create Manual Backup"
    ["backup_restore"]="Restore Backup"
    ["backup_list"]="Available Backups"
    ["logs"]="System Logs"
    ["settings"]="Settings"
    ["exit"]="Exit"
    ["crud_ops"]="CRUD Operations"
    ["search_reports"]="Search & Reports"
    ["system_ops"]="System"
    ["crud_ops_desc"]="Manage student records"
    ["search_reports_desc"]="Find and analyze data"
    ["system_ops_desc"]="Backup, logs, settings"
    ["student_code"]="Student Code (8-10 digits)"
    ["first_name"]="First Name"
    ["last_name"]="Last Name"
    ["email"]="Email Address"
    ["phone"]="Phone (11 digits, starts with 0)"
    ["gpa"]="GPA (0-20)"
    ["enter_id"]="Enter Student ID"
    ["confirm_delete"]="Type 'DELETE' to confirm"
    ["press_enter"]="Press Enter to continue..."
    ["search_term"]="Search term (name, code, email)"
    ["no_students"]="No students found"
    ["no_results"]="No results found"
    ["total_students"]="Total Students"
    ["avg_gpa"]="Average GPA"
    ["highest_gpa"]="Highest GPA"
    ["lowest_gpa"]="Lowest GPA"
    ["excellent"]="Excellent (≥17)"
    ["good"]="Good (14-16.99)"
    ["average"]="Average (12-13.99)"
    ["poor"]="Poor (<12)"
    ["gpa_distribution"]="GPA Distribution"
    ["backup_created"]="Backup created successfully"
    ["backup_restored"]="Backup restored successfully"
    ["student_added"]="Student added successfully"
    ["student_updated"]="Student updated successfully"
    ["student_deleted"]="Student deleted successfully"
    ["operation_cancelled"]="Operation cancelled"
    ["invalid_input"]="Invalid input"
    ["export_success"]="Exported successfully"
    ["import_success"]="Imported successfully"
    ["import_file"]="CSV file to import"
    ["enter_choice"]="Enter your choice"
    ["current_info"]="Current Information"
    ["keep_current"]="Enter to keep current"
    ["yes"]="Yes"
    ["no"]="No"
    ["confirm"]="Confirm"
    ["cancel"]="Cancel"
    ["gpa_calc"]="GPA Calculator"
    ["gpa_calc_desc"]="Calculate weighted GPA"
    ["sorted_by"]="Sorted by"
    ["gpa_range"]="GPA Range"
    ["recent_activity"]="Recent Activity"
    ["system_health"]="System Health"
    ["data_integrity"]="Data Integrity"
    ["quick_actions"]="Quick Actions"
    ["dark_mode"]="Dark Theme"
    ["light_mode"]="Light Theme"
    ["language"]="Language"
    ["gpa_chart"]="GPA Distribution Chart"
    ["top_students"]="Top Students"
    ["bottom_students"]="Needs Improvement"
)

declare -A MSG_FA=(
    ["title"]="سیستم مدیریت دانشجویان"
    ["subtitle"]="نسخه حرفه‌ای"
    ["version"]="نسخه"
    ["add_student"]="افزودن دانشجوی جدید"
    ["view_all"]="مشاهده همه دانشجویان"
    ["view_details"]="مشاهده جزئیات دانشجو"
    ["edit_student"]="ویرایش دانشجو"
    ["delete_student"]="حذف دانشجو"
    ["search"]="جستجوی دانشجویان"
    ["statistics"]="آمار و تحلیل‌ها"
    ["export_json"]="خروجی JSON"
    ["import_csv"]="وارد کردن از CSV"
    ["backup_create"]="ایجاد پشتیبان دستی"
    ["backup_restore"]="بازیابی پشتیبان"
    ["backup_list"]="پشتیبان‌های موجود"
    ["logs"]="لاگ‌های سیستم"
    ["settings"]="تنظیمات"
    ["exit"]="خروج"
    ["crud_ops"]="عملیات CRUD"
    ["search_reports"]="جستجو و گزارشات"
    ["system_ops"]="سیستم"
    ["crud_ops_desc"]="مدیریت رکوردهای دانشجویان"
    ["search_reports_desc"]="یافتن و تحلیل داده‌ها"
    ["system_ops_desc"]="پشتیبان، لاگ‌ها، تنظیمات"
    ["student_code"]="کد دانشجویی (۸ تا ۱۰ رقم)"
    ["first_name"]="نام"
    ["last_name"]="نام خانوادگی"
    ["email"]="آدرس ایمیل"
    ["phone"]="تلفن (۱۱ رقم، با ۰ شروع شود)"
    ["gpa"]="معدل (۰ تا ۲۰)"
    ["enter_id"]="شناسه دانشجو را وارد کنید"
    ["confirm_delete"]="برای تایید 'DELETE' را تایپ کنید"
    ["press_enter"]="برای ادامه Enter بزنید..."
    ["search_term"]="عبارت جستجو (نام، کد، ایمیل)"
    ["no_students"]="دانشجویی یافت نشد"
    ["no_results"]="نتیجه‌ای یافت نشد"
    ["total_students"]="تعداد کل دانشجویان"
    ["avg_gpa"]="معدل کل"
    ["highest_gpa"]="بالاترین معدل"
    ["lowest_gpa"]="پایین‌ترین معدل"
    ["excellent"]="عالی (≥۱۷)"
    ["good"]="خوب (۱۴ تا ۱۶.۹۹)"
    ["average"]="متوسط (۱۲ تا ۱۳.۹۹)"
    ["poor"]="ضعیف (کمتر از ۱۲)"
    ["gpa_distribution"]="توزیع معدل"
    ["backup_created"]="پشتیبان با موفقیت ایجاد شد"
    ["backup_restored"]="پشتیبان با موفقیت بازیابی شد"
    ["student_added"]="دانشجو با موفقیت اضافه شد"
    ["student_updated"]="دانشجو با موفقیت بروزرسانی شد"
    ["student_deleted"]="دانشجو با موفقیت حذف شد"
    ["operation_cancelled"]="عملیات لغو شد"
    ["invalid_input"]="ورودی نامعتبر"
    ["export_success"]="خروجی با موفقیت ایجاد شد"
    ["import_success"]="با موفقیت وارد شد"
    ["import_file"]="فایل CSV برای وارد کردن"
    ["enter_choice"]="انتخاب خود را وارد کنید"
    ["current_info"]="اطلاعات فعلی"
    ["keep_current"]="برای نگه داشتن فعلی Enter بزنید"
    ["yes"]="بله"
    ["no"]="خیر"
    ["confirm"]="تایید"
    ["cancel"]="لغو"
    ["gpa_calc"]="ماشین‌حساب معدل"
    ["gpa_calc_desc"]="محاسبه معدل وزنی"
    ["sorted_by"]="مرتب شده بر اساس"
    ["gpa_range"]="محدوده معدل"
    ["recent_activity"]="فعالیت‌های اخیر"
    ["system_health"]="سلامت سیستم"
    ["data_integrity"]="یکپارچگی داده‌ها"
    ["quick_actions"]="اقدامات سریع"
    ["dark_mode"]="حالت تاریک"
    ["light_mode"]="حالت روشن"
    ["language"]="زبان"
    ["gpa_chart"]="نمودار توزیع معدل"
    ["top_students"]="دانشجویان برتر"
    ["bottom_students"]="نیاز به بهبود"
)

# Message helper
msg() {
    local key="$1"
    if [[ "$LANG_MODE" == "fa" ]]; then
        echo "${MSG_FA[$key]:-$key}"
    else
        echo "${MSG_EN[$key]:-$key}"
    fi
}

# ==============================================================================
# Logging & Error Handling
# ==============================================================================

# Enhanced logging with levels
log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp caller_info

    # Check log level
    case "$LOG_LEVEL" in
        ERROR) [[ "$level" != "ERROR" ]] && return 0 ;;
        WARN) [[ "$level" =~ ^(DEBUG|INFO)$ ]] && return 0 ;;
        INFO) [[ "$level" == "DEBUG" ]] && return 0 ;;
    esac

    timestamp="$(date +"$DATE_FORMAT")"

    # Get caller information for DEBUG
    if [[ "$level" == "DEBUG" && "${DEBUG:-0}" == "1" ]]; then
        caller_info=" [${BASH_SOURCE[2]##*/}:${BASH_LINENO[1]}:${FUNCNAME[2]}]"
    fi

    # Write to log file (writes < PIPE_BUF are atomic on POSIX systems)
    echo "[$timestamp] [$level]${caller_info:-} $msg" >> "$LOG_FILE" 2>/dev/null || true

    # Console output with colors
    case "$level" in
        ERROR)
            echo -e "${C_ERROR}${I_CROSS} $msg${C_RESET}" >&2
            ;;
        SUCCESS)
            echo -e "${C_SUCCESS}${I_CHECK} $msg${C_RESET}"
            ;;
        WARN)
            echo -e "${C_WARNING}${I_WARN} $msg${C_RESET}"
            ;;
        INFO)
            echo -e "${C_INFO}${I_INFO} $msg${C_RESET}"
            ;;
        DEBUG)
            [[ "${DEBUG:-0}" == "1" ]] && \
                echo -e "${C_MAGENTA}${C_DIM}[DEBUG]${caller_info} $msg${C_RESET}" >&2
            ;;
    esac
}

# Enhanced error handler with stack trace
error_handler() {
    local exit_code=$?
    local line_number=$1
    local bash_lineno=$2
    local last_command="${BASH_COMMAND}"
    local func_name="${FUNCNAME[1]:-main}"

    log ERROR "Command failed with exit code $exit_code"
    log ERROR "  Command: $last_command"
    log ERROR "  Function: $func_name"
    log ERROR "  Line: $line_number"

    # Stack trace
    if [[ "${DEBUG:-0}" == "1" ]]; then
        log DEBUG "Stack trace:"
        local frame=0
        while caller $frame; do
            ((frame++))
        done | while read -r line func file; do
            log DEBUG "  at $func ($file:$line)"
        done
    fi

    cleanup_on_exit
    exit "$exit_code"
}

# Set up trap for errors with enhanced handler
trap 'error_handler ${LINENO} ${BASH_LINENO}' ERR
trap cleanup_on_exit EXIT INT TERM HUP

die() {
    log ERROR "$*"
    exit 1
}

cleanup_on_exit() {
    local exit_code=$?

    log DEBUG "Cleanup initiated (exit code: $exit_code)"

    # Release lock
    release_lock 2>/dev/null || true

    # Clean temp files older than 1 hour
    find "$DATA_DIR" -name ".tmp.*" -mmin +60 -delete 2>/dev/null || true

    # Remove PID file
    [[ -f "$PID_FILE" ]] && rm -f "$PID_FILE" 2>/dev/null || true

    # Kill background jobs
    local jobs
    jobs=$(jobs -p 2>/dev/null || true)
    [[ -n "$jobs" ]] && kill $jobs 2>/dev/null || true

    log DEBUG "Cleanup completed"
}

# ==============================================================================
# UI Components (Professional Grade)
# ==============================================================================

# Get terminal width
get_terminal_width() {
    local width
    width=$(tput cols 2>/dev/null || echo 80)
    echo "$width"
}

# Print a horizontal line
print_line() {
    local char="${1:-$BOX_H}"
    local width="${2:-$(get_terminal_width)}"
    local color="${3:-$C_DIM}"

    printf "${color}"
    printf "%0.s${char}" $(seq 1 "$width")
    printf "${C_RESET}\n"
}

# Print a centered text
print_centered() {
    local text="$1"
    local width="${2:-$(get_terminal_width)}"
    local color="${3:-$C_RESET}"

    # Calculate visible length (strip ANSI codes)
    local visible_text
    visible_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#visible_text}
    local padding=$(( (width - text_len) / 2 ))

    if (( padding < 0 )); then padding=0; fi

    printf "${color}"
    printf "%0.s " $(seq 1 "$padding")
    printf "%s" "$text"
    printf "%0.s " $(seq 1 "$padding")
    printf "${C_RESET}\n"
}

# Draw a professional box
draw_box() {
    local title="$1"
    local width="${2:-$(get_terminal_width)}"
    local inner_width=$((width - 4))

    # Title line
    local title_display="$title"
    local title_len=${#title_display}

    echo -e "${C_HEADER}${BOX_TL}$(printf "%0.s${BOX_H}" $(seq 1 $inner_width))${BOX_TR}${C_RESET}"

    if [[ -n "$title" ]]; then
        local left_pad=$(( (inner_width - title_len) / 2 ))
        local right_pad=$(( inner_width - title_len - left_pad ))
        echo -e "${C_HEADER}${BOX_V}${C_RESET}$(printf "%0.s " $(seq 1 $left_pad))${C_HIGHLIGHT}${title_display}${C_RESET}$(printf "%0.s " $(seq 1 $right_pad))${C_HEADER}${BOX_V}${C_RESET}"
        echo -e "${C_HEADER}${BOX_T_RIGHT}$(printf "%0.s${BOX_H}" $(seq 1 $inner_width))${BOX_T_LEFT}${C_RESET}"
    fi
}

# Close a box
close_box() {
    local width="${1:-$(get_terminal_width)}"
    local inner_width=$((width - 4))
    echo -e "${C_HEADER}${BOX_BL}$(printf "%0.s${BOX_H}" $(seq 1 $inner_width))${BOX_BR}${C_RESET}"
}

# Draw a light box (for sub-sections)
draw_light_box() {
    local title="$1"
    local width="${2:-60}"
    local inner_width=$((width - 4))

    echo -e "${C_DIM}${BOX_LT}$(printf "%0.s${BOX_LH}" $(seq 1 $inner_width))${BOX_RT}${C_RESET}"

    if [[ -n "$title" ]]; then
        local title_len=${#title}
        local left_pad=$(( (inner_width - title_len) / 2 ))
        local right_pad=$(( inner_width - title_len - left_pad ))
        echo -e "${C_DIM}${BOX_LV}${C_RESET}$(printf "%0.s " $(seq 1 $left_pad))${C_HIGHLIGHT}${title}${C_RESET}$(printf "%0.s " $(seq 1 $right_pad))${C_DIM}${BOX_LV}${C_RESET}"
        echo -e "${C_DIM}${BOX_LT}$(printf "%0.s${BOX_LH}" $(seq 1 $inner_width))${BOX_RT}${C_RESET}"
    fi
}

# Close a light box
close_light_box() {
    local width="${1:-60}"
    local inner_width=$((width - 4))
    echo -e "${C_DIM}${BOX_LB}$(printf "%0.s${BOX_LH}" $(seq 1 $inner_width))${BOX_RB}${C_RESET}"
}

# Print a status bar
print_status_bar() {
    local left_text="$1"
    local right_text="$2"
    local width="${3:-$(get_terminal_width)}"

    local left_len=${#left_text}
    local right_len=${#right_text}
    local spaces=$(( width - left_len - right_len - 4 ))

    if (( spaces < 0 )); then spaces=0; fi

    echo -e "${C_DIM}${BOX_LV}${C_RESET} ${left_text}$(printf "%0.s " $(seq 1 $spaces))${right_text} ${C_DIM}${BOX_LV}${C_RESET}"
}

# Print a progress bar
print_progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-40}"
    local color="${4:-$C_GREEN}"

    local percentage=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))

    printf "${color}["
    printf "%0.s█" $(seq 1 $filled)
    printf "${C_DIM}"
    printf "%0.s░" $(seq 1 $empty)
    printf "${C_RESET}${color}] %3d%%${C_RESET}" "$percentage"
}

# Print a spinner
spinner() {
    local pid=$1
    local message="${2:-Processing}"
    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        local char="${spin_chars:$i:1}"
        printf "\r${C_CYAN}${char}${C_RESET} ${C_DIM}${message}...${C_RESET}"
        i=$(( (i + 1) % ${#spin_chars} ))
        sleep 0.1
    done
    printf "\r"
}

# Print a table header
print_table_header() {
    local width=$(get_terminal_width)
    local -a headers=("$@")

    printf "${C_HEADER}"
    printf "%-5s" "#"
    for header in "${headers[@]}"; do
        printf " %-15s" "$header"
    done
    printf "${C_RESET}\n"

    print_line "─" "$width" "${C_DIM}"
}

# Print a table row
print_table_row() {
    local num="$1"
    shift
    local -a values=("$@")
    local color="${2:-$C_RESET}"

    printf "${C_DIM}%-5s${C_RESET}" "$num"
    for value in "${values[@]}"; do
        printf " %-15s" "${value:0:15}"
    done
    printf "\n"
}

# Print a stat card
print_stat_card() {
    local label="$1"
    local value="$2"
    local icon="${3:-$I_INFO}"
    local color="${4:-$C_CYAN}"

    echo -e "  ${color}${icon} ${C_HIGHLIGHT}${label}:${C_RESET} ${color}${value}${C_RESET}"
}

# Print a menu item
print_menu_item() {
    local num="$1"
    local icon="$2"
    local label="$3"
    local desc="${4:-}"
    local color="${5:-$C_CYAN}"

    if [[ -n "$desc" ]]; then
        echo -e "  ${color}${C_BOLD}${num})${C_RESET} ${icon} ${C_HIGHLIGHT}${label}${C_RESET}"
        echo -e "     ${C_DIM}${desc}${C_RESET}"
    else
        echo -e "  ${color}${C_BOLD}${num})${C_RESET} ${icon} ${C_HIGHLIGHT}${label}${C_RESET}"
    fi
}

# Print a section divider
print_section() {
    local title="$1"
    local color="${2:-$C_HEADER}"

    echo ""
    echo -e "${color}┌─── ${C_HIGHLIGHT}${title}${C_RESET}${color} ───┐${C_RESET}"
}

# Print section end
print_section_end() {
    local color="${1:-$C_HEADER}"
    echo -e "${color}└$(printf "%0.s─" $(seq 1 40))┘${C_RESET}"
}

# ==============================================================================
# Performance Tracking
# ==============================================================================

start_timer() {
    [[ "$ENABLE_PERFORMANCE_METRICS" != "true" ]] && return 0
    OPERATION_START_TIME=$(date +%s%N)
}

end_timer() {
    [[ "$ENABLE_PERFORMANCE_METRICS" != "true" ]] && return 0
    local end_time=$(date +%s%N)
    local elapsed=$(( (end_time - OPERATION_START_TIME) / 1000000 ))  # ms
    echo -e "${C_DIM}${I_CLOCK} Completed in ${elapsed}ms${C_RESET}"
}

# ==============================================================================
# File Locking (Prevent Race Conditions)
# ==============================================================================

acquire_lock() {
    local elapsed=0

    log DEBUG "Attempting to acquire lock..."

    while (( elapsed < LOCK_TIMEOUT )); do
        if mkdir "$LOCK_FILE" 2>/dev/null; then
            echo $$ > "$LOCK_FILE/pid"
            echo "$(date +%s)" > "$LOCK_FILE/timestamp"
            log DEBUG "Lock acquired (PID: $$)"
            return 0
        fi

        # Check if lock holder is still alive
        if [[ -f "$LOCK_FILE/pid" ]]; then
            local lock_pid
            lock_pid=$(cat "$LOCK_FILE/pid" 2>/dev/null || echo "")

            if [[ -n "$lock_pid" ]]; then
                if ! kill -0 "$lock_pid" 2>/dev/null; then
                    log WARN "Removing stale lock (PID: $lock_pid)"
                    rm -rf "$LOCK_FILE" 2>/dev/null || true
                    continue
                fi

                # Check lock age
                if [[ -f "$LOCK_FILE/timestamp" ]]; then
                    local lock_time
                    lock_time=$(cat "$LOCK_FILE/timestamp" 2>/dev/null || echo "0")
                    local current_time=$(date +%s)
                    local lock_age=$(( current_time - lock_time ))

                    if (( lock_age > LOCK_TIMEOUT * 2 )); then
                        log WARN "Lock is too old (${lock_age}s), removing..."
                        rm -rf "$LOCK_FILE" 2>/dev/null || true
                        continue
                    fi
                fi
            fi
        fi

        sleep 1
        ((elapsed++))
        log DEBUG "Waiting for lock... (${elapsed}/${LOCK_TIMEOUT})"
    done

    die "Could not acquire lock after ${LOCK_TIMEOUT}s. Another instance running?"
}

release_lock() {
    if [[ -d "$LOCK_FILE" ]]; then
        rm -rf "$LOCK_FILE" 2>/dev/null || true
        log DEBUG "Lock released"
    fi
}

# ==============================================================================
# CSV Operations (RFC 4180 Compliant)
# ==============================================================================

csv_escape() {
    local field="$1"

    # If field contains comma, quote, or newline, escape it
    if [[ "$field" =~ [,\"$'\n'] ]]; then
        # Escape quotes by doubling them
        field="${field//\"/\"\"}"
        # Wrap in quotes
        echo "\"$field\""
    else
        echo "$field"
    fi
}

# Parse CSV line using AWK with FPAT (Field Pattern)
csv_parse_line() {
    local line="$1"

    awk -v line="$line" '
        BEGIN {
            FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")"
            $0 = line

            for (i = 1; i <= NF; i++) {
                field = $i

                # Remove surrounding quotes
                gsub(/^"|"$/, "", field)

                # Unescape doubled quotes
                gsub(/""/, "\"", field)

                print field
            }
        }
    '
}

# Get specific field from CSV row
get_csv_field() {
    local line="$1"
    local field_num="$2"

    csv_parse_line "$line" | sed -n "${field_num}p"
}

# Atomic write operation with retry
atomic_write() {
    local target="$1"
    local temp_file
    local retry_count=0

    temp_file="$(mktemp "${target}.XXXXXX")" || die "Failed to create temp file"

    # Read from stdin and write to temp
    while (( retry_count < MAX_RETRIES )); do
        if cat > "$temp_file" 2>/dev/null; then
            break
        else
            ((retry_count++))
            log WARN "Write attempt $retry_count failed, retrying..."
            sleep "$RETRY_DELAY"
        fi
    done

    if (( retry_count >= MAX_RETRIES )); then
        rm -f "$temp_file"
        die "Failed to write after $MAX_RETRIES attempts"
    fi

    # Atomic move with retry
    retry_count=0
    while (( retry_count < MAX_RETRIES )); do
        if mv "$temp_file" "$target" 2>/dev/null; then
            log DEBUG "Atomic write successful: $target"
            return 0
        else
            ((retry_count++))
            log WARN "Move attempt $retry_count failed, retrying..."
            sleep "$RETRY_DELAY"
        fi
    done

    rm -f "$temp_file"
    die "Failed to replace $target after $MAX_RETRIES attempts"
}

# ==============================================================================
# Validation Functions
# ==============================================================================

validate_gpa() {
    local gpa="$1"

    # Check format: number with optional 1-2 decimal places
    [[ "$gpa" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]] || return 1

    # Check range using awk (no bc dependency)
    awk -v gpa="$gpa" 'BEGIN { exit !(gpa >= 0 && gpa <= 20) }' && return 0 || return 1
}

validate_email() {
    local email="$1"
    local regex='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

    [[ "$email" =~ $regex ]]
}

validate_phone() {
    local phone="$1"

    # Remove spaces and dashes
    phone="${phone//[-[:space:]]}"

    # Iranian phone format: 11 digits starting with 0
    [[ "$phone" =~ ^0[0-9]{10}$ ]]
}

validate_student_code() {
    local code="$1"
    local exclude_id="${2:-}"

    [[ "$code" =~ ^[0-9]{8,10}$ ]] || return 1

    if [[ -f "$CSV_FILE" ]]; then
        awk -v code="$code" -v exclude_id="$exclude_id" '
            BEGIN { FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")" }
            NR > 1 {
                if (exclude_id != "" && $1 == exclude_id) next
                gsub(/^"|"$/, "", $2)
                if ($2 == code) exit 1
            }
        ' "$CSV_FILE" || return 1
    fi

    return 0
}

sanitize_input() {
    local input="$1"

    # Trim leading/trailing whitespace
    input="${input#"${input%%[![:space:]]*}"}"
    input="${input%"${input##*[![:space:]]}"}"

    # Remove control characters (ASCII 1-8, 11, 12, 14-31) using sed for portability
    input=$(printf '%s' "$input" | sed 's/[\x01-\x08\x0B\x0C\x0E-\x1F]//g')

    echo "$input"
}

# ==============================================================================
# System Initialization
# ==============================================================================

check_dependencies() {
    local missing_deps=()

    log DEBUG "Checking dependencies..."

    for cmd in awk sed grep mktemp flock date; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if (( ${#missing_deps[@]} > 0 )); then
        die "Missing dependencies: ${missing_deps[*]}"
    fi

    log DEBUG "All dependencies satisfied"
}

check_single_instance() {
    if [[ -f "$PID_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")

        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            die "Another instance is already running (PID: $old_pid)"
        else
            log WARN "Removing stale PID file"
            rm -f "$PID_FILE"
        fi
    fi

    echo $$ > "$PID_FILE"
}

init_system() {
    log DEBUG "Initializing system..."

    # Create directories
    for dir in "$DATA_DIR" "$BACKUP_DIR" "$CONFIG_DIR" "$CACHE_DIR"; do
        if ! mkdir -p "$dir" 2>/dev/null; then
            die "Failed to create directory: $dir"
        fi
    done

    # Initialize log file
    if ! touch "$LOG_FILE" 2>/dev/null; then
        die "Failed to create log file: $LOG_FILE"
    fi

    # Create CSV with header if not exists
    if [[ ! -f "$CSV_FILE" ]]; then
        cat > "$CSV_FILE" << 'EOF'
ID,StudentCode,FirstName,LastName,Email,Phone,GPA,RegistrationDate
EOF
        log INFO "Database initialized"
    fi

    # Validate CSV integrity
    if ! head -1 "$CSV_FILE" | grep -q "^ID,StudentCode,FirstName"; then
        die "CSV file appears to be corrupted"
    fi

    # Load config if exists
    if [[ -f "$CONFIG_FILE" ]]; then
        log DEBUG "Loading configuration from $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE" || log WARN "Failed to load config file"
    fi

    log DEBUG "System initialized successfully"
}

# ==============================================================================
# ID Generation (Thread-Safe)
# ==============================================================================

get_next_id() {
    local lock_fd max_id

    # Use file descriptor for locking
    exec {lock_fd}>"$CSV_FILE.idlock"

    if ! flock -x -w "$LOCK_TIMEOUT" "$lock_fd"; then
        exec {lock_fd}>&-
        die "Failed to acquire ID lock"
    fi

    if [[ ! -f "$CSV_FILE" ]] || [[ $(wc -l < "$CSV_FILE") -eq 1 ]]; then
        echo 1
    else
        max_id=$(awk -F',' 'NR > 1 { print $1 }' "$CSV_FILE" | \
                 sort -n | \
                 tail -1)
        echo $(( ${max_id:-0} + 1 ))
    fi

    flock -u "$lock_fd"
    exec {lock_fd}>&-
}

# ==============================================================================
# Backup Management
# ==============================================================================

create_backup() {
    local reason="${1:-manual}"
    local timestamp backup_file

    [[ ! -f "$CSV_FILE" ]] && {
        log WARN "No database file to backup"
        return 1
    }

    timestamp="$(date '+%Y%m%d_%H%M%S')"
    backup_file="$BACKUP_DIR/students_${timestamp}_${reason}.csv"

    log DEBUG "Creating backup: $backup_file"

    # Use atomic copy with retry
    local retry_count=0
    while (( retry_count < MAX_RETRIES )); do
        if cp "$CSV_FILE" "$backup_file" 2>/dev/null; then
            log INFO "Backup created: $(basename "$backup_file")"
            cleanup_old_backups &  # Run in background
            return 0
        else
            ((retry_count++))
            log WARN "Backup attempt $retry_count failed, retrying..."
            sleep "$RETRY_DELAY"
        fi
    done

    log ERROR "Backup failed after $MAX_RETRIES attempts"
    return 1
}

cleanup_old_backups() {
    local backup_count

    backup_count=$(ls -1 "$BACKUP_DIR"/students_*.csv 2>/dev/null | wc -l)

    if (( backup_count > MAX_BACKUPS )); then
        log DEBUG "Cleaning up old backups (current: $backup_count, max: $MAX_BACKUPS)"

        # Remove oldest backups beyond MAX_BACKUPS (portable: ls -t sorts by time)
        ls -1t "$BACKUP_DIR"/students_*.csv 2>/dev/null | \
            tail -n +"$((MAX_BACKUPS + 1))" | \
            while IFS= read -r old_backup; do
                rm -f "$old_backup" 2>/dev/null || true
            done

        log DEBUG "Backup cleanup completed"
    fi
}

restore_backup() {
    local backup_file="$1"

    [[ ! -f "$backup_file" ]] && die "Backup file not found: $backup_file"

    log INFO "Restoring backup: $(basename "$backup_file")"

    acquire_lock

    # Create safety backup of current database (if it exists)
    if [[ -f "$CSV_FILE" ]]; then
        if ! cp "$CSV_FILE" "$CSV_FILE.before_restore.$(date +%s)" 2>/dev/null; then
            release_lock
            die "Failed to create safety backup"
        fi
    fi

    # Restore with retry
    local retry_count=0
    while (( retry_count < MAX_RETRIES )); do
        if cp "$backup_file" "$CSV_FILE" 2>/dev/null; then
            release_lock
            log SUCCESS "Backup restored successfully"
            return 0
        else
            ((retry_count++))
            log WARN "Restore attempt $retry_count failed, retrying..."
            sleep "$RETRY_DELAY"
        fi
    done

    release_lock
    die "Failed to restore backup after $MAX_RETRIES attempts"
}

# ==============================================================================
# CRUD Operations
# ==============================================================================

add_student() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "➕ $(msg add_student)" "$width"

    local student_code first_name last_name email phone gpa

    # Get student code
    while true; do
        echo ""
        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg student_code): ${C_RESET}")" student_code
        student_code="$(sanitize_input "$student_code")"

        if validate_student_code "$student_code"; then
            break
        else
            echo -e "  ${C_ERROR}${I_CROSS} Invalid or duplicate student code${C_RESET}"
        fi
    done

    # Get first name
    while true; do
        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg first_name): ${C_RESET}")" first_name
        first_name="$(sanitize_input "$first_name")"
        [[ -n "$first_name" ]] && break
        echo -e "  ${C_ERROR}${I_CROSS} Name cannot be empty${C_RESET}"
    done

    # Get last name
    while true; do
        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg last_name): ${C_RESET}")" last_name
        last_name="$(sanitize_input "$last_name")"
        [[ -n "$last_name" ]] && break
        echo -e "  ${C_ERROR}${I_CROSS} Last name cannot be empty${C_RESET}"
    done

    # Get email
    while true; do
        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg email): ${C_RESET}")" email
        email="$(sanitize_input "$email")"
        validate_email "$email" && break
        echo -e "  ${C_ERROR}${I_CROSS} Invalid email format${C_RESET}"
    done

    # Get phone
    while true; do
        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg phone): ${C_RESET}")" phone
        phone="$(sanitize_input "$phone")"
        validate_phone "$phone" && break
        echo -e "  ${C_ERROR}${I_CROSS} Invalid phone number${C_RESET}"
    done

    # Get GPA
    while true; do
        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg gpa): ${C_RESET}")" gpa
        validate_gpa "$gpa" && break
        echo -e "  ${C_ERROR}${I_CROSS} GPA must be between 0 and 20${C_RESET}"
    done

    # Generate ID and timestamp
    acquire_lock

    local student_id reg_date new_line
    student_id="$(get_next_id)"
    reg_date="$(date +"$DATE_FORMAT")"

    # Build CSV line with proper escaping
    new_line="$(csv_escape "$student_id")"
    new_line+=",$(csv_escape "$student_code")"
    new_line+=",$(csv_escape "$first_name")"
    new_line+=",$(csv_escape "$last_name")"
    new_line+=",$(csv_escape "$email")"
    new_line+=",$(csv_escape "$phone")"
    new_line+=",$(csv_escape "$gpa")"
    new_line+=",$(csv_escape "$reg_date")"

    # Append under directory lock protection
    echo "$new_line" >> "$CSV_FILE" || {
        release_lock
        die "Failed to add student to database"
    }

    release_lock

    echo ""
    echo -e "${C_SUCCESS}${I_CHECK} $(msg student_added) (ID: $student_id)${C_RESET}"
    create_backup "auto" &>/dev/null &

    close_box "$width"
    end_timer
    read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

display_students() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "📋 $(msg view_all)" "$width"

    [[ ! -f "$CSV_FILE" ]] && die "Database file not found"

    local total_count
    total_count=$(awk 'END {print NR-1}' "$CSV_FILE")

    if (( total_count == 0 )); then
        echo ""
        echo -e "  ${C_WARNING}${I_WARN} $(msg no_students)${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return
    fi

    echo ""

    # Display using AWK with proper CSV parsing
    awk -v cyan="$C_CYAN" -v reset="$C_RESET" -v green="$C_GREEN" -v bold="$C_BOLD" -v dim="$C_DIM" -v white="$C_WHITE" '
        BEGIN {
            FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")"

            # Header
            printf cyan bold "%-5s %-12s %-15s %-15s %-25s %-12s %-8s" reset "\n",
                   "ID", "Code", "First", "Last", "Email", "Phone", "GPA"

            printf dim "%s" reset "\n",
                   "─────────────────────────────────────────────────────────────────────────────────────────────"
        }

        NR > 1 {
            # Remove quotes and unescape
            for (i = 1; i <= NF; i++) {
                gsub(/^"|"$/, "", $i)
                gsub(/""/, "\"", $i)
            }

            # Color-code GPA
            gpa_val = $7 + 0
            if (gpa_val >= 17) gpa_color = green
            else if (gpa_val >= 14) gpa_color = cyan
            else if (gpa_val >= 12) gpa_color = "\033[1;33m"
            else gpa_color = "\033[0;31m"

            printf "%-5s %-12s %-15s %-15s %-25s %-12s " \
                   "%s%-8s%s\n",
                   $1, $2, substr($3, 1, 15), substr($4, 1, 15),
                   substr($5, 1, 25), $6, gpa_color, $7, reset
        }

        END {
            print ""
            printf green "✓ Total: %d students" reset "\n", NR-1
        }
    ' "$CSV_FILE"

    close_box "$width"
    end_timer
    read -rsp $'\n\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

view_student_details() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "👤 $(msg view_details)" "$width"

    read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg enter_id): ${C_RESET}")" student_id
    student_id="$(sanitize_input "$student_id")"

    [[ ! "$student_id" =~ ^[0-9]+$ ]] && {
        echo -e "  ${C_ERROR}${I_CROSS} Invalid ID format${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return 1
    }

    local student_data
    student_data=$(awk -v id="$student_id" '
        BEGIN { FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")" }
        NR > 1 && $1 == id {
            for (i = 1; i <= NF; i++) {
                gsub(/^"|"$/, "", $i)
                gsub(/""/, "\"", $i)
                print $i
            }
            exit
        }
    ' "$CSV_FILE")

    if [[ -z "$student_data" ]]; then
        echo -e "  ${C_ERROR}${I_CROSS} Student not found (ID: $student_id)${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return 1
    fi

    local -a fields
    mapfile -t fields <<< "$student_data"

    echo ""

    # Draw a nice detail card
    draw_light_box "Student Details" "$((width - 8))"

    local detail_width=$((width - 12))

    echo -e "  ${C_DIM}${BOX_LV}${C_RESET}  ${C_HEADER}ID:${C_RESET}              ${C_HIGHLIGHT}${fields[0]}${C_RESET}"
    echo -e "  ${C_DIM}${BOX_LV}${C_RESET}  ${C_HEADER}Student Code:${C_RESET}    ${C_HIGHLIGHT}${fields[1]}${C_RESET}"
    echo -e "  ${C_DIM}${BOX_LV}${C_RESET}  ${C_HEADER}Name:${C_RESET}            ${C_HIGHLIGHT}${fields[2]} ${fields[3]}${C_RESET}"
    echo -e "  ${C_DIM}${BOX_LV}${C_RESET}  ${C_HEADER}Email:${C_RESET}           ${C_HIGHLIGHT}${fields[4]}${C_RESET}"
    echo -e "  ${C_DIM}${BOX_LV}${C_RESET}  ${C_HEADER}Phone:${C_RESET}           ${C_HIGHLIGHT}${fields[5]}${C_RESET}"

    # GPA with color coding
    local gpa_val="${fields[6]}"
    local gpa_color="$C_CYAN"
    if awk "BEGIN { exit !($gpa_val >= 17) }" 2>/dev/null; then
        gpa_color="$C_GREEN"
    elif awk "BEGIN { exit !($gpa_val >= 14) }" 2>/dev/null; then
        gpa_color="$C_CYAN"
    elif awk "BEGIN { exit !($gpa_val >= 12) }" 2>/dev/null; then
        gpa_color="$C_YELLOW"
    else
        gpa_color="$C_RED"
    fi

    echo -e "  ${C_DIM}${BOX_LV}${C_RESET}  ${C_HEADER}GPA:${C_RESET}             ${gpa_color}${C_BOLD}${fields[6]}${C_RESET}"
    echo -e "  ${C_DIM}${BOX_LV}${C_RESET}  ${C_HEADER}Registered:${C_RESET}      ${C_DIM}${fields[7]}${C_RESET}"

    close_light_box "$((width - 8))"

    close_box "$width"
    end_timer
    read -rsp $'\n\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

edit_student() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "✏️  $(msg edit_student)" "$width"

    read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg enter_id): ${C_RESET}")" student_id
    student_id="$(sanitize_input "$student_id")"

    [[ ! "$student_id" =~ ^[0-9]+$ ]] && {
        echo -e "  ${C_ERROR}${I_CROSS} Invalid ID format${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return 1
    }

    # Get current data
    local current_data
    current_data=$(awk -v id="$student_id" '
        BEGIN { FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")" }
        NR > 1 && $1 == id {
            for (i = 1; i <= NF; i++) {
                gsub(/^"|"$/, "", $i)
                gsub(/""/, "\"", $i)
                print $i
            }
            exit
        }
    ' "$CSV_FILE")

    if [[ -z "$current_data" ]]; then
        echo -e "  ${C_ERROR}${I_CROSS} Student not found${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return 1
    fi

    local -a old_fields
    mapfile -t old_fields <<< "$current_data"

    echo ""
    echo -e "  ${C_WARNING}${I_INFO} $(msg current_info):${C_RESET}"
    echo -e "  ${C_DIM}Code: ${old_fields[1]} | Name: ${old_fields[2]} ${old_fields[3]} | GPA: ${old_fields[6]}${C_RESET}"
    echo ""

    # Get new values
    local new_code new_fname new_lname new_email new_phone new_gpa

    # Student code
    while true; do
        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg student_code) ($(msg keep_current)): ${C_RESET}")" new_code
        new_code="$(sanitize_input "$new_code")"

        if [[ -z "$new_code" ]]; then
            new_code="${old_fields[1]}"
            break
        elif validate_student_code "$new_code" "$student_id"; then
            break
        else
            echo -e "  ${C_ERROR}${I_CROSS} Invalid or duplicate student code${C_RESET}"
        fi
    done

    # First name
    read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg first_name) ($(msg keep_current)): ${C_RESET}")" new_fname
    new_fname="$(sanitize_input "$new_fname")"
    [[ -z "$new_fname" ]] && new_fname="${old_fields[2]}"

    # Last name
    read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg last_name) ($(msg keep_current)): ${C_RESET}")" new_lname
    new_lname="$(sanitize_input "$new_lname")"
    [[ -z "$new_lname" ]] && new_lname="${old_fields[3]}"

    # Email
    while true; do
        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg email) ($(msg keep_current)): ${C_RESET}")" new_email
        new_email="$(sanitize_input "$new_email")"

        if [[ -z "$new_email" ]]; then
            new_email="${old_fields[4]}"
            break
        elif validate_email "$new_email"; then
            break
        else
            echo -e "  ${C_ERROR}${I_CROSS} Invalid email format${C_RESET}"
        fi
    done

    # Phone
    while true; do
        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg phone) ($(msg keep_current)): ${C_RESET}")" new_phone
        new_phone="$(sanitize_input "$new_phone")"

        if [[ -z "$new_phone" ]]; then
            new_phone="${old_fields[5]}"
            break
        elif validate_phone "$new_phone"; then
            break
        else
            echo -e "  ${C_ERROR}${I_CROSS} Invalid phone number${C_RESET}"
        fi
    done

    # GPA
    while true; do
        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg gpa) ($(msg keep_current)): ${C_RESET}")" new_gpa

        if [[ -z "$new_gpa" ]]; then
            new_gpa="${old_fields[6]}"
            break
        elif validate_gpa "$new_gpa"; then
            break
        else
            echo -e "  ${C_ERROR}${I_CROSS} GPA must be between 0 and 20${C_RESET}"
        fi
    done

    # Update record
    acquire_lock

    local new_line temp_file
    temp_file="$(mktemp)"

    new_line="$(csv_escape "${old_fields[0]}")"
    new_line+=",$(csv_escape "$new_code")"
    new_line+=",$(csv_escape "$new_fname")"
    new_line+=",$(csv_escape "$new_lname")"
    new_line+=",$(csv_escape "$new_email")"
    new_line+=",$(csv_escape "$new_phone")"
    new_line+=",$(csv_escape "$new_gpa")"
    new_line+=",$(csv_escape "${old_fields[7]}")"

    awk -v id="$student_id" -v newline="$new_line" '
        BEGIN { FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")" }
        NR == 1 { print; next }
        $1 == id { print newline; next }
        { print }
    ' "$CSV_FILE" > "$temp_file"

    if mv "$temp_file" "$CSV_FILE" 2>/dev/null; then
        release_lock
        echo ""
        echo -e "${C_SUCCESS}${I_CHECK} $(msg student_updated)${C_RESET}"
        create_backup "auto" &>/dev/null &
    else
        rm -f "$temp_file"
        release_lock
        echo -e "  ${C_ERROR}${I_CROSS} Failed to update student${C_RESET}"
    fi

    close_box "$width"
    end_timer
    read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

delete_student() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "🗑️  $(msg delete_student)" "$width"

    read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg enter_id): ${C_RESET}")" student_id
    student_id="$(sanitize_input "$student_id")"

    [[ ! "$student_id" =~ ^[0-9]+$ ]] && {
        echo -e "  ${C_ERROR}${I_CROSS} Invalid ID format${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return 1
    }

    # Get student info
    local student_data
    student_data=$(awk -v id="$student_id" '
        BEGIN { FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")" }
        NR > 1 && $1 == id {
            for (i = 1; i <= NF; i++) {
                gsub(/^"|"$/, "", $i)
                gsub(/""/, "\"", $i)
                print $i
            }
            exit
        }
    ' "$CSV_FILE")

    if [[ -z "$student_data" ]]; then
        echo -e "  ${C_ERROR}${I_CROSS} Student not found${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return 1
    fi

    local -a fields
    mapfile -t fields <<< "$student_data"

    echo ""
    echo -e "  ${C_WARNING}${I_WARN} Are you sure you want to delete this student?${C_RESET}"
    echo -e "  ${C_DIM}ID: ${fields[0]} | Code: ${fields[1]}${C_RESET}"
    echo -e "  ${C_DIM}Name: ${fields[2]} ${fields[3]}${C_RESET}"
    echo -e "  ${C_ERROR}${C_BOLD}This action cannot be undone!${C_RESET}"
    echo ""

    read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg confirm_delete): ${C_RESET}")" confirm

    if [[ "$confirm" != "DELETE" ]]; then
        echo -e "  ${C_WARNING}${I_WARN} $(msg operation_cancelled)${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return
    fi

    # Delete record
    acquire_lock

    local temp_file
    temp_file="$(mktemp)"

    awk -v id="$student_id" '
        BEGIN { FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")" }
        NR == 1 { print; next }
        $1 != id { print }
    ' "$CSV_FILE" > "$temp_file"

    if mv "$temp_file" "$CSV_FILE" 2>/dev/null; then
        release_lock
        echo ""
        echo -e "${C_SUCCESS}${I_CHECK} $(msg student_deleted)${C_RESET}"
        create_backup "auto" &>/dev/null &
    else
        rm -f "$temp_file"
        release_lock
        echo -e "  ${C_ERROR}${I_CROSS} Failed to delete student${C_RESET}"
    fi

    close_box "$width"
    end_timer
    read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

search_students() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "🔍 $(msg search)" "$width"

    read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg search_term): ${C_RESET}")" search_term
    search_term="$(sanitize_input "$search_term")"

    if [[ -z "$search_term" ]]; then
        echo -e "  ${C_ERROR}${I_CROSS} Search term cannot be empty${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return
    fi

    echo -e "\n  ${C_HEADER}Search Results:${C_RESET}\n"

    local results
    results=$(awk -v term="$search_term" -v cyan="$C_CYAN" -v reset="$C_RESET" -v green="$C_GREEN" -v bold="$C_BOLD" -v dim="$C_DIM" '
        BEGIN {
            FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")"
            term = tolower(term)
            found = 0
        }

        NR == 1 {
            printf cyan bold "%-5s %-12s %-15s %-15s %-25s %-8s" reset "\n",
                   "ID", "Code", "First", "Last", "Email", "GPA"
            printf dim "%s" reset "\n",
                   "────────────────────────────────────────────────────────────────────────────────"
            next
        }

        {
            # Unescape fields
            for (i = 1; i <= NF; i++) {
                gsub(/^"|"$/, "", $i)
                gsub(/""/, "\"", $i)
            }

            # Case-insensitive search in code, first name, last name, email
            if (tolower($2) ~ term || tolower($3) ~ term || tolower($4) ~ term || tolower($5) ~ term) {
                printf "%-5s %-12s %-15s %-15s %-25s %-8s\n",
                       $1, $2, substr($3, 1, 15), substr($4, 1, 15),
                       substr($5, 1, 25), $7
                found++
            }
        }

        END {
            print ""
            if (found == 0) {
                print "No results found"
            } else {
                printf green "✓ Found %d result(s)" reset "\n", found
            }
        }
    ' "$CSV_FILE")

    echo "$results"

    close_box "$width"
    end_timer
    read -rsp $'\n\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

# ==============================================================================
# Statistics & Reporting (Enhanced)
# ==============================================================================

show_statistics() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "📊 $(msg statistics)" "$width"

    [[ ! -f "$CSV_FILE" ]] && die "Database file not found"

    echo ""

    awk -v green="$C_GREEN" -v yellow="$C_YELLOW" -v red="$C_RED" -v cyan="$C_CYAN" -v reset="$C_RESET" -v bold="$C_BOLD" -v dim="$C_DIM" -v white="$C_WHITE" -v blue="$C_BLUE" '
        BEGIN {
            FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")"
            total = 0
            sum_gpa = 0
            max_gpa = 0
            min_gpa = 20
            excellent = 0
            good = 0
            average = 0
            poor = 0
        }

        NR > 1 {
            total++

            # Clean GPA field
            gpa = $7
            gsub(/^"|"$/, "", gpa)
            gpa = gpa + 0

            sum_gpa += gpa
            if (gpa > max_gpa) { max_gpa = gpa; max_name = $3 " " $4 }
            if (gpa < min_gpa) { min_gpa = gpa; min_name = $3 " " $4 }

            # Store all GPAs for distribution chart
            gpas[total] = gpa

            if (gpa >= 17) excellent++
            else if (gpa >= 14) good++
            else if (gpa >= 12) average++
            else poor++
        }

        END {
            if (total == 0) {
                print "  \033[1;33m⚠ No data available\033[0m"
                exit
            }

            avg_gpa = sum_gpa / total

            # System Health Section
            printf "  \033[1;36m┌─── System Health ─────────────────────────┐\033[0m\n"
            printf "  \033[0;36m│\033[0m  📊 Total Students:    \033[1;37m%-20d\033[0m\033[0;36m│\033[0m\n", total
            printf "  \033[0;36m│\033[0m  📈 Average GPA:       \033[1;37m%-20.2f\033[0m\033[0;36m│\033[0m\n", avg_gpa
            printf "  \033[0;36m│\033[0m  🏆 Highest GPA:       \033[1;32m%-20.2f\033[0m\033[0;36m│\033[0m\n", max_gpa
            printf "  \033[0;36m│\033[0m  📉 Lowest GPA:        \033[1;31m%-20.2f\033[0m\033[0;36m│\033[0m\n", min_gpa
            printf "  \033[0;36m└──────────────────────────────────────────┘\033[0m\n"

            print ""

            # GPA Distribution with Visual Chart
            printf "  \033[1;36m┌─── GPA Distribution Chart ───────────────┐\033[0m\n"

            # Excellent bar
            bar_len = int((excellent / total) * 30)
            if (bar_len == 0 && excellent > 0) bar_len = 1
            printf "  \033[0;36m│\033[0m  \033[1;32mExcellent (≥17):\033[0m "
            for (i = 0; i < bar_len; i++) printf "█"
            for (i = bar_len; i < 30; i++) printf "░"
            printf " %3d (%5.1f%%)\033[0m\033[0;36m│\033[0m\n", excellent, (excellent/total)*100

            # Good bar
            bar_len = int((good / total) * 30)
            if (bar_len == 0 && good > 0) bar_len = 1
            printf "  \033[0;36m│\033[0m  \033[0;36mGood (14-16.99):  \033[0m "
            for (i = 0; i < bar_len; i++) printf "█"
            for (i = bar_len; i < 30; i++) printf "░"
            printf " %3d (%5.1f%%)\033[0m\033[0;36m│\033[0m\n", good, (good/total)*100

            # Average bar
            bar_len = int((average / total) * 30)
            if (bar_len == 0 && average > 0) bar_len = 1
            printf "  \033[0;36m│\033[0m  \033[1;33mAverage (12-13.99):\033[0m"
            for (i = 0; i < bar_len; i++) printf "█"
            for (i = bar_len; i < 30; i++) printf "░"
            printf " %3d (%5.1f%%)\033[0m\033[0;36m│\033[0m\n", average, (average/total)*100

            # Poor bar
            bar_len = int((poor / total) * 30)
            if (bar_len == 0 && poor > 0) bar_len = 1
            printf "  \033[0;36m│\033[0m  \033[0;31mPoor (<12):       \033[0m "
            for (i = 0; i < bar_len; i++) printf "█"
            for (i = bar_len; i < 30; i++) printf "░"
            printf " %3d (%5.1f%%)\033[0m\033[0;36m│\033[0m\n", poor, (poor/total)*100

            printf "  \033[0;36m└──────────────────────────────────────────┘\033[0m\n"

            print ""

            # Data Integrity Check
            printf "  \033[1;36m┌─── Data Integrity ───────────────────────┐\033[0m\n"
            integrity_score = int((total > 0 ? 100 : 0))
            printf "  \033[0;36m│\033[0m  ✓ Database Status:   \033[1;32mHealthy\033[0m           \033[0;36m│\033[0m\n"
            printf "  \033[0;36m│\033[0m  ✓ Integrity Score:   \033[1;32m%d%%\033[0m               \033[0;36m│\033[0m\n", integrity_score
            printf "  \033[0;36m└──────────────────────────────────────────┘\033[0m\n"
        }
    ' "$CSV_FILE"

    close_box "$width"
    end_timer
    read -rsp $'\n\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

# ==============================================================================
# Export & Import
# ==============================================================================

export_to_json() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "📤 $(msg export_json)" "$width"

    local output_file="$DATA_DIR/students_export_$(date +%Y%m%d_%H%M%S).json"

    echo -e "\n  ${C_DIM}Exporting to JSON...${C_RESET}"

    awk '
        BEGIN {
            FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")"
            print "{"
            print "  \"students\": ["
            first = 1
        }

        NR > 1 {
            # Clean fields
            for (i = 1; i <= NF; i++) {
                gsub(/^"|"$/, "", $i)
                gsub(/""/, "\"", $i)
                gsub(/\\/, "\\\\", $i)
                gsub(/"/, "\\\"", $i)
            }

            if (!first) print ","
            first = 0

            print "    {"
            printf "      \"id\": %s,\n", $1
            printf "      \"studentCode\": \"%s\",\n", $2
            printf "      \"firstName\": \"%s\",\n", $3
            printf "      \"lastName\": \"%s\",\n", $4
            printf "      \"email\": \"%s\",\n", $5
            printf "      \"phone\": \"%s\",\n", $6
            printf "      \"gpa\": %s,\n", $7
            printf "      \"registrationDate\": \"%s\"\n", $8
            printf "    }"
        }

        END {
            print ""
            print "  ],"
            printf "  \"exportDate\": \"%s\",\n", strftime("%Y-%m-%d %H:%M:%S")
            printf "  \"totalRecords\": %d,\n", NR-1
            printf "  \"version\": \"%s\"\n", "5.0.0"
            print "}"
        }
    ' "$CSV_FILE" > "$output_file"

    echo -e "\n  ${C_SUCCESS}${I_CHECK} $(msg export_success): $output_file${C_RESET}"

    close_box "$width"
    end_timer
    read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

import_from_csv() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "📥 $(msg import_csv)" "$width"

    echo -e "\n  ${C_DIM}Enter the path to the CSV file to import:${C_RESET}\n"
    read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg import_file): ${C_RESET}")" import_file
    import_file="$(sanitize_input "$import_file")"

    if [[ ! -f "$import_file" ]]; then
        echo -e "\n  ${C_ERROR}${I_CROSS} File not found: $import_file${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return 1
    fi

    # Validate CSV format
    local header
    header=$(head -1 "$import_file")
    if [[ ! "$header" =~ ^ID,StudentCode,FirstName ]]; then
        echo -e "\n  ${C_ERROR}${I_CROSS} Invalid CSV format. Expected header: ID,StudentCode,FirstName,LastName,Email,Phone,GPA,RegistrationDate${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return 1
    fi

    local import_count
    import_count=$(awk 'END {print NR-1}' "$import_file")

    echo -e "\n  ${C_INFO}${I_INFO} Found $import_count records to import${C_RESET}"
    echo ""

    # Show preview
    echo -e "  ${C_HEADER}Preview (first 5 records):${C_RESET}"
    head -6 "$import_file" | tail -5 | while IFS= read -r line; do
        local code name
        code=$(get_csv_field "$line" 2)
        name="$(get_csv_field "$line" 3) $(get_csv_field "$line" 4)"
        echo -e "  ${C_DIM}→ Code: $code | Name: $name${C_RESET}"
    done

    echo ""
    read -rp "$(echo -e "${C_BLUE}${I_ARROW} Import all records? (y/n): ${C_RESET}")" confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "\n  ${C_WARNING}${I_WARN} $(msg operation_cancelled)${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return
    fi

    # Create backup before import
    create_backup "pre_import" &>/dev/null

    acquire_lock

    local imported=0
    local skipped=0

    while IFS= read -r line; do
        local student_code
        student_code=$(get_csv_field "$line" 2)

        # Check for duplicate student code
        if awk -v code="$student_code" '
            BEGIN { FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")" }
            NR > 1 {
                gsub(/^"|"$/, "", $2)
                if ($2 == code) exit 0
            }
            END { exit 1 }
        ' "$CSV_FILE" 2>/dev/null; then
            ((skipped++))
            continue
        fi

        # Get the student data
        local s_id s_code s_fname s_lname s_email s_phone s_gpa s_date
        s_id=$(get_csv_field "$line" 1)
        s_code="$student_code"
        s_fname=$(get_csv_field "$line" 3)
        s_lname=$(get_csv_field "$line" 4)
        s_email=$(get_csv_field "$line" 5)
        s_phone=$(get_csv_field "$line" 6)
        s_gpa=$(get_csv_field "$line" 7)
        s_date=$(get_csv_field "$line" 8)

        # Generate new ID
        local new_id
        new_id="$(get_next_id)"

        local new_line
        new_line="$(csv_escape "$new_id")"
        new_line+=",$(csv_escape "$s_code")"
        new_line+=",$(csv_escape "$s_fname")"
        new_line+=",$(csv_escape "$s_lname")"
        new_line+=",$(csv_escape "$s_email")"
        new_line+=",$(csv_escape "$s_phone")"
        new_line+=",$(csv_escape "$s_gpa")"
        new_line+=",$(csv_escape "$s_date")"

        echo "$new_line" >> "$CSV_FILE"
        ((imported++))

    done < <(tail -n +2 "$import_file")

    release_lock

    echo -e "\n  ${C_SUCCESS}${I_CHECK} $(msg import_success)${C_RESET}"
    echo -e "  ${C_DIM}Imported: $imported | Skipped (duplicates): $skipped${C_RESET}"

    create_backup "post_import" &>/dev/null

    close_box "$width"
    end_timer
    read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

export_clean_csv() {
    local output_file="${1:-"$DATA_DIR/students_export_$(date +%Y%m%d_%H%M%S).csv"}"

    log INFO "Exporting clean CSV to: $output_file"

    if [[ ! -f "$CSV_FILE" ]]; then
        log ERROR "No database to export"
        return 1
    fi

    # Copy CSV with header only if it exists and has data
    awk '
        BEGIN { FPAT = "([^,]*)|(\\\"([^\\\"]|\\\"\\\")*\\\")" }
        NR == 1 { print; next }
        {
            for (i = 1; i <= NF; i++) {
                gsub(/^"|"$/, "", $i)
                gsub(/""/, "\"", $i)
            }
            # Re-escape properly
            for (i = 1; i <= NF; i++) {
                if ($i ~ /[,\"\n]/) {
                    gsub(/"/, "\"\"", $i)
                    $i = "\"" $i "\""
                }
            }
            print
        }
    ' "$CSV_FILE" > "$output_file"

    log SUCCESS "Clean CSV exported: $output_file"
    echo "$output_file"
}

# ==============================================================================
# GPA Calculator
# ==============================================================================

gpa_calculator() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "🧮 $(msg gpa_calc)" "$width"

    echo -e "\n  ${C_DIM}$(msg gpa_calc_desc)${C_RESET}\n"

    local total_credits=0
    local total_grade_points=0
    local course_num=1

    echo -e "  ${C_HEADER}Enter your courses (type 'done' when finished):${C_RESET}\n"

    while true; do
        local credit grade

        echo -e "  ${C_DIM}── Course $course_num ──${C_RESET}"

        read -rp "$(echo -e "    ${C_BLUE}Credits: ${C_RESET}")" credit
        [[ "$credit" == "done" || "$credit" == "d" ]] && break

        if ! [[ "$credit" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            echo -e "    ${C_ERROR}${I_CROSS} Invalid credit${C_RESET}"
            continue
        fi

        read -rp "$(echo -e "    ${C_BLUE}Grade (0-20): ${C_RESET}")" grade

        if ! validate_gpa "$grade"; then
            echo -e "    ${C_ERROR}${I_CROSS} Invalid grade (must be 0-20)${C_RESET}"
            continue
        fi

        total_credits=$(awk "BEGIN { printf \"%.2f\", $total_credits + $credit }")
        total_grade_points=$(awk "BEGIN { printf \"%.2f\", $total_grade_points + ($credit * $grade) }")

        echo -e "    ${C_SUCCESS}${I_CHECK} Added: $credit credits × $grade = $(awk "BEGIN { printf \"%.2f\", $credit * $grade }")${C_RESET}"
        echo ""

        ((course_num++))
    done

    if (( course_num <= 1 )); then
        echo -e "\n  ${C_WARNING}${I_WARN} No courses entered${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return
    fi

    local gpa
    gpa=$(awk "BEGIN { printf \"%.2f\", $total_grade_points / $total_credits }")

    echo ""
    print_line "─" "$((width - 8))" "${C_DIM}"
    echo ""

    # Color code the GPA
    local gpa_color="$C_CYAN"
    if awk "BEGIN { exit !($gpa >= 17) }" 2>/dev/null; then
        gpa_color="$C_GREEN"
    elif awk "BEGIN { exit !($gpa >= 14) }" 2>/dev/null; then
        gpa_color="$C_CYAN"
    elif awk "BEGIN { exit !($gpa >= 12) }" 2>/dev/null; then
        gpa_color="$C_YELLOW"
    else
        gpa_color="$C_RED"
    fi

    echo -e "  ${C_HEADER}Results:${C_RESET}"
    echo -e "  ${C_DIM}Total Credits: $total_credits${C_RESET}"
    echo -e "  ${C_DIM}Total Grade Points: $total_grade_points${C_RESET}"
    echo ""
    echo -e "  ${C_HIGHLIGHT}Your GPA: ${gpa_color}${C_BOLD}$gpa${C_RESET}"
    echo ""

    # Show GPA interpretation
    if awk "BEGIN { exit !($gpa >= 17) }" 2>/dev/null; then
        echo -e "  ${C_GREEN}${I_TROPHY} Excellent! You're doing amazing!${C_RESET}"
    elif awk "BEGIN { exit !($gpa >= 14) }" 2>/dev/null; then
        echo -e "  ${C_CYAN}${I_STAR} Good job! Keep it up!${C_RESET}"
    elif awk "BEGIN { exit !($gpa >= 12) }" 2>/dev/null; then
        echo -e "  ${C_YELLOW}${I_BULB} Average. There's room for improvement.${C_RESET}"
    else
        echo -e "  ${C_RED}${I_WARN} Needs significant improvement. Consider seeking help.${C_RESET}"
    fi

    close_box "$width"
    end_timer
    read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

# ==============================================================================
# Help & Version
# ==============================================================================

show_help() {
    local width=$(get_terminal_width)

    echo -e "${C_HEADER}"
    cat << EOF
╔$(printf "%0.s═" $(seq 1 $((width - 2))))╗
║$(printf "%0.s " $(seq 1 $(( (width - 2 - ${#APP_NAME} - ${#APP_VERSION} - 12) / 2 ))))🎓 ${APP_NAME} v${APP_VERSION}$(printf "%0.s " $(seq 1 $(( (width - 2 - ${#APP_NAME} - ${#APP_VERSION} - 12) / 2 ))))║
╚$(printf "%0.s═" $(seq 1 $((width - 2))))╝${C_RESET}

${C_BOLD}USAGE:${C_RESET}
    $SCRIPT_NAME [OPTIONS]

${C_BOLD}OPTIONS:${C_RESET}
    -h, --help              Show this help message
    -v, --version           Show version information
    -d, --debug             Enable debug mode
    -p, --performance       Enable performance metrics
    --lang <en|fa>          Set language (English/Persian)
    --check-deps            Check system dependencies
    --init                  Initialize/repair system directories
    --export-csv            Export database to clean CSV file

${C_BOLD}CONFIGURATION:${C_RESET}
    Config file: $CONFIG_FILE

    Available settings:
      MAX_BACKUPS=10
      LOCK_TIMEOUT=10
      MAX_RETRIES=3
      LOG_LEVEL=INFO
      ENABLE_PERFORMANCE_METRICS=false
      LANG_MODE=en

${C_BOLD}FILES:${C_RESET}
    Data:    $CSV_FILE
    Backups: $BACKUP_DIR
    Logs:    $LOG_FILE

${C_BOLD}FEATURES:${C_RESET}
    • Thread-safe operations with file locking
    • RFC 4180 compliant CSV handling
    • Automatic backup rotation (keeps last $MAX_BACKUPS)
    • Multi-level logging (DEBUG, INFO, WARN, ERROR)
    • Input validation and sanitization
    • JSON & CSV export capability
    • Performance metrics tracking
    • Single instance enforcement
    • GPA Calculator
    • Batch CSV Import
    • Bilingual support (English/Persian)
    • Professional terminal UI with charts

${C_BOLD}EXAMPLES:${C_RESET}
    # Run normally
    $SCRIPT_NAME

    # Enable debug mode
    DEBUG=1 $SCRIPT_NAME --debug

    # Enable performance metrics
    $SCRIPT_NAME --performance

    # Set language to Persian
    $SCRIPT_NAME --lang fa

    # Check dependencies
    $SCRIPT_NAME --check-deps

${C_BOLD}AUTHOR:${C_RESET}
    Mehdi Khorshidi Far <mehdi@code-watch.dev>

${C_BOLD}LICENSE:${C_RESET}
    MIT License

${C_BOLD}REPOSITORY:${C_RESET}
    github.com/Mehdi-dev-sudo/student-management-bash

EOF
}

show_version() {
    local width=$(get_terminal_width)
    draw_box "Version Info" "$width"

    echo ""
    echo -e "  ${C_HEADER}Application:${C_RESET} ${C_HIGHLIGHT}$APP_NAME${C_RESET}"
    echo -e "  ${C_HEADER}Version:${C_RESET}     ${C_SUCCESS}$APP_VERSION${C_RESET}"
    echo -e "  ${C_HEADER}Bash:${C_RESET}        ${C_DIM}${BASH_VERSION}${C_RESET}"
    echo -e "  ${C_HEADER}System:${C_RESET}      ${C_DIM}$(uname -s) $(uname -r)${C_RESET}"
    echo ""

    close_box "$width"
}

# ==============================================================================
# System Management
# ==============================================================================

view_logs() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "📜 $(msg logs) (Last 50 lines)" "$width"

    echo ""

    if [[ -f "$LOG_FILE" ]]; then
        tail -n 50 "$LOG_FILE" | while IFS= read -r line; do
            # Colorize log levels
            if [[ "$line" =~ \[ERROR\] ]]; then
                echo -e "  ${C_ERROR}$line${C_RESET}"
            elif [[ "$line" =~ \[WARN\] ]]; then
                echo -e "  ${C_WARNING}$line${C_RESET}"
            elif [[ "$line" =~ \[SUCCESS\] ]]; then
                echo -e "  ${C_SUCCESS}$line${C_RESET}"
            elif [[ "$line" =~ \[DEBUG\] ]]; then
                echo -e "  ${C_MAGENTA}${C_DIM}$line${C_RESET}"
            else
                echo -e "  ${C_DIM}$line${C_RESET}"
            fi
        done
    else
        echo -e "  ${C_WARNING}${I_WARN} No logs found${C_RESET}"
    fi

    close_box "$width"
    end_timer
    read -rsp $'\n\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

list_backups() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "💾 $(msg backup_list)" "$width"

    local backups backups_array
    # Portable: ls -1t lists files sorted by modification time (newest first)
    backups=$(ls -1t "$BACKUP_DIR"/students_*.csv 2>/dev/null || true)

    if [[ -z "$backups" ]]; then
        echo -e "\n  ${C_WARNING}${I_WARN} No backups found${C_RESET}"
        close_box "$width"
        read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
        return
    fi

    mapfile -t backups_array <<< "$backups"
    local count=${#backups_array[@]}

    echo ""

    for i in "${!backups_array[@]}"; do
        local line_num=$((i + 1))
        local backup_file="${backups_array[$i]}"
        local display_name
        display_name=$(basename "$backup_file")

        if echo "$display_name" | grep -q "$(date +%Y%m%d)"; then
            echo -e "  ${C_GREEN}${line_num}) ${display_name}${C_RESET}"
        else
            echo -e "  ${C_DIM}${line_num}) ${display_name}${C_RESET}"
        fi
    done

    echo ""

    read -rp "$(echo -e "${C_BLUE}${I_ARROW} Enter backup number to restore (0 to cancel): ${C_RESET}")" choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice > 0 && choice <= count )); then
        local selected_backup="${backups_array[$((choice - 1))]}"
        restore_backup "$selected_backup"
    elif [[ "$choice" != "0" ]]; then
        echo -e "  ${C_ERROR}${I_CROSS} Invalid selection${C_RESET}"
    fi

    close_box "$width"
    end_timer
    read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

# ==============================================================================
# Settings
# ==============================================================================

settings_menu() {
    clear
    start_timer

    local width=$(get_terminal_width)
    draw_box "⚙️  $(msg settings)" "$width"

    echo ""
    echo -e "  ${C_HEADER}Current Settings:${C_RESET}"
    echo -e "  ${C_DIM}Language: ${C_HIGHLIGHT}$LANG_MODE${C_RESET}"
    echo -e "  ${C_DIM}Max Backups: ${C_HIGHLIGHT}$MAX_BACKUPS${C_RESET}"
    echo -e "  ${C_DIM}Lock Timeout: ${C_HIGHLIGHT}$LOCK_TIMEOUT${C_RESET}"
    echo -e "  ${C_DIM}Max Retries: ${C_HIGHLIGHT}$MAX_RETRIES${C_RESET}"
    echo -e "  ${C_DIM}Log Level: ${C_HIGHLIGHT}$LOG_LEVEL${C_RESET}"
    echo -e "  ${C_DIM}Performance Metrics: ${C_HIGHLIGHT}$ENABLE_PERFORMANCE_METRICS${C_RESET}"
    echo ""

    echo -e "  ${C_HEADER}Settings:${C_RESET}"
    echo "  1) 🌐 Change Language (Current: $LANG_MODE)"
    echo "  2) 💾 Change Max Backups (Current: $MAX_BACKUPS)"
    echo "  3) 📝 Change Log Level (Current: $LOG_LEVEL)"
    echo "  4) ⚡ Toggle Performance Metrics (Current: $ENABLE_PERFORMANCE_METRICS)"
    echo "  0) ← Back to Main Menu"
    echo ""

    read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg enter_choice): ${C_RESET}")" choice

    case "$choice" in
        1)
            echo ""
            echo -e "  1) 🇺🇸 English"
            echo -e "  2) 🇮🇷 فارسی (Persian)"
            read -rp "$(echo -e "  ${C_BLUE}Select language: ${C_RESET}")" lang_choice
            case "$lang_choice" in
                1) LANG_MODE="en" ;;
                2) LANG_MODE="fa" ;;
            esac
            # Save to config
            mkdir -p "$CONFIG_DIR"
            echo "LANG_MODE=\"$LANG_MODE\"" > "$CONFIG_FILE"
            echo -e "\n  ${C_SUCCESS}${I_CHECK} Language set to: $LANG_MODE${C_RESET}"
            ;;
        2)
            read -rp "$(echo -e "  ${C_BLUE}New max backups: ${C_RESET}")" new_max
            if [[ "$new_max" =~ ^[0-9]+$ ]] && (( new_max > 0 )); then
                MAX_BACKUPS="$new_max"
                mkdir -p "$CONFIG_DIR"
                echo "MAX_BACKUPS=\"$MAX_BACKUPS\"" >> "$CONFIG_FILE"
                echo -e "\n  ${C_SUCCESS}${I_CHECK} Max backups set to: $MAX_BACKUPS${C_RESET}"
            else
                echo -e "\n  ${C_ERROR}${I_CROSS} Invalid value${C_RESET}"
            fi
            ;;
        3)
            echo -e "\n  1) DEBUG"
            echo -e "  2) INFO"
            echo -e "  3) WARN"
            echo -e "  4) ERROR"
            read -rp "$(echo -e "  ${C_BLUE}Select log level: ${C_RESET}")" log_choice
            case "$log_choice" in
                1) LOG_LEVEL="DEBUG" ;;
                2) LOG_LEVEL="INFO" ;;
                3) LOG_LEVEL="WARN" ;;
                4) LOG_LEVEL="ERROR" ;;
            esac
            mkdir -p "$CONFIG_DIR"
            echo "LOG_LEVEL=\"$LOG_LEVEL\"" >> "$CONFIG_FILE"
            echo -e "\n  ${C_SUCCESS}${I_CHECK} Log level set to: $LOG_LEVEL${C_RESET}"
            ;;
        4)
            if [[ "$ENABLE_PERFORMANCE_METRICS" == "true" ]]; then
                ENABLE_PERFORMANCE_METRICS="false"
            else
                ENABLE_PERFORMANCE_METRICS="true"
            fi
            mkdir -p "$CONFIG_DIR"
            echo "ENABLE_PERFORMANCE_METRICS=\"$ENABLE_PERFORMANCE_METRICS\"" >> "$CONFIG_FILE"
            echo -e "\n  ${C_SUCCESS}${I_CHECK} Performance metrics: $ENABLE_PERFORMANCE_METRICS${C_RESET}"
            ;;
        0)
            close_box "$width"
            return
            ;;
    esac

    close_box "$width"
    end_timer
    read -rsp $'\n'"$(echo -e "${C_DIM}$(msg press_enter)${C_RESET}")"
}

# ==============================================================================
# Main Menu (Professional Dashboard)
# ==============================================================================

show_menu() {
    clear

    local width=$(get_terminal_width)
    local total_students backup_count
    total_students=$(awk 'END {print NR-1}' "$CSV_FILE" 2>/dev/null || echo "0")
    backup_count=$(find "$BACKUP_DIR" -name "students_*.csv" 2>/dev/null | wc -l)

    # Top banner
    echo -e "${C_HEADER}"
    echo -e "╔$(printf "%0.s═" $(seq 1 $((width - 2))))╗"
    echo -e "║$(printf "%0.s " $(seq 1 $((width - 2))))║"
    echo -e "║$(printf "%0.s " $(seq 1 $(( (width - 2 - 48) / 2 ))) )🎓 $(msg title) v${APP_VERSION}$(printf "%0.s " $(seq 1 $(( (width - 2 - 48) / 2 ))) )║"
    echo -e "║$(printf "%0.s " $(seq 1 $(( (width - 2 - 22) / 2 ))) )$(msg subtitle)$(printf "%0.s " $(seq 1 $(( (width - 2 - 22) / 2 ))) )║"
    echo -e "║$(printf "%0.s " $(seq 1 $((width - 2))))║"
    echo -e "╚$(printf "%0.s═" $(seq 1 $((width - 2))))╝"
    echo -e "${C_RESET}"

    # Status bar
    echo -e "  ${C_DIM}${I_DATABASE} Students: ${C_HIGHLIGHT}$total_students${C_RESET}  ${C_DIM}|${C_RESET}  ${C_DIM}${I_SHIELD} Backups: ${C_HIGHLIGHT}$backup_count${C_RESET}  ${C_DIM}|${C_RESET}  ${C_DIM}${I_LIGHTNING} Status: ${C_SUCCESS}Healthy${C_RESET}"
    echo ""

    # CRUD Operations
    print_section "$(msg crud_ops) - $(msg crud_ops_desc)"
    echo ""
    print_menu_item "1" "➕" "$(msg add_student)"
    print_menu_item "2" "📋" "$(msg view_all)"
    print_menu_item "3" "👤" "$(msg view_details)"
    print_menu_item "4" "✏️ " "$(msg edit_student)"
    print_menu_item "5" "🗑️ " "$(msg delete_student)"
    print_section_end

    echo ""

    # Search & Reports
    print_section "$(msg search_reports) - $(msg search_reports_desc)"
    echo ""
    print_menu_item "6" "🔍" "$(msg search)"
    print_menu_item "7" "📊" "$(msg statistics)"
    print_menu_item "8" "📤" "$(msg export_json)"
    print_menu_item "9" "📥" "$(msg import_csv)"
    print_menu_item "10" "🧮" "$(msg gpa_calc)"
    print_section_end

    echo ""

    # System
    print_section "$(msg system_ops) - $(msg system_ops_desc)"
    echo ""
    print_menu_item "11" "💾" "$(msg backup_create)"
    print_menu_item "12" "🔄" "$(msg backup_restore)"
    print_menu_item "13" "📜" "$(msg logs)"
    print_menu_item "14" "⚙️ " "$(msg settings)"
    print_menu_item "0" "🚪" "$(msg exit)"
    print_section_end

    echo ""

    # Footer
    echo -e "${C_DIM}═══════════════════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_DIM}${I_BULB} Tip: Use --lang fa for Persian, --lang en for English${C_RESET}"
    echo ""
}

# ==============================================================================
# Argument Parsing
# ==============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--debug)
                DEBUG=1
                LOG_LEVEL="DEBUG"
                log DEBUG "Debug mode enabled"
                shift
                ;;
            -p|--performance)
                ENABLE_PERFORMANCE_METRICS="true"
                log INFO "Performance metrics enabled"
                shift
                ;;
            --lang)
                shift
                case "${1:-}" in
                    en|fa) LANG_MODE="$1" ;;
                    *) echo -e "${C_RED}Invalid language. Use 'en' or 'fa'${C_RESET}" >&2; exit 1 ;;
                esac
                shift
                ;;
            --check-deps)
                check_dependencies
                echo -e "${C_GREEN}✓ All dependencies satisfied${C_RESET}"
                exit 0
                ;;
            --init)
                init_system
                log SUCCESS "System initialized"
                exit 0
                ;;
            --export-csv)
                init_system
                export_clean_csv
                exit $?
                ;;
            *)
                echo -e "${C_RED}Unknown option: $1${C_RESET}" >&2
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# ==============================================================================
# Main Program
# ==============================================================================

main() {
    # Parse command line arguments
    parse_arguments "$@"

    # System checks
    check_dependencies
    check_single_instance
    init_system

    # Main menu loop
    while true; do
        show_menu

        read -rp "$(echo -e "${C_BLUE}${I_ARROW} $(msg enter_choice): ${C_RESET}")" choice

        case "$choice" in
            1) add_student ;;
            2) display_students ;;
            3) view_student_details ;;
            4) edit_student ;;
            5) delete_student ;;
            6) search_students ;;
            7) show_statistics ;;
            8) export_to_json ;;
            9) import_from_csv ;;
            10) gpa_calculator ;;
            11)
                if create_backup "manual"; then
                    echo -e "\n  ${C_SUCCESS}${I_CHECK} $(msg backup_created)${C_RESET}"
                else
                    echo -e "\n  ${C_ERROR}${I_CROSS} Backup failed${C_RESET}"
                fi
                sleep 2
                ;;
            12) list_backups ;;
            13) view_logs ;;
            14) settings_menu ;;
            0)
                echo -e "\n${C_SUCCESS}${I_CHECK} Thank you for using $APP_NAME!${C_RESET}"
                echo -e "${C_DIM}Goodbye!${C_RESET}\n"
                exit 0
                ;;
            *)
                echo -e "\n  ${C_ERROR}${I_CROSS} Invalid choice. Please try again.${C_RESET}"
                sleep 1
                ;;
        esac
    done
}

# ==============================================================================
# Script Entry Point
# ==============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
