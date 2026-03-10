import SwiftUI

struct DemoModeBadge: View {
    var body: some View {
        Text("Demo Mode")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.purple, in: Capsule())
    }
}

#Preview {
    DemoModeBadge()
}
