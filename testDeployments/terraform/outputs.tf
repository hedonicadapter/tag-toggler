output "resource_group" {
  value       = azurerm_resource_group.main.name
  description = "Resource group used for all resources."
}

output "vm_name" {
  value       = length(azurerm_linux_virtual_machine.vm) > 0 ? azurerm_linux_virtual_machine.vm[0].name : null
  description = "Name of the demo VM (if created)."
}

output "vmss_name" {
  value       = length(azurerm_linux_virtual_machine_scale_set.vmss) > 0 ? azurerm_linux_virtual_machine_scale_set.vmss[0].name : null
  description = "Name of the demo VMSS (if created)."
}

output "aks_name" {
  value       = length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].name : null
  description = "Name of the demo AKS cluster (if created)."
}

output "webapp_name" {
  value       = length(azurerm_linux_web_app.web) > 0 ? azurerm_linux_web_app.web[0].name : null
  description = "Name of the demo web app (if created)."
}

output "function_app" {
  value       = length(azurerm_linux_function_app.func) > 0 ? azurerm_linux_function_app.func[0].name : null
  description = "Name of the demo Function App (if created)."
}

output "aci_fqdn" {
  value       = length(azurerm_container_group.aci) > 0 ? azurerm_container_group.aci[0].fqdn : null
  description = "Public FQDN for the demo ACI (if created)."
}

output "postgres_fqdn" {
  value       = length(azurerm_postgresql_flexible_server.pg) > 0 ? azurerm_postgresql_flexible_server.pg[0].fqdn : null
  description = "FQDN of the demo PostgreSQL server (if created)."
}

output "mysql_fqdn" {
  value       = length(azurerm_mysql_flexible_server.mysql) > 0 ? azurerm_mysql_flexible_server.mysql[0].fqdn : null
  description = "FQDN of the demo MySQL server (if created)."
}

output "sqlmi_name" {
  value       = length(azurerm_mssql_managed_instance.sqlmi) > 0 ? azurerm_mssql_managed_instance.sqlmi[0].name : null
  description = "Name of the demo SQL Managed Instance (if created)."
}

#output "synapse_workspace" {
#  value       = length(azurerm_synapse_workspace.ws) > 0 ? azurerm_synapse_workspace.ws[0].name : null
#  description = "Name of the demo Synapse workspace (if created)."
#}

output "application_gateway" {
  value       = length(azurerm_application_gateway.main) > 0 ? azurerm_application_gateway.main[0].name : null
  description = "Name of the demo Application Gateway (if created)."
}

output "spring_service" {
  value       = length(azurerm_spring_cloud_service.spring) > 0 ? azurerm_spring_cloud_service.spring[0].name : null
  description = "Name of the Azure Spring Apps service (if created)."
}

output "stream_analytics_job" {
  value       = length(azurerm_stream_analytics_job.sa) > 0 ? azurerm_stream_analytics_job.sa[0].name : null
  description = "Name of the Stream Analytics job (if created)."
}
