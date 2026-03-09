import Charts
import SwiftUI

struct SimpleLineChart: View {
    let dataPoints: [DataPoint]

    var body: some View {
        Chart(dataPoints) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Value", point.value)
            )
            .foregroundStyle(.blue)

            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Value", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 200)
    }
}

// MARK: - Previews

#Preview {
    let now = Date()
    let samplePoints = (0..<30).map { i in
        DataPoint(
            timestamp: now.addingTimeInterval(Double(i)),
            value: 75.0 + Double.random(in: -15...15)
        )
    }

    SimpleLineChart(dataPoints: samplePoints)
        .padding()
}
