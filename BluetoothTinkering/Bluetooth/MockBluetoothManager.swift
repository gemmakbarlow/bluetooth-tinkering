import CoreBluetooth
import Foundation
import Observation

@Observable
final class MockBluetoothManager: BluetoothManaging, @unchecked Sendable {
    var state: BluetoothState = .poweredOn
    var discoveredPeripherals: [DiscoveredPeripheral] = []
    var connectedPeripheral: DiscoveredPeripheral? = nil
    var connectionState: ConnectionState = .disconnected
    var discoveredServices: [DiscoveredService] = []
    var events: [BluetoothEvent] = []
    var isScanning: Bool = false

    // Test hooks
    var onStartScanning: (() -> Void)?
    var onStopScanning: (() -> Void)?
    var onConnect: ((DiscoveredPeripheral) -> Void)?
    var onDisconnect: (() -> Void)?

    func startScanning() {
        isScanning = true
        onStartScanning?()
    }

    func stopScanning() {
        isScanning = false
        onStopScanning?()
    }

    func connect(to peripheral: DiscoveredPeripheral) {
        connectionState = .connecting
        onConnect?(peripheral)
    }

    func disconnect() {
        connectionState = .disconnecting
        onDisconnect?()
    }

    func discoverServices() {}
    func discoverCharacteristics(for service: DiscoveredService) {}
    func readValue(for characteristic: DiscoveredCharacteristic) {}
    func writeValue(_ data: Data, for characteristic: DiscoveredCharacteristic) {}
    func setNotify(_ enabled: Bool, for characteristic: DiscoveredCharacteristic) {}

    // MARK: - Test Helpers

    func simulatePeripheralDiscovered(_ peripheral: DiscoveredPeripheral) {
        if let index = discoveredPeripherals.firstIndex(where: { $0.id == peripheral.id }) {
            discoveredPeripherals[index].rssi = peripheral.rssi
            discoveredPeripherals[index].lastSeen = peripheral.lastSeen
        } else {
            discoveredPeripherals.append(peripheral)
        }
        events.append(BluetoothEvent(type: .scan, message: "Discovered \(peripheral.displayName)"))
    }

    func simulateConnection(_ peripheral: DiscoveredPeripheral) {
        connectedPeripheral = peripheral
        connectionState = .connected
        events.append(BluetoothEvent(type: .connection, message: "Connected to \(peripheral.displayName)"))
    }

    func simulateDisconnection() {
        let name = connectedPeripheral?.displayName ?? "device"
        connectedPeripheral = nil
        connectionState = .disconnected
        discoveredServices = []
        events.append(BluetoothEvent(type: .disconnection, message: "Disconnected from \(name)"))
    }

    func simulateStateChange(_ newState: BluetoothState) {
        state = newState
    }
}
