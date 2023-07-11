/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: List Snapshot
**
** Created By:  Shawn McMillian
**
** Description: List all of the snapshots, how old and what size
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
SELECT	D.name AS [SnapShotName],
		DB_NAME(D.source_database_id) AS [SnapShotOf],
		Create_date AS [DateCreated],
		DATEDIFF(MINUTE,Create_date,GETDATE()) AS [MinutesOld],
		MF.[name] AS [LogicalName],
		MF.[physical_name] AS [PhysicalName],
		(MF.Size * 8000)/1024/1024 [FileSizeGB],
		MF.growth,
		MF.max_size
FROM [master].[sys].[databases] AS D
	JOIN [sys].[master_files] AS MF ON D.database_id = MF.database_id
WHERE D.source_database_id IS NOT NULL;