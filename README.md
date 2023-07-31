# AKS Bicep Example

This repo provides sample Azure Bicep files for deploying AKS and associated resources for an Azure application via Azure Developer CLI.

## Deployment (WIP)

* Install [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) into your local environment.

* Install [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd?tabs=winget-windows%2Cbrew-mac%2Cscript-linux&pivots=os-windows) into your local environment.

* Clone this repo.

* Login to Azure CLI using an account with Owner permissions on the subscription you intend to use.

    ```shell
    az login
    ```

* Install providers and tools

    ```shell
    az aks install-cli
    az provider register --namespace Microsoft.Kubernetes --wait
    az provider register --namespace Microsoft.ContainerService --wait
    az provider register --namespace Microsoft.KubernetesConfiguration --wait
    ```

* Run ```azd init``` to initialize the project in your local environment.

    ```shell
    azd init
    ```

* Run ```azd up``` to deploy and configure resources.

    ```shell
    azd up
    ```
