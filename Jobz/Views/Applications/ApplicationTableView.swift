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
    @State private var isFiltering = false
    
    @State private var filterCompanies = Set<String>()
    @State private var filterRoles = Set<String>()
    @State private var filterSeasons = Set<String>()
    @State private var filterLocations = Set<String>()
    
    @State private var newAppId = ""
    @State private var newAppCompany = ""
    @State private var newAppRole = ""
    @State private var newAppSeason = ""
    @State private var newAppLocation: String? = nil
    
    var uniqueCompanies: [String] { Set(applications.map { $0.companyName }).sorted() }
    var uniqueRoles: [String] { Set(applications.map { $0.role }).sorted() }
    var uniqueSeasons: [String] { Set(applications.map { $0.season ?? "" }).sorted() }
    var uniqueLocations: [String] { Set(applications.map { $0.location ?? "" }).sorted() }
    
    var sortedApplications: [JobApplication] {
        var filtered = applications
        if isFiltering {
            if !filterCompanies.isEmpty {
                filtered = filtered.filter { filterCompanies.contains($0.companyName) }
            }
            if !filterRoles.isEmpty {
                filtered = filtered.filter { filterRoles.contains($0.role) }
            }
            if !filterSeasons.isEmpty {
                filtered = filtered.filter { filterSeasons.contains($0.season ?? "") }
            }
            if !filterLocations.isEmpty {
                filtered = filtered.filter { filterLocations.contains($0.location ?? "") }
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
                    MultiSelectMenu(title: "Season", options: uniqueSeasons, selectedOptions: $filterSeasons)
                    MultiSelectMenu(title: "Location", options: uniqueLocations, selectedOptions: $filterLocations)
                    
                    Spacer()
                    
                    Button("Clear Filters") {
                        filterCompanies.removeAll()
                        filterRoles.removeAll()
                        filterSeasons.removeAll()
                        filterLocations.removeAll()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .disabled(filterCompanies.isEmpty && filterRoles.isEmpty && filterSeasons.isEmpty && filterLocations.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                Divider()
            }
            
            if isEditing {
                HStack {
                    TextField("ID (opt)", text: $newAppId)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    TextField("Company", text: $newAppCompany)
                        .textFieldStyle(.roundedBorder)
                    TextField("Role", text: $newAppRole)
                        .textFieldStyle(.roundedBorder)
                    Picker("", selection: $newAppSeason) {
                        Text("Season").tag("")
                        Text("Summer 2025").tag("Summer 2025")
                        Text("Fall 2025").tag("Fall 2025")
                        Text("Spring 2026").tag("Spring 2026")
                        Text("Summer 2026").tag("Summer 2026")
                        Text("Fall 2026").tag("Fall 2026")
                        Text("Winter 2027").tag("Winter 2027")
                        Text("Spring 2027").tag("Spring 2027")
                        Text("Summer 2027").tag("Summer 2027")
                        Text("Fall 2027").tag("Fall 2027")
                    }
                    .labelsHidden()
                    .frame(width: 120)
                    MultiSelectLocationMenu(selectedLocationsStr: $newAppLocation)
                        .frame(width: 150)
                    Button("Add") {
                        addApplication()
                    }
                    .disabled(newAppCompany.isEmpty || newAppRole.isEmpty)
                }
                .padding()
            }
            
            Table(sortedApplications, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("ID", value: \.sortId) { app in
                    if isEditing {
                        TextField("ID", value: Binding(
                            get: { app.id },
                            set: { newValue in updateApplication(app, newId: newValue) }
                        ), format: .number)
                    } else {
                        Text("\(app.id ?? 0)")
                    }
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
                        Picker("", selection: Binding(
                            get: { app.season ?? "" },
                            set: { newValue in updateApplication(app, newSeason: newValue.isEmpty ? nil : newValue) }
                        )) {
                            Text("None").tag("")
                            Text("Summer 2025").tag("Summer 2025")
                            Text("Fall 2025").tag("Fall 2025")
                            Text("Spring 2026").tag("Spring 2026")
                            Text("Summer 2026").tag("Summer 2026")
                            Text("Fall 2026").tag("Fall 2026")
                            Text("Winter 2027").tag("Winter 2027")
                            Text("Spring 2027").tag("Spring 2027")
                            Text("Summer 2027").tag("Summer 2027")
                            Text("Fall 2027").tag("Fall 2027")
                        }
                        .labelsHidden()
                    } else {
                        Text(app.season ?? "")
                    }
                }
                TableColumn("Location", value: \.sortLocation) { app in
                    if isEditing {
                        MultiSelectLocationMenu(selectedLocationsStr: Binding(
                            get: { app.location },
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
                Toggle(isOn: $isFiltering) {
                    Label("Filter: \(isFiltering ? "On" : "Off")", systemImage: isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .toggleStyle(.button)
                .labelStyle(.titleAndIcon)
            }
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
            ToolbarItem(placement: .primaryAction) {
                Button(action: { exportCSV() }) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
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
    
    private func addApplication() {
        var newApp = JobApplication(
            id: newAppId.isEmpty ? nil : Int64(newAppId),
            companyName: newAppCompany,
            role: newAppRole,
            season: newAppSeason.isEmpty ? nil : newAppSeason,
            location: newAppLocation
        )
        do {
            try applicationService.createApplication(&newApp)
            newAppId = ""
            newAppCompany = ""
            newAppRole = ""
            newAppSeason = ""
            newAppLocation = nil
            loadApplications()
        } catch {
            print("Error adding application: \(error)")
        }
    }
    
    private func updateApplication(_ app: JobApplication, newId: Int64? = nil, newCompanyName: String? = nil, newRole: String? = nil, newRoleExtraNotes: String? = nil, newDuration: String? = nil, newSeason: String? = nil, newLocation: String? = nil, newNotes: String? = nil) {
        do {
            if let newId = newId, let oldId = app.id, newId != oldId {
                try applicationService.updateApplicationId(oldId: oldId, newId: newId)
            }
            
            var updatedApp = app
            if let newId = newId { updatedApp.id = newId }
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
    
    private func exportCSV() {
        let headers = ["application_id", "company_name", "role", "role_extra_notes", "duration", "season", "location", "notes"]
        let rows = applications.map { app in
            [
                app.id.map(String.init) ?? "",
                app.companyName,
                app.role,
                app.roleExtraNotes ?? "",
                app.duration ?? "",
                app.season ?? "",
                app.location ?? "",
                app.notes ?? ""
            ]
        }
        let csvString = CSVExporter.generateCSV(headers: headers, rows: rows)
        let filename = CSVExporter.generateFilename(prefix: "Applications")
        CSVExporter.exportToFile(csvString: csvString, defaultFilename: filename)
    }
}
