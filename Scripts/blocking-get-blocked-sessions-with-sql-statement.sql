-- Modified from sql-server-performance-tuning-using-wait-statistics-whitepaper.pdf
     -- can also run sp_whoisactive if installed on sql instance
SELECT dm_exec_requests.session_id AS blocked_session_id
     , dm_exec_connections.session_id AS blocking_session_id
     , dm_os_waiting_tasks.wait_duration_ms AS blocked_time_waiting_ms
     , blocked_session.host_name AS blocked_host
     , blocked_session.program_name AS blocked_program
     , blocked_session.login_name AS blocked_login
     , blocking_session.host_name AS blocking_host
     , blocking_session.program_name AS blocking_program
     , blocking_session.login_name AS blocking_login
     , dm_os_waiting_tasks.wait_type AS blocking_resource
     , dm_os_waiting_tasks.resource_description
     , blocked_cache.text AS blocked_text
     , blocking_cache.text AS blocking_text
FROM   sys.dm_exec_connections
       INNER JOIN sys.dm_exec_requests ON dm_exec_connections.session_id = dm_exec_requests.blocking_session_id
CROSS APPLY sys.dm_exec_sql_text(dm_exec_requests.sql_handle) AS blocked_cache
CROSS APPLY sys.dm_exec_sql_text(dm_exec_connections.most_recent_sql_handle) AS blocking_cache
INNER JOIN sys.dm_os_waiting_tasks ON dm_os_waiting_tasks.session_id = dm_exec_requests.session_id
INNER JOIN sys.dm_exec_sessions AS blocked_session ON dm_exec_requests.session_id = blocked_session.session_id
INNER JOIN sys.dm_exec_sessions AS blocking_session ON dm_exec_connections.session_id = blocking_session.session_id;