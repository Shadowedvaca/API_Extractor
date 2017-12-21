# Generic functions the can be utilized if needed

# Function that calls an API and returns the string
function Get-APIResponse([System.String]$apiURL,[System.Collections.Hashtable]$headersReqd) {
    $webGet = New-Object System.Net.WebClient
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    # If function was called with headers, add them
    foreach ( $header in $headersReqd.GetEnumerator() ) { $webGet.Headers.Add( $header.Key, $header.Value ) > $null }
    $tooMany = 0
    do {
        try { $apiResponse = $webGet.DownloadString($apiURL) }
        catch {
            $exceptionMessage = $_.Exception.Message
            if ( $exceptionMessage.EndsWith("(429) Too Many Requests.`"") ) {
                Start-Sleep -s 60
                $tooMany = 1
            }
            else { return $false, $exceptionMessage }
        }
    } until ( $tooMany -eq 0 )
    return $true, $apiResponse
}

# Function that adds a various number of items to a passed hashtable ( against a key if passed )
function Write-Hash ([System.Collections.Hashtable]$baseHash,[System.String]$keyStr) {
    if ( $args.Count -lt 2 ) { return $false }
    else {
        for ( $a = 0; $a -lt $args.Count; $a += 2 ) {
            # if no key passed
            if ( $keyStr -eq "" -or $keyStr -eq $null ) { $baseHash.Add($args[$a],$args[$a+1]) > $null }
            # if key passed
            else {
                if ( $a -eq 0 ) { $baseHash.Add($keyStr, @{}) > $null }
                $baseHash[$keyStr].Add($args[$a]. $args[$a+1]) > $null
            }

        }
        return $true
    }
}

# Writes data to SQL from a hash table
function Write-SQL ([System.Collections.Hashtable]$connDB,[System.Collections.ArrayList]$valueList,[System.Collections.ArrayList]$keyList) {
    # No Values passed, stop
    if ( $valueList.Count -eq 0 ) { return $false, "Hashtable is Empty" }
    # No Keys passed, assume keys from first row of value hash
    if ( $keyList.Count   -eq 0 ) {
        [System.Collections.ArrayList]$keyList = @()
        $valueList[0].GetEnumerator() | ForEach-Object { $keyList.Add($_.Key) > $null }
    }
    # Prep Insert portion of SQL
    $insertSQL = "INSERT INTO " + $connDB.table + " ( "
    ForEach ( $key in $keyList ) { $insertSQL = $insertSQL + $key + ", " }
    $insertSQL = $insertSQL.Substring(0,$insertSQL.Length - 2) + " ) "
    # Prep Value portion of SQL
    $valuesSQL = "VALUES "
    ForEach ( $row in $valueList ) {
        $valuesSQL = $valuesSQL + "( "
        ForEach ( $key in $keyList ) {
            $tmpVal = $row.$key
            if ( $tmpVal -eq $null )                                                     { $valuesSQL = $valuesSQL + "'', "                }
            elseif ( $tmpVal -is [boolean] )                                             { $valuesSQL = $valuesSQL + "'" + $tmpVal + "', " }
            elseif ( $tmpVal -is [datetime] )                                            { $valuesSQL = $valuesSQL + "'" + $tmpVal + "', " }
            elseif ( $tmpVal -is [string] -or $tmpVal -is [char] -or $tmpVal -is [xml] ) { $valuesSQL = $valuesSQL + "'" + $tmpVal + "', " }
            else                                                                         { $valuesSQL = $valuesSQL + $tmpVal + ", "        }
            Remove-Variable 'tmpVal'
        }
        $valuesSQL = $valuesSQL.Substring(0,$valuesSQL.Length - 2) + " ), "
    }
    $valuesSQL = $valuesSQL.Substring(0,$valuesSQL.Length - 2) + ";"
    # Execute SQL Strings together
    try {
        Invoke-Sqlcmd -Query ( $insertSQL + $valuesSQL ) -ServerInstance ($connDB.server) -Database ($connDB.db) -MaxCharLength ([int]::MaxValue) -QueryTimeout ([int]::MaxValue)
        return $true, ($insertSQL + $valuesSQL ) # successful result
    }
    # sql failed result
    catch { return $false, ( $insertSQL + $valuesSQL ) }
}
