#!/bin/bash

# Test cases for Edge Cases

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Operations on an empty file
test_ops_on_empty_file() {
    local target_file="$TMP_DIR/empty.txt"
    touch "$target_file"

    # Insert into empty file should work
    local json_insert="$TMP_DIR/insert.json"
    cat > "$json_insert" << EOF
{ "operations": [{ "type": "insert", "file": "$target_file", "line": 0, "content": "a line" }] }
EOF
    run_batch_edit "$json_insert"
    local exit_code_insert=$?
    assert_exit_code 0 $exit_code_insert || return 1
    assert_content_equals "$target_file" "a line" || return 1

    # Restore empty file for next step
    > "$target_file"

    # Replace on empty file should fail (line range invalid)
    local json_replace="$TMP_DIR/replace.json"
    cat > "$json_replace" << EOF
{ "operations": [{ "type": "replace", "file": "$target_file", "start_line": 1, "end_line": 1 }] }
EOF
    run_batch_edit "$json_replace"
    local exit_code_replace=$?
    if [[ $exit_code_replace -eq 0 ]]; then
        log_test_fail "Replace on empty file should fail"
        return 1
    fi

    return 0
}

# Test 2: File with no trailing newline
test_no_trailing_newline() {
    local target_file="$TMP_DIR/no_newline.txt"
    echo -n "hello" > "$target_file"

    # Append to file
    local json_append="$TMP_DIR/append.json"
    cat > "$json_append" << EOF
{ "operations": [{ "type": "insert", "file": "$target_file", "line": -1, "content": " world" }] }
EOF
    run_batch_edit "$json_append"

    assert_content_equals "$target_file" $'hello\n world' || return 1

    return 0
}

# Test 3: Unicode and special characters in content
test_special_chars() {
    local target_file="$TMP_DIR/special.txt"
    local json_file="$TMP_DIR/special.json"

    local content="こんにちは, world! \" ' \\ \$ \`"

    # Create the JSON using jq to handle special character escaping
    jq -n --arg file "$target_file" --arg content "$content" \
    '{operations: [{type: "create", file: $file, content: $content}]}' > "$json_file"

    run_batch_edit "$json_file"
    assert_content_equals "$target_file" "$content" || return 1

    return 0
}

# Test 4: Operations on a single-line file
test_single_line_file() {
    local target_file="$TMP_DIR/single_line.txt"
    echo "single line" > "$target_file"

    # Delete the only line
    local json_delete="$TMP_DIR/delete.json"
    cat > "$json_delete" << EOF
{ "operations": [{ "type": "delete", "file": "$target_file", "start_line": 1, "end_line": 1 }] }
EOF
    run_batch_edit "$json_delete"
    if [[ -s "$target_file" ]]; then
        log_test_fail "File should be empty after deleting the only line"
        return 1
    fi

    # Replace the only line
    echo "single line" > "$target_file" # Restore
    local json_replace="$TMP_DIR/replace.json"
    cat > "$json_replace" << EOF
{ "operations": [{ "type": "replace", "file": "$target_file", "start_line": 1, "end_line": 1, "content": "new line" }] }
EOF
    run_batch_edit "$json_replace"
    assert_content_equals "$target_file" "new line" || return 1

    return 0
}

# Test 6: File encoding and UTF-8 handling
test_utf8_encoding() {
    local target_file="$TMP_DIR/utf8.txt"
    
    # Create content with various UTF-8 characters
    local json_file="$TMP_DIR/utf8.json"
    
    # Use jq to properly handle UTF-8 content
    jq -n '{
        "operations": [
            {
                "type": "create",
                "file": $file,
                "content": $content
            }
        ]
    }' --arg file "$target_file" --arg content "Hello 世界! 🌍 Café naïve résumé" > "$json_file"
    
    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1
    
    # Verify UTF-8 content
    assert_contains "$target_file" "世界" || return 1
    assert_contains "$target_file" "🌍" || return 1
    assert_contains "$target_file" "Café" || return 1
    assert_contains "$target_file" "naïve" || return 1
    assert_contains "$target_file" "résumé" || return 1
    
    return 0
}

# Test 7: Very long single line
test_very_long_line() {
    local target_file="$TMP_DIR/long_line.txt"
    
    # Create a very long line (10KB)
    local long_content=$(printf 'A%.0s' {1..10240})
    
    local json_file="$TMP_DIR/long_line.json"
    jq -n --arg file "$target_file" --arg content "$long_content" '{
        "operations": [{"type": "create", "file": $file, "content": $content}]
    }' > "$json_file"
    
    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1
    
    # Verify file size is approximately correct
    local file_size=$(wc -c < "$target_file")
    if [[ $file_size -lt 10000 ]]; then
        log_test_fail "File size too small: $file_size"
        return 1
    fi
    
    return 0
}

# Test 5: Multiple operations on the same line
test_multiple_ops_same_line() {
    local target_file="$TMP_DIR/multi_op_line.txt"
    cat > "$target_file" << 'EOF'
line 1
line 2
line 3
EOF

    local json_file="$TMP_DIR/multi_op.json"
    cat > "$json_file" << EOF
{ "operations": [
    { "type": "insert", "file": "$target_file", "line": 2, "content": "inserted before 2" },
    { "type": "insert", "file": "$target_file", "line": 2, "content": "inserted again" }
]}
EOF
    run_batch_edit "$json_file"

    # Both should be inserted at original line 2. With absolute line numbers,
    # the second operation is executed first, so "inserted again" is at line 2
    # and "inserted before 2" is at line 3.
    local line2=$(sed -n '2p' "$target_file")
    local line3=$(sed -n '3p' "$target_file")

    if [[ "$line2" != "inserted again" || "$line3" != "inserted before 2" ]]; then
        log_test_fail "Multiple inserts on same line did not behave as expected"
        cat "$target_file" >&2
        return 1
    fi

    return 0
}


# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running Edge Case tests..."
    echo ""

    run_test "ops_on_empty_file" test_ops_on_empty_file
    run_test "no_trailing_newline" test_no_trailing_newline
    run_test "special_chars" test_special_chars
    run_test "single_line_file" test_single_line_file
    run_test "multiple_ops_same_line" test_multiple_ops_same_line
    run_test "utf8_encoding" test_utf8_encoding
    run_test "very_long_line" test_very_long_line

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi
