$i=0
while ($i -le 999) {
    Stop-Process -Name "Ldprovision" -Force -ErrorAction SilentlyContinue
    Start-Sleep -S 3
}