import CoreBluetooth
import Foundation

enum BluetoothState: Equatable {
    case unknown
    case poweredOff
    case poweredOn
    case unauthorized
    case unsupported
}

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

protocol BluetoothManaging: AnyObject, Observable {
    var state: BluetoothState { get }
    var discoveredPeripherals: [DiscoveredPeripheral] { get }
    var connectedPeripheral: DiscoveredPeripheral? { get }
    var connectionState: ConnectionState { get }
    var discoveredServices: [DiscoveredService] { get }
    var events: [BluetoothEvent] { get }
    var isScanning: Bool { get }

    func startScanning()
    func stopScanning()
    func connect(to peripheral: DiscoveredPeripheral)
    func disconnect()
    func discoverServices()
    func discoverCharacteristics(for service: DiscoveredService)
    func readValue(for characteristic: DiscoveredCharacteristic)
    func writeValue(_ data: Data, for characteristic: DiscoveredCharacteristic)
    func setNotify(_ enabled: Bool, for characteristic: DiscoveredCharacteristic)
}
