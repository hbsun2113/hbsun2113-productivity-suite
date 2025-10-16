#!/bin/bash

# Test cases for absolute line number logic and new core features

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Mixed operations (delete, insert, replace) on a single file
# Verifies that operations are sorted and executed correctly based on absolute line numbers.
test_mixed_operations() {
    local target_file="$TMP_DIR/mixed_ops.txt"
    cat > "$target_file" << 'EOF'
line 1
line 2
line 3
line 4
line 5
EOF

    local json_file="$TMP_DIR/mixed_ops.json"
    cat > "$json_file" << EOF
{
    "operations": [
        { "type": "delete", "file": "$target_file", "start_line": 4, "end_line": 4 },
        { "type": "insert", "file": "$target_file", "line": 2, "content": "inserted line" },
        { "type": "replace", "file": "$target_file", "start_line": 5, "end_line": 5, "content": "replaced line 5" }
    ]
}
EOF

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1

    local expected_content
    expected_content=$(cat << 'EOF'
line 1
inserted line
line 2
line 3
replaced line 5
EOF
)
    assert_content_equals "$target_file" "$expected_content" || return 1
    return 0
}

# Test 2: Conflict detection for overlapping operations
# Verifies that the script correctly identifies and aborts conflicting operations.
test_conflict_detection() {
    local target_file="$TMP_DIR/conflict.txt"
    cat > "$target_file" << 'EOF'
line 1
line 2
line 3
line 4
EOF

    local json_file="$TMP_DIR/conflict.json"
    # Operation 2 (insert at line 3) conflicts with operation 1 (delete lines 2-4)
    cat > "$json_file" << EOF
{
    "operations": [
        { "type": "delete", "file": "$target_file", "start_line": 2, "end_line": 4 },
        { "type": "insert", "file": "$target_file", "line": 3, "content": "should fail" }
    ]
}
EOF

    run_batch_edit "$json_file"
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Script should have failed due to conflicting operations but it succeeded."
        return 1
    fi

    local error_output
    error_output=$(cat "$TMP_DIR/batch_edit_output.txt")
    assert_contains "$TMP_DIR/batch_edit_output.txt" "conflicts with operation" || {
        log_test_fail "Error output did not contain expected conflict message."
        echo "Actual output:" >&2
        echo "$error_output" >&2
        return 1
    }

    return 0
}

# Test 3: Operations on a file created in the same batch
# Verifies that later operations can target a file created by an earlier operation.
test_ops_on_created_file() {
    local target_file="$TMP_DIR/created_then_edited.txt"
    local json_file="$TMP_DIR/create_then_edit.json"

    cat > "$json_file" << EOF
{
    "operations": [
        { "type": "create", "file": "$target_file", "content": "line 1\\nline 3" },
        { "type": "insert", "file": "$target_file", "line": 2, "content": "line 2" }
    ]
}
EOF

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1

    local expected_content
    expected_content=$(cat << 'EOF'
line 1
line 2
line 3
EOF
)
    assert_content_equals "$target_file" "$expected_content" || return 1
    return 0
}


# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running Absolute Line Number Logic tests..."
    echo ""

    run_test "mixed_operations" test_mixed_operations
    run_test "conflict_detection" test_conflict_detection
    run_test "ops_on_created_file" test_ops_on_created_file

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi