-- List of currently running SSRS Subscriptions
USE ReportServer;

SELECT Catalog.Name AS SubscriptionName
     , Subscriptions.SubscriptionID
     , ItemID AS ReportID
     , Subscriptions.LastRunTime
     , Subscriptions.LastStatus
     , Subscriptions.Description
     , COUNT(Notifications.ReportID) AS TotalReportsPending
     , COUNT(DISTINCT Notifications.ActivationID) AS TotalTimesRan
FROM dbo.Subscriptions
LEFT JOIN dbo.Catalog ON Catalog.ItemID = Subscriptions.Report_OID
LEFT JOIN dbo.Notifications ON Catalog.ItemID = Notifications.ReportID
WHERE Subscriptions.LastStatus NOT LIKE 'Done:%'
      AND Subscriptions.LastStatus NOT LIKE 'Mail sent%'
      AND Subscriptions.LastStatus NOT LIKE 'New Subscriptio%'
GROUP BY Catalog.Name
       , Subscriptions.SubscriptionID
       , ItemID
       , Subscriptions.LastRunTime
       , Subscriptions.LastStatus
       , Subscriptions.Description
ORDER BY Subscriptions.LastRunTime;
