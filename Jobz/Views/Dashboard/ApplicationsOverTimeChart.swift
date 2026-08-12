import SwiftUI
import Charts

struct ApplicationsOverTimeChart: View {
    let records: [ApplicationStatusRecord]
    
    // Group applications by week starting on Sunday
    var timeData: [(date: Date, count: Int)] {
        let validRecords = records.compactMap { $0.appliedAt }
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // 1 is Sunday
        
        let grouped = Dictionary(grouping: validRecords) { date in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        }
        
        return grouped.map { (date: $0.key, count: $0.value.count) }
            .sorted(by: { $0.date < $1.date })
    }
    
    private var minDate: Date? {
        timeData.map(\.date).min()
    }
    
    private var maxDate: Date? {
        timeData.map(\.date).max()
    }
    
    private var yearBoundaryDates: [Date] {
        guard let minDate = minDate, let maxDate = maxDate else { return [] }
        let calendar = Calendar.current
        let startYear = calendar.component(.year, from: minDate)
        let endYear = calendar.component(.year, from: maxDate)
        
        return ((startYear + 1)...endYear).compactMap { year in
            if let date = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
               date >= minDate && date <= maxDate {
                return date
            }
            return nil
        }
    }
    
    private var yearMidDates: [Date] {
        guard let minDate = minDate, let maxDate = maxDate else { return [] }
        let calendar = Calendar.current
        let startYear = calendar.component(.year, from: minDate)
        let endYear = calendar.component(.year, from: maxDate)
        
        return (startYear...endYear).compactMap { year in
            let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? minDate
            let nextYearStart = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) ?? maxDate
            
            let start = max(minDate, yearStart)
            let end = min(maxDate, nextYearStart)
            
            let midInterval = end.timeIntervalSince(start) / 2
            return start.addingTimeInterval(midInterval)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Applications Over Time")
                .font(.headline)
            
            if let minDate = minDate, let maxDate = maxDate {
                Chart {
                    // Vertical Year Boundary Lines
                    ForEach(yearBoundaryDates, id: \.self) { yearDate in
                        RuleMark(x: .value("Year Boundary", yearDate))
                            .foregroundStyle(Color.secondary.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    }
                    
                    ForEach(timeData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date, unit: .weekOfYear),
                            y: .value("Applications", item.count)
                        )
                        .foregroundStyle(Color.indigo)
                        .interpolationMethod(.monotone)
                        
                        AreaMark(
                            x: .value("Date", item.date, unit: .weekOfYear),
                            y: .value("Applications", item.count)
                        )
                        .foregroundStyle(Color.indigo.opacity(0.15))
                    }
                }
                .chartXScale(domain: minDate...maxDate)
                .chartXAxis {
                    // Month ticks & abbreviated month names
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(Color.gray.opacity(0.25))
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .font(.caption2)
                    }
                    
                    // Centered year labels at mid-period for each year
                    AxisMarks(values: yearMidDates) { value in
                        AxisValueLabel(format: .dateTime.year())
                            .font(.caption.bold())
                            .foregroundStyle(Color.primary)
                    }
                }
                .frame(height: 240)
            } else {
                Text("No application data available.")
                    .foregroundColor(.secondary)
                    .frame(height: 220)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
