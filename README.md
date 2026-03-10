# Azure Tag Start/Stop Runbook

PowerShell runbook to start or stop tagged Azure resources in parallel, plus sample deployment scripts (Azure CLI and Terraform) to spin up test targets.

> **Warning:** Some demo resources are costly (SQL Managed Instance, Synapse, Stream Analytics). Disable them when planning/applying Terraform: `terraform plan -var "enable_sqlmi=false" -var "enable_synapse=false" -var "enable_stream_analytics=false"`. 
>
> Synapse, Spring Apps, and Stream Analytics haven't been tested.

## Running locally
### Requirements
- Azure CLI
- Az PowerShell module
- Permissions; use the custom role in [permissions.json](permissions.json) with a managed identity or service principal:
	```bash
	az role definition create --role-definition permissions.json
	az role assignment create \
	  --assignee <principal_id> \
	  --role "Tag Resource Start Stop Operator" \
	  --scope /subscriptions/<subscription_id>
	```

1. Set tags on the resources you want to control, like `schedule=office-hours`
1. Stop or start by tag (`-Action` accepts `start` or `stop`):
	```pwsh
	pwsh ./runbook.ps1 -Action stop -TagKey schedule -TagValue office-hours
	pwsh ./runbook.ps1 -Action start -TagKey schedule -TagValue office-hours 
	```

## Running on Azure Automation Accounts
### Requirements
- PowerShell 7.2+ runbook runtime with a managed identity assigned to the automation account
- Permissions; assign the same custom role to that managed identity:
	```bash
	az role definition create --role-definition permissions.json
	az role assignment create \
	  --assignee <automation_account_managed_identity_principal_id> \
	  --role "Tag Resource Start Stop Operator" \
	  --scope /subscriptions/<subscription_id>
	```
1. First set tags on the resources you want to control, then call the runbook with the tag key/value

## How it works
- Signs in with the assigned identity
- Queries all resources that match the provided tag key/value, then dispatches start and stop commands to each resource
- Runs actions in parallel with a throttle of 10
- Builds a Markdown summary of successes/failures and POSTs it to an optional webhook for alerting

### Supported resource types and and the commands used:

| Resource | Command used |
| --- | --- |
| AKS | `az aks start\|stop --resource-group <rg> --name <name>` |
| App Service (web app) | `az webapp start\|stop --resource-group <rg> --name <name>` |
| Function App | `az functionapp start\|stop --resource-group <rg> --name <name>` |
| Azure Container Instances | `az container start\|stop --resource-group <rg> --name <name>` |
| PostgreSQL Flexible Server | `az postgres flexible-server start\|stop --resource-group <rg> --name <name>` |
| MySQL Flexible Server | `az mysql flexible-server start\|stop --resource-group <rg> --name <name>` |
| SQL Managed Instance | `az sql mi start\|stop --resource-group <rg> --managed-instance <name>` |
| Application Gateway | `az network application-gateway start\|stop --resource-group <rg> --name <name>` |
| VM / VMSS | `az resource invoke-action --action start|powerOff --resource-group <rg> --name <name> --resource-type <type>` |
| Synapse SQL pool (per workspace) | `az synapse sql pool resume/pause --workspace-name <ws> --name <pool>` |
| Stream Analytics job | `az stream-analytics job start\|stop --resource-group <rg> --name <name>` | 
| Fallback | `az resource invoke-action --action start\|powerOff --resource-group <rg> --name <name> --resource-type <type>` |

## Repo layout
- [runbook.ps1](runbook.ps1): main tag-based start/stop script
- [testDeployments/azCli](testDeployments/azCli): bash scripts that provision demo resources
- [testDeployments/terraform](testDeployments/terraform): Terraform equivalents with feature flags for each resource type; see its [README](testDeployments/terraform/README.md) for enable/disable guidance and cautions
- [permissions.json](permissions.json): custom role to keep least privilege for the runbook
