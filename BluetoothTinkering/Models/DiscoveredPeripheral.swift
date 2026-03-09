import CoreBluetooth
import Foundation

struct DiscoveredPeripheral: Identifiable, @unchecked Sendable {
    let id: UUID
    let peripheral: CBPeripheral?
    var name: String?
    var rssi: Int
    var advertisedServiceUUIDs: [CBUUID]
    var lastSeen: Date

    var displayName: String {
        name ?? "Unknown Device"
    }

    var isNamed: Bool {
        name != nil
    }
}
