#!/bin/bash

# Test cases for CREATE operation

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Basic file creation
test_create_basic() {
    local json_file="$TMP_DIR/create_basic.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create JSON operations file
    cat > "$json_file" << 'EOF'
{
    "operations": [
        {
            "type": "create",
            "file": "/tmp/test_create_basic.txt",
            "content": "Hello, World!"
        }
    ]
}
EOF

    # Replace placeholder with actual path
    sed -i "s|/tmp/test_create_basic.txt|$target_file|" "$json_file"

    # Run batch_edit
    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    # Assertions
    assert_exit_code 0 $exit_code || return 1
    assert_file_exists "$target_file" || return 1
    assert_content_equals "$target_file" "Hello, World!" || return 1

    return 0
}

# Test 2: Create file with empty content
test_create_empty() {
    local json_file="$TMP_DIR/create_empty.json"
    local target_file="$TMP_DIR/empty_file.txt"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$target_file",
            "content": ""
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_file_exists "$target_file" || return 1
    assert_content_equals "$target_file" "" || return 1

    return 0
}

# Test 3: Create file with multiline content
test_create_multiline() {
    local json_file="$TMP_DIR/create_multiline.json"
    local target_file="$TMP_DIR/multiline_file.txt"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$target_file",
            "content": "Line 1\nLine 2\nLine 3"
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
    assert_contains "$target_file" "Line 2" || return 1
    assert_contains "$target_file" "Line 3" || return 1

    return 0
}

# Test 4: Create file in nested directory
test_create_nested_dir() {
    local json_file="$TMP_DIR/create_nested.json"
    local target_file="$TMP_DIR/nested/dir/structure/file.txt"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$target_file",
            "content": "Nested file content"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_file_exists "$target_file" || return 1
    assert_content_equals "$target_file" "Nested file content" || return 1

    return 0
}

# Test 5: Error - Create existing file
test_create_existing_error() {
    local json_file="$TMP_DIR/create_existing.json"
    local target_file="$TMP_DIR/existing_file.txt"

    # Create existing file
    echo "Existing content" > "$target_file"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$target_file",
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
        log_test_fail "Should have failed for existing file"
        return 1
    fi

    # Original file should remain unchanged
    assert_content_equals "$target_file" "Existing content" || return 1

    return 0
}

# Test 6: Multiple create operations
test_create_multiple() {
    local json_file="$TMP_DIR/create_multiple.json"
    local file1="$TMP_DIR/file1.txt"
    local file2="$TMP_DIR/file2.txt"
    local file3="$TMP_DIR/file3.txt"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$file1",
            "content": "Content 1"
        },
        {
            "type": "create",
            "file": "$file2",
            "content": "Content 2"
        },
        {
            "type": "create",
            "file": "$file3",
            "content": "Content 3"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_file_exists "$file1" || return 1
    assert_file_exists "$file2" || return 1
    assert_file_exists "$file3" || return 1
    assert_content_equals "$file1" "Content 1" || return 1
    assert_content_equals "$file2" "Content 2" || return 1
    assert_content_equals "$file3" "Content 3" || return 1

    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running CREATE operation tests..."
    echo ""

    run_test "create_basic" test_create_basic
    run_test "create_empty" test_create_empty
    run_test "create_multiline" test_create_multiline
    run_test "create_nested_dir" test_create_nested_dir
    run_test "create_existing_error" test_create_existing_error
    run_test "create_multiple" test_create_multiple

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi