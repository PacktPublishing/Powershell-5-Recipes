param(
    $ShortcutPath,
    $Target)
$ErrorActionPreference = 'stop'
if (-not(Test-Path $Target)) {
    Write-Error "Target $Target does not exist."
}

$TargetPath = Resolve-Path $Target

if(Test-Path $ShortcutPath) {
    #todo: prompt user
}
$FullShortcutPath = Join-Path (Get-Location) $ShortcutPath

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($FullShortcutPath)
$Shortcut.TargetPath = $TargetPath
$Shortcut.Save()
