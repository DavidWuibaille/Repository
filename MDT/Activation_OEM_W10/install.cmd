powershell -noprofile -command "Set-ExecutionPolicy bypass LocalMachine"
powershell -file "%~dp0ActivationW10OEM.ps1"

timeout 10
