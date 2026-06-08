# Notch Todo 会话交接

## 1. 会话摘要

本次会话主要围绕 Codex 开发环境做精简和核查：保留面向开发、前端、E2E 和安全审查的能力，移除重复 skills，并对比了 Codex 与 Claude Code 的配置差异。项目代码本身没有继续开发，`notch-todo` 当前仍处于可日常使用状态。

## 2. 完成的工作

- 复核并精简了全局 Codex 配置，保留开发主力能力：
  - Superpowers
  - GitHub
  - Build Web Apps
  - Codex Security
  - OpenAI Developers
  - Browser
  - Chrome
- 保留 E2E 相关 MCP：
  - Context7
  - Playwright
  - Chrome DevTools
  - Filesystem
  - Node REPL
  - Pencil
- 禁用了非开发常驻插件：
  - Notion
  - Google Drive
  - Slack
  - Gmail
  - Hugging Face
  - Documents
  - Spreadsheets
  - Presentations
- 禁用了 `sequential-thinking` MCP。
- 删除了已确认完全重复的本地 Codex skills：
  - 14 个本地 Superpowers 副本，保留插件版 Superpowers。
  - 本地 `react-best-practices`，保留 Build Web Apps 版。
  - `.agents/skills/find-skills`，保留 `.codex/skills/find-skills`。
  - 空目录 `.codex/skills/codex-primary-runtime`。
- 备份已保存到 `~/.codex/cleanup-backup-20260606-204823`。
- 复核 Claude Code 配置并确认：
  - Claude Code 启用插件明显更多，存在 Notion 加载失败、frontend-design 重复、review/UI/workflow/LSP 能力重叠。
  - Claude Code 仅做只读检查，未修改配置。
- 解释了 Codex TUI 与 GUI 的区别：TUI 适合终端开发，GUI 更适合浏览器、设计稿、图片、并行任务和可视化审批。
- 解释了 `frontend-app-builder` 的触发方式及其与 Superpowers、Image Gen、Browser 的关系。

## 3. 待完成的工作

暂无已知项目功能待完成工作。

**当前存在未提交/未跟踪文件：**

- `.superpowers/`：本地 Superpowers/设计探索产物，不应直接提交，除非确认其中内容有项目价值。
- `tomorrow.md`：本地 E2E/任务文件，不应直接提交，除非确认要纳入仓库。
- `HANDOFF.md`：本次交接更新产生的已跟踪文件修改，需要按需提交或丢弃。

## 4. 关键决策

- Notch Todo 的功能方向保持克制：先日常使用，只修复真实问题，不继续扩展复杂功能。
- Codex 配置采用“开发优先、按需启用”原则，减少插件和 skills 噪声。
- Superpowers 保留插件版，不保留本地重复副本；这样避免重复触发和版本分叉。
- E2E 能力组合保留：
  - Playwright MCP 负责流程自动化。
  - Chrome DevTools MCP 负责 Console、Network 和性能诊断。
  - Browser/Chrome 负责本地页面与真实登录态验证。
  - Context7 负责最新库文档查询。
- `frontend-design` 在 Codex 中由 `build-web-apps:frontend-app-builder` 覆盖，不额外安装旧名 skill。
- Codex TUI 作为主力开发界面；GUI 仅在视觉设计、浏览器操作、Computer Use、并行任务管理等场景中更有优势。

## 5. 重要文件

- `HANDOFF.md`：当前交接文档。
- `Sources/NotchTodoApp/NotchPanelView.swift`：紧凑/展开 UI、任务卡片、设置页、状态页和动画参数。
- `Sources/NotchTodoApp/NotchWindowController.swift`：刘海窗口、hover、锁定和收起行为。
- `Sources/NotchTodoApp/AppController.swift`：应用生命周期、文件选择、设置动作和退出。
- `Sources/NotchTodoApp/TaskViewModel.swift`：任务状态、进度和展示分组。
- `Sources/NotchTodoCore/MarkdownTaskParser.swift`：Markdown 解析和 checkbox 最小修改。
- `Sources/NotchTodoCore/TaskFileStore.swift`：文件权限、监控和原子写入。
- `scripts/build-app.sh`：构建本地 App bundle。
- `scripts/install-app.sh`：安装到 `/Applications` 并启动。
- `README.md`：Markdown 模板、构建和安装说明。
- `docs/superpowers/specs/2026-06-06-daily-use-polish-design.md`：最终收尾规格。
- `Tests/NotchTodoAppTests/`、`Tests/NotchTodoCoreTests/`：当前测试。

## 6. 下一步建议

1. 若继续开发 Notch Todo，先日常使用并记录真实问题；不要先扩展功能。
2. 提交前明确处理 `.superpowers/` 和 `tomorrow.md`，避免误提交本地产物。
3. 若只想保存本次交接，提交 `HANDOFF.md` 即可。
4. 如果发现 Codex 配置精简后缺少能力，再按需重新启用对应插件，不要恢复全量插件。

## 当前 Git 状态

- 分支：`main`
- 最近提交：`0d99ac4 docs: add session handoff`
- 未跟踪：`.superpowers/`、`tomorrow.md`
- 本次交接更新后：`HANDOFF.md` 会显示为已修改。
