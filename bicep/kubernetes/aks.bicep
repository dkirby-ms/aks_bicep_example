@description('The name of the Staging Kubernetes cluster resource')
param aksClusterName string = 'VideoAI-AKS'

@description('The location of the Managed Cluster resource')
param location string = resourceGroup().location

@description('Sample Resource tag')
param resourceTags object = {
  Project: 'VideoAI'
}

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN')
param dnsPrefixStaging string = 'videoai'

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The number of nodes for the cluster')
@minValue(1)
@maxValue(50)
param agentCount int = 3

@description('The size of the Virtual Machine')
param agentVMSize string = 'Standard_D4s_v4'

@description('User name for the Linux Virtual Machines')
param linuxAdminUsername string = 'videoadmin'

@description('Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
param sshRSAPublicKey string

@description('boolean flag to turn on and off of RBAC')
param enableRBAC bool = true

@description('The name of the staging aks subnet')
param aksSubnetId string

@description('Name of the Azure Container Registry')
param acrName string = 'videoaiacr'

@description('Provide a tier of your Azure Container Registry.')
param acrSku string = 'Basic'

@description('The type of operating system')
@allowed([
  'Linux'
])
param osType string = 'Linux'
var tier  = 'free'

@description('The version of Kubernetes')
param kubernetesVersion string = '1.25.6'

var serviceCidr = '10.21.64.0/19'
var dnsServiceIP = '10.21.64.10'
var dockerBridgeCidr = '172.18.0.1/16'

resource aks 'Microsoft.ContainerService/managedClusters@2023-03-02-preview' = {
  location: location
  name: aksClusterName
  tags: resourceTags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: tier
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: enableRBAC
    dnsPrefix: dnsPrefixStaging
    aadProfile: {
      managed: true
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        mode: 'System'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: osType
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksSubnetId
      }
    ]
    storageProfile:{
      diskCSIDriver: {
        enabled: true
      }
    }
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
    }
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshRSAPublicKey
          }
        ]
      }
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' ={
  name: acrName
  location: location
  tags: resourceTags
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
  }
}
