import SwiftUI

struct DashboardView: View {
    @State private var records: [ApplicationStatusRecord] = []
    private let metricsService = MetricsService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Dashboard")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    StatusBreakdownChart(records: records)
                    ApplicationsOverTimeChart(records: records)
                }
                
                HStack {
                    WeeklyGoalDonutChart(records: records)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
            }
            .padding()
        }
        .onAppear {
            loadMetrics()
        }
    }
    
    private func loadMetrics() {
        do {
            records = try metricsService.fetchAllStatusRecords()
        } catch {
            print("Failed to load metrics: \(error)")
        }
    }
}
