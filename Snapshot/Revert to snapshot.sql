/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Revert to snapshot
**
** Created By:  Shawn McMillian
**
** Description: Revert a database to a snapshot
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

--Verify that the database is online and capable of being reverted
IF NOT EXISTS(SELECT 1 FROM [sys].[databases] WHERE [name] = @DatabaseName AND state_desc = 'ONLINE')
	BEGIN
	RAISERROR('Error, The database provided is not online, so it cant be revereted',11,1) WITH NOWAIT;
	RETURN   
	END

--Check to see if the snapshot name already exists
IF NOT EXISTS(SELECT 1 FROM [sys].[databases] WHERE [name] = @SnapshotName AND Source_database_id IS NOT NULL)
	BEGIN
	RAISERROR('Error, The snapshot name you provided does not exists in the server/instance.',11,1) WITH NOWAIT;
	RETURN   
	END

--Check to see if anyone is connected to the database, or this isn't going to work
IF EXISTS(SELECT 1 FROM sys.dm_exec_sessions WHERE database_id = DB_ID(@DatabaseName))
	BEGIN
	RAISERROR('Error, The database you are trying to restore has active sessions',11,1) WITH NOWAIT;
	RETURN   
	END

--***********************************************************************************
--****				     Build the command and execute							 ****
--***********************************************************************************
BEGIN TRY
	--Create the Dynamic SQL to create the snapshot
	SET @SQL = 'RESTORE DATABASE ' + @DatabaseName + ' FROM DATABASE_SNAPSHOT = ''' + @SnapshotName + ''';' + CHAR(13)
		
	IF @Debug = 1
		BEGIN
		PRINT @SQL
		END
	ELSE	
		BEGIN
		--Create the snaphot
		EXEC [master].[dbo].[sp_executeSQL] @stmt = @SQL;
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