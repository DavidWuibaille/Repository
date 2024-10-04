$taniumApiUrl = "https://xxxxxxxxx-api.cloud.tanium.com/api/v2"
$apiToken = "token-123456789123456789" # Replace with your API token

# Définir les en-têtes avec le token d'API
$headers = @{
    "session" = $apiToken
}

# Définir le corps de la requête pour créer un groupe d'ordinateurs
$groupBody = @{
    "name" = "My_New_Computer_Group"
    "filter" = @{
        "operator" = "and"
        "sub_filters" = @(
            @{
                "sensor" = "Operating System"
                "operator" = "contains"
                "value" = "Windows"
            }
        )
    }
}

# Envoyer la requête à l'API pour créer un groupe d'ordinateurs
$response = Invoke-RestMethod -Uri "$taniumApiUrl/groups" -Method Post -Headers $headers -Body ($groupBody | ConvertTo-Json) -ContentType "application/json"

# Afficher la réponse de l'API
$response
