$appRepo = "https://github.com/microsoft/azure-arc-jumpstart-apps"
$ingressNamespace = "ingress-nginx"
$appNamespace = "hello-world"
$certname = "ingress-cert"
$certdns = "videoai.demo.xyz"
$rgName = $ENV:AZURE_RESOURCE_GROUP
$clusterName = $env:AKS_CLUSTER_NAME
$keyVaultName = $env:KEYVAULT_NAME
$tenantId = $Env:TENANT_ID

az config set extension.use_dynamic_install=yes_without_prompt

# Get AKS credential and create namespaces
az aks get-credentials --resource-group $rgName --name $clusterName
kubectl get nodes
kubectl create namespace $ingressNamespace
kubectl create namespace $appNamespace

# Create GitOps config for NGINX Ingress Controller
Write-Host "Creating GitOps config for NGINX Ingress Controller"
az k8s-configuration flux create `
    --cluster-name $clusterName `
    --resource-group $rgName `
    --name config-nginx `
    --namespace $ingressNamespace `
    --cluster-type connectedClusters `
    --scope cluster `
    --url $appRepo `
    --branch main --sync-interval 3s `
    --kustomization name=nginx path=./nginx/release

# Create GitOps config for Hello-Arc application
Write-Host "Creating GitOps config for Hello-Arc application"
az k8s-configuration flux create `
    --cluster-name $clusterName `
    --resource-group $rgName `
    --name config-helloarc `
    --namespace hello-arc `
    --cluster-type connectedClusters `
    --scope namespace `
    --url $appRepo `
    --branch main --sync-interval 3s `
    --kustomization name=helloarc path=./hello-arc/yaml

# Install Key Vault extension on AKS cluster and set permissions for the user assigned identity to allow importing certificates
Write-Host "Installing Azure Key Vault Kubernetes extension instance"
az aks enable-addons --addons azure-keyvault-secrets-provider --name $clusterName --resource-group $rgName
$userAssignedClientId = az aks show -g $rgName -n $clusterName --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
az keyvault set-policy -n $keyVaultName --key-permissions get --spn $userAssignedClientId
az keyvault set-policy -n $keyVaultName --secret-permissions get --spn $userAssignedClientId
az keyvault set-policy -n $keyVaultName --certificate-permissions get list import --spn $userAssignedClientId

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

# Update yaml placeholder values
$pathToYaml = ".\artifacts\hello-arc.yaml"
$modifiedYaml = "hello-arc-modified.yaml"
Copy-Item -Path $pathToYaml -Destination $modifiedYaml -Force
(Get-Content -path $modifiedYaml -Raw) -Replace '\{JS_CERTNAME}', $certname | Set-Content -Path $_.FullName
(Get-Content -path $modifiedYaml -Raw) -Replace '\{JS_KEYVAULTNAME}', $keyVaultName | Set-Content -Path $_.FullName
(Get-Content -path $modifiedYaml -Raw) -Replace '\{JS_HOST}', $certdns | Set-Content -Path $_.FullName
(Get-Content -path $modifiedYaml -Raw) -Replace '\{JS_TENANTID}', $tenantId | Set-Content -Path $_.FullName

# Deploy ingress controller
kubectl --namespace $appNamespace apply -f $modifiedYaml
$ip = kubectl get service/ingress-nginx-controller --namespace $ingressNamespace --output=jsonpath='{.status.loadBalancer.ingress[0].ip}'
Write-Host "Hello-arc service IP: $ip"
#Add-Content -Path $Env:windir\System32\drivers\etc\hosts -Value "`n`t$ip`t$certdns" -Force

