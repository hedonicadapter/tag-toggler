#!/usr/bin/env bash
set -euo pipefail

# Variables
SUFFIX=$(date +%s)
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
PLAN_NAME="demo-app-plan-$SUFFIX"
APP_NAME="demo-webapp-$SUFFIX"

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
echo " Azure App Service (Web App) Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
	echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
	exit 1
fi

echo "2. Creating App Service Plan: $PLAN_NAME"
az appservice plan create --name $PLAN_NAME --resource-group $RG_NAME --sku B1 --is-linux --output none

echo "3. Deploying Web App: $APP_NAME"
az webapp create --resource-group $RG_NAME --plan $PLAN_NAME --name $APP_NAME --runtime "NODE:18-lts" --output none

# echo "4. Stopping Web App..."
# az webapp stop --resource-group $RG_NAME --name $APP_NAME

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "5. Starting Web App..."
# az webapp start --resource-group $RG_NAME --name $APP_NAME

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "6. Cleanup will run automatically on exit."
