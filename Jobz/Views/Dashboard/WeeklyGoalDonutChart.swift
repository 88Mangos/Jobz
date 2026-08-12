import SwiftUI
import Charts

struct WeeklyGoalDonutChart: View {
    let records: [ApplicationStatusRecord]
    let weeklyGoal: Int = 15 // Target applications per week
    
    var currentWeekCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return records.compactMap { $0.appliedAt }.filter { date in
            calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        }.count
    }
    
    var progressData: [(category: String, count: Int)] {
        let completed = min(currentWeekCount, weeklyGoal)
        let remaining = max(0, weeklyGoal - currentWeekCount)
        return [
            ("Applied", completed),
            ("Remaining", remaining)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Goal Progress (\(currentWeekCount)/\(weeklyGoal))")
                .font(.headline)
            
            Chart(progressData, id: \.category) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.65),
                    angularInset: 1.5
                )
                .foregroundStyle(item.category == "Applied" ? .green : .secondary.opacity(0.2))
            }
            .chartBackground { _ in
                VStack {
                    Text("\(Int((Double(currentWeekCount) / Double(weeklyGoal)) * 100))%")
                        .font(.title)
                        .bold()
                    Text("of goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
