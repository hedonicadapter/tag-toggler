#!/usr/bin/env bash
set -euo pipefail

# Variables
SUFFIX=$(date +%s)
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
CONTAINER_NAME="demo-aci-$SUFFIX"

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
echo " Azure Container Instances (ACI) Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
  echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
  exit 1
fi

echo "2. Deploying Container Instance: $CONTAINER_NAME"
az container create \
  --resource-group $RG_NAME \
  --name $CONTAINER_NAME \
  --image mcr.microsoft.com/azuredocs/aci-helloworld \
  --dns-name-label $CONTAINER_NAME \
  --ports 80 \
  --cpu 0.5 \
  --memory 1.0 \
  --output none

# echo "3. Stopping Container Instance..."
# az container stop --resource-group $RG_NAME --name $CONTAINER_NAME
# echo "ACI Stopped."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "4. Starting Container Instance..."
# az container start --resource-group $RG_NAME --name $CONTAINER_NAME
# echo "ACI Started."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "5. Cleanup will run automatically on exit."
