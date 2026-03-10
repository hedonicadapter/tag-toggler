#!/usr/bin/env bash
set -euo pipefail

# Variables
SUFFIX=$(date +%s)
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
WS_NAME="demosynapsews$SUFFIX"
POOL_NAME="demopool"
STORAGE_NAME="synapsestore$SUFFIX"
FS_NAME="users"

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
echo " Azure Synapse Analytics Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
  echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
  exit 1
fi

echo "2. Deploying Data Lake Storage Gen2..."
az storage account create \
  --name $STORAGE_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --enable-hierarchical-namespace true \
  --output none

az storage fs create --name $FS_NAME --account-name $STORAGE_NAME --output none

echo "3. Deploying Synapse Workspace: $WS_NAME"
az synapse workspace create \
  --name $WS_NAME \
  --resource-group $RG_NAME \
  --storage-account $STORAGE_NAME \
  --file-system $FS_NAME \
  --sql-admin-login-user sqladminuser \
  --sql-admin-login-password "P@ssw0rd1234!" \
  --location $LOCATION \
  --output none

echo "4. Deploying Dedicated SQL Pool: $POOL_NAME"
az synapse sql pool create \
  --name $POOL_NAME \
  --workspace-name $WS_NAME \
  --resource-group $RG_NAME \
  --performance-level DW100c \
  --max-size-bytes 53687091200 \
  --output none

# echo "5. Pausing (Stopping) SQL Pool..."
# az synapse sql pool pause \
#   --name $POOL_NAME \
#   --workspace-name $WS_NAME \
#   --resource-group $RG_NAME
# echo "SQL Pool Paused."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "6. Resuming (Starting) SQL Pool..."
# az synapse sql pool resume \
#   --name $POOL_NAME \
#   --workspace-name $WS_NAME \
#   --resource-group $RG_NAME
# echo "SQL Pool Resumed."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "7. Cleanup will run automatically on exit."
