
-- Get the list of currently running SQL Agent Jobs, along with info about the job step currently running
SELECT j.name AS job_name
     , CAST(ja.start_execution_date AS DATETIME2(0)) AS job_start_date_time
     , CAST(DATEADD(second, DATEDIFF(second, start_execution_date, GETDATE()), '1900-01-01') AS TIME(0)) AS job_run_duration
     , CASE
           WHEN ja.last_executed_step_id IS NULL THEN js.step_id
           ELSE js2.step_id
       END AS job_step_id
     , CASE
           WHEN ja.last_executed_step_id IS NULL THEN js.step_name
           ELSE js2.step_name
       END AS job_step_name_running
     , CASE
           WHEN ja.last_executed_step_id IS NULL THEN js.subsystem
           ELSE js2.subsystem
       END AS job_step_subsystem
     , CASE
           WHEN ja.last_executed_step_id IS NULL THEN js.command
           ELSE js2.command
       END AS job_step_command
FROM msdb.dbo.sysjobactivity ja
JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
LEFT JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
                                     AND CASE
                                             WHEN ja.last_executed_step_id IS NULL THEN j.start_step_id
                                             ELSE ja.last_executed_step_id
                                         END = js.step_id
LEFT JOIN msdb.dbo.sysjobsteps js2 ON js.job_id = js2.job_id
                                      AND js.on_success_step_id = js2.step_id
WHERE ja.session_id =
      (
          SELECT TOP 1 session_id
          FROM msdb.dbo.syssessions
          ORDER BY agent_start_date DESC
      )
      AND start_execution_date IS NOT NULL
      AND stop_execution_date IS NULL;