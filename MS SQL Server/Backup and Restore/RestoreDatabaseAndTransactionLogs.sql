/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: RestoreDatabaseAndTransactionLogs
**
** Created By:  Shawn McMillian
**
** Description: Use MSDB to find all of the transaction log backups and retore them
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
DECLARE @DatabaseName sysname,
		@BackupStartDate datetime ,
		@Backup_set_id_start int,
		@Backup_set_id_end int,
		@SQL nvarchar(max),
		@DiskSQL nvarchar(max),
		@Loopid int = 1,
		@LoopMax int = 0,
		@SaAccount varchar(128)

IF(OBJECT_ID('tempdb.dbo.#FullBackupFiles') IS NOT NULL)
	BEGIN
	DROP TABLE #FullBackupFiles;
	END

IF(OBJECT_ID('tempdb.dbo.#DiffBackupFiles') IS NOT NULL)
	BEGIN
	DROP TABLE #DiffBackupFiles;
	END

--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
SET @DatabaseName = 'Docusign' --change me to the database you want to restore
SET @SaAccount = (SELECT [name] FROM sys.server_principals WHERE principal_id = 1) --Assume this is SA

--*************************************************************************************
--****								Last backup details							   ****
--*************************************************************************************
--Get the last full backup setID
SELECT @backup_set_id_start = MAX(backup_set_id) 
FROM msdb.dbo.backupset 
WHERE database_name = @DatabaseName AND type = 'D' 

SELECT @backup_set_id_end = MIN(backup_set_id) 
FROM msdb.dbo.backupset 
WHERE database_name = @DatabaseName AND type = 'D' 
AND backup_set_id > @backup_set_id_start 

IF @backup_set_id_end IS NULL SET @backup_set_id_end = 999999999 

--Get a list of the files in the full backup 
SELECT MF.family_sequence_number AS [Sequence], B.backup_set_id, MF.physical_device_name
INTO #FullBackupFiles 
FROM [msdb].[dbo].[backupset] AS B
	JOIN [msdb].[dbo].[backupmediafamily] AS MF ON  B.media_set_id = MF.media_set_id
WHERE B.database_name = @DatabaseName 
AND B.backup_set_id = @backup_set_id_start 

SET @LoopMax = @@ROWCOUNT

--*************************************************************************************
--****						Generate the database restore						   ****
--*************************************************************************************
--Create the retore statement
SET @SQL = 'USE [master];
GO
EXECUTE AS LOGIN = ''' + @SaAccount + '''
GO
RESTORE DATABASE [' + @DatabaseName + ']
FROM	@Disk@
WITH  FILE = 1,
NORECOVERY,
NOUNLOAD,
MAXTRANSFERSIZE = 4194304,
STATS = 5'

--Loop through the list of files and update the SQL with the file names
WHILE @Loopid <= @LoopMax
	BEGIN
	IF @Loopid < @LoopMax
		BEGIN
		SET @DiskSQL = (SELECT 'DISK = N''' + physical_device_name  + ''',' + CHAR(10) + CHAR(9) + CHAR(9) + '@Disk@'  FROM #FullBackupFiles WHERE [Sequence] = @Loopid)
		END
	ELSE
		BEGIN
		SET @DiskSQL = (SELECT 'DISK = N''' + physical_device_name  + '''' FROM #FullBackupFiles WHERE [Sequence] = @Loopid)
		END
	SET @SQL = REPLACE(@SQL,'@Disk@',@DiskSQL)
	SET @Loopid = @Loopid + 1
	END

SELECT @SQL

--*************************************************************************************
--****						Last differential details							   ****
--*************************************************************************************
--Get the last full backup setID
SELECT @backup_set_id_start = MAX(backup_set_id) 
FROM msdb.dbo.backupset 
WHERE database_name = @DatabaseName AND type = 'I' 

SELECT @backup_set_id_end = MIN(backup_set_id) 
FROM msdb.dbo.backupset 
WHERE database_name = @DatabaseName AND type = 'I' 
AND backup_set_id > @backup_set_id_start 

IF @backup_set_id_end IS NULL SET @backup_set_id_end = 999999999 

--Get a list of the files in the full backup 
SELECT MF.family_sequence_number AS [Sequence], B.backup_set_id, MF.physical_device_name
INTO #DiffBackupFiles 
FROM [msdb].[dbo].[backupset] AS B
	JOIN [msdb].[dbo].[backupmediafamily] AS MF ON  B.media_set_id = MF.media_set_id
WHERE B.database_name = @DatabaseName 
AND B.backup_set_id = @backup_set_id_start 

SET @LoopMax = @@ROWCOUNT
SET @Loopid = 1

--*************************************************************************************
--****					  Generate the differential restore						   ****
--*************************************************************************************
--Create the retore statement
SET @SQL = 'USE [master];
GO
EXECUTE AS LOGIN = ''' + @SaAccount + '''
GO
RESTORE DATABASE [' + @DatabaseName + ']
FROM	@Disk@
WITH  FILE = 1,
NORECOVERY,
NOUNLOAD,
MAXTRANSFERSIZE = 4194304,
STATS = 5'

--Loop through the list of files and update the SQL with the file names
WHILE @Loopid <= @LoopMax
	BEGIN
	IF @Loopid < @LoopMax
		BEGIN
		SET @DiskSQL = (SELECT 'DISK = N''' + physical_device_name  + ''',' + CHAR(10) + CHAR(9) + CHAR(9) + '@Disk@'  FROM #DiffBackupFiles WHERE [Sequence] = @Loopid)
		END
	ELSE
		BEGIN
		SET @DiskSQL = (SELECT 'DISK = N''' + physical_device_name  + '''' FROM #DiffBackupFiles WHERE [Sequence] = @Loopid)
		END
	SET @SQL = REPLACE(@SQL,'@Disk@',@DiskSQL)
	SET @Loopid = @Loopid + 1
	END

SELECT @SQL

--*************************************************************************************
--****						Generate the Transaction restore					   ****
--*************************************************************************************
SELECT B.backup_set_id, 'RESTORE LOG ' + @DatabaseName + ' FROM DISK = ''' + MF.physical_device_name + ''' WITH NORECOVERY' 
FROM [msdb].[dbo].[backupset] AS B
	JOIN [msdb].[dbo].[backupmediafamily] AS MF ON  B.media_set_id = MF.media_set_id
WHERE B.database_name = @DatabaseName 
AND B.backup_set_id >= @backup_set_id_start AND B.backup_set_id < @backup_set_id_end 
AND B.type = 'L' 
ORDER BY B.backup_set_id

--*************************************************************************************
--****						Generate the recovery statement					   ****
--*************************************************************************************
SELECT 999999999 AS backup_set_id, 'RESTORE DATABASE ' + @DatabaseName + ' WITH RECOVERY' 
ORDER BY backup_set_id