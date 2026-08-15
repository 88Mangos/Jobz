# Features Left
- [x] About & Licenses Page - add the Textual Dependency (akin to the README)
- [x] Create a new tab with a plus logo -> add new app with notes (like the scratchpad, but it also creates a new associated application row) instead of having to go to application spreadsheet view, edit mode, add new row - and then ledger spreadsheet view, edit mode, add new row.
- [x] Using underlying logic similar to the SQL query below, make a new tab only for pending applications (arrow arrow logo)
```sql
SELECT 
	* 
FROM application_status_view 
WHERE statusRaw = 'Pending'
order by appliedAt desc;
``` 
- [x] Make a new associated notes tab where I put some of my musings - probably best to render it as just one large markdown that I can edit (not side by side, just an edit button at the top is sufficient) where I can dump things before they actaully become job entries. 
- [ ] Handling Images
- [ ] Exporting all User Data (also leads to easier backups)

## Handling Images 
I don't necessarily want to save the screenshots, just the raw data stored in a table somewhere (like what Maccy does) would be good. 

## Exporting all User Data
Export everything as one Zip File and ingest everything as one zip file (needs to include EVERYTHING include dangling notes and My Saved SQL queries.)
