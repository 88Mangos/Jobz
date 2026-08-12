import SwiftUI

struct ApplicationListView: View {
    @State private var applications: [ApplicationStatusRecord] = []
    @State private var showingNewApplicationForm = false
    private let applicationService = ApplicationService()
    
    enum ViewMode {
        case list
        case spreadsheet
    }
    
    @State private var viewMode: ViewMode = .list
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("View Mode", selection: $viewMode) {
                Text("List").tag(ViewMode.list)
                Text("Spreadsheet").tag(ViewMode.spreadsheet)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if viewMode == .list {
                List(applications) { app in
                    NavigationLink(destination: ApplicationDetailView(applicationId: app.applicationId)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(app.companyName)
                                    .font(.headline)
                                Text(app.role)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            StatusBadgeView(status: app.status)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                ApplicationDataGrid(applications: $applications, onRefresh: loadApplications)
            }
        }
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingNewApplicationForm = true
                }) {
                    Label("Add Application", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewApplicationForm) {
            NewApplicationForm(onSave: loadApplications)
        }
        .onAppear {
            loadApplications()
        }
    }
    
    private func loadApplications() {
        do {
            applications = try applicationService.fetchApplications()
        } catch {
            print("Error loading applications: \\(error)")
        }
    }
}
