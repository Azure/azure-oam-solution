# Azure OAM Deployment

This reposititory contains instructions and scripts for easily getting an OAM-enabled Kubernetes cluster running on Azure using Crossplane.

## Getting Started

### Prerequisites

The tutorial uses commands that assume an Posix-like shell environment. 

- Linux
- macOS
- Windows with WSL

#### Install azoam CLI

You can download the azoam CLI from this repository. Feel free to install to your path or run from the local directory depending on your preferences.

**Linux / Windows with WSL**

```sh
curl -O https://github.com/Azure/azure-oam-solution/raw/master/tools/linux_amd64/azoam
chmod +x ./azoam
```

**macOS**

```sh
curl -O https://github.com/Azure/azure-oam-solution/raw/master/tools/macos_amd64/azoam
chmod +x ./azoam
```

#### Install Azure CLI

These instructions use the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).

#### Install jq

[Install jq](https://stedolan.github.io/jq/download/) to process JSON output.

#### Install kubectl

These instructions use [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to deploy to Kubernetes.

#### Create Service Principal

```sh
# log in to azure (if not logged in)
az login

# create service principal permissions limited to this subscription
az ad sp create-for-rbac --sdk-auth --role Contributor > "creds.json"
```

Verify the credential's file is present:
```sh
ls creds.json
```

#### Resource Group

Choose a name for the resource group:
```sh
export OAM_TUTORIAL_RESOURCE_GROUP_NAME=<name>
```

Example:
```sh
export OAM_TUTORIAL_RESOURCE_GROUP_NAME=oam-tutorial
```

If you already have a resource group and don't want to create a new one, run the command *above* and skip the command below.

```sh
# log in to azure (if not logged in)
az login

az group create --name $OAM_TUTORIAL_RESOURCE_GROUP_NAME --location <location>
```

Example:
```sh
az group create --name $OAM_TUTORIAL_RESOURCE_GROUP_NAME --location westus2
```

#### Generate SSH Key

Check if you have an ssh key:

```sh
ls ~/.ssh/id_rsa.pub
```

If file is not present, generate an ssh key:

```sh
ssh-keygen
```

Keep all defaults, and the output should be something like:
```sh
Generating public/private rsa key pair.
Enter file in which to save the key (/home/user/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/user/.ssh/id_rsa.
Your public key has been saved in /home/user/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX user@pc
The key's randomart image is:
+---[RSA 2048]----+
|    .      ..Xo..|
|   . . .  . .o.X.|
|    . . o.  ..+ B|
|   .   o.o  .+ ..|
|    ..o.X   X..  |
|   . %o=      .  |
|    @.B...     . |
|   o.=. X. . .  .|
|    .oo  E. . .. |
+----[SHA256]-----+
```

Make a note of the resource group name you choose for reference later.

### Apply ARM template

Run the following command to deploy a Kubernetes cluster with support for OAM.

```sh
az deployment group create \
  --template-uri https://raw.githubusercontent.com/Azure/azure-oam-solution/master/template.json \
  --resource-group $OAM_TUTORIAL_RESOURCE_GROUP_NAME \
  --parameter "sshRSAPublicKey=$(cat ~/.ssh/id_rsa.pub)" \
  --parameter "servicePrincipalClientId=$(jq '.clientId' --raw-output) creds.json" \
  --parameter "servicePrincipalClientSecret=$(jq '.clientSecret' --raw-output) creds.json"
```

### Find the created AKS cluster

When the ARM template completes successfully you will have an AKS cluster in the provided resource group.

```sh
az aks list --resource-group $OAM_TUTORIAL_RESOURCE_GROUP_NAME
```

Export the AKS cluster name to a environment variable:

```sh
export OAM_TUTORIAL_AKS_CLUSTER_NAME=$(az aks list --resource-group $OAM_TUTORIAL_RESOURCE_GROUP_NAME --query '[].name' -o tsv)
```

```sh
az aks get-credentials --name $OAM_TUTORIAL_AKS_CLUSTER_NAME --resource-group $OAM_TUTORIAL_RESOURCE_GROUP_NAME
```
Now you should have credentials in your Kubernetes configuration for the AKS cluster. Now you can use `kubectl` to deploy some workloads using OAM.

## Complete the tutorial

Once you can access the AKS cluster you're ready to go!

Find the tutorial [here](tutorial/README.md).

## Cleaning Up

All of the resources created by this tutorial are all part of the same resource group. To delete all of the resources run the following command.

```sh
az group delete --name  $OAM_TUTORIAL_RESOURCE_GROUP_NAME --yes
```

Run the following to delete the service principal.

```sh
az ad sp delete --id "$(<creds.json | jq '.clientId' | xargs -I CLIENTID az ad sp list --filter \"appId eq 'CLIENTID'\" --query '[0].servicePrincipalNames[0]' -o tsv)"
```

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
