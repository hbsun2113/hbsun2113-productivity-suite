#!/bin/bash

# Test cases for REPLACE operation

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Basic replace operation
test_replace_basic() {
    local json_file="$TMP_DIR/replace_basic.json"
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
            "type": "replace",
            "file": "$target_file",
            "start_line": 2,
            "end_line": 4,
            "content": "Replacement text for lines 2-4"
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
    assert_contains "$target_file" "Line 1" || return 1
    assert_contains "$target_file" "Replacement text for lines 2-4" || return 1
    assert_contains "$target_file" "Line 5" || return 1
    assert_not_contains "$target_file" "Line 2" || return 1
    assert_not_contains "$target_file" "Line 3" || return 1
    assert_not_contains "$target_file" "Line 4" || return 1

    # Check that the result has 3 lines total
    local actual_lines=$(grep -c . "$target_file" || true)
    if [[ "$actual_lines" -ne 3 ]]; then
        log_test_fail "Expected 3 lines, got $actual_lines"
        return 1
    fi

    return 0
}

# Test 2: Replace single line
test_replace_single_line() {
    local json_file="$TMP_DIR/replace_single.json"
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
            "type": "replace",
            "file": "$target_file",
            "start_line": 2,
            "end_line": 2,
            "content": "Modified second line"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 3 || return 1
    assert_contains "$target_file" "First line" || return 1
    assert_contains "$target_file" "Modified second line" || return 1
    assert_contains "$target_file" "Third line" || return 1

    return 0
}

# Test 3: Replace with empty content (delete lines)
test_replace_with_empty() {
    local json_file="$TMP_DIR/replace_empty.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Keep this
Delete this
Delete this too
Keep this as well
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "replace",
            "file": "$target_file",
            "start_line": 2,
            "end_line": 3,
            "content": ""
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 3 || return 1
    assert_contains "$target_file" "Keep this" || return 1
    assert_contains "$target_file" "Keep this as well" || return 1
    assert_not_contains "$target_file" "Delete" || return 1

    return 0
}

# Test 4: Replace entire file
test_replace_entire_file() {
    local json_file="$TMP_DIR/replace_entire.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Old content line 1
Old content line 2
Old content line 3
EOF

    # Count lines for end_line
    local total_lines=$(wc -l < "$target_file")

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "replace",
            "file": "$target_file",
            "start_line": 1,
            "end_line": $total_lines,
            "content": "Completely new content"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_content_equals "$target_file" "Completely new content" || return 1

    return 0
}

# Test 5: Multiple replace operations on same file
test_replace_multiple() {
    local json_file="$TMP_DIR/replace_multiple.json"
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
            "type": "replace",
            "file": "$target_file",
            "start_line": 2,
            "end_line": 2,
            "content": "Modified Line 2"
        },
        {
            "type": "replace",
            "file": "$target_file",
            "start_line": 4,
            "end_line": 5,
            "content": "Combined Line 4-5"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 5 || return 1
    assert_contains "$target_file" "Line 1" || return 1
    assert_contains "$target_file" "Modified Line 2" || return 1
    assert_contains "$target_file" "Line 3" || return 1
    assert_contains "$target_file" "Combined Line 4-5" || return 1
    assert_contains "$target_file" "Line 6" || return 1

    return 0
}

# Test 6: Error - Line range exceeds file length
test_replace_exceeds_range() {
    local json_file="$TMP_DIR/replace_exceeds.json"
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
            "type": "replace",
            "file": "$target_file",
            "start_line": 2,
            "end_line": 5,
            "content": "New content"
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

# Test 7: Replace on file created in same batch
test_replace_after_create() {
    local json_file="$TMP_DIR/replace_after_create.json"
    local target_file="$TMP_DIR/new_file.txt"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$target_file",
            "content": "Line 1\nLine 2\nLine 3"
        },
        {
            "type": "replace",
            "file": "$target_file",
            "start_line": 2,
            "end_line": 2,
            "content": "Modified Line 2"
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
    assert_contains "$target_file" "Modified Line 2" || return 1
    assert_contains "$target_file" "Line 3" || return 1

    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running REPLACE operation tests..."
    echo ""

    run_test "replace_basic" test_replace_basic
    run_test "replace_single_line" test_replace_single_line
    run_test "replace_with_empty" test_replace_with_empty
    run_test "replace_entire_file" test_replace_entire_file
    run_test "replace_multiple" test_replace_multiple
    run_test "replace_exceeds_range" test_replace_exceeds_range
    run_test "replace_after_create" test_replace_after_create

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi