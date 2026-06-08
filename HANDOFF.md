# Notch Todo 会话交接

## 1. 会话摘要

本次会话围绕 `roadmap.md` 逐项完成了 Phase 1 到 Phase 3 的功能与修复，重点是任务文件错误恢复、设置页日常操作、紧凑态显示策略和长列表视觉提示。当前实现已多次通过完整测试，并已提交推送到 `main`。

## 2. 完成的工作

- 新增并提交 `roadmap.md`，记录克制版后续开发路线。
- 完成 Phase 1：错误状态细分、写入冲突重新加载、权限失效重新选择文件。
- 完成 Phase 2：设置页新增“在默认 App 中打开”“在 Finder 中显示”“重新加载任务”。
- 修复设置页内容增多后显示不全的问题，设置页已改为可滚动。
- 完成 Phase 3：全部完成时 compact 状态低调显示、compact 点击展开、任务长列表 scroll fade。
- 新增 `Sources/NotchTodoApp/TaskPanelError.swift`，集中处理面板错误分类、文案和恢复动作。
- 已完成并推送提交：
  - `0ddfd83 docs: add roadmap`
  - `51f396a feat: improve task panel recovery and settings`
  - `23ad95b feat: add task list scroll fade`
- 最近一次提交前完整验证：`swift test`，`53 tests, 0 failures`。

## 3. 待完成的工作

当前已规划但暂缓的功能只剩 Phase 4：

- 安装脚本增加版本检查。
- 增加导出诊断信息。
- Developer ID 签名和公证说明。

**当前存在未提交/未跟踪文件：**

- `.superpowers/`：本地 Superpowers 产物，未提交。
- `tomorrow.md`：本地任务测试文件，未提交。
- `HANDOFF.md`：本次交接更新后会显示为已修改，需要按需提交或保留。

暂无已知功能缺陷；最近用户确认第 1-9 项行为满足需求。

## 4. 关键决策

- Markdown 文件继续作为唯一数据源，应用只显示任务和切换 checkbox。
- 不新增任务增删改、多文件、多项目、提醒、云同步等完整任务管理器能力。
- “打开 Markdown 文件”使用 macOS 默认 App，不内置编辑器。
- “在 Finder 中显示”只定位当前任务文件，文件丢失时进入现有错误状态。
- 设置页内容增多后采用滚动，不扩大面板高度。
- 全部任务完成时不完全隐藏入口，只把 compact label 改成低调 `✓` 并降低 opacity。
- Compact 点击展开不等于 pin，不改变锁定状态。
- 长列表 scroll fade 使用静态低 opacity overlay，不检测滚动位置，避免复杂状态。
- 提交时继续排除 `.superpowers/` 和 `tomorrow.md`。

## 5. 重要文件

- `roadmap.md`：已完成到第 9 项，Phase 4 暂缓。
- `Sources/NotchTodoApp/TaskPanelError.swift`：面板错误分类、文案和恢复动作。
- `Sources/NotchTodoApp/TaskViewModel.swift`：任务状态、错误状态、reload/open/reveal 和 compact label。
- `Sources/NotchTodoApp/NotchPanelView.swift`：紧凑/展开 UI、设置页、滚动 fade、错误状态视图。
- `Sources/NotchTodoApp/NotchWindowController.swift`：hover、compact 点击展开、pin、外部点击收起。
- `Sources/NotchTodoApp/AppController.swift`：启动、文件选择、权限恢复入口。
- `Sources/NotchTodoCore/MarkdownTaskParser.swift`：Markdown 解析和 checkbox 最小修改。
- `Sources/NotchTodoCore/TaskFileStore.swift`：security-scoped bookmark、文件监控、原子写入。
- `scripts/install-app.sh`：构建、安装到 `/Applications` 并启动。
- `Tests/NotchTodoAppTests/`、`Tests/NotchTodoCoreTests/`：当前测试覆盖。

## 6. 下一步建议

1. 暂停功能开发，继续日常使用观察真实问题。
2. 如果恢复开发，优先评审 Phase 4 第 10 项“安装脚本增加版本检查”。
3. 如需提交本交接文档，只 stage `HANDOFF.md`；不要误提交 `.superpowers/` 和 `tomorrow.md`。
4. 提交前继续运行完整测试：`swift test`。

## 当前 Git 状态

- 分支：`main`
- 最近提交：
  - `23ad95b feat: add task list scroll fade`
  - `51f396a feat: improve task panel recovery and settings`
  - `0ddfd83 docs: add roadmap`
- 当前 tracked diff：无。
- 未跟踪：`.superpowers/`、`tomorrow.md`。
- 本次交接更新后：`HANDOFF.md` 会显示为已修改。
