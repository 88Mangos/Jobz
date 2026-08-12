import SwiftUI
import UniformTypeIdentifiers
import GRDB

struct ApplicationTableView: View {
    @State private var applications: [JobApplication] = []
    private let applicationService = ApplicationService()
    
    @State private var isImporting = false
    @State private var selection = Set<JobApplication.ID>()
    
    @State private var csvError: String? = nil
    @State private var showCSVError = false
    @State private var showDeleteConfirmation = false
    @State private var sortOrder = [KeyPathComparator(\JobApplication.companyName)]
    @State private var isEditing = false
    
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
                    if isEditing {
                        TextField("Company", text: Binding(
                            get: { app.companyName },
                            set: { newValue in updateApplication(app, newCompanyName: newValue) }
                        ))
                    } else {
                        Text(app.companyName)
                    }
                }
                TableColumn("Role", value: \.role) { app in
                    if isEditing {
                        TextField("Role", text: Binding(
                            get: { app.role },
                            set: { newValue in updateApplication(app, newRole: newValue) }
                        ))
                    } else {
                        Text(app.role)
                    }
                }
                TableColumn("Role Notes", value: \.sortRoleExtraNotes) { app in
                    if isEditing {
                        TextField("Role Notes", text: Binding(
                            get: { app.roleExtraNotes ?? "" },
                            set: { newValue in updateApplication(app, newRoleExtraNotes: newValue) }
                        ))
                    } else {
                        Text(app.roleExtraNotes ?? "")
                    }
                }
                TableColumn("Duration", value: \.sortDuration) { app in
                    if isEditing {
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
                    } else {
                        Text(app.duration ?? "")
                    }
                }
                TableColumn("Season", value: \.sortSeason) { app in
                    if isEditing {
                        TextField("Season", text: Binding(
                            get: { app.season ?? "" },
                            set: { newValue in updateApplication(app, newSeason: newValue) }
                        ))
                    } else {
                        Text(app.season ?? "")
                    }
                }
                TableColumn("Location", value: \.sortLocation) { app in
                    if isEditing {
                        TextField("Location", text: Binding(
                            get: { app.location ?? "" },
                            set: { newValue in updateApplication(app, newLocation: newValue) }
                        ))
                    } else {
                        Text(app.location ?? "")
                    }
                }
                TableColumn("Notes", value: \.sortNotes) { app in
                    if isEditing {
                        TextField("Notes", text: Binding(
                            get: { app.notes ?? "" },
                            set: { newValue in updateApplication(app, newNotes: newValue) }
                        ))
                    } else {
                        Text(app.notes ?? "")
                    }
                }
            }
        }
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Toggle(isOn: $isEditing) {
                    Label("Edit Mode: \(isEditing ? "On" : "Off")", systemImage: isEditing ? "pencil.circle.fill" : "pencil.circle")
                }
                .toggleStyle(.button)
                .labelStyle(.titleAndIcon)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showDeleteConfirmation = true }) {
                    Label("Delete Selected", systemImage: "trash")
                }
                .disabled(selection.isEmpty || !isEditing)
                .labelStyle(.titleAndIcon)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isImporting = true }) {
                    Label("Import CSV", systemImage: "square.and.arrow.down")
                }
                .disabled(!isEditing)
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
    
    private func updateApplication(_ app: JobApplication, newCompanyName: String? = nil, newRole: String? = nil, newRoleExtraNotes: String? = nil, newDuration: String? = nil, newSeason: String? = nil, newLocation: String? = nil, newNotes: String? = nil) {
        do {
            var updatedApp = app
            if let companyName = newCompanyName { updatedApp.companyName = companyName }
            if let role = newRole { updatedApp.role = role }
            if let roleExtraNotes = newRoleExtraNotes { updatedApp.roleExtraNotes = roleExtraNotes.isEmpty ? nil : roleExtraNotes }
            if let duration = newDuration { updatedApp.duration = duration.isEmpty ? nil : duration }
            if let season = newSeason { updatedApp.season = season.isEmpty ? nil : season }
            if let location = newLocation { updatedApp.location = location.isEmpty ? nil : location }
            if let notes = newNotes { updatedApp.notes = notes.isEmpty ? nil : notes }
            
            try applicationService.dbQueue.write { db in
                try updatedApp.update(db)
            }
            loadApplications()
        } catch {
            print("Error updating application: \(error)")
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
