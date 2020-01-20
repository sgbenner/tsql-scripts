SELECT foreign_keys.name AS fk_name, 
       OBJECT_SCHEMA_NAME(foreign_keys.parent_object_id) AS fk_schema_name, 
       OBJECT_NAME(foreign_keys.parent_object_id) AS fk_table_name, 
       foreign_key_columns.field_names AS fk_field_names, 
       OBJECT_SCHEMA_NAME(foreign_keys.referenced_object_id) AS referenced_schema_name, 
       OBJECT_NAME(foreign_keys.referenced_object_id) AS referenced_table_name, 
       foreign_key_columns.referenced_field_names, 
       foreign_keys.is_disabled, 
       foreign_keys.is_not_trusted, 
       foreign_keys.is_system_named, 
       foreign_keys.delete_referential_action_desc AS delete_action, 
       foreign_keys.update_referential_action_desc AS update_action, 
       CONCAT('ALTER TABLE [', OBJECT_SCHEMA_NAME(foreign_keys.parent_object_id), '].[', OBJECT_NAME(foreign_keys.parent_object_id), ']  WITH CHECK ADD CONSTRAINT [', foreign_keys.name, '] FOREIGN KEY(', foreign_key_columns.field_names, ') REFERENCES ', '[', OBJECT_SCHEMA_NAME(foreign_keys.referenced_object_id), '].[', OBJECT_NAME(foreign_keys.referenced_object_id), '] (', foreign_key_columns.referenced_field_names, ')') AS create_fk_script, 
       CONCAT('ALTER TABLE [', OBJECT_SCHEMA_NAME(foreign_keys.parent_object_id), '].[', OBJECT_NAME(foreign_keys.parent_object_id), ']  DROP CONSTRAINT [', foreign_keys.name, ']') AS delete_fk_script
-- select *
FROM sys.foreign_keys
     INNER JOIN
(
    SELECT foreign_keys.object_id, 
           rtriM(ltrim(STUFF(
    (
        SELECT ', ' + concat('[', COL_NAME(foreign_key_columns.parent_object_id, foreign_key_columns.parent_column_id), ']')
        FROM sys.foreign_key_columns
        WHERE foreign_keys.object_id = foreign_key_columns.constraint_object_id
        ORDER BY constraint_column_id FOR XML PATH('')
    ), 1, 1, ''))) AS field_names, 
           rtrim(ltrim(STUFF(
    (
        SELECT ', ' + concat('[', COL_NAME(foreign_key_columns.referenced_object_id, foreign_key_columns.referenced_column_id), ']')
        FROM sys.foreign_key_columns
        WHERE foreign_keys.object_id = foreign_key_columns.constraint_object_id
        ORDER BY constraint_column_id FOR XML PATH('')
    ), 1, 2, ''))) AS referenced_field_names
    FROM sys.foreign_keys
) AS foreign_key_columns ON foreign_keys.object_id = foreign_key_columns.object_id
ORDER BY fk_schema_name, 
         fk_table_name;