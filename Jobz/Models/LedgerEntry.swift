import Foundation
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
