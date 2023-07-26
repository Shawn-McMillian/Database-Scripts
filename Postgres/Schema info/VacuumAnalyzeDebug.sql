/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: VacuumAnalyzeDebug
**
** Created By:  Shawn McMillian
**
** Description: Examine the dead tuples, costs and thresholds to see if Vacuum and Analyze are working
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
WITH raw_data AS (
  SELECT
    pg_namespace.nspname,
    pg_class.relname,
    pg_class.oid AS relid,
    pg_class.reltuples,
    pg_stat_all_tables.n_dead_tup,
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
	pg_stat_all_tables.autoanalyze_count
  FROM
    pg_class
  JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
    LEFT OUTER JOIN pg_stat_all_tables ON pg_class.oid = pg_stat_all_tables.relid
  WHERE
    n_dead_tup IS NOT NULL
    AND nspname NOT IN ('information_schema', 'pg_catalog')
    AND nspname NOT LIKE 'pg_toast%'
    AND pg_class.relkind = 'r'
), data AS (
  SELECT
    *,
    COALESCE(raw_data.c_analyze_factor, current_setting('autovacuum_analyze_scale_factor'))::float8 AS analyze_factor,
    COALESCE(raw_data.c_analyze_threshold, current_setting('autovacuum_analyze_threshold'))::float8 AS analyze_threshold,
    COALESCE(raw_data.c_vacuum_factor, current_setting('autovacuum_vacuum_scale_factor'))::float8 AS vacuum_factor,
    COALESCE(raw_data.c_vacuum_threshold, current_setting('autovacuum_vacuum_threshold'))::float8 AS vacuum_threshold
  FROM raw_data
)
SELECT	relid,
		nspname AS SchemaName,
		relname AS TableName,
		to_char(reltuples::bigint,'FM999,999,999,999') AS RowCount,
		n_dead_tup AS DeadRowCount,
		'VacuumSettings' AS VacuumSettings,
		vacuum_factor AS VacuumFactor,
		vacuum_threshold AS VacuumThreshold,
		to_char(ROUND(reltuples * vacuum_factor + vacuum_threshold),'FM999,999,999,999') AS VacuumThreshold,
		c_vacuum_factor as VacuumOverrideFactor,
		c_vacuum_threshold as VacuumOverrideThreshold,
		last_vacuum AS LastVacuum,
		vacuum_count AS VacuumCount,
		last_autovacuum AS LastAutoVacuum,
		autovacuum_count AS AutoVacuumCount,
		'AnalyzeSettings' AS VacuumSettings,
		analyze_factor AS AnalyzeFactor,
		analyze_threshold AS AnalyzeThreshold,
		to_char(ROUND(reltuples * analyze_factor + analyze_threshold),'FM999,999,999,999') AS AnalyzeThreshold,
		c_analyze_factor as AnalyzeOverrideFactor,
		c_analyze_threshold as AnalyzeOverrideThreshold,
		last_analyze AS LastAnalyze,
		analyze_count AS AnalyzeCount,
		last_autoanalyze AS LastAutoAnalyze,
		autoanalyze_count AS AutoAnalyzeCount,
		to_char(n_mod_since_analyze::bigint,'FM999,999,999,999') AS ModifiedSinceAnalyze
FROM data
ORDER BY DeadRowCount DESC;