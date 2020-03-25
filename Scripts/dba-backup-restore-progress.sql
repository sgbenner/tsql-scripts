-- Get Metadata about Backup/Restore Database
SELECT session_id AS SPID
     , command
     , a.text AS Query
     , start_time
     , percent_complete
     , DATEADD(second , estimated_completion_time / 1000 , GETDATE()) AS estimated_completion_time
FROM   sys.dm_exec_requests r
       CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
WHERE  r.command IN('BACKUP DATABASE' , 'RESTORE DATABASE');