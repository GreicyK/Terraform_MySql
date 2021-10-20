terraform {
   required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.46.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {
}
}
resource "azurerm_resource_group" "myterraformgroup"  {
  name     = "myResourceGroupVM"
  location = "eastus"

      tags     = {
        "Environment" = "aula teste"
    }
}
resource "azurerm_virtual_network" "myterraformgroup" {
  name                = "myterraformgroup"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Production"
    faculdade = "impacta"
    turma = "es22"
  }
}

resource "azurerm_subnet" "sb-aulaeas22" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformgroup.name
  address_prefixes     = ["10.0.1.0/24"]

}
resource "azurerm_public_ip" "ip-aula" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  location        =    "eastus"
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }

  }
  resource "azurerm_network_security_group" "nsg-aula" {
  name                = "acceptanceTestSecurityGroup1"
  location            =    "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
resource "azurerm_network_interface" "nic-aula" {
  name                = "nic"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "nic-es22"
    subnet_id                     = azurerm_subnet.sb-aulaeas22.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ip-aula.id
  }
}
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic-aula.id
  network_security_group_id = azurerm_network_security_group.nsg-aula.id
}
resource "azurerm_virtual_machine" "vm_aulaes22" {
  name                  = "aula-vn"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.nic-aula.id]
  vm_size               = "Standard_DS1_v2"


  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
data "azurerm_public_ip" "ip-db" {
  name                = azurerm_public_ip.ip-aula.name
  resource_group_name = azurerm_resource_group.myterraformgroup.name
}

resource "time_sleep" "wait_30_seconds_db" {
  depends_on = [azurerm_virtual_machine.vm_aulaes22]
  create_duration = "30s"
}