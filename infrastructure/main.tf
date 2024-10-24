terraform {
   
  backend "azurerm" {
      resource_group_name  = "tech264"
      storage_account_name = "tech264ilhaantfstate"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
  }
 }

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  use_cli                         = true
  resource_provider_registrations = "none"
}
data "azurerm_resource_group" "tech264" {
  name = "tech264" # Replace with the actual name of your resource group
}


resource "azurerm_virtual_network" "tech264-ilhaan-2-subnet-vnet" {
  name                = "tech264-ilhaan-2-subnet-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.tech264.location 
  resource_group_name = data.azurerm_resource_group.tech264.name
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "public-subnet"
  resource_group_name  = data.azurerm_resource_group.tech264.name
  virtual_network_name = azurerm_virtual_network.tech264-ilhaan-2-subnet-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "private-subnet"
  resource_group_name  = data.azurerm_resource_group.tech264.name
  virtual_network_name = azurerm_virtual_network.tech264-ilhaan-2-subnet-vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Network Security Group for App VM
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = data.azurerm_resource_group.tech264.location
  resource_group_name = data.azurerm_resource_group.tech264.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_http"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group for DB VM
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg"
  location            = data.azurerm_resource_group.tech264.location
  resource_group_name = data.azurerm_resource_group.tech264.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_mongo"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "27017"
    source_address_prefix      = "10.0.2.0/24" # Allow access from app subnet
    destination_address_prefix = "*"
  }
}
# CONNECTING NSG-TO-NIC
resource "azurerm_network_interface_security_group_association" "db_nic_2_nsg" {
  network_interface_id      = azurerm_network_interface.db_nic.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}
 
resource "azurerm_network_interface_security_group_association" "app_nic_2_nsg" {
  network_interface_id      = azurerm_network_interface.app_nic.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# Network Interface for App VM
resource "azurerm_network_interface" "app_nic" {
  name                = "ilhaan-app-nic"
  location            = data.azurerm_resource_group.tech264.location
  resource_group_name = data.azurerm_resource_group.tech264.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_public_ip.id
  }
}

# Network Interface for DB VM
resource "azurerm_network_interface" "db_nic" {
  name                = "ilhaan-db-nic"
  location            = data.azurerm_resource_group.tech264.location
  resource_group_name = data.azurerm_resource_group.tech264.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Public IP for App VM (for SSH access)
resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  location            = data.azurerm_resource_group.tech264.location
  resource_group_name = data.azurerm_resource_group.tech264.name
  allocation_method   = "Static"
}

# Linux Virtual Machine for App
resource "azurerm_linux_virtual_machine" "ilhaan-app" {
  name                = "ilhaan-app"
  location            = "UK South"
  resource_group_name = data.azurerm_resource_group.tech264.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.app_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/tech264-ilhaan-az-key.pub") # Path to your public SSH key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # source_image_reference {
  #   publisher = "Canonical"
  #   offer     = "UbuntuServer"
  #   sku       = "22.04-LTS"
  #   version   = "latest"
  # }

# App VM user data script
  user_data = base64encode(file("./run-app-only.sh"))
  source_image_id =  "/subscriptions/cd36dfff-6e85-4164-b64e-b4078a773259/resourceGroups/tech264/providers/Microsoft.Compute/images/tech264-ilhaan-ready-to-run-app-image"
}

# Linux Virtual Machine for DB
resource "azurerm_linux_virtual_machine" "ilhaan-db" {
  name                = "ilhaan-db"
  location            = "UK South"
  resource_group_name = data.azurerm_resource_group.tech264.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.db_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/tech264-ilhaan-az-key.pub") # Path to your public SSH key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # source_image_reference {
  #   publisher = "Canonical"
  #   offer     = "UbuntuServer"
  #   sku       = "22.04-LTS"
  #   version   = "latest"
  # }
  source_image_id = "/subscriptions/cd36dfff-6e85-4164-b64e-b4078a773259/resourceGroups/tech264/providers/Microsoft.Compute/images/tech264-ilhaan-ready-to-run-db-image"
  # user_data = filebase64("dbscript.sh") # DB VM user data script

}
