import SwiftUI

struct SimulatedDataBadge: View {
    var body: some View {
        Text("Simulated Data")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.purple, in: Capsule())
    }
}

// MARK: - Previews

#Preview {
    SimulatedDataBadge()
}
