. $PSScriptRoot\dnsimpleps.ps1

Set-Alias -Name zonerecord -Value Get-ZoneRecord
Set-Alias -Name accesstoken -Value Read-AccessToken

Export-ModuleMember `
    -Function Add-ZoneRecord,Remove-ZoneRecord,Get-ZoneRecord,Write-AccessToken,Read-AccessToken `
    -Alias zonerecord
