/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: Active queries
**
** Created By:  Shawn McMillian
**
** Description: Get all of running process
**
** Databases:   Common
**
** Revision History:
** ------------------------------------------------------------------------------------------------------
** Date							Name					Description
** ---------------------------- ----------------------- -------------------------------------------------
** July 11 2023					Shawn McMillian			Initial script creation.
*******************************************************************************
** 
*******************************************************************************
*/

--Find long running processes
SELECT
	pid,
	user,
	usename,
	application_name,
	pg_stat_activity.query_start,
	now() - pg_stat_activity.query_start AS query_time,
	state,
	wait_event_type,
	wait_event,
	query
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '1 minutes'
ORDER BY query_time desc

--Find blocking processes
SELECT
    activity.pid,
    activity.usename,
    activity.query,
    blocking.pid AS blocking_id,
    blocking.query AS blocking_query
FROM pg_stat_activity AS activity
JOIN pg_stat_activity AS blocking ON blocking.pid = ANY(pg_blocking_pids(activity.pid));

--Find locking problems
select 
    relname as relation_name, 
    pg_locks.*,
	query
from pg_locks
join pg_class on pg_locks.relation = pg_class.oid
join pg_stat_activity on pg_locks.pid = pg_stat_activity.pid;

--Gracefully kill a pid
--pg_cancel_backend(pid);

--Hard kill a pid
--pg_terminate_backend(pid)