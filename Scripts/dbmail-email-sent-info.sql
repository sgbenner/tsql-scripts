/*******************
-- Event Log
*******************/

SELECT TOP 1000 *
FROM msdb.dbo.sysmail_event_log
ORDER BY log_date DESC;

/*******************
-- All DB Mail Items
*******************/

SELECT TOP 1000 send_request_date
              , sent_date
              , sent_status
              , *
FROM msdb.dbo.sysmail_allitems
ORDER BY sysmail_allitems.send_request_date DESC;

/*******************
-- Unsent Items
*******************/

SELECT *
FROM msdb.dbo.sysmail_unsentitems;

/*******************
-- Failed Items
*******************/

SELECT *
FROM msdb.dbo.sysmail_faileditems;

/*******************
-- Sent Items
*******************/

SELECT *
FROM msdb.dbo.sysmail_sentitems;

/*******************
-- Email Attachments
*******************/

SELECT *
FROM msdb.dbo.sysmail_mailattachments;