# NotchMind - AI 编码助手控制中心


## 项目概述

NotchMind 是一个 macOS 应用程序，将 MacBook 的 notch（刘海）区域转换为 AI 编码代理的控制面板。该应用程序监控多个 AI 工具（Claude Code、Codex、Gemini CLI、Cursor、OpenCode、Droid），允许用户批准权限、回答提示，并在不切换上下文的情况下跳转到终端。

## 核心功能

- 利用 MacBook notch 区域作为专用控制面板
- 监控多个 AI 编码工具的状态
- 统一的权限管理界面
- 一键跳转到终端或相应工具
- 保持开发者工作流的连续性
- 内存占用低于 50MB
- 丰富的动画和交互体验
- 模块化的架构设计
- 安全的权限和访问控制
- 多工具切换和管理

## 技术特色

- 原生 Swift/SwiftUI 开发，确保高性能
- 复古未来主义用户界面设计
- 智能权限管理
- 低资源消耗架构
- 高度可定制的控制面板
- 模块化设计便于扩展
- 安全审计功能

## 安装要求

- macOS 12.0 或更高版本
- MacBook Pro 或 MacBook Air（带 notch）
- Xcode 开发环境（开发用途）

## 功能详情

### AI 工具监控
- 自动检测并监控流行的 AI 编码工具
- 实时状态更新（运行中、空闲、错误等）
- 资源使用情况监控

### Notch 集成
- 利用 MacBook Pro notch 区域显示关键信息
- 悬停展开控制面板
- 丰富的动画和过渡效果

### 权限管理
- 统一的权限请求处理界面
- 按风险级别分类的权限管理
- 安全的权限审批流程

### 安全审计
- 访问控制和审计功能
- 网络和文件访问监控
- 安全事件记录和报告

### 键盘快捷键
- `Cmd + Shift + N`: 打开/关闭 notch 面板
- `Cmd + Shift + B`: 后台模式切换
- `Cmd + Shift + A`: 激活 AI 代理
- `Esc`: 关闭打开的面板

## 架构设计

### 模块化架构
NotchMind 采用模块化设计，核心模块包括：

- **AI 工具监控模块**: 检测和跟踪 AI 编码工具
- **性能监控模块**: 监控 CPU 和内存使用情况
- **权限管理模块**: 处理权限请求和批准
- **安全审计模块**: 验证访问请求并记录事件
- **UI 控制模块**: 管理 notch 面板和用户交互

### 接口协议
```swift
protocol AIToolProtocol: AnyObject {
    var id: UUID { get }
    var name: String { get }
    var version: String { get }
    var isActive: Bool { get }
    var status: AITool.ToolStatus { get }

    // 生命周期方法
    func connect() async throws
    func disconnect() async throws

    // 核心功能
    func executeCommand(_ command: String) async throws -> String
    func executeScript(_ script: String) async throws -> String
}
```

## 开发进展

项目已完成核心功能开发，包括：
- Notch 面板 UI 和动画
- AI 工具监控和管理
- 权限管理系统
- 安全审计功能
- 模块化架构
- 文档完善

## 贡献

欢迎社区贡献者参与项目开发。请遵循以下步骤：

1. Fork 仓库
2. 创建特性分支
3. 提交您的更改
4. 发起 Pull Request# NotchMind
