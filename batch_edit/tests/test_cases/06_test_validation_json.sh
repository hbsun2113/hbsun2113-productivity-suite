#!/bin/bash

# Test cases for JSON validation

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Invalid JSON syntax
test_invalid_json_syntax() {
    local json_file="$TMP_DIR/invalid_syntax.json"

    # Create a file with invalid JSON (trailing comma)
    echo '{ "operations": [ { "type": "create", "file": "/tmp/a.txt" } ], }' > "$json_file"

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for invalid JSON syntax"
        return 1
    fi

    # Check for specific error message
    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Invalid JSON syntax"* ]]; then
        log_test_fail "Incorrect error message for invalid syntax"
        echo "Actual output: $output" >&2
        return 1
    fi

    return 0
}

# Test 2: Missing 'operations' array
test_missing_operations_array() {
    local json_file="$TMP_DIR/missing_ops.json"

    echo '{ "data": [] }' > "$json_file"

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for missing 'operations' array"
        return 1
    fi

    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Missing 'operations' array in JSON"* ]]; then
        log_test_fail "Incorrect error message for missing array"
        return 1
    fi

    return 0
}

# Test 3: 'operations' is not an array
test_operations_not_array() {
    local json_file="$TMP_DIR/ops_not_array.json"

    echo '{ "operations": "not an array" }' > "$json_file"

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for 'operations' not being an array"
        return 1
    fi

    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Field 'operations' must be an array"* ]]; then
        log_test_fail "Incorrect error message for wrong type"
        return 1
    fi

    return 0
}

# Test 4: Empty 'operations' array
test_empty_operations_array() {
    local json_file="$TMP_DIR/empty_ops.json"

    echo '{ "operations": [] }' > "$json_file"

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for empty 'operations' array"
        return 1
    fi

    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Operations array cannot be empty"* ]]; then
        log_test_fail "Incorrect error message for empty array"
        return 1
    fi

    return 0
}

# Test 5: Missing operation 'type'
test_missing_op_type() {
    local json_file="$TMP_DIR/missing_type.json"

    echo '{ "operations": [{ "file": "/tmp/a.txt" }] }' > "$json_file"

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for missing operation type"
        return 1
    fi

    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Operation 1: Missing required field 'type'"* ]]; then
        log_test_fail "Incorrect error message for missing type"
        return 1
    fi

    return 0
}

# Test 6: Unknown operation 'type'
test_unknown_op_type() {
    local json_file="$TMP_DIR/unknown_type.json"

    echo '{ "operations": [{ "type": "unknown", "file": "/tmp/a.txt" }] }' > "$json_file"

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for unknown operation type"
        return 1
    fi

    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    if ! [[ "$output" == *"[ERROR] Operation 1: Unknown operation type: unknown"* ]]; then
        log_test_fail "Incorrect error message for unknown type"
        return 1
    fi

    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running JSON Validation tests..."
    echo ""

    run_test "invalid_json_syntax" test_invalid_json_syntax
    run_test "missing_operations_array" test_missing_operations_array
    run_test "operations_not_array" test_operations_not_array
    run_test "empty_operations_array" test_empty_operations_array
    run_test "missing_op_type" test_missing_op_type
    run_test "unknown_op_type" test_unknown_op_type

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi