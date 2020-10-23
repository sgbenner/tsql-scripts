USE [ReportServer];

SELECT [Catalog].[Path] AS ReportPath
     , [Catalog].[Name] AS ReportName
     , [Catalog].Hidden
     , CAST([Catalog].CreationDate AS DATE) AS CreationDate
     , CAST([Catalog].ModifiedDate AS DATE) AS ModifiedDate
     , [CreatedBy].UserName AS CreatedBy
     , ModifiedBy.UserName AS ModifiedBy
     , ExecutionMetrics.*
FROM [dbo].[Catalog]
LEFT OUTER JOIN [dbo].[Users] AS CreatedBy ON [Catalog].CreatedByID = CreatedBy.UserID
LEFT OUTER JOIN [dbo].[Users] AS ModifiedBy ON [Catalog].ModifiedByID = ModifiedBy.UserID
LEFT OUTER JOIN
     (
         SELECT ReportID
              , COUNT(*) AS ExecutionCount
              , SUM(CASE
                        WHEN STATUS = 'rsSuccess' THEN 1
                        ELSE 0
                    END) AS TotalSuccess
              , SUM(CASE
                        WHEN STATUS <> 'rsSuccess' THEN 1
                        ELSE 0
                    END) AS TotalNonSuccess
              , MAX(CASE
                        WHEN STATUS = 'rsSuccess' THEN TimeStart
                        ELSE NULL
                    END) AS LastSuccessfulRunTime
              , MAX(TimeStart) AS LastRunTime
              , AVG(CAST(TimeDataRetrieval AS BIGINT)) AS AvgDataRetrievalTime
              , AVG(CAST(TimeProcessing AS BIGINT)) AS AvgTimeProcessing
              , AVG(CAST(TimeRendering AS BIGINT)) AS AvgTimeRendering
              , AVG([RowCount]) AS AvgRowCount
              , MIN([RowCount]) AS MinRowCount
              , MAX([RowCount]) AS MaxRowCount
         FROM [dbo].[ExecutionLog]
         GROUP BY ReportID
     ) AS ExecutionMetrics ON [Catalog].ItemID = ExecutionMetrics.ReportID
WHERE [Catalog].[Type] = 2 -- report type
ORDER BY 1
       , 2;