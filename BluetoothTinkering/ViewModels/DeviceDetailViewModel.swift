import Foundation
import Observation

@MainActor
@Observable
final class DeviceDetailViewModel {
    private let manager: any BluetoothManaging
    private var connectionTimeoutTask: Task<Void, Never>?

    var connectionState: ConnectionState {
        manager.connectionState
    }

    var isConnecting: Bool {
        manager.connectionState == .connecting
    }

    var services: [DiscoveredService] {
        manager.discoveredServices
    }

    var connectedPeripheral: DiscoveredPeripheral? {
        manager.connectedPeripheral
    }

    var error: String?

    init(manager: any BluetoothManaging) {
        self.manager = manager
    }

    func connect(to peripheral: DiscoveredPeripheral) {
        guard !isConnecting else { return }
        error = nil
        manager.connect(to: peripheral)
        startConnectionTimeout()
    }

    func disconnect() {
        connectionTimeoutTask?.cancel()
        manager.disconnect()
    }

    func discoverServices() {
        manager.discoverServices()
    }

    func discoverCharacteristics(for service: DiscoveredService) {
        manager.discoverCharacteristics(for: service)
    }

    func readValue(for characteristic: DiscoveredCharacteristic) {
        manager.readValue(for: characteristic)
    }

    func writeValue(_ string: String, for characteristic: DiscoveredCharacteristic) {
        guard let data = string.data(using: .utf8) else { return }
        manager.writeValue(data, for: characteristic)
    }

    func toggleNotify(for characteristic: DiscoveredCharacteristic) {
        manager.setNotify(!characteristic.isNotifying, for: characteristic)
    }

    private func startConnectionTimeout() {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = Task {
            try? await Task.sleep(for: .seconds(10))
            if !Task.isCancelled && connectionState == .connecting {
                manager.disconnect()
                error = "Connection timed out. Please try again."
            }
        }
    }
}
