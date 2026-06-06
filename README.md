# Notch Todo

Notch Todo 是一个轻量的 macOS 原生应用。它从指定的 Markdown 文件读取任务，
在 MacBook 内建刘海旁显示完成进度，并允许在展开面板中切换 checkbox。

## Markdown 模板

应用只读取唯一的 `## Tasks` 区块中的一级 checklist：

```md
# Tomorrow

## Tasks

- [ ] 完成项目周报
- [ ] 准备会议材料
- [x] 回复客户邮件
```

点击刘海面板中的 checkbox 会在原文件中切换 `[ ]` 和 `[x]`。应用不会新增、
删除、改名或排序任务。

## 系统要求

- macOS 14 Sonoma 或更高版本
- 带刘海的 MacBook 内建显示器
- Xcode 及已接受的 Xcode license

应用不会在外接显示器或无刘海显示器上创建悬浮面板，但菜单栏入口仍然可用。

## 构建

当前机器如果没有把 `xcode-select` 指向完整 Xcode，可显式使用 Xcode toolchain：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" \
  SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" \
  swift test

./scripts/build-app.sh
```

生成的应用位于：

```text
build/Notch Todo.app
```

首次启动后，通过菜单栏的月亮图标选择 Markdown 文件。应用使用
security-scoped bookmark 保存文件访问权限。登录时启动默认关闭，可从菜单栏切换。

本地构建使用 ad-hoc 签名，未进行 Apple Developer ID 签名或公证。
