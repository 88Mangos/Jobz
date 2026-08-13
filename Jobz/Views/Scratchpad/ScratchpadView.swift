import SwiftUI
import GRDB
import Textual

struct ScratchpadView: View {
    @State private var applications: [ApplicationStatusRecord] = []
    @State private var timeline: [LedgerEntry] = []
    
    @State private var selectedApplicationId: Int64? = nil
    @State private var date = Date()
    @State private var timezone: String = {
        let currentId = TimeZone.current.identifier
        let supported = ["America/New_York", "America/Chicago", "America/Los_Angeles", "UTC"]
        return supported.contains(currentId) ? currentId : "America/New_York"
    }()
    @State private var type: EventType = .update
    @State private var notes = ""
    
    private let applicationService = ApplicationService()
    
    private var supportedTimezones: [String] {
        var zones = ["America/New_York", "America/Chicago", "America/Los_Angeles", "UTC"]
        let current = TimeZone.current.identifier
        if !zones.contains(current) {
            zones.insert(current, at: 0)
        }
        return zones
    }
    
    private var sortedApplications: [ApplicationStatusRecord] {
        applications.sorted {
            if $0.companyName.localizedCaseInsensitiveCompare($1.companyName) == .orderedSame {
                if $0.role.localizedCaseInsensitiveCompare($1.role) == .orderedSame {
                    return $0.applicationId < $1.applicationId
                }
                return $0.role.localizedCaseInsensitiveCompare($1.role) == .orderedAscending
            }
            return $0.companyName.localizedCaseInsensitiveCompare($1.companyName) == .orderedAscending
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Picker("Application", selection: $selectedApplicationId) {
                        Text("Select Application").tag(Int64?.none)
                        ForEach(sortedApplications) { app in
                            Text("\(app.companyName) (ID: \(app.applicationId)) - \(app.role)").tag(Int64?.some(app.applicationId))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 280)
                    
                    Picker("Event Type", selection: $type) {
                        ForEach(EventType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .frame(width: 150)
                    
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                    
                    Picker("Timezone", selection: $timezone) {
                        ForEach(supportedTimezones, id: \.self) { tzId in
                            Text(TimeZone.formattedLabel(for: tzId, date: date)).tag(tzId)
                        }
                    }
                    .frame(width: 150)
                    
                    Spacer()
                    
                    Button(action: saveNote) {
                        Label("Save to Timeline", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedApplicationId == nil)
                }
                
                if selectedApplicationId != nil {
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        if timeline.isEmpty {
                            Text("No timeline events yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            HStack(spacing: 0) {
                                let chronologicalTimeline = Array(timeline.reversed())
                                ForEach(Array(chronologicalTimeline.enumerated()), id: \.element.sortId) { index, entry in
                                    VStack(alignment: .center, spacing: 4) {
                                        Text(entry.type.rawValue)
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(entry.type.color)
                                            .lineLimit(1)
                                        
                                        ZStack(alignment: .center) {
                                            GeometryReader { geometry in
                                                Path { path in
                                                    let startX: CGFloat = (index == 0) ? geometry.size.width / 2 : 0
                                                    let endX: CGFloat = (index == chronologicalTimeline.count - 1) ? geometry.size.width / 2 : geometry.size.width
                                                    path.move(to: CGPoint(x: startX, y: geometry.size.height / 2))
                                                    path.addLine(to: CGPoint(x: endX, y: geometry.size.height / 2))
                                                }
                                                .stroke(Color.gray.opacity(0.35), lineWidth: 2)
                                            }
                                            .frame(height: 12)
                                            
                                            Circle()
                                                .fill(entry.type.color)
                                                .frame(width: 10, height: 10)
                                        }
                                        .frame(height: 12)
                                        
                                        Text(entry.createdAt, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 120)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                        }
                    }
                    .frame(height: 70)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Editor and Preview
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    TextEditor(text: $notes)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(width: geometry.size.width / 2)
                    
                    Divider()
                    
                    ScrollView {
                        VStack(alignment: .leading) {
                            StructuredText(markdown: notes)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textual.textSelection(.enabled)
                                .padding()
                        }
                    }
                    .frame(width: geometry.size.width / 2)
                    .background(Color.gray.opacity(0.02))
                }
            }
        }
        .navigationTitle("Scratchpad")
        .onAppear {
            loadApplications()
        }
        .task(id: selectedApplicationId) {
            loadTimeline(for: selectedApplicationId)
        }
    }
    
    
    private func loadApplications() {
        do {
            applications = try applicationService.fetchApplications()
        } catch {
            print("Failed to load applications: \(error)")
        }
    }
    
    private func loadTimeline(for appId: Int64?) {
        guard let appId = appId else {
            timeline = []
            return
        }
        do {
            timeline = try applicationService.fetchLedgerEntries(for: appId)
        } catch {
            print("Failed to load timeline: \(error)")
        }
    }
    
    private func saveNote() {
        guard let appId = selectedApplicationId else { return }
        
        var entry = LedgerEntry(
            createdAt: date,
            type: type,
            applicationId: appId,
            update: notes.isEmpty ? nil : notes,
            timezone: timezone
        )
        
        do {
            try applicationService.addLedgerEntry(&entry)
            notes = ""
            date = Date()
            loadTimeline(for: appId)
        } catch {
            print("Failed to save note: \(error)")
        }
    }
}
