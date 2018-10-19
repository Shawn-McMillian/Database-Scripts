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
function Test-SQLConnection #Check to see if the SQL Server provided can be connected to.
{    
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        $ConnectionString
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

function Check-TargetDirectory #Checks to see if the $TargetDirectory exists, optionally creates if not
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
		#Write-Verbose "Target directory: $TargetDirectory exists";
		[bool]$global:TargetDirectoryExists = $true
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

function Create-SQLConnectionString #Creates the connection string from the values provided
{
	[CmdletBinding()]
	param (	[parameter(Mandatory = $true)]
			[string]$SqlServerName,
			[parameter(Mandatory = $true)]
			[string]$DatabaseName,
			[parameter(Mandatory = $true)]
			[bool]$TrustedConnection = $true,
			[parameter(Mandatory = $true)]
			[string]$UserName,
			[parameter(Mandatory = $true)]
			[string]$Password,
			[parameter(Mandatory = $true)]
			[bool]$MultiSubnetFailover = $false,
			[parameter(Mandatory = $true)]
			[bool]$ApplicationIntent = $false
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

function Create-Table #Creates a dataset from the provided parameters
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
        $command.CommandTimeout = 120
        
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

function AddItemProperties($item, $properties, $output)
{
    if($item -ne $null)
    {
        foreach($property in $properties)
        {
            $propertyHash =$property -as [hashtable]
            if($propertyHash -ne $null)
            {
                $hashName=$propertyHash["name"] -as [string]
                if($hashName -eq $null)
                {
                    throw "there should be a string Name"  
                }
         
                $expression=$propertyHash["expression"] -as [scriptblock]
                if($expression -eq $null)
                {
                    throw "there should be a ScriptBlock Expression"  
                }
         
                $_=$item
                $expressionValue=& $expression
         
                $output | add-member -MemberType "NoteProperty" -Name $hashName -Value $expressionValue
            }
            else
            {
                # .psobject.Properties allows you to list the properties of any object, also known as "reflection"
                foreach($itemProperty in $item.psobject.Properties)
                {
                    if ($itemProperty.Name -like $property)
                    {
                        $output | add-member -MemberType "NoteProperty" -Name $itemProperty.Name -Value $itemProperty.Value
                    }
                }
            }
        }
    }
} #End AddItemProperties

    
function WriteJoinObjectOutput($leftItem, $rightItem, $leftProperties, $rightProperties, $Type)
{
    $output = new-object psobject

    if($Type -eq "AllInRight")
    {
        # This mix of rightItem with LeftProperties and vice versa is due to
        # the switch of Left and Right arguments for AllInRight
        AddItemProperties $rightItem $leftProperties $output
        AddItemProperties $leftItem $rightProperties $output
    }
    else
    {
        AddItemProperties $leftItem $leftProperties $output
        AddItemProperties $rightItem $rightProperties $output
    }
    $output
} #WriteJoinObjectOutput

function Join-Object
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # List to join with $Right
        [Parameter(Mandatory=$true,
                   Position=0)]
        [object[]]
        $Left,

        # List to join with $Left
        [Parameter(Mandatory=$true,
                   Position=1)]
        [object[]]
        $Right,

        # Condition in which an item in the left matches an item in the right
        # typically something like: {$args[0].Id -eq $args[1].Id}
        [Parameter(Mandatory=$true,
                   Position=2)]
        [scriptblock]
        $Where,

        # Properties from $Left we want in the output.
        # Each property can:
        # – Be a plain property name like "Name"
        # – Contain wildcards like "*"
        # – Be a hashtable like @{Name="Product Name";Expression={$_.Name}}. Name is the output property name
        #   and Expression is the property value. The same syntax is available in select-object and it is 
        #   important for join-object because joined lists could have a property with the same name
        [Parameter(Mandatory=$true,
                   Position=3)]
        [object[]]
        $LeftProperties,

        # Properties from $Right we want in the output.
        # Like LeftProperties, each can be a plain name, wildcard or hashtable. See the LeftProperties comments.
        [Parameter(Mandatory=$true,
                   Position=4)]
        [object[]]
        $RightProperties,

        # Type of join. 
        #   AllInLeft will have all elements from Left at least once in the output, and might appear more than once
        # if the where clause is true for more than one element in right, Left elements with matches in Right are 
        # preceded by elements with no matches. This is equivalent to an outer left join (or simply left join) 
        # SQL statement.
        #  AllInRight is similar to AllInLeft.
        #  OnlyIfInBoth will cause all elements from Left to be placed in the output, only if there is at least one
        # match in Right. This is equivalent to a SQL inner join (or simply join) statement.
        #  AllInBoth will have all entries in right and left in the output. Specifically, it will have all entries
        # in right with at least one match in left, followed by all entries in Right with no matches in left, 
        # followed by all entries in Left with no matches in Right.This is equivallent to a SQL full join.
        [Parameter(Mandatory=$false,
                   Position=5)]
        [ValidateSet("AllInLeft","OnlyIfInBoth","AllInBoth", "AllInRight")]
        [string]
        $Type="OnlyIfInBoth"
    )

    Begin
    {
        # a list of the matches in right for each object in left
        $leftMatchesInRight = new-object System.Collections.ArrayList

        # the count for all matches  
        $rightMatchesCount = New-Object "object[]" $Right.Count

        for($i=0;$i -lt $Right.Count;$i++)
        {
            $rightMatchesCount[$i]=0
        }
    }

    Process
    {
        if($Type -eq "AllInRight")
        {
            # for AllInRight we just switch Left and Right
            $aux = $Left
            $Left = $Right
            $Right = $aux
        }

        # go over items in $Left and produce the list of matches
        foreach($leftItem in $Left)
        {
            $leftItemMatchesInRight = new-object System.Collections.ArrayList
            $null = $leftMatchesInRight.Add($leftItemMatchesInRight)

            for($i=0; $i -lt $right.Count;$i++)
            {
                $rightItem=$right[$i]

                if($Type -eq "AllInRight")
                {
                    # For AllInRight, we want $args[0] to refer to the left and $args[1] to refer to right,
                    # but since we switched left and right, we have to switch the where arguments
                    $whereLeft = $rightItem
                    $whereRight = $leftItem
                }
                else
                {
                    $whereLeft = $leftItem
                    $whereRight = $rightItem
                }

                if(Invoke-Command -ScriptBlock $where -ArgumentList $whereLeft,$whereRight)
                {
                    $null = $leftItemMatchesInRight.Add($rightItem)
                    $rightMatchesCount[$i]++
                }
            
            }
        }

        # go over the list of matches and produce output
        for($i=0; $i -lt $left.Count;$i++)
        {
            $leftItemMatchesInRight=$leftMatchesInRight[$i]
            $leftItem=$left[$i]
                               
            if($leftItemMatchesInRight.Count -eq 0)
            {
                if($Type -ne "OnlyIfInBoth")
                {
                    WriteJoinObjectOutput $leftItem  $null  $LeftProperties  $RightProperties $Type
                }

                continue
            }

            foreach($leftItemMatchInRight in $leftItemMatchesInRight)
            {
                WriteJoinObjectOutput $leftItem $leftItemMatchInRight  $LeftProperties  $RightProperties $Type
            }
        }
    }

    End
    {
        #produce final output for members of right with no matches for the AllInBoth option
        if($Type -eq "AllInBoth")
        {
            for($i=0; $i -lt $right.Count;$i++)
            {
                $rightMatchCount=$rightMatchesCount[$i]
                if($rightMatchCount -eq 0)
                {
                    $rightItem=$Right[$i]
                    WriteJoinObjectOutput $null $rightItem $LeftProperties $RightProperties $Type
                }
            }
        }
    }
} #end Join-Object

<#******************************************************************************
**	                             Script		                        	      ** 
******************************************************************************#>
Clear
$ErrorActionPreference="Stop"
Write-Host "Starting" -ForegroundColor "Gray"

$SourceQuery = "IF(OBJECT_ID('tempdb.dbo.#Range') IS NULL)
	BEGIN
	CREATE TABLE #Range (StartValue bigint, EndValue bigint)
	END
ELSE
	BEGIN
	TRUNCATE TABLE #Range
	END

DECLARE @Start bigint = 0,
		@End bigint,
		@BatchSize bigint = 1000000,
		@NextValue bigint

SELECT @End = (SELECT MAX(RowModVersion) FROM Envelope WITH(INDEX(IX_Envelope_RowModVersion)));

WHILE @Start <= @End
	BEGIN
	SET @NextValue = @Start + @BatchSize
	INSERT INTO #Range (StartValue, EndValue) VALUES(@Start,@NextValue)
	SET @Start = @NextValue
	END

SELECT R.StartValue, COUNT(*) AS [SourceCount], '' AS [SourceDelta]
FROM Envelope AS W
	JOIN #Range AS R ON W.RowModVersion BETWEEN R.StartValue AND R.EndValue
GROUP BY R.StartValue
ORDER BY R.StartValue"

$TargetQuery = "IF(OBJECT_ID('tempdb.dbo.#Range') IS NULL)
	BEGIN
	CREATE TABLE #Range (StartValue bigint, EndValue bigint)
	END
ELSE
	BEGIN
	TRUNCATE TABLE #Range
	END

DECLARE @Start bigint = 0,
		@End bigint,
		@BatchSize bigint = 1000000,
		@NextValue bigint

SELECT @End = (SELECT MAX(RowModVersion) FROM Envelope WITH(INDEX(IX_Envelope_RowModVersion)));

WHILE @Start <= @End
	BEGIN
	SET @NextValue = @Start + @BatchSize
	INSERT INTO #Range (StartValue, EndValue) VALUES(@Start,@NextValue)
	SET @Start = @NextValue
	END

CREATE INDEX IDX_#Range_Test ON #Range(StartValue, EndValue)

SELECT RowModVersion INTO #Temp1 FROM Envelope

CREATE INDEX IDX_#Temp1_Test ON #Temp1(RowModVersion) 

SELECT R.StartValue, COUNT(*) AS [TargetCount], '' AS [TargetDelta]
FROM #Temp1 AS W 
	JOIN #Range AS R ON W.RowModVersion BETWEEN R.StartValue AND R.EndValue
GROUP BY R.StartValue
ORDER BY R.StartValue"

#Construct a connection string to the Source
Write-Host -NoNewLine "	Create the connection string to the source: " -ForegroundColor "Gray"
$ValidConnectionStringSource = (Create-SQLConnectionString -SqlServerName "AGLHQTEST0.hqtest.tst,46926" -DatabaseName "Docusign" -TrustedConnection $true -UserName "Username" -Password "Password" -MultiSubnetFailover $False -ApplicationIntent $False)

#Construct a connection string to the Target
Write-Host -NoNewLine "	Create the connection string to the target: " -ForegroundColor "Gray"
$ValidConnectionStringTarget = (Create-SQLConnectionString -SqlServerName "AGLHQTEST0.hqtest.tst,46926" -DatabaseName "EnvelopeSearch" -TrustedConnection $true -UserName "Username" -Password "Password" -MultiSubnetFailover $False -ApplicationIntent $False)

#Validate SQL Server instance source
Write-Host -NoNewLine "	Validating SQL Instance Source: " -ForegroundColor "Gray"
$ValidSQLConnection = (Test-SQLConnection -ConnectionString $ValidConnectionStringSource)

#Validate SQL Server instance target
Write-Host -NoNewLine "	Validating SQL Instance Source: " -ForegroundColor "Gray"
$ValidSQLConnection = (Test-SQLConnection -ConnectionString $ValidConnectionStringTarget)

#Validate the Export directory exists, and we can access it
Write-Host -NoNewLine "	Validating Export Directory: " -ForegroundColor "Gray"
$ValidExportDirectory = (Check-TargetDirectory -TargetDirectory "C:\Temp" -CreateIfMissing $true) 
if ($ValidExportDirectory -eq $false) {Exit}

#Execute the Source query
Write-Host -NoNewLine "	Running Source Query: " -ForegroundColor "Gray"
$SourceTable = (Create-Table -TableConnectionString $ValidConnectionStringSource -TableQuery $SourceQuery)
#$SourceTable | format-table -auto > "C:\Temp\SourceQuery"

#Execute the Target query
Write-Host -NoNewLine "	Running Target Query: " -ForegroundColor "Gray"
$TargetTable = (Create-Table -TableConnectionString $ValidConnectionStringTarget -TableQuery $TargetQuery)
#$TargetTable | format-table -auto > "C:\Temp\TargetQuery"

#Join the tables 
Write-Host -NoNewLine "	Merging queries: " -ForegroundColor "Gray"
$TableResults = join-object -Left $SourceTable -Right $TargetTable -Where {$args[0].StartValue -eq $args[1].StartValue}  -Type AllInBoth -LeftProperties  StartValue, SourceCount, SourceDelta -RightProperties TargetCount, TargetDelta
#$TableResults | format-table -auto > "C:\Temp\CombinedQuery"
Write-Host "Passed" -ForegroundColor "Green"

#Walk the results and calculate the Delta
Write-Host -NoNewLine "	Calculating Delta: " -ForegroundColor "Gray"
foreach ($row in $TableResults)
    {
        $row.SourceDelta = [int]$row.SourceCount - [int]$row.TargetCount
        $row.TargetDelta = [int]$row.TargetCount - [int]$row.SourceCount
    }

$TableResults | export-csv "C:\Temp\CombinedResults.csv" -notypeinformation
Write-Host "Passed" -ForegroundColor "Green"


Write-Host "Finished" -ForegroundColor "Gray"