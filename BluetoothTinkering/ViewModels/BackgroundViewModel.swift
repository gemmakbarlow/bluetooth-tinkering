import Foundation
import Observation

@Observable
final class BackgroundViewModel {
    private let manager: any BluetoothManaging

    var isMonitoring: Bool = false

    var events: [BluetoothEvent] {
        Array(manager.events.sorted { $0.timestamp > $1.timestamp }.prefix(100))
    }

    var hasConnectedDevice: Bool {
        manager.connectedPeripheral != nil
    }

    init(manager: any BluetoothManaging) {
        self.manager = manager
    }
}
