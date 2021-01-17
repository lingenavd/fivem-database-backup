#########################################################################################
##### Script om de FiveM datafolder en resources te doorlopen                       #####
##### De foldernaam en de diskusage in MB wordt weergegeven                         #####
#########################################################################################
<#
    Huidige versie:

        Versie: 1.0
        Datum:  15 januari 2021
                - Initiele versie
#>

$MultipleFoldersToParse = ("D:\FXServer\server-data", "D:\FXServer\server-data\resources")
"server-data:"
foreach ($folderToParse in $MultipleFoldersToParse) {
    Set-Location -Path $folderToParse

    $allFolders = Get-ChildItem | Where-Object { $_.PSIsContainer }

    ForEach ($folder in $allFolders) {
        $foldersize = [math]::Ceiling((Get-ChildItem -LiteralPath $folder.FullName -Include * -Recurse | Measure-Object Length -Sum).Sum / 1MB)
        $folder.Name + ": " + $foldersize + " MB"
    }
}
