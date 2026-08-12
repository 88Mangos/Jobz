# Jobz — macOS App Specification & Target Architecture

## Project Overview
Jobz is a native macOS app built with SwiftUI, GRDB (SQLite), and Swift Charts designed to track job applications, log stage-by-stage ledger updates (interviews, assessments, offers), and render real-time pipeline analytics.

---

## 1. Domain Models & Database Schemas

### Application Table (`application`)
Stores top-level metadata for each unique company/role application.
* `application_id` (INTEGER, Primary Key, Auto-increment)
* `company_name` (TEXT, Not Null)
* `role` (TEXT, Not Null)
* `role_extra_notes` (TEXT, Optional)
* `duration` (TEXT, Optional) — e.g. "Full-time", "Summer 2026"
* `season` (TEXT, Optional) — e.g. "Fall 2026"
* `location` (TEXT, Optional)
* `notes` (TEXT, Optional)

### Ledger Table (`ledger`)
Stores individual event updates tied to a job application over time.
* `ledger_id` (INTEGER, Primary Key, Auto-increment)
* `created_at` (DATETIME, Not Null)
* `type` (TEXT, Not Null) — Values: `Applied`, `Online Assessment`, `Interview`, `Update`, `Offer`, `Rejection`, `Accepted`
* `application_id` (INTEGER, Foreign Key -> `application.application_id`, ON DELETE CASCADE)
* `update` (TEXT, Optional)

### Derived Status SQL View (`application_status_view`)
SQL view combining `application` and `ledger` to compute dynamic pipeline metrics:
* `num_interviews`: Count of ledger records where `type = 'Interview'`.
* `num_OAs`: Count of ledger records where `type = 'Online Assessment'`.
* `applied_at`: Minimum `created_at` timestamp where `type = 'Applied'`.
* `last_updated`: Maximum `created_at` timestamp across all associated ledger events.
* `status`: Derived status string according to the following precedence:
  1. `Accepted` — if any ledger event is `Accepted`
  2. `Offered` — if any ledger event is `Offer`
  3. `Rejected` — if any ledger event is `Rejection`
  4. `Interviewing` — if any ledger event is `Interview`
  5. `Ghosted` — if inactive for > 60 days (`MAX(created_at) < datetime('now', '-60 days')`) and not terminal
  6. `Pending` — default fallback state

---

## 2. Analytics & Visuals (Swift Charts)

1. **Status Breakdown Chart:** Bar chart representing unique applications by current derived status (`Accepted`, `Offered`, `Rejected`, `Interviewing`, `Pending`, `Ghosted`).
2. **Applications Over Time:** Line/Area chart plotting application volume over time using `applied_at`.
3. **Weekly Goal Donut Chart:** SectorMark donut chart displaying progress towards a target number of applications per week.

---

## 3. Project File Structure

```text
Jobz/
├── App/
│   ├── JobzApp.swift               # App main entry point (@main) & DatabaseQueue setup
│   └── Assets.xcassets             # Colors and icons
│
├── Database/
│   ├── DatabaseManager.swift       # SQLite database initialization in Application Support
│   └── Migrations.swift            # Database Migrations & SQL Status View definition
│
├── Models/
│   ├── Application.swift           # JobApplication struct (FetchableRecord, MutablePersistableRecord)
│   ├── LedgerEntry.swift           # LedgerEntry struct & EventType enum
│   └── ApplicationStatusRecord.swift # ApplicationStatusRecord struct & ApplicationStatus enum
│
├── Services/
│   ├── ApplicationService.swift    # Data access methods for inserting/updating applications & ledger items
│   └── MetricsService.swift        # SQL query execution against application_status_view
│
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift     # 3-chart grid dashboard layout
│   │   ├── StatusBreakdownChart.swift
│   │   ├── ApplicationsOverTimeChart.swift
│   │   └── WeeklyGoalDonutChart.swift
│   │
│   ├── Applications/
│   │   ├── ApplicationListView.swift # Master list of applications with status badges
│   │   ├── ApplicationDetailView.swift # Detailed view of application & event history
│   │   ├── NewApplicationForm.swift  # Modal/Form to create a new application + initial Applied event
│   │   └── AddLedgerEventForm.swift  # Form to append an event update to an application
│   │
│   └── Components/
│       ├── StatusBadgeView.swift   # Visual status pill (Color coded for Offered/Interviewing/Ghosted)
│       └── MetricCardView.swift    # Quick-read summary statistics
│
└── Utilities/
    └── Date+Extensions.swift       # Date formatting and week-calculation helpers
```

---

## 4. Execution Directives for Coding Agent
Language/Frameworks: Swift 6, SwiftUI (macOS 14+ target), GRDB.swift 6/7, Swift Charts.

Storage Path: Store the .sqlite file in ~/Library/Application Support/Jobz/Jobz.sqlite.

Data Concurrency: Wrap all write operations in explicit GRDB transactions (dbQueue.write).

UI Pattern: NavigationSplitView with sidebar navigation for modern macOS layout guidelines.

--- 

## 5. Snippets
```swift
import Foundation
import GRDB

// MARK: - Enums
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

enum ApplicationStatus: String, Codable, CaseIterable, Identifiable {
    case accepted = "Accepted"
    case offered = "Offered"
    case rejected = "Rejected"
    case interviewing = "Interviewing"
    case pending = "Pending"
    case ghosted = "Ghosted"
    
    var id: String { rawValue }
}

// MARK: - Database Models
struct JobApplication: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    var id: Int64?
    var companyName: String
    var role: String
    var roleExtraNotes: String?
    var duration: String?  // e.g. "Full-time", "Summer 2026"
    var season: String?    // e.g. "Fall 2026"
    var location: String?
    var notes: String?

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

struct LedgerEntry: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    var id: Int64?
    var createdAt: Date
    var type: EventType
    var applicationId: Int64
    var update: String?

    enum CodingKeys: String, CodingKey {
        case id = "ledger_id"
        case createdAt = "created_at"
        case type
        case applicationId = "application_id"
        case update
    }
}
```

```swift
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

extension AppDatabase {
    static func setupMigrations(_ dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1_schema") { db in
            // Application Table
            try db.create(table: "application") { t in
                t.autoIncrementedPrimaryKey("application_id")
                t.column("company_name", .text).notNull()
                t.column("role", .text).notNull()
                t.column("role_extra_notes", .text)
                t.column("duration", .text)
                t.column("season", .text)
                t.column("location", .text)
                t.column("notes", .text)
            }
            
            // Ledger Table
            try db.create(table: "ledger") { t in
                t.autoIncrementedPrimaryKey("ledger_id")
                t.column("created_at", .datetime).notNull()
                t.column("type", .text).notNull()
                t.column("application_id", .integer)
                    .notNull()
                    .references("application", onDelete: .cascade)
                t.column("update", .text)
            }
            
            // Status View with Ghosting Logic (2 Months = 60 days cutoff)
            try db.execute(sql: """
                CREATE VIEW application_status_view AS
                SELECT 
                    a.application_id,
                    a.company_name,
                    a.role,
                    a.location,
                    a.season,
                    
                    -- Derived Interview & OA counts
                    COUNT(CASE WHEN l.type = 'Interview' THEN 1 END) AS numInterviews,
                    COUNT(CASE WHEN l.type = 'Online Assessment' THEN 1 END) AS numOAs,
                    
                    -- Applied date & Last updated timestamp
                    MIN(CASE WHEN l.type = 'Applied' THEN l.created_at END) AS appliedAt,
                    MAX(l.created_at) AS lastUpdated,
                    
                    -- Status derivation hierarchy
                    CASE 
                        WHEN SUM(CASE WHEN l.type = 'Accepted' THEN 1 ELSE 0 END) > 0 THEN 'Accepted'
                        WHEN SUM(CASE WHEN l.type = 'Offer' THEN 1 ELSE 0 END) > 0 THEN 'Offered'
                        WHEN SUM(CASE WHEN l.type = 'Rejection' THEN 1 ELSE 0 END) > 0 THEN 'Rejected'
                        WHEN SUM(CASE WHEN l.type = 'Interview' THEN 1 ELSE 0 END) > 0 THEN 'Interviewing'
                        
                        -- Ghosted if not in a final/interview state and inactive for > 60 days
                        WHEN MAX(l.created_at) < datetime('now', '-60 days') THEN 'Ghosted'
                        
                        ELSE 'Pending'
                    END AS statusRaw
                    
                FROM application a
                LEFT JOIN ledger l ON a.application_id = l.application_id
                GROUP BY a.application_id;
            """)
        }
        
        try migrator.migrate(dbQueue)
    }
}
```

```swift
import SwiftUI
import Charts

// MARK: - Chart 1: Status Breakdown
struct StatusBreakdownChart: View {
    let records: [ApplicationStatusRecord]
    
    var statusCounts: [(status: ApplicationStatus, count: Int)] {
        let grouped = Dictionary(grouping: records, by: { $0.status })
        return ApplicationStatus.allCases.map { status in
            (status: status, count: grouped[status]?.count ?? 0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Applications by Status")
                .font(.headline)
            
            Chart(statusCounts, id: \.status) { item in
                BarMark(
                    x: .value("Status", item.status.rawValue),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(by: .value("Status", item.status.rawValue))
                .annotation(position: .top) {
                    if item.count > 0 {
                        Text("\(item.count)")
                            .font(.caption2)
                    }
                }
            }
            .frame(height: 220)
        }
        .padding()
    }
}

// MARK: - Chart 2: Applications Over Time (Line Chart)
struct ApplicationsOverTimeChart: View {
    let records: [ApplicationStatusRecord]
    
    // Group applications by week/day
    var timeData: [(date: Date, count: Int)] {
        let validRecords = records.compactMap { $0.appliedAt }
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: validRecords) { date in
            calendar.startOfDay(for: date)
        }
        
        return grouped.map { (date: $0.key, count: $0.value.count) }
            .sorted(by: { $0.date < $1.date })
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Applications Over Time")
                .font(.headline)
            
            Chart(timeData, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Applications", item.count)
                )
                .interpolationMethod(.monotone)
                
                AreaMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Applications", item.count)
                )
                .foregroundStyle(.blue.opacity(0.1))
            }
            .frame(height: 220)
        }
        .padding()
    }
}

// MARK: - Chart 3: Weekly Goal Progress (Donut Chart)
struct WeeklyGoalDonutChart: View {
    let records: [ApplicationStatusRecord]
    let weeklyGoal: Int = 15 // Target applications per week
    
    var currentWeekCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return records.compactMap { $0.appliedAt }.filter { date in
            calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        }.count
    }
    
    var progressData: [(category: String, count: Int)] {
        let completed = min(currentWeekCount, weeklyGoal)
        let remaining = max(0, weeklyGoal - currentWeekCount)
        return [
            ("Applied", completed),
            ("Remaining", remaining)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Goal Progress (\(currentWeekCount)/\(weeklyGoal))")
                .font(.headline)
            
            Chart(progressData, id: \.category) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.65),
                    angularInset: 1.5
                )
                .foregroundStyle(item.category == "Applied" ? .green : .secondary.opacity(0.2))
            }
            .chartBackground { _ in
                VStack {
                    Text("\(Int((Double(currentWeekCount) / Double(weeklyGoal)) * 100))%")
                        .font(.title)
                        .bold()
                    Text("of goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 220)
        }
        .padding()
    }

```