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

