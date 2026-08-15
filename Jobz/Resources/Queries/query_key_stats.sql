SELECT 
    SUM(CASE WHEN type = 'Interview' THEN 1 ELSE 0 END) AS total_interviews,
    SUM(CASE WHEN type = 'Online Assessment' THEN 1 ELSE 0 END) AS total_assessments,
    SUM(CASE WHEN type = 'Chat' THEN 1 ELSE 0 END) AS total_chats
FROM ledger;
