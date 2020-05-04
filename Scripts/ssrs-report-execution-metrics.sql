select [Catalog].[Path] as ReportPath
	, [Catalog].[Name] as ReportName
	, [Catalog].Hidden
	, cast([Catalog].CreationDate as date) as CreationDate
	, cast([Catalog].ModifiedDate as date) as ModifiedDate
	, [CreatedBy].UserName as CreatedBy
	, ModifiedBy.UserName as ModifiedBy
	, ExecutionMetrics.*
from [ReportServer].[dbo].[Catalog]
left outer join [ReportServer].[dbo].[Users] as CreatedBy on [Catalog].CreatedByID = CreatedBy.UserID
left outer join [ReportServer].[dbo].[Users] as ModifiedBy on [Catalog].ModifiedByID = ModifiedBy.UserID
left outer join (
		select ReportID, count(*) as ExecutionCount, sum(case when Status = 'rsSuccess' then 1 else 0 end) as TotalSuccess
			, sum(case when Status <> 'rsSuccess' then 1 else 0 end) as TotalNonSuccess
			, max(case when Status = 'rsSuccess' then TimeStart else null end) as LastSuccessfulRunTime
			, max(TimeStart) as LastRunTime
			, avg(TimeDataRetrieval) as AvgDataRetrievalTime
			, avg(TimeProcessing) as AvgTimeProcessing
			, avg(TimeRendering) as AvgTimeRendering
			, avg([RowCount]) as AvgRowCount
			, min([RowCount]) as MinRowCount
			, max([RowCount]) as MaxRowCount
		from [ReportServer].[dbo].[ExecutionLog]
		group by ReportID
		) as ExecutionMetrics on [Catalog].ItemID = ExecutionMetrics.ReportID
where [Catalog].[Type] = 2 -- report type
order by 1,2
