---
allowed-tools: Read, Glob, Grep, Bash, mcp__serena__list_dir, mcp__serena__read_file, mcp__serena__get_symbols_overview, mcp__serena__find_symbol, mcp__serena__find_referencing_symbols, mcp__serena__search_for_pattern, mcp__serena__read_memory, mcp__serena__list_memories, mcp__serena__execute_shell_command, mcp__grep__searchGitHub, mcp__context7__resolve-library-id, mcp__context7__get-library-docs, WebFetch, WebSearch, mcp__exa__web_search_exa, mcp__exa__get_code_context_exa, BashOutput
argument-hint: [path or topic to explore]
description: Deep code analysis and exploration
---

IMPORTANT: Systematically analyze code structure using symbolic tools.
Provide actionable insights for development decisions.

## Target
Explore: ${1:-.} (default: current directory)

## Analysis Approach

### Phase 1: Structure Mapping
1. Use `mcp__serena__list_dir` to understand directory organization
2. Use `Glob` to identify file patterns (e.g., `**/*.py`, `**/*.ts`)
3. Map the overall architecture and module boundaries

### Phase 2: Symbol Analysis
1. Use `mcp__serena__get_symbols_overview` for key files to understand top-level structure
2. Use `mcp__serena__find_symbol` to locate important classes, functions, and components
3. Use `mcp__serena__find_referencing_symbols` to understand dependencies and relationships
4. Prefer symbolic tools over reading entire files

### Phase 3: Pattern Recognition
1. Identify coding conventions (naming, structure, style)
2. Recognize architectural patterns (MVC, layered, microservices, etc.)
3. Find common utilities and helper functions
4. Spot configuration patterns

### Phase 4: Technology Stack Analysis
1. Identify languages and frameworks
2. Find external dependencies (package.json, requirements.txt, etc.)
3. Understand build and test tooling

## Output Format

Provide a comprehensive analysis report with:

### 1. Architecture Summary
- High-level structure and organization
- Module boundaries and relationships
- Design patterns identified

### 2. Key Components
- Important files/modules with brief explanations
- Entry points and core logic
- Critical dependencies

### 3. Conventions Found
- Code style and naming patterns
- Project structure conventions
- Common patterns and anti-patterns

### 4. Technology Stack
- Languages and versions
- Frameworks and libraries
- Development tools and scripts

### 5. Insights & Recommendations
- Strengths of the codebase
- Potential areas for improvement
- Suggested next steps for development
- Files to read for deeper understanding

## Guidelines

- IMPORTANT: Use symbolic tools (get_symbols_overview, find_symbol) before reading entire files
- Focus on understanding structure and patterns, not implementation details
- Provide concrete examples from the code
- Keep analysis concise but comprehensive
- If exploring unfamiliar libraries, use `mcp__context7__get-library-docs` for documentation
- Use `mcp__grep__searchGitHub` to find real-world usage examples if needed
- If files are too large, read specific sections based on symbolic analysis

## Notes

This command is READ-ONLY and will not modify any files. It's designed for the "Explore" phase of the "Explore → Plan → Code → Commit" workflow.
