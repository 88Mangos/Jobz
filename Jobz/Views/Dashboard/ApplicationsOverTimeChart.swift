import SwiftUI
import Charts

struct ApplicationsOverTimeChart: View {
    let metricsService = MetricsService()
    
    @State private var timeData: [MetricsService.TimeSeriesDataPoint] = []
    
    @State private var isFilteringByDate: Bool = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    
    @State private var showApplications: Bool = true
    @State private var showInterviews: Bool = true
    @State private var showOAs: Bool = true
    
    @State private var hoveredDate: Date?
    
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            // Left Controls Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Metrics Over Time")
                    .font(.headline)
                
                let data = hoveredDate.flatMap { date in timeData.first(where: { Calendar.current.isDate($0.weekStart, equalTo: date, toGranularity: .weekOfYear) }) }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hoveredDate?.formatted(date: .abbreviated, time: .omitted) ?? "Hover for week")
                        .font(.caption.bold())
                        .foregroundColor(hoveredDate == nil ? .secondary : .primary)
                    
                    if showApplications {
                        HStack(spacing: 4) {
                            Text("Applications:").foregroundColor(.blue)
                            Text(data != nil ? "\(data!.applications)" : "-").foregroundColor(.blue)
                        }
                        .font(.caption)
                    }
                    if showOAs {
                        HStack(spacing: 4) {
                            Text("OAs:").foregroundColor(.purple)
                            Text(data != nil ? "\(data!.oas)" : "-").foregroundColor(.purple)
                        }
                        .font(.caption)
                    }
                    if showInterviews {
                        HStack(spacing: 4) {
                            Text("Interviews:").foregroundColor(.orange)
                            Text(data != nil ? "\(data!.interviews)" : "-").foregroundColor(.orange)
                        }
                        .font(.caption)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
                
                Divider()
                
                // Date Filter
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Filter by Date", isOn: $isFilteringByDate)
                        .toggleStyle(.switch)
                    
                    if isFilteringByDate {
                        DatePicker("From", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                        DatePicker("To", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                        
                        Button("Reset") {
                            isFilteringByDate = false
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                }
                
                Divider()
                
                // Legend / Toggles
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $showApplications) {
                        HStack {
                            Circle().fill(Color.blue).frame(width: 8, height: 8)
                            Text("Applications").font(.subheadline)
                        }
                    }
                    .toggleStyle(.checkbox)
                    
                    Toggle(isOn: $showOAs) {
                        HStack {
                            Circle().fill(Color.purple).frame(width: 8, height: 8)
                            Text("OAs").font(.subheadline)
                        }
                    }
                    .toggleStyle(.checkbox)
                    
                    Toggle(isOn: $showInterviews) {
                        HStack {
                            Circle().fill(Color.orange).frame(width: 8, height: 8)
                            Text("Interviews").font(.subheadline)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
                
                Spacer()
            }
            .frame(width: 170)
            
            // Chart Section
            Chart {
                if showApplications {
                    ForEach(timeData, id: \.weekStart) { item in
                        LineMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.applications),
                            series: .value("Metric", "Applications")
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.monotone)
                        
                        AreaMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            yStart: .value("Count", 0),
                            yEnd: .value("Count", item.applications),
                            series: .value("Metric", "Applications")
                        )
                        .foregroundStyle(LinearGradient(colors: [Color.blue.opacity(0.2), Color.clear], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.monotone)
                    }
                }
                
                if showOAs {
                    ForEach(timeData, id: \.weekStart) { item in
                        LineMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.oas),
                            series: .value("Metric", "OAs")
                        )
                        .foregroundStyle(Color.purple)
                        .interpolationMethod(.monotone)
                        
                        AreaMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            yStart: .value("Count", 0),
                            yEnd: .value("Count", item.oas),
                            series: .value("Metric", "OAs")
                        )
                        .foregroundStyle(LinearGradient(colors: [Color.purple.opacity(0.2), Color.clear], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.monotone)
                    }
                }
                
                if showInterviews {
                    ForEach(timeData, id: \.weekStart) { item in
                        LineMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.interviews),
                            series: .value("Metric", "Interviews")
                        )
                        .foregroundStyle(Color.orange)
                        .interpolationMethod(.monotone)
                        
                        AreaMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            yStart: .value("Count", 0),
                            yEnd: .value("Count", item.interviews),
                            series: .value("Metric", "Interviews")
                        )
                        .foregroundStyle(LinearGradient(colors: [Color.orange.opacity(0.2), Color.clear], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.monotone)
                    }
                }
                
                if let hoveredDate = hoveredDate {
                    RuleMark(x: .value("Hover", hoveredDate, unit: .weekOfYear))
                        .foregroundStyle(Color.gray.opacity(0.5))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.gray.opacity(0.25))
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(.caption2)
                }
            }
            .chartXSelection(value: $hoveredDate)
            .frame(minHeight: 280) // Maximally tall
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 2)
        .onChange(of: isFilteringByDate) { _ in loadData() }
        .onChange(of: startDate) { _ in loadData() }
        .onChange(of: endDate) { _ in loadData() }
        .onAppear { loadData() }
    }
    
    private func loadData() {
        do {
            let fetchStart = isFilteringByDate ? startDate : nil
            let fetchEnd = isFilteringByDate ? endDate : nil
            timeData = try metricsService.fetchTimeSeriesData(startDate: fetchStart, endDate: fetchEnd)
        } catch {
            print("Failed to load time series data: \(error)")
        }
    }
}
