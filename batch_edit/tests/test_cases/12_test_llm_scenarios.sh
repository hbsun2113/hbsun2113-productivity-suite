#!/bin/bash

# Test cases for Basic LLM Scenarios (12_test_llm_scenarios.sh)

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Complex JSON with 20+ operations
test_llm_complex_json() {
    local dir="$TMP_DIR/complex_json"
    mkdir -p "$dir"
    local json_file="$TMP_DIR/complex.json"

    # Generate 25 files to be created
    local operations_str=""
    for i in $(seq 1 25); do
        local file_path="$dir/file_$i.txt"
        local content="Content for file $i"
        operations_str+=$(printf '{"type": "create", "file": "%s", "content": "%s"},' "$file_path" "$content")
    done
    operations_str=${operations_str%,} # Remove trailing comma

    # Create the JSON file
    cat > "$json_file" << EOF
{
    "operations": [
        $operations_str
    ]
}
EOF

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1

    # Verify all files were created correctly
    for i in $(seq 1 25); do
        local file_path="$dir/file_$i.txt"
        assert_file_exists "$file_path" || return 1
        assert_content_equals "$file_path" "Content for file $i" || return 1
    done
    return 0
}

# Test 2: Absolute line number precision
test_llm_line_precision() {
    local target_file="$TMP_DIR/precision.txt"
    cat > "$target_file" << 'EOF'
Line 1
Line 2 (to be replaced)
Line 3
Line 4
Line 5 (delete this)
Line 6
EOF

    local json_file="$TMP_DIR/precision.json"
    jq -n \
      --arg file "$target_file" \
      '{
        "operations": [
          { "type": "replace", "file": $file, "start_line": 2, "end_line": 2, "content": "Line 2 (was replaced)" },
          { "type": "delete", "file": $file, "start_line": 5, "end_line": 5 },
          { "type": "insert", "file": $file, "line": 4, "content": "A new line inserted" }
        ]
      }' > "$json_file"

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1

    local expected_content
    expected_content=$(cat << 'EOF'
Line 1
Line 2 (was replaced)
Line 3
A new line inserted
Line 4
Line 6
EOF
)
    assert_content_equals "$target_file" "$expected_content" || return 1
    return 0
}

# Test 3: Content handling with special characters
test_llm_special_characters() {
    local target_file="$TMP_DIR/special_chars.py"
    cat > "$target_file" << 'EOF'
def old_function():
    print("This is old.")
EOF

    local new_content='def new_function():
    # This is a comment with "quotes" and backslashes \
    print("Line with\ttab and\nnewline")'

    local json_file="$TMP_DIR/special.json"
    jq -n \
      --arg file "$target_file" \
      --arg content "$new_content" \
      '{
        "operations": [
          { "type": "replace", "file": $file, "start_line": 1, "end_line": 2, "content": $content }
        ]
      }' > "$json_file"

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1

    assert_content_equals "$target_file" "$new_content" || return 1
    return 0
}

# Test 4: Handling of large content blocks (e.g., 500 lines)
test_llm_large_content() {
    local target_file="$TMP_DIR/large_file.txt"
    local content_to_insert_file="$TMP_DIR/large_content.txt"

    # Create a 500-line content block
    for i in $(seq 1 500); do
        echo "This is line $i of a large content block." >> "$content_to_insert_file"
    done
    local large_content=$(cat "$content_to_insert_file")

    local json_file="$TMP_DIR/large.json"
    jq -n \
        --arg file "$target_file" \
        --arg content "$large_content" \
        '{ "operations": [ { "type": "create", "file": $file, "content": $content } ] }' > "$json_file"

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1

    assert_file_exists "$target_file" || return 1
    assert_line_count "$target_file" 500 || return 1
    assert_contains "$target_file" "This is line 500" || return 1
    return 0
}


# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    run_test "test_llm_complex_json" test_llm_complex_json
    run_test "test_llm_line_precision" test_llm_line_precision
    run_test "test_llm_special_characters" test_llm_special_characters
    run_test "test_llm_large_content" test_llm_large_content

    print_summary
    exit ${TEST_FAILED}
fi
