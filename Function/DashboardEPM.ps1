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
        [string]$Filter
    )

    # Initialiser la collection pour stocker les données
    $ApplicationData = @()

    # Définir la requête SQL avec le filtre dynamique
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A1.SUITENAME 
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN AppSoftwareSuites A1 (nolock) 
        ON A0.Computer_Idn = A1.Computer_Idn
        WHERE (A1.SUITENAME LIKE N'%$Filter%')
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $ApplicationData += [PSCustomObject]@{
            'DISPLAYNAME' = $element.DISPLAYNAME
            'SUITENAME'   = $element.SUITENAME
        }
    }

    # Retourner la collection
    return $ApplicationData
}


function Get-BitlockerDetails {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$OSTypeFilter = "Windows 11"  # Filtre par défaut pour le système d'exploitation
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
        WHERE (A1.OSTYPE LIKE N'%$OSTypeFilter%')
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $BitlockerDetails += [PSCustomObject]@{
            'DEVICENAME'    = $element.DISPLAYNAME
            'SECURE Boot'   = $element.SECUREBOOTENABLED
            'UEFI'          = $element.UEFIENABLED
            'BitLocker'     = $element.CONVERSIONSTATUS
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
        [System.Data.SqlClient.SqlConnection]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$OSTypeFilter = "Windows 11"  # Filtre par défaut pour le système d'exploitation
    )

    # Initialiser la collection pour stocker les données
    $WindowsDetails = @()

    # Définir la requête SQL avec le filtre dynamique pour le système d'exploitation
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A1.OSTYPE, A2.CURRENTBUILD, A2.UBR
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN Operating_System A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        LEFT OUTER JOIN OSNT A2 (nolock) ON A0.Computer_Idn = A2.Computer_Idn
        WHERE (A1.OSTYPE LIKE N'%$OSTypeFilter%')
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

    # Retourner la collection d'objets
    return $WindowsDetails
}