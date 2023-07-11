/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: XEvent Procedure Trace for a database
**
** Created By:  Shawn McMillian
**
** Description: Trace all procedures for a database
**
** Databases:   master
**
** Revision History:
** ------------------------------------------------------------------------------------------------------
** Date							Name					Description
** ---------------------------- ----------------------- -------------------------------------------------
** Wed May 10 2017  7:41AM		Shawn McMillian			Initial script creation.
*******************************************************************************
** 
*******************************************************************************
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON

--Set the loacal variables for the script
DECLARE @DatabaseName sysname,
		@DatabaseID int,
		@DynamicSQL nvarchar(max);
 
--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
SET @DatabaseName = 'master';

--*************************************************************************************
--****						    Format all parameters  							   ****
--*************************************************************************************
SET @DatabaseID = (SELECT database_id FROM master.sys.databases WHERE [name] = @DatabaseName)


/*******************************************************************************
**				  Drop any extended events of the same name					  **
*******************************************************************************/
IF EXISTS ( SELECT 1 FROM sys.server_event_sessions WHERE  name = 'XE_All_Procedure_Trace_For_Database' )
	BEGIN
    DROP EVENT SESSION [XE_All_Procedure_Trace_For_Database] ON SERVER;
	END

/*******************************************************************************
**				              Create the event					              **
*******************************************************************************/
SET @DynamicSQL = '
CREATE EVENT SESSION [XE_All_Procedure_Trace_For_Database] ON SERVER 

ADD EVENT sqlserver.rpc_completed
	(ACTION
		(
			sqlserver.client_app_name,
			sqlserver.client_pid,
			sqlserver.database_id,
			sqlserver.database_name,
			sqlserver.nt_username,
			sqlserver.query_hash,
			sqlserver.server_principal_name,
			sqlserver.session_id,
			sqlserver.sql_text
		)
    WHERE 
		(
			(([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) 
			AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) 
			AND (([sqlserver].[database_name]=N''' + @DatabaseName + ''')))
		),

ADD EVENT sqlserver.sql_statement_completed
	(ACTION
		(
			sqlserver.client_app_name,
			sqlserver.client_pid,
			sqlserver.database_id,
			sqlserver.database_name,
			sqlserver.nt_username,
			sqlserver.query_hash,
			sqlserver.server_principal_name,
			sqlserver.session_id,
			sqlserver.sql_text
		)
    WHERE 
		(
			(([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) 
			AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) 
			AND (([sqlserver].[database_name]=N''' + @DatabaseName + ''')))
		)

ADD TARGET package0.event_file
	(
		SET filename=N''C:\Temp\XE_All_Procedure_Trace_For_Database.xel'',metadatafile=N''C:\Temp\XE_All_Procedure_Trace_For_Database.xem''
	)

WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)'

--Create the event
EXEC [master].[dbo].[sp_executesql] @stmt = @DynamicSQL;

--Verify that the Event was created
IF NOT EXISTS ( SELECT 1 FROM sys.server_event_sessions WHERE  name = 'XE_All_Procedure_Trace_For_Database' )
	BEGIN
    RAISERROR('The X-Event was not created',11,1) WITH NOWAIT;
	END


/*******************************************************************************
**				              Start the event					              **
*******************************************************************************/
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE [name] = 'XE_All_Procedure_Trace_For_Database')
	BEGIN
	ALTER EVENT SESSION [XE_All_Procedure_Trace_For_Database] ON SERVER
		STATE = START;
	END
GO

/*******************************************************************************
**				        Loop while we capture data					          **
*******************************************************************************/
WAITFOR DELAY '00:00:30.000'

/*******************************************************************************
**				              Stop the event					              **
*******************************************************************************/
IF EXISTS(SELECT 1 FROM sys.dm_xe_sessions WHERE [name] = 'XE_All_Procedure_Trace_For_Database')
	BEGIN
	ALTER EVENT SESSION [XE_All_Procedure_Trace_For_Database] ON SERVER
		STATE = STOP;
	END
GO

/*******************************************************************************
**				        Return the results of of the Event 					  **
*******************************************************************************/
/*
;WITH CTE_XE_All_Procedure_Trace_For_Database_Raw AS
(
	SELECT data = CONVERT(XML, event_data)
    FROM sys.fn_xe_file_target_read_file('C:\Temp\XE_All_Procedure_Trace_For_Database*.xel', 'C:\Temp\XE_All_Procedure_Trace_For_Database.xem',NULL, NULL)
),

CTE_XE_All_Procedure_Trace_For_Database AS
(
	SELECT
		data.value('(event/@name)[1]','nvarchar(250)') AS [Event],
		data.value('(event/action[@name="session_id"]/value)[1]','nvarchar(400)') AS [SPID],
		data.value('(event/action[@name="database_name"]/value)[1]','nvarchar(400)') AS [DatabaseName],
		data.value('(event/data[@name="object_name"]/value)[1]','nvarchar(250)') AS [ObjectName],
		data.value('(event/data[@name="statement"]/value)[1]','nvarchar(250)') AS [Statement],
		data.value('(event/data[@name="duration"]/value)[1]','nvarchar(250)') AS [Duration],
		data.value('(event/data[@name="cpu_time"]/value)[1]','nvarchar(250)') AS [CPU],
		data.value('(event/data[@name="physical_reads"]/value)[1]','nvarchar(250)') AS [PhysicalReads],
		data.value('(event/data[@name="logical_reads"]/value)[1]','nvarchar(250)') AS [LogicalReads],
		data.value('(event/data[@name="writes"]/value)[1]','nvarchar(250)') AS [Writes],
		data.value('(event/data[@name="row_count"]/value)[1]','nvarchar(250)') AS [RowCount],
		data.value('(event/action[@name="client_app_name"]/value)[1]','nvarchar(400)') AS [Application],
		data.value('(event/action[@name="server_principal_name"]/value)[1]','nvarchar(400)') AS [LoginName],
		data.value('(event/@timestamp)[1]','datetime2') AS [timestamp]
	FROM CTE_XE_All_Procedure_Trace_For_Database_Raw
)

SELECT * 
FROM CTE_XE_All_Procedure_Trace_For_Database
--WHERE ObjectName <> 'sp_reset_connection'
*/

