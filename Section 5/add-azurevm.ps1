param(
    $resourceGroupName,
    $location,
    $vmname
)

$rg = New-AzureRmResourceGroup -Name $resourceGroupName `
    -Location $location

$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name "default" `
    -AddressPrefix 192.168.1.0/24

$vnet = New-AzureRmVirtualNetwork -Name "$($rg.ResourceGroupName)-vnet" `
    -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location `
    -AddressPrefix 192.168.0.0/16 -Subnet $subnet

$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name 'allow-rdp' `
    -Protocol Tcp -Direction Inbound -SourcePortRange * `
    -SourceAddressPrefix * -DestinationPortRange 3389 `
    -DestinationAddressPrefix * -Access Allow -Priority 1000

$nsgRuleWSMan = New-AzureRmNetworkSecurityRuleConfig -Name 'allow-wsman' `
    -Protocol Tcp -Direction Inbound -Priority 1001 `
    -SourceAddressPrefix * -SourcePortRange * `
    -DestinationPortRange 5986 -DestinationAddressPrefix * `
    -Access Allow

$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rg.ResourceGroupName `
    -Location $rg.Location -Name "$VMName-nsg" `
    -SecurityRules $nsgRuleRDP, $nsgRuleWSMan

$pip = New-AzureRmPublicIpAddress -Name $vmname `
    -ResourceGroupName $rg.ResourceGroupName `
    -Location $rg.Location -AllocationMethod Static

$nic = New-AzureRmNetworkInterface -Name "$VMName-primarynic" `
    -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id `
    -NetworkSecurityGroupId $nsg.Id

$vault = New-AzureRmKeyVault -VaultName "poshkeys" -ResourceGroupName `
    $rg.ResourceGroupName -Location $rg.Location `
    -EnabledForDeployment -EnabledForTemplateDeployment

$cert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\my `
    -KeySpec KeyExchange -DnsName $VMName

$password = Read-Host -Prompt 'Enter password for private key' -AsSecureString

Export-PfxCertificate -Cert $cert -FilePath "$vmname.pfx" -Password $password

$certBytes = Get-Content -Path ".\$vmname.pfx" -Encoding Byte

$certBase64 = [System.Convert]::ToBase64String($certBytes)
$certInfo = @{'data'=$certBase64;'dataType'='pfx';'password'=$password}
$certInfoJson = ConvertTo-Json $certInfo
$certInfoBytes = [System.Text.Encoding]::UTF8.GetBytes($certInfoJson)
$certInfoBase64 = = [System.Convert]::ToBase64String($certInfoBytes)
$secret = ConvertTo-SecureString -String $certInfoBase64 -AsPlainText -Force
$certSecret = Set-AzureKeyVaultSecret -VaultName $vault.VaultName -Name "$VMName-cert" -SecretValue $secret

New-AzureRmVmConfig -Name $vmname -VMSize Standard_d2 `
    | Add-AzureRmVMSecret -SourceVaultId $vault.ResourceId `
        -CertificateStore "my" -CertificateUrl $certSecret.Id `
    | Add-AzureRmVMNetworkInterface -Id $nic.Id `
    | Set-AzureRmVMOperatingSystem -Windows -ComputerName $vm.Name `
        -Credential (Get-Credential) -WinRMHttps `
        -WinRMCertificateUrl $certSecret.Id `
    | Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer `
        -Offer WindowsServer -Version latest -Skus 2016-datacenter `
    | New-AzureRmVM -ResourceGroupName $rg.ResourceGroupName `
        -Location  $rg.Location
