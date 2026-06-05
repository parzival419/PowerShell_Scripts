# DistributionList_Member_Audit.ps1
# Audits members of all distribution lists matching a specified filter
# and exports results to a dated CSV.
#
# Requirements:
#   Install-Module ExchangeOnlineManagement -Scope CurrentUser
#
# Update the config block before running.

# --------------------------- Config ---------------------------
$AdminUPN      = "admin@yourdomain.com"       # UPN used to connect to Exchange Online
$DLFilter      = "your-prefix*"               # PrimarySmtpAddress filter pattern (e.g. "team-*")
$ExportDir     = "C:\Temp"
$ExportPath    = Join-Path $ExportDir "DL_Member_Audit_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"

# --------------------------- Connect --------------------------
try {
    Connect-ExchangeOnline -UserPrincipalName $AdminUPN -ErrorAction Stop
}
catch {
    Write-Output "ERROR: Failed to connect to Exchange Online. $_"
    exit 1
}

# ---------------------- Ensure export dir ---------------------
if (-not (Test-Path $ExportDir)) {
    try {
        New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null
    }
    catch {
        Write-Output "ERROR: Could not create export directory $ExportDir. $_"
        exit 1
    }
}

# ---------------------- Fetch DLs ----------------------------
Write-Output "Fetching distribution lists matching '$DLFilter'..."

try {
    $DLs = Get-DistributionGroup -ResultSize Unlimited -ErrorAction Stop |
        Where-Object { $_.PrimarySmtpAddress -like $DLFilter }
}
catch {
    Write-Output "ERROR: Failed to retrieve distribution groups. $_"
    exit 1
}

Write-Output "Found $($DLs.Count) distribution list(s)."

# ---------------------- Collect members ----------------------
$Results = foreach ($DL in $DLs) {
    Write-Output "  Processing: $($DL.PrimarySmtpAddress)"

    try {
        $Members = Get-DistributionGroupMember -Identity $DL.Identity -ResultSize Unlimited -ErrorAction Stop
    }
    catch {
        Write-Output "  ERROR: Could not retrieve members for $($DL.PrimarySmtpAddress). $_"
        continue
    }

    if ($Members.Count -eq 0) {
        [PSCustomObject]@{
            DL_DisplayName       = $DL.DisplayName
            DL_Email             = $DL.PrimarySmtpAddress
            DL_ManagedBy         = ($DL.ManagedBy -join "; ")
            Member_DisplayName   = "(empty)"
            Member_Email         = ""
            Member_Type          = ""
            Member_RecipientType = ""
        }
    } else {
        foreach ($Member in $Members) {
            [PSCustomObject]@{
                DL_DisplayName       = $DL.DisplayName
                DL_Email             = $DL.PrimarySmtpAddress
                DL_ManagedBy         = ($DL.ManagedBy -join "; ")
                Member_DisplayName   = $Member.DisplayName
                Member_Email         = $Member.PrimarySmtpAddress
                Member_Type          = $Member.RecipientType
                Member_RecipientType = $Member.RecipientTypeDetails
            }
        }
    }
}

# ---------------------- Export --------------------------------
try {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    Write-Output "`nDone. $($Results.Count) rows exported to $ExportPath"
}
catch {
    Write-Output "ERROR: Failed to export CSV. $_"
    exit 1
}
