# Writes data to SQL from a hash table
function Insert-OneRow ([System.Collections.ArrayList]$connDB,[System.Collections.Hashtable]$keyValues) {
    # ConnDB[0] = server / [1] = DB / [2] = (schema.)table
    $insertSQL = "INSERT INTO " + $connDB[2] + " ( "
    $valuesSQL = "VALUES ( "
    ForEach ( $key in $keyValues.GetEnumerator() ) {
        $insertSQL = $insertSQL + $key.Name + ", "
        $valuesSQL = $valuesSQL + "'" + $key.Value + "', "
    }
    $insertSQL = $insertSQL.Substring(0,$insertSQL.Length - 2) + " ) "
    $valuesSQL = $valuesSQL.Substring(0,$valuesSQL.Length - 2) + " );"
    # Execute SQL Strings together
    try {
        Invoke-Sqlcmd -Query ( $insertSQL + $valuesSQL ) -ServerInstance ($connDB[0]) -Database ($connDB[1])
        return @(( $insertSQL + $valuesSQL ), 1) # SQL Used / Rows inserted
    }
    catch {
        return @(( $insertSQL + $valuesSQL ), 0) # Flag that nothing was inserted
    }
}

# Writes to the log using any passed information
function Insert-ExtractionLog ([System.Collections.ArrayList]$connDB,[string]$logText,[System.Collections.Hashtable]$apiData,[System.Collections.Hashtable]$sqlData,[Bool]$isFail) {
    $keyValues = @{ "RunID" = $connDB[3] ; "LogText" = $logText }
    if ( $connDB[5] -gt 0 ) {
        $keyValues.Add( "VendorID", $connDB[5].ToString() )
    }
    if ( $connDB[6] -gt 0 ) {
        $keyValues.Add( "APIID", $connDB[6].ToString() )
    }
    if ( $connDB[7] -gt 0 ) {
        $keyValues.Add( "IntegrationID", $connDB[7].ToString() )
    }
    if ( $apiData.Count -ne 0 ) {
        $keyValues.Add( "APIURL", $apiData.URL )
        $keyValues.Add( "APIResponse", $apiData.Response )
        $keyValues.Add( "APIResultCount", $apiData.Results )
    }
    if ( $sqlData.Count -ne 0 ) {
        $keyValues.Add( "SQLCode", $sqlData.SQL )
        $keyValues.Add( "SQLResultCount", $sqlData.Rows )
    }
    if ( $isFail ) {
        $keyValues.Add( "IsFailure", '1' )
    }
    else {
        $keyValues.Add( "IsFailure", '0' )
    }
    Insert-OneRow $connDB $keyValues
}

# Pulls the data out of the data object using the structure passed and inserted to the tables using the passed mappings
function Insert-MappedData([System.Collections.ArrayList]$connDB,[int]$currentLevel,[System.Collections.ArrayList]$apiStruct,[string]$insertSQL,[string]$selectSQL,[System.Collections.ArrayList]$apiValues,[System.Collections.ArrayList]$logConn)
{
    # ConnDB[0] = server / [1] = DB for mapped data to go / [2] = (schema.)table for mapped data to go / [3] = DB where api process is kept / [4] = integration ID passed
    foreach ( $a in $apiValues[$currentLevel] )
    {
        # Clone the array and turn the current level to the result of the foreach at this level
        [System.Collections.ArrayList]$dataArray = @()
        $i = -1
        foreach ( $cln in $apiValues ) { if ( ++$i -eq $currentLevel ) { $dataArray.Add($a) } else { $dataArray.Add($cln) } }
        if ( ( $apiStruct.Count - 1 ) -eq $currentLevel )
        {
            $mappedData = @{}
            # Loop through mappings
            ForEach( $mapping in (Invoke-Sqlcmd -Query ("select * from dbo.IntegrationMappings where IntegrationID = " + ($connDB[4]) + " order by LevelID asc, ID asc;") -ServerInstance ($connDB[0]) -Database ($connDB[3]) ) ) {
                $tmpKey = $mapping.ColumnName
                # If the value contains periods, that means it needs to drill down through one or more levels, seperate from the main structure
                if ( ($mapping.KeyName).Contains(".") ) {
                    $lvl = $dataArray[$mapping.LevelID]
                    ($mapping.KeyName).Split(".") | foreach { $lvl = $lvl.$($_) }
                    if ( $lvl -is [string] -or $lvl -is [char] -or $lvl -is [xml] ) {
                        $tmpValue = $lvl.Replace("'","''")
                    }
                    else {
                        $tmpValue = $lvl
                    }
                }
                elseif ( $mapping.KeyName -eq "Array_Value" ) {
                    $tmpValue = ($dataArray[$mapping.LevelID]).Replace("'","''")
                }
                else {
                    # If value is text, strip out '
                    if ( $dataArray[$mapping.LevelID].$($mapping.KeyName) -is [string] -or $dataArray[$mapping.LevelID].$($mapping.KeyName) -is [char] -or $dataArray[$mapping.LevelID].$($mapping.KeyName) -is [xml] ) {
                        $tmpValue = ($dataArray[$mapping.LevelID].$($mapping.KeyName)).Replace("'","''")
                    }
                    else {
                        $tmpValue = ($dataArray[$mapping.LevelID].$($mapping.KeyName))
                    }
                }
                $mappedData.Add($tmpKey, $tmpValue)
            }
            # Call function to insert into SQL
            $infoSQL = Insert-OneRow $connDB $mappedData
            # Log query to table ( if required )
            if ( $infoSQL[1] -eq 0 ) {
                Insert-ExtractionLog $logConn "Failed to insert Mapped Row" -sqlData @{ "SQL" = ($infoSQL[0]).Replace("'","''"); "Rows" = "0" } -isFail $true
            }
            else {
                if ( ($logConn[4]).Contains("SQL") ) {
                    Insert-ExtractionLog $logConn "Inserted Mapped Row" -sqlData @{ "SQL" = ($infoSQL[0]).Replace("'","''"); "Rows" = ($infoSQL[1]).ToString() }
                }
            }
        }
        else
        {
            $dataArray.add($dataArray[$currentLevel].$($apiStruct[$currentLevel+1]))
            Insert-MappedData $connDB ($currentLevel+1) $apiStruct $insertSQL $selectSQL $dataArray $logConn
        }
    }
}

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

$serverName = "SERVER_NAME_GOES_HERE"          # Name of server where SQL DB is
$databaseName = "API_Extractions"              # Name of DB the information will be placed in
$loggingStyle = "API|SQL"                      # Verbosity setting for logging
                                                    # If contains API - Will log all API URLs and returns
                                                    # If contains SQL - Will log all SQL Queries and rows impacted
                                                    # Always records start/stop times of sections & errors

# logConn = [0] Server [1] DB [2] Table [3] Vendor Run ID [4] Logging Style [5] Vendor ID [6] API ID [7] Integration ID
$logConn = @( $serverName, $databaseName, "dbo.RunLog", ([guid]::NewGuid()).ToString(), $loggingStyle, 0, 0, 0 )

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Vendor Loop 
ForEach( $vendor in (Invoke-Sqlcmd -Query "select * from dbo.Vendors;" -ServerInstance $serverName -Database $databaseName) ) {
    # Log the run and put the Vendor Run ID in the log connection
    Insert-OneRow @($serverName, $databaseName, "dbo.RunList" ) @{ "ID" =  $logConn[3] }
    $logConn[5] = $vendor.ID
    Insert-ExtractionLog $logConn ("Started" )
    # Truncate all tables from this vendor
    ForEach( $dbDetails in (Invoke-Sqlcmd -Query ("select distinct DatabaseName, TableName from dbo.Integrations i inner join dbo.APIs a on i.APIID = a.ID where a.VendorID = " + $vendor.ID + ";") -ServerInstance $serverName -Database $databaseName) ) {
        $tmpSQL = "truncate table " + $dbDetails.TableName + ";"
        Invoke-Sqlcmd -Query $tmpSQL -ServerInstance $serverName -Database ($dbDetails.DatabaseName)
            if ( ($logConn[4]).Contains("SQL") ) {
            Insert-ExtractionLog $logConn ( $dbDetails.DatabaseName + "." + $dbDetails.TableName + " Table Truncated" ) -sqlData @{ "SQL" = $tmpSQL ; "Rows" = '0' }
        }
    }
    # API Loop
    ForEach( $api in (Invoke-Sqlcmd -Query ("select * from dbo.APIs where VendorID = " + $vendor.ID + ";") -ServerInstance $serverName -Database $databaseName) ) {
        $logConn[6] = $api.ID
        Insert-ExtractionLog $logConn ("Started" )
        # API Variable Prep
        $apiString = $api.APIString
        $apiReturnLimit = $api.APIReturnLimit
        $apiLimitObject = $api.ObjectToCount
        # Build in any parameters required
        ForEach( $param in (Invoke-Sqlcmd -Query ("select * from dbo.Params p inner join dbo.APIParams ap on p.ID = ap.ParamID where ap.APIID = " + $api.ID + " order by p.ID asc;") -ServerInstance $serverName -Database $databaseName) ) {
            if ( $param.ParamValueType -eq "value" ) {
                $apiString = $apiString + $param.ParamName + "=" + $param.ParamValue
            }
            else {
                $apiString = $apiString + $param.ParamName + "=" + ( Invoke-Expression -Command $param.ParamValue )
            }
        }
        # Header Prep
        $webGet = New-Object System.Net.WebClient
        ForEach( $header in (Invoke-Sqlcmd -Query ("select * from dbo.Headers h inner join dbo.APIHeaders ah on h.ID = ah.HeaderID where ah.APIID = " + $api.ID + " order by h.ID asc;") -ServerInstance $serverName -Database $databaseName) ) {
            $webGet.Headers.Add($header.HeaderName, $header.HeaderValue)
        }
        # Loop each extract if it returns 100 results
        $rowsFound = 0
        $rowsPulled = 0
        do {
            Insert-ExtractionLog $logConn ("Starting Set" )
            # If there is a row limit and a skip parameter, utilize these to iterate through the rowset
            if ( $apiReturnLimit -gt 0 -and $api.SkipParamName ) {
                $thisRun = $apiString + $api.SkipParamName + $rowsPulled
            }
            else {
                $thisRun = $apiString
            }
            # Try the extract and if get 429 back, pause for 1 minute
            $tooMany = 0
            do {
                try {
                    $rawresult = $webGet.DownloadString($thisRun)
                    $tooMany = 0
                }
                catch {
                    $exceptionMessage = $_.Exception.Message
                    # If the api is returning too many requests, wait 1 minute, then retry
                    if ( $exceptionMessage.EndsWith("(429) Too Many Requests.`"") ) {
                        Insert-ExtractionLog $logConn ("API URL Exception 429, Pausing Extraction" ) @{ "URL" = $thisRun; "Response" = $exceptionMessage ; "Results" = '0' }
                        Start-Sleep -s 60
                        $tooMany = 1
                    }
                    # Otherwise, log the error and move on
                    else {
                        # Logging will be reimplemented later...
                        Insert-ExtractionLog $logConn ("API URL Other Exception" ) @{ "URL" = $thisRun; "Response" = $exceptionMessage ; "Results" = '0' } -isFail $true
                        $tooMany = 0
                    }
                }
            } until ( $tooMany -eq 0 )
            # Prep the API Return & related counts
            $result = ConvertFrom-Json $rawresult
            $sqlsafeResult = $rawresult.Replace("'","''")
            if ( $apiLimitObject -eq "" ) {
                $rowsFound = $result.Count
            }
            else {
                $rowsFound = $result.$($apiLimitObject).Count
            }
            if ( $rowsFound -eq $null ) {
                $rowsFound = 1
            }
            $rowsPulled += $rowsFound
            if ( ($logConn[4]).Contains("API") ) {
                Insert-ExtractionLog $logConn ("API Result" ) @{ "URL" = $thisRun ; "Response" = $sqlsafeResult ; "Results" = $rowsFound.ToString() }
            }
            # Loop through Integrations
            ForEach( $integration in (Invoke-Sqlcmd -Query ("select * from dbo.Integrations where APIID = " + $api.ID + " order by ID asc;") -ServerInstance $serverName -Database $databaseName) ) {
                $logConn[7] = $integration.ID
                Insert-ExtractionLog $logConn ("Started" )
                # Set insert sql targets ( assumes same server as API_Extractions DB )
                $connDB = @( $serverName, $integration.DatabaseName, $integration.TableName, $databaseName, $integration.ID )
                # Build IntegrationLevels object for recursion handling
                $lastLevel = -1
                [System.Collections.ArrayList]$integrationLevels = @()
                $continue = 1
                ForEach( $integrationLevel in (Invoke-Sqlcmd -Query ("select * from dbo.IntegrationLevels where IntegrationID = " + $integration.ID + " order by LevelID asc;") -ServerInstance $serverName -Database $databaseName) ) {
                    # Check that the first level is zero and all subsequent levels are one from the last, otherwise log error and do not continue
                    if ( ( $integrationLevel.LevelID - 1 ) -eq $lastLevel ) {
                        $integrationlevels.add($integrationLevel.LevelName)
                        $lastLevel += 1
                    }
                    else {
                        Insert-ExtractionLog $logConn ("Levels are not sequential or do not start at zero ( " + $integrationLevel.LevelName + " )" ) -isFail $true
                        $continue = 0
                    }
                }
                if ( $continue -eq 1 ) {
                    # Recursively loop through all required Integration Levels and build the SQL string
                    Insert-MappedData $connDB 0 $integrationlevels "" "" $result $logConn
                }
            }
            Insert-ExtractionLog $logConn ( "Finished" )
            $logConn[7] = 0
            Insert-ExtractionLog $logConn ("$rowsPulled - $rowsFound" )
            # if no return limit was specified, force it to stop the loop
            if ( $apiReturnLimit -eq 0 ) {
                $rowsFound = -1
            }
        } while ( $rowsFound -ge $apiReturnLimit )
    }
    Insert-ExtractionLog $logConn ("Finished" )
    $logConn[6] = 0
}
Insert-ExtractionLog $logConn ("Finished" )
