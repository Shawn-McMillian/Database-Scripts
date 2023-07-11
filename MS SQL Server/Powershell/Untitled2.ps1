function Invoke-SQL
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]
		$dataSource,
		[Parameter(Mandatory = $true)]
		[string]
		$database,
		[Parameter(Mandatory = $true)]
		[string]
		$sqlCommand = $(throw "Please specify a query."),
		[Parameter(Mandatory = $false)]
		[int]
		$commandTimeOut,
		[Parameter(Mandatory = $false)]
		[Switch]
		$readOnly
	)
		
	if ($readOnly)
	{
		$connectionString = "Data Source=$dataSource; Integrated Security=SSPI; Initial Catalog=$database; multisubnetfailover=True; ApplicationIntent=ReadOnly;"
		#$connectionString = "Data Source=$dataSource; User Id=""DocuSignUser""; Password=""""; Initial Catalog=$database; multisubnetfailover=True; ApplicationIntent=ReadOnly;"
		Write-Verbose "Invoke-Sql passing ApplicationIntent = ReadOnly"
	}
	else
	{
		$connectionString = "Data Source=$dataSource; Integrated Security=SSPI; Initial Catalog=$database; multisubnetfailover=True; ApplicationIntent=ReadWrite;"
		#$connectionString = "Data Source=$dataSource; User Id=""DocuSignUser""; Password=""""; Initial Catalog=$database; multisubnetfailover=True; ApplicationIntent=ReadWrite;"
		Write-Verbose "Invoke-Sql passing ApplicationIntent = ReadWrite"
	}

	if (!($commandTimeOut))
	{
		[int]$commandTimeOut = 120
	}
	
	Add-Type -AssemblyName System.Data
	Write-Verbose "ConnectionString: $connectionString"
	Write-Verbose "Query timeout: $commandTimeOut seconds"
	$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
	$command = new-object system.data.sqlclient.sqlcommand($sqlCommand, $connection)
	$command.CommandTimeout = $commandTimeOut
	$connection.Open()
	
	$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
	$dataset = New-Object System.Data.DataSet
	$adapter.Fill($dataSet) | Out-Null
	
	$connection.Close()
	$dataSet.Tables
}

function Test-SQL
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]
		$ServerName,
		[Parameter(Mandatory = $true)]
		[bool]
		$ReadOnly
	)
	
	#Test the proc once
	Write-Host "Testing $ServerName" -ForegroundColor "Red"
	$sw = [Diagnostics.Stopwatch]::StartNew()
	$Data = Invoke-SQL -dataSource $ServerName -database Docusign -readOnly $ReadOnly -sqlCommand "exec SelectEnvelopeIntegrationByAccountId @AccountId='8981D027-92FA-4D93-B3D7-93B28D9DEE1A';"
	$RowCount = $Data.rows.Count
	$sw.Stop()
	$Duration = $sw.ElapsedMilliseconds
	Write-Host "Rows Returned:$RowCount" -ForegroundColor "Green"
	Write-Host "Duration (Milliseconds):$Duration" -ForegroundColor "Green"
	$Data.Clear()
	Clear-Variable RowCount
	Clear-Variable Duration
	Clear-Variable sw
	
	$sw = [Diagnostics.Stopwatch]::StartNew()
	$Data = Invoke-SQL -dataSource $ServerName -database Docusign -readOnly $ReadOnly -sqlCommand "exec SelectEnvelopeIntegrationByAccountId @AccountId='8981D027-92FA-4D93-B3D7-93B28D9DEE1A';"
	$RowCount = $Data.rows.Count
	$sw.Stop()
	$Duration = $sw.ElapsedMilliseconds
	Write-Host "Rows Returned:$RowCount" -ForegroundColor "Green"
	Write-Host "Duration (Milliseconds):$Duration" -ForegroundColor "Green"
	$Data.Clear()
	Clear-Variable RowCount
	Clear-Variable Duration
	Clear-Variable sw

}


cls

Test-SQL -ServerName "SENA1DB1F" -ReadOnly $false

Test-SQL -ServerName "DANA1DB1H" -ReadOnly $false

Test-SQL -ServerName "AGLNA101" -ReadOnly $false

Test-SQL -ServerName "AGLNA101" -ReadOnly $true

