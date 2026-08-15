import SwiftUI

struct DashboardView: View {
    @State private var records: [ApplicationStatusRecord] = []
    private let metricsService = MetricsService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    StatusBreakdownChart(records: records)
                    WeeklyGoalDonutChart(records: records)
                }
                
                HStack {
                    ApplicationsOverTimeChart()
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
                
                HomeNotesCard()
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
