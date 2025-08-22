# Import the required modules
Import-Module Pode.Web
Import-Module SqlServer
 
# Start the Pode server
Start-PodeServer {
    Add-PodeEndpoint -Address * -Port 8080 -Protocol Http
 
    # Define the route to get the computer name based on the MAC address
    Add-PodeRoute -Method Get -Path '/GetName' -ScriptBlock {
        # Retrieve the MAC address from the query parameters
        $macaddress = $WebEvent.Query['macaddress']
        Write-Host "Received MAC Address: $macaddress"
 
        $user = 'sa'
        $password = "Password1"
        $creds = New-Object -TypeName System.Management.Automation.PsCredential -ArgumentList ($user, (ConvertTo-SecureString -String $password -AsPlainText -Force))
        $database = "EPM"
         $dataSource = "epm2024.monlab.lan"
        Write-Host "--- Connecting to SQL"
        $PassSQL = $creds.GetNetworkCredential().Password
 
        # Connecting to the database
        $connectionString = "Server=$dataSource;uid=$user;pwd=$PassSQL;Database=$database;Integrated Security=False;"
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()
     
        $query = "SELECT DISTINCT A0.DISPLAYNAME, A1.PHYSADDRESS  FROM Computer A0 (nolock) LEFT OUTER JOIN BoundAdapter A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn  WHERE (A0.DISPLAYNAME IS NOT NULL)   ORDER BY  A0.DISPLAYNAME "
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $result = $command.ExecuteReader()
        $table = New-Object System.Data.DataTable
        $table.Load($result)
 
        $connection.Close()
 
        $computername = "Not found"
        foreach ($element in $table) {  
            $Tabmac = $($element.PHYSADDRESS)
            #write-host "Compare $Tabmac - $macaddress"
            If ($Tabmac -eq $macaddress) {
                $computername = $($element.DISPLAYNAME)
                #write-host "Match .."
            }
        }
        Write-host "Result $computername"
        # Return the response
        Write-PodeJsonResponse -Value @{
            Computername   = $computername
            SecondVariable = "ABCDE"
        }
    }
}