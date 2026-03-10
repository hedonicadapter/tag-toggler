# Terraform variants for the bash runbooks

This folder mirrors the existing bash runbooks with Terraform resources. The scripts stay untouched; use Terraform when you want a reproducible plan/apply path.

## What gets created
All resources reuse the defaults from the scripts:
- Resource group: `rg-sand-sdc-automaton`
- Region: `eastus`
- Spot VM/VMSS, AKS, App Service (Linux), Function App (consumption), ACI, Postgres and MySQL Flexible Server, SQL Managed Instance, Synapse (workspace + dedicated SQL pool), Application Gateway Standard_v2, Azure Spring Apps (Basic), Stream Analytics job.

Each resource is behind a feature flag so you can turn on only what you need. Defaults are `false` to avoid long/expensive deploys (SQL MI, App Gateway, AKS, etc.).

## Quickstart
1. Install the AzureRM provider auth of your choice (Azure CLI login is fine):
   ```bash
   az login
   cd terraform
   terraform init
   ```
2. Enable the resources you want, for example to deploy the VM + web app:
   ```bash
   terraform plan \
     -var "enable_vm=true" \
     -var "enable_webapp=true"
   terraform apply \
     -var "enable_vm=true" \
     -var "enable_webapp=true"
   ```
3. Override the shared admin password for database-like resources:
   ```bash
   terraform plan -var "database_password=YourS3cureP@ss!" -var "enable_postgres=true"
   ```

## Notes and cautions
- SQL Managed Instance, Application Gateway, Synapse, Spring Apps, and AKS take longer and cost more. Keep their flags `false` unless needed.
- The Stream Analytics job is created with a placeholder query; add inputs/outputs before starting it.
- Names get a small random suffix to avoid collisions. The functional names match the scripts (e.g., `demo-vm`, `demo-appgw`).
- The bash scripts remain unchanged; you can still run them directly if preferred.
