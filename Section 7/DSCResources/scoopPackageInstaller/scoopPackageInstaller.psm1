function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("scoopinstaller")]
        [System.String]
        $Key
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    $returnValue = @{
        Home = $env:SCOOP
        Ensure = if (get-command scoop -ErrorAction 'SilentlyContinue') { 'Present' } else { 'Absent' }
        Key = 'scoopinstaller'
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [System.String]
        $Home,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("scoopinstaller")]
        [System.String]
        $Key
    )
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
        if (-not(Get-Command scoop -ErrorAction 'SilentlyContinue')) {
            Write-Debug "Installing scoop"
            iwr -UseBasicParsing -Uri http://get.scoop.sh | iex
        }
    }
    if ($Ensure -eq 'Absent') {
        if (test-path $Home) {
            Remove-Item $home -Recurse -Force
        }
        if ($env:SCOOP) {
            [Environment]::SetEnvironmentVariable('SCOOP',$null,'Machine')
            Remove-Item Env:\Scoop
        }
    }
    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [System.String]
        $Home,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("scoopinstaller")]
        [System.String]
        $Key
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    $currentState = Get-TargetResource 'scoopinstaller'
    if ($currentState.Home -eq $Home -and $currentState.Ensure -eq $Ensure) {
        $true
    } else {
        $false
    }
}

Export-ModuleMember -Function *-TargetResource
