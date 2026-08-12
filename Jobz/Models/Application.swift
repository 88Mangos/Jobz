import Foundation
import GRDB

struct JobApplication: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    var id: Int64?
    var companyName: String
    var role: String
    var roleExtraNotes: String?
    var duration: String?  // e.g. "Full-time", "Summer 2026"
    var season: String?    // e.g. "Fall 2026"
    var location: String?
    var notes: String?

    var sortRoleExtraNotes: String { roleExtraNotes ?? "" }
    var sortDuration: String { duration ?? "" }
    var sortSeason: String { season ?? "" }
    var sortLocation: String { location ?? "" }
    var sortNotes: String { notes ?? "" }
    var sortId: Int64 { id ?? 0 }

    static let databaseTableName = "application"

    enum CodingKeys: String, CodingKey {
        case id = "application_id"
        case companyName = "company_name"
        case role
        case roleExtraNotes = "role_extra_notes"
        case duration
        case season
        case location
        case notes
    }
}
