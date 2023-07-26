/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: VacuumDebug
**
** Created By:  Shawn McMillian
**
** Description: Examine the dead tuples, costs and thresholds to see if Vacuum is working
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
WITH CalculationOverride (VacuumScaleFactor, VacuumThreshold, AnalyzeScaleFactor,AnalyzeThreshold)  AS
	(
		/*
		Give us the ability to overide the scale and thresholds below
		This lets us see what table and setting override values would look like
		before we make them. Keep the values NULL of you don't want to override.
		Example override provided
		*/
		VALUES (NULL, NULL, NULL, NULL)
		--VALUES (CAST(.01 as float8), CAST(50 as float8), CAST(.01 as float8),CAST(50 as float8))
	),
	
	raw_data AS 
	(
	  SELECT
		pg_namespace.nspname,
		pg_class.relname,
		pg_class.oid AS relid,
		CAST(pg_class.reltuples AS FLOAT) AS reltuples,
		CAST(pg_stat_all_tables.n_dead_tup AS FLOAT) AS n_dead_tup,
		pg_stat_all_tables.n_mod_since_analyze,
		(SELECT split_part(x, '=', 2) FROM unnest(pg_class.reloptions) q (x) WHERE x ~ '^autovacuum_analyze_scale_factor=' ) as c_analyze_factor,
		(SELECT split_part(x, '=', 2) FROM unnest(pg_class.reloptions) q (x) WHERE x ~ '^autovacuum_analyze_threshold=' ) as c_analyze_threshold,
		(SELECT split_part(x, '=', 2) FROM unnest(pg_class.reloptions) q (x) WHERE x ~ '^autovacuum_vacuum_scale_factor=' ) as c_vacuum_factor,
		(SELECT split_part(x, '=', 2) FROM unnest(pg_class.reloptions) q (x) WHERE x ~ '^autovacuum_vacuum_threshold=' ) as c_vacuum_threshold,
		to_char(pg_stat_all_tables.last_vacuum, 'YYYY-MM-DD HH24:MI:SS') as last_vacuum,
		to_char(pg_stat_all_tables.last_autovacuum, 'YYYY-MM-DD HH24:MI:SS') as last_autovacuum,
		to_char(pg_stat_all_tables.last_analyze, 'YYYY-MM-DD HH24:MI:SS') as last_analyze,
		to_char(pg_stat_all_tables.last_autoanalyze, 'YYYY-MM-DD HH24:MI:SS') as last_autoanalyze,
		pg_stat_all_tables.vacuum_count,
		pg_stat_all_tables.autovacuum_count,
		pg_stat_all_tables.analyze_count,
		pg_stat_all_tables.autoanalyze_count,
		(SELECT CAST(VacuumScaleFactor AS text) FROM CalculationOverride) AS OverrideVacuumScaleFactor,
		(SELECT CAST(VacuumThreshold AS text) FROM CalculationOverride) AS OverrideVacuumThreshold,
		(SELECT CAST(AnalyzeScaleFactor AS text) FROM CalculationOverride) AS OverrideAnalyzeScaleFactor,
		(SELECT CAST(AnalyzeThreshold AS text) FROM CalculationOverride) AS OverrideAnalyzeThreshold
	  FROM
		pg_class
	  JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
		LEFT OUTER JOIN pg_stat_all_tables ON pg_class.oid = pg_stat_all_tables.relid
	  WHERE
		n_dead_tup IS NOT NULL
		AND nspname NOT IN ('information_schema', 'pg_catalog')
		AND nspname NOT LIKE 'pg_toast%'
		AND pg_class.relkind = 'r'
	), 
	
	Results AS 
	(
		SELECT
		*,
		COALESCE(OverrideAnalyzeScaleFactor,raw_data.c_analyze_factor, current_setting('autovacuum_analyze_scale_factor'))::float8 AS analyze_factor,
		COALESCE(OverrideAnalyzeThreshold,raw_data.c_analyze_threshold, current_setting('autovacuum_analyze_threshold'))::float8 AS analyze_threshold,
		COALESCE(OverrideVacuumScaleFactor,raw_data.c_vacuum_factor, current_setting('autovacuum_vacuum_scale_factor'))::float8 AS vacuum_factor,
		COALESCE(OverrideVacuumThreshold,raw_data.c_vacuum_threshold, current_setting('autovacuum_vacuum_threshold'))::float8 AS vacuum_threshold
	  FROM raw_data
	)
	
--Return the results from the CTE
SELECT	relid,
		nspname AS SchemaName,
		relname AS TableName,
		to_char(reltuples::bigint,'FM999,999,999,999') AS RowCount,
		to_char(n_dead_tup::bigint,'FM999,999,999,999') AS DeadRowCount,
		CASE
			WHEN reltuples = 0 AND n_dead_tup > 0 THEN 100
			WHEN reltuples = 0 AND n_dead_tup = 0 THEN 0 
			ELSE ROUND((n_dead_tup/reltuples)* 100)
		END AS PercentOfTotal,
		to_char(n_mod_since_analyze::bigint,'FM999,999,999,999') AS ModifiedSinceAnalyze,
		vacuum_factor AS ScaleFactor,
		vacuum_threshold AS Threshold,
		to_char(ROUND((reltuples + vacuum_threshold) * vacuum_factor),'FM999,999,999,999') AS VacuumAT,
		c_vacuum_factor as OrScaleFactor, --Table overide value if one exists
		c_vacuum_threshold as OrThreshold, --Table overide value if one exists
		last_vacuum AS LastVacuum,
		vacuum_count AS VacuumCount,
		last_autovacuum AS LastAutoVacuum,
		autovacuum_count AS AutoVacuumCount
FROM Results
--WHERE n_dead_tup > ROUND((reltuples + vacuum_threshold) * vacuum_factor)
ORDER BY PercentOfTotal DESC;

--Vacuum settings and alerts
/*
SELECT * 
FROM pg_settings 
WHERE name LIKE '%autovacuum%'
WHERE Name = 'log_autovacuum_min_duration'
*/