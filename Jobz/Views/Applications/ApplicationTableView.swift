import SwiftUI
import UniformTypeIdentifiers

struct ApplicationTableView: View {
    @State private var applications: [JobApplication] = []
    private let applicationService = ApplicationService()
    
    @State private var isImporting = false
    @State private var selection = Set<JobApplication.ID>()
    
    @State private var csvError: String? = nil
    @State private var showCSVError = false
    @State private var showDeleteConfirmation = false
    @State private var sortOrder = [KeyPathComparator(\JobApplication.companyName)]
    
    var sortedApplications: [JobApplication] {
        applications.sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Table(sortedApplications, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("ID", value: \.sortId) { app in
                    Text("\(app.id ?? 0)")
                }
                TableColumn("Company", value: \.companyName) { app in
                    Text(app.companyName)
                }
                TableColumn("Role", value: \.role) { app in
                    Text(app.role)
                }
                TableColumn("Role Notes", value: \.sortRoleExtraNotes) { app in
                    Text(app.roleExtraNotes ?? "")
                }
                TableColumn("Duration", value: \.sortDuration) { app in
                    Text(app.duration ?? "")
                }
                TableColumn("Season", value: \.sortSeason) { app in
                    Text(app.season ?? "")
                }
                TableColumn("Location", value: \.sortLocation) { app in
                    Text(app.location ?? "")
                }
                TableColumn("Notes", value: \.sortNotes) { app in
                    Text(app.notes ?? "")
                }
            }
        }
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showDeleteConfirmation = true }) {
                    Label("Delete Selected", systemImage: "trash")
                }
                .disabled(selection.isEmpty)
                .labelStyle(.titleAndIcon)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isImporting = true }) {
                    Label("Import CSV", systemImage: "square.and.arrow.down")
                }
                .labelStyle(.titleAndIcon)
            }
        }
        .onAppear {
            loadApplications()
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importCSV(url: url)
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteSelected() }
        } message: {
            Text("Are you sure you want to delete \(selection.count) application(s)? This action cannot be undone.")
        }
        .alert(isPresented: $showCSVError) {
            Alert(
                title: Text("CSV Import Failed"),
                message: Text(csvError ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func loadApplications() {
        do {
            applications = try applicationService.fetchRawApplications()
        } catch {
            print("Error loading applications: \(error)")
        }
    }
    
    private func deleteSelected() {
        do {
            let validIds = Set(selection.compactMap { $0 })
            try applicationService.deleteApplications(ids: validIds)
            selection.removeAll()
            loadApplications()
        } catch {
            print("Error deleting applications: \(error)")
        }
    }
    
    private func importCSV(url: URL) {
        do {
            try CSVImporter.importApplications(from: url, using: applicationService)
            loadApplications()
        } catch let error as LocalizedError {
            csvError = error.errorDescription
            showCSVError = true
        } catch {
            csvError = error.localizedDescription
            showCSVError = true
        }
    }
}
