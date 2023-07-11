$limit = (Get-Date).AddDays(-22)
$path = "D:"

# Display all files older than the limit data above, in a Grid view
Get-ChildItem -Path $path -include *.bak, *.trn -Recurse -ErrorAction SilentlyContinue | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | select-object FullName, CreationTime, Length | Out-GridView

#Delete all files older than the limit data above, Whatif will have to be removed (for Safety)
Get-ChildItem -Path $path -include *.bak, *.trn -Recurse -ErrorAction SilentlyContinue | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -WhatIf

# Delete any empty directories left behind after deleting the old files.
Get-ChildItem -Path $path -Recurse | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Recurse -Whatif