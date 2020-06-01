-- Get historical run time in seconds of each task within an ssis package.
SELECT event_messages.operation_id
    , package_name
    , message_source_name
    , MIN(message_time) Task_Start
    , MAX(message_time) Task_Finish
    , DATEDIFF(SECOND, MIN(message_time)
    , MAX(message_time)) [time_Take_Seconds]
-- select *
FROM SSISDB.[catalog].[event_messages]
INNER JOIN SSISDB.[catalog].[operations] ON operations.operation_id = event_messages.operation_id
WHERE package_name = 'Load.Bizvault.dtsx'
      AND message_time >= GETDATE() - 30
	  and message not like '%validation%' -- ignore pre-run validation messages. This messes up the true start time of the task
GROUP BY event_messages.operation_id
    , package_name
    , message_source_name
ORDER BY message_source_name
    , Task_Start;