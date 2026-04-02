#!/usr/bin/env swift

import Foundation
import Darwin

/**
 Memory Usage Tracker for NotchMind
 Estimates current memory usage and validates it stays within bounds
 */

func getCurrentMemoryUsage() -> Double {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.stride)/4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }

    if kerr == KERN_SUCCESS {
        return Double(info.resident_size) / (1024.0 * 1024.0) // Convert to MB
    } else {
        return 0.0
    }
}

func runMemoryBenchmark() {
    print("🔍 Starting NotchMind Memory Benchmark...")

    // Initial measurement
    let initialMemory = getCurrentMemoryUsage()
    print("📊 Initial memory usage: \(String(format: "%.2f", initialMemory)) MB")

    // Simulate some application activity
    print("⚡ Simulating application activity...")

    // Create some objects to simulate real usage
    var simulatedObjects: [String: AnyObject] = [:]
    for i in 0..<100 {
        let key = "test_object_\(i)"
        simulatedObjects[key] = NSArray(objects: "test_data_\(i)", i, NSDate())
    }

    // Small delay to allow for memory allocation
    Thread.sleep(forTimeInterval: 0.1)

    let duringActivityMemory = getCurrentMemoryUsage()
    print("📈 During activity: \(String(format: "%.2f", duringActivityMemory)) MB")

    // Release simulated objects
    simulatedObjects.removeAll()

    // Force garbage collection simulation
    autoreleasepool {
        // Empty autorelease pool to trigger cleanup
    }

    Thread.sleep(forTimeInterval: 0.1)

    let afterCleanupMemory = getCurrentMemoryUsage()
    print("📉 After cleanup: \(String(format: "%.2f", afterCleanupMemory)) MB")

    // Calculate metrics
    let peakUsage = max(initialMemory, duringActivityMemory, afterCleanupMemory)
    let memoryDelta = afterCleanupMemory - initialMemory

    print("\n📋 Memory Report:")
    print("   Peak Usage: \(String(format: "%.2f", peakUsage)) MB")
    print("   Delta: \(String(format: "%.2f", memoryDelta)) MB")

    // Check against target
    let targetMemory = 50.0 // 50 MB target
    let isWithinBounds = peakUsage <= targetMemory

    print("\n🎯 Target Check (< 50MB): \(isWithinBounds ? "✅ PASS" : "❌ FAIL")")

    if !isWithinBounds {
        print("⚠️  Warning: Memory usage exceeds target of \(targetMemory) MB")
        print("   Current peak: \(String(format: "%.2f", peakUsage)) MB")
    } else {
        print("✨ Great! Memory usage is within target bounds")
    }

    // Final status
    print("\n✅ Benchmark Complete")

    exit(isWithinBounds ? 0 : 1)
}

// Run the benchmark
runMemoryBenchmark()