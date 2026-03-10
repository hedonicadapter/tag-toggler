#!/usr/bin/env bash
set -euo pipefail
# Note: Stream Analytics Requires predefined input/output to start properly in most cases.
# Variables
SUFFIX=$(date +%s)
RG_NAME=${1:-"rg-sand-sdc-automaton"}
LOCATION=${2:-"eastus"}
JOB_NAME="demo-sa-job-$SUFFIX"

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
echo " Azure Stream Analytics Runbook"
echo "==========================================="

echo "1. Verifying Resource Group exists: $RG_NAME"
if [[ "$(az group exists --name "$RG_NAME" --output tsv)" != "true" ]]; then
  echo "Resource Group $RG_NAME not found. Please create it before running this script." >&2
  exit 1
fi

echo "2. Deploying Stream Analytics Job: $JOB_NAME"
az stream-analytics job create \
  --resource-group $RG_NAME \
  --name $JOB_NAME \
  --location $LOCATION \
  --output none

echo "Note: Cannot start a job without defined inputs and outputs."
echo "However, if configured, you would use:"
echo "az stream-analytics job start --resource-group $RG_NAME --name $JOB_NAME"
echo "az stream-analytics job stop --resource-group $RG_NAME --name $JOB_NAME"

# echo "3. Cleanup will run automatically on exit."
