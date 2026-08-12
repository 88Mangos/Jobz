# Changelog

## [Unreleased]

### Added
- **Test Database Environment**: Added a `-useTestDB` launch argument to switch the app to `Jobz_Test.sqlite`, protecting live data during development and testing.
- **Ledger Tab**: Introduced a dedicated `GlobalLedgerView` accessible from the sidebar. 
- **Global Ledger Data Grid**: The Ledger tab features a spreadsheet-like grid displaying all ledger events, with toggles to group and filter events by specific applications.
- **Application Spreadsheet View**: Added a picker in the Applications tab to toggle between the original card list view and a new `ApplicationDataGrid` spreadsheet view.
- **Inline Editing**: Both the `ApplicationDataGrid` and `GlobalLedgerView` support clicking into cells to seamlessly edit data (e.g. updating company name, role, event type, or notes) without opening a separate form.
- **Quick-Add Data Entry**: Added an input row at the bottom of both spreadsheet views to rapidly insert new applications and ledger entries.
- **CSV Importer**: Added a "CSV Import" button to both spreadsheet views, allowing bulk importing of Applications and Ledger events via file selection.
- **Multi-Select Deletion**: Replaced quick-add rows with a "Delete Selected" button in the main toolbar of both spreadsheet views. Added support for bulk-selecting spreadsheet rows using `Command-click` or `Shift-click`.
- **Strict CSV Validation**: `CSVImporter` now intelligently maps headers by name (agnostic to column order) and handles case-insensitivity, BOMs, and quotes. It gracefully ignores extraneous columns while strictly validating required ones.
- **CSV Error Reporting**: Attempting to upload a malformed CSV will now halt the process and present a native UI alert detailing the exact matched, missing, and extraneous column headers.
- **Chart Customization Guide**: Generated `CustomizingCharts.md` to document how to override Swift Chart colors for personalization.

### Fixed
- **Missing Application Bug**: Fixed a GRDB decoding error where applications with zero ledger events were not displayed. Added `CodingKeys` to `ApplicationStatusRecord` to properly map `snake_case` SQL columns, and made `lastUpdated` optional.
- **Navigation Back Stack**: Wrapped the detail view inside `ContentView` in a `NavigationStack` so that pushing to the `ApplicationDetailView` correctly provides a "< Back" button.
