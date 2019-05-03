param(
    $resourceGroupName,
    $location,
    $webapp
)

$rg = New-AzureRmResourceGroup -Name $resourceGroupName `
    -Location $location

$plan = New-AzureRmAppServicePlan -Tier Standard -WorkerSize Small `
	-NumberofWorkers 1 -ResourceGroupName $rg.ResourceGroupame `
	-Location $rg.Location -Name "$($webapp)plan"

New-AzureRmWebApp -Name $webapp -ResourceGroupName `
	$rg.ResourceGroupName -Location $rg.Location `
    -AppServicePlan $plan.Name
