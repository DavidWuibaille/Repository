$taniumApiUrl = "https://xxxxxxxxx-api.cloud.tanium.com/api/v2"
$apiToken = "token-123456789123456789" # Replace with your API token
# Define the headers with the API token
$headers = @{
    "session" = $apiToken
}
# Query to list computers with their IP addresses
$queryBody = @{
    "query_text" = "Get Computer Name and IP Address and Operating System from all machines" # Dynamically ask a question via the Tanium API
}
# Send the request to the API to execute the question
$response = Invoke-RestMethod -Uri "$taniumApiUrl/questions" -Method Post -Headers $headers -Body ($queryBody | ConvertTo-Json) -ContentType "application/json"
# Extract the ID of the asked question
$questionId = $response.data.id

Start-sleep -Seconds 10

$allResults = @()
# Check the results of the asked question (this may take some time depending on the size of the environment)
$resultsUri = "$taniumApiUrl/result_data/question/$questionId"
$responseResults = (Invoke-RestMethod -Uri $resultsUri -Method Get -Headers $headers ).Data
# Loop through the results and display the computer names and IP addresses
foreach ( $resultRow in $responseResults.result_sets.rows ) {
    $row = @{}
   
    for ( $i = 0; i -lt $responseResults.result_sets.columns.Count; i++ ) {
        $row.Add($responseResults.result_sets.columns[$i].name, ($ResultRow.data[$i].text))
    }
   
    $allResults += [PSCustomObject]$row
}
$allResults
