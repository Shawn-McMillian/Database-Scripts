/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: Table statistics
**
** Created By:  Shawn McMillian
**
** Description: Get all of the statistics for the tables in the database. 
**
** Databases:   Common
**
** Revision History:
** ------------------------------------------------------------------------------------------------------
** Date							Name					Description
** ---------------------------- ----------------------- -------------------------------------------------
** July 11 2023					Shawn McMillian			Initial script creation.
*******************************************************************************
** 
*******************************************************************************
*/
SELECT *
FROM pg_stats
--WHERE tablename = 'TableName'
--AND schemaname = 'SchemaName'
