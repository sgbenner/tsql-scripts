USE SSISDB;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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
