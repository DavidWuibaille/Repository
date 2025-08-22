function Check-RebootPending {
    $RebootPending = $false

    # Vérification de différentes sources pour voir si un redémarrage est nécessaire

    # 1. Vérifier le redémarrage en attente via Windows Update
    try {
        $WindowsUpdatePending = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
        if ($WindowsUpdatePending) {
            Write-Host "Redémarrage requis par Windows Update."
            $RebootPending = $true
        }
    } catch {
        Write-Warning "Erreur lors de la vérification de Windows Update: $_"
    }

    # 2. Vérifier le redémarrage en attente via le Component-Based Servicing (CBS)
    try {
        $CBSRebootPending = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
        if ($CBSRebootPending) {
            Write-Host "Redémarrage requis par le service CBS (Component-Based Servicing)."
            $RebootPending = $true
        }
    } catch {
        Write-Warning "Erreur lors de la vérification du service CBS: $_"
    }

    # 3. Vérifier les fichiers en attente de renommage via PendingFileRenameOperations
    try {
        $PendingFileRenames = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
        if ($PendingFileRenames.PendingFileRenameOperations) {
            Write-Host "Des fichiers sont en attente de renommage (PendingFileRenameOperations)."
            $RebootPending = $true
        }
    } catch {
        Write-Warning "Erreur lors de la vérification des fichiers en attente de renommage: $_"
    }

    # 4. Vérifier le flag UpdateExeVolatile (souvent utilisé pour les installations MSI)
    try {
        $MSIRebootPending = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Updates" -Name UpdateExeVolatile -ErrorAction SilentlyContinue
        if ($MSIRebootPending.UpdateExeVolatile -ne 0) {
            Write-Host "Redémarrage requis par un programme d'installation (MSI)."
            $RebootPending = $true
        }
    } catch {
        Write-Warning "Erreur lors de la vérification de l'état d'UpdateExeVolatile: $_"
    }


    return $RebootPending
}

function Get-LoggedInUser {
    try {
        # Utilisation de Get-CimInstance pour récupérer l'utilisateur connecté
        $consoleUser = (Get-WmiObject Win32_Process -Filter 'Name="explorer.exe"').SessionId | Select-Object -Unique
        return $consoleUser
    } catch {
        Write-Warning "Erreur lors de la récupération de l'utilisateur connecté: $_"
        return $null
    }
}

function Send-MessageToUser {
    param (
        [string]$message,
        [int]$timeoutSeconds = 30
    )

    try {
        $sessionId = (Get-CimInstance Win32_Process -Filter 'Name="explorer.exe"').SessionId | Select-Object -Unique

        if ($sessionId) {
            & msg.exe $sessionId "$message"
            Start-Sleep -Seconds $timeoutSeconds
        } else {
            Write-Warning "Impossible d'envoyer un message à l'utilisateur car la session n'a pas pu être trouvée."
        }
    } catch {
        Write-Warning "Erreur lors de l'envoi du message à l'utilisateur: $_"
    }
}

# Script principal
$RebootPending = Check-RebootPending
$consoleUser = Get-LoggedInUser

if (-not $consoleUser) {
    Write-Host "Aucun utilisateur connecté."

    if ($RebootPending) {
        Write-Host "Un redémarrage est requis. Redémarrage du système."
        Restart-Computer -Force
    } else {
        Write-Host "Aucun redémarrage nécessaire."
    }
} else {
    Write-Host "Utilisateur connecté : $consoleUser"

    if ($RebootPending) {
        $message = "Un redemarrage est en attente ----- Merci de redemarrer votre ordinateur."
        Send-MessageToUser -message $message -timeoutSeconds 60
    } else {
        Write-Host "Aucun redémarrage requis."
    }
}
