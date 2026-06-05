# DesktopShortcut_Detection_Script.ps1
# Detects whether a managed desktop shortcut and its icon are present
# on the public desktop. Used with Intune remediation.
#
# Update the config block to match your shortcut name and icon path
# before deploying.
#
# Exit 0 = compliant, shortcut and icon exist
# Exit 1 = non-compliant, remediation required

# --------------------------- Config ---------------------------
$ShortcutName = "App Shortcut.lnk"           # Name of the .lnk file on the desktop
$IconDir      = "C:\ProgramData\ManagedIcons" # Local directory where the icon is stored
$IconName     = "app-icon.ico"                # Icon filename

# --------------------------------------------------------------
$ShortcutPath = Join-Path "$env:PUBLIC\Desktop" $ShortcutName
$IconPath     = Join-Path $IconDir $IconName

if ((Test-Path $ShortcutPath) -and (Test-Path $IconPath)) {
    Write-Output "Compliant: Desktop shortcut and icon are present."
    exit 0
}

if (-not (Test-Path $ShortcutPath)) {
    Write-Output "Non-compliant: Shortcut not found at $ShortcutPath."
}

if (-not (Test-Path $IconPath)) {
    Write-Output "Non-compliant: Icon not found at $IconPath."
}

exit 1
