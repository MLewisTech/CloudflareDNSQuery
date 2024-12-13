#region GlobalVariables

#This section is for declaring all the variables used in the script.

#Set the Base URI to https://api.cloudflare.com/client/v4/zones/ as this will then be used during the API calls to get the zone ID and then get the associated records

$BaseURI = "https://api.cloudflare.com/client/v4/zones/"

#Never use hardcoded details in scripts.
#Ideally get the API token from something like Azure Key Vault, Hashicorp Vault, Bitwarden Secrets Manager to ensure that the API token remains safe and secure.

#Enter API token here:
$ApiToken = ""

#Headers for auth:

$Headers = @{"Authorization" = "Bearer $ApiToken"}

$Headers

#endregion GlobalVariables

#region GetZones

#This section is to get a list of all zones and their IDs for use in getting the DNS records

#Set query to get max page size.

$ZoneUriQuery = $BaseURI+"?per_page=1000"

$GetZones = Invoke-RestMethod -Uri $ZoneUriQuery -Method Get -Headers $Headers | ConvertTo-Json -Depth 5 -AsArray | ConvertFrom-Json -Depth 5 -AsHashtable

#endregion GetZones

$GetZones.result | Out-File D:\Scripts\CloudFlare.txt

$GetZones.result_info