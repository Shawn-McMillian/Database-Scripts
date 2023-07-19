/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: Vacuum Analyze debug
**
** Created By:  Shawn McMillian
**
** Description: Look at the settings and results for vacuum and analyze
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

--Look at all of the tables and see which are not getting vacummed as expected. Based on defaults
SELECT	schemaname AS SchemaName,
		relname AS TableName,
		n_live_tup AS LiveTuples,
		n_dead_tup AS DeadTuples,
		ROUND(((CAST(n_dead_tup AS NUMERIC)/(CAST(n_live_tup AS NUMERIC)+1)) * 100),2) AS "ScalePercent",
		n_ins_since_vacuum AS InsertedSinceLastVacuum,
		n_mod_since_analyze AS ModifiedSinceLastAnalyze,
		'Vacuum' AS "Vacuum",
		to_char(last_autovacuum, 'YYYY-MM-DD HH24:MI:SS') AS LastAutovacuumDate,
		to_char(last_vacuum, 'YYYY-MM-DD HH24:MI:SS') AS LastVacuumDate,
		vacuum_count AS VacuumCount,
		autovacuum_count AS AutoVacuumCount,
		'Analyze' AS "Analyze",
		to_char(last_autoanalyze, 'YYYY-MM-DD HH24:MI:SS') AS LastAutoanalyzeDate,
		to_char(last_analyze, 'YYYY-MM-DD HH24:MI:SS') AS LastAnalyzeDate,
		analyze_count AS AnalyzeCount,
		autoanalyze_count AS AutoAnalyzeCount
FROM pg_stat_all_tables
ORDER BY DeadTuples desc;

--Look at the settings to get the default vaules
select category, name,setting,unit,source,min_val,max_val from pg_settings where category = 'Autovacuum';







