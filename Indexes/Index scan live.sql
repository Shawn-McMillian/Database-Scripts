/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Index scan live
**
** Created By:  Shawn McMillian
**
** Description: Perform a scan of an table and index for fragmentation. Always run in the DB where the table exists
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

DECLARE @SchemaName sysname = NULL,
		@TableName sysname = NULL,
		@IndexName sysname = NULL,
		@Databaseid int,
		@IndexID int = 0;
		
--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
SET @SchemaName = 'dbo' --The schema where the table lives
SET @TableName = 'File' --The table name to scan
SET @IndexName = NULL --The index to scan, if none set to NULL

--***********************************************************************************
--****						     Input Validation   							 ****
--***********************************************************************************
--Evaluate the schema name
IF(@SchemaName IS NULL)
	BEGIN
	RAISERROR('Error, you must provide a schema Name for this script to work.',11,1) WITH NOWAIT;
	RETURN
	END

--Check to see if the table exists
IF NOT EXISTS(SELECT 1 FROM [sys].[schemas] WHERE name = @SchemaName)
	BEGIN
	RAISERROR('Error, The Schema name you provided does not exists in the database.',11,1) WITH NOWAIT;
	RETURN   
	END

--Evaluate the table name
IF(@TableName IS NULL)
	BEGIN
	RAISERROR('Error, you must provide a table Name for this script to work.',11,1) WITH NOWAIT;
	RETURN
	END

--Check to see if the table exists
IF NOT EXISTS(SELECT 1 FROM [sys].[tables] WHERE name = @TableName)
	BEGIN
	RAISERROR('Error, The table name you provided does not exists in the database.',11,1) WITH NOWAIT;
	RETURN   
	END

--Evaluate the table name
IF(@IndexName IS NOT NULL)
	BEGIN
	--Check to see if the index exists
	IF NOT EXISTS(SELECT * FROM [sys].[indexes] WHERE object_id = OBJECT_ID(@SchemaName + '.' + @TableName) AND [name] = @IndexName)
		BEGIN
		RAISERROR('Error, The index name you provided does not exists in the table.',11,1) WITH NOWAIT;
		RETURN   
		END
	END

--***********************************************************************************
--****						Build the temporary object   						 ****
--***********************************************************************************
IF(OBJECT_ID('tempdb..#IndexScanLiveResults') IS NULL)
		BEGIN
		CREATE TABLE #IndexScanLiveResults (
			[DatabaseName] nvarchar(256) NOT NULL,
			[database_id] smallint NULL,
			[SchemaName] nvarchar(256) NULL,
			[TableName] nvarchar(256) NULL,
			[object_id] int	NULL,
			[IndexName] sysname NULL,
			[index_id] int NULL,
			[avg_fragmentation_in_percent] float NULL,
			[fragment_count] bigint	NULL,
			[partition_number] int NULL,
			[index_type_desc] nvarchar(120) NULL,
			[alloc_unit_type_desc] nvarchar(120) NULL,
			[index_depth] tinyint NULL,
			[index_level] tinyint NULL,
			[Create] varchar(max) NULL,
			[Alter] varchar(max) NULL,
			[Rebuild]  varchar(max) NULL,
			[Reorg]	 varchar(max) NULL
			)
		END
	ELSE
		BEGIN
		TRUNCATE TABLE #IndexScanLiveResults;
		END

--***********************************************************************************
--****						     Perform the scan   							 ****
--***********************************************************************************
IF (@IndexName IS NULL)
	BEGIN
	INSERT INTO #IndexScanLiveResults (
			[DatabaseName] ,
			[database_id],
			[SchemaName],
			[TableName],
			[object_id],
			[IndexName],
			[index_id],
			[avg_fragmentation_in_percent],
			[fragment_count],
			[partition_number],
			[index_type_desc],
			[alloc_unit_type_desc],
			[index_depth],
			[index_level],
			[Create],
			[Alter],
			[Rebuild],
			[Reorg])

	SELECT	DB_NAME([database_id]) AS [DatabaseName],
			[database_id],
			OBJECT_SCHEMA_NAME(IPS.object_id,[database_id]) AS [SchemaName],
			OBJECT_NAME(IPS.object_id,[database_id]) AS [TableName],
			IPS.object_id,
			I.[name] AS [IndexName],
			IPS.[index_id],
			[avg_fragmentation_in_percent],
			[fragment_count],
			[partition_number],
			[index_type_desc],
			[alloc_unit_type_desc] ,
			[index_depth],
			[index_level],
			'CREATE INDEX [' + I.[name] + '] ON [' + OBJECT_SCHEMA_NAME(IPS.object_id,[database_id]) + '].[' + OBJECT_NAME(IPS.object_id,[database_id]) + '] ' AS [Create],
			'' AS [Alter],
			'ALTER INDEX [' + I.[name] + '] ON [' + OBJECT_SCHEMA_NAME(IPS.object_id,[database_id]) + '].[' + OBJECT_NAME(IPS.object_id,[database_id]) + '] REBUILD WITH(ONLINE = ON, SORT_IN_TEMPDB = ON);'  AS [Rebuild],
			'ALTER INDEX [' + I.[name] + '] ON [' + OBJECT_SCHEMA_NAME(IPS.object_id,[database_id]) + '].[' + OBJECT_NAME(IPS.object_id,[database_id]) + '] REORGANIZE;' AS [Reorg]
	FROM [sys].[dm_db_index_physical_stats](DB_ID(),OBJECT_ID(@SchemaName + '.' + @TableName),NULL,NULL,'LIMITED') AS IPS
		JOIN [sys].[indexes] AS I ON IPS.object_id = I.object_id 
			AND IPS.index_id = I.index_id;
	
	SELECT * FROM sys.indexes WHERE object_id = 2059154381
	END
ELSE
	BEGIN
	SET @IndexID = (SELECT index_id FROM sys.indexes WHERE object_id = OBJECT_ID(@SchemaName + '.' + @TableName) AND [name] = @IndexName)

	INSERT INTO #IndexScanLiveResults (
			[DatabaseName] ,
			[database_id],
			[SchemaName],
			[TableName],
			[object_id],
			[IndexName],
			[index_id],
			[avg_fragmentation_in_percent],
			[fragment_count],
			[partition_number],
			[index_type_desc],
			[alloc_unit_type_desc],
			[index_depth],
			[index_level],
			[Create],
			[Alter],
			[Rebuild],
			[Reorg])

	SELECT	DB_NAME([database_id]) AS [DatabaseName],
			[database_id],
			OBJECT_SCHEMA_NAME(IPS.object_id,[database_id]) AS [SchemaName],
			OBJECT_NAME(IPS.object_id,[database_id]) AS [TableName],
			IPS.object_id,
			I.[name] AS [IndexName],
			IPS.[index_id],
			[avg_fragmentation_in_percent],
			[fragment_count],
			[partition_number],
			[index_type_desc],
			[alloc_unit_type_desc] ,
			[index_depth],
			[index_level],
			'' AS [Create],
			'' AS [Alter],
			'' AS [Rebuild],
			'' AS [Reorg]
	FROM [sys].[dm_db_index_physical_stats](DB_ID(),OBJECT_ID(@SchemaName + '.' + @TableName),@IndexID,NULL,'LIMITED')AS IPS
		JOIN [sys].[indexes] AS I ON IPS.object_id = I.object_id 
			AND IPS.index_id = I.index_id;
	END

--***********************************************************************************
--****						     format helper scripts   						 ****
--***********************************************************************************


--***********************************************************************************
--****						     return the results      						 ****
--***********************************************************************************
SELECT *
FROM #IndexScanLiveResults

