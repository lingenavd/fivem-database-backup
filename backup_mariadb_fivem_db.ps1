#########################################################################################
##### Script to create automated backups and notifications for your FiveM database  #####
##### in MariaDB 10.4. 
#########################################################################################
<#
    Current version:
        Version: 1.4
        Date:  February 2, 2021
                1-Changed block: # Check succesfull backup #
                  After a failed database backup the errolog file was not removed. This will result
                  in getting only failed database backup mail, even if the database backup was successful.
                  Added code to remove the errorlog file after it was attached to the fail mail.
        Version: 1.3
        Date:  January 15, 2021
                1-Added the key value/pairs necessary for the mysqldump command-line parameters to
                  connect to the MariaDB database in the configuration parameter file
                  "C:\powershell_scripts\mariadbConfig.yaml"
                2-New block: # create credential object for the MariaDB session#
                3-Changed block: # mysqldump.exe command-line parameters #
                  Removed the use of the native "mariadb.cnf" file because password was unencrypted.
                  The configuration parameter file "mariadbConfig.yaml" is extended (see 1).
                4-Removed the native "mariadb.cnf" file.
                5-Changed block: # How to install / use: #
                  Removed the explanation for the "mariadb.cnf" file.
                  Added the explanation for the "mariadbConfig.yaml" file.
                  Added the explanation to create the encrypted password file for the MariaDB connection.
                
        Update history:
        Version: 1.2
        Date:  January 13, 2021
                1-Changed block: # get all names for the existing archive (rar) files #
                  Replaced the hardcoded database name into the database name variable.
                  This was the root cause of the problem that the last archve file (.rar) was not
                  deleted. 
                2-Changed block: # get all names for the existing database backup (.sql) files #
                  Replaced the hardcoded database name into the database name variable.
                  This was the root cause of the problem that the last database backup file (.sql)
                  was not deleted. 
                3-Changed block: # mail archive file #
                  Added subject en body variables for the mail.

        Version: 1.1
        Date:  January 12, 2021
                1-Changed block: # How to install / use: #
                  Added the explanation to create the encrypted password file for the -mail- connection.
                2-Changed block: # read all key/value pairs from yaml file to create variables #
                  Variabeles are not defined in this script but based on the key/value pairs in the
                  configuration parameter file "C:\powershell_scripts\mariadbConfig.yaml"
                3-Changed block: # create credential object for mail connection#
                  See aslo point 1.

        Version: 1.0
        Date:  January 11, 2021
                - Initial version
#>


<#
    # How to install / use: #
    
    1 - Before first use: Create a READONLY user in the MariaDB server for the backup proces
        with the following SQL query command:
        GRANT LOCK TABLES, SELECT ON *.* TO 'your_backup_user'@'%' IDENTIFIED BY 'yoursecret_password';        
    2 - Before first use: Change the configuration parameter file with your values:
        C:\powershell_scripts\mariadbConfig.yaml
    3 - Before first use: Create an encrypt password file for the Google -mail- account
        Start the following Powershell command lines to create the password file, you will
        be prompted for username and password.
        $emailPwdFile = "C:\powershell_scripts\emailbu.pwd"
        (get-credential).password | ConvertFrom-SecureString | set-content $emailPwdFile
    4 - Before first use: Create an encrypt password file for the connection to the MariaDB
        server database.
        Start the following Powershell command lines to create the password file, you will
        be prompted for username and password.
        $dbPwdFile = "C:\powershell_scripts\mariadb.pwd"
        (get-credential).password | ConvertFrom-SecureString | set-content $dbPwdFile
    5 - Before first use: Hide the following files in the Windows file explorer
        - C:\powershell_scripts\mariadb.pwd
        - C:\powershell_scripts\emailbu.pwd

#>

########################################################################################
##### read all key/value pairs from yaml file to create variables                  #####
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

# if the file "backupCounter.log" does not exist it will be created
# this file is used to count the number of successful database backup and when to create
# a new archive (rar) file
if (Test-Path -Path $backupCounterLogFile) {
    $backupCounterContent = Get-Content -Path $backupCounterLogFile
    $backupCounter = [int]$backupCounterContent
}
else {
    $backupCounter = 0
    $backupCounter | Out-File -FilePath $backupCounterLogFile
}


# create credential object for the mail connection
$emailPwd = Get-Content $emailPwdFile | ConvertTo-SecureString
$mailCreds = New-Object System.Management.Automation.PsCredential($emailUsr,$emailPwd)

# create credential object for the MariaDB connection
$dbEncPwd = Get-Content $dbPwdFile | ConvertTo-SecureString
$dbCreds = New-Object System.Management.Automation.PsCredential($dbUser,$dbEncPwd)
$dbPwd = (New-Object PSCredential($dbUser,$dbEncPwd)).GetNetworkCredential().Password

# Date of today
$timestamp = "$(Get-Date -UFormat "%d")-$(Get-Date -UFormat "%m")-$(Get-Date -UFormat "%Y")_$(Get-Date -UFormat "%H")$(Get-Date -UFormat "%M")"
#Write-Host $timestamp

# create the file name for the backup- and the archive files
$backupFile = $backuppath + "\" + $database + "_" + $timestamp +".sql"
$backupRar = $backuppath + "\" + $database + "_" + $timestamp +".rar"

# mysqldump.exe command-line parameters
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
    $mailSubject = "Backup MariaDB successful"
    $mailBody = "Backup for the FiveM MariaDB database succeeded $backupCounter times."
    Send-MailMessage -to $mailTo -From $mailFrom -Subject $mailSubject -Body $mailBody -SmtpServer $smtpServer -port $smtpPort -UseSsl -Credential $mailCreds
}
else {
    #Write-Host "Backup MySQL Failed"
    $mailSubject = "Backup MariaDB failed with errors"
    $mailBody = "Backup for the FiveM MariaDB database failed, see attached error log file."
    Send-MailMessage -to $mailTo -From $mailFrom -Subject $mailSubject -Body $mailBody -SmtpServer $smtpServer -port $smtpPort -UseSsl -Credential $mailCreds -Attachments $errorLog
}


# get all names for the existing archive (rar) files
$allRarFiles = Get-ChildItem -Path "$backuppath\$database*.rar"

# archive and mail a new archive file with all database backup files
if ($backupCounter -ge $numberofBackupsToKeep) {

    # Delete all archive files
    foreach ($rarFile in $allRarFiles) {
        Remove-Item -Path "$backuppath\$($rarFile.name)"
    }

    # rar.exe command-line parameters 
    $winrarParameters = "a $backupRar $backupPath"
    
    # Create new archive file
    Start-Process -FilePath "$winrarPath\rar.exe" -ArgumentList $winrarParameters -ErrorAction:SilentlyContinue -Wait:$true
    
    # reset succesfull backup counter
    $backupCounter = 0
    $backupCounter | Out-File -FilePath $backupCounterLogFile
    
    # mail the archive file
    $mailSubject = "Archive file with $numberofBackupsToKeep database backup files"
    $mailBody = "Archive file with $numberofBackupsToKeep database backup files is attached to this mail."
    Send-MailMessage -to $mailTo -From $mailFrom -Subject $mailSubject -Body $mailBody -SmtpServer $smtpServer -port $smtpPort -UseSsl -Credential $mailCreds -Attachments $backupRar
}


# get all names for the existing database backup (.sql) files
$allBackupFiles = Get-ChildItem -Path "$backuppath\$database*.sql"
$allBackupFilesSorted = $allBackupFiles | Sort-Object -Property CreationTime -Descending
$numberOfBackupFiles = $allBackupFilesSorted.count
#Write-Host $allBackupFilesSorted


# Delete the oldest database backup (.sql) file
if ($allBackupFilesSorted.count -ge $numberofBackupsToKeep) {
    for ($i=$numberOfBackupFiles-1; $i -le $numberOfBackupFiles-1; $i++) {
        $fileToBeDeleted = "$backuppath" + "\" + "$($allBackupFilesSorted[$i].name)"
        #write-host $fileToBeDeleted
        Remove-Item -Path $fileToBeDeleted
    }
}
