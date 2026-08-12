import SwiftUI
import GRDB

struct SummaryDetailView: View {
    let applicationId: Int64
    @State private var application: JobApplication?
    @State private var ledgerEntries: [LedgerEntry] = []
    @State private var showingAddLedgerForm = false
    @State private var entryToEdit: LedgerEntry?
    @State private var isEditingNotes = false
    @State private var editedNotes = ""
    
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
                            
                            if let extraNotes = app.roleExtraNotes, !extraNotes.isEmpty {
                                Text(extraNotes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            if isEditingNotes {
                                VStack(alignment: .leading, spacing: 4) {
                                    TextField("Application notes", text: $editedNotes, axis: .vertical)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.body)
                                    HStack {
                                        Button("Save") {
                                            saveNotes(app: app)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.small)
                                        
                                        Button("Cancel") {
                                            isEditingNotes = false
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                            } else {
                                HStack(alignment: .top) {
                                    if let notes = app.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("No application notes")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                    
                                    Button(action: {
                                        editedNotes = app.notes ?? ""
                                        isEditingNotes = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.secondary)
                                            .imageScale(.small)
                                    }
                                    .buttonStyle(.plain)
                                }
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
                    
                    if ledgerEntries.isEmpty {
                        Text("No updates recorded yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(ledgerEntries.enumerated()), id: \.element.sortId) { index, entry in
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack(alignment: .top) {
                                        GeometryReader { geometry in
                                            Path { path in
                                                let startY: CGFloat = (index == 0) ? 10 : 0
                                                let endY: CGFloat = (index == ledgerEntries.count - 1) ? 10 : geometry.size.height
                                                path.move(to: CGPoint(x: geometry.size.width / 2, y: startY))
                                                path.addLine(to: CGPoint(x: geometry.size.width / 2, y: endY))
                                            }
                                            .stroke(Color.gray.opacity(0.35), lineWidth: 2)
                                        }
                                        .frame(width: 12)
                                        
                                        Circle()
                                            .fill(entry.type.color)
                                            .frame(width: 10, height: 10)
                                            .padding(.top, 5)
                                    }
                                    .frame(width: 12)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
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
                                    .padding(.bottom, 16)
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    entryToEdit = entry
                                }
                            }
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
        .sheet(item: $entryToEdit) { entry in
            EditLedgerEventForm(entry: entry, onSave: loadData)
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
    
    private func saveNotes(app: JobApplication) {
        var updatedApp = app
        updatedApp.notes = editedNotes.isEmpty ? nil : editedNotes
        do {
            try applicationService.dbQueue.write { db in
                try updatedApp.update(db)
            }
            application = updatedApp
            isEditingNotes = false
        } catch {
            print("Failed to save notes: \(error)")
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
