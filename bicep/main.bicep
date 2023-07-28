@description('RSA public key used for securing SSH access to ArcBox resources')
@secure()
param sshRSAPublicKey string

@description('Target GitHub account')
param githubAccount string = 'dkirby-ms'

@description('Target GitHub branch')
param githubBranch string = 'master'

@description('ObjectId of the named user or service principal that should be granted access to key vault via template deployment')
param keyVaultUserObjectId string

@description('Location is the Azure region where the template resources will be deployed')
param location string = resourceGroup().location

var templateBaseUrl = 'https://raw.githubusercontent.com/${githubAccount}/aks_bicep_example/${githubBranch}/'

module network 'network/vnet.bicep' = {
  name: 'networkDeployment'
  params: {
    location: location
  }
}

module ubuntu 'virtual_machine/ubuntu.bicep' = {
  name: 'ubuntuDeployment'
  params: {
    sshRSAPublicKey: sshRSAPublicKey
    subnetId: network.outputs.subnetId
    templateBaseUrl: templateBaseUrl
    azureLocation: location
  }
}

module stagingStorageAccount 'storage/storageAccount.bicep' = {
  name: 'stagingStorageAccountDeployment'
  params: {
    location: location
  }
}

module aks 'kubernetes/aks.bicep' = {
  name: 'aksDeployment'
  params: {
    sshRSAPublicKey: sshRSAPublicKey
    location: location
    aksSubnetId: network.outputs.subnetId
  }
}

module eventhub 'messaging/eventhub.bicep' = {
  name: 'eventhubDeployment'
  params: {
    location: location
    projectName: 'videoai'
  }
}

module keyVault 'management/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    keyVaultName: 'videoai_kv'
    objectId: keyVaultUserObjectId
    secretName: 'example_secret'
    secretValue: 'example_secret_value'
  }
}
