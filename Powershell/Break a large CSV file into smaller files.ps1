# variable used to store the path of the source CSV file
$sourceCSV = "C:\Users\shawn.mcmillian\Downloads\Statefarm - A8B79DA9-C839-4753-8640-E1EF95DD48E1.csv" ;

# variable used to advance the number of the row from which the export starts
$startrow = 0 ;

# counter used in names of resulting CSV files
$counter = 1 ;

# setting the while loop to continue as long as the value of the $startrow variable is smaller than the number of rows in your source CSV file
while ($startrow -lt 100000000)
{

# import of however many rows you want the resulting CSV to contain starting from the $startrow position and export of the imported content to a new file
Import-CSV $sourceCSV | select-object -skip $startrow -first 100000 | Export-CSV "C:\Users\shawn.mcmillian\Downloads\Statefarm - A8B79DA9-C839-4753-8640-E1EF95DD48E1 - $($counter).csv" -NoClobber;

# advancing the number of the row from which the export starts
$startrow += 100000 ;

# incrementing the $counter variable
$counter++ ;

}
