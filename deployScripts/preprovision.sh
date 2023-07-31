#!/bin/bash
########################################################################
# Create SSH RSA Public Key
########################################################################
echo "Creating SSH RSA Public Key..."
file="videoai_rsa"

# Generate the SSH key pair
ssh-keygen -q -t rsa -b 4096 -f $file -N '""' 

# Get the public key
AZURE_PUBLIC_SSH_KEY=$(cat $file.pub)

# Escape the backslashes 
#AZURE_PUBLIC_SSH_KEY=$AZURE_PUBLIC_SSH_KEY.Replace("\", "\\")

# set the env variable
azd env set AZURE_PUBLIC_SSH_KEY "$AZURE_PUBLIC_SSH_KEY"

########################################################################
# Get the logged in user's object ID and tenant ID
########################################################################
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
azd env set USER_OBJECT_ID "$USER_OBJECT_ID"
TENANT_ID=$(az account show --query tenantId -o tsv)
azd env set TENANT_ID "$TENANT_ID"
