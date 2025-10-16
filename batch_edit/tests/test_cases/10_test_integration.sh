#!/bin/bash

# Test cases for Integration Scenarios

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Refactoring - Rename a variable across multiple files
test_integration_refactor() {
    local dir="$TMP_DIR/project"
    mkdir -p "$dir"
    local file1="$dir/main.js"
    local file2="$dir/utils.js"
    local file3="$dir/config.js"

    # Create initial project files
    cat > "$file1" << 'EOF'
import { old_variable } from './utils';
console.log(old_variable);
const local_var = old_variable + 1;
EOF
    cat > "$file2" << 'EOF'
export const old_variable = 42;
function some_func() { return old_variable; }
EOF
    cat > "$file3" << 'EOF'
// Config related to old_variable
const config = { setting: 'value' };
EOF

    local json_file="$TMP_DIR/refactor.json"

    # Create a batch operation to rename 'old_variable' to 'new_variable'
    jq -n \
      --arg f1 "$file1" --arg f2 "$file2" --arg f3 "$file3" \
      '{
        "operations": [
          {
            "type": "patch", "file": $f1,
            "find": "old_variable", "replace": "new_variable", "all": true
          },
          {
            "type": "patch", "file": $f2,
            "find": "old_variable", "replace": "new_variable", "all": true
          },
          {
            "type": "patch", "file": $f3,
            "find": "old_variable", "replace": "new_variable", "all": true
          }
        ]
      }' > "$json_file"

    run_batch_edit "$json_file"
    local exit_code=$?
    assert_exit_code 0 $exit_code || return 1

    # Assertions
    assert_not_contains "$file1" "old_variable" || return 1
    assert_contains "$file1" "new_variable" || return 1

    assert_not_contains "$file2" "old_variable" || return 1
    assert_contains "$file2" "new_variable" || return 1

    assert_not_contains "$file3" "old_variable" || return 1
    assert_contains "$file3" "new_variable" || return 1

    return 0
}

# Test 2: Project setup - Create multiple config files from a template
test_integration_project_setup() {
    local dir="$TMP_DIR/new_project"
    local template_file="$dir/template.conf"

    # Assume batch_edit will create the directory
    # mkdir -p "$dir"

    cat > "$template_file" << 'EOF'
# Base Configuration
SETTING_A={{PLACEHOLDER_A}}
SETTING_B={{PLACEHOLDER_B}}
EOF

    local file1="$dir/prod.conf"
    local file2="$dir/dev.conf"

    local json_file="$TMP_DIR/setup.json"

    # Batch op to create prod and dev configs from template
    jq -n \
      --arg tpl "$(cat "$template_file")" \
      --arg f1 "$file1" --arg f2 "$file2" \
      '{
        "operations": [
          # Create prod config
          { "type": "create", "file": $f1, "content": $tpl },
          { "type": "patch", "file": $f1, "find": "{{PLACEHOLDER_A}}", "replace": "prod_value_a" },
          { "type": "patch", "file": $f1, "find": "{{PLACEHOLDER_B}}", "replace": "prod_value_b" },

          # Create dev config
          { "type": "create", "file": $f2, "content": $tpl },
          { "type": "patch", "file": $f2, "find": "{{PLACEHOLDER_A}}", "replace": "dev_value_a" },
          { "type": "patch", "file": $f2, "find": "{{PLACEHOLDER_B}}", "replace": "dev_value_b" }
        ]
      }' > "$json_file"


    run_batch_edit "$json_file"
    local exit_code=$?
    assert_exit_code 0 $exit_code || return 1

    assert_file_exists "$file1" || return 1
    assert_contains "$file1" "SETTING_A=prod_value_a" || return 1
    assert_contains "$file1" "SETTING_B=prod_value_b" || return 1
    assert_not_contains "$file1" "PLACEHOLDER" || return 1

    assert_file_exists "$file2" || return 1
    assert_contains "$file2" "SETTING_A=dev_value_a" || return 1
    assert_contains "$file2" "SETTING_B=dev_value_b" || return 1
    assert_not_contains "$file2" "PLACEHOLDER" || return 1

    return 0
}


# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running Integration tests..."
    echo ""

    # Need to create the template file for test_integration_project_setup before running it
    mkdir -p "$TMP_DIR/new_project"
    cat > "$TMP_DIR/new_project/template.conf" << 'EOF'
# Base Configuration
SETTING_A={{PLACEHOLDER_A}}
SETTING_B={{PLACEHOLDER_B}}
EOF

    run_test "integration_refactor" test_integration_refactor
    run_test "integration_project_setup" test_integration_project_setup

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi