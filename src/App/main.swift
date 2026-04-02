//
//  NotchMind - AI Coding Assistant Control Center
//  main.swift
//  Application entry point
//

import AppKit

// Main entry point for the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)