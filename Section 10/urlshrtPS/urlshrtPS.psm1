
function Add-ShortUrl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({[Uri]::CheckHostName($_) -eq 'Dns'})]
        $Zone,
        [Parameter(Mandatory,Position=1)]
        $Name,
        [Parameter(Mandatory,Position=2)]
        [ValidateScript({[Uri]::IsWellFormedUriString($_,[UriKind]::Absolute)})]
        $Url,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateRange(10000,99999)]
        [int]$Account,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [System.Security.SecureString]$AccessToken
        )

    $record = Get-ZoneRecord -Zone $Zone -Name $Name -Account $Account -AccessToken $AccessToken
    if ($record) {
        Write-Error "Record with name $Name and type URL already exists in zone $Zone"
        return
    }
    Add-ZoneRecord -Zone $Zone -RecordType URL -Name $Name -Content $Url -Account $Account -AccessToken $AccessToken
}

function Remove-ShortUrl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({[Uri]::CheckHostName($_) -eq 'Dns'})]
        $Zone,
        [Parameter(Mandatory,Position=1)]
        $Name,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateRange(10000,99999)]
        [int]$Account,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [System.Security.SecureString]$AccessToken
        )

    $record = Get-ZoneRecord -Zone $Zone -Name $Name -Account $Account -AccessToken $AccessToken
    if (-not($record)) {
        Write-Output "Record with name $Name and type URL does not exist in zone $Zone"
        return
    }
    Remove-ZoneRecord -Zone $Zone -Id $record.id -Account $Account -AccessToken $AccessToken
}
