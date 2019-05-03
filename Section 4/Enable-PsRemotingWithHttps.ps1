#requires -RunAsAdministrator
param(
    $dnsName
    )

$cert = New-SelfSignedCertificate `
    -CertStoreLocation Cert:\LocalMachine\My `
    -DnsName $dnsName

Export-Certificate -Cert $cert -FilePath ".\$($dnsName).cer"
Enable-PSRemoting -Force
Remove-item wsman:\localhost\listener\listener* -Recurse
new-item -Path wsman:\localhost\listener -Transport HTTPS `
    -Address * -CertificateThumbPrint $cert.Thumbprint
New-NetFirewallRule -DisplayName 'WinRM (HTTPS-In)' `
    -Name 'WinRM/HTTPS' -Profile Any -LocalPort 5986 `
    -Protocol Tcp
Disable-NetFirewallRule -DisplayName `
    "Windows Remote Management (HTTP-In)"
