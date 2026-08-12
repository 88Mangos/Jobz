import SwiftUI

struct AddLedgerEventForm: View {
    @Environment(\.dismiss) var dismiss
    let applicationId: Int64
    var onSave: () -> Void
    
    @State private var type: EventType = .update
    @State private var date = Date()
    @State private var notes = ""
    @State private var timezone: String = {
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
    
    private let applicationService = ApplicationService()
    
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
                    ForEach(supportedTimezones, id: \.self) { tzId in
                        Text(TimeZone.formattedLabel(for: tzId, date: date)).tag(tzId)
                    }
                }
                TextField("Notes", text: $notes)
            }
            .padding()
            .navigationTitle("Add Update")
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
        var entry = LedgerEntry(
            createdAt: date,
            type: type,
            applicationId: applicationId,
            update: notes.isEmpty ? nil : notes,
            timezone: timezone
        )
        do {
            try applicationService.addLedgerEntry(&entry)
            onSave()
            dismiss()
        } catch {
            print("Failed to save: \\(error)")
        }
    }
}
