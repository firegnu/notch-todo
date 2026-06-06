# Notch Todo 会话交接

## 1. 会话摘要

本次会话从零完成了一个原生 macOS 刘海任务应用，并持续打磨了刘海布局、展开动画、任务交互和设置入口。当前版本已进入可日常使用状态，后续目标是先真实使用几天，只修复实际问题，不继续扩展复杂功能。

## 2. 完成的工作

- 实现 SwiftUI + AppKit 原生应用，仅显示在带刘海的内建屏幕。
- 从用户选择的 Markdown 文件读取唯一 `## Tasks` 区域，并通过 checkbox 原位同步 `[ ]` / `[x]`。
- 使用 security-scoped bookmark 持久化文件权限，支持外部文件变化自动刷新。
- 实现刘海旁紧凑进度、hover 展开、锁定、外部点击收起和分阶段平滑动画。
- 紧凑状态使用像素 Labubu，并加入低频眨眼动画和全部完成反馈。
- 移除菜单栏常驻图标，将文件选择、登录启动和退出迁移到展开面板的设置页。
- 完成原生极简视觉刷新：
  - 第一个未完成任务作为“接下来”主卡。
  - 其他任务放入“稍后”，已完成任务沉到“已完成”区域。
  - 普通任务使用低对比独立卡片和 hover 提亮。
  - 主卡字体 `13pt`、普通任务 `12.5pt`，主卡内边距和圆角均为 `13pt`。
- 加入 160ms checkbox/任务重组轻量动画，并遵守 macOS Reduce Motion。
- 统一空任务、全部完成和文件错误状态；错误状态始终可重新选择文件。
- 新增 `scripts/install-app.sh`，可构建、替换 `/Applications/Notch Todo.app` 并启动。
- 已实测安装版本运行路径为 `/Applications/Notch Todo.app/Contents/MacOS/NotchTodo`。
- 完整测试目前为 36 项，全部通过；安装包 ad-hoc 签名验证通过。

最近已推送提交：

- `54cb2e6 feat: finish daily use polish`
- `3b03f1f feat: refine native focus task layout`
- `cc13d9b docs: define native focus visual refresh`
- `402576b feat: move settings into notch panel`

## 3. 待完成的工作

暂无已知功能待完成工作。下一阶段应先日常使用并记录真实问题。

**当前存在未提交文件：**

- `.superpowers/`：本地视觉 brainstorming mockup，不应提交。
- `tomorrow.md`：本地 E2E 任务文件，不应提交。

## 4. 关键决策

- Markdown 文件是唯一数据源；应用不创建、编辑、删除或排序任务文本。
- UI 分组只改变展示顺序，不修改 Markdown 中的行顺序。
- 功能保持克制：不加入日期计算、通知、日历、Todoist/Notion 集成、声音、彩带或复杂配置。
- 只操作内建刘海屏，外接屏幕不显示面板。
- 设置入口只在展开面板中，不保留菜单栏图标。
- 展开面板固定为 `360 x 420`，避免修改已经验收的窗口定位和动画结构。
- 视觉采用 macOS 原生极简方向，Labubu 只作为轻量识别元素。
- 当前没有 Developer ID 签名或公证，本地安装使用 ad-hoc 签名。

## 5. 重要文件

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
- `Tests/NotchTodoAppTests/`、`Tests/NotchTodoCoreTests/`：当前 36 项测试。

## 6. 下一步建议

1. 日常使用几天，重点观察 hover 展开、checkbox 写回和登录启动是否稳定。
2. 若发现问题，先写最小复现测试，再做局部修复；不要顺带增加功能。
3. 需要重新安装时运行 `./scripts/install-app.sh`。
4. 提交新工作前继续排除 `.superpowers/` 和 `tomorrow.md`。

## 当前 Git 状态

- 分支：`main`
- 最近功能提交：`54cb2e6 feat: finish daily use polish`
- 远端：该提交已推送到 `origin/main`
- 未跟踪：`.superpowers/`、`tomorrow.md`
