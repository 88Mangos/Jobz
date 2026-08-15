SELECT 
    COUNT(*) AS total_applications,
    COUNT(CASE WHEN numInterviews > 0 THEN 1 END) AS applications_with_interviews,
    ROUND(COUNT(CASE WHEN numInterviews > 0 THEN 1 END) * 100.0 / COUNT(*), 1) || '%' AS interview_rate,
    COUNT(CASE WHEN statusRaw IN ('Offered', 'Accepted') THEN 1 END) AS applications_with_offers,
    ROUND(COUNT(CASE WHEN statusRaw IN ('Offered', 'Accepted') THEN 1 END) * 100.0 / COUNT(*), 1) || '%' AS offer_rate
FROM application_status_view;
