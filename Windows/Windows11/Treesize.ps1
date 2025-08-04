Get-ChildItem 'C:\Users' -Directory | ForEach-Object {
    $folder = $_.FullName
    $size = (Get-ChildItem $folder -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        UserFolder = $folder
        SizeGB     = "{0:N2}" -f ($size / 1GB)
        SizeMB     = "{0:N0}" -f ($size / 1MB)
        SizeBytes  = $size
    }
} | Sort-Object SizeBytes -Descending | Out-GridView -Title "Tailles des profils C:\Users"
