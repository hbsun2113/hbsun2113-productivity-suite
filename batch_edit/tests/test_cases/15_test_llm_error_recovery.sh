#!/bin/bash

# Test cases for LLM Error Recovery & Edge Cases (15_test_llm_error_recovery.sh)

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Malformed JSON syntax
test_llm_malformed_json() {
    local json_file="$TMP_DIR/malformed.json"
    echo '{ "operations": [ { "type": "create", "file": "/tmp/test.txt" } ' > "$json_file" # Missing closing bracket and brace

    run_batch_edit "$json_file"
    local exit_code=$?
    assert_exit_code 1 "$exit_code" || return 1

    local output_file="$TMP_DIR/batch_edit_output.txt"
    assert_contains "$output_file" "Invalid JSON syntax" || return 1
    return 0
}

# Test 2: Line number out of range
test_llm_line_out_of_range() {
    local target_file="$TMP_DIR/range_error.txt"
    echo "Line 1" > "$target_file"

    local json_file="$TMP_DIR/range.json"
    jq -n \
      --arg file "$target_file" \
      '{
        "operations": [
          { "type": "insert", "file": $file, "line": 10, "content": "This should fail" }
        ]
      }' > "$json_file"

    run_batch_edit "$json_file"
    local exit_code=$?
    assert_exit_code 1 "$exit_code" || return 1

    local output_file="$TMP_DIR/batch_edit_output.txt"
    assert_contains "$output_file" "exceeds file length" || return 1
    return 0
}

# Test 3: Overlapping operations conflict
test_llm_conflict_detection() {
    local target_file="$TMP_DIR/conflict.txt"
    cat > "$target_file" << 'EOF'
Line 1
Line 2
Line 3
Line 4
Line 5
EOF

    local json_file="$TMP_DIR/conflict.json"
    jq -n \
      --arg file "$target_file" \
      '{
        "operations": [
          { "type": "delete", "file": $file, "start_line": 2, "end_line": 4 },
          { "type": "replace", "file": $file, "start_line": 3, "end_line": 5, "content": "Conflict" }
        ]
      }' > "$json_file"

    run_batch_edit "$json_file"
    local exit_code=$?
    assert_exit_code 1 "$exit_code" || return 1

    local output_file="$TMP_DIR/batch_edit_output.txt"
    assert_contains "$output_file" "conflicts with operation" || return 1
    return 0
}

# Test 4: Full rollback on failure
test_llm_full_rollback() {
    local file1="$TMP_DIR/rollback_1.txt"
    local file2="$TMP_DIR/rollback_2.txt"
    local original_content_1="Original content 1"
    local original_content_2="Original content 2"
    echo "$original_content_1" > "$file1"
    echo "$original_content_2" > "$file2"

    local json_file="$TMP_DIR/rollback.json"
    jq -n \
      --arg f1 "$file1" \
      --arg f2 "$file2" \
      '{
        "operations": [
          { "type": "replace", "file": $f1, "start_line": 1, "end_line": 1, "content": "Updated 1" },
          { "type": "insert", "file": $f2, "line": 10, "content": "This will fail" }
        ]
      }' > "$json_file"

    run_batch_edit "$json_file"
    local exit_code=$?
    assert_exit_code 1 "$exit_code" || return 1

    # Verify that file1 was restored to its original state
    assert_content_equals "$file1" "$original_content_1" || return 1
    assert_content_equals "$file2" "$original_content_2" || return 1
    return 0
}


# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    run_test "test_llm_malformed_json" test_llm_malformed_json
    run_test "test_llm_line_out_of_range" test_llm_line_out_of_range
    run_test "test_llm_conflict_detection" test_llm_conflict_detection
    run_test "test_llm_full_rollback" test_llm_full_rollback

    print_summary
    exit ${TEST_FAILED}
fi
