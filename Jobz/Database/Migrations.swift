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
            try db.execute(sql: ResourceLoader.loadQuery("application_status_view_v1.sql"))
        }
        
        migrator.registerMigration("v2_schema_update_view") { db in
            try db.execute(sql: "DROP VIEW IF EXISTS application_status_view")
            try db.execute(sql: ResourceLoader.loadQuery("application_status_view_v2.sql"))
        }
        
        migrator.registerMigration("v3_ledger_timezone") { db in
            try db.alter(table: "ledger") { t in
                t.add(column: "timezone", .text)
            }
        }
        
        migrator.registerMigration("v4_revert_assessment") { db in
            try db.execute(sql: "UPDATE ledger SET type = 'Online Assessment' WHERE type = 'Assessment'")
        }
        
        try migrator.migrate(dbQueue)
    }
}
