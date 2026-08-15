import SwiftUI
import UniformTypeIdentifiers

struct BackupView: View {
    @State private var isExporting = false
    @State private var isInspecting = false
    @State private var isImporting = false
    
    @State private var showModeSelectionSheet = false
    @State private var selectedZipURL: URL? = nil
    @State private var inspectedMetadata: BackupMetadata? = nil
    @State private var selectedMode: BackupImportMode = .replaceAll
    @State private var showConfirmReplaceAlert = false
    
    @State private var importResult: BackupImportResult? = nil
    @State private var showSuccessAlert = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    private let applicationService = ApplicationService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Image(systemName: "externaldrive.badge.timemachine")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Backup & Restore")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Export all user data to a portable ZIP archive or restore previous backups.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // Export Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Export Complete Archive", systemImage: "square.and.arrow.up.circle.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    Text("Packages all your data into a single human-readable ZIP archive. You can inspect or modify individual CSV, Markdown, and JSON files inside the archive.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Archive includes:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                            archiveItemRow(icon: "tablecells", title: "applications.csv", desc: "Raw Applications spreadsheet")
                            archiveItemRow(icon: "text.book.closed", title: "ledger.csv", desc: "Raw Ledger events timeline")
                            archiveItemRow(icon: "text.quote", title: "musings.md", desc: "Musings scratchpad notes")
                            archiveItemRow(icon: "note.text", title: "dashboard_notes.md", desc: "Dashboard notes dump")
                            archiveItemRow(icon: "server.rack", title: "saved_queries.json", desc: "Custom SQL Lab queries")
                            archiveItemRow(icon: "mappin.and.ellipse", title: "custom_locations.json", desc: "Custom location entries")
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    HStack {
                        Spacer()
                        Button(action: handleExport) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export All Data (.zip)")
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(isExporting)
                    }
                }
                .padding(20)
                .background(Color(NSColor.secondarySystemFill))
                .cornerRadius(12)
                
                // Import Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Import & Restore Archive", systemImage: "square.and.arrow.down.circle.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    Text("Ingest a previously exported Jobz ZIP backup. You can choose between a clean idempotent replacement or non-destructive merging.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.title3)
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Replace All Data (Full Restore)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Wipes current database and preferences, restoring the exact state from the archive. Fully idempotent.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "plus.square.on.square")
                                .font(.title3)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Merge with Existing Data")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Updates matching IDs, appends new applications and events, and combines saved queries & custom locations.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    HStack {
                        Spacer()
                        Button(action: promptSelectZipForImport) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                Text("Select Backup Archive (.zip)...")
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(isInspecting || isImporting)
                    }
                }
                .padding(20)
                .background(Color(NSColor.secondarySystemFill))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("Backup & Restore")
        .sheet(isPresented: $showModeSelectionSheet) {
            importModeSheet
        }
        .alert("Confirm Full Restore", isPresented: $showConfirmReplaceAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Replace All Data", role: .destructive) {
                executeImport(mode: .replaceAll)
            }
        } message: {
            Text("This will wipe all existing job applications, ledger events, musings, notes, custom locations, and saved SQL queries, replacing them with the contents of this archive.\n\nThis action cannot be undone.")
        }
        .alert("Import Successful", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            if let res = importResult {
                Text("Mode: \(res.mode.rawValue)\n\n• Applications: \(res.applicationsCount)\n• Ledger Events: \(res.ledgerCount)\n• Saved SQL Queries: \(res.savedQueriesCount)\n• Custom Locations: \(res.customLocationsCount)\n• Musings: \(res.musingsImported ? "Restored" : "None")\n• Dashboard Notes: \(res.dashboardNotesImported ? "Restored" : "None")")
            } else {
                Text("All user data has been successfully imported.")
            }
        }
        .alert("Import Failed", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred during import.")
        }
    }
    
    // MARK: - Subviews
    
    private func archiveItemRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private var importModeSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "archivebox.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Restore Jobz Backup")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") {
                    showModeSelectionSheet = false
                    selectedZipURL = nil
                    inspectedMetadata = nil
                }
            }
            
            Divider()
            
            if let meta = inspectedMetadata {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Archive Contents:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                        GridRow {
                            Text("Export Date:")
                                .foregroundColor(.secondary)
                            Text(meta.exportedAt, style: .date)
                                .fontWeight(.medium) + Text(" ") + Text(meta.exportedAt, style: .time)
                        }
                        GridRow {
                            Text("Applications:")
                                .foregroundColor(.secondary)
                            Text("\(meta.applicationCount) records")
                                .fontWeight(.medium)
                        }
                        GridRow {
                            Text("Ledger Events:")
                                .foregroundColor(.secondary)
                            Text("\(meta.ledgerCount) events")
                                .fontWeight(.medium)
                        }
                        GridRow {
                            Text("Saved Queries:")
                                .foregroundColor(.secondary)
                            Text("\(meta.savedQueriesCount) custom queries")
                                .fontWeight(.medium)
                        }
                        GridRow {
                            Text("Custom Locations:")
                                .foregroundColor(.secondary)
                            Text("\(meta.customLocationsCount) locations")
                                .fontWeight(.medium)
                        }
                        GridRow {
                            Text("Scratchpads:")
                                .foregroundColor(.secondary)
                            Text("\(meta.hasMusings ? "Musings ✓" : "No Musings") | \(meta.hasDashboardNotes ? "Dashboard Notes ✓" : "No Notes")")
                                .fontWeight(.medium)
                        }
                    }
                    .font(.caption)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Import Mode:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(BackupImportMode.allCases) { mode in
                    Button(action: { selectedMode = mode }) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: selectedMode == mode ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(selectedMode == mode ? .accentColor : .secondary)
                                .font(.title3)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(selectedMode == mode ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedMode == mode ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Cancel") {
                    showModeSelectionSheet = false
                    selectedZipURL = nil
                    inspectedMetadata = nil
                }
                
                Button(action: {
                    if selectedMode == .replaceAll {
                        showConfirmReplaceAlert = true
                    } else {
                        executeImport(mode: .merge)
                    }
                }) {
                    Text(selectedMode == .replaceAll ? "Proceed to Replace..." : "Merge Data")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedMode == .replaceAll ? .orange : .blue)
            }
        }
        .padding(24)
        .frame(minWidth: 480, maxWidth: 540)
    }
    
    // MARK: - Actions
    
    private func handleExport() {
        isExporting = true
        BackupService.promptExportBackup(using: applicationService) { result in
            isExporting = false
            switch result {
            case .success:
                break
            case .failure(let error):
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func promptSelectZipForImport() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.zip]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Select Jobz Backup Archive"
        openPanel.message = "Choose a .zip backup archive to import."
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                inspectZip(url: url)
            }
        }
    }
    
    private func inspectZip(url: URL) {
        isInspecting = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let (_, metadata, cleanup) = try BackupService.inspectBackup(from: url)
                cleanup()
                
                DispatchQueue.main.async {
                    self.selectedZipURL = url
                    self.inspectedMetadata = metadata
                    self.isInspecting = false
                    self.showModeSelectionSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isInspecting = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func executeImport(mode: BackupImportMode) {
        guard let url = selectedZipURL else { return }
        showModeSelectionSheet = false
        isImporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try BackupService.importBackup(from: url, mode: mode, using: self.applicationService)
                DispatchQueue.main.async {
                    self.isImporting = false
                    self.importResult = result
                    self.showSuccessAlert = true
                    self.selectedZipURL = nil
                    self.inspectedMetadata = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.isImporting = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    BackupView()
}
