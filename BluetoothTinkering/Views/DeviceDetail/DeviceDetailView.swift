import SwiftUI

struct DeviceDetailView: View {
    let peripheral: DiscoveredPeripheral
    @Environment(DeviceDetailViewModel.self) private var viewModel

    var body: some View {
        List {
            connectionSection

            if let error = viewModel.error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            if viewModel.connectionState == .connected {
                servicesContent
            }
        }
        .navigationTitle(peripheral.displayName)
        .onChange(of: viewModel.connectionState) { _, newState in
            if newState == .connected {
                viewModel.discoverServices()
            }
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        Section {
            HStack {
                connectionStateLabel

                Spacer()

                connectionButton
            }
        }
    }

    @ViewBuilder
    private var connectionStateLabel: some View {
        switch viewModel.connectionState {
        case .disconnected:
            Label("Disconnected", systemImage: "circle")
                .foregroundStyle(.secondary)
        case .connecting:
            Label("Connecting...", systemImage: "circle.dotted")
                .foregroundStyle(.orange)
        case .connected:
            Label("Connected", systemImage: "circle.fill")
                .foregroundStyle(.green)
        case .disconnecting:
            Label("Disconnecting...", systemImage: "circle.dotted")
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private var connectionButton: some View {
        switch viewModel.connectionState {
        case .disconnected:
            Button("Connect") {
                viewModel.connect(to: peripheral)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        case .connecting:
            ProgressView()
        case .connected:
            Button("Disconnect") {
                viewModel.disconnect()
            }
            .buttonStyle(.bordered)
            .tint(.red)
        case .disconnecting:
            ProgressView()
        }
    }

    // MARK: - Services Content

    @ViewBuilder
    private var servicesContent: some View {
        if viewModel.services.isEmpty {
            Section {
                ProgressView("Discovering services...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        } else {
            Section("Services") {
                ForEach(viewModel.services) { service in
                    ServiceSection(service: service)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Disconnected") {
    let mock = MockBluetoothManager()
    let viewModel = DeviceDetailViewModel(manager: mock)

    NavigationStack {
        DeviceDetailView(peripheral: DiscoveredPeripheral(
            id: UUID(),
            peripheral: nil,
            name: "Heart Rate Monitor",
            rssi: -55,
            advertisedServiceUUIDs: [],
            lastSeen: Date()
        ))
        .environment(viewModel)
    }
}

#Preview("Connecting") {
    let mock = MockBluetoothManager()
    let _ = { mock.connectionState = .connecting }()
    let viewModel = DeviceDetailViewModel(manager: mock)

    NavigationStack {
        DeviceDetailView(peripheral: DiscoveredPeripheral(
            id: UUID(),
            peripheral: nil,
            name: "Heart Rate Monitor",
            rssi: -55,
            advertisedServiceUUIDs: [],
            lastSeen: Date()
        ))
        .environment(viewModel)
    }
}

#Preview("Connected") {
    let mock = MockBluetoothManager()
    let peripheral = DiscoveredPeripheral(
        id: UUID(),
        peripheral: nil,
        name: "Heart Rate Monitor",
        rssi: -55,
        advertisedServiceUUIDs: [],
        lastSeen: Date()
    )
    let _ = { mock.simulateConnection(peripheral) }()
    let viewModel = DeviceDetailViewModel(manager: mock)

    NavigationStack {
        DeviceDetailView(peripheral: peripheral)
            .environment(viewModel)
    }
}

#Preview("Error State") {
    let mock = MockBluetoothManager()
    let viewModel = DeviceDetailViewModel(manager: mock)
    let _ = { viewModel.error = "Connection timed out. Please try again." }()

    NavigationStack {
        DeviceDetailView(peripheral: DiscoveredPeripheral(
            id: UUID(),
            peripheral: nil,
            name: "Heart Rate Monitor",
            rssi: -55,
            advertisedServiceUUIDs: [],
            lastSeen: Date()
        ))
        .environment(viewModel)
    }
}
