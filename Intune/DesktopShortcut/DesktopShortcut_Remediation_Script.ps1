# DesktopShortcut_Remediation_Script.ps1
# Creates or repairs a managed desktop shortcut and icon on the public desktop.
# Runs after detection script returns exit 1.
#
# Update the config block to match your environment before deploying.
#
# Exit 0 = remediation successful
# Exit 1 = remediation failed

# --------------------------- Config ---------------------------
$ShortcutName = "App Shortcut.lnk"           # Name of the .lnk file on the desktop
$TargetURL    = "https://your-app-url-here"   # URL or executable path the shortcut points to
$IconDir      = "C:\ProgramData\ManagedIcons" # Local directory to store the icon
$IconName     = "app-icon.ico"                # Icon filename
$IconUrl      = "https://your-storage-account.blob.core.windows.net/icons/app-icon.ico" # Public URL to download the icon from

# --------------------------------------------------------------
$ShortcutPath = Join-Path "$env:PUBLIC\Desktop" $ShortcutName
$IconPath     = Join-Path $IconDir $IconName

try {
    if (-not (Test-Path $IconDir)) {
        New-Item -Path $IconDir -ItemType Directory -Force | Out-Null
        Write-Output "Created icon directory: $IconDir"
    }

    Invoke-WebRequest -Uri $IconUrl -OutFile $IconPath -UseBasicParsing -ErrorAction Stop
    Write-Output "Icon downloaded to $IconPath"

    $WshShell            = New-Object -ComObject WScript.Shell
    $Shortcut            = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetURL
    $Shortcut.IconLocation = $IconPath
    $Shortcut.Save()

    Write-Output "Remediation complete: Desktop shortcut created at $ShortcutPath"
    exit 0
}
catch {
    Write-Output "ERROR: Remediation failed. $_"
    exit 1
}
