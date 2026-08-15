import Foundation
import AppKit
import UniformTypeIdentifiers
import zlib

enum BackupImportMode: String, CaseIterable, Identifiable {
    case replaceAll = "Replace All Data (Full Restore)"
    case merge = "Merge with Existing Data"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .replaceAll:
            return "Completely wipes existing applications, ledger events, and settings before restoring the archive. Idempotent and exact snapshot restore."
        case .merge:
            return "Updates matching application and ledger IDs, appends new records, and merges custom locations and saved queries without overwriting unique local data."
        }
    }
}

struct BackupMetadata: Codable {
    var version: String = "1.0"
    var exportedAt: Date = Date()
    var appVersion: String = "1.0.0"
    var applicationCount: Int = 0
    var ledgerCount: Int = 0
    var savedQueriesCount: Int = 0
    var customLocationsCount: Int = 0
    var hasMusings: Bool = false
    var hasDashboardNotes: Bool = false
}

struct BackupImportResult {
    var applicationsCount: Int
    var ledgerCount: Int
    var savedQueriesCount: Int
    var customLocationsCount: Int
    var musingsImported: Bool
    var dashboardNotesImported: Bool
    var mode: BackupImportMode
}

enum BackupError: Error, LocalizedError {
    case stagingDirectoryFailed
    case exportZipFailed(String)
    case extractionFailed(String)
    case fileUnreadable
    case invalidBackupArchive(String)
    
    var errorDescription: String? {
        switch self {
        case .stagingDirectoryFailed:
            return "Failed to create temporary staging directory for backup."
        case .exportZipFailed(let msg):
            return "Failed to compress backup archive: \(msg)"
        case .extractionFailed(let msg):
            return "Failed to extract backup archive: \(msg)"
        case .fileUnreadable:
            return "Unable to access the selected backup file."
        case .invalidBackupArchive(let msg):
            return "Invalid backup archive: \(msg)"
        }
    }
}

struct ZipEntry {
    let name: String
    let data: Data
}

struct CRC32 {
    static let table: [UInt32] = {
        (0...255).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1 != 0) ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()
    
    static func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = table[index] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}

private extension Data {
    func readUInt16LE(at offset: Int) -> UInt16? {
        guard offset >= 0 && offset + 2 <= count else { return nil }
        let idx = startIndex + offset
        return UInt16(self[idx]) | (UInt16(self[idx + 1]) << 8)
    }
    
    func readUInt32LE(at offset: Int) -> UInt32? {
        guard offset >= 0 && offset + 4 <= count else { return nil }
        let idx = startIndex + offset
        return UInt32(self[idx]) |
               (UInt32(self[idx + 1]) << 8) |
               (UInt32(self[idx + 2]) << 16) |
               (UInt32(self[idx + 3]) << 24)
    }
    
    mutating func appendUInt16LE(_ value: UInt16) {
        let b0 = UInt8(value & 0xFF)
        let b1 = UInt8((value >> 8) & 0xFF)
        self.append(contentsOf: [b0, b1])
    }
    
    mutating func appendUInt32LE(_ value: UInt32) {
        let b0 = UInt8(value & 0xFF)
        let b1 = UInt8((value >> 8) & 0xFF)
        let b2 = UInt8((value >> 16) & 0xFF)
        let b3 = UInt8((value >> 24) & 0xFF)
        self.append(contentsOf: [b0, b1, b2, b3])
    }
}

enum ZipArchive {
    static func createZip(entries: [ZipEntry]) -> Data {
        var body = Data()
        var centralDirectory = Data()
        
        for entry in entries {
            let offset = UInt32(body.count)
            let nameData = Data(entry.name.utf8)
            let nameLength = UInt16(nameData.count)
            let uncompressedSize = UInt32(entry.data.count)
            let crcVal = CRC32.checksum(entry.data)
            
            // Local Header
            var localHeader = Data()
            localHeader.appendUInt32LE(0x04034b50) // Signature
            localHeader.appendUInt16LE(20)         // Version needed
            localHeader.appendUInt16LE(0)          // General flag
            localHeader.appendUInt16LE(0)          // Method (Store = 0)
            localHeader.appendUInt16LE(0)          // Mod time
            localHeader.appendUInt16LE(0)          // Mod date
            localHeader.appendUInt32LE(crcVal)     // CRC-32
            localHeader.appendUInt32LE(uncompressedSize) // Compressed size
            localHeader.appendUInt32LE(uncompressedSize) // Uncompressed size
            localHeader.appendUInt16LE(nameLength) // Filename length
            localHeader.appendUInt16LE(0)          // Extra field length
            localHeader.append(nameData)
            localHeader.append(entry.data)
            
            body.append(localHeader)
            
            // Central Directory Header
            var cd = Data()
            cd.appendUInt32LE(0x02014b50)          // Signature
            cd.appendUInt16LE(20)                  // Version made by
            cd.appendUInt16LE(20)                  // Version needed
            cd.appendUInt16LE(0)                   // General flag
            cd.appendUInt16LE(0)                   // Method
            cd.appendUInt16LE(0)                   // Mod time
            cd.appendUInt16LE(0)                   // Mod date
            cd.appendUInt32LE(crcVal)              // CRC-32
            cd.appendUInt32LE(uncompressedSize)    // Compressed size
            cd.appendUInt32LE(uncompressedSize)    // Uncompressed size
            cd.appendUInt16LE(nameLength)          // Filename length
            cd.appendUInt16LE(0)                   // Extra field length
            cd.appendUInt16LE(0)                   // Comment length
            cd.appendUInt16LE(0)                   // Disk number start
            cd.appendUInt16LE(0)                   // Internal attrs
            cd.appendUInt32LE(0)                   // External attrs
            cd.appendUInt32LE(offset)              // Relative offset
            cd.append(nameData)
            
            centralDirectory.append(cd)
        }
        
        let cdOffset = UInt32(body.count)
        let cdSize = UInt32(centralDirectory.count)
        let totalRecords = UInt16(entries.count)
        
        var eocd = Data()
        eocd.appendUInt32LE(0x06054b50)            // Signature
        eocd.appendUInt16LE(0)                     // Disk number
        eocd.appendUInt16LE(0)                     // Start disk
        eocd.appendUInt16LE(totalRecords)          // Records on disk
        eocd.appendUInt16LE(totalRecords)          // Total records
        eocd.appendUInt32LE(cdSize)                // Size of CD
        eocd.appendUInt32LE(cdOffset)              // Offset of CD
        eocd.appendUInt16LE(0)                     // Comment length
        
        var zipData = Data()
        zipData.append(body)
        zipData.append(centralDirectory)
        zipData.append(eocd)
        return zipData
    }
    
    static func extractZip(from data: Data) throws -> [ZipEntry] {
        var entries: [ZipEntry] = []
        var offset = 0
        let totalCount = data.count
        
        while offset + 30 <= totalCount {
            guard let sig = data.readUInt32LE(at: offset), sig == 0x04034b50 else {
                break
            }
            
            guard let method = data.readUInt16LE(at: offset + 8),
                  let compSize = data.readUInt32LE(at: offset + 18),
                  let uncompSize = data.readUInt32LE(at: offset + 22),
                  let nameLen = data.readUInt16LE(at: offset + 26),
                  let extraLen = data.readUInt16LE(at: offset + 28) else {
                break
            }
            
            let headerSize = 30 + Int(nameLen) + Int(extraLen)
            let cSize = Int(compSize)
            guard offset + headerSize + cSize <= totalCount else { break }
            
            let nameStart = data.startIndex + offset + 30
            let nameEnd = nameStart + Int(nameLen)
            let nameData = data.subdata(in: nameStart ..< nameEnd)
            let name = String(data: nameData, encoding: .utf8) ?? "file"
            
            let compStart = data.startIndex + offset + headerSize
            let compEnd = compStart + cSize
            let compressedData = data.subdata(in: compStart ..< compEnd)
            
            let entryData: Data
            if method == 0 {
                entryData = compressedData
            } else if method == 8 {
                entryData = try decompressDeflate(compressedData, expectedSize: Int(uncompSize))
            } else {
                entryData = compressedData
            }
            
            if !name.hasSuffix("/") {
                let cleanName = (name as NSString).lastPathComponent
                entries.append(ZipEntry(name: cleanName, data: entryData))
            }
            
            offset += headerSize + cSize
        }
        
        return entries
    }
    
    private static func decompressDeflate(_ data: Data, expectedSize: Int) throws -> Data {
        var stream = z_stream()
        let initRes = inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initRes == Z_OK else {
            throw BackupError.extractionFailed("zlib inflateInit error: \(initRes)")
        }
        defer { inflateEnd(&stream) }
        
        var decompressed = Data(count: max(expectedSize, 1024))
        var status: Int32 = Z_OK
        
        let contiguousData = Data(data)
        try contiguousData.withUnsafeBytes { inputPtr in
            guard let inAddr = inputPtr.baseAddress else { return }
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inAddr.assumingMemoryBound(to: Bytef.self))
            stream.avail_in = uInt(contiguousData.count)
            
            while status == Z_OK {
                let currentCapacity = decompressed.count
                if Int(stream.total_out) >= currentCapacity {
                    decompressed.count += 4096
                }
                let availableCapacity = decompressed.count
                
                decompressed.withUnsafeMutableBytes { outPtr in
                    guard let outAddr = outPtr.baseAddress else { return }
                    stream.next_out = outAddr.assumingMemoryBound(to: Bytef.self).advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(availableCapacity - Int(stream.total_out))
                    status = inflate(&stream, Z_NO_FLUSH)
                }
            }
        }
        
        guard status == Z_STREAM_END || status == Z_OK else {
            throw BackupError.extractionFailed("zlib inflate failed: \(status)")
        }
        
        decompressed.count = Int(stream.total_out)
        return decompressed
    }
}

enum BackupService {
    
    // MARK: - Export
    
    static func createBackupZip(using service: ApplicationService = ApplicationService()) throws -> (zipURL: URL, metadata: BackupMetadata) {
        var entries: [ZipEntry] = []
        
        // 1. Applications CSV
        let applications = try service.fetchRawApplications()
        let applicationsCSV = CSVExporter.generateApplicationsCSV(applications)
        entries.append(ZipEntry(name: "applications.csv", data: Data(applicationsCSV.utf8)))
        
        // 2. Ledger CSV
        let ledgerEntries = try service.fetchAllLedgerEntries()
        let ledgerCSV = CSVExporter.generateLedgerCSV(ledgerEntries)
        entries.append(ZipEntry(name: "ledger.csv", data: Data(ledgerCSV.utf8)))
        
        // 3. Musings Markdown
        let musings = UserDefaults.standard.string(forKey: "musingsNotesTab") ?? ""
        entries.append(ZipEntry(name: "musings.md", data: Data(musings.utf8)))
        
        // 4. Dashboard Notes Dump Markdown
        let dashboardNotes = UserDefaults.standard.string(forKey: "homePageNotesDump") ?? ""
        entries.append(ZipEntry(name: "dashboard_notes.md", data: Data(dashboardNotes.utf8)))
        
        // 5. Custom Saved SQL Queries JSON
        let savedQueriesRaw = UserDefaults.standard.string(forKey: "savedSQLQueriesData") ?? "[]"
        let savedQueriesData = savedQueriesRaw.data(using: .utf8) ?? Data("[]".utf8)
        entries.append(ZipEntry(name: "saved_queries.json", data: savedQueriesData))
        let savedQueriesCount = (try? JSONDecoder().decode([SavedQuery].self, from: savedQueriesData))?.count ?? 0
        
        // 6. Custom Locations JSON
        let customLocationsStr = UserDefaults.standard.string(forKey: "customLocations") ?? ""
        let customLocationsList = customLocationsStr.split(separator: "|").map(String.init)
        let customLocationsData = try JSONEncoder().encode(customLocationsList)
        entries.append(ZipEntry(name: "custom_locations.json", data: customLocationsData))
        
        // 7. Metadata JSON
        var metadata = BackupMetadata()
        metadata.version = "1.0"
        metadata.exportedAt = Date()
        metadata.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        metadata.applicationCount = applications.count
        metadata.ledgerCount = ledgerEntries.count
        metadata.savedQueriesCount = savedQueriesCount
        metadata.customLocationsCount = customLocationsList.count
        metadata.hasMusings = !musings.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        metadata.hasDashboardNotes = !dashboardNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let metadataData = try encoder.encode(metadata)
        entries.append(ZipEntry(name: "metadata.json", data: metadataData))
        
        // 8. Package entries into ZIP Data and write to temporary file
        let zipData = ZipArchive.createZip(entries: entries)
        let zipFilename = CSVExporter.generateFilename(prefix: "Jobz_Backup").replacingOccurrences(of: ".csv", with: ".zip")
        let destinationZipURL = FileManager.default.temporaryDirectory.appendingPathComponent(zipFilename)
        if FileManager.default.fileExists(atPath: destinationZipURL.path) {
            try? FileManager.default.removeItem(at: destinationZipURL)
        }
        try zipData.write(to: destinationZipURL)
        
        return (destinationZipURL, metadata)
    }
    
    /// Prompts user with NSSavePanel to save the generated backup ZIP file.
    static func promptExportBackup(using service: ApplicationService = ApplicationService(), completion: ((Result<URL, Error>) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let (tempZipURL, _) = try createBackupZip(using: service)
                
                DispatchQueue.main.async {
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.zip]
                    savePanel.nameFieldStringValue = tempZipURL.lastPathComponent
                    savePanel.canCreateDirectories = true
                    savePanel.isExtensionHidden = false
                    savePanel.title = "Export All User Data"
                    savePanel.message = "Save your Jobz complete backup archive (.zip)."
                    
                    savePanel.begin { result in
                        if result == .OK, let targetURL = savePanel.url {
                            do {
                                if FileManager.default.fileExists(atPath: targetURL.path) {
                                    try FileManager.default.removeItem(at: targetURL)
                                }
                                try FileManager.default.copyItem(at: tempZipURL, to: targetURL)
                                completion?(.success(targetURL))
                            } catch {
                                completion?(.failure(error))
                            }
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Inspection & Extraction
    
    static func inspectBackup(from zipURL: URL) throws -> (entries: [ZipEntry], metadata: BackupMetadata, cleanup: () -> Void) {
        let isScoped = zipURL.startAccessingSecurityScopedResource()
        let cleanup = {
            if isScoped {
                zipURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let data: Data
        do {
            data = try Data(contentsOf: zipURL)
        } catch {
            cleanup()
            throw BackupError.fileUnreadable
        }
        
        let entries = try ZipArchive.extractZip(from: data)
        
        var metadata = BackupMetadata()
        if let metaEntry = entries.first(where: { $0.name == "metadata.json" }) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode(BackupMetadata.self, from: metaEntry.data) {
                metadata = decoded
            }
        }
        
        let hasApps = entries.contains(where: { $0.name == "applications.csv" })
        let hasLedger = entries.contains(where: { $0.name == "ledger.csv" })
        if !hasApps && !hasLedger {
            cleanup()
            throw BackupError.invalidBackupArchive("Missing applications.csv or ledger.csv in backup archive.")
        }
        
        if let appsEntry = entries.first(where: { $0.name == "applications.csv" }),
           let content = String(data: appsEntry.data, encoding: .utf8),
           let apps = try? CSVImporter.parseApplications(from: content) {
            metadata.applicationCount = apps.count
        }
        
        if let ledgerEntry = entries.first(where: { $0.name == "ledger.csv" }),
           let content = String(data: ledgerEntry.data, encoding: .utf8),
           let list = try? CSVImporter.parseLedger(from: content) {
            metadata.ledgerCount = list.count
        }
        
        return (entries, metadata, cleanup)
    }
    
    // MARK: - Import
    
    static func importBackup(from zipURL: URL, mode: BackupImportMode, using service: ApplicationService = ApplicationService()) throws -> BackupImportResult {
        let (entries, _, cleanup) = try inspectBackup(from: zipURL)
        defer { cleanup() }
        
        // 1. Applications
        var importedApplications: [JobApplication] = []
        if let appsEntry = entries.first(where: { $0.name == "applications.csv" }),
           let content = String(data: appsEntry.data, encoding: .utf8) {
            importedApplications = try CSVImporter.parseApplications(from: content)
        }
        
        // 2. Ledger
        var importedLedger: [LedgerEntry] = []
        if let ledgerEntry = entries.first(where: { $0.name == "ledger.csv" }),
           let content = String(data: ledgerEntry.data, encoding: .utf8) {
            importedLedger = try CSVImporter.parseLedger(from: content)
        }
        
        // 3. Musings
        var importedMusings: String? = nil
        if let musingsEntry = entries.first(where: { $0.name == "musings.md" }),
           let content = String(data: musingsEntry.data, encoding: .utf8) {
            importedMusings = content
        }
        
        // 4. Dashboard Notes Dump
        var importedDashboardNotes: String? = nil
        if let notesEntry = entries.first(where: { $0.name == "dashboard_notes.md" }),
           let content = String(data: notesEntry.data, encoding: .utf8) {
            importedDashboardNotes = content
        }
        
        // 5. Saved Queries
        var importedSavedQueries: [SavedQuery] = []
        if let queriesEntry = entries.first(where: { $0.name == "saved_queries.json" }),
           let list = try? JSONDecoder().decode([SavedQuery].self, from: queriesEntry.data) {
            importedSavedQueries = list
        }
        
        // 6. Custom Locations
        var importedLocations: [String] = []
        if let locEntry = entries.first(where: { $0.name == "custom_locations.json" }),
           let list = try? JSONDecoder().decode([String].self, from: locEntry.data) {
            importedLocations = list
        }
        
        switch mode {
        case .replaceAll:
            // 1 & 2: Database tables
            try service.restoreAllApplicationsAndLedger(applications: importedApplications, ledgerEntries: importedLedger)
            
            // 3: Musings
            if let musings = importedMusings {
                UserDefaults.standard.set(musings, forKey: "musingsNotesTab")
            } else {
                UserDefaults.standard.removeObject(forKey: "musingsNotesTab")
            }
            
            // 4: Dashboard Notes
            if let notes = importedDashboardNotes {
                UserDefaults.standard.set(notes, forKey: "homePageNotesDump")
            } else {
                UserDefaults.standard.removeObject(forKey: "homePageNotesDump")
            }
            
            // 5: Saved Queries
            if let encodedData = try? JSONEncoder().encode(importedSavedQueries),
               let jsonString = String(data: encodedData, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: "savedSQLQueriesData")
            }
            
            // 6: Custom Locations
            let customLocStr = importedLocations.joined(separator: "|")
            UserDefaults.standard.set(customLocStr, forKey: "customLocations")
            
        case .merge:
            // 1 & 2: Database tables upsert
            try service.mergeApplicationsAndLedger(applications: importedApplications, ledgerEntries: importedLedger)
            
            // 3: Musings merge
            if let imported = importedMusings, !imported.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let current = UserDefaults.standard.string(forKey: "musingsNotesTab") ?? ""
                if current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    UserDefaults.standard.set(imported, forKey: "musingsNotesTab")
                } else if !current.contains(imported.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    let merged = current + "\n\n---\n### Restored Musings\n" + imported
                    UserDefaults.standard.set(merged, forKey: "musingsNotesTab")
                }
            }
            
            // 4: Dashboard Notes merge
            if let imported = importedDashboardNotes, !imported.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let current = UserDefaults.standard.string(forKey: "homePageNotesDump") ?? ""
                if current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    UserDefaults.standard.set(imported, forKey: "homePageNotesDump")
                } else if !current.contains(imported.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    let merged = current + "\n\n---\n### Restored Notes\n" + imported
                    UserDefaults.standard.set(merged, forKey: "homePageNotesDump")
                }
            }
            
            // 5: Saved Queries merge
            var currentQueries: [SavedQuery] = []
            if let currentData = UserDefaults.standard.string(forKey: "savedSQLQueriesData")?.data(using: .utf8),
               let list = try? JSONDecoder().decode([SavedQuery].self, from: currentData) {
                currentQueries = list
            }
            var mergedQueries = currentQueries
            for importedQuery in importedSavedQueries {
                if !mergedQueries.contains(where: { $0.id == importedQuery.id || ($0.name == importedQuery.name && $0.sql == importedQuery.sql) }) {
                    mergedQueries.append(importedQuery)
                }
            }
            if let encodedData = try? JSONEncoder().encode(mergedQueries),
               let jsonString = String(data: encodedData, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: "savedSQLQueriesData")
            }
            
            // 6: Custom Locations merge
            let currentLocations = (UserDefaults.standard.string(forKey: "customLocations") ?? "")
                .split(separator: "|")
                .map(String.init)
            var mergedLocations = currentLocations
            for loc in importedLocations {
                let trimmed = loc.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !mergedLocations.contains(trimmed) {
                    mergedLocations.append(trimmed)
                }
            }
            UserDefaults.standard.set(mergedLocations.joined(separator: "|"), forKey: "customLocations")
        }
        
        return BackupImportResult(
            applicationsCount: importedApplications.count,
            ledgerCount: importedLedger.count,
            savedQueriesCount: importedSavedQueries.count,
            customLocationsCount: importedLocations.count,
            musingsImported: importedMusings != nil,
            dashboardNotesImported: importedDashboardNotes != nil,
            mode: mode
        )
    }
}
