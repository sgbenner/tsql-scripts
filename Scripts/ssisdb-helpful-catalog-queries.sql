USE SSISDB;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- all projects/packages, with last successful execution time, last failure time and avg execution time
DECLARE @LastXDaysForMetrics int = 30;
SELECT    folders.name AS folder_name
        , projects.name AS project_name
        , packages.name AS package_name
        , CAST(projects.created_time AS datetime2(0)) AS project_created_time
        , CAST(projects.last_deployed_time AS datetime2(0)) AS project_last_deployed_time
          -- last execution info
        , last_execution_info.executed_as_name
        , CASE last_execution_info.STATUS
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
        , CAST(last_execution_info.start_time AS datetime2(0)) AS last_exec_start_time
        , DATEDIFF(second , last_execution_info.start_time , last_execution_info.end_time) AS last_exec_runtime_S
        , execution_metrics.total_execs
        , execution_metrics.success_execs
        , execution_metrics.failure_execs
        , execution_metrics.avg_success_exec_time_S
FROM      catalog.projects
          INNER JOIN catalog.packages ON packages.project_id = projects.project_id
INNER JOIN catalog.folders ON projects.folder_id = folders.folder_id
OUTER APPLY
(
    SELECT TOP 1 *
    FROM         [catalog].executions
    WHERE        folders.name = executions.folder_name
                 AND projects.name = executions.project_name
                 AND packages.name = executions.package_name
    ORDER BY start_time DESC
) AS last_execution_info
OUTER APPLY
(
    SELECT TOP 1 executions.folder_name
               , executions.project_name
               , executions.package_name
               , COUNT(*) AS total_execs
               , SUM(CASE
                         WHEN executions.STATUS = 7 THEN 1
                         ELSE 0
                     END) AS success_execs
               , SUM(CASE
                         WHEN executions.STATUS = 4 THEN 1
                         ELSE 0
                     END) AS failure_execs
               , AVG(CASE
                         WHEN executions.STATUS = 7 THEN DATEDIFF(second , executions.start_time , executions.end_time)
                         ELSE NULL
                     END) AS avg_success_exec_time_S
    FROM         [catalog].executions
    WHERE        folders.name = executions.folder_name
                 AND projects.name = executions.project_name
                 AND packages.name = executions.package_name
                 AND executions.created_time > DATEADD(day , @LastXDaysForMetrics * -1 , SYSDATETIME())
    GROUP BY folder_name
           , project_name
           , package_name
) AS execution_metrics
ORDER BY folders.name
       , projects.name;
