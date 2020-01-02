SELECT schemas.Name AS SchemaName
     , tables.NAME AS TableName
     , partitions.rows AS TotalRows
     , SUM(allocation_units.total_pages) * 8 AS TotalSpaceKB
     , CAST(ROUND(((SUM(allocation_units.total_pages) * 8) / 1024.00) , 2) AS numeric(36 , 2)) AS TotalSpaceMB
     , SUM(allocation_units.used_pages) * 8 AS UsedSpaceKB
     , CAST(ROUND(((SUM(allocation_units.used_pages) * 8) / 1024.00) , 2) AS numeric(36 , 2)) AS UsedSpaceMB
     , (SUM(allocation_units.total_pages) - SUM(allocation_units.used_pages)) * 8 AS UnusedSpaceKB
     , CAST(ROUND(((SUM(allocation_units.total_pages) - SUM(allocation_units.used_pages)) * 8) / 1024.00 , 2) AS numeric(36 , 2)) AS UnusedSpaceMB
FROM   sys.tables
       INNER JOIN sys.indexes ON tables.OBJECT_ID = indexes.object_id
INNER JOIN sys.partitions ON indexes.object_id = partitions.OBJECT_ID
                             AND indexes.index_id = partitions.index_id
INNER JOIN sys.allocation_units ON partitions.partition_id = allocation_units.container_id
LEFT OUTER JOIN sys.schemas ON tables.schema_id = schemas.schema_id
WHERE  tables.NAME NOT LIKE 'dt%'
       AND tables.is_ms_shipped = 0
       AND indexes.OBJECT_ID > 255
GROUP BY tables.Name
       , schemas.Name
       , partitions.Rows