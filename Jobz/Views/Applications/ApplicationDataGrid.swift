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
    
    var body: some View {
        VStack(spacing: 0) {
            Table(applications, selection: $selection) {
                TableColumn("Company") { app in
                    TextField("Company", text: Binding(
                        get: { app.companyName },
                        set: { newValue in updateApplication(app, newCompanyName: newValue) }
                    ))
                }
                TableColumn("Role") { app in
                    TextField("Role", text: Binding(
                        get: { app.role },
                        set: { newValue in updateApplication(app, newRole: newValue) }
                    ))
                }
                TableColumn("Location") { app in
                    TextField("Location", text: Binding(
                        get: { app.location ?? "" },
                        set: { newValue in updateApplication(app, newLocation: newValue) }
                    ))
                }
                TableColumn("Status") { app in
                    StatusBadgeView(status: app.status)
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
    
    private func updateApplication(_ record: ApplicationStatusRecord, newCompanyName: String? = nil, newRole: String? = nil, newLocation: String? = nil) {
        do {
            guard var app = try applicationService.fetchApplication(id: record.applicationId) else { return }
            
            if let company = newCompanyName { app.companyName = company }
            if let role = newRole { app.role = role }
            if let location = newLocation { app.location = location }
            
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
