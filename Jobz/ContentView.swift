import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarItem? = .dashboard
    
    enum SidebarItem: Hashable {
        case dashboard
        case applications
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: SidebarItem.dashboard) {
                    Label("Dashboard", systemImage: "house")
                }
                NavigationLink(value: SidebarItem.applications) {
                    Label("Applications", systemImage: "list.bullet")
                }
            }
            .navigationTitle("Jobz")
        } detail: {
            switch selection {
            case .dashboard:
                DashboardView()
            case .applications:
                ApplicationListView()
            case nil:
                Text("Select an item from the sidebar")
            }
        }
    }
}

#Preview {
    ContentView()
}
