$Count   = 1
$Total   = $OrdinateurClient.Rows.Count
foreach ($OrdinateurIP in $OrdinateurClient) {
    Write-Progress -Activity "Processing " -status "Computers : $Count / $Total" -PercentComplete ($Count / $Total * 100) -Id 1
    $Count               += 1
    $Nom                = $OrdinateurIP."DISPLAYNAME"
     
    }
}
Write-Progress -Activity 'Processing' -Completed -Id 1