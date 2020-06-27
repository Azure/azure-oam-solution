# Azure OAM Deployment

This reposititory contains instructions and scripts for easily getting an OAM-enabled Kubernetes control plane running on Azure using Crossplane.

## Getting Started

### Prerequisites

#### Install Azure CLI

These instructions use the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).

#### Install jq

[Install jq](https://stedolan.github.io/jq/download/) to process JSON output.

#### Service Principal

Crossplane needs a Service Principal so that it can manage resources for you.

You can use the script provided at `scripts/create-service-principal.sh` (requires `jq`) OR follow the instructions [here](https://crossplane.io/docs/v0.11/getting-started/install-configure.html) for `Select Provider -> Azure -> Get Azure Principal Keyfile`. You do not install or configure anything other than the service principal now, just make sure to create `creds.json` and run all of the listed commands to grant permissions.

```sh
# log in to azure (if not logged in)
az login

wget -q https://raw.githubusercontent.com/Azure/azure-oam-solution/master/scripts/create-service-principal.sh -O - | /bin/bash
```

Verify the credential's file is present:
```sh
ls creds.json
```

#### Resource Group

This walkthrough will provide a resource group to Crossplane, where it will place provisioned resources.

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

Run (or customize) the following command to deploy the OAM control plane.

**Bash/Zsh**:
```sh
az deployment group create \
  --template-uri https://raw.githubusercontent.com/Azure/azure-oam-solution/master/template.json \
  --resource-group $OAM_TUTORIAL_RESOURCE_GROUP_NAME  \
  --parameter "adminPasswordOrKey=$(<~/.ssh/id_rsa.pub)" \
  --parameter "servicePrincipal=$(<creds.json)"
```

The ARM template in this repo is based on the ARM template found [here](https://azure.microsoft.com/en-us/resources/templates/101-vm-simple-linux/). This documentation covers the supported parameters.

The `adminPasswordOrKey` parameter in this example command uses an existing SSH public key in `~/.ssh/id_rsa.pub`.

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
Now you should have credentials in your Kubernetes configuration for the AKS cluster. Your workloads will be deployed in this Kubernetes cluster.

### Connect to the control plane VM

Extract the VM's *public* IP address:
```
export OAM_TUTORIAL_VM_IP=$(az vm list-ip-addresses -g $OAM_TUTORIAL_RESOURCE_GROUP_NAME --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)
```

The created VM IP address should be part of the command output.

```sh
ssh azureuser@$OAM_TUTORIAL_VM_IP
```

The OAM control plane is running in Minikube on the VM that you just logged into. Minikube will be stopped when you first log in.

```sh
minikube start
```

Now you can use `kubectl` to deploy some workloads using OAM.

## Complete the tutorial

Once you can log into the control plane VM and access the AKS cluster you're ready to go!

Find the tutorial [here](tutorial/README.md).

## Cleaning Up

All of the resources created by Crossplane, your control plane VM, and AKS cluster are all part of the same resource group. To delete all of the resources run the following command.

```sh
az group delete --name  $OAM_TUTORIAL_RESOURCE_GROUP_NAME --yes
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
