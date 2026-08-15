SELECT 
    strftime('%Y-%m', created_at) AS month,
    SUM(CASE WHEN type = 'Applied' THEN 1 ELSE 0 END) AS applications,
    SUM(CASE WHEN type = 'Online Assessment' THEN 1 ELSE 0 END) AS assessments,
    SUM(CASE WHEN type = 'Interview' THEN 1 ELSE 0 END) AS interviews,
    SUM(CASE WHEN type = 'Offer' THEN 1 ELSE 0 END) AS offers
FROM ledger
GROUP BY month
ORDER BY month DESC;
