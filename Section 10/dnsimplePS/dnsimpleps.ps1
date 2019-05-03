
function ToAuthorizationHeader($t) {
    $AccessToken = (new-object PSCredential `
        'username', $t).GetNetworkCredential().Password
    @{'Authorization'="Bearer $AccessToken"}
}

function CallDnsimpleApi ($method, $uri, $body, [System.Security.SecureString]$AccessToken) {
    Invoke-RestMethod -Method $method -Uri $uri `
        -Headers (ToAuthorizationHeader $AccessToken) `
        -Body $body -ContentType 'application/json' `
        | Select-Object -ExpandProperty data
}

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
        [System.Security.SecureString]$AccessToken
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

        CallDnsimpleApi -Method 'POST' -Uri $uri -Body $data -AccessToken $AccessToken
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
        [System.Security.SecureString]$AccessToken
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
    CallDnsimpleApi -Method Get -Uri $Uri -AccessToken $AccessToken
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
        [System.Security.SecureString]$AccessToken)
    
    if ($PsCmdLet.ShouldProcess("record with id $Id in zone $Zone")) {
        $Uri = "https://api.dnsimple.com/v2/$Account/zones/$Zone/records/$Id" 
        Write-Debug "Requesting: DELETE $Uri"
        Invoke-WebRequest -Method DELETE -Uri $Uri `
            -Headers (ToAuthorizationHeader $AccessToken) `
            | select-object StatusCode,StatusDescription
    }
}

function Write-AccessToken {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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
            AccessToken = (ConvertTo-SecureString $store[$Account]) 
        }
    } else {
        $store.Keys | foreach-object { new-object PSObject -Property @{Account=$_} }
    }
}