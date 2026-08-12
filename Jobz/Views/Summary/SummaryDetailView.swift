import SwiftUI

struct SummaryDetailView: View {
    let applicationId: Int64
    @State private var application: JobApplication?
    @State private var ledgerEntries: [LedgerEntry] = []
    @State private var showingAddLedgerForm = false
    
    private let applicationService = ApplicationService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let app = application {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(app.companyName)
                            .font(.largeTitle)
                            .bold()
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expandedRole(for: app))
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            if let notes = app.roleExtraNotes, !notes.isEmpty {
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let loc = app.location, !loc.isEmpty {
                            Text(loc)
                                .font(.body)
                        }
                    }
                    .padding(.bottom)
                    
                    Divider()
                    
                    HStack {
                        Text("Timeline")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Button("Add Update") {
                            showingAddLedgerForm = true
                        }
                    }
                    
                    ForEach(ledgerEntries) { entry in
                        HStack(alignment: .top) {
                            VStack {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 5)
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 2)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(entry.type.rawValue)
                                    .font(.headline)
                                Text(entry.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let update = entry.update, !update.isEmpty {
                                    Text(update)
                                        .font(.body)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.bottom, 10)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .padding()
        }
        .onAppear {
            loadData()
        }
        // Force reload if applicationId changes
        .onChange(of: applicationId) { _, _ in
            loadData()
        }
        .sheet(isPresented: $showingAddLedgerForm) {
            AddLedgerEventForm(applicationId: applicationId, onSave: loadData)
        }
    }
    
    private func loadData() {
        do {
            application = try applicationService.fetchApplication(id: applicationId)
            ledgerEntries = try applicationService.fetchLedgerEntries(for: applicationId)
        } catch {
            print("Error loading data: \(error)")
        }
    }
    
    private func expandedRole(for app: JobApplication) -> String {
        let role = app.role.trimmingCharacters(in: .whitespacesAndNewlines)
        let upperRole = role.uppercased()
        
        if upperRole == "OTHER" {
            return "Other"
        }
        
        let expansion: String?
        switch upperRole {
        case "MLE": expansion = "Machine Learning Engineer"
        case "AIE": expansion = "AI Engineer"
        case "SWE": expansion = "Software Engineer"
        case "IT": expansion = "Information Technology"
        case "DS": expansion = "Data Science"
        case "QT": expansion = "Quant Trader"
        case "QR": expansion = "Quant Researcher"
        default: expansion = nil
        }
        
        if let expansion = expansion {
            return "\(role) - \(expansion)"
        }
        
        return role
    }
}
