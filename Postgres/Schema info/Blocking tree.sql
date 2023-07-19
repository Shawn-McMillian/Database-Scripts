--Blocking tree query. Procured from the internet and enhanced.
WITH recursive RecursiveLocks AS 
	(
		SELECT	pid, 
				locktype, 
				granted,
				array_position(array['AccessShare','RowShare','RowExclusive','ShareUpdateExclusive','Share','ShareRowExclusive','Exclusive','AccessExclusive'], left(mode, -4)) m,
				row(locktype, database, relation, page, tuple, virtualxid, transactionid, classid, objid, objsubid) obj
		FROM pg_locks
	), 
	
	Pairs AS 
	(
		SELECT 	W.pid waiter, 
				L.pid locker, 
				L.obj, 
				L.m
		FROM RecursiveLocks AS W 
			JOIN RecursiveLocks AS L ON L.obj IS NOT DISTINCT FROM W.obj AND L.locktype = W.locktype AND NOT L.pid = W.pid AND L.granted
		WHERE NOT W.granted
		AND NOT EXISTS (SELECT FROM RecursiveLocks AS I WHERE I.pid=L.pid AND I.locktype = L.locktype AND I.obj IS NOT DISTINCT FROM L.obj AND I.m > L.m)
	),
	Leads AS 
	(
		SELECT 	o.locker, 
				1::int lvl, 
				count(*) AS q, 
				array[locker] track, 
				false AS cycle
		FROM pairs AS o
		GROUP BY o.locker
		
		UNION ALL
		
		select 	i.locker, 
				leads.lvl + 1, 
				(SELECT COUNT(*) FROM pairs q WHERE q.locker = i.locker), 
				leads.track || i.locker, 
				i.locker = any(leads.track)
		FROM pairs AS i, leads
		WHERE i.waiter = leads.locker AND NOT CYCLE
	),
	Tree AS 
	(
		SELECT locker pid,
		locker dad,
		locker root,
		CASE WHEN CYCLE THEN track END dl, 
		null::record obj,0 lvl, 
		locker::text path, 
		array_agg(locker) over () all_pids
		FROM leads o
		WHERE
		(CYCLE AND NOT EXISTS (SELECT FROM leads i WHERE i.locker=any(o.track) AND (i.lvl>o.lvl or i.q<o.q)))
		OR (NOT CYCLE AND NOT EXISTS (SELECT FROM pairs WHERE waiter=o.locker) AND NOT EXISTS (SELECT FROM leads i WHERE i.locker=o.locker AND i.lvl>o.lvl))
		
		UNION ALL
		
		SELECT w.waiter pid,tree.pid,tree.root,CASE WHEN w.waiter=any(tree.dl) THEN tree.dl END,w.obj,tree.lvl+1,tree.path||'.'||w.waiter,all_pids || array_agg(w.waiter) over ()
		FROM tree
		JOIN pairs w ON tree.pid=w.locker AND NOT w.waiter = ANY (all_pids)
	)

SELECT 	(clock_timestamp() - A.xact_start)::interval(0) AS TransactionAge,
		(clock_timestamp() - A.state_change)::interval(0) AS ChangeAge,
		A.datname AS DatabaseName,
		A.usename AS UserName,
		A.client_addr AS ClientAddress,
		w.obj wait_on_object,
		T.pid AS ProcessID,
		A.wait_event_type AS WaitEventType,
		A.wait_event AS WaitEvent,
		pg_blocking_pids(T.pid) AS BlockedByProcessID,
		replace(a.state, 'idle in transaction', 'idletx') AS State,
		lvl AS TreeLevel,
		(SELECT COUNT(*) FROM tree p WHERE p.path ~ ('^'||T.path) AND NOT p.path=T.path) AS BlockingOthers,
		CASE WHEN T.pid=any(T.dl) THEN '!>' ELSE repeat(' .', lvl) END||' '||TRIM(LEFT(regexp_replace(A.query, e'\\s+', ' ', 'g'),300)) LatestQuery,
		(SELECT array_to_json(array_agg(json_build_object(mode, granted))) FROM pg_locks pl WHERE pl.pid = T.pid) AS locks
FROM Tree AS T
	LEFT JOIN pairs AS W ON W.waiter = T.pid AND W.locker = T.dad
	JOIN pg_stat_activity AS A using (pid)
	JOIN pg_stat_activity AS R ON R.pid = T.root
ORDER BY (now() - R.xact_start), path



