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
    
    static func parseCSV(_ content: String) -> [[String]] {
        var text = content
        if text.hasPrefix("\u{FEFF}") {
            text.removeFirst()
        }
        
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        var isStartOfField = true
        
        let scalars = Array(text.unicodeScalars)
        let count = scalars.count
        var index = 0
        
        while index < count {
            let scalar = scalars[index]
            
            if isStartOfField {
                if scalar == "\"" {
                    insideQuotes = true
                    isStartOfField = false
                    index += 1
                    continue
                } else {
                    insideQuotes = false
                    isStartOfField = false
                }
            }
            
            if insideQuotes {
                if scalar == "\"" {
                    if index + 1 < count && scalars[index + 1] == "\"" {
                        currentField.append("\"")
                        index += 2
                    } else {
                        insideQuotes = false
                        index += 1
                    }
                } else {
                    currentField.append(Character(scalar))
                    index += 1
                }
            } else {
                if scalar == "," {
                    currentRow.append(currentField)
                    currentField = ""
                    isStartOfField = true
                    index += 1
                } else if scalar == "\r" {
                    currentRow.append(currentField)
                    currentField = ""
                    rows.append(currentRow)
                    currentRow = []
                    isStartOfField = true
                    
                    if index + 1 < count && scalars[index + 1] == "\n" {
                        index += 2
                    } else {
                        index += 1
                    }
                } else if scalar == "\n" {
                    currentRow.append(currentField)
                    currentField = ""
                    rows.append(currentRow)
                    currentRow = []
                    isStartOfField = true
                    index += 1
                } else {
                    currentField.append(Character(scalar))
                    index += 1
                }
            }
        }
        
        if !currentField.isEmpty || !currentRow.isEmpty || !isStartOfField {
            currentRow.append(currentField)
            rows.append(currentRow)
        }
        
        if let lastRow = rows.last, lastRow.count == 1 && lastRow[0].isEmpty {
            rows.removeLast()
        }
        
        return rows
    }
    
    static func parseCSVRow(_ line: String) -> [String] {
        return parseCSV(line).first ?? []
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
    
    static func parseApplications(from content: String) throws -> [JobApplication] {
        let rows = parseCSV(content)
        guard rows.count > 0 else { return [] }
        
        let expectedHeaders = Set(["company_name", "role", "duration", "season", "location", "notes"])
        let actualHeaders = rows[0].map { 
            $0.trimmingCharacters(in: .init(charactersIn: "\u{FEFF}\r\n ")).lowercased()
        }
        let actualHeaderSet = Set(actualHeaders)
        
        let matched = expectedHeaders.intersection(actualHeaderSet)
        let missing = expectedHeaders.subtracting(actualHeaderSet)
        let extraneous = actualHeaderSet.subtracting(expectedHeaders)
        
        if !missing.isEmpty {
            throw CSVError.validationFailed(matched: Array(matched), missing: Array(missing), extraneous: Array(extraneous))
        }
        
        guard rows.count > 1 else { return [] }
        
        let aIdx = actualHeaders.firstIndex(of: "application_id")
        let cIdx = actualHeaders.firstIndex(of: "company_name")!
        let rIdx = actualHeaders.firstIndex(of: "role")!
        let rnIdx = actualHeaders.firstIndex(of: "role_extra_notes")
        let dIdx = actualHeaders.firstIndex(of: "duration")!
        let sIdx = actualHeaders.firstIndex(of: "season")!
        let lIdx = actualHeaders.firstIndex(of: "location")!
        let nIdx = actualHeaders.firstIndex(of: "notes")!
        
        var applications: [JobApplication] = []
        
        for i in 1..<rows.count {
            let cols = rows[i]
            if cols.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }
            
            func getCol(_ idx: Int?) -> String? {
                guard let idx = idx, idx < cols.count else { return nil }
                let trimmed = cols[idx].trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : cols[idx]
            }
            
            let companyName = getCol(cIdx) ?? ""
            let role = getCol(rIdx) ?? ""
            let roleExtraNotes = getCol(rnIdx)
            let duration = getCol(dIdx)
            let season = getCol(sIdx)
            let location = getCol(lIdx)
            let notes = getCol(nIdx)
            
            var appId: Int64? = nil
            if let aStr = getCol(aIdx), let parsedId = Int64(aStr) {
                appId = parsedId
            }
            
            let app = JobApplication(
                id: appId,
                companyName: companyName,
                role: role,
                roleExtraNotes: roleExtraNotes,
                duration: duration,
                season: season,
                location: location,
                notes: notes
            )
            applications.append(app)
        }
        return applications
    }
    
    static func parseLedger(from content: String) throws -> [LedgerEntry] {
        let rows = parseCSV(content)
        guard rows.count > 0 else { return [] }
        
        let expectedHeaders = Set(["application_id", "created_at", "type", "update"])
        let actualHeaders = rows[0].map { 
            $0.trimmingCharacters(in: .init(charactersIn: "\u{FEFF}\r\n ")).lowercased()
        }
        let actualHeaderSet = Set(actualHeaders)
        
        let matched = expectedHeaders.intersection(actualHeaderSet)
        let missing = expectedHeaders.subtracting(actualHeaderSet)
        let extraneous = actualHeaderSet.subtracting(expectedHeaders)
        
        if !missing.isEmpty {
            throw CSVError.validationFailed(matched: Array(matched), missing: Array(missing), extraneous: Array(extraneous))
        }
        
        guard rows.count > 1 else { return [] }
        
        let lidIdx = actualHeaders.firstIndex(of: "ledger_id")
        let aIdx = actualHeaders.firstIndex(of: "application_id")!
        let cIdx = actualHeaders.firstIndex(of: "created_at")!
        let tIdx = actualHeaders.firstIndex(of: "type")!
        let uIdx = actualHeaders.firstIndex(of: "update")!
        let tzIdx = actualHeaders.firstIndex(of: "timezone")
        
        var entries: [LedgerEntry] = []
        
        for i in 1..<rows.count {
            let cols = rows[i]
            if cols.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }
            
            func getCol(_ idx: Int?) -> String? {
                guard let idx = idx, idx < cols.count else { return nil }
                let trimmed = cols[idx].trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : cols[idx]
            }
            
            guard let aStr = getCol(aIdx), let appId = Int64(aStr) else { continue }
            guard let dateStr = getCol(cIdx) else { continue }
            let typeStr = getCol(tIdx) ?? "Update"
            let updateStr = getCol(uIdx)
            let timezoneStr = getCol(tzIdx)
            
            var ledgerId: Int64? = nil
            if let lStr = getCol(lidIdx), let parsedLid = Int64(lStr) {
                ledgerId = parsedLid
            }
            
            let date = parseDate(dateStr)
            let type = EventType(rawValue: typeStr) ?? .update
            
            let entry = LedgerEntry(
                ledgerId: ledgerId,
                createdAt: date,
                type: type,
                applicationId: appId,
                update: updateStr,
                timezone: timezoneStr
            )
            entries.append(entry)
        }
        return entries
    }
    
    static func importApplications(from url: URL, using service: ApplicationService) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVError.fileUnreadable
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let apps = try parseApplications(from: content)
        for var app in apps {
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
        let entries = try parseLedger(from: content)
        for var entry in entries {
            try service.addLedgerEntry(&entry)
        }
        try service.syncAutoIncrementSequences()
    }
}
