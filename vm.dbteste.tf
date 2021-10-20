resource "null_resource" "mysql" {
   triggers = {
      order = azurerm_virtual_machine.vm_aulaes22.id
    }
    provisioner "file" {
        connection {
            type = "ssh"
            user = "testadmin"
            password = "Password1234!"
            host = data.azurerm_public_ip.ip-db.ip_address
        }
        source = "mysql"
        destination = "/home/testadmin"
    }

    depends_on = [ time_sleep.wait_30_seconds_db ]
}
resource "null_resource" "deploy2_db" {
    triggers = {
        order = null_resource.upload_db.id
    }
    provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = "testadmin"
            password = "Password1234!"
            host = data.azurerm_public_ip.ip-db.ip_address
        }
        inline = [
            "sudo apt-get update",
            "sudo apt-get install -y mysql-server-5.7",
            "sudo mysql < /home/testadmin/mysql/script/user.sql",

        ]
    }
}
resource "azurerm_network_security_rule" "example" {
  name                        = "mysql"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myterraformgroup.name
  network_security_group_name = azurerm_network_security_group.nsg-aula.name
}