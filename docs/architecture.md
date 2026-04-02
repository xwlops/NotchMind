# NotchMind 系统架构文档

## 整体架构

NotchMind 采用模块化设计，主要分为以下几个组件：

### 1. Notch 控制面板 (Notch Panel)
- 负责在 MacBook 的 notch 区域显示控制界面
- 实现透明背景和动态效果
- 处理用户交互事件

### 2. AI 工具监控器 (AI Tool Monitor)
- 监控多个 AI 工具的运行状态
- 识别工具发出的权限请求
- 维护各工具的通信通道

### 3. 权限管理系统 (Permission Manager)
- 处理来自 AI 工具的权限请求
- 实现用户授权流程
- 记录权限决策历史

### 4. 终端集成模块 (Terminal Integrator)
- 实现一键跳转到终端功能
- 管理多个终端会话
- 保持工作上下文

### 5. 性能监控器 (Performance Monitor)
- 监控内存使用情况
- 确保应用符合 < 50MB RAM 的限制
- 实现资源清理和优化

## 技术栈

- **语言**: Swift
- **框架**: AppKit, SwiftUI, Combine
- **架构模式**: MVVM + Coordinator
- **内存管理**: ARC (Automatic Reference Counting)

## 数据流

```
AI Tools → Monitor → Permission System → User Interface → Notch Panel
                  ↓
            Terminal Integration ← Control Commands
```

## 设计原则

1. **性能优先**: 保持极低内存和CPU占用
2. **用户体验**: 无缝集成，最少化干扰
3. **可扩展性**: 易于集成新的 AI 工具
4. **安全性**: 严格的权限控制和数据保护