function Update-Environment {
    $locations = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
                 'HKCU:\Environment'

    $locations | ForEach-Object {
        $k = Get-Item $_
        $k.GetValueNames() | ForEach-Object {
            $name  = $_
            $value = $k.GetValue($_)

            if ($userLocation -and $name -ieq 'PATH') {
                $env:path += ";$value"
            } else {
                Set-Item -Path Env:\$name -Value $value
            }
        }

        $userLocation = $true
    }
}


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Home
    )
    Update-Environment

    $returnValue = @{
        Home = $Home
        Ensure = if (get-command scoop -ErrorAction 'SilentlyContinue') { 'Present' } else { 'Absent' }
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Home,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )
    Update-Environment
    
    $scoopShims = "$Home\shims"
    if ($Ensure -eq 'Present') {
        if (-not(test-path $Home)) {
            Write-Debug "Creating Scoop home directory"
            mkdir $Home | Out-Null
        }
        if ($env:SCOOP -ne $Home) {
            Write-Debug "Adding Scoop env. variable"
            [Environment]::SetEnvironmentVariable('SCOOP',$HOME,'Machine')
            $env:SCOOP = $Home
        }
        $machinePath = [Environment]::GetEnvironmentVariable('path','machine') -split ';'
        if ($machinePath -notcontains $scoopShims) {
            [Environment]::SetEnvironmentVariable('path',(($machinePath + $scoopShims) -join ';'),'Machine')
            $env:path = [Environment]::GetEnvironmentVariable('path')
        }
        if (-not(Get-Command scoop -ErrorAction 'SilentlyContinue')) {
            Write-Debug "Installing scoop"
            iwr -UseBasicParsing -Uri http://get.scoop.sh | iex
        }
    } elseif ($Ensure -eq 'Absent') {
        if (test-path $Home) {
            Remove-Item $home -Recurse -Force
        }
        if ($env:SCOOP) {
            [Environment]::SetEnvironmentVariable('SCOOP',$null,'Machine')
            Remove-Item Env:\Scoop
        }
        $machinePath = [Environment]::GetEnvironmentVariable('path','machine') -split ';'
        if ($machinePath -contains $scoopShims) {
            [Environment]::SetEnvironmentVariable('path',(($machinePath | where { $_ -ne $scoopShims}) -join ';'),'Machine')
            $env:path = [Environment]::GetEnvironmentVariable('path')
        }
    }
    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Home,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )
    Update-Environment

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    $currentState = Get-TargetResource 'scoopinstaller'
    if ($currentState.Ensure -eq $Ensure) {
        $true
    } else {
        $false
    }
}

Export-ModuleMember -Function *-TargetResource
