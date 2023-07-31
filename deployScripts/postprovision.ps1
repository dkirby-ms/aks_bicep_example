$appRepo = "https://github.com/microsoft/azure-arc-jumpstart-apps"
$ingressNamespace = "ingress-nginx"
$certname = "ingress-cert"
$certdns = "videoai.demo.xyz"
$rgName = $ENV:AZURE_RESOURCE_GROUP
$clusterName = $env:AKS_CLUSTER_NAME
$keyVaultName = $env:KEYVAULT_NAME
$tenantId = $env:

az config set extension.use_dynamic_install=yes_without_prompt

# Get AKS credential and create namespaces
az aks get-credentials --resource-group $rgName --name $clusterName
kubectl get nodes
kubectl create namespace $ingressNamespace
kubectl create namespace "hello-world"

# Create TLS certificate for ingress controller
Write-Host "Creating self-signed TLS certificate"
Install-Module pki
$cert = New-SelfSignedCertificate -DnsName $certdns -KeyAlgorithm RSA -KeyLength 2048 -NotAfter (Get-Date).AddYears(1) -CertStoreLocation "Cert:\CurrentUser\My"
$certPassword = ConvertTo-SecureString -String "certpassword" -Force -AsPlainText
Export-PfxCertificate -Cert "cert:\CurrentUser\My\$($cert.Thumbprint)" -FilePath "$certname.pfx" -Password $certPassword
Write-Host "Importing the TLS certificate to Key Vault"
az keyvault certificate import `
    --vault-name $keyVaultName `
    --password $certPassword `
    --name $certname `
    --file "$certname.pfx"

# Install Key Vault extension on AKS cluster
Write-Host "Installing Azure Key Vault Kubernetes extension instance"
az k8s-extension create --name 'akvsecretsprovider' `
    --extension-type Microsoft.AzureKeyVaultSecretsProvider `
    --scope cluster `
    --cluster-name $clusterName `
    --resource-group $rgName `
    --cluster-type connectedClusters `
    --release-namespace kube-system `
    --configuration-settings 'secrets-store-csi-driver.enableSecretRotation=true' 'secrets-store-csi-driver.syncSecret.enabled=true'

# Update yaml placeholder values
$pathToYaml = ".\artifacts\hello-arc.yaml"
$modifiedYaml = "hello-arc-modified.yaml"
CopyItem -Path $pathToYaml -Destination $modifiedYaml
(Get-Content -path $modifiedYaml -Raw) -Replace '\{JS_CERTNAME}', $certname | Set-Content -Path $_.FullName
(Get-Content -path $modifiedYaml -Raw) -Replace '\{JS_KEYVAULTNAME}', $keyVaultName | Set-Content -Path $_.FullName
(Get-Content -path $modifiedYaml -Raw) -Replace '\{JS_HOST}', $certdns | Set-Content -Path $_.FullName
(Get-Content -path $modifiedYaml -Raw) -Replace '\{JS_TENANTID}', $Env:TENANT_ID | Set-Content -Path $_.FullName