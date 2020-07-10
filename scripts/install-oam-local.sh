#!/usr/bin/env bash
set -eux

if [[ "$#" -ne 2 ]]
then
  echo "usage: install-oam-local.sh <resource-group> <cluster-name>"
  exit 1
fi

RESOURCE_GROUP=$1
CLUSTER_NAME=$2

az aks get-credentials --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP

KUBERNETES_VERSION="1.16.9"
KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
CROSSPLANE_VERSION="0.12.0"
CROSSPLANE_OAM_LOCAL_VERSION="0.1.0"

# Install kubectl - https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
chmod +x ./kubectl
./kubectl version --client

# Install helm - https://helm.sh/docs/intro/install/
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm version

# Install Crossplane - https://crossplane.io/docs/v0.12/getting-started/install-configure.html
./kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: crossplane-system
EOF

helm repo add crossplane-alpha https://charts.crossplane.io/alpha
helm install crossplane crossplane-alpha/crossplane \
  --namespace crossplane-system \
  --version "$CROSSPLANE_VERSION" \
  --wait

# Workaround https://github.com/crossplane/addon-oam-kubernetes-local/issues/50 
./kubectl create secret generic webhook-server-cert -n crossplane-system

helm install addon-oam-kubernetes-local crossplane-alpha/oam-core-resources \
  --namespace crossplane-system \
  --version "$CROSSPLANE_OAM_LOCAL_VERSION" \
  --wait
