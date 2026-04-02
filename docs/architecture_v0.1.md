# 架构设计说明文档 v0.1

## 文档概述

### 项目背景

NotchMind 是一款 macOS 系统级工具，旨在为 AI 开发者的终端工作流提供无缝的权限管理与状态监控能力。随着 AI 编程助手（如 Claude Code、Cursor、Windsurf 等）在开发工作流中的广泛使用，开发者需要一种统一的方式来管理这些工具的系统权限请求，同时保持对工具运行状态的实时感知。

NotchMind 利用 MacBook Pro 的 notch 区域作为常驻控制面板，在不干扰用户工作的前提下，提供以下核心功能：
- AI 工具运行状态监控
- 权限请求的实时提醒与审批
- 一键跳转终端
- 资源占用实时监控

### 文档目的

本文档旨在完整描述 NotchMind 的系统架构设计，为开发团队提供明确的技术实现指导。主要目标包括：

1. **明确模块边界**：定义各核心模块的职责边界与交互接口
2. **指导技术实现**：为具体编码工作提供架构依据
3. **支撑性能优化**：明确资源预算，指导性能调优
4. **记录待决事项**：标记需要后续确认的技术决策

---

## 系统架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         NotchMind App                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  Notch Renderer │  │  Agent Manager  │  │ Permission     │  │
│  │                 │◄─┤                 │◄─┤ Layer          │  │
│  │  (SwiftUI)      │  │                 │  │                │  │
│  └────────┬────────┘  └────────┬────────┘  └───────┬────────┘  │
│           │                     │                    │          │
│           │        ┌────────────┴────────────┐       │          │
│           │        │      Tool Bridge        │       │          │
│           └───────►│                         │◄──────┘          │
│                    │  (IPC / XPC / Unix      │                  │
│                    │   Domain Socket)       │                  │
│                    └────────────┬────────────┘                  │
│                                 │                               │
└─────────────────────────────────┼───────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │     External AI Tools     │
                    │  (Claude Code / Cursor /  │
                    │   Windsurf / etc.)        │
                    └───────────────────────────┘
```

### 2.2 模块划分

NotchMind 采用模块化架构设计，核心模块包括：**Notch Renderer（Notch 渲染器）**、**Agent Manager（代理管理器）**、**Tool Bridge（工具桥接层）**、**Permission Layer（权限层）**。

#### 2.2.1 Notch Renderer（Notch 渲染器）

Notch Renderer 负责在 MacBook Pro 的 notch 区域内渲染用户界面，是用户与 NotchMind 交互的主要入口。

**核心职责：**
- **UI 渲染**：使用 SwiftUI 在 notch 区域渲染状态指示器、通知气泡、快捷按钮
- **交互处理**：响应用户的点击、悬停等交互事件
- **动态效果**：实现透明背景、动态光效、平滑过渡动画
- **响应式适配**：适配不同型号 MacBook 的 notch 尺寸（13"/14"/16"）

**技术要点：**
- 窗口级别：NSPanel（透明、无标题栏）
- 渲染框架：SwiftUI + AppKit 混合模式
- 动画框架：SwiftUI Animation + Core Animation

**模块位置**：`/NotchRenderer/` 目录

#### 2.2.2 Agent Manager（代理管理器）

Agent Manager 是系统的中央调度中心，负责协调各个模块的工作，维护 AI 工具的运行时状态。

**核心职责：**
- **工具注册**：管理已连接的 AI 工具列表
- **状态追踪**：实时维护各工具的运行状态（在线/忙碌/离线）
- **事件分发**：接收来自 Tool Bridge 的事件并分发到对应处理模块
- **生命周期管理**：管理工具连接的建立与断开

**技术要点：**
- 设计模式：Coordinator 模式
- 状态管理：Combine 响应式流
- 并发模型：Swift Concurrency (async/await)

**模块位置**：`/AgentManager/` 目录

#### 2.2.3 Tool Bridge（工具桥接层）

Tool Bridge 是 NotchMind 与外部 AI 工具之间的通信桥梁，负责建立和维护进程间通信通道。

**核心职责：**
- **进程间通信**：建立并维护与各 AI 工具的 IPC 通道
- **协议解析**：解析工具发送的权限请求和状态更新消息
- **连接池管理**：管理多个工具的并发连接
- **数据转发**：将工具事件转发给 Agent Manager

**技术要点：**
- 通信方式：Unix Domain Socket（最终确定）
- 序列化：JSON（最终确定）
- 心跳机制：定期健康检查连接状态

**模块位置**：`/ToolBridge/` 目录

#### 2.2.5 Tool Integration（工具集成层）

Tool Integration 是 NotchMind 与外部 AI 工具对接的核心模块，负责统一管理各种 AI 工具的接入、状态监控和权限请求。

**核心职责：**
- **工具发现**：自动检测系统中安装的 AI 工具（Claude Code、Codex、Cursor、Windsurf 等）
- **连接管理**：建立并维护与各工具的进程间通信通道
- **协议适配**：统一不同工具的通信协议差异
- **状态同步**：实时同步各工具的运行状态

**支持的 AI 工具：**
- Claude Code - Anthropic AI 编程助手
- Codex - OpenAI CLI 工具
- Gemini CLI - Google CLI 工具
- Cursor - AI 增强代码编辑器
- Windsurf - AI 终端工具
- OpenCode - 开源 AI 编辑器

**模块位置**：`/ToolIntegration/` 目录

### 2.2.6 Permission Layer（权限层）

Permission Layer 负责处理所有与系统权限相关的逻辑，是安全策略的执行者。

**核心职责：**
- **请求接收**：接收并验证来自 Tool Bridge 的权限请求
- **策略评估**：根据预设规则评估权限请求（白名单/黑名单/需确认）
- **用户授权**：展示权限请求弹窗，获取用户授权决策
- **决策记录**：持久化权限决策历史，支持后续审计

**技术要点：**
- 存储：SQLite（权限决策历史）
- 安全：代码签名验证工具身份
- 隐私：不记录敏感命令内容

**模块位置**：`/PermissionLayer/` 目录

### 2.3 模块交互流程

#### 2.3.1 权限请求处理流程

```
AI Tool ──IPC──► Tool Bridge ──Event──► Agent Manager
                                              │
                                              ▼
                                        Permission Layer
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
              [白名单规则]              [需确认]                 [黑名单规则]
                    │                         │                         │
                    ▼                         ▼                         ▼
              自动授权 ───────────► 用户授权弹窗 ───────────► 拒绝并记录
                                              │
                                              ▼
                                        Notch Renderer
                                              │
                                              ▼
                                        用户决策 ──► 持久化 ──► 返回结果
```

#### 2.3.2 状态监控流程

```
AI Tool ──IPC──► Tool Bridge ──Status Update──► Agent Manager
                                                    │
                                                    ▼
                                              Notch Renderer
                                                    │
                                                    ▼
                                            UI 状态指示器更新
```

---

## 技术方案

### 3.1 进程间通信方式

NotchMind 需要与多个外部 AI 工具建立进程间通信，综合考虑性能、可靠性和开发复杂度，推荐以下方案：

#### 方案对比

| 特性 | Unix Domain Socket | XPC Services | Mach Ports | D-Bus |
|------|-------------------|---------------|-------------|-------|
| 性能 | 高 | 高 | 最高 | 中 |
| 复杂度 | 低 | 中 | 高 | 中 |
| 跨进程 | 是 | 是 | 是 | 否（仅同一主机）|
| macOS 原生 | 是 | 是 | 是 | 否 |
| 调试友好 | 是 | 中 | 低 | 是 |

#### 推荐方案：Unix Domain Socket

**理由：**
1. **性能优异**：相比 XPC 和 D-Bus，Unix Domain Socket 在高并发场景下开销更低
2. **实现简单**：API 简洁，易于理解和维护
3. **跨平台兼容**：BSD 通用特性，未来如需移植更方便
4. **调试方便**：可使用 standard socket 工具进行调试

**协议设计：**
- 消息格式：JSON（文本可读，便于调试）
- 帧格式：Length-Prefixed（4 字节长度 + JSON 消息）
- 心跳间隔：30 秒
- 超时阈值：90 秒无响应则判定连接失效

#### 备选方案：XPC Services

如未来需要更严格的进程隔离或系统级集成，可迁移到 XPC Services：
- **优势**：系统级生命周期管理、原生 crash 报告
- **劣势**：开发复杂度较高、调试困难

### 3.2 内存预算分配

NotchMind 需严格控制在 50MB 以内的内存占用，以下是各模块的内存预算分配：

#### 内存预算表

| 模块 | 预算占比 | 预算大小 | 说明 |
|------|---------|---------|------|
| Notch Renderer | 25% | 12.5 MB | SwiftUI 视图、动画缓冲区 |
| Agent Manager | 15% | 7.5 MB | 状态缓存、事件队列 |
| Tool Bridge | 20% | 10 MB | 连接池、接收缓冲区 |
| Tool Integration | 15% | 7.5 MB | 工具适配器、协议解析 |
| Permission Layer | 10% | 5 MB | 策略缓存、历史记录 |
| 系统预留 | 15% | 7.5 MB | 运行时波动、OS 消耗 |

#### 内存管理策略

1. **对象池**：重用频繁创建/销毁的对象（如事件对象）
2. **懒加载**：非必要数据不预加载，按需获取
3. **自动释放池**：Objective-C/Swift 混编场景下正确使用 AutoreleasePool
4. **内存警告响应**：注册内存警告回调，主动释放非关键缓存

---

## AI 工具集成

### 4.1 集成架构

NotchMind 采用适配器模式实现对多种 AI 工具的统一管理：

```
┌─────────────────────────────────────────────────────────────────┐
│                      Tool Integration Layer                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Claude Code  │  │    Codex     │  │  Gemini CLI  │         │
│  │   Adapter    │  │   Adapter    │  │   Adapter    │  ...    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                 │                 │                  │
│  ┌──────┴─────────────────┴─────────────────┴───────┐         │
│  │              Universal Interface (AIToolInterface) │        │
│  └──────────────────────┬───────────────────────────┘         │
│                         │                                      │
│                    Tool Bridge                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 通用接口定义

```swift
protocol AIToolInterface {
    /// 工具唯一标识
    var identifier: String { get }

    /// 工具显示名称
    var displayName: String { get }

    /// 当前运行状态
    var status: ToolStatus { get }

    /// 检查工具状态
    func checkStatus() async -> ToolStatus

    /// 处理权限请求
    func handlePermissionRequest(_ request: PermissionRequest) async -> PermissionResponse

    /// 激活工具连接
    func connect() async throws

    /// 断开工具连接
    func disconnect() async
}

enum ToolStatus {
    case online      // 正常运行
    case busy        // 处理任务中
    case offline     // 未运行
    case error(Error) // 错误状态
}
```

### 4.3 支持的工具列表

| 工具名称 | 进程名 | 检测方式 | 通信协议 |
|---------|--------|----------|----------|
| Claude Code | `Claude` / `claude` | 进程监控 | Unix Socket |
| Codex | `node` (Codex子进程) | 进程树分析 | Unix Socket |
| Gemini CLI | `gemini` | 进程监控 | Unix Socket |
| Cursor | `Cursor` | 进程监控 | XPC / API |
| Windsurf | `windsurf` | 进程监控 | Unix Socket |
| OpenCode | `opencode` | 进程监控 | Unix Socket |

### 4.4 通信协议

#### 4.4.1 权限请求协议

```json
// Request
{
    "type": "permission_request",
    "id": "req_xxxxx",
    "source": {
        "tool": "claude_code",
        "version": "1.0.0",
        "processId": 12345
    },
    "permission": {
        "type": "file_access",
        "path": "/Users/user/project",
        "mode": "read_write"
    },
    "timestamp": "2026-04-02T10:00:00Z"
}

// Response
{
    "type": "permission_response",
    "requestId": "req_xxxxx",
    "decision": "approved",
    "expiresAt": "2026-04-02T10:30:00Z",
    "conditions": {
        "duration": "session",
        "pathScope": "/Users/user/project/*"
    }
}
```

#### 4.4.2 状态报告协议

```json
{
    "type": "status_update",
    "tool": "claude_code",
    "status": "busy",
    "details": {
        "currentTask": "refactoring auth module",
        "progress": "45%"
    },
    "timestamp": "2026-04-02T10:00:00Z"
}
```

### 4.5 工具发现机制

1. **主动扫描**：启动时扫描常用路径下的 AI 工具
2. **进程监控**：通过 `NSWorkspace` 监控运行中的进程
3. **配置文件**：读取用户自定义的工具路径配置

---

## API 接口说明

### 5.1 核心 API

#### 5.1.1 工具管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/tools` | 获取所有已注册工具列表 |
| GET | `/api/tools/:id` | 获取指定工具的详细信息 |
| POST | `/api/tools/:id/connect` | 连接指定工具 |
| POST | `/api/tools/:id/disconnect` | 断开指定工具 |

#### 5.1.2 权限管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/permissions` | 获取权限请求列表 |
| POST | `/api/permissions/:id/approve` | 批准权限请求 |
| POST | `/api/permissions/:id/deny` | 拒绝权限请求 |
| GET | `/api/permissions/history` | 获取权限历史记录 |

#### 5.1.3 状态监控

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/status` | 获取整体状态 |
| GET | `/api/status/:tool` | 获取指定工具状态 |
| WebSocket | `/ws/status` | 实时状态推送 |

### 5.2 数据类型定义

```swift
// 工具信息
struct ToolInfo: Codable {
    let id: String
    let name: String
    let version: String
    let status: ToolStatus
    let connectedAt: Date?
}

// 权限请求
struct PermissionRequest: Codable {
    let id: String
    let toolId: String
    let type: PermissionType
    let resource: String
    let timestamp: Date
}

enum PermissionType: String, Codable {
    case fileAccess
    case networkAccess
    case shellExecution
    case systemAccess
}

// 权限决策
struct PermissionDecision: Codable {
    let requestId: String
    let decision: DecisionType
    let expiresAt: Date?
    let timestamp: Date
}

enum DecisionType: String, Codable {
    case approved
    case denied
    case temporary
}
```

### 5.3 错误响应

```json
{
    "error": {
        "code": "TOOL_NOT_FOUND",
        "message": "The requested tool is not registered",
        "details": {
            "requestedId": "unknown_tool"
        }
    }
}
```

| 错误码 | 说明 |
|--------|------|
| TOOL_NOT_FOUND | 工具未注册 |
| PERMISSION_DENIED | 权限不足 |
| CONNECTION_FAILED | 连接失败 |
| INVALID_REQUEST | 请求格式错误 |
| TIMEOUT | 操作超时 |

---

## 术语解释

### 核心术语

| 术语 | 英文 | 定义 |
|------|------|------|
| Notch 渲染器 | Notch Renderer | 在 MacBook Pro notch 区域渲染 UI 的模块 |
| 代理管理器 | Agent Manager | 协调各模块工作、管理 AI 工具连接的中央调度模块 |
| 工具桥接层 | Tool Bridge | 建立并维护与外部 AI 工具 IPC 通信的桥接模块 |
| 权限层 | Permission Layer | 处理权限请求、执行业务安全策略的模块 |
| 进程间通信 | IPC (Inter-Process Communication) | 不同进程之间交换数据的机制 |
| Unix Domain Socket | Unix Domain Socket | 同一主机上进程间通信的机制 |
| 权限请求 | Permission Request | AI 工具向 NotchMind 发起的系统权限请求 |
| XPC Services | XPC Services | macOS 上的进程间通信和服务框架 |
| 内存预算 | Memory Budget | 各模块允许使用的最大内存量 |
| MVVM | Model-View-ViewModel | UI 架构模式，分离视图与业务逻辑 |
| Coordinator | Coordinator | 导航流程管理架构模式 |
| ARC | ARC (Automatic Reference Counting) | Swift 的自动引用计数内存管理机制 |
| Combine | Combine | Swift 响应式编程框架 |

### 外部组件

| 术语 | 定义 |
|------|------|
| Claude Code | Anthropic 推出的 AI 编程助手 |
| Cursor | 基于 AI 的代码编辑器 |
| Windsurf | AI 增强的终端工具 |

---

## 待确认项

以下技术决策已完成最终确定：

1. **进程间通信协议** [已确定]
   - 方案：Unix Domain Socket
   - 消息序列化格式：JSON（文本可读，便于调试）
   - 帧格式：Length-Prefixed（4 字节长度 + JSON 消息）
   - 心跳间隔：30 秒
   - 超时阈值：90 秒

2. **权限策略细节** [已确定]
   - 白名单/黑名单规则的具体实现：SQLite 存储 + 内存缓存
   - 用户自定义规则优先级：支持（规则按优先级排序匹配）
   - 权限决策历史的保留周期：默认 30 天，可配置

3. **工具集成方式** [已确定]
   - 各 AI 工具采用适配器模式统一接口
   - 支持工具主动注册与被动发现双模式

4. **性能基准** [已确定]
   - 50MB 内存限制为软性目标，峰值不超过 100MB
   - CPU 占用目标：空闲 < 1%，活跃 < 5%

5. **安全策略** [已确定]
   - AI 工具身份验证：代码签名验证
   - 权限请求传输：同一主机内部通信，无需额外加密

---

## 附录

### 参考文档

- `/docs/architecture.md` - 现有架构文档
- `/docs/ui_design.md` - UI 设计文档
- Apple Developer Documentation - NSPanel, XPC Services, SwiftUI

### 版本历史

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|---------|
| v0.1 | 2026-04-02 | Lang | 初始版本 |