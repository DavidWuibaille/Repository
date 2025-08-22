# Import the required modules
Import-Module -name pode, Pode.Web
Import-Module SqlServer
 
# Start the Pode server
Start-PodeServer {
    Add-PodeEndpoint -Address * -Port 12176 -Protocol Http
	
	New-PodeLoggingMethod -File -name 'c:\temp\webserror.log' | Enable-PodeErrorLogging -level @("Error", "Warning")
 
    # Define the route to get the computer name based on the MAC address
    Add-PodeRoute -Method Get -Path '/GetName' -ScriptBlock {
        $macaddress = $WebEvent.Query['macaddress']
        Write-Host "MAC Address: $macaddress"
 
		#Invoke-RestMethod -Uri 'http://localhost:12176/GetName?macaddress=000000000000' -Method Get
        $computername = "Not found"
		$csvline = get-content -Path "c:\temp\newcomputer.csv"
		$result = $csvline | ForEach-Object {
			$colonne = $_ -split ','
			if ($colonne[0] -eq $macaddress) {
				$computername = $colonne[1]
				$Postype      = $colonne[2]
			}
		}

        Write-host "Return : $computername"
        Write-PodeJsonResponse -Value @{
            Computername   = $computername
            Postype = $Postype
        }
    }
	
	#iexplore http://localhost:12176
	Use-PodeWebTemplates -Title 'leblogosd' -Theme Light
	
	# Add link Head web page
	$navdiv = New-PodeWebNavDivider
	$Navblog = New-PodeWebNavLink -Name 'Blog'   -Url 'https://blog.wuibaille.fr'         -Icon 'server' -Newtab
	$NavGit = New-PodeWebNavLink  -Name 'Github' -Url 'https://github.com/DavidWuibaille' -Icon 'github' -Newtab	
	Set-PodeWebNavDefault -Items $Navblog, $navdiv, $NavGit

	Set-PodeWebHomePage -layouts @(
		New-PodeWebHero -Title 'Welcome' -Message 'Team Cash'
	)
	
	Add-PodeWebPage -Name 'AddComputer' -DisplayName "Add Computer" -Icon "server" -ScriptBlock {
		New-PodeWebForm -Name "Add Computer" -Content @(
			New-PodeWebTextbox -Name "macaddress" -Displayname "MacAddress"
			New-PodeWebTextbox -Name "computername" -Displayname "Computer Name"
			New-PodeWebTextbox -Name "postype" -Displayname "postype"			
		) -ScriptBlock {
			$macaddress   = $WebEvent.Data['macaddress']
			$computername = $WebEvent.Data['computername']
			$postype      = $WebEvent.Data['postype']
			$macaddress = $macaddress.replace(":", "").replace("-", "")

			if ($macaddress -ne "" -and $computername -ne "" -and $postype -ne "") {
				$csvData = "c:\temp\newcomputer.csv"

				$csvLines = "$macaddress"+ "," + $computername + "," + $postype
				$csvLines | Add-Content -Path $csvData

				Show-PodeWebToast -Message "Le $computername a ete ajoute." -Title "Info" -Duration 3000
			} Else {	
				Show-PodeWebToast -Message "MacAddress et Computer Name ne doivent pas etre vides." -Title "Erreur" -Duration 3000
			}
			

		}
	}
	
	
	
	Add-PodeWebPage -Name 'GetComputer' -DisplayName "Get Computer" -Icon "server" -ScriptBlock {
		New-PodeWebForm -Name "Get Computer" -Content @(
			New-PodeWebTextbox -Name "computername" -Displayname "Computer Name"			
		) -ScriptBlock {
			$computername = $WebEvent.Data['computername']
			
			if ($computername -ne "") {
				$macaddress = "notfound"
				$Postype    = "notfound"
				$csvline = get-content -Path "c:\temp\newcomputer.csv"
				$result = $csvline | ForEach-Object {
					$colonne = $_ -split ','
					if ($colonne[1] -eq $computername) {
						$macaddress   = $colonne[0]
						$Postype      = $colonne[2]
					}
				}

				Show-PodeWebToast -Message "$computername $macaddress $Postype" -Title "Get Info" -Duration 5000
			} Else {	
				Show-PodeWebToast -Message "Computer Name ne doit pas etre vide." -Title "Erreur" -Duration 5000
			}
			

		}
	}


	Add-PodeWebPage -Name 'GetComputer2' -DisplayName "Get Computer2" -Icon "server" -ScriptBlock {
		new-podeWebcontainer -Content @(
			New-podeWebTable -Name 'CSVcontent' -CsvFilePath "c:\temp\newcomputer.csv" -SimpleFilter
		)
	}
	
	
	Add-PodeWebPage -Name 'GetComputer3' -DisplayName "Get Computer3" -Icon "server" -ScriptBlock {
		New-PodeWebContainer -Content @(
			New-PodeWebTable -Name 'Computer' -Sort -AsCard -SimpleFilter -ScriptBlock {
				# Define the file path
				$filePath = 'C:\temp\newcomputer.csv'
				$data = Import-Csv -Path $filePath -Delimiter ',' # Assuming comma delimiter

				# Apply sorting if specified
				$sortColumn = $WebEvent.Data.SortColumn
				if (![string]::IsNullOrWhiteSpace($sortColumn)) {
					$data = @($data | Sort-Object -Property { $_.$sortColumn } -Descending:$descending)
				}

				# Return the data to update the table
				return $data
			}
		)
	}


	
	Add-PodeWebPage -Name 'Exemple1' -DisplayName "zz Exemple option" -Icon "server" -ScriptBlock {
		new-podeWebcontainer -Content @(
			New-PodeWebForm -Name "Options" -Content @(
				#New-PodeWebRadio -Name "options" -Options @("optionA","optionB","optionC","optionD")
				#New-PodeWebRadio -Name "options" -Options @("optionA","optionB","optionC","optionD") -Multiple				
				New-PodeWebCheckbox -Name "options" -Options @("optionA","optionB","optionC","optionD")		
			) -scriptBlock {
				$AllOptions = $WebEvent.data.Options.Split(',')		
				if ($AllOptions.contains("optionA")) {
					Write-host "If OptionA"
				}	
			}
		)
	}
	
	<#
	Add-PodeWebPage -Name 'Exemple2' -DisplayName "zz Exemple UpdateValue" -Icon "server" -ScriptBlock {
		new-podeWebcontainer -Content @(
			New-PodeWebForm -Name "Value" -Content @(
				New-PodeWebTextbox -Name "ChangeValue"
			) -scriptBlock {
				$getvalue = $WebEvent.Data['ChangeValue']
				write-host $getvalue
				Update-PodeWebTextbox -Value "Myscriptvalue" -Name "ChangeValue"
			}
		)
	}
	#>	
	
	Add-PodeWebPage -Name 'Process' -Scriptblock {
		new-podeWebcontainer -Content @(
			New-PodeWebChart -Name 'Top Process' -Type Bar -AutoRefresh -ScriptBlock {
				Get-Process |
				Sort-Object -Property CPU -Descending |
				Select-Object -First 10 |
				ConvertTo-PodeWebChartData -LabelProperty ProcessNAme -DatasetProperty CPU, Handles
				
			}
		)
	}
	
}