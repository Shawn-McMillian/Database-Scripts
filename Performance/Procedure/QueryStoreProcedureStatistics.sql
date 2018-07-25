/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: QueryStoreProcedureStatistics
**
** Created By:  Shawn McMillian
**
** Description: Get basic statistics about procedures from query store 
**
** Databases:   master
**
** Revision History:
** ------------------------------------------------------------------------------------------------------
** Date							Name					Description
** ---------------------------- ----------------------- -------------------------------------------------
** Jul 25 2018 09:53AM			Shawn McMillian			Initial script creation.
*******************************************************************************
** 
*******************************************************************************
*/
SELECT	CASE 
			WHEN DB_ID() = 32767 THEN 'Resource' 
			ELSE DB_NAME(DB_ID())
		END AS [DatabaseName],
		OBJECT_SCHEMA_NAME(Q.object_id,DB_ID()) AS [SchemaName],
		OBJECT_NAME(Q.object_id,DB_ID()) AS [ProcedureName],
		CAST(RS.last_execution_time AS Date) AS [Day],
		MAX(Q.initial_compile_start_time) AS [InitialCacheTime],
		MAX(Q.last_compile_start_time) AS [LastCacheTime],
		MAX(Q.last_execution_time) AS [LastExecutionTime],
		SUM(RS.count_executions) AS [ExecutionCount],
		AVG(RS.avg_cpu_time) AS [AvgCPU],
		AVG(RS.avg_duration) AS [AvgDuration],
		AVG(RS.avg_logical_io_reads) AS [AvgLogicalReads],
		AVG(RS.avg_logical_io_writes) AS [AvgLogicalWrites],
		AVG(RS.avg_physical_io_reads)AS [AvgPhysicalReads] 
FROM sys.query_store_query_text AS QT
	JOIN sys.query_store_query AS Q ON QT.query_text_id = Q.query_text_id
	JOIN sys.query_store_plan AS P ON Q.query_id = P.query_id
	JOIN sys.query_store_runtime_stats AS RS ON P.plan_id = RS.plan_id 
WHERE  OBJECT_NAME(Q.object_id) = 'InsertDocument'
GROUP BY Q.object_id, CAST(RS.last_execution_time AS Date)
ORDER BY [Day]