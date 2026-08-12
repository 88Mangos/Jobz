import Foundation
import GRDB

class MetricsService {
    let dbQueue: DatabaseQueue
    
    init(dbQueue: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.dbQueue = dbQueue
    }
    
    func fetchAllStatusRecords() throws -> [ApplicationStatusRecord] {
        try dbQueue.read { db in
            try ApplicationStatusRecord.fetchAll(db, sql: "SELECT * FROM application_status_view")
        }
    }
}
