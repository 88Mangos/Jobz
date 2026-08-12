import Foundation
import GRDB

enum CSVError: Error {
    case fileUnreadable
    case invalidFormat
}

class CSVImporter {
    static func importApplications(from url: URL, using service: ApplicationService) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVError.fileUnreadable
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // Skip header row
        guard rows.count > 1 else { return }
        
        for i in 1..<rows.count {
            let cols = rows[i].components(separatedBy: ",")
            if cols.count >= 2 {
                let company = cols[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let role = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)
                var duration: String? = cols.count > 2 ? cols[2] : nil
                var season: String? = cols.count > 3 ? cols[3] : nil
                var location: String? = cols.count > 4 ? cols[4] : nil
                var notes: String? = cols.count > 5 ? cols[5] : nil
                
                if duration?.isEmpty == true { duration = nil }
                if season?.isEmpty == true { season = nil }
                if location?.isEmpty == true { location = nil }
                if notes?.isEmpty == true { notes = nil }
                
                var app = JobApplication(
                    companyName: company,
                    role: role,
                    duration: duration,
                    season: season,
                    location: location,
                    notes: notes
                )
                try service.createApplication(&app)
            }
        }
    }
    
    static func importLedger(from url: URL, using service: ApplicationService) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVError.fileUnreadable
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard rows.count > 1 else { return }
        
        let dateFormatter = ISO8601DateFormatter()
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd"
        
        for i in 1..<rows.count {
            let cols = rows[i].components(separatedBy: ",")
            if cols.count >= 3 {
                guard let appId = Int64(cols[0].trimmingCharacters(in: .whitespacesAndNewlines)) else { continue }
                let dateStr = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let typeStr = cols[2].trimmingCharacters(in: .whitespacesAndNewlines)
                var updateStr: String? = cols.count > 3 ? cols[3] : nil
                if updateStr?.isEmpty == true { updateStr = nil }
                
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
}
