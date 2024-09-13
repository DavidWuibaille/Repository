# Import the required modules
Import-Module Pode.Web
Import-Module SqlServer
 
# Start the Pode server
Start-PodeServer {
    Add-PodeEndpoint -Address * -Port 12176 -Protocol Http
 
	# invoke-RestMethod http://localhost:12176/GetName?macaddress=AZERTYUI 
    # Define the route to get the computer name based on the MAC address
    Add-PodeRoute -Method Get -Path '/GetName' -ScriptBlock {
        # Retrieve the MAC address from the query parameters
        $macaddress = $WebEvent.Query['macaddress']
        
		Write-Host "macaddress: $macaddress"
        Write-PodeJsonResponse -Value @{
            Computername   = "PC1234"
            Postype        = "ABCD"
        }
    }
	
	#Invoke-RestMethod http://localhost:12176/users/2
	Add-PodeRoute -Method Get -Path '/users/:userid' -ScriptBlock {
		$Valueuserid = $WebEvent.Parameters['userid']
		
		Write-Host "Valueuserid: $Valueuserid"	
		Write-PodeJsonResponse -Value @{
            Username   = "PC1234"
            Id        = $Valueuserid
        }
	}
	
	#iexplore http://localhost:12176
	Use-PodeWebTemplates -Title 'Leblogosd' -Theme Light

	Set-PodeWebHomePage -layouts @(
		New-PodeWebHero -Title 'Welcom david' -Message 'powershell is good ...'
	)
	
	Add-PodeWebPage -Name 'NewComputer' -DisplayName "New Computer" -Icon "server" -ScriptBlock {
		New-PodeWebForm -Name "New Computer" -Content @(
			New-PodeWebTextbox -Name "macaddress" -Displayname "MacAddress"
			New-PodeWebTextbox -Name "computername" -Displayname "Computer Name"
		) -ScriptBlock {
			$macaddress   = $WebEvent.Data['macaddress']
			$computername = $WebEvent.Data['computername']
			
			$macaddress = $macaddress.replace(":";"")
			$macaddress = $macaddress.replace("-";"")
			
			
			show-podeWebToast -Message "Add $computername" -Title "Info" -Duration 3000			
		}
	}
}