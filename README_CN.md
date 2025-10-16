# hbsun2113 的生产力套件

一个全面的 Claude Code 生产力插件，通过强大的斜杠命令、专业代理、智能钩子和批量编辑功能增强您的开发工作流。

## 🚀 功能特性

### 斜杠命令

- **`/explore`** - 深度代码分析与探索
  - 使用符号工具系统化分析代码结构
  - 为开发决策提供可操作的见解
  - 只读方式探索代码库

- **`/gitCommit`** - 创建格式正确的 git 提交
  - 自动生成提交信息
  - 包含 Claude 协作签名

- **`/requirementDoc`** - 分析需求并编写文档
  - 将需求转换为结构化文档
  - 支持自定义文档命名

- **`/rev-engine`** - 通过多轮 ultrathink 实现最大化 Claude 规划
  - 多轮规划配合计划模式
  - 交互式或自动化规划
  - 聚焦特定领域的规划

- **`/todoDoc`** - 从需求创建待办事项列表
  - 从需求文档生成实施计划
  - 与 TodoWrite 同步实现实时跟踪

### 自定义代理

- **`code-reviewer`** - 专业代码审查专家
  - 主动代码质量检查
  - 安全性和可维护性分析

- **`library-usage-researcher`** - 研究库使用模式
  - 系统化收集库文档
  - 来自 GitHub 的真实使用示例
  - 最佳实践和高级技巧（中文输出）

- **`memory-network-builder`** - 构建和管理记忆网络
  - 组织项目知识
  - 交叉引用信息

### 钩子

- **Markdown 格式化器**（PostToolUse）
  - Edit/Write 操作后自动格式化 markdown 文件
  - 检测并添加缺失的代码块语言标签
  - 修复过多的空行

### 状态栏

- 增强的状态栏显示：
  - 当前目录（彩色）
  - Git 分支（如果在仓库中）
  - 当前模型名称

### 批量编辑工具

强大的批量文件编辑系统，用于高效的多文件操作：
- 带自动备份的顺序执行
- 失败时回滚
- 支持创建、替换、插入、删除和补丁操作
- 全面的验证

## 📦 安装

### 使用 Claude Code 插件系统

```bash
# 添加插件市场
/plugin marketplace add hbsun2113/claude-code-plugins

# 安装插件
/plugin install hbsun2113-productivity-suite
```

### 手动安装

1. 克隆或下载此插件到你的 `~/.claude/plugins/` 目录
2. 重启 Claude Code 或重新加载插件
3. 插件将自动被检测和加载

## 🔧 依赖项

- **Python** >= 3.6（用于 markdown 格式化器钩子）
- **Bash** >= 4.0（用于状态栏和批量编辑）
- **jq** >= 1.5（用于状态栏中的 JSON 解析）

## 📖 使用示例

### 代码探索
```bash
/explore src/components
```

### 创建待办事项列表
```bash
/todoDoc requirements.md implementation-plan.md
```

### 研究库
让 Claude 使用 `library-usage-researcher` 代理：
```text
我想了解如何使用 React Query 进行数据获取
```

### 批量编辑文件
```bash
./batch_edit/batch_edit.sh operations.json
```

## 🎯 插件组件

```text
hbsun2113-productivity-suite/
├── plugin.json                 # 插件配置
├── README.md                   # 英文文档
├── README_CN.md                # 中文文档
├── .claude/
│   ├── commands/              # 斜杠命令
│   │   ├── explore.md
│   │   ├── gitCommit.md
│   │   ├── requirementDoc.md
│   │   ├── rev-engine.md
│   │   └── todoDoc.md
│   ├── agents/                # 自定义代理
│   │   ├── code-reviewer.md
│   │   ├── library-usage-researcher.md
│   │   └── memory-network-builder.md
│   ├── hooks/                 # 钩子
│   │   └── markdown_formatter.py
│   └── scripts/               # 脚本
│       └── statusline.sh
└── batch_edit/                # 批量编辑工具
    ├── batch_edit.sh
    ├── doc/
    └── tests/
```

## 🤝 贡献

欢迎贡献！请随时提交问题或拉取请求。

## 📄 许可证

MIT 许可证 - 可自由使用和修改。

## 👤 作者

**hbsun2113**

## 🙏 致谢

为 Claude Code 社区构建，旨在提升开发生产力。
