#!/bin/bash

# Test cases for Rollback mechanism

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Rollback on mid-batch failure
test_rollback_on_failure() {
    local json_file="$TMP_DIR/rollback_failure.json"
    local file1="$TMP_DIR/file1.txt"
    local file2="$TMP_DIR/file2.txt"

    # Initial content for file1
    echo "Initial content for file1" > "$file1"
    local original_content=$(cat "$file1")

    # This batch will:
    # 1. Create file2 (should be removed on rollback)
    # 2. Replace content in file1 (should be restored)
    # 3. Fail on a nonexistent file
    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$file2",
            "content": "This file should not exist after rollback"
        },
        {
            "type": "replace",
            "file": "$file1",
            "start_line": 1,
            "end_line": 1,
            "content": "This content should be rolled back"
        },
        {
            "type": "delete",
            "file": "/tmp/non_existent_file_for_rollback_test.txt",
            "start_line": 1,
            "end_line": 1
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed to trigger rollback"
        return 1
    fi

    # Assertions for rollback
    # File 1 should be restored to its original state
    assert_file_exists "$file1" || return 1
    assert_content_equals "$file1" "$original_content" || return 1

    # File 2, created during the batch, should be removed
    assert_file_not_exists "$file2" || return 1

    return 0
}

# Test 2: Rollback with multiple file modifications
test_rollback_multiple_files() {
    local json_file="$TMP_DIR/rollback_multiple.json"
    local file_a="$TMP_DIR/a.txt"
    local file_b="$TMP_DIR/b.txt"
    local file_c="$TMP_DIR/c.txt" # This will be created

    # Initial content
    echo "original a" > "$file_a"
    echo "original b" > "$file_b"
    local original_a=$(cat "$file_a")
    local original_b=$(cat "$file_b")

    cat > "$json_file" << EOF
{
    "operations": [
        { "type": "patch", "file": "$file_a", "find": "original", "replace": "modified" },
        { "type": "create", "file": "$file_c", "content": "new file" },
        { "type": "insert", "file": "$file_b", "line": -1, "content": "appended" },
        { "type": "replace", "file": "/nonexistent/path/to/fail", "start_line": 1, "end_line": 1 }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Batch should have failed"
        return 1
    fi

    assert_content_equals "$file_a" "$original_a" || return 1
    assert_content_equals "$file_b" "$original_b" || return 1
    assert_file_not_exists "$file_c" || return 1

    return 0
}

# Test 3: No rollback on successful execution
test_no_rollback_on_success() {
    local json_file="$TMP_DIR/no_rollback.json"
    local file1="$TMP_DIR/success_file.txt"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$file1",
            "content": "Success!"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_file_exists "$file1" || return 1

    # Check that backup directory for this session is cleaned up
    local output=$(cat "$TMP_DIR/batch_edit_output.txt")
    local session_id=$(echo "$output" | grep "Created backup session" | sed 's/.*: //')

    if [[ -z "$session_id" ]]; then
        log_test_fail "Could not find backup session ID in output"
        return 1
    fi

    local backup_dir="$BATCH_EDIT_DIR/backups/$session_id"
    if [[ -d "$backup_dir" ]]; then
        log_test_fail "Backup directory was not cleaned up on success: $backup_dir"
        return 1
    fi

    return 0
}


# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running Rollback tests..."
    echo ""

    run_test "rollback_on_failure" test_rollback_on_failure
    run_test "rollback_multiple_files" test_rollback_multiple_files
    # run_test "no_rollback_on_success" test_no_rollback_on_success

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi