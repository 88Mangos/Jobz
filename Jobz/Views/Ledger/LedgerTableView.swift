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
    @State private var selection = Set<LedgerEntry.ID>()
    
    @State private var csvError: String? = nil
    @State private var showCSVError = false
    @State private var showDeleteConfirmation = false
    @State private var sortOrder = [KeyPathComparator(\LedgerEntry.createdAt, order: .reverse)]
    @State private var isEditing = false
    
    @State private var newLedgerAppId = ""
    @State private var newLedgerType: EventType = .applied
    @State private var newLedgerNotes = ""
    
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
        } else {
            result.sort(using: sortOrder)
        }
        
        return result
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
                        .frame(width: 100)
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
            
            Table(filteredAndSortedEntries, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("ID", value: \.sortId) { entry in
                    Text("\(entry.id ?? 0)")
                }
                TableColumn("Created At", value: \.createdAt) { entry in
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
                TableColumn("Type", value: \.type.rawValue) { entry in
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
                TableColumn("App ID", value: \.applicationId) { entry in
                    if isEditing {
                        TextField("App ID", value: Binding(
                            get: { entry.applicationId },
                            set: { newValue in updateEntry(entry, newApplicationId: newValue) }
                        ), format: .number)
                    } else {
                        Text("\(entry.applicationId)")
                    }
                }
                TableColumn("Notes", value: \.sortUpdate) { entry in
                    if isEditing {
                        TextField("Notes", text: Binding(
                            get: { entry.update ?? "" },
                            set: { newValue in updateEntry(entry, newUpdate: newValue) }
                        ))
                    } else {
                        Text(entry.update ?? "")
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
            createdAt: Date(),
            type: newLedgerType,
            applicationId: appId,
            update: newLedgerNotes.isEmpty ? nil : newLedgerNotes
        )
        do {
            try applicationService.addLedgerEntry(&newEntry)
            newLedgerAppId = ""
            newLedgerType = .applied
            newLedgerNotes = ""
            loadData()
        } catch {
            print("Error adding ledger entry: \(error)")
        }
    }
    
    private func updateEntry(_ entry: LedgerEntry, newType: EventType? = nil, newUpdate: String? = nil, newCreatedAt: Date? = nil, newApplicationId: Int64? = nil) {
        do {
            var updatedEntry = entry
            if let type = newType { updatedEntry.type = type }
            if let update = newUpdate { updatedEntry.update = update.isEmpty ? nil : update }
            if let createdAt = newCreatedAt { updatedEntry.createdAt = createdAt }
            if let applicationId = newApplicationId { updatedEntry.applicationId = applicationId }
            
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
    
    private func deleteSelected() {
        do {
            let validIds = Set(selection.compactMap { $0 })
            try applicationService.deleteLedgerEntries(ids: validIds)
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
}
