# NotchMind - Development Team Guide

## Project Overview

NotchMind is a native macOS application that transforms the MacBook notch area into an AI coding assistant control panel. It monitors multiple AI tools (Claude Code, Codex, Gemini CLI, Cursor, OpenCode, Droid) and provides unified permission management.

## Architecture

- **Pattern**: MVVM + Coordinator
- **Language**: Swift 5.9
- **Minimum macOS**: 12.0
- **Target**: Native macOS app with status bar integration

## Project Structure

```
NotchMind/
├── src/
│   ├── App/          # AppDelegate, main entry point
│   ├── Models/       # Data models (AIToolType, ToolStatus)
│   ├── Views/        # UI components (NotchPanelController)
│   ├── ViewModels/   # MVVM view models
│   ├── Services/     # Business logic (AIToolMonitorService, PermissionManagerService)
│   ├── Utilities/    # Constants, helpers
│   └── Extensions/   # NSColor+Hex, Date+Extensions
├── resources/        # Info.plist, entitlements, assets
├── tests/            # Unit tests
└── project.yml       # XcodeGen configuration
```

## Key Components

### Services
- **AIToolMonitorService**: Monitors AI tool processes and status
- **PermissionManagerService**: Handles permission requests and history

### Views
- **NotchPanelController**: NSPanel for notch area display
- **ToolStatusIndicatorView**: Individual tool status indicators

## Building the Project

### Prerequisites
1. Install XcodeGen: `brew install xcodegen`
2. Generate Xcode project: `xcodegen generate`
3. Open `NotchMind.xcodeproj` in Xcode

### Running
- Build with ⌘R in Xcode
- The app runs as a status bar application (menu bar icon)

## Development Guidelines

### Memory Budget
- Target: < 50MB RAM usage
- Use value types (struct) over reference types (class) where possible
- Implement proper cleanup in deinit

### Code Style
- Follow Swift API Design Guidelines
- Use Combine for reactive bindings
- Prefer protocols over concrete implementations

### Testing
- Unit tests in `tests/` directory
- Run tests with ⌘U in Xcode

## Dependencies

Currently no external dependencies - using native frameworks only:
- AppKit (UI)
- Combine (Reactive programming)
- Foundation (Core utilities)

## Notes

- The app is designed to run as a menu bar (status bar) application
- Notch panel displays floating above other windows
- Retro-futuristic UI design with dark theme