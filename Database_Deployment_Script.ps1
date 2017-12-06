# Code to ensure SQLPS is loaded
cls
function Import-Module-SQLPS {
    #pushd and popd to avoid import from changing the current directory (ref: http://stackoverflow.com/questions/12915299/sql-server-2012-sqlps-module-changing-current-location-automatically)
    #3>&1 puts warning stream to standard output stream (see https://connect.microsoft.com/PowerShell/feedback/details/297055/capture-warning-verbose-debug-and-host-output-via-alternate-streams)
    #out-null blocks that output, so we don't see the annoying warnings described here: https://www.codykonior.com/2015/05/30/whats-wrong-with-sqlps/
    push-location
    import-module sqlps 3>&1 | out-null
    pop-location
}
 
Import-Module-SQLPS

###########################################################################################################
# SET THESE VARIABLES TO DEFINE THE DB NAMING AND SERVER
###########################################################################################################
# Database name variables
$databaseName = 'API_Extractions'
# Server where the databases will be deployed
$serverName = 'SERVER_NAME_GOES_HERE'
###########################################################################################################

$ns = 'Microsoft.SqlServer.Management.Smo'
$server = New-Object ("$ns.Server") ($serverName)

# Make DBs
$db = New-Object ("$ns.Database") ($server, "$databaseName")
$db.Create()

# Populate all objects through DDL scripts
Get-ChildItem -Path "$PSScriptRoot\" -Recurse -Filter *.sql -File | sort FullName |
ForEach-Object {
    # read file into variable / run code in SQL
    $sqlQuery = Get-Content $_.FullName -Raw
    Invoke-Sqlcmd -Query $sqlQuery -ServerInstance $serverName -Database $databaseName
}

# Display all objects created by DB
Invoke-Sqlcmd -Query "SELECT '$databaseName' as DBName, Type, Name, create_date FROM sys.objects WHERE type IN ( 'U', 'V', 'IF', 'TR', 'P', 'TT' ) ORDER BY Type, name" -ServerInstance $serverName -Database $databaseName
Invoke-Sqlcmd -Query "use master;"  -ServerInstance $serverName -Database $databaseName
