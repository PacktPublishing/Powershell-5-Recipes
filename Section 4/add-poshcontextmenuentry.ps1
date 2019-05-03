#requires -RunAsAdministrator
if (-not(test-path hkcr:)) {
	New-psdrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    $addedPsDrive = $true
}
try {
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    pushd hkcr:\directory\shell
    New-item powershellmenu
    Set-ItemProperty -LiteralPath powershellmenu `
        -name '(default)' -Value 'Open PoSH here'
    cd .\powershellmenu\
    New-item command
    Set-itemproperty -Literalpath command -Name '(default)' `
        -Value "C:\\Windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe -NoExit -Command Set-Location -LiteralPath '%L'"
} finally {
    popd
    $ErrorActionPreference = $oldErrorActionPreference
    if ($addedPsDrive) {
        Remove-PsDrive -Name HKCR
    }
}
