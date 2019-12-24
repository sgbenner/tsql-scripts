SELECT foreign_keys.name AS fk_name, 
       OBJECT_SCHEMA_NAME(foreign_keys.parent_object_id) as fk_schema_name,
	   OBJECT_NAME(foreign_keys.parent_object_id) AS fk_table_name, 
       foreign_key_columns.field_names as fk_field_names,
	   OBJECT_SCHEMA_NAME(foreign_keys.referenced_object_id) as referenced_schema_name,
       OBJECT_NAME(foreign_keys.referenced_object_id) AS referenced_table_name, 
       foreign_key_columns.referenced_field_names, 
       foreign_keys.is_disabled, 
       foreign_keys.is_not_trusted, 
       foreign_keys.is_system_named, 
       foreign_keys.delete_referential_action_desc AS delete_action, 
       foreign_keys.update_referential_action_desc AS update_action, 
       CONCAT('ALTER TABLE [',OBJECT_SCHEMA_NAME(foreign_keys.parent_object_id),'].[',OBJECT_NAME(foreign_keys.parent_object_id),']  WITH NOCHECK ADD CONSTRAINT [',foreign_keys.name,'] FOREIGN KEY(',foreign_key_columns.field_names,') REFERENCES ','[',OBJECT_SCHEMA_NAME(foreign_keys.referenced_object_id),'].[',OBJECT_NAME(foreign_keys.referenced_object_id),'] (',foreign_key_columns.referenced_field_names,')') AS create_fk_script, 
       CONCAT('ALTER TABLE [',OBJECT_SCHEMA_NAME(foreign_keys.parent_object_id),'].[',OBJECT_NAME(foreign_keys.parent_object_id),']  DROP CONSTRAINT [',foreign_keys.name,']') AS delete_fk_script
-- select *
FROM sys.foreign_keys
     CROSS APPLY
(
    SELECT foreign_key_columns.constraint_object_id, 
           STRING_AGG(concat('[', COL_NAME(foreign_key_columns.parent_object_id, foreign_key_columns.parent_column_id), ']'), ', ') AS field_names, 
           STRING_AGG(concat('[', COL_NAME(tables.object_id, foreign_key_columns.referenced_column_id), ']'), ', ') AS referenced_field_names
    FROM sys.foreign_key_columns
         INNER JOIN sys.tables ON tables.OBJECT_ID = foreign_key_columns.referenced_object_id
    WHERE foreign_keys.OBJECT_ID = foreign_key_columns.constraint_object_id
    GROUP BY foreign_key_columns.constraint_object_id
) AS foreign_key_columns
order by fk_schema_name, fk_table_name
