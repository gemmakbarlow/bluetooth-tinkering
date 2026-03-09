import SwiftUI

struct AccessorySetupView: View {
    @Environment(AccessorySetupViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                Section {
                    AccessorySetupInfoSection()
                }

                Section {
                    Button {
                        viewModel.showPicker()
                    } label: {
                        Label("Pair New Accessory", systemImage: "plus.circle.fill")
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                }

                Section("Paired Accessories") {
                    if viewModel.accessories.isEmpty {
                        ContentUnavailableView {
                            Label("No Accessories", systemImage: "sensor.tag.radiowaves.forward")
                        } description: {
                            Text("No accessories paired yet. Tap 'Pair New Accessory' to get started.")
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.accessories) { accessory in
                            PairedAccessoryRow(accessory: accessory) {
                                viewModel.removeAccessory(accessory)
                            } onRename: { newName in
                                viewModel.renameAccessory(accessory, to: newName)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Accessory Setup")
            .onAppear {
                viewModel.activateSession()
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.error != nil },
                    set: { if !$0 { viewModel.error = nil } }
                ),
                presenting: viewModel.error
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
}

// MARK: - Previews

#Preview("With Accessories") {
    let viewModel = AccessorySetupViewModel()

    let _ = {
        viewModel.handleAccessoryAdded(displayName: "Heart Rate Monitor")
        viewModel.handleAccessoryAdded(displayName: "Temperature Sensor")
        viewModel.handleAccessoryAdded(displayName: "Cycling Speed Sensor")
    }()

    AccessorySetupView()
        .environment(viewModel)
}

#Preview("Empty") {
    let viewModel = AccessorySetupViewModel()

    AccessorySetupView()
        .environment(viewModel)
}
