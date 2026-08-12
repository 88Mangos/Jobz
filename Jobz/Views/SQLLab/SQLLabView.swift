import SwiftUI

struct SQLLabView: View {
    @State private var query: String = "SELECT * FROM application"
    @State private var columns: [String] = []
    @State private var rows: [[String: String]] = []
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SQL Lab")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextEditor(text: $query)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 150)
                    .padding(4)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                    )
                
                HStack {
                    Button(action: executeQuery) {
                        Label("Run Query", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: exportCSV) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .disabled(columns.isEmpty || rows.isEmpty)
                    
                    Spacer()
                    
                    Text("Read-only queries. Results limited to 100 rows.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
            
            Divider()
            
            // Results table
            if columns.isEmpty && errorMessage == nil {
                VStack {
                    Spacer()
                    Text("No results to display")
                        .foregroundColor(.secondary)
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
                                    .padding(.vertical, 4)
                                    .frame(width: 150, alignment: .leading)
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
                                        .padding(.vertical, 4)
                                        .frame(width: 150, alignment: .leading)
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
    }
    
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
}

#Preview {
    SQLLabView()
}
