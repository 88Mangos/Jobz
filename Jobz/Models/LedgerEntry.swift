import Foundation
import SwiftUI
import GRDB

enum EventType: String, Codable, CaseIterable, Identifiable {
    case applied = "Applied"
    case oa = "Online Assessment"
    case interview = "Interview"
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
    
    var sortUpdate: String { update ?? "" }
    var sortId: Int64 { id ?? 0 }
    static let databaseTableName = "ledger"

    enum CodingKeys: String, CodingKey {
        case id = "ledger_id"
        case createdAt = "created_at"
        case type
        case applicationId = "application_id"
        case update
    }
}
