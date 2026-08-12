import Foundation
import GRDB

class ApplicationService {
    let dbQueue: DatabaseQueue
    
    init(dbQueue: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.dbQueue = dbQueue
    }
    
    func createApplication(_ application: inout JobApplication, initialEventDate: Date = Date(), skipLedger: Bool = false) throws {
        try dbQueue.write { db in
            try application.insert(db)
            
            guard !skipLedger else { return }
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
    
    func updateApplicationId(oldId: Int64, newId: Int64) throws {
        try dbQueue.write { db in
            guard var oldApp = try JobApplication.fetchOne(db, key: oldId) else { return }
            oldApp.id = newId
            try oldApp.insert(db)
            try db.execute(sql: "UPDATE ledger SET application_id = ? WHERE application_id = ?", arguments: [newId, oldId])
            try JobApplication.deleteOne(db, key: oldId)
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
    
    func fetchRawApplications() throws -> [JobApplication] {
        try dbQueue.read { db in
            try JobApplication.fetchAll(db)
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
    
    func fetchAllLedgerEntries() throws -> [LedgerEntry] {
        try dbQueue.read { db in
            try LedgerEntry.order(Column("created_at").desc).fetchAll(db)
        }
    }
    
    func deleteApplications(ids: Set<Int64>) throws {
        _ = try dbQueue.write { db in
            try JobApplication.deleteAll(db, keys: Array(ids))
        }
    }
    
    func deleteLedgerEntries(ids: Set<Int64>) throws {
        _ = try dbQueue.write { db in
            try LedgerEntry.deleteAll(db, keys: Array(ids))
        }
    }
    
    func syncAutoIncrementSequences() throws {
        try dbQueue.write { db in
            try db.execute(sql: "UPDATE sqlite_sequence SET seq = COALESCE((SELECT MAX(application_id) FROM application), 0) WHERE name = 'application'")
            try db.execute(sql: "UPDATE sqlite_sequence SET seq = COALESCE((SELECT MAX(ledger_id) FROM ledger), 0) WHERE name = 'ledger'")
        }
    }
}
