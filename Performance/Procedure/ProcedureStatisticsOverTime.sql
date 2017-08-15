/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: ProcedureStatisticsOverTime
**
** Created By:  Shawn McMillian
**
** Description: Get basic statistics about procedures on an instance
**
** Databases:   master
**
** Revision History:
** ------------------------------------------------------------------------------------------------------
** Date							Name					Description
** ---------------------------- ----------------------- -------------------------------------------------
** Oct 28 2011 12:28PM			Shawn McMillian			Initial script creation.
*******************************************************************************
** 
*******************************************************************************
*/
--Just in case the temp tables exist, lets drop them first
IF (SELECT OBJECT_ID('tempdb.dbo.#StartingStatistics')) IS NOT NULL	
	BEGIN
	DROP TABLE #StartingStatistics
	END
	
IF (SELECT OBJECT_ID('tempdb.dbo.#EndingStatistics')) IS NOT NULL	
	BEGIN
	DROP TABLE #EndingStatistics
	END
	
--Insert the first set of data into a temp table
SELECT	CASE 
			WHEN dbid = 32767 THEN 'Resource' 
			ELSE DB_NAME(dbid)
		END AS [DatabaseName],
		OBJECT_SCHEMA_NAME(objectid,dbid) AS [SchemaName],
		OBJECT_NAME(objectid,dbid) AS [ProcedureName],
		MAX(QS.creation_time) AS [CacheTime],
		MAX(last_execution_time) AS [LastExecutionTime],
		MAX(usecounts) AS [ExecutionCount],
		SUM(total_worker_time) / SUM(usecounts) AS [AvgCPU],
		SUM(total_elapsed_time) / SUM(usecounts) AS [AvgElapsed],
		SUM(total_logical_reads) / SUM(usecounts) AS [AvgLogicalReads],
		SUM(total_logical_writes) / SUM(usecounts) AS [AvgLogicalWrites],
		SUM(total_physical_reads) / SUM(usecounts)AS [AvgPhysicalReads]
INTO #StartingStatistics		
FROM sys.dm_exec_query_stats AS QS  
	JOIN sys.dm_exec_cached_plans AS CP ON QS.plan_handle = CP.plan_handle 
	CROSS APPLY sys.dm_exec_sql_text(CP.plan_handle) 
WHERE objtype = 'Proc' 
AND [text] NOT LIKE '%CREATE FUNC%' 
--AND OBJECT_NAME(objectid,dbid) = 'NameOfProcGoesHere'
GROUP BY CP.plan_handle, dbid, objectid;

--Delay for 1 minute
WAITFOR DELAY '00:01'

--Insert the second set of data into a temp table
SELECT	CASE 
			WHEN dbid = 32767 THEN 'Resource' 
			ELSE DB_NAME(dbid)
		END AS [DatabaseName],
		OBJECT_SCHEMA_NAME(objectid,dbid) AS [SchemaName],
		OBJECT_NAME(objectid,dbid) AS [ProcedureName],
		MAX(QS.creation_time) AS [CacheTime],
		MAX(last_execution_time) AS [LastExecutionTime],
		MAX(usecounts) AS [ExecutionCount],
		SUM(total_worker_time) / SUM(usecounts) AS [AvgCPU],
		SUM(total_elapsed_time) / SUM(usecounts) AS [AvgElapsed],
		SUM(total_logical_reads) / SUM(usecounts) AS [AvgLogicalReads],
		SUM(total_logical_writes) / SUM(usecounts) AS [AvgLogicalWrites],
		SUM(total_physical_reads) / SUM(usecounts)AS [AvgPhysicalReads]
INTO #EndingStatistics		
FROM sys.dm_exec_query_stats AS QS  
	JOIN sys.dm_exec_cached_plans AS CP ON QS.plan_handle = CP.plan_handle 
	CROSS APPLY sys.dm_exec_sql_text(CP.plan_handle) 
WHERE objtype = 'Proc' 
AND [text] NOT LIKE '%CREATE FUNC%' 
--AND OBJECT_NAME(objectid,dbid) = 'NameOfProcGoesHere'
GROUP BY CP.plan_handle, dbid, objectid;

--return the deltas
SELECT 	SS.DatabaseName,
		SS.SchemaName,
		SS.ProcedureName,
		ES.ExecutionCount - SS.ExecutionCount AS [DeltaCount],
		(ES.ExecutionCount - SS.ExecutionCount)/60 AS [DeltaCountPerSec]
FROM #StartingStatistics AS SS
	JOIN #EndingStatistics AS ES ON SS.DatabaseName = ES.DatabaseName
		AND SS.SchemaName = ES.SchemaName
		AND SS.ProcedureName = ES.ProcedureName
--WHERE T1.ProcedureName = 'NameOfProcGoesHere'
ORDER BY [DeltaCount] DESC
