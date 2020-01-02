-- Pages in Memory by DB w/ % Of Total Server Memory
WITH cteData
     AS (SELECT dm_os_buffer_descriptors.database_id
              , COUNT(*) AS TotalPages
         -- select top 1500 *
         FROM   sys.dm_os_buffer_descriptors
         GROUP BY dm_os_buffer_descriptors.database_id WITH ROLLUP)
     SELECT    CASE
                   WHEN cteData.database_id IS NULL THEN '<TOTAL>'
                   ELSE CAST(cteData.database_id AS varchar)
               END AS database_id
             , CASE
                   WHEN cteData.database_id IS NULL THEN '<TOTAL>'
                   ELSE COALESCE(databases.name , 'ResourceDB')
               END AS database_name
             , TotalPages AS total_pages
             , CAST((TotalPages * 8.0) / 1024 AS decimal(20 , 2)) AS mbs_in_buffer_pool
             , CAST(TotalPages * 8.0 / 1024 / SqlAllocatedMemory.SqlAllocatedMemory * 100 AS decimal(5 , 2)) AS percent_total_memory
     FROM      cteData
               LEFT OUTER JOIN sys.databases ON cteData.database_id = databases.database_id
     INNER JOIN
     (
         SELECT CAST(value AS int) AS SqlAllocatedMemory
         FROM   sys.configurations
         WHERE  [name] = 'max server memory (MB)'
     ) AS SqlAllocatedMemory ON 1 = 1
     ORDER BY TotalPages DESC;

-- All pages in memory
-- Run w/o TOP ### command VERY CAUTIOUSLY. A server with lots of memory could have millions of data pages in the buffer pool.
SELECT TOP 150 database_id
             , file_id
             , page_id
             , page_level
             , allocation_unit_id
             , page_type
             , row_count
             , free_space_in_bytes
             , is_modified
             , numa_node
             , read_microsec -- amount of time it took to read the extent (8 page section) into memory from disk
             , is_in_bpool_extension
FROM           sys.dm_os_buffer_descriptors;
