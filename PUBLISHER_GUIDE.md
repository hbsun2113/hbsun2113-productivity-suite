# Publisher Guide - How to Share Your Plugin

This guide explains how to publish the `hbsun2113-productivity-suite` plugin so others can install it.

## 📋 Prerequisites

- A GitHub account
- Git installed locally
- Your plugin ready at `~/.claude/plugins/hbsun2113-productivity-suite/`

## 🚀 Publishing Steps

### Step 1: Create GitHub Repository for the Plugin

1. **Create a new repository on GitHub:**
   - Repository name: `claude-code-productivity-suite`
   - Description: "A comprehensive productivity plugin for Claude Code"
   - Make it **Public** (required for plugin installation)
   - Don't initialize with README (we already have one)

2. **Initialize and push your plugin:**

```bash
cd ~/.claude/plugins/hbsun2113-productivity-suite

# Initialize git repository
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial release: v1.0.0

- 5 powerful slash commands (/explore, /gitCommit, /requirementDoc, /rev-engine, /todoDoc)
- 3 specialized agents (code-reviewer, library-usage-researcher, memory-network-builder)
- Smart markdown formatter hook
- Enhanced status line with git branch
- Comprehensive batch editing tool"

# Add remote (replace hbsun2113 with your GitHub username)
git remote add origin https://github.com/hbsun2113/claude-code-productivity-suite.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 2: Create a Marketplace Repository (Recommended)

For easier plugin management and future plugins, create a separate marketplace repository:

1. **Create another repository:**
   - Repository name: `claude-code-plugins`
   - Description: "Plugin marketplace for Claude Code"
   - Make it **Public**

2. **Set up the marketplace:**

```bash
# Create a new directory for marketplace
mkdir -p ~/claude-code-plugins/.claude-plugin

# Create marketplace.json
cat > ~/claude-code-plugins/.claude-plugin/marketplace.json << 'EOF'
{
  "name": "hbsun2113-plugins",
  "owner": {
    "name": "hbsun2113",
    "email": "[email protected]"
  },
  "plugins": [
    {
      "name": "hbsun2113-productivity-suite",
      "source": {
        "source": "github",
        "repo": "hbsun2113/claude-code-productivity-suite"
      },
      "description": "A comprehensive productivity plugin with slash commands, agents, hooks, and batch editing tools",
      "version": "1.0.0",
      "author": {
        "name": "hbsun2113",
        "email": "[email protected]"
      },
      "homepage": "https://github.com/hbsun2113/claude-code-productivity-suite",
      "repository": "https://github.com/hbsun2113/claude-code-productivity-suite",
      "license": "MIT",
      "keywords": [
        "productivity",
        "workflow",
        "chinese",
        "batch-edit",
        "code-analysis",
        "git",
        "development"
      ]
    }
  ]
}
EOF

# Create README
cat > ~/claude-code-plugins/README.md << 'EOF'
# hbsun2113's Claude Code Plugin Marketplace

A curated collection of productivity plugins for Claude Code.

## Available Plugins

### hbsun2113-productivity-suite

A comprehensive productivity plugin with:
- 5 slash commands for workflow automation
- 3 specialized agents
- Smart markdown formatter
- Enhanced status line
- Batch editing tool

## Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add hbsun2113/claude-code-plugins
```

Then install plugins:

```bash
/plugin install hbsun2113-productivity-suite
```

## License

MIT
EOF

# Initialize and push
cd ~/claude-code-plugins
git init
git add .
git commit -m "Add hbsun2113-productivity-suite to marketplace"
git remote add origin https://github.com/hbsun2113/claude-code-plugins.git
git branch -M main
git push -u origin main
```bash

### Step 3: Test Your Published Plugin

Before sharing, test that your plugin can be installed:

```bash
# Remove local plugin (backup first if needed)
mv ~/.claude/plugins/hbsun2113-productivity-suite ~/.claude/plugins/hbsun2113-productivity-suite.backup

# Add your marketplace
/plugin marketplace add hbsun2113/claude-code-plugins

# Install from marketplace
/plugin install hbsun2113-productivity-suite

# Test a command
/explore .
```

### Step 4: Create a Release (Optional but Recommended)

On GitHub, create a release for version tracking:

1. Go to your plugin repository on GitHub
2. Click "Releases" → "Create a new release"
3. Tag: `v1.0.0`
4. Title: `v1.0.0 - Initial Release`
5. Description: Copy from your commit message
6. Click "Publish release"

## 📢 Sharing Your Plugin

### Share the marketplace:

**Option 1: Via Marketplace (Recommended)**
```bash
/plugin marketplace add hbsun2113/claude-code-plugins
/plugin install hbsun2113-productivity-suite
```

**Option 2: Direct Plugin Repository**
```bash
/plugin marketplace add hbsun2113/claude-code-productivity-suite
/plugin install hbsun2113-productivity-suite
```

### Share on:

- GitHub README with installation instructions
- Reddit (r/ClaudeAI, r/ClaudeCode if exists)
- Discord communities
- Twitter/X
- Your blog or website

## 🔄 Updating Your Plugin

When you make changes:

1. **Update version in plugin.json:**
   ```json
   {
     "version": "1.1.0"
   }
   ```

2. **Update marketplace.json** (if using separate marketplace):
   ```json
   {
     "version": "1.1.0"
   }
   ```

3. **Commit and push:**
   ```bash
   git add .
   git commit -m "Release v1.1.0: Add new features"
   git push
   ```

4. **Create new GitHub release** with the new version tag

5. **Users update with:**
   ```bash
   /plugin update hbsun2113-productivity-suite
   ```

## 📊 Analytics and Feedback

- Monitor GitHub stars, forks, and issues
- Encourage users to report bugs via GitHub Issues
- Add a CHANGELOG.md to track changes
- Consider adding screenshots/demos to README

## ⚠️ Important Notes

1. **Repository must be public** for users to install
2. **Keep marketplace.json updated** when you release new versions
3. **Test before releasing** to avoid breaking changes
4. **Use semantic versioning** (MAJOR.MINOR.PATCH)
5. **Document breaking changes** clearly in releases

## 🤝 Best Practices

- Respond to issues and pull requests
- Keep documentation up to date
- Add examples and screenshots
- Include a CHANGELOG.md
- Tag releases properly
- Test on both terminal and VS Code

## 📝 Template for Announcements

```markdown
🚀 New Claude Code Plugin: hbsun2113's Productivity Suite

A comprehensive productivity plugin featuring:
✅ 5 powerful slash commands
✅ 3 specialized AI agents
✅ Smart markdown formatter
✅ Enhanced status line
✅ Batch editing tool

Installation:
/plugin marketplace add hbsun2113/claude-code-plugins
/plugin install hbsun2113-productivity-suite

GitHub: https://github.com/hbsun2113/claude-code-productivity-suite
```

## 🆘 Troubleshooting

**Plugin not installing?**
- Ensure repository is public
- Check that .claude-plugin/plugin.json exists
- Verify marketplace.json format

**Users reporting errors?**
- Check dependencies are documented
- Verify paths use ${CLAUDE_PLUGIN_ROOT}
- Test on fresh installation

---

Good luck with your plugin! 🎉
