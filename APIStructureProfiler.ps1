# Functions written to profile an data object, primarily for use with API responses

function Prep-APIStructureParse ([System.Collections.Hashtable]$structHash,[System.String]$apiResponse) {
    <#
        .SYNOPSIS
            This function takes a hash and adds the structure from the passed api response string to it
        .EXAMPLE
            [System.Collections.Hashtable]$myHash = @{}
            [System.String]$jsonString = '{"menu": {"id": "file","value": "File","popup": {"menuitem": [{"value": "New", "onclick": "CreateNewDoc()"},{"value": "Open", "onclick": "OpenDoc()"},{"value": "Close", "onclick": "CloseDoc()"}]}}}'
            Profile-API $myHash $jsonString
        .PARAMETER structHash
            Function will put the api structure into a sub-hash with a key of the full path to the object
        .PARAMETER apiResponse
            Function expects a valid json string to be passed
        .RETURNS
            No explicit return, the $structHash is passed by reference and updated
        .AUTHOR
            Mike Morris | 2017-12-12
        .CHANGELOG
            Mike Morris | 2017-12-12 | Initial Build
    #>
    Parse-APIStructure ( $apiResponse | ConvertFrom-Json ) $structHash 0 "" "API Response" "API Response"
}

function Parse-APIStructure ($inputData,[System.Collections.Hashtable]$dataStruct,[System.Int32]$levelID,[System.String]$parentKey,[System.String]$currentKey,[System.String]$itemPath) {
    <#
        .SYNOPSIS
            This recursive function loops through the structure inside a data structure
        .EXAMPLE
            See Profile-API function
        .PARAMETER inputData
            Data object that needs to be parsed and logged
        .PARAMETER dataStruct
            Hash table where structure is logged
        .PARAMETER levelID
            # of levels deep in structure.  Each time an object is found, this will be incremented
        .PARAMETER parentKey
            Name of object above the current object
        .PARAMETER currentKey
            Name of the current object
        .PARAMETER itemPath
            Full text of entire object path up to and including the current object
        .RETURNS
            No explicit return, the $structHash is passed by reference and updated
        .AUTHOR
            Mike Morris | 2017-12-12
        .CHANGELOG
            Mike Morris | 2017-12-12 | Initial Build
    #>
    # if no value, set data type to default message
    if ( $inputData -eq $null ) { $dataType = "No value for property" }
    else { $dataType = ($inputData.GetType()).ToString() }
    # Log the passed object
    Write-APIStructure $dataStruct $levelID $parentKey $currentKey $dataType $itemPath
    # Check to see if drill down is needed
    if ( $dataType.contains("PSCustomObject") ) { # Dictionary
        foreach ( $b in ( $inputData | Get-Member -MemberType *Property).Name ) {
            # Recursively log each item
            Parse-APIStructure $inputData.$b $dataStruct ( $levelID + 1 ) $currentKey $b "$itemPath.$b"
        }
    }
    elseif ( $dataType.contains("Object[]") ) { # Array
        foreach ( $a in $inputData ) {
            # Recursively log each item
            Parse-APIStructure $a $dataStruct ( $levelID + 1 ) $currentKey ("Item[]")  "$itemPath.Item[]"
        }
    }
}

# Function that builds the specific structure hash and ensures no duplicates are added
function Write-APIStructure ([System.Collections.Hashtable]$baseHash,[System.Int32]$levelID,[System.String]$parentKey,[System.String]$currentKey,[System.String]$currentType,[System.String]$itemPath) {
    <#
        .SYNOPSIS
            This function logs the structure level to the hash.  All data profiling of the data structure is tracked here.
        .EXAMPLE
            See the Parse-Structure function for an example
        .PARAMETER baseHash
            This is the hash that the structure will be logged to
        .PARAMETER levelID
            This is the level of the structure item to be logged
        .PARAMETER parentKey
            This is the parent of the structure item to be logged
        .PARAMETER currentKey
            This is the structure item to be logged.
        .PARAMETER currentType
            This is the powershell data type of the item to be logged
        .PARAMETER itemPath
            This is the complete path of the structure item to be logged.  This is the primary key for each row of the hash.
        .RETURNS
            No explicit return, the $structHash is passed by reference and updated
        .AUTHOR
            Mike Morris | 2017-12-12
        .CHANGELOG
            Mike Morris | 2017-12-12 | Initial Build
    #>
    if ( $currentType -eq "No value for property" ) { $nulls = 1 }
    else { $nulls = 0 }
    # If level added before, check type and, if different, append new one to end
    if ( ( $baseHash.GetEnumerator() | % { $_.Key } ) -eq $itemPath ) {
        if ( -not ($baseHash[$itemPath].type).Contains($currentType) ) { $baseHash[$itemPath].type = $baseHash[$itemPath].type + ", " + $currentType }
        # Basic Profiling on subsequent finds
        $baseHash[$itemPath].stats.occurences += 1 # How many times the item was found
        $baseHash[$itemPath].stats.nulls += $nulls # How many times the item contained a null value
    }
    else {
        # Profiling setup is done in the stats property at the end
        $baseHash.Add($itemPath, @{ "level" = $levelID; "parent" = $parentKey; "key" = $currentKey; "type" = $currentType; "path" = $itemPath; "stats" = @{ "occurences" = 1; "nulls" = $nulls } } ) > $null
    }
}

function Write-SQL-Profiles ([System.Collections.Hashtable]$structHash,[System.Collections.Hashtable]$connDB) {
    <#
        .SYNOPSIS
            This function uses a structure hash built from the Parse & Capture Structure functions to log to SQL.  The stats are ignored in this function.
        .EXAMPLE
            $structHash = @{"API Result" = @{"level" = 0; "parent" = ""; "key" = "API Result"; "type" = "System.Management.Automation.PSCustomObject"; "path" = "API Result"}}
            $connDB = @{"server" = "SERVER_NAME_HERE"; "db" = "API_Extractions"; "apiid" = 1}
            Log-Structure $structHash $connDB
        .PARAMETER structHash
            The hashtable to be put into SQL.  The format is explained above in the example and in the Capture-Structure function.
        .PARAMETER connDB
            The hashtable controlling the SQL connection.  It must have at minimum a server, db, and apiid keys.  See example above.
        .RETURNS
            [0] = True / False
            [1] = Text
                If hashtable is empty, passes back false and a message
                If SQL ran successfully, passes back true and the SQL that was used
                If SQL failed, passes back false and the SQL that was used
        .AUTHOR
            Mike Morris | 2017-12-12
        .CHANGELOG
            Mike Morris | 2017-12-12 | Initial Build
    #>
    # If structure hash table has no rows, stop and return false
    if ( $structHash.Count -lt 1 ) { return $false, "Hashtable is Empty" }
    # Insert Profile Results
    $sqlPrefix = "
        MERGE api.Profiles AS T
        USING ( SELECT " + $connDB.apiid + " as APIID, s.* FROM ( VALUES "
    $sqlSuffix = "
        ) AS s ( LevelID, ItemPath, ParentKeyName, KeyName, ValueTypes ) ) AS S
        ON ( T.APIID = S.APIID AND T.ItemPath = S.ItemPath )
        WHEN MATCHED THEN
            UPDATE SET T.LevelID = S.LevelID, T.ParentKeyName = S.ParentKeyName, T.KeyName = S.KeyName, T.ValueTypes = S.ValueTypes, T.LastModifiedDate = CASE WHEN T.ValueTypes <> S.ValueTypes OR T.KeyName <> S.KeyName OR T.ParentKeyName <> S.ParentKeyName OR T.LevelID <> S.LevelID OR T.IsActive = 0 THEN GETDATE() ELSE T.LastModifiedDate END, T.LastCheckedDate = GETDATE(), T.IsActive = 1
        WHEN NOT MATCHED BY TARGET THEN
            INSERT ( APIID, LevelID,ItemPath, ParentKeyName, KeyName, ValueTypes ) VALUES ( S.APIID, S.LevelID, S.ItemPath, S.ParentKeyName, S.KeyName, S.ValueTypes )
        WHEN NOT MATCHED BY SOURCE AND T.APIID = " + $connDB.apiid + " THEN
            UPDATE SET T.LastModifiedDate = GETDATE(), T.LastCheckedDate = GETDATE(), T.IsActive = 0;"
    $sqlValues = ""
    foreach ( $row in $structHash.GetEnumerator() ) {
        if ( $sqlValues -ne "" ) { $sqlValues = ($sqlValues + ", ") }
        $sqlValues = ( $sqlValues + "( " + $structHash.($row.Key).level + ", '" + $structHash.($row.Key).path + "', '" + $structHash.($row.Key).parent + "', '" + $structHash.($row.Key).key + "', '" + $structHash.($row.Key).type + "' )" )
    }
    $allSQL = ( $sqlPrefix + $sqlValues + $sqlSuffix )
    Write-Host $allSQL
    try {
        Invoke-Sqlcmd -Query $allSQL -ServerInstance ($connDB.server) -Database ($connDB.db) -MaxCharLength ([int]::MaxValue) -QueryTimeout ([int]::MaxValue)
        return $true, $allSQL # SQL Used
    }
    catch {
        return $false, $allSQL # Flag that nothing was inserted and pass SQL that was attempted
    }
}

function Write-SQL-ProfileStats ([System.Collections.Hashtable]$structHash,[System.Collections.Hashtable]$connDB) {
    <#
        .SYNOPSIS
            This function uses a structure hash built from the Parse & Capture Structure functions to log to SQL.  It primarily uses the stats key.  It uses the path to link back to the profile table.
        .EXAMPLE
            $structHash = @{"API Result" = @{"level" = 0; "parent" = ""; "key" = "API Result"; "type" = "System.Management.Automation.PSCustomObject"; "path" = "API Result"; "stats" = @{"occurences" = 1; "nulls" = 0}}}
            $connDB = @{"server" = "SERVER_NAME_HERE"; "db" = "API_Extractions"; "apiid" = 1}
            Log-StructureStats $structHash $connDB
        .PARAMETER structHash
            The hashtable to be put into SQL.  The format is explained above in the example and in the Capture-Structure function.
        .PARAMETER connDB
            The hashtable controlling the SQL connection.  It must have at minimum a server, db, and apiid keys.  See example above.
        .RETURNS
            [0] = True / False
            [1] = Text
                If hashtable is empty, passes back false and a message
                If SQL ran successfully, passes back true and the SQL that was used
                If SQL failed, passes back false and the SQL that was used
        .AUTHOR
            Mike Morris | 2017-12-12
        .CHANGELOG
            Mike Morris | 2017-12-12 | Initial Build
    #>
    # If structure hash table has no rows, stop and return false
    if ( $structHash.Count -lt 1 ) { return $false, "Hashtable is Empty" }
    # Insert Profile Stat Results
    $sqlPrefix = "
        MERGE api.ProfileStats AS T
        USING ( SELECT * FROM ( "
    $sqlSuffix = " ) a ) AS S
        ON ( T.APIID = S.APIID AND T.ProfileID = S.ProfileID AND T.MetricName = S.MetricName )
        WHEN MATCHED THEN
            UPDATE SET T.Metric = S.Metric, T.LastModifiedDate = CASE WHEN T.Metric <> S.Metric OR T.IsActive = 0 THEN GETDATE() ELSE T.LastModifiedDate END, T.LastCheckedDate = GETDATE(), T.IsActive = 1
        WHEN NOT MATCHED BY TARGET THEN
            INSERT ( APIID, ProfileID, MetricName, Metric ) VALUES ( S.APIID, S.ProfileID, S.MetricName, S.Metric )
        WHEN NOT MATCHED BY SOURCE AND T.APIID = " + $connDB.apiid + " THEN
            UPDATE SET T.LastModifiedDate = GETDATE(), T.LastCheckedDate = GETDATE(), T.IsActive = 0;"
    $sqlValues = ""
    foreach ( $row in $structHash.GetEnumerator() ) {
        foreach ( $stat in $structHash.($row.Key).stats.GetEnumerator() ) {
            if ( $sqlValues -ne "" ) { $sqlValues = ($sqlValues + " UNION ALL ") }
            $sqlValues = ( $sqlValues + "SELECT " + $connDB.apiid + " AS APIID, ID AS ProfileID, '" + $stat.Key + "' AS MetricName, " + $structHash.($row.Key).stats.($stat.Key) + " AS Metric FROM api.Profiles WHERE APIID = " + $connDB.apiid + " AND ItemPath = '" + $structHash.($row.Key).path + "'" )
        }
    }
    $allSQL = ( $sqlPrefix + $sqlValues + $sqlSuffix )
    try {
        Invoke-Sqlcmd -Query $allSQL -ServerInstance ($connDB.server) -Database ($connDB.db) -MaxCharLength ([int]::MaxValue) -QueryTimeout ([int]::MaxValue)
        return $true, $allSQL # SQL Used
    }
    catch {
        return $false, $allSQL # Flag that nothing was inserted and pass SQL that was attempted
    }
}