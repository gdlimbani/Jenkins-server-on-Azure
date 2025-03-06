# Variables for resource names and settings

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
  default = "95eba7e9-db83-4900-a7a9-695be8543900"
}

variable "client_id" {
  description = "The Azure client ID"
  type        = string
  default = "8778c87a-82d8-4950-9cac-36609e466085"
}

variable "client_secret" {
  description = "The Azure client secret"
  type        = string
  default = "uiE8Q~b9xzbEIu7fmT7QFB5ynWWK-A1EsnPeuapd"
}

variable "tenant_id" {
  description = "The Azure tenant ID"
  type        = string
  default = "3da2b7e8-16b9-4850-a1a1-cebdc35e74a0"
}

variable "location" {
  default = "Central India"
  type = string
}

variable "resource_group_name" {
  default = "gdl"
  type = string
}

variable "vm_name" {
  default = "gdl-jenkins-vm"
  type = string
}

variable "admin_username" {
  default = "azureuser"
  type = string
}

variable "admin_password" {
  sensitive = true
  type = string
}

variable "virtual_network_name" {
  default = "gdl-jenkins-vnet"
  type = string
}

variable "subnet_name" {
  default = "gdl-jenkins-subnet"
  type = string
}

variable "network_security_group_name" {
  default = "gdl-jenkins-nsg"
}

variable "public_ip_name" {
  default = "gdl-jenkins-public-ip"
}

variable "network_interface_name" {
  default = "gdl-jenkins-nic"
}