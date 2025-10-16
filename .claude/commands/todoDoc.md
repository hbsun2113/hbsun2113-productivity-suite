---
allowed-tools: Write, TodoWrite
argument-hint: [requirement document name] [todo-list document name]
description: create a todo list
---
To complete the target defined in the requirements document ${1:-"requirements.md"}:

## Your Tasks:

1. **Create a detailed task list document** (markdown) named ${2:-"implementation-plan.md"}
   - Each task should be small, highly testable, and designed for a large language model to complete
   - Ensure the foundational tasks (database setup, project setup, foundation code components like servers) are defined first so that the following tasks can leverage them
   - Your plan should ultimately fully implement the requirements without adding redundant features
   - Your plan should not only conform to mature development standards but also match your capabilities (that is, your capabilities can ultimately achieve the goals set in the plan)
   - The markdown should be in Chinese

2. **IMPORTANT: Populate TodoWrite with the same tasks** for real-time progress tracking
   - After creating the markdown file, use the TodoWrite tool to load all tasks
   - This enables dynamic tracking during execution
   - Mark tasks with appropriate status (all should start as "pending")
   - Ensure task descriptions are actionable and match the markdown document
