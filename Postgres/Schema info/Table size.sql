/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: Table Size
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
		to_char(C.reltuples::bigint,'FM9,999,999,999') AS RowEstimate,
		pg_size_pretty(pg_table_size(C.oid)) AS TableSize,
		pg_size_pretty(pg_indexes_size(C.oid)) AS IndexSize,
		pg_size_pretty(pg_total_relation_size(C.oid)) AS TotalSize,
		C.relhasindex
FROM pg_class AS c
JOIN pg_namespace AS N ON n.oid = c.relnamespace
WHERE 	C.relkind = 'r'
--AND 	C.reltuples::bigint > 0
AND 	N.nspname NOT IN('pg_catalog','information_schema','pglogical')
--AND  	C.relname = 'mytable'
--AND   N.nspname = 'myschema'
ORDER BY SchemaName asc, TableName asc;
