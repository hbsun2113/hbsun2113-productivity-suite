# Batch File Operations System Requirements

## 1. Overview

### 1.1 Purpose
The Batch File Operations System is a performance optimization tool designed specifically for Claude Code to execute multiple file operations through a single bash script invocation, reducing API overhead and improving execution speed.

### 1.2 Scope
This system is exclusively designed for Claude's programmatic use. Human usability is not a design consideration.

### 1.3 Primary Goal
Reduce token consumption and execution time by consolidating multiple file operations into single batch executions.

## 2. Functional Requirements

### 2.1 Core Operations
The system SHALL support exactly 5 operation types:

#### 2.1.1 Create Operation
- Creates new files with specified content
- Fails if file already exists
- Creates parent directories if needed

#### 2.1.2 Replace Operation
- Replaces content between specified line ranges
- Parameters: start_line, end_line, content
- Line numbers are 1-indexed

#### 2.1.3 Insert Operation
- Inserts content at specified line position
- Line 0 = prepend to beginning
- Line -1 = append to end
- Other values insert before specified line

#### 2.1.4 Delete Operation
- Removes specified line range from file
- Parameters: start_line, end_line
- File must exist

#### 2.1.5 Patch Operation
- Find and replace text patterns
- Supports literal string or regex patterns
- Optional "all" flag for global replacement

### 2.2 Input Format
Operations SHALL be defined via JSON with type-specific structures to minimize cognitive load and reduce errors:

```json
{
  "operations": [
    // Create operation
    {
      "type": "create",
      "file": "/absolute/path/to/file",
      "content": "file content"
    },
    // Replace operation
    {
      "type": "replace",
      "file": "/absolute/path/to/file",
      "start_line": 10,
      "end_line": 20,
      "content": "replacement content"
    },
    // Insert operation
    {
      "type": "insert",
      "file": "/absolute/path/to/file",
      "line": 42,  // 0=prepend, -1=append
      "content": "content to insert"
    },
    // Delete operation
    {
      "type": "delete",
      "file": "/absolute/path/to/file",
      "start_line": 5,
      "end_line": 8
    },
    // Patch operation
    {
      "type": "patch",
      "file": "/absolute/path/to/file",
      "find": "pattern to find",
      "replace": "replacement text",
      "all": true  // optional, default false
    }
  ]
}
```

### 2.3 Validation Requirements
- The system SHALL validate JSON syntax before execution
- The system SHALL validate operation parameters based on operation type:

**Create Operation Requirements:**
- `file`: absolute path
- `content`: string (may be empty)

**Replace Operation Requirements:**
- `file`: absolute path to existing file
- `start_line`, `end_line`: positive integers, start_line ≤ end_line
- `content`: string (may be empty)

**Insert Operation Requirements:**
- `file`: absolute path to existing file
- `line`: integer (0 for prepend, -1 for append, positive for line position)
- `content`: string (may be empty)

**Delete Operation Requirements:**
- `file`: absolute path to existing file
- `start_line`, `end_line`: positive integers, start_line ≤ end_line

**Patch Operation Requirements:**
- `file`: absolute path to existing file
- `find`: non-empty string
- `replace`: string (may be empty)
- `all`: boolean (optional, defaults to false)

- Validation logic SHALL be identical to execution logic to prevent inconsistencies

### 2.4 Execution Requirements
- Operations SHALL be processed sequentially in order
- Each operation SHALL be atomic (fully succeed or fully fail)
- On any operation failure, ALL changes SHALL be rolled back

## 3. Non-Functional Requirements

### 3.1 Performance
- Batch operations with 5+ edits SHALL execute faster than equivalent individual operations
- JSON parsing and validation SHALL complete within 100ms

### 3.2 Error Handling
Error messages SHALL include:
- Operation index that failed
- Operation type
- Target file path
- Specific error reason
- Rollback status

Example error format:
```text
ERROR: Operation 3 failed
Type: replace
File: /path/to/file.js
Issue: Line range 10-20 exceeds file length (15 lines)
Action: Rollback completed, all files restored
```

### 3.3 Backup & Recovery
- The system SHALL create timestamped backups before first operation
- Backups SHALL be stored in `~/.claude/batch_edit/backups/`
- On failure, the system SHALL automatically restore all files from backup
- Successful operations SHALL trigger backup cleanup

### 3.4 File Management
Directory structure:
```text
~/.claude/batch_edit/
├── batch_edit.sh          # Main execution script
├── tmp/                   # Temporary JSON operation files
│   └── batch_ops_*.json
├── backups/               # File backups
│   └── backup_*/
└── README.md             # Documentation
```

## 4. Operational Requirements

### 4.1 Claude Workflow
1. Analyze task scope (3+ operations → use batch mode)
2. Generate JSON operations directly
3. Write JSON to `~/.claude/batch_edit/tmp/batch_ops_[timestamp].json`
4. Execute `~/.claude/batch_edit/batch_edit.sh tmp/batch_ops_[timestamp].json`
5. Parse output for errors
6. If errors: analyze, regenerate JSON, retry
7. Auto-cleanup temp files on success

### 4.2 Decision Criteria
Use batch operations when:
- 3 or more file operations needed
- Cross-file refactoring required
- Bulk find/replace across multiple files
- Creating multiple similar files

Use direct operations when:
- Single file, minor changes
- Exploratory/debugging edits
- Need to read file content first

## 5. Implementation Requirements

### 5.1 Technology Stack
- Pure Bash script (no external dependencies)
- JSON parsing via jq (pre-installed)
- Standard Unix utilities (sed, awk, etc.)

### 5.2 Compatibility
- Must work on Linux
- Bash version 4.0+
- No root/sudo requirements

### 5.3 Security
- No execution of arbitrary code from JSON
- File operations limited to user-accessible paths
- No network operations

## 6. Documentation Requirements

### 6.1 README.md
SHALL include:
- Operation type examples
- Error code reference
- Common usage patterns

### 6.2 CLAUDE.md Update
SHALL include:
- System availability notice
- Decision matrix for batch vs direct operations
- Usage workflow

## 7. Success Criteria

The system is considered successful when:
1. Batch operations reduce token usage by 50%+ for 5+ operations
2. Error messages enable successful retry within 1 attempt
3. Zero data loss through backup/rollback mechanism
4. Claude autonomously chooses optimal operation mode (batch vs direct)

## 8. Out of Scope

The following are explicitly NOT requirements:
- Human-friendly interface or prompts
- Interactive mode or user confirmation
- Helper scripts for JSON generation
- GUI or web interface
- Operation history or logging
- Concurrent operation processing
- Windows or macOS compatibility
