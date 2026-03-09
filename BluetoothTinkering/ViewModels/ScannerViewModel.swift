import Foundation
import Observation

enum SortOption {
    case signalStrength
    case name
}

@Observable
final class ScannerViewModel {
    private let manager: any BluetoothManaging

    var hideUnnamed: Bool = false
    var sortOption: SortOption = .signalStrength

    var bluetoothState: BluetoothState {
        manager.state
    }

    var isScanning: Bool {
        manager.isScanning
    }

    var filteredPeripherals: [DiscoveredPeripheral] {
        var result = manager.discoveredPeripherals

        if hideUnnamed {
            result = result.filter { $0.isNamed }
        }

        switch sortOption {
        case .signalStrength:
            result.sort { $0.rssi > $1.rssi }
        case .name:
            result.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        }

        return result
    }

    init(manager: any BluetoothManaging) {
        self.manager = manager
    }

    func startScanning() {
        manager.startScanning()
    }

    func stopScanning() {
        manager.stopScanning()
    }
}
