import Foundation
import GRDB

enum CSVError: Error, LocalizedError {
    case fileUnreadable
    case validationFailed(matched: [String], missing: [String], extraneous: [String])
    
    var errorDescription: String? {
        switch self {
        case .fileUnreadable:
            return "Unable to read the CSV file."
        case .validationFailed(let matched, let missing, let extraneous):
            return "CSV validation failed.\nMatched: \(matched.joined(separator: ", "))\nMissing: \(missing.joined(separator: ", "))\nExtraneous: \(extraneous.joined(separator: ", "))"
        }
    }
}

class CSVImporter {
    static func importApplications(from url: URL, using service: ApplicationService) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVError.fileUnreadable
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: CharacterSet.newlines).filter { !$0.isEmpty }
        
        guard rows.count > 0 else { return }
        
        let expectedHeaders = Set(["company_name", "role", "duration", "season", "location", "notes"])
        let actualHeaders = rows[0].components(separatedBy: ",").map { 
            $0.replacingOccurrences(of: "\"", with: "")
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .trimmingCharacters(in: .init(charactersIn: "\u{FEFF}"))
              .lowercased()
        }
        let actualHeaderSet = Set(actualHeaders)
        
        let matched = expectedHeaders.intersection(actualHeaderSet)
        let missing = expectedHeaders.subtracting(actualHeaderSet)
        let extraneous = actualHeaderSet.subtracting(expectedHeaders)
        
        if !missing.isEmpty {
            throw CSVError.validationFailed(matched: Array(matched), missing: Array(missing), extraneous: Array(extraneous))
        }
        
        guard rows.count > 1 else { return }
        
        // Find indices
        let aIdx = actualHeaders.firstIndex(of: "application_id")
        let cIdx = actualHeaders.firstIndex(of: "company_name")!
        let rIdx = actualHeaders.firstIndex(of: "role")!
        let rnIdx = actualHeaders.firstIndex(of: "role_extra_notes")
        let dIdx = actualHeaders.firstIndex(of: "duration")!
        let sIdx = actualHeaders.firstIndex(of: "season")!
        let lIdx = actualHeaders.firstIndex(of: "location")!
        let nIdx = actualHeaders.firstIndex(of: "notes")!
        
        for i in 1..<rows.count {
            let cols = rows[i].components(separatedBy: ",").map { 
                $0.replacingOccurrences(of: "\"", with: "")
                  .trimmingCharacters(in: .whitespacesAndNewlines) 
            }
            // Ensure we have enough columns to access the max index safely, though components will usually match header count
            guard cols.count == actualHeaders.count else { continue }
            
            var duration: String? = cols[dIdx].isEmpty ? nil : cols[dIdx]
            var season: String? = cols[sIdx].isEmpty ? nil : cols[sIdx]
            var location: String? = cols[lIdx].isEmpty ? nil : cols[lIdx]
            var notes: String? = cols[nIdx].isEmpty ? nil : cols[nIdx]
            var roleExtraNotes: String? = nil
            if let rn = rnIdx {
                roleExtraNotes = cols[rn].isEmpty ? nil : cols[rn]
            }
            var appId: Int64? = nil
            if let a = aIdx, let parsedId = Int64(cols[a]) {
                appId = parsedId
            }
            
            var app = JobApplication(
                id: appId,
                companyName: cols[cIdx],
                role: cols[rIdx],
                roleExtraNotes: roleExtraNotes,
                duration: duration,
                season: season,
                location: location,
                notes: notes
            )
            try service.createApplication(&app)
        }
    }
    
    static func importLedger(from url: URL, using service: ApplicationService) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVError.fileUnreadable
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: CharacterSet.newlines).filter { !$0.isEmpty }
        
        guard rows.count > 0 else { return }
        
        // Validation
        let expectedHeaders = Set(["application_id", "created_at", "type", "update"])
        let actualHeaders = rows[0].components(separatedBy: ",").map { 
            $0.replacingOccurrences(of: "\"", with: "")
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .trimmingCharacters(in: .init(charactersIn: "\u{FEFF}"))
              .lowercased()
        }
        let actualHeaderSet = Set(actualHeaders)
        
        let matched = expectedHeaders.intersection(actualHeaderSet)
        let missing = expectedHeaders.subtracting(actualHeaderSet)
        let extraneous = actualHeaderSet.subtracting(expectedHeaders)
        
        if !missing.isEmpty {
            throw CSVError.validationFailed(matched: Array(matched), missing: Array(missing), extraneous: Array(extraneous))
        }
        
        guard rows.count > 1 else { return }
        
        let aIdx = actualHeaders.firstIndex(of: "application_id")!
        let cIdx = actualHeaders.firstIndex(of: "created_at")!
        let tIdx = actualHeaders.firstIndex(of: "type")!
        let uIdx = actualHeaders.firstIndex(of: "update")!
        
        let dateFormatter = ISO8601DateFormatter()
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd"
        
        for i in 1..<rows.count {
            let cols = rows[i].components(separatedBy: ",").map { 
                $0.replacingOccurrences(of: "\"", with: "")
                  .trimmingCharacters(in: .whitespacesAndNewlines) 
            }
            guard cols.count == actualHeaders.count else { continue }
            
            guard let appId = Int64(cols[aIdx]) else { continue }
            let dateStr = cols[cIdx]
            let typeStr = cols[tIdx]
            var updateStr: String? = cols[uIdx].isEmpty ? nil : cols[uIdx]
            
            let date = dateFormatter.date(from: dateStr) ?? fallbackFormatter.date(from: dateStr) ?? Date()
            let type = EventType(rawValue: typeStr) ?? .update
            
            var entry = LedgerEntry(
                createdAt: date,
                type: type,
                applicationId: appId,
                update: updateStr
            )
            try service.addLedgerEntry(&entry)
        }
    }
}
