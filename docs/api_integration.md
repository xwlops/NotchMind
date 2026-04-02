# NotchMind AI 工具集成文档

## 文档概述

本文档详细描述 NotchMind 与各类 AI 工具的集成方案，包括接口定义、通信协议、安全机制和扩展性设计。

## 集成概述

NotchMind 需要与以下 AI 工具进行集成：
- Claude Code
- Codex
- Gemini CLI
- Cursor
- OpenCode
- Droid

## 集成架构

### 1. 通用接口层 (Universal Interface Layer)

所有 AI 工具集成都需要实现相同的接口协议，确保统一的管理方式。

```swift
protocol AIToolInterface {
    // 工具唯一标识符
    var identifier: String { get }

    // 工具显示名称
    var displayName: String { get }

    // 工具版本
    var version: String { get }

    // 当前是否激活
    var isActive: Bool { get }

    // 当前状态
    var status: ToolStatus { get }

    // 进程ID（如适用）
    var processId: Int32? { get }

    // 检查工具状态
    func checkStatus() async -> ToolStatus

    // 处理权限请求
    func handlePermissionRequest(_ request: PermissionRequest) async -> PermissionResponse

    // 激活工具连接
    func connect() async throws

    // 断开工具连接
    func disconnect() async

    // 发送消息到工具
    func sendMessage(_ message: ToolMessage) async throws -> ToolResponse
}
```

### 2. 状态管理

```swift
enum ToolStatus: String, Codable {
    case online      // 工具正常运行
    case busy        // 工具正在处理任务
    case offline     // 工具未运行
    case connecting  // 正在连接
    case error       // 错误状态
}

struct ToolInfo: Codable, Identifiable {
    let id: String
    let name: String
    let version: String
    let status: ToolStatus
    let lastActive: Date?
    let processId: Int32?
}
```

### 3. 权限系统

```swift
// 权限请求
struct PermissionRequest: Codable, Identifiable {
    let id: String
    let toolId: String
    let type: PermissionType
    let resource: String
    let details: [String: String]?
    let timestamp: Date
}

enum PermissionType: String, Codable {
    case fileAccess      // 文件访问
    case networkAccess   // 网络访问
    case shellExecution  // Shell 执行
    case systemAccess    // 系统权限
    case clipboardAccess // 剪贴板访问
}

// 权限响应
struct PermissionResponse: Codable {
    let requestId: String
    let decision: DecisionType
    let expiresAt: Date?
    let conditions: PermissionConditions?
    let timestamp: Date
}

enum DecisionType: String, Codable {
    case approved    // 批准
    case denied      // 拒绝
    case temporary  // 临时许可
}

struct PermissionConditions: Codable {
    let duration: String?       // 有效期: "session", "once", "permanent"
    let pathScope: String?      // 路径范围
    let allowedOperations: [String]? // 允许的操作
}

// 权限历史记录
struct PermissionRecord: Codable, Identifiable {
    let id: String
    let requestId: String
    let toolId: String
    let type: PermissionType
    let decision: DecisionType
    let timestamp: Date
    let expiresAt: Date?
}
```

### 4. 消息通信

```swift
// 工具消息
struct ToolMessage: Codable {
    let id: String
    let type: MessageType
    let payload: [String: AnyCodable]
    let timestamp: Date
}

enum MessageType: String, Codable {
    case permissionRequest
    case statusUpdate
    case commandResponse
    case heartbeat
}

// 工具响应
struct ToolResponse: Codable {
    let messageId: String
    let success: Bool
    let data: [String: AnyCodable]?
    let error: String?
}

// 通用 AnyCodable 类型
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
```

## 具体工具集成

### Claude Code 集成

```swift
class ClaudeCodeAdapter: AIToolInterface {
    let identifier = "claude_code"
    let displayName = "Claude Code"
    var version: String = "1.0"

    // 进程检测
    private let processNames = ["Claude", "claude", "Claude Code"]

    func detectProcess() -> Bool {
        // 使用 NSWorkspace 监控运行进程
        let runningProcesses = NSWorkspace.shared.runningApplications
        return runningProcesses.contains { app in
            processNames.contains(app.localizedName ?? "")
        }
    }

    // 通信端口
    var socketPath: String {
        return "/tmp/notchmind_claude_code.sock"
    }
}
```

| 属性 | 值 |
|------|-----|
| 进程名 | `Claude`, `claude` |
| 检测方式 | NSWorkspace 进程监控 |
| 通信协议 | Unix Domain Socket |
| 默认端口 | `/tmp/notchmind_claude_code.sock` |
| 权限类型 | 文件读写、API 调用 |

### Codex 集成

```swift
class CodexAdapter: AIToolInterface {
    let identifier = "codex"
    let displayName = "Codex"

    // Codex 作为 Node.js 子进程运行
    func detectProcess() -> Bool {
        // 检查 node 进程是否带有 codex 参数
        return NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier?.contains("node") == true
        }
    }
}
```

| 属性 | 值 |
|------|-----|
| 进程名 | `node` (Codex 子进程) |
| 检测方式 | 进程树分析 |
| 通信协议 | Unix Domain Socket |
| 权限类型 | 执行权限、文件访问 |

### Gemini CLI 集成

```swift
class GeminiCLIAdapter: AIToolInterface {
    let identifier = "gemini_cli"
    let displayName = "Gemini CLI"

    private let processName = "gemini"
}
```

| 属性 | 值 |
|------|-----|
| 进程名 | `gemini` |
| 检测方式 | 进程监控 |
| 通信协议 | 标准 I/O + Socket |
| 权限类型 | API 访问、文件操作 |

### Cursor 集成

```swift
class CursorAdapter: AIToolInterface {
    let identifier = "cursor"
    let displayName = "Cursor"

    // Cursor 是独立的 macOS 应用
    var bundleIdentifier: String {
        return "com.cursor.sh"
    }
}
```

| 属性 | 值 |
|------|-----|
| Bundle ID | `com.cursor.sh` |
| 检测方式 | Bundle ID 匹配 |
| 通信协议 | XPC / Editor API |
| 权限类型 | 编辑器访问、项目文件 |

### OpenCode 集成

```swift
class OpenCodeAdapter: AIToolInterface {
    let identifier = "opencode"
    let displayName = "OpenCode"
}
```

| 属性 | 值 |
|------|-----|
| 进程名 | `opencode` |
| 检测方式 | 进程监控 |
| 通信协议 | Unix Socket |
| 权限类型 | 项目访问、网络 |

### Droid 集成

```swift
class DroidAdapter: AIToolInterface {
    let identifier = "droid"
    let displayName = "Droid"
}
```

| 属性 | 值 |
|------|-----|
| 进程名 | `Droid` 相关进程 |
| 检测方式 | 进程监控 |
| 通信协议 | 专用协议 |
| 权限类型 | 移动开发、模拟器 |

## 通信协议

### 1. 消息格式

所有通信消息采用 JSON 格式，帧格式为 Length-Prefixed（4 字节长度 + JSON 消息）：

```
┌────────────┬────────────────────────────────────┐
│ Length (4) │         Payload (JSON)             │
│ 0x0000012C │ {"type": "permission_request", ...} │
└────────────┴────────────────────────────────────┘
```

### 2. 权限请求协议

```json
// Request
{
    "type": "permission_request",
    "id": "req_8a7f3d2e",
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
    "context": {
        "fileType": "source",
        "operation": "create"
    },
    "timestamp": "2026-04-02T10:00:00.000Z"
}

// Response
{
    "type": "permission_response",
    "requestId": "req_8a7f3d2e",
    "decision": "approved",
    "expiresAt": "2026-04-02T10:30:00.000Z",
    "conditions": {
        "duration": "session",
        "pathScope": "/Users/user/project/*"
    },
    "timestamp": "2026-04-02T10:00:05.000Z"
}
```

### 3. 状态报告协议

```json
// Status Update
{
    "type": "status_update",
    "tool": "claude_code",
    "status": "busy",
    "details": {
        "currentTask": "refactoring auth module",
        "progress": "45%",
        "filesModified": 12
    },
    "timestamp": "2026-04-02T10:00:00.000Z"
}

// Heartbeat
{
    "type": "heartbeat",
    "tool": "claude_code",
    "uptime": 3600,
    "timestamp": "2026-04-02T10:00:00.000Z"
}
```

### 4. 心跳机制

- 心跳间隔：30 秒
- 超时阈值：90 秒无响应则判定连接失效
- 心跳消息：`{"type": "heartbeat", "tool": "...", "timestamp": "..."}`

## 扩展性设计

### 1. 插件系统

```swift
// 插件接口
protocol ToolAdapterPlugin {
    var adapter: AIToolInterface { get }
    func install() async throws
    func uninstall() async throws
    func update() async throws
}

// 插件管理器
class PluginManager {
    func loadPlugin(from path: String) async throws -> ToolAdapterPlugin
    func unloadPlugin(identifier: String) async throws
    func listPlugins() -> [ToolAdapterPlugin]
}
```

| 功能 | 说明 |
|------|------|
| 插件发现 | 扫描 `~/Library/Application Support/NotchMind/Plugins/` |
| 热加载 | 支持运行时加载/卸载插件 |
| 版本管理 | 支持插件版本检查和更新 |

### 2. 配置管理

```swift
struct ToolConfiguration: Codable {
    let toolId: String
    let enabled: Bool
    let autoConnect: Bool
    let permissionRules: [PermissionRule]
    let notificationSettings: NotificationConfig
}

struct PermissionRule: Codable {
    let type: PermissionType
    let action: RuleAction  // allow, deny, prompt
    let pathPatterns: [String]?
    let expiresAt: Date?
}
```

| 配置项 | 说明 |
|--------|------|
| 工具启用状态 | 是否启用该工具的集成 |
| 自动连接 | 启动时自动连接工具 |
| 权限规则 | 自定义权限过滤规则 |
| 通知设置 | 通知偏好配置 |

## 安全考虑

### 1. 沙盒隔离

```swift
// 工具隔离配置
struct ToolIsolationConfig {
    let enableSandbox: Bool
    let allowedPaths: [String]
    let deniedPaths: [String]
    let networkAccess: NetworkAccessLevel
    let maxMemoryMB: Int
}

enum NetworkAccessLevel {
    case none      // 禁止网络访问
    case localOnly // 仅本地网络
    case limited   // 限制域名
    case full      // 完全开放
}
```

| 配置项 | 说明 |
|--------|------|
| 沙盒启用 | 是否启用进程沙盒 |
| 允许路径 | 白名单路径 |
| 禁止路径 | 黑名单路径 |
| 网络级别 | 网络访问限制 |
| 内存限制 | 最大内存占用 |

### 2. 权限控制

```swift
// 权限控制策略
class PermissionPolicy {
    // 最小权限原则
    func evaluate(_ request: PermissionRequest) -> PermissionDecision

    // 临时权限管理
    func grantTemporary(_ request: PermissionRequest, duration: TimeInterval) -> PermissionDecision

    // 权限审计
    func audit(_ record: PermissionRecord)
}
```

| 策略 | 说明 |
|------|------|
| 最小权限 | 只授予必需的最小权限 |
| 临时许可 | 限制时间，过期自动失效 |
| 审计日志 | 记录所有权限使用 |

### 3. 数据保护

```swift
// 敏感数据处理
class SecureStorage {
    // 加密存储
    func store(key: String, value: Data) throws

    // 安全清理
    func secureWipe(_ key: String) throws
}

// 敏感配置示例
struct SecureConfig: Codable {
    @SecureString var apiKey: String  // 自动加密存储
    @SecureString var token: String
}
```

| 措施 | 说明 |
|------|------|
| 加密存储 | API Key、Token 等敏感信息加密 |
| 安全清理 | 权限释放后清除残留数据 |
| 内存保护 | 敏感数据不使用字符串明文 |

---

## 版本历史

| 版本 | 日期 | 变更说明 |
|------|------|----------|
| v0.2 | 2026-04-02 | 补充详细 API 定义和通信协议 |
| v0.1 | 2026-04-02 | 初始版本 |