<#******************************************************************************
**	       Intellectual property of DocuSign, All rights reserved.			  ** 
**  		This computer program is protected by copyright law				  **
**  					and international treaties.							  **
********************************************************************************
**                                                                            **
** Script Name: 	Remote Procedure Execute      							  **
** Version:			1.00.00													  **
** Created By:		Shawn McMillian											  **
** Description:		Execute the provided procedure and capture statistics     **
**					about the execution.
********************************************************************************
** Revision History:														  **
** ---------------------------------------------------------------------------**
** Date			Name				Description							      **
** ---------------------------------------------------------------------------**
** 05/02/2018	Shawn McMillian		Created                                   **
#*****************************************************************************#>
# . 'C:\Users\shawn.mcmillian\Box Sync\Development\PowerShell\EDW Full pull Export.ps1' -SQLInstance "DSW011048\DS02" -DatabaseName "master" -Procedure "sys.sp_who2" -UseTrustedSecurity = "true"

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
	
	[Parameter(Mandatory = $true)]
	[string] $DatabaseName = "UserName",
	
	[Parameter(Mandatory = $false)]
	[string] $DatabaseName = "Password",
	
	[Parameter(Mandatory = $false)]
	[string] $ProcedureToExecute = "sys.sp_who2",
	
	[Parameter(Mandatory = $true)]
	[string]
	$QueryDirectory = "C:\Temp\RemoteProcedureExecute"
	
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

function Create-SQLConnectionString #Checks to see if the $TargetDirectory exists, optionally creates if not
{
	[CmdletBinding()]
	param (	[parameter(Mandatory = $true)]
			[string]$SqlServerName,
			[parameter(Mandatory = $true)]
			[bool]$DatabaseName,
			[parameter(Mandatory = $true)]
			[bool]$TrustedConnection = $true,
			[parameter(Mandatory = $false)]
			[string]$UserName,
			[parameter(Mandatory = $false)]
			[string]$Password,
			[parameter(Mandatory = $false)]
			[bool]$MultiSubnetFailover = $true,
			[parameter(Mandatory = $false)]
			[bool]$ApplicationIntent = $true
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
	if ($MultiSubnetFailover = $true)
	{
		$connectionString = $connectionString + "; multisubnetfailover=True"
	}
	
	#Set the Application Intent settings
	if ($ApplicationIntent = $true)
	{
		$connectionString = $connectionString + "; ApplicationIntent=ReadOnly"
	}
} #End Create-SQLConnectionString

<#******************************************************************************
**	                             Script		                        	      ** 
******************************************************************************#>
Clear
Write-Host "Starting" -ForegroundColor "Gray"

#Construct a connection string
Write-Host -NoNewLine "	Create the connection string:" -ForegroundColor "Gray"
$ValidConnectionString = (Create-SQLConnectionString -SqlServerName $SQLInstance -DatabaseName $DatabaseName -TrustedConnection $TrustedConnection -UserName $UserName -Password $Password -MultiSubnetFailover $MultiSubnetFailover -ApplicationIntent $ApplicationIntent)

#Validate SQL Server instance
Write-Host -NoNewLine "	Validating SQL Instance:" -ForegroundColor "Gray"
$ValidSQLConnection = (Test-SQLConnection -ConnectionString $ValidConnectionString)
if ($ValidSQLConnection -eq $false) {Exit}

#Validate the Export directory exists, and we can access it
Write-Host -NoNewLine "	Validating Export Directory:" -ForegroundColor "Gray"
$ValidExportDirectory = (Check-TargetDirectory -TargetDirectory $ExportDirectory -CreateIfMissing $true) 
if ($ValidExportDirectory -eq $false) {Exit}

#Execute the procedure and return the results and stats

	
Write-Host "Finished" -ForegroundColor "Gray"

