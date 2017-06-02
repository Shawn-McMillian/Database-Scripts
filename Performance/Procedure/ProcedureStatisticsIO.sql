/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: ProcedureStatisticsIO
**
** Created By:  Shawn McMillian
**
** Description: Get basic I/O statistics about procedures on an instance
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
SELECT CASE 
			WHEN ST.dbid = 32767 THEN 'Resource' 
			ELSE DB_NAME(ST.dbid)
		END AS [DatabaseName],
		OBJECT_SCHEMA_NAME(objectid,ST.dbid) AS [SchemaName],
		OBJECT_NAME(objectid,ST.dbid) AS [ProcedureName],
		MAX(CP.usecounts) AS [ExecutionCount],
		SUM(QS.total_physical_reads + QS.total_logical_reads + QS.total_logical_writes) AS [Total_IO],
		SUM(QS.total_physical_reads + QS.total_logical_reads + QS.total_logical_writes) / (MAX(CP.usecounts)) [Avg_Total_IO],
		SUM(QS.total_physical_reads) AS [Total_Physical_Reads],
		SUM(QS.total_physical_reads) / (MAX(CP.usecounts) * 1.0) AS [Avg_Physical_Reads],    
		SUM(QS.total_logical_reads) AS [Total_Logical_Reads],
		SUM(QS.total_logical_reads) / (MAX(CP.usecounts) * 1.0) AS [Avg_Logical_Read],  
		SUM(QS.total_logical_writes) AS [Total_Logical_Writes],
		SUM(QS.total_logical_writes) / (MAX(CP.usecounts) * 1.0) AS [Avg_Logical_Writes]  
 FROM sys.dm_exec_query_stats AS QS 
	CROSS APPLY sys.dm_exec_sql_text(QS.plan_handle) AS ST
	JOIN sys.dm_exec_cached_plans AS CP ON QS.plan_handle = CP.plan_handle
 WHERE DB_NAME(ST.dbid) IS NOT NULL 
 AND CP.objtype = 'proc'
 --AND DB_NAME(ST.dbid) = 'DatabaseNameGoesHere'
 --AND OBJECT_SCHEMA_NAME(objectid,ST.dbid) = 'SchemaNamegoesHere'
 --AND OBJECT_NAME(objectid,dbid) = 'NameOfProcGoesHere'
 GROUP BY CASE 
			WHEN ST.dbid = 32767 THEN 'Resource' 
			ELSE DB_NAME(ST.dbid)
		END,
		OBJECT_SCHEMA_NAME(objectid,ST.dbid), 
		OBJECT_NAME(objectid,ST.dbid) 
ORDER BY SUM(QS.total_physical_reads + QS.total_logical_reads + QS.total_logical_writes) DESC;
--ORDER BY [Total_IO] DESC;
--ORDER BY [Avg_Total_IO] DESC;
--ORDER BY [Total_Physical_Reads] DESC;
--ORDER BY [Avg_Physical_Reads] DESC;
--ORDER BY [Total_Logical_Reads] DESC;
--ORDER BY [Avg_Logical_Read] DESC;
--ORDER BY [Total_Logical_Writes] DESC;
--ORDER BY [Avg_Logical_Writes] DESC;
--ORDER BY [ExecutionCount] DESC;
--ORDER BY [ProcedureName] ASC