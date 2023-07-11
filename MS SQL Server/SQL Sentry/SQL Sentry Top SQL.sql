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
DECLARE @start datetime, 
		@end datetime;
 
IF(OBJECT_ID('tempdb.dbo.#EventSourceConnection') IS NULL)
	BEGIN
	CREATE TABLE #EventSourceConnection (EventSourceConnectionID smallint NOT NULL, ObjectName nvarchar(256))
	END
ELSE
	BEGIN
	TRUNCATE TABLE #EventSourceConnection
	END
	
--*************************************************************************************
--****								Change me!!  								   ****
--*************************************************************************************
INSERT INTO #EventSourceConnection( EventSourceConnectionID, ObjectName)
SELECT	DISTINCT
		ID AS [EventSourceConnectionID], 
		ObjectName
FROM [dbo].[EventSourceConnection]
WHERE ObjectName LIKE N'%SEN0%'
AND IsWatched = 1;

SELECT	@start = DATEADD(hour,-2,GETDATE()),  --NOT UTC unless you change the predicate below.
		@end = GETDATE()
		--@start = '2019-07-23 13:00:00.000' 
		--@end = '2019-07-23 14:00:00.000'
		
 --*************************************************************************************
--****								Return the results  							****
--**************************************************************************************
SELECT	ESC.ObjectName, 
		PAD.TextData AS [QueryText],
		--REPLACE(REPLACE(REPLACE(PAD.TextData,CHAR(10),''),CHAR(13),''),CHAR(9),'') AS [QueryTextNoCRLF],
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
AND EventSourceConnectionID IN (SELECT EventSourceConnectionID FROM #EventSourceConnection)
AND StartTime >= @start AND StartTime <= @end
AND EndTime >= @start AND EndTime <= @end
--AND PAD.ObjectName <> ''
--AND PAD.ObjectName LIKE '%ExportRecipientEvent%' ESCAPE '|'
--AND PAD.ObjectName LIKE '%TemplateSelectByAccountIdIncludeFolderTypeForAutoMatch%' ESCAPE '|'
--AND PAD.TextData LIKE '%exec sp_executesql%'
--AND PAD.TextData LIKE '%@counterId=4156888844864549337%'
--AND PAD.GrantedQueryMemoryKB > 100
--AND PAD.TextData LIKE '%@SendingUserId=NULL%'
--AND PAD.TextData LIKE '%@RecipientUserId=NULL%'
--AND PAD.TextData LIKE '%@EnvelopeStatusLookupId=default%'
--AND PAD.TextData LIKE '%@CustomFields=1%'
ORDER BY Duration DESC
--ORDER BY CPU DESC
--ORDER BY Reads DESC
--ORDER BY Writes DESC
--ORDER BY PAD.EndTime
--ORDER BY GrantedMemoryKB DESC
--ORDER BY StartTime DESC
--ORDER BY [GrantedQueryMemoryMB] DESC
