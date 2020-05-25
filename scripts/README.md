## Installing OAM in remote mode

This script can be used on a Linux VM to install minikube, Crossplane, and the Azure provider to manage a remote AKS cluster.

This has been tested using the UbuntuLTS image - but the script should work on any `apt` based system.

### Prerequisites

#### Service Principal

Crossplane needs a Service Principal so that it can manage resources for you.

Follow the instructions [here](https://crossplane.io/docs/v0.11/getting-started/install-configure.html) for `Select Provider -> Azure -> Get Azure Principal Keyfile`. You do not install or configurat anything other than the service principal now, just make sure to create `creds.json` and run all of the listed commands to grant permissions. 

#### Create Resource Group

This walkthrough will provide a resource group to Crossplane, where it will place provisioned resources. You can use the same resource group for the control plane VM and the provisioned resources if you prefer.

```sh
az group create --name <resource-group> --location <location>
```

Make a note of the resource group and location you choose for reference later.

#### Azure VM

This walkthrough uses minikube to run a local install of kubernetes for Crossplane. As a result you will need an Azure VM that supports nested virtualization (Dsv3 series).

Create one using the following command as a template:

```sh
az vm create \
  --resource-group <resource-group> \
  --name <vm-name> \
  --size Standard_D4s_v3  \
  --image UbuntuLTS \
  --admin-username azureuser \
  --generate-ssh-keys
```

Make a note of the public IP address of the created VM as you will need it to connect to the machine.

### Running the script

#### Copying Files

You will need to get your Azure Service Principal credentials and the provided script onto the Azure VM.

```sh
# ssh into the VM interactively to add it to the known hosts
ssh azureuser@<ip-address>
exit

scp creds.json azureuser@<ip-address>:/home/azureuser/creds.json
scp install-oam-remote.sh azureuser@<ip-address>:/home/azureuser/install-oam-remote.sh
```

#### Running the script

Log into the VM if you haven't.

```sh
ssh azureuser@<ip-address>
```

Run the script (`creds.json` should be in your working directory already)

```sh
./install-oam-remote-.sh <resource-group> <location> "$(base64 ./creds.json | tr -d '\n')"
```

When the script is finished, it will print the name of the created AKS cluster. You are now ready to deploy OAM applications.

Note that with remote mode you use `kubectl` with the minikube instance on the control plane VM - and your applications are actually deployed to the AKS cluster.