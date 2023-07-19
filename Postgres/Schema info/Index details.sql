/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: Index details
**
** Created By:  Shawn McMillian
**
** Description: Get all of the details for the tables in the database. 
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
SELECT 	N.nspname AS SchemaName,
		C.relname AS TableName,
    	C1.relname AS IndexName,
    	AM.amname AS IndexType,
		pg_size_pretty(pg_relation_size(S.indexrelid)) AS IndexSize,
		case IX.indisprimary when 'f' then 'NO' else 'YES' end IS_PRIMARY,
		case IX.indisclustered when 'f' then 'NO' else 'YES' end IS_CLUSTERED,
		case IX.indisunique when 'f' then 'NO' else 'YES' end IS_UNIQUE,
		--case IX.indisvalid when 'f' then 'NO' else 'YES' end IS_VALID,
		S.idx_scan AS IndexUsed,
		s.idx_tup_fetch AS IndexColumnsRead,
		S.idx_tup_read AS ColumnsRead,
		array_to_string(array_agg(a.attname), ', ') AS IndexColumns
FROM pg_class AS C
	JOIN pg_namespace AS N ON C.relnamespace = N.oid
	JOIN pg_index AS IX ON C.oid = IX.indrelid
	JOIN pg_class AS C1 ON IX.indexrelid = C1.oid
	JOIN pg_am AS AM ON C.relam = AM.oid
	JOIN pg_attribute AS A ON C.oid = A.attrelid
	LEFT JOIN pg_stat_user_indexes AS S ON IX.indexrelid = S.indexrelid
WHERE C.relkind = 'r' --Tables
AND N.nspname NOT IN('pg_catalog','information_schema','pglogical')
AND A.attnum = ANY(IX.indkey)
--AND C1.relname not in (SELECT conname FROM pg_constraint)
--AND C.relname = 'TableName'
--AND N.nspname = 'SchemaName'
GROUP BY N.nspname,
		C.relname,
    	C1.relname,
    	AM.amname,
		S.indexrelid,
		IX.indisunique,
		IX.indisprimary,
		IX.indisclustered,
		IX.indisvalid,
		S.idx_scan,
		S.idx_tup_read,
		s.idx_tup_fetch
ORDER BY N.nspname asc, TableName asc, IndexName asc;



