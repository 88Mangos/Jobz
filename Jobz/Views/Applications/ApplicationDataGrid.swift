import SwiftUI
import UniformTypeIdentifiers
import GRDB

struct ApplicationDataGrid: View {
    @Binding var applications: [ApplicationStatusRecord]
    var onRefresh: () -> Void
    private let applicationService = ApplicationService()
    
    // Quick Add State (Commented out per user request)
    /*
    @State private var newCompanyName = ""
    @State private var newRole = ""
    @State private var newLocation = ""
    */
    
    @State private var isImporting = false
    @State private var selection = Set<ApplicationStatusRecord.ID>()
    
    @State private var csvError: String? = nil
    @State private var showCSVError = false
    @State private var showDeleteConfirmation = false
    @State private var sortOrder = [KeyPathComparator(\ApplicationStatusRecord.companyName)]
    
    var sortedApplications: [ApplicationStatusRecord] {
        applications.sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Table(sortedApplications, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("application_id", value: \.applicationId) { app in
                    Text("\(app.applicationId)")
                }
                TableColumn("company_name", value: \.companyName) { app in
                    TextField("Company", text: Binding(
                        get: { app.companyName },
                        set: { newValue in updateApplication(app, newCompanyName: newValue) }
                    ))
                }
                TableColumn("role", value: \.role) { app in
                    TextField("Role", text: Binding(
                        get: { app.role },
                        set: { newValue in updateApplication(app, newRole: newValue) }
                    ))
                }
                TableColumn("role_extra_notes", value: \.sortRoleExtraNotes) { app in
                    TextField("Role Notes", text: Binding(
                        get: { app.roleExtraNotes ?? "" },
                        set: { newValue in updateApplication(app, newRoleExtraNotes: newValue) }
                    ))
                }
                TableColumn("duration", value: \.sortDuration) { app in
                    Picker("", selection: Binding(
                        get: { app.duration ?? "" },
                        set: { newValue in updateApplication(app, newDuration: newValue) }
                    )) {
                        Text("").tag("")
                        Text("Full-time").tag("Full-time")
                        Text("Part-time").tag("Part-time")
                        Text("Internship").tag("Internship")
                        Text("Contract").tag("Contract")
                        Text("Co-op").tag("Co-op")
                    }
                    .labelsHidden()
                }
                TableColumn("season", value: \.sortSeason) { app in
                    TextField("Season", text: Binding(
                        get: { app.season ?? "" },
                        set: { newValue in updateApplication(app, newSeason: newValue) }
                    ))
                }
                TableColumn("location", value: \.sortLocation) { app in
                    TextField("Location", text: Binding(
                        get: { app.location ?? "" },
                        set: { newValue in updateApplication(app, newLocation: newValue) }
                    ))
                }
                TableColumn("notes", value: \.sortNotes) { app in
                    TextField("Notes", text: Binding(
                        get: { app.notes ?? "" },
                        set: { newValue in updateApplication(app, newNotes: newValue) }
                    ))
                }
            }
            
            // Quick Add Row (Commented out)
            /*
            Divider()
            HStack {
                TextField("New Company", text: $newCompanyName)
                    .textFieldStyle(.roundedBorder)
                TextField("New Role", text: $newRole)
                    .textFieldStyle(.roundedBorder)
                TextField("Location (Optional)", text: $newLocation)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    quickAdd()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(newCompanyName.isEmpty || newRole.isEmpty)
                
                Button(action: { isImporting = true }) {
                    Label("CSV Import", systemImage: "square.and.arrow.down")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            */
        }
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
    
    private func updateApplication(_ record: ApplicationStatusRecord, newCompanyName: String? = nil, newRole: String? = nil, newRoleExtraNotes: String? = nil, newDuration: String? = nil, newSeason: String? = nil, newLocation: String? = nil, newNotes: String? = nil) {
        do {
            guard var app = try applicationService.fetchApplication(id: record.applicationId) else { return }
            
            if let company = newCompanyName { app.companyName = company }
            if let role = newRole { app.role = role }
            if let location = newLocation { app.location = location }
            if let roleExtraNotes = newRoleExtraNotes { app.roleExtraNotes = roleExtraNotes }
            if let duration = newDuration { app.duration = duration }
            if let season = newSeason { app.season = season }
            if let notes = newNotes { app.notes = notes }
            
            try applicationService.dbQueue.write { db in
                try app.update(db)
            }
            onRefresh()
        } catch {
            print("Error updating application: \(error)")
        }
    }
    
    /*
    private func quickAdd() {
        var newApp = JobApplication(
            companyName: newCompanyName,
            role: newRole,
            location: newLocation.isEmpty ? nil : newLocation
        )
        do {
            try applicationService.createApplication(&newApp)
            newCompanyName = ""
            newRole = ""
            newLocation = ""
            onRefresh()
        } catch {
            print("Error saving quick add: \(error)")
        }
    }
    */
    
    private func deleteSelected() {
        do {
            try applicationService.deleteApplications(ids: selection)
            selection.removeAll()
            onRefresh()
        } catch {
            print("Error deleting applications: \(error)")
        }
    }
    
    private func importCSV(url: URL) {
        do {
            try CSVImporter.importApplications(from: url, using: applicationService)
            onRefresh()
        } catch let error as LocalizedError {
            csvError = error.errorDescription
            showCSVError = true
        } catch {
            csvError = error.localizedDescription
            showCSVError = true
        }
    }
}
