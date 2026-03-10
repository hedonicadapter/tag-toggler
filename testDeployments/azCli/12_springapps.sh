#!/usr/bin/env bash
set -euo pipefail

# Variables
SUFFIX=$(date +%s)
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
SERVICE_NAME="demospringsvc$SUFFIX"
APP_NAME="demo-app-$SUFFIX"

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
echo " Azure Spring Apps Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
  echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
  exit 1
fi

echo "2. Deploying Spring Apps Service: $SERVICE_NAME (Requires spring extension, takes several minutes)"
az extension add --name spring --upgrade --yes
az spring create \
  --resource-group $RG_NAME \
  --name $SERVICE_NAME \
  --location $LOCATION \
  --sku Basic \
  --output none

echo "3. Creating Spring App inside service: $APP_NAME"
az spring app create \
  --resource-group $RG_NAME \
  --service $SERVICE_NAME \
  --name $APP_NAME \
  --assign-endpoint true \
  --output none

# echo "4. Stopping Spring App..."
# az spring app stop \
#   --resource-group $RG_NAME \
#   --service $SERVICE_NAME \
#   --name $APP_NAME
# echo "Spring App Stopped."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "5. Starting Spring App..."
# az spring app start \
#   --resource-group $RG_NAME \
#   --service $SERVICE_NAME \
#   --name $APP_NAME
# echo "Spring App Started."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "6. Cleanup will run automatically on exit."
