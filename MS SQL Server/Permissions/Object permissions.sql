/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Object permissions
**
** Created By:  Shawn McMillian
**
** Description: List our all of the obejcts and who has access to them 
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
--****								Change me!!  								   ****
--************************************************************************************
SELECT	S.name AS [Schema],
		O.name AS [Object],
		DBP.name AS [UserName],
		DP.type AS [permissionsType],
		DP.permission_name AS [PermissionsName],
		DP.state AS [permissionsState],
		DP.state_desc AS [StateDescription],
		DP.state_desc + ' ' + DP.permission_name + ' on ['+ S.name + '].[' + O.name + '] to [' + DBP.name + ']' COLLATE LATIN1_General_CI_AS AS [Statement]
FROM sys.database_permissions AS DP
	JOIN sys.objects AS O ON DP.major_id = O.object_id 
	JOIN sys.schemas AS S ON O.schema_id = S.schema_id 
	JOIN sys.database_principals AS DBP ON DP.grantee_principal_id = DBP.principal_id
--WHERE S.name = 'SomeSchema'
--AND O.name = 'SomeOnject' 
--AND DBP.name = 'SomeUserName'
ORDER BY [Schema], [Object], [UserName], [PermissionsName]