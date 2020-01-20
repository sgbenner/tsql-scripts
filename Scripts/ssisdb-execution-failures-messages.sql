USE SSISDB;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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