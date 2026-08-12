# Changelog

## [Unreleased]

### Added
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
