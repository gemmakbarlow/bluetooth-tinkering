import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    private let realManager: BluetoothManager
    private let mockManager: MockBluetoothManager

    var mode: ApplicationMode = .standard

    var activeManager: any BluetoothManaging {
        switch mode {
        case .standard: realManager
        case .demo: mockManager
        }
    }

    var isDemoMode: Bool {
        mode == .demo
    }

    init() {
        self.realManager = BluetoothManager()
        self.mockManager = MockBluetoothManager()
    }
}
