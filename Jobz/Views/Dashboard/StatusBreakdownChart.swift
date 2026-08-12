import SwiftUI
import Charts

struct StatusBreakdownChart: View {
    let records: [ApplicationStatusRecord]
    
    var statusCounts: [(status: ApplicationStatus, count: Int)] {
        let grouped = Dictionary(grouping: records, by: { $0.status })
        return ApplicationStatus.allCases.map { status in
            (status: status, count: grouped[status]?.count ?? 0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Applications by Status")
                .font(.headline)
            
            Chart(statusCounts, id: \.status) { item in
                BarMark(
                    x: .value("Status", item.status.rawValue),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(by: .value("Status", item.status.rawValue))
                .annotation(position: .top) {
                    if item.count > 0 {
                        Text("\(item.count)")
                            .font(.caption2)
                    }
                }
            }
            .frame(height: 220)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
