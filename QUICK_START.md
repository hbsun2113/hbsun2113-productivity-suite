# Quick Start Guide

Get started with hbsun2113's Productivity Suite in 2 minutes!

## For Users (Installing the Plugin)

### Installation (3 steps)

```bash
# 1. Add the marketplace
/plugin marketplace add hbsun2113/claude-code-plugins

# 2. Install the plugin
/plugin install hbsun2113-productivity-suite

# 3. Try it out!
/explore .
```

### What You Get

✅ **5 Slash Commands**
- `/explore` - Analyze code structure
- `/gitCommit` - Create git commits
- `/requirementDoc` - Generate requirement docs
- `/rev-engine` - Multi-round planning
- `/todoDoc` - Create todo lists

✅ **3 AI Agents**
- `code-reviewer` - Code quality analysis
- `library-usage-researcher` - Library research (Chinese)
- `memory-network-builder` - Knowledge management

✅ **Automatic Features**
- Markdown formatter (auto-fixes code blocks)
- Enhanced status line (shows dir, branch, model)
- Batch editing tool

### Next Steps

- Read [USER_GUIDE.md](USER_GUIDE.md) for detailed usage
- Check [README.md](README.md) for feature overview
- See [README_CN.md](README_CN.md) for Chinese docs

---

## For Publishers (Sharing Your Plugin)

### Publishing (4 steps)

1. **Create plugin repository on GitHub**
   ```bash
   cd ~/.claude/plugins/hbsun2113-productivity-suite
   git init
   git add .
   git commit -m "Initial release v1.0.0"
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```

2. **Create marketplace repository** (optional but recommended)
   - Create a new repo: `claude-code-plugins`
   - Add `.claude-plugin/marketplace.json` file
   - List your plugin in the marketplace

3. **Test installation**
   ```bash
   /plugin marketplace add YOUR_USERNAME/claude-code-plugins
   /plugin install your-plugin-name
   ```

4. **Share!**
   - Update README with installation instructions
   - Share on GitHub, Reddit, Twitter, etc.

### Next Steps

- Read [PUBLISHER_GUIDE.md](PUBLISHER_GUIDE.md) for complete publishing guide
- See [plugin format documentation](https://docs.claude.com/en/docs/claude-code/plugins)

---

## Need Help?

- **Installation issues?** → See [USER_GUIDE.md](USER_GUIDE.md) Troubleshooting section
- **Publishing questions?** → See [PUBLISHER_GUIDE.md](PUBLISHER_GUIDE.md)
- **Found a bug?** → [Open an issue](https://github.com/hbsun2113/claude-code-productivity-suite/issues)
