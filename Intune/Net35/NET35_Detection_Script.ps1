# NET35_Detection_Script.ps1
# Detects whether the .NET Framework 3.5 (NetFx3) Windows feature is enabled.
# Used with Intune remediation.
#
# Exit 0 = compliant, NetFx3 is enabled
# Exit 1 = non-compliant, remediation required

$feature = Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue

if ($null -eq $feature) {
    Write-Output "ERROR: Unable to query NetFx3 feature state."
    exit 1
}

if ($feature.State -eq "Enabled") {
    Write-Output "Compliant: .NET Framework 3.5 is enabled."
    exit 0
}

Write-Output "Non-compliant: .NET Framework 3.5 is not enabled (State: $($feature.State))."
exit 1
