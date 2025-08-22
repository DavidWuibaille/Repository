# Function to re-launch the script as Administrator if not already elevated
function Ensure-RunAsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Restarting script with Administrator privileges..."
        $scriptPath = $MyInvocation.MyCommand.Definition

        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        exit
    }
}

# Run the elevation check
Ensure-RunAsAdmin

# Get current directory
$driverPath = Get-Location
$infFiles = Get-ChildItem -Path $driverPath -Recurse -Filter *.inf

if ($infFiles.Count -eq 0) {
    Write-Host "No .inf files found in the current directory: $driverPath"
    exit
}

Write-Host "Scanning .inf files for driver definitions..."

foreach ($inf in $infFiles) {
    $content = Get-Content $inf.FullName -ErrorAction SilentlyContinue
    $hasVersion = $false
    $hasClass = $false

    foreach ($line in $content) {
        if ($line -match '^\s*\[Version\]\s*$') {
            $hasVersion = $true
        } elseif ($line -match '^\s*Class\s*=') {
            $hasClass = $true
        }

        if ($hasVersion -and $hasClass) {
            break
        }
    }

    if ($hasVersion -and $hasClass) {
        Write-Host "Driver file detected: $($inf.FullName)"
        try {
            $output = pnputil /add-driver "$($inf.FullName)" /install
            Write-Host $output
        } catch {
            Write-Warning "Error installing driver: $($inf.FullName)"
            Write-Warning $_.Exception.Message
        }
    } else {
        Write-Host "Skipped (not a valid driver .inf): $($inf.FullName)"
    }
}

Write-Host ""
Write-Host "All .inf files processed."
pause
