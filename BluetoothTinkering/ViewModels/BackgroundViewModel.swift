import Foundation
import Observation

@MainActor
@Observable
final class BackgroundViewModel {
    private let manager: any BluetoothManaging

    // Future Consideration: Both BackgroundViewModel and ScannerViewModel can start/stop scanning
    // independently on the same BluetoothManaging instance. Add reference-counting or a shared
    // scanning coordinator if concurrent scanning from multiple screens becomes an issue.
    var isMonitoring: Bool = false {
        didSet {
            if isMonitoring {
                manager.startScanning()
            } else {
                manager.stopScanning()
            }
        }
    }

    // Future Consideration: Cache sorted events instead of re-sorting on every access,
    // if event volume grows significantly beyond the current 150 cap.
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
