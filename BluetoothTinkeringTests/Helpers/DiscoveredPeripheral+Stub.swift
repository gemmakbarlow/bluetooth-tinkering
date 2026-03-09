@testable import BluetoothTinkering
import Foundation

extension DiscoveredPeripheral {
    static func stub(name: String? = nil, rssi: Int = -50) -> DiscoveredPeripheral {
        DiscoveredPeripheral(
            id: UUID(),
            peripheral: nil,
            name: name,
            rssi: rssi,
            advertisedServiceUUIDs: [],
            lastSeen: Date()
        )
    }
}
