/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Database backup Waits and Recovery
**
** Created By:  Shawn McMillian
**
** Description: When you can't get a backup or T-log done. These stats will tell you why. 
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
SELECT	[name],
		log_reuse_wait_desc,
		recovery_model_desc
FROM [master].[sys].[databases];