#!/bin/bash

# Test cases for DELETE operation

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Basic delete operation
test_delete_basic() {
    local json_file="$TMP_DIR/delete_basic.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Line 1
Line 2
Line 3
Line 4
Line 5
EOF

    # Create JSON operations file
    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "delete",
            "file": "$target_file",
            "start_line": 2,
            "end_line": 4
        }
    ]
}
EOF

    # Run batch_edit
    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    # Assertions
    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 2 || return 1
    assert_contains "$target_file" "Line 1" || return 1
    assert_contains "$target_file" "Line 5" || return 1
    assert_not_contains "$target_file" "Line 2" || return 1
    assert_not_contains "$target_file" "Line 3" || return 1
    assert_not_contains "$target_file" "Line 4" || return 1

    return 0
}

# Test 2: Delete single line
test_delete_single_line() {
    local json_file="$TMP_DIR/delete_single.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
First line
Second line
Third line
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "delete",
            "file": "$target_file",
            "start_line": 2,
            "end_line": 2
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 2 || return 1
    assert_contains "$target_file" "First line" || return 1
    assert_contains "$target_file" "Third line" || return 1
    assert_not_contains "$target_file" "Second line" || return 1

    return 0
}

# Test 3: Delete first line
test_delete_first_line() {
    local json_file="$TMP_DIR/delete_first.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Delete me
Keep this
Keep this too
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "delete",
            "file": "$target_file",
            "start_line": 1,
            "end_line": 1
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 2 || return 1
    assert_contains "$target_file" "Keep this" || return 1
    assert_contains "$target_file" "Keep this too" || return 1
    assert_not_contains "$target_file" "Delete me" || return 1

    # Check that "Keep this" is now the first line
    local first_line=$(sed -n '1p' "$target_file")
    if [[ "$first_line" != "Keep this" ]]; then
        log_test_fail "First line should be 'Keep this'"
        return 1
    fi

    return 0
}

# Test 4: Delete last line
test_delete_last_line() {
    local json_file="$TMP_DIR/delete_last.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Keep this
Keep this too
Delete me
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "delete",
            "file": "$target_file",
            "start_line": 3,
            "end_line": 3
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 2 || return 1
    assert_contains "$target_file" "Keep this" || return 1
    assert_contains "$target_file" "Keep this too" || return 1
    assert_not_contains "$target_file" "Delete me" || return 1

    return 0
}

# Test 5: Delete all lines (entire file content)
test_delete_all_lines() {
    local json_file="$TMP_DIR/delete_all.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Line 1
Line 2
Line 3
EOF

    local total_lines=$(wc -l < "$target_file")

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "delete",
            "file": "$target_file",
            "start_line": 1,
            "end_line": $total_lines
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1

    # File should exist but be empty
    assert_file_exists "$target_file" || return 1

    # Check if file is empty
    if [[ -s "$target_file" ]]; then
        log_test_fail "File should be empty after deleting all lines"
        return 1
    fi

    return 0
}

# Test 6: Multiple delete operations
test_delete_multiple() {
    local json_file="$TMP_DIR/delete_multiple.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Line 1
Line 2
Line 3
Line 4
Line 5
Line 6
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "delete",
            "file": "$target_file",
            "start_line": 2,
            "end_line": 2
        },
        {
            "type": "delete",
            "file": "$target_file",
            "start_line": 4,
            "end_line": 5
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 3 || return 1
    assert_contains "$target_file" "Line 1" || return 1
    assert_contains "$target_file" "Line 3" || return 1
    assert_not_contains "$target_file" "Line 6" || return 1
    assert_not_contains "$target_file" "Line 2" || return 1
    assert_contains "$target_file" "Line 4" || return 1
    assert_not_contains "$target_file" "Line 5" || return 1

    return 0
}

# Test 7: Error - Line range exceeds file length
test_delete_exceeds_range() {
    local json_file="$TMP_DIR/delete_exceeds.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Line 1
Line 2
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "delete",
            "file": "$target_file",
            "start_line": 2,
            "end_line": 5
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    # Should fail
    if [[ $exit_code -eq 0 ]]; then
        log_test_fail "Should have failed for exceeding line range"
        return 1
    fi

    # Original file should remain unchanged
    assert_line_count "$target_file" 2 || return 1
    assert_contains "$target_file" "Line 1" || return 1
    assert_contains "$target_file" "Line 2" || return 1

    return 0
}

# Test 8: Delete after other operations
test_delete_after_ops() {
    local json_file="$TMP_DIR/delete_after_ops.json"
    local target_file="$TMP_DIR/new_file.txt"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$target_file",
            "content": "Line 1\nLine 2\nLine 3\nLine 4"
        },
        {
            "type": "insert",
            "file": "$target_file",
            "line": 2,
            "content": "Inserted line"
        },
        {
            "type": "delete",
            "file": "$target_file",
            "start_line": 3,
            "end_line": 4
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_file_exists "$target_file" || return 1
    assert_line_count "$target_file" 3 || return 1
    assert_contains "$target_file" "Line 1" || return 1
    assert_contains "$target_file" "Inserted line" || return 1
    assert_contains "$target_file" "Line 4" || return 1
    assert_not_contains "$target_file" "Line 2" || return 1
    assert_not_contains "$target_file" "Line 3" || return 1

    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running DELETE operation tests..."
    echo ""

    run_test "delete_basic" test_delete_basic
    run_test "delete_single_line" test_delete_single_line
    run_test "delete_first_line" test_delete_first_line
    run_test "delete_last_line" test_delete_last_line
    run_test "delete_all_lines" test_delete_all_lines
    run_test "delete_multiple" test_delete_multiple
    run_test "delete_exceeds_range" test_delete_exceeds_range
    run_test "delete_after_ops" test_delete_after_ops

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi