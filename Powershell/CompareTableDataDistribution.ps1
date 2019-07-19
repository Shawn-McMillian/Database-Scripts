<#******************************************************************************
**	       Intellectual property of DocuSign, All rights reserved.			  ** 
**  		This computer program is protected by copyright law				  **
**  					and international treaties.							  **
********************************************************************************
**                                                                            **
** Script Name: 	Compare Table Data Distribution					          **
** Version:			1.00.00													  **
** Created By:		Shawn McMillian											  **
** Description:		Use RowModVersion to compare data distribution Histogram  **
********************************************************************************
** Revision History:														  **
** ---------------------------------------------------------------------------**
** Date			Name				Description							      **
** ---------------------------------------------------------------------------**
** 10/17/2018	Shawn McMillian		Created                                   **
#*****************************************************************************#>
# ./'\CompareTableDataDistribution.ps1' -SQLInstance "SomeServer" -DatabaseName "master" -UseTrustedSecurity $true -UserName "UserName" -Password "Password" -MultiSubnetFailover $false -ApplicationIntent $false -ResultsDirectory "C:Temp" -ResultsFile "Results.csv" -QueryToExecute "SELECT * FROM sys.dm_exec_sessions WHERE HOST_NAME IS NOT NULL;"
########################## VARS ######################

<#******************************************************************************
**	                             Functions		                        	  ** 
******************************************************************************#>
function Test-SQLConnectionString #Check to see if the SQL Server provided can be connected to.
{    
    [OutputType([bool])]
    Param
    (    
        [Parameter( Mandatory=$true)] 
        [string]$ConnectionString
    )
    try
    {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString;
        $sqlConnection.Open();
        $sqlConnection.Close();

        Write-Host "Passed" -ForegroundColor "Green";
		return $true;
    }
    catch
    {
        Write-Host "Failed" -ForegroundColor "Red";
		return $false
    }
} #End Test-SQLConnection

function Find-TargetDirectory #Checks to see if the $TargetDirectory exists, optionally creates if not
{
	[CmdletBinding()]
	param (	[parameter(Mandatory = $true)]
			[string]$TargetDirectory,
			[parameter(Mandatory = $true)]
			[bool]$CreateIfMissing
	)
	
	if (Test-Path $TargetDirectory)
	{
		Write-Host "Passed" -ForegroundColor "Green"
	}
	else
	{
		if ($CreateIfMissing -eq $true)
		{
			New-Item -Path $TargetDirectory -Type directory -Force -ErrorAction 'Stop' | Out-Null
			Write-Host "Passed" -ForegroundColor "Green"
			return $true;
		}
		else
		{
			Write-Error "Target directory: $TargetDirectory does not exist." -ErrorAction 'Stop'
			Write-Host "Failed" -ForegroundColor "Red"
			return $false;
		}
	}
} #End Check-TargetDirectory

function New-SQLConnectionString #Creates the connection string from the values provided
{
	[CmdletBinding()]
	param (	[parameter(Mandatory = $true)]
			[string]$SqlServerName,
			[parameter(Mandatory = $true)]
			[string]$DatabaseName,
			[parameter(Mandatory = $true)]
			[bool]$TrustedConnection,
			[parameter(Mandatory = $true)]
			[string]$UserName,
			[parameter(Mandatory = $true)]
			[string]$Password,
			[parameter(Mandatory = $true)]
			[bool]$MultiSubnetFailover,
			[parameter(Mandatory = $true)]
			[bool]$ApplicationIntent
	)
	
	#Set the server and database portion of the string
	$connectionString = "Data Source=$SqlServerName; database=$DatabaseName"
	
	#Set the security portion.. User/Password vs trusted security
	if ($TrustedConnection -eq $true)
	{
		$connectionString = $connectionString + "; Integrated Security=SSPI"
	}
	else
	{
		$connectionString = $connectionString + "; User Id=$UserName; Password=$Password"
	}

	#Set the multisubnet settings
	if ($MultiSubnetFailover -eq $true)
	{
		$connectionString = $connectionString + "; multisubnetfailover=True"
	}
	
	#Set the Application Intent settings
	if ($ApplicationIntent -eq $true)
	{
		$connectionString = $connectionString + "; ApplicationIntent=ReadOnly"
	}
	
	if ($connectionString -ne "")
		{
			Write-Host "Passed" -ForegroundColor "Green"
		}
	else
		{
			Write-Host "Failed" -ForegroundColor "Red"
		}
		
    $connectionString = $connectionString + "; Connect Timeout=15"

	Return $connectionString
} #End Create-SQLConnectionString

function New-Table #Creates a dataset from the provided parameters
{
	[CmdletBinding()]
	param (	[parameter(Mandatory = $true)]
			[string]$TableConnectionString,
			[parameter(Mandatory = $true)]
			[string]$TableQuery
	    )

    $Connection =  New-Object System.Data.SqlClient.SqlConnection
    try 
    {
        #Create a stopwatch to capture duration
        $sw = [Diagnostics.Stopwatch]::StartNew()

        #Create the connection
        $Connection.ConnectionString = $TableConnectionString
        
        #Create the Command
        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.CommandText = $TableQuery
        $command.Connection = $Connection
        $command.CommandTimeout = 240
        
        #Create the adapter and table
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $command
        $DataSet = New-Object System.Data.DataSet
        $Table = new-object system.data.datatable

        #Fill the adapter and table
        $RowsAffected = $SqlAdapter.Fill($DataSet)
        $Table = $DataSet.Tables[0]
    
        #Stop the stopwatch and capture the duration
        $sw.Stop()
        $QueryDuration = $sw.Elapsed

        Write-Host "Complete: $RowsAffected rows returned in $QueryDuration" -ForegroundColor "Green"
    }
    catch
    {
         #Stop the stopwatch and capture the duration
        $sw.Stop()
        $QueryDuration = $sw.Elapsed

        #Write the message and error to the stack and bail out
        Write-Host "Failed in $QueryDuration seconds" -ForegroundColor "Red"
        Write-Host $_.Exception.Message -ForegroundColor "Red"
        Write-Host $_.Exception.ItemName -ForegroundColor "Red"
        break
    }
    finally
    {
        $Connection.Dispose()
    }

        return ,$Table
} #End Create-Table

function New-DynamicSourceQuery #Creates the query to use on the source system
{
	[CmdletBinding()]
	param (	[parameter(Mandatory = $true)]
			[string]$TableName,
			[parameter(Mandatory = $true)]
			[string]$IndexHint
	)
	
	try 
	{
		$DynamicSourceQuery = "SET NOCOUNT ON;

--Create the temp tables
IF(OBJECT_ID('tempdb.dbo.#Range') IS NOT NULL)
	BEGIN
	DROP TABLE #Range
	END

CREATE TABLE #Range (StartValue bigint, EndValue bigint)


IF(OBJECT_ID('tempdb.dbo.#RowModVersion') IS NOT NULL)
	BEGIN
	DROP TABLE #RowModVersion
	END

CREATE TABLE #RowModVersion (RowModVersion bigint)

--Declare the locals
DECLARE @Start bigint = 0,
		@End bigint,
		@BatchSize bigint = 1000000,
		@NextValue bigint

--Get the max rowmodversion from the table
SELECT @End = (SELECT MAX(RowModVersion) FROM $TableName WITH(INDEX($IndexHint)));

--Create the histogram buckets
WHILE @Start <= @End
	BEGIN
	SET @NextValue = @Start + @BatchSize
	INSERT INTO #Range (StartValue, EndValue) VALUES(@Start,@NextValue)
	SET @Start = @NextValue
	END

--Insert the values from the table into a temp table, to make sure we get a good index hit.
INSERT INTO #RowModVersion (RowModVersion)
SELECT RowModVersion
FROM $TableName WITH(INDEX($IndexHint));

--Index the tables for speed.
CREATE INDEX IDX_#Range_StartEnd ON #Range(StartValue, EndValue)
CREATE INDEX IDX_#RowModVersion_RowModVersion ON #RowModVersion(RowModVersion)

--Return the results
SELECT  R.StartValue,COUNT(*) AS [Count], CAST(0 AS INT) AS [SourceDelta]
FROM #RowModVersion AS W 
	JOIN #Range AS R ON W.RowModVersion BETWEEN R.StartValue AND R.EndValue
GROUP BY R.StartValue
ORDER BY R.StartValue"

		 #Write the message and error to the stack and bail out
		 Write-Host "Passed" -ForegroundColor "Green"
	}
	catch 
	{
		 #Write the message and error to the stack and bail out
		 Write-Host "Failed" -ForegroundColor "Red"
	}


Return $DynamicSourceQuery
} #End New-DynamicSourceQuery

function New-DynamicTargetQuery #Creates the query to use on the source system
{
	[CmdletBinding()]
	param (	[parameter(Mandatory = $true)]
			[string]$TableName,
			[parameter(Mandatory = $true)]
			[string]$IndexHint
	)
	try 
	{
		$DynamicTargetQuery = "SET NOCOUNT ON;

--Create the temp tables
IF(OBJECT_ID('tempdb.dbo.#Range') IS NOT NULL)
	BEGIN
	DROP TABLE #Range
	END

CREATE TABLE #Range (StartValue bigint, EndValue bigint)


IF(OBJECT_ID('tempdb.dbo.#RowModVersion') IS NOT NULL)
	BEGIN
	DROP TABLE #RowModVersion
	END

CREATE TABLE #RowModVersion (RowModVersion bigint)

--Declare the locals
DECLARE @Start bigint = 0,
		@End bigint,
		@BatchSize bigint = 1000000,
		@NextValue bigint

--Get the max rowmodversion from the table
SELECT @End = (SELECT MAX(RowModVersion) FROM $TableName WITH(INDEX($IndexHint)));

--Create the histogram buckets
WHILE @Start <= @End
	BEGIN
	SET @NextValue = @Start + @BatchSize
	INSERT INTO #Range (StartValue, EndValue) VALUES(@Start,@NextValue)
	SET @Start = @NextValue
	END

--Insert the values from the table into a temp table, to make sure we get a good index hit.
INSERT INTO #RowModVersion (RowModVersion)
SELECT RowModVersion
FROM $TableName WITH(INDEX($IndexHint));

--Index the tables for speed.
CREATE INDEX IDX_#Range_StartEnd ON #Range(StartValue, EndValue)
CREATE INDEX IDX_#RowModVersion_RowModVersion ON #RowModVersion(RowModVersion)

--Return the results
SELECT  R.StartValue,COUNT(*) AS [Count], CAST(0 AS INT) AS [SourceDelta]
FROM #RowModVersion AS W 
	JOIN #Range AS R ON W.RowModVersion BETWEEN R.StartValue AND R.EndValue
GROUP BY R.StartValue
ORDER BY R.StartValue"

		 #Write the message and error to the stack and bail out
		 Write-Host "Passed" -ForegroundColor "Green"
	}
	catch 
	{
		 #Write the message and error to the stack and bail out
		 Write-Host "Failed" -ForegroundColor "Red"
	}

	Return $DynamicTargetQuery
} #end New-DynamicTargetQuery

function Invoke-TableCompare #Creates a dataset from the provided parameters
{
	[CmdletBinding()]
	param (	[parameter(Mandatory = $true)]
			[string]$SourceConnectionString,
			[parameter(Mandatory = $true)]
			[string]$TargetConnectionString,
			[parameter(Mandatory = $true)]
			[string]$QuerySource,
			[parameter(Mandatory = $true)]
			[string]$QuueryTarget
	    )

    
    try 
    {
        #Execute the Source query
		Write-Host -NoNewLine "	Running Source Query: " -ForegroundColor "Gray"
		$SourceTable = (New-Table -TableConnectionString $ValidConnectionStringSource -TableQuery $SourceQuery)

		#Execute the Target query
		Write-Host -NoNewLine "	Running Target Query: " -ForegroundColor "Gray"
		$TargetTable = (New-Table -TableConnectionString $ValidConnectionStringTarget -TableQuery $TargetQuery)
    }
    catch
    {
        
    }
    finally
    {
        
    }

     return ,$Table
} #End Create-Table

<#******************************************************************************
**	                             Script		                        	      ** 
******************************************************************************#>
Clear-Host
$ErrorActionPreference="Stop"
Write-Host "Starting" -ForegroundColor "Gray"

#Construct a connection string to the Source
Write-Host -NoNewLine "	Create the connection string to the source: " -ForegroundColor "Gray"
$ValidConnectionStringSource = (New-SQLConnectionString -SqlServerName "AGLHQTEST0.hqtest.tst,46926" -DatabaseName "Docusign" -TrustedConnection $true -UserName "Username" -Password "Password" -MultiSubnetFailover $False -ApplicationIntent $False)

#Construct a connection string to the Target
Write-Host -NoNewLine "	Create the connection string to the target: " -ForegroundColor "Gray"
$ValidConnectionStringTarget = (New-SQLConnectionString -SqlServerName "AGLHQTEST0.hqtest.tst,46926" -DatabaseName "EnvelopeSearch" -TrustedConnection $true -UserName "Username" -Password "Password" -MultiSubnetFailover $False -ApplicationIntent $False)

#Validate SQL Server instance source
Write-Host -NoNewLine "	Validating SQL Instance Source: " -ForegroundColor "Gray"
$ValidSQLConnection = (Test-SQLConnectionString -ConnectionString $ValidConnectionStringSource)
if($ValidSQLConnection -eq $false) {Exit}

#Validate SQL Server instance target
Write-Host -NoNewLine "	Validating SQL Instance Source: " -ForegroundColor "Gray"
$ValidSQLConnection = (Test-SQLConnectionString -ConnectionString $ValidConnectionStringTarget)
if($ValidSQLConnection -eq $false) {Exit}

#Validate the Export directory exists, and we can access it
Write-Host -NoNewLine "	Validating Export Directory: " -ForegroundColor "Gray"
$ValidExportDirectory = (Find-TargetDirectory -TargetDirectory "C:\Temp" -CreateIfMissing $true) 
if ($ValidExportDirectory -eq $false) {Exit}

#Construct a source query
Write-Host -NoNewLine "	Constructing Source Query: " -ForegroundColor "Gray"
$SourceQuery = (New-DynamicSourceQuery -TableName "[dbo].[Activation]" -IndexHint "IX_Activation_RowModVersion" )
if ($SourceQuery -eq $false) {Exit}

#Construct a target query
Write-Host -NoNewLine "	Constructing Target Query: " -ForegroundColor "Gray"
$TargetQuery = (New-DynamicTargetQuery -TableName "[dbo].[Activation]" -IndexHint "IX_Activation_RowModVersion" )
if ($TargetQuery -eq $false) {Exit}

#Execute the Source query
Write-Host -NoNewLine "	Running Source Query: " -ForegroundColor "Gray"
$SourceTable = (New-Table -TableConnectionString $ValidConnectionStringSource -TableQuery $SourceQuery)

#Execute the Target query
Write-Host -NoNewLine "	Running Target Query: " -ForegroundColor "Gray"
$TargetTable = (New-Table -TableConnectionString $ValidConnectionStringTarget -TableQuery $TargetQuery)

#Merge the tables 
Write-Host -NoNewLine "	Merging results: " -ForegroundColor "Gray"
try     {
            $ResultTable = new-object system.data.datatable
            [void]$ResultTable.Columns.Add("RowModVersionBucket", [Double])
            [void]$ResultTable.Columns.Add("SourceCount", [Double])
            [void]$ResultTable.Columns.Add("TargetCount", [Double])
            [void]$ResultTable.Columns.Add("SourceDelta", [Double])
            [void]$ResultTable.Columns.Add("TargetDelta", [Double])

            foreach ($row in $SourceTable)
                {
                foreach ($Result in $TargetTable)
                    {
                        if($row.StartValue -eq $result.StartValue)
                            {
                                $NewRow = $ResultTable.NewRow()
                                $NewRow.RowModVersionBucket = $row.StartValue
                                $NewRow.SourceCount = $row.Count
                                $NewRow.TargetCount = $result.Count
                                $NewRow.SourceDelta = [int]$row.Count - [int]$result.Count
                                $NewRow.TargetDelta = [int]$result.Count - [int]$row.Count
                                $ResultTable.Rows.Add($NewRow)
                            }
                    }
                }
                
            $ResultTable | Format-Table -AutoSize | Out-File -FilePath "C:\Temp\ResultTable.txt"
        
            Write-Host "Passed" -ForegroundColor "Green"
        }
catch   {
            Write-Host "Failed" -ForegroundColor "Red"
        }

Write-Host "Finished" -ForegroundColor "Gray"