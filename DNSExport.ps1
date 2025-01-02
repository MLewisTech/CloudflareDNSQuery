#region License

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

write-host "#######################################################################################`n`nMIT License

Copyright (c) 2024 gametech001

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the `"Software`"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED `"AS IS`", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#######################################################################################`n`n"

#endregion License

Write-Host "`nThis script is for getting all DNS records for domains in Cloudflare via the API.`n`nFor this script to run, you'll to create an API token in Cloudflare that has at least the following:`n`n1) Permissions - Zone.DNS.Read`n2) Zone Resources - Include all from an account`n`n"

#region GetVariables

#region GetApiTokenInput

#Check if API token is to hand
$ApiTokenQuery = Read-Host "Do you have an API token? Y/N"

#Check response of $ApiTokenQuery and proceed if yes.
if (($ApiTokenQuery -like "y") -or ($ApiTokenQuery -like "Yes")){

    #Get API token and store as $ApiTokenInput variable. Text masked to help keep details secure.
    $ApiTokenInput = Read-Host -prompt "Please enter your API token here" -MaskInput

    #Track times asked for API token.
    $ApiTokenAskCount = 1

    #If $ApiTokenInput is empty, then loop through 4 more times asking for the token before exiting.
    if ([string]::IsNullOrEmpty($ApiTokenInput)){
        while ($ApiTokenAskCount -le 4){
            $ApiTokenInput = Read-Host -prompt "`n`n[!] No API token has been entered!`n`n Please enter your API token here" -MaskInput 
            $ApiTokenAskCount++

            #Exit while loop if $ApiTokenInput is no longer empty and proceed with the rest of the script.
            if (!([string]::IsNullOrEmpty($ApiTokenInput))){break}
        }
        if ($ApiTokenAskCount -eq 5){
            Write-host "No API token has been entered after 5 attempts.`n`nIf you need help with generating an API token, please follow the Cloudflare docs at https://developers.cloudflare.com/fundamentals/api/get-started/create-token/.`n`nGoodbye."
            #Exit
        }
    }
    Write-host ""
}else{
    Write-host "Please run the script when you have an API token ready to go.`n`nIf you need help with generating an API token, please follow the Cloudflare docs at https://developers.cloudflare.com/fundamentals/api/get-started/create-token/"
    #Exit
}

#endregion GetApiTokenInput

#region GetZonesInput

$ZoneQuery = Read-host "By default, this script will get all records for all domains. Do you want to get the records for specific domains?`n [Y] Yes [N] No (Default)"

switch ($ZoneQuery){
    y {$Domains = Read-Host "Please enter a comma separated list of domains (E.g. example.co.uk,example.com,example.net,contoso.com,contoso.net)";$AllDomains = $false;$DomainArray = $Domains.Split(',');break}
    ye {$Domains = Read-Host "Please enter a comma separated list of domains (E.g. example.co.uk,example.com,example.net,contoso.com,contoso.net)";$AllDomains = $false;$DomainArray = $Domains.Split(',');break}
    yes {$Domains = Read-Host "Please enter a comma separated list of domains (E.g. example.co.uk,example.com,example.net,contoso.com,contoso.net)";$AllDomains = $false;$DomainArray = $Domains.Split(',');break}
    Default {Write-Host "All records for all domains will be retrieved. Proceeding.";$AllDomains = $true;break}
}

#endregion GetZonesInput

#region GetOutputFile

$OutputFileQuery = Read-Host "Do you want to save the output to a specific directory otherwise the output will be the working directory this script is ran from?`n [Y] Yes [N] No (Default)"

switch ($OutputFileQuery){
    y {$OutputDirectory = Read-Host "Please enter the file path here"}
    ye {$OutputDirectory = Read-Host "Please enter the file path here"}
    yes {$OutputDirectory = Read-Host "Please enter the file path here"}
    Default {Write-host "Outputting to the local working directory which is"}
}

#endregion GetOutputFile

#endregion GetVariables

#region GlobalVariables

#This section is for declaring all the variables used in the script.

#Set the Base URI to https://api.cloudflare.com/client/v4/zones/ as this will then be used during the API calls to get the zone ID and then get the associated records

$BaseURI = "https://api.cloudflare.com/client/v4/zones/"

#Never use hardcoded details in scripts.
#Ideally get the API token from something like Azure Key Vault, Hashicorp Vault, Bitwarden Secrets Manager to ensure that the API token remains safe and secure.

#Headers for auth:

$Headers = @{"Authorization" = "Bearer $ApiTokenInput"}

#endregion GlobalVariables

#region GetZones

#WIP
#Get total amount of zones if getting all domains.

If ($AllDomains -eq $true){
    $TotalDomains = (Invoke-RestMethod -Uri $BaseURI -Method Get -Headers $Headers).result_info.total_count
}


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