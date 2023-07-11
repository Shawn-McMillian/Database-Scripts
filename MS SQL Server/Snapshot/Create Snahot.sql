/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Create Snapshot
**
** Created By:  Shawn McMillian
**
** Description: Create a snapshot on a database using the Database as a template
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

DECLARE @DatabaseName sysname,
		@SnapshotName sysname,
		@Debug bit,
		@SQL nvarchar(max)


--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
SET @DatabaseName = 'DBAdmin' --The name of the database to snapshot
SET @SnapshotName = 'DBAdmin_snapshot' --What to call the snapshot
SET @Debug = 1 --set to 1 to output the command, 0 to run the command.

--***********************************************************************************
--****						     Input Validation   							 ****
--***********************************************************************************
--Evaluate the database name
IF(@DatabaseName IS NULL)
	BEGIN
	RAISERROR('Error, you must provide a database Name for this script to work.',11,1) WITH NOWAIT;
	RETURN
	END

--Check to see if the database exists
IF NOT EXISTS(SELECT 1 FROM [sys].[databases] WHERE [name] = @DatabaseName)
	BEGIN
	RAISERROR('Error, The database name you provided does not exists in the server/instance.',11,1) WITH NOWAIT;
	RETURN   
	END

--Verify that it's not a system database
IF @DatabaseName IN('master','model','tempdb')
	BEGIN
	RAISERROR('Error, you cannot snapshot a system database',11,1) WITH NOWAIT;
	RETURN   
	END

--Verify that the database is online and capable of being snapshot
IF NOT EXISTS(SELECT 1 FROM [sys].[databases] WHERE [name] = @DatabaseName AND state_desc = 'ONLINE')
	BEGIN
	RAISERROR('Error, The database provided is not online, so a snapshot cannot be generated',11,1) WITH NOWAIT;
	RETURN   
	END

--Check to see if the snapshot name already exists
IF EXISTS(SELECT 1 FROM [sys].[databases] WHERE [name] = @SnapshotName AND Source_database_id IS NOT NULL)
	BEGIN
	RAISERROR('Error, The snapshot name you provided already exists in the server/instance.',11,1) WITH NOWAIT;
	RETURN   
	END

--***********************************************************************************
--****				     Build the command and execute							 ****
--***********************************************************************************
BEGIN TRY
	--Create the Dynamic SQL to create the snapshot
	SET @SQL = 'CREATE DATABASE ' + @SnapshotName + ' ON' + CHAR(13)

	--Add the logical and physical files
	SELECT	@SQL = @SQL + CHAR(9) + '(NAME = ' + [name] + ', FILENAME = ''' + LEFT(physical_name,(LEN(physical_name) - CHARINDEX('\',REVERSE(physical_name)))) + '\' + @SnapshotName + '_' + CAST([File_id] AS varchar(3)) + '.ss''),' + CHAR(13)
	FROM [master].[sys].[master_files]
	WHERE DB_NAME(database_id) = @DatabaseName
	AND type_desc = 'ROWS'

	--clean up the string.
	SELECT	@SQL = LEFT(@SQL,LEN(@SQL)-2)

	--Finish the string
	SET @SQL = @SQL + CHAR(13) + 'AS SNAPSHOT OF ' + @DatabaseName + ';'
		
	IF @Debug = 1
		BEGIN
		PRINT @SQL
		END
	ELSE	
		BEGIN
		--Create the snaphot
		EXEC [master].[dbo].[sp_executeSQL] @stmt = @SQL;

		--Verify the snapshot was created
		IF (SELECT COUNT(*) FROM [master].[sys].[databases] WHERE [name] = @SnapshotName AND Source_database_id IS NOT NULL) = 0
			BEGIN
			THROW 51000, 'The snapshot was not created, please verify.', 1;
			END
		ELSE
			BEGIN
			PRINT 'Snapshot ' + @SnapshotName + ' Created successfully'
			END
		END
END TRY

BEGIN CATCH
	SELECT	ERROR_NUMBER() AS [ErrorNumber],
			ERROR_SEVERITY() AS [ErrorSeverity],
			ERROR_STATE() AS [ErrorState],
			ERROR_PROCEDURE() AS [ErrorProcedure],
			ERROR_LINE() AS [ErrorLine],
			ERROR_MESSAGE() AS [ErrorMessage];

	THROW;
END CATCH;