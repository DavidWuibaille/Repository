function Get-SqlData($connection, $query) {
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $result = $command.ExecuteReader()
    $table = New-Object System.Data.DataTable
    $table.Load($result)
    return $table
}

function Connect-SQLDatabase {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Server,

        [Parameter(Mandatory = $true)]
        [string]$Database,

        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$Password
    )

    try {
        # Construction de la chaîne de connexion
        $connectionString = "Server=$Server;uid=$User;pwd=$Password;Database=$Database;Integrated Security=False;"
        
        # Création de l'objet connexion SQL
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        
        # Ouverture de la connexion
        $connection.Open()
        Write-Host "------ Connected to Database: $Database on Server: $Server"
        
        # Retourne l'objet connexion
        return $connection
    } catch {
        # Gestion des erreurs
        Write-Host "------ Error connecting to Database: $Database on Server: $Server"
        Write-Host "------ Error details: $_"
        return $null
    }
}

function Get-ApplicationData {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$AppFilter
    )

    # Initialiser la collection pour stocker les données
    $ApplicationData = @()

    # Définir la requête SQL avec le filtre dynamique
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A1.SUITENAME, A1.VERSION
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN AppSoftwareSuites A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        WHERE (A1.SUITENAME LIKE N'%$AppFilter%')
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $ApplicationData += [PSCustomObject]@{
            'APPLICATION'   = $element.SUITENAME
            'VERSION'     = $element.VERSION
            'DEVICENAME' = $element.DISPLAYNAME
        }
    }

    # Retourner la collection
    return $ApplicationData
}


function Get-BitlockerDetails {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    # Initialiser la collection pour stocker les données
    $BitlockerDetails = @()

    # Définir la requête SQL avec le filtre dynamique pour le système d'exploitation
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A2.SECUREBOOTENABLED, A2.UEFIENABLED, A3.CONVERSIONSTATUS,
                        A4.TPMENABLE, A4.TPMVERSION, A5.MODEL
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN Operating_System A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        LEFT OUTER JOIN BIOS A2 (nolock) ON A0.Computer_Idn = A2.Computer_Idn
        LEFT OUTER JOIN BitLocker A3 (nolock) ON A0.Computer_Idn = A3.Computer_Idn
        LEFT OUTER JOIN TPMSystem A4 (nolock) ON A0.Computer_Idn = A4.Computer_Idn
        LEFT OUTER JOIN CompSystem A5 (nolock) ON A0.Computer_Idn = A5.Computer_Idn
        WHERE (A1.OSTYPE LIKE N'%Windows%')
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $BitlockerDetails += [PSCustomObject]@{
            'DEVICENAME'    = $element.DISPLAYNAME
            'BitLocker'     = if ([string]::IsNullOrEmpty($element.CONVERSIONSTATUS)) { "NoData" } else { $element.CONVERSIONSTATUS }
            'SECURE Boot'   = $element.SECUREBOOTENABLED
            'UEFI'          = $element.UEFIENABLED
            'TPM'           = $element.TPMENABLE
            'TPM Version'   = $element.TPMVERSION
            'Model'         = $element.MODEL
        }
    }

    # Retourner la collection d'objets
    return $BitlockerDetails
}


function Get-WindowsDetails {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    # Initialiser la collection pour stocker les données
    $WindowsDetails = @()

    # Définir la requête SQL avec le filtre dynamique pour le système d'exploitation
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A1.OSTYPE, A2.CURRENTBUILD, A2.UBR
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN Operating_System A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        LEFT OUTER JOIN OSNT A2 (nolock) ON A0.Computer_Idn = A2.Computer_Idn
        WHERE (A1.OSTYPE LIKE N'%Windows%')
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $versionFull  = "$($element.CURRENTBUILD).$($element.UBR)"  # Version complète
        $WindowsDetails += [PSCustomObject]@{
            'DEVICENAME' = $element.DISPLAYNAME
            'VERSION'    = $versionFull
        }
    }
    $WindowsDetails = $WindowsDetails | Sort-Object VERSION
    # Retourner la collection d'objets
    return $WindowsDetails
}


function Close-SQLConnection {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    try {
        # Vérifier si la connexion est ouverte
        if ($Connection.State -eq [System.Data.ConnectionState]::Open) {
            $Connection.Close()
            Write-Host "------ Connection closed successfully."
        } else {
            Write-Host "------ Connection is already closed or not initialized."
        }
    } catch {
        # Gestion des erreurs
        Write-Host "------ Error closing the connection."
        Write-Host "------ Error details: $_"
    }
}


function Get-WorkstationModels {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    # Initialiser la collection pour stocker les données
    $WorkstationModels = @()

    # Définir la requête SQL
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A1.MODEL
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN CompSystem A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        WHERE (A0.Computer_Idn NOT IN (
            SELECT Computer_Idn 
            FROM Computer 
            WHERE TYPE LIKE N'%Server%'
        ))
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        # Vérifier si le modèle est vide, ne contient que des espaces ou est égal à "Default string"
        $modelValue = if ([string]::IsNullOrWhiteSpace($element.MODEL) -or $element.MODEL -eq "Default string") {
            "No Data"
        } else {
            $element.MODEL
        }

        $WorkstationModels += [PSCustomObject]@{
            'DEVICENAME' = $element.DISPLAYNAME
            'MODEL'      = $modelValue
        }
    }

    # Retourner la collection d'objets
    return $WorkstationModels
}


function Get-WorkstationManufacturers {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    # Initialiser la collection pour stocker les données
    $ManufacturerData = @()

    # Définir la requête SQL
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A1.MANUFACTURER
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN CompSystem A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        WHERE (A0.Computer_Idn NOT IN (
            SELECT Computer_Idn 
            FROM Computer 
            WHERE TYPE LIKE N'%Server%'
        ))
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $ManufacturerData += [PSCustomObject]@{
            'DEVICENAME'    = $element.DISPLAYNAME
            'MANUFACTURER'  = if ([string]::IsNullOrEmpty($element.MANUFACTURER)) { "NoData" } else { $element.MANUFACTURER }
        }
    }

    # Retourner la collection d'objets
    return $ManufacturerData
}


function Get-EnvironmentVariables {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$VariableName
    )

    # Initialiser la collection pour stocker les données
    $EnvironmentVariables = @()

    # Définir la requête SQL avec le filtre pour le nom de la variable
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A1.VALUESTRING
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN EnvironSettings A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        WHERE (A0.Computer_Idn NOT IN (
            SELECT Computer_Idn 
            FROM Computer 
            WHERE TYPE LIKE N'%Server%'
        ))
        AND A1.NAME = N'$VariableName'
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $EnvironmentVariables += [PSCustomObject]@{
            'DEVICENAME' = $element.DISPLAYNAME
            'VALUE'      = $element.VALUESTRING
        }
    }

    # Retourner la collection d'objets
    return $EnvironmentVariables
}

function Get-HardwareScanDay {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    # Initialiser la collection pour stocker les données
    $HardwareScanData = @()

    # Définir la requête SQL
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A0.HWLASTSCANDATE
        FROM Computer A0 (nolock)
        WHERE (A0.Computer_Idn NOT IN (
            SELECT Computer_Idn 
            FROM Computer 
            WHERE TYPE LIKE N'%Server%'
        ))
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $scanDate = $element.HWLASTSCANDATE
        $daysDifference = (Get-Date) - [datetime]$scanDate

        # Classifier la date selon les intervalles
        $category = switch ($true) {
            ($daysDifference.TotalDays -le 7)  { "<7 jours" }
            ($daysDifference.TotalDays -le 14) { "<14 jours" }
            ($daysDifference.TotalDays -le 30) { "<30 jours" }
            ($daysDifference.TotalDays -le 90) { "<90 jours" }
            default                            { ">90 jours" }
        }

        $HardwareScanData += [PSCustomObject]@{
            'DEVICENAME'      = $element.DISPLAYNAME
            'SCAN_CATEGORY'   = $category
        }
    }

    # Retourner la collection d'objets
    return $HardwareScanData
}


$Connection            = Connect-SQLDatabase                     -Server $ServerSQL -Database $database -User $user -Password $PassSQL
$Application1          = Get-ApplicationData                     -Connection $Connection -AppFilter $ApplicationFilter1
$Application2          = Get-ApplicationData                     -Connection $Connection -AppFilter $ApplicationFilter2
$BitlockerDetails      = Get-BitlockerDetails                    -Connection $Connection
$WindowsDetails        = Get-WindowsDetails                      -Connection $Connection
$WorkstationModels     = Get-WorkstationModels                   -Connection $Connection
$WorkstationMakes      = Get-WorkstationManufacturers            -Connection $Connection
$Variable1             = Get-EnvironmentVariables                -Connection $Connection -VariableName $VariableFilter1
$HardwareScanDay       = Get-HardwareScanDay                     -Connection $Connection
$WindowsgroupesVersion = $WindowsDetails    | Group-Object -Property VERSION
$BitlockerStatus       = $BitlockerDetails  | Group-Object -Property Bitlocker
$Modelscount           = $WorkstationModels | Group-Object -Property MODEL
$Makesount             = $WorkstationMakes  | Group-Object -Property MANUFACTURER
#$ScanDaycount          = HardwareScanDay    | Group-Object -Property SCAN_CATEGORY
Close-SQLConnection -Connection $Connection



