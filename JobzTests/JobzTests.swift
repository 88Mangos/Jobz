import Foundation
import XCTest
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
}

