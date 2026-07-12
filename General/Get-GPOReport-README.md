# Get-GPOReport.ps1

A PowerShell script that looks up a list of Group Policy Objects (GPOs) by name and exports each one's settings report to XML.

## Features

- Accepts GPO names as an inline array or from a text file (one name per line)
- Generates an individual XML report per GPO using `Get-GPOReport`
- Optionally combines all reports into a single XML file
- Sanitizes filenames and prints a success/failure summary table
- Supports querying a specific domain

## Requirements

- PowerShell 5.1+ (Windows PowerShell) or PowerShell 7+
- [GroupPolicy module](https://learn.microsoft.com/en-us/powershell/module/grouppolicy/) (RSAT: Group Policy Management Tools)
- Read permissions on the target GPOs

## Installation

1. Clone this repo or download `Get-GPOReport.ps1`
2. Make sure RSAT Group Policy tools are installed:

   ```powershell
   Get-WindowsCapability -Name RSAT.GroupPolicy* -Online | Add-WindowsCapability -Online
   ```

## Usage

### From a text file of GPO names

```powershell
.\Get-GPOReport.ps1 -InputFile .\gpo-list.txt -OutputFolder C:\Reports
```

`gpo-list.txt` should contain one GPO name per line:

```
Default Domain Policy
Password Policy
Workstation Baseline
```

### Inline array of GPO names

```powershell
.\Get-GPOReport.ps1 -GpoNames "Default Domain Policy","Password Policy"
```

### Combine all reports into one XML file

```powershell
.\Get-GPOReport.ps1 -GpoNames "Default Domain Policy","Password Policy" -Combine
```

### Target a specific domain

```powershell
.\Get-GPOReport.ps1 -InputFile .\gpo-list.txt -Domain contoso.com
```

## Parameters

| Parameter      | Type       | Description                                                        |
|----------------|-----------|----------------------------------------------------------------------|
| `-GpoNames`    | string[]  | Array of GPO display names to look up                               |
| `-InputFile`   | string    | Path to a text file with one GPO name per line                      |
| `-OutputFolder`| string    | Folder where XML reports are saved (default: `.\GPOReports`)         |
| `-Domain`      | string    | Domain to query (defaults to current domain)                        |
| `-Combine`     | switch    | Also generate a single combined XML file with all GPO reports       |

## Output

- One `.xml` file per GPO, named after the GPO (special characters sanitized)
- Optional `CombinedGPOReports.xml` if `-Combine` is used
- Console summary table showing GPO name, status, ID, and output file path

## Example Output

```
Processing GPO: Default Domain Policy
  -> Saved: .\GPOReports\Default Domain Policy.xml
Processing GPO: Password Policy
  -> Saved: .\GPOReports\Password Policy.xml

--- Summary ---

GPOName                Status  Id                                   OutputFile
-------                ------  --                                   ----------
Default Domain Policy  Success 31b2f340-016d-11d2-945f-00c04fb984f9  .\GPOReports\Default Domain Policy.xml
Password Policy        Success a1b2c3d4-...                         .\GPOReports\Password Policy.xml
```

## Notes

- GPO names must match exactly (case-insensitive) as they appear in Group Policy Management Console
- If a GPO name isn't found, that entry is marked `Failed` in the summary and the script continues with the rest
- Run from an account with sufficient rights to read GPOs in the target domain

## License

MIT
