import SwiftUI

struct AddLedgerEventForm: View {
    @Environment(\.dismiss) var dismiss
    let applicationId: Int64
    var onSave: () -> Void
    
    @State private var type: EventType = .update
    @State private var date = Date()
    @State private var notes = ""
    
    private let applicationService = ApplicationService()
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Event Type", selection: $type) {
                    ForEach(EventType.allCases) { eventType in
                        Text(eventType.rawValue).tag(eventType)
                    }
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
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
            update: notes.isEmpty ? nil : notes
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
