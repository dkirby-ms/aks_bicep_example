# AKS Bicep Example

This repo provides sample Azure Bicep files for deploying AKS and associated resources for an Azure application.

## Deployment

```shell
az group create -n MyGroup -l eastus
az deployment group create -g MyGroup -f main.bicep -p main.parameters.json
```
