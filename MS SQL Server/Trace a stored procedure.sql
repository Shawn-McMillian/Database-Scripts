/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: XEvent Procedure Trace
**
** Created By:  Shawn McMillian
**
** Description: Trace a procedure in a system using XEvents
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
		@SchemaName sysname,
		@ProcedureName sysname,
		@DatabaseID int, 
		@ProcedureID int;
 
--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
SET @DatabaseName = 'docusign';
SET @SchemaName = 'dbo';
SET @ProcedureName = 'SelectDashboardsText';

--*************************************************************************************
--****						    Format all parameters  							   ****
--*************************************************************************************
SET @DatabaseID = (SELECT database_id FROM master.sys.databases WHERE [name] = @DatabaseName)
SET @ProcedureID = (SELECT object_id(@DatabaseName + '.' + @SchemaName + '.' + @ProcedureName,'P'))

--PRINT @DatabaseID
--PRINT @ProcedureID
/*******************************************************************************
**				  Drop any extended events of the same name					  **
*******************************************************************************/
IF EXISTS ( SELECT 1 FROM sys.server_event_sessions WHERE  name = 'XE_Procedure_Trace' )
	BEGIN
    DROP EVENT SESSION [XE_Procedure_Trace] ON SERVER;
	END

/*******************************************************************************
**				              Create the event					              **
*******************************************************************************/
CREATE EVENT SESSION [XE_Procedure_Trace] ON SERVER 

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
			AND (([sqlserver].[database_name]=N'Docusign')))
		),

ADD EVENT sqlserver.sql_batch_completed
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
			AND (([sqlserver].[database_name]=N'Docusign')))
		)


/*
		(([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) 
			AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) 
			AND (([sqlserver].[database_name]=N'Docusign') 
			AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'SelectDashboardsText'))))
*/

--ADD EVENT sqlserver.sql_statement_completed
--	(ACTION
--		( 
--		  sqlserver.database_name,
--		  sqlserver.nt_username,
--		  sqlserver.client_pid,
--		  sqlserver.client_app_name,
--		  sqlserver.server_principal_name,
--		  sqlserver.session_id
--		)
--	WHERE ([sqlserver].[database_id]=(7))
--	)

ADD TARGET package0.event_file
	(
		SET filename=N'C:\Temp\XE_Procedure_Trace.xel',metadatafile=N'C:\Temp\XE_Procedure_Trace.xem'
	)

WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)


/*******************************************************************************
**				              Start the event					              **
*******************************************************************************/
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE [name] = 'XE_Procedure_Trace')
	BEGIN
	ALTER EVENT SESSION [XE_Procedure_Trace] ON SERVER
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
IF EXISTS(SELECT 1 FROM sys.dm_xe_sessions WHERE [name] = 'XE_Procedure_Trace')
	BEGIN
	ALTER EVENT SESSION [XE_Procedure_Trace] ON SERVER
		STATE = STOP;
	END
GO

/*******************************************************************************
**				        Return the results of of the Event 					  **
*******************************************************************************/
/*
;WITH CTE_XE_Procedure_Trace_Raw AS
(
	SELECT data = CONVERT(XML, event_data)
    FROM sys.fn_xe_file_target_read_file('C:\Temp\XE_Procedure_Trace*.xel', 'C:\Temp\XE_Procedure_Trace.xem',NULL, NULL)
),

CTE_XE_Procedure_Trace AS 
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
	FROM CTE_XE_Procedure_Trace_Raw
)


SELECT * 
FROM CTE_XE_Procedure_Trace
*/
