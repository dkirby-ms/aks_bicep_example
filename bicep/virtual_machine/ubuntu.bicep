@description('The name of you Virtual Machine')
param vmName string = 'UbuntuServer-VM1'

@description('Username for the Virtual Machine')
param adminUsername string = 'admin'

@description('SSH Key for the Virtual Machine. SSH key is recommended over password')
@secure()
param sshRSAPublicKey string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version')
@allowed([
  '20_04-lts-gen2'
])
param ubuntuOSVersion string = '20_04-lts-gen2'

@description('Location for all resources.')
param azureLocation string = resourceGroup().location

@description('The size of the VM')
param vmSize string = 'Standard_B4ms'

@description('Resource Id of the subnet in the virtual network')
param subnetId string

param resourceTags object = {
  Project: 'VideoAI'
}

@description('The base URL used for accessing artifacts and automation artifacts')
param templateBaseUrl string

var publicIpAddressName = '${vmName}-PIP'
var networkInterfaceName = '${vmName}-NIC'
var osDiskType = 'Premium_LRS'
var PublicIP = {
  id: publicIpAddress.id
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: networkInterfaceName
  location: azureLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: PublicIP
        }
      }
    ]
  }
}

resource publicIpAddress 'Microsoft.Network/publicIpAddresses@2022-01-01' = {
  name: publicIpAddressName
  location: azureLocation
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: azureLocation
  tags: resourceTags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        name: '${vmName}-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshRSAPublicKey
            }
          ]
        }
      }
    }
  }
}

resource vmInstallscriptK3s 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: vm
  name: 'installscript'
  location: azureLocation
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      commandToExecute: 'bash installscript.sh ${templateBaseUrl}'
      fileUris: [
        '${templateBaseUrl}artifacts/installscript.sh'
      ]
    }
  }
}
