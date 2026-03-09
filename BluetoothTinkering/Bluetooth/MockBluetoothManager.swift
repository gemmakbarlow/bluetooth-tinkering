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
    var simulatedScanningEnabled: Bool = false
    private var simulatedScanTask: Task<Void, Never>?
    private var simulatedConnectTask: Task<Void, Never>?
    private var simulatedDisconnectTask: Task<Void, Never>?

    // Test hooks
    var onStartScanning: (() -> Void)?
    var onStopScanning: (() -> Void)?
    var onConnect: ((DiscoveredPeripheral) -> Void)?
    var onDisconnect: (() -> Void)?

    func startScanning() {
        isScanning = true
        onStartScanning?()
        if simulatedScanningEnabled {
            startSimulatedScan()
        }
    }

    func stopScanning() {
        isScanning = false
        simulatedScanTask?.cancel()
        simulatedScanTask = nil
        onStopScanning?()
    }

    func connect(to peripheral: DiscoveredPeripheral) {
        simulatedDisconnectTask?.cancel()
        connectionState = .connecting
        onConnect?(peripheral)
        if simulatedScanningEnabled {
            simulatedConnectTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled, connectionState == .connecting else { return }
                simulateConnection(peripheral)
            }
        }
    }

    func disconnect() {
        simulatedConnectTask?.cancel()
        connectionState = .disconnecting
        onDisconnect?()
        if simulatedScanningEnabled {
            simulatedDisconnectTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                simulateDisconnection()
            }
        }
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

    // MARK: - Simulated Scanning

    private func startSimulatedScan() {
        simulatedScanTask?.cancel()
        simulatedScanTask = Task { @MainActor in
            let fakePeripherals: [(String?, Int, [CBUUID])] = [
                ("Heart Rate Monitor", -45, [CBUUID(string: "180D")]),
                ("Temperature Sensor", -62, [CBUUID(string: "1809")]),
                ("Blood Pressure", -78, [CBUUID(string: "1810")]),
                (nil, -88, []),
            ]
            for (index, config) in fakePeripherals.enumerated() {
                try? await Task.sleep(for: .milliseconds(300 * (index + 1)))
                guard !Task.isCancelled, isScanning else { return }
                let peripheral = DiscoveredPeripheral(
                    id: UUID(),
                    peripheral: nil,
                    name: config.0,
                    rssi: config.1,
                    advertisedServiceUUIDs: config.2,
                    lastSeen: Date()
                )
                simulatePeripheralDiscovered(peripheral)
            }
        }
    }
}
