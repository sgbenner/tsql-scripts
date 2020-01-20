USE SSISDB;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

/****************************************
-- Recent Failures
****************************************/

SELECT folder_name
     , project_name
     , package_name
     , executed_as_name
     , CAST(start_time AS DATETIME2(0)) AS start_time
     , CAST(end_time AS DATETIME2(0)) AS end_time
     , DATEDIFF(second , start_time , end_time) AS time_running_S
     , CASE executions.[status]
           WHEN 1 THEN 'created'
           WHEN 2 THEN 'running'
           WHEN 3 THEN 'canceled'
           WHEN 4 THEN 'failed'
           WHEN 5 THEN 'pending'
           WHEN 6 THEN 'ended unexpectedly'
           WHEN 7 THEN 'succeeded'
           WHEN 8 THEN 'stopping'
           WHEN 9 THEN 'completed'
       END AS last_exec_status -- The status of the operation. The possible values are created (1), running (2), canceled (3), failed (4), pending (5), ended unexpectedly (6), succeeded (7), stopping (8), and completed (9).
-- select *
FROM   [catalog].executions
WHERE  executions.[status] IN(4 , 6) -- Running and Stopping
ORDER BY end_time DESC;