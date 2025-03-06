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
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Create a Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.network_security_group_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  allocation_method            = "Dynamic"
  sku                          = "Basic"
}

# Create Network Interface
resource "azurerm_network_interface" "nic" {
  name                         = "${var.network_interface_name}"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name  
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
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  size                         = "Standard_B1ms"
  admin_username               = var.admin_username
  admin_password               = var.admin_password
  network_interface_ids        = [azurerm_network_interface.nic.id]
#   storage_os_disk {
#     name              = "jenkins-os-disk"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed           = true
#     disk_size_gb      = 20
#   }

  os_disk {
    name              = "gdl-jenkins-os-disk"
    caching           = "ReadWrite"
    disk_size_gb      = 20
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
resource "azurerm_virtual_machine_extension" "install_jenkins" {
  name                 = "install-jenkins"
  virtual_machine_id   = azurerm_linux_virtual_machine.jenkins_vm.id
  publisher             = "Canonical"
  type                  = "CustomScript"
  type_handler_version = "1.10"

  settings = <<SETTINGS
  #!/bin/bash
  sudo yum update
    sudo wget -O /etc/yum.repos.d/jenkins.repo \
        https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum upgrade -y
    sudo amazon-linux-extras install java-17-amazon-corretto-devel -y
    sudo yum install jenkins -y
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    sudo ufw allow 8080
    sudo ufw reload

    # install git
    sudo yum install git -y

    # install terraform

    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install terraform

    # install kubectl

    sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.23.6/bin/linux/amd64/kubectl
    sudo chmod +x ./kubectl
    sudo mkdir -p $HOME/bin && sudo cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
SETTINGS
}
