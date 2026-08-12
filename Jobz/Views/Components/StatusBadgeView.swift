import SwiftUI

struct StatusBadgeView: View {
    let status: ApplicationStatus
    
    var color: Color {
        switch status {
        case .accepted: return .green
        case .offered: return .green
        case .rejected: return .red
        case .interviewing: return .orange
        case .pending: return .blue
        case .ghosted: return .gray
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
