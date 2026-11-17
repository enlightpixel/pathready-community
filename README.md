# Microsoft 365 path validator

A read-only PowerShell preflight for a local archive headed to SharePoint Online or OneDrive. Pass the folder you plan to upload and its intended destination. The script reports paths and names worth reviewing before you move anything. No sign-in, dependencies, or network requests.

## Run it

Use PowerShell 7.2 or later. Save the script locally, then run:

```powershell
./Test-M365Path.ps1 -Source 'C:\Incoming\Archive' -Destination '/sites/Operations/Shared Documents/Client archives'
```

Use `-IncludeSourceFolder` if you will upload the Archive folder itself. The default models uploading its contents. Pipe results to `Export-Csv -NoTypeInformation -LiteralPath ./path-findings.csv` if you want a shareable report. Review it before sharing because it contains relative filenames.

## How length is measured

Enter a decoded server-relative destination, including the site and library. Use a literal space where the URL has `%20`. The hostname and leading slash are excluded from the estimate. The script uses PowerShell's UTF-16 string length, so a surrogate pair counts as two units. An empty result means this scan produced no findings under its chosen checks. It also reports unreadable directories and skipped links when encountered.

This preflight does not verify tenant permissions, destination names independently of local entries, sync-client limits, or upload success. Review Microsoft’s current service rules before migration. [Microsoft naming and path limits](https://support.microsoft.com/en-us/onedrive/restrictions-and-limitations-in-onedrive-and-sharepoint)

For a reviewable rename plan, separate verified copy, and handoff report, see [PathReady](https://enlightpixel.com/products/pathready?utm_source=github&utm_medium=referral&utm_campaign=path-validator) or the [PathReady download and requirements](https://enlightpixel.com/products/pathready/download). The standalone PowerShell script is available under MIT.
