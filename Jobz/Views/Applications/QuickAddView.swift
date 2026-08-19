import SwiftUI

struct QuickAddView: View {
    @State private var existingCompanies: [String] = []
    @State private var existingRoles: [String] = []
    @State private var existingSeasons: [String] = []
    
    @State private var selectedCompany = "__ADD_NEW__"
    @State private var newCompany = ""
    
    @State private var selectedRole = "__ADD_NEW__"
    @State private var newRole = ""
    
    @State private var roleExtraNotes = ""
    
    @State private var selectedSeason = "__ADD_NEW__"
    @State private var newSeason = ""
    
    @State private var duration = ""
    @State private var location: String? = nil
    
    @State private var notes = ""
    @State private var date = Date()
    @State private var timezone: String? = {
        let currentId = TimeZone.current.identifier
        let supported = ["America/New_York", "America/Chicago", "America/Los_Angeles", "UTC"]
        return supported.contains(currentId) ? currentId : "America/New_York"
    }()
    @State private var showSuccessMessage = false
    
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Form {
                    Section(header: Text("Core Details")) {
                        Picker("Company", selection: $selectedCompany) {
                            Text("Add new...").tag("__ADD_NEW__")
                            Divider()
                            ForEach(existingCompanies, id: \.self) { company in
                                Text(company).tag(company)
                            }
                        }
                        if selectedCompany == "__ADD_NEW__" {
                            TextField("New Company Name", text: $newCompany)
                        }
                        
                        Picker("Role", selection: $selectedRole) {
                            Text("Add new...").tag("__ADD_NEW__")
                            Divider()
                            ForEach(existingRoles, id: \.self) { role in
                                Text(role).tag(role)
                            }
                        }
                        if selectedRole == "__ADD_NEW__" {
                            TextField("New Role", text: $newRole)
                        }
                        
                        TextField("Role Notes (Optional)", text: $roleExtraNotes)
                    }
                    
                    Section(header: Text("Additional Details")) {
                        Picker("Season", selection: $selectedSeason) {
                            Text("Add new...").tag("__ADD_NEW__")
                            Text("None").tag("__NONE__")
                            Divider()
                            ForEach(existingSeasons, id: \.self) { season in
                                Text(season).tag(season)
                            }
                        }
                        if selectedSeason == "__ADD_NEW__" {
                            TextField("New Season", text: $newSeason)
                        }
                        
                        TextField("Duration (e.g. Summer, 12 weeks)", text: $duration)
                        
                        HStack {
                            Text("Locations")
                            Spacer()
                            MultiSelectLocationMenu(selectedLocationsStr: $location)
                        }
                    }
                    
                    Section(header: Text("Initial Event")) {
                        DatePicker("Applied Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        Picker("Timezone", selection: $timezone) {
                            Text("None").tag(String?.none)
                            ForEach(supportedTimezones, id: \.self) { tzId in
                                Text(TimeZone.formattedLabel(for: tzId, date: date)).tag(String?.some(tzId))
                            }
                        }
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
                    .disabled(isSaveDisabled)
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
        .onAppear {
            loadExistingData()
        }
    }
    
    private var isSaveDisabled: Bool {
        let finalCompany = selectedCompany == "__ADD_NEW__" ? newCompany : selectedCompany
        let finalRole = selectedRole == "__ADD_NEW__" ? newRole : selectedRole
        return finalCompany.trimmingCharacters(in: .whitespaces).isEmpty || finalRole.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func loadExistingData() {
        do {
            let apps = try applicationService.fetchRawApplications()
            existingCompanies = Array(Set(apps.map { $0.companyName })).sorted()
            existingRoles = Array(Set(apps.map { $0.role })).sorted()
            existingSeasons = Array(Set(apps.compactMap { $0.season }.filter { !$0.isEmpty })).sorted()
        } catch {
            print("Failed to load existing data: \(error)")
        }
    }
    
    private func save() {
        let finalCompany = selectedCompany == "__ADD_NEW__" ? newCompany : selectedCompany
        let finalRole = selectedRole == "__ADD_NEW__" ? newRole : selectedRole
        let finalSeason: String? = {
            if selectedSeason == "__NONE__" { return nil }
            if selectedSeason == "__ADD_NEW__" { return newSeason.isEmpty ? nil : newSeason }
            return selectedSeason
        }()
        
        var newApp = JobApplication(
            companyName: finalCompany.trimmingCharacters(in: .whitespaces),
            role: finalRole.trimmingCharacters(in: .whitespaces),
            roleExtraNotes: roleExtraNotes.isEmpty ? nil : roleExtraNotes,
            duration: duration.isEmpty ? nil : duration,
            season: finalSeason?.trimmingCharacters(in: .whitespaces),
            location: location,
            notes: notes.isEmpty ? nil : notes
        )
        do {
            try applicationService.createApplication(&newApp, initialEventDate: date, timezone: timezone)
            
            // Reload data to reflect potentially new company/role/season
            loadExistingData()
            
            // Reset form
            selectedCompany = "__ADD_NEW__"
            newCompany = ""
            selectedRole = "__ADD_NEW__"
            newRole = ""
            roleExtraNotes = ""
            selectedSeason = "__ADD_NEW__"
            newSeason = ""
            duration = ""
            location = nil
            notes = ""
            date = Date()
            timezone = {
                let currentId = TimeZone.current.identifier
                let supported = ["America/New_York", "America/Chicago", "America/Los_Angeles", "UTC"]
                return supported.contains(currentId) ? currentId : "America/New_York"
            }()
            
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
