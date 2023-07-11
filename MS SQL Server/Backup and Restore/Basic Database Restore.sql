/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Basic Database Restore
**
** Created By:  Shawn McMillian
**
** Description: Perform a basic database restore, using the values from a known backup.
**
** Databases:   master
**
** Revision History:
** ------------------------------------------------------------------------------------------------------
** Date							Name					Description
** ---------------------------- ----------------------- -------------------------------------------------
** Mon Mar 20 2006  4:19PM		Shawn McMillian			Initial script creation.
*******************************************************************************
** 
*******************************************************************************
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO


--Set the loacal variables for the script
DECLARE @ReturnError int = 0,
		@ReturnRowCount int,
		@InstanceName sysname = REPLACE(CAST(ISNULL(SERVERPROPERTY('InstanceName'),SERVERPROPERTY('ServerName')) AS nvarchar(128)), '\', '_'),
		--@RestoreProcessID smallint,
		@OriginalDatabaseExists bit,
		@NewDatabaseExists bit,
		@DatabaseRename bit,
		@SQL nvarchar(4000),
		@LoopStart int,
		@LoopEnd int,
		@LoopCurrent int,
		@DatabaseStatus nvarchar(128),
		@RecoverFile nvarchar(512),
		@SourceServerName nvarchar(128), 
		@OriginalDatabaseName nvarchar(128),
		@NewDatabaseName nvarchar(128),
		@RecoverMode nvarchar(32),
		@BackupFileLocation nvarchar(512),
		@Debug bit;

--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
SET @SourceServerName = 'local' --The name of the server where the backup was taken
SET @OriginalDatabaseName = 'HealthCheck' --The name of the database that was backed up.
SET @NewDatabaseName = NULL --The name of the database will have after restore. Leave NULL to be the same name as the backup
SET @RecoverMode = 'Recovery' --Specifies the mode in which to leave the databse after restore. Valid Values (Recovery,NoRecovery or Standby)
SET @BackupFileLocation = NULL --The location and name of the backup file. Leave this value NULL if you want the lastest backup from the source system. (Single file backup only)
SET @Debug = 1

--***********************************************************************************
--****						     Input Validation   							 ****
--***********************************************************************************
--Evaluate the DatabaseName input parameter
IF(@OriginalDatabaseName IS NULL)
	BEGIN
	RAISERROR('Error, you must provide an Original Database Name for this script to work.',11,1) WITH NOWAIT;
	RETURN
	END

--Check to see if the original database exists
IF EXISTS(SELECT 1 FROM [master].[sys].[databases] WHERE name = @OriginalDatabaseName)
	BEGIN
	SET @OriginalDatabaseExists = 1;   
	END
ELSE
	BEGIN
	SET @OriginalDatabaseExists = 0;
	END

--Check to see if the new database exists
IF EXISTS(SELECT 1 FROM [master].[sys].[databases] WHERE name = ISNULL(@NewDatabaseName,''))
	BEGIN
	SET @NewDatabaseExists = 1;   
	END
ELSE
	BEGIN
	SET @NewDatabaseExists = 0;
	SET @DatabaseStatus = (SELECT CAST(DATABASEPROPERTYEX(@NewDatabaseName,'Status') AS nvarchar(128)));
	END

--Evaluate the NewDatabaseName input parameter
IF(@NewDatabaseName IS NULL)
	BEGIN
	SET @NewDatabaseName = @OriginalDatabaseName;
	END

--Set the Rename parameter so that we know how to process this later on
IF(@OriginalDatabaseExists = 1 AND @NewDatabaseExists = 0 AND @OriginalDatabaseName = @NewDatabaseName)
	BEGIN
	--We are here because the Original DB exists and a NULL was passed in for the new DB. So we just restore the DB. No rename
	SET @DatabaseRename = 0;
	END
ELSE IF(@OriginalDatabaseExists = 1 AND @NewDatabaseExists = 0 AND @OriginalDatabaseName <> @NewDatabaseName)
	BEGIN
	--We are here because the Original DB exists and a different db name was passed in for the new DB. So we retore the original and rename it
	SET @DatabaseRename = 1;
	END
ELSE IF(@OriginalDatabaseExists = 1 AND @NewDatabaseExists = 1 AND @OriginalDatabaseName = @NewDatabaseName)
	BEGIN
	--We are here because the Original DB exists and new DB exist and have the same names. So we just restore the DB. No Rename
	SET @DatabaseRename = 0;
	END
ELSE IF(@OriginalDatabaseExists = 1 AND @NewDatabaseExists = 1 AND @OriginalDatabaseName <> @NewDatabaseName)
	BEGIN
	--We are here because the Original DB exists and new DB exist and have the different names. So we retore the original and rename it
	SET @DatabaseRename = 1;
	END
ELSE IF(@OriginalDatabaseExists = 0 AND @NewDatabaseExists = 0 AND @OriginalDatabaseName = @NewDatabaseName)
	BEGIN
	--We are here because the Original DB and the new DB don't exist and have the same name. So we just restore the DB. No Rename
	SET @DatabaseRename = 0;
	END
ELSE IF(@OriginalDatabaseExists = 0 AND @NewDatabaseExists = 0 AND @OriginalDatabaseName <> @NewDatabaseName)
	BEGIN
	--We are here because the Original DB and the new DB don't exist and have the different names. So we retore the original and rename it
	SET @DatabaseRename = 1;
	END
ELSE IF(@OriginalDatabaseExists = 0 AND @NewDatabaseExists = 1 AND @OriginalDatabaseName <> @NewDatabaseName)
	BEGIN
	--We are here because the Original DB does not exist and the new DB exists and have the different names. So we retore the original and rename it
	SET @DatabaseRename = 1;
	END

--Check the recovery mode that was passed
IF(UPPER(@RecoverMode) NOT IN('RECOVERY','NORECOVERY','STANDBY'))
	BEGIN
	RAISERROR('Error, the recovery mode passed in, does not match the expected value. Valid modes are RECOVERY, NORECOVERY or STANDBY',11,1) WITH NOWAIT;
	RETURN
	END


