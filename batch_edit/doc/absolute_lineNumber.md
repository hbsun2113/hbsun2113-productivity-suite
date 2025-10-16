# Batch Edit Tool - Absolute Line Number Requirements

## 1. Executive Summary

This document outlines the requirements for modifying the `batch_edit.sh` tool to use absolute line numbers (based on the original file state) instead of relative line numbers (based on the dynamically changing file state after each operation).

## 2. Problem Statement

### Current Behavior
- Operations are executed sequentially, with each operation working on the result of the previous operation
- Line numbers in later operations must account for changes made by earlier operations
- Users (especially LLMs) must mentally calculate line number shifts caused by each operation

### Example of Current Problem
```json
{
  "operations": [
    {"type": "delete", "file": "/path/file.py", "start_line": 10, "end_line": 15},
    {"type": "insert", "file": "/path/file.py", "line": 20, "content": "new code"}
  ]
}
```
In current implementation, `line: 20` refers to line 20 AFTER the deletion (which would be original line 25).

### User Impact
- High cognitive load when defining multiple operations
- Error-prone due to manual line number calculations
- Difficult to verify correctness by looking at the original file

## 3. Proposed Solution

### Core Requirement
All line numbers in all operations should reference the **original file state** (before any operations are applied).

### Desired Behavior
```json
{
  "operations": [
    {"type": "delete", "file": "/path/file.py", "start_line": 10, "end_line": 15},
    {"type": "insert", "file": "/path/file.py", "line": 20, "content": "new code"}
  ]
}
```
`line: 20` should refer to line 20 of the ORIGINAL file, regardless of previous operations.

## 4. Functional Requirements

### 4.1 Line Number Reference
- All line numbers MUST reference the original file state
- The tool MUST internally handle line number adjustments
- Line number semantics remain unchanged (1-based indexing)

### 4.2 Operation Execution Strategy
- The tool MUST intelligently reorder operations for optimal execution
- Execution order MUST NOT affect the final result
- Original operation indices MUST be preserved for error reporting

### 4.3 Conflict Detection
The tool MUST detect and reject conflicting operations:
- Operations with overlapping line ranges
- Insert operations within delete ranges
- Replace operations that span deleted regions

### 4.4 Operation Priority Rules
Suggested execution order (per file):
1. **create** operations (no line numbers involved)
2. Operations sorted by line number (descending) to minimize adjustments
3. **patch** operations (content-based, not line-based)

### 4.5 Backward Compatibility
- Existing JSON structure remains the same
- No new fields required
- Behavior change is transparent to users

## 5. Technical Requirements

### 5.1 Algorithm Requirements
- Implement operation sorting algorithm
- Implement conflict detection algorithm
- Maintain operation metadata for error reporting

### 5.2 Error Handling
- Error messages MUST reference original operation indices
- Conflicts MUST be detected during validation phase
- Clear error messages explaining why operations conflict

### 5.3 Performance
- Sorting overhead should be minimal (O(n log n) acceptable)
- Conflict detection should be efficient (O(n²) acceptable for small n)

## 6. Use Cases

### Use Case 1: Multiple Deletions
```json
{
  "operations": [
    {"type": "delete", "file": "/a.py", "start_line": 5, "end_line": 10},
    {"type": "delete", "file": "/a.py", "start_line": 15, "end_line": 20},
    {"type": "delete", "file": "/a.py", "start_line": 25, "end_line": 30}
  ]
}
```
All line numbers reference the original file. Tool executes from bottom to top.

### Use Case 2: Mixed Operations
```json
{
  "operations": [
    {"type": "insert", "file": "/a.py", "line": 5, "content": "import os"},
    {"type": "delete", "file": "/a.py", "start_line": 10, "end_line": 12},
    {"type": "replace", "file": "/a.py", "start_line": 20, "end_line": 22, "content": "new_function()"}
  ]
}
```
Tool reorders to: replace (20-22) → delete (10-12) → insert (5)

### Use Case 3: Conflict Detection
```json
{
  "operations": [
    {"type": "delete", "file": "/a.py", "start_line": 10, "end_line": 20},
    {"type": "replace", "file": "/a.py", "start_line": 15, "end_line": 18, "content": "new"}
  ]
}
```
Tool rejects with error: "Operation 2 conflicts with operation 1: line range 15-18 overlaps with deletion range 10-20"

## 7. Edge Cases

### 7.1 Created Files
- Operations on newly created files reference the created content
- Line numbers start from 1 for the created content

### 7.2 Empty Files
- Line number validation adjusted for empty files
- Insert at line 0 (prepend) and line -1 (append) still work

### 7.3 Patch Operations
- Always executed last since they're content-based
- Not affected by line number changes

## 8. Testing Requirements

### 8.1 Unit Tests
- Test operation sorting algorithm
- Test conflict detection
- Test line number adjustment calculations

### 8.2 Integration Tests
- Test complex multi-operation scenarios
- Test error cases and conflict scenarios
- Test all operation types with absolute line numbers

### 8.3 Regression Tests
- Ensure all existing operation types still work
- Ensure backup/rollback mechanism remains functional

## 9. Implementation Strategy

### Phase 1: Design Validation
- Review and approve the sorting algorithm
- Review conflict detection logic
- Finalize execution order rules

### Phase 2: Implementation
1. Add operation metadata structure
2. Implement sorting algorithm
3. Implement conflict detection
4. Modify execution functions to work with sorted operations
5. Update error messages to reference original indices

### Phase 3: Testing
- Comprehensive testing of new behavior
- Edge case validation
- Performance testing with large operation sets

## 10. Success Criteria

- Users can specify all line numbers based on the original file
- No mental calculation of line shifts required
- Operations execute correctly regardless of definition order
- Conflicts are detected and reported clearly
- Performance impact is negligible
- All existing features continue to work

## 11. Benefits

### For LLM Users
- Dramatically reduced cognitive load
- More intuitive operation definition
- Lower error rates
- Easier to verify correctness

### For Human Users
- Matches IDE behavior and expectations
- No need to track cumulative changes
- Can plan all operations by looking at original file once

## 12. Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Complex implementation | Use well-tested sorting algorithms |
| Potential bugs in reordering | Comprehensive test suite |
| User confusion about behavior change | Clear documentation and examples |
| Performance impact | Optimize for common cases (few operations per file) |

## 13. Acceptance Criteria

- [ ] All operations use absolute line numbers
- [ ] Conflict detection prevents invalid operation sets
- [ ] Error messages reference original operation order
- [ ] Performance acceptable for up to 100 operations
- [ ] All existing tests pass
- [ ] New tests cover absolute line number behavior
- [ ] Documentation updated with examples

## 14. Future Enhancements

- Add `--dry-run` flag to preview execution order
- Add `reference_mode` field to support both absolute and relative modes
- Add visualization of operation effects
- Support for operation dependencies/ordering hints
