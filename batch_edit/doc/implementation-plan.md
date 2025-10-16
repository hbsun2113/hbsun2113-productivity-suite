# Batch File Operations System Implementation Plan

## Overview
This plan implements a robust batch file operations system for Claude Code, focusing on performance optimization through consolidated file operations and comprehensive error handling with backup/rollback capabilities.

## Implementation Phases

### Phase 1: Infrastructure Setup
**Duration**: 1 implementation session
**Objective**: Create directory structure and core framework

#### Tasks:
1. ✅ Create directory structure
2. ✅ Initialize basic script template
3. ✅ Set up error handling framework
4. ✅ Create utility functions for logging

**Deliverables**:
- Directory structure (`tmp/`, `backups/`)
- Basic `batch_edit.sh` skeleton
- Core utility functions (logging, error handling)

---

### Phase 2: JSON Validation Engine
**Duration**: 1 implementation session
**Objective**: Build robust JSON parsing and validation system

#### Tasks:
1. ✅ Implement JSON syntax validation using jq
2. ✅ Create operation type validation functions
3. ✅ Build parameter validation for each operation type
4. ✅ Ensure validation logic matches execution logic
5. ✅ Create comprehensive error reporting for validation failures

**Validation Rules (Type-Specific)**:
- **create**: `file` (absolute path), `content` (string)
- **replace**: `file` (existing file), `start_line`, `end_line` (positive integers), `content` (string)
- **insert**: `file` (existing file), `line` (integer: 0=prepend, -1=append), `content` (string)
- **delete**: `file` (existing file), `start_line`, `end_line` (positive integers)
- **patch**: `file` (existing file), `find` (non-empty string), `replace` (string), `all` (optional boolean)

**Deliverables**:
- `validate_json()` function
- Type-specific validation functions: `validate_create()`, `validate_replace()`, `validate_insert()`, `validate_delete()`, `validate_patch()`
- Error reporting with operation index and specific issues

---

### Phase 3: Backup System
**Duration**: 1 implementation session
**Objective**: Implement comprehensive backup and rollback mechanism

#### Tasks:
1. ✅ Create timestamped backup directory system
2. ✅ Implement file backup before first modification
3. ✅ Build rollback function to restore all files
4. ✅ Add backup cleanup for successful operations
5. ✅ Handle edge cases (file permissions, disk space)

**Backup Strategy**:
- Create `backups/backup_YYYYMMDD_HHMMSS_PID/` directory
- Copy original files before any modifications
- Track all modified files for potential rollback
- Cleanup successful backups after 24 hours

**Deliverables**:
- `create_backup()` function
- `rollback_changes()` function
- `cleanup_backups()` function

---

### Phase 4: Core Operations Implementation
**Duration**: 2 implementation sessions
**Objective**: Implement all 5 file operations with atomic behavior

#### Session 4A: Basic Operations
**Tasks**:
1. ✅ Implement `create` operation
2. ✅ Implement `delete` operation
3. ✅ Add file existence and permission checks
4. ✅ Ensure atomic operation behavior

#### Session 4B: Complex Operations
**Tasks**:
1. ✅ Implement `replace` operation with line range handling
2. ✅ Implement `insert` operation (prepend/append/middle)
3. ✅ Implement `patch` operation with regex support
4. ✅ Add comprehensive input validation for each operation

**Operation Specifications (Type-Specific JSON)**:
- **create**: `{"type": "create", "file": "/path", "content": "..."}`
- **replace**: `{"type": "replace", "file": "/path", "start_line": 10, "end_line": 20, "content": "..."}`
- **insert**: `{"type": "insert", "file": "/path", "line": 42, "content": "..."}` (0=prepend, -1=append)
- **delete**: `{"type": "delete", "file": "/path", "start_line": 5, "end_line": 8}`
- **patch**: `{"type": "patch", "file": "/path", "find": "...", "replace": "...", "all": true}`

**Deliverables**:
- `op_create()`, `op_replace()`, `op_insert()`, `op_delete()`, `op_patch()` functions
- Line number validation and file length checking
- Atomic operation guarantees

---

### Phase 5: Execution Engine
**Duration**: 1 implementation session
**Objective**: Build main execution loop with error handling and rollback

#### Tasks:
1. ✅ Create main execution loop
2. ✅ Implement sequential operation processing
3. ✅ Add comprehensive error detection and reporting
4. ✅ Integrate rollback on any operation failure
5. ✅ Add progress reporting and operation tracking

**Execution Flow**:
1. Validate JSON and all operations
2. Create backup of all target files
3. Execute operations sequentially
4. On success: cleanup temp files and old backups
5. On failure: rollback all changes and report error

**Deliverables**:
- `execute_operations()` main function
- Error reporting with operation context
- Complete rollback integration

---

### Phase 6: Documentation and Integration
**Duration**: 1 implementation session
**Objective**: Create documentation and integrate with Claude's workflow

#### Tasks:
1. ✅ Create comprehensive README.md
2. ✅ Update global CLAUDE.md with batch system documentation
3. ✅ Add usage examples and error code reference
4. ✅ Document decision criteria for batch vs direct operations
5. ✅ Create integration guidelines for Claude

**Documentation Content**:
- Type-specific operation examples with optimized JSON formats
- Error codes and troubleshooting guide
- Performance benchmarks and usage guidelines
- Integration workflow for Claude with decision criteria

**Deliverables**:
- Complete README.md
- Updated CLAUDE.md
- Usage examples and integration guide

---

### Phase 7: Testing and Validation
**Duration**: 1 implementation session
**Objective**: Comprehensive testing and system validation

#### Tasks:
1. ✅ Test all 5 operations individually
2. ✅ Test complex multi-operation scenarios
3. ✅ Verify backup and rollback functionality
4. ✅ Test error handling and edge cases
5. ✅ Validate performance improvements
6. ✅ Test Claude integration workflow

**Test Scenarios**:
- Single operation types
- Multi-file operations
- Error conditions and rollback
- Large file handling
- Permission and access issues
- JSON validation edge cases

**Deliverables**:
- Fully tested and validated system
- Performance benchmarks
- Error handling verification

---

## Technical Implementation Details

### Core Architecture
```bash
batch_edit.sh
├── main()                    # Entry point and argument handling
├── validate_json()           # JSON syntax and structure validation
├── validate_operations()     # Operation-specific validation
├── create_backup()           # Backup system management
├── execute_operations()      # Main execution loop
├── rollback_changes()        # Failure recovery
└── cleanup()                # Temporary file management
```

### Error Handling Strategy
- **Validation Phase**: Pre-flight checks with detailed error messages
- **Execution Phase**: Atomic operations with immediate rollback on failure
- **Rollback Phase**: Complete restoration of original file states
- **Reporting**: Structured error output for Claude consumption

### Performance Optimizations
- Single JSON parse for all operations
- Batch file I/O operations
- Minimal system calls
- Efficient backup strategy

### Security Considerations
- No arbitrary code execution from JSON
- Path validation for security
- File permission checking
- User-space only operations

## Success Metrics
1. **Performance**: 50%+ token reduction for 5+ operations
2. **Reliability**: Zero data loss through backup/rollback
3. **Usability**: Single-attempt error correction for Claude
4. **Integration**: Seamless adoption in Claude's workflow

## Risk Mitigation
- **Data Loss**: Comprehensive backup before any modifications
- **Operation Failure**: Atomic operations with immediate rollback
- **System Issues**: Graceful degradation and clear error reporting
- **Performance Regression**: Fallback to direct operations for small tasks

## Implementation Timeline
- **Total Duration**: 7 implementation sessions
- **Critical Path**: Phases 2-5 (core functionality)
- **Dependencies**: Each phase builds on previous phases
- **Parallel Work**: Documentation can be prepared during core development

This plan ensures a robust, performant, and reliable batch file operations system specifically optimized for Claude's programmatic use while maintaining the highest standards of data safety and error recovery.
