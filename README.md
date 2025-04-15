# CloudflareDNSQuery

CloudflareDNSQuery is a PowerShell script created to export DNS records from Cloudflare via the Cloudflare API to a .csv file for further review or as a backup of the zone before making any changes to DNS records.

The script can either export all zones from a Cloudflare account or can export select zones from an account.

The PowerShell script is able to run in both PowerShell 5.1 and PowerShell 7 without issue.

## Requirements

To be able to run this script, you need to generate an API token in the Cloudflare console.

Required Cloudflare API permissions to use this script:
1. Permissions - Zone.DNS.Read
2. Zone Resources - Include all from an account

To get started, please see
[Cloudflare's documentation on creating the API token.](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)

## Script Defaults 

1. If anything requires user input, then the script will always default to "No".
1. The script will save the .csv output file to the location the scripts runs from but this can be changed if needed.
    1. E.g. If the script is ran from your downloads folder, then it'll save the .csv file to your downloads folder.
1. The default output file will include the date and time the script ran but this can be changed if needed.

## Instructions

1. Download the DNSExport.ps1 file.
1. Open PowerShell or Windows Terminal.
1. To run the script, do one of the following:
    1. Change the directory to where the DNSExport.ps1 file is. You can do this with the `cd` command.
    1. Enter the full path to the file, including the file name. E.g. `C:\Users\MLewisTech\Downloads\DNSExport.ps1`. 
    <br>
    
        >[!NOTE]
        > It is possible that your PowerShell blocks the execution of the script. If so, then you may get an error from PowerShell that says something like "File C:\Users\MLewisTech\Downloads\DNSExport.ps1 cannot be loaded because running scripts is disabled on this system. For more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170".
        >
        >If you get similar to above, then you'll need to change the execution policy of your PowerShell to allow the script to run.

        <br>

        >[!CAUTION]
        >**Changing the PowerShell execution policy can reduce the security of your machine and could allow malicious code to run.**
        >
        >**You should always review any code and scripts found from the internet before downloading and running (including this script).**
        >
        >**Only change the execution policy if you know what you are doing and accept the risks associated with changing it.**

<br>

1. Once the script loads, then press enter to continue.
1. You will then be prompted for if you have a Cloudflare API token.
    1. If so, then enter `yes` and enter the token when prompted.
        1. Press `enter` when done.
    1. If you don't have an API token, then please follow [Cloudflare's Guide](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) to create one.
1. You'll then be prompted if you want to get the DNS records for all domains (default option) or for specific domains.
    1. If you want to get records for all domains either just press `enter` or enter `no`.
        1. Proceed to step 7.
    1. If you want to get the records for specific domains, then enter `yes`.
        1. You then be prompted for if you have a .csv or .txt file containing the domains that you want to get records for.
            1. Enter `yes` and a File Explorer window will open to allow you to browse and select the .csv or .txt file containing the domains.
            1. Either pressing `enter` or entering `no` will allow you to input a comma separated list of domains into the console window (E.g. example.co.uk,example.com,example.net,contoso.com,contoso.net).
1. You'll then be prompted if you want to change the output directory/file.
    1. If you want to change the either the output directory, the outputfile or both, then enter `yes`.
        1. Enter the new directory path and/or the new file name to change this.
    1. Otherwise, either pressing `enter` or entering `no` will use the default output directory (the directory where the script is ran from) and the default output file.
1. The script will then run through the list of selected domains and get the DNS records records. These DNS records will then be output into a .csv file.
    1. This section of the script also handles the Cloudflare API rate limiting to ensure that the API limit isn't hit (1200 requests within a 5 minute period).
1. Once the script has finished, you can then either open .csv file that was generated or you can exit the script.
    1. To open the generated .csv file, enter `yes`.
    1. To exit the script, then either press `enter` or enter `no`.


## Troubleshooting
1. Does the API token have the correct permissions?
    1. Permissions - Zone.DNS.Read
    1. Zone Resources - Include all from an account
1. Has the API token expired?
1. Have you changed the PowerShell execution policy to allow scripts to run?
