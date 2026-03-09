import SwiftUI

@main
struct BluetoothTinkeringApp: App {
    @State private var bluetoothManager: BluetoothManager
    @State private var scannerViewModel: ScannerViewModel
    @State private var deviceDetailViewModel: DeviceDetailViewModel
    @State private var accessorySetupViewModel: AccessorySetupViewModel
    @State private var backgroundViewModel: BackgroundViewModel
    @State private var dashboardViewModel: DashboardViewModel

    init() {
        let manager = BluetoothManager()
        _bluetoothManager = State(initialValue: manager)
        _scannerViewModel = State(initialValue: ScannerViewModel(manager: manager))
        _deviceDetailViewModel = State(initialValue: DeviceDetailViewModel(manager: manager))
        _accessorySetupViewModel = State(initialValue: AccessorySetupViewModel())
        _backgroundViewModel = State(initialValue: BackgroundViewModel(manager: manager))
        _dashboardViewModel = State(initialValue: DashboardViewModel(manager: manager))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(scannerViewModel)
                .environment(deviceDetailViewModel)
                .environment(accessorySetupViewModel)
                .environment(backgroundViewModel)
                .environment(dashboardViewModel)
                .environment(bluetoothManager)
        }
    }
}
