function Remove-Package {
    param(
        [string]$KB
    )
 
    # Recherche du ou des packages
    $packages = Get-WindowsPackage -Online | Where-Object { $_.PackageName -match $KB }
 
    if($packages.Count -eq 0) {
        Write-Host "No packages found matching $KB."
        return
    }
 
    # Affichage des packages trouvés
    Write-Host "Packages found matching $KB"
    $packages | ForEach-Object { Write-Host $_.PackageName }
 
    # Suppression des packages
    foreach($package in $packages) {
        try {
            Write-Host "Uninstalling $($package.PackageName)..."
            Remove-WindowsPackage -Online -PackageName $package.PackageName -NoRestart -ErrorAction Stop
            Write-Host "$($package.PackageName) uninstalled successfully."
        } catch {
            Write-Error "Failed to uninstall $($package.PackageName). Error: $_"
        }
    }
 
    Write-Host "Please restart your computer."
}
 
# Exemple d'utilisation
Remove-Package -KB "KB4589210"