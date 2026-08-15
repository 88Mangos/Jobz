import Foundation
import XCTest
import GRDB
@testable import Jobz

final class JobzTests: XCTestCase {

    func testCSVExporterFormatting() throws {
        // Plain text
        XCTAssertEqual(CSVExporter.formatField("Hello"), "Hello")
        
        // Field with comma
        XCTAssertEqual(CSVExporter.formatField("Hello, world"), "\"Hello, world\"")
        
        // Field with quotes
        XCTAssertEqual(CSVExporter.formatField("He said \"Hello\""), "\"He said \"\"Hello\"\"\"")
        
        // Field with newlines
        XCTAssertEqual(CSVExporter.formatField("Line 1\nLine 2"), "\"Line 1\nLine 2\"")
        
        // Field with comma, quotes, and newlines
        XCTAssertEqual(CSVExporter.formatField("Note: \"Quote\", with, comma\nSecond line"), "\"Note: \"\"Quote\"\", with, comma\nSecond line\"")
    }

    func testCSVImporterParsing() throws {
        let csvText = "application_id,company_name,role,role_extra_notes,duration,season,location,notes\n1,Acme \"Corp\",Software Engineer,\"Note with \"\"quotes\"\" and , commas\",\"Full-time\",Fall 2026,\"San Francisco, CA\",\"Ginormous Note:\n- Bullet 1: line with comma, and \"\"quote\"\"\n- Bullet 2: line with space\n\n- Line after empty line in note.\"\n2,Beta,Designer,,,,\"NY\",\"Simple note\""
        
        let rows = CSVImporter.parseCSV(csvText)
        XCTAssertEqual(rows.count, 3)
        
        let headerRow = rows[0]
        XCTAssertEqual(headerRow, ["application_id", "company_name", "role", "role_extra_notes", "duration", "season", "location", "notes"])
        
        let firstRow = rows[1]
        XCTAssertEqual(firstRow[0], "1")
        XCTAssertEqual(firstRow[1], "Acme \"Corp\"")
        XCTAssertEqual(firstRow[2], "Software Engineer")
        XCTAssertEqual(firstRow[3], "Note with \"quotes\" and , commas")
        XCTAssertEqual(firstRow[4], "Full-time")
        XCTAssertEqual(firstRow[5], "Fall 2026")
        XCTAssertEqual(firstRow[6], "San Francisco, CA")
        
        let expectedNotes = "Ginormous Note:\n- Bullet 1: line with comma, and \"quote\"\n- Bullet 2: line with space\n\n- Line after empty line in note."
        XCTAssertEqual(firstRow[7], expectedNotes)
        
        let secondRow = rows[2]
        XCTAssertEqual(secondRow[0], "2")
        XCTAssertEqual(secondRow[1], "Beta")
        XCTAssertEqual(secondRow[7], "Simple note")
    }

    func testCSVRoundtripApplications() throws {
        let headers = ["application_id", "company_name", "role", "role_extra_notes", "duration", "season", "location", "notes"]
        
        let originalRows = [
            [
                "101",
                "Google, Inc. \"Alphabet\"",
                "Senior Systems Engineer (L5)",
                "Focus on \"Kernel & Memory Management\", C++, Rust\nSalary: $200,000",
                "Full-time",
                "Summer 2026",
                "Mountain View, CA / Remote",
                "Ginormous notes:\n1. Had screen with Recruiter (nice, talked about team)\n2. Technical interview 1: \"Design a lock-free queue, with O(1) ops\"\n3. System Design: Scalable logging system for 10M events/sec.\n\nPassed all rounds!"
            ],
            [
                "102",
                "Startup, LLC",
                "Founding Engineer",
                "",
                "",
                "Fall 2026",
                "New York, NY",
                "Short note with \"quotes\" & commas, plus newline\nEnd of note."
            ]
        ]
        
        let generatedCSV = CSVExporter.generateCSV(headers: headers, rows: originalRows)
        let parsedRows = CSVImporter.parseCSV(generatedCSV)
        
        XCTAssertEqual(parsedRows.count, 3)
        XCTAssertEqual(parsedRows[0], headers)
        XCTAssertEqual(parsedRows[1], originalRows[0])
        XCTAssertEqual(parsedRows[2], originalRows[1])
    }

    func testLocationParserParsing() throws {
        let defaultOptions = [
            "Remote",
            "San Francisco, CA",
            "New York, NY",
            "Seattle, WA",
            "Austin, TX",
            "Boston, MA",
            "Los Angeles, CA",
            "Chicago, IL"
        ]
        
        // Nil and empty
        XCTAssertEqual(LocationParser.parseLocations(from: nil), [])
        XCTAssertEqual(LocationParser.parseLocations(from: ""), [])
        XCTAssertEqual(LocationParser.parseLocations(from: "   "), [])
        
        // Single location with comma inside (city, state)
        let single = LocationParser.parseLocations(from: "San Francisco, CA", knownOptions: defaultOptions)
        XCTAssertEqual(single, ["San Francisco, CA"])
        
        // Multiple locations semicolon separated
        let semi = LocationParser.parseLocations(from: "San Francisco, CA; New York, NY; Remote", knownOptions: defaultOptions)
        XCTAssertEqual(semi, ["San Francisco, CA", "New York, NY", "Remote"])
        
        // Multiple locations slash separated
        let slash = LocationParser.parseLocations(from: "Mountain View, CA / Remote", knownOptions: defaultOptions)
        XCTAssertEqual(slash, ["Mountain View, CA", "Remote"])
        
        // Multiple locations comma separated using known options
        let comma = LocationParser.parseLocations(from: "San Francisco, CA, New York, NY, Austin, TX", knownOptions: defaultOptions)
        XCTAssertEqual(comma, ["San Francisco, CA", "New York, NY", "Austin, TX"])
        
        // Custom location with default options
        let customWithKnown = LocationParser.parseLocations(from: "London, UK; Remote", knownOptions: defaultOptions)
        XCTAssertEqual(customWithKnown, ["London, UK", "Remote"])
    }

    func testLocationParserFormatting() throws {
        let options = ["Remote", "San Francisco, CA", "New York, NY", "Seattle, WA"]
        
        // Empty set
        XCTAssertNil(LocationParser.formatLocations([], sortedBy: options))
        
        // Single location
        let singleResult = LocationParser.formatLocations(["San Francisco, CA"], sortedBy: options)
        XCTAssertEqual(singleResult, "San Francisco, CA")
        
        // Multiple locations preserve option order
        let multiResult = LocationParser.formatLocations(["New York, NY", "Remote", "San Francisco, CA"], sortedBy: options)
        XCTAssertEqual(multiResult, "Remote; San Francisco, CA; New York, NY")
        
        // Custom location appended
        let customResult = LocationParser.formatLocations(["Remote", "London, UK"], sortedBy: options)
        XCTAssertEqual(customResult, "Remote; London, UK")
    }

    func testSemicolonLocationsWithCommasCSVHandling() throws {
        let originalApps = [
            JobApplication(
                id: 1,
                companyName: "Apple Inc.",
                role: "iOS Engineer",
                roleExtraNotes: "Swift, SwiftUI",
                duration: "Full-time",
                season: "Fall 2026",
                location: "Cupertino, CA; Seattle, WA; Remote",
                notes: "Top choice"
            ),
            JobApplication(
                id: 2,
                companyName: "Meta",
                role: "Research Scientist",
                roleExtraNotes: "AI/ML",
                duration: "Summer 2026",
                season: "Summer 2026",
                location: "Menlo Park, CA; New York, NY; London, UK",
                notes: "Interesting team"
            )
        ]
        
        let csv = CSVExporter.generateApplicationsCSV(originalApps)
        let parsed = try CSVImporter.parseApplications(from: csv)
        
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed[0].location, "Cupertino, CA; Seattle, WA; Remote")
        XCTAssertEqual(parsed[1].location, "Menlo Park, CA; New York, NY; London, UK")
    }

    func testPureZipArchive() throws {
        let entry1 = ZipEntry(name: "test1.txt", data: Data("Hello World 123".utf8))
        let entry2 = ZipEntry(name: "nested/test2.json", data: Data("{\"key\": \"value\"}".utf8))
        
        let zip = ZipArchive.createZip(entries: [entry1, entry2])
        XCTAssertGreaterThan(zip.count, 0)
        
        let extracted = try ZipArchive.extractZip(from: zip)
        XCTAssertEqual(extracted.count, 2)
        XCTAssertEqual(extracted[0].name, "test1.txt")
        XCTAssertEqual(String(data: extracted[0].data, encoding: .utf8), "Hello World 123")
        XCTAssertEqual(extracted[1].name, "test2.json")
        XCTAssertEqual(String(data: extracted[1].data, encoding: .utf8), "{\"key\": \"value\"}")
    }

    func testBackupExportAndInspectRoundtrip() throws {
        let dbQueue = try DatabaseQueue()
        try AppDatabase.setupMigrations(dbQueue)
        let service = ApplicationService(dbQueue: dbQueue)
        
        UserDefaults.standard.set("## My Musings\n- Thoughts on system architecture.", forKey: "musingsNotesTab")
        UserDefaults.standard.set("Quick python snippet:\n```python\nprint('hello')\n```", forKey: "homePageNotesDump")
        UserDefaults.standard.set("Denver, CO|Boulder, CO", forKey: "customLocations")
        
        let testQuery = SavedQuery(name: "Test Query", sql: "SELECT * FROM application;")
        let queryData = try JSONEncoder().encode([testQuery])
        UserDefaults.standard.set(String(data: queryData, encoding: .utf8)!, forKey: "savedSQLQueriesData")
        
        let (zipURL, metadata) = try BackupService.createBackupZip(using: service)
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipURL.path))
        XCTAssertTrue(metadata.hasMusings)
        XCTAssertTrue(metadata.hasDashboardNotes)
        XCTAssertGreaterThanOrEqual(metadata.customLocationsCount, 2)
        XCTAssertGreaterThanOrEqual(metadata.savedQueriesCount, 1)
        
        let (_, inspected, cleanup) = try BackupService.inspectBackup(from: zipURL)
        defer { cleanup() }
        
        XCTAssertEqual(inspected.hasMusings, true)
        XCTAssertEqual(inspected.hasDashboardNotes, true)
        XCTAssertEqual(inspected.savedQueriesCount, metadata.savedQueriesCount)
        XCTAssertEqual(inspected.customLocationsCount, metadata.customLocationsCount)
    }

    func testBackupReplaceAllIdempotency() throws {
        let dbQueue = try DatabaseQueue()
        try AppDatabase.setupMigrations(dbQueue)
        let service = ApplicationService(dbQueue: dbQueue)
        
        // Prepare mock applications & ledger
        var app1 = JobApplication(
            id: 991,
            companyName: "Idempotency Corp",
            role: "Site Reliability Engineer",
            roleExtraNotes: "High availability",
            duration: "Full-time",
            season: "Spring 2027",
            location: "Austin, TX; Remote",
            notes: "Initial note"
        )
        try service.createApplication(&app1, skipLedger: true)
        
        var entry1 = LedgerEntry(
            ledgerId: 9901,
            createdAt: Date(timeIntervalSince1970: 1700000000),
            type: .applied,
            applicationId: 991,
            update: "Applied via referral",
            timezone: "America/Chicago"
        )
        try service.addLedgerEntry(&entry1)
        
        UserDefaults.standard.set("Idempotent Musing Note", forKey: "musingsNotesTab")
        UserDefaults.standard.set("Idempotent Dashboard Note", forKey: "homePageNotesDump")
        UserDefaults.standard.set("Miami, FL|Toronto, Canada", forKey: "customLocations")
        
        // Export to zip
        let (zipURL, _) = try BackupService.createBackupZip(using: service)
        
        // Run import in replaceAll mode multiple times sequentially
        for _ in 1...3 {
            let result = try BackupService.importBackup(from: zipURL, mode: .replaceAll, using: service)
            XCTAssertGreaterThanOrEqual(result.applicationsCount, 1)
            XCTAssertGreaterThanOrEqual(result.ledgerCount, 1)
            
            let restoredApp = try service.fetchApplication(id: 991)
            XCTAssertNotNil(restoredApp)
            XCTAssertEqual(restoredApp?.companyName, "Idempotency Corp")
            XCTAssertEqual(restoredApp?.location, "Austin, TX; Remote")
            
            let musings = UserDefaults.standard.string(forKey: "musingsNotesTab")
            XCTAssertEqual(musings, "Idempotent Musing Note")
            
            let notes = UserDefaults.standard.string(forKey: "homePageNotesDump")
            XCTAssertEqual(notes, "Idempotent Dashboard Note")
            
            let locations = UserDefaults.standard.string(forKey: "customLocations")
            XCTAssertEqual(locations, "Miami, FL|Toronto, Canada")
        }
        
        // Cleanup test entries
        try service.deleteApplications(ids: [991])
        try service.deleteLedgerEntries(ids: [9901])
    }

    func testBackupMergeMode() throws {
        let dbQueue = try DatabaseQueue()
        try AppDatabase.setupMigrations(dbQueue)
        let service = ApplicationService(dbQueue: dbQueue)
        
        // Create initial local application
        var existingApp = JobApplication(
            id: 881,
            companyName: "Local Co",
            role: "Frontend Dev",
            roleExtraNotes: nil,
            duration: "Full-time",
            season: "Fall 2026",
            location: "San Francisco, CA",
            notes: "Local note"
        )
        try service.createApplication(&existingApp, skipLedger: true)
        
        // Set local preferences
        UserDefaults.standard.set("Local Musings", forKey: "musingsNotesTab")
        UserDefaults.standard.set("Tokyo, Japan", forKey: "customLocations")
        
        // Create a backup archive from modified state
        var backupApp = JobApplication(
            id: 882,
            companyName: "Remote Co",
            role: "Backend Dev",
            roleExtraNotes: nil,
            duration: "Full-time",
            season: "Fall 2026",
            location: "Remote",
            notes: "Backup note"
        )
        try service.createApplication(&backupApp, skipLedger: true)
        UserDefaults.standard.set("Paris, France", forKey: "customLocations")
        UserDefaults.standard.set("Backup Musings", forKey: "musingsNotesTab")
        
        let (zipURL, _) = try BackupService.createBackupZip(using: service)
        
        // Now reset local to only having existingApp and Tokyo
        try service.deleteApplications(ids: [882])
        UserDefaults.standard.set("Tokyo, Japan", forKey: "customLocations")
        UserDefaults.standard.set("Local Musings", forKey: "musingsNotesTab")
        
        // Merge backup
        _ = try BackupService.importBackup(from: zipURL, mode: .merge, using: service)
        
        // Check that both applications exist
        let app881 = try service.fetchApplication(id: 881)
        let app882 = try service.fetchApplication(id: 882)
        XCTAssertNotNil(app881)
        XCTAssertNotNil(app882)
        
        // Check locations merged
        let mergedLocations = (UserDefaults.standard.string(forKey: "customLocations") ?? "").split(separator: "|").map(String.init)
        XCTAssertTrue(mergedLocations.contains("Tokyo, Japan"))
        XCTAssertTrue(mergedLocations.contains("Paris, France"))
        
        // Cleanup test entries
        try service.deleteApplications(ids: [881, 882])
    }
}


