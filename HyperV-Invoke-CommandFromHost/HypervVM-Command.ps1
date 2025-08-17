#requires -RunAsAdministrator
<#
GUI to:
- List running Hyper-V VMs
- Fetch .ps1 scripts from https://nas.wuibaille.fr/WS/postype/
- Prompt for credentials
- Execute selected script inside selected VMs via PowerShell Direct
- Optional: run gpupdate /force afterwards

Tested on Windows 11 + PowerShell 5/7.
#>

$ErrorActionPreference = 'Stop'

# ---------- Config ----------
$BaseUrl = 'https://nas.wuibaille.fr/WS/postype/'

# ---------- Setup ----------
try { Import-Module Hyper-V -ErrorAction Stop } catch {
    Write-Error "Hyper-V PowerShell module not available. Install/enable Hyper-V Management Tools."
    return
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 0x3000  # include TLS1.3 if available
} catch {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function Get-RunningVMs {
    Get-VM | Where-Object { $_.State -eq 'Running' } | Sort-Object Name | Select-Object -ExpandProperty Name
}

function Get-ScriptsFromUrl {
    param([string]$Url)
    # Fetch directory HTML and extract .ps1 links (robust for PS5/PS7)
    $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing
    $html = $resp.Content

    # Regex: href="something.ps1" or href='something.ps1'
    $matches = [System.Text.RegularExpressions.Regex]::Matches($html, 'href\s*=\s*["' + "'" + ']([^"' + "'" + ']+\.ps1)["' + "'" + ']', 'IgnoreCase')
    $links = @()
    $baseUri = [Uri]$Url
    foreach ($m in $matches) {
        $href = $m.Groups[1].Value
        # Skip parent links etc.
        if ($href -match '^\.\./?$') { continue }
        $full = if ([Uri]::IsWellFormedUriString($href, [UriKind]::Absolute)) {
            [Uri]$href
        } else {
            [Uri]::new($baseUri, $href)
        }
        $name = [System.IO.Path]::GetFileName($full.AbsolutePath)
        if (-not [string]::IsNullOrWhiteSpace($name)) {
            $links += [PSCustomObject]@{ Name = $name; Url = $full.AbsoluteUri }
        }
    }
    $links | Sort-Object Name -Unique
}

function Write-Log {
    param([string]$Message)
    $ts = (Get-Date).ToString('HH:mm:ss')
    $LogTextBox.AppendText("[$ts] $Message`r`n")
    $LogTextBox.SelectionStart = $LogTextBox.Text.Length
    $LogTextBox.ScrollToCaret()
}

function Invoke-GuestScript {
    param(
        [string]$VMName,
        [pscredential]$Credential,
        [string]$ScriptUrl,
        [bool]$RunGpupdate
    )
    $fileName = [IO.Path]::GetFileName($ScriptUrl)

    Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock {
        param($Url, $FileName, $DoGp)

        # Prefer TLS12/13 in guest
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 0x3000
        } catch {
            try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
        }

        $dest = Join-Path $env:TEMP $FileName
        $out = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Downloaded   = $false
            DownloadErr  = $null
            ScriptExit   = $null
            ScriptErr    = $null
            GPExit       = $null
            GPErr        = $null
        }

        try {
            Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -ErrorAction Stop
            $out.Downloaded = Test-Path -LiteralPath $dest
        } catch {
            $out.DownloadErr = $_.Exception.Message
        }

        if ($out.Downloaded) {
            try {
                $p = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', $dest) -WindowStyle Hidden -Wait -PassThru
                $out.ScriptExit = $p.ExitCode
            } catch {
                $out.ScriptExit = -1
                $out.ScriptErr  = $_.Exception.Message
            }
        }

        if ($DoGp) {
            try {
                $p2 = Start-Process -FilePath 'gpupdate.exe' -ArgumentList '/force' -WindowStyle Hidden -Wait -PassThru
                $out.GPExit = $p2.ExitCode
            } catch {
                $out.GPExit = -1
                $out.GPErr  = $_.Exception.Message
            }
        }

        $out
    } -ArgumentList $ScriptUrl, $fileName, $RunGpupdate -ErrorAction Stop
}

# ---------- GUI ----------
$form                = New-Object System.Windows.Forms.Form
$form.Text           = 'Hyper-V Guest Script Runner'
$form.StartPosition  = 'CenterScreen'
$form.Size           = New-Object System.Drawing.Size(820, 640)
$form.MaximizeBox    = $true

# Credentials
$grpCred = New-Object System.Windows.Forms.GroupBox
$grpCred.Text = 'Credentials (Guest OS)'
$grpCred.Location = New-Object System.Drawing.Point(12, 12)
$grpCred.Size     = New-Object System.Drawing.Size(390, 90)

$lblUser = New-Object System.Windows.Forms.Label
$lblUser.Text = 'Username'
$lblUser.Location = New-Object System.Drawing.Point(12, 28)
$lblUser.AutoSize = $true
$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Location = New-Object System.Drawing.Point(100, 24)
$txtUser.Size     = New-Object System.Drawing.Size(270, 23)
$txtUser.Text     = '.\Administrator'

$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = 'Password'
$lblPass.Location = New-Object System.Drawing.Point(12, 58)
$lblPass.AutoSize = $true
$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = New-Object System.Drawing.Point(100, 54)
$txtPass.Size     = New-Object System.Drawing.Size(270, 23)
$txtPass.UseSystemPasswordChar = $true

$grpCred.Controls.AddRange(@($lblUser,$txtUser,$lblPass,$txtPass))
$form.Controls.Add($grpCred)

# Scripts
$grpScripts = New-Object System.Windows.Forms.GroupBox
$grpScripts.Text = 'Available Scripts'
$grpScripts.Location = New-Object System.Drawing.Point(12, 110)
$grpScripts.Size     = New-Object System.Drawing.Size(780, 80)

$lblScript = New-Object System.Windows.Forms.Label
$lblScript.Text = 'Script'
$lblScript.Location = New-Object System.Drawing.Point(12, 35)
$lblScript.AutoSize = $true

$cmbScripts = New-Object System.Windows.Forms.ComboBox
$cmbScripts.Location = New-Object System.Drawing.Point(70, 31)
$cmbScripts.Size     = New-Object System.Drawing.Size(620, 23)
$cmbScripts.DropDownStyle = 'DropDownList'

$btnRefreshScripts = New-Object System.Windows.Forms.Button
$btnRefreshScripts.Text = 'Refresh'
$btnRefreshScripts.Location = New-Object System.Drawing.Point(700, 30)
$btnRefreshScripts.Size     = New-Object System.Drawing.Size(65, 25)

$grpScripts.Controls.AddRange(@($lblScript,$cmbScripts,$btnRefreshScripts))
$form.Controls.Add($grpScripts)

# VMs
$grpVMs = New-Object System.Windows.Forms.GroupBox
$grpVMs.Text = 'Running VMs'
$grpVMs.Location = New-Object System.Drawing.Point(12, 200)
$grpVMs.Size     = New-Object System.Drawing.Size(390, 320)

$vmList = New-Object System.Windows.Forms.CheckedListBox
$vmList.Location = New-Object System.Drawing.Point(12, 24)
$vmList.Size     = New-Object System.Drawing.Size(360, 244)
$vmList.CheckOnClick = $true

$btnSelAll = New-Object System.Windows.Forms.Button
$btnSelAll.Text = 'Select All'
$btnSelAll.Location = New-Object System.Drawing.Point(12, 276)
$btnSelAll.Size     = New-Object System.Drawing.Size(90, 25)

$btnClearSel = New-Object System.Windows.Forms.Button
$btnClearSel.Text = 'Clear'
$btnClearSel.Location = New-Object System.Drawing.Point(108, 276)
$btnClearSel.Size     = New-Object System.Drawing.Size(90, 25)

$btnRefreshVMs = New-Object System.Windows.Forms.Button
$btnRefreshVMs.Text = 'Refresh'
$btnRefreshVMs.Location = New-Object System.Drawing.Point(204, 276)
$btnRefreshVMs.Size     = New-Object System.Drawing.Size(90, 25)

$grpVMs.Controls.AddRange(@($vmList,$btnSelAll,$btnClearSel,$btnRefreshVMs))
$form.Controls.Add($grpVMs)

# Actions / Options
$grpActions = New-Object System.Windows.Forms.GroupBox
$grpActions.Text = 'Actions'
$grpActions.Location = New-Object System.Drawing.Point(414, 200)
$grpActions.Size     = New-Object System.Drawing.Size(378, 100)

$chkGp = New-Object System.Windows.Forms.CheckBox
$chkGp.Text = 'Run gpupdate /force after script'
$chkGp.Location = New-Object System.Drawing.Point(16, 28)
$chkGp.AutoSize = $true
$chkGp.Checked = $false

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = 'Run on Selected VMs'
$btnRun.Location = New-Object System.Drawing.Point(16, 58)
$btnRun.Size     = New-Object System.Drawing.Size(340, 28)

$grpActions.Controls.AddRange(@($chkGp,$btnRun))
$form.Controls.Add($grpActions)

# Log
$grpLog = New-Object System.Windows.Forms.GroupBox
$grpLog.Text = 'Log'
$grpLog.Location = New-Object System.Drawing.Point(414, 304)
$grpLog.Size     = New-Object System.Drawing.Size(378, 216)

$LogTextBox = New-Object System.Windows.Forms.TextBox
$LogTextBox.Multiline = $true
$LogTextBox.ScrollBars = 'Vertical'
$LogTextBox.Location = New-Object System.Drawing.Point(16, 24)
$LogTextBox.Size     = New-Object System.Drawing.Size(346, 176)
$LogTextBox.Font     = New-Object System.Drawing.Font('Consolas', 9)

$grpLog.Controls.Add($LogTextBox)
$form.Controls.Add($grpLog)

# Progress bar
$prg = New-Object System.Windows.Forms.ProgressBar
$prg.Location = New-Object System.Drawing.Point(12, 532)
$prg.Size     = New-Object System.Drawing.Size(780, 20)
$prg.Minimum  = 0
$prg.Step     = 1
$form.Controls.Add($prg)

# ---------- Handlers ----------
$populateVMs = {
    $vmList.Items.Clear()
    $vms = Get-RunningVMs
    foreach ($v in $vms) { [void]$vmList.Items.Add($v, $false) }
    Write-Log ("Found {0} running VMs." -f $vms.Count)
}

$populateScripts = {
    try {
        $cmbScripts.Items.Clear()
        $scripts = Get-ScriptsFromUrl -Url $BaseUrl
        foreach ($s in $scripts) {
            # store PSCustomObject directly; display Name
            [void]$cmbScripts.Items.Add($s)
        }
        if ($cmbScripts.Items.Count -gt 0) { $cmbScripts.SelectedIndex = 0 }
        Write-Log ("Loaded {0} scripts from {1}" -f $cmbScripts.Items.Count, $BaseUrl)
    } catch {
        Write-Log "ERROR fetching scripts: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Failed to fetch scripts.`r`n$($_.Exception.Message)", 'Error',
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

$btnRefreshVMs.Add_Click({ & $populateVMs })
$btnRefreshScripts.Add_Click({ & $populateScripts })

$btnSelAll.Add_Click({
    for ($i=0; $i -lt $vmList.Items.Count; $i++) { $vmList.SetItemChecked($i, $true) }
})
$btnClearSel.Add_Click({
    for ($i=0; $i -lt $vmList.Items.Count; $i++) { $vmList.SetItemChecked($i, $false) }
})

$btnRun.Add_Click({
    # Validate inputs
    $user = $txtUser.Text.Trim()
    $pass = $txtPass.Text
    if ([string]::IsNullOrWhiteSpace($user) -or [string]::IsNullOrWhiteSpace($pass)) {
        [System.Windows.Forms.MessageBox]::Show('Please enter username and password.', 'Missing credentials',
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    $selScript = $cmbScripts.SelectedItem
    if (-not $selScript) {
        [System.Windows.Forms.MessageBox]::Show('Please select a script.', 'No script selected',
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    $selectedVMs = @()
    foreach ($item in $vmList.CheckedItems) { $selectedVMs += [string]$item }
    if (-not $selectedVMs -or $selectedVMs.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('Please select at least one VM.', 'No VMs selected',
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    # Build credential
    try {
        $sec = ConvertTo-SecureString $pass -AsPlainText -Force
        $cred = [pscredential]::new($user, $sec)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Invalid credentials: $($_.Exception.Message)", 'Error',
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    # Disable controls during run
    foreach ($ctrl in @($form.Controls + $grpCred.Controls + $grpScripts.Controls + $grpVMs.Controls + $grpActions.Controls)) {
        try { $ctrl.Enabled = $false } catch {}
    }

    $prg.Value = 0
    $prg.Maximum = $selectedVMs.Count

    Write-Log ("Executing '{0}' on {1} VM(s)..." -f $selScript.Name, $selectedVMs.Count)

    foreach ($vm in $selectedVMs) {
        try {
            Write-Log "[$vm] Starting..."
            $res = Invoke-GuestScript -VMName $vm -Credential $cred -ScriptUrl $selScript.Url -RunGpupdate $chkGp.Checked

            # Summarize
            $dl = if ($res.Downloaded) { 'OK' } else { 'FAIL' }
            $sx = if ($null -ne $res.ScriptExit) { $res.ScriptExit } else { 'N/A' }
            $gx = if ($null -ne $res.GPExit)     { $res.GPExit }     else { 'N/A' }

            Write-Log ("[$vm] Download={0}; ScriptExit={1}; GPExit={2}" -f $dl, $sx, $gx)

            if ($res.DownloadErr) { Write-Log ("[$vm] DownloadError: {0}" -f $res.DownloadErr) }
            if ($res.ScriptErr)   { Write-Log ("[$vm] ScriptError:   {0}" -f $res.ScriptErr) }
            if ($res.GPErr)       { Write-Log ("[$vm] GPError:       {0}" -f $res.GPErr) }
        }
        catch {
            Write-Log ("[$vm] ERROR: {0}" -f $_.Exception.Message)
        }
        finally {
            $prg.PerformStep()
        }
    }

    Write-Log 'Done.'

    # Re-enable controls
    foreach ($ctrl in @($form.Controls + $grpCred.Controls + $grpScripts.Controls + $grpVMs.Controls + $grpActions.Controls)) {
        try { $ctrl.Enabled = $true } catch {}
    }
})

# ---------- Init ----------
& $populateVMs
& $populateScripts

[void]$form.ShowDialog()
