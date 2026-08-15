import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarItem? = .dashboard
    
    enum SidebarItem: Hashable {
        case dashboard
        case summary
        case applications
        case ledger
        case scratchpad
        case sqlLab
        case quickAdd
        case about
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Main") {
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
                    NavigationLink(value: SidebarItem.scratchpad) {
                        Label("Scratchpad", systemImage: "square.and.pencil")
                    }
                    NavigationLink(value: SidebarItem.quickAdd) {
                        Label("Quick Add", systemImage: "plus")
                    }
                    NavigationLink(value: SidebarItem.sqlLab) {
                        Label("SQL Lab", systemImage: "server.rack")
                    }
                }
                
                Section("Information") {
                    NavigationLink(value: SidebarItem.about) {
                        Label("About & Licenses", systemImage: "info.circle")
                    }
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
                case .scratchpad:
                    ScratchpadView()
                case .quickAdd:
                    QuickAddView()
                case .sqlLab:
                    SQLLabView()
                case .about:
                    AboutView()
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
