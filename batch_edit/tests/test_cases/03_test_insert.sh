#!/bin/bash

# Test cases for INSERT operation

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Basic insert at specific line
test_insert_basic() {
    local json_file="$TMP_DIR/insert_basic.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Line 1
Line 2
Line 3
EOF

    # Create JSON operations file - insert after line 2
    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "insert",
            "file": "$target_file",
            "line": 3,
            "content": "Inserted line"
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
    assert_line_count "$target_file" 4 || return 1
    assert_contains "$target_file" "Line 1" || return 1
    assert_contains "$target_file" "Line 2" || return 1
    assert_contains "$target_file" "Inserted line" || return 1
    assert_contains "$target_file" "Line 3" || return 1

    # Check order
    local line_2=$(sed -n '2p' "$target_file")
    local line_3=$(sed -n '3p' "$target_file")
    local line_4=$(sed -n '4p' "$target_file")

    if [[ "$line_2" != "Line 2" || "$line_3" != "Inserted line" || "$line_4" != "Line 3" ]]; then
        log_test_fail "Lines not in correct order"
        return 1
    fi

    return 0
}

# Test 2: Insert at beginning (line 0)
test_insert_beginning() {
    local json_file="$TMP_DIR/insert_beginning.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
First line
Second line
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "insert",
            "file": "$target_file",
            "line": 0,
            "content": "New first line"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 3 || return 1

    # Check that new line is first
    local first_line=$(sed -n '1p' "$target_file")
    if [[ "$first_line" != "New first line" ]]; then
        log_test_fail "New line not inserted at beginning"
        return 1
    fi

    return 0
}

# Test 3: Append at end (line -1)
test_insert_append() {
    local json_file="$TMP_DIR/insert_append.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
First line
Second line
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "insert",
            "file": "$target_file",
            "line": -1,
            "content": "Appended line"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 3 || return 1

    # Check that new line is last
    local last_line=$(tail -n 1 "$target_file")
    if [[ "$last_line" != "Appended line" ]]; then
        log_test_fail "Line not appended at end"
        return 1
    fi

    return 0
}

# Test 4: Insert multiline content
test_insert_multiline() {
    local json_file="$TMP_DIR/insert_multiline.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Line 1
Line 3
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "insert",
            "file": "$target_file",
            "line": 2,
            "content": "Insert A\nInsert B\nInsert C"
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
    assert_contains "$target_file" "Insert A" || return 1
    assert_contains "$target_file" "Insert B" || return 1
    assert_contains "$target_file" "Insert C" || return 1
    assert_contains "$target_file" "Line 3" || return 1

    return 0
}

# Test 5: Multiple insert operations
test_insert_multiple() {
    local json_file="$TMP_DIR/insert_multiple.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Line 1
Line 2
Line 3
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "insert",
            "file": "$target_file",
            "line": 0,
            "content": "Header"
        },
        {
            "type": "insert",
            "file": "$target_file",
            "line": -1,
            "content": "Footer"
        },
        {
            "type": "insert",
            "file": "$target_file",
            "line": 3,
            "content": "Middle insert"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_line_count "$target_file" 6 || return 1

    # Check order: Header, Line 1, Middle insert, Line 2, Line 3, Footer
    local line_1=$(sed -n '1p' "$target_file")
    local line_3=$(sed -n '3p' "$target_file")
    local line_6=$(sed -n '6p' "$target_file")

    if [[ "$line_1" != "Header" ]]; then
        log_test_fail "Header not at beginning"
        return 1
    fi

    if [[ "$line_3" != "Middle insert" ]]; then
        log_test_fail "Middle insert not at position 3"
        return 1
    fi

    if [[ "$line_6" != "Footer" ]]; then
        log_test_fail "Footer not at end"
        return 1
    fi

    return 0
}

# Test 6: Insert into empty file
test_insert_empty_file() {
    local json_file="$TMP_DIR/insert_empty.json"
    local target_file="$TMP_DIR/empty_file.txt"

    # Create empty file
    touch "$target_file"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "insert",
            "file": "$target_file",
            "line": 0,
            "content": "First content"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_content_equals "$target_file" "First content" || return 1

    return 0
}

# Test 7: Insert after create operation
test_insert_after_create() {
    local json_file="$TMP_DIR/insert_after_create.json"
    local target_file="$TMP_DIR/new_file.txt"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$target_file",
            "content": "Initial line"
        },
        {
            "type": "insert",
            "file": "$target_file",
            "line": -1,
            "content": "Added line"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_file_exists "$target_file" || return 1
    assert_line_count "$target_file" 2 || return 1
    assert_contains "$target_file" "Initial line" || return 1
    assert_contains "$target_file" "Added line" || return 1

    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running INSERT operation tests..."
    echo ""

    run_test "insert_basic" test_insert_basic
    run_test "insert_beginning" test_insert_beginning
    run_test "insert_append" test_insert_append
    run_test "insert_multiline" test_insert_multiline
    run_test "insert_multiple" test_insert_multiple
    run_test "insert_empty_file" test_insert_empty_file
    run_test "insert_after_create" test_insert_after_create

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi