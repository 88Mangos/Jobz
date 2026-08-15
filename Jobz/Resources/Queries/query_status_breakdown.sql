SELECT 
    statusRaw AS current_status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM application_status_view), 1) || '%' AS share
FROM application_status_view
GROUP BY statusRaw
ORDER BY count DESC;
