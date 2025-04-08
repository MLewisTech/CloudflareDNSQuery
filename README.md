<h1>CloudflareDNSQuery</h1>

CloudflareDNSQuery is a PowerShell script created to export DNS records from Cloudflare via the Cloudflare API to a .csv file for further review or as a backup of the zone before making any changes to DNS records.

The script can either export all zones from a Cloudflare account or can export select zones from an account.

The PowerShell script is able to run in both PowerShell 5.1 and PowerShell 7.

<h2>Requirements</h2>

To be able to run this script, you need to generate an API token in the Cloudflare console.

Required Cloudflare API permissions to use this script:
1. Permissions - Zone.DNS.Read
2. Zone Resources - Include all from an account

Cloudflare's documentation on creating the API token can be found at: https://developers.cloudflare.com/fundamentals/api/get-started/create-token/.

<h2>Script Defaults</h2>

1. If anything requires user input, then the script will always default to "No".
2. The script will save the .csv output file to the location the scripts runs from but this can be changed if needed.
    1. E.g. If the script is ran from your downloads folder, then it'll save the .csv file to your downloads folder.
3. The default output file will include the date and time the script ran but this can be changed if needed.

<h2>Instructions</h2>

1. Download the DNSExport.ps1 file.
2. Open PowerShell or Windows Terminal.
3. To run the script, do one of the following:
    1. Change the directory to where the DNSExport.ps1 file is. You can do this with the `cd` command.
    2. Enter the full path to the file, including the file name. E.g. `C:\Users\MLewisTech\Downloads\DNSExport.ps1`.    
4. Once the script loads, then press enter to continue.
5. You will then be prompted for if you have a Cloudflare API token.
    1. If so, then select yes and enter the token.


