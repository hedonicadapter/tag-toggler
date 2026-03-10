#!/usr/bin/env bash
set -euo pipefail

# Variables
SUFFIX=$(date +%s)
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
STORAGE_NAME="demofuncstore$SUFFIX"
APP_NAME="demo-func-$SUFFIX"

# cleanup() {
# 	set +e
# 	echo "Cleaning up resources inside $RG_NAME (keeping the resource group)"
# 	if [[ -n "${RG_NAME:-}" ]] && [[ "$(az group exists --name "$RG_NAME" --output tsv 2>/dev/null)" == "true" ]]; then
# 		RESOURCE_IDS=$(az resource list --resource-group "$RG_NAME" --query "[].id" -o tsv 2>/dev/null)
# 		if [[ -n "$RESOURCE_IDS" ]]; then
# 			az resource delete --ids $RESOURCE_IDS --output none
# 			echo "Deleted resources inside $RG_NAME."
# 		else
# 			echo "No resources to delete inside $RG_NAME."
# 		fi
# 	else
# 		echo "Resource Group $RG_NAME not found; skipping cleanup."
# 	fi
# }
# trap cleanup EXIT

echo "==========================================="
echo " Azure Functions Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
	echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
	exit 1
fi

echo "2. Creating Storage Account: $STORAGE_NAME"
az storage account create --name $STORAGE_NAME --location $LOCATION --resource-group $RG_NAME --sku Standard_LRS --output none

echo "3. Deploying Function App: $APP_NAME"
# Deploy a Consumption plan function app
az functionapp create --resource-group $RG_NAME --consumption-plan-location $LOCATION --runtime node --runtime-version 18 --functions-version 4 --name $APP_NAME --storage-account $STORAGE_NAME --output none

# echo "4. Stopping Function App..."
# az functionapp stop --resource-group $RG_NAME --name $APP_NAME
# echo "Function App Stopped."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "5. Starting Function App..."
# az functionapp start --resource-group $RG_NAME --name $APP_NAME
# echo "Function App Started."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "6. Cleanup will run automatically on exit."
