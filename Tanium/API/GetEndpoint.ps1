$taniumApiUrl = "https://xxxxxxxxx-api.cloud.tanium.com/api/v2"
$apiToken = "token-123456789123456789" # Replace with your API token

# Définir les en-têtes avec le token d'API
$headers = @{
    "session" = $apiToken
}

# Spécifiez l'ID de l'endpoint pour lequel vous voulez des détails
$endpointId = "123456"

# Envoyer la requête pour obtenir les détails de l'endpoint
$response = Invoke-RestMethod -Uri "$taniumApiUrl/endpoints/$endpointId" -Method Get -Headers $headers -ContentType "application/json"

# Afficher les détails de l'endpoint
$response
