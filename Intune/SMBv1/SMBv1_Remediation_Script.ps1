# SMBv1_Remediation_Script.ps1
# Disables the SMB1Protocol Windows feature.
# Runs after detection script returns exit 1.
#
# Exit 0 = remediation successful
# Exit 1 = remediation failed

$SMBv1Status = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue

if ($null -eq $SMBv1Status) {
    Write-Output "ERROR: Unable to determine SMBv1 status. Remediation aborted."
    exit 1
}

if ($SMBv1Status.State -eq "Disabled") {
    Write-Output "SMBv1 is already disabled. No action needed."
    exit 0
}

try {
    Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop
    Write-Output "Remediation complete: SMBv1 has been disabled. A reboot may be required."
    exit 0
}
catch {
    Write-Output "ERROR: Failed to disable SMBv1. $_"
    exit 1
}
