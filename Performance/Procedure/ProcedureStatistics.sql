/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: ProcedureStatistics
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
FROM sys.dm_exec_query_stats AS QS  
	JOIN sys.dm_exec_cached_plans AS CP ON QS.plan_handle = CP.plan_handle 
	CROSS APPLY sys.dm_exec_sql_text(CP.plan_handle) 
WHERE objtype = 'Proc' 
AND [text] NOT LIKE '%CREATE FUNC%' 
--AND OBJECT_NAME(objectid,dbid) = 'NameOfProcGoesHere'
GROUP BY CP.plan_handle, dbid, objectid;