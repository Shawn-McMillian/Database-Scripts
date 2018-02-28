/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: Drop Snapshot
**
** Created By:  Shawn McMillian
**
** Description: Drop a snapshot by name
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

DECLARE @SnapshotName sysname,
		@Debug bit,
		@SQL nvarchar(max)


--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
SET @SnapshotName = 'DBAdmin_snapshot' --What to call the snapshot
SET @Debug = 1--set to 1 to output the command, 0 to run the command.

--***********************************************************************************
--****						     Input Validation   							 ****
--***********************************************************************************
--Check to see if the snapshot exists and to make sure it's a snapshot.
IF NOT EXISTS(SELECT 1 FROM [sys].[databases] WHERE [name] = @SnapshotName AND Source_database_id IS NOT NULL)
	BEGIN
	RAISERROR('Error, The snapshot name you provided does not exist on the server/instance or the snapshot name is a real database.',11,1) WITH NOWAIT;
	RETURN   
	END


--***********************************************************************************
--****				     Build the command and execute							 ****
--***********************************************************************************
BEGIN TRY
	--Build the drop command
	SET @SQL = 'DROP DATABASE ' + @SnapshotName + ';' 

	--Look at the Debug flag and go down the correct path
	IF @Debug = 1
		BEGIN
		PRINT @SQL
		END
	ELSE	
		BEGIN
		--Drop the snaphot
		EXEC [master].[dbo].[sp_executeSQL] @stmt = @SQL;

		--Verify the snapshot was dropped
		IF (SELECT COUNT(*) FROM [master].[sys].[databases] WHERE [name] = @SnapshotName AND Source_database_id IS NOT NULL) > 0
			BEGIN
			THROW 51000, 'The snapshot was not dropped. This action can take some time, check again in a few minutes', 1;
			END
		ELSE
			BEGIN
			PRINT 'Snapshot ' + @SnapshotName + ' Dropped successfully'
			END
		END
END TRY

BEGIN CATCH
	SELECT	ERROR_NUMBER() AS [ErrorNumber],
			ERROR_SEVERITY() AS [ErrorSeverity],
			ERROR_STATE() AS [ErrorState],
			ERROR_PROCEDURE() AS [ErrorProcedure],
			ERROR_LINE() AS [ErrorLine],
			ERROR_MESSAGE() AS [ErrorMessage];

	THROW;
END CATCH;