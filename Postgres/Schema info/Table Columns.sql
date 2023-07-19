/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: Table columns
**
** Created By:  Shawn McMillian
**
** Description: Quickly find all of the columns in a table 
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
SELECT 	table_catalog,
		table_schema,
		table_name,
		ordinal_position,
		column_name,
		udt_name,
		character_maximum_length,
		is_nullable,
		is_identity
FROM information_schema.columns
WHERE table_name = 'TableName'
--AND table_schema = 'your_schema'
ORDER BY ordinal_position
