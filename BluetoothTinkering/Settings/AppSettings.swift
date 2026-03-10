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

    var bluetoothState: BluetoothState {
        switch mode {
        case .standard: realManager.state
        case .demo: .poweredOn
        }
    }

    init() {
        self.realManager = BluetoothManager()
        self.mockManager = MockBluetoothManager()
    }

    func enableDemoMode() {
        mockManager.simulatedScanningEnabled = true
        mode = .demo
    }

    func disableDemoMode() {
        mockManager.simulatedScanningEnabled = false
        mockManager.stopScanning()
        mockManager.discoveredPeripherals = []
        if mockManager.connectedPeripheral != nil {
            mockManager.simulateDisconnection()
        }
        mode = .standard
    }
}
