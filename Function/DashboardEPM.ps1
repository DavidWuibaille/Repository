############################################### SQL ################################################################
$Exporthtml = "C:\Exploitation\report\SuiviOS.htm"
$configPath = "C:\Scripts\config.json"
############################################### SQL ################################################################


$config = Get-Content $configPath | ConvertFrom-Json
$ServerSQL = $config.SQL.Server
$database = $config.SQL.Database
$user = $config.SQL.Username
$password = $config.SQL.Password

# Convertir le mot de passe en SecureString
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($user, $securePassword)
$PassSQL = $creds.GetNetworkCredential().Password


Import-Module -Name PSwriteHTML
. ([scriptblock]::Create((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DavidWuibaille/Repository/main/Function/DashboardEPM.ps1" -UseBasicParsing).Content))

$Connection            = Connect-SQLDatabase                     -Server $ServerSQL -Database $database -User $user -Password $PassSQL
#$Application1          = Get-ApplicationData                     -Connection $Connection -AppFilter $ApplicationFilter1
#$Application2          = Get-ApplicationData                     -Connection $Connection -AppFilter $ApplicationFilter2
#$BitlockerDetails      = Get-BitlockerDetails                    -Connection $Connection
$WindowsDetails        = Get-WindowsDetails                      -Connection $Connection
$WorkstationModels     = Get-WorkstationModels                   -Connection $Connection
#$WorkstationMakes      = Get-WorkstationManufacturers            -Connection $Connection
#$Variable1             = Get-EnvironmentVariables                -Connection $Connection -VariableName $VariableFilter1
#$HardwareScanDay       = Get-HardwareScanDay                     -Connection $Connection
$WindowsgroupesVersion = $WindowsDetails    | Group-Object -Property VERSION
#$BitlockerStatus       = $BitlockerDetails  | Group-Object -Property Bitlocker
$Modelscount           = $WorkstationModels | Group-Object -Property MODEL
$Makesount             = $WorkstationMakes  | Group-Object -Property MANUFACTURER
#$ScanDaycount          = HardwareScanDay    | Group-Object -Property SCAN_CATEGORY
Close-SQLConnection -Connection $Connection





# Sauvegarde quotidienne des versions Windows
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$historyFile = Join-Path -Path $scriptPath -ChildPath "windows_versions_history.csv"
$today = (Get-Date -Format "yyyy-MM-dd")

$todayData = $WindowsgroupesVersion | ForEach-Object {
    [PSCustomObject]@{
        Date    = $today
        Version = $_.Name
        Count   = $_.Count
    }
}

$yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")

if (-Not (Test-Path $historyFile)) {
    # Si le fichier n'existe pas, on crée aussi les données d'hier à zéro
    $yesterdayData = $WindowsgroupesVersion | ForEach-Object {
        [PSCustomObject]@{
            Date    = $yesterday
            Version = $_.Name
            Count   = 0
        }
    }

    # On combine hier (zéro) + aujourd'hui (réel)
    $yesterdayData + $todayData | Export-Csv -Path $historyFile -NoTypeInformation -Encoding UTF8
} else {
    $existingData = Import-Csv $historyFile
    $newEntries = $todayData | Where-Object {
        $version = $_.Version
        -Not ($existingData | Where-Object { $_.Date -eq $today -and $_.Version -eq $version })
    }
    if ($newEntries) {
        $newEntries | Export-Csv -Path $historyFile -Append -NoTypeInformation -Encoding UTF8
    }
}

# Génération des courbes temporelles
$history = Import-Csv -Path $historyFile

# Assurer que Count est bien un entier (au cas où CSV l'ait converti en string)
$history | ForEach-Object { $_.Count = [int]$_.Count }

$versions = $history.Version | Sort-Object -Unique
$dates = $history.Date | Sort-Object -Unique

# Courbe pour chaque version complète
$lines = foreach ($version in $versions) {
    $valeurs = foreach ($date in $dates) {
        $sum = ($history | Where-Object { $_.Date -eq $date -and $_.Version -eq $version } | Measure-Object -Property Count -Sum).Sum
        if (-not $sum) { $sum = 0 }
        $sum
    }
    [PSCustomObject]@{
        Version = $version
        Values  = $valeurs
    }
}

# Ajouter colonne MajorVersion à partir de Version
$historyGrouped = $history | ForEach-Object {
    $_ | Add-Member -NotePropertyName "MajorVersion" -NotePropertyValue ($_.Version -split '\.')[0] -Force
    $_
}

# Liste des versions majeures uniques
$majorVersions = $historyGrouped.MajorVersion | Sort-Object -Unique

# Dictionnaire de labels lisibles
$versionLabels = @{
    "14393" = "Windows 10 1607"
    "17763" = "Windows 10 1809"
    "19044" = "Windows 10 21H2"
    "20348" = "Windows Server 2022"
    "22621" = "Windows 11 22H2"
    "22631" = "Windows 11 23H2"
}

# Courbes pour les versions majeures
$linesMajor = foreach ($version in $majorVersions) {
    $valeurs = foreach ($date in $dates) {
        $sum = ($historyGrouped | Where-Object {
            $_.Date -eq $date -and $_.MajorVersion -eq $version
        } | Measure-Object -Property Count -Sum).Sum

        if (-not $sum) { $sum = 0 }
        $sum
    }

    $displayName = if ($versionLabels.ContainsKey($version)) {
        $versionLabels[$version]
    } else {
        $version
    }

    [PSCustomObject]@{
        Version = $displayName
        Values  = $valeurs
    }
}



# Rapport HTML
New-HTML -TitleText 'Dashboard' {

    # Onglet Windows - Donut chart actuel
    New-HTMLTab -Name 'Windows' {
        New-HTMLSection -HeaderText 'Windows Version' {
            New-HTMLPanel {
                New-HTMLChart -Title "Version" {
                    New-ChartToolbar -Download
                    New-ChartEvent -DataTableID 'WindowsOS' -ColumnID 1
                    foreach ($groupe in $WindowsgroupesVersion) {
                        New-ChartDonut -Name $($groupe.Name) -Value $($groupe.Count)
                    }
                }
            }
			
			New-HTMLPanel {
				New-HTMLChart -Title "Windows Major" {
					New-ChartToolbar -Download
					 foreach ($line in $linesMajor) {
						$total = ($line.Values | Measure-Object -Sum).Sum
						New-ChartDonut -Name $($line.Version) -Value $total
					}
				}
			}			
			
        }
        New-HTMLSection -Invisible {
            New-HTMLPanel {
                New-HTMLTable -DataTable $WindowsDetails -DataTableID 'WindowsOS' -HideFooter
            }
        }
    }

    # Onglet Timeline - Évolution dans le temps
    New-HTMLTab -Name 'Windows Timeline' {
        New-HTMLSection -HeaderText 'Windows Versions Over Time' {
            New-HTMLPanel {
                New-HTMLChart -Title "Windows Versions (Daily Evolution)" -TitleAlignment center {
                    New-ChartAxisX -Names $dates
                    foreach ($line in $lines) {
                        New-ChartLine -Name $line.Version -Value $line.Values
                    }
                }
            }
        }
# Deuxième graphique en-dessous
New-HTMLSection -HeaderText 'Windows Versions Over Time (Grouped by Major Version)' {
    New-HTMLPanel {
        New-HTMLChart -Title "Windows Major Versions (Daily Evolution)" -TitleAlignment center {
            New-ChartAxisX -Names $dates
            foreach ($line in $linesMajor) {
                New-ChartLine -Name $line.Version -Value $line.Values
            }
        }
    }
}		
		
    }

    # Onglet Hardware
    New-HTMLTab -Name 'Model' {
        New-HTMLSection -HeaderText 'Hardware' {
            New-HTMLPanel {
                New-HTMLChart -Title "Version" {
                    New-ChartToolbar -Download
                    New-ChartEvent -DataTableID 'Modelcount' -ColumnID 1
                    foreach ($groupe in $Modelscount) {
                        New-ChartDonut -Name $($groupe.Name) -Value $($groupe.Count)
                    }
                }
            }
        }
        New-HTMLSection -HeaderText 'Models details' {
            New-HTMLTable -DataTable $WorkstationModels -DataTableID 'Modelcount' -HideFooter {
                "<H1>Models Details</H1>"
            }
        }
    }

    # Pied de page
    New-HTMLFooter {
        New-HTMLText -Text "Date of this report (GMT time): $(Get-Date)" -Color Blue -Alignment Center 
    }

} -FilePath $Exporthtml -Online
