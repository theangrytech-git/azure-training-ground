/*******************************************************************************

PROJECT NAME:       %INSERT NAME HERE%
CREATED BY:         THEANGRYTECH-GIT
REPO:
DESCRIPTION:   This project will be used for deploying a small environment
                in Azure using Terraform. The environment will consist of
                a resource group, virtual network, subnets, network security
                groups, firewalls, firewall rules, NAT rules and storage accounts.

*******************************************************************************/

/*******************************************************************************
                            WORK IN PROGRESS
********************************************************************************

Notes:
This section will be used to add in anything that will need to be added in,
updated or changed in future commits.

********************************************************************************/


/*******************************************************************************
                         CREATE LOCAL VARIABLES
*******************************************************************************/
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}
output "current_subscription_display_name" {
value = data.azurerm_subscription.current
}


/*******************************************************************************
                         CREATE RANDOM GENERATOR
*******************************************************************************/

resource "random_string" "random" {
  length           = 3
  lower = true
  upper = false
  numeric = true
  special          = false
}

resource "random_password" "vm_admin_password" {
  length           = 16
  special          = true
  override_special = "!@#"
  upper            = true
  lower            = true
  numeric           = true
}

/*******************************************************************************
                         CREATE RESOURCE GROUPS
*******************************************************************************/
module "rg_compute" {
  source   = "./modules/resource_group"
  name     = "rg-uks-compute1"
  location = "uksouth"
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "rg_storage" {
  source   = "./modules/resource_group"
  name     = "rg-uks-storage1"
  location = "uksouth"
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "rg_monitoring" {
  source   = "./modules/resource_group"
  name     = "rg-uks-monitoring1"
  location = "uksouth"
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "rg_networking" {
  source   = "./modules/resource_group"
  name     = "rg-uks-networking1"
  location = "uksouth"
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "rg_security" {
  source   = "./modules/resource_group"
  name     = "rg-uks-security1"
  location = "uksouth"
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

/*******************************************************************************
                      CREATE VIRTUAL NETWORKS AND SUBNETS
*******************************************************************************/
module "vnet_uks_main" {
  source              = "./modules/vnet"
  name                = "vnet-uks-main"
  location            = "uksouth"
  resource_group_name = module.rg_networking.name
  address_space       = ["10.0.0.0/20"]

  subnets = [
    {
      name             = "subnet-app"
      address_prefixes = ["10.0.1.0/24"]
    },
    {
      name             = "subnet-db"
      address_prefixes = ["10.0.2.0/24"]
      delegations = [
    {
      name = "pg-delegation"
      service_delegation = {
        name    = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  ]
  },
    {
      name             = "subnet-storage"
      address_prefixes = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    },
    {
      name             = "subnet-vm"
      address_prefixes = ["10.0.4.0/24"]
    },
    {
      name             = "subnet-security"
      address_prefixes = ["10.0.5.0/24"]
    },
    {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.0.6.0/26"]
    }

  ]

  tags = {
    environment = "training"
    owner       = "op9"
  }
}

/*******************************************************************************
                         CREATE PRIVATE DNS ZONES
*******************************************************************************/

module "private_dns_postgres" {
  source              = "./modules/priv_dns_zone"
  zone_name           = "privatelink.postgres.database.azure.com"
  resource_group_name = module.rg_networking.name
  virtual_network_links = {
    "vnet-db" = module.vnet_uks_main.vnet_id
  }
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

/*******************************************************************************
                         CREATE NETWORK SECURITY GROUPS
*******************************************************************************/
module "nsg_vm" {
  source              = "./modules/nsg"
  name                = "nsg-vm"
  location            = module.rg_networking.location
  resource_group_name = module.rg_networking.name

  subnet_ids = {
    "subnet-vm" = module.vnet_uks_main.subnet_ids["subnet-vm"]
  }

  security_rules = [
    {
      name                       = "AllowHTTP"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowSSH"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowRDP"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "nsg_storage" {
  source              = "./modules/nsg"
  name                = "nsg-storage"
  location            = module.rg_networking.location
  resource_group_name = module.rg_networking.name

  subnet_ids = {
    "subnet-storage" = module.vnet_uks_main.subnet_ids["subnet-storage"]
  }

  security_rules = [
    {
      name                       = "AllowHTTP"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowHTTPS"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowSMB"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "445"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowNFS"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "2049"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

/*******************************************************************************
                         CREATE WINDOWS VMS
*******************************************************************************/
module "win_vm_1" {
  source              = "./modules/vm_win"
  name                = "vm-uks-win-01"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  subnet_id           = module.vnet_uks_main.subnet_ids["subnet-vm"]
  admin_username      = "netco_user"
  admin_password      = random_password.vm_admin_password.result
  public_ip_enabled   = true
  availability_set_id = azurerm_availability_set.uks_as_win.id

  tags = {
    environment = "training"
    owner       = "op9"
  }
  depends_on = [
    module.log_analytics
  ]
}

module "diag_win_vm1" {
  source                      = "./modules/diagnostics"
  name                        = "diag-${module.win_vm_1.vm_name}"
  target_resource_id          = module.win_vm_1.vm_id
  log_analytics_workspace_id  = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

module "win_vm_2" {
  source              = "./modules/vm_win"
  name                = "vm-uks-win-02"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  subnet_id           = module.vnet_uks_main.subnet_ids["subnet-vm"]
  admin_username      = "netco_user"
  admin_password      = random_password.vm_admin_password.result
  public_ip_enabled   = true

  tags = {
    environment = "training"
    owner       = "op9"
  }
  depends_on = [
    module.log_analytics
  ]
}

module "diag_win_vm2" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.win_vm_2.vm_name}"
  target_resource_id        = module.win_vm_2.vm_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

/*******************************************************************************
                            CREATE LINUX VMS
*******************************************************************************/
module "lin_vm_1" {
  source              = "./modules/vm_lin"
  name                = "vm-uks-linux-${random_string.random.result}-01"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  subnet_id           = module.vnet_uks_main.subnet_ids["subnet-vm"]
  admin_username      = "netco_user"
  admin_password      = random_password.vm_admin_password.result
  public_ip_enabled   = true
  availability_set_id = azurerm_availability_set.uks_as_linux.id

  tags = {
    environment = "training"
    owner       = "op9"
  }
  depends_on = [
    module.log_analytics
  ]
}

module "diag_lin_vm1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.lin_vm_1.vm_name}"
  target_resource_id        = module.lin_vm_1.vm_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

module "lin_vm_2" {
  source              = "./modules/vm_lin"
  name                = "vm-uks-linux-${random_string.random.result}-02"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  subnet_id           = module.vnet_uks_main.subnet_ids["subnet-vm"]
  admin_username      = "netco_user"
  admin_password      = random_password.vm_admin_password.result
  public_ip_enabled   = true

  tags = {
    environment = "training"
    owner       = "op9"
  }
  depends_on = [
    module.log_analytics
  ]
}

module "diag_lin_vm2" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.lin_vm_2.vm_name}"
  target_resource_id        = module.lin_vm_2.vm_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

/*******************************************************************************
                         CREATE WINDOWS VMSS
*******************************************************************************/

module "vmss_win_1" {
  source              = "./modules/vmss_win"
  name                = "uks-win-vmss"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  subnet_id           = module.vnet_uks_main.subnet_ids["subnet-vm"]
  admin_username      = "netco_user"
  admin_password      = random_password.vm_admin_password.result

  instance_count = 2

  tags = {
    environment = "training"
    owner       = "op9"
  }
  depends_on = [
    module.log_analytics
  ]
}

module "diag_vmss_vm1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.vmss_win_1.vmss_name}"
  target_resource_id        = module.vmss_win_1.vmss_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

/*******************************************************************************
                         CREATE BASTION HOST
*******************************************************************************/

module "bastion" {
  source              = "./modules/bastion"
  name                = "bastion-uks-training"
  #dns_name            = null
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  subnet_id           = module.vnet_uks_main.subnet_ids["AzureBastionSubnet"]

  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "diag_bastion" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.bastion.name}"
  target_resource_id        = module.bastion.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

/*******************************************************************************
                         CREATE CONTAINER INSTANCES
*******************************************************************************/

module "aci_nginx_1" {
  source              = "./modules/container_instance"
  name                = "aci-nginx-training-${random_string.random.result}"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name

  container_name = "nginx"
  image          = "nginx:latest"
  cpu            = 1
  memory         = 1.5
  port           = 80

  dns_name_label = "nginx-uks-training"
  environment_variables = {
    ENVIRONMENT = "dev"
  }

  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "diag_aci_nginx_1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.aci_nginx_1.name}"
  target_resource_id        = module.aci_nginx_1.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

module "aci_hello" {
  source              = "./modules/container_instance"
  name                = "aci-nginx-hello-${random_string.random.result}"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name

  container_name = "hello-world"
  image          = "mcr.microsoft.com/mcr/hello-world:latest"
  cpu            = 0.5
  memory         = 1.5
  port           = 443

  dns_name_label = "nginx-uks-hello"
  environment_variables = {
    ENVIRONMENT = "dev"
  }

  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "diag_aci_hello" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.aci_hello.name}"
  target_resource_id        = module.aci_hello.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

/*******************************************************************************
                         CREATE CONTAINER REGIRSTRIES
*******************************************************************************/

module "acr_training" {
  source              = "./modules/container_registry"
  name                = "acrukstraining"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "diag_acr_training" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.acr_training.name}"
  target_resource_id        = module.acr_training.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

/*******************************************************************************
                         CREATE AVAILABILITY SETS
*******************************************************************************/

resource "azurerm_availability_set" "uks_as_win" {
  name                = "uks-aset-windows"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags = {
    environment = "training"
    owner       = "op9"
  }

}

resource "azurerm_availability_set" "uks_as_linux" {
  name                = "uks-aset-linux"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags = {
    environment = "training"
    owner       = "ops9"
  }
}

/*******************************************************************************
                         CREATE APP SERVICE PLANS
*******************************************************************************/

module "asp_y1" {
  source              = "./modules/asp"
  name                = "asp-uks-linux-plan-01"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name

  os_type     = "Linux"
  sku_name    = "Y1"  # Y1 = Linux Consumption; P1v2 = Premium; B1 = Basic
  worker_count = 1

  tags = {
    environment = "training"
    owner       = "ops9"
  }
}

module "asp_b1" {
  source              = "./modules/asp"
  name                = "asp-uks-linux-plan-02"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name

  os_type     = "Linux"
  sku_name    = "B1"  # Y1 = Linux Consumption; P1v2 = Premium; B1 = Basic
  worker_count = 1

  tags = {
    environment = "training"
    owner       = "ops9"
  }
}

/*******************************************************************************
                         CREATE LINUX FUNCTION APPS
*******************************************************************************/

module "linux_fa_y1" {
  source                     = "./modules/fa_linux"
  name                       = "fa-uks-linux-01"
  location                   = module.rg_compute.location
  resource_group_name        = module.rg_compute.name
  app_service_plan_id        = module.asp_y1.id
  storage_account_name       = module.storage_app_1.name
  storage_account_access_key = module.storage_app_1.primary_access_key

  runtime = "python"
  runtime_version = "3.10"  # Specify the Python version you want to use
  #version = module.fa_lin.site_config.application_stack[0].python_version.version
  app_settings = {
    "CUSTOM_ENV" = "training"
    "APPINSIGHTS_CONNECTION_STRING" = module.app_insights.connection_string
    "APPLICATIONINSIGHTS_ROLE_NAME" = "fa-uks-linux-01"
  }

  tags = {
    environment = "training"
    owner       = "op9"
  }
  depends_on = [
    module.asp_y1,
    module.storage_app_1
  ]
}

module "diag_linux_fa_y1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.linux_fa_y1.function_app_name}"
  target_resource_id        = module.linux_fa_y1.function_app_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

module "linux_fa_b1" {
  source                     = "./modules/fa_linux"
  name                       = "fa-uks-linux-02"
  location                   = module.rg_compute.location
  resource_group_name        = module.rg_compute.name
  app_service_plan_id        = module.asp_b1.id
  storage_account_name       = module.storage_app_1.name
  storage_account_access_key = module.storage_app_1.primary_access_key

  runtime = "python"
  runtime_version = "3.10"  # Specify the Python version you want to use
  #version = module.fa_lin.site_config.application_stack[0].python_version.version
  app_settings = {
    "CUSTOM_ENV" = "training"
    "APPINSIGHTS_CONNECTION_STRING" = module.app_insights.connection_string
    "APPLICATIONINSIGHTS_ROLE_NAME" = "fa-uks-linux-02"
  }

  tags = {
    environment = "training"
    owner       = "op9"
  }
  depends_on = [
    module.asp_b1,
    module.storage_app_1
  ]
}

module "diag_linux_fa_b1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.linux_fa_b1.function_app_name}"
  target_resource_id        = module.linux_fa_b1.function_app_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

module "linux_wa_b1" {
  source              = "./modules/wa_linux"
  name                = "wa-uks-linux-01"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  app_service_plan_id = module.asp_b1.id
  runtime             = "python"
  runtime_version             = "3.10"

  app_settings = {
  "DB1_NAME"     = "app_db"
  "DB1_CONN"     = "Host=${module.postgres.fqdn};Port=5432;Database=app_db;Username=${module.postgres.admin_username};Password=${module.postgres.admin_password};SslMode=Require"

  "DB2_NAME"     = "audit_db"
  "DB2_CONN"     = "Host=${module.postgres.fqdn};Port=5432;Database=audit_db;Username=${module.postgres.admin_username};Password=${module.postgres.admin_password};SslMode=Require"

  "FUNCTIONS_WORKER_RUNTIME" = "python"
  "WEBSITE_RUN_FROM_PACKAGE" = "1"
  "CUSTOM_ENV" = "training"
  "APPINSIGHTS_CONNECTION_STRING" = module.app_insights.connection_string
  "APPLICATIONINSIGHTS_ROLE_NAME" = "wa-uks-linux-01"
  }

  tags = {
    environment = "training"
    owner       = "op9"
  }
  depends_on = [
    module.asp_b1,
    #module.storage_app_1
  ]
}

module "diag_linux_wa_b1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.linux_wa_b1.web_app_name}"
  target_resource_id        = module.linux_wa_b1.web_app_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories              = []
  metric_categories           = ["AllMetrics"]
}

/*******************************************************************************
                            CREATE DATABASES
*******************************************************************************/

module "postgres" {
  source              = "./modules/postgres_db"
  name                = "pg-uks-app-01"
  location            = module.rg_compute.location
  resource_group_name = module.rg_compute.name
  admin_username      = "pgadminuser"
  admin_password      = random_password.vm_admin_password.result
  db_names             = ["webappdb", "auditdb",]
  subnet_id           = module.vnet_uks_main .subnet_ids["subnet-db"]
  private_dns_zone_id = module.private_dns_postgres.id

  tags = {
    environment = "training"
    owner       = "op9"
  }
  depends_on = [module.vnet_uks_main]
}

module "diag_postgres" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.postgres.database_names[0]}"
  target_resource_id        = module.postgres.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories     = ["PostgreSQLLogs"]
  metric_categories  = ["AllMetrics"]
}

/*******************************************************************************
                         CREATE KEY VAULTS
*******************************************************************************/

module "keyvault" {
  source              = "./modules/keyvault"
  name                = "kv-uks-${random_string.random.result}"
  location            = module.rg_security.location
  resource_group_name = module.rg_security.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  access_policies = [
    {
      tenant_id               = data.azurerm_client_config.current.tenant_id
      object_id               = data.azurerm_client_config.current.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "Set", "List"]
      certificate_permissions = []
      storage_permissions     = []
    }
  ]

  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "diag_keyvault" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.keyvault.name}"
  target_resource_id        = module.keyvault.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories     = ["AuditEvent"]
  metric_categories  = ["AllMetrics"]
}

/*******************************************************************************
                         CREATE APP CONFIGURATION
*******************************************************************************/

module "appconfig" {
  source              = "./modules/appconfig"
  name                = "appconfig-uks-${random_string.random.result}"
  location            = module.rg_security.location
  resource_group_name = module.rg_security.name

  key_values = {
    "ENVIRONMENT" = {
      value = "training"
    }
    "API_BASE_URL" = {
      value       = "https://api.example.com"
      value_label = "dev"
      value_type  = "text/plain"
    }
  }

  tags = {
    environment = "training"
    owner       = "op9"
  }
}

/*******************************************************************************
                         CREATE APPLICATION INSIGHTS
*******************************************************************************/

module "app_insights" {
  source              = "./modules/app_insights"
  name                = "appi-uks-training"
  location            = module.rg_monitoring.location
  resource_group_name = module.rg_monitoring.name
  application_type    = "web"
  workspace_id        = module.log_analytics.workspace_id  # Optional, can be null

  tags = {
    environment = "training"
    owner       = "op9"
  }
}

/*******************************************************************************
                         CREATE LOG ANALYTICS WORKSPACE
*******************************************************************************/

module "log_analytics" {
  source              = "./modules/log_analytics"
  name                = "la-uks-training"
  location            = module.rg_monitoring.location
  resource_group_name = module.rg_monitoring.name
  retention_in_days   = 60

  tags = {
    environment = "training"
    owner       = "op9"
  }
}

/*******************************************************************************
                         CREATE STORAGE ACCOUNTS
*******************************************************************************/

module "storage_app_1" {
  source              = "./modules/storage"
  name                = "sauksfuncapp${random_string.random.result}"
  location            = module.rg_storage.location
  resource_group_name = module.rg_storage.name
  account_tier        = "Standard"
  replication_type    = "LRS"
  access_tier         = "Hot"
  #account_kind                = "StorageV2"

  tags = {
    environment = "training"
    team        = "ops9"
  }
}

module "diag_sa_1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.storage_app_1.name}"
  target_resource_id        = module.storage_app_1.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories     = []
  metric_categories  = ["AllMetrics"]
}

module "storage_general" {
  source              = "./modules/storage"
  name                = "sauksgeneral${random_string.random.result}"
  location            = module.rg_storage.location
  resource_group_name = module.rg_storage.name
  account_tier        = "Standard"
  replication_type    = "LRS"
  access_tier         = "Hot"
  #account_kind                = "StorageV2"

  tags = {
    environment = "training"
    team        = "ops9"
  }
}

module "diag_gen_1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.storage_general.name}"
  target_resource_id        = module.storage_general.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories     = []
  metric_categories  = ["AllMetrics"]
}

module "storage_site" {
  source              = "./modules/storage"
  name                = "sauksstaticsite${random_string.random.result}"
  location            = module.rg_storage.location
  resource_group_name = module.rg_storage.name
  account_tier        = "Standard"
  replication_type    = "LRS"
  access_tier         = "Hot"
  #kind                = "StorageV2"

  tags = {
    environment = "training"
    team        = "ops9"
  }
}

module "diag_site_1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.storage_site.name}"
  target_resource_id        = module.storage_site.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories     = []
  metric_categories  = ["AllMetrics"]
}

module "storage_vm" {
  source              = "./modules/storage"
  name                = "sauksvms${random_string.random.result}"
  location            = module.rg_storage.location
  resource_group_name = module.rg_storage.name
  account_tier        = "Standard"
  replication_type    = "LRS"
  access_tier         = "Hot"
  #kind                = "StorageV2"

  tags = {
    environment = "training"
    team        = "ops9"
  }
}

module "diag_vm_1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.storage_vm.name}"
  target_resource_id        = module.storage_vm.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories     = []
  metric_categories  = ["AllMetrics"]
}

module "storage_archive" {
  source              = "./modules/storage"
  name                = "sauksarchive${random_string.random.result}"
  location            = module.rg_storage.location
  resource_group_name = module.rg_storage.name
  account_tier        = "Standard"
  replication_type    = "LRS"
  access_tier         = "Hot"
  #kind                = "StorageV2"

  tags = {
    environment = "training"
    team        = "ops9"
  }
}

module "diag_archive_1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.storage_archive.name}"
  target_resource_id        = module.storage_archive.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories     = []
  metric_categories  = ["AllMetrics"]
}

module "storage_db" {
  source              = "./modules/storage"
  name                = "sauksdatabase${random_string.random.result}"
  location            = module.rg_storage.location
  resource_group_name = module.rg_storage.name
  account_tier        = "Standard"
  replication_type    = "LRS"
  access_tier         = "Hot"
  #kind                = "StorageV2"

  tags = {
    environment = "training"
    team        = "ops9"
  }
}

module "diag_storage_db_1" {
  source                    = "./modules/diagnostics"
  name                      = "diag-${module.storage_db.name}"
  target_resource_id        = module.storage_db.id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  log_categories     = []
  metric_categories  = ["AllMetrics"]
}