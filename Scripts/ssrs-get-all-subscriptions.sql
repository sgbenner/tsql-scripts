-- List all SSRS subscriptions 
USE [ReportServer];

SELECT LEFT([Catalog].[Path] , LEN([Catalog].[Path]) - CHARINDEX('/' , REVERSE([Catalog].[Path]))) AS Folder
     , [Catalog].Name AS ReportName
     , Subscriptions.[Description]
     , CASE
           WHEN Subscriptions.DataSettings IS NOT NULL THEN 'Data Driven'
           ELSE 'Normal'
       END AS SubscriptionType
     , Subscriptions.EventType
     , Subscriptions.DeliveryExtension
     , Subscriptions.LastStatus AS LastRunStatus
     , Subscriptions.LastRunTime
     , Schedule.ScheduleID AS AgentJobName
     , [Catalog].[Description] AS ReportDescription
     , Users.UserName AS SubscriptionOwner
     , Subscriptions.ModifiedDate
     , Schedule.Name AS ScheduleName
     , CAST(Subscriptions.ExtensionSettings AS XML) AS ExtensionSettings
     , CAST(Subscriptions.MatchData AS XML) AS MatchData
     , CAST(Subscriptions.DataSettings AS XML) AS DataSettings
FROM   dbo.Subscriptions
       INNER JOIN dbo.Users ON Subscriptions.OwnerID = Users.UserID
INNER JOIN dbo.[Catalog] ON Subscriptions.Report_OID = [Catalog].ItemID
INNER JOIN dbo.ReportSchedule ON Subscriptions.Report_OID = ReportSchedule.ReportID
                                 AND Subscriptions.SubscriptionID = ReportSchedule.SubscriptionID
INNER JOIN dbo.Schedule ON ReportSchedule.ScheduleID = Schedule.ScheduleID
ORDER BY Folder
       , ReportName;