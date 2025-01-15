#region InitialSetup

#Start logging
$WorkingDir = Get-Location | Select-Object Path -ExpandProperty Path; $LogFile = $WorkingDir + "\Cloudflare_DNS_Export_Log_" + (get-date -format "yyyy-MM-ddTHHmmss") + ".txt"; Start-Transcript -Path $LogFile -IncludeInvocationHeader -Append | Out-Null

#endregion InitalSetup

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

#File output defaults:

$OutputFile = "Cloudflare_DNS_Export_"+(Get-Date -Format "yyyy-MM-ddTHHmm")+".csv"
$OutputDirectory = $WorkingDir

#Get working directory and save as variable for later use.

Write-host "By default, this script will output a .csv file to the working directory, which is $(Get-location)."
$OutputFileQuery = Read-Host "Do you want to change the directory or file name (if the directory doesn't exist, then this script will attempt to create it otherwise, it will fall back to the working location)?`n`n [Y] Yes [No]"

switch ($OutputFileQuery){
    y {$ChangeOutput = $true;break}
    ye {$ChangeOutput = $true;break} 
    yes {$ChangeOutput = $true;break} 
    Default {Write-host "No option selected or invalid option entered. Setting default directory to be $($WorkingDir).`n`nSetting default output file name to be $($DefaultOutputFile)."; $ChangeOutput = $false;break}
}

#File and path checks and handling

#Future - May look at moving the below to a function to call from the above switch block for each statement

#Get new file/path.

if ($ChangeOutput -eq $true){
    Write-host "To change just the path only, end with a backslash (e.g. C:\Cloudflare_DNS_Export\).`nOtherwise the script will assume that the last item is the file name (e.g. C:\Cloudflare_DNS_Export\Output)."
    $DesiredOutputDestination = Read-Host "Please enter the path and file location here"
    if ($null -eq $DesiredOutputDestination){
        write-host "No file path/filename has been entered. Using default directory and file name."
        $ChangeOutput = $false
    } 
}

#Check if using the working directory or if using new directory.
try{
    if ($ChangeOutput -eq $false){
        $OutputDirectory = $WorkingDir
        $OutputFile = $DefaultOutputFile
    }
    #If using different directory, then check to see if $DesiredOutputDestination is path only or path and file.
    else{
        if ($DesiredOutputDestination.EndsWith("\")){
            Write-Host "It looks like you want to use a new path for the output file.`n`nChecking to see if the path exists and attempting to create it if not.`nIf the script is unable to create the path, then it will fall back to the working directory."
            #Check if directory already exists and attempt to create it not. 
            #Fall back to using working directory if unable to create new directory.
            if (!(test-path $DesiredOutputDestination)){
                try {
                    New-Item -ItemType Directory -Path $DesiredOutputDestination -Force | Out-Null
                }
                catch {
                    mkdir -Path $DesiredOutputDestination -Force | Out-Null
                }
                if (Test-Path $DesiredOutputDestination){
                    Write-host "Successfully created $($DesiredOutputDestination). Proceeding."
                    $OutputDirectory = $DesiredOutputDestination
                }else{
                    Write-Host "Failed to create $($DesiredOutputDestination). Defaulting to the working directory."
                    $OutputDirectory = $WorkingDir
                }
            }else{
                Write-host "$($DesiredOutputDestination) already exists. Proceeding."
                $OutputDirectory = $DesiredOutputDestination
            }
        }
        #If $DesiredOutputDestination doesn't end with a "\", then assume file. 
        else{
                #Check if file ends in an extension or if it is just a file name.
                #If just a file name, then add ".csv" as the extension.
                $OutputDirectoryCheck = (Split-Path $DesiredOutputDestination -Parent)
                if (!($DesiredOutputDestination.extension)){
                    $OutputFile = (Split-Path $DesiredOutputDestination -Leaf)+".csv"
                    if (!(Test-Path $OutputDirectoryCheck)){
                        try {
                            New-Item -ItemType Directory -Path $DesiredOutputDestination -Force | Out-Null
                        }
                        catch {
                            mkdir -Path $DesiredOutputDestination -Force | Out-Null
                        }
                        if (Test-Path $OutputDirectoryCheck){
                            Write-host "Successfully created $($OutputDirectoryCheck). Proceeding."
                            $OutputDirectory = $OutputDirectoryCheck
                        }else{
                            Write-Host "Failed to create $($OutputDirectoryCheck). Defaulting to the working directory."
                            $OutputDirectory = $WorkingDir
                        }
                    }else{
                        Write-host "$($OutputDirectoryCheck) already exists. Proceeding."
                        $OutputDirectory = $OutputDirectoryCheck
                    }        
                }else{
                    $OutputFile = (Split-Path $DesiredOutputDestination -Leaf)
                    if (!(Test-Path $OutputDirectoryCheck)){
                        try {
                            New-Item -ItemType Directory -Path $DesiredOutputDestination -Force | Out-Null
                        }
                        catch {
                            mkdir -Path $DesiredOutputDestination -Force | Out-Null
                        }
                        if (Test-Path $OutputDirectoryCheck){
                            Write-host "Successfully created $($OutputDirectoryCheck). Proceeding."
                            $OutputDirectory = $OutputDirectoryCheck
                        }else{
                            Write-Host "Failed to create $($OutputDirectoryCheck). Defaulting to the working directory."
                            $OutputDirectory = $WorkingDir
                        }
                    }else{
                        Write-host "$($OutputDirectoryCheck) already exists. Proceeding."
                        $OutputDirectory = $OutputDirectoryCheck
                    }
                }    
            }
        }
    }
catch{
    Write-Host "Sorry. Something went wrong.`n`nDefaulting output directory and file to $($OutputDirectory)\$($OutputFile)."
}

$FullOutputPath = $OutputDirectory+"\"+$OutputFile

#endregion GetOutputFile

#endregion GetVariables

#region APIGlobalVariables

#This section is for declaring all the variables used in the script.

#Set the Base URI to https://api.cloudflare.com/client/v4/zones/ as this will then be used during the API calls to get the zone ID and then get the associated records

$BaseURI = "https://api.cloudflare.com/client/v4/zones/"

#Headers for auth:

$Headers = @{"Authorization" = "Bearer $ApiTokenInput"}

#Get Zone Info:

$ZoneData = Invoke-RestMethod -Uri $BaseURI -Method Get -Headers $Headers

#endregion APIGlobalVariables

#region ExportDNSRecords

#Get total amount of zones if getting all domains.

If ($AllDomains -eq $true){
    If ($ZoneData.result_info.total_count -gt 10){
        foreach ($page in $TotalPages){
            $TotalPages = $ZoneData.result_info.total_pages
            $ZoneIDs = $GetZones.result.id
            $ZoneName = $GetZones.result.name
            foreach ($Zone in $ZoneIDs){
                write-host "Getting DNS records for $($ZoneName)"
                $Records = "$($BaseURI)/$Zone/dns_records/"
                $Records = Invoke-RestMethod -Uri "$($BaseURI)/$Zone/dns_records/" -Method Get -Headers $Headers
                $Records.result | Select-Object type,content,priority,proxiable,proxied,ttl,tags,comment | Export-csv D:\Scripts\cloudflare.csv -Append -NoTypeInformation
            }
        }
    }
}

#Set query to get max page size.

$ZoneUriQuery = $BaseURI+"?per_page=1000"

#Get the IDs of Zones for use in exporting DNS records:

$GetZones = Invoke-RestMethod -Uri $ZoneUriQuery -Method Get -Headers $Headers

$ZoneIDs = $GetZones.result.id
$ZoneName = $GetZones.result.name

#$ZoneIDs

#endregion ExportDNSRecords



#######################################################################################################################################################################################################################

#$GetZones.result

#region GetDNSRecords

foreach ($Zone in $ZoneIDs){

    $Records = Invoke-RestMethod -Uri "$($BaseURI)/$Zone/dns_records/" -Method Get -Headers $Headers
    $Records.result | Select-Object type,content,priority,proxiable,proxied,ttl,tags,comment | Export-csv D:\Scripts\cloudflare.csv -Append -NoTypeInformation
}
#endregion GetDNSRecords

#$DNSRecords.result | Select type,content,priority,proxiable,proxied,ttl,tags,comment

#End logging
Stop-Transcript