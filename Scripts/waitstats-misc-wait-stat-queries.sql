

-- Signal Wait Time as % of Total Wait Time
    -- Signal Wait: Amount of time a thread is waiting to get back on the CPU after the requested resource is available
    -- High signal wait time can indicate CPU pressure/contention
SELECT SUM(wait_time_ms) AS TotalWaitTime
     , SUM(signal_wait_time_ms) AS TotalSignalWaitTime
     , (SUM(CAST(signal_wait_time_ms AS numeric(20 , 2))) / SUM(CAST(wait_time_ms AS numeric(20 , 2))) * 100) AS PercentageSignalWaitsOfTotalTime
FROM   sys.dm_os_wait_stats;