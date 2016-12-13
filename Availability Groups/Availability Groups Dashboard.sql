/*
*******************************************************************************
**         Intellectual property of Shawn McMillian, All rights reserved.
**         This computer program is protected by copyright law
**         and international treaties.
*******************************************************************************
**
** Script Name: Availability Groups Dashboard
**
** Created By:  Shawn McMillian
**
** Description: Get all of the relevant Availability Group data that a DBA will need to watch, 
** troublshoot and fix AG problems.
**
** Databases:   Common
**
** Revision History:
** ------------------------------------------------------------------------------------------------------
** Date							Name					Description
** ---------------------------- ----------------------- -------------------------------------------------
** Mar 09 2015					Shawn McMillian			Initial script creation.
*******************************************************************************
** 
*******************************************************************************
*/

/*******************************************************************************
***							Determine Primary Server					     ***
*******************************************************************************/
--Determine the Primary server
SELECT  a.name AS [AGName],
        primary_replica AS [PrimaryServer]
FROM MASTER.sys.dm_hadr_availability_group_states AS AGS
    JOIN sys.availability_groups AS A ON AGS.group_id = A.group_id

/*******************************************************************************
***							High Level AG Status						     ***
*******************************************************************************/
SELECT  AG.name AS [AGName],
        AR.replica_server_name AS [ServerName],
        CASE
            WHEN ARS.role_desc IS NULL THEN N'DISCONNECTED'
            ELSE ARS.role_desc
        END AS [ServerRole],
        AR.availability_mode_desc AS [CommitType],
        AR.failover_mode_desc [FailoverMode],
        ARS.synchronization_health_desc AS [Health],
		'ALTER AVAILABILITY GROUP ' + AG.name + ' FAILOVER;' AS [Failover]
FROM sys.availability_groups AS AG
    JOIN sys.availability_replicas AS AR ON AG.group_id = AR.group_id
    JOIN sys.dm_hadr_availability_replica_states AS ARS  ON AR.replica_id = ARS.replica_id
ORDER BY ServerRole, ServerName

/*******************************************************************************
***							      AG Status									 ***
*******************************************************************************/
SELECT  AR.replica_server_name AS [ServerName],
        AG.name AS [AGName],
        DB_NAME(DRS.database_id) AS [DatabaseName],
        CASE
            WHEN ARS.is_local = 1 THEN N'LOCAL'
            ELSE 'REMOTE'
        END AS [AGLocation],
        CASE
            WHEN ARS.role_desc IS NULL THEN N'DISCONNECTED'
            ELSE ARS.role_desc 
        END AS [AgState],
        DRS.last_commit_time AS [LastCommit],
		DATEDIFF(second,DRS.last_commit_time,GETDATE()) [CommitLatencyseconds],
        DRS.log_send_queue_size AS [SendQueueSize],
        DRS.redo_queue_size AS [RedoQueueSize],
        DRS.redo_rate AS [RedoRate],
        ISNULL( CASE DRS.redo_rate
                    WHEN 0 THEN -1
                    ELSE CAST(DRS.redo_queue_size AS float) / DRS.redo_rate
                END, -1) AS [EstimatedRecoveryTime],
		'ALTER DATABASE ' + DB_NAME(DRS.database_id) + ' SET HADR SUSPEND' AS [SuspendDB],
		'ALTER DATABASE ' + DB_NAME(DRS.database_id) + ' SET HADR RESUME' AS [ResumeDB]
FROM sys.availability_groups AS AG
    JOIN sys.availability_replicas AS AR ON AG.group_id = AR.group_id
    JOIN sys.dm_hadr_availability_replica_states AS ARS  ON AR.replica_id = ARS.replica_id
    JOIN sys.dm_hadr_database_replica_states AS DRS ON AG.group_id = DRS.group_id
        AND ARS.replica_id = DRS.replica_id
ORDER BY [AgState],[ServerName],[DatabaseName]

--

/*******************************************************************************
***							      Set to Sync							 ***
*******************************************************************************/
SELECT AG.name AS [AGName],
        AR.replica_server_name AS [ServerName],
        CASE
            WHEN ARS.role_desc IS NULL THEN N'DISCONNECTED'
            ELSE ARS.role_desc
        END AS [ServerRole],
        AR.availability_mode_desc AS [CommitType],
        AR.failover_mode_desc [FailoverMode],
        ARS.synchronization_health_desc AS [Health],
		'USE master;
GO

--Set the node to SYNCHRONOUS_COMMIT
ALTER AVAILABILITY GROUP [' + AG.NAME + ']
MODIFY REPLICA ON N''' + AR.replica_server_name + ''' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT)
--If there are no other Servers with their roles set to Automatic then add this one.
IF ((   SELECT  COUNT(*)
        FROM sys.availability_groups AS AG
            JOIN sys.availability_replicas AS AR ON AG.group_id = AR.group_id
            JOIN sys.dm_hadr_availability_replica_states AS ARS  ON AR.replica_id = ARS.replica_id
        WHERE AG.name = ''' + AG.NAME + '''
        AND AR.replica_server_name <> N''' + AR.replica_server_name + '''
        AND AR.failover_mode_desc = ''AUTOMATIC''
        --AND Check to make sure this server is local? How??
        AND CASE
                WHEN ARS.role_desc IS NULL THEN N''DISCONNECTED''
                ELSE ARS.role_desc
            END <> ''PRIMARY'') = 0)
    BEGIN

    --We need to set this node to manual failover
    ALTER AVAILABILITY GROUP [' + AG.NAME + ']
    MODIFY REPLICA ON N''' + AR.replica_server_name + ''' WITH (FAILOVER_MODE = AUTOMATIC);
    END
GO' AS [SetToSync]
FROM sys.availability_groups AS AG
    JOIN sys.availability_replicas AS AR ON AG.group_id = AR.group_id
    JOIN sys.dm_hadr_availability_replica_states AS ARS  ON AR.replica_id = ARS.replica_id
WHERE	CASE
            WHEN ARS.role_desc IS NULL THEN N'DISCONNECTED'
            ELSE ARS.role_desc
        END = 'SECONDARY'
AND AR.availability_mode_desc = 'ASYNCHRONOUS_COMMIT'



/*******************************************************************************
***							      Set to Sync								 ***
*******************************************************************************/
SELECT	AG.name AS [AGName],
        AR.replica_server_name AS [ServerName],
        CASE
            WHEN ARS.role_desc IS NULL THEN N'DISCONNECTED'
            ELSE ARS.role_desc
        END AS [ServerRole],
        AR.availability_mode_desc AS [CommitType],
        AR.failover_mode_desc [FailoverMode],
        ARS.synchronization_health_desc AS [Health],
		'USE master;
GO

--If the server is in the correct mode, then place it in Async
IF ((   SELECT  AR.failover_mode_desc
        FROM sys.availability_groups AS AG
            JOIN sys.availability_replicas AS AR ON AG.group_id = AR.group_id
            JOIN sys.dm_hadr_availability_replica_states AS ARS  ON AR.replica_id = ARS.replica_id
        WHERE AG.name = ''' + AG.name + '''
        AND AR.replica_server_name = N''' + AR.replica_server_name + ''') = ''MANUAL'')
    BEGIN
    ALTER AVAILABILITY GROUP [' + AG.name + ']
    MODIFY REPLICA ON N''' + AR.replica_server_name + ''' WITH (AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT);
    END
ELSE
    BEGIN
    --Warn if this is the last AUTOMATIC node.
    IF (SELECT  COUNT(*)
        FROM sys.availability_groups AS AG
            JOIN sys.availability_replicas AS AR ON AG.group_id = AR.group_id
            JOIN sys.dm_hadr_availability_replica_states AS ARS  ON AR.replica_id = ARS.replica_id
        WHERE AG.name = ''' + AG.name + '''
        AND AR.replica_server_name <> N'''' + AR.replica_server_name + ''''
        AND AR.failover_mode_desc = ''AUTOMATIC''
        AND CASE
                WHEN ARS.role_desc IS NULL THEN N''DISCONNECTED''
                ELSE ARS.role_desc
            END <> ''PRIMARY'') = 0
        BEGIN
        PRINT ''There are no longer any AUTOMATIC failover nodes in the AG'';
        END
    --We need to set this node to manual failover
    ALTER AVAILABILITY GROUP [' + AG.name + ']
    MODIFY REPLICA ON N''' + AR.replica_server_name + ''' WITH (FAILOVER_MODE = MANUAL);
    --Set the node to Asyncronous
    ALTER AVAILABILITY GROUP [' + AG.name + ']
    MODIFY REPLICA ON N''' + AR.replica_server_name + ''' WITH (AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT);
    END
GO' AS [SetToAsync]
FROM sys.availability_groups AS AG
    JOIN sys.availability_replicas AS AR ON AG.group_id = AR.group_id
    JOIN sys.dm_hadr_availability_replica_states AS ARS  ON AR.replica_id = ARS.replica_id
WHERE	CASE
            WHEN ARS.role_desc IS NULL THEN N'DISCONNECTED'
            ELSE ARS.role_desc
        END = 'SECONDARY'
AND AR.availability_mode_desc = 'SYNCHRONOUS_COMMIT'


/*******************************************************************************
***							   Read only routing							 ***
*******************************************************************************/
DECLARE @RoutingOrder TABLE (
       Replica_ID UNIQUEIDENTIFIER
       , routing_priority INT
       , read_only_replica_id UNIQUEIDENTIFIER
       , PrimaryServer nvarchar(512)
       , ReadReplica NVARCHAR(512)
       )

DECLARE @ReadRoutingFinal TABLE (
       name SYSNAME
       , availability_mode TINYINT
       , failover_mode TINYINT
       , ReadRoutingOrder NVARCHAR(1000)
       )

DECLARE @AvailabilityGroups TABLE ( 
       Name SYSNAME
       , group_id UNIQUEIDENTIFIER
       )

DECLARE @AvailabilityReplicas TABLE ( 
       group_id UNIQUEIDENTIFIER
       , replica_id UNIQUEIDENTIFIER
       , replica_server_name NVARCHAR(256)
       , availability_mode TINYINT
       , failover_mode TINYINT
       )

DECLARE @AvailabilityReplicaStates TABLE ( 
       group_id UNIQUEIDENTIFIER
       , replica_id UNIQUEIDENTIFIER
       , role_desc NVARCHAR(60)
       , role TINYINT
       )

DECLARE @AvailabilityDatabases TABLE (
       name SYSNAME
       , database_name NVARCHAR(256)
       )

DECLARE @AGDatabasesFinal TABLE (
       name SYSNAME
       , DatabaseList NVARCHAR(1000)
       )

/* Load up the table vars with the relevant data from each DMV */
INSERT INTO @AvailabilityReplicaStates
       SELECT group_id
                     , replica_id
                     , role_desc
                     , role
       FROM sys.dm_hadr_availability_replica_states


INSERT INTO @AvailabilityReplicas
       SELECT group_id      
                     , replica_id
                     , replica_server_name
                     , availability_mode
                     , failover_mode
       FROM sys.availability_replicas


INSERT INTO @AvailabilityGroups
       SELECT name
                     , group_id
       FROM sys.availability_groups


INSERT INTO @RoutingOrder
       SELECT l.replica_id
                     , l.routing_priority
                     , l.read_only_replica_id
                     , r.replica_server_name as PrimaryServer
                     , r2.replica_server_name as ReadReplica
       FROM sys.availability_read_only_routing_lists l
                     join @AvailabilityReplicas r on l.replica_id = r.replica_id
                     join @AvailabilityReplicas r2 on l.read_only_replica_id = r2.replica_id

--Aggregate Read Routing for report
;with cteReadReplicas AS (
              select replica_id
              ,PrimaryServer
              ,  '(' + STUFF((SELECT N', ' + ReadReplica FROM @RoutingOrder cr2 WHERE cr2.PrimaryServer = cr.PrimaryServer and cr2.Replica_ID = cr.Replica_ID 
                     AND cr2.routing_priority = 1
                                  order by cr2.routing_priority, cr2.ReadReplica
                           for xml path(N''), type).value(N'.[1]', N'nvarchar(1000)'),1,2,N'')
                           + ')'
                           + COALESCE (', ' + STUFF((SELECT N', ' + ReadReplica FROM @RoutingOrder cr2 WHERE cr2.PrimaryServer = cr.PrimaryServer and cr2.Replica_ID = cr.Replica_ID 
                     AND cr2.routing_priority = 2
                                  order by cr2.routing_priority, cr2.ReadReplica
                           for xml path(N''), type).value(N'.[1]', N'nvarchar(1000)'),1,2,N''), '')
                           + COALESCE (', ' + STUFF((SELECT N', ' + ReadReplica FROM @RoutingOrder cr2 WHERE cr2.PrimaryServer = cr.PrimaryServer and cr2.Replica_ID = cr.Replica_ID 
                     AND cr2.routing_priority > 2
                                  order by cr2.routing_priority, cr2.ReadReplica
                           for xml path(N''), type).value(N'.[1]', N'nvarchar(1000)'),1,2,N''), '')
                           as ReadRoutingOrder

              from @RoutingOrder cr             
              group by PrimaryServer, replica_id
              )

SELECT	AG.[Name] AS [AGName],
		PrimaryServer,
		ReadRoutingOrder,
		'ALTER AVAILABILITY GROUP ' + AG.[Name] + ' MODIFY REPLICA ON ''' + [PrimaryServer] + ''' with (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST = (' + REPLACE(REPLACE(REPLACE(ReadRoutingOrder + '''','(','('''),', ',''', '''),')'',','''),') + ')));' AS [ModifyReadOnly],
		'ALTER AVAILABILITY GROUP ' + AG.[Name] + ' MODIFY REPLICA ON ''' + [PrimaryServer] + ''' with (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N''TCP://' + [PrimaryServer] + '.corp.docusign.net:1433''));' AS [SecondaryRole]
FROM cteReadReplicas AS RR
	JOIN sys.availability_replicas AS AR ON RR.Replica_ID = AR.replica_id
	JOIN sys.availability_groups AS AG ON AR.group_id = AG.group_id

