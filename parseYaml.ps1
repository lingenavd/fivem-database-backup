########################################################################################
##### Ophalen van de configuratie parameters voor het definieren van de variabelen #####
########################################################################################
<#
    Huidige versie:
        Versie: 1.1
        Datum:  12 januari 2021
                1-Aangepast:
                  De list vanuit de yaml file was eerst hardcoded, omdat er maar 1 list
                  in de yaml file stond en deze in het script hardcoded naar de $mailto
                  variabele werd vertaald.
                  Dat is nu niet meer nodig, alle list keys worden nu ook als variabele
                  aangemaakt.
                  Nu kunnen er meerdere lists in de yaml file voorkomen en de list key
                  wordt automatisch vertaald naar een array variabele.
                
        Update geschiedenis:
        Versie: 1.0
        Datum:  11 januari 2021
                - Initiele versie
    
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

