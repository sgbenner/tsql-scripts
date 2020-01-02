-- Get list of top 50 most expensive queries by total_worker_time
	-- can be helpful when looking for pain points in current server performance
SELECT TOP 50 CAST(query_stats.creation_time AS datetime2(0)) AS creation_time
            , CAST(query_stats.last_execution_time AS datetime2(0)) AS last_execution_time
            , query_stats.execution_count
            , query_stats.execution_count / IIF(CAST(query_stats.creation_time AS date) = CAST(query_stats.last_execution_time AS date) , 1 , DATEDIFF(day , query_stats.creation_time , query_stats.last_execution_time)) AS execs_per_day_est
            , query_stats.total_worker_time / 1000 AS total_worker_time_ms
            , query_stats.last_worker_time / 1000 AS last_worker_time_ms
            , query_stats.min_worker_time / 1000 AS min_worker_time_ms
            , query_stats.max_worker_time / 1000 AS max_worker_time_ms
            , query_stats.total_rows
            , query_stats.last_rows
            , query_stats.min_rows
            , query_stats.max_rows
            , IIF(sql_text.objectid IS NOT NULL , concat('[' , DB_NAME(sql_text.dbid) , '].[' , OBJECT_SCHEMA_NAME(sql_text.objectid , sql_text.dbid) , '].[' , OBJECT_NAME(sql_text.objectid , sql_text.dbid) , ']') , '') AS db_obj_name
            , sql_text.text AS sql_text
            , sql_plan.query_plan
FROM          sys.dm_exec_query_stats AS query_stats
              CROSS APPLY sys.dm_exec_sql_text(query_stats.sql_handle) AS sql_text
CROSS APPLY sys.dm_exec_query_plan(query_stats.plan_handle) AS sql_plan
WHERE         COALESCE(DB_NAME(sql_text.dbid) , '') <> 'SSISDB' -- ignore SSISDB queries
ORDER BY total_worker_time DESC;