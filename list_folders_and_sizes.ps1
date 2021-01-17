#########################################################################################
##### Script to parse the FiveM data and resource folders                           #####
##### The folder name and diskusage will be printed on the screen                   #####
#########################################################################################
<#
    Current version:

        Versie: 1.0
        Date:  January 15, 2021
                - Initial version
#>

#change this list with the folders you want to parse
$MultipleFoldersToParse = ("D:\FXServer\server-data", "D:\FXServer\server-data\resources")

foreach ($folderToParse in $MultipleFoldersToParse) {
    Set-Location -Path $folderToParse

    $allFolders = Get-ChildItem | Where-Object { $_.PSIsContainer }

    ForEach ($folder in $allFolders) {
        $foldersize = [math]::Ceiling((Get-ChildItem -LiteralPath $folder.FullName -Include * -Recurse | Measure-Object Length -Sum).Sum / 1MB)
        $folder.Name + ": " + $foldersize + " MB"
    }
}
