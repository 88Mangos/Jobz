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
            sql: """
            SELECT 
                SUM(CASE WHEN type = 'Interview' THEN 1 ELSE 0 END) AS total_interviews,
                SUM(CASE WHEN type = 'Online Assessment' THEN 1 ELSE 0 END) AS total_assessments,
                SUM(CASE WHEN type = 'Chat' THEN 1 ELSE 0 END) AS total_chats
            FROM ledger;
            """
        ),
        SavedQuery(
            name: "Application Conversion Rates",
            sql: """
            SELECT 
                COUNT(*) AS total_applications,
                COUNT(CASE WHEN numInterviews > 0 THEN 1 END) AS applications_with_interviews,
                ROUND(COUNT(CASE WHEN numInterviews > 0 THEN 1 END) * 100.0 / COUNT(*), 1) || '%' AS interview_rate,
                COUNT(CASE WHEN statusRaw IN ('Offered', 'Accepted') THEN 1 END) AS applications_with_offers,
                ROUND(COUNT(CASE WHEN statusRaw IN ('Offered', 'Accepted') THEN 1 END) * 100.0 / COUNT(*), 1) || '%' AS offer_rate
            FROM application_status_view;
            """
        ),
        SavedQuery(
            name: "Current Application Status Breakdown",
            sql: """
            SELECT 
                statusRaw AS current_status,
                COUNT(*) AS count,
                ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM application_status_view), 1) || '%' AS share
            FROM application_status_view
            GROUP BY statusRaw
            ORDER BY count DESC;
            """
        ),
        SavedQuery(
            name: "Monthly Activity Velocity",
            sql: """
            SELECT 
                strftime('%Y-%m', created_at) AS month,
                SUM(CASE WHEN type = 'Applied' THEN 1 ELSE 0 END) AS applications,
                SUM(CASE WHEN type = 'Online Assessment' THEN 1 ELSE 0 END) AS assessments,
                SUM(CASE WHEN type = 'Interview' THEN 1 ELSE 0 END) AS interviews,
                SUM(CASE WHEN type = 'Offer' THEN 1 ELSE 0 END) AS offers
            FROM ledger
            GROUP BY month
            ORDER BY month DESC;
            """
        )
    ]
}
