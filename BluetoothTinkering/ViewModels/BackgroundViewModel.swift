import Foundation
import Observation

@MainActor
@Observable
final class BackgroundViewModel {
    private let manager: any BluetoothManaging

    var isMonitoring: Bool = false {
        didSet {
            if isMonitoring {
                manager.startScanning()
            } else {
                manager.stopScanning()
            }
        }
    }

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
