/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Executing Backup Statistics
**
** Created By:  Shawn McMillian
**
** Description: Show any backups running and the elapsed and remaining times.
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
SELECT	DB_NAME(database_id) AS [DatabaseName],
		command, 
		percent_complete,
		total_elapsed_time / 60000.0 AS [Elapsed],
		estimated_completion_time / 60000.0 AS [remaining]
FROM sys.dm_exec_requests
WHERE command LIKE 'BACKUP%';