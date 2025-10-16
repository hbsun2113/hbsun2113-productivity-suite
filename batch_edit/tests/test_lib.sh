#!/bin/bash

# Test framework core library - FINAL, SIMPLIFIED VERSION


# --- Global State ---
TEST_PASSED=0
TEST_FAILED=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATCH_EDIT_DIR="$(dirname "$SCRIPT_DIR")"
BATCH_EDIT_SCRIPT="$BATCH_EDIT_DIR/batch_edit.sh"
TMP_DIR="$SCRIPT_DIR/tmp"
RESULTS_DIR="$SCRIPT_DIR/results"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# --- Core Functions ---

# Helper function for negative assertions
assert_not_contains() {
    local file="$1"
    local pattern="$2"
    
    if grep -q "$pattern" "$file"; then
        log_test_fail "File $file should NOT contain '$pattern'"
        return 1
    fi
    return 0
}
init_test_env() {
    # This is now called by each test file
    rm -rf "$TMP_DIR" "$RESULTS_DIR"
    mkdir -p "$TMP_DIR" "$RESULTS_DIR"
}

cleanup_test_env() {
    rm -rf "$TMP_DIR"
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    echo -n "Testing $test_name... "
    # We don't use a subshell to ensure TEST_PASSED/FAILED are modified in the current shell
    if "$test_function"; then
        echo -e "${GREEN}✓${NC}"
        ((TEST_PASSED++))
    else
        echo -e "${RED}✗${NC}"
        # Failure reason is now printed inside the test function
        ((TEST_FAILED++))
    fi
}

print_summary() {
    local total=$((TEST_PASSED + TEST_FAILED))
    echo ""
    echo "========================================"
    echo "Test Summary:"
    echo " Passed: $TEST_PASSED, Failed: $TEST_FAILED, Total: $total"
    echo "========================================"

    if [[ $TEST_FAILED -ne 0 ]]; then
        return 1
    fi
    return 0
}

run_batch_edit() {
    # This helper is for convenience within test functions
    "$BATCH_EDIT_SCRIPT" --log-level ERROR "$@" 2> "$TMP_DIR/batch_edit_output.txt"
}

log_test_fail() {
    echo "  [FAIL] $1" >&2
}

# --- Assertion Functions ---
# They are now responsible for printing the failure reason
assert_exit_code() {
    local expected="$1"
    local actual="$2"
    if [[ "$actual" -ne "$expected" ]]; then
        echo "  [FAIL] Exit code mismatch: expected $expected, got $actual" >&2
        return 1
    fi
}

assert_file_exists() {
    if [[ ! -f "$1" ]]; then
        echo "  [FAIL] File not found: $1" >&2
        return 1
    fi
}

assert_file_not_exists() {
    if [[ -f "$1" ]]; then
        echo "  [FAIL] File should not exist: $1" >&2
        return 1
    fi
}

assert_content_equals() {
    local file="$1"
    local expected="$2"
    local actual
    actual=$(cat "$file")
    if [[ "$actual" != "$expected" ]]; then
        echo "  [FAIL] Content mismatch in $file" >&2
        echo "    Expected: '$expected'" >&2
        echo "    Actual:   '$actual'" >&2
        return 1
    fi
}
# ... add other assertions in the same style ...
assert_line_count() {
    local file="$1"
    local expected_count="$2"
    local actual_count=$(wc -l < "$file")
    if [[ "$actual_count" -ne "$expected_count" ]]; then
        echo "  [FAIL] Line count in $file: expected $expected_count, got $actual_count" >&2
        return 1
    fi
}

assert_contains() {
    local file="$1"
    local search_string="$2"
    if ! grep -qF "$search_string" "$file"; then
        echo "  [FAIL] File $file does not contain '$search_string'" >&2
        return 1
    fi
}

assert_not_contains() {
    local file="$1"
    local search_string="$2"
    if grep -qF "$search_string" "$file"; then
        echo "  [FAIL] File $file should not contain '$search_string'" >&2
        return 1
    fi
}
