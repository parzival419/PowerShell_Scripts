#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Cleans orphaned MSI and MSP files from C:\Windows\Installer.

.DESCRIPTION
    Uses the Windows Installer COM object via VBScript to build a list of
    registered patches, then removes any files and subdirectories in
    C:\Windows\Installer that are not referenced by an active product or patch.

.NOTES
    Set $DryRun = $true to preview deletions without removing anything.
    Set $DryRun = $false to perform the actual cleanup.
    Must be run as Administrator.
#>

# --------------------------- Config ---------------------------
$DryRun        = $true    # Set to $false to perform actual cleanup
$InstallerPath = "C:\Windows\Installer"

# ---------------------- VBScript: Build patch list ------------
$vbsPath    = "$env:TEMP\WiMsps.vbs"
$outputPath = "$env:TEMP\WiMsps_output.txt"

$vbsContent = @"
Dim msi : Set msi = CreateObject("WindowsInstaller.Installer")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.CreateTextFile("$outputPath", True)
objFile.WriteLine "ProductCode, PatchCode, PatchLocation"
objFile.WriteLine ""
Dim products : Set products = msi.Products
Dim productCode
For Each productCode in products
    Dim patches : Set patches = msi.Patches(productCode)
    Dim patchCode
    For Each patchCode in patches
        Dim location : location = msi.PatchInfo(patchCode, "LocalPackage")
        objFile.WriteLine productCode & ", " & patchCode & ", " & location
    Next
Next
"@

try {
    Set-Content -Path $vbsPath -Value $vbsContent -Force -ErrorAction Stop
    $result = & cscript //NoLogo $vbsPath 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Output "ERROR: VBScript execution failed. $result"
        exit 1
    }
}
catch {
    Write-Output "ERROR: Failed to write or execute VBScript. $_"
    exit 1
}

# ---------------------- Load patch list -----------------------
try {
    $patchList     = Import-Csv $outputPath -ErrorAction Stop
    $patchLocations = $patchList |
        Select-Object -ExpandProperty ' PatchLocation' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" }
}
catch {
    Write-Output "ERROR: Failed to import patch list. $_"
    exit 1
}

if ($DryRun) {
    Write-Output "DRY RUN enabled. No files will be deleted."
}

$freedBytes = 0

# ---------------------- Pass 1: Files ------------------------
Write-Output "`n-- Pass 1: Files --"

Get-ChildItem $InstallerPath -File | ForEach-Object {
    $fullName = $_.FullName
    $sizeMB   = [math]::Round($_.Length / 1MB, 2)

    if ($patchLocations -contains $fullName) {
        Write-Output "KEEPING:  $fullName"
    } else {
        Write-Output "$(if ($DryRun) { 'WOULD REMOVE' } else { 'REMOVING' }): $fullName ($sizeMB MB)"
        $freedBytes += $_.Length

        if (-not $DryRun) {
            try {
                Remove-Item $fullName -Force -ErrorAction Stop
            }
            catch {
                Write-Output "ERROR: Could not remove $fullName. $_"
            }
        }
    }
}

# ---------------------- Pass 2: Directories -------------------
Write-Output "`n-- Pass 2: Directories --"

Get-ChildItem $InstallerPath -Directory | ForEach-Object {
    $dirName  = $_.Name
    $dirSize  = (Get-ChildItem $_.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $dirSizeMB = [math]::Round($dirSize / 1MB, 2)
    $isReferenced = $patchList | Where-Object {
        $_.ProductCode -like "*$dirName*" -or $_.PatchCode -like "*$dirName*"
    }

    if ($isReferenced) {
        Write-Output "KEEPING DIR:  $dirName"
    } else {
        Write-Output "$(if ($DryRun) { 'WOULD REMOVE DIR' } else { 'REMOVING DIR' }): $dirName ($dirSizeMB MB)"
        $freedBytes += $dirSize

        if (-not $DryRun) {
            try {
                Remove-Item $_.FullName -Force -Recurse -ErrorAction Stop
            }
            catch {
                Write-Output "ERROR: Could not remove directory $dirName. $_"
            }
        }
    }
}

# ---------------------- Summary -------------------------------
$freedGB = [math]::Round($freedBytes / 1GB, 2)

if ($DryRun) {
    Write-Output "`nDry run complete. Estimated space to be freed: $freedGB GB"
    Write-Output "Set `$DryRun = `$false and re-run to perform actual cleanup."
} else {
    Write-Output "`nCleanup complete. Approximate space freed: $freedGB GB"
}

# ---------------------- Cleanup temp files --------------------
Remove-Item $vbsPath    -Force -ErrorAction SilentlyContinue
Remove-Item $outputPath -Force -ErrorAction SilentlyContinue