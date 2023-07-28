@description('Name of the VNet')
param virtualNetworkName string = 'VideoAI-VNet'

@description('Name of the subnet in the virtual network')
param subnetName string = 'VideoAI-Subnet'

@description('Azure Region to deploy the Log Analytics Workspace')
param location string = resourceGroup().location

@description('Name of the Network Security Group')
param networkSecurityGroupName string = 'VideoAI-NSG'

var addressPrefix = '10.16.0.0/16'
var subnetAddressPrefix = '10.16.1.0/24'
var primarySubnet = [
  {
    name: subnetName
    properties: {
      addressPrefix: subnetAddressPrefix
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      networkSecurityGroup: {
        id: networkSecurityGroup.id
      }
    }
  }
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets:  primarySubnet
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow_k8s_443'
        properties: {
          priority: 1005
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

output vnetId string = virtualNetwork.id
output subnetId string = virtualNetwork.properties.subnets[0].id
