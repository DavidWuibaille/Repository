$taniumApiUrl = "https://xxxxxxxxx-api.cloud.tanium.com/api/v2"
$apiToken = "token-123456789123456789" # Replace with your API token

# Définir les en-têtes avec le token d'API
$headers = @{
    "session" = $apiToken
}

# Requête pour obtenir la liste des groupes d'ordinateurs
$response = Invoke-RestMethod -Uri "$taniumApiUrl/groups" -Method Get -Headers $headers -ContentType "application/json"

# Afficher les groupes d'ordinateurs
$response.data
