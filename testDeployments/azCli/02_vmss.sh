#!/usr/bin/env bash
set -euo pipefail

# Variables
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
VMSS_NAME="demovmss"
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
echo " Azure Virtual Machine Scale Set (VMSS) Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
  echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
  exit 1
fi

echo "2. Deploying Virtual Machine Scale Set: $VMSS_NAME"
az vmss create \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --image $IMAGE \
  --vm-sku Standard_B1ls \
  --instance-count 1 \
  --priority Spot \
  --max-price -1 \
  --upgrade-policy-mode manual \
  --admin-username azureuser \
  --generate-ssh-keys \
  --output none
# echo "3. Stopping (Deallocating) VMSS..."
# az vmss deallocate --resource-group $RG_NAME --name $VMSS_NAME

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "4. Starting VMSS..."
# az vmss start --resource-group $RG_NAME --name $VMSS_NAME

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "5. Cleanup will run automatically on exit."
