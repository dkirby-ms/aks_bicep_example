@minLength(1)
@maxLength(77)
@description('Prefix for resource group, i.e. {name}-rg')
param envName string

@description('RSA public key used for securing SSH access to resources')
@secure()
param sshRSAPublicKey string

@description('Target GitHub account')
param githubAccount string = 'dkirby-ms'

@description('Target GitHub branch')
param githubBranch string = 'master'

@description('ObjectId of the named user or service principal that should be granted access to key vault via template deployment')
param keyVaultUserObjectId string

@description('Location is the Azure region where the template resources will be deployed')
param location string

var templateBaseUrl = 'https://raw.githubusercontent.com/${githubAccount}/aks_bicep_example/${githubBranch}/'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${envName}-rg'
  location: location
}

module network 'network/vnet.bicep' = {
  name: 'networkDeployment'
  scope: rg
  params: {
    location: location
  }
}

module ubuntu 'virtual_machine/ubuntu.bicep' = {
  name: 'ubuntuDeployment'
  scope: rg
  params: {
    sshRSAPublicKey: sshRSAPublicKey
    subnetId: network.outputs.subnetId
    templateBaseUrl: templateBaseUrl
    azureLocation: location
  }
}

module stagingStorageAccount 'storage/storageAccount.bicep' = {
  name: 'stagingStorageAccountDeployment'
  scope: rg
  params: {
    location: location
  }
}

module aks 'kubernetes/aks.bicep' = {
  name: 'aksDeployment'
  scope: rg
  params: {
    sshRSAPublicKey: sshRSAPublicKey
    location: location
    aksSubnetId: network.outputs.subnetId
  }
}

module eventhub 'messaging/eventhub.bicep' = {
  name: 'eventhubDeployment'
  scope: rg
  params: {
    location: location
    projectName: 'videoai'
  }
}

module keyVault 'management/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  scope: rg
  params: {
    location: location
    keyVaultName: 'videoaikv'
    objectId: keyVaultUserObjectId
    secretName: 'example_secret'
    secretValue: 'example_secret_value'
  }
}

output AZURE_RESOURCE_GROUP string = rg.name
output AKS_CLUSTER_NAME string = aks.outputs.clusterName
output KEYVAULT_NAME string = keyVault.outputs.KEYVAULT_NAME
