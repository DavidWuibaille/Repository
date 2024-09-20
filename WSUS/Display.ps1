# Initializations
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()
$computerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$summariesComputerFailed = $wsus.GetSummariesPerComputerTarget($updateScope,$computerScope) | Where-Object FailedCount -NE 0 | Sort-Object FailedCount, UnknownCount, NotInstalledCount -Descending
$computers = Get-WsusComputer
$computersErrorEvents = $wsus.GetUpdateEventHistory([System.DateTime]::Today.AddDays(-7), [System.DateTime]::Today) | Where-Object ComputerId -ne [Guid]::Empty | Where-Object IsError -eq $true

function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

$csvFile = "$PSScriptRoot\WSUSFailedComputer_" + "{0:MMddyy}" -f (Get-Date) + ".csv"
Get-WsusComputer -ComputerUpdateStatus Failed | Export-Csv -Path $csvFile -NoTypeInformation
$ComputersErrorToday = Get-WsusComputer -ComputerUpdateStatus Failed

$csvList = (Get-ChildItem -Path $PSScriptRoot -Filter *.csv).FullName
$AllCsv = $csvList | Import-Csv
$AllCsv = $AllCsv | Sort-Object "FullDomainName"

$Ordinateur = @()
$CountError  = 1
$OldComputer = "XXXX"
Foreach ($csv In $AllCsv) {
    $FullDomainName = $csv.FullDomainName

    $ExitError = $true
    Foreach ($ComputerErrorToday In $ComputersErrorToday) {
        $FullNameComputerErrorToday = $ComputerErrorToday.FullDomainName
        if ($FullNameComputerErrorToday -eq $FullDomainName) { $ExitError = $false }
    }

    If (-not $ExitError) {
        If ($OldComputer -eq $FullDomainName) {
          $CountError += 1
        } Else {
            if ($OldComputer -ne "XXXX") {
                $CountError = $CountError.ToString("0000")
                $Ordinateur += "$CountError;$OldComputer"
            }
            $CountError  = 1
            $OldComputer = $FullDomainName
        }
    }
}

$Ordinateur = $Ordinateur | Sort-Object -Descending
$TotalAffiche = 10
$NbAffiche    = 0
Foreach ($Computererror In $Ordinateur) {
    If ($NbAffiche -lt $TotalAffiche) {
        Write-Host $Computererror

        $NbAffiche += 1

        $NomOrdinateur = $Computererror.Substring(5)
        ForEach ($computerFailed In $summariesComputerFailed) {
          $computer = $computers | Where-Object Id -eq $computerFailed.ComputerTargetId

          $Computername = $computer.FullDomainName
          $ComputerIP   = $computer.IPAddress

          if ($Computername -eq $NomOrdinateur) {
              $computerUpdatesFailed = ($wsus.GetComputerTargets($computerScope) | Where-Object Id -EQ $computerFailed.ComputerTargetId).GetUpdateInstallationInfoPerUpdate($updateScope) | Where-Object UpdateInstallationState -EQ "Failed"
              ForEach ($update In $computerUpdatesFailed) {
                $outputText = $wsus.GetUpdate($update.UpdateId).Title
                Write-Host "------------ $outputText"
              }
          }
        }
    }
}