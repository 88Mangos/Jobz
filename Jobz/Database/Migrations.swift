import Foundation
import GRDB

struct AppDatabase {
    static func setupMigrations(_ dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1_schema") { db in
            // Application Table
            try db.create(table: "application") { t in
                t.autoIncrementedPrimaryKey("application_id")
                t.column("company_name", .text).notNull()
                t.column("role", .text).notNull()
                t.column("role_extra_notes", .text)
                t.column("duration", .text)
                t.column("season", .text)
                t.column("location", .text)
                t.column("notes", .text)
            }
            
            // Ledger Table
            try db.create(table: "ledger") { t in
                t.autoIncrementedPrimaryKey("ledger_id")
                t.column("created_at", .datetime).notNull()
                t.column("type", .text).notNull()
                t.column("application_id", .integer)
                    .notNull()
                    .references("application", onDelete: .cascade)
                t.column("update", .text)
            }
            
            // Status View with Ghosting Logic (2 Months = 60 days cutoff)
            try db.execute(sql: """
                CREATE VIEW application_status_view AS
                SELECT 
                    a.application_id,
                    a.company_name,
                    a.role,
                    a.location,
                    a.season,
                    
                    -- Derived Interview & OA counts
                    COUNT(CASE WHEN l.type = 'Interview' THEN 1 END) AS numInterviews,
                    COUNT(CASE WHEN l.type = 'Online Assessment' THEN 1 END) AS numOAs,
                    
                    -- Applied date & Last updated timestamp
                    MIN(CASE WHEN l.type = 'Applied' THEN l.created_at END) AS appliedAt,
                    MAX(l.created_at) AS lastUpdated,
                    
                    -- Status derivation hierarchy
                    CASE 
                        WHEN SUM(CASE WHEN l.type = 'Accepted' THEN 1 ELSE 0 END) > 0 THEN 'Accepted'
                        WHEN SUM(CASE WHEN l.type = 'Offer' THEN 1 ELSE 0 END) > 0 THEN 'Offered'
                        WHEN SUM(CASE WHEN l.type = 'Rejection' THEN 1 ELSE 0 END) > 0 THEN 'Rejected'
                        WHEN SUM(CASE WHEN l.type = 'Interview' THEN 1 ELSE 0 END) > 0 THEN 'Interviewing'
                        
                        -- Ghosted if not in a final/interview state and inactive for > 60 days
                        WHEN MAX(l.created_at) < datetime('now', '-60 days') THEN 'Ghosted'
                        
                        ELSE 'Pending'
                    END AS statusRaw
                    
                FROM application a
                LEFT JOIN ledger l ON a.application_id = l.application_id
                GROUP BY a.application_id;
            """)
        }
        
        migrator.registerMigration("v2_schema_update_view") { db in
            try db.execute(sql: "DROP VIEW IF EXISTS application_status_view")
            try db.execute(sql: """
                CREATE VIEW application_status_view AS
                SELECT 
                    a.application_id,
                    a.company_name,
                    a.role,
                    a.role_extra_notes,
                    a.duration,
                    a.season,
                    a.location,
                    a.notes,
                    
                    -- Derived Interview & OA counts
                    COUNT(CASE WHEN l.type = 'Interview' THEN 1 END) AS numInterviews,
                    COUNT(CASE WHEN l.type = 'Online Assessment' THEN 1 END) AS numOAs,
                    
                    -- Applied date & Last updated timestamp
                    MIN(CASE WHEN l.type = 'Applied' THEN l.created_at END) AS appliedAt,
                    MAX(l.created_at) AS lastUpdated,
                    
                    -- Status derivation hierarchy
                    CASE 
                        WHEN SUM(CASE WHEN l.type = 'Accepted' THEN 1 ELSE 0 END) > 0 THEN 'Accepted'
                        WHEN SUM(CASE WHEN l.type = 'Offer' THEN 1 ELSE 0 END) > 0 THEN 'Offered'
                        WHEN SUM(CASE WHEN l.type = 'Rejection' THEN 1 ELSE 0 END) > 0 THEN 'Rejected'
                        WHEN SUM(CASE WHEN l.type = 'Interview' THEN 1 ELSE 0 END) > 0 THEN 'Interviewing'
                        
                        -- Ghosted if not in a final/interview state and inactive for > 60 days
                        WHEN MAX(l.created_at) < datetime('now', '-60 days') THEN 'Ghosted'
                        
                        ELSE 'Pending'
                    END AS statusRaw
                    
                FROM application a
                LEFT JOIN ledger l ON a.application_id = l.application_id
                GROUP BY a.application_id;
            """)
        }
        
        migrator.registerMigration("v3_ledger_timezone") { db in
            try db.alter(table: "ledger") { t in
                t.add(column: "timezone", .text)
            }
        }
        
        try migrator.migrate(dbQueue)
    }
}
