import SwiftUI

struct ContentView: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
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

            VStack(alignment: .trailing, spacing: 8) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.blue, in: Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 16)
                .padding(.top, 4)

                if appSettings.isDemoMode {
                    DemoModeBadge()
                        .padding(.trailing, 16)
                }
            }
        }
        .overlay {
            if !appSettings.isDemoMode {
                BluetoothStateOverlay(state: appSettings.bluetoothState) {
                    appSettings.enableDemoMode()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
