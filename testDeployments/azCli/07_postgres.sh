#!/usr/bin/env bash
set -euo pipefail

# Variables
SUFFIX=$(date +%s)
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
SERVER_NAME="demo-pg-server-$SUFFIX"

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
echo " Azure Database for PostgreSQL Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
  echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
  exit 1
fi

echo "2. Deploying PostgreSQL Flexible Server: $SERVER_NAME (Can take several minutes)"
az postgres flexible-server create \
  --resource-group $RG_NAME \
  --name $SERVER_NAME \
  --location $LOCATION \
  --admin-user pgadmin \
  --admin-password "P@ssw0rd1234!" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --backup-retention 7 \
  --geo-redundant-backup Disabled \
  --high-availability Disabled \
  --output none

# echo "3. Stopping PostgreSQL Server..."
# az postgres flexible-server stop --resource-group $RG_NAME --name $SERVER_NAME
# echo "Server Stopped."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "4. Starting PostgreSQL Server..."
# az postgres flexible-server start --resource-group $RG_NAME --name $SERVER_NAME
# echo "Server Started."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "5. Cleanup will run automatically on exit."
