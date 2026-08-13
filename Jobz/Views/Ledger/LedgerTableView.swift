import SwiftUI
import GRDB
import UniformTypeIdentifiers

struct LedgerTableView: View {
    @State private var entries: [LedgerEntry] = []
    @State private var applications: [ApplicationStatusRecord] = []
    private let applicationService = ApplicationService()
    
    @State private var selectedApplicationId: Int64? = nil
    @State private var isGrouped = false
    
    @State private var isImporting = false
    @State private var selection = Set<Int64>()
    
    @State private var csvError: String? = nil
    @State private var showCSVError = false
    @State private var showDeleteConfirmation = false
    @State private var sortOrder = [KeyPathComparator(\LedgerTableRow.entry.createdAt, order: .reverse)]
    @State private var isEditing = false
    
    @State private var newLedgerAppId = ""
    @State private var newLedgerType: EventType = .applied
    @State private var newLedgerNotes = ""
    @State private var newLedgerCreatedAt = Date()
    @State private var newLedgerTimezone: String = {
        let currentId = TimeZone.current.identifier
        let supported = ["America/New_York", "America/Chicago", "America/Los_Angeles", "UTC"]
        return supported.contains(currentId) ? currentId : "America/New_York"
    }()
    
    private var supportedTimezones: [String] {
        var zones = ["America/New_York", "America/Chicago", "America/Los_Angeles", "UTC"]
        let current = TimeZone.current.identifier
        if !zones.contains(current) {
            zones.insert(current, at: 0)
        }
        return zones
    }
    
    var filteredAndSortedEntries: [LedgerEntry] {
        var result = entries
        
        if let appId = selectedApplicationId {
            result = result.filter { $0.applicationId == appId }
        }
        
        if isGrouped {
            result.sort { 
                if $0.applicationId == $1.applicationId {
                    return $0.createdAt > $1.createdAt
                }
                return $0.applicationId < $1.applicationId
            }
        }
        
        return result
    }
    
    struct LedgerTableRow: Identifiable {
        let id: Int64
        var entry: LedgerEntry
    }
    
    var tableRows: [LedgerTableRow] {
        var rows = filteredAndSortedEntries.map { LedgerTableRow(id: $0.id, entry: $0) }
        if !isGrouped {
            rows.sort(using: sortOrder)
        }
        return rows
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar area for grouping/filtering
            HStack {
                Picker("Filter App", selection: $selectedApplicationId) {
                    Text("All Applications").tag(Int64?.none)
                    ForEach(applications) { app in
                        Text(app.companyName).tag(Int64?.some(app.applicationId))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 250)
                
                Toggle("Group by App", isOn: $isGrouped)
                    .toggleStyle(.checkbox)
                
                Spacer()
            }
            .padding()
            
            if isEditing {
                HStack {
                    TextField("App ID", text: $newLedgerAppId)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    
                    
                    Text(Int64(newLedgerAppId) != nil ? appDetails(for: Int64(newLedgerAppId)!) : "Enter valid ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 180, alignment: .leading)
                        .lineLimit(1)
                        
                    DatePicker("", selection: $newLedgerCreatedAt, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        
                    Picker("Timezone", selection: $newLedgerTimezone) {
                        ForEach(supportedTimezones, id: \.self) { tzId in
                            Text(TimeZone.formattedLabel(for: tzId, date: newLedgerCreatedAt)).tag(tzId)
                        }
                    }
                    .labelsHidden()
                        
                    Picker("Type", selection: $newLedgerType) {
                        ForEach(EventType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .labelsHidden()
                    TextField("Notes", text: $newLedgerNotes)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        addLedgerEntry()
                    }
                    .disabled(newLedgerAppId.isEmpty || Int64(newLedgerAppId) == nil)
                }
                .padding([.horizontal, .bottom])
            }
            
            Table(tableRows, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("ID", value: \.id) { row in
                    Text("\(row.id)")
                }
                .width(min: 30, max: 50)
                TableColumn("Created At", value: \.entry.createdAt) { row in
                    let entry = row.entry
                    if isEditing {
                        DatePicker("", selection: Binding(
                            get: { entry.createdAt },
                            set: { newValue in updateEntry(entry, newCreatedAt: newValue) }
                        ), displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                    } else {
                        Text(entry.createdAt, style: .date)
                        + Text(" ") +
                        Text(entry.createdAt, style: .time)
                    }
                }
                .width(min: 150, ideal: 180, max: 250)
                TableColumn("Timezone") { row in
                    let entry = row.entry
                    if isEditing {
                        Picker("", selection: Binding(
                            get: { entry.timezone ?? "America/New_York" },
                            set: { newValue in updateEntry(entry, newTimezone: newValue) }
                        )) {
                            ForEach(supportedTimezones, id: \.self) { tzId in
                                Text(TimeZone.formattedLabel(for: tzId, date: entry.createdAt)).tag(tzId)
                            }
                        }
                        .labelsHidden()
                    } else {
                        if let tzId = entry.timezone {
                            Text(TimeZone.formattedLabel(for: tzId, date: entry.createdAt))
                        } else {
                            Text("")
                        }
                    }
                }
                .width(min: 220, ideal: 250, max: 300)
                TableColumn("Type", value: \.entry.type.rawValue) { row in
                    let entry = row.entry
                    if isEditing {
                        Picker("", selection: Binding(
                            get: { entry.type },
                            set: { newValue in updateEntry(entry, newType: newValue) }
                        )) {
                            ForEach(EventType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .labelsHidden()
                    } else {
                        Text(entry.type.rawValue)
                    }
                }
                .width(min: 120, max: 150)
                TableColumn("Application", value: \.entry.applicationId) { row in
                    let entry = row.entry
                    if isEditing {
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("App ID", value: Binding(
                                get: { entry.applicationId },
                                set: { newValue in updateEntry(entry, newApplicationId: newValue) }
                            ), format: .number)
                            Text(appDetails(for: entry.applicationId))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.applicationId)")
                            Text(appDetails(for: entry.applicationId))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .width(min: 150, ideal: 200, max: 250)
                TableColumn("Notes", value: \.entry.sortUpdate) { row in
                    let entry = row.entry
                    if isEditing {
                        TextField("Notes", text: Binding(
                            get: { entry.update ?? "" },
                            set: { newValue in updateEntry(entry, newUpdate: newValue) }
                        ))
                    } else {
                        Text(entry.sortUpdate)
                            .lineLimit(1)
                    }
                }
            }
        }
        .navigationTitle("Ledger")
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
            ToolbarItem(placement: .primaryAction) {
                Button(action: { exportCSV() }) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                .labelStyle(.titleAndIcon)
            }
        }
        .onAppear {
            loadData()
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
            Text("Are you sure you want to delete \(selection.count) ledger entry(s)? This action cannot be undone.")
        }
        .alert(isPresented: $showCSVError) {
            Alert(
                title: Text("CSV Import Failed"),
                message: Text(csvError ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func loadData() {
        do {
            entries = try applicationService.fetchAllLedgerEntries()
            applications = try applicationService.fetchApplications()
        } catch {
            print("Error loading data: \(error)")
        }
    }
    
    private func addLedgerEntry() {
        guard let appId = Int64(newLedgerAppId) else { return }
        var newEntry = LedgerEntry(
            createdAt: newLedgerCreatedAt,
            type: newLedgerType,
            applicationId: appId,
            update: newLedgerNotes.isEmpty ? nil : newLedgerNotes,
            timezone: newLedgerTimezone
        )
        do {
            try applicationService.addLedgerEntry(&newEntry)
            newLedgerAppId = ""
            newLedgerType = .applied
            newLedgerNotes = ""
            newLedgerCreatedAt = Date()
            newLedgerTimezone = {
                let currentId = TimeZone.current.identifier
                let supported = ["America/New_York", "America/Chicago", "America/Los_Angeles", "UTC"]
                return supported.contains(currentId) ? currentId : "America/New_York"
            }()
            loadData()
        } catch {
            print("Error adding ledger entry: \(error)")
        }
    }
    
    private func updateEntry(_ entry: LedgerEntry, newType: EventType? = nil, newUpdate: String? = nil, newCreatedAt: Date? = nil, newApplicationId: Int64? = nil, newTimezone: String? = nil) {
        do {
            var updatedEntry = entry
            if let type = newType { updatedEntry.type = type }
            if let update = newUpdate { updatedEntry.update = update.isEmpty ? nil : update }
            if let createdAt = newCreatedAt { updatedEntry.createdAt = createdAt }
            if let applicationId = newApplicationId { updatedEntry.applicationId = applicationId }
            if let timezone = newTimezone { updatedEntry.timezone = timezone }
            
            try applicationService.dbQueue.write { db in
                try updatedEntry.update(db)
            }
            loadData()
        } catch {
            print("Error updating entry: \(error)")
        }
    }
    
    private func appName(for id: Int64) -> String {
        return applications.first { $0.applicationId == id }?.companyName ?? "Unknown"
    }
    
    private func appDetails(for id: Int64) -> String {
        if let app = applications.first(where: { $0.applicationId == id }) {
            return "\(app.companyName) - \(app.role)"
        }
        return "Unknown Application"
    }
    
    private func deleteSelected() {
        do {
            try applicationService.deleteLedgerEntries(ids: selection)
            selection.removeAll()
            loadData()
        } catch {
            print("Error deleting ledger entries: \(error)")
        }
    }
    
    private func importCSV(url: URL) {
        do {
            try CSVImporter.importLedger(from: url, using: applicationService)
            loadData()
        } catch let error as LocalizedError {
            csvError = error.errorDescription
            showCSVError = true
        } catch {
            csvError = error.localizedDescription
            showCSVError = true
        }
    }
    
    private func exportCSV() {
        let headers = ["ledger_id", "created_at", "type", "application_id", "update", "timezone"]
        
        let formatter = ISO8601DateFormatter()
        let rows = tableRows.map { row in
            let entry = row.entry
            return [
                String(entry.id),
                formatter.string(from: entry.createdAt),
                entry.type.rawValue,
                String(entry.applicationId),
                entry.update ?? "",
                entry.timezone ?? ""
            ]
        }
        
        let csvString = CSVExporter.generateCSV(headers: headers, rows: rows)
        let filename = CSVExporter.generateFilename(prefix: "Ledger")
        CSVExporter.exportToFile(csvString: csvString, defaultFilename: filename)
    }
}
