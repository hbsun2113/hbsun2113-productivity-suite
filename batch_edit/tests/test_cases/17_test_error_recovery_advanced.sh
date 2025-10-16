#!/bin/bash

# Test cases for Advanced Error Recovery Scenarios

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Partial failure with rollback in complex scenario
test_partial_failure_complex_rollback() {
    local dir="$TMP_DIR/rollback_complex"
    mkdir -p "$dir"
    
    # Create initial files
    echo "Original content 1" > "$dir/file1.txt"
    echo "Original content 2" > "$dir/file2.txt"
    echo "Original content 3" > "$dir/file3.txt"
    
    # JSON with operations that will fail partway through
    local json_file="$TMP_DIR/complex_fail.json"
    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "patch",
            "file": "$dir/file1.txt",
            "find": "Original",
            "replace": "Modified",
            "all": false
        },
        {
            "type": "create",
            "file": "$dir/new_file.txt",
            "content": "New file content"
        },
        {
            "type": "replace",
            "file": "$dir/file2.txt",
            "start_line": 1,
            "end_line": 1,
            "content": "Updated content 2"
        },
        {
            "type": "replace",
            "file": "$dir/nonexistent.txt",
            "start_line": 1,
            "end_line": 1,
            "content": "This will fail"
        }
    ]
}
EOF

    # Execute and expect failure
    run_batch_edit "$json_file"
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed due to nonexistent file"
        return 1
    fi
    
    # Verify rollback - all files should be in original state
    assert_content_equals "$dir/file1.txt" "Original content 1" || return 1
    assert_content_equals "$dir/file2.txt" "Original content 2" || return 1
    assert_content_equals "$dir/file3.txt" "Original content 3" || return 1
    
    # New file should not exist
    if [[ -f "$dir/new_file.txt" ]]; then
        log_test_fail "New file should not exist after rollback"
        return 1
    fi
    
    return 0
}

# Test 2: Permission errors and recovery (simplified)
test_permission_error_recovery() {
    local dir="$TMP_DIR/permission_test"
    mkdir -p "$dir"
    
    # Create files that will succeed
    echo "Content 1" > "$dir/file1.txt"
    echo "Content 2" > "$dir/file2.txt"
    
    local json_file="$TMP_DIR/permission_fail.json"
    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "patch",
            "file": "$dir/file1.txt",
            "find": "Content 1",
            "replace": "Modified 1",
            "all": false
        },
        {
            "type": "create",
            "file": "/dev/null/impossible.txt",
            "content": "This should fail"
        }
    ]
}
EOF

    # Execute and expect failure
    run_batch_edit "$json_file"
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed due to invalid path"
        return 1
    fi
    
    # Verify rollback worked - the file should be restored to original content
    assert_content_equals "$dir/file1.txt" "Content 1" || return 1
    
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running Advanced Error Recovery tests..."
    echo ""

    run_test "partial_failure_complex_rollback" test_partial_failure_complex_rollback
    run_test "permission_error_recovery" test_permission_error_recovery

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi
