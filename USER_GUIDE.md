# User Installation Guide

Complete guide for installing and using the `hbsun2113-productivity-suite` plugin.

## 🎯 Quick Start

The fastest way to install this plugin:

```bash
# Add the marketplace
/plugin marketplace add hbsun2113/claude-code-plugins

# Install the plugin
/plugin install hbsun2113-productivity-suite

# Start using it!
/explore .
```

## 📋 Prerequisites

Before installing, ensure you have:

- **Claude Code** installed (Terminal or VS Code)
- **Python 3.6+** for the markdown formatter hook
- **Bash 4.0+** for status line and batch edit tool
- **jq 1.5+** for JSON parsing in status line

### Check Dependencies

```bash
# Check Python
python3 --version

# Check Bash
bash --version

# Check jq
jq --version
```

### Install Missing Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install python3 jq
```

**macOS:**
```bash
brew install python3 jq
```

**Arch Linux:**
```bash
sudo pacman -S python jq
```

## 📥 Installation Methods

### Method 1: Via Marketplace (Recommended)

This is the easiest method for most users:

```bash
# Step 1: Add the marketplace
/plugin marketplace add hbsun2113/claude-code-plugins

# Step 2: Install the plugin
/plugin install hbsun2113-productivity-suite

# Step 3: Verify installation
/plugin list
```

You should see `hbsun2113-productivity-suite` in the list of installed plugins.

### Method 2: Direct from Plugin Repository

If you prefer to install directly from the plugin repository:

```bash
# Add the plugin repository as a marketplace
/plugin marketplace add hbsun2113/claude-code-productivity-suite

# Install the plugin
/plugin install hbsun2113-productivity-suite
```

### Method 3: Manual Installation

For advanced users who want to customize or develop:

1. **Clone the repository:**
   ```bash
   cd ~/.claude/plugins
   git clone https://github.com/hbsun2113/claude-code-productivity-suite.git hbsun2113-productivity-suite
   ```

2. **Restart Claude Code** or reload plugins

3. **Verify installation:**
   ```bash
   /plugin list
   ```

## ✅ Verification

After installation, test that everything works:

### Test Slash Commands

```bash
# Test the explore command
/explore .

# Test todo document creation (requires a requirements file)
/todoDoc requirements.md todo.md

# Test git commit helper
/gitCommit
```

### Test Agents

Ask Claude to use the agents:

```bash
Can you review my code for quality issues?
```

Claude should automatically use the `code-reviewer` agent.

```bash
How do I use React Query for data fetching?
```

Claude should use the `library-usage-researcher` agent.

### Test Hooks

Create or edit a markdown file - the markdown formatter hook will automatically format it:

```bash
# In Claude Code, create a markdown file with unformatted code blocks
# The hook will automatically add language tags
```

### Test Status Line

You should see an enhanced status line showing:
- Current directory (in blue)
- Git branch (in green, if in a git repository)
- Model name (in yellow)

## 🎮 Using the Plugin

### Slash Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/explore` | Deep code analysis | `/explore src/components` |
| `/gitCommit` | Create git commit | `/gitCommit` |
| `/requirementDoc` | Analyze requirements | `/requirementDoc requirements.md` |
| `/rev-engine` | Multi-round planning | `/rev-engine --interactive` |
| `/todoDoc` | Create todo list | `/todoDoc requirements.md plan.md` |

### Agents

The plugin includes 3 specialized agents that Claude will use automatically:

1. **code-reviewer**: Triggered when you ask for code review
2. **library-usage-researcher**: Triggered when you ask about library usage (outputs in Chinese)
3. **memory-network-builder**: Triggered for knowledge management tasks

### Batch Edit Tool

For advanced batch file operations:

```bash
# Navigate to the batch_edit directory
cd ~/.claude/plugins/hbsun2113-productivity-suite/batch_edit

# Create an operations.json file (see batch_edit/doc/ for examples)
# Run batch edit
./batch_edit.sh operations.json
```

See `batch_edit/doc/` for comprehensive documentation.

## ⚙️ Configuration

### Disable Status Line

If you prefer not to use the enhanced status line, add to your `~/.claude/settings.json`:

```json
{
  "statusLine": null
}
```

### Disable Markdown Formatter

To disable automatic markdown formatting:

```json
{
  "hooks": {
    "PostToolUse": []
  }
}
```

### Customize Hooks

You can modify the hook behavior by editing:
```text
~/.claude/plugins/hbsun2113-productivity-suite/.claude/hooks/hooks.json
```

## 🔄 Updating

To update to the latest version:

```bash
# Update the plugin
/plugin update hbsun2113-productivity-suite

# Or update all plugins
/plugin update --all
```

## 🗑️ Uninstallation

To remove the plugin:

```bash
# Uninstall via plugin command
/plugin uninstall hbsun2113-productivity-suite

# Or manually remove
rm -rf ~/.claude/plugins/hbsun2113-productivity-suite
```

## 🐛 Troubleshooting

### Plugin Not Found

**Problem**: `/plugin install` says plugin not found

**Solution**:
1. Ensure you've added the marketplace first
2. Check that the repository is public on GitHub
3. Try refreshing: `/plugin marketplace refresh`

### Python Hook Errors

**Problem**: Markdown formatter not working

**Solution**:
```bash
# Make sure the script is executable
chmod +x ~/.claude/plugins/hbsun2113-productivity-suite/.claude/hooks/markdown_formatter.py

# Check Python path
which python3

# Test the script manually
echo '{}' | ~/.claude/plugins/hbsun2113-productivity-suite/.claude/hooks/markdown_formatter.py
```

### Status Line Not Showing

**Problem**: Enhanced status line not appearing

**Solution**:
```bash
# Make script executable
chmod +x ~/.claude/plugins/hbsun2113-productivity-suite/.claude/scripts/statusline.sh

# Verify jq is installed
jq --version

# Check if another statusLine config exists in settings.json
```

### Commands Not Working

**Problem**: Slash commands not recognized

**Solution**:
1. Verify plugin is installed: `/plugin list`
2. Check that plugin is enabled
3. Restart Claude Code
4. Verify command files exist in `.claude/commands/`

### Agent Not Triggering

**Problem**: Claude not using specialized agents

**Solution**:
- Agents are triggered automatically based on context
- Try being more explicit: "Please use the code-reviewer agent to review this code"
- Check that agent files exist in `.claude/agents/`

## 📚 Learning More

### Documentation

- [README.md](README.md) - Overview and features
- [README_CN.md](README_CN.md) - Chinese documentation
- [INSTALL.md](INSTALL.md) - Detailed installation guide
- [batch_edit/doc/](batch_edit/doc/) - Batch edit tool documentation

### Example Usage

See the documentation for each slash command:
```bash
# Command files contain usage examples
cat ~/.claude/plugins/hbsun2113-productivity-suite/.claude/commands/explore.md
```

### Support

- **Issues**: [GitHub Issues](https://github.com/hbsun2113/claude-code-productivity-suite/issues)
- **Discussions**: [GitHub Discussions](https://github.com/hbsun2113/claude-code-productivity-suite/discussions)

## 💡 Tips

1. **Use tab completion** - Type `/` and press tab to see available commands
2. **Combine tools** - Use `/explore` before `/todoDoc` for better planning
3. **Leverage agents** - Be specific in your requests to trigger the right agent
4. **Batch operations** - Use the batch_edit tool for large-scale refactoring
5. **Status line** - Quickly see your context without running commands

## 🎉 Getting Started Examples

### Example 1: Exploring a New Codebase

```bash
# First, explore the structure
/explore src/

# Then ask questions
"What are the main components in this codebase?"
```

### Example 2: Planning a Feature

```bash
# Create requirements document first
# Then generate implementation plan
/todoDoc feature-requirements.md implementation-plan.md
```

### Example 3: Research a Library

```bash
I need to understand how to use FastAPI for building REST APIs
```

Claude will use the `library-usage-researcher` agent and provide comprehensive documentation in Chinese.

### Example 4: Code Review

```bash
Please review the code in src/auth/login.py for security and quality issues
```

Claude will use the `code-reviewer` agent to provide detailed feedback.

---

Enjoy your enhanced Claude Code experience! 🚀
