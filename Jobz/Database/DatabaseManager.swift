import Foundation
import GRDB
import os.log

public class DatabaseManager {
    public static let shared = DatabaseManager()
    
    public var dbQueue: DatabaseQueue!
    
    private init() {
        do {
            let appSupportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let directoryURL = appSupportURL.appendingPathComponent("Jobz", isDirectory: true)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            
            let useTestDB = ProcessInfo.processInfo.arguments.contains("-useTestDB") || ProcessInfo.processInfo.environment["USE_TEST_DB"] == "1"
            let dbName = useTestDB ? "Jobz_Test.sqlite" : "Jobz.sqlite"
            
            if useTestDB {
                os_log("Using TEST database: %{public}@", dbName)
            }
            
            let databaseURL = directoryURL.appendingPathComponent(dbName)
            dbQueue = try DatabaseQueue(path: databaseURL.path)
            
            try AppDatabase.setupMigrations(dbQueue)
        } catch {
            os_log("Database initialization failed: %{public}@", error.localizedDescription)
            fatalError("Database initialization failed: \(error)")
        }
    }
    
    public func executeSQL(_ sql: String) throws -> (columns: [String], rows: [[String: String]]) {
        var finalSql = sql.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalSql.hasSuffix(";") {
            finalSql.removeLast()
        }
        
        // Ensure read-only safety by using read method which prevents modifications
        return try dbQueue.read { db in
            // Execute the query with a limit of 100 rows for safety
            let wrappedSql = "SELECT * FROM (\(finalSql)) LIMIT 100"
            let rows = try Row.fetchAll(db, sql: wrappedSql)
            
            guard let firstRow = rows.first else {
                return ([], [])
            }
            
            let columns = Array(firstRow.columnNames)
            let resultRows = rows.map { row -> [String: String] in
                var dict: [String: String] = [:]
                for column in columns {
                    let dbValue: DatabaseValue = row[column]
                    if dbValue.isNull {
                        dict[column] = "NULL"
                    } else {
                        dict[column] = dbValue.description
                    }
                }
                return dict
            }
            
            return (columns, resultRows)
        }
    }
}
