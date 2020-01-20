USE SSISDB;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

/****************************************
-- all projects/packages, with last successful execution time, last failure time and avg execution time
****************************************/

DECLARE @LastXDaysForMetrics INT = 30;

SELECT    folders.name AS folder_name
        , projects.name AS project_name
        , packages.name AS package_name
        , CAST(projects.created_time AS DATETIME2(0)) AS project_created_time
        , CAST(projects.last_deployed_time AS DATETIME2(0)) AS project_last_deployed_time
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
        , CAST(last_execution_info.start_time AS DATETIME2(0)) AS last_exec_start_time
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

/****************************************
-- Currently Running Packages
****************************************/

SELECT folder_name
     , project_name
     , package_name
     , executed_as_name
     , CAST(start_time AS DATETIME2(0)) AS start_time
     , CAST(end_time AS DATETIME2(0)) AS end_time
     , DATEDIFF(second , start_time , GETDATE()) AS time_running_S
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
WHERE  executions.[status] IN(2 , 8); -- Running and Stopping

/****************************************
-- Agent Job(s) That Execute Package - Long query, but works great to merge data between SSISDB and sysjobs/sysjobsteps tables.
****************************************/
-- Get Job Step Info

DECLARE @Split VARCHAR(1) = '\';

WITH cteJobStepInfo
     AS (SELECT    sysjobs.name AS job_name
                 , sysjobsteps.step_name AS job_step_name
                 , sysjobs.enabled AS job_enabled
                 , sysjobsteps.command AS job_step_command
                 , SUBSTRING(sysjobsteps.command , SSISDBLocation + 7 , DtsxLocation - SSISDBLocation - 2) AS FolderProjectPackage
         FROM      msdb.dbo.sysjobs
         INNER JOIN
         (
             SELECT *
                  , CHARINDEX('SSISDB\' , sysjobsteps.command) AS SSISDBLocation
                  , CHARINDEX('.dtsx' , sysjobsteps.command) AS DtsxLocation
             FROM   msdb.dbo.sysjobsteps
             WHERE  sysjobsteps.subsystem = 'SSIS'
         ) AS sysjobsteps ON sysjobsteps.job_id = sysjobs.job_id
         WHERE SSISDBLocation <> 0) ,
     cteJobStepInfoParsed
     AS (
     -- Parse Job Step string to get folder/project/package
     SELECT job_name
          , job_step_name
          , job_enabled
          , MIN(CASE
                    WHEN PathLocation = 'Folder' THEN value
                    ELSE NULL
                END) AS folder_name
          , MIN(CASE
                    WHEN PathLocation = 'Project' THEN value
                    ELSE NULL
                END) AS project_Name
          , MIN(CASE
                    WHEN PathLocation = 'Package' THEN value
                    ELSE NULL
                END) AS package_name
     FROM   cteJobStepInfo
     CROSS APPLY
     (
         SELECT *
              , CASE ProjLevel
                    WHEN 1 THEN 'Folder'
                    WHEN 2 THEN 'Project'
                    WHEN 3 THEN 'Package'
                    ELSE ''
                END AS PathLocation
         FROM
         (
             SELECT *
                  , ROW_NUMBER() OVER(
                    ORDER BY FolderLevel) AS ProjLevel
             FROM
             (
                 SELECT value
                      , CHARINDEX(@Split + value + @Split , @Split + cteJobStepInfo.FolderProjectPackage + @Split) AS FolderLevel
                 FROM   STRING_SPLIT(cteJobStepInfo.FolderProjectPackage , @Split) AS d
             ) AS D
         ) AS D
     ) AS D
     GROUP BY job_name
            , job_step_name
            , job_enabled)
     SELECT folders.name AS folder_name
          , projects.name AS project_name
          , packages.name AS package_name
          , cteJobStepInfoParsed.job_name
          , cteJobStepInfoParsed.job_step_name
          , cteJobStepInfoParsed.job_enabled
     FROM   catalog.projects
     INNER JOIN catalog.packages ON packages.project_id = projects.project_id
     INNER JOIN catalog.folders ON projects.folder_id = folders.folder_id
     INNER JOIN cteJobStepInfoParsed ON folders.name = cteJobStepInfoParsed.folder_name
                                        AND projects.name = cteJobStepInfoParsed.project_name
                                        AND packages.name = cteJobStepInfoParsed.package_name
     ORDER BY folders.name
            , projects.name;

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

/****************************************
-- All messages for last Package Execution
****************************************/

DECLARE @FolderName  VARCHAR(255) = 'Claim'
      , @ProjectName VARCHAR(255) = 'Claim'
      , @PackageName VARCHAR(255) = 'MajescoClaim.dtsx';

SELECT    executions.execution_id
        , executions.folder_name
        , executions.project_name
        , executions.package_name
        , executions.environment_folder_name AS env_folder
        , executions.environment_name AS env_name
        , executions.executed_as_name
        , executions.server_name
        , CASE operation_messages.message_source_type
              WHEN 10 THEN 'Entry APIs, such as T-SQL and CLR Stored procedures'
              WHEN 20 THEN 'External process used to run package (ISServerExec.exe)'
              WHEN 30 THEN 'Package-level objects'
              WHEN 40 THEN 'Control Flow tasks'
              WHEN 50 THEN 'Control Flow containers'
              WHEN 60 THEN 'Data Flow task'
              ELSE ''
          END AS message_source
        , CASE operation_messages.message_type
              WHEN-1 THEN 'Unknown'
              WHEN 120 THEN 'Error'
              WHEN 110 THEN 'Warning'
              WHEN 70 THEN 'Information'
              WHEN 10 THEN 'Pre-validate'
              WHEN 20 THEN 'Post-validate'
              WHEN 30 THEN 'Pre-execute'
              WHEN 40 THEN 'Post-execute'
              WHEN 60 THEN 'Progress'
              WHEN 50 THEN 'StatusChange'
              WHEN 100 THEN 'QueryCancel'
              WHEN 130 THEN 'TaskFailed'
              WHEN 90 THEN 'Diagnostic'
              WHEN 200 THEN 'Custom'
              WHEN 140 THEN 'DiagnosticEx'
              ELSE ''
          END AS message_type
        , operation_messages.message_time
        , operation_messages.message
FROM
(
    SELECT TOP 1 *
    FROM         catalog.executions
    WHERE        folder_name = @FolderName
                 AND project_name = @ProjectName
                 AND package_name = @PackageName
    ORDER BY start_time DESC
) AS executions
INNER JOIN catalog.operations ON execution_id = operation_id
INNER JOIN catalog.operation_messages ON operations.operation_id = operation_messages.operation_id
ORDER BY message_time
       , operation_message_id;

/****************************************
-- All Error and Task Failed Messages, sorted by most recent failures
****************************************/

SELECT executions.execution_id
     , executions.folder_name
     , executions.project_name
     , executions.package_name
     , event_messages.execution_path
     , event_messages.event_name
     , CAST(event_messages.message_time AS DATETIME2(3)) AS message_time
     , event_messages.message
     , executions.environment_folder_name AS env_folder
     , executions.environment_name AS env_name
     , executions.executed_as_name
     , event_messages.message_source_name
-- select *
FROM   catalog.executions
INNER JOIN catalog.operations ON execution_id = operation_id
INNER JOIN catalog.event_messages ON operations.operation_id = event_messages.operation_id
WHERE  event_messages.message_type IN(120 , 130) -- Error, TaskFailed
       AND event_messages.message_time >= GETDATE() - 30 --- just showing last 30 days to keep result set a little smaller
ORDER BY execution_id DESC
       , message_time;