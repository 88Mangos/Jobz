import SwiftUI
import Charts

struct ApplicationsOverTimeChart: View {
    let metricsService = MetricsService()
    
    @State private var timeData: [MetricsService.TimeSeriesDataPoint] = []
    
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    
    @State private var showApplications: Bool = true
    @State private var showInterviews: Bool = true
    @State private var showOAs: Bool = true
    
    @State private var hoveredDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Metrics Over Time")
                    .font(.headline)
                
                Spacer()
                
                // Toggles
                Toggle("Applications", isOn: $showApplications)
                    .toggleStyle(.checkbox)
                    .tint(.blue)
                Toggle("Interviews", isOn: $showInterviews)
                    .toggleStyle(.checkbox)
                    .tint(.orange)
                Toggle("OAs", isOn: $showOAs)
                    .toggleStyle(.checkbox)
                    .tint(.purple)
            }
            
            // Date Picker
            HStack {
                DatePicker("From", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                Text("to")
                DatePicker("To", selection: $endDate, displayedComponents: .date)
                    .labelsHidden()
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            Chart {
                ForEach(timeData, id: \.weekStart) { item in
                    if showApplications {
                        LineMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.applications),
                            series: .value("Metric", "Applications")
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.monotone)
                        
                        AreaMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.applications),
                            series: .value("Metric", "Applications")
                        )
                        .foregroundStyle(Color.blue.opacity(0.1))
                    }
                    
                    if showInterviews {
                        LineMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.interviews),
                            series: .value("Metric", "Interviews")
                        )
                        .foregroundStyle(Color.orange)
                        .interpolationMethod(.monotone)
                    }
                    
                    if showOAs {
                        LineMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.oas),
                            series: .value("Metric", "OAs")
                        )
                        .foregroundStyle(Color.purple)
                        .interpolationMethod(.monotone)
                    }
                }
                
                if let hoveredDate = hoveredDate, let data = timeData.first(where: { Calendar.current.isDate($0.weekStart, equalTo: hoveredDate, toGranularity: .weekOfYear) }) {
                    RuleMark(x: .value("Hover", hoveredDate, unit: .weekOfYear))
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .annotation(position: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(hoveredDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption.bold())
                                if showApplications {
                                    Text("Applications: \(data.applications)").font(.caption).foregroundColor(.blue)
                                }
                                if showInterviews {
                                    Text("Interviews: \(data.interviews)").font(.caption).foregroundColor(.orange)
                                }
                                if showOAs {
                                    Text("OAs: \(data.oas)").font(.caption).foregroundColor(.purple)
                                }
                            }
                            .padding(8)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                        }
                }
            }
            .chartXScale(domain: startDate...endDate)
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
            .frame(height: 240)
            .onChange(of: startDate) { _ in loadData() }
            .onChange(of: endDate) { _ in loadData() }
            .onAppear { loadData() }
            
            // SQLite Tooltip
            Text(sqliteTooltip)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private func loadData() {
        do {
            timeData = try metricsService.fetchTimeSeriesData(startDate: startDate, endDate: endDate)
        } catch {
            print("Failed to load time series data: \(error)")
        }
    }
    
    private var sqliteTooltip: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)
        return "SELECT date(created_at, '-' || strftime('%w', created_at) || ' days') as week_start, ... FROM ledger WHERE type IN ('Applied', 'Interview', 'Online Assessment') AND created_at >= '\(startStr)' AND created_at <= '\(endStr)' GROUP BY week_start"
    }
}
