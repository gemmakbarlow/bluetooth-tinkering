import SwiftUI

struct ContentView: View {
    @Environment(BluetoothManager.self) private var bluetoothManager

    var body: some View {
        TabView {
            Tab("Scanner", systemImage: "antenna.radiowaves.left.and.right") {
                ScannerView()
            }
            Tab("Setup", systemImage: "square.and.arrow.down.on.square") {
                AccessorySetupView()
            }
            Tab("Background", systemImage: "moon.fill") {
                BackgroundMonitorView()
            }
            Tab("Dashboard", systemImage: "chart.line.uptrend.xyaxis") {
                DashboardView()
            }
        }
        .tint(.blue)
        .overlay {
            BluetoothStateOverlay(state: bluetoothManager.state)
        }
    }
}
