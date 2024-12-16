#######################################################################################

# This script is licensed under the MIT License

#Copyright (c) 2024 gametech001

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

#######################################################################################

Write-Host "This script is for getting all DNS records for domains in CloudFlare via the API."

#region GlobalVariables

#This section is for declaring all the variables used in the script.

#Set the Base URI to https://api.cloudflare.com/client/v4/zones/ as this will then be used during the API calls to get the zone ID and then get the associated records

$BaseURI = "https://api.cloudflare.com/client/v4/zones/"

#Never use hardcoded details in scripts.
#Ideally get the API token from something like Azure Key Vault, Hashicorp Vault, Bitwarden Secrets Manager to ensure that the API token remains safe and secure.
#If the above isn't an option, then please enter the token below.

#Enter API token here:
$ApiToken = ""

#Headers for auth:

$Headers = @{"Authorization" = "Bearer $ApiToken"}

#endregion GlobalVariables

#region GetZones

#This section is to get a list of all zones and their IDs for use in getting the DNS records

#WIP - Check amount of domains

#$ZoneCount = Invoke-RestMethod -Uri $BaseURI -Method Get -Headers $Headers
#If ($ZoneCount.result_info.total_count -lt "1000"){
#}


#Set query to get max page size.

$ZoneUriQuery = $BaseURI+"?per_page=1000"

#Get the IDs of Zones for use in exporting DNS records:

$GetZones = Invoke-RestMethod -Uri $ZoneUriQuery -Method Get -Headers $Headers

$ZoneIDs = $GetZones.result.id
$ZoneName = $GetZones.result.name

#$ZoneIDs

#endregion GetZones

#$GetZones.result

#region GetDNSRecords

foreach ($Zone in $ZoneIDs){

    $Records = Invoke-RestMethod -Uri "$($BaseURI)/$Zone/dns_records/" -Method Get -Headers $Headers
    $Records.result | Select type,content,priority,proxiable,proxied,ttl,tags,comment | Export-csv D:\Scripts\cloudflare.csv -Append -NoTypeInformation
}
#endregion GetDNSRecords

#$DNSRecords.result | Select type,content,priority,proxiable,proxied,ttl,tags,comment