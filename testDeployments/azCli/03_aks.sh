#!/usr/bin/env bash
set -euo pipefail

# Variables
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
AKS_NAME="demo-aks-cluster"

# cleanup() {
#   set +e
#   echo "Cleaning up resources inside $RG_NAME (keeping the resource group)"
#   if [[ -n "${RG_NAME:-}" ]] && [[ "$(az group exists --name "$RG_NAME" --output tsv 2>/dev/null)" == "true" ]]; then
#     RESOURCE_IDS=$(az resource list --resource-group "$RG_NAME" --query "[].id" -o tsv 2>/dev/null)
#     if [[ -n "$RESOURCE_IDS" ]]; then
#       az resource delete --ids $RESOURCE_IDS --output none
#       echo "Deleted resources inside $RG_NAME."
#     else
#       echo "No resources to delete inside $RG_NAME."
#     fi
#   else
#     echo "Resource Group $RG_NAME not found; skipping cleanup."
#   fi
# }
# trap cleanup EXIT

echo "==========================================="
echo " Azure Kubernetes Service (AKS) Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
  echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
  exit 1
fi

echo "2. Deploying AKS Cluster: $AKS_NAME (this might take several minutes)"
az aks create \
  --resource-group $RG_NAME \
  --name $AKS_NAME \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys \
  --output none
# echo "3. Stopping AKS Cluster..."
# az aks stop --resource-group $RG_NAME --name $AKS_NAME
# echo "AKS Stopped."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "4. Starting AKS Cluster..."
# az aks start --resource-group $RG_NAME --name $AKS_NAME
# echo "AKS Started."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "5. Cleanup will run automatically on exit."
