import SwiftUI
import UniformTypeIdentifiers
import GRDB

struct ApplicationDataGrid: View {
    @Binding var applications: [ApplicationStatusRecord]
    var onRefresh: () -> Void
    private let applicationService = ApplicationService()
    
    // Quick Add State
    @State private var newCompanyName = ""
    @State private var newRole = ""
    @State private var newLocation = ""
    
    @State private var isImporting = false
    
    var body: some View {
        VStack(spacing: 0) {
            Table(applications) {
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
            
            Divider()
            
            // Quick Add Row
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
                print("Error selecting file: \\(error.localizedDescription)")
            }
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
            print("Error updating application: \\(error)")
        }
    }
    
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
            print("Error saving quick add: \\(error)")
        }
    }
    
    private func importCSV(url: URL) {
        // We will implement CSVImporter and call it here.
        do {
            try CSVImporter.importApplications(from: url, using: applicationService)
            onRefresh()
        } catch {
            print("Error importing CSV: \\(error)")
        }
    }
}
