/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: ProcedureTextAndPlans
**
** Created By:  Shawn McMillian
**
** Description: Get the text and plan for all procedures
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
			WHEN ST.dbid = 32767 THEN 'Resource' 
			ELSE DB_NAME(ST.dbid)
		END AS [DatabaseName],
		OBJECT_SCHEMA_NAME(ST.objectid,ST.dbid) AS [SchemaName],
		OBJECT_NAME(ST.objectid,ST.dbid) AS [ProcedureName],
		UseCounts AS [CacheUseCount], 
		Cacheobjtype AS [CacheObjectType], 
		Objtype AS [ObjectType], 
		[TEXT] AS [ProcedureText], 
		query_plan AS [QueryPlan]
FROM sys.dm_exec_cached_plans  AS CP
	CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS ST
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS QP
WHERE DB_NAME(ST.dbid) <> 'Resource'
--AND OBJECT_SCHEMA_NAME(ST.objectid,ST.dbid) = 'SchemaNamegoesHere'
--AND OBJECT_NAME(ST.objectid,dbid) = 'NameOfProcGoesHere'
ORDER BY UseCounts DESC

