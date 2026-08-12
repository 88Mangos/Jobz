import SwiftUI
import GRDB

struct EditLedgerEventForm: View {
    @Environment(\.dismiss) var dismiss
    let entry: LedgerEntry
    var onSave: () -> Void
    
    @State private var type: EventType
    @State private var date: Date
    @State private var notes: String
    @State private var timezone: String?
    
    private var supportedTimezones: [String] {
        var zones = ["America/New_York", "America/Chicago", "America/Los_Angeles", "UTC"]
        let current = TimeZone.current.identifier
        if !zones.contains(current) {
            zones.insert(current, at: 0)
        }
        return zones
    }
    
    private let applicationService = ApplicationService()
    
    init(entry: LedgerEntry, onSave: @escaping () -> Void) {
        self.entry = entry
        self.onSave = onSave
        
        _type = State(wrappedValue: entry.type)
        _date = State(wrappedValue: entry.createdAt)
        _notes = State(wrappedValue: entry.update ?? "")
        _timezone = State(wrappedValue: entry.timezone)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Event Type", selection: $type) {
                    ForEach(EventType.allCases) { eventType in
                        Text(eventType.rawValue).tag(eventType)
                    }
                }
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                Picker("Timezone", selection: $timezone) {
                    Text("None").tag(String?.none)
                    ForEach(supportedTimezones, id: \.self) { tzId in
                        Text(TimeZone.formattedLabel(for: tzId, date: date)).tag(String?.some(tzId))
                    }
                }
                TextField("Notes", text: $notes)
            }
            .padding()
            .navigationTitle("Edit Update")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
    }
    
    private func save() {
        var updatedEntry = entry
        updatedEntry.type = type
        updatedEntry.createdAt = date
        updatedEntry.update = notes.isEmpty ? nil : notes
        updatedEntry.timezone = timezone
        
        do {
            try applicationService.dbQueue.write { db in
                try updatedEntry.update(db)
            }
            onSave()
            dismiss()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
