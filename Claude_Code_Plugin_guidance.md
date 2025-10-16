# Claude Code Plugin 完整指南

**插件名称**: hbsun2113-productivity-suite
**当前版本**: v1.0.2
**作者**: hbsun2113
**仓库**: https://github.com/hbsun2113/hbsun2113-productivity-suite

---

## 目录

1. [用户指南](#用户指南)
   - [快速安装](#快速安装)
   - [功能概览](#功能概览)
   - [使用方法](#使用方法)
   - [故障排查](#故障排查)
2. [发布者指南](#发布者指南)
   - [插件结构](#插件结构)
   - [发布流程](#发布流程)
   - [版本管理](#版本管理)
   - [常见问题](#常见问题)

---

# 用户指南

## 快速安装

### 方法一：从市场安装（推荐）

```bash
# 1. 添加插件市场
/plugin marketplace add hbsun2113-plugins https://github.com/hbsun2113/hbsun2113-claude-code-plugins

# 2. 安装插件
/plugin install hbsun2113-productivity-suite

# 3. 验证安装
/plugin list
```

### 方法二：直接从GitHub安装

```bash
/plugin install github:hbsun2113/hbsun2113-productivity-suite
```

### 验证安装成功

安装后应该显示：
```text
hbsun2113-productivity-suite  v1.0.2  (enabled)
```

---

## 功能概览

### 斜杠命令（5个）

| 命令 | 功能 | 用法 |
|------|------|------|
| `/explore` | 深度代码分析和探索 | `/explore [路径]` |
| `/gitCommit` | 创建格式化的 Git 提交 | `/gitCommit` |
| `/requirementDoc` | 分析需求并编写文档 | `/requirementDoc [文档名]` |
| `/rev-engine` | 多轮 ultrathink 规划 | `/rev-engine <任务描述> [--interactive] [--rounds=N]` |
| `/todoDoc` | 从需求创建待办列表 | `/todoDoc [需求文档名] [待办文档名]` |

### AI 代理（3个）

| 代理 | 触发方式 | 功能 |
|------|---------|------|
| `code-reviewer` | 自动触发 | 代码质量审查专家 |
| `library-usage-researcher` | 自动触发 | 库使用研究（中文输出） |
| `memory-network-builder` | 按需调用 | 记忆网络构建器 |

### Hooks

- **Markdown 格式化器**: 自动检测和修复 Markdown 代码块
- **PreToolUse 日志**: 记录工具使用情况

### 批量编辑工具

位于 `.claude/batch_edit/`，支持：
- 批量创建文件
- 批量替换内容
- 批量插入/删除
- 自动备份和回滚

---

## 使用方法

### 1. 代码探索

```bash
# 探索当前目录
/explore .

# 探索特定模块
/explore src/components

# 探索并生成文档
/explore src/api
```

### 2. Git 工作流

```bash
# 创建智能提交（会分析变更并生成合适的提交信息）
/gitCommit
```

### 3. 需求管理

```bash
# 步骤1: 创建需求文档
/requirementDoc 用户认证功能

# 步骤2: 生成待办列表
/todoDoc 用户认证功能需求文档 用户认证待办列表
```

### 4. 深度规划

```bash
# 基础用法
/rev-engine "实现用户认证系统"

# 交互模式（多轮确认）
/rev-engine "重构数据库架构" --interactive

# 指定规划轮数
/rev-engine "优化性能" --rounds=5

# 聚焦特定领域
/rev-engine "API设计" --focus=architecture
```

### 5. 批量编辑

```bash
# 准备JSON配置文件
cat > operations.json << 'EOF'
{
  "operations": [
    {
      "type": "replace",
      "file": "/path/to/file.py",
      "start_line": 10,
      "end_line": 15,
      "content": "new content"
    }
  ]
}
EOF

# 执行批量编辑
~/.claude/plugins/hbsun2113-productivity-suite/.claude/batch_edit/batch_edit.sh operations.json
```

---

## 故障排查

### 问题1: 命令不可用

**症状**: `/explore` 等命令提示 "Unknown command"

**解决方案**:
```bash
# 1. 确认插件已安装
/plugin list

# 2. 如果显示 (disabled)，启用插件
/plugin enable hbsun2113-productivity-suite

# 3. 如果仍然无法使用，重新安装
/plugin uninstall hbsun2113-productivity-suite
rm -rf ~/.claude/plugins/hbsun2113-productivity-suite
rm -rf ~/.claude/plugins/cache/*
/plugin install hbsun2113-productivity-suite
```

### 问题2: 版本过旧

**症状**: 功能不全或有bug

**解决方案**:
```bash
# 检查版本
/plugin list

# 如果不是 v1.0.2，完全重装
/plugin uninstall hbsun2113-productivity-suite
rm -rf ~/.claude/plugins/hbsun2113-productivity-suite
rm -rf ~/.claude/plugins/cache/*
/plugin install hbsun2113-productivity-suite
```

### 问题3: Hooks 不工作

**症状**: Markdown 格式化不生效

**解决方案**:
```bash
# 检查 hooks 配置
cat ~/.claude/plugins/hbsun2113-productivity-suite/.claude/hooks/hooks.json

# 确保脚本可执行
chmod +x ~/.claude/plugins/hbsun2113-productivity-suite/.claude/hooks/markdown_formatter.py
```

---

# 发布者指南

## 插件结构

### 标准目录结构

```text
hbsun2113-productivity-suite/
├── .claude-plugin/
│   ├── plugin.json          # 插件元数据（核心文件）
│   └── marketplace.json     # 市场信息
├── .claude/
│   ├── commands/            # 斜杠命令
│   │   ├── explore.md
│   │   ├── gitCommit.md
│   │   ├── requirementDoc.md
│   │   ├── rev-engine.md
│   │   └── todoDoc.md
│   ├── agents/              # AI 代理
│   │   ├── code-reviewer.md
│   │   ├── library-usage-researcher.md
│   │   └── memory-network-builder.md
│   ├── hooks/               # 事件钩子
│   │   ├── hooks.json
│   │   └── markdown_formatter.py
│   ├── scripts/             # 辅助脚本
│   │   └── statusline.sh
│   └── batch_edit/          # 批量编辑工具
│       ├── batch_edit.sh
│       └── ...
├── README.md
├── README_CN.md
├── LICENSE
└── .gitignore
```

### 核心配置文件

#### plugin.json（关键！）

```json
{
  "name": "hbsun2113-productivity-suite",
  "version": "1.0.2",
  "description": "A comprehensive productivity plugin for Claude Code",
  "author": {
    "name": "hbsun2113",
    "email": "[email protected]",
    "url": "https://github.com/hbsun2113"
  },
  "homepage": "https://github.com/hbsun2113/hbsun2113-productivity-suite",
  "repository": "https://github.com/hbsun2113/hbsun2113-productivity-suite",
  "license": "MIT",
  "keywords": ["productivity", "workflow", "chinese"],
  "commands": [
    "./.claude/commands/explore.md",
    "./.claude/commands/gitCommit.md",
    "./.claude/commands/requirementDoc.md",
    "./.claude/commands/rev-engine.md",
    "./.claude/commands/todoDoc.md"
  ],
  "agents": [
    "./.claude/agents/code-reviewer.md",
    "./.claude/agents/library-usage-researcher.md",
    "./.claude/agents/memory-network-builder.md"
  ],
  "hooks": "./.claude/hooks/hooks.json",
  "mcpServers": {}
}
```

**关键要点**:
1. ✅ `commands` 和 `agents` **必须是数组**，列出所有 `.md` 文件
2. ❌ **不能**使用目录路径（如 `"./.claude/commands"`）
3. ✅ 所有路径必须以 `./` 开头（相对于插件根目录）
4. ✅ 每个文件必须以 `.md` 结尾

#### marketplace.json

```json
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
        "repo": "hbsun2113/hbsun2113-productivity-suite"
      },
      "description": "A comprehensive productivity plugin",
      "version": "1.0.2",
      "author": {
        "name": "hbsun2113",
        "email": "[email protected]"
      },
      "homepage": "https://github.com/hbsun2113/hbsun2113-productivity-suite",
      "repository": "https://github.com/hbsun2113/hbsun2113-productivity-suite",
      "license": "MIT",
      "keywords": ["productivity", "workflow"]
    }
  ]
}
```

---

## 发布流程

### 前提条件

- GitHub 账号
- Git 已配置 SSH 密钥
- Claude Code CLI 可用

### 步骤1: 创建插件仓库

```bash
# 在 GitHub 上创建仓库（通过 Web UI）
# 仓库名: hbsun2113-productivity-suite

# 初始化插件目录
cd ~/.claude/plugins/hbsun2113-productivity-suite
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin git@github.com:hbsun2113/hbsun2113-productivity-suite.git
git push -u origin main
```

### 步骤2: 创建市场仓库

```bash
# 在 GitHub 上创建市场仓库
# 仓库名: hbsun2113-claude-code-plugins

# 创建本地市场目录
mkdir -p ~/claude-code-plugins/.claude-plugin
cd ~/claude-code-plugins

# 创建 marketplace.json（见上文）
# 提交并推送
git init
git add .
git commit -m "Initial marketplace setup"
git branch -M main
git remote add origin git@github.com:hbsun2113/hbsun2113-claude-code-plugins.git
git push -u origin main
```

### 步骤3: 验证发布

```bash
# 测试安装
/plugin marketplace add hbsun2113-plugins https://github.com/hbsun2113/hbsun2113-claude-code-plugins
/plugin install hbsun2113-productivity-suite

# 测试命令
/explore .
```

---

## 版本管理

### 语义化版本号

格式: `MAJOR.MINOR.PATCH`

- **MAJOR**: 不兼容的 API 变更
- **MINOR**: 向后兼容的新功能
- **PATCH**: 向后兼容的 bug 修复

### 发布新版本

```bash
# 1. 更新版本号
cd ~/.claude/plugins/hbsun2113-productivity-suite
# 编辑 .claude-plugin/plugin.json 中的 version

# 2. 提交变更
git add .
git commit -m "Release v1.0.3"
git tag v1.0.3
git push origin main --tags

# 3. 更新市场
cd ~/claude-code-plugins
# 编辑 .claude-plugin/marketplace.json 中的 version
git add .
git commit -m "Update plugin version to v1.0.3"
git push origin main
```

### 版本历史示例

```markdown
## v1.0.2 (2025-10-16)
- 🐛 修复: 使用正确的文件数组格式
- ✅ 通过 manifest 验证

## v1.0.1 (2025-10-16)
- 🐛 修复: 添加 commands 和 agents 路径配置

## v1.0.0 (2025-10-15)
- 🎉 初始发布
```

---

## 常见问题

### 问题1: "must end with '.md'" 错误

**错误信息**:
```text
Validation errors: agents: Invalid input: must end with '.md'
```

**原因**: `commands` 或 `agents` 字段使用了目录路径

**错误示例**:
```json
{
  "commands": "./.claude/commands",
  "agents": "./.claude/agents"
}
```

**正确方案**:
```json
{
  "commands": [
    "./.claude/commands/explore.md",
    "./.claude/commands/gitCommit.md"
  ],
  "agents": [
    "./.claude/agents/code-reviewer.md"
  ]
}
```

### 问题2: 路径可移植性

**问题**: 硬编码的绝对路径导致插件在其他系统无法使用

**错误示例**:
```bash
# statusline.sh
echo "$input" >> /home/myuser/.claude/statusline-input.txt
```

**正确方案**:
```bash
# 使用 ~ 而不是绝对路径
echo "$input" >> ~/.claude/statusline-input.txt

# 或使用 ${CLAUDE_PLUGIN_ROOT}
echo "$input" >> "${CLAUDE_PLUGIN_ROOT}/.claude/statusline-input.txt"
```

### 问题3: Hooks 权限

**问题**: Hook 脚本没有执行权限

**解决方案**:
```bash
# 在发布前设置执行权限
chmod +x .claude/hooks/markdown_formatter.py
chmod +x .claude/scripts/statusline.sh

# 提交权限变更
git add .
git commit -m "Set execute permissions for scripts"
git push
```

### 问题4: 用户安装后命令不可用

**可能原因**:
1. plugin.json 中缺少 `commands` 配置
2. `commands` 路径不正确
3. 命令文件名拼写错误

**调试步骤**:
```bash
# 1. 检查插件安装位置
ls -la ~/.claude/plugins/your-plugin-name/

# 2. 检查 plugin.json
cat ~/.claude/plugins/your-plugin-name/.claude-plugin/plugin.json

# 3. 验证命令文件存在
ls -la ~/.claude/plugins/your-plugin-name/.claude/commands/

# 4. 检查文件内容
cat ~/.claude/plugins/your-plugin-name/.claude/commands/explore.md
```

---

## 最佳实践

### 1. 文档完整性

必备文档：
- ✅ README.md（英文）
- ✅ README_CN.md（中文，如果目标用户包括中文用户）
- ✅ LICENSE
- ✅ QUICK_START.md（快速上手指南）
- ✅ 详细的命令使用示例

### 2. 代码质量

- ✅ 所有脚本添加 shebang（`#!/bin/bash` 或 `#!/usr/bin/env python3`）
- ✅ 设置正确的执行权限
- ✅ 添加必要的错误处理
- ✅ 提供清晰的错误信息

### 3. 测试

发布前测试清单：
- [ ] 在全新环境安装测试
- [ ] 测试所有斜杠命令
- [ ] 验证 AI 代理触发
- [ ] 测试 Hooks 功能
- [ ] 检查所有文档链接

### 4. 版本控制

- ✅ 使用 git tags 标记版本
- ✅ 维护 CHANGELOG.md
- ✅ 同步更新 plugin.json 和 marketplace.json 中的版本号
- ✅ 重大变更前通知用户

---

## 技术要点总结

### 必须遵守的规则

1. **plugin.json 格式**:
   ```json
   {
     "commands": ["./path/to/cmd1.md", "./path/to/cmd2.md"],
     "agents": ["./path/to/agent1.md", "./path/to/agent2.md"]
   }
   ```
   - ✅ 必须是数组
   - ✅ 每个元素必须以 `.md` 结尾
   - ✅ 路径以 `./` 开头

2. **路径规则**:
   - ✅ 使用相对路径（相对于插件根目录）
   - ✅ Hooks 中使用 `${CLAUDE_PLUGIN_ROOT}` 变量
   - ✅ 脚本中使用 `~/.claude` 而非绝对路径

3. **文件权限**:
   ```bash
   chmod +x .claude/hooks/*.py
   chmod +x .claude/scripts/*.sh
   ```

4. **Git 工作流**:
   ```bash
   # 插件仓库
   git tag v1.0.2
   git push origin main --tags

   # 市场仓库
   # 更新 marketplace.json version
   git push origin main
   ```

### 调试技巧

```bash
# 查看插件列表
/plugin list

# 查看市场列表
/plugin marketplace list

# 重新安装（清理缓存）
/plugin uninstall <name>
rm -rf ~/.claude/plugins/<name>
rm -rf ~/.claude/plugins/cache/*
/plugin install <name>

# 检查插件文件
ls -laR ~/.claude/plugins/<name>/

# 查看错误日志
cat ~/.claude/logs/claude-code.log
```

---

## 联系方式

- **GitHub Issues**: https://github.com/hbsun2113/hbsun2113-productivity-suite/issues
- **Email**: [email protected]
- **插件仓库**: https://github.com/hbsun2113/hbsun2113-productivity-suite
- **市场仓库**: https://github.com/hbsun2113/hbsun2113-claude-code-plugins

---

## 附录: 快速参考

### 用户快速安装

```bash
/plugin marketplace add hbsun2113-plugins https://github.com/hbsun2113/hbsun2113-claude-code-plugins
/plugin install hbsun2113-productivity-suite
/plugin list
```

### 发布者快速发布

```bash
# 1. 创建并配置 plugin.json（数组格式！）
# 2. 初始化 Git
git init && git add . && git commit -m "Initial commit"

# 3. 推送到 GitHub
git remote add origin git@github.com:USER/REPO.git
git push -u origin main

# 4. 创建市场仓库并配置 marketplace.json
# 5. 推送市场仓库
```

### 常用命令速查

| 操作 | 命令 |
|------|------|
| 安装插件 | `/plugin install <name>` |
| 卸载插件 | `/plugin uninstall <name>` |
| 列出插件 | `/plugin list` |
| 启用插件 | `/plugin enable <name>` |
| 禁用插件 | `/plugin disable <name>` |
| 添加市场 | `/plugin marketplace add <name> <url>` |
| 列出市场 | `/plugin marketplace list` |

---

**最后更新**: 2025-10-16
**插件版本**: v1.0.2
**文档版本**: 1.0
