# Jobz

Purpose: track Tyler's job search

More specifically
1. track each job application
1. track associated interviews and assessments
1. create pretty charts

**Application Table Schema:**
application_id	company_name	role	role_extra_notes	duration	season	location	notes														

**Ledger Schema:**
Used to be: 
timestamp	ledger_id	Type	application_id	Company	Title	Season	Update	City	Link	Deadline/Event Date	Location	Supplements	Resume Version	People	Notes	Where did you hear about it?	Entry Key	Week																	

Want to be:
ledger_id created_at  type  application_id  update 

**Status View:**
Join Application table and ledger + derive the following columns
1. num interviews
1. num OAs
1. applied_at
1. last_updated
1. status (offered, accepted, rejected, interviewing, pending, ghosted) - ghosted auto-derived from last_updated greater than 2 months ago 

**Charts:**
From Status View - breakdown of all applications (unique application id) by accepted/rejected/ghosted 

From Status View - using applied_at timestamp, line chart showing num applications over time 

From Status View - using applied_at timestamp, donut showing progress towards goal num applications per week 

**CSV Import & Data Ingestion:**
1. **User Interface**: File menu option or button in navigation sidebar (`Import Data...`) presenting a modal/file picker (`NSOpenPanel`) to select `applications.csv` and `ledger.csv`.
2. **Application CSV Expected Headers**:
   - `application_id` (optional, used for mapping to ledger if present)
   - `company_name` (required)
   - `role` (required)
   - `role_extra_notes`, `duration`, `season`, `location`, `notes` (optional)
3. **Ledger CSV Expected Headers**:
   - `ledger_id` (optional)
   - `created_at` (required - e.g. `YYYY-MM-DD` or `YYYY-MM-DD HH:MM:SS`)
   - `type` (required - `Applied`, `Online Assessment`, `Interview`, `Update`, `Offer`, `Rejection`, `Accepted`)
   - `application_id` (required - maps to application)
   - `update` (optional notes)
4. **Import Behavior**:
   - Process `applications.csv` first, inserting records into `application` table (maintaining ID mapping if auto-incrementing).
   - Process `ledger.csv` second, linking entries to the corresponding `application_id`.
   - Execute all insertions inside a single database transaction for atomic safety.
 