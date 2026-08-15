import SwiftUI

struct SummaryTableView: View {
    @State private var applications: [ApplicationStatusRecord] = []
    private let applicationService = ApplicationService()
    
    @State private var selection: ApplicationStatusRecord.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\ApplicationStatusRecord.companyName)]
    @State private var isFiltering = false
    
    @State private var filterCompanies = Set<String>()
    @State private var filterRoles = Set<String>()
    @State private var filterStatuses = Set<String>()
    
    @State private var showingInspector = false
    
    var uniqueCompanies: [String] { Set(applications.map { $0.companyName }).sorted() }
    var uniqueRoles: [String] { Set(applications.map { $0.role }).sorted() }
    var uniqueStatuses: [String] { Set(applications.map { $0.statusRaw }).sorted() }
    
    var sortedApplications: [ApplicationStatusRecord] {
        var filtered = applications
        if isFiltering {
            if !filterCompanies.isEmpty {
                filtered = filtered.filter { filterCompanies.contains($0.companyName) }
            }
            if !filterRoles.isEmpty {
                filtered = filtered.filter { filterRoles.contains($0.role) }
            }
            if !filterStatuses.isEmpty {
                filtered = filtered.filter { filterStatuses.contains($0.statusRaw) }
            }
        }
        return filtered.sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack(spacing: 0) {
                if isFiltering {
                    HStack(spacing: 16) {
                        MultiSelectMenu(title: "Company", options: uniqueCompanies, selectedOptions: $filterCompanies)
                        MultiSelectMenu(title: "Role", options: uniqueRoles, selectedOptions: $filterRoles)
                        MultiSelectMenu(title: "Status", options: uniqueStatuses, selectedOptions: $filterStatuses)
                        
                        Spacer()
                        
                        Button("Clear Filters") {
                            filterCompanies.removeAll()
                            filterRoles.removeAll()
                            filterStatuses.removeAll()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                        .disabled(filterCompanies.isEmpty && filterRoles.isEmpty && filterStatuses.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    Divider()
                }
                
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
            } // End Table
            } // End VStack
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Toggle(isOn: $isFiltering) {
                        Label("Filter: \(isFiltering ? "On" : "Off")", systemImage: isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .toggleStyle(.button)
                    .labelStyle(.titleAndIcon)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { exportCSV() }) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    .labelStyle(.titleAndIcon)
                }
        }
        .inspector(isPresented: $showingInspector) {
            if let selectedId = selection {
                SummaryDetailView(applicationId: selectedId)
            } else {
                Text("Select an application to view details")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .onChange(of: selection) { _, newValue in
            showingInspector = newValue != nil
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
