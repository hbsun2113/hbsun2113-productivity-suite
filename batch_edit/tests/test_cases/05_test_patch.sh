#!/bin/bash

# Test cases for PATCH operation

source "$(dirname "${BASH_SOURCE[0]}")/../test_lib.sh"

# Test 1: Basic patch (single replacement)
test_patch_basic() {
    local json_file="$TMP_DIR/patch_basic.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Hello world
This is a test
Hello again
EOF

    # Create JSON operations file
    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "patch",
            "file": "$target_file",
            "find": "Hello",
            "replace": "Hi"
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
    assert_contains "$target_file" "Hi world" || return 1
    assert_contains "$target_file" "This is a test" || return 1
    assert_contains "$target_file" "Hello again" || return 1

    # Check that only first occurrence was replaced
    local hello_count=$(grep -c "Hello" "$target_file")
    if [[ $hello_count -ne 1 ]]; then
        log_test_fail "Expected 1 'Hello', found $hello_count"
        return 1
    fi

    return 0
}

# Test 2: Patch with all flag (replace all occurrences)
test_patch_all() {
    local json_file="$TMP_DIR/patch_all.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
foo bar foo
foo baz
bar foo bar
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "patch",
            "file": "$target_file",
            "find": "foo",
            "replace": "FOO",
            "all": true
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_contains "$target_file" "FOO bar FOO" || return 1
    assert_contains "$target_file" "FOO baz" || return 1
    assert_contains "$target_file" "bar FOO bar" || return 1
    assert_not_contains "$target_file" "foo" || return 1

    return 0
}

# Test 3: Patch with empty replacement (delete pattern)
test_patch_delete() {
    local json_file="$TMP_DIR/patch_delete.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
Remove TODO: this part
Keep this
Remove TODO: this too
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "patch",
            "file": "$target_file",
            "find": "TODO: ",
            "replace": "",
            "all": true
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_contains "$target_file" "Remove this part" || return 1
    assert_contains "$target_file" "Keep this" || return 1
    assert_contains "$target_file" "Remove this too" || return 1
    assert_not_contains "$target_file" "TODO:" || return 1

    return 0
}

# Test 4: Patch with special characters
test_patch_special_chars() {
    local json_file="$TMP_DIR/patch_special.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file with special characters
    cat > "$target_file" << 'EOF'
Path: /home/user/file.txt
Regex: [a-z]+
Variable: $VAR
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "patch",
            "file": "$target_file",
            "find": "/home/user",
            "replace": "/opt/app"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_contains "$target_file" "Path: /opt/app/file.txt" || return 1
    assert_contains "$target_file" "Regex: [a-z]+" || return 1
    assert_contains "$target_file" "Variable: \$VAR" || return 1

    return 0
}

# Test 5: Multiple patch operations
test_patch_multiple() {
    local json_file="$TMP_DIR/patch_multiple.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
The quick brown fox jumps over the lazy dog
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "patch",
            "file": "$target_file",
            "find": "quick",
            "replace": "slow"
        },
        {
            "type": "patch",
            "file": "$target_file",
            "find": "brown",
            "replace": "red"
        },
        {
            "type": "patch",
            "file": "$target_file",
            "find": "lazy",
            "replace": "sleeping"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_contains "$target_file" "The slow red fox jumps over the sleeping dog" || return 1

    return 0
}

# Test 6: Patch on multiline file
test_patch_multiline() {
    local json_file="$TMP_DIR/patch_multiline.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
function old_name() {
    console.log("old_name called");
    return old_name_result;
}

// Call old_name function
old_name();
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "patch",
            "file": "$target_file",
            "find": "old_name",
            "replace": "new_name",
            "all": true
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_contains "$target_file" "function new_name()" || return 1
    assert_contains "$target_file" "console.log(\"new_name called\");" || return 1
    assert_contains "$target_file" "return new_name_result;" || return 1
    assert_contains "$target_file" "// Call new_name function" || return 1
    assert_contains "$target_file" "new_name();" || return 1
    assert_not_contains "$target_file" "old_name" || return 1

    return 0
}

# Test 7: Patch after other operations
test_patch_after_ops() {
    local json_file="$TMP_DIR/patch_after_ops.json"
    local target_file="$TMP_DIR/new_file.txt"

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "create",
            "file": "$target_file",
            "content": "Create TODO item\nAnother TODO item"
        },
        {
            "type": "insert",
            "file": "$target_file",
            "line": -1,
            "content": "Final TODO item"
        },
        {
            "type": "patch",
            "file": "$target_file",
            "find": "TODO",
            "replace": "DONE",
            "all": true
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    assert_exit_code 0 $exit_code || return 1
    assert_file_exists "$target_file" || return 1
    assert_contains "$target_file" "Create DONE item" || return 1
    assert_contains "$target_file" "Another DONE item" || return 1
    assert_contains "$target_file" "Final DONE item" || return 1
    assert_not_contains "$target_file" "TODO" || return 1

    return 0
}

# Test 8: Error - Pattern not found
test_patch_not_found() {
    local json_file="$TMP_DIR/patch_not_found.json"
    local target_file="$TMP_DIR/test_file.txt"

    # Create initial file
    cat > "$target_file" << 'EOF'
This is a test file
With some content
EOF

    cat > "$json_file" << EOF
{
    "operations": [
        {
            "type": "patch",
            "file": "$target_file",
            "find": "nonexistent",
            "replace": "replacement"
        }
    ]
}
EOF

    local exit_code
    run_batch_edit "$json_file"
    exit_code=$?

    # Should succeed even if pattern not found (no changes made)
    assert_exit_code 0 $exit_code || return 1

    # File should remain unchanged
    assert_contains "$target_file" "This is a test file" || return 1
    assert_contains "$target_file" "With some content" || return 1

    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_test_env

    echo "Running PATCH operation tests..."
    echo ""

    run_test "patch_basic" test_patch_basic
    run_test "patch_all" test_patch_all
    run_test "patch_delete" test_patch_delete
    run_test "patch_special_chars" test_patch_special_chars
    run_test "patch_multiple" test_patch_multiple
    run_test "patch_multiline" test_patch_multiline
    run_test "patch_after_ops" test_patch_after_ops
    run_test "patch_not_found" test_patch_not_found

    print_summary
    exit_code=$?

    cleanup_test_env
    exit $exit_code
fi