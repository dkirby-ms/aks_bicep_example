@description('RSA public key used for securing SSH access to ArcBox resources')
@secure()
param sshRSAPublicKey string

@description('Target GitHub account')
param githubAccount string = 'dkirby-ms'

@description('Target GitHub branch')
param githubBranch string = 'main'

var templateBaseUrl = 'https://raw.githubusercontent.com/${githubAccount}/aks_bicep_example/${githubBranch}/'

var location = resourceGroup().location

module networkDeployment 'network/vnet.bicep' = {
  name: 'networkDeployment'
  params: {
    location: location
  }
}

module ubuntuDeployment 'virtual_machine/ubuntu.bicep' = {
  name: 'ubuntuDeployment'
  params: {
    sshRSAPublicKey: sshRSAPublicKey
    subnetId: networkDeployment.outputs.subnetId
    templateBaseUrl: templateBaseUrl
    azureLocation: location
  }
}

module stagingStorageAccountDeployment 'storage/storageAccount.bicep' = {
  name: 'stagingStorageAccountDeployment'
  params: {
    location: location
  }
}

module aksDeployment 'kubernetes/aks.bicep' = {
  name: 'aksDeployment'
  params: {
    sshRSAPublicKey: sshRSAPublicKey
    location: location
    aksSubnetId: networkDeployment.outputs.subnetId
  }
  dependsOn: [
    stagingStorageAccountDeployment
  ]
}
