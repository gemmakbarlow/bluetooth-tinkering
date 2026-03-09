import SwiftUI

struct SignalStrengthIndicator: View {
    let rssi: Int

    private var barCount: Int {
        if rssi > -50 {
            return 4
        } else if rssi >= -70 {
            return 3
        } else if rssi >= -85 {
            return 2
        } else {
            return 1
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(1...4, id: \.self) { bar in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(bar <= barCount ? Color.blue : Color.blue.opacity(0.2))
                    .frame(width: 4, height: CGFloat(bar) * 4)
            }
        }
        .frame(height: 16)
    }
}

#Preview("Excellent Signal") {
    SignalStrengthIndicator(rssi: -40)
}

#Preview("Good Signal") {
    SignalStrengthIndicator(rssi: -60)
}

#Preview("Fair Signal") {
    SignalStrengthIndicator(rssi: -75)
}

#Preview("Weak Signal") {
    SignalStrengthIndicator(rssi: -90)
}
