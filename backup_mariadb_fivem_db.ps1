#########################################################################################
##### Script om automatische backups te maken van de FiveM database in MariaDB 10.4 #####
##### MariaDB server properties and credentials                                     #####
#########################################################################################
<#
    Huidige versie:
        Versie: 1.3
        Datum:  15 januari 2021
                1-Configuratie parameter bestand "C:\powershell_scripts\mariadbConfig.yaml" uitgebreid met key,
                  value pairs voor de benodigde mysqldump command-line parameters
                2-Nieuw blok: # aanmaken van een credentials object voor de sessie naar MariaDB #
                3-Aangepast blok: # parameters die gebruikt worden bij het uitvoeren van het mysqldump.exe programma #
                  Omdat nu ook het ww van de MariaDB sessie is encrypt, wordt er geen gebruik meer gemaakt van een
                  apart "mariadb.cnf" bestand, maar zijn de configuratie parameters uit dat bestand opgenomen in het
                  configuratie parameter bestand "mariadbConfig.yaml". Hierdoor zijn de config parameters ook toe-
                  gevoegd aan de mysqldump command-line parameters
                4-Configuratie parameter bestand "mariadb.cnf" verwijderd.
                5-Aangepast blok: # !! Onderstaande dient vooraf eenmalig, met de hand worden aangemaakt !! #
                  Uitleg mariadb.cnf verwijderd en uitleg mariadbConfig.yaml toegevoegd
                  Beschrijving toegevoegd voor het eenmalig aanmaken ban het encrypte wachtwoord bestand voor
                  de sessie naar MariaDB.
                
        Update geschiedenis:
        Versie: 1.2
        Datum:  13 januari 2021
                1-Aangepast blok: # verzamel alle bestandsnamen van de archive (rar) bestanden #
                  Er stond nog een harde databse naam in de script regel, i.p.v. de variabele die de database
                  naam bevat. Dir resulteerde er in dat het oudste archive bestand niet werd verwijderd.
                2-Aangepast blok: # verzamel alle bestandsnamen van de database backup bestanden #
                  Er stond nog een harde databse naam in de script regel, i.p.v. de variabele die de database
                  naam bevat. Dir resulteerde er in dat het oudste database backup (.sql) bestand niet werd
                  verwijderd.
                3-Aangepast blok: # mail het archive bestand #
                  De arhcief mail voorzien van een eigen subject en body voor in de mail.

        Versie: 1.1
        Datum:  12 januari 2021
                1-Aangepast blok: # !! Onderstaande dient vooraf eenmalig, met de hand worden aangemaakt !! #
                  Beschrijving toegevoegd voor het eenmalig aanmaken ban het encrypte wachtwoord bestand voor
                  het Google -mail- account.
                2-Aangepast blok: # Ophalen van de configuratie parameters voor het definieren van de variabelen #
                  Variabelen niet meer hardcoded opgenomen, variabelen worden nu aangemakt op basis van de
                  key-naam in het bestand "C:\powershell_scripts\mariadbConfig.yaml"
                  De key-namen in het bestand "C:\powershell_scripts\mariadbConfig.yaml" moeten dus NIET worden
                  aangepast, omdat anders het Powershell script niet meer werkt omdat het script wel de key-namen
                  als de naam van de variabele verwacht.
                3-Aangepast blok: # aanmaken van een credentials object voor het versturen van mail #
                  Het wachtwoord bestand $emailPwdFile dient nu vooraf eenmalig met de hand worden aangemaakt als
                  een encrypt wachtwoord bestand. Zie ook punt 1 van de aanpassingen in versie 1.1.

        Versie: 1.0
        Datum:  11 januari 2021
                - Initiele versie
#>


<#
    ###################################################################################
    ##### !! Onderstaande dient vooraf eenmalig, met de hand worden aangemaakt !! #####
    ###################################################################################
    
    #####################################################################################
    Maak vooraf een nieuwe READONLY user aan in de MariaDB server voor het backup proces
    met onderstaande SQL query commando:
    GRANT LOCK TABLES, SELECT ON *.* TO 'backupuser'@'%' IDENTIFIED BY 'Ti@nReadOnlyAccount!';

    
    #####################################################################################
    Vul vooraf het onderstaande configuratie parameter bestand in:
    C:\powershell_scripts\mariadbConfig.yaml

    (in een toekomstige versie zal dit bestand met een vraag en antwoorden reeks worden
    aangemaakt)
    
    #####################################################################################
    Maak vooraf een ge-encrypt wachtwoord bestand aan voor het Google -mail- account

    Just like the Windows Task Scheduler, this method will encrypt using the Windows
    Data Protection API, which also means we fall into the same limitations of only
    being able to access the password file with one account and only on the same
    device that created the password file.
    The user login credentials are essentially the key to the password file.
    However, this method allows us to save multiple passwords and reference them in
    our script.
    
    Start onderstaande Powershell regels om het wachtwoord bestand aan te maken
    Er wordt gevraagd om de user en password gegevens.

    $emailPwdFile = "C:\powershell_scripts\emailbu.pwd"
    (get-credential).password | ConvertFrom-SecureString | set-content $emailPwdFile

    #####################################################################################
    Maak vooraf een ge-encrypt wachtwoord bestand aan voor de sessie naar MariaDB 

    Start onderstaande Powershell regels om het wachtwoord bestand aan te maken
    Er wordt gevraagd om de user en password gegevens.

    $dbPwdFile = "C:\powershell_scripts\mariadb.pwd"
    (get-credential).password | ConvertFrom-SecureString | set-content $dbPwdFile

    
    maak onderstaande bestanden beide hidden in de Windows file explorer
    - C:\powershell_scripts\mariadb.pwd
    - C:\powershell_scripts\emailbu.pwd

#>

########################################################################################
##### Ophalen van de configuratie parameters voor het definieren van de variabelen #####
########################################################################################
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

<#
# print all variables
foreach ($keyValuePair in $keyValueHash.GetEnumerator() ) {
   Get-Variable -Name $($keyValuePair.Name)
}
#>


#######################
##### MAIN script #####
#######################

# als het bestand "backupCounter.log" niet bestaat, wordt het aangemaakt
# dit bestand wordt gebruikt om te tellen wanneer een nieuwe archive (rar) file moet worden aangemaakt
if (Test-Path -Path $backupCounterLogFile) {
    $backupCounterContent = Get-Content -Path $backupCounterLogFile
    $backupCounter = [int]$backupCounterContent
}
else {
    $backupCounter = 0
    $backupCounter | Out-File -FilePath $backupCounterLogFile
}


# aanmaken van een credentials object voor het versturen van mail
$emailPwd = Get-Content $emailPwdFile | ConvertTo-SecureString
$mailCreds = New-Object System.Management.Automation.PsCredential($emailUsr,$emailPwd)

# aanmaken van een credentials object voor de sessie naar MariaDB
$dbEncPwd = Get-Content $dbPwdFile | ConvertTo-SecureString
$dbCreds = New-Object System.Management.Automation.PsCredential($dbUser,$dbEncPwd)
$dbPwd = (New-Object PSCredential($dbUser,$dbEncPwd)).GetNetworkCredential().Password

# Datum van vandaag
$timestamp = "$(Get-Date -UFormat "%d")-$(Get-Date -UFormat "%m")-$(Get-Date -UFormat "%Y")_$(Get-Date -UFormat "%H")$(Get-Date -UFormat "%M")"
#Write-Host $timestamp

# bestandsnamen voor de backup-file en het archive bestand samenstellen
$backupFile = $backuppath + "\" + $database + "_" + $timestamp +".sql"
$backupRar = $backuppath + "\" + $database + "_" + $timestamp +".rar"

# parameters die gebruikt worden bij het uitvoeren van het mysqldump.exe programma
$mysqldumpParameters = "--host=$dbHost --protocol=$dbSocket --port=$dbPort --user=$dbUser --password=$dbPwd --log-error=$errorLog --result-file=$backupFile --databases $database"

# Create backup
Start-Process -FilePath "$mariadbPath\mysqldump.exe" -ArgumentList $mysqldumpParameters -ErrorAction:SilentlyContinue -Wait:$true

# Check succesfull backup
$lastLineInMysqlDumpFile = Get-Content $backupfile -Tail 1 -ErrorAction:SilentlyContinue
$mysqldumpErrorLog = Get-Content $errorLog -ErrorAction:SilentlyContinue
#$lastLineInMysqlDumpFile
#$mysqldumpErrorLog.length
if ($lastLineInMysqlDumpFile -imatch "Dump completed" -and $mysqldumpErrorLog.length -eq 0) {
    #Write-Host "Backup MySQL Success"
    $backupCounter ++
    $backupCounter | Out-File -FilePath $backupCounterLogFile
    $mailSubject = "Backup MariaDB succesvol"
    $mailBody = "Backup voor de FiveM MariaDB database is nu voor de $backupCounter -de keer gelukt."
    Send-MailMessage -to $mailTo -From $mailFrom -Subject $mailSubject -Body $mailBody -SmtpServer $smtpServer -port $smtpPort -UseSsl -Credential $mailCreds
}
else {
    #Write-Host "Backup MySQL Failed"
    $mailSubject = "Backup MariaDB failed with errors"
    $mailBody = "Backup voor de FiveM MariaDB database is gefaald, zie bijgevoegd bestand voor de error log."
    Send-MailMessage -to $mailTo -From $mailFrom -Subject $mailSubject -Body $mailBody -SmtpServer $smtpServer -port $smtpPort -UseSsl -Credential $mailCreds -Attachments $errorLog
}


# verzamel alle bestandsnamen van de archive (rar) bestanden
$allRarFiles = Get-ChildItem -Path "$backuppath\$database*.rar"

# archive and mail een nieuw archive bestand met alle backup files die tot nu toe zijn gemaakt
# het aantal backups in het archive bestand is afhankelijk van het aantal dat bewaard dient te blijven
# de variable $numberofBackupsToKeep geeft dat aantal aan
if ($backupCounter -ge $numberofBackupsToKeep) {

    # verwijder eerst het oude archive bestand
    foreach ($rarFile in $allRarFiles) {
        Remove-Item -Path "$backuppath\$($rarFile.name)"
    }

    # parameters die gebruikt worden bij het uitvoeren van het rar.exe programma
    $winrarParameters = "a $backupRar $backupPath"
    
    # Create archive bestand
    Start-Process -FilePath "$winrarPath\rar.exe" -ArgumentList $winrarParameters -ErrorAction:SilentlyContinue -Wait:$true
    
    # zet de teller weer op nul
    $backupCounter = 0
    $backupCounter | Out-File -FilePath $backupCounterLogFile
    
    # mail het archive bestand
    $mailSubject = "Archief bestand met de laatste $numberofBackupsToKeep database backup files"
    $mailBody = "Archief bestand met de laatste $numberofBackupsToKeep database backup files is toegevoegd aan deze mail als bijlage."
    Send-MailMessage -to $mailTo -From $mailFrom -Subject $mailSubject -Body $mailBody -SmtpServer $smtpServer -port $smtpPort -UseSsl -Credential $mailCreds -Attachments $backupRar
}


# verzamel alle bestandsnamen van de database backup bestanden
$allBackupFiles = Get-ChildItem -Path "$backuppath\$database*.sql"
$allBackupFilesSorted = $allBackupFiles | Sort-Object -Property CreationTime -Descending
$numberOfBackupFiles = $allBackupFilesSorted.count
#Write-Host $allBackupFilesSorted


# Als er meer database backup bestanden bestaan dan dat er bewaard dienen te worden,
# dan wordt het oudste backup bestand (.sql) verwijderd
if ($allBackupFilesSorted.count -ge $numberofBackupsToKeep) {
    for ($i=$numberOfBackupFiles-1; $i -le $numberOfBackupFiles-1; $i++) {
        $fileToBeDeleted = "$backuppath" + "\" + "$($allBackupFilesSorted[$i].name)"
        #write-host $fileToBeDeleted
        Remove-Item -Path $fileToBeDeleted
    }
}
