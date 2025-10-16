#!/bin/bash

# Main test runner - Pure Orchestrator

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_CASES_DIR="$SCRIPT_DIR/test_cases"
FINAL_STATUS=0

main() {
    echo "========================================"
    echo "Running batch_edit.sh Test Suite"
    echo "========================================"

    local test_files_to_run=($(find "$TEST_CASES_DIR" -type f -name "??_test_*.sh" | sort))

    for test_file in "${test_files_to_run[@]}"; do
        echo -e "\n----------------------------------------"
        echo "Executing Test File: $(basename "$test_file")"
        echo "----------------------------------------"

        # Run test file. If it fails, record it but continue.
        if ! bash "$test_file"; then
            echo -e "\n[ERROR] Test file $(basename "$test_file") failed." >&2
            FINAL_STATUS=1
        fi
    done

    echo -e "\n========================================"
    if [[ $FINAL_STATUS -eq 0 ]]; then
        echo "✅ All test files passed successfully."
        exit 0
    else
        echo "❌ Some test files reported failures."
        exit 1
    fi
    echo "========================================"
}

main "$@"