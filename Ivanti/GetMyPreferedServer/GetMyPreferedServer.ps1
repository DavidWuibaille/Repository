[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GetMyPreferedServer" Height="169.316" Width="500.004">
    <Grid>
        <TextBox HorizontalAlignment="Left" Name= "IPadress" Height="23" Margin="20,14,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="446"/>
        <Button Name="preferedserver" Content="Get Preferedserver from IP" HorizontalAlignment="Left" Margin="20,37,0,0" VerticalAlignment="Top" Width="446"/>
        <TextBox HorizontalAlignment="Left" Name="Status" Height="23" Margin="20,84,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="446"/>
    </Grid>
</Window>


    
'@
#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}


$dataSource = "InstanceSQL"
$user = "CompteSQL"
$PassSQL = 'MotdepassseSQL'
$database = "Nomdelabase"
$connectionString = "Server=$dataSource;uid=$user; pwd=$PassSQL;Database=$database;Integrated Security=False;"

function IsIpAddressInRange {
    param(
            [string] $ipAddress,
            [string] $fromAddress,
            [string] $toAddress
        )
        $ErrorActionPreference = "SilentlyContinue"
        $ip = [system.net.ipaddress]::Parse($ipAddress).GetAddressBytes()
        [array]::Reverse($ip)
        $ip = [system.BitConverter]::ToUInt32($ip, 0)
    
        $from = [system.net.ipaddress]::Parse($fromAddress).GetAddressBytes()
        [array]::Reverse($from)
        $from = [system.BitConverter]::ToUInt32($from, 0)
    
        $to = [system.net.ipaddress]::Parse($toAddress).GetAddressBytes()
        [array]::Reverse($to)
        $to = [system.BitConverter]::ToUInt32($to, 0)
    
        $from -le $ip -and $ip -le $to
        $ErrorActionPreference = "Continue"
    }





$preferedserver.add_Click({
    $status.Text = "Pref="
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    
    $connection.Open()
    
    $query = "SELECT * FROM [$database].[dbo].[PreferredServerIPLimit] INNER JOIN [$database].[dbo].[PreferredServer] ON [$database].[dbo].[PreferredServer].PreferredServer_Idn = [$database].[dbo].[PreferredServerIPLimit].PreferredServer_Idn"
    

    $command = $connection.CreateCommand()
    $command.CommandText = $query

    $result = $command.ExecuteReader()

    $table = new-object System.Data.DataTable
    $table.Load($result)

    foreach ($element in $table) {

        $StartIP = $element.StartingIPAddress
        For ($i=1; $i -le 9; $i++)   {$StringIP = "00" + $i ; $StartIP = $StartIP.replace($StringIP,$i)}
        For ($i=10; $i -le 99; $i++) {$StringIP = "0"  + $i ; $StartIP = $StartIP.replace($StringIP,$i)}
        $EndIP = $element.EndingIPAddress
        For ($i=1; $i -le 9; $i++)   {$StringIP = "00" + $i ; $EndIP = $EndIP.replace($StringIP,$i)}
        For ($i=10; $i -le 99; $i++) {$StringIP = "0"  + $i ; $EndIP = $EndIP.replace($StringIP,$i)}

        #write-host $element.ServerName $StartIP $EndIP
        $IPserver = $IPadress.text
    

        $IPLageRange = IsIpAddressInRange $IPserver $StartIP $EndIP
        if ($IPLageRange -eq $true) {
            write-host $element.ServerName $StartIP $EndIP
            write-host "Match" 
            $status.Text = $status.Text + " " + $element.ServerName
        }



    }

})

# Display UI object
$Form.ShowDialog() | out-null