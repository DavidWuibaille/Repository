# Detect Active Card
$CarteUP = ""
$Cards = Get-NetAdapter
foreach ($Card in $Cards) {
    if (($Card.Status -eq "Up") -and ($Card.Name -notlike "*VMware*" )) {
        if (($CarteUP -eq "") -or ($CarteUP -like"*wi")) {
            $CarteUP = $Card.Name
        }
    }
}


# Detect Index Card
$IndexCarte = ""
$indexCards = Get-NetIPInterface
foreach ($indexCard in $indexCards) {
    if (($indexCard.InterfaceAlias -eq "$CarteUP") -and ($indexCard.AddressFamily -eq "IPv4")) {
        $IndexCarte = $IndexCard.ifIndex
        $DHCPCarte  = $IndexCard.DHCP

    }
}

Set-DnsClientServerAddress -InterfaceIndex $IndexCarte -ServerAddresses  ("192.168.0.210")


