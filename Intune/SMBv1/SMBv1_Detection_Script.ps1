# SMBv1_Detection_Script.ps1
# Detects whether the SMB1Protocol Windows feature is enabled.
# Used with Intune remediation.
#
# Exit 0 = compliant, SMBv1 is disabled
# Exit 1 = non-compliant, remediation required

$SMBv1Status = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue

if ($null -eq $SMBv1Status) {
    Write-Output "ERROR: Unable to determine SMBv1 status. Detection failed."
    exit 1
}

switch ($SMBv1Status.State) {
    "Disabled" {
        Write-Output "Compliant: SMBv1 is disabled."
        exit 0
    }
    "Enabled" {
        Write-Output "Non-compliant: SMBv1 is enabled."
        exit 1
    }
    default {
        Write-Output "Non-compliant: SMBv1 state is unknown ($($SMBv1Status.State))."
        exit 1
    }
}
