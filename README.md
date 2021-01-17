# fivem-database-backup

NOTE!
Some scripts and files are now hardcoded to be in the folder: C:\powershell_scripts\ (I have to change that)

Powershell scripts and files:

Powershell scripts to backup and archive your fivem database and send e-mail notifications and archives
You can schedule this script in the server task scheduler
- backup_mariadb_fivem_db.ps1

YAML based configuration parameter file to create Powershell variables for every key-value pair (also included in backup_mariadb_fivem_db.ps1)
- mariadbConfig.yaml

Powershell script to parse the YAML based configuration parameter file to create Powershell variables for every key-value pair
- parseYaml.ps1

Powershell script to parse the folders in the array, gives an nice feedback of all Fivem resource folders and their size
- list_folders_and_sizes.ps1


How to install / use:

    1 - Maak vooraf een nieuwe READONLY user aan in de MariaDB server voor het backup proces
        met onderstaande SQL query commando:
        GRANT LOCK TABLES, SELECT ON *.* TO 'your_backup_user'@'%' IDENTIFIED BY 'yoursecret_password';        
    2 - Vul vooraf het onderstaande configuratie parameter bestand in:
        C:\powershell_scripts\mariadbConfig.yaml
    3 - Maak vooraf een ge-encrypt wachtwoord bestand aan voor het Google -mail- account
        Start onderstaande Powershell regels om het wachtwoord bestand aan te maken, er wordt gevraagd om de user en password gegevens.
        $emailPwdFile = "C:\powershell_scripts\emailbu.pwd"
        (get-credential).password | ConvertFrom-SecureString | set-content $emailPwdFile
    4 - Maak vooraf een ge-encrypt wachtwoord bestand aan voor de sessie naar MariaDB 
        Start onderstaande Powershell regels om het wachtwoord bestand aan te maken, er wordt gevraagd om de user en password gegevens.
        $dbPwdFile = "C:\powershell_scripts\mariadb.pwd"
        (get-credential).password | ConvertFrom-SecureString | set-content $dbPwdFile
    5 - maak onderstaande bestanden beide hidden in de Windows file explorer
        - C:\powershell_scripts\mariadb.pwd
        - C:\powershell_scripts\emailbu.pwd


TODO:
- translate the comments in the Powershell scripts from Dutch to English
- remove hardcoded file paths
- create a Powershell script for the first time install and configuration (create YAM file, password files, etc.)
- extend the Powershell script "backup_mariadb_fivem_db.ps1" and the config paramater file "mariadbConfig.yaml" with extra parameters for:
  - boolean parameters if you want to mail after every successfull or failed database backup
  - parameter that represents a number after how many succcessfull backups a notification should be e-mailed
  - parameter that represents a number after how many failed backups a notification should be e-mailed
- The scripts and config file contain now names for MariaDB, but it also works for mySQL databases, so the idea is not to make it type specific.

