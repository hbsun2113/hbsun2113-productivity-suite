# hbsun2113's Productivity Suite

A comprehensive productivity plugin for Claude Code that enhances your development workflow with powerful slash commands, specialized agents, smart hooks, and batch editing capabilities.

## 🚀 Features

### Slash Commands

- **`/explore`** - Deep code analysis and exploration
  - Systematically analyze code structure using symbolic tools
  - Provide actionable insights for development decisions
  - Read-only exploration of codebases

- **`/gitCommit`** - Create git commits with proper formatting
  - Automated commit message generation
  - Co-authored by Claude signature

- **`/requirementDoc`** - Analyze requirements and write documentation
  - Convert requirements into structured documentation
  - Supports custom document naming

- **`/rev-engine`** - Maximum Claude planning through multi-round ultrathink
  - Multi-round planning with Plan Mode
  - Interactive or automated planning
  - Focused planning on specific areas

- **`/todoDoc`** - Create todo lists from requirements
  - Generate implementation plans from requirement documents
  - Sync with TodoWrite for real-time tracking

### Custom Agents

- **`code-reviewer`** - Expert code review specialist
  - Proactive code quality checks
  - Security and maintainability analysis

- **`library-usage-researcher`** - Research library usage patterns
  - Systematic library documentation gathering
  - Real-world usage examples from GitHub
  - Best practices and advanced techniques (Chinese output)

- **`memory-network-builder`** - Build and manage memory networks
  - Organize project knowledge
  - Cross-reference information

### Hooks

- **Markdown Formatter** (PostToolUse)
  - Automatically formats markdown files after Edit/Write operations
  - Detects and adds missing language tags to code fences
  - Fixes excessive blank lines

### Status Line

- Enhanced status line showing:
  - Current directory (colored)
  - Git branch (if in a repository)
  - Current model name

### Batch Edit Tool

A powerful batch file editing system for efficient multi-file operations:
- Sequential execution with automatic backup
- Rollback on failure
- Support for create, replace, insert, delete, and patch operations
- Comprehensive validation

## 📦 Installation

### Using Claude Code Plugin System

```bash
# Add the plugin marketplace
/plugin marketplace add hbsun2113/claude-code-plugins

# Install the plugin
/plugin install hbsun2113-productivity-suite
```

### Manual Installation

1. Clone or download this plugin to your `~/.claude/plugins/` directory
2. Restart Claude Code or reload plugins
3. The plugin will be automatically detected and loaded

## 🔧 Dependencies

- **Python** >= 3.6 (for markdown formatter hook)
- **Bash** >= 4.0 (for status line and batch edit)
- **jq** >= 1.5 (for JSON parsing in status line)

## 📖 Usage Examples

### Code Exploration
```bash
/explore src/components
```

### Create a Todo List
```bash
/todoDoc requirements.md implementation-plan.md
```

### Research a Library
Ask Claude to use the `library-usage-researcher` agent:
```bash
How do I use React Query for data fetching?
```

### Batch Edit Files
```bash
./batch_edit/batch_edit.sh operations.json
```

## 🎯 Plugin Components

```text
hbsun2113-productivity-suite/
├── plugin.json                 # Plugin configuration
├── README.md                   # English documentation
├── README_CN.md                # Chinese documentation
├── .claude/
│   ├── commands/              # Slash commands
│   │   ├── explore.md
│   │   ├── gitCommit.md
│   │   ├── requirementDoc.md
│   │   ├── rev-engine.md
│   │   └── todoDoc.md
│   ├── agents/                # Custom agents
│   │   ├── code-reviewer.md
│   │   ├── library-usage-researcher.md
│   │   └── memory-network-builder.md
│   ├── hooks/                 # Hooks
│   │   └── markdown_formatter.py
│   └── scripts/               # Scripts
│       └── statusline.sh
└── batch_edit/                # Batch editing tool
    ├── batch_edit.sh
    ├── doc/
    └── tests/
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

MIT License - feel free to use and modify as needed.

## 👤 Author

**hbsun2113**

## 🙏 Acknowledgments

Built for the Claude Code community to enhance development productivity.
