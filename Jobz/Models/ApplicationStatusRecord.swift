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
    let location: String?
    let season: String?
    let numInterviews: Int
    let numOAs: Int
    let appliedAt: Date?
    let lastUpdated: Date
    let statusRaw: String
    
    var status: ApplicationStatus {
        ApplicationStatus(rawValue: statusRaw) ?? .pending
    }
}
