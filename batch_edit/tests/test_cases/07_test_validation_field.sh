#!/bin/bash

# Test cases for Field validation

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Relative path instead of absolute
test_relative_path() {
    local json_file="$TMP_DIR/relative_path.json"

    echo '{ "operations": [{ "type": "create", "file": "relative/path.txt" }] }' > "$json_file"

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for relative path"
        return 1
    fi

    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Operation 1 (create): Field 'file' must be absolute path"* ]]; then
        log_test_fail "Incorrect error message for relative path"
        return 1
    fi

    return 0
}

# Test 2: Missing 'file' field
test_missing_file_field() {
    local json_file="$TMP_DIR/missing_file.json"

    echo '{ "operations": [{ "type": "create", "content": "hello" }] }' > "$json_file"

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for missing 'file' field"
        return 1
    fi

    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Operation 1 (create): Missing required field 'file'"* ]]; then
        log_test_fail "Incorrect error message for missing 'file'"
        return 1
    fi

    return 0
}


# Test 3: Invalid start_line/end_line (replace)
test_invalid_line_range_replace() {
    local json_file="$TMP_DIR/invalid_range.json"
    local target_file="$TMP_DIR/test_file.txt"
    touch "$target_file"

    # start_line > end_line
    echo '{ "operations": [{ "type": "replace", "file": "'"$target_file"'", "start_line": 5, "end_line": 2 }] }' > "$json_file"

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for invalid line range"
        return 1
    fi

    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Operation 1 (replace): start_line (5) must be <= end_line (2)"* ]]; then
        log_test_fail "Incorrect error message for invalid range"
        return 1
    fi

    return 0
}

# Test 4: File does not exist for replace/insert/delete/patch
test_file_not_exist() {
    local ops=("replace" "insert" "delete" "patch")

    for op_type in "${ops[@]}"; do
        local json_file="$TMP_DIR/nonexistent_${op_type}.json"
        local op_details=""

        case "$op_type" in
            "replace"|"delete")
                op_details='"start_line": 1, "end_line": 1'
                ;;
            "insert")
                op_details='"line": 1, "content": "..."'
                ;;
            "patch")
                op_details='"find": "a", "replace": "b"'
                ;;
        esac

        echo '{ "operations": [{ "type": "'"$op_type"'", "file": "/tmp/non_existent_file.txt", '"$op_details"' }] }' > "$json_file"

        local exit_code
        run_batch_edit "$json_file"
        exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            log_test_fail "Should have failed for nonexistent file for op '$op_type'"
            return 1
        fi

        local output=$(cat "$TMP_DIR/batch_edit_output.txt")
        if ! [[ "$output" == *"[ERROR] Operation 1 ($op_type): File does not exist: /tmp/non_existent_file.txt"* ]]; then
            log_test_fail "Incorrect error message for nonexistent file"
            return 1
        fi
    done

    return 0
}

# Test 5: Invalid field types
test_invalid_field_types() {
    local json_file="$TMP_DIR/invalid_types.json"
    local target_file="$TMP_DIR/test_file.txt"
    touch "$target_file"

    # 'content' is not a string
    echo '{ "operations": [{ "type": "create", "file": "'"$target_file"'", "content": 123 }] }' > "$json_file"

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for invalid 'content' type"
        return 1
    fi

    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Operation 1 (create): Field 'content' must be string"* ]]; then
        log_test_fail "Incorrect error message for invalid content type"
        return 1
    fi

    # 'all' is not a boolean
    echo '{ "operations": [{ "type": "patch", "file": "'"$target_file"'", "find": "a", "all": "true_str" }] }' > "$json_file"

    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for invalid 'all' type"
        return 1
    fi

    output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Operation 1 (patch): Field 'all' must be boolean"* ]]; then
        log_test_fail "Incorrect error message for invalid 'all' type"
        return 1
    fi

    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running Field Validation tests..."
    echo ""

    run_test "relative_path" test_relative_path
    run_test "missing_file_field" test_missing_file_field
    run_test "invalid_line_range_replace" test_invalid_line_range_replace
    run_test "file_not_exist" test_file_not_exist
    run_test "invalid_field_types" test_invalid_field_types

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi