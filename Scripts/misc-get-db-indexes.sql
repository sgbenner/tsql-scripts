SELECT    CASE
              WHEN objects.[type] = 'U' THEN 'Table'
              WHEN objects.[type] = 'V' THEN 'View'
          END AS object_type
         ,SCHEMA_NAME(objects.schema_id) as schema_name
         ,objects.[name] AS object_name
         ,indexes.[name] AS index_name
         ,SUBSTRING(column_names,1,LEN(column_names) - 1) AS index_columns
         ,coalesce(SUBSTRING(included_column_names,1,LEN(included_column_names) - 1),'<none>') AS included_columns
         ,CASE
              WHEN indexes.[type] = 1 THEN 'Clustered index'
              WHEN indexes.[type] = 2 THEN 'Nonclustered unique index'
              WHEN indexes.[type] = 3 THEN 'XML index'
              WHEN indexes.[type] = 4 THEN 'Spatial index'
              WHEN indexes.[type] = 5 THEN 'Clustered columnstore index'
              WHEN indexes.[type] = 6 THEN 'Nonclustered columnstore index'
              WHEN indexes.[type] = 7 THEN 'Nonclustered hash index'
          END + CASE
                    WHEN indexes.is_primary_key = 'true' THEN ' (PK)'
                    ELSE ''
                END AS index_type
         ,coalesce(indexes.filter_definition,'<none>') as filter_def
         ,indexes.is_primary_key
         ,indexes.is_unique
         ,indexes.is_disabled
FROM      sys.objects
          INNER JOIN sys.indexes ON objects.object_id = indexes.object_id
CROSS APPLY
(
    SELECT concat(columns.name,space(1),'(',case when index_columns.is_descending_key = 'true' then 'desc' else 'asc' end,')',', ')
	FROM   sys.index_columns
           INNER JOIN sys.columns ON index_columns.object_id = columns.object_id
                                         AND index_columns.column_id = columns.column_id
    WHERE  index_columns.object_id = objects.object_id
           AND index_columns.index_id = indexes.index_id
		   and index_columns.is_included_column = 'false'
    ORDER BY key_ordinal FOR XML PATH('')
) D(column_names)
CROSS APPLY
(
    SELECT concat(columns.name,space(1),'(',case when index_columns.is_descending_key = 'true' then 'desc' else 'asc' end,')',', ')
	FROM   sys.index_columns
           INNER JOIN sys.columns ON index_columns.object_id = columns.object_id
                                         AND index_columns.column_id = columns.column_id
    WHERE  index_columns.object_id = objects.object_id
           AND index_columns.index_id = indexes.index_id
		   and index_columns.is_included_column = 'true'
    ORDER BY key_ordinal FOR XML PATH('')
) Included(included_column_names)
WHERE objects.is_ms_shipped <> 1
      AND index_id > 0
ORDER BY schema_name, object_name, index_name