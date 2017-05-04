$limit = (Get-Date).AddDays(-25)
$path = "D:"
Get-ChildItem -Path $path -include *.bak, *.trn -Recurse -ErrorAction SilentlyContinue | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | select-object FullName, CreationTime, Length | Out-GridView
