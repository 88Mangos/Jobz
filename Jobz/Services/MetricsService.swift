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
    
    struct TimeSeriesDataPoint: FetchableRecord, Decodable {
        let weekStart: Date
        let applications: Int
        let interviews: Int
        let oas: Int
        
        enum CodingKeys: String, CodingKey {
            case weekStart = "week_start"
            case applications
            case interviews
            case oas
        }
    }
    
    func fetchTimeSeriesData(startDate: Date?, endDate: Date?) throws -> [TimeSeriesDataPoint] {
        try dbQueue.read { db in
            var conditions: [String] = ["type IN ('Applied', 'Interview', 'Online Assessment')"]
            var arguments: [Any] = []
            
            if let start = startDate {
                conditions.append("created_at >= ?")
                arguments.append(start)
            }
            if let end = endDate {
                conditions.append("created_at <= ?")
                arguments.append(end)
            }
            
            let whereClause = conditions.joined(separator: " AND ")
            
            let sql = """
            SELECT 
                date(created_at, '-' || strftime('%w', created_at) || ' days') as week_start,
                SUM(CASE WHEN type = 'Applied' THEN 1 ELSE 0 END) as applications,
                SUM(CASE WHEN type = 'Interview' THEN 1 ELSE 0 END) as interviews,
                SUM(CASE WHEN type = 'Online Assessment' THEN 1 ELSE 0 END) as oas
            FROM ledger
            WHERE \(whereClause)
            GROUP BY week_start
            ORDER BY week_start ASC
            """
            
            return try TimeSeriesDataPoint.fetchAll(db, sql: sql, arguments: StatementArguments(arguments) ?? StatementArguments())
        }
    }
}
