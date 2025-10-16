# Absolute Line Number Implementation Plan

## Overview

This document provides a progressive implementation plan for converting the `batch_edit.sh` tool to use absolute line numbers (based on original file state) instead of relative line numbers (based on dynamically changing file state).

## Implementation Strategy

### Core Approach
- **Smart Execution Ordering**: Process operations in optimal order (high line numbers first) to minimize line number adjustments
- **Conflict Detection**: Detect overlapping operations during validation phase
- **Metadata Preservation**: Keep original operation indices for error reporting
- **Backward Compatibility**: No changes to JSON input format

## Phase 1: Foundation and Analysis

### 1.1 Create Test Framework
- **Priority**: High
- **Effort**: 2-3 hours
- **Dependencies**: None

**Tasks:**
- [ ] Create `test_cases/` directory structure
- [ ] Create basic test runner script
- [ ] Set up sample test files with known content
- [ ] Create test JSON files covering all operation types
- [ ] Verify current behavior with test cases

### 1.2 Create Backup of Current Implementation
- **Priority**: High
- **Effort**: 30 minutes
- **Dependencies**: None

**Tasks:**
- [ ] Copy `batch_edit.sh` to `batch_edit_original.sh`
- [ ] Document current behavior with examples
- [ ] Create rollback plan if needed

### 1.3 Add Enhanced Logging and Debug Mode
- **Priority**: Medium
- **Effort**: 1-2 hours
- **Dependencies**: None

**Tasks:**
- [ ] Add `--debug` flag for detailed operation tracking
- [ ] Log operation processing order
- [ ] Log line number calculations
- [ ] Add operation metadata logging

## Phase 2: Core Algorithm Implementation

### 2.1 Implement Operation Metadata Structure
- **Priority**: High
- **Effort**: 2-3 hours
- **Dependencies**: 1.3

**Tasks:**
- [ ] Add global arrays for operation metadata:
  - `OPERATION_ORIGINAL_INDEX[]`
  - `OPERATION_PRIORITY[]`
  - `OPERATION_SORT_KEY[]`
- [ ] Modify `validate_operations()` to populate metadata
- [ ] Add helper functions for metadata access

### 2.2 Implement Operation Sorting Algorithm
- **Priority**: High
- **Effort**: 3-4 hours
- **Dependencies**: 2.1

**Tasks:**
- [ ] Create `sort_operations_by_file()` function
- [ ] Implement priority-based sorting:
  - Priority 0: `create` operations
  - Priority 1: `delete`, `replace`, `insert` (by descending line number)
  - Priority 2: `patch` operations
- [ ] Create `generate_execution_order()` function
- [ ] Test sorting with sample operation sets

### 2.3 Implement Conflict Detection
- **Priority**: High
- **Effort**: 3-4 hours
- **Dependencies**: 2.1

**Tasks:**
- [ ] Create `detect_line_conflicts()` function
- [ ] Implement overlap detection for same-file operations:
  - Delete vs Delete overlap
  - Delete vs Replace overlap
  - Replace vs Replace overlap
  - Insert within Delete range
- [ ] Add conflict error messages with original indices
- [ ] Test conflict detection with edge cases

## Phase 3: Execution Engine Modification

### 3.1 Modify Main Execution Flow
- **Priority**: High
- **Effort**: 2-3 hours
- **Dependencies**: 2.2, 2.3

**Tasks:**
- [ ] Update `execute_operations()` to use sorted order
- [ ] Preserve original index mapping for error reporting
- [ ] Modify error messages to reference original operation numbers
- [ ] Update progress logging to show both execution and original order

### 3.2 Update Individual Operation Functions
- **Priority**: Medium
- **Effort**: 2-3 hours
- **Dependencies**: 3.1

**Tasks:**
- [ ] Update `op_create()`, `op_replace()`, `op_insert()`, `op_delete()`, `op_patch()`
- [ ] Ensure error messages include original operation index
- [ ] Add debug logging for line number usage
- [ ] Verify all operations work with reordered execution

### 3.3 Handle Created Files Edge Case
- **Priority**: Medium
- **Effort**: 1-2 hours
- **Dependencies**: 3.1

**Tasks:**
- [ ] Track files created during execution
- [ ] Modify validation for operations on created files
- [ ] Ensure operations on created files use created content as reference
- [ ] Test mixed create/modify scenarios

## Phase 4: Testing and Validation

### 4.1 Unit Testing
- **Priority**: High
- **Effort**: 4-5 hours
- **Dependencies**: 3.2

**Tasks:**
- [ ] Test operation sorting algorithm:
  - Single file, multiple operations
  - Multiple files with different operation types
  - Edge cases (empty operations, single operation)
- [ ] Test conflict detection:
  - All types of overlaps
  - Edge cases (adjacent lines, single line operations)
- [ ] Test metadata preservation:
  - Original indices in error messages
  - Correct operation tracking

### 4.2 Integration Testing
- **Priority**: High
- **Effort**: 3-4 hours
- **Dependencies**: 4.1

**Tasks:**
- [ ] Test complex scenarios from requirements:
  - Multiple deletions (Use Case 1)
  - Mixed operations (Use Case 2)
  - Conflict scenarios (Use Case 3)
- [ ] Test all operation types with absolute line numbers
- [ ] Test edge cases:
  - Empty files
  - Created files with subsequent operations
  - Large files with many operations

### 4.3 Regression Testing
- **Priority**: High
- **Effort**: 2-3 hours
- **Dependencies**: 4.2

**Tasks:**
- [ ] Run all existing functionality tests
- [ ] Verify backup/rollback mechanism still works
- [ ] Test error handling and cleanup
- [ ] Performance testing with large operation sets
- [ ] Compare results with original implementation (where applicable)

## Phase 5: Documentation and Finalization

### 5.1 Update Documentation
- **Priority**: Medium
- **Effort**: 2-3 hours
- **Dependencies**: 4.3

**Tasks:**
- [ ] Update script header comments
- [ ] Add usage examples showing absolute line number behavior
- [ ] Document new debug options
- [ ] Update error message reference guide

### 5.2 Code Cleanup and Optimization
- **Priority**: Low
- **Effort**: 1-2 hours
- **Dependencies**: 5.1

**Tasks:**
- [ ] Remove debug code not needed in production
- [ ] Optimize sorting algorithm if needed
- [ ] Clean up variable naming and comments
- [ ] Final code review

### 5.3 Create Migration Guide
- **Priority**: Low
- **Effort**: 1 hour
- **Dependencies**: 5.2

**Tasks:**
- [ ] Document behavior changes
- [ ] Provide before/after examples
- [ ] Create troubleshooting guide
- [ ] Add performance notes

## Implementation Details

### Key Functions to Add/Modify

```bash
# New functions to add
sort_operations_by_file()      # Core sorting algorithm
detect_line_conflicts()        # Conflict detection
generate_execution_order()     # Create execution plan
get_operation_metadata()       # Access metadata by index

# Existing functions to modify
validate_operations()          # Add metadata population
execute_operations()           # Use sorted order
op_create(), op_replace(), etc. # Update error reporting
error_exit()                   # Include original indices
```

### Data Structures

```bash
# Global arrays for operation metadata
declare -a OPERATION_ORIGINAL_INDEX
declare -a OPERATION_PRIORITY
declare -a OPERATION_SORT_KEY
declare -a OPERATION_FILE_GROUP
declare -a EXECUTION_ORDER
```

### Algorithm Pseudocode

```bash
1. Parse and validate operations (existing)
2. Populate operation metadata
3. Group operations by file
4. For each file group:
   - Check for conflicts
   - Sort by priority and line number
5. Generate final execution order
6. Execute operations in computed order
7. Map any errors back to original indices
```

## Risk Mitigation

### High-Risk Areas
1. **Complex sorting logic**: Mitigate with extensive unit tests
2. **Edge cases with created files**: Test thoroughly with mixed scenarios
3. **Error message mapping**: Ensure all error paths preserve original indices
4. **Performance impact**: Profile with large operation sets

### Rollback Plan
- Keep original `batch_edit.sh` as `batch_edit_original.sh`
- All tests must pass before considering implementation complete
- Gradual rollout: test with simple cases first

## Timeline Estimation

- **Phase 1**: 1 day (Foundation)
- **Phase 2**: 2-3 days (Core algorithms)
- **Phase 3**: 2 days (Execution engine)
- **Phase 4**: 2-3 days (Testing)
- **Phase 5**: 1 day (Documentation)

**Total Estimated Time**: 8-10 days of focused development

## Success Metrics

- [ ] All operations reference original file line numbers
- [ ] Conflicts detected and reported with clear messages
- [ ] No regression in existing functionality
- [ ] Performance acceptable for realistic operation sets (<100 operations)
- [ ] Error messages reference original operation indices
- [ ] All test cases pass

## Dependencies and Prerequisites

- `jq` (JSON processing) - already required
- `bash` 4.0+ for associative arrays
- Sufficient test coverage before implementation
- Understanding of current operation semantics

## Notes

- Implementation preserves existing JSON format completely
- Change is transparent to users - only internal behavior changes
- Focus on correctness over performance optimization initially
- All existing safety mechanisms (backup/rollback) remain intact
