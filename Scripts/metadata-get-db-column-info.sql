
-- get database column metadata
    -- To Add: Computed Column Definition
SELECT objects.type_desc AS obj_type
     , schemas.name AS schema_name
     , objects.name AS obj_name
     , columns.name AS col_name
     , types.name AS data_type
     , concat(types.name ,
                    CASE
                        WHEN types.name IN('varchar' , 'nvarchar' , 'char' , 'nchar' , 'datetime2' , 'decimal' , 'numeric') 
						THEN concat('(' ,
								CASE
									WHEN types.name IN('datetime2') THEN CAST(columns.scale AS varchar)
									WHEN types.name IN('decimal' , 'numeric') THEN concat(columns.precision , ',' , columns.scale)
									WHEN columns.max_length = -1 THEN 'max'
									WHEN types.name IN('nchar' , 'nvarchar') THEN CAST(columns.max_length / 2 AS varchar)
									ELSE CAST(columns.max_length AS varchar)
								END , ')')
                        ELSE ''
                    END) AS col_definition
     , columns.max_length
     , columns.precision
     , columns.scale
     , columns.collation_name
     , columns.is_nullable
     , columns.is_identity
     , columns.is_computed
FROM   sys.objects
       INNER JOIN sys.columns ON objects.object_id = columns.object_id
INNER JOIN sys.schemas ON objects.schema_id = schemas.schema_id
INNER JOIN sys.types ON columns.user_type_id = types.user_type_id
WHERE  schemas.schema_id <> 4 -- ignore sys schema
