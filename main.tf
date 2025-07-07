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

data "azurerm_subscription" "current" {}
output "current_subscription_display_name" {
value = data.azurerm_subscription.current
}


/*******************************************************************************
                         CREATE RANDOM GENERATOR
*******************************************************************************/

resource "random_string" "random" {
  length           = 3
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
  name     = "rg-uks-compute"
  location = "uksouth"
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "rg_storage" {
  source   = "./modules/resource_group"
  name     = "rg-uks-storage"
  location = "uksouth"
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "rg_monitoring" {
  source   = "./modules/resource_group"
  name     = "rg-uks-monitoring"
  location = "uksouth"
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "rg_networking" {
  source   = "./modules/resource_group"
  name     = "rg-uks-networking"
  location = "uksouth"
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

module "rg_security" {
  source   = "./modules/resource_group"
  name     = "rg-uks-security"
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
  address_space       = ["10.0.0.0/22"]

  subnets = [
    {
      name             = "subnet-app"
      address_prefixes = ["10.0.1.0/24"]
    },
    {
      name             = "subnet-db"
      address_prefixes = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage"]
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

  ]

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
      priority                   = 110
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
      priority                   = 110
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
      priority                   = 110
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
  name                = "vm-uks-win-${random_string.random.result}-01"
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
}

module "win_vm_2" {
  source              = "./modules/vm_win"
  name                = "vm-uks-win-${random_string.random.result}-02"
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
    owner       = "linux-team"
  }
}

/*******************************************************************************
                         CREATE FIREWALL RULES
*******************************************************************************/


/*******************************************************************************
                         CREATE NAT RULES
*******************************************************************************/


/*******************************************************************************
                         CREATE STORAGE ACCOUNTS
*******************************************************************************/



















