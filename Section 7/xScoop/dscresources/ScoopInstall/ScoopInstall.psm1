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
        $Name
    )
    Update-Environment
    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    $Ensure = 'Absent'
    if (get-command 'scoop' -ErrorAction SilentlyContinue) {
        if ((scoop list) -match "$Name \(.*?\)") {
            $Ensure = 'Present'
        }
    } else {
        Write-Debug 'Could not find scoop installation. PATH problem'
    }

    $returnValue = @{
        Name = $Name
        Ensure = $Ensure
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
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )
    Update-Environment
    if ($Ensure -eq 'Present') {
        scoop install $Name                
    } else {
        scoop uninstall $Name
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )
    Update-Environment
    $currentState = Get-TargetResource $Name

    if ($currentState.Ensure -eq $Ensure) {
        $true
    } else {
        $false
    }
}

Export-ModuleMember -Function *-TargetResource
