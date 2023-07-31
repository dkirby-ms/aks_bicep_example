# AKS Bicep Example

This repo provides sample Azure Bicep files for deploying AKS and associated resources for an Azure application via Azure Developer CLI.

## Deployment (WIP)

* Install Azure CLI and Azure Developer CLI into your local environment.

* Clone this repo.

* Login to Azure CLI using an account with Owner permissions on the subscription you intend to use.

    ```shell
    az login
    ```

* Run ```azd init``` to initialize the project in your local environment.

    ```shell
    azd init
    ```

* Run ```azd up``` to deploy and configure resources.

    ```shell
    azd up
    ```
