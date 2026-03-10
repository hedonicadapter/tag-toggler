terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.5"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.default_tags
}

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  suffix = lower(random_id.suffix.hex)
  default_tags = {
    chungus = "bungus"
  }
}

# -----------------------------
# Virtual Machine (Spot)
# -----------------------------
resource "azurerm_virtual_network" "vm" {
  count               = var.enable_vm ? 1 : 0
  name                = "demo-vnet-vm-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.10.0.0/16"]
  tags                = local.default_tags
}

resource "azurerm_subnet" "vm" {
  count                = var.enable_vm ? 1 : 0
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vm[count.index].name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_public_ip" "vm" {
  count               = var.enable_vm ? 1 : 0
  name                = "demo-vm-ip-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags                = local.default_tags
}

resource "azurerm_network_interface" "vm" {
  count               = var.enable_vm ? 1 : 0
  name                = "demo-vm-nic-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm[count.index].id
  }

  tags = local.default_tags
}

resource "tls_private_key" "vm" {
  count     = var.enable_vm ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.enable_vm ? 1 : 0
  name                  = "demo-vm-${local.suffix}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  size                  = var.vm_size
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.vm[count.index].id]
  priority              = "Spot"
  eviction_policy       = "Deallocate"
  max_bid_price         = -1
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.vm[count.index].public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = local.default_tags
}

# -----------------------------
# Virtual Machine Scale Set
# -----------------------------
resource "azurerm_virtual_network" "vmss" {
  count               = var.enable_vmss ? 1 : 0
  name                = "demo-vnet-vmss-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.20.0.0/16"]
  tags                = local.default_tags
}

resource "azurerm_subnet" "vmss" {
  count                = var.enable_vmss ? 1 : 0
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vmss[count.index].name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "tls_private_key" "vmss" {
  count     = var.enable_vmss ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  count                = var.enable_vmss ? 1 : 0
  name                 = "demo-vmss-${local.suffix}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.main.name
  sku                  = var.vm_size
  instances            = 1
  priority             = "Spot"
  eviction_policy      = "Deallocate"
  max_bid_price        = -1
  upgrade_mode         = "Manual"
  overprovision        = false

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.vmss[count.index].public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "vmss-ipcfg"
      primary                                = true
      subnet_id                              = azurerm_subnet.vmss[count.index].id
      load_balancer_backend_address_pool_ids = []
    }
  }

  tags = local.default_tags
}

# -----------------------------
# Azure Kubernetes Service
# -----------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  count               = var.enable_aks ? 1 : 0
  name                = "demo-aks-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "demoaks${local.suffix}"

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.default_tags
}

# -----------------------------
# App Service (Linux Web App)
# -----------------------------
resource "azurerm_service_plan" "web" {
  count               = var.enable_webapp ? 1 : 0
  name                = "demo-app-plan-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "F1"
  tags                = local.default_tags
}

resource "azurerm_linux_web_app" "web" {
  count               = var.enable_webapp ? 1 : 0
  name                = "demo-webapp-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.web[count.index].id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }

  tags = local.default_tags
}

# -----------------------------
# Azure Functions (Consumption)
# -----------------------------
resource "azurerm_storage_account" "func" {
  count                    = var.enable_functionapp ? 1 : 0
  name                     = "demofuncstore${local.suffix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  tags                     = local.default_tags
}

resource "azurerm_service_plan" "func" {
  count               = var.enable_functionapp ? 1 : 0
  name                = "demo-func-plan-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.default_tags
}

resource "azurerm_linux_function_app" "func" {
  count                       = var.enable_functionapp ? 1 : 0
  name                        = "demo-func-${local.suffix}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.main.name
  service_plan_id             = azurerm_service_plan.func[count.index].id
  storage_account_name        = azurerm_storage_account.func[count.index].name
  storage_account_access_key  = azurerm_storage_account.func[count.index].primary_access_key
  functions_extension_version = "~4"

  site_config {
    application_stack {
      node_version = "18"
    }
    application_insights_key = null
  }

  tags = local.default_tags
}

# -----------------------------
# Azure Container Instances
# -----------------------------
resource "azurerm_container_group" "aci" {
  count               = var.enable_aci ? 1 : 0
  name                = "demo-aci-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = "demo-aci-${local.suffix}"

  container {
    name   = "hello"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld"
    cpu    = 0.5
    memory = 1

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = merge(local.default_tags, {
    environment = "demo"
  })
}

# -----------------------------
# PostgreSQL Flexible Server
# -----------------------------
resource "azurerm_postgresql_flexible_server" "pg" {
  count                        = var.enable_postgres ? 1 : 0
  name                         = "demo-pg-${local.suffix}"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.main.name
  administrator_login          = "pgadmin"
  administrator_password       = var.database_password
  sku_name                     = "B_Standard_B1ms"
  storage_mb                   = 32768
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  version = "14"
  authentication {
    password_auth_enabled = true
  }
  public_network_access_enabled = true
  tags                          = local.default_tags
}

# -----------------------------
# MySQL Flexible Server
# -----------------------------
resource "azurerm_mysql_flexible_server" "mysql" {
  count                        = var.enable_mysql ? 1 : 0
  name                         = "demo-mysql-${local.suffix}"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.main.name
  administrator_login          = "mysqladmin"
  administrator_password       = var.database_password
  sku_name                     = "B_Standard_B1ms"
  storage {
    size_gb = 32
  }
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  version = "8.0.21"
  tags                          = local.default_tags
}

# -----------------------------
# SQL Managed Instance (provisions in its own VNet/subnet)
# -----------------------------
resource "azurerm_virtual_network" "sqlmi" {
  count               = var.enable_sqlmi ? 1 : 0
  name                = "demo-vnet-sqlmi-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.30.0.0/16"]
  tags                = local.default_tags
}

resource "azurerm_subnet" "sqlmi" {
  count                                          = var.enable_sqlmi ? 1 : 0
  name                                           = "ManagedInstance"
  resource_group_name                            = azurerm_resource_group.main.name
  virtual_network_name                           = azurerm_virtual_network.sqlmi[count.index].name
  address_prefixes                               = ["10.30.1.0/24"]

  delegation {
    name = "sqlmi-delegation"

    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_mssql_managed_instance" "sqlmi" {
  count                           = var.enable_sqlmi ? 1 : 0
  name                            = "demo-sqlmi-${local.suffix}"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.main.name
  administrator_login             = "sqlmiadmin"
  administrator_login_password    = var.database_password
  subnet_id                       = azurerm_subnet.sqlmi[count.index].id
  license_type                    = "BasePrice"
  sku_name                        = "GP_Gen5"
  vcores                          = 4
  storage_size_in_gb              = 32
  timezone_id                     = "UTC"
  public_data_endpoint_enabled    = false
  minimum_tls_version             = "1.2"
  tags                            = local.default_tags
}

# -----------------------------
# Synapse Workspace + Dedicated SQL Pool
# -----------------------------
# resource "azurerm_storage_account" "synapse" {
#   count                           = var.enable_synapse ? 1 : 0
#   name                            = "synapsestore${local.suffix}"
#   resource_group_name             = azurerm_resource_group.main.name
#   location                        = var.location
#   account_kind                    = "StorageV2"
#   account_tier                    = "Standard"
#   account_replication_type        = "LRS"
#   is_hns_enabled                  = true
#   enable_https_traffic_only       = true
#   min_tls_version                 = "TLS1_2"
#   allow_nested_items_to_be_public = false
# }

# resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
#   count              = var.enable_synapse ? 1 : 0
#   name               = "users"
#   storage_account_id = azurerm_storage_account.synapse[count.index].id
# }

# resource "azurerm_synapse_workspace" "ws" {
#   count               = var.enable_synapse ? 1 : 0
#   name                = "demosynapsews${local.suffix}"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = var.location
#   storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse[count.index].id
#   sql_administrator_login              = "sqladminuser"
#   sql_administrator_login_password     = var.database_password
#   managed_virtual_network_enabled      = true
# }

# resource "azurerm_synapse_sql_pool" "pool" {
#   count               = var.enable_synapse ? 1 : 0
#   name                = "demopool"
#   resource_group_name = azurerm_resource_group.main.name
#   workspace_name      = azurerm_synapse_workspace.ws[count.index].name
#   sku_name            = "DW100c"
#   create_mode         = "Default"
#   max_size_bytes      = 53687091200
# }

# -----------------------------
# Application Gateway
# -----------------------------
resource "azurerm_virtual_network" "appgw" {
  count               = var.enable_app_gateway ? 1 : 0
  name                = "demo-vnet-appgw-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.40.0.0/16"]
  tags                = local.default_tags
}

resource "azurerm_subnet" "appgw" {
  count                                          = var.enable_app_gateway ? 1 : 0
  name                                           = "AppGwSubnet"
  resource_group_name                            = azurerm_resource_group.main.name
  virtual_network_name                           = azurerm_virtual_network.appgw[count.index].name
  address_prefixes                               = ["10.40.1.0/24"]
}

resource "azurerm_public_ip" "appgw" {
  count               = var.enable_app_gateway ? 1 : 0
  name                = "demo-appgw-ip-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.default_tags
}

resource "azurerm_application_gateway" "main" {
  count               = var.enable_app_gateway ? 1 : 0
  name                = "demo-appgw-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  http2_enabled       = true
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = azurerm_subnet.appgw[count.index].id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.appgw[count.index].id
  }

  backend_address_pool {
    name = "defaultpool"
  }

  backend_http_settings {
    name                  = "defaulthttpsettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "httplistener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "httprule"
    rule_type                  = "Basic"
    http_listener_name         = "httplistener"
    backend_address_pool_name  = "defaultpool"
    backend_http_settings_name = "defaulthttpsettings"
  }

  tags = local.default_tags
}

# -----------------------------
# Azure Spring Apps (Basic)
# -----------------------------
resource "azurerm_spring_cloud_service" "spring" {
  count               = var.enable_spring_apps ? 1 : 0
  name                = "demospringsvc${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku_name            = "B0"
  tags                = local.default_tags
}

resource "azurerm_spring_cloud_app" "spring" {
  count               = var.enable_spring_apps ? 1 : 0
  name                = "demo-app-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  service_name        = azurerm_spring_cloud_service.spring[count.index].name
  identity {
    type = "SystemAssigned"
  }
  https_only = false
}

# -----------------------------
# Stream Analytics Job
# -----------------------------
resource "azurerm_stream_analytics_job" "sa" {
  count               = var.enable_stream_analytics ? 1 : 0
  name                = "demo-sa-job-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  compatibility_level = "1.2"
  data_locale         = "en-US"
  events_late_arrival_max_delay_in_seconds    = 5
  events_out_of_order_max_delay_in_seconds    = 0
  events_out_of_order_policy                  = "Adjust"
  output_error_policy                         = "Stop"
  streaming_units                             = 1
  transformation_query                        = "SELECT * INTO [output] FROM [input]"

  tags = merge(local.default_tags, {
    note = "Inputs/outputs must be defined before starting the job."
  })
}
