import SwiftUI

struct SummaryTableView: View {
    @State private var applications: [ApplicationStatusRecord] = []
    private let applicationService = ApplicationService()
    
    @State private var selection: ApplicationStatusRecord.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\ApplicationStatusRecord.companyName)]
    
    var sortedApplications: [ApplicationStatusRecord] {
        applications.sorted(using: sortOrder)
    }
    
    var body: some View {
        NavigationSplitView {
            Table(sortedApplications, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("Company", value: \.companyName)
                TableColumn("Role", value: \.role)
                TableColumn("Status", value: \.statusRaw)
                TableColumn("Interviews", value: \.numInterviews) { app in
                    Text("\(app.numInterviews)")
                }
                TableColumn("Assessments", value: \.numOAs) { app in
                    Text("\(app.numOAs)")
                }
                TableColumn("Applied At", value: \.sortAppliedAt) { app in
                    if let date = app.appliedAt {
                        Text(date, style: .date)
                    } else {
                        Text("-")
                    }
                }
                TableColumn("Last Updated", value: \.sortLastUpdated) { app in
                    if let date = app.lastUpdated {
                        Text(date, style: .date)
                    } else {
                        Text("-")
                    }
                }
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { exportCSV() }) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    .labelStyle(.titleAndIcon)
                }
            }
        } detail: {
            if let selectedId = selection {
                SummaryDetailView(applicationId: selectedId)
            } else {
                Text("Select an application to view timeline")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadApplications()
        }
    }
    
    private func loadApplications() {
        do {
            applications = try applicationService.fetchApplications()
        } catch {
            print("Error loading applications: \(error)")
        }
    }
    
    private func exportCSV() {
        let headers = ["application_id", "company_name", "role", "role_extra_notes", "duration", "location", "season", "notes", "num_interviews", "num_oas", "applied_at", "last_updated", "status"]
        
        let formatter = ISO8601DateFormatter()
        let rows = applications.map { app in
            [
                String(app.applicationId),
                app.companyName,
                app.role,
                app.roleExtraNotes ?? "",
                app.duration ?? "",
                app.location ?? "",
                app.season ?? "",
                app.notes ?? "",
                String(app.numInterviews),
                String(app.numOAs),
                app.appliedAt.map { formatter.string(from: $0) } ?? "",
                app.lastUpdated.map { formatter.string(from: $0) } ?? "",
                app.statusRaw
            ]
        }
        
        let csvString = CSVExporter.generateCSV(headers: headers, rows: rows)
        let filename = CSVExporter.generateFilename(prefix: "Summary")
        CSVExporter.exportToFile(csvString: csvString, defaultFilename: filename)
    }
}
