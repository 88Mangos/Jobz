import Foundation
import GRDB

enum ApplicationStatus: String, Codable, CaseIterable, Identifiable {
    case accepted = "Accepted"
    case offered = "Offered"
    case rejected = "Rejected"
    case interviewing = "Interviewing"
    case pending = "Pending"
    case ghosted = "Ghosted"
    
    var id: String { rawValue }
}

struct ApplicationStatusRecord: FetchableRecord, Decodable, Identifiable {
    var id: Int64 { applicationId }
    
    let applicationId: Int64
    let companyName: String
    let role: String
    let roleExtraNotes: String?
    let duration: String?
    let location: String?
    let season: String?
    let notes: String?
    let numInterviews: Int
    let numOAs: Int
    let appliedAt: Date?
    let lastUpdated: Date?
    let statusRaw: String
    
    var sortLocation: String { location ?? "" }
    var sortRoleExtraNotes: String { roleExtraNotes ?? "" }
    var sortDuration: String { duration ?? "" }
    var sortSeason: String { season ?? "" }
    var sortNotes: String { notes ?? "" }
    var sortAppliedAt: Date { appliedAt ?? Date.distantPast }
    var sortLastUpdated: Date { lastUpdated ?? Date.distantPast }
    
    enum CodingKeys: String, CodingKey {
        case applicationId = "application_id"
        case companyName = "company_name"
        case role
        case roleExtraNotes = "role_extra_notes"
        case duration
        case location
        case season
        case notes
        case numInterviews
        case numOAs
        case appliedAt
        case lastUpdated
        case statusRaw
    }
    
    var status: ApplicationStatus {
        ApplicationStatus(rawValue: statusRaw) ?? .pending
    }
}
