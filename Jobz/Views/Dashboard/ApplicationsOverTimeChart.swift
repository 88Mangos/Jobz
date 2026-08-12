import SwiftUI
import Charts

struct ApplicationsOverTimeChart: View {
    let records: [ApplicationStatusRecord]
    
    // Group applications by week/day
    var timeData: [(date: Date, count: Int)] {
        let validRecords = records.compactMap { $0.appliedAt }
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: validRecords) { date in
            calendar.startOfDay(for: date)
        }
        
        return grouped.map { (date: $0.key, count: $0.value.count) }
            .sorted(by: { $0.date < $1.date })
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Applications Over Time")
                .font(.headline)
            
            Chart(timeData, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Applications", item.count)
                )
                .interpolationMethod(.monotone)
                
                AreaMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Applications", item.count)
                )
                .foregroundStyle(.blue.opacity(0.1))
            }
            .frame(height: 220)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
