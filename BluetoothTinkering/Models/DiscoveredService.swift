import CoreBluetooth
import Foundation

struct DiscoveredService: Identifiable {
    let id: String
    let service: CBService
    var characteristics: [DiscoveredCharacteristic]

    init(service: CBService) {
        self.id = service.uuid.uuidString
        self.service = service
        self.characteristics = []
    }

    var displayName: String {
        service.uuid.description
    }
}
