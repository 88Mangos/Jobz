import Foundation
import GRDB

struct ApplicationService {
    let dbQueue: DatabaseQueue
    
    init(dbQueue: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.dbQueue = dbQueue
    }
    
    func createApplication(_ application: inout JobApplication, initialEventDate: Date = Date(), timezone: String? = nil, skipLedger: Bool = false) throws {
        application = try dbQueue.write { db in
            var app = application
            try app.insert(db)
            if app.id == nil {
                app.id = db.lastInsertedRowID
            }
            
            if !skipLedger, let appId = app.id {
                var initialLedger = LedgerEntry(
                    createdAt: initialEventDate,
                    type: .applied,
                    applicationId: appId,
                    update: "Initial Application",
                    timezone: timezone
                )
                try initialLedger.insert(db)
                if initialLedger.ledgerId == nil {
                    initialLedger.ledgerId = db.lastInsertedRowID
                }
            }
            return app
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
        entry = try dbQueue.write { db in
            var e = entry
            try e.insert(db)
            if e.ledgerId == nil {
                e.ledgerId = db.lastInsertedRowID
            }
            return e
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
    
    func restoreAllApplicationsAndLedger(applications: [JobApplication], ledgerEntries: [LedgerEntry]) throws {
        try dbQueue.write { db in
            try db.execute(sql: "PRAGMA foreign_keys = OFF;")
            try db.execute(sql: "DELETE FROM ledger;")
            try db.execute(sql: "DELETE FROM application;")
            try db.execute(sql: "PRAGMA foreign_keys = ON;")
            
            for var app in applications {
                try app.insert(db)
            }
            for var entry in ledgerEntries {
                try entry.insert(db)
            }
            
            try db.execute(sql: "UPDATE sqlite_sequence SET seq = COALESCE((SELECT MAX(application_id) FROM application), 0) WHERE name = 'application'")
            try db.execute(sql: "UPDATE sqlite_sequence SET seq = COALESCE((SELECT MAX(ledger_id) FROM ledger), 0) WHERE name = 'ledger'")
        }
    }
    
    func mergeApplicationsAndLedger(applications: [JobApplication], ledgerEntries: [LedgerEntry]) throws {
        try dbQueue.write { db in
            for var app in applications {
                try app.save(db)
            }
            for var entry in ledgerEntries {
                try entry.save(db)
            }
            
            try db.execute(sql: "UPDATE sqlite_sequence SET seq = COALESCE((SELECT MAX(application_id) FROM application), 0) WHERE name = 'application'")
            try db.execute(sql: "UPDATE sqlite_sequence SET seq = COALESCE((SELECT MAX(ledger_id) FROM ledger), 0) WHERE name = 'ledger'")
        }
    }
}

