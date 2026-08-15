import SwiftUI

struct QuickAddView: View {
    @State private var companyName = ""
    @State private var role = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var showSuccessMessage = false
    
    private let applicationService = ApplicationService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quick Add Application")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 10)
            
            Form {
                Section(header: Text("Application Details")) {
                    TextField("Company Name", text: $companyName)
                    TextField("Role", text: $role)
                    DatePicker("Applied Date", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Spacer()
                Button(action: save) {
                    Text("Save & Add Another")
                        .bold()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(companyName.isEmpty || role.isEmpty)
            }
            .padding(.top, 10)
            
            if showSuccessMessage {
                Text("Application successfully added!")
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
            
            Spacer()
        }
        .padding(30)
    }
    
    private func save() {
        var newApp = JobApplication(
            companyName: companyName,
            role: role,
            notes: notes.isEmpty ? nil : notes
        )
        do {
            try applicationService.createApplication(&newApp, initialEventDate: date)
            
            // Reset form
            companyName = ""
            role = ""
            notes = ""
            date = Date()
            
            // Show success message briefly
            withAnimation {
                showSuccessMessage = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSuccessMessage = false
                }
            }
        } catch {
            print("Failed to save: \(error)")
        }
    }
}

#Preview {
    QuickAddView()
}
