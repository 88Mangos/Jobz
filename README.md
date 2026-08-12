# Jobz 🚀

**Jobz** is a modern, native macOS application designed to track, analyze, and manage job applications, interviews, online assessments (OAs), and search metrics with SQLite querying and interactive charts.

---

## 🌟 Key Features

- **Dashboard & Analytics**:
  - **Applications Over Time**: Interactive line chart showing weekly application volume over time.
  - **Status Breakdown**: Visual breakdown of applications across all status stages.
  - **Weekly Goal Donut Chart**: Track weekly progress towards application goals.
- **Application & Ledger Management**:
  - Full application table view with search, filtering, and detail drawers.
  - Ledger log tracking individual events (Applications, OAs, Interviews, Offers, Rejections, Updates).
- **SQL Lab**:
  - Execute custom SQL queries directly against the local SQLite database.
  - Table preview and tabular query results exportable to CSV.
- **Snowflake-style CSV Data Export & Ingestion**:
  - Export SQLLab queries, application tables, ledger entries, and summary views to CSV with datetime-formatted filenames.
  - Single-transaction atomic CSV import for `applications.csv` and `ledger.csv`.

---

## 🛠 Architecture & Tech Stack

- **Framework**: Swift 5.9+, SwiftUI (macOS 14.0+)
- **Database**: SQLite powered by [GRDB.swift](https://github.com/groue/GRDB.swift)
- **Navigation**: `NavigationSplitView` with custom sidebar items.
- **Charts**: Swift Charts (`Charts` framework).

```
Jobz/
├── App/                # JobzApp entry point & ContentView main navigation
├── Database/           # DatabaseManager & GRDB schema migrations
├── Models/             # Application, LedgerEntry, ApplicationStatusRecord
├── Services/           # ApplicationService, MetricsService, CSVImporter
└── Views/              # Dashboard, Applications, Ledger, SQLLab, Summary & Components
```

---

## 🎨 Theme & Color Customization

You can customize the app's visual theme and status badge colors:

1. **Global Accent Color**:
   - Located at [`Jobz/Assets.xcassets/AccentColor.colorset`](file:///Users/tyleryang/Developer/Jobz/Jobz/Assets.xcassets/AccentColor.colorset).
   - Change the primary accent in Xcode's Asset Catalog to customize buttons, selection highlights, and navigation accents.
2. **Status Badge Colors**:
   - Defined in [`StatusBadgeView.swift`](file:///Users/tyleryang/Developer/Jobz/Jobz/Views/Components/StatusBadgeView.swift).
   - Customize color mappings for each application status:
     - `Offered`: `.green`
     - `Accepted`: `.purple`
     - `Rejected`: `.red`
     - `Interviewing`: `.blue`
     - `Pending`: `.orange`
     - `Ghosted`: `.gray`

---

## 📖 How to Use

### 1. Adding & Editing Applications
- Click **New Application** from the sidebar or header to open the creation modal.
- Enter Company Name, Role, Season/Term, Location, Duration, and initial Notes.

### 2. Logging Ledger Events
- From an application detail view or the Ledger tab, click **Add Update**.
- Select the event type (`Applied`, `Online Assessment`, `Interview`, `Update`, `Offer`, `Rejection`, `Accepted`) and add notes or dates.

### 3. Importing & Exporting Data
- **Import**: Select **File > Import Data...** to load `applications.csv` and `ledger.csv`.
- **Export**: Click the **Export CSV** button on any table (Applications, Ledger, Summary, SQLLab) to generate a timestamped CSV output file.

---

## 💡 Ledger Data Model & Philosophy

### Why Generic "Update" vs Specific Events?
- **Specific Events** (`Applied`, `Online Assessment`, `Interview`, `Offer`, `Rejection`, `Accepted`) mark milestone state transitions in the application lifecycle.
- **Generic "Update" Events** allow logging qualitative progress (e.g., "Followed up with recruiter", "Submitted background check", "Connected on LinkedIn") without altering the macro lifecycle stage of the application.

### Dynamic Status & Ghosted Derivation
Applications do not store a static status string. Instead, **Status View** dynamically joins the `application` and `ledger` tables:
1. Calculates **num_interviews** and **num_OAs**.
2. Identifies `applied_at` (first `Applied` timestamp) and `last_updated` (most recent ledger timestamp).
3. Evaluates current status:
   - Latest terminal status (`Accepted`, `Offered`, `Rejected`).
   - Active status (`Interviewing`, `Pending`).
   - **Auto-Ghosted**: Automatically converts active applications to `Ghosted` if `last_updated` is greater than 2 months ago without an outcome.

---

## 🚀 Building & Running

### Requirements
- macOS 14.0+
- Xcode 15.0+

### Build Command
```bash
xcodebuild -project Jobz.xcodeproj -scheme Jobz build
```
