write-host "--- import module"
Import-Module -Name PSwriteHTML

############################################### SQL ################################################################
$Exporthtml = "C:\temp\default.htm"
$dataSource = "epm2024.monlab.lan"
$user = "sa"

# Best solution with password encrypt
#$password = ConvertTo-SecureString -String "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
#$creds    = New-Object -TypeName System.Management.Automation.PsCredential -ArgumentList ($user, $password)

# bad solution with visible password
$password = "Password1"
$creds = New-Object -TypeName System.Management.Automation.PsCredential -ArgumentList ($user, (ConvertTo-SecureString -String $password -AsPlainText -Force))
$database = "EPM"
Write-Host "--- Connecting to SQL"
$PassSQL = $creds.GetNetworkCredential().Password

# Connecting to the database
try {
    $connectionString = "Server=$dataSource;uid=$user;pwd=$PassSQL;Database=$database;Integrated Security=False;"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    Write-Host "------ Connected to Database: $database"
} catch {
    Write-Host "------ Error connecting to Database: $database"
    exit
}

############################################### DATA QUERIES ################################################################
# Function to execute SQL queries and load results into a PowerShell data table
function Get-SqlData($connection, $query) {
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $result = $command.ExecuteReader()
    $table = New-Object System.Data.DataTable
    $table.Load($result)
    return $table
}

# Query for Application1
$Application1 = @()
$query = "SELECT DISTINCT A0.DISPLAYNAME, A1.SUITENAME FROM Computer A0 (nolock)
          LEFT OUTER JOIN AppSoftwareSuites A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
          WHERE (A1.SUITENAME LIKE N'%Visual C++ 2022 X86%')
          ORDER BY A0.DISPLAYNAME"
$table = Get-SqlData $connection $query
foreach ($element in $table) {
    $Application1 += [PSCustomObject]@{
        'DISPLAYNAME' = $element.DISPLAYNAME
        'SUITENAME'   = $element.SUITENAME
    }
}

# Query for Application2
$Application2 = @()
$query = "SELECT DISTINCT A0.DISPLAYNAME, A1.SUITENAME FROM Computer A0 (nolock)
          LEFT OUTER JOIN AppSoftwareSuites A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
          WHERE (A1.SUITENAME LIKE N'%Edge%')
          ORDER BY A0.DISPLAYNAME"
$table = Get-SqlData $connection $query
foreach ($element in $table) {
    $Application2 += [PSCustomObject]@{
        'DEVICENAME' = $element.DISPLAYNAME
        'SUITENAME'  = $element.SUITENAME
    }
}

# Query for Bitlocker details
$Bitlocker = @()
$query = "SELECT DISTINCT A0.DISPLAYNAME, A2.SECUREBOOTENABLED, A2.UEFIENABLED, A3.CONVERSIONSTATUS,
                 A4.TPMENABLE, A4.TPMVERSION, A5.MODEL
          FROM Computer A0 (nolock)
          LEFT OUTER JOIN Operating_System A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
          LEFT OUTER JOIN BIOS A2 (nolock) ON A0.Computer_Idn = A2.Computer_Idn
          LEFT OUTER JOIN BitLocker A3 (nolock) ON A0.Computer_Idn = A3.Computer_Idn
          LEFT OUTER JOIN TPMSystem A4 (nolock) ON A0.Computer_Idn = A4.Computer_Idn
          LEFT OUTER JOIN CompSystem A5 (nolock) ON A0.Computer_Idn = A5.Computer_Idn
          WHERE (A1.OSTYPE LIKE N'%Windows 10%')
          ORDER BY A0.DISPLAYNAME"
$table = Get-SqlData $connection $query
foreach ($element in $table) {
    $Bitlocker += [PSCustomObject]@{
        'DEVICENAME'    = $element.DISPLAYNAME
        'SECURE Boot'   = $element.SECUREBOOTENABLED
        'UEFI'          = $element.UEFIENABLED
        'BitLocker'     = $element.CONVERSIONSTATUS
        'TPM'           = $element.TPMENABLE
        'TPM Version'   = $element.TPMVERSION
        'Model'         = $element.MODEL
    }
}

# Query for Windows details
$Windows  = @()
$WindowsG = @()
$query = "SELECT DISTINCT A0.DISPLAYNAME, A1.OSTYPE, A2.CURRENTBUILD, A2.UBR
          FROM Computer A0 (nolock)
          LEFT OUTER JOIN Operating_System A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
          LEFT OUTER JOIN OSNT A2 (nolock) ON A0.Computer_Idn = A2.Computer_Idn
          WHERE (A1.OSTYPE LIKE N'%Windows 1%')
          ORDER BY A0.DISPLAYNAME"
$table = Get-SqlData $connection $query
foreach ($element in $table) {
    $versionFull  = "$($element.CURRENTBUILD).$($element.UBR)"
    $versionShort = "$($element.CURRENTBUILD)"
    $Windows += [PSCustomObject]@{
        'DEVICENAME' = $element.DISPLAYNAME
        'VERSION'    = $versionFull
    }
    $WindowsG += [PSCustomObject]@{
        'DEVICENAME' = $element.DISPLAYNAME
        'VERSION'    = $versionShort
    }
}

# Sort and group Windows data by version
$Windows        = $Windows | Sort-Object VERSION
$groupesVersion = $Windows | Group-Object -Property VERSION

$WindowsG        = $WindowsG | Sort-Object VERSION
$groupesVersionG = $WindowsG | Group-Object -Property VERSION

# Closing the SQL connection
$connection.Close()

Write-Host "------ Finished executing queries and closing SQL connection"

# Generating HTML report
New-HTML -TitleText 'IVANTI Report' {

    # Start Applications Tab
    New-HTMLTab -Name 'Application Tab' {

        # Content for Application1 tab
        New-HTMLPanel {
            New-HTMLSection -HeaderText 'Application Name for Application1' {
                New-HTMLTable -DataTable $Application1 -HideFooter -SearchPane
            }           
        }

        # Content for Application2 tab
        New-HTMLPanel {
            New-HTMLSection -HeaderText 'Application Name for Application2' {
                New-HTMLTable -DataTable $Application2 -HideFooter -SearchPane
            }           
        }
    }
    # End Applications Tab
	
    # Start Windows Tab
    New-HTMLTab -Name 'Windows TAB' {		
        New-HTMLSection -HeaderText 'Windows Version' {
            New-HTMLPanel {
                # Chart for full version details
                New-HTMLChart -Title "Version" {
                    New-ChartToolbar -Download
                    New-ChartEvent -DataTableID 'WindowsOS' -ColumnID 1
                    foreach ($groupe in $groupesVersion) {
                        New-ChartDonut -Name $($groupe.Name) -Value $($groupe.Count)
                    }
                }
            }
            # Chart for short version details
            New-HTMLPanel {
                New-HTMLChart -Title "VersionG" {
                    New-ChartToolbar -Download
                    foreach ($groupe in $groupesVersionG) {
                        New-ChartDonut -Name $($groupe.Name) -Value $($groupe.Count)
                    }
                }
            }
        }

        # Hidden section to display Windows data table
        New-HTMLSection -Invisible {			
            New-HTMLPanel {
                New-HTMLTable -DataTable $Windows -DataTableID 'WindowsOS' -HideFooter
            }
        }        
        # Section for Bitlocker details
        New-HTMLSection -HeaderText 'Bitlocker detail' {
            New-HTMLTable -DataTable $Bitlocker -HideFooter -SearchPane -PreContent {
                "<H1>Bitlocker Details</H1>"
            }
        }
    }
    # End Windows Tab

    # Footer with the report date
    New-HTMLFooter {
        New-HTMLText -Text "Date of this report (GMT time): $(Get-Date)" -Color Blue -Alignment Center 
    }
} -FilePath $Exporthtml -Online
