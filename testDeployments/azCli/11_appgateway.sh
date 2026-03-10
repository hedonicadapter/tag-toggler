#!/usr/bin/env bash
set -euo pipefail

# Variables
SUFFIX=$(date +%s)
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
VNET_NAME="demo-vnet-$SUFFIX"
SUBNET_NAME="AppGwSubnet"
IP_NAME="demo-appgw-ip-$SUFFIX"
APPGW_NAME="demo-appgw-$SUFFIX"

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
echo " Azure Application Gateway Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
  echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
  exit 1
fi

echo "2. Setting up Networking... (VNet/Subnet/Public IP)"
az network vnet create \
  --name $VNET_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --address-prefix 10.0.0.0/16 \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix 10.0.0.0/24 \
  --output none

az network public-ip create \
  --resource-group $RG_NAME \
  --name $IP_NAME \
  --allocation-method Static \
  --sku Standard \
  --output none

echo "3. Deploying Application Gateway: $APPGW_NAME (May take up to 20 mins)"
az network application-gateway create \
  --name $APPGW_NAME \
  --location $LOCATION \
  --resource-group $RG_NAME \
  --capacity 1 \
  --sku Standard_v2 \
  --public-ip-address $IP_NAME \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --output none

# echo "4. Stopping Application Gateway..."
# az network application-gateway stop --resource-group $RG_NAME --name $APPGW_NAME
# echo "App Gateway Stopped."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "5. Starting Application Gateway..."
# az network application-gateway start --resource-group $RG_NAME --name $APPGW_NAME
# echo "App Gateway Started."

# echo "Waiting for 30 seconds..."
# sleep 20

# echo "6. Cleanup will run automatically on exit."
