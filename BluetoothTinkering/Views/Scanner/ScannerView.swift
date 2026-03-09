import CoreBluetooth
import SwiftUI

struct ScannerView: View {
    @Environment(ScannerViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.filteredPeripherals.isEmpty {
                    emptyState
                } else {
                    peripheralList
                }
            }
            .navigationTitle("Scanner")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.hideUnnamed.toggle()
                    } label: {
                        Image(systemName: viewModel.hideUnnamed ? "eye.slash" : "eye")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $viewModel.sortOption) {
                            Label("Signal Strength", systemImage: "antenna.radiowaves.left.and.right")
                                .tag(SortOption.signalStrength)
                            Label("Name", systemImage: "textformat")
                                .tag(SortOption.name)
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }

    private var peripheralList: some View {
        List(viewModel.filteredPeripherals) { peripheral in
            NavigationLink {
                DeviceDetailView(peripheral: peripheral)
            } label: {
                PeripheralRow(peripheral: peripheral)
            }
        }
        .refreshable {
            viewModel.startScanning()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Devices Found", systemImage: "antenna.radiowaves.left.and.right.slash")
        } description: {
            Text("Make sure Bluetooth is enabled and devices are nearby.")
        }
    }
}

// MARK: - Previews

#Preview("Populated Scanner") {
    let mock = MockBluetoothManager()
    let viewModel = ScannerViewModel(manager: mock)

    // Add mock peripherals
    let _ = {
        mock.simulatePeripheralDiscovered(DiscoveredPeripheral(
            id: UUID(),
            peripheral: nil,
            name: "Heart Rate Monitor",
            rssi: -45,
            advertisedServiceUUIDs: [CBUUID(string: "180D")],
            lastSeen: Date()
        ))
        mock.simulatePeripheralDiscovered(DiscoveredPeripheral(
            id: UUID(),
            peripheral: nil,
            name: "AirPods Pro",
            rssi: -62,
            advertisedServiceUUIDs: [CBUUID(string: "180F"), CBUUID(string: "180A")],
            lastSeen: Date()
        ))
        mock.simulatePeripheralDiscovered(DiscoveredPeripheral(
            id: UUID(),
            peripheral: nil,
            name: nil,
            rssi: -88,
            advertisedServiceUUIDs: [],
            lastSeen: Date()
        ))
    }()

    ScannerView()
        .environment(viewModel)
}

#Preview("Empty Scanner") {
    let mock = MockBluetoothManager()
    let viewModel = ScannerViewModel(manager: mock)

    ScannerView()
        .environment(viewModel)
}
