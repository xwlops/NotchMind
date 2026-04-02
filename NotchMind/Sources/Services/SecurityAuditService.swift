import Foundation
import Security

// MARK: - Security Audit Protocol
protocol SecurityAuditing {
    func auditToolAccess(_ toolId: UUID, forAccessType accessType: AccessType) -> AuditResult
    func auditFileAccess(_ filePath: String, by toolId: UUID) -> AuditResult
    func auditNetworkAccess(_ destination: String, by toolId: UUID) -> AuditResult
    func generateSecurityReport() -> SecurityReport
    func registerSecurityEvent(_ event: SecurityEvent)
}

// MARK: - Security Types
enum AccessType: String, CaseIterable {
    case fileRead = "File Read"
    case fileWrite = "File Write"
    case network = "Network"
    case clipboard = "Clipboard"
    case processControl = "Process Control"
    case shellCommand = "Shell Command"
    case camera = "Camera"
    case microphone = "Microphone"
    case location = "Location"
}

struct AuditResult {
    let allowed: Bool
    let reason: String
    let timestamp: Date
    let riskLevel: RiskLevel

    enum RiskLevel: String, Comparable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"

        static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
            let order: [RiskLevel] = [.low, .medium, .high, .critical]
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
    }
}

struct SecurityReport {
    let timestamp: Date
    let totalAudits: Int
    let suspiciousActivities: [SecurityEvent]
    let riskSummary: [RiskLevel: Int]
    let recommendations: [String]
}

struct SecurityEvent {
    let id: UUID
    let toolId: UUID
    let eventType: EventType
    let timestamp: Date
    let details: String
    let riskLevel: AuditResult.RiskLevel
    let resolved: Bool

    enum EventType: String {
        case unauthorizedAccess = "Unauthorized Access"
        case suspiciousActivity = "Suspicious Activity"
        case policyViolation = "Policy Violation"
        case dataExfiltrationAttempt = "Data Exfiltration Attempt"
        case elevatedPrivileges = "Elevated Privileges"
    }
}

// MARK: - Security Audit Manager
class SecurityAuditManager: SecurityAuditing, ObservableObject {
    static let shared = SecurityAuditManager()

    @Published var securityEvents: [SecurityEvent] = []
    @Published var auditHistory: [AuditRecord] = []

    private init() {}

    // Audit tool access
    func auditToolAccess(_ toolId: UUID, forAccessType accessType: AccessType) -> AuditResult {
        let timestamp = Date()
        let record = AuditRecord(
            toolId: toolId,
            accessType: accessType,
            timestamp: timestamp,
            result: .allowed
        )

        auditHistory.append(record)

        // Default security policy
        switch accessType {
        case .fileWrite, .shellCommand, .processControl:
            return AuditResult(
                allowed: true, // Would normally be controlled by user permissions
                reason: "Access granted based on user permissions",
                timestamp: timestamp,
                riskLevel: .medium
            )
        case .network:
            return AuditResult(
                allowed: true,
                reason: "Network access allowed within sandbox",
                timestamp: timestamp,
                riskLevel: .low
            )
        case .clipboard, .camera, .microphone:
            return AuditResult(
                allowed: false,
                reason: "Restricted access type requires explicit user permission",
                timestamp: timestamp,
                riskLevel: .high
            )
        default:
            return AuditResult(
                allowed: true,
                reason: "Access granted",
                timestamp: timestamp,
                riskLevel: .low
            )
        }
    }

    // Audit file access
    func auditFileAccess(_ filePath: String, by toolId: UUID) -> AuditResult {
        let timestamp = Date()
        let accessType: AccessType = filePath.hasSuffix("/") ? .fileRead : .fileWrite
        let record = AuditRecord(
            toolId: toolId,
            accessType: accessType,
            timestamp: timestamp,
            result: .allowed
        )

        auditHistory.append(record)

        // Check if this is a sensitive file
        let sensitivePaths = ["/etc/", "/private/", "/System/", ".ssh", ".env", "password"]
        let isSensitive = sensitivePaths.contains { filePath.localizedCaseInsensitiveContains($0) }

        if isSensitive {
            let event = SecurityEvent(
                id: UUID(),
                toolId: toolId,
                eventType: .policyViolation,
                timestamp: timestamp,
                details: "Attempted access to sensitive file: \(filePath)",
                riskLevel: .critical,
                resolved: false
            )
            registerSecurityEvent(event)

            return AuditResult(
                allowed: false,
                reason: "Access to sensitive file blocked",
                timestamp: timestamp,
                riskLevel: .critical
            )
        }

        return AuditResult(
            allowed: true,
            reason: "File access allowed within project scope",
            timestamp: timestamp,
            riskLevel: isSensitive ? .high : .low
        )
    }

    // Audit network access
    func auditNetworkAccess(_ destination: String, by toolId: UUID) -> AuditResult {
        let timestamp = Date()
        let record = AuditRecord(
            toolId: toolId,
            accessType: .network,
            timestamp: timestamp,
            result: .allowed
        )

        auditHistory.append(record)

        // Check if destination is in blocked list
        let blockedDomains = ["malware", "phishing", "suspicious"]
        let isBlocked = blockedDomains.contains { destination.localizedCaseInsensitiveContains($0) }

        if isBlocked {
            let event = SecurityEvent(
                id: UUID(),
                toolId: toolId,
                eventType: .suspiciousActivity,
                timestamp: timestamp,
                details: "Attempted connection to blocked domain: \(destination)",
                riskLevel: .critical,
                resolved: false
            )
            registerSecurityEvent(event)

            return AuditResult(
                allowed: false,
                reason: "Connection to blocked domain refused",
                timestamp: timestamp,
                riskLevel: .critical
            )
        }

        return AuditResult(
            allowed: true,
            reason: "Network access allowed within policy",
            timestamp: timestamp,
            riskLevel: .low
        )
    }

    // Generate security report
    func generateSecurityReport() -> SecurityReport {
        let suspiciousActivities = securityEvents.filter { !$0.resolved }
        let riskSummary = Dictionary(grouping: securityEvents, by: \.riskLevel)
            .mapValues { $0.count }

        let recommendations = generateRecommendations()

        return SecurityReport(
            timestamp: Date(),
            totalAudits: auditHistory.count,
            suspiciousActivities: suspiciousActivities,
            riskSummary: riskSummary,
            recommendations: recommendations
        )
    }

    // Register security event
    func registerSecurityEvent(_ event: SecurityEvent) {
        DispatchQueue.main.async {
            self.securityEvents.append(event)
        }
    }

    // MARK: - Private Methods
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []

        // Check for patterns in security events
        let highRiskEvents = securityEvents.filter { $0.riskLevel == .high || $0.riskLevel == .critical }
        if highRiskEvents.count > 5 {
            recommendations.append("Consider reviewing tool permissions for frequently flagged tools")
        }

        let recentEvents = securityEvents.filter {
            Date().timeIntervalSince($0.timestamp) < 86400  // Last 24 hours
        }
        if recentEvents.count > 10 {
            recommendations.append("High volume of security events - consider adjusting policies")
        }

        if recommendations.isEmpty {
            recommendations.append("Security posture looks good. Continue monitoring.")
        }

        return recommendations
    }
}

// MARK: - Supporting Structures
struct AuditRecord {
    let toolId: UUID
    let accessType: AccessType
    let timestamp: Date
    let result: AuditResult

    enum Result {
        case allowed
        case blocked
        case escalated
    }
}

// MARK: - Security Policy Manager
class SecurityPolicyManager {
    static let shared = SecurityPolicyManager()

    private var policies: [UUID: [AccessType: PolicyRule]] = [:]

    private init() {}

    func setPolicy(for toolId: UUID, accessType: AccessType, rule: PolicyRule) {
        if policies[toolId] == nil {
            policies[toolId] = [:]
        }
        policies[toolId]?[accessType] = rule
    }

    func getPolicy(for toolId: UUID, accessType: AccessType) -> PolicyRule? {
        return policies[toolId]?[accessType]
    }

    func evaluatePolicy(for toolId: UUID, accessType: AccessType, context: AccessContext) -> AuditResult {
        guard let policy = getPolicy(for: toolId, accessType: accessType) else {
            // Default policy - require user approval for high-risk access
            switch accessType {
            case .fileWrite, .shellCommand, .processControl:
                return AuditResult(
                    allowed: false,
                    reason: "Explicit user approval required",
                    timestamp: Date(),
                    riskLevel: .medium
                )
            default:
                return AuditResult(
                    allowed: true,
                    reason: "Allowed by default policy",
                    timestamp: Date(),
                    riskLevel: .low
                )
            }
        }

        return policy.evaluate(context: context)
    }
}

struct PolicyRule {
    let allowed: Bool
    let conditions: [Condition]
    let riskLevel: AuditResult.RiskLevel
    let expiration: Date?

    struct Condition {
        let property: Property
        let operation: Operation
        let value: String

        enum Property: String {
            case timeOfDay = "Time of Day"
            case fileExtension = "File Extension"
            case networkDomain = "Network Domain"
            case processPath = "Process Path"
        }

        enum Operation: String {
            case equals = "Equals"
            case contains = "Contains"
            case startsWith = "Starts With"
            case endsWith = "Ends With"
            case greaterThan = "Greater Than"
            case lessThan = "Less Than"
        }
    }

    func evaluate(context: AccessContext) -> AuditResult {
        // Check if policy has expired
        if let expiration = expiration, expiration < Date() {
            return AuditResult(
                allowed: false,
                reason: "Policy has expired",
                timestamp: Date(),
                riskLevel: .medium
            )
        }

        // Evaluate conditions
        for condition in conditions {
            if !evaluate(condition: condition, context: context) {
                return AuditResult(
                    allowed: false,
                    reason: "Condition not met: \(condition.property.rawValue) \(condition.operation.rawValue) \(condition.value)",
                    timestamp: Date(),
                    riskLevel: riskLevel
                )
            }
        }

        return AuditResult(
            allowed: allowed,
            reason: allowed ? "Policy conditions satisfied" : "Policy violation",
            timestamp: Date(),
            riskLevel: riskLevel
        )
    }

    private func evaluate(condition: Condition, context: AccessContext) -> Bool {
        let contextValue = getValue(from: context, property: condition.property)

        switch condition.operation {
        case .equals:
            return contextValue == condition.value
        case .contains:
            return contextValue.localizedCaseInsensitiveContains(condition.value)
        case .startsWith:
            return contextValue.localizedCaseInsensitiveHasPrefix(condition.value)
        case .endsWith:
            return contextValue.localizedCaseInsensitiveHasSuffix(condition.value)
        case .greaterThan:
            return Double(contextValue) ?? 0 > Double(condition.value) ?? 0
        case .lessThan:
            return Double(contextValue) ?? 0 < Double(condition.value) ?? 0
        }
    }

    private func getValue(from context: AccessContext, property: PolicyRule.Condition.Property) -> String {
        switch property {
        case .timeOfDay:
            return DateFormatter().string(from: Date())
        case .fileExtension:
            return (context.filePath ?? "").components(separatedBy: ".").last ?? ""
        case .networkDomain:
            return context.networkDestination ?? ""
        case .processPath:
            return context.processPath ?? ""
        }
    }
}

struct AccessContext {
    let filePath: String?
    let networkDestination: String?
    let processPath: String?
    let time: Date
    let userData: [String: Any]?
}