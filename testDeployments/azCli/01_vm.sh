#!/usr/bin/env bash
set -euo pipefail

# Variables
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
VM_NAME="demo-vm"
IMAGE="Ubuntu2204"

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
echo " Azure Virtual Machine (VM) Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
  echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
  exit 1
fi

echo "2. Deploying Virtual Machine: $VM_NAME"
az vm create \
  --resource-group $RG_NAME \
  --name $VM_NAME \
  --image $IMAGE \
  --size Standard_B1ls \
  --priority Spot \
  --max-price -1 \
  --eviction-policy Deallocate \
  --admin-username azureuser \
  --generate-ssh-keys \
  --output none
# echo "3. Stopping (Deallocating) VM..."
# az vm deallocate --resource-group $RG_NAME --name $VM_NAME --no-wait
# echo "Waiting for VM to fully deallocate..."
# az vm wait --deallocated --resource-group $RG_NAME --name $VM_NAME
# echo "VM Stopped."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "4. Starting VM..."
# az vm start --resource-group $RG_NAME --name $VM_NAME --no-wait
# echo "Waiting for VM to fully start..."
# az vm wait --updated --resource-group $RG_NAME --name $VM_NAME
# echo "VM Started."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "5. Cleanup will run automatically on exit."
