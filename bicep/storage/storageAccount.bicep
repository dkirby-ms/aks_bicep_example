@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

var contentStorageAccountName = 'content${uniqueString(resourceGroup().id)}'
var stagingStorageAccountName = 'staging${uniqueString(resourceGroup().id)}'

resource contentStorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: contentStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

resource stagingStorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: stagingStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

output contentStorageAccountName string = contentStorageAccountName
