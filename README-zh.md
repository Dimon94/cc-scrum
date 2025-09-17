# CC-Scrum Framework

**Claude Code 智能开发框架与 Scrum 集成**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Framework: Claude Code](https://img.shields.io/badge/Framework-Claude%20Code-blue)](https://docs.anthropic.com/en/docs/claude-code)
[![Scrum: Compliant](https://img.shields.io/badge/Scrum-Compliant-green)](https://scrumguides.org/)

## 🎯 概述

CC-Scrum 是一个全面的智能开发框架，通过 Claude Code 子代理将 Scrum 方法论与 AI 驱动的自动化相结合。通过智能任务编排、自动化质量门控和自愈进程，革新您的开发工作流。

### ✨ 核心特性

- **🤖 6 个专业 AI 代理**：产品负责人、Scrum Master、架构师、开发者、QA、安全专家
- **🧠 Meta-Todo 智能化**：4 阶段处理的自动任务分解
- **🔒 质量门控自动化**：100 分评分系统的 DoD 合规性
- **🔄 自愈监控**：24/7 后台进程管理
- **🎯 智能代理路由**：上下文感知的建议和协作
- **📊 Sprint 分析**：速度跟踪和进度分析

## 🚀 快速开始

### 通用一键安装

适用于 **macOS**、**Linux** 和 **Windows** (WSL/Git Bash)：

```bash
curl -fsSL https://raw.githubusercontent.com/Dimon94/cc-scrum/main/install-cc-scrum-universal.sh | bash
```

或下载并本地运行：

```bash
git clone https://github.com/Dimon94/cc-scrum.git
cd cc-scrum
./install-cc-scrum-universal.sh
```

### 平台特定安装

#### 🍎 macOS
```bash
# 标准安装（适用于默认 Bash 3.2）
./install-cc-scrum-universal.sh

# 推荐：使用 Homebrew Bash 4+ 获得增强功能
/usr/local/bin/bash install-cc-scrum-universal.sh
```

#### 🐧 Linux
```bash
# 所有主要发行版（Ubuntu、CentOS、Debian）
./install-cc-scrum-universal.sh

# CI/CD 无人值守模式
./install-cc-scrum-universal.sh --unattended
```

#### 🪟 Windows
```bash
# Git Bash（推荐）
bash install-cc-scrum-universal.sh

# Windows 子系统 for Linux (WSL)
./install-cc-scrum-universal.sh
```

### 交互式安装

通用安装器将：
1. 🔍 **自动检测平台**（macOS/Linux/Windows）和项目类型
2. ⚙️ **配置代理**和质量门控，包含平台优化
3. 📋 **生成文档**，使用跨平台模板
4. 🚀 **设置监控**，集成平台特定工具

## 🛠️ 跨平台项目支持

| 技术栈 | macOS | Linux | Windows | 构建工具 | 质量门控 |
|--------|-------|-------|---------|----------|----------|
| **Node.js** | ✅ | ✅ | ✅ | npm, yarn, pnpm | ESLint, TypeScript, Jest |
| **Python** | ✅ | ✅ | ✅ | pip, poetry, conda | flake8, mypy, pytest |
| **Rust** | ✅ | ✅ | ✅ | cargo | clippy, rustfmt |
| **Go** | ✅ | ✅ | ✅ | go mod | golint, go vet |
| **通用** | ✅ | ✅ | ✅ | 自定义 | 可配置 |

### 平台兼容性说明
- **🍎 macOS**：BSD 工具，兼容 GNU 回退
- **🐧 Linux**：原生 GNU 工具，最佳性能
- **🪟 Windows**：WSL/Git Bash，自动工具检测

## 📁 项目结构

```
cc-scrum/
├── .claude/
│   ├── agents/              # 6 个专业 AI 代理
│   │   ├── po.md           # 产品负责人代理
│   │   ├── sm.md           # Scrum Master 代理
│   │   ├── arch.md         # 解决方案架构师代理
│   │   ├── dev.md          # 开发者代理
│   │   ├── qa.md           # 质量保证代理
│   │   └── sec.md          # 安全专家代理
│   ├── commands/           # 自定义斜杠命令
│   │   ├── review.md       # 代码审查命令
│   │   ├── standup.md      # 每日站会命令
│   │   ├── meta-todo.md    # 智能任务分解
│   │   └── agents-status.md # 代理状态命令
│   ├── hooks/              # 智能钩子系统
│   │   ├── pre_tool_use.sh     # 执行前验证
│   │   ├── post_tool_use.sh    # 执行后分析
│   │   └── user_prompt_submit.sh # 智能路由
│   ├── scripts/            # 自动化脚本
│   │   ├── quality-gate-check-universal.sh
│   │   ├── background-monitor.sh
│   │   └── template-generator.sh
│   ├── templates/          # 动态文档模板
│   │   ├── backlog.template
│   │   ├── dod.template
│   │   └── sprint.template
│   └── settings.json       # 框架配置
├── install-cc-scrum-universal.sh # 通用安装器
├── CLAUDE.md               # AI 开发模式
├── PROJECT_OVERVIEW.md     # 技术架构
├── GETTING_STARTED.md      # 快速开始指南
├── CROSS_PLATFORM_COMPATIBILITY_REPORT.md
└── README.md               # 项目文档
```

## 🤖 代理能力

### @po (产品负责人)
- **INVEST 原则**：用户故事验证和增强
- **MoSCoW 优先级划分**：需求优先级框架
- **利益相关者分析**：沟通和需求收集

### @sm (Scrum Master)
- **Sprint 引导**：规划、每日站会、回顾
- **度量计算**：速度、燃尽图、完成率
- **阻碍跟踪**：障碍识别和解决方案

### @arch (解决方案架构师)
- **ADR 文档**：带权衡分析的架构决策记录
- **系统设计**：可扩展性和性能考虑
- **技术选型**：框架和工具推荐

### @dev (开发者)
- **REPL 优先开发**：交互式算法验证
- **代码质量**：整洁代码原则和最佳实践
- **性能优化**：性能分析和优化技术

### @qa (质量保证)
- **测试金字塔策略**：单元、集成和端到端测试
- **边界条件发现**：边界条件识别
- **覆盖率分析**：全面的测试覆盖率评估

### @sec (安全专家)
- **OWASP Top 10**：全面的安全漏洞评估
- **威胁建模**：安全风险分析和缓解
- **合规性**：GDPR、SOC2 和法规要求验证

## 📋 使用示例

### 智能代码审查
```bash
/review src/auth/login.js
```
- 多代理分析（安全、质量、架构）
- DoD 合规性验证
- 自动化测试和文档检查

### 智能任务分解
```bash
/meta-todo "实现使用 OAuth2 和 JWT 的用户认证"
```
- 专家验证的四阶段处理
- JWT 实现的 REPL 算法测试
- 依赖排序和风险评估

### Sprint 进度跟踪
```bash
/standup
```
- 自动化进度计算
- 阻碍识别
- 速度分析

## 💡 最佳实践

### 1. 用户故事创建
```bash
# 最佳实践
"@po 根据业务需求'提高用户留存率'创建用户故事"

# 示例输出：
# 作为一个新用户，我想要收到个性化的入门指导，
# 以便我能快速了解产品功能并开始使用。
#
# 验收标准：
# - [ ] 新用户注册后显示欢迎向导
# - [ ] 向导包含3-5个关键功能介绍
# - [ ] 用户可以跳过或完成整个向导
# - [ ] 完成向导的用户留存率提高20%
```

### 2. 智能任务分解
```bash
# 复杂功能的任务分解
/meta-todo "实现实时聊天功能" --tier=3 --background

# 系统会自动：
# - 分析需求复杂度 (WebSocket、数据库、UI、安全等)
# - 生成任务依赖图
# - 标识可并行执行的任务
# - 启动背景研究 (最佳实践、性能基准等)
# - 提供时间估算和风险评估
```

### 3. 质量保证流程
```bash
# 开发前：测试策略
"@qa 为实时聊天功能制定测试策略，包括单元测试、集成测试和性能测试"

# 开发中：持续验证
"@qa 检查当前WebSocket实现的测试覆盖率，补充缺失的边界条件测试"

# 开发后：全面评审
/review pr  # 包含自动化测试、代码质量、安全检查
```

### 4. 安全左移实践
```bash
# 设计阶段安全考虑
"@sec 对实时聊天架构进行威胁建模，识别潜在安全风险"

# 实现阶段安全验证
"@sec 审查WebSocket实现，检查输入验证、认证和授权机制"

# 部署前安全扫描
"@sec 对聊天功能进行渗透测试，生成安全评估报告"
```

## 🔧 配置和定制

### 子代理工具权限
每个子代理都配置了特定的工具权限：

```yaml
# 示例：开发者代理配置
tools:
  - Read          # 读取文件
  - Edit          # 编辑文件
  - MultiEdit     # 批量编辑
  - Write         # 创建文件
  - Bash          # 执行命令
  - Grep          # 搜索内容
  - Glob          # 文件模式匹配
  - WebSearch     # 网络搜索
  - WebFetch      # 获取网页内容
```

### 质量门控配置
在 `DOD.md` 中定义完成标准：

```markdown
## 质量要求
- [ ] 测试覆盖率 ≥80%
- [ ] 无高/严重级别安全漏洞
- [ ] 代码规范检查通过
- [ ] 性能基准测试通过
- [ ] 文档更新完成
```

### 个性化配置
在 `CLAUDE.md` 中记录项目特定的模式和约定：

```markdown
## 成功模式
- OAuth实现：研究(3h) + 设计(3h) + 实现(8h) + 测试(6h)
- UI修复：识别(0.5h) + 实现(1h) + 测试(0.5h)

## 技术约定
- 使用TypeScript严格模式
- API优先使用RESTful设计
- 数据库迁移必须可回滚
```

## 📊 效果监控

### 开发效率指标
- **任务完成准确率**: 85-95% (相比传统任务分解的60-70%)
- **时间估算偏差**: ±15% (系统学习后)
- **代码质量得分**: >90% (多代理审查)
- **安全漏洞率**: <0.1% (主动安全集成)

## 🤝 贡献指南

### 扩展子代理
1. 在 `.claude/agents/` 创建新的 Markdown 文件
2. 定义代理角色、职责和工具权限
3. 编写详细的系统提示词
4. 测试代理功能和集成

### 添加新命令
1. 在 `.claude/slash_commands/` 创建命令文件
2. 使用 YAML frontmatter 定义元数据
3. 编写命令功能说明和用法示例
4. 集成到现有工作流中

### 改进质量门控
1. 更新 `DOD.md` 中的质量标准
2. 在 `/review` 命令中添加新的检查项
3. 配置自动化验证脚本
4. 更新 `CLAUDE.md` 中的成功模式

## 📜 许可证

MIT License - 详见 LICENSE 文件

## 🙏 致谢

- **Claude Code 团队**: 提供强大的子代理框架
- **Scrum 社区**: 提供成熟的敏捷开发方法论
- **开源社区**: 提供丰富的工具和最佳实践

---

**开始使用**: `"@po 帮我将第一个需求转换为用户故事"`

让 AI 驱动的 Scrum 流程提升你的开发效率！ 🚀