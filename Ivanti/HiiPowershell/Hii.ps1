Param(
    [parameter(Mandatory=$true)][String]$path
)

$Biosvendor = Get-WmiObject Win32_ComputerSystem
$Marque = $Biosvendor.Manufacturer
$Modele = $Biosvendor.Model

if ($Marque -like "*Dell*") 			{ $Marque = "Dell" }
if ($Marque -like "*Hewlett-Packard*") 	{ $Marque = "HP" }
if ($Marque -like "*VMware*") 			{ $Marque = "VM" }
if ($Marque -like "*TOSHIBA*") 			{ $Marque = "TOSHIBA" }
if ($Marque -like "*Microsoft*") 		{ $Marque = "Microsoft" }
if ($Marque -like "*Wacom*") 			{ $Marque = "Wacom" }
if ($Marque -like "*Aava*") 			{ $Marque = "Aava" }
if ($Marque -like "*WINCOR*") 			{ $Marque = "WINCOR" }
if ($Marque -like "*LENOVO*") 			{ $Marque = "LENOVO" }

if ($Marque -eq "LENOVO") {
	$BiosSystem = Get-WmiObject Win32_ComputerSystemproduct
	$Modele = $BiosSystem.Version
}
$Modele = $Modele.replace("HP RT5810","RP5810")
$Modele = $Modele.replace("HPRT5810","RP5810")
$Modele = $Modele.replace("RP581P","RP5810")
$Modele = $Modele.replace("L3D26AV","")
$Modele = $Modele -ireplace [regex]::Escape(","), ""
$Modele = $Modele -ireplace [regex]::Escape("HP "), ""
$Modele = $Modele -ireplace [regex]::Escape("Tower"), ""
$Modele = $Modele -ireplace [regex]::Escape("Workstation"), ""
$Modele = $Modele -ireplace [regex]::Escape("2-in-1"), "2IN1"
$Modele = $Modele -ireplace [regex]::Escape("EliteBook"), ""
$Modele = $Modele -ireplace [regex]::Escape("EliteOne"), ""
$Modele = $Modele -ireplace [regex]::Escape("EliteDesk"), ""
$Modele = $Modele -ireplace [regex]::Escape("Elite"), ""
$Modele = $Modele -ireplace [regex]::Escape("ProBook"), ""
$Modele = $Modele -ireplace [regex]::Escape("ProDesk"), ""
$Modele = $Modele -ireplace [regex]::Escape("Non-Touch AiO"), "AiO"
$Modele = $Modele -ireplace [regex]::Escape("TouchAiO"), "AiO"
$Modele = $Modele -ireplace [regex]::Escape("Non-TouchAiO"), "AiO"
$Modele = $Modele -ireplace [regex]::Escape("TouchAiO"), "AiO"
$Modele = $Modele -ireplace [regex]::Escape("AiO"), "AiO"
$Modele = $Modele -ireplace [regex]::Escape("TWR"), ""
$Modele = $Modele -ireplace [regex]::Escape("23-in"), ""
$Modele = $Modele -ireplace [regex]::Escape("23.8"), ""
$Modele = $Modele -ireplace [regex]::Escape("RPC RETAIL SYSTEM"), "RP"
$Modele = $Modele -ireplace [regex]::Escape("RPS RETAIL SYSTEM"), "RP"
$Modele = $Modele -ireplace [regex]::Escape("Retail System Model"), ""
$Modele = $Modele -ireplace [regex]::Escape("Base Model System"), ""
$Modele = $Modele -ireplace [regex]::Escape("RETAIL SYSTEM"), ""
$Modele = $Modele -ireplace [regex]::Escape("Retail Model"), ""
$Modele = $Modele -ireplace [regex]::Escape("BASE MODEL"), ""
$Modele = $Modele -ireplace [regex]::Escape("RPCRETAIL YSTEM"), "RP"
$Modele = $Modele -ireplace [regex]::Escape("RPSRETAILSYSTEM"), "RP"
$Modele = $Modele -ireplace [regex]::Escape("RetailSystemModel"), ""
$Modele = $Modele -ireplace [regex]::Escape("BaseModelSystem"), ""
$Modele = $Modele -ireplace [regex]::Escape("RETAILSYSTEM"), ""
$Modele = $Modele -ireplace [regex]::Escape("RetailModel"), ""
$Modele = $Modele -ireplace [regex]::Escape("BASEMODEL"), ""
$Modele = $Modele -ireplace [regex]::Escape("NOTEBOOK"), ""
$Modele = $Modele -ireplace [regex]::Escape(" PC"), ""
$Modele = $Modele -ireplace [regex]::Escape("RP5 "), "RP"
$Modele = $Modele -ireplace [regex]::Escape(" POS"), ""
$Modele = $Modele -ireplace [regex]::Escape("MODEL "), ""
$Modele = $Modele -ireplace [regex]::Escape("Business System"), ""
$Modele = $Modele -ireplace [regex]::Escape("Wacom"), ""
$Modele = $Modele -ireplace [regex]::Escape("Mobile "), ""
$Modele = $Modele -ireplace [regex]::Escape("ThinkCentre"), ""
$Modele = $Modele -ireplace [regex]::Escape("ThinkPad"), ""
$Modele = $Modele -ireplace [regex]::Escape("15.6 Inch"), ""

$Modele = $Modele.replace(" ","")


If (!(test-path "c:\drivers")) { New-Item -Path "c:\drivers" -ItemType directory }

$ModeleFull = $path+"\"+$Marque+"_"+$Modele
#exit 0
write-host "x:\windows\system32\robocopy.exe ""$ModeleFull"" c:\drivers /MIR /R:3"
Start-Process -FilePath "x:\windows\system32\robocopy.exe" -ArgumentList """$ModeleFull"" c:\drivers /MIR /R:3" -wait -PassThru

#exit 0
write-host "x:\windows\system32\dism.exe /Image:C:\ /Add-Driver /Driver:c:\drivers /recurse"
Start-Process -FilePath "x:\windows\system32\dism.exe" -ArgumentList "/Image:C:\ /Add-Driver /Driver:c:\drivers /recurse" -wait -PassThru


Write-Output "x:\windows\system32\robocopy.exe ""$ModeleFull"" c:\drivers /MIR /R:3"            | Out-file "c:\drivers\Inject.log" -append
write-Output "x:\windows\system32\dism.exe /Image:C:\ /Add-Driver /Driver:c:\drivers /recurse"  | Out-file "c:\drivers\Inject.log" -append