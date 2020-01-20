USE SSISDB;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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