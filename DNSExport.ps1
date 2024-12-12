#region GlobalVariables

#This section is for declaring all the variables used in the script.

$BaseURI = "https://api.cloudflare.com/client/v4"

#Never use hardcoded details in scripts.

$Email = ""

$ApiToken = ""

#Headers for auth:

$Headers = "@{'X-Auth-Email'='$($Email)';'X-Auth-Key'='$($ApiToken)'}"

#endregion GlobalVariables

$Headers