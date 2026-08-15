# Changelog

## [Unreleased]

### Fixed
- **Markdown Rendering**: Replaced native SwiftUI `Text(AttributedString)` with the `Textual` library in `HomeNotesCard` and `ScratchpadView` to fix formatting issues where line breaks were condensed and bullet points were stripped by the native parser.
- **Multi-Location Selection & Parsing**: Fixed a parsing bug where multi-select location strings split on `", "` broke city/state pairs (e.g. `"San Francisco, CA"`), causing checkmarks to disappear and selections to be dropped. Introduced `LocationParser` to robustly handle city/state formatting, semicolon separators (`"; "`), slash separators (`" / "`), and legacy comma lists.
- **RFC 4180 CSV Export/Import Roundtripping**: Fixed CSV parsing in `CSVImporter` to process streams character-by-character per RFC 4180. Preserves multiline notes, unescapes double quotes (`""`), and correctly handles commas within quoted fields so exported data can be re-imported perfectly regardless of content size or complex formatting.
- **App Category Configuration**: Configured `INFOPLIST_KEY_LSApplicationCategoryType` (`public.app-category.productivity`) in `project.pbxproj` build settings to resolve Xcode target category warnings.
- **Metrics Time-Series Statement Arguments**: Fixed optional unwrapping of `StatementArguments` in `MetricsService.fetchTimeSeriesData` to resolve compilation failure.

### Added
- Efficient GRDB query in `MetricsService` (`fetchTimeSeriesData`) to fetch time-series data for applications, interviews, and online assessments by week.
- **Interactive Dashboard Line Chart**: Rewrote `ApplicationsOverTimeChart` to include hoverable data points, toggles for "Applications", "Interviews", and "OAs", and a dynamic Date Range Picker.
- Added an auto-generated SQLite tooltip string under the line chart to display the executed SQL query for educational transparency.


- **Multi-Select Spreadsheet Filtering**: Replaced global text search with per-column, multiple-selectable dropdown filters in the Applications, Ledger, and Summary spreadsheet views, enabling complex queries (e.g., "only include MLE and DS roles for Summer 2025").
- **Musings Tab**: Added a dedicated `MusingsView` tab for unstructured thoughts, utilizing `UserDefaults` and Markdown rendering to keep a single, globally accessible scratchpad outside of specific job applications.
- **Summary Table Inspector**: Replaced the `NavigationSplitView` in `SummaryTableView` with a collapsible `.inspector()` modifier. The detail pane containing the application's timeline and info is now collapsed by default and only appears when a specific application row is selected.
- **Sidebar Grouping**: Streamlined the sidebar by grouping `Applications` and `Ledger` under a new "Raw Spreadsheets" section, and reordered the Main section for better flow.
- **Redundant Heading Removal**: Removed redundant large headings from the Dashboard, Musings, Quick Add, and SQL Lab tabs since the selected sidebar tab name already provides context.
- **Quick Add Tab**: Added a dedicated `QuickAddView` to the sidebar with a plus logo for rapidly inserting new applications without interacting with spreadsheets. Enhanced with fully-specified fields matching the table schema (Company, Role, Season, Location, Duration, Notes), featuring smart dropdowns that pre-populate with existing values from your database while still allowing you to type new ones. Timezone selection is now supported in the applied date picker.
- **Textual License Attribution**: Added an attribution card for the Textual library to the About & Licenses page to bring it in line with the README documentation.
- **Scratchpad Application Selector & Alphabetical Sorting**: Displayed the application ID next to company name in the Scratchpad application picker (`Company (ID: #) - Role`) to disambiguate multiple applications for the same company/role across seasons, and alphabetically sorted the dropdown options.
- **Blank Scratchpad Timeline Logging**: Allowed saving events to the timeline from the Scratchpad without requiring notes (persisting `nil` update notes).
- **Multi-Location Picker Component & Form Support**: Extracted `MultiSelectLocationMenu` into a standalone reusable component supporting multiple location selection, "Clear All", and dynamic custom location addition. Added `MultiSelectLocationMenu` to `NewApplicationForm` so users can choose multiple locations when creating a new application.
- **Home Page Notes Dump**: Added a persistent notes card (`HomeNotesCard`) to the Dashboard view with full Markdown rendering and monospaced edit mode for quick unattached notes, code snippets (supporting Python triple-quoted docstrings), one-click clipboard copying with visual feedback, and `AppStorage` persistence.
- **SQL Lab Saved & Named Queries**: Added a persistent Saved Query Library to the SQL Lab tab with custom query naming, scrollable Presets & My Queries sections, one-click load & run, copy to clipboard with visual feedback, and query deletion.
- **Expandable Timeline Notes**: Long ledger event updates are now truncated to 4 lines by default on the Summary detail view timeline, with a "Show More" / "Show Less" toggle for easier reading.
- **"Online Assessment" => "Assessment"** retained `.oa` enum but changed how it renders 
- **Assessment Received/Reminder Event Types**: Added an `Assessment Received` and `Assessment Reminder` event type to differentiate between receiving an assessment and actively completing one + emails that just tell me to complete an assessment
- **Chat Event Type**: Added a new `Chat` event type to the ledger with a distinct pink color indicator to differentiate informal networking chats from formal interviews.
- **Dynamic Location Menu**: Supported adding custom locations dynamically in the Multi-select Location dropdown menu. Custom locations are saved to AppStorage.
- **Application Location Editing**: Added inline editing for application location in the Summary detail view, leveraging the updated Multi-select Location dropdown menu.
- **Ledger Event Editing**: Added `EditLedgerEventForm` to allow modifying existing ledger timeline events directly from the Summary detail view.
- **Datetime Inputs**: Upgraded date pickers in ledger event forms to support both date and precise time inputs.
- **Application Notes Editing**: Rendered application notes below the role extra notes in the Summary detail view, complete with an inline edit mode for fast updates.
- **Timezone Support**: Added a `timezone` field to the `Ledger` schema via a new migration. Introduced dynamic, location-aware GMT labels (e.g., `GMT-04:00 (EDT) - New York`) in the Add Update form and Ledger table. Timezones default automatically to the user's current location and correctly offset UTC timestamps in exports based on historical daylight saving rules.
- **Ledger Inline Application Details**: Replaced the standalone App ID column in the Ledger grid with an integrated "Application" column that prominently displays both the numeric ID and a dynamically resolved caption of the company name and role (e.g., `123`, `Google - SWE`). This same real-time validation is surfaced in the Quick-Add row to streamline manual data entry.
- **CSV Export**: Added native CSV export support to Applications, Ledger, Summary, and SQL Lab views using `NSSavePanel`. Ensures standard CSV compliance (escaping quotes, commas, and newlines) and automatically generates ISO-8601 UTC timestamped filenames (e.g., `Applications_20260812T151046Z.csv`).
- **Sandbox Entitlements**: Added the `Jobz.entitlements` file with `com.apple.security.files.user-selected.read-write` and updated project settings to securely enable `NSSavePanel` in the macOS App Sandbox without `EXC_BREAKPOINT` runtime crashes.
- **Third-Party License & Attributions**: Added comprehensive open-source licensing and copyright attributions for `GRDB.swift` by Gwendal Roué. Created [`ACKNOWLEDGEMENTS.md`](ACKNOWLEDGEMENTS.md), added root [`LICENSE`](LICENSE), updated [`README.md`](README.md), and introduced an in-app **About & Licenses** SwiftUI view ([`AboutView.swift`](Jobz/Views/About/AboutView.swift)) accessible via sidebar navigation and app menu.
- **Dashboard Chart Layout & Timeline Axes**: Reorganized dashboard chart layout and upgraded `ApplicationsOverTimeChart` with clamped X-axis bounds starting at the initial data date, monthly grid ticks/labels, dashed year divider lines, and centered year headers.
- **Event-Specific Timeline Colors**: Extended `EventType` with semantic color mappings (e.g., Applied, Interview, Offer, Rejection, Accepted) to visually distinguish timeline event types.
- **Connected Timeline View**: Updated `SummaryDetailView` to render continuous vertical lines connecting timeline event dots seamlessly.
- **Robust CSV Import & Season Dropdown**: Enhanced `CSVImporter` with quoted field parsing, flexible date format matching, auto-increment sequence synchronization, and added additional season dropdown options in `ApplicationTableView`.
- **Quick-Add Bar**: Reintroduced the Quick-Add bar to the top of both the Applications and Ledger spreadsheet views, visible only when Edit Mode is toggled on.
- **Application ID Editing**: The `application_id` field can now be explicitly set when creating a new application via the Quick-Add bar, and is also fully editable for existing applications in the spreadsheet. Updating an application's ID will safely migrate all associated ledger entries.
- **Dropdown Enums for Spreadsheets**: Upgraded the "Season" column to use a predefined dropdown `Picker`, and the "Location" column to use a custom multi-select checkbox menu (saving as a comma-separated list) for faster data entry in Edit Mode.
- **SQL Lab**: Added a new "SQL Lab" tab to the sidebar that allows executing raw, read-only SQLite queries against the database. For security and to encourage using the GUI for modifications, this lab is strictly restricted to read-only queries (like SELECT), and results are safely limited to 100 rows to prevent UI hangs.
- **Spreadsheet Edit Mode**: Added an "Edit Mode" toggle to the toolbar in the Applications and Ledger spreadsheet views. When disabled, the tables render as read-only text for significantly improved scrolling performance. When enabled, the tables use `TextField`, `Picker`, and `DatePicker` bindings to allow inline data entry.
- **Role Name Expansion**: The `SummaryDetailView` now expands standard tech role abbreviations (e.g., SWE to Software Engineer). Any extra role notes are cleanly formatted on a new line beneath the primary role title.
- **Summary Tab**: Added a new Summary tab featuring a read-only spreadsheet view (`SummaryTableView`) of the `application_status_view` with derived pipeline metrics (applied at, last updated, interview counts).
- **Detail Timeline View**: Selecting an application in the Summary tab now opens a detailed split-view (`SummaryDetailView`) displaying the application's timeline of events.
- **Strict Read-Only Spreadsheet Views**: Deprecated the card-based ApplicationListView in favor of a new `ApplicationTableView`. Removed inline editing from the Applications and Ledger spreadsheets to enforce a strict read-only tabular presentation of the raw data.
- **Test Database Environment**: Added a `-useTestDB` launch argument to switch the app to `Jobz_Test.sqlite`, protecting live data during development and testing.
- **Ledger Tab**: Introduced a dedicated `GlobalLedgerView` accessible from the sidebar. 
- **Global Ledger Data Grid**: The Ledger tab features a spreadsheet-like grid displaying all ledger events, with toggles to group and filter events by specific applications.
- **Application Spreadsheet View**: Added a picker in the Applications tab to toggle between the original card list view and a new `ApplicationDataGrid` spreadsheet view.
- **Quick-Add Data Entry**: Added an input row at the bottom of both spreadsheet views to rapidly insert new applications and ledger entries.
- **CSV Importer**: Added a "CSV Import" button to both spreadsheet views, allowing bulk importing of Applications and Ledger events via file selection.
- **Multi-Select Deletion**: Replaced quick-add rows with a "Delete Selected" button in the main toolbar of both spreadsheet views. Added support for bulk-selecting spreadsheet rows using `Command-click` or `Shift-click`.
- **Strict CSV Validation**: `CSVImporter` now intelligently maps headers by name (agnostic to column order) and handles case-insensitivity, BOMs, and quotes. It gracefully ignores extraneous columns while strictly validating required ones.
- **CSV Error Reporting**: Attempting to upload a malformed CSV will now halt the process and present a native UI alert detailing the exact matched, missing, and extraneous column headers.
- **Chart Customization Guide**: Generated `CustomizingCharts.md` to document how to override Swift Chart colors for personalization.
- **Raw Database Spreadsheet Mode**: Updated Applications and Ledger grids to display raw CSV schema column names (`application_id`, `company_name`, `role_extra_notes`, `duration`, `created_at`, etc.).
- **Rich Inline Spreadsheet Editors**: Added inline `DatePicker` for `created_at`, dropdown `Picker` for `duration` and `type`, and editable text fields for optional notes and raw foreign key `application_id`.
- **Restored Ledger Quick-Add**: Added a dedicated quick-add bar to the bottom of the Global Ledger tab for rapid entry using raw `application_id` values.
- **Table Column Sorting**: Added native column header click sorting for both spreadsheet views.

### Fixed
- **Missing Application Bug**: Fixed a GRDB decoding error where applications with zero ledger events were not displayed. Added `CodingKeys` to `ApplicationStatusRecord` to properly map `snake_case` SQL columns, and made `lastUpdated` optional.
- **Navigation Back Stack**: Wrapped the detail view inside `ContentView` in a `NavigationStack` so that pushing to the `ApplicationDetailView` correctly provides a "< Back" button.
- **Applications Over Time Chart Grouping**: Refactored `ApplicationsOverTimeChart` to aggregate applications by week starting on Sunday rather than by hour/day.
- **CSV Import Ledger Creation**: Updated CSV import to skip auto-generating "Applied" ledger entries so imports act strictly as manual data overrides.
- **Online Assessment Ledger Decoding**: Reverted Enum value for Online Assessment back to `.oa = "Online Assessment"` and added a `v4_revert_assessment` migration to repair corrupted database records. This properly fixes a decoding bug where the Ledger tab would fail to render any rows.
