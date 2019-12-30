/*************************************************
-- list of jobs; selected info about jobs
*************************************************/
SELECT sysjobs.job_id
     , sysjobs.name AS job_name
     , sysjobs.enabled
     , sysjobs.description AS job_desc
     , syscategories.name AS category
     , syslogins.name AS owner_name
     , CASE sysjobs.notify_level_eventlog
           WHEN 0 THEN 'None'
           WHEN 1 THEN 'On success'
           WHEN 2 THEN 'On failure'
           WHEN 3 THEN 'On completion'
       END AS eventlog_notification
     , CASE sysjobs.notify_level_email
           WHEN 0 THEN 'None'
           WHEN 1 THEN 'On success'
           WHEN 2 THEN 'On failure'
           WHEN 3 THEN 'On completion'
       END AS email_notification
     , COALESCE(sysoperators.name , '<N/A>') AS email_operator_name
     , CASE sysjobs.delete_level
           WHEN 0 THEN 'Never'
           WHEN 1 THEN 'On success'
           WHEN 2 THEN 'On Failure'
           WHEN 3 THEN 'On completion'
       END AS delete_level
     , sysjobs.date_created
     , sysjobs.date_modified
     , sysjobs.start_step_id
       -- fields rarely needed
     , sysjobs.version_number
     , sysjobs.originating_server_id
     , sysjobs.notify_level_netsend
     , sysjobs.notify_level_page
     , sysjobs.notify_netsend_operator_id
     , sysjobs.notify_page_operator_id
FROM   msdb.dbo.sysjobs
       LEFT OUTER JOIN sys.syslogins ON sysjobs.owner_sid = syslogins.sid
LEFT OUTER JOIN msdb.dbo.syscategories ON sysjobs.category_id = syscategories.category_id
LEFT OUTER JOIN msdb.dbo.sysoperators ON sysjobs.notify_email_operator_id = sysoperators.id
ORDER BY date_created;

/*************************************************
-- Job Run History (last run time, next run time, avg duration, etc.)
*************************************************/

SELECT    sysjobs.job_id
        , sysjobs.name AS job_name
        , last_run_date_time.step_id
        , last_run_date_time.last_run_date_time
        , next_run_date_time.next_run_date_time
FROM      msdb.dbo.sysjobs
          OUTER APPLY
(
    SELECT TOP 1 *
               , CAST(CASE
                          WHEN last_run_date = 0 THEN NULL
                          ELSE concat(CAST(last_run_date AS varchar) , ' ' , concat(LEFT(last_run_time_str , 2) , ':' , SUBSTRING(last_run_time_str , 3 , 2) , ':' , RIGHT(last_run_time_str , 2)))
                      END AS datetime2(0)) AS last_run_date_time
    FROM
    (
        SELECT *
             , RIGHT('000000' + CAST(sysjobsteps.last_run_time AS varchar) , 6) AS last_run_time_str
        FROM   msdb.dbo.sysjobsteps
    ) AS last_job_run
    WHERE        sysjobs.job_id = last_job_run.job_id
    ORDER BY last_run_date_time DESC
) AS last_run_date_time
OUTER APPLY
(
    SELECT *
         , CAST(CASE
                    WHEN next_run_date = 0 THEN NULL
                    ELSE concat(CAST(next_run_date AS varchar) , ' ' , concat(LEFT(next_run_time_str , 2) , ':' , SUBSTRING(next_run_time_str , 3 , 2) , ':' , RIGHT(next_run_time_str , 2)))
                END AS datetime2(0)) AS next_run_date_time
    FROM
    (
        SELECT *
             , RIGHT('000000' + CAST(sysjobschedules.next_run_time AS varchar) , 6) AS next_run_time_str
        FROM   msdb.dbo.sysjobschedules
    ) AS next_job_run
    WHERE  sysjobs.job_id = next_job_run.job_id
) AS next_run_date_time;

/*************************************************
-- Agent Job Info
	Copied from here: https://stackoverflow.com/questions/6538851/sql-scheduled-job-query-duration-of-last-runs
*************************************************/
SELECT [sJOB].[name] AS [JobName]
     , [sDBP].[name] AS [JobOwner]
     , [sCAT].[name] AS [JobCategory]
     , [sJOB].[description] AS [JobDescription]
     , [sJSTP].[step_id] AS [JobStartStepNo]
     , [sJSTP].[step_name] AS [JobStartStepName]
     , [sJOB].[date_created] AS [JobCreatedOn]
     , [sJOB].[date_modified] AS [JobLastModifiedOn]
     , CASE [sJOB].[enabled]
           WHEN 1 THEN 'Yes'
           WHEN 0 THEN 'No'
       END AS [IsEnabled]
     , CASE
           WHEN [sSCH].[schedule_uid] IS NULL THEN 'No'
           ELSE 'Yes'
       END AS [IsScheduled]
     , CASE
           WHEN [freq_type] = 64 THEN 'Start automatically when SQL Server Agent starts'
           WHEN [freq_type] = 128 THEN 'Start whenever the CPUs become idle'
           WHEN [freq_type] IN(4 , 8 , 16 , 32) THEN 'Recurring'
           WHEN [freq_type] = 1 THEN 'One Time'
       END [ScheduleType]
     , CASE [freq_type]
           WHEN 1 THEN 'One Time'
           WHEN 4 THEN 'Daily'
           WHEN 8 THEN 'Weekly'
           WHEN 16 THEN 'Monthly'
           WHEN 32 THEN 'Monthly - Relative to Frequency Interval'
           WHEN 64 THEN 'Start automatically when SQL Server Agent starts'
           WHEN 128 THEN 'Start whenever the CPUs become idle'
       END [Occurrence]
     , CASE [freq_type]
           WHEN 4 THEN 'Occurs every ' + CAST([freq_interval] AS varchar(3)) + ' day(s)'
           WHEN 8 THEN 'Occurs every ' + CAST([freq_recurrence_factor] AS varchar(3)) + ' week(s) on ' + CASE
                                                                                                             WHEN [freq_interval]&1 = 1 THEN 'Sunday'
                                                                                                             ELSE ''
                                                                                                         END + CASE
                                                                                                                   WHEN [freq_interval]&2 = 2 THEN ', Monday'
                                                                                                                   ELSE ''
                                                                                                               END + CASE
                                                                                                                         WHEN [freq_interval]&4 = 4 THEN ', Tuesday'
                                                                                                                         ELSE ''
                                                                                                                     END + CASE
                                                                                                                               WHEN [freq_interval]&8 = 8 THEN ', Wednesday'
                                                                                                                               ELSE ''
                                                                                                                           END + CASE
                                                                                                                                     WHEN [freq_interval]&16 = 16 THEN ', Thursday'
                                                                                                                                     ELSE ''
                                                                                                                                 END + CASE
                                                                                                                                           WHEN [freq_interval]&32 = 32 THEN ', Friday'
                                                                                                                                           ELSE ''
                                                                                                                                       END + CASE
                                                                                                                                                 WHEN [freq_interval]&64 = 64 THEN ', Saturday'
                                                                                                                                                 ELSE ''
                                                                                                                                             END
           WHEN 16 THEN 'Occurs on Day ' + CAST([freq_interval] AS varchar(3)) + ' of every ' + CAST([freq_recurrence_factor] AS varchar(3)) + ' month(s)'
           WHEN 32 THEN 'Occurs on ' + CASE [freq_relative_interval]
                                           WHEN 1 THEN 'First'
                                           WHEN 2 THEN 'Second'
                                           WHEN 4 THEN 'Third'
                                           WHEN 8 THEN 'Fourth'
                                           WHEN 16 THEN 'Last'
                                       END + ' ' + CASE [freq_interval]
                                                       WHEN 1 THEN 'Sunday'
                                                       WHEN 2 THEN 'Monday'
                                                       WHEN 3 THEN 'Tuesday'
                                                       WHEN 4 THEN 'Wednesday'
                                                       WHEN 5 THEN 'Thursday'
                                                       WHEN 6 THEN 'Friday'
                                                       WHEN 7 THEN 'Saturday'
                                                       WHEN 8 THEN 'Day'
                                                       WHEN 9 THEN 'Weekday'
                                                       WHEN 10 THEN 'Weekend day'
                                                   END + ' of every ' + CAST([freq_recurrence_factor] AS varchar(3)) + ' month(s)'
       END AS [Recurrence]
     , CASE [freq_subday_type]
           WHEN 1 THEN 'Occurs once at ' + STUFF(STUFF(RIGHT('000000' + CAST([active_start_time] AS varchar(6)) , 6) , 3 , 0 , ':') , 6 , 0 , ':')
           WHEN 2 THEN 'Occurs every ' + CAST([freq_subday_interval] AS varchar(3)) + ' Second(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST([active_start_time] AS varchar(6)) , 6) , 3 , 0 , ':') , 6 , 0 , ':') + ' & ' + STUFF(STUFF(RIGHT('000000' + CAST([active_end_time] AS varchar(6)) , 6) , 3 , 0 , ':') , 6 , 0 , ':')
           WHEN 4 THEN 'Occurs every ' + CAST([freq_subday_interval] AS varchar(3)) + ' Minute(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST([active_start_time] AS varchar(6)) , 6) , 3 , 0 , ':') , 6 , 0 , ':') + ' & ' + STUFF(STUFF(RIGHT('000000' + CAST([active_end_time] AS varchar(6)) , 6) , 3 , 0 , ':') , 6 , 0 , ':')
           WHEN 8 THEN 'Occurs every ' + CAST([freq_subday_interval] AS varchar(3)) + ' Hour(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST([active_start_time] AS varchar(6)) , 6) , 3 , 0 , ':') , 6 , 0 , ':') + ' & ' + STUFF(STUFF(RIGHT('000000' + CAST([active_end_time] AS varchar(6)) , 6) , 3 , 0 , ':') , 6 , 0 , ':')
       END [Frequency]
     , [sSCH].[name] AS [JobScheduleName]
       --,[sJSTP].database_name
     , Last_Run = CONVERT(datetime , RTRIM(run_date) + ' ' + STUFF(STUFF(REPLACE(STR(RTRIM(h.run_time) , 6 , 0) , ' ' , '0') , 3 , 0 , ':') , 6 , 0 , ':'))
     , CASE [sJSTP].Last_run_outcome
           WHEN 0 THEN 'Failed'
           WHEN 1 THEN 'Succeeded'
           WHEN 2 THEN 'Retry'
           WHEN 3 THEN 'Canceled'
           WHEN 5 THEN 'Unknown'
       END AS Last_Run_Status
     , Last_Run_Duration_HHMMSS = STUFF(STUFF(REPLACE(STR([sJSTP].last_run_duration , 7 , 0) , ' ' , '0') , 4 , 0 , ':') , 7 , 0 , ':')
     , Max_Duration = STUFF(STUFF(REPLACE(STR(l.run_duration , 7 , 0) , ' ' , '0') , 4 , 0 , ':') , 7 , 0 , ':')
     , Next_Run = CONVERT(datetime , RTRIM(NULLIF([sJOBSCH].next_run_date , 0)) + ' ' + STUFF(STUFF(REPLACE(STR(RTRIM([sJOBSCH].next_run_time) , 6 , 0) , ' ' , '0') , 3 , 0 , ':') , 6 , 0 , ':'))
     , CASE [sJOB].[delete_level]
           WHEN 0 THEN 'Never'
           WHEN 1 THEN 'On Success'
           WHEN 2 THEN 'On Failure'
           WHEN 3 THEN 'On Completion'
       END AS [JobDeletionCriterion]
     , [sSVR].[name] AS [OriginatingServerName]
     , [sJSTP].subsystem
     , [sJSTP].command
     , h.message
FROM   [msdb].[dbo].[sysjobs] AS [sJOB]
       LEFT JOIN [msdb].[sys].[servers] AS [sSVR] ON [sJOB].[originating_server_id] = [sSVR].[server_id]
LEFT JOIN [msdb].[dbo].[syscategories] AS [sCAT] ON [sJOB].[category_id] = [sCAT].[category_id]
LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sJSTP] ON [sJOB].[job_id] = [sJSTP].[job_id]
                                                   AND [sJOB].[start_step_id] = [sJSTP].[step_id]
LEFT JOIN [sys].syslogins AS [sDBP] ON [sJOB].[owner_sid] = [sDBP].[sid]
LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sJOBSCH] ON [sJOB].[job_id] = [sJOBSCH].[job_id]
LEFT JOIN [msdb].[dbo].[sysschedules] AS [sSCH] ON [sJOBSCH].[schedule_id] = [sSCH].[schedule_id]
LEFT JOIN
(
    SELECT job_id
         , instance_id = MAX(instance_id)
         , MAX(run_duration) AS run_duration
    FROM   msdb.dbo.sysjobhistory
    GROUP BY job_id
) AS l ON sJOB.job_id = l.job_id
LEFT JOIN msdb.dbo.sysjobhistory AS h ON h.job_id = l.job_id
                                         AND h.instance_id = l.instance_id
ORDER BY [JobName];