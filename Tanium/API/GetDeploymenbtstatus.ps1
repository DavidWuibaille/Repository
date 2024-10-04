$taniumApiUrl = "https://xxxxxxxxx-api.cloud.tanium.com/api/v2"
$apiToken = "token-123456789123456789" # Replace with your API token

# Définir les en-têtes avec le token d'API
$headers = @{
    "session" = $apiToken
}

# Envoyer la requête pour obtenir le statut des déploiements
$response = Invoke-RestMethod -Uri "$taniumApiUrl/packages/deployments/status" -Method Get -Headers $headers -ContentType "application/json"

# Afficher le statut des déploiements
$response.data
