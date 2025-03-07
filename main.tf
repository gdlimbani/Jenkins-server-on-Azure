provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

# Create a Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.virtual_network_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = "${var.resource_group_name}"
  address_space       = ["10.0.0.0/16"]
}

# Create a Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.network_security_group_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = "${var.resource_group_name}"

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 80
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowJenkins"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 8080
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create Public IP for VM
resource "azurerm_public_ip" "public_ip" {
  name                         = "${var.public_ip_name}"
  resource_group_name          = "${var.resource_group_name}"
  location                     = data.azurerm_resource_group.rg.location
  allocation_method            = "Dynamic"
  sku                          = "Basic"
}

# Create Network Interface
resource "azurerm_network_interface" "nic" {
  name                         = "${var.network_interface_name}"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = "${var.resource_group_name}"  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Create the Virtual Machine
resource "azurerm_linux_virtual_machine" "jenkins_vm" {
  name                         = var.vm_name
  resource_group_name          = "${var.resource_group_name}"
  location                     = data.azurerm_resource_group.rg.location
  size                         = "Standard_B1ms"
  admin_username               = var.admin_username
  admin_password               = var.admin_password
  network_interface_ids        = [azurerm_network_interface.nic.id]

  # Optionally, disable SSH key authentication
  disable_password_authentication = false

  //custom_data = filebase64("./jenkins-script.sh")
  custom_data = base64encode(<<EOF
#!/bin/bash
sudo apt update
sudo apt install -y openjdk-11-jre-headless
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5BA31D57EF5975CA
sudo apt update
sudo apt install -y jenkins=2.249.3
sudo systemctl start jenkins
sudo systemctl enable jenkins
EOF
  )

  os_disk {
    name              = "gdl-jenkins-os-disk"
    caching           = "ReadWrite"
    disk_size_gb      = 30
    storage_account_type    = "Standard_LRS"   # Specify storage type, for example, Standard_LRS
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "jenkins"
    "Created By" = "Gautam Limbani"
  }
}

# Output the Public IP
output "jenkins_vm_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

# Script to install Jenkins on the VM
# resource "azurerm_virtual_machine_extension" "install_jenkins" {
#   name                 = "install-jenkins"
#   virtual_machine_id   = azurerm_linux_virtual_machine.jenkins_vm.id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"

#   settings = <<SETTINGS
#     {
#         "commandToExecute": "bash -c 'sudo apt update && sudo apt install -y openjdk-11-jdk && wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add - && sudo sh -c \\\"echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list\\\" && sudo apt update && sudo apt install -y jenkins && sudo systemctl start jenkins && sudo systemctl enable jenkins'"
#     }
#   SETTINGS
# }
