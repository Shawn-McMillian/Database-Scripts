$Path = "C:\Users\shawn.mcmillian\Downloads\SQLScripts\"
$CombineFile = Join-Path -Path $Path -ChildPath "CombinedFiles.sql"
cls

foreach ($f in Get-ChildItem -path $Path -Filter *.sql | sort-object) 
{ 
     $FileToRead = Join-Path -Path $Path -ChildPath $f.Name
    Get-Content -Path $FileToRead | Out-File -filepath $CombineFile -Append
}