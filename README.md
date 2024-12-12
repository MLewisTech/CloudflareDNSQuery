<h1><strong>THIS IS A WORK IN PROGRESS<strong></h1>

----------------------------------------------------------------------------------------------------------------------------------------------

This is for creating a PowerShell API call to Cloudflare to get a list of all DNS zones and entries for using in backup or for review.

This will output to a .csv file which can then be manipulated as needed.

----------------------------------------------------------------------------------------------------------------------------------------------

<h2>To do:</h2>

1. Add email check to make sure email is valid
2. Figure out API code for getting DNS zone entries
3. Create code to loop through each one and output to spreadsheet
    1. Work out if better to output to a single spreadhseet or output to multiple spreadsheets.
        1. If using a single spreadsheet, then put each domain on a separate tab?

<h2>Longer Term:</h2>

1. Add option to get specific domain(s) rather than all domains