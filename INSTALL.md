# Installation Guide

## Quick Install (Recommended)

### Method 1: Using Plugin Marketplace

```bash
# Add the marketplace
/plugin marketplace add hbsun2113/claude-code-plugins

# Install the plugin
/plugin install hbsun2113-productivity-suite

# Enable the plugin
/plugin enable hbsun2113-productivity-suite
```

### Method 2: Manual Installation

1. Download or clone this repository
2. Copy the plugin directory to your Claude Code plugins directory:

```bash
cp -r hbsun2113-productivity-suite ~/.claude/plugins/
```

3. Restart Claude Code or reload plugins

## Verify Installation

After installation, verify that the plugin is loaded:

```bash
/plugin list
```

You should see `hbsun2113-productivity-suite` in the list of installed plugins.

## Test Commands

Try one of the slash commands to verify everything is working:

```bash
/explore .
```

## Configuration

The plugin works out of the box with default settings. However, you can customize:

### Status Line

The status line is automatically enabled. To disable it, edit your `settings.json`:

```json
{
  "statusLine": null
}
```

### Hooks

The markdown formatter hook is automatically enabled. To disable it, edit your `settings.json`:

```json
{
  "hooks": {
    "PostToolUse": []
  }
}
```

## Troubleshooting

### Python not found

Ensure Python 3.6+ is installed:

```bash
python3 --version
```

### jq not found

Install jq for your system:

**Ubuntu/Debian:**
```bash
sudo apt-get install jq
```

**macOS:**
```bash
brew install jq
```

**Arch Linux:**
```bash
sudo pacman -S jq
```

### Hooks not working

1. Check that the hook script is executable:
```bash
chmod +x ~/.claude/plugins/hbsun2113-productivity-suite/.claude/hooks/markdown_formatter.py
```

2. Verify Python path:
```bash
which python3
```

### Status Line not showing

1. Check that the script is executable:
```bash
chmod +x ~/.claude/plugins/hbsun2113-productivity-suite/.claude/scripts/statusline.sh
```

2. Verify jq is installed:
```bash
which jq
```

## Uninstallation

To uninstall the plugin:

```bash
/plugin uninstall hbsun2113-productivity-suite
```

Or manually remove the directory:

```bash
rm -rf ~/.claude/plugins/hbsun2113-productivity-suite
```

## Getting Help

If you encounter any issues:

1. Check the [README](README.md) for usage examples
2. Review the [Chinese documentation](README_CN.md) if you prefer Chinese
3. Report issues on the [GitHub repository](https://github.com/hbsun2113/claude-code-productivity-suite/issues)
