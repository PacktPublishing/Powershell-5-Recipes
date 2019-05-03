param (
    [Parameter(Mandatory)]
    $ResourceGroupName,
    [Parameter(Mandatory)]
    $AutomationAccountName,
    [Parameter(Mandatory)]
    $ConfigurationName
    )
$ErrorActionPreference = 'stop'
$CompilationJob = Start-AzureRmAutomationDscCompilationJob `
    -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName `
    -ConfigurationName $ConfigurationName

Write-host 'Waiting for compilation job to finish' -NoNewLine

while($CompilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null)
{
    $CompilationJob = $CompilationJob | Get-AzureRmAutomationDscCompilationJob
    Write-host '.' -NoNewLine
    Start-Sleep -Seconds 3
}
Write-host 'done.'
$CompilationJob
$CompilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any
