import SwiftUI

@main
struct BluetoothTinkeringApp: App {
    @State private var appSettings = AppSettings()
    @State private var scannerViewModel: ScannerViewModel
    @State private var deviceDetailViewModel: DeviceDetailViewModel
    @State private var accessorySetupViewModel: AccessorySetupViewModel
    @State private var backgroundViewModel: BackgroundViewModel
    @State private var dashboardViewModel: DashboardViewModel

    init() {
        let settings = AppSettings()
        _appSettings = State(initialValue: settings)
        let manager = settings.activeManager
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
                .environment(appSettings)
                .onChange(of: appSettings.mode) { _, _ in
                    rebuildViewModels()
                }
        }
    }

    private func rebuildViewModels() {
        // Clean up old ViewModels
        backgroundViewModel.isMonitoring = false
        dashboardViewModel.stopMockData()
        dashboardViewModel.stopStaleDataCheck()
        deviceDetailViewModel.disconnect()

        // Create new ViewModels with active manager
        let manager = appSettings.activeManager
        scannerViewModel = ScannerViewModel(manager: manager)
        deviceDetailViewModel = DeviceDetailViewModel(manager: manager)
        backgroundViewModel = BackgroundViewModel(manager: manager)
        dashboardViewModel = DashboardViewModel(manager: manager)
    }
}
