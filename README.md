# PowerShell Utilities

A collection of useful PowerShell scripts for everyday administrative tasks. This repository is intended to serve as a personal toolbox for automating and simplifying common IT operations.

## Scripts

### 1. Export Azure AD Licensed Users

**File:** `Export-AzureADLicensedUsers.ps1`  
This script connects to Azure Active Directory and exports a list of licensed users to a CSV file. It maps license SKU part numbers to user-friendly license names for easier reporting.

#### Features:
- Connects to Azure AD using `Connect-AzureAD`
- Retrieves all licensed users
- Maps license SKU IDs to readable names
- Outputs user and license info to a dated CSV file in `C:\Temp`

#### Requirements:
- AzureAD PowerShell module
- Appropriate permissions to read user and license data

#### Output:
CSV file named `AzureLicenseInventory-MM-dd-yyyy.csv` saved to `C:\Temp`

---

## More Scripts Coming Soon

This is the first script in what will become a growing collection of useful PowerShell tools. Stay tuned!

## License

MIT License
