########################################################################################
##### Script to parse a Yaml file and convert the key, value pairs to Powershell   #####
##### variables
########################################################################################
<#
    Current version:
        Version: 1.1
        Date:  January 12, 2021
                1-Changed:
                  The Powershell variables were hardcoded and only the values were used
                  from the yaml file. Now all keys from the yaml file are created as
                  Powershell variabeles with the value from the yaml file.
                  Now, multiple lists can exist in the yaml file, the list key will also
                  be created and translated to an array variabele.
                
        Update history:
        Version: 1.0
        Date:  January 11, 2021
                - Initial version
    
#>

$mariadbConfigFileContent = Get-Content -Path C:\powershell_scripts\mariadbConfig.yaml
#$mariadbConfigFileContent
$newVariableName = ""
$keyValueHash = @{}
foreach ($line in $mariadbConfigFileContent) {
    if ($line -notmatch "(^(---|#)|^\s*$)") {
        #write-host $line
        if ($line -match ":$") {
            if ($newVariableName.Length -ne 0) {
                $keyValueHash.$listKey = (Get-Variable -Name $newVariableName).Value
                Remove-Variable -name $newVariableName
                $newVariableName = ""
            }
            $listKey = ($line -replace ":").trim()
            $listValue = ""
            $keyValueHash.add($listKey,$listValue)
            New-Variable -Name "arr$listKey" -value @()
            $newVariableName = (Get-Variable -Name "arr$listKey").Name
        }
        elseif ($line -match "\s-") {
            $listValue = $null
            $listValue = ($line -split "-\s")[1] -replace ("'","")
            $VariableValue = @(((Get-Variable -Name $newVariableName).Value) + ($listValue))
            Set-Variable -Name $newVariableName -value $VariableValue
        }
        else {
            if ($newVariableName.Length -ne 0) {
                $keyValueHash.$listKey = (Get-Variable -Name $newVariableName).Value
                Remove-Variable -name $newVariableName
                $newVariableName = ""
            }
            $key,$value = ($line -split ":\s").trim() -replace ("'","")
            $keyValueHash.add($key,$value)
            #Write-Host "$key ## $($value.trim())"
        }
    }
    else {
        continue
    }
}


# print hash table
#$keyValueHash

######################
##### Variabelen #####
######################
foreach ($keyValuePair in $keyValueHash.GetEnumerator() ) {
   New-Variable -Name $($keyValuePair.Name) -value  $($keyValuePair.Value)
}



# print all variables
foreach ($keyValuePair in $keyValueHash.GetEnumerator() ) {
   Get-Variable -Name $($keyValuePair.Name)
}

