#!/bin/bash

# Test cases for LLM Multi-File Project Edits (14_test_llm_multi_file_edits.sh)

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Cross-file dependency updates
test_llm_dependency_update() {
    local dir="$TMP_DIR/project_dep"
    mkdir -p "$dir"
    local main_file="$dir/main.js"
    local old_util_file="$dir/old_utils.js"
    local new_util_file="$dir/new_utils.js"

    cat > "$main_file" << 'EOF'
import { helper } from './old_utils.js';
helper();
EOF
    cat > "$old_util_file" << 'EOF'
export function helper() { console.log("Old helper"); }
EOF

    # Operation: Move helper to new_utils.js and update import in main.js
    local json_file="$TMP_DIR/dep_update.json"
    local new_util_content='export function helper() { console.log("New helper"); }'
    local new_main_content="import { helper } from './new_utils.js';\nhelper();"

    jq -n \
      --arg main "$main_file" \
      --arg old_util "$old_util_file" \
      --arg new_util "$new_util_file" \
      --arg n_util_c "$new_util_content" \
      --arg n_main_c "$new_main_content" \
      '{
        "operations": [
          { "type": "create", "file": $new_util, "content": $n_util_c },
          { "type": "delete", "file": $old_util, "start_line": 1, "end_line": 1 },
          { "type": "replace", "file": $main, "start_line": 1, "end_line": 2, "content": $n_main_c }
        ]
      }' > "$json_file"

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1

    assert_file_exists "$new_util_file" || return 1
    assert_contains "$new_util_file" "New helper" || return 1
    assert_content_equals "$old_util_file" "" || return 1
    assert_contains "$main_file" "./new_utils.js" || return 1
    return 0
}

# Test 2: Large-scale parallel modifications (20 files, 50 ops)
test_llm_large_scale_edits() {
    local dir="$TMP_DIR/large_project"
    mkdir -p "$dir"
    local operations_str=""

    for i in $(seq 1 20); do
        local file_path="$dir/file_$i.txt"
        echo "Initial content for file $i" > "$file_path"
        # 1 create, 1 replace, 1 insert = 3 ops per file * 20 files = 60 ops total
        operations_str+=$(printf '{"type": "create", "file": "%s.new", "content": "New file for %d"},' "$file_path" "$i")
        operations_str+=$(printf '{"type": "replace", "file": "%s", "start_line": 1, "end_line": 1, "content": "Replaced content for %d"},' "$file_path" "$i")
        operations_str+=$(printf '{"type": "insert", "file": "%s", "line": -1, "content": "Appended line for %d"},' "$file_path" "$i")
    done
    operations_str=${operations_str%,}

    local json_file="$TMP_DIR/large_scale.json"
    echo "{\"operations\": [$operations_str]}" > "$json_file"

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1

    for i in $(seq 1 20); do
        local file_path="$dir/file_$i.txt"
        assert_file_exists "$file_path.new" || return 1
        assert_contains "$file_path" "Replaced content for $i" || return 1
        assert_contains "$file_path" "Appended line for $i" || return 1
        assert_line_count "$file_path" 2 || return 1
    done
    return 0
}


# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    run_test "test_llm_dependency_update" test_llm_dependency_update
    run_test "test_llm_large_scale_edits" test_llm_large_scale_edits

    print_summary
    exit ${TEST_FAILED}
fi
