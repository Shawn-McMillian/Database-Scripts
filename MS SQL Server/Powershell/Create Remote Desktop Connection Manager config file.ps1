<#
.SYNOPSIS
   Create a remote desktop connection manager file from a text file that contains groups and server names.
.DESCRIPTION
   Provide a file in the correct format and have this script generate the RDCM file. Assume a few things about the file structure and permissions.
.PARAMETER <paramName>
   $InputFileNameFQ - the name of the file that conatins the TAB delimted results
   $TemplateFilNameFQ - Empty rdg file to use as a starting place
   $OutputFileNameFQ - The name of the file to create
.EXAMPLE
   <An example of using the script>
#>
#Input parameters here
$InputFileNameFQ = "C:\Users\shawn.mcmillian\Downloads\SQLInventory.tab"
$TemplateFilNameFQ = "C:\Users\shawn.mcmillian\Downloads\RDCMan Template.rdg"
$OutputFileNameFQ = "C:\Users\shawn.mcmillian\Downloads\SQLRDCM.rdg"

#build the header file
$Header = "DataCenter", "SiteRing", "InstanceRole", "InstanceName"

#Open the file and parse it
$Delimitedfile = Import-Csv -Delimiter "`t" -Path $InputFileNameFQ -Header $Header | ForEach-Object {

#Open the template as XML for editing
[XML]$RDCConfig = Get-Content -Path $TemplateFilNameFQ 

#Loop through each line of the input file and add the groups and servers
foreach ($property in $_.PSObject.Properties)
{
	#Create the data center outer groups if needed
	if($property.Value == "DataCenter")
		{
			switch ($property.Value)
				{
					"Amsterdam" {"EU"}
					"Chicago" {"NA"}
					"Dallas" {"NA"}
					"Chicago" {"NA"}
					"Frankfurt" {"NA"}
					"Seattle" {"NA"}
					default {"Unknown"}
				}
			
		}
		
	Write-Host c
	Write-Host $property.Value
	Write-Host ""
}