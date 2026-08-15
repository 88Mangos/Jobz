import SwiftUI
import AppKit

struct SQLLabView: View {
    @State private var query: String = "SELECT * FROM application"
    @State private var columns: [String] = []
    @State private var rows: [[String: String]] = []
    @State private var errorMessage: String? = nil
    
    // Saved queries persistence
    @AppStorage("savedSQLQueriesData") private var savedQueriesData: String = ""
    @State private var showSavedPanel: Bool = true
    @State private var showingSaveSheet: Bool = false
    @State private var newQueryName: String = ""
    @State private var copiedQueryId: UUID? = nil
    @State private var selectedTab: QueryTab = .presets
    
    enum QueryTab: String, CaseIterable, Identifiable {
        case presets = "Presets"
        case myQueries = "My Queries"
        var id: String { rawValue }
    }
    
    var body: some View {
        HSplitView {
            // Main Editor & Results Panel
            VStack(spacing: 0) {
                // Header & Action Bar
                VStack(alignment: .leading, spacing: 10) {
                    HStack {

                        Spacer()
                        
                        Button(action: { showSavedPanel.toggle() }) {
                            Label(showSavedPanel ? "Hide Saved Queries" : "Saved Queries", systemImage: showSavedPanel ? "sidebar.right" : "bookmark.fill")
                        }
                        .buttonStyle(.bordered)
                        .help("Toggle Saved Queries Panel")
                    }
                    
                    TextEditor(text: $query)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 140)
                        .padding(4)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                        )
                    
                    HStack(spacing: 10) {
                        Button(action: executeQuery) {
                            Label("Run Query", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: [.command])
                        
                        Button(action: {
                            newQueryName = suggestQueryName(for: query)
                            showingSaveSheet = true
                        }) {
                            Label("Save Query", systemImage: "bookmark.badge.plus")
                        }
                        .buttonStyle(.bordered)
                        .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Button(action: exportCSV) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        .disabled(columns.isEmpty || rows.isEmpty)
                        
                        Spacer()
                        
                        Text("Read-only (SELECT queries only). Limit: 100 rows.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
                .padding()
                
                Divider()
                
                // Results table
                if columns.isEmpty && errorMessage == nil {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "terminal")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No results to display")
                            .foregroundColor(.secondary)
                        Text("Click 'Run Query' or select a saved query to view results.")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if columns.isEmpty && errorMessage != nil {
                    Spacer()
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Header
                            HStack(spacing: 0) {
                                ForEach(columns, id: \.self) { column in
                                    Text(column)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .frame(width: 160, alignment: .leading)
                                        .background(Color(nsColor: .windowBackgroundColor))
                                        .border(Color.secondary.opacity(0.3), width: 0.5)
                                }
                            }
                            
                            // Rows
                            ForEach(0..<rows.count, id: \.self) { rowIndex in
                                HStack(spacing: 0) {
                                    ForEach(columns, id: \.self) { column in
                                        Text(rows[rowIndex][column] ?? "")
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .frame(width: 160, alignment: .leading)
                                            .border(Color.secondary.opacity(0.3), width: 0.5)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                }
                            }
                        }
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                }
            }
            .frame(minWidth: 450)
            
            // Saved Queries Panel (Collapsible Side Panel)
            if showSavedPanel {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Query Library")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Picker("Tab", selection: $selectedTab) {
                            ForEach(QueryTab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            let userSaved = getSavedQueries()
                            let queriesToDisplay = (selectedTab == .presets) ? SavedQuery.presets : userSaved
                            
                            if queriesToDisplay.isEmpty {
                                VStack(spacing: 8) {
                                    Spacer(minLength: 40)
                                    Image(systemName: selectedTab == .presets ? "star.slash" : "bookmark.slash")
                                        .font(.system(size: 28))
                                        .foregroundColor(.secondary)
                                    Text(selectedTab == .presets ? "No Presets" : "No Saved Queries")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(selectedTab == .presets ? "Standard query templates will appear here." : "Click 'Save Query' above to save custom queries.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 16)
                                }
                            } else {
                                ForEach(queriesToDisplay) { item in
                                    queryCard(for: item, isUserSaved: selectedTab == .myQueries)
                                }
                            }
                        }
                        .padding(12)
                    }
                }
                .frame(minWidth: 280, maxWidth: 350)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            saveQueryModal
        }
    }
    
    // MARK: - Query Card View
    private func queryCard(for savedQuery: SavedQuery, isUserSaved: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(savedQuery.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                if copiedQueryId == savedQuery.id {
                    Text("Copied!")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            Text(savedQuery.sql)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                )
            
            HStack {
                Button(action: {
                    query = savedQuery.sql
                    executeQuery()
                }) {
                    Label("Load & Run", systemImage: "arrow.up.forward.square")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: {
                    copyToClipboard(savedQuery.sql)
                    withAnimation {
                        copiedQueryId = savedQuery.id
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if copiedQueryId == savedQuery.id {
                            copiedQueryId = nil
                        }
                    }
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                if isUserSaved {
                    Button(action: {
                        deleteQuery(savedQuery)
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete Saved Query")
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Save Query Sheet Modal
    private var saveQueryModal: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save Query")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Query Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("e.g., Interviews Count", text: $newQueryName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("SQL Statement")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(query)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .lineLimit(4)
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    showingSaveSheet = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Save") {
                    saveCurrentQuery()
                    showingSaveSheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newQueryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(20)
        .frame(width: 380)
    }
    
    // MARK: - Helper Actions
    private func executeQuery() {
        errorMessage = nil
        do {
            let result = try DatabaseManager.shared.executeSQL(query)
            columns = result.columns
            rows = result.rows
        } catch {
            errorMessage = error.localizedDescription
            columns = []
            rows = []
        }
    }
    
    private func exportCSV() {
        guard !columns.isEmpty, !rows.isEmpty else { return }
        
        let csvRows = rows.map { dict in
            columns.map { col in dict[col] ?? "" }
        }
        
        let csvString = CSVExporter.generateCSV(headers: columns, rows: csvRows)
        let filename = CSVExporter.generateFilename(prefix: "SQLLab")
        CSVExporter.exportToFile(csvString: csvString, defaultFilename: filename)
    }
    
    private func getSavedQueries() -> [SavedQuery] {
        guard !savedQueriesData.isEmpty,
              let data = savedQueriesData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SavedQuery].self, from: data) else {
            return []
        }
        return decoded
    }
    
    private func saveQueriesList(_ queries: [SavedQuery]) {
        if let encoded = try? JSONEncoder().encode(queries),
           let jsonString = String(data: encoded, encoding: .utf8) {
            savedQueriesData = jsonString
        }
    }
    
    private func saveCurrentQuery() {
        let trimmedName = newQueryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newEntry = SavedQuery(name: trimmedName, sql: query)
        var current = getSavedQueries()
        current.insert(newEntry, at: 0)
        saveQueriesList(current)
        selectedTab = .myQueries
    }
    
    private func deleteQuery(_ item: SavedQuery) {
        var current = getSavedQueries()
        current.removeAll { $0.id == item.id }
        saveQueriesList(current)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func suggestQueryName(for sql: String) -> String {
        let lower = sql.lowercased()
        if lower.contains("interview") { return "Interviews Query" }
        if lower.contains("assessment") || lower.contains("oa") { return "Assessments Query" }
        if lower.contains("chat") { return "Chats Query" }
        if lower.contains("status") { return "Status Summary" }
        if lower.contains("application") { return "Applications Query" }
        if lower.contains("ledger") { return "Ledger Entries" }
        return "Custom Query"
    }
}

#Preview {
    SQLLabView()
}
