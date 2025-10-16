#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$SCRIPT_DIR/tmp"
BACKUP_DIR="$SCRIPT_DIR/backups"
BACKUP_SESSION=""
OPERATIONS_FILE=""
CREATED_FILES=()
LOG_LEVEL="ERROR"

# Global arrays for operation metadata and absolute line number support
declare -a OPERATION_ORIGINAL_INDEX
declare -a OPERATION_PRIORITY
declare -a OPERATION_SORT_KEY
declare -a OPERATION_FILE_GROUP
declare -a EXECUTION_ORDER
declare -a ORIGINAL_OPERATIONS

log_info() {
    if [[ "$LOG_LEVEL" == "INFO" || "$LOG_LEVEL" == "DEBUG" ]]; then
        echo "[INFO] $*" >&2
    fi
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_debug() {
    if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Helper functions for operation metadata
get_operation_priority() {
    local op_type="$1"
    local line_number="$2"

    case "$op_type" in
        "create")
            echo "0"
            ;;
        "delete"|"replace"|"insert")
            # Higher line numbers get higher priority (executed first)
            # Use negative line number so higher lines sort first
            echo "1_$(printf "%010d" $((999999 - line_number)))"
            ;;
        "patch")
            echo "2"
            ;;
        *)
            echo "999"
            ;;
    esac
}

get_operation_sort_key() {
    local operation="$1"
    log_debug "get_operation_sort_key: operation='$operation'"
    local op_type=$(echo "$operation" | jq -r '.type')
    local file=$(echo "$operation" | jq -r '.file')
    log_debug "get_operation_sort_key: op_type='$op_type', file='$file'"

    local line_number=0
    case "$op_type" in
        "replace"|"delete")
            line_number=$(echo "$operation" | jq -r '.start_line // 0')
            ;;
        "insert")
            line_number=$(echo "$operation" | jq -r '.line // 0')
            ;;
    esac
    log_debug "get_operation_sort_key: line_number='$line_number'"

    local priority=$(get_operation_priority "$op_type" "$line_number")
    log_debug "get_operation_sort_key: priority='$priority'"
    echo "${file}|${priority}|${line_number}"
}

detect_line_conflicts() {
    local json_file="$1"
    mapfile -t operations < <(jq -c '.operations[]' "$json_file")

    # Group operations by file and check for conflicts
    local -A file_operations=()
    local index=1

    for operation in "${operations[@]}"; do
        local file=$(echo "$operation" | jq -r '.file')
        local op_type=$(echo "$operation" | jq -r '.type')

        # Only check line-based operations
        if [[ "$op_type" == "delete" || "$op_type" == "replace" || "$op_type" == "insert" ]]; then
            if [[ -z "${file_operations[$file]:-}" ]]; then
                file_operations["$file"]=""
            fi
            file_operations["$file"]+="$index:$operation"$'\n'
        fi
        ((index++))
    done

    # Check each file for conflicts
    for file in "${!file_operations[@]}"; do
        local -a ops_array
        mapfile -t ops_array <<< "${file_operations[$file]}"
        local -a line_ranges=()

        for op_data in "${ops_array[@]}"; do
            if [[ -z "$op_data" ]]; then continue; fi
            local op_index="${op_data%%:*}"
            local op_json="${op_data#*:}"
            local op_type=$(echo "$op_json" | jq -r '.type')

            case "$op_type" in
                "delete"|"replace")
                    local start_line=$(echo "$op_json" | jq -r '.start_line')
                    local end_line=$(echo "$op_json" | jq -r '.end_line')
                    line_ranges+=("$op_index:$start_line:$end_line:$op_type")
                    ;;
                "insert")
                    local line=$(echo "$op_json" | jq -r '.line')
                    # Insert conflicts if it's within a delete/replace range
                    line_ranges+=("$op_index:$line:$line:insert")
                    ;;
            esac
        done

        # Check for overlaps
        for ((i=0; i<${#line_ranges[@]}; i++)); do
            for ((j=i+1; j<${#line_ranges[@]}; j++)); do
                local range1="${line_ranges[$i]}"
                local range2="${line_ranges[$j]}"

                local idx1="${range1%%:*}"; range1="${range1#*:}"
                local start1="${range1%%:*}"; range1="${range1#*:}"
                local end1="${range1%%:*}"; range1="${range1#*:}"
                local type1="${range1}"

                local idx2="${range2%%:*}"; range2="${range2#*:}"
                local start2="${range2%%:*}"; range2="${range2#*:}"
                local end2="${range2%%:*}"; range2="${range2#*:}"
                local type2="${range2}"

                # Check for overlap
                if [[ "$start1" -le "$end2" && "$start2" -le "$end1" ]]; then
                    # Allow multiple inserts on the same line
                    if [[ "$type1" == "insert" && "$type2" == "insert" ]]; then
                        continue
                    fi

                    # Special case: adjacent operations are not conflicts
                    if [[ "$end1" -eq $((start2 - 1)) || "$end2" -eq $((start1 - 1)) ]]; then
                        continue
                    fi

                    error_exit "Operation $idx2 conflicts with operation $idx1: line range $start2-$end2 overlaps with $type1 range $start1-$end1 in file $file"
                fi
            done
        done
    done

    log_debug "No operation conflicts detected"
}

sort_operations_by_file() {
    local json_file="$1"
    mapfile -t operations < <(jq -c '.operations[]' "$json_file")

    # Clear previous data
    OPERATION_ORIGINAL_INDEX=()
    OPERATION_PRIORITY=()
    OPERATION_SORT_KEY=()
    OPERATION_FILE_GROUP=()
    EXECUTION_ORDER=()
    ORIGINAL_OPERATIONS=()

    # Store original operations and create metadata
    local index=1
    for operation in "${operations[@]}"; do
        ORIGINAL_OPERATIONS+=("$operation")
        OPERATION_ORIGINAL_INDEX+=("$index")

        local sort_key=$(get_operation_sort_key "$operation")
        OPERATION_SORT_KEY+=("$sort_key")

        local file=$(echo "$operation" | jq -r '.file')
        OPERATION_FILE_GROUP+=("$file")

        ((index++))
    done

    # Create execution order by sorting
    local -a indexed_operations=()
    for ((i=0; i<${#ORIGINAL_OPERATIONS[@]}; i++)); do
        indexed_operations+=("$i:${OPERATION_SORT_KEY[$i]}")
    done

    # Sort by sort key
    local sorted_indices
    sorted_indices=($(printf '%s\n' "${indexed_operations[@]}" | sort -t'|' -k1,1 -k2,2r | cut -d':' -f1))

    EXECUTION_ORDER=("${sorted_indices[@]}")

    log_debug "Generated execution order: ${EXECUTION_ORDER[*]}"
}

error_exit() {
    local exit_code=${2:-1}
    log_error "$1"
    if [[ -n "$BACKUP_SESSION" ]]; then
        rollback_changes
    fi
    exit "$exit_code"
}

validate_json() {
    local json_file="$1"

    if [[ ! -f "$json_file" ]]; then
        error_exit "JSON file not found: $json_file"
    fi

    if ! jq empty "$json_file" 2>/dev/null; then
        error_exit "Invalid JSON syntax in file: $json_file"
    fi

    if ! jq -e '.operations' "$json_file" >/dev/null 2>&1; then
        error_exit "Missing 'operations' array in JSON"
    fi

    if ! jq -e '.operations | type == "array"' "$json_file" >/dev/null 2>&1; then
        error_exit "Field 'operations' must be an array"
    fi

    local op_count
    op_count=$(jq '.operations | length' "$json_file")
    if [[ "$op_count" -eq 0 ]]; then
        error_exit "Operations array cannot be empty"
    fi

    log_info "JSON validation passed: $op_count operations found"
}

validate_create() {
    local op="$1"
    local index="$2"

    local file
    file=$(echo "$op" | jq -r '.file // empty')
    if [[ -z "$file" ]]; then
        error_exit "Operation $index (create): Missing required field 'file'"
    fi

    if [[ "${file:0:1}" != "/" ]]; then
        error_exit "Operation $index (create): Field 'file' must be absolute path: $file"
    fi

    if echo "$op" | jq -e '.content // empty' >/dev/null; then
        if ! echo "$op" | jq -e '.content | type == "string"' >/dev/null; then
            error_exit "Operation $index (create): Field 'content' must be string"
        fi
    fi

    if [[ -f "$file" ]]; then
        error_exit "Operation $index (create): File already exists: $file"
    fi
}

validate_replace() {
    local op="$1"
    local index="$2"
    local created_files_str="${3:-}"
    read -r -a created_files <<< "$created_files_str"

    local file
    file=$(echo "$op" | jq -r '.file // empty')
    if [[ -z "$file" ]]; then
        error_exit "Operation $index (replace): Missing required field 'file'"
    fi

    if [[ "${file:0:1}" != "/" ]]; then
        error_exit "Operation $index (replace): Field 'file' must be absolute path: $file"
    fi

    local file_exists=false
    if [[ -f "$file" ]]; then
        file_exists=true
    else
        for created_file in "${created_files[@]}"; do
            if [[ "$created_file" == "$file" ]]; then
                file_exists=true
                break
            fi
        done
    fi

    if [[ "$file_exists" == "false" ]]; then
        error_exit "Operation $index (replace): File does not exist: $file"
    fi

    local start_line end_line
    start_line=$(echo "$op" | jq -r '.start_line // empty')
    end_line=$(echo "$op" | jq -r '.end_line // empty')

    if [[ -z "$start_line" ]]; then
        error_exit "Operation $index (replace): Missing required field 'start_line'"
    fi

    if [[ -z "$end_line" ]]; then
        error_exit "Operation $index (replace): Missing required field 'end_line'"
    fi

    if ! [[ "$start_line" =~ ^[1-9][0-9]*$ ]]; then
        error_exit "Operation $index (replace): Field 'start_line' must be positive integer: $start_line"
    fi

    if ! [[ "$end_line" =~ ^[1-9][0-9]*$ ]]; then
        error_exit "Operation $index (replace): Field 'end_line' must be positive integer: $end_line"
    fi

    if [[ "$start_line" -gt "$end_line" ]]; then
        error_exit "Operation $index (replace): start_line ($start_line) must be <= end_line ($end_line)"
    fi

    if echo "$op" | jq -e '.content // empty' >/dev/null; then
        if ! echo "$op" | jq -e '.content | type == "string"' >/dev/null; then
            error_exit "Operation $index (replace): Field 'content' must be string"
        fi
    fi

    if [[ -f "$file" ]]; then
        local file_lines
        file_lines=$(wc -l <"$file")
        if [[ "$start_line" -gt "$file_lines" ]]; then
            error_exit "Operation $index (replace): start_line ($start_line) exceeds file length ($file_lines lines)"
        fi
    fi
}

validate_insert() {
    local op="$1"
    local index="$2"
    local created_files_str="${3:-}"
    read -r -a created_files <<< "$created_files_str"

    local file
    file=$(echo "$op" | jq -r '.file // empty')
    if [[ -z "$file" ]]; then
        error_exit "Operation $index (insert): Missing required field 'file'"
    fi

    if [[ "${file:0:1}" != "/" ]]; then
        error_exit "Operation $index (insert): Field 'file' must be absolute path: $file"
    fi

    local file_exists=false
    if [[ -f "$file" ]]; then
        file_exists=true
    else
        for created_file in "${created_files[@]}"; do
            if [[ "$created_file" == "$file" ]]; then
                file_exists=true
                break
            fi
        done
    fi

    if [[ "$file_exists" == "false" ]]; then
        error_exit "Operation $index (insert): File does not exist: $file"
    fi

    local line
    line=$(echo "$op" | jq -r '.line // empty')
    if [[ -z "$line" ]]; then
        error_exit "Operation $index (insert): Missing required field 'line'"
    fi

    if ! [[ "$line" =~ ^-?[0-9]+$ ]]; then
        error_exit "Operation $index (insert): Field 'line' must be integer: $line"
    fi

    if echo "$op" | jq -e '.content // empty' >/dev/null; then
        if ! echo "$op" | jq -e '.content | type == "string"' >/dev/null; then
            error_exit "Operation $index (insert): Field 'content' must be string"
        fi
    fi

    if [[ -f "$file" ]]; then
        local file_lines
        file_lines=$(wc -l <"$file")
        if [[ "$line" -gt $((file_lines + 1)) && "$line" -ne -1 ]]; then
            error_exit "Operation $index (insert): line ($line) exceeds file length + 1 ($((file_lines + 1)) lines)"
        fi
    fi
}

validate_delete() {
    local op="$1"
    local index="$2"
    local created_files_str="${3:-}"
    read -r -a created_files <<< "$created_files_str"

    local file
    file=$(echo "$op" | jq -r '.file // empty')
    if [[ -z "$file" ]]; then
        error_exit "Operation $index (delete): Missing required field 'file'"
    fi

    if [[ "${file:0:1}" != "/" ]]; then
        error_exit "Operation $index (delete): Field 'file' must be absolute path: $file"
    fi

    local file_exists=false
    if [[ -f "$file" ]]; then
        file_exists=true
    else
        for created_file in "${created_files[@]}"; do
            if [[ "$created_file" == "$file" ]]; then
                file_exists=true
                break
            fi
        done
    fi

    if [[ "$file_exists" == "false" ]]; then
        error_exit "Operation $index (delete): File does not exist: $file"
    fi

    local start_line end_line
    start_line=$(echo "$op" | jq -r '.start_line // empty')
    end_line=$(echo "$op" | jq -r '.end_line // empty')

    if [[ -z "$start_line" ]]; then
        error_exit "Operation $index (delete): Missing required field 'start_line'"
    fi

    if [[ -z "$end_line" ]]; then
        error_exit "Operation $index (delete): Missing required field 'end_line'"
    fi

    if ! [[ "$start_line" =~ ^[1-9][0-9]*$ ]]; then
        error_exit "Operation $index (delete): Field 'start_line' must be positive integer: $start_line"
    fi

    if ! [[ "$end_line" =~ ^[1-9][0-9]*$ ]]; then
        error_exit "Operation $index (delete): Field 'end_line' must be positive integer: $end_line"
    fi

    if [[ "$start_line" -gt "$end_line" ]]; then
        error_exit "Operation $index (delete): start_line ($start_line) must be <= end_line ($end_line)"
    fi

    if [[ -f "$file" ]]; then
        local file_lines
        file_lines=$(wc -l < "$file")
        if [[ "$end_line" -gt "$file_lines" ]]; then
            error_exit "Operation $index (delete): Line range $start_line-$end_line exceeds file length ($file_lines lines)"
        fi
    fi
}

validate_patch() {
    local op="$1"
    local index="$2"
    local created_files_str="${3:-}"
    read -r -a created_files <<< "$created_files_str"

    local file
    file=$(echo "$op" | jq -r '.file // empty')
    if [[ -z "$file" ]]; then
        error_exit "Operation $index (patch): Missing required field 'file'"
    fi

    if [[ "${file:0:1}" != "/" ]]; then
        error_exit "Operation $index (patch): Field 'file' must be absolute path: $file"
    fi

    local file_exists=false
    if [[ -f "$file" ]]; then
        file_exists=true
    else
        for created_file in "${created_files[@]}"; do
            if [[ "$created_file" == "$file" ]]; then
                file_exists=true
                break
            fi
        done
    fi

    if [[ "$file_exists" == "false" ]]; then
        error_exit "Operation $index (patch): File does not exist: $file"
    fi

    local find_str
    find_str=$(echo "$op" | jq -r '.find // empty')
    if [[ -z "$find_str" ]]; then
        error_exit "Operation $index (patch): Missing or empty required field 'find'"
    fi

    if echo "$op" | jq -e '.replace // empty' >/dev/null; then
        if ! echo "$op" | jq -e '.replace | type == "string"' >/dev/null; then
            error_exit "Operation $index (patch): Field 'replace' must be string"
        fi
    fi

    if echo "$op" | jq -e '.all // empty' >/dev/null; then
        if ! echo "$op" | jq -e '.all | type == "boolean"' >/dev/null; then
            error_exit "Operation $index (patch): Field 'all' must be boolean"
        fi
    fi
}

validate_operations() {
    local json_file="$1"
    mapfile -t operations < <(jq -c '.operations[]' "$json_file")

    local created_files=()
    local index=1
    for operation in "${operations[@]}"; do
        local op_type
        op_type=$(echo "$operation" | jq -r '.type // empty')

        if [[ -z "$op_type" ]]; then
            error_exit "Operation $index: Missing required field 'type'"
        fi

        case "$op_type" in
            "create")
                validate_create "$operation" "$index"
                local file
                file=$(echo "$operation" | jq -r '.file')
                created_files+=("$file")
                ;;
            "replace")
                if [[ ${#created_files[@]} -eq 0 ]]; then
                    validate_replace "$operation" "$index"
                else
                    validate_replace "$operation" "$index" "${created_files[*]}"
                fi
                ;;
            "insert")
                if [[ ${#created_files[@]} -eq 0 ]]; then
                    validate_insert "$operation" "$index"
                else
                    validate_insert "$operation" "$index" "${created_files[*]}"
                fi
                ;;
            "delete")
                if [[ ${#created_files[@]} -eq 0 ]]; then
                    validate_delete "$operation" "$index"
                else
                    validate_delete "$operation" "$index" "${created_files[*]}"
                fi
                ;;
            "patch")
                if [[ ${#created_files[@]} -eq 0 ]]; then
                    validate_patch "$operation" "$index"
                else
                    validate_patch "$operation" "$index" "${created_files[*]}"
                fi
                ;;
            *)
                error_exit "Operation $index: Unknown operation type: $op_type"
                ;;
        esac

        ((index++))
    done

    # Check for conflicts after all operations are validated
    detect_line_conflicts "$json_file"

    log_info "All operations validated successfully"
}

create_backup() {
    local json_file="$1"

    BACKUP_SESSION="backup_$(date +%Y%m%d_%H%M%S)_$$"
    local backup_path="$BACKUP_DIR/$BACKUP_SESSION"

    mkdir -p "$backup_path"
    log_info "Created backup session: $BACKUP_SESSION"

    local files_to_backup
    files_to_backup=$(jq -r '.operations[].file' "$json_file" | sort | uniq)

    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local backup_file="$backup_path$(dirname "$file")"
            mkdir -p "$backup_file"
            cp "$file" "$backup_path$file"
            log_debug "Backed up: $file"
        fi
    done <<< "$files_to_backup"

    log_info "Backup completed for session: $BACKUP_SESSION"
}

rollback_changes() {
    if [[ -z "$BACKUP_SESSION" ]]; then
        log_error "No backup session to rollback"
        return 1
    fi

    local backup_path="$BACKUP_DIR/$BACKUP_SESSION"
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup directory not found: $backup_path"
        return 1
    fi

    log_info "Rolling back changes from session: $BACKUP_SESSION"

    find "$backup_path" -type f | while IFS= read -r backup_file; do
        local original_file="${backup_file#$backup_path}"
        cp "$backup_file" "$original_file"
        log_debug "Restored: $original_file"
    done

    # Remove files that were created during this session
    for created_file in "${CREATED_FILES[@]}"; do
        if [[ -f "$created_file" ]]; then
            rm -f "$created_file"
            log_debug "Removed created file: $created_file"
        fi
    done

    log_info "Rollback completed successfully"
}

cleanup_backups() {
    find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup_*" -mtime +1 -exec rm -rf {} \; 2>/dev/null || true
    log_debug "Cleaned up old backups"
}

op_create() {
    local operation="$1"
    local index="$2"

    local file content
    file=$(echo "$operation" | jq -r '.file')
    content=$(echo "$operation" | jq -r '.content // ""')

    local dir
    dir=$(dirname "$file")
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_debug "Created parent directories for: $file"
    fi

    echo "$content" > "$file"
    CREATED_FILES+=("$file")
    log_info "Operation $index (create): Created file $file"
}

op_replace() {
    local operation="$1"
    local index="$2"

    local file start_line end_line content
    file=$(echo "$operation" | jq -r '.file')
    start_line=$(echo "$operation" | jq -r '.start_line')
    end_line=$(echo "$operation" | jq -r '.end_line')
    content=$(echo "$operation" | jq -r '.content // ""')

    local total_lines
    total_lines=$(wc -l < "$file")
    if [[ "$start_line" -gt "$total_lines" || "$end_line" -gt "$total_lines" ]]; then
        error_exit "Operation $index (replace): line range $start_line-$end_line exceeds file length ($total_lines lines)"
    fi

    local temp_file
    temp_file=$(mktemp)

    {
        if [[ "$start_line" -gt 1 ]]; then
            head -n $((start_line - 1)) "$file"
        fi

        echo "$content"

        local total_lines
        total_lines=$(wc -l < "$file")
        if [[ "$end_line" -lt "$total_lines" ]]; then
            tail -n +$((end_line + 1)) "$file"
        fi
    } > "$temp_file"

    if ! mv "$temp_file" "$file"; then
        error_exit "Operation $index (replace): Failed to write to file: $file"
    fi
    log_info "Operation $index (replace): Replaced lines $start_line-$end_line in $file"
}

op_insert() {
    local operation="$1"
    local index="$2"

    local file line content
    file=$(echo "$operation" | jq -r '.file')
    line=$(echo "$operation" | jq -r '.line')
    content=$(echo "$operation" | jq -r '.content // ""')

    local temp_file
    temp_file=$(mktemp)

    if [[ "$line" -eq 0 ]]; then
        {
            echo "$content"
            cat "$file"
        } > "$temp_file"
        log_info "Operation $index (insert): Prepended content to $file"
    elif [[ "$line" -eq -1 ]]; then
        {
            cat "$file"
            # Add newline if file not empty and doesn't end with one
            if [[ -s "$file" ]] && [[ -n "$(tail -c 1 "$file")" ]]; then
                echo ""
            fi
            echo "$content"
        } > "$temp_file"
        log_info "Operation $index (insert): Appended content to $file"
    else
        {
            head -n $((line - 1)) "$file"
            echo "$content"
            tail -n +$line "$file"
        } > "$temp_file"
        log_info "Operation $index (insert): Inserted content at line $line in $file"
    fi

    if ! mv "$temp_file" "$file"; then
        error_exit "Operation $index (insert): Failed to write to file: $file"
    fi
}

op_delete() {
    local operation="$1"
    local index="$2"

    local file start_line end_line
    file=$(echo "$operation" | jq -r '.file')
    start_line=$(echo "$operation" | jq -r '.start_line')
    end_line=$(echo "$operation" | jq -r '.end_line')

    local temp_file
    temp_file=$(mktemp)

    {
        if [[ "$start_line" -gt 1 ]]; then
            head -n $((start_line - 1)) "$file"
        fi

        local total_lines
        total_lines=$(wc -l < "$file")
        if [[ "$end_line" -lt "$total_lines" ]]; then
            tail -n +$((end_line + 1)) "$file"
        fi
    } > "$temp_file"

    if ! mv "$temp_file" "$file"; then
        error_exit "Operation $index (delete): Failed to write to file: $file"
    fi
    log_info "Operation $index (delete): Deleted lines $start_line-$end_line from $file"
}

op_patch() {
    local operation="$1"
    local index="$2"

    local file find_str replace_str all_flag
    file=$(echo "$operation" | jq -r '.file')
    find_str=$(echo "$operation" | jq -r '.find')
    replace_str=$(echo "$operation" | jq -r '.replace // ""')
    all_flag=$(echo "$operation" | jq -r '.all // false')

    local temp_file
    temp_file=$(mktemp)

    if [[ "$all_flag" == "true" ]]; then
        sed "s|$(printf '%s' "$find_str" | sed 's/[[\.*^$()+?{|]/\\&/g')|$(printf '%s' "$replace_str" | sed 's/[[\.*^$(){}|]/\\&/g')|g" "$file" > "$temp_file"
    else
        awk -v s_find="$find_str" -v s_repl="$replace_str" '
        BEGIN {f=1}
        f && sub(s_find, s_repl) {f=0}
        {print}
        ' "$file" > "$temp_file"
    fi

    if ! mv "$temp_file" "$file"; then
        error_exit "Operation $index (patch): Failed to write to file: $file"
    fi

    if [[ "$all_flag" == "true" ]]; then
        log_info "Operation $index (patch): Replaced all occurrences of '$find_str' with '$replace_str' in $file"
    else
        log_info "Operation $index (patch): Replaced first occurrence of '$find_str' with '$replace_str' in $file"
    fi
}

execute_operations() {
    local json_file="$1"

    log_info "Starting execution of operations"

    # Generate sorted execution order
    sort_operations_by_file "$json_file"

    # Execute operations in sorted order
    for exec_index in "${EXECUTION_ORDER[@]}"; do
        local operation="${ORIGINAL_OPERATIONS[$exec_index]}"
        local original_index="${OPERATION_ORIGINAL_INDEX[$exec_index]}"
        local op_type
        op_type=$(echo "$operation" | jq -r '.type')

        log_debug "Executing operation $original_index (execution order $exec_index): $op_type"

        case "$op_type" in
            "create")
                op_create "$operation" "$original_index"
                ;;
            "replace")
                op_replace "$operation" "$original_index"
                ;;
            "insert")
                op_insert "$operation" "$original_index"
                ;;
            "delete")
                op_delete "$operation" "$original_index"
                ;;
            "patch")
                op_patch "$operation" "$original_index"
                ;;
            *)
                error_exit "Operation $original_index: Unknown operation type: $op_type"
                ;;
        esac
    done

    log_info "All operations completed successfully"
}

cleanup() {
    if [[ -n "$BACKUP_SESSION" ]]; then
        rm -rf "$BACKUP_DIR/$BACKUP_SESSION"
        log_debug "Cleaned up backup session: $BACKUP_SESSION"
    fi

    cleanup_backups
}

main() {
    local json_input=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --log-level)
                if [[ -z "$2" ]]; then
                    echo "Error: --log-level requires a value (ERROR, INFO, DEBUG)" >&2
                    exit 1
                fi
                case "$2" in
                    ERROR|INFO|DEBUG)
                        LOG_LEVEL="$2"
                        shift 2
                        ;;
                    *)
                        echo "Error: Invalid log level '$2'. Must be ERROR, INFO, or DEBUG" >&2
                        exit 1
                        ;;
                esac
                ;;
            -*)
                echo "Error: Unknown option '$1'" >&2
                echo "Usage: $0 [--log-level ERROR|INFO|DEBUG] <json_operations_file>" >&2
                echo "       $0 tmp/batch_ops_12345.json" >&2
                exit 1
                ;;
            *)
                if [[ -n "$json_input" ]]; then
                    echo "Error: Multiple operation files specified" >&2
                    exit 1
                fi
                json_input="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$json_input" ]]; then
        echo "Usage: $0 [--log-level ERROR|INFO|DEBUG] <json_operations_file>" >&2
        echo "       $0 tmp/batch_ops_12345.json" >&2
        exit 1
    fi

    if [[ "${json_input:0:1}" != "/" ]]; then
        json_input="$SCRIPT_DIR/$json_input"
    fi

    OPERATIONS_FILE="$json_input"

    validate_json "$json_input"
    validate_operations "$json_input"
    create_backup "$json_input"
    execute_operations "$json_input"
    cleanup

    echo "SUCCESS: All operations completed successfully"
}

trap cleanup EXIT
trap 'error_exit "Script failed during execution"' ERR

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi