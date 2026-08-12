import SwiftUI
import GRDB
import UniformTypeIdentifiers

struct GlobalLedgerView: View {
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
    
    // Quick Add State
    @State private var newCreatedAt: Date = Date()
    @State private var newType: EventType = .applied
    @State private var newApplicationId: Int64? = nil
    @State private var newUpdate: String = ""
    
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
            
            Table(filteredAndSortedEntries, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("ledger_id", value: \.sortId) { entry in
                    Text("\(entry.id ?? 0)")
                }
                TableColumn("created_at", value: \.createdAt) { entry in
                    DatePicker("", selection: Binding(
                        get: { entry.createdAt },
                        set: { newValue in updateEntry(entry, newCreatedAt: newValue) }
                    ), displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                }
                TableColumn("type", value: \.type.rawValue) { entry in
                    Picker("", selection: Binding(
                        get: { entry.type },
                        set: { newValue in updateEntry(entry, newType: newValue) }
                    )) {
                        ForEach(EventType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .labelsHidden()
                }
                TableColumn("application_id", value: \.applicationId) { entry in
                    TextField("App ID", value: Binding(
                        get: { entry.applicationId },
                        set: { newValue in updateEntry(entry, newApplicationId: newValue) }
                    ), format: .number)
                }
                TableColumn("update", value: \.sortUpdate) { entry in
                    TextField("Notes", text: Binding(
                        get: { entry.update ?? "" },
                        set: { newValue in updateEntry(entry, newUpdate: newValue) }
                    ))
                }
            }
            
    
        }
        .navigationTitle("Global Ledger")
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
    
    private func appName(for id: Int64) -> String {
        return applications.first { $0.applicationId == id }?.companyName ?? "Unknown"
    }
    
    private func updateEntry(_ entry: LedgerEntry, newType: EventType? = nil, newUpdate: String? = nil, newCreatedAt: Date? = nil, newApplicationId: Int64? = nil) {
        do {
            var updatedEntry = entry
            if let type = newType { updatedEntry.type = type }
            if let update = newUpdate { updatedEntry.update = update }
            if let createdAt = newCreatedAt { updatedEntry.createdAt = createdAt }
            if let appId = newApplicationId { updatedEntry.applicationId = appId }
            
            try applicationService.dbQueue.write { db in
                try updatedEntry.update(db)
            }
            loadData()
        } catch {
            print("Error updating ledger entry: \(error)")
        }
    }
    
    private func quickAdd() {
        guard let appId = newApplicationId else { return }
        var newEntry = LedgerEntry(
            createdAt: newCreatedAt,
            type: newType,
            applicationId: appId,
            update: newUpdate.isEmpty ? nil : newUpdate
        )
        do {
            try applicationService.addLedgerEntry(&newEntry)
            newCreatedAt = Date()
            newType = .applied
            newApplicationId = nil
            newUpdate = ""
            loadData()
        } catch {
            print("Error saving quick add: \(error)")
        }
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
