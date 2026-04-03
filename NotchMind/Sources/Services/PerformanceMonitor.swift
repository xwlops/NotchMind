import Foundation
import Combine

/// Monitors system performance metrics (CPU, Memory)
final class PerformanceMonitor: ObservableObject {
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0

    private var monitorTimer: Timer?
    private let updateInterval: TimeInterval = 5.0  // Reduced from 1.0 to 5.0 seconds

    init() {}

    func startMonitoring() {
        // Initial reading
        updateMetrics()

        monitorTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }

    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func updateMetrics() {
        updateMemoryUsage()
        updateCPUUsage()
    }

    private func updateMemoryUsage() {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMemory = Double(taskInfo.phys_footprint) / 1_048_576 // Convert to MB
            DispatchQueue.main.async {
                self.memoryUsage = usedMemory
            }
        }
    }

    private func updateCPUUsage() {
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUsU,
            &cpuInfo,
            &numCpuInfo
        )

        if result == KERN_SUCCESS, let info = cpuInfo {
            var totalUsage: Double = 0.0
            let numCPUs = Int(numCPUsU)

            for i in 0..<numCPUs {
                let offset = Int(CPU_STATE_USER) + (i * Int(CPU_STATE_MAX))
                let user = Double(info[offset])
                let system = Double(info[offset + 1])
                let idle = Double(info[offset + 2])

                totalUsage += (user + system) / (user + system + idle) * 100.0
            }

            let averageUsage = numCPUs > 0 ? totalUsage / Double(numCPUs) : 0.0

            DispatchQueue.main.async {
                self.cpuUsage = averageUsage
            }

            let infoSize = vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), infoSize)
        }
    }
}
