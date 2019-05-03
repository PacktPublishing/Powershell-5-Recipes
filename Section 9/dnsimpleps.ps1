
function Add-ZoneRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({[Uri]::CheckHostName($_) -eq 'Dns'})]
        $Zone,
        [Parameter(Mandatory,Position=1)]
        [ValidateSet('A','ALIAS','CNAME','MX','SPF','URL','TXT','NS','SRV','NAPTR','PTR','AAAA','SSHFP','HINFO','POOL','CAA')]
        $RecordType, 
        [Parameter(Mandatory,Position=2)]
        $Name,
        [Parameter(Mandatory,Position=3)]
        $Content,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateRange(10000,99999)]
        [int]$Account,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$AccessToken
        )
    Begin {
        Write-debug "Begin"
    }
    Process {

    $data = [pscustomobject]@{
        'name' = $Name
        'content' = $Content
        'type' = $RecordType
    } | ConvertTo-Json

    $uri = "https://api.dnsimple.com/v2/$Account/zones/$Zone/records"
    Write-Debug "Calling Uri $uri with payload $data"

    Invoke-RestMethod -Method POST -Uri $uri `
        -Headers @{'Authorization'="Bearer $AccessToken"} `
        -Body $data -ContentType 'application/json' `
        | Select-Object -ExpandProperty data
    }
    End {
        Write-debug "End"
    }
}

function Get-ZoneRecord {
    [CmdletBinding(DefaultParameterSetName='ListRecords')]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({[Uri]::CheckHostName($_) -eq 'Dns'})]
        $Zone,

        [Parameter(Mandatory=$false,Position=1,ParameterSetName='ListRecords')]
        [ValidateSet('A','ALIAS','CNAME','MX','SPF','URL','TXT','NS','SRV','NAPTR','PTR','AAAA','SSHFP','HINFO','POOL','CAA')]
        $RecordType,
        [Parameter(Mandatory=$false,ParameterSetName='ListRecords')]
        $Name,
        [Parameter(Mandatory=$false,ParameterSetName='ListRecords')]
        $NameLike,
        
        [Parameter(Mandatory,ParameterSetName='ById')]
        $Id,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateRange(10000,99999)]
        [int]$Account,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$AccessToken
        )

    Write-debug "Parameter set name: $($PsCmdlet.ParameterSetName)"
    if ($PsCmdlet.ParameterSetName -eq 'ListRecords') {
        $Uri = "https://api.dnsimple.com/v2/$Account/zones/$Zone/records"
        $query = @{}
        if ($RecordType) { $query.Add('type',$RecordType) }
        if ($Name) { $query.Add('name', $Name) }
        if ($NameLike) { $query.Add('name_like', $NameLike) }
        if ($query.Count -gt 0) {
            $qRaw = ($query.Keys | ForEach-Object { "$_=$([Uri]::EscapeDataString($query[$_]))" }) `
                -join '&'
            $Uri += "?$qRaw"
        }
    } else  {
        $Uri = "https://api.dnsimple.com/v2/$Account/zones/$Zone/records/$Id"
    }
    Write-Debug "Requesting: GET $Uri"
    Invoke-RestMethod -Method Get -Uri $Uri -Headers @{'Authorization'="Bearer $AccessToken"} -UseBasicParsing `
        | Select-Object -ExpandProperty data
}

function Remove-ZoneRecord {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({[Uri]::CheckHostName($_) -eq 'Dns'})]
        $Zone,
        [Parameter(Mandatory,Position=1)]
        $Id,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateRange(10000,99999)]
        [int]$Account,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$AccessToken)
    
    if ($PsCmdLet.ShouldProcess("record with id $Id in zone $Zone")) {
        $Uri = "https://api.dnsimple.com/v2/$Account/zones/$Zone/records/$Id" 
        Write-Debug "Requesting: DELETE $Uri"
        Invoke-WebRequest -Method DELETE -Uri $Uri `
            -Headers @{'Authorization'="Bearer $AccessToken"} `
            | select-object StatusCode,StatusDescription
    }
}

function Write-AccessToken {
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$AccessToken,
        [Parameter(Mandatory,Position=1)]
        [ValidateRange(10000,99999)]
        [int]$Account,
        [Parameter(Mandatory=$false)]
        $Path = "$(join-path (split-path $PROFILE) '.dnsimple.tokens')"
    )
    $store = @{}
    if (test-path $Path) {
        Write-debug "Reading access tokens from $Path"
        $store = Import-CliXml -Path $Path
        Write-debug "$($store.Count) tokens read"
    } else {
        Write-debug "Access tokens store at $Path does not exist"
    }

    if ($AccessToken -isnot [System.Security.SecureString]) {
        Write-debug 'Input is cleartext - creating SecureString'
        $AccessTokenSecure = ConvertTo-SecureString -AsPlainText $AccessToken -Force
    } else {
        Write-debug 'Input is already SecureString'
        $AccessTokenSecure = $AccessToken
    }
    $store[$Account] = (ConvertFrom-SecureString $AccessTokenSecure)

    Write-debug "Writing access tokens (count: $($store.Count)) to store at $Path"
    Export-CliXml -Path $Path -InputObject $store
}

function Read-AccessToken {
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateRange(10000,99999)]
        [int]$Account,
        [Parameter(Mandatory=$false)]
        $Path = "$(join-path (split-path $PROFILE) '.dnsimple.tokens')"
        )

    if (-not(test-path $Path)) {
        Write-error "Access token store at $Path not found"
        return
    }
    Write-debug "Reading access tokens from $Path"
    $store = Import-CliXml -Path $Path
    Write-debug "$($store.Count) tokens read"
    if ($Account) {
        [pscustomobject]@{
            Account=$Account
            AccessToken = (new-object PSCredential 'doesntmatter',`
                (ConvertTo-SecureString $store[$Account])).GetNetworkCredential().Password 
        }
    } else {
        $store.Keys | foreach-object { new-object PSObject -Property @{Account=$_} }
    }
}