import SwiftUI

struct ServiceSection: View {
    let service: DiscoveredService
    @Environment(DeviceDetailViewModel.self) private var viewModel

    @State private var isExpanded: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if service.characteristics.isEmpty {
                ProgressView("Discovering characteristics...")
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(service.characteristics) { characteristic in
                    CharacteristicRow(
                        characteristic: characteristic,
                        onRead: { viewModel.readValue(for: characteristic) },
                        onWrite: { value in viewModel.writeValue(value, for: characteristic) },
                        onToggleNotify: { viewModel.toggleNotify(for: characteristic) }
                    )
                }
            }
        } label: {
            Text(service.displayName)
                .font(.headline)
                .foregroundStyle(.blue)
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                viewModel.discoverCharacteristics(for: service)
            }
        }
    }
}
