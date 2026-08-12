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
            
            let databaseURL = directoryURL.appendingPathComponent("Jobz.sqlite")
            dbQueue = try DatabaseQueue(path: databaseURL.path)
            
            try AppDatabase.setupMigrations(dbQueue)
        } catch {
            os_log("Database initialization failed: %{public}@", error.localizedDescription)
            fatalError("Database initialization failed: \(error)")
        }
    }
}
