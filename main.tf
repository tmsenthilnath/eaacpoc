provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.28.0"

subscription_id = "38a48eb9-12be-4a21-91d8-d92ce3ad56a4"
client_id = "${var.azure_client_id}"
client_secret = "${var.azure_client_secret}"
tenant_id = "776ff747-970b-4a0b-96b6-9e248a307707"
}


resource "azurerm_resource_group" "cicd01" {
name = "CI-CD01"
location = "southeastasia"

tags = {
environment = "PoC"
}
}
# Terraform Template for Creation of AKS
resource "azurerm_kubernetes_cluster" "CICD" {
name = "CICD-AKS"
location = "southeastasia" 
resource_group_name = "CI-CD01"
dns_prefix = "cicd-aks01"

agent_pool_profile {
name = "default"
count = 1
vm_size = "Standard_D1_v2"
os_type = "Linux"
os_disk_size_gb = 30
}
service_principal {
client_id = "${var.azure_client_id}"
client_secret = "${var.azure_client_secret}"
}
}

# Terraform Template for Creation of Application Gateway
resource "azurerm_virtual_network" "test" {
name = "cicdvnet"
resource_group_name = "ci-cd01"
location = "southeastasia"
address_space = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
name = "frontend"
resource_group_name = "ci-cd01"
virtual_network_name = "${azurerm_virtual_network.test.name}"
address_prefix = "10.254.0.0/24"
}

resource "azurerm_subnet" "backend" {
name = "backend"
resource_group_name = "ci-cd01"
virtual_network_name = "${azurerm_virtual_network.test.name}"
address_prefix = "10.254.2.0/24"
}

resource "azurerm_public_ip" "test" {
name = "ci-cd01-pip"
resource_group_name = "ci-cd01"
location = "southeastasia"
allocation_method = "Dynamic"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
backend_address_pool_name = "${azurerm_virtual_network.test.name}-beap"
frontend_port_name = "${azurerm_virtual_network.test.name}-feport"
frontend_ip_configuration_name = "${azurerm_virtual_network.test.name}-feip"
http_setting_name = "${azurerm_virtual_network.test.name}-be-htst"
listener_name = "${azurerm_virtual_network.test.name}-httplstn"
request_routing_rule_name = "${azurerm_virtual_network.test.name}-rqrt"
redirect_configuration_name = "${azurerm_virtual_network.test.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
name = "ci-cd01-appgateway"
resource_group_name = "ci-cd01"
location = "southeastasia"

sku {
name = "Standard_Small"
tier = "Standard"
capacity = 2
}

gateway_ip_configuration {
name = "my-gateway-ip-configuration"
subnet_id = "${azurerm_subnet.frontend.id}"
}

frontend_port {
name = "${local.frontend_port_name}"
port = 80
}

frontend_ip_configuration {
name = "${local.frontend_ip_configuration_name}"
public_ip_address_id = "${azurerm_public_ip.test.id}"
}

backend_address_pool {
name = "${local.backend_address_pool_name}"
}

backend_http_settings {
name = "${local.http_setting_name}"
cookie_based_affinity = "Disabled"
path = "/path1/"
port = 80
protocol = "Http"
request_timeout = 1
}

http_listener {
name = "${local.listener_name}"
frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
frontend_port_name = "${local.frontend_port_name}"
protocol = "Http"
}

request_routing_rule {
name = "${local.request_routing_rule_name}"
rule_type = "Basic"
http_listener_name = "${local.listener_name}"
backend_address_pool_name = "${local.backend_address_pool_name}"
backend_http_settings_name = "${local.http_setting_name}"
}
}
# Provision Container registry
resource "azurerm_container_registry" "acr" {
name = "cicdreg"
resource_group_name = "ci-cd01"
location = "southeastasia"
sku = "Basic"
admin_enabled = false
}
#Provision storage account

resource "azurerm_storage_account" "cicdstg" {
name = "cicd01"
resource_group_name = "ci-cd01"
location = "southeastasia"
account_tier = "Standard"
account_replication_type = "ZRS"

} 
