/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Find last diff backup per database
**
** Created By:  Shawn McMillian
**
** Description: Find the last diff backup for each database on the server
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
SELECT	D.[name] AS [DatabaseName],
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
WHERE BS.[Type] = 'I';
