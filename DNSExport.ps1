#region GlobalVariables

#This section is for declaring all the variables used in the script.

#Set the Base URI to https://api.cloudflare.com/client/v4/zones/ as this will then be used during the API calls to get the zone ID and then get the associated records

$BaseURI = "https://api.cloudflare.com/client/v4/zones/"

#Never use hardcoded details in scripts.

$Email = ""

$ApiToken = ""

#Headers for auth:

#$Headers = "@{'X-Auth-Email'='$($Email)';'X-Auth-Key'='$($ApiToken)'}"

$Headers = @{
    'X-Auth-Email'=$Email;
    'X-Auth-Key'=$ApiToken
}

$Headers

#endregion GlobalVariables

#region GetZones

#This section is to get a list of all zones and their IDs for use in getting the DNS records

Invoke-RestMethod -Uri $BaseURI -Method Get -Headers $Headers | ConvertTo-Json -Depth 5

#endregion GetZones