/*
*******************************************************************************
**       Intellectual property of Shawn McMillian, All rights reserved.
**       This computer program is protected by copyright law
**       and international treaties.
*******************************************************************************
**
** Script Name: SQL Sentry Top SQL
**
** Created By:  Shawn McMillian
**
** Description: Replicate the TOP SQL call in SQl Sentry
**
** Databases:   SQLSentry
**
** Revision History:
** ------------------------------------------------------------------------------------------------------
** Date							Name					Description
** ---------------------------- ----------------------- -------------------------------------------------
** Wed Dec 21 2016  6:55AM		Shawn McMillian			Initial script creation.
*******************************************************************************
** 
*******************************************************************************
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;

--Set the loacal variables for the script
DECLARE @EventSourceConnectionID int, 
		@start datetime, 
		@end datetime;
 
--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
SELECT	@EventSourceConnectionID = ID, 
		@start = DATEADD(minute,-10,GETDATE()),  --NOT UTC unless you change the predicate below.
		@end = GETDATE()
FROM [dbo].[EventSourceConnection]
WHERE ObjectName LIKE N'CHNA2DB1A%';


 --*************************************************************************************
--****								Return the results  							****
--**************************************************************************************
SELECT	ESC.ObjectName, 
		PAD.TextData AS [QueryText],
		PAD.ApplicationName,
		PAD.DatabaseName,
		PAD.HostName,
		PAD.LoginName,
		PAD.Duration,
		PAD.CPU,
		PAD.Reads,
		PAD.Writes,
		PAD.StartTime,
		PAD.EndTime,
		PAD.SPID,
		PAD.IntegerData,
		PAD.FileName,
		PAD.ParentID,
		PAD.NestLevel,
		PAD.IntegerData2,
		PAD.LineNumber,
		PAD.TransactionID,
		PAD.Offset,
		PAD.ObjectID,
		PAD.ObjectName,
		PAD.HasPlan,
		PAD.HasStatements,
		PAD.Error,
		PAD.HostProcessID,
		PAD.SessionMemoryKB,
		PAD.TempdbUserKB,
		PAD.TempdbUserKBDealloc,
		PAD.TempdbInternalKB,
		PAD.TempdbInternalKBDealloc,
		PAD.GrantedQueryMemoryKB,
		PAD.DegreeOfParallelism,
		PAD.GrantTime,
		PAD.RequestedMemoryKB,
		PAD.GrantedMemoryKB,
		PAD.RequiredMemoryKB,
		PAD.GroupID,
		PAD.PoolID,
		PAD.IdealMemoryKB,
		PAD.IsSmallSemaphore
FROM [dbo].[PerformanceAnalysisTraceData] AS PAD
	JOIN [dbo].[EventSourceConnection] AS ESC ON PAD.EventSourceConnectionID = ESC.ID
WHERE Duration > 1000
AND EventSourceConnectionID = @EventSourceConnectionID 
AND StartTime >= @start AND StartTime <= @end
AND EndTime >= @start AND EndTime <= @end
ORDER BY Duration DESC
--ORDER BY CPU DESC
--ORDER BY Reads DESC
--ORDER BY Writes DESC


