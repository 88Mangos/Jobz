import Foundation
import SwiftUI
import GRDB

enum EventType: String, Codable, CaseIterable, Identifiable {
    case applied = "Applied"
    case oa = "Assessment"
    case interview = "Interview"
    case chat = "Chat"
    case assessmentReceived = "Assessment Received"
    case assessmentReminder = "Assessment Reminder"
    case update = "Update"
    case offer = "Offer"
    case rejection = "Rejection"
    case accepted = "Accepted"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .applied: return .blue
        case .oa: return .purple
        case .interview: return .orange
        case .chat: return .yellow
        case .assessmentReminder: return .pink
        case .assessmentReceived: return .indigo
        case .update: return .teal
        case .offer: return .mint
        case .rejection: return .red
        case .accepted: return .green
        }
    }
}

struct LedgerEntry: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    var id: Int64?
    var createdAt: Date
    var type: EventType
    var applicationId: Int64
    var update: String?
    var timezone: String? = nil
    
    var createdAtUtc: Date? {
        guard let tzId = timezone, let tz = TimeZone(identifier: tzId) else { return nil }
        let offset = tz.secondsFromGMT(for: createdAt)
        return createdAt.addingTimeInterval(TimeInterval(-offset))
    }
    
    var sortUpdate: String { update ?? "" }
    var sortId: Int64 { id ?? 0 }
    static let databaseTableName = "ledger"

    enum CodingKeys: String, CodingKey {
        case id = "ledger_id"
        case createdAt = "created_at"
        case type
        case applicationId = "application_id"
        case update
        case timezone
    }
}

extension TimeZone {
    static func formattedLabel(for identifier: String, date: Date) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return identifier }
        let gmtOffset = tz.secondsFromGMT(for: date)
        let hours = gmtOffset / 3600
        let minutes = abs(gmtOffset % 3600) / 60
        let sign = hours >= 0 ? "+" : "-"
        let gmtString = String(format: "GMT%@%02d:%02d", sign, abs(hours), minutes)
        
        let abbrev = tz.abbreviation(for: date) ?? ""
        
        let city: String
        switch identifier {
        case "America/New_York": city = "New York"
        case "America/Chicago": city = "Chicago"
        case "America/Los_Angeles": city = "San Francisco"
        case "UTC": city = "Zulu"
        default: city = identifier.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? identifier
        }
        
        return "\(gmtString) (\(abbrev)) - \(city)"
    }
}
