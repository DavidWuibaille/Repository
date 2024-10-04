$taniumApiUrl = "https://xxxxxxxxx-api.cloud.tanium.com/api/v2"
$apiToken = "token-123456789123456789" # Replace with your API token

# Définir les en-têtes avec le token d'API
$headers = @{
    "session" = $apiToken
}

# Spécifiez le nom du package à déployer et l'ID du groupe d'ordinateurs
$packageId = "456789"
$groupId = "123456"

# Créer le corps de la requête pour le déploiement
$deploymentBody = @{
    "package_spec_id" = $packageId
    "target_group_id" = $groupId
}

# Envoyer la requête pour déployer le package
$response = Invoke-RestMethod -Uri "$taniumApiUrl/packages/deployments" -Method Post -Headers $headers -Body ($deploymentBody | ConvertTo-Json) -ContentType "application/json"

# Afficher la réponse de l'API
$response
