import Foundation

struct BluetoothEvent: Identifiable {
    let id: UUID
    let timestamp: Date
    let type: EventType
    let message: String

    init(type: EventType, message: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.message = message
    }

    enum EventType: String {
        case scan
        case connection
        case disconnection
        case notification
        case error
        case background
    }
}
