# Désactive le démarrage du service "Tanium Client"
Set-Service -Name "Tanium Client" -StartupType Disabled

# Arrête le service "Tanium Client"
Stop-Service -Name "Tanium Client" -Force
