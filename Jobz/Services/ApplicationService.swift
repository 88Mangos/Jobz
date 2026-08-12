import Foundation
import GRDB

class ApplicationService {
    let dbQueue: DatabaseQueue
    
    init(dbQueue: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.dbQueue = dbQueue
    }
    
    func createApplication(_ application: inout JobApplication, initialEventDate: Date = Date()) throws {
        try dbQueue.write { db in
            try application.insert(db)
            
            guard let appId = application.id else { return }
            
            var initialLedger = LedgerEntry(
                createdAt: initialEventDate,
                type: .applied,
                applicationId: appId,
                update: "Initial Application"
            )
            try initialLedger.insert(db)
        }
    }
    
    func addLedgerEntry(_ entry: inout LedgerEntry) throws {
        try dbQueue.write { db in
            try entry.insert(db)
        }
    }
    
    func fetchApplications() throws -> [ApplicationStatusRecord] {
        try dbQueue.read { db in
            try ApplicationStatusRecord.fetchAll(db, sql: "SELECT * FROM application_status_view ORDER BY lastUpdated DESC")
        }
    }
    
    func fetchApplication(id: Int64) throws -> JobApplication? {
        try dbQueue.read { db in
            try JobApplication.fetchOne(db, key: id)
        }
    }
    
    func fetchLedgerEntries(for applicationId: Int64) throws -> [LedgerEntry] {
        try dbQueue.read { db in
            try LedgerEntry.filter(Column("application_id") == applicationId)
                .order(Column("created_at").desc)
                .fetchAll(db)
        }
    }
}
