# Notch Todo 会话交接

## 1. 会话摘要

本次会话确认当前 Notch Todo 已满足主要日常需求，并为后续开发制定了一份克制版路线图。项目代码没有继续改动，新增的工作主要是文档层面的 `roadmap.md`，用于后续逐项评审和执行。

## 2. 完成的工作

- 已提交并推送上一版交接文档：
  - `db86ebe docs: update session handoff`
- 创建 `roadmap.md`，记录后续克制版开发路线：
  - Phase 1：稳定性维护
  - Phase 2：日常便利
  - Phase 3：显示策略
  - Phase 4：分发与维护
- 在 roadmap 中明确后续开发原则：
  - Markdown 文件继续作为唯一数据源。
  - 应用只负责显示任务和切换 checkbox。
  - 不新增任务管理系统能力。
  - 每个阶段小步实现、单独验证。
- 明确暂不纳入的能力：
  - 新增、删除、编辑任务
  - 多文件或多项目
  - 日期自动切换
  - 提醒、通知、番茄钟
  - 第三方任务服务集成
  - 复杂主题或偏好系统
  - 云同步
  - 外接屏支持
- 确定建议的下一个实现包：
  1. 错误状态细分
  2. 设置页增加“重新加载任务”
  3. 设置页增加“打开 Markdown 文件”

## 3. 待完成的工作

暂无已知项目功能待完成工作。

**当前存在未提交/未跟踪文件：**

- `roadmap.md`：本次新增路线图，建议评审后提交。
- `.superpowers/`：本地 Superpowers/设计探索产物，不应直接提交，除非确认其中内容有项目价值。
- `tomorrow.md`：本地 E2E/任务文件，不应直接提交，除非确认要纳入仓库。
- `HANDOFF.md`：本次交接更新产生的已跟踪文件修改，需要按需提交或丢弃。

## 4. 关键决策

- 当前版本功能已满足用户主要需求，后续不再主动扩展产品边界。
- Roadmap 优先维护可靠性和日常便利，不把应用演进为完整 todo app。
- 后续执行应从 `roadmap.md` 的“建议的下一个实现包”开始逐项评审。
- 每项功能都需要保持现有原则：不改任务文本、不重排 Markdown、不接入第三方任务服务。
- 若继续开发，应先写最小复现或验收测试，再做局部实现。

## 5. 重要文件

- `roadmap.md`：后续路线图，下一轮评审和实现的入口。
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
- `Tests/NotchTodoAppTests/`、`Tests/NotchTodoCoreTests/`：当前测试。

## 6. 下一步建议

1. 先评审 `roadmap.md`，确认是否调整阶段、删减条目或重排优先级。
2. 若 roadmap 确认无误，提交 `roadmap.md` 和本次 `HANDOFF.md` 更新。
3. 开始实现前，只选择一个小包：错误状态细分、重新加载任务、打开 Markdown 文件。
4. 提交前继续排除 `.superpowers/` 和 `tomorrow.md`，避免误提交本地产物。

## 当前 Git 状态

- 分支：`main`
- 最近提交：`db86ebe docs: update session handoff`
- 未跟踪：`.superpowers/`、`roadmap.md`、`tomorrow.md`
- 本次交接更新后：`HANDOFF.md` 会显示为已修改。
