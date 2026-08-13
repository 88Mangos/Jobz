<p align="center">
  <img alt="Jobz App Icon" src="Jobz/Assets.xcassets/AppIcon.appiconset/app_icon_128x128.png" width="128" height="128" />
</p>

<h1 align="center">Jobz</h1>

<p align="center">
  <strong>A modern, native macOS toolkit to track, analyze, and query job applications.</strong><br>
  Built with Swift, SwiftUI, and SQLite powered by GRDB.swift.
</p>

<p align="center">
  <a href="https://developer.apple.com/swift/"><img alt="Swift 5.9+" src="https://img.shields.io/badge/swift-5.9+-orange.svg?style=flat"></a>
  <a href="https://developer.apple.com/macos/"><img alt="macOS 14.0+" src="https://img.shields.io/badge/macOS-14.0+--Sonoma-blue.svg?style=flat"></a>
  <a href="LICENSE"><img alt="License MIT" src="https://img.shields.io/badge/license-MIT-green.svg?style=flat"></a>
  <a href="https://github.com/groue/GRDB.swift"><img alt="GRDB.swift" src="https://img.shields.io/badge/SQLite-GRDB.swift-lightgrey.svg?style=flat"></a>
</p>

**Version Tracking**: [v1.0.0](CHANGELOG.md) • [CHANGELOG](CHANGELOG.md) • [ROADMAP](ROADMAP.md)

**Requirements**: macOS 14.0+ (Sonoma) • Swift 5.9+ • Xcode 15.0+ • SQLite 3.20.0+ (via GRDB)

---

<p align="center">
  <a href="#-key-features">Key Features</a> &bull;
  <a href="#-requirements">Requirements</a> &bull;
  <a href="#-architecture--tech-stack">Architecture</a> &bull;
  <a href="#-how-to-use">How to Use</a> &bull;
  <a href="#-ledger-data-model--philosophy">Data Model</a> &bull;
  <a href="#-building--running">Building</a> &bull;
  <a href="#-license--attributions">License</a>
</p>

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
  - Persistent Saved & Named Query Library with one-click load & run.
- **Snowflake-style CSV Data Export & Ingestion**:
  - Export SQLLab queries, application tables, ledger entries, and summary views to CSV with datetime-formatted filenames.
  - Single-transaction atomic CSV import for `applications.csv` and `ledger.csv`.

---

## 📋 Requirements

| Requirement | Minimum Version | Notes |
| :--- | :--- | :--- |
| **Operating System** | macOS 14.0 (Sonoma) | Required for native SwiftUI Charts & `NavigationSplitView` features |
| **Xcode** | Xcode 15.0+ | Required for building Swift 5.9 target schemas |
| **Swift Toolchain** | Swift 5.9+ | Modern Swift concurrency & macro compatibility |
| **Database** | SQLite 3.20.0+ | Managed automatically via [GRDB.swift](https://github.com/groue/GRDB.swift) (v6.29.3) |

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

### Build Command
```bash
xcodebuild -project Jobz.xcodeproj -scheme Jobz build
```

---

## 📜 License & Attributions

Jobz is open source software released under the [MIT License](LICENSE).

### Third-Party Open Source Software

This application incorporates open-source software libraries. We gratefully acknowledge the following third-party package:

- **[GRDB.swift](https://github.com/groue/GRDB.swift)**
  - **Author**: Gwendal Roué ([@groue](https://github.com/groue))
  - **License**: [MIT License](https://github.com/groue/GRDB.swift/blob/master/LICENSE)
  - **Notice**: Copyright (C) 2015-2025 Gwendal Roué

For complete third-party license texts and copyright notices, please consult [`ACKNOWLEDGEMENTS.md`](ACKNOWLEDGEMENTS.md) or open the **About & Licenses** view directly in the application.

## AI Disclosure
I don't know a lick of Swift. Sorry [SwiftCoderJoe](https://github.com/SwiftCoderJoe). In case the clearly vibecoded README hasn't made it obvious yet, this entire app is coded with Gemini + Antigravity, and the icons were also AI-generated.


