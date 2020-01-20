-- Find potential missing indexes. This will return a list of foreign keys without an index with the foreign key field as ordinal position 1 in the index
	-- Table with a small amount of rows can probably be ignored as they are unlikely an issue, but keeping in query so we have a full list here.
WITH cteRowCounts
     AS (SELECT tables.object_id
              , partitions.rows AS TotalRows
         FROM   sys.tables
                INNER JOIN sys.indexes ON tables.OBJECT_ID = indexes.object_id
         INNER JOIN sys.partitions ON indexes.object_id = partitions.OBJECT_ID
                                      AND indexes.index_id = partitions.index_id
         WHERE  tables.NAME NOT LIKE 'dt%'
                AND tables.is_ms_shipped = 0
                AND indexes.type_desc IN('HEAP' , 'CLUSTERED')
                AND indexes.OBJECT_ID > 255)
     SELECT foreign_key_columns.parent_object_id AS parent_object_id
          , OBJECT_SCHEMA_NAME(foreign_key_columns.parent_object_id) AS schema_name
          , OBJECT_NAME(foreign_key_columns.parent_object_id) AS table_name
          , COL_NAME(foreign_key_columns.parent_object_id , foreign_key_columns.parent_column_id) AS column_name
          , foreign_keys.name AS fk_name
          , OBJECT_SCHEMA_NAME(foreign_keys.referenced_object_id) AS ref_schema_name
          , OBJECT_NAME(foreign_key_columns.referenced_object_id) AS ref_table_name
          , COL_NAME(foreign_key_columns.referenced_object_id , foreign_key_columns.referenced_column_id) AS ref_column_name
          , FKTable.TotalRows AS fk_total_rows
          , RefTable.TotalRows AS ref_total_rows
     FROM   sys.foreign_key_columns
            INNER JOIN sys.foreign_keys ON foreign_key_columns.constraint_object_id = foreign_keys.object_id
     INNER JOIN cteRowCounts AS FKTable ON foreign_key_columns.parent_object_id = FKTable.object_id
     INNER JOIN cteRowCounts AS RefTable ON foreign_keys.referenced_object_id = RefTable.object_id
     WHERE  NOT EXISTS
     (
         SELECT *
         FROM   sys.index_columns
         WHERE  foreign_key_columns.parent_object_id = index_columns.object_id
                AND foreign_key_columns.parent_column_id = index_columns.column_id
                AND index_columns.key_ordinal = 1
     );