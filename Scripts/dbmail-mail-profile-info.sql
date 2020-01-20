/*************************************************************
-- Get All DB Mail Profiles/Accounts/Server Relevant Info
*************************************************************/
SELECT   sysmail_profile.profile_id
       , sysmail_profileaccount.account_id AS account_id
       , sysmail_profile.name AS profile_name
       , sysmail_profile.description AS profile_description
       , sysmail_account.name AS account_name
       , sysmail_account.email_address
       , sysmail_account.display_name
       , sysmail_account.replyto_address
       , sysmail_server.servertype
       , sysmail_server.servername
       , sysmail_server.port
       , sysmail_server.username
       , sysmail_server.use_default_credentials
       , sysmail_server.enable_ssl
       , sysmail_server.flags
       , sysmail_server.timeout
       , cast((SELECT * FROM msdb.dbo.sysmail_configuration FOR xml PATH) as xml) as mail_configs
	   -- last modified times/users
       , sysmail_profile.last_mod_datetime AS profile_last_mod_datetime
       , sysmail_profile.last_mod_user AS profile_last_mod_user
       , sysmail_profileaccount.last_mod_datetime AS profileaccount_last_mod_datetime
       , sysmail_profileaccount.last_mod_user AS profileaccount_last_mod_user
       , sysmail_account.last_mod_datetime AS account_last_mod_datetime
       , sysmail_account.last_mod_user AS account_last_mod_user
       , sysmail_server.last_mod_datetime AS server_last_mod_datetime
       , sysmail_server.last_mod_user AS server_last_mod_user
FROM msdb.dbo.sysmail_profile
INNER JOIN msdb.dbo.sysmail_profileaccount ON sysmail_profile.profile_id = sysmail_profileaccount.profile_id
INNER JOIN msdb.dbo.sysmail_account ON sysmail_profileaccount.account_id = sysmail_account.account_id
INNER JOIN msdb.dbo.sysmail_server ON sysmail_account.account_id = sysmail_server.account_id;