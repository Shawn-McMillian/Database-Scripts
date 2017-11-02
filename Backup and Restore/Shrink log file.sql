/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Shrink log file
**
** Created By:  Shawn McMillian
**
** Description: Shrink the log file for a database
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
--Use this to find the log file we want to shrink
SELECT	D.[name] AS DatabaseName,
		MF.[name] AS LogicalfileName,
		MF.physical_name AS Physicalname
FROM sys.databases AS D
	JOIN sys.master_files AS MF ON D.database_id = MF.database_id
WHERE MF.type_desc = 'Log' 
AND D.[name] = [DatabaseNameHere]


USE [DatabaseNameHere]
GO
DBCC SHRINKFILE (N'LogicalfileName' , 100000)
GO