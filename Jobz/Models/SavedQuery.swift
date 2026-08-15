import Foundation

struct SavedQuery: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var sql: String
    var createdAt: Date = Date()
    
    static let presets: [SavedQuery] = [
        SavedQuery(
            name: "Total Interviews Count",
            sql: "SELECT COUNT(*) AS total_interviews\nFROM ledger\nWHERE type = 'Interview';"
        ),
        SavedQuery(
            name: "Total Online Assessments Count",
            sql: "SELECT COUNT(*) AS total_assessments\nFROM ledger\nWHERE type = 'Online Assessment';"
        ),
        SavedQuery(
            name: "Total Chats Count",
            sql: "SELECT COUNT(*) AS total_chats\nFROM ledger\nWHERE type = 'Chat';"
        ),
        SavedQuery(
            name: "Key Stats Summary",
            sql: ResourceLoader.loadQuery("query_key_stats.sql")
        ),
        SavedQuery(
            name: "Application Conversion Rates",
            sql: ResourceLoader.loadQuery("query_conversion_rates.sql")
        ),
        SavedQuery(
            name: "Current Application Status Breakdown",
            sql: ResourceLoader.loadQuery("query_status_breakdown.sql")
        ),
        SavedQuery(
            name: "Monthly Activity Velocity",
            sql: ResourceLoader.loadQuery("query_monthly_velocity.sql")
        )
    ]
}
