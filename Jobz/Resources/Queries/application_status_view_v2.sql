CREATE VIEW application_status_view AS
SELECT 
    a.application_id,
    a.company_name,
    a.role,
    a.role_extra_notes,
    a.duration,
    a.season,
    a.location,
    a.notes,
    
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
