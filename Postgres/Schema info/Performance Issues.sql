/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: Performance issues
**
** Created By:  Shawn McMillian
**
** Description: Quickly find performance issues 
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
--Find where we are scanning, instead of using an index.
SELECT 	schemaname AS SchemaName,
		relname AS TableName,
		seq_scan AS NumSequentialScans,
		seq_tup_read AS NumColumnReads,
		seq_tup_read / seq_scan AS AvgColumnReads,
		idx_scan AS NumIndexScans,
		vacuum_count AS NumVacuum,
		autovacuum_count,
		analyze_count,
		autoanalyze_count  
FROM pg_stat_user_tables
WHERE seq_scan > 0
AND relname = 'app_persistedtechnicalvariant'
ORDER BY seq_tup_read DESC 
LIMIT 25;

--Find indexes that are not being used.
SELECT 	schemaname AS SchemaName, 
		relname AS TableName, 
		indexrelname AS IndexName, 
		idx_scan AS NumIndexScans, 
		pg_size_pretty(pg_relation_size(indexrelid)) AS IndexSize,
		pg_size_pretty(SUM(pg_relation_size(indexrelid)) OVER (ORDER BY idx_scan, indexrelid)) AS TableSize
FROM pg_stat_user_indexes
WHERE schemaname NOT IN('pg_catalog','information_schema','pglogical')
ORDER BY NumIndexScans asc;

--Find long running queries
SELECT 	userid::regrole AS UserName,
		(SELECT datname FROM pg_database WHERE oid = SS.dbid) AS DatabaseName,
		interval '1 millisecond' * total_time AS TotalExecutionTime,
		total_time / calls AS AvgExecutionTimems,
		round(( 100 * total_time / SUM(total_time) OVER ())::numeric, 2) AS PercentOfTotalTime,
		round(total_time::numeric, 2) AS TotalTime,
		round(mean_time::numeric, 2) AS MeanTime,
		stddev_time AS StanardDeviationTime,
		calls AS NumCalls,
		query
FROM pg_stat_statements AS SS
ORDER BY mean_time DESC
LIMIT 10;

--Find I/O intensive queries
SELECT 	userid::regrole AS UserName,
		(SELECT datname FROM pg_database WHERE oid = SS.dbid) AS DatabaseName,
		interval '1 millisecond' * total_time AS TotalExecutionTime,
		total_time / calls AS AvgExecutionTimems,
		(blk_read_time+blk_write_time)/calls AS IOLoad,
		blk_read_time,
		blk_write_time,
		calls AS NumCalls,
		Query
FROM pg_stat_statements AS SS
WHERE (blk_read_time+blk_write_time) > 0
ORDER BY IOLoad DESC
LIMIT 10;

--Find memory intensive queries
SELECT 	userid::regrole AS UserName,
		(SELECT datname FROM pg_database WHERE oid = SS.dbid) AS DatabaseName,
		interval '1 millisecond' * total_time AS TotalExecutionTime,
		total_time / calls AS AvgExecutionTimems,
		(shared_blks_hit+shared_blks_dirtied)/calls AS MemoryLoad,
		shared_blks_hit,
		shared_blks_dirtied,
		calls AS NumCalls,
		Query
FROM pg_stat_statements AS SS
WHERE (shared_blks_hit+shared_blks_dirtied) > 0
ORDER BY MemoryLoad DESC
LIMIT 10;

--Find temporary file usage
SELECT 	userid::regrole AS UserName,
		(SELECT datname FROM pg_database WHERE oid = SS.dbid) AS DatabaseName,
		interval '1 millisecond' * total_time AS TotalExecutionTime,
		total_time / calls AS AvgExecutionTimems,
		temp_blks_written AS TempFileLoad,
		calls AS NumCalls,
		Query
FROM pg_stat_statements AS SS
WHERE temp_blks_written > 0
ORDER BY TempFileLoad DESC
LIMIT 10;





