import SwiftUI

struct NewApplicationForm: View {
    @Environment(\.dismiss) var dismiss
    var onSave: () -> Void
    
    @State private var companyName = ""
    @State private var role = ""
    @State private var location: String? = nil
    @State private var date = Date()
    
    private let applicationService = ApplicationService()
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Company Name", text: $companyName)
                TextField("Role", text: $role)
                HStack {
                    Text("Location")
                    Spacer()
                    MultiSelectLocationMenu(selectedLocationsStr: $location)
                }
                DatePicker("Applied Date", selection: $date, displayedComponents: .date)
            }
            .padding()
            .navigationTitle("New Application")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(companyName.isEmpty || role.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
    
    private func save() {
        var newApp = JobApplication(
            companyName: companyName,
            role: role,
            location: location
        )
        do {
            try applicationService.createApplication(&newApp, initialEventDate: date)
            onSave()
            dismiss()
        } catch {
            print("Failed to save: \\(error)")
        }
    }
}
