<# 
# NAME: Convert-Encoding.ps1 
# AUTHOR: Stefan Roth / stefanroth.net 
# DATE:18.01.2015 
.Synopsis 
  Converts files in SourcePath to UTF-8 Encoding 
.DESCRIPTION 
  Script converts all files in SourcePath recursevly to UTF-8 and saves them in DestinatioPath 
.EXAMPLE 
   .\Convert-Encoding.ps1 -SourcePath D:\Temp -DestinationPath D:\ConvertedFiles -Encoding utf8 
.INPUTS 
   [String]$SourcePath 
   [String]$DestinationPath 
   [String]$Encoding 
.OUTPUTS 
   - 
.NOTES 
   Be aware that the scripts gets all files recursively starting from the SourcePath!! 
#> 
Param ( 
    [Parameter(Mandatory=$True)][String]$SourcePath, 
    [Parameter(Mandatory=$True)][String]$DestinationPath, 
    [Parameter(Mandatory=$True)][ValidateSet("utf8")][String]$Encoding 
) 
     
    $Files = Get-ChildItem $SourcePath -Recurse -File 
 
        If ($Files.Count -gt 0){ 
     
            If (!($DestinationPath.Substring($DestinationPath.Length - 1) -eq "\")) { 
                $DestinationPath = $DestinationPath + "\" + $Files[0].Directory.Name + "\" 
            } 
            Else { 
                $DestinationPath = $DestinationPath + $Files[0].Directory.Name + "\" 
            } 
 
         If (!(Test-Path -Path $DestinationPath)) {New-Item -ItemType Directory -Path $DestinationPath | Out-Null} 
     
                ForEach($File in $Files) 
                { 
                    Write-Host "Read and Convert $($File.Name)" -ForegroundColor Cyan 
                    Get-Content $File.FullName  | Set-Content -Encoding $Encoding ($DestinationPath + $File.Name) -Force -Confirm:$false 
                } 
 
        Write-Host "Conversion of $($Files.Count) Files to $Encoding in $DestinationPath completed" -ForegroundColor Green 
} 
Else 
{ 
        Write-Host "Source-Directory empty or invalid SourcePath." -ForegroundColor Red 
}