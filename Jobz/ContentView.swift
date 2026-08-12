import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarItem? = .dashboard
    
    enum SidebarItem: Hashable {
        case dashboard
        case summary
        case applications
        case ledger
        case sqlLab
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: SidebarItem.dashboard) {
                    Label("Dashboard", systemImage: "house")
                }
                NavigationLink(value: SidebarItem.summary) {
                    Label("Summary", systemImage: "chart.bar.doc.horizontal")
                }
                NavigationLink(value: SidebarItem.applications) {
                    Label("Applications", systemImage: "tablecells")
                }
                NavigationLink(value: SidebarItem.ledger) {
                    Label("Ledger", systemImage: "text.book.closed")
                }
                NavigationLink(value: SidebarItem.sqlLab) {
                    Label("SQL Lab", systemImage: "server.rack")
                }
            }
            .navigationTitle("Jobz")
        } detail: {
            NavigationStack {
                switch selection {
                case .dashboard:
                    DashboardView()
                case .summary:
                    SummaryTableView()
                case .applications:
                    ApplicationTableView()
                case .ledger:
                    LedgerTableView()
                case .sqlLab:
                    SQLLabView()
                case nil:
                    Text("Select an item from the sidebar")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
