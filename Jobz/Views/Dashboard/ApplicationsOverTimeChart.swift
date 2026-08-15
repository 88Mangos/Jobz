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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Metrics Over Time")
                    .font(.headline)
                
                Spacer()
            }
            
            // Date Picker
            HStack {
                Toggle("Filter by Date", isOn: $isFilteringByDate)
                    .toggleStyle(.switch)
                    .labelsHidden()
                Text("Filter by Date")
                
                if isFilteringByDate {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                    Text("to")
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                    
                    Button("Reset") {
                        isFilteringByDate = false
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            HStack(alignment: .top, spacing: 16) {
                Chart {
                ForEach(timeData, id: \.weekStart) { item in
                    if showApplications {
                        LineMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.applications)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.monotone)
                        
                        AreaMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.applications)
                        )
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.monotone)
                    }
                    
                    if showInterviews {
                        LineMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.interviews)
                        )
                        .foregroundStyle(Color.orange)
                        .interpolationMethod(.monotone)
                        
                        AreaMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.interviews)
                        )
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.monotone)
                    }
                    
                    if showOAs {
                        LineMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.oas)
                        )
                        .foregroundStyle(Color.purple)
                        .interpolationMethod(.monotone)
                        
                        AreaMark(
                            x: .value("Date", item.weekStart, unit: .weekOfYear),
                            y: .value("Count", item.oas)
                        )
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.monotone)
                    }
                }
                
                if let hoveredDate = hoveredDate {
                    RuleMark(x: .value("Hover", hoveredDate, unit: .weekOfYear))
                        .foregroundStyle(Color.gray.opacity(0.5))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    if let hoveredDate = hoveredDate,
                       let data = timeData.first(where: { Calendar.current.isDate($0.weekStart, equalTo: hoveredDate, toGranularity: .weekOfYear) }),
                       let xPosition = proxy.position(forX: hoveredDate) {
                        
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
                        .position(x: min(max(xPosition, 60), geometry.size.width - 60), y: 40)
                    }
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
            .chartLegend(.hidden)
            .frame(height: 240)
            
            // Vertical Legend with Checkboxes
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $showApplications) {
                    HStack {
                        Circle().fill(Color.blue).frame(width: 8, height: 8)
                        Text("Applications").font(.subheadline)
                    }
                }
                .toggleStyle(.checkbox)
                .tint(.blue)
                
                Toggle(isOn: $showInterviews) {
                    HStack {
                        Circle().fill(Color.orange).frame(width: 8, height: 8)
                        Text("Interviews").font(.subheadline)
                    }
                }
                .toggleStyle(.checkbox)
                .tint(.orange)
                
                Toggle(isOn: $showOAs) {
                    HStack {
                        Circle().fill(Color.purple).frame(width: 8, height: 8)
                        Text("OAs").font(.subheadline)
                    }
                }
                .toggleStyle(.checkbox)
                .tint(.purple)
            }
            .padding(.leading, 8)
            .padding(.top, 24)
            }
            .onChange(of: isFilteringByDate) { _ in loadData() }
            .onChange(of: startDate) { _ in loadData() }
            .onChange(of: endDate) { _ in loadData() }
            .onAppear { loadData() }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 2)
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
