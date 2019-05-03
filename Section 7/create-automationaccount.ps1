param (
    [Parameter(Mandatory)]
    $Name,
    [Parameter(Mandatory)]
    $Location,
    [Parameter(Mandatory)]
    $ResourceGroupName
    )
$ErrorActionPreference = 'stop'
$rg = Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction silentlycontinue
if ($rg -eq $null) {
    $rg = New-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location
}

$acc = Get-AzureRmAutomationAccount -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction silentlycontinue
if ($acc -eq $null) {
    $acc = New-AzureRmAutomationAccount -Name $Name -ResourceGroupName $ResourceGroupName -Location $Location `
        -Plan Basic
}
$acc | Get-AzureRmAutomationRegistrationInfo | out-host
$acc