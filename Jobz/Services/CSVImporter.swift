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
    
    private static let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    
    static func parseCSVRow(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result.map { 
            $0.replacingOccurrences(of: "\"", with: "")
              .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private static func fixTwoDigitYear(_ date: Date) -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        if year < 100 {
            return calendar.date(byAdding: .year, value: 2000, to: date) ?? date
        }
        return date
    }
    
    private static func parseDate(_ str: String) -> Date {
        let sanitizedStr = str.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                              .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Try ISO8601
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: sanitizedStr) {
            return fixTwoDigitYear(date)
        }
        
        // 2. Explicit formatters with US POSIX locale
        let dateFormats = [
            "M/d/yy h:mm:ss a",
            "M/d/yy h:mm a",
            "M/d/yy H:mm:ss",
            "M/d/yy H:mm",
            "M/d/yy",
            "MM/dd/yy h:mm:ss a",
            "MM/dd/yy h:mm a",
            "MM/dd/yy H:mm:ss",
            "MM/dd/yy H:mm",
            "MM/dd/yy",
            "M/d/yyyy h:mm:ss a",
            "M/d/yyyy h:mm a",
            "M/d/yyyy H:mm:ss",
            "M/d/yyyy H:mm",
            "M/d/yyyy",
            "MM/dd/yyyy h:mm:ss a",
            "MM/dd/yyyy h:mm a",
            "MM/dd/yyyy H:mm:ss",
            "MM/dd/yyyy H:mm",
            "MM/dd/yyyy",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        let twoDigitStart = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2000, month: 1, day: 1))
        
        for format in dateFormats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = format
            if format.contains("yy") && !format.contains("yyyy") {
                df.twoDigitStartDate = twoDigitStart
            }
            if let date = df.date(from: sanitizedStr) {
                return fixTwoDigitYear(date)
            }
        }
        
        // 3. Fallback to NSDataDetector (Apple Natural Language & Date Detector)
        if let detector = dataDetector {
            let range = NSRange(location: 0, length: sanitizedStr.utf16.count)
            if let match = detector.firstMatch(in: sanitizedStr, options: [], range: range),
               let date = match.date {
                return fixTwoDigitYear(date)
            }
        }
        
        return Date()
    }
    
    static func importApplications(from url: URL, using service: ApplicationService) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVError.fileUnreadable
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines)
                          .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard rows.count > 0 else { return }
        
        let expectedHeaders = Set(["company_name", "role", "duration", "season", "location", "notes"])
        let actualHeaders = parseCSVRow(rows[0]).map { 
            $0.trimmingCharacters(in: .init(charactersIn: "\u{FEFF}")).lowercased()
        }
        let actualHeaderSet = Set(actualHeaders)
        
        let matched = expectedHeaders.intersection(actualHeaderSet)
        let missing = expectedHeaders.subtracting(actualHeaderSet)
        let extraneous = actualHeaderSet.subtracting(expectedHeaders)
        
        if !missing.isEmpty {
            throw CSVError.validationFailed(matched: Array(matched), missing: Array(missing), extraneous: Array(extraneous))
        }
        
        guard rows.count > 1 else { return }
        
        let aIdx = actualHeaders.firstIndex(of: "application_id")
        let cIdx = actualHeaders.firstIndex(of: "company_name")!
        let rIdx = actualHeaders.firstIndex(of: "role")!
        let rnIdx = actualHeaders.firstIndex(of: "role_extra_notes")
        let dIdx = actualHeaders.firstIndex(of: "duration")!
        let sIdx = actualHeaders.firstIndex(of: "season")!
        let lIdx = actualHeaders.firstIndex(of: "location")!
        let nIdx = actualHeaders.firstIndex(of: "notes")!
        
        for i in 1..<rows.count {
            let cols = parseCSVRow(rows[i])
            guard cols.count >= actualHeaders.count else { continue }
            
            let duration: String? = cols[dIdx].isEmpty ? nil : cols[dIdx]
            let season: String? = cols[sIdx].isEmpty ? nil : cols[sIdx]
            let location: String? = cols[lIdx].isEmpty ? nil : cols[lIdx]
            let notes: String? = cols[nIdx].isEmpty ? nil : cols[nIdx]
            var roleExtraNotes: String? = nil
            if let rn = rnIdx, rn < cols.count {
                roleExtraNotes = cols[rn].isEmpty ? nil : cols[rn]
            }
            var appId: Int64? = nil
            if let a = aIdx, a < cols.count, let parsedId = Int64(cols[a]) {
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
            try service.createApplication(&app, skipLedger: true)
        }
        try service.syncAutoIncrementSequences()
    }
    
    static func importLedger(from url: URL, using service: ApplicationService) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVError.fileUnreadable
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines)
                          .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard rows.count > 0 else { return }
        
        let expectedHeaders = Set(["application_id", "created_at", "type", "update"])
        let actualHeaders = parseCSVRow(rows[0]).map { 
            $0.trimmingCharacters(in: .init(charactersIn: "\u{FEFF}")).lowercased()
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
        let tzIdx = actualHeaders.firstIndex(of: "timezone")
        
        for i in 1..<rows.count {
            let cols = parseCSVRow(rows[i])
            guard cols.count >= actualHeaders.count else { continue }
            
            guard let appId = Int64(cols[aIdx]) else { continue }
            let dateStr = cols[cIdx]
            let typeStr = cols[tIdx]
            let updateStr: String? = cols[uIdx].isEmpty ? nil : cols[uIdx]
            
            let date = parseDate(dateStr)
            let type = EventType(rawValue: typeStr) ?? .update
            var timezoneStr: String? = nil
            if let tzIdx = tzIdx, tzIdx < cols.count {
                timezoneStr = cols[tzIdx].isEmpty ? nil : cols[tzIdx]
            }
            
            var entry = LedgerEntry(
                createdAt: date,
                type: type,
                applicationId: appId,
                update: updateStr,
                timezone: timezoneStr
            )
            try service.addLedgerEntry(&entry)
        }
        try service.syncAutoIncrementSequences()
    }
}
