# PowerShell Utilities

A personal toolbox of PowerShell scripts for automating everyday IT and Azure/M365 admin tasks.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell)
![License](https://img.shields.io/github/license/parzival419/PowerShell_Scripts)

---

## Repository Structure

```
PowerShell_Scripts/
├── Azure/
│   └── user_licenses.ps1
├── Intune/         # coming soon
├── M365/           # coming soon
└── README.md
```

---

## Scripts

### Azure / user_licenses.ps1

Connects to Azure AD and exports a dated CSV of all licensed users. License SKU part numbers are mapped to friendly names for easy reporting.

**Usage**
```powershell
# Install the module if needed
Install-Module AzureAD

# Run the script
.\Azure\user_licenses.ps1
```

**Output:** `C:\Temp\AzureLicenseInventory-MM-dd-yyyy.csv`

**Fields:** Name, Title, Department, Email, SKU, License, Company, Office

**Licenses mapped (20+):** M365 E3, M365 F3, Office 365 E1/E3/F3, Exchange Online, Power BI Pro, Copilot for M365, Teams Premium, Visio, Project, and more

**Requirements:**
- PowerShell 5.1+
- `AzureAD` module
- Read permissions on Azure AD users and license SKUs

---

## Roadmap

- [ ] Intune device compliance report
- [ ] M365 mailbox size audit
- [ ] Stale user account cleanup
- [ ] Bulk license assignment from CSV

---

MIT License · [parzival419](https://github.com/parzival419)
