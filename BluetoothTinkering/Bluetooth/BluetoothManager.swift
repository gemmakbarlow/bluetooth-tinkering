import CoreBluetooth
import Foundation
import Observation

@Observable
final class BluetoothManager: NSObject, BluetoothManaging, @unchecked Sendable {
    var state: BluetoothState = .unknown
    var discoveredPeripherals: [DiscoveredPeripheral] = []
    var connectedPeripheral: DiscoveredPeripheral? = nil
    var connectionState: ConnectionState = .disconnected
    var discoveredServices: [DiscoveredService] = []
    var events: [BluetoothEvent] = []
    var isScanning: Bool = false

    private var centralManager: CBCentralManager!
    private var scanTimeoutTask: Task<Void, Never>?
    private let scanTimeout: TimeInterval

    init(scanTimeout: TimeInterval = 30) {
        self.scanTimeout = scanTimeout
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionRestoreIdentifierKey: "com.gemmakbarlow.bluetooth-tinkering.central"
        ])
    }

    func startScanning() {
        guard state == .poweredOn, !isScanning else { return }
        discoveredPeripherals = []
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        isScanning = true
        events.append(BluetoothEvent(type: .scan, message: "Started scanning"))
        startScanTimeout()
    }

    func stopScanning() {
        scanTimeoutTask?.cancel()
        centralManager.stopScan()
        isScanning = false
        events.append(BluetoothEvent(type: .scan, message: "Stopped scanning"))
    }

    func connect(to peripheral: DiscoveredPeripheral) {
        guard let cbPeripheral = peripheral.peripheral else { return }
        connectionState = .connecting
        centralManager.connect(cbPeripheral, options: nil)
    }

    func disconnect() {
        if let peripheral = connectedPeripheral?.peripheral {
            connectionState = .disconnecting
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func discoverServices() {
        connectedPeripheral?.peripheral?.discoverServices(nil)
    }

    func discoverCharacteristics(for service: DiscoveredService) {
        connectedPeripheral?.peripheral?.discoverCharacteristics(nil, for: service.service)
    }

    func readValue(for characteristic: DiscoveredCharacteristic) {
        connectedPeripheral?.peripheral?.readValue(for: characteristic.characteristic)
    }

    func writeValue(_ data: Data, for characteristic: DiscoveredCharacteristic) {
        let type: CBCharacteristicWriteType = characteristic.characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        connectedPeripheral?.peripheral?.writeValue(data, for: characteristic.characteristic, type: type)
    }

    func setNotify(_ enabled: Bool, for characteristic: DiscoveredCharacteristic) {
        connectedPeripheral?.peripheral?.setNotifyValue(enabled, for: characteristic.characteristic)
    }

    // MARK: - Internal for testing

    func handleDiscovery(id: UUID, name: String?, rssi: Int, serviceUUIDs: [CBUUID]) {
        if let index = discoveredPeripherals.firstIndex(where: { $0.id == id }) {
            discoveredPeripherals[index].rssi = rssi
            discoveredPeripherals[index].lastSeen = Date()
        } else {
            let peripheral = DiscoveredPeripheral(
                id: id,
                peripheral: nil,
                name: name,
                rssi: rssi,
                advertisedServiceUUIDs: serviceUUIDs,
                lastSeen: Date()
            )
            discoveredPeripherals.append(peripheral)
        }
    }

    private func startScanTimeout() {
        scanTimeoutTask?.cancel()
        scanTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(scanTimeout))
            if !Task.isCancelled && isScanning {
                stopScanning()
            }
        }
    }

    private func mapState(_ cbState: CBManagerState) -> BluetoothState {
        switch cbState {
        case .poweredOn: return .poweredOn
        case .poweredOff: return .poweredOff
        case .unauthorized: return .unauthorized
        case .unsupported: return .unsupported
        default: return .unknown
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = mapState(central.state)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []

        if let index = discoveredPeripherals.firstIndex(where: { $0.id == peripheral.identifier }) {
            discoveredPeripherals[index].rssi = RSSI.intValue
            discoveredPeripherals[index].lastSeen = Date()
            if let name = name { discoveredPeripherals[index].name = name }
        } else {
            let discovered = DiscoveredPeripheral(
                id: peripheral.identifier,
                peripheral: peripheral,
                name: name,
                rssi: RSSI.intValue,
                advertisedServiceUUIDs: serviceUUIDs,
                lastSeen: Date()
            )
            discoveredPeripherals.append(discovered)
            events.append(BluetoothEvent(type: .scan, message: "Discovered \(discovered.displayName)"))
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let index = discoveredPeripherals.firstIndex(where: { $0.id == peripheral.identifier }) {
            connectedPeripheral = discoveredPeripherals[index]
        }
        connectionState = .connected
        peripheral.delegate = self
        events.append(BluetoothEvent(type: .connection, message: "Connected to \(peripheral.name ?? "device")"))
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        let name = connectedPeripheral?.displayName ?? "device"
        connectedPeripheral = nil
        connectionState = .disconnected
        discoveredServices = []
        events.append(BluetoothEvent(type: .disconnection, message: "Disconnected from \(name)"))
        if let error = error {
            events.append(BluetoothEvent(type: .error, message: "Disconnect error: \(error.localizedDescription)"))
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        connectionState = .disconnected
        events.append(BluetoothEvent(type: .error, message: "Failed to connect: \(error?.localizedDescription ?? "unknown")"))
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        events.append(BluetoothEvent(type: .background, message: "State restored from background"))
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard let services = peripheral.services else { return }
        discoveredServices = services.map { DiscoveredService(service: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard let characteristics = service.characteristics else { return }
        if let index = discoveredServices.firstIndex(where: { $0.id == service.uuid.uuidString }) {
            discoveredServices[index].characteristics = characteristics.map { DiscoveredCharacteristic(characteristic: $0) }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        for serviceIndex in discoveredServices.indices {
            if let charIndex = discoveredServices[serviceIndex].characteristics.firstIndex(where: { $0.id == characteristic.uuid.uuidString }) {
                discoveredServices[serviceIndex].characteristics[charIndex].lastValue = characteristic.value
            }
        }
        if characteristic.isNotifying {
            events.append(BluetoothEvent(type: .notification, message: "Value updated for \(characteristic.uuid)"))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        for serviceIndex in discoveredServices.indices {
            if let charIndex = discoveredServices[serviceIndex].characteristics.firstIndex(where: { $0.id == characteristic.uuid.uuidString }) {
                discoveredServices[serviceIndex].characteristics[charIndex].isNotifying = characteristic.isNotifying
            }
        }
    }
}
