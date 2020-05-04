select [Catalog].[Path] as ReportPath
	, [Catalog].[Name] as ReportName
	, [Catalog].Hidden
	, [Catalog].CreationDate
	, [Catalog].ModifiedDate
	, [Catalog].CreatedByID
	, [Catalog].ModifiedByID
	, ExecutionMetrics.*
from [ReportServer].[dbo].[Catalog]
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