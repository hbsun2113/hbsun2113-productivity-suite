#!/bin/bash

# Test cases for Complex Real-world Scenarios

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Code refactoring scenario - rename function across multiple files
test_code_refactoring_scenario() {
    local dir="$TMP_DIR/refactor"
    mkdir -p "$dir"
    
    # Create source files with function calls
    cat > "$dir/main.py" << 'EOF'
def old_function():
    return "hello"

def main():
    result = old_function()
    print(result)
EOF

    cat > "$dir/utils.py" << 'EOF'
from main import old_function

def helper():
    return old_function() + " world"
EOF

    # JSON to rename function across all files
    local json_file="$TMP_DIR/refactor.json"
    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "patch",
            "file": "$dir/main.py",
            "find": "def old_function():",
            "replace": "def new_function():",
            "all": false
        },
        {
            "type": "patch",
            "file": "$dir/main.py",
            "find": "old_function()",
            "replace": "new_function()",
            "all": true
        },
        {
            "type": "patch",
            "file": "$dir/utils.py",
            "find": "old_function",
            "replace": "new_function",
            "all": true
        }
    ]
}
EOF

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1
    
    # Verify all replacements worked
    assert_contains "$dir/main.py" "def new_function():" || return 1
    assert_contains "$dir/main.py" "new_function()" || return 1
    
    # Check that old function definition is gone
    if grep -q "def old_function():" "$dir/main.py"; then
        log_test_fail "Function definition should be renamed"
        return 1
    fi
    
    assert_contains "$dir/utils.py" "new_function" || return 1
    if grep -q "old_function" "$dir/utils.py"; then
        log_test_fail "All references to old_function should be replaced"
        return 1
    fi
    
    return 0
}

# Test 2: Configuration file migration scenario
test_config_migration_scenario() {
    local dir="$TMP_DIR/config"
    mkdir -p "$dir"
    
    # Create old config files
    cat > "$dir/app.conf" << 'EOF'
[database]
host=localhost
port=5432
user=admin
password=secret

[cache]
type=redis
host=localhost
port=6379
EOF

    local json_file="$TMP_DIR/migration.json"
    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "insert",
            "file": "$dir/app.conf",
            "line": 1,
            "content": "# Migrated configuration v2.0"
        },
        {
            "type": "patch",
            "file": "$dir/app.conf",
            "find": "password=secret",
            "replace": "password_file=/etc/secrets/db_password",
            "all": false
        },
        {
            "type": "insert",
            "file": "$dir/app.conf",
            "line": -1,
            "content": "\n[security]\nssl_enabled=true\ncert_file=/etc/ssl/app.crt"
        }
    ]
}
EOF

    run_batch_edit "$json_file"
    assert_exit_code 0 $? || return 1
    
    # Verify migration worked
    assert_contains "$dir/app.conf" "# Migrated configuration v2.0" || return 1
    assert_contains "$dir/app.conf" "password_file=/etc/secrets/db_password" || return 1
    if grep -q "password=secret" "$dir/app.conf"; then
        log_test_fail "Old password setting should be replaced"
        return 1
    fi
    assert_contains "$dir/app.conf" "[security]" || return 1
    assert_contains "$dir/app.conf" "ssl_enabled=true" || return 1
    
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running Complex Scenario tests..."
    echo ""

    run_test "code_refactoring_scenario" test_code_refactoring_scenario
    run_test "config_migration_scenario" test_config_migration_scenario

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi
