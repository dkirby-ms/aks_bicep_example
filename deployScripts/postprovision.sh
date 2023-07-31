#!/bin/bash
appRepo="https://github.com/microsoft/azure-arc-jumpstart-apps"
ingressNamespace="ingress-nginx"
appNamespace="hello-world"
certname="ingress-cert"
certdns="videoai.demo.xyz"
rgName=$AZURE_RESOURCE_GROUP
clusterName=$AKS_CLUSTER_NAME
keyVaultName=$KEYVAULT_NAME
tenantId=$TENANT_ID

az config set extension.use_dynamic_install=yes_without_prompt

# Get AKS credential and create namespaces
az aks get-credentials --resource-group "$rgName" --name "$clusterName"
kubectl get nodes
kubectl create namespace $ingressNamespace
kubectl create namespace $appNamespace

# Create GitOps config for NGINX Ingress Controller
echo "Creating GitOps config for NGINX Ingress Controller"
az k8s-configuration flux create --cluster-name "$clusterName" --resource-group "$rgName" --name config-nginx --namespace $ingressNamespace --cluster-type managedClusters --scope cluster --url $appRepo --branch main --sync-interval 3s --kustomization name=nginx path=./nginx/release
provisioningState=""
while [ "$provisioningState" != "Succeeded" ]
do
    provisioningState=$(az aks show -g aks_bicep_example-dev-rg -n VideoAI-AKS --query provisioningState -o tsv)
done

# Create GitOps config for Hello-Arc application
echo "Creating GitOps config for Hello-Arc application"
az k8s-configuration flux create --cluster-name "$clusterName" --resource-group "$rgName" --name config-helloarc --namespace hello-arc --cluster-type managedClusters --scope namespace --url $appRepo --branch main --sync-interval 3s --kustomization name=helloarc path=./hello-arc/yaml
provisioningState=""
while [ "$provisioningState" != "Succeeded" ]
do
    provisioningState=$(az aks show -g aks_bicep_example-dev-rg -n VideoAI-AKS --query provisioningState -o tsv)
done

# Install Key Vault extension on AKS cluster and set permissions for the user assigned identity to allow importing certificates
echo "Installing Azure Key Vault Kubernetes extension instance"
az aks enable-addons --addons azure-keyvault-secrets-provider --name "$clusterName" --resource-group "$rgName"
userAssignedClientId=$(az aks show -g "$rgName" -n "$clusterName" --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
az keyvault set-policy -n "$keyVaultName" --key-permissions get --spn "$userAssignedClientId"
az keyvault set-policy -n "$keyVaultName" --secret-permissions get --spn "$userAssignedClientId"
az keyvault set-policy -n "$keyVaultName" --certificate-permissions get list import --spn "$userAssignedClientId"

# Create TLS certificate for ingress controller
echo "Creating self-signed TLS certificate"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $certname.pem -out $certname.pem -subj "/C=US/ST=LA/L=Covington/O=Dis/CN=$certdns"
#$cert = New-SelfSignedCertificate -DnsName $certdns -KeyAlgorithm RSA -KeyLength 2048 -NotAfter (Get-Date).AddYears(1) -CertStoreLocation "Cert:\CurrentUser\My"
#$certPassword = ConvertTo-SecureString -String "certpassword" -Force -AsPlainText
#Export-PfxCertificate -Cert "cert:\CurrentUser\My\$($cert.Thumbprint)" -FilePath "$certname.pfx" -Password $certPassword
echo "Importing the TLS certificate to Key Vault"
az keyvault certificate import --vault-name "$keyVaultName" --name $certname --file "$certname.pem"

# Update yaml placeholder values
pathToYaml="./artifacts/hello-arc.yaml"
modifiedYaml="hello-arc-modified.yaml"
cp $pathToYaml $modifiedYaml -f
sed -i "s/JS_CERTNAME/$certname/g" $modifiedYaml
sed -i "s/JS_KEYVAULTNAME/$keyVaultName/g" $modifiedYaml
sed -i "s/JS_HOST/$certdns/g" $modifiedYaml
sed -i "s/JS_TENANTID/$tenantId/g" $modifiedYaml

# Deploy ingress controller
kubectl --namespace $appNamespace apply -f $modifiedYaml
ip=$(kubectl get service/ingress-nginx-controller --namespace $ingressNamespace --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Hello-arc service IP: $ip"
#Add-Content -Path $Env:windir\System32\drivers\etc\hosts -Value "`n`t$ip`t$certdns" -Force

