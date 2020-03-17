
DROP TABLE IF EXISTS #OrphanedUsers;

CREATE TABLE #OrphanedUsers
(db_name   sysname , 
 user_name sysname
);

INSERT INTO #OrphanedUsers
EXEC msdb..sp_msforeachdb '
use [?]
select ''?'', p.name
from sys.database_principals p
where p.type in (''G'',''S'',''U'')
and p.sid not in (select sid from sys.server_principals)
and p.name not in (
    ''dbo'',
    ''guest'',
    ''INFORMATION_SCHEMA'',
    ''sys'',
    ''MS_DataCollectorInternalUser'',
	''AllSchemaOwner''
) ;';

SELECT *
FROM   #OrphanedUsers;