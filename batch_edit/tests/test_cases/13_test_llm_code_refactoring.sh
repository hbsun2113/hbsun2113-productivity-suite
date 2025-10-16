#!/bin/bash

# Test cases for LLM Code Refactoring Scenarios (13_test_llm_code_refactoring.sh)

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Extract function refactoring
test_llm_extract_function() {
    local source_file="$TMP_DIR/source.js"
    local util_file="$TMP_DIR/utils.js"

    cat > "$source_file" << 'EOF'
function calculate() {
    // Complex calculation
    let result = (5 * 3) + 10;
    console.log(result);
}
calculate();
EOF

    local extracted_fn_content='function performCalculation() {
    // Complex calculation
    return (5 * 3) + 10;
}'
    local updated_source_content='import { performCalculation } from "./utils.js";
function calculate() {
    let result = performCalculation();
    console.log(result);
}
calculate();'

    local json_file="$TMP_DIR/extract.json"
    jq -n \
      --arg src "$source_file" \
      --arg util "$util_file" \
      --arg e_content "$extracted_fn_content" \
      --arg u_content "$updated_source_content" \
      '{
        "operations": [
          { "type": "create", "file": $util, "content": $e_content },
          { "type": "replace", "file": $src, "start_line": 1, "end_line": 6, "content": $u_content }
        ]
      }' > "$json_file"

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1

    assert_file_exists "$util_file" || return 1
    assert_content_equals "$util_file" "$extracted_fn_content" || return 1
    assert_content_equals "$source_file" "$updated_source_content" || return 1
    return 0
}

# Test 2: Update method signature
test_llm_update_signature() {
    local user_service="$TMP_DIR/userService.js"
    local app_main="$TMP_DIR/app.js"

    cat > "$user_service" << 'EOF'
class UserService {
    getUser(userId) {
        return `User ${userId}`;
    }
}
EOF
    cat > "$app_main" << 'EOF'
const service = new UserService();
service.getUser(123);
EOF

    local updated_service_content='class UserService {
    getUser(userId, includeDetails) {
        return `User ${userId}`;
    }
}'
    local updated_app_content='const service = new UserService();
service.getUser(123, true);'

    local json_file="$TMP_DIR/signature.json"
    jq -n \
        --arg service "$user_service" \
        --arg app "$app_main" \
        --arg u_service "$updated_service_content" \
        --arg u_app "$updated_app_content" \
      '{
        "operations": [
          { "type": "replace", "file": $service, "start_line": 1, "end_line": 5, "content": $u_service },
          { "type": "replace", "file": $app, "start_line": 1, "end_line": 2, "content": $u_app }
        ]
      }' > "$json_file"

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1

    assert_content_equals "$user_service" "$updated_service_content" || return 1
    assert_content_equals "$app_main" "$updated_app_content" || return 1
    return 0
}

# Test 3: Import management (cleanup and reorder)
test_llm_import_management() {
    local target_file="$TMP_DIR/component.js"
    cat > "$target_file" << 'EOF'
import { B } from './b';
import { C } from './c';
import { A } from './a';

// Code using A, B, C
EOF

    local new_content='import { A } from "./a";
import { B } from "./b";
import { C } from "./c";

// Code using A, B, C'

    local json_file="$TMP_DIR/imports.json"
    jq -n \
      --arg file "$target_file" \
      --arg content "$new_content" \
      '{
        "operations": [
          { "type": "replace", "file": $file, "start_line": 1, "end_line": 5, "content": $content }
        ]
      }' > "$json_file"

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1
    assert_content_equals "$target_file" "$new_content" || return 1
    return 0
}


# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    run_test "test_llm_extract_function" test_llm_extract_function
    run_test "test_llm_update_signature" test_llm_update_signature
    run_test "test_llm_import_management" test_llm_import_management

    print_summary
    exit ${TEST_FAILED}
fi
