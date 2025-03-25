#region InitialSetup

#This region is to do inital setup of the console/script.

#Get original console colours

$CurrentPSBackgroundColour = $Host.UI.RawUI.BackgroundColor
$CurrentPSForegroundColour = $Host.UI.RawUI.ForegroundColor

#Set console colours for session

$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'White'

#Clear console
Clear-Host

#endregion InitalSetup

#region APIGlobalVariables

#This section is for declaring all the variables used in the script.

#Set the Base URI to https://api.cloudflare.com/client/v4/zones/ as this will then be used later on during the script

$BaseURI = "https://api.cloudflare.com/client/v4/zones/"

#endregion APIGlobalVariables

#region License

#MIT license.

write-host -ForegroundColor Green "`n#######################################################################################"

Write-host "`nMIT License

Copyright (c) 2025 gametech001

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
SOFTWARE.`n"

Write-Host -ForegroundColor Green "#######################################################################################`n"

#endregion License

#Token requirements

Write-Host "This script is for getting all DNS records for domains in Cloudflare via the API.`n`nFor this script to run, you'll to create an API token in Cloudflare that has at least the following:`n`n1) Permissions - Zone.DNS.Read`n2) Zone Resources - Include all from an account`n"
Write-Host -ForegroundColor Green "#######################################################################################`n"
Pause
write-host ""
#region GetVariables

#region GetApiTokenInput

#Check if API token is to hand
$ApiTokenQuery = Read-Host "Do you have an API token?`n[Y] Yes [N] No (Default)"

#Handling of API token input
switch ($ApiTokenQuery){
    y {$ApiTokenPrompt = $true;break}
    ye {$ApiTokenPrompt = $true;break}
    yes {$ApiTokenPrompt = $true;break}
    Default { 
        Write-host -ForegroundColor Red "`nPlease run the script when you have an API token ready to go.`n`nIf you need help with generating an API token, please follow the Cloudflare docs at https://developers.cloudflare.com/fundamentals/api/get-started/create-token`n"
        Exit
    }
}

#Check response of $ApiTokenQuery and proceed if $ApiTokenPrompt -eq $true
if ($ApiTokenPrompt -eq $true){

    #Set $ApiTokenInput to $null for initial token prompt
    $ApiTokenInput = $null

    #Set $ApiCount to 0. This is used for tracking amount of API requests within a set interval (normally 1200 requests with a 5 minute period) to avoid hitting the API limits Cloudflare have. See https://developers.cloudflare.com/fundamentals/api/reference/limits/ for more information.
    $ApiCount = 0

    #Sert initial $TimeStamp for API limit
    $TimeStamp = Get-Date

    #Whilst $ApiTokenInput -eq $null, keep looping through to prompt user for the API token.
    while([string]::IsNullOrEmpty($ApiTokenInput)){

        #Check for API limit and exit if 1200 requests have been made within 5 minutes.
        if (($ApiCount -ge 1200)-and ($TimeStamp -lt $TimeStamp.AddMinutes(5))){
            write-host -ForegroundColor Red "[!] Warning. An incorrect API token has been entered 1200 times within a 5 minute period.`n`nPlease run the script when you have an API token ready to go.`n`nIf you need help with generating an API token, please follow the Cloudflare docs at https://developers.cloudflare.com/fundamentals/api/get-started/create-token/."
            Exit
        }

        #Requirements for API token.
        Write-Host -ForegroundColor Green "`n#######################################################################################`n"
        Write-host -ForegroundColor Yellow "Please note that you'll need the following API permissions to use this script: `n`n1) Permissions - Zone.DNS.Read`n2) Zone Resources - Include all from an account`n"
        Write-host -ForegroundColor Yellow "Please follow the Cloudflare docs at https://developers.cloudflare.com/fundamentals/api/get-started/create-token to create an API token.`n"

        #Prompt user for API token.
        $ApiTokenInput = Read-Host -prompt "Please enter your API token here" 

        #Check if $ApiTokenInput is not $null.
        if (!([string]::IsNullOrEmpty($ApiTokenInput))){
            Write-host "`nChecking if API token is valid.`n"

            #Set headers for API requests. Will be used later in script as well.
            $Headers = @{"Authorization" = "Bearer $ApiTokenInput"}

            #Try invoke-webrequest with $BaseURI, GET method and $Headers then get response code as $StatusCode.
            #If $StatusCode -eq 200, then API token is valid. Otheriwse, the API token is invalid and the loop resets with $ApiTokenInput being reset to $null.
            #Each attempt (successful or not) increments the $ApiCount counter ($ApiCount++).
            try{
                $TestHeaders = Invoke-Webrequest -Uri $BaseURI -Method Get -Headers $Headers
                $StatusCode = $TestHeaders.StatusCode
            }catch {
                $StatusCode = $_.Exception.Response.StatusCode.value__
            }
            if ($StatusCode -eq "200"){
                Write-host "API token is valid. Proceeding.`n"
                $ApiCount++
                break
            }else{
                Write-host -ForegroundColor Red "Invalid API token entered. Please try again."
                $ApiTokenInput = $null
                $ApiCount++
            }
        }
    }
}
#endregion GetApiTokenInput

Write-Host -ForegroundColor Green "#######################################################################################`n"

#region GetZonesInput

#This region is for getting the zone(s) in Cloudflare to get the DNS records for.
#First, prompt user if they want to get all zones (default) or specific zones.

$ZoneQuery = Read-host "By default, this script will get all records for all domains. Do you want to get the records for specific domains?`n[Y] Yes [N] No (Default)"
Write-host ""
switch ($ZoneQuery){
    y {$AllDomains = $false;break}
    ye {$AllDomains = $false;break}
    yes {$AllDomains = $false;break}
    Default {Write-Host "All records for all domains will be retrieved. Proceeding.";$AllDomains = $true;break}
}

#Error handing if nothing has been entered.
if ($Domains -eq ""){
    Write-host -ForegroundColor Red "`n[!] No domains have been entered.`n`n`Defaulting to getting all domains."
    $AllDomains = $true
}

#Check how the user wants to input the zones into the script (either via .csv/.txt file or manaully by typing them in)
if ($AllDomains -eq $false){
    
    #Check for .csv or .txt input.
    #If no file to use for the zones, then default to manually asking user for input of comma separated domains.
    switch ($DomainInputQuery = Read-host "Do you have a .csv or .txt file containing the domains you want to export records for? `n[Y] Yes [N] No (Default)"){
        y {$ImportFromFile = $true;break}
        ye {$ImportFromFile = $true;break}
        yes {$ImportFromFile = $true;break}
        Default {
            #Enter a comma separated list of domains here (E.g. example.co.uk,example.com,example.net,contoso.com,contoso.net), then check to see if the list is empty.
            #If the list is empty, then keep looping through to prompt user to enter domains.
            #No API limit will be hit here, so loop can go on forever (may need to add handling to prevent this if needed but ctrl + c will exit it and stop the script).
            $ManualDomainInput = Read-Host "`nPlease enter a comma separated list of domains here (E.g. example.co.uk,example.com,example.net,contoso.com,contoso.net)"
            while([string]::IsNullOrEmpty($ManualDomainInput)){
                Write-host -ForegroundColor Red "`n[!] No domains have been entered.`n`nPlease try again."
                $ManualDomainInput = Read-Host "`nPlease enter a comma separated list of domains here (E.g. example.co.uk,example.com,example.net,contoso.com,contoso.net)"
            }
            #Check if $ManualDomainInput is empty and if not, then split the domains into an array (split by a comma ",").
            if (!([string]::IsNullOrEmpty($ManualDomainInput))){
                $AllDomains = $false
                $DomainArray = $ManualDomainInput.Split(',')
            }
        }
    }
}

#Handling for if import from file was selected.
#Import from file will open File Explore window to allow user to browse to the file.
if($ImportFromFile -eq $true){

    #Open File Explorer file picker with filter set to .txt or .csv files.
    Add-Type -AssemblyName System.Windows.Forms
    $FileInputPicker = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
        Filter = 'Text files (*.txt)|*.txt|CSV files (*.csv)|*.csv'
    }
    $null = $FileInputPicker.ShowDialog()

    #Save file from File Explorer picker to variable name.
    $ChosenFile = $FileInputPicker.filename

    #Try and check if the file ends with .csv or .txt and save contents to $DomainArray.
    #Otherwise, catch handling and fall back to manual file entry loop. 
    try{
        if ($ChosenFile.EndsWith(".csv")){
            $DomainArray = (Import-Csv -path $ChosenFile) | Select-Object -ExpandProperty *
            $AllDomains = $false
            Write-host "`nThe input file to be used is $($ChosenFile).`n"
        }
        if($ChosenFile.EndsWith(".txt")){
            $DomainArray = Get-Content -path $ChosenFile
            $AllDomains = $false
            Write-host "`nThe input file to be used is $($ChosenFile).`n"
        }   
    }
    catch{
        Write-host -ForegroundColor Red "`nNo file selected/invalid file type selected. Defaulting to manual entry." 
        $ManualDomainInput = Read-Host "`nPlease enter a comma separated list of domains here (E.g. example.co.uk,example.com,example.net,contoso.com,contoso.net)"
        while([string]::IsNullOrEmpty($ManualDomainInput)){
            Write-host -ForegroundColor Red "`n[!] No domains have been entered.`n`nPlease try again."
            $ManualDomainInput = Read-Host "`nPlease enter a comma separated list of domains here (E.g. example.co.uk,example.com,example.net,contoso.com,contoso.net)"
        }
        #Check if $ManualDomainInput is empty and if not, then split the domains into an array (split by a comma ",").
        if (!([string]::IsNullOrEmpty($ManualDomainInput))){
            $AllDomains = $false
            $DomainArray = $ManualDomainInput.Split(',')
        }
    }
}
#endregion GetZonesInput

Write-Host -ForegroundColor Green "`n#######################################################################################`n"

#region GetOutputFile

#File output defaults:

#Get working directory and save as variable for later use.
$WorkingDir = Get-Location | Select-Object Path -ExpandProperty Path

#Set default Outputs

$DefaultOutputFile = "Cloudflare_DNS_Export_"+(Get-Date -Format "yyyy-MM-ddTHHmm")+".csv"
$DefaultOutputDirectory = $WorkingDir

Write-host "By default, this script will output a .csv file to the working directory, which is $(Get-location).`n"
$OutputFileQuery = Read-Host "Do you want to change the directory or file name? If the directory doesn't exist, then this script will attempt to create it otherwise, it will fall back to the working location?`n[Y] Yes [N] No (Default)"

switch ($OutputFileQuery){
    y {$ChangeOutput = $true;break}
    ye {$ChangeOutput = $true;break} 
    yes {$ChangeOutput = $true;break} 
    Default {Write-host  -ForegroundColor Red "`n[!] No option selected or invalid option entered.`n`nSetting default directory to be $($DefaultOutputDirectory).`n`nSetting default output file name to be $($DefaultOutputFile)."; $ChangeOutput = $false;break}
}

#File and path checks and handling

#Future - May look at moving the below to a function to call from the above switch block for each statement

#Get new file/path.

if ($ChangeOutput -eq $true){
    Write-host "`nTo change just the path only, end with a backslash (e.g. C:\Cloudflare_DNS_Export\).`nOtherwise the script will assume that the last item is the file name (e.g. C:\Cloudflare_DNS_Export\Output)."
    $DesiredOutputDestination = Read-Host "Please enter the path and file location here"
    if ($null -eq $DesiredOutputDestination){
        write-host "No file path/filename has been entered. Using default directory and file name."
        $ChangeOutput = $false
    } 
}

#Check if using the working directory or if using new directory.
try{
    if ($ChangeOutput -eq $false){
        $OutputDirectory = $DefaultOutputDirectory
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
                    Write-Host -ForegroundColor Red "Failed to create $($DesiredOutputDestination). Defaulting to the working directory."
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
                            Write-Host -ForegroundColor Red "Failed to create $($OutputDirectoryCheck). Defaulting to the working directory."
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
                            Write-Host -ForegroundColor Red "Failed to create $($OutputDirectoryCheck). Defaulting to the working directory."
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
    $OutputDirectory = $WorkingDir
    $OutputFile = $DefaultOutputFile
    Write-Host -ForegroundColor Red "[!] Sorry. Something went wrong.`n`nDefaulting output directory and file to $($OutputDirectory)\$($DefaultOutputFile)."
}

$FullOutputPath = $OutputDirectory+"\"+$OutputFile

#endregion GetOutputFile

Write-Host -ForegroundColor Green "`n#######################################################################################`n"

#endregion GetVariables

#region ExportDNSRecords

#Get total amount of zones if getting all domains.

Write-host -ForegroundColor Blue "Starting export of DNS records.`n"
$TimeStamp = Get-Date

If ($AllDomains -eq $true){
    $PageQueryURI = $BaseURI+"?per_page=1000"
    $ZoneData = Invoke-RestMethod -Uri $PageQueryURI -Method Get -Headers $Headers
    $ZoneIDs = $ZoneData.result.id
    $ApiCount++
    If ($ZoneData.result_info.total_count -gt 1000){
        $TotalPages = $ZoneData.result_info.total_pages
        foreach ($page in $TotalPages){
            foreach ($ID in $ZoneIDs){
                if (($ApiCount -ge 1190)-and ($TimeStamp -lt $TimeStamp.AddMinutes(5))){
                    Write-host -ForegroundColor Red "[!] Warning. Approaching Cloudflare API limit of 1200 per 5 minute interval.`n`nSleeping for 5 minutes to ensure that the Cloudflare API limit isn't hit."
                    Write-host "`n`nScript will automatically resume after 5 minutes."
                    Start-Sleep -Seconds 300
                    $ApiCount = 0
                    $TimeStamp = Get-Date
                }
                $ZoneName = $ZoneData.result | Where-Object id -eq $ID | Select-Object name -ExpandProperty name
                Write-host "Getting DNS records for $ZoneName.`n"
                $RecordsURI = "$($BaseURI)$($ID)/dns_records/"
                $Records = Invoke-RestMethod -Uri $RecordsURI -Method Get -Headers $Headers
                $ApiCount++
                if($Records.result_info.total_count -eq 0){
                    Write-host -ForegroundColor Red "No records exist for $($ZoneName).`n"
                }
                else{
                    foreach($Record in $Records.result){
                        $RecordOutPut = [pscustomobject]@{
                        Domain = $ZoneName
                        Name = $Record.name                 
                        Type = $Record.type
                        Content = $Record.content
                        Priority = $Record.priority
                        Proxiable = $Record.proxiable
                        Proxied = $Record.proxied
                        TTL = $Record.ttl
                        Comment = $Record.comment
                        }
                        $RecordOutPut | Export-Csv $FullOutputPath -NoTypeInformation -Append
                    }
                } 
            }
        }
    }else{
        foreach ($ID in $ZoneIDs){
            if (($ApiCount -ge 1190)-and ($TimeStamp -lt $TimeStamp.AddMinutes(5))){
                Write-host -ForegroundColor Red "[!] Warning. Approaching Cloudflare API limit of 1200 per 5 minute interval.`n`nSleeping for 5 minutes to ensure that the Cloudflare API limit isn't hit."
                Write-host "`n`nScript will automatically resume after 5 minutes."
                Start-Sleep -Seconds 300
                $ApiCount = 0
                $TimeStamp = Get-Date
            }
            $ZoneName = $ZoneData.result | Where-Object id -eq $ID | Select-Object name -ExpandProperty name
            Write-host "Getting DNS records for $ZoneName.`n"
            $RecordsURI = "$($BaseURI)$($ID)/dns_records/"
            $Records = Invoke-RestMethod -Uri $RecordsURI -Method Get -Headers $Headers
            $ApiCount++
            if($Records.result_info.total_count -eq 0){
                Write-host -ForegroundColor Red "No records exist for $($ZoneName).`n"
            }
            else{
                foreach($Record in $Records.result){
                    $RecordOutPut = [pscustomobject]@{
                    Domain = $ZoneName
                    Name = $Record.name                 
                    Type = $Record.type
                    Content = $Record.content
                    Priority = $Record.priority
                    Proxiable = $Record.proxiable
                    Proxied = $Record.proxied
                    TTL = $Record.ttl
                    Comment = $Record.comment
                    }
                    $RecordOutPut | Export-Csv $FullOutputPath -NoTypeInformation -Append
                }
            } 
        }
    }
}else{
    $ListOfTLDsWithHeaders = (Invoke-WebRequest -uri "https://data.iana.org/TLD/tlds-alpha-by-domain.txt").Content -split "`n"
    $TLDsNoHeaders = ($ListOfTLDsWithHeaders[1..$ListOfTLDsWithHeaders.Length])
    foreach ($ZoneName in $DomainArray){
        if (($ApiCount -ge 1190)-and ($TimeStamp -lt $TimeStamp.AddMinutes(5))){
            Write-host -ForegroundColor Red "[!] Warning. Approaching Cloudflare API limit of 1200 per 5 minute interval.`n`nSleeping for 5 minutes to ensure that the Cloudflare API limit isn't hit."
            Write-host "`n`nScript will automatically resume after 5 minutes."
            Start-Sleep -Seconds 300
            $ApiCount = 0
            $TimeStamp = Get-Date
        }
        if(($ZoneName.Split(".") | Select-Object -Last 1) -in $TLDsNoHeaders){          
            $ZoneNameQueryURI = $BaseURI+"?name=$ZoneName.`n"
            Write-host "Getting DNS records for $($ZoneName)"
            $ZoneID = (Invoke-RestMethod -Uri $ZoneNameQueryURI -Method Get -Headers $Headers).result.id
            $ApiCount++
            $RecordsURI = "$($BaseURI)$($ZoneID)/dns_records/"
            $Records = Invoke-RestMethod -Uri $RecordsURI -Method Get -Headers $Headers
            $ApiCount++
            if($Records.result_info.total_count -eq 0){
                Write-host -ForegroundColor Red "No records exist for $($ZoneName).`n"
            }
            else{
                foreach($Record in $Records.result){
                    $RecordOutPut = [pscustomobject]@{
                    Domain = $ZoneName
                    Name = $Record.name                 
                    Type = $Record.type
                    Content = $Record.content
                    Priority = $Record.priority
                    Proxiable = $Record.proxiable
                    Proxied = $Record.proxied
                    TTL = $Record.ttl
                    Comment = $Record.comment
                    }
                    $RecordOutPut | Export-Csv $FullOutputPath -NoTypeInformation -Append
                }
            } 
        }else{
            Write-host -ForegroundColor Red "$($ZoneName) is invalid. Skipping check for domain.`n"
        }
    }
}

#endregion ExportDNSRecords

#region FinalBits
Write-Host -ForegroundColor Green "#######################################################################################`n"
Write-host "DNS records have been exported to $($FullOutputPath)."
$OpenFileNowQuery = Read-Host "`nDo you want to open the file now?`n`n[Y] Yes [N] No (Default)"

switch ($OpenFileNowQuery){
    y {Invoke-Item -Path $FullOutputPath;break}
    ye {Invoke-Item -Path $FullOutputPath;break}
    yes {Invoke-Item -Path $FullOutputPath;break}
    Default {break}
}

Write-host "`nThank you for using this script to export Cloudflare DNS records.`n`nHave a good day.`n`nGoodbye`n"

#Restore console back to original settings

$Host.UI.RawUI.BackgroundColor = $CurrentPSBackgroundColour
$Host.UI.RawUI.ForegroundColor = $CurrentPSForegroundColour

Exit

#endregion FinalBits