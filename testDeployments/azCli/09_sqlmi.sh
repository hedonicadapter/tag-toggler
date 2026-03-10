#!/usr/bin/env bash
set -euo pipefail
# Note: SQL Managed Instances take a very long time to provision and modify.
# Using background processes for brevity in the sample, but actual operations take a long time.
# Variables
SUFFIX=$(date +%s)
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
VNET_NAME="demo-vnet-$SUFFIX"
SUBNET_NAME="ManagedInstance"
MI_NAME="demo-sqlmi-$SUFFIX"

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
echo " Azure SQL Managed Instance Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
  echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
  exit 1
fi

echo "2. Setting up Networking... (VNet/Subnet)"
az network vnet create \
  --name $VNET_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --address-prefix 10.0.0.0/16 \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix 10.0.0.0/24 \
  --output none

echo "3. Deploying SQL Managed Instance: $MI_NAME (Note: This can take hours, starting in background)"
# We're just demonstrating the commands, this might fail synchronously or take too long in a generic script
az sql mi create \
  --resource-group $RG_NAME \
  --name $MI_NAME \
  --subnet $SUBNET_NAME \
  --vnet-name $VNET_NAME \
  --admin-user sqlmiadmin \
  --admin-password "P@ssw0rd1234!" \
  --tier GeneralPurpose \
  --family Gen5 \
  --compute-model Provisioned \
  --vcores 2 \
  --storage 32 \
  --license-type BasePrice \
  --no-wait

# echo "Simulating wait..."
# sleep 20

# echo "4. Stopping SQL Managed Instance... (Assuming it existed)"
# az sql mi stop --resource-group $RG_NAME --name $MI_NAME
# echo "(Command commented out due to long provisioning time: az sql mi stop)"

# echo "5. Starting SQL Managed Instance... (Assuming it existed)"
# az sql mi start --resource-group $RG_NAME --name $MI_NAME
# echo "(Command commented out due to long provisioning time: az sql mi start)"

# echo "6. Cleanup will run automatically on exit."
