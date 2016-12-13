/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Basic database log backup
**
** Created By:  Shawn McMillian
**
** Description: Perform a basic database log backup, using the default settings. Great for taking a quick backup.
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
DECLARE @ReturnError int,
		@InstanceNameFS nvarchar(32),
		@Key nvarchar(512),
		@InstanceName nvarchar(256) = REPLACE(CAST(ISNULL(SERVERPROPERTY('InstanceName'),SERVERPROPERTY('ServerName')) AS nvarchar(128)), '\', '_'),
		@StartTime datetime = CURRENT_TIMESTAMP,
		@TimeStamp nvarchar(15),
		@DatabaseName sysname = '',
		@BackupDirectory nvarchar(256) = '',
		@BackupDirectoryFull nvarchar(512) = '',
		@BackupFileNameFull nvarchar(1024) = '',
		@BackupName nvarchar(128) = '',
		@BackupDescription nvarchar(512) = '',
		@BackupTool nvarchar(32) = 'SQLServer',
		@BackupExtension char(3) = 'trn',
		@SQL nvarchar(max) = '',
		@Debug bit

DECLARE @SubDirectory TABLE(SubDirectory nvarchar(512));

--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
SET @DatabaseName = 'master' --change me to the database you want to backup
SET @Debug = 1 --Change to 0 (zero) to take the backup.


--*************************************************************************************
--****								Backup location								   ****
--*************************************************************************************
--Set the location where all backups should go.
EXEC @ReturnError = [master].[dbo].[xp_regread]	@rootkey = N'HKEY_LOCAL_MACHINE',
												@key = N'Software\Microsoft\Microsoft SQL Server\Instance Names\SQL',
												@value_name = @InstanceName,
												@InstanceNameFS = @InstanceNameFS OUTPUT;

	--Check the error codes
	IF(@ReturnError <> 0) 
		BEGIN 
		PRINT 'Error, While attempting to get the file system instance name from the registry';
		RETURN;
		END

--Construct the key for the registry location
SET @Key = 'Software\Microsoft\Microsoft SQL Server\' + @InstanceNameFS + '\MSSQLServer'

--Get the backup directory
EXEC @ReturnError = [master].[dbo].[xp_regread]	@rootkey = N'HKEY_LOCAL_MACHINE',
												@key = @Key,
												@value_name = 'BackupDirectory',
												@BackupDirectory = @BackupDirectory OUTPUT;

	--Check the error codes
	IF(@ReturnError <> 0) 
		BEGIN 
		PRINT 'Error, While attempting to get the instance backup directory from the registry';
		RETURN;  
		END

--*************************************************************************************
--****							Backup properties								   ****
--*************************************************************************************
SET @TimeStamp = CONVERT(nvarchar, @StartTime, 112) + CAST(DATEPART(hh,@StartTime) AS nvarchar) + CAST(DATEPART(mi,@StartTime) AS nvarchar);

SELECT	@BackupDirectoryFull = @BackupDirectory + '\' + @DatabaseName,
		@BackupFileNameFull =	CASE
									WHEN LOWER(@BackupTool) = LOWER('SQLServer') THEN @BackupDirectory + '\' + @DatabaseName + '\' + @DatabaseName + '_' + 'db_' + LEFT(REPLACE(REPLACE(REPLACE(CONVERT(nvarchar(128),CURRENT_TIMESTAMP,120),'-',''),' ',''),':',''),12) + '.' + @BackupExtension
									WHEN LOWER(@BackupTool) = LOWER('SQLSafe') THEN @BackupDirectory + '\%database%\%Instance%_%database%_%backupType%_%timestamp%.' + @BackupExtension
									WHEN LOWER(@BackupTool) = LOWER('LiteSpeed') THEN @BackupDirectory + '\%D\%D_%T_%z.' + @BackupExtension
									ELSE 'Break Me'
								END,
		@BackupName = @DatabaseName + '-Log database backup',
		@BackupDescription = 'Log backup of database [' + @InstanceName + '].[' + @DatabaseName + '] at ' + CAST(@TimeStamp AS nvarchar)

--Create a text version of the command to be run
SET @SQL= 'BACKUP	LOG ' + @DatabaseName + '
		TO DISK = ''' + @BackupFileNameFull + '''
		WITH NOFORMAT, 
		INIT,
		NAME = ''' + @BackupName + ''',
		DESCRIPTION = ''' + @BackupDescription + ''',
		COMPRESSION,
		NOREWIND, 
		NOUNLOAD,
		SKIP,
		STATS = 10;'

--*************************************************************************************
--****						Backup location	validation							   ****
--*************************************************************************************
--Get a list of the folders in the directory
INSERT INTO @SubDirectory (SubDirectory)
EXEC @ReturnError = [master].[sys].[xp_subdirs] @BackupDirectory

	--Check the error codes
	IF(@ReturnError <> 0) 
		BEGIN 
		PRINT 'Error, While attempting to insert the xp_subdirs command results into the table variable'  
		END

--Validate that the directory structure exists, if not create it
IF NOT EXISTS(SELECT 1 FROM @SubDirectory WHERE SubDirectory = @DatabaseName)
	BEGIN
	EXEC @ReturnError = [master].[dbo].[xp_create_subdir] @BackupDirectoryFull

		--Check the error codes
		IF(@ReturnError <> 0) 
			BEGIN 
			PRINT 'Error, While attempting to create the folder in the directory' 
			END 
	END

--*************************************************************************************
--****						     Backup the database							   ****
--*************************************************************************************
--Backup the database
IF (@Debug = 0)
	BEGIN
	BACKUP LOG @DatabaseName
			TO DISK = @BackupFileNameFull
			WITH NOFORMAT, 
			INIT,
			NAME = @BackupName,
			DESCRIPTION = @BackupDescription,
			COMPRESSION,
			NOREWIND, 
			NOUNLOAD,
			SKIP,
			STATS = 10;
	END

--Print the command to the stack
PRINT ''
PRINT ''
PRINT @SQL


