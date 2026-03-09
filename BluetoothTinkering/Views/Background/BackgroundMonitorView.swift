import SwiftUI

struct BackgroundMonitorView: View {
    @Environment(BackgroundViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                Section {
                    Toggle("Monitoring", isOn: $viewModel.isMonitoring)
                        .disabled(!viewModel.hasConnectedDevice)

                    if !viewModel.hasConnectedDevice {
                        Label(
                            "Connect to a device to enable background monitoring.",
                            systemImage: "info.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Section {
                    BackgroundInfoSection()
                }

                Section("Event Log") {
                    if viewModel.events.isEmpty {
                        ContentUnavailableView {
                            Label("No Events", systemImage: "list.bullet")
                        } description: {
                            Text("No events recorded yet")
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.events) { event in
                            EventRow(event: event)
                        }
                    }
                }
            }
            .navigationTitle("Background Monitor")
        }
    }
}

// MARK: - Previews

#Preview("With Events") {
    let mock = MockBluetoothManager()
    let viewModel = BackgroundViewModel(manager: mock)

    let _ = {
        mock.events.append(BluetoothEvent(type: .background, message: "App entered background"))
        mock.events.append(BluetoothEvent(type: .scan, message: "Discovered Heart Rate Monitor"))
        mock.events.append(BluetoothEvent(type: .connection, message: "Connected to Heart Rate Monitor"))
        mock.events.append(BluetoothEvent(type: .notification, message: "Received heart rate: 72 bpm"))
        mock.events.append(BluetoothEvent(type: .error, message: "Connection timeout"))
        mock.events.append(BluetoothEvent(type: .disconnection, message: "Disconnected from Heart Rate Monitor"))
    }()

    BackgroundMonitorView()
        .environment(viewModel)
}

#Preview("Empty") {
    let mock = MockBluetoothManager()
    let viewModel = BackgroundViewModel(manager: mock)

    BackgroundMonitorView()
        .environment(viewModel)
}
