#!/usr/bin/env bash

# ==============================================================================
# Student Management System - Enterprise Grade v4.0
# Version: 4.0.0
# License: MIT
# Author: Mehdi-dev-sudo  mehdi.khorshidi333@gmail.com
# Repository: github.com/Mehdi-dev-sudo/student-management-bash
# Description: Thread-safe, production-ready student records management
#              with advanced error handling and performance optimization
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
readonly APP_VERSION="4.0.0"
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

readonly DATE_FORMAT='%Y-%m-%d %H:%M:%S'

# ANSI Color Codes
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[1;33m'
readonly C_BLUE='\033[0;34m'
readonly C_CYAN='\033[0;36m'
readonly C_MAGENTA='\033[0;35m'
readonly C_WHITE='\033[1;37m'
readonly C_BOLD='\033[1m'
readonly C_DIM='\033[2m'
readonly C_RESET='\033[0m'

# Unicode Icons
readonly I_CHECK="✓"
readonly I_CROSS="✗"
readonly I_WARN="⚠"
readonly I_INFO="ℹ"
readonly I_ARROW="→"
readonly I_STAR="★"
readonly I_CLOCK="⏱"

# Performance tracking
declare -g OPERATION_START_TIME=0

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
    
    # Write to log file with retry logic
    local retry_count=0
    while (( retry_count < MAX_RETRIES )); do
        if {
            flock -x -w 5 200
            echo "[$timestamp] [$level]${caller_info:-} $msg" >> "$LOG_FILE"
        } 200>"$LOG_FILE.lock" 2>/dev/null; then
            break
        else
            ((retry_count++))
            sleep 0.1
        fi
    done
    
    # Console output with colors
    case "$level" in
        ERROR)
            echo -e "${C_RED}${I_CROSS} $msg${C_RESET}" >&2
            ;;
        SUCCESS)
            echo -e "${C_GREEN}${I_CHECK} $msg${C_RESET}"
            ;;
        WARN)
            echo -e "${C_YELLOW}${I_WARN} $msg${C_RESET}"
            ;;
        INFO)
            echo -e "${C_CYAN}${I_INFO} $msg${C_RESET}"
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
    log INFO "${I_CLOCK} Operation completed in ${elapsed}ms"
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
            FPAT = "([^,]*)|(\"([^\"]|\"\")*\")"
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
    local exclude_id="${2:-}"  # For edit operation
    
    # Format check: 8-10 digits
    [[ "$code" =~ ^[0-9]{8,10}$ ]] || return 1
    
    # Uniqueness check using AWK (field 2 is student code)
    if [[ -f "$CSV_FILE" ]]; then
        awk -F',' -v code="$code" -v exclude_id="$exclude_id" '
            BEGIN { FPAT = "([^,]*)|(\"([^\"]|\"\")*\")" }
            NR > 1 {
                # Skip if this is the record being edited
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
    
    # Remove control characters
    input="${input//[$'\001'-$'\037']}"
    
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
    
    backup_count=$(find "$BACKUP_DIR" -name "students_*.csv" 2>/dev/null | wc -l)
    
    if (( backup_count > MAX_BACKUPS )); then
        log DEBUG "Cleaning up old backups (current: $backup_count, max: $MAX_BACKUPS)"
        
        find "$BACKUP_DIR" -name "students_*.csv" -type f -printf '%T@ %p\n' 2>/dev/null | \
            sort -n | \
            head -n -"$MAX_BACKUPS" | \
            cut -d' ' -f2- | \
            xargs -r rm -f
        
        log DEBUG "Backup cleanup completed"
    fi
}

restore_backup() {
    local backup_file="$1"
    
    [[ ! -f "$backup_file" ]] && die "Backup file not found: $backup_file"
    
    log INFO "Restoring backup: $(basename "$backup_file")"
    
    acquire_lock
    
    # Create safety backup
    if ! cp "$CSV_FILE" "$CSV_FILE.before_restore.$(date +%s)" 2>/dev/null; then
        release_lock
        die "Failed to create safety backup"
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
    
    echo -e "${C_CYAN}${C_BOLD}"
    echo "═══════════════════════════════════════════════"
    echo "          ➕ Add New Student"
    echo "═══════════════════════════════════════════════"
    echo -e "${C_RESET}\n"
    
    local student_code first_name last_name email phone gpa
    
    # Get student code
    while true; do
        read -rp "$(echo -e "${C_BLUE}Student Code (8-10 digits): ${C_RESET}")" student_code
        student_code="$(sanitize_input "$student_code")"
        
        if validate_student_code "$student_code"; then
            break
        else
            log ERROR "Invalid or duplicate student code"
        fi
    done
    
    # Get first name
    while true; do
        read -rp "$(echo -e "${C_BLUE}First Name: ${C_RESET}")" first_name
        first_name="$(sanitize_input "$first_name")"
        [[ -n "$first_name" ]] && break
        log ERROR "First name cannot be empty"
    done
    
    # Get last name
    while true; do
        read -rp "$(echo -e "${C_BLUE}Last Name: ${C_RESET}")" last_name
        last_name="$(sanitize_input "$last_name")"
        [[ -n "$last_name" ]] && break
        log ERROR "Last name cannot be empty"
    done
    
    # Get email
    while true; do
        read -rp "$(echo -e "${C_BLUE}Email: ${C_RESET}")" email
        email="$(sanitize_input "$email")"
        validate_email "$email" && break
        log ERROR "Invalid email format"
    done
    
    # Get phone
    while true; do
        read -rp "$(echo -e "${C_BLUE}Phone (11 digits, starts with 0): ${C_RESET}")" phone
        phone="$(sanitize_input "$phone")"
        validate_phone "$phone" && break
        log ERROR "Invalid phone number"
    done
    
    # Get GPA
    while true; do
        read -rp "$(echo -e "${C_BLUE}GPA (0-20): ${C_RESET}")" gpa
        validate_gpa "$gpa" && break
        log ERROR "GPA must be between 0 and 20"
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
    
    # Atomic append with retry
    local retry_count=0
    while (( retry_count < MAX_RETRIES )); do
        if {
            flock -x -w 5 200
            echo "$new_line" >> "$CSV_FILE"
        } 200>"$CSV_FILE.lock" 2>/dev/null; then
            break
        else
            ((retry_count++))
            sleep 0.1
        fi
    done
    
    if (( retry_count >= MAX_RETRIES )); then
        release_lock
        die "Failed to add student after $MAX_RETRIES attempts"
    fi
    
    release_lock
    
    log SUCCESS "Student added successfully (ID: $student_id)"
    create_backup "auto" &>/dev/null &
    
    end_timer
    read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
}

display_students() {
    clear
    start_timer
    
    echo -e "${C_CYAN}${C_BOLD}"
    echo "═══════════════════════════════════════════════"
    echo "          📋 Student List"
    echo "═══════════════════════════════════════════════"
    echo -e "${C_RESET}\n"
    
    [[ ! -f "$CSV_FILE" ]] && die "Database file not found"
    
    local total_count
    total_count=$(awk 'END {print NR-1}' "$CSV_FILE")
    
    if (( total_count == 0 )); then
        log WARN "No students found"
        read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
        return
    fi
    
    # Display using AWK with proper CSV parsing
    awk -v cyan="$C_CYAN" -v reset="$C_RESET" -v green="$C_GREEN" -v bold="$C_BOLD" '
        BEGIN {
            FPAT = "([^,]*)|(\"([^\"]|\"\")*\")"
            
            # Header
            printf cyan bold "%-5s %-12s %-15s %-15s %-25s %-12s %-8s" reset "\n",
                   "ID", "Code", "First", "Last", "Email", "Phone", "GPA"
            
            printf cyan "%s" reset "\n", \
                   "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
        
        NR > 1 {
            # Remove quotes and unescape
            for (i = 1; i <= NF; i++) {
                gsub(/^"|"$/, "", $i)
                gsub(/""/, "\"", $i)
            }
            
            printf "%-5s %-12s %-15s %-15s %-25s %-12s %-8s\n",
                   $1, $2, substr($3, 1, 15), substr($4, 1, 15), 
                   substr($5, 1, 25), $6, $7
        }
        
        END {
            print ""
            printf green "✓ Total: %d students" reset "\n", NR-1
        }
    ' "$CSV_FILE"
    
    end_timer
    read -rsp $'\n\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
}

view_student_details() {
    clear
    start_timer
    
    echo -e "${C_CYAN}${C_BOLD}"
    echo "═══════════════════════════════════════════════"
    echo "          👤 Student Details"
    echo "═══════════════════════════════════════════════"
    echo -e "${C_RESET}\n"
    
    read -rp "$(echo -e "${C_BLUE}Enter Student ID: ${C_RESET}")" student_id
    student_id="$(sanitize_input "$student_id")"
    
    [[ ! "$student_id" =~ ^[0-9]+$ ]] && {
        log ERROR "Invalid ID format"
        read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
        return 1
    }
    
    local student_data
    student_data=$(awk -F',' -v id="$student_id" '
        BEGIN { FPAT = "([^,]*)|(\"([^\"]|\"\")*\")" }
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
        log ERROR "Student not found (ID: $student_id)"
        read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
        return 1
    fi
    
    # Parse fields
    local -a fields
    mapfile -t fields <<< "$student_data"
    
    echo ""
    echo -e "${C_CYAN}${C_BOLD}ID:${C_RESET}              ${fields[0]}"
    echo -e "${C_CYAN}${C_BOLD}Student Code:${C_RESET}    ${fields[1]}"
    echo -e "${C_CYAN}${C_BOLD}Name:${C_RESET}            ${fields[2]} ${fields[3]}"
    echo -e "${C_CYAN}${C_BOLD}Email:${C_RESET}           ${fields[4]}"
    echo -e "${C_CYAN}${C_BOLD}Phone:${C_RESET}           ${fields[5]}"
    echo -e "${C_CYAN}${C_BOLD}GPA:${C_RESET}             ${fields[6]}"
    echo -e "${C_CYAN}${C_BOLD}Registered:${C_RESET}      ${fields[7]}"
    
    end_timer
    read -rsp $'\n\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
}

edit_student() {
    clear
    start_timer
    
    echo -e "${C_CYAN}${C_BOLD}"
    echo "═══════════════════════════════════════════════"
    echo "          ✏️  Edit Student"
    echo "═══════════════════════════════════════════════"
    echo -e "${C_RESET}\n"
    
    read -rp "$(echo -e "${C_BLUE}Enter Student ID: ${C_RESET}")" student_id
    student_id="$(sanitize_input "$student_id")"
    
    [[ ! "$student_id" =~ ^[0-9]+$ ]] && {
        log ERROR "Invalid ID format"
        read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
        return 1
    }
    
    # Get current data
    local current_data
    current_data=$(awk -F',' -v id="$student_id" '
        BEGIN { FPAT = "([^,]*)|(\"([^\"]|\"\")*\")" }
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
        log ERROR "Student not found"
        read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
        return 1
    fi
    
    local -a old_fields
    mapfile -t old_fields <<< "$current_data"
    
    echo -e "\n${C_YELLOW}Current Information:${C_RESET}"
    echo "Code: ${old_fields[1]} | Name: ${old_fields[2]} ${old_fields[3]} | GPA: ${old_fields[6]}"
    echo ""
    
    # Get new values
    local new_code new_fname new_lname new_email new_phone new_gpa
    
    # Student code
    while true; do
        read -rp "$(echo -e "${C_BLUE}New Student Code (Enter to keep): ${C_RESET}")" new_code
        new_code="$(sanitize_input "$new_code")"
        
        if [[ -z "$new_code" ]]; then
            new_code="${old_fields[1]}"
            break
        elif validate_student_code "$new_code" "$student_id"; then
            break
        else
            log ERROR "Invalid or duplicate student code"
        fi
    done
    
    # First name
    read -rp "$(echo -e "${C_BLUE}New First Name (Enter to keep): ${C_RESET}")" new_fname
    new_fname="$(sanitize_input "$new_fname")"
    [[ -z "$new_fname" ]] && new_fname="${old_fields[2]}"
    
    # Last name
    read -rp "$(echo -e "${C_BLUE}New Last Name (Enter to keep): ${C_RESET}")" new_lname
    new_lname="$(sanitize_input "$new_lname")"
    [[ -z "$new_lname" ]] && new_lname="${old_fields[3]}"
    
    # Email
    while true; do
        read -rp "$(echo -e "${C_BLUE}New Email (Enter to keep): ${C_RESET}")" new_email
        new_email="$(sanitize_input "$new_email")"
        
        if [[ -z "$new_email" ]]; then
            new_email="${old_fields[4]}"
            break
        elif validate_email "$new_email"; then
            break
        else
            log ERROR "Invalid email format"
        fi
    done
    
    # Phone
    while true; do
        read -rp "$(echo -e "${C_BLUE}New Phone (Enter to keep): ${C_RESET}")" new_phone
        new_phone="$(sanitize_input "$new_phone")"
        
        if [[ -z "$new_phone" ]]; then
            new_phone="${old_fields[5]}"
            break
        elif validate_phone "$new_phone"; then
            break
        else
            log ERROR "Invalid phone number"
        fi
    done
    
    # GPA
    while true; do
        read -rp "$(echo -e "${C_BLUE}New GPA (Enter to keep): ${C_RESET}")" new_gpa
        
        if [[ -z "$new_gpa" ]]; then
            new_gpa="${old_fields[6]}"
            break
        elif validate_gpa "$new_gpa"; then
            break
        else
            log ERROR "Invalid GPA"
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
    
    awk -F',' -v id="$student_id" -v newline="$new_line" '
        BEGIN { FPAT = "([^,]*)|(\"([^\"]|\"\")*\")" }
        NR == 1 { print; next }
        $1 == id { print newline; next }
        { print }
    ' "$CSV_FILE" > "$temp_file"
    
    if mv "$temp_file" "$CSV_FILE" 2>/dev/null; then
        release_lock
        log SUCCESS "Student updated successfully"
        create_backup "auto" &>/dev/null &
    else
        rm -f "$temp_file"
        release_lock
        log ERROR "Failed to update student"
    fi
    
    end_timer
    read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
}

delete_student() {
    clear
    start_timer
    
    echo -e "${C_CYAN}${C_BOLD}"
    echo "═══════════════════════════════════════════════"
    echo "          🗑️  Delete Student"
    echo "═══════════════════════════════════════════════"
    echo -e "${C_RESET}\n"
    
    read -rp "$(echo -e "${C_BLUE}Enter Student ID: ${C_RESET}")" student_id
    student_id="$(sanitize_input "$student_id")"
    
    [[ ! "$student_id" =~ ^[0-9]+$ ]] && {
        log ERROR "Invalid ID format"
        read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
        return 1
    }
    
    # Get student info
    local student_data
    student_data=$(awk -F',' -v id="$student_id" '
        BEGIN { FPAT = "([^,]*)|(\"([^\"]|\"\")*\")" }
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
        log ERROR "Student not found"
        read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
        return 1
    fi
    
    local -a fields
    mapfile -t fields <<< "$student_data"
    
    echo -e "\n${C_YELLOW}${I_WARN} Are you sure you want to delete this student?${C_RESET}"
    echo "ID: ${fields[0]} | Code: ${fields[1]}"
    echo "Name: ${fields[2]} ${fields[3]}"
    echo -e "${C_RED}${C_BOLD}This action cannot be undone!${C_RESET}\n"
    
    read -rp "$(echo -e "${C_BLUE}Type 'DELETE' to confirm: ${C_RESET}")" confirm
    
    if [[ "$confirm" != "DELETE" ]]; then
        log WARN "Operation cancelled"
        read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
        return
    fi
    
    # Delete record
    acquire_lock
    
    local temp_file
    temp_file="$(mktemp)"
    
    awk -F',' -v id="$student_id" '
        BEGIN { FPAT = "([^,]*)|(\"([^\"]|\"\")*\")" }
        NR == 1 { print; next }
        $1 != id { print }
    ' "$CSV_FILE" > "$temp_file"
    
    if mv "$temp_file" "$CSV_FILE" 2>/dev/null; then
        release_lock
        log SUCCESS "Student deleted successfully"
        create_backup "auto" &>/dev/null &
    else
        rm -f "$temp_file"
        release_lock
        log ERROR "Failed to delete student"
    fi
    
    end_timer
    read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
}

search_students() {
    clear
    start_timer
    
    echo -e "${C_CYAN}${C_BOLD}"
    echo "═══════════════════════════════════════════════"
    echo "          🔍 Search Students"
    echo "═══════════════════════════════════════════════"
    echo -e "${C_RESET}\n"
    
    read -rp "$(echo -e "${C_BLUE}Search term (name, code, email): ${C_RESET}")" search_term
    search_term="$(sanitize_input "$search_term")"
    
    [[ -z "$search_term" ]] && {
        log ERROR "Search term cannot be empty"
        read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
        return
    }
    
    echo -e "\n${C_CYAN}Search Results:${C_RESET}\n"
    
    local results
    results=$(awk -F',' -v term="$search_term" -v cyan="$C_CYAN" -v reset="$C_RESET" -v green="$C_GREEN" -v bold="$C_BOLD" '
        BEGIN {
            FPAT = "([^,]*)|(\"([^\"]|\"\")*\")"
            IGNORECASE = 1
            found = 0
        }
        
        NR == 1 {
            printf cyan bold "%-5s %-12s %-15s %-15s %-25s %-8s" reset "\n",
                   "ID", "Code", "First", "Last", "Email", "GPA"
            printf cyan "%s" reset "\n", \
                   "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            next
        }
        
        {
            # Unescape fields
            for (i = 1; i <= NF; i++) {
                gsub(/^"|"$/, "", $i)
                gsub(/""/, "\"", $i)
            }
            
            # Search in code, first name, last name, email
            if ($2 ~ term || $3 ~ term || $4 ~ term || $5 ~ term) {
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
    
    end_timer
    read -rsp $'\n\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
}

# ==============================================================================
# Statistics & Reporting
# ==============================================================================

show_statistics() {
    clear
    start_timer
    
    echo -e "${C_CYAN}${C_BOLD}"
    echo "═══════════════════════════════════════════════"
    echo "          📊 Statistics"
    echo "═══════════════════════════════════════════════"
    echo -e "${C_RESET}\n"
    
    [[ ! -f "$CSV_FILE" ]] && die "Database file not found"
    
    awk -F',' -v green="$C_GREEN" -v yellow="$C_YELLOW" -v red="$C_RED" -v cyan="$C_CYAN" -v reset="$C_RESET" '
        BEGIN {
            FPAT = "([^,]*)|(\"([^\"]|\"\")*\")"
            total = 0
            sum_gpa = 0
            max_gpa = 0
            min_gpa = 20
        }
        
        NR > 1 {
            total++
            
            # Clean GPA field
            gpa = $7
            gsub(/^"|"$/, "", gpa)
            gpa = gpa + 0
            
            sum_gpa += gpa
            if (gpa > max_gpa) max_gpa = gpa
            if (gpa < min_gpa) min_gpa = gpa
            
            if (gpa >= 17) excellent++
            else if (gpa >= 14) good++
            else if (gpa >= 12) average++
            else poor++
        }
        
        END {
            if (total == 0) {
                print "No data available"
                exit
            }
            
            avg_gpa = sum_gpa / total
            
            printf cyan "Total Students:      " reset "%d\n", total
            printf cyan "Average GPA:         " reset "%.2f\n", avg_gpa
            printf cyan "Highest GPA:         " reset green "%.2f" reset "\n", max_gpa
            printf cyan "Lowest GPA:          " reset red "%.2f" reset "\n\n", min_gpa
            
            print cyan "GPA Distribution:" reset
            printf "  " green "Excellent (≥17):   " reset "%d (%.1f%%)\n", excellent, (excellent/total)*100
            printf "  " cyan "Good (14-16.99):   " reset "%d (%.1f%%)\n", good, (good/total)*100
            printf "  " yellow "Average (12-13.99):" reset "%d (%.1f%%)\n", average, (average/total)*100
            printf "  " red "Poor (<12):        " reset "%d (%.1f%%)\n", poor, (poor/total)*100
        }
    ' "$CSV_FILE"
    
    end_timer
    read -rsp $'\n\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
}

export_to_json() {
    clear
    start_timer
    
    echo -e "${C_CYAN}${C_BOLD}"
    echo "═══════════════════════════════════════════════"
    echo "          📤 Export to JSON"
    echo "═══════════════════════════════════════════════"
    echo -e "${C_RESET}\n"
    
    local output_file="$DATA_DIR/students_export_$(date +%Y%m%d_%H%M%S).json"
    
    log INFO "Exporting to JSON..."
    
    awk -F',' '
        BEGIN {
            FPAT = "([^,]*)|(\"([^\"]|\"\")*\")"
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
            printf "  \"version\": \"4.0.0\"\n"
            print "}"
        }
    ' "$CSV_FILE" > "$output_file"
    
    log SUCCESS "Exported to: $output_file"
    
    end_timer
    read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
}

# ==============================================================================
# Help & Version
# ==============================================================================

show_help() {
    cat << EOF
${C_CYAN}${C_BOLD}$APP_NAME v$APP_VERSION${C_RESET}

${C_BOLD}USAGE:${C_RESET}
    $SCRIPT_NAME [OPTIONS]

${C_BOLD}OPTIONS:${C_RESET}
    -h, --help              Show this help message
    -v, --version           Show version information
    -d, --debug             Enable debug mode
    -p, --performance       Enable performance metrics
    --check-deps            Check system dependencies
    --init                  Initialize/repair system directories

${C_BOLD}CONFIGURATION:${C_RESET}
    Config file: $CONFIG_FILE
    
    Available settings:
      MAX_BACKUPS=10
      LOCK_TIMEOUT=10
      MAX_RETRIES=3
      LOG_LEVEL=INFO
      ENABLE_PERFORMANCE_METRICS=false

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
    • JSON export capability
    • Performance metrics tracking
    • Single instance enforcement

${C_BOLD}EXAMPLES:${C_RESET}
    # Run normally
    $SCRIPT_NAME

    # Enable debug mode
    DEBUG=1 $SCRIPT_NAME --debug

    # Enable performance metrics
    $SCRIPT_NAME --performance

    # Check dependencies
    $SCRIPT_NAME --check-deps

${C_BOLD}AUTHOR:${C_RESET}
    Mehdi Khorshidi Far <mehdi.khorshidi333@gmail.com>

${C_BOLD}LICENSE:${C_RESET}
    MIT License

${C_BOLD}REPOSITORY:${C_RESET}
    github.com/username/student-mgmt

EOF
}

show_version() {
    echo -e "${C_CYAN}${C_BOLD}$APP_NAME${C_RESET}"
    echo -e "Version: ${C_GREEN}$APP_VERSION${C_RESET}"
    echo ""
    echo "Bash version: ${BASH_VERSION}"
    echo "System: $(uname -s) $(uname -r)"
    echo ""
}

# ==============================================================================
# System Management
# ==============================================================================

view_logs() {
    clear
    echo -e "${C_CYAN}${C_BOLD}"
    echo "═══════════════════════════════════════════════"
    echo "          📜 Recent Logs (Last 50 lines)"
    echo "═══════════════════════════════════════════════"
    echo -e "${C_RESET}\n"
    
    if [[ -f "$LOG_FILE" ]]; then
        tail -n 50 "$LOG_FILE" | while IFS= read -r line; do
            # Colorize log levels
            if [[ "$line" =~ \[ERROR\] ]]; then
                echo -e "${C_RED}$line${C_RESET}"
            elif [[ "$line" =~ \[WARN\] ]]; then
                echo -e "${C_YELLOW}$line${C_RESET}"
            elif [[ "$line" =~ \[SUCCESS\] ]]; then
                echo -e "${C_GREEN}$line${C_RESET}"
            elif [[ "$line" =~ \[DEBUG\] ]]; then
                echo -e "${C_MAGENTA}${C_DIM}$line${C_RESET}"
            else
                echo "$line"
            fi
        done
    else
        log WARN "No logs found"
    fi
    
    read -rsp $'\n\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
}

list_backups() {
    clear
    echo -e "${C_CYAN}${C_BOLD}"
    echo "═══════════════════════════════════════════════"
    echo "          💾 Available Backups"
    echo "═══════════════════════════════════════════════"
    echo -e "${C_RESET}\n"
    
    local backups
    backups=$(find "$BACKUP_DIR" -name "students_*.csv" -type f -printf '%T@ %p\n' 2>/dev/null | \
              sort -rn | \
              awk '{$1=""; print $0}' | \
              sed 's/^ //')
    
    if [[ -z "$backups" ]]; then
        log WARN "No backups found"
        read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
        return
    fi
    
    echo "$backups" | nl -w2 -s') ' | while IFS= read -r line; do
        # Highlight recent backups (less than 1 day old)
        if echo "$line" | grep -q "$(date +%Y%m%d)"; then
            echo -e "${C_GREEN}$line${C_RESET}"
        else
            echo "$line"
        fi
    done
    
    echo ""
    
    read -rp "$(echo -e "${C_BLUE}Enter backup number to restore (0 to cancel): ${C_RESET}")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice > 0 )); then
        local selected_backup
        selected_backup=$(echo "$backups" | sed -n "${choice}p")
        
        if [[ -n "$selected_backup" ]]; then
            restore_backup "$selected_backup"
        else
            log ERROR "Invalid selection"
        fi
    fi
    
    read -rsp $'\n'"$(echo -e "${C_CYAN}Press Enter to continue...${C_RESET}")"
}

# ==============================================================================
# Main Menu
# ==============================================================================

show_menu() {
    clear
    echo -e "${C_CYAN}${C_BOLD}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════╗
║                                                   ║
║        🎓 Student Management System v4.0.0        ║
║             Enterprise Grade Edition              ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
EOF
    echo -e "${C_RESET}"
    
    echo -e "${C_BLUE}${C_BOLD}📝 CRUD Operations:${C_RESET}"
    echo "  1) ➕ Add New Student"
    echo "  2) 📋 Display All Students"
    echo "  3) 👤 View Student Details"
    echo "  4) ✏️  Edit Student"
    echo "  5) 🗑️  Delete Student"
    echo ""
    echo -e "${C_BLUE}${C_BOLD}🔍 Search & Reports:${C_RESET}"
    echo "  6) 🔍 Search Students"
    echo "  7) 📊 Show Statistics"
    echo "  8) 📤 Export to JSON"
    echo ""
    echo -e "${C_BLUE}${C_BOLD}⚙️  System:${C_RESET}"
    echo "  9) 💾 Create Manual Backup"
    echo " 10) 🔄 Restore Backup"
    echo " 11) 📜 View Logs"
    echo "  0) 🚪 Exit"
    echo ""
    echo -e "${C_CYAN}═══════════════════════════════════════════════════${C_RESET}"
    
    # Show system status
    local total_students backup_count
    total_students=$(awk 'END {print NR-1}' "$CSV_FILE" 2>/dev/null || echo "0")
    backup_count=$(find "$BACKUP_DIR" -name "students_*.csv" 2>/dev/null | wc -l)
    
    echo -e "${C_DIM}Students: $total_students | Backups: $backup_count${C_RESET}"
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
        
        read -rp "$(echo -e "${C_BLUE}Enter your choice: ${C_RESET}")" choice
        
        case "$choice" in
            1) add_student ;;
            2) display_students ;;
            3) view_student_details ;;
            4) edit_student ;;
            5) delete_student ;;
            6) search_students ;;
            7) show_statistics ;;
            8) export_to_json ;;
            9) 
                if create_backup "manual"; then
                    log SUCCESS "Manual backup created"
                else
                    log ERROR "Backup failed"
                fi
                sleep 2
                ;;
            10) list_backups ;;
            11) view_logs ;;
            0)
                echo -e "\n${C_GREEN}${I_CHECK} Thank you for using $APP_NAME!${C_RESET}"
                echo -e "${C_DIM}Goodbye!${C_RESET}\n"
                exit 0
                ;;
            *)
                log ERROR "Invalid choice. Please try again."
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
