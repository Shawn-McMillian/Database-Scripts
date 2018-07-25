<#******************************************************************************
**	       Intellectual property of DocuSign, All rights reserved.			  ** 
**  		This computer program is protected by copyright law				  **
**  					and international treaties.							  **
********************************************************************************
**                                                                            **
** Script Name: 	SQL Query to CSV      							          **
** Version:			1.00.00													  **
** Created By:		Shawn McMillian											  **
** Description:		Execute the provided query and capture the results to CSV **
********************************************************************************
** Revision History:														  **
** ---------------------------------------------------------------------------**
** Date			Name				Description							      **
** ---------------------------------------------------------------------------**
** 09/16/2008	Shawn McMillian		Created                                   **
#*****************************************************************************#>
# ./'\SQL Query to CSV.ps1' -SQLInstance "SomeServer" -DatabaseName "master" -UseTrustedSecurity $true -UserName "UserName" -Password "Password" -MultiSubnetFailover $false -ApplicationIntent $false -ResultsDirectory "C:Temp" -ResultsFile "Results.csv" -QueryToExecute "SELECT * FROM sys.dm_exec_sessions WHERE HOST_NAME IS NOT NULL;"
########################## VARS ######################
[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string] $SQLInstance = "DSW011048\DS02",
	
	[Parameter(Mandatory = $true)]
	[string] $DatabaseName = "master",
	
	[Parameter(Mandatory = $true)]
	[bool] $UseTrustedSecurity = $true,
	
	[Parameter(Mandatory = $false)]
	[string] $UserName = "UserName",
	
	[Parameter(Mandatory = $false)]
	[string] $Password = "Password",
	
	[Parameter(Mandatory = $true)]
	[bool] $MultiSubnetFailover = $false,
	
	[Parameter(Mandatory = $true)]
	[bool] $ApplicationIntent = $false,
	
	[Parameter(Mandatory = $true)]
	[string] $QueryToExecute = "SELECT * FROM sys.dm_exec_sessions WHERE HOST_NAME IS NOT NULL;",
	
	[Parameter(Mandatory = $true)]
	[string]
	$ResultsDirectory = "C:\Temp",
	
	[Parameter(Mandatory = $true)]
	[string]
	$ResultsFile = "Results.csv"
)

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
		
	Return $connectionString
} #End Create-SQLConnectionString

<#******************************************************************************
**	                             Script		                        	      ** 
******************************************************************************#>
Clear
Write-Host "Starting" -ForegroundColor "Gray"

#Construct a connection string
Write-Host -NoNewLine "	Create the connection string: " -ForegroundColor "Gray"
$ValidConnectionString = (Create-SQLConnectionString -SqlServerName $SQLInstance -DatabaseName $DatabaseName -TrustedConnection $UseTrustedSecurity -UserName $UserName -Password $Password -MultiSubnetFailover $MultiSubnetFailover -ApplicationIntent $ApplicationIntent)

#Validate SQL Server instance
Write-Host -NoNewLine "	Validating SQL Instance: " -ForegroundColor "Gray"
$ValidSQLConnection = (Test-SQLConnection -ConnectionString $ValidConnectionString)

#Validate the Export directory exists, and we can access it
Write-Host -NoNewLine "	Validating Export Directory: " -ForegroundColor "Gray"
$ValidExportDirectory = (Check-TargetDirectory -TargetDirectory $ResultsDirectory -CreateIfMissing $true) 
if ($ValidExportDirectory -eq $false) {Exit}

#Execute the query and return the results
Write-Host -NoNewLine "	Exporting Data to file: " -ForegroundColor "Gray"

$connection =  New-Object System.Data.SqlClient.SqlConnection
  try 
  {
    $connection.ConnectionString = $ValidConnectionString
    
    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.CommandText = $QueryToExecute
    $command.Connection = $Connection
    
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $command
    $DataSet = New-Object System.Data.DataSet
    $RowsAffected = $SqlAdapter.Fill($DataSet)
    
    #$DataSet.Tables[0] | Export-Csv "$ResultsDirectory/$ResultsFile" -NoTypeInformation -Encoding UTF8 -Delimiter ","
	foreach ($row in $DataSet.Tables[0].Rows)
		{ 
  		$Test = $row[0].ToString().Trim()
		Write-Host $Test
  		}  
	
	Write-Host "Complete: $RowsAffected rows returned" -ForegroundColor "Green"
  }
  catch
  {
  Write-Host "Failed" -ForegroundColor "Green"
  }
  finally
  {
    $connection.Dispose()
  }

Write-Host "Finished" -ForegroundColor "Gray"


