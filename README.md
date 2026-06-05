# PowerShell Utilities

A personal toolbox of PowerShell scripts for automating everyday IT and Azure/M365 admin tasks.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell)
![License](https://img.shields.io/github/license/parzival419/PowerShell_Scripts)

---

## Repository Structure

```
PowerShell_Scripts/
├── Azure/
│   ├── License_Audit.ps1
│   └── user_licenses.ps1
├── Intune/
│   ├── DesktopShortcut/
│   │   ├── DesktopShortcut_Detection_Script.ps1
│   │   └── DesktopShortcut_Remediation_Script.ps1
│   ├── ForceRestart/
│   │   ├── ForceRestart_Detection_Script.ps1
│   │   └── ForceRestart_Remediation_Script.ps1
│   ├── Net35/
│   │   ├── NET35_Detection_Script.ps1
│   │   └── NET35_Remediation_Script.ps1
│   ├── SMBv1/
│   │   ├── SMBv1_Detection_Script.ps1
│   │   └── SMBv1_Remediation_Script.ps1
│   └── WinTrust/
│       ├── WinTrust_Detection_Script.ps1
│       └── WinTrust_Remediation_Script.ps1
├── M365/
│   └── DistributionList_Member_Audit.ps1
├── General/
│   └── MSI_MSP_Cleanup.ps1
└── README.md
```

---

## Azure

### License_Audit.ps1

Connects to Microsoft Graph and exports a dated CSV of all licensed users with friendly license names mapped from SKU part numbers. Replaces the legacy AzureAD module approach.

**Requirements:** `Microsoft.Graph` module, `User.Read.All` and `Directory.Read.All` permissions

**Output:** `C:\Temp\LicenseAudit-MM-dd-yyyy.csv`

**Fields:** Name, Title, Department, Email, SKU, License, Company, Office

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
.\Azure\License_Audit.ps1
```

### user_licenses.ps1

Original version of the license audit script using the legacy AzureAD PowerShell module. Kept for reference. `License_Audit.ps1` is the recommended version as the AzureAD module has been deprecated by Microsoft.

**Requirements:** `AzureAD` module, read permissions on Azure AD users and license SKUs

**Output:** `C:\Temp\AzureLicenseInventory-MM-dd-yyyy.csv`

**Fields:** Name, Title, Department, Email, SKU, License, Company, Office

```powershell
Install-Module AzureAD
.\Azure\user_licenses.ps1
```

---

## Intune

All Intune scripts follow the detection/remediation pattern. Detection scripts exit 0 for compliant and exit 1 for non-compliant. Remediation scripts run when detection returns exit 1.

### DesktopShortcut

Detects and repairs a managed desktop shortcut and icon on the public desktop. Update the config block with your shortcut name, target URL, and icon URL before deploying.

```
Intune/DesktopShortcut/DesktopShortcut_Detection_Script.ps1
Intune/DesktopShortcut/DesktopShortcut_Remediation_Script.ps1
```

### ForceRestart

Detects whether device uptime exceeds 1 day. Remediation prompts the user via Windows toast notifications with up to 2 deferrals before forcing a restart countdown. Runs in user context. Update the config block with your org name and icon URL before deploying.

```
Intune/ForceRestart/ForceRestart_Detection_Script.ps1
Intune/ForceRestart/ForceRestart_Remediation_Script.ps1
```

### Net35

Detects and enables the .NET Framework 3.5 (NetFx3) Windows feature.

```
Intune/Net35/NET35_Detection_Script.ps1
Intune/Net35/NET35_Remediation_Script.ps1
```

### SMBv1

Detects and disables the SMB1Protocol Windows feature.

```
Intune/SMBv1/SMBv1_Detection_Script.ps1
Intune/SMBv1/SMBv1_Remediation_Script.ps1
```

### WinTrust

Detects and configures the `EnableCertPaddingCheck` registry key in both 32-bit and 64-bit WinTrust paths.

```
Intune/WinTrust/WinTrust_Detection_Script.ps1
Intune/WinTrust/WinTrust_Remediation_Script.ps1
```

---

## M365

### DistributionList_Member_Audit.ps1

Connects to Exchange Online and exports a dated CSV of all members across distribution lists matching a specified filter. Logs empty DLs for easy identification. Update the config block with your admin UPN and DL filter pattern before running.

**Requirements:** `ExchangeOnlineManagement` module

**Output:** `C:\Temp\DL_Member_Audit_yyyyMMdd_HHmm.csv`

**Fields:** DL_DisplayName, DL_Email, DL_ManagedBy, Member_DisplayName, Member_Email, Member_Type, Member_RecipientType

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
.\M365\DistributionList_Member_Audit.ps1
```

---

## General

### MSI_MSP_Cleanup.ps1

Removes orphaned MSI and MSP files from `C:\Windows\Installer` by cross-referencing the Windows Installer registry. Includes dry run mode -- set `$DryRun = $true` to preview deletions before committing. Must be run as Administrator.

```powershell
# Preview only
$DryRun = $true
.\General\MSI_MSP_Cleanup.ps1

# Actual cleanup
$DryRun = $false
.\General\MSI_MSP_Cleanup.ps1
```

---

MIT License · [parzival419](https://github.com/parzival419)
