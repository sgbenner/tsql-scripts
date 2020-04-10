-- Get Metadata about Backup/Restore Database
SELECT session_id AS SPID
     , command
     , a.text AS Query
     , start_time
     , percent_complete
     , DATEADD(second , estimated_completion_time / 1000 , GETDATE()) AS estimated_completion_time
     , CAST(DATEDIFF(second , GETDATE() , DATEADD(second , estimated_completion_time / 1000 , GETDATE())) / 60.0 AS decimal(10 , 2)) AS time_until_complete_min
     , DATEDIFF(second , GETDATE() , DATEADD(second , estimated_completion_time / 1000 , GETDATE())) AS time_until_complete_sec
FROM   sys.dm_exec_requests r
       CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
WHERE  r.command IN('BACKUP DATABASE' , 'RESTORE DATABASE' , 'RESTORE HEADERONLY');