import Foundation
import AppKit
import UniformTypeIdentifiers

class CSVExporter {
    
    /// Generates a CSV string given an array of headers and an array of rows (each row is an array of strings).
    static func generateCSV(headers: [String], rows: [[String]]) -> String {
        var csvString = ""
        
        // Add headers
        let formattedHeaders = headers.map { formatField($0) }.joined(separator: ",")
        csvString.append(formattedHeaders + "\n")
        
        // Add rows
        for row in rows {
            let formattedRow = row.map { formatField($0) }.joined(separator: ",")
            csvString.append(formattedRow + "\n")
        }
        
        return csvString
    }
    
    /// Formats a single field according to CSV standards.
    static func formatField(_ field: String) -> String {
        var formatted = field
        
        // If the field contains quotes, escape them by doubling
        let containsQuotes = formatted.contains("\"")
        if containsQuotes {
            formatted = formatted.replacingOccurrences(of: "\"", with: "\"\"")
        }
        
        // If the field contains commas, quotes, or newlines, wrap it in double quotes
        if formatted.contains(",") || containsQuotes || formatted.contains("\n") || formatted.contains("\r") {
            formatted = "\"\(formatted)\""
        }
        
        return formatted
    }
    
    /// Generates a filename with the current UTC datetime (e.g., "prefix_20260812T150209Z.csv")
    static func generateFilename(prefix: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let dateString = formatter.string(from: Date())
        return "\(prefix)_\(dateString).csv"
    }
    
    /// Prompts the user to save the CSV string to a file using NSSavePanel.
    static func exportToFile(csvString: String, defaultFilename: String) {
        DispatchQueue.main.async {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.commaSeparatedText]
            savePanel.nameFieldStringValue = defaultFilename
            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            savePanel.title = "Export CSV"
            savePanel.message = "Choose a location to save your exported data."
            
            savePanel.begin { result in
                if result == .OK, let url = savePanel.url {
                    do {
                        try csvString.write(to: url, atomically: true, encoding: .utf8)
                    } catch {
                        print("Failed to save CSV: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
