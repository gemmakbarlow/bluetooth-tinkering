import CoreBluetooth
import Foundation

struct DiscoveredCharacteristic: Identifiable {
    let id: String
    let characteristic: CBCharacteristic
    var lastValue: Data?
    var isNotifying: Bool

    init(characteristic: CBCharacteristic) {
        self.id = characteristic.uuid.uuidString
        self.characteristic = characteristic
        self.lastValue = characteristic.value
        self.isNotifying = characteristic.isNotifying
    }

    var canRead: Bool {
        characteristic.properties.contains(.read)
    }

    var canWrite: Bool {
        characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
    }

    var canNotify: Bool {
        characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate)
    }

    var displayName: String {
        characteristic.uuid.description
    }

    var valueString: String? {
        guard let data = lastValue else { return nil }
        return String(data: data, encoding: .utf8) ?? data.map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}
