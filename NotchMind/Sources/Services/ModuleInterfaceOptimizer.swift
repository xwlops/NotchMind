import Foundation
import Combine

// MARK: - Module Event Protocol
protocol ModuleEvent {
    var timestamp: Date { get }
}

// MARK: - Module Protocol
protocol ModuleProtocol: AnyObject {
    var id: UUID { get }
    var name: String { get }

    func initialize() async throws
    func deinitialize() async throws
}

// MARK: - Module Manager
final class ModuleManager: ObservableObject {
    static let shared = ModuleManager()

    @Published private(set) var modules: [UUID: ModuleProtocol] = [:]
    @Published private(set) var isMonitoring = false

    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func register(module: ModuleProtocol) {
        modules[module.id] = module
    }

    func unregister(moduleId: UUID) {
        modules.removeValue(forKey: moduleId)
    }

    func startMonitoring() {
        isMonitoring = true
    }

    func stopMonitoring() {
        isMonitoring = false
    }
}

// MARK: - Event Publisher
final class EventPublisher<Event: ModuleEvent>: ObservableObject {
    private var subscribers: [AnySubscriberBox] = []

    func subscribe<Handler: ModuleEventHandler>(_ handler: Handler) where Handler.Event == Event {
        let box = SubscriberBox(handler: handler)
        subscribers.append(box)
    }

    func publish(_ event: Event) {
        subscribers.forEach { $0.receive(event) }
    }
}

// MARK: - Module Event Handler
protocol ModuleEventHandler {
    associatedtype Event: ModuleEvent
    func receive(_ event: Event)
}

// MARK: - Subscriber Box
private class SubscriberBox<Event: ModuleEvent>: ModuleEventHandler where Event: ModuleEvent {
    private let handler: (Event) -> Void

    init(handler: @escaping (Event) -> Void) {
        self.handler = handler
    }

    func receive(_ event: ModuleEvent) {
        if let typedEvent = event as? Event {
            handler(typedEvent)
        }
    }
}

// MARK: - Module Errors
enum ModuleError: LocalizedError {
    case moduleNotFound
    case moduleAlreadyRegistered

    var errorDescription: String? {
        switch self {
        case .moduleNotFound:
            return "Module not found"
        case .moduleAlreadyRegistered:
            return "Module already registered"
        }
    }
}