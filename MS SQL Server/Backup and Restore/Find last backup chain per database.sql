/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Find last backup chain per database
**
** Created By:  Shawn McMillian
**
** Description: Find the last log backup for each database on the server
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


--*************************************************************************************
--****					      Find the last full backups.  						   ****
--*************************************************************************************
;WITH CTE_LastFullBackup ([DatabaseName], [BackupType], [BackupFinishDate], [BackupFileName], [Sequence])
AS
	(
	SELECT	D.[name] AS [DatabaseName],
			'FULL' AS [BackupType],
			BS.backup_finish_date AS [BackupFinishDate],
			BMF.physical_device_name AS [BackupFileName],
			BMF.family_sequence_number AS [Sequence]
	FROM [master].[sys].[databases] AS D 
		JOIN [msdb].[dbo].[backupset] AS BS ON (D.name = BS.database_name)
		JOIN [msdb].[dbo].[backupmediaset] AS BMS ON (BS.media_set_id = BMS.media_set_id)
		JOIN [msdb].[dbo].[backupmediafamily] AS BMF ON (BMS.media_set_id = BMF.media_set_id)
		JOIN (	SELECT	D.[name] AS [DatabaseName],
						MAX(BS.backup_set_id) AS [backup_set_id]
				FROM [master].[sys].[databases] AS D 
					JOIN [msdb].[dbo].[backupset] AS BS ON (D.name = BS.database_name)
					JOIN [msdb].[dbo].[backupmediaset] AS BMS ON (BS.media_set_id = BMS.media_set_id)
					JOIN [msdb].[dbo].[backupmediafamily] AS BMF ON (BMS.media_set_id = BMF.media_set_id)
				WHERE BS.[Type] = 'D'
				GROUP BY D.[name]) AS T ON D.[name] = T.DatabaseName AND BS.backup_set_id = T.backup_set_id
	WHERE BS.[Type] = 'D'
	),
CTE_LastDiffBackup ([DatabaseName], [BackupType], [BackupFinishDate], [BackupFileName], [Sequence])
AS
	(
	SELECT	D.[name] AS [DatabaseName],
			'DIFF' AS [BackupType],
			BS.backup_finish_date AS [BackupFinishDate],
			BMF.physical_device_name AS [BackupFileName],
			BMF.family_sequence_number AS [Sequence]
	FROM [master].[sys].[databases] AS D 
		JOIN [msdb].[dbo].[backupset] AS BS ON (D.name = BS.database_name)
		JOIN [msdb].[dbo].[backupmediaset] AS BMS ON (BS.media_set_id = BMS.media_set_id)
		JOIN [msdb].[dbo].[backupmediafamily] AS BMF ON (BMS.media_set_id = BMF.media_set_id)
		JOIN (	SELECT	D.[name] AS [DatabaseName],
						MAX(BS.backup_set_id) AS [backup_set_id]
				FROM [master].[sys].[databases] AS D 
					JOIN [msdb].[dbo].[backupset] AS BS ON (D.name = BS.database_name)
					JOIN [msdb].[dbo].[backupmediaset] AS BMS ON (BS.media_set_id = BMS.media_set_id)
					JOIN [msdb].[dbo].[backupmediafamily] AS BMF ON (BMS.media_set_id = BMF.media_set_id)
				WHERE BS.[Type] = 'I'
				GROUP BY D.[name]) AS T ON D.[name] = T.DatabaseName AND BS.backup_set_id = T.backup_set_id
	WHERE BS.[Type] = 'I'
	)

SELECT * FROM CTE_LastFullBackup
UNION 
SELECT * FROM CTE_LastDiffBackup
